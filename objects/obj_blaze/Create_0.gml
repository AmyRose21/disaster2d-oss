// =====================================================================
//  BLAZE (v2.2, rescatada de TD2D Through the Blood).
//  Macros en scr_blaze_special; estados propios en Step_2.
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
isFlying = false;
dashing = 0;
flyTimer = 0;
flyTimeout = 0;
dashTimer = 0;
// BLAZE: salto de fuego, bola de fuego y forma ardiente
djumpRecharge = 0;
fireballTimer = 0;
burningTimer = 0;
burning = 0;
shootPose = 0;

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
specialFunc = scr_blaze_special; /* Function with abilities */

//constants
acc = BLAZE_ACC;
maxHSpeed = BLAZE_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7.5;
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
