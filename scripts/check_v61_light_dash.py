#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v61_light_dash.py — verificacion del LIGHT DASH + LSA de Amy Canon
(v6.1: CORRECCION DE DISEÑO del LSA — la C EN EL AIRE dispara el LSA con
CADENA de enemigos: golpea a uno, salta a otro, JAMAS repite objetivos,
luego se lanza por los anillos, intercepta enemigos no golpeados por el
camino y NUNCA detecta a nadie con i-frames; la C EN EL SUELO es el
martillo de siempre. Se conservan intactos los v6.0: i-frames durante
el vuelo y 2 s al salir, frenado de emergencia con X, fix del dash
clavado al piso y fix de la rotacion invisible con isSpinning).
Hereda TODAS las comprobaciones v5.9-v6.0 (cero regresiones).

Parte 1 (estatica): brackets balanceados en todos los archivos tocados,
los 8 puntos de integracion presentes, colision de estados evitada
(LIGHTDASH=25 vs HUG=24), sprite registrado con frames reales, y el
TUNING DEL USUARIO pineado (SPEED 5 / RADIUS 220 / LINK 275 / RINGS 20 /
TIME 200) para que nadie lo revierta sin darse cuenta. v6.1 anade:
macros de la cadena, la C dentro del bloque AEREO (antes que la Z), el
bloque del LSA separado de la Z, la banda lsaHit, la intercepcion, el
gate de i-frames del golpe y el gate isGrounded del martillo.

Parte 2 (simulacion): la logica del dash porteada 1:1 a Python, con las
constantes PARSEADAS del propio gml (unica fuente de verdad). v6.1 anade:
  - LSA AEREO: el bloque de la C vive dentro de if(!isGrounded) y la C
    del suelo sigue siendo el martillo (gate isGrounded del especial).
  - CADENA DE ENEMIGOS: golpea al mas cercano -> SALTA al siguiente no
    golpeado -> JAMAS repite objetivos (banda lsaHit) -> cuando no queda
    nadie, se lanza por los ANILLOS de la zona.
  - INTERCEPCION: un enemigo no golpeado que aparezca por el camino a
    menos de LSA_INTERCEPT desvia el rayo ANTES que el objetivo original.
  - I-FRAMES: nadie con isHurt es objetivo (ni arranque, ni re-plan, ni
    intercepcion) y si el objetivo los gana a mitad de vuelo, el golpe
    NO entra (pero queda marcado: no se repite).
  - TOPE: con mas de LSA_MAX_TARGETS enemigos, la cadena corta sola.
Se conservan las sims v6.0 (objetivo/homing/golpe/esquiva/senal, fix
piso, frenado, i-frames de vuelo) y v5.9-v5.10 (rotacion, cadena,
terreno, A*).
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
    "scripts/net_state_game/net_state_game.gml",
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
check("v5.9.4/v6.0 scr_light_dash: arranques y salidas dejan su fantasma (4 llamadas x,y)",
      ld.count("scr_light_dash_ghost(x, y);") == 4
      and _exit_fn != -1
      and ld.find("scr_light_dash_ghost(x, y);", _exit_fn) != -1,
      "2 en v5.9.4 (arranque Z + salida); v6.0 anade arranque LSA y freno")
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
_flecha = ld.find("============ 2. LSA")
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


# --- v6.0: LSA + i-frames + frenado + fixes (estatica) ---
nsg = sources.get("scripts/net_state_game/net_state_game.gml", "")
check("v6.0 FILES: net_state_game cargado (rama de la senal)",
      "CLIENT_SOUND_EMIT" in nsg)

check("v6.0 macros: LSA (RANGE/PURSUIT/HIT/STUN/MAX_TIME) + IFRAME_EXIT",
      re.search(r"#macro\s+LSA_RANGE\s+400\b", ld) is not None
      and re.search(r"#macro\s+LSA_PURSUIT\s+\(LSA_RANGE \* 1\.5\)", ld) is not None
      and re.search(r"#macro\s+LSA_HIT_RADIUS\s+48\b", ld) is not None
      and re.search(r"#macro\s+LSA_STUN_TIME\s+\(60 \* 3\)", ld) is not None
      and re.search(r"#macro\s+LSA_MAX_TIME\s+300\b", ld) is not None
      and re.search(r"#macro\s+LIGHT_DASH_IFRAME_EXIT\s+\(60 \* 2\)", ld) is not None)

check("v6.1 macros: la CADENA (NEXT_DIST/INTERCEPT/MAX_TARGETS)",
      re.search(r"#macro\s+LSA_NEXT_DIST\s+LSA_RANGE", ld) is not None
      and re.search(r"#macro\s+LSA_INTERCEPT\s+140\b", ld) is not None
      and re.search(r"#macro\s+LSA_MAX_TARGETS\s+6\b", ld) is not None)

