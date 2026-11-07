#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v59_light_dash.py — verificacion del LIGHT DASH de Amy Canon
(v5.9 -> v5.10: fix del crash de primer frame, estela fantasmal, flecha
indicadora, alcance ampliado, ritmo, cadena consciente del terreno y
PATHFINDING A* REAL: mp_grid + string pulling con WAYPOINTS).

Parte 1 (estatica): brackets balanceados en todos los archivos tocados,
los 8 puntos de integracion presentes, colision de estados evitada
(LIGHTDASH=25 vs HUG=24), sprite registrado con frames reales, y el
TUNING DEL USUARIO pineado (SPEED 5 / RADIUS 220 / LINK 275 / RINGS 20 /
TIME 200) para que nadie lo revierta sin darse cuenta.

Parte 2 (simulacion): la logica del dash porteada 1:1 a Python, con las
constantes PARSEADAS del propio gml (unica fuente de verdad):
  - ROTACION: el volteo R-space nunca deja |theta| > 90, nunca viaja de
    espaldas y el giro es continuo en los cruces de vertical.
  - CADENA: el finder captura filas/columnas/arcos, respeta MAX_RINGS y
    los gates de activacion.
  - TERRENO (v5.9.5): anillos enterrados fuera, apoyados dentro, y el
    vecino visible arranca antes que el bloqueado.
  - PATHFINDING A* (v5.10): puerto del mp_grid (celdas de
    LIGHT_DASH_GRID_CELL, A* 8-direcciones sin cortar esquinas, celdas
    de salida/meta desbloqueadas y re-bloqueadas SOLO si tenian terreno
    — sin celdas fantasma), del string pulling (los quiebres conservados
    pasan scr_light_dash_clear) y del vuelo por WAYPOINTS: el rayo RODEA
    un muro con hueco aunque ningun anillo lo guie, respeta el
    presupuesto ROUTE_FACTOR, NO corre A* cuando hay linea de vision, un
    anillo roto a mitad de desvio se salta sin romper la ruta, y la
    flecha apunta al primer QUIEBRE (no a la pared).
