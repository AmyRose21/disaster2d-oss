#macro METALAMY_ATTACK BALANCING+1
#macro METALAMY_AIR_ATTACK BALANCING+2
#macro METALAMY_SHOCKED BALANCING+3
#macro METALAMY_WON BALANCING+4
#macro METALAMY_LOST BALANCING+5
#macro METALAMY_ZIPLINE BALANCING+6
#macro METALAMY_LAZER BALANCING+7 // pose de disparo (tecla C, slot 20)
#macro METALAMY_SCAN BALANCING+8   // pose de escaneo (tecla V, slot 21, v4.7)

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
        // v4.7 (dash): el sprite es SIEMPRE spr_metalamy_attack2 (slot 15),
        // en el aire Y en tierra: ni al aterrizar ni al impactar con nada
        // aparece la vieja attack11 (pedido del usuario: "si le golpea debe
        // mantener el sprite como tal que tiene"). El viejo corte del ataque
        // al cambiar suelo <-> aire tambien desaparece: el dash dura lo que
        // diga su attackTimer (0,5 s) y ya esta.
        state = METALAMY_AIR_ATTACK;
        return;
}

if(shootPose > 0 && isGrounded)
{
        state = METALAMY_LAZER;
        return;
}

// v4.7 (scan): pose de escaneo mientras scanPose este activo (misma
// prioridad baja que la del disparo: el dash y la bala la pisan).
if(scanPose > 0 && isGrounded)
{
        state = METALAMY_SCAN;
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
