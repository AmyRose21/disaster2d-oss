// =====================================================================
//  METAL AMY (v2.2, killer rescatado de TD2D Through the Blood).
//  Macros en scr_metalamy_special. Estados propios en Step_2
//  (METALAMY_*: plantilla obj_exeller).
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
shockedTimer = 0;
deadTimer = 31;
deadColor = c_white;
invisTimer = 0;
revivalTimes = 0;
redRingTimer = 0;
attackSpeed = 0;
bounceTimer = 0;

shards = 0;

// METAL AMY: bala del canon
bulletTimer = 0;
shootPose = 0;

//General
hp = 10000;
isGrounded = false;
isJumping = false;
isLookingUp = false;
isLookingDown = false;
isDead = false;
isHurt = false;
isAttacking = false;
isSpinning = false;
isHiding = false;
won = false;
lost = false;
justJumped = false;
emotion = false;
emotionSnd = snd_none;
isBoosting = false;
isZipline = false;
isOnEdge = false;
edgeDir = 1;

taunt1 = array_contains(obj_unlockables.trades, "tmetalamy0");
taunt2 = array_contains(obj_unlockables.trades, "tmetalamy1");

// DIANA SPECIFIC
doubleJump = false;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = false;
canSpin = true;
specialFunc = scr_metalamy_special; /* Function with abilities */

//constants
acc = METALAMY_ACC;
maxHSpeed = METALAMY_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7;
isSlow = false;

instance_create_depth(x, y, 0, obj_exe_indicator);
instance_create_depth(x, y, 0, obj_exe_sprindicator);

// Create sensors
instance_create_depth(x, y, 0, obj_player_sensorTL);
instance_create_depth(x, y, 0, obj_player_sensorTR);
instance_create_depth(x, y, 0, obj_player_sensorL);
instance_create_depth(x, y, 0, obj_player_sensorR);
instance_create_depth(x, y, 0, obj_player_sensorBL);
instance_create_depth(x, y, 0, obj_player_sensorBR);
instance_create_depth(x, y, 0, obj_player_sensorAL);
instance_create_depth(x, y, 0, obj_player_sensorAR);

global.playerControls = false;
