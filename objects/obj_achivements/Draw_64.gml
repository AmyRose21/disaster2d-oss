if(!boxSide)
{
	if(boxX > 0)
	{
		draw_sprite(spr_achivementbox, 0, boxX, 4);
		boxX -= 6;
	}
}
else
{
	if(boxX < 194)
		boxX += 6;
		
	draw_sprite(spr_achivementbox, 0, boxX, 4);
}

// [WELCOME PACK v1] Popup del paquete de bienvenida (solo instala limpia
// en Android — ver Create). Caja propia arriba-izquierda (mismo sitio que
// la de logros) que se desliza al entrar, aguanta ~4,7 s y se va; la
// moneda gira con los 26 frames de spr_mercoin. Texto en minusculas: la
// fuente pixel del juego (scr_text_spr) no tiene mayusculas.
if(welcomeTimer > 0)
{
	welcomeTimer--;

	// deslizamiento: 20 frames entrando, ~280 quieta, 20 saliendo
	var _wx = 4;
	if(welcomeTimer > 300)
		_wx = -140 + (144 * (320 - welcomeTimer) / 20);
	else if(welcomeTimer <= 20)
		_wx = 4 - (144 * (20 - welcomeTimer) / 20);

	draw_set_color(c_black);
	draw_set_alpha(0.85);
	draw_rectangle(_wx, 4, _wx + 134, 34, false);

	draw_set_color(c_white);
	draw_set_alpha(0.9);
	draw_rectangle(_wx, 4, _wx + 134, 34, true);

	draw_sprite(spr_mercoin, floor(current_time / 100) % sprite_get_number(spr_mercoin), _wx + 8, 9);
	scr_text_spr(_wx + 36, 9, "welcome pack", c_yellow, 1);
	scr_text_spr(_wx + 36, 18, $"+{welcomePack} mercoins", c_white, 1);

	draw_set_alpha(1);
	draw_set_color(c_white);
}