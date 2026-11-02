// Default player values

// v3.0 (balance): escudo 20 -> 15 s, rastreador 30 -> 25 s y
// jetpack (doble salto) 10 -> 8 s (pedido del usuario)
#macro EGGMAN_DJUMP_RECHARGE (60 * 8)
#macro EGGMAN_TRACKER_RECHARGE (60 * 25)
#macro EGGMAN_SHIELD_RECHARGE (60 * 15)
#macro EEGGMAN_SHIELD_RECHARGE (60 * 7)
#macro EGGMAN_MAXSPEED 9
#macro EGGMAN_ACC 0.045835

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
djumpRecharge = 0;
trackerRecharge = 0;
shieldRechrage = 0;
// v3.1 «Genio Malvado» estilo RESCATE (patron dedemonTarget de Vanilla):
// geniusTarget/-Type = la trampa (nid + 0 sensor / 1 trampa de Amelia) sobre
// la que esta el Dr. (para el prompt y para saber QUIEN paga al completar);
// geniusSendCd = cadencia de los paquetes de progreso (cada 2 frames).
geniusTarget = -1;
geniusTargetType = -1;
geniusSendCd = 0;
revivalTimes = 0;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
frame = 0;
deadTimer = 0;
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
justJumped = false;
isColliding = false;
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
specialFunc = scr_egg_special; /* Function with abilities */

//constants
acc = EGGMAN_ACC;
maxHSpeed = EGGMAN_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 6.2;
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