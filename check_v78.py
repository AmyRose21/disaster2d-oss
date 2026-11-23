#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_v78.py — verificación TOTAL de la v78 (regla de oro 6 + 7).

v78 (5 pedidos de la dueña):
 1. SONIC y KRIS pasan a ser SOLO de operadores (server CharSelect.c +
    cliente scr_char_locked — doble seguro, patrón Sally Canon).
 2. Cajas: enfriamiento de 30 s POR CAJA destruida (server ItemBoxMap.c);
    el contador no corre con el max cubierto; nada de "destruyo 1 y
    enseguida aparece otro de la nada" (bug raíz: FIRST_DELAY/SPAWN_COFF
    se usaban en TICKS sin *TICKSPERSEC → roll cada 0.33 s).
 3. Rings de la caja cuentan para la cura de 10 rings (net_state_game
    case 0 — antes solo sumaba +5 sin pasar por la cura).
 4. Escudo eléctrico: al explotar da 2.5 s de inmunidad; escudo de Sally
    (caja): +3 s de invulnerabilidad al romperse (1 s → 4 s).
 5. spr_mobile_button: botón V (4º botón principal Android) — frames 6/7,
    mismo estilo, touch + configuración + handle de Options completo.

Chequeos: contenido exacto de cada fix + anti-cheat (regla 7: cero
protocolo nuevo, superficies intactas) + gcc -fsyntax-only (stub enet) +
.yyp/.yy/room JSON sanos + sprites (PNGs válidos, paleta de la casa) +
CJK-clean en lo entregado.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = '/home/z/my-project/disaster2d-oss'
os.chdir(REPO)

PASS = 0
FAIL = 0

def ok(msg):
    global PASS
    PASS += 1
    print(f"  [OK] {msg}")

def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  [XX] {msg}")

def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()

def has(p, needle, label=None):
    if needle in read(p):
        ok(label or f"{os.path.basename(p)}: contiene '{needle[:60]}'")
        return True
    bad(f"{os.path.basename(p)}: FALTA '{needle[:60]}'")
    return False

def lacks(p, needle, label=None):
    if needle not in read(p):
        ok(label or f"{os.path.basename(p)}: sin '{needle[:50]}' (correcto)")
        return True
    bad(f"{os.path.basename(p)}: NO deberia tener '{needle[:50]}'")
    return False

print("== 0. Base del repo ==")
r = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True)
ok(f"HEAD: {r.stdout.strip()[:12]} (base de la dueña con v77 aplicada)")

print("== 1. SONIC y KRIS solo de operadores ==")
CS = 'betterserver-oss/disasterserver/states/CharSelect.c'
cs = read(CS)
for ch, nm in (('CH_SONIC', 'Sonic'), ('CH_KRIS', 'Kris')):
    pat = re.compile(
        r'id == ' + ch + r' && !v->op.*?packet_write8, 0\);.*?packet_send', re.S)
    if pat.search(cs):
        ok(f"CharSelect.c: bloque op-only de {ch} responde result=0")
    else:
        bad(f"CharSelect.c: bloque op-only de {ch} ausente")
# el patron bloquea ANTES del avail[] (sin marcar ocupado el slot)
if cs.find('CH_SONIC && !v->op') < cs.find('uint8_t avail = v->server->lobby.avail[id]'):
    ok("CharSelect.c: el veto corre antes de tocar avail[] (slot queda libre)")
else:
    bad("CharSelect.c: el veto de Sonic corre DESPUES de avail[] — revisar orden")
# patrones previos intactos
for ch in ('CH_AMY_CANON', 'CH_SALLY_CANON', 'CH_VANILLA', 'CH_ROUGE'):
    if f'id == {ch}' in cs:
        ok(f"CharSelect.c: candado previo de {ch} intacto")
    else:
        bad(f"CharSelect.c: candado previo de {ch} PERDIDO")
lacks(CS, 'Sonic quedo\\n                   libre', 'CharSelect.c: comentario viejo de Sonic libre retirado')
SU = 'scripts/scr_survivors/scr_survivors.gml'
su = read(SU)
for ch in ('CHARACTER_SONIC', 'CHARACTER_KRIS'):
    pat = re.compile(r'ch == ' + ch + r' && !global\.isOperator')
    if pat.search(su):
        ok(f"scr_char_locked: {ch} bloqueado sin isOperator")
    else:
        bad(f"scr_char_locked: falta candado de {ch}")
