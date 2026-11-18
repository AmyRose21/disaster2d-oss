#!/usr/bin/env python3
"""allybars_preview.py — maqueta del HUD inferior con las barras de aliados.

Dibuja el GUI 480x270 (confirmado: window_set_size(480,270)) a 2x con:
  - tira del equipo centrada: tiles 26x26, banda 242-267 (anclados abajo
    en y=268), espaciadas 28px
  - mini barra de vida de cada tile (filas 255-260): fondo negro 24x6 +
    relleno 22px=100HP, paleta lime/yellow/red por tramos
  - digitos de deadTimer/shards en y=264 (5px de alto: 264-269)
  - bloque propio v8 a la izquierda (222-240): retrato 18x18 + barra
    100px + "+NN"
  - barrita nega v8 en y=212
Escenarios: 4 jugadores (HP variadas + un muerto) y 8 jugadores (tira
maxima, para comprobar que no choca con el bloque propio ni los bordes).
"""
from PIL import Image, ImageDraw

S = 2  # escala
W, H = 480 * S, 270 * S

LIME = (48, 224, 66)
YELLOW = (255, 221, 0)
RED = (255, 40, 40)
DARKRED = (140, 20, 20)

def bar_color(hp):
    return LIME if hp >= 50 else (YELLOW if hp >= 25 else RED)

def draw_tile(d, tx, hp, label, dead=False, num=None, numcol=(40, 255, 60)):
    """tile 26x26 banda 242-267 + mini barra filas 255-260 + numero 264+"""
    x0, y0 = tx * S, 242 * S
    # marco del retrato (placeholder: gris azulado con inicial)
    d.rectangle([x0, y0, x0 + 26 * S - 1, y0 + 26 * S - 1], fill=(52, 60, 78), outline=(20, 24, 34))
    d.text((x0 + 9 * S, y0 + 6 * S), label, fill=(200, 210, 230))
    # mini barra v1: fondo negro (tx+1,255)-(tx+24,260), relleno (tx+2,256)-(tx+1+ceil(hp*.22),259)
    bx0, by0 = (tx + 1) * S, 255 * S
    d.rectangle([bx0, by0, (tx + 24) * S - 1, 260 * S - 1], fill=(0, 0, 0))
    if hp > 0:
        w = -(-hp * 22 // 100)  # ceil(hp*0.22)
        d.rectangle([(tx + 2) * S, 256 * S, (tx + 1 + w) * S - 1, 259 * S - 1], fill=bar_color(hp))
    # numero (deadTimer/shards) en 264: digitos 5px de alto -> 264-269
    if num is not None:
        d.text(((tx + 8) * S, 264 * S), num, fill=numcol)

def own_block(d, hp, nega=0):
    """bloque propio v8: retrato 18x18 (2-20), barra 21-125, +NN en 128"""
    y = 222
    d.rectangle([2 * S, y * S, 19 * S, (y + 17) * S - 1], fill=(0, 0, 0), outline=(255, 255, 255))
    d.text((5 * S, (y + 4) * S), "TU", fill=(220, 220, 230))
    d.rectangle([21 * S, (y + 4) * S, 124 * S - 1, (y + 13) * S - 1], fill=(0, 0, 0))
    if hp > 0:
        d.rectangle([22 * S, (y + 5) * S, (22 + hp) * S - 1, (y + 12) * S - 1], fill=bar_color(hp))
    for t in (1, 2, 3):
        d.rectangle([(22 + 25 * t) * S, (y + 5) * S, (22 + 25 * t) * S, (y + 12) * S - 1], fill=(0, 0, 0))
    d.text((128 * S, (y + 4) * S), f"+{hp}", fill=(255, 255, 255))
    # nega v8 (y=212, x=60..162)
    if nega > 0:
        d.rectangle([59 * S, 211 * S, 162 * S, 217 * S - 1], fill=(0, 0, 0))
        d.rectangle([60 * S, 212 * S, (60 + nega) * S - 1, 216 * S - 1], fill=(150, 60, 190))

def strip(d, players, self_first=True):
    """players: lista de dicts {hp, label, dead, num} — el primero es el local"""
    n = len(players)
    pos = 480 // 2 - (n * 28) // 2
    for i, p in enumerate(players):
        draw_tile(d, pos + i * 28, p["hp"], p["label"], p.get("dead", False), p.get("num"), p.get("numcol", (40, 255, 60)))

def render(name, players, own_hp, nega=0):
    img = Image.new("RGB", (W, H), (16, 18, 26))
    d = ImageDraw.Draw(img)
    # guia: borde inferior de la tira (268) y del GUI (270)
    d.line([0, 268 * S - 1, W, 268 * S - 1], fill=(90, 40, 40))
    strip(d, players)
    own_block(d, own_hp, nega)
    # etiquetas de zona
    d.text((4 * S, 244 * S), "tira equipo 242-268", fill=(140, 150, 170))
    img.save(name)
    print("escrito", name)

# escenario 1: 4 jugadores (local + 3 aliados), HP variadas, un muerto con deadTimer
render("/tmp/render/allybars_4p.png", [
    dict(hp=100, label="T"),            # local (tu tile tambien lleva barra)
    dict(hp=68,  label="A"),            # aliado verde
    dict(hp=30,  label="S"),            # aliado amarillo
    dict(hp=0,   label="K", dead=True, num="7", numcol=(255, 90, 90)),  # muerto: barra vacia + deadTimer
], own_hp=100)

# escenario 2: 8 jugadores (tira maxima realista) + un shard verde
render("/tmp/render/allybars_8p.png", [
    dict(hp=100, label="T"),
    dict(hp=92,  label="A"), dict(hp=77, label="S"), dict(hp=64, label="V"),
    dict(hp=55,  label="M"), dict(hp=41, label="B"), dict(hp=22, label="R", num="3"),
    dict(hp=9,   label="F"),
], own_hp=87, nega=40)

# escenario 3: 10 jugadores (stress: la tira llega hasta x=100)
render("/tmp/render/allybars_10p.png", [
    dict(hp=100, label="T"),
    dict(hp=90, label="A"), dict(hp=80, label="S"), dict(hp=70, label="V"), dict(hp=60, label="M"),
    dict(hp=50, label="B"), dict(hp=40, label="R"), dict(hp=30, label="F"), dict(hp=20, label="E"),
    dict(hp=10, label="C"),
], own_hp=100)
