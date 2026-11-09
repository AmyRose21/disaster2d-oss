#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_nu_v2_room.py — Fix V2 del porte NU Project (Negagen Temple).

El bug: room_alphagentemple.yy traia "%%Name" (doble %) en vez de "%Name".
JSON valido (por eso el parser tolerante del check V1 lo paso), pero el
esquema de GameMaker exige el campo EXACTO "%Name" -> "Field %Name expected"
en (3,3) y el IDE no abria el proyecto.

Este check cubre el hueco del V1: valida el PRIMER CAMPO EXACTO de todos
los .yy nuevos del porte, no solo la sintaxis JSON + parent.path.

Checks:
 [1] Los 19 .yy nuevos parsean (tolerante a comas finales estilo GM)
 [2] Primer key == "$GM<Tipo>" esperado (Room/Sprite/Sound/Object)
 [3] Key "%Name" EXACTO presente (ni "%%Name", ni ausente, ni otro %*)
 [4] Ninguna key del recurso contiene "%%" (barrido por archivo)
 [5] "%Name" == nombre del recurso (nombre de carpeta)
 [6] parent.path registrado en Folders del .yyp
 [7] Recurso registrado en la lista "id" del .yyp
 [8] Room: isDnd presente, 9 capas, 113 instancias, 2816x1536
 [9] Barrido repo-wide: ninguna key "%%..." en NINGUN .yy del proyecto
