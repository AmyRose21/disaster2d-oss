var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_SONIC][state];

switch(state)
{
        case IDLE:
                image_speed = 1;
                break;
                
        case HURT:
                image_speed = 0;
                image_index = 0;
                break;
                
        case BALANCING:
                image_xscale = edgeDir;
                image_speed = 1;
                break;
                
        case WALK:
                image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
                break;
                
        case FALL:
                image_index = 0;
                break;
                
        case RUN:
                image_speed = max(abs(xspd) / 20, 0.5);
                break;
                
        // PASIVA SPIN: el salto de Sonic es giratorio (bola). Mientras
        // dura, el contacto con el EXE en salto/rodadura se repelen.
        case JUMP:
                image_speed = 1.1;
                
                if(image_index >= image_number - 1)
                        isJumping = false;
                break;
                
        case DEAD:
                if(revivalTimes >= 2)
                {
                        image_speed = 0.5;
                        break;
                }
                
                if(isGrounded)
                        image_speed = 1;
                else
                        image_speed = 0;
                
                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;
                
        case LOOKUP:
        case LOOKDOWN:
                image_speed = 1;
                
                // Stop on last frame
                if(image_index >= 1)
                        image_index = 1;
                        
                break;
                
        case SPIN:
                image_speed = abs(xspd) / 5;
                break;
                
        // EL GOLPE (tecla X): 3 variantes (tierra 1 / tierra 2 / aire).
        // La animacion termina sola el golpe; al llegar al ultimo frame
        // se apaga isAttacking. La variante la fijo scr_sonic_special.
        case SONIC_ATTACK:
        case SONIC_ATTACK_TIERRA2:
        case SONIC_ATTACK_AIRE:
                image_speed = SONIC_ATTACK_ANIMSPD;

                if(image_index >= image_number - 1)
                        isAttacking = false;
                break;
                
        // NERVIOS DE ACERO: tirado en el suelo. Una sola pasada lenta en
        // los 3 segundos de espera y se queda clavado en el ultimo frame.
        case SONIC_NERVIOS:
                image_speed = 0.03;

                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;
                
        // NERVIOS DE ACERO: levantandose. El paso a powerboost lo corta
        // el timer del Step (SONIC_NERVIOS_FINISH_TIME), no la animacion.
        case SONIC_NERVIOS_FINISH:
                image_speed = 0.15;
                break;
                
        // SPINDASH: carga de la bola. Mientras mas carga tiene, mas
        // rapido gira la animacion (efecto de revolucadas).
        case SONIC_SPINDASH:
                image_speed = 0.5 + (spinCharge * 0.15);
                break;
                
        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;                
                break;
}
