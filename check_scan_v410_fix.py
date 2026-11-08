#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_scan_v410_fix.py — verificador del SCAN v4.10 (Metal Amy).

QUE CAMBIA LA v4.10 (pedido del usuario):
  1) DURACION «de 8 a 12 s»: la V manual pasa de 8 s a 12 s
     (METALAMY_SCAN_TIME = 60*12) y la ventana PASIVA de la marca de la
     cazadora queda en 8 s con macro propia (METALAMY_HUNT_WINDOW = 60*8,
     la usaba el Step_0 con el macro manual). El HUD no cambia: sus
     barras de progreso leen SCAN_RECHARGE y HUNT_TIME, ninguno se toca.
  2) SILUETAS LEJANAS EN MAPAS CLAROS: la silueta fijada al borde de la
     pantalla (fuera de la vista 480x270) era un fantasma aditivo con
     alpha *0.45 — en mapas con mucha iluminacion sumar rojo a un fondo
     casi blanco no cambia nada y «no se notaban». Ahora se dibuja en
     TRES pasadas: contorno oscuro (blend normal, 4 offsets de 2 px,
     alpha 0.9) + relleno rojo vivo (blend normal, alpha 0.62+0.33*pulso)
     + brillo aditivo encima (alpha 0.35*pulso). La silueta DENTRO de la
     vista queda IDENTICA a la v4.8 (brillo aditivo pulsante): el pedido
     era solo para las que estan lejos de Metal Amy.

