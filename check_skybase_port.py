#!/usr/bin/env python3
"""Valida el porte SkyBase: sintaxis yy, referencias cruzadas, integridad vs dump del mod."""
import json, os, re, glob, sys

import os as _os
HERE = _os.path.dirname(_os.path.abspath(__file__)) or '.'
REPO = HERE
ok = fail = 0
def check(cond, msg):
    global ok, fail
    if cond: ok += 1
    else:
        fail += 1
        print('  FALLO:', msg)

def gmload(p):
    src = open(p, encoding='utf-8').read()
    src = re.sub(r',(\s*[}\]])', r'\1', src)
    return json.loads(src)

# 1. sintaxis de todos los yy nuevos
print('== 1. sintaxis .yy nuevos ==')
new_yys = []
for pat in ['sprites/*skybase*/*.yy', 'sprites/background_skybase*/*.yy',
            'objects/obj_skybase_*/*.yy', 'sounds/*skybase*/*.yy', 'rooms/room_skybase/*.yy']:
    for p in glob.glob(os.path.join(REPO, pat)):
        if p not in new_yys: new_yys.append(p)
check(len(new_yys) == 17, f'17 .yy esperados (15 V1 + 2 previews V2), hay {len(new_yys)}')
for p in new_yys:
    try:
        gmload(p)
        check(True, '')
    except Exception as e:
        check(False, f'{p}: {e}')

# 2. room: capas e instancias
print('== 2. room_skybase ==')
room = gmload(os.path.join(REPO, 'rooms/room_skybase/room_skybase.yy'))
check(room['name'] == 'room_skybase', 'nombre room')
check(room.get('isDnd') == False, 'campo raiz "isDnd" presente y false (bug del fix GM: sin el, el IDE no carga el proyecto)')
check(room['roomSettings']['Width'] == 3500 and room['roomSettings']['Height'] == 1500, 'dimensiones 3500x1500')
check(len(room['layers']) == 8, f"8 capas, hay {len(room['layers'])}")
check(len(room['instanceCreationOrder']) == 130, f"creation order 130, hay {len(room['instanceCreationOrder'])}")
layers = {l['%Name']: l for l in room['layers']}
check(set(layers) == {'Assets_2','Collisions','Instances','Assets_1','Background3','Background2','Background1','Background'}, 'nombres de capas')
depths = {n: l['depth'] for n, l in layers.items()}
check(depths == {'Assets_2':-200,'Collisions':-100,'Instances':0,'Assets_1':100,'Background3':200,'Background2':300,'Background1':400,'Background':500}, f'depths: {depths}')
n_inst = len(layers['Collisions']['instances']) + len(layers['Instances']['instances'])
check(n_inst == 130, f"instancias 130, hay {n_inst}")
check(len(layers['Collisions']['instances']) == 70, f"collisions 70, hay {len(layers['Collisions']['instances'])}")
check(len(layers['Instances']['instances']) == 60, f"instances 60, hay {len(layers['Instances']['instances'])}")
check(len(layers['Assets_2']['assets']) == 7, f"assets_2 7, hay {len(layers['Assets_2']['assets'])}")
check(len(layers['Assets_1']['assets']) == 4, f"assets_1 4, hay {len(layers['Assets_1']['assets'])}")
# orden de capas por depth ascendente
ds = [l['depth'] for l in room['layers']]
check(ds == sorted(ds), 'capas en depth ascendente')

# 3. todos los objectId del room existen en el proyecto
print('== 3. referencias del room ==')
objs_used = set()
for lname in ('Collisions', 'Instances'):
    for i in layers[lname]['instances']:
        objs_used.add(i['objectId']['name'])
        p = os.path.join(REPO, 'objects', i['objectId']['name'], i['objectId']['name'] + '.yy')
        check(os.path.exists(p), f"no existe objeto {i['objectId']['name']}")
for lname in ('Assets_1', 'Assets_2'):
    for g in layers[lname]['assets']:
        sp = os.path.join(REPO, 'sprites', g['spriteId']['name'], g['spriteId']['name'] + '.yy')
        check(os.path.exists(sp), f"no existe sprite {g['spriteId']['name']}")
