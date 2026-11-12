/// F9 activa/desactiva el post-proceso (solo visual, para comparar).
if(keyboard_check_pressed(vk_f9))
{
	enabled = !enabled;

	// apagado = el motor vuelve a dibujar la app surface el solo
	application_surface_draw_enable(!enabled);
}