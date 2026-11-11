// =====================================================================
//  v3 (D.I.B.) — PORTAL TRAMPA de JINNA (cliente). Lo planta la V+ABAJO
//  (CLIENT_JINNA_TRAP): el server valida y spawnea la entidad JinnaTrap,
//  que replica el spawn a TODOS los clientes con este objeto (patron de
//  la trampa de Amelia). Es un portal (spr_jinna_portal) algo mas pequeno
//  que el del teleport, plantado en los pies de Jinna y con vida propia
//  (v4: 70 s, antes 20 s; la retirada real la manda el server con
//  state 1).
//
//  PISADA: cada cliente es la autoridad de su propio jugador — cuando el
//  jugador LOCAL superviviente (vivo, sin demonizar; el EXE y los
//  esbirros NO la activan) entra en el radio, este cliente avisa con
//  CLIENT_JINNA_TRAP_HIT y el server valida + reenvia los efectos
//  (SERVER_JINNA_TRAP_HIT): dano + teletransporte hasta Jinna SIN
//  i-frames... o la ABSORCION si la victima es Vanilla.
//
//  OJO: la pisada NO respeta i-frames (hurttime): orden de la duena —
//  "si este tenia I frame al momento de tocar la trampa recibira el
//  dano igual y se le removera" (el gate de hurttime vive en la victima
//  de los golpes, no aqui: la trampa se pisa igual estando invulnerable).
// =====================================================================
nid = 0;         // id de la entidad del server (SERVER_JINNA_TRAP_STATE)
life = JINNA_TRAP_LIFE; // vida visual (el remove real llega del server)
triggerSent = false;    // esta pisada ya fue reportada

// visual: mismo portal del teleport pero un 45% mas pequeno (se distingue
// del portal de huida a simple vista sin delatar la trampa del todo)
sprite_index = spr_jinna_portal;
image_speed = 20 / sprite_get_speed(spr_jinna_portal); // a 20 fps reales
image_xscale = 0.55;
image_yscale = 0.55;
depth = 5; // detras de los personajes: es un agujero en el suelo
