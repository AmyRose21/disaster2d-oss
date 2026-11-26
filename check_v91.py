#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v91.py — PASADA 1 de verificacion de la v91 (Rouge: modo visible + glide coyote).

Uso:  python3 check_v91.py <RAIZ_DEL_PROYECTO>
      (por defecto RAIZ = directorio de este script. El contrato es pasar la
      raiz como argumento — leccion v90 pasada 2: una herramienta de
      verificacion JAMAS adivina su objetivo desde su propia ubicacion.)

Verifica los 2 archivos de juego tocados por la v91 (y SOLO esos):
  objects/obj_rouge/Draw_64.gml                     (nombre de modalidad visible)
  scripts/scr_rouge_special/scr_rouge_special.gml   (el planeo respeta el coyote)

Secciones:
  S1  Estructura de Draw_64.gml (bloque v91 + resto intacto)
  S2  Estructura de scr_rouge_special.gml (guard de coyote en el planeo)
  S3  Simulacion de frames (mini-interprete OLD vs NEW: reproduce el bug y el fix)
  S4  Seguridad estatica (UTF-8/LF, balance de llaves, .yyp/.yy intactos)
  S5  Anti-cheat / superficie de red (regla de oro 7: cero paquetes nuevos)
  S6  Paridad de familia (mismo guard que su vuelo activo y que el planeo de Knux)

