#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v97_pass2.py — PASADA 2 (profunda) del fix v97 (desync LOVE de Kris).

 1. Reconstruccion BYTE A BYTE del archivo de trabajo: HEAD + los 3 bloques
    editados (macro-comentario / comentario de la funcion / cuerpo de
    scr_kris_love_event) == working. Prueba que NO hay ni un byte distinto
    fuera de los 3 bloques.
 2. Re-simulacion con las constantes PARSEADAS DEL ARCHIVO DE TRABAJO
    (umbrales, KRIS_LV_MAX, perillas 1.5/5, bonus 20, base 100) — no
    hardcodeadas: local == espejo en CADA golpe para LMS/normal/mixto,
    y el conteo de golpes al LV 20 (12 en LMS@5, 38 en normal@1.5).
 3. Consumidores del espejo krisLvNet INTACTOS y coherentes con el flush:
    stun escalado del puppet, el gate del dano real al exe (>= LV_MAX) y
    la barra/vida del puppet (scr_player_maxhp con el puppet como inst).
 4. Los 2 call sites de scr_kris_love_event (cuchillazo + parry) intactos.
 5. Sanidad GML final: estructura de la funcion (repeat dentro del if
    dentro de la funcion), sin caracteres raros, fin de archivo con \n.
 6. Indices de red: snd_none sigue siendo la entrada 0 y snd_kris_lvup
    la 124 (cero cambios de array — nada que reindexar en el server).
"""

import re
import subprocess
import sys

REPO = "/home/z/my-project/repo"
GML_PATH = "scripts/scr_kris_special/scr_kris_special.gml"
GML = f"{REPO}/{GML_PATH}"

ok_count = 0
fail_count = 0

def check(name, cond, detail=""):
    global ok_count, fail_count
    if cond:
        ok_count += 1
        print(f"  [OK]   {name}")
    else:
        fail_count += 1
        print(f"  [FAIL] {name}" + (f" — {detail}" if detail else ""))

def read(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

working = read(GML)

# ------------------------------------------- 1. reconstruccion byte a byte
print("== 1. Reconstruccion byte a byte (HEAD + 3 bloques == working) ==")
head = subprocess.run(["git", "-C", REPO, "show", f"HEAD:{GML_PATH}"],
                      capture_output=True, text=True).stdout
assert head, "no se pudo leer HEAD"

def apply_block(src, old, new):
    assert old in src, f"bloque viejo no encontrado:\n{old[:120]}..."
    assert src.count(old) == 1, "bloque viejo aparece mas de una vez"
    return src.replace(old, new, 1)

B1_OLD = """// el modo normal KRIS_LV_XP_NORMAL (+50% = 1.5). LV 20 = 56 impactos:
// 19 golpes en LMS / 38 en normal (antes 28 / 56). Tuneable aqui.
#macro KRIS_LV_XP_NORMAL 1.5
#macro KRIS_LV_XP_LMS 5"""
B1_NEW = """// el modo normal KRIS_LV_XP_NORMAL (+50% = 1.5). LV 20 = 56 impactos:
// 19 golpes en LMS / 38 en normal (antes 28 / 56). Tuneable aqui.
// v97: la perilla quedo en 5 en el repo (LV 20 en 12 golpes de LMS) y
// el MULTI-SIGNAL FLUSH de scr_kris_love_event la vuelve LIBRE: ya NO
// importa el espaciado de umbrales — la advertencia "no pasar de 3 por
// golpe" del v96 queda OBSOLETA. Tunear a gusto.
#macro KRIS_LV_XP_NORMAL 1.5
#macro KRIS_LV_XP_LMS 5"""

