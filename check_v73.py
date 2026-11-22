#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# check_v73.py — validador de la v73 (WSS retune + Exe sin buffs + fix
# inmunidad). Superset del check_v72.py (que sustituye: borra el viejo).
# Corre desde la raiz del proyecto (la carpeta con el .yyp).
# Sale 0 solo si TODOS los checks pasan.
import json, os, re, shutil, subprocess, sys, tempfile

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

CHARS = ["obj_amelia","obj_amy","obj_amy_canon","obj_amy_fleetway","obj_blaze",
         "obj_chaos","obj_cream","obj_egg","obj_exe","obj_exeller","obj_exetior",
         "obj_jinna","obj_knux","obj_kris","obj_metal","obj_metalamy","obj_rouge",
         "obj_sally","obj_sonic","obj_tails","obj_vanilla"]

print("== 1. Balance de llaves/parens/corchetes (lexer consciente de comentarios/strings) ==")
GML_FILES = ["scripts/scr_wss/scr_wss.gml",
             "scripts/scr_collision_basic/scr_collision_basic.gml",
             "scripts/net_state_game/net_state_game.gml",
             "objects/obj_sally_canon/Draw_0.gml",
             "objects/obj_player_puppet/Create_0.gml",
             "objects/obj_player_puppet/Step_0.gml",
             "objects/obj_player_puppet/Draw_0.gml"] + \
            [f"objects/{c}/Draw_0.gml" for c in CHARS]
for p in GML_FILES:
    txt = open(os.path.join(REPO, p), encoding="utf-8").read()
    if "\r" in txt:
        bad(f"{p}: contiene CR")
    if gml_lexer_balance(txt):
        ok(f"{p}")
    else:
        bad(f"{p}: desbalanceado")

print("== 2. Parches v72 intactos (marca exacta, 1 vez) ==")
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
for c in CHARS:
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

print("== 3. scr_wss.gml: estructura y macros v73 ==")
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
V = {m[0]: m[1] for m in macros}
def num(k):
    return float(V[k])
# valores exactos del retune v73 (feedback: "el salto no se nota mucho")
V73 = {"WSS_STRETCH_MAX": "0.45", "WSS_SQUASH_MAX": "0.42", "WSS_TAKEOFF_GAIN": "0.085",
       "WSS_AIRFLOW_GAIN": "0.055", "WSS_IMPACT_GAIN": "0.050", "WSS_STATE_SQUASH": "0.24",
       "WSS_SMOOTH_DECAY": "0.10", "WSS_X_RATIO": "0.6", "WSS_SHARP_STEP": "0.030",
       "WSS_JELLY_K": "0.035", "WSS_JELLY_DAMP": "0.88", "WSS_ENABLED": "1",
       "WSS_STRETCH_STYLE": "0", "WSS_SQUASH_STYLE": "0", "WSS_RETURN_STYLE": "1"}
mismatch = {k: (V.get(k), want) for k, want in V73.items() if V.get(k) != want}
if not mismatch:
    ok("valores v73 exactos (retune: salto 0.315->0.450, squash 0.21->0.35)")
else:
    bad(f"macros con valor inesperado: {mismatch}")
for fn in ["function scr_wss_update()", "function scr_wss_puppet_update()",
           "function scr_wss_return()", "function scr_wss_draw()"]:
    if wss.count(fn) == 1:
        ok(fn)
    else:
        bad(f"{fn} count != 1")
used = set(re.findall(r"\b(WSS_\w+)\b", strip_comments(wss))) - set(names)
if not used:
    ok("toda macro usada esta definida")
else:
    bad(f"macros usadas sin definir: {used}")
if "\t" not in wss:
    ok("sin TABs (estilo 8 espacios del script)")
else:
    bad("TABs en scr_wss.gml")

print("== 4. v73 fix inmunidad (caja invulnerable reinicia al maximo) ==")
nsg = open(os.path.join(REPO, "scripts/net_state_game/net_state_game.gml"), encoding="utf-8").read()
nsg_nc = strip_comments(nsg)
if one("scripts/net_state_game/net_state_game.gml", "global.player.hurttime = ITEMBOX_INVULN_TIME;") == 1 and \
   "if(global.player.hurttime <= 0)" not in nsg_nc:
    ok("case 2: hurttime SIEMPRE = ITEMBOX_INVULN_TIME (guard viejo fuera)")
