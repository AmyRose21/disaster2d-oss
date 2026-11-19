#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v32.py — Validador de la ronda v32: HABILIDAD V DE ROUGE.

    * V = CAMBIO DE MODALIDAD (la mas poderosa): cicla en orden
      ROUGE -> EGGMAN -> SUPPORT -> ATTACK -> ROUGE el set de X y C.
    * C (modo ROUGE) = INVISIBILIDAD patron sonic.exe original:
      siluetas de contorno rojo con TODOS los movimientos, duracion
      25% MENOS que la del exe (675 vs 900) e INMUNE a TODO rastreo
      (exe/exeller/exetior + scan de Metal Amy: jamas la senalan,
      ni con anillo rojo).
    * EGGMAN: X = escudo electrico (stun 2 s con chispazo), C = mina
      (CLIENT_ETRACKER).
    * SUPPORT: X = escudo de Sally (absorbe golpe + burbuja), C =
      anillos de Vanilla (canal 1 s, pose spr_rouge_emotion3
      "emotico3", CLIENT_CREAM_SPAWN_RINGS).
    * ATTACK: X = patada de Sally (anim nueva spr_rouge_attack3,
      hitbox +65% del bbox, i-frames, recarga de Sally).
    * Capacidad NATA: MEJORAR TRAMPAS (el Genio de Eggman porteado:
      abajo sobre trampa de Amelia (5 anillos) o sensor (3) la dora).

Verifica (estatico, sin GameMaker):
  1. Los 21 sprites nuevos: estructura .yy + PNGs + siluetas ROJO
     PURO + registro .yyp (+21 exactas) + GUIDs unicos en el proyecto.
  2. GML balanceado en los 17 archivos tocados.
  3. Una asercion por caracteristica pedida (con el numero de linea).
  4. Tablas de anims: 27 slots en anims/eanims/negaanims + la tabla
     de siluetas con sus 27 slots.
  5. Server: las 3 puertas anticheat con CH_ROUGE.

Uso: python3 check_v32.py [ruta_repo]   (por defecto /home/z/my-project/repo)
"""
import json
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/repo"
SPR = os.path.join(REPO, "sprites")
YYP = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print(f"  [OK] {msg}")


def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  [FALLA] {msg}")


def check(cond, msg):
    if cond:
        ok(msg)
    else:
        bad(msg)


def rd(path):
    return open(path, encoding="utf-8", errors="replace").read()


def yy_load(path):
    raw = rd(path)
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", raw))


# archivos GML tocados (relativos al repo)
GML = {
    "create": "objects/obj_rouge/Create_0.gml",
    "step2": "objects/obj_rouge/Step_2.gml",
    "special": "scripts/scr_rouge_special/scr_rouge_special.gml",
    "draw76": "objects/obj_rouge/Draw_76.gml",
    "draw64": "objects/obj_rouge/Draw_64.gml",
    "draw0": "objects/obj_rouge/Draw_0.gml",
    "survivors": "scripts/scr_survivors/scr_survivors.gml",
    "udpprocess": "scripts/net_udpprocess/net_udpprocess.gml",
    "netclient": "objects/obj_netclient/Step_2.gml",
    "puppet_step": "objects/obj_player_puppet/Step_0.gml",
    "puppet_draw": "objects/obj_player_puppet/Draw_0.gml",
    "hurt": "scripts/scr_player_hurt/scr_player_hurt.gml",
    "eggtrack": "objects/obj_eggtrack/Step_0.gml",
    "amelia": "objects/obj_amelia_trap/Step_0.gml",
    "ind_exe": "objects/obj_exe_indicator/Step_2.gml",
    "ind_exeller": "objects/obj_exeller_indicator/Step_2.gml",
    "ind_exetior": "objects/obj_exetior_indicator/Step_2.gml",
}
SRV = "betterserver-oss/disasterserver/states/Game.c"


def balanced(text):
    """Balance de llaves/parens/corchetes ignorando strings y //"""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == '"' and (i == 0 or text[i - 1] != "\\"):
            i += 1
            while i < n and (text[i] != '"' or text[i - 1] == "\\"):
                i += 1
        elif c == "'" and (i == 0 or text[i - 1] != "\\"):
            i += 1
            while i < n and (text[i] != "'" or text[i - 1] == "\\"):
                i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 1
        else:
            out.append(c)
        i += 1
    clean = "".join(out)
    return (clean.count("{") == clean.count("}")
            and clean.count("(") == clean.count(")")
            and clean.count("[") == clean.count("]"))


def find_line(text, needle, nth=1):
    """Linea (1-based) de la n-esa aparicion de needle, o -1."""
    lines = text.split("\n")
    seen = 0
    for i, ln in enumerate(lines):
        if needle in ln:
            seen += 1
            if seen == nth:
                return i + 1
    return -1


