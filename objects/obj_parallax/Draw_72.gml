/*
	КАК ИСПОЛЬЗОВАТЬ:
	в коде создания комнаты сделать лист всех слоев и их скоростей:
	
	формат:
	[ id слоя, х-скорость, у-скорость, y offset (опцианально) ]
	
	пример:
	global.parallax = 
	[
		[ layer_get_id("Background"), 0.3, 0 ]
	];
*/
// v1.2 OPTIONS MORE: BACKGROUNDS off = ademas quita el heat haze de las
// capas de nivel (tiles/assets). Sin el fondo del escenario, la
// distorsion animada del filtro se nota como un "barrido" sobre el negro
// del fondo solido, y cada filtro es un pase de shader a pantalla
// completa (el juego original ya los quita en Android por lo mismo).
// Solo VV y AI ponen heat haze en capas que siguen visibles con el
// toggle activado; se limpia una sola vez por entrada a la sala porque
// layer_clear_fx no se puede deshacer sin recargarla.
if(!obj_config.optBackgrounds && !bgFxDone)
{
	bgFxDone = true;
	
	var _fxl;
	switch(room)
	{
		case room_volcanovalley:
			_fxl = ["Tiles", "Tiles2", "TilesFore", "Assets_1", "Assets_2", "Bochki"];
			break;
		
		case room_angelisland:
			_fxl = ["Tiles", "TilesFore", "Assets_1", "Assets_2"];
			break;
		
		default:
			_fxl = [];
			break;
	}
	
	for(var j = 0; j < array_length(_fxl); j++)
	{
		var _lid = layer_get_id(_fxl[j]);
		if(is_undefined(_lid) || _lid == -1)
			continue;
		
		layer_clear_fx(_lid);
	}
}

for(var i = 0; i < array_length(global.parallax); i++)
{
	var lay = global.parallax[i][0];
	var xspd = global.parallax[i][1];
	var yspd = global.parallax[i][2];
		
	// v1 OPTIONS MORE: BACKGROUNDS off = oculta las capas de fondo del
	// escenario (las de la lista de parallax de la room)
	if(!obj_config.optBackgrounds)
		layer_set_visible(lay, false);
	else if(!layer_get_visible(lay))
		layer_set_visible(lay, true);
	
	// v1 OPTIONS MORE: PARALLAX SCROLLING off = capas pegadas a la camara
	// (factor 1:1 en vez del de la room: se ven fijas en pantalla)
	if(!obj_config.optParallax)
	{
		xspd = 1;
		yspd = 1;
	}
	
	var cx, cy;
	if(array_length(global.parallax[i]) > 3)
	{
		var yoff = global.parallax[i][3];
		
		cx = camera_get_view_x(view_camera[0]);
		cy = camera_get_view_y(view_camera[0]) + yoff;
	}
	else
	{
		cx = camera_get_view_x(view_camera[0]);
		cy = camera_get_view_y(view_camera[0]);
	}
	
	layer_x(lay, cx * xspd);
	layer_y(lay, cy * yspd);
}