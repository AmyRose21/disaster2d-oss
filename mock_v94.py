#!/usr/bin/env python3
# v94 — PIXEL-MOCK de los iconos animados de KRIS y AMY CANON.
# Emula drawMiniIcon (obj_playerui/Draw_64.gml) exactamente: frame =
# floor(current_time/150) mod frames, contenido (_cx.._cx+_cw, _cy.._cy+_ch)
# escalado, color estado, alpha recarga, desliz (1-alpha)*10, vaiven _fly
# y la tecla real al lado (Z/X/C/V por defecto). Vista 480x270, esquina
# HUD x[360..480] y[0..70], ampliada 4x.
import re, os
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.abspath(__file__))
HUD_X0, HUD_Y0 = 360, 0
HUD_W, HUD_H = 120, 70
ZOOM = 4
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 9)

def frames_of(name):
    d = os.path.join(REPO, "sprites", name)
    txt = open(os.path.join(d, name + ".yy")).read()
    guids = re.findall(r'"%Name":\s*"([0-9a-fA-F-]{36})",\s*"name":\s*"\1"', txt)
    out = []
    for g in guids:
        p = os.path.join(d, g + ".png")
        if os.path.exists(p):
            out.append(Image.open(p).convert("RGBA"))
    return out

def tint(img, col, alpha):
    r, g, b = col
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            pr, pg, pb, pa = px[x, y]
            if pa == 0:
                continue
            # multiplicar por el color, luego por alpha global (draw_sprite_part_ext)
            nr = int(pr * r / 255) if r < 255 else pr
            ng = int(pg * g / 255) if g < 255 else pg
            nb = int(pb * b / 255) if b < 255 else pb
            px[x, y] = (nr, ng, nb, int(pa * alpha))

