if(!visible)
        return;

if(!instance_exists(global.player))
        return;

if(!ringVisible && !exeVisible)
        return;

var _x = global.player.x;
var _y = global.player.y;

// FLECHA VERDE = la salida (anillo de escape): pegada a Vanilla.
if(ringVisible)
        draw_sprite_ext(spr_sindicator2, 0, ceil(_x - obj_camera.x), ceil(_y - obj_camera.y), 1, 1, ringAngle, c_white, 1);

// FLECHA ROJA = el EXE REAL (spr_indicator, 32x16 origin 3): PEGADA a
// Vanilla, rotando hacia su objetivo sin offsets extra. Solo si salida
// y exe caen en la misma direccion se separa 14 px perpendicular.
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
