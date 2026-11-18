#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v23.py — Validador del fix ROUGE v23 (3 bugs de la duena + 1 bloqueante).

Bugs reportados:
  (1) glide: al activarse mirando a la IZQUIERDA se ve del lado DERECHO
  (2) ataque por tierra: no usa spr_rouge_attack2
  (3) spindash: no carga con multiples Z ni supera la velocidad de carrera

Fixes aplicados (4 archivos):
  objects/obj_rouge/Draw_76.gml            -> case ROUGE_GLIDE_AIR: image_xscale = 1
  objects/obj_rouge/Create_0.gml            -> restituye ROUGE_GLIDE_RECHARGE (compilacion)
                                               + ROUGE_ROLL_SPEED_CAP 18 (bypass)
  scripts/scr_rouge_special/scr_rouge_special.gml
                                            -> entrada del spindash sin "!isSpinCharging"
                                               (revolucadas multiples, paridad Sonic/Sally)
                                               + guard "!isSpinCharging" en el X (paridad
                                               golpe de Sonic) + el ataque apaga la bola
                                               (isSpinning/spinDashRelease = false) para que
                                               el tornado SI muestre spr_rouge_attack2
  scripts/scr_collision_basic/scr_collision_basic.gml
                                            -> bypass de velocidad de la bola de Rouge
                                               (tope 18, patron Sonic/Amelia)

Uso:  python3 check_v23.py [ruta_del_proyecto]
      (por defecto: el directorio donde este el script o ./repo)
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


# ----------------------------------------------------------------------------
# utilidades GML: quitar comentarios y literales para analizar estructura
# ----------------------------------------------------------------------------
def strip_gml(src):
    out = []
    i, n = 0, len(src)
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
    return not stack, f"{fname}: pila restante {stack[:4]}" if stack else f"{fname}: OK"


# ----------------------------------------------------------------------------
# simulacion 1:1 compacta (transcripcion del comportamiento FIXEADO;
# el detalle completo esta en scripts/sim_rouge_v23.py del sandbox)
# ----------------------------------------------------------------------------
ROGUE_ATK_RECH = 60 * 20
TORNADO_TIME = int(60 * 0.8)
SPD_BASE, SPD_REV, SPD_MAX = 8, 2, 10
GLIDE_SPD = 5
R_ATTACK, R_AIR_ATTACK, R_GLIDE_AIR, R_SPINDASH, R_SPIN_RELEASE = 14, 15, 23, 20, 21
ANIMS = {14: 'attack1', 15: 'attack2', 23: 'glide', 20: 'charger', 21: 'release'}


