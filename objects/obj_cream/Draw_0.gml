if(effectTime > 0)
{
	effectTime--;
	
	if(effectTime % 3 == 0)
	{
		var inst = scr_effect_fade_quick(x, y, sprite_index);
		inst.depth = depth + 10;
		inst.image_xscale = image_xscale;
		inst.image_index = image_index;
		inst.image_speed = 0;
		inst.palleteFrom = global.palleteFrom;
		inst.palleteTo = global.palleteTo;
	}
}

//Actual draw
// v8 (NEGAGEN, toque negativo): SUBDITO NEGATIVO local — el cuerpo
// se dibuja INVERTIDO (shd_negative), no con la paleta demon: es el
// look canon de Negagen, verificado pixel a pixel contra los
// spr_amynega_* / spr_eggnega_* del build original.
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
{
	shader_set(shd_negative);
		draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
	shader_reset();
}
else
{
	scr_palette_swap(global.palleteFrom, global.palleteTo);
	draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
	shader_reset();
}