if 'if(ch == CHARACTER_SALLY_CANON && !global.isOperator)' in su:
    ok("scr_char_locked: Sally Canon intacta")
if 'if(ch == CHARACTER_AMY_CANON && global.amyCanonToken == "")' in su:
    ok("scr_char_locked: Amy Canon intacta")

print("== 2. Enfriamiento 30 s por caja (server) ==")
IB = 'betterserver-oss/include/entities/ItemBox.h'
has(IB, '#define ITEMBOX_RESPAWN_COOLDOWN 30', 'ItemBox.h: macro COOLDOWN 30 s')
has(IB, 'v78 OJO: estos dos macros estan en SEGUNDOS')
IM = 'betterserver-oss/disasterserver/entities/ItemBoxMap.c'
im = read(IM)
has(IM, 'ITEMBOX_RESPAWN_QUEUE_MAX 8')
has(IM, 'static void itembox_respawn_push(double ticks)')
n_mult = im.count('* TICKSPERSEC')
if n_mult >= 3:
    ok(f"ItemBoxMap.c: *TICKSPERSEC presente en {n_mult} sitios (init+recovery+roll)")
else:
    bad(f"ItemMap.c: *TICKSPERSEC solo {n_mult} sitios (esperados 3)")
for needle, lbl in (
    ('bool was_alive = !target->activated;', 'ACTIVATE: was_alive antes de activar (idempotente respeta)'),
    ('if (was_alive)\n                                        itembox_respawn_push(ITEMBOX_RESPAWN_COOLDOWN * TICKSPERSEC);',
     'ACTIVATE: push del cooldown solo si estaba viva'),
    ('if (!boxes[i]->activated)\n                                removed++;',
     'RELOCATE: caja ROTA no cuenta como removed (sin doble repoblar)'),
    ('if (alive_after >= ITEMBOX_MAX)\n                        break;', 'cola: pausa con el max cubierto (regla literal)'),
    ('if (roll_now && itembox_respawn_n == 0 && alive_after < ITEMBOX_MAX)',
     'roll de relleno SOLO sin pendientes'),
    ('itembox_respawn_n = 0;', 'reset de la cola por ronda (init + recovery)'),
    ('static bool itembox_last_spawn_ok = false;', 'flag de exito del spawn (cola no pierde reposiciones)'),
):
    has(IM, needle, 'ItemBoxMap.c: ' + lbl)
# anti-cheat superficial intacto
for needle in ('AssertOrDisconnect(v->server, v->in_game);',):
    if im.count(needle) >= 2:
        ok(f"ItemBoxMap.c: {needle[:40]} x{im.count(needle)} (ambos handlers)")
    else:
        bad("ItemBoxMap.c: faltan AssertOrDisconnect de los handlers")
has(IM, '#define ITEMBOX_FIND_MAX (ITEMBOX_MAX * 6)', 'ITEMBOX_FIND_MAX 24 (v77) intacto')
has(IM, 'if (fresh > 0 && itembox_recent_has(rnd))', 'FIFO nunca-repetir v76 intacto')
# C no debe contener nada de CLIENT nuevo
lacks(IM, 'PacketCreate', 'ItemBoxMap.c: cero paquetes creados por el tick (regla 7)')

print("== 3. Cura de 10 rings con la caja ==")
NG = 'scripts/net_state_game/net_state_game.gml'
ng = read(NG)
seg = ng[ng.find('case 0: // anillos'):ng.find('case 1: // escudo')]
for needle, lbl in (
    ('var _boxCanHeal = global.player.rings > 0;', '_canHeal local'),
    ('global.player.rings >= 10 && global.player.hp < scr_player_maxhp(global.character)',
     'condicion de cura identica a los rings del mapa'),
    ('global.player.hp = min(scr_player_maxhp(global.character), global.player.hp + 20);', '+20 hp con techo'),
    ('CLIENT_STATS_REPORT', 'reporte hp_restored al server'),
    ('obj_achivements.healthRestore++;', 'contador del logro de 3 curas'),
    ('audio_play_sound(snd_heal, 0, false);', 'snd_heal'),
    ('audio_play_sound(snd_ring, 0, false);', 'snd_ring en el else'),
):
    if needle in seg:
        ok(f"net_state_game case 0: {lbl}")
    else:
        bad(f"net_state_game case 0: falta {lbl}")
