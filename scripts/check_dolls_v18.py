#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VALIDADOR v18 (DOLLS ACUMULATIVOS) — Sonicexe The Disaster 2D Remake
====================================================================
Chequea los 3 frentes de la ronda v18:

  1) AMELIA especial del portal trampa (kind 6):
     - Server: CH_AMELIA -> kind 6 (absorcion SIEMPRE) y PLAYER_CAUGHT 1-6.
     - Cliente: absorbVictim con spr_amelia_trapped, rango 1-6 en victima
       y en el ocultado del puppet, y su case en scr_jinna_capture_sprite.

  2) LA FILA DE MUNEcos (sprites acumulados lado a lado):
     - obj_jinna: arrays jinnaCaughtDolls / jinnaCaughtDollDelay en Create,
       cuenta atras en Step y el dibujo acumulado en Draw_0.
     - net_state_game: handler apila cada especial (con dedup) y manda el
       sprite de Amelia (spr_amelia_doll_placed).

  3) MEJORAS DIRECTAS ACUMULATIVAS ("+" en vez de cifra fija):
     - scr_jinna_special: macros JINNA_BONUS_* + scr_jinna_power().
     - Los 5 puntos de aplicacion usan base + scr_jinna_power() * macro:
       golpe (obj_player_puppet), agarre, trampa x2 y slow (net_state_game,
       obj_jinna_trap).
     - Los globals por especial (jinnaCaughtAmy/Sally/Vanilla/Amelia)
       viven en obj_netclient y se resetean en obj_level.
     - Cero referencias vivas al viejo global.jinnaCaughtTier.

Ademas verifica llaves/parentesis balanceados en todos los .gml tocados.
Uso:  python3 scripts/check_dolls_v18.py   (desde la raiz del proyecto)
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

CHECKS = []


def check(name, ok, detail=""):
    CHECKS.append((name, bool(ok), detail))


