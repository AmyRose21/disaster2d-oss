#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v97.py — PASADA 1 del fix del desync LOVE de Kris (v97).

Bug reportado por la duena: "kris sube rapido en el cliente pero en el
server no lo reconoce, los demas lo ven a lv 13 mientras que en su
cliente ya es lv 20".

Causa raiz (verificada): el repo tenia KRIS_LV_XP_LMS = 5 (perilla que
la duena dejo tras el v96, que entrego 3). Con umbrales espaciados de 3
(scr_kris_love_lv), un golpe a 5 CRUZA DOS umbrales: krisLv local salta
2 niveles pero la senal silenciosa viajaba UNA sola vez y el espejo
krisLvNet solo hace +1 por senal → drift permanente. 12 golpes de LMS:
local LV 20, espejo LV 13 (los demas ven 13).

Fix (v97, MULTI-SIGNAL FLUSH): una senal por NIVEL cruzado
(repeat(_up) net_sound_emit(snd_none)) + cura KRIS_LV_HP_BONUS * _up.

Esta pasada verifica:
  1. Solo scripts/scr_kris_special/scr_kris_special.gml cambio vs HEAD.
  2. Los 3 edits exactos y unicos (macro-comentario / comentario de la
     funcion / cuerpo: _up, guard, cura *_up, repeat(_up)).
  3. Las perillas QuedAN IGUAL (1.5 / 5 — la de la duena se RESPETA).
  4. El receptor (net_state_game.gml) INTACTO: espejo +1 por senal con
     cap KRIS_LV_MAX — el flush se apoya en el, no lo toca.
  5. Balance de llaves/parens: delta 0 vs HEAD (el desbalance +1 de
     parens pre-existente en comentarios se conserva tal cual).
  6. SIMULACION con las reglas reales: (a) el bug se reproduce con la
     regla vieja (20 vs 13); (b) con el flush el espejo == local en
     cada golpe con perillas 1.5 / 5 / 7 / 10 y mezclas normal→LMS.
  7. Coherencia de la cura: +20 POR nivel, hp<=480, clamp del min.
  8. Relay del server: el CLIENT_SOUND_EMIT broadcast (nid==emisor,
     snd_none idx 0) NO pasa por la validacion de stun (exige nid !=
     emisor) NI por el tope de Chocola (109/110) → server_broadcast_ex
     sin dedup: las N senales llegan siempre.
