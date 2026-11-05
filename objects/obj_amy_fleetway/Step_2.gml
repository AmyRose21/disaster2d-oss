// v4.10 — FIX DESFASE DE INDICES: estas macros estaban TODAS corridas
// por -1 respecto del array de scr_survivors.gml (14=attack1, 15=attack2,
// 16=none, 17=zipline, 18=DJ, 19-21=cbamy). El FW_CB_IDLE apuntaba al 18
// (spr_amy_dj_fw: por eso "quieta no hacia la animacion de cbamy"), el
// FW_CB_WALK al 19 (spr_cbamy_IDLE: por eso "al caminar usa la idle") y
// el FW_DJ al 17 (la pose de TIROLINA). Ademas el estado de la tirolina
// usaba el identificador ZIPLINE, que NO EXISTE como macro (crash latente
// al agarrar una tirolina): ahora tiene su macro propia.
#macro FW_ATTACK BALANCING+1      // 14: puño (attack1, tecla B)
#macro FW_ATTACK2 BALANCING+2     // 15: patada (attack2, tecla B, alterna)
#macro FW_ZIPLINE BALANCING+4     // 17: tirolina
#macro FW_DJ BALANCING+5          // 18: pose DJ (doble salto, tecla Z)
#macro FW_CB_IDLE BALANCING+6     // 19: con ballesta, parada
#macro FW_CB_WALK BALANCING+7     // 20: con ballesta, caminando
#macro FW_CB_RUN BALANCING+8      // 21: con ballesta, corriendo

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

// DJ: mientras vuela con el doble salto musical usa su sprite propio
if(isDJ)
{
	state = FW_DJ;
	return;
}

if(isAttacking)
{
	// v4.10: alterna puño (attack1, frame 14) y patada (attack2,
	// frame 15) segun attackNum — antes siempre usaba el 14 y la
	// patada nunca se veia. El estado viaja por red: los demas
	// clientes ven la misma animacion (mismo array de sprites).
	state = attackNum ? FW_ATTACK : FW_ATTACK2;
	return;
}

if(isZipline)
{
	if(isGrounded)
		isZipline = false;
	else
	{
		// v4.10: FW_ZIPLINE (antes se usaba "ZIPLINE", identificador
		// que no existe en el proyecto: error en cuanto agarrara
		// una tirolina). Frame 17 del array = spr_amy_zipline_fw.
		state = FW_ZIPLINE;
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

// Con la ballesta en la mano (cbTimer): variantes idle/walk/run
if(isCB)
{
	if(abs(xspd) > 0 && isGrounded)
	{
		if(abs(xspd) < 8)
			state = FW_CB_WALK;
		else
			state = FW_CB_RUN;
	}
	else
		state = FW_CB_IDLE;

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
