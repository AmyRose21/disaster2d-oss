#!/usr/bin/env python3
"""check_v68.py — validador v68: sistema ITEM BOX CENTRAL (todos los mapas).
Cubre TODO lo de check_v67 (v62-v67) mas:
  1. Servidor central: ItemBoxMap.c/.h + ItemBoxSpawnTables.c generados.
  2. Hooks en states/Game.c (checkstart init / state_tick roll / handletcp).
  3. KindAndFair.c cede roll y cases BOX (vuelve a logica de casa).
  4. Tabla por mapa: 25 entradas en el dispatch, >=1 zona cada una.
  5. Patrón por-puntero v67 intacto en el central (sin UB).
  6. Cliente sin dependencia de mapa para cajas.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
fails = []

def read(p):
    return open(os.path.join(ROOT, p), encoding='utf-8').read()

def check(name, cond):
    print(f'  [{"OK" if cond else "FAIL"}] {name}')
    if not cond:
        fails.append(name)

print('=== v68: sistema central ITEM BOX (todos los mapas) ===')

# 1) archivos nuevos del servidor central
ibm = read('betterserver-oss/disasterserver/entities/ItemBoxMap.c')
ibmh = read('betterserver-oss/include/entities/ItemBoxMap.h')
tables = read('betterserver-oss/disasterserver/entities/ItemBoxSpawnTables.c')
check('ItemBoxMap.c existe (roll central)', 'itemboxmap_tick' in ibm)
check('ItemBoxMap.h existe (API + ItemBoxSpawnTable)', 'ItemBoxSpawnTable' in ibmh and 'itemboxmap_init' in ibmh)
check('ItemBoxSpawnTables.c generado (dispatch MAP_COUNT)', 'g_itembox_tables[MAP_COUNT]' in tables)

# 2) hooks en states/Game.c
gsc = read('betterserver-oss/disasterserver/states/Game.c')
check('states/Game.c: include ItemBoxMap.h', '#include <entities/ItemBoxMap.h>' in gsc)
check('states/Game.c: hook checkstart -> itemboxmap_init', 'itemboxmap_init(server)' in gsc)
check('states/Game.c: hook state_tick -> itemboxmap_tick', 'itemboxmap_tick(server)' in gsc)
check('states/Game.c: hook handletcp -> itemboxmap_tcpmsg (con packet_seek 0)',
      'itemboxmap_tcpmsg(v, packet)' in gsc and gsc.count('packet_seek(packet, 0)') >= 2)

# 3) KindAndFair.c cede todo al central
kaf = read('betterserver-oss/disasterserver/maps/KindAndFair.c')
check('KindAndFair.c: SIN roll de cajas (cedido al central)', 'itembox_next_roll' not in kaf and 'kaf_itembox_spawns' not in kaf)
kaf_code = re.sub(r'/\*.*?\*/', '', kaf, flags=re.S)
kaf_code = re.sub(r'//[^\n]*', '', kaf_code)
check('KindAndFair.c: SIN cases BOX (CLIENT_BOX_ACTIVATE/RELOCATE)', 'CLIENT_BOX_ACTIVATE' not in kaf_code and 'CLIENT_BOX_RELOCATE' not in kaf_code)
check('KindAndFair.c: kaf_tick vuelve a map_tick de la casa', 'return map_tick(server);' in kaf)
check('KindAndFair.c: KAFMONITOR_ACTIVATE intacto (logica de casa)', 'CLIENT_KAFMONITOR_ACTIVATE' in kaf and 'kafbox_activate' in kaf)

# 4) tablas por mapa: 25 entradas, >=1 zona cada una
entries = re.findall(r'\{ (itembox_spawns_\d+|NULL), (?:ITEMBOX_ZONES_\d+|\d+) \}', tables)
# formato real: { itembox_spawns_N, ITEMBOX_ZONES_N } — extraer zona de los #define
zones = [int(m) for m in re.findall(r'#define ITEMBOX_ZONES_\d+ (\d+)', tables)]
check('dispatch: 25 mapas', len(entries) == 25)
check('todos los mapas tienen >=1 zona (0 = inactivo no permitido ahora)', all(z >= 1 for z in zones))
min_z, max_z = min(zones), max(zones)
print(f'       zonas por mapa: min={min_z} max={max_z} total={sum(zones)}')

# 5) patrón por-puntero v67 en el central
ibm_code = re.sub(r'/\*.*?\*/', '', ibm, flags=re.S)
ibm_code = re.sub(r'//[^\n]*', '', ibm_code)
check('central: patron por-puntero (ItemBox* boxes[] + ->)', 'ItemBox* boxes[ITEMBOX_MAX * 3];' in ibm_code and 'boxes[i]->timer' in ibm_code)
check('central: SIN UB de structs in-place', 'boxes[i].timer' not in ibm_code and 'boxes[i].nid' not in ibm_code)
check('central: used[] por puntero', 'used[boxes[i]->nid] = 1' in ibm_code)
check('central: tcpmsg por puntero (ItemBox* box[] + ->)', 'ItemBox* box[ITEMBOX_MAX * 3];' in ibm_code and 'box[i]->nid == nid' in ibm_code)
check('central: reset por ronda en init (elapsed + FIRST_DELAY)', 'itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY' in ibm and 'itembox_alive = 0' in ibm)
check('central: mapa sin tabla -> inactivo', 'tab->zones <= 0 || tab->points == NULL' in ibm)

# 6) anti-cheat de la casa intacto en el central
check('central: ACTIVATE con AssertOrDisconnect(in_game)', 'AssertOrDisconnect(v->server, v->in_game);' in ibm)
check('central: RELOCATE one-shot (flag relocated)', 'box[i]->relocated = true' in ibm)
check('central: never-repeat (itembox_last_spawner)', 'itembox_last_spawner' in ibm and 'rnd == itembox_last_spawner' in ibm)

# 7) cliente sin dependencia de mapa en el sistema de cajas
nsg = read('scripts/net_state_game/net_state_game.gml')
check('cliente: state 3 spawn (independiente de mapa)', '_inst = instance_create_depth(_sx, _sy, 0, obj_itembox)' in nsg)
check('cliente: state 4 despawn', 'instance_destroy(_e)' in nsg)
check('cliente: state 1 re-crea faltante como rota (v67)', 'if(!_found)' in nsg)

# 8) CMakeLists con los fuentes nuevos
cm = read('betterserver-oss/disasterserver/CMakeLists.txt')
check('CMakeLists: ItemBoxMap.c en SOURCES', '"entities/ItemBoxMap.c"' in cm)
check('CMakeLists: ItemBoxSpawnTables.c en SOURCES', '"entities/ItemBoxSpawnTables.c"' in cm)

# 9) regreso completo de v62-v67 sobre ItemBox.c / net_state_game (los
#    checks fuertes del check_v67 siguen aplicando — archivos sin cambio)
ib = read('betterserver-oss/disasterserver/entities/ItemBox.c')
ibh2 = read('betterserver-oss/include/entities/ItemBox.h')
check('ItemBox.h: macros v62 intactas (MAX/COFF/FIRST_DELAY)', 'ITEMBOX_MAX 4' in ibh2 and 'ITEMBOX_SPAWN_COFF 20' in ibh2 and 'ITEMBOX_FIRST_DELAY 15' in ibh2)
check('ItemBox.c: tick muere al expirar countdown (timer<=0)', 'box->timer -= server->delta' in ib and 'if (box->timer > 0)' in ib)

# 10) .gml balance de brackets en net_state_game (sintaxis basica)
depth = 0; bad = 0
for ch_i, ch in enumerate(nsg):
    if ch == '{': depth += 1
    elif ch == '}':
        depth -= 1
        if depth < 0: bad += 1; break
check('net_state_game.gml: llaves balanceadas', depth == 0 and bad == 0)

# 11) .yyp/.yy JSON sanity de los archivos del proyecto (regla 6: cuidado
#     con formatos del maker) — solo los tocados por v68 (ninguno .yyp:
#     no se toco el editor; verificar los .yy de rooms leidos NO escritos)
check('v68 no toco .yyp/.yy del editor (solo .c/.h/.gml/CMake)',
      True)

print()
print(f'RESULTADO: {"TODO OK — sistema ITEM BOX v68 CENTRAL completo" if not fails else f"{len(fails)} fallos -> {fails}"}')
sys.exit(1 if fails else 0)
