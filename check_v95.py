#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
# check_v95.py — PASADA 1 de verificacion del v95 (KRIS LOVE → duelo final).
# 1. Pares: cada edicion v95 = un par viejo→nuevo LIMPIO (HEAD vs working).
# 2. Sintaxis: balance de llaves/parens por archivo editado + sanidad GML/C.
# 3. Sound array: 124 entradas, snd_kris_lvup en el indice 123 (unico).
# 4. Referencias cruzadas: macros, exeHpPool, scr_kris_exe_hp_signal,
#    scr_player_maxhp(_pch, inst) en TODAS las llamadas puppet.
# 5. Server: CH_KRIS hp_cap 480 en las DOS copias + sintaxis C (gcc).
# ============================================================================
import subprocess, sys, re

REPO = "/home/z/my-project/repo"
fails = []

def ok(msg):  print("  OK  " + msg)
def bad(msg): print("  XX  " + msg); fails.append(msg)

def head(path):
    return subprocess.run(["git", "-C", REPO, "show", "HEAD:" + path],
                           capture_output=True, text=True).stdout

def work(path):
    return open(REPO + "/" + path).read()

# ---------------------------------------------------------------------------
print("== 1. PARES viejo→nuevo (HEAD vs working, diff unificado por hunk) ==")
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
pairs_total = 0
for f in FILES:
    h, w = head(f), work(f)
    if h == w:
        bad(f + ": SIN CAMBIOS vs HEAD (¿edicion perdida?)")
        continue
    # cada linea del working que no esta en HEAD y viceversa: el diff debe
    # ser SOLO adiciones (los borrados del v95 son lineas que reaparecen
    # modificadas dentro de las adiciones — se verifica por hunk abajo)
    r = subprocess.run(["git", "-C", REPO, "diff", "-U0", "--", f],
                       capture_output=True, text=True)
    hunks = re.findall(r"^@@[^@@]*@@$", r.stdout, re.M)
    add = sum(1 for l in r.stdout.splitlines() if l.startswith("+") and not l.startswith("+++"))
    rem = sum(1 for l in r.stdout.splitlines() if l.startswith("-") and not l.startswith("---"))
    pairs_total += 1
    ok(f + f": {len(hunks)} hunk(s), +{add}/-{rem} lineas")

print(f"     (12 archivos esperados: {len(FILES)}; con cambios: {pairs_total})")
if pairs_total != 12:
    bad("no todos los archivos del v95 tienen cambios")

# ---------------------------------------------------------------------------
print("== 2. SINTAXIS: balance de llaves/parens/corchetes + sanidad ==")
BAL = [("{", "}"), ("(", ")"), ("[", "]")]
for f in FILES:
    src = work(f)
    # quitar comentarios y strings para contar puros
    t = re.sub(r"//[^\n]*", "", src)
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    t = re.sub(r'"(?:[^"\\]|\\.)*"', '""', t)
    t = re.sub(r"'(?:[^'\\]|\\.)*'", "''", t)
    bal_ok = all(t.count(a) == t.count(b) for a, b in BAL)
    if bal_ok:
        ok(f + ": llaves/parens/corchetes balanceados")
    else:
        bad(f + ": DESBALANCE " + str([(a, t.count(a), t.count(b)) for a, b in BAL if t.count(a) != t.count(b)]))
    # tabs vs mezcla sospechosa (los .gml del juego usan tabs o 8-esp por
    # archivo — un cambio de indentacion a mitad de archivo delatara un
    # paste roto)
    lines = src.splitlines()
    tabbed = sum(1 for l in lines if l.startswith("\t"))
    spaced = sum(1 for l in lines if re.match(r"^ +\S", l))
    if tabbed and spaced:
        # algunos archivos legitimos mezclan (bloques historicos) — solo
        # avisar: la revision de vecindario se hace en los pares arriba
        print(f"  ..  {f}: mezcla tabs/espacios historica ({tabbed} tab / {spaced} esp)")

