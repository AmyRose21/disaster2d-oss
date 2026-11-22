// v32: INVISIBLE no deja RESIDUOS FANTASMA (delatarian su posicion
// al vuelo: el contorno rojo es solo SU vista local)
if(effectTime > 0 && invisTimer <= 0)
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
	draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
	shader_reset();

// v32 — BURBUJA del ESCUDO DE SALLY (modo SUPPORT): su propia vista
// (los demas clientes la dibujan en su puppet con el bit
// PLAYER_SALLYSHIELD, patron de la Sally vanilla en su Draw_0).
if(shieldTimer > 0)
	draw_sprite(revivalTimes >= 2 ? spr_sallyshield2 : spr_sallyshield, (current_time / 30) % 41, floor(x), floor(y));

// v34 — AURA DEL ESCUDO ELECTRICO (modo EGGMAN): el mismo sprite
// animado del doctor (spr_electroshield, patron de su Draw_0 —
// "if(isAttacking) draw..." centrado en el cuerpo). Antes lo unico
// que se veia al activarlo era la pose de vuelo del estado y se
// confundia con SU habilidad de siempre; ahora se ve EL AURA del
// doctor desde el primer frame (el chispazo de la descarga sigue
// saliendo en la pantalla de quien la toque).
if(eShieldTimer > 0)
	draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));

// v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer, 2.5 s).
// Mismo dibujo que el escudo de Eggman (patron obj_egg/Draw_0 L22): sprite
// compartido spr_electroshield, anim por current_time. Lazy var (coyoteTimer
// pattern): los personajes sin la variable no la tocan.
if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)
        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));
