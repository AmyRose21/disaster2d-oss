if(!visible)
        return;

if(!instance_exists(global.player))
        return;

if(!ringVisible && !exeVisible)
        return;

var _x = global.player.x;
var _y = global.player.y;

// FLECHA VERDE = la salida (anillo de escape): pegada a Amy, igual que el
// indicador del anillo del juego (spr_sindicator2 de obj_surv_ringindicator).
if(ringVisible)
        draw_sprite_ext(spr_sindicator2, 0, ceil(_x - obj_camera.x), ceil(_y - obj_camera.y), 1, 1, ringAngle, c_white, 1);

// FLECHA ROJA = el exe (spr_indicator: la flecha roja 32x16 del juego base,
// misma forma que la del eggtrack pero en rojo). Roja = peligro: senala donde
// esta el EXE REAL (el Step solo elige al puppet con character ==
// CHARACTER_EXE, nunca a sus minions). PEGADA a Amy con el mismo anclaje
// que la verde (los dos sprites son gemelos: 32x16, origin 3): se dibuja
// en (_x,_y) y rota hacia su objetivo, sin ningun offset hacia el exe.
// Solo si la salida y el exe caen en la misma direccion (se taparian la
// una a la otra) se desplaza perpendicularmente 14 px, siguiendo pegada.
if(exeVisible)
{
        var _ox = _x;
        var _oy = _y;
        
        if(ringVisible && abs(angle_difference(exeAngle, ringAngle)) < 20)
        {
                var p = degtorad(exeAngle + 90);
                _ox += cos(p) * 14;
                _oy -= sin(p) * 14;
        }
        
        draw_sprite_ext(spr_indicator, 0, ceil(_ox - obj_camera.x), ceil(_oy - obj_camera.y), 1, 1, exeAngle, c_white, 1);
}