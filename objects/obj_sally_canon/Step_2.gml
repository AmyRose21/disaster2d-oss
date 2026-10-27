// Los estados de la fase 2 (SALLY_CANON_F2_PT1..PT4, valores 18-21)
// estan definidos en scripts/scr_sally_canon_fase2.gml y usan los
// indices 18-21 del array player_anims de CHARACTER_SALLY_CANON.

// La fase 2 manda: mientras dure, el estado ES la parte actual (pt1 a
// pt4). Tiene prioridad sobre todo lo demas (no esta ni muerta ni
// herida: esta en su animacion de caida/recuperacion).
if(fase2State != SALLY_CANON_F2_OFF)
{
	state = fase2State;
	return;
}

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

if(isHurt)
{
	state = HURT;
	return;
}

if(isSliding)
{
	state = SALLY_SLIDE;
	return;
}

if(isAttacking)
{
	state = SALLY_ATTACK;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = SALLY_ZIPLINE;
		return;
	}
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
	if(abs(xspd) < 6)
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
	{
		state = FALL;
	}
}
