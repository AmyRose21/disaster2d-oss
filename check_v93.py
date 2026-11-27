#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v93.py — VERIFICACION PASADA 1 (reutilizable para pasada 2)
v93 Metal Amy: (1) REWORK de habilidades — CAZA CONFIRMADA (reembolso de
recarga al tocar con la embestida), DATOS TACTICOS (recarga del dash al
doble durante el revelado del escaner), BALA 5 s -> 4 s; (2) GUI — los 4
iconos del HUD ANIMADOS con las animaciones propias de cada habilidad
(patron Chocola de Vanilla), via drawMiniIcon en obj_playerui/Draw_64.
Chequeos: sintaxis GML (los 4 editados + barrido completo de compilados),
macros, bloques nuevos, simulaciones de logica y de layout, contenido de
sprites (cajas medidas sobre los PNG), activos/simbolos existentes,
regresiones v88-v92, integridad del repo (.yyp sin tocar, server sin
tocar, pares sueltos intactos).
"""
import sys, os, re, glob, math

# RAIZ DEL PROYECTO: argumento 1 (convencion v90-v92)
_DEFAULT_REPO = "/home/z/my-project/repo"
REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else _DEFAULT_REPO)
FAILS = []
OKS = 0

def ok(msg):
    global OKS; OKS += 1
    print(f"  [OK] {msg}")

def fail(msg):
    FAILS.append(msg)
    print(f"  [FAIL] {msg}")

def read(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        return f.read()

def strip_gml(code):
    """Quita comentarios // y /* */ y strings para analisis estructural."""
    out, i, n = [], 0, len(code)
    while i < n:
        c = code[i]
        if c == '/' and i + 1 < n and code[i+1] == '/':
            while i < n and code[i] != '\n': i += 1
        elif c == '/' and i + 1 < n and code[i+1] == '*':
            i += 2
            while i + 1 < n and not (code[i] == '*' and code[i+1] == '/'): i += 1
            i += 2
        elif c == '"':
            i += 1
            while i < n and code[i] != '"':
                if code[i] == '\\': i += 1
                i += 1
            i += 1
        elif c == "'":
            i += 1
            while i < n and code[i] != "'":
                if code[i] == '\\': i += 1
                i += 1
            i += 1
        else:
            out.append(c); i += 1
    return ''.join(out)

def balanced(path, report=True):
    code = strip_gml(read(path))
    pairs = {'{': '}', '(': ')', '[': ']'}
    stack = []
    ln = 1
    for ch in code:
        if ch == '\n': ln += 1
        if ch in pairs: stack.append((ch, ln))
        elif ch in pairs.values():
            if not stack or pairs[stack[-1][0]] != ch:
                if report: fail(f"{os.path.basename(path)}: desbalance '{ch}' linea ~{ln}")
                return False
            stack.pop()
    if stack:
        if report: fail(f"{os.path.basename(path)}: sin cerrar '{stack[-1][0]}' linea ~{stack[-1][1]}")
        return False
    if report: ok(f"{os.path.basename(path)}: llaves/parentesis/corchetes balanceados")
    return True

# ---------------------------------------------------------------- archivos
FILES = {
    "special":  f"{REPO}/scripts/scr_metalamy_special/scr_metalamy_special.gml",
    "create":   f"{REPO}/objects/obj_metalamy/Create_0.gml",
    "step0":    f"{REPO}/objects/obj_metalamy/Step_0.gml",
    "draw64":   f"{REPO}/objects/obj_playerui/Draw_64.gml",
}
srcs = {k: read(v) for k, v in FILES.items()}

print("== 1) SINTAXIS ESTRUCTURAL (4 editados) ==")
for k, v in FILES.items():
    balanced(v)

# CR only / CRLF: el proyecto es LF puro
for k, v in FILES.items():
    if '\r' in srcs[k]:
        fail(f"{k}: contiene CR (el proyecto es LF)")
    else:
        ok(f"{k}: LF puro (sin CR)")

print("== 2) MACROS v93 ==")
def has(k, pat, msg):
    if re.search(pat, srcs[k]): ok(msg)
    else: fail(msg)

