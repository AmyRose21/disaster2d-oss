function scr_rouge_special()
{
        // =====================================================================
        //  ROUGE (v13 — REWORK DE LA DUEÑA) — kit nuevo:
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
        //     terminar. El X EN EL AIRE sigue siendo la patada aerea
        //     (spr_rouge_attack1, estado 14) de siempre.
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

        // ---------------- SPINDASH (abajo + Z en tierra) ----------------
        // Reglas de Sonic: un solo camino para la 1a pulsacion y las
        // siguientes; exige suelo, parada (|gspd| < 2), y el resto de los
        // guards clasicos. El vuelo/ataque/tornado/hurt/stun lo cancelan.
        if(global.playerControls && isGrounded && !isAttacking && !isHurt
        && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
        && redRingTimer <= 0 && !isFlying
        && keyboard_check(global.KeyDown) && abs(gspd) < ROUGE_SPINDASH_START_MAX
        && !isSpinning && !isSpinCharging && keyboard_check_pressed(global.KeyA))
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

        // ---------------- VUELO patron VANILLA (Z en el aire) ----------------
        // v4.9 (COYOTE): mismo guard que Vanilla/Tails — si acaba de dejar
        // el suelo dentro de la ventana de salto, el Z se lo lleva el salto
        // normal; el vuelo sale con la siguiente pulsacion.
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && !isGrounded && !isAttacking && !isSpinCharging
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

        // ---------------- TORNADO (X en tierra) + PATADA AEREA (X en aire) ----------------
        // X EN TIERRA: el tornado (spr_rouge_attack2, estado 15) — sale a
        // 12 px/f y decae hasta 1.5 al cabo de 0.8 s, con i-frames durante
        // TODO el recorrido (scr_player_hurt). X EN EL AIRE: la patada con
        // vuelo de siempre (spr_rouge_attack1, estado 14).
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && tornadoState <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;

                if(isGrounded)
                {
                        // --- TORNADO ---
                        tornadoState = ROUGE_TORNADO_TIME;
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
                        // --- PATADA AEREA (la de siempre, patron Sally) ---
                        attackTimer = ROUGE_ATTACK_RECHARGE;
                        isAttacking = true;
                        isFlying = false; // pegar manda (corta el vuelo)

                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);
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

                // RAPIDO al arranque y PERDIENDO velocidad hasta el minimo:
                // transcurrido = ROUGE_TORNADO_TIME - tornadoState
                var _elapsed = ROUGE_TORNADO_TIME - tornadoState;
                var _speed = ROUGE_TORNADO_START - (ROUGE_TORNADO_START - ROUGE_TORNADO_MIN) * min(_elapsed / ROUGE_TORNADO_TIME, 1);

                xspd = _speed * image_xscale;
                gspd = xspd;

                // estela del remolino mientras avanza
                if(floor(x) mod 3 == 0)
                        net_quick_effect(x - 10 * image_xscale, y, spr_dust);

                // CHOQUE CONTRA PARED: corta el tornado (patron Metal).
                if(place_meeting(x + 4 * image_xscale, y, obj_floor_parent) || place_meeting(x - 4 * image_xscale, y, obj_floor_parent))
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
        else if(isAttacking && !isGrounded)
        {
                // la patada aerea clasica mantiene su empujoncito horizontal;
                // el tornado NO pasa por aqui (tornadoState > 0 arriba).
                gspd = 0;
                xspd = image_xscale * 2;
        }

        // el dano corta el vuelo y desarma la bola del spindash
        if(isHurt)
        {
                isFlying = false;
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

        // ---------------- recarga del vuelo (patron VANILLA) ----------------
        // la puerta flyTimer cuenta hacia atras SOLO cuando NO esta volando.
        if(!isFlying && flyTimer > 0)
                flyTimer--;

        if(attackTimer > 0)
                attackTimer--;
}
