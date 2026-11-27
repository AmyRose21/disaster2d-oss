#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
# check_v96.py — PASADA 1 de verificacion del v96 (KRIS: ritmo del LOVE).
# Pedido: "aumentaremos a 200% lo del aumento de nivel en lms y 50% en
# modo normal" — LMS 3 impactos/golpe (+200% = 3x), normal 1.5 (+50%).
# 1. Pares: las 3 ediciones v96 son EXACTAS y estan SOLO en el archivo
#    que cambia (scr_kris_special.gml) — el resto del arbol vs HEAD sigue
#    siendo exactamente el set v95 (12 de juego + 3 docs).
# 2. Literales: macros nuevas 1 vez, formula nueva 1 vez, formula vieja
#    "? 2 : 1" CERO veces en TODO el codigo del juego.
# 3. Anclas v46/v95 intactas (anti-regresion byte-exacta vs HEAD).
# 4. Sintaxis: balance de llaves/parens/corchetes + indentacion del archivo
#    editado (8 espacios, sin tabs mezclados).
# ============================================================================
import subprocess, sys, re

REPO = "/home/z/my-project/repo"
fails = []

def ok(msg):  print("  OK  " + msg)
def bad(msg): print("  XX  " + msg); fails.append(msg)

KS = "scripts/scr_kris_special/scr_kris_special.gml"

def head(path):
    return subprocess.run(["git", "-C", REPO, "show", "HEAD:" + path],
                          capture_output=True, text=True).stdout

def work(path):
    return open(REPO + "/" + path).read()

ks = work(KS)

# ---------------------------------------------------------------------------
print("== 1. LAS 3 EDICIONES v96 (exactas, unicas, en su sitio) ==")

# Edicion 1: bloque de macros v96 (insertado entre las LOVE v46 y las v95)
E1_NEW = """// ---- v96 (ritmo del LOVE): cuantos impactos cuenta cada golpe ----
// Pedido de la duena: "esta vez aumentaremos a 200% lo del aumento de
// nivel en lms y 50% en modo normal" \u2014 el Show Fuerte (LMS) acumula
// KRIS_LV_XP_LMS impactos por golpe (+200% = el TRIPLE de rapido) y
// el modo normal KRIS_LV_XP_NORMAL (+50% = 1.5). LV 20 = 56 impactos:
// 19 golpes en LMS / 38 en normal (antes 28 / 56). Tuneable aqui.
#macro KRIS_LV_XP_NORMAL 1.5
#macro KRIS_LV_XP_LMS 3
"""
if ks.count(E1_NEW) == 1:
    ok("bloque v96 de macros presente 1 vez (KRIS_LV_XP_NORMAL 1.5 / KRIS_LV_XP_LMS 3)")
else:
    bad("bloque v96 de macros: NO esta exactamente 1 vez como se escribio")

# Edicion 2: bloque de comentario de scr_kris_love_event (v95 -> v96)
E2_OLD = """// v95 (LMS, pedido): "si por otra parte esta en LMS su nivel subira con
// mucha mas rapidez (100% mas rapido)" \u2014 durante el Show Fuerte
// (global.lmsActive: el server lo confirma con SERVER_GAME_LMS cuando
// queda UN solo superviviente) cada impacto cuenta DOBLE. Si Kris esta
// vivo con el show activo, EL es el ultimo: nadie mas puede acumular.
"""
E2_NEW = """// v96 (ritmo, pedido): "aumentaremos a 200% lo del aumento de nivel
// en lms y 50% en modo normal" \u2014 durante el Show Fuerte (global.
// lmsActive: el server lo confirma con SERVER_GAME_LMS cuando queda
// UN solo superviviente) cada impacto cuenta TRIPLE (KRIS_LV_XP_LMS =
// 3 = +200%); en modo normal cuenta KRIS_LV_XP_NORMAL = 1.5 (+50%).
// LV 20 = 56 impactos: 19 golpes en LMS / 38 en normal. Si Kris esta
// vivo con el show activo, EL es el ultimo: nadie mas puede acumular.
// Los umbrales siguen espaciados de 3 en 3 y NINGUN modo suma mas de 3
// por golpe: imposible cruzar dos umbrales de un golpe (el espejo
// krisLvNet sube +1 por senal y sigue exacto, sin drift).
"""
if ks.count(E2_OLD) == 0 and ks.count(E2_NEW) == 1:
    ok("comentario de scr_kris_love_event: el v95 salio, el v96 entro (1 vez)")
else:
    bad("comentario de scr_kris_love_event: viejo presente (%d) / nuevo presente (%d)"
        % (ks.count(E2_OLD), ks.count(E2_NEW)))

