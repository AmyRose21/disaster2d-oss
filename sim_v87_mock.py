#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v87 mock renderer: PREVIEW_V87_AURAS_MOCK.png.

NOT a game capture — a Python/PIL mock that mirrors 1:1 the formulas of
objects/obj_amelia_auras/Draw_64.gml (v87) so the reworked layers can be
eyeballed without opening GameMaker. Every value below is copied from the
AMELIA_AURA_* macros in scripts/scr_amelia_special/scr_amelia_special.gml.

Renders 3 panels (pulse = 0 / 23 / 46) of a fake 480x270 GUI scaled x2:
  * Amelia (pink) + her 350 px reach drawn faint for reference,
  * an EXE signature (k=0.80) with a fresh entry ping in panel 1,
  * a minion signature (k=0.45),
  * a COLD signature (k=0.65, blue, frozen),
  * two OFF-SCREEN signatures (exe k=0.90, minion k=0.10) -> chevron
    markers at the screen edge with proximity pips.

Usage: python3 sim_v87_mock.py [repo_root]
Writes: <repo_root>/PREVIEW_V87_AURAS_MOCK.png
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw

# ---- AMELIA_AURA_* macros (copied from scr_amelia_special.gml) ----
RADIUS = 350.0
EXE_R, MINION_R = 26.0, 14.0
PULSE_SPD = 0.09
EXE_PULSE_AMP, MINION_PULSE_AMP = 3.0, 2.0
EXE_COLOR = (255, 80, 0)
EXE_CORE = (255, 200, 90)
MINION_COLOR = (255, 130, 30)
COLD_COLOR = (110, 185, 255)
COLD_CORE = (225, 245, 255)
SEED = 59
RIPPLES_EXE, RIPPLES_MINION = 3, 2
RIPPLE_SPREAD = 12.0
RIPPLE_A_EXE, RIPPLE_A_MINION = 0.5, 0.3
TICKS_EXE, TICKS_MINION, TICKS_COLD = 8, 4, 6
TICK_LEN, TICK_LEN_EXE = 4.0, 6.0
RETICLE_SPD_EXE, RETICLE_SPD_MINION = 5.5, -3.5
PING_R, PING_A = 40.0, 0.6
PIP_0, PIP_STEP, PIP_R = 22.0, 5.0, 1.5
POINTER, POINTER_W, POINTER_EXE = 11.0, 3.5, 1.4
EDGE = 16.0
FLASH = 27  # 60 * 0.45

S = 2  # GUI scale (480x270 -> 960x540)


def smoothstep_k(aurak, flash=0.0):
    """v84/v87 strength: (0.3 + 0.7*k) * smoothstep(k / EDGE_FADE) + fl*0.5, clamped."""
    e = aurak / 0.12
    e = 0.0 if e < 0 else (1.0 if e > 1 else e)
    k = (0.3 + 0.7 * aurak) * (e * e * (3 - 2 * e)) + flash * 0.5
    return min(k, 1.0)


def add(dst, layer, alpha):
    """Additive blend (bm_add): dst += layer * alpha."""
    if alpha <= 0:
        return dst
    if alpha < 1.0:
        layer = layer.point(lambda v: int(v * alpha))
    return ImageChops.add(dst, layer)