check("v6.0/v6.1 scr_light_dash: funciones LSA + frenado + chain presentes",
      all(f"function {f}(" in ld for f in
          ["scr_lsa_find_target", "scr_lsa_find_target_at", "scr_lsa_leg_to",
           "scr_lsa_next_leg", "scr_lsa_hit", "scr_lsa_stun_signal",
           "scr_light_dash_brake", "scr_light_dash_chain"]))

check("v6.0 scr_light_dash: la Z NUNCA es un LSA (reset en el arranque)",
      "isLSA = false;      // v6.0: el dash de la Z NUNCA es un LSA" in ld)

# v6.1 — estructura: la C (LSA) vive DENTRO del bloque aereo, PRIMERO;
# la Z (flecha) despues; el suelo no activa nada (nota del martillo)
_sec2 = ld.find("============ 2. LSA")
_sec3 = ld.find("================= 3. FLECHA")
_airgate = ld.find("if(!isGrounded)", _sec2)
_cc = ld.find("keyboard_check_pressed(global.KeyC)", _sec2)
_groundnote = ld.find("En el SUELO este hook")
check("v6.1 estructura: secciones LSA (2) y Z (3) presentes y ordenadas",
      -1 < _sec2 < _airgate < _cc < _sec3 < _groundnote)
check("v6.1 estructura: la C vive DENTRO del bloque aereo (LSA = C en el AIRE)",
      _airgate != -1 and _cc != -1 and _sec2 < _airgate < _cc < _sec3)
check("v6.1 estructura: la Z (seccion 3) no toca la C ni objetivos LSA",
      "KeyC" not in ld[_sec3:_groundnote]
      and "scr_lsa" not in ld[_sec3:_groundnote])
check("v6.1 estructura: el SUELO no activa nada aqui (ahi manda el martillo)",
      "scr_amy_canon_special" in ld[_groundnote:_groundnote + 400]
      and "exige isGrounded" in ld[_groundnote:_groundnote + 400])

check("v6.1 scr_light_dash: activacion del LSA = C con CD compartido (dashTimer)",
      "if(keyboard_check_pressed(global.KeyC) && dashTimer <= 0)" in ld
      and "dashTimer = revivalTimes >= 2 ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;" in ld)

check("v6.1 scr_light_dash: la banda se limpia ANTES de buscar al primero",
      ld.find("lsaHit = [];       // vuelo NUEVO", _sec2)
      < ld.find("var _exe = scr_lsa_find_target();", _sec2))

check("v6.0 scr_light_dash: el LSA arranca con isAttacking (contacto-stun)",
      "isAttacking = true; // el exe que TOQUE el rayo queda aturdido" in ld)

check("v6.0 scr_light_dash: gates comunes (isHiding, sin isGrounded global)",
      "if(isHiding)" in ld
      and re.search(r"if\(isDead \|\| isHurt \|\| shockedTimer > 0 \|\| isZipline\)", ld) is not None
      and "if(isGrounded || isDead || isHurt" not in ld)

check("v6.0 scr_light_dash: homing del eslabon con tope de persecucion",
      'variable_struct_exists(_tgt, "exe")' in ld
      and "point_distance(x, y, _live.x, _live.y) < LSA_PURSUIT" in ld
      and 'array_push(_leg, {x: _exe.x, y: _exe.y, exe: _exe});' in ld)

check("v6.1 scr_light_dash: intercepcion SOLO en fase de anillos (LSA_INTERCEPT)",
      'if(isLSA && _tgt != noone && !(is_struct(_tgt) && variable_struct_exists(_tgt, "exe")) && array_length(lsaHit) < LSA_MAX_TARGETS)' in ld
      and "scr_lsa_find_target_at(x, y, LSA_INTERCEPT, lsaHit, noone)" in ld
      and "fase de anillos" in ld)

check("v6.1 scr_light_dash: la llegada marca al objetivo y encadena el siguiente",
      "array_push(lsaHit, _tgt.exe.id);" in ld
      and "array_find_index(lsaHit, _tgt.exe.id) == -1" in ld
      and "scr_lsa_next_leg(_tgt.x, _tgt.y);" in ld
      and "array_push(lightDashChain, _leg[i]);" in ld)

check("v6.0 scr_light_dash: el golpe del LSA en la llegada (scr_lsa_hit)",
      'else if(variable_struct_exists(_tgt, "exe"))' in ld
      and "scr_lsa_hit(_tgt);" in ld)

check("v6.0 scr_light_dash: FRENADO solo del dash de la Z (X, !isLSA)",
      "if(!isLSA && keyboard_check_pressed(global.KeyB))" in ld)

check("v6.0 scr_light_dash: el freno es parada total + latch de 2 frames",
      "lightDashBrakeLatch = 2;" in ld
      and re.search(r"xspd = 0;\s*\n\s*yspd = 0;\s*\n\s*gspd = 0;", ld) is not None)

check("v6.0 scr_light_dash: i-frames durante el vuelo (hurttime > 0)",
      "hurttime = max(hurttime, 2);" in ld)

