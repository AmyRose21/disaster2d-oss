#macro METALAMY_ATTACK BALANCING+1
#macro METALAMY_AIR_ATTACK BALANCING+2
#macro METALAMY_SHOCKED BALANCING+3
#macro METALAMY_WON BALANCING+4
#macro METALAMY_LOST BALANCING+5
#macro METALAMY_ZIPLINE BALANCING+6
#macro METALAMY_LAZER BALANCING+7 // pose de disparo (tecla C, slot 20)

if(!emotion)
	state = IDLE;

if(won)
{
	if(isGrounded)
	{
		state = METALAMY_WON;
		return;
	}
}

if(lost)
{
	if(isGrounded)
	{
		state = METALAMY_LOST;
		return;
	}
}

if(isHurt)
{
	state = HURT;
	return;
}

if(shockedTimer > 0)
{
	if(!isGrounded)
		state = HURT;
	else
		state = METALAMY_SHOCKED;

	return;
}

if(isAttacking)
{
	if(isGrounded)
	{
		if(state == METALAMY_AIR_ATTACK)
		{
			isAttacking = false;
			return;
		}
		state = METALAMY_ATTACK;
	}
	else
	{
		if(state == METALAMY_ATTACK)
		{
			isAttacking = false;
			return;
		}
		state = METALAMY_AIR_ATTACK;
	}
	return;
}

if(shootPose > 0 && isGrounded)
{
	state = METALAMY_LAZER;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;

	state = METALAMY_ZIPLINE;
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
