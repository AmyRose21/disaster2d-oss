/// @description BURBUJA DE SECUESTRO (Amy Canon) - reglas canonicas
/// Amy Canon NUNCA se convierte en exe (regla canonica). Su 1ra
/// caida, en vez de matarla (estado de agonia con timer de 30s),
/// la encierra en una burbuja de secuestro: dentro levita lentamente
/// hacia arriba, puede moverse a izquierda/derecha, no puede salir
/// durante unos segundos, no puede ser herida por nada, y un
/// companero del equipo puede liberarla antes tocandola.
/// Si tras salir de la burbuja vuelve a ser derribada, muere
/// directamente (sin agonia y sin transformarse en exe).

// =====================================================================
//  PARAMETROS AJUSTABLES  (60 frames = 1 segundo)
// ---------------------------------------------------------------------
//  * TIEMPO_MIN / TIEMPO_MAX = la burbuja la retiene un numero
//    aleatorio de segundos entre ambos valores (7 a 10 por defecto).
//  * LEVITACION = velocidad (en pixeles/frame) a la que sube dentro
//    de la burbuja. 0.35 = sube lenta y tranquila; 0.8 = la arrastra.
//  * VEL_LATERAL = velocidad para moverse a los lados DENTRO de la
//    burbuja. 2.0 = la mitad de su paso normal caminando.
//  * HP_SALIDA = vida con la que sale al romperse la burbuja
//    (40 = misma vida que da un revive normal del juego).
//  * INVULN_SALIDA = frames de invulnerabilidad al salir, para que
//    no la rematen de un golpe justo al romperse la burbuja.
// =====================================================================
#macro AMY_CANON_BUBBLE_TIME_MIN (60 * 7)        // TIEMPO minimo atrapada (7 seg)
#macro AMY_CANON_BUBBLE_TIME_MAX (60 * 10)       // TIEMPO maximo atrapada (10 seg)
#macro AMY_CANON_BUBBLE_UP 0.35                  // LEVITACION hacia arriba (px/frame)
#macro AMY_CANON_BUBBLE_SIDE 2.0                // VEL_LATERAL dentro de la burbuja
#macro AMY_CANON_BUBBLE_RELEASE_HP 100           // HP_SALIDA al romperse la burbuja
#macro AMY_CANON_BUBBLE_RELEASE_INVULN (60 * 4) // INVULN_SALIDA (4 seg)

// Estados de la burbuja (variable bubbleState del jugador)
#macro AMY_BUBBLE_NONE 0   // normal: todavia no ha sido capturada en esta ronda
#macro AMY_BUBBLE_ACTIVE 1 // secuestrada: esta dentro de la burbuja
#macro AMY_BUBBLE_OVER 2   // ya salio: si cae de nuevo, muere directo

function scr_amy_canon_capture()
{
	// --- ENTRA EN LA BURBUJA (1ra caida de Amy Canon) ---
	// Se llama desde scr_player_instakill()/scr_player_hurt():
	// en vez de morir, queda secuestrada. El estado se sincroniza
	// solo con los demas clientes via CLIENT_PLAYER_DATA (state
	// 19/20/21 = secuestro), asi que todos la ven dentro de la
	// burbuja sin necesidad de paquetes extra.
	with(global.player)
	{
		bubbleState = AMY_BUBBLE_ACTIVE;
		bubbleTimer = irandom_range(AMY_CANON_BUBBLE_TIME_MIN, AMY_CANON_BUBBLE_TIME_MAX);
		bubbleDir = 0;
		bubbleFree = false;

		hp = max(hp, 0);     // la caida puede dejarla negativa: se normaliza a 0
		hurttime = 0;        // sin invulnerabilidad ni knockback heredado
		shockedTimer = 0;
		isDead = false;      // la burbuja NO cuenta como muerte
		revivalTimes = 0;    // jamas pasa a 2: nunca se transforma en exe
		isAttacking = false;
		isHJ = false;
		isDashing = false;   // la captura cancela la acometida (ataque 3)
		isTarotDashing = false; // ... y el impulso aereo (tarot)
		isTarotFloat = false;   // ... y la pasiva del tarot
		isSpinning = false;
		isJumping = false;
		isBoosting = false;
		isHiding = false;
		isZipline = false;
		isHurt = false;
		emotion = false;
		deadTimer = 31;
		gspd = 0;
		xspd = 0;
		yspd = -AMY_CANON_BUBBLE_UP;
		image_xscale = 1;   // mira al frente por defecto

		// Sonido del secuestro (lo oyen todos los que esten cerca)
		audio_play_sound(snd_bubble, 0, false);
		net_sound_emit(snd_bubble);
	}
}

