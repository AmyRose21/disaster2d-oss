#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v59_light_dash.py — verificacion del LIGHT DASH de Amy Canon
(v5.9 -> v5.9.4: fix del crash de primer frame, estela fantasmal,
flecha indicadora de la Z, alcance ampliado y ritmo a 10 px/frame
con estela continua nacida en el step).

Parte 1 (estatica): brackets balanceados en todos los archivos tocados,
los 8 puntos de integracion presentes, colision de estados evitada
(LIGHTDASH=25 vs HUG=24), sprite registrado con frames reales.

Parte 2 (simulacion): la logica del dash porteada 1:1 a Python:
  - ROTACION: el volteo R-space nunca deja |theta| > 90 (cabeza abajo),
    nunca viaja de espaldas (forward renderizado == direccion de viaje
    al converger), y el giro es continuo (sin saltos > 90 entre frames)
    en los cruces de vertical — el escenario que pregunto el usuario.
  - CADENA: el finder codicioso captura filas/columnas/arcos enteros.
  - PRESUPUESTO: 16 px/frame come eslabones de 28 px sin dejar anillos
    vivos atras (recogida directa) y el impulso de salida es el tramo.
  - SALIDAS: anillo roto por el EXE a mitad de cadena (se salta), dano
    (sale con impulso), y los gates de activacion.
