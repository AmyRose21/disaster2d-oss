// =====================================================================
//  AMELIA (v2.2, rescatada de TD2D Through the Blood).
//  Tres habilidades (reconstruidas de los assets del mod: obj_amelia_
//  banana era un resorte-trampa con parent obj_spring_parent, y
//  obj_amelia_bomb una bomba con mecha de 5 s):
//   * VUELO (tecla Z en el aire, tras saltar): sube manteniendo Z,
//     planea al soltar (patron Vanilla/Tails). Dura 4 s. Recarga 18 s.
//   * BANANA (tecla X, mirando abajo en el suelo): deja caer un
//     RESORTE-trampa en el suelo. Quien lo pise (incluido el killer)
//     sale disparado hacia arriba en su propio cliente (la fisica del
//     resorte es la del juego, 100% local). Dura 12 s y se usa una
//     vez. Recarga 25 s.
//   * BOMBA (tecla C en el suelo): planta una bomba con 5 s de mecha;
//     explota aunque el killer la pise antes (el boom lo dispara el
//     server: mecha o contacto). Aturde 2 s al killer en un radio de
//     90 px (cada cliente se aplica su propio stun; los aliados solo
//     reciben empujon). Recarga 35 s.
//  Stats: equilibrada (11), salto estandar, con spindash.
// =====================================================================
#macro AMELIA_MAXSPEED 11
#macro AMELIA_ACC 0.35
#macro AMELIA_FLY_SOLO (60 * 4)
#macro AMELIA_FLY_RISE -3.5
#macro AMELIA_FLY_GLIDE 1
#macro AMELIA_FLY_RECHARGE (60 * 18)
#macro EAMELIA_FLY_RECHARGE (60 * 8)
#macro AMELIA_BANANA_RECHARGE (60 * 25)
#macro EAMELIA_BANANA_RECHARGE (60 * 10)
#macro AMELIA_BOMB_RECHARGE (60 * 35)
#macro EAMELIA_BOMB_RECHARGE (60 * 15)

function scr_amelia_special()
{
        // Red ring / esconderse: corta todo
        if(redRingTimer > 0 || isHiding)
        {
                if(flyTimer <= 60 * 2)
                        flyTimer = 60 * 2;

                if(bananaTimer <= 60 * 2)
                        bananaTimer = 60 * 2;

                if(bombTimer <= 60 * 2)
                        bombTimer = 60 * 2;

                if(isFlying)
                        isFlying = false;
        }

        // ---- VUELO (tecla Z en el aire) ----
        if(global.playerControls && isJumping && !justJumped && keyboard_check_pressed(global.KeyA) && flyTimer <= 0)
        {
                flyTimeout = 0;
                isFlying = true;
                isJumping = false;
                isSpinning = false;
                flyTimer = AMELIA_FLY_RECHARGE;
        }

        if(isFlying)
        {
                if(global.playerControls && keyboard_check(global.KeyA))
                        yspd = AMELIA_FLY_RISE;
                else
                        yspd = AMELIA_FLY_GLIDE;

                flyTimeout++;

                if(flyTimeout > AMELIA_FLY_SOLO)
                        isFlying = false;

                if(isGrounded)
                        isFlying = false;
        }

        // ---- BANANA (tecla X, mirando abajo, en el suelo) ----
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

        // ---- BOMBA (tecla C en el suelo) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && bombTimer <= 0 && isColliding)
        {
                audio_play_sound(snd_amelia_trap, 0, false);
                net_sound_emit(snd_amelia_trap);

                net_amelia_bomb(x + _xx, y + 18);

                bombTimer = revivalTimes >= 2 ? EAMELIA_BOMB_RECHARGE : AMELIA_BOMB_RECHARGE;
        }

        // timers
        if(!isFlying && flyTimer > 0)
                flyTimer--;

        if(bananaTimer > 0)
                bananaTimer--;

        if(bombTimer > 0)
                bombTimer--;
}
