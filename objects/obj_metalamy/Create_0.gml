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

// METAL AMY v4.7/v4.8/v4.10: scan (tecla V)
scanTimer = 0;    // revelado activo (V manual: METALAMY_SCAN_TIME, 12 s · cazadora: METALAMY_HUNT_WINDOW, 8 s)
scanRecharge = 0; // enfriamiento restante (20 s)
scanPose = 0;     // frames de pose de escaneo restantes

// METAL AMY v4.8 — MARCA DE LA CAZADORA (pasiva 3): con 1 solo
// superviviente vivo la V se apaga y el rastreo sale solo (8 s cada 14 s)
huntMode = false; // activo mientras quede exactamente 1 vivo
huntCd = 0;       // enfriamiento del ciclo pasivo (arranca al cerrar la ventana)

// METAL AMY v4.8 — ADAPTABILIDAD (pasiva 4): stun dentro de los 3 s
// posteriores a perder la inmunidad por golpe -> +1 carga del dash
adaptWindow = 0;  // frames restantes de la ventana abierta
adaptAfter = false; // la inmunidad (hurttime) estaba activa el frame anterior
wasShocked = false; // venia stuneada el frame anterior (deteccion de arranque)

// METAL AMY v4.6: dash de 8 direcciones (tecla X)
dashDirX = 0;      // -1 / 0 / 1 de la ultima embestida
dashDirY = 0;      // -1 / 0 / 1 de la ultima embestida
dashCharges = METALAMY_DASH_MAX; // nace con las 3 cargas
dashRecharge = 0;  // progreso de la carga en curso (5 s por carga)
dashBoost = 0;     // frames de impulso restantes del dash actual

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