_pose_fn = ld.find("function scr_light_dash_pose()")
_pose_end = ld.find("function scr_light_dash_ghost(")
check("v6.0 FIX PISO: el pose re-afirma isGrounded = false (seguro burbuja)",
      _pose_fn != -1 and _pose_end != -1
      and "isGrounded = false;" in ld[_pose_fn:_pose_end]
      and "pozo de la burbuja" in ld[_pose_fn:_pose_end])

check("v6.0 scr_light_dash: salida con 2 s de i-frames + reset de modo",
      ld.count("hurttime = LIGHT_DASH_IFRAME_EXIT;") == 2
      and "isLSA = false;         // v6.0: reset del modo" in ld
      and "isAttacking = false;   // v6.0: el contacto-stun del vuelo muere" in ld)

check("v6.0 scr_light_dash: tope de tiempo propio del LSA",
      "lightDashTime > (isLSA ? LSA_MAX_TIME : LIGHT_DASH_MAX_TIME)" in ld)

check("v6.0 scr_light_dash: objetivo = bando exe mas cercano (filtros Chocola)",
      "if(isInactive || !visible)" in ld
      and "if(isHurt)          // i-frames: no se le pega al transparente" in ld
      and "if(state == DEAD)   // ya stuneado / fuera de combate" in ld
      and "if(character != CHARACTER_EXE && !isDemonized)" in ld
      and "point_distance(x, y, _fx, _fy)" in ld)

check("v6.1 scr_light_dash: buscador general con banda y skip (jamas repetir)",
      "function scr_lsa_find_target_at(" in ld
      and "array_find_index(_hitList, id) != -1" in ld
      and "_skipExe != noone && id == _skipExe" in ld)

check("v6.1 scr_light_dash: el tramo al objetivo (leg_to) con A* y eslabon vivo",
      "function scr_lsa_leg_to(" in ld
      and "LSA_RANGE * LIGHT_DASH_ROUTE_FACTOR" in ld
      and "if(!_direct && array_length(_wps) == 0)" in ld)

check("v6.1 scr_light_dash: la cadena enemigo->enemigo->anillos (next_leg)",
      "function scr_lsa_next_leg(" in ld
      and "LSA_NEXT_DIST, lsaHit, noone)" in ld
      and "return scr_light_dash_chain(_fx, _fy, LIGHT_DASH_LINK_DIST);" in ld)

check("v6.0 scr_light_dash: el golpe exige cercania real (HIT_RADIUS)",
      "point_distance(_slot.x, _slot.y, _exe.x, _exe.y) > LSA_HIT_RADIUS" in ld)

check("v6.0 scr_light_dash: senal por snd_dash dirigido al nid del objetivo",
      "net_sound_emit_at(snd_dash, _exe.master_id);" in ld)

check("v6.1 scr_light_dash: el golpe respeta i-frames ganados a mitad de vuelo",
      "if(_exe.isHurt)" in ld
      and "el golpe no entra (esquivado)" in ld)

_sig_fn = ld.find("function scr_lsa_stun_signal()")
check("v6.0 scr_light_dash: stun_signal = modelo Chocola (sonido ANTES del dedup)",
      _sig_fn != -1
      and ld.find("audio_play_sound(snd_exe_stun, 0, false);", _sig_fn)
      < ld.find("if(global.player.shockedTimer > 0)", _sig_fn)
      and "shockedTimer = LSA_STUN_TIME;" in ld
      and "scr_exe_stunsound();" in ld
      and "PacketType.CLIENT_PLAYER_HURT" in ld)

check("v6.0 net_state_game: rama de la senal del LSA (shouldPlay + snd_dash)",
      "else if(global.net_snds[sid] == snd_dash)" in nsg
      and "scr_lsa_stun_signal();" in nsg)

check("v6.0 Create: declara isLSA + lightDashBrakeLatch",
      re.search(r"isLSA\s*=\s*false;", cr) is not None
      and re.search(r"lightDashBrakeLatch\s*=\s*0;", cr) is not None)

check("v6.1 Create: declara lsaHit (la banda de la cadena)",
      re.search(r"lsaHit\s*=\s*\[\];", cr) is not None)

check("v6.1 scr_light_dash: lazy declara lsaHit (red de seguridad)",
      "lsaHit = [];             // v6.1: objetivos ya golpeados" in ld)

check("v6.0 Draw_0: la rotacion del rayo manda sobre la bola (fix isSpinning)",
      "(isSpinning && !isLightDashing) ? 0 : radtodeg(angle)" in d0)

check("v6.0 special: latch del frenado apaga el impulso de tarot",
      "lightDashBrakeLatch <= 0" in sp
      and "if(lightDashBrakeLatch > 0)" in sp)

check("v6.1 special: la C EN EL SUELO sigue siendo el MARTILLO (gate)",
      re.search(r"!isDashing && isGrounded && !isLightDashing && keyboard_check_pressed\(global\.KeyC\)", sp) is not None
      and "aire la C es el LSA" in sp)

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


# =====================================================================
#  v6.0/v6.1 — SIMULACIÓN LSA + FIXES (constantes PARSEADAS del gml)
# =====================================================================
print()
print("-- v6.0/v6.1: LSA (objetivo, cadena, intercepcion, golpe, senal) --")

