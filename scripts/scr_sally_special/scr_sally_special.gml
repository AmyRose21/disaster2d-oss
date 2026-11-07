function scr_sally_special()
{
        // SALLY CANON: si la patada termino (fin de animacion, dano o
        // stun apagan isAttacking), apaga tambien la marca de patada en
        // tierra. La vanilla no define groundKick: solo se lee detras
        // del gate de SALLY_CANON, nunca en obj_sally.
        if(global.character == CHARACTER_SALLY_CANON && !isAttacking)
                groundKick = false;

        if(redRingTimer > 0)
        {
                if(shieldRechrage <= 2)
                        shieldRechrage = 2;

                if(attackTimer <= 2)
                        attackTimer = 2;

                isAttacking = false;

                // SALLY CANON (duelista): el anillo rojo corta tambien la
                // carga del spindash (mismo patron que Amelia).
                if(global.character == CHARACTER_SALLY_CANON && isSpinCharging)
                {
                        isSpinCharging = false;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);
                }
        }

        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;

                if(shieldRechrage <= 60 * 2)
                        shieldRechrage = 60 * 2;

                isAttacking = false;

                // SALLY CANON (duelista): esconderse corta la carga del
                // spindash (colocar no rompe el sigilo; pelear, si).
                if(global.character == CHARACTER_SALLY_CANON && isSpinCharging)
                {
                        isSpinCharging = false;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);
                }
        }

        // PATADA (tecla X): en el AIRE para las dos Sally (como siempre)
        // y EN TIERRA solo para Sally Canon en fase duelista (la nueva
        // de 2 patadas; la vanilla y la canon fase 1 siguen solo aerea).
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0)
        {
                if(!isGrounded)
                {
                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);

                        if(keyboard_check(global.KeyLeft))
                                image_xscale = -1;
                        else if(keyboard_check(global.KeyRight))
                                image_xscale = 1;

                        image_index = 0;
                        image_speed = 0;
                        isJumping = false;
                        isAttacking = true;

                        // canon: esta es la aerea (estado 14), no la de tierra
                        if(global.character == CHARACTER_SALLY_CANON)
                                groundKick = false;

                        attackTimer = revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                }
                else if(global.character == CHARACTER_SALLY_CANON && duelista
                && !isSliding && !isSpinCharging && !isHiding && !isHurt && !isDead
                && shockedTimer <= 0 && !isZipline && redRingTimer <= 0)
                {
                        // PATADA EN TIERRA (fase duelista): 2 patadas en 1
                        // animacion (spr_sally_fase2_attack_canon, estado 22).
                        // La 1a ocupa los frames 0-6 y la 2a entra del 7 en
                        // adelante; cada una puede golpear al bando EXE 1 vez
                        // (la unica habilidad del juego con doble golpe) e
                        // ignora TODOS los i-frames: si la 1a conecta, el exe
                        // se TP al frente de Sally y come la 2a. Todo eso lo
                        // aplica el cliente de la victima (obj_player_puppet).
                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);

                        if(keyboard_check(global.KeyLeft))
                                image_xscale = -1;
                        else if(keyboard_check(global.KeyRight))
                                image_xscale = 1;

                        image_index = 0;
                        isAttacking = true;
                        groundKick = true;
                        attackTimer = revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                }
        }

        // SPINDASH (SALLY CANON, fase duelista): abajo + Z repetido
        // parado carga la bola; soltar ABAJO la lanza (estado SPIN, bola
        // spr_sally_spindash_canon). Porte 1:1 del de Amelia/Sonic con
        // los mismos valores (SALLY_CANON_SPINDASH_*): sin cooldown, el
        // coste es el tiempo de revolucioneo.
        if(global.character == CHARACTER_SALLY_CANON && duelista)
        {
                if(global.playerControls && isGrounded && !isAttacking && !isHurt
                && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
                && redRingTimer <= 0
                && keyboard_check(global.KeyDown) && gspd == 0 && keyboard_check_pressed(global.KeyA))
                {
                        isSpinCharging = true;
                        spinCharge = min(spinCharge + SALLY_CANON_SPINDASH_REV, SALLY_CANON_SPINDASH_CHARGE_MAX);
                        spinChargeDecay = 0;
                        spinDustTimer = 0;
                        image_index = 0;

                        // cada revolucada suena MAS aguda (1.0 -> 1.8 con la
                        // bola llena) y patea polvo detras (por red)
                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);
                        spinRevSnd = audio_play_sound(snd_spin, 0, false);
                        audio_sound_pitch(spinRevSnd, 1.0 + (spinCharge / SALLY_CANON_SPINDASH_CHARGE_MAX) * SALLY_CANON_SPINDASH_PITCH_STEP);
                        net_sound_emit(snd_spin);

                        net_quick_effect(x - image_xscale * 12, y + 16, spr_dust, false, -image_xscale, -image_xscale * 2, -1);
                }

                if(isSpinCharging)
                {
                        // Quieta mientras carga, pero puede girar la mirada.
                        gspd = 0;

                        if(keyboard_check(global.KeyLeft))
                                image_xscale = -1;
                        else if(keyboard_check(global.KeyRight))
                                image_xscale = 1;

                        // La carga decae sola si dejas de dar revolucadas.
                        spinChargeDecay++;
                        if(spinChargeDecay >= SALLY_CANON_SPINDASH_DECAY)
                        {
                                spinChargeDecay = 0;
                                spinCharge = max(0, spinCharge - 1);
                        }

                        // polvo ambiente detras mientras carga (solo local)
                        spinDustTimer++;

                        if(spinDustTimer >= SALLY_CANON_SPINDASH_DUST_EVERY)
                        {
                                spinDustTimer = 0;
                                scr_effect_quick(x - image_xscale * (10 + irandom(4)), y + 14 + irandom(3), spr_dust, 0.4, false, -image_xscale, -0.5);
                        }

                        // Cancelaciones: dano, stun, muerte, tirolina, perder
                        // el suelo, anillo rojo o esconderse.
                        if(isHurt || isDead || shockedTimer > 0 || isZipline || !isGrounded
                        || redRingTimer > 0 || isHiding)
                        {
                                isSpinCharging = false;
                                spinCharge = 0;

                                if(spinRevSnd != -1)
                                        audio_stop_sound(spinRevSnd);
                        }
                        else if(!global.playerControls || !keyboard_check(global.KeyDown))
                        {
                                // --- LANZAMIENTO del spindash ---
                                var _chg = spinCharge;
                                isSpinCharging = false;
                                isSpinning = true;    // sale en bola (estado SPIN)
                                isJumping = false;
                                gspd = (SALLY_CANON_SPINDASH_BASE + _chg) * image_xscale;
                                spinCharge = 0;

                                if(spinRevSnd != -1)
                                        audio_stop_sound(spinRevSnd);

                                audio_play_sound(snd_dash, 0, false);
                                net_sound_emit(snd_dash);

                                // polvareda de salida detras (3 nubes sin carga
                                // -> 8 con la bola llena), por red
                                var _burst = SALLY_CANON_SPINDASH_BURST_MIN + floor(_chg / SALLY_CANON_SPINDASH_CHARGE_MAX * (SALLY_CANON_SPINDASH_BURST_MAX - SALLY_CANON_SPINDASH_BURST_MIN));

                                for(var i = 0; i < _burst; i++)
                                {
                                        var _dx = x - image_xscale * (6 + irandom(12));
                                        var _dy = y + 12 + irandom(5);

                                        net_quick_effect(_dx, _dy, spr_dust, false, -image_xscale, -image_xscale * (1 + irandom(2)), -irandom(1));
                                }

                                // mini-temblor de camara proporcional a la carga
                                if(_chg > 0)
                                        scr_camera_shake(12, 1 + _chg * 0.15, 0.2);
                        }
                }
        }

        if(global.playerControls && keyboard_check_pressed(global.KeyC) && shieldRechrage <= 0)
        {
                audio_play_sound(snd_sally_shield, 0, false);
                net_sound_emit(snd_sally_shield);

                shieldTimer = 5 * 60;
                // Canon: recarga propia (28 s, 2 menos que la vanilla).
                shieldRechrage = global.character == CHARACTER_SALLY_CANON ? SALLY_CANON_SHIELD_RECHARGE : (revivalTimes >= 2 ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE);

                // v5.8: POSE DE ACTIVACION (un solo uso). Al pulsar la
                // habilidad se reproduce UNA vez la pose que toca segun
                // el momento (quieta / agachada / en el aire) y ya: no
                // loopea, no se queda clavada y no vuelve a salir mientras
                // dura el escudo (solo al pulsar OTRA VEZ la habilidad).
                // Solo Sally Canon en fase duelista: la Sally vanilla no
                // tiene estas variables y el gate corta antes de leerlas
                // (mismo patron que groundKick alla arriba). El "state"
                // leido aqui es el del frame anterior — justo la pose que
                // el jugador esta VIENDO al pulsar la tecla.
                if(global.character == CHARACTER_SALLY_CANON && duelista && !isHurt && !isDead && shockedTimer <= 0 && fase2State == SALLY_CANON_F2_OFF)
                {
                        var _poseCat = 0;
                        if(state == JUMP || state == FALL)
                                _poseCat = 2;
                        else if(state == LOOKDOWN)
                                _poseCat = 1;

                        shieldPoseCat = _poseCat;
                        shieldPoseT = 0;

                        switch(_poseCat)
                        {
                                case 1: shieldPoseSpr = spr_sally_shield_down_canon; break;
                                case 2: shieldPoseSpr = spr_sally_shield_air_canon; break;
                                default: shieldPoseSpr = spr_sally_shield_canon; break;
                        }

                        shieldPoseOn = true;
                }
        }

        if(global.playerControls && abs(xspd) >= 2.5 && keyboard_check_pressed(global.KeyDown) && isGrounded && !isSliding)
        {
                audio_play_sound(snd_sally_slide, 0, false);
                net_sound_emit(snd_sally_slide);

                isAttacking = false;
                isSliding = true;
                slideSpeed = xspd + 2 * sign(xspd);
        }

        if(shieldRechrage > 0)
                shieldRechrage--;

        if(attackTimer > 0)
                attackTimer--;

        if(shieldTimer > 0)
        {
                shieldTimer--;
                if(shieldTimer <= 0 && revivalTimes >= 2)
                {
                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                        net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                        net_sound_emit(snd_sally_shieldbreak);
                }

                shieldRechrage = global.character == CHARACTER_SALLY_CANON ? SALLY_CANON_SHIELD_RECHARGE : (revivalTimes >= 2 ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE);
        }

        if(isSliding)
        {
                if(shockedTimer > 0)
                {
                        isSliding = false;
                        return;
                }

                if(!isGrounded)
                {
                        isSliding = false;
                        return;
                }

                if(x <= 1 || x >= room_width - 1)
                {
                        isSliding = false;
                        return;
                }

                if(abs(slideSpeed) > 0)
                {
                        slideSpeed -= min(abs(slideSpeed), acc * 2.5) * sign(slideSpeed) * cos(angle);
                }
                else
                {
                        isSliding = false;
                        return;
                }

                if(floor(x) % 5 == 0)
                {
                        net_quick_effect(global.player.x - 8 * sign(slideSpeed), global.player.y + 20, spr_dust);
                        audio_play_sound(snd_sally_slide, 0, false);
                }

                gspd = 0;
                xspd = slideSpeed * cos(angle);
                yspd = slideSpeed * -sin(angle);
        }
}
