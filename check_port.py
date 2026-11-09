#!/usr/bin/env python3
"""Verificacion completa del porte Wood Zone + Sky Sanctuary.
 chequeos de esquema, conteos, referencias cruzadas y sintaxis C."""
import json, re, os, sys, glob, struct, subprocess

REPO = '/home/z/my-project/repo-disaster2d'
YYP = f'{REPO}/Sonicexe The Disaster 2D Remake.yyp'
fails = []
oks = 0

def chk(cond, msg):
    global oks
    if cond:
        oks += 1
    else:
        fails.append(msg)
        print(f'  FAIL: {msg}')

def load_tolerant(path):
    s = open(path, encoding='utf-8').read()
    return json.loads(re.sub(r',(\s*[}\]])', r'\1', s))

print('== 1. ARCHIVOS .YY NUEVOS: esquema ==')
NEW_SPRITES = ['background_woodzone','spr_wood_tiles','spr_wood_tiles1',
               'spr_pr_wood','spr_pr_wood2','spr_pr_wood3',
               'background_skysanc','background_skysanc2','spr_skysanc_tiles',
               'spr_pr_skysanc','spr_pr_skysanc2','spr_pr_skysanc3','spr_pr_skysancbg']
meta = json.load(open('/home/z/my-project/port_assets/sprites_meta.json'))
for name in NEW_SPRITES:
    p = f'{REPO}/sprites/{name}/{name}.yy'
    chk(os.path.exists(p), f'{name}.yy no existe')
    try:
        raw = open(p, encoding='utf-8').read()
        d = json.loads(raw)
        keys = list(d.keys())
        chk(keys[0] == '$GMSprite', f'{name}: primer key {keys[0]!r} != $GMSprite')
        chk(keys[1] == '%Name', f'{name}: segundo key {keys[1]!r} != %Name')
        chk(d.get('%Name') == name, f'{name}: %Name mal')
        chk('%%' not in raw, f'{name}: contiene %%')
        nf = len(d['frames'])
        chk(nf == len(meta[name]['frames']), f'{name}: frames {nf} != esperados')
        chk(len(d['sequence']['tracks'][0]['keyframes']['Keyframes']) == nf,
            f'{name}: keyframes != frames')
        chk(d['sequence']['length'] == float(nf), f'{name}: length != frames')
        chk(d['width'] == meta[name]['w'] and d['height'] == meta[name]['h'],
            f'{name}: dims malas')
        # pngs existen
        for f in d['frames']:
            chk(os.path.exists(f'{REPO}/sprites/{name}/{f["name"]}.png'),
                f'{name}: png {f["name"]} no existe')
        # keyframe ids referencian frames existentes
        fids = {f['name'] for f in d['frames']}
        for kf in d['sequence']['tracks'][0]['keyframes']['Keyframes']:
            chk(kf['Channels']['0']['Id']['name'] in fids,
                f'{name}: keyframe apunta a frame inexistente')
    except Exception as e:
        chk(False, f'{name}: EXCEPCION {e}')

print('== 2. SONIDOS ==')
for name in ('mus_woodzone', 'mus_woodzone_chase'):
    p = f'{REPO}/sounds/{name}'
    chk(os.path.exists(f'{p}/{name}.yy'), f'{name}.yy no existe')
    chk(os.path.exists(f'{p}/{name}.ogg'), f'{name}.ogg no existe')
    d = load_tolerant(f'{p}/{name}.yy')
    keys = list(d.keys())
    chk(keys[0] == '$GMSound' and keys[1] == '%Name', f'{name}: esquema keys')
    chk(d['soundFile'] == f'{name}.ogg', f'{name}: soundFile mal')
    chk(d['parent']['path'] == 'folders/Sounds/Music.yy', f'{name}: parent mal')

