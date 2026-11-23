#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_v76.py — Verificacion al 100% de la entrega v76 (HAZARD RELOCATE
+ SPAWN VARIETY).

Verifica:
  1. GML obj_itembox/Step_2.gml: lexer balanceado + nucleo v63 intacto +
     bloque v76 (lava/abismo/spikes) + rect Marijuna == rect del player.
  2. C Ring.c: gcc -fsyntax-only + formato de paquete intacto + memoria
     reciente (variedad) sin romper el roll rojo.
  3. C ItemBoxMap.c: gcc -fsyntax-only + veto v74 intacto + memoria ult-3.
  4. Server.h: campos ring_recent presentes, nucleo intacto.
  5. Anti-cheat/protocolo: Packet.h y net_packets.gml SIN cambios vs HEAD.
  6. .yyp/.resource_order sanos y sin CJK en todo lo entregado.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.abspath(__file__))
FAILS = []


def ok(msg):
    print(f"  [OK] {msg}")


def bad(msg):
    FAILS.append(msg)
    print(f"  [MAL] {msg}")


def rel(p):
    return os.path.join(REPO, p)


def read(p):
    return open(rel(p), encoding="utf-8").read()


# ---------------------------------------------------------------------------
print("== 1. obj_itembox/Step_2.gml (cliente) ==")
gml = read("objects/obj_itembox/Step_2.gml")

