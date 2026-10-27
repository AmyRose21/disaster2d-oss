#macro SONIC_ATTACK BALANCING+1      // el golpe: tierra variante 1 (spr_sonic_attack2_tierra1)
#macro SONIC_SPINDASH BALANCING+2    // carga del spindash (spr_sonic_spin_charger)
#macro SONIC_ZIPLINE BALANCING+3     // tirolina (spr_sonic_zipline)
#macro SONIC_ATTACK_TIERRA2 BALANCING+4 // el golpe: tierra variante 2, hitbox +20% (spr idx 18)
#macro SONIC_ATTACK_AIRE BALANCING+5    // el golpe en el aire, hitbox +30% (spr idx 19)
#macro SONIC_NERVIOS BALANCING+6        // NERVIOS DE ACERO: tirado en el suelo (spr idx 20)
#macro SONIC_NERVIOS_FINISH BALANCING+7 // NERVIOS DE ACERO: levantandose (spr idx 21)

if(!emotion)
        state = IDLE;

// NERVIOS DE ACERO (fase 1 y 2): tirado en el suelo o levantandose.
// Tiene prioridad sobre TODO (mismo nivel que isDead): durante estas
// fases no hay control ni contacto posible. La fase 3 (powerboost) NO
// bloquea nada: Sonic se mueve y actua con total normalidad, solo que
// va dejando fantasmas y es inmune (eso lo garantiza scr_player_hurt).
if(nerviosState == 1)
{
        state = SONIC_NERVIOS;
        return;
}

if(nerviosState == 2)
{
        state = SONIC_NERVIOS_FINISH;
        return;
}

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
        // Variante del golpe: tierra 1 (normal), tierra 2 (+20% hitbox)
        // o aire (+30% hitbox). La fija scr_sonic_special al iniciarlo.
        if(atkVariant == 1)
                state = SONIC_ATTACK_TIERRA2;
        else if(atkVariant == 2)
                state = SONIC_ATTACK_AIRE;
        else
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
