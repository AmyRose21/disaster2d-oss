var offset = 25;
if(hp > 0)
{
	var frame = 5;
	
	if(hp >= 100)
		frame = 5;
	else if(hp >= 75)
		frame = 4;
	else if(hp >= 50)
		frame = 3;
	else if(hp >= 25)
		frame = 2;
	else if(hp > 0)
		frame = 1
	else
		frame = 0;
	
	var _colour = room == room_act9 ? c_dkgray : c_white;
	// v11 (NEGAGEN): el SUBDITO NEGATIVO usa la BARRA NEGA propia
	// (spr_hp_nega: inversion de su barra con el contorno intacto)
	// con SU vida real (frame por hp), sin shader. El esbirro comun
	// sigue con su frame 0 fijo rojo.
	if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
		draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr_nega : spr_hp_nega, frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);
	else
		draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr : spr_hp, revivalTimes == 2 ? 0 : frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);
	
	if(isSlow)
		draw_sprite(spr_frozen, 0, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset);
	
	if(obj_netclient.exeId != obj_netclient.nid && revivalTimes < 2)
		scr_number_spr(ceil(x-obj_camera.x) - 2, ceil(y-obj_camera.y) - offset - 12, string(global.player.rings), _colour);
}
// ============================================================================
// v25 — RADAR DE LA SALIDA (flecha verde, patron AMY CANON, pedido de la
// duena): mientras exista el ANILLO DE ESCAPE (obj_bigring), Rouge lleva
// pegada una flecha verde (spr_sindicator2, la del indicador del juego)
// que apunta al anillo MAS CERCANO — mismo anclaje y sprite que la de
// Amy Canon (obj_amycanon_indicators). Informacion PURA del cliente
// local (obj_rouge solo existe como jugador local; los ajenos son
// puppets): cero paquetes, cero servidor, nadie mas la ve. La flecha
// ROJA del exe NO va: esa es la exclusiva de Amy Canon — Rouge pidió
// solo el radar del anillo. Demonizada (red de seguridad, nunca pasa):
// apagada para no duplicar la flecha estandar del juego.
// ============================================================================
if(hp > 0 && revivalTimes < 2 && instance_exists(obj_bigring))
{
	var _ring = instance_nearest(x, y, obj_bigring);

	if(_ring != noone)
		draw_sprite_ext(spr_sindicator2, 0, ceil(x - obj_camera.x), ceil(y - obj_camera.y), 1, 1, point_direction(x, y, _ring.x, _ring.y), c_white, 1);
}

// ============================================================================
// v91 (duena) — MODALIDAD ACTIVA (HABILIDAD V): REWORK DE VISIBILIDAD.
// El nombre del set bajo la barra de vida ahora se lee DE UN VISTAZO:
//  * TEXTO UN 50% MAS GRANDE: escala 0.4 -> 0.6 (la letra de fnt_big
//    mide 18 px: antes quedaba en ~7 px, ahora ~11 px).
//  * CONTORNO NEGRO grueso (8 pasadas de 1 px alrededor, tecnica
//    clasica): el color ya no se funde con fondos claros ni con su
//    propio cuerpo — se lee igual sobre cielo, hierba o su sprite.
//  * REPOSO MAS BRILLANTE: alpha 0.55 -> 0.9 (el "tono suave" lavaba
//    el nombre y costaba saber que set llevaba puesto).
//  * Al ciclarla (modeFlash): sale un pelin MAS GRANDE todavia (0.7)
//    a tope de brillo, y en los ultimos 12 frames del destello el
//    tamano baja SUAVE hasta el de reposo — el cambio se nota, sin
//    salto brusco. Sigue fija SIEMPRE para saber que X/C lleva.
// Solo la pantalla de la jugadora (el ciclo no viaja: cada habilidad
// se delata sola cuando la usa, no por llevar el set puesto).
// ============================================================================
if(hp > 0 && !isDead)
{
	var _modeName = "ROUGE";
	var _modeCol = $F2A0C8;

	switch(rougeMode)
	{
		case ROUGE_MODE_EGGMAN:  _modeName = "EGGMAN";  _modeCol = $FFD24A; break;
		case ROUGE_MODE_SUPPORT: _modeName = "SOPORTE"; _modeCol = $6EDD62; break;
		case ROUGE_MODE_ATTACK:  _modeName = "ATAQUE";  _modeCol = $FF8A3D; break;
	}

	var _modeX = ceil(x - obj_camera.x);
	var _modeY = ceil(y - obj_camera.y) - offset + 12;

	draw_set_font(fnt_big);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _modeScale = 0.6 + 0.1 * min(modeFlash / 12, 1);
	var _modeAlpha = modeFlash > 0 ? 1 : 0.9;

	// contorno negro (4 cardinales + 4 diagonales, 1 px cada uno)
	draw_text_transformed_color(_modeX + 1, _modeY, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX - 1, _modeY, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX, _modeY + 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX, _modeY - 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX + 1, _modeY + 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX - 1, _modeY + 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX + 1, _modeY - 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);
	draw_text_transformed_color(_modeX - 1, _modeY - 1, _modeName, _modeScale, _modeScale, 0, c_black, c_black, c_black, c_black, _modeAlpha);

	// el nombre de color, encima del contorno
	draw_text_transformed_color(_modeX, _modeY, _modeName, _modeScale, _modeScale, 0, _modeCol, _modeCol, _modeCol, _modeCol, _modeAlpha);
}
