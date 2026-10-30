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

// V2: paciencia / moribunda tienen sprite propio y pisan todo lo demas
if(pacienciaState == 1)
{
	state = VANILLA_PACIENCIA;
	return;
}

if(pacienciaState == 2 || moribundaState > 0)
{
	state = VANILLA_PACIENCIA_AGOTADA;
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
	else if(isFloatRunning)
		state = VANILLA_FLOAT_RUN; // V2: 3ra fase de corrida
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