def macro_expr(name, _seen=None):
    """Evalua una macro que es una EXPRESION ((60 * 3), (LSA_RANGE * 1.5)):
    sustituye referencias a otras macros y calcula el resultado. Solo
    aritmetica basica (whitelist de caracteres)."""
    _seen = _seen if _seen is not None else set()
    if name in _seen:
        return None
    _seen.add(name)
    m = re.search(r"#macro\s+" + re.escape(name) + r"\s+([^\n]+)", ld)
    if not m:
        return None
    txt = m.group(1).strip()
    for ref in sorted(set(re.findall(r"(?:LIGHT_DASH|LSA)_\w+", txt)),
                      key=len, reverse=True):
        if ref == name:
            continue
        v = macro_expr(ref, _seen)
        if v is None:
            return None
        txt = re.sub(r"\b" + ref + r"\b", "(" + repr(v) + ")", txt)
    if not re.fullmatch(r"[0-9.+\-*/() ]+", txt):
        return None
    try:
        return eval(txt, {"__builtins__": {}}, {})
    except Exception:
        return None


LSA_RANGE = macro_expr("LSA_RANGE")
LSA_PURSUIT = macro_expr("LSA_PURSUIT")
LSA_HIT = macro_expr("LSA_HIT_RADIUS")
LSA_STUN = macro_expr("LSA_STUN_TIME")
LSA_MAX_TIME = macro_expr("LSA_MAX_TIME")
IFRAME_EXIT = macro_expr("LIGHT_DASH_IFRAME_EXIT")
LSA_NEXT = macro_expr("LSA_NEXT_DIST")
LSA_INTERCEPT = macro_expr("LSA_INTERCEPT")
LSA_MAX_TARGETS = macro_expr("LSA_MAX_TARGETS")

check("sim v6.0: las 6 macros del LSA/i-frames se parsean del gml",
      None not in (LSA_RANGE, LSA_PURSUIT, LSA_HIT, LSA_STUN,
                   LSA_MAX_TIME, IFRAME_EXIT))
check("sim v6.0: valores del pedido (stun 3 s, i-frames de salida 2 s)",
      LSA_STUN == 180 and IFRAME_EXIT == 120)
check("sim v6.1: las 3 macros de la cadena se parsean del gml",
      None not in (LSA_NEXT, LSA_INTERCEPT, LSA_MAX_TARGETS))
check("sim v6.1: NEXT == RANGE (mismo alcance) y tope de 6 objetivos",
      LSA_NEXT == LSA_RANGE and LSA_MAX_TARGETS == 6)


class Puppet:
    """Puerto minimo del obj_player_puppet para el buscador de objetivos."""

    def __init__(self, x, y, character="EXE", demonized=False,
                 inactive=False, hurt=False, dead_state=False, visible=True):
        self.x, self.y = x, y
        self.character = character
        self.demonized = demonized
        self.inactive = inactive
        self.hurt = hurt
        self.dead_state = dead_state  # state == DEAD (ya stuneado)
        self.visible = visible
        self.stun_count = 0           # v6.1: cuantos stuns del LSA le cayeron


def find_lsa_target_at(fx, fy, maxd, hit_list, skip, puppets):
    """Puerto 1:1 de scr_lsa_find_target_at (banda + skip incluidos)."""
    best, bestd = None, maxd
    for p in puppets:
        if p.inactive or not p.visible:
            continue
        if p.hurt:
            continue
        if p.dead_state:
            continue
        if p.character != "EXE" and not p.demonized:
            continue
        if skip is not None and p is skip:
            continue
        if p in hit_list:
            continue
        d = point_distance(fx, fy, p.x, p.y)
        if d < bestd:
            bestd, best = d, p
    return best


def find_lsa_target(amy_x, amy_y, puppets):
    """Puerto de scr_lsa_find_target (envoltorio: banda vacia)."""
    return find_lsa_target_at(amy_x, amy_y, LSA_RANGE, [], None, puppets)


# (a) el exe mas cercano gana; los supervivientes ni cuentan
puppets = [Puppet(500, 100, "SONIC"), Puppet(300, 100), Puppet(380, 100)]
check("LSA objetivo: el EXE mas cercano (los aliados ni cuentan)",
      find_lsa_target(0, 0, puppets) is puppets[1])

# (b) esbirro demonizado tambien vale (y gana por cercania)
puppets = [Puppet(350, 100), Puppet(200, 100, "AMY", demonized=True)]
check("LSA objetivo: el esbirro demonizado SI vale y gana por cercania",
      find_lsa_target(0, 0, puppets) is puppets[1])

# (c) filtros: i-frames, ya stuneado, invisible, inactivo, fuera de rango
puppets = [Puppet(300, 100, hurt=True)]
check("LSA objetivo: con i-frames no es fijable", find_lsa_target(0, 0, puppets) is None)
puppets = [Puppet(300, 100, dead_state=True)]
check("LSA objetivo: ya stuneado (state DEAD) no es fijable",
      find_lsa_target(0, 0, puppets) is None)