for lname in ('Background1', 'Background2', 'Background3'):
    sid = layers[lname]['spriteId']
    p = os.path.join(REPO, 'sprites', sid['name'], sid['name'] + '.yy')
    check(os.path.exists(p), f"no existe sprite bg {sid['name']}")
print('  objetos usados:', ', '.join(sorted(objs_used)))
# objetos custom presentes
for o in ['obj_skybase_pillar', 'obj_skybase_slope']:
    check(o in objs_used, f'{o} no esta en el room')

# 4. verificacion 1:1 contra el dump del mod
print('== 4. contenido 1:1 vs dump del mod ==')
detail = None
for cand in [_os.path.join(HERE, 'docs', 'skybase_room_detail.txt'),
             _os.path.join(HERE, 'skybase_room_detail.txt'),
             '/home/z/my-project/skybase/skybase_room_detail.txt']:
    if _os.path.exists(cand):
        detail = open(cand, encoding='utf-8').read()
        print(f'  dump 1:1: {cand}')
        break
HAVE_DUMP = detail is not None
if not HAVE_DUMP:
    print('  AVISO: dump del mod no encontrado; se omite la comparacion 1:1')
    detail = ''
mod_insts = []
for line in detail.splitlines():
    mi = re.match(r'\s*INST id=(\d+) obj=(\S+) x=(-?\d+) y=(-?\d+) sx=(-?[\d.]+) sy=(-?[\d.]+)', line)
    if mi:
        mod_insts.append(mi.groups())
if HAVE_DUMP: check(len(mod_insts) == 130, f'dump 130 inst, hay {len(mod_insts)}')
port_insts = {}
for lname in ('Collisions', 'Instances'):
    for i in layers[lname]['instances']:
        port_insts[i['%Name']] = (i['objectId']['name'], i['x'], i['y'], i['scaleX'], i['scaleY'])
mism = 0
for (iid, obj, x, y, sx, sy) in (mod_insts if HAVE_DUMP else []):
    key = f'inst_{iid}'
    pi = port_insts.get(key)
    if pi is None:
        mism += 1; print(f"  FALTA {key}"); continue
    if not (pi[0] == obj and pi[1] == float(x) and pi[2] == float(y) and abs(pi[3]-float(sx)) < 1e-6 and abs(pi[4]-float(sy)) < 1e-6):
        mism += 1; print(f"  DIFIERE {key}: mod={obj},{x},{y},{sx},{sy} port={pi}")
if HAVE_DUMP: check(mism == 0, f'{mism} instancias difieren del dump')
# el slope espejado conserva -1
mir = port_insts.get('inst_104840')
check(mir is not None and mir[3] == -1.0, f'slope espejado sx=-1: {mir}')

# 5. sprites: frames PNG existen
print('== 5. sprites ==')
SPRITES = ['spr_skybase_tiles','background_skybase1','background_skybase2','background_skybase3',
           'spr_skybase_propeller','spr_skybase_myhole','spr_skybase_telepod',
           'spr_skybase_pillar','spr_skybase_slope']
expected_frames = {'spr_skybase_tiles':2,'spr_skybase_propeller':4,'spr_skybase_telepod':4}
for s in SPRITES:
    d = gmload(os.path.join(REPO, 'sprites', s, s + '.yy'))
    files = set(os.listdir(os.path.join(REPO, 'sprites', s)))
    for fr in d['frames']:
        check(fr['name'] + '.png' in files, f"{s}: falta frame {fr['name']}")
    exp = expected_frames.get(s, 1)
    check(len(d['frames']) == exp, f"{s}: {len(d['frames'])} frames, esperaba {exp}")
    check(d['textureGroupId']['name'] == 'SkyBase', f"{s}: textureGroup")
    check(d['parent']['path'] == 'folders/Sprites/Zones/SkyBase.yy', f"{s}: parent folder")
