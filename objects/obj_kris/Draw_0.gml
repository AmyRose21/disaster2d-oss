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

// ESCUDO (tecla C): anillo de activacion/exito (mismo estilo del
// powerboost de Sonic). SIN aura de aliados: el escudo de Kris es
// PERSONAL (solo bloquea lo que el ve venir de frente), no cubre a
// nadie mas — por eso aqui NO se dibuja el circulo del parry.
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

scr_powerboost_fx_flash(floor(x), floor(y - 6), parryFlash);

// v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer, 2.5 s).
// Mismo dibujo que el escudo de Eggman (patron obj_egg/Draw_0 L22): sprite
// compartido spr_electroshield, anim por current_time. Lazy var (coyoteTimer
// pattern): los personajes sin la variable no la tocan.
if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)
        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));
