// =====================================================================
//  METAL AMY (v2.2, killer rescatado de TD2D Through the Blood).
//  Kit reconstruido de los assets del mod (net_metal_amy_shoot,
//  obj_metal_amy_bullet, spr_metalamy_attack11/22, spr_metalamy_lazer):
//   * DASH (tecla X, v4.6): embestida dirigible en 8 direcciones (patron
//     chaos: en el aire manda la direccion que sujetes con las flechas;
//     en tierra es horizontal, y arriba/diagonal despega). Sustituye al
//     golpe normal. Tres cargas (METALAMY_DASH_MAX), cada una tarda 5 s
//     en recargar (secuencial) y entre uso y uso hay 0,5 s
//     (METALAMY_DASH_GAP = attackTimer). Animacion: SIEMPRE
//     spr_metalamy_attack2 (v4.7: la vieja attack11 salio del kit — al
//     impactar/aterrizar el sprite se mantiene, no cambia).
//     Sonido: snd_metalamy_dash.
//   * BALA (tecla C): disparo del canon del pecho: proyectil recto
//     que hace 20 de dano al sobreviviente que toque (mismo modelo
//     que el laser exe de Tails: lo tick-ea el server, el dano lo
//     aplica el cliente de la victima y el parry de Sonic puede
//     desviarlo). Recarga 8 s.
//   * SCAN (tecla V, v4.7): rastreador — revela la direccion de TODOS
//     los supervivientes (agujas del obj_exe_indicator en su cliente;
//     la aguja normal solo marca al mas cercano / al del anillo rojo)
//     durante METALAMY_SCAN_TIME, con pose propia (spr_metalamy_scan,
//     slot 21) y enfriamiento de 20 s. Cero paquetes: los puppets ya
//     estan sincronizados en su cliente, el scan es solo visual.
//  Stats: identicos a Exeller (12 / 0.056875).
// =====================================================================
#macro METALAMY_BULLET_RECHARGE (60 * 3)
#macro METALAMY_MAXSPEED 13
#macro METALAMY_ACC 0.056875

// v4.6 — DASH (tecla X)
#macro METALAMY_DASH_MAX 3            // cargas maximas
#macro METALAMY_DASH_RECHARGE (60 * 5) // 5 s de recarga POR carga
#macro METALAMY_DASH_GAP (60 * 0.5)   // 0,5 s entre usos (gatea attackTimer)
#macro METALAMY_DASH_BOOST 18         // frames de impulso a velocidad alta
#macro METALAMY_DASH_HSPD 12          // velocidad horizontal (patron chaos)
#macro METALAMY_DASH_VSPD 8           // velocidad vertical (patron chaos)

// v4.7 — SCAN (tecla V): rastreador de supervivientes
#macro METALAMY_SCAN_RECHARGE (60 * 20) // 20 s de enfriamiento
#macro METALAMY_SCAN_TIME (60 * 3)      // 3 s de revelado (patron del tracker: obj_surv_indicator / SERVER_TRACKER_PING)
#macro METALAMY_SCAN_POSE 48            // 0,8 s de pose de escaneo (spr_metalamy_scan, slot 21)

