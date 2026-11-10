#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# =============================================================================
# TD2DR — VERIFICADOR del FIX "PORTAL GUN" V1
# =============================================================================
# Comprueba, sin abrir el juego:
#   [A] Codigo: objects/obj_abyss/Step_0.gml usa la nueva seleccion
#       (par tid/target_id + mas cercano AL JUGADOR + preferencia por suelo),
#       mantiene el dano (20) y el bloque de shards de RavineMist intacto.
#   [B] Datos (rooms .yy, JSON tolerante):
#       1. Ningun pozo (obj_abyss) toca suelo caminable en los 4 mapas
#          nuevos (regla: franja del pozo vs mascara de un jugador parado,
#          altura 48). El bug original: el pozo medio de SkySanctuary
#          pisaba el bloque (752..1008, top 1084) => teleport por caminar.
#       2. Todos los obj_abyss_target de las 3 salas arregladas tienen
#          suelo debajo (excepto 3 "borderline" que vienen del porte y que
#          el codigo nuevo esquiva por la regla anti-rebote: aviso, no error).
#       3. Simulacion de caidas por TODO el ancho de cada pozo con el
#          ALGORITMO NUEVO (espejo exacto del GML): devuelve el target
#          elegido y la distancia; el maximo no debe pasarse de UMBRAL.
#   [C] El JSON de las 3 salas parsea y los conteos de instancias cuadran.
#
# Uso:  python3 check_portal_gun_fix.py   (desde la raiz del repo)
# =============================================================================
import json, re, os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
FAIL = []
WARN = []

def k(m, extra=''):
    print(f'  [OK]   {m}' + (f' ({extra})' if extra else ''))

def err(m):
    print(f'  [FALLO] {m}')
    FAIL.append(m)

def warn(m):
    print(f'  [AVISO] {m}')
    WARN.append(m)

# ---------------------------------------------------------------- (A) codigo
def check_codigo():
    print('\n[A] Codigo — objects/obj_abyss/Step_0.gml')
    p = os.path.join(ROOT, 'objects/obj_abyss/Step_0.gml')
    if not os.path.exists(p):
        err('no existe Step_0.gml'); return
    t = open(p, encoding='utf-8', errors='replace').read()
    player_branch = t[:t.find('obj_ravintmist_shard')] if 'obj_ravintmist_shard' in t else t
    shard_branch = t[t.find('obj_ravintmist_shard'):] if 'obj_ravintmist_shard' in t else ''
    if 'point_distance(global.player.x, global.player.y, x, y)' in player_branch:
        k('seleccion relativa AL JUGADOR (point_distance)')
    else:
        err('falta point_distance(global.player...) en la rama del jugador')
    if 'collision_rectangle(x - 12, y, x + 12, y + 48, obj_floor_parent, true, true)' in player_branch:
        k('regla anti-rebote (collision_rectangle vs obj_floor_parent)')
    else:
        err('falta la regla anti-rebote')
    if 'tid == other.target_id' in player_branch:
        k('emparejamiento tid/target_id (sistema de DesertTown)')
    else:
        err('falta el emparejamiento tid/target_id')
    if 'instance_nearest(x, y, obj_abyss_target)' not in player_branch:
        k('la rama del jugador ya NO usa instance_nearest desde la esquina del pozo')
    else:
        err('la rama del jugador sigue usando instance_nearest(x, y, ...)')
    if 'scr_player_hurt(20, 0, 0)' in player_branch:
        k('dano de caida intacto: scr_player_hurt(20, 0, 0)')
    else:
        err('falta scr_player_hurt(20, 0, 0)')
    if shard_branch and 'instance_nearest(x, y, obj_abyss_target)' in shard_branch \
       and '_inst.x = inst.x - _inst.sprite_height/2' in shard_branch:
        k('bloque de shards de RavineMist intacto')
    else:
        err('bloque de shards de RavineMist alterado')
    if t.count('{') == t.count('}'):
        k('llaves balanceadas (%d)' % t.count('{'))
    else:
        err('llaves desbalanceadas')

# ---------------------------------------------------------------- (B) datos
def load_room(rel):
    raw = open(os.path.join(ROOT, rel), encoding='utf-8', errors='replace').read()
    raw = re.sub(r'/\*.*?\*/', '', raw, flags=re.S)
    raw = re.sub(r'^///.*$', '', raw, flags=re.M)
    raw = re.sub(r',(\s*[}\]])', r'\1', raw)
    return json.loads(raw.strip())

FLOOR = {'obj_solid_block', 'obj_solid_block2', 'obj_platform_jumptrough', 'obj_skybase_slope'}
H_MASK = 48  # altura aprox de la mascara del jugador parado

def rect(i, w=32, h=32, ox=16, oy=16):
    sx, sy = i.get('sx', 1), i.get('sy', 1)
    l = i['x'] - ox * sx; r = i['x'] + (w - ox) * sx
    t = i['y'] - oy * sy; b = i['y'] + (h - oy) * sy
    return l, t, r, b

def room_instances(d):
    out = []
    for layer in d.get('layers', []):
        for inst in layer.get('instances', []):
            out.append({'obj': inst.get('objectId', {}).get('name', '?'),
                        'x': float(inst.get('x', 0)), 'y': float(inst.get('y', 0)),
                        'sx': float(inst.get('scaleX', 1) or 1),
                        'sy': float(inst.get('scaleY', 1) or 1),
                        'name': inst.get('name') or inst.get('%Name', '')})
    return out

