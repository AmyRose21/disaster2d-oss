#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_retira_smax_v1.py — verificador del RETIRA SMAX v1.

QUE CAMBIA (pedido del usuario): «¿esta esmerald hill y green hills
incluidos? ojo no confundas con Hill green hils. Smax y es asi elimina
esas 2 zonas de la seleccion esos estan corruptos».

Los dos mapas de testeo porteados de Sonic MAX salen de TODA via de
seleccion (votacion, .map, .sp/.vp de practica, UI del server):
  - "SMax Green Hill"   //21  room_smax_greenhill
  - "SMax Emerald Hill" //22  room_smax_emeraldhill
El "Hill" original del juego (indice 12, room_greenhill) NO se toca.

Este script NO modifica nada: solo verifica. Uso:
    python3 check_retira_smax_v1.py [raiz_del_repo]
Sale 0 si todo esta OK (imprime el detalle de cada chequeo).
"""

import re
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
SRV = os.path.join(ROOT, "betterserver-oss")

ok_count = 0
fail_count = 0

def check(name, cond, detail=""):
    global ok_count, fail_count
    if cond:
        ok_count += 1
        print(f"  [OK]   {name}" + (f" — {detail}" if detail else ""))
    else:
        fail_count += 1
        print(f"  [FAIL] {name}" + (f" — {detail}" if detail else ""))

def read(p):
    with open(p, encoding="utf-8", errors="replace") as f:
        return f.read()

print("== SERVIDOR ==")

maps_h = read(os.path.join(SRV, "include", "Maps.h"))
m = re.search(r"#define MAP_COUNT (\d+)", maps_h)
check("Maps.h define MAP_COUNT 21", m and m.group(1) == "21", m.group(0) if m else "no hay define")
check("Maps.h sin declaracion de smap_init", "smap_init" not in maps_h)

maps_c = read(os.path.join(SRV, "disasterserver", "Maps.c"))
gml = re.search(r"g_mapList\[MAP_COUNT\]\s*=\s*\{(.*?)\n\};", maps_c, re.S).group(1)
entry_lines = [l for l in gml.splitlines() if re.match(r"^\s*\{\s*CLRCODE_", l)]
names = [re.findall(r'"([^"]+)"', l)[0] for l in entry_lines]
check("g_mapList tiene exactamente 21 entradas", len(names) == 21, f"{len(names)} entradas")
check("g_mapList[12] sigue siendo 'Hill' (el original)", names[12] == "Hill" if len(names) > 12 else False)
check("g_mapList[20] sigue siendo 'Fart Zone' (practica)", names[20] == "Fart Zone" if len(names) > 20 else False)
check("Ningun SMax en g_mapList (entradas reales)", not any("SMax" in n for n in names))
check("Maps.c sin funcion smap_init", "bool smap_init" not in maps_c)

zone_h = read(os.path.join(SRV, "include", "Zone.h"))
check("Zone.h declara g_mapZone[21]", "g_mapZone[21]" in zone_h)
check("Zone.h declara g_mapZoneSize[21]", "g_mapZoneSize[21]" in zone_h)

zone_c = read(os.path.join(SRV, "disasterserver", "Zone.c"))
gz = re.search(r"Zone\* g_mapZone\[(\d+)\]\s*=\s*\{(.*?)\n\};", zone_c, re.S)
gzs = re.search(r"size_t g_mapZoneSize\[(\d+)\]\s*=\s*\{(.*?)\n\};", zone_c, re.S)
n_gz = len(re.findall(r"room_\w+", gz.group(2)))
n_gzs = len(re.findall(r"ARRAY_SIZE\(room_\w+\)", gzs.group(2)))
check("g_mapZone: 21 entradas y decl [21]", n_gz == 21 and gz.group(1) == "21", f"{n_gz} entradas, decl [{gz.group(1)}]")
check("g_mapZoneSize: 21 entradas y decl [21]", n_gzs == 21 and gzs.group(1) == "21", f"{n_gzs} entradas, decl [{gzs.group(1)}]")
check("Zone.c sin arrays room_smax_*", "room_smax_" not in zone_c)
check("Zone.c llaves balanceadas", zone_c.count("{") == zone_c.count("}"),
      f"{zone_c.count('{')} vs {zone_c.count('}')}")

cfg_h = read(os.path.join(SRV, "include", "Config.h"))
check("Config.h declara map_list[21]", "map_list[21]" in cfg_h)

cfg_c = read(os.path.join(SRV, "disasterserver", "Config.c"))
ml = re.search(r"\.map_list = \{ ([^}]*) \}", cfg_c).group(1)
vals = [v.strip() for v in ml.split(",")]
check("Config.c defaults: 21 bools, ultimo false (Fart fuera del voto)",
      len(vals) == 21 and vals[-1] == "false" and all(v == "true" for v in vals[:20]),
      f"{len(vals)} valores")

lob = read(os.path.join(SRV, "disasterserver", "states", "Lobby.c"))
check("states/Lobby.c bound del .map es 'ind >= MAP_COUNT' (sin OOB)",
      "ind >= MAP_COUNT)" in lob and "MAP_COUNT+1" not in lob)
check("states/Lobby.c mensaje 'between 1 and %d' con MAP_COUNT",
      '"map should be between 1 and %d", MAP_COUNT);' in lob)

srv = read(os.path.join(SRV, "disasterserver", "states", "Server.c"))
check("states/Server.c ayuda .map con MAP_COUNT (no +1)",
      'choose map (1-%d)", MAP_COUNT);' in srv)

print("== CLIENTE ==")

g = read(os.path.join(ROOT, "scripts", "scr_globals", "scr_globals.gml"))
lv_body = re.search(r"global\.levels\s*=\s*\[(.*?)\n\];", g, re.S).group(1)
lv = re.findall(r"\{\s*group:\s*\"([^\"]+)\"[^}]*rid:\s*(\w+)", lv_body)
de_body = re.search(r"global\.levelDescriptions\s*=\s*\[(.*?)\n\];", g, re.S).group(1)
de = re.findall(r'^\s*"((?:[^"\\]|\\.)*)"', de_body, re.M)
check("global.levels tiene 21 entradas", len(lv) == 21, f"{len(lv)}")
check("global.levels[12] es Hill/room_greenhill (NO confundir con los SMax)",
      lv[12] == ("Hill", "room_greenhill") if len(lv) > 12 else False)
check("global.levels[20] es Fart/room_fartzone", lv[20] == ("Fart", "room_fartzone") if len(lv) > 20 else False)
check("Ningun room_smax_* en global.levels", "room_smax_" not in lv_body)
check("levelDescriptions alineada 1:1 (21) — el crash del 22, muerto",
      len(de) == 21, f"{len(de)} descripciones")
check("levelDescriptions sin textos del porte SMax",
      not any("Sonic MAX" in d for d in de))

pr = read(os.path.join(ROOT, "objects", "obj_lobby_prolet", "Create_0.gml"))
md_body = re.search(r"mapData\s*=\s*\[(.*?)\n\];", pr, re.S).group(1)
md = re.findall(r"\{\s*tiles:\s*\[([^\]]*)\]\s*,\s*bg:\s*(\w+)", md_body)
check("mapData (previews del lobby) tiene 21 entradas", len(md) == 21, f"{len(md)}")
check("mapData sin previews SMax (spr_pr_ehz)", "spr_pr_ehz" not in md_body)
check("mapData[12] es el preview ghz original", md[12][1] == "spr_pr_ghzbg" if len(md) > 12 else False)

print("== RESIDUOS ==")

def strip_comments(txt):
    txt = re.sub(r"/\*.*?\*/", "", txt, flags=re.S)
    txt = re.sub(r"//[^\n]*", "", txt)
    return txt

compiled = [
    os.path.join(SRV, "disasterserver", "Maps.c"),
    os.path.join(SRV, "disasterserver", "Zone.c"),
    os.path.join(SRV, "disasterserver", "Config.c"),
    os.path.join(SRV, "disasterserver", "states", "Lobby.c"),
    os.path.join(SRV, "disasterserver", "states", "Server.c"),
    os.path.join(SRV, "include", "Maps.h"),
    os.path.join(SRV, "include", "Zone.h"),
    os.path.join(SRV, "include", "Config.h"),
]
resid = [os.path.basename(p) for p in compiled if re.search(r"smap_|smax_|SMax ", strip_comments(read(p)))]
check("Cero referencias smap/smax en CODIGO (solo comentarios explicativos)", not resid, f"{resid}")

print()
print(f"RESULTADO: {ok_count}/{ok_count + fail_count} OK")
if fail_count:
    print(f"*** {fail_count} CHEQUEOS FALLIDOS ***")
    sys.exit(1)
print("TODO CONSISTENTE: 21 mapas, SMax fuera de la seleccion, Hill [12] y Fart [20] intactos")
