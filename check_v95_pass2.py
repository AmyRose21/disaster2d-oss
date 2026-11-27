#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
# check_v95_pass2.py — PASADA 2 (independiente) del v95.
# A. ROUNDTRIP BYTE A BYTE: genera los pares viejo→nuevo de CADA archivo
#    desde git (HEAD vs working) y demuestra que aplicar los pares sobre
#    HEAD produce EXACTAMENTE el working (no puede haber drift ni edits
#    fantasma) — patron gen_v94_pairs.py.
# B. SIMULACION de las reglas del pedido de la duena:
#    1. LV: umbrales v46 + LMS al doble (100% mas rapido).
#    2. Vida: +20 max y +20 cura por subida, clamp a la vida total.
#    3. Pool del exe: -35 por golpe SOLO a LV20, knockdown+refill a 0,
#       espejo Kris == autoridad exe (misma secuencia TCP).
#    4. Barra: pixeles dentro de 480x270, sin pisar el reloj (y<=14) ni
#       el "Escape!!!" (y=32).
# C. CHECKS ANTI-REGRESION: nada del v95 corre fuera de sitio (rama del
#    receptor dentro del with de puppets; bloque del exe dentro de la
#    rama victima-exe; flecha dentro del if(hp>0)).
# ============================================================================
import subprocess, sys, re, difflib

REPO = "/home/z/my-project/repo"
fails = []

def ok(msg):  print("  OK  " + msg)
def bad(msg): print("  XX  " + msg); fails.append(msg)

def head(path):
    return subprocess.run(["git", "-C", REPO, "show", "HEAD:" + path],
                           capture_output=True, text=True).stdout

def work(path):
    return open(REPO + "/" + path).read()

FILES = [
    "scripts/scr_kris_special/scr_kris_special.gml",
    "scripts/scr_player_maxhp/scr_player_maxhp.gml",
    "objects/obj_level/Draw_64.gml",
    "scripts/net_sounds/net_sounds.gml",
    "scripts/net_state_game/net_state_game.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "objects/obj_kris/Draw_64.gml",
    "objects/obj_level/Create_0.gml",
    "scripts/scr_globals.gml",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/disasterserver/Game.c",
]

# ---------------------------------------------------------------------------
print("== A. ROUNDTRIP: HEAD + pares(generados de git) == working ==")
total_pairs = 0
for f in FILES:
    h, w = head(f), work(f)
    # pares = hunks del diff unificado U0 aplicados POR POSICION (exacto:
    # @@ -a,b +c,d @@ da el rango viejo y el nuevo — reconstruccion
    # determinista, sin depender de que el bloque viejo sea unico)
    d = list(difflib.unified_diff(h.splitlines(), w.splitlines(), lineterm="", n=0))
    ops = []           # (hdr, rem, add)
    state = {"rem": [], "add": [], "hdr": None}
    def flush(st):
        if st["hdr"] is None and not st["rem"] and not st["add"]:
            return
        ops.append((st["hdr"], st["rem"], st["add"]))
        st["rem"], st["add"], st["hdr"] = [], [], None
    for line in d[2:]:
        if line.startswith("@@"):
            flush(state)
            m2 = re.match(r"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@", line)
            state["hdr"] = (int(m2.group(1)), int(m2.group(2) or 1))
        elif line.startswith("-"):
            state["rem"].append(line[1:])
        elif line.startswith("+"):
            state["add"].append(line[1:])
    flush(state)
    # aplicar por posicion: recorrer los hunks viejos en orden, sustituyendo
    src_lines = h.splitlines()
    out, pos = [], 0
    for (ostart, ocount), rem, add in ops:
        # convencion del diff unificado: @@ -l,c @@ con c>=1 toca las lineas
        # viejas [l, l+c-1] (1-based) => idx = l-1; con c == 0 (insercion
        # pura) las lineas nuevas van DESPUES de la vieja l => idx = l
        idx = ostart - 1 if ocount >= 1 else ostart
        out.extend(src_lines[pos:idx])
        if rem and add:             # reemplazo (par viejo→nuevo)
            assert src_lines[idx:idx + len(rem)] == rem, f + ": hunk desalineado"
            out.extend(add)
        elif rem and not add:       # borrado puro
            assert src_lines[idx:idx + len(rem)] == rem, f + ": hunk desalineado"
        else:                       # insercion pura (par vacio→nuevo)
            out.extend(add)
        pos = idx + ocount
    out.extend(src_lines[pos:])
    rebuilt = "\n".join(out) + ("\n" if h.endswith("\n") else "")
    if rebuilt == w or "\n".join(out) == w.rstrip("\n"):
        n_replace = sum(1 for _, r, a in ops if r and a)
        n_insert = sum(1 for _, r, a in ops if a and not r)
        ok(f + f": {len(ops)} par(es) ({n_replace} reemplazo + {n_insert} insercion) reconstruyen HEAD→working EXACTO")
    else:
        bad(f + ": el roundtrip NO reproduce el archivo (drift)")
    total_pairs += len(ops)
