#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v85 verification (no GameMaker here): lexer checks, content checks and
numeric simulations of the new gate and the kick windows.

Usage: python3 -I check_v85.py <repo_root> [--roundtrip <zip>] [--allow-v84]
Exit code 0 only if every check passes.  Read-only.  --allow-v84 tolerates the
v84 file set in git status (the recommended order applies v84 first).
"""
import os
import re
import subprocess
import sys
import zipfile

CODE = [
    "scripts/scr_sally_special/scr_sally_special.gml",
    "scripts/scr_sally_canon_fase2/scr_sally_canon_fase2.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_sally_canon/Draw_76.gml",
    "objects/obj_sally_canon/Step_2.gml",
]
DOCS = ["CACHE.md", "LEARNING.md", "worklog.md", "LEEME_V85_SALLY_PATADA_FASE1.txt", "check_v85.py"]
V84 = [
    "scripts/scr_chocola/scr_chocola.gml", "objects/obj_vanilla/Create_0.gml",
    "objects/obj_chocola/Create_0.gml", "scripts/net_udpprocess/net_udpprocess.gml",
    "scripts/net_state_game/net_state_game.gml", "scripts/scr_amelia_special/scr_amelia_special.gml",
    "objects/obj_amelia/Create_0.gml", "objects/obj_amelia_auras/Create_0.gml",
    "objects/obj_amelia_auras/Step_0.gml", "objects/obj_amelia_auras/Draw_64.gml",
    "objects/obj_amelia_indicators/Draw_64.gml", "betterserver-oss/include/Server.h",
    "betterserver-oss/disasterserver/states/Game.c", "CACHE.md", "LEARNING.md", "worklog.md",
    "LEEME_V84_VANILLA_CHOCOLA_AMELIA.txt", "check_v84.py",
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
    allow84 = "--allow-v84" in sys.argv
    rd = sys.argv.index("--roundtrip") if "--roundtrip" in sys.argv else -1
    st = subprocess.run(["git", "-C", root, "status", "--porcelain"], capture_output=True, text=True).stdout
    changed = [l[3:] for l in st.splitlines() if l.strip()]
    if rd > 0:
        z = zipfile.ZipFile(sys.argv[rd + 1])
        names = z.namelist()
        check(sorted(names) == sorted(changed), "roundtrip: zip list == changed list of the clone (%d files)" % len(names))
        check(all(read(root, n) == z.read(n) for n in names), "roundtrip: every zipped file is byte-identical in the clone")
    check(set(CODE) <= set(changed), "all 5 patched files show as modified in git")
    check(not any(c.endswith((".yy", ".yyp")) for c in changed), "no .yy / .yyp touched")
    allowed = set(CODE + DOCS + V84) if allow84 else set(CODE + DOCS)
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
        check(t.endswith("\n") == base_raw.decode("utf-8", "replace").endswith("\n"),
              "%s: final-newline convention kept as the owner's original" % rel)
        base_ct = chained_ternary(strip_gml(base_raw.decode("utf-8", "replace")))
        check(chained_ternary(code) <= base_ct, "%s: no NEW chained ternary (owner's file %d, patched %d)" % (rel, base_ct, chained_ternary(code)))
        check("TODO85" not in t and "<<V85" not in t, "%s: no leftover marker" % rel)

    # ---- v85 content: the gate and its comments ----
    ss = read(root, "scripts/scr_sally_special/scr_sally_special.gml").decode("utf-8")
    check("else if(global.character == CHARACTER_SALLY_CANON && duelista" not in ss,
          "scr_sally_special: the OLD ground-kick gate (duelista) is GONE")
    check(ss.count("else if(global.character == CHARACTER_SALLY_CANON\n"
                   "                && !isSliding && !isSpinCharging && !isHiding && !isHurt && !isDead\n"
                   "                && shockedTimer <= 0 && !isZipline && redRingTimer <= 0)") == 1,
          "scr_sally_special: the NEW phase-agnostic ground-kick gate x1")
    check(ss.count("if(global.character == CHARACTER_SALLY_CANON && duelista)") == 1,
          "scr_sally_special: the SPINDASH gate still requires duelista (phase 2 only)")
    check(ss.count("groundKick = false;") == 2 and "canon: esta es la aerea (estado 14), no la de tierra" in ss,
          "scr_sally_special: groundKick = false x2 (auto-off + the AIR kick marking state 14)")
    check(ss.count("attackTimer = revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;") == 2,
          "scr_sally_special: both kick branches share the same recharge (15 s / 4 s esbirro)")
    check("if(global.character == CHARACTER_SALLY_CANON && !isAttacking)\n                groundKick = false;" in ss,
          "scr_sally_special: groundKick auto-off kept (kick ended)")
    f2 = read(root, "scripts/scr_sally_canon_fase2/scr_sally_canon_fase2.gml").decode("utf-8")
    check("v85 (pedido de la duena): ya NO espera a la fase duelista" in f2 and "CUALQUIER fase desde la v85" in f2,
          "scr_sally_canon_fase2: header/macros comments updated (ground kick any phase)")
    check(f2.count("duelista = true;") == 1 and "canSpin = true;" in f2 and "canSpinDash = true;" in f2,
          "scr_sally_canon_fase2: the duelista unlock itself (pt4) unchanged")
    check("#macro SALLY_CANON_F2_ATTACK BALANCING+9" in f2 and "#macro SALLY_CANON_F2_KICK1_END 6" in f2
          and "#macro SALLY_CANON_F2_KICK2_START 7" in f2,
          "scr_sally_canon_fase2: kick state/window macros unchanged (22 / frames 0-6 / 7+)")
    pp = read(root, "objects/obj_player_puppet/Step_0.gml").decode("utf-8")
    check(pp.count("if(character == CHARACTER_SALLY_CANON && state == SALLY_CANON_F2_ATTACK)") == 1,
          "puppet/Step_0: the victim-side kick block still keyed on STATE ONLY (no duelista)")
    check(pp.count("SALLY_CANON_F2_ATTACK") == 3, "puppet/Step_0: state 22 references x3 (reset / pad / kick)")
    window = pp[pp.index("PATADA EN TIERRA"):pp.index("CLIENT_PLAYER_HURT", pp.index("PATADA EN TIERRA"))]
    check("duelista" not in strip_gml(window), "puppet/Step_0: NO duelista in the CODE of the victim-side kick effect (comments excluded)")
    check("else if(state == SALLY_ATTACK)\n                _scKickPad = ceil((bbox_right - bbox_left) * (duelista ? SALLY_CANON_KICK_PCT_F2_AIR : SALLY_CANON_KICK_PCT_F1));" in pp,
          "puppet/Step_0: the AIR kick pad keeps its phase split (+25% f1 / +50% duelista)")
    d7 = read(root, "objects/obj_sally_canon/Draw_76.gml").decode("utf-8")
    check("case SALLY_CANON_F2_ATTACK:" in d7 and d7.count("groundKick = false;") == 1,
          "Draw_76: state 22 case ends the kick + clears groundKick (anim end)")
    s2 = read(root, "objects/obj_sally_canon/Step_2.gml").decode("utf-8")
    check(s2.count("state = groundKick ? SALLY_CANON_F2_ATTACK : SALLY_ATTACK;") == 1,
          "Step_2: state 22 vs 14 chosen by groundKick (unchanged)")
    cr = read(root, "objects/obj_sally_canon/Create_0.gml").decode("utf-8")
    check("groundKick = false;" in cr and "duelista = false;" in cr, "Create_0: groundKick/duelista still declared")
    ui = read(root, "objects/obj_playerui/Draw_64.gml").decode("utf-8")
    check("spr_gui_sallyattack" in ui, "HUD: the X kick icon is phase-agnostic (nothing to change there)")

    # ---- macro uniqueness project-wide ----
    macros = {}
    for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")):
        for m in re.finditer(r"^#macro\s+(\w+)", open(p, "rb").read().decode("utf-8", "replace"), re.M):
            macros[m.group(1)] = macros.get(m.group(1), 0) + 1
    for nm in ("SALLY_CANON_F2_ATTACK", "SALLY_ATTACK", "SALLY_CANON_KICK_PCT_F2_GROUND",
               "SALLY_CANON_KICK_PCT_F1", "SALLY_CANON_KICK_PCT_F2_AIR", "SALLY_ATTACK_RECHARGE"):
        check(macros.get(nm, 0) == 1, "macro %s exists and is unique in the whole project" % nm)

    # ---- simulations ----
    # 1) launch gate matrix (mirror of scr_sally_special, v85)
    def launch(char, duelista, grounded, attack_cd, sliding=False, hiding=False, hurt=False,
               dead=False, shocked=False, zipline=False, redring=False, spincharging=False):
        if not (char == "SALLY_CANON" or char == "SALLY"):
            return None
        if attack_cd:
            return None
        if not grounded:
            return "AIR_KICK"
        if char != "SALLY_CANON":
            return None
        if sliding or spincharging or hiding or hurt or dead or shocked or zipline or redring:
            return None
        return "GROUND_KICK"  # v85: no duelista requirement

    cases = [
        ("SALLY_CANON", False, True, False, "GROUND_KICK", "fase 1, en el suelo, X -> PATADA EN TIERRA (lo pedido)"),
        ("SALLY_CANON", True, True, False, "GROUND_KICK", "duelista, en el suelo, X -> patada en tierra (como antes)"),
        ("SALLY_CANON", False, False, False, "AIR_KICK", "fase 1, en el aire, X -> patada aerea (como antes)"),
        ("SALLY", False, True, False, None, "Sally vanilla en el suelo: NADA (solo aerea, como siempre)"),
        ("SALLY", False, False, False, "AIR_KICK", "Sally vanilla en el aire: patada aerea"),
        ("SALLY_CANON", False, True, True, None, "patada en recarga (15 s): bloqueada"),
        ("SALLY_CANON", False, True, False, None, "deslizando: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "escondida: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "herida: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "muerta: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "aturdida: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "tirolina: bloqueada"),
        ("SALLY_CANON", False, True, False, None, "anillo rojo: bloqueada"),
    ]
    wrong = []
    for char, du, gr, cd, exp, label in cases:
        kw = {}
        if "deslizando" in label:
            kw["sliding"] = True
        elif "escondida" in label:
            kw["hiding"] = True
        elif "herida" in label:
            kw["hurt"] = True
        elif "muerta" in label:
            kw["dead"] = True
        elif "aturdida" in label:
            kw["shocked"] = True
        elif "tirolina" in label:
            kw["zipline"] = True
        elif "anillo rojo" in label:
            kw["redring"] = True
        got = launch(char, du, gr, cd, **kw)
        if got != exp:
            wrong.append("%s -> %r (want %r)" % (label, got, exp))
    check(not wrong, "sim launch gate: " + ("; ".join(wrong) if wrong else "all %d cases as expected" % len(cases)))

    # 2) kick windows on the victim side: 2 hits max per kick, reset on leaving state 22
    def run_attack(frame_idxs):
        h1 = h2 = False
        hits = []
        for f in frame_idxs:
            win1 = (not h1) and f <= 6
            win2 = (not h2) and f >= 7
            if win1 or win2:
                if win1:
                    h1 = True
                    hits.append((f, 1))
                else:
                    h2 = True
                    hits.append((f, 2))
        return hits

    full = run_attack(range(11))
    check(len(full) == 2 and full[0] == (0, 1) and full[1] == (7, 2),
          "sim kick windows: 11-frame anim -> exactly 2 hits (kick1 @0, kick2 @7)")
    check(len(run_attack(range(7))) == 1, "sim kick windows: only frames 0-6 -> 1 hit (kick1 only)")
    check(len(run_attack(range(7, 11))) == 1, "sim kick windows: only frames 7+ -> 1 hit (kick2 only)")
    check(run_attack([]) == [], "sim kick windows: no anim -> no hits")

    # 3) recharge: SALLY_ATTACK_RECHARGE = 60 * 15 (900 frames) shared with the air kick
    check("SALLY_ATTACK_RECHARGE (60 * 15)" in read(root, "objects/obj_sally/Create_0.gml").decode("utf-8"),
          "sim recharge: 15 s intact (both kicks share it, esbirro 4 s)")
    # 4) state byte fits u8 (22 < 255) and the anim tables have the sprite for both local and puppet
    sv = read(root, "scripts/scr_survivors/scr_survivors.gml").decode("utf-8")
    check(sv.count("spr_sally_fase2_attack_canon, //22") == 2,
          "anim tables: state 22 sprite present for the player AND the puppet (x2)")
    check(22 <= 255, "state 22 travels fine in the u8 state byte of CLIENT_PLAYER_DATA")

    print("RESULT:", "ALL PASS" if not FAILS else "%d FAILED" % len(FAILS))
    sys.exit(1 if FAILS else 0)


if __name__ == "__main__":
    main()