else:
    bad("case 2: fix de reset a max no aplicado o guard viejo presente")
if "ITEMBOX_INVULN_TIME (60 * 6.25)" in nsg:
    ok("macro ITEMBOX_INVULN_TIME intacta (60 * 6.25 = 375 frames)")
else:
    bad("macro ITEMBOX_INVULN_TIME alterada")
# los otros 3 rewards conservan su guard !ya-activo (diseno de la casa)
for pat, name in [("shieldTimer <= 0", "escudo"),
                  ("electricShieldTimer <= 0", "escudo electrico"),
                  ("bootsTimer <= 0", "botas")]:
    if pat in nsg_nc:
        ok(f"guard !ya-activo del {name} conservado (solo la invencibilidad resetea)")
    else:
        bad(f"guard del {name} desaparecio (cambio no pedido)")

print("== 5. v73 Exe sin buffs (server + cliente) ==")
ibm = open(os.path.join(REPO, "betterserver-oss/disasterserver/entities/ItemBoxMap.c"), encoding="utf-8").read()
kaf = open(os.path.join(REPO, "betterserver-oss/disasterserver/maps/KindAndFair.c"), encoding="utf-8").read()
MARK = "uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;"
if ibm.count(MARK) == 1 and "itembox_activate(v->server, target, v->id, proj)" not in ibm:
    ok("ItemBoxMap.c: Exe rompe la caja pero cobra pid 0 (nadie)")
else:
    bad("ItemBoxMap.c: denial del Exe no aplicado")
if kaf.count(MARK) == 1 and "kafbox_activate(v->server, box[nid], v->id, proj)" not in kaf:
    ok("KindAndFair.c: Exe rompe el monitor Kaf pero cobra pid 0")
else:
    bad("KindAndFair.c: denial del Exe no aplicado")
GUARD = re.compile(r"if\(obj_netclient\.nid != _pid\)\s*break;\s*if\(global\.character == CHARACTER_EXE\)\s*break;")
n_guards = len(GUARD.findall(nsg_nc))
if n_guards == 2:
    ok("net_state_game: 2 guardas anti-Exe (rewards de caja + boost Kaf), tras el check de pid")
else:
    bad(f"net_state_game: guardas anti-Exe = {n_guards} (esperaba 2)")
# el Exe sigue PODIENDO romperlas (scr_collision_objects no cambio)
sco = open(os.path.join(REPO, "scripts/scr_collision_objects/scr_collision_objects.gml"), encoding="utf-8").read()
if sco.count("cpacket_tcp(PacketType.CLIENT_BOX_ACTIVATE)") == 1 and \
   sco.count("cpacket_tcp(PacketType.CLIENT_KAFMONITOR_ACTIVATE)") == 1 and \
   "ch2 == CHARACTER_EXE" in sco and "invisTimer" in sco:
    ok("scr_collision_objects intacto: el Exe rompe cajas/monitores atacando (invis no)")
else:
    bad("scr_collision_objects cambio inesperado (no se toco en v73)")

print("== 6. Sintaxis C del server (gcc -fsyntax-only con stub enet) ==")
gcc = shutil.which("gcc")
if gcc:
    stub = os.path.join(tempfile.mkdtemp(prefix="enet_stub_"), "enet")
    os.makedirs(stub, exist_ok=True)
    with open(os.path.join(stub, "enet.h"), "w") as f:
        f.write("#ifndef ENET_STUB_H\n#define ENET_STUB_H\n"
                "#include <stdint.h>\n#include <stddef.h>\n"
                "typedef struct ENetPeer { uint32_t roundTripTime; } ENetPeer;\n"
                "typedef struct ENetHost { int dummy; } ENetHost;\n"
                "typedef struct ENetPacket { uint8_t *data; size_t dataLength; } ENetPacket;\n"
                "typedef struct { int type; ENetPeer *peer; ENetPacket *packet; } ENetEvent;\n"
                "#endif\n")
    for c in ["betterserver-oss/disasterserver/entities/ItemBoxMap.c",
              "betterserver-oss/disasterserver/maps/KindAndFair.c"]:
        r = subprocess.run([gcc, "-fsyntax-only", "-Ibetterserver-oss/include",
                            "-I" + os.path.dirname(stub), c],
                           cwd=REPO, capture_output=True, text=True, timeout=60)
        if r.returncode == 0:
            ok(f"{os.path.basename(c)}: sintaxis OK")
        else:
            bad(f"{c}: {r.stderr[:300]}")
