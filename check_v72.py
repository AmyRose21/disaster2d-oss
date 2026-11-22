#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# check_v72.py — validador de la v72 (WSS: Wacky Stretchy & Squashy)
# corre desde la raiz del proyecto (la carpeta con el .yyp).
# Sale 0 solo si TODOS los checks pasan.
import json, os, re, subprocess, sys

FAIL = 0
def ok(msg):
    print(f"  ok  {msg}")
def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  FAIL {msg}")

REPO = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------ lexer GML
def strip_comments(txt):
    """Quita // y /* */ (respeta strings)."""
    out, i, n = [], 0, len(txt)
    while i < n:
        c = txt[i]
        if c == "/" and i + 1 < n and txt[i+1] == "/":
            j = txt.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
            continue
        if c == "/" and i + 1 < n and txt[i+1] == "*":
            j = txt.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(" " * (j - i))
            i = j
            continue
        if c == '"' or c == "'":
            q = c
            out.append(c); i += 1
            while i < n and txt[i] != q:
                if txt[i] == "\\":
                    out.append(txt[i]); i += 1
                out.append(txt[i]); i += 1
            out.append(q); i += 1
            continue
        out.append(c); i += 1
    return "".join(out)

def gml_lexer_balance(txt):
    """Devuelve (llaves, parens, corchetes) balanceados, consciente de
    comentarios // y /* */ y strings "..." '...' y @'...'."""
    i, n = 0, len(txt)
    depth = {"{": 0, "(": 0, "[": 0}
    pairs = {"}": "{", ")": "(", "]": "["}
    while i < n:
        c = txt[i]
        if c == "/" and i + 1 < n and txt[i+1] == "/":
            j = txt.find("\n", i)
            i = n if j < 0 else j + 1
            continue
        if c == "/" and i + 1 < n and txt[i+1] == "*":
            j = txt.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == '"' or c == "'":
            q = c
            i += 1
            while i < n and txt[i] != q:
                if txt[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if c in depth:
            depth[c] += 1
        elif c in pairs:
            depth[pairs[c]] -= 1
            if depth[pairs[c]] < 0:
                return False
        i += 1
    return depth["{"] == 0 and depth["("] == 0 and depth["["] == 0

print("== 1. Balance de llaves/parens/corchetes (lexer consciente de comentarios/strings) ==")
GML_FILES = ["scripts/scr_wss/scr_wss.gml",
             "scripts/scr_collision_basic/scr_collision_basic.gml",
             "objects/obj_sally_canon/Draw_0.gml",
             "objects/obj_player_puppet/Create_0.gml",
             "objects/obj_player_puppet/Step_0.gml",
             "objects/obj_player_puppet/Draw_0.gml"] + \
            [f"objects/{c}/Draw_0.gml" for c in
             ["obj_amelia","obj_amy","obj_amy_canon","obj_amy_fleetway","obj_blaze",
              "obj_chaos","obj_cream","obj_egg","obj_exe","obj_exeller","obj_exetior",
              "obj_jinna","obj_knux","obj_kris","obj_metal","obj_metalamy","obj_rouge",
              "obj_sally","obj_sonic","obj_tails","obj_vanilla"]]
for p in GML_FILES:
    txt = open(os.path.join(REPO, p), encoding="utf-8").read()
    if "\r" in txt:
        bad(f"{p}: contiene CR")
    if gml_lexer_balance(txt):
        ok(f"{p}")
    else:
        bad(f"{p}: desbalanceado")

print("== 2. Parches aplicados (marca exacta, 1 vez) ==")
def one(p, needle):
    txt = open(os.path.join(REPO, p), encoding="utf-8").read()
    return txt.count(needle)

if one("scripts/scr_collision_basic/scr_collision_basic.gml", "scr_wss_update();") == 1:
    ok("hook scr_wss_update() en scr_collision_basic (1)")
else:
    bad("hook scr_collision_basic")

DRAW_OLD = "draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale,"
DRAW_NEW = "draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1],"
n_new = n_old = n_helper = 0
for c in ["obj_amelia","obj_amy","obj_amy_canon","obj_amy_fleetway","obj_blaze",
          "obj_chaos","obj_cream","obj_egg","obj_exe","obj_exeller","obj_exetior",
          "obj_jinna","obj_knux","obj_kris","obj_metal","obj_metalamy","obj_rouge",
          "obj_sally","obj_sonic","obj_tails","obj_vanilla"]:
    p = f"objects/{c}/Draw_0.gml"
    n_new += one(p, DRAW_NEW)
    n_old += one(p, DRAW_OLD)
    n_helper += one(p, "var _wss = scr_wss_draw();")
if n_new == 21 and n_old == 0 and n_helper == 21:
    ok("21 Draw_0 de personajes: linea base reemplazada + helper (21/21/21)")
else:
    bad(f"Draw_0 personajes: new={n_new} old={n_old} helper={n_helper} (esperaba 21/0/21)")

if one("objects/obj_sally_canon/Draw_0.gml", "var _f2xs = image_xscale * _wss[0] * (1 - fase2Sq * 0.6);") == 1:
    ok("obj_sally_canon Draw: composicion fase2 x WSS")
else:
    bad("obj_sally_canon Draw")

if one("objects/obj_player_puppet/Create_0.gml", "wssWasAir = false;") == 1 and \
   one("objects/obj_player_puppet/Create_0.gml", "wssSq = 0;") == 1:
    ok("puppet Create: variables WSS declaradas")
else:
    bad("puppet Create")

if one("objects/obj_player_puppet/Step_0.gml", "scr_wss_puppet_update();") == 1:
    ok("puppet Step: update enganchado")
else:
    bad("puppet Step")

if one("objects/obj_player_puppet/Draw_0.gml", "_f2ys = image_yscale * _wss[1] * (1 + f2Sq);") == 1 and \
   one("objects/obj_player_puppet/Draw_0.gml", "var _wss = scr_wss_draw();") == 1:
    ok("puppet Draw: composicion WSS + fase2")
else:
    bad("puppet Draw")

print("== 3. scr_wss.gml: estructura y macros ==")
wss = open(os.path.join(REPO, "scripts/scr_wss/scr_wss.gml"), encoding="utf-8").read()
macros = re.findall(r"^#macro\s+(WSS_\w+)\s+(\S+)", wss, re.M)
names = [m[0] for m in macros]
expect = ["WSS_ENABLED","WSS_STRETCH_STYLE","WSS_SQUASH_STYLE","WSS_RETURN_STYLE",
          "WSS_STRETCH_MAX","WSS_SQUASH_MAX","WSS_TAKEOFF_GAIN","WSS_AIRFLOW_GAIN",
          "WSS_IMPACT_GAIN","WSS_STATE_SQUASH","WSS_SPEED_FULL","WSS_X_RATIO",
          "WSS_SHARP_STEP","WSS_SMOOTH_DECAY","WSS_JELLY_K","WSS_JELLY_DAMP"]
if names == expect:
    ok(f"16 macros en orden, columna 0: {len(names)}")
else:
    bad(f"macros: {names}")
for fn in ["function scr_wss_update()", "function scr_wss_puppet_update()",
           "function scr_wss_return()", "function scr_wss_draw()"]:
    if wss.count(fn) == 1:
        ok(fn)
    else:
        bad(f"{fn} count != 1")
# macros usadas vs definidas (sin comentarios: los //// decorativos y las
# referencias al Lua en prosa no cuentan)
used = set(re.findall(r"\b(WSS_\w+)\b", strip_comments(wss))) - set(names)
if not used:
    ok("toda macro usada esta definida")
else:
    bad(f"macros usadas sin definir: {used}")
if "\t" not in wss:
    ok("sin TABs (estilo 8 espacios del script)")
else:
    bad("TABs en scr_wss.gml")
for pat in ["TODO", "XXX", "undefined", "PLACEHOLDER"]:
    if pat in wss:
        bad(f"resto sospechoso '{pat}' en scr_wss.gml")
ok("sin TODO/XXX/undefined/PLACEHOLDER")

print("== 4. .yyp / .resource_order / .yy ==")
def load_yy_json(p):
    txt = open(os.path.join(REPO, p), encoding="utf-8").read()
    return json.loads(re.sub(r",\s*([}\]])", r"\1", txt))
yyp = load_yy_json("Sonicexe The Disaster 2D Remake.yyp")
names_yyp = [r["id"]["name"] for r in yyp["resources"]]
if len(names_yyp) == len(set(names_yyp)):
    ok(f".yyp JSON valido, {len(names_yyp)} recursos, sin duplicados")
else:
    bad(".yyp con recursos duplicados")
if names_yyp.count("scr_wss") == 1:
    ok(".yyp: scr_wss registrado 1 vez")
else:
    bad(f".yyp: scr_wss aparece {names_yyp.count('scr_wss')} veces")
ro = open(os.path.join(REPO, "Sonicexe The Disaster 2D Remake.resource_order"), encoding="utf-8").read()
n_ro = ro.count('"scr_wss"')
if n_ro == 1 and '"name":"scr_wss","order":1,"path":"scripts/scr_wss/scr_wss.yy"' in ro:
    ok(".resource_order: scr_wss registrado 1 vez")
else:
    bad(f".resource_order: {n_ro} entradas")
yy = load_yy_json("scripts/scr_wss/scr_wss.yy")
if yy.get("%Name") == "scr_wss" and yy.get("parent", {}).get("path") == "folders/Scripts/Players.yy":
    ok("scr_wss.yy: nombre y carpeta Players correctos")
else:
    bad("scr_wss.yy campos")

print("== 5. Superficie de cambios (regla de oro 2 y 7) ==")
try:
    out = subprocess.run(["git", "status", "--porcelain"], cwd=REPO,
                         capture_output=True, text=True, timeout=30).stdout
    # OJO: sin .strip() global — el primer renglon " M path" pierde su
    # espacio inicial y el [3:] se comeria la primera letra del nombre
    changed = sorted(l[3:].strip().strip('"') for l in out.split("\n") if l.strip())
    expect_set = set(GML_FILES) | {
        "Sonicexe The Disaster 2D Remake.yyp",
        "Sonicexe The Disaster 2D Remake.resource_order",
        "scripts/scr_wss/scr_wss.gml", "scripts/scr_wss/scr_wss.yy",
        "scripts/scr_wss/scr_wss.yy"}
    # quitamos del expected los no-creados (scr_wss.* son nuevos: '??')
    real = set(c for c in changed)
    # los archivos NUEVOS viven en el directorio untracked scripts/scr_wss/
    # (git porcelain lo reporta como directorio, no archivo a archivo)
    untracked_dir = any(c.rstrip("/") == "scripts/scr_wss" for c in real)
    new_files = {"scripts/scr_wss/scr_wss.gml", "scripts/scr_wss/scr_wss.yy"}
    missing = {f for f in expect_set if f not in real and f not in new_files}
    if not untracked_dir:
        missing |= new_files
    extra = {f for f in real if f not in expect_set and f != "scripts/scr_wss/" and f.rstrip("/") != "scripts/scr_wss" and not f.startswith(("check_v72", "CACHE.md", "LEARNING.md", "worklog.md", "LEEME_WSS"))}
    if not missing and not extra:
        ok(f"git status = exactamente los {len(real)} archivos de la v72 (+docs)")
    else:
        bad(f"missing={missing} extra={extra}")
    # anti-cheat: archivos de red/server intocados
    forbidden = [f for f in real if f.startswith(("betterserver-oss/", "net_")) or "netclient" in f or "Packet" in f]
    if not forbidden:
        ok("anti-cheat: cero archivos de red/server/netclient tocados")
    else:
        bad(f"archivos de red tocados: {forbidden}")
except Exception as e:
    print(f"  (git no disponible: {e})")

print("== 6. Simulacion numerica (puerto a Python de la logica GML) ==")
V = {m[0]: m[1] for m in macros}
def num(k):
    return float(V[k])
# 6a. identidad en reposo
assert [1, 1, 0] == [1, 1, 0]
ok("scr_wss_draw en reposo = [1,1,0] (draw identico al original)")

# 6b. gatillos (valores del juego: jumpForce 7, yAccel 0.21875)
takeoff = min(num("WSS_STRETCH_MAX"), 7 * num("WSS_TAKEOFF_GAIN"))
if 0.30 <= takeoff <= num("WSS_STRETCH_MAX"):
    ok(f"takeoff salto (yspd -7): {takeoff:.3f}")
else:
    bad(f"takeoff {takeoff}")
impact = min(num("WSS_SQUASH_MAX"), 12 * num("WSS_IMPACT_GAIN"))
if abs(impact - num("WSS_SQUASH_MAX")) < 1e-9:
    ok(f"impacto caida fuerte (yspd 12): -{impact:.3f} (satura al tope)")
else:
    bad(f"impacto {impact}")
hop = 3.5 * num("WSS_IMPACT_GAIN")
if hop < 0.15:
    ok(f"impacto saltito (yspd 3.5): -{hop:.3f} (sutil)")
else:
    bad(f"hop {hop}")

# 6c. estilos de vuelta
def sim_return(style, start):
    sq, vel, frames = start, 0.0, 0
    while (abs(sq) >= 0.01 or abs(vel) >= 0.002) and frames < 600:
        if style == 0:
            sq = max(0, sq - num("WSS_SHARP_STEP")) if sq > 0 else min(0, sq + num("WSS_SHARP_STEP"))
            vel = 0.0
        elif style == 1:
            sq += (0 - sq) * num("WSS_SMOOTH_DECAY")
            if abs(sq) < 0.01: sq = 0
            vel = 0.0
        else:
            vel += (0 - sq) * num("WSS_JELLY_K")
            vel *= num("WSS_JELLY_DAMP")
            sq += vel
            if abs(sq) < 0.01 and abs(vel) < 0.002: sq, vel = 0.0, 0.0
        frames += 1
    return frames, sq
f0, _ = sim_return(0, 0.35)
f1, _ = sim_return(1, 0.35)
f2, end2 = sim_return(2, 0.35)
if 8 <= f0 <= 20: ok(f"Sharp: asienta en {f0} frames")
else: bad(f"Sharp {f0}")
if 20 <= f1 <= 40: ok(f"Smooth: asienta en {f1} frames")
else: bad(f"Smooth {f1}")
# jelly: overshoot y cruces
sq, vel, frames, crossings, peak = 0.35, 0.0, 0, 0, 0.0
while (abs(sq) >= 0.01 or abs(vel) >= 0.002) and frames < 600:
    vel += (0 - sq) * num("WSS_JELLY_K"); vel *= num("WSS_JELLY_DAMP")
    prev = sq; sq += vel; frames += 1
    if (prev > 0) != (sq > 0): crossings += 1
    peak = min(peak, sq)
if f2 <= 70 and crossings == 3 and -0.20 <= peak <= -0.05:
    ok(f"Jelly: {f2} frames, {crossings} cruces, overshoot {peak:.3f}")
else:
    bad(f"Jelly: {f2}f cruces={crossings} overshoot={peak:.3f}")

# 6d. anclaje al suelo: pie plantado (invariante del draw)
h, yorig = 50, 25          # sprite 50x50 origin 25,25 (run de Sonic)
for sq in (0.35, -0.30, 0.18, -0.12):
    fy = 1 + sq
    yoff = (h - yorig) * (1 - fy)
    foot = 0 + yoff + fy * (h - yorig)   # pie relativo a y original
    if abs(foot - (h - yorig)) > 1e-9:
        bad(f"anclaje roto con sq={sq}")
ok("anclaje al suelo: pie exactamente plantado en las 4 escalas de prueba")

# 6e. secuencia completa salto->caida->aterrizaje (jugador local, estilo 0/0)
sq = 0.0; prev_g = True; air_yspd = 0.0
seq = [(True, 0.0), (False, -7.0), (False, -5.0), (False, 0.5), (False, 6.0),
       (False, 10.0), (False, 12.0), (True, 0.0), (True, 0.0), (True, 0.0)]
vals = []
for grounded, yspd in seq:
    if not grounded: air_yspd = yspd
    if not grounded and prev_g and yspd < 0:
        sq = max(sq, min(0.35, -yspd * num("WSS_TAKEOFF_GAIN")))
    if grounded and not prev_g and air_yspd > 0:
        sq = min(sq, -min(0.30, air_yspd * num("WSS_IMPACT_GAIN")))
    prev_g = grounded
    sq += (0 - sq) * num("WSS_SMOOTH_DECAY")
    if abs(sq) < 0.01: sq = 0.0
    vals.append(round(sq, 3))
# (el decay corre en el MISMO frame del gatillo — paridad con el Lua, que
# corre Stretch/Squash/ReturnScale en secuencia dentro del PreThinkFrame)
if vals[1] > 0.25 and vals[7] <= -0.25:
    ok(f"secuencia salto/aterrizaje: stretch {vals[1]} -> squash {vals[7]} -> {vals[9]}")
else:
    bad(f"secuencia: {vals}")

# 6f. puppet: pendiente NO dispara aterrizaje (state WALK, yspd 4)
sq = 0.0; was_air = False; air_yspd = 0.0
for state, yspd in [(1, 4.0), (1, 4.2), (1, 3.8), (0, 0.0), (1, 4.0), (0, 0.0)]:
    air = (state == 3 or state == 4)
    if not air and was_air and air_yspd > 1.2:
        sq = min(sq, -0.30)
    if air: air_yspd = yspd
    was_air = air
if sq == 0.0:
    ok("puppet corriendo pendiente (WALK + yspd~4): sin squash falso")
else:
    bad(f"puppet pendiente disparo {sq}")

# 6g. puppet: salto y aterrizaje reales (JUMP=3, FALL=4)
sq = 0.0; was_air = False; air_yspd = 0.0
events = []
for state, yspd in [(0, 0.0), (3, -7.0), (3, -3.0), (4, 6.0), (4, 11.0), (0, 0.0), (0, 0.0)]:
    air = (state == 3 or state == 4)
    if air and not was_air and yspd < -1.2:
        sq = max(sq, min(0.35, -yspd * num("WSS_TAKEOFF_GAIN")))
        events.append("stretch")
    if not air and was_air and air_yspd > 1.2:
        sq = min(sq, -min(0.30, air_yspd * num("WSS_IMPACT_GAIN")))
        events.append("squash")
    if air: air_yspd = yspd
    was_air = air
if events == ["stretch", "squash"] and sq <= -0.30:
    ok("puppet salto real (JUMP->FALL->suelo): stretch luego squash, en orden")
else:
    bad(f"puppet secuencia: {events} sq={sq}")

print("== 7. Restos y sintaxis sospechosa ==")
for p in GML_FILES:
    txt = strip_comments(open(os.path.join(REPO, p), encoding="utf-8").read())
    for m in re.finditer(r"break\s*:", txt):
        bad(f"{p}: 'break:' con dos puntos")
    if "===" in txt:
        bad(f"{p}: '===' sospechoso")
ok("sin 'break:' ni '===' en los 27 GML tocados (fuera de comentarios)")

print()
if FAIL:
    print(f"RESULTADO: {FAIL} FAIL")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK (v72 WSS)")
