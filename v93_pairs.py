#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v93_pairs.py — pares (viejo, nuevo) EXACTOS de los 17 edits de v93, derivados
de las ediciones documentadas de la sesion. check_v93_pass2.py los aplica sobre
`git show HEAD:archivo` y exige que el resultado sea IGUAL byte a byte al
archivo entregado — prueba de que nada mas se movio."""

PAIRS = {

"scripts/scr_metalamy_special/scr_metalamy_special.gml": [
("""//     golpe normal. Tres cargas (METALAMY_DASH_MAX), cada una tarda 5 s
//     en recargar (secuencial) y entre uso y uso hay 0,5 s
//     (METALAMY_DASH_GAP = attackTimer). Animacion: SIEMPRE
//     spr_metalamy_attack2 (v4.7: la vieja attack11 salio del kit — al
//     impactar/aterrizar el sprite se mantiene, no cambia).
//     Sonido: snd_metalamy_dash.""",
"""//     golpe normal. Tres cargas (METALAMY_DASH_MAX), cada una tarda 3,75 s
//     en recargar (secuencial; v93: al DOBLE mientras dura el revelado del
//     escaner) y entre uso y uso hay 0,5 s (METALAMY_DASH_GAP = attackTimer).
//     Animacion: SIEMPRE spr_metalamy_attack2 (v4.7: la vieja attack11 salio
//     del kit — al impactar/aterrizar el sprite se mantiene, no cambia).
//     Sonido: snd_metalamy_dash.
//     v93 — CAZA CONFIRMADA: la embestida que TOCA a un superviviente
//     hiteable devuelve 1,5 s de la recarga de cargas (una vez POR
//     embestida). El dano lo aplica el cliente de la victima como siempre;
//     esto es solo el feedback local de cargas (patron Adaptabilidad)."""),

("""//     aplica el cliente de la victima y el parry de Sonic puede
//     desviarlo). Recarga 8 s.""",
"""//     aplica el cliente de la victima y el parry de Sonic puede
//     desviarlo). Recarga 4 s (v93: era 5; el server solo exige UNA bala
//     viva a la vez — su cooldown es 0, ver Game.c)."""),

("""//     al borde de la pantalla apuntando hacia donde esta. Dura de 8 a
//     12 s (v4.10, pedido del usuario): 12 s la V manual y 8 s la
//     ventana pasiva de la cazadora (v4.8: antes 3 s y eran agujas tipo
//     tracker). Pose propia (spr_metalamy_scan, slot 21) y
//     enfriamiento de 20 s. Cero paquetes: los puppets ya viajan
//     sincronizados.
//  Stats: identicos a Exeller (12 / 0.056875).
// =====================================================================
#macro METALAMY_BULLET_RECHARGE (60 * 5)""",
"""//     al borde de la pantalla apuntando hacia donde esta. Dura 15,5 s la
//     V manual y 8 s la ventana pasiva de la cazadora (v4.8). Pose propia
//     (spr_metalamy_scan, slot 21) y enfriamiento de 14,5 s. Cero
//     paquetes: los puppets ya viajan sincronizados.
//     v93 — DATOS TACTICOS: mientras dura el revelado (V manual o ventana
//     de la cazadora) la recarga del dash corre AL DOBLE: la maquina de
//     caza ya sabe donde estan.
//   * v93 — GUI ANIMADA: los 4 iconos del HUD dibujan cada habilidad con
//     SU PROPIA animacion de juego (patron «Chocola» de Vanilla) — ver
//     drawMiniIcon en obj_playerui/Draw_64.gml.
//  Stats: identicos a Exeller (12 / 0.056875).
// =====================================================================
#macro METALAMY_BULLET_RECHARGE (60 * 4)"""),

("""#macro METALAMY_DASH_RECHARGE (60 * 3.75) // 5 s de recarga POR carga""",
"""#macro METALAMY_DASH_RECHARGE (60 * 3.75) // 3,75 s de recarga POR carga (la mitad con el scan activo: v93)"""),

("""#macro METALAMY_DASH_VSPD 8           // velocidad vertical (patron chaos)""",
"""#macro METALAMY_DASH_VSPD 8           // velocidad vertical (patron chaos)
#macro METALAMY_DASH_HIT_REFUND (60 * 1.5) // v93: caza confirmada — 1,5 s de recarga por embestida que TOCA"""),

