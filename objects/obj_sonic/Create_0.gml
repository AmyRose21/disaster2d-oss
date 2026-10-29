// Default player values

#macro SONIC_MAXSPEED 11
// CONSEJO: si quieres que Sonic sea EL MAS RAPIDO del bando superviviente
// (igualando a los EXE, que corren a 12), cambia el 11 de arriba por 12.
// El resto del roster survivor corre a 11; los 4 EXE corren a 12.
#macro SONIC_ACC 0.046875

// =====================================================================
//  ATAQUE 1: EL GOLPE (tecla X) - estilo EXE
// ---------------------------------------------------------------------
//  Sonic pega con el mismo tipo de golpe que usan los killers (el
//  ataque normal del EXE original / Exetior): sprite spr_sonic_attack2
//  y el MISMO sonido (snd_dash). Si el EXE o un demonizado lo toca
//  mientras pega, queda aturdido 3 segundos (sistema estandar del
//  juego, igual que el martillo de Amy). Sonic NO se frena al golpear:
//  conserva su impulso, igual que los EXE con su ataque.
//
//  * CD = frames de recarga. 60*20 = 20 segundos (version
//    superviviente). SONIC_EATTACK_RECHARGE es el CD cuando Sonic
//    esta demonizado (revivalTimes >= 2).
//  * VEL_ANIM = velocidad de la animacion (frames de sprite por step).
//    spr_sonic_attack2 tiene 15 frames; con 0.5 el golpe tarda 30
//    frames (medio segundo) en dar la vuelta completa.
// =====================================================================
#macro SONIC_ATTACK_RECHARGE (60 * 20)
#macro SONIC_EATTACK_RECHARGE (60 * 5)
#macro SONIC_ATTACK_ANIMSPD 0.5

// =====================================================================
//  ATAQUE 2: SPINDASH (abajo + Z repetido, soltar abajo) - clasico
// ---------------------------------------------------------------------
//  Como en los Sonic clasicos: agachado (ABAJO) y parado, cada pulsacion
//  de Z (salto) le da una revolucada mas a la carga (con el sonido
//  snd_spin del juego). Al SOLTAR ABAJO, Sonic sale disparado en bola
//  (isSpinning) a una velocidad que depende de la carga.
//
//  * BASE      = velocidad minima al soltar sin ninguna carga.
//  * REV       = velocidad que suma cada pulsacion de Z.
//  * CHARGE_MAX = carga maxima posible. Velocidad maxima al soltar =
//                BASE + CHARGE_MAX (8 + 6 = 14, igual de rapida que la
//                acometida de martillo de Amy Canon).
//  * DECAY     = frames que tarda en perder 1 punto de carga estando
//                quieto sin pulsar Z (90 frames = 1.5 segundos).
//
//  El spindash NO tiene cooldown: su coste es quedarte quieto
//  cargandolo. Al salir disparado va en bola (estado SPIN), y la
//  friccion natural de la bola lo frena hasta la velocidad normal.
// =====================================================================
#macro SONIC_SPINDASH_BASE 8
#macro SONIC_SPINDASH_REV 2
#macro SONIC_SPINDASH_CHARGE_MAX 6
#macro SONIC_SPINDASH_DECAY 90

// =====================================================================
//  PASIVA NERVIOS DE ACERO: la 1ra caida de la ronda NO mata a Sonic.
//  Igual que la burbuja de Amy: en vez del estado de agonia, cae al
//  suelo SONIC_NERVIOS_TIME segundos con la animacion ..._Idle en
//  LOOP, luego se levanta (animacion ..._finish) y entra en POWERBOOST:
//  SONIC_NERVIOS_INVULN
//  segundos de invulnerabilidad TOTAL dejando una estela de fantasmas
//  de corta duracion (estilo dash de Cream). Solo 1 vez por ronda.
//  (60 frames = 1 segundo)
// =====================================================================
#macro SONIC_NERVIOS_TIME (60 * 4)          // DURACION tirado en el suelo, Idle en LOOP (4 seg; pon (60 * 3) si lo prefieres de 3)
#macro SONIC_NERVIOS_IDLE_SPD 0.5           // velocidad del LOOP del Idle (frames de sprite por step)
#macro SONIC_NERVIOS_FINISH_TIME 30         // DURACION de la animacion de levantarse (~0.5 seg)
#macro SONIC_NERVIOS_INVULN (60 * 4)        // DURACION del powerboost (4 seg)
#macro SONIC_NERVIOS_GHOST_EVERY 5          // un fantasma cada N frames
#macro SONIC_NERVIOS_GHOST_FADE 0.07        // velocidad de desvanecido (~14 frames de vida)
#macro SONIC_REVIVEBOOST_INVULN (60 * 6)    // inmunidad al REVIVIR con powerboost (6 seg; el revive normal da 4)

