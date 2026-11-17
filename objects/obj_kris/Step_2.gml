// KRIS — maquina de estados de red (patron Rouge + parry de Sonic).
// Estados netos: 0-13 estandar; 17 = tirolina y 18 = atascado
// (patron Knux, hoy sin uso: Kris no se agarra de paredes); 19 =
// MORIBUNDA (mismo slot que Rouge/Vanilla); 20 = tajo de tierra y
// 40/41 = ataque aereo air1/air2 (patron de estados dinamicos de
// Sonic, resueltos POR SPRITE en el Draw_76 y en el puppet); 60/61/64
// = ESCUDO (los mismos del parry, viajan en el u8 state del
// CLIENT_PLAYER_DATA y todos los clientes los resuelven contra
// scr_parry_sprite).

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

// MORIBUNDA pisa todo lo demas (tirado en el suelo, quieta)
if(moribundaState > 0)
{
	state = KRIS_MORIBUNDA;
	return;
}

// ESCUDO: estados 60/61/64 (patron parry). Van antes que la espada:
// el escudo reemplaza cualquier otra animacion mientras dura.
if(parryState > 0)
{
	if(parryState == 4)
		state = SONIC_PARRY_EXITO;
	else if(parryState == 2)
		state = SONIC_PARRY_INICIO_ACT;
	else
		state = SONIC_PARRY_INICIO;

	return;
}

// ESPADA (tecla X): la fase se fijo al iniciar (patron Sonic: si
// empezo en el aire sigue contando como aire aunque aterrice).
if(isAttacking)
{
	if(krisAtkVariant == 1)
		state = KRIS_ATK_TIERRA;
	else if(krisAtkVariant == 3)
		state = KRIS_ATK_AIRE + 1;
	else
		state = KRIS_ATK_AIRE;

	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		state = KRIS_ZIPLINE;
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
	state = KRIS_STUCK;
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