def mini_icon(base, spr, cx, cy, cw, ch, scale, key, xx, yy, col, alpha, fly, t, label_hud):
    fr = frames_of(spr)
    frame = int(t / 150) % max(1, len(fr))
    slide = (1.0 - alpha) * 10
    flyx = round(__import__("math").sin(t / fly) * 3) if fly > 0 else 0
    src = fr[frame].crop((cx, cy, cx + cw, cy + ch))
    src = src.resize((max(1, round(cw * scale)), max(1, round(ch * scale))), Image.NEAREST)
    tint(src, col, alpha)
    base.alpha_composite(src, (int(xx + slide + flyx) - HUD_X0, int(yy) - HUD_Y0))
    d = ImageDraw.Draw(base)
    tx = xx + cw * scale + 4 + slide + flyx - HUD_X0
    ty = yy + int(ch * scale * 0.5) - 3 - HUD_Y0
    a = int(alpha * 255)
    d.text((tx + 1, ty + 1), key, font=FONT, fill=(0, 0, 0, a // 2))
    d.text((tx, ty), key, font=FONT, fill=col + (a,))

def render(scenario, rows, t):
    img = Image.new("RGBA", (HUD_W, HUD_H), (40, 44, 52, 255))
    for r in rows:
        mini_icon(img, *r, t=t, label_hud=scenario)
    return img.resize((HUD_W * ZOOM, HUD_H * ZOOM), Image.NEAREST)

def two_panels(a, b):
    out = Image.new("RGBA", (HUD_W * ZOOM * 2, HUD_H * ZOOM), (20, 22, 26, 255))
    out.paste(a, (0, 0)); out.paste(b, (HUD_W * ZOOM, 0))
    return out

WHITE, RED = (255, 255, 255), (255, 68, 68)

# ---------------- KRIS ----------------
kris_ready = [
    ("spr_kris_jump", 5, 1, 35, 42, 0.38, "Z", 372, 222 - 216, WHITE, 1.0, 0),
    ("spr_kris_attack1_air1", 8, 0, 53, 70, 0.24, "X", 372, 240 - 216, WHITE, 1.0, 0),
    ("spr_kris_block_success_ground", 10, 7, 35, 40, 0.4, "C", 372, 258 - 216, WHITE, 1.0, 0),
]
kris_recharging = [
    ("spr_kris_jump", 5, 1, 35, 42, 0.38, "Z", 372, 222 - 216, RED, 0.35, 0),
    ("spr_kris_attack1_air1", 8, 0, 53, 70, 0.24, "X", 372, 240 - 216, RED, 0.6, 0),
    ("spr_kris_block_success_ground", 10, 7, 35, 40, 0.4, "C", 372, 258 - 216, RED, 0.45, 0),
]
kr = two_panels(render("kris_ready", kris_ready, t=0), render("kris_recharging", kris_recharging, t=300))
kr.save(os.path.join(REPO, "PREVIEW_V94_KRIS.png"))

# ---------------- AMY CANON ----------------
ac_ground = [  # en suelo, todo listo
    ("spr_amy_attack2_canon", 1, 0, 47, 59, 0.28, "Z", 372, 222 - 216, WHITE, 1.0, 0),
    ("spr_amy_attack1_canon", 1, 2, 45, 42, 0.38, "X", 372, 240 - 216, RED, 1.0, 0),  # lista PERO en tierra -> rojo
    ("spr_amy_attack3_canon_", 25, 18, 57, 52, 0.3, "C", 372, 258 - 216, WHITE, 1.0, 0),
    ("spr_amy_parry_exitoso", 6, 4, 38, 42, 0.38, "V", 416, 258 - 216, WHITE, 1.0, 0),
]
ac_air = [  # en el aire: X lista, C = LSA
    ("spr_amy_attack2_canon", 1, 0, 47, 59, 0.28, "Z", 372, 222 - 216, RED, 0.5, 0),
    ("spr_amy_attack1_canon", 1, 2, 45, 42, 0.38, "X", 372, 240 - 216, WHITE, 1.0, 0),
    ("spr_amy_light_speed_canon", 0, 0, 35, 33, 0.42, "C", 372, 258 - 216, WHITE, 1.0, 200),
    ("spr_amy_parry_exitoso", 6, 4, 38, 42, 0.38, "V", 416, 258 - 216, RED, 1.0, 0),  # parry es tierra
]
ac_super2 = [  # super fase 2 en tierra: C = lanzada de martillo
    ("spr_amy_attack2_canon", 1, 0, 47, 59, 0.28, "Z", 372, 222 - 216, WHITE, 1.0, 0),
    ("spr_amy_attack1_canon", 1, 2, 45, 42, 0.38, "X", 372, 240 - 216, RED, 0.5, 0),
    ("spr_super_amy_hrow_hammer", 0, 3, 56, 52, 0.3, "C", 372, 258 - 216, RED, 0.62, 0),
    ("spr_amy_parry_exitoso", 6, 4, 38, 42, 0.38, "V", 416, 258 - 216, RED, 0.4, 0),
]
ac_recharging = [
    ("spr_amy_attack2_canon", 1, 0, 47, 59, 0.28, "Z", 372, 222 - 216, RED, 0.3, 0),
    ("spr_amy_attack1_canon", 1, 2, 45, 42, 0.38, "X", 372, 240 - 216, RED, 0.55, 0),
    ("spr_amy_attack3_canon_", 25, 18, 57, 52, 0.3, "C", 372, 258 - 216, RED, 0.7, 0),
    ("spr_amy_parry_exitoso", 6, 4, 38, 42, 0.38, "V", 416, 258 - 216, RED, 0.45, 0),
]
quad = Image.new("RGBA", (HUD_W * ZOOM * 2, HUD_H * ZOOM * 2), (20, 22, 26, 255))
quad.paste(render("ground", ac_ground, t=0), (0, 0))
quad.paste(render("air", ac_air, t=450), (HUD_W * ZOOM, 0))
quad.paste(render("super2", ac_super2, t=150), (0, HUD_H * ZOOM))
quad.paste(render("rech", ac_recharging, t=600), (HUD_W * ZOOM, HUD_H * ZOOM))
quad.save(os.path.join(REPO, "PREVIEW_V94_AMYCANON.png"))
print("OK PREVIEW_V94_KRIS.png + PREVIEW_V94_AMYCANON.png")
