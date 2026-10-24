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
	
	// --- Habilidad 1: SALTO DE MARTILLO / IMPULSO AEREO (tecla Z) ---
	// EN SUELO (parada o corriendo): salto de martillo alto. Ya NO hace
	// falta mirar hacia abajo; se puede usar en plena carrera. El golpe
	// tiene la hitbox un 20% mas grande (pad en obj_player_puppet).
	// EN EL AIRE: impulso de tarot hacia adelante (movilidad); daña al
	// killer y lo stunea 2s si la toca durante el impulso.
	if(global.playerControls && bubbleState == AMY_BUBBLE_NONE && keyboard_check_pressed(global.KeyA) && hjumpTimer <= 0)
	{
		// Direccion: si aprietas izquierda/derecha, mira hacia ese lado;
		// si no, hacia donde ya miraba (vale para las dos modalidades).
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;
		
		if(isGrounded)
		{
			// --- modalidad SUELO: salto de martillo (como siempre) ---
			isGrounded = false;
			isSpinning = false;
			isJumping = true;
			justJumped = true;
			xspd -= 10 * sin(angle);
			yspd = -10 * cos(angle);
			
			isHJ = true;
			hjumpTimer = AMY_CANON_BIGJUMP_RECHARGE;
			audio_play_sound(snd_jump, 0, false);
			net_sound_emit(snd_jump);
		}
		else if(!isHurt && !isDead && shockedTimer <= 0 && !isZipline && !isDashing && !isAttacking && !isHJ)
		{
			// --- modalidad AIRE: impulso de tarot hacia adelante ---
			isTarotDashing = true;
			isAttacking = true;     // el killer que la toque queda aturdido 2s (ver obj_player_puppet)
			isTarotFloat = false;
			tarotDashDir = image_xscale;
			tarotDashTimeLeft = AMY_CANON_TAROTDASH_TIME;
			image_index = 0;
			
			// Mismo CD que el salto de martillo: es la misma habilidad 1,
			// la que toque primero se lo gasta.
			hjumpTimer = AMY_CANON_BIGJUMP_RECHARGE;
			
			// Los 3 sonidos del tarot arrancan solos: el bloque de audio
			// del Step_0 los mantiene en loop y los detiene al acabar.
		}
	}
	
	// --- HABILIDAD 1 (aire): DURANTE el impulso ---
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
	
	// --- Habilidad 2: ATAQUE DE CORAZONES (tecla X) ---
	// (!isDashing evita activarlo en medio de la acometida)
	if(global.playerControls && !isDashing && keyboard_check_pressed(global.KeyB) && attackTimer <= 0)
	{
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;
			
		for(var i = 0; i < 4; i++)
			net_quick_effect(global.player.x + 2 + (i * 10) * image_xscale, global.player.y - 4 + irandom_range(-3, 3), global.player.revivalTimes >= 2 ? spr_eroseheart : spr_roseheart, false, 1, 0, -1);
		
		image_index = 0;
		attackTimer = revivalTimes >= 2 ? AMY_CANON_EXEATTACK_RECHARGE : AMY_CANON_ATTACK_RECHARGE;
		isAttacking = true;
		audio_play_sound(snd_dash, 0, false);
		net_sound_emit(snd_dash);
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
	
	// El ataque normal (tecla X) la frena en el sitio,
	// pero durante la ACOMETIDA no hay que frenarla.
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
