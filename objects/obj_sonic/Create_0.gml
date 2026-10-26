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
