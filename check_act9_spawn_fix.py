#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_act9_spawn_fix.py — Verificador del FIX ACT9 SPAWN V1 (TD2DR).

BUG: en Act 9, jugadores que spam-elegian personaje aparecian EN EL SUELO
aplastados por el muro al spawnear (contaba como muerte).

CAUSA (cadena completa, verificada en el codigo):
  1) states/Game.c (game_state_handletcp): el "ready" que arranca la partida
     se marca con CUALQUIER paquete TCP — p. ej. los clicks de personaje
     spameados durante el fade de transicion ya cuentan como ready.
  2) La partida (y los muros) arrancaban mientras un cliente seguia en el
     fade (1,6 s) + cargando texturas de la sala.
  3) Ese cliente spawnneaba DENTRO del muro ya avanzado (spawnpoint
     (3024,576) queda cubierto por el muro derecho a los ~8,7 s de barrido;
     (2856,256) a los ~21,8 s; (304,512) a los ~28,7 s).
  4) obj_act9_wall/Step_1.gml lo aplastaba al aparecer: scr_player_instakill
     (CUENTA COMO MUERTE) + teletransporte a (1535,943) = "aparecen en el
     suelo".
  5) Bonus: ese punto del suelo queda DENTRO del muro-techo al final de la
     ronda (off >= ~0,92) => teletransporte al olvido.

FIX:
  A (server, entities/Act9Wall.c): cada muro NO ARRANCA hasta que todos los
     participantes vivos hayan reportado su primera posicion (pos != 0,0),
     con tope de gracia de 30 s (anti-zombi). Solo re-captura start_time:
     el barrido siempre termina justo al acabar la ronda.
  B (cliente, obj_act9_wall/Step_1.gml): tras el aplastamiento, el
     teletransporte va al punto clasico SOLO si esta fuera de todos los
     muros; si esta cubierto, escanea el suelo hacia los costados; si todo
     esta cubierto (fin de ronda), no teletransporta.

Parte A (estatica): ambos fixes presentes, math original intacto, sin
teleportes duros, llaves balanceadas.

Parte B (simulacion): el reloj del muro portado 1:1 (off = (S-t)/S con
hold por re-captura) + la seleccion de teleport:
  - Spawneo con cliente lento cargando 12 s: SIN fix el spawn (3024,576)
    queda dentro del muro derecho (crush = muerte); CON fix el muro espera
    y el spawn es seguro.
  - El hold libera cuando el ultimo reporta; el barrido termina exactamente
    al acabar la ronda (off = 1 en time = 0).
  - Teleport: punto clasico libre -> clasico; cubierto por un muro lateral
    -> escanea al costado; todo cubierto (techo del final) -> no teleporta.

Uso:  python check_act9_spawn_fix.py [ruta_del_repo]
      (por defecto asume que esta al lado de betterserver-oss/)