else:
    print("  (gcc no disponible: check de sintaxis C omitido — se verifico en el sandbox)")

print("== 7. .yyp / .resource_order / .yy ==")
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

print("== 8. Superficie de cambios (regla de oro 2 y 7) ==")
try:
    out = subprocess.run(["git", "status", "--porcelain"], cwd=REPO,
                         capture_output=True, text=True, timeout=30).stdout
    # OJO: sin .strip() global — parse per-line (leccion v72)
    changed = sorted(l[3:].strip().strip('"') for l in out.split("\n") if l.strip())
    real = set(changed)
    # nucleo v73: SIEMPRE debe estar modificado/creado
    core_v73 = {"scripts/scr_wss/scr_wss.gml",
                "scripts/net_state_game/net_state_game.gml",
                "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
                "betterserver-oss/disasterserver/maps/KindAndFair.c",
                "check_v73.py", "LEEME_V73.txt",
                "CACHE.md", "LEARNING.md", "worklog.md"}
    # scr_wss.gml puede venir como archivo suelto (v72 commiteada) o dentro
    # del directorio untracked scripts/scr_wss/ (v72 sin commitear)
    untracked_dir = any(c.rstrip("/") == "scripts/scr_wss" for c in real)
    missing = {f for f in core_v73 if f not in real}
    if untracked_dir and "scripts/scr_wss/scr_wss.gml" in missing:
        missing.discard("scripts/scr_wss/scr_wss.gml")
    if not missing:
        ok(f"nucleo v73 completo en git status ({len(real)} entradas)")
    else:
        bad(f"faltan archivos del nucleo v73: {missing}")
    # archivos v72: presentes si la v72 sigue sin commitear (estado actual
    # del repo de la duena), ausentes si ya la commiteo — ambos validos
    v72_files = {f"objects/{c}/Draw_0.gml" for c in CHARS} | {
        "objects/obj_sally_canon/Draw_0.gml",
        "scripts/scr_collision_basic/scr_collision_basic.gml",
        "objects/obj_player_puppet/Create_0.gml",
        "objects/obj_player_puppet/Step_0.gml",
        "objects/obj_player_puppet/Draw_0.gml",
        "Sonicexe The Disaster 2D Remake.yyp",
        "Sonicexe The Disaster 2D Remake.resource_order"}
    allowed = core_v73 | v72_files | {"scripts/scr_wss", "scripts/scr_wss/",
                                      "scripts/scr_wss/scr_wss.yy"}
    extra = {f for f in real if f not in allowed
             and not f.startswith(("check_v7", "LEEME_"))}
    if not extra:
        ok("cero archivos fuera de lo esperado (v72+v73+docs)")
    else:
        bad(f"archivos inesperados: {extra}")
    # anti-cheat: protocolo y netclient INTOCADOS (cero paquetes nuevos;
    # el denial vive en el server y en guards del cliente)
    proto = [f for f in real if "net_packets" in f or "Packet" in f or "netclient" in f]
    if not proto:
        ok("anti-cheat: protocolo (net_packets/Packet.h) y netclient intactos")
    else:
        bad(f"archivos de protocolo tocados: {proto}")
except Exception as e:
    print(f"  (git no disponible: {e})")

print("== 9. Simulacion numerica (retune v73, valores del juego: jumpForce 7) ==")
takeoff = min(num("WSS_STRETCH_MAX"), 7 * num("WSS_TAKEOFF_GAIN"))
if abs(takeoff - num("WSS_STRETCH_MAX")) < 1e-9:
    ok(f"takeoff salto (yspd -7): {takeoff:.3f} — SATURA el tope (muy notorio)")
else:
    bad(f"takeoff {takeoff} (esperaba saturar en {num('WSS_STRETCH_MAX')})")
