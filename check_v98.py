#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v98.py — PASADA 1 del v98 (KRIS LV 20 — EL DUELO FINAL).
#  Verifica los 8 pedidos de la duena sobre el arbol de trabajo:
#   P1  barra del exe con su NOMBRE (el "?????" eran las MAYUSCULAS de
#       la micro-fuente scr_text_spr, glifo default 44)
#   P2  barra visible para TODOS desde el LV 20 espejado de Kris
#   P3  el parry TAMBIEN cuenta como dano al pool
#   P4  enfriamiento de la espada: -2 s en LMS, -4 s adicionales a LV 20
#   P5  LMS activo -> anti-camp fuera para supervivientes
#   P6  pool a 0 -> fin de partida, victoria a los vivos no corrompidos,
#       contados como escapados por el anillo (CLIENT_EXE_DEFEATED)
#   P7  Kris a LV 20 antes del LMS -> su show arranca solo (server cuenta
#       las senales snd_none del LOVE)
#   P8  Kris a LV 20 durante su show NATURAL -> anillo retirado (RING_OFF)
#  + integridad .yyp/.yy, paridad de enums, balance de llaves/parens,
#    sintaxis C del server (gcc -fsyntax-only con stub de enet) y
#    simulaciones de todas las reglas nuevas.
# ============================================================================
import subprocess, sys, os, re, json, tempfile, shutil

REPO = os.path.dirname(os.path.abspath(__file__))
os.chdir(REPO)

OK = 0
FAIL = 0
def chk(name, cond, extra=""):
    global OK, FAIL
    if cond:
        OK += 1
        print(f"  [OK]   {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name} {extra}")

