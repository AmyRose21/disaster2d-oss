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

// JINNA: agarre (tecla V)
jinnaGrabCd = 0;       // enfriamiento restante
jinnaGrabVisual = 0;   // frames de pose de agarre (attack2)

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
