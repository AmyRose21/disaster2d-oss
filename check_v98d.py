#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v98d.py — v98d (STUN AL CAUSANTE + CAJAS QUE COBRAN AL DUENO DEL
#  LASER). Dos pedidos de la duena:
#   D1  ZAP EXACTO: "buscar al que causo el ataque y aplicarle el stun
#       tambien" — cuando al escudo electrico lo rompe un PROYECTIL, el
#       stun va al DUENO del laser (nid EXACTO: viaja en el paquete de
#       spawn desde siempre; net_state_game solo lo usaba para isOwner y
#       lo tiraba). Antes el zap solo contaba un puppet "atacando" cerca
#       del portador: un tirador caminando a 2000 px era invisible y el
#       escudo "no stuneaba a nadie". La deteccion por contacto/
#       cercania queda de FALLBACK (melee, hazards: attackerNid = -1).
#   D2  CREDITO DE CAJA: "si un proyectil lo destruye no cuenta para el
#       que lo destruyo... no se lo da a nadie" — CLIENT_BOX_ACTIVATE
#       gana un tercer campo (owner u16: nid del dueno del laser; 0 en
#       melee) y el server le COBRA el reward al DUENO. EXCEPCIONES
#       (regla de la duena): BOTAS = NADIE ("tener la speed activa sin
#       querer seria una pendejada" — solo la cobra quien la rompe a
#       proposito) y los monitores Kaf QUEDAN IGUAL (KindAndFair.c y el
#       Step_2 del kaf_speedboobster INTOCADOS, sin campo owner).
#  + gcc -fsyntax-only de los .c tocados (stub de enet), llaves
#    balanceadas de los GML tocados, v98b/v98c siguen intactos.
# ============================================================================
import subprocess, sys, os, re, tempfile, shutil

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
print("=== 1. ARCHIVOS TOCADOS (v98d: 12 propios + los 5 del v98c pendiente) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
untracked = sorted([l[2:].strip() for l in lines if l[:2] == "??"])
V98D_MOD = sorted([
    # 11 del v98d (check_v98c.py NO: es untracked, nunca commiteado upstream)
    "betterserver-oss/disasterserver/entities/ItemBox.c",
    "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/entities/ItemBox.h",
    "objects/obj_itembox/Step_2.gml",
    "objects/obj_tails_projectile/Create_0.gml",
    "objects/obj_tails_projectile/Step_0.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_collision_objects/scr_collision_objects.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    # los 5 del v98c (aun sin commitear upstream cuando se empezo v98d)
    "objects/obj_player_puppet/Create_0.gml",
    "check_v98b.py",
    "worklog.md",
    "CACHE.md",
    "LEARNING.md",
])
V98D_UNTRACKED = sorted([
    "check_v98c.py", "LEEME_V98C_FIX_ESCUDO_ELECTRICO.txt",
    "check_v98d.py", "LEEME_V98D_ATRIBUCION_DEL_LASER.txt",
])
chk("modificados = 11 del v98d + 5 del v98c (16), ni uno mas",
    mod_files == V98D_MOD, f"real: {mod_files}")
chk("nuevos sin trackear: checks + LEEMEs de v98c y v98d (4)",
    untracked == V98D_UNTRACKED, f"real: {untracked}")
chk("cero .yy/.yyp tocados", not any(f.endswith((".yy", ".yyp")) for f in mod_files))
chk("KAF INTACTO (regla de la duena): ni el monitor ni KindAndFair.c en la lista",
    "kaf" not in st.lower() and "KindAndFair" not in st)

lcr = rd("objects/obj_tails_projectile/Create_0.gml")
lstep = rd("objects/obj_tails_projectile/Step_0.gml")
nsg = rd("scripts/net_state_game/net_state_game.gml")
hurt = rd("scripts/scr_player_hurt/scr_player_hurt.gml")
box2 = rd("objects/obj_itembox/Step_2.gml")
coll = rd("scripts/scr_collision_objects/scr_collision_objects.gml")
nps = rd("scripts/net_packets/net_packets.gml")
pupcr = rd("objects/obj_player_puppet/Create_0.gml")
draw64 = rd("objects/obj_level/Draw_64.gml")
pkt_h = rd("betterserver-oss/include/Packet.h")
ibx_h = rd("betterserver-oss/include/entities/ItemBox.h")
ibx_c = rd("betterserver-oss/disasterserver/entities/ItemBox.c")
ibm_c = rd("betterserver-oss/disasterserver/entities/ItemBoxMap.c")
kaf_s2 = rd("objects/obj_kaf_speedboobster/Step_2.gml")
kaf_c = rd("betterserver-oss/disasterserver/maps/KindAndFair.c")

# ---------------------------------------------------------------------------
print("=== 2. EL LASER CONOCE A SU DUENO ===")
chk("Create del laser: ownerNid = -1 con su comentario v98d",
    re.search(r"^ownerNid = -1;$", lcr, re.M) is not None and "v98d" in lcr)
chk("spawn (net_state_game): inst.ownerNid = _owner — el nid que YA viajaba",
    "inst.ownerNid = _owner;" in nsg)
chk("isOwner se sigue calculando igual (no se rompio el spawn)",
    "inst.isOwner = _owner == obj_netclient.nid;" in nsg)

# ---------------------------------------------------------------------------
print("=== 3. D1 — EL ZAP STUNEA AL CAUSANTE EXACTO ===")
chk("firma: scr_player_hurt gana el 8.o param attackerNid=-1",
    "exeSource=false, attackerNid=-1)" in hurt)
chk("el comentario del param documenta para que sirve",
    "attackerNid — nid del CAUSANTE exacto" in hurt)
chk("el zap: rama de atribucion exacta ANTES de la heuristica",
    re.search(r"if\(attackerNid >= 0\)\s*\n\s*_zapNid = attackerNid;\s*\n\s*else if\(instance_exists\(obj_player_puppet\)\)", hurt) is not None)
chk("el laser pasa su ownerNid en la llamada (attackerNid)",
    re.search(r"scr_player_hurt\(dmg, -sign\(x - global\.player\.x\) \* 4, 2, snd_hurt, spr_blood1, false, true, ownerNid\);", lstep) is not None)
chk("la heuristica v92 queda INTACTA como fallback (loop de puppets)",
    "_pp.isAttacking || _pp.isJumping || _pp.isSpinning" in hurt
    and "instance_find(obj_player_puppet, _pi)" in hurt)
chk("y sigue leyendo solo vars con default (v98c): _pp.isJumping existe en el Create del puppet",
    re.search(r"^isJumping = false;$", pupcr, re.M) is not None
    and re.search(r"^isSpinning = false;$", pupcr, re.M) is not None)
chk("la senal del stun sigue igual (net_sound_emit_at al nid del zapper)",
    re.search(r"net_sound_emit_at\(snd_metal_stun, _zapNid\)", hurt) is not None)

# ---------------------------------------------------------------------------
print("=== 4. D2 — LA CAJA COBRA AL DUENO DEL PROYECTIL ===")
chk("box Step_2: instance_place para el laser EXACTO (2+ Tails = 3 lasers vivos)",
    "var _plaser = instance_place(x, y, obj_tails_projectile);" in box2)
chk("box Step_2: envia el nid del dueno (u16, tercero)",
    "buffer_write(pack, buffer_u16, _plaser == noone ? 0 : _plaser.ownerNid);" in box2)
chk("melee (scr_collision_objects): escribe el campo u16 en 0",
    re.search(r"buffer_write\(pack, buffer_u16, 0\); // v98d: campo dueno", coll) is not None)
chk("los DOS senders usan el MISMO formato de 3 campos (nid u8, proj bool, owner u16)",
    box2.count("buffer_write(pack, buffer_u8, nid);") == 1
    and kaf_s2.count("buffer_write(pack, buffer_u16") == 0)
chk("net_packets.gml documenta el campo owner",
    "CLIENT_BOX_ACTIVATE (nid," in nps and "owner u16" in nps)
chk("Packet.h documenta el campo owner (paridad de la casa)",
    "(nid, proj, owner u16)" in pkt_h)
chk("Packet.h y net_packets.gml siguen en paridad (BOX_ACTIVATE -> BOX_STATE)",
    pkt_h.index("CLIENT_BOX_ACTIVATE,") < pkt_h.index("SERVER_BOX_STATE,")
    and nps.index("CLIENT_BOX_ACTIVATE,") < nps.index("SERVER_BOX_STATE,"))
chk("server: lee el campo (PacketRead powner u16)",
    "PacketRead(powner, packet, packet_read16, uint16_t);" in ibm_c)
chk("server: itembox_activate firma sin is_proj (pid ya resuelto)",
    "bool itembox_activate(Server* server, ItemBox* box, uint16_t pid);" in ibx_h
    and "bool itembox_activate(Server* server, ItemBox* box, uint16_t pid)\n{" in ibx_c)
chk("server: difunde el pid resuelto (ya NO is_proj ? 0 : pid)",
    "itembox_broadcast(server, 2, box, pid);" in ibx_c)

# ---------------------------------------------------------------------------
print("=== 5. LAS EXCEPCIONES DE LA DUENA ===")
chk("BOTAS por proyectil NO cobran: type != ITEMTYPE_BOOTS en la regla",
    re.search(r"proj\)\s*\n\s*\{\s*\n\s*reward = 0;\s*\n\s*if \(powner != 0\s*\n\s*&& powner != v->server->game\.exe\s*\n\s*&& target->type != ITEMTYPE_BOOTS\)", ibm_c) is not None)
chk("el veto v74 sigue: el Exe jamas cobra (reward exe = 0 en melee)",
    "(v->server->game.exe == v->id) ? 0 : v->id" in ibm_c)
chk("Kaf monitor INTACTO: CLIENT_KAFMONITOR_ACTIVATE sin campo owner",
    kaf_s2.count("buffer_write") == 2
    and "CLIENT_KAFMONITOR_ACTIVATE" in kaf_s2)
chk("KindAndFair.c INTACTO: kafbox_activate(v->id, proj) igual que siempre",
    "kafbox_activate(v->server, box[nid], v->id, proj)" in kaf_c)
chk("cliente v75 sigue: el Exe no cobra aunque el server mande su pid",
    "if(global.character == CHARACTER_EXE)" in nsg)

# ---------------------------------------------------------------------------
print("=== 6. SINTAXIS C DEL SERVER (gcc -fsyntax-only, stub de enet) ===")
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
import subprocess as sp
for f in ["entities/ItemBoxMap.c", "entities/ItemBox.c", "states/Game.c", "maps/KindAndFair.c"]:
    r = sp.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/{f}",
               shell=True, capture_output=True, text=True, cwd="betterserver-oss")
    chk(f"{f} compila limpio (gcc -fsyntax-only)", r.returncode == 0, r.stderr[:300])
