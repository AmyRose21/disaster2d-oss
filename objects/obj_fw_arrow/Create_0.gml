// =====================================================================
//  v2.15 («La Torre») — FLEETWAY AMY: flecha CLAVADA de la ballesta.
//  v4.9 — PLATAFORMA SALTABLE (como en el video del juego original):
//  ahora cuelga de obj_platform_jumptrough, NO de obj_solid_parent. Se
//  comporta como los pisos atravesables del juego: saltas desde abajo,
//  la ATRAVIESAS subiendo y aterrizas ENCIMA al caer — ya no es un
//  muro/techo que te rebota contra el suelo. Dura FW_ARROW_STICK_TIME
//  (5 s); el server la baja con SERVER_FWBOLT_STATE 2 (arrowDrop) y el
//  timer local es fallback si ese paquete se pierde. Las flechas en
//  vuelo TAMPOCO la sienten (scr_fw_wall_at excluye la familia
//  saltable): se clavan en el MURO de detras, como en el original.
// =====================================================================
fwId = -1;
arrowTimer = FW_ARROW_STICK_TIME;
arrowDrop = false;
image_speed = 0;
image_index = 0;
