#!/usr/bin/env python3
# ============================================================================
# preview_barras_v10.py — maqueta visual del HUD v10 "IGUAL A LA IMAGEN"
# Reproduce con la MISMA geometria del codigo GML (mismas coordenadas) un
# frame del juego, para verificacion visual antes de aplicar el parche.
# Genera 3 vistas: 4 aliados, 8 aliados y "victima de Jinna" (nega).
# ============================================================================
from PIL import Image, ImageDraw

W, H = 480, 270

DIGITS = {
    '0': ["111", "101", "101", "101", "111"], '1': ["010", "110", "010", "010", "111"],
    '2': ["111", "001", "111", "100", "111"], '3': ["111", "001", "111", "001", "111"],
    '4': ["101", "101", "111", "001", "001"], '5': ["111", "100", "111", "001", "111"],
    '6': ["111", "100", "111", "101", "111"], '7': ["111", "001", "001", "001", "001"],
    '8': ["111", "101", "111", "101", "111"], '9': ["111", "101", "111", "001", "111"],
    '+': ["000", "010", "111", "010", "000"], '7': ["111", "001", "010", "010", "010"],
    'A': ["111", "101", "111", "101", "101"], 'B': ["110", "101", "110", "101", "110"],
    'S': ["111", "100", "111", "001", "111"], 'D': ["110", "101", "101", "101", "110"],
    'C': ["010", "101", "100", "100", "010"],
}