def check_sala(room_file, room_name, n_targets_esperado, umbral, borderline_ok=()):
    print(f'\n[B] {room_name}')
    try:
        d = load_room(os.path.join('rooms', room_file, room_file + '.yy'))
    except Exception as e:
        err(f'{room_name}: JSON no parsea: {e}'); return
    insts = room_instances(d)
    pits = [i for i in insts if i['obj'] == 'obj_abyss']
    tg = [i for i in insts if i['obj'] == 'obj_abyss_target']
    floors = [i for i in insts if i['obj'] in FLOOR]
    W = d.get('roomSettings', {}).get('Width')
    k(f'JSON ok ({W}x{d.get("roomSettings", {}).get("Height")}, {len(insts)} instances)')
    if len(tg) != n_targets_esperado:
        err(f'{room_name}: {len(tg)} targets (esperados {n_targets_esperado})')
    else:
        k(f'{len(tg)} targets de retorno')

    # --- 1. pozos vs suelo caminable
    for p in pits:
        pl, ptop = p['x'] - 16 * p['sx'], p['y'] - 32 * p['sy']
        pr, pbot = p['x'] + 16 * p['sx'], p['y']
        for f in floors:
            fl, ftop = f['x'] - 16 * f['sx'], f['y'] - 16 * f['sy']
            fr = f['x'] + 16 * f['sx']
            if ptop < ftop and pbot > ftop - H_MASK and not (pr <= fl or pl >= fr):
                err(f"pozo {p['name']} x[{pl:.0f},{pr:.0f}] toca suelo caminable {f['name']} ({fl:.0f},{ftop:.0f})")
    if not any(f for f in FAIL if 'toca suelo caminable' in f):
        k(f'{len(pits)} pozos sin solape con suelo caminable')

    # --- 2. targets con suelo
    def grounded(t):
        for f in floors:
            fl, ftop = f['x'] - 16 * f['sx'], f['y'] - 16 * f['sy']
            fr = f['x'] + 16 * f['sx']
            if t['x'] >= fl - 12 and t['x'] <= fr + 12 and t['y'] >= ftop - 8 and t['y'] <= ftop + 32 * f['sy'] + 8:
                return True
        return False
    air = [t for t in tg if not grounded(t)]
    if not air:
        k('todos los targets tienen suelo debajo')
    else:
        for t in air:
            if (t['x'], t['y']) in borderline_ok:
                warn(f"target borderline ({t['x']:.0f},{t['y']:.0f}) del porte original (el codigo lo esquiva)")
            else:
                err(f"target ({t['x']:.0f},{t['y']:.0f}) SIN suelo debajo")

    # --- 3. simulacion de caidas con el ALGORITMO NUEVO
    def dist(ax, ay, bx, by):
        return ((ax - bx) ** 2 + (ay - by) ** 2) ** 0.5
    def pick(fx, fy):
        best, bd = None, 1e18
        bestS, bdS = None, 1e18
        for t in tg:
            d = dist(fx, fy, t['x'], t['y'])
            if d < bd:
                bd, best = d, t
            if grounded(t) and d < bdS:
                bdS, bestS = d, t
        return (bestS if bestS else best), (bdS if bestS else bd)
    worst = (0, None)
    for p in pits:
        pl, pr = p['x'] - 16 * p['sx'], p['x'] + 16 * p['sx']
        py = p['y'] - 4
        x = pl
        while x <= pr:
            t, d = pick(x, py)
            if d > worst[0]:
                worst = (d, (x, t['x'], t['y']))
            if t and not grounded(t) and any(grounded(q) for q in tg):
                err(f'caida en x={x:.0f} elige target SIN suelo ({t["x"]:.0f},{t["y"]:.0f})')
            x += 32
    if worst[0] <= umbral:
        k(f'distancia maxima de teleport simulada: {worst[0]:.0f}px (umbral {umbral}) @ {worst[1]}')
    else:
        err(f'distancia maxima {worst[0]:.0f}px > umbral {umbral} @ {worst[1]}')

if __name__ == '__main__':
    print('=' * 72)
    print('TD2DR — VERIFICADOR FIX PORTAL GUN V1')
    print('=' * 72)
    check_codigo()
    #                      sala                 targets  umbral  borderline del porte
    check_sala('room_skysanctuary', 'room_skysanctuary (SkySanctuary)', 23, 900,
               borderline_ok={(1424.0, 1472.0), (1424.0, 864.0), (1952.0, 992.0)})
    check_sala('room_skybase', 'room_skybase (SkyBase)', 12, 700)
    check_sala('room_woodzone', 'room_woodzone (Wood Zone)', 2, 300)
    # control: mapas originales sin cambios
    print('\n[B] control: mapas originales (no tocados)')
    for r in ['room_deserttown', 'room_ravinemist']:
        try:
            d = load_room(os.path.join('rooms', r, r + '.yy'))
            k(f'{r}: JSON ok (sin cambios, referencia)')
        except Exception as e:
            err(f'{r}: JSON roto: {e}')
    print('\n' + '=' * 72)
    print(f'RESULTADO: {len(FAIL)} fallos, {len(WARN)} avisos')
    if FAIL:
        for f in FAIL:
            print('  FALLO:', f)
        sys.exit(1)
    print('TODO OK')