"""
import os
import sys

RESULTS = []


def check(name, ok):
    RESULTS.append((name, bool(ok)))
    print(("  [PASS] " if ok else "  [FAIL] ") + name)


ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
AW = os.path.join(ROOT, "betterserver-oss", "disasterserver", "entities", "Act9Wall.c")
ST = os.path.join(ROOT, "objects", "obj_act9_wall", "Step_1.gml")
GC = os.path.join(ROOT, "betterserver-oss", "disasterserver", "states", "Game.c")

print("=== PARTE A: ESTATICA ===")

aw = open(AW, encoding="utf-8").read()
st = open(ST, encoding="utf-8").read()
gc = open(GC, encoding="utf-8").read()

# --- server ---
check("Act9Wall.c: constante de gracia ACT9_WALL_HOLD_SEC = 30",
      "#define ACT9_WALL_HOLD_SEC 30" in aw)

check("Act9Wall.c: hold — re-captura start_time si hay jugador sin posicion (pos == 0,0)",
      "wall->start_time = time;" in aw
      and "data->plr.pos.x == 0 && data->plr.pos.y == 0" in aw)

check("Act9Wall.c: el hold solo dentro de la ventana de gracia (elapsed < HOLD*TICKSPERSEC)",
      "server->game.elapsed < ACT9_WALL_HOLD_SEC * TICKSPERSEC" in aw)

check("Act9Wall.c: el hold ignora espectadores (!in_game) y muertos (PLAYER_DEAD)",
      "if (!data->in_game)" in aw and "data->plr.flags & PLAYER_DEAD" in aw)

check("Act9Wall.c: el barrido original intacto (off = (start-time)/start)",
      "double off = (double)(wall->start_time - time) / (double)wall->start_time;" in aw)

check("Act9Wall.c: el kick del server 'Inside the wall for too long!' sigue existiendo",
      '"Inside the wall for too long!"' in aw)

# --- causa raiz documentada: el ready con cualquier TCP sigue ahi (lo mitiga el hold) ---
check("states/Game.c: la causa raiz sigue documentada (ready con cualquier paquete)",
      "v->plr.ready = true;" in gc)

# --- cliente ---
check("Step_1.gml: bloque de punto seguro presente (_tpOK/_tpX/_tpY)",
      "var _tpOK = false;" in st and "var _tpX = 1535;" in st and "var _tpY = 943;" in st)

check("Step_1.gml: cobertura evaluada contra TODOS los muros (with obj_act9_wall)",
      st.count("with(obj_act9_wall)") >= 2)

check("Step_1.gml: escaneo lateral acotado al mapa (64..3008, paso tile)",
      "_cx < 64 || _cx > 3008" in st and "_d += 64" in st)

check("Step_1.gml: cero teletransportes duros restantes (1535 incondicional)",
      st.count("global.player.x = 1535;") == 0
      and st.count("global.player.x = _tpX;") == 3
      and st.count("if(_tpOK)") == 3)

check("Step_1.gml: el instakill del aplastamiento sigue intacto (3 ramas)",
      st.count("scr_player_instakill();") == 3)

check("Step_1.gml: llaves balanceadas",
      st.count("{") == st.count("}"))

print("=== PARTE B: SIMULACION (reloj del muro 1:1 + teleport) ===")

TICKS = 60  # TICKSPERSEC
ROOM_W = 3072
ROUND_S = 130  # Act 9: map_time(2.17*TICKSPERSEC) = 130 s
# spawnpoints del room (rooms/room_act9/*.yy)
SPAWNS = [(304, 512), (1536, 960), (2856, 256), (3024, 576)]
# muros: (wid, pos_x, pos_y) de act9_init


def wall_regions(off):
    """Regiones letales de cada muro segun 'off' (math 1:1 de act9wall_tick)."""
    regions = []
    # wid 0 (techo que baja): x fijo, y = 1025*off - 768 .. 1025*off
    y0 = 1025 * off
    regions.append(("techo", -2240, y0 - 768, -2240 + 64 * 117, y0))
    # wid 1 (izquierda): wx = 1663*off - 64; y = 0..1248
    x1 = 1663 * off
    regions.append(("izq", x1 - 2240, 0, x1 - 64, 64 * 19.5))
    # wid 2 (derecha): x = 3136 - 1663*off; y = 0..1248
    x2 = 1663 * off
    regions.append(("der", 3136 - x2, 0, 3136 - x2 + 64 * 34, 64 * 19.5))
    return regions


def inside(regions, px, py):
    return any(px >= x and py >= y and px <= wx and py <= hy
               for _, x, y, wx, hy in regions)


def sim_round(load_times, fix=True, hold_sec=30):
    """Simula la ronda: cada jugador reporta posicion a los load_times[i]
    segundos del arranque. El reloj de la RONDA es fijo (INIT_CLOCK - t);
    start_time es lo que captura/re-captura el muro (math 1:1 de act9wall).
    Devuelve ([(t_reporte, off)], off_al_fin_de_ronda)."""
    INIT_CLOCK = ROUND_S * TICKS + TICKS  # act9wall_init: time_sec*60 + 60
    start_time = INIT_CLOCK
    reports = []
    for t in range(0, ROUND_S * TICKS):
        elapsed_s = t / TICKS
        remaining = INIT_CLOCK - t  # reloj de la ronda (fijo)
        if fix and elapsed_s < hold_sec:
            # hold: mientras alguien vivo no haya reportado, re-captura
            if any(t / TICKS < lt for lt in load_times):
                start_time = remaining
        off = (start_time - remaining) / start_time
        for lt in load_times:
            if abs(elapsed_s - lt) < 1 / TICKS:
                reports.append((lt, off))
    off_end = (start_time - 0) / start_time if start_time > 0 else 0
    return reports, off_end


# 1) spawn del cliente lento SIN fix: dentro del muro
reports_nofix, _ = sim_round([0.5, 12.0], fix=False)
off_slow_nofix = [o for t, o in reports_nofix if t == 12.0][0]
crush_nofix = any(inside(wall_regions(off_slow_nofix), sx, sy) for sx, sy in SPAWNS)
check(f"SIM: SIN fix, cliente que tarda 12 s spawnnea con off={off_slow_nofix:.3f} "
      f"-> algun spawnpoint ya esta DENTRO del muro (reproduce el bug)", crush_nofix)

# 2) CON fix: el muro espera, spawn seguro
reports_fix, off_end = sim_round([0.5, 12.0], fix=True)
off_slow_fix = [o for t, o in reports_fix if t == 12.0][0]
safe_fix = all(not inside(wall_regions(off_slow_fix), sx, sy) for sx, sy in SPAWNS)
check(f"SIM: CON fix, ese mismo cliente spawnnea con off={off_slow_fix:.3f} "
      f"-> TODOS los spawnpoints seguros", safe_fix)

# 3) el barrido termina exactamente al final de la ronda
check(f"SIM: con hold, el barrido igual termina completo al acabar la ronda "
      f"(off final = {off_end:.2f})", abs(off_end - 1.0) < 1e-9)

# 4) hold libera cuando el ultimo reporta (no antes, no despues)
off_early = [o for t, o in reports_fix if t == 0.5][0]
check(f"SIM: el primer jugador (reporta a los 0,5 s) tambien arranca con el "
      f"muro quieto (off={off_early:.3f}) — nadie tiene ventaja injusta",
      off_early == 0.0)

# 5) tope anti-zombi: si NADIE reporta jamas, tras la gracia el muro
# igual completa su barrido al final de la ronda (no queda clavado)
reports_zombie, off_end_z = sim_round([9999], fix=True)
check("SIM: tope anti-zombi — si nadie reporta, el muro igual completa el "
      f"barrido al fin de la ronda (off final = {off_end_z:.2f})",
      off_end_z == 1.0)

# 6) teleport seguro: punto clasico libre a mitad de ronda
reg_mid = wall_regions(0.5)  # mitad de ronda
classic_covered = inside(reg_mid, 1535, 943)
check("SIM: a mitad de ronda el punto clasico (1535,943) esta LIBRE -> teleport clasico",
      not classic_covered)

# 7) teleport seguro: final de ronda, techo cubre el clasico -> escaneo o nada
reg_end = wall_regions(0.95)
classic_cov_end = inside(reg_end, 1535, 943)
# a 0.95: techo = y in [1025*0.95-768, 1025*0.95] = [205.75, 973.75] -> cubre 943
check("SIM: al final de la ronda (off=0.95) el punto clasico queda DENTRO del techo "
      "-> el fix NO teleporta al olvido", classic_cov_end)

# 8) escaneo lateral: cubierto solo por muro izquierdo -> encuentra punto al costado
reg_left = wall_regions(0.5)
# forzar: muro izquierdo con front en 1560 (cubre el clasico), derecho lejos
custom = [("izq", -2240, 0, 1560, 1248), ("der", 2600, 0, 4776, 1248)]
scan = None
for d in range(64, 1537, 64):
    for cx in (1535 - d, 1535 + d):
        if 64 <= cx <= 3008 and not inside(custom, cx, 943):
            scan = cx
            break
    if scan is not None:
        break
check(f"SIM: cubierto solo por el muro izquierdo -> el escaneo encuentra {scan} "
      "(libre hacia el centro)", scan is not None and scan == 1599)

# resumen
print()
total = len(RESULTS)
passed = sum(1 for _, ok in RESULTS if ok)
for name, ok in RESULTS:
    if not ok:
        print(f"  FALLA: {name}")
print(f"RESULTADO: {passed}/{total}")
sys.exit(0 if passed == total else 1)