// =====================================================================
//  ATAQUE 1 variantes (golpe, tecla X): en el AIRE la hitbox de stuneo
//  es 30% mas grande; en TIERRA hay 2 variantes al azar: la 1 usa la
//  hitbox normal y la 2 es 20% mas grande. En ambos casos Sonic es
//  inmune al dano mientras dura el golpe (ver scr_player_hurt).
// =====================================================================
#macro SONIC_ATTACK_AIRE_PAD 9              // px extra de hitbox en el aire (~30%)
#macro SONIC_ATTACK_TIERRA2_PAD 6           // px extra de la variante 2 de tierra (~20%)

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
revivalTimes = 0;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

attackTimer = 0;

// --- Variables del SPINDASH ---
isSpinCharging = false;   // true mientras esta agachado cargando la bola
spinCharge = 0;           // carga actual (0..SONIC_SPINDASH_CHARGE_MAX)
spinChargeDecay = 0;      // contador para perder carga con el tiempo

// --- Variables de NERVIOS DE ACERO (pasiva) ---
nerviosState = 0;    // 0=apagada, 1=tirado en el suelo, 2=levantandose, 3=powerboost
nerviosUsed = false; // true tras usarla: 1 sola vez por ronda
nerviosTimer = 0;    // contador de la fase actual
ghostTimer = 0;      // contador para la estela de fantasmas

// --- POWERBOOST visual (FX Frontiers procedurales: scr_powerboost_fx) ---
reviveBoost = false; // FASE 2: true tras ser revivido -> efectos persistentes
pbTime = 0;          // reloj de animacion del pulso del aura
pbFlash = 0;         // frames restantes del anillo de activacion

// --- Variante del ATAQUE 1 (golpe) ---
// El golpe escanea solo los sprites del proyecto: cualquier
// spr_sonic_attack2_tierra<N> o spr_sonic_attack2_aereo<N> (N=1,2,3...)
// cuenta como una variante. Se fijan al INICIAR el golpe y no cambian:
// si empezo en el aire, la animacion es aerea hasta el final.
atkAir = false;  // true: el golpe empezo en el aire
atkNum = 1;      // numero de la variante elegida (1..N)

// --- PARRY (tecla C, estilo Frontiers) ---
// Logica completa en scripts/scr_parry/scr_parry.gml. Cooldowns:
// fallo 14s / exito 7s en fase normal; fallo 10s / exito 2s tras haber
// usado Nervios de Acero (fase powerboost, nerviosUsed).
parryState = 0;      // 0=nada, 1=windup, 2=ventana activa, 4=exito
parryTimer = 0;      // frames restantes de la fase actual
parryCooldown = 0;   // frames restantes de recarga
parrySuccess = false;// true si la ventana intercepto algo
parryActive = false; // true durante ventana+gracia (lo leen los checks de red)
parryAir = false;    // el parry empezo en el aire (elige sprite/state)
parryFlash = 0;      // frames restantes del anillo cian (lo dibuja Draw_0)

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
isAttacking = false;
isHiding = false;
justJumped = false;
emotion = false;
isBoosting = false;
isZipline = false;
isOnEdge = false;
edgeDir = 1;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
// PASIVA: Sonic SI rueda (bola) al agacharse corriendo, como Tails/Knux.
canSpin = true;
specialFunc = scr_sonic_special; /* Function with abilities */

//constants
acc = SONIC_ACC;
maxHSpeed = SONIC_MAXSPEED;
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
