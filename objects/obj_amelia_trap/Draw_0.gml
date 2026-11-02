// v3.0 («Genio Malvado»): trampa MEJORADA por Eggman — CONTORNO
// DORADO alrededor del sprite. El exe invisible usa el mismo truco
// pero con sprites aparte hechos a mano (spr_exe_invis_*); aqui el
// contorno tambien es un sprite aparte GENERADO (spr_trap_gold:
// silueta dorada dilatada 1 px que se dibuja DETRAS del sprite
// normal, con un latido suave de brillo). El sprite de la trampa se
// dibuja a mano (antes lo hacia el draw por defecto del objeto).
if(upgraded)
{
        var _pulse = 0.72 + 0.28 * abs(sin(current_time / 260));
        draw_sprite_ext(spr_trap_gold, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, c_white, _pulse);
}

draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, image_blend, image_alpha);