puppets = [Puppet(300, 100, visible=False)]
check("LSA objetivo: el exe invisible no es fijable", find_lsa_target(0, 0, puppets) is None)
puppets = [Puppet(300, 100, inactive=True)]
check("LSA objetivo: el inactivo no es fijable", find_lsa_target(0, 0, puppets) is None)
puppets = [Puppet(LSA_RANGE + 1, 0)]
check(f"LSA objetivo: a {LSA_RANGE + 1:g} px esta fuera de captura",
      find_lsa_target(0, 0, puppets) is None)

# (c2) v6.1 — la banda: un objetivo golpeado JAMAS vuelve a ser objetivo
puppets = [Puppet(300, 100)]
exe = puppets[0]
check("LSA banda: el ya golpeado no vuelve a ser objetivo (JAMAS repite)",
      find_lsa_target_at(0, 0, LSA_RANGE, [exe], None, puppets) is None)

# (c3) v6.1 — el skip: el buscador general puede excluir a quien se pida
# (lo usa la intercepcion con noone; el parametro queda para futuros usos)
puppets = [Puppet(100, 0), Puppet(120, 0)]
check("LSA skip: sin skip, el mas cercano gana",
      find_lsa_target_at(0, 0, LSA_INTERCEPT, [], None, puppets) is puppets[0])
check("LSA skip: con skip, el excluido no cuenta",
      find_lsa_target_at(0, 0, LSA_INTERCEPT, [], puppets[0], puppets) is puppets[1])

# (d) el LSA encadena anillos DESDE la posicion del objetivo (LINK_DIST)


def find_chain_reach(px, py, rings, first_reach, terrain=None):
    """Puerto de scr_light_dash_chain con captura inicial custom."""
    world = make_world(terrain or [])
    flight, chain = [], []
    ax, ay = px, py
    while len(chain) < MAX_RINGS:
        reach = first_reach if len(chain) == 0 else LINK_DIST
        cand = []
        for r in rings:
            if r.used or not r.visible or r.alpha < 1:
                continue
            if point_in_terrain(r.x, r.y, world["terrain"]):
                continue
            if r in chain:
                continue
            d = point_distance(ax, ay, r.x, r.y)
            if d < reach:
                cand.append([d, r])
        if not cand:
            break
        nxt, nxtD = None, reach + 1
        for d, r in cand:
            if d >= nxtD:
                continue
            if seg_clear(ax, ay, r.x, r.y, world["terrain"]):
                nxtD, nxt = d, r
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


exe = Puppet(300, 100)
rings = [Ring(300, 80, 60, 1060), Ring(300, 56, 61, 1061)]
flight, chain = find_chain_reach(exe.x, exe.y, rings, LINK_DIST)
check("LSA extension: encadena anillos DESDE el exe (LINK_DIST de captura)",
      len(chain) == 2)
rings = [Ring(300 + LINK_DIST + 40, 100, 62, 1062)]
flight, chain = find_chain_reach(exe.x, exe.y, rings, LINK_DIST)
check("LSA extension: un anillo mas alla del eslabon no engancha",
      len(chain) == 0)


# (e) homing + golpe: el eslabon persigue al exe vivo


class ExeSlot:
    """El struct {x, y, exe} del eslabon de objetivo."""

    def __init__(self, exe):
        self.exe = exe
        self.x, self.y = exe.x, exe.y


def lsa_chase(p, exe, exe_move=None, max_frames=400):
    """Puerto del vuelo del LSA hacia el objetivo: homing con tope de
    persecucion, movimiento a SPEED y golpe al llegar (solo si el exe
    sigue a menos de LSA_HIT_RADIUS del eslabon)."""
    slot = ExeSlot(exe)
    frames = 0
    hits = 0
    while frames < max_frames:
        frames += 1
        if exe_move is not None:
            exe_move(exe)  # el exe se mueve a la vez que el rayo
        if point_distance(p.x, p.y, exe.x, exe.y) < LSA_PURSUIT:
            slot.x, slot.y = exe.x, exe.y  # homing
        dx, dy = slot.x - p.x, slot.y - p.y
        dist = math.hypot(dx, dy)
        if dist <= SPEED:
            p.x, p.y = slot.x, slot.y
            if point_distance(slot.x, slot.y, exe.x, exe.y) <= LSA_HIT:
                hits += 1
            return frames, hits
        p.x += dx / dist * SPEED
        p.y += dy / dist * SPEED
    return frames, hits


p = Player(0, 0)
exe = Puppet(200, 0)
frames, hits = lsa_chase(p, exe)
check("LSA golpe: exe quieto a 200 px — llega y pega UNA vez",
      hits == 1 and frames == math.ceil(200 / SPEED)
      and point_distance(p.x, p.y, exe.x, exe.y) < 0.01)

p = Player(0, 0)
exe = Puppet(200, 0)
frames, hits = lsa_chase(p, exe, exe_move=lambda e: setattr(e, "y", e.y - 2))
check("LSA homing: el exe se mueve y el golpe cae en su posicion NUEVA",
      hits == 1 and abs(exe.y - p.y) < SPEED)