B2_OLD = """// UN solo superviviente) cada impacto cuenta TRIPLE (KRIS_LV_XP_LMS =
// 3 = +200%); en modo normal cuenta KRIS_LV_XP_NORMAL = 1.5 (+50%).
// LV 20 = 56 impactos: 19 golpes en LMS / 38 en normal. Si Kris esta
// vivo con el show activo, EL es el ultimo: nadie mas puede acumular.
// Los umbrales siguen espaciados de 3 en 3 y NINGUN modo suma mas de 3
// por golpe: imposible cruzar dos umbrales de un golpe (el espejo
// krisLvNet sube +1 por senal y sigue exacto, sin drift)."""
B2_NEW = """// UN solo superviviente) cada impacto cuenta KRIS_LV_XP_LMS (perilla,
// hoy 5); en modo normal cuenta KRIS_LV_XP_NORMAL (1.5). Si Kris esta
// vivo con el show activo, EL es el ultimo: nadie mas puede acumular.
// v97 (SINCRONIZACION, bug reportado): con perillas > 3 un mismo
// golpe CRUZA DOS umbrales (estan espaciados de 3) — el LV local
// saltaba 2 niveles de un golpe mientras la senal silenciosa viajaba
// UNA sola vez y el espejo krisLvNet solo hace +1 por senal: los
// demas se quedaban atras (local LV 20 contra LV 13 espejado tras 12
// golpes de LMS a 5). FIX = MULTI-SIGNAL FLUSH: una senal POR NIVEL
// cruzado — el espejo queda EXACTO con CUALQUIER perilla."""

B3_OLD = """        var _new = scr_kris_love_lv(global.player.krisLvHits);

        if(_new > global.player.krisLv)
        {
                global.player.krisLv = _new;

                // v95 (duena): "y el se cura esa misma cantidad por cada
                // que sube de nivel" — +20 de vida MAXIMA por LV (la nueva
                // vida total la calcula scr_player_maxhp con el LV recien
                // subido) y cura LOS MISMOS 20 en el acto. Con la vida ya
                // al tope no gana nada (el clamp del min). El hp viaja
                // clampeado a la nueva vida total en el CLIENT_PLAYER_DATA
                // (obj_netclient Step_2 ya consulta scr_player_maxhp).
                global.player.hp = min(global.player.hp + KRIS_LV_HP_BONUS, scr_player_maxhp(CHARACTER_KRIS));

                // v47 (duena): el sonido de la subida de LV es el SUYO -
                // el mp3 "Undertale Sound Effect - LV Up" que subio,
                // registrado como asset nuevo snd_kris_lvup. Local como
                // siempre: los demas no oyen nada, la senal viaja
                // silenciosa.
                audio_play_sound(snd_kris_lvup, 0, false);

                // senal +1 LV: la reciben los demas clientes en el
                // CLIENT_SOUND_EMIT (rama de snd_none con gate de
                // personaje) y la espejan en el puppet de Kris.
                net_sound_emit(snd_none);
        }"""
B3_NEW = """        var _new = scr_kris_love_lv(global.player.krisLvHits);
        var _up = _new - global.player.krisLv; // niveles cruzados (0 = no sube)

        if(_up > 0)
        {
                global.player.krisLv = _new;

                // v95 (duena): "y el se cura esa misma cantidad por cada
                // que sube de nivel" — +20 de vida MAXIMA por LV (la nueva
                // vida total la calcula scr_player_maxhp con el LV recien
                // subido) y cura LOS MISMOS 20 POR CADA subida (v97: un
                // golpe que cruza 2 niveles cura 2x20 y sube 2x20 de vida
                // maxima — antes contaba +20 una sola vez). Con la vida ya
                // al tope no gana nada (el clamp del min). El hp viaja
                // clampeado a la nueva vida total en el CLIENT_PLAYER_DATA
                // (obj_netclient Step_2 ya consulta scr_player_maxhp).
                global.player.hp = min(global.player.hp + KRIS_LV_HP_BONUS * _up, scr_player_maxhp(CHARACTER_KRIS));

                // v47 (duena): el sonido de la subida de LV es el SUYO -
                // el mp3 "Undertale Sound Effect - LV Up" que subio,
                // registrado como asset nuevo snd_kris_lvup. Local como
                // siempre: los demas no oyen nada, la senal viaja
                // silenciosa.
                audio_play_sound(snd_kris_lvup, 0, false);

                // v97 MULTI-SIGNAL FLUSH: una senal silenciosa POR NIVEL
                // cruzado (antes UNA por golpe: con perillas > 3 un golpe
                // cruzaba 2 umbrales y el espejo krisLvNet — que sube +1
                // por senal — se quedaba atras para siempre, sin resync).
                // El receptor (net_state_game, rama del snd_none con gate
                // de personaje) espeja +1 por senal: queda EXACTO con
                // cualquier perilla. El server reenvia el broadcast sin
                // dedup (solo valida las senales DIRIGIDAS de stun): las
                // N senales llegan siempre.
                repeat(_up)
                        net_sound_emit(snd_none);
        }"""

