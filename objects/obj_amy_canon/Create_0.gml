// Default player values

#macro AMY_CANON_ATTACK_RECHARGE (60 * 0)
#macro AMY_CANON_EXEATTACK_RECHARGE (60 * 5)
#macro AMY_CANON_BIGJUMP_RECHARGE (60 * 3)
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
#macro AMY_CANON_DASH_RECHARGE (60 * 10)   // CD en modo superviviente (15 segundos)
#macro AMY_CANON_EDASH_RECHARGE (60 * 5)   // CD en modo demonizada (5 segundos)
#macro AMY_CANON_DASH_HITFRAME 3           // FRAME de la animacion donde cae el golpe de martillo
#macro AMY_CANON_DASH_ANIMSPD 0.5          // VELOCIDAD de animacion (~3.7 golpes por segundo)

// =====================================================================
//  PASIVA TAROT + HABILIDADES (version tarot v3)
// ---------------------------------------------------------------------
//  HABILIDAD 1 = SALTO DE MARTILLO (ABAJO + Z, en el suelo): salto alto
//  como la Amy original, PERO tambien en plena carrera (conserva el
//  impulso). Z sola = salto normal. Hitbox del golpe un 20% mas grande
//  (AMY_CANON_HJUMP_HITBOX_PAD). CD: hjumpTimer
//  (AMY_CANON_BIGJUMP_RECHARGE). En el aire la Z no hace nada.
//
//  PASIVA TAROT FLOAT: si Amy esta en el aire CAYENDO y dejas presionado
//  el boton de saltar (Z), entra en estado tarot (spr_amy_tarot_float)
//  y cae MUCHISIMO mas lento, en cuanto empieza a caer.
//  SONIDO de la pasiva: SOLO DSTAROT2 + Loop_Card en loop (DSTAROT1 no
//  suena en la pasiva). Se detienen al soltar el boton, tocar el suelo
//  o cualquier cosa que la pare (dano, stun, burbuja, etc.).
#macro AMY_CANON_TAROT_FALLSPD 0.5   // VELOCIDAD de caida flotando (12 = caida normal; 0.5 = 24 veces mas lento)
// ---------------------------------------------------------------------
//  HABILIDAD 2 = IMPULSO AEREO DE TAROT (tecla X, SOLO EN EL AIRE; antes
//  era el ataque de corazones): dash hacia adelante como la acometida de
//  la tecla C pero aereo, con el sprite nuevo spr_amy_attack1_canon
//  (2 frames). Si el killer la toca durante el impulso queda aturdido
//  2 segundos. SONIDO: DSTAROT1 suena 1 vez al arrancar (sin loop) y
//  Loop_Card va en loop mientras dura; se detienen al acabar.
//  CD: attackTimer (AMY_CANON_TAROTDASH_RECHARGE).
#macro AMY_CANON_TAROTDASH_TIME 48        // DURACION del impulso aereo en frames (~0.8s; la acometida dura 64)
#macro AMY_CANON_TAROTDASH_SPEED 14      // VELOCIDAD horizontal del impulso (igual que la acometida)
#macro AMY_CANON_TAROTDASH_FALLSPD 2     // caida max durante el impulso (casi horizontal)
#macro AMY_CANON_TAROTDASH_ANIMSPD 0.25  // VELOCIDAD de anim del sprite de 2 frames (1 ciclo cada 8 frames)
#macro AMY_CANON_TAROTDASH_RECHARGE (60 * 5)   // CD del impulso en modo superviviente (9 seg)
#macro AMY_CANON_ETAROTDASH_RECHARGE (60 * 4)  // CD del impulso en modo demonizada (4 seg)
#macro AMY_CANON_HJUMP_HITBOX_PAD 5      // px extra de hitbox del salto de martillo (~20% del sprite)
#macro AMY_CANON_TAROTDASH_HITBOX_PAD 5  // px extra de hitbox del impulso aereo de tarot (~20% del sprite)

// =====================================================================
//  v2.13 — SOL (la cara de Amy Canon de la pasiva «Sol y Luna»):
//  GOTEO AUTOMATICO de 1 ring cada 7 s MIENTRAS VIVA (se pausa escondida
//  o muerta). El ring es para TODO el bando: va por el mismo camino que
//  los anillos de Cream (CLIENT_CREAM_SPAWN_RINGS; el server lo acepta
//  para CH_AMY_CANON desde v2.13 y spawnea 1 solo, worth 1) y lo recoge
//  quien lo pise. «Mientras viva» es la regla: Amy caida apaga el Sol.
//  7 s a proposito (nota de diseño de la pagina): a este ritmo curar
//  sigue costando rings y el EXE conserva su ventana de kill.
// =====================================================================
#macro AMY_CANON_SOL_RING_EVERY (60 * 7)

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

// v2.13 (SOL de «Sol y Luna»): contador del goteo de rings (1 cada
// AMY_CANON_SOL_RING_EVERY frames mientras viva; ver scr_amy_canon_special)
solRingTimer = AMY_CANON_SOL_RING_EVERY;

// --- Variables del ATAQUE 3 (acometida de martillo) ---
isDashing = false;      // true mientras dura la acometida
dashTimeLeft = 0;       // frames que le quedan a la acometida
dashDir = 1;            // direccion de la acometida (1 = derecha, -1 = izquierda)
dashTimer = 0;          // cooldown (CD) de la acometida en frames
dashSwingLatch = false; // evita que 1 mismo golpe suene 2 veces seguidas

