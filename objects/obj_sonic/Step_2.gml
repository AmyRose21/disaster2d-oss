// v2: el golpe (tecla X) ya NO usa un estado fijo por variante: cada
// variante tiene su propio estado dinamico (SONIC_ATK_TIERRA/AIRE + N-1)
// y el sprite se resuelve con el escaneo por nombre de scr_survivors.gml.
#macro SONIC_SPINDASH BALANCING+2    // carga del spindash (spr idx 15)
#macro SONIC_ZIPLINE BALANCING+4     // tirolina (spr idx 17). ARREGLADO v2: antes apuntaba al 16 (spr_none) y Sonic se volvia invisible en la tirolina
#macro SONIC_NERVIOS BALANCING+5     // NERVIOS DE ACERO: tirado en el suelo, Idle en LOOP (spr idx 18)
#macro SONIC_NERVIOS_FINISH BALANCING+6 // NERVIOS DE ACERO: levantandose (spr idx 19)

// GOLPE (tecla X) con variantes dinamicas: el juego escanea solo
// cualquier sprite llamado spr_sonic_attack2_tierra<N> (golpe en
// tierra) o spr_sonic_attack2_aereo<N> (golpe en el aire), N = 1, 2,
// 3... Cada variante viaja por red como su propio estado (el server
// lo reenvia intacto), asi el otro jugador ve la misma animacion.
// Hitbox: aire +30%; tierra variante 1 normal, variante 2 o mas +20%
// (pads en obj_player_puppet/Step_0).
#macro SONIC_ATK_TIERRA 20        // variante N de tierra = estado 20 + (N-1), hasta 39
#macro SONIC_ATK_TIERRA_MAX 20    // tope de variantes tierra que se escanean
#macro SONIC_ATK_AIRE 40          // variante N de aire = estado 40 + (N-1), hasta 59
#macro SONIC_ATK_AIRE_MAX 20      // tope de variantes aire que se escanean

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
        // Variante del golpe: la fijo scr_sonic_special al INICIARLO
        // (atkAir + atkNum) y no cambia a mitad de animacion: si empezo
        // en el aire sigue siendo aerea aunque aterrice (y al reves).
        // El estado viaja tal cual por red: el puppet del otro cliente
        // resuelve el mismo sprite con el mismo escaneo por nombre.
        state = (atkAir ? SONIC_ATK_AIRE : SONIC_ATK_TIERRA) + (atkNum - 1);
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
