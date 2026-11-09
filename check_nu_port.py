#!/usr/bin/env python3
"""check_nu_port.py — validacion integral del porte Negagen Temple (NU Project).

Verifica: assets creados y referenciados, room 1:1 vs el dump del mod,
seleccion alineada 22/23 en las 7 listas (cliente+server), sintaxis,
referencias de carpetas del .yyp, y PNGs de frames.
"""
import json, re, os, subprocess, sys

REPO = '/home/z/my-project/repo-disaster2d/'
NU = '/home/z/my-project/nuproj/'
BS = REPO + 'betterserver-oss/'
ok = fail = 0

def chk(cond, name, detail=''):
    global ok, fail
    if cond:
        ok += 1
        print(f'  OK   {name}')
    else:
        fail += 1
        print(f'  FAIL {name} {detail}')

def gmload(p):
    src = open(p, encoding='utf-8').read()
    return json.loads(re.sub(r',(\s*[}\]])', r'\1', src))

print('== 1. sprites/sonidos/objetos nuevos ==')
SPRITES = ['spr_nt_tiles', 'spr_nt_tiles2', 'spr_nt_tiles3', 'spr_bg_nt', 'spr_bg_nt2',
           'statui', 'spr_dusha', 'spr_dusha2', 'spr_femboy', 'spr_negatv',
           'spr_pr_nt_tile', 'spr_pr_nt_tile2', 'spr_pr_nt_tile3', 'spr_pr_bg_nt']
for s in SPRITES:
    d = REPO + f'sprites/{s}'
    yy = gmload(f'{d}/{s}.yy')
    npng = len([f for f in os.listdir(d) if f.endswith('.png')])
    guids = {fr['name'] for fr in yy['frames']}
    png_ok = all(os.path.exists(f'{d}/{g}.png') for g in guids)
    orphans = [f for f in os.listdir(d) if f.endswith('.png') and f[:-4] not in guids]
    chk(npng == len(yy['frames']) and png_ok and not orphans,
        f'sprite {s}', f'frames={len(yy["frames"])} pngs={npng} huerfanos={orphans}')

from PIL import Image
# tamanos exactos de frames
EXPECT = {'spr_nt_tiles': (1072, 1536, 3), 'spr_nt_tiles2': (1072, 1536, 3),
          'spr_nt_tiles3': (1072, 1536, 3), 'spr_bg_nt': (416, 128, 1),
          'spr_bg_nt2': (440, 32, 1), 'statui': (46, 59, 7),
          'spr_dusha': (61, 12, 24), 'spr_dusha2': (47, 47, 24),
          'spr_femboy': (37, 35, 22), 'spr_negatv': (173, 98, 1),
          'spr_pr_nt_tile': (873, 270, 1), 'spr_pr_nt_tile2': (873, 270, 1),
          'spr_pr_nt_tile3': (873, 270, 1), 'spr_pr_bg_nt': (416, 270, 1)}
for s, (w, h, n) in EXPECT.items():
    yy = gmload(REPO + f'sprites/{s}/{s}.yy')
    im = Image.open(REPO + f'sprites/{s}/{yy["frames"][0]["name"]}.png')
    chk(im.size == (w, h) and len(yy['frames']) == n, f'tamano {s}', f'{im.size} vs {(w,h)} n={len(yy["frames"])}')

for snd in ('mus_alphagentemple', 'mus_alphagentemple_chase'):
    d = REPO + f'sounds/{snd}'
    yy = gmload(f'{d}/{snd}.yy')
    chk(os.path.exists(f'{d}/{snd}.ogg') and yy['soundFile'] == f'{snd}.ogg'
        and yy['parent']['name'] == 'Music', f'sonido {snd}')

for o in ('obj_femboy_temple', 'obj_negatv'):
    yy = gmload(REPO + f'objects/{o}/{o}.yy')
    chk(yy['resourceType'] == 'GMObject', f'objeto {o}')
yfb = gmload(REPO + 'objects/obj_femboy_temple/obj_femboy_temple.yy')
chk((yfb.get('parentObjectId') or {}).get('name') == 'obj_corpse'
    and yfb['visible'] is False and yfb['spriteId']['name'] == 'spr_femboy'
    and len(yfb['eventList']) == 1, 'obj_femboy_temple hijo de obj_corpse + Create')
chk('char = -1;' in open(REPO + 'objects/obj_femboy_temple/Create_0.gml').read(),
    'obj_femboy_temple Create char=-1 (patron corpse)')
yng = gmload(REPO + 'objects/obj_negatv/obj_negatv.yy')
chk((yng.get('parentObjectId') is None) and yng['visible'] is True
    and not yng['eventList'], 'obj_negatv decorativo sin eventos')

print('== 2. room 1:1 vs dump del mod ==')
room = gmload(REPO + 'rooms/room_alphagentemple/room_alphagentemple.yy')
chk(room['roomSettings']['Width'] == 2816 and room['roomSettings']['Height'] == 1536,
    'room 2816x1536')