function scr_amy_canon_bubble()
{
	// --- DENTRO DE LA BURBUJA (cada frame) ---
	// Corre en el ambito de obj_amy_canon (desde su Step_0, en vez
	// de scr_move_basic): dentro de la burbuja no corre, no salta,
	// no ataca; solo levita y se mueve a los lados.

	bubbleTimer--;

	// Direccion de la mirada (define el sprite de captura):
	// sin teclas = mira al frente; izquierda/derecha = gira los ojos.
	// (spr_amy_capture_canon / _left / _right)
	bubbleDir = 0;
	if(global.playerControls && keyboard_check(global.KeyLeft))
		bubbleDir = -1;
	if(global.playerControls && keyboard_check(global.KeyRight))
		bubbleDir = 1;

	// Fisica: levita hacia arriba + desplazamiento lateral.
	// OJO: scr_collision_basic suma la gravedad (yAccel) despues de
	// esto, por eso se compensa aqui: la levitacion neta queda en
	// AMY_CANON_BUBBLE_UP. scr_collision_check_top la detiene si
	// llega al techo (se queda flotando ahi hasta salir).
	xspd = bubbleDir * AMY_CANON_BUBBLE_SIDE;
	yspd = -(AMY_CANON_BUBBLE_UP + yAccel);
	image_xscale = 1; // el sprite de captura ya trae la direccion en la mirada

	// Dentro de la burbuja no puede hacer nada mas:
	isAttacking = false;
	isHJ = false;
	isDashing = false;
	isTarotDashing = false;
	isTarotFloat = false;
	isSpinning = false;
	isJumping = false;
	isLookingDown = false;
	isLookingUp = false;

	// --- Liberacion anticipada: un companero del team la toca ---
	// (vale cualquier superviviente vivo que NO este demonizado;
	//  el EXE y los minions no pueden liberarla)
	var list = ds_list_create();
	instance_place_list(x, y, obj_player_puppet, list, false);
	for(var i = 0; i < ds_list_size(list); i++)
	{
		var inst = list[| i];
		if(inst.isDemonized || inst.hp <= 0)
			continue;

		bubbleFree = true;
		break;
	}
	ds_list_destroy(list);

	// --- Fin natural: la burbuja se rompe sola al acabar su tiempo ---
	if(bubbleTimer <= 0)
		bubbleFree = true;

	if(bubbleFree)
	{
		// SALE DE LA BURBUJA: vuelve a la accion con la vida de
		// salida. Si la derriban otra vez, muere directo (eso lo
		// decide scr_player_instakill con bubbleState == OVER).
		bubbleState = AMY_BUBBLE_OVER;
		hp = AMY_CANON_BUBBLE_RELEASE_HP;
		hurttime = AMY_CANON_BUBBLE_RELEASE_INVULN;
		isGrounded = false; // cae desde donde este flotando
		xspd = 0;
		yspd = 0;
		gspd = 0;
		bubbleDir = 0;

		// Efecto de romperse la burbuja (visible en todos los
		// clientes) + sonido de pop. spr_shieldbreak es la esfera
		// rompiendose del juego (ajustable si prefieres otro sprite).
		audio_play_sound(snd_sally_shieldbreak, 0, false);
		net_sound_emit(snd_sally_shieldbreak);
		net_quick_effect(x, y, spr_shieldbreak, false, 1, 0, 0, 1);
	}
}
