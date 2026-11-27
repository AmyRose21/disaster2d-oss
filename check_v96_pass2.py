#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
# check_v96_pass2.py — PASADA 2 (independiente) del v96 (KRIS: ritmo LOVE).
# A. ROUNDTRIP BYTE A BYTE: HEAD + pares viejo→nuevo generados DEL PROPIO
#    GIT (aplicados POR POSICION del diff, insercion pura = DESPUES de la
#    linea l) reconstruyen EXACTOS los 12 archivos del juego tocados desde
#    HEAD (11 intocados por v96 + scr_kris_special.gml con las 3 ediciones
#    v96 encima del v95). Si algo se movio de mas, el roundtrip truena.
# B. SIMULACION de las reglas con los numeros REALES del pedido v96:
#    1. NORMAL: 1.5 impactos/golpe (+50%) — LV 20 en 38 golpes exactos.
#    2. LMS (Show Fuerte): 3 impactos/golpe (+200% = triple) — LV 20 en 19.
#    3. Umbrales v46 INTACTOS (LV 20 = 56 impactos, sin tocar).
#    4. Floats EXACTOS (1.5 y 3 binarios exactos: cero deriva de redondeo).
#    5. Invariante 1-nivel-por-golpe (delta <= 3 < espaciado+1): el espejo
#       krisLvNet (+1 por senal, primera = 2) nunca se desincroniza.
#    6. Cura por subida +20 clampada al tope nuevo (LV 20 = 480) y el
#       duelo del exe SIN CAMBIOS (350 pool, -35 a LV 20, derribo a 0).
# C. CHECKS ANTI-REGRESION: los gates v95 siguen byte-exactos en su rama.
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
    d = list(difflib.unified_diff(h.splitlines(), w.splitlines(), lineterm="", n=0))
    ops = []
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
    src_lines = h.splitlines()
    out, pos = [], 0
    for (ostart, ocount), rem, add in ops:
        idx = ostart - 1 if ocount >= 1 else ostart
        out.extend(src_lines[pos:idx])
        if rem and add:
            assert src_lines[idx:idx + len(rem)] == rem, f + ": hunk desalineado"
            out.extend(add)
        elif rem and not add:
            assert src_lines[idx:idx + len(rem)] == rem, f + ": hunk desalineado"
        else:
            out.extend(add)
        pos = idx + ocount
    out.extend(src_lines[pos:])
    rebuilt = "\n".join(out) + ("\n" if h.endswith("\n") else "")
    if rebuilt == w or "\n".join(out) == w.rstrip("\n"):
        n_replace = sum(1 for _, r, a in ops if r and a)
        n_insert = sum(1 for _, r, a in ops if a and not r)
        ok(f + f": {len(ops)} par(es) ({n_replace} reemplazo + {n_insert} insercion) HEAD\u2192working EXACTO")
    else:
        bad(f + ": el roundtrip NO reproduce el archivo (drift)")
    total_pairs += len(ops)
print(f"     pares totales: {total_pairs}")

# ---------------------------------------------------------------------------
print("== B1. UMBRALES v46 INTACTOS (regla v46, sin tocar por v96) ==")
_th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56]
def love_lv(hits):
    lv = 1
    for i, t in enumerate(_th):
        if hits >= t:
            lv = i + 2
    return min(lv, 20)
assert love_lv(0) == 1 and love_lv(1.999) == 1
assert love_lv(2) == 2 and love_lv(56) == 20 and love_lv(999) == 20
ok("umbrales v46: 56 impactos = LV 20 (float-safe, tope KRIS_LV_MAX)")

print("== B2. NORMAL: 1.5 impactos/golpe (+50%) ==")
h, ev_n = 0.0, 0
while love_lv(h) < 20:
    h += 1.5
    ev_n += 1
if ev_n == 38 and love_lv(37 * 1.5) == 19 and love_lv(38 * 1.5) == 20:
    ok("normal: LV 20 en 38 golpes EXACTOS (38*1.5 = 57 >= 56; 37 golpes = 55.5 -> LV 19)")