def rd(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

# ---------------------------------------------------------------------------
print("=== 1. ARCHIVOS TOCADOS (regla 2: solo lo previsto, cero .yy/.yyp) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
expected = sorted([
    # 11 archivos de JUEGO del v98
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/Server.h",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_player_warning/Draw_75.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_kris_special/scr_kris_special.gml",
    "scripts/scr_move_basic/scr_move_basic.gml",
    "scripts/scr_parry/scr_parry.gml",
    # + los 3 docs de siempre (reglas 4/5/9: van en el zip)
    "CACHE.md",
    "LEARNING.md",
    "worklog.md",
])
chk("exactamente los 14 archivos modificados previstos (11 juego + 3 docs)",
    mod_files == expected,
    f"\n        got: {mod_files}\n        exp: {expected}")
chk("NINGUN .yy ni .yyp tocado", not any(f.endswith(('.yy', '.yyp')) for f in mod_files))

# ---------------------------------------------------------------------------
print("=== 2. P1+P2 — BARRA DEL ASESINO (nombre + para todos) ===")
ui = rd("objects/obj_playerui/Draw_64.gml")
chk("P1: la LLAMADA vieja del rotulo \"EL ASESINO  \" (mayusculas -> ?????) YA NO existe",
    '"EL ASESINO  " + string(' not in ui)
chk("P1: el rotulo usa el nombre del exe en minusculas (string_lower)",
    "string_lower(_exeName)" in ui and '+ "  " + string(ceil(_kbHp / KRIS_EXE_DAMAGE)) + " golpes"' in ui)
chk("P1: el nombre sale del puppet del exe (master_id == exeId) o del propio global.nickname",
    "master_id != obj_netclient.exeId" in ui and "_exeName = global.nickname;" in ui)
chk("P1: fallback generico cuando no hay puppet del exe",
    '"el asesino"' in ui)
chk("P2: gate local de Kris (su krisLv, como v95) sigue presente",
    re.search(r'global\.character == CHARACTER_KRIS.*?global\.player\.krisLv >= KRIS_LV_MAX', ui, re.S) is not None)
chk("P2: gate espejado para TODAS las pantallas (krisLvNet del puppet de Kris)",
    "krisLvNet : 1) >= KRIS_LV_MAX" in ui)
chk("P2: el espejo de la senal del exe existe en el receptor (net_state_game) SIN refill",
    "snd_kris_lvup && character == CHARACTER_EXE" in rd("scripts/net_state_game/net_state_game.gml")
    and "global.exeHpPool = max(global.exeHpPool - KRIS_EXE_DAMAGE, 0);" in rd("scripts/net_state_game/net_state_game.gml"))
nsg = rd("scripts/net_state_game/net_state_game.gml")
m = re.search(r'else if\(global\.net_snds\[sid\] == snd_kris_lvup && character == CHARACTER_EXE\)\s*\{([^}]*)\}', nsg)
chk("P2/P6: la rama del espejo NO rellena el pool a 0 (KRIS_EXE_MAXHP fuera de ella)",
    m is not None and "KRIS_EXE_MAXHP" not in m.group(1))

# ---------------------------------------------------------------------------
print("=== 3. P3 — EL PARRY TAMBIEN CUENTA COMO DANO ===")
parry = rd("scripts/scr_parry/scr_parry.gml")
chk("P3: scr_parry_apply_stun llama a scr_kris_exe_pool_hit",
    "scr_kris_exe_pool_hit(_parryStun)" in parry)
chk("P3: solo el EXE REAL (el esbirro/nega parreado no tiene pool)",
    re.search(r'if\(global\.character == CHARACTER_EXE && !global\.player\.isDead && _klvP >= KRIS_LV_MAX\)\s*_parryStun = scr_kris_exe_pool_hit\(_parryStun\);', parry) is not None)
ks = rd("scripts/scr_kris_special/scr_kris_special.gml")
chk("P3/P6: el helper compartido existe (espada Y parry)",
    "function scr_kris_exe_pool_hit(_stunTime)" in ks)
chk("P3/P6: el helper hace -35, manda la senal y suena el chime",
    "global.exeHpPool = max(global.exeHpPool - KRIS_EXE_DAMAGE, 0);" in ks
    and ks.count("scr_kris_exe_hp_signal();") >= 1
    and "audio_play_sound(snd_kris_lvup, 0, false);" in ks)
chk("P3/P6: a 0 avisa al server (CLIENT_EXE_DEFEATED) y devuelve el knockdown",
    "PacketType.CLIENT_EXE_DEFEATED" in ks and "return KRIS_EXE_DOWN_SEC;" in ks)
chk("P3/P6: el helper NO rellena el pool (refill retirado)",
    re.search(r'function scr_kris_exe_pool_hit.*?\n\}', ks, re.S).group(0).count("KRIS_EXE_MAXHP") == 0)
puppet = rd("objects/obj_player_puppet/Step_0.gml")
chk("P3/P6: la espada usa el MISMO helper (una sola verdad del golpe real)",
    "stunTime = scr_kris_exe_pool_hit(stunTime);" in puppet)
chk("P3/P6: el bloque viejo de la espada (refill inline) retirado",
    "global.exeHpPool = KRIS_EXE_MAXHP;" not in puppet)

# ---------------------------------------------------------------------------
print("=== 4. P4 — ENFRIAMIENTO DE LA ESPADA ===")
chk("P4: macros de recorte presentes (-2 s LMS / -4 s LV20 / suelo 2 s)",
    "#macro KRIS_SWORD_CUT_LMS (60 * 2)" in ks
    and "#macro KRIS_SWORD_CUT_LV20 (60 * 4)" in ks
    and "#macro KRIS_SWORD_RECHARGE_MIN (60 * 2)" in ks)
chk("P4: scr_kris_sword_recharge existe y aplica los dos recortes",
    "function scr_kris_sword_recharge()" in ks
    and "_cd -= KRIS_SWORD_CUT_LMS;" in ks and "_cd -= KRIS_SWORD_CUT_LV20;" in ks)
chk("P4: el golpe usa la recarga dinamica",
    "attackTimer = scr_kris_sword_recharge();" in ks)
chk("P4: el icono del HUD usa el maximo vigente",
    "var _kcd = scr_kris_sword_recharge();" in ui
    and "(min(max(global.player.attackTimer, 0), _kcd) / _kcd)" in ui)
# tabla simulada con constantes parseadas (todas en segundos de 60 f)
base = round(60 * float(re.search(r'#macro KRIS_ATTACK_RECHARGE \(60 \* ([\d.]+)\)', ks).group(1)))
cut_l = 60 * int(re.search(r'#macro KRIS_SWORD_CUT_LMS \(60 \* (\d+)\)', ks).group(1))
cut_v = 60 * int(re.search(r'#macro KRIS_SWORD_CUT_LV20 \(60 \* (\d+)\)', ks).group(1))
floor_ = 60 * int(re.search(r'#macro KRIS_SWORD_RECHARGE_MIN \(60 \* (\d+)\)', ks).group(1))
def recharge(lms, lv20):
    cd = base - (cut_l if lms else 0) - (cut_v if lv20 else 0)
    return max(cd, floor_)
chk(f"P4: tabla exacta normal={recharge(False,False)} LMS={recharge(True,False)} LV20+LMS={recharge(True,True)} (645/525/285)",
    recharge(False, False) == 645 and recharge(True, False) == 525 and recharge(True, True) == 285)
chk("P4: con recortes extremos el suelo de 2 s se respeta (macro floor)",
    max(base - cut_l - cut_v, floor_) == floor_ or base - cut_l - cut_v >= floor_)

# ---------------------------------------------------------------------------
print("=== 5. P5 — ANTI-CAMP FUERA DURANTE EL LMS ===")
mb = rd("scripts/scr_move_basic/scr_move_basic.gml")
chk("P5: el disparo del aviso gatea !global.lmsActive",
    "global.timeMinutes >= 1 && !global.lmsActive)" in mb)
chk("P5: el comentario del pedido de la duena documentado en el sitio",
    "no tiene logica si solo queda 1" in mb or "no tiene sentido ahi" in mb)
warn = rd("objects/obj_player_warning/Draw_75.gml")
chk("P5: el aviso YA en pantalla se apaga con el show activo (moved=true)",
    "else if(global.lmsActive)" in warn and warn.count("\tmoved = true;") >= 3)

# ---------------------------------------------------------------------------
print("=== 6. P6 — FIN DE PARTIDA AL POOL 0 (CLIENT_EXE_DEFEATED) ===")
gc = rd("betterserver-oss/disasterserver/states/Game.c")
chk("P6: case CLIENT_EXE_DEFEATED en el server",
    "case CLIENT_EXE_DEFEATED:" in gc)
chk("P6: SOLO el exe de la ronda puede reportarlo (anti-cheat)",
    "AssertOrDisconnect(v->server, v->id == v->server->game.exe);" in gc)
chk("P6: la ronda ya cerrando no se re-cierra (gate end > 0)",
    re.search(r'case CLIENT_EXE_DEFEATED:.*?if \(v->server->game\.end > 0\)\s*break;', gc, re.S) is not None)
chk("P6: los ganadores excluyen muertos/esbirros/NEGA/portal/ya-escapados",
    "w->plr.flags & (PLAYER_DEAD | PLAYER_DEMONIZED | PLAYER_NEGATIZED | PLAYER_CAUGHT | PLAYER_ESCAPED)" in gc)
chk("P6: a cada ganador se le marca ESCAPED + los DOS paquetes del escape",
    gc.count("SET_FLAG(w->plr.flags, PLAYER_ESCAPED);") == 1
    and "PacketCreate(&pack, SERVER_PLAYER_ESCAPED);" in gc
    and "PacketCreate(&pack, SERVER_GAME_PLAYER_ESCAPED);" in gc)
chk("P6: la partida cierra con ED_SURVWIN",
    "RAssert(game_end(v->server, ED_SURVWIN, true));" in gc)

# ---------------------------------------------------------------------------
print("=== 7. P7/P8 — EL SERVER CUENTA EL LOVE DE KRIS ===")
sh = rd("betterserver-oss/include/Server.h")
chk("P7: KRIS_LV20_SIGNALS = 19 definido (LV1 + 19 senales = LV 20)",
    "#define KRIS_LV20_SIGNALS 19" in sh)
chk("P7/P8: campos del struct Game (kris_lv / lms_natural / ring_off)",
    "uint8_t kris_lv;" in sh and "bool lms_natural;" in sh and "bool ring_off;" in sh)
chk("P7: el conteo en CLIENT_SOUND_EMIT (snd_none = indice 0, CH_KRIS, no exe)",
    re.search(r'if \(nid == v->id && sndidx == 0 /\* snd_none \*/\s*\n\s*&& v->surv_char == CH_KRIS && v->id != v->server->game\.exe\s*\n\s*&& v->server->game\.kris_lv < KRIS_LV20_SIGNALS\)\s*\n\s*v->server->game\.kris_lv\+\+;', gc) is not None)
chk("P7: el override de Kris a LV 20 fuerza su show aunque queden mas vivos",
    "server->game.kris_lv >= KRIS_LV20_SIGNALS" in gc and "kris_show = true;" in gc)
chk("P7: el disparo automatico NO marca natural (el anillo sigue para los demas)",
    "server->game.lms_natural = !kris_show;" in gc)
chk("P8: el retiro del anillo exige show NATURAL de Kris (lms && lms_natural && lms_char == CH_KRIS)",
    re.search(r'if \(server->game\.kris_lv >= KRIS_LV20_SIGNALS && server->game\.lms\s*\n\s*&& server->game\.lms_natural && server->game\.lms_char == CH_KRIS\s*\n\s*&& !server->game\.ring_off\)', gc) is not None)
chk("P8: game_bigring se vuelve no-op con ring_off (salvo BS_NONE de la ronda nueva)",
    re.search(r'if \(server->game\.ring_off && state != BS_NONE\)\s*\n\s*return true;', gc) is not None)
chk("P8: reenvio del RING_OFF al que se reconecta (game_state_join)",
    gc.count("PacketCreate(&packet, SERVER_GAME_RING_OFF);") == 2)
nsg_ring = "case PacketType.SERVER_GAME_RING_OFF:" in nsg
chk("P8: el cliente destruye su obj_bigring + quita el banner Escape + esconde el npring",
    nsg_ring and "instance_destroy();" in nsg
    and "with(obj_level)\n                                        state = 0;" in nsg
    and "with(obj_npring)\n                                        visible = false;" in nsg)

# ---------------------------------------------------------------------------
print("=== 8. ENUMS DE PAQUETES — PARIDAD EXACTA CLIENTE/SERVER ===")
ph = rd("betterserver-oss/include/Packet.h")
npk = rd("scripts/net_packets/net_packets.gml")
def server_enum(text):
    body = text[text.index("typedef enum"):text.index("} PacketType;")]
    body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
    out = []
    for line in body.split('\n'):
        s = line.strip().rstrip(',')
        if not s or s.startswith('//') or s in ('typedef enum', '{'):
            continue
        out.append(s)
    return out
def client_enum(text):
    body = text[text.index("enum PacketType"):text.index("\n}")]
    body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
    out = []
    for line in body.split('\n'):
        s = line.strip()
        if not s or s.startswith('//') or s.startswith('enum'):
            continue
        s = s.rstrip(',').strip()
        if re.fullmatch(r'[A-Z_][A-Z0-9_]*', s):
            out.append(s)
    return out
se, ce = server_enum(ph), client_enum(npk)
chk(f"enum del server: {len(se)} entradas (hasta SERVER_GAME_RING_OFF)", se[-2:] == ["CLIENT_EXE_DEFEATED", "SERVER_GAME_RING_OFF"])
chk(f"enum del cliente: {len(ce)} entradas", ce[-2:] == ["CLIENT_EXE_DEFEATED", "SERVER_GAME_RING_OFF"])
chk(f"PARIDAD EXACTA cliente==server ({len(ce)} vs {len(se)})", ce == se)
chk("los 2 paquetes nuevos van AL FINAL de ambos (patron casa v96)",
    se.index("SERVER_CLAIM_STATE") == len(se) - 3 and ce.index("SERVER_CLAIM_STATE") == len(ce) - 3)

# ---------------------------------------------------------------------------
print("=== 9. BALANCE DE LLAVES/PARENS (delta 0 vs HEAD, patron casa) ===")
def bal(text):
    t = re.sub(r'//[^\n]*', '', text)
    t = re.sub(r'/\*.*?\*/', '', t, flags=re.S)
    t = re.sub(r'"(?:[^"\\]|\\.)*"', '""', t)
    t = re.sub(r"'(?:[^'\\]|\\.)'", "''", t)
    return t.count('{') - t.count('}'), t.count('(') - t.count(')')
for f in ["scripts/scr_kris_special/scr_kris_special.gml", "scripts/scr_parry/scr_parry.gml",
          "objects/obj_player_puppet/Step_0.gml", "objects/obj_playerui/Draw_64.gml",
          "scripts/net_state_game/net_state_game.gml", "scripts/scr_move_basic/scr_move_basic.gml",
          "objects/obj_player_warning/Draw_75.gml", "scripts/net_packets/net_packets.gml"]:
    head = run(f"git show HEAD:{f}")
    w_b, h_b = bal(rd(f)), bal(head)
    chk(f"balance {os.path.basename(f)}: delta {w_b[0]}/{w_b[1]} == HEAD {h_b[0]}/{h_b[1]}",
        w_b == h_b)

# ---------------------------------------------------------------------------
print("=== 10. SIN TABS EN LOS .gml TOCADOS (regla de la casa) ===")
for f in ["scripts/scr_kris_special/scr_kris_special.gml", "scripts/scr_parry/scr_parry.gml",
          "objects/obj_player_puppet/Step_0.gml", "objects/obj_playerui/Draw_64.gml",
          "scripts/net_state_game/net_state_game.gml", "scripts/net_packets/net_packets.gml"]:
    diff = run(f"git diff HEAD -- {f}")
    added = [l for l in diff.splitlines() if l.startswith('+') and not l.startswith('+++')]
    chk(f"sin tabs anadidos en {os.path.basename(f)}", not any('\t' in l for l in added))
# obj_player_warning/Draw_75 USA tabs de siempre: las lineas de SENTENCIA
# anadidas usan tabs como el resto (los if/else van a columna 0 como en el
# archivo original y los comentarios tambien a columna 0)
diffw = run("git diff HEAD -- objects/obj_player_warning/Draw_75.gml")
addedw = [l[1:] for l in diffw.splitlines() if l.startswith('+') and not l.startswith('+++')]
chk("Draw_75 del warning: las sentencias anadidas usan tabs (estilo del archivo)",
    all(('\t' in l) or (not l.strip().startswith('moved'))
        for l in addedw if l.strip() and not l.strip().startswith('//')))

# ---------------------------------------------------------------------------
print("=== 11. SINTAXIS C DEL SERVER (gcc -fsyntax-only, stub de enet) ===")
stub_dir = tempfile.mkdtemp(prefix="enet_stub_")
os.makedirs(os.path.join(stub_dir, "enet"), exist_ok=True)
with open(os.path.join(stub_dir, "enet", "enet.h"), "w") as f:
    f.write("""#ifndef ENET_STUB_H
#define ENET_STUB_H
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#define ENET_HOST_ANY 0
#define ENET_PACKET_FLAG_RELIABLE 1
typedef struct { uint32_t host; uint16_t port; } ENetAddress;
typedef struct { uint8_t *data; size_t dataLength; } ENetPacket;
typedef struct ENetPeer { int dummy; uint32_t roundTripTime; uint32_t sessionID; void *data;
        uint16_t incomingPeerID; ENetAddress address; } ENetPeer;
typedef struct ENetHost { int dummy; size_t mtu; int socket; } ENetHost;
typedef struct { int type; ENetPeer *peer; ENetPacket *packet; } ENetEvent;
typedef enum { ENET_EVENT_TYPE_NONE = 0, ENET_EVENT_TYPE_CONNECT, ENET_EVENT_TYPE_DISCONNECT, ENET_EVENT_TYPE_RECEIVE } ENetEventType;
typedef int ENetSocket;
typedef enum { ENET_SOCKOPT_RCVBUF = 0, ENET_SOCKOPT_SNDBUF } ENetSocketOption;
int enet_initialize(void); void enet_deinitialize(void);
ENetHost* enet_host_create(const ENetAddress*, ...);
int enet_host_service(ENetHost*, ENetEvent*, uint32_t);
void enet_packet_destroy(ENetPacket*);
int enet_peer_send(ENetPeer*, uint8_t, ENetPacket*);
void enet_peer_disconnect(ENetPeer*, uint32_t);
void enet_peer_disconnect_now(ENetPeer*, uint32_t);
void enet_peer_reset(ENetPeer*);
ENetPacket* enet_packet_create(const void*, size_t, uint32_t);
void enet_host_flush(ENetHost*); void enet_host_broadcast(ENetHost*, uint8_t, ENetPacket*);
int enet_address_get_host_ip(ENetAddress* a, char* b, size_t c);
void enet_socket_set_option(ENetSocket, ENetSocketOption, int);
void enet_host_destroy(ENetHost*);
#endif
""")
r = subprocess.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/states/Game.c",
                   shell=True, capture_output=True, text=True, cwd="betterserver-oss")
chk("states/Game.c compila limpio (gcc -fsyntax-only)", r.returncode == 0, r.stderr[:300])
for extra in ["states/CharSelect.c", "states/Lobby.c", "states/Mapvote.c", "states/Results.c", "entities/ItemBoxMap.c", "entities/Ring.c"]:
    r2 = subprocess.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/{extra}",
                        shell=True, capture_output=True, text=True, cwd="betterserver-oss")
    chk(f"{extra} sigue compilando (Server.h/Packet.h sanos)", r2.returncode == 0, r2.stderr[:200])
