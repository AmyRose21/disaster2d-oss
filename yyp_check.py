#!/usr/bin/env python3
"""yyp_check.py v2 — Auditor + reparador de proyectos GameMaker (.yyp).

v2: si el .yyp o un .yy tiene JSON invalido (coma colgante, comillas
tipograficas, BOM, comentarios de edicion manual), lo REPARA primero
(con backup) y luego sigue la auditoria completa. El error tipico
"Failed to load project: Object reference not set to an instance of an
object" del IDE es exactamente un JSON roto o una referencia rota.

USO (Windows, en la carpeta del proyecto):
  py yyp_check.py "Sonicexe The Disaster 2D Remake.yyp"          # solo auditoria
  py yyp_check.py "Sonicexe The Disaster 2D Remake.yyp" --fix    # reparar
"""
import json, os, sys, glob, argparse, shutil, uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gm_json import load_repair  # noqa: E402

RES_DIR_MAP = {
    "GMSprite": "sprites", "GMObject": "objects", "GMScript": "scripts",
    "GMSound": "sounds", "GMRoom": "rooms", "GMPath": "paths",
    "GMShader": "shaders", "GMFont": "fonts", "GMTileSet": "tilesets",
    "GMTimeline": "timelines", "GMSequence": "sequences",
    "GMAnimCurve": "animcurves", "GMExtension": "extensions",
}


def backup(path):
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copyfile(path, bak)
    return bak


def load(path, fixes, problems, do_fix):
    """Carga JSON con reparacion tolerante. Con --fix reescribe el archivo
    reparado (backup antes). Devuelve el objeto o None."""
    obj, repairs = load_repair(path)
    if obj is None:
        problems.append(f"JSON INREPARABLE: {path}: {repairs[0]} (revisar a mano)")
        return None
    if repairs:
        if do_fix:
            backup(path)
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(obj, fh, indent=2)
            fixes.append(f"{os.path.basename(path)}: " + "; ".join(repairs))
        else:
            problems.append(f"JSON INVALIDO en {os.path.basename(path)}: " + "; ".join(repairs) + " (usa --fix)")
    return obj


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("yyp")
    ap.add_argument("--fix", action="store_true")
    args = ap.parse_args()
    yyp = os.path.abspath(args.yyp)
    root = os.path.dirname(yyp)
    if not os.path.exists(yyp):
        print(f"ERROR: no existe {yyp}")
        sys.exit(1)

    problems, fixes = [], []

    proj = load(yyp, fixes, problems, args.fix)
    if proj is None:
        print("=" * 60)
        print("FATAL: no se pudo leer el .yyp ni reparandolo. Es el archivo")
        print("que rompe el load del IDE. Revisa la linea/col del error a mano.")
        sys.exit(1)

    resources = proj.get("Resources", [])

    # --- ids duplicados
    seen_ids = {}
    for r in resources:
        rid = r.get("id")
        if rid and rid in seen_ids:
            problems.append(f"ID duplicado en .yyp: {rid} ({r.get('name')})")
        seen_ids[rid] = r.get("name")

    # --- recursos listados cuyo .yy no existe / huerfanos en disco
    listed = {}
    for r in resources:
        rt, name = r.get("resourceType", ""), r.get("name", "")
        folder = RES_DIR_MAP.get(rt)
        if folder is None:
            continue
        p = f"{root}/{folder}/{name}/{name}.yy"
        listed[p] = (name, rt)

    on_disk = {}
    for typ, folder in RES_DIR_MAP.items():
        for yy in glob.glob(f"{root}/{folder}/*/*.yy"):
            base = os.path.basename(yy)[:-3]
            on_disk[yy] = (base, typ)

    for p in [p for p in listed if not os.path.exists(p)]:
        n, t = listed[p]
        problems.append(f"RECURSO SIN ARCHIVO: {t} '{n}' en .yyp pero no hay {os.path.relpath(p, root)}")
        if args.fix:
            resources[:] = [r for r in resources
                            if not (r.get("resourceType") == t and r.get("name") == n)]
            fixes.append(f"quitado del .yyp: {t} '{n}' (no existia en disco)")

    for yy in [yy for yy in on_disk if yy not in listed]:
        n, t = on_disk[yy]
        problems.append(f"ARCHIVO HUERFANO: {os.path.relpath(yy, root)} no esta en el .yyp")
        if args.fix:
            resources.append({
                "id": str(uuid.uuid4()).upper(),
                "resourcePath": os.path.relpath(yy, root).replace("\\", "/"),
                "resourceType": t, "name": n,
            })
            fixes.append(f"agregado al .yyp: {t} '{n}'")

    # --- frames de sprites sin PNG
    for yy in sorted(glob.glob(f"{root}/sprites/*/*.yy")):
        base = os.path.basename(yy)[:-3]
        data = load(yy, fixes, problems, args.fix)
        if data is None or data.get("resourceType") != "GMSprite":
            continue
        d = os.path.dirname(yy)
        bad = [fr for fr in data.get("frames", [])
               if not os.path.exists(f"{d}/{fr.get('name')}.png")]
        if bad:
            problems.append(f"FRAMES SIN PNG: {base}: {len(bad)} frame(s) roto(s)")
            if args.fix:
                good = [fr for fr in data.get("frames", [])
                        if os.path.exists(f"{d}/{fr.get('name')}.png")]
                if good:
                    data["frames"] = good
                    seq = data.get("sequence") or {}
                    for tr in seq.get("tracks", []):
                        kfs = tr.get("keyframes", {}).get("Keyframes", [])
                        tr["keyframes"]["Keyframes"] = [
                            k for k in kfs
                            if k.get("Channels", {}).get("0", {}).get("Id", {}).get("name")
                            in {g.get("name") for g in good}]
                    seq["length"] = float(len(good))
                    backup(yy)
                    with open(yy, "w") as fh:
                        json.dump(data, fh, indent=2)
                    fixes.append(f"reparado {base}: -{len(bad)} frames sin PNG")
                else:
                    problems.append(f"  {base}: TODOS los frames rotos (no se toca)")

    # --- reporte
    print("=" * 60)
    print(f"PROYECTO: {yyp}")
    print(f"recursos en .yyp: {len(resources)} | .yy en disco: {len(on_disk)}")
    print("=" * 60)
    if not problems:
        print("OK: JSON valido y referencias consistentes.")
        print("Si el IDE aun no abre: (a) IDE viejo para resourceVersion nuevos;")
        print("(b) un .yy con campo null donde espera objeto; (c) .gml corrupto.")
    for p in problems:
        print("  !", p)
    if args.fix and fixes:
        backup(yyp)
        with open(yyp, "w", encoding="utf-8") as fh:
            json.dump(proj, fh, indent=2)
        print("=" * 60)
        print(f"REPAROS: {len(fixes)} (backup .yyp.bak / .yy.bak)")
        for f in fixes:
            print("  +", f)
    elif args.fix:
        print("nada mas que reparar")


if __name__ == "__main__":
    main()