chk(room.get('isDnd') is False, 'room isDnd:false (leccion V2)')
chk(room['creationCodeFile'].endswith('RoomCreationCode.gml'), 'creationCodeFile')
chk(len(room['layers']) == 9, '9 capas', len(room['layers']))
lay = {l['name']: l for l in room['layers']}
depths = {n: l['depth'] for n, l in lay.items()}
chk(depths == {'statui': -100, 'Instances_1': 0, 'sfera1': 100, 'femboy': 200,
               'sfera2': 300, 'Collisions': 400, 'Backgrounds2': 500, 'Background': 600,
               'black': 700}, 'depths 1:1 del mod', depths)
chk(lay['sfera1']['visible'] is False and lay['sfera2']['visible'] is False,
    'sfera1/sfera2 ocultas (1:1)')
chk(len(lay['statui']['assets']) == 11 and len(lay['sfera1']['assets']) == 4
    and len(lay['sfera2']['assets']) == 4, 'graphics 11+4+4')
n_inst = sum(len(l['instances']) for l in room['layers'] if 'instances' in l)
chk(n_inst == 113, '113 instancias (58+1+54)', n_inst)
chk(len(room['instanceCreationOrder']) == 113, 'instanceCreationOrder 113')
# conteo por objeto contra el dump del mod
counts = {}
for l in room['layers']:
    for i in l.get('instances', []):
        counts[i['objectId']['name']] = counts.get(i['objectId']['name'], 0) + 1
EXPECT_COUNTS = {'obj_spring_up': 2, 'obj_yspring_up': 3, 'obj_bspring_up': 3,
                 'obj_ring_spawner': 26, 'obj_ringspawn': 5, 'obj_spawnpoint': 4,
                 'obj_exespawn': 4, 'obj_am_hideobject': 11, 'obj_solid_block': 30,
                 'obj_platform_jumptrough': 10, 'obj_angleanuller': 5,
                 'obj_angleanuller_eggsafe': 7, 'obj_parallax': 1, 'obj_negatv': 1,
                 'obj_femboy_temple': 1}
chk(counts == EXPECT_COUNTS, 'conteo por objeto 1:1', {k: v for k, v in counts.items() if EXPECT_COUNTS.get(k) != v})
# backgrounds
chk(lay['Backgrounds2']['spriteId']['name'] == 'spr_bg_nt2' and lay['Backgrounds2']['htiled']
    and lay['Backgrounds2']['vtiled'], 'Backgrounds2 = bg2 del mod (renombre spr_bg_nt2)')
chk(lay['Background']['spriteId']['name'] == 'spr_bg_nt' and lay['Background']['colour'] == 4293256677,
    'Background = spr_bg_nt tint 0xFFE5E5E5')
chk(lay['black']['spriteId'] is None, 'black sin sprite (1:1)')
ccc = open(REPO + 'rooms/room_alphagentemple/RoomCreationCode.gml').read()
chk('scr_play_music(mus_alphagentemple)' in ccc and 'scr_level_split(spr_nt_tiles, 100)' in ccc
    and 'scr_level_split(spr_nt_tiles2, 90)' in ccc and 'scr_level_split(spr_nt_tiles3, 450)' in ccc
    and 'layer_get_id("Backgrounds2"), 0.8' in ccc, 'RoomCreationCode (patron de la casa)')

print('== 3. seleccion alineada 22/23 ==')
src = open(REPO + 'scripts/scr_globals/scr_globals.gml', encoding='utf-8').read()
m = re.search(r'global\.levels\s*=\s*\[(.*?)\n\];', src, re.S)
levels = re.findall(r'\{ group: "([^"]+)", rid: (\w+)', m.group(1))
chk(len(levels) == 23, f'global.levels 23 entradas ({len(levels)})')
chk(levels[22] == ('NegagenTemple', 'room_alphagentemple'), 'levels[22] = NegagenTemple')
chk(levels[21] == ('SkyBase', 'room_skybase') and levels[12] == ('Hill', 'room_greenhill'),
    '[21] SkyBase y [12] Hill intactos')
m = re.search(r'global\.levelDescriptions\s*=\s*\[(.*?)\n\];', src, re.S)
descs = re.findall(r'^\s*"([^"]*)",\s*$', m.group(1), re.M)
chk(len(descs) == 23, f'levelDescriptions 23 entradas ({len(descs)})')
chk(descs[22].startswith('a temple in a deep wave-like blue'), 'desc[22] del mod')

src = open(REPO + 'objects/obj_lobby_prolet/Create_0.gml', encoding='utf-8').read()
m = re.search(r'mapData\s*=\s*\[(.*?)\n\];', src, re.S)
tiles_n = len(re.findall(r'\{ tiles:', m.group(1)))
chk(tiles_n == 23, f'mapData 23 entradas ({tiles_n})')
chk('spr_pr_nt_tile, spr_pr_nt_tile2, spr_pr_nt_tile3' in src and 'bg: spr_pr_bg_nt' in src,
    'mapData[22] con previews del propio mod')

