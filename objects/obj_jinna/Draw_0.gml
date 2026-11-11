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

//Actual draw
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding || shockedTimer > 0) ? 0.5 : image_alpha);
shader_reset();

// TELEGRAPH DEL TELETRANSPORTE: flecha parpadeante (spr_jinna_clonearrow,
// 2 frames) sobre el objetivo mientras dura el windup — es el aviso que
// ve la jugadora de Jinna para saber a quien va a cazar el portal.
if(jinnaTeleWindup > 0 && instance_exists(jinnaTeleTarget))
{
	draw_sprite(spr_jinna_clonearrow, floor(current_time / 100) % 2, jinnaTeleTarget.x, jinnaTeleTarget.y - 46 - jinnaTeleTarget.sprite_yoffset + 8);
}

//hakc
if(isDead)
{
	xspd = 0;
	gspd = 0;
	return;
}
