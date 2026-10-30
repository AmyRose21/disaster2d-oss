// Default player values

#macro CREAM_FLY_RECHARGE (60 * 15)
#macro CREAM_FLY_SOLO (60 * 2)    // planeo SOLO: 2 seg (el original)
#macro CREAM_FLY_CARRY (60 * 5.5) // planeo con PASAJERO colgado: max 5.5 seg
#macro CREAM_DASH_RECHARGE (60 * 30)
#macro CREAM_RINGS_RECHARGE (60 * 40)
#macro ECREAM_RINGS_RECHARGE (60 * 30)
#macro CREAM_MAXSPEED 11
#macro CREAM_ACC 0.046875

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
ringsTimer = 0;
ringsSpawn = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

isColliding = false;
isFlying = true;
dashing = 0;
flyTimer = 0;
flyTimeout = 0;
dashTimer = 0;

// V2 (defensivo, fix v2.1.2): variables del kit de Vanilla (paciencia,
// moribunda, chocola, float run). Cream NO las usa, pero es el clone de
// Vanilla y comparte sus scripts genericos (scr_move_basic,
// scr_player_hurt...): si alguna lectura sin gate se cuela en una rama
// comun (le paso con el salto: "pacienciaState not set"), Cream crasheaba.
// Con estos defaults toda lectura en Cream es valida y da 0/false: mismo
// comportamiento que siempre, pero a prueba de ese patron de crash.
pacienciaState = 0;
pacienciaTimer = 0;
pacienciaWaitChocola = false;
pacienciaChocolaOut = false;
pacienciaUsed = false;
moribundaState = 0;
moribundaTimer = 0;
chocolaCd = 0;
chocolaProxTimer = 0;
dedemonCd = 0;
runHold = 0;
floatRunCap = CREAM_MAXSPEED;
isFloatRunning = false;
floatGhostTimer = 0;

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

// DIANA SPECIFIC
doubleJump = false;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = true;
specialFunc = scr_cream_special; /* Function with abilities */

//constants
acc = CREAM_ACC;
maxHSpeed = CREAM_MAXSPEED;
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