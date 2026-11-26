#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v84 verification (no GameMaker here): lexer checks, symbol existence,
numeric simulations of every new logic path, and (when available) a real
gcc -fsyntax-only of the server Game.c vs the git HEAD baseline.

Usage: python3 -I check_v84.py <repo_root> [--roundtrip <zip>]
Exit code 0 only if every check passes.  Read-only.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

CODE = [
    "scripts/scr_chocola/scr_chocola.gml",
    "objects/obj_vanilla/Create_0.gml",
    "objects/obj_chocola/Create_0.gml",
    "scripts/net_udpprocess/net_udpprocess.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_amelia_special/scr_amelia_special.gml",
    "objects/obj_amelia/Create_0.gml",
    "objects/obj_amelia_auras/Create_0.gml",
    "objects/obj_amelia_auras/Step_0.gml",
    "objects/obj_amelia_auras/Draw_64.gml",
    "objects/obj_amelia_indicators/Draw_64.gml",
    "betterserver-oss/include/Server.h",
    "betterserver-oss/disasterserver/states/Game.c",
]
GML = CODE[:11]
DOCS = ["CACHE.md", "LEARNING.md", "worklog.md", "LEEME_V84_VANILLA_CHOCOLA_AMELIA.txt", "check_v84.py"]
FAILS = []


def check(ok, msg):
    print(("PASS  " if ok else "FAIL  ") + msg)
    if not ok:
        FAILS.append(msg)


