#!/usr/bin/env python3
"""yyp_add_rouge.py v2 — Integra el paquete Rouge en un .yyp EXISTENTE.

v2: AUTO-REPARA el .yyp primero (coma colgante, comillas tipograficas,
BOM, comentarios) usando gm_json, respalda (.yyp.bak) y solo entonces
integra el paquete:
  1. Copia sprites/* y objects/obj_rouge al proyecto (sin sobreescribir).
  2. Registra cada recurso en el .yyp: {id, resourcePath, resourceType, name}.
  3. Crea folders/Sprites.yy y folders/Objects.yy con children si faltan.
  4. Verifica al final que todas las referencias cuadren.

USO (Windows, en la carpeta del proyecto, junto a la carpeta del paquete):
  py yyp_add_rouge.py "Sonicexe The Disaster 2D Remake.yyp"
  py yyp_add_rouge.py "proyecto.yyp" --pack "Rogue_GameMaker_Pack"
"""
import json, os, sys, uuid, glob, shutil, argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gm_json import load_repair  # noqa: E402

DEFAULT_PACK = None  # se resuelve con --pack o carpeta hermana


def backup(path):
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copyfile(path, bak)
    return bak


def resolve_pack(explicit, script_dir):
    if explicit:
        return os.path.abspath(explicit)
    # el pack suele estar junto a los scripts (misma carpeta del zip)
    for cand in [script_dir, os.path.dirname(script_dir)]:
        for name in ["Rogue_GameMaker_Pack", "gm_pack"]:
            p = os.path.join(cand, name)
            if os.path.isdir(p):
                return p
    return None


def ensure_folder_yy(root, folder_name, children_ids):
    """Crea folders/<Name>.yy (GMFolder) si no existe, con children."""
    p = os.path.join(root, "folders", f"{folder_name}.yy")
    if os.path.exists(p):
        data, _ = load_repair(p)
        if data is not None:
            ids = data.get("children", [])
            changed = False
            for cid in children_ids:
                if cid not in ids:
                    ids.append(cid)
                    changed = True
            if changed:
                backup(p)
                data["children"] = ids
                with open(p, "w") as fh:
                    json.dump(data, fh, indent=2)
            return
    os.makedirs(os.path.dirname(p), exist_ok=True)
    folder = {
        "resourceType": "GMFolder",
        "resourceVersion": "1.0",
        "name": folder_name,
        "tags": [],
        "isDefaultView": False,
        "localisedFolderName": "",
        "folderName": folder_name,
        "children": children_ids,
        "filter": "",
        "parent": {"name": "Main", "path": "folders/Main.yy"},
    }
    with open(p, "w") as fh:
        json.dump(folder, fh, indent=2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("yyp")
    ap.add_argument("--pack", help="ruta a Rogue_GameMaker_Pack (default: junto al script)")
    args = ap.parse_args()
    yyp = os.path.abspath(args.yyp)
    root = os.path.dirname(yyp)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    pack = resolve_pack(args.pack, script_dir)
    if not os.path.exists(yyp):
        print(f"ERROR: no existe {yyp}")
        sys.exit(1)
    if not pack or not os.path.isdir(os.path.join(pack, "sprites")):
        print("ERROR: no encuentro el paquete (carpeta con sprites/ y objects/).")
        print("       usa --pack 'Rogue_GameMaker_Pack'")
        sys.exit(1)
    print(f"paquete: {pack}")

    # --- 1. cargar (auto-reparando)
    proj, repairs = load_repair(yyp)
    if proj is None:
        print(f"FATAL: {repairs[0]}")
        print("Corre primero: py yyp_check.py <tu.yyp> --fix")
        sys.exit(1)
    if repairs:
        backup(yyp)
        with open(yyp, "w", encoding="utf-8") as fh:
            json.dump(proj, fh, indent=2)
        print("yyp auto-reparado:", "; ".join(repairs))

    res = proj.get("Resources", [])
    existing = {r.get("name") for r in res if r.get("name")}
    new_ids = {"sprites": [], "objects": []}

    added = []
    # --- 2. sprites
    for yy in sorted(glob.glob(f"{pack}/sprites/*/*.yy")):
        name = os.path.basename(yy)[:-3]
        dst = f"{root}/sprites/{name}"
        if os.path.exists(dst):
            print(f"  = sprites/{name} ya existe (no se copia)")
        else:
            shutil.copytree(os.path.dirname(yy), dst)
            print(f"  + sprites/{name}/")
        if name not in existing:
            rid = str(uuid.uuid4()).upper()
            res.append({"id": rid,
                        "resourcePath": f"sprites/{name}/{name}.yy",
                        "resourceType": "GMSprite", "name": name})
            new_ids["sprites"].append(rid)
            existing.add(name)
            added.append(("GMSprite", name))

    # --- 3. objeto
    for yy in sorted(glob.glob(f"{pack}/objects/*/*.yy")):
        name = os.path.basename(yy)[:-3]
        dst = f"{root}/objects/{name}"
        if os.path.exists(dst):
            print(f"  = objects/{name} ya existe (no se copia)")
        else:
            shutil.copytree(os.path.dirname(yy), dst)
            print(f"  + objects/{name}/")
        if name not in existing:
            rid = str(uuid.uuid4()).upper()
            res.append({"id": rid,
                        "resourcePath": f"objects/{name}/{name}.yy",
                        "resourceType": "GMObject", "name": name})
            new_ids["objects"].append(rid)
            existing.add(name)
            added.append(("GMObject", name))

    proj["Resources"] = res
    backup(yyp)
    with open(yyp, "w", encoding="utf-8") as fh:
        json.dump(proj, fh, indent=2)
    print(f".yyp actualizado: +{len(added)} recursos")

    # --- 4. folders/Sprites.yy y Objects.yy con children
    ensure_folder_yy(root, "Sprites", new_ids["sprites"])
    ensure_folder_yy(root, "Objects", new_ids["objects"])

    # --- 5. verificación final
    DIR = {"GMSprite": "sprites", "GMObject": "objects", "GMScript": "scripts",
           "GMSound": "sounds", "GMRoom": "rooms", "GMPath": "paths",
           "GMShader": "shaders", "GMFont": "fonts", "GMTileSet": "tilesets",
           "GMTimeline": "timelines", "GMSequence": "sequences",
           "GMAnimCurve": "animcurves", "GMExtension": "extensions"}
    bad = 0
    for r in proj["Resources"]:
        if r.get("resourceType") in DIR:
            p = f"{root}/{DIR[r['resourceType']]}/{r.get('name')}/{r.get('name')}.yy"
            if not os.path.exists(p):
                print(f"  ! SIN ARCHIVO: {r.get('name')}")
                bad += 1
    for yy in glob.glob(f"{root}/sprites/*/*.yy"):
        data, _ = load_repair(yy)
        if data is None:
            print(f"  ! YY ILEGIBLE: {yy}")
            bad += 1
            continue
        d = os.path.dirname(yy)
        for fr in data.get("frames", []):
            if not os.path.exists(f"{d}/{fr.get('name')}.png"):
                print(f"  ! FRAME SIN PNG: {yy} {fr.get('name')[:8]}")
                bad += 1
    print("VERIFICACION:", "OK — todas las referencias cuadran" if bad == 0 else f"{bad} rotas (arriba)")


if __name__ == "__main__":
    main()
