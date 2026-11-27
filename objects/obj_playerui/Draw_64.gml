// ============================================================================
// v10 (NEGAGEN) — ICONOS DE HABILIDAD DEL SUBDITO NEGATIVO: TODOS los
// checks de esbirro de este HUD usan scr_esbirro_hud(global.player)
// (revivalTimes >= 2 PERO sin la marca nega isNegatouch). El subdito
// negativo NO es un esbirro comun para el interfaz: conserva SUS iconos
// de habilidad de superviviente y SUS recargas normales (es un
// superviviente INVERTIDO — el look nega de Negagen — no un demonio
// rojo del bando EXE). El esbirro comun (death-timer) sigue viendo las
// variantes EXE de siempre. La marca la declara lazy el paquete de
// conversion (scr_jinna_negatouch_convert / SERVER_JINNA_MINION_STATE).
// ============================================================================
// ============================================================================
// v4.3b — LETRA DE TECLA DINAMICA EN EL HUD (arreglo de prioridad)
//
// v4.3: la letra de la tecla ya no esta horneada: el arte se dibuja
// recortado (draw_sprite_part_ext) sin la zona de la letra y al lado se
// dibuja la tecla REAL de la configuracion (scr_text_spr +
// scr_controls_keycode_to_key), con el mismo color/alpha del enfriamiento.
//
// v4.3b (arreglos tras probar en partida):
//  1) TRAMPA DE AMELIA (y otros 6 iconos) NO SE VEIAN: GameMaker recorta
//     los bordes transparentes de los sprites al empaquetarlos en texturas,
//     y pedir draw_sprite_part_ext con top=0 / h=alto_total en un sprite
//     con margenes vacios (la trampa tiene 2 filas vacias arriba y 3 abajo)
//     sale de la textura y NO se dibuja nada. Solucion: pedir solo la caja
//     de contenido real (medida pixel a pixel, tabla de abajo) y desplazar
//     el destino igual: el resultado en pantalla es identico.
//  2) EMOCIONES: las letras A/S/D horneadas del PNG se borraron al meter
//     las teclas dinamicas y quedaba el hueco vacio junto a cada cara.
//     Ahora se dibujan las teclas REALES (global.KeyEm1/2/3, remapeables)
//     en el mismo sitio donde estaban las horneadas.
//
// v4.3c: la TRAMPA de Amelia se activa con SOLO la tecla C (ver
//        scr_amelia_special: KeyC + isColliding, SIN isLookingDown),
//        pero su sprite trae "-↓+C" horneado y v4.3 conservaba el "↓+"
//        como si fuera un combo real. Ahora el arte se corta en el guion:
//        el icono muestra "[trampa]-C", igual que como se lanza de verdad.
//        El "↓+" SE conserva en trampolin (↓+X), spindash (↓+Z) y tracker
//        de Eggman (↓+C) porque esos SI exigen estar agachado.
//
//  - En PC se ve siempre la tecla actual del remapeo (letra, numero o
//    nombre corto: space, shift, enter, ...). Se actualiza al instante
//    porque se consulta global.KeyX en cada fotograma.
//  - v5.5: en Android TAMBIEN se dibuja la letra. v4.3 la ocultaba alli
//    ("el control son los botones tactiles") y el icono quedaba con el
//    hueco vacio, "sin tecla aparente" — pero los botones tactiles
//    A/B/C/V SIMULAN estas mismas teclas (scr_controls_init_touch hace
//    keyboard_key_press(global.KeyB) etc.), asi que la letra es igual de
//    cierta en el movil y sirve para saber que hace cada boton del HUD.
//  - Las pistas horneadas que NO son teclas (flechas de direccion, el +
//    de los combos, las flechas del walldash) se conservan como arte o se
//    redibujan detras de la letra dinamica.
//
// drawKeyIcon(_spr, _frame, _artW, _key, _xx, _yy, _col, _alpha, _hintX):
//  _artW  = ancho en pixeles del arte SIN la letra horneada (medido sobre
//           los PNG originales; ver tabla en cada llamada).
//  _hintX = columna donde empieza una pista horneada posterior (flechas);
//           0 = no hay pista. Se redibuja despues de la letra dinamica.
// ============================================================================

if(!global.showHud)
        return;

var _mob = (os_type == os_android ? 200 : 0);

// ============================================================================
// v95 (KRIS LV 20 — "consecuencias"): LA BARRA DE VIDA DEL ASESINO.
// Pedido de la duena: "al llegar al nv 20 (si es que llega) el asesino
// le aparecera una barra de vida". SOLO la ve KRIS (es SU duelo: el
// dano de 35 por golpe y el pool de 350 son cosa de SU espada con LV
// maximo). Dibujo patron jefecito de casa: barra roja centrada bajo el
// reloj y bajo el "Escape!!!" (spr_status se dibuja en y=32 con origen
// superior: ocupa hasta y=47 — la barra arranca en y=49 y no lo tapa).
// El valor es global.exeHpPool: en el cliente
// de Kris es el ESPEJO que alimenta la senal silenciosa del exe
// (rama de snd_kris_lvup en net_state_game); en el del exe es su propia
// vida real. Los dos nacen llenos (KRIS_EXE_MAXHP), aplican la misma
// secuencia de -35 (TCP ordenado) y se rellenan solos al tocar 0.
// ============================================================================
if(global.character == CHARACTER_KRIS
&& instance_exists(global.player)
&& variable_instance_exists(global.player.id, "krisLv")
&& global.player.krisLv >= KRIS_LV_MAX
&& !global.player.isDead)
{
        var _kbX = 480 / 2 - 100;   // barra de 200 px centrada
        var _kbY = 51;               // bajo el "Escape!!!" (spr_status: 32..47)
        var _kbHp = clamp(global.exeHpPool, 0, KRIS_EXE_MAXHP);

        // funda negra con borde + casco granate (patron hudAllyBar de
        // obj_level: 1 px de borde a cada lado del relleno)
        draw_set_alpha(0.92);
        draw_set_color(c_black);
        draw_rectangle(_kbX - 2, _kbY - 2, _kbX + 202, _kbY + 10, false);
        draw_set_color(make_color_rgb(84, 12, 12));
        draw_rectangle(_kbX, _kbY, _kbX + 200, _kbY + 8, false);

        // relleno ROJO vivo — 350 de pool = 198 px (como el relleno de
        // hudAllyBar: proporcional con ceil para que el primer punto de
        // vida SIEMPRE pinte 1 px)
        if(_kbHp > 0)
        {
                draw_set_color(make_color_rgb(232, 20, 20));
                draw_rectangle(_kbX + 1, _kbY + 1, _kbX + 1 + ceil(_kbHp / KRIS_EXE_MAXHP * 198), _kbY + 7, false);
        }

        draw_set_alpha(1);
        draw_set_color(c_white);

        // rotulo con la cuenta real de golpes que faltan (micro-fuente
        // del HUD, patron del "+NN" de hudAllyBar)
        scr_text_spr(_kbX + 6, _kbY + 1, "EL ASESINO  " + string(ceil(_kbHp / KRIS_EXE_DAMAGE)) + " golpes", c_white, 1);
}

