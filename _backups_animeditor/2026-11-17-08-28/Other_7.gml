switch(state)
{
	// Kris: idle de 3 frames — la pose de salida de la emocion es el
	// frame 0 (los "image_number - 4/70" de Knux/Tails dependen del
	// largo de SU tira; el idle de Kris es corto)
	case IDLE:
	case BALANCING:
		image_index = 0;
		break;

	case EMOTION1:
		if(keyboard_check(global.KeyEm1))
			image_index = 2;
		else
		{
			image_index = 0;
			state = IDLE;
			emotion = false;
		}
		break;

	case EMOTION2:
		if(keyboard_check(global.KeyEm2))
			image_index = 0;
		else
		{
			image_index = 0;
			state = IDLE;
			emotion = false;
		}
		break;

	case EMOTION3:
		if(keyboard_check(global.KeyEm3))
			image_index = 2;
		else
		{
			image_index = 0;
			state = IDLE;
			emotion = false;
		}
		break;

	case JUMP:
		image_index = image_number - 1;
		break;
	
	case HURT:
		image_index = image_number - 1;
		break;
	}