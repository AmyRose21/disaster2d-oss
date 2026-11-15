#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_rouge_v4.py - Repara los sprites Rouge rotos del proyecto GMS2
("Sonicexe The Disaster 2D Remake").

Cambios respecto a v3:
  * v3 asumia que cada frame tenia clave '%Name' (formato GM 2022+) y
    reventaba con KeyError. Este proyecto usa el formato VIEJO de GMS2
    (frames GMSpriteFrame con 'name'); v4 acepta cualquier formato:
    '%Name', 'name', 'id', o strings.
  * Tolerante al JSON "estilo GameMaker" (BOM, comas colgantes).
  * Si el .yy roto no se puede ni parsear, lo RECONSTRUYE desde cero:
    frames = los PNGs de la carpeta, estructura = un sprite sano del
    proyecto (plantilla), con copia de seguridad y verificacion.
  * Auditoria de todos los sprites sin romperse nunca.

USO (con GameMaker Studio 2 CERRADO):
    cd C:\\Users\\AM\\Documents\\GitHub\\disaster2d-oss
    python fix_rouge_v4.py
  o bien:
    python fix_rouge_v4.py "C:\\Users\\AM\\Documents\\GitHub\\disaster2d-oss"
  Se pueden indicar otros sprites a reparar como argumentos extra.
