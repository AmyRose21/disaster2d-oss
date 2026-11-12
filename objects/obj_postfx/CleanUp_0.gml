/// Al destruirse el controlador (cierre del juego), devolver el
/// control de la app surface al motor y liberar las superficies.
application_surface_draw_enable(true);

if(surface_exists(surfA))
	surface_free(surfA);
if(surface_exists(surfB))
	surface_free(surfB);