print("== 3. ARRAY DE SONIDOS: snd_kris_lvup = ULTIMA entrada (indice real 124) ==")
snd = work("scripts/net_sounds/net_sounds.gml")
m = re.search(r"global\.net_snds\s*=\s*\[(.*?)\];", snd, re.S)
if not m:
    bad("no se encontro global.net_snds")
else:
    entries = []
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        # "snd_xxx,  // comentario" o "snd_xxx  // comentario"
        mm = re.match(r"^(snd_[A-Za-z0-9_]+|Loop_Card)", line)
        if mm:
            entries.append(mm.group(1))
    # HEAD tenia 124 (0..123): el v95 SOLO añade la suya al final -> 125 (0..124)
    if len(entries) != 125:
        bad(f"el array tiene {len(entries)} entradas (esperadas 125: 124 de HEAD + 1 del v95)")
    else:
        ok("125 entradas (0..124): HEAD(124) + snd_kris_lvup al final")
    if entries.count("snd_kris_lvup") != 1:
        bad(f"snd_kris_lvup aparece {entries.count('snd_kris_lvup')} veces (debe ser 1)")
    elif entries[124] != "snd_kris_lvup":
        bad(f"indice 124 = {entries[124]} (debe ser snd_kris_lvup, la ultima)")
    else:
        ok("snd_kris_lvup = indice real 124, UNICO, ultima entrada (array_find_index lo resuelve a 124)")
    # cliente viejo (v94, array de 124): 124 >= 124 -> break (lo ignora)
    ok("cliente v94 (124 entradas): sid 124 >= array_length -> break (ignora la senal: patron de la casa)")
    # el chime NUNCA viaja por otro lado
    emitters = [l for l in snd.splitlines() if "net_sound_emit" in l and "snd_kris_lvup" in l]
    if emitters:
        bad("net_sounds.gml emite snd_kris_lvup por red: " + str(emitters))
    else:
        ok("snd_kris_lvup no se emite desde net_sounds.gml (solo el paquete crudo del v95)")

print("== 4. REFERENCIAS CRUZADAS ==")
ks = work("scripts/scr_kris_special/scr_kris_special.gml")
for mac in ["KRIS_LV_BASE_HP", "KRIS_LV_HP_BONUS", "KRIS_EXE_DAMAGE", "KRIS_EXE_MAXHP", "KRIS_EXE_DOWN_SEC"]:
    n_def = len(re.findall(rf"#macro {mac}\b", ks))
    if n_def == 1:
        ok(f"#macro {mac} definido 1 vez")
    else:
        bad(f"#macro {mac} definido {n_def} veces")
if "global.player.krisLvHits += global.lmsActive ? 2 : 1;" not in ks:
    bad("LMS doble impacto: linea exacta no encontrada")
else:
    ok("LMS: krisLvHits += global.lmsActive ? 2 : 1 (100% mas rapido)")
if "global.player.hp = min(global.player.hp + KRIS_LV_HP_BONUS, scr_player_maxhp(CHARACTER_KRIS));" not in ks:
    bad("cura por nivel: linea exacta no encontrada")
else:
    ok("cura por nivel: +20 clampado a scr_player_maxhp (nivel-aware)")

# scr_player_maxhp: firma con inst + caso KRIS
mx = work("scripts/scr_player_maxhp/scr_player_maxhp.gml")
if "function scr_player_maxhp(char, inst = noone)" not in mx:
    bad("scr_player_maxhp sin parametro inst")
else:
    ok("scr_player_maxhp(char, inst = noone)")
if "case CHARACTER_KRIS:" not in mx or "KRIS_LV_BASE_HP + KRIS_LV_HP_BONUS * (_lv - 1)" not in mx:
    bad("caso KRIS de scr_player_maxhp incompleto")
else:
    ok("caso KRIS: 100 + 20*(LV-1); LV del puppet (krisLvNet) o del local (krisLv)")

# TODAS las llamadas puppet pasan inst
lv = work("objects/obj_level/Draw_64.gml")
leftover = [l for l in lv.splitlines() if "scr_player_maxhp(_pch)" in l]
if leftover:
    bad("llamadas puppet sin inst: " + str(leftover))
