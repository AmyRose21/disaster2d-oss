#macro AMY_CANON_ATTACK BALANCING+1
#macro AMY_CANON_HJUMP BALANCING+2
#macro AMY_CANON_SEX BALANCING+3
#macro AMY_CANON_ZIPLINE BALANCING+4
// ATAQUE 3: estado de la acometida de martillo (sprite spr_amy_attack3_canon_)
#macro AMY_CANON_DASH BALANCING+5
// ESTADO BURBUJA (secuestro): 3 variantes segun la mirada.
// El sprite de cada una es spr_amy_capture_canon / _left / _right
// y estan registrados al final del array de CHARACTER_AMY_CANON en
// scr_survivors.gml (indices 19/20/21).
#macro AMY_CANON_CAPTURE BALANCING+6     // secuestro: mira al FRENTE (sin teclas)
#macro AMY_CANON_CAPTURE_L BALANCING+7   // secuestro: moviendose a la IZQUIERDA
#macro AMY_CANON_CAPTURE_R BALANCING+8   // secuestro: moviendose a la DERECHA
// PASIVA TAROT: flotacion cayendo lento con Z presionado (spr_amy_tarot_float)
#macro AMY_CANON_TAROT BALANCING+9
// HABILIDAD 2 (tecla X) SOLO en el aire: impulso de tarot (spr_amy_attack1_canon)
#macro AMY_CANON_TAROTDASH BALANCING+10

if(!emotion)
        state = IDLE;

// ESTADO BURBUJA: tiene prioridad sobre todo lo demas (misma
// prioridad que isDead). La variante del sprite depende de las
// teclas de movimiento: sin teclas = al frente (base), con
// izquierda/derecha = esa variante. (bubbleDir lo fija
// scr_amy_canon_bubble.gml segun el input).
if(bubbleState == AMY_BUBBLE_ACTIVE)
{
        if(bubbleDir < 0)
                state = AMY_CANON_CAPTURE_L;
        else if(bubbleDir > 0)
                state = AMY_CANON_CAPTURE_R;
        else
                state = AMY_CANON_CAPTURE;
                
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

// ABRAZO COMBINADO (interaccion con Sonic): mientras dura, su estado
// de red es AMY_CANON_HUG. En este cliente el sprite combinado lo
// dibuja Draw_0 (punto medio con Sonic) y en los demas, el puppet de
// Amy con el mismo check. Va ANTES que todo lo demas (el abrazo es
// solo un emote: si le pasa algo, scr_amy_hug_step_amy lo rompe y
// este bloque ya no corre).
if(hugActive)
{
        state = AMY_CANON_HUG;
        return;
}

if(isHJ)
{
        state = AMY_CANON_HJUMP;
        return;
}

// La acometida (ataque 3) se revisa ANTES que el ataque normal,
// porque durante la acometida isAttacking tambien esta en true
// y si no, se mostraria el sprite del ataque 1 en vez del ataque 3.
if(isDashing)
{
        state = AMY_CANON_DASH;
        return;
}

if(isTarotDashing)
{
        state = AMY_CANON_TAROTDASH;
        return;
}

if(isTarotFloat)
{
        state = AMY_CANON_TAROT;
        return;
}

if(isAttacking)
{
        state = AMY_CANON_ATTACK;               
        return;
}

if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = AMY_CANON_ZIPLINE;
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