def build(ally_list, self_hp=100, nega_pct=None, fname="/tmp/preview_v10.png"):
    im = Image.new("RGB", (W, H), (24, 0, 0))
    d = ImageDraw.Draw(im)

    # fondo: pared de ladrillos rojo-oscura
    for y in range(0, H, 16):
        for x in range(0, W, 32):
            ox = (y // 16 % 2) * 16
            d.rectangle([x + ox, y, x + ox + 30, y + 14], fill=(47, 7, 2), outline=(29, 4, 4))

    def pix_text(x, y, s, col, scale=1):
        for ch in s:
            g = DIGITS.get(ch)
            if g:
                for r, row in enumerate(g):
                    for c, v in enumerate(row):
                        if v == '1':
                            d.rectangle([x + c * scale, y + r * scale,
                                         x + c * scale + scale - 1, y + r * scale + scale - 1], fill=col)
            x += 4 * scale

    # reloj + ping (v10: x=268)
    d.rectangle([211, 0, 260, 20], fill=(20, 12, 10), outline=(255, 255, 255))
    pix_text(224, 6, "123", (255, 255, 255))
    pix_text(268, 4, "12ms", (39, 255, 57))

    # iconos de habilidad (v10: racimo superior derecho x=370+)
    for i, col in enumerate([(255, 220, 90), (120, 200, 255), (255, 120, 120)]):
        ix, iy = 370, 2 + i * 12
        d.rectangle([ix, iy, ix + 46, iy + 10], fill=(30, 20, 20), outline=col)
        pix_text(ix + 4, iy + 3, ["B", "A", "C"][i], col)

    # retrato 26x26 uniforme (aprox del tile del juego)
    def portrait(x, y, face, ring):
        d.ellipse([x + 2, y + 2, x + 24, y + 24], fill=(10, 8, 8), outline=ring)
        cx, cy = x + 13, y + 13
        d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=face)
        d.ellipse([cx - 3, cy - 3, cx - 1, cy - 1], fill=(20, 10, 10))
        d.ellipse([cx + 1, cy - 3, cx + 3, cy - 1], fill=(20, 10, 10))

    def ally_bar(ty, hp):
        cy = ty + 13
        d.rectangle([30, cy - 4, 76, cy + 4], fill=(84, 12, 12))       # funda granate
        if hp > 0:
            d.rectangle([31, cy - 3, 31 + (hp * 46 + 99) // 100, cy + 3], fill=(232, 20, 20))
        pix_text(32, cy - 2, f"+{hp}", (255, 255, 255))                # "+NN" dentro

    # columna de aliados (filas y = 2 + i*26)
    for i, (face, ring, hp) in enumerate(ally_list):
        ty = 2 + i * 26
        portrait(2, ty, face, ring)
        ally_bar(ty, hp)

    # fila propia (y 210-236)
    portrait(2, 210, (255, 190, 60), (255, 255, 255))
    ally_bar(210, self_hp)
    pix_text(14, 232, "7", (39, 255, 35))                              # shards

    # barra grande v10 (242-268)
    d.rectangle([2, 242, 28, 268], fill=(255, 255, 255))               # marco blanco 2px
    d.rectangle([4, 244, 26, 266], fill=(0, 0, 0))
    d.ellipse([6, 246, 24, 264], fill=(255, 190, 60))
    d.ellipse([10, 252, 13, 255], fill=(20, 10, 10))
    d.ellipse([16, 252, 19, 255], fill=(20, 10, 10))

    fill_col = (0, 255, 1) if self_hp >= 50 else ((255, 255, 0) if self_hp >= 25 else (255, 0, 0))
    d.rectangle([30, 248, 180, 262], fill=(0, 0, 0))                   # contorno negro
    d.rectangle([31, 249, 31 + (self_hp * 148 + 99) // 100, 261], fill=fill_col)
    for t in (68, 105, 142):                                           # 4 tramos
        d.rectangle([t, 249, t + 1, 261], fill=(0, 0, 0))

    # "+NN" grande (glifos 2x con sombra) en 186,249
    x = 186
    for ch in f"+{self_hp}":
        g = DIGITS.get(ch)
        if g:
            for r, row in enumerate(g):
                for c, v in enumerate(row):
                    if v == '1':
                        d.rectangle([x + c * 2 + 2, 249 + r * 2 + 2, x + c * 2 + 3, 251 + r * 2 + 3], fill=(60, 0, 0))
                        d.rectangle([x + c * 2, 249 + r * 2, x + c * 2 + 1, 250 + r * 2 + 1], fill=(255, 255, 255))
        x += 12

    # nega (solo victima de Jinna): y 236-243, x 30-180
    if nega_pct is not None:
        d.rectangle([29, 236, 181, 243], fill=(0, 0, 0))
        d.rectangle([30, 237, 30 + int(150 * nega_pct), 242], fill=(120, 40, 160))

    # emociones (dcha abajo, sin tocar)
    d.rectangle([442, 222, 470, 240], fill=(40, 30, 30), outline=(255, 255, 255))
    pix_text(463, 225, "A", (255, 255, 255))
    pix_text(463, 232, "S", (255, 255, 255))

    im.save(fname)
    print("ok", fname)

# vista 1: 4 aliados (uno herido a 40, uno muerto)
build([((255, 120, 90), (230, 230, 230), 100),
       ((255, 170, 190), (255, 150, 170), 100),
       ((255, 200, 120), (240, 220, 180), 40),
       ((200, 160, 255), (150, 150, 160), 0)], fname="/tmp/preview_v10.png")

# vista 2: 8 aliados (colonia llena)
build([((255, 120, 90), (230, 230, 230), 100),
       ((255, 170, 190), (255, 150, 170), 100),
       ((255, 200, 120), (240, 220, 180), 75),
       ((200, 160, 255), (150, 150, 160), 60),
       ((120, 220, 150), (230, 230, 230), 100),
       ((255, 150, 100), (200, 200, 210), 100),
       ((180, 180, 200), (240, 240, 240), 100),
       ((255, 210, 120), (255, 150, 170), 100)], fname="/tmp/preview_v10_8.png")

# vista 3: victima de Jinna con vida baja (barra amarilla + nega encima)
build([((255, 120, 90), (230, 230, 230), 100),
       ((255, 170, 190), (255, 150, 170), 100)], self_hp=38, nega_pct=0.55, fname="/tmp/preview_v10_nega.png")
