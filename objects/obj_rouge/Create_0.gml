// Default player values

// =====================================================================
//  ROUGE (v4.4): superviviente #15. Stats movidos de Knuckles (misma
//  agilidad aerea) con la aceleracion canonica de superviviente del
//  110v (v2.2.4), como Amelia/Blaze. Habilidades:
//   * Z en el aire  = PLANCEO (patron Knuckles: caida lenta y
//                     horizontal, max 5 s)
//   * pared         = AGARRE (patron Knuckles: al tocar pared real en
//                     planeo se clava y puede saltar desde ahi)
//   * X (tierra/aire) = PATADA (spr_rouge_attack2 tierra /
//                     spr_rouge_attack1 aire, patron Sally: golpe con
//                     stun de 3 s al bando EXE que aplica el cliente
//                     de la victima; recarga 20 s)
//  JAMAS se demoniza (regla canonica): igual que Amy Canon/Sally
//  Canon/Sonic/Vanilla (parche del server).
//
//  v4.5 — VIDAS (regla de la duena): 1 sola vida "blanda".
//   * 1ra caida -> MORIBUNDA (patron Vanilla): 6 s tirada, inmune a
//     todo, y se levanta sola con 40 de vida. El server NUNCA sabe
//     que cayo (la ronda sigue). Su retrato marca el "hit" (cayo 1
//     vez: revivalTimes=1 solo en el cliente).
//   * 2da caida -> MUERTE REAL de una (con la X en el retrato):
//     reviveObj se limpia, sin barra de revive, y el server (guard
//     canon de Game.c) la marca PLAYER_CANTREVIVE al instante.
//   * PORTAL TRAMPA DE JINNA: si el dano de la trampa la IRIA a
//     dejar moribunda o muerta (hp tras el golpe <= 0), en vez del
//     dano normal es ABSORBIDA (spr_rouge_traped): fuera de juego +
//     Jinna potenciada (tier "arduas" de Amy/Sally).
// =====================================================================
#macro ROUGE_ATTACK_RECHARGE (60 * 20)
#macro ROUGE_GLIDE_RECHARGE (60 * 12)
#macro ROUGE_MAXSPEED 11
#macro ROUGE_ACC 0.046875

// v4.5 — moribunda (su unica salvacion; patron VANILLA_MORIBUNDA_*)
#macro ROUGE_MORIBUNDA_TIME (60 * 6)  // tirada en el suelo
#macro ROUGE_MORIBUNDA_HEAL 40        // se levanta con poca vida
#macro ROUGE_MORIBUNDA_INVULN (60 * 3)
#macro ROUGE_MORIBUNDA_LEVITATE -0.35 // flota solo si cayo a un hoyo

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
glideTimer = 0;
glideTimeout = 0;
revivalTimes = 0;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
glide_xspd = 0;
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
emotion = false;
isBoosting = false;
isZipline = false;
isStuck = false;
isOnEdge = false;
edgeDir = 1;

// v4.5 — MORIBUNDA: su salvacion de 1ra caida (patron Vanilla). 0 =
// normal; 1 = tirada en el suelo (inmune, 6 s, se levanta con 40).
moribundaState = 0;
moribundaTimer = 0;

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = true;
specialFunc = scr_rouge_special; /* Function with abilities */

//constants
acc = ROUGE_ACC;
maxHSpeed = ROUGE_MAXSPEED;
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
