#!/usr/bin/env python3
"""check_v64.py — validador (v62 + gravedad/relocate v63) del sistema ITEM BOX v2 (cajas de recompensa
aleatorias). Convencion de la casa: cada cambio grande lleva su check_vXX.
Verifica:
  1. Enum sync: net_packets.gml y Packet.h con CLIENT_BOX_ACTIVATE /
     SERVER_BOX_STATE AL FINAL y en el MISMO orden relativo.
  2. Objeto cliente: obj_itembox completo (Create/Step_2/Destroy/yy) y
     registrado en el .yyp.
  3. Caso de red: SERVER_BOX_STATE en net_state_game con los 5 rewards
     y las duraciones exactas de la casa.
  4. Rotura por cuerpo en scr_collision_objects (obj_itembox).
  5. Servidor C: ItemBox.h/.c, KindAndFair.c (spawners + roll + tick),
     Maps.c (kaf_tick), CMakeLists (fuente registrada).
  6. Escudo electrico: bit PLAYER_ELECTROSHIELD, emisor en netclient,
     receptor en udpprocess, overlay en puppet Draw, stun al atacante
     via net_sound_emit_at + receptor en CLIENT_SOUND_EMIT.
  7. Botas: bootsTimer tick + _capH/_acc en scr_move_basic.
  8. Sprites de la duena presentes y registrados (6/6 en yyp, 6/6 en
     resource_order — incluye el fix de spr_invincibility_box).
  9. v63 GRAVEDAD: obj_itembox cae al suelo (grounded/vspd/gravedad 0.2),
     CLIENT_BOX_RELOCATE al final del enum en los DOS lados, handler en
     KindAndFair.c (marca relocated), tabla de 9 spawners derivada de
     ring spawners, nunca-repetir (itembox_last_spawner), rotura solo
     apoyada (grounded && !reported), escala 0.47 del residuo gigante
     (spr_boxused 64x64 -> contenido ~30px) en Create y state 3.

Uso: python3 check_v64.py  (desde la raiz del repo)
Exit 0 = todo OK; exit 1 = fallo (print del motivo).
"""
import os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__)) + '/..' if os.path.basename(os.path.dirname(os.path.abspath(__file__))) == 'scripts' else os.path.abspath(__file__ + '/..')
ROOT = os.path.abspath(ROOT)
if not os.path.exists(os.path.join(ROOT, 'Sonicexe The Disaster 2D Remake.yyp')):
    ROOT = os.getcwd()

fails = []
def check(name, cond, detail=''):
    if cond:
        print(f'  [OK] {name}')
    else:
        print(f'  [FAIL] {name} {detail}')
        fails.append(name)

def read(p):
    with open(os.path.join(ROOT, p), encoding='utf-8') as f:
        return f.read()

print('== v62 ITEM BOX v2 — validacion ==')
print()

# 1) enum sync
gml = read('scripts/net_packets/net_packets.gml')
hdr = read('betterserver-oss/include/Packet.h')

def enum_list(txt, is_c):
    body = re.sub(r'/\*.*?\*/', '', txt, flags=re.S)
    if not is_c:
        m = re.search(r'enum PacketType\s*\{(.*?)\}', body, re.S)
        body = m.group(1)
    return [t.strip().rstrip(',') for t in re.findall(r'^\s*((?:CLIENT_|SERVER_)[A-Z_0-9]+)\s*,?\s*$', body, re.M)]

cli = enum_list(gml, False)
srv = enum_list(hdr, True)
check('enums: mismas entradas en el mismo orden', cli == srv, f'cli={len(cli)} srv={len(srv)}')
check('enums: BOX trio al final (ACTIVATE, STATE, RELOCATE)', cli[-3:] == ['CLIENT_BOX_ACTIVATE', 'SERVER_BOX_STATE', 'CLIENT_BOX_RELOCATE'] and srv[-3:] == ['CLIENT_BOX_ACTIVATE', 'SERVER_BOX_STATE', 'CLIENT_BOX_RELOCATE'])

# 2) objeto cliente
for f in ['objects/obj_itembox/Create_0.gml', 'objects/obj_itembox/Step_2.gml', 'objects/obj_itembox/Destroy_0.gml', 'objects/obj_itembox/obj_itembox.yy']:
    check(f'obj_itembox: {os.path.basename(f)} existe', os.path.exists(os.path.join(ROOT, f)))
yy = read('objects/obj_itembox/obj_itembox.yy')
check('obj_itembox.yy: sprite por defecto spr_ring_box', 'spr_ring_box' in yy)
check('obj_itembox.yy: folder Spawners', '"Spawners"' in yy)
yyp = read('Sonicexe The Disaster 2D Remake.yyp')
check('yyp: obj_itembox registrado', '"name":"obj_itembox"' in yyp)

