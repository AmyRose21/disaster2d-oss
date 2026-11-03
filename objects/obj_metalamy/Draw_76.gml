sprite_index = global.player_exesanims[? EXE_METALAMY][state];
switch(state)
{
        case IDLE:
                image_speed = 1;
                break;

        case HURT:
        case METALAMY_ZIPLINE:
                image_speed = 0;
                image_index = 0;
                break;

        case BALANCING:
                image_xscale = edgeDir;
                image_speed = 1;
                break;

        case FALL:
                image_speed = 0.1;
                if(image_index >= image_number - 1)
                        image_index = image_number - 1;

                if(xspd > 0)
                        image_xscale = 1;
                else if(xspd < 0)
                        image_xscale = -1;
                break;

        case WALK:
                image_speed = (abs(xspd) / (maxHSpeed));
                break;

        case RUN:
        case JUMP:
                image_speed = max(abs(xspd) / 20, 0.5);
                break;

        case LOOKUP:
        case LOOKDOWN:
                image_speed = 0.2;

                // Stop on last frame
                if(image_index >= 1)
                        image_index = 1;

                break;

        case SPIN:
                image_speed = abs(xspd) / 5;
                break;

        case METALAMY_ATTACK:      // v4.7: slot 14 reusa attack2 (la vieja attack11 salio del kit)
        case METALAMY_AIR_ATTACK:
                // v4.6/v4.7 (dash): spr_metalamy_attack2 SIEMPRE (4 frames,
                // slot 15; aire y tierra, y al impactar NO cambia): corre
                // despacio para cubrir el impulso, se fija en su ultimo
                // frame y el ataque lo cierra el TIEMPO (attackTimer = 0,5
                // s), no la animacion (la vieja attack22 cerraba por frame).
                image_speed = 0.25;

                if(image_index >= image_number - 1)
                        image_index = image_number - 1;

                if(attackTimer <= 0)
                {
                        xspd = xspd * .7;
                        gspd = gspd * .7;
                        isAttacking = false;
                        isJumping = false;
                }
                break;

        case METALAMY_SHOCKED:
        {
                image_speed = 0.5;
                break;
        }

        case METALAMY_LOST:
        case METALAMY_WON:
                image_speed = 0.8;
                break;

        case METALAMY_LAZER:
                image_speed = 0;
                image_index = 0;
                break;

        case METALAMY_SCAN:
                // v4.7 (scan): spr_metalamy_scan (8 frames): la onda sale y
                // la pose se sostiene lo que dure scanPose (0,8 s), fijada
                // en su ultimo frame (patron de la pose de disparo).
                image_speed = 0.25;

                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;

        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 0.8;
                break;
}
