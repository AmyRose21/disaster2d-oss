#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
# mock_v95.py — PREVIEW del v95 (KRIS: salida visible + LOVE = crecimiento +
# duelo final). Mock PIXEL EXACTO con las coordenadas reales del codigo:
#  - obj_playerui/Draw_64.gml: barra del asesino (_kbX=140, _kbY=38, 200x8,
#    relleno ceil(hp/350*198), rotulo "EL ASESINO  N golpes").
#  - obj_kris/Draw_64.gml: flecha spr_sindicator2 (verde, 32x16, origin 3)
#    pegada al cuerpo rotando hacia el obj_bigring mas cercano + "lv N".
#  - obj_level/Draw_64: reloj (224..252, y=4) de contexto + "Escape!!!" y=32.
# 3 estados de la barra (350 lleno / 105 a 3 golpes / knockdown) + panel de
# la flecha. Lienzo 480x270 como el juego, escala 2x para el PNG final.
# ============================================================================
from PIL import Image, ImageDraw, ImageFont
import math

W, H, ZOOM = 480, 270, 2

def font(sz):
    for p in ["/usr/share/fonts/truetype/chinese/NotoSansSC-Regular.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            pass
    return ImageFont.load_default()

F6  = font(6)
F8  = font(8)
F10 = font(10)

def hud_frame(bar_hp, title, sub):
    """un frame 480x270 del HUD de KRIS con la barra del asesino al valor dado"""
    img = Image.new("RGB", (W, H), (24, 26, 34))
    d = ImageDraw.Draw(img)

    # --- fondo de mapa sugerido (lineas de suelo/piso) ---
    for y in range(60, H, 36):
        d.line([(0, y), (W, y)], fill=(30, 33, 42), width=2)

    # --- reloj (obj_level Draw_64: x224..252, y4) ---
    d.rectangle([216, 2, 258, 16], fill=(10, 10, 12))
    d.text((224, 4), "1:47", font=F8, fill=(240, 240, 240))

    # --- "Escape!!!" (obj_level: spr_status 168x15 origen (84,0): y=32..47) ---
    d.rectangle([W//2 - 84, 32, W//2 + 84, 47], outline=(255, 80, 80))
    d.text((W//2 - 30, 36), "Escape!!!", font=F8, fill=(255, 80, 80))

    # === LA BARRA DEL ASESINO (coordenadas EXACTAS del playerui v95) ===
    kbX, kbY = 140, 51                       # 480/2-100, 51 (bajo el Escape real: 32..47)
    d.rectangle([kbX - 2, kbY - 2, kbX + 202, kbY + 10], fill=(0, 0, 0))          # funda negra
    d.rectangle([kbX, kbY, kbX + 200, kbY + 8], fill=(84, 12, 12))                 # casco granate
    if bar_hp > 0:
        fill = math.ceil(bar_hp / 350 * 198)  # ceil(hp/350*198) como el juego
        d.rectangle([kbX + 1, kbY + 1, kbX + 1 + fill, kbY + 7], fill=(232, 20, 20))
    hits_left = math.ceil(bar_hp / 35)      # ceil(hp/35) como el rotulo
    d.text((kbX + 6, kbY + 1), f"EL ASESINO  {hits_left} golpes", font=F6, fill=(255, 255, 255))

    # --- fila propia abajo (banda 242-268): retrato + barra "+NN" (lv 20 = 480) ---
    d.rectangle([2, 242, 28, 268], outline=(120, 120, 130), fill=(40, 42, 50))
    d.text((6, 248), "KRIS", font=F6, fill=(200, 200, 210))
    d.rectangle([30, 251, 76, 259], fill=(84, 12, 12))
    d.rectangle([31, 252, 75, 258], fill=(232, 20, 20))     # lleno (se acaba de subir de LV)
    d.text((32, 252), "+480", font=F6, fill=(255, 255, 255))
    # lv 20 en rojo pleno sobre la fila (patron v47)
    d.text((90, 246), "lv 20", font=F8, fill=(255, 40, 40))

    # --- panel de titulo ---
    d.text((8, 8), title, font=F10, fill=(255, 220, 90))
    d.text((8, 20), sub, font=F6, fill=(170, 170, 180))
    return img

def arrow_panel():
    """la FLECHA DE SALIDA: Kris + flecha verde rotando al bigring mas cercano"""
    img = Image.new("RGB", (W, H), (24, 26, 34))
    d = ImageDraw.Draw(img)
    d.text((8, 8), "FLECHA DE SALIDA (siempre visible)", font=F10, fill=(120, 255, 120))
    d.text((8, 20), "spr_sindicator2 pegado al cuerpo, patron Amy Canon — apunta al anillo de escape mas cercano", font=F6, fill=(170, 170, 180))

    # anillo de escape (obj_bigring) arriba a la derecha
    rx, ry = 402, 78
    d.ellipse([rx - 14, ry - 14, rx + 14, ry + 14], outline=(255, 216, 0), width=4)
    d.ellipse([rx - 6, ry - 6, rx + 6, ry + 6], outline=(255, 255, 160), width=2)

    # Kris (muñeco simple) abajo a la izquierda
    kx, ky = 120, 170
    d.rectangle([kx - 8, ky - 16, kx + 8, ky + 16], fill=(40, 60, 130), outline=(16, 20, 40))
    d.rectangle([kx - 6, ky - 26, kx + 6, ky - 16], fill=(224, 208, 190), outline=(60, 50, 40))  # cara
    d.rectangle([kx - 3, ky - 22, kx - 1, ky - 20], fill=(20, 20, 30))                          # pelo azul oscuro
    d.rectangle([kx + 1, ky - 22, kx + 3, ky - 20], fill=(20, 20, 30))
    # la espada (X)
    d.line([(kx + 8, ky - 4), (kx + 20, ky - 10)], fill=(190, 190, 210), width=2)
    d.text((kx - 28, ky - 44), "lv 20", font=F8, fill=(255, 40, 40))

    # LA FLECHA: 32x16 origin(3,8) girada hacia el bigring (point_direction)
    import math
    ang = math.degrees(math.atan2(-(ry - ky), rx - kx))     # point_direction: arriba=90
    # triángulo-flecha verde (aprox. visual del spr_sindicator2)
    L, wd = 30, 7
    tipx = kx + math.cos(math.radians(ang)) * L
    tipy = ky - math.sin(math.radians(ang)) * L
    basex = kx + math.cos(math.radians(ang)) * 2
    basey = ky - math.sin(math.radians(ang)) * 2
    perp = ang + 90
    p1 = (basex + math.cos(math.radians(perp)) * wd, basey - math.sin(math.radians(perp)) * wd)
    p2 = (basex - math.cos(math.radians(perp)) * wd, basey + math.sin(math.radians(perp)) * wd)
    d.polygon([p1, (tipx, tipy), p2], fill=(90, 230, 90), outline=(20, 90, 30))

    # leyenda de la barra del asesino tambien en este panel (conectado al lv20)
    kbX, kbY = 140, 236
    d.rectangle([kbX - 2, kbY - 2, kbX + 202, kbY + 10], fill=(0, 0, 0))
    d.rectangle([kbX, kbY, kbX + 200, kbY + 8], fill=(84, 12, 12))
    d.rectangle([kbX + 1, kbY + 1, kbX + 1 + math.ceil(350 / 350 * 198), kbY + 7], fill=(232, 20, 20))
    d.text((kbX + 6, kbY + 1), "EL ASESINO  10 golpes", font=F6, fill=(255, 255, 255))
    d.text((kbX, kbY - 12), "con LV 20 la espada le hace 35 de dano real por golpe", font=F6, fill=(200, 130, 130))
    return img

# ---- componer la lámina: 3 estados de barra + panel flecha ----
frames = [
    hud_frame(350, "A. BARRA LLENA (350 = 10 golpes)", "recien llegado al LV 20: el asesino se vuelve vulnerable"),
    hud_frame(105, "B. A UN TERCIO (105 = 3 golpes)", "7 cuchillazos conectados de 35"),
    hud_frame(0,  "C. KNOCKDOWN (llega a 0)", "10 golpes = derribo de 10 s y el pool se rellena"),
    arrow_panel(),
]
sheet = Image.new("RGB", (W * 2 * 2 + 30, H * 2 * 2 + 20), (12, 13, 18))
for i, fr in enumerate(frames[:2]):
    sheet.paste(fr.resize((W * 2, H * 2), Image.NEAREST), (5 + i * (W * 2 + 10), 5))
for i, fr in enumerate(frames[2:]):
    sheet.paste(fr.resize((W * 2, H * 2), Image.NEAREST), (5 + i * (W * 2 + 10), 10 + H * 2 + 5))

out = "/home/z/my-project/download/PREVIEW_V95_KRIS_DUENO.png"
sheet.save(out)
print("OK", out, sheet.size)