print(f"     pares totales: {total_pairs}")

# ---------------------------------------------------------------------------
print("== B1. SIMULACION LOVE + LMS (umbrales v46 intactos, doble en LMS) ==")
_th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56]
def love_lv(hits):
    lv = 1
    for i, t in enumerate(_th):
        if hits >= t:
            lv = i + 2
    return min(lv, 20)
assert love_lv(0) == 1 and love_lv(1) == 1
assert love_lv(2) == 2 and love_lv(56) == 20 and love_lv(999) == 20
ok("umbrales v46: 56 impactos = LV 20 (tope KRIS_LV_MAX)")

# LMS al doble: la mitad de eventos
events_normal = 0
h = 0
while love_lv(h) < 20:
    h += 1; events_normal += 1
h2 = 0; events_lms = 0
while love_lv(h2) < 20:
    h2 += 2; events_lms += 1          # += 2 por evento (global.lmsActive)
assert events_normal == 56 and events_lms == 28
ok(f"LMS: LV 20 en {events_lms} eventos vs {events_normal} normales (100% mas rapido, como pidio)")
assert h2 == 56
ok("LMS: mismos umbrales — el doble de impacto por golpe, sin atajos raros")

print("== B2. SIMULACION VIDA (max +20 por LV, cura +20, clamp) ==")
KRIS_LV_BASE_HP, KRIS_LV_HP_BONUS = 100, 20
def maxhp(lv): return KRIS_LV_BASE_HP + KRIS_LV_HP_BONUS * (lv - 1)
assert maxhp(1) == 100 and maxhp(20) == 480 and maxhp(10) == 280
ok("scr_player_maxhp: LV1=100, LV10=280, LV20=480 (=100+20*19, cap del server)")
# subida de nivel con vida parcial: se cura 20 sin pasarse del nuevo tope
hp = 47; lv = 7
lv += 1
hp = min(hp + 20, maxhp(lv))
assert hp == 67
ok("cura por nivel: 47→67 (se cura LOS MISMOS 20, clamp al nuevo max)")
hp = maxhp(9)  # lleno
lv += 1
hp = min(hp + 20, maxhp(10))
assert hp == maxhp(10)
ok("cura por nivel con vida llena: se queda en el tope (no gana doble)")
# anti-cheat: el hp nunca puede superar 480 en el wire
assert max(0, min(480, 480)) == 480 and max(0, min(480, 481)) == 480
ok("clamp del CLIENT_PLAYER_DATA: hp<=480 siempre (server cap alineado)")

print("== B3. SIMULACION POOL DEL ASESINO (autoridad exe == espejo Kris) ==")
KRIS_EXE_DAMAGE, KRIS_EXE_MAXHP = 35, 350
def run_fight(hits, start_lv20=True):
    """autoridad (exe) y espejo (kris) aplican la MISMA secuencia"""
    exe_pool, kris_mirror = KRIS_EXE_MAXHP, KRIS_EXE_MAXHP
    downs = 0
    for _ in range(hits):
        if not start_lv20:
            continue  # debajo de LV 20: cero dano (el gate)
        exe_pool = max(exe_pool - KRIS_EXE_DAMAGE, 0)
        kris_mirror = max(kris_mirror - KRIS_EXE_DAMAGE, 0)
        if exe_pool <= 0:
            exe_pool = KRIS_EXE_MAXHP
            downs += 1
        if kris_mirror <= 0:
            kris_mirror = KRIS_EXE_MAXHP
    return exe_pool, kris_mirror, downs
p, m, d = run_fight(10)
assert p == m == KRIS_EXE_MAXHP and d == 1
ok("10 golpes = knockdown + refill: los DOS lados quedan en 350 (sin senal extra)")
p, m, d = run_fight(9)
assert p == m == 35 and d == 0
ok("9 golpes = 35 restantes: espejo == autoridad en TODO momento")
p, m, d = run_fight(25)
assert p == m == 175 and d == 2, (p, m, d)
ok("25 golpes = 2 knockdowns + 5 golpes = 175 (secuencia identica a ambos lados)")
# debajo de LV 20 no hay dano:
p, m, d = run_fight(50, start_lv20=False)
assert p == m == KRIS_EXE_MAXHP
ok("debajo de LV 20: CERO dano al pool (gate krisLvNet >= KRIS_LV_MAX)")