shutil.rmtree(stub_dir, ignore_errors=True)

# ---------------------------------------------------------------------------
print("=== 7. LLAVES BALANCEADAS (archivos GML tocados) ===")
for f in ["scripts/net_state_game/net_state_game.gml", "scripts/net_packets/net_packets.gml",
          "objects/obj_itembox/Step_2.gml", "objects/obj_tails_projectile/Create_0.gml",
          "objects/obj_tails_projectile/Step_0.gml",
          "scripts/scr_collision_objects/scr_collision_objects.gml",
          "scripts/scr_player_hurt/scr_player_hurt.gml"]:
    txt = rd(f)
    txt2 = re.sub(r'"(?:[^"\\]|\\.)*"', '""', txt)
    txt2 = re.sub(r"//[^\n]*", "", txt2)
    txt2 = re.sub(r"/\*.*?\*/", "", txt2, flags=re.S)
    chk(f"{f}: llaves y parens balanceadas",
        txt2.count("{") == txt2.count("}") and txt2.count("(") == txt2.count(")"))

# ---------------------------------------------------------------------------
print("=== 8. v98b + v98c SIGUEN INTACTOS ===")
chk("v98b: el infinito sigue en (238, 15) rotado 90",
    "draw_sprite_ext(spr_counter, 8, 238, 15, 1, 1, 90, c_white, 1);" in draw64)
chk("v98b: RING_OFF sigue marcando global.ringOff = true",
    "SERVER_GAME_RING_OFF" in nsg and "global.ringOff = true;" in nsg)
chk("v98c: defaults defensivos del puppet intactos",
    re.search(r"^isJumping = false;$", pupcr, re.M) is not None
    and re.search(r"^isSpinning = false;$", pupcr, re.M) is not None)
chk("check_v98b y check_v98c parcheados: reconocen el vuelo del v98d",
    "V98D_MOD" in rd("check_v98b.py") and "V98D_MOD" in rd("check_v98c.py"))

print()
print(f"RESULTADO: {OK} OK, {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
