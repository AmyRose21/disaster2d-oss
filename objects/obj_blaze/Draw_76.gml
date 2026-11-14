// v11 (NEGAGEN, 3 FORMAS): 1 normal / 2 NEGA / 3 demonizada.
// El subdito NEGATIVO usa la TIRA NEGA propia del personaje
// (spr_<char>nega_*: inversion pura de SUS sprites, mismo canon
// que los spr_amynega_* / spr_eggnega_* del build Negagen).
// El esbirro comun sigue con sus eanims; el superviviente igual.
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;
sprite_index = arr[? CHARACTER_BLAZE][state];

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
		// (MUELLES): frames de subida/bajada configurados con la
		// Suite (global.fallAnims en scr_survivors.gml)
		scr_fall_anim();
		break;

	case WALK:
		image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
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
	case BLAZE_SHOOT:
		image_speed = 1;

		if(image_index >= image_number - 1)
			image_index = image_number - 1;
		break;

	case BLAZE_BURNING:
		image_speed = 0.7;
		break;

	// v20 (NEGA): la tira DEAD del subdito negativo hace de
	// animacion de STUN (el slot 6 del mirror nega copio el
	// dead del superviviente): UNA pasada y se queda en el
	// ultimo frame. Estos tres (TTB) no tenian case DEAD:
	// el esbirro demon heredaba la velocidad anterior — el
	// break en seco conserva exactamente ese comportamiento.
	case DEAD:
		if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
		{
			image_speed = 0.5;

			if(image_index >= image_number - 1)
				image_index = image_number - 1;

			break;
		}
		break;
}
