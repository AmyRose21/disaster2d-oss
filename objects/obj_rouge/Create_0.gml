// Default player values

// =====================================================================
//  ROUGE (v13 — REWORK DE LA DUEÑA): superviviente #15. Stats sin
//  cambio (misma agilidad aerea de siempre). VIDA TOTAL: 125 (antes
//  100 — ver scr_player_maxhp, el HUD y el netcode ya van por max).
//  Kit NUEVO (todo con sprites propios):
//   * Z en el aire  = VUELO (patron VANILLA, antes Tails): MANTENIENDO
//                     Z SUBE (ROUGE_FLY_RISE), SOLTANDO baja lento
//                     (ROUGE_FLY_GLIDE) — subir y bajar. Dura
//                     ROUGE_FLY_SOLO (5 s) y recarga en suelo
//                     ROUGE_FLY_RECHARGE (15 s). Sprite spr_rouge_fly.
//   * Abajo + Z en tierra = SPINDASH (reglas de SONIC): cada Z suma
//                     2 de carga (max 10, tono mas agudo por rev);
//                     quieto cargando, decay 1 cada 90 f sin pulsar;
//                     al SOLTAR abajo sale disparada (base 8 + carga)
//                     en bola con estela y mini-temblor. Carga con
//                     spr_rouge_spin_charger, lanzada con
//                     spr_rouge_spin_release.
//   * X (tierra)     = TORNADO (spr_rouge_attack2): arranca RAPIDA y
//                     va PERDIENDO velocidad, i-frames durante TODO
//                     el movimiento (patron tornado de Knuckles).
//                     Recarga 20 s (ROUGE_ATTACK_RECHARGE).
//  JAMAS se demoniza (regla canonica): igual que Amy Canon/Sally
//  Canon/Sonic/Vanilla (parche del server).
//
//  v4.5 — VIDAS (regla de la duena): 1 sola vida "blanda" (moribunda,
//  6 s tirada inmune y se levanta con 40 — sin cambio en v13).
//  PORTAL TRAMPA DE JINNA: absorbida (spr_rouge_traped) si el dano la
//  iba a dejar moribunda o muerta (sin cambio en v13).
// =====================================================================
#macro ROUGE_ATTACK_RECHARGE (60 * 20)     // v13: tornado (X)
#macro ROUGE_MAXSPEED 11
#macro ROUGE_ACC 0.046875

// v13 — VUELO patron VANILLA (subir y bajar): mismos numeros que Vanilla
#macro ROUGE_FLY_SOLO (60 * 5)        // duracion del vuelo: 5 s
#macro ROUGE_FLY_RISE -3.5            // subida MANTENIENDO Z
#macro ROUGE_FLY_GLIDE 1             // bajada suave SOLTANDO Z
#macro ROUGE_FLY_RECHARGE (60 * 15)  // recarga en suelo: 15 s

// v13 — SPINDASH (reglas de Sonic, mismos numeros)
#macro ROUGE_SPINDASH_BASE 8
#macro ROUGE_SPINDASH_REV 2
#macro ROUGE_SPINDASH_CHARGE_MAX 10
#macro ROUGE_SPINDASH_DECAY 90
#macro ROUGE_SPINDASH_START_MAX 2
#macro ROUGE_SPINDASH_PITCH_STEP 0.8
#macro ROUGE_SPINDASH_DUST_EVERY 10
#macro ROUGE_SPINDASH_BURST_MIN 3
#macro ROUGE_SPINDASH_BURST_MAX 8

// v13 — TORNADO (X): arranca rapida y decae hasta el minimo
#macro ROUGE_TORNADO_TIME (60 * 0.8)   // duracion total: 0.8 s
#macro ROUGE_TORNADO_START 12          // velocidad inicial
#macro ROUGE_TORNADO_MIN 1.5           // velocidad final (decae lineal)

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
// v12 (NEGAGEN): la marca de SUBDITO NEGATIVO se declara AQUI, no lazy.
// BUG v8-v11: el paquete de conversion escribia "global.player.isNegatouch
// = true" — una dot-escritura sobre el INDICE del objeto en una variable
// que NO existia en la instancia (GameMaker no la crea por esa via:
// escritura silenciosamente ineficaz en este runtime). El guard
// variable_instance_exists del Draw_76/Draw_64 local daba false SIEMPRE:
// el afectado se veia su propio sprite en SU pantalla mientras los demas
// clientes si veian el nega (el puppet declara la marca en su Create y
// el with() escribe por INSTANCIA). Declarada aqui, la escritura del
// paquete es una asignacion normal a una variable ya existente (como
// hp / revivalTimes, que siempre funcionaron) y el guard del Draw pasa
// tambien en la pantalla del convertido.
isNegatouch = false;
deadTimer = 31;
deadColor = c_white;
shockedTimer = 0;
reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
redRingTimer = 0;
deadTimer = 0;
glide_xspd = 0;
// v13 — VUELO patron VANILLA (subir y bajar): flyTimer es la PUERTA de
// recarga (0 o menos = listo; al despegar toma ROUGE_FLY_RECHARGE y
// cuenta hacia atras SOLO en el suelo, como Vanilla) y flyTimeout mide
// la DURACION del vuelo en el aire (tope ROUGE_FLY_SOLO).
flyTimer = 0;
flyTimeout = 0;
// v13 — SPINDASH (reglas de Sonic): carga por revolucadas + decay
isSpinCharging = false;
spinCharge = 0;
spinChargeDecay = 0;
spinRevSnd = -1;
spinDustTimer = 0;
spinDashRelease = false;   // true mientras la bola lanzada muestra spr_rouge_spin_release
// v13 — TORNADO (X): tornadoState > 0 = moviendose con i-frames
tornadoState = 0;
bounceTimer = 0;
shards = 0;
chunkX = -1000;
chunkY = -1000;
chunkTimer = 0;

//General
hp = 125; // v13: VIDA TOTAL de Rouge (antes 100) — ver scr_player_maxhp
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
