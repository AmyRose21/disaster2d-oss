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

// v82 (duena): NOMBRE DE LA FORMA CYBER bajo la barra de vida (mismo sitio
// y estilo que el modo de Rouge). Solo en SEMI CYBER / CYBER COMPLETA: en
// NORMAL no se escribe nada. Brilla mientras dura el destello del cambio.
if(cyberForm > 0 && revivalTimes < 2 && hp > 0)
{
	var _cyName = "SEMI CYBER";
	var _cyCol = $35D9FF;

	if(cyberForm >= SALLY_CYBER_FORM_FULL)
	{
		_cyName = "CYBER";
		_cyCol = $C6FDFF;
	}

	draw_set_font(fnt_big);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_transformed_color(ceil(x - obj_camera.x), ceil(y - obj_camera.y) - offset + 12, _cyName, 0.4, 0.4, 0, _cyCol, _cyCol, _cyCol, _cyCol, cyberFlash > 0 ? 1 : 0.7);
}