// Portal de JINNA (visual puro, sin colision): 20 frames a 20 fps
// (spr_jinna_portal, origin abajo-centro: se planta en los pies). Lo
// crea su propia cliente al salir Y la replica del server para todos
// (SERVER_JINNA_PORTAL_STATE) al llegar.
// v4.2 — SALIDA ELEGANTE (solo visual, pedido de la duena): al terminar,
// el portal NO revienta: se HACE MAS PEQUENO hasta desaparecer (ver
// Alarm_0 + Draw_0), igual que la fase 1 del obj_jinna_absorb cuando
// atrapa a Vanilla.
image_speed = 20 / sprite_get_speed(spr_jinna_portal); // a 20 fps reales
depth = -50; // sobre el jugador, bajo el HUD

shrink = 0; // v4.2: frames de encogido restantes (0 = animacion normal)

alarm[0] = 26; // los 20 frames + colchon
