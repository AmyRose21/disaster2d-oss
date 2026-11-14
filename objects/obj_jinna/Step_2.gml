// Estados propios de JINNA (plantilla obj_metalamy; macros de slot al
// estilo BALANCING+N para no tocar los base 0-13).
#macro JINNA_ATTACK1 BALANCING+1   // 14: golpe en tierra (spr_jinna_attack1)
#macro JINNA_ATTACK2 BALANCING+2   // 15: golpe aereo / pose de agarre (attack2)
#macro JINNA_SHOCKED BALANCING+3   // 16
#macro JINNA_WON BALANCING+4       // 17
#macro JINNA_LOST BALANCING+5      // 18
#macro JINNA_ZIPLINE BALANCING+6   // 19
#macro JINNA_LOST2 BALANCING+7     // 20: derrota alterna (spr_jinna_lost2)
#macro JINNA_TELE BALANCING+8      // 21: pose de teletransporte (spr_jinna_tele)

if(!emotion)
        state = IDLE;

// v21: al ganar SOLO la pose (spr_jinna_won) — el sonido es la risa
// del jingle de victoria (snd_jina_laugh, que ya suena de serie en
// todos los clientes via net_state_game). La linea snd_jina_taunt3
// se retiro a peticion de la duena (el dialogo molestaba).
if(won)
{
        if(isGrounded)
                state = JINNA_WON;
}

if(lost)
{
        if(isGrounded)
                state = jinnaLostState; // derrota aleatoria (patron chaos: lost/lost2)
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
                state = JINNA_SHOCKED;

        return;
}

if(jinnaTelePose > 0)
{
        state = JINNA_TELE;
        return;
}

// v4 — pose de PLANTAR LA TRAMPA: mismo sprite del tele (spr_jinna_tele),
// pedido de la duena ("la animacion al poner la trampa sera esta
// spr_jinna_tele"): Jina se agacha al portal que deja en sus pies.
if(jinnaTrapVisual > 0)
{
        state = JINNA_TELE;
        return;
}

// v6 — pose de INVOCAR MINIONS (C + ABAJO): mismo sprite del tele
// (spr_jinna_tele) que la trampa: Jinna se agacha sobre el portal
// del que emergen sus esbirros.
if(jinnaMinionPose > 0)
{
        state = JINNA_TELE;
        return;
}

if(jinnaGrabVisual > 0 && isGrounded)
{
        state = JINNA_ATTACK2;
        return;
}

if(isAttacking)
{
        state = isGrounded ? JINNA_ATTACK1 : JINNA_ATTACK2;
        return;
}

if(!isGrounded)
{
        if(yspd < 0)
                state = JUMP;
        else
                state = FALL;
}
else if(abs(gspd) > 0.5 || abs(xspd) > 0.5)
{
        if(abs(gspd) >= maxHSpeed * 0.95 || abs(xspd) >= maxHSpeed * 0.95)
                state = RUN;
        else
                state = WALK;
}
else if(isLookingUp)
        state = LOOKUP;
else if(isLookingDown)
        state = LOOKDOWN;
else if(isOnEdge)
        state = BALANCING;
else if(isZipline)
        state = JINNA_ZIPLINE;

if(isSpinning)
        state = SPIN;