Sale con exit 0 solo si TODOS los checks pasan.
"""

import difflib
import io
import os
import re
import subprocess
import sys

PASS = 0
FAIL = 0
FAILURES = []


def check(section, name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print("  [OK]   %-64s" % name)
    else:
        FAIL += 1
        FAILURES.append("%s :: %s %s" % (section, name, detail))
        print("  [FAIL] %-64s %s" % (name, detail))


def section(title):
    print("\n=== %s ===" % title)


# ---------------------------------------------------------------------------
# Cadenas EXACTAS que la v91 debe dejar en los archivos (fuente de verdad).
# El bloque nuevo de Draw_64 usa TABS; scr_rouge_special usa 8 ESPACIOS.
# ---------------------------------------------------------------------------

V91_MODE_BANNER = "// v91 (duena) \u2014 MODALIDAD ACTIVA (HABILIDAD V): REWORK DE VISIBILIDAD."
V91_MODE_SCALE = "\tvar _modeScale = 0.6 + 0.1 * min(modeFlash / 12, 1);"
V91_MODE_ALPHA = "\tvar _modeAlpha = modeFlash > 0 ? 1 : 0.9;"
V91_MODE_X = "\tvar _modeX = ceil(x - obj_camera.x);"
V91_MODE_Y = "\tvar _modeY = ceil(y - obj_camera.y) - offset + 12;"

# Los 8 offsets del contorno (4 cardinales + 4 diagonales), sin indentar
OUTLINE_OFFSETS = [
    "_modeX + 1, _modeY,", "_modeX - 1, _modeY,",
    "_modeX, _modeY + 1,", "_modeX, _modeY - 1,",
    "_modeX + 1, _modeY + 1,", "_modeX - 1, _modeY + 1,",
    "_modeX + 1, _modeY - 1,", "_modeX - 1, _modeY - 1,",
]
OUTLINE_CALL = ("\tdraw_text_transformed_color(%s _modeName, _modeScale, _modeScale, 0, "
                "c_black, c_black, c_black, c_black, _modeAlpha);")
COLOR_CALL = ("\tdraw_text_transformed_color(_modeX, _modeY, _modeName, _modeScale, "
              "_modeScale, 0, _modeCol, _modeCol, _modeCol, _modeCol, _modeAlpha);")
OLD_V32_ALPHA = "modeFlash > 0 ? 1 : 0.55"

MODE_NAMES_AND_COLORS = [
    ('"ROUGE"', "$F2A0C8"),
    ('"EGGMAN"', "$FFD24A"),
    ('"SOPORTE"', "$6EDD62"),
    ('"ATAQUE"', "$FF8A3D"),
]

V91_GLIDE_BANNER = "// v91 (duena) \u2014 EL PLANEO RESPETA EL TIEMPO DE COYOTE"
GLIDE_GUARD_LINE = ('        && !(variable_instance_exists(id, "coyoteTimer") '
                    '&& coyoteTimer > 0 && yspd >= 0))')
FAMILY_GUARD_CORE = ('!(variable_instance_exists(id, "coyoteTimer") '
                     '&& coyoteTimer > 0 && yspd >= 0)')
GLIDE_ACTIVATION_HEAD = ("        if(global.playerControls && !isGrounded && !isGliding "
                         "&& !isFlying && !isAttacking")
GLIDE_ACTIVATION_Z = "        && !isStuck && yspd > 0 && keyboard_check(global.KeyA)"
GLIDE_BODY = """                isGliding = true;
                isJumping = false;
                isSpinning = false;
                spinDashRelease = false;
                glide_xspd = image_xscale * ROUGE_GLIDE_SPD;"""
GLIDE_ACTIVE_FROZEN = """        if(isGliding)
        {
                // puerta del agarre de pared abierta mientras planea
                glideTimer = 1;"""

NET_TOKENS = ["cpacket", "buffer_write", "send_server", "send_tcp", "send_udp",
              "net_sound", "CLIENT_", "SERVER_", "PacketType", "net_state",
              "obj_netclient", "obj_netserver"]


def read(root, rel):
    path = os.path.join(root, rel)
    if not os.path.isfile(path):
        return None
    with io.open(path, "r", encoding="utf-8") as fh:
        return fh.read()


def git_show(root, rel):
    """Best-effort: contenido del archivo en origin/main (None si no hay git/ref)."""
    try:
        proc = subprocess.run(["git", "-C", root, "show", "origin/main:" + rel],
                              capture_output=True, timeout=30)
        if proc.returncode == 0:
            return proc.stdout.decode("utf-8", "replace")
    except Exception:
        pass
    return None


def git_status_porcelain(root):
    """Best-effort git status --porcelain -> [(xy, path), ...]. Sin strip global
    (leccion v90 pasada 2: el XY code tiene espacios iniciales significativos)."""
    try:
        proc = subprocess.run(["git", "-C", root, "status", "--porcelain"],
                              capture_output=True, timeout=30)
        if proc.returncode != 0:
            return None
        out = []
        for line in proc.stdout.decode("utf-8", "replace").split("\n"):
            if not line.strip():
                continue
            m = re.match(r"^(..)\s+(.+?)\s*$", line)
            if m:
                out.append((m.group(1), m.group(2).strip()))
        return out
    except Exception:
        return None

def strip_gml(code):
    """Quita comentarios y literales \"...\" para contar llaves/parens con seguridad."""
    out = []
    i, n = 0, len(code)
    in_str = False
    while i < n:
        c = code[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            i += 1
            continue
        if c == "/" and i + 1 < n and code[i + 1] == "/":
            while i < n and code[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and code[i + 1] == "*":
            i += 2
            while i + 1 < n and not (code[i] == "*" and code[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def balance(code):
    s = strip_gml(code)
    return s.count("{") - s.count("}"), s.count("(") - s.count(")")


def added_lines(old, new):
    """Lineas NUEVAS (que empiezan con '+' y no son el header del diff)."""
    if old is None:
        return []
    return [l for l in difflib.unified_diff(old.split("\n"), new.split("\n"),
                                            lineterm="", n=0)
            if l.startswith("+") and not l.startswith("+++")]


# ---------------------------------------------------------------------------
# S3 — Mini-interprete: el orden REAL del bucle de Step_0 reproducido.
#
# Orden por frame (verificado contra el codigo real):
#   1. specialFunc()  (scr_move_basic L786)  -> activacion del planeo (guard
#      OLD vs NEW) + bloque del planeo ACTIVO (pisa yspd TODOS los frames)
#   2. coyote update  (scr_move_basic L796-798) -> suelo: refill 10 / aire: -1
#   3. salto          (scr_move_basic L835+)   -> pressed Z, !isJumping,
#      (isGrounded || (coyoteTimer > 0 && yspd >= 0 && !isZipline)) y
#      guards de Rouge -> isJumping = true, yspd = -jumpForce, coyoteTimer = 0
#   4. colision       (scr_collision_basic)   -> aire: yspd += yAccel
#      (y el vuelo activo, si lo hay, mantiene su yspd propio)
# ---------------------------------------------------------------------------

Y_ACCEL = 0.21875          # Create_0 de obj_rouge
JUMP_FORCE = 6.5           # Create_0 de obj_rouge
PLAYER_COYOTE_FRAMES = 10  # scr_move_basic L10
GLIDE_FALL = 0.7922        # ROUGE_GLIDE_FALL (Create_0)
ROUGE_FLY_RISE = -3.5      # ROUGE_FLY_RISE (Create_0)


def sim_frame(st, z_pressed, z_held, new_guard):
    events = []

    # 1a. activacion del planeo (guard OLD = sin linea coyote / NEW = con ella)
    if (st["controls"] and not st["isGrounded"] and not st["isGliding"]
            and not st["isFlying"] and not st["isAttacking"] and not st["isHurt"]
            and not st["isDead"] and st["shocked"] <= 0 and not st["isZipline"]
            and not st["isSliding"] and not st["isStuck"]
            and st["yspd"] > 0 and z_held):
        coyote_blocks = new_guard and st["coyoteTimer"] > 0 and st["yspd"] >= 0
        if not coyote_blocks:
            st["isGliding"] = True
            st["isJumping"] = False
            st["isSpinning"] = False
            events.append("glide_on")

    # 1b. bloque del planeo ACTIVO (pisa el yspd mientras Z siga pulsada)
    if st["isGliding"]:
        if z_held:
            st["yspd"] = GLIDE_FALL - Y_ACCEL
        else:
            st["isGliding"] = False
            events.append("glide_off_release")
        if st["isGrounded"]:
            st["isGliding"] = False
            events.append("glide_off_land")

    # 2. coyote update
    if st["isGrounded"]:
        st["coyoteTimer"] = PLAYER_COYOTE_FRAMES
    elif st["coyoteTimer"] > 0:
        st["coyoteTimer"] -= 1

    # 3. salto (incluida la ventana coyote)
    if (st["controls"] and z_pressed and not st["isJumping"]
            and (st["isGrounded"] or (st["coyoteTimer"] > 0
                                      and st["yspd"] >= 0 and not st["isZipline"]))
            and not st["isAttacking"] and not st["isSpinCharging"]):
        st["isGrounded"] = False
        st["isJumping"] = True
        st["yspd"] = -JUMP_FORCE
        st["coyoteTimer"] = 0
        events.append("jump")

    # 4. colision (gravedad; el vuelo mantiene su propio yspd)
    if not st["isGrounded"]:
        if st["isFlying"]:
            st["yspd"] = ROUGE_FLY_RISE
        else:
            st["yspd"] = min(st["yspd"] + Y_ACCEL, 12)

    return events


def sim_base(airborne=False):
    st = {"controls": True, "isGrounded": True, "isJumping": False, "isGliding": False,
          "isFlying": False, "isAttacking": False, "isHurt": False, "isDead": False,
          "shocked": 0, "isZipline": False, "isSliding": False, "isStuck": False,
          "isSpinning": False, "isSpinCharging": False, "yspd": 0.0,
          "coyoteTimer": PLAYER_COYOTE_FRAMES}
    if airborne:  # acaba de pisar fuera del borde: 1er frame de aire cayendo
        st["isGrounded"] = False
        st["yspd"] = Y_ACCEL
    return st


def sim_run(script, new_guard, airborne=False, fly_frames=0):
    st = sim_base(airborne)
    if fly_frames:  # despego del vuelo activo: en el aire, ventana ya gastada
        st["isGrounded"] = False
        st["isFlying"] = True
        st["coyoteTimer"] = 0
        st["yspd"] = ROUGE_FLY_RISE
    log = []
    for f, (zp, zh) in enumerate(script):
        if fly_frames:
            st["isFlying"] = f < fly_frames  # el vuelo se apaga en fly_frames
        ev = sim_frame(st, zp, zh, new_guard)
        log.append((f, ev, round(st["yspd"], 3), st["isGliding"],
                    st["isJumping"], st["coyoteTimer"], st["isGrounded"]))
    return log


def first_frame(log, evname):
    return next((f for f, ev, *_ in log if evname in ev), None)


def simulate():
    res = []

    # --- Escenario A: EL BUG — salto TARDIO desde un borde (frame 2 pulsa Z) ---
    script_a = [(False, False), (False, False), (True, True)] + [(False, True)] * 70
    log_old = sim_run(script_a, new_guard=False, airborne=True)
    log_new = sim_run(script_a, new_guard=True, airborne=True)

    a2_old = log_old[2]
    res.append(("A-OLD reproduce el bug: glide_on + jump EN EL MISMO frame de la pulsacion tardia",
                "glide_on" in a2_old[1] and "jump" in a2_old[1], "frame2 OLD=%s" % (a2_old,)))
    a3_old = log_old[3]
    res.append(("A-OLD el salto queda comido: yspd asciende 1 frame y vuelve al planeo",
                a2_old[2] < -6 and a3_old[2] > 0 and a3_old[3],
                "f2=%s f3=%s" % (a2_old[2], a3_old[2])))

    a2_new = log_new[2]
    res.append(("A-NEW sin glide durante la ventana: la pulsacion tardia SALTA limpio",
                "glide_on" not in a2_new[1] and "jump" in a2_new[1],
                "frame2 NEW=%s" % (a2_new,)))
    fg_new = first_frame(log_new, "glide_on")
    res.append(("A-NEW el glide solo sale DESPUES del apex del salto (cadena intacta)",
                fg_new is not None and fg_new > 25, "primer glide NEW=%s" % fg_new))
    if fg_new is not None:
        fgl = log_new[fg_new]
        res.append(("A-NEW al encenderse el glide ya no es un salto (transicion limpia)",
                    not fgl[4], "frame=%s" % (fgl,)))

    # --- Escenario B: Z MANTENIDA al salir del borde (sin pulsacion nueva) ---
    script_b = [(False, True)] * 30
    log_b_old = sim_run(script_b, new_guard=False, airborne=True)
    log_b_new = sim_run(script_b, new_guard=True, airborne=True)
    fg_b_old = first_frame(log_b_old, "glide_on")
    fg_b_new = first_frame(log_b_new, "glide_on")
    res.append(("B-OLD el glide se encendia al instante (frame <= 1, ventana abierta)",
                fg_b_old is not None and fg_b_old <= 1, "frame=%s" % fg_b_old))
    res.append(("B-NEW el glide espera a que la ventana se gaste (frame 10 exacto)",
                fg_b_new == 10, "frame=%s" % fg_b_new))
    res.append(("B-NEW ningun glide mientras la ventana esta abierta (f < 10)",
                not [f for f, ev, *_ in log_b_new if "glide_on" in ev and f < 10], ""))

    # --- Escenario C: salto NORMAL desde el suelo con Z mantenida ---
    script_c = [(True, True)] + [(False, True)] * 70
    log_c_old = sim_run(script_c, new_guard=False)
    log_c_new = sim_run(script_c, new_guard=True)
    fg_c_old = first_frame(log_c_old, "glide_on")
    fg_c_new = first_frame(log_c_new, "glide_on")
    res.append(("C: la cadena salto normal -> glide es IDENTICA en OLD y NEW",
                fg_c_old is not None and fg_c_old == fg_c_new,
                "OLD=%s NEW=%s" % (fg_c_old, fg_c_new)))
    res.append(("C: el salto normal sale en el frame 0 en ambos",
                "jump" in log_c_old[0][1] and "jump" in log_c_new[0][1], ""))

    # --- Escenario D: fin del VUELO activo con Z mantenida (toma el relevo) ---
    log_d = sim_run([(False, True)] * 60, new_guard=True, fly_frames=20)
    fg_d = first_frame(log_d, "glide_on")
    res.append(("D: fin del vuelo (Z mantenida) -> el glide toma el relevo despues (cadena)",
                fg_d is not None and 20 <= fg_d <= 45, "frame=%s" % fg_d))

    # --- Escenario E: fuzz — NEW JAMAS enciende glide con ventana abierta ---
    import random
    rng = random.Random(9191)
    violations = 0
    for _ in range(3000):
        st = sim_base(airborne=rng.random() < 0.5)
        for _ in range(60):
            zp = rng.random() < 0.06
            zh = rng.random() < 0.7
            before = dict(st)
            sim_frame(st, zp, zh, True)
            if st["isGliding"] and not before["isGliding"]:
                if before["isGrounded"]:
                    violations += 1        # imposible (guard !isGrounded): paranoia
                elif before["coyoteTimer"] > 0 and before["yspd"] >= 0:
                    violations += 1       # el guard v91 fallaria
                st["coyoteTimer"] = 0      # gasta la ventana (no re-contar)
    res.append(("E: fuzz 3000 pasos — NEW nunca enciende el glide con la ventana abierta",
                violations == 0, "violaciones=%d" % violations))

    return res


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1
                           else os.path.dirname(os.path.abspath(__file__)))
    print("check_v91.py — PASADA 1")
    print("RAIZ DEL PROYECTO: %s" % root)

    d64_rel = "objects/obj_rouge/Draw_64.gml"
    spc_rel = "scripts/scr_rouge_special/scr_rouge_special.gml"
    mb_rel = "scripts/scr_move_basic/scr_move_basic.gml"
    knx_rel = "scripts/scr_knux_special/scr_knux_special.gml"
    d64 = read(root, d64_rel)
    spc = read(root, spc_rel)
    mbs = read(root, mb_rel)
    knx = read(root, knx_rel)

    section("S0 — Archivos presentes")
    check("S0", "Draw_64.gml de obj_rouge existe", d64 is not None)
    check("S0", "scr_rouge_special.gml existe", spc is not None)
    check("S0", "scr_move_basic.gml existe (motor del coyote)", mbs is not None)
    if d64 is None or spc is None or mbs is None:
        print("\nRESULTADO: FALLO (archivos base no encontrados)")
        return 1

    d64_old = git_show(root, d64_rel)
    spc_old = git_show(root, spc_rel)
    have_git = d64_old is not None and spc_old is not None
    if not have_git:
        print("  [nota] origin/main no disponible: los checks vs git se saltan; "
              "los invariantes embebidos cubren la estructura")

    # ------------------------------------------------------------------ S1
    section("S1 — Draw_64.gml: nombre de modalidad mas visible")
    check("S1", "banner v91 presente", V91_MODE_BANNER in d64)
    check("S1", "llamada vieja v32 (alpha 0.55) eliminada", OLD_V32_ALPHA not in d64)
    check("S1", "escala vieja 0.4 eliminada", "0.4, 0.4, 0, " not in d64)
    check("S1", "exactamente 9 draw_text_transformed_color (8 contorno + 1 color)",
          d64.count("draw_text_transformed_color(") == 9,
          "encontradas: %d" % d64.count("draw_text_transformed_color("))
    missing = [o for o in OUTLINE_OFFSETS if (OUTLINE_CALL % o) not in d64]
    check("S1", "las 8 pasadas del contorno negro estan exactas (offsets + c_black x4)",
          not missing, "faltan: %s" % missing)
    check("S1", "la llamada de color (_modeCol) esta exacta", COLOR_CALL in d64)
    last_outline_pos = d64.rfind(OUTLINE_CALL % "_modeX - 1, _modeY - 1,")
    color_pos = d64.rfind(COLOR_CALL)
    check("S1", "la llamada de color es la ULTIMA (dibujada encima del contorno)",
          color_pos > last_outline_pos >= 0)
    check("S1", "escala v91 exacta (0.6 reposo + pop 0.7 al ciclar)", V91_MODE_SCALE in d64)
    check("S1", "alpha v91 exacta (1 destello / 0.9 reposo)", V91_MODE_ALPHA in d64)
    check("S1", "anclas _modeX/_modeY (ceil camara + offset + 12)",
          V91_MODE_X in d64 and V91_MODE_Y in d64)
    check("S1", "texto ~11 px de alto (18 px de fnt_big * 0.6) vs ~7 px antes",
          "0.6 + 0.1 * min(modeFlash / 12, 1)" in d64)
    check("S1", "los 4 nombres y colores de modalidad intactos",
          all(n in d64 and c in d64 for n, c in MODE_NAMES_AND_COLORS))
    check("S1", "el switch conserva sus 3 casos (EGGMAN/SUPPORT/ATTACK)",
          d64.count("case ROUGE_MODE_") == 3)
    check("S1", "guarda del bloque: if(hp > 0 && !isDead)", "if(hp > 0 && !isDead)" in d64)
    check("S1", "fuente/alineacion se fijan igual que siempre (fnt_big/center/middle)",
          "\tdraw_set_font(fnt_big);" in d64
          and "\tdraw_set_halign(fa_center);" in d64
          and "\tdraw_set_valign(fa_middle);" in d64)

    banner_idx = d64.find(V91_MODE_BANNER)
    bad_indent = []
    if banner_idx >= 0:
        for i, l in enumerate(d64.split("\n")):
            if i >= d64[:banner_idx].count("\n") and l.strip() and re.match(r"^ +\S", l):
                bad_indent.append(i + 1)
    check("S1", "indentacion del bloque v91 con TABS (convencion del archivo)",
          not bad_indent, "lineas con espacios: %s" % bad_indent[:5])

    braces, parens = balance(d64)
    check("S1", "llaves/parens balanceadas en Draw_64.gml", braces == 0 and parens == 0,
          "braces=%d parens=%d" % (braces, parens))

    if have_git:
        check("S1", "lineas 1-54 byte-identicas a origin/main (barra HP + radar intactos)",
              d64_old.split("\n")[:54] == d64.split("\n")[:54])

    # ------------------------------------------------------------------ S2
    section("S2 — scr_rouge_special.gml: el planeo respeta el tiempo de coyote")
    check("S2", "banner v91 del planeo presente", V91_GLIDE_BANNER in spc)
    check("S2", "linea del guard de coyote EXACTA en la activacion del planeo",
          GLIDE_GUARD_LINE in spc)
    check("S2", "cabeza de la activacion intacta (!isGrounded/!isGliding/!isFlying/!isAttacking)",
          GLIDE_ACTIVATION_HEAD in spc)
    check("S2", "linea de Z mantenida intacta (yspd > 0 && keyboard_check)",
          GLIDE_ACTIVATION_Z in spc)
    check("S2", "el guard es la linea FINAL de la condicion (despues de la linea de Z)",
          spc.rfind(GLIDE_GUARD_LINE) > spc.find(GLIDE_ACTIVATION_Z) >= 0)
    check("S2", "cuerpo de la activacion intacto (isGliding = true + glide_xspd)",
          GLIDE_BODY in spc)
    check("S2", "una sola activacion del planeo (unico isGliding = true del archivo)",
          spc.count("isGliding = true;") == 1,
          "encontrados: %d" % spc.count("isGliding = true;"))
    check("S2", "bloque del planeo ACTIVO congelado (glideTimer = 1 / agarre de pared)",
          GLIDE_ACTIVE_FROZEN in spc)

    glide_banner = spc.find("// ---------------- GLIDE PASIVA (v14, tipo Knuckles) ----------------")
    guard_idx = spc.rfind(GLIDE_GUARD_LINE)  # rfind: el del planeo es el ULTIMO (el 1o es su vuelo)
    body_idx = spc.find(GLIDE_BODY)
    check("S2", "el guard vive DENTRO del bloque GLIDE PASIVA (banner < guard < cuerpo)",
          0 <= glide_banner < guard_idx < body_idx,
          "banner=%d guard=%d body=%d" % (glide_banner, guard_idx, body_idx))

    check("S2", "motor del coyote intacto en scr_move_basic (ventana + salto aereo)",
          "(isGrounded || (coyoteTimer > 0 && yspd >= 0 && !isZipline))" in mbs
          and "coyoteTimer = 0;" in mbs
          and "#macro PLAYER_COYOTE_FRAMES 10" in mbs)
    special_first = mbs.find("specialFunc();")
    jump_idx = mbs.find("keyboard_check_pressed(global.KeyA) && !isJumping")
    check("S2", "orden critico intacto: specialFunc() corre ANTES del bloque de salto",
          0 <= special_first < jump_idx,
          "special=%d jump=%d" % (special_first, jump_idx))
    check("S2", "el salto consume la ventana (coyoteTimer = 0 tras saltar) — invariante",
          "// v4.9: el salto consumio la ventana coyote" in mbs)

    braces, parens = balance(spc)
    check("S2", "llaves/parens balanceadas en scr_rouge_special.gml",
          braces == 0 and parens == 0, "braces=%d parens=%d" % (braces, parens))
    if have_git:
        ob, op_ = balance(spc_old)
        check("S2", "balance identico a origin/main (solo lineas nuevas, sin cerrar nada)",
              (braces, parens) == (ob, op_))
        delta = len(spc.split("\n")) - len(spc_old.split("\n"))
        check("S2", "diff vs origin/main = +17 lineas exactas (16 de banner + 1 de guard)",
              delta == 17, "delta=%d" % delta)

    # ------------------------------------------------------------------ S6
    section("S6 — Paridad de familia (guard v4.9 en su vuelo + Knux)")
    fly_idx = spc.find("keyboard_check_pressed(global.KeyA) && keyboard_check(global.KeyUp)")
    check("S6", "activacion del VUELO intacta (Z + ARRIBA)", fly_idx >= 0)
    if fly_idx >= 0:
        check("S6", "el vuelo activo CONSERVA su guard de coyote (paridad no rota)",
              FAMILY_GUARD_CORE in spc[fly_idx:fly_idx + 700])
    check("S6", "guard de familia en scr_rouge_special exactamente 2 veces (vuelo + planeo)",
          spc.count(FAMILY_GUARD_CORE) == 2,
          "encontrados: %d" % spc.count(FAMILY_GUARD_CORE))
    if knx is not None:
        check("S6", "scr_knux_special.gml conserva SU guard de coyote (referencia de familia)",
              FAMILY_GUARD_CORE in knx and "glideTimer <= 0" in knx)
        if have_git and git_show(root, knx_rel) is not None:
            check("S6", "scr_knux_special.gml byte-identico a origin/main (intacto)",
                  git_show(root, knx_rel) == knx)
    st2 = read(root, "objects/obj_rouge/Step_2.gml")
    if st2 is not None:
        check("S6", "estado 23 ROUGE_GLIDE_AIR sigue mapeado en Step_2 (red intacta)",
              "state = ROUGE_GLIDE_AIR;" in st2)
    ui = read(root, "objects/obj_playerui/Draw_64.gml")
    if ui is not None:
        check("S6", "iconos HUD por modalidad intactos (obj_playerui)",
              "rougeMode == ROUGE_MODE_EGGMAN" in ui)

    # ------------------------------------------------------------------ S4
    section("S4 — Seguridad estatica / integridad del proyecto")
    for rel, content in ((d64_rel, d64), (spc_rel, spc)):
        check("S4", "%s es UTF-8 valido sin BOM y con finales LF" % rel,
              not content.startswith("﻿") and "\r" not in content
              and content.endswith("\n"))
    # OJO: "TODO" a secas es espanol normal en este proyecto ("durante TODO
    # el tornado") — solo cuentan marcadores con DOS PUNTOS.
    markers = ("TODO:", "FIXME:", "XXX:", "PLACEHOLDER:")
    for rel, content in ((d64_rel, d64), (spc_rel, spc)):
        found = [m for m in markers if m in content]
        check("S4", "%s sin marcadores temporales (TODO:/FIXME:/XXX:)" % rel,
              not found, str(found))
    st = git_status_porcelain(root)
    if st is not None:
        gml_mods = [p for xy, p in st if p.endswith(".gml")]
        expected = {d64_rel, spc_rel}
        # la v90 (parry de Sonic) ya aplicada pero sin commitear NO es fuga:
        # es el estado esperado del proyecto del duena antes de esta v91.
        v90_known = {"scripts/scr_parry/scr_parry.gml",
                     "scripts/scr_player_hurt/scr_player_hurt.gml",
                     "objects/obj_amy_canon/Step_0.gml",
                     "objects/obj_amy_canon/Create_0.gml",
                     "objects/obj_sonic/Create_0.gml",
                     "objects/obj_kris/Create_0.gml",
                     "objects/obj_player_puppet/Draw_0.gml"}
        unexpected = [p for p in gml_mods if p not in expected and p not in v90_known]
        check("S4", "git: solo los 2 .gml de la v91 (y la v90 ya aplicada) difieren",
              not unexpected, "inesperados: %s" % unexpected[:5])
        yy = [p for xy, p in st if p.endswith((".yyp", ".yy", ".resource_order"))]
        check("S4", "git: CERO archivos .yyp/.yy/.resource_order tocados", not yy, str(yy[:5]))
    else:
        print("  [skip] git no disponible — integridad de proyecto no verificable aqui")

    # ------------------------------------------------------------------ S5
    section("S5 — Anti-cheat / superficie de red (regla de oro 7)")
    if have_git:
        add_d64 = added_lines(d64_old, d64)
        add_spc = added_lines(spc_old, spc)
        bad = [t for l in add_d64 + add_spc for t in NET_TOKENS if t in l]
        check("S5", "ninguna linea nueva toca la red (cero tokens de paquete)", not bad, str(bad))
        check("S5", "lineas nuevas de scr_rouge_special = solo comentarios + guard",
              all(l[1:].strip().startswith("//") or l[1:].strip().startswith("&&")
                  for l in add_spc),
              "inesperadas: %s" % [l for l in add_spc
                                   if not (l[1:].strip().startswith("//")
                                           or l[1:].strip().startswith("&&"))][:3])
        check("S5", "lineas nuevas de Draw_64 = comentarios + draw_* (HUD local)",
              all(l[1:].strip().startswith("//") or l[1:].strip().startswith("draw_")
                  or l[1:].strip().startswith("var _mode")
                  or l[1:].strip().startswith("}")
                  or l[1:].strip() in ("{", "switch(rougeMode)", "")
                  or l[1:].strip().startswith("case ")
                  for l in add_d64),
              "inesperadas: %s" % [l for l in add_d64
                                   if not (l[1:].strip().startswith("//")
                                           or l[1:].strip().startswith("draw_")
                                           or l[1:].strip().startswith("var _mode")
                                           or l[1:].strip() in ("{", "}", "")
                                           or l[1:].strip() == "switch(rougeMode)"
                                           or l[1:].strip().startswith("case "))][:3])
    else:
        print("  [skip] checks de diff vs origin/main (sin git) — S2/S6 cubren el contenido")

    # ------------------------------------------------------------------ S3
    section("S3 — Simulacion de frames (mini-interprete OLD vs NEW)")
    for name, ok, detail in simulate():
        check("S3", name, ok, detail)

    # ------------------------------------------------------------------ resumen
    print("\n" + "=" * 74)
    print("RESULTADO PASADA 1: %d OK / %d FALLO" % (PASS, FAIL))
    if FAILURES:
        print("Fallos:")
        for f in FAILURES:
            print("  - %s" % f)
        return 1
    print("TODO OK. Pasar a la PASADA 2 (check_v91_pass2.py).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
