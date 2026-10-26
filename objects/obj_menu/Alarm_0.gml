// FIX PLACA INVISIBLE: si spr_menu_buttons compilo con la version vieja
// (solo 66 frames, sin el frame 66 "amy canon"), toda placa con
// image_index 66 quedaria invisible (frame fuera de rango). Respaldo:
// usar el frame 46 ("amy rose") para que la pagina nunca quede sin nombre.
if (sprite_get_number(spr_menu_buttons) <= 66)
{
	with(obj_menu_button)
	{
		if (image_index == 66)
			image_index = 46;
	}
}

buttonSelected(0, -1, 0, false);