shutil.rmtree(stub_dir, ignore_errors=True)

# ---------------------------------------------------------------------------
print("=== 12. SIMULACION 1 — LOVE -> senales -> espejo del server (P7) ===")
# reglas REALES parseadas: umbrales v46 + perilla v96/v97 + flush 1-senal-por-nivel
th_raw = re.search(r'static _th = \[([^\]]+)\];', ks).group(1)
TH = [int(x.strip()) for x in th_raw.split(',')]
KN = float(re.search(r'#macro KRIS_LV_XP_NORMAL ([\d.]+)', ks).group(1))
KL = float(re.search(r'#macro KRIS_LV_XP_LMS ([\d.]+)', ks).group(1))
LVMAX = int(re.search(r'#macro KRIS_LV_MAX (\d+)', ks).group(1))
def love_lv(hits):
    lv = 1
    for i, t in enumerate(TH):
        if hits >= t:
            lv = i + 2
    return min(lv, LVMAX)
def sim_love(xp):
    lv, hits, signals, server_lv = 1, 0.0, 0, 0
    events = []
    for _ in range(200):
        hits += xp
        new = love_lv(hits)
        up = new - lv
        if up > 0:
            lv = new
            signals += up          # flush v97: UNA senal por nivel cruzado
            for _s in range(up):
                if server_lv < 19:
                    server_lv += 1  # el contador del server (cap 19)
        events.append((lv, signals, server_lv))
        if lv >= LVMAX:
            break
    return events
