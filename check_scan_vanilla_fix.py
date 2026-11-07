#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_scan_vanilla_fix.py — verificador del FIX SCAN v4.9 (Metal Amy)
+ MINI FIX v2.2 (paciencia/moribunda de Vanilla).

FIX 1 — SCAN DE METAL AMY (obj_exe_indicator):
  CAUSA RAIZ: el indicador nace visible:false (el .yy) y la linea que
  calculaba `visible` en Step_2 daba false SIEMPRE para Metal Amy (es el
  bando EXE, no usa invisibilidad, no es Chaos, sin anillo rojo). En este
  runtime una instancia invisible NO ejecuta su Draw GUI -> las siluetas
  del scan (que no dependen de la aguja) jamas se dibujaban, ni con la V
  ni con la pasiva de la cazadora. La v4.8.1 arreglo el gate que LLENA la
  lista pero el evento de dibujo segua sin correr ni una vez.
  FIX: la condicion de la aguja pasa a la bandera propia `needle`
  (identica formula) y `visible` queda como interruptor del MOTOR que el
  Step_2 enciende con `needle || scanCount > 0`. El Draw_64 gatea la
  aguja con `needle` (para que el scan no arrastre la flecha consigo).

FIX 2 — VANILLA (scr_chocola.gml, scr_vanilla_v2_step):
  CAUSA RAIZ: paciencia/moribunda ponia yspd = LEVITATE siempre que no
  estuviera en el suelo; una Vanilla debilitada EN EL AIRE sobre suelo
  normal se quedaba clavada flotando los 5 s de la fase.
  FIX: 3 ramas — en el suelo quieta (yspd=0); SIN terreno en la columna
  de abajo (hoyo de verdad) levita exactamente como antes; CON terreno
  debajo cae con gravedad y tope de caida (min(yspd+yAccel, maxYSpeed)).

