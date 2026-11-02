switch(state)
{
	case IDLE:
		// El idle canon son 121 frames: intro (0-90) y un gesto
		// final fluido (91-120) que TERMINA en la pose de reposo
		// (frame 120). El loop entra despues del 120: la animacion
		// se ve entera una vez y se queda quieta en la pose final,
		// sin repetir el gesto del final en circulo. (El -14 venia
		// de la Sally original: su idle de 90 frames tiene la
		// respiracion justo en las ultimas 14; en el canon ese corte
		// pillaba el gesto a medias y lo rebotaba sin parar.)
		image_index = image_number - 1;
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
			image_index = 0;
		else
		{
			image_index = 0;
			state = IDLE;
			emotion = false;
		}
		break;
}