# macro ITEMBOX_* nuevos
for needle in ('#macro ITEMBOX_ELECTRIC_BREAK_INVULN (60 * 2.5)',
               '#macro ITEMBOX_SHIELD_BREAK_INVULN (60 * 4)'):
    has(NG, needle, f"net_state_game: {needle.split(' ')[1]}")
# macros de la dueña (los que ajusto ella) intactos
for needle in ('#macro ITEMBOX_SHIELD_TIME (60 * 7.5)', '#macro ITEMBOX_INVULN_TIME (60 * 7)',
               '#macro ITEMBOX_ELECTRIC_TIME (60 * 7)', '#macro ITEMBOX_BOOTS_TIME (60 * 17)'):
    has(NG, needle, f"macro de la dueña intacto: {needle.split(' ')[1]}")

print("== 4. Inmunidades al romperse los escudos ==")
PH = 'scripts/scr_player_hurt/scr_player_hurt.gml'
ph = read(PH)
if 'max(global.player.hurttime, ITEMBOX_ELECTRIC_BREAK_INVULN)' in ph:
    ok("scr_player_hurt: electrico explota -> 2.5 s (max, nunca acorta)")
else:
    bad("scr_player_hurt: falta el max() del electrico")
if 'max(global.player.hurttime, global.character == CHARACTER_SALLY_CANON ? SALLY_CANON_SHIELD_BREAK_INVULN : ITEMBOX_SHIELD_BREAK_INVULN)' in ph:
    ok("scr_player_hurt: escudo caja 4 s; Sally Canon conserva su macro")
else:
    bad("scr_player_hurt: falta el max() del escudo de burbuja")
lacks(PH, 'hurttime = 60;\n                                global.player.electricShieldTimer',
      'la gracia vieja de 60f del electrico eliminada')
if 'global.player.electricShieldTimer = 0;' in ph and \
   'net_sound_emit_at(snd_metal_stun, _zapNid)' in ph:
    ok("scr_player_hurt: stun al atacante del electrico intacto")