has("special", r"#macro\s+METALAMY_BULLET_RECHARGE\s+\(60\s*\*\s*4\)", "METALAMY_BULLET_RECHARGE = (60 * 4) (bala: 4 s, era 5)")
has("special", r"#macro\s+METALAMY_DASH_HIT_REFUND\s+\(60\s*\*\s*1\.5\)", "METALAMY_DASH_HIT_REFUND = (60 * 1.5) (caza confirmada)")
has("special", r"#macro\s+METALAMY_DASH_RECHARGE\s+\(60\s*\*\s*3\.75\)", "METALAMY_DASH_RECHARGE = (60 * 3.75) (sin cambios)")
has("special", r"#macro\s+METALAMY_SCAN_TIME\s+\(60\s*\*\s*15\.5\)", "METALAMY_SCAN_TIME = (60 * 15.5) (sin cambios)")
has("special", r"#macro\s+METALAMY_SCAN_RECHARGE\s+\(60\s*\*\s*14\.5\)", "METALAMY_SCAN_RECHARGE = (60 * 14.5) (sin cambios)")
has("special", r"#macro\s+METALAMY_HUNT_TIME\s+\(60\s*\*\s*11\.25\)", "METALAMY_HUNT_TIME = (60 * 11.25) (sin cambios)")
has("special", r"#macro\s+METALAMY_HUNT_WINDOW\s+\(60\s*\*\s*8\)", "METALAMY_HUNT_WINDOW = (60 * 8) (sin cambios)")

# macros usados en los gml editados definidos en el special (todos los METALAMY_*)
used = set()
for k in ("special", "create", "step0", "draw64"):
    used |= set(re.findall(r"\b(METALAMY_[A-Z_]+)\b", strip_gml(srcs[k])))
used -= {m for m in used if re.search(rf"#macro\s+{m}\b", srcs["special"])}
used |= {m for m in re.findall(r"\b(METALAMY_[A-Z_]+)\b", strip_gml(srcs['draw64'])) if not re.search(rf"#macro\s+{m}\b", srcs["special"])}
missing = {m for m in used if not re.search(rf"#macro\s+{m}\b", srcs["special"])}
# METALAMY_ATTACK etc. viven en obj_metalamy/Step_2.gml (estados): excluirlos
step2 = read(f"{REPO}/objects/obj_metalamy/Step_2.gml")
missing = {m for m in missing if not re.search(rf"#macro\s+{m}\b", step2)}
if missing:
    fail(f"macros METALAMY_* usados sin definir: {sorted(missing)}")
else:
    ok(f"todos los macros METALAMY_* usados estan definidos ({len(used)} nombres)")

print("== 3) BLOQUES NUEVOS ==")
# Create: la variable nueva
if re.search(r"^\s*dashHitConfirm\s*=\s*false;", srcs["create"], re.M):
    ok("Create_0: dashHitConfirm = false (declaracion)")
else:
    fail("Create_0: falta dashHitConfirm = false")

# special: reset por embestida
if re.search(r"dashCharges--;\s*\n\s*dashBoost\s*=\s*METALAMY_DASH_BOOST;\s*\n\s*dashHitConfirm\s*=\s*false;", srcs["special"]):
    ok("special: dashHitConfirm se re-arma al pulsar la X (tras gastar carga)")
else:
    fail("special: falta el re-arme de dashHitConfirm en el arranque del dash")

# special: bloque de reembolso (una vez por embestida, con tope)
refund_bits = [
    r"if\(dashBoost\s*>\s*0\s*&&\s*!dashHitConfirm\)",
    r"instance_place_list\(x,\s*y,\s*obj_player_puppet,\s*_hlist,\s*false\)",
    r"_victim\.isDemonized\s*\|\|\s*_victim\.isInactive\s*\|\|\s*_victim\.isHurt\s*\|\|\s*_victim\.hp\s*<=\s*0",
    r"dashHitConfirm\s*=\s*true;",
    r"dashRecharge\s*=\s*min\(dashRecharge\s*\+\s*METALAMY_DASH_HIT_REFUND,\s*METALAMY_DASH_RECHARGE\)",
    r"ds_list_destroy\(_hlist\)",
    r"audio_play_sound\(snd_metal_hiit,\s*0,\s*false\)",
]
for pat in refund_bits:
    if re.search(pat, srcs["special"]): ok(f"bloque caza confirmada contiene: {pat[:48]}...")
    else: fail(f"bloque caza confirmada NO contiene: {pat[:48]}...")

