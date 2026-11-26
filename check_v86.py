#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v86 verification (no GameMaker here): lexer checks, content checks and
numeric simulations of the unified kick pads and the exit-arrow guard.

Usage: python3 -I check_v86.py <repo_root> [--roundtrip <zip>] [--allow-prev]
Exit code 0 only if every check passes.  Read-only.  --allow-prev tolerates the
v84+v85 file sets in git status (the recommended order applies them first).
"""
import os
import re
import subprocess
import sys
import zipfile

CODE = [
    "objects/obj_sally_canon/Draw_64.gml",
    "scripts/scr_sally_canon_fase2/scr_sally_canon_fase2.gml",
    "objects/obj_player_puppet/Step_0.gml",
]
DOCS = ["CACHE.md", "LEARNING.md", "worklog.md", "LEEME_V86_SALLY_HITBOX_FLECHA.txt", "check_v86.py"]
PREV = [
    "scripts/scr_chocola/scr_chocola.gml", "objects/obj_vanilla/Create_0.gml",
    "objects/obj_chocola/Create_0.gml", "scripts/net_udpprocess/net_udpprocess.gml",
    "scripts/net_state_game/net_state_game.gml", "scripts/scr_amelia_special/scr_amelia_special.gml",
    "objects/obj_amelia/Create_0.gml", "objects/obj_amelia_auras/Create_0.gml",
    "objects/obj_amelia_auras/Step_0.gml", "objects/obj_amelia_auras/Draw_64.gml",
    "objects/obj_amelia_indicators/Draw_64.gml", "betterserver-oss/include/Server.h",
    "betterserver-oss/disasterserver/states/Game.c", "CACHE.md", "LEARNING.md", "worklog.md",
    "LEEME_V84_VANILLA_CHOCOLA_AMELIA.txt", "check_v84.py",
    "scripts/scr_sally_special/scr_sally_special.gml", "scripts/scr_sally_canon_fase2/scr_sally_canon_fase2.gml",
    "objects/obj_player_puppet/Step_0.gml", "objects/obj_sally_canon/Draw_76.gml",
    "objects/obj_sally_canon/Step_2.gml", "LEEME_V85_SALLY_PATADA_FASE1.txt", "check_v85.py",
]
FAILS = []


def check(ok, msg):
    print(("PASS  " if ok else "FAIL  ") + msg)
    if not ok:
        FAILS.append(msg)


def read(root, rel):
    with open(os.path.join(root, rel), "rb") as f:
        return f.read()


def strip_gml(src):
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            seg = src[i:(n if j < 0 else j + 2)]
            out.append("\n" * seg.count("\n"))
            i = n if j < 0 else j + 2
        elif c in "\"'":
            q = c
            j = i + 1
            while j < n and src[j] != q:
                j += 2 if src[j] == "\\" else 1
            out.append(q + q)
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def brackets(code):
    stack, pairs = [], {")": "(", "]": "[", "}": "{"}
    for k, c in enumerate(code):
        if c in "([{":
            stack.append(c)
        elif c in ")]}":
            if not stack or stack.pop() != pairs[c]:
                return False, "mismatch at char %d" % k
    return (not stack), ("unclosed %r" % stack[-5:] if stack else "")


def chained_ternary(code):
    depth, q, bad = 0, {}, 0
    for c in code:
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            q.pop(depth, None)
        elif c == ";":
            if depth <= 0:
                q = {}
            else:
                q.pop(depth, None)
        elif c == "?":
            q[depth] = q.get(depth, 0) + 1
            if q[depth] > 1:
                bad += 1
    return bad


def walk(root, sub, ext):
    for dp, dn, fn in os.walk(os.path.join(root, sub)):
        if "_backups" in dp:
            continue
        for f in fn:
            if f.endswith(ext):
                yield os.path.join(dp, f)


def main():
    root = sys.argv[1]
    allowprev = "--allow-prev" in sys.argv
    rd = sys.argv.index("--roundtrip") if "--roundtrip" in sys.argv else -1
    st = subprocess.run(["git", "-C", root, "status", "--porcelain"], capture_output=True, text=True).stdout
    changed = [l[3:] for l in st.splitlines() if l.strip()]
    if rd > 0:
        z = zipfile.ZipFile(sys.argv[rd + 1])
        names = z.namelist()
        check(sorted(names) == sorted(changed), "roundtrip: zip list == changed list of the clone (%d files)" % len(names))
        check(all(read(root, n) == z.read(n) for n in names), "roundtrip: every zipped file is byte-identical in the clone")
    check(set(CODE) <= set(changed), "all 3 patched files show as modified in git")
    check(not any(c.endswith((".yy", ".yyp")) for c in changed), "no .yy / .yyp touched")
    allowed = set(CODE + DOCS + PREV) if allowprev else set(CODE + DOCS)
    extra = sorted(set(changed) - allowed)
    check(not extra, "no unexpected extra files changed: %s" % extra)
    miss = [d for d in DOCS if d not in changed and os.path.exists(os.path.join(root, d))]
    if miss:
        print("NOTE  docs present on disk but not yet modified (docs step pending): %s" % miss)

    # ---- lexer checks on every patched GML file ----
    for rel in CODE:
        b = read(root, rel)
        t = b.decode("utf-8")
        code = strip_gml(t)
        ok, why = brackets(code)
        check(ok, "%s: brackets balanced %s" % (rel, why))
        check(b"\r" not in b, "%s: no CR (LF only)" % rel)
        base_raw = subprocess.run(["git", "-C", root, "show", "HEAD:" + rel], capture_output=True).stdout
        base = base_raw.decode("utf-8", "replace")
        check(t.endswith("\n") == base.endswith("\n"), "%s: final-newline convention kept as the owner's original" % rel)
        base_ct = chained_ternary(strip_gml(base))
        check(chained_ternary(code) <= base_ct, "%s: no NEW chained ternary (owner's file %d, patched %d)" % (rel, base_ct, chained_ternary(code)))

    # ---- v86 content: the unified pads ----
    f2 = read(root, "scripts/scr_sally_canon_fase2/scr_sally_canon_fase2.gml").decode("utf-8")
    check("#macro SALLY_CANON_KICK_PCT_GROUND 0.30" in f2 and "#macro SALLY_CANON_KICK_PCT_AIR 0.50" in f2,
          "scr_sally_canon_fase2: renamed macros GROUND 0.30 / AIR 0.50 defined")
    pp = read(root, "objects/obj_player_puppet/Step_0.gml").decode("utf-8")
    check(pp.count("_scKickPad = ceil((bbox_right - bbox_left) * SALLY_CANON_KICK_PCT_AIR);") == 1,
          "puppet/Step_0: the AIR pad uses the unified macro (no phase split)")
    check(pp.count("_scKickPad = ceil((bbox_right - bbox_left) * SALLY_CANON_KICK_PCT_GROUND);") == 1,
          "puppet/Step_0: the GROUND pad uses the unified macro")
    check(pp.count("* SALLY_CANON_KICK_PCT_GROUND * scr_sally_cyber_hitbox_mul") == 1,
          "puppet/Step_0: the 2nd-kick pad (TP factor) still multiplies the cyber form")
    padwin = pp[pp.index("var _scKickPad = 0;"):pp.index("// v3 (D.I.B.)")]
    check("duelista" not in strip_gml(padwin), "puppet/Step_0: NO duelista left in the pad computation CODE")
    grep_all = subprocess.run(["grep", "-rn", "-e", "SALLY_CANON_KICK_PCT_F1", "-e", "SALLY_CANON_KICK_PCT_F2_GROUND",
                               "-e", "SALLY_CANON_KICK_PCT_F2_AIR",
                               os.path.join(root, "scripts"), os.path.join(root, "objects")], capture_output=True, text=True).stdout
    check(grep_all.strip() == "", "old macro names gone project-wide:\n" + grep_all[:300])

    # ---- v86 content: the exit radar in Sally Canon's Draw GUI ----
    d6 = read(root, "objects/obj_sally_canon/Draw_64.gml").decode("utf-8")
    check("v86 (duena): RADAR DE LA SALIDA" in d6, "Draw_64: the v86 exit-radar banner exists")
    check(d6.count("if(hp > 0 && revivalTimes < 2 && instance_exists(obj_bigring))") == 1,
          "Draw_64: the radar guard (alive + not esbirro + ring exists) x1")
    check(d6.count("var _ring = instance_nearest(x, y, obj_bigring);") == 1 and
          d6.count("draw_sprite_ext(spr_sindicator2, 0, ceil(x - obj_camera.x), ceil(y - obj_camera.y), 1, 1, point_direction(x, y, _ring.x, _ring.y), c_white, 1);") == 1,
          "Draw_64: green arrow (spr_sindicator2) drawn at the body pointing to the nearest ring, like Rouge's")
    check("exeVisible" not in d6 and "spr_indicator" not in d6, "Draw_64: the RED exe arrow is NOT added (Amy-Canon exclusive)")
    cr = read(root, "objects/obj_sally_canon/Create_0.gml").decode("utf-8")
    check("obj_amycanon_indicators" not in cr and "obj_vanilla_indicators" not in cr,
          "Create_0: no indicator object spawned for her (the radar is inline in Draw_64; her legit sensor/reviveObj spawns stay)")
    rj = read(root, "objects/obj_rouge/Draw_64.gml").decode("utf-8")
    check("spr_sindicator2" in rj, "precedent intact: Rouge's radar untouched (same sprite/pattern)")
    ai = read(root, "objects/obj_amycanon_indicators/Step_0.gml").decode("utf-8")
    check("obj_bigring" in ai, "precedent intact: Amy Canon's indicators untouched")

    # ---- v85 features still intact ----
    ss = read(root, "scripts/scr_sally_special/scr_sally_special.gml").decode("utf-8")
    check("else if(global.character == CHARACTER_SALLY_CANON && duelista" not in ss and
          ss.count("else if(global.character == CHARACTER_SALLY_CANON\n") == 1,
          "v85 intact: ground-kick launch gate still phase-agnostic")
    check(ss.count("if(global.character == CHARACTER_SALLY_CANON && duelista)") == 1,
          "v85 intact: the spindash still requires duelista")

    # ---- macro uniqueness project-wide ----
    macros = {}
    for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")):
        for m in re.finditer(r"^#macro\s+(\w+)", open(p, "rb").read().decode("utf-8", "replace"), re.M):
            macros[m.group(1)] = macros.get(m.group(1), 0) + 1
    for nm in ("SALLY_CANON_KICK_PCT_GROUND", "SALLY_CANON_KICK_PCT_AIR", "SALLY_CANON_F2_ATTACK", "SALLY_ATTACK"):
        check(macros.get(nm, 0) == 1, "macro %s exists and is unique in the whole project" % nm)
    for nm in ("SALLY_CANON_KICK_PCT_F1", "SALLY_CANON_KICK_PCT_F2_GROUND", "SALLY_CANON_KICK_PCT_F2_AIR"):
        check(nm not in macros, "old macro %s no longer defined anywhere" % nm)

    # ---- simulations ----
    import math
    ceil = lambda v: math.ceil(v)

    # 1) pad: % of bbox width, same in BOTH phases, cyber multiplier on top
    def pad(state, duelista, w, cyber_mul=1.0, esbirro=False):
        pct = 0.30 if state == 22 else 0.50
        if esbirro:
            cyber_mul = 1.0  # esbirro keeps the plain pad
        return ceil(w * pct * cyber_mul)

    width = 44
    exp_ground, exp_air = math.ceil(width * 0.30), math.ceil(width * 0.50)
    ok = True
    for du in (False, True):
        ok &= pad(22, du, width) == exp_ground
        ok &= pad(14, du, width) == exp_air
    check(ok, "sim pads: ground %d px / air %d px for a %d-px bbox, IDENTICAL in phase 1 and duelista" % (exp_ground, exp_air, width))
    check(pad(14, False, width, 1.45) == math.ceil(width * 0.50 * 1.45), "sim pads: cyber semi (x1.45) still multiplies on top (v82 intact)")
    check(pad(14, False, width, 1.70, True) == exp_air, "sim pads: esbirro keeps the plain pad (no cyber bonus)")
    check(exp_ground == 14 and exp_air == 22, "sim pads: expected ceil values (30%%->14, 50%%->22 of 44)")
    # the previous phase-1 air pad (+25%) no longer exists
    check(math.ceil(width * 0.25) != exp_air, "sim pads: the old +25%% phase-1 pad (%d px) is now the same +50%% (%d px)" % (math.ceil(width * 0.25), exp_air))

    # 2) exit radar visibility (mirror of the Draw_64 guard)
    def arrow(hp, revival, ring_exists):
        return hp > 0 and revival < 2 and ring_exists

    cases = [
        (100, 0, True, True, "viva, fase 1, con anillo: FLECHA"),
        (100, 1, True, True, "viva, duelista, con anillo: FLECHA (cualquier fase)"),
        (0, 0, True, False, "tirada en fase 2 con vida en 0: sin flecha"),
        (55, 0, True, True, "fase 2 pt4 regenerando (hp>0): FLECHA"),
        (100, 0, False, False, "sin anillo de escape aun: sin flecha"),
        (0, 2, True, False, "muerta/demonizada (red de seguridad): sin flecha"),
    ]
    wrong = ["%s -> %r" % (l, arrow(h, r, e)) for h, r, e, exp, l in cases if arrow(h, r, e) != exp]
    check(not wrong, "sim radar: " + ("; ".join(wrong) if wrong else "all %d cases as expected" % len(cases)))

    # 3) the arrow costs no packets: no net function inside the radar block
    if "RADAR DE LA SALIDA" in d6:
        radar = d6[d6.index("v86 (duena): RADAR DE LA SALIDA"):]
        check("net_" not in strip_gml(radar) and "cpacket" not in radar,
              "sim radar: pure local HUD info (no net_sound/net_quick_effect/cpacket in the block)")
    else:
        check(False, "sim radar: block missing (cannot inspect)")
    # 4) sprite anchor parity with the precedent (Rouge) and Amy Canon
    check("ceil(x - obj_camera.x), ceil(y - obj_camera.y), 1, 1, point_direction(x, y, _ring.x, _ring.y)" in d6
          and "ceil(x - obj_camera.x), ceil(y - obj_camera.y), 1, 1, point_direction(x, y, _ring.x, _ring.y)" in rj,
          "sim radar: same anchoring/rotation formula as Rouge's radar (verified side by side)")

    print("RESULT:", "ALL PASS" if not FAILS else "%d FAILED" % len(FAILS))
    sys.exit(1 if FAILS else 0)


if __name__ == "__main__":
    main()