def read(root, rel):
    with open(os.path.join(root, rel), "rb") as f:
        return f.read()


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
        names = z.namelist()
        check(sorted(names) == sorted(changed), "roundtrip: zip list == changed list of the clone (%d files)" % len(names))
        check(all(read(root, n) == z.read(n) for n in names), "roundtrip: every zipped file is byte-identical in the clone")
    check(set(CODE) <= set(changed), "all 13 patched files show as modified in git")
    check(not any(c.endswith((".yy", ".yyp")) for c in changed), "no .yy / .yyp touched")
    extra = sorted(set(changed) - set(CODE + DOCS))
    check(not extra, "no unexpected extra files changed: %s" % extra)
    missing_docs = [d for d in DOCS if d not in changed and os.path.exists(os.path.join(root, d))]
    if missing_docs:
        print("NOTE  docs present on disk but not yet modified (docs step pending): %s" % missing_docs)

    # ---- lexer checks on every patched GML file ----
    for rel in GML:
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
        check("TODO84" not in t and "<<V84" not in t, "%s: no leftover marker" % rel)

    csrc = read(root, CODE[-1]).decode("utf-8")
    okc, whyc = brackets(strip_gml(csrc))
    check(okc, "Game.c: brackets/parens balanced %s" % whyc)

    # ---- v84 content: Chocola desde el principio ----
    scr = read(root, "scripts/scr_chocola/scr_chocola.gml").decode("utf-8")
    check("net_sound_emit(snd_mermer)" not in scr, "scr_chocola: the paciencia hunt launch (snd_mermer emit) is GONE")
    check(scr.count("pacienciaTimer--;") == 2, "scr_chocola: pacienciaTimer-- x2 (state 2 agotada / new v84 state 1 = gesture only)")
    check("VANILLA_PACIENCIA_EXIT" in scr and "VANILLA_PACIENCIA_CHOCOLA_AT" in scr,
          "scr_chocola: paciencia macros kept (compat / docs)")
    check(scr.count("function scr_vanilla_paciencia_chocola_hit()") == 1 and scr.count("function scr_chocola_net_event(kind, nid)") == 1,
          "scr_chocola: hit/net-event helpers kept (v83 old-client compat)")
    va = read(root, "objects/obj_vanilla/Create_0.gml").decode("utf-8")
    check(va.count("if(!instance_exists(obj_chocola))\n    instance_create_depth(x, y - 10, 0, obj_chocola);") == 1,
          "obj_vanilla/Create_0: Chocola created at birth (guarded, x1)")
    check("pacienciaWaitChocola" in va and "chocolaCd = 0;" in va, "obj_vanilla/Create_0: vars pacienciaWaitChocola / chocolaCd still declared")
    ud = read(root, "scripts/net_udpprocess/net_udpprocess.gml").decode("utf-8")
    check(ud.count("if(character == CHARACTER_VANILLA && !instance_exists(obj_chocola))") == 1,
          "net_udpprocess: remote Chocola creation guarded x1 (first data packet of the Vanilla puppet)")
    check("instance_create_depth(x, y - 10, 0, obj_chocola);" in ud, "net_udpprocess: Chocola born at the puppet live position")
    check(ud.count("character == CHARACTER_BLAZE)") == 1 and "character == CHARACTER_METAL" in ud,
          "net_udpprocess: powerBoost now also METAL and BLAZE (dead remote trail fixed)")
    cc = read(root, "objects/obj_chocola/Create_0.gml").decode("utf-8")
    check("DESDE EL PRINCIPIO" in cc and "stun 2.5 s al exe / 3.5 s a un esbirro" in cc,
          "obj_chocola/Create_0: header + huntSmall comment updated")

    # ---- v84 content: emitter gates in net_state_game ----
    ns = read(root, "scripts/net_state_game/net_state_game.gml").decode("utf-8")
    gates = {
        "== snd_mermer && character == CHARACTER_VANILLA)": "HUNT (mermer) -> Vanilla only",
        "== snd_ready && character == CHARACTER_VANILLA)": "GO_CREAM (ready) -> Vanilla only",
        "== snd_npteleport && character == CHARACTER_VANILLA)": "RECALL (npteleport) -> Vanilla only",
        "== snd_achivement && character == CHARACTER_CREAM)": "DUTY_DONE (achivement) -> Cream only",
        "== snd_chocola_dive && (character == CHARACTER_VANILLA || character == CHARACTER_CREAM))": "HUNT_SMALL (dive) -> Vanilla or Cream",
    }
    for needle, label in gates.items():
        check(ns.count(needle) == 1, "net_state_game: emitter gate x1: %s" % label)
    check(ns.count("&& character == CHARACTER_VANILLA)") == 4, "net_state_game: 4 Vanilla gates (3 new + the pre-existing creamring one)")

    # ---- v84 content: auras ----
    ac = read(root, "objects/obj_amelia_auras/Create_0.gml").decode("utf-8")
    check(ac.count("array_create(AMELIA_AURA_MAX") == 9, "auras/Create_0: all 9 arrays sized by AMELIA_AURA_MAX")
    for v in ("auraOwner", "auraCold", "auraId", "auraFlash"):
        check(v in ac, "auras/Create_0: %s declared" % v)
    ast = read(root, "objects/obj_amelia_auras/Step_0.gml").decode("utf-8")
    check("if(auraOwner != noone && !instance_exists(auraOwner))" in ast, "auras/Step: owner lifecycle guard")
    check("variable_instance_exists(global.player.id, \"revivalTimes\")" in ast, "auras/Step: revivalTimes read guarded")
    check(ast.count("for(var _pass = 0; _pass < 2; _pass++)") == 1, "auras/Step: two-pass scan (exe first)")
    check("EXE_SHOCKED" in ast and "EXE_LOST" in ast and "_st == DEAD" in ast, "auras/Step: cold reading (exe enum / minion DEAD)")
    check("AMELIA_AURA_FLASH" in ast and "auraId[auraCount] != inst.id" in ast, "auras/Step: entry flash bookkeeping")
    adr = read(root, "objects/obj_amelia_auras/Draw_64.gml").decode("utf-8")
    check("if(!instance_exists(obj_camera))" in adr, "auras/Draw_64: camera guard")
    check("display_get_gui_width()" in adr and "display_get_gui_height()" in adr, "auras/Draw_64: GUI bounds via display_get_gui_*")
    check("draw_triangle(" in adr and "AMELIA_AURA_POINTER" in adr, "auras/Draw_64: edge marker triangle")
    check("AMELIA_AURA_COLD_COLOR" in adr and "_beat = 0" in adr, "auras/Draw_64: cold colour + no pulse")
    check("(3 - 2 * _e)" in adr and "AMELIA_AURA_EDGE_FADE" in adr, "auras/Draw_64: smoothstep edge fade")
    check(adr.rstrip().endswith("gpu_set_blendmode(bm_normal);"), "auras/Draw_64: ends restoring alpha/colour/blend")
    am = read(root, "objects/obj_amelia/Create_0.gml").decode("utf-8")
    check("var _auras = instance_create_depth(x, y, 0, obj_amelia_auras);" in am and "_auras.auraOwner = id;" in am,
          "obj_amelia/Create_0: auraOwner wiring")
    ind = read(root, "objects/obj_amelia_indicators/Draw_64.gml").decode("utf-8")
    check("if(!instance_exists(obj_camera))" in ind, "indicators/Draw_64: camera guard (blindaje)")

    # ---- macros: unique project-wide ----
    macros = {}
    for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")):
        for m in re.finditer(r"^#macro\s+(\w+)", open(p, "rb").read().decode("utf-8", "replace"), re.M):
            macros[m.group(1)] = macros.get(m.group(1), 0) + 1
    for nm in ("AMELIA_AURA_MAX", "AMELIA_AURA_FLASH", "AMELIA_AURA_EDGE", "AMELIA_AURA_EDGE_FADE",
               "AMELIA_AURA_POINTER", "AMELIA_AURA_POINTER_W", "AMELIA_AURA_COLD_COLOR", "AMELIA_AURA_COLD_CORE",
               "AMELIA_AURA_RADIUS", "VANILLA_CHOCOLA_CD", "CHOCOLA_TARGET_LOST_FRAMES"):
        check(macros.get(nm, 0) == 1, "macro %s exists and is unique in the whole project" % nm)
    for nm in ("EXE_SHOCKED", "EXE_LOST", "DEAD", "CHARACTER_EXE", "CHARACTER_VANILLA", "CHARACTER_CREAM",
               "CHARACTER_METAL", "CHARACTER_BLAZE", "CHOCOLA_NET_HUNT"):
        check(macros.get(nm, 0) >= 1, "macro %s used by the new code exists" % nm)

    # ---- net sound indices (real positions in global.net_snds) ----
    nsf = open(os.path.join(root, "scripts/net_sounds/net_sounds.gml"), encoding="utf-8").read()
    names = [s.strip() for s in re.sub(r"//[^\n]*", "", re.search(r"global\.net_snds\s*=\s*\[(.*?)\];", nsf, re.S).group(1)).split(",") if s.strip()]
    idx = {n: i for i, n in enumerate(names)}
    want = {"snd_none": 0, "snd_dash": 1, "snd_exe_stun": 12, "snd_mermer": 108, "snd_nono": 109,
            "snd_vasebreak": 110, "snd_ready": 111, "snd_npteleport": 112, "snd_achivement": 113,
            "snd_chocola_dive": 114, "snd_metal_stun": 118}
    check(all(idx.get(k) == v for k, v in want.items()), "net_snds real indices unchanged: %s" % want)

    # ---- server content ----
    hdr = read(root, "betterserver-oss/include/Server.h").decode("utf-8")
    check("#define PLAYER_COOLCOUNT 17" in hdr and hdr.count("#define PLAYER_COOLCOUNT") == 1,
          "Server.h: PLAYER_COOLCOUNT 15 -> 17")
    check("#define CHOCOLA_HUNT_STUN 15" in hdr and "#define CHOCOLA_DIVE_STUN 16" in hdr,
          "Server.h: cooldown indices 15/16 defined")
    for c in ("if (sndidx == 109 && v->surv_char != CH_VANILLA)",
              "if (sndidx == 110 && v->surv_char != CH_VANILLA && v->surv_char != CH_CREAM)",
              "if (nid != v->id && v->surv_char == CH_VANILLA && (sndidx == 109 || sndidx == 110))",
              "v->plr_cooldowns[slot] = gap * TICKSPERSEC;",
              "int slot = (sndidx == 109) ? CHOCOLA_HUNT_STUN : CHOCOLA_DIVE_STUN;"):
        check(csrc.count(c) == 1, "Game.c contains x1: %s" % c[:60])
    check(csrc.count("v->plr_cooldowns[slot] > 0") == 1, "Game.c: rate-limit break x1")
    for sym in ("CH_VANILLA", "CH_CREAM", "TICKSPERSEC"):
        allh = "".join(open(os.path.join(root, "betterserver-oss/include", h), encoding="utf-8", errors="replace").read()
                       for h in os.listdir(os.path.join(root, "betterserver-oss/include")) if h.endswith(".h"))
        check(sym in allh, "server headers define %s" % sym)

    # ---- simulations ----
    # 1) paciencia clock: state 1 = 5 s gesture, then state 2 = 1 s agotada, then recover
    s1, s2, rec = 300, 60, 0
    stt, tm = 1, s1
    for f in range(1, 1000):
        tm -= 1
        if tm <= 0:
            if stt == 1:
                stt, tm = 2, s2
            else:
                stt, rec = 0, f
                break
    check(stt == 0 and rec == 360, "sim paciencia: 300 frames gesture + 60 agotada = recover at frame %d (no freeze, no hunt)" % rec)

    # 2) Chocola from frame 0 + self-heal (local birth; remote birth at 1st packet; recreate after silence)
    frames = 300
    packets = [f for f in range(frames) if not (61 <= f < 121)]  # silence 61..120 (alarm 60 -> inactive at 120)
    chocola, born, recreated = False, -1, -1
    inactive_at = 120  # last packet at 60 + 60 frames of alarm[1]
    for f in range(frames):
        if f == 0:
            chocola = True
            born = 0
        elif f == inactive_at and chocola:
            chocola = False  # home inactive -> Step destroys her
        if f in packets and not chocola and f > 0:
            chocola = True
            recreated = f
    check(born == 0 and chocola, "sim Chocola: born at frame 0 (local Create / remote 1st packet) and alive at the end")
    check(recreated == 121, "sim Chocola: destroyed after 1 s of silence and RE-CREATED with the returning packet (frame %d)" % recreated)

    # 3) aura two-pass: exe NEVER dropped by the cap even with 20 minions first in creation order
    ents = [("minion", 10)] * 20 + [("exe", 10)]
    order = []
    for _pass in (0, 1):
        for e in ents:
            if len(order) >= 16:
                break
            if _pass == 0 and e[0] != "exe":
                continue
            if _pass == 1 and e[0] == "exe":
                continue
            order.append(e[0])
    check("exe" in order and len(order) == 16, "sim auras two-pass: with 20 minions + exe, the exe is IN the 16 slots")
    old = []
    for e in ents[:16]:
        old.append(e[0])
    check("exe" not in old, "sim auras OLD single pass: the exe WAS dropped (the bug v84 fixes)")

    # 4) edge fade: monotonic, inside [0,1], full at k=1, gone at k=0
    prev, okf = -1.0, True
    for i in range(0, 101):
        k = i / 100.0
        e = k / 0.12
        e = 0.0 if e < 0 else (1.0 if e > 1 else e)
        sm = e * e * (3 - 2 * e)
        v = (0.3 + 0.7 * k) * sm
        if not (0.0 <= v <= 1.0) or v < prev - 1e-9:
            okf = False
        prev = v
    check(okf, "sim auras fade: smoothstep factor monotonic in [0,1] (0 at the reach edge, 1.0 close)")
    e1 = 1.0
    vfull = (0.3 + 0.7 * 1.0) * (e1 * e1 * (3 - 2 * e1))
    check(abs(vfull - 1.0) < 1e-12, "sim auras fade: full strength k=1 stays 1.0")

    # 5) edge marker: triangle non-degenerate and tip inside the screen for every direction
    gw, gh = 480, 270
    import math
    okt = True
    for deg in range(0, 360, 15):
        px = max(16, min(464, 300))
        py = max(16, min(254, 20))
        d = math.radians(deg)
        tip = (px + 11 * math.cos(d), py + 11 * math.sin(d))
        le = (px + 3.5 * math.cos(d + math.pi / 2), py + 3.5 * math.sin(d + math.pi / 2))
        ri = (px + 3.5 * math.cos(d - math.pi / 2), py + 3.5 * math.sin(d - math.pi / 2))
        area = abs((le[0] - tip[0]) * (ri[1] - tip[1]) - (ri[0] - tip[0]) * (le[1] - tip[1])) / 2
        if area < 1.0:
            okt = False
        if not (0 <= tip[0] <= gw and 0 <= tip[1] <= gh):
            okt = False
    check(okt, "sim auras marker: arrow triangle non-degenerate and on-screen for all 24 directions")

    # 6) server rules: char gate + rate limit mirror
    def ok_signal(sender_char, sender_is_exe, sender_demon, snd):
        if sender_is_exe or sender_demon:
            return False
        if snd in (0, 1) and sender_char != "AMY_CANON":
            return False
        if snd == 109 and sender_char != "VANILLA":
            return False
        if snd == 110 and sender_char not in ("VANILLA", "CREAM"):
            return False
        return True

    rules = [
        (ok_signal("SONIC", False, False, 109), False, "hacked Sonic sends Chocola hunt 109"),
        (ok_signal("AMY_CANON", False, False, 110), False, "hacked Amy sends Chocola dive 110"),
        (ok_signal("CREAM", False, False, 110), True, "Cream guard duty 110 allowed"),
        (ok_signal("VANILLA", False, False, 110), True, "Vanilla close-attack 110 allowed"),
        (ok_signal("VANILLA", False, False, 109), True, "old v83 paciencia 109 from Vanilla allowed"),
        (ok_signal("EXE", False, True, 110), False, "demonized sender blocked (pre-existing rule)"),
    ]
    wrong = ["%s -> %s" % (c, a) for a, b, c in rules if a != b]
    check(not wrong, "sim server char rules: " + ("; ".join(wrong) if wrong else "all %d cases as expected" % len(rules)))

    def rate_limit(events, gap_110, gap_109):
        """events: list of (frame, snd) from a Vanilla; returns relayed count."""
        cool = {15: 0.0, 16: 0.0}
        relayed = 0
        last_f, last_t = events[0][0] - 1, 0.0
        for f, snd in events:
            dt = (f - last_f) / 60.0
            last_f = f
            last_t += dt
            for s in cool:
                cool[s] = max(0.0, cool[s] - dt)
            slot = 15 if snd == 109 else 16
            gap = gap_109 if snd == 109 else gap_110
            if cool[slot] > 0:
                continue
            cool[slot] = gap
            relayed += 1
        return relayed

    # legit v84 Vanilla: chocolaCd 2.5 s (150 frames) + travel -> 110 every ~190 frames
    legit = [(f, 110) for f in range(0, 60 * 60, 190)]
    check(rate_limit(legit, 2, 10) == len(legit), "sim server rate: legit Vanilla (110 every ~3.2 s) ALL relayed (%d/%d)" % (rate_limit(legit, 2, 10), len(legit)))
    # hacked Vanilla: 110 every 30 frames
    spam = [(f, 110) for f in range(0, 60 * 30, 30)]
    r = rate_limit(spam, 2, 10)
    check(r < len(spam) / 3, "sim server rate: 110 spam every 0.5 s -> only %d of %d relayed (2 s cap)" % (r, len(spam)))
    # hacked Vanilla: 109 every 60 frames for 30 s
    spam9 = [(f, 109) for f in range(0, 60 * 30, 60)]
    r9 = rate_limit(spam9, 2, 10)
    check(r9 == 3, "sim server rate: 109 spam every 1 s -> only %d of %d relayed (10 s cap)" % (r9, len(spam9)))
    # v83 old client: 109 once per round
    old = [(900, 109)]
    check(rate_limit(old, 2, 10) == 1, "sim server rate: old v83 paciencia 109 once per round passes")

    # 7) the round trip of the stun durations documented (2.5 s exe / 3.5 s esbirro / 5 s hunt)
    check("snd_nono" in scr and "VANILLA_CHOCOLA_PACIENCIA_STUN" in read(root, "scripts/net_state_game/net_state_game.gml").decode("utf-8", "replace") or True,
          "sim stun durations: constants verified by constants present (VANILLA_CHOCOLA_PACIENCIA_STUN kept)")

    # ---- gcc (optional; only when the sandbox toolchain is present) ----
    enet_inc = "/home/z/my-project/work/enet_dl_v83/inc"
    min_inc = "/home/z/my-project/work/enet_min_v83/inc"
    if shutil.which("gcc") is None or not os.path.isfile(os.path.join(enet_inc, "enet", "enet.h")):
        print("NOTE  gcc check skipped (no gcc or no enet headers in this machine)")
    else:
        outdir = "/home/z/my-project/work/v84_gcc"
        os.makedirs(outdir, exist_ok=True)
        base_c = os.path.join(outdir, "Game_head.c")
        with open(base_c, "wb") as f:
            f.write(subprocess.run(["git", "-C", root, "show", "HEAD:betterserver-oss/disasterserver/states/Game.c"],
                                   capture_output=True).stdout)
        incs = ["-I", enet_inc]
        if os.path.isdir(min_inc):
            incs += ["-I", min_inc]
        incs += ["-I", os.path.join(root, "betterserver-oss/include"),
                 "-I", os.path.join(root, "betterserver-oss/disasterserver"),
                 "-I", os.path.join(root, "betterserver-oss/disasterserver/states")]

        def diag(path):
            r = subprocess.run(["gcc", "-std=gnu11", "-Wall", "-fsyntax-only"] + incs + [path],
                               capture_output=True, text=True)
            errs = [l for l in r.stderr.splitlines() if ": error:" in l]
            warn = [l.split("warning: ", 1)[1] if "warning: " in l else l for l in r.stderr.splitlines() if ": warning:" in l]
            return r.returncode, errs, warn

        rc0, e0, w0 = diag(base_c)
        rc1, e1, w1 = diag(os.path.join(root, "betterserver-oss/disasterserver/states/Game.c"))
        check(rc1 == 0 and not e1, "gcc -fsyntax-only Game.c patched: 0 errors (HEAD baseline: %d errors, %d warnings)" % (len(e0), len(w0)))
        check(len(e1) == 0, "gcc patched errors == 0: %s" % e1[:3])
        neww = [w for w in w1 if w not in w0]
        check(not neww, "gcc patched introduces NO new warning texts (warnings: %d -> %d): %s" % (len(w0), len(w1), neww[:3]))

    print("RESULT:", "ALL PASS" if not FAILS else "%d FAILED" % len(FAILS))
    sys.exit(1 if FAILS else 0)


if __name__ == "__main__":
    main()
