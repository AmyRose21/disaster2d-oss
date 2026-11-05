// Default player values — Fleetway Amy (v2.14)
// Port de "The Disaster 2D Fleetway Amy" (GameJolt, idkjustsee):
// rework de Amy inspirado en Sally.exe Continued/Finished Nightmare.
// Fisica identica a Amy Canon (el mod original usa estos valores).

#macro FW_ATTACK_RECHARGE (60 * 20)     // puño/patada (tecla B) modo superviviente (20 s)
#macro FW_EATTACK_RECHARGE (60 * 5)     // puño/patada con revivalTimes >= 2 (5 s)

// v2.15 («La Torre») — rework de la BALLESTA (tecla C):
// cargador de 3 flechas, recarga de 8 s POR flecha y 0,5 s entre
// disparos. La flecha vuela recta, se CLAVA en paredes/suelos durante
// 5 s y sirve de plataforma (obj_fw_arrow, hijo de obj_solid_parent).
// Contra el EXE: stun de 3 s con reduccion acumulativa del 17,5% por
// stun continuo (tope 50%; se resetea tras 7 s sin stuns de flecha).
// Contra esbirros: siempre 3 s completos. Demonizada: daño 20 real.
#macro FW_ARROW_MAX 3                    // flechas del cargador
#macro FW_ARROW_RELOAD (60 * 8)          // recarga de cada flecha (8 s)
#macro FW_ARROW_SHOT_CD 30               // 0,5 s entre disparos
#macro FW_ARROW_STICK_TIME (60 * 5)      // clavada como plataforma (5 s)
#macro FW_ARROW_STUN (60 * 3)            // stun base de flecha al EXE (3 s)
#macro FW_ARROW_STUN_STEP 0.175          // -17,5% por stun continuo
#macro FW_ARROW_STUN_CAP 0.5             // tope de reduccion (50%)
#macro FW_ARROW_STUN_RESET (60 * 7)      // el % se resetea tras 7 s sin stun de flecha

// v2.15.1 — FIX «LA FLECHA TRASPASA LA PARED»: el vuelo lo simula cada
// cliente con barrido sub-pixel (el server NO conoce el mapa: sus ticks
// de posicion llegaban como teleports de 14 px y en las rafagas de UDP
// se saltaban la pared de un salto — el evento de colision de GM solo
// dispara si hay solape AL FINAL del frame). FW_ARROW_FLIGHT =
// FWBOLT_SPEED del server (14 px por tick a 60 tps = 14 px/frame).
#macro FW_ARROW_FLIGHT 14                // px por frame de vuelo local
#macro FW_ARROW_SWEEP 3.5                // sub-paso maximo del barrido (4 por frame)
#macro FW_ARROW_BURY 4                   // px de punta enterrada al clavarse (visual)

// v4.9 — MODO PARED: alcance en px desde Amy dentro del cual un muro real
// a la altura de los pies convierte el disparo en "flecha de escalada"
// (sale a los pies y se clava casi al instante, como en el video del
// juego original). Fuera de ese alcance el disparo es el normal (pecho,
// vuelo recto). Escanea de 12 en 12..FW_WALL_REACH px hacia donde mira.
#macro FW_WALL_REACH 48                  // px: distancia maxima del muro para el modo pared

// v2.15 («La Torre») — pasivas de Fleetway Amy:
// LA TORRE: bloqueo fijo del 33% del daño recibido (estilo Chocola
// con Vanilla, pero determinista). Con REFLEJO DE UNA MISMA ALMA
// (ver abajo) sube hasta un tope del 40%.
// El DJ doble salto aturde al EXE 3,2 s por contacto mientras vuela.
#macro FW_DJ_STUN (60 * 3.2)             // stun del DJ al exe (3,2 s)
#macro TOWER_BLOCK 0.33                  // La Torre: 33% de bloqueo
#macro TOWER_BLOCK_MAX 0.40              // tope de La Torre con Reflejo