def line_layer(size, p1, p2, color, width):
    lay = Image.new("RGB", size, (0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.line([p1, p2], fill=color, width=width)
    return lay


def ellipse_layer(size, box, color, width, outline):
    lay = Image.new("RGB", size, (0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.ellipse(box, fill=None if outline else color,
              outline=color if outline else None, width=width if outline else 1)
    return lay


def tri_layer(size, pts, color):
    lay = Image.new("RGB", size, (0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.polygon(pts, fill=color)
    return lay


def capsule_layer(size, cx, cy, w, h, color):
    lay = Image.new("RGB", size, (0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.rounded_rectangle([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2],
                        radius=w / 2, fill=color)
    return lay


def draw_signature(img, x, y, aurak, is_exe, cold, pulse, eid, flash=0.0, scale=S):
    """Mirror of one iteration of the Draw_64 loop (onscreen branch)."""
    beat = math.sin(pulse * (2 if is_exe else 1))
    if cold:
        beat = 0.0
    seed = (eid % SEED) / SEED
    fl = flash / FLASH if flash > 0 else 0.0
    k = smoothstep_k(aurak, fl)
    r = 0.0
    if is_exe:
        r = EXE_R + beat * EXE_PULSE_AMP
    else:
        r = MINION_R + beat * MINION_PULSE_AMP
    r += fl * 2
    ay = y - 6

    col_halo = COLD_COLOR if cold else (EXE_COLOR if is_exe else MINION_COLOR)
    col_core = COLD_CORE if cold else (EXE_CORE if is_exe else MINION_COLOR)

    # A. heat dome (2 layers)
    img = add(img, ellipse_layer(img.size, circ(x, ay, r, scale), col_halo, 0, False), 0.05 * k)
    dome = 0.10 * k
    if is_exe:
        dome += 0.05 * beat * k
    img = add(img, ellipse_layer(img.size, circ(x, ay, r * 0.62, scale), col_halo, 0, False), dome)

    # B. sonar waves
    if not cold:
        waves = RIPPLES_EXE if is_exe else RIPPLES_MINION
        wa = (RIPPLE_A_EXE if is_exe else RIPPLE_A_MINION) * k
        col_wave = col_core if is_exe else col_halo
        wspd = (PULSE_SPD / (2 * math.pi)) * (2 if is_exe else 1)
        for w in range(waves):
            t = (pulse * wspd + w / waves + seed) % 1.0
            rad = r * 0.55 + t * (r + RIPPLE_SPREAD - r * 0.55)
            img = add(img, ellipse_layer(img.size, circ(x, ay, rad, scale), col_wave, scale, True),
                      wa * (1 - t) * (1 - t))

    # C. reticle ring + ticks
    img = add(img, ellipse_layer(img.size, circ(x, ay, r, scale), col_core, scale, True),
              (0.5 if is_exe else 0.3) * k)
    ticks, tlen = (TICKS_EXE, TICK_LEN_EXE) if is_exe else (TICKS_MINION, TICK_LEN)
    tbase = pulse * (RETICLE_SPD_EXE if is_exe else RETICLE_SPD_MINION)
    if cold:
        ticks, tbase = TICKS_COLD, -45.0
    for t in range(ticks):
        a = math.radians(tbase + 360.0 / ticks * t)
        p1 = (x + (r + 2) * math.cos(a), ay + (r + 2) * math.sin(a))
        p2 = (x + (r + 2 + tlen) * math.cos(a), ay + (r + 2 + tlen) * math.sin(a))
        img = add(img, line_layer(img.size, px(p1, scale), px(p2, scale), col_core, scale), 0.4 * k)

    # D. core (exe only)
    if is_exe:
        img = add(img, ellipse_layer(img.size, circ(x, ay, 8 + beat * 2, scale), col_core, 0, False), 0.35 * k)

    # E. silhouette (capsule mock; exe = 2 layers)
    if is_exe:
        img = add(img, capsule_layer(img.size, int(x * scale), int((y - 2) * scale), 30 * scale, 44 * scale, col_halo), 0.22 * k)
        img = add(img, capsule_layer(img.size, int(x * scale), int((y - 2) * scale), 24 * scale, 36 * scale, col_core), 0.38 * k)
    else:
        img = add(img, capsule_layer(img.size, int(x * scale), int((y - 2) * scale), 22 * scale, 32 * scale, col_core), 0.2 * k)

    # F. entry ping
    if fl > 0:
        img = add(img, ellipse_layer(img.size, circ(x, ay, 4 + (1 - fl) * PING_R, scale), col_core, scale, True), PING_A * fl)
    return img


def draw_edge_marker(img, sx, sy, gw, gh, aurak, is_exe, cold, flash=0.0, scale=S):
    """Mirror of the off-screen branch (chevron x2 + anchor ring + pips)."""
    fl = flash / FLASH if flash > 0 else 0.0
    mk = min(0.35 + 0.45 * aurak + fl * 0.3, 1.0)
    px_, py_ = min(max(sx, EDGE), gw - EDGE), min(max(sy, EDGE), gh - EDGE)
    amel = (gw * 0.25, gh * 0.55)
    d = math.degrees(math.atan2(sy - amel[1], sx - amel[0])) % 360.0

    col_halo = COLD_COLOR if cold else (EXE_COLOR if is_exe else MINION_COLOR)
    col_core = COLD_CORE if cold else (EXE_CORE if is_exe else MINION_COLOR)

    cs = POINTER_EXE if is_exe else 1.0
    fd, fw = POINTER * cs, POINTER_W * cs

    bx, by = px_ - fd * 1.1 * math.cos(math.radians(d)), py_ - fd * 1.1 * math.sin(math.radians(d))
    bw = fw * 0.65
    dr = math.radians(d)
    back = [(bx + fd * 0.85 * math.cos(dr), by + fd * 0.85 * math.sin(dr)),
            (bx + bw * math.cos(dr + math.pi / 2), by + bw * math.sin(dr + math.pi / 2)),
            (bx + bw * math.cos(dr - math.pi / 2), by + bw * math.sin(dr - math.pi / 2))]
    img = add(img, tri_layer(img.size, pxs(back, scale), col_halo), mk * 0.45)

    nx, ny = px_ - fd * 0.4 * math.cos(dr), py_ - fd * 0.4 * math.sin(dr)
    front = [(nx + fd * math.cos(dr), ny + fd * math.sin(dr)),
             (nx + fw * math.cos(dr + math.pi / 2), ny + fw * math.sin(dr + math.pi / 2)),
             (nx + fw * math.cos(dr - math.pi / 2), ny + fw * math.sin(dr - math.pi / 2))]
    img = add(img, tri_layer(img.size, pxs(front, scale), col_core), mk)

    img = add(img, ellipse_layer(img.size, circ(px_, py_, 3, scale), col_halo, scale, True), mk * 0.8)

    pips = 3 if aurak > 0.66 else (2 if aurak > 0.33 else 1)
    for p in range(pips):
        pd = PIP_0 + p * PIP_STEP
        qx, qy = px_ - pd * math.cos(dr), py_ - pd * math.sin(dr)
        img = add(img, ellipse_layer(img.size, circ(qx, qy, PIP_R, scale), col_core, 0, False), mk * 0.8)
    return img


def circ(x, y, r, scale):
    rr = r * scale
    return [x * scale - rr, y * scale - rr, x * scale + rr, y * scale + rr]


def px(p, scale):
    return (p[0] * scale, p[1] * scale)


def pxs(pts, scale):
    return [(x * scale, y * scale) for x, y in pts]


def panel(pulse):
    """One 480x270 GUI mock scaled x2 -> 960x540 RGB."""
    gw, gh = 480, 270
    img = Image.new("RGB", (gw * S, gh * S), (26, 26, 32))
    d = ImageDraw.Draw(img)
    # fake map: floor + a wall the auras see through
    d.rectangle([0, 180 * S, gw * S, gh * S], fill=(38, 34, 30))
    d.rectangle([190 * S, 60 * S, 210 * S, 260 * S], fill=(52, 46, 40))
    d.rectangle([330 * S, 0, 350 * S, 120 * S], fill=(52, 46, 40))

    # Amelia's reach (reference only, faint white ring at 350 px)
    ax, ay = gw * 0.25, gh * 0.55
    reach = Image.new("RGB", img.size, (0, 0, 0))
    ImageDraw.Draw(reach).ellipse(circ(ax, ay, RADIUS, S), outline=(40, 40, 44), width=2)
    img = ImageChops.add(img, reach)
    # Amelia (pink, reference)
    d = ImageDraw.Draw(img)
    d.ellipse([ax * S - 9, ay * S - 13, ax * S + 9, ay * S + 13], fill=(224, 84, 148))
    d.text((ax * S - 22, ay * S + 18), "AMELIA", fill=(200, 200, 200))

    # onscreen signatures (EXE fresh ping only in panel 1)
    img = draw_signature(img, 262, 110, 0.80, True, False, pulse, eid=100007, flash=FLASH if pulse < 30 else 0)
    img = draw_signature(img, 400, 205, 0.45, False, False, pulse, eid=100029)
    img = draw_signature(img, 140, 222, 0.65, False, True, pulse, eid=100053)

    # offscreen signatures (beyond the GUI bounds)
    img = draw_edge_marker(img, 520, 46, gw, gh, 0.90, True, False)    # exe, very close
    img = draw_edge_marker(img, 300, -40, gw, gh, 0.10, False, False)  # minion, far

    d = ImageDraw.Draw(img)
    d.text((262 * S - 60, 110 * S - 74), "EXE (k=0.80)", fill=(255, 160, 90))
    d.text((400 * S - 70, 205 * S - 52), "MINION (k=0.45)", fill=(255, 180, 120))
    d.text((140 * S - 60, 222 * S - 46), "COLD (k=0.65)", fill=(160, 210, 255))
    d.text((10, 10), "v87 aura mock - pulse=%.2f (NOT a game capture; formulas mirrored 1:1 from Draw_64.gml)" % pulse,
           fill=(150, 150, 150))
    return img


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    header = Image.new("RGB", (960, 34), (16, 16, 20))
    ImageDraw.Draw(header).text(
        (12, 10),
        "AURAVISION v87 VISUAL REWORK - layers: heat dome / sonar waves / reticle / core / silhouette / entry ping / edge chevron + pips",
        fill=(210, 210, 210))
    panels = [panel(p) for p in (0.0, 23.0, 46.0)]
    gap = 8
    total = 34 + sum(p.size[1] for p in panels) + gap * len(panels)
    out = Image.new("RGB", (960, total), (16, 16, 20))
    y = 0
    out.paste(header, (0, y))
    y += header.size[1] + gap
    for p in panels:
        out.paste(p, (0, y))
        y += p.size[1] + gap
    dst = os.path.join(root, "PREVIEW_V87_AURAS_MOCK.png")
    out.save(dst)
    print("wrote", dst, out.size)


if __name__ == "__main__":
    main()
