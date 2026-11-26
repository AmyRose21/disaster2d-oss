#!/usr/bin/env python3
"""v82 - GANCHOS del cyber: parches byte-exactos en 12 archivos.

Uso: apply_v82_hooks.py [repo_root]

Cada parche usa un ancla literal; exige que el ancla aparezca EXACTAMENTE 1 vez
(si el archivo ya esta parcheado, lo salta). Escribe con newline="" (no toca
los saltos de linea) y conserva el estado de fin de archivo de cada archivo.
El orden de los archivos respeta el perfil medido con show.py (tabuladores
solo donde el original los tiene).
"""
import os
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/work/disaster2d-oss"

# --------------------------------------------------------------------------
# 1) obj_sally_canon/Create_0.gml  (8 espacios, LF)
# --------------------------------------------------------------------------
SALLY_CREATE_OLD = "isSlow = false;\n\n// Create sensors\n"
SALLY_CREATE_NEW = (
    "isSlow = false;\n"
    "\n"
    "// v82 (duena): FORMAS CYBER (tecla V, scr_sally_special). 0 = NORMAL,\n"
    "// 1 = SEMI CYBER, 2 = CYBER COMPLETA. cyberFlash = destello del cambio.\n"
    "// Los numeros de cada forma viven en las macros SALLY_CYBER_* de\n"
    "// scr_amy_cyber.gml.\n"
    "cyberForm = 0;\n"
    "cyberFlash = 0;\n"
    "\n"
    "// Create sensors\n"
)

# --------------------------------------------------------------------------
# 2) scr_sally_special.gml  (8 espacios, LF) - tecla V + duracion del escudo
# --------------------------------------------------------------------------
SPECIAL_ANCHOR = "        if(global.playerControls && keyboard_check_pressed(global.KeyC) && shieldRechrage <= 0)\n"

SPECIAL_V_BLOCK = '''        // ---- v82 (duena): FORMAS CYBER DE SALLY CANON (tecla V) ----
        // NORMAL -> SEMI CYBER -> CYBER COMPLETA -> NORMAL ... Cada forma
        // es mas fuerte que la anterior (numeros: SALLY_CYBER_* de
        // scr_amy_cyber.gml). CONDICION: tiene que haber una AMY CANON
        // viva (y no esbirro) en la partida; si no, V no hace nada y la
        // forma activa se apaga sola. La esbirro (2+ caidas) no las usa.
        // Solo la Sally Canon: la vanilla no tiene cyberForm y este bloque
        // esta detras del gate de personaje.
        if(global.character == CHARACTER_SALLY_CANON && SALLY_CYBER_ENABLED)
        {
                var _cyOk = (!SALLY_CYBER_NEED_AMY_CANON || scr_sally_cyber_amy_present())
                && revivalTimes < 2 && !isDead && hp > 0 && fase2State == SALLY_CANON_F2_OFF;

                // se murio la Amy Canon (o yo): vuelta a NORMAL
                if(cyberForm > 0 && !_cyOk && SALLY_CYBER_AUTO_DROP)
                {
                        cyberForm = SALLY_CYBER_FORM_NORMAL;
                        cyberFlash = SALLY_CYBER_FLASH_TIME;
                }

                if(global.playerControls && keyboard_check_pressed(global.KeyV) && _cyOk
                && shockedTimer <= 0 && !isHurt && !isAttacking && !isSliding && !isHiding
                && !isSpinCharging && redRingTimer <= 0 && !isZipline)
                {
                        cyberForm = (cyberForm + 1) mod 3;
                        cyberFlash = SALLY_CYBER_FLASH_TIME;

                        audio_play_sound(SALLY_CYBER_SWITCH_SND, 0, false);
                }

                if(cyberFlash > 0)
                        cyberFlash--;
        }

'''

