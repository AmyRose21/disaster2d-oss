switch(result)
{
	case 0:
		// Nadie escapo (gana el EXE): bad ending vanilla, igual que siempre
		scr_play_music(mus_exewin);
		break;
		
	case 1:
		// ENDINGS POR CANTIDAD DE ESCAPADOS (estilo TD original).
		// mus_survwin (vanilla) queda INACTIVO: solo suena como red de seguridad
		// en el caso imposible de "ganan los survivors pero nadie escapo".
		//
		// Reglas:
		//   * TODOS escaparon ............ Best_ending / Best_ending_Alt (aleatorio)
		//   * escapa solo 1 .............. Solo_ending / Solo_ending_Alt (aleatorio)
		//   * escapan exactamente 2 ...... Duo_ending
		//   * escapan mas de 2 (no todos)  Standard_Ending / Standard_Ending_Alt (aleatorio)
		//
		// Nota: en partidas de 2 survivors donde ambos escapan suena Best
		// ("escaparon todos"). Si prefieres que ese caso suene Duo, mueve el
		// bloque "escapedCnt == 2" ANTES del bloque "escapedCnt >= survTotal".
		if(escapedCnt == 0)
		{
			scr_play_music(mus_survwin); // red de seguridad (no deberia pasar)
			break;
		}
		
		/* >>[endings v2]<< Variante sincronizada: la eleccion base/Alt ya no es
		 * aleatoria por cliente, se deriva de (segundos de ronda + escapados),
		 * datos que todos comparten. Asi TODOS los clientes oyen la misma pista
		 * y el servidor (states/Results.c: results_music_countdown) espera
		 * exactamente la duracion de esa pista antes de volver al lobby. */
		var _alt = (timeSec + escapedCnt) % 2;
		
		if(escapedCnt >= survTotal)
		{
			// escaparon todos: Best ending
			scr_play_music(_alt ? Best_ending : Best_ending_Alt);
		}
		else if(escapedCnt == 1)
		{
			// solo escapo 1: Solo ending
			scr_play_music(_alt ? Solo_ending : Solo_ending_Alt);
		}
		else if(escapedCnt == 2)
		{
			// escapo el duo: Duo ending
			scr_play_music(Duo_ending);
		}
		else
		{
			// escapo mas de 2 pero no todos: Standard ending
			scr_play_music(_alt ? Standard_Ending : Standard_Ending_Alt);
		}
		break;
		
	case 2:
		scr_play_music(mus_timeover);
		break;
}
