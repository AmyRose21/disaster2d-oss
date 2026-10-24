var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_AMY_CANON][state];

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
                
        case AMY_CANON_ATTACK:
                image_speed = 0.3;

                if(image_index >= image_number - 1)
                        isAttacking = false;
                break;
                
        // ATAQUE 3: acometida de martillo. La animacion corre en LOOP
        // a la velocidad AMY_CANON_DASH_ANIMSPD (ajustable en Create_0.gml).
        // El fin de la acometida lo controla dashTimeLeft en
        // scr_amy_canon_special.gml, no la animacion.
        case AMY_CANON_DASH:
                image_speed = AMY_CANON_DASH_ANIMSPD;
                
                if(!isDashing)
                        isAttacking = false;
                break;
                
        // ESTADO BURBUJA (secuestro): sprites de 1 frame; la variante
        // (frente/izquierda/derecha) la elige Step_2 segun bubbleDir.
        case AMY_CANON_CAPTURE:
        case AMY_CANON_CAPTURE_L:
        case AMY_CANON_CAPTURE_R:
                image_speed = 0;
                image_index = 0;
                break;
                
        case AMY_CANON_HJUMP:
                image_speed = 0.3;
                
                if(image_index >= image_number - 1)
                        isHJ = false;
                break;
                
        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;                
                break;
}