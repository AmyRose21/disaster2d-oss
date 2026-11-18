#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v24.py — Validador del rework ROUGE v24 (pedidos de la duena).

Pedidos:
  (1) el ataque por tierra SI debe reproducir spr_rouge_attack2 (el
      problema: la patada aerea terminaba por ANIMACION en el aire y al
      aterrizar ya no quedaba ataque -> se veia solo correr);
      NUEVO ataque aereo = TALADRO: impulso hacia abajo, duracion propia,
      residuos fantasma, ROMPE i-frames; si aterriza con carga restante
      arranca el tornado (attack2) con duracion COMPLETA (2 habilidades
      en 1); el tornado tambien deja fantasmas
  (2) glide: cae 35% mas lento que el de Knuckles y 25% mas rapida
  (3) i-frames de 2 s por cada toque de pared en el planeo
  (4) vuelo pasa a Z + ARRIBA (no gastarlo al querer planear)
  (5) vida: LMS cura hasta el maximo del personaje (no fija 100) y al
      inicio de la ronda todos entran al max (Rouge 125 / Metal 150)

Uso:  python3 check_v24.py [ruta_del_proyecto]
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
TORNADO_TIME = int(60 * 0.8)
TORNADO_START, TORNADO_MIN = 12, 1.5
SPD_BASE, SPD_REV, SPD_MAX, SPD_START_MAX = 8, 2, 10, 2
DRILL_TIME, DRILL_DIVE = 60, 12
GLIDE_SPD, GLIDE_ACC, GLIDE_FALL = 6.25, 2, 0.7922
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
                s.dr = DRILL_TIME
                s.yspd = DRILL_DIVE; s.xspd = 0; s.gspd = 0
        # taladro activo
        if s.dr > 0:
            if s.dead or s.shock > 0 or s.hurt:
                s.dr = 0; s.atk = False; s.atkT = ATT_RECH
            else:
                if s.yspd < DRILL_DIVE:
                    s.yspd = DRILL_DIVE
                if s.et <= 0:
                    s.et = 16
                s.dr -= 1
                if s.dr <= 0 and not s.grounded:
                    s.atk = False; s.atkT = ATT_RECH
        # tornado activo
        if s.tor > 0:
            if s.dead or s.shock > 0:
                s.tor = 1
            el = TORNADO_TIME - s.tor
            spd = TORNADO_START - (TORNADO_START - TORNADO_MIN) * min(el / TORNADO_TIME, 1)
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
                pass  # gira rapido, sin cierre
            else:
                if s.img >= s.imgn - 1 and s.dr <= 0:
                    s.atk = False; s.grounded = False
        elif s.state == R_AIR_ATK:
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
    # A: X en tierra
    p = Sim()
    for k in mkseq(62, xp=lambda f: f == 10):
        p.frame(k)
    a = [l for l in p.log[10:57]]
    R.append(("SIM A: tornado attack2 47f", len(a) == 47 and all(l[1] == 'attack2' for l in a)))
    # B: X durante rodada del spindash
    p = Sim()
    for k in mkseq(70, zp=lambda f: f in (5, 7), z=lambda f: f in (5, 7),
                   down=lambda f: f < 12, xp=lambda f: f == 20):
        p.frame(k)
    b = [l for l in p.log[20:67]]
    R.append(("SIM B: X en rodada = attack2 47f", len(b) == 47 and all(l[1] == 'attack2' for l in b)))
    # C: spindash 5 Z
    p = Sim()
    for k in mkseq(56, zp=lambda f: f in (5, 15, 25, 35, 45), z=lambda f: f in (5, 15, 25, 35, 45),
                   down=lambda f: f < 50):
        p.frame(k)
    R.append(("SIM C: carga 10 + salida 18", p.log[48][0] == R_SPINDASH
              and abs(max(abs(l[4]) for l in p.log[50:53]) - 18) < 0.5))
    # D: glide izquierda
    p = Sim()
    for k in mkseq(55, zp=lambda f: f == 10, z=lambda f: f == 10 or f >= 25,
                   left=lambda f: f >= 25):
        p.frame(k)
    g = [l for l in p.log if l[0] == R_GLIDE_AIR]
    R.append(("SIM D: glide frame 4 sin espejo, cae 0.7922, va 6.25",
              len(g) > 5 and all(l[2] == 1 and l[3] == 4 for l in g)
              and all(abs(l[5] - 0.7922) < 0.02 for l in g)
              and all(6.2 <= abs(l[4]) <= 6.4 for l in g)))
    # E: taladro
    p = Sim()
    for k in mkseq(70, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 12):
        p.frame(k)
    R.append(("SIM E: picada 12, attack1, sin recarga, fantasmas",
              p.log[12][0] == R_ATK and p.log[12][5] >= 11.9
              and p.log[13][1] == 'attack1' and p.log[13][9] == 0
              and p.ghosts >= 8))
    # E2: taladro aterriza -> tornado FULL
    p = Sim()
    for k in mkseq(90, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 8):
        p.frame(k)
    ft = next(i for i, l in enumerate(p.log) if l[6] > 0)
    t = [l for l in p.log[ft:ft + 47]]
    end = ft + 48
    R.append(("SIM E2: aterrizar = tornado FULL attack2 + 1 recarga al final",
              p.log[ft][6] >= 46 and p.log[ft][7] == 0
              and len(t) == 47 and all(l[1] == 'attack2' for l in t)
              and p.log[end][9] > 0 and all(l[9] == 0 for l in p.log[8:end])))
    # E3: taladro agotado en el aire
    p = Sim(floor=99999)
    p.y = 300.0  # nace lejos del piso: nunca aterriza
    for k in mkseq(90, zp=lambda f: f == 5, z=lambda f: f == 5, xp=lambda f: f == 8):
        p.frame(k)
    R.append(("SIM E3: agotado en aire paga la recarga",
              p.log[69][8] is False and p.log[69][9] >= 1190))
    # F: vuelo Z+Up
    p = Sim()
    for k in mkseq(80, zp=lambda f: f == 10, z=lambda f: f == 10):
        p.frame(k)
    R.append(("SIM F: Z sola en el aire no gasta el vuelo",
              p.log[70][10] is False and p.log[70][11] == 0))
    p = Sim()
    for k in mkseq(80, zp=lambda f: f in (10, 30), z=lambda f: f in (10, 30),
                   up=lambda f: f == 30):
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
    coll = read(P('scripts', 'scr_collision_basic', 'scr_collision_basic.gml'))
    pup = read(P('objects', 'obj_player_puppet', 'Step_0.gml'))
    nsg = read(P('scripts', 'net_state_game', 'net_state_game.gml'))
    spawn = read(P('objects', 'obj_spawnpoint', 'Create_0.gml'))

    print("== TALADRO aereo (ataque X en el aire, v24) ==")
    xg = re.search(r'keyboard_check_pressed\(global\.KeyB\)(.*?)\n\s*\{', spec, re.S)
    check("guard del X: !isSpinCharging + !isAttacking (no reiniciar el taladro)",
          bool(xg) and '!isSpinCharging' in xg.group(1) and '!isAttacking' in xg.group(1))
    air = re.search(r'--- TALADRO AEREO \(modo aereo, v24\) ---(.*?)audio_play_sound', spec, re.S)
    ab = air.group(1) if air else ''
    check("rama aerea: drillState = ROUGE_DRILL_TIME", 'drillState = ROUGE_DRILL_TIME' in ab)
    check("rama aerea: impulso abajo yspd = ROUGE_DRILL_DIVE", 'yspd = ROUGE_DRILL_DIVE' in ab)
    check("rama aerea: picada vertical (xspd = 0)", 'xspd = 0' in ab)
    check("rama aerea: SIN attackTimer al activar (recarga al final de la cadena)",
          'attackTimer' not in ab)
    dr = re.search(r'taladro aereo activo \(v24\)(.*?)\n\s*// ---------------- tornado activo', spec, re.S)
    db = dr.group(1) if dr else ''
    check("bloque taladro activo presente (duración, no animación)", bool(dr))
    check("taladro mantiene la picada (yspd >= ROUGE_DRILL_DIVE)", 'if(yspd < ROUGE_DRILL_DIVE)' in db)
    check("taladro deja fantasmas (effectTime)", 'effectTime = 16' in db)
    check("taladro lo cortan daño/stun/muerte pagando recarga",
          'isDead || shockedTimer > 0 || isHurt' in db and 'attackTimer = ROUGE_ATTACK_RECHARGE' in db)
    check("taladro agotado EN EL AIRE paga la recarga",
          'if(drillState <= 0 && !isGrounded)' in db)
    dm = re.search(r'CAMBIO DE MODO AEREO -> TERRESTRE.*?\n(.*?)\n\s*else if', spec, re.S)
    dmb = dm.group(1) if dm else ''
    check("cambio de modo: drillState = 0 + tornadoState = ROUGE_TORNADO_TIME (FULL)",
          'drillState = 0' in dmb and 'tornadoState = ROUGE_TORNADO_TIME' in dmb)
    check("else-if defensivo con gates tornadoState/drillState",
          'tornadoState <= 0 && drillState <= 0' in spec)
    tb = re.search(r'---------------- tornado activo ----------------(.*?)CAMBIO DE MODO', spec, re.S)
    check("tornado tambien deja fantasmas (effectTime)", 'effectTime = 16' in (tb.group(1) if tb else ''))

    print("\n== Draw_76: taladro y transicion ==")
    c14 = re.search(r'case ROUGE_ATTACK:(.*?)case ROUGE_AIR_ATTACK:', draw76, re.S)
    c15 = re.search(r'case ROUGE_AIR_ATTACK:(.*?)// v13: estado de VUELO', draw76, re.S)
    check("case ROUGE_ATTACK: drillState > 0 => image_speed 2 (taladro girando)",
          bool(c14) and 'drillState > 0' in c14.group(1) and 'image_speed = 2' in c14.group(1))
    check("case ROUGE_ATTACK: cierre por animacion NO mata el aterrizaje (&& drillState <= 0)",
          bool(c14) and re.search(r'image_number - 1 && drillState <= 0', c14.group(1)))
    check("case ROUGE_AIR_ATTACK: drillState tambien mantiene el giro (frame de aterrizaje)",
          bool(c15) and 'drillState > 0' in c15.group(1))

    print("\n== Rompe-i-frames del taladro (puppet) ==")
    i_g = pup.find('if(global.player.shockedTimer <= 0 && global.player.hurttime <= 0)')
    i_d = pup.find('if(character == CHARACTER_ROUGE && state == ROUGE_ATTACK)')
    check("rama del taladro ANTES del gate de i-frames (lo rompe)", i_g > 0 and 0 < i_d < i_g)
    seg = pup[i_d:i_g] if i_d > 0 else ''
    check("aplica el stun directo (shockedTimer) sin gate",
          'global.player.shockedTimer = _rstun * 60' in seg)
    check("reporta CLIENT_PLAYER_HURT + STATS_REPORT (patron Sally F2)",
          'CLIENT_PLAYER_HURT' in seg and 'CLIENT_STATS_REPORT' in seg)
    check("rama devuelve (return) sin caer al camino normal", 'return;' in seg)
    f2 = pup.find('if(character == CHARACTER_SALLY_CANON && state == SALLY_CANON_F2_ATTACK)')
    check("patada duelista de Sally Canon INTACTA", f2 > 0)

    print("\n== GLIDE: mas lenta y mas rapida que Knuckles (v24) ==")
    check("macro ROUGE_GLIDE_SPD 6.25 (+25% del 5 de Knux)",
          re.search(r'#macro ROUGE_GLIDE_SPD 6\.25', create) is not None)
    check("macro ROUGE_GLIDE_FALL 0.7922 (objetivo EFECTIVO, 65% del de Knux)",
          re.search(r'#macro ROUGE_GLIDE_FALL 0\.7922', create) is not None)
    check("special resta yAccel (la gravedad rellena hasta el objetivo)",
          'yspd = ROUGE_GLIDE_FALL - yAccel' in spec)
    check("mapeo de frames por RANGOS (soporta 6.25 no entero)",
          'var _gi = floor(glide_xspd)' in spec and '_gi >= 2' in spec)
    check("ya NO hay switch con cases exactos de ROUGE_GLIDE_SPD",
          'case ROUGE_GLIDE_SPD' not in spec)
    knx = read(P('objects', 'obj_knux', 'Draw_76.gml'))
    check("Knuckles INTACTO (su glide sigue yspd = 1, sin i-frames de pared)",
          re.search(r'yspd = 1;', read(P('scripts', 'scr_knux_special', 'scr_knux_special.gml'))) is not None
          and 'ROUGE_WALL_IFRAMES' not in read(P('scripts', 'scr_knux_special', 'scr_knux_special.gml')))

    print("\n== I-frames por toque de pared (v24) ==")
    n_wall = len(re.findall(r'hurttime = max\(hurttime, ROUGE_WALL_IFRAMES\)', coll))
    check("ambos sensores pagan 2 s al AGARRAR (solo Rouge)", n_wall == 2)
    check("macro ROUGE_WALL_IFRAMES (60 * 2)", re.search(r'#macro ROUGE_WALL_IFRAMES \(60 \* 2\)', create) is not None)
    check("dentro de la transicion !isStuck (una vez por toque)",
          len(re.findall(r'isStuck = true;\s*\n\s*// v24.*?hurttime = max\(hurttime, ROUGE_WALL_IFRAMES\)', coll, re.S)) >= 1)

    print("\n== Vuelo: Z + ARRIBA (v24) ==")
    fg = re.search(r'VUELO patron VANILLA \(Z \+ ARRIBA.*?\n\s*if\((.*?)\)\s*\n\s*\{', spec, re.S)
    check("activacion exige keyboard_check(global.KeyUp)",
          bool(fg) and 'keyboard_check(global.KeyUp)' in fg.group(1))
    check("glide pasiva SIN cambio (Z mantenida al caer)",
          'yspd > 0 && keyboard_check(global.KeyA)' in spec)

    print("\n== Vida: LMS cura al max + inicio de ronda (v24) ==")
    check("LMS: hp = max(hp, scr_player_maxhp(char)) — nunca baja, cura al tope",
          'global.player.hp = max(global.player.hp, scr_player_maxhp(global.character))' in nsg)
    check("LMS: ya NO fija hp = LMS_HP directo",
          re.search(r'global\.player\.hp = LMS_HP\s*;', nsg) is None)
    check("spawn: cura al MAX al nacer en la ronda (pinst.hp)",
          'pinst.hp = scr_player_maxhp(global.character)' in spawn)
    check("spawn: sigue sin tocar al EXE", 'global.character != CHARACTER_EXE' in spawn)
    mx = read(P('scripts', 'scr_player_maxhp', 'scr_player_maxhp.gml'))
    check("scr_player_maxhp intacto (Rouge 125 / Metal 150 / resto 100)",
          'return 125' in mx and 'return 150' in mx)

    print("\n== Regresiones v23 (intactas) ==")
    check("spindash: entrada SIN !isSpinCharging (revolucadas)",
          re.search(r'!isSpinning && keyboard_check_pressed\(global\.KeyA\)\)', spec) is not None)
    check("ataque apaga la bola (isSpinning/spinDashRelease = false)",
          'isSpinning = false' in spec and 'spinDashRelease = false' in spec)
    check("Draw_76 glide: image_xscale = 1 (fix espejo v23)",
          re.search(r'case ROUGE_GLIDE_AIR:\s*\n\s*image_speed = 0;\s*\n\s*image_xscale = 1;', draw76) is not None)
    check("bypass de velocidad de la bola (v23) intacto",
          re.search(r'CHARACTER_ROUGE && isSpinning\)\s*\n?\s*_clampX = max\(maxHSpeed, min\(abs\(gspd\), ROUGE_ROLL_SPEED_CAP\)\)', coll) is not None)
    check("macros v23 intactas (ROLL_SPEED_CAP 18 / GLIDE_RECHARGE)",
          '#macro ROUGE_ROLL_SPEED_CAP 18' in create and '#macro ROUGE_GLIDE_RECHARGE (60 * 12)' in create)
    check("drillState declarado en el Create", re.search(r'^drillState = 0;', create, re.M) is not None)
    check("hp de Rouge en Create sigue 125", re.search(r'^hp = 125;', create, re.M) is not None)
    son = read(P('scripts', 'scr_sonic_special', 'scr_sonic_special.gml'))
    sal = read(P('scripts', 'scr_sally_special', 'scr_sally_special.gml'))
    entry_re = re.compile(r'if\(global\.playerControls && isGrounded && !isAttacking && !isHurt'
                          r'(.*?)keyboard_check_pressed\(global\.KeyA\)\)', re.S)
    se = entry_re.search(son)
    sa = entry_re.search(sal)
    check("Sonic y Sally INTACTOS (entradas de sus spindashes iguales, sin ROUGE_)",
          bool(se) and '!isSpinCharging' not in se.group(1)
          and bool(sa) and '!isSpinCharging' not in sa.group(1)
          and 'ROUGE_' not in strip_gml(son) and 'ROUGE_' not in strip_gml(sal))
    check("puppet: Sally F2 + estandar intactos (solo se ANADIO la rama Rouge)",
          pup.count('if(character == CHARACTER_SALLY_CANON && state == SALLY_CANON_F2_ATTACK)') == 1)
    nsc = read(P('scripts', 'net_state_charselect', 'net_state_charselect.gml'))
    check("charselect SIN cambios esta vez", 'scr_player_maxhp' not in nsc)

    print("\n== Balance de llaves/parens/brackets ==")
    for path in ['scripts/scr_rouge_special/scr_rouge_special.gml',
                 'objects/obj_rouge/Create_0.gml',
                 'objects/obj_rouge/Draw_76.gml',
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
    print("TODO OK — v24 completa y sin regresiones.")


if __name__ == '__main__':
    main()
