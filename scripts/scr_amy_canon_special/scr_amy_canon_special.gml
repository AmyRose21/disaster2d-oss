function scr_amy_canon_special()
{
	// =================================================================
	//  ATAQUE 3: ACOMETIDA DE MARTILLO (tecla C)
	//  Amy corre hacia adelante golpeando con el martillo.
	//  Ajusta DURACION / VELOCIDAD / CD en las macros
	//  AMY_CANON_DASH_* del Create_0.gml de obj_amy_canon.
	// =================================================================
	
	// --- Bloqueos (igual que las otras habilidades) ---
	
	// Con el anillo rojo puesto no puede usar la acometida:
	// se cancela y el CD queda congelado en 2 frames.
	if(redRingTimer > 0)
	{
		if(attackTimer <= 2)
			attackTimer = 2;
		
		if(hjumpTimer <= 2)
			hjumpTimer = 2;
		
		if(dashTimer <= 2)
			dashTimer = 2;
			
		isAttacking = false;
		isDashing = false;
		isTarotDashing = false; // el anillo rojo tambien corta el impulso aereo
		isTarotFloat = false;   // ... y la pasiva del tarot
	}
	
	// Escondida (agachada en un escondite): no puede usar la
	// acometida y el CD queda congelado en 2 segundos.
	if(isHiding)
	{
		if(attackTimer <= 60 * 2)
			attackTimer = 60 * 2;
		
		if(hjumpTimer <= 60 * 2)
			hjumpTimer = 60 * 2;
		
		if(dashTimer <= 60 * 2)
			dashTimer = 60 * 2;
			
		isAttacking = false;
		isDashing = false;
		isTarotDashing = false; // escondida: nada de impulsos aereos
		isTarotFloat = false;
	}
	
	// --- Habilidad 1: SALTO DE MARTILLO (ABAJO + Z, SOLO en el suelo) ---
	// Entrada estilo Amy original: mantener ABAJO y pulsar Z. PERO a
	// diferencia de la original, Amy Canon tambien puede hacerlo EN
	// PLENA CARRERA (la original solo agachada/parada): el salto de
	// martillo conserva el impulso de la carrera. Z SIN Abajo = salto
	// normal del juego (el martillo NUNCA se dispara con el salto
	// normal). Tampoco salta el martillo en plena acometida (C).
	// El golpe tiene la hitbox un 20% mas grande (pad en
	// obj_player_puppet). En el aire la Z no dispara nada: la pasiva
	// del tarot se activa manteniendola al caer (Step_0) y el impulso
	// aereo esta en la tecla X (habilidad 2).
	// BUGFIX burbuja: antes se exibia el estado NONE de la burbuja y al
	// salir (estado OVER) quedaba bloqueada PARA SIEMPRE; ahora solo se
	// bloquea DENTRO de la burbuja (!= AMY_BUBBLE_ACTIVE).
	if(global.playerControls && bubbleState != AMY_BUBBLE_ACTIVE && isGrounded
	&& !isDashing
	&& keyboard_check(global.KeyDown) && keyboard_check_pressed(global.KeyA) && hjumpTimer <= 0)
	{
		// Direccion: si aprietas izquierda/derecha, mira hacia ese lado;
		// si no, hacia donde ya miraba.
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;
		
		// --- salto de martillo (como siempre) ---
		isGrounded = false;
		isSpinning = false;
		isJumping = true;
		justJumped = true;
		// Al dispararse desde la CARRERA, el image_index viene a mitad de
		// la animacion de correr y se saltaria los frames del golpe (la
		// hitbox vive en los frames 0-3): reiniciar para que el swing
		// arranque siempre del frame 0.
		image_index = 0;
		xspd -= 10 * sin(angle);
		yspd = -10 * cos(angle);
		
		isHJ = true;
		hjumpTimer = AMY_CANON_BIGJUMP_RECHARGE;
		audio_play_sound(snd_jump, 0, false);
		net_sound_emit(snd_jump);
	}
	
	// --- HABILIDAD 2 (aire): DURANTE el impulso ---
	if(isTarotDashing)
	{
		tarotDashTimeLeft--;
		
		// Cancelaciones: aterrizar, dano, stun, muerte, tirolina, la
		// acometida del suelo, quedarse sin tiempo o salir del mapa.
		if(isGrounded || isHurt || isDead || shockedTimer > 0 || isZipline || isDashing || tarotDashTimeLeft <= 0 || x <= 1 || x >= room_width - 1)
		{
			isTarotDashing = false;
			isAttacking = false;
		}
		else
		{
			// Movimiento: la impulsa hacia adelante con caida casi nula.
			xspd = AMY_CANON_TAROTDASH_SPEED * tarotDashDir;
			yspd = min(yspd, AMY_CANON_TAROTDASH_FALLSPD);
		}
	}
	
	// --- Habilidad 2: IMPULSO AEREO DE TAROT (tecla X, SOLO EN EL AIRE) ---
	// Dash hacia adelante como la acometida de la tecla C, pero que
	// UNICAMENTE se usa en el aire (aqui estaba antes el ataque de
	// corazones). Si el killer la toca durante el impulso queda aturdido
	// 2 segundos (ver obj_player_puppet). Sonidos: DSTAROT1 suena 1 vez
	// al arrancar (sin loop) y Loop_Card va en loop mientras dura (lo
	// gestiona el bloque de audio del Step_0).
	// BUGFIX burbuja: mismo caso que el salto de martillo — disponible
	// tambien DESPUES de salir de la burbuja, solo se bloquea DENTRO.
	if(global.playerControls && bubbleState != AMY_BUBBLE_ACTIVE && !isGrounded
	&& !isHurt && !isDead && shockedTimer <= 0 && !isZipline && !isDashing
	&& !isAttacking && !isHJ && !isTarotDashing && keyboard_check_pressed(global.KeyB)
	&& attackTimer <= 0)
	{
		// Direccion: si aprietas izquierda/derecha, mira hacia ese lado;
		// si no, hacia donde ya miraba.
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;
		
		// --- impulso de tarot hacia adelante ---
		isTarotDashing = true;
		isAttacking = true;     // el killer que la toque queda aturdido 2s (ver obj_player_puppet)
		isTarotFloat = false;
		tarotDashDir = image_xscale;
		tarotDashTimeLeft = AMY_CANON_TAROTDASH_TIME;
		image_index = 0;
		
		// DSTAROT1 suena UNA sola vez al arrancar (loop = false: nunca va
		// en loop y se apaga solo). Loop_Card lo pone el Step_0 en loop.
		tarotSnd1 = audio_play_sound(DSTAROT1, 0, false);
		
		// NET: mandar el one-shot del impulso al resto de la sala
		// (mismo patron que el snd_tails_fly de scr_tails_special).
		net_sound_emit(DSTAROT1);
		
		// CD de la habilidad 2 (el que muestra el icono 2 de la UI).
		attackTimer = revivalTimes >= 2 ? AMY_CANON_ETAROTDASH_RECHARGE : AMY_CANON_TAROTDASH_RECHARGE;
	}
	
	// --- ATAQUE 3: INICIO de la acometida ---
	// Se activa con la tecla C (global.KeyC), solo en el suelo
	// y cuando el CD (dashTimer) llego a 0.
	if(global.playerControls && !isDashing && isGrounded && keyboard_check_pressed(global.KeyC) && dashTimer <= 0)
	{
		// Direccion: si aprietas izquierda/derecha al iniciar,
		// la acometida va hacia ese lado; si no, hacia donde miras.
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;
		
		isDashing = true;          // arranca la acometida
		isAttacking = true;        // con esto el EXE que te toque queda aturdido 3s (sistema del juego)
		dashDir = image_xscale;    // se guarda la direccion: no se puede girar a mitad de camino
		dashTimeLeft = AMY_CANON_DASH_TIME;  // DURACION ajustable (macro)
		dashSwingLatch = false;
		image_index = 0;
		
		// El CD arranca EN el momento del uso. Si eres demonizada
		// (revivalTimes >= 2) usa el CD corto AMY_CANON_EDASH_RECHARGE.
		dashTimer = revivalTimes >= 2 ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;
		
		audio_play_sound(snd_dash, 0, false);
		net_sound_emit(snd_dash);
	}
	
	// --- ATAQUE 3: DURANTE la acometida ---
	if(isDashing)
	{
		dashTimeLeft--;
		
		// Cancelaciones: si le hacen dano, la electrocutan, cae al
		// vacio, agarra una tirolina, se acaba el tiempo o llega al
		// borde de la sala, la acometida termina.
		if(shockedTimer > 0 || isHurt || isDead || isZipline || !isGrounded || dashTimeLeft <= 0 || x <= 1 || x >= room_width - 1)
		{
			isDashing = false;
			isAttacking = false;
		}
		else
		{
			// Movimiento: avanza a AMY_CANON_DASH_SPEED pixeles por
			// frame siguiendo la inclinacion del suelo (angle),
			// igual que el deslizamiento de Sally.
			gspd = AMY_CANON_DASH_SPEED * dashDir;
			xspd = gspd * cos(angle);
			yspd = gspd * -sin(angle);
			
			// GOLPE DE MARTILLO: cada vez que la animacion pasa por
			// el frame de impacto (AMY_CANON_DASH_HITFRAME = 3)
			// suena un golpe y levanta polvo delante.
			// dashSwingLatch evita que el mismo golpe se dispare
			// 2 veces (el frame dura 2 steps con anim 0.5).
			if(floor(image_index) == AMY_CANON_DASH_HITFRAME && !dashSwingLatch)
			{
				dashSwingLatch = true;
				
				audio_play_sound(snd_snap, 0, false);
				net_sound_emit(snd_snap);
				
				net_quick_effect(x + 18 * dashDir, y + 16, spr_dust, false, dashDir, 0, -1);
			}
			
			if(floor(image_index) != AMY_CANON_DASH_HITFRAME)
				dashSwingLatch = false;
		}
	}
	
	// El impulso aereo (tecla X) deja isAttacking en true para el stuneo;
	// en el aire gspd no se usa y durante la ACOMETIDA no hay que frenar.
	if(isAttacking && !isDashing)
		gspd = 0;
		
	if(state == AMY_CANON_HJUMP && isGrounded)
	{
		state = IDLE;
		isAttacking = false;
	}
	
	if(hjumpTimer > 0 && isGrounded)
		hjumpTimer--;
	
	if(attackTimer > 0)
		attackTimer--;
	
	// El CD de la acometida baja 1 frame por step solo cuando esta
	// en el suelo (mismo comportamiento que el salto alto).
	if(dashTimer > 0 && isGrounded && !isDashing)
		dashTimer--;
}
