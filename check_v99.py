#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v99.py — v99 (PARITY Y BALANCE). Seis pedidos de la duena:
#   D1  ATRIBUCION PARA TODOS LOS PROYECTILES: el patron v98d del laser
#       (ownerNid + scr_player_hurt con attackerNid) ahora tambien en la
#       BALA DE METAL AMY (su dueno es EL EXE: si rompe un escudo
#       electrico, el zap cae sobre el asesino — «excepto si son exes
#       esos son ejecutados»), la FLECHA de Amy Fleetway DEMONIZADA y la
#       BOLA DE FUEGO de Blaze DEMONIZADA.
#   D2  PARRY QUE DEVUELVE TODOS LOS PROYECTILES: «si devuelve el tails
#       pero no con amy fleet ni con los misiles de metal amy etc» —
#       mismos deflects del laser para la bala, la flecha demonizada y
#       la bola demonizada (el escudo de Kris BLOQUEA los tres, como
#       hace con el laser: bloquea, no devuelve).
#   D3  NERF PASIVA CD: «ya no podran usar su pasiva de añadirse cd a
#       sus habilidades a KRIS bajo ningun prospecto» — guard CHARACTER_
#       KRIS en scr_weak_mark_hit (inmune a la marca de Metal Amy y a la
#       mejorada de Jinna, patron del Sonic-LMS v5.0).
#   D4  BARRA LV 20: el icono del exe DEL LOBBY (spr_lobby_exeicon*, uno
#       por asesino) a la IZQUIERDA de la barra de vida del asesino.
#   D5  COMPILAR_SERVER.BAT: si detecta el exe abierto lo CIERRA SOLO
#       (ya no pregunta S/N).
#   D6  DAÑOS POR ASESINO: Exetior 50 / exe normal 45 / Exeller 40 /
#       Chaos 35 / Metal Amy 30 (la mas agil) / Jinna 45 (plano: el bono
#       de las atrapadas ya NO engorda el golpe basico).
#  + gcc -fsyntax-only (stub enet), llaves balanceadas, v98b/c/d intactos.
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
print("=== 1. ARCHIVOS TOCADOS (v99: 17 propios + v98d 11 + v98c 5 = 29 + 6 nuevos) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
untracked = sorted([l[2:].strip() for l in lines if l[:2] == "??"])
V99_MOD = sorted([
    # 17 del v99
    "betterserver-oss/compilar_server.bat",
    "betterserver-oss/disasterserver/entities/BlazeFireball.c",
    "betterserver-oss/disasterserver/entities/MetalAmyBullet.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "objects/obj_blaze_fireball/Create_0.gml",
    "objects/obj_blaze_fireball/Step_0.gml",
    "objects/obj_fw_bolt/Create_0.gml",
    "objects/obj_fw_bolt/Step_0.gml",
    "objects/obj_metal_amy_bullet/Create_0.gml",
    "objects/obj_metal_amy_bullet/Step_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_parry/scr_parry.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    # los 12 del v98d (aun sin commitear upstream)
    "betterserver-oss/disasterserver/entities/ItemBox.c",
    "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
    "betterserver-oss/include/entities/ItemBox.h",
    "objects/obj_itembox/Step_2.gml",
    "objects/obj_tails_projectile/Create_0.gml",
    "objects/obj_tails_projectile/Step_0.gml",
    "scripts/scr_collision_objects/scr_collision_objects.gml",
    # los 5 del v98c (aun sin commitear upstream)
    "objects/obj_player_puppet/Create_0.gml",
    "check_v98b.py",
    "worklog.md",
    "CACHE.md",
    "LEARNING.md",
])
V99_UNTRACKED = sorted([
    "LEEME_V98C_FIX_ESCUDO_ELECTRICO.txt", "LEEME_V98D_ATRIBUCION_DEL_LASER.txt",
    "check_v98c.py", "check_v98d.py",
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
])
# v100 (upstream commiteo v98c+v98d: "asuewe"/"ewe"): el vuelo cambia de
# forma — solo quedan los archivos del v99 que DIFIEREN del HEAD nuevo.
V100_MOD = sorted([
    "betterserver-oss/compilar_server.bat",
    "betterserver-oss/disasterserver/entities/BlazeFireball.c",
    "betterserver-oss/disasterserver/entities/MetalAmyBullet.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "check_v98b.py", "check_v98c.py", "check_v98d.py",
    "objects/obj_blaze_fireball/Create_0.gml",
    "objects/obj_blaze_fireball/Step_0.gml",
    "objects/obj_fw_bolt/Create_0.gml",
    "objects/obj_fw_bolt/Step_0.gml",
    "objects/obj_metal_amy_bullet/Create_0.gml",
    "objects/obj_metal_amy_bullet/Step_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_parry/scr_parry.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    "worklog.md", "CACHE.md", "LEARNING.md",
])
V100_UNTRACKED = sorted([
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
])
if mod_files == []:
    _mods_ok = untracked == []
    _estado = "arbol limpio: v99 ya commiteado upstream"
elif mod_files == V99_MOD:
    _mods_ok = untracked == V99_UNTRACKED
    _estado = "vuelo del v99 sobre el HEAD viejo (pre-asuewe)"
elif mod_files == V100_MOD or mod_files == sorted(V100_MOD + ["scripts/scr_kris_special/scr_kris_special.gml"]):
    _mods_ok = untracked in (
        V100_UNTRACKED,
        sorted(V100_UNTRACKED + ["check_v100.py", "LEEME_V100_EL_BLOQUEO_CUENTA.txt"]),
        # v101: mismos mods + los 2 del v101 (el gate v3.0 retirado)
        sorted(V100_UNTRACKED + ["check_v100.py", "LEEME_V100_EL_BLOQUEO_CUENTA.txt",
                                 "check_v101.py", "LEEME_V101_CASTIGO_AUN_CON_LAG.txt"]),
    )
    _estado = "vuelo del v100 (el bloqueo siempre cuenta)"
else:
    _mods_ok = False
    _estado = "NO RECONOCIDO"
chk(f"estado del arbol: {_estado} — ni un archivo de mas, cero .yy/.yyp",
    _mods_ok and not any(f.endswith((".yy", ".yyp")) for f in mod_files),
    f"real mods: {mod_files} untracked: {untracked}")
chk("nuevos sin trackear: los del v99 o los del v100",
    untracked == V99_UNTRACKED or "check_v99.py" in untracked,
    f"real: {untracked}")
chk("cero .yy/.yyp tocados", not any(f.endswith((".yy", ".yyp")) for f in mod_files))
chk("KAF MONITOR INTACTO (como en v98d): ni KindAndFair.c ni el Step_2 del kaf en la lista",
    "kaf" not in st.lower() and "KindAndFair" not in st)

pupst = rd("objects/obj_player_puppet/Step_0.gml")
hurt = rd("scripts/scr_player_hurt/scr_player_hurt.gml")
parry = rd("scripts/scr_parry/scr_parry.gml")
nsg = rd("scripts/net_state_game/net_state_game.gml")
nps = rd("scripts/net_packets/net_packets.gml")
pkt_h = rd("betterserver-oss/include/Packet.h")
game_c = rd("betterserver-oss/disasterserver/states/Game.c")
mab_c = rd("betterserver-oss/disasterserver/entities/MetalAmyBullet.c")
bfi_c = rd("betterserver-oss/disasterserver/entities/BlazeFireball.c")
bat = rd("betterserver-oss/compilar_server.bat")
ui64 = rd("objects/obj_playerui/Draw_64.gml")
bcr = rd("objects/obj_metal_amy_bullet/Create_0.gml")
bst = rd("objects/obj_metal_amy_bullet/Step_0.gml")
fcr = rd("objects/obj_fw_bolt/Create_0.gml")
fst = rd("objects/obj_fw_bolt/Step_0.gml")
hcr = rd("objects/obj_blaze_fireball/Create_0.gml")
hst = rd("objects/obj_blaze_fireball/Step_0.gml")

# ---------------------------------------------------------------------------
print("=== 2. D6 — DAÑOS POR ASESINO (50/45/40/35/30/45) ===")
chk("switch por exeCharacter: EXETIOR 50 / ORIGINAL 45 / EXELLER 40 / CHAOS 35 / METALAMY 30 / JINNA 45",
    all(re.search(r"case " + m + r":\s*\n\s*damage = " + v + ";", pupst) for m, v in
        [("EXE_EXETIOR", "50"), ("EXE_ORIGINAL", "45"), ("EXE_EXELLER", "40"),
         ("EXE_CHAOS", "35"), ("EXE_METALAMY", "30"), ("EXE_JINNA", "45")]))
chk("el bono de las atrapadas YA NO engorda el golpe basico de Jinna",
    "damage += scr_jinna_power()" not in pupst)
chk("...pero SIGUE sumando en el agarre y la trampa (JINNA_BONUS_GRAB/TRAP intactos)",
    "scr_jinna_power() * JINNA_BONUS_GRAB" in nsg
    and re.search(r"JINNA_BONUS_GRAB\s+5", rd("scripts/scr_jinna_special/scr_jinna_special.gml")) is not None)
chk("el esbirro comun sigue a 20 (base) y el negativo a 15",
    "var damage = 20;" in pupst and "damage = JINNA_NEGA_DAMAGE;" in pupst)

# ---------------------------------------------------------------------------
print("=== 3. D3 — KRIS INMUNE A LA MARCA DE DEBILIDAD (nerf Metal Amy + Jinna) ===")
m = re.search(r"function scr_weak_mark_hit[\s\S]*?\n\}", hurt)
chk("guard CHARACTER_KRIS dentro de scr_weak_mark_hit",
    m is not None and "if(global.character == CHARACTER_KRIS)\n                return;" in m.group(0))
chk("el guard esta ANTES de aplicar el CD (despues del de Sonic-LMS, antes del weakMarkCd)",
    m is not None and m.group(0).find("CHARACTER_KRIS") < m.group(0).find("global.player.weakMarkCd = _cd;"))
chk("la marca sigue aplicando al resto (el switch de personajes queda intacto)",
    "case CHARACTER_TAILS:" in hurt and "METALAMY_WEAKMARK_TIME" in hurt)

# ---------------------------------------------------------------------------
print("=== 4. D5 — EL .BAT CIERRA EL EXE SOLO ===")
chk("ya NO pregunta S/N (adios al set /p OP2)",
    "set /p OP2" not in bat)
chk("el taskkill automatico sigue ahi",
    'taskkill /im "DisasterServer.exe" /f >nul 2>&1' in bat)
chk("avisa que cierra solo (v99)",
    "cerrandolo automaticamente (v99)" in bat)
chk("si el taskkill FALLA sigue cancelando (no compila contra un exe abierto)",
    'set "EXE_BUSY=1"' in bat)

# ---------------------------------------------------------------------------
print("=== 5. D4 — EL ICONO DEL EXE DEL LOBBY EN LA BARRA DEL LV 20 ===")
chk("el switch de iconos (los mismos sprites del lobby: uno por asesino)",
    all(s in ui64 for s in ["spr_lobby_exeicon2", "spr_lobby_exeicon3", "spr_lobby_exeicon4",
                            "spr_lobby_exeicon6", "spr_lobby_exeicon7"]))
chk("a la IZQUIERDA de la barra (pegado al borde izquierdo, centrado en vertical)",
    "draw_sprite_ext(_exeIconSpr, 0, _kbX - _exeIw - 3, _kbY + 4 - _exeIh / 2" in ui64)
chk("el icono se resuelve como el nombre: global.exeCharacter en la pantalla del exe, el puppet del exe en las demas",
    "_exeChar = global.exeCharacter;" in ui64 and "_exeChar = exeCharacter;" in ui64)
chk("el icono vive DENTRO del gate _kris20 (solo en el duelo, como la barra)",
    re.search(r"if\(_kris20\)[\s\S]*draw_sprite_ext\(_exeIconSpr", ui64) is not None)

# ---------------------------------------------------------------------------
print("=== 6. D1 — OWNERNID EN TODOS LOS PROYECTILES (bala / flecha / bola) ===")
chk("bala de Metal Amy: ownerNid + deflected en el Create",
    "ownerNid = -1;" in bcr and "deflected = false;" in bcr)
chk("flecha de Fleetway: ownerNid en el Create",
    "ownerNid = -1;" in fcr)
chk("bola de Blaze: ownerNid + deflected + exeFire en el Create",
    "ownerNid = -1;" in hcr and "deflected = false;" in hcr and "exeFire = false;" in hcr)
chk("los 3 spawns del cliente guardan el dueno (patron laser de Tails)",
    "inst.ownerNid = _mowner;" in nsg and "inst.ownerNid = _fowner;" in nsg and "inst.ownerNid = _owner; // v99" in nsg)
chk("el server difunde el dueno en los spawns de bala y bola (al final del paquete)",
    "PacketWrite(&pack, packet_write16, mb->owner);" in mab_c
    and "PacketWrite(&pack, packet_write16, fb->owner);" in bfi_c)
chk("los 3 scr_player_hurt llevan attackerNid=ownerNid (8.o param del zap)",
    "spr_blood1, false, true, ownerNid);" in bst
    and "spr_blood2, false, true, ownerNid);" in fst
    and "spr_blood2, false, true, ownerNid);" in hst)
chk("el laser de Tails conserva SU ownerNid del v98d (no se toco)",
    "scr_player_hurt(dmg, -sign(x - global.player.x) * 4, 2, snd_hurt, spr_blood1, false, true, ownerNid);" in rd("objects/obj_tails_projectile/Step_0.gml"))

# ---------------------------------------------------------------------------
print("=== 7. D2 — EL PARRY DEVUELVE LOS 3 PROYECTILES ===")
chk("enum paridad: los 3 paquetes nuevos AL FINAL y en el MISMO orden en Packet.h y net_packets.gml",
    pkt_h.index("CLIENT_METALAMY_BULLET_DEFLECT") < pkt_h.index("CLIENT_FWBOLT_DEFLECT") < pkt_h.index("CLIENT_BLAZE_FIREBALL_DEFLECT") < pkt_h.index("} PacketType;")
    and nps.index("CLIENT_METALAMY_BULLET_DEFLECT") < nps.index("CLIENT_FWBOLT_DEFLECT") < nps.index("CLIENT_BLAZE_FIREBALL_DEFLECT") < nps.rindex("}"))
chk("Game.c: los 3 handlers de deflect (validacion + flip + broadcast)",
    all(s in game_c for s in ["case CLIENT_METALAMY_BULLET_DEFLECT:", "case CLIENT_FWBOLT_DEFLECT:", "case CLIENT_BLAZE_FIREBALL_DEFLECT:"]))
chk("el deflect de la flecha SOLO si damage > 0 (la dmg 0 es anti-exe: no se devuelve)",
    re.search(r"case CLIENT_FWBOLT_DEFLECT:[\s\S]*?if \(bolt->damage > 0\)", game_c) is not None)
chk("los 3 handlers validan que quien pide el deflect NO sea el Exe (superficie del deflect del laser)",
    game_c.count("v->id != v->server->game.exe") >= 3)
chk("cliente: estados 3 (bala) / 4 (flecha) / 5 (bola) del deflect",
    "else if(_state == 3) // v99: DEFLECT" in nsg
    and "else if(_state == 4) // v99: DEFLECT" in nsg
    and "else if(_state == 5) // v99: DEFLECT" in nsg)
chk("los deflects vuelven cian (patron visual del laser devuelto)",
    nsg.count("image_blend = SONIC_PB_COLOR;") >= 3)
chk("la flecha devuelta se CONVIERTE en la variante stun (dmg = 0)",
    "dmg = 0; // la variante anti-exe" in nsg)
chk("la bala devuelta aturde al killer 3 s y atraviesa a los aliados (rama deflected del Step)",
    "if(deflected)" in bst and "global.player.shockedTimer = 60 * 3;" in bst)
chk("la bola devuelta viaja anti-exe (exeFire = false + deflected)",
    "deflected = true; // viaja anti-exe" in nsg and "exeFire = false;\n                                        image_blend" in nsg.replace("                                        image_blend", "exeFire") or "deflected = true; // viaja anti-exe" in nsg)
chk("el Step de la bola marca exeFire (lo leen parry y escudo)",
    "exeFire = _blazeDemon;" in hst)
chk("scr_parry: los 3 bloques deflect con sus paquetes",
    all(s in parry for s in ["PacketType.CLIENT_METALAMY_BULLET_DEFLECT", "PacketType.CLIENT_FWBOLT_DEFLECT", "PacketType.CLIENT_BLAZE_FIREBALL_DEFLECT"]))
chk("scr_parry: el aura cubre a los aliados en los deflects (patron del laser: bbox vs other)",
    parry.count("scr_parry_bbox_overlap(self, other)") >= 3)
chk("el ESCUDO de Kris bloquea los 3 (deteccion frontal, SIN deflect: igual que el laser)",
    re.search(r"if\(scr_parry_char_is_kris\(global\.character\)\)[\s\S]*?obj_metal_amy_bullet[\s\S]*?scr_kris_block_front[\s\S]*?obj_fw_bolt[\s\S]*?scr_kris_block_front[\s\S]*?obj_blaze_fireball", parry) is not None)
chk("el deflect del laser de Tails original queda INTACTO",
    "PacketType.CLIENT_TPROJECTILE_DEFLECT" in parry and parry.index("CLIENT_TPROJECTILE_DEFLECT") < parry.index("CLIENT_METALAMY_BULLET_DEFLECT"))

# ---------------------------------------------------------------------------
print("=== 8. SINTAXIS C DEL SERVER (gcc -fsyntax-only, stub de enet) ===")
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
for f in ["states/Game.c", "entities/MetalAmyBullet.c", "entities/BlazeFireball.c",
          "entities/FwBolt.c", "entities/ItemBoxMap.c", "entities/ItemBox.c", "maps/KindAndFair.c"]:
    r = sp.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/{f}",
               shell=True, capture_output=True, text=True, cwd="betterserver-oss")
    chk(f"{f} compila limpio (gcc -fsyntax-only)", r.returncode == 0, r.stderr[:300])
