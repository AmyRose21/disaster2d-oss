// v11 (NEGAGEN, 3 FORMAS): 1 normal / 2 NEGA / 3 demonizada.
// El subdito NEGATIVO usa la TIRA NEGA propia del personaje
// (spr_<char>nega_*: inversion pura de SUS sprites, mismo canon
// que los spr_amynega_* / spr_eggnega_* del build Negagen).
// El esbirro comun sigue con sus eanims; el superviviente igual.
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;
sprite_index = arr[? CHARACTER_FLEETWAY_AMY][state];

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

	case FW_ATTACK:
	case FW_ATTACK2:
		// Puño (attack1) y patada (attack2): 4 frames cada uno, rápido
		image_speed = 0.5;

		if(image_index >= image_number - 1)
			isAttacking = false;
		break;

	case FW_DJ:
		// Pose del DJ (1 frame): sin animación, solo la postura de vuelo
		image_speed = 0;
		image_index = 0;
		break;

	case FW_CB_IDLE:
	case FW_CB_WALK:
	case FW_CB_RUN:
		// Con la ballesta en la mano: mismos ritmos que sin ella.
		// v4.10: la idle de la ballesta tiene 3 frames y ANIMA
		// (antes se fijaba image_index = 0 cada frame y quedaba
		// congelada en el primero: "quieta no hace la animacion
		// de cbamy"). Ahora corre igual que la IDLE normal.
		if(state == FW_CB_WALK)
			image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
		else if(state == FW_CB_RUN)
			image_speed = max(abs(xspd) / 20, 0.5);
		else
			image_speed = 1;
		break;

	case EMOTION1:
	case EMOTION2:
	case EMOTION3:
		image_speed = 1;
		break;
}