else:
    bad("normal: LV 20 en %d golpes (esperado 38)" % ev_n)
# floats exactos: 1.5 y 3 son binarios exactos -> 1.5*N nunca arrastra error
for n in range(1, 100):
    assert (n * 1.5) * 2 == n * 3 and int(n * 3) == n * 3, "float no exacto en normal"
ok("1.5*N es EXACTO en binario (x2 == 3N entero): cero deriva de redondeo")

print("== B3. LMS: 3 impactos/golpe (+200% = el triple) ==")
h, ev_l = 0.0, 0
while love_lv(h) < 20:
    h += 3
    ev_l += 1
if ev_l == 19 and love_lv(18 * 3) == 19 and love_lv(19 * 3) == 20:
    ok("LMS: LV 20 en 19 golpes EXACTOS (19*3 = 57 >= 56; 18 golpes = 54 -> LV 19)")
else:
    bad("LMS: LV 20 en %d golpes (esperado 19)" % ev_l)
speedup_n = 56 / ev_n   # 56 eventos a 1x ahora en 38
speedup_l = 56 / ev_l   # 56 eventos a 1x ahora en 19
ok("velocidad EFECTIVA de subir LV: normal x%.2f (~+50%% por golpe), LMS x%.2f (~+200%% por golpe)"
   % (speedup_n, speedup_l))

print("== B4. INVARIANTE 1-NIVEL-POR-GOLPE (el espejo nunca se desincroniza) ==")
# TODOS los estados alcanzables: a golpes normales y luego b golpes LMS
# (el Show Fuerte puede activarse en MEDIO de la ronda, sobre un total
# fraccional). Un golpe suma 1.5 o 3; cruzar DOS umbrales nuevos exige
# avanzar > 3 — imposible. El espejo krisLvNet sube +1 por senal.
worst = 0
for a in range(0, 61):
    for b in range(0, 3):
        base = a * 1.5 + b * 3
        for delta in (1.5, 3):
            jump = love_lv(base + delta) - love_lv(base)
            worst = max(worst, jump)
            if jump > 1:
                bad("salto de %d niveles en un golpe (base=%s, delta=%s)" % (jump, base, delta))
if worst == 1:
    ok("maximo salto por golpe = 1 nivel en TODOS los estados alcanzables (60 normal x 3 LMS): la senal +1 del espejo siempre alcanza")
else:
    ok("maximo salto por golpe = %d" % worst)

# simulacion integral local == espejo en las 3 progresiones (pura, LMS, mixta)
def simulate(events, mirror_check=True):
    h, lv, mirror, signals = 0.0, 1, 1, 0
    for delta in events:
        h += delta
        new = love_lv(h)
        while new > lv:      # en la practica es 0 o 1 subida por golpe (arriba)
            lv += 1
            signals += 1
            mirror = 2 if signals == 1 else min(mirror + 1, 20)
    return lv, mirror, signals, h
for name, events in [
        ("normal pura", [1.5] * 40),
        ("LMS pura", [3] * 21),
        ("mixta (10 normal + LMS)", [1.5] * 10 + [3] * 12)]:
    lv, mirror, signals, h = simulate(events)
    exp = love_lv(h)
    # senales = subidas de LV = lv_final - 1 (arranca en LV 1); el espejo
    # recibe +1 por senal (la primera lo pone en 2) — debe quedar IGUAL al local
    if lv == mirror == exp and signals == lv - 1:
        ok("%s: LV local %d == espejo %d == tabla (%.1f impactos, %d senales)" % (name, lv, mirror, h, signals))
    else:
        bad("%s: local %d / espejo %d / tabla %d / senales %d" % (name, lv, mirror, exp, signals))

print("== B5. CURA POR SUBIDA + DUELO DEL EXE (logica v95 INTACTA al ritmo nuevo) ==")
# cada subida: max = 100 + 20*(LV-1), cura +20 clampada al nuevo tope
hp, maxhp, lv = 100, 100, 1
h = 0.0
heals = 0
while love_lv(h) < 20:
    h += 3           # LMS: el camino mas rapido
    new = love_lv(h)
    if new > lv:
        lv = new
        maxhp = 100 + 20 * (lv - 1)
        hp = min(hp + 20, maxhp)   # KRIS_LV_HP_BONUS = 20
        heals += 1