// v2.15 — REFLEJO DE UNA MISMA ALMA (pasiva compartida de las Amys):
// por cada Amy en el campo (Amy, Amy Canon, Amelia o Fleetway) la
// eficacia de los efectos de sus pasivas sube un 5%, hasta un 15%.
// Afecta al bloqueo de La Torre (FW) y a la hitbox de FUERZA (Amy
// vanilla). Se define aqui pero lo usan los tres personajes
// (scr_amy_soul_* en scr_characters.gml).
#macro SOUL_STEP 0.05                    // +5% por Amy presente
#macro SOUL_CAP 0.15                     // tope +15%
#macro AMY_FUERZA_HITBOX 0.20            // FUERZA: hitbox +20% (Amy vanilla)

#macro FW_DJ_RECHARGE (60 * 10)         // DJ doble salto (tecla A aérea) superviviente (10 s)
#macro FW_EDJ_RECHARGE (60 * 15)        // DJ con revivalTimes >= 2 (15 s) — el revival lo SUBE (más vuelo)
#macro FW_DJ_BOOST -6                   // impulso vertical del DJ (yspd)
#macro FW_DJ_TIME 30                    // frames que dura el vuelo del DJ (djTimer de -1 a -30)
#macro FW_CB_TIME 120                   // frames con la ballesta en la mano tras disparar (2 s)
#macro FW_MAXSPEED 11
#macro FW_ACC 0.046875

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

// Fleetway: timers del moveset (nombres del mod original)
attackTimer = 0;     // puño/patada (tecla B)
djTimer = 0;         // DJ doble salto: 0 listo, -1..-30 volando, >0 recargando
crossBow = 0;        // v2.15: CD corto entre disparos (FW_ARROW_SHOT_CD)
cbTimer = 0;         // frames restantes con la ballesta EN LA MANO (sprites cbamy)
// v2.15 («La Torre»): cargador de la ballesta
fwArrows = FW_ARROW_MAX;        // flechas disponibles (0..3)
fwArrowReload = 0;              // recarga de la siguiente flecha (0 = cargador lleno)
// v2.14.1: paridad con obj_amy: el Step_0 portado lee isHJ en el guardia de
// daño de contacto (linea 48); sin declararlo el juego crashea con
// "isHJ not set before reading it". En Fleetway nunca se activa (el salto
// de martillo lo reemplaza el DJ) pero la variable tiene que existir.
hjumpTimer = 0;      // sin salto de martillo: siempre a 0
isHJ = false;        // idem: Step_0 lo lee, nada lo activa

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

// Fleetway: flags del moveset
isDJ = false;        // volando con el DJ doble salto
isCB = false;        // llevando la ballesta en la mano (cbTimer > 0)
afterCB = false;     // post-disparo (transición)
attackNum = 0;       // alterna puño (attack1) / patada (attack2)

//Character flags (constants)
canLookDown = true;
canLookUp = true;
canSpinDash = true;
canSpin = false;
specialFunc = scr_amy_fleetway_special; /* Function with abilities */

//constants (física del mod original: veloz como Amy Canon)
acc = FW_ACC;
maxHSpeed = FW_MAXSPEED;
maxYSpeed = 12;
yAccel = 0.21875; //gravity
jumpForce = 7;
isSlow = false;
doubleJump = false;

// Create sensors
instance_create_depth(x, y, 0, obj_player_sensorTL);
instance_create_depth(x, y, 0, obj_player_sensorTR);
instance_create_depth(x, y, 0, obj_player_sensorL);
instance_create_depth(x, y, 0, obj_player_sensorR);
instance_create_depth(x, y, 0, obj_player_sensorBL);
instance_create_depth(x, y, 0, obj_player_sensorBR);
instance_create_depth(x, y, 0, obj_player_sensorAL);
instance_create_depth(x, y, 0, obj_player_sensorAR);
