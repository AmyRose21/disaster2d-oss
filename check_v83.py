#!/usr/bin/env python3
"""v83 verification (no GameMaker here): lexer checks, symbol existence, numeric simulation.

Usage: python3 -I check_v83.py <repo_root> [--roundtrip <zip>]
Exit code 0 only if every check passes.  Read-only.
"""
import json
import os
import re
import subprocess
import sys
import zipfile

CODE = [
    "scripts/net_udpprocess/net_udpprocess.gml",
    "scripts/scr_chocola/scr_chocola.gml",
    "objects/obj_chocola/Create_0.gml",
    "objects/obj_chocola/Step_0.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    "scripts/scr_amy_canon_bubble/scr_amy_canon_bubble.gml",
    "objects/obj_amy_canon/Draw_76.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/scr_parry/scr_parry.gml",
    "betterserver-oss/disasterserver/states/Game.c",
]
DOCS = ["CACHE.md", "LEARNING.md", "worklog.md", "LEEME_V83_VANILLA_AMY_CANON.txt", "check_v83.py"]
FAILS = []


def check(ok, msg):
    print(("PASS  " if ok else "FAIL  ") + msg)
    if not ok:
        FAILS.append(msg)


def read(root, rel):
    return open(os.path.join(root, rel), "rb").read()