def read(path):
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        return None
    with open(full, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def balanced(text, path):
    """Balance de llaves/parentesis/corchetes ignorando strings y // comentarios."""
    depth = {"{": 0, "(": 0, "[": 0}
    pairs = {"}": "{", ")": "(", "]": "["}
    i, n = 0, len(text)
    in_str = in_line_comment = in_block_comment = False
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if in_line_comment:
            if c == "\n":
                in_line_comment = False
        elif in_block_comment:
            if c == "*" and nxt == "/":
                in_block_comment = False
                i += 1
        elif in_str:
            if c == "\\":
                i += 1
            elif c == '"':
                in_str = False
        else:
            if c == "/" and nxt == "/":
                in_line_comment = True
                i += 1
            elif c == "/" and nxt == "*":
                in_block_comment = True
                i += 1
            elif c == '"':
                in_str = True
            elif c in depth:
                depth[c] += 1
            elif c in pairs:
                depth[pairs[c]] -= 1
                if depth[pairs[c]] < 0:
                    return False, f"']' ')' '}}' de mas cerca de pos {i}"
        i += 1
    if in_str:
        return False, "string sin cerrar"
    if in_block_comment:
        return False, "comentario /* sin cerrar"
    leftover = {k: v for k, v in depth.items() if v != 0}
    if leftover:
        return False, f"sin cerrar: {leftover}"
    return True, ""


# ---------------------------------------------------------------------------
# 0) Sintaxis de todos los archivos tocados
# ---------------------------------------------------------------------------
GML_FILES = [
    "scripts/scr_jinna_special/scr_jinna_special.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_jinna_capture_sprite/scr_jinna_capture_sprite.gml",
    "objects/obj_jinna/Create_0.gml",
    "objects/obj_jinna/Step_0.gml",
    "objects/obj_jinna/Draw_0.gml",
    "objects/obj_jinna_trap/Step_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_netclient/Create_0.gml",
    "objects/obj_level/Create_0.gml",
    "objects/obj_jinna_absorb/Create_0.gml",
]
for path in GML_FILES:
    txt = read(path)
    if txt is None:
        check(f"[SINTAXIS] {path} existe", False, "ARCHIVO NO ENCONTRADO")
        continue
    ok, detail = balanced(txt, path)
    check(f"[SINTAXIS] llaves/parens balanceados — {os.path.basename(path)}", ok, detail)

# ---------------------------------------------------------------------------
# 1) SERVER: Amelia = kind 6
# ---------------------------------------------------------------------------
srv = read("betterserver-oss/disasterserver/states/Game.c")
check("[SERVER] kind 6 para CH_AMELIA",
      srv and re.search(r"else if \(v->surv_char == CH_AMELIA\)\s*\n\s*kind = 6;", srv) is not None)
check("[SERVER] PLAYER_CAUGHT cubre kinds 1-6",
      srv and "if (kind >= 1 && kind <= 6)" in srv)
check("[SERVER] comentario v18 de Amelia",
      srv and "kind 6 = AMELIA (v18)" in srv)

# ---------------------------------------------------------------------------
# 2) scr_jinna_special: macros + scr_jinna_power
# ---------------------------------------------------------------------------
spec = read("scripts/scr_jinna_special/scr_jinna_special.gml")
for macro in ["JINNA_BONUS_TRAP", "JINNA_BONUS_ATTACK", "JINNA_BONUS_GRAB", "JINNA_BONUS_SLOW"]:
    check(f"[MEJORAS] macro {macro} definido", spec and f"#macro {macro}" in spec)
check("[MEJORAS] funcion scr_jinna_power()",
      spec and "function scr_jinna_power()" in spec)
check("[MEJORAS] Amy Canon vale doble (_u += 2)",
      spec and re.search(r"if\(global\.jinnaCaughtAmy\)\s*_u \+= 2;", spec) is not None)
check("[MEJORAS] Sally/Vanilla/Amelia valen 1",
      spec and spec.count("_u += 1;") == 3)

# ---------------------------------------------------------------------------
# 3) Los 5 puntos de aplicacion usan SUMA (base + unidades * macro)
# ---------------------------------------------------------------------------
nsg = read("scripts/net_state_game/net_state_game.gml")
pup = read("objects/obj_player_puppet/Step_0.gml")
trap = read("objects/obj_jinna_trap/Step_0.gml")

check("[MEJORAS] agarre: base + power * GRAB",
      nsg and "JINNA_GRAB_DAMAGE + scr_jinna_power() * JINNA_BONUS_GRAB" in nsg)
check("[MEJORAS] trampa (TP victima): base + power * TRAP",
      nsg and "JINNA_TRAP_DAMAGE + scr_jinna_power() * JINNA_BONUS_TRAP" in nsg)
check("[MEJORAS] slow del teleport: base + power * SLOW",
      nsg and "JINNA_TELE_SLOW_TIME + scr_jinna_power() * JINNA_BONUS_SLOW" in nsg)
check("[MEJORAS] trampa (calculo fatal): base + power * TRAP",
      trap and "JINNA_TRAP_DAMAGE + scr_jinna_power() * JINNA_BONUS_TRAP" in trap)
check("[MEJORAS] golpe basico: damage += power * ATTACK",
      pup and "damage += scr_jinna_power() * JINNA_BONUS_ATTACK;" in pup)

# y que NO queden formulas fijas del tier viejo
for path, txt in [("net_state_game", nsg), ("obj_jinna_trap", trap), ("obj_player_puppet", pup)]:
    legacy = re.findall(r"jinnaCaughtTier", txt or "")
    check(f"[MEJORAS] {path} sin jinnaCaughtTier vivo", len(legacy) == 0, f"{len(legacy)} restos")
    fixed = re.findall(r"\? 22 :|18 : JINNA_TRAP_DAMAGE|\? 30 : 25|4\.5 :|3\.75 :", txt or "")
    check(f"[MEJORAS] {path} sin cifras fijas viejas", len(fixed) == 0, str(fixed))

# ---------------------------------------------------------------------------
# 4) Globals por especial: declaracion + reset por ronda
# ---------------------------------------------------------------------------
netc = read("objects/obj_netclient/Create_0.gml")
lvl = read("objects/obj_level/Create_0.gml")
for g in ["global.jinnaCaughtAmy", "global.jinnaCaughtSally",
          "global.jinnaCaughtVanilla", "global.jinnaCaughtAmelia"]:
    check(f"[GLOBALS] {g} en obj_netclient", netc and f"{g} = false" in netc)
    check(f"[GLOBALS] {g} se resetea en obj_level", lvl and f"{g} = false" in lvl)

# ---------------------------------------------------------------------------
# 5) Handler: flags + fila de munecos + dedup + kind 6
# ---------------------------------------------------------------------------
check("[HANDLER] flags por especial (kinds 1/2/3/6)",
      nsg and "global.jinnaCaughtVanilla = true" in nsg
      and "global.jinnaCaughtAmy = true" in nsg
      and "global.jinnaCaughtSally = true" in nsg
      and "global.jinnaCaughtAmelia = true" in nsg)
check("[HANDLER] muneco de Amelia = spr_amelia_doll_placed",
      nsg and "spr_amelia_doll_placed" in nsg)
check("[HANDLER] apila en la fila (array_push dolls + delay)",
      nsg and "array_push(obj_jinna.jinnaCaughtDolls," in nsg
      and "array_push(obj_jinna.jinnaCaughtDollDelay," in nsg)
check("[HANDLER] dedup defensivo de la fila",
      nsg and "_haveDoll" in nsg)
check("[HANDLER] Rouge/generica sin mejoras (solo fantasma)",
      nsg and "else if(_hkind == 4 || _hkind == 5)" in nsg)
check("[HANDLER] victima: rango de absorcion 1-6",
      nsg and "_hkind >= 1 && _hkind <= 6" in nsg)
check("[HANDLER] absorbVictim con spr_amelia_trapped (kind 6)",
      nsg and "(_hkind == 6) ? spr_amelia_trapped" in nsg)
check("[HANDLER] puppet oculto tambien con kind 6",
      nsg and nsg.count("_hkind >= 1 && _hkind <= 6") >= 2)
check("[HANDLER] delay de la fila = 102 frames",
      nsg and "array_push(obj_jinna.jinnaCaughtDollDelay, 102)" in nsg)

# ---------------------------------------------------------------------------
# 6) obj_jinna: Create / Step / Draw de la fila
# ---------------------------------------------------------------------------
crt = read("objects/obj_jinna/Create_0.gml")
stp = read("objects/obj_jinna/Step_0.gml")
drw = read("objects/obj_jinna/Draw_0.gml")
check("[JINNA] Create: arrays de la fila", crt and "jinnaCaughtDolls = []" in crt
      and "jinnaCaughtDollDelay = []" in crt)
check("[JINNA] Step: cuenta atras de cada muneco",
      stp and "jinnaCaughtDollDelay[_jd]--" in stp)
check("[JINNA] Draw: fila acumulada lado a lado",
      drw and "array_length(jinnaCaughtDolls)" in drw
      and "sprite_get_width(_js)" in drw)
check("[JINNA] Draw: la fila manda sobre el fantasma individual",
      drw and "_dollShown > 0" in drw)
check("[JINNA] Draw: se salta los munecos aun en espera",
      drw and "continue;" in drw)

# ---------------------------------------------------------------------------
# 7) scr_jinna_capture_sprite: Amelia con su arte propio
# ---------------------------------------------------------------------------
cap = read("scripts/scr_jinna_capture_sprite/scr_jinna_capture_sprite.gml")
check("[RELEVO] Amelia -> spr_amelia_trapped",
      cap and re.search(r"case CHARACTER_AMELIA:\s*\n\s*return spr_amelia_trapped;", cap) is not None)

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------
fails = [c for c in CHECKS if not c[1]]
print("=" * 72)
for name, ok, detail in CHECKS:
    print(f"  {'OK ' if ok else 'FAIL'}  {name}" + (f"   -> {detail}" if (detail and not ok) else ""))
print("=" * 72)
print(f"RESULTADO: {len(CHECKS) - len(fails)}/{len(CHECKS)} OK"
      + ("" if not fails else f"  |  {len(fails)} FALLA(N): " + ", ".join(f[0] for f in fails)))
sys.exit(0 if not fails else 1)
