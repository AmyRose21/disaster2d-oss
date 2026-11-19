#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v30.py — Validador de la ronda v30 (MEJORA DE EFICACIA del
compilar_server.bat: compilar el server mas rapido en el uso diario).

  INEFICIENCIAS del .bat viejo (opcion 1, la de uso diario):
  re-configuraba cmake en CADA compilacion, compilaba SIN paralelo
  y siempre copiaba DLLs / restauraba configs / verificaba la GUI
  aunque no hubiera cambiado nada.
  MEJORAS v30 (mismo menu, mismas rutas, mismo exe de salida):
  1) configure solo la 1a vez o si cambia la CONFIG (stamp en
     build/.configure-stamp); un CMakeLists nuevo lo re-configura
     solo el propio cmake --build;
  2) --parallel -j con todos los nucleos en las DOS opciones;
  3) deteccion de "nada que recompilar" (ticks del exe antes y
     despues): si no cambio, no copia DLLs ni toca configs;
  4) temporizador por compilacion;
  5) auto-descarga de la carpeta enet si falta (submodulo).

  VERIFICACION REAL (en Linux, mismo flujo que maneja el .bat):
  11/11 — configure 816 ms; build paralelo completo; smoke test
  (BetterServer v1101, port 8606); sin cambios: 70 ms / 0 TUs y
  ticks identicos; tocar 1 .c: solo ese TU (927 ms) y ticks
  cambiados; serial 7.1 s vs paralelo 4.7 s (50% mejor con -j 2).
  Las 107 comprobaciones v29 (anticheat + tornado + v28 y demas)
  van dentro.

