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
// v6 (minions de Jinna): true mientras este jugador es un MINION activo
// (invocado por el ↓+C de Jinna): su barra de HP muestra la vida REAL
// (frame por hp, no la barra vacia del esbirro comun) y los golpes de
// los supervivientes le hacen 20 de dano (lo aplica el cliente del
// propio minion). Lo setean los handlers de SERVER_JINNA_MINION_STATE /
// SERVER_JINNA_MINION_DOWN en net_state_game (todos los clientes).
isMinion = false;
// v7 (toque negativo): true cuando este jugador es un SÚBDITO NEGATIVO
// (convertido por la energia negativa de Jinna, el modo alternativo de
// Negagen): su golpe pega 15 en vez de 20 ("negative characters are
// weaker than usual"). Lo pone el handler de SERVER_JINNA_NEGATOUCH_STATE
// en net_state_game (todos los clientes).
// v9: tambien lo llevan los MINIONS invocados del portal — mismo LOOK
// negativo (shd_negative), pero golpe de 20 y vuelta al portal al caer:
// son minions plenos (los marca SERVER_JINNA_MINION_STATE igual).
isNegatouch = false;
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
isDJ = false; // v2.15 «La Torre»: FW Amy volando con el DJ (bitflag PLAYER_DJ)

isInactive = false;
state = 0;
angle = 0;
effect = false;
effectTimer = 0;

// v2.13 (LUNA de «Sol y Luna»): velo de gracia de Amelia. Al OCULTARSE
// (flanco de subida de isHiding, que cada cliente deriva igual), los
// primeros 3 s ni indicadores ni sensores del EXE la marcan; CD 15 s.
// Lo calcula el Step de este puppet en CADA cliente (solo lo consume
// el bando EXE). Pasado el velo: indicable pero cuerpo invisible (EXE).
lunaGrace = 0;
lunaGraceCd = 0;
lunaWasHiding = false;

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

// SALLY CANON fase DUELISTA (v5.4): la marca llega con el bitflag
// PLAYER_POWERBOOST (sticky: una vez vista, se queda hasta el fin de
// la ronda) y las dos patadas de la patada en tierra (estado 22) se
// anotan aqui para no golpear 2 veces con la misma ventana.
duelista = false;   // true tras su 1ra caida (fase duelista activa)
f2atkHit1 = false;  // la 1a patada (frames 0-6) ya golpeo en esta ejecucion
f2atkHit2 = false;  // la 2a patada (frames 7+) ya golpeo en esta ejecucion

// SALLY CANON POSES DEL ESCUDO (v5.8): contador propio de la
// animacion de ACTIVACION (un solo pase al pulsar la habilidad; el
// flanco de subida del bitflag la dispara en el Step de este
// puppet). Mismas variables que el jugador local.
shieldPoseOn = false;
shieldPoseSpr = -1;
shieldPoseCat = -1;     // 0 = tierra / 1 = agachada / 2 = aire
shieldPoseT = 0;
shieldPosePrev = false; // valor anterior de sallyShield (flanco)