SPECIAL_SHIELD_OLD = (
    "                shieldTimer = 5 * 60;\n"
    "                // Canon: recarga propia (28 s, 2 menos que la vanilla).\n"
)
SPECIAL_SHIELD_NEW = (
    "                // v82 (duena): en forma CYBER el escudo puede durar mas (segun\n"
    "                // SALLY_CYBER_SHIELD_MODE; con el modo 0 por defecto dura igual).\n"
    "                shieldTimer = ceil(5 * 60 * scr_sally_cyber_shield_duration_mul(scr_sally_cyber_form()));\n"
    "                // Canon: recarga propia (28 s, 2 menos que la vanilla).\n"
)

# --------------------------------------------------------------------------
# 3) scr_player_hurt.gml  (8 espacios, LF) - resistencia + escudo que aguanta
# --------------------------------------------------------------------------
HURT_GUARD_OLD = (
    "        if(global.player.isDead)\n"
    "                return;\n"
    "\n"
    '        // v36 (duena: "la invisibilidad debe hacerla inmune al dano\n'
)
HURT_RESIST_BLOCK = '''        // v82 (duena): FORMAS CYBER de Sally Canon. SEMI CYBER resiste el
        // 35% del dano y CYBER COMPLETA el 60%. Se aplica al PRINCIPIO del
        // pipeline de la victima: todo lo de abajo (anillos, stats,
        // knockback, i-frames) sigue su curso con el dano ya reducido.
        // Entero y minimo 1: el dano de las stats viaja como u8/s16. El
        // esbirro no (revivalTimes >= 2) y la vanilla no tiene cyberForm
        // (gate de personaje + variable_instance_exists).
        if(global.character == CHARACTER_SALLY_CANON && damage > 0 && global.player.revivalTimes < 2
        && variable_instance_exists(global.player.id, "cyberForm") && global.player.cyberForm > 0)
                damage = max(1, round(damage * scr_sally_cyber_resist_mul(clamp(floor(global.player.cyberForm), 0, 2))));

'''

HURT_SHIELD_ANCHOR = '                                // v78 (duena): "aumenta la invulerabilidad del escudo de\n'
HURT_HOLD_BLOCK = '''                                // v82 (duena): FORMA CYBER de Sally Canon - "efectividad
                                // de escudo": en SEMI/COMPLETA el escudo puede AGUANTAR el
                                // golpe en vez de romperse (45% / 70%). Aguantar = el golpe
                                // no hace dano, el escudo sigue puesto (minimo 0.5 s) y da
                                // i-frames cortos para que no le caiga otro en la misma
                                // rafaga. La esbirro y la vanilla nunca entran aqui (la
                                // tirada con forma 0 devuelve false sin gastar azar).
                                if(global.character == CHARACTER_SALLY_CANON && global.player.revivalTimes < 2
                                && scr_sally_cyber_shield_hold(scr_sally_cyber_form()))
                                {
                                        global.player.hurttime = max(global.player.hurttime, SALLY_CYBER_SHIELD_HOLD_INVULN);
                                        global.player.shieldTimer = max(global.player.shieldTimer, SALLY_CYBER_SHIELD_HOLD_MIN_TIME);

                                        audio_play_sound(snd_parry, 0, false);
                                        return;
                                }

'''

# --------------------------------------------------------------------------
# 4) obj_player_puppet/Step_0.gml  (8 espacios, SIN newline final)
# --------------------------------------------------------------------------
PUPPET_STEP_OLD = (
    "                _scKickPad = ceil((bbox_right - bbox_left) * (duelista ? SALLY_CANON_KICK_PCT_F2_AIR : SALLY_CANON_KICK_PCT_F1));\n"
    "}\n"
)
PUPPET_STEP_NEW = (
    "                _scKickPad = ceil((bbox_right - bbox_left) * (duelista ? SALLY_CANON_KICK_PCT_F2_AIR : SALLY_CANON_KICK_PCT_F1));\n"
    "\n"
    "        // v82 (duena): FORMAS CYBER de Sally Canon - la patada llega mas\n"
    "        // lejos: x1.45 en SEMI CYBER, x1.70 en CYBER COMPLETA (la forma\n"
    "        // viaja en su CLIENT_PLAYER_DATA, ver net_udpprocess). Mismo pad\n"
    "        // por distancia de siempre, solo mas ancho. El esbirro (2+ caidas)\n"
    "        // nunca: su patada se queda como estaba.\n"
    "        _scKickPad = ceil(_scKickPad * scr_sally_cyber_hitbox_mul(cyberForm, revivalTimes >= 2));\n"
    "}\n"
)