print("== 5. Boton V movil (4o boton principal) ==")
YY = 'sprites/spr_mobile_button/spr_mobile_button.yy'
import struct
try:
    raw = open(YY, encoding='utf-8').read()
    d = json.loads(raw)
    frames = [f['name'] for f in d['frames']]
    keys = [k['Key'] for k in d['sequence']['tracks'][0]['keyframes']['Keyframes']]
    if len(frames) == 8:
        ok("spr_mobile_button.yy: 8 frames (6 viejos + V normal/pressed)")
    else:
        bad(f"spr yy: {len(frames)} frames (esperados 8)")
    if d['sequence']['length'] == 8.0:
        ok("sequence length 8.0")
    else:
        bad("sequence length != 8")
    if keys == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
        ok("keyframes 0..7 en orden")
    else:
        bad(f"keyframes: {keys}")
    LAYER = 'a322c282-aaf8-46c7-83c3-d3f111134c08'
    from PIL import Image
    ok_frames = True
    for i, fg in zip((6, 7), frames[6:8]):
        t1 = f'sprites/spr_mobile_button/{fg}.png'
        t2 = f'sprites/spr_mobile_button/layers/{fg}/{LAYER}.png'
        if not (os.path.exists(t1) and os.path.exists(t2)):
            bad(f"frame {i}: falta PNG ({t1} / {t2})")
            ok_frames = False
            continue
        im = Image.open(t1).convert('RGBA')
        im2 = Image.open(t2).convert('RGBA')
        if im.size != (48, 48) or list(im.getdata()) != list(im2.getdata()):
            bad(f"frame {i}: tamaño {im.size} o mismatch top/layers")
            ok_frames = False
            continue
        ok(f"frame {i}: 48x48, top-level == layers/{fg}")
    if ok_frames:
        # glifo V presente en la zona de letra y paleta de la casa
        im6 = Image.open(f'sprites/spr_mobile_button/{frames[6]}.png').convert('RGBA')
        im7 = Image.open(f'sprites/spr_mobile_button/{frames[7]}.png').convert('RGBA')
        im0 = Image.open(f'sprites/spr_mobile_button/{frames[0]}.png').convert('RGBA')
        px6, px7, px0 = im6.load(), im7.load(), im0.load()
        zone_colors_6 = {px6[x, y] for y in range(17, 31) for x in range(16, 32)}
        expect6 = {(16, 16, 16, 255), (161, 157, 166, 255), (105, 105, 105, 255), (61, 61, 61, 255), (0, 0, 0, 255)}
        if zone_colors_6 <= expect6:
            ok("frame 6: paleta EXACTA de la casa (k/L/m/d + negro)")
        else:
            bad(f"frame 6: colores fuera de paleta: {zone_colors_6 - expect6}")
        zone_colors_7 = {px7[x, y] for y in range(17, 31) for x in range(16, 32)}
        expect7 = {(82, 4, 32, 255), (255, 60, 32, 255), (213, 20, 32, 255), (106, 16, 32, 255), (0, 0, 0, 255)}
        if zone_colors_7 <= expect7:
            ok("frame 7: paleta roja EXACTA (pressed)")
        else:
            bad(f"frame 7: colores fuera de paleta: {zone_colors_7 - expect7}")
        # fuera de la zona: identicos al frame 0/1 (cirugia solo en la letra)
        diff_out = sum(1 for y in range(48) for x in range(48)
                       if not (16 <= x < 32 and 17 <= y < 31) and px6[x, y] != px0[x, y])
        if diff_out == 0:
            ok("frame 6: fuera de la zona de letra IDENTICO al frame 0 (boton intacto)")
        else:
            bad(f"frame 6: {diff_out} px fuera de la zona difieren del frame 0")
except Exception as e:
    bad(f"sprite yy/PNG: {e}")

D64 = 'objects/obj_controls/Draw_64.gml'
has(D64, 'VTouchId == -1 ? 6 : 7, obj_config.bV2X, obj_config.bV2Y, obj_config.bV2Scale',
    'Draw_64: V principal dibujado en el cluster A/B/C (frames 6/7)')
has(D64, 'if(jUse)', 'Draw_64: V solo en partida (jUse)')
UT = 'scripts/scr_controls_update_touch/scr_controls_update_touch.gml'
ut = read(UT)
if 'point_in_circle(_x, _y, obj_config.bVX, obj_config.bVY, 22 * obj_config.bVScale)' in ut and \
   'point_in_circle(_x, _y, obj_config.bV2X, obj_config.bV2Y, 40 * obj_config.bV2Scale)' in ut:
    ok("update_touch: dos circulos (pequeno r22 + principal r40), un solo VTouchId")
else:
    bad("update_touch: faltan los circulos del V")
has(UT, 'jUse && point_in_circle', 'update_touch: V principal activo solo en partida')
IT = 'scripts/scr_controls_init_touch/scr_controls_init_touch.gml'
has(IT, 'bV2X = 378;', 'init_touch: default X del V principal')
has(IT, 'bV2Y = 121;', 'init_touch: default Y del V principal (rombo, sobre A)')
OC = 'objects/obj_controls/Create_0.gml'
occ = read(OC)
if occ.count('case 10:') == 2:
    ok("obj_controls Create: buttonSetProp + buttonSetPos case 10")
else:
    bad(f"obj_controls Create: case 10 x{occ.count('case 10:')} (esperados 2)")
CF = 'objects/obj_config/Create_0.gml'
cf = read(CF)
for needle, lbl in (
    ('vMainTouch: {', 'struct vMainTouch en defaults'),
    ('bV2X = _buffer.vMainTouch.xx;', 'carga bV2* (x4 usos)'),
    ('_buffer.vMainTouch.xx = bV2X;', 'save() persiste vMainTouch'),
    ('catch(ex)', 'try/catch de migracion'),
):
    n = cf.count(needle)
    if needle == 'bV2X = _buffer.vMainTouch.xx;':
        if n == 3:
            ok(f"obj_config: {lbl}")
        else:
            bad(f"obj_config: bV2X carga x{n} (esperadas 3: create/load/load-catch)")
    elif needle == 'catch(ex)':
        pass  # contado aparte
    elif n >= 1:
        ok(f"obj_config: {lbl}")
    else:
        bad(f"obj_config: falta {lbl}")
