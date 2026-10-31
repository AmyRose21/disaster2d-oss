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
//  Stats: equilibrada (11) con la aceleracion canonica de
//  superviviente del 110v (v2.2.4), salto estandar, con spindash.
// =====================================================================
#macro AMELIA_MAXSPEED 11
#macro AMELIA_ACC 0.046875
#macro AMELIA_BANANA_RECHARGE (60 * 25)
#macro EAMELIA_BANANA_RECHARGE (60 * 10)
#macro AMELIA_TRAP_RECHARGE (60 * 35)
#macro EAMELIA_TRAP_RECHARGE (60 * 15)

function scr_amelia_special()
{
        // Red ring / esconderse: corta todo
        if(redRingTimer > 0 || isHiding)
        {
                if(bananaTimer <= 60 * 2)
                        bananaTimer = 60 * 2;

                if(trapTimer <= 60 * 2)
                        trapTimer = 60 * 2;
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

        if(global.playerControls && keyboard_check_pressed(global.KeyB) && bananaTimer <= 0 && isLookingDown && isColliding)
        {
                audio_play_sound(snd_amelia_banana_spawn, 0, false);
                net_sound_emit(snd_amelia_banana_spawn);

                net_amelia_banana(x + _xx, y + 18);

                bananaTimer = revivalTimes >= 2 ? EAMELIA_BANANA_RECHARGE : AMELIA_BANANA_RECHARGE;
        }

        // ---- TRAMPA (tecla C en el suelo) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && trapTimer <= 0 && isColliding)
        {
                audio_play_sound(snd_amelia_trap, 0, false);
                net_sound_emit(snd_amelia_trap);

                net_amelia_trap(x + _xx, y + 18);

                trapTimer = revivalTimes >= 2 ? EAMELIA_TRAP_RECHARGE : AMELIA_TRAP_RECHARGE;
        }

        // timers
        if(bananaTimer > 0)
                bananaTimer--;

        if(trapTimer > 0)
                trapTimer--;
}