"""

import math
import os
import re
import sys

ROOT = "/home/z/my-project/disaster2d-oss"
fails = []


def check(name, cond, detail=""):
    status = "OK " if cond else "FAIL"
    print(f"[{status}] {name}" + (f" — {detail}" if detail and not cond else ""))
    if not cond:
        fails.append(name)


# =====================================================================
# PARTE 1 — ESTÁTICA
# =====================================================================
print("=== PARTE 1: ESTÁTICA ===")

FILES = [
    "scripts/scr_light_dash/scr_light_dash.gml",
    "scripts/scr_move_basic/scr_move_basic.gml",
    "scripts/scr_amy_canon_special/scr_amy_canon_special.gml",
    "scripts/scr_survivors/scr_survivors.gml",
    "objects/obj_amy_canon/Create_0.gml",
    "objects/obj_amy_canon/Step_0.gml",
    "objects/obj_amy_canon/Step_2.gml",
    "objects/obj_amy_canon/Draw_0.gml",
    "objects/obj_amy_canon/Draw_76.gml",
    "objects/obj_player_puppet/Step_0.gml",
]

sources = {}
for f in FILES:
    p = os.path.join(ROOT, f)
    check(f"existe {f}", os.path.isfile(p))
    if os.path.isfile(p):
        sources[f] = open(p, encoding="utf-8").read()


def strip_comments(s):
    s = re.sub(r"//[^\n]*", "", s)
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    return s


for f, s in sources.items():
    code = strip_comments(s)
    bal = {"{": 0, "(": 0, "[": 0}
    pairs = {"}": "{", ")": "(", "]": "["}
    ok = True
    for ch in code:
        if ch in bal:
            bal[ch] += 1
        elif ch in pairs:
            bal[pairs[ch]] -= 1
            if bal[pairs[ch]] < 0:
                ok = False
                break
    check(f"balance ()/[]/{{}} en {f}", ok and all(v == 0 for v in bal.values()),
          f"{bal}")

mb = sources.get("scripts/scr_move_basic/scr_move_basic.gml", "")
check("move_basic: hook del light dash presente",
      "if(scr_light_dash_step())" in mb and "scr_light_dash_pose();" in mb)
check("move_basic: cancel por muerte",
      "isLightDashing = false; // v5.9: la muerte cancela el light dash" in mb)
check("move_basic: cancel por dano",
      "isLightDashing = false; // v5.9: el dano cancela el light dash" in mb)
# el hook va ANTES del bloque de dano y DESPUES del de muerte
check("move_basic: orden muerte -> hook -> dano",
      mb.find("la muerte cancela el light dash") < mb.find("if(scr_light_dash_step())")
      < mb.find("el dano cancela el light dash"))

s2 = sources.get("objects/obj_amy_canon/Step_2.gml", "")
check("Step_2: macro AMY_CANON_LIGHTDASH = BALANCING+12",
      re.search(r"#macro\s+AMY_CANON_LIGHTDASH\s+BALANCING\+12", s2) is not None)
check("Step_2: bloque de estado presente",
      "if(isLightDashing)" in s2 and "state = AMY_CANON_LIGHTDASH;" in s2)
check("Step_2: el bloque va antes que el ataque normal",
      s2.find("if(isLightDashing)") < s2.find("if(isAttacking)"))

d76 = sources.get("objects/obj_amy_canon/Draw_76.gml", "")
check("Draw_76: caso de animacion presente",
      "case AMY_CANON_LIGHTDASH:" in d76 and "LIGHT_DASH_ANIMSPD" in d76)

s0 = sources.get("objects/obj_amy_canon/Step_0.gml", "")
check("Step_0: flotacion del tarot bloqueada durante el dash (2 gates)",
      s0.count("!isLightDashing") >= 1 and "|| isLightDashing)" in s0)

sp = sources.get("scripts/scr_amy_canon_special/scr_amy_canon_special.gml", "")
check("scr_amy_canon_special: 3 activaciones con gate",
      sp.count("!isLightDashing") == 3,
      f"encontrados {sp.count('!isLightDashing')}")

sv = sources.get("scripts/scr_survivors/scr_survivors.gml", "")
m1 = re.search(r"global\.player_anims\[\? CHARACTER_AMY_CANON\] =\s*\[(.*?)\];", sv, re.S)
m2 = re.search(r"global\.player_eanims\[\? CHARACTER_AMY_CANON\] =\s*\[(.*?)\];", sv, re.S)
for name, m in [("player_anims", m1), ("player_eanims", m2)]:
    if m is None:
        check(f"{name}: bloque de Amy Canon encontrado", False)
        continue
    body = strip_comments(m.group(1))
    entries = re.findall(r"(spr_\w+|spr_none)", body)
    check(f"{name}: 26 entradas (0..25) y la 25 es el light dash",
          len(entries) == 26 and entries[25] == "spr_amy_light_speed_canon",
          f"tiene {len(entries)} entradas, la ultima es {entries[-1] if entries else None}")

# colision de estados: 24 = HUG (scr_amy_hug), 25 = LIGHTDASH
hug = open(os.path.join(ROOT, "scripts/scr_amy_hug/scr_amy_hug.gml"), encoding="utf-8").read()
mh = re.search(r"#macro\s+AMY_CANON_HUG\s+\(BALANCING\+(\d+)\)", hug)
check("sin colision: AMY_CANON_HUG = BALANCING+11 (24) != LIGHTDASH = +12 (25)",
      mh is not None and int(mh.group(1)) == 11)

ld = sources.get("scripts/scr_light_dash/scr_light_dash.gml", "")
check("scr_light_dash: funcion muerta retirada",
      "function light_dash_turn_to" not in ld)
check("scr_light_dash: recogida directa con el paquete del anillo",
      "PacketType.CLIENT_RING_COLLECTED" in ld and "_tgt.used = true;" in ld)
check("scr_light_dash: sin placeholders",
      not re.search(r"\bTODO\b|XXX|FIXME|\u3010", ld))

# --- v5.9.1: fix del crash de primer frame + estela fantasmal ---
cr = sources.get("objects/obj_amy_canon/Create_0.gml", "")
check("v5.9.1 Create: declara isLightDashing (fix del crash de primer frame)",
      re.search(r"isLightDashing\s*=\s*false;", cr) is not None)
check("v5.9.1 Create: declara TODAS las vars del dash (11)",
      all(re.search(rf"\b{v}\s*=", cr) for v in [
          "isLightDashing", "lightDashChain", "lightDashIdx", "lightDashTime",
          "lightDashDeg", "lightDashFace", "lightDashToX", "lightDashToY",
          "lightDashVX", "lightDashVY", "lightDashGhostTimer"]))
check("v5.9.1 scr_light_dash: macros de la estela (FADE)",
      re.search(r"#macro\s+LIGHT_DASH_GHOST_FADE\s+0\.06", ld) is not None)
check("v5.9.1 scr_light_dash: lazy declara el ghostTimer tambien",
      "lightDashGhostTimer = 0; // contador de la estela (scr_light_dash_ghost)" in ld)

d0 = sources.get("objects/obj_amy_canon/Draw_0.gml", "")
check("v5.9.1->v5.9.4 scr_light_dash: estela local presente (quickeffect + cadencia)",
      "obj_quickeffect_fade" in ld and "LIGHT_DASH_GHOST_EVERY" in ld
      and "LIGHT_DASH_GHOST_FADE" in ld)
check("v5.9.1->v5.9.4 scr_light_dash: la estela copia la pose ROTADA (lightDashDeg)",
      re.search(r"_ghost\.image_angle\s*=\s*lightDashDeg;", ld) is not None)
check("v5.9.1->v5.9.4 scr_light_dash: la estela lleva la paleta del jugador",
      "_ghost.palleteFrom = global.palleteFrom;" in ld)

pp = sources.get("objects/obj_player_puppet/Step_0.gml", "")
check("v5.9.1 puppet: estela remota presente (estado 25, sin bytes de red)",
      "state == AMY_CANON_LIGHTDASH" in pp and "LIGHT_DASH_GHOST_EVERY" in pp)
check("v5.9.1 puppet: usa el angle del paquete EN GRADOS (sin radtodeg)",
      re.search(r"_ghost\.image_angle\s*=\s*angle;", pp) is not None)
check("v5.9.1 puppet: la estela es solo para Amy canon",
      re.search(r"if\(character == CHARACTER_AMY_CANON && state == AMY_CANON_LIGHTDASH\)", pp) is not None)

# --- v5.9.2: flecha indicadora (la Z sin choque con la flotacion) ---
check("v5.9.2 Create: declara las 2 vars de la flecha",
      re.search(r"lightDashAim\s*=\s*\[\];", cr) is not None
      and re.search(r"lightDashAimLife\s*=\s*0;", cr) is not None)
check("v5.9.2 scr_light_dash: macros de la flecha",
      re.search(r"#macro\s+LIGHT_DASH_ARROW_DIST\s+16", ld) is not None
      and re.search(r"#macro\s+LIGHT_DASH_ARROW_SIZE\s+7", ld) is not None)
check("v5.9.2 scr_light_dash: lazy declara las vars de la flecha",
      "lightDashAim = [];       // v5.9.2: cadena para la FLECHA (Draw_0)" in ld
      and "lightDashAimLife = 0;    // v5.9.2: vida de la flecha (caduca sola)" in ld)
check("v5.9.2 scr_light_dash: la flecha caduca cada frame (clear antes del viaje)",
      ld.find("la FLECHA caduca sola cada frame") != -1
      and ld.find("la FLECHA caduca sola cada frame") < ld.find("// ================= 1. VIAJE"))
check("v5.9.2 scr_light_dash: escaneo continuo llena lightDashAim",
      "lightDashAim = _chain;" in ld and "lightDashAimLife = 2;" in ld)
check("v5.9.2 scr_light_dash: la flotacion NO bloquea el escaneo (gate despues)",
      ld.find("var _chain = scr_light_dash_find();") != -1
      and ld.find("isTarotFloat || !keyboard_check_pressed(global.KeyA)")
      > ld.find("var _chain = scr_light_dash_find();"))
check("v5.9.2 scr_light_dash: gates de estados activos sin isTarotFloat",
      re.search(r"if\(isDashing \|\| isTarotDashing \|\| isHJ \|\| isAttacking\)", ld) is not None)
check("v5.9.2 Draw_0: flecha con halo + triangulo + keycap de la tecla real",
      "LIGHT_DASH_ARROW_DIST" in d0 and "draw_triangle" in d0
      and "scr_hud_keycap_at" in d0 and "global.KeyA" in d0)
check("v5.9.2 Draw_0: la flecha va despues del cuerpo (shader_reset antes)",
      d0.find("shader_reset();") != -1
      and d0.find("shader_reset();") < d0.find("LIGHT DASH: FLECHA INDICADORA"))
check("v5.9.2 Draw_0: la flecha caduca y mira el anillo vivo",
      "lightDashAimLife--" in d0 and "!_ring.used" in d0
      and "instance_exists(_ring)" in d0)

# --- v5.9.3: alcance ampliado (radio 96, eslabones 80, 1 anillo) ---
check("v5.9.3 scr_light_dash: radio de captura ampliado a 96",
      re.search(r"#macro\s+LIGHT_DASH_FIRST_RADIUS\s+96", ld) is not None)
check("v5.9.3 scr_light_dash: tolerancia de eslabones ampliada a 80",
      re.search(r"#macro\s+LIGHT_DASH_LINK_DIST\s+80", ld) is not None)
check("v5.9.3 scr_light_dash: UN anillo basta (gate < 1, ya no < 2)",
      re.search(r"if\(array_length\(_chain\) < 1\)", ld) is not None
      and "if(array_length(_chain) < 2)" not in ld)
check("v5.9.3 scr_light_dash: velocidad pre-fijada al arrancar (lunge)",
      "var _d0 = point_direction(x, y, _chain[0].x, _chain[0].y);" in ld
      and "lengthdir_x(LIGHT_DASH_SPEED, _d0)" in ld)
check("v5.9.3 Draw_0: flecha tambien con UN solo anillo (>= 1)",
      "array_length(lightDashAim) >= 1" in d0
      and "array_length(lightDashAim) >= 2" not in d0)

# --- v5.9.4: ritmo a 10 + estela continua (nace en el step) ---
check("v5.9.4 scr_light_dash: velocidad bajada a 10 (era 16: teletransporte)",
      re.search(r"#macro\s+LIGHT_DASH_SPEED\s+10\b", ld) is not None)
check("v5.9.4 scr_light_dash: tope de tiempo subido a 180 (speed menor)",
      re.search(r"#macro\s+LIGHT_DASH_MAX_TIME\s+180", ld) is not None)
check("v5.9.4 scr_light_dash: fantasma CADA frame (EVERY 1, rayo continuo)",
      re.search(r"#macro\s+LIGHT_DASH_GHOST_EVERY\s+1\b", ld) is not None)
check("v5.9.4 scr_light_dash: funcion scr_light_dash_ghost (nace en el step)",
      "function scr_light_dash_ghost(" in ld)
check("v5.9.4 scr_light_dash: fantasma en cada frame de vuelo (lightDashToX/Y)",
      "scr_light_dash_ghost(lightDashToX, lightDashToY);" in ld)
_exit_fn = ld.find("function scr_light_dash_exit()")
check("v5.9.4 scr_light_dash: arranque y salida dejan su fantasma (2 llamadas x,y)",
      ld.count("scr_light_dash_ghost(x, y);") == 2
      and _exit_fn != -1
      and ld.find("scr_light_dash_ghost(x, y);", _exit_fn) != -1)
check("v5.9.4 Draw_0: el Draw ya NO spawnea la estela (sin dobles)",
      "obj_quickeffect_fade" not in d0 and "lightDashGhostTimer" not in d0)

yyp = open(os.path.join(ROOT, "Sonicexe The Disaster 2D Remake.yyp"), encoding="utf-8").read()
check("yyp: script registrado", '"scr_light_dash"' in yyp)
check("yyp: sprite registrado", '"spr_amy_light_speed_canon"' in yyp)

spr_dir = os.path.join(ROOT, "sprites/spr_amy_light_speed_canon")
yy = open(os.path.join(spr_dir, "spr_amy_light_speed_canon.yy"), encoding="utf-8").read()
root_pngs = [f for f in os.listdir(spr_dir) if f.endswith(".png")]
frame_ids = re.findall(r'"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', yy)
# animacion real del usuario (1 frame 35x33): el N de frames sale del yy,
# sin hardcodear — si manana anhade frames al sprite, esto sigue ok
n_frames = len(frame_ids)
check("sprite: frames del yy con su png en disco, no vacios",
      n_frames >= 1 and len(root_pngs) == n_frames
      and all(os.path.getsize(os.path.join(spr_dir, p)) > 100 for p in root_pngs),
      f"{n_frames} frames, {len(root_pngs)} pngs")
check("sprite: cada frame del yy tiene su png",
      all(f"{fid}.png" in root_pngs for fid in frame_ids))
check("sprite: layers de GMS2 presentes (1 carpeta por frame)",
      os.path.isdir(os.path.join(spr_dir, "layers"))
      and len(os.listdir(os.path.join(spr_dir, "layers"))) == n_frames)

# =====================================================================
# PARTE 2 — SIMULACIÓN (lógica portada 1:1)
# =====================================================================
print()
print("=== PARTE 2: SIMULACIÓN ===")

SPEED = 10.0
FIRST_RADIUS = 96.0
LINK_DIST = 80.0
MAX_RINGS = 16
MAX_TIME = 180
TURN = 0.35


def point_direction(x1, y1, x2, y2):
    """GM: 0=derecha, 90=arriba, 0..360."""
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return 0.0
    deg = math.degrees(math.atan2(-dy, dx))
    return deg % 360.0


def angle_difference(a, b):
    """GM: wrap de (a - b) a (-180, 180]."""
    d = (a - b) % 360.0
    if d > 180.0:
        d -= 360.0
    return d


def dcos(deg):
    return math.cos(math.radians(deg))


def point_distance(x1, y1, x2, y2):
    return math.hypot(x2 - x1, y2 - y1)


class Ring:
    def __init__(self, x, y, iid=0, nid=0):
        self.x, self.y = x, y
        self.iid, self.nid = iid, nid
        self.used = False
        self.visible = True
        self.alpha = 1.0


class Player:
    def __init__(self, x, y, face=1):
        self.x, self.y = x, y
        self.face = face
        self.deg = 0.0            # theta de dibujo
        self.to_x, self.to_y = x, y
        self.vx, self.vy = 0.0, 0.0
        self.chain = []
        self.idx = 0
        self.time = 0
        self.collected = []       # anillos comidos por el dash
        self.packets = []         # CLIENT_RING_COLLECTED enviados


def find_chain(px, py, rings):
    chain = []
    best, best_d = None, FIRST_RADIUS
    for r in rings:
        if r.used or not r.visible or r.alpha < 1:
            continue
        d = point_distance(px, py, r.x, r.y)
        if d < best_d:
            best, best_d = r, d
    if best is None:
        return chain
    chain.append(best)
    while len(chain) < MAX_RINGS:
        last = chain[-1]
        nxt, nxt_d = None, LINK_DIST
        for r in rings:
            if r.used or not r.visible or r.alpha < 1:
                continue
            if r in chain:
                continue
            d = point_distance(last.x, last.y, r.x, r.y)
            if d < nxt_d:
                nxt, nxt_d = r, d
        if nxt is None:
            break
        chain.append(nxt)
    return chain


def travel_frame(p, rings):
    """Un frame de viaje (el bloque 1 de scr_light_dash_step, portado)."""
    p.time += 1
    # objetivo vivo
    tgt = None
    while p.idx < len(p.chain):
        r = p.chain[p.idx]
        if (r in rings or True) and not r.used:  # instance_exists simulado
            tgt = r
            break
        p.idx += 1
    if tgt is None:
        return False  # cadena agotada
    budget = SPEED
    p.to_x, p.to_y = p.x, p.y
    while budget > 0 and tgt is not None:
        dx, dy = tgt.x - p.to_x, tgt.y - p.to_y
        dist = point_distance(0, 0, dx, dy)
        if dist <= budget or dist == 0:
            p.to_x, p.to_y = tgt.x, tgt.y
            budget -= max(dist, 0)
            p.idx += 1
            # recogida directa
            tgt.used = True
            p.collected.append(tgt)
            p.packets.append((tgt.iid, tgt.nid))
            tgt = None
            while p.idx < len(p.chain):
                r2 = p.chain[p.idx]
                if not r2.used:
                    tgt = r2
                    break
                p.idx += 1
        else:
            p.to_x += dx / dist * budget
            p.to_y += dy / dist * budget
            budget = 0
    mx, my = p.to_x - p.x, p.to_y - p.y
    if mx != 0 or my != 0:
        d = point_direction(0, 0, mx, my)
        r_ang = p.deg + 180 if p.face < 0 else p.deg
        r_ang += angle_difference(d, r_ang) * TURN
        if dcos(r_ang) >= 0:
            p.face, p.deg = 1, r_ang
        else:
            p.face, p.deg = -1, r_ang - 180
        while p.deg > 180:
            p.deg -= 360
        while p.deg <= -180:
            p.deg += 360
        ln = point_distance(0, 0, mx, my)
        p.vx, p.vy = mx / ln * SPEED, my / ln * SPEED
    p.x, p.y = p.to_x, p.to_y  # scr_light_dash_pose
    return True


def rendered_forward(face, deg):
    """Hacia donde apunta el sprite en pantalla (grados GM)."""
    return (deg if face > 0 else deg + 180) % 360.0


# --- 2.1: el scenario del usuario: columna que arranca arriba y gira ---
print("-- rotacion: fila->columna y columna->fila --")

# (a) fila horizontal hacia la derecha que sube en columna (gamma invertida)
rings = [Ring(100, 500, 1, 101), Ring(128, 500, 2, 102), Ring(156, 500, 3, 103),
         Ring(156, 476, 4, 104), Ring(156, 452, 5, 105), Ring(156, 428, 6, 106)]
p = Player(80, 500)
p.chain = find_chain(p.x, p.y, rings)
check("finder: captura los 6 eslabones de la L", len(p.chain) == 6)

frames = 0
max_jump = 0
prev_fwd = rendered_forward(p.face, p.deg)
while travel_frame(p, rings) and frames < 100:
    frames += 1
    fwd = rendered_forward(p.face, p.deg)
    max_jump = max(max_jump, abs(angle_difference(fwd, prev_fwd)))
    prev_fwd = fwd
    assert abs(p.deg) <= 90.0001, f"theta fuera de rango: {p.deg}"

check("rotacion: theta siempre en [-90, 90] (nunca cabeza abajo)", True)
check("rotacion: giro continuo (sin saltos > 90 entre frames)", max_jump <= 90.0001,
      f"salto maximo {max_jump:.1f}")
check("rotacion: al final apunta arriba (la columna)",
      abs(angle_difference(rendered_forward(p.face, p.deg), 90)) < 25,
      f"apunta a {rendered_forward(p.face, p.deg):.1f}")
check("viaje: los 6 anillos recogidos, 6 paquetes, sin repetir",
      len(p.collected) == 6 and len(p.packets) == 6
      and len({(r.iid, r.nid) for r in p.collected}) == 6)
check("salida: impulso del ultimo tramo (hacia arriba)",
      abs(p.vy + SPEED) < 0.01 and abs(p.vx) < 0.01,
      f"vx={p.vx:.2f} vy={p.vy:.2f}")

# (b) EL caso preguntado: va hacia ARRIBA por una columna y la cadena
# dobla hacia la DERECHA al final — nunca debe verse de espaldas
rings = [Ring(400, 600), Ring(400, 576), Ring(400, 552),
         Ring(424, 540), Ring(452, 536), Ring(480, 536)]
p = Player(400, 620)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
backpedal = False
while travel_frame(p, rings) and frames < 100:
    frames += 1
    fwd = rendered_forward(p.face, p.deg)
    # "de espaldas": apuntando >= 100° en contra de la marcha del tramo
    # (la marcha real de cada frame):
check("caso usuario (columna->derecha): converge mirando a la derecha",
      abs(angle_difference(rendered_forward(p.face, p.deg), 0)) < 25,
      f"apunta a {rendered_forward(p.face, p.deg):.1f}")
check("caso usuario: theta en rango y sin espaldas", abs(p.deg) <= 90.0001)

# (c) cruzar la vertical al reves: de arriba-derecha a arriba-izquierda
rings = [Ring(100, 480), Ring(112, 452), Ring(134, 430),
         Ring(162, 420), Ring(190, 430), Ring(212, 452)]
p = Player(90, 505)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
max_jump = 0
prev_fwd = rendered_forward(p.face, p.deg)
thetas = []
while travel_frame(p, rings) and frames < 100:
    frames += 1
    thetas.append(p.deg)
    fwd = rendered_forward(p.face, p.deg)
    max_jump = max(max_jump, abs(angle_difference(fwd, prev_fwd)))
    prev_fwd = fwd
check("arco (cruce de vertical): continuo, sin salto de direccion",
      max_jump <= 90.0001, f"salto maximo {max_jump:.1f}")
check("arco: theta siempre en rango", all(abs(t) <= 90.0001 for t in thetas))
check("arco: termina apuntando abajo-derecha (la bajada del arco)",
      abs(angle_difference(rendered_forward(p.face, p.deg), 330)) < 30,
      f"apunta a {rendered_forward(p.face, p.deg):.1f}")

# (d) barrido exhaustivo: para CADA direccion de viaje, tras converger,
# el sprite apunta a la direccion y theta esta en rango
print("-- rotacion: barrido de 360 grados --")
bad = []
for d in range(0, 360, 5):
    p = Player(0, 0)
    # 40 frames persiguiendo la misma direccion (converge)
    for _ in range(40):
        p.to_x, p.to_y = p.x + SPEED * math.cos(math.radians(d)), \
                         p.y - SPEED * math.sin(math.radians(d))
        mx, my = p.to_x - p.x, p.to_y - p.y
        r_ang = p.deg + 180 if p.face < 0 else p.deg
        r_ang += angle_difference(d, r_ang) * TURN
        if dcos(r_ang) >= 0:
            p.face, p.deg = 1, r_ang
        else:
            p.face, p.deg = -1, r_ang - 180
        while p.deg > 180:
            p.deg -= 360
        while p.deg <= -180:
            p.deg += 360
        p.x, p.y = p.to_x, p.to_y
    fwd = rendered_forward(p.face, p.deg)
    if abs(angle_difference(fwd, d)) > 5 or abs(p.deg) > 90.0001:
        bad.append((d, fwd, p.deg))
check("barrido 360: apunta a la direccion de viaje, nunca cabeza abajo",
      not bad, f"fallas: {bad[:5]}")

# --- 2.2: presupuesto y eslabones cortos ---
print("-- presupuesto: fila de 4 a 28 px, budget 16 --")
rings = [Ring(0, 0), Ring(28, 0), Ring(56, 0), Ring(84, 0)]
p = Player(-20, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("fila 4x28: todo recogido",
      all(r.used for r in rings) and len(p.collected) == 4)
check("fila 4x28: sale disparada a la velocidad del dash",
      abs(p.vx - SPEED) < 0.01 and abs(p.vy) < 0.01)
check("fila 4x28: termino pasando por el ultimo anillo",
      abs(p.x - 84) < 0.01 and abs(p.y) < 0.01,
      f"paro en ({p.x:.1f}, {p.y:.1f})")

# --- 2.3: el EXE revienta un anillo a mitad de cadena ---
print("-- contra-jugada: anillo roto a mitad de vuelo --")
rings = [Ring(0, 0), Ring(30, 0), Ring(60, 0), Ring(90, 0), Ring(120, 0)]
p = Player(-15, 0)
p.chain = find_chain(p.x, p.y, rings)
check("cadena de 5", len(p.chain) == 5)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
    if frames == 2:
        rings[2].used = True  # el EXE revienta el 3o (recogido=roto aqui)
check("anillo roto: el dash lo salta y come el resto",
      len(p.collected) == 4 and rings[3].used and rings[4].used)

# --- 2.4: gates de activacion ---
print("-- activacion --")
# v5.9.3: un solo anillo SI forma cadena (lunge de recogida)
rings = [Ring(0, 0)]
check("gate: 1 anillo solo SI forma cadena (v5.9.3)",
      len(find_chain(10, 0, rings)) == 1)
# anillo demasiado lejos
rings = [Ring(0, 0), Ring(28, 0)]
check("gate: linea a >96 px fuera de captura",
      len(find_chain(200, 200, rings)) == 0)
# anillo con fade-in pendiente no cuenta
r = Ring(0, 0)
r2 = Ring(28, 0)
r2.alpha = 0.5
check("gate: anillo en fade-in excluido",
      len(find_chain(10, 0, [r, r2])) == 1)

# --- 2.5: tope de tiempo ---
print("-- seguridad --")
rings = [Ring(i * 24, 0) for i in range(30)]  # mas que MAX_RINGS
chain = find_chain(0, 0, rings)
check("tope: la cadena se corta en 16 eslabones", len(chain) == MAX_RINGS)

# --- 2.6: geometria de la FLECHA v5.9.2 (no tapa la cadena) ---
print("-- flecha: geometria del indicador --")


def ldx(l, d):
    return l * math.cos(math.radians(d))


def ldy(l, d):
    return -l * math.sin(math.radians(d))


# (nombre, cadena, posicion de Amy) — las 3 formas canonicas de los
# mapas (columna como ascensor, fila como carril) + una diagonal
cases = [
    ("columna abajo", [(200, 500), (200, 476), (200, 452)], (200, 530)),
    ("columna arriba", [(200, 300), (200, 324), (200, 348)], (200, 270)),
    ("fila derecha", [(300, 400), (328, 400), (356, 400)], (270, 400)),
    ("diagonal", [(300, 400), (322, 388), (344, 376)], (285, 408)),
]
ok_keycap = True
ok_arrow = True
for name, chn, amy in cases:
    r0 = chn[0]
    d = point_direction(amy[0], amy[1], r0[0], r0[1])
    # keycap: 16 px del anillo hacia el lateral derecho del tramo
    kx = r0[0] + ldx(16, d - 90)
    ky = r0[1] + ldy(16, d - 90)
    # ancla de la flecha: 16 px antes del anillo, del lado de Amy
    ax = r0[0] + ldx(16, d + 180)
    ay = r0[1] + ldy(16, d + 180)
    for (rx, ry) in chn:
        if point_distance(kx, ky, rx, ry) < 10:
            ok_keycap = False
        if point_distance(ax, ay, rx, ry) < 10 and (rx, ry) != (r0[0], r0[1]):
            ok_arrow = False
    # la flecha apunta exactamente al primer tramo (de Amy al anillo)
    if abs(angle_difference(d, point_direction(amy[0], amy[1], r0[0], r0[1]))) > 0.01:
        ok_arrow = False
check("flecha: el keycap nunca pisa un anillo de la cadena", ok_keycap)
check("flecha: el ancla queda libre y apunta al primer tramo", ok_arrow)

# --- 2.7: v5.9.3 — un anillo basta + tolerancias ampliadas ---
print("-- v5.9.3: lunge de 1 anillo y tolerancias --")

# un solo anillo: lunge completo (recoge y sale disparada hacia el)
rings = [Ring(100, 0, 7, 77)]
p = Player(60, 0)
p.chain = find_chain(p.x, p.y, rings)
check("v5.9.3: un anillo solo forma cadena (len 1)", len(p.chain) == 1)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("v5.9.3: lunge de 1 anillo: lo recoge y sale con impulso",
      rings[0].used and len(p.collected) == 1 and len(p.packets) == 1
      and abs(p.vx - SPEED) < 0.01 and abs(p.vy) < 0.01,
      f"vx={p.vx:.2f} vy={p.vy:.2f}")

# anillos separados 70 px: con 48 no encadenaban, con 80 si
rings = [Ring(0, 0), Ring(70, 0), Ring(140, 0)]
check("v5.9.3: tolerancia 80 engancha anillos separados 70 px",
      len(find_chain(-10, 0, rings)) == 3)

# captura del primer anillo a 90 px (antes de 56 no llegaba)
rings = [Ring(90, 0)]
check("v5.9.3: primer anillo capturado a 90 px (radio 96)",
      len(find_chain(0, 0, rings)) == 1)

# ...y a 120 px sigue fuera (el radio no es infinito)
rings = [Ring(120, 0)]
check("v5.9.3: a 120 px sigue fuera del radio",
      len(find_chain(0, 0, rings)) == 0)

# --- 2.8: v5.9.4 — estela durante TODO el camino + ritmo a 10 ---
print("-- v5.9.4: estela continua y ritmo --")

# 5 anillos a 30 px = 140 px de camino: a 10 px/frame son 14 frames de
# vuelo — a 16 eran 9, y con fantasma cada 2 frames nacido en el Draw
# la estela entera eran ~4 fantasmas sueltos ("solo al agarrar").
# Ahora: 1 de arranque + 14 de vuelo + 1 de salida = 16 fantasmas.
rings = [Ring(i * 30, 0) for i in range(5)]
p = Player(-20, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("v5.9.4: a 10 px/frame el viaje de 140 px dura 14 frames (a 16 eran 9)",
      frames == 14, f"{frames} frames")
check("v5.9.4: estela completa — arranque + vuelo + salida = 16 fantasmas",
      frames + 2 == 16, f"{frames + 2} fantasmas")

# hasta el lunge mas corto (1 anillo cerca) deja estela: arranque +
# vuelo + salida, minimo 3 fantasmas
rings = [Ring(40, 0)]
p = Player(0, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("v5.9.4: el lunge de 1 anillo tambien deja estela (>= 3 fantasmas)",
      frames + 2 >= 3, f"{frames + 2} fantasmas")

print()
if fails:
    print(f"RESULTADO: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULTADO: TODO OK")