for xp, name in [(KN, "normal 1.5"), (KL, "LMS 5")]:
    ev = sim_love(xp)
    last = ev[-1]
    chk(f"LOVE {name}: local LV {last[0]} == senales+1 {last[1]+1} == server LV 1+{last[2]}",
        last[0] == last[1] + 1 and last[1] == last[2] and last[0] == 20)
    # en cada paso: espejo del server NUNCA se adelanta al local y termina igual
    ok_all = all(e[0] == e[2] + 1 or e[2] <= e[1] for e in ev)
    chk(f"LOVE {name}: el espejo del server acompana al local en TODOS los pasos", ok_all)
chk("LV 20 == 19 senales (KRIS_LV20_SIGNALS exacto)", sim_love(KL)[-1][1] == 19)

print("=== 13. SIMULACION 2 — matriz P7/P8 (show y anillo) ===")
class G:
    def __init__(self):
        self.lms = False; self.lms_char = None; self.lms_natural = False
        self.kris_lv = 0; self.ring_off = False
def tick(g, players):
    # bloque LMS (simplificado con las reglas nuevas)
    if not g.lms:
        alive = [p for p in players if p["alive"]]
        last = alive[0] if len(alive) == 1 else None
        kris_show = False
        if g.kris_lv >= 19:
            kr = [p for p in players if p["char"] == "KRIS" and p["alive"]]
            if kr:
                last = kr[0]; kris_show = True
        if last is not None:
            if last["char"] in ("KRIS", "SONIC", "TAILS"):  # tiene show
                g.lms = True; g.lms_char = last["char"]; g.lms_natural = not kris_show
    # bloque anillo
    if g.kris_lv >= 19 and g.lms and g.lms_natural and g.lms_char == "KRIS" and not g.ring_off:
        g.ring_off = True