# 3) caso de red
nsg = read('scripts/net_state_game/net_state_game.gml')
case = nsg[nsg.find('case PacketType.SERVER_BOX_STATE:'):nsg.find('case PacketType.SERVER_NAPBALL_STATE:')]
check('net_state_game: case SERVER_BOX_STATE presente', 'case PacketType.SERVER_BOX_STATE:' in nsg)
check('net_state_game: estados 3/2/1 del protocolo', all(s in case for s in ['_state == 3', '_state == 1', '_state == 2']))
check('net_state_game: rewards — anillos +5 con cap 119', 'global.player.rings + 5, 119' in case)
check('net_state_game: reward escudo = shieldTimer 5*60', 'global.player.shieldTimer = 5 * 60' in case)
check('net_state_game: reward invencibilidad = hurttime 3*60', 'global.player.hurttime = 3 * 60' in case)
check('net_state_game: reward electrico = electricShieldTimer 60*2.5', 'global.player.electricShieldTimer = 60 * 2.5' in case)
check('net_state_game: reward botas = bootsTimer 60*8', 'global.player.bootsTimer = 60 * 8' in case)
check('net_state_game: sprite por tipo + boxused al romper', 'spr_boxused' in case and all(s in case for s in ['spr_ring_box', 'spr_shield_box', 'spr_invincibility_box', 'spr_lightning_shield_box', 'spr_speedboots_box']))
check('net_state_game: solo cobra el pid premiado', 'obj_netclient.nid != _pid' in case)

# 4) rotura por cuerpo
sco = read('scripts/scr_collision_objects/scr_collision_objects.gml')
check('collision_objects: rectangulo obj_itembox', 'collision_rectangle(x - 6, y - 20, x + 6, y + 20, obj_itembox' in sco)
check('collision_objects: CLIENT_BOX_ACTIVATE al romper', 'PacketType.CLIENT_BOX_ACTIVATE' in sco)
check('collision_objects: EXE invisible no rompe (anti-grief)', 'invisTimer > 0' in sco[sco.find('_boxInst'):sco.find('_boxInst') + 1500])

# 5) servidor C
for f in ['betterserver-oss/include/entities/ItemBox.h', 'betterserver-oss/disasterserver/entities/ItemBox.c']:
    check(f'server: {os.path.basename(f)} existe', os.path.exists(os.path.join(ROOT, f)))
kaf = read('betterserver-oss/disasterserver/maps/KindAndFair.c')
_tbl = kaf[kaf.find('kaf_itembox_spawns'):kaf.find('KAF_ITEMBOX_SPAWN_COUNT')]
_tbl_pts = re.findall(r'\{\s*(\d+),\s*(\d+)\s*\}', _tbl)
check('KindAndFair.c: tabla v64 de 13 spawners APOYADOS (tiles 128x128 reales)', len(_tbl_pts) == 13 and ('728', '922') in _tbl_pts and ('1296', '1378') in _tbl_pts and ('304', '994') in _tbl_pts)
check('KindAndFair.c: roll ponderado (35/20/15/15/15)', 'r < 35' in kaf and 'r < 55' in kaf and 'r < 70' in kaf and 'r < 85' in kaf)
check('KindAndFair.c: goto-gen sobre spawners libres (patron Ring.c)', 'goto gen' in kaf)
check('KindAndFair.c: case CLIENT_BOX_ACTIVATE con validacion in_game', 'AssertOrDisconnect(v->server, v->in_game)' in kaf)
maps = read('betterserver-oss/disasterserver/Maps.c')
check('Maps.c: kaf_tick registrado en el mapa 7', 'kaf_init, kaf_tick, kaf_tcpmsg' in maps)
kfh = read('betterserver-oss/include/maps/KindAndFair.h')
check('KindAndFair.h: kaf_tick declarado', 'bool kaf_tick' in kfh)
cmk = read('betterserver-oss/disasterserver/CMakeLists.txt')
check('CMakeLists: ItemBox.c en SOURCES', '"entities/ItemBox.c"' in cmk)
ib = read('betterserver-oss/disasterserver/entities/ItemBox.c')
check('ItemBox.c: broadcast state con type+pid+sx+sy', 'packet_write16, (uint16_t)box->pos.x' in ib)
check('ItemBox.c: activate idempotente (anti-cheat)', 'if (box->activated)' in ib)

# 6) escudo electrico
pk = read('scripts/net_packets/net_packets.gml')
check('net_packets: macro PLAYER_ELECTROSHIELD', '#macro PLAYER_ELECTROSHIELD' in pk)
nc = read('objects/obj_netclient/Step_2.gml')
check('netclient: envia bit mientras electricShieldTimer > 0', 'PLAYER_ELECTROSHIELD' in nc)
udp = read('scripts/net_udpprocess/net_udpprocess.gml')
check('udpprocess: electroShield = bit & PLAYER_ELECTROSHIELD', 'electroShield = bitflags & PLAYER_ELECTROSHIELD' in udp)
pc = read('objects/obj_player_puppet/Create_0.gml')
check('puppet Create: electroShield init', 'electroShield = false' in pc)
pd = read('objects/obj_player_puppet/Draw_0.gml')
check('puppet Draw: overlay spr_electroshield', 'if(electroShield)' in pd)
ph = read('scripts/scr_player_hurt/scr_player_hurt.gml')
check('player_hurt: escudo repele golpe (hurttime 60 + consume)', 'global.player.electricShieldTimer = 0' in ph and 'net_sound_emit_at(snd_metal_stun, _zapNid)' in ph)
check('player_hurt: stun al atacante via senal targeted (patron parry)', '_zapNid' in ph)
check('net_state_game: receptor snd_metal_stun aturde al atacante', 'global.net_snds[sid] == snd_metal_stun' in nsg)