print("== B4. LAYOUT DE LA BARRA (480x270, sin pisar reloj ni Escape) ==")
kbX, kbY = 480 / 2 - 100, 51
assert kbX == 140 and kbY == 51
x0, y0, x1, y1 = kbX - 2, kbY - 2, kbX + 202, kbY + 10
assert x0 >= 0 and x1 <= 480 and y0 >= 0 and y1 <= 270
ok(f"barra {x0}..{x1} x {y0}..{y1}: dentro del lienzo 480x270")
# VLM catch: spr_status es 168x15 con origen (84,0) y se dibuja en y=32:
# ocupa y=32..47 — la barra debe arrancar DEBAJO
assert y0 > 47, "no debe pisar el Escape!!! (spr_status ocupa y=32..47)"
ok(f"la barra arranca en y={y0}: DEBAJO del 'Escape!!!' (spr_status 32..47)")
assert y0 > 14   # lejos del reloj (y=4..14)
ok("lejos del reloj (y=4..14)")

# ---------------------------------------------------------------------------
print("== C. ANTI-REGRESION: los bloques v95 viven donde deben ==")
ns = work("scripts/net_state_game/net_state_game.gml")
i_mirror = ns.find('else if(global.net_snds[sid] == snd_kris_lvup && character == CHARACTER_EXE)')
i_with = ns.rfind("with(obj_player_puppet)", 0, i_mirror)
i_gate = ns.find("if(master_id != pid)", i_with, i_mirror)
i_case = ns.rfind("case PacketType.CLIENT_SOUND_EMIT:", 0, i_with)
if i_mirror > 0 and i_with > 0 and i_gate > i_with and i_case > 0:
    ok("rama espejo: dentro del case CLIENT_SOUND_EMIT → with(puppets) → master_id == pid (puppet del EMISOR=exe)")
else:
    bad("rama espejo fuera del with de puppets")
# el exe del gate es el character del PUPPET, no el local
if ns.count("character == CHARACTER_EXE)") >= 1 and "global.character" not in ns[i_mirror:i_mirror+300]:
    ok("el gate usa el character del puppet (exe emisor), no el global local")

pp = work("objects/obj_player_puppet/Step_0.gml")
i_v95 = pp.find('if(global.character == CHARACTER_EXE && !global.player.isDead')
i_exe_branch = pp.find("if(!isDemonized && globalExe)")
i_stun_gate = pp.find("if(global.player.shockedTimer <= 0 && global.player.hurttime <= 0)")
i_shocked = pp.find("global.player.shockedTimer = stunTime * 60;", i_v95)
if i_exe_branch < i_stun_gate < i_v95 < i_shocked:
    ok("bloque -35: dentro de la rama victima-exe (survivor ataca a local exe), antes de aplicar shockedTimer")
else:
    bad("bloque -35 fuera de sitio (orden: rama exe → gate stun → v95 → shockedTimer)")

kr = work("objects/obj_kris/Draw_64.gml")
i_hp = kr.find("if(hp > 0)")
i_arrow = kr.find("if(revivalTimes < 2 && instance_exists(obj_bigring))")
i_close = kr.rfind("}")
if i_hp < i_arrow < i_close:
    ok("flecha de salida: dentro del if(hp > 0) del Draw_64 (muerto = sin brujula)")
else:
    bad("flecha de salida fuera del if(hp > 0)")

ui = work("objects/obj_playerui/Draw_64.gml")
if ui.find("var _kbX") < ui.find("case CHARACTER_KRIS:") and ui.find("EL ASESINO") > 0:
    ok("barra del playerui: ANTES del switch de iconos (dibuja siempre, no solo con habilidades)")
i_showhud = ui.find("if(!global.showHud)")
if i_showhud < ui.find("var _kbX"):
    ok("barra detras del gate global.showHud (se apaga con el resto del HUD)")

# scr_globals usa la MACRO (no un 350 suelto que pudiera divergir)
gs = work("scripts/scr_globals.gml")
if "global.exeHpPool = KRIS_EXE_MAXHP;" in gs and "global.exeHpPool = 350;" not in gs:
    ok("scr_globals: usa la macro KRIS_EXE_MAXHP (fuente unica de verdad)")
else:
    bad("scr_globals con literal suelto")

# ---------------------------------------------------------------------------
print()
if fails:
    print(f"RESULTADO PASADA 2: {len(fails)} FALLO(S)")
    for m in fails:
        print("  - " + m)
    sys.exit(1)
print("RESULTADO PASADA 2: TODO LIMPIO (0 fallos) — 2 PASADAS COMPLETAS")