shutil.rmtree(stub_dir, ignore_errors=True)

# ---------------------------------------------------------------------------
print("=== 9. LLAVES BALANCEADAS (archivos GML tocados) ===")
for f in ["scripts/net_state_game/net_state_game.gml", "scripts/net_packets/net_packets.gml",
          "scripts/scr_parry/scr_parry.gml", "scripts/scr_player_hurt/scr_player_hurt.gml",
          "objects/obj_player_puppet/Step_0.gml", "objects/obj_playerui/Draw_64.gml",
          "objects/obj_metal_amy_bullet/Create_0.gml", "objects/obj_metal_amy_bullet/Step_0.gml",
          "objects/obj_fw_bolt/Create_0.gml", "objects/obj_fw_bolt/Step_0.gml",
          "objects/obj_blaze_fireball/Create_0.gml", "objects/obj_blaze_fireball/Step_0.gml"]:
    txt = rd(f)
    txt2 = re.sub(r'"(?:[^"\\]|\\.)*"', '""', txt)
    txt2 = re.sub(r"//[^\n]*", "", txt2)
    txt2 = re.sub(r"/\*.*?\*/", "", txt2, flags=re.S)
    chk(f"{f}: llaves y parens balanceadas",
        txt2.count("{") == txt2.count("}") and txt2.count("(") == txt2.count(")"))

