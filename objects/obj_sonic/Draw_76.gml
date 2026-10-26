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
                
        // EL GOLPE (tecla X): la animacion del ataque termina sola el
        // golpe; al llegar al ultimo frame se apaga isAttacking.
        case SONIC_ATTACK:
                image_speed = SONIC_ATTACK_ANIMSPD;

                if(image_index >= image_number - 1)
                        isAttacking = false;
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