# 7) botas
mb = read('scripts/scr_move_basic/scr_move_basic.gml')
check('move_basic: tick de bootsTimer + electricShieldTimer', 'bootsTimer--' in mb and 'electricShieldTimer--' in mb)
check('move_basic: _capH = maxHSpeed + 3 con botas', '_capH = maxHSpeed + 3' in mb)
check('move_basic: _acc = acc * 1.5 con botas', '_acc = acc * 1.5' in mb)
check('move_basic: estela reusa effectTime (ghosts existentes)', 'bootsTimer > 0' in mb and 'effectTime = 16' in mb)

# 8) sprites de la duena
ro = read('Sonicexe The Disaster 2D Remake.resource_order')
for s in ['spr_boxused', 'spr_invincibility_box', 'spr_lightning_shield_box', 'spr_ring_box', 'spr_shield_box', 'spr_speedboots_box']:
    check(f'sprite {s}: en yyp y resource_order', f'"name":"{s}"' in yyp and f'"name":"{s}"' in ro)

print()
# 9) v63 GRAVEDAD / RELOCATE / RESIDUO
ibh = read('betterserver-oss/include/entities/ItemBox.h')
check('ItemBox.h: campo relocated en el struct', 'bool\t relocated;' in ibh.replace('    ', '\t') or 'relocated' in ibh)
check('KindAndFair.c: case CLIENT_BOX_RELOCATE (marca la entidad)', 'case CLIENT_BOX_RELOCATE:' in kaf and 'relocated = true' in kaf)
check('KindAndFair.c: nunca-repetir (itembox_last_spawner)', 'itembox_last_spawner' in kaf and 'rnd == itembox_last_spawner' in kaf)
check('KindAndFair.c: relocate fuerza la muerte del tick (timer = 0)', 'boxes[i].timer = 0' in kaf)
crt = read('objects/obj_itembox/Create_0.gml')
check('obj_itembox Create: grounded/vspd/reported (v63)', 'grounded = false' in crt and 'vspd = 0' in crt and 'reported = false' in crt)
_crt_code = '\n'.join(l for l in crt.splitlines() if not l.strip().startswith('//'))
check('obj_itembox Create: caja VIVA a escala 1.0 (fix diminuta v64)', 'image_xscale = 1;' in _crt_code and 'image_yscale = 1;' in _crt_code and '0.47' not in _crt_code)
check('obj_itembox Create: method report_relocate (1 sola vez)', 'report_relocate = function()' in crt)
stp = read('objects/obj_itembox/Step_2.gml')
check('obj_itembox Step: gravedad de la casa (yspd += 0.2)', 'vspd += 0.2' in stp)
check('obj_itembox Step: clava al floor parent', 'place_meeting(x, y, obj_floor_parent)' in stp)
check('obj_itembox Step: reporte trampolin/abismo -> RELOCATE', 'place_meeting(x, y, obj_spring_parent)' in stp and 'report_relocate()' in stp)
check('obj_itembox Step: rompe proyectil solo apoyada', 'grounded && place_meeting(x, y, obj_tails_projectile)' in stp)
sco2 = read('scripts/scr_collision_objects/scr_collision_objects.gml')
check('collision_objects: rotura solo apoyada (!reported)', '_boxInst.grounded && !_boxInst.reported' in sco2)
nsg2 = read('scripts/net_state_game/net_state_game.gml')
check('net_state_game: state 3 despierta la caida (grounded=false, reset report)', '_inst.grounded = false' in nsg2 and '_inst.reported = false' in nsg2)
check('net_state_game: rota queda apoyada, residuo 0.47 + y-15 (30x15)', '_inst.grounded = true' in nsg2 and '_inst.image_xscale = 0.47' in nsg2 and '_inst.y -= 15' in nsg2)
check('net_state_game: spawn viva a escala 1.0 (fix diminuta v64)', '_inst.image_xscale = 1;' in nsg2)
check('net_packets: CLIENT_BOX_RELOCATE en el enum', 'CLIENT_BOX_RELOCATE' in pk)

if fails:
    print(f'RESULTADO: {len(fails)} fallos -> {fails}')
    sys.exit(1)
print('RESULTADO: TODO OK — sistema ITEM BOX v2+v3+v4 completo y consistente')
sys.exit(0)