# ---------------------------------------------------------------------------
print("=== 10. v98b + v98c + v98d SIGUEN INTACTOS ===")
chk("v98b: el infinito sigue en (238, 15) rotado 90",
    "draw_sprite_ext(spr_counter, 8, 238, 15, 1, 1, 90, c_white, 1);" in rd("objects/obj_level/Draw_64.gml"))
chk("v98c: defaults defensivos del puppet intactos",
    re.search(r"^isJumping = false;$", rd("objects/obj_player_puppet/Create_0.gml"), re.M) is not None)
chk("v98d: el zap del escudo sigue con atribucion exacta (attackerNid antes de la heuristica)",
    re.search(r"if\(attackerNid >= 0\)\s*\n\s*_zapNid = attackerNid;\s*\n\s*else if\(instance_exists\(obj_player_puppet\)\)", hurt) is not None)
chk("v98d: la caja sigue cobrando al dueno del laser (botas/exe: nadie)",
    "powner != v->server->game.exe" in rd("betterserver-oss/disasterserver/entities/ItemBoxMap.c")
    and "target->type != ITEMTYPE_BOOTS" in rd("betterserver-oss/disasterserver/entities/ItemBoxMap.c"))
chk("checks viejos parcheados: reconocen el vuelo del v99",
    "V99_MOD" in rd("check_v98b.py") and "V99_MOD" in rd("check_v98c.py") and "V99_MOD" in rd("check_v98d.py"))

print()
print(f"RESULTADO: {OK} OK, {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
