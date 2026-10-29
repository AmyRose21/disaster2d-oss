// FIX PLACA INVISIBLE: si spr_menu_buttons compilo con la version vieja
// (solo 66 frames, sin el frame 66 "amy canon"), toda placa con
// image_index 66 quedaria invisible (frame fuera de rango). Respaldo:
// usar el frame 46 ("amy rose") para que la pagina nunca quede sin nombre.
// v4.2: lo mismo para el frame 67 ("special 3" de la fila de la V del
// parry de Amy Canon): respaldo al 20 ("special 2") mientras el sprite
// quede viejo; con el sprite importado sale el label correcto.
if (sprite_get_number(spr_menu_buttons) <= 66)
{
	with(obj_menu_button)
	{
		if (image_index == 66)
			image_index = 46;
	}
}

if (sprite_get_number(spr_menu_buttons) <= 67)
{
	with(obj_menu_button)
	{
		if (image_index == 67)
			image_index = 20;
	}
}

buttonSelected(0, -1, 0, false);
