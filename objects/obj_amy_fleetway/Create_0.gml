// Default player values — Fleetway Amy (v2.14)
// Port de "The Disaster 2D Fleetway Amy" (GameJolt, idkjustsee):
// rework de Amy inspirado en Sally.exe Continued/Finished Nightmare.
// Fisica identica a Amy Canon (el mod original usa estos valores).

#macro FW_ATTACK_RECHARGE (60 * 20)     // puño/patada (tecla B) modo superviviente (20 s)
#macro FW_EATTACK_RECHARGE (60 * 5)     // puño/patada con revivalTimes >= 2 (5 s)
#macro FW_CROSSBOW_RECHARGE (60 * 25)   // ballesta (tecla C) modo superviviente (25 s)
#macro FW_ECROSSBOW_RECHARGE (60 * 15)  // ballesta con revivalTimes >= 2 (15 s)
#macro FW_DJ_RECHARGE (60 * 10)         // DJ doble salto (tecla A aérea) superviviente (10 s)
#macro FW_EDJ_RECHARGE (60 * 15)        // DJ con revivalTimes >= 2 (15 s) — el revival lo SUBE (más vuelo)
#macro FW_DJ_BOOST -6                   // impulso vertical del DJ (yspd)
#macro FW_DJ_TIME 30                    // frames que dura el vuelo del DJ (djTimer de -1 a -30)
#macro FW_CB_TIME 120                   // frames con la ballesta en la mano tras disparar (2 s)
#macro FW_MAXSPEED 11
#macro FW_ACC 0.046875

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

// Fleetway: timers del moveset (nombres del mod original)
attackTimer = 0;     // puño/patada (tecla B)
djTimer = 0;         // DJ doble salto: 0 listo, -1..-30 volando, >0 recargando
crossBow = 0;        // ballesta (tecla C)
cbTimer = 0;         // frames restantes con la ballesta EN LA MANO (sprites cbamy)
// v2.14.1: paridad con obj_amy: el Step_0 portado lee isHJ en el guardia de
// daño de contacto (linea 48); sin declararlo el juego crashea con
// "isHJ not set before reading it". En Fleetway nunca se activa (el salto
// de martillo lo reemplaza el DJ) pero la variable tiene que existir.
hjumpTimer = 0;      // sin salto de martillo: siempre a 0
isHJ = false;        // idem: Step_0 lo lee, nada lo activa

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

// Fleetway: flags del moveset
isDJ = false;        // volando con el DJ doble salto
isCB = false;        // llevando la ballesta en la mano (cbTimer > 0)
afterCB = false;     // post-disparo (transición)
attackNum = 0;       // alterna puño (attack1) / patada (attack2)

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = false;
specialFunc = scr_amy_fleetway_special; /* Function with abilities */

//constants (física del mod original: veloz como Amy Canon)
acc = FW_ACC;
maxHSpeed = FW_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7;
isSlow = false;
doubleJump = false;

// Create sensors
instance_create_depth(x, y, 0, obj_player_sensorTL);
instance_create_depth(x, y, 0, obj_player_sensorTR);
instance_create_depth(x, y, 0, obj_player_sensorL);
instance_create_depth(x, y, 0, obj_player_sensorR);
instance_create_depth(x, y, 0, obj_player_sensorBL);
instance_create_depth(x, y, 0, obj_player_sensorBR);
instance_create_depth(x, y, 0, obj_player_sensorAL);
instance_create_depth(x, y, 0, obj_player_sensorAR);