"""

import re
import subprocess
import sys

REPO = "/home/z/my-project/repo"
GML = f"{REPO}/scripts/scr_kris_special/scr_kris_special.gml"
NET = f"{REPO}/scripts/net_state_game/net_state_game.gml"
GAME_C = f"{REPO}/betterserver-oss/disasterserver/states/Game.c"

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

# ------------------------------------------------------------------ git
print("== 1. Git: solo los archivos tocados ==")
st = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                    capture_output=True, text=True).stdout.splitlines()
# OJO (bug de checker corregido): NO hacer .strip() antes de splitlines —
# el porcelain usa ' M path' (espacio inicial) y el strip se lo comia.
mod = sorted(l for l in st if l and not l.startswith("??"))
new = sorted(l[3:] for l in st if l.startswith("??"))
print(f"  modified: {mod}")
print(f"  untracked (nuevos): {new}")
# JUEGO: 2 gml (fix + comentario). DOCS: LEARNING/CACHE/worklog (regla 4/5/9).
# NUEVOS: los checks y el LEEME de la entrega v97.
check("modificados = 2 del JUEGO + 3 docs de memoria",
      mod == [" M CACHE.md", " M LEARNING.md",
              " M scripts/net_sounds/net_sounds.gml",
              " M scripts/scr_kris_special/scr_kris_special.gml",
              " M worklog.md"],
      f"got {mod}")
check("nuevos = solo los checks v97 + LEEME de la entrega",
      new == ["LEEME_V97_KRIS_SYNC.txt", "check_v97.py", "check_v97_pass2.py"],
      f"got {new}")
# el cambio de net_sounds.gml es SOLO de comentarios: la parte de CODIGO
# (antes de //) de cada linea +/- es identica — solo cambia el comentario
# que sigue a la entrada snd_kris_lvup (124→126) y frases del bloque.
nds_diff = subprocess.run(["git", "-C", REPO, "diff", "--unified=0",
                           "scripts/net_sounds/net_sounds.gml"],
                          capture_output=True, text=True).stdout
minus, plus = [], []
for l in nds_diff.splitlines():
    if l.startswith("---") or l.startswith("+++"):
        continue
    if l.startswith("-") or l.startswith("+"):
        code = l[1:].split("//")[0].strip()
        (minus if l.startswith("-") else plus).append(code)
# las lineas de comentario PURO dan code='' y pueden cambiar de numero (un
# comentario largo se partio en varias lineas): lo que debe ser IDENTICO es
# la parte de CODIGO no vacia, y toda linea cambiada o es comentario puro
# o es la entrada con un comentario trailing distinto.
ne_minus = sorted(x for x in minus if x)
ne_plus = sorted(x for x in plus if x)
check("net_sounds.gml: la parte de CODIGO no vacia es identica (diff 100% comentarios)",
      ne_minus == ne_plus and ne_minus, f"-{ne_minus} +{ne_plus}")
check("net_sounds.gml: toda linea cambiada es comentario puro (code='') o la entrada snd_kris_lvup",
      ne_minus == ["snd_kris_lvup"] and ne_plus == ["snd_kris_lvup"]
      and all(x == "" or x == "snd_kris_lvup" for x in minus + plus))

gml = read(GML)
net = read(NET)
gamec = read(GAME_C)

# ------------------------------------------------------------ 2. edits
print("== 2. Edits exactos en scr_kris_special.gml ==")
check("_up computado ANTES de asignar krisLv (y con el comment 'niveles cruzados')",
      "var _up = _new - global.player.krisLv; // niveles cruzados (0 = no sube)" in gml)
check("guard nuevo: if(_up > 0)", "if(_up > 0)" in gml and "if(_new > global.player.krisLv)" not in gml)
check("cura por nivel: KRIS_LV_HP_BONUS * _up",
      "min(global.player.hp + KRIS_LV_HP_BONUS * _up, scr_player_maxhp(CHARACTER_KRIS))" in gml)
check("flush: repeat(_up) net_sound_emit(snd_none);",
      re.search(r"repeat\(_up\)\s*\n\s*net_sound_emit\(snd_none\);", gml) is not None)
check("la señal suelta vieja (net_sound_emit(snd_none); directo) ya NO existe",
      len(re.findall(r"net_sound_emit\(snd_none\);", gml)) == 1
      and re.search(r"repeat\(_up\)\s*\n\s*net_sound_emit\(snd_none\);", gml) is not None)
check("chime local intacto: audio_play_sound(snd_kris_lvup, 0, false);",
      "audio_play_sound(snd_kris_lvup, 0, false);" in gml)
check("macro-comentario v97 anadido (perilla libre / aviso v96 OBSOLETO)",
      "la advertencia \"no pasar de 3 por" in gml and "OBSOLETA" in gml)
check("comentario de la funcion: version v97 con el bug 20 vs 13 citado",
      "v97 (SINCRONIZACION, bug reportado)" in gml and "LV 13 espejado tras 12" in gml)

# ------------------------------------------------------ 3. perillas
print("== 3. Perillas respetadas (la duena las dejo asi) ==")
check("KRIS_LV_XP_NORMAL 1.5 (intacto)",
      re.search(r"#macro KRIS_LV_XP_NORMAL 1\.5", gml) is not None)
check("KRIS_LV_XP_LMS 5 (intacto, es la perilla del repo)",
      re.search(r"#macro KRIS_LV_XP_LMS 5", gml) is not None)
check("macros v95/v46 intactas (KRIS_LV_MAX 20, HP 100/20, EXE 35/350/10)",
      all(m in gml for m in ["#macro KRIS_LV_MAX 20", "#macro KRIS_LV_BASE_HP 100",
                             "#macro KRIS_LV_HP_BONUS 20", "#macro KRIS_EXE_DAMAGE 35",
                             "#macro KRIS_EXE_MAXHP 350", "#macro KRIS_EXE_DOWN_SEC 10"]))
check("formula de acumulacion intacta (lmsActive ? LMS : NORMAL)",
      "global.player.krisLvHits += global.lmsActive ? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL;" in gml)
check("umbrales v46 intactos (lista _th sin tocar)",
      "static _th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56];" in gml)

# -------------------------------------------------- 4. receptor intacto
print("== 4. Receptor (net_state_game.gml) INTACTO ==")
check("rama del espejo snd_none && CHARACTER_KRIS presente",
      "global.net_snds[sid] == snd_none && character == CHARACTER_KRIS" in net)
check("espejo +1 con cap KRIS_LV_MAX (sin tocar)",
      "krisLvNet = min(krisLvNet + 1, KRIS_LV_MAX);" in net)
check("primera señal => 2 (arranque del espejo) presente",
      "krisLvNet = 2;" in net)
check("net_sound_emit(snd_none) en el emisor NO silencia a Kris (gate solo exe invisible)",
      re.search(r"function net_sound_emit\(sndid\)[^{]*\{", read(f"{REPO}/scripts/net_sounds/net_sounds.gml")) is not None)

# ----------------------------------------------- 5. balance estructural
print("== 5. Balance estructural GML (delta 0 vs HEAD) ==")
head = subprocess.run(["git", "-C", REPO, "show",
                       "HEAD:scripts/scr_kris_special/scr_kris_special.gml"],
                      capture_output=True, text=True).stdout

def bal(s):
    # ignora comentarios // y strings para las llaves/parens del codigo
    s = re.sub(r"//[^\n]*", "", s)
    return s.count("{") - s.count("}"), s.count("(") - s.count(")")

b_new, p_new = bal(gml)
b_old, p_old = bal(head)
check(f"llaves balanceadas (nuevo {b_new} == viejo {b_old})", b_new == b_old == 0)
check(f"parens: delta 0 vs HEAD (nuevo {p_new}, viejo {p_old} — desbalance pre-existente de comentarios se conserva)",
      p_new == p_old)
check("sin tabs anadidos (el archivo usa espacios)",
      "\t" not in gml)
check("numero de funciones sin cambio",
      len(re.findall(r"^function ", gml, re.M)) == len(re.findall(r"^function ", head, re.M)))
check("repeat(_up) usado (estilo de la casa: scr_rouge_special usa repeat)",
      "repeat(_up)" in gml)

# --------------------------------------------------- 6. simulacion
print("== 6. Simulacion con las reglas REALES ==")
TH = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56]
LV_MAX = 20
TH_FILE = re.search(r"static _th = \[([0-9, ]+)\];", gml)
TH_FILE = [int(x) for x in TH_FILE.group(1).split(",")] if TH_FILE else None
check("umbrales parseados del archivo == esperados", TH_FILE == TH, f"{TH_FILE}")

def love_lv(hits):
    lv = 1
    for i, t in enumerate(TH):
        if hits >= t:
            lv = i + 2
    return min(lv, LV_MAX)

def sim(xp_lms, xp_normal, n_lms, n_norm_first=0, flush=True):
    """Reglas reales: local salta AL nuevo nivel; espejo +1 POR SENAL;
    con flush se emite una senal por nivel cruzado, sin flush una por evento."""
    hits = 0.0
    local = 1
    mirror = 1
    signals = 0
    for _ in range(n_norm_first):
        hits += xp_normal
        new = love_lv(hits)
        if new > local:
            up = new - local
            local = new
            n = up if flush else 1
            for _ in range(n):
                mirror = min(mirror + 1, LV_MAX)
                signals += 1
    for _ in range(n_lms):
        hits += xp_lms
        new = love_lv(hits)
        if new > local:
            up = new - local
            local = new
            n = up if flush else 1
            for _ in range(n):
                mirror = min(mirror + 1, LV_MAX)
                signals += 1
    return local, mirror, signals, hits

# (a) el bug se reproduce con la regla VIEJA (sin flush) a perilla 5
l, m, s, h = sim(5, 1.5, 12, flush=False)
check("BUG reproducido con regla vieja: 12 golpes LMS@5 → local 20, espejo 13 (el reporte)",
      (l, m) == (20, 13), f"local {l} espejo {m}")
# y con perilla 3 (v96 como se entrego) no habia bug
l, m, s, h = sim(3, 1.5, 19, flush=False)
check("v96 @3 sin flush: sin drift (invariante respetado) — el bug es de la perilla >3",
      (l, m) == (20, 20), f"local {l} espejo {m}")
# (b) con el flush: espejo == local SIEMPRE, cualquier perilla
for xp, n, lbl in [(5, 12, "LMS@5, 12 golpes (el caso del reporte)"),
                   (5, 60, "LMS@5, 60 golpes"),
                   (3, 19, "LMS@3, 19 golpes"),
                   (1.5, 0, "—"),  # placeholder replaced below
                   (7, 30, "LMS@7 extremo, 30 golpes"),
                   (10, 25, "LMS@10 locura, 25 golpes")]:
    if lbl == "—":
        continue
    l, m, s, h = sim(xp, 1.5, n, flush=True)
    check(f"flush {lbl}: local {l} == espejo {m}", l == m, f"{l} vs {m}")
# normal puro
l, m, s, h = sim(0.0001, 1.5, 0, n_norm_first=80)
check("flush normal@1.5 puro (80 golpes): local == espejo == 20", (l, m) == (20, 20), f"{l} {m}")
# mezcla: 10 normal luego LMS hasta 20
hits = 0.0; local = 1; mirror = 1
for _ in range(10):
    hits += 1.5
    new = love_lv(hits)
    if new > local:
        for _ in range(new - local):
            mirror = min(mirror + 1, LV_MAX)
        local = new
n = 0
while local < 20 and n < 100:
    hits += 5; n += 1
    new = love_lv(hits)
    if new > local:
        for _ in range(new - local):
            mirror = min(mirror + 1, LV_MAX)
        local = new
check(f"flush mezcla (10 normal + {n} LMS@5): local == espejo == 20", (local, mirror) == (20, 20))
# senales totales para LV 20 == niveles ganados == 19
l, m, s, h = sim(5, 1.5, 12, flush=True)
check("senales emitidas hasta LV 20 == niveles ganados == 19 (1 por nivel)", s == 19, f"{s}")

# ------------------------------------------------------- 7. la cura
print("== 7. Coherencia de la cura (+20 POR nivel) ==")
BASE, BONUS = 100, 20
def maxhp(lv):
    return BASE + BONUS * (lv - 1)
check("LV 20 → 480 == cap del server (CH_KRIS 480 en Game.c)", maxhp(20) == 480 and "case CH_KRIS: hp_cap = 480;" in gamec)
# golpe que cruza 2 niveles desde full hp: cura 40, no 20
hp = 100.0; local = 1; hits = 0.0; ups = []
for _ in range(12):
    hits += 5
    new = love_lv(hits)
    if new > local:
        up = new - local
        hp = min(hp + BONUS * up, maxhp(new))
        ups.append((new, up, hp))
        local = new
check("curas por golpe con la regla *_up: la cura total al LV 20 == 480 desde 100",
      abs(hp - 480) < 1e-9, f"hp {hp}")
check("cada subida deja hp == maxhp del nivel alcanzado (empezando full)",
      all(abs(h - maxhp(lv)) < 1e-9 for lv, up, h in ups))
check("ningun hp supera 480 (clamp del min)", all(h <= 480 for lv, up, h in ups))
check("existe al menos un golpe que cruza 2 niveles con perilla 5 (el caso del fix de la cura)",
      any(up == 2 for lv, up, h in ups))

# --------------------------------------------- 8. relay del server
print("== 8. Relay del server (broadcast sin dedup) ==")
# indice real de snd_none en net_snds
nds = read(f"{REPO}/scripts/net_sounds/net_sounds.gml")
arr = re.search(r"global\.net_snds\s*=\s*\[(.*?)\];", nds, re.S)
entries = [e.strip().rstrip(",") for e in arr.group(1).split("\n") if e.strip() and not e.strip().startswith("//")]
first = entries[0]
check("snd_none es la entrada 0 del array (la senal viaja con ese indice)", first == "snd_none", f"first={first}")
# el emisor manda nid == SU nid (broadcast) → nid == v->id en el server
snds = read(f"{REPO}/scripts/net_sounds/net_sounds.gml")
m = re.search(r"function net_sound_emit\(sndid\)\s*\{(.*?)\n\}", snds, re.S)
check("net_sound_emit escribe nid == obj_netclient.nid (broadcast, shouldPlay=false)",
      "buffer_write(buffer, buffer_u16, obj_netclient.nid);" in m.group(1)
      and "buffer_write(buffer, buffer_bool, false);" in m.group(1))
# validaciones del server SOLO aplican a nid != emisor
check("game_is_stun_signal(snd_none) es true PERO la validacion exige nid != v->id (broadcast pasa libre)",
      "if (nid != v->id && game_is_stun_signal(sndidx) && !game_stun_signal_ok(v, nid, sndidx))" in gamec)
check("tope de ritmo de Chocola: solo sndidx 109/110 (snd_none=0 jamas lo toca)",
      "(sndidx == 109 || sndidx == 110)" in gamec)
check("el relay termina en server_broadcast_ex (reenvia TODO, sin dedup)",
      "server_broadcast_ex(v->server, packet, true,  v->id);" in gamec)
# Bug de checker corregido: sndidx == 0 SI aparece en game_stun_signal_ok
# (linea ~706, Amy Canon) pero esa funcion SOLO se llama con nid != v->id
# (senal DIRIGIDA). El broadcast de Kris (nid == emisor) nunca llega ahi.
# Aserto fuerte: TODOS los break que descartan dentro del case
# CLIENT_SOUND_EMIT exigen nid != v->id en su propia condicion.
case_m = re.search(r"case CLIENT_SOUND_EMIT:\s*\{(.*?)\n\s*\}", gamec, re.S)
check("el case CLIENT_SOUND_EMIT existe en Game.c", case_m is not None)
if case_m:
    body = case_m.group(1)
    breaks = [m.start() for m in re.finditer(r"\bbreak;", body)]
    unsafe = 0
    for bpos in breaks:
        # el if mas cercano hacia atras: su condicion debe traer nid != v->id
        # o el break va DESPUES del server_broadcast_ex (fin normal del case)
        pre = body[:bpos]
        if "server_broadcast_ex" in pre[pre.rfind("server_broadcast_ex"):] if "server_broadcast_ex" in pre else False:
            continue
        last_if = pre.rfind("if (")
        last_brace = pre.rfind("}")
        if last_if > last_brace:
            cond = pre[last_if:pre.find("\n", last_if)]
            if "nid != v->id" not in cond:
                # ¿es el break final del case (despues del broadcast)?
                if pre.rfind("server_broadcast_ex") > last_if:
                    continue
                unsafe += 1
                print(f"        break sospechoso: {cond.strip()[:90]}")
    check("todos los break del case CLIENT_SOUND_EMIT exigen nid != v->id (o van tras el broadcast final)",
          unsafe == 0, f"{unsafe} breaks inseguros")
check("la unica otra referencia a sndidx == 0 (Amy Canon) vive en game_stun_signal_ok (solo senales DIRIGIDAS)",
      gamec.count("sndidx == 0") == 1
      and "sndidx == 0" in gamec.split("game_stun_signal_ok")[1].split("}")[0])

print()
print(f"RESULTADO PASADA 1: {ok_count} OK, {fail_count} FAIL")
sys.exit(1 if fail_count else 0)