# --------------------------------------------------------------------------
# 5) obj_player_puppet/Create_0.gml  (sin indentar, SIN newline final)
# --------------------------------------------------------------------------
PUPPET_CREATE_TAIL = "shieldPosePrev = false; // valor anterior de sallyShield (flanco)"
PUPPET_CREATE_ADD = (
    "\n"
    "\n"
    "// v82 (duena): FORMA CYBER de Sally Canon remota: 0 = normal,\n"
    "// 1 = SEMI CYBER, 2 = CYBER COMPLETA. La escribe net_udpprocess con los\n"
    "// 3 ultimos bytes de su CLIENT_PLAYER_DATA. La leen el Step_0 (pad de la\n"
    "// patada) y el Draw_0 (holograma) de este puppet.\n"
    "cyberForm = 0;"
)

# --------------------------------------------------------------------------
# 6) obj_netclient/Step_2.gml  (8 espacios, SIN newline final) - emisor
# --------------------------------------------------------------------------
SENDER_OLD = (
    "                        if(global.character == CHARACTER_TAILS)\n"
    "                        {\n"
    "                                buffer_write(buffer, buffer_u8, attackCharge);\n"
    "                                buffer_write(buffer, buffer_s16, -radtodeg(arctan2(obj_tails.yspd, obj_tails.isGrounded ? obj_tails.gspd : obj_tails.xspd)));\n"
    "                        }\n"
)
SENDER_ADD = (
    "\n"
    "                        // v82 (duena): FORMA CYBER de Sally Canon (tecla V) - 3 bytes\n"
    "                        // AL FINAL del paquete: [SALLY_CYBER_NET_TAG_A, TAG_B, forma].\n"
    "                        // El server retransmite todo lo que viene despues del bitflags\n"
    "                        // sin mirarlo (Game.c: while pos < len), asi que no hace falta\n"
    "                        // tocar ni el server ni los tipos de paquete. DOBLE etiqueta:\n"
    "                        // el buffer de recepcion es FIJO y un cliente viejo (que no\n"
    "                        // manda estos bytes) se leeria como basura vieja, no como -1.\n"
    "                        if(global.character == CHARACTER_SALLY_CANON && variable_instance_exists(id, \"cyberForm\"))\n"
    "                        {\n"
    "                                buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_A);\n"
    "                                buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_B);\n"
    "                                buffer_write(buffer, buffer_u8, clamp(floor(cyberForm), 0, 2));\n"
    "                        }\n"
)