("""#macro METALAMY_SCAN_RECHARGE (60 * 14.5) // 20 s de enfriamiento (uso manual)
#macro METALAMY_SCAN_TIME (60 * 15.5)      // 12 s de revelado con la V (v4.10: antes 8)""",
"""#macro METALAMY_SCAN_RECHARGE (60 * 14.5) // 14,5 s de enfriamiento (uso manual)
#macro METALAMY_SCAN_TIME (60 * 15.5)      // 15,5 s de revelado con la V"""),

("""#macro METALAMY_HUNT_TIME (60 * 11.25)     // Marca de la cazadora: ciclo de 14 s (rastreo pasivo)""",
"""#macro METALAMY_HUNT_TIME (60 * 11.25)     // Marca de la cazadora: ciclo de 11,25 s (rastreo pasivo)"""),

("""                // v4.6: gasta una carga y arranca el impulso
                dashCharges--;
                dashBoost = METALAMY_DASH_BOOST;""",
"""                // v4.6: gasta una carga y arranca el impulso
                dashCharges--;
                dashBoost = METALAMY_DASH_BOOST;
                dashHitConfirm = false; // v93: cada embestida puede cobrar UNA caza"""),

("""                if(isGrounded && abs(xspd) > 0 && floor(x) mod 4 == 0)
                        net_quick_effect(x - 8 * sign(image_xscale), y + 20, spr_dust);""",
"""                // v93 — CAZA CONFIRMADA: la embestida toco a un superviviente
                // hiteable -> devuelve 1,5 s de la recarga de cargas (una sola
                // vez POR embestida: dashHitConfirm, que se re-arma al pulsar
                // la X). El DANO lo aplica el cliente de la VICTIMA como
                // siempre (obj_player_puppet); esto es solo el feedback local
                // de cargas, mismo patron que la Adaptabilidad (pasiva 4) —
                // cero paquetes, cero superficie nueva de trampa (las cargas
                // siempre fueron estado local del cliente).
                if(dashBoost > 0 && !dashHitConfirm)
                {
                        var _hlist = ds_list_create();
                        instance_place_list(x, y, obj_player_puppet, _hlist, false);

                        for(var _hi = 0; _hi < ds_list_size(_hlist); _hi++)
                        {
                                var _victim = _hlist[| _hi];

                                if(_victim.isDemonized || _victim.isInactive || _victim.isHurt || _victim.hp <= 0)
                                        continue;

                                dashHitConfirm = true;
                                dashRecharge = min(dashRecharge + METALAMY_DASH_HIT_REFUND, METALAMY_DASH_RECHARGE);

                                audio_play_sound(snd_metal_hiit, 0, false);
                                scr_camera_shake(8, 0.4, 0.1);
                                break;
                        }

                        ds_list_destroy(_hlist);
                }

                if(isGrounded && abs(xspd) > 0 && floor(x) mod 4 == 0)
                        net_quick_effect(x - 8 * sign(image_xscale), y + 20, spr_dust);"""),

("""        // v4.6 — recarga de cargas: UNA cada 5 s (secuencial, patron del
        // contador de rebote de Vanilla), hasta 3. Con las 3 llenas el
        // contador queda a cero para no arrastrar recarga a medias.
        if(dashCharges < METALAMY_DASH_MAX)
        {
                dashRecharge++;

                if(dashRecharge >= METALAMY_DASH_RECHARGE)
                {
                        dashRecharge = 0;
                        dashCharges++;
                }
        }
        else
                dashRecharge = 0;
}""",
"""        // v4.6 — recarga de cargas: UNA cada 3,75 s (secuencial, patron del
        // contador de rebote de Vanilla), hasta 3. Con las 3 llenas el
        // contador queda a cero para no arrastrar recarga a medias.
        // v93 — DATOS TACTICOS: mientras dura el revelado del escaner (la V
        // manual o la ventana pasiva de la cazadora) la recarga corre AL
        // DOBLE (+2 por frame): la maquina de caza ya sabe donde estan.
        if(dashCharges < METALAMY_DASH_MAX)
        {
                if(scanTimer > 0)
                        dashRecharge += 2;
                else
                        dashRecharge++;

                if(dashRecharge >= METALAMY_DASH_RECHARGE)
                {
                        dashRecharge = 0;
                        dashCharges++;
                }
        }
        else
                dashRecharge = 0;
}"""),
],