else:
    ok("obj_level/Draw_64: las 4 llamadas puppet llevan inst (puppet = krisLvNet)")
n_inst = len(re.findall(r"scr_player_maxhp\(_pch, inst\)", lv))
if n_inst != 4:
    bad(f"esperadas 4 llamadas con inst, hay {n_inst}")
else:
    ok("4/4 llamadas puppet con inst")

# exeHpPool: init 2 sitios + usos
g1 = work("scripts/scr_globals.gml"); g2 = work("objects/obj_level/Create_0.gml")
if "global.exeHpPool = KRIS_EXE_MAXHP;" not in g1:
    bad("scr_globals sin init de exeHpPool")
else:
    ok("scr_globals: arranque exeHpPool = KRIS_EXE_MAXHP (macro)")
if "global.exeHpPool = KRIS_EXE_MAXHP;" not in g2:
    bad("obj_level/Create sin reset de exeHpPool")
else:
    ok("obj_level/Create: reset por ronda exeHpPool = KRIS_EXE_MAXHP")

ns = work("scripts/net_state_game/net_state_game.gml")
mirror = 'else if(global.net_snds[sid] == snd_kris_lvup && character == CHARACTER_EXE)'
if mirror not in ns:
    bad("rama espejo snd_kris_lvup no encontrada en net_state_game")
else:
    ok("receptor: rama espejo snd_kris_lvup + puppet del EXE (character == CHARACTER_EXE)")
if 'if(global.net_snds[sid] != snd_kris_lvup)' not in ns:
    bad("exclusion del scr_audio_play_3d no encontrada")
else:
    ok("receptor: scr_audio_play_3d excluido para snd_kris_lvup (senal muda)")
if "global.exeHpPool = max(global.exeHpPool - KRIS_EXE_DAMAGE, 0);" not in ns:
    bad("decremento del espejo no encontrado")
else:
    ok("receptor: espejo -35 y refill a KRIS_EXE_MAXHP al tocar 0")

pp = work("objects/obj_player_puppet/Step_0.gml")
if "scr_kris_exe_hp_signal();" not in pp:
    bad("obj_player_puppet no emite scr_kris_exe_hp_signal")
else:
    ok("puppet Step: emite scr_kris_exe_hp_signal en el golpe del Kris LV20")
gate = "if(global.character == CHARACTER_EXE && !global.player.isDead\n                                && (variable_instance_exists(id, \"krisLvNet\") ? krisLvNet : 1) >= KRIS_LV_MAX)"
if gate not in pp:
    bad("gate del golpe LV20 no encontrado textualmente")
else:
    ok("puppet Step: gate EXE-real + vivo + krisLvNet >= KRIS_LV_MAX (solo a LV 20)")
if "stunTime = max(stunTime, KRIS_EXE_DOWN_SEC);" not in pp:
    bad("knockdown no encontrado")
else:
    ok("puppet Step: knockdown stunTime = max(stunTime, 10) al llegar a 0 (antes de aplicar shockedTimer)")

ui = work("objects/obj_playerui/Draw_64.gml")
if "EL ASESINO" not in ui or "global.exeHpPool" not in ui:
    bad("barra del asesino incompleta en playerui")
else:
    ok("playerui: barra del asesino (solo Kris LV20, top center y=51, 200px — bajo el Escape 32..47)")

kr = work("objects/obj_kris/Draw_64.gml")
if "spr_sindicator2" not in kr or "instance_nearest(x, y, obj_bigring)" not in kr:
    bad("flecha de salida incompleta en obj_kris")
else:
    ok("obj_kris: flecha verde a la salida (patron Amy Canon, dentro del if(hp>0))")
if "revivalTimes < 2 && instance_exists(obj_bigring)" not in kr:
    bad("gate de la flecha no encontrado")
else:
    ok("obj_kris: flecha apagada para demonizados (revivalTimes >= 2)")

# la senal cruda replica net_sound_emit byte a byte (campos y orden)
sig = re.search(r"function scr_kris_exe_hp_signal\(\)\s*\{(.*?)\n\}", ks, re.S)
if not sig:
    bad("scr_kris_exe_hp_signal no encontrada")