recon = apply_block(head, B1_OLD, B1_NEW)
recon = apply_block(recon, B2_OLD, B2_NEW)
recon = apply_block(recon, B3_OLD, B3_NEW)
check("HEAD + los 3 bloques == working BYTE A BYTE (0 bytes distintos fuera de los edits)",
      recon == working)
if recon != working:
    wl = working.splitlines()
    rl = recon.splitlines()
    for i, (a, b) in enumerate(zip(wl, rl)):
        if a != b:
            print(f"    primera diferencia linea {i+1}:\n    work: {a!r}\n    reco: {b!r}")
            break
    print(f"    lineas: work {len(wl)} vs recon {len(rl)}")

# ------------------------------- 2. re-simulacion con constantes del archivo
print("== 2. Re-simulacion con constantes PARSEADAS del archivo de trabajo ==")
th_m = re.search(r"static _th = \[([0-9, ]+)\];", working)
TH = [int(x) for x in th_m.group(1).split(",")]
LV_MAX = int(re.search(r"#macro KRIS_LV_MAX (\d+)", working).group(1))
XP_N = float(re.search(r"#macro KRIS_LV_XP_NORMAL ([\d.]+)", working).group(1))
XP_L = float(re.search(r"#macro KRIS_LV_XP_LMS (\d+)", working).group(1))
BONUS = int(re.search(r"#macro KRIS_LV_HP_BONUS (\d+)", working).group(1))
BASE = int(re.search(r"#macro KRIS_LV_BASE_HP (\d+)", working).group(1))
print(f"  parseado: TH={TH[0]}..{TH[-1]} ({len(TH)} umbrales) LV_MAX={LV_MAX} "
      f"XP_N={XP_N} XP_L={XP_L} BONUS={BONUS} BASE={BASE}")
check("constantes parseadas == esperadas del repo",
      (TH[0], TH[-1], len(TH), LV_MAX, XP_N, XP_L, BONUS, BASE)
      == (2, 56, 19, 20, 1.5, 5.0, 20, 100))

def love_lv(hits):
    lv = 1
    for i, t in enumerate(TH):
        if hits >= t:
            lv = i + 2
    return min(lv, LV_MAX)

def run(xp_seq, flush=True, heal=True, start_hp=None):
    """Corre la secuencia de golpes (lista de (modo, n)) con las reglas del
    archivo: local salta al nivel nuevo; espejo +1 por senal; flush = una
    senal por nivel; cura BONUS*_up (o BONUS*1 si heal viejo)."""
    hits = 0.0
    local = 1
    mirror = 1
    hp = float(BASE) if start_hp is None else start_hp
    maxhp = BASE + BONUS * (local - 1)
    events = []
    for mode, n in xp_seq:
        xp = XP_L if mode == "lms" else XP_N
        for _ in range(n):
            hits += xp
            new = love_lv(hits)
            if new > local:
                up = new - local
                local = new
                maxhp = BASE + BONUS * (local - 1)
                hp = min(hp + (BONUS * up if heal else BONUS), maxhp)
                sig = up if flush else 1
                for _ in range(sig):
                    mirror = min(mirror + 1, LV_MAX)
                events.append((hits, local, mirror, hp))
    return events, local, mirror, hp, maxhp, hits

# progresion pura LMS hasta el tope
ev, l, m, hp, mh, _ = run([("lms", 40)])
check("LMS@5 puro: local == espejo en CADA subida", all(e[1] == e[2] for e in ev))
check("LMS@5 puro: LV 20 alcanzado y espejo 20 tambien", (l, m) == (20, 20))
check("LMS@5 puro: primer golpe ya cruza 2 niveles (hits 5 → LV 3)", ev[0][1] == 3)
# 19 niveles ganados en 12 EVENTOS (con perilla 5 hay saltos dobles)
check("LMS@5 puro: 12 EVENTOS con subida (19 niveles — hay saltos dobles) y el ultimo en hits 60",
      len(ev) == 12 and ev[-1][0] == 60.0, f"{len(ev)} eventos, ultimo {ev[-1][0]}")
check("LMS@5 puro: saltos dobles presentes (6 saltos de 2 niveles: el caso del fix)",
      sum(1 for i, e in enumerate(ev) if i > 0 and e[1] - ev[i-1][1] == 2) + (1 if ev[0][1] - 1 == 2 else 0) == 7)