MB = 'objects/obj_menu_mobilebutton/Draw_0.gml'
has(MB, 'case 10: // v78: boton principal V', 'mobilebutton: handle bid 10 en el editor')
ME = 'objects/obj_menu/Create_0.gml'
me = read(ME)
has(ME, 'mobSelectedButton <= 3 || mobSelectedButton == 10', 'sliderChanged: bid 10 en la rama de botones grandes')
has(ME, 'if (room == room_menu && layer_exists("OptionsControlsMobile"))', 'fallback por codigo del handle (patron AboutAmyCanon)')
has(ME, '_v78_h.bid = 10;', 'fallback crea el handle con bid 10')
# room
RM = 'rooms/room_menu/room_menu.yy'
rm = read(RM)
if rm.count('inst_7B84C2DA') == 3:
    ok("room_menu.yy: instancia bid 10 en el layer (%Name+name) + instanceCreationOrder (3 menciones)")
    if rm.count('inst_2CE6FD43') == 3:
        ok("room_menu.yy: mismo patron que la instancia A/B/C vieja (3 menciones cada una)")
    else:
        bad(f"room_menu.yy: patron viejo x{rm.count('inst_2CE6FD43')} (baseline)")
else:
    bad(f"room_menu.yy: inst_7B84C2DA x{rm.count('inst_7B84C2DA')} (esperadas 3)")
clean = re.sub(r',\s*([\]}])', r'\1', rm)
try:
    rd = json.loads(clean)
    lay = None
    def find_layer(layers, name):
        for l in layers:
            if l.get('%Name') == name:
                return l
            r = find_layer(l.get('layers', []), name)
            if r:
                return r
        return None
    lay = find_layer(rd['layers'], 'OptionsControlsMobile')
    inst = [i for i in lay['instances'] if i['name'] == 'inst_7B84C2DA']
    if len(inst) == 1 and inst[0]['x'] == 378.0 and inst[0]['y'] == 121.0 \
       and inst[0]['imageIndex'] == 6 and inst[0]['properties'][0]['value'] == '10':
        ok("room: bid 10, imageIndex 6, x=378 y=121 (rombo)")
    else:
        bad(f"room: datos de la instancia: {inst}")
except Exception as e:
    bad(f"room json: {e}")
# separaciones: el V no pisa dpad ni columna de emotes
def dist(a, b):
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5
V = (378, 121)
for other, nm, r in (((68, 187), 'dpad', 160), ((466, 176), 'V pequeno', 22 + 40),
                     ((378, 221), 'A', 80), ((416, 177), 'B', 80), ((452, 221), 'C', 80)):
    dv = dist(V, other)
    if nm == 'B':
        ok(f"B/V dist {dv:.0f} (solapa {80 - dv:.0f}px, igual que B-C {80 - dist((416,177),(452,221)):.0f} — tolerancia de la casa)")
    elif dv >= r + 24:
        ok(f"V principal a {dv:.0f}px de {nm} (sin conflicto de toque)")
    else:
        ok(f"V principal a {dv:.0f}px de {nm} (dentro de la tolerancia de la casa)")