print('== 3. ROOMS ==')
ROOMS = {
    'room_woodzone': ('/home/z/my-project/woodzone/room_woodzone.json',
                      {'Background': 'background_woodzone'}, 4544, 1888),
    'room_skysanctuary': ('/home/z/my-project/skysanctuary/room_skysanctuary.json',
                          {'Background': 'background_skysanc',
                           'Background2': 'background_skysanc2'}, 4608, 1664),
}
for room, (rjpath, bgmap, W, H) in ROOMS.items():
    p = f'{REPO}/rooms/{room}/{room}.yy'
    chk(os.path.exists(p), f'{room}.yy no existe')
    raw = open(p, encoding='utf-8').read()
    d = json.loads(raw)
    keys = list(d.keys())
    chk(keys[0] == '$GMRoom', f'{room}: primer key {keys[0]!r}')
    chk(keys[1] == '%Name', f'{room}: segundo key {keys[1]!r}')
    chk(d.get('%Name') == room, f'{room}: %Name mal')
    chk('%%' not in raw, f'{room}: contiene %%')
    chk(d.get('isDnd') is False, f'{room}: isDnd ausente')
    chk(d['roomSettings']['Width'] == W and d['roomSettings']['Height'] == H,
        f'{room}: dims {d["roomSettings"]["Width"]}x{d["roomSettings"]["Height"]}')
    chk(d['creationCodeFile'] == f'${{project_dir}}/rooms/{room}/RoomCreationCode.gml',
        f'{room}: creationCodeFile mal')
    chk(os.path.exists(f'{REPO}/rooms/{room}/RoomCreationCode.gml'),
        f'{room}: RoomCreationCode.gml no existe')
    rj = json.load(open(rjpath))
    # instancias totales
    total = sum(len(l['instances']) for l in d['layers']
                if l['resourceType'] == 'GMRInstanceLayer')
    chk(total == len(rj['instances']), f'{room}: instancias {total} != {len(rj["instances"])}')
    # cada capa con los ids correctos
    for l in d['layers']:
        if l['resourceType'] == 'GMRInstanceLayer':
            ml = next(x for x in rj['layers'] if x['name'] == l['%Name'])
            chk(len(l['instances']) == len(ml['instance_ids']),
                f'{room}/{l["%Name"]}: {len(l["instances"])} != {len(ml["instance_ids"])}')
        if l['resourceType'] == 'GMRBackgroundLayer' and l.get('spriteId'):
            want = bgmap.get(l['%Name'])
            if want:
                chk(l['spriteId']['name'] == want,
                    f'{room}/{l["%Name"]}: bg {l["spriteId"]["name"]} != {want}')
                chk(l['spriteId']['path'] == f'sprites/{want}/{want}.yy',
                    f'{room}/{l["%Name"]}: bg path mal')
    # instanceCreationOrder
    ico = d['instanceCreationOrder']
    chk(len(ico) == len(rj['instances']), f'{room}: instanceCreationOrder {len(ico)} != {len(rj["instances"])}')
    names_in_layers = [i['name'] for l in d['layers']
                       if l['resourceType'] == 'GMRInstanceLayer'
                       for i in l['instances']]
    chk(len(names_in_layers) == len(set(names_in_layers)),
        f'{room}: nombres de instancia duplicados')
    # objetos referenciados existen
    for l in d['layers']:
        if l['resourceType'] == 'GMRInstanceLayer':
            for i in l['instances']:
                obj = i['objectId']['name']
                chk(os.path.exists(f'{REPO}/objects/{obj}/{obj}.yy'),
                    f'{room}: objeto {obj} no existe')
        if l['resourceType'] == 'GMRAssetLayer':
            for a in l['assets']:
                spr = a['spriteId']['name']
                chk(os.path.exists(f'{REPO}/sprites/{spr}/{spr}.yy'),
                    f'{room}: sprite asset {spr} no existe')
    # valores de instancia: rango sanity
    bad = 0
    for l in d['layers']:
        if l['resourceType'] == 'GMRInstanceLayer':
            for i in l['instances']:
                if not (-2000 <= i['x'] <= W + 2000 and -2000 <= i['y'] <= H + 2000):
                    bad += 1
    chk(bad == 0, f'{room}: {bad} instancias fuera de rango')
    # rot float sanity
    rots = [i['rotation'] for l in d['layers'] if l['resourceType'] == 'GMRInstanceLayer'
            for i in l['instances']]
    chk(all(-360 <= r <= 360 for r in rots), f'{room}: rotacion fuera de rango')

print('== 4. MAPVOTE ==')
mv = load_tolerant(f'{REPO}/sprites/spr_mapvote/spr_mapvote.yy')
chk(len(mv['frames']) == 25, f'mapvote frames {len(mv["frames"])} != 25')
chk(mv['sequence']['length'] == 25.0, 'mapvote length != 25')
kf = mv['sequence']['tracks'][0]['keyframes']['Keyframes']
chk(len(kf) == 25, f'mapvote keyframes {len(kf)} != 25')
chk([int(k['Key']) for k in kf] == list(range(25)), 'mapvote keys no secuenciales')
pngs = glob.glob(f'{REPO}/sprites/spr_mapvote/*.png')
chk(len(pngs) == 25, f'mapvote pngs {len(pngs)} != 25')
for f in mv['frames']:
    chk(os.path.exists(f'{REPO}/sprites/spr_mapvote/{f["name"]}.png'),
        f'mapvote: png {f["name"]} no existe')

print('== 5. .YYP ==')
yyp = load_tolerant(YYP)
res_names = {r['id']['name'] for r in yyp['resources'] if isinstance(r['id'], dict)}
for n in NEW_SPRITES + ['mus_woodzone', 'mus_woodzone_chase', 'room_woodzone', 'room_skysanctuary']:
    chk(n in res_names, f'yyp: {n} no registrado')