Uso:  python3 check_v30.py [ruta_del_proyecto]
"""
import os
import re
import sys

RESULTS = []


def check(name, cond):
    RESULTS.append((name, bool(cond)))
    print(f"  [{'OK' if cond else 'FAIL'}] {name}")


def read(p):
    with open(p, encoding='utf-8', errors='replace') as f:
        return f.read()


def strip_gml(src):
    out, i, n = [], 0, len(src)
    in_str = in_line = in_block = False
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if in_line:
            if c == '\n':
                in_line = False
                out.append(c)
        elif in_block:
            if c == '*' and nxt == '/':
                in_block = False
                i += 1
        elif in_str:
            if c == '\\':
                i += 1
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == '/' and nxt == '/':
                in_line = True
                i += 1
            elif c == '/' and nxt == '*':
                in_block = True
                i += 1
            else:
                out.append(c)
        i += 1
    return ''.join(out)


def balanced(src, fname):
    s = strip_gml(src)
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for ch in s:
        if ch in '([{':
            stack.append(ch)
        elif ch in ')]}':
            if not stack or stack[-1] != pairs[ch]:
                return False, f"{fname}: desbalance en '{ch}'"
            stack.pop()
    return not stack, f"{fname}: OK" if not stack else f"{fname}: pila {stack[:4]}"


# ============================================================================
# SIMULACION 1:1 compacta (transcripcion del comportamiento v24 fixeado;
# version verbosa: scripts/sim_rouge_v24.py)
# ============================================================================
import math

ATT_RECH = 60 * 20
TORNADO_TIME = int(60 * 3)
TORNADO_BRAKE = int(60 * 0.8)
TORNADO_START, TORNADO_MIN = 12, 1.5
SPD_BASE, SPD_REV, SPD_MAX, SPD_START_MAX = 8, 2, 10, 2
DRILL_DIVE, DRILL_DIVE_X = 12, 8
GLIDE_SPD, GLIDE_ACC, GLIDE_FALL = 6.25, 3, 0.7922
WALL_IF = 60 * 2
FLY_RECH = 60 * 15
ACC, MAXHS, MAXYS, YACC = 0.046875, 11, 12, 0.21875
IDLE, JUMP, FALL, SPIN = 0, 3, 4, 12
R_ATK, R_AIR_ATK, R_GLIDE_ST, R_STUCK, R_SPINDASH, R_SPIN_REL, R_GLIDE_AIR = 14, 15, 16, 18, 20, 21, 23
ANIMS = {14: 'attack1', 15: 'attack2', 16: 'fly', 20: 'charger', 21: 'release', 23: 'glide'}
FRAMES = {14: 2, 15: 2, 16: 4, 20: 23, 21: 18, 23: 5}


class Sim:
    def __init__(s, floor=300):
        s.floor = floor
        s.gspd = s.xspd = s.yspd = 0.0
        s.y = float(floor)
        s.x = 500.0
        s.grounded = True
        s.state = 0; s.sprite = 'idle'; s.img = 0.0; s.imgn = 2
        s.xscale = 1.0
        s.atkT = 0; s.flyT = 0; s.flyOut = 0
        s.fly = s.jmp = s.atk = False
        s.charging = False; s.charge = 0.0
        s.spin = False; s.rel = False
        s.tor = 0; s.dr = 0
        s.glide = False; s.gx = 0.0; s.glideT = 0
        s.stuck = False; s.sliding = False
        s.hurt = s.dead = False; s.shock = 0
        s.ht = 0; s.et = 0; s.ghosts = 0
        s.coyote = 0
        s.log = []

    def special(s, k):
        if (k['ctrl'] and s.grounded and not s.atk and not s.hurt and not s.dead
                and s.shock <= 0 and not s.fly and not s.sliding
                and k['down'] and abs(s.gspd) < SPD_START_MAX and not s.spin and k['zp']):
            s.charging = True
            s.charge = min(s.charge + SPD_REV, SPD_MAX)
        if s.charging:
            s.gspd = s.xspd = 0
            if not k['ctrl'] or not k['down'] or not s.grounded:
                if s.grounded:
                    c = s.charge
                    s.charging = False; s.spin = True; s.rel = True; s.jmp = False
                    s.gspd = (SPD_BASE + c) * s.xscale; s.charge = 0
                else:
                    s.charging = False; s.charge = 0
        if not s.spin and s.rel:
            s.rel = False
        # VUELO: Z + ARRIBA (v24)
        if (k['ctrl'] and k['zp'] and k['up'] and not s.grounded and not s.atk
                and not s.charging and not s.glide and s.coyote <= 0):
            if not s.fly and s.flyT <= 0:
                s.flyT = FLY_RECH; s.flyOut = 0
                s.fly = True; s.jmp = False; s.spin = False; s.rel = False
        # ATAQUE X
        if (k['ctrl'] and k['xp'] and s.atkT <= 0 and s.tor <= 0 and not s.sliding
                and not s.charging and not s.atk):
            if k['left']:
                s.xscale = -1
            elif k['right']:
                s.xscale = 1
            s.img = 0
            if s.glide:
                s.glide = False
                if s.stuck:
                    s.stuck = False
            s.spin = False; s.rel = False
            if s.grounded:
                s.tor = TORNADO_TIME; s.atk = True; s.fly = False; s.jmp = False
            else:
                s.atk = True; s.fly = False; s.jmp = False
                s.dr = 1  # v25: bandera (ilimitado)
                s.yspd = DRILL_DIVE; s.xspd = s.xscale * DRILL_DIVE_X; s.gspd = 0
        # taladro activo
        if s.dr > 0:
            if s.dead or s.shock > 0 or s.hurt:
                s.dr = 0; s.atk = False; s.atkT = ATT_RECH
            else:
                if s.yspd < DRILL_DIVE:
                    s.yspd = DRILL_DIVE
                if s.et <= 0:
                    s.et = 16
                # v25: ILIMITADO en el aire
        # tornado activo
        if s.tor > 0:
            if s.dead or s.shock > 0:
                s.tor = 1
            el = TORNADO_TIME - s.tor
            spd = TORNADO_START - (TORNADO_START - TORNADO_MIN) * min(el / TORNADO_BRAKE, 1)
            s.xspd = spd * s.xscale; s.gspd = s.xspd
            if s.et <= 0:
                s.et = 16
            s.tor -= 1
            if s.tor <= 0:
                s.atk = False; s.atkT = ATT_RECH
        # cambio de modo taladro -> tornado (FULL)
        if s.atk and s.grounded and s.tor <= 0 and not s.hurt and not s.dead and s.shock <= 0:
            s.dr = 0
            s.tor = TORNADO_TIME
            s.jmp = False
        elif s.atk and not s.grounded and s.tor <= 0 and s.dr <= 0:
            s.gspd = 0; s.xspd = s.xscale * 2
        if s.hurt:
            s.fly = False; s.glide = False; s.rel = False
        if s.fly:
            s.spin = False; s.jmp = False
            s.yspd = -3.5 if (k['ctrl'] and k['z']) else 1
            s.flyOut += 1
            if s.flyOut > 300:
                s.fly = False
            if s.grounded:
                s.fly = False
        # glide pasiva
        if (k['ctrl'] and not s.grounded and not s.glide and not s.fly and not s.atk
                and not s.hurt and not s.dead and s.shock <= 0 and not s.stuck
                and s.yspd > 0 and k['z']):
            s.glide = True; s.jmp = False; s.spin = False; s.rel = False
            s.gx = s.xscale * GLIDE_SPD
        if s.glide:
            s.glideT = 1
            if k['ctrl'] and k['z']:
                if not s.stuck:
                    if k['left'] and s.gx > -GLIDE_SPD:
                        s.gx -= ACC * GLIDE_ACC
                    elif k['right'] and s.gx < GLIDE_SPD:
                        s.gx += ACC * GLIDE_ACC
                    gi = math.floor(s.gx)
                    s.img = 0 if gi >= 2 else (1 if gi == 1 else (2 if gi == 0 else (3 if gi == -1 else 4)))
            else:
                s.glide = False
                if s.stuck:
                    s.stuck = False
            s.xscale = 1
            s.yspd = GLIDE_FALL - YACC       # la gravedad rellena hasta 0.7922
            s.xspd = s.gx
            if s.grounded:
                s.glide = False
                if s.stuck:
                    s.stuck = False
        if not s.fly and s.flyT > 0 and s.grounded:
            s.flyT -= 1
        if s.atkT > 0:
            s.atkT -= 1

    def move(s, k):
        if s.grounded:
            s.gspd -= min(abs(s.gspd), 0.09375) * (1 if s.gspd > 0 else -1) if s.gspd != 0 else 0
            s.xspd = s.gspd; s.yspd = 0
        s.special(k)
        if s.grounded:
            s.coyote = 10
        elif s.coyote > 0:
            s.coyote -= 1
        if not s.grounded and k['ctrl']:
            if k['left']:
                s.xscale = -1; s.xspd -= ACC * 2
            elif k['right']:
                s.xscale = 1; s.xspd += ACC * 2
        if k['ctrl'] and k['zp'] and not s.jmp and s.grounded and not s.atk and not s.charging:
            s.grounded = False; s.jmp = True; s.yspd = -6.5

    def collision(s, k):
        cap = 18 if s.spin else MAXHS
        s.xspd = max(-cap, min(cap, s.xspd))
        s.yspd = max(-MAXYS, min(MAXYS, s.yspd))
        s.x += s.xspd
        if s.grounded:
            s.yspd = 0
        else:
            s.yspd = min(s.yspd + YACC, MAXYS)
            s.y += s.yspd
            if s.y >= s.floor:
                s.y = s.floor; s.grounded = True; s.jmp = False
        if s.glide and s.glideT > 0 and k['wall'] and not s.stuck and not s.hurt:
            s.stuck = True
            s.ht = max(s.ht, WALL_IF)

    def step2(s):
        s.state = IDLE
        if s.dead or s.shock > 0:
            s.state = 6; return
        if s.charging:
            s.state = R_SPINDASH; return
        if s.spin and s.rel:
            s.state = R_SPIN_REL; return
        if s.sliding:
            s.state = 22; return
        if s.atk:
            s.state = R_AIR_ATK if s.grounded else R_ATK
            return
        if s.hurt:
            s.state = 5; return
        if s.stuck:
            s.state = R_STUCK; return
        if s.glide:
            s.state = R_GLIDE_AIR; return
        if s.fly:
            s.state = R_GLIDE_ST; return
        if s.spin:
            s.state = SPIN; return
        if not s.grounded:
            s.state = JUMP if s.jmp else FALL

    def draw(s):
        s.sprite = ANIMS.get(s.state, f'st{s.state}')
        s.imgn = FRAMES.get(s.state, 2)
        if s.state == R_ATK:
            if s.dr > 0:
                s.img = (s.img + 1) % 2  # v25: loop real
            else:
                if s.img >= s.imgn - 1 and s.dr <= 0:
                    s.atk = False; s.grounded = False
        elif s.state == R_AIR_ATK:
            if s.tor > 0 or s.dr > 0:
                s.img = (s.img + 0.5) % 2  # v25: loop real del remolino
            if s.tor <= 0 and s.dr <= 0:
                if s.img >= s.imgn - 1:
                    s.atk = False; s.grounded = False
        elif s.state == R_GLIDE_AIR:
            s.xscale = 1
        if s.et > 0:
            s.et -= 1
            if s.et % 3 == 0:
                s.ghosts += 1

    def frame(s, k):
        if s.shock <= 0:
            s.move(k)
        s.collision(k)
        s.step2()
        s.draw()
        if s.ht > 0:
            s.ht -= 1
        s.log.append((s.state, s.sprite, s.xscale, s.img, round(s.xspd, 2),
                      round(s.yspd, 3), s.tor, s.dr, s.atk, s.atkT, s.fly,
                      s.flyT, s.ht))


def K(ctrl=True, z=False, zp=False, xp=False, left=False, right=False,
      down=False, up=False, wall=False):
    return dict(ctrl=ctrl, z=z, zp=zp, xp=xp, left=left, right=right,
                down=down, up=up, wall=wall)


def mkseq(n, **bf):
    seq = []
    for f in range(n):
        k = dict(ctrl=True, z=False, zp=False, xp=False, left=False, right=False,
                 down=False, up=False, wall=False)
        for key, val in bf.items():
            k[key] = val(f) if callable(val) else (f in val)
        seq.append(K(**k))
    return seq


#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sim_rouge_v26.py — Simulador FIEL del pipeline real de obj_rouge para el bug
del video de la duena: "en tierra se ve unos milisegundos el attack2 y luego
correr". Modela el ORDEN REAL de eventos por frame:

    Step_0 (scr_move_basic):
        specialFunc()  ->  coyote  ->  In-Air steering  ->  salto
        ->  scr_collision_basic()  (gravedad DESPUES del special, clamps,
            aplica movimiento, setea isGrounded, frena contra muros)
    Step_2 (End Step): maquina de estados (prioridad exacta del archivo)
    Draw_76 (anim): cases 14/15 con sus guardas, image_speed, wraps y los
        cierres "defensivos" (incluido el veneno isGrounded = false)

Escenario H1 = el del video: taladro diagonal que aterriza PEGADO a un muro
de madera en su direccion de avance. FIXED=False reproduce el bug; FIXED=True
verifica el fix v26 (corte de pared solo si el remolino VIAJO).
"""
import math

# ---- macros ----
PT_TORNADO_TIME = int(60 * 3)
PT_TORNADO_BRAKE = int(60 * 0.8)
PT_TORNADO_START, PT_TORNADO_MIN = 12.0, 1.5
PT_WALL_TRAVEL = 6          # v26
PT_DRILL_DIVE, PT_DRILL_DIVE_X = 12.0, 8.0
PT_ATT_RECH = 20 * 60
PT_MAXH, PT_ACC, PT_YACC, PT_MAXY = 11.0, 0.046875, 0.21875, 16.0
GLIDE_SPD, GLIDE_ACC, GLIDE_FALL = 6.25, 3, 0.7922

# states
P_IDLE, P_WALK, P_RUN, P_SPIN = 0, 1, 2, 6
P_R_ATK, P_R_AIR_ATK = 14, 15
P_BALANCING = 13
AN = {14: 4, 15: 2, 0: 4, 1: 6, 2: 8, 6: 1}  # image_number por estado


