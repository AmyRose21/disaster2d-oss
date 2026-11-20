#macro ROUGE_ATTACK BALANCING+1
#macro ROUGE_AIR_ATTACK BALANCING+2
#macro ROUGE_GLIDE BALANCING+3
#macro ROUGE_ZIPLINE BALANCING+4
#macro ROUGE_STUCK BALANCING+5
#macro ROUGE_MORIBUNDA BALANCING+6
#macro ROUGE_SPINDASH BALANCING+7     // v13: carga del spindash (spr_rouge_spin_charger)
#macro ROUGE_SPIN_RELEASE BALANCING+8 // v13: bola lanzada (spr_rouge_spin_release)
#macro ROUGE_SLIDE BALANCING+9        // v14: slide de Sally (spr_rouge_slide)
#macro ROUGE_GLIDE_AIR BALANCING+10   // v14: glide PASIVA tipo Knuckles (spr_rouge_glide)
#macro ROUGE_KICK BALANCING+11        // v32: PATADA de Sally (spr_rouge_attack3, modo ATTACK)
#macro ROUGE_RINGS BALANCING+12       // v32: canal de ANILLOS (spr_rouge_emotion3, modo SUPPORT)
#macro ROUGE_ESHIELD BALANCING+13     // v32: ESCUDO ELECTRICO (v42: reserva del puppet, ya NO se asigna local)

// v4.4: mismos estados netos que Knuckles (attack=14, air_attack=15,
// glide=16, zipline=17, stuck=18: viajan en el u8 state del
// CLIENT_PLAYER_DATA y todos los clientes los resuelven contra
// player_anims[CHARACTER_ROUGE]). v4.5: 19 = ROUGE_MORIBUNDA (1ra
// caida tirada: mismo patron del estado 19 de Vanilla).
// v13: 20 = ROUGE_SPINDASH (carga) y 21 = ROUGE_SPIN_RELEASE (bola
// lanzada del spindash) — viajan igual: el puppet los resuelve contra
// la tabla de scr_survivors.
// v14: 22 = ROUGE_SLIDE (el slide de Sally) y 23 = ROUGE_GLIDE_AIR
// (la glide PASIVA tipo Knuckles, tira direccional spr_rouge_glide).
// Nada de estados nuevos de red: viajan en el mismo u8 de siempre.

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

// v13 — SPINDASH: la carga del spindash pisa todo lo demas (quieta en
// el suelo, bola revolucionandose); la bola LANZADA se dibuja con su
// propia tira mientras dure el lanzamiento (spinDashRelease) y vuelve
// a la bola clasica del rodar normal cuando el flag se apaga.
if(isSpinCharging)
{
        state = ROUGE_SPINDASH;
        return;
}

if(isSpinning && spinDashRelease)
{
        state = ROUGE_SPIN_RELEASE;
        return;
}

// v4.5 — MORIBUNDA pisa todo lo demas (tirada en el suelo, quieta)
if(moribundaState > 0)
{
        state = ROUGE_MORIBUNDA;
        return;
}

// v32 — CANAL DE ANILLOS (C en modo SUPPORT): quieto invocando con la
// pose spr_rouge_emotion3 (la "emotico3" de la duena) mientras dure
// ringsChannel (el canal corta si la hieren: scr_rouge_special apaga
// ringsChannel y el estado vuelve al flujo normal al frame siguiente).
if(ringsChannel > 0)
{
        state = ROUGE_RINGS;
        return;
}

// v14 — SLIDE (patron Sally): por encima del ataque para que la
// patada aterrizada no lo tape — slide (spr_rouge_slide, 1 frame).
if(isSliding)
{
        state = ROUGE_SLIDE;
        return;
}

// OJO: el mapeo tierra/aire es al reves que el nombre del sprite:
// spr_rouge_attack1 (4 frames, la patada con vuelo) es el AEREO en
// el slot 14 del array de anims, y spr_rouge_attack2 (el barrido
// bajo) el de tierra en el 15 — el case del special decide cual
// mostrar. Aqui el estado es el MISMO esquema de Knuckles:
// en tierra = ROUGE_AIR_ATTACK(15) para el golpe alto,
// en el aire = ROUGE_ATTACK(14) para el vuelo.
// v32: la PATADA (modo ATTACK) pisa el mapeo tierra/aire con su
// estado propio (ROUGE_KICK = spr_rouge_attack3).
// v42 (fix duena, patron del doctor y del escudo de Sally v5.6): el
// ESCUDO ELECTRICO ya NO pisa NINGUN estado — es SOLO el aura
// (la dibuja Draw_0 con eShieldTimer, encima del cuerpo). Mientras
// dura, la animacion fluye NORMAL (idle respirando, andar, correr,
// salto...): antes el estado quedaba CLAVADO en ROUGE_ESHIELD y se
// congelaba la pose de idle. El isAttacking que deja el escudo sigue
// viajando igual (bit PLAYER_ATTACKING, el MISMO canal del escudo
// de Eggman) para que los puppets dibujen el aura y apliquen el
// chispazo de contacto.
if(isAttacking && eShieldTimer <= 0)
{
        if(kickState > 0)
                state = ROUGE_KICK;
        else if(isGrounded)
                state = ROUGE_AIR_ATTACK;
        else
                state = ROUGE_ATTACK;

        return;
}

if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = ROUGE_ZIPLINE;
                return;
        }
}

if(isHurt)
{
        state = HURT;
        return;
}

if(isStuck)
{
        state = ROUGE_STUCK;
        return;
}

// v13: el estado 16 (ROUGE_GLIDE) es el VUELO patron VANILLA (subir
// y bajar con Z): mismo slot de siempre — la tabla de scr_survivors
// ahora lleva spr_rouge_fly (alas batiendo) en el 16.
// v14: el estado 23 (ROUGE_GLIDE_AIR) es la GLIDE PASIVA tipo
// Knuckles — tira direccional spr_rouge_glide, frame 0..4 = hacia
// donde planea; el agarre de pared sigue siendo el 18 (ROUGE_STUCK).
if(isGliding)
{
        state = ROUGE_GLIDE_AIR;
        return;
}

if(isFlying)
{
        state = ROUGE_GLIDE;
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
