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

// v89 (bug de la liana, reporte de la duena: «cuando se agarra de las
// lianas se queda en la pose de agarre y no puede usar otra vez ese
// agarre»): a Jinna le faltaba el bloque de tirolina que TODOS los
// demas personajes tienen en su Step_2 (Sonic, Tails, Metalamy — su
// propia plantilla — y el resto). Sin este bloque, el isZipline que
// pone obj_aiz_zipline (_holdPlayer) NUNCA se apaga cuando el viaje
// termina solo (el soltar con salto si lo apaga; llegar al final de
// la liana no): al aterrizar, cada vez que Jinna quedaba quieta en el
// suelo la maquina la dejaba en JINNA_ZIPLINE (spr_jinna_zipline = la
// «pose de agarre»), y de regalo el guard de obj_aiz_zipline
// («if(global.player.isZipline) return;», el que impide que una
// liana agarre a quien ya viaja en otra) le negaba TODAS las lianas
// para siempre. Mismo bloque estandar de la plantilla: en el aire =
// pose de liana (slot 19, que Draw_76 ya sabia dibujar; de paso el
// CARRY la ve colgada igual que todos), y al pisar suelo el flag se
// apaga y la maquina sigue su curso normal.
if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = JINNA_ZIPLINE;
                return;
        }
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

// (v89) justo aqui, despues de BALANCING, vivia «else if(isZipline)
// state = JINNA_ZIPLINE;»: solo se alcanzaba PARADA EN EL SUELO, que
// es justo el sintoma del bug (la pose de agarre para siempre). Con
// el bloque de arriba apagando el flag al aterrizar, este else-if
// quedaba en codigo muerto y se retira: la pose de liana solo existe
// en el aire, como en todos los demas personajes.
if(isSpinning)
        state = SPIN;