// --- Variables del TAROT (pasiva float + impulso aereo de la habilidad 2) ---
isTarotFloat = false;    // true mientras flota cayendo lento (pasiva)
isTarotDashing = false;  // true durante el impulso aereo (habilidad 2, tecla X)
tarotDashTimeLeft = 0;   // frames que le quedan al impulso aereo
tarotDashDir = 1;        // direccion del impulso aereo (1 = der, -1 = izq)
tarotSnd1 = -1;          // canal de DSTAROT1 (one-shot del impulso; no se detiene a mano)
tarotSnd2 = -1;          // canal de DSTAROT2 (loop de la pasiva)
tarotSnd3 = -1;          // canal de Loop_Card (loop compartido pasiva/impulso)
tarotNetTimer = 0;       // NET: contador de frames para re-enviar los loops del tarot

// --- Variables del LIGHT DASH (v5.9, Z en el aire junto a anillos) ---
// v5.9.1: declaradas AQUI (no lazy) porque el Step_2 y el Step_0 las
// leen en frames donde scr_move_basic aun no llego a correr su hook:
// el early-return de !isServerReady (conectar / practice) se salta el
// script entero y el "if(isLightDashing)" del Step_2 revienta con
// "not set before reading it" en el primer frame. Mismo pozo que el
// v4.9 documento para specialFunc; declararlo en el Create lo tapa
// para siempre. El bloque lazy del script queda como red de seguridad
// para el resto de personajes (el hook de move_basic corre para todos).
isLightDashing = false;   // true mientras recorre la cadena de anillos
lightDashChain = [];      // la RUTA: anillos + waypoints del desvio (v5.10)
lightDashIdx = 0;         // indice del anillo objetivo actual
lightDashTime = 0;        // frames de vuelo (tope de seguridad)
lightDashDeg = 0;         // angulo de dibujo actual (grados)
lightDashFace = 1;        // mirada actual del sprite (1 = der, -1 = izq)
lightDashToX = 0;         // posicion objetivo de este frame
lightDashToY = 0;
lightDashVX = 0;          // velocidad del tramo (para la red y la salida)
lightDashVY = 0;
lightDashGhostTimer = 0;  // v5.9.1: contador de la estela (lo usa scr_light_dash_ghost)
lightDashAim = [];        // v5.9.2: cadena visible para la FLECHA (Draw_0)
lightDashAimLife = 0;     // v5.9.2: vida de la flecha (caduca sola, 1 frame)
lightDashAimX = 0;        // v5.10: primer punto de la RUTA (flecha; con
                         // desvio A* es el primer quiebre, no el anillo)
lightDashAimY = 0;
lightDashAimDir = 0;      // v5.10: direccion del primer tramo de la ruta
isLSA = false;            // v6.0: true mientras el vuelo es un LSA (C, ataque)
lightDashBrakeLatch = 0;  // v6.0: frames de silencio del impulso de tarot tras frenar el dash con X

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

// ABRAZO COMBINADO (interaccion especial con Sonic, tecla del EMOTE 3
// cerca de el): mientras dura, el estado de red es AMY_CANON_HUG y su
// cuerpo no se dibuja: Draw_0 pinta el sprite combinado (spr_amy_hug_canon)
// en el punto medio con Sonic. Ver scr_amy_hug.gml.
hugActive = false;   // true mientras esta abrazando
hugPartner = noone;  // el puppet del Sonic que abraza
hugSide = 1;         // 1 = Amy quedo a la IZQUIERDA de Sonic (sprite tal cual)

// --- PARRY (tecla V): mismas fijaciones que el de Sonic (v4.0) ---
// La maquina de fases la corre scr_parry_step (la llama el Step_0);
// los estados de red son los 60/61/64 compartidos y el HUD es el 4o
// icono de su fila (obj_playerui). Ver scr_parry.gml.
parryState = 0;       // 0=nada, 1=windup, 2=ventana activa, 4=exito
parryTimer = 0;       // frames que le quedan a la fase actual
parryCooldown = 0;    // frames restantes de recarga
parryCooldownMax = 1; // duracion total del CD activo (lo lee el icono del HUD; 1 = evita /0)
parrySuccess = false; // true si la ventana intercepto algo
parryActive = false;  // true durante ventana+gracia (lo leen los checks de red)
parryFlash = 0;       // frames restantes del anillo de activacion (lo dibuja Draw_0)
parryLateSignal = 0;  // margen tras cerrar la ventana para la senal de exito que llega por red

// Stubs para el scr_parry_step COMPARTIDO con Sonic (el mismo codigo
// corre en los dos): Sonic si tiene Nervios de Acero (nerviosState/
// nerviosUsed) y spindash (isSpinCharging); Amy Canon no, asi que aqui
// valen neutro y todas las condiciones le quedan en paz.
nerviosState = 0;       // Amy no tiene Nervios de Acero
nerviosUsed = false;    // ... ni fase powerboost: CDs normales siempre
isSpinCharging = false; // ... ni spindash
spinCharge = 0;

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

// Sensores pasivos de Amy Canon (solo en SU cliente): flecha verde hacia
// la salida + flecha azul hacia el exe. Ver obj_amycanon_indicators.
instance_create_depth(x, y, 0, obj_amycanon_indicators);