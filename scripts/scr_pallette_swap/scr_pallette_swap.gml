function scr_palette_swap(palleteIn, palleteOut)
{
	// v52 (fix "Illegal array count"): en super forma los fantasmas
	// (estela del LSA/light dash y el del Draw) viajan SIN paleta ([])
	// porque los sprites super ya traen los colores horneados.
	// shader_set_uniform_f_array con un array VACIO crashea, asi que
	// aqui se sale temprano sin poner ningun shader: el draw del caller
	// dibuja tal cual y su shader_reset() queda inocuo (igual que en el
	// Draw_0 de Amy canon con la super activa).
	if(!array_length(palleteIn) || !array_length(palleteOut))
		return;

	shader_set(shd_colour);
	
	var arr = shader_get_uniform(shd_colour, "u_Pattern");
	shader_set_uniform_f_array(arr, palleteIn);
	
	var arr2 = shader_get_uniform(shd_colour, "u_Replacements");
	shader_set_uniform_f_array(arr2, palleteOut);
	
	var cnt = shader_get_uniform(shd_colour, "u_ColourCount");
	shader_set_uniform_i(cnt, array_length(palleteIn) / 4);
}