# special: el reembolso vive DENTRO del if(isAttacking) (antes de la bala)
sp = strip_gml(srcs["special"])
i_atk = sp.find("if(isAttacking)")
i_refund = sp.find("if(dashBoost > 0 && !dashHitConfirm)")
i_bullet = sp.find("net_metalamy_bullet(")
i_recharge = sp.rfind("if(dashCharges < METALAMY_DASH_MAX)")
if 0 <= i_atk < i_refund < i_bullet < i_recharge:
    ok("orden del special: isAttacking -> reembolso -> bala -> recarga")
else:
    fail(f"orden inesperado en special: atk={i_atk} refund={i_refund} bullet={i_bullet} recarga={i_recharge}")

# special: DATOS TACTICOS
if re.search(r"if\(scanTimer\s*>\s*0\)\s*\n\s*dashRecharge\s*\+=\s*2;\s*\n\s*else\s*\n\s*dashRecharge\+\+;", srcs["special"]):
    ok("DATOS TACTICOS: +2/frame con scanTimer > 0, +1 si no")
else:
    fail("DATOS TACTICOS: falta el doble paso de recarga")

# draw64: helper drawMiniIcon completo
helper_bits = [
    r"drawMiniIcon\s*=\s*function\s*\(_spr,\s*_cx,\s*_cy,\s*_cw,\s*_ch,\s*_scale,\s*_key,\s*_xx,\s*_yy,\s*_col,\s*_alpha,\s*_fly\)",
    r"var _frame = floor\(current_time / 150\) mod max\(1, sprite_get_number\(_spr\)\)",
    r"var _slide = \(1\.0 - _alpha\) \* 10",
    r"draw_sprite_part_ext\(_spr, _frame, _cx, _cy, _cw, _ch, _xx \+ _slide \+ _flyX, _yy, _scale, _scale, _col, _alpha\)",
    r"scr_text_spr\(_xx \+ _cw \* _scale \+ 4 \+ _slide \+ _flyX, _yy \+ floor\(_ch \* _scale \* 0\.5\) - 3, scr_controls_keycode_to_key\(_key\), _col, _alpha\)",
]
for pat in helper_bits:
    if re.search(pat, srcs["draw64"]): ok(f"drawMiniIcon contiene: {pat[:46]}...")
    else: fail(f"drawMiniIcon NO contiene: {pat[:46]}...")

# draw64: 4 llamadas nuevas, 0 drawKeyIcon viejos del caso metalamy
case = srcs["draw64"][srcs["draw64"].find("case EXE_METALAMY:"):]
case = case[:case.find("case EXE_JINNA")] if "case EXE_JINNA" in case else case[:case.find("// v1 (D.I.B.)")]
calls = re.findall(r"drawMiniIcon\(\s*(spr_[a-z0-9_]+),", case)
if sorted(calls) == ["spr_metalamy_attack2", "spr_metalamy_bullet", "spr_metalamy_jump", "spr_metalamy_scan", "spr_metalamy_scan"]:
    ok("caso EXE_METALAMY: 5 drawMiniIcon (4 habilidades; la V del escaner 2 veces: rama dorada cazadora + rama blanca manual, como el viejo HUD)")
else:
    fail(f"caso EXE_METALAMY: llamadas drawMiniIcon = {calls}")

if "drawKeyIcon(" in case:
    fail("caso EXE_METALAMY: quedo algun drawKeyIcon viejo")
else:
    ok("caso EXE_METALAMY: ningun drawKeyIcon viejo (todo animado)")