# --------------------------------------------------------------------------
# 7) net_udpprocess.gml  (8 espacios, SIN newline final) - lector
# --------------------------------------------------------------------------
READER_OLD = (
    "                                                if(character == CHARACTER_SALLY_CANON && (bitflags & PLAYER_POWERBOOST))\n"
    "                                                        duelista = true;\n"
)
READER_ADD = (
    "\n"
    "                                                // v82 (duena): FORMA CYBER de Sally Canon (tecla V de la\n"
    "                                                // otra jugadora) - 3 bytes al final de su paquete:\n"
    "                                                // [TAG_A, TAG_B, forma]. Tiene que ser LA ULTIMA lectura\n"
    "                                                // de este case. Etiqueta doble: sin las dos coincidencias\n"
    "                                                // exactas la forma es 0 (cliente viejo = bytes viejos en\n"
    "                                                // el buffer fijo). Un cliente viejo que reciba el paquete\n"
    "                                                // nuevo simplemente no lee estos bytes.\n"
    "                                                if(character == CHARACTER_SALLY_CANON)\n"
    "                                                {\n"
    "                                                        var _cyA = buffer_read_s(rbuff, buffer_u8);\n"
    "                                                        var _cyB = buffer_read_s(rbuff, buffer_u8);\n"
    "                                                        var _cyF = buffer_read_s(rbuff, buffer_u8);\n"
    "\n"
    "                                                        cyberForm = (_cyA == SALLY_CYBER_NET_TAG_A && _cyB == SALLY_CYBER_NET_TAG_B && _cyF >= 0 && _cyF <= 2) ? _cyF : 0;\n"
    "                                                }\n"
)

# --------------------------------------------------------------------------
# 8) obj_player_puppet/Draw_0.gml  (8 espacios, LF)
# --------------------------------------------------------------------------
PUPPET_DRAW_OLD = '''        if(variable_global_exists("scr_amy_cyber"))
                scr_amy_cyber(character, fromPallete, toPallete, is_cheating ? spr_merfurmu : _poseBodySpr, _poseBodyIdx);
        else
                scr_palette_swap(fromPallete, toPallete);
        draw_sprite_ext(is_cheating ? spr_merfurmu : _poseBodySpr, _poseBodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle, image_blend, _hideAlpha);
        shader_reset();
'''
PUPPET_DRAW_NEW = '''        // v82 (duena): FORMAS CYBER de Sally Canon remota (tecla V de la
        // otra jugadora): el puppet la dibuja con el mismo holograma de
        // Amy, nivel 1 (SEMI CYBER) o 2 (CYBER COMPLETA), mas su glow
        // exterior. La forma llega en los 3 ultimos bytes de su
        // CLIENT_PLAYER_DATA (net_udpprocess). La esbirro nunca la usa
        // (revivalTimes >= 2): su puppet se dibuja NORMAL. Para el resto
        // lvl = -1 = automatico (AMY_CYBER_CHARS: Amy Canon, nivel 1).
        var _cyLvl = -1;

        if(character == CHARACTER_SALLY_CANON)
                _cyLvl = (revivalTimes < 2 && cyberForm > 0) ? clamp(floor(cyberForm), 0, 2) : 0;

        var _cySpr = is_cheating ? spr_merfurmu : _poseBodySpr;

        if(variable_global_exists("scr_amy_cyber"))
        {
                scr_amy_cyber_halo(character, _cySpr, _poseBodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle, _hideAlpha);
                scr_amy_cyber(character, fromPallete, toPallete, _cySpr, _poseBodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle);
        }
        else
                scr_palette_swap(fromPallete, toPallete);

        draw_sprite_ext(is_cheating ? spr_merfurmu : _poseBodySpr, _poseBodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle, image_blend, _hideAlpha);
        shader_reset();
'''

# --------------------------------------------------------------------------
# 9) obj_sally_canon/Draw_0.gml  (bloque con 1 tabulador -> 8 espacios, LF)
# --------------------------------------------------------------------------
SALLY_DRAW_OLD = (
    "\tscr_palette_swap(global.palleteFrom, global.palleteTo);\n"
    "\tdraw_sprite_ext(_bodySpr, _bodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);\n"
    "\tshader_reset();\n"
)
SALLY_DRAW_NEW = '''        // v82 (duena): FORMAS CYBER (tecla V). SEMI CYBER / CYBER COMPLETA
        // dibujan el cuerpo con el shader holograma (nivel 1 / 2) y su glow
        // exterior; NORMAL usa el palette swap de siempre. El esbirro
        // siempre devuelve forma 0 (scr_sally_cyber_form). cyberFlash sube
        // el glitch un instante al cambiar de forma.
        var _cyLvl = scr_sally_cyber_form();
        var _cyRot = isSpinning ? 0 : radtodeg(angle);
        var _cyAlp = (hurttime > 0 || isHiding) ? 0.5 : image_alpha;
        var _cyFls = cyberFlash / SALLY_CYBER_FLASH_TIME;

        if(_cyLvl > 0)
        {
                scr_amy_cyber_halo(global.character, _bodySpr, _bodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, _cyAlp);
                scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, _bodySpr, _bodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, _cyFls);
        }
        else
                scr_palette_swap(global.palleteFrom, global.palleteTo);

        draw_sprite_ext(_bodySpr, _bodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, image_blend, _cyAlp);
        shader_reset();
'''

