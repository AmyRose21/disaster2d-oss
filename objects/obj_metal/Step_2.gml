#macro METAL_ATTACK BALANCING+1   // overdrive (tecla X)
#macro METAL_ELECTRO BALANCING+2  // electrocampo (tecla C)
#macro METAL_ZIPLINE BALANCING+3

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

if(metalDashing > 0)
{
        state = METAL_ATTACK;
        return;
}

if(isElectro > 0)
{
        state = METAL_ELECTRO;
        return;
}

if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = METAL_ZIPLINE;
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
