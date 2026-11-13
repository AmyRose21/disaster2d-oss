// =====================================================================
//  JINNA (v1, killer rescatado de TD2DR Darkness In Blood / D.I.B.,
//  GameJolt 1104339 de DIFFF). 6.a asesina (EXE_JINNA = 5).
//
//  Kit (descripcion oficial del mod, ver AboutJinna): "jinna is a fast
//  killer who uses portals and demonic magic to control the chase. she
//  can teleport toward the nearest survivor [...] her grab can lock a
//  survivor in place for a short time [...] with her speed, direct
//  attack and sudden repositioning [...]".
//   * VELOCIDAD: la mas rapida del bando EXE (13; Exe/Exeller van a 12).
//   * GOLPE (X): patron del exe basico con COMMIT (JINNA_ATTACK_LOCK):
//     el swing frena el impulso unos frames — golpe honesto, no drive-by.
//   * TELETRANSPORTE (C, scr_jinna_special): portales gemelos + pose de
//     tele + flecha (spr_jinna_clonearrow) sobre el objetivo durante el
//     telegraph. Reusa el grace de anticheat del server (ex_teleport).
//   * AGARRE (V, scr_jinna_special): bloquea al superviviente 1,6 s
//     (obj_jinna_grab_effect en la victima) + 10 de dano ("1 HP" en su
//     placa oficial).
//  Macros en scr_jinna_special. Estados propios en Step_2 (plantilla
//  obj_metalamy / obj_exeller).
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

// JINNA: commit del golpe (el swing frena el impulso)
jinnaAttackLock = 0;

// JINNA: teletransporte (tecla C)
jinnaTeleCd = 0;       // enfriamiento restante
jinnaTeleWindup = 0;   // frames de telegraph (flecha sobre el objetivo)
jinnaTeleTarget = noone; // puppet objetivo durante el telegraph
jinnaTelePose = 0;     // frames de pose de tele tras aterrizar

// JINNA: agarre (tecla V) / portal trampa (V + ABAJO)
jinnaGrabCd = 0;       // enfriamiento restante del AGARRE
jinnaGrabVisual = 0;   // frames de pose de agarre (attack2)
jinnaTrapCd = 0;       // v4: enfriamiento restante del PORTAL TRAMPA (independiente del agarre)
jinnaTrapVisual = 0;   // v4: frames de pose al PLANTAR la trampa (spr_jinna_tele, ver Step_2)

// JINNA v6 — INVOCACION DE MINIONS (tecla C + ABAJO): todos los
// atrapados en el portal (capturas del portal trampa) se materializan
// a sus pies como esbirros con VIDA REAL. Recarga propia de 25 s que
// solo se paga si habia alguien que invocar (lo decide el server).
jinnaMinionCd = 0;     // enfriamiento restante de la INVOCACION (independiente del teleport)
jinnaMinionPose = 0;   // frames de pose al invocar (spr_jinna_tele, mismo patron que la trampa)

// JINNA v3 — ADAPTACION A ATURDIMIENTOS (pasiva de lore): cada stun que
// recibe le ensena a resistirlos: +10% de resistencia por stun recibido
// (tope 50%). La resistencia RECORTEA la duracion de cada stun NUEVO (el
// primero entra entero; del segundo en adelante cada vez mas corto). No
// decae: se resetea al empezar la ronda.
jinnaStunResist = 0;   // 0..50 (%)
jinnaShockNext = 0;    // valor esperado de shockedTimer el proximo frame (deteccion de stuns NUEVOS)

// JINNA v3/v4 — ATRAPADA EN EL PORTAL TRAMPA: cuando Vanilla, AMY CANON
// o SALLY CANON (v4.1) caen en el portal trampa, sobre la cabeza de
// Jinna aparece su senal (solo visible para SU jugadora) tras la
// animacion de absorcion. jinnaCaughtDelay cuenta esa espera (~1,7 s)
// y jinnaCaughtShow la deja fijada hasta el fin de ronda; dibujado en
// Draw_0. jinnaCaughtKind es el TIER de potenciacion (JINNA_CAUGHT_NONE
// /AMY/VANILLA = 0/1/2 en scr_jinna_special): Amy y Sally Canon son el
// tier "arduas" (la mitad de los aumentos) y Vanilla el fuerte. El
// sprite concreto de la senal viaja en jinnaCaughtSprite (pantalla de
// Vanilla o pose canon de Amy/Sally semi-transparente).
jinnaCaughtDelay = 0;    // frames hasta mostrar a la atrapada (0 = nada pendiente)
jinnaCaughtShow = false; // true = la atrapada ya esta dibujada sobre su cabeza
jinnaCaughtKind = JINNA_CAUGHT_NONE; // tier: 0 = nadie / 1 = Amy o Sally (arduas) / 2 = Vanilla (fuerte)
jinnaCaughtSprite = spr_vanilla_caught; // v4.1: sprite de la senal (Vanilla / Amy / Sally Canon, lo fija el handler del paquete)

// JINNA: misc
jinnaGoSnd = false;            // la linea de arranque suena 1 vez (ver Step_0)
jinnaWonSnd = false;           // la linea de victoria suena 1 vez
jinnaLostState = choose(JINNA_LOST, JINNA_LOST2); // derrota aleatoria (patron chaos)

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

// taunts (tjinna0/tjinna1: los mismos IDs de trade del mod original)
taunt1 = array_contains(obj_unlockables.trades, "tjinna0");
taunt2 = array_contains(obj_unlockables.trades, "tjinna1");

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = false;
canSpin = true;
specialFunc = scr_jinna_special; /* Function with abilities */

//constants
acc = JINNA_ACC;
maxHSpeed = JINNA_MAXSPEED;
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
