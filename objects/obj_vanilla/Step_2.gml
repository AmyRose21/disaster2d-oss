// Vanilla: estados identicos a Cream. Las macros CREAM_FLY /
// CREAM_SPAWN / CREAM_ZIPLINE estan definidas en
// obj_cream/Step_2.gml y no se redeclaran (patron sally_canon).
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

if(ringsSpawn > 0)
{
	state = CREAM_SPAWN;
	return;
}

if(isHurt)
{
	state = HURT;
	return;
}

if(isFlying)
{
	state = CREAM_FLY;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = CREAM_ZIPLINE;
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