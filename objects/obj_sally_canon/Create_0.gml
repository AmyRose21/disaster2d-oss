// Default player values (Sally Canon: misma base que Sally)

// Escudo roto: la Sally normal queda 1 seg inmune al romperse el
// escudo; Sally Canon son 3 seg (los 2 seg extra pedidos).
#macro SALLY_CANON_SHIELD_BREAK_INVULN (60 * 3)

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

// --- Variables de la FASE 2 (modo al caer, 4 partes) ---
// Ver scr_sally_canon_fase2.gml: macros ajustables y significado de
// cada parte (retroceso, suelo, salto con squash & stretch, regeneracion).
fase2State = SALLY_CANON_F2_OFF; // 0 = normal; 18-21 = pt1 a pt4
fase2Timer = 0;                  // frames que le quedan a la parte actual
fase2Used = false;               // true tras su 1ra caida (1 vez por ronda)
fase2Air = 0;                    // frames en el aire de pt3 (seguro de aterrizaje)
fase2HitX = 0;                   // direccion del ultimo golpe (retroceso de pt1)
fase2Sq = 0;                     // squash & stretch de pt3/pt4 (0 = normal)

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

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = false;
// Mismas habilidades que Sally (scr_sally_special no depende del
// personaje). Los cambios de Sally Canon van por otro lado: el slide
// da i-frames mientras dura y el escudo roto da 3 seg de inmunidad
// (ambos guards viven en scr_player_hurt).
specialFunc = scr_sally_special; /* Function with abilities */

//constants (mismas que Sally)
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
