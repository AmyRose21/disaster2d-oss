// Portal de JINNA (visual puro, sin colision): 20 frames a 20 fps
// (spr_jinna_portal, origin abajo-centro: se planta en los pies). Lo
// crea su propia cliente al salir Y la replica del server para todos
// (SERVER_JINNA_PORTAL_STATE) al llegar.
image_speed = 20 / sprite_get_speed(spr_jinna_portal); // a 20 fps reales
depth = -50; // sobre el jugador, bajo el HUD

alarm[0] = 26; // los 20 frames + colchon