p = Player(0, 0)
exe = Puppet(150, 0)
frames, hits = lsa_chase(p, exe, exe_move=lambda e: setattr(e, "x", e.x + 8))
check("LSA esquiva: el exe HUYE mas rapido que el rayo -> sin golpe",
      hits == 0 and frames < LSA_MAX_TIME,
      f"hits={hits} frames={frames}")


# (e2) v6.1 — EL VUELO COMPLETO DE LA CADENA: tramo -> golpe -> banda ->
# re-plan (siguiente enemigo) -> ... -> anillos. Puerto del bloque 1 con
# homing, intercepcion y golpe con i-frames.

def lsa_leg_to(world, fx, fy, exe):
    """Puerto 1:1 de scr_lsa_leg_to (waypoints del rodeo + eslabon vivo)."""
    wps = []
    direct = seg_clear(fx, fy, exe.x, exe.y, world["terrain"])
    if not direct:
        wps = route_detour(world, fx, fy, exe.x, exe.y, LSA_RANGE * ROUTE_FACTOR)
    if not direct and not wps:
        return None
    leg = [Wp(w[0], w[1]) for w in wps]
    leg.append(ExeSlot(exe))
    return leg


def lsa_next_leg(world, fx, fy, puppets, hit_list, rings):
    """Puerto 1:1 de scr_lsa_next_leg (siguiente enemigo o anillos)."""
    if len(hit_list) < LSA_MAX_TARGETS:
        exe = find_lsa_target_at(fx, fy, LSA_NEXT, hit_list, None, puppets)
        if exe is not None:
            leg = lsa_leg_to(world, fx, fy, exe)
            if leg is not None:
                return leg
    world2 = make_world(world["terrain"])
    return find_chain_reach(fx, fy, rings, LINK_DIST)[0]


def link_alive(r):
    if isinstance(r, (Wp, ExeSlot)):
        return True
    return not r.used


def lsa_flight(world, amy, puppets, rings, max_frames=3000, on_frame=None):
    """Puerto del vuelo completo del LSA: resuelve eslabon, homing,
    INTERCEPCION (enemigo no golpeado a < LSA_INTERCEPT que no sea el
    perseguido), movimiento con budget, golpe al llegar (cercania real +
    i-frames), marca en la banda y re-plan. Devuelve
    (frames, orden_de_golpes, anillos_recogidos, banda)."""
    hit_list = []
    hit_order = []
    collected = []
    first = find_lsa_target_at(amy[0], amy[1], LSA_RANGE, hit_list, None, puppets)
    if first is None:
        return 0, [], [], hit_list
    chain = lsa_leg_to(world, amy[0], amy[1], first)
    if chain is None:
        return 0, [], [], hit_list
    x, y = amy
    idx = 0
    frames = 0
    while frames < max_frames:
        frames += 1
        if on_frame:
            on_frame(frames, puppets)
        tgt = None
        while idx < len(chain):
            r = chain[idx]
            if link_alive(r):
                tgt = r
                break
            idx += 1
        if tgt is None:
            break
        if isinstance(tgt, ExeSlot):
            live = tgt.exe
            if point_distance(x, y, live.x, live.y) < LSA_PURSUIT:
                tgt.x, tgt.y = live.x, live.y
        # v6.1: intercepcion SOLO fuera de la fase enemigo->enemigo
        # (anillos/waypoints): la cadena secuencia sola entre objetivos
        if not isinstance(tgt, ExeSlot) and len(hit_list) < LSA_MAX_TARGETS:
            snap = find_lsa_target_at(x, y, LSA_INTERCEPT, hit_list, None, puppets)
            if snap is not None:
                leg = lsa_leg_to(world, x, y, snap)
                if leg is not None:
                    chain = leg
                    idx = 0
                    tgt = chain[0]
        budget = SPEED
        while budget > 0 and tgt is not None:
            dx, dy = tgt.x - x, tgt.y - y
            dist = math.hypot(dx, dy)
            if dist <= budget or dist == 0:
                x, y = tgt.x, tgt.y
                budget -= max(dist, 0)
                idx += 1
                if isinstance(tgt, ExeSlot):
                    exe = tgt.exe
                    if point_distance(tgt.x, tgt.y, exe.x, exe.y) <= LSA_HIT and not exe.hurt:
                        exe.stun_count += 1
                        hit_order.append(exe)
                    if exe not in hit_list:
                        hit_list.append(exe)
                    chain = chain + lsa_next_leg(world, tgt.x, tgt.y, puppets, hit_list, rings)
                elif not isinstance(tgt, Wp):
                    tgt.used = True
                    collected.append(tgt)
                tgt = None
                while idx < len(chain):
                    r2 = chain[idx]
                    if link_alive(r2):
                        tgt = r2
                        break
                    idx += 1
            else:
                x += dx / dist * budget
                y += dy / dist * budget
                budget = 0
    return frames, hit_order, collected, hit_list


