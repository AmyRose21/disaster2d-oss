var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_VANILLA][state];

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
		// v1.2: LOOP de verdad (antes: frame fijo 0/1, por eso nunca
		// se repetia). La velocidad de la animacion crece con la caida.
		image_speed = 0.15 + min(abs(yspd), 12) * 0.02;
		break;
		
	case WALK:
		image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
		break;
		
	case RUN:
	case JUMP:
		image_speed = max(abs(xspd) / 20, 0.5);
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
		
	case CREAM_FLY:
		image_speed = 0.3;
		break;
		
	case CREAM_SPAWN:
		// v1.2: LOOP (antes: clamp al ultimo frame; con el sprite de
		// 4 frames se congelaba en el 3 casi todo el cast de 60).
		image_speed = 0.2;
		break;
		
	case EMOTION1:
	case EMOTION2:
	case EMOTION3:
		image_speed = 1;		
		break;
}