# Edicion 3: LA FORMULA (la unica linea de logica que cambia)
E3_OLD = "        global.player.krisLvHits += global.lmsActive ? 2 : 1;"
E3_NEW = "        global.player.krisLvHits += global.lmsActive ? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL;"
if ks.count(E3_OLD) == 0 and ks.count(E3_NEW) == 1:
    ok("FORMULA: krisLvHits += lmsActive ? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL (1 vez)")
else:
    bad("FORMULA: vieja presente (%d) / nueva presente (%d)"
        % (ks.count(E3_OLD), ks.count(E3_NEW)))

# Reconstruccion del estado v95: revertir las 3 ediciones en memoria debe
# devolver el archivo v95 exacto (el que check_v95 verifico) — si alguna
# edicion hubiera tocado otra cosa, la reconstruccion NO cuadraria con el
# diff v95-vs-HEAD para las regiones ajenas (verificado en pasada 2).
v95_text = ks.replace(E1_NEW, "").replace(E2_NEW, E2_OLD).replace(E3_NEW, E3_OLD)
if v95_text != ks:
    ok("estado v95 reconstruible en memoria (revert de las 3 ediciones limpio)")
else:
    bad("el revert de las 3 ediciones NO cambio nada (ediciones no encontradas)")

# ---------------------------------------------------------------------------
print("== 2. LITERALES NUEVOS/VIEJOS en TODO el juego ==")
files_all = [l for l in subprocess.run(
    ["git", "-C", REPO, "ls-files", "-z", "*.gml", "*.c", "*.h", "*.yyp", "*.yy"],
    capture_output=True, text=True).stdout.split("\0") if l]
hits_new_macro = [f for f in files_all if "KRIS_LV_XP" in open(REPO + "/" + f, errors="ignore").read()]
if hits_new_macro == [KS]:
    ok("KRIS_LV_XP_* definidas y usadas SOLO en scr_kris_special.gml")
else:
    bad("KRIS_LV_XP_* aparece en: %s (esperado solo %s)" % (hits_new_macro, KS))

old_formula_files = []
for f in files_all:
    if "/_backups_animeditor/" in f:
        continue  # copias muertas historicas, no parte del juego compilado
    if re.search(r"lmsActive\s*\?\s*2\s*:\s*1\b", open(REPO + "/" + f, errors="ignore").read()):
        old_formula_files.append(f)
if not old_formula_files:
    ok("formula vieja 'lmsActive ? 2 : 1': CERO apariciones en el codigo del juego")
else:
    bad("formula vieja todavia viva en: %s" % old_formula_files)

if ks.count("#macro KRIS_LV_XP_NORMAL 1.5") == 1 and ks.count("#macro KRIS_LV_XP_LMS 3") == 1:
    ok("macros definidas exactamente 1 vez cada una (1.5 normal / 3 LMS)")
else:
    bad("macros duplicadas o con valor equivocado")

# ---------------------------------------------------------------------------
print("== 3. ANCLAS v46/v95 INTACTAS (anti-regresion) ==")
h_ks = head(KS)
# (a) anclas v46: existen en HEAD — byte-exactas y con la MISMA cuenta
anchors_v46 = [
    ("umbrales v46 byte-exactos",
     "static _th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56];"),
    ("tope v46", "#macro KRIS_LV_MAX 20"),
    ("chime v47", "audio_play_sound(snd_kris_lvup, 0, false);"),
    ("senal silenciosa v46", "net_sound_emit(snd_none);"),
    ("tope del LV en scr_kris_love_lv", "return min(_lv, KRIS_LV_MAX);"),
]
for name, line in anchors_v46:
    if line in ks and line in h_ks and ks.count(line) == h_ks.count(line):
        ok(name + " — identico a HEAD (sin tocar)")
    else:
        bad(name + " — CAMBIO inesperado vs HEAD")
# (b) anclas v95: NO existen en HEAD (las AADIO v95) — basta con que
# sigan presentes 1 vez en el working (v96 no borro nada del v95)
anchors_v95 = [
    ("vida v95", "#macro KRIS_LV_BASE_HP 100"),
    ("bonus v95", "#macro KRIS_LV_HP_BONUS 20"),
    ("duelo v95", "#macro KRIS_EXE_DAMAGE 35"),
    ("pool v95", "#macro KRIS_EXE_MAXHP 350"),
    ("derribo v95", "#macro KRIS_EXE_DOWN_SEC 10"),
    ("cura por subida v95 (logica intacta)",
     "global.player.hp = min(global.player.hp + KRIS_LV_HP_BONUS, scr_player_maxhp(CHARACTER_KRIS));"),
]
for name, line in anchors_v95:
    if line in ks and line not in h_ks and ks.count(line) == 1:
        ok(name + " — presente 1 vez (anadido por v95, v96 no lo toco)")
    else:
        bad(name + " — ausente o duplicado inesperadamente")