#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sim_rouge_v27.py — Pipeline fiel del v26 + los TRES bugs nuevos (v27).

  S1 TRAMPOLIN (bug de la duena): el taladro cae sobre un trampolin
  (obj_spring_parent: dispara con yspd>0 + sensor + blanco; su case
  KNUX/ROUGE pone isAttacking=false + paga la recarga + lanza
  yspd=-16; cooldown 30f). SIN fix v27: el clamp de picada borra el
  impulso al frame siguiente, drillState NUNCA se limpia (el
  trampolin no lo toca y el cambio de modo exige isAttacking) ->
  slam + "empuje hacia abajo perpetuo" con fantasmas hasta re-usar
  la habilidad. CON fix v27: si sube, el taladro se corta limpio y
  el impulso del trampolin se respeta.
  S2 TORNADO AL AIRE (la "animacion muerta que seguia empujando"):
  el remolino se sale del suelo por un borde. SIN fix: isAttacking
  muere por el cierre defensivo del estado 14 pero el bloque sigue
  empujando (tornado FANTASMA). CON fix: corte limpio sin recarga.
  H1/H2/H3 (v26): muro al aterrizar (reproduce el video), muro en
  plena carrera, campo abierto — siguen pasando.
"""
import math

# ---- macros ----
PT_TORNADO_TIME = int(60 * 3)
PT_TORNADO_BRAKE = int(60 * 0.8)
PT_TORNADO_START, PT_TORNADO_MIN = 12.0, 1.5
PT_WALL_TRAVEL = 6            # v26
PT_DRILL_DIVE, DRILL_DIVE_X = 12.0, 8.0
PT_ATT_RECH = 20 * 60
PT_MAXH, PT_ACC, PT_YACC, PT_MAXY = 11.0, 0.046875, 0.21875, 16.0
PT_SPRING_UP = -16.0          # ydir del trampolin hacia arriba
PT_SPRING_CD = 30             # cooldown del trampolin (alarm[0])

# states
P_IDLE, P_WALK, P_RUN, P_SPIN = 0, 1, 2, 6
P_R_ATK, P_R_AIR_ATK = 14, 15
AN = {14: 4, 15: 2, 0: 4, 1: 6, 2: 8, 6: 1}  # image_number por estado


class PipeSim:
    def __init__(s, wall_x=None, floor_y=500.0, fixed26=True, fixed27=True,
                 spring=None, ledge_x=None, fixed28=True, slope=0.0,
                 wall_h=32.0, ceil_h=None):
        s.fixed26 = fixed26        # v26: corte de pared solo si viajo
        s.fixed27 = fixed27        # v27: trampolin + tornado aereo
        s.fixed28 = fixed28        # v28: sonda de PUNTO (no mascara)
        s.wall_x = wall_x
        s.floor_y = floor_y
        s.ledge_x = ledge_x        # el suelo solo existe hasta ledge_x
        s.spring = spring          # dict(x=..., top=...) o None
        s.slope_tan = math.tan(math.radians(slope))  # pendiente que SUBE hacia +x
        s.wall_h = wall_h          # altura del muro sobre la linea del suelo
        s.ceil_h = ceil_h          # techo del pasillo (None = cielo abierto)
        if spring:
            spring['cd'] = 0
        # estado
        s.x, s.y = 200.0, floor_y
        s.xspd = s.yspd = s.gspd = 0.0
        s.grounded = True
        s.isJumping = s.isSpinning = s.isAttacking = False
        s.isGliding = s.isFlying = s.isSliding = s.isHurt = s.isDead = False
        s.xscale = 1.0
        s.atkT = 0
        s.tor = 0; s.dr = 0; s.torX = 0.0
        s.et = 0; s.ghosts = 0; s.dust = 0; s.shakes = 0; s.bounces = 0
        s.state = P_IDLE; s.img = 0.0; s.imgspd = 1.0
        s.log = []

    def floor_top(s, fx):
        # linea del suelo en fx (plano o pendiente; nace a floor_y en x=200)
        return s.floor_y - (fx - 200.0) * s.slope_tan

    def probe_point_fire(s, px, py):
        # position_meeting(px, py, obj_floor_parent): ¿el punto cae dentro
        # de alguna geometria hija de floor_parent?
        if s.wall_x is not None and px >= s.wall_x \
           and py >= s.floor_top(s.wall_x) - s.wall_h:
            return True            # dentro del muro real (de su tope p'abajo)
        if s.ceil_h is not None and py <= s.floor_top(px) - s.ceil_h:
            return True            # dentro del techo del pasillo
        if s.slope_tan > 0 and s.floor_top(px) < py:
            return True            # la pendiente propia sobrepasa el punto
        return False

    # ================= scr_rouge_special =================
    def special(s, k):
        if s.atkT > 0:
            s.atkT -= 1
        # X (KeyB) recien pulsada
        if k['xp'] and s.atkT <= 0 and s.tor <= 0 and not s.isAttacking and not s.isSliding:
            if s.grounded:
                s.tor = PT_TORNADO_TIME; s.torX = s.x
                s.isAttacking = True; s.isJumping = False
                s.dust += 3
            else:
                s.isAttacking = True; s.isJumping = False
                s.dr = 1
                s.yspd = PT_DRILL_DIVE
                s.xspd = s.xscale * DRILL_DIVE_X
        # taladro activo (v25 ilimitado; v27 corte si sube)
        if s.dr > 0:
            if s.isDead or s.isHurt:
                s.dr = 0; s.isAttacking = False; s.atkT = PT_ATT_RECH
            elif s.fixed27 and s.yspd < 0:
                # v27: la lanzaron hacia arriba (trampolin) -> corte limpio
                s.dr = 0; s.isAttacking = False
            else:
                if s.yspd < PT_DRILL_DIVE:
                    s.yspd = PT_DRILL_DIVE
                if s.et <= 0:
                    s.et = 16
        # tornado activo
        if s.tor > 0:
            if s.isDead:
                s.tor = 1
            elif s.fixed27 and not s.grounded:
                # v27: ataque de suelo fuera del suelo -> corte limpio
                s.tor = 0; s.isAttacking = False
            if s.tor > 0:
                el = PT_TORNADO_TIME - s.tor
                spd = PT_TORNADO_START - (PT_TORNADO_START - PT_TORNADO_MIN) * min(el / PT_TORNADO_BRAKE, 1)
                s.xspd = spd * s.xscale
                s.gspd = s.xspd
                if s.et <= 0:
                    s.et = 16
                s.dust += 1
                dirx = 1.0 if s.xscale > 0 else -1.0
                ft = s.floor_top(s.x)
                if s.fixed28:
                    # v28: PUNTO a 18 px por delante/detras (1 px mas alla
                    # del borde de la mascara, +17) y a 28 px sobre la linea
                    # del suelo (y - 10 con el origen a suelo - 18)
                    fires = (s.probe_point_fire(s.x + 18 * dirx, ft - 28)
                             or s.probe_point_fire(s.x - 18 * dirx, ft - 28))
                else:
                    # PRE-FIX: place_meeting con la MASCARA. La de attack2
                    # cuelga 5 px BAJO la linea del suelo (bbox +23 contra
                    # snap -18): el propio suelo solapa -> "pared" en
                    # cualquier terreno en cuanto la puerta v26 deja pasar
                    fires = s.grounded
                gate = (abs(s.x - s.torX) > PT_WALL_TRAVEL) if s.fixed26 else True
                if fires and gate:
                    s.tor = 1
                    s.shakes += 1; s.dust += 4
                s.tor -= 1
                if s.tor <= 0:
                    s.isAttacking = False
                    s.atkT = PT_ATT_RECH
        # cambio de modo taladro -> tornado (exige isAttacking vivo)
        if s.isAttacking and s.grounded and s.tor <= 0:
            s.dr = 0
            s.tor = PT_TORNADO_TIME; s.torX = s.x
            s.dust += 3

    # ================= scr_collision_basic + objects =================
    def collision(s):
        cap = 18.0 if s.isSpinning else PT_MAXH
        s.xspd = max(-cap, min(cap, s.xspd))
        s.yspd = max(-PT_MAXY, min(PT_MAXY, s.yspd))
        if not s.grounded:
            s.yspd = min(s.yspd + PT_YACC, PT_MAXY)
        # eje X (muro bloquea en el borde REAL de la mascara de attack2:
        # +17 por la derecha, -21 por la izquierda)
        nx = s.x + s.xspd
        if s.wall_x is not None:
            if s.xspd > 0 and nx >= s.wall_x - 17:
                nx = s.x if s.wall_x - 17 <= s.x else s.wall_x - 17
            elif s.xspd < 0 and nx <= s.wall_x + 21:
                nx = s.x if s.wall_x + 21 >= s.x else s.wall_x + 21
        s.x = nx
        # eje Y: suelo solo hasta ledge_x
        has_floor = True
        if s.ledge_x is not None and s.x > s.ledge_x:
            has_floor = False
        if not s.grounded:
            s.y += s.yspd
            # trampolin (scr_collision_objects: sensor + yspd>0 + blanco)
            if s.spring and s.spring['cd'] <= 0 and s.yspd > 0 \
               and abs(s.x - s.spring['x']) <= 16 and s.y >= s.spring['top'] - 4 \
               and s.y <= s.spring['top'] + 20:
                # case KNUX/ROUGE del trampolin: cancela ataque + paga recarga
                if s.isAttacking:
                    s.atkT = PT_ATT_RECH
                    s.isAttacking = False
                s.yspd = PT_SPRING_UP
                s.grounded = False
                s.spring['cd'] = PT_SPRING_CD
                s.bounces += 1
            if has_floor and s.y >= s.floor_top(s.x):
                s.y = s.floor_top(s.x); s.grounded = True; s.isJumping = False
        else:
            if has_floor:
                s.y = s.floor_top(s.x)
            else:
                s.grounded = False  # se sale del suelo por el borde
        if s.spring:
            s.spring['cd'] = max(0, s.spring['cd'] - 1)

    # ================= Step_2: maquina de estados =================
    def statemachine(s):
        if s.isAttacking:
            s.state = P_R_AIR_ATK if s.grounded else P_R_ATK
            return
        if abs(s.xspd) > 0 and s.grounded:
            s.state = P_WALK if abs(s.xspd) < 8 else P_RUN
            return
        if not s.grounded:
            s.state = 200; return
        s.state = P_IDLE

    # ================= Draw_76 (anim) =================
    def anim(s):
        if s.state == P_R_ATK:
            if s.dr > 0:
                s.imgspd = 1.0
            else:
                s.imgspd = 1.5
                # v27: el cierre respeta tornadoState solo con el fix activo
                if s.img >= AN[14] - 1 and s.dr <= 0 and (not s.fixed27 or s.tor <= 0):
                    s.isAttacking = False
                    s.grounded = False
        elif s.state == P_R_AIR_ATK:
            if s.tor > 0 or s.dr > 0:
                s.imgspd = 0.5
            else:
                s.imgspd = 1.5
                if s.img >= AN[15] - 1:
                    s.isAttacking = False
                    s.grounded = False
        elif s.state == P_RUN:
            s.imgspd = 1.0
        else:
            s.imgspd = 1.0
        s.img += s.imgspd
        n = AN.get(s.state, 4)
        while s.img >= n:
            s.img -= n

    def frame(s, k):
        s.special(k)
        if not s.grounded:
            if k['left']:
                s.xscale = -1.0; s.xspd -= PT_ACC * 2
            elif k['right']:
                s.xscale = 1.0; s.xspd += PT_ACC * 2
        if k['zp'] and not s.isJumping and s.grounded and not s.isAttacking:
            s.grounded = False
            s.isJumping = True
            s.yspd = -16.0
        s.collision()
        s.statemachine()
        s.anim()
        if s.et > 0:
            s.et -= 1
            if s.et % 3 == 0:
                s.ghosts += 1
        s.log.append(dict(f=len(s.log), st=s.state, sp={14: 'attack1', 15: 'attack2'}.get(s.state, f'st{s.state}'),
                          x=round(s.x, 1), y=round(s.y, 1), xv=round(s.xspd, 2), yv=round(s.yspd, 2),
                          tor=s.tor, dr=s.dr, atk=s.isAttacking, atT=s.atkT, g=s.grounded))


def pmkseq(n, **bf):
    seq = []
    for f in range(n):
        k = dict(controls=True, z=False, zp=False, xp=False, left=False, right=False, down=False)
        for key, val in bf.items():
            k[key] = val(f) if callable(val) else (f in val)
        seq.append(k)
    return seq


R = []


def run(sim, seq):
    for k in seq:
        sim.frame(k)
    return sim


def sim_all():
    R = []
    # A: X en tierra -> attack2 3 s con perfil de frenado
    p = Sim()
    for k in mkseq(210, xp=lambda f: f == 10):
        p.frame(k)
    a = [l for l in p.log[10:189]]
    R.append(("SIM A: tornado attack2 179f visibles (3 s)",
              len(a) == 179 and all(l[1] == 'attack2' for l in a)))
    R.append(("SIM A: arranque al tope del motor (11)", abs(p.log[10][4] - 11) < 0.1))
    R.append(("SIM A: frenado intacto (minimo 1.5 a los 0.8 s)",
              abs(p.log[58][4] - 1.5) < 0.3 and abs(p.log[120][4] - 1.5) < 0.3))
    R.append(("SIM A: recarga al final", p.log[189][9] > 0))
    R.append(("SIM A: animacion en LOOP (frames 0 y 1)",
              {int(l[3]) for l in p.log[10:189]} == {0, 1}))
    # B: X durante rodada del spindash
    p = Sim()
    for k in mkseq(230, zp=lambda f: f in (5, 7), z=lambda f: f in (5, 7),
                   down=lambda f: f < 12, xp=lambda f: f == 20):
        p.frame(k)
    b = [l for l in p.log[20:199]]
    R.append(("SIM B: X en rodada = attack2 179f", len(b) == 179 and all(l[1] == 'attack2' for l in b)))
    # C: spindash 5 Z
    p = Sim()
    for k in mkseq(56, zp=lambda f: f in (5, 15, 25, 35, 45), z=lambda f: f in (5, 15, 25, 35, 45),
                   down=lambda f: f < 50):
        p.frame(k)
    R.append(("SIM C: carga 10 + salida 18", p.log[48][0] == R_SPINDASH
              and abs(max(abs(l[4]) for l in p.log[50:53]) - 18) < 0.5))
    # D: glide + inversion agil
    p = Sim()
    for k in mkseq(220, zp=lambda f: f == 10, z=lambda f: f >= 12,
                   left=lambda f: 12 <= f < 60, right=lambda f: f >= 60):
        p.frame(k)
    g = [l for l in p.log if l[0] == R_GLIDE_AIR]
    gl = [l for l in g if l[4] < -6.2]  # fase de plena izquierda (antes de invertir)
    R.append(("SIM D: glide frame 4 sin espejo, cae 0.7922, va 6.25",
              len(gl) > 5 and all(l[2] == 1 and l[3] == 4 for l in gl)
              and all(abs(l[5] - 0.7922) < 0.02 for l in g)
              and all(6.2 <= abs(l[4]) <= 6.4 for l in gl)))
    first_right = next(i for i in range(60, len(p.log)) if p.log[i][4] >= 6.2)
    R.append((f"SIM D: inversion -6.25 -> +6.25 en {first_right - 60}f (< 95; Knux ~107)",
              first_right - 60 < 95))
    # E: taladro diagonal
    p = Sim()
    for k in mkseq(70, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 12):
        p.frame(k)
    R.append(("SIM E: picada 12 + DIAGONAL 8 + attack1 + sin recarga + fantasmas",
              p.log[12][0] == R_ATK and p.log[12][5] >= 11.9
              and abs(p.log[12][4] - 8) < 0.1 and p.log[13][1] == 'attack1'
              and p.log[13][9] == 0 and p.ghosts >= 8))
    # E2: taladro aterriza -> tornado 3 s FULL
    p = Sim()
    for k in mkseq(230, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 8):
        p.frame(k)
    ft = next(i for i, l in enumerate(p.log) if l[6] > 0)
    end = next(i for i in range(ft, len(p.log)) if p.log[i][9] > 0)
    t = [l for l in p.log[ft:end]]
    R.append(("SIM E2: aterrizar = tornado FULL 3 s attack2 + 1 recarga al final",
              p.log[ft][6] >= 178 and p.log[ft][7] == 0
              and len(t) >= 178 and all(l[1] == 'attack2' for l in t)
              and p.log[end][9] > 0 and all(l[9] == 0 for l in p.log[8:end])))
    # E3: taladro ILIMITADO
    p = Sim(floor=99999)
    p.y = 300.0
    for k in mkseq(300, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 8):
        p.frame(k)
    R.append(("SIM E3: ILIMITADO — a los 300 frames sigue taladrando sin recarga",
              p.log[299][8] is True and p.log[299][9] == 0 and p.log[299][5] >= 11.9))
    # F: vuelo Z+Up
    p = Sim()
    for k in mkseq(80, zp=lambda f: f == 10, z=lambda f: f == 10):
        p.frame(k)
    R.append(("SIM F: Z sola en el aire no gasta el vuelo",
              p.log[70][10] is False and p.log[70][11] == 0))
    p = Sim()
    for k in mkseq(80, zp=lambda f: f in (10, 30), z=lambda f: f in (10, 30), up=lambda f: f == 30):
        p.frame(k)
    R.append(("SIM F2: Z + ARRIBA activa el vuelo", p.log[31][10] is True))
    # G: pared -> i-frames 2 s una vez
    p = Sim()
    for k in mkseq(70, zp=lambda f: f == 5, z=lambda f: f == 5 or f >= 15,
                   left=lambda f: f >= 15, wall=lambda f: f >= 30):
        p.frame(k)
    fs = next((i for i, l in enumerate(p.log) if l[0] == R_STUCK), None)
    R.append(("SIM G: agarre de pared = 120 de i-frames (una vez)",
              fs is not None and p.log[fs][12] >= 119 and p.log[fs + 25][12] <= 95))

    # ---- v27: pipeline FIEL (special -> salto -> collision -> estados -> anim) ----
    # S1: trampolin — el taladro cae sobre el (bug #2 de la duena)
    for fixed27, tag in ((False, 'PRE-FIX (bug del trampolin)'), (True, 'FIX v27')):
        p = PipeSim(spring=dict(x=282.0, top=430.0), floor_y=500.0, fixed27=fixed27)
        for k in pmkseq(220, zp=lambda f: f == 5, xp=lambda f: f == 18, right=lambda f: 18 <= f < 44):
            p.frame(k)
        fb = next((i for i, l in enumerate(p.log) if l['yv'] < 0 and i > 18), None)
        last = p.log[-1]
        min_y = min(l['y'] for l in p.log[fb:]) if fb else None
        rising = sum(1 for l in p.log[fb:] if l['yv'] < 0) if fb else 0
        ghosts = sum(1 for l in p.log if l['dr'] > 0 and not l['atk'])
        if not fixed27:
            R.append((f"PIPE S1 {tag}: reproducido — el clamp borra el rebote y drillState queda ATASCADO",
                      fb is not None and rising <= 2 and last['dr'] == 1 and not last['atk'] and ghosts > 30))
        else:
            R.append((f"PIPE S1 {tag}: el impulso se respeta (sube >=100 px), taladro cortado, aterrizaje limpio",
                      fb is not None and rising >= 40 and min_y <= 330 and last['dr'] == 0
                      and not last['atk'] and ghosts <= 1 and p.bounces == 1 and last['g'] is True))
    # S2: el tornado se sale por un borde (bug #1 de la duena)
    for fixed27, tag in ((False, 'PRE-FIX (la animacion muerta)'), (True, 'FIX v27')):
        p = PipeSim(ledge_x=520.0, floor_y=500.0, fixed27=fixed27)
        for k in pmkseq(140, xp=lambda f: f == 10):
            p.frame(k)
        fl = next(i for i, l in enumerate(p.log) if not l['g'] and i > 12)
        ghost = [l for l in p.log if l['tor'] > 0 and not l['atk']]
        if not fixed27:
            R.append((f"PIPE S2 {tag}: reproducido — tornado FANTASMA empujando >20 frames con la animacion muerta",
                      len(ghost) > 20))
        else:
            R.append((f"PIPE S2 {tag}: corte limpio al despegarse (0 frames fantasma, sin recarga)",
                      len(ghost) == 0 and not p.log[fl + 2]['atk'] and p.log[fl + 2]['tor'] == 0))
    # ---- v28: el suelo NO es una pared (geometria real mascara + snap) ----
    # S3: suelo PLANO — sin fix, la mascara de attack2 (5 px DENTRO del
    # suelo) hace que el place_meeting vea "pared" en cuanto pasa la puerta
    for fixed28, tag in ((False, 'PRE-FIX (el suelo ES la pared)'), (True, 'FIX v28')):
        p = PipeSim(floor_y=500.0, fixed28=fixed28)
        for k in pmkseq(200, xp=lambda f: f == 10):
            p.frame(k)
        a2 = [l for l in p.log if l['sp'] == 'attack2']
        if not fixed28:
            R.append((f"PIPE S3 {tag}: reproducido — muere al 2o frame de moverse sobre suelo plano",
                      p.shakes == 1 and len(a2) <= 3))
        else:
            R.append((f"PIPE S3 {tag}: plano = 3 s de attack2, cero cortes",
                      len(a2) >= 179 and p.shakes == 0))
    # S4: cuesta de 45 (obj_ghz_slope -> jumptrough -> floor_parent)
    for fixed28, tag in ((False, 'PRE-FIX'), (True, 'FIX v28')):
        p = PipeSim(floor_y=500.0, slope=45.0, fixed28=fixed28)
        for k in pmkseq(200, xp=lambda f: f == 10):
            p.frame(k)
        a2 = [l for l in p.log if l['sp'] == 'attack2']
        if not fixed28:
            R.append((f"PIPE S4 {tag}: reproducido — la pendiente ES una pared para la mascara",
                      p.shakes == 1 and len(a2) <= 3))
        else:
            R.append((f"PIPE S4 {tag}: sube la cuesta de 45 ENTERA (el punto viaja 28 px sobre la linea)",
                      len(a2) >= 179 and p.shakes == 0 and p.log[189]['y'] <= 100.0))
    # S5: pasillo de 3 tiles — el techo (a 48 px) queda 20 px por encima del punto
    p = PipeSim(floor_y=500.0, ceil_h=48.0)
    for k in pmkseq(200, xp=lambda f: f == 10):
        p.frame(k)
    a5 = [l for l in p.log if l['sp'] == 'attack2']
    R.append(("PIPE S5: pasillo de 3 tiles = 3 s completos (el techo no toca el punto)",
              len(a5) >= 179 and p.shakes == 0))
    # S6: muro real de 2 tiles en plena carrera — el punto (+18) toca EXACTO
    # cuando el borde de su mascara (+17) llega a la cara (x = cara - 17)
    p = PipeSim(wall_x=500.0, wall_h=32.0)
    for k in pmkseq(200, xp=lambda f: f == 10):
        p.frame(k)
    mxa = max(l['x'] for l in p.log)
    R.append(("PIPE S6: muro de 2 tiles corta EXACTO al contacto (para en 483 = cara - 17)",
              p.shakes == 1 and abs(mxa - 483.0) <= 0.01 and not p.log[-1]['atk']))

    # H1/H2/H3 (v26) con los fixes nuevos puestos
    p = PipeSim(wall_x=244.0, floor_y=500.0)
    for k in pmkseq(260, zp=lambda f: f == 5, xp=lambda f: f == 18, right=lambda f: 18 <= f < 40):
        p.frame(k)
    fl = next(i for i, l in enumerate(p.log) if l['g'] and i > 18)
    a2 = [l for l in p.log[fl:] if l['sp'] == 'attack2']
    endf = next(i for i in range(fl, len(p.log)) if p.log[i]['atT'] > 0)
    R.append(("PIPE H1: taladro aterriza pegado al muro -> gira en el sitio los 3 s (v26 intacto)",
              len(a2) >= 178 and p.shakes == 0 and endf - fl >= 178))
    p = PipeSim(wall_x=350.0, floor_y=500.0)
    for k in pmkseq(120, xp=lambda f: f == 10, right=lambda f: f < 10):
        p.frame(k)
    R.append(("PIPE H2: pared en plena carrera sigue cortando (patron Metal intacto)",
              p.shakes >= 1 and not p.log[-1]['atk'] and any(l['x'] >= 320 for l in p.log)))
    p = PipeSim(wall_x=None, floor_y=500.0)
    for k in pmkseq(200, xp=lambda f: f == 10):
        p.frame(k)
    a3 = [l for l in p.log[10:189] if l['sp'] == 'attack2']
    R.append(("PIPE H3: sin muro el tornado dura los 3 s (179 frames attack2)", len(a3) == 179))

    # ---- v29: acumulador del anticheat del server (transcripcion del C) ----
    # if(is_attacking) attack_timer += elapsed; if(attack_timer >= duration)
    #     kick "nuh-uh!";  else attack_timer = 0  (reset al soltar el bit)
    def anti_run(segments, duration, dt=50.0):
        timer, t, kick_t = 0.0, 0.0, None
        for on, off in segments:
            for _ in range(int(on / dt)):
                timer += dt
                t += dt
                if timer >= duration:
                    kick_t = t
                    break
            if kick_t is not None:
                break
            timer = 0.0            # bit OFF: el acumulador se resetea
            t += off
        return kick_t

    # K1: el tornado de Rouge (bit ON 3000 ms) contra el tope VIEJO de 2000
    R.append(("SIM K1 PRE-FIX: el remolino (3000 ms ON) bota con 'nuh-uh!' a los ~2000 ms",
              1950 <= (anti_run([(3000, 0)], 2000) or -1) <= 2100))
    # K2: con la excepcion (8000), el tornado completo pasa
    R.append(("SIM K2 FIX v29: tornado completo (3000 ms) SIN kick con el techo de Rouge (8000)",
              anti_run([(3000, 0)], 8000) is None))
    # K3: la cadena 2-en-1: taladro hasta 3 s + tornado 3 s = 6000 ms continuos
    R.append(("SIM K3: cadena 2-en-1 (taladro 3000 + tornado 3000 = 6000 ms ON) SIN kick",
              anti_run([(6000, 0)], 8000) is None))
    # K4: el anticheat sigue VIVO: un bit fijo de 8500 ms (cheat) recibe el kick
    R.append(("SIM K4: anticheat VIVO — bit fijo de 8500 ms = kick a los ~8000 ms (techo subido, no apagado)",
              7950 <= (anti_run([(8500, 0)], 8000) or -1) <= 8150))
    # K5: regresion LSA de Amy (vuelo maximo 5000 ms, techo 6000)
    R.append(("SIM K5: LSA de Amy Canon intacto (5000 ms ON vs techo 6000) SIN kick",
              anti_run([(5000, 0)], 6000) is None))
    # K6: el reset: tornado cortado por pared a mitad + otro tornado despues
    R.append(("SIM K6: corte por pared (1500 ms ON) resetea el acumulador -> otro tornado pasa limpio",
              anti_run([(1500, 500), (3000, 0)], 8000) is None))
    # K7: tope generico intacto para el resto de personajes (2100 ms ON = kick)
    R.append(("SIM K7: tope generico 2000 intacto — 2100 ms ON de otro personaje = kick",
              1950 <= (anti_run([(2100, 0)], 2000) or -1) <= 2150))
    return R


# ============================================================================
# checks estaticos
# ============================================================================
def main():
    base = sys.argv[1] if len(sys.argv) > 1 else None
    if base is None:
        cands = [os.path.dirname(os.path.abspath(__file__)), 'repo',
                 os.path.join(os.path.dirname(os.path.abspath(__file__)), 'repo')]
        base = next((c for c in cands
                     if os.path.exists(os.path.join(c, 'objects', 'obj_rouge', 'Create_0.gml'))), cands[0])
    P = lambda *a: os.path.join(base, *a)
    print(f"Proyecto: {os.path.abspath(base)}\n")

    spec = read(P('scripts', 'scr_rouge_special', 'scr_rouge_special.gml'))
    create = read(P('objects', 'obj_rouge', 'Create_0.gml'))
    draw76 = read(P('objects', 'obj_rouge', 'Draw_76.gml'))
    draw64 = read(P('objects', 'obj_rouge', 'Draw_64.gml'))
    coll = read(P('scripts', 'scr_collision_basic', 'scr_collision_basic.gml'))
    pup = read(P('objects', 'obj_player_puppet', 'Step_0.gml'))
    nsg = read(P('scripts', 'net_state_game', 'net_state_game.gml'))
    spawn = read(P('objects', 'obj_spawnpoint', 'Create_0.gml'))
    surv = read(P('scripts', 'scr_survivors', 'scr_survivors.gml'))

    print("== (1) GLIDE con giro AGIL (v25) ==")
    check("macro ROUGE_GLIDE_ACC 3 (invierte ~89f vs ~107 de Knux)",
          re.search(r'#macro ROUGE_GLIDE_ACC 3\b', create) is not None)
    check("macro ROUGE_GLIDE_SPD 6.25 y ROUGE_GLIDE_FALL 0.7922 intactos (v24)",
          re.search(r'#macro ROUGE_GLIDE_SPD 6\.25', create) is not None
          and re.search(r'#macro ROUGE_GLIDE_FALL 0\.7922', create) is not None)
    check("special: caida ROUGE_GLIDE_FALL - yAccel (v24)", 'yspd = ROUGE_GLIDE_FALL - yAccel' in spec)
    check("mapeo de frames por RANGOS (v24)", 'var _gi = floor(glide_xspd)' in spec and '_gi >= 2' in spec)

    print("\n== (2) TORNADO 3 s + LOOP de animacion (v25) ==")
    check("macro ROUGE_TORNADO_TIME (60 * 3) — la de tierra dura 3 s",
          re.search(r'#macro ROUGE_TORNADO_TIME \(60 \* 3\)', create) is not None)
    check("macro ROUGE_TORNADO_BRAKE (60 * 0.8) — frenado original aparte",
          re.search(r'#macro ROUGE_TORNADO_BRAKE \(60 \* 0\.8\)', create) is not None)
    check("el frenado usa BRAKE (no estira el dash a los 3 s)",
          'min(_elapsed / ROUGE_TORNADO_BRAKE, 1)' in spec
          and 'min(_elapsed / ROUGE_TORNADO_TIME, 1)' not in spec)
    c15 = re.search(r'case ROUGE_AIR_ATTACK:(.*?)// v13: estado de VUELO', draw76, re.S)
    check("Draw_76 tornado: image_speed 0.5 (LOOP REAL — 2.0 clava el frame 0)",
          bool(c15) and re.search(r'image_speed = 0\.5;', c15.group(1)) is not None
          and re.search(r'image_speed = 2;', c15.group(1)) is None)
    check("Draw_76 tornado: drillState mantiene el giro en el aterrizaje (v24)",
          bool(c15) and 'drillState > 0' in c15.group(1))
    c14 = re.search(r'case ROUGE_ATTACK:(.*?)case ROUGE_AIR_ATTACK:', draw76, re.S)
    check("Draw_76 taladro: image_speed 1 (loop) + cierre seguro (v24)",
          bool(c14) and re.search(r'image_speed = 1;', c14.group(1)) is not None
          and 'drillState <= 0' in c14.group(1))

    print("\n== (2b) FIX v26: wall-cut solo si el remolino VIAJO ==")
    check("macro ROUGE_TORNADO_WALL_TRAVEL 6 (px de viaje minimo)",
          re.search(r'#macro ROUGE_TORNADO_WALL_TRAVEL 6\b', create) is not None)
    check("tornadoStartX declarado en el Create",
          re.search(r'^tornadoStartX = 0;', create, re.M) is not None)
    starts = re.findall(r'tornadoState = ROUGE_TORNADO_TIME;\s*\n\s*tornadoStartX = x;', spec)
    check("AMBOS arranques del tornado registran su origen (X en tierra + aterrizaje del taladro)",
          len(starts) == 2)
    check("el corte de pared lleva la puerta abs(x - tornadoStartX) > ROUGE_TORNADO_WALL_TRAVEL",
          '&& abs(x - tornadoStartX) > ROUGE_TORNADO_WALL_TRAVEL' in spec)
    check("v28: sonda de PUNTO 18 px por delante y por detras, a y - 10 (mascara +17 / snap -18)",
          'position_meeting(x + 18 * image_xscale, y - 10, obj_floor_parent)' in spec
          and 'position_meeting(x - 18 * image_xscale, y - 10, obj_floor_parent)' in spec)

    print("\n== (2c) FIX v27: trampolin + tornado aereo + anims debilitada ==")
    m = re.search(r'player_eanims\[\? CHARACTER_ROUGE\]\s*=\s*\[(.*?)\];', surv, re.S)
    eanims = m.group(1) if m else ''
    check("eanims Rouge: slot 14 = spr_erouge_attack1 (picada aerea) — estaba INVERTIDO",
          re.search(r'spr_erouge_attack1,\s*//14', eanims) is not None)
    check("eanims Rouge: slot 15 = spr_erouge_attack2 (tornado en tierra)",
          re.search(r'spr_erouge_attack2,\s*//15', eanims) is not None)
    mn = re.search(r'player_negaanims\[\? CHARACTER_ROUGE\]\s*=\s*\[(.*?)\];', surv, re.S)
    neg = mn.group(1) if mn else ''
    check("negaanims Rouge intacta (14=attack1, 15=attack2)",
          re.search(r'spr_rougenega_attack1,\s*//14', neg) is not None
          and re.search(r'spr_rougenega_attack2,\s*//15', neg) is not None)
    man = re.search(r'player_anims\[\? CHARACTER_ROUGE\]\s*=\s*\[(.*?)\];', surv, re.S)
    main = man.group(1) if man else ''
    check("anims principal Rouge intacta (14=attack1, 15=attack2)",
          re.search(r'spr_rouge_attack1,\s*//14', main) is not None
          and re.search(r'spr_rouge_attack2,\s*//15', main) is not None)
    check("taladro: corte limpio al subir (else if(yspd < 0) -> drillState=0, sin recarga)",
          re.search(r'else if\(yspd < 0\)\s*\{[^}]*?drillState = 0;\s*\n\s*isAttacking = false;\s*\n\s*\}', spec, re.S) is not None)
    check("tornado: corte limpio al salir del suelo (else if(!isGrounded) -> tornadoState=0, sin recarga)",
          re.search(r'else if\(!isGrounded\)\s*\{[^}]*?tornadoState = 0;\s*\n\s*isAttacking = false;\s*\n\s*\}', spec, re.S) is not None)
    check("tornado: el movimiento queda guardado tras los cortes (2 apariciones de if(tornadoState > 0))",
          len(re.findall(r'if\(tornadoState > 0\)', spec)) == 2)
    check("Draw_76 estado 14: el cierre defensivo respeta tambien tornadoState",
          'drillState <= 0 && tornadoState <= 0' in draw76)

    print("\n== (2d) FIX v28: el suelo ya no cuenta como pared ==")
    spr = read(P('sprites', 'spr_rouge_attack2', 'spr_rouge_attack2.yy'))
    bb = re.search(r'"bbox_bottom":\s*(\d+)', spr)
    yo = re.search(r'"yorigin":\s*(\d+)', spr)
    check("RAIZ: la mascara de attack2 cuelga a +23 (bbox_bottom 50 - yorigin 27) = 5 px DENTRO del suelo (snap a -18)",
          bool(bb) and bool(yo) and int(bb.group(1)) - int(yo.group(1)) == 23)
    check("v28: cero place_meeting en el CODIGO de scr_rouge_special (solo queda nombrado en el comentario historico)",
          'place_meeting' not in strip_gml(spec))
    check("v28: el punto va a y - 10 en AMBAS direcciones (28 px sobre la linea del suelo)",
          spec.count('y - 10, obj_floor_parent)') == 2)
    gslope = read(P('objects', 'obj_ghz_slope', 'obj_ghz_slope.yy'))
    jtr = read(P('objects', 'obj_platform_jumptrough', 'obj_platform_jumptrough.yy'))
    check("v28: las pendientes del juego SON objetivo del probe (ghz_slope -> jumptrough -> floor_parent)",
          '"name":"obj_platform_jumptrough"' in gslope
          and '"name":"obj_floor_parent"' in jtr)
    check("v28: comentario de la raiz documentado en el bloque del corte",
          'v28 (raiz del "tornado no funciona")' in spec)

    print("\n== (2e) FIX v29: excepcion anti-kick del anticheat (server) ==")
    srv = read(P('betterserver-oss', 'disasterserver', 'states', 'Game.c'))
    check("v29: case CH_ROUGE con duration = 8000 en el switch del anticheat (states/Game.c, el UNICO Game.c que compila)",
          re.search(r'case CH_ROUGE:\s*\{\s*duration = 8000;\s*break;\s*\}', srv, re.S) is not None)
    check("v29: excepciones previas intactas — Eggman 3000, LSA de Amy Canon 6000, Jinna 6000",
          'duration = 3000;' in srv and srv.count('duration = 6000;') == 2)
    check("v29: tope generico de 2000 ms intacto (el anticheat NO se apaga, solo se sube el techo)",
          'int duration = 2000;' in srv)
    check("v29: el kick sigue ahi (server_disconnect DR_KICKEDBYHOST 'nuh-uh!')",
          '"nuh-uh!"' in srv)
    check("v29: la excepcion SOLO en states/Game.c (el Game.c de la raiz esta MUERTO: el CMake no lo compila; su case CH_ROUGE es el viejo tope de HP)",
          'duration = 8000' not in read(P('betterserver-oss', 'disasterserver', 'Game.c')))
    check("v29: el acumulador y su reset intactos (attack_timer >= duration -> kick; bit OFF -> attack_timer = 0)",
          'v->plr.attack_timer >= duration' in srv and 'v->plr.attack_timer = 0;' in srv)
    nclient = read(P('objects', 'obj_netclient', 'Step_2.gml'))
    check("v29: el cliente manda el bit (PLAYER_ATTACKING en obj_netclient/Step_2, 2 ramas)",
          nclient.count('bitflags |= PLAYER_ATTACKING') == 2)
    check("v29: comentario del porque documentado junto al case (mismo mecanismo que el LSA)",
          'Rouge (remolino v24-28)' in srv)

    print("\n== (2f) MEJORA v30: compilar_server.bat eficaz ==")
    bat = read(P('betterserver-oss', 'compilar_server.bat'))
    bat_b = open(P('betterserver-oss', 'compilar_server.bat'), 'rb').read()
    fast = bat[bat.index(':build_fast'):bat.index(':build_full')]
    full = bat[bat.index(':build_full'):bat.index(':dll_menu')]
    check("v30: configure con stamp — subrutina :need_configure + sello .configure-stamp + salto",
          ':need_configure' in bat and '.configure-stamp' in bat and 'NEEDCFG' in bat and 'salto el paso de cmake -B' in fast)
    check("v30: en build_fast el cmake -B SOLO dentro del bloque NEEDCFG==1 (orden: need_configure < cmake -B < cmake --build)",
          0 < fast.index('call :need_configure') < fast.index('cmake -B') < fast.index('cmake --build'))
    check("v30: compilacion PARALELA en ambas opciones (--parallel %NUMBER_OF_PROCESSORS% x2)",
          bat.count('--parallel %NUMBER_OF_PROCESSORS%') == 2 and '--parallel' in fast and '--parallel' in full)
    check("v30: fallback si NUMBER_OF_PROCESSORS no existe",
          'if not defined NUMBER_OF_PROCESSORS' in bat)
    check("v30: rmdir del build SOLO en la opcion 2 (Limpiar TODO); la 1 es incremental",
          bat.count('rmdir /s /q "%BUILDDIR%"') == 1 and 'rmdir' not in fast)
    check("v30: deteccion de 'nada que recompilar' por ticks del exe (:exe_ticks + LastWriteTimeUtc.Ticks)",
          ':exe_ticks' in bat and 'LastWriteTimeUtc.Ticks' in bat and 'Nada que recompilar' in fast)
    check("v30: orden de ticks en build_fast (antes < cmake --build < despues < comparacion < mensaje)",
          fast.index('call :exe_ticks EXE_T0') < fast.index('cmake --build')
          and fast.index('cmake --build') < fast.index('call :exe_ticks EXE_T1')
          and fast.index('call :exe_ticks EXE_T1') < fast.index('if "%EXE_T0%"=="%EXE_T1%"'))
    check("v30: sin cambios NO se copian DLLs ni se toca nada (copy_dlls despues de la comparacion de ticks)",
          fast.index('if "%EXE_T0%"=="%EXE_T1%"') < fast.index('call :copy_dlls'))
    check("v30: temporizador por compilacion (ToUnixTimeMilliseconds al inicio y al final)",
          bat.count('ToUnixTimeMilliseconds()') >= 3 and 'Tiempo: {0:n1} s' in fast)
    check("v30: auto-descarga de enet si falta (:check_enet + clone + :enet_missing)",
          ':check_enet' in bat and 'git clone --depth 1 https://github.com/lsalzman/enet' in bat
          and ':enet_missing' in bat and bat.count('call :check_enet') == 2)
    check("v30: deteccion de exe bloqueado y verificacion GUI conservadas",
          ':ensure_exe_closed' in bat and ':verify_gui' in bat and 'LastWriteTimeUtc' in bat)
    check("v30: menu de 8 opciones y flujo relay intactos (goto 1-8 + configurar_relay.ps1)",
          all((f'if "%OP%"=="{i}" goto' in bat) for i in range(1, 9)) and 'configurar_relay.ps1' in bat)
    check("v30: errorlevel controlado tras cada cmake (4 puntos: 2 configure + 2 build)",
          bat.count('if errorlevel 1 goto build_fail') == 4)
    labels = re.findall(r'^:(\w+)', bat, re.M)
    targets = [t for t in re.findall(r'\b(?:goto|call)\s+:?(\w+)', bat) if t != 'eof']
    check("v30: integridad batch — labels unicos y todo goto/call tiene su :label",
          len(labels) == len(set(labels)) and set(targets) <= set(labels))
    check("v30: integridad batch — todo label esta referenciado (ni sobran ni faltan)",
          set(labels) - {'menu'} <= set(targets) | {'menu'})
    check("v30: compatibilidad cmd — ASCII puro, sin CR (LF como el original), sin BOM",
          all(b < 128 for b in bat_b) and b'\r' not in bat_b and not bat_b.startswith(b'\xef\xbb\xbf'))

    print("\n== (3) TALADRO diagonal e ILIMITADO (v25) ==")
    check("macro ROUGE_DRILL_DIVE_X 8 (impulso diagonal)",
          re.search(r'#macro ROUGE_DRILL_DIVE_X 8', create) is not None)
    check("ya NO existe la macro de duracion ROUGE_DRILL_TIME",
          'ROUGE_DRILL_TIME' not in create and 'ROUGE_DRILL_TIME' not in spec)
    air = re.search(r'--- TALADRO AEREO \(modo aereo, v24\) ---(.*?)audio_play_sound', spec, re.S)
    ab = air.group(1) if air else ''
    check("rama aerea: drillState = 1 (BANDERA, sin limite)",
          'drillState = 1' in ab)
    check("rama aerea: impulso DIAGONAL xspd = image_xscale * ROUGE_DRILL_DIVE_X",
          'xspd = image_xscale * ROUGE_DRILL_DIVE_X' in ab)
    check("rama aerea: yspd = ROUGE_DRILL_DIVE (picada) intacta",
          'yspd = ROUGE_DRILL_DIVE' in ab)
    dr = re.search(r'taladro aereo activo \(v24, v25 ILIMITADO\)(.*?)\n\s*// ---------------- tornado activo', spec, re.S)
    db = dr.group(1) if dr else ''
    check("bloque taladro SIN decremento (no expira por tiempo)",
          bool(dr) and 'drillState--' not in db and 'drillState -= 1' not in db)
    check("cortes (dano/stun/muerte) pagan la recarga (v24)",
          'isDead || shockedTimer > 0 || isHurt' in db and 'attackTimer = ROUGE_ATTACK_RECHARGE' in db)
    check("fantasmas del taladro (effectTime) intactos (v24)", 'effectTime = 16' in db)
    check("cambio de modo: drillState = 0 + tornadoState COMPLETO (v24)",
          re.search(r'drillState = 0;\s*\n\s*tornadoState = ROUGE_TORNADO_TIME', spec) is not None)

    print("\n== (4) RADAR de la salida (patron Amy Canon, v25) ==")
    check("Draw_64 de Rouge dibuja spr_sindicator2 (flecha verde de Amy Canon)",
          'spr_sindicator2' in draw64)
    check("apunta al obj_bigring MAS CERCANO (instance_nearest + point_direction)",
          'instance_nearest(x, y, obj_bigring)' in draw64
          and 'point_direction(x, y, _ring.x, _ring.y)' in draw64)
    check("guards: hp > 0, revivalTimes < 2 y anillo existente",
          re.search(r'if\(hp > 0 && revivalTimes < 2 && instance_exists\(obj_bigring\)\)', draw64) is not None)
    check("NO dibuja la flecha roja del exe (esa es exclusiva de Amy Canon)",
          'spr_indicator' not in draw64.replace('spr_sindicator2', '')
          and 'exeVisible' not in draw64)
    check("es SOLO informacion local (cero paquetes nuevos)",
          'net_' not in draw64[draw64.find('RADAR DE LA SALIDA'):] if 'RADAR DE LA SALIDA' in draw64 else False)

    print("\n== Regresiones v24/v23 (intactas) ==")
    check("rompe-i-frames del taladro en el puppet (v24)",
          'if(character == CHARACTER_ROUGE && state == ROUGE_ATTACK)' in pup
          and pup.find('if(character == CHARACTER_ROUGE && state == ROUGE_ATTACK)') <
              pup.find('if(global.player.shockedTimer <= 0 && global.player.hurttime <= 0)'))
    check("vuelo Z + ARRIBA (v24)", 'keyboard_check_pressed(global.KeyA) && keyboard_check(global.KeyUp)' in spec)
    check("i-frames de pared: 2 sensores (v24)",
          len(re.findall(r'hurttime = max\(hurttime, ROUGE_WALL_IFRAMES\)', coll)) == 2)
    check("macro ROUGE_WALL_IFRAMES (60 * 2) (v24)",
          re.search(r'#macro ROUGE_WALL_IFRAMES \(60 \* 2\)', create) is not None)
    check("LMS cura al max del personaje (v24)",
          'global.player.hp = max(global.player.hp, scr_player_maxhp(global.character))' in nsg
          and re.search(r'global\.player\.hp = LMS_HP\s*;', nsg) is None)
    check("spawn cura al max al nacer (v24)",
          'pinst.hp = scr_player_maxhp(global.character)' in spawn)
    check("spindash: entrada SIN !isSpinCharging + bypass 18 (v23)",
          re.search(r'!isSpinning && keyboard_check_pressed\(global\.KeyA\)\)', spec) is not None
          and '#macro ROUGE_ROLL_SPEED_CAP 18' in create)
    check("Draw_76 glide: image_xscale = 1 (fix espejo v23)",
          re.search(r'case ROUGE_GLIDE_AIR:\s*\n\s*image_speed = 0;\s*\n\s*image_xscale = 1;', draw76) is not None)
    check("drillState declarado en el Create (v24)",
          re.search(r'^drillState = 0;', create, re.M) is not None)
    check("hp de Rouge en Create sigue 125",
          re.search(r'^hp = 125;', create, re.M) is not None)
    check("Sally F2 del puppet INTACTA (mi rama no la toca)",
          pup.count('if(character == CHARACTER_SALLY_CANON && state == SALLY_CANON_F2_ATTACK)') == 1)
    mx = read(P('scripts', 'scr_player_maxhp', 'scr_player_maxhp.gml'))
    check("scr_player_maxhp intacto (Rouge 125 / Metal 150 / resto 100)",
          'return 125' in mx and 'return 150' in mx)
    son = read(P('scripts', 'scr_sonic_special', 'scr_sonic_special.gml'))
    check("Sonic INTACTO (sin ROUGE_ en su codigo)", 'ROUGE_' not in strip_gml(son))

    print("\n== Balance de llaves/parens/brackets ==")
    for path in ['scripts/scr_rouge_special/scr_rouge_special.gml',
                 'objects/obj_rouge/Create_0.gml',
                 'objects/obj_rouge/Draw_76.gml',
                 'objects/obj_rouge/Draw_64.gml',
                 'scripts/scr_collision_basic/scr_collision_basic.gml',
                 'objects/obj_player_puppet/Step_0.gml',
                 'scripts/net_state_game/net_state_game.gml',
                 'objects/obj_spawnpoint/Create_0.gml',
                 'betterserver-oss/disasterserver/states/Game.c']:
        ok, msg = balanced(read(P(*path.split('/'))), path)
        check(msg, ok)

    print("\n== Simulaciones 1:1 ==")
    for name, passed in sim_all():
        check(name, passed)

    print(f"\n{'=' * 56}")
    fails = [n for n, ok in RESULTS if not ok]
    print(f"TOTAL: {len(RESULTS) - len(fails)}/{len(RESULTS)} OK")
    if fails:
        print("FALLAS:", *fails, sep='\n  - ')
        sys.exit(1)
    print("TODO OK — v30 completa y sin regresiones.")


if __name__ == '__main__':
    main()
