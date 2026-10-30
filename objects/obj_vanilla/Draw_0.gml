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

// V2: FLOAT RUN — imagenes residuales mientras dura la pose (misma
// tecnica que la estela de Nervios de Acero de Sonic; la estela que ven
// los DEMAS clientes sale del bitflag PLAYER_POWERBOOST en obj_netclient).
if(isFloatRunning && isGrounded && abs(xspd) > 1)
{
	floatGhostTimer++;
	
	if(floatGhostTimer mod VANILLA_FLOAT_GHOST_EVERY == 0)
	{
		var _ghost = instance_create_depth(x, y, 0, obj_quickeffect_fade);
		_ghost.sprite_index = sprite_index;
		_ghost.image_index = image_index;
		_ghost.image_xscale = image_xscale;
		_ghost.image_yscale = 1;
		_ghost.image_angle = radtodeg(angle);
		_ghost.fadeSpeed = VANILLA_FLOAT_GHOST_FADE;
		_ghost.depth = 1; // detras del jugador (depth 0)
	}
}
else
	floatGhostTimer = 0;

//Actual draw
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();