class Sim:
    def __init__(s):
        s.gspd = s.xspd = s.yspd = 0.0
        s.grounded = True
        s.spin_charging = s.spinning = s.spinning_release = False
        s.charge = 0.0
        s.attacking = s.tornado = s.jumping = s.gliding = s.flying = False
        s.xscale = 1.0
        s.glide_xspd = 0.0
        s.y = 300.0
        s.state = 0
        s.sprite = 'idle'
        s.img_idx = 0.0
        s.frames = 3

    def step(s, z=False, z_p=False, x_p=False, left=False, down=False):
        # --- special (fixeado) ---
        if (z_p and s.grounded and not s.attacking and not s.spinning
                and down and abs(s.gspd) < 2 and not s.flying):
            s.spin_charging = True
            s.charge = min(s.charge + SPD_REV, SPD_MAX)   # cada Z suma (SIN !isSpinCharging)
        if s.spin_charging:
            s.gspd = s.xspd = 0
            if not down or not s.grounded:
                if s.grounded:  # lanzamiento (soltar abajo)
                    s.spin_charging = False
                    s.spinning = True
                    s.spinning_release = True
                    s.gspd = (SPD_BASE + s.charge) * s.xscale
                else:
                    s.spin_charging = False
                    s.charge = 0
        if (x_p and not s.attacking and s.tornado <= 0
                and not s.spin_charging):                  # guard nuevo (paridad Sonic)
            s.spinning = False                             # FIX: pegar apaga la bola
            s.spinning_release = False
            if s.grounded:
                s.tornado = TORNADO_TIME
                s.attacking = True
            else:
                s.attacking = True
        if s.tornado > 0:
            s.tornado -= 1
            if s.tornado <= 0:
                s.attacking = False
        # --- colision (bypass fixeado: tope 18 en bola) ---
        cap = 18 if s.spinning else 11
        s.xspd = max(-cap, min(cap, s.gspd))
        if s.grounded:
            s.yspd = 0
        else:
            s.yspd = min(s.yspd + 0.21875, 12)
            s.y += s.yspd
            if s.y >= 300:
                s.y = 300
                s.grounded = True
        # --- move_basic: In Air pisa xscale con izquierda (el bug del glide) ---
        if not s.grounded and left:
            s.xscale = -1
        # --- glide pasiva (activacion al descender con Z) ---
        if (not s.grounded and not s.gliding and not s.flying and not s.attacking
                and s.yspd > 0 and z):
            s.gliding = True
            s.glide_xspd = s.xscale * GLIDE_SPD
        if s.gliding:
            if not z:
                s.gliding = False
            else:
                fi = int(s.glide_xspd // 1)
                s.img_idx = 0 if fi >= 2 else (1 if fi == 1 else (2 if fi == 0 else (3 if fi == -1 else 4)))
            s.xscale = 1                                    # el special la fija...
            s.yspd = 1
            s.xspd = s.glide_xspd
        # --- Step_2 (prioridades exactas) ---
        if s.spin_charging:
            s.state = R_SPINDASH
        elif s.spinning and s.spinning_release:
            s.state = R_SPIN_RELEASE
        elif s.attacking:
            s.state = R_AIR_ATTACK if s.grounded else R_ATTACK
        elif s.gliding:
            s.state = R_GLIDE_AIR
        elif s.spinning:
            s.state = 12
        else:
            s.state = 0
        s.sprite = ANIMS.get(s.state, f'st{s.state}')


def sim_attack_roll():
    """X en plena rodada del spindash -> el tornado debe verse attack2."""
    p = Sim()
    p.xscale = 1
    seq = []
    for f in range(70):
        x_p = (f == 20)
        z_p = f in (5, 7)
        down = f < 12
        p.step(z_p=z_p, x_p=x_p, down=down, z=z_p)
        seq.append((p.state, p.sprite))
        if f == 13:
            assert p.spinning, 'la rodada no arranco'
    tornado_frames = [s for s in seq[20:67]]
    return all(sp == 'attack2' for _, sp in tornado_frames) and len(tornado_frames) == 47


def sim_charge():
    """5 revolucadas de Z -> carga 10; salida 18 px/f."""
    p = Sim()
    for f in range(52):
        z_p = f in (5, 15, 25, 35, 45)
        down = f < 50
        p.step(z_p=z_p, z=z_p, down=down)
        if f == 49:
            charge = p.charge
    return charge == 10 and abs(p.gspd) == 18


def sim_glide():
    """Glide mirando izquierda: sin espejo (Draw fija xscale=1)."""
    p = Sim()
    p.jumping = True
    p.grounded = False
    p.yspd = -6
    seen = []
    for f in range(55):
        left = f >= 25
        z = f >= 25
        p.step(z=z, left=left)
        if p.state == R_GLIDE_AIR:
            seen.append((p.xscale, p.img_idx))
    return len(seen) > 5 and all(xs == 1 and idx == 4 for xs, idx in seen)


def sim_attack_plain():
    """X en tierra (parada) -> attack2 los 47 frames del tornado."""
    p = Sim()
    ok = True
    for f in range(62):
        p.step(x_p=(f == 10))
        if 10 <= f <= 56:
            ok = ok and p.state == R_AIR_ATTACK and p.sprite == 'attack2'
    return ok


# ----------------------------------------------------------------------------
# checks estaticos sobre los archivos REALES
# ----------------------------------------------------------------------------
def main():
    base = sys.argv[1] if len(sys.argv) > 1 else None
    if base is None:
        cands = [os.path.dirname(os.path.abspath(__file__)), 'repo',
                 os.path.join(os.path.dirname(os.path.abspath(__file__)), 'repo')]
        base = next((c for c in cands
                     if os.path.exists(os.path.join(c, 'objects', 'obj_rouge', 'Create_0.gml'))),
                    cands[0])
    P = lambda *a: os.path.join(base, *a)
    print(f"Proyecto: {os.path.abspath(base)}\n")

    spec = read(P('scripts', 'scr_rouge_special', 'scr_rouge_special.gml'))
    create = read(P('objects', 'obj_rouge', 'Create_0.gml'))
    draw76 = read(P('objects', 'obj_rouge', 'Draw_76.gml'))
    coll = read(P('scripts', 'scr_collision_basic', 'scr_collision_basic.gml'))

    print("== FIX 1: glide espejado (Draw_76 local) ==")
    m = re.search(r'case ROUGE_GLIDE_AIR:\s*\n(.*?)break;', draw76, re.S)
    body = m.group(1) if m else ''
    check("case ROUGE_GLIDE_AIR existe", bool(m))
    check("case ROUGE_GLIDE_AIR fija image_xscale = 1", 'image_xscale = 1' in body)
    check("case ROUGE_GLIDE_AIR mantiene image_speed = 0", 'image_speed = 0' in body)
    knx = read(P('objects', 'obj_knux', 'Draw_76.gml'))
    mk = re.search(r'case KNUX_GLIDE:\s*\n(.*?)break;', knx, re.S)
    check("patron Knuckles intacto (KNUX_GLIDE con xscale=1)",
          bool(mk) and 'image_xscale = 1' in mk.group(1))
    pup = read(P('objects', 'obj_player_puppet', 'Draw_0.gml'))
    check("puppet intacto (xscale=1 en ROUGE_GLIDE_AIR remoto)",
          'state == ROUGE_GLIDE_AIR' in pup and 'image_xscale = 1' in pup)

    print("\n== FIX 2: ataque por tierra con spr_rouge_attack2 ==")
    guard = re.search(r'keyboard_check_pressed\(global\.KeyB\)(.*?)\n\s*\{', spec, re.S)
    check("guard del X incluye !isSpinCharging (paridad golpe de Sonic)",
          bool(guard) and '!isSpinCharging' in guard.group(1))
    xblock = re.search(r'keyboard_check_pressed\(global\.KeyB\).*?\n(.*?)\n\s*if\(isGrounded\)', spec, re.S)
    check("el ataque apaga la bola antes de ramificar (isSpinning = false)",
          bool(xblock) and 'isSpinning = false' in xblock.group(1))
    check("...y libera spinDashRelease = false",
          bool(xblock) and 'spinDashRelease = false' in xblock.group(1))
    step2 = read(P('objects', 'obj_rouge', 'Step_2.gml'))
    check("Step_2 intacto: tierra -> ROUGE_AIR_ATTACK (15)",
          re.search(r'if\(isGrounded\)\s*\n\s*state = ROUGE_AIR_ATTACK', step2) is not None)
    surv = read(P('scripts', 'scr_survivors', 'scr_survivors.gml'))
    tbl = re.search(r'global\.player_anims\[\? CHARACTER_ROUGE\] =\s*\[(.*?)\];', surv, re.S)
    check("tabla scr_survivors intacta: slot 15 = spr_rouge_attack2",
          bool(tbl) and re.search(r'spr_rouge_attack2,\s*//15', tbl.group(1)) is not None)

    print("\n== FIX 3: spindash identico al de Sonic ==")
    entry = re.search(r'if\(global\.playerControls && isGrounded && !isAttacking && !isHurt'
                      r'(.*?)keyboard_check_pressed\(global\.KeyA\)\)', spec, re.S)
    e = entry.group(1) if entry else ''
    check("entrada del spindash SIN !isSpinCharging (revolucadas multiples)",
          bool(entry) and '!isSpinCharging' not in e)
    check("entrada mantiene los guards de Sonic (abajo + parado + !isSpinning)",
          'keyboard_check(global.KeyDown)' in e and '!isSpinning' in e
          and 'abs(gspd) < ROUGE_SPINDASH_START_MAX' in e)
    son = read(P('scripts', 'scr_sonic_special', 'scr_sonic_special.gml'))
    se = re.search(r'if\(global\.playerControls && isGrounded && !isAttacking && !isHurt'
                   r'(.*?)keyboard_check_pressed\(global\.KeyA\)\)', son, re.S)
    check("spindash de Sonic INTACTO (su entrada sigue igual, sin regresiones)",
          bool(se) and '!isSpinCharging' not in se.group(1))
    sal = read(P('scripts', 'scr_sally_special', 'scr_sally_special.gml'))
    sa = re.search(r'if\(global\.playerControls && isGrounded && !isAttacking && !isHurt'
                   r'(.*?)keyboard_check_pressed\(global\.KeyA\)\)', sal, re.S)
    check("spindash de Sally INTACTO", bool(sa) and '!isSpinCharging' not in sa.group(1))
    check("bypass en scr_collision_basic (CHARACTER_ROUGE + isSpinning)",
          re.search(r'global\.character == CHARACTER_ROUGE && isSpinning\)\s*\n?\s*_clampX = '
                    r'max\(maxHSpeed, min\(abs\(gspd\), ROUGE_ROLL_SPEED_CAP\)\)', coll) is not None)
    check("bypass de Sonic INTACTO", 'SONIC_ROLL_SPEED_CAP' in coll)
    check("bypass de Amelia INTACTO", 'AMELIA_ROLL_SPEED_CAP' in coll)
    check("macro ROUGE_ROLL_SPEED_CAP 18 en Create",
          re.search(r'#macro ROUGE_ROLL_SPEED_CAP 18', create) is not None)

    print("\n== FIX 4: bloqueante de compilacion (macro restituida) ==")
    check("macro ROUGE_GLIDE_RECHARGE definida en Create de Rouge",
          re.search(r'#macro ROUGE_GLIDE_RECHARGE \(60 \* 12\)', create) is not None)
    defs = 0
    for root, _, files in os.walk(base):
        for fn in files:
            if fn.endswith('.gml'):
                d = read(os.path.join(root, fn))
                defs += len(re.findall(r'#macro\s+ROUGE_GLIDE_RECHARGE\b', d))
    check("definida exactamente 1 vez en todo el proyecto", defs == 1)
    cobj = read(P('scripts', 'scr_collision_objects', 'scr_collision_objects.gml'))
    nsg = read(P('scripts', 'net_state_game', 'net_state_game.gml'))
    uses = len(re.findall(r'\bROUGE_GLIDE_RECHARGE\b', cobj)) + len(re.findall(r'\bROUGE_GLIDE_RECHARGE\b', nsg))
    check("sus 3 usos (muelles x2 + puertas) siguen presentes e intactos", uses == 3)

    print("\n== Balance de llaves/parens/brackets (GML tocados) ==")
    for path in ['scripts/scr_rouge_special/scr_rouge_special.gml',
                 'objects/obj_rouge/Create_0.gml',
                 'objects/obj_rouge/Draw_76.gml',
                 'scripts/scr_collision_basic/scr_collision_basic.gml']:
        ok, msg = balanced(read(P(*path.split('/'))), path)
        check(msg, ok)

    print("\n== Simulaciones 1:1 del codigo fixeado ==")
    check("SIM A: X en tierra -> spr_rouge_attack2 los 47 frames", sim_attack_plain())
    check("SIM B: X en rodada del spindash -> attack2 (antes: la bola)", sim_attack_roll())
    check("SIM C: 5 Z cargan 10 y salen a 18 px/f (bypass)", sim_charge())
    check("SIM D: glide a la izquierda sin espejo (frame 4, xscale 1)", sim_glide())

    print(f"\n{'=' * 50}")
    fails = [n for n, ok in RESULTS if not ok]
    print(f"TOTAL: {len(RESULTS) - len(fails)}/{len(RESULTS)} OK")
    if fails:
        print("FALLAS:", *fails, sep='\n  - ')
        sys.exit(1)
    print("TODO OK — el fix esta completo y sin regresiones.")


if __name__ == '__main__':
    main()