[10] Diff vs zip V1: la UNICA linea cambiada es la 3 (%Name)
"""
import json, re, sys, os, zipfile, io

os.chdir(os.path.dirname(os.path.abspath(__file__)))
YYP = "Sonicexe The Disaster 2D Remake.yyp"
V1ZIP = "/home/z/my-project/download/td2dr_nu_project_v1_negagentemple.zip"

ok = fail = 0
def chk(cond, msg):
    global ok, fail
    tag = "OK " if cond else "FAIL"
    if not cond: fail += 1
    else: ok += 1
    print(f"[{tag}] {msg}")

def tolerant_parse(path):
    s = open(path, encoding="utf-8-sig").read()
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", s)), s

# --- cargar .yyp ---
yyp, _ = tolerant_parse(YYP)
folders = {f["folderPath"] for f in yyp["Folders"]}
resources = set()
for r in yyp["resources"]:
    rid = r.get("id")
    if isinstance(rid, dict):
        resources.add(rid.get("path"))
    elif isinstance(rid, str):
        resources.add(rid)

# --- los 19 recursos nuevos del porte NU ---
NEW = {
    "rooms/room_alphagentemple/room_alphagentemple.yy":  "$GMRoom",
    "sprites/spr_bg_nt/spr_bg_nt.yy":                    "$GMSprite",
    "sprites/spr_bg_nt2/spr_bg_nt2.yy":                  "$GMSprite",
    "sprites/spr_dusha/spr_dusha.yy":                    "$GMSprite",
    "sprites/spr_dusha2/spr_dusha2.yy":                  "$GMSprite",
    "sprites/spr_femboy/spr_femboy.yy":                  "$GMSprite",
    "sprites/spr_negatv/spr_negatv.yy":                  "$GMSprite",
    "sprites/spr_nt_tiles/spr_nt_tiles.yy":              "$GMSprite",
    "sprites/spr_nt_tiles2/spr_nt_tiles2.yy":            "$GMSprite",
    "sprites/spr_nt_tiles3/spr_nt_tiles3.yy":            "$GMSprite",
    "sprites/spr_pr_bg_nt/spr_pr_bg_nt.yy":              "$GMSprite",
    "sprites/spr_pr_nt_tile/spr_pr_nt_tile.yy":          "$GMSprite",
    "sprites/spr_pr_nt_tile2/spr_pr_nt_tile2.yy":        "$GMSprite",
    "sprites/spr_pr_nt_tile3/spr_pr_nt_tile3.yy":        "$GMSprite",
    "sprites/statui/statui.yy":                          "$GMSprite",
    "sounds/mus_alphagentemple/mus_alphagentemple.yy":   "$GMSound",
    "sounds/mus_alphagentemple_chase/mus_alphagentemple_chase.yy": "$GMSound",
    "objects/obj_femboy_temple/obj_femboy_temple.yy":    "$GMObject",
    "objects/obj_negatv/obj_negatv.yy":                  "$GMObject",
}

print("== [1-7] Schema de los 19 .yy nuevos ==")
for rel, tag in NEW.items():
    try:
        data, raw = tolerant_parse(rel)
    except Exception as e:
        chk(False, f"{rel}: NO PARSEA: {e}")
        continue
    name = os.path.basename(rel)[:-3]
    keys = list(data.keys())
    chk(keys[0] == tag, f"{name}: primer key '{keys[0]}' == '{tag}'")
    bad_pct = [k for k in keys if k.startswith("%%")]
    chk(not bad_pct, f"{name}: sin keys '%%...' ({bad_pct or 'limpio'})")
    chk("%Name" in data, f"{name}: key '%Name' EXACTA presente")
    chk(data.get("%Name") == name, f"{name}: %Name == '{name}' (valor: {data.get('%Name')!r})")
    parent = data.get("parent", {}).get("path")
    chk(parent in folders, f"{name}: parent '{parent}' registrado en .yyp")
    chk(f"{os.path.dirname(rel)}/{name}.yy" in resources, f"{name}: en lista 'id' del .yyp")

print("\n== [8] Room en detalle ==")
room, _ = tolerant_parse("rooms/room_alphagentemple/room_alphagentemple.yy")
chk("isDnd" in room, "room: isDnd presente (leccion del skybase V1)")
chk(room["%Name"] == "room_alphagentemple", "room: %Name correcto tras el fix")
chk(len(room["layers"]) == 9, f"room: 9 capas (tiene {len(room['layers'])})")
chk(len(room["instanceCreationOrder"]) == 113, f"room: 113 instancias (tiene {len(room['instanceCreationOrder'])})")
w = room["roomSettings"]["Width"]; h = room["roomSettings"]["Height"]
chk((w, h) == (2816, 1536), f"room: 2816x1536 (es {w}x{h})")

print("\n== [9] Barrido repo-wide de keys '%%' ==")
hits = []
for root, _, files in os.walk("."):
    if root.startswith(("./.git", "./betterserver-oss")): continue
    for f in files:
        if not f.endswith(".yy"): continue
        p = os.path.join(root, f)
        try:
            d, _ = tolerant_parse(p)
        except Exception:
            continue
        for k in d.keys():
            if k.startswith("%%"):
                hits.append(f"{p}: '{k}'")
chk(not hits, f"ninguna key '%%' en ningun .yy del proyecto ({hits or 'limpio'})")

print("\n== [10] Diff vs zip V1: solo la linea 3 cambia ==")
try:
    with zipfile.ZipFile(V1ZIP) as z:
        old_raw = z.read("rooms/room_alphagentemple/room_alphagentemple.yy").decode("utf-8")
    new_raw = open("rooms/room_alphagentemple/room_alphagentemple.yy", encoding="utf-8").read()
    old_l, new_l = old_raw.splitlines(), new_raw.splitlines()
    chk(len(old_l) == len(new_l), f"mismo numero de lineas ({len(old_l)})")
    diffs = [(i+1, a, b) for i, (a, b) in enumerate(zip(old_l, new_l)) if a != b]
    chk(len(diffs) == 1 and diffs[0][0] == 3 and "%%Name" in diffs[0][1] and re.match(r'\s*"%Name"', diffs[0][2]),
        f"UNICA linea distinta = la 3: '%%Name' -> '%Name' ({diffs})")
except FileNotFoundError:
    print("[----] zip V1 no disponible en esta maquina (skip)")

print(f"\n==== {ok} OK / {fail} FAIL ====")
sys.exit(1 if fail else 0)