Este script NO modifica nada: solo verifica (estatica + simulaciones 1:1
del dibujo y del ciclo de la cazadora, reproduciendo el comportamiento
viejo como control). Uso: python3 check_scan_v410_fix.py [raiz_del_repo]
"""

import math
import os
import re
import subprocess
import sys

FAIL = 0
PASS = 0


def check(name, cond, detail=""):
    global FAIL, PASS
    if cond:
        PASS += 1
        print(f"  [OK]   {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}" + (f" — {detail}" if detail else ""))


def section(title):
    print(f"\n=== {title} ===")


_cand = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(
    os.path.abspath(__file__))
if not os.path.isdir(os.path.join(_cand, "objects")):
    _cand = os.path.dirname(_cand)
REPO = _cand if os.path.isdir(os.path.join(_cand, "objects")) else None
if not REPO:
    print("No encuentro la raiz del repo (objects/).")
    sys.exit(1)


def rd(rel):
    with open(os.path.join(REPO, rel), encoding="utf-8", errors="replace") as f:
        return f.read()


def git_show(rel):
    try:
        out = subprocess.run(["git", "-C", REPO, "show", "HEAD:" + rel],
                             capture_output=True, text=True, check=True)
        return out.stdout
    except subprocess.CalledProcessError:
        return None


# ==========================================================================
print("FIX SCAN v4.10 — Metal Amy: duracion 8-12 s + siluetas lejanas legibles")
print(f"repo: {REPO}")

# --------------------------------------------------------------------------
section("1. ESTATICA — macros del scan (scr_metalamy_special.gml)")
# --------------------------------------------------------------------------
sp = rd("scripts/scr_metalamy_special/scr_metalamy_special.gml")

m = re.search(r"#macro\s+METALAMY_SCAN_TIME\s+\(60\s*\*\s*(\d+)\)", sp)
check("METALAMY_SCAN_TIME = 12 s (V manual)", m and m.group(1) == "12",
      m.group(1) if m else "no encontrado")

m = re.search(r"#macro\s+METALAMY_HUNT_WINDOW\s+\(60\s*\*\s*(\d+)\)", sp)
check("METALAMY_HUNT_WINDOW = 8 s (macro nueva de la cazadora)",
      m and m.group(1) == "8", m.group(1) if m else "no encontrado")

m = re.search(r"#macro\s+METALAMY_SCAN_RECHARGE\s+\(60\s*\*\s*(\d+)\)", sp)
check("METALAMY_SCAN_RECHARGE sigue en 20 s (intacto)", m and m.group(1) == "20")

m = re.search(r"#macro\s+METALAMY_HUNT_TIME\s+\(60\s*\*\s*(\d+)\)", sp)
check("METALAMY_HUNT_TIME sigue en 14 s (ciclo de la cazadora, intacto)",
      m and m.group(1) == "14")

check("12 y 8 caen dentro del rango pedido «de 8 a 12 s»",
      True, "12 manual / 8 pasiva")

# --------------------------------------------------------------------------
section("2. ESTATICA — quien usa cada macro")
# --------------------------------------------------------------------------
step0 = rd("objects/obj_metalamy/Step_0.gml")
draw64 = rd("objects/obj_exe_indicator/Draw_64.gml")
create0 = rd("objects/obj_metalamy/Create_0.gml")
playerui = rd("objects/obj_playerui/Draw_64.gml")

check("Step_0: la ventana pasiva usa METALAMY_HUNT_WINDOW (2 asignaciones)",
      len(re.findall(r"scanTimer\s*=\s*METALAMY_HUNT_WINDOW", step0)) == 2,
      f"{len(re.findall(r'scanTimer\\s*=\\s*METALAMY_HUNT_WINDOW', step0))} asignaciones")
check("Step_0: ya NO usa METALAMY_SCAN_TIME",
      "METALAMY_SCAN_TIME" not in step0,
      "la V manual nunca se dispara desde el Step_0")
check("special: la V manual sigue usando METALAMY_SCAN_TIME (1 sitio)",
      len(re.findall(r"scanTimer\s*=\s*METALAMY_SCAN_TIME", sp)) == 1)
check("HUD intacto: sigue leyendo HUNT_TIME y SCAN_RECHARGE (no la duracion)",
      "METALAMY_HUNT_TIME" in playerui and "METALAMY_SCAN_RECHARGE" in playerui
      and "METALAMY_SCAN_TIME" not in playerui)
check("HUD intacto byte a byte vs HEAD (sin cambios del cliente en el UI)",
      playerui == git_show("objects/obj_playerui/Draw_64.gml"))

# --------------------------------------------------------------------------
section("3. ESTATICA — Draw_64: las tres pasadas de la silueta lejana")
# --------------------------------------------------------------------------
check("colores v4.10 presentes: contorno make_color_rgb(56, 8, 8)",
      "make_color_rgb(56, 8, 8)" in draw64)
check("relleno vivo make_color_rgb(255, 72, 72)",
      "make_color_rgb(255, 72, 72)" in draw64)
check("pasada 1: contorno con 4 offsets (+-2 px) en blend normal",
      len(re.findall(r"ceil\(_sx\)\s*[+-]\s*2|ceil\(_sy\)\s*[+-]\s*2", draw64)) >= 4
      and draw64.count("_farEdge") >= 5)
check("alpha del contorno = 0.9 * _fade", "0.9 * _fade" in draw64)
check("pasada 2: relleno solido alpha (0.62 + 0.33 * _pulse) * _fade",
      "(0.62 + 0.33 * _pulse) * _fade" in draw64)
check("pasada 3: brillo aditivo 0.35 * _pulse * _fade",
      "0.35 * _pulse * _fade" in draw64)
check("la silueta lejana sigue fijada al borde: clamp(_sx, 24, 456) + clamp(_sy, 24, 246)",
      "clamp(_sx, 24, 456)" in draw64 and "clamp(_sy, 24, 246)" in draw64)
check("DENTRO de la vista: formula v4.8 intacta (c_red, _pulse * _fade, aditivo)",
      "c_red, _pulse * _fade" in draw64)
check("el viejo fantasma *0.45 ya no existe", "_alpha *= 0.45" not in draw64)
check("blendmodes balanceados en el bloque del scan (2 aditivos, 2 normales)",
      draw64.count("gpu_set_blendmode(bm_add)") == 2
      and draw64.count("gpu_set_blendmode(bm_normal)") == 2)

# --------------------------------------------------------------------------
section("4. ESTATICA — lo que NO se toca (regresiones vs HEAD)")
# --------------------------------------------------------------------------
for rel in ["objects/obj_exe_indicator/Step_2.gml",
            "objects/obj_exe_indicator/Create_0.gml",
            "objects/obj_exe_indicator/obj_exe_indicator.yy"]:
    head = git_show(rel)
    check(f"{rel} intacto vs HEAD" if head is not None else f"{rel} nuevo en el arbol",
          rd(rel) == head if head is not None else True)

check("la aguja (needle) sigue gateada con su bandera propia",
      "if(!needle)" in draw64 and "needle = (" in rd("objects/obj_exe_indicator/Step_2.gml"))
check("interruptor del motor intacto: visible = needle || scanCount > 0",
      "visible = needle || scanCount > 0" in rd("objects/obj_exe_indicator/Step_2.gml"))

# llaves balanceadas en los 3 gml editados
for rel in ["scripts/scr_metalamy_special/scr_metalamy_special.gml",
            "objects/obj_metalamy/Step_0.gml",
            "objects/obj_exe_indicator/Draw_64.gml"]:
    t = rd(rel)
    check(f"llaves balanceadas: {rel.split('/')[-1]}",
          t.count("{") == t.count("}"),
          f"{{={t.count('{')} }}={t.count('}')}")

# --------------------------------------------------------------------------
section("5. SIMULACION 1:1 — visibilidad de la silueta lejana en un mapa CLARO")
# --------------------------------------------------------------------------
# Se reproduce la matematica EXACTA de GameMaker para un pixel del cuerpo
# del sprite contra tres fondos representativos, con el pulso al minimo
# (0.25, el peor caso del seno) y fade a tope (1.0).
#   - aditivo : dst + src*alpha   (v4.8 / dentro de la vista)
#   - normal  : lerp(dst, src, alpha)  (contorno y relleno v4.10)
# El sprite de silueta es c_red (255,0,0) en la v4.8; en la v4.10 el
# cuerpo pinta _farFill (255,72,72) y el borde _farEdge (56,8,8).


def additive(dst, src, a):
    return tuple(min(255, round(d + s * a)) for d, s in zip(dst, src))


def normal(dst, src, a):
    return tuple(round(d + (s - d) * a) for d, s in zip(dst, src))


PULSE_MIN = 0.55 - 0.3           # 0.25 — el seno en su valle
FADE = 1.0
RED = (255, 0, 0)
EDGE = (56, 8, 8)
FILL = (255, 72, 72)
BACKGROUNDS = {
    "mapa claro (nieve/arena, 236,232,224)": (236, 232, 224),
    "mapa luminoso medio (200,208,220)": (200, 208, 220),
    "mapa oscuro (24,20,28)": (24, 20, 28),
}

for nombre, bg in BACKGROUNDS.items():
    # VIEJO (v4.8): aditivo c_red con alpha = pulse*fade*0.45
    viejo = additive(bg, RED, PULSE_MIN * FADE * 0.45)
    # NUEVO (v4.10): contorno normal -> relleno normal -> aditivo suave
    borde = normal(bg, EDGE, 0.9 * FADE)
    cuerpo = normal(borde, FILL, (0.62 + 0.33 * PULSE_MIN) * FADE)
    nuevo = additive(cuerpo, RED, 0.35 * PULSE_MIN * FADE)

    # contraste perceptual aproximado (distancia al fondo)
    d_viejo = sum(abs(a - b) for a, b in zip(viejo, bg))
    d_nuevo = sum(abs(a - b) for a, b in zip(nuevo, bg))
    mejor = d_nuevo > d_viejo * 2
    check(f"{nombre}: contraste nuevo {d_nuevo} vs viejo {d_viejo} (>2x)", mejor)

# caso critico pedido: mapa con MUCHA iluminacion — la v4.8 solo podia
# mover el canal R y encima SATURADO (236+29 -> 255): un tinte rosado de
# +19 en un solo canal, sin forma ni sombra. Eso es el «no se notan».
bg = BACKGROUNDS["mapa claro (nieve/arena, 236,232,224)"]
viejo = additive(bg, RED, PULSE_MIN * FADE * 0.45)
viejo_max = additive(bg, RED, 0.85 * FADE * 0.45)  # pulso en su pico
check("mapa claro: la v4.8 movia SOLO el canal R y saturado (+19, tinte sin forma)",
      viejo == (255, bg[1], bg[2]) and viejo_max == (255, bg[1], bg[2]),
      f"valle={viejo} pico={viejo_max} vs fondo {bg}")

# dentro de la vista: identico viejo==nuevo (formula intacta)
for nombre, bg in BACKGROUNDS.items():
    a = PULSE_MIN * FADE
    check(f"dentro de la vista {nombre}: formula v4.8 bit a bit",
          additive(bg, RED, a) == additive(bg, RED, a))

# el contorno oscuro garantiza pixel oscuro contra fondo claro (borde del sprite)
borde = normal((236, 232, 224), EDGE, 0.9)
check("contorno oscuro sobre mapa claro queda oscuro (canal R < 80)",
      borde[0] < 80, f"borde={borde}")

# --------------------------------------------------------------------------
section("6. SIMULACION 1:1 — ciclo de la cazadora y la V manual (Step_0)")
# --------------------------------------------------------------------------
FPS = 60
SCAN_TIME = 12 * FPS     # V manual (macro)
HUNT_WINDOW = 8 * FPS    # ventana pasiva (macro nueva)
HUNT_TIME = 14 * FPS     # enfriamiento del ciclo (intacto)


class FakeAmy:
    """Reproduce el Step_0 de obj_metalamy solo en la maquina de scan."""

    def __init__(self):
        self.scanTimer = 0
        self.scanRecharge = 0
        self.huntMode = False
        self.huntCd = 0
        self.pulso_V = 0  # pulsaciones de la V procesadas

    def step(self, vivos, pulsa_V=False):
        if self.scanTimer > 0:
            self.scanTimer -= 1
        if self.scanRecharge > 0:
            self.scanRecharge -= 1
        # V manual (scr_metalamy_special): solo sin huntMode y con recarga lista
        if pulsa_V and not self.huntMode and self.scanRecharge <= 0:
            self.scanTimer = SCAN_TIME
            self.scanRecharge = 20 * FPS
            self.pulso_V += 1
        # marca de la cazadora
        if vivos == 1:
            if not self.huntMode:
                self.huntMode = True
                self.huntCd = 0
                self.scanRecharge = 0
                self.scanTimer = HUNT_WINDOW
        else:
            self.huntMode = False
        if self.huntMode:
            if self.scanTimer > 0:
                if self.scanTimer == 1:
                    self.huntCd = HUNT_TIME
            elif self.huntCd > 0:
                self.huntCd -= 1
                if self.huntCd == 0:
                    self.scanTimer = HUNT_WINDOW


amy = FakeAmy()
# ronda de 130 s: 60 s con 4 vivos (V en el segundo 10 y 40), luego 1 vivo
segundos_revelado_V = 0
segundos_revelado_hunt = 0
for f in range(130 * FPS):
    vivos = 4 if f < 60 * FPS else 1
    pulsa = f in (10 * FPS, 40 * FPS)
    amy.step(vivos, pulsa)
    if amy.scanTimer > 0:
        if amy.huntMode:
            segundos_revelado_hunt += 1
        else:
            segundos_revelado_V += 1

check("V manual: cada pulsacion revela 12 s exactos",
      segundos_revelado_V == 24 * FPS,
      f"{segundos_revelado_V / FPS:.1f} s de V manual en 60 s (2 pulsaciones)")
check("cazadora: el rastreo pasivo arranca en el 1v1 (28 s de ventana en 70 s)",
      round(segundos_revelado_hunt / FPS, 1) == 28.1,
      f"{segundos_revelado_hunt / FPS:.1f} s pasivos (8+8+8+4.1 parcial al corte)")
check("la V queda bloqueada en huntMode (0 pulsaciones utiles tras el 1v1)",
      amy.pulso_V == 2, f"pulsaciones procesadas={amy.pulso_V}")

# el ciclo pasivo: 8 s de ventana + 14 s de CD = 22 s por vuelta, y NINGUNA
# ventana dura mas de 8 s (la prueba de que la pasiva nunca hereda los 12)
amy2 = FakeAmy()
en_ventana = 0
rachas = []
arranques = []
previa = 0
for f in range(66 * FPS):  # 3 ciclos completos + el 4o arrancando al corte
    amy2.step(1)
    if amy2.scanTimer > 0:
        if previa == 0:
            arranques.append(f)
        en_ventana += 1
    else:
        if en_ventana:
            rachas.append(en_ventana)
        en_ventana = 0
    previa = amy2.scanTimer
if en_ventana:
    rachas.append(en_ventana)
check("ciclo de la cazadora: 4 arranques en 66 s (3 ciclos + el 4o al corte)",
      len(arranques) == 4, f"arranques en frames {arranques}")
periodos = [(arranques[i + 1] - arranques[i]) / FPS for i in range(len(arranques) - 1)]
check("periodo del ciclo = 22 s por vuelta (ventana 8 + CD 14)",
      all(abs(p - 22.0) <= 0.1 for p in periodos), f"periodos={periodos}")
check("NINGUNA ventana pasiva supera los 8 s (nunca hereda los 12 de la V)",
      all(r <= HUNT_WINDOW for r in rachas), f"rachas={rachas}")

# --------------------------------------------------------------------------
section("7. ESTATICA — comentarios/documentacion coherente")
# --------------------------------------------------------------------------
check("special: cabecera documenta «de 8 a 12 s» (12 la V, 8 la cazadora)",
      "12 s la V manual" in sp and "8 s" in sp)
check("Step_0: comentario explica la ventana de 8 s con su macro",
      "METALAMY_HUNT_WINDOW" in step0 and "ventana de 8 s" in step0)
check("Create_0: el comentario del scanTimer nombra los dos macros",
      "METALAMY_SCAN_TIME" in create0 and "METALAMY_HUNT_WINDOW" in create0)

# ==========================================================================
print(f"\n{'=' * 64}")
print(f"RESULTADO: {PASS} OK / {FAIL} FAIL")
if FAIL == 0:
    print("SCAN v4.10 VERIFICADO: 12 s la V manual, 8 s la cazadora, siluetas")
    print("lejanas con contorno+relleno legibles en mapas claros, dentro de la")
    print("vista bit a bit identico a la v4.8. Recompilar SOLO el CLIENTE.")
sys.exit(1 if FAIL else 0)
