// Default player values

#macro SALLY_EATTACK_RECHARGE (60 * 4)
#macro SALLY_ATTACK_RECHARGE (60 * 15)
#macro SALLY_SHIELD_RECHARGE (60 * 30)
#macro SALLY_ESHIELD_RECHARGE (60 * 15)
#macro SALLY_MAXSPEED 11
#macro SALLY_ACC 0.046875

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
shieldTimer = 0;
shieldRechrage = 0;
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
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
frame = 0;
deadTimer = 0;
deadColor = c_white;
slideSpeed = 5;
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
isAttacking = false;
isGliding = false;
isHiding = false;
isSliding = false;
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
canSpin = false;
specialFunc = scr_sally_special; /* Function with abilities */

//constants
acc = SALLY_ACC;
maxHSpeed = SALLY_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 6.5;
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