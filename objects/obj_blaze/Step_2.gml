#macro BLAZE_SHOOT BALANCING+1    // pose de disparo (tecla X)
#macro BLAZE_BURNING BALANCING+2 // forma ardiente (tecla C)
#macro BLAZE_ZIPLINE BALANCING+3

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

if(burning > 0)
{
	state = BLAZE_BURNING;
	return;
}

if(shootPose > 0 && isGrounded)
{
	state = BLAZE_SHOOT;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = BLAZE_ZIPLINE;
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