print('== 4. server ==')
mh = open(BS + 'include/Maps.h').read()
chk('#define MAP_COUNT 23' in mh, 'MAP_COUNT 23')
mc = open(BS + 'disasterserver/Maps.c').read()
entries = re.findall(r'\}, (\d+), ([\d+]+) \}, //(\d+)$', mc, re.M)
chk(len(entries) == 23, f'g_mapList 23 entradas ({len(entries)})')
chk(entries[22] == ('1', '26', '22'), 'g_mapList[22] spawn_red=1 ring_count=26', entries[22] if len(entries) > 22 else None)
chk('"Negagen Temple"' in mc, 'nombre Negagen Temple')
zh = open(BS + 'include/Zone.h').read()
chk('g_mapZone[23]' in zh and 'g_mapZoneSize[23]' in zh, 'Zone.h arrays [23]')
zc = open(BS + 'disasterserver/Zone.c').read()
chk('Zone room_alphagentemple[] =' in zc and zc.count('room_alphagentemple') >= 3,
    'Zone.c zonas del templo')
nz = len(re.findall(r'\{ -?\d+, -?\d+, BLOCK_SIZE', zc.split('Zone room_alphagentemple[] =')[1].split('};')[0]))
chk(nz == 25, f'25 zonas anticheat ({nz})')
gzm = re.search(r'Zone\* g_mapZone\[23\] =\n\{(.*?)\n\};', zc, re.S)
chk(gzm and gzm.group(1).count('room_') == 23, 'g_mapZone 23 entradas')
ch = open(BS + 'include/Config.h').read()
chk('bool    map_list[23];' in ch, 'Config.h map_list[23]')
cc = open(BS + 'disasterserver/Config.c').read()
ml = re.search(r'\.map_list = \{ ([^}]*) \}', cc)
chk(ml and ml.group(1).count('true') + ml.group(1).count('false') == 23
    and ml.group(1).split(', ')[20] == 'false' and ml.group(1).split(', ')[22] == 'true',
    'Config.c defaults: 23 entradas, Fart fuera, [22] activo')

print('== 5. sintaxis C (gcc -fsyntax-only, stub enet) ==')
os.chdir(BS + 'disasterserver')
for f in ('Maps.c', 'Config.c', 'Zone.c', 'states/Lobby.c', 'states/Server.c', 'states/Mapvote.c'):
    r = subprocess.run(['gcc', '-fsyntax-only', '-I', '../include', '-I', '/tmp/enet-stub',
                        '-D_GNU_SOURCE', '-std=c17', f], capture_output=True, text=True)
    errs = [l for l in r.stderr.splitlines() if 'error' in l]
    chk(not errs, f'gcc {f}', errs[:2])

print('== 6. registro .yyp ==')
yyp = gmload(REPO + 'Sonicexe The Disaster 2D Remake.yyp')
res = {r['id']['name']: r['id']['path'] for r in yyp['resources']}
need = SPRITES + ['mus_alphagentemple', 'mus_alphagentemple_chase',
                  'obj_femboy_temple', 'obj_negatv', 'room_alphagentemple']
chk(all(n in res for n in need), '19 recursos registrados',
    [n for n in need if n not in res])
chk(len(res) == len(yyp['resources']), 'sin duplicados')
fps = {f['folderPath'] for f in yyp['Folders']}
chk('folders/Sprites/Zones/NegagenTemple.yy' in fps
    and 'folders/Objects/Game Objects/Level Specific/NegagenTemple.yy' in fps, '2 carpetas NegagenTemple')
chk(any(t['name'] == 'NegagenTemple' for t in yyp['TextureGroups']), 'texture group NegagenTemple')
chk(yyp['RoomOrderNodes'][-1]['roomId']['name'] == 'room_alphagentemple', 'RoomOrderNode al final')

# parent.path de TODOS los .yy nuevos vs carpetas del yyp
folders = {f['folderPath'].replace('.yy', '') for f in yyp['Folders']}
bad_parents = []
for n in need:
    p = res[n]
    yy = gmload(REPO + p)
    pp = yy.get('parent', {}).get('path', '')
    if pp and pp.replace('.yy', '') not in folders:
        bad_parents.append((n, pp))
chk(not bad_parents, 'parent.path de los 19 .yy apuntan a carpetas registradas', bad_parents)

print('== 7. icono mapvote frame 22 ==')
mv = gmload(REPO + 'sprites/spr_mapvote/spr_mapvote.yy')
chk(len(mv['frames']) == 23, 'spr_mapvote sigue en 23 frames (sin tocar el .yy)')
icon = Image.open(REPO + 'sprites/spr_mapvote/' + mv['frames'][22]['name'] + '.png').convert('RGBA')
chk(icon.size == (123, 104), 'icono 123x104')
import numpy as np
a = np.array(icon)
non_blank = (a[..., 3] > 0).mean()
chk(0.5 < non_blank, 'icono con contenido real', f'opaco={non_blank:.2f}')

print()
print(f'RESULTADO: {ok} OK / {fail} FAIL')
sys.exit(1 if fail else 0)
