#!/usr/bin/env python3
"""v77 — NOT PERFECT: cajas que siguen a la zona + puntos TL/TR.

Verifica (regla de oro 6: verificacion al 100%):
 1. ItemBoxSpawnTables.c: 56 zonas, nid 0..28 IDENTICOS a la v68 (append
    puro), 27 nuevos (13 TL + 14 TR), cada uno con suelo real debajo
    (derivado del room), sin rect prohibido en la posicion final de
    reposo, sin resorte a 48px. Demas tablas intactas vs HEAD.
 2. ItemBoxMap.c: helpers NP, filtro de zona en el spawn, reubicacion
    por zona cada tick, repoblacion inmediata, cadencia v68/v76 intacta
    (COFF 20 s, FIRST_DELAY 15 s, FIFO ult-3), superficie v74 intacta,
    FIND_MAX=24, gcc -fsyntax-only OK.
 3. Anti-cheat (regla 7): Packet.h / net_packets.gml / net_state_game.gml
    / objetos del cliente SIN cambios vs HEAD.
 4. .yyp sano + sin CJK en lo entregado.
 5. Re-validacion del metodo de generacion (FASE 1: 29/29 contra v68).
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict

REPO = os.path.dirname(os.path.abspath(__file__))
FAILS = []


def ok(msg):
    print(f"  [OK] {msg}")


def bad(msg):
    FAILS.append(msg)
    print(f"  [MAL] {msg}")


def read(p):
    with open(os.path.join(REPO, p)) as f:
        return f.read()


def head(p):
    """contenido del archivo en HEAD (git)"""
    r = subprocess.run(["git", "show", f"HEAD:{p}"], cwd=REPO,
                       capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


NP_ZW, NP_ZH = 2904.0, 1368.0

print("== 1. ItemBoxSpawnTables.c ==")
tbl = read("betterserver-oss/disasterserver/entities/ItemBoxSpawnTables.c")

m = re.search(r'static const uint16_t itembox_spawns_6\[\]\[2\] = \{(.*?)\};\s*\n#define ITEMBOX_ZONES_6 (\d+)', tbl, re.S)
if not m:
    bad("no se encontro la tabla 6 / define")
    pts_s, zones_n = [], 0
else:
    pts_s = [(int(a), int(b)) for a, b in re.findall(r'\{\s*(\d+),\s*(\d+)\s*\}', m.group(1))]
    zones_n = int(m.group(2))

if zones_n == 56:
    ok("ITEMBOX_ZONES_6 == 56")
else:
    bad(f"ITEMBOX_ZONES_6 == {zones_n} (esperado 56)")

if len(pts_s) == 56:
    ok("la tabla 6 tiene 56 puntos")
else:
    bad(f"la tabla 6 tiene {len(pts_s)} puntos (esperado 56)")

# nid 0..28 identicos a HEAD
head_tbl = head("betterserver-oss/disasterserver/entities/ItemBoxSpawnTables.c")
hm = re.search(r'static const uint16_t itembox_spawns_6\[\]\[2\] = \{(.*?)\};', head_tbl, re.S)
hpts = [(int(a), int(b)) for a, b in re.findall(r'\{\s*(\d+),\s*(\d+)\s*\}', hm.group(1))] if hm else []
if pts_s[:29] == hpts[:29] and len(hpts) == 29:
    ok("nid 0..28 IDENTICOS a la v68 (append puro, ningun indice cambia)")
else:
    bad("los nid 0..28 cambiaron respecto a HEAD")

new_pts = pts_s[29:]
tl = [p for p in new_pts if p[0] < NP_ZW and p[1] < NP_ZH]
tr = [p for p in new_pts if p[0] >= NP_ZW and p[1] < NP_ZH]
otros = [p for p in new_pts if p[1] >= NP_ZH]
if len(tl) == 13 and len(tr) == 14 and not otros:
    ok(f"27 nuevos: {len(tl)} TL (zona 0) + {len(tr)} TR (zona 1), ninguno en la mitad inferior")
else:
    bad(f"distribucion nueva incorrecta: TL={len(tl)} TR={len(tr)} otros={len(otros)}")

# demas tablas intactas (normalizando espacios/tabs: el editor reindento
# el archivo entero a espacios, mismo patron v76 en Ring.c/ItemBoxMap.c)

def norm(s):
    return re.sub(r'[ \t]+', ' ', s)

cur_tables = norm(re.sub(r'/\* \[6\] Not Perfect.*?ITEMBOX_ZONES_6 56', 'X', tbl, flags=re.S))
head_tables = norm(re.sub(r'/\* \[6\] Not Perfect.*?ITEMBOX_ZONES_6 29', 'X', head_tbl, flags=re.S))
if cur_tables == head_tables:
    ok("todas las demas tablas intactas vs HEAD (solo reindentacion)")
else:
    bad("algo fuera de la tabla 6 cambio en ItemBoxSpawnTables.c")

# ---- validacion fisica de los 27 puntos nuevos contra el room
room = read("rooms/room_notperfect/room_notperfect.yy")
inst_re = re.compile(
    r'\{"\$GMRInstance":"v4".*?"scaleX":([\d.eE+-]+),"scaleY":([\d.eE+-]+),'
    r'"x":([\d.eE+-]+),"y":([\d.eE+-]+),\}', re.S)
insts = defaultdict(list)
for mm in inst_re.finditer(room):
    blk = mm.group(0)
    objm = re.search(r'"objectId":\{"name":"([^"]+)"', blk)
    if objm:
        insts[objm.group(1)].append((float(mm.group(3)), float(mm.group(4)),
                                     float(mm.group(1)), float(mm.group(2))))
floors = [(x, y, 128 * sx, 128 * sy) for x, y, sx, sy in insts['obj_solid_block']]
floors += [(x, y, 64 * sx, 32 * sy) for x, y, sx, sy in insts['obj_platform_jumptrough']]
springs = [(x, y) for x, y, _, _ in insts['obj_bspring_up']]

zsrc = read("betterserver-oss/disasterserver/Zone.c")
zm = re.search(r'Zone room_notperfect\[\] =\s*\{(.*?)\};', zsrc, re.S)
forb = [(float(x), float(y), float(x) + float(w) * 128, float(y) + float(h) * 128)
        for x, y, w, h in re.findall(
            r'\{\s*([\d.-]+),\s*([\d.-]+),\s*BLOCK_SIZE \* ([\d.]+),\s*BLOCK_SIZE \* ([\d.]+)\s*\}',
            zm.group(1))]


def overlap(a, b, tol=0.5):
    return not (a[2] <= b[0] + tol or b[2] <= a[0] + tol or
                a[3] <= b[1] + tol or b[3] <= a[1] + tol)


def final_rest(px, py):
    best = None
    for fx, fy, fw, fh in floors:
        ov = min(px + 30, fx + fw) - max(px, fx)
        if ov <= 0 and not (fx <= px and px + 30 <= fx + fw):
            continue
        if fy < py + 30 and fy + fh > py:
            if best is None or fy > best:
                best = fy
    return (px, py) if best is None else (px, best - 30)


bad_phys = []
for px, py in new_pts:
    # suelo en la ventana v68 (ring y ~24px sobre su plataforma)
    fx_, fy_ = final_rest(px, py)
    supported = any(
        (min(px + 30, fx + fw) - max(px, fx)) >= 8 and abs(fy - (py + 30)) <= 40.5
        for fx, fy, fw, fh in floors)
    box = (fx_, fy_, fx_ + 30, fy_ + 30)
    player = (fx_, fy_ - 50, fx_ + 30, fy_ + 30)
    in_forb = any(overlap(box, r, 1.0) or overlap(player, r, 1.0) for r in forb)
    near_spring = any(abs(sx - (px + 15)) < 48 and abs(sy - (py + 15)) < 48 for sx, sy in springs)
    if not supported or in_forb or near_spring:
        bad_phys.append((px, py, supported, in_forb, near_spring))
if not bad_phys:
    ok("27 puntos nuevos: todos con suelo real (ventana v68), fuera de rects prohibidos y sin resortes a 48px")
else:
    bad(f"puntos fisicamente invalidos: {bad_phys}")

# FASE 1 re-validada: los 29 v68 se regeneran 29/29 desde los ring spawners
print("== 2. Re-validacion del metodo (FASE 1) ==")
ring_bl = [(x, y) for x, y, _, _ in insts['obj_ring_spawner'] if y >= NP_ZH]


def floor_below(x, y_from, window=40.0):
    best = None
    for fx, fy, fw, fh in floors:
        ov = min(x + 30, fx + fw) - max(x, fx)
        if ov < 8:
            continue
        if y_from - 0.5 <= fy <= y_from + window:
            if best is None or fy < best:
                best = fy
    return best


regen = []
for rx, ry in ring_bl:
    top = floor_below(rx + 24, ry)
    if top is None:
        continue
    regen.append((rx + 24, top - 30))
seen = set()
regen_d = []
for p in sorted(regen):
    key = (int(p[0] // 96), int(p[1] // 64))
    if key in seen:
        continue
    seen.add(key)
    regen_d.append(p)
if set(regen_d) == set(hpts):
    ok(f"FASE 1: regeneracion de la mitad inferior = {len(regen_d)}/29 EXACTO vs v68")
else:
    bad(f"FASE 1 diverge: falta {sorted(set(hpts) - set(regen_d))} sobra {sorted(set(regen_d) - set(hpts))}")

print("== 3. ItemBoxMap.c ==")
src = read("betterserver-oss/disasterserver/entities/ItemBoxMap.c")
checks = [
    ("include NotPerfect.h", "#include <entities/NotPerfect.h>" in src),
    ("NP_MAP_ID 6", "#define NP_MAP_ID   6" in src),
    ("constantes zona 2904/1368", "NP_ZONE_W   2904.0" in src and "NP_ZONE_H   1368.0" in src),
    ("np_zone_of helper", "static int np_zone_of(uint16_t px, uint16_t py)" in src),
    ("np_current_zone con fallback -1", "static int np_current_zone(Server* server)" in src and "return -1;" in src),
    ("busca tag npctrl", '"npctrl"' in src),
    ("zona = stage %% 4", "stage % 4" in src),
    ("spawn_one: filtro por zona", "np_zone_of(tab->points[i][0], tab->points[i][1]) == zone" in src),
    ("spawn_one: push FIFO intacto", "itembox_recent_push(rnd);" in src),
    ("spawn_one: MakeItemBox intacto", "MakeItemBox((uint8_t)rnd, itembox_roll_type())" in src),
    ("spawn_one: pos desde tabla", "box.pos.x = (double)tab->points[rnd][0];" in src),
    ("tick: reubicacion por zona", "np_zone_of(tab->points[boxes[i]->nid][0], tab->points[boxes[i]->nid][1]) != zone" in src),
    ("tick: marca relocated antes de matar", "boxes[i]->relocated = true;" in src),
    ("tick: timer=0 muerte ordenada", "boxes[i]->timer = 0;" in src),
    ("tick: repoblacion = removed", "int back = removed;" in src),
    ("tick: bounded por ITEMBOX_MAX", "back > ITEMBOX_MAX - alive_after" in src),
    ("tick: roll cadencia intacta", "itembox_next_roll = server->game.elapsed + ITEMBOX_SPAWN_COFF;" in src),
    ("init: FIRST_DELAY intacto", "ITEMBOX_FIRST_DELAY" in src),
    ("init: reset FIFO ult-3 intacto", "itembox_recent_len = 0;" in src),
    ("FIFO ult-3 intacto (v76)", "#define ITEMBOX_RECENT_MAX 3" in src),
    ("FIND_MAX 24", "#define ITEMBOX_FIND_MAX (ITEMBOX_MAX * 6)" in src),
    ("sin ITEMBOX_MAX * 3 restante", "ITEMBOX_MAX * 3" not in src),
    ("v74: exe-denial intacto", "uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;" in src),
    ("v74: solo cajas nuevas (comentario)", "SOLO las cajas nuevas" in src),
    ("RELOCATE handler: one-shot intacto", "if (box[i]->nid != nid || box[i]->relocated)" in src),
    ("ACTIVATE: AssertOrDisconnect intacto", "AssertOrDisconnect(v->server, v->in_game);" in src),
    ("goto gen nunca-repetir intacto", "if (fresh > 0 && itembox_recent_has(rnd))" in src),
]
for name, cond in checks:
    ok(name) if cond else bad(name)

print("== 4. Sintaxis C (gcc -fsyntax-only, stub enet) ==")
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
    for c in ["betterserver-oss/disasterserver/entities/ItemBoxMap.c",
              "betterserver-oss/disasterserver/entities/ItemBoxSpawnTables.c"]:
        r = subprocess.run([gcc, "-fsyntax-only", "-Wall",
                            "-Ibetterserver-oss/include", f"-I{os.path.dirname(stub)}",
                            os.path.join(REPO, c)], capture_output=True, text=True, cwd=REPO)
        if r.returncode == 0 and not r.stderr.strip():
            ok(f"{os.path.basename(c)}: sintaxis OK (sin warnings)")
        else:
            bad(f"{os.path.basename(c)}: {r.stderr.strip()[:200]}")
else:
    print("  [SKIP] gcc no disponible")

print("== 5. Anti-cheat / protocolo (regla 7) ==")
for p in ["betterserver-oss/include/Packet.h",
          "scripts/net_packets/net_packets.gml",
          "scripts/net_state_game/net_state_game.gml",
          "objects/obj_itembox/Step_2.gml",
          "objects/obj_itembox/Create_0.gml",
          "objects/obj_itembox/obj_itembox.yy",
          "rooms/room_notperfect/room_notperfect.yy",
          "objects/obj_np_controller/obj_np_controller.yy",
          "betterserver-oss/disasterserver/entities/NotPerfect.c"]:
    if read(p) == head(p):
        ok(f"sin cambios (correcto): {p}")
    else:
        bad(f"ARCHIVO MODIFICADO (inesperado): {p}")

print("== 6. .yyp y CJK ==")


def load_yy_json(p):
    txt = open(os.path.join(REPO, p), encoding="utf-8").read()
    return json.loads(re.sub(r",\s*([}\]])", r"\1", txt))


yyp = load_yy_json("Sonicexe The Disaster 2D Remake.yyp")
names = [x["id"]["name"] for x in yyp["resources"]]
if len(names) == len(set(names)):
    ok(f".yyp JSON valido: {len(names)} recursos, sin duplicados")
else:
    bad(".yyp con recursos duplicados")

for p in ["betterserver-oss/disasterserver/entities/ItemBoxMap.c",
          "betterserver-oss/disasterserver/entities/ItemBoxSpawnTables.c"]:
    txt = read(p)
    cjk = [ch for ch in txt if '\u4e00' <= ch <= '\u9fff' or '\u3040' <= ch <= '\u30ff']
    if not cjk:
        ok(f"sin CJK: {os.path.basename(p)}")
    else:
        bad(f"CJK presente en {p}: {cjk[:5]}")

print()
if FAILS:
    print(f"RESULTADO: {len(FAILS)} CHECKS MAL")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK")