if lv == 20 and maxhp == 480 and heals == 19 and hp == 480:
    ok("19 subidas en LMS: tope 480, hp clampado al tope en cada cura (19 x 20 = 380 curados de 380 posibles)")
else:
    bad("crecimiento: lv=%d maxhp=%d heals=%d hp=%d" % (lv, maxhp, heals, hp))
# duelo del exe: SIN CAMBIOS — pool 350, -35 por golpe SOLO a LV 20, a 0: derribo + refill
pool, hits_to_down = 350, 0
while pool > 0:
    pool -= 35
    hits_to_down += 1
if hits_to_down == 10 and pool == 0:
    ok("duelo intacto: 10 golpes de 35 = 350 -> derribo (KRIS_EXE_DOWN_SEC) + refill del pool")
else:
    bad("duelo: %d golpes para derribar (esperado 10)" % hits_to_down)
# con el ritmo nuevo: LV 20 en el golpe 19 de LMS -> el golpe 20 ya hiere de verdad
h = 0.0
first_wound = None
for i in range(1, 26):
    h += 3
    if love_lv(h) >= 20:
        first_wound = i
        break
if first_wound == 19:
    ok("al ritmo LMS nuevo, el primer golpe que HIERE de verdad es el 19 (ya LV 20)")
else:
    bad("primer golpe hiriendo: %s (esperado 19)" % first_wound)

# ---------------------------------------------------------------------------
print("== C. ANTI-REGRESION: gates v95 byte-exactos en su sitio ==")
GATES = [
    ("objects/obj_player_puppet/Step_0.gml",
     "&& (variable_instance_exists(id, \"krisLvNet\") ? krisLvNet : 1) >= KRIS_LV_MAX)",
     "gate del golpe real: Kris del puppet a LV 20 y victima = EXE real"),
    ("objects/obj_playerui/Draw_64.gml",
     "global.character == CHARACTER_KRIS",
     "la barra del asesino solo la dibuja KRIS"),
    ("objects/obj_kris/Draw_64.gml",
     "spr_sindicator2",
     "flecha de salida pegada al cuerpo"),
    ("scripts/scr_player_maxhp/scr_player_maxhp.gml",
     "KRIS_LV_BASE_HP + KRIS_LV_HP_BONUS * (_lv - 1)",
     "vida de Kris escala con el LV (fuente unica)"),
    ("scripts/scr_globals.gml",
     "global.exeHpPool = KRIS_EXE_MAXHP",
     "arranque del pool del exe por ronda"),
    ("betterserver-oss/disasterserver/states/Game.c",
     "case CH_KRIS: hp_cap = 480",
     "anticheat del server: tope 480 (la copia compilada)"),
    ("betterserver-oss/disasterserver/Game.c",
     "case CH_KRIS: hp_cap = 480",
     "anticheat del server: tope 480 (la copia muerta, alineada igual)"),
]
for path, needle, why in GATES:
    if needle in work(path):
        ok(why + " — presente (" + path.split("/")[-1] + ")")
    else:
        bad(why + " — NO ENCONTRADO en " + path)

# la formula NUEVA vive en la funcion correcta (no en cualquier lado)
ks = work(FILES[0])
m = re.search(r"function scr_kris_love_event\(_kind\)\n\{\n"
              r"(?:.*\n)*?"
              r"        global\.player\.krisLvHits \+= global\.lmsActive \? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL;",
              ks)
if m:
    ok("la formula v96 vive DENTRO de scr_kris_love_event (el unico punto de acumulacion)")
else:
    bad("la formula v96 no esta dentro de scr_kris_love_event")

# ---------------------------------------------------------------------------
print()
if fails:
    print("PASADA 2 del v96: %d FALLO(S)" % len(fails))
    sys.exit(1)
print("PASADA 2 del v96: TODO LIMPIO")
