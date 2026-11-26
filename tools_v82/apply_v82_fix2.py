#!/usr/bin/env python3
"""v82 - ultimo retoque fuera del nucleo: la 2a patada de Sally Canon (el TP de
fase 2) tambien usa la forma cyber (objects/obj_player_puppet/Step_0.gml).

Se aplica DESPUES de apply_v82_core.py y apply_v82_hooks.py.
Uso: python3 apply_v82_fix2.py [ruta_del_repo]
Idempotente: si el marcador ya esta, salta.
"""
import os
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/work/disaster2d-oss"
STEP_REL = "objects/obj_player_puppet/Step_0.gml"

P4_OLD = "var _f2pad = ceil((bbox_right - bbox_left) * SALLY_CANON_KICK_PCT_F2_GROUND);"
P4_NEW = ("var _f2pad = ceil((bbox_right - bbox_left) * SALLY_CANON_KICK_PCT_F2_GROUND * scr_sally_cyber_hitbox_mul(cyberForm, revivalTimes >= 2));"
          " // v82: media hitbox de la 2a patada, con la forma cyber")
MARKER = "con la forma cyber"


def main():
    path = os.path.join(REPO, STEP_REL)
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8")
    if MARKER in text:
        print("[SKIP] ya estaba      2a patada x forma cyber")
        return
    n = text.count(P4_OLD)
    if n != 1:
        raise SystemExit("[XX] ABORTO: el ancla aparece %d veces (se esperaba 1) en %s" % (n, path))
    with open(path, "wb") as fh:
        fh.write(text.replace(P4_OLD, P4_NEW).encode("utf-8"))
    print("[OK]   parcheado       2a patada x forma cyber")


if __name__ == "__main__":
    main()