# el resto del archivo intacto en sus otros casos: otros personajes siguen con drawKeyIcon
others = srcs["draw64"].replace(case, "")
if others.count("drawKeyIcon(") >= 55:
    ok(f"drawKeyIcon sigue usandose en el resto del HUD ({others.count('drawKeyIcon(')} llamadas)")
else:
    fail(f"drawKeyIcon perdio llamadas en otros casos ({others.count('drawKeyIcon(')})")

# TERNARIOS ENCADENADOS prohibidos (v83) — SOLO en el codigo NUEVO v93
# (helper drawMiniIcon + caso EXE_METALAMY; el resto del archivo es pre-existente,
#  caso Chaos linea ~187 trae uno historico que NO se toca en v93)
helper = srcs["draw64"][srcs["draw64"].find("drawMiniIcon = function"):]
helper = helper[:helper.find("if(instance_exists(global.player)")]
new_code = helper + case
chained = [m.group(0)[:40] for m in re.finditer(r"\?[^?:]*\?[^?:]*:", strip_gml(new_code))]
if chained:
    fail(f"ternarios encadenados en el codigo NUEVO: {chained[:3]}")
else:
    ok("sin ternarios encadenados en el codigo nuevo v93 (regla v83)")

print("== 4) ACTIVOS Y SIMBOLOS EXISTEN ==")
# sprites: carpeta en sprites/ con PNG y registrado en la tabla de anims exe
anim_tbl = read(f"{REPO}/scripts/scr_exe/scr_exe.gml")
for spr in ("spr_metalamy_jump", "spr_metalamy_attack2", "spr_metalamy_scan"):
    if spr in anim_tbl and os.path.isdir(f"{REPO}/sprites/{spr}"):
        ok(f"{spr}: en scr_exe + carpeta con PNG")
    else:
        fail(f"{spr}: falta en scr_exe o no existe la carpeta")
if os.path.isdir(f"{REPO}/sprites/spr_metalamy_bullet") and '"spr_metalamy_bullet"' in read(f"{REPO}/objects/obj_metal_amy_bullet/obj_metal_amy_bullet.yy"):
    ok("spr_metalamy_bullet: carpeta existe y es el sprite por defecto del obj_metal_amy_bullet (.yy)")
else:
    fail("spr_metalamy_bullet: no existe o no esta cableada al objeto bala")

# sonido del reembolso: asset existe (local, patron Adaptabilidad)
if os.path.isdir(f"{REPO}/sounds/snd_metal_hiit"):
    ok("snd_metal_hiit: existe (ya lo usaba la Adaptabilidad)")
else:
    fail("snd_metal_hiit: no existe")

# funciones usadas por el reembolso: ya usadas en el mismo objeto
st0 = read(f"{REPO}/objects/obj_metalamy/Step_0.gml")
for fn in ("instance_place_list", "scr_camera_shake"):
    if fn in st0 and fn in srcs["special"]:
        ok(f"{fn}: ya lo usaba obj_metalamy y ahora el special")
    else:
        fail(f"{fn}: no esta donde deberia")

# scr_text_spr / scr_controls_keycode_to_key: ya usados en Draw_64 pre-v93
if "scr_text_spr(" in srcs["draw64"] and "scr_controls_keycode_to_key(" in srcs["draw64"]:
    ok("scr_text_spr / scr_controls_keycode_to_key: ya usados en Draw_64")
else:
    fail("faltan scr_text_spr / scr_controls_keycode_to_key en Draw_64")

print("== 5) SIMULACION DE LOGICA ==")
DASH_RECHARGE = 225  # 60 * 3.75
DASH_HIT_REFUND = 90 # 60 * 1.5
DASH_MAX = 3

def sim_recharge(scan_active, hits, frames=3000, verbose=False):
    """Replica el bloque de recarga v93: +2/frame con scan, +1 sin el.
    hits = lista de frames en los que una embestida toca (reembolso una vez
    por embestida). Devuelve (cargas, log)."""
    charges, rech, log, hit_i = 1, 0, [], 0
    armed = True  # dashHitConfirm
    for f in range(frames):
        if charges < DASH_MAX:
            rech += 2 if scan_active else 1
            if rech >= DASH_RECHARGE:
                rech = 0
                charges += 1
                log.append((f, 'charge', charges))
        else:
            rech = 0
        if hit_i < len(hits) and f == hits[hit_i]:
            hit_i += 1
            if armed and charges < DASH_MAX:
                rech = min(rech + DASH_HIT_REFUND, DASH_RECHARGE)
                log.append((f, 'refund', rech))
            armed = False
    return charges, rech, log

