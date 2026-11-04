// =====================================================================
//  v2.15 («La Torre») — FLEETWAY AMY: flecha CLAVADA de la ballesta.
//  Hija de obj_solid_parent: sirve de PLATAFORMA durante 5 s
//  (FW_ARROW_STICK_TIME). El server la baja con SERVER_FWBOLT_STATE 2
//  (arrowDrop); el timer local es fallback si ese paquete se pierde.
//  Las flechas en vuelo chocan contra ella (hereda de solid): se
//  pueden apilar en torre, como en la wiki de Exe Nightmare.
// =====================================================================
fwId = -1;
arrowTimer = FW_ARROW_STICK_TIME;
arrowDrop = false;
image_speed = 0;
image_index = 0;