# progresion normal pura
ev, l, m, hp, mh, _ = run([("norm", 40)])
check("normal@1.5 puro: local == espejo en cada subida y LV 20", all(e[1] == e[2] for e in ev) and (l, m) == (20, 20))
check("normal@1.5 puro: LV 20 en 38 golpes (57 hits)", ev[-1][0] == 57.0)
# mezcla: 15 normal, show a mitad, luego LMS
ev, l, m, hp, mh, _ = run([("norm", 15), ("lms", 20)])
check("mezcla (15 normal + LMS): local == espejo en cada subida", all(e[1] == e[2] for e in ev) and l == m == 20)
# el caso del REPORTE: solo LMS, 12 golpes — el espejo debe quedar en 20 (antes 13)
ev, l, m, hp, mh, _ = run([("lms", 12)])
check("EL REPORTE (12 golpes LMS@5): local 20 == espejo 20 (antes espejo 13)", (l, m) == (20, 20))
check("y sin el flush el mismo caso da espejo 13 (regresion del bug: se demuestra)",
      run([("lms", 12)], flush=False)[2] == 13)
# la cura con la regla nueva: desde full, cada subida queda == maxhp
ev, l, m, hp, mh, _ = run([("lms", 12)])
check("cura *_up: hp final == maxhp(20) == 480 desde 100", abs(hp - 480) < 1e-9 and mh == 480)
check("cura *_up: hp == maxhp del nivel en cada subida (empezando full)",
      all(abs(e[3] - (BASE + BONUS * (e[1] - 1))) < 1e-9 for e in ev))
# cura herido: desde 60 hp, el golpe doble (LV1→3) cura 40 y queda 100 == maxhp(3)
ev, l, m, hp, mh, _ = run([("lms", 1)], start_hp=60.0)
check("cura *_up herido (hp 60, golpe doble): cura 40 → 100 == maxhp(3)", (hp, mh) == (100.0, 140.0))
# el clamp del min: hp nunca supera la vida maxima del nivel alcanzado
ev, l, m, hp, mh, _ = run([("norm", 3)], start_hp=99.0)
check("clamp del min respetado (hp herido nunca supera maxhp del nivel)", hp <= mh)

# --------------------------------- 3. consumidores del espejo intactos
print("== 3. Consumidores del espejo krisLvNet (pantallas ajenas) ==")
pup_s0 = read(f"{REPO}/objects/obj_player_puppet/Step_0.gml")
check("stun escalado por LV en el puppet (Step_0: krisLvNet escala el stun de la espada)",
      "krisLvNet" in pup_s0 and "KRIS_LV_STUN_PCT" in pup_s0)
check("gate del dano real al exe: krisLvNet >= KRIS_LV_MAX en el Step_0 del puppet",
      re.search(r"krisLvNet[^\n]*>=\s*KRIS_LV_MAX", pup_s0) is not None)
maxhp_gml = read(f"{REPO}/scripts/scr_player_maxhp/scr_player_maxhp.gml")
check("scr_player_maxhp: la barra del puppet escala con krisLvNet (inst.krisLvNet)",
      "inst.krisLvNet" in maxhp_gml)
check("obj_netclient Step_2: el clamp del hp que VIAJA consulta scr_player_maxhp (nivel-aware)",
      "scr_player_maxhp" in read(f"{REPO}/objects/obj_netclient/Step_2.gml"))
recv = read(f"{REPO}/scripts/net_state_game/net_state_game.gml")
check("receptor: el espejo sube +1 por senal con cap (intacto — el flush se apoya en el)",
      "krisLvNet = min(krisLvNet + 1, KRIS_LV_MAX);" in recv)
# coherencia exe-duelo: el espejo llega a 20 en el MISMO golpe que el local
ev, l, m, *_ = run([("lms", 12)])
first20_local = next(i for i, e in enumerate(ev) if e[1] == 20)
first20_mirror = next(i for i, e in enumerate(ev) if e[2] == 20)
check("el espejo alcanza LV 20 en la MISMA subida que el local (el duelero ve la barra a tiempo)",
      first20_local == first20_mirror)
# y SIN flush el espejo nunca llega a 20 en ese round (el duelero no ve nada)
ev2, l2, m2, *_ = run([("lms", 12)], flush=False)
check("regresion demostrada: sin flush el espejo se queda en 13 y el exe JAMAS ve el LV 20",
      m2 == 13)