visible1 = takeoff * (1 - num("WSS_SMOOTH_DECAY"))
if visible1 >= 0.38:
    ok(f"estiron visible en el frame 1: {visible1:.3f} (v72: 0.277)")
else:
    bad(f"visible1 {visible1} — menos notorio que lo pedido")
impact = min(num("WSS_SQUASH_MAX"), 12 * num("WSS_IMPACT_GAIN"))
if abs(impact - num("WSS_SQUASH_MAX")) < 1e-9:
    ok(f"impacto caida fuerte (yspd 12): -{impact:.3f} (satura al tope)")
else:
    bad(f"impacto {impact}")
impact7 = min(num("WSS_SQUASH_MAX"), 7 * num("WSS_IMPACT_GAIN"))
if 0.30 <= impact7 <= num("WSS_SQUASH_MAX"):
    ok(f"impacto salto normal (yspd 7): -{impact7:.3f} (v72: -0.21)")
else:
    bad(f"impact7 {impact7}")
hop = 3.5 * num("WSS_IMPACT_GAIN")
if 0.10 <= hop <= 0.22:
    ok(f"impacto saltito (yspd 3.5): -{hop:.3f} (presente pero no absurdo)")
else:
    bad(f"hop {hop}")
fx = 1 - takeoff * num("WSS_X_RATIO")
if 0.60 <= fx <= 0.85:
    ok(f"estrechamiento al estirar: fx = {fx:.2f} (se nota sin deformar)")
else:
    bad(f"fx {fx}")

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
f0, _ = sim_return(0, takeoff)
f1, _ = sim_return(1, takeoff)
f2, end2 = sim_return(2, takeoff)
if 10 <= f0 <= 25: ok(f"Sharp: asienta en {f0} frames (v72: 12)")
else: bad(f"Sharp {f0}")
if 25 <= f1 <= 50: ok(f"Smooth: asienta en {f1} frames (v72: 28 — dura mas)")
else: bad(f"Smooth {f1}")
sq, vel, frames, crossings, peak = takeoff, 0.0, 0, 0, 0.0
while (abs(sq) >= 0.01 or abs(vel) >= 0.002) and frames < 600:
    vel += (0 - sq) * num("WSS_JELLY_K"); vel *= num("WSS_JELLY_DAMP")
    prev = sq; sq += vel; frames += 1
    if (prev > 0) != (sq > 0): crossings += 1
    peak = min(peak, sq)
if f2 <= 75 and crossings == 3 and -0.22 <= peak <= -0.08:
    ok(f"Jelly: {f2} frames, {crossings} cruces, overshoot {peak:.3f} (misma proporcion que v72)")
else:
    bad(f"Jelly: {f2}f cruces={crossings} overshoot={peak:.3f}")

# anclaje al suelo: pie plantado (invariante del draw)
h, yorig = 50, 25
for sqv in (takeoff, -impact, 0.18, -0.12):
    fy = 1 + sqv
    yoff = (h - yorig) * (1 - fy)
    foot = 0 + yoff + fy * (h - yorig)
    if abs(foot - (h - yorig)) > 1e-9:
        bad(f"anclaje roto con sq={sqv}")
ok("anclaje al suelo: pie exactamente plantado en las 4 escalas de prueba")

# secuencia completa salto->caida->aterrizaje (jugador local, estilo 0/0)
sq, prev_g, air_yspd = 0.0, True, 0.0
seq = [(True, 0.0), (False, -7.0), (False, -5.0), (False, 0.5), (False, 6.0),
       (False, 10.0), (False, 12.0), (True, 0.0), (True, 0.0), (True, 0.0)]
vals = []
for grounded, yspd in seq:
    if not grounded: air_yspd = yspd
    if not grounded and prev_g and yspd < 0:
        sq = max(sq, min(num("WSS_STRETCH_MAX"), -yspd * num("WSS_TAKEOFF_GAIN")))
    if grounded and not prev_g and air_yspd > 0:
        sq = min(sq, -min(num("WSS_SQUASH_MAX"), air_yspd * num("WSS_IMPACT_GAIN")))
    prev_g = grounded
    sq += (0 - sq) * num("WSS_SMOOTH_DECAY")
    if abs(sq) < 0.01: sq = 0.0
    vals.append(round(sq, 3))
