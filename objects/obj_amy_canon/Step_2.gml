#macro AMY_CANON_ATTACK BALANCING+1
#macro AMY_CANON_HJUMP BALANCING+2
#macro AMY_CANON_SEX BALANCING+3
#macro AMY_CANON_ZIPLINE BALANCING+4
// ATAQUE 3: estado de la acometida de martillo (sprite spr_amy_attack3_canon_)
#macro AMY_CANON_DASH BALANCING+5

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

if(isHJ)
{
	state = AMY_CANON_HJUMP;
	return;
}

// La acometida (ataque 3) se revisa ANTES que el ataque normal,
// porque durante la acometida isAttacking tambien esta en true
// y si no, se mostraria el sprite del ataque 1 en vez del ataque 3.
if(isDashing)
{
	state = AMY_CANON_DASH;
	return;
}

if(isAttacking)
{
	state = AMY_CANON_ATTACK;		
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = AMY_CANON_ZIPLINE;
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