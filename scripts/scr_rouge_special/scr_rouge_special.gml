function scr_rouge_special()
{
        // =====================================================================
        //  ROUGE (v4.6) — moveset "ladrona de joyas": VUELO patron Tails
        //  + la patada de Sally en sus dos variantes.
        //
        //   * Z en el aire = VUELO (patron Tails): arranca con el
        //     presupuesto lleno (ROUGE_FLY_TIME, 2.67 s) y cada pulsacion
        //     de Z la re-impulsa hacia arriba (flyGrv = -1); entre
        //     pulsaciones la gravedad propia del vuelo decae hasta +2
        //     (cada vez cae mas suave). Agotado el presupuesto se cae con
        //     la gravedad normal. Recarga en el suelo: 7 s
        //     (ROUGE_FLY_RECHARGE). El suelo, el dano y los muelles cortan
        //     el vuelo, exactamente como a Tails. (v4.4-4.5: antes era
        //     planeo patron Knuckles con agarre de pared; la tira
        //     direccional de 5 frames del planeo pasa a ser la pose de
        //     vuelo con las alas extendidas.)
        //   * X = PATADA (patron Sally): en tierra el barrido bajo
        //     (spr_rouge_attack2, estado 15) y en el aire la patada con
        //     vuelo (spr_rouge_attack1, estado 14) con su empujoncito
        //     horizontal de ataque. La patada corta el vuelo. El stun de
        //     3 s al bando EXE lo aplica el cliente de la VICTIMA
        //     (obj_player_puppet, bit PLAYER_ATTACKING que viaja con
        //     Rouge en obj_netclient). Recarga 20 s.
        //
        //  v4.5 — MORIBUNDA: su salvacion de 1ra caida (la activa
        //  scr_player_instakill desde scr_player_hurt, patron Vanilla):
        //  mientras moribundaState > 0 esta tirada en el suelo, quieta e
        //  inmune; a los 6 s se levanta sola con 40 de vida. Ni vuelo ni
        //  patada mientras dura. El server jamas se entera (la 2da caida
        //  SI es muerte real: guard canon del server).
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
                isFlying = false; // v4.6: moribunda no vuela

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
                        flyTimer = -ROUGE_FLY_RECHARGE; // misericordia: vuelo listo al levantarse
                        attackTimer = 0;                // ...y la patada tambien
                }

                return;
        }

        // anillo rojo / esconderse: sin especiales y SIN recargar el vuelo
        // (patron Tails: el flyTimer se mantiene a un pelo del tope para
        // que no llegue a "recargado" y no pueda despegar)
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;

                if(flyTimer <= -ROUGE_FLY_RECHARGE + 2)
                        flyTimer = -ROUGE_FLY_RECHARGE + 2;
        }

        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;

                if(flyTimer <= -ROUGE_FLY_RECHARGE + 2 * 60)
                        flyTimer = -ROUGE_FLY_RECHARGE + 2 * 60;
        }

        // ---------------- VUELO (tecla Z en el aire) ----------------
        // v4.9 (COYOTE): mismo guard que Tails — si acaba de dejar el
        // suelo dentro de la ventana de salto, el Z se lo lleva el salto
        // normal; el vuelo sale con la siguiente pulsacion.
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && !isGrounded && !isAttacking
        && !(variable_instance_exists(id, "coyoteTimer") && coyoteTimer > 0 && yspd >= 0))
        {
                if(!isFlying && flyTimer <= -ROUGE_FLY_RECHARGE)
                {
                        audio_play_sound(snd_tails_fly, 0, false);
                        net_sound_emit(snd_tails_fly);

                        flyTimer = ROUGE_FLY_TIME;
                        flyElapsed = 0;
                        flyGrv = -1;
                        isFlying = true;
                        isJumping = false;
                        isSpinning = false;
                }

                // patron Tails: cada pulsacion re-impulza mientras quede
                // presupuesto; sin presupuesto, la pulsacion lo corta
                if(isFlying)
                {
                        if(flyTimer > 0)
                                flyGrv = -1;
                        else
                                isFlying = false;

                        isJumping = false;
                }
        }

        // PATADA (tecla X): en tierra Y en el aire (a diferencia de la
        // Sally vanilla, que solo la tiene aerea). El golpe aturde al
        // bando EXE 3 s por contacto: lo aplica el cliente de la victima
        // con el bit PLAYER_ATTACKING (patron Knuckles/Sally/Metal).
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                attackTimer = ROUGE_ATTACK_RECHARGE;
                isAttacking = true;
                isFlying = false; // v4.6: pegar manda (corta el vuelo)
                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
        }

        if(isAttacking)
        {
                // la patada corta el vuelo (patron Knux: pegar manda)
                if(isFlying)
                        isFlying = false;

                gspd = 0;
                xspd = image_xscale * (isGrounded ? .5 : 2);
        }

        // el dano corta el vuelo (el suelo lo corta el bloque de
        // aterrizaje de abajo, que ademas resetea el presupuesto —
        // exactamente el patron de Tails)
        if(isHurt)
                isFlying = false;

        // ---------------- vuelo activo ----------------
        if(isFlying)
        {
                isSpinning = false;
                isJumping = false;

                // patron Tails: la gravedad del vuelo decae de -1 (impulso)
                // hasta +2 (cada suave); cada Z la re-arma a -1
                if(flyGrv < 2)
                        flyGrv += 0.035;

                // presupuesto: cuenta desde que despega; al agotarse, caida
                // normal (la gravedad de scr_collision_basic hace el resto)
                if(!isGrounded && flyTimer > 0)
                {
                        flyElapsed++;
                        flyTimer = max(0, ROUGE_FLY_TIME - flyElapsed);
                }

                if(flyTimer <= 0)
                        isFlying = false;

                yspd = flyGrv;

                // tira direccional de 5 frames (la del antiguo planeo, con
                // las alas extendidas): frame segun la velocidad horizontal
                // real (0=derecha rapida, 1=derecha, 2=quiebre frontal,
                // 3=izquierda, 4=izquierda rapida). xscale fijo a 1 porque
                // los frames ya traen la direccion (case ROUGE_GLIDE).
                if(xspd > 2)
                        image_index = 0;
                else if(xspd > 0.5)
                        image_index = 1;
                else if(xspd > -0.5)
                        image_index = 2;
                else if(xspd > -2)
                        image_index = 3;
                else
                        image_index = 4;
        }

        // aleteo audible mientras queda presupuesto (patron Tails)
        if(flyTimer > 0 && flyTimer mod 18 == 0)
        {
                audio_play_sound(snd_tails_fly, 0, false);
                net_sound_emit(snd_tails_fly);
        }

        // ---------------- aterrizaje / recarga (patron Tails) ----------------
        if(isGrounded)
        {
                if(isFlying)
                {
                        isFlying = false;
                        flyTimer = 0;
                }

                if(flyTimer > -ROUGE_FLY_RECHARGE)
                        flyTimer--;
        }
        else
                if(flyTimer > 0)
                        flyTimer--;

        if(attackTimer > 0)
                attackTimer--;
}
