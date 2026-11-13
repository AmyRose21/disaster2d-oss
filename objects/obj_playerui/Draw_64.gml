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

drawKeyIcon = function(_spr, _frame, _artW, _key, _xx, _yy, _col, _alpha, _hintX)
{
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
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = (min(global.player.invisTimer, 0) / EXE_INVIS_RECHARGE);
                                        drawKeyIcon(spr_gui_exeinvisability, 0, 25, global.KeyC, prog * 4, 250 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_CHAOS:
                                        if(global.player.stuckTimer <= 30/2)
                                        {
                                                var _cf = !global.player.isGrounded;
                                                prog = global.player.slimeTimer > 0 ? 0 : 1.0 - (min(global.player.attackTimer, 120) / 120.0);
                                                drawKeyIcon(spr_gui_chaosattack, _cf, 19, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, _cf ? 31 : 0);
                                        }
                                        else
                                        {
                                                var frame = 2;

                                                if(global.player.isGrounded && global.player.stuckDir > 0)
                                                        frame = 1;

                                                if(global.player.isGrounded && global.player.stuckDir < 0)
                                                        frame = 0;

                                                prog = 1;
                                                drawKeyIcon(spr_gui_chaoswalldash, frame, 19, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 31);
                                        }

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, prog && global.player.slimeTimer <= 0 ? c_white : c_red, global.player.slimeTimer <= 0 ? (prog ? 1 : 0.5) : 0, 0);

                                        prog = global.player.slimeTimer > 0 ? 1 : (min(global.player.slimeTimer, 0) / -CHAOS_INVIS_RECHARGE);
                                        drawKeyIcon(spr_gui_chaosslime, 0, 18, global.KeyC, prog * 4, 250 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_EXETIOR:
                                        var _ef = !global.player.isGrounded;
                                        prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        drawKeyIcon(spr_gui_exetiorattack, _ef, 19, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, _ef ? 31 : 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = (1.0 - (global.player.bringTimer / EXETIOR_BRING_RECHARGE));
                                        drawKeyIcon(spr_gui_exetiorring, 0, 20, global.KeyC, prog * 4, 250 - _mob, prog == 1.0 && global.player.canSpawnRings ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_EXELLER:
                                        prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

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

                                        drawKeyIcon(spr, 0, spr == spr_gui_exellerclone ? 20 : 47, global.KeyC, prog * 4, 250 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                                        break;

                                case EXE_METALAMY:
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
                                        drawKeyIcon(spr_gui_metalamyattack, 0, 0, global.KeyB, _maprog * 10, 240 - _mob, _maprog == 1.0 ? c_white : c_red, _maprog, 0);

                                        prog = global.playerControls && global.player.isJumping;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, prog ? c_white : c_red, prog ? 1 : 0.5, 0);

                                        prog = 1.0 - (global.player.bulletTimer / METALAMY_BULLET_RECHARGE);
                                        drawKeyIcon(spr_gui_metal_amy_lazer, 0, 24, global.KeyC, prog * 4, 250 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

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
                                                drawKeyIcon(spr_gui_metalamy_indy, 0, 14, global.KeyV, 44 + _sprog * 10, 250 - _mob, _sready ? c_yellow : c_red, _sready ? 1 : _sprog, 0);
                                        }
                                        else
                                        {
                                                _sprog = 1.0 - (global.player.scanRecharge / METALAMY_SCAN_RECHARGE);
                                                _sready = _sprog >= 1.0 || _sact;
                                                drawKeyIcon(spr_gui_metalamy_indy, 0, 14, global.KeyV, 44 + _sprog * 10, 250 - _mob, _sready ? c_white : c_red, _sready ? 1 : _sprog, 0);
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
                                        drawKeyIcon(spr_gui_exeattack, 0, 19, global.KeyB, _jprog * 10, 240 - _mob, _jprog == 1.0 ? c_white : c_red, _jprog, 0);

                                        // Z: salto libre de los killers
                                        _jprog = (global.player.hurttime <= 0 && global.player.shockedTimer <= 0) ? 1.0 : 0.0;
                                        drawKeyIcon(spr_gui_exefreejump, 0, 26, global.KeyA, 3, 218 - _mob, _jprog ? c_white : c_red, _jprog ? 1 : 0.5, 0);

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
                                                drawKeyIcon(spr_gui_jinatrap, 0, 25, global.KeyC, _jprog * 4, 250 - _mob, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        else
                                        {
                                                var _jt = global.player.jinnaTeleCd;
                                                _jprog = 1.0 - (_jt / JINNA_TELEPORT_RECHARGE);
                                                var _jteleAct = global.player.jinnaTeleWindup > 0;
                                                drawKeyIcon(spr_gui_jinateleport, 0, 25, global.KeyC, _jprog * 4, 250 - _mob, (_jprog >= 1.0 || _jteleAct) ? c_white : c_red, _jteleAct ? 1 : _jprog, 0);
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
                                                drawKeyIcon(spr_gui_jinatrap, 0, 32, global.KeyV, 44 + _jprog * 10, 250 - _mob, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        else
                                        {
                                                // MODO AGARRE (V sola): garra del mod
                                                _jprog = 1.0 - (global.player.jinnaGrabCd / JINNA_GRAB_RECHARGE);
                                                drawKeyIcon(spr_gui_jinagrub, 0, 26, global.KeyV, 44 + _jprog * 10, 250 - _mob, _jprog >= 1.0 ? c_white : c_red, _jprog, 0);
                                        }
                                        break;
                                }
                        }

                        break;
                }

                case CHARACTER_TAILS: //tails
                {
                        var prog = (min(global.player.flyTimer, 0) / -420.0);
                        drawKeyIcon(spr_gui_tailsfly, global.player.revivalTimes >= 2, 26, global.KeyA, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        // v4.3: la X horneada y el texto (hold) de este sprite se recortan
                        // (el misil ocupa las filas 0-10) y el texto se redibuja dinamico.
                        var val = global.player.revivalTimes >= 2 ? ETAILS_ATTACK_RECHARGE : TAILS_ATTACK_RECHARGE;
                        prog = 1.0 - (global.player.attackTimer / val);
                        var _tcol = prog == 1.0 ? c_white : c_red;
                        draw_sprite_part_ext(spr_gui_tailsattack, 0, 0, 0, 25, 11, prog * 12, 250 - _mob, 1, 1, _tcol, prog);

                        // v5.5: tecla y "(hold)" tambien en Android (mismo
                        // criterio que drawKeyIcon)
                        scr_text_spr(prog * 12 + 27, 250 - _mob + 2, scr_controls_keycode_to_key(global.KeyB), _tcol, prog);
                        scr_text_spr(prog * 12 + 3, 250 - _mob + 12, "(hold)", _tcol, prog);
                        break;
                }

                case CHARACTER_KNUX:
                {
                        var prog = 1.0 - (min(global.player.glideTimer, KNUX_GLIDE_RECHARGE) / KNUX_GLIDE_RECHARGE);
                        drawKeyIcon(spr_gui_knuxglide, global.player.revivalTimes >= 2, 23, global.KeyA, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        var val = global.player.revivalTimes >= 2 ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        prog = 1.0 - (min(global.player.attackTimer, val) / val);
                        drawKeyIcon(spr_gui_knuxattack, 0, 19, global.KeyB, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                // v4.4 — ROUGE: mismos dos iconos que Knuckles (planeo
                // Z + patada X), con sus sprites propios del TTB
                // (spr_gui_rougeglide / spr_gui_rougeattack). La
                // patada NO tiene version exe (jamais se demoniza):
                // su recarga es siempre la de superviviente.
                case CHARACTER_ROUGE:
                {
                        var prog = 1.0 - (min(global.player.glideTimer, ROUGE_GLIDE_RECHARGE) / ROUGE_GLIDE_RECHARGE);
                        drawKeyIcon(spr_gui_rougeglide, 0, 23, global.KeyA, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (min(global.player.attackTimer, ROUGE_ATTACK_RECHARGE) / ROUGE_ATTACK_RECHARGE);
                        drawKeyIcon(spr_gui_rougeattack, 0, 19, global.KeyB, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_EGGMAN:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / EGGMAN_DJUMP_RECHARGE);
                        drawKeyIcon(spr_gui_eggdjump, 0, 20, global.KeyA, prog * 10, 222 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / EGGMAN_SHIELD_RECHARGE);
                        drawKeyIcon(spr_gui_eggshield, 0, 20, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.trackerRecharge, 0) / EGGMAN_TRACKER_RECHARGE);
                        drawKeyIcon(spr_gui_eggtrack, 0, 38, global.KeyC, prog * 10, 258 - _mob, (global.player.isColliding && prog == 1.0) ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_AMY:
                {
                        var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_BIGJUMP_RECHARGE);
                        drawKeyIcon(spr_gui_amyhjump, 0, 32, global.KeyA, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        var val = global.player.revivalTimes >= 2 ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_AMY_CANON:
                {
                                // Icono 1: SALTO DE MARTILLO (tecla Z, en el suelo). El relleno
                                // muestra el CD; blanco = listo Y en el suelo (espejo del icono 3).
                                var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_CANON_BIGJUMP_RECHARGE);
                                var b1 = (prog == 1.0 && global.player.isGrounded) ? c_white : c_red;
                                drawKeyIcon(spr_gui_amyhjump_canon, 0, 32, global.KeyA, prog * 10, 222 - _mob, b1, prog, 0);

                                // Icono 2: IMPULSO AEREO DE TAROT (tecla X, SOLO en el aire).
                                // El relleno muestra el CD; blanco = lista Y en el aire
                                // (espejo del icono 3, que exige estar en el suelo).
                                var val = global.player.revivalTimes >= 2 ? AMY_CANON_ETAROTDASH_RECHARGE : AMY_CANON_TAROTDASH_RECHARGE;
                                prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                                var b2 = (prog == 1.0 && !global.player.isGrounded) ? c_white : c_red;
                                drawKeyIcon(spr_gui_amyattack_canon, 0, 23, global.KeyB, prog * 10, 240 - _mob, b2, prog, 0);

                        // Icono 3: ACOMETIDA DE MARTILLO (tecla C). v4.3: la C ya no esta
                        // horneada: se dibuja la tecla real de special2.
                        val = global.player.revivalTimes >= 2 ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;
                        prog = 1.0 - (max(global.player.dashTimer, 0) / val);
                        var b = (prog == 1.0 && global.player.isGrounded) ? c_white : c_red;
                        drawKeyIcon(spr_gui_amydash_canon, 0, 23, global.KeyC, prog * 10, 258 - _mob, b, prog, 0);

                        // Icono 4: PARRY (tecla V, v4.0). Mismas fijaciones que el de
                        // Sonic (estados 60/61/64). El relleno muestra el CD que falta:
                        // como el CD depende de COMO termino el ultimo intento
                        // (fallo/exito), se guarda la duracion total en
                        // parryCooldownMax al aplicarlo y asi el icono siempre arranca
                        // lleno. Blanco = listo Y en el suelo (el parry es solo en
                        // tierra); rojo = lo demas. Si spr_gui_amyparry_canon no
                        // existiera en el proyecto, no se dibuja pero tampoco crashea
                        // (mismo patron que el parry de Sonic y el spindash).
                                                // v4.1: se dibuja AL LADO del icono de la acometida (misma fila
                        // que la C, a su derecha) y no DEBAJO: la vista mide 480x270 y una
                        // cuarta fila apilada (y=276) caia FUERA de pantalla (por eso no
                        // salia). C y V comparten fila, como Z X C V en el teclado; en
                        // Android (y-200) tampoco choca con el boton G (23,81).
                        var _sprParry = asset_get_index("spr_gui_amyparry_canon");
                        if(_sprParry >= 0)
                        {
                                var _pmax = max(global.player.parryCooldownMax, 1);
                                var _pprog = 1.0 - (max(global.player.parryCooldown, 0) / _pmax);
                                var _pready = (_pprog >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                                drawKeyIcon(_sprParry, 0, 19, global.KeyV, 44 + _pprog * 10, 258 - _mob, _pready, _pprog, 0);
                        }
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
                        var _djProg = _djReady ? 1.0 : (global.player.djTimer < 0 ? 0.0 : 1.0 - (global.player.djTimer / (global.player.revivalTimes >= 2 ? FW_EDJ_RECHARGE : FW_DJ_RECHARGE)));
                        var b1 = (_djReady && !global.player.isGrounded) ? c_white : c_red;
                        drawKeyIcon(spr_gui_amydj_fw, 0, 32, global.KeyA, _djProg * 10, 222 - _mob, b1, _djProg, 0);

                        // Icono 2 (tecla B): PUÑO/PATADA. El relleno muestra el CD.
                        var val2 = global.player.revivalTimes >= 2 ? FW_EATTACK_RECHARGE : FW_ATTACK_RECHARGE;
                        var prog2 = 1.0 - (max(global.player.attackTimer, 0) / val2);
                        drawKeyIcon(spr_gui_amyattack_fw, 0, 23, global.KeyB, prog2 * 10, 240 - _mob, prog2 == 1.0 ? c_white : c_red, prog2, 0);

                        // Icono 3 (tecla C): BALLESTA — v2.15 («La Torre»): cargador
                        // de 3 flechas (recarga 8 s por flecha, 0,5 s entre disparos).
                        // El relleno muestra el cargador entero (flechas + fraccion de
                        // la que esta recargando); los pips debajo cuentan las listas.
                        // Blanco = hay flecha Y paso el CD de disparo; rojo = lo demas.
                        // Mientras dura cbTimer la lleva en la mano (sprites cbamy).
                        // v4.3 (fix exe): demonizada (revivalTimes >= 2) NO puede usar
                        // la ballesta — icono en rojo con el cargador vacio de llenado.
                        var _arrows = global.player.fwArrows;
                        var _prog3 = global.player.revivalTimes >= 2 ? 0 : min(1.0, (_arrows + (_arrows < FW_ARROW_MAX ? 1.0 - max(global.player.fwArrowReload, 0) / FW_ARROW_RELOAD : 0)) / FW_ARROW_MAX);
                        var b3 = (global.player.revivalTimes < 2 && _arrows > 0 && global.player.crossBow <= 0) ? c_white : c_red;
                        drawKeyIcon(spr_gui_amycrossbow_fw, 0, 23, global.KeyC, _prog3 * 10, 258 - _mob, b3, _prog3, 0);

                        // Pips de municion: un rectangulo por flecha disponible
                        draw_set_color(b3);
                        draw_set_alpha(0.9);
                        for(var _pi = 0; _pi < FW_ARROW_MAX; _pi++)
                                draw_rectangle(2 + _pi * 7, 258 - _mob + 12, 7 + _pi * 7, 261 - _mob + 12, _pi >= _arrows);
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
                                drawKeyIcon(_sprParry, 0, 19, global.KeyC, _pprog * 10, 222 - _mob, _pready, _pprog, 0);
                        }

                        // Icono (tecla X): EL GOLPE. Reutiliza el icono generico del
                        // ataque de Amy; cuando crees spr_gui_sonicattack, cambialo aqui.
                        var val = global.player.revivalTimes >= 2 ? SONIC_EATTACK_RECHARGE : SONIC_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

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
                                        drawKeyIcon(_sprSpindash, 0, 33, global.KeyA, charge * 10, 258 - _mob, charge >= 1.0 ? c_white : c_red, 0.4 + charge * 0.6, 0);
                                }
                                else
                                        drawKeyIcon(_sprSpindash, 0, 33, global.KeyA, 10, 258 - _mob, c_white, 1, 0);
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
                                        drawKeyIcon(_sprDropdash, 0, 34, global.KeyA, 54, 258 - _mob, c_white, 1, 0);
                                else
                                {
                                        var _ddprog = min(global.player.dropDashTimer / SONIC_DROPDASH_HOLD, 1.0);
                                        var _ddcol = (global.player.dropDashFromJump && !global.player.isGrounded) ? c_white : c_red;
                                        drawKeyIcon(_sprDropdash, 0, 34, global.KeyA, 44 + _ddprog * 10, 258 - _mob, _ddcol, 0.4 + _ddprog * 0.6, 0);
                                }
                        }
                        break;
                }
                case CHARACTER_CREAM:
                {
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        drawKeyIcon(spr_gui_creamfly, global.player.revivalTimes >= 2, 25, global.KeyA, prog * 10, 222 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.ringsTimer, 0) / (global.player.revivalTimes >= 2 ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        drawKeyIcon(spr_gui_creamrings, global.player.revivalTimes >= 2, 21, global.KeyC, prog * 10, 257 - _mob, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_VANILLA:
                {
                        // VANILLA: mismas habilidades que Cream (scr_cream_special),
                        // reusa sus iconos del HUD (vuelo Z, dash X, anillos C)
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        drawKeyIcon(spr_gui_creamfly, global.player.revivalTimes >= 2, 25, global.KeyA, prog * 10, 222 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.ringsTimer, 0) / (global.player.revivalTimes >= 2 ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        drawKeyIcon(spr_gui_creamrings, global.player.revivalTimes >= 2, 21, global.KeyC, prog * 10, 257 - _mob, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog, 0);
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
                        var prog = 1.0 - (max(global.player.dashTimer, 0) / (global.player.revivalTimes >= 2 ? EMETAL_OVERDRIVE_RECHARGE : METAL_OVERDRIVE_RECHARGE));
                        drawKeyIcon(spr_gui_creamdash, 0, 21, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.electroTimer, 0) / (global.player.revivalTimes >= 2 ? EMETAL_ELECTRO_RECHARGE : METAL_ELECTRO_RECHARGE));
                        drawKeyIcon(spr_gui_eggshield, 0, 20, global.KeyC, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
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
                                        drawKeyIcon(_sprSpin, 0, 33, global.KeyA, _charge * 10, 222 - _mob, _charge >= 1.0 ? c_white : c_red, 0.4 + _charge * 0.6, 0);
                                }
                                else
                                        drawKeyIcon(_sprSpin, 0, 33, global.KeyA, 10, 222 - _mob, c_white, 1, 0);
                        }

                        // Icono (tecla X): TRAMPOLIN — el resorte
                        // (spr_gui_sonicspring; estaba en disco desde la
                        // extraccion del mod de Sonic y v2.7 lo registra
                        // en el .yyp, hasta ahora jamas se uso).
                        var prog = 1.0 - (max(global.player.bananaTimer, 0) / (global.player.revivalTimes >= 2 ? EAMELIA_BANANA_RECHARGE : AMELIA_BANANA_RECHARGE));
                        drawKeyIcon(spr_gui_sonicspring, 0, 33, global.KeyB, prog * 10, 240 - _mob, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog, 0);

                        // Icono (tecla C): TRAMPA — la trampa-oso que
                        // siempre fue suya (antes estaba en el slot X).
                        // v4.3c: artW 25 (antes 39). El sprite trae
                        // "[trampa] - ↓ + C" horneado (arte 0-18, guion
                        // 20-24, flecha 26-33, + 35-38, C 40-47), pero la
                        // trampa NO exige abajo: solo C + estar en el suelo
                        // (scr_amelia_special). Se corta en el guion y la
                        // tecla dinamica queda justo despues: "[trampa]-C".
                        prog = 1.0 - (max(global.player.trapTimer, 0) / (global.player.revivalTimes >= 2 ? EAMELIA_TRAP_RECHARGE : AMELIA_TRAP_RECHARGE));
                        drawKeyIcon(spr_gui_amelia_trap, 0, 39, global.KeyC, prog * 10, 258 - _mob, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog, 0);
                        break;
                }

                // ============================================================
                // v2.2 (TTB) — BLAZE: salto de fuego (Z), bola (X) y ardiente (C)
                case CHARACTER_BLAZE:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_DJUMP_RECHARGE : BLAZE_DJUMP_RECHARGE));
                        drawKeyIcon(spr_gui_eggdjump, 0, 20, global.KeyA, prog * 10, 222 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.fireballTimer, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_FIREBALL_RECHARGE : BLAZE_FIREBALL_RECHARGE));
                        drawKeyIcon(spr_gui_amyattack, 0, 23, global.KeyB, prog * 10, 240 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);

                        prog = 1.0 - (max(global.player.burningTimer, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_BURNING_RECHARGE : BLAZE_BURNING_RECHARGE));
                        drawKeyIcon(spr_gui_sallyshield, 0, 19, global.KeyC, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }

                case CHARACTER_SALLY:
                {
                        // v4.3: la patada aerea es KeyB (X) y el escudo KeyC (C);
                        // antes el comentario deca Z: el que manda es scr_sally_special.
                        var val = global.player.revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);

                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;

                        if(global.player.isGrounded)
                                b = c_red;

                        drawKeyIcon(spr_gui_sallyattack, global.player.revivalTimes >= 2, 17, global.KeyB, prog * 10, 240 - _mob, b, prog, 0);

                        val = global.player.revivalTimes >= 2 ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE;
                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        drawKeyIcon(spr_gui_sallyshield, global.player.revivalTimes >= 2, 19, global.KeyC, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }
                case CHARACTER_SALLY_CANON:
                {
                        // SALLY CANON: tiene las mismas habilidades que Sally
                        // (scr_sally_special), asi que usa sus mismos iconos del
                        // HUD: la PATADA (tecla X, ver scr_sally_special) y el
                        // ESCUDO (tecla C). El relleno de cada icono muestra el
                        // CD que le falta; blanco = listo. La patada es AEREA en
                        // fase 1 (roja en el suelo, como la de Sally); en fase
                        // DUELISTA tambien vale en tierra (blanca en el suelo).
                        var val = global.player.revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);

                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;

                        // v5.4: en fase duelista la patada en tierra existe:
                        // el icono va listo aun parado
                        if(global.player.isGrounded && !global.player.duelista)
                                b = c_red;

                        drawKeyIcon(spr_gui_sallyattack, global.player.revivalTimes >= 2, 17, global.KeyB, prog * 10, 240 - _mob, b, prog, 0);

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
                                                drawKeyIcon(_sprSpin, 0, 33, global.KeyA, _charge * 10, 222 - _mob, _charge >= 1.0 ? c_white : c_red, 0.4 + _charge * 0.6, 0);
                                        }
                                        else
                                                drawKeyIcon(_sprSpin, 0, 33, global.KeyA, 10, 222 - _mob, c_white, 1, 0);
                                }
                        }

                        // v5.4: recarga propia del escudo canon (28 s, 2 menos
                        // que la vanilla) — la barra del icono usa SU macro.
                        val = SALLY_CANON_SHIELD_RECHARGE;
                        prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        drawKeyIcon(spr_gui_sallyshield, global.player.revivalTimes >= 2, 19, global.KeyC, prog * 10, 258 - _mob, prog == 1.0 ? c_white : c_red, prog, 0);
                        break;
                }
        }

        // v7 (toque negativo) — CARGA NEGATIVA DE JINNA (visible SOLO para
        // la victima, patron de la marca de debilidad de Metal Amy): una
        // barrita morada bajo el HUD de vida que se llena con cada golpe de
        // Jina (agarre/trampa +25, golpe X +15). A 100 llega la conversion
        // instantanea a súbdito negativo (el "negatimer" de Negagen). En
        // gracia (jinnaNegaGrace, su Antinegatemper) parpadea tenue.
        if(global.character != CHARACTER_EXE && global.player.revivalTimes < 2
        && variable_instance_exists(global.player.id, "jinnaNegaCharge")
        && global.player.jinnaNegaCharge > 0 && !global.player.isDead)
        {
                var _negaPct = global.player.jinnaNegaCharge / JINNA_NEGA_MAX;
                var _negaX = 60;
                var _negaY = 178 - _mob;
                var _negaCol = make_color_rgb(120, 40, 160); // energía negativa: violeta
                var _negaAlpha = (variable_instance_exists(global.player.id, "jinnaNegaGrace") && global.player.jinnaNegaGrace > 0) ? 0.45 + 0.3 * sin(current_time / 90) : 0.9;

                draw_set_alpha(_negaAlpha);
                draw_set_color(c_black);
                draw_rectangle(_negaX - 1, _negaY - 1, _negaX + 102, _negaY + 5, false);
                draw_set_color(_negaCol);
                draw_rectangle(_negaX, _negaY, _negaX + 100 * _negaPct, _negaY + 4, false);
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
