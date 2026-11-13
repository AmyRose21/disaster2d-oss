// =====================================================================
//  AMELIA (v2.4, rescatada de TD2D Through the Blood).
//  Macros en scr_amelia_special; estados propios en Step_2.
//  (v2.4 quito vuelo/velocidad; v2.6 anyade el SPINDASH de su placa
//  del TTB: abajo + Z repetido, soltar abajo lanza en bola.)
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
revivalTimes = 0;
// v12 (NEGAGEN): la marca de SUBDITO NEGATIVO se declara AQUI, no lazy.
// BUG v8-v11: el paquete de conversion escribia "global.player.isNegatouch
// = true" — una dot-escritura sobre el INDICE del objeto en una variable
// que NO existia en la instancia (GameMaker no la crea por esa via:
// escritura silenciosamente ineficaz en este runtime). El guard
// variable_instance_exists del Draw_76/Draw_64 local daba false SIEMPRE:
// el afectado se veia su propio sprite en SU pantalla mientras los demas
// clientes si veian el nega (el puppet declara la marca en su Create y
// el with() escribe por INSTANCIA). Declarada aqui, la escritura del
// paquete es una asignacion normal a una variable ya existente (como
// hp / revivalTimes, que siempre funcionaron) y el guard del Draw pasa
// tambien en la pantalla del convertido.
isNegatouch = false;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
ringsTimer = 0;
ringsSpawn = 0; // defensivo (no invoca anillos: nunca > 0)
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

isColliding = false;
// AMELIA: trampolin y trampa
bananaTimer = 0;
trapTimer = 0;
// v2.6 (SPINDASH de su placa TTB): carga del spindash (patron Sonic)
isSpinCharging = false;
spinCharge = 0;           // carga actual (0..AMELIA_SPINDASH_CHARGE_MAX)
spinChargeDecay = 0;
spinDustTimer = 0;
spinRevSnd = -1;

//General
hp = 100;
isGrounded = false;
isJumping = false;
isLookingUp = false;
isLookingDown = false;
isDead = false;
isHurt = false;
isSpinning = false;
isAttacking = false;
isHiding = false;
justJumped = false;
emotion = false;
isBoosting = false;
isZipline = false;
isOnEdge = false;
edgeDir = 1;

// DIANA SPECIFIC
doubleJump = false;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = true;
specialFunc = scr_amelia_special; /* Function with abilities */

//constants
acc = AMELIA_ACC;
maxHSpeed = AMELIA_MAXSPEED;
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

// PASIVA AURAVISIÓN (v2.12, «los ojos de Nate»): sensores de calor de
// Amelia, solo en SU cliente (patron de los sensores de Amy Canon).
// Ve el aura de las entidades del bando EXE en un radio de 350 px a
// traves de las paredes; la del EXE REAL arde mas fuerte. Ver
// obj_amelia_auras y las macros AMELIA_AURA_* en scr_amelia_special.
instance_create_depth(x, y, 0, obj_amelia_auras);

// MARCA DE LA SALIDA (v4.5): version LIMITADA de los sensores de Amy
// Canon — flecha verde hacia el anillo de escape solo si esta a <= 680
// px (AMELIA_EXIT_SENSE), y parpadeando. Solo en SU cliente. Ver
// obj_amelia_indicators.
instance_create_depth(x, y, 0, obj_amelia_indicators);
