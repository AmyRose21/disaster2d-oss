sprite_index = global.player_exesanims[? EXE_JINNA][state];
switch(state)
{
        case IDLE:
                image_speed = 1;
                break;

        case HURT:
        case JINNA_ZIPLINE:
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

        case JINNA_ATTACK1:   // golpe en tierra: attack1 (5 frames)
        case JINNA_ATTACK2:   // golpe aereo / pose de agarre: attack2 (6 frames)
                image_speed = 0.3;

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

        case JINNA_SHOCKED:
                image_speed = 0.5;
                break;

        case JINNA_LOST:
        case JINNA_LOST2:
        case JINNA_WON:
                image_speed = 0.8;
                break;

        case JINNA_TELE:
                // pose de teletransporte: fija (1 frame) mientras dura
                image_speed = 0;
                image_index = 0;
                break;

        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 0.8;
                break;
}
