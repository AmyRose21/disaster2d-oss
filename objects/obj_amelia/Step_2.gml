#macro AMELIA_FLY BALANCING+1     // (v2.2: sin uso; v2.4 quito el vuelo, corre normal)
#macro AMELIA_SPINDASH BALANCING+2 // v2.6: carga del spindash (spr idx 15)
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

// v2.6 (SPINDASH de su placa TTB): la carga tiene prioridad sobre
// mirar abajo/rodar — mientras carga esta agachada en bola (patron
// Sonic: este bloque va ANTES que el de isLookingDown).
if(isSpinCharging)
{
        state = AMELIA_SPINDASH;
        return;
}

if(isHurt)
{
        state = HURT;
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
