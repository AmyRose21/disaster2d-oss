// v3.0 («Genio Malvado»): sensor MEJORADO por Eggman — CONTORNO
// DORADO alrededor del sprite mientras esta armado (spr_eggtrack_gold,
// generado igual que spr_trap_gold; ver obj_amelia_trap/Draw_0). El
// sprite del sensor se dibuja a mano (antes, draw por defecto).
if(upgraded && !activated)
{
        var _pulse = 0.72 + 0.28 * abs(sin(current_time / 260));
        draw_sprite_ext(spr_eggtrack_gold, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, c_white, _pulse);
}

draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, image_blend, image_alpha);