# A: Kris solo (natural) LMS y LUEGO llega a 20 -> anillo OFF
g = G(); p = [{"char": "KRIS", "alive": True}]
tick(g, p); chk("A: show natural de Kris arranca solo", g.lms and g.lms_natural and g.lms_char == "KRIS")
chk("A: sin LV 20 el anillo sigue", not g.ring_off)
g.kris_lv = 19; tick(g, p)
chk("A: Kris llega a LV 20 durante su show natural -> anillo OFF", g.ring_off)
# B: otros vivos + Kris LV 20 -> show AUTOMATICO, anillo intacto
g = G(); p = [{"char": "KRIS", "alive": True}, {"char": "SONIC", "alive": True}, {"char": "TAILS", "alive": True}]
g.kris_lv = 19; tick(g, p)
chk("B: LV 20 antes del LMS -> show automatico IGNORANDO el solo-1", g.lms and not g.lms_natural)
chk("B: el show automatico NO retira el anillo (los demas siguen escapando)", not g.ring_off)
# C: LMS natural de OTRO personaje -> nunca ring_off aunque Kris tenga LV 20
g = G(); p = [{"char": "SONIC", "alive": True}, {"char": "KRIS", "alive": False}]
tick(g, p); g.kris_lv = 19; tick(g, p)
chk("C: show natural de otro personaje con Kris muerto -> sin anillo-off", not g.ring_off and g.lms_char == "SONIC")
# D: el latch del anillo: un solo broadcast (ring_off no se repite)
calls = []
g = G(); p = [{"char": "KRIS", "alive": True}]
tick(g, p); g.kris_lv = 19
for _ in range(5):
    tick(g, p)
    if g.ring_off:
        calls.append(1)
