#macro FW_ATTACK BALANCING+1      // 14: puño/patada
#macro FW_DJ BALANCING+4          // 18: pose DJ (doble salto)
#macro FW_CB_IDLE BALANCING+5     // 19: con ballesta, parada
#macro FW_CB_WALK BALANCING+6     // 20: con ballesta, caminando
#macro FW_CB_RUN BALANCING+7      // 21: con ballesta, corriendo

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

// DJ: mientras vuela con el doble salto musical usa su sprite propio
if(isDJ)
{
	state = FW_DJ;
	return;
}

if(isAttacking)
{
	state = FW_ATTACK;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = ZIPLINE;
		return;
	}
}

if(isHurt)
{
	state = HURT;
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

// Con la ballesta en la mano (cbTimer): variantes idle/walk/run
if(isCB)
{
	if(abs(xspd) > 0 && isGrounded)
	{
		if(abs(xspd) < 8)
			state = FW_CB_WALK;
		else
			state = FW_CB_RUN;
	}
	else
		state = FW_CB_IDLE;

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