"objects/obj_metalamy/Create_0.gml": [
("""// METAL AMY v4.7/v4.8/v4.10: scan (tecla V)
scanTimer = 0;    // revelado activo (V manual: METALAMY_SCAN_TIME, 12 s · cazadora: METALAMY_HUNT_WINDOW, 8 s)
scanRecharge = 0; // enfriamiento restante (20 s)""",
"""// METAL AMY v4.7/v4.8/v4.10: scan (tecla V)
scanTimer = 0;    // revelado activo (V manual: METALAMY_SCAN_TIME, 15,5 s · cazadora: METALAMY_HUNT_WINDOW, 8 s)
scanRecharge = 0; // enfriamiento restante (14,5 s)"""),

("""// METAL AMY v4.8 — MARCA DE LA CAZADORA (pasiva 3): con 1 solo
// superviviente vivo la V se apaga y el rastreo sale solo (8 s cada 14 s)""",
"""// METAL AMY v4.8 — MARCA DE LA CAZADORA (pasiva 3): con 1 solo
// superviviente vivo la V se apaga y el rastreo sale solo (ventana de 8 s
// cada ciclo de 11,25 s — METALAMY_HUNT_TIME)"""),

("""dashCharges = METALAMY_DASH_MAX; // nace con las 3 cargas
dashRecharge = 0;  // progreso de la carga en curso (5 s por carga)
dashBoost = 0;     // frames de impulso restantes del dash actual""",
"""dashCharges = METALAMY_DASH_MAX; // nace con las 3 cargas
dashRecharge = 0;  // progreso de la carga en curso (3,75 s por carga)
dashBoost = 0;     // frames de impulso restantes del dash actual
dashHitConfirm = false; // v93: caza confirmada — la embestida que TOCA ya cobro su reembolso"""),
],

"objects/obj_metalamy/Step_0.gml": [
("""// ---- MARCA DE LA CAZADORA: el ultimo superviviente ----
// Al quedar exactamente 1 vivo (esbirros y agonizantes fuera del conteo),
// la V se apaga (huntMode) y el rastreo sale solo: ventana de 8 s
// (METALAMY_HUNT_WINDOW; la V manual dura 12 s — v4.10: "de 8 a 12 s"),
// luego 14 s de enfriamiento — que arranca cuando la ventana TERMINA — y
// vuelta a empezar. Reviven a alguien (2+ vivos) -> vuelve al scan manual.""",
"""// ---- MARCA DE LA CAZADORA: el ultimo superviviente ----
// Al quedar exactamente 1 vivo (esbirros y agonizantes fuera del conteo),
// la V se apaga (huntMode) y el rastreo sale solo: ventana de 8 s
// (METALAMY_HUNT_WINDOW; la V manual dura 15,5 s), luego un ciclo de
// 11,25 s de enfriamiento — que arranca cuando la ventana TERMINA — y
// vuelta a empezar. Reviven a alguien (2+ vivos) -> vuelve al scan manual."""),

("""if(huntMode)
{
        // ciclo: ventana -> CD de 14 s al terminar -> nueva ventana""",
"""if(huntMode)
{
        // ciclo: ventana -> enfriamiento de 11,25 s al terminar -> nueva ventana"""),
],
}

PAIRS["objects/obj_playerui/Draw_64.gml"] = [
("""        // 3) pista horneada posterior (flechas del walldash / golpe aereo),
        //    si la hay y cae dentro del contenido del sprite
        if(_hintX > 0)
        {
                var _hw = (_iR + 1) - _hintX;
                if(_hw > 0)
                        draw_sprite_part_ext(_spr, _frame, _hintX, _oy, _hw, _ih, _xx + _artW + _tw + 4, _yy + _oy, 1, 1, _col, _alpha);
        }
}

if(instance_exists(global.player) && !global.player.isDead)""",
"""        // 3) pista horneada posterior (flechas del walldash / golpe aereo),
        //    si la hay y cae dentro del contenido del sprite
        if(_hintX > 0)
        {
                var _hw = (_iR + 1) - _hintX;
                if(_hw > 0)
                        draw_sprite_part_ext(_spr, _frame, _hintX, _oy, _hw, _ih, _xx + _artW + _tw + 4, _yy + _oy, 1, 1, _col, _alpha);
        }
}

// v93 (HUD) — ICONO ANIMADO DE HABILIDAD (patron «Chocola» de Vanilla): el
// sprite REAL de la habilidad (sus frames de juego, animando de verdad) en
// vez de un icono GUI estatico. Cicla frames con current_time (uno cada
// 150 ms, patron de la V de Vanilla), con color de estado (blanco = listo,
// rojo = recargando), alpha de recarga (el relleno se llena), desliz hacia
// la derecha mientras NO esta lista y la tecla REAL de la configuracion al
// lado (v4.3, respeta el remapeo).
//   _cx/_cy/_cw/_ch = zona de contenido del sprite medida sobre los PNG
//   (v4.3b: draw_sprite_part_ext solo pide zonas que existen de verdad en
//   la textura, como el recorte (3,2,13,21) de la Chocola).
//   _fly > 0 (periodo del vaiven) anima los sprites de UN frame (la bala
//   de Metal Amy): vaiven horizontal suave de ±3 px, "en vuelo".
drawMiniIcon = function(_spr, _cx, _cy, _cw, _ch, _scale, _key, _xx, _yy, _col, _alpha, _fly)
{
        var _frame = floor(current_time / 150) mod max(1, sprite_get_number(_spr));
        var _slide = (1.0 - _alpha) * 10;
        var _flyX = 0;

        if(_fly > 0)
                _flyX = round(sin(current_time / _fly) * 3);

        draw_sprite_part_ext(_spr, _frame, _cx, _cy, _cw, _ch, _xx + _slide + _flyX, _yy, _scale, _scale, _col, _alpha);
        scr_text_spr(_xx + _cw * _scale + 4 + _slide + _flyX, _yy + floor(_ch * _scale * 0.5) - 3, scr_controls_keycode_to_key(_key), _col, _alpha);
}

if(instance_exists(global.player) && !global.player.isDead)"""),
]