function scr_metalamy_special()
{
        if(won || lost)
        {
                isAttacking = false;
                attackTimer = 0;
                dashBoost = 0;
                scanPose = 0;   // v4.7
                scanTimer = 0;  // v4.7: fin de ronda, fuera el revelado
        }

        // cancelar el salto en el aire (patron killers)
        if(global.playerControls && isJumping && keyboard_check_pressed(global.KeyA))
                isJumping = false;

        // ---- DASH (tecla X, v4.6): embestida dirigible en 8 direcciones ----
        // Requisitos: sin recovery activo (attackTimer = los 0,5 s entre
        // usos), al menos una carga y sin invisibilidad. El patron de
        // direccion es el del dash de chaos: la direccion que sujetes al
        // pulsar decide hacia donde embiste; sin flechas, hacia donde mira.
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && invisTimer <= 0 && dashCharges > 0)
        {
                var _dx = 0;
                var _dy = 0;

                if(keyboard_check(global.KeyLeft))
                        _dx = -1;
                else if(keyboard_check(global.KeyRight))
                        _dx = 1;

                if(keyboard_check(global.KeyUp))
                        _dy = -1;
                else if(keyboard_check(global.KeyDown))
                        _dy = 1;

                // sin direccion: hacia donde mira (patron chaos)
                if(_dx == 0 && _dy == 0)
                        _dx = image_xscale;

                // en tierra no se entra en el suelo: la componente hacia
                // abajo se anula (y una embestida puramente vertical hacia
                // abajo pasa a ser horizontal)
                if(isGrounded && _dy > 0)
                {
                        _dy = 0;

                        if(_dx == 0)
                                _dx = image_xscale;
                }

                dashDirX = _dx;
                dashDirY = _dy;

                if(dashDirX != 0)
                        image_xscale = sign(dashDirX);

                image_index = 0;
                attackSpeed = xspd;
                attackTimer = METALAMY_DASH_GAP;
                isAttacking = true;
                isJumping = false;
                isSpinning = false;

                // v4.6: gasta una carga y arranca el impulso
                dashCharges--;
                dashBoost = METALAMY_DASH_BOOST;

                // embestida ascendente desde tierra: despega YA (patron
                // del salto de scr_move_basic: isGrounded = false + yspd)
                if(isGrounded && dashDirY < 0)
                {
                        isGrounded = false;
                        xspd = dashDirX * METALAMY_DASH_HSPD;
                        yspd = dashDirY * METALAMY_DASH_VSPD;
                }

                audio_play_sound(snd_metalamy_dash, 0, false);
                net_sound_emit(snd_metalamy_dash);
        }

        if(isAttacking)
        {
                // v4.6 — fase de impulso: velocidad dirigida cada frame
                // (patron chaos; pisa la gravedad y la entrada por teclado,
                // que ya corrieron antes en scr_move_basic). En tierra manda
                // gspd para que las pendientes sigan aplicando.
                if(dashBoost > 0)
                {
                        if(isGrounded)
                        {
                                gspd = dashDirX * METALAMY_DASH_HSPD;
                                xspd = gspd * cos(angle);
                                yspd = gspd * -sin(angle);
                        }
                        else
                        {
                                xspd = dashDirX * METALAMY_DASH_HSPD;
                                yspd = dashDirY * METALAMY_DASH_VSPD;
                        }
                }
                else
                {
                        // frenado del dash aereo (patron chaos: deriva suave
                        // mientras expira el attackTimer de 0,5 s)
                        if(!isGrounded)
                        {
                                xspd = dashDirX * 2;
                                yspd = dashDirY * 2;
                        }
                        else if(yspd > 0)
                                yspd = 0;
                }

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

        // ---- SCAN (tecla V, v4.7): rastreador ----
        // Revela la direccion de TODOS los supervivientes durante
        // METALAMY_SCAN_TIME (lo dibuja obj_exe_indicator en este cliente;
        // la aguja normal solo marca al mas cercano o al del anillo rojo).
        // Es puramente visual: los puppets ya viajan sincronizados, asi que
        // NO hace falta ningun paquete nuevo. El sonido es el del rastreador
        // (snd_egg_tracker: ya viajaba por red desde el Eggman, cualquier
        // cliente lo conoce). Sin gateo de invisibilidad: el dash y la bala
        // son ATAQUES, el scan es informacion.
        if(global.playerControls && keyboard_check_pressed(global.KeyV) && scanRecharge <= 0)
        {
                scanTimer = METALAMY_SCAN_TIME;
                scanRecharge = METALAMY_SCAN_RECHARGE;
                scanPose = METALAMY_SCAN_POSE;

                audio_play_sound(snd_egg_tracker, 0, false);
                net_sound_emit(snd_egg_tracker);
        }

        // timers
        if(attackTimer > 0)
                attackTimer--;

        if(bulletTimer > 0)
                bulletTimer--;

        if(shootPose > 0)
                shootPose--;

        // v4.7 — timers del scan
        if(scanTimer > 0)
                scanTimer--;

        if(scanRecharge > 0)
                scanRecharge--;

        if(scanPose > 0)
                scanPose--;

        // v4.6 — impulso del dash (se agota solo; si el ataque se cancela
        // por stun/muelle/etc. simplemente expira sin efecto)
        if(dashBoost > 0)
                dashBoost--;

        // v4.6 — recarga de cargas: UNA cada 5 s (secuencial, patron del
        // contador de rebote de Vanilla), hasta 3. Con las 3 llenas el
        // contador queda a cero para no arrastrar recarga a medias.
        if(dashCharges < METALAMY_DASH_MAX)
        {
                dashRecharge++;

                if(dashRecharge >= METALAMY_DASH_RECHARGE)
                {
                        dashRecharge = 0;
                        dashCharges++;
                }
        }
        else
                dashRecharge = 0;
}
