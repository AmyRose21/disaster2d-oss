if(effectTime > 0)
{
	effectTime--;
	
	if(effectTime % 3 == 0)
	{
		var inst = scr_effect_fade_quick(x, y, sprite_index);
		inst.image_xscale = image_xscale;
		inst.image_index = image_index;
		inst.image_speed = 0;
		inst.depth = depth+10;
		inst.palleteFrom = global.palleteFrom;
		inst.palleteTo = global.palleteTo;
	}
}

// FASE 2: SQUASH & STRETCH (solo pt3/pt4). fase2Sq > 0 = estirada
// (despegue del salto), fase2Sq < 0 = aplastada (aterrizaje). Rebota
// sola a 0 (scr_sally_canon_fase2). La escala se ancla al SUELO: los
// pies quedan plantados y el cuerpo se estira/aplasta hacia arriba.
var _f2xs = image_xscale;
var _f2ys = image_yscale;
var _f2yoff = 0;

if(fase2Sq != 0)
{
	_f2ys = image_yscale * (1 + fase2Sq);
	_f2xs = image_xscale * (1 - fase2Sq * 0.6);
	_f2yoff = (sprite_height - sprite_yoffset) * (1 - _f2ys);
}

//Actual draw

scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

if(shieldTimer > 0)
	draw_sprite(spr_sallyshield_canon, (current_time / 30) % 41, floor(x), floor(y));