_old_case = """                                case EXE_METALAMY:
                                {
                                        // v2.2 (TTB): golpe (X) y bala del canon (C).
                                        // v4.3: el frame 0 de spr_gui_metalamyattack ERA una X grande
                                        // horneada (no habia arte separable), asi que se dibuja solo la
                                        // tecla real (artW = 0) en su lugar.
                                        // v4.6 (dash): el anillo del icono X refleja el sistema de
                                        // cargas: con cargas -> barre el gap de 0,5 s entre usos; sin
                                        // cargas -> el anillo ES la recarga (5 s por carga), rojo
                                        // hasta llenarse.
                                        var _maprog;
                                        if(global.player.dashCharges > 0)
                                                _maprog = 1.0 - (min(global.player.attackTimer, METALAMY_DASH_GAP) / METALAMY_DASH_GAP);
                                        else
                                                _maprog = global.player.dashRecharge / METALAMY_DASH_RECHARGE;
                                        drawKeyIcon(spr_gui_metalamyattack, 0, 0, global.KeyB, _maprog * 10, 240 - _ico, _maprog == 1.0 ? c_white : c_red, _maprog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = 1.0 - (global.player.bulletTimer / METALAMY_BULLET_RECHARGE);
                                        drawKeyIcon(spr_gui_metal_amy_lazer, 0, 24, global.KeyC, prog * 4, 250 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                                        // v4.7/v4.8 (SCAN, tecla V): a la derecha de la C, misma fila
                                        // (patron Amy canon v4.1: C y V comparten fila, como en el
                                        // teclado; la vista es 480x270 y una cuarta fila apilada
                                        // caeria fuera de pantalla). spr_gui_metalamy_indy trae el
                                        // ojo verde + una V horneada en un keycap (x24..31 del PNG):
                                        // NO hace falta editar la imagen — el mecanismo de v4.3
                                        // recorta el arte hasta el ojo (artW = 14) y dibuja la tecla
                                        // REAL dinamica (drawKeyIcon), igual que en todos los iconos
                                        // de habilidad desde v4.3.
                                        // v4.8 — MARCA DE LA CAZADORA: con 1 solo superviviente la
                                        // V ya no se pulsa: el anillo pasa a reflejar el CICLO
                                        // pasivo (ventana de 8 s en blanco; luego el relleno barre
                                        // los 14 s del enfriamiento) — el icono se vuelve dorado
                                        // para avisar de que el rastreo ahora sale solo.
                                        var _sact = global.player.scanTimer > 0;
                                        var _sready;
                                        var _sprog;

                                        if(global.player.huntMode)
                                        {
                                                _sprog = 1.0 - (global.player.huntCd / METALAMY_HUNT_TIME);
                                                _sready = _sact || _sprog >= 1.0;
                                                drawKeyIcon(spr_gui_metalamy_indy, 0, 14, global.KeyV, 44 + _sprog * 10, 250 - _ico, _sready ? c_yellow : c_red, _sready ? 1 : _sprog, 0);
                                        }
                                        else
                                        {
                                                _sprog = 1.0 - (global.player.scanRecharge / METALAMY_SCAN_RECHARGE);
                                                _sready = _sprog >= 1.0 || _sact;
                                                drawKeyIcon(spr_gui_metalamy_indy, 0, 14, global.KeyV, 44 + _sprog * 10, 250 - _ico, _sready ? c_white : c_red, _sready ? 1 : _sprog, 0);
                                        }
                                        break;
                                }"""