# ---------------------------------------------- 4. call sites intactos
print("== 4. Call sites de scr_kris_love_event ==")
hits_grep = subprocess.run(["grep", "-rn", "scr_kris_love_event(", f"{REPO}/scripts",
                            f"{REPO}/objects"], capture_output=True, text=True).stdout
callers = [l for l in hits_grep.splitlines() if "function scr_kris_love_event" not in l]
callers = [l.replace(REPO + "/", "") for l in callers]
print("  llamadas:")
for c in callers:
    print(f"    {c}")
check("exactamente 1 call site: TODO embudo por CLIENT_PLAYER_HURT (desde v47 el parry cuenta ahi tambien — 2 fuentes, 1 acumulador)",
      len(callers) == 1 and "net_state_game.gml:3060" in callers[0], f"{callers}")
check("call sites intactos vs HEAD (solo el fix + comentario del array + docs de memoria)",
      set(subprocess.run(["git", "-C", REPO, "diff", "--name-only"],
                         capture_output=True, text=True).stdout.split())
      == {GML_PATH, "scripts/net_sounds/net_sounds.gml",
          "LEARNING.md", "CACHE.md", "worklog.md"})

# -------------------------------------------- 5. sanidad GML final
print("== 5. Sanidad GML final ==")
fn = re.search(r"function scr_kris_love_event\(_kind\)\s*\{(.*?)\n\}", working, re.S)
check("la funcion scr_kris_love_event existe y cierra", fn is not None)
body = fn.group(1)
check("_up se define ANTES de usarse (y krisLv se asigna despues del guard)",
      body.index("var _up =") < body.index("if(_up > 0)") < body.index("global.player.krisLv = _new;"))
check("repeat(_up) DENTRO del if(_up > 0) — nunca emite con _up == 0",
      body.index("if(_up > 0)") < body.index("repeat(_up)"))
check("repeat(_up) antes del cierre del if (la llave de cierre va despues)",
      body.index("repeat(_up)") < body.rindex("}"))
check("el archivo termina con salto de linea", working.endswith("\n"))
check("sin CR (\\r) ni tabs en el archivo", "\r" not in working and "\t" not in working)
check("caracteres no-ASCII solo en comentarios (los — de siempre)",
      all((line.lstrip().startswith("//")) for line in working.splitlines()
          if any(ord(ch) > 127 for ch in line)))

# ---------------------------------------- 6. indices de red sin cambios
print("== 6. Indices de red (cero cambios de array) ==")
nds = read(f"{REPO}/scripts/net_sounds/net_sounds.gml")
arr = re.search(r"global\.net_snds\s*=\s*\[(.*?)\];", nds, re.S).group(1)
entries = []
for line in arr.split("\n"):
    s = line.strip()
    if not s or s.startswith("//") or s.startswith("/*") or s.startswith("*"):
        continue
    name = s.split("//")[0].strip().rstrip(",")
    if name:
        entries.append(name)
check(f"snd_none sigue siendo la entrada 0 (total {len(entries)} entradas)", entries[0] == "snd_none")
check("snd_kris_lvup sigue al final — indice real 126 (los taunts de Jina lo empujaron del 124; AMBOS lados resuelven por VALOR, el indice no manda)",
      entries.index("snd_kris_lvup") == 126 and entries[-1] == "snd_kris_lvup")
check("el comentario viejo '124 (real)' ya no miente (v97: corregido a 126)",
      "126 (real" in nds and "124 (real):" not in nds)
check("los indices hardcodeados del server siguen estables (0/1/12/109/110/118)",
      [entries[i] for i in (0, 1, 12, 109, 110, 118)]
      == ["snd_none", "snd_dash", "snd_exe_stun", "snd_nono", "snd_vasebreak", "snd_metal_stun"])
check("el receptor del exe HP compara por VALOR (index_find en ambos lados — el drift de indice es inocuo)",
      "global.net_snds[sid] == snd_kris_lvup" in read(f"{REPO}/scripts/net_state_game/net_state_game.gml"))
# la entrada sique parseando igual (1 entrada, mismo nombre, sin coma colgante)
check("el array sique valido tras el retoque de comentario (snd_kris_lvup sin coma y ] despues)",
      re.search(r"snd_kris_lvup[^\n]*\n(?:\s*//[^\n]*\n)*\s*\];", nds) is not None)

print()
print(f"RESULTADO PASADA 2: {ok_count} OK, {fail_count} FAIL")
sys.exit(1 if fail_count else 0)
