#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""validate_v5_3.py — revisa que el proyecto tenga la base v5.3 del Show LMS
(LMS por personaje) bien puesta. Uso:
    python validate_v5_3.py [carpeta del proyecto]
Sin argumento revisa la carpeta donde esté (busca el .yyp hacia arriba).
"""
import io, os, re, sys

# CHARACTER_* (cliente) <-> CH_* (server), los 14 supervivientes
CHMAP = {
    'CHARACTER_TAILS': 'CH_TAILS', 'CHARACTER_KNUX': 'CH_KNUX',
    'CHARACTER_EGGMAN': 'CH_EGGMAN', 'CHARACTER_AMY': 'CH_AMY',
    'CHARACTER_CREAM': 'CH_CREAM', 'CHARACTER_SALLY': 'CH_SALLY',
    'CHARACTER_AMY_CANON': 'CH_AMY_CANON', 'CHARACTER_SONIC': 'CH_SONIC',
    'CHARACTER_SALLY_CANON': 'CH_SALLY_CANON', 'CHARACTER_VANILLA': 'CH_VANILLA',
    'CHARACTER_METAL': 'CH_METAL', 'CHARACTER_AMELIA': 'CH_AMELIA',
    'CHARACTER_BLAZE': 'CH_BLAZE', 'CHARACTER_FLEETWAY_AMY': 'CH_FLEETWAY_AMY',
}

ok = fail = 0
def rep(good, msg):
    global ok, fail
    print(('  [OK] ' if good else '  [X] ') + msg)
    if good: ok += 1
    else: fail += 1

def find_root():
    if len(sys.argv) > 1 and os.path.isdir(sys.argv[1]):
        return sys.argv[1]
    d = os.getcwd()
    for _ in range(4):
        if any(f.endswith('.yyp') for f in os.listdir(d) if os.path.isfile(os.path.join(d, f))):
            return d
        d = os.path.dirname(d)
    return os.getcwd()

root = find_root()
print('Revisando: ' + root)
print('=' * 62)

def rd(rel):
    p = os.path.join(root, rel)
    if not os.path.isfile(p):
        return None
    with io.open(p, 'r', encoding='utf-8', errors='replace') as f:
        return f.read()

# ---------- 1) scr_lms.gml (cliente) ----------
print('[1] scripts/scr_lms/scr_lms.gml')
gml = rd('scripts/scr_lms/scr_lms.gml')
if gml is None:
    rep(False, 'existe')
    gml = ''
else:
    rep(True, 'existe')
    rep('global.lmsCharSongs = ds_map_create();' in gml, 'base v5.3 (global.lmsCharSongs)')
    if 'global.lmsSongs' in gml:
        rep(False, 'quedó lista vieja v5.1 (global.lmsSongs) — falta actualizar')
    else:
        rep(True, 'sin lista vieja v5.1')
    rep('function scr_lms_play_song(ch, idx)' in gml, 'scr_lms_play_song(ch, idx) — 2 argumentos')
    for mac in ['LMS_HP', 'LMS_BLOCK_CHANCE', 'LMS_BLOCK_INVULN', 'LMS_STUN_BONUS', 'LMS_SPIN_STUN']:
        rep(('#macro ' + mac) in gml, 'macro ' + mac)
    rep('if(global.character != CHARACTER_SONIC || !global.lmsActive)' in gml,
        'pasivas de bloqueo SOLO de Sonic')

client_map = {}
if gml:
    for m in re.finditer(r'global\.lmsCharSongs\[\?\s*(CHARACTER_\w+)\]\s*=\s*\[([^\]]*)\]', gml):
        client_map[m.group(1)] = [a.strip() for a in m.group(2).split(',') if a.strip()]
print('  [i] personajes con show en el cliente: %d' % len(client_map))

# ---------- 2) net_state_game.gml (cliente) ----------
print('[2] scripts/net_state_game/net_state_game.gml')
nsg = rd('scripts/net_state_game/net_state_game.gml') or ''
rep('var _lmsChar = buffer_read_s(rbuff, buffer_u8);' in nsg, 'lee el personaje del show (u8)')
rep('var _lmsSong = buffer_read_s(rbuff, buffer_u8);' in nsg, 'lee la canción (u8)')
rep('scr_lms_play_song(_lmsChar, _lmsSong)' in nsg, 'toca la canción DEL personaje')
rep('global.character == _lmsChar' in nsg, 'la vida se la rellena al personaje del show')
rep('global.player.hp = LMS_HP;' in nsg, 'cura con LMS_HP')

# ---------- 3) net_packets.gml + Packet.h ----------
print('[3] enum del paquete (cliente y server)')
npk = rd('scripts/net_packets/net_packets.gml') or ''
pkh = rd('betterserver-oss/include/Packet.h') or ''
rep('SERVER_GAME_LMS' in npk, 'SERVER_GAME_LMS en net_packets.gml')
rep('SERVER_GAME_LMS' in pkh, 'SERVER_GAME_LMS en Packet.h')

# ---------- 4) Server.h ----------
print('[4] betterserver-oss/include/Server.h')
srv = rd('betterserver-oss/include/Server.h') or ''
rep('LMS_SHOWS' in srv, 'tabla LMS_SHOWS (v5.3)')
rep('LMS_SONG_SEC' not in srv and 'LMS_TIME_SEC' not in srv, 'sin listas viejas v5.0/v5.1')
rep('uint8_t lms_char;' in srv, 'campo lms_char en el struct Game')
rep('uint8_t lms_song;' in srv, 'campo lms_song en el struct Game')
mm = re.search(r'#define LMS_MAX_SONGS (\d+)', srv)
max_songs = int(mm.group(1)) if mm else 0
rep(bool(mm), 'LMS_MAX_SONGS = ' + str(max_songs))

server_rows = {}
if srv:
    for m in re.finditer(r'\{\s*(CH_\w+),\s*(\d+),\s*\{([^}]*)\}\s*\}', srv):
        ch, n, secs = m.group(1), int(m.group(2)), [int(x) for x in m.group(3).split(',') if x.strip()]
        server_rows[ch] = (n, secs)
rep(bool(server_rows) or 'LMS_SHOW_COUNT 0' in srv,
    'entradas en LMS_SHOWS: ' + str(len(server_rows)) + (' (ninguna: LMS apagado)' if not server_rows else ''))
for ch, (n, secs) in sorted(server_rows.items()):
    rep(1 <= n <= max_songs and len(secs) == n,
        'fila %s coherente (%d canción/es, %s)' % (ch, n, secs))

# ---------- 5) Game.c ----------
print('[5] betterserver-oss/disasterserver/states/Game.c')
gc = rd('betterserver-oss/disasterserver/states/Game.c') or ''
rep('LMS_SHOWS[i].ch == (uint8_t)last->surv_char' in gc, 'disparo POR PERSONAJE (busca en LMS_SHOWS)')
rep('last->surv_char == CH_SONIC' not in gc, 'sin gate viejo solo-Sonic')
rep('server->game.lms_char = show->ch;' in gc, 'guarda el personaje del show')
rep('packet_write8, server->game.lms_char' in gc, 'manda char+song en el paquete')
rep('v->server->game.lms_char' in gc, 'reenvío a reconexiones con char+song')

# ---------- 6) sonidos ----------
print('[6] sonidos de las listas')
for cm, assets in sorted(client_map.items()):
    for a in assets:
        yy = rd('sounds/%s/%s.yy' % (a, a))
        if yy is None:
            rep(False, 'sounds/%s/%s.yy existe (%s)' % (a, a, cm))
            continue
        dm = re.search(r'"duration":([0-9.]+)', yy)
        sm = re.search(r'"soundFile":"([^"]+)"', yy)
        rep(bool(dm) and bool(sm), '%s (%s): duración %s · %s' % (
            a, cm, dm.group(1) if dm else '?', sm.group(1) if sm else '?'))

# ---------- 7) cliente <-> server ----------
print('[7] listas cliente <-> server consistentes')
cli_ch = {CHMAP[c] for c in client_map if c in CHMAP}
rep(cli_ch == set(server_rows),
    'mismos personajes en los dos lados' + ('' if cli_ch == set(server_rows) else
    ' (cliente: %s · server: %s)' % (sorted(cli_ch), sorted(server_rows))))
for cm, assets in sorted(client_map.items()):
    ch = CHMAP.get(cm)
    if ch not in server_rows:
        continue
    n, secs = server_rows[ch]
    if n != len(assets):
        rep(False, '%s: %d canciones en el cliente pero %d en el server' % (cm, len(assets), n))
        continue
    for i, a in enumerate(assets):
        yy = rd('sounds/%s/%s.yy' % (a, a)) or ''
        dm = re.search(r'"duration":([0-9.]+)', yy)
        dur = round(float(dm.group(1))) if dm else None
        if dur is not None and abs(dur - secs[i]) > 1:
            rep(False, '%s #%d: duración %ds en el .yy pero %ds en el server' % (cm, i + 1, dur, secs[i]))

# ---------- 8) Suite ----------
print('[8] Suite_TD2D.html')
st = rd('Suite_TD2D.html')
rep(st is not None and 'Suite TD2D — parte 6 (v5.3)' in st, 'Suite con módulo Show LMS v5.3')
rep(st is not None and 'LMS_CHARS' in st, 'Suite con lista de personajes')

print('=' * 62)
print('RESULTADO: %d OK · %d FAIL' % (ok, fail))
print('Si algo falla: aplica v5_3_git/ACTUALIZAR_V5_3.bat (o el botón')
print('«⬆ Actualizar base a v5.3» del Suite) y recompila el server.')
sys.exit(1 if fail else 0)