// v12 (HUD): los ICONOS DE HABILIDAD siguen en el rincon superior
// derecho (x 370..446, anclados con el +370 de drawKeyIcon y _ico=216).
// El BORDE IZQUIERDO entero es la COLUMNA DEL EQUIPO (retratos + barras,
// obj_level v12) con los ALIADOS apilando de ABAJO hacia ARRIBA y TU
// fila propia (retrato + barrita "+NN", la unica barra de tu vida tras
// eliminar la barra verde grande v10) anclada en la banda inferior
// 242-268. La barrita nega vive encima de esa barrita propia.
// _mob sigue moviendo SOLO lo que ya movia (las emociones).
var _ico = 216;

drawKeyIcon = function(_spr, _frame, _artW, _key, _xx, _yy, _col, _alpha, _hintX)
{
        // v10: todo el grupo de iconos se ancla en x=370 (antes 0): el
        // borde izquierdo ya no esta disponible (columna del equipo).
        _xx += 370;
        var _h = sprite_get_height(_spr);

        // v4.3b: caja de contenido real del sprite (medida sobre los PNG):
        // _ox/_oy = columnas/filas vacias antes del contenido,
        // _ih     = alto del contenido, _iR = ultima columna con pixeles.
        // draw_sprite_part_ext solo pide zonas que existen de verdad en la
        // textura (GameMaker recorta los margenes transparentes al
        // empaquetar): pedir filas/columnas ya recortadas hacia que el
        // icono NO se dibujara (caso visible: la trampa de Amelia).
        var _ox = 0;
        var _oy = 0;
        var _ih = _h;
        var _iR = sprite_get_width(_spr) - 1;
        if(_spr == spr_gui_amelia_trap)          { _oy = 2; _ih = 9;  _iR = 47; }
        else if(_spr == spr_gui_chaosattack)     { _oy = 3; _ih = 8;  _iR = 18; }
        else if(_spr == spr_gui_chaoswalldash)   { _ox = 1; _oy = 1; _ih = 11; _iR = 48; }
        else if(_spr == spr_gui_chaosslime)      { _ox = 1; _oy = 1; _ih = 11; _iR = 27; }
        else if(_spr == spr_gui_exetiorattack)   { _ox = 1;             _iR = 42; }
        else if(_spr == spr_gui_metal_amy_lazer) { _oy = 2; _ih = 9;  _iR = 23; }
        else if(_spr == spr_gui_sonicparry)      { _ox = 4;             _iR = 32; }

        // 1) arte del icono recortado: columnas [_ox .. _artW), filas
        //    [_oy .. _oy+_ih), SIN la zona de la letra horneada
        if(_artW > 0)
                draw_sprite_part_ext(_spr, _frame, _ox, _oy, _artW - _ox, _ih, _xx + _ox, _yy + _oy, 1, 1, _col, _alpha);

        // 2) tecla REAL de la configuracion (v5.5: tambien en Android —
        //    los botones tactiles simulan estas teclas, ver cabecera)
        var _tw = scr_text_spr(_xx + _artW + 2, _yy + floor((_h - 6) / 2), scr_controls_keycode_to_key(_key), _col, _alpha);

        // 3) pista horneada posterior (flechas del walldash / golpe aereo),
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

if(instance_exists(global.player) && !global.player.isDead)
{
        switch(global.character)
        {
                case CHARACTER_EXE: //exe
                {
                        switch(global.exeCharacter)
                        {
                                case EXE_ORIGINAL:
                                        var prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = (min(global.player.invisTimer, 0) / EXE_INVIS_RECHARGE);
                                        drawKeyIcon(spr_gui_exeinvisability, 0, 25, global.KeyC, prog * 4, 250 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_CHAOS:
                                        if(global.player.stuckTimer <= 30/2)
                                        {
                                                var _cf = !global.player.isGrounded;
                                                prog = global.player.slimeTimer > 0 ? 0 : 1.0 - (min(global.player.attackTimer, 120) / 120.0);
                                                drawKeyIcon(spr_gui_chaosattack, _cf, 19, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, _cf ? 31 : 0);
                                        }
                                        else
                                        {
                                                var frame = 2;

                                                if(global.player.isGrounded && global.player.stuckDir > 0)
                                                        frame = 1;

                                                if(global.player.isGrounded && global.player.stuckDir < 0)
                                                        frame = 0;

                                                prog = 1;
                                                drawKeyIcon(spr_gui_chaoswalldash, frame, 19, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 31);
                                        }

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, prog && global.player.slimeTimer <= 0 ? c_white : c_red, global.player.slimeTimer <= 0 ? (prog ? 1 : 0.5) : 0, 0);

                                        prog = global.player.slimeTimer > 0 ? 1 : (min(global.player.slimeTimer, 0) / -CHAOS_INVIS_RECHARGE);
                                        drawKeyIcon(spr_gui_chaosslime, 0, 18, global.KeyC, prog * 4, 250 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_EXETIOR:
                                        var _ef = !global.player.isGrounded;
                                        prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        drawKeyIcon(spr_gui_exetiorattack, _ef, 19, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, _ef ? 31 : 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = (1.0 - (global.player.bringTimer / EXETIOR_BRING_RECHARGE));
                                        drawKeyIcon(spr_gui_exetiorring, 0, 20, global.KeyC, prog * 4, 250 - _ico, prog == 1.0 && global.player.canSpawnRings ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_EXELLER:
                                        prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = 1.0 - (global.player.cloneTimer / EXELLER_CLONE_RECHARGE);
                                        var spr = spr_gui_exellerclone;

                                        if((keyboard_check(global.KeyDown) || keyboard_check(global.KeyUp)))
                                        {
                                                if(global.player.cloneCount > 0)
                                                {
                                                        spr = spr_gui_exellerclone2;
                                                        prog = 1;
                                                }
                                        }

                                        if(spr == spr_gui_exellerclone && global.player.cloneCount >= 2)
                                                prog = 0;

                                        drawKeyIcon(spr, 0, spr == spr_gui_exellerclone ? 20 : 47, global.KeyC, prog * 4, 250 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_METALAMY:
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
                                }

                                // v1 (D.I.B.): JINNA — golpe X (puno basico, commit),
                                // teletransporte C y agarre V. Sus dos iconos propios
                                // (spr_gui_jinateleport / spr_gui_jinagrub) traen la
                                // tecla horneada del mod: se recorta y se dibuja la
                                // REAL (mecanismo v4.3, como en el resto del HUD).
                                // v4: el hueco V tiene DOS modos — agarre (V sola) y
                                // portal trampa (V + ABAJO) — con recargas INDEPENDIENTES
                                // e iconos que se INTERCAMBIAN al presionar abajo (patron
                                // del chaos aereo / exellerclone2; sprite nuevo
                                // spr_gui_jinatrap: portal + "▼+").
                                case EXE_JINNA:
                                {
                                        // X: golpe (dano 20 via PLAYER_ATTACKING)
                                        var _jprog = 1.0 - (global.player.attackTimer / 120.0);
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, _jprog * 10, 240 - _ico, _jprog == 1.0 ? c_white : c_red, _jprog, 0);

                                        // Z: salto libre de los killers
                                        _jprog = (global.player.hurttime <= 0 && global.player.shockedTimer <= 0) ? 1.0 : 0.0;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _ico, _jprog ? c_white : c_red, _jprog ? 1 : 0.5, 0);

                                        // C: teletransporte (icono del mod: portal)
                                        // v6 — C: DOS modos (patron de la V). Sola = tele-
                                        // transporte (icono del mod); con ABAJO = INVOCACION
                                        // de minions (reusa el icono del portal con "▼+",
                                        // spr_gui_jinatrap) con SU recarga propia de 25 s.
                                        if(keyboard_check(global.KeyDown))
                                        {
                                                // MODO INVOCAR (C + ABAJO): los atrapados en el
                                                // portal se materializan a sus pies como minions
                                                _jprog = 1.0 - (global.player.jinnaMinionCd / JINNA_MINION_RECHARGE);
                                                drawKeyIcon(spr_gui_jinatrap, 0, 25, global.KeyC, _jprog * 4, 250 - _ico, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        else
                                        {
                                                var _jt = global.player.jinnaTeleCd;
                                                _jprog = 1.0 - (_jt / JINNA_TELEPORT_RECHARGE);
                                                var _jteleAct = global.player.jinnaTeleWindup > 0;
                                                drawKeyIcon(spr_gui_jinateleport, 0, 25, global.KeyC, _jprog * 4, 250 - _ico, (_jprog >= 1.0 || _jteleAct) ? c_white : c_red, _jteleAct ? 1 : _jprog, 0);
                                        }

                                        // v4 — V: DOS modos con enfriamientos INDEPENDIENTES
                                        // (v3 BUG: C y V se dibujaban ambos en x = prog*4 y
                                        // quedaban MONTADOS uno encima del otro; el hueco V
                                        // pasa a la derecha, patron Metal Amy). El icono
                                        // CAMBIA al presionar ABAJO: garra = agarre con SU
                                        // recarga; portal + "▼+" = trampa con la SUYA.
                                        if(keyboard_check(global.KeyDown))
                                        {
                                                // MODO TRAMPA (V + ABAJO): icono del portal
                                                // trampa (spr_gui_jinatrap) y SU recarga propia
                                                _jprog = 1.0 - (global.player.jinnaTrapCd / JINNA_TRAP_RECHARGE);
                                                drawKeyIcon(spr_gui_jinatrap, 0, 32, global.KeyV, 44 + _jprog * 10, 250 - _ico, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        else
                                        {
                                                // MODO AGARRE (V sola): garra del mod
                                                _jprog = 1.0 - (global.player.jinnaGrabCd / JINNA_GRAB_RECHARGE);
                                                drawKeyIcon(spr_gui_jinagrub, 0, 26, global.KeyV, 44 + _jprog * 10, 250 - _ico, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        break;
                                }
                        }

                        break;
                }

                case CHARACTER_TAILS: //tails
                {
                        var prog = (min(global.player.flyTimer, 0) / -420.0);
                        drawKeyIcon(spr_gui_tailsfly, scr_esbirro_hud(global.player), 26, global.KeyA, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        // v4.3: la X horneada y el texto (hold) de este sprite se recortan
                        // (el misil ocupa las filas 0-10) y el texto se redibuja dinamico.
                        var val = scr_esbirro_hud(global.player) ? ETAILS_ATTACK_RECHARGE : TAILS_ATTACK_RECHARGE;
                        prog = 1.0 - (global.player.attackTimer / val);
                        var _tcol = prog == 1.0 ? c_white : c_red;
                        draw_sprite_part_ext(spr_gui_tailsattack, 0, 0, 0, 25, 11, 370 + prog * 12, 250 - _ico, 1, 1, _tcol, prog);

                        // v5.5: tecla y "(hold)" tambien en Android (mismo
                        // criterio que drawKeyIcon)
                        scr_text_spr(370 + prog * 12 + 27, 250 - _ico + 2, scr_controls_keycode_to_key(global.KeyB), _tcol, prog);
                        scr_text_spr(370 + prog * 12 + 3, 250 - _ico + 12, "(hold)", _tcol, prog);
                        break;
                }

                case CHARACTER_KNUX:
                {
                        var prog = 1.0 - (min(global.player.glideTimer, KNUX_GLIDE_RECHARGE) / KNUX_GLIDE_RECHARGE);
                        drawKeyIcon(spr_gui_knuxglide, scr_esbirro_hud(global.player), 23, global.KeyA, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        var val = scr_esbirro_hud(global.player) ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        prog = 1.0 - (min(global.player.attackTimer, val) / val);
                        drawKeyIcon(spr_gui_knuxattack, 0, 19, global.KeyB, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                // v13 — ROUGE (REWORK): icono de VUELO patron VANILLA (Z:
                // mantener = subir, soltar = bajar; la barrita se llena
                // mientras recarga en el suelo, 15 s) + TORNADO X (i-frames,
                // recarga 20 s) + SPINDASH (abajo + Z, sin cooldown), con
                // sus sprites del TTB (spr_gui_rougeglide /
                // spr_gui_rougeattack / placeholder de Sonic para el spin).
                // Nada tiene version exe (jamais se demoniza): recargas de
                // superviviente siempre.
                // v33 (fix duena "los iconos no cambian"): el HUD CAMBIA con
                // la modalidad de la V — cada set ensena SUS iconos con SUS
                // recargas reales (blanco = listo, rojo = recargando), y la
                // V abajo lleva el icono del set puesto (brillante 2 s al
                // ciclar con modeFlash, tono suave fijo despues — igual que
                // el nombre bajo la barra de vida del Draw_64). El set normal
                // queda INTACTO (vuelo/tornado/spindash donde siempre) y solo
                // se le suma la V; en los otros modos el vuelo y el spin NO
                // se dibujan (no aplican: por eso "la de vuelo no se veia"
                // cuando llevaba otro set puesto).
                case CHARACTER_ROUGE:
                {
                        // ---- V: el icono del CAMBIO (fila nueva, abajo del
                        // todo para no montarse con el spin de su set) ----
                        var _vSpr = spr_gui_rougeglide; // su set: el vuelo
                        var _vW = 23;

                        if(global.player.rougeMode == ROUGE_MODE_EGGMAN)
                        {
                                _vSpr = spr_gui_eggshield;
                                _vW = 20;
                        }
                        else if(global.player.rougeMode == ROUGE_MODE_SUPPORT)
                        {
                                _vSpr = spr_gui_sallyshield;
                                _vW = 20;
                        }
                        else if(global.player.rougeMode == ROUGE_MODE_ATTACK)
                        {
                                _vSpr = spr_gui_sallyattack;
                                _vW = 23;
                        }

                        drawKeyIcon(_vSpr, 0, _vW, global.KeyV, 10, 276 - _ico, global.player.modeFlash > 0 ? c_white : c_lime, global.player.modeFlash > 0 ? 1 : 0.65, 0);

                        if(global.player.rougeMode == ROUGE_MODE_ROUGE)
                        {
                                // ---- set normal (v13, intacto) ----
                                // VUELO patron VANILLA: la puerta flyTimer cuenta
                                // hacia atras desde ROUGE_FLY_RECHARGE cuando NO vuela
                                // (0 = listo). Icono listo = blanco, recarga = rojo.
                                var _rprog = 1.0 - (max(global.player.flyTimer, 0) / ROUGE_FLY_RECHARGE);
                                drawKeyIcon(spr_gui_rougeglide, 0, 23, global.KeyA, _rprog * 10, 240 - _ico, _rprog == 1.0 ? c_white : c_red, _rprog, 0);

                                // TORNADO (X en tierra): recarga attackTimer.
                                var prog = 1.0 - (min(global.player.attackTimer, ROUGE_ATTACK_RECHARGE) / ROUGE_ATTACK_RECHARGE);
                                drawKeyIcon(spr_gui_rougeattack, 0, 19, global.KeyB, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                                // SPINDASH (abajo + Z): sin cooldown (su coste
                                // es el tiempo de revolucioneo), patron del de Sonic:
                                // siempre visible, blanco = listo, brilla mas al cargar.
                                var _rspr = asset_get_index("spr_gui_rougespindash");
                                if(is_undefined(_rspr) || _rspr < 0)
                                        _rspr = spr_gui_sonicspindash; // placeholder hasta que exista el propio

                                var _rcharging = variable_instance_exists(global.player.id, "isSpinCharging") && global.player.isSpinCharging;
                                var _rchg = variable_instance_exists(global.player.id, "spinCharge") ? global.player.spinCharge / ROUGE_SPINDASH_CHARGE_MAX : 0;
                                drawKeyIcon(_rspr, 0, 33, global.KeyA, 10, 222 - _ico, _rcharging ? c_red : c_white, _rcharging ? 0.5 + _rchg * 0.5 : 1, 0);

                                // ---- C: INVISIBILIDAD (v36: el icono y el
                                // boton que faltaban) — el icono del exe
                                // (patron de SU hud): barrita cuenta la
                                // RECARGA; roja mientras dura la
                                // invisibilidad y durante la recarga,
                                // blanca = lista ----
                                var _iprog = min(global.player.invisTimer, 0) / ROUGE_INVIS_RECHARGE;
                                drawKeyIcon(spr_gui_exeinvisability, 0, 25, global.KeyC, _iprog * 4, 294 - _ico, _iprog == 1.0 ? c_white : c_red, _iprog, 0);
                        }
                        else if(global.player.rougeMode == ROUGE_MODE_EGGMAN)
                        {
                                // ---- X: ESCUDO ELECTRICO (recarga total del
                                // doctor: activo + espera, la misma formula
                                // del special) ----
                                var _etot = ROUGE_ESHIELD_TIME + (global.player.revivalTimes >= 2 ? ROUGE_ESHIELD_RECHARGE_E : ROUGE_ESHIELD_RECHARGE);
                                var _eprog = 1.0 - (max(global.player.eShieldRecharge, 0) / _etot);
                                drawKeyIcon(spr_gui_eggshield, 0, 20, global.KeyB, _eprog * 10, 240 - _ico, _eprog == 1.0 ? c_white : c_red, _eprog, 0);

                                // ---- C: MINA/SENSOR (25 s del doctor) ----
                                var _mprog = 1.0 - (max(global.player.trackerRecharge, 0) / EGGMAN_TRACKER_RECHARGE);
                                drawKeyIcon(spr_gui_eggtrack, 0, 24, global.KeyC, _mprog * 10, 258 - _ico, _mprog == 1.0 ? c_white : c_red, _mprog, 0);
                        }
                        else if(global.player.rougeMode == ROUGE_MODE_SUPPORT)
                        {
                                // ---- X: ESCUDO DE SALLY (30 s / 15 debilitada) ----
                                var _stot = global.player.revivalTimes >= 2 ? ROUGE_SHIELD_RECHARGE_E : ROUGE_SHIELD_RECHARGE;
                                var _sprog = 1.0 - (max(global.player.shieldRechrage, 0) / _stot);
                                drawKeyIcon(spr_gui_sallyshield, 0, 20, global.KeyB, _sprog * 10, 240 - _ico, _sprog == 1.0 ? c_white : c_red, _sprog, 0);

                                // ---- C: ANILLOS DE VANILLA (15 s) ----
                                var _gprog = 1.0 - (max(global.player.ringsTimer, 0) / ROUGE_RINGS_RECHARGE);
                                drawKeyIcon(spr_gui_creamrings, 0, 20, global.KeyC, _gprog * 10, 258 - _ico, _gprog == 1.0 ? c_white : c_red, _gprog, 0);
                        }
                        else // ROUGE_MODE_ATTACK
                        {
                                // ---- X: PATADA DE SALLY (15 s / 7,5 debilitada;
                                // v34: recarga PROPIA kickRecharge — antes leia
                                // attackTimer y el tornado la dejaba muerta 20 s) ----
                                var _ktot = global.player.revivalTimes >= 2 ? ROUGE_KICK_RECHARGE / 2 : ROUGE_KICK_RECHARGE;
                                var _kprog = 1.0 - (min(max(global.player.kickRecharge, 0), _ktot) / _ktot);
                                drawKeyIcon(spr_gui_sallyattack, 0, 23, global.KeyB, _kprog * 10, 240 - _ico, _kprog == 1.0 ? c_white : c_red, _kprog, 0);

                                // C sin asignar todavia (proximo set): no se dibuja
                        }
                        break;
                }

                // v5/v2 (KRIS): DOBLE SALTO (Z aire) + ESPADA (X) + ESCUDO
                // (C, patron parry: el relleno muestra el CD que falta y
                // blanco = listo Y en tierra). Sin version exe (jamas se
                // demoniza).
                // v94 (ICONOS ANIMADOS, pedido de la duena: "el mismo
                // tratamiento" que Metal Amy v93 — patron «Chocola» de
                // Vanilla): fuera los placeholders prestados que esperaban
                // sprites GUI propios que nunca llegaron (el jetpack de
                // Eggman, el ataque de Amy, el escudo de Eggman). Cada
                // habilidad se dibuja con SU PROPIA animacion de juego
                // ciclando frames (drawMiniIcon):
                //   doble salto -> spr_kris_jump (6 frames)
                //   espada      -> spr_kris_attack1_air1 (4 frames)
                //   escudo      -> spr_kris_block_success_ground (9 frames)
                case CHARACTER_KRIS:
                {
                        // Z — DOBLE SALTO: spr_kris_jump (6 f, contenido
                        // (5,1,35,42) medido sobre los PNG, regla v4.3b de
                        // zonas que existen de verdad en la textura) al 38%.
                        // Blanco = listo; rojo = recargando.
                        var _kprog0 = 1.0 - (max(global.player.djumpRecharge, 0) / KRIS_DJUMP_RECHARGE);
                        drawMiniIcon(spr_kris_jump, 5, 1, 35, 42, 0.38, global.KeyA, 372, 222 - _ico, _kprog0 == 1.0 ? c_white : c_red, _kprog0, 0);

                        // X — ESPADA: spr_kris_attack1_air1 (4 f, contenido
                        // (8,0,53,70)) al 24% — el tajo base: la tierra y la
                        // fase 1 aerea usan este mismo sprite.
                        var _kprog1 = 1.0 - (min(max(global.player.attackTimer, 0), KRIS_ATTACK_RECHARGE) / KRIS_ATTACK_RECHARGE);
                        drawMiniIcon(spr_kris_attack1_air1, 8, 0, 53, 70, 0.24, global.KeyB, 372, 240 - _ico, _kprog1 == 1.0 ? c_white : c_red, _kprog1, 0);

                        // C — ESCUDO: spr_kris_block_success_ground (9 f,
                        // contenido (10,7,35,40)) al 40% — el bloqueo que
                        // sale al frente. Patron parry: blanco = listo Y en
                        // tierra; rojo = lo demas. SIEMPRE visible (v2).
                        var _kmax = max(global.player.parryCooldownMax, 1);
                        var _kprog2 = 1.0 - (max(global.player.parryCooldown, 0) / _kmax);
                        var _kready = (_kprog2 >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                        drawMiniIcon(spr_kris_block_success_ground, 10, 7, 35, 40, 0.4, global.KeyC, 372, 258 - _ico, _kready, _kprog2, 0);
                        break;
                }

                case CHARACTER_EGGMAN:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / EGGMAN_DJUMP_RECHARGE);
                        drawKeyIcon(spr_gui_eggdjump, 0, 20, global.KeyA, prog * 10, 222 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / EGGMAN_SHIELD_RECHARGE);
                        drawKeyIcon(spr_gui_eggshield, 0, 20, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.trackerRecharge, 0) / EGGMAN_TRACKER_RECHARGE);
                        drawKeyIcon(spr_gui_eggtrack, 0, 38, global.KeyC, prog * 10, 258 - _ico, (global.player.isColliding && prog == 1.0) ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_AMY:
                {
                        var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_BIGJUMP_RECHARGE);
                        drawKeyIcon(spr_gui_amyhjump, 0, 32, global.KeyA, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        var val = scr_esbirro_hud(global.player) ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_AMY_CANON:
                {
                                // v94 (ICONOS ANIMADOS, pedido de la duena: "el mismo
                                // tratamiento" que Metal Amy v93 — patron «Chocola» de
                                // Vanilla): cada habilidad se dibuja con SU PROPIA
                                // animacion de juego ciclando frames (drawMiniIcon),
                                // en vez de los iconos GUI estaticos. La logica de
                                // color/recarga de cada icono queda INTACTA (v4.x/v83).

                                // Icono 1: SALTO DE MARTILLO (tecla Z, en el suelo): la
                                // animacion propia del salto — spr_amy_attack2_canon
                                // (4 frames, contenido (1,0,47,59)) al 28%. El relleno
                                // muestra el CD; blanco = listo Y en el suelo.
                                var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_CANON_BIGJUMP_RECHARGE);
                                var b1 = (prog == 1.0 && global.player.isGrounded) ? c_white : c_red;
                                drawMiniIcon(spr_amy_attack2_canon, 1, 0, 47, 59, 0.28, global.KeyA, 372, 222 - _ico, b1, prog, 0);

                                // Icono 2: IMPULSO AEREO DE TAROT (tecla X, SOLO en el
                                // aire): el impulso de tarot — spr_amy_attack1_canon
                                // (2 frames en loop, contenido (1,2,45,42)) al 38%.
                                // El relleno muestra el CD; blanco = lista Y en el aire
                                // (espejo del icono 3, que exige estar en el suelo).
                                var val = scr_esbirro_hud(global.player) ? AMY_CANON_ETAROTDASH_RECHARGE : AMY_CANON_TAROTDASH_RECHARGE;
                                prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                                var b2 = (prog == 1.0 && !global.player.isGrounded) ? c_white : c_red;
                                drawMiniIcon(spr_amy_attack1_canon, 1, 2, 45, 42, 0.38, global.KeyB, 372, 240 - _ico, b2, prog, 0);

                        // Icono 3: ACOMETIDA DE MARTILLO (tecla C). v4.3: la C ya no esta
                        // horneada: se dibuja la tecla real de special2.
                        // v83: la C tiene DOS caras y el icono muestra la que toca. En el aire
                        // (cualquier forma) es el LSA: comparte recarga con la acometida, asi que
                        // blanco cuando esta listo TAMBIEN en el aire (antes se veia rojo). En
                        // tierra con la SUPER fase 2 es la LANZADA DE MARTILLO (hammerThrowTimer),
                        // la unica habilidad con recarga que no tenia icono. En tierra con la
                        // super fase 1 la C no hace nada: rojo.
                        // v94: la CARA tambien anima con su sprite real: LSA en el aire
                        // (spr_amy_light_speed_canon, 1 f + vaiven de vuelo), LANZADA
                        // en la super fase 2 (spr_super_amy_hrow_hammer, 10 f) y la
                        // acometida en tierra (spr_amy_attack3_canon_, 8 f).
                        var _acThrow = (global.player.superFormPhase >= 2 && global.player.isGrounded);
                        var _acNoC = (global.player.superFormPhase == 1 && global.player.isGrounded);
                        var _acCd = global.player.dashTimer;
                        val = scr_esbirro_hud(global.player) ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;

                        if(_acThrow)
                        {
                                _acCd = global.player.hammerThrowTimer;
                                val = AMY_SUPER_HTHROW_RECHARGE;
                        }

                        prog = 1.0 - (max(_acCd, 0) / val);
                        var b = (prog == 1.0 && !_acNoC) ? c_white : c_red;

                        if(_acThrow)
                                drawMiniIcon(spr_super_amy_hrow_hammer, 0, 3, 56, 52, 0.3, global.KeyC, 372, 258 - _ico, b, prog, 0);
                        else if(!global.player.isGrounded)
                                drawMiniIcon(spr_amy_light_speed_canon, 0, 0, 35, 33, 0.42, global.KeyC, 372, 258 - _ico, b, prog, 200);
                        else
                                drawMiniIcon(spr_amy_attack3_canon_, 25, 18, 57, 52, 0.3, global.KeyC, 372, 258 - _ico, b, prog, 0);

                        // Icono 4: PARRY (tecla V, v4.0). Mismas fijaciones que el de
                        // Sonic (estados 60/61/64). El relleno muestra el CD que falta:
                        // como el CD depende de COMO termino el ultimo intento
                        // (fallo/exito), se guarda la duracion total en
                        // parryCooldownMax al aplicarlo y asi el icono siempre arranca
                        // lleno. Blanco = listo Y en el suelo (el parry es solo en
                        // tierra); rojo = lo demas.
                        // v94: anima con el parry exitoso REAL de Amy (spr_amy_
                        // parry_exitoso, 10 frames, contenido (6,4,38,42)) al 38%.
                                                // v4.1: se dibuja AL LADO del icono de la acometida (misma fila
                        // que la C, a su derecha) y no DEBAJO: la vista mide 480x270 y una
                        // cuarta fila apilada (y=276) caia FUERA de pantalla (por eso no
                        // salia). C y V comparten fila, como Z X C V en el teclado; en
                        // Android (y-200) tampoco choca con el boton G (23,81).
                        var _pmax = max(global.player.parryCooldownMax, 1);
                        var _pprog = 1.0 - (max(global.player.parryCooldown, 0) / _pmax);
                        var _pready = (_pprog >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                        drawMiniIcon(spr_amy_parry_exitoso, 6, 4, 38, 42, 0.38, global.KeyV, 416, 258 - _ico, _pready, _pprog, 0);
                        break;
                }
                case CHARACTER_FLEETWAY_AMY:
                {
                        // Icono 1 (tecla A, en el aire): DJ DOBLE SALTO. El relleno
                        // muestra el CD; blanco = lista Y en el aire (espejo del
                        // icono de Amy Canon). El timer vuela en negativo mientras
                        // dura el impulso: se ignora esa fase para el icono.
                        // v2.14.1: leido via global.player (antes iba a pelo y
                        // petaba: "obj_playerui.djTimer not set", que el scope
                        // del Draw es el propio obj_playerui, no el jugador).
                        var _djReady = (global.player.djTimer == 0);
                        var _djProg = _djReady ? 1.0 : (global.player.djTimer < 0 ? 0.0 : 1.0 - (global.player.djTimer / (scr_esbirro_hud(global.player) ? FW_EDJ_RECHARGE : FW_DJ_RECHARGE)));
                        var b1 = (_djReady && !global.player.isGrounded) ? c_white : c_red;
                        drawKeyIcon(spr_gui_amydj_fw, 0, 32, global.KeyA, _djProg * 10, 222 - _ico, b1, _djProg, 0);

                        // Icono 2 (tecla B): PUÑO/PATADA. El relleno muestra el CD.
                        var val2 = scr_esbirro_hud(global.player) ? FW_EATTACK_RECHARGE : FW_ATTACK_RECHARGE;
                        var prog2 = 1.0 - (max(global.player.attackTimer, 0) / val2);
                        drawKeyIcon(spr_gui_amyattack_fw, 0, 23, global.KeyB, prog2 * 10, 240 - _ico, prog2 == 1.0 ? c_white : c_red, prog2, 0);

                        // Icono 3 (tecla C): BALLESTA — v2.15 («La Torre»): cargador
                        // de 3 flechas (recarga 8 s por flecha, 0,5 s entre disparos).
                        // El relleno muestra el cargador entero (flechas + fraccion de
                        // la que esta recargando); los pips debajo cuentan las listas.
                        // Blanco = hay flecha Y paso el CD de disparo; rojo = lo demas.
                        // Mientras dura cbTimer la lleva en la mano (sprites cbamy).
                        // v4.3 (fix exe): demonizada (revivalTimes >= 2) NO puede usar
                        // la ballesta — icono en rojo con el cargador vacio de llenado.
                        // v10: check CRUDO (no scr_esbirro_hud): el SUBDITO NEGATIVO
                        // TAMPOCO puede usarla — sigue en el bando EXE y las flechas
                        // son arma anti-exe (el pedido de balance de v4.3 cubre a
                        // cualquier jugador del lado demonico, nega incluido).
                        var _arrows = global.player.fwArrows;
                        var _prog3 = (global.player.revivalTimes >= 2) ? 0 : min(1.0, (_arrows + (_arrows < FW_ARROW_MAX ? 1.0 - max(global.player.fwArrowReload, 0) / FW_ARROW_RELOAD : 0)) / FW_ARROW_MAX);
                        var b3 = (global.player.revivalTimes < 2 && _arrows > 0 && global.player.crossBow <= 0) ? c_white : c_red;
                        drawKeyIcon(spr_gui_amycrossbow_fw, 0, 23, global.KeyC, _prog3 * 10, 258 - _ico, b3, _prog3, 0);

                        // Pips de municion: un rectangulo por flecha disponible
                        draw_set_color(b3);
                        draw_set_alpha(0.9);
                        for(var _pi = 0; _pi < FW_ARROW_MAX; _pi++)
                                draw_rectangle(372 + _pi * 7, 258 - _ico + 12, 377 + _pi * 7, 261 - _ico + 12, _pi >= _arrows);
                        draw_set_color(c_white);
                        draw_set_alpha(1);
                        break;
                }

                case CHARACTER_SONIC:
                {
                        // Icono (tecla C): PARRY (v3.2). El relleno muestra el CD
                        // que falta: como el CD depende de COMO termino el ultimo
                        // intento (fallo/exito x normal/powerboost), se guarda la
                        // duracion total en parryCooldownMax al aplicarlo y asi el
                        // icono siempre arranca lleno. Blanco = listo Y en el
                        // suelo (el parry es solo en tierra); rojo = lo demas.
                        // Si spr_gui_sonicparry no existiera en el proyecto, no se
                        // dibuja pero tampoco crashea (mismo patron que el
                        // spindash de abajo).
                        var _sprParry = asset_get_index("spr_gui_sonicparry");
                        if(_sprParry >= 0)
                        {
                                var _pmax = max(global.player.parryCooldownMax, 1);
                                var _pprog = 1.0 - (max(global.player.parryCooldown, 0) / _pmax);
                                var _pready = (_pprog >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                                drawKeyIcon(_sprParry, 0, 19, global.KeyC, _pprog * 10, 222 - _ico, _pready, _pprog, 0);
                        }

                        // Icono (tecla X): EL GOLPE. Reutiliza el icono generico del
                        // ataque de Amy; cuando crees spr_gui_sonicattack, cambialo aqui.
                        var val = scr_esbirro_hud(global.player) ? SONIC_EATTACK_RECHARGE : SONIC_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        // Icono (abajo + Z): SPINDASH. Sin cooldown: su coste es el
                        // tiempo de revolucioneo. Siempre visible: blanco = listo para
                        // cargar; rojo = cargando la bola (brilla mas al llenarse).
                        // Icono extraido del mod TD2DR X SONIC de Renx Diamond.
                        // Si spr_gui_sonicspindash no existe (aun sin crear en el IDE),
                        // no se dibuja pero tampoco crashea.
                        var _sprSpindash = asset_get_index("spr_gui_sonicspindash");
                        if(_sprSpindash >= 0)
                        {
                                if(global.player.isSpinCharging)
                                {
                                        var charge = global.player.spinCharge / SONIC_SPINDASH_CHARGE_MAX;
                                        drawKeyIcon(_sprSpindash, 0, 33, global.KeyA, charge * 10, 258 - _ico, charge >= 1.0 ? c_white : c_red, 0.4 + charge * 0.6, 0);
                                }
                                else
                                        drawKeyIcon(_sprSpindash, 0, 33, global.KeyA, 10, 258 - _ico, c_white, 1, 0);
                        }

                        // Icono (Z en el aire): DROP DASH (v3). Sin cooldown: su coste
                        // es medio segundo de agarre en el aire. Se dibuja AL LADO del
                        // spindash, en su misma fila (como el parry de Amy Canon v4.1:
                        // la vista mide 480x270 y una fila mas caeria fuera de
                        // pantalla). El relleno es el armado (dropDashTimer / HOLD);
                        // blanco = en el aire tras saltar (se puede armar), rojo = en
                        // tierra o vuelo sin salto; lleno y fijo = ARMADO: al aterrizar
                        // sale disparado. Usa el sprite spr_gui_sonicdropdash (existia
                        // en el proyecto sin usar). Si no existiera, no se dibuja pero
                        // tampoco crashea (mismo patron que el parry y el spindash).
                        var _sprDropdash = asset_get_index("spr_gui_sonicdropdash");
                        if(_sprDropdash >= 0)
                        {
                                if(global.player.dropDashReady)
                                        drawKeyIcon(_sprDropdash, 0, 34, global.KeyA, 54, 258 - _ico, c_white, 1, 0);
                                else
                                {
                                        var _ddprog = min(global.player.dropDashTimer / SONIC_DROPDASH_HOLD, 1.0);
                                        var _ddcol = (global.player.dropDashFromJump && !global.player.isGrounded) ? c_white : c_red;
                                        drawKeyIcon(_sprDropdash, 0, 34, global.KeyA, 44 + _ddprog * 10, 258 - _ico, _ddcol, 0.4 + _ddprog * 0.6, 0);
                                }
                        }
                        break;
                }
                case CHARACTER_CREAM:
                {
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        drawKeyIcon(spr_gui_creamfly, scr_esbirro_hud(global.player), 25, global.KeyA, prog * 10, 222 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.ringsTimer, 0) / (scr_esbirro_hud(global.player) ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        drawKeyIcon(spr_gui_creamrings, scr_esbirro_hud(global.player), 21, global.KeyC, prog * 10, 257 - _ico, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_VANILLA:
                {
                        // VANILLA: mismas habilidades que Cream (scr_cream_special),
                        // reusa sus iconos del HUD (vuelo Z, dash X, anillos C)
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        drawKeyIcon(spr_gui_creamfly, scr_esbirro_hud(global.player), 25, global.KeyA, prog * 10, 222 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.ringsTimer, 0) / (scr_esbirro_hud(global.player) ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        drawKeyIcon(spr_gui_creamrings, scr_esbirro_hud(global.player), 21, global.KeyC, prog * 10, 257 - _ico, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog, 0);
                                                // v83: ICONO 4 (tecla V) - CHOCA. La V de Vanilla NO es un ataque: manda a
                        // Chocola con Cream o la llama de vuelta, y no tenia icono. BLANCO = Chocola
                        // en casa, AMARILLO = fuera (con Cream / custodiando), GRIS = en caza o de
                        // regreso, ROJO = sin Chocola. Relleno = chocolaCd (la recarga compartida de
                        // su bloqueo/ataque).
                        var _vChoc = scr_chocola_get();
                        var _vCol = make_color_rgb(220, 60, 60);
                        var _vFill = 1.0;

                        if(instance_exists(global.player) && variable_instance_exists(global.player.id, "chocolaCd"))
                                _vFill = clamp(1.0 - (max(global.player.chocolaCd, 0) / VANILLA_CHOCOLA_CD), 0.35, 1.0);

                        if(_vChoc != noone)
                        {
                                if(_vChoc.mode == CHOCOLA_FOLLOW)
                                        _vCol = c_white;
                                else if(_vChoc.mode == CHOCOLA_GO_CREAM || _vChoc.mode == CHOCOLA_GUARD)
                                        _vCol = make_color_rgb(255, 220, 0);
                                else
                                        _vCol = make_color_rgb(170, 170, 170);
                        }

                        // Va en la fila de la C, a su derecha (mismo sitio que el parry de Amy
                        // Canon): el contenido de spr_vanilla_chocola_Idle (13x21 px) a mitad de
                        // escala + la tecla REAL de la V (respeta el remapeo de controles).
                        var _vSlide = (1.0 - _vFill) * 10;
                        var _vFrame = floor(current_time / 150) mod sprite_get_number(spr_vanilla_chocola_Idle);

                        draw_sprite_part_ext(spr_vanilla_chocola_Idle, _vFrame, 3, 2, 13, 21, 370 + 44 + _vSlide, 258 - _ico + 1, 0.5, 0.5, _vCol, _vFill);
                        scr_text_spr(370 + 44 + 9 + _vSlide, 258 - _ico + 3, scr_controls_keycode_to_key(global.KeyV), _vCol, _vFill);
break;
                }

                // ============================================================
                // v2.2 (TTB) / v2.7 — METAL SONIC: OVERDRIVE (X) y SPARK
                // FIELD (C), los nombres de su placa del TTB. El overdrive
                // v2.7 es AUTOMATICO (no hay que mantener X): arranca
                // solo, gana velocidad (11 -> 16 en 0.4 s) y se corta solo
                // al chocar contra una pared (ver scr_metal_special).
                // Iconos prestados del juego base hasta que haya propios.
                case CHARACTER_METAL:
                {
                        var prog = 1.0 - (max(global.player.dashTimer, 0) / (scr_esbirro_hud(global.player) ? EMETAL_OVERDRIVE_RECHARGE : METAL_OVERDRIVE_RECHARGE));
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.electroTimer, 0) / (scr_esbirro_hud(global.player) ? EMETAL_ELECTRO_RECHARGE : METAL_ELECTRO_RECHARGE));
                        drawKeyIcon(spr_gui_eggshield, 0, 20, global.KeyC, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                // ============================================================
                // v2.7 — AMELIA: spindash (abajo + Z), trampolin (X) y
                // trampa (C), cada una con SU icono (antes el trampolin
                // usaba el icono de la trampa y la trampa el eggtrack de
                // Eggman; el spindash no tenia icono). Sprites que ya
                // estaban en el proyecto, ninguno nuevo.
                case CHARACTER_AMELIA:
                {
                        // Icono (abajo + Z): SPINDASH (v2.6). Sin cooldown:
                        // su coste es el tiempo de revolucioneo. Mismo
                        // patron que el de Sonic: cargando, el relleno
                        // crece con la carga y brilla al llenarse; fuera
                        // de carga, blanco fijo. Reusa el icono de Sonic
                        // (para uno cobrizo propio, cambia ese PNG y ya).
                        var _sprSpin = asset_get_index("spr_gui_sonicspindash");
                        if(_sprSpin >= 0)
                        {
                                if(global.player.isSpinCharging)
                                {
                                        var _charge = global.player.spinCharge / AMELIA_SPINDASH_CHARGE_MAX;
                                        drawKeyIcon(_sprSpin, 0, 33, global.KeyA, _charge * 10, 222 - _ico, _charge >= 1.0 ? c_white : c_red, 0.4 + _charge * 0.6, 0);
                                }
                                else
                                        drawKeyIcon(_sprSpin, 0, 33, global.KeyA, 10, 222 - _ico, c_white, 1, 0);
                        }

                        // Icono (tecla X): TRAMPOLIN — el resorte
                        // (spr_gui_sonicspring; estaba en disco desde la
                        // extraccion del mod de Sonic y v2.7 lo registra
                        // en el .yyp, hasta ahora jamas se uso).
                        var prog = 1.0 - (max(global.player.bananaTimer, 0) / (scr_esbirro_hud(global.player) ? EAMELIA_BANANA_RECHARGE : AMELIA_BANANA_RECHARGE));
                        drawKeyIcon(spr_gui_sonicspring, 0, 33, global.KeyB, prog * 10, 240 - _ico, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog, 0);

                        // Icono (tecla C): TRAMPA — la trampa-oso que
                        // siempre fue suya (antes estaba en el slot X).
                        // v4.3c: artW 25 (antes 39). El sprite trae
                        // "[trampa] - ↓ + C" horneado (arte 0-18, guion
                        // 20-24, flecha 26-33, + 35-38, C 40-47), pero la
                        // trampa NO exige abajo: solo C + estar en el suelo
                        // (scr_amelia_special). Se corta en el guion y la
                        // tecla dinamica queda justo despues: "[trampa]-C".
                        prog = 1.0 - (max(global.player.trapTimer, 0) / (scr_esbirro_hud(global.player) ? EAMELIA_TRAP_RECHARGE : AMELIA_TRAP_RECHARGE));
                        drawKeyIcon(spr_gui_amelia_trap, 0, 39, global.KeyC, prog * 10, 258 - _ico, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog, 0);
                        break;
                }

                // ============================================================
                // v2.2 (TTB) — BLAZE: salto de fuego (Z), bola (X) y ardiente (C)
                case CHARACTER_BLAZE:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / (scr_esbirro_hud(global.player) ? EBLAZE_DJUMP_RECHARGE : BLAZE_DJUMP_RECHARGE));
                        drawKeyIcon(spr_gui_eggdjump, 0, 20, global.KeyA, prog * 10, 222 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.fireballTimer, 0) / (scr_esbirro_hud(global.player) ? EBLAZE_FIREBALL_RECHARGE : BLAZE_FIREBALL_RECHARGE));
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 240 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.burningTimer, 0) / (scr_esbirro_hud(global.player) ? EBLAZE_BURNING_RECHARGE : BLAZE_BURNING_RECHARGE));
                        drawKeyIcon(spr_gui_sallyshield, 0, 19, global.KeyC, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_SALLY:
                {
                        // v4.3: la patada aerea es KeyB (X) y el escudo KeyC (C);
                        // antes el comentario deca Z: el que manda es scr_sally_special.
                        var val = scr_esbirro_hud(global.player) ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);

                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;

                        if(global.player.isGrounded)
                                b = c_red;

                        drawKeyIcon(spr_gui_sallyattack, scr_esbirro_hud(global.player), 17, global.KeyB, prog * 10, 240 - _ico, b, prog, 0);

                        val = scr_esbirro_hud(global.player) ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE;
                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        drawKeyIcon(spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyC, prog * 10, 258 - _ico, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }
                case CHARACTER_SALLY_CANON:
                {
                        // SALLY CANON: tiene las mismas habilidades que Sally
                        // (scr_sally_special), asi que usa sus mismos iconos del
                        // HUD: la PATADA (tecla X, ver scr_sally_special) y el
                        // ESCUDO (tecla C). El relleno de cada icono muestra el
                        // CD que le falta; blanco = listo. La patada vale en el
                        // AIRE y EN TIERRA desde la fase 1 (v84: antes la de
                        // tierra era solo de la fase duelista).
                        var val = scr_esbirro_hud(global.player) ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);

                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;

                        drawKeyIcon(spr_gui_sallyattack, scr_esbirro_hud(global.player), 17, global.KeyB, prog * 10, 240 - _ico, b, prog, 0);

                        // v5.4 DUELISTA: icono del SPINDASH (abajo + Z), mismo
                        // patron que el de Sonic/Amelia (reusa su icono; sin
                        // cooldown: el coste es el revolucioneo). Solo en fase
                        // duelista: antes de su 1ra caida no tiene la habilidad.
                        if(global.player.duelista)
                        {
                                var _sprSpin = asset_get_index("spr_gui_sonicspindash");
                                
                                if(_sprSpin >= 0)
                                {
                                        if(global.player.isSpinCharging)
                                        {
                                                var _charge = global.player.spinCharge / SALLY_CANON_SPINDASH_CHARGE_MAX;
                                                drawKeyIcon(_sprSpin, 0, 33, global.KeyA, _charge * 10, 222 - _ico, _charge >= 1.0 ? c_white : c_red, 0.4 + _charge * 0.6, 0);
                                        }
                                        else
                                                drawKeyIcon(_sprSpin, 0, 33, global.KeyA, 10, 222 - _ico, c_white, 1, 0);
                                }
                        }

                        // v5.4: recarga propia del escudo canon (28 s, 2 menos
                        // que la vanilla) — la barra del icono usa SU macro.
                        val = SALLY_CANON_SHIELD_RECHARGE;
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
                }
        }

        // v12 (BARRA VERDE GRANDE ELIMINADA): pedido — "elimina la barra
        // verde grande y coloca la que es del personaje; no deben salir 2
        // barras que representen mi vida, yo quiero la que se ve con el
        // icono". El bloque v10 que dibujaba aqui la barra propia grande
        // (caja de retrato + barra segmentada + "+NN" a 2x) se borro
        // ENTERO: tu vida ahora la representa SOLO la fila propia de la
        // columna del equipo (obj_level v12): tu retrato (el icono de tu
        // personaje) + su barrita "+NN" (hudAllyBar), anclados en la banda
        // inferior 242-268, el puesto exacto que ocupaba la barra verde.
        // La barrita nega (bloque de abajo) vive sobre esa barrita propia.

        // v7 (toque negativo) — CARGA NEGATIVA DE JINNA (visible SOLO para
        // la victima, patron de la marca de debilidad de Metal Amy): una
        // barrita morada sobre la barra de vida v8 que se llena con cada golpe de
        // Jina (agarre/trampa +25, golpe X +15). A 100 llega la conversion
        // instantanea a súbdito negativo (el "negatimer" de Negagen). En
        // gracia (jinnaNegaGrace, su Antinegatemper) parpadea tenue.
        if(global.character != CHARACTER_EXE && global.player.revivalTimes < 2
        && variable_instance_exists(global.player.id, "jinnaNegaCharge")
        && global.player.jinnaNegaCharge > 0 && !global.player.isDead)
        {
                var _negaPct = global.player.jinnaNegaCharge / JINNA_NEGA_MAX;
                // v12: la barra verde grande ya NO existe — tu vida es la
                // barrita propia de la columna (obj_level: retrato + hudAllyBar
                // en la banda 242-268). Esta carga negativa vive ENCIMA de esa
                // barrita (justo sobre su funda 251-259): misma x (30) y misma
                // escala de anchura (46 px = 100%) que su relleno rojo.
                var _negaX = 30;
                var _negaY = 244;
                var _negaCol = make_color_rgb(120, 40, 160); // energía negativa: violeta
                var _negaAlpha = (variable_instance_exists(global.player.id, "jinnaNegaGrace") && global.player.jinnaNegaGrace > 0) ? 0.45 + 0.3 * sin(current_time / 90) : 0.9;

                draw_set_alpha(_negaAlpha);
                draw_set_color(c_black);
                draw_rectangle(_negaX - 1, _negaY - 1, _negaX + 47, _negaY + 5, false);
                draw_set_color(_negaCol);
                draw_rectangle(_negaX, _negaY, _negaX + 46 * _negaPct, _negaY + 4, false);
                draw_set_alpha(1);
                draw_set_color(c_white);
        }

        // v4.3b: el recordatorio de emociones recupera sus teclas, ahora
        // DINAMICAS: el PNG original tenia A/S/D horneadas junto a cada
        // cara (columnas 20-27 del sprite), pero se borraron para las
        // teclas dinamicas y quedaba el hueco vacio. El sprite se ancla
        // por su esquina superior DERECHA (origen 28,0): a x=470 ocupa
        // 442-470, asi que las teclas van en x=463, una por cara.
        if(global.character != CHARACTER_EXE && (global.player.state == IDLE || global.player.emotion))
        {
                var _ey = 222 - _mob;
                draw_sprite(spr_gui_emotions, 0, 470, _ey);

                // tecla REAL de cada emocion (remapeable) — v5.5: tambien
                // en Android (los botones tactiles D/E/F simulan KeyEm1/2/3)
                scr_text_spr(463, _ey + 3,  scr_controls_keycode_to_key(global.KeyEm1), c_white, 1);
                scr_text_spr(463, _ey + 17, scr_controls_keycode_to_key(global.KeyEm2), c_white, 1);
                scr_text_spr(463, _ey + 31, scr_controls_keycode_to_key(global.KeyEm3), c_white, 1);
        }
}