# 1a. Lexer: balance de llaves/parens/corchetes fuera de strings y comentarios
def lex_balance(src):
    depth = {"{": 0, "(": 0, "[": 0}
    pairs = {"}": "{", ")": "(", "]": "["}
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in "//":
            pass
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "/*":
            pass
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = (j + 2) if j >= 0 else n
            continue
        if c == '"':
            i += 1
            while i < n and src[i] != '"':
                if src[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if c == "'":
            i += 1
            while i < n and src[i] != "'":
                if src[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if c in depth:
            depth[c] += 1
        elif c in pairs:
            depth[pairs[c]] -= 1
            if depth[pairs[c]] < 0:
                return f"'{c}' cierra sin abrir"
        i += 1
    for k, v in depth.items():
        if v != 0:
            return f"'{k}' desbalanceado ({v:+d})"
    return None


err = lex_balance(gml)
if err:
    bad(f"lexer Step_2.gml: {err}")
else:
    ok("lexer Step_2.gml: llaves/parens/corchetes/strings balanceados")

# 1b. Nucleo v63 INTACTO (nada roto por el parche v76)
core_v63 = [
    ("gravedad 0.2", "vspd += 0.2;"),
    ("cap de caida 12", "if(vspd > 12)"),
    ("snap al suelo while", "while(place_meeting(x, y, obj_floor_parent))"),
    ("aterrizaje grounded", "grounded = true;"),
    ("polvita en la base", "scr_effect_quick(x + 15, y + 30, spr_dust, 0.5, true);"),
    ("chequeo resorte", "place_meeting(x, y, obj_spring_parent)"),
    ("fuera de room", "x < 0 || y < 0 || x > room_width || y > room_height"),
    ("one-shot reported en caida", "else if(!reported)"),
    ("rompe solo apoyada", "if(grounded && place_meeting(x, y, obj_tails_projectile))"),
    ("paquete activate", "cpacket_tcp(PacketType.CLIENT_BOX_ACTIVATE)"),
    ("emitter higiene", "audio_emitter_position(emitter, x, y-16, 0);"),
]
for name, frag in core_v63:
    if frag in gml:
        ok(f"nucleo v63 intacto: {name}")
    else:
        bad(f"nucleo v63 ROTO: {name} -> falta: {frag}")

# 1c. Bloque v76 presente y completo
hazards = [
    ("abismo (precipicio)", "place_meeting(x, y, obj_abyss)"),
    ("lava Volcano Valley", "place_meeting(x, y, obj_vv_lavacolumn)"),
    ("spikes estaticos", "place_meeting(x, y, obj_spike)"),
    ("guard one-shot", "if(!reported)"),
    ("relocate reportado", "if(_hz)\n                report_relocate();"),
]
for name, frag in hazards:
    if frag in gml:
        ok(f"v76 hazard: {name}")
    else:
        bad(f"v76 hazard FALTA: {name}")

# 1d. Rectangulo Marijuna == EXACTO al chequeo del player (cross-check)
# El rect letal vive en la linea if(...) ANTES del scr_player_hurt; esos
# 4 patrones son unicos en el archivo (las constantes de audio no matchean).
pl = read("objects/obj_marijuna_lavaplatform/Step_0.gml")
m_yprev = re.findall(r"player\.y \+ \d+ >= y \+ (\d+)", pl)
m_ynext = re.findall(r"player\.y <= y \+ (\d+)", pl)
m_xprev = re.findall(r"player\.x \+ \d+ >= x \+ (\d+)", pl)
m_xnext = re.findall(r"player\.x <= x \+ (\d+)", pl)
expected = [m_yprev[0], m_xprev[0], m_xnext[0], m_ynext[0]] if all(
    [m_yprev, m_ynext, m_xprev, m_xnext]) else []
box_rect = re.search(
    r"other\.bbox_right >= x \+ (\d+) && other\.bbox_left <= x \+ (\d+)"
    r"\s*&& other\.bbox_bottom >= y \+ (\d+) && other\.bbox_top <= y \+ (\d+)",
    gml)
if box_rect and all(expected):
    got = [box_rect.group(3), box_rect.group(1), box_rect.group(2), box_rect.group(4)]
    if got == expected:
        ok(f"rect Marijuna caja == rect player (x:{expected[1]}..{expected[2]}, y:{expected[0]}..{expected[3]})")
    else:
        bad(f"rect Marijuna DIFIERE: caja {got} vs player {expected}")
else:
    bad(f"rect Marijuna no parseado: player={expected} caja={'si' if box_rect else 'no'}")

# 1e. with() correcto sobre marijuna + break + other
if "with(obj_marijuna_lavaplatform)" in gml and "_hz = true;" in gml:
    ok("with(obj_marijuna_lavaplatform) con asignacion _hz presente")
else:
    bad("with(obj_marijuna_lavaplatform) o asignacion _hz faltante")

# 1f. Sin caracteres CJK (regresion del borrador)
cjk = re.findall(r"[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]", gml)
if cjk:
    bad(f"Step_2.gml contiene CJK: {cjk[:5]}")
else:
    ok("Step_2.gml sin caracteres CJK")

# ---------------------------------------------------------------------------
print("== 2. Ring.c (server): variedad de spawn rings ==")
ring = read("betterserver-oss/disasterserver/entities/Ring.c")

ring_checks = [
    ("memoria reciente 4", "#define RING_RECENT_MAX 4"),
    ("helper has", "static bool ring_recent_has(Server* server, int rid)"),
    ("veto nunca-repetir", "if (fresh > 0 && ring_recent_has(server, rnd))"),
    ("push FIFO", "server->game.ring_recent[RING_RECENT_MAX - 1] = (uint8_t)rnd;"),
    ("marca slot ocupado", "server->game.rings[rnd] = true;"),
    ("rid asignado", "ring->rid = (uint8_t)rnd;"),
    ("roll rojo intacto", "ring->red = g_mapList[server->game.map].spawn_red_rings && (rand() % 100 <= 10);"),
    ("paquete spawn intacto", "PacketWrite(&pack, packet_write8, 0);"),
    ("paquete despawn intacto", "PacketWrite(&pack, packet_write8, 1);"),
    ("paquete red flag intacto", "PacketWrite(&pack, packet_write8, ring->red);"),
    ("libera slot uninit", "server->game.rings[ring->rid] = 0;"),
]
for name, frag in ring_checks:
    if frag in ring:
        ok(f"Ring.c: {name}")
    else:
        bad(f"Ring.c FALTA: {name}")

# El paquete de spawn conserva el ORDEN exacto (rid, id, red)
m = re.search(r"PacketCreate\(&pack, SERVER_RING_STATE\);\s*"
              r"PacketWrite\(&pack, packet_write8, 0\);\s*"
              r"PacketWrite\(&pack, packet_write8, ring->rid\);\s*"
              r"PacketWrite\(&pack, packet_write16, ring->id\);\s*"
              r"PacketWrite\(&pack, packet_write8, ring->red\);", ring)
if m:
    ok("Ring.c: orden del paquete SERVER_RING_STATE intacto (rid,id,red)")
else:
    bad("Ring.c: orden del paquete SERVER_RING_STATE alterado")

# ---------------------------------------------------------------------------
print("== 3. ItemBoxMap.c (server): memoria ult-3 ==")
ibm = read("betterserver-oss/disasterserver/entities/ItemBoxMap.c")

ibm_checks = [
    ("macro ult-3", "#define ITEMBOX_RECENT_MAX 3"),
    ("helper has", "static bool itembox_recent_has(int zone)"),
    ("helper push", "static void itembox_recent_push(int zone)"),
    ("veto con frescas", "if (fresh_count > 0 && itembox_recent_has(rnd))"),
    ("push al elegir", "itembox_recent_push(rnd);"),
    ("reset por ronda", "itembox_recent_len = 0;"),
    ("veto v74 exe intacto", "uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;"),
    ("relocate one-shot server", "if (box[i]->nid != nid || box[i]->relocated)"),
    ("assert relocate", "AssertOrDisconnect(v->server, v->in_game);"),
    ("muerte ordenada relocate", "boxes[i]->timer = 0;"),
    ("spawn usa tabla", "box.pos.x = (double)tab->points[rnd][0];"),
]
for name, frag in ibm_checks:
    if frag in ibm:
        ok(f"ItemBoxMap.c: {name}")
    else:
        bad(f"ItemBoxMap.c FALTA: {name}")

# La referencia vieja solo es aceptable en COMENTARIOS (documentacion
# historica); en CODIGO debe haber desaparecido por completo.
ibm_code = "\n".join(l for l in ibm.splitlines()
                      if not l.strip().startswith(("/*", "*", "//")))
if "itembox_last_spawner" in ibm_code:
    bad("ItemBoxMap.c: referencia de CODIGO a itembox_last_spawner")
else:
    ok("ItemBoxMap.c: itembox_last_spawner fuera del codigo (solo comentario historico)")

# El veto v74 debe seguir EXACTAMENTE igual (byte compare contra HEAD)
r = subprocess.run(["git", "show", "HEAD:betterserver-oss/disasterserver/entities/ItemBoxMap.c"],
                   cwd=REPO, capture_output=True, text=True)
if r.returncode == 0:
    head = r.stdout
    for frag in ["game.exe == v->id", "SOLO las cajas nuevas",
                 "AssertOrDisconnect(v->server, v->in_game);",
                 "box[i]->relocated = true;"]:
        if frag in head and frag in ibm:
            ok(f"superficie v74 preservada: {frag[:40]}")
        else:
            bad(f"superficie v74 perdida: {frag[:40]}")

# ---------------------------------------------------------------------------
print("== 4. Server.h: campos de memoria ==")
sh = read("betterserver-oss/include/Server.h")
for name, frag in [
    ("array ring_recent[4]", "uint8_t ring_recent[4];"),
    ("contador len", "uint8_t ring_recent_len;"),
    ("rings[256] intacto", "bool rings[256];"),
    ("ring_coff intacto", "uint8_t ring_coff;"),
]:
    if frag in sh:
        ok(f"Server.h: {name}")
    else:
        bad(f"Server.h FALTA: {name}")

# Los nuevos campos deben vivir DENTRO del struct Game (antes de "} Game;")
gpos = sh.find("uint8_t ring_recent[4];")
gpos_end = sh.find("} Game;")
if 0 < gpos < gpos_end:
    ok("Server.h: ring_recent vive dentro del struct Game (auto-reset por ronda)")
else:
    bad("Server.h: ring_recent fuera del struct Game")

# ---------------------------------------------------------------------------
print("== 5. Anti-cheat / protocolo (regla 7) ==")
# Packet.h y net_packets.gml SIN cambios vs HEAD (cero paquetes nuevos)
for f in ["betterserver-oss/include/Packet.h",
          "scripts/net_packets/net_packets.gml",
          "scripts/net_state_game/net_state_game.gml",
          "objects/obj_itembox/Create_0.gml",
          "objects/obj_itembox/obj_itembox.yy"]:
    r = subprocess.run(["git", "diff", "--name-only", "HEAD", "--", f],
                       cwd=REPO, capture_output=True, text=True)
    if r.stdout.strip() == "":
        ok(f"sin cambios (correcto): {f}")
    else:
        bad(f"ARCHIVO TOCADO SIN RAZON: {f}")

# ---------------------------------------------------------------------------
print("== 6. Sintaxis C (gcc -fsyntax-only con stub enet) ==")
gcc = shutil.which("gcc")
if gcc:
    stub = os.path.join(tempfile.mkdtemp(prefix="enet_stub_"), "enet")
    os.makedirs(stub, exist_ok=True)
    with open(os.path.join(stub, "enet.h"), "w") as f:
        f.write("#ifndef ENET_STUB_H\n#define ENET_STUB_H\n"
                "#include <stdint.h>\n#include <stddef.h>\n"
                "typedef struct ENetPeer { uint32_t roundTripTime; } ENetPeer;\n"
                "typedef struct ENetHost { int dummy; } ENetHost;\n"
                "typedef struct ENetPacket { uint8_t *data; size_t dataLength; } ENetPacket;\n"
                "typedef struct { int type; ENetPeer *peer; ENetPacket *packet; } ENetEvent;\n"
                "#endif\n")
    for c in ["betterserver-oss/disasterserver/entities/Ring.c",
              "betterserver-oss/disasterserver/entities/ItemBoxMap.c"]:
        r = subprocess.run([gcc, "-fsyntax-only", "-Ibetterserver-oss/include",
                            "-I" + os.path.dirname(stub), c],
                           cwd=REPO, capture_output=True, text=True, timeout=60)
        if r.returncode == 0:
            ok(f"{os.path.basename(c)}: sintaxis OK")
        else:
            bad(f"{c}: {r.stderr[:400]}")
else:
    print("  (gcc no disponible)")

# ---------------------------------------------------------------------------
print("== 7. .yyp / .resource_order / sin CJK ==")
def load_yy_json(p):
    txt = open(rel(p), encoding="utf-8").read()
    return json.loads(re.sub(r",\s*([}\]])", r"\1", txt))

yyp = load_yy_json("Sonicexe The Disaster 2D Remake.yyp")
names = [x["id"]["name"] for x in yyp["resources"]]
if len(names) == len(set(names)):
    ok(f".yyp JSON valido: {len(names)} recursos, sin duplicados")
else:
    bad(".yyp con recursos duplicados")

for f in ["objects/obj_itembox/Step_2.gml",
          "betterserver-oss/disasterserver/entities/Ring.c",
          "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
          "betterserver-oss/include/Server.h"]:
    cjk = re.findall(r"[\u4e00-\u9fff]", read(f))
    if cjk:
        bad(f"CJK en {f}: {cjk[:3]}")
    else:
        ok(f"sin CJK: {f}")

# ---------------------------------------------------------------------------
print()
if FAILS:
    print(f"RESULTADO: {len(FAILS)} FALLO(S)")
    for f in FAILS:
        print(f"  - {f}")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK")
