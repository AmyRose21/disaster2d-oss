// =====================================================================
//  AMELIA (v2.4, rescatada de TD2D Through the Blood).
//  Kit corregido al del TD original: Amelia usa SOLO TRAMPAS.
//  (v2.4: el VUELO de v2.2 se elimina y NO se sustituye por ninguna
//  habilidad de velocidad — pedido del usuario tras ver el bug de
//  velocidad: la activacion con la tecla de salto y el isBoosting
//  compartido de las botas de los Kafmonitors provocaba carrera
//  forzada incontrolable. Desde v2.4 isBoosting es exclusivo de las
//  botas, que funcionan para Amelia igual que para los demas.)
//   * TRAMPOLIN (tecla X, mirando abajo en el suelo): SIN CAMBIOS
//     desde v2.2. Resorte colocable: quien lo pise (killer incluido)
//     sale disparado hacia arriba en su propio cliente (la fisica del
//     resorte es la del juego, 100% local). Dura 12 s y se usa una
//     vez. Recarga 25 s.
//   * TRAMPA (tecla C en el suelo): planta una trampa (spr_trap) que
//     dura hasta 60 s (la retira el server) o hasta que la pisa
//     alguien del lado del EXE: STUN de 3 s + debuff de velocidad
//     (-40%) otros 3.5 s al salir del stun (stun y slow los aplica
//     el cliente de la victima sobre su propio jugador; el resto
//     solo ve el efecto y escucha el sonido). Recarga 35 s. Maximo
//     1 viva por Amelia (lo lleva el server).
//   * SPINDASH (abajo + Z repetido, parada; v2.6): la habilidad
//     firma de la fila 1 de su placa del TTB. Porte del de Sonic:
//     revolucadas con tono creciente y polvo, al soltar ABAJO sale
//     disparada en bola (estado SPIN) a (8 + carga) px/frame; la bola
//     rueda por encima de la carrera con tope 18 (clamp de
//     scr_collision_basic). Sin cooldown: el coste es el tiempo de
//     revolucioneo. (La pasiva SPINNING del pie de su placa ya estaba:
//     canSpin = true desde v2.2.)
//  Stats: equilibrada (11) con la aceleracion canonica de
//  superviviente del 110v (v2.2.4), salto estandar, con spindash.
// =====================================================================
#macro AMELIA_MAXSPEED 11
#macro AMELIA_ACC 0.046875
#macro AMELIA_BANANA_RECHARGE (60 * 25)
#macro EAMELIA_BANANA_RECHARGE (60 * 10)
#macro AMELIA_TRAP_RECHARGE (60 * 35)
#macro EAMELIA_TRAP_RECHARGE (60 * 15)

// v2.6 (SPINDASH, la habilidad firma de la fila 1 de su placa TTB):
// valores 1:1 con los de Sonic (misma movilidad y stats de placa).
#macro AMELIA_SPINDASH_BASE 8
#macro AMELIA_SPINDASH_REV 2
#macro AMELIA_SPINDASH_CHARGE_MAX 10
#macro AMELIA_SPINDASH_DECAY 90
#macro AMELIA_SPINDASH_PITCH_STEP 0.8
#macro AMELIA_SPINDASH_DUST_EVERY 10
#macro AMELIA_SPINDASH_BURST_MIN 3
#macro AMELIA_SPINDASH_BURST_MAX 8
#macro AMELIA_ROLL_SPEED_CAP 18