print("-- v6.1: LA CADENA (golpea uno, salta a otro, luego anillos) --")

# (g) la cadena completa: exe -> esbirro demonizado -> anillos; el aliado ni cuenta
world = make_world([])
puppets = [Puppet(150, 0),
           Puppet(300, -50, "AMY", demonized=True),
           Puppet(100, -20, "SONIC")]
rings = [Ring(300, -100, 70, 1070), Ring(300, -150, 71, 1071)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, rings)
check("LSA cadena: golpea al exe, SALTA al esbirro y NO toca al aliado",
      [p.character for p in order] == ["EXE", "AMY"]
      and puppets[2].stun_count == 0,
      f"orden={[p.character for p in order]}")
check("LSA cadena: cada enemigo golpeado EXACTAMENTE una vez (JAMAS repite)",
      puppets[0].stun_count == 1 and puppets[1].stun_count == 1
      and len(band) == 2 and len({id(p) for p in band}) == 2)
check("LSA cadena: sin enemigos restantes se lanza por los ANILLOS",
      len(collected) == 2 and all(r.used for r in rings))
check("LSA cadena: el vuelo termina solo (tope de frames lejano)",
      0 < frames < 500, f"{frames} frames")

# (h) INTERCEPCION EN FASE DE ANILLOS: C esta a 516 px del primer objetivo
# (fuera de LSA_NEXT_DIST: la cadena NO lo alcanza) pero a < 140 del tramo
# de anillos: SOLO la intercepcion puede golpearlo
puppets = [Puppet(100, 0), Puppet(600, -130)]
rings = [Ring(350, 0, 72, 1072), Ring(600, 0, 73, 1073)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, rings)
check("LSA intercepcion: el enemigo del camino de los ANILLOS cae (via desvio)",
      len(order) == 2 and order[0] is puppets[0] and order[1] is puppets[1]
      and point_distance(100, 0, 600, -130) > LSA_NEXT,
      f"orden={[p.character for p in order]}")
check("LSA intercepcion: ambos golpeados una sola vez y los anillos recogidos",
      puppets[0].stun_count == 1 and puppets[1].stun_count == 1
      and len(collected) == 2 and all(r.used for r in rings))

# (h2) el tope: con 8 enemigos la banda corta la cadena en 6 y termina en anillos
puppets = [Puppet(120 + i * 100, 0) for i in range(8)]
rings = [Ring(620 + 250, 0, 80, 1080)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, rings)
check(f"LSA tope: con 8 enemigos solo caen {int(LSA_MAX_TARGETS)} (la cadena termina)",
      len(order) == LSA_MAX_TARGETS
      and sum(p.stun_count for p in puppets) == LSA_MAX_TARGETS
      and puppets[7].stun_count == 0
      and len(collected) == 1,
      f"golpes={len(order)}, anillos={len(collected)}")

# (i) I-FRAMES: ni al arrancar, ni a mitad de vuelo
puppets = [Puppet(200, 0, hurt=True)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, [])
check("LSA i-frames: un exe con i-frames JAMAS es objetivo (ni arranca)",
      order == [] and frames == 0)


def grant_iframes(frame, puppets):
    if frame == 10:
        puppets[0].hurt = True


puppets = [Puppet(200, 0)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, [],
                                            on_frame=grant_iframes)
check("LSA i-frames: ganados a mitad de vuelo -> el golpe NO entra",
      order == [] and puppets[0].stun_count == 0)
check("LSA i-frames: ...pero el objetivo queda marcado (no se repite: termina)",
      puppets[0] in band and len(band) == 1 and frames < 300)

# (i2) sin objetivos del bando exe: la C en el aire no arranca nada
puppets = [Puppet(100, 0, "SONIC")]
rings = [Ring(50, 0, 81, 1081)]
frames, order, collected, band = lsa_flight(world, (0, 0), puppets, rings)
check("LSA vacio: sin objetivos del bando exe la C en el aire no arranca nada",
      frames == 0 and order == [] and collected == []
      and not rings[0].used)

# (f) la senal de stun: modelo Chocola (sonido ANTES del dedup)


def apply_lsa_stun(is_exe_side, shocked_before, hurttime_before=0):
    """Puerto de scr_lsa_stun_signal sobre el estado del receptor.
    Devuelve (sonidos, shockedTimer, yspd) o None si no es bando exe."""
    if not is_exe_side:
        return None
    sounds = 1  # golpe canonico SIEMPRE (antes del dedup)
    if shocked_before > 0:
        return (sounds, shocked_before, 0)
    return (sounds, LSA_STUN, -2)


check("LSA senal: exe limpio -> stun de 3 s + knockback",
      apply_lsa_stun(True, 0) == (1, 180, -2))
check("LSA senal: ya stuneado -> suena pero NO re-aplica (dedup)",
      apply_lsa_stun(True, 90) == (1, 90, 0))
check("LSA senal: un superviviente normal la ignora",
      apply_lsa_stun(False, 0) is None)

