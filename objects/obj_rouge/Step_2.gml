#macro ROUGE_ATTACK BALANCING+1
#macro ROUGE_AIR_ATTACK BALANCING+2
#macro ROUGE_GLIDE BALANCING+3
#macro ROUGE_ZIPLINE BALANCING+4
#macro ROUGE_STUCK BALANCING+5
#macro ROUGE_MORIBUNDA BALANCING+6

// v4.4: mismos estados netos que Knuckles (attack=14, air_attack=15,
// glide=16, zipline=17, stuck=18: viajan en el u8 state del
// CLIENT_PLAYER_DATA y todos los clientes los resuelven contra
// player_anims[CHARACTER_ROUGE]). v4.5: 19 = ROUGE_MORIBUNDA (1ra
// caida tirada: mismo patron del estado 19 de Vanilla).

if(!emotion)
	state = IDLE;

if(isDead)
{
	state = DEAD;
	return;
}

if(shockedTimer > 0)
{
	state = DEAD;
	return;
}

// v4.5 — MORIBUNDA pisa todo lo demas (tirada en el suelo, quieta)
if(moribundaState > 0)
{
	state = ROUGE_MORIBUNDA;
	return;
}

// OJO: el mapeo tierra/aire es al reves que el nombre del sprite:
// spr_rouge_attack1 (4 frames, la patada con vuelo) es el AEREO en
// el slot 14 del array de anims, y spr_rouge_attack2 (el barrido
// bajo) el de tierra en el 15 — el case del special decide cual
// mostrar. Aqui el estado es el MISMO esquema de Knuckles:
// en tierra = ROUGE_AIR_ATTACK(15) para el golpe alto,
// en el aire = ROUGE_ATTACK(14) para el vuelo.
if(isAttacking)
{
	if(isGrounded)
		state = ROUGE_AIR_ATTACK;
	else
		state = ROUGE_ATTACK;

	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = ROUGE_ZIPLINE;
		return;
	}
}

if(isHurt)
{
	state = HURT;
	return;
}

if(isStuck)
{
	state = ROUGE_STUCK;
	return;
}

if(isGliding)
{
	state = ROUGE_GLIDE;
	return;
}

if(isLookingUp)
{
	state = LOOKUP;
	return;
}

if(isLookingDown)
{
	state = LOOKDOWN;
	return;
}

if(isSpinning)
{
	state = SPIN;
	return;
}

if(abs(xspd) > 0 && isGrounded)
{
	if(abs(xspd) < 8)
		state = WALK;
	else
		state = RUN;
}

if(isOnEdge)
{
	state = BALANCING;
	return;
}

if (!isGrounded) //in air
{
	if(isJumping)
		state = JUMP;
	else
		state = FALL;
}