def main():
    print("=" * 68)
    print(" CHECK v32 — HABILIDAD V DE ROUGE (modalidades + invisibilidad)")
    print("=" * 68)
    gml = {k: rd(os.path.join(REPO, v)) for k, v in GML.items()}
    srv = rd(os.path.join(REPO, SRV))

    # ------------------------------------------------------------- GML
    print("\n[1] GML balanceado (17 archivos) y sin restos")
    for k, v in GML.items():
        check(balanced(gml[k]), f"llaves/parens balanceados: {v}")
    for k, v in GML.items():
        # marcadores de plantilla: con dos puntos (TODO:/FIXME:/XXX:).
        # En este codigo se escribe en español y "durante TODO el recorrido"
        # o "inmune a TODO" son comentarios legales, no restos.
        for pat, label in [(r"\bTODO\s*:", "TODO:"), (r"\bFIXME\s*:", "FIXME:"),
                           (r"\bXXX\s*:", "XXX:"), (r"PLACEHOLDER_V32", "PLACEHOLDER_V32")]:
            if re.search(pat, gml[k]):
                bad(f"resto '{label}': {v}")
    ok("sin restos de plantilla en los 17 archivos (marcadores con ':'; el TODO español de los comentarios no cuenta)")

    # --------------------------------------------------------- MACROS
    print("\n[2] Macros y variables nuevas (obj_rouge/Create_0.gml)")
    macros = {
        "ROUGE_MODE_COUNT": "4",
        "ROUGE_MODE_ROUGE": "0",
        "ROUGE_MODE_EGGMAN": "1",
        "ROUGE_MODE_SUPPORT": "2",
        "ROUGE_MODE_ATTACK": "3",
        "ROUGE_INVIS_DURATION": "675",
        "ROUGE_INVIS_RECHARGE": "-(60 * 14)",
        "ROUGE_KICK_TIME": "16",
        "ROUGE_KICK_HITBOX_PCT": "0.65",
        "ROUGE_KICK_RECHARGE": "(60 * 15)",
        "ROUGE_ESHIELD_TIME": "(60 * 1.5)",
        "ROUGE_ESHIELD_RECHARGE": "(60 * 15)",
        "ROUGE_RINGS_CHANNEL": "(60 * 1)",
        "ROUGE_RINGS_RECHARGE": "(60 * 15)",
        "ROUGE_SHIELD_TIME": "(60 * 5)",
        "ROUGE_SHIELD_RECHARGE": "(60 * 30)",
    }
    for m, val in macros.items():
        check(re.search(rf"#macro {m}\s+{re.escape(val)}(?=\s|$)", gml["create"]) is not None,
              f"#macro {m} = {val}")
    # duracion 25% menos que el exe (900 -> 675)
    check("MENOS el 25% pedido por la duena = 675" in gml["create"],
          "comentario: 675 = 900 - 25% (11,25 s vs 15 s del exe)")
    vars_decl = ["rougeMode", "modeFlash", "invisTimer", "kickState",
                 "eShieldTimer", "eShieldRecharge", "shieldTimer", "shieldRechrage",
                 "ringsChannel", "ringsTimer", "trackerRecharge",
                 "geniusTarget", "geniusTargetType", "geniusSendCd"]
    for v in vars_decl:
        check(re.search(rf"^{v} = ", gml["create"], re.M) is not None,
              f"variable declarada: {v} = ...")
    check("invisTimer = ROUGE_INVIS_RECHARGE;" in gml["create"],
          "invisTimer arranca recargada (patron exe)")

    # ------------------------------------------------------- ESTADOS
    print("\n[3] Estados nuevos (obj_rouge/Step_2.gml)")
    for m, val in [("ROUGE_KICK", "BALANCING+11"), ("ROUGE_RINGS", "BALANCING+12"),
                   ("ROUGE_ESHIELD", "BALANCING+13")]:
        check(f"#macro {m} {val}" in gml["step2"], f"#macro {m} = {val} (estado {24 + int(val[-2:]) - 11})")
    check("if(ringsChannel > 0)" in gml["step2"] and "state = ROUGE_RINGS;" in gml["step2"],
          "Step_2: canal de anillos -> estado ROUGE_RINGS")
    check("if(kickState > 0)" in gml["step2"] and "state = ROUGE_KICK;" in gml["step2"],
          "Step_2: patada pisa el mapeo ataque (ROUGE_KICK)")
    check("eShieldTimer > 0" in gml["step2"] and "state = ROUGE_ESHIELD;" in gml["step2"],
          "Step_2: escudo electrico pisa el mapeo ataque (ROUGE_ESHIELD)")

    # ---------------------------------------------------- CICLO V (local)
    print("\n[4] HABILIDAD V: ciclo de modalidades (scr_rouge_special)")
    check(find_line(gml["special"], "keyboard_check_pressed(global.KeyV)") > 0,
          "V (global.KeyV) pulsada detectada")
    check("rougeMode = (rougeMode + 1) mod ROUGE_MODE_COUNT;" in gml["special"],
          "ciclo ordenado: rougeMode = (rougeMode + 1) mod 4")
    check("modeFlash = 60 * 2;" in gml["special"], "modeFlash 2 s (HUD del cambio)")
    check(find_line(gml["special"], "V: CAMBIO DE MODALIDAD") > 0,
          "bloque V documentado en el special")
    # el ciclo no viaja: ninguna escritura de rougeMode fuera del special/create
    others = ["draw64", "draw76", "draw0", "step2"]
    check(all("rougeMode =" not in gml[k].replace("switch(rougeMode)", "") for k in others),
          "el ciclo es 100% local (solo el special escribe rougeMode)")
    check("switch(rougeMode)" in gml["draw64"], "HUD del Draw_64 segun la modalidad")
    for name in ["ROUGE", "EGGMAN", "SOPORTE", "ATAQUE"]:
        check(f'"{name}"' in gml["draw64"], f"HUD muestra el nombre {name}")

    # --------------------------------------------- INVISIBILIDAD (C)
    print("\n[5] INVISIBILIDAD (C del modo ROUGE, patron exe)")
    check(find_line(gml["special"], "keyboard_check_pressed(global.KeyC)") > 0,
          "C pulsada detectada en el special")
    check("if(invisTimer <= ROUGE_INVIS_RECHARGE)" in gml["special"],
          "activacion con candado de recarga (patron exe)")
    check("invisTimer = ROUGE_INVIS_DURATION;" in gml["special"],
          "activar: invisTimer = 675")
    check(re.search(r"else if\(invisTimer > 0\)\s*\{[\s\S]{0,220}?invisTimer = 0;", gml["special"]) is not None,
          "corte manual temprano con C (patron exe)")
    check("if(invisTimer > ROUGE_INVIS_RECHARGE)\n                invisTimer--;" in gml["special"]
          or re.search(r"if\(invisTimer > ROUGE_INVIS_RECHARGE\)\s*\n\s*invisTimer--;", gml["special"]) is not None,
          "decay hasta la recarga negativa (patron exe)")
    # sin net_sound_emit en el bloque de invisibilidad (sigilo total).
    # Se busca la SINTAXIS DE LLAMADA (con parentesis): los comentarios
    # del propio bloque citan la funcion para explicarlo.
    invis_block = gml["special"][gml["special"].find("INVISIBILIDAD (C en modo ROUGE"):gml["special"].find("decay de la invisibilidad")]
    check("net_sound_emit(" not in invis_block,
          "SONIDOS SOLO LOCALES (cero emits que delaten su posicion)")
    # bit PLAYER_INVIS en el netclient (survivor branch)
    check("if(global.character == CHARACTER_ROUGE)" in gml["netclient"]
          and "bitflags |= PLAYER_INVIS;" in gml["netclient"],
          "netclient: ROUGE manda PLAYER_INVIS (mismo bit del exe)")
    check("if(shieldTimer > 0)\n                                        bitflags |= PLAYER_SALLYSHIELD;" in gml["netclient"]
          or re.search(r"if\(global\.character == CHARACTER_ROUGE\)[\s\S]{0,200}bitflags \|= PLAYER_SALLYSHIELD;", gml["netclient"]) is not None,
          "netclient: ROUGE manda PLAYER_SALLYSHIELD (escudo de Sally)")
    # udpprocess: visible del puppet
    check('if(character == CHARACTER_ROUGE)' in gml["udpprocess"]
          and "visible = !(bitflags & PLAYER_INVIS);" in gml["udpprocess"],
          "udpprocess: puppet de Rouge visible = !PLAYER_INVIS (como el exe)")
    # Draw_76: siluetas locales
    check("global.player_rougeinvis" in gml["draw76"] and "if(invisTimer > 0)" in gml["draw76"],
          "Draw_76: invisible dibuja la tabla de SILUETAS (solo su vista)")
    check("if(effectTime > 0 && invisTimer <= 0)" in gml["draw0"],
          "Draw_0: invisible NO deja residuos fantasma")
    # inmune a rastreo: 3 indicadores + scan, ANTES del anillo rojo
    for k, name in [("ind_exe", "exe original"), ("ind_exeller", "exeller"),
                    ("ind_exetior", "exetior")]:
        t = gml[k]
        pos_skip = find_line(t, "inst.character == CHARACTER_ROUGE && !inst.visible")
        pos_red = find_line(t, "inst.hasRedRing &&")
        check(pos_skip > 0 and pos_red > 0 and pos_skip < pos_red,
              f"indicador de {name}: salta a la Rouge invisible ANTES del anillo rojo")
    check(find_line(gml["ind_exe"], "character == CHARACTER_ROUGE && !visible") > 0,
          "SCAN de Metal Amy: la Rouge invisible tampoco sale en el revelado")

    # ------------------------------------------------- PATADA (attack3)
    print("\n[6] PATADA DE SALLY (X del modo ATTACK)")
    check("if(rougeMode == ROUGE_MODE_ATTACK" in gml["special"]
          and "keyboard_check_pressed(global.KeyB)" in gml["special"],
          "activacion: X (KeyB) en modo ATTACK")
    check("kickState = ROUGE_KICK_TIME;" in gml["special"], "kickState = 16 (i-frames)")
    check("kickRecharge = revivalTimes >= 2 ? ROUGE_KICK_RECHARGE / 2 : ROUGE_KICK_RECHARGE;" in gml["special"],
          "recarga de Sally (15 s; 7,5 debilitada)")
    check("_rougeKickPad = ceil((bbox_right - bbox_left) * ROUGE_KICK_HITBOX_PCT);" in gml["puppet_step"],
          "puppet: pad de hitbox +65% del ANCHO del bbox")
    check("state == ROUGE_KICK" in gml["puppet_step"]
          and "distance_to_object(global.player) <= _rougeKickPad" in gml["puppet_step"],
          "puppet: el pad amplia el alcance del stun (patron Sally Canon)")
    check("global.player.kickState > 0" in gml["hurt"],
          "scr_player_hurt: I-FRAMES mientras kickState > 0")
    check("case ROUGE_KICK:" in gml["draw76"] and "image_speed = 0.75;" in gml["draw76"],
          "Draw_76: tira spr_rouge_attack3 a 0.75 con hold del ultimo frame")

    # ------------------------------------------------------ EGGMAN mode
    print("\n[7] MODO EGGMAN (escudo electrico + mina)")
    check("if(rougeMode == ROUGE_MODE_EGGMAN" in gml["special"]
          and "eShieldTimer = ROUGE_ESHIELD_TIME;" in gml["special"],
          "X: escudo electrico (1,5 s, patron del doctor)")
    check("eShieldRecharge = ROUGE_ESHIELD_TIME + (revivalTimes >= 2 ? ROUGE_ESHIELD_RECHARGE_E : ROUGE_ESHIELD_RECHARGE);"
          in gml["special"], "recarga total 15 s / 7 s debilitada")
    check("PacketType.CLIENT_ETRACKER" in gml["special"],
          "C: mina por el MISMO paquete del sensor de Eggman")
    check("trackerRecharge = EGGMAN_TRACKER_RECHARGE;" in gml["special"],
          "recarga del sensor: la del doctor (25 s)")
    check("state == ROUGE_ESHIELD" in gml["puppet_step"]
          and "stunTime = 2;" in gml["puppet_step"]
          and "snd_electroshock" in gml["puppet_step"]
          and "spr_shockparticle" in gml["puppet_step"],
          "puppet: contacto con el escudo = STUN ELECTRICO 2 s + chispazo (estilo doctor)")
    check("case ROUGE_ESHIELD:" in gml["draw76"], "Draw_76: estado del escudo electrico")

    # ------------------------------------------------------ SUPPORT mode
    print("\n[8] MODO SUPPORT (escudo de Sally + anillos de Vanilla)")
    check("if(rougeMode == ROUGE_MODE_SUPPORT" in gml["special"]
          and "shieldTimer = ROUGE_SHIELD_TIME;" in gml["special"],
          "X: escudo de Sally (5 s de burbuja)")
    check("global.character == CHARACTER_ROUGE && global.player.shieldTimer > 0" in gml["hurt"],
          "scr_player_hurt: el escudo de Rouge ABSORBE un golpe (como Sally)")
    check("global.character == CHARACTER_ROUGE && global.player.shieldTimer > 0" in gml["puppet_step"],
          "puppet: el escudo de Rouge bloquea el contacto del esbirro")
    check("case CHARACTER_ROUGE:" in gml["puppet_draw"]
          and "sallyShield" in gml["puppet_draw"],
          "puppet Draw: burbuja del escudo en el case ROUGE")
    check("if(shieldTimer > 0)\n\tdraw_sprite(revivalTimes >= 2 ? spr_sallyshield2 : spr_sallyshield" in gml["draw0"]
          or re.search(r"if\(shieldTimer > 0\)\s*\n\tdraw_sprite\(revivalTimes >= 2 \? spr_sallyshield2 : spr_sallyshield", gml["draw0"]) is not None,
          "Draw_0: burbuja en la vista propia (patron obj_sally)")
    check("PacketType.CLIENT_CREAM_SPAWN_RINGS" in gml["special"],
          "C: anillos por el MISMO paquete de Vanilla/Cream")
    check("ringsChannel = ROUGE_RINGS_CHANNEL;" in gml["special"],
          "canal quieto de 1 s (patron Vanilla)")
    check("case ROUGE_RINGS:" in gml["draw76"], "Draw_76: estado del canal")
    check("ringsChannel = 0;\n                        ringsTimer = ROUGE_RINGS_RECHARGE;" in gml["special"]
          or re.search(r"ringsChannel = 0;\s*\n\s*ringsTimer = ROUGE_RINGS_RECHARGE;", gml["special"]) is not None,
          "cortar el canal a mitad PAGA la recarga (patron Vanilla)")

    # -------------------------------------------------- MEJORAR TRAMPAS
    print("\n[9] Capacidad NATA: MEJORAR TRAMPAS (Genio porteado)")
    check("net_egg_upgrade_progress(geniusTargetType, geniusTarget, rings);" in gml["special"],
          "special: envia el progreso por el MISMO camino del Genio")
    check("with(_lockType == 1 ? obj_amelia_trap : obj_eggtrack)" in gml["special"],
          "lock del objetivo: trampa de Amelia o sensor (prioridad del Genio)")
    check("rings >= (geniusTargetType == 1 ? EGG_GENIUS_TRAP_COST : EGG_GENIUS_SENSOR_COST)" in gml["special"],
          "costes del Genio: 5 anillos trampa / 3 sensor")
    check("(global.character == CHARACTER_EGGMAN || global.character == CHARACTER_ROUGE)" in gml["eggtrack"],
          "eggtrack: prompt de mejora tambien para Rouge")
    check("(global.character == CHARACTER_EGGMAN || global.character == CHARACTER_ROUGE)" in gml["amelia"],
          "amelia_trap: prompt de mejora tambien para Rouge")

    # --------------------------------------------------------- TABLAS
    print("\n[10] Tablas de anims (scr_survivors.gml)")
    invis_sprites = ["spr_rouge_invis_" + s for s in
                     ["idle", "walk", "run", "jump", "fall", "hurt", "dead",
                      "lookup", "lookdown", "emotion1", "emotion2", "emotion",
                      "balancing", "fly", "zipline", "stuck",
                      "spin_charger", "spin_release", "slide", "glide"]]
    new_sprites = ["spr_rouge_attack3"] + invis_sprites

    def table_after(marker, count, label):
        i = gml["survivors"].find(marker)
        check(i > 0, f"tabla encontrada: {label}")
        if i < 0:
            return
        seg = gml["survivors"][i:i + 5000]
        end = seg.find("\n];")
        body = seg[:end]
        # entradas REALES del array: linea que arranca con identificador
        # (sprite o variable _rougeNegaStuck) — los comentarios con
        # menciones spr_ dentro no cuentan.
        n = len(re.findall(r"^\s*(?:spr_\w+|_[A-Za-z]\w*)\s*,?\s*(?://|$)", body, re.M))
        check(n == count, f"{label}: {n} slots (esperados {count})")

    table_after("global.player_anims[? CHARACTER_ROUGE] =", 27, "player_anims ROUGE")
    table_after("global.player_eanims[? CHARACTER_ROUGE] =", 27, "player_eanims ROUGE")
    table_after("global.player_negaanims[? CHARACTER_ROUGE] =", 27, "player_negaanims ROUGE")
    table_after("global.player_rougeinvis[? CHARACTER_ROUGE] =", 27, "player_rougeinvis (siluetas)")
    check("global.player_rougeinvis = ds_map_create();" in gml["survivors"],
          "el ds_map de siluetas se crea")
    for ref in ["spr_rouge_attack3, //24", "spr_rouge_emotion3, //25", "spr_rouge_idle //26"]:
        check(ref in gml["survivors"], f"slot nuevo en anims: {ref}")
    for s in invis_sprites:
        check(s in gml["survivors"], f"silueta referenciada en la tabla: {s}")
    # la patada usa la anim nueva y la pose del canal es emotion3
    check("spr_rouge_attack3" in gml["survivors"], "anims: patada -> spr_rouge_attack3")
    check("spr_rouge_emotion3, //25" in gml["survivors"], "anims: canal -> spr_rouge_emotion3 (emotico3)")

    # -------------------------------------------------------- SPRITES
    print("\n[11] Los 21 sprites nuevos (estructura + arte)")
    from PIL import Image
    guid_re = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    src_of = {s: "spr_rouge_" + s[len("spr_rouge_invis_"):] for s in invis_sprites}
    src_of["spr_rouge_attack3"] = "spr_rouge_attack1"

    # GUIDs: cada uno aparece 3x en SU .yy (%Name + name + keyframe) — eso
    # es la estructura normal. Lo que NO puede haber es un guid mio en OTRO
    # archivo (ni compartido entre dos de mis sprites). El proyecto trae
    # 2385 colisiones pre-existentes entre sprites viejos (copias sin
    # regenerar, GM las tolera): fuera del alcance de esta ronda.
    cross = {}
    for d in sorted(os.listdir(SPR)):
        p = os.path.join(SPR, d, d + ".yy")
        if os.path.exists(p):
            for g in set(guid_re.findall(rd(p))):
                cross.setdefault(g, set()).add(d)
    is_mine = lambda d: d == "spr_rouge_attack3" or d.startswith("spr_rouge_invis_")
    col_mine = {g: ds for g, ds in cross.items() if len(ds) > 1 and any(is_mine(x) for x in ds)}
    check(not col_mine,
          f"mis {len(new_sprites)} sprites: CERO GUIDs compartidos con otro archivo"
          + (f" ({list(col_mine.items())[:2]})" if col_mine else ""))

    for name in new_sprites:
        d = os.path.join(SPR, name)
        if not os.path.isdir(d):
            bad(f"{name}: NO EXISTE la carpeta")
            continue
        try:
            data = yy_load(os.path.join(d, name + ".yy"))
        except Exception as e:
            bad(f"{name}: .yy no parsea ({e})")
            continue
        frames = data["frames"]
        src = yy_load(os.path.join(SPR, src_of[name], src_of[name] + ".yy"))
        errs = []
        if data["%Name"] != name:
            errs.append("%Name")
        if (data["width"], data["height"]) != (src["width"], src["height"]):
            errs.append("w/h")
        if (data["sequence"]["xorigin"], data["sequence"]["yorigin"]) != (src["sequence"]["xorigin"], src["sequence"]["yorigin"]):
            errs.append("origen")
        if (data["bbox_left"], data["bbox_right"], data["bbox_top"], data["bbox_bottom"]) != (
                src["bbox_left"], src["bbox_right"], src["bbox_top"], src["bbox_bottom"]):
            errs.append("bbox")
        if data["sequence"]["length"] != float(len(frames)):
            errs.append("length")
        if data["sequence"]["name"] != name or data["sequence"]["%Name"] != name:
            errs.append("seq name")
        for f in frames:
            fp = os.path.join(d, f["name"] + ".png")
            if not os.path.exists(fp):
                errs.append(f"falta {f['name'][:8]}.png")
                continue
            im = Image.open(fp)
            if im.size != (data["width"], data["height"]):
                errs.append(f"png {f['name'][:8]} tam {im.size}")
            if not os.path.isdir(os.path.join(d, "layers", f["name"])):
                errs.append(f"falta layers/{f['name'][:8]}/")
            if name.startswith("spr_rouge_invis_"):
                badpx = [p for p in im.convert("RGBA").getdata() if p[3] > 0 and p != (255, 0, 0, 255)]
                if badpx:
                    errs.append(f"pixel no-rojo en {f['name'][:8]} ({badpx[0]})")
            if name == "spr_rouge_attack3":
                pass  # la secuencia se valida abajo con bytes contra attack1
        if errs:
            bad(f"{name}: {', '.join(errs[:4])}")
        else:
            ok(f"{name}: {len(frames)} frames, {data['width']}x{data['height']}, "
               f"origen {data['sequence']['xorigin']},{data['sequence']['yorigin']}"
               + (" — SOLO rojo puro" if name.startswith("spr_rouge_invis_") else ""))

    # attack3: la secuencia correcta de frames del origen (0,0,1,1,1,1,1,0)
    a3 = yy_load(os.path.join(SPR, "spr_rouge_attack3", "spr_rouge_attack3.yy"))
    a1 = yy_load(os.path.join(SPR, "spr_rouge_attack1", "spr_rouge_attack1.yy"))
    seq_expected = [0, 0, 1, 1, 1, 1, 1, 0]
    same = []
    for i, f in enumerate(a3["frames"]):
        exp = os.path.join(SPR, "spr_rouge_attack1", a1["frames"][seq_expected[i]]["name"] + ".png")
        got = os.path.join(SPR, "spr_rouge_attack3", f["name"] + ".png")
        same.append(Image.open(exp).tobytes() == Image.open(got).tobytes())
    check(all(same), f"attack3: los 8 frames son la secuencia [0,0,1,1,1,1,1,0] de attack1 ({sum(same)}/8)")

    # ------------------------------------------------------------ YYP
    print("\n[12] Registro en el .yyp")
    yyp = rd(YYP)
    entries = re.findall(r'\{"id":\{"name":"(spr_[^"]+)","path":"sprites/([^"]+)/\2\.yy",\},\}', yyp)
    names = {e[0] for e in entries}
    missing = [s for s in new_sprites if s not in names]
    check(not missing, f"los 21 sprites registrados en el .yyp" + (f" (faltan: {missing})" if missing else ""))
    # parseo tolerante completo (estructura intacta)
    try:
        json.loads(re.sub(r",(\s*[}\]])", r"\1", yyp))
        ok("el .yyp completo sigue parseando como JSON de GameMaker")
    except Exception as e:
        bad(f"el .yyp NO parsea: {e}")
    # diff exacto vs git — v32.1: la v32 ya viene COMMITIDA en el
    # upstream (la duena la subio: commits aacfebb4 + 165985a3), asi
    # que el .yyp del arbol debe ser IDENTICO a HEAD: sin diff. (En la
    # v32 original este check exigia el diff +21 contra el upstream
    # pre-v32; la linea base se movio.)
    diff = subprocess.run(["git", "-C", REPO, "diff", "--numstat", "--",
                           "Sonicexe The Disaster 2D Remake.yyp"],
                          capture_output=True, text=True).stdout.strip()
    check(diff == "", f"el .yyp sin cambios locales (la v32 ya viene del upstream)")

    # ---------------------------------------------------------- SERVER
    print("\n[13] Server anticheat (betterserver Game.c)")
    for label, needle in [
        ("RINGS: Rouge permitida en CLIENT_CREAM_SPAWN_RINGS",
         "v->surv_char == CH_CREAM || v->surv_char == CH_VANILLA || v->surv_char == CH_AMY_CANON || v->surv_char == CH_ROUGE"),
        ("UPGRADE: Rouge permitida en el Genio (trampas)",
         "v->surv_char == CH_EGGMAN || v->surv_char == CH_ROUGE"),
        ("ETRACKER: Rouge permitida en la mina",
         "v->surv_char == CH_EGGMAN || v->surv_char == CH_ROUGE"),
    ]:
        n = srv.count(needle)
        check(n >= (1 if "RINGS" in label else 2),
              f"{label} ({n} sitio{'s' if n > 1 else ''})")
    # la duracion del ataque (8000 ms v29) sigue cubriendo patada/escudo
    check("case CH_ROUGE:" in srv and "duration = 8000;" in srv,
          "anticheat de duracion v29 intacto (8000 ms cubre patada + escudo)")

    # --------------------------------------------------- GIT: tocados
    # v32.1: la linea base se MOVIO — la duena commitio la v32 completa
    # al upstream. ESTA ronda (v33) trae EXACTAMENTE: el HUD por
    # modalidad (obj_playerui/Draw_64) + el fix del contacto de la
    # patada/escudo (obj_player_puppet/Step_0) + el payload de
    # documentacion. Cero .yyp, cero sprites nuevos, cero server.
    print("\n[14] Archivos tocados (git) — nada mas que la ronda v34")
    # OJO: sin .strip() del stdout entero — le come el espacio inicial a
    # la PRIMERA linea (' M ruta' -> 'M ruta') y el parser la descartaba
    # (el "heck_v32.py" fantasma de la ronda v32.1 era exactamente esto)
    st = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                        capture_output=True, text=True).stdout.split("\n")
    # parse robusto: 'XY ruta' (X/Y de 1 char + espacio). Undelete
    # unstaged es ' D ruta' (3 chars de prefijo); staged es 'D  ruta'.
    modified = []
    for l in st:
        if len(l) >= 4 and l[2] == " ":
            modified.append(l[3:].strip().strip('"'))
    modified = sorted(set(modified))
    expected_hotfix = {"scripts/scr_rouge_special/scr_rouge_special.gml",
                       "scripts/scr_survivors/scr_survivors.gml",
                       "objects/obj_rouge/Create_0.gml",
                       "objects/obj_rouge/Draw_0.gml",
                       "objects/obj_player_puppet/Draw_0.gml",
                       "objects/obj_playerui/Draw_64.gml"}
    doc_payload = {"worklog.md", "LEEME_ROUGE_V34.txt", "check_v34.py"}
    extra_mod = set(modified) - expected_hotfix - doc_payload
    missing_mod = expected_hotfix - set(modified)
    check(not extra_mod and not missing_mod,
          f"modificados: los 6 GML de la ronda v34 (recarga propia + auras + slots) + docs"
          + (f" (EXTRA: {extra_mod})" if extra_mod else "")
          + (f" (FALTAN: {missing_mod})" if missing_mod else ""))

    # ---- el fix v32.1 sigue vivo: burbuja FUSIONADA en el case de la
    # tirolina (el bug era "duplicate case statement found") ----
    # (el bug: "duplicate case statement found" — mi case nuevo duplico
    # el CHARACTER_ROUGE de la tirolina que existia desde la v4.4)
    t = gml["puppet_draw"]
    n_rouge_cases = t.count("case CHARACTER_ROUGE:")
    # 2 legitimos: uno en el switch pequeno del xscale (glide, linea ~80)
    # y uno en el switch grande de personajes (tirolina + burbuja). El bug
    # era un 3.o (dos en el MISMO switch grande) — lo caza el [15].
    check(n_rouge_cases == 2,
          f"puppet Draw_0: 2 cases CHARACTER_ROUGE (1 por switch — el bug "
          f"del zip v32 eran 3: dos en el mismo switch grande)")
    fused = re.search(
        r"case CHARACTER_ROUGE:\s*\n\s*if\(state == ROUGE_ZIPLINE\)\s*\n\s*draw_sprite\(spr_aiz_zipline[^\n]*\n\s*\n\s*if\(sallyShield\)",
        t)
    check(fused is not None,
          "la burbuja del escudo va DENTRO del case existente de la "
          "tirolina (fusion, no case aparte)")

    # --------------------------------------------- CASES DUPLICADOS
    # v32.1: la leccion del bug reportado por la duena ("duplicate case
    # statement found" en obj_player_puppet/Draw_0 — el case
    # CHARACTER_ROUGE de la tirolina ya existia desde la v4.4 y el de la
    # burbuja del escudo lo duplico: un checker que solo mira "existe el
    # case" nunca lo ve; hay que exigir UNICIDAD dentro de su switch).
    print("\n[15] Cases duplicados (la leccion del bug v32.1)")
    dup_total = scan_duplicate_cases(REPO)
    check(dup_total == 0,
          "0 cases duplicados en todo el proyecto (labels con macros "
          "resueltos; los case de strings tipo case \".mute\": son "
          "legales y quedan fuera)")

    # ============================================== [16] HUD POR MODALIDAD
    # v33 (bug A de la duena: "cuando cambie de habilidad los iconos de
    # las habilidades sean visibles... la de vuelo no se ve en la lista
    # tampoco se ve el icono de lo de los cambios ni cambian las
    # habilidades de rouge visiblemente"): el case ROUGE del playerui
    # mostraba SIEMPRE el set normal (vuelo/tornado/spin) porque la v32
    # nunca toco el HUD. Ahora dibuja por modalidad + el icono de la V.
    print("\n[16] HUD por modalidad (obj_playerui/Draw_64, bug A)")
    hud = rd(os.path.join(REPO, "objects", "obj_playerui", "Draw_64.gml"))
    check(hud.count("global.player.rougeMode == ROUGE_MODE_") == 6,
          f"los 4 modos del ciclo consultados con prefijo global.player "
          f"({hud.count('global.player.rougeMode == ROUGE_MODE_')} lecturas)")
    check(re.search(r"(?<![.\w])rougeMode", hud) is None,
          "ninguna lectura de rougeMode SIN prefijo (crashearia: obj_playerui no es obj_rouge)")
    # el icono de la V (el cambio) con el sprite del modo y fila nueva
    check("drawKeyIcon(_vSpr, 0, _vW, global.KeyV," in hud
          and "276 - _ico" in hud,
          "icono de la V (el cambio) con su fila propia (276, sin montarse con el spin 222)")
    for modo, spr, var in [
        ("EGGMAN (escudo electrico X)", "spr_gui_eggshield", "eShieldRecharge"),
        ("EGGMAN (mina C)", "spr_gui_eggtrack", "trackerRecharge"),
        ("SUPPORT (escudo de Sally X)", "spr_gui_sallyshield", "shieldRechrage"),
        ("SUPPORT (anillos C)", "spr_gui_creamrings", "ringsTimer"),
        ("ATTACK (patada X)", "spr_gui_sallyattack", "kickRecharge"),
    ]:
        check(f"spr_gui_" in hud and spr in hud and f"global.player.{var}" in hud,
              f"icono {spr} + recarga real {var} en el HUD — modo {modo}")
    # el set normal queda INTACTO (los 3 iconos clasicos del v13)
    check(hud.count("spr_gui_rougeglide") >= 2 and "spr_gui_rougeattack" in hud
          and "spr_gui_sonicspindash" in hud,
          "set normal intacto: vuelo + tornado + spindash donde siempre")

    # ============================================== [17] CONTACTO PATADA/ESCUDO
    # v33 (bug B de la duena: "al usar la patada o el escudo de eggman
    # usa es el ataque de rouge en vez de las habilidades... no pasa con
    # el escudo ni los rings estos de vanilla"): el rebote generico del
    # v4.4 ("Rouge patea igual que Knuckles", puppet Step_0) capturaba el
    # contacto ANTES que los efectos propios — con el exe atacando, la
    # patada y el escudo electrico rebotaban igual que el tornado.
    print("\n[17] Contacto patada/escudo (obj_player_puppet/Step_0, bug B)")
    puppet = rd(os.path.join(REPO, "objects", "obj_player_puppet", "Step_0.gml"))
    excl = "state != ROUGE_KICK && state != ROUGE_ESHIELD"
    check(puppet.count(excl) == 2,
          f"rebote generico v4.4 YA no captura ROUGE_KICK/ROUGE_ESHIELD "
          f"(2 exclusiones: exe {puppet.count(excl)} + esbirro; hay {puppet.count(excl)})")
    # el bloque nuevo de la patada: stun 3 s rompe-i-frames, patron taladro
    kick_block = re.search(
        r"if\(character == CHARACTER_ROUGE && state == ROUGE_KICK\)\s*\{(.{0,3500}?)return;",
        puppet, re.S)
    check(kick_block is not None and "_kpstun = 3" in puppet
          and "CLIENT_PLAYER_HURT" in (kick_block.group(1) if kick_block else ""),
          "bloque propio de la PATADA: stun 3 s rompe-i-frames (patron taladro v24) + report")
    check(kick_block is not None and "scr_jinna_negatouch_stun_hurt();" in (kick_block.group(1) if kick_block else ""),
          "la patada tambien cuesta 20 de vida al nega local (v17, autofiltro)")
    # el escudo cae al bloque grande -> electrico v32 (863) YA accesible
    check(puppet.count("if(character == CHARACTER_ROUGE && state == ROUGE_ESHIELD)") == 1
          and "snd_electroshock" in puppet,
          "escudo electrico: el case v32 (chispazo + 2 s + sin empujon) ahora SI alcanzable")
    # el tornado/taladro siguen rebotando (v4.4/v24 intactos)
    check("if(character == CHARACTER_ROUGE && state == ROUGE_ATTACK)" in puppet
          and "_rougeKickPad" in puppet,
          "tornado/taladro intactos (v4.4 rebote + bloque taladro v24) y pad +65% de la patada vivo")

    # ============================================== [18] IDENTIDAD DE LAS HABILIDADES v34
    # v34 (aclaracion de la duena: "cuando cambie a ejemplo eggman la X
    # no disparara la habilidad de rouge sino la de eggman... rouge sigue
    # usando aun la habilidad de rouge"): el disparo SI era correcto
    # (guards por modo verificados), pero la EXPERIENCIA decia lo
    # contrario: (a) la patada usaba attackTimer COMPARTIDA con el
    # tornado — probar el tornado dejaba la X del modo ATTACK muerta 20 s;
    # (b) el escudo se veia como su VUELO (spr_rouge_fly) sin nada
    # electrico en su pantalla — imposible distinguirlo de "lo de rouge".
    print("\n[18] Identidad de las habilidades prestadas (v34)")
    special = gml["special"]
    check("&& kickRecharge <= 0 &&" in special,
          "patada: guard con SU recarga propia kickRecharge (no la del tornado)")
    check(special.count("kickRecharge") >= 4,
          f"kickRecharge completa en el special: guard + set + decay ({special.count('kickRecharge')} usos)")
    check("attackTimer = revivalTimes >= 2 ? ROUGE_ATTACK_RECHARGE / 2 : ROUGE_ATTACK_RECHARGE;" in special,
          "el tornado SIN cambios: sigue pagando SU attackTimer al terminar (sin regresion)")
    rouge_draw0 = rd(os.path.join(REPO, "objects", "obj_rouge", "Draw_0.gml"))
    check("if(eShieldTimer > 0)" in rouge_draw0
          and "draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));" in rouge_draw0,
          "AURA electrica del doctor EN SU PANTALLA (Draw_0 de obj_rouge, patron del doctor)")
    puppet_draw = gml["puppet_draw"]
    check("if(state == ROUGE_ESHIELD)" in puppet_draw
          and puppet_draw.count("draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));") >= 2,
          "AURA electrica tambien en SU PUPPET (los demas la ven; el doctor ya la tenia)")
    survivors = gml["survivors"]
    check("spr_rouge_idle //26" in survivors and "spr_erouge_idle //26" in survivors
          and "spr_rougenega_idle //26" in survivors,
          "slots 26 de las 3 tablas en pose IDLE (fuera la de vuelo: se confundia con su habilidad)")
    check("global.player.kickRecharge" in hud,
          "HUD del modo ATTACK ensena la recarga propia de la patada")

    # ------------------------------------------------------------ FIN
    print("\n" + "=" * 68)
    print(f" RESULTADO: {PASS} OK / {FAIL} FALLAS")
    print("=" * 68)
    return 1 if FAIL else 0