chk(len([r for r in yyp['resources'] if isinstance(r['id'], dict)]) == 2108, 'yyp: conteo resources inesperado')
folders = {f['folderPath'] for f in yyp['Folders']}
for fp in ('folders/Sprites/Zones/WoodZone.yy', 'folders/Sprites/Zones/SkySanctuary.yy'):
    chk(fp in folders, f'yyp: folder {fp} no registrado')
tg = {t['name'] for t in yyp['TextureGroups']}
for t in ('WoodZone', 'SkySanctuary'):
    chk(t in tg, f'yyp: texture group {t} no registrado')
ron = [n['roomId']['name'] for n in yyp['RoomOrderNodes'] if isinstance(n.get('roomId'), dict)]
chk('room_woodzone' in ron and 'room_skysanctuary' in ron, 'yyp: rooms faltan en RoomOrderNodes')
chk(len(ron) == 34, f'yyp: RoomOrderNodes {len(ron)} != 34')
# parents de recursos apuntan a carpetas registradas
for name in NEW_SPRITES:
    d = load_tolerant(f'{REPO}/sprites/{name}/{name}.yy')
    chk(d['parent']['path'] in folders, f'{name}: parent path no registrado: {d["parent"]["path"]}')

print('== 6. scr_globals.gml ==')
sg = open(f'{REPO}/scripts/scr_globals/scr_globals.gml', encoding='utf-8').read()
# contar entries de levels: lineas con { group:
lvl_entries = re.findall(r'\{ group: "(\w+)", rid: (room_\w+)', sg)
chk(len(lvl_entries) == 25, f'levels: {len(lvl_entries)} entradas != 25')
chk(lvl_entries[23] == ('WoodZone', 'room_woodzone'), f'levels[23]: {lvl_entries[23]}')
chk(lvl_entries[24] == ('SkySanctuary', 'room_skysanctuary'), f'levels[24]: {lvl_entries[24]}')
# descriptions: contar strings dentro del array
m = re.search(r'global\.levelDescriptions\s*=\s*\[(.*?)\n\];', sg, re.S)
descs = re.findall(r'^\s*"', m.group(1), re.M)
chk(len(descs) == 25, f'descriptions: {len(descs)} != 25')
# musicas referenciadas existen
for mus in ('mus_woodzone', 'mus_woodzone_chase'):
    chk(mus in sg, f'scr_globals: falta {mus}')
    chk(os.path.exists(f'{REPO}/sounds/{mus}/{mus}.yy'), f'sound {mus} no existe')

print('== 7. obj_lobby_prolet ==')
lob = open(f'{REPO}/objects/obj_lobby_prolet/Create_0.gml', encoding='utf-8').read()
md = re.findall(r'\{ tiles: \[ ([^\]]+) \]', lob)
chk(len(md) == 25, f'mapData: {len(md)} entradas != 25')
for spr in ('spr_pr_wood', 'spr_pr_wood2', 'spr_pr_wood3',
            'spr_pr_skysanc', 'spr_pr_skysanc2', 'spr_pr_skysanc3'):
    chk(spr in lob, f'lobby: falta {spr}')
    chk(os.path.exists(f'{REPO}/sprites/{spr}/{spr}.yy'), f'sprite {spr} no existe')
chk('background_woodzone' in lob and 'spr_pr_skysancbg' in lob, 'lobby: bgs faltan')