_new_case = """                                case EXE_METALAMY:
                                {
                                        // v93 — ICONOS ANIMADOS (patron «Chocola» de Vanilla,
                                        // pedido de la dueña): cada habilidad se dibuja con SU
                                        // PROPIA animacion de juego (los frames reales, ciclando
                                        // con current_time) en vez de los iconos GUI estaticos.
                                        // BLANCO = listo, ROJO = recargando (DORADO = la
                                        // cazadora), relleno = progreso y desliz mientras
                                        // recarga; tecla REAL dinamica al lado (v4.3).

                                        // Z — salto: la bola de giro (spr_metalamy_jump, 5
                                        // frames, contenido completo 30x30) al 40%: blanca en
                                        // el aire, roja y deslizada en tierra.
                                        var _jact = global.playerControls && global.player.isJumping;
                                        drawMiniIcon(spr_metalamy_jump, 0, 0, 30, 30, 0.4, global.KeyA, 372, 219 - _ico, _jact ? c_white : c_red, _jact ? 1 : 0.5, 0);

                                        // X — embestida (spr_metalamy_attack2, 4 frames): el
                                        // relleno es el gap de 0,5 s entre usos con cargas, o
                                        // la recarga de la siguiente carga sin ellas (v4.6) —
                                        // caza confirmada (v93: tocar devuelve 1,5 s) y datos
                                        // tacticos (v93: con el scan activo recarga al doble)
                                        // la aceleran por dentro.
                                        var _maprog;
                                        if(global.player.dashCharges > 0)
                                                _maprog = 1.0 - (min(global.player.attackTimer, METALAMY_DASH_GAP) / METALAMY_DASH_GAP);
                                        else
                                                _maprog = global.player.dashRecharge / METALAMY_DASH_RECHARGE;
                                        drawMiniIcon(spr_metalamy_attack2, 0, 0, 31, 31, 0.4, global.KeyB, 372, 238 - _ico, _maprog >= 1.0 ? c_white : c_red, _maprog, 0);

                                        // C — bala del canon (spr_metalamy_bullet, contenido
                                        // x[1..40] y[3..12]): UN frame — la anima el vaiven de
                                        // vuelo (±3 px). Recarga 4 s (v93).
                                        prog = 1.0 - (global.player.bulletTimer / METALAMY_BULLET_RECHARGE);
                                        drawMiniIcon(spr_metalamy_bullet, 1, 3, 40, 10, 0.7, global.KeyC, 372, 252 - _ico, prog >= 1.0 ? c_white : c_red, prog, 200);

                                        // V — escáner (spr_metalamy_scan, 8 frames: la pose con
                                        // el barrido verde, contenido x[0..52] y[18..61]) al
                                        // 30%. Patron v4.8: con 1 solo superviviente vivo la V
                                        // se vuelve pasiva (cazadora) — icono DORADO y el
                                        // relleno es el ciclo de la ventana; si no, el
                                        // enfriamiento del manual (14,5 s).
                                        var _sact = global.player.scanTimer > 0;
                                        var _sready;
                                        var _sprog;

                                        if(global.player.huntMode)
                                        {
                                                _sprog = 1.0 - (global.player.huntCd / METALAMY_HUNT_TIME);
                                                _sready = _sact || _sprog >= 1.0;
                                                drawMiniIcon(spr_metalamy_scan, 0, 18, 53, 44, 0.3, global.KeyV, 416, 252 - _ico, _sready ? c_yellow : c_red, _sready ? 1 : _sprog, 0);
                                        }
                                        else
                                        {
                                                _sprog = 1.0 - (global.player.scanRecharge / METALAMY_SCAN_RECHARGE);
                                                _sready = _sprog >= 1.0 || _sact;
                                                drawMiniIcon(spr_metalamy_scan, 0, 18, 53, 44, 0.3, global.KeyV, 416, 252 - _ico, _sready ? c_white : c_red, _sready ? 1 : _sprog, 0);
                                        }
                                        break;
                                }"""

PAIRS["objects/obj_playerui/Draw_64.gml"].append((_old_case, _new_case))
