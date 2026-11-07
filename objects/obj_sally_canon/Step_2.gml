// POSES DEL ESCUDO (v5.8): la animacion de ACTIVACION (la pose quieta
// / agachada / aire que sale al pulsar la habilidad) vive su propia
// vida: se corta en seco si cambia la familia de animacion con la que
// empezo (aire <-> suelo <-> agachada; ej. activarla en el aire y caer
// al suelo la corta al instante), si la interrumpen dano / stun /
// muerte / fase 2 o si el escudo se apaga; y termina sola al
// reproducirse UNA vez (shieldPoseT llega al final). Mientras dure,
// Draw_0 dibuja la pose en vez del cuerpo; despues el cuerpo vuelve a
// su sprite normal y la pose NO vuelve a salir hasta la proxima
// activacion. Ni loopea ni se queda clavada: un solo pase y punto.
if(shieldPoseOn)
{
        var _poseCat = 0;
        if(state == JUMP || state == FALL)
                _poseCat = 2;
        else if(state == LOOKDOWN)
                _poseCat = 1;

        if(_poseCat != shieldPoseCat || shieldTimer <= 0 || isHurt || isDead || shockedTimer > 0 || fase2State != SALLY_CANON_F2_OFF)
                shieldPoseOn = false;
        else
        {
                shieldPoseT += SALLY_CANON_POSE_VEL;
                if(shieldPoseT >= sprite_get_number(shieldPoseSpr))
                        shieldPoseOn = false;
        }
}

// Los estados de la fase 2 (SALLY_CANON_F2_PT1..PT4, valores 18-21)
// estan definidos en scripts/scr_sally_canon_fase2.gml y usan los
// indices 18-21 del array player_anims de CHARACTER_SALLY_CANON.

// La fase 2 manda: mientras dure, el estado ES la parte actual (pt1 a
// pt4). Tiene prioridad sobre todo lo demas (no esta ni muerta ni
// herida: esta en su animacion de caida/recuperacion).
if(fase2State != SALLY_CANON_F2_OFF)
{
        state = fase2State;
        return;
}

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

// SPINDASH (duelista): la carga tiene prioridad sobre mirar abajo /
// rodar — mientras carga esta agachada en bola (mismo orden que
// Amelia: este bloque va ANTES que el de isLookingDown).
if(isSpinCharging)
{
        state = SALLY_CANON_SPINCHARGE;
        return;
}

if(isSliding)
{
        state = SALLY_SLIDE;
        return;
}

if(isAttacking)
{
        // DUELISTA: la patada en TIERRA viaja en su propio estado (22,
        // spr_sally_fase2_attack_canon) para que el cliente de la
        // victima sepa que son 2 hitboxes que ignoran i-frames; la
        // aerea sigue en el 14 de siempre.
        state = groundKick ? SALLY_CANON_F2_ATTACK : SALLY_ATTACK;
        return;
}

if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = SALLY_ZIPLINE;
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
        {
                state = FALL;
        }
}
