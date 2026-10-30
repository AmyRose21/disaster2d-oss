// Default player values
depth = obj_spawnpoint.depth + 2;
//Variables
master_id = 0;
is_cheating = 0;

character = 0;
exeCharacter = 0;

hp = 100;
nickname = "";
nicknameWidth = 0;
rings = 0;
shards = 0;

isDemonized = false;
isAttacking = false;
isHurt = false;
reviveObj = noone;
revivalTimes = 0;
xspd = 0;
yspd = 0;
// isGrounded NO viaja por red: default defensivo para que leerlo en un
// puppet no reviente (lo hace obj_chocola para su sprite de movimiento)
isGrounded = true;
pX = x;
pY = y;
image_speed = 0;
isHiding = false;
hasRedRing = false;
powerBoost = false; // SONIC: powerboost de Nervios de Acero (bitflag de PLAYER_DATA)
ghostTimer = 0;     // contador de la estela de fantasmas
deadTimer = 31;
deadColor = c_white;

tailsCharge = 0;
sallyShield = false;
slimeMode = false;

isInactive = false;
state = 0;
angle = 0;
effect = false;
effectTimer = 0;
emitter = audio_emitter_create();
audio_emitter_falloff(emitter, 250, 500, 1);

reviveObj = instance_create_depth(x, y, 0, obj_revival_puppet);
healObj = instance_create_depth(x, y, 0, obj_heal_progress);

fromPallete = [ 0 ];
toPallete = [ 0 ];
petFromPallete = [ 0 ];
petToPallete = [ 0 ];

palleteName = "";

potater = false;
potatoTimer = 0;

// SALLY CANON fase 2: squash & stretch remoto (derivado del estado)
f2Sq = 0;
f2LastState = 0;