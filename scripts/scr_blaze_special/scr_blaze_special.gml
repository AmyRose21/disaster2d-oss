// =====================================================================
//  BLAZE (v2.2, rescatada de TD2D Through the Blood).
//  Tres habilidades (reconstruidas de los assets del mod: net_blaze_
//  shoot_fireball + spr_blaze_fireball, "burning blaze" en los
//  strings, spr_blaze_skak/snd_blaze_skak para su salto):
//   * SALTO DE FUEGO (tecla Z en el aire): doble salto con impulso de
//     llamas (patron jetpack de Eggman). Recarga 12 s.
//   * BOLA DE FUEGO (tecla X): proyectil de fuego horizontal que
//     aturde al killer 2 s al tocarlo (mismo modelo que el laser de
//     Tails: el server lo tick-ea y lo reenvia; el stun lo aplica el
//     cliente del killer al ser tocado; el aliado Sonic puede
//     parrear el reflejo). Recarga 23 s.
//   * BLAZE ARDIENTE (tecla C): 1.5 s envuelta en fuego, +30% de
//     velocidad y cualquier killer que la toque queda aturdido 3 s
//     (canal isAttacking; el golpe de fuego lo pone el cliente del
//     killer: caso BLAZE en obj_player_puppet). Recarga 30 s.
//  Stats: rapida (12.5), salto alto (7.5).
// =====================================================================
#macro BLAZE_MAXSPEED 12.5
#macro BLAZE_ACC 0.42
#macro BLAZE_DJUMP_RECHARGE (60 * 12)
#macro EBLAZE_DJUMP_RECHARGE (60 * 6)
// TTB (placa del mod): FIRE BALL 9 SEC
#macro BLAZE_FIREBALL_RECHARGE (60 * 9)
#macro EBLAZE_FIREBALL_RECHARGE (60 * 4)
#macro BLAZE_BURNING_RECHARGE (60 * 30)
#macro EBLAZE_BURNING_RECHARGE (60 * 12)
#macro BLAZE_BURNING_TIME (60 * 1.5)

function scr_blaze_special()
{
        // Red ring / esconderse
        if(redRingTimer > 0 || isHiding)
        {
                if(djumpRecharge <= 60 * 2)
                        djumpRecharge = 60 * 2;

                if(fireballTimer <= 60 * 2)
                        fireballTimer = 60 * 2;

                if(burningTimer <= 60 * 2)
                        burningTimer = 60 * 2;

                isAttacking = false;
                burning = 0;
        }

        // ---- SALTO DE FUEGO (tecla Z en el aire) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && isJumping && djumpRecharge == 0)
        {
                isJumping = false;
                yspd = -8;

                audio_play_sound(snd_blaze_skak, 0, false);
                net_sound_emit(snd_blaze_skak);

                net_quick_effect(x, y + 16, spr_dust);

                djumpRecharge = -1;
        }

        // ---- BOLA DE FUEGO (tecla X) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && fireballTimer <= 0 && burning <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;

                audio_play_sound(snd_blaze_shot, 0, false);
                net_sound_emit(snd_blaze_shot);

                // spawn local inmediato + aviso al server (que lo
                // reenvia al resto: ver net_blaze_fireball)
                net_blaze_fireball(x + 14 * image_xscale, y - 4, image_xscale);

                scr_camera_shake(15, 0.8, 0.1);
                fireballTimer = revivalTimes >= 2 ? EBLAZE_FIREBALL_RECHARGE : BLAZE_FIREBALL_RECHARGE;

                // pose de disparo un instante
                shootPose = 24;
        }

        // ---- BLAZE ARDIENTE (tecla C) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && burningTimer <= 0 && burning <= 0)
        {
                burning = BLAZE_BURNING_TIME;
                isAttacking = true;
                image_index = 0;

                audio_play_sound(snd_blaze_go, 0, false);
                net_sound_emit(snd_blaze_go);

                net_quick_effect(x, y, spr_shockparticle);
        }

        if(burning > 0)
        {
                burning--;

                // aura de fuego mientras dura
                if(burning mod 6 == 0)
                        net_quick_effect(x + random_range(-12, 12), y + random_range(-18, 6), spr_shard_sparkle);

                if(burning <= 0 || isHurt || isDead || shockedTimer > 0)
                {
                        burning = 0;
                        isAttacking = false;

                        audio_play_sound(snd_blaze_goon, 0, false);
                        net_sound_emit(snd_blaze_goon);

                        burningTimer = revivalTimes >= 2 ? EBLAZE_BURNING_RECHARGE : BLAZE_BURNING_RECHARGE;
                }
        }

        // velocidad: +30% mientras arde
        if(burning > 0)
        {
                maxHSpeed = BLAZE_MAXSPEED * 1.3;
                acc = BLAZE_ACC * 1.3;
        }
        else if(isSlow)
        {
                maxHSpeed = (BLAZE_MAXSPEED * (100-30)) / 100;
                acc = (BLAZE_ACC * (100-30)) / 100;
        }
        else
        {
                maxHSpeed = BLAZE_MAXSPEED;
                acc = BLAZE_ACC;
        }

        // timers
        if(djumpRecharge < 0)
        {
                djumpRecharge--;

                if(djumpRecharge <= -30)
                        djumpRecharge = BLAZE_DJUMP_RECHARGE;
        }
        else if(djumpRecharge > 0)
                djumpRecharge--;

        if(fireballTimer > 0)
                fireballTimer--;

        if(burningTimer > 0)
                burningTimer--;

        if(shootPose > 0)
                shootPose--;
}