# --------------------------------------------------------------------------
# 10) obj_amy_canon/Draw_0.gml  (8 espacios, LF)
# --------------------------------------------------------------------------
AMY_BLOCK_OLD = '''        if(!(variable_instance_exists(id, "superFormPhase") && superFormPhase > 0))
        {
                if(variable_global_exists("scr_amy_cyber"))
                        scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, sprite_index, image_index);
                else
                        scr_palette_swap(global.palleteFrom, global.palleteTo);
        }
'''
AMY_BLOCK_NEW = '''        // v82 (duena): el holograma mejora (contorno luminoso, glow exterior,
        // lineas de datos, pies que se deshacen) y necesita saber DONDE se
        // dibuja el cuerpo: mismo punto, escala, rotacion y alfa que el
        // draw_sprite_ext de abajo. Por eso scr_wss_draw() sube aqui (es
        // pura: da igual llamarla antes) y sale una sola vez.
        var _wss = scr_wss_draw();
        var _cyRot = (isSpinning && !isLightDashing) ? 0 : radtodeg(angle);
        var _cyAlp = (hurttime > 0 || isHiding) ? 0.5 : image_alpha;

        if(!(variable_instance_exists(id, "superFormPhase") && superFormPhase > 0))
        {
                if(variable_global_exists("scr_amy_cyber"))
                {
                        scr_amy_cyber_halo(global.character, sprite_index, image_index, -1, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot, _cyAlp);
                        scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, sprite_index, image_index, -1, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot);
                }
                else
                        scr_palette_swap(global.palleteFrom, global.palleteTo);
        }
'''
AMY_DRAW_OLD = (
    "        var _wss = scr_wss_draw();\n"
    "        draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], (isSpinning && !isLightDashing) ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);\n"
)
AMY_DRAW_NEW = (
    "        // (v82: la llamada a scr_wss_draw() subio al bloque de arriba; aqui\n"
    "        // solo se dibuja el cuerpo con los mismos valores que el shader.)\n"
    "        draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot, image_blend, _cyAlp);\n"
)

# --------------------------------------------------------------------------
# 11) obj_playerui/Draw_64.gml  (8 espacios, LF) - icono V del HUD
# --------------------------------------------------------------------------
HUD_OLD = (
    "                        val = SALLY_CANON_SHIELD_RECHARGE;\n"
    "                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);\n"
    "                        drawKeyIcon(spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyC, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);\n"
    "                        break;\n"
)
HUD_NEW = '''                        val = SALLY_CANON_SHIELD_RECHARGE;
                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        drawKeyIcon(spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyC, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        // v82 (duena): FORMA CYBER (tecla V, scr_sally_special). Icono
                        // en la fila de abajo, como el V de Rouge. Color = estado:
                        // gris = no se puede (no hay Amy Canon viva, o esbirro),
                        // blanco = NORMAL, cian = SEMI CYBER, cian claro = CYBER
                        // COMPLETA; blanco a tope mientras dura el destello del cambio.
                        var _cyForm = scr_sally_cyber_form();
                        var _cyCol  = c_gray;
                        var _cyAlp  = 0.5;

                        if(!scr_esbirro_hud(global.player) && scr_sally_cyber_amy_present())
                        {
                                _cyCol = c_white;
                                _cyAlp = 0.8;

                                if(_cyForm >= SALLY_CYBER_FORM_SEMI)
                                {
                                        _cyCol = $35D9FF;
                                        _cyAlp = 1;
                                }

                                if(_cyForm >= SALLY_CYBER_FORM_FULL)
                                        _cyCol = $C6FDFF;
                        }

                        if(variable_instance_exists(global.player.id, "cyberFlash") && global.player.cyberFlash > 0)
                        {
                                _cyCol = c_white;
                                _cyAlp = 1;
                        }

                        drawKeyIcon(spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyV, 10, 276 - _ico, _cyCol, _cyAlp, 0);
                        break;
'''