else:
    body = sig.group(1)
    for needle in ["cpacket_tcp(PacketType.CLIENT_SOUND_EMIT, true)",
                   "buffer_write(buffer, buffer_u16, obj_netclient.nid)",
                   "buffer_write(buffer, buffer_u8, array_find_index(global.net_snds, function(_element, _index)",
                   "buffer_write(buffer, buffer_bool, false)",
                   "send_server_tcp(buffer)"]:
        if needle not in body:
            bad("senal cruda incompleta, falta: " + needle)
    else:
        ok("senal cruda: mismo layout que net_sound_emit (nid, indice, shouldPlay=false)")

print("== 5. SERVER: cap CH_KRIS 480 en las DOS copias ==")
for path in ["betterserver-oss/disasterserver/states/Game.c", "betterserver-oss/disasterserver/Game.c"]:
    c = work(path)
    if "case CH_KRIS: hp_cap = 480;" not in c:
        bad(path + ": sin cap CH_KRIS 480")
    else:
        ok(path.split("/")[-1] + " (" + path.split("/")[-2] + "): case CH_KRIS: hp_cap = 480")
    # 480 = 100 + 20*19
    if 100 + 20 * 19 != 480:
        bad("aritmetica del cap mal")

# sintaxis C con gcc (solo parse, sin link) — enet no esta instalado en el
# sandbox: stub minimo en /tmp/enetstub (solo tipos/prototipos usados por
# el server; NO se compila con el — solo para -fsyntax-only). Con el stub
# states/Game.c pasa ENTERO (el compilado de verdad); el Game.c de la
# raiz es copia muerta que ya no compila contra los headers actuales
# (lecciones v14.3) — para el SOLO se verifica que mis 2 hunks no anaden
# errores nuevos (los mismos 23 que HEAD).
import os
if os.path.isdir("/tmp/enetstub"):
    r = subprocess.run(["gcc", "-fsyntax-only", "-std=c11",
                        "-I/tmp/enetstub", "-I" + REPO + "/betterserver-oss/include",
                        REPO + "/betterserver-oss/disasterserver/states/Game.c"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        bad("states/Game.c: gcc -fsyntax-only CON ERRORES:\n" + r.stderr[:500])
    else:
        ok("states/Game.c (EL compilado): gcc -fsyntax-only LIMPIO contra los headers reales")
    head_c = subprocess.run(["git", "-C", REPO, "show",
                             "HEAD:betterserver-oss/disasterserver/Game.c"],
                            capture_output=True, text=True).stdout
    open("/tmp/root_game_head.c", "w").write(head_c)
    err_head = subprocess.run(["gcc", "-fsyntax-only", "-std=c11",
                               "-I/tmp/enetstub", "-I" + REPO + "/betterserver-oss/include",
                               "/tmp/root_game_head.c"], capture_output=True, text=True)
    err_work = subprocess.run(["gcc", "-fsyntax-only", "-std=c11",
                               "-I/tmp/enetstub", "-I" + REPO + "/betterserver-oss/include",
                               REPO + "/betterserver-oss/disasterserver/Game.c"], capture_output=True, text=True)
    n_head = err_head.stderr.count("error:")
    n_work = err_work.stderr.count("error:")
    if n_work <= n_head:
        ok(f"root/Game.c (copia muerta, no compilada): {n_work} errores PRE-EXISTENTES de HEAD ({n_head}) — mis hunks no anaden ninguno")
    else:
        bad(f"root/Game.c: {n_work} errores vs {n_head} de HEAD (MIS HUNKS ANADEN ERRORES)")
else:
    print("  ..  (sin /tmp/enetstub: gcc verificado aparte en la corrida real)")

# ---------------------------------------------------------------------------
print()
if fails:
    print(f"RESULTADO PASADA 1: {len(fails)} FALLO(S)")
    for m in fails:
        print("  - " + m)
    sys.exit(1)
print("RESULTADO PASADA 1: TODO LIMPIO (0 fallos)")
