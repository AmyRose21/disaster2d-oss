// Default player values

#macro AMY_CANON_ATTACK_RECHARGE (60 * 20)
#macro AMY_CANON_EXEATTACK_RECHARGE (60 * 5)
#macro AMY_CANON_BIGJUMP_RECHARGE (60 * 9)
#macro AMY_CANON_MAXSPEED 11
#macro AMY_CANON_ACC 0.046875

// =====================================================================
//  ATAQUE 3: ACOMETIDA DE MARTILLO  (se activa con la tecla C)
// ---------------------------------------------------------------------
//  Guia rapida de los valores que puedes ajustar:
//  * DURACION  = cuanto tiempo (en frames) dura la acometida.
//                60 frames = 1 segundo. Prueba entre 48 (corta) y 96 (larga).
//  * VELOCIDAD = pixeles por frame que avanza Amy durante la acometida.
//                Su carrera normal maxima es 11; con 14 va mas rapido que
//                corriendo. Mas de 16 puede atravesar paredes al chocar.
//  * CD (cooldown) = frames que debes esperar para volver a usarla.
//                60*15 = 15 segundos (version superviviente).
//                AMY_CANON_EDASH_RECHARGE es el CD cuando Amy esta
//                demonizada (revivalTimes >= 2), suele ser mas corto.
//  * FRAME_GOLPE = frame de la animacion donde el martillo impacta
//                (frame 3 del sprite spr_amy_attack3_canon_). Cada vez que
//                la animacion pasa por ese frame suena un golpe.
//  * VEL_ANIM   = velocidad de la animacion (frames de sprite por step).
//                0.5 = la animacion de 8 frames tarda 16 steps en dar una
//                vuelta completa (1 golpe). Con duracion 64 son 4 golpes.
// =====================================================================
// CONSEJO: usa la DURACION en multiplos de 16 para que la animacion
// termine justo al acabar un golpe: 48 = 3 golpes, 64 = 4, 80 = 5.
#macro AMY_CANON_DASH_TIME 64               // DURACION en frames (64 = 1 seg aprox = 4 golpes completos)
#macro AMY_CANON_DASH_SPEED 14             // VELOCIDAD (mayor que 11 = mas rapida que correr)
#macro AMY_CANON_DASH_RECHARGE (60 * 15)   // CD en modo superviviente (15 segundos)
#macro AMY_CANON_EDASH_RECHARGE (60 * 5)   // CD en modo demonizada (5 segundos)
#macro AMY_CANON_DASH_HITFRAME 3           // FRAME de la animacion donde cae el golpe de martillo
#macro AMY_CANON_DASH_ANIMSPD 0.5          // VELOCIDAD de animacion (~3.7 golpes por segundo)

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
hjumpTimer = 0;
isHJ = false;

// --- Variables del ATAQUE 3 (acometida de martillo) ---
isDashing = false;      // true mientras dura la acometida
dashTimeLeft = 0;       // frames que le quedan a la acometida
dashDir = 1;            // direccion de la acometida (1 = derecha, -1 = izquierda)
dashTimer = 0;          // cooldown (CD) de la acometida en frames
dashSwingLatch = false; // evita que 1 mismo golpe suene 2 veces seguidas

// --- Variables del ESTADO BURBUJA (secuestro, reglas canonicas) ---
// Ver scr_amy_canon_bubble.gml para el significado y los valores
// ajustables (tiempo dentro, levitacion, vida al salir, etc.).
bubbleState = AMY_BUBBLE_NONE; // 0 = normal; 1 = dentro de la burbuja; 2 = ya salio
bubbleTimer = 0;               // frames que le quedan a la burbuja
bubbleDir = 0;                 // mirada: -1 = izq, +1 = der, 0 = al frente
bubbleFree = false;            // se pone true cuando toca liberarla

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
canSpin = false;
specialFunc = scr_amy_canon_special; /* Function with abilities */

//constants
acc = AMY_CANON_ACC;
maxHSpeed = AMY_CANON_MAXSPEED;
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