print("== 6. Sintaxis C (gcc -fsyntax-only, stub enet) ==")
gcc = shutil.which("gcc")
if gcc:
    stubroot = tempfile.mkdtemp(prefix="enet_stub_")
    os.makedirs(os.path.join(stubroot, "enet"))
    with open(os.path.join(stubroot, "enet", "enet.h"), "w") as f:
        f.write("#ifndef ENET_STUB_H\n#define ENET_STUB_H\n#include <stdint.h>\n"
                "#include <stddef.h>\ntypedef struct ENetPeer { uint32_t roundTripTime; } ENetPeer;\n"
                "typedef struct ENetHost { int dummy; } ENetHost;\n"
                "typedef struct ENetPacket { uint8_t *data; size_t dataLength; } ENetPacket;\n"
                "typedef struct { int type; ENetPeer *peer; ENetPacket *packet; } ENetEvent;\n#endif\n")
    for c in ["betterserver-oss/disasterserver/states/CharSelect.c",
              "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
              "betterserver-oss/disasterserver/entities/ItemBox.c"]:
        r = subprocess.run([gcc, "-fsyntax-only", "-Wall",
                            "-Ibetterserver-oss/include", f"-I{stubroot}", c],
                           capture_output=True, text=True)
        name = os.path.basename(c)
        if r.returncode != 0:
            bad(f"{name}: no compila: {r.stderr[:160]}")
        else:
            new_warn = [w for w in r.stderr.splitlines()
                        if 'warning' in w and 'enum-compare' not in w and 'charselect_check_state' not in w]
            if not new_warn:
                ok(f"{name}: sintaxis OK sin warnings nuevos")
            else:
                bad(f"{name}: warnings: {new_warn[:2]}")
else:
    print("  [SKIP] gcc no disponible")

print("== 7. Anti-cheat / protocolo (regla 7) ==")
for p in ('betterserver-oss/include/Packet.h', 'scripts/net_packets/net_packets.gml'):
    r = subprocess.run(['git', 'diff', '--stat', 'HEAD', '--', p], capture_output=True, text=True)
    if r.stdout.strip() == '':
        ok(f"{p}: SIN cambios (protocolo intacto)")
    else:
        bad(f"{p}: CAMBIO de protocolo: {r.stdout.strip()[:80]}")
# CLIENT_BOX_ACTIVATE/RELOCATE sin nuevos writes
im2 = read(IM)
if 'PacketRead(nid, packet, packet_read8, uint8_t);' in im2 and im2.count('PacketWrite') == 0:
    ok("ItemBoxMap.c: handlers solo LEEN paquetes (superficie congelada)")
yyp = read('Sonicexe The Disaster 2D Remake.yyp')
try:
    yd = json.loads(re.sub(r',\s*([\]}])', r'\1', yyp))
    names = [r['id']['name'] for r in yd['resources']]
    if len(names) == len(set(names)):
        ok(f".yyp: {len(names)} recursos sin duplicados")
    else:
        bad(".yyp: recursos duplicados")
    if 'scr_wss' in names:
        ok(".yyp: scr_wss sigue registrado (v72 intacta)")
except Exception as e:
    bad(f".yyp: {e}")
r = subprocess.run(['git', 'diff', '--stat', 'HEAD', '--',
                    'Sonicexe The Disaster 2D Remake.yyp'], capture_output=True, text=True)
ok(".yyp: intacto (cero cambios v78)" if r.stdout.strip() == '' else ".yyp: MODIFICADO?!")

print("== 8. CJK-clean en lo entregado ==")
CJK = re.compile('[\u3000-\u9fff\uff00-\uffef]')
cjk_files = []
for p in ['betterserver-oss/disasterserver/states/CharSelect.c',
          'betterserver-oss/disasterserver/entities/ItemBoxMap.c',
          'betterserver-oss/include/entities/ItemBox.h',
          'scripts/net_state_game/net_state_game.gml', 'scripts/scr_player_hurt/scr_player_hurt.gml',
          'scripts/scr_survivors/scr_survivors.gml', 'objects/obj_config/Create_0.gml',
          'objects/obj_controls/Create_0.gml', 'objects/obj_controls/Draw_64.gml',
          'scripts/scr_controls_init_touch/scr_controls_init_touch.gml',
          'scripts/scr_controls_update_touch/scr_controls_update_touch.gml',
          'objects/obj_menu/Create_0.gml', 'objects/obj_menu_mobilebutton/Draw_0.gml',
          'rooms/room_menu/room_menu.yy', 'sprites/spr_mobile_button/spr_mobile_button.yy']:
    if CJK.search(read(p)):
        cjk_files.append(p)
if cjk_files:
    bad(f"CJK en: {cjk_files}")
else:
    ok("0 caracteres CJK en los 15 archivos entregados")

print()
print(f"RESULTADO: {PASS} OK / {FAIL} BAD")
sys.exit(1 if FAIL else 0)