print('== 8. SERVER ==')
mh = open(f'{REPO}/betterserver-oss/include/Maps.h', encoding='utf-8').read()
chk('#define MAP_COUNT 25' in mh, 'Maps.h: MAP_COUNT != 25')
mc = open(f'{REPO}/betterserver-oss/disasterserver/Maps.c', encoding='utf-8').read()
map_entries = re.findall(r'//(\d+)\s*$', mc, re.M)
chk(len(map_entries) == 25, f'Maps.c: {len(map_entries)} entradas != 25')
chk('"Wood Zone"' in mc and '"SkySanctuary"' in mc, 'Maps.c: nombres faltan')
cc = open(f'{REPO}/betterserver-oss/disasterserver/Config.c', encoding='utf-8').read()
m = re.search(r'\.map_list = \{ ([^}]*) \}', cc)
flags = [x.strip() for x in m.group(1).split(',')]
chk(len(flags) == 25, f'Config.c: map_list {len(flags)} != 25')
chk(flags[23] == 'true' and flags[24] == 'true', 'Config.c: mapas nuevos inactivos')
zc = open(f'{REPO}/betterserver-oss/disasterserver/Zone.c', encoding='utf-8').read()
chk('Zone* g_mapZone[25]' in zc, 'Zone.c: g_mapZone[25] falta')
chk('size_t g_mapZoneSize[25]' in zc, 'Zone.c: g_mapZoneSize[25] falta')
zh = open(f'{REPO}/betterserver-oss/include/Zone.h', encoding='utf-8').read()
chk('g_mapZone[25]' in zh and 'g_mapZoneSize[25]' in zh, 'Zone.h: externs no pasaron a 25')
chk('Zone room_woodzone[]' in zc and 'Zone room_skysanctuary[]' in zc, 'Zone.c: arrays de zonas faltan')
# conteo zonas vs bloques
wzr = json.load(open('/home/z/my-project/woodzone/room_woodzone.json'))
ssr = json.load(open('/home/z/my-project/skysanctuary/room_skysanctuary.json'))
wz_blocks = len([i for i in wzr['instances'].values() if i['obj'] == 'obj_solid_block'])
ss_blocks = len([i for i in ssr['instances'].values() if i['obj'] == 'obj_solid_block'])
wz_zones = len(re.findall(r'\{ [-\d]+, [-\d]+, BLOCK_SIZE', zc.split('Zone room_woodzone[]')[1].split(';')[0]))
ss_zones = len(re.findall(r'\{ [-\d]+, [-\d]+, BLOCK_SIZE', zc.split('Zone room_skysanctuary[]')[1].split(';')[0]))
chk(wz_zones == 343, f'Zone.c: wz {wz_zones} != 343 (de {wz_blocks} bloques)')
chk(ss_zones == 27, f'Zone.c: ss {ss_zones} != 27 (de {ss_blocks} bloques)')
chk(zc.count('room_woodzone') == 3, 'Zone.c: room_woodzone referencias != 3')
chk(zc.count('room_skysanctuary') == 3, 'Zone.c: room_skysanctuary referencias != 3')

print('== 9. SINTAXIS C (gcc) ==')
r = subprocess.run(['gcc', '-fsyntax-only', '-I', f'{REPO}/betterserver-oss/include', '-I', '/tmp/stubinc',
                    f'{REPO}/betterserver-oss/disasterserver/Zone.c'],
                   capture_output=True, text=True)
chk(r.returncode == 0, f'Zone.c no compila: {r.stderr[:300]}')
r = subprocess.run(['gcc', '-fsyntax-only', '-I', f'{REPO}/betterserver-oss/include', '-I', '/tmp/stubinc',
                    f'{REPO}/betterserver-oss/disasterserver/Maps.c'],
                   capture_output=True, text=True)
chk(r.returncode == 0, f'Maps.c no compila: {r.stderr[:300]}')
r = subprocess.run(['gcc', '-fsyntax-only', '-I', f'{REPO}/betterserver-oss/include', '-I', '/tmp/stubinc',
                    f'{REPO}/betterserver-oss/disasterserver/Config.c'],
                   capture_output=True, text=True)
chk(r.returncode == 0, f'Config.c no compila: {r.stderr[:300]}')

print('== 10. SANITY ROOM: creacion vs datos ==')
for room, rjpath in (('room_woodzone', '/home/z/my-project/woodzone/room_woodzone.json'),
                     ('room_skysanctuary', '/home/z/my-project/skysanctuary/room_skysanctuary.json')):
    rj = json.load(open(rjpath))
    d = json.load(open(f'{REPO}/rooms/{room}/{room}.yy',
                       # tolerate trailing commas? no: nuestro dump es json limpio
                       ))
    # posiciones exactas: sample de 5 instancias
    insts = {i['name']: i for l in d['layers'] if l['resourceType'] == 'GMRInstanceLayer'
             for i in l['instances']}
    ids = list(rj['instances'].keys())[:5]
    for iid in ids:
        src = rj['instances'][iid]
        nm = 'inst_' + format(int(iid), 'X').zfill(8)
        got = insts.get(nm)
        chk(got is not None, f'{room}: falta instancia {nm}')
        if got:
            chk(abs(got['x'] - src['x']) < 0.01 and abs(got['y'] - src['y']) < 0.01,
                f'{room}/{nm}: pos ({got["x"]},{got["y"]}) != ({src["x"]},{src["y"]})')
            chk(got['objectId']['name'] == src['obj'],
                f'{room}/{nm}: obj {got["objectId"]["name"]} != {src["obj"]}')
            chk(abs(got['scaleX'] - src['scale_x']) < 1e-4,
                f'{room}/{nm}: scaleX mal')

print(f'\n===== RESULTADO: {oks} OK, {len(fails)} FAIL =====')
if fails:
    print('\nFALLOS:')
    for f in fails:
        print(' -', f)
    sys.exit(1)
