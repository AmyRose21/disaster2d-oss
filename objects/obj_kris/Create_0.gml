// Default player values

// =====================================================================
//  KRIS (Deltarune) — superviviente #16. Base Tails (placeholder de
//  la duena: menu/barra) con su set de 13 sprites propios. Kit:
//   * Z EN EL AIRE = DOBLE SALTO (v2, pasiva): patron JETPACK de
//     Eggman — UN salto extra (solo subiendo de un salto, impulso -8)
//     con enfriamiento KRIS_DJUMP_RECHARGE. El HUD lo muestra como el
//     jetpack de Eggman (placeholder). Kris sigue SIN volar ni planear
//     (regla de la duena intacta). Su "slot glide" lo ocupa el ESCUDO.
//   * X = ESPADA (patron puno de Knuckles): en tierra un tajo
//     (reusa spr_kris_attack1_air1 hasta que haya arte de tierra) y
//     en el aire el ataque de DOS fases: air1 (spr_kris_attack1_air1)
//     -> air2 (spr_kris_attack1_air2) con hitbox +50% (pad del
//     puppet) e I-FRAMES mientras dura air2 (scr_player_hurt).
//     Stun de 3 s al bando EXE por contacto (cliente de la victima).
//   * C = ESCUDO (patron parry de Sonic, ver scr_parry.gml): SOLO en
//     tierra y SOLO contra lo que viene DE FRENTE (o del aire hacia
//     donde mira). De espaldas no bloquea nada. El exito usa
//     spr_kris_block_success_ground / _air segun donde este el
//     atacante.
//   * 1ra caida -> MORIBUNDA (patron Rouge v4.5): 6 s tirado, inmune
//     a todo, se levanta solo con 40 de vida. El server JAMAS se
//     entera de esa caida.
//   * 2da caida -> MUERTE REAL directa (guard canon del server):
//     JAMAS se demoniza ni se convierte en subdito negativo.
//   * JAMAS absorbible por Jinna: la trampa es SIEMPRE kind 0 en el
//     server (dano + TP normal); su cliente resuelve moribunda/muerte.
// =====================================================================

//Variables
gspd = 0;
xspd = 0;
yspd = 0;
state = 0;
angle = 0;
hurttime = 0;
rings = 0;
lookTimer = 0;
effectTime = 0;
attackTimer = 0;
// v2 (pasiva): recarga del DOBLE SALTO aereo (patron Eggman; el HUD la
// pinta con el icono del jetpack de Eggman)
djumpRecharge = 0;
revivalTimes = 0;
// v12 (NEGAGEN): la marca de SUBDITO NEGATIVO se declara AQUI, no lazy
// (patron de los 15 supervivientes). Kris JAMAS se convierte (regla),
// pero la declaramos igual: cualquier escritura por paquete aterriza
// en una variable real y los guards de los Draw pasan limpios.
isNegatouch = false;
shockedTimer = 0;
deadTimer = 31;
deadColor = c_white;
redRingTimer = 0;
deadTimer = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

//General
hp = 100;
isGrounded = false;
isJumping = false;
isLookingUp = false;
isLookingDown = false;
isDead = false;
isHurt = false;
isFlying = false;
isSpinning = false;
justJumped = false;
isHiding = false;
isAttacking = false;
isGliding = false;
emotion = false;
isBoosting = false;
isZipline = false;
isStuck = false;
isOnEdge = false;
edgeDir = 1;

// MORIBUNDA (patron Rouge v4.5): 0 = normal; 1 = tirado en el suelo
// (inmune, 6 s, se levanta con 40). El server nunca sabe que cayo.
moribundaState = 0;
moribundaTimer = 0;

// ESPADA: fase del golpe en curso
// (0 = ninguna, 1 = tajo en tierra, 2 = air1, 3 = air2)
krisAtkVariant = 0;

// LOVE (v46): nivel de violencia de Kris. Sube con los impactos
// acertados - cuchillazos de la espada + bloqueos del escudo - segun
// la lista de scr_kris_love_lv. Se pinta sobre la barra de vida
// (Draw_64) y alarga el stun de la espada en las pantallas ajenas.
// Reset por partida: vive en el Create del jugador.
krisLvHits = 0;
krisLv = 1;

// ESCUDO (patron parry): la maquina de fases vive en scr_parry_step
// (scr_parry.gml). Cooldowns:
//   parryState 0=nada, 1=windup, 2=ventana activa, 4=exito
parryState = 0;
parryTimer = 0;
parryCooldown = 0;
parryCooldownMax = 1;   // lo lee el icono del HUD (1 = evita /0)
parrySuccess = false;
parryActive = false;
parryFlash = 0;
parryLateSignal = 0;
// variante de la animacion de exito (true = el ataque bloqueado venia
// del AIRE -> spr_kris_block_success_air; false -> _ground)
krisBlockAir = false;

// Declaraciones neutras para scr_parry_step (patron Amy Canon: Sonic
// si tiene Nervios de Acero y spindash; Kris no, asi que aqui van en 0
// — el step del parry las lee sin gate de personaje)
nerviosState = 0;
nerviosUsed = false;
isSpinCharging = false;

//Character flags (constants)
canMove = true;
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = true;
specialFunc = scr_kris_special; /* Function with abilities */

//constants (stats Tails: la base placeholder de la duena)
acc = KRIS_ACC;
maxHSpeed = KRIS_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7;
isSlow = false;

// Create sensors
instance_create_depth(x, y, 0, obj_player_sensorTL);
instance_create_depth(x, y, 0, obj_player_sensorTR);
instance_create_depth(x, y, 0, obj_player_sensorL);
instance_create_depth(x, y, 0, obj_player_sensorR);
instance_create_depth(x, y, 0, obj_player_sensorBL);
instance_create_depth(x, y, 0, obj_player_sensorBR);
instance_create_depth(x, y, 0, obj_player_sensorAL);
instance_create_depth(x, y, 0, obj_player_sensorAR);