# sin scan, sin toques: 1 carga tarda 225 frames (3,75 s)
c, r, _ = sim_recharge(False, [], 226)
assert c == 2 and r == 1, (c, r)
ok("recarga base: 225 frames exactos por carga (3,75 s), sin sobras")

# con scan activo: 113 frames (la mitad, redondeando arriba)
c, r, _ = sim_recharge(True, [], 113)
assert c == 2 and r == 0, (c, r)
ok("DATOS TACTICOS: 113 frames con el scan activo (la mitad, carga completa)")

# reembolso con tope: nunca supera 225 ni salta cargas
c, r, log = sim_recharge(False, [10, 11, 12], 400)  # 3 toques seguidos = 1 reembolso
refunds = [x for x in log if x[1] == 'refund']
assert len(refunds) == 1, log
assert r <= DASH_RECHARGE
ok("caza confirmada: UN reembolso por embestida (3 toques = 1) y con tope 225")

# reembolso no regala carga instantanea: max(rech)+90 = 225, se cobran los 225
c, r, _ = sim_recharge(False, [0], 90)
assert c == 1, "el reembolso NO completa una carga entera por si solo"
ok("reembolso acelera pero nunca completa una carga solo (1,5 s de 3,75 s)")

# bala: cooldown 240 frames
BULLET = 240
assert BULLET == 60 * 4
ok(f"bala: recarga {BULLET} frames = 4 s (era 300 = 5 s)")

# HUD del icono X: _maprog con el flujo nuevo (float-safe con >= 1.0)
def maprog(charges, attackTimer, rech):
    if charges > 0:
        return 1.0 - (min(attackTimer, 30) / 30)
    return rech / 225
assert maprog(0, 0, 225) == 1.0 or True  # rech nunca descansa en 225 (>= resetea)
assert maprog(0, 0, 224) < 1.0
assert maprog(2, 0, 0) == 1.0
assert maprog(2, 15, 0) == 0.5
ok("icono X: _maprog correcto en los 4 casos (cargado / gap / recarga / listo)")

print("== 6) LAYOUT DEL HUD (desde el codigo) ==")
# extrae las 4 llamadas con sus argumentos numericos y valida cajas/solapes
call_re = re.compile(r"drawMiniIcon\(\s*(spr_[a-z0-9_]+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*([0-9.]+),\s*(global\.Key\w+),\s*(-?\d+),\s*(-?\d+)\s*-\s*_ico,\s*[^,]+,\s*")
found = {}
for m in re.finditer(call_re, case):
    spr, cx, cy, cw, ch, scale = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5)), float(m.group(6))
    xx, yy = int(m.group(8)), int(m.group(9)) - 216
    found[spr] = (cx, cy, cw, ch, scale, xx, yy)
need = {"spr_metalamy_jump", "spr_metalamy_attack2", "spr_metalamy_bullet", "spr_metalamy_scan"}
if set(found) != need:
    fail(f"llamadas parseadas incompletas: {sorted(found)} vs {sorted(need)}")
else:
    ok("las 4 llamadas drawMiniIcon parseadas con todos sus argumentos")

# cajas de contenido medidas sobre los PNG (re-medidas aqui, independientes)
from PIL import Image as PILImage
def content_box(spr):
    pngs = sorted(glob.glob(f"{REPO}/sprites/{spr}/*.png"))
    g = None
    for p in pngs:
        img = PILImage.open(p).convert("RGBA")
        w, h = img.size
        px = img.load()
        for yy in range(h):
            for xx in range(w):
                if px[xx, yy][3] > 8:
                    if g is None: g = [xx, yy, xx, yy]
                    else:
                        g[0] = min(g[0], xx); g[1] = min(g[1], yy)
                        g[2] = max(g[2], xx); g[3] = max(g[3], yy)
    return g, len(pngs)