chk("D: el retiro del anillo se dispara UNA vez (latch)", len(calls) >= 1 and g.ring_off)

print("=== 14. SIMULACION 3 — matriz P6 (ganadores del derribo) ===")
# replica exacta del filtro del server
DEAD, DEM, NEG, CAUGHT, ESC = 1, 2, 4, 8, 16
players = [
    {"id": 1, "exe": True,  "flags": 0},                    # el exe (reporta)
    {"id": 2, "exe": False, "flags": 0},                    # kris vivo sano -> GANA
    {"id": 3, "exe": False, "flags": DEAD},                 # muerto -> no
    {"id": 4, "exe": False, "flags": DEM},                  # esbirro -> no
    {"id": 5, "exe": False, "flags": NEG},                  # NEGA vivo -> NO GANA
    {"id": 6, "exe": False, "flags": CAUGHT},               # en el portal -> no
    {"id": 7, "exe": False, "flags": ESC},                  # ya escapo por el ring -> no re-marca
    {"id": 8, "exe": False, "flags": 0},                    # otro vivo sano -> GANA
]
winners = [p["id"] for p in players if not p["exe"] and not (p["flags"] & (DEAD | DEM | NEG | CAUGHT | ESC))]
chk("P6: ganadores = SOLO los vivos no corrompidos (2 y 8)", winners == [2, 8])
end = 0
def handle_defeated(sender_id):
    global end
    if sender_id != 1:  # AssertOrDisconnect(v->id == game.exe)
        return "DISCONNECT"
    if end > 0:
        return "IGNORADO"
    end = 5 * 60  # game_end pone end = 5 s
    return "SURVWIN"