def scan_duplicate_cases(repo):
    """Detector de cases duplicados por switch (portable: viaja DENTRO
    del checker para que funcione en cualquier arbol sin depender de
    scripts/externos). Resuelve los #macro del proyecto a valor
    numerico; los labels STRING quedan fuera (case ".mute": y case
    "\\n": son legales y distintos entre si). Devuelve el numero de
    etiquetas duplicadas, o -1 ante error interno."""
    def strip_noise(text):
        out, i, n = [], 0, len(text)
        while i < n:
            c = text[i]
            if c == "\n":
                out.append(c)
                i += 1
            elif c == '"' or c == "'":
                q = c
                i += 1
                while i < n and text[i] != q:
                    i += 1
                i += 1
                out.append(" ")
            elif c == "/" and i + 1 < n and text[i + 1] == "/":
                while i < n and text[i] != "\n":
                    i += 1
            elif c == "/" and i + 1 < n and text[i + 1] == "*":
                i += 2
                while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                    if text[i] == "\n":
                        out.append("\n")
                    i += 1
                i += 2
                out.append(" ")
            else:
                out.append(c)
                i += 1
        return "".join(out)

    def eval_expr(expr, macros, depth=0):
        if depth > 12:
            return None
        expr = expr.strip()
        if re.fullmatch(r"-?\d+", expr):
            return int(expr)
        if re.fullmatch(r"[A-Za-z_]\w*", expr) and expr in macros:
            return eval_expr(macros[expr], macros, depth + 1)
        if expr.startswith("(") and expr.endswith(")"):
            return eval_expr(expr[1:-1], macros, depth + 1)
        if expr.startswith("-"):
            v = eval_expr(expr[1:], macros, depth + 1)
            return -v if v is not None else None
        for op in ("+", "-", "*", "/"):
            parts, lvl, cur = [], 0, ""
            for ch in expr:
                if ch == "(":
                    lvl += 1
                elif ch == ")":
                    lvl -= 1
                if ch == op and lvl == 0:
                    parts.append(cur)
                    cur = ""
                else:
                    cur += ch
            parts.append(cur)
            if len(parts) > 1:
                vals = [eval_expr(p, macros, depth + 1) for p in parts]
                if None in vals:
                    return None
                v = vals[0]
                for x in vals[1:]:
                    if op == "+":
                        v += x
                    elif op == "-":
                        v -= x
                    elif op == "*":
                        v *= x
                    else:
                        return None if x == 0 else v // x
                return v
        return None

    # tabla de macros del proyecto (solo .gml de codigo)
    macros = {}
    gml_files = []
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d not in
                   ("build", "enet", ".git", "sprites", "sounds", "fonts",
                    "rooms", "tiles", "paths", "sequences", "shader",
                    "timelines", "animcurves", "notes", "datafiles",
                    "extensions", "options")]
        for f in files:
            if f.endswith(".gml"):
                gml_files.append(os.path.join(root, f))
    try:
        for path in gml_files:
            for m in re.finditer(r"#macro\s+([A-Za-z_]\w*)\s+(.+)",
                                 strip_noise(rd(path))):
                macros[m.group(1)] = m.group(2).strip()

        dups = 0
        for path in sorted(gml_files):
            clean = strip_noise(rd(path))
            n = len(clean)
            i = 0
            while True:
                sw = clean.find("switch", i)
                if sw < 0:
                    break
                if sw > 0 and (clean[sw - 1].isalnum() or clean[sw - 1] == "_"):
                    i = sw + 6
                    continue
                j = clean.find("{", sw)
                if j < 0:
                    break
                lvl, k = 0, j
                while k < n:
                    if clean[k] == "{":
                        lvl += 1
                    elif clean[k] == "}":
                        lvl -= 1
                        if lvl == 0:
                            break
                    k += 1
                # SIN las llaves delimitadoras: los cases del switch van
                # a profundidad 0 (con la llave propia incluida quedaban
                # a 1 y el detector no veia NADA — falso negativo).
                body = clean[j + 1:k]
                start_line = clean[:sw].count("\n") + 1
                depth = 0
                labels = {}
                for mm in re.finditer(r"(case\s+([^:]+?)\s*:)|(\{)|(\})", body):
                    if mm.group(3):
                        depth += 1
                    elif mm.group(4):
                        depth -= 1
                    elif mm.group(1) is not None and depth == 0:
                        expr = mm.group(2).strip()
                        ln = start_line + body[:mm.start()].count("\n")
                        if not expr:
                            key = ("str", ln)      # label de string: unico
                        else:
                            val = eval_expr(expr, macros)
                            key = ("num", val) if val is not None else ("raw", expr)
                        labels.setdefault(key, []).append((ln, expr))
                dups += sum(1 for hits in labels.values() if len(hits) > 1)
                i = k + 1
        return dups
    except Exception:
        return -1


if __name__ == "__main__":
    sys.exit(main())