function scr_amelia_special()
{
        // Red ring / esconderse: corta todo (tambien la carga v2.6)
        if(redRingTimer > 0 || isHiding)
        {
                if(bananaTimer <= 60 * 2)
                        bananaTimer = 60 * 2;

                if(trapTimer <= 60 * 2)
                        trapTimer = 60 * 2;

                if(isSpinCharging)
                {
                        isSpinCharging = false;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);
                }
        }

        // Stats de base respetando el slow de la trampa (patron
        // scr_metal_special). Sin boost propio desde v2.4: mientras
        // lleva botas (isBoosting) scr_move_basic retorna antes de
        // llamar a specialFunc, asi que aqui nunca se pisa el boost
        // de los Kafmonitors.
        if(isSlow)
        {
                maxHSpeed = (AMELIA_MAXSPEED * (100-40)) / 100;
                acc = (AMELIA_ACC * (100-40)) / 100;
        }
        else
        {
                maxHSpeed = AMELIA_MAXSPEED;
                acc = AMELIA_ACC;
        }

        // ---- TRAMPOLIN (tecla X, mirando abajo, en el suelo) ----
        // Patron del tracker de Eggman: se pide al server, que la
        // spawnea como entidad y la reenvia a TODOS los clientes.
        var _xx = image_xscale > 0 ? 12 : -12;
        isColliding = isGrounded && !place_meeting(x, y, obj_angleanuller) && position_meeting(x + _xx, y + 18, obj_floor_parent);

        if(global.playerControls && keyboard_check_pressed(global.KeyB) && bananaTimer <= 0 && !isSpinCharging && isLookingDown && isColliding)
        {
                audio_play_sound(snd_amelia_banana_spawn, 0, false);
                net_sound_emit(snd_amelia_banana_spawn);

                net_amelia_banana(x + _xx, y + 18);

                bananaTimer = revivalTimes >= 2 ? EAMELIA_BANANA_RECHARGE : AMELIA_BANANA_RECHARGE;
        }

        // ---- TRAMPA (tecla C en el suelo) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && trapTimer <= 0 && !isSpinCharging && isColliding)
        {
                audio_play_sound(snd_amelia_trap, 0, false);
                net_sound_emit(snd_amelia_trap);

                net_amelia_trap(x + _xx, y + 18);

                trapTimer = revivalTimes >= 2 ? EAMELIA_TRAP_RECHARGE : AMELIA_TRAP_RECHARGE;
        }

        // ---- SPINDASH (abajo + Z repetido; soltar abajo lanza) ----
        // v2.6: porte del de Sonic (sin drop dash: su placa solo lista
        // SPINDASH). UN solo camino para la 1a pulsacion y las
        // siguientes: este bloque se re-dispara con cada Z porque la
        // carga mantiene gspd == 0.
        if(global.playerControls && isGrounded && !isAttacking && !isHurt
        && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
        && redRingTimer <= 0
        && keyboard_check(global.KeyDown) && gspd == 0 && keyboard_check_pressed(global.KeyA))
        {
                isSpinCharging = true;
                spinCharge = min(spinCharge + AMELIA_SPINDASH_REV, AMELIA_SPINDASH_CHARGE_MAX);
                spinChargeDecay = 0;
                spinDustTimer = 0;
                image_index = 0;

                // cada revolucada suena MAS aguda (1.0 -> 1.8 con la
                // bola llena) y patea polvo detras (por red). El tono
                // solo lo oye la local: el paquete de sonido del
                // protocolo no lleva pitch.
                if(spinRevSnd != -1)
                        audio_stop_sound(spinRevSnd);
                spinRevSnd = audio_play_sound(snd_spin, 0, false);
                audio_sound_pitch(spinRevSnd, 1.0 + (spinCharge / AMELIA_SPINDASH_CHARGE_MAX) * AMELIA_SPINDASH_PITCH_STEP);
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
                if(spinChargeDecay >= AMELIA_SPINDASH_DECAY)
                {
                        spinChargeDecay = 0;
                        spinCharge = max(0, spinCharge - 1);
                }

                // polvo ambiente detras mientras carga (solo local)
                spinDustTimer++;

                if(spinDustTimer >= AMELIA_SPINDASH_DUST_EVERY)
                {
                        spinDustTimer = 0;
                        scr_effect_quick(x - image_xscale * (10 + irandom(4)), y + 14 + irandom(3), spr_dust, 0.4, false, -image_xscale, -0.5);
                }

                // Cancelaciones: dano, stun, muerte, tirolina, perder el
                // suelo, anillo rojo o esconderse.
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
                        gspd = (AMELIA_SPINDASH_BASE + _chg) * image_xscale;
                        spinCharge = 0;

                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);

                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);

                        // polvareda de salida detras (3 nubes sin carga
                        // -> 8 con la bola llena), por red
                        var _burst = AMELIA_SPINDASH_BURST_MIN + floor(_chg / AMELIA_SPINDASH_CHARGE_MAX * (AMELIA_SPINDASH_BURST_MAX - AMELIA_SPINDASH_BURST_MIN));

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

        // timers
        if(bananaTimer > 0)
                bananaTimer--;

        if(trapTimer > 0)
                trapTimer--;
}