# slope con colision precisa
slope = gmload(os.path.join(REPO, 'sprites', 'spr_skybase_slope', 'spr_skybase_slope.yy'))
check(slope['collisionKind'] == 2, 'slope collisionKind 2 (precisa)')
check(slope['bbox_left']==0 and slope['bbox_right']==118 and slope['bbox_top']==0 and slope['bbox_bottom']==71, f"slope bbox {slope['bbox_left']},{slope['bbox_top']},{slope['bbox_right']},{slope['bbox_bottom']}")
# png de slope: no vacio
from PIL import Image
img = Image.open(os.path.join(REPO, 'sprites', 'spr_skybase_slope', slope['frames'][0]['name'] + '.png'))
check(img.size == (119, 72), f"slope png {img.size}")
# tiles: 2 frames con dimensiones
tiles = gmload(os.path.join(REPO, 'sprites', 'spr_skybase_tiles', 'spr_skybase_tiles.yy'))
check(tiles['width'] == 1750 and tiles['height'] == 1500, 'tiles 1750x1500')
for fr in tiles['frames']:
    im = Image.open(os.path.join(REPO, 'sprites', 'spr_skybase_tiles', fr['name'] + '.png'))
    check(im.size == (1750, 1500), f"tiles frame {im.size}")

# 6. objetos
print('== 6. objetos ==')
op = gmload(os.path.join(REPO, 'objects', 'obj_skybase_pillar', 'obj_skybase_pillar.yy'))
check(op['parentObjectId']['name'] == 'obj_hiding_parent', 'pillar parent')
check(op['spriteId']['name'] == 'spr_skybase_pillar', 'pillar sprite')
check(op['eventList'] == [], 'pillar sin eventos')
oslope = gmload(os.path.join(REPO, 'objects', 'obj_skybase_slope', 'obj_skybase_slope.yy'))
check(oslope['parentObjectId']['name'] == 'obj_solid_block', 'slope parent')
check(oslope['spriteId']['name'] == 'spr_skybase_slope', 'slope sprite')
for name, path in [('obj_hiding_parent','objects/obj_hiding_parent/obj_hiding_parent.yy'), ('obj_solid_block','objects/obj_solid_block/obj_solid_block.yy')]:
    check(os.path.exists(os.path.join(REPO, path)), f'parent {name} existe')

# 7. sonidos
print('== 7. sonidos ==')
for name, fn in [('mus_skybase','mus_skybase.ogg'),('mus_skybase_chase','mus_skybase_chase.ogg'),('snd_skybase_target','snd_skybase_target.wav')]:
    d = os.path.join(REPO, 'sounds', name)
    yy = gmload(os.path.join(d, name + '.yy'))
    check(os.path.exists(os.path.join(d, fn)), f'{name}/{fn} existe')
    check(yy['soundFile'] == fn, f'{name}: soundFile')
mus = gmload(os.path.join(REPO, 'sounds', 'mus_skybase', 'mus_skybase.yy'))
check(mus['channelFormat'] == 1 and mus['compression'] == 3, 'mus_skybase stereo/comp3')
check(mus['parent']['path'] == 'folders/Sounds/Music.yy', 'mus_skybase parent Music')
snd = gmload(os.path.join(REPO, 'sounds', 'snd_skybase_target', 'snd_skybase_target.yy'))
check(snd['channelFormat'] == 0 and snd['compression'] == 0, 'snd mono/comp0')
import wave
w = wave.open(os.path.join(REPO, 'sounds', 'snd_skybase_target', 'snd_skybase_target.wav'))
check(w.getnchannels() == 1 and w.getframerate() == 44100, 'wav mono 44100')

# 8. yyp
print('== 8. .yyp ==')
yyp = json.load(open(os.path.join(REPO, 'Sonicexe The Disaster 2D Remake.yyp'), encoding='utf-8'))
res = {r['id']['name'] for r in yyp['resources']}
for n in SPRITES + ['obj_skybase_pillar','obj_skybase_slope','mus_skybase','mus_skybase_chase','snd_skybase_target','room_skybase','spr_pr_skybase','spr_pr_skybasebg']:
    check(n in res, f'{n} no esta en yyp resources')