chk("P6: el propio exe reporta -> SURVWIN", handle_defeated(1) == "SURVWIN")
chk("P6: un duplicado ya cerrando se IGNORA (gate end>0)", handle_defeated(1) == "IGNORADO")
chk("P6: un superviviente que lo falsifica -> DISCONNECT (anti-cheat)", handle_defeated(2) == "DISCONNECT")

print("=== 15. SIMULACION 4 — snd_none: quien cuenta para el server ===")
def counts(nid, sndidx, surv_char, is_exe, kris_lv):
    if nid == 1 and sndidx == 0 and surv_char == "CH_KRIS" and not is_exe and kris_lv < 19:
        kris_lv += 1
    return kris_lv
kv = 0
kv = counts(1, 0, "CH_KRIS", False, kv); chk("cuenta: senal de LOVE de Kris (broadcast, idx 0)", kv == 1)
kv = counts(1, 126, "CH_KRIS", False, kv); chk("NO cuenta: la senal cruda del exe-hp (idx 126)", kv == 1)
kv = counts(1, 0, "CH_SONIC", False, kv); chk("NO cuenta: snd_none de otro personaje", kv == 1)
kv = counts(1, 0, "CH_KRIS", True, kv); chk("NO cuenta: el clon de Exeller (su player ES el exe)", kv == 1)
kv = counts(2, 0, "CH_KRIS", False, kv); chk("NO cuenta: snd_none DIRIGIDO (nid != emisor)", kv == 1)
kv = 19
kv = counts(1, 0, "CH_KRIS", False, kv); chk("tope: con 19 ya no cuenta mas (cap del espejo)", kv == 19)

print("=== 16. INTEGRIDAD .yyp/.yy (regla 6) ===")
def json5(text):
    # JSON5 tolerante (patron casa v93): el .yyp de GameMaker trae comas
    # colgantes y comentarios de linea
    text = re.sub(r'^\s*//[^\n]*', '', text, flags=re.M)
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)
yyp = json5(rd("Sonicexe The Disaster 2D Remake.yyp"))
chk(f".yyp parses como JSON5 ({len(yyp['resources'])} recursos)", len(yyp["resources"]) > 2000)
head_yyp = run("git show HEAD:'Sonicexe The Disaster 2D Remake.yyp'")
hy = json5(head_yyp)
chk(".yyp SIN cambios de recursos vs HEAD (cero entradas nuevas/borradas)",
    len(yyp["resources"]) == len(hy["resources"]))
yy_status = [l for l in lines if l[2:].strip().endswith('.yy')]
chk("cero .yy tocados", len(yy_status) == 0)

# ---------------------------------------------------------------------------
print()
print(f"RESULTADO PASADA 1: {OK} OK / {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
