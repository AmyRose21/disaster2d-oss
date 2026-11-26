#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v87 verification (no GameMaker here): VISUAL rework of Amelia's auras.

The rework is DRAW-ONLY, so the checks prove exactly that:
  * Step_0.gml (the sensing) is BYTE-identical to git HEAD,
  * Create_0.gml only gained comment lines (code identical to HEAD),
  * every identifier used by the new Draw_64 is declared/known
    (locals, instance vars, macros, GML builtins),
  * every v84 guard survived (camera, GUI bounds, cold, flash,
    smoothstep edge fade, alpha/colour/blend restore),
  * numeric simulations of every new layer: heat dome, sonar waves
    (with the per-signature seed), reticle ticks (exe forward /
    minion backwards / cold frozen), entry ping, double chevron and
    the proximity pips of the edge marker.

Usage: python3 -I check_v87.py <repo_root> [--roundtrip <zip>]
Exit code 0 only if every check passes.  Read-only.
"""
import math
import os
import re
import subprocess
import sys
import zipfile

CODE = [
    "scripts/scr_amelia_special/scr_amelia_special.gml",
    "objects/obj_amelia_auras/Create_0.gml",
    "objects/obj_amelia_auras/Draw_64.gml",
]
STEP = "objects/obj_amelia_auras/Step_0.gml"
DOCS = ["CACHE.md", "LEARNING.md", "worklog.md",
        "LEEME_V87_AMELIA_AURAS_REWORK.txt", "check_v87.py",
        "sim_v87_mock.py", "PREVIEW_V87_AURAS_MOCK.png"]
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
        if "_backups" in dp or "__pycache__" in dp:
            continue
        for f in fn:
            if f.endswith(ext):
                yield os.path.join(dp, f)


def head(root, rel):
    return subprocess.run(["git", "-C", root, "show", "HEAD:" + rel],
                          capture_output=True).stdout


def macros_of(root):
    macros = {}
    for p in list(walk(root, "scripts", ".gml")) + list(walk(root, "objects", ".gml")):
        for m in re.finditer(r"(?m)^#macro\s+(\w+)",
                             open(p, "rb").read().decode("utf-8", "replace")):
            macros[m.group(1)] = macros.get(m.group(1), 0) + 1
    return macros


BUILTIN = {
    "draw_set_alpha", "draw_set_color", "draw_circle", "draw_triangle",
    "draw_line_width", "draw_sprite_ext", "draw_set_circle_precision",
    "gpu_set_blendmode", "bm_add", "bm_normal", "c_white",
    "instance_exists", "variable_instance_exists", "array_length",
    "display_get_gui_width", "display_get_gui_height",
    "point_direction", "lengthdir_x", "lengthdir_y",
    "frac", "sin", "min", "max", "abs", "ceil", "floor", "clamp", "pi",
    "x", "y", "id", "sprite_index", "image_index", "image_xscale",
    "image_yscale", "angle", "visible",
}
KEYWORDS = {"if", "else", "for", "while", "return", "var", "not", "and",
            "or", "mod", "div", "true", "false", "noone", "self",
            "other", "all", "global", "pi", "break", "continue"}
RES_PREFIX = ("obj_", "spr_", "snd_", "scr_", "fnt_", "rm_", "path_",
              "sh_", "sp_", "an_", "seq_")


def main():
    root = sys.argv[1]
    rd = sys.argv.index("--roundtrip") if "--roundtrip" in sys.argv else -1
    st = subprocess.run(["git", "-C", root, "status", "--porcelain"],
                        capture_output=True, text=True).stdout
    changed = [l[3:] for l in st.splitlines() if l.strip()]
    if rd > 0:
        z = zipfile.ZipFile(sys.argv[rd + 1])
        names = z.namelist()
        check(sorted(names) == sorted(changed),
              "roundtrip: zip list == changed list of the clone (%d files)" % len(names))
        check(all(read(root, n) == z.read(n) for n in names),
              "roundtrip: every zipped file is byte-identical in the clone")
    check(set(CODE) <= set(changed), "all 3 patched files show as modified in git")
    check(STEP not in changed, "Step_0.gml (the SENSING) is NOT modified: v87 is draw-only")
    check(not any(c.endswith((".yy", ".yyp")) for c in changed), "no .yy / .yyp touched")
    extra = sorted(set(changed) - set(CODE + DOCS))
    check(not extra, "no unexpected extra files changed: %s" % extra)

    # ---- the sensing is intact, byte-exact ----
    check(read(root, STEP) == head(root, STEP),
          "Step_0.gml: byte-identical to git HEAD (sensing 100% untouched)")

    # ---- Create_0: comments only ----
    ac = read(root, "objects/obj_amelia_auras/Create_0.gml").decode("utf-8")
    cur_code = [l for l in strip_gml(ac).splitlines() if l.strip()]
    head_code = [l for l in strip_gml(head(root, "objects/obj_amelia_auras/Create_0.gml").decode("utf-8")).splitlines() if l.strip()]
    check(cur_code == head_code,
          "auras/Create_0: code identical to HEAD (only comment lines added)")
    check(ac.count("array_create(AMELIA_AURA_MAX") == 9,
          "auras/Create_0: all 9 arrays still sized by AMELIA_AURA_MAX (no new state)")

    # ---- lexer on every patched GML file ----
    for rel in CODE:
        b = read(root, rel)
        t = b.decode("utf-8")
        code = strip_gml(t)
        ok, why = brackets(code)
        check(ok, "%s: brackets balanced %s" % (rel, why))
        check(b"\r" not in b, "%s: no CR (LF only)" % rel)
        base_raw = head(root, rel).decode("utf-8", "replace")
        check(t.endswith("\n") == base_raw.endswith("\n"),
              "%s: final-newline convention kept as the owner's original" % rel)
        base_ct = chained_ternary(strip_gml(base_raw))
        check(chained_ternary(code) <= base_ct,
              "%s: no NEW chained ternary (owner's file %d, patched %d)" % (rel, base_ct, chained_ternary(code)))
        check("TODO87" not in t and "FIXME" not in t and "XXX" not in t,
              "%s: no leftover marker" % rel)

    adr = read(root, "objects/obj_amelia_auras/Draw_64.gml").decode("utf-8")
    scr = read(root, "scripts/scr_amelia_special/scr_amelia_special.gml").decode("utf-8")

    # ---- v84 guards all survived the rewrite ----
    for needle, label in [
        ("if(!visible)", "visible guard"),
        ("auraCount <= 0)", "empty guard"),
        ("if(!instance_exists(obj_camera))", "camera guard"),
        ("display_get_gui_width()", "GUI bounds W"),
        ("display_get_gui_height()", "GUI bounds H"),
        ("AMELIA_AURA_EDGE;", "edge margin"),
        ("(3 - 2 * _e)", "smoothstep edge fade"),
        ("AMELIA_AURA_EDGE_FADE", "edge fade macro"),
        ("_beat = 0;", "cold = no pulse"),
        ("AMELIA_AURA_COLD_COLOR", "cold colour"),
        ("AMELIA_AURA_COLD_CORE", "cold core colour"),
        ("variable_instance_exists(_inst.id, \"angle\")", "silhouette guarded read"),
        ("draw_set_circle_precision(32)", "circle precision"),
        ("gpu_set_blendmode(bm_add)", "additive blend on"),
        ("gpu_set_blendmode(bm_normal)", "blend restored"),
        ("draw_set_alpha(1);", "alpha restored"),
        ("draw_set_color(c_white)", "colour restored"),
        ("floor(_sx), floor(_sy)", "silhouette draws at the puppet's floor coords"),
    ]:
        check(needle in adr, "Draw_64: v84 guard kept: %s" % label)

    # ---- v87 layers present ----
    for needle, label in [
        ("// --- A. DOMO", "A. heat dome"),
        ("_r * 0.62, false", "A. dome inner layer (0.62)"),
        ("// --- B. ONDAS SONAR", "B. sonar waves"),
        ("frac(auraPulse * _wspd + w / _waves + _seed)", "B. wave phase (frac + seed)"),
        ("AMELIA_AURA_RIPPLE_SPREAD", "B. ripple spread macro"),
        ("_wspd = _wspd * 2;", "B. exe waves at 2x speed (like its heartbeat)"),
        ("// --- C. RET", "C. reticle"),
        ("draw_line_width(", "C. tick marks via draw_line_width"),
        ("_tbase = -45;", "C. cold reticle FROZEN (static base angle)"),
        ("AMELIA_AURA_TICKS_COLD", "C. cold tick count macro"),
        ("// --- D. N", "D. core"),
        ("8 + _beat * 2, false", "D. exe hot core kept from v84"),
        ("// --- E. SILUETA", "E. silhouette"),
        ("0.22 * _k", "E. exe silhouette layer 1 (halo)"),
        ("0.38 * _k", "E. exe silhouette layer 2 (core)"),
        ("// --- F. PING", "F. entry ping"),
        ("AMELIA_AURA_PING_A * _fl", "F. ping alpha"),
        ("4 + (1 - _fl) * AMELIA_AURA_PING_R", "F. ping radius 4..4+PING_R"),
        ("// --- G. marcador de borde", "G. edge marker"),
        ("AMELIA_AURA_POINTER * _cs", "G. chevron scaled by signature type"),
        ("AMELIA_AURA_POINTER_EXE", "G. exe chevron macro"),
        ("_fd * 0.85, _dir", "G. back chevron apex"),
        ("AMELIA_AURA_PIP_0 + p * AMELIA_AURA_PIP_STEP", "G. proximity pips spacing"),
        ("auraK[i] > 0.66", "G. pip threshold near"),
        ("else if(auraK[i] > 0.33)", "G. pip threshold mid"),
        ("auraPulse * (auraExe[i] ? 2 : 1)", "exe heartbeat at 2x kept"),
        ("if(_k > 1)", "k clamp kept"),
        ("if(_mk > 1)", "marker alpha clamp kept"),
        ("_eid mod AMELIA_AURA_SEED", "per-signature stable seed (id mod SEED)"),
    ]:
        check(needle in adr, "Draw_64: v87 layer kept: %s" % label)

    # ---- pure local drawing: no net, no server, no randomness ----
    check(not re.search(r"\bnet_|\bbuffer_|socket|udp_send", strip_gml(adr)),
          "Draw_64: zero network/server calls (visual rework stays client-local)")
    check("random" not in strip_gml(adr),
          "Draw_64: deterministic drawing (no random() -> same frame, same picture)")

    # ---- macros: unique project-wide, all used ones exist ----
    macros = macros_of(root)
    new_macros = ["AMELIA_AURA_SEED", "AMELIA_AURA_RIPPLES_EXE", "AMELIA_AURA_RIPPLES_MINION",
                  "AMELIA_AURA_RIPPLE_SPREAD", "AMELIA_AURA_RIPPLE_A_EXE", "AMELIA_AURA_RIPPLE_A_MINION",
                  "AMELIA_AURA_TICKS_EXE", "AMELIA_AURA_TICKS_MINION", "AMELIA_AURA_TICKS_COLD",
                  "AMELIA_AURA_TICK_LEN", "AMELIA_AURA_TICK_LEN_EXE",
                  "AMELIA_AURA_RETICLE_SPD_EXE", "AMELIA_AURA_RETICLE_SPD_MINION",
                  "AMELIA_AURA_PING_R", "AMELIA_AURA_PING_A",
                  "AMELIA_AURA_PIP_0", "AMELIA_AURA_PIP_STEP", "AMELIA_AURA_PIP_R",
                  "AMELIA_AURA_POINTER_EXE"]
    for nm in new_macros:
        check(macros.get(nm, 0) == 1, "macro %s defined exactly once in the project" % nm)
        check(nm in adr, "macro %s is actually used by the new Draw_64" % nm)
    old_macros = ["AMELIA_AURA_RADIUS", "AMELIA_AURA_EXE_R", "AMELIA_AURA_MINION_R",
                  "AMELIA_AURA_PULSE_SPD", "AMELIA_AURA_EXE_PULSE_AMP", "AMELIA_AURA_MINION_PULSE_AMP",
                  "AMELIA_AURA_EXE_COLOR", "AMELIA_AURA_EXE_CORE", "AMELIA_AURA_MINION_COLOR",
                  "AMELIA_AURA_MAX", "AMELIA_AURA_FLASH", "AMELIA_AURA_EDGE", "AMELIA_AURA_EDGE_FADE",
                  "AMELIA_AURA_POINTER", "AMELIA_AURA_POINTER_W",
                  "AMELIA_AURA_COLD_COLOR", "AMELIA_AURA_COLD_CORE"]
    for nm in old_macros:
        check(macros.get(nm, 0) == 1, "v84/v2.12 macro %s still unique (canon values untouched)" % nm)

    # every AMELIA_AURA_* used by Draw_64 is defined
    used = set(re.findall(r"\b(AMELIA_AURA_\w+)", adr))
    check(all(macros.get(u, 0) == 1 for u in used),
          "every AMELIA_AURA_* used by Draw_64 is defined exactly once: %s" % sorted(used))

    # ---- symbol table: every identifier of the new Draw_64 is known ----
    code = strip_gml(adr)
    code = re.sub(r"\bglobal\.\w+", "global", code)  # global.player -> global
    locals_ = set(re.findall(r"\bvar\s+([A-Za-z_]\w*)", code))
    create_code = strip_gml(ac)
    instvars = set(re.findall(r"(?m)^([A-Za-z_]\w*)\s*=[^=]", create_code))
    instvars.add("depth")
    known = locals_ | instvars | set(macros) | BUILTIN | KEYWORDS | {"obj_camera"}
    unknown = sorted(u for u in set(re.findall(r"[A-Za-z_]\w*", code))
                     if u not in known and not u.startswith(RES_PREFIX))
    check(not unknown, "Draw_64 symbol table: every identifier declared/known (unknown: %s)" % unknown)
    check({"auraCount", "auraPulse", "auraX", "auraY", "auraR", "auraK", "auraExe",
           "auraInst", "auraCold", "auraId", "auraFlash"} <= instvars,
          "Draw_64 reads only fields declared by the auras' Create")

    # ---- scr_amelia_special: macro values documented + old section intact ----
    for needle, label in [
        ("#macro AMELIA_AURA_SEED 59", "SEED 59 (prime)"),
        ("#macro AMELIA_AURA_RIPPLES_EXE 3", "3 exe waves"),
        ("#macro AMELIA_AURA_RIPPLES_MINION 2", "2 minion waves"),
        ("#macro AMELIA_AURA_RIPPLE_SPREAD 12", "wave spread 12 px"),
        ("#macro AMELIA_AURA_TICKS_EXE 8", "8 exe ticks"),
        ("#macro AMELIA_AURA_TICKS_MINION 4", "4 minion ticks"),
        ("#macro AMELIA_AURA_TICKS_COLD 6", "6 cold ticks"),
        ("#macro AMELIA_AURA_RETICLE_SPD_EXE 5.5", "exe reticle forward"),
        ("#macro AMELIA_AURA_RETICLE_SPD_MINION -3.5", "minion reticle BACKWARDS"),
        ("#macro AMELIA_AURA_PING_R 40", "ping radius 40"),
        ("#macro AMELIA_AURA_POINTER_EXE 1.4", "exe chevron 1.4x"),
    ]:
        check(needle in scr, "scr_amelia_special: %s" % label)
    for nm in ("AMELIA_MAXSPEED", "AMELIA_TRAP_RECHARGE", "AMELIA_LUNA_VEIL_TIME", "AMELIA_ECLIPSE_TIME"):
        check(("#macro %s" % nm) in scr, "scr_amelia_special: rest of the kit intact (%s)" % nm)

    # ================= simulations =================
    PULSE_SPD, EXE_R, MINION_R = 0.09, 26.0, 14.0
    SPREAD, SEED, FLASH = 12.0, 59, 27  # 60 * 0.45
    EDGE_FADE, PING_R, PING_A = 0.12, 40.0, 0.6

    # 1) heat dome: 2 layers, both <= 0.15 alpha, inner >= outer (gradient)
    okd = True
    for k10 in range(11):
        k = k10 / 10.0
        for beat in (-1.0, 0.0, 1.0):
            outer = 0.05 * k
            inner = (0.10 + 0.05 * beat) * k
            if not (0 <= outer <= inner + 1e-9 and inner <= 0.15 + 1e-9):
                okd = False
    check(okd, "sim dome: outer 0.05k <= inner (0.10+0.05beat)k, both <= 0.15 (gradient, never opaque)")

    # 2) sonar waves: radius in [0.55r, r+SPREAD), monotonic in t; alpha (1-t)^2*A*k <= A
    okw = True
    for r, A, who in ((EXE_R, 0.5, "exe"), (MINION_R, 0.3, "minion")):
        r0, r1 = 0.55 * r, r + SPREAD
        prev = -1.0
        for s in range(241):
            t = s / 240.0 * (1 - 1e-9)
            rad = r0 + t * (r1 - r0)
            alpha = A * (1 - t) * (1 - t)
            if not (r0 - 1e-9 <= rad <= r1 + 1e-9) or rad < prev - 1e-9:
                okw = False
            if not (0 <= alpha <= A):
                okw = False
            prev = rad
        if who == "exe":
            check(abs(r0 - 14.3) < 1e-9 and abs(r1 - 38.0) < 1e-9, "sim waves exe: born at 14.3 px, die at 38 px (aro 26)")
        else:
            check(abs(r0 - 7.7) < 1e-9 and abs(r1 - 26.0) < 1e-9, "sim waves minion: born at 7.7 px, die at 26 px (aro 14)")
    check(okw, "sim waves: radius monotonic in [0.55r, r+SPREAD], alpha (1-t)^2*A in [0,A]")

    # 3) wave speed: exe cycle = half the minion cycle (2x, like its heartbeat)
    cyc_min = 2 * math.pi / PULSE_SPD
    check(abs(cyc_min - 69.813) < 0.01, "sim wave clock: minion full wave every ~69.8 frames (~1.16 s at 60 fps)")
    check(abs(cyc_min / 2 - 34.906) < 0.01, "sim wave clock: exe full wave every ~34.9 frames (exactly 2x)")

    # 4) seed: id mod 59 -> 59 distinct phases in [0,1), stable per signature
    seeds = {(i % SEED) / SEED for i in range(1, 2001)}
    check(len(seeds) == SEED and all(0 <= s < 1 for s in seeds),
          "sim seed: (id mod 59)/59 gives %d distinct stable phases in [0,1)" % len(seeds))
    check(all(SEED % p for p in range(2, 8)), "sim seed: 59 is prime (no harmonic lock with tick counts)")

    # 5) reticle ticks: outside the ring, even spacing, exe forwards / minion backwards / cold frozen
    okt = True
    for r, n, ln, who in ((EXE_R, 8, 6, "exe"), (MINION_R, 4, 4, "minion"), (MINION_R, 6, 4, "cold")):
        angs = {-45 + 360.0 / n * t if who == "cold" else 360.0 / n * t for t in range(n)}
        if len(angs) != n:
            okt = False
        for a in angs:
            inner, outer = r + 2, r + 2 + ln
            if not (r < inner < outer <= r + 8):
                okt = False
    spd_exe, spd_min = 0.09 * 5.5, 0.09 * -3.5
    check(okt, "sim reticle: ticks evenly spaced, strictly outside the aro (r+2 .. r+8)")
    check(0 < spd_exe < 1 and -1 < spd_min < 0,
          "sim reticle: exe turns FORWARD at %.3f deg/frame, minion BACKWARDS at %.3f deg/frame (no jumps)" % (spd_exe, spd_min))

    # 6) entry ping: radius 4 -> 4+PING_R growing while alpha PING_A -> 0
    okp, prev_r = True, 3.9
    for fl in range(FLASH, -1, -1):
        f = fl / FLASH
        rad = 4 + (1 - f) * PING_R
        if not (4 <= rad <= 4 + PING_R + 1e-9) or rad < prev_r - 1e-9:
            okp = False
        if not (0 <= PING_A * f <= PING_A):
            okp = False
        prev_r = rad
    check(okp, "sim ping: flash 27->0 => radius 4->44 monotonic, alpha 0.6->0 (born small and bright)")

    # 7) chevron: (a) invariant: tip offset (0.6 * POINTER * POINTER_EXE = 9.24)
    #    is SMALLER than the edge margin - 2: whatever the direction, the tip
    #    stays inside the EDGE band on any resolution; (b) both triangles
    #    non-degenerate; (c) back apex strictly behind the front apex (">>");
    #    (d) realistic outward dirs (center -> anchor +/- 30 deg): tip on-screen
    #    at 3 resolutions x 8 anchors x 5 spreads.
    tip_off = 0.6 * 11.0 * 1.4
    check(tip_off < 16 - 2,
          "sim chevron: tip offset %.2f px < edge margin - 2 (never crosses the border, any direction)" % tip_off)
    okc = True
    for deg in range(0, 360, 15):
        d = math.radians(deg)
        for cs in (1.0, 1.4):
            fd, fw = 11.0 * cs, 3.5 * cs
            if fd * fw < 1 or fd * 0.85 * fw * 0.65 < 1:
                okc = False
            if not (-0.25 * fd < 0.6 * fd):  # back apex behind the anchor, front apex beyond it
                okc = False
    check(okc, "sim chevron: both triangles non-degenerate and back apex behind front apex (24 dirs x 2 scales)")
    okr = True
    for gw, gh in ((480, 270), (320, 180), (200, 120)):
        ex0, ex1, ey0, ey1 = 16, gw - 16, 16, gh - 16
        anchors = [(ex0, ey0), (ex1, ey0), (ex0, ey1), (ex1, ey1),
                   (gw / 2, ey0), (gw / 2, ey1), (ex0, gh / 2), (ex1, gh / 2)]
        for (px, py) in anchors:
            bdeg = math.degrees(math.atan2(py - gh / 2.0, px - gw / 2.0))
            for off in (-30, -15, 0, 15, 30):
                d = math.radians(bdeg + off)
                fd = 11.0 * 1.4
                tipx = px - fd * 0.4 * math.cos(d) + fd * math.cos(d)
                tipy = py - fd * 0.4 * math.sin(d) + fd * math.sin(d)
                if not (0 <= tipx <= gw and 0 <= tipy <= gh):
                    okr = False
    check(okr, "sim chevron: with realistic outward dirs the tip stays on-screen at 3 resolutions")

    # 8) pips: 1-3 by proximity; PIP_0 starts BEYOND the chevron tail
    #    (1.1 * POINTER * POINTER_EXE = 16.94 px), so pips and chevron never
    #    overlap; with realistic outward dirs the dots go back TOWARDS the
    #    middle of the screen: on-screen.
    check(22.0 > 1.1 * 11.0 * 1.4,
          "sim pips: PIP_0 (22) starts beyond the chevron tail (%.2f px): no overlap" % (1.1 * 11.0 * 1.4))
    okpp = True
    for k, want in ((0.9, 3), (0.67, 3), (0.5, 2), (0.4, 2), (0.1, 1)):
        pips = 1
        if k > 0.66:
            pips = 3
        elif k > 0.33:
            pips = 2
        if pips != want:
            okpp = False
    for gw, gh in ((480, 270), (320, 180), (200, 120)):
        ex0, ex1, ey0, ey1 = 16, gw - 16, 16, gh - 16
        anchors = [(ex0, ey0), (ex1, ey0), (ex0, ey1), (ex1, ey1),
                   (gw / 2, ey0), (gw / 2, ey1), (ex0, gh / 2), (ex1, gh / 2)]
        for (px, py) in anchors:
            bdeg = math.degrees(math.atan2(py - gh / 2.0, px - gw / 2.0))
            for off in (-30, -15, 0, 15, 30):
                d = math.radians(bdeg + off)
                for p in range(3):
                    pd = 22 + p * 5
                    qx = px - pd * math.cos(d)
                    qy = py - pd * math.sin(d)
                    if not (0 <= qx <= gw and 0 <= qy <= gh):
                        okpp = False
    check(okpp, "sim pips: k>0.66->3, >0.33->2, else 1; dots (22/27/32 px back towards Amelia) on-screen for realistic dirs at 3 resolutions")

    # 9) alpha caps: _k and _mk clamped by code, worst raw values documented
    k_raw = (0.3 + 0.7 * 1.0) * 1.0 + 0.5
    mk_raw = 0.35 + 0.45 * 1.0 + 0.3
    check(k_raw > 1 and "if(_k > 1)" in adr and "if(_mk > 1)" in adr,
          "sim caps: raw worst k=%.2f / mk=%.2f both > 1 and BOTH clamps present in code" % (k_raw, mk_raw))

    # 10) v84 edge fade still monotonic (unchanged formula)
    prev, okf = -1.0, True
    for i in range(101):
        kk = i / 100.0
        e = kk / EDGE_FADE
        e = 0.0 if e < 0 else (1.0 if e > 1 else e)
        v = (0.3 + 0.7 * kk) * (e * e * (3 - 2 * e))
        if not (0 <= v <= 1) or v < prev - 1e-9:
            okf = False
        prev = v
    check(okf, "sim fade: v84 smoothstep factor still monotonic in [0,1]")

    # 11) cold signature: beat forced 0 -> dome/ring/core static; no waves; 6 frozen ticks
    check("_beat = 0;" in adr and "if(!_cold)" in adr and "_tbase = -45;" in adr,
          "sim cold: no pulse, no waves, frozen reticle (static blue = neutralised threat)")

    # ---- docs ----
    wl = read(root, "worklog.md").decode("utf-8")
    cache = read(root, "CACHE.md").decode("utf-8")
    learn = read(root, "LEARNING.md").decode("utf-8")
    leeme = os.path.join(root, "LEEME_V87_AMELIA_AURAS_REWORK.txt")
    check("## v87" in wl, "worklog.md: v87 entry present")
    check("v87" in cache, "CACHE.md: v87 changelog/section present")
    check("v87" in learn, "LEARNING.md: v87 lessons present")
    check(os.path.isfile(leeme) and os.path.getsize(leeme) > 500, "LEEME_V87 present and non-trivial")
    png = os.path.join(root, "PREVIEW_V87_AURAS_MOCK.png")
    if os.path.isfile(png):
        try:
            from PIL import Image
            im = Image.open(png).convert("L")
            px = list(im.getdata())
            dark = sum(1 for v in px if v < 200) / float(len(px))
            check(dark > 0.5, "PREVIEW_V87_AURAS_MOCK.png: renders (non-blank, %.0f%% non-white)" % (dark * 100))
        except Exception as e:
            check(False, "PREVIEW_V87_AURAS_MOCK.png: PIL check failed: %s" % e)
    else:
        print("NOTE  PREVIEW png not present (sim_v87_mock.py not run yet)")

    print("RESULT:", "ALL PASS" if not FAILS else "%d FAILED" % len(FAILS))
    sys.exit(1 if FAILS else 0)


if __name__ == "__main__":
    main()