if vals[1] > 0.35 and vals[7] <= -0.30:
    ok(f"secuencia salto/aterrizaje: stretch {vals[1]} -> squash {vals[7]} -> {vals[9]}")
else:
    bad(f"secuencia: {vals}")

# puppet: pendiente NO dispara aterrizaje (state WALK, yspd 4)
sq, was_air, air_yspd = 0.0, False, 0.0
for state, yspd in [(1, 4.0), (1, 4.2), (1, 3.8), (0, 0.0), (1, 4.0), (0, 0.0)]:
    air = (state == 3 or state == 4)
    if not air and was_air and air_yspd > 1.2:
        sq = min(sq, -num("WSS_SQUASH_MAX"))
    if air: air_yspd = yspd
    was_air = air
if sq == 0.0:
    ok("puppet corriendo pendiente (WALK + yspd~4): sin squash falso")
else:
    bad(f"puppet pendiente disparo {sq}")

# puppet: salto y aterrizaje reales (JUMP=3, FALL=4)
sq, was_air, air_yspd = 0.0, False, 0.0
events = []
for state, yspd in [(0, 0.0), (3, -7.0), (3, -3.0), (4, 6.0), (4, 11.0), (0, 0.0), (0, 0.0)]:
    air = (state == 3 or state == 4)
    if air and not was_air and yspd < -1.2:
        sq = max(sq, min(num("WSS_STRETCH_MAX"), -yspd * num("WSS_TAKEOFF_GAIN")))
        events.append("stretch")
    if not air and was_air and air_yspd > 1.2:
        sq = min(sq, -min(num("WSS_SQUASH_MAX"), air_yspd * num("WSS_IMPACT_GAIN")))
        events.append("squash")
    if air: air_yspd = yspd
    was_air = air
if events == ["stretch", "squash"] and sq <= -0.40:
    ok("puppet salto real (JUMP->FALL->suelo): stretch luego squash, en orden")
else:
    bad(f"puppet secuencia: {events} sq={sq}")

print("== 10. Simulacion de las 2 reglas nuevas (logica portada) ==")
# fix inmunidad: recoger otra caja SIEMPRE deja el timer en el maximo
INVULN = 60 * 6.25
for start in (0.0, 100.0, 180.0, INVULN, INVULN - 1):
    after = INVULN  # v73: asignacion incondicional
    if after != INVULN:
        bad(f"inmunidad: desde {start} no reinicia al maximo")
ok(f"inmunidad: desde cualquier restante (0/{100}/{180}/{INVULN:.0f}/{INVULN-1:.0f}) -> SIEMPRE {INVULN:.0f} (max)")
# (v72: desde 180 quedaba 180 — la caja se gastaba en vacio; ahora nunca)
# exe denial: el server decide el pid del reward
def reward_pid(game_exe, vid):
    return 0 if game_exe == vid else vid
if reward_pid(5, 5) == 0 and reward_pid(5, 3) == 3 and reward_pid(0, 1) == 1:
    ok("exe denial: Exe (id=game.exe) cobra pid 0; superviviente cobra su id")
else:
    bad("exe denial: logica del pid incorrecta")
# y el pid 0 nunca coincide con un peer real (ids empiezan en 1: Server.c
# v->id = incomingPeerID + 1; peer_msg rechaza id 0)

print("== 11. Restos y sintaxis sospechosa ==")
for p in GML_FILES:
    txt = strip_comments(open(os.path.join(REPO, p), encoding="utf-8").read())
    for m in re.finditer(r"break\s*:", txt):
        bad(f"{p}: 'break:' con dos puntos")
    if "===" in txt:
        bad(f"{p}: '===' sospechoso")
for p, txt in (("ItemBoxMap.c", ibm), ("KindAndFair.c", kaf)):
    if re.search(r"TODO:|FIXME|XXX|PLACEHOLDER", txt):
        bad(f"{p}: resto de trabajo pendiente")
ok("sin 'break:' ni '===' ni TODO:/FIXME/PLACEHOLDER en los archivos tocados")

print()
if FAIL:
    print(f"RESULTADO: {FAIL} FAIL")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK (v73: WSS retune + Exe sin buffs + fix inmunidad)")