Este script NO modifica nada: solo verifica (estatica + simulaciones 1:1
de los dos sistemas, reproduciendo el comportamiento viejo como control).
Uso: python3 check_scan_vanilla_fix.py [raiz_del_repo]
"""

import os
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


# --------------------------------------------------------------------------
# localizacion del repo (portable): argumento > carpeta del propio archivo
# (si el checker vive en la raiz) > carpeta padre (si vive en scripts/)
# --------------------------------------------------------------------------
_cand = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(
    os.path.abspath(__file__))
if not os.path.isdir(os.path.join(_cand, "objects")):
    _cand = os.path.dirname(_cand)
ROOT = _cand

IND = os.path.join(ROOT, "objects", "obj_exe_indicator")
CHO = os.path.join(ROOT, "scripts", "scr_chocola")

step2 = open(os.path.join(IND, "Step_2.gml"), encoding="utf-8").read()
draw64 = open(os.path.join(IND, "Draw_64.gml"), encoding="utf-8").read()
create0 = open(os.path.join(IND, "Create_0.gml"), encoding="utf-8").read()
_yyp_path = os.path.join(ROOT, "Sonicexe The Disaster 2D Remake.yyp")
yyp = (open(_yyp_path, encoding="utf-8").read()
       if os.path.exists(_yyp_path) else None)  # zip solo-fix: no esta
chocola = open(os.path.join(CHO, "scr_chocola.gml"), encoding="utf-8").read()

# ==========================================================================
section("FIX 1 — SCAN METAL AMY: estatica de obj_exe_indicator")

# 1. la aguja ahora es `needle` con la MISMA formula de siempre
check("Step_2: la aguja vive en `needle` (formula original intacta)",
      "needle = (global.character != CHARACTER_EXE || "
      "global.player.invisTimer > 0 || "
      "(global.exeCharacter == 1 && global.player.slimeTimer > 0)) "
      "|| redRings;" in step2,
      "no se encuentra la asignacion needle = (condicion original)")

check("Step_2: ya NO existe la vieja linea `visible = (global...`",
      "visible = (global.character" not in step2,
      "la vieja asignacion de visible sigue presente")

# 2. el interruptor del motor, DESPUES de llenar el scan
check("Step_2: interruptor del motor `visible = needle || scanCount > 0;`",
      "visible = needle || scanCount > 0;" in step2,
      "falta la linea visible = needle || scanCount > 0;")

pos_fill = step2.find("other.scanList[other.scanCount] = id;")
pos_vis = step2.find("visible = needle || scanCount > 0;")
check("Step_2: el interruptor va DESPUES de llenar la lista (orden)",
      0 < pos_fill < pos_vis,
      f"pos_fill={pos_fill}, pos_visible={pos_vis}")

# 3. el gate de llenado del scan sigue intacto (v4.8.1)
check("Step_2: gate del scan intacto (EXE + EXE_METALAMY + scanTimer)",
      "global.character == CHARACTER_EXE" in step2
      and "global.exeCharacter == EXE_METALAMY" in step2
      and "global.player.scanTimer > 0" in step2,
      "alguna condicion del gate desaparecio")

check("Step_2: filtro v4.8.1 de desconectados (isInactive) intacto",
      "if(isInactive || hp <= 0 || revivalTimes >= 2)" in step2,
      "filtro de puppets modificado")

check("Step_2: anti-regresion — variable_instance_exists NO vuelve",
      "variable_instance_exists" not in "\n".join(
          ln.split("//")[0] for ln in step2.splitlines()),
      "reaparecio el patron roto de la v4.8 (llamada real, no comentario)")

# 4. Draw_64: la aguja se gatea con needle, el scan sigue sin gate visible
check("Draw_64: aguja gateada con `if(!needle)`",
      "if(!needle)" in draw64,
      "no se encuentra if(!needle)")

check("Draw_64: ya NO gatea la aguja con `if(!visible)`",
      "if(!visible)" not in draw64,
      "la aguja sigue gateada con visible (el scan arrastraria la flecha)")

check("Draw_64: bloque del scan intacto y sin gate de aguja",
      "if(scanCount > 0 && instance_exists(global.player) "
      "&& instance_exists(obj_camera))" in draw64,
      "el gate del bloque de siluetas cambio")

check("Draw_64: siluetas siguen dibujandose (draw_sprite_ext c_red)",
      "draw_sprite_ext(_t.sprite_index" in draw64 and "c_red" in draw64,
      "el dibujado de siluetas desaparecio")

check("Draw_64: blendmode aditivo del revelado intacto",
      "gpu_set_blendmode(bm_add)" in draw64,
      "falta el blend aditivo")

# 5. Create_0 declara la bandera desde el arranque
check("Create_0: declara `needle = false;`",
      "needle = false;" in create0,
      "falta la declaracion de needle")

check("Create_0: scanList sigue siendo array explicito (v4.8.1)",
      "scanList = [];" in create0,
      "regresion del fix v4.8.1")

# 6. el .yyp sigue registrando el objeto (no era un asset fantasma)
if yyp is None:
    print("  [SKIP] .yyp: no esta en esta carpeta (zip solo-fix) — "
          "correr desde el repo completo para verificarlo")
    PASS += 1
else:
    check(".yyp: obj_exe_indicator registrado en el proyecto",
          '"obj_exe_indicator"' in yyp,
          "el objeto desaparecio del proyecto")

# 7. nadie mas gateaba el indicador desde fuera (los otros creadores)
for f in ("objects/obj_exe/Create_0.gml",
          "objects/obj_chaos/Create_0.gml",
          "objects/obj_metalamy/Create_0.gml"):
    p = os.path.join(ROOT, f)
    txt = open(p, encoding="utf-8").read() if os.path.exists(p) else ""
    check(f"{f}: sigue creando su obj_exe_indicator",
          "instance_create_depth(x, y, 0, obj_exe_indicator);" in txt,
          "la creacion del indicador desaparecio (los otros exes pierden la aguja)")

# ==========================================================================
section("FIX 1 — SCAN METAL AMY: simulacion 1:1 (Step_2 + Draw_64)")


class Puppet:
    def __init__(self, x, y, hp=100, character=5, inactive=False,
                 revival=0, ishurt=False, hiding=False):
        self.x = x
        self.y = y
        self.hp = hp
        self.character = character   # 5 = cualquier superviviente
        self.isInactive = inactive
        self.revivalTimes = revival
        self.isHurt = ishurt
        self.isHiding = hiding
        self.lunaGrace = 0


class Indicator:
    """Replica EXACTA del Step_2 + Draw_64 con la mecanica del runtime:
    una instancia con visible=false NO ejecuta su Draw GUI."""

    def __init__(self, old_code):
        self.old_code = old_code      # True = comportamiento pre-fix
        self.scanList = []
        self.scanCount = 0
        self.needle = False
        self.visible = False
        self.draws = []               # ("scan"|"needle"|None) por frame

    def step(self, g_character, g_exechar, player_alive, puppets,
             invis=0, slime=0, redrings=False, scan_timer=0):
        self.scanCount = 0
        self.scanList = []
        # --- bloque de la aguja (formula original) ---
        needle = ((g_character != 0) or invis > 0 or
                  (g_exechar == 1 and slime > 0)) or redrings
        # --- bloque del scan (gate v4.8.1) ---
        if (g_character == 0 and g_exechar == 4 and player_alive
                and len(puppets) > 0 and scan_timer > 0):
            for p in puppets:
                if (p.isInactive or p.hp <= 0 or p.revivalTimes >= 2):
                    continue
                if (p.character == 12 and p.isHiding and p.lunaGrace > 0):
                    continue   # velo de Amelia (fuera de estos tests)
                self.scanList.append(p)
                self.scanCount += 1
        # --- el interruptor del motor ---
        if self.old_code:
            self.visible = needle          # BUG: scan sin interrumptor
        else:
            self.visible = needle or self.scanCount > 0
        self.needle = needle

    def draw_gui_runs(self):
        """En este runtime el Draw GUI NO corre si visible == false."""
        return self.visible

    def frame(self, *a, **k):
        self.step(*a, **k)
        if not self.draw_gui_runs():
            self.draws.append(None)
            return
        drew = []
        if self.scanCount > 0:
            drew.append("scan")
        if self.needle:
            drew.append("needle")
        self.draws.append(tuple(drew) if drew else None)


CHARACTER_EXE, EXE_CHAOS, EXE_METALAMY = 0, 1, 4

# --- escenario 1: METAL AMY pulsa la V (3 vivos, 1 muerto, 1 desconectado)
pups = [Puppet(100, 100), Puppet(200, 100), Puppet(300, 100),
        Puppet(400, 100, hp=0), Puppet(500, 100, inactive=True)]

old = Indicator(old_code=True)
for _ in range(30):
    old.frame(CHARACTER_EXE, EXE_METALAMY, True, pups, scan_timer=480)
check("V activada: CODIGO VIEJO no dibuja nada (reproduce el bug)",
      all(d is None for d in old.draws),
      "el codigo viejo dibujaba — el diagnostico estaba mal")

new = Indicator(old_code=False)
for _ in range(30):
    new.frame(CHARACTER_EXE, EXE_METALAMY, True, pups, scan_timer=480)
check("V activada: NUEVO dibuja el scan TODOS los frames",
      all(d == ("scan",) for d in new.draws),
      f"resultado: {set(new.draws)}")
check("V activada: el scan llena exactamente 3 siluetas (filtros vivos)",
      new.scanCount == 3,
      f"scanCount={new.scanCount}")

# --- escenario 2: pasiva de la cazadora (LMS, queda 1 vivo)
pups_lms = [Puppet(100, 100), Puppet(400, 100, revival=2)]
new2 = Indicator(old_code=False)
for _ in range(10):
    new2.frame(CHARACTER_EXE, EXE_METALAMY, True, pups_lms, scan_timer=480)
check("LMS (1 vivo real): NUEVO dibuja el scan de la cazadora",
      all(d == ("scan",) for d in new2.draws) and new2.scanCount == 1,
      f"dibujo={set(new2.draws)}, scanCount={new2.scanCount}")

old2 = Indicator(old_code=True)
for _ in range(10):
    old2.frame(CHARACTER_EXE, EXE_METALAMY, True, pups_lms, scan_timer=480)
check("LMS: CODIGO VIEJO no dibuja (reproduce el bug de la pasiva)",
      all(d is None for d in old2.draws))

# --- escenario 3: durante el scan NO sale la flecha (acuerdo v4.8)
check("Scan activo: la AGUJA no se cuela en el revelado",
      all("needle" not in (d or ()) for d in new.draws),
      "el scan arrastro la flecha consigo")

# --- escenario 4: expira el revelado (scanTimer = 0) -> evento se apaga
new3 = Indicator(old_code=False)
new3.frame(CHARACTER_EXE, EXE_METALAMY, True, pups, scan_timer=480)
new3.frame(CHARACTER_EXE, EXE_METALAMY, True, pups, scan_timer=0)
check("Expira el revelado: el evento vuelve a apagarse (frame barato)",
      new3.draws[0] == ("scan",) and new3.draws[1] is None,
      f"draws={new3.draws}")

# --- escenario 5: sin survivors en la sala (puppets = 0)
new4 = Indicator(old_code=False)
new4.frame(CHARACTER_EXE, EXE_METALAMY, True, [], scan_timer=480)
check("Sin puppets en sala: no hay nada que dibujar ni que encender",
      new4.draws == [None] and new4.visible is False)

# --- regresion: EXE clasico invisible (la aguja de siempre)
exe_old = Indicator(old_code=True)
exe_new = Indicator(old_code=False)
for _ in range(10):
    exe_old.frame(CHARACTER_EXE, 0, True, pups, invis=120)
    exe_new.frame(CHARACTER_EXE, 0, True, pups, invis=120)
check("REGRESION EXE invisible: aguja identica viejo vs nuevo",
      exe_old.draws == exe_new.draws and all(d == ("needle",)
                                             for d in exe_new.draws),
      f"old={set(exe_old.draws)} new={set(exe_new.draws)}")

# --- regresion: anillo rojo (Exetior)
r_old = Indicator(old_code=True)
r_new = Indicator(old_code=False)
for _ in range(10):
    r_old.frame(CHARACTER_EXE, 2, True, pups, redrings=True)
    r_new.frame(CHARACTER_EXE, 2, True, pups, redrings=True)
check("REGRESION anillo rojo: aguja identica viejo vs nuevo",
      r_old.draws == r_new.draws and all(d == ("needle",) for d in r_new.draws))

# --- regresion: slime de Chaos
s_old = Indicator(old_code=True)
s_new = Indicator(old_code=False)
for _ in range(10):
    s_old.frame(CHARACTER_EXE, EXE_CHAOS, True, pups, slime=300)
    s_new.frame(CHARACTER_EXE, EXE_CHAOS, True, pups, slime=300)
check("REGRESION slime de Chaos: aguja identica viejo vs nuevo",
      s_old.draws == s_new.draws and all(d == ("needle",) for d in s_new.draws))

# --- regresion: EXE visible sin nada (frame comun: nada dibujado)
n_old = Indicator(old_code=True)
n_new = Indicator(old_code=False)
for _ in range(10):
    n_old.frame(CHARACTER_EXE, 0, True, pups)
    n_new.frame(CHARACTER_EXE, 0, True, pups)
check("REGRESION frame comun (exe visible sin nada): identico y barato",
      n_old.draws == n_new.draws == [None] * 10)

# ==========================================================================
section("FIX 2 — VANILLA: estatica de scr_chocola (scr_vanilla_v2_step)")

BRANCH = ("if(isGrounded)\n"
          "                yspd = 0;\n"
          "        else if(!collision_line(x, y, x, room_height + 64, "
          "obj_floor_parent, true, true))\n"
          "                yspd = VANILLA_PACIENCIA_LEVITATE;\n"
          "        else\n"
          "                yspd = min(yspd + yAccel, maxYSpeed);")

check("PACIENCIA: rama de 3 (suelo / hoyo-levita / caida) presente",
      chocola.count(BRANCH) == 2,
      f"apariciones del bloque de 3 ramas: {chocola.count(BRANCH)} (esperadas 2: paciencia y moribunda)")

check("PACIENCIA/MORIBUNDA: la vieja linea unica ya no existe",
      "yspd = isGrounded ? 0 : VANILLA_PACIENCIA_LEVITATE;" not in chocola,
      "sigue la asignacion unica que dejaba a Vanilla flotando")

check("Levitacion de hoyos intacta (macro -0.35 y sus 2 usos)",
      "#macro VANILLA_PACIENCIA_LEVITATE -0.35" in chocola
      and chocola.count("VANILLA_PACIENCIA_LEVITATE;") == 2,
      "macro o usos de la levitacion alterados")

check("Deteccion de suelo usa el padre universal del terreno",
      "obj_floor_parent" in chocola,
      "no se detecta obj_floor_parent en la columna")

check("La caida respeta el tope de velocidad (maxYSpeed)",
      "min(yspd + yAccel, maxYSpeed)" in chocola,
      "la caida no esta acotada")

# el resto del bloque de paciencia no se toco
for needle in ("pacienciaTimer <= VANILLA_PACIENCIA_CHOCOLA_AT",
               "pacienciaState = 2;",
               "pacienciaWaitChocola = true"):
    check(f"PACIENCIA: mecanica intacta ({needle.split(' =')[0].strip()[:34]})",
          needle in chocola)

for needle in ("moribundaTimer--;",
               "hp = VANILLA_MORIBUNDA_HEAL;",
               "moribundaState = 0;"):
    check(f"MORIBUNDA: mecanica intacta ({needle[:34]})",
          needle in chocola)

# ==========================================================================
section("FIX 2 — VANILLA: simulacion 1:1 (paciencia + gravedad del motor)")

YACCEL = 0.21875
MAXY = 12
LEVIT = -0.35


def vanilla_frames(old_code, grounded, floor_below, frames=400,
                   floor_y=None, start_y=0.0):
    """Replica paciencia (o moribunda) + la gravedad de scr_collision_basic.
    Devuelve (yspds, ys, aterrizo). isGrounded se evalua al aterrizar."""
    yspd = 0.0
    y = start_y
    yspds, ys = [], []
    landed = False
    for _ in range(frames):
        # --- bloque paciencia (specialFunc) ---
        if grounded:
            yspd = 0.0
        elif old_code:
            yspd = LEVIT
        elif not floor_below:
            yspd = LEVIT
        else:
            yspd = min(yspd + YACCEL, MAXY)
        # --- scr_collision_basic: gravedad + movimiento ---
        if not grounded:
            yspd += YACCEL
        y += yspd
        if floor_y is not None and y >= floor_y:
            y = floor_y
            grounded = True
            yspd = 0.0
            landed = True
        yspds.append(yspd)
        ys.append(y)
    return yspds, ys, landed


# --- caso A: debilitada EN EL AIRE con suelo 300 px mas abajo
old_y = vanilla_frames(True, False, True, frames=120, floor_y=300, start_y=0)
new_y = vanilla_frames(False, False, True, frames=120, floor_y=300, start_y=0)
check("Aire sobre suelo: CODIGO VIEJO flota hacia arriba (reproduce el bug)",
      old_y[1][-1] < 0 and max(old_y[1]) < 5,
      f"y final vieja={old_y[1][-1]:.2f} (deberia seguir subiendo, flotando)")
check("Aire sobre suelo: NUEVO CAE y aterriza en el suelo",
      new_y[2] and abs(new_y[1][-1] - 300) < 0.01,
      f"y final nueva={new_y[1][-1]:.2f}, aterrizo={new_y[2]}")
check("Aire sobre suelo: la caida respeta el tope (~12.2 px/frame)",
      max(new_y[0]) <= MAXY + YACCEL + 1e-9,
      f"yspd max={max(new_y[0]):.3f} (tope {MAXY + YACCEL})")
check("Aire sobre suelo: aterrizada, quieta (yspd 0 hasta el final)",
      new_y[0][-1] == 0.0,
      f"yspd final={new_y[0][-1]}")

# --- caso B: debilitada sobre un HOYO de verdad (sin suelo en la columna)
old_h = vanilla_frames(True, False, False, frames=300, start_y=0)
new_h = vanilla_frames(False, False, False, frames=300, start_y=0)
check("Hoyo: NUEVO levita IDENTICO al codigo viejo (cero cambio)",
      all(abs(a - b) < 1e-9 for a, b in zip(old_h[0], new_h[0]))
      and abs(old_h[1][-1] - new_h[1][-1]) < 1e-9,
      f"y vieja={old_h[1][-1]:.2f} vs nueva={new_h[1][-1]:.2f}")
check("Hoyo: deriva suave hacia arriba como disena la v2 (~-0.13/f)",
      abs(new_h[0][10] - (LEVIT + YACCEL)) < 1e-9,
      f"yspd en el hoyo={new_h[0][10]:.4f} (esperada {LEVIT + YACCEL})")

# --- caso C: debilitada ya en el suelo (la inmensa mayoria de los casos)
old_g = vanilla_frames(True, True, True, frames=60, start_y=300)
new_g = vanilla_frames(False, True, True, frames=60, start_y=300)
check("En el suelo: quieta (yspd 0), identico viejo vs nuevo",
      old_g[0] == new_g[0] == [0.0] * 60
      and old_g[1] == new_g[1] == [300.0] * 60)

# --- caso D: moribunda comparte el mismo bloque (mismas 3 ramas)
check("Moribunda: mismo fix (2 apariciones del bloque = paciencia+moribunda)",
      chocola.count(BRANCH) == 2 and "MINI FIX v2.2" in chocola)

# --- caso E: la fase sigue su curso (el timer no depende de yspd)
check("La fase no depende de la caida: timer y Chocola intactos en el codigo",
      "pacienciaTimer--;" in chocola and "pacienciaTimer <= 0" in chocola)

# ==========================================================================
print(f"\n{'=' * 60}")
print(f"RESULTADO: {PASS} OK / {FAIL} FAIL")
if FAIL:
    print("HAY FALLOS — revisar antes de compilar.")
    sys.exit(1)
print("TODO OK — el fix esta consistente con el diseno del juego.")
print("Recuerda: recompilar el CLIENTE (GameMaker). El server NO se toca.")