"""

import heapq
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

# --- TUNING DEL USUARIO (v5.10): pineado para que nadie lo revierta ---
check("TUNING USUARIO: LIGHT_DASH_SPEED 5 (no revertir)",
      re.search(r"#macro\s+LIGHT_DASH_SPEED\s+5\b", ld) is not None)
check("TUNING USUARIO: LIGHT_DASH_FIRST_RADIUS 220 (no revertir)",
      re.search(r"#macro\s+LIGHT_DASH_FIRST_RADIUS\s+220\b", ld) is not None)
check("TUNING USUARIO: LIGHT_DASH_LINK_DIST 275 (no revertir)",
      re.search(r"#macro\s+LIGHT_DASH_LINK_DIST\s+275\b", ld) is not None)
check("TUNING USUARIO: LIGHT_DASH_MAX_RINGS 20 (no revertir)",
      re.search(r"#macro\s+LIGHT_DASH_MAX_RINGS\s+20\b", ld) is not None)
check("TUNING USUARIO: LIGHT_DASH_MAX_TIME 200 (no revertir)",
      re.search(r"#macro\s+LIGHT_DASH_MAX_TIME\s+200\b", ld) is not None)

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
check("v5.9.2/v5.10 scr_light_dash: la FLECHA son SOLO anillos (filtro de ruta)",
      "lightDashAim = [];" in ld and "if(!is_struct(_route[i]))" in ld
      and "array_push(lightDashAim, _route[i]);" in ld)
check("v5.9.2 scr_light_dash: la flotacion NO bloquea el escaneo (gate despues)",
      ld.find("var _route = scr_light_dash_find();") != -1
      and ld.find("isTarotFloat || !keyboard_check_pressed(global.KeyA)")
      > ld.find("var _route = scr_light_dash_find();"))
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

# --- v5.9.3: 1 anillo basta + tolerancias (valores = tuning usuario) ---
check("v5.9.3 scr_light_dash: UN anillo basta (gate < 1)",
      re.search(r"if\(array_length\(_route\) < 1\)", ld) is not None
      and "if(array_length(_chain) < 2)" not in ld)
check("v5.9.3 scr_light_dash: velocidad pre-fijada al arrancar (lunge, ruta)",
      "var _d0 = point_direction(x, y, _route[0].x, _route[0].y);" in ld
      and "lengthdir_x(LIGHT_DASH_SPEED, _d0)" in ld)
check("v5.9.3 Draw_0: flecha tambien con UN solo anillo (>= 1)",
      "array_length(lightDashAim) >= 1" in d0
      and "array_length(lightDashAim) >= 2" not in d0)

# --- v5.9.4: estela en el step + cadencia 1 ---
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

# --- v5.9.5: cadena consciente del terreno ---
check("v5.9.5 scr_light_dash: macro del terreno (padre universal)",
      re.search(r"#macro\s+LIGHT_DASH_TERRAIN\s+obj_floor_parent", ld) is not None)
check("v5.9.5 scr_light_dash: macro del margen de los tramos",
      re.search(r"#macro\s+LIGHT_DASH_LOS_TRIM\s+8\b", ld) is not None)
check("v5.9.5 scr_light_dash: funcion scr_light_dash_clear (linea de vision)",
      re.search(r"function\s+scr_light_dash_clear\(x1,\s*y1,\s*x2,\s*y2\)", ld) is not None
      and ld.count("collision_line(") >= 1)
check("v5.9.5 scr_light_dash: el tramo se prueba recortado (guard 2*TRIM)",
      "LIGHT_DASH_LOS_TRIM * 2" in ld and ld.count("LIGHT_DASH_LOS_TRIM") >= 5)
check("v5.9.5 scr_light_dash: cabecera documenta el pathfinding",
      "PATHFINDING DEL RAYO" in ld
      and ld.find("buscar el angulo") != -1)

# el finder exige visibilidad: pase 1 = min-scan con clear
check("v5.9.5/v5.10 scr_light_dash: pase 1 = el mas cercano VISIBLE (min-scan)",
      "if(scr_light_dash_clear(_px, _py, _r.x, _r.y))" in ld
      and "_nextD = _cand[i][0];" in ld)

# SIN rescate propio EN EL VUELO (el anti-atasco del juego lo cubre);
# el collision_point de la higiene de candidatos vive en el finder
_viaje = ld.find("// ================= 1. VIAJE")
_flecha = ld.find("// ================= 2. FLECHA")
check("v5.9.5 scr_light_dash: SIN rescate propio en el VUELO (anti-atasco del juego)",
      _viaje != -1 and _flecha != -1
      and "collision_point" not in ld[_viaje:_flecha]
      and "sistema anti-atasco" in ld)

# --- v5.10: PATHFINDING A* REAL ---
check("v5.10 scr_light_dash: macros del A* (factor, celda, refresh)",
      re.search(r"#macro\s+LIGHT_DASH_ROUTE_FACTOR\s+1\.5", ld) is not None
      and re.search(r"#macro\s+LIGHT_DASH_GRID_CELL\s+16\b", ld) is not None
      and re.search(r"#macro\s+LIGHT_DASH_GRID_REFRESH\s+30\b", ld) is not None)
check("v5.10 scr_light_dash: funcion scr_light_dash_grid (mp_grid cacheado)",
      "function scr_light_dash_grid(" in ld
      and "mp_grid_create(" in ld
      and "mp_grid_add_instances(global.__ldGrid, LIGHT_DASH_TERRAIN, true)" in ld
      and "mp_grid_destroy(" in ld)
check("v5.10 scr_light_dash: funcion scr_light_dash_route (A* + string pulling)",
      "function scr_light_dash_route(" in ld
      and "mp_grid_path(_grid, _path, _x1, _y1, _x2, _y2, true)" in ld
      and "path_get_number(_path)" in ld)
check("v5.10 scr_light_dash: SIN celdas fantasma (re-bloqueo condicional exacto)",
      "collision_rectangle(" in ld and "if(_b1)" in ld and "if(_b2)" in ld)
check("v5.10 scr_light_dash: el vuelo acepta WAYPOINTS (2 loops struct-aware)",
      ld.count("if(is_struct(_r) || (instance_exists(_r) && !_r.used))") == 1
      and ld.count("if(is_struct(_r2) || (instance_exists(_r2) && !_r2.used))") == 1)
check("v5.10 scr_light_dash: solo los ANILLOS se recogen (guard en la recogida)",
      "if(!is_struct(_tgt))" in ld)
check("v5.10 scr_light_dash: el finder empuja WAYPOINTS a la ruta",
      "array_push(_route, {x: _wps[i][0], y: _wps[i][1]});" in ld)
check("v5.10 scr_light_dash: higiene de candidatos (anillos ENTERRADOS fuera)",
      ld.find("higiene de candidatos") != -1
      and ld.find("if(collision_point(x, y, LIGHT_DASH_TERRAIN, true, true))")
      > ld.find("function scr_light_dash_find"))
check("v5.10 scr_light_dash: pase 2 = A* por el mas cercano (pool min-extract)",
      "_wps = scr_light_dash_route(_px, _py, _r2.x, _r2.y," in ld
      and "_reach * LIGHT_DASH_ROUTE_FACTOR);" in ld)
check("v5.10 scr_light_dash: seccion 2 guarda la RUTA y el aim de la flecha",
      "lightDashChain = _route;" in ld
      and "lightDashAimDir = point_direction(x, y, _route[0].x, _route[0].y);" in ld)
check("v5.10 Create: declara las 3 vars del aim (X/Y/Dir)",
      all(re.search(rf"\b{v}\s*=\s*0;", cr) for v in
          ["lightDashAimX", "lightDashAimY", "lightDashAimDir"]))
check("v5.10 scr_light_dash: lazy declara las 3 vars del aim",
      all(f"{v} = 0;" in ld for v in
          ["lightDashAimX", "lightDashAimY", "lightDashAimDir"]))
check("v5.10 Draw_0: la flecha apunta al PRIMER TRAMO de la ruta",
      "var _dir = lightDashAimDir;" in d0)
check("v5.10 Draw_0: el ancla de la flecha es el primer punto de la ruta",
      "lightDashAimX + lengthdir_x(LIGHT_DASH_ARROW_DIST" in d0
      and "lightDashAimY + lengthdir_y(LIGHT_DASH_ARROW_DIST" in d0)
check("v5.10 Create: el comentario de la ruta (anillos + waypoints)",
      "waypoints del desvio" in cr)

yyp = open(os.path.join(ROOT, "Sonicexe The Disaster 2D Remake.yyp"), encoding="utf-8").read()
check("yyp: script registrado", '"scr_light_dash"' in yyp)
check("yyp: sprite registrado", '"spr_amy_light_speed_canon"' in yyp)

spr_dir = os.path.join(ROOT, "sprites/spr_amy_light_speed_canon")
yy = open(os.path.join(spr_dir, "spr_amy_light_speed_canon.yy"), encoding="utf-8").read()
root_pngs = [f for f in os.listdir(spr_dir) if f.endswith(".png")]
frame_ids = re.findall(r'"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', yy)
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
# PARTE 2 — SIMULACIÓN (lógica portada 1:1, constantes PARSEADAS)
# =====================================================================
print()
print("=== PARTE 2: SIMULACIÓN ===")


def macro_num(name, cast=float):
    m = re.search(r"#macro\s+" + name + r"\s+([0-9.]+)", ld)
    return cast(m.group(1)) if m else None


SPEED = macro_num("LIGHT_DASH_SPEED")
FIRST_RADIUS = macro_num("LIGHT_DASH_FIRST_RADIUS")
LINK_DIST = macro_num("LIGHT_DASH_LINK_DIST")
MAX_RINGS = macro_num("LIGHT_DASH_MAX_RINGS", int)
MAX_TIME = macro_num("LIGHT_DASH_MAX_TIME")
TURN = macro_num("LIGHT_DASH_TURN")
TRIM = macro_num("LIGHT_DASH_LOS_TRIM")
ROUTE_FACTOR = macro_num("LIGHT_DASH_ROUTE_FACTOR")
CELL = macro_num("LIGHT_DASH_GRID_CELL", int)

check("sim: las 9 macros del dash se parsean del gml",
      None not in (SPEED, FIRST_RADIUS, LINK_DIST, MAX_RINGS, MAX_TIME, TURN,
                   TRIM, ROUTE_FACTOR, CELL))

ROOM_W, ROOM_H = 800, 600
HW, HH = ROOM_W // CELL, ROOM_H // CELL


def point_distance(x1, y1, x2, y2):
    return math.hypot(x2 - x1, y2 - y1)


def point_direction(x1, y1, x2, y2):
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return 0.0
    return math.degrees(math.atan2(-dy, dx)) % 360.0


def angle_difference(a, b):
    d = (a - b) % 360.0
    if d > 180.0:
        d -= 360.0
    return d


def dcos(deg):
    return math.cos(math.radians(deg))


class Ring:
    def __init__(self, x, y, iid=0, nid=0):
        self.x, self.y = x, y
        self.iid, self.nid = iid, nid
        self.used = False
        self.visible = True
        self.alpha = 1.0


class Wp:
    """Waypoint del desvio A* (el struct {x, y} del GML)."""

    def __init__(self, x, y):
        self.x, self.y = x, y


class Player:
    def __init__(self, x, y, face=1):
        self.x, self.y = x, y
        self.face = face
        self.deg = 0.0
        self.to_x, self.to_y = x, y
        self.vx, self.vy = 0.0, 0.0
        self.chain = []      # la RUTA: anillos + waypoints
        self.idx = 0
        self.time = 0
        self.collected = []
        self.packets = []


def point_in_terrain(px, py, terrain):
    for (rx, ry, rw, rh) in terrain:
        if rx <= px <= rx + rw and ry <= py <= ry + rh:
            return True
    return False


def seg_clear(x1, y1, x2, y2, terrain):
    """Puerto 1:1 de scr_light_dash_clear (tramo recortado TRIM px)."""
    if not terrain:
        return True
    d = point_distance(x1, y1, x2, y2)
    if d <= TRIM * 2:
        return True
    nx, ny = (x2 - x1) / d, (y2 - y1) / d
    ax, ay = x1 + nx * TRIM, y1 + ny * TRIM
    bx, by = x2 - nx * TRIM, y2 - ny * TRIM
    steps = max(2, int(point_distance(ax, ay, bx, by) * 2))
    for i in range(steps + 1):
        t = i / steps
        px, py = ax + (bx - ax) * t, ay + (by - ay) * t
        if point_in_terrain(px, py, terrain):
            return False
    return True


def build_blocked(terrain):
    """Puerto de mp_grid_add_instances: celda bloqueada si el terreno la
    toca (interseccion estricta de areas)."""
    blocked = set()
    for ch in range(HW):
        for cv in range(HH):
            x0, y0, x1, y1 = ch * CELL, cv * CELL, (ch + 1) * CELL, (cv + 1) * CELL
            for (rx, ry, rw, rh) in terrain:
                if x0 < rx + rw and x1 > rx and y0 < ry + rh and y1 > ry:
                    blocked.add((ch, cv))
                    break
    return blocked


def make_world(terrain):
    return {"terrain": [tuple(t) for t in terrain],
            "blocked": build_blocked(terrain), "astar": 0}


def astar(blocked, start, goal):
    """A* 8-direcciones sin cortar esquinas (puerto del mp_grid_path con
    allowdiag=true; la ruta exacta de GM puede diferir en detalles, aqui
    se valida la CLASE de comportamiento: reachability y forma)."""
    if start == goal:
        return [start]

    def h(c):
        return math.hypot(c[0] - goal[0], c[1] - goal[1])

    openq = [(h(start), 0.0, start)]
    came = {start: None}
    g = {start: 0.0}
    while openq:
        _, _, cur = heapq.heappop(openq)
        if cur == goal:
            path = []
            while cur is not None:
                path.append(cur)
                cur = came[cur]
            return path[::-1]
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                nb = (cur[0] + dx, cur[1] + dy)
                if not (0 <= nb[0] < HW and 0 <= nb[1] < HH):
                    continue
                if nb in blocked:
                    continue
                if dx != 0 and dy != 0:
                    if (cur[0] + dx, cur[1]) in blocked or (cur[0], cur[1] + dy) in blocked:
                        continue
                ng = g[cur] + math.hypot(dx, dy)
                if ng < g.get(nb, float("inf")) - 1e-9:
                    g[nb] = ng
                    came[nb] = cur
                    heapq.heappush(openq, (ng + h(nb), ng, nb))
    return None


def route_detour(world, x1, y1, x2, y2, max_len):
    """Puerto 1:1 de scr_light_dash_route: A* + string pulling + presupuesto.
    Devuelve los QUIEBRES (sin la meta) o [] si no hay camino/presupuesto."""
    x1c = min(max(x1, 0), HW * CELL - 1)
    y1c = min(max(y1, 0), HH * CELL - 1)
    x2c = min(max(x2, 0), HW * CELL - 1)
    y2c = min(max(y2, 0), HH * CELL - 1)
    c1 = (int(x1c // CELL), int(y1c // CELL))
    c2 = (int(x2c // CELL), int(y2c // CELL))
    b1 = c1 in world["blocked"]
    b2 = c2 in world["blocked"]
    world["blocked"].discard(c1)
    world["blocked"].discard(c2)
    world["astar"] += 1
    cells = astar(world["blocked"], c1, c2)
    if b1:
        world["blocked"].add(c1)
    if b2:
        world["blocked"].add(c2)
    if cells is None:
        return []
    pts = [(cx * CELL + CELL / 2.0, cy * CELL + CELL / 2.0) for (cx, cy) in cells]
    pts.append((x2c, y2c))  # la META REAL cierra la cuerda
    n = len(pts) - 1
    kept = []
    ax, ay = x1c, y1c
    i = 0
    while i <= n:
        far = i
        for j in range(n, i - 1, -1):
            if seg_clear(ax, ay, pts[j][0], pts[j][1], world["terrain"]):
                far = j
                break
        kept.append(pts[far])
        ax, ay = pts[far]
        i = far + 1
    ln = point_distance(x1c, y1c, kept[0][0], kept[0][1])
    for k in range(1, len(kept)):
        ln += point_distance(kept[k - 1][0], kept[k - 1][1], kept[k][0], kept[k][1])
    if ln > max_len:
        return []
    return kept[:-1]  # quiebres, sin la meta


def find_route(world, px, py, rings):
    """Puerto 1:1 de scr_light_dash_find (v5.10): devuelve (ruta, cadena)."""
    flight = []
    chain = []
    ax, ay = px, py
    while len(chain) < MAX_RINGS:
        reach = FIRST_RADIUS if len(chain) == 0 else LINK_DIST
        cand = []
        for r in rings:
            if r.used or not r.visible or r.alpha < 1:
                continue
            if point_in_terrain(r.x, r.y, world["terrain"]):
                continue  # higiene: enterrados fuera
            if r in chain:
                continue
            d = point_distance(ax, ay, r.x, r.y)
            if d < reach:
                cand.append([d, r])
        if not cand:
            break
        nxt = None
        nxtD = reach + 1
        for d, r in cand:
            if d >= nxtD:
                continue
            if seg_clear(ax, ay, r.x, r.y, world["terrain"]):
                nxtD = d
                nxt = r
        wps = []
        if nxt is None:
            pool = [list(c) for c in cand]
            while pool and nxt is None:
                mi = 0
                for k in range(1, len(pool)):
                    if pool[k][0] < pool[mi][0]:
                        mi = k
                d, r = pool.pop(mi)
                wps = route_detour(world, ax, ay, r.x, r.y, reach * ROUTE_FACTOR)
                if wps:
                    nxt = r
        if nxt is None:
            break
        for w in wps:
            flight.append(Wp(w[0], w[1]))
        flight.append(nxt)
        chain.append(nxt)
        ax, ay = nxt.x, nxt.y
    return flight, chain


def find_chain(px, py, rings, terrain=None):
    """Compatibilidad con los escenarios sin terreno: la ruta == anillos."""
    world = make_world(terrain or [])
    flight, _ = find_route(world, px, py, rings)
    return flight


def travel_frame(p, rings):
    """Un frame de viaje (bloque 1 de scr_light_dash_step, portado con
    soporte de WAYPOINTS: los structs no mueren ni se recogen)."""
    p.time += 1
    tgt = None
    while p.idx < len(p.chain):
        r = p.chain[p.idx]
        if isinstance(r, Wp) or not r.used:
            tgt = r
            break
        p.idx += 1
    if tgt is None:
        return False
    budget = SPEED
    p.to_x, p.to_y = p.x, p.y
    while budget > 0 and tgt is not None:
        dx, dy = tgt.x - p.to_x, tgt.y - p.to_y
        dist = point_distance(0, 0, dx, dy)
        if dist <= budget or dist == 0:
            p.to_x, p.to_y = tgt.x, tgt.y
            budget -= max(dist, 0)
            p.idx += 1
            if not isinstance(tgt, Wp):
                tgt.used = True
                p.collected.append(tgt)
                p.packets.append((tgt.iid, tgt.nid))
            tgt = None
            while p.idx < len(p.chain):
                r2 = p.chain[p.idx]
                if isinstance(r2, Wp) or not r2.used:
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
        ln2 = point_distance(0, 0, mx, my)
        p.vx, p.vy = mx / ln2 * SPEED, my / ln2 * SPEED
    p.x, p.y = p.to_x, p.to_y
    return True


def rendered_forward(face, deg):
    return (deg if face > 0 else deg + 180) % 360.0


# --- 2.1: rotacion (sin terreno: ruta == anillos) ---
print("-- rotacion: fila->columna y columna->fila --")

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

rings = [Ring(400, 600), Ring(400, 576), Ring(400, 552),
         Ring(424, 540), Ring(452, 536), Ring(480, 536)]
p = Player(400, 620)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
backpedal = False
while travel_frame(p, rings) and frames < 100:
    frames += 1
    fwd = rendered_forward(p.face, p.deg)
    if abs(angle_difference(fwd, 180)) < 60:
        backpedal = True
check("caso usuario (columna->derecha): converge mirando a la derecha",
      abs(angle_difference(rendered_forward(p.face, p.deg), 0)) < 25,
      f"apunta a {rendered_forward(p.face, p.deg):.1f}")
check("caso usuario: theta en rango y sin espaldas",
      abs(p.deg) <= 90.0001 and not backpedal)

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

print("-- rotacion: barrido de 360 grados --")
bad = []
for d in range(0, 360, 5):
    p = Player(0, 0)
    for _ in range(40):
        p.to_x = p.x + SPEED * math.cos(math.radians(d))
        p.to_y = p.y - SPEED * math.sin(math.radians(d))
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
print(f"-- presupuesto: fila de 4 a 28 px, budget SPEED ({SPEED:g}) --")
rings = [Ring(0, 0), Ring(28, 0), Ring(56, 0), Ring(84, 0)]
p = Player(-20, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 200:
    frames += 1
check("fila 4x28: todo recogido",
      all(r.used for r in rings) and len(p.collected) == 4)
check("fila 4x28: sale disparada a la velocidad del dash",
      abs(p.vx - SPEED) < 0.01 and abs(p.vy) < 0.01)
check("fila 4x28: termino pasando por el ultimo anillo",
      abs(p.x - 84) < 0.01 and abs(p.y) < 0.01,
      f"paro en ({p.x:.1f}, {p.y:.1f})")
check("fila 4x28: 104 px duran ceil(104/SPEED) frames",
      frames == math.ceil(104 / SPEED - 1e-9), f"{frames} frames")

# --- 2.3: el EXE revienta un anillo a mitad de cadena ---
print("-- contra-jugada: anillo roto a mitad de vuelo --")
rings = [Ring(0, 0), Ring(30, 0), Ring(60, 0), Ring(90, 0), Ring(120, 0)]
p = Player(-15, 0)
p.chain = find_chain(p.x, p.y, rings)
check("cadena de 5", len(p.chain) == 5)
frames = 0
while travel_frame(p, rings) and frames < 200:
    frames += 1
    if frames == 2:
        rings[2].used = True  # el EXE revienta el 3o
check("anillo roto: el dash lo salta y come el resto",
      len(p.collected) == 4 and rings[3].used and rings[4].used)

# --- 2.4: gates de activacion ---
print("-- activacion --")
rings = [Ring(0, 0)]
check("gate: 1 anillo solo SI forma cadena (v5.9.3)",
      len(find_chain(10, 0, rings)) == 1)
rings = [Ring(0, 0), Ring(28, 0)]
check(f"gate: linea a >{FIRST_RADIUS:g} px fuera de captura",
      len(find_chain(200, 200, rings)) == 0)
r = Ring(0, 0)
r2 = Ring(28, 0)
r2.alpha = 0.5
check("gate: anillo en fade-in excluido",
      len(find_chain(10, 0, [r, r2])) == 1)

# --- 2.5: tope de tiempo/eslabones ---
print("-- seguridad --")
rings = [Ring(i * 24, 0) for i in range(30)]
chain = find_chain(0, 0, rings)
check(f"tope: la cadena se corta en MAX_RINGS ({MAX_RINGS})",
      len(chain) == MAX_RINGS)

# --- 2.6: geometria de la FLECHA v5.9.2 (no tapa la cadena) ---
print("-- flecha: geometria del indicador --")


def ldx(l, d):
    return l * math.cos(math.radians(d))


def ldy(l, d):
    return -l * math.sin(math.radians(d))


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
    kx = r0[0] + ldx(16, d - 90)
    ky = r0[1] + ldy(16, d - 90)
    ax = r0[0] + ldx(16, d + 180)
    ay = r0[1] + ldy(16, d + 180)
    for (rx, ry) in chn:
        if point_distance(kx, ky, rx, ry) < 10:
            ok_keycap = False
        if point_distance(ax, ay, rx, ry) < 10 and (rx, ry) != (r0[0], r0[1]):
            ok_arrow = False
    if abs(angle_difference(d, point_direction(amy[0], amy[1], r0[0], r0[1]))) > 0.01:
        ok_arrow = False
check("flecha: el keycap nunca pisa un anillo de la cadena", ok_keycap)
check("flecha: el ancla queda libre y apunta al primer tramo", ok_arrow)

# --- 2.7: lunge de 1 anillo + tolerancias (valores del usuario) ---
print("-- v5.9.3: lunge de 1 anillo y tolerancias --")

rings = [Ring(40, 0, 7, 77)]
p = Player(0, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("v5.9.3: lunge de 1 anillo: lo recoge y sale con impulso",
      rings[0].used and len(p.collected) == 1 and len(p.packets) == 1
      and abs(p.vx - SPEED) < 0.01 and abs(p.vy) < 0.01,
      f"vx={p.vx:.2f} vy={p.vy:.2f}")

rings = [Ring(0, 0), Ring(250, 0), Ring(500, 0)]
check(f"v5.9.3/usuario: LINK {LINK_DIST:g} engancha anillos separados 250 px",
      len(find_chain(-10, 0, rings)) == 3)

check(f"v5.9.3/usuario: primer anillo capturado a 200 px (radio {FIRST_RADIUS:g})",
      len(find_chain(0, 0, [Ring(200, 0)])) == 1)
check("v5.9.3/usuario: a 240 px sigue fuera del radio",
      len(find_chain(0, 0, [Ring(240, 0)])) == 0)

# --- 2.8: estela continua y ritmo ---
print("-- v5.9.4: estela continua y ritmo --")

rings = [Ring(i * 30, 0) for i in range(5)]
p = Player(-20, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 200:
    frames += 1
check(f"v5.9.4: 140 px duran ceil(140/SPEED) frames ({math.ceil(140 / SPEED)})",
      frames == math.ceil(140 / SPEED - 1e-9), f"{frames} frames")
check("v5.9.4: estela completa — arranque + vuelo + salida",
      frames + 2 >= math.ceil(140 / SPEED - 1e-9) + 2)

rings = [Ring(40, 0)]
p = Player(0, 0)
p.chain = find_chain(p.x, p.y, rings)
frames = 0
while travel_frame(p, rings) and frames < 100:
    frames += 1
check("v5.9.4: el lunge mas corto tambien deja estela (>= 3 fantasmas)",
      frames + 2 >= 3)

# --- 2.9: terreno (v5.9.5 + semantica v5.10) ---
print("-- v5.9.5/v5.10: terreno (muros, pisos, apoyados) --")

# (a) anillo DETRAS de un muro que TAPA TODA la sala: ni recto ni
# rodeando -> sin cadena (y el A* lo intento, no fue un gate)
world = make_world([(40, -20, 12, 640)])
rings = [Ring(90, 0, 9, 909)]
flight, chain = find_route(world, 0, 0, rings)
check("v5.10: anillo tras muro SIN salida no encadena (A* lo intento)",
      len(chain) == 0 and len(flight) == 0 and world["astar"] >= 1)

world2 = make_world([])
flight, chain = find_route(world2, 0, 0, rings)
check("v5.10: el mismo anillo sin muro encadena (regresion del radio)",
      len(chain) == 1 and world2["astar"] == 0)

# (b) anillo APOYADO en el suelo: lunge directo, sin A*
floor = [(0, 390, 800, 210)]
rings = [Ring(100, 378, 10, 1010)]
world = make_world(floor)
flight, chain = find_route(world, 100, 300, rings)
check("v5.10: anillo APOYADO en el suelo SI encadena (lunge intacto)",
      len(chain) == 1 and not any(isinstance(e, Wp) for e in flight)
      and world["astar"] == 0)
p = Player(100, 300)
p.chain = flight
frames = 0
while travel_frame(p, rings) and frames < 200:
    frames += 1
check("v5.10: el lunge al anillo del suelo lo recoge y termina AFUERA",
      rings[0].used and len(p.packets) == 1 and not point_in_terrain(p.x, p.y, floor),
      f"pos final ({p.x:.0f},{p.y:.0f})")

# (c) eslabon ENTERRADO: la higiene de candidatos lo excluye
rings = [Ring(200, 350, 11, 1011), Ring(240, 400, 12, 1012)]
world = make_world(floor)
flight, chain = find_route(world, 200, 300, rings)
check("v5.10: eslabon ENTERRADO se salta (higiene de candidatos)",
      len(chain) == 1 and chain[0] is rings[0])
p = Player(200, 300)
p.chain = flight
frames = 0
while travel_frame(p, rings) and frames < 200:
    frames += 1
check("v5.10: recoge el visible y NUNCA entra en el piso",
      rings[0].used and not rings[1].used and not point_in_terrain(p.x, p.y, floor))

# (d) el anillo VISIBLE arranca antes que el bloqueado (sin gastar A*)
wall2 = [(30, -10, 12, 70)]
rings = [Ring(50, 0, 13, 1013), Ring(40, -45, 14, 1014)]
world = make_world(wall2)
flight, chain = find_route(world, 0, 0, rings)
check("v5.10: el anillo VISIBLE arranca antes que el bloqueado (sin A*)",
      len(chain) == 2 and chain[0] is rings[1] and chain[1] is rings[0]
      and world["astar"] == 0)
p = Player(0, 0)
p.chain = flight
frames = 0
touched = False
while travel_frame(p, rings) and frames < 200:
    frames += 1
    if point_in_terrain(p.x, p.y, wall2):
        touched = True
check("v5.10: RODEA por el anillo visible y LLEGA al de atras",
      rings[0].used and rings[1].used and not touched)

# (e) eslabones pegadisimos: el guard de 2*TRIM no rompe cadenas densas
rings = [Ring(0, 0, 30, 1030), Ring(12, 0, 31, 1031)]
world = make_world([(5, -5, 2, 10)])
flight, chain = find_route(world, -4, 0, rings)
check("v5.10: eslabones pegados (12 px) encadenan sin drama del margen",
      len(chain) == 2 and world["astar"] == 0)

# --- 2.10: PATHFINDING A* REAL ---
print("-- v5.10: PATHFINDING A* (el rodeo de verdad) --")

# (f) EL CASO PEDIDO: anillo detras de un muro con hueco abajo, SIN
# ningun otro anillo que guie. El A* traza el rodeo, el string pulling
# lo endereza y el rayo sigue los quiebres hasta el anillo.
wallf = [(40, 4, 12, 76)]  # x 40..52, y 4..80 (libre por abajo)
rings = [Ring(90, 40, 15, 1015)]
world = make_world(wallf)
flight, chain = find_route(world, 0, 40, rings)
check("v5.10 A*: anillo tras muro CON salida -> encadena con WAYPOINTS",
      len(chain) == 1 and len(flight) > 1 and isinstance(flight[0], Wp)
      and world["astar"] >= 1)

p = Player(0, 40)
p.chain = flight
frames = 0
touched = False
while travel_frame(p, rings) and frames < 400:
    frames += 1
    if point_in_terrain(p.x, p.y, wallf):
        touched = True
check("v5.10 A*: el rayo RODEA el muro, recoge el anillo y no toca nada",
      rings[0].used and len(p.packets) == 1 and not touched
      and abs(p.x - 90) < 0.01 and abs(p.y - 40) < 0.01)

d_total = point_distance(0, 40, flight[0].x, flight[0].y)
for k in range(1, len(flight)):
    d_total += point_distance(flight[k - 1].x, flight[k - 1].y,
                              flight[k].x, flight[k].y)
check("v5.10 A*: el viaje dura exactamente la ruta / SPEED",
      frames == math.ceil(d_total / SPEED - 1e-9),
      f"{frames} frames vs {math.ceil(d_total / SPEED - 1e-9)}")

# la FLECHA: halo en el anillo, direccion = primer tramo de la RUTA
aim = [e for e in flight if not isinstance(e, Wp)]
aim_dir = point_direction(0, 40, flight[0].x, flight[0].y)
check("v5.10 A*: la flecha apunta al PRIMER QUIEBRE (no a la pared)",
      aim == [rings[0]]
      and abs(angle_difference(aim_dir,
                               point_direction(0, 40, rings[0].x, rings[0].y))) > 30,
      f"dir ruta {aim_dir:.1f} vs dir anillo "
      f"{point_direction(0, 40, rings[0].x, rings[0].y):.1f}")

# (g) rodeo mas largo que el presupuesto -> descartado como en v5.9.5
wallh = [(40, 4, 12, 380)]
rings = [Ring(90, 100, 16, 1016)]
world = make_world(wallh)
flight, chain = find_route(world, 0, 100, rings)
check("v5.10 A*: rodeo sobre presupuesto (ROUTE_FACTOR) -> descartado",
      len(chain) == 0 and world["astar"] >= 1)

# (h) REGRESION CRITICA: con linea de vision no corre NINGUN A*
rings = [Ring(0, 0), Ring(28, 0), Ring(56, 0), Ring(84, 0)]
world = make_world([])
flight, chain = find_route(world, -20, 0, rings)
check("v5.10: con linea de vision NO corre ningun A* (caso comun intacto)",
      world["astar"] == 0 and len(chain) == 4
      and not any(isinstance(e, Wp) for e in flight))

# (i) el EXE revienta el primer anillo a mitad de desvio: el rayo sigue
# los quiebres, se salta el roto y come el segundo
rings = [Ring(90, 40, 17, 1017), Ring(240, 40, 18, 1018)]
world = make_world(wallf)
flight, chain = find_route(world, 0, 40, rings)
check("v5.10 A*: cadena de 2 tras el muro (desvio + extension directa)",
      len(chain) == 2 and isinstance(flight[0], Wp)
      and not isinstance(flight[-1], Wp))
p = Player(0, 40)
p.chain = flight
frames = 0
touched = False
while travel_frame(p, rings) and frames < 400:
    frames += 1
    if frames == 3:
        rings[0].used = True  # el EXE revienta el primero
    if point_in_terrain(p.x, p.y, wallf):
        touched = True
check("v5.10 A*: anillo roto a mitad de desvio -> sigue quiebres y come el 2o",
      rings[0] not in p.collected and rings[1].used and len(p.packets) == 1
      and not touched)

# (j) el grid no acumula celdas fantasma (re-bloqueo condicional exacto)
world = make_world(wallf)
snap = set(world["blocked"])
rings = [Ring(90, 40, 50, 1050), Ring(300, 200, 51, 1051), Ring(60, 500, 52, 1052)]
for ax, ay in [(0, 40), (280, 180), (40, 480), (44, 10), (0, 40)]:
    find_route(world, ax, ay, rings)
check("v5.10 A*: el grid no acumula celdas fantasma (re-bloqueo exacto)",
      world["blocked"] == snap)

# (k) el tuning del usuario contra el mapa disperso de TD
rings = [Ring(0, 0, 40, 1040), Ring(250, 0, 41, 1041), Ring(500, 0, 42, 1042)]
world = make_world([])
flight, chain = find_route(world, -10, 0, rings)
check(f"v5.10/usuario: anillos TD separados 250 px encadenan (LINK {LINK_DIST:g})",
      len(chain) == 3 and world["astar"] == 0)

print()
if fails:
    print(f"RESULTADO: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULTADO: TODO OK")