ron = yyp['RoomOrderNodes']
check(any(n['roomId']['name'] == 'room_skybase' for n in ron), 'room_skybase en RoomOrderNodes')
check(ron[-1]['roomId']['name'] == 'room_skybase', 'room_skybase es el ultimo en RoomOrder')
check(len(ron) == 33, f'33 roomorder nodes, hay {len(ron)}')
folders = {f['folderPath'] for f in yyp['Folders']}
check('folders/Sprites/Zones/SkyBase.yy' in folders, 'folder sprites SkyBase')
check('folders/Objects/Game Objects/Level Specific/SkyBase.yy' in folders, 'folder objetos SkyBase')
tg = {t['name'] for t in yyp['TextureGroups']}
check('SkyBase' in tg, 'texturegroup SkyBase')
tgs = next(t for t in yyp['TextureGroups'] if t['name'] == 'SkyBase')
check(tgs['autocrop'] == True, 'SkyBase autocrop true')
# sin duplicados en resources
names = [r['id']['name'] for r in yyp['resources']]
check(len(names) == len(set(names)), 'sin duplicados en resources')
check(len(names) == 2073, f'resources total 2073 (2056 base + 15 V1 + 2 preview V2), hay {len(names)}')
# todos los resources nuevos tienen archivo
for r in yyp['resources'][-17:]:
    check(os.path.exists(os.path.join(REPO, r['id']['path'])), f"falta {r['id']['path']}")

# 9. INCLUIDO en la seleccion (v2: el usuario aprobo el mapa)
print('== 9. INCLUIDO en seleccion (indice 21, listas 22/22) ==')
sg = open(os.path.join(REPO, 'scripts/scr_globals/scr_globals.gml'), encoding='utf-8').read()
n_lev = len(re.findall(r'\{ group: "', sg))
lev_arr = re.search(r'global\.levelDescriptions =\s*\[(.*?)\n\];', sg, re.S).group(1)
n_desc = len(re.findall(r'^\s+"', lev_arr, re.M))
check(n_lev == 22, f'global.levels 22 entradas, hay {n_lev}')
check(n_desc == 22, f'levelDescriptions 22 entradas, hay {n_desc}')
check('"SkyBase"' in sg and 'rid: room_skybase' in sg, 'levels[21] = SkyBase/room_skybase')
check('floating base above the clouds' in sg, 'descripcion [21] presente')
# alineacion critica (el bug del crash de los SMax): descriptions >= levels
check(n_desc >= n_lev, 'levelDescriptions nunca mas corta que levels (bug RETIRA SMAX)')
lobby = open(os.path.join(REPO, 'objects/obj_lobby_prolet/Create_0.gml'), encoding='utf-8').read()
n_map = len(re.findall(r'\{ tiles: \[', lobby))
check(n_map == 22, f'mapData 22 entradas, hay {n_map}')
check('spr_pr_skybase' in lobby and 'spr_pr_skybasebg' in lobby, 'mapData[21] previews skybase')
mh = open(os.path.join(REPO, 'betterserver-oss/include/Maps.h'), encoding='utf-8').read()
m = re.search(r'#define MAP_COUNT (\d+)', mh)
check(m and m.group(1) == '22', f'MAP_COUNT 22: {m.group(1) if m else "?"}')
mc = open(os.path.join(REPO, 'betterserver-oss/disasterserver/Maps.c'), encoding='utf-8').read()
n_gm = len(re.findall(r'\{ CLRCODE_', mc))
check(n_gm == 22, f'g_mapList 22 entradas, hay {n_gm}')
check('"SkyBase"' in mc and re.search(r'\{ map_init, map_tick, map_tcpmsg, map_left \}, 1, 12 \}, //21', mc), 'entrada //21 SkyBase generica ring_count 12')
zh = open(os.path.join(REPO, 'betterserver-oss/include/Zone.h'), encoding='utf-8').read()
check('g_mapZone[22]' in zh and 'g_mapZoneSize[22]' in zh, 'Zone.h arrays [22]')
zc = open(os.path.join(REPO, 'betterserver-oss/disasterserver/Zone.c'), encoding='utf-8').read()
check('Zone room_skybase[] =' in zc, 'Zone.c room_skybase[] definida')
check(zc.count('room_skybase') == 3, 'Zone.c room_skybase en array + 2 listas')
nz = len(re.findall(r'^ \{ .*BLOCK_SIZE.*\},$', re.search(r'Zone room_skybase\[\] =\s*\{(.*?)\n\};', zc, re.S).group(1), re.M))
check(nz == 40, f'40 zonas anticheat (40 solidos 1:1), hay {nz}')
zh_ok = re.search(r'g_mapZone\[22\] =\s*\{(.*?)\n\};', zc, re.S).group(1)
check(zh_ok.rstrip().endswith('room_skybase'), 'g_mapZone[21] = room_skybase (ultimo)')
ch = open(os.path.join(REPO, 'betterserver-oss/include/Config.h'), encoding='utf-8').read()
check('map_list[22]' in ch, 'Config.h map_list[22]')
cc = open(os.path.join(REPO, 'betterserver-oss/disasterserver/Config.c'), encoding='utf-8').read()
mlm = re.search(r'\.map_list = \{ ([^}]*)\}', cc)
bools = [b.strip() for b in mlm.group(1).split(',') if b.strip()]
check(len(bools) == 22, f'Config.c defaults 22 bools, hay {len(bools)}')
check(bools[20] == 'false' and bools[21] == 'true', 'Fart [20] fuera del voto, SkyBase [21] activo')
# Lobby.c/Server.c usan MAP_COUNT dinamico en el texto -> no requieren edicion
lc = open(os.path.join(REPO, 'betterserver-oss/disasterserver/states/Lobby.c'), encoding='utf-8').read()
check('between 1 and %d", MAP_COUNT' in lc, 'texto .map sigue dinamico con MAP_COUNT')

