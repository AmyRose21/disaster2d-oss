#macro AMELIA_FLY BALANCING+1
#macro AMELIA_SRINGS BALANCING+2 // defensivo (sin uso)
#macro AMELIA_ZIPLINE BALANCING+3

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

if(isFlying)
{
	state = AMELIA_FLY;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = AMELIA_ZIPLINE;
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
		state = FALL;
}