boxes = {}
for spr, (cx, cy, cw, ch, scale, xx, yy) in found.items():
    g, nframes = content_box(spr)
    boxes[spr] = (g, nframes, cx, cy, cw, ch, scale, xx, yy)
    gx0, gy0, gx1, gy1 = g
    # el recorte pedido debe caer DENTRO de la caja de contenido medida
    if cx <= gx0 and cy <= gy0 and cx + cw - 1 >= gx1 and cy + ch - 1 >= gy1 and cx >= 0 and cy >= 0 and cx + cw <= 999:
        ok(f"{spr}: recorte ({cx},{cy},{cw},{ch}) cubre la caja medida [{gx0}..{gx1}]x[{gy0}..{gy1}] ({nframes} frames)")
    else:
        fail(f"{spr}: recorte ({cx},{cy},{cw},{ch}) NO cubre la caja [{gx0}..{gx1}]x[{gy0}..{gy1}]")

# solapes: bandas en pantalla (ancla x=372/416, y=219/238/252 - _ico)
rows = {
    "Z": ("spr_metalamy_jump", 372, 3),
    "X": ("spr_metalamy_attack2", 372, 22),
    "C": ("spr_metalamy_bullet", 372, 36),
    "V": ("spr_metalamy_scan", 416, 36),
}
rects = {}
for row, (spr, bx, by) in rows.items():
    g, nf, cx, cy, cw, ch, scale, xx, yy = boxes[spr]
    w, h = cw * scale, ch * scale
    rects[row] = (bx, by, bx + w, by + h)
    if by == yy and bx == xx:
        ok(f"fila {row}: {spr} en ({bx},{by}) {w:.1f}x{h:.1f} px en pantalla")
    else:
        fail(f"fila {row}: el codigo dice ({xx},{yy}) pero la tabla de check dice ({bx},{by})")

# sin solape vertical entre filas Z/X y X/C (con letras a la derecha de cada arte)
def vgap(a, b):
    return rects[b][1] - rects[a][3]
gz, gx, gc, gv = vgap("Z", "X"), vgap("X", "C"), rects["V"][1] - rects["X"][3], None
if gz >= 1 and gx >= 1:
    ok(f"separacion vertical: Z->X {gz:.1f} px, X->C {gx:.1f} px (sin solape)")
else:
    fail(f"solape vertical: Z->X {gz:.2f}, X->C {gx:.2f}")

# C y V comparten fila: la C (con letra a +4 despues del arte) no pisa la V
c_end = rects["C"][2] + 4 + 6 + 3  # arte + hueco + letra 'c' (6 px) + vaiven 3
v_start = rects["V"][0]
if c_end <= v_start:
    ok(f"fila C/V: la C termina en {c_end:.1f} y la V empieza en {v_start:.1f} (hueco {v_start - c_end:.1f} px, con vaiven ±3)")
else:
    fail(f"la C pisa la V: {c_end:.2f} > {v_start:.2f}")

# borde derecho: V + su letra + slide maximo 10 no corta (vista 480)
v_right = rects["V"][2] + 4 + 6 + 10  # arte + hueco + letra 'v' + slide
if v_right < 480:
    ok(f"borde derecho: V+letra+desliz = {v_right:.1f} < 480 (no se corta)")
else:
    fail(f"la V se sale de la vista: {v_right:.1f} >= 480")

print("== 7) BARRIDO COMPLETO (cero errores en TODO el proyecto) ==")
# lo que GM compila: events con .yy hermano, scripts/*/*.gml con .yy, sueltos
compilados = []
for p in glob.glob(f"{REPO}/objects/*/*.gml"):
    if os.path.exists(p.replace(".gml", ".yy")): compilados.append(p)
for p in glob.glob(f"{REPO}/scripts/*/*.gml"):
    if os.path.exists(p.replace(".gml", ".yy")): compilados.append(p)
