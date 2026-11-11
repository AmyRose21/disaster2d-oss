// Efecto de AGARRE de JINNA sobre la victima (visual + bloqueo).
// Lo crea el cliente de CADA jugador al recibir SERVER_JINNA_GRAB_STATE
// (net_state_game): en el cliente de la VICTIMA ademas congela a su
// jugador real (locked=true; mismo lado que el stun: la victima es la
// autoridad de su propio movimiento). Plantilla del finishGrab del mod
// (gml_Script_finishGrab@obj_jinna_grab_effect_Create_0 del data.win).
//
// El bloqueo usa global.playerControls (el gate de input de la casa: lo
// revisan scr_move_basic y todos los especiales) y solo se devuelve si
// NOSOTROS lo quitamos (tookControl): no pisa los cortes de fin de
// ronda, que tambien lo apagan.
locked = false;      // solo lo pone en true el cliente de la victima
target = noone;      // puppet de la victima (lo asigna quien lo crea)
tookControl = false; // nosotros apagamos el control de la victima
timer = JINNA_GRAB_LOCK; // frames de bloqueo restantes
alarm[0] = JINNA_GRAB_LOCK + 8; // el efecto vive el bloqueo + colchon