"""

import copy
import json
import os
import re
import shutil
import struct
import sys
import uuid
from datetime import datetime

DEFAULT_TARGETS = ['spr_rouge_glide', 'spr_rouge_marijuna', 'spr_rougenega_glide']
BACKUP_DIR = '_yyfix_backup'

# Plantilla de respaldo (formato GMS2 clasico) por si no hallara ningun
# sprite sano en el proyecto. Se usa solo como ultimo recurso.
TEMPLATE = {
    'bboxMode': 0, 'collisionKind': 1, 'type': 0, 'origin': 4,
    'preMultiplyAlpha': False, 'edgeFiltering': False, 'collisionTolerance': 0,
    'swfPrecision': 2.525,
    'bbox_left': 0, 'bbox_top': 0, 'bbox_right': 31, 'bbox_bottom': 31,
    'HTile': False, 'VTile': False, 'For3D': False,
    'width': 32, 'height': 32,
    'textureGroupId': 'Default', 'textureGroup': -1,
    'playbackSpeedType': 0, 'autoRecord': True, 'volume': 1.0,
    'parent': {'name': 'Sprites', 'path': 'folders/Sprites.yy'},
    'resourceVersion': '1.0', 'name': 'x', 'tags': [],
    'resourceType': 'GMSprite',
    'sequence': {
        'spriteId': None,
        'timeUnits': 1, 'playback': 1, 'playbackSpeed': 15.0,
        'playbackSpeedType': 0, 'autoRecord': True, 'volume': 1.0,
        'length': 1.0,
        'events': {'Keyframes': [], 'resourceVersion': '1.0',
                   'resourceType': 'KeyframeStore<MessageEventKeyframe>'},
        'moments': {'Keyframes': [], 'resourceVersion': '1.0',
                    'resourceType': 'KeyframeStore<MomentsEventKeyframe>'},
        'tracks': [{'name': 'frames', 'spriteId': None,
                    'keyframes': {'Keyframes': [],
                                  'resourceVersion': '1.0',
                                  'resourceType': 'KeyframeStore<SpriteFrameKeyframe>'},
                    'resourceVersion': '1.0', 'tags': [],
                    'resourceType': 'GMSequenceTrack'}],
        'visible': True, 'locked': False,
        'resourceVersion': '1.0', 'name': 'x', 'tags': [],
        'resourceType': 'GMSequence',
    },
    'layers': [{'visible': True, 'isLocked': False, 'blendMode': 0,
                'opacity': 100.0, 'displayName': 'default',
                'resourceVersion': '1.0', 'name': 'default', 'tags': [],
                'resourceType': 'GMImageLayer'}],
    'frames': [],
}


# ---------------------- carga tolerante ----------------------

def read_text(path):
    with open(path, 'r', encoding='utf-8-sig', errors='replace') as f:
        return f.read()


def gm_loads(text):
    """json.loads tolerante al estilo GameMaker (BOM + comas colgantes)."""
    t = text.lstrip('\ufeff')
    try:
        return json.loads(t)
    except json.JSONDecodeError:
        pass
    t2 = re.sub(r',(\s*[}\]])', r'\1', t)   # quita ",}" y ",]"
    return json.loads(t2)


# ------------- frames en cualquier formato (fix del KeyError) -------------

def frame_guid(f):
    """GUID/nombre de un frame en CUALQUIER formato de GMS.
    Aqui era donde v3 reventaba con f['%Name']."""
    if isinstance(f, str):
        s = f.strip()
        return s or None
    if isinstance(f, dict):
        for k in ('%Name', 'name', 'Name'):
            v = f.get(k)
            if isinstance(v, str) and v.strip():
                return v.strip()
        for k in ('id', 'Id'):
            v = f.get(k)
            if isinstance(v, str) and v.strip():
                return v.strip()
            if isinstance(v, dict):
                for kk in ('name', 'Name'):
                    vv = v.get(kk)
                    if isinstance(vv, str) and vv.strip():
                        return vv.strip()
        comp = f.get('Composite')
        if not isinstance(comp, dict):
            comp = f.get('composite')
        if isinstance(comp, dict):
            fid = comp.get('FrameId') or comp.get('frameId') or comp.get('id')
            if isinstance(fid, str) and fid.strip():
                return fid.strip()
            if isinstance(fid, dict):
                for kk in ('name', 'Name'):
                    vv = fid.get(kk)
                    if isinstance(vv, str) and vv.strip():
                        return vv.strip()
    return None


def frames_list(d):
    fr = d.get('frames') if isinstance(d, dict) else None
    return fr if isinstance(fr, list) else []


def png_size(path):
    try:
        with open(path, 'rb') as f:
            head = f.read(24)
        if len(head) >= 24 and head[:8] == b'\x89PNG\r\n\x1a\n':
            w, h = struct.unpack('>II', head[16:24])
            return int(w), int(h)
    except OSError:
        pass
    return None


# ---------------------- auditoria de sprites ----------------------

def audit(sprites_dir, targets):
    rows = []
    donors = {}          # n_frames -> {name, data, guids}
    if not os.path.isdir(sprites_dir):
        print('ERROR: no existe la carpeta de sprites:', sprites_dir)
        return rows, donors
    for n in sorted(os.listdir(sprites_dir)):
        sd = os.path.join(sprites_dir, n)
        yy = os.path.join(sd, n + '.yy')
        if not os.path.isdir(sd) or not os.path.isfile(yy):
            continue
        try:
            d = gm_loads(read_text(yy))
        except Exception as e:
            rows.append((n, '?', '?', '?', 'JSON ROTO: ' + str(e)[:60]))
            continue
        try:
            fr = frames_list(d)
            guids = [frame_guid(f) for f in fr]
            ok = sum(1 for g in guids if g)
            comps = sum(1 for f in fr if isinstance(f, dict)
                        and (isinstance(f.get('Composite'), dict) or f.get('composite')))
            layers = d.get('layers')
            nl = len(layers) if isinstance(layers, list) else 0
            if d.get('resourceType') != 'GMSprite':
                nota = 'ATENCION: resourceType != GMSprite'
            elif fr and ok != len(fr):
                nota = 'ATENCION: frames con formato desconocido'
            else:
                nota = 'ok'
            if (nota == 'ok' and n not in targets and fr
                    and isinstance(d.get('sequence'), dict)
                    and isinstance(d.get('layers'), list)
                    and len(fr) not in donors):
                donors[len(fr)] = {'name': n, 'data': d,
                                   'guids': [g for g in guids if g]}
            rows.append((n, str(len(fr)), str(nl), str(comps), nota))
        except Exception as e:
            rows.append((n, '?', '?', '?', 'error: ' + str(e)[:60]))
    return rows, donors


def pick_donor(donors, n):
    if n in donors:
        return donors[n]
    if donors:
        best = None
        for c in sorted(donors):
            if c >= n:
                best = c
                break
        if best is None:
            best = sorted(donors)[-1]
        return donors[best]
    return {'name': None, 'data': copy.deepcopy(TEMPLATE), 'guids': []}


# ---------------------- construccion de piezas ----------------------

def swap_strings(obj, smap):
    """Reemplazo profundo de strings exactos (nombres, rutas, GUIDs)."""
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            nk = smap.get(k, k) if isinstance(k, str) else k
            out[nk] = swap_strings(v, smap)
        return out
    if isinstance(obj, list):
        return [swap_strings(v, smap) for v in obj]
    if isinstance(obj, str):
        return smap.get(obj, obj)
    return obj


def build_frames(tmpl_frames, guids, target_name, target_path):
    tmpl = next((f for f in tmpl_frames if isinstance(f, dict)), {})
    out = []
    for g in guids:
        fr = copy.deepcopy(tmpl)
        wrote = False
        for k in ('name', '%Name'):
            if k in fr:
                fr[k] = g
                wrote = True
        if isinstance(fr.get('id'), str):
            fr['id'] = g
            wrote = True
        if not wrote:
            fr['name'] = g
        if isinstance(fr.get('images'), list):
            fr['images'] = []
        fr.pop('Composite', None)
        fr.pop('composite', None)
        fr['parent'] = {'name': target_name, 'path': target_path}
        fr.setdefault('resourceVersion', '1.0')
        fr.setdefault('resourceType', 'GMSpriteFrame')
        fr.setdefault('tags', [])
        out.append(fr)
    return out


def build_keyframes(tmpl_kfs, guids, target_path):
    tmpl = copy.deepcopy(tmpl_kfs[0]) if tmpl_kfs else {}
    out = []
    for i, g in enumerate(guids):
        kf = copy.deepcopy(tmpl)
        kf['id'] = str(uuid.uuid4())
        kf['Key'] = float(i)
        kf['Length'] = 1.0
        kf.setdefault('Stretch', False)
        kf.setdefault('Disabled', False)
        kf.setdefault('IsCreationKey', False)
        chans = kf.get('Channels') if isinstance(kf.get('Channels'), dict) else {}
        ch0 = copy.deepcopy(chans['0']) if isinstance(chans.get('0'), dict) else {}
        ch0['Id'] = {'name': g, 'path': target_path}
        ch0.setdefault('resourceVersion', '1.0')
        ch0.setdefault('resourceType', 'SpriteFrameKeyframe')
        kf['Channels'] = {'0': ch0}
        kf.setdefault('resourceVersion', '1.0')
        kf.setdefault('resourceType', 'Keyframe<SpriteFrameKeyframe>')
        out.append(kf)
    return out


# ---------------------- reparacion de un sprite ----------------------

def repair_target(name, root, sprites_dir, donors, stamp):
    tdir = os.path.join(sprites_dir, name)
    yy = os.path.join(tdir, name + '.yy')
    if not os.path.isdir(tdir):
        return 'SKIP: no existe la carpeta ' + tdir
    pngs = [f for f in os.listdir(tdir)
            if f.lower().endswith('.png') and 'composite' not in f.lower()]
    if not pngs:
        return 'SKIP: la carpeta no tiene PNGs de frames'

    # datos del archivo roto (si se pueden leer)
    broken = None
    if os.path.isfile(yy):
        try:
            broken = gm_loads(read_text(yy))
        except Exception:
            broken = None

    # orden de los frames
    png_base = [os.path.splitext(p)[0] for p in sorted(pngs)]
    order = list(png_base)
    order_src = 'orden alfabetico'
    if isinstance(broken, dict):
        have = [frame_guid(f) for f in frames_list(broken)]
        have = [g for g in have if g in set(png_base)]
        if have:
            rest = [b for b in png_base if b not in set(have)]
            order = have + rest
            order_src = 'orden del .yy original'
    else:
        try:
            times = {p: os.path.getmtime(os.path.join(tdir, p)) for p in pngs}
            if len(set(times.values())) > 1:
                order = [os.path.splitext(p)[0]
                         for p in sorted(pngs, key=lambda p: times[p])]
                order_src = 'fecha de los PNG'
        except OSError:
            pass
    guids = order

    # tamanio de los PNGs (todos deberian coincidir)
    first_size = None
    mism = False
    for b in order:
        s = png_size(os.path.join(tdir, b + '.png'))
        if s is None:
            continue
        if first_size is None:
            first_size = s
        elif s != first_size:
            mism = True
    if first_size is None:
        return 'SKIP: no pude leer el tamanio de los PNGs'
    w, h = first_size

    tpath = 'sprites/' + name + '/' + name + '.yy'
    donor = pick_donor(donors, len(guids))
    dname = donor['name']
    nd = copy.deepcopy(donor['data'])

    # reemplazo de referencias (nombre, ruta, GUIDs de frames)
    smap = {}
    if dname:
        smap[dname] = name
        smap['sprites/' + dname + '/' + dname + '.yy'] = tpath
        for i, g in enumerate(donor['guids']):
            if i < len(guids):
                smap[g] = guids[i]
    nd = swap_strings(nd, smap)

    # asegurar sequence
    if not isinstance(nd.get('sequence'), dict):
        nd['sequence'] = {}
    seq = nd['sequence']

    # conservar del roto lo recuperable
    if isinstance(broken, dict):
        for k in ('bboxMode', 'collisionKind', 'type', 'origin', 'xorigin', 'yorigin',
                  'preMultiplyAlpha', 'edgeFiltering', 'collisionTolerance',
                  'swfPrecision', 'HTile', 'VTile', 'For3D', 'textureGroupId',
                  'textureGroup', 'playbackSpeedType', 'autoRecord', 'volume'):
            if k in broken:
                nd[k] = broken[k]
        if isinstance(broken.get('parent'), dict):
            nd['parent'] = broken['parent']
        bseq = broken.get('sequence')
        if isinstance(bseq, dict):
            for k in ('playbackSpeed', 'playbackSpeedType', 'timeUnits', 'playback'):
                if k in bseq:
                    seq[k] = bseq[k]

    # campos basicos
    nd['name'] = name
    nd['width'] = w
    nd['height'] = h
    nd['bbox_left'] = 0
    nd['bbox_top'] = 0
    nd['bbox_right'] = w - 1
    nd['bbox_bottom'] = h - 1

    # origen: centrado segun el preset si no se recupero del roto
    if not (isinstance(broken, dict) and 'xorigin' in broken):
        if 'xorigin' in nd or 'yorigin' in nd:
            preset = nd.get('origin', 4)
            bl, bt = nd['bbox_left'], nd['bbox_top']
            br, bb = nd['bbox_right'], nd['bbox_bottom']
            cx, cy = (bl + br) // 2, (bt + bb) // 2
            m = {0: (bl, bt), 1: (cx, bt), 2: (br, bt), 3: (bl, cy), 4: (cx, cy),
                 5: (br, cy), 6: (bl, bb), 7: (cx, bb), 8: (br, bb)}
            ox, oy = m.get(preset, (cx, cy))
            if 'xorigin' in nd:
                nd['xorigin'] = ox
            if 'yorigin' in nd:
                nd['yorigin'] = oy

    # sequence completo
    seq['name'] = name
    seq['spriteId'] = {'name': name, 'path': tpath}
    seq['length'] = float(len(guids))
    seq.setdefault('timeUnits', 1)
    seq.setdefault('playback', 1)
    seq.setdefault('playbackSpeed', 15.0)
    seq.setdefault('playbackSpeedType', 0)
    seq.setdefault('autoRecord', True)
    seq.setdefault('volume', 1.0)
    seq.setdefault('visible', True)
    seq.setdefault('locked', False)
    seq.setdefault('resourceVersion', '1.0')
    seq.setdefault('tags', [])
    seq['resourceType'] = 'GMSequence'
    for key, rt in (('events', 'KeyframeStore<MessageEventKeyframe>'),
                    ('moments', 'KeyframeStore<MomentsEventKeyframe>')):
        st = seq.get(key)
        if not isinstance(st, dict):
            st = {}
            seq[key] = st
        if not isinstance(st.get('Keyframes'), list):
            st['Keyframes'] = []
        st.setdefault('resourceVersion', '1.0')
        st['resourceType'] = rt

    # track "frames" con su KeyframeStore
    store = None
    tracks = seq.get('tracks')
    if isinstance(tracks, list):
        for tr in tracks:
            if isinstance(tr, dict) and isinstance(tr.get('keyframes'), dict):
                store = tr['keyframes']
                tr.setdefault('name', 'frames')
                tr.setdefault('spriteId', None)
                tr.setdefault('resourceVersion', '1.0')
                tr.setdefault('tags', [])
                if not tr.get('resourceType'):
                    tr['resourceType'] = 'GMSequenceTrack'
                break
    if store is None:
        store = {'Keyframes': [], 'resourceVersion': '1.0',
                 'resourceType': 'KeyframeStore<SpriteFrameKeyframe>'}
        seq['tracks'] = [{'name': 'frames', 'spriteId': None, 'keyframes': store,
                          'resourceVersion': '1.0', 'tags': [],
                          'resourceType': 'GMSequenceTrack'}]
    store.setdefault('resourceVersion', '1.0')
    if not store.get('resourceType'):
        store['resourceType'] = 'KeyframeStore<SpriteFrameKeyframe>'

    # frames y keyframes: si el donor tenia el mismo numero de frames ya
    # quedaron bien tras el swap; si no, se reconstruyen
    dfr = frames_list(donor['data'])
    if len(dfr) != len(guids):
        nd['frames'] = build_frames(dfr, guids, name, tpath)
    kfs = store.get('Keyframes')
    if not isinstance(kfs, list) or len(kfs) != len(guids):
        store['Keyframes'] = build_keyframes(kfs or [], guids, tpath)

    # layers
    if not isinstance(nd.get('layers'), list) or not nd['layers']:
        nd['layers'] = [{'visible': True, 'isLocked': False, 'blendMode': 0,
                         'opacity': 100.0, 'displayName': 'default',
                         'resourceVersion': '1.0', 'name': 'default', 'tags': [],
                         'resourceType': 'GMImageLayer'}]
    else:
        for lay in nd['layers']:
            if isinstance(lay, dict):
                lay.setdefault('resourceType', 'GMImageLayer')
                lay.setdefault('resourceVersion', '1.0')

    nd['resourceVersion'] = nd.get('resourceVersion') or '1.0'
    nd['resourceType'] = 'GMSprite'
    nd.setdefault('tags', [])

    # copia de seguridad y escritura
    bfile = None
    if os.path.isfile(yy):
        bdir = os.path.join(root, BACKUP_DIR, name)
        os.makedirs(bdir, exist_ok=True)
        bfile = os.path.join(bdir, name + '.yy.' + stamp)
        shutil.copy2(yy, bfile)
    with open(yy, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(nd, f, indent=4, ensure_ascii=False)
        f.write('\n')

    # verificacion post-escritura
    try:
        check = gm_loads(read_text(yy))
        if (not isinstance(check, dict)
                or check.get('resourceType') != 'GMSprite'
                or len(frames_list(check)) != len(guids)):
            raise ValueError('estructura inesperada')
    except Exception as e:
        if bfile and os.path.isfile(bfile):
            shutil.copy2(bfile, yy)
        else:
            try:
                os.remove(yy)
            except OSError:
                pass
        return 'ERROR al verificar (%s); original restaurado' % e

    msg = 'REPARADO: %d frames %dx%d, orden=%s, plantilla=%s' % (
        len(guids), w, h, order_src, dname or 'plantilla interna')
    if mism:
        msg += '  [AVISO: los PNG no tienen todos el mismo tamanio]'
    if order_src != 'orden del .yy original':
        msg += '  [revisa el orden de frames en el editor]'
    return msg


# ---------------------- verificacion del .yyp ----------------------

def check_yyp(root, targets, stamp):
    yyps = [f for f in os.listdir(root) if f.lower().endswith('.yyp')]
    if not yyps:
        return 'AVISO: no encontre el .yyp en ' + root
    p = os.path.join(root, yyps[0])
    try:
        d = gm_loads(read_text(p))
    except Exception as e:
        return 'AVISO: no pude leer el .yyp (%s)' % str(e)[:60]
    res = d.get('Resources')
    if not isinstance(res, list):
        return 'AVISO: .yyp sin lista Resources'
    have = {}
    for r in res:
        if isinstance(r, dict) and isinstance(r.get('id'), dict):
            have[r['id'].get('name')] = r
    changed = False
    for t in targets:
        want = 'sprites/' + t + '/' + t + '.yy'
        e = have.get(t)
        if e is None:
            res.append({'id': {'name': t, 'path': want}, 'Order': len(res)})
            changed = True
            print('  entrada agregada al .yyp:', t)
        elif e['id'].get('path') != want:
            print('  ruta corregida en .yyp:', t, '->', want)
            e['id']['path'] = want
            changed = True
    if changed:
        bdir = os.path.join(root, BACKUP_DIR)
        os.makedirs(bdir, exist_ok=True)
        shutil.copy2(p, os.path.join(bdir, yyps[0] + '.' + stamp))
        with open(p, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(d, f, indent=4, ensure_ascii=False)
            f.write('\n')
        return '.yyp actualizado (copia previa en ' + BACKUP_DIR + ')'
    return '.yyp OK: los sprites ya estaban referenciados'


# ---------------------- main ----------------------

def main(argv):
    root = os.path.abspath(argv[1] if len(argv) > 1 else '.')
    targets = list(argv[2:]) or list(DEFAULT_TARGETS)
    sprites_dir = os.path.join(root, 'sprites')
    stamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    print('Proyecto :', root)
    print('Objetivos:', ', '.join(targets))
    print()
    print('== AUDITORIA DE SPRITES ==')
    rows, donors = audit(sprites_dir, targets)
    audit_path = os.path.join(root, 'audit_sprites.txt')
    with open(audit_path, 'w', encoding='utf-8') as f:
        f.write('%-34s %6s %6s %5s  %s\n'
                % ('sprite', 'frames', 'layers', 'comps', 'nota'))
        for r in rows:
            f.write('%-34s %6s %6s %5s  %s\n' % (r[0][:34], r[1], r[2], r[3], r[4]))
    print('Sprites auditados: %d   Plantillas sanas: %d'
          % (len(rows), len(donors)))
    print('Tabla completa en:', audit_path)
    tset = set(targets)
    shown = 0
    for r in rows:
        if r[0] in tset or r[4] != 'ok':
            print('%-34s %6s %6s %5s  %s' % (r[0][:34], r[1], r[2], r[3], r[4]))
            shown += 1
    if not shown:
        print('(todos los sprites estan ok)')

    print()
    print('== REPARACION ==')
    for t in targets:
        try:
            msg = repair_target(t, root, sprites_dir, donors, stamp)
        except Exception as e:
            msg = 'ERROR %s: %s' % (type(e).__name__, e)
        print('%-20s %s' % (t, msg))

    print()
    print('== .YYP ==')
    print(check_yyp(root, targets, stamp))
    print()
    print('Listo. Copias de seguridad en ' + BACKUP_DIR + '/.')
    print('Abre GameMaker Studio 2 y verifica los sprites reparados.')


if __name__ == '__main__':
    main(sys.argv)