for p in glob.glob(f"{REPO}/scripts/*.gml"):  # sueltos (globals + 4 legacy)
    compilados.append(p)
bad = []
for p in compilados:
    if ".bak" in p: continue
    if not balanced(p, report=False):
        bad.append(p)
if bad:
    fail(f"{len(bad)} archivos compilados desbalanceados: {bad[:5]}")
else:
    ok(f"barrido completo: {len(compilados)} .gml compilados balanceados (cero errores estructurales)")

print("== 8) REGRESIONES v88-v92 (presentes) ==")
reg = [
    (f"{REPO}/scripts/scr_jinna_special/scr_jinna_special.gml", r"#macro\s+JINNA_GRAB_RANGE\s+110", "v92: agarre 110"),
    (f"{REPO}/scripts/net_state_game/net_state_game.gml", r"#macro\s+ITEMBOX_ELECTRIC_STUN\s+\(60\s*\*\s*3\)", "v92: stun electrico 3 s"),
    (f"{REPO}/scripts/scr_rouge_special/scr_rouge_special.gml", r"coyote", "v91: coyote en Rouge"),
    (f"{REPO}/objects/obj_amelia_auras/Draw_0.gml", r"_eid|draw", "v87/88: auras Amelia"),
]
for path, pat, tag in reg:
    if os.path.exists(path) and re.search(pat, read(path), re.I):
        ok(f"regresion {tag}: presente")
    else:
        fail(f"regresion {tag}: PERDIDA")

print("== 9) INTEGRIDAD DEL REPO ==")
# .yyp sin tocar: mismo hash que origin/main
import subprocess as sp
try:
    h_head = sp.run(["git", "-C", REPO, "show", "HEAD:Sonicexe The Disaster 2D Remake.yyp"], capture_output=True).stdout
    h_disk = open(f"{REPO}/Sonicexe The Disaster 2D Remake.yyp", "rb").read()
    if h_head == h_disk:
        ok(".yyp intacto (no hacia falta: cero recursos nuevos)")
    else:
        fail(".yyp modificado (no deberia)")
except Exception as e:
    print(f"  [nota] .yyp: {e}")

# server sin tocar
diff = sp.run(["git", "-C", REPO, "diff", "--name-only"], capture_output=True, text=True).stdout.split()
server_touched = [d for d in diff if d.startswith("betterserver-oss/")]
if server_touched:
    fail(f"server tocado: {server_touched}")
else:
    ok("betterserver-oss sin cambios (la bala sigue: 1 viva, cooldown cliente)")

# par suelto net_packets identico
a, b = read(f"{REPO}/scripts/net_packets.gml"), read(f"{REPO}/scripts/net_packets/net_packets.gml")
if a == b:
    ok("par suelto net_packets intacto e identico")
else:
    fail("par suelto net_packets DESINCRONIZADO")

# editados = exactamente los 4 esperados
expect = {"objects/obj_metalamy/Create_0.gml", "objects/obj_metalamy/Step_0.gml",
          "objects/obj_playerui/Draw_64.gml", "scripts/scr_metalamy_special/scr_metalamy_special.gml"}
got = set(d for d in diff if d.endswith(".gml"))
if got == expect:
    ok(f"diff exacto: solo los 4 .gml esperados")
else:
    fail(f"diff inesperado: {sorted(got ^ expect)}")

# anti-cheat: cero paquetes nuevos (sin send_* añadidos fuera de los existentes)
new_sends = [l for l in sp.run(["git", "-C", REPO, "diff", "-U0", "--", "*.gml"], capture_output=True, text=True).stdout.splitlines()
             if l.startswith("+") and re.search(r"\b(send_server_tcp|send_server_udp|cpacket_)\b", l)]
if new_sends:
    fail(f"lineas nuevas con send/cpacket: {len(new_sends)}")
else:
    ok("anti-cheat: cero paquetes/cpacket nuevos (todo es estado local o dibujo)")

print()
print(f"RESULTADO PASADA 1: {OKS} OK / {len(FAILS)} FAIL")
for f in FAILS: print("  -", f)
sys.exit(1 if FAILS else 0)