# 9b. assets de inclusion: previews prolet + icono mapvote
print('== 9b. assets de inclusion ==')
for s, w, h in [('spr_pr_skybase', 630, 270), ('spr_pr_skybasebg', 512, 288)]:
    d = gmload(os.path.join(REPO, 'sprites', s, s + '.yy'))
    check(d['width'] == w and d['height'] == h, f'{s} {w}x{h}')
    check(d['textureGroupId']['name'] == 'Prolet', f'{s} textureGroup Prolet')
    check(d['parent']['path'] == 'folders/Sprites/Zones/Prolety.yy', f'{s} parent Prolety')
    for fr in d['frames']:
        check(os.path.exists(os.path.join(REPO, 'sprites', s, fr['name'] + '.png')), f'{s} frame png')
    im = Image.open(os.path.join(REPO, 'sprites', s, d['frames'][0]['name'] + '.png'))
    check(im.size == (w, h), f'{s} png {im.size}')
# icono del mapvote: frame 21 reutilizado (antes SMax GH huerfano, naranja plano)
mv = gmload(os.path.join(REPO, 'sprites/spr_mapvote/spr_mapvote.yy'))
check(len(mv['frames']) == 23, 'spr_mapvote 23 frames (sin tocar el .yy)')
g21 = mv['frames'][21]['name']
im = Image.open(os.path.join(REPO, 'sprites/spr_mapvote', g21 + '.png')).convert('RGBA')
check(im.size == (123, 104), f'icono mapvote 123x104: {im.size}')
check(im.getpixel((0, 0))[3] == 0 and im.getpixel((122, 0))[3] == 0, 'icono esquinas transparentes (ya no el naranja SMax)')
check(im.getpixel((60, 50))[3] == 255, 'icono banda central opaca')
# banda = crop real del mapa (variacion de color, no color plano)
cols = {im.getpixel((x, y))[:3] for x in range(10, 113, 7) for y in range(12, 84, 6)}
check(len(cols) > 20, f'icono con contenido variado del mapa: {len(cols)} colores')

# 10. RoomCreationCode
print('== 10. RoomCreationCode ==')
rcc = open(os.path.join(REPO, 'rooms/room_skybase/RoomCreationCode.gml'), encoding='utf-8').read()
check('scr_play_music(mus_skybase)' in rcc, 'musica skybase')
check('scr_level_split(spr_skybase_tiles, 110)' in rcc, 'level_split tiles')
check('layer_get_id("Background3")' in rcc and 'layer_get_id("Background1")' in rcc, 'parallax 3 capas')
# referencias del rcc existen
check('mus_skybase' in res and 'spr_skybase_tiles' in res, 'assets del rcc registrados')
# RoomCreationCode no oculta capa Guide (skybase no tiene capa Guide)
check('layer_set_visible' not in rcc, 'rcc sin restos de capa Guide (skybase no la tiene)')

print(f'\nRESULTADO: {ok} OK, {fail} FALLOS')
sys.exit(1 if fail else 0)
