// v11 (NEGAGEN, 3 FORMAS): 1 normal / 2 NEGA / 3 demonizada.
// El subdito NEGATIVO usa la TIRA NEGA propia del personaje
// (spr_<char>nega_*: inversion pura de SUS sprites, mismo canon
// que los spr_amynega_* / spr_eggnega_* del build Negagen).
// El esbirro comun sigue con sus eanims; el superviviente igual.
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;
sprite_index = arr[? CHARACTER_CREAM][state];

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
		
	case FALL:
		image_index = yspd > 0 ? 1 : 0;
		break;
		
	case WALK:
		image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
		break;
		
	case RUN:
	case JUMP:
		image_speed = max(abs(xspd) / 20, 0.5);
		break;
		
	case DEAD:
		// v20 (NEGA): la tira DEAD del subdito negativo hace de
		// animacion de STUN (el slot 6 del mirror nega copio el
		// dead del superviviente): UNA pasada y se queda en el
		// ultimo frame, no en bucle como el stun del esbirro demon.
		if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
		{
			image_speed = 0.5;

			if(image_index >= image_number - 1)
			image_index = image_number - 1;

			break;
		}

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
		
	case CREAM_FLY:
		image_speed = 0.3;
		break;
		
	case CREAM_SPAWN:
		image_speed = 0.5;
		
		if(image_index >= image_number - 1)
			image_index = image_number - 1;
		break;
		
	case EMOTION1:
	case EMOTION2:
	case EMOTION3:
		image_speed = 1;		
		break;
}