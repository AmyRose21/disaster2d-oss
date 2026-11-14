// =====================================================================
//  v3/v4 (D.I.B.) — ABSORCION DEL PORTAL TRAMPA de JINNA (Vanilla o,
//  desde la v4, AMY CANON). Lo crea SOLO el cliente de la propia
//  victima al recibir SERVER_JINNA_TRAP_HIT kind 1/2 (net_state_game):
//  ella callo en la trampa y es succionada a LA OTRA DIMENSION.
//
//  Secuencia (todo local, en su cliente):
//   * Fase 0 (~1,2 s): su sprite se hace mas pequeno hasta desaparecer
//     EN EL CENTRO del portal (que sigue abierto: no se va inmediatamente).
//     v4: el sprite de la victima llega en absorbVictim — Vanilla usa su
//     spr_vanilla_absorb_trap y Amy Canon su pose de secuestro
//     (spr_amy_capture_canon: ella aun no tiene arte de absorcion propio).
//   * Fase 1 (~0,5 s): el portal se encoge hasta eliminarse.
//   * Fin: FUERA DE JUEGO — el flujo estandar de MUERTE DIRECTA de la
//     victima (paquete CLIENT_PLAYER_DEATH_STATE + isDead + camara de
//     espectador), SIN sus salvaciones de paciencia/moribunda (la
//     absorcion no es dano: es la trampa). Su UI queda como si hubiera
//     muerto ("muerta sin estar muerta"). El server la marca
//     PLAYER_DEAD: la partida la considera fuera, no cuenta para el
//     win del EXE pendiente y nadie puede revivirla.
//
//  Mientras tanto (los demas clientes): su puppet se oculta al vuelo en
//  el handler del paquete y los flags de mejora por especial (v18) activan
//  en TODOS los clientes los aumentos ACUMULATIVOS del kit de Jinna; sobre
//  la cabeza de la propia Jinna aparece su senal — o su MUNECO en la fila
//  acumulativa de especiales — (solo en SU cliente).
//
//  jinnaX/jinnaY llegan por si el futuro pide un efecto hacia ella.
// =====================================================================
phase = 0;        // 0 = encogiendo a la victima, 1 = encogiendo el portal
timer = 72;       // frames de la fase 0 (~1,2 s)
portalScale = 0.55; // misma escala visual del obj_jinna_trap
tookControl = false; // nosotros apagamos el control de la victima
jinnaX = 0;
jinnaY = 0;
absorbSnd = false;
absorbVictim = spr_vanilla_absorb_trap; // v4: sprite de quien se absorbe (Amy Canon: spr_amy_capture_canon)

depth = -50; // la absorcion se dibuja SOBRE todo lo demas
