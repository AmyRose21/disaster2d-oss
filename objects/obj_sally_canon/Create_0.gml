// Default player values (Sally Canon: misma base que Sally)

// Escudo roto: la Sally normal queda 1 seg inmune al romperse el
// escudo; Sally Canon son 3 seg (los 2 seg extra pedidos).
#macro SALLY_CANON_SHIELD_BREAK_INVULN (60 * 5)

// Escudo de Sally Canon: recarga 2 seg MAS RAPIDA que la de Sally
// (30 -> 28 s), para que la fase 1 no quede tan indefensa. Solo
// afecta a Sally Canon: la vanilla conserva SU SALLY_SHIELD_RECHARGE.
#macro SALLY_CANON_SHIELD_RECHARGE (60 * 28)

// POSES DEL ESCUDO (v5.8): velocidad de la animacion de ACTIVACION
// del escudo (frames de pose por frame de juego). 0.5 = cada frame
// de la pose dura 2 frames de juego (quieta 5f ~ 0.17 s, agachada
// 7f ~ 0.23 s, aire 4f ~ 0.13 s): se lee bien sin frenar el juego.
// A 1 es el ritmo "de motor" (mas rapido); mas abajo, mas lenta.
#macro SALLY_CANON_POSE_VEL 0.5

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

// --- Variables de la FASE DUELISTA (tras la 1ra caida) ---
// Ver scr_sally_canon_fase2.gml (bloque FASE DUELISTA). La marca se
// activa al final de pt4 y viaja por red con PLAYER_POWERBOOST.
duelista = false;   // true = fase duelista activa (patada en tierra,
                    // spindash, rodadura, escudo grupal, pasiva evasion)
groundKick = false; // true = la patada en curso es la de TIERRA (estado 22)

// POSES DEL ESCUDO (v5.8): animacion de ACTIVACION del escudo, de
// UN SOLO USO. Al pulsar la habilidad (scr_sally_special) se
// reproduce UNA vez la pose que toca segun el momento (quieta /
// agachada / en el aire) y punto: no loopea, no se queda clavada en
// el ultimo frame y NO vuelve a salir mientras dura el escudo —
// solo al pulsar OTRA VEZ la habilidad. Si cambia la familia de la
// animacion (ej. activarla en el aire y caer al suelo) se corta en
// seco al instante. Draw_0 dibuja la pose con SU propio contador
// (shieldPoseT): no toca sprite_index ni image_index, asi que ni los
// clamps del switch de Draw_76 ni Other_7 (Animation End) pueden
// cortarla o reiniciarla (eran la causa de los loops y reinicios de
// las v5.4-v5.7).
shieldPoseOn = false;   // true = se esta viendo la pose de activacion
shieldPoseSpr = -1;     // spr_sally_shield_canon / _down_canon / _air_canon
shieldPoseCat = -1;     // 0 = tierra / 1 = agachada / 2 = aire
shieldPoseT = 0;        // frames de pose reproducidos (avanza SALLY_CANON_POSE_VEL)

// SPINDASH (duelista): mismas variables que Amelia/Sonic (patron de
// scr_amelia_special; carga con abajo + Z, suelto abajo = lanzamiento).
isSpinCharging = false;
spinCharge = 0;           // carga actual (0..SALLY_CANON_SPINDASH_CHARGE_MAX)
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
// El spindash y la rodadura son de la FASE DUELISTA: arrancan
// apagados y se encienden al final de la fase 2 (ver
// scr_sally_canon_fase2). La vanilla no cambia en nada.
canSpinDash = false;
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
