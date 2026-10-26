#macro SONIC_ATTACK BALANCING+1      // el golpe (spr_sonic_attack2)
#macro SONIC_SPINDASH BALANCING+2    // carga del spindash (spr_sonic_spin_charger)
#macro SONIC_ZIPLINE BALANCING+3     // tirolina (spr_sonic_zipline)

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

// La carga del spindash tiene prioridad sobre el ataque: mientras
// carga esta agachado en bola y no puede pegar.
if(isSpinCharging)
{
        state = SONIC_SPINDASH;
        return;
}

if(isAttacking)
{
        state = SONIC_ATTACK;               
        return;
}

if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = SONIC_ZIPLINE;
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