# gate del espejo (+1 por senal) en el archivo de red: INTACTO vs HEAD-era
# (ese archivo hoy debe ser exactamente el v95 — v96 no lo toca)
NSG = "scripts/net_state_game/net_state_game.gml"
nsg = work(NSG)
if ("krisLvNet = min(krisLvNet + 1, KRIS_LV_MAX);" in nsg
        and "krisLvNet = 2;" in nsg
        and "krisLvHits += global.lmsActive" not in nsg):
    ok("espejo net_state_game: krisLvNet +1 por senal (primera = 2) — intacto, sin formula de hits")
else:
    bad("espejo net_state_game: algo se movio")

# init del contador: sigue entero en el Create (floats solo al acumular)
KC = "objects/obj_kris/Create_0.gml"
if "krisLvHits = 0;" in work(KC) and "krisLv = 1;" in work(KC):
    ok("Create de Kris: krisLvHits = 0 / krisLv = 1 — reset por partida intacto")
else:
    bad("Create de Kris: init del LOVE alterado")

# ---------------------------------------------------------------------------
print("== 4. SINTAXIS del archivo editado ==")
# braces/brackets: balance ABSOLUTO; parens: el archivo ya venia con un
# ( suelto en comentarios desde HEAD (139/138) — lo que v96 garantiza es
# que el desbalance NO CAMBIA vs HEAD (delta 0) y las llaves siguen a 0
for pair in [("{", "}"), ("[", "]")]:
    o, c = ks.count(pair[0]), ks.count(pair[1])
    if o == c:
        ok("balance %s%s: %d == %d" % (pair[0], pair[1], o, c))
    else:
        bad("balance %s%s: %d != %d" % (pair[0], pair[1], o, c))
d_w = ks.count("(") - ks.count(")")
d_h = h_ks.count("(") - h_ks.count(")")
if d_w == d_h:
    ok("parens: desbalance %d == %d (el ( suelto de HEAD en comentarios, delta v96 = 0)" % (d_w, d_h))
else:
    bad("parens: el desbalance cambio (%d en HEAD vs %d ahora)" % (d_h, d_w))
if ks.endswith("\n") and "\r" not in ks:
    ok("EOF con newline simple (sin CR)")
else:
    bad("EOF/CR: formato raro")
if "\t" not in ks:
    ok("indentacion 100% espacios (8) — sin tabs")
else:
    bad("tabs mezclados en el archivo")
# las 5 lineas nuevas de codigo (2 macros + 1 formula) usan indentacion de casa
if re.search(r"^#macro KRIS_LV_XP_NORMAL 1\.5$", ks, re.M) and \
   re.search(r"^#macro KRIS_LV_XP_LMS 3$", ks, re.M) and \
   re.search(r"^        global\.player\.krisLvHits \+= global\.lmsActive \? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL;$", ks, re.M):
    ok("indentacion de las lineas nuevas: macros a margen, formula a 8 espacios")
else:
    bad("indentacion de las lineas nuevas incorrecta")

# ---------------------------------------------------------------------------
print("== 5. SET DE ARCHIVOS MODIFICADOS vs HEAD (debe ser EXACTO el v95) ==")
V95_SET = {
    "CACHE.md", "LEARNING.md", "worklog.md",
    "betterserver-oss/disasterserver/Game.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "objects/obj_kris/Draw_64.gml",
    "objects/obj_level/Create_0.gml",
    "objects/obj_level/Draw_64.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_sounds/net_sounds.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_globals.gml",
    "scripts/scr_kris_special/scr_kris_special.gml",
    "scripts/scr_player_maxhp/scr_player_maxhp.gml",
}
changed = set(subprocess.run(["git", "-C", REPO, "diff", "--name-only", "HEAD"],
                             capture_output=True, text=True).stdout.split())
if changed == V95_SET:
    ok("15 archivos modificados vs HEAD = set v95 exacto (v96 NO agrego archivos nuevos al diff)")
else:
    extra, missing = changed - V95_SET, V95_SET - changed
    bad("set de cambios vs HEAD difiere del v95: extra=%s faltan=%s" % (sorted(extra), sorted(missing)))

# ---------------------------------------------------------------------------
print()
if fails:
    print("PASADA 1 del v96: %d FALLO(S)" % len(fails))
    sys.exit(1)
print("PASADA 1 del v96: TODO LIMPIO")
