function scr_rouge_special()
{
        // =====================================================================
        //  ROUGE (v13 — REWORK DE LA DUEÑA) — kit nuevo:
        //
        //  v32 — HABILIDAD V: CAMBIO DE MODALIDAD (la mas poderosa de
        //   todas). V cicla EN ORDEN el set de X y C entre 4 sets:
        //    * ROUGE  : X = taladro (aire) / tornado (tierra) de siempre,
        //               C = INVISIBILIDAD patron sonic.exe (siluetas
        //               rojas spr_rouge_invis_*, 675 f = un 25% MENOS que
        //               el exe, recarga igual de 14 s; JAMAS rastreada:
        //               exe/exeller/exetior/scan de Metal Amy la saltan
        //               aunque lleve el anillo rojo).
        //    * EGGMAN : X = ESCUDO ELECTRICO (1,5 s, stun de 2 s con
        //               chispazo, patron del doctor), C = MINA (el sensor
        //               CLIENT_ETRACKER tal cual, 25 s).
        //    * SUPPORT: X = ESCUDO DE SALLY (5 s de burbuja, absorbe un
        //               golpe), C = ANILLOS DE VANILLA (canal de 1 s con
        //               la pose "emotico3" spr_rouge_emotion3 y el mismo
        //               CLIENT_CREAM_SPAWN_RINGS; valen 4 al recogerlos).
        //    * ATTACK : X = PATADA DE SALLY (anim nueva spr_rouge_attack3,
        //               hitbox +65% del ancho del bbox, I-FRAMES toda la
        //               patada, recarga de Sally 15 s). C sin asignar por
        //               ahora (unicamente Sally en este set).
        //   Y la siguiente V vuelve al set ROUGE. El ciclo es 100% local:
        //   cada habilidad viaja por SU camino de siempre (bitflags y
        //   paquetes ya existentes) con SUS validaciones de siempre.
        //   Capacidad NATA (todos los modos): MEJORAR TRAMPAS — el Genio
        //   de Eggman porteado: ABAJO sobre una trampa de Amelia (5
        //   anillos) o un sensor (3) con anillos la DORA (+25%).
        //
        //   * Z en el aire = VUELO patron VANILLA (antes Tails): MANTENER
        //     Z = SUBE (ROUGE_FLY_RISE -3.5); SOLTAR Z = baja lento
        //     (ROUGE_FLY_GLIDE +1) — subir y bajar. Dura ROUGE_FLY_SOLO
        //     (5 s, contador flyTimeout) y recarga en suelo
        //     ROUGE_FLY_RECHARGE (15 s, puerta flyTimer). Sprite del estado
        //     ROUGE_GLIDE (16): spr_rouge_fly. El dano, el suelo y el
        //     tornado cortan el vuelo (como a Vanilla).
        //   * ABAJO + Z en tierra = SPINDASH (reglas de SONIC): cada
        //     pulsacion de Z suma ROUGE_SPINDASH_REV (2) de carga (hasta
        //     ROUGE_SPINDASH_CHARGE_MAX = 10) y el tono del snd_spin sube
        //     con la carga; cargando esta QUIETA (gspd/xspd = 0, puede
        //     girar la mirada) y la carga decae 1 punto cada
        //     ROUGE_SPINDASH_DECAY (90) frames sin pulsar. Al SOLTAR
        //     abajo: sale DISPARADA — gspd = (ROUGE_SPINDASH_BASE + carga)
        //     * xscale — en bola (SPIN) mostrando spr_rouge_spin_release
        //     (spinDashRelease), con polvareda de salida y mini-temblor.
        //     Cargando muestra spr_rouge_spin_charger (estado 20).
        //     Cancelan: dano, stun, muerte, tirolina, saltar fuera del
        //     suelo, volar.
        //   * X EN TIERRA = TORNADO (spr_rouge_attack2, estado 15): sale
        //     a ROUGE_TORNADO_START (12 px/f) y va PERDIENDO velocidad
        //     hasta ROUGE_TORNADO_MIN (1.5) al final del recorrido
        //     (ROUGE_TORNADO_TIME, 0.8 s). I-FRAMES durante TODO el
        //     movimiento (scr_player_hurt: tornadoState > 0 = inmune,
        //     patron tornado de Knuckles). El stun al bando EXE por
        //     contacto lo aplica el cliente de la victima (bit
        //     PLAYER_ATTACKING que viaja con Rouge). Recarga 20 s al
        //     terminar.
        //
        //  v14 — 2 MODALIDADES DEL ATAQUE (X): spr_rouge_attack1 en el
        //     AIRE (la patada, estado 14) y spr_rouge_attack2 en TIERRA
        //     (el tornado, estado 15). Si se usa EN EL AIRE y le queda
        //     tiempo (la patada sigue activa) cuando TOCA SUELO, el
        //     ataque CAMBIA de modo aereo a modo terrestre: arranca el
        //     tornado con sus i-frames y su recorrido (misma recarga).
        //  v24 — EL ATAQUE AEREO ES UN TALADRO (rework): impulso hacia
        //     ABAJO (ROUGE_DRILL_DIVE), residuos FANTASMA (effectTime) y su
        //     contacto ROMPE los i-frames de la victima (patron Sally
        //     Canon, aplicado en obj_player_puppet). Si ATERRIZA con carga
        //     restante arranca el tornado (attack2) con duracion COMPLETA
        //     — como si la habilidad de tierra se hubiera activado (2
        //     habilidades en 1). El tornado tambien deja fantasmas. Una
        //     SOLA recarga: se paga cuando termina la cadena.
        //  v27 — TRAMPOLIN + TORNADO AEREO + ANIMS DEBILITADA:
        //     (1) el taladro ya NO borra el impulso de un trampolin: si la
        //     lanzan hacia arriba se corta limpio sin recarga (antes:
        //     rebote-slam infinito "empujando hacia abajo a perpetuidad");
        //     (2) el remolino corta limpio (sin recarga) si sale del suelo
        //     (trampolin/rampa/borde): antes quedaba como tornado FANTASMA
        //     ("la animacion muere pero el ataque sigue empujando");
        //     (3) scr_survivors: la tabla de anims de Rouge DEBILITADA
        //     (revivalTimes >= 2) tenia attack1/attack2 INVERTIDOS: el
        //     tornado pintaba la patada — por eso spr_rouge_attack2 "no
        //     aparecia nunca" en tus ultimas pruebas.
        //  v26 — FIX DEL TORNADO DE 1 FRAME: al aterrizar el taladro
        //     PEGADO a un muro (o pulsar X al lado de uno), el corte de
        //     pared lo mataba en el primer frame ("milisegundos" de attack2
        //     y a correr). Ahora el corte exige que el remolino haya VIAJADO
        //     desde su origen (tornadoStartX): nacido pegado a la pared gira
        //     en el sitio toda la duracion; la pared en plena carrera sigue
        //     cortandolo igual (patron Metal intacto).
        //  v25 — TALADRO DIAGONAL e ILIMITADO en el aire: el impulso
        //     ahora cae EN DIAGONAL hacia donde mira (ROUGE_DRILL_DIVE_X)
        //     y en el aire NO expira: taladra hasta aterrizar o que lo
        //     corten. El TORNADO de tierra dura 3 s (antes 0.8) con el
        //     mismo frenado de arranque y su animacion en loop TODO ese
        //     tiempo. El GLIDE gira un 17% mas rapido que el de Knux
        //     (ROUGE_GLIDE_ACC 3: la velocidad extra ya no se siente
        //     pesada al invertir la direccion). Y RADAR: flecha verde a
        //     la salida cuando existe el anillo (Draw_64, patron Amy
        //     Canon, solo local).
        //  v24 — GLIDE MEJORADA: cae un 35% MAS LENTO que la de Knuckles
        //     (ROUGE_GLIDE_FALL 0.65 vs su 1) y planea un 25% MAS RAPIDA
        //     (ROUGE_GLIDE_SPD 6.25 vs su 5). El agarre de pared le da
        //     2 s de I-FRAMES por cada toque (scr_collision_basic). El
        //     VUELO activo pasa a Z + ARRIBA (asi una Z suelta al caer
        //     no lo gasta: cae derecha al planeo).
        //  v14 — SLIDE DE SALLY: ABAJO mientras corre = slide (no el
        //     rodar clasico; canSpin = false en el Create). Patron
        //     exacto de Sally (scr_sally_special): |xspd| >= 2.5 +
        //     Down recien pulsada; slideSpeed = xspd + 2 y decae sola.
        //     spr_rouge_slide (estado 22).
        //  v14 — GLIDE PASIVA (tipo Knuckles): MANTENER Z al empezar a
        //     DESCENDER = planeo con la tira direccional
        //     spr_rouge_glide (estado 23; frame = direccion del
        //     glide_xspd). PASIVA de verdad: SIN recarga y NO esta atada
        //     al efecto del anillo rojo (el planeo funciona igual con
        //     redRingTimer > 0). Pared = agarre (spr_rouge_stuck,
        //     estado 18) via scr_collision_basic (glideTimer = 1 la
        //     mantiene abierta). El vuelo activo (Z pulsacion fresca)
        //     sigue siendo una habilidad con recarga: conviven.
        //
        //  v14 — PASIVA «CAZADORA DE TESOROS»: 50% (ROUGE_TREASURE_CHANCE)
        //     de que un anillo NORMAL cuente por 2 (net_state_game,
        //     SERVER_RING_COLLECTED). NO aplica a los anillos GENERADOS
        //     por Cream/Vanilla/Amy Canon (los del _state 2 de
        //     SERVER_RING_STATE: quedan apuntados en genRingNids).
        //
        //  v4.5 — MORIBUNDA: su salvacion de 1ra caida sigue IGUAL
        //  (tirada 6 s inmune, se levanta con 40; la activa
        //  scr_player_instakill desde scr_player_hurt).
        // =====================================================================

        // ---------------- MORIBUNDA (1ra caida) ----------------
        if(moribundaState > 0)
        {
                gspd = 0;
                xspd = 0;

                // mismo mini-fix de Vanilla: debilitada EN EL AIRE cae al suelo
                // en vez de quedarse flotando; la levitacion queda SOLO para el
                // hoyo de verdad (sin terreno en la columna de abajo)
                if(isGrounded)
                        yspd = 0;
                else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
                        yspd = ROUGE_MORIBUNDA_LEVITATE;
                else
                        yspd = min(yspd + yAccel, maxYSpeed);

                isJumping = false;
                isSpinning = false;
                isAttacking = false;
                isGliding = false;
                isFlying = false; // moribunda no vuela

                // v14: el slide tambien se corta
                isSliding = false;

                // v13: el tornado y la carga del spindash tambien se cortan
                tornadoState = 0;
                isSpinCharging = false;
                spinCharge = 0;

                if(isStuck)
                {
                        canMove = true;
                        isStuck = false;
                }

                moribundaTimer--;

                if(moribundaTimer <= 0)
                {
                        moribundaState = 0;
                        hp = ROUGE_MORIBUNDA_HEAL;
                        hurttime = ROUGE_MORIBUNDA_INVULN;
                        isHurt = false;
                        flyTimer = 0;   // misericordia: vuelo listo al levantarse
                        flyTimeout = 0;
                        attackTimer = 0; // ...y el tornado tambien
                }

                return;
        }

        // anillo rojo / esconderse: sin especiales y SIN recargar el vuelo
        // (patron Vanilla: el flyTimer se mantiene a un pelo del 0 para que
        // no llegue a "recargado" y no pueda despegar)
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;

                if(flyTimer < 2)
                        flyTimer = 2;
        }

        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;

                if(flyTimer < 60 * 2)
                        flyTimer = 60 * 2;
        }

        // =================================================================
        //  v32 — HABILIDAD V: CAMBIO DE MODALIDAD (la mas poderosa).
        //  Cicla EN ORDEN el set de X y C: ROUGE -> EGGMAN -> SUPPORT
        //  (Sally + Vanilla) -> ATTACK (por ahora unicamente Sally) -> y
        //  de vuelta a ROUGE. El ciclo es 100% LOCAL (cero paquetes):
        //  cada habilidad viaja despues por SU camino de siempre con
        //  SUS validaciones de siempre (server incluido). No se puede
        //  ciclar en mitad de una habilidad (isAttacking / canal).
        // =================================================================
        if(global.playerControls && keyboard_check_pressed(global.KeyV)
        && !isDead && shockedTimer <= 0 && !isHurt && !isAttacking
        && ringsChannel <= 0 && !isSpinCharging)
        {
                // cambiar de modalidad APAGA la invisibilidad (la
                // invisibilidad es la C de su set normal: sin set
                // normal no hay con que esconderse)
                if(invisTimer > 0)
                        invisTimer = 0;

                rougeMode = (rougeMode + 1) mod ROUGE_MODE_COUNT;
                modeFlash = 60 * 2;

                // feedback local: el ciclo no viaja por red
                audio_play_sound(snd_buble, 0, false);
        }

        // =================================================================
        //  v32 — INVISIBILIDAD (C en modo ROUGE, patron sonic.exe
        //  original): contorno rojo local (siluetas spr_rouge_invis_*)
        //  y PARA LOS DEMAS... nada: el bit PLAYER_INVIS esconde su
        //  puppet en TODOS los clientes (igual que el exe) y las
        //  agujas de rastreo JAMAS la senalan (exe/exeller/exetior/
        //  metal amy: la saltan aunque lleve el anillo rojo). Dura un
        //  25% MENOS que la del exe (675 vs 900) con su MISMA recarga
        //  (14 s tras apagarse, corte manual incluido). Los sonidos
        //  son SOLO locales: ningun emit delata donde esta.
        // =================================================================
        if(rougeMode == ROUGE_MODE_ROUGE
        && global.playerControls && keyboard_check_pressed(global.KeyC)
        && revivalTimes < 2 && !isDead && shockedTimer <= 0 && !isHurt
        && redRingTimer <= 0 && ringsChannel <= 0
        && !(variable_instance_exists(id, "isNegatouch") && isNegatouch))
        {
                if(invisTimer <= ROUGE_INVIS_RECHARGE)
                {
                        // ACTIVAR — v36 (duena): SU voz propia al
                        // desaparecer ("too bad", de los mp3 nuevos),
                        // fuera los sonidos del exe. Sigilo de
                        // superviviente: solo local, sin emit.
                        var _play = true;

                        for(var _isnd = 46; _isnd < array_length(global.net_snds); _isnd++)
                        {
                                if(audio_is_playing(global.net_snds[_isnd]))
                                {
                                        _play = false;
                                        break;
                                }
                        }

                        if(_play)
                                audio_play_sound(snd_rouge_toobad, 0, false);

                        invisTimer = ROUGE_INVIS_DURATION;
                }
                else if(invisTimer > 0)
                {
                        // corte manual temprano (como el exe): los
                        // sonidos de APARICION los pone el bloque de
                        // abajo al ver invisTimer == 0
                        invisTimer = 0;
                }
        }

        // v36 (duena): APARICION — al terminarse la invisibilidad (o al
        // cortarla con C) suenan las 2 ULTIMAS voces ("warp surprised" +
        // "i make my own luck") SUMADAS al sonido de aparicion normal
        // del exe. Viajan por red (net_sound_emit, patron del exe): la
        // aparicion es un evento publico — se ve y se oye en todas las
        // pantallas. Muerta no suena (la muerte la apaga mas arriba).
        if(invisTimer == 0 && !isDead)
        {
                var _play = true;

                for(var _isnd = 46; _isnd < array_length(global.net_snds); _isnd++)
                {
                        if(audio_is_playing(global.net_snds[_isnd]))
                        {
                                _play = false;
                                break;
                        }
                }

                audio_play_sound(snd_exe_appear, 0, false);
                net_sound_emit(snd_exe_appear);

                if(_play)
                {
                        audio_play_sound(snd_rouge_warp, 0, false);
                        net_sound_emit(snd_rouge_warp);

                        audio_play_sound(snd_rouge_luck, 0, false);
                        net_sound_emit(snd_rouge_luck);
                }
        }

        // decay de la invisibilidad (patron exe): cuenta hasta la
        // RECARGA negativa; el tramo negativo es el candado de
        // reactivacion. Muerta no se esconde (la muerte la apaga).
        if(isDead && invisTimer > 0)
                invisTimer = 0;

        if(invisTimer > ROUGE_INVIS_RECHARGE)
                invisTimer--;

        // ---------------- SPINDASH (abajo + Z en tierra) ----------------
        // Reglas de Sonic: un solo camino para la 1a pulsacion y las
        // siguientes; exige suelo, parada (|gspd| < 2), y el resto de los
        // guards clasicos. El vuelo/ataque/tornado/hurt/stun lo cancelan.
        // v23 (fix de las revolucadas): FUERA el "!isSpinCharging" de la
        // entrada — con el, solo la 1a pulsacion de Z entraba al bloque y
        // machacar Z no cargaba NADA (la bola se quedaba en 2 para siempre).
        // Sonic y Sally NO lo tienen: cada Z fresca (abajo mantenida) suma
        // ROUGE_SPINDASH_REV aunque ya este cargando. Ese es el sistema
        // clasico completo.
        // v35 (SEGURO pedida por la duena): el giro es del SET ROUGE —
        // con otro set puesto (eggman/soporte/ataque) abajo+Z no hace
        // NADA. Igual que ya hacia el tornado (guard de modo en 456) y
        // la invisibilidad (guard en 246): sin el seguro, el giro seguia
        // disparandose en los demas sets y se mezclaba con la habilidad
        // de la X del modo.
        if(rougeMode == ROUGE_MODE_ROUGE
        && global.playerControls && isGrounded && !isAttacking && !isHurt
        && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
        && redRingTimer <= 0 && !isFlying && !isSliding
        && keyboard_check(global.KeyDown) && abs(gspd) < ROUGE_SPINDASH_START_MAX
        && !isSpinning && ringsChannel <= 0 && keyboard_check_pressed(global.KeyA))
        {
                isSpinCharging = true;
                spinCharge = min(spinCharge + ROUGE_SPINDASH_REV, ROUGE_SPINDASH_CHARGE_MAX);
                spinChargeDecay = 0;
                spinDustTimer = 0;
                image_index = 0;

                // JUGO (patron Sonic): cada revolucada suena MAS AGUDA
                // (tono 1.0 -> 1.8 con la bola llena) y patea polvo detras.
                if(spinRevSnd != -1)
                        audio_stop_sound(spinRevSnd);
                spinRevSnd = audio_play_sound(snd_spin, 0, false);
                audio_sound_pitch(spinRevSnd, 1.0 + (spinCharge / ROUGE_SPINDASH_CHARGE_MAX) * ROUGE_SPINDASH_PITCH_STEP);
                net_sound_emit(snd_spin);

                net_quick_effect(x - image_xscale * 12, y + 16, spr_dust, false, -image_xscale, -image_xscale * 2, -1);
        }

        // v37: el bloque v36 que plantaba a Rouge durante el escudo
        // (gspd=xspd=0) SE RETIRA — era un parche a ciegas del sintoma.
        // La causa real del "dash" (la duena lo grabo en video): dos
        // bloques de la v24 pensados solo para tornado/taladro — el
        // cambio de modo que arrancaba el tornado fantasma al tocar
        // suelo, y el fallback aereo que empujaba xspd=2 — ambos ya
        // llevan sus gates abajo. El escudo queda como el del doctor:
        // anda y cae normal, CERO dash, movibilidad plena.

        if(isSpinCharging)
        {
                // Quieto mientras carga, pero puede girar la mirada (Sonic).
                gspd = 0;
                xspd = 0;

                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                // La carga decae sola si dejas de dar revolucadas.
                spinChargeDecay++;
                if(spinChargeDecay >= ROUGE_SPINDASH_DECAY)
                {
                        spinChargeDecay = 0;
                        spinCharge = max(0, spinCharge - 1);
                }

                // JUGO: polvo ambiente detras mientras carga.
                spinDustTimer++;

                if(spinDustTimer >= ROUGE_SPINDASH_DUST_EVERY)
                {
                        spinDustTimer = 0;
                        scr_effect_quick(x - image_xscale * (10 + irandom(4)), y + 14 + irandom(3), spr_dust, 0.4, false, -image_xscale, -0.5);
                }

                // Cancelaciones (Sonic): dano, stun, muerte, tirolina,
                // saltar fuera del suelo, o VOLAR (v13).
                if(isHurt || isDead || shockedTimer > 0 || isZipline || !isGrounded || isFlying)
                {
                        isSpinCharging = false;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);   // corte del motor al estrellarse
                }
                else if(!global.playerControls || !keyboard_check(global.KeyDown))
                {
                        // --- LANZAMIENTO del spindash ---
                        var _chg = spinCharge;   // carga ANTES de limpiarla: define la polvareda
                        isSpinCharging = false;
                        isSpinning = true;    // sale en bola (SPIN)
                        spinDashRelease = true; // ...mostrando spr_rouge_spin_release
                        isJumping = false;
                        gspd = (ROUGE_SPINDASH_BASE + _chg) * image_xscale;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);   // el snd_dash toma el relevo

                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);

                        // JUGO: polvareda de salida detras (3 nubes sin carga
                        // -> 8 con la bola llena), como Sonic.
                        var _burst = ROUGE_SPINDASH_BURST_MIN + floor(_chg / ROUGE_SPINDASH_CHARGE_MAX * (ROUGE_SPINDASH_BURST_MAX - ROUGE_SPINDASH_BURST_MIN));

                        for(var i = 0; i < _burst; i++)
                        {
                                var _dx = x - image_xscale * (6 + irandom(12));
                                var _dy = y + 12 + irandom(5);

                                net_quick_effect(_dx, _dy, spr_dust, false, -image_xscale, -image_xscale * (1 + irandom(2)), -irandom(1));
                        }

                        // JUGO: mini-temblor de camara proporcional a la carga.
                        if(_chg > 0)
                                scr_camera_shake(12, 1 + _chg * 0.15, 0.2);
                }
        }

        // la bola de lanzamiento solo dura mientras isSpinning siga viva
        // (el rodar normal o el dano la devuelven a la bola clasica).
        if(!isSpinning && spinDashRelease)
                spinDashRelease = false;

        // ---------------- VUELO patron VANILLA (Z + ARRIBA en el aire) ----------------
        // v24 (pedido de la duena): el vuelo ACTIVO ahora se activa con
        // Z + FLECHA DE ARRIBA. Antes bastaba una pulsacion fresca de Z en
        // el aire y se GASTABA el vuelo cuando lo que querias era PLANEAR
        // (mantener Z al caer): ahora una Z suelta (sin arriba) no consume
        // nada — caes y el planeo pasivo toma el relevo solo.
        // v4.9 (COYOTE): mismo guard que Vanilla/Tails — si acaba de dejar
        // el suelo dentro de la ventana de salto, el Z se lo lleva el salto
        // normal; el vuelo sale con la siguiente pulsacion.
        // v14: el GLIDE PASIVA de abajo (Z MANTENIDA al descender) es un
        // camino DISTINTO: no gasta ni mira flyTimer (recarga) y el anillo
        // rojo no la bloquea — conviven con el vuelo activo.
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && keyboard_check(global.KeyUp) && !isGrounded && !isAttacking && !isSpinCharging && !isGliding
        && !(variable_instance_exists(id, "coyoteTimer") && coyoteTimer > 0 && yspd >= 0))
        {
                if(!isFlying && flyTimer <= 0)
                {
                        audio_play_sound(snd_tails_fly, 0, false);
                        net_sound_emit(snd_tails_fly);

                        flyTimer = ROUGE_FLY_RECHARGE;  // la puerta se cierra 15 s
                        flyTimeout = 0;
                        isFlying = true;
                        isJumping = false;
                        isSpinning = false;
                        spinDashRelease = false;
                }
        }

        // ---------------- TORNADO (X en tierra) + TALADRO AEREO (X en aire) ----------------
        // v24 (REWORK del ataque aereo, pedido de la duena): el X en el
        // AIRE ya no es la patada de animacion — es un TALADRO: impulso
        // hacia ABAJO EN DIAGONAL (v25, ROUGE_DRILL_DIVE + _X) sin limite
        // de tiempo en el aire (v25), deja
        // RESIDUOS FANTASMA mientras taladra y su contacto ROMPE los
        // i-frames de la victima (patron de la patada duelista de Sally
        // Canon: lo aplica el cliente de la victima en obj_player_puppet).
        // Si ATERRIZA mientras le queda carga, el ataque CAMBIA de modo
        // aereo a TERRESTRE: arranca el TORNADO (spr_rouge_attack2) con su
        // duracion reiniciada al MAXIMO — como si la habilidad de tierra
        // se hubiera activado (2 habilidades en 1). El tornado tambien
        // deja residuos fantasma. Una SOLA recarga compartida: arranca
        // cuando la cadena termina (taladro agotado en el aire o tornado
        // terminado), no al activar.
        // v23 (fix del sprite): dos arreglos para que el ataque SI muestre
        // su tira (antes salia la BOLA del spindash en vez de
        // spr_rouge_attack2):
        //  1) !isSpinCharging en el guard (paridad con el golpe de Sonic):
        //     durante la carga el X no arranca nada (en Sonic tampoco).
        //  2) el ataque APAGA la bola al empezar (isSpinning = false +
        //     spinDashRelease = false, igual que el golpe de Sonic apaga
        //     isSpinning): si pegabas en plena RODADA del spindash, el
        //     Step_2 priorizaba el estado ROUGE_SPIN_RELEASE (21) sobre
        //     isAttacking y TODO el tornado se veia como bola rodando —
        //     nunca aparecia el remolino.
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && tornadoState <= 0 && !isSliding && !isSpinCharging && !isAttacking && rougeMode == ROUGE_MODE_ROUGE)
        {
                // v32: pegar APAGA la invisibilidad (cancela y sigue —
                // la aguja jamas la senala, pero atacar no es esconderse)
                if(invisTimer > 0)
                        invisTimer = 0;

                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;

                // pegar corta el planeo pasivo (patron Knuckles)
                if(isGliding)
                {
                        isGliding = false;

                        if(isStuck)
                        {
                                canMove = true;
                                isStuck = false;
                        }
                }

                // pegar manda sobre la bola (patron del golpe de Sonic)
                isSpinning = false;
                spinDashRelease = false;

                if(isGrounded)
                {
                        // --- TORNADO (modo terrestre) ---
                        tornadoState = ROUGE_TORNADO_TIME;
                        tornadoStartX = x; // v26: origen del remolino (ver corte de pared)
                        isAttacking = true;
                        isFlying = false; // pegar manda (corta el vuelo)
                        isJumping = false;

                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);

                        // polvareda de arranque del remolino
                        repeat(3)
                                net_quick_effect(x - image_xscale * (4 + irandom(8)), y + 12 + irandom(4), spr_dust, false, -image_xscale, -image_xscale, -irandom(1));
                }
                else
                {
                        // --- TALADRO AEREO (modo aereo, v24) ---
                        // La recarga NO se paga aqui: la paga el final de
                        // la cadena (el tornado al terminar, o el corte si
                        // el taladro cae interrumpido).
                        isAttacking = true;
                        isFlying = false; // pegar manda (corta el vuelo)
                        isJumping = false;
                        drillState = 1;  // v25: BANDERA — en el aire NO hay limite de tiempo

                        // v25 (pedido de la duena): impulso DIAGONAL hacia
                        // donde mira (antes picada vertical pura): el taladro
                        // cae furioso Y avanza sobre el objetivo
                        yspd = ROUGE_DRILL_DIVE;
                        xspd = image_xscale * ROUGE_DRILL_DIVE_X;
                        gspd = 0;

                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);
                }
        }

        // =================================================================
        //  v32 — X/C POR MODALIDAD (la V de arriba decide cual corre):
        //  EGGMAN  : X = ESCUDO ELECTRICO, C = MINA (sensor).
        //  SUPPORT : X = ESCUDO DE SALLY,  C = ANILLOS DE VANILLA.
        //  ATTACK  : X = PATADA DE SALLY (spr_rouge_attack3, hitbox
        //            +65%, i-frames). C sin asignar por ahora.
        //  Todos comparten los guards clasicos del kit (como el
        //  spindash: dano, stun, muerte, tirolina, escondite, anillo
        //  rojo y el canal de anillos cortan todo).
        // =================================================================

        // ---------------- PATADA (X, modo ATTACK — v32) ----------------
        // Patron de la patada de Sally: isAttacking + su recarga, con
        // la tira nueva spr_rouge_attack3 (estado ROUGE_KICK) e
        // I-FRAMES durante TODA la patada (kickState, scr_player_hurt).
        // La hitbox +65% la aplica el puppet en el cliente de la
        // victima (pad del ancho del bbox, patron Sally Canon/Jinna).
        // Vale en tierra Y en el aire (mantiene el impulso que lleve).
        if(rougeMode == ROUGE_MODE_ATTACK
        && global.playerControls && keyboard_check_pressed(global.KeyB)
        && kickRecharge <= 0 && !isSliding && !isSpinCharging && !isAttacking
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && !isHiding && redRingTimer <= 0 && ringsChannel <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;

                // pegar corta el planeo (patron del tornado)
                if(isGliding)
                {
                        isGliding = false;

                        if(isStuck)
                        {
                                canMove = true;
                                isStuck = false;
                        }
                }

                // pegar manda sobre la bola y el vuelo (patron tornado)
                isSpinning = false;
                spinDashRelease = false;
                isFlying = false;
                isJumping = false;

                isAttacking = true;
                kickState = ROUGE_KICK_TIME;
                // v34: recarga PROPIA (antes attackTimer: el tornado la
                // dejaba muerta 20 s y ella le robaba 15 s al tornado)
                kickRecharge = revivalTimes >= 2 ? ROUGE_KICK_RECHARGE / 2 : ROUGE_KICK_RECHARGE;

                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);

                repeat(2)
                        net_quick_effect(x - image_xscale * (4 + irandom(8)), y + 12 + irandom(4), spr_dust, false, -image_xscale, -image_xscale, -irandom(1));
        }

        // ---------------- ESCUDO ELECTRICO (X, modo EGGMAN — v32) ----------------
        // Patron del escudo de Eggman: 1,5 s de aura de contacto —
        // quien la toque come el STUN ELECTRICO de 2 s con chispazo y
        // sonido (lo aplica su puppet en el cliente de la victima, el
        // caso ROUGE_ESHIELD). Recarga total 15 s (7 debilitada), mis-
        // mos numeros que el EGGMAN_SHIELD_RECHARGE del doctor.
        if(rougeMode == ROUGE_MODE_EGGMAN
        && global.playerControls && keyboard_check_pressed(global.KeyB)
        && eShieldRecharge <= 0 && !isSliding && !isSpinCharging && !isAttacking
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && !isHiding && redRingTimer <= 0 && ringsChannel <= 0)
        {
                isAttacking = true;
                eShieldTimer = ROUGE_ESHIELD_TIME;
                eShieldRecharge = ROUGE_ESHIELD_TIME + (revivalTimes >= 2 ? ROUGE_ESHIELD_RECHARGE_E : ROUGE_ESHIELD_RECHARGE);

                audio_play_sound(snd_egg_shield, 0, false);
                net_sound_emit(snd_egg_shield);
        }

        // ---------------- ESCUDO DE SALLY (X, modo SUPPORT — v32) ----------------
        // Patron del escudo de Sally: burbuja de 5 s que ABSORBE un
        // golpe (scr_player_hurt) y viaja con PLAYER_SALLYSHIELD para
        // que los demas clientes le dibujen la burbuja en su puppet.
        // Recarga 30 s (15 debilitada), mismos numeros que Sally.
        if(rougeMode == ROUGE_MODE_SUPPORT
        && global.playerControls && keyboard_check_pressed(global.KeyB)
        && shieldRechrage <= 0 && !isSliding && !isSpinCharging && !isAttacking
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && !isHiding && redRingTimer <= 0 && ringsChannel <= 0)
        {
                shieldTimer = ROUGE_SHIELD_TIME;
                shieldRechrage = revivalTimes >= 2 ? ROUGE_SHIELD_RECHARGE_E : ROUGE_SHIELD_RECHARGE;

                audio_play_sound(snd_sally_shield, 0, false);
                net_sound_emit(snd_sally_shield);
        }

        // ---------------- MINA / SENSOR (C, modo EGGMAN — v32) ----------------
        // El rastreador de Eggman tal cual: ABAJO mirando + pie firme
        // cerca del borde del suelo -> CLIENT_ETRACKER y el server lo
        // spawnea como entidad eggtrack para TODOS (25 s de recarga,
        // EGGMAN_TRACKER_RECHARGE del doctor). Mejorable con la
        // capacidad nata de abajo (3 anillos).
        if(rougeMode == ROUGE_MODE_EGGMAN
        && global.playerControls && keyboard_check_pressed(global.KeyC)
        && trackerRecharge <= 0 && isLookingDown && isGrounded)
        {
                var _mxx = image_xscale > 0 ? 12 : -12;

                if(!place_meeting(x, y, obj_angleanuller) && position_meeting(x + _mxx, y + 18, obj_floor_parent))
                {
                        audio_play_sound(snd_egg_tracker, 0, false);
                        net_sound_emit(snd_egg_tracker);

                        var _mpk = cpacket_tcp(PacketType.CLIENT_ETRACKER);
                        buffer_write(_mpk, buffer_u16, x);
                        buffer_write(_mpk, buffer_u16, y + 18);
                        send_server_tcp(_mpk);

                        trackerRecharge = EGGMAN_TRACKER_RECHARGE;
                }
        }

        // ---------------- ANILLOS (C, modo SUPPORT — v32) ----------------
        // Patron Vanilla: canal quieto de 1 s con la POSE "emotico3"
        // (spr_rouge_emotion3, estado ROUGE_RINGS) y al terminar sale
        // el CLIENT_CREAM_SPAWN_RINGS de siempre (anillos que valen 4
        // al recogerlos, los spawnea y valida el server). Cortar el
        // canal a mitad PAGA la recarga entera (como Vanilla). Solo la
        // Rouge superviviente (la debilitada no invoca soporte).
        if(rougeMode == ROUGE_MODE_SUPPORT
        && global.playerControls && keyboard_check_pressed(global.KeyC)
        && ringsTimer <= 0 && isGrounded && revivalTimes < 2
        && !isAttacking && !isSpinCharging && !isSliding
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && !isHiding && redRingTimer <= 0)
        {
                // sitio despejado para la pareja de anillos (patron
                // Vanilla: contra el techo no sale nada)
                if(!collision_circle(x, y - 24, 24, obj_floor_parent, true, true))
                {
                        ringsChannel = ROUGE_RINGS_CHANNEL;
                        image_index = 0;
                }
        }

        // ---------------- taladro aereo activo (v24, v25 ILIMITADO) ---
        // En picada mientras dure drillState: garantiza la velocidad de
        // taladro (la gravedad sola no baja mas rapido que el impulso) y
        // va dejando RESIDUOS FANTASMA (effectTime: el local los dibuja
        // en Draw_0 y a los demas clientes les llega solo con el bitflag
        // PLAYER_EFFECT de obj_netclient/Step_2 — cero cambios de red).
        // v25 (pedido de la duena): EN EL AIRE NO TIENE LIMITE — ya NO
        // expira por tiempo: taladra hasta ATERRIZAR (el bloque del
        // cambio de modo de abajo le pasa el relevo al tornado con
        // duracion COMPLETA) o hasta que lo corten dano/stun/muerte
        // (pagando ahi la recarga).
        if(drillState > 0)
        {
                if(isDead || shockedTimer > 0 || isHurt)
                {
                        drillState = 0;
                        isAttacking = false;
                        attackTimer = ROUGE_ATTACK_RECHARGE;
                }
                else if(yspd < 0)
                {
                        // v27 (bug del trampolin de la duena): si algo la
                        // LANZA HACIA ARRIBA en mitad del taladro (un
                        // trampolin: scr_collision_objects le pone yspd
                        // negativo al aterrizar encima), el clamp de picada
                        // de abajo lo BORRABA al frame siguiente: la llevaba
                        // de vuelta al trampolin y otra vez y otra vez —
                        // rebote-slam INFINITO ("empuja hacia abajo a
                        // perpetuidad", ataque en tiempo infinito). Un
                        // taladro que SUBE ya no es un taladro: se corta
                        // LIMPIO, SIN recarga (lo corto el mapa, no la
                        // jugadora) y el impulso del trampolin se respeta
                        // tal cual.
                        drillState = 0;
                        isAttacking = false;
                }
                else
                {
                        if(yspd < ROUGE_DRILL_DIVE)
                                yspd = ROUGE_DRILL_DIVE;

                        // residuos fantasma del taladro
                        if(effectTime <= 0)
                                effectTime = 16;
                }
        }

        // ---------------- tornado activo ----------------
        if(tornadoState > 0)
        {
                // i-frames durante TODO el movimiento (scr_player_hurt);
                // solo lo cortan muerte o stun (el dano ya no entra) o la
                // pared con su polvareda + mini-temblor (patron overdrive
                // de Metal).
                if(isDead || shockedTimer > 0)
                        tornadoState = 1; // cortar en el siguiente bloque
                else if(!isGrounded)
                {
                        // v27 (la "animacion muerta que seguia empujando"):
                        // el remolino es un ataque DE SUELO. Si un trampolin,
                        // una rampa o el borde de una plataforma la sacan del
                        // suelo a mitad de carrera, ANTES el ataque seguia
                        // vivo por detras (isAttacking ya lo habia matado el
                        // cierre defensivo del estado 14 y el bloque este le
                        // seguia dando velocidad + fantasmas + i-frames: un
                        // tornado FANTASMA empujando a una Rouge corriendo).
                        // Ahora se corta LIMPIO, SIN recarga (la saco del
                        // suelo el mapa: el impulso del trampolin o la caida
                        // del borde se respeta tal cual).
                        tornadoState = 0;
                        isAttacking = false;
                }

                // v27: si uno de los cortes de arriba lo cerro este frame,
                // no queda nada que hacer aqui (antes el movimiento y el
                // desconteo seguian corriendo con el ataque ya muerto).
                if(tornadoState > 0)
                {
                        // RAPIDO al arranque y PERDIENDO velocidad hasta el minimo.
                        // v25: el frenado termina en ROUGE_TORNADO_BRAKE (0.8 s, el
                        // perfil de siempre) y NO se estira a la nueva duracion de
                        // 3 s: pasados los 0.8 s el remolino recorre el resto de la
                        // habilidad a la velocidad minima (1.5) — misma pegadura de
                        // arranque, duracion larguisima.
                        var _elapsed = ROUGE_TORNADO_TIME - tornadoState;
                        var _speed = ROUGE_TORNADO_START - (ROUGE_TORNADO_START - ROUGE_TORNADO_MIN) * min(_elapsed / ROUGE_TORNADO_BRAKE, 1);

                        xspd = _speed * image_xscale;
                        gspd = xspd;

                        // v24: residuos fantasma del remolino (mismo sistema del
                        // taladro: effectTime local + bitflag PLAYER_EFFECT remoto)
                        if(effectTime <= 0)
                                effectTime = 16;

                        // estela del remolino mientras avanza
                        if(floor(x) mod 3 == 0)
                                net_quick_effect(x - 10 * image_xscale, y, spr_dust);

                        // CHOQUE CONTRA PARED: corta el tornado (patron Metal).
                        // v26: el corte SOLO vale si el remolino VIAJO desde donde
                        // nacio (abs(x - tornadoStartX) > ROUGE_TORNADO_WALL_TRAVEL);
                        // si NACE pegado a la pared, gira EN EL SITIO toda su duracion
                        // (colision lo frena, la tira sigue en loop con sus i-frames).
                        // v28 (raiz del "tornado no funciona"): el probe usaba
                        // place_meeting con la MASCARA de Rouge, y la mascara de
                        // spr_rouge_attack2 cuelga 5 px POR DEBAJO de la linea del
                        // suelo (bbox_bottom 50 - yorigin 27 = +23, contra los -18
                        // del snap de scr_collision_basic): el propio suelo contaba
                        // como "pared" y el tornado moria en el frame 2 sobre
                        // CUALQUIER terreno, plano o pendiente. Ahora se sondea con
                        // un PUNTO (position_meeting): inmune a la mascara del
                        // sprite. El punto va a y - 10 (28 px sobre la linea del
                        // suelo: ni el suelo plano ni una cuesta de 45 grados suben
                        // ahi, y el techo de un pasillo de 3 tiles queda a 20 px)
                        // y a 18 px por delante/detras (1 px mas alla del borde de
                        // su mascara, +17: dispara EXACTO al tocar la pared, sin
                        // verla antes de tiempo).
                        if((position_meeting(x + 18 * image_xscale, y - 10, obj_floor_parent) || position_meeting(x - 18 * image_xscale, y - 10, obj_floor_parent))
                        && abs(x - tornadoStartX) > ROUGE_TORNADO_WALL_TRAVEL)
                        {
                                tornadoState = 1;
                                scr_camera_shake(12, 2, 0.2);

                                repeat(4)
                                        net_quick_effect(x + 8 * image_xscale + random_range(-6, 6), y + random_range(-10, 4), spr_dust);
                        }

                        tornadoState--;

                        if(tornadoState <= 0)
                        {
                                isAttacking = false;
                                attackTimer = revivalTimes >= 2 ? ROUGE_ATTACK_RECHARGE / 2 : ROUGE_ATTACK_RECHARGE;
                        }
                }
        }

        // ---------------- patada activa (v32, modo ATTACK) ----------------
        // La tira se mantiene en su ultimo frame (Draw_76) y el cierre
        // lo da el timer: i-frames hasta el final (scr_player_hurt
        // mira kickState). Dano, stun o muerte la cortan igual (la
        // recarga ya se pago al activar, como la de Sally).
        if(kickState > 0)
        {
                if(isDead || shockedTimer > 0 || isHurt)
                {
                        kickState = 0;
                        isAttacking = false;
                }
                else
                {
                        kickState--;

                        if(kickState <= 0)
                                isAttacking = false;
                }
        }

        // ---------------- escudo electrico activo (v32, modo EGGMAN) ----------------
        // Aura de contacto de 1,5 s: cierra por timer (o muerte/stun —
        // el dano NO lo apaga: igual que el doctor, un golpe no apaga
        // la descarga). La recarga ya corre desde la activacion.
        if(eShieldTimer > 0)
        {
                if(isDead || shockedTimer > 0)
                {
                        eShieldTimer = 0;
                        isAttacking = false;
                }
                else
                {
                        eShieldTimer--;

                        if(eShieldTimer <= 0)
                                isAttacking = false;
                }
        }

        // ---------------- escudo de Sally activo (v32, modo SUPPORT) ----------------
        // Burbuja de 5 s: absorbe un golpe (scr_player_hurt) y al
        // expirar solita suena el rompimiento si va debilitada (patron
        // exacto de Sally: el efecto de romperse va en el bloque del
        // golpe; aqui solo el expiry del caso debilitada).
        if(shieldTimer > 0)
        {
                shieldTimer--;

                if(shieldTimer <= 0 && revivalTimes >= 2)
                {
                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                        net_quick_effect(x, y, spr_shieldbreak2, false, 1, 0, 0, 1);
                        net_sound_emit(snd_sally_shieldbreak);
                }
        }

        // ---------------- canal de anillos activo (v32, modo SUPPORT) ----------------
        // QUIETA invocando (patron Vanilla): perder el suelo, dano,
        // stun, muerte o perder el control corta el canal PAGANDO la
        // recarga entera. Al completarlo sale el paquete y los anillos
        // los spawnea el server para todos (valen 4 al recogerlos).
        if(ringsChannel > 0)
        {
                if(!isGrounded || isHurt || isDead || shockedTimer > 0 || !global.playerControls)
                {
                        ringsChannel = 0;
                        ringsTimer = ROUGE_RINGS_RECHARGE;
                }
                else if(ringsChannel <= 1)
                {
                        // desove (patron Vanilla: al final del canal)
                        audio_play_sound(snd_creamring, 0, false);
                        net_sound_emit(snd_creamring);

                        var _rpk = cpacket_tcp(PacketType.CLIENT_CREAM_SPAWN_RINGS, false);
                        buffer_write(_rpk, buffer_u16, x);
                        buffer_write(_rpk, buffer_u16, y - 24);
                        buffer_write(_rpk, buffer_u8, 0); // pareja normal (Rouge jamas se demoniza)
                        send_server_tcp(_rpk);

                        ringsChannel = 0;
                        ringsTimer = ROUGE_RINGS_RECHARGE;
                }
                else
                {
                        gspd = 0;
                        xspd = 0;
                        yspd = 0;
                        ringsChannel--;
                }
        }

        // v24 — CAMBIO DE MODO AEREO -> TERRESTRE (taladro -> tornado): el
        // TALADRO fue usado EN EL AIRE y TODAVIA LE QUEDA CARGA (isAttacking
        // sigue viva: el drillState no se agoto) cuando TOCA SUELO -> el
        // ataque cambia de modalidad y arranca el TORNADO (modo terrestre)
        // con la duracion REINICIADA AL MAXIMO (ROUGE_TORNADO_TIME completa:
        // como si la habilidad de tierra se hubiera activado — 2 habilidades
        // en 1) con sus i-frames, su recorrido y sus residuos fantasma.
        // La recarga la sigue pagando el tornado al terminar (una sola).
        // Solo se llega aqui aterrizando en mitad del taladro: el X en
        // tierra ya deja tornadoState > 0 en el MISMO frame, el taladro
        // agotado en el aire apaga isAttacking y el tornado terminado
        // tambien.
        // v37 (bug del video de la duena): este cambio de modo es
        // EXCLUSIVO del taladro que aterriza — exige drillState > 0.
        // Sin el gate, la PATADA (v32) y el ESCUDO ELECTRICO (v34) al
        // tocar suelo con isAttacking arrancaban el tornado COMPLETO
        // (recorrido, polvareda y snd_dash) con la animacion pisada
        // por su propio estado: el escudo se veia como "el patron del
        // torbellino sin la animacion" y la lanzaba hacia adelante.
        if(isAttacking && isGrounded && tornadoState <= 0 && drillState > 0 && !isHurt && !isDead && shockedTimer <= 0)
        {
                // el taladro termina aqui: el tornado toma el relevo
                drillState = 0;
                tornadoState = ROUGE_TORNADO_TIME;
                tornadoStartX = x; // v26: origen del remolino (ver corte de pared)
                isJumping = false;

                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);

                // polvareda del cambio de modo (la misma del arranque)
                repeat(3)
                        net_quick_effect(x - image_xscale * (4 + irandom(8)), y + 12 + irandom(4), spr_dust, false, -image_xscale, -image_xscale, -irandom(1));
        }
        else if(isAttacking && !isGrounded && tornadoState <= 0 && drillState <= 0
        && kickState <= 0 && eShieldTimer <= 0)
        {
                // (defensivo de la v24, hoy MUERTO para todo ataque real:
                // taladro (drillState), patada (kickState) y escudo
                // (eShieldTimer) ya no caen aqui — este fallback empujaba
                // xspd = 2 a la PATADA y al ESCUDO en el aire (v37: otra
                // cara del bug del video). Se conserva por si algun dia
                // hay un ataque aereo sin estado propio.)
                gspd = 0;
                xspd = image_xscale * 2;
        }

        // el dano corta el vuelo, el planeo y desarma la bola del spindash
        if(isHurt)
        {
                isFlying = false;
                isGliding = false;

                if(isStuck)
                {
                        canMove = true;
                        isStuck = false;
                }

                spinDashRelease = false;
        }

        // ---------------- vuelo activo (patron VANILLA: subir y bajar) ----------------
        if(isFlying)
        {
                isSpinning = false;
                isJumping = false;

                // MANTENER Z: SUBE. SOLTAR: baja lento (planeo) — el pedido.
                if(global.playerControls && keyboard_check(global.KeyA))
                        yspd = ROUGE_FLY_RISE;
                else
                        yspd = ROUGE_FLY_GLIDE;

                // duracion del vuelo: flyTimeout cuenta frames en el aire
                flyTimeout++;

                if(flyTimeout > ROUGE_FLY_SOLO)
                        isFlying = false;

                if(isGrounded)
                        isFlying = false;
        }

        // aleteo audible mientras vuela (patron Tails/Vanilla)
        if(isFlying && floor(flyTimeout) mod 18 == 0 && flyTimeout > 0)
        {
                audio_play_sound(snd_tails_fly, 0, false);
                net_sound_emit(snd_tails_fly);
        }

        // ---------------- GLIDE PASIVA (v14, tipo Knuckles) ----------------
        // MANTENER Z al empezar a DESCENDER (yspd > 0) = planeo. NO mira
        // flyTimer (el vuelo activo es aparte), NO mira redRingTimer (es
        // una PASIVA: el anillo rojo NO la bloquea) y NO tiene tope de
        // tiempo: mientras Z siga pulsada, planea — siempre baja (v24:
        // ROUGE_GLIDE_FALL 0.65, un 35% mas lento que Knuckles), no puede
        // estancar la partida.
        // Al despegar el vuelo activo con Z aun MANTENIDA: cuando este
        // termina (tope de 5 s o soltarla), si Z sigue pulsada el planeo
        // toma el relevo solo — la cadena natural del pedido.
        // v24: el vuelo activo se activa con Z + ARRIBA — una Z suelta al
        // caer ya NO lo gasta: cae derecha al planeo.
        if(global.playerControls && !isGrounded && !isGliding && !isFlying && !isAttacking
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline && !isSliding
        && !isStuck && yspd > 0 && keyboard_check(global.KeyA))
        {
                isGliding = true;
                isJumping = false;
                isSpinning = false;
                spinDashRelease = false;
                glide_xspd = image_xscale * ROUGE_GLIDE_SPD;
        }

        // planeo activo (patron Knuckles): izquierda/derecha ajustan el
        // glide_xspd dentro de +-ROUGE_GLIDE_SPD y la TIRA DIRECCIONAL
        // spr_rouge_glide (frame 0..4) muestra hacia donde se desliza.
        // SOLTAR Z = caida libre. La pared la agarra (scr_collision_basic
        // pide glideTimer > 0 para Rouge: vale 1 mientras planea).
        if(isGliding)
        {
                // puerta del agarre de pared abierta mientras planea
                glideTimer = 1;

                if(global.playerControls && keyboard_check(global.KeyA))
                {
                        if(!isStuck)
                        {
                                if(global.playerControls && keyboard_check(global.KeyLeft))
                                {
                                        if(glide_xspd > -ROUGE_GLIDE_SPD)
                                                glide_xspd -= acc * ROUGE_GLIDE_ACC;
                                }
                                else if(global.playerControls && keyboard_check(global.KeyRight))
                                {
                                        if(glide_xspd < ROUGE_GLIDE_SPD)
                                                glide_xspd += acc * ROUGE_GLIDE_ACC;
                                }

                                // tira direccional (frame = intensidad del
                                // desliz). v24: por RANGOS, no casos exactos
                                // — ROUGE_GLIDE_SPD ya no es entero (6.25 =
                                // 25% mas que el 5 de Knuckles) y floor()
                                // nunca matcheaba los case viejos.
                                var _gi = floor(glide_xspd);

                                if(_gi >= 2)
                                        image_index = 0;
                                else if(_gi == 1)
                                        image_index = 1;
                                else if(_gi == 0)
                                        image_index = 2;
                                else if(_gi == -1)
                                        image_index = 3;
                                else
                                        image_index = 4;
                        }
                }
                else
                {
                        // soltar Z = fin del planeo (y del agarre si la habia)
                        isGliding = false;

                        if(isStuck)
                        {
                                canMove = true;
                                isStuck = false;
                        }
                }

                // la tira es direccional (como la de Knuckles): siempre mira
                // a la derecha, el frame dice el lado — sin espejo.
                // v24: cae un 35% MAS LENTO que el planeo de Knuckles EN
                // JUEGO: la gravedad (yAccel) se suma en
                // scr_collision_basic DESPUES de este bloque, asi que aqui
                // se deja el yspd en OBJETIVO - yAccel y la gravedad
                // rellena hasta ROUGE_GLIDE_FALL (0.7922 efectivos = el
                // 65% de los 1.21875 efectivos del planeo de Knux).
                image_xscale = 1;
                yspd = ROUGE_GLIDE_FALL - yAccel;
                xspd = glide_xspd;

                // aterrizar o dano cierran el planeo (el dano ya apaga
                // isGliding arriba en su bloque)
                if(isGrounded)
                {
                        isGliding = false;

                        if(isStuck)
                        {
                                canMove = true;
                                isStuck = false;
                        }
                }
        }

        // ---------------- SLIDE (v14, patron SALLY) ----------------
        // ABAJO recien pulsada mientras corre (|xspd| >= ROUGE_SLIDE_MIN)
        // = slide en vez del rodar clasico (canSpin = false en el Create).
        // Mismas reglas que Sally: slideSpeed = xspd + 2 en la direccion
        // que llevaba y decae sola; el slide corta stun, aire, borde de
        // pantalla y quedarse sin velocidad.
        if(global.playerControls && abs(xspd) >= ROUGE_SLIDE_MIN && keyboard_check_pressed(global.KeyDown) && isGrounded && !isSliding
        && !isAttacking && !isSpinning && !isSpinCharging && !isHurt && !isDead
        && shockedTimer <= 0 && !isZipline && !isHiding)
        {
                audio_play_sound(snd_sally_slide, 0, false);
                net_sound_emit(snd_sally_slide);

                isAttacking = false;
                isSliding = true;
                slideSpeed = xspd + 2 * sign(xspd);
        }

        if(isSliding)
        {
                if(shockedTimer > 0 || !isGrounded || x <= 1 || x >= room_width - 1)
                {
                        isSliding = false;
                }
                else if(abs(slideSpeed) > 0)
                {
                        slideSpeed -= min(abs(slideSpeed), acc * 2.5) * sign(slideSpeed) * cos(angle);

                        if(floor(x) % 5 == 0)
                        {
                                net_quick_effect(x - 8 * sign(slideSpeed), y + 20, spr_dust);
                                audio_play_sound(snd_sally_slide, 0, false);
                        }

                        gspd = 0;
                        xspd = slideSpeed * cos(angle);
                        yspd = slideSpeed * -sin(angle);
                }
                else
                {
                        isSliding = false;
                }
        }

        // =================================================================
        //  v32 — MEJORAR TRAMPAS (capacidad NATA, en TODAS las
        //  modalidades): el "Genio Malvado" de Eggman (scr_egg_special
        //  v3.1) porteado para Rouge. Mantiene ABAJO ENCIMA de una
        //  TRAMPA de Amelia (5 anillos) o un SENSOR de Eggman (3) con
        //  anillos de sobra: la MISMA barra del revive se llena del
        //  lado del server y al completarse cobra los anillos y DORA la
        //  trampa (+25% de efectividad). Soltar el ABAJO a mitad NO
        //  tira el dinero: el progreso queda en el server (patron
        //  revive). Cero paquetes nuevos: net_egg_upgrade_progress.
        // =================================================================
        if(global.playerControls && revivalTimes < 2 && !isDead
        && !(variable_instance_exists(id, "isNegatouch") && isNegatouch))
        {
                // 1) mantener el LOCK mientras la trampa siga valida y
                // cerca (patron dedemonTarget: sin cambios de objetivo
                // a mitad de barra)
                if(geniusTarget != -1)
                {
                        var _lockNid = geniusTarget;
                        var _lockType = geniusTargetType;
                        var _keep = noone;

                        with(_lockType == 1 ? obj_amelia_trap : obj_eggtrack)
                        {
                                if(nid != _lockNid)
                                        continue;

                                if((_lockType == 1 && (upgraded || triggerSent))
                                || (_lockType == 0 && (upgraded || activated))
                                || distance_to_object(global.player) > EGG_GENIUS_RANGE * 1.5)
                                        continue;

                                _keep = self;
                                break;
                        }

                        if(!instance_exists(_keep))
                        {
                                // lock liberado: la barra a medio llenar
                                // se conserva en el server, no se tira nada
                                geniusTarget = -1;
                                geniusTargetType = -1;
                        }
                }

                // 2) sin lock: la TRAMPA de Amelia mas cercana y si no
                // hay, un SENSOR (misma prioridad que Eggman)
                if(geniusTarget == -1)
                {
                        var _trap = noone;

                        if(instance_exists(obj_amelia_trap))
                        {
                                var _best = EGG_GENIUS_RANGE;

                                with(obj_amelia_trap)
                                {
                                        if(upgraded || triggerSent)
                                                continue;

                                        var _d = distance_to_object(global.player);

                                        if(_d <= _best)
                                        {
                                                _best = _d;
                                                _trap = self;
                                        }
                                }
                        }

                        var _sensor = noone;

                        if(!instance_exists(_trap) && instance_exists(obj_eggtrack))
                        {
                                var _best2 = EGG_GENIUS_RANGE;

                                with(obj_eggtrack)
                                {
                                        if(upgraded || activated)
                                                continue;

                                        var _d = distance_to_object(global.player);

                                        if(_d <= _best2)
                                        {
                                                _best2 = _d;
                                                _sensor = self;
                                        }
                                }
                        }

                        if(instance_exists(_trap))
                        {
                                geniusTarget = _trap.nid;
                                geniusTargetType = 1;
                        }
                        else if(instance_exists(_sensor))
                        {
                                geniusTarget = _sensor.nid;
                                geniusTargetType = 0;
                        }
                }

                // 3) prompt (upgOver en el Step de cada trampa) + envio
                // del progreso mientras se mantiene ABAJO con anillos
                if(geniusTarget != -1 && isLookingDown
                && rings >= (geniusTargetType == 1 ? EGG_GENIUS_TRAP_COST : EGG_GENIUS_SENSOR_COST)
                && geniusSendCd <= 0)
                {
                        geniusSendCd = EGG_GENIUS_SEND_CD;

                        net_egg_upgrade_progress(geniusTargetType, geniusTarget, rings);
                }
        }

        // ---------------- recarga del vuelo (patron VANILLA) ----------------
        // la puerta flyTimer cuenta hacia atras SOLO cuando NO esta volando.
        // (OJO: no decrementa glideTimer — para Rouge ya no es una recarga:
        // vale 1 mientras planea para la puerta del agarre de pared.)
        if(!isFlying && flyTimer > 0)
                flyTimer--;

        if(attackTimer > 0)
                attackTimer--;

        // ---------------- timers de la habilidad V (v32) ----------------
        if(modeFlash > 0)
                modeFlash--;

        // v34: decay de la recarga PROPIA de la patada
        if(kickRecharge > 0)
                kickRecharge--;

        if(eShieldRecharge > 0)
                eShieldRecharge--;

        if(shieldRechrage > 0)
                shieldRechrage--;

        if(ringsTimer > 0)
                ringsTimer--;

        if(trackerRecharge > 0)
                trackerRecharge--;

        if(geniusSendCd > 0)
                geniusSendCd--;
}