# --------------------------------------------------------------------------
# 12) obj_sally_canon/Draw_64.gml  (tabuladores, SIN newline final) - nombre
# --------------------------------------------------------------------------
LABEL_ADD = (
    "\n"
    "\n"
    "// v82 (duena): NOMBRE DE LA FORMA CYBER bajo la barra de vida (mismo sitio\n"
    "// y estilo que el modo de Rouge). Solo en SEMI CYBER / CYBER COMPLETA: en\n"
    "// NORMAL no se escribe nada. Brilla mientras dura el destello del cambio.\n"
    "if(cyberForm > 0 && revivalTimes < 2 && hp > 0)\n"
    "{\n"
    "\tvar _cyName = \"SEMI CYBER\";\n"
    "\tvar _cyCol = $35D9FF;\n"
    "\n"
    "\tif(cyberForm >= SALLY_CYBER_FORM_FULL)\n"
    "\t{\n"
    "\t\t_cyName = \"CYBER\";\n"
    "\t\t_cyCol = $C6FDFF;\n"
    "\t}\n"
    "\n"
    "\tdraw_set_font(fnt_big);\n"
    "\tdraw_set_halign(fa_center);\n"
    "\tdraw_set_valign(fa_middle);\n"
    "\tdraw_text_transformed_color(ceil(x - obj_camera.x), ceil(y - obj_camera.y) - offset + 12, _cyName, 0.4, 0.4, 0, _cyCol, _cyCol, _cyCol, _cyCol, cyberFlash > 0 ? 1 : 0.7);\n"
    "}"
)


def read(path):
    with open(path, "rb") as fh:
        return fh.read()


def write(path, data):
    with open(path, "wb") as fh:
        fh.write(data)


def patch(rel, old, new, marker):
    """Reemplaza old (exactamente 1 vez) por new.

    marker = trozo unico de 'new' que identifica el parche ya aplicado.
    """
    path = os.path.join(REPO, rel)
    text = read(path).decode("utf-8")

    if marker in text:
        print(f"[SKIP] ya estaba {rel} :: {marker[:40]!r}")
        return

    if text.count(old) != 1:
        raise SystemExit(f"[XX] {rel}: ancla encontrada {text.count(old)} veces (se esperaba 1). ABORTO")

    write(path, text.replace(old, new).encode("utf-8"))
    print(f"[OK] parcheado  {rel} :: {marker[:40]!r}")


def append(rel, tail, addition):
    """Anade al final exigiendo que el archivo termine exactamente en 'tail'."""
    path = os.path.join(REPO, rel)
    text = read(path).decode("utf-8")

    if text.endswith(addition):
        print(f"[SKIP] ya estaba {rel}")
        return

    if not text.endswith(tail):
        raise SystemExit(f"[XX] {rel}: no termina en el ancla esperada. ABORTO")

    write(path, (text + addition).encode("utf-8"))
    print(f"[OK] parcheado  {rel}")