print()
print("-- v6.0: FIX PISO (el pozo de la burbuja de secuestro) --")


def stuck_pipeline(fix, frames=120):
    """Pipeline REAL del frame de Amy durante el dash (orden del Step):
    1. scr_move_basic -> hook: el vuelo calcula (to_x, to_y), cerrea
       xspd/yspd y corre scr_collision_basic (A): con isGrounded en true
       la rama de suelo hace y = winner (SNAP al piso).
    2. scr_light_dash_pose: y = to_y  (+ isGrounded = false con el fix).
    3. Step_0: scr_collision_basic (B) con la velocidad del pose: si
       isGrounded sigue en true, la rama de suelo vuelve a CLAVARLA al
       piso (y = winner) y la elevacion del vuelo se pierde.
    Modelo con un piso plano y un anillo ARRIBA: devuelve el frame en el
    que el VUELO alcanza el anillo, o None si nunca llega (clavada)."""
    floor_y = 400.0
    target_y = 300.0
    y = floor_y
    grounded = True  # aterrizo en el frame previo (el bug reportado)
    for f in range(1, frames + 1):
        to_y = max(y - SPEED, target_y)
        if to_y <= target_y:
            return f  # este frame el vuelo alcanza el anillo
        # --- collision A (dentro del hook) ---
        if grounded:
            y = floor_y  # rama de suelo: snap (aqui no duele, el pose manda)
        # --- pose ---
        y = to_y
        if fix:
            grounded = False  # v6.0: el seguro de la burbuja, cada frame
        # --- collision B (Step_0, ya con la velocidad del tramo) ---
        if grounded:
            y = floor_y  # rama de suelo: LA CLAVADURA
        else:
            y += -SPEED + 0.22  # yspd del tramo + gravedad (subiendo: no aterriza)
            if y > floor_y:
                y = floor_y
                grounded = True
    return None


bug_frames = stuck_pipeline(False)
fix_frames = stuck_pipeline(True)
check("FIX PISO reproduce el bug: sin el seguro el dash NUNCA sube (clavado)",
      bug_frames is None)
check("FIX PISO lo cura: con el seguro alcanza el anillo de arriba",
      fix_frames is not None and fix_frames <= 20,
      f"llega en {fix_frames} frames")

print()
print("-- v6.0: frenado de emergencia (X) + i-frames --")


def brake_scenario():
    st = {"flying": True, "xspd": SPEED, "yspd": -2.0, "gspd": SPEED,
          "hurttime": 0, "latch": 0, "boost": False, "exited": False}

    def flight_frame(press_x):
        if st["flying"]:
            if press_x:  # scr_light_dash_brake
                st["flying"] = False
                st["exited"] = True
                st["xspd"] = st["yspd"] = st["gspd"] = 0.0
                st["hurttime"] = IFRAME_EXIT
                st["latch"] = 2
                return False
            st["hurttime"] = max(st["hurttime"], 2)  # i-frames del vuelo
            st["hurttime"] -= 1  # el Step_0 baja 1
            return True
        return False

    def special_frame(press_x):  # scr_amy_canon_special (impulso de tarot)
        if st["latch"] > 0:
            st["latch"] -= 1
            return  # latch: la X del frenado no enciende el boost
        if press_x:
            st["boost"] = True

    frames = 0
    while flight_frame(frames == 20) and frames < 100:
        frames += 1
    # keyboard_check_pressed solo dispara UN frame: el del freno. En ese
    # MISMO frame specialFunc (impulso de tarot) ve la X oprimida — el
    # latch es lo unico que lo impide. Los frames siguientes ya no estan
    # "pressed" (tecla sostenida != pressed).
    special_frame(True)   # frame del freno: la X presionada de verdad
    special_frame(False)  # frame +1: latch consumiendose, sin pressed
    special_frame(False)  # frame +2: latch agotado, sin pressed
    return st, frames


st, frames = brake_scenario()
check("FRENADO: sale en el frame 20 con parada TOTAL (xspd=yspd=gspd=0)",
      frames == 20 and st["exited"] and st["xspd"] == 0
      and st["yspd"] == 0 and st["gspd"] == 0)
check("FRENADO: la salida del freno tambien deja los 2 s de i-frames",
      st["hurttime"] == IFRAME_EXIT)
check("FRENADO: el impulso de tarot NO se enciende con la X del freno (latch)",
      not st["boost"])


def flight_iframes(n_frames):
    hurttime = 0
    for _ in range(n_frames):
        hurttime = max(hurttime, 2)  # el vuelo repone
        hurttime -= 1                # el Step_0 baja
        if hurttime <= 0:
            return None  # hueco: seria dañable
    return hurttime


check("I-FRAMES: hurttime nunca cae a 0 durante el vuelo (intocable)",
      flight_iframes(200) == 1)
check("I-FRAMES: y al salir quedan los 120 frames (2 s)",
      flight_iframes(50) is not None and IFRAME_EXIT == 120)


print()
if fails:
    print(f"RESULTADO: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULTADO: TODO OK")
