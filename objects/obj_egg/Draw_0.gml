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

	scr_palette_swap(global.palleteFrom, global.palleteTo);
	// v72 WSS: escala squash & stretch del cuerpo (scr_wss),
	// anclada al suelo — solo visual: la fisica y la mascara
	// de colision no cambian. [fx, fy, yoff].
	var _wss = scr_wss_draw();
	draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
	shader_reset();

if(isAttacking)
	draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));

// v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer, 2.5 s).
// Mismo dibujo que el escudo de Eggman (patron obj_egg/Draw_0 L22): sprite
// compartido spr_electroshield, anim por current_time. Lazy var (coyoteTimer
// pattern): los personajes sin la variable no la tocan.
if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)
        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));

// v71 ITEM BOX v3 — escudo de burbuja de la caja (shieldTimer): mismo
// patrón del eléctrico de arriba — burbuja animada encima del cuerpo en
// cualquier estado. Lazy var (coyoteTimer pattern): personajes sin la
// variable (o sin caja) no la tocan; Sally/SallyCanon/Rouge la dibujan
// en su propio Draw.
if(variable_instance_exists(id, "shieldTimer") && shieldTimer > 0)
        draw_sprite(revivalTimes >= 2 ? spr_sallyshield2 : spr_sallyshield, (current_time / 30) % 41, floor(x), floor(y));
