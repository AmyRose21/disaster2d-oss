function scr_rouge_special()
{
	// =====================================================================
	//  ROUGE (v4.4) — moveset "ladrona de joyas": todo el aparato aereo
	//  de Knuckles + la patada de Sally en sus dos variantes.
	//
	//   * Z en el aire = PLANCEO (1:1 Knuckles): Z mantenido planea,
	//     izq/der aceleran hasta +-5, max 5 s (glideTimeout), soltar Z
	//     lo corta. Al tocar una pared REAL (canStuck, ver
	//     scr_collision_basic) se CLAVA (isStuck): desde ahi Z salta
	//     en direccion contraria a la pared. El planeo corta solo con
	//     suelo / dano / stun / muerte / tirolina / anillo rojo /
	//     esconderse, exactamente como Knuckles.
	//   * X = PATADA (patron Sally): en tierra el barrido bajo
	//     (spr_rouge_attack2, estado 15) y en el aire la patada con
	//     vuelo (spr_rouge_attack1, estado 14) con su empujoncito
	//     horizontal de ataque. El stun de 3 s al bando EXE lo aplica
	//     el cliente de la VICTIMA (obj_player_puppet, bit
	//     PLAYER_ATTACKING que viaja con Rouge en obj_netclient).
	//     Recarga 20 s.
	//
	//  v4.5 — MORIBUNDA: su salvacion de 1ra caida (la activa
	//  scr_player_instakill desde scr_player_hurt, patron Vanilla):
	//  mientras moribundaState > 0 esta tirada en el suelo, quieta e
	//  inmune; a los 6 s se levanta sola con 40 de vida. Ni planeo ni
	//  patada mientras dura. El server jamas se entera (la 2da caida
	//  SI es muerte real: guard canon del server).
	// =====================================================================

	// ---------------- MORIBUNDA (1ra caida) ----------------
	if(moribundaState > 0)
	{
		gspd = 0;
		xspd = 0;

		// mismo mini-fix de Vanilla: debilitada EN EL AIRE cae al suelo
		// en vez de quedarse flotando; la levitacion queda SOLO para el
		// hoyo de verdad (sin terreno en la columna de abajo)
		if(isGrounded)
			yspd = 0;
		else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
			yspd = ROUGE_MORIBUNDA_LEVITATE;
		else
			yspd = min(yspd + yAccel, maxYSpeed);

		isJumping = false;
		isSpinning = false;
		isAttacking = false;
		isGliding = false;

		if(isStuck)
		{
			canMove = true;
			isStuck = false;
		}

		moribundaTimer--;

		if(moribundaTimer <= 0)
		{
			moribundaState = 0;
			hp = ROUGE_MORIBUNDA_HEAL;
			hurttime = ROUGE_MORIBUNDA_INVULN;
			isHurt = false;
			glideTimer = 0;   // misericordia: planeo listo al levantarse
			attackTimer = 0;  // ...y la patada tambien
		}

		return;
	}

	if(redRingTimer > 0)
	{
		if(attackTimer <= 2)
			attackTimer = 2;

		if(glideTimer <= 2)
			glideTimer = 2;

		isAttacking = false;
	}

	if(isHiding)
	{
		if(attackTimer <= 60 * 2)
			attackTimer = 60 * 2;

		if(glideTimer <= 60 * 2)
			glideTimer = 60 * 2;

		isAttacking = false;
	}

	// v4.9 (COYOTE): mismo guard que Knux — si acaba de dejar el suelo
	// dentro de la ventana de salto, el Z se lo lleva el salto normal;
	// el planeo sale con la siguiente pulsacion.
	if(global.playerControls && keyboard_check_pressed(global.KeyA) && !isGrounded && !isGliding && glideTimer <= 0
	&& !(variable_instance_exists(id, "coyoteTimer") && coyoteTimer > 0 && yspd >= 0))
	{
		isAttacking = false;
		isJumping = false;
		isSpinning = false;
		isGliding = true;
		glideTimer = ROUGE_GLIDE_RECHARGE;
		glide_xspd = image_xscale * 5;
	}

	// PATADA (tecla X): en tierra Y en el aire (a diferencia de la
	// Sally vanilla, que solo la tiene aerea). El golpe aturde al
	// bando EXE 3 s por contacto: lo aplica el cliente de la victima
	// con el bit PLAYER_ATTACKING (patron Knuckles/Sally/Metal).
	if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0)
	{
		if(keyboard_check(global.KeyLeft))
			image_xscale = -1;
		else if(keyboard_check(global.KeyRight))
			image_xscale = 1;

		image_index = 0;
		attackTimer = ROUGE_ATTACK_RECHARGE;
		isAttacking = true;
		audio_play_sound(snd_dash, 0, false);
		net_sound_emit(snd_dash);
	}

	if(isAttacking)
	{
		// la patada corta el planeo/agarre (patron Knux: pegar manda)
		if(isGliding)
		{
			isGliding = false;

			if(isStuck)
			{
				canMove = true;
				isStuck = false;
			}
		}

		gspd = 0;
		xspd = image_xscale * (isGrounded ? .5 : 2);
	}

	if(isGrounded || isHurt)
	{
		isGliding = false;

		if(isStuck)
		{
			canMove = true;
			isStuck = false;
		}
	}

	if(isGliding)
	{
		isAttacking = false;
		glideTimeout++;

		if(glideTimeout >= 5 * 60)
		{
			glideTimeout = 0;
			isGliding = false;

			if(isStuck)
			{
				canMove = true;
				isStuck = false;
			}
		}

		if(global.playerControls && keyboard_check(global.KeyA))
		{
			if(!isStuck)
			{
				if(global.playerControls && keyboard_check(global.KeyLeft))
				{
					if(glide_xspd > -5)
						glide_xspd -= acc * 2;
				}
				else if(global.playerControls && keyboard_check(global.KeyRight))
				{
					if(glide_xspd < 5)
						glide_xspd += acc * 2;
				}

				switch(floor(glide_xspd))
				{
					case 5:
					case 4:
					case 3:
					case 2:
						image_index = 0;
						break;

					case 1:
						image_index = 1;
						break;

					case 0:
						image_index = 2;
						break;

					case -1:
						image_index = 3;
						break;

					case -5:
					case -4:
					case -3:
					case -2:
						image_index = 4;
						break;
				}
			}
		}
		else
		{
			isGliding = false;

			if(isStuck)
			{
				canMove = true;
				isStuck = false;
			}
		}

		image_xscale = 1;
		yspd = 1;
		xspd = glide_xspd;
	}
	else
	{
		if(isStuck)
		{
			canMove = true;
			isStuck = false;
		}
	}

	if(attackTimer > 0)
		attackTimer--;

	if(glideTimer > 0 && !isGliding)
		glideTimer--;
}