def strip_gml(src):
    """Remove // and /* */ comments and string literals, keeping newlines."""
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
    rd = sys.argv.index("--roundtrip") if "--roundtrip" in sys.argv else -1
    st = subprocess.run(["git", "-C", root, "status", "--porcelain"], capture_output=True, text=True).stdout
    changed = [l[3:] for l in st.splitlines() if l.strip()]
    if rd > 0:
        z = zipfile.ZipFile(sys.argv[rd + 1])
        names = [n for n in z.namelist()]
        check(sorted(names) == sorted(changed), "roundtrip: zip list == changed list of the clone (%d files)" % len(names))
        check(all(read(root, n) == z.read(n) for n in names), "roundtrip: every zipped file is byte-identical in the clone")
    check(set(CODE) <= set(changed), "all 10 patched files show as modified in git")
    check(not any(c.endswith((".yy", ".yyp")) for c in changed), "no .yy / .yyp touched")
    check(set(changed) <= set(CODE + DOCS), "changed files are only the expected ones: %s" % sorted(set(changed) - set(CODE + DOCS)))

    for rel in CODE[:-1]:
        b = read(root, rel)
        t = b.decode("utf-8")
        code = strip_gml(t)
        ok, why = brackets(code)
        check(ok, "%s: brackets balanced %s" % (rel, why))
        print(("PASS  " if b"\r" not in b else "NOTE  ") + "%s: no CR (LF only)" % rel)
        print(("PASS  " if t.endswith("\n") else "NOTE  ") + "%s: ends with newline" % rel)
        base_ct = chained_ternary(strip_gml(subprocess.run(["git", "-C", root, "show", "HEAD:" + rel], capture_output=True).stdout.decode("utf-8", "replace")))
        check(chained_ternary(code) <= base_ct, "%s: no NEW chained ternary (owner's file %d, patched %d)" % (rel, base_ct, chained_ternary(code)))
        check("<<V83" not in t and "TODO83" not in t, "%s: no leftover marker" % rel)

    csrc = read(root, CODE[-1]).decode("utf-8")
    ok, why = brackets(strip_gml(csrc))
    check(ok, "Game.c: brackets/parens balanced %s" % why)
    h0 = csrc.find("/* v83 ANTI-CHEAT - SENALES")
    h1 = csrc.find("return true;", h0)
    check(0 < h0 < h1 and csrc.rfind("\n", 0, h0) + 1 == h0 and csrc.count("v83 ANTI-CHEAT") == 3,
          "Game.c: v83 helper block starts at column 0 and the 3 v83 blocks are present")

    # ---- symbol existence / uniqueness
    scr = read(root, "scripts/scr_chocola/scr_chocola.gml").decode("utf-8")
    check(len(re.findall(r"^function scr_chocola_target_lost\(\)", scr, re.M)) == 1, "scr_chocola_target_lost defined once")
    check(len(re.findall(r"^#macro CHOCOLA_TARGET_LOST_FRAMES 60", scr, re.M)) == 1, "CHOCOLA_TARGET_LOST_FRAMES defined once (file)")
    step = read(root, "objects/obj_chocola/Step_0.gml").decode("utf-8")
    check(step.count("|| scr_chocola_target_lost()") == 2, "obj_chocola/Step_0: scr_chocola_target_lost used in 2 aborts")
    check("targetLostTimer = 0;" in read(root, "objects/obj_chocola/Create_0.gml").decode("utf-8"), "obj_chocola/Create_0: targetLostTimer declared")
    macros = {}
    for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")):
        for m in re.finditer(r"^#macro\s+(\w+)", open(p, "rb").read().decode("utf-8", "replace"), re.M):
            macros[m.group(1)] = macros.get(m.group(1), 0) + 1
    check(macros.get("CHOCOLA_TARGET_LOST_FRAMES") == 1, "macro CHOCOLA_TARGET_LOST_FRAMES unique in the whole project")
    for nm in ("CHOCOLA_FOLLOW", "CHOCOLA_GO_CREAM", "CHOCOLA_GUARD", "VANILLA_CHOCOLA_CD"):
        check(macros.get(nm, 0) == 1, "macro %s exists and is unique" % nm)
    ac = read(root, "objects/obj_amy_canon/Create_0.gml").decode("utf-8")
    check("superFormPhase" in ac and "hammerThrowTimer" in ac and macros.get("AMY_SUPER_HTHROW_RECHARGE", 0) == 1,
          "obj_amy_canon/Create_0: superFormPhase / hammerThrowTimer declared; macro AMY_SUPER_HTHROW_RECHARGE unique")
    va = read(root, "objects/obj_vanilla/Create_0.gml").decode("utf-8")
    check("chocolaCd" in (va + scr), "chocolaCd declared (obj_vanilla/Create_0 or scr_chocola)")
    allgml = "".join(open(p, "rb").read().decode("utf-8", "replace") for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")))
    check("global.KeyV" in allgml.replace(open(os.path.join(root, "objects/obj_playerui/Draw_64.gml"), "rb").read().decode("utf-8", "replace"), ""),
          "global.KeyV exists in the project outside the patched HUD file")
    check(os.path.isdir(os.path.join(root, "objects/obj_chocola")), "asset obj_chocola exists")
    sp = os.path.join(root, "sprites", "spr_vanilla_chocola_Idle")
    yy = re.sub(r",(\s*[}\]])", r"\1", re.sub(r"//[^\n]*", "", open(os.path.join(sp, "spr_vanilla_chocola_Idle.yy"), encoding="utf-8").read()))
    frames = [f["name"] for f in json.loads(yy)["frames"]]
    check(len(frames) == 5, "spr_vanilla_chocola_Idle has 5 frames")
    try:
        from PIL import Image
        outside = []
        for fi, f in enumerate(frames):
            im = Image.open(os.path.join(sp, f + ".png")).convert("RGBA")
            w, h = im.size
            px = im.load()
            for y in range(h):
                for x in range(w):
                    if px[x, y][3] > 8 and not (2 <= x < 17 and 1 <= y < 24):
                        outside.append((fi, x, y))
        check(not outside, "HUD crop (3,2,13x21) contains all ink of the 5 frames; outside=%s" % outside[:6])
        print("      sprite size", im.size)
    except Exception as e:  # noqa
        check(False, "sprite crop measurement: %s" % e)
    hud = read(root, "objects/obj_playerui/Draw_64.gml").decode("utf-8")
    for v in ("_acThrow", "_acNoC", "_acCd", "_vChoc", "_vCol", "_vFill", "_vSlide", "_vFrame"):
        check(len(re.findall(r"\b%s\b" % v, hud)) >= 2 and len(re.findall(r"\bvar %s\b" % v, hud)) == 1, "HUD var %s declared once, used" % v)
    for fn in ("scr_chocola_get", "scr_text_spr", "scr_controls_keycode_to_key", "scr_esbirro_hud"):
        hits = [p for p in walk(root, "scripts", ".gml") if re.search(r"^function %s\(" % fn, open(p, "rb").read().decode("utf-8", "replace"), re.M)]
        check(len(hits) == 1, "function %s defined once (%s)" % (fn, os.path.basename(hits[0]) if hits else "-"))
    ph = read(root, "scripts/scr_player_hurt/scr_player_hurt.gml").decode("utf-8")
    check(ph.count("hammerThrowTimer = (hammerThrowTimer <= 0) ? _t : hammerThrowTimer + _t;") == 1, "weak mark: hammerThrowTimer line x1")
    check(ph.count('if(character == CHARACTER_VANILLA && variable_instance_exists(id, "chocolaCd"))') == 1, "weak mark: chocolaCd guard x1")
    parry = read(root, "scripts/scr_parry/scr_parry.gml").decode("utf-8")
    check(parry.count("net_sound_emit_at(snd_parry, ") == 2 and "net_sound_emit_at(Perfect_Parry" not in parry, "parry ting sent as snd_parry x2")
    ns = open(os.path.join(root, "scripts/net_sounds/net_sounds.gml"), encoding="utf-8").read()
    names = [s.strip() for s in re.sub(r"//[^\n]*", "", re.search(r"global\.net_snds\s*=\s*\[(.*?)\];", ns, re.S).group(1)).split(",") if s.strip()]
    idx = {n: i for i, n in enumerate(names)}
    want = {"snd_none": 0, "snd_dash": 1, "snd_exe_stun": 12, "snd_nono": 109, "snd_vasebreak": 110, "snd_metal_stun": 118, "snd_parry": 107, "snd_ringlose": 6, "snd_hurt": 9}
    check(all(idx.get(k) == v for k, v in want.items()), "net_snds real indices %s" % want)
    check("Perfect_Parry" not in names, "Perfect_Parry is NOT in net_snds (the bug)")
    for c in ("static bool game_is_stun_signal(uint8_t sndidx)", "static bool game_stun_signal_ok(PeerData* v, uint16_t nid, uint8_t sndidx)",
              "if (nid != v->id && game_is_stun_signal(sndidx) && !game_stun_signal_ok(v, nid, sndidx))",
              "if (red_ring == 2 && (v->surv_char != CH_VANILLA || !(v->plr.flags & PLAYER_NEGATIZED)))",
              "if (red_ring == 1 && !(v->plr.flags & PLAYER_DEMONIZED))"):
        check(csrc.count(c) == 1, "Game.c contains x1: %s" % c[:60])
    for sym in ("PLAYER_NEGATIZED", "PLAYER_DEMONIZED", "CH_AMY_CANON"):
        hdr = "".join(open(os.path.join(root, "betterserver-oss/include", h), encoding="utf-8", errors="replace").read() for h in os.listdir(os.path.join(root, "betterserver-oss/include")) if h.endswith(".h"))
        check(sym in hdr, "server header defines %s" % sym)

    # ---- simulations (Python mirror of the patched logic)
    bad = []
    timer, fired = 0, []
    for f in range(1, 200):
        inactive = f <= 75 or f > 100
        if not inactive:
            timer = 0
            continue
        timer += 1
        if timer >= 60:
            fired.append(f)
            timer = 0
    check(fired == [60, 160], "sim Chocola lost-target: fires at frame 60 of silence, resets, fires again 60 later -> %s" % fired)
    okh = True
    for phase in (0, 1, 2):
        for grounded in (False, True):
            for d in range(0, 601, 7):
                for ht in range(0, 301, 11):
                    throw = phase >= 2 and grounded
                    cd, val = (ht, 300) if throw else (d, 600)
                    prog = 1.0 - max(cd, 0) / val
                    white = (prog == 1.0 and not (phase == 1 and grounded))
                    if not (0.0 <= prog <= 1.0):
                        okh = False
                    if phase == 0 and not grounded and d == 0 and not white:
                        okh = False       # LSA ready in the air must be white (the reported bug)
                    if phase == 2 and grounded and d == 0 and ht == 200 and white:
                        okh = False       # throw cooling must be red
    check(okh, "sim HUD Amy icon 3: progress in 0..1, LSA ready in air = white, throw cooling = red")
    okv = all(0.35 <= min(1.0, max(0.35, 1.0 - max(c, 0) / 150.0)) <= 1.0 for c in range(-5, 200))
    check(okv, "sim HUD Vanilla icon V: fill stays in 0.35..1 for chocolaCd -5..199")

    def server(sender_char, sender_demon, sender_is_exe, tgt_in_game, tgt_demon, tgt_is_exe, snd):
        if snd not in (0, 1, 12, 109, 110, 118) or sender_is_exe:
            return "relay"
        if not tgt_in_game or not (tgt_is_exe or tgt_demon):
            return "drop"
        if sender_is_exe or sender_demon:
            return "drop"
        if snd in (0, 1) and sender_char != "AMY_CANON":
            return "drop"
        return "relay"
    exp = [
        (server("SONIC", False, False, True, False, True, 0), "drop", "hacked Sonic sends hammer stun to the EXE"),
        (server("AMY_CANON", False, False, True, False, True, 0), "relay", "real Amy Canon hammer stun"),
        (server("AMY_CANON", True, False, True, False, True, 1), "drop", "demonized Amy cannot LSA"),
        (server("KNUX", False, False, True, False, False, 12), "drop", "stun signal aimed at a survivor"),
        (server("KNUX", False, False, True, True, False, 12), "relay", "parry stun of the victim's client on a demonized attacker"),
        (server("VANILLA", False, False, True, False, True, 109), "relay", "Chocola paciencia stun"),
        (server("EXE", False, True, True, False, False, 120), "relay", "exe kill voice (not a stun signal) untouched"),
        (server("AMY_CANON", False, False, False, False, True, 1), "drop", "target left the game"),
    ]
    wrong = ["%s -> %s" % (c, a) for a, b, c in exp if a != b]
    check(not wrong, "sim server stun-signal rule table: " + ("; ".join(wrong) if wrong else "all %d cases as expected" % len(exp)))
    print("      " + " | ".join("%s:%s" % (c[:28], a) for a, b, c in exp))

    def rings(char, nega, demon, byte):
        if char == "AMY_CANON":
            return "1 ring"
        if byte == 2 and (char != "VANILLA" or not nega):
            return "drop"
        if byte == 1 and not demon:
            return "drop"
        return "spawn"
    rexp = [("VANILLA", True, True, 2, "spawn"), ("VANILLA", False, False, 2, "drop"), ("CREAM", False, True, 1, "spawn"),
            ("CREAM", False, False, 1, "drop"), ("CREAM", False, False, 0, "spawn"), ("VANILLA", False, False, 0, "spawn"), ("ROUGE", False, False, 0, "spawn")]
    check(all(rings(*x[:4]) == x[4] for x in rexp), "sim server ring-type guard: %s" % "; ".join("%s/%d:%s" % (x[0], x[3], rings(*x[:4])) for x in rexp))
    print("RESULT:", "ALL PASS" if not FAILS else "%d FAILED" % len(FAILS))
    sys.exit(1 if FAILS else 0)


if __name__ == "__main__":
    main()
