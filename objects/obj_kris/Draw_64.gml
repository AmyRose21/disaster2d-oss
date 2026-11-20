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
	// Kris JAMAS se convierte en subdito negativo (regla), pero el
	// patron del guard es el mismo de los 15 supervivientes.
	if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
		draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr_nega : spr_hp_nega, frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);
	else
		draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr : spr_hp, revivalTimes == 2 ? 0 : frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);

	if(isSlow)
		draw_sprite(spr_frozen, 0, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset);

	if(obj_netclient.exeId != obj_netclient.nid && revivalTimes < 2)
		scr_number_spr(ceil(x-obj_camera.x) - 2, ceil(y-obj_camera.y) - offset - 12, string(global.player.rings), _colour);

	// v46 (LOVE): el LV de Kris por encima de su barra de vida (una
	// linea mas arriba que el contador de anillos). En rojo, mismo
	// patron de color del nombre del clon de Exeller (act9 lo apaga a
	// gris oscuro).
	if(variable_instance_exists(id, "krisLv") && krisLv > 0)
		scr_text_spr(ceil(x - obj_camera.x) - 14, ceil(y - obj_camera.y) - offset - 24, "lv " + string(krisLv), room == room_act9 ? c_dkgray : c_red, 1);
}