// v3.1 («Genio Malvado»): trampa MEJORADA por Eggman — CONTORNO
// DORADO alrededor del sprite. El exe invisible usa el mismo truco
// pero con sprites aparte hechos a mano (spr_exe_invis_*); aqui el
// contorno tambien es un sprite aparte GENERADO (spr_trap_gold:
// silueta dorada dilatada 1 px que se dibuja DETRAS del sprite
// normal, con un latido suave de brillo). El sprite de la trampa se
// dibuja a mano (antes lo hacia el draw por defecto del objeto).
//
// v3.1 (pedido): el dorado SOLO lo ve el bando SUPERVIVIENTE — el
// EXE y los ESBIRROS no ven cual trampa se mejoro (encima de la
// barra de mejora: nada de filtrar el juguete del equipo al rival).
// Mismo gate que el prompt/barra de abajo.
var _survView = instance_exists(global.player)
        && global.character != CHARACTER_EXE
        && global.player.revivalTimes < 2;

if(upgraded && _survView)
{
        var _pulse = 0.72 + 0.28 * abs(sin(current_time / 260));
        draw_sprite_ext(spr_trap_gold, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, c_white, _pulse);
}

draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, image_angle, image_blend, image_alpha);

// v3.1: barra de mejora del GENIO (estilo revive). Mientras el Eggman
// mantiene ABAJO, el server reenvia el progreso (upgShow/upgProg) y se
// dibuja la MISMA tira del revive (spr_revival, frame = progreso *
// frames) sobre la trampa; con anillos justos aparece el prompt fijo
// (spr_revival2 = faltan anillos, patron reviveObj). Solo supervivientes.
if(_survView)
{
        if(upgShow)
        {
                var _frames = sprite_get_number(spr_revival);
                draw_sprite_ext(spr_revival, upgProg * _frames, floor(x) + 16, floor(y) - 46, 1, 1, 0, c_white, 1);
        }
        else if(upgOver >= 0)
        {
                draw_sprite_ext(upgOver == 1 ? spr_revival : spr_revival2, 0, floor(x) + 16, floor(y) - 46, 1, 1, 0, c_white, 1);
        }
}
