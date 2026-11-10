// ============================================================================
// v1 OPTIONS MORE: construir la pestana More (capa OptionsMore + filas +
// pestañas, y la pestaña MORE en General/Controls/Back). Se hace aqui, 1
// frame despues de crear la room, porque el patron de auto-curacion exige
// que TODAS las instancias de la room ya existan antes de buscar/duplicar.
// scr_menu_more_build() es idempotente. Igual que el fix v4.2 de special3.
// ============================================================================
scr_menu_more_build();

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
