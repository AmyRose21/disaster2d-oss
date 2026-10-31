// =====================================================================
//  METAL AMY (v2.2, killer rescatado de TD2D Through the Blood).
//  Kit reconstruido de los assets del mod (net_metal_amy_shoot,
//  obj_metal_amy_bullet, spr_metalamy_attack11/22, spr_metalamy_lazer):
//   * GOLPE (tecla X): ataque cuerpo a cuerpo estandar de killer
//     (mismo patron que Exeller: en tierra 1 s de recovery, en el
//     aire 2 s).
//   * BALA (tecla C): disparo del canon del pecho: proyectil recto
//     que hace 20 de dano al sobreviviente que toque (mismo modelo
//     que el laser exe de Tails: lo tick-ea el server, el dano lo
//     aplica el cliente de la victima y el parry de Sonic puede
//     desviarlo). Recarga 8 s.
//  Stats: identicos a Exeller (12 / 0.056875).
// =====================================================================
#macro METALAMY_BULLET_RECHARGE (60 * 8)
#macro METALAMY_MAXSPEED 12
#macro METALAMY_ACC 0.056875

function scr_metalamy_special()
{
        if(won || lost)
        {
                isAttacking = false;
                attackTimer = 0;
        }

        // cancelar el salto en el aire (patron killers)
        if(global.playerControls && isJumping && keyboard_check_pressed(global.KeyA))
                isJumping = false;

        // ---- GOLPE (tecla X): patron Exeller ----
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && invisTimer <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                attackSpeed = xspd;
                attackTimer = isGrounded ?  60 : 120;
                isAttacking = true;
                isJumping = false;
                isSpinning = false;

                audio_play_sound(snd_metalamy_dash, 0, false);
                net_sound_emit(snd_metalamy_dash);
        }

        if(isAttacking)
        {
                if(yspd > 0)
                        yspd = isGrounded ? 0 : 2.5;

                if(isGrounded && abs(xspd) > 0 && floor(x) mod 4 == 0)
                        net_quick_effect(x - 8 * sign(image_xscale), y + 20, spr_dust);
        }

        // ---- BALA (tecla C): patron laser de Tails lado exe ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && attackTimer <= 0 && bulletTimer <= 0 && invisTimer <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                isJumping = false;

                audio_play_sound(snd_metal_lazer, 0, false);
                net_sound_emit(snd_metal_lazer);

                // spawn local inmediato + aviso al server
                net_metalamy_bullet(x + 14 * image_xscale, y - 6, image_xscale);

                scr_camera_shake(15, 0.8, 0.1);
                bulletTimer = METALAMY_BULLET_RECHARGE;

                // pose de disparo un instante
                shootPose = 24;
        }

        // timers
        if(attackTimer > 0)
                attackTimer--;

        if(bulletTimer > 0)
                bulletTimer--;

        if(shootPose > 0)
                shootPose--;
}
