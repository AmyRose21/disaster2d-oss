// v3.1 («Genio Malvado»): sensor MEJORADO por Eggman — CONTORNO
// DORADO alrededor del sprite mientras esta armado (spr_eggtrack_gold,
// generado igual que spr_trap_gold; ver obj_amelia_trap/Draw_0). El
// sprite del sensor se dibuja a mano (antes, draw por defecto).
//
// v3.1 (pedido): el dorado SOLO lo ve el bando SUPERVIVIENTE — el EXE
// y los ESBIRROS no ven cual sensor se mejoro (lo mismo con la barra
// de mejora de abajo: nada de filtrar el juguete del equipo al rival).
var _survView = instance_exists(global.player)
        && global.character != CHARACTER_EXE
        && global.player.revivalTimes < 2;

if(upgraded && !activated && _survView)
{
        var _pulse = 0.72 + 0.28 * abs(sin(current_time / 260));
        draw_sprite_ext(spr_eggtrack_gold, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, c_white, _pulse);
}

draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, image_blend, image_alpha);

// v3.1: barra de mejora del GENIO (estilo revive) — la MISMA tira del
// revive (spr_revival) sobre el sensor mientras el Eggman mantiene
// ABAJO; prompt fijo (spr_revival2 = faltan anillos) para el Dr. Solo
// supervivientes (el sensor es chiquito: la barra va 12 px encima).
if(_survView)
{
        if(upgShow)
        {
                var _frames = sprite_get_number(spr_revival);
                draw_sprite_ext(spr_revival, upgProg * _frames, floor(x), floor(y) - 20, 1, 1, 0, c_white, 1);
        }
        else if(upgOver >= 0)
        {
                draw_sprite_ext(upgOver == 1 ? spr_revival : spr_revival2, 0, floor(x), floor(y) - 20, 1, 1, 0, c_white, 1);
        }
}
