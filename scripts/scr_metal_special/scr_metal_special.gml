// =====================================================================
//  METAL SONIC (v2.2, rescatado de TD2D Through the Blood).
//  Ofensivo con dos habilidades (descripcion original del mod):
//   * DASH (tecla X): embestida a maxima velocidad hasta por 10
//     segundos o hasta chocar contra un objeto; aturde al killer 3 s
//     al tocarlo (via isAttacking, el mismo canal del escudo de
//     Eggman: el stun lo aplica el cliente del killer en
//     obj_player_puppet). Recarga 40 s.
//   * ELECTRO (tecla C): electrificado 1 segundo; cualquier killer
//     que lo toque queda aturdido 3 s (el golpe electrico lo pone el
//     cliente del killer: caso METAL en obj_player_puppet, con
//     spr_shockparticle + snd_metal_electro). Recarga 30 s.
//  Stats: carrera de superviviente estandar (11); como robot que es,
//  arranca un pelin mas pesado (acc 0.040). El dash es su velocidad
//  real (16, ver METAL_DASH_SPEED): ahi si supera a los EXE.
//  v2.2.4: antes corria a 13 con acc 0.4 — mas rapido que los EXE
//  (12) y acelerando 8.5x mas que un superviviente normal (0.046875):
//  llegaba al tope en 3 frames, por eso se sentia descontrolado.
//  Valores canonicos del 110v: survivors 11 / EXE 12.
// =====================================================================
#macro METAL_MAXSPEED 11
#macro METAL_ACC 0.040
#macro METAL_DASH_RECHARGE (60 * 40)
#macro EMETAL_DASH_RECHARGE (60 * 15)
#macro METAL_DASH_MAX (60 * 10)      // duracion maxima del dash (10 s)
#macro METAL_DASH_SPEED 16
#macro METAL_ELECTRO_RECHARGE (60 * 30)
#macro EMETAL_ELECTRO_RECHARGE (60 * 12)
#macro METAL_ELECTRO_TIME 60         // 1 s electrificado

function scr_metal_special()
{
        // Red ring / esconderse: cooldowns al minimo y sin atacar
        if(redRingTimer > 0 || isHiding)
        {
                if(dashTimer <= 60 * 2)
                        dashTimer = 60 * 2;

                if(electroTimer <= 60 * 2)
                        electroTimer = 60 * 2;

                isAttacking = false;
                metalDashing = 0;
        }

        // ---- DASH (tecla X) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && dashTimer <= 0 && !metalDashing && !isElectro && isGrounded)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                metalDashing = METAL_DASH_MAX;
                isAttacking = true;
                isSpinning = false;
                image_index = 0;

                audio_play_sound(snd_metal_dash, 0, false);
                net_sound_emit(snd_metal_dash);
        }

        if(metalDashing > 0)
        {
                // mantener X: sigue el dash; soltarla lo corta
                if(!global.playerControls || !keyboard_check(global.KeyB) || isHurt || isDead || shockedTimer > 0)
                        metalDashing = 1; // cortar en el siguiente bloque

                // velocidad constante en la direccion del dash
                maxHSpeed = METAL_DASH_SPEED;
                xspd = METAL_DASH_SPEED * image_xscale;
                gspd = xspd;
                acc = 1;

                // estela
                if(floor(x) mod 3 == 0)
                        net_quick_effect(x - 10 * image_xscale, y, spr_dust);

                // choque contra pared: corta el dash
                if(place_meeting(x + 4 * image_xscale, y, obj_floor_parent) || place_meeting(x - 4 * image_xscale, y, obj_floor_parent))
                        metalDashing = 1;

                metalDashing--;

                if(metalDashing <= 0)
                {
                        isAttacking = false;
                        dashTimer = revivalTimes >= 2 ? EMETAL_DASH_RECHARGE : METAL_DASH_RECHARGE;
                }
        }
        else
        {
                if(isSlow)
                {
                        maxHSpeed = (METAL_MAXSPEED * (100-30)) / 100;
                        acc = (METAL_ACC * (100-30)) / 100;
                }
                else
                {
                        maxHSpeed = METAL_MAXSPEED;
                        acc = METAL_ACC;
                }
        }

        // ---- ELECTRO (tecla C) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && electroTimer <= 0 && metalDashing <= 0)
        {
                isElectro = METAL_ELECTRO_TIME;
                isAttacking = true;
                image_index = 0;

                audio_play_sound(snd_metal_electro, 0, false);
                net_sound_emit(snd_metal_electro);

                net_quick_effect(x, y, spr_shockparticle);
        }

        if(isElectro > 0)
        {
                isElectro--;

                // chispas alrededor mientras dura
                if(isElectro mod 8 == 0)
                        net_quick_effect(x + random_range(-14, 14), y + random_range(-20, 4), spr_shockparticle);

                if(isElectro <= 0 || isHurt || isDead || shockedTimer > 0)
                {
                        isElectro = 0;

                        if(metalDashing <= 0)
                                isAttacking = false;

                        electroTimer = revivalTimes >= 2 ? EMETAL_ELECTRO_RECHARGE : METAL_ELECTRO_RECHARGE;
                }
        }

        if(dashTimer > 0)
                dashTimer--;

        if(electroTimer > 0)
                electroTimer--;
}
