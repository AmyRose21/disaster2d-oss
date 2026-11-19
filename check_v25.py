#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v25.py — Validador de la ronda v25 de ROUGE (pedidos de la duena).

  (1) GLIDE con giro AGIL: la velocidad 6.25 hacia la inversion pesada
      -> ROUGE_GLIDE_ACC 3 (invierte en ~89 frames vs ~107 de Knux)
  (2) TORNADO (attack2) dura 3 s (antes 0.8) con el frenado original
      intacto (ROUGE_TORNADO_BRAKE) y su animacion en LOOP REAL toda la
      duracion (image_speed 0.5: con 2.0 la tira de 2 frames quedaba
      clavada en el frame 0 por el wrap)
  (3) TALADRO: impulso DIAGONAL (ROUGE_DRILL_DIVE_X 8 hacia donde mira)
      e ILIMITADO en el aire (ya no expira: taladra hasta aterrizar
      -> tornado, o a que lo corten dano/stun/muerte)
  (4) RADAR de la salida: flecha verde al anillo de escape (patron Amy
      Canon) en el Draw_64 de obj_rouge — solo local, cero red
  (5) (TierList_Mejoras_V5_0.html va aparte, no es codigo)

Uso:  python3 check_v25.py [ruta_del_proyecto]
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
                 'objects/obj_spawnpoint/Create_0.gml']:
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
    print("TODO OK — v25 completa y sin regresiones.")


if __name__ == '__main__':
    main()