def main():
    sp = "scripts/scr_sally_special/scr_sally_special.gml"
    ph = "scripts/scr_player_hurt/scr_player_hurt.gml"
    am = "objects/obj_amy_canon/Draw_0.gml"

    # ---------- 1 ----------
    patch("objects/obj_sally_canon/Create_0.gml", SALLY_CREATE_OLD, SALLY_CREATE_NEW,
          "cyberForm = 0;\ncyberFlash = 0;\n")
    # ---------- 2 ----------
    patch(sp, SPECIAL_ANCHOR, SPECIAL_V_BLOCK + SPECIAL_ANCHOR,
          "FORMAS CYBER DE SALLY CANON (tecla V) ----")
    patch(sp, SPECIAL_SHIELD_OLD, SPECIAL_SHIELD_NEW,
          "shieldTimer = ceil(5 * 60 * scr_sally_cyber_shield_duration_mul(scr_sally_cyber_form()));")
    # ---------- 3 ----------
    guard = "        if(global.player.isDead)\n                return;\n\n"
    v36 = '        // v36 (duena: "la invisibilidad debe hacerla inmune al dano\n'
    assert HURT_GUARD_OLD == guard + v36
    patch(ph, HURT_GUARD_OLD, guard + HURT_RESIST_BLOCK + v36,
          "damage = max(1, round(damage * scr_sally_cyber_resist_mul(")
    # va ANTES del comentario v78 (que describe la linea de hurttime de abajo)
    patch(ph, HURT_SHIELD_ANCHOR, HURT_HOLD_BLOCK + HURT_SHIELD_ANCHOR,
          "scr_sally_cyber_shield_hold(scr_sally_cyber_form()))")
    # ---------- 4 ----------
    patch("objects/obj_player_puppet/Step_0.gml", PUPPET_STEP_OLD, PUPPET_STEP_NEW,
          "scr_sally_cyber_hitbox_mul(cyberForm, revivalTimes >= 2)")
    # ---------- 5 ----------
    append("objects/obj_player_puppet/Create_0.gml", PUPPET_CREATE_TAIL, PUPPET_CREATE_ADD)
    # ---------- 6 ----------
    patch("objects/obj_netclient/Step_2.gml", SENDER_OLD, SENDER_OLD + SENDER_ADD,
          "buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_A);")
    # ---------- 7 ----------
    patch("scripts/net_udpprocess/net_udpprocess.gml", READER_OLD, READER_OLD + READER_ADD,
          "cyberForm = (_cyA == SALLY_CYBER_NET_TAG_A")
    # ---------- 8 ----------
    patch("objects/obj_player_puppet/Draw_0.gml", PUPPET_DRAW_OLD, PUPPET_DRAW_NEW,
          "scr_amy_cyber_halo(character, _cySpr,")
    # ---------- 9 ----------
    patch("objects/obj_sally_canon/Draw_0.gml", SALLY_DRAW_OLD, SALLY_DRAW_NEW,
          "var _cyLvl = scr_sally_cyber_form();")
    # ---------- 10 ----------
    patch(am, AMY_BLOCK_OLD, AMY_BLOCK_NEW,
          "scr_amy_cyber_halo(global.character, sprite_index, image_index, -1,")
    patch(am, AMY_DRAW_OLD, AMY_DRAW_NEW,
          "image_xscale * _wss[0], image_yscale * _wss[1], _cyRot, image_blend, _cyAlp);")
    # ---------- 11 ----------
    patch("objects/obj_playerui/Draw_64.gml", HUD_OLD, HUD_NEW,
          "spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyV, 10, 276 - _ico")
    # ---------- 12 ----------
    # Draw_64 de Sally Canon termina en el '}' del if(hp > 0), SIN newline final
    append("objects/obj_sally_canon/Draw_64.gml",
           "\t\tscr_number_spr(ceil(x-obj_camera.x) - 2, ceil(y-obj_camera.y) - offset - 12, string(global.player.rings), _colour);\n}",
           LABEL_ADD)


if __name__ == "__main__":
    main()
