// v4.7 (SCAN de Metal Amy): agujas hacia TODOS los supervivientes
// mientras dura el revelado. NO dependen de `visible` (esa aguja unica
// es la del anillo rojo / invisibilidad / slime, con sus propias
// condiciones): el scan es un HUD propio del jugador Metal Amy. Anillo
// de 26 px alrededor de ella, con pulso y fundido en el ultimo medio
// segundo (los angulos los recoge el Step_2, mismos filtros que la
// aguja normal: muertos, esbirros y el velo de Amelia fuera).
if(scanCount > 0 && instance_exists(global.player))
{
        var _pulse = 0.55 + 0.25 * sin(global.player.scanTimer * 0.3);
        var _fade = min(1, global.player.scanTimer / 30);
        var _cx = ceil(global.player.x - obj_camera.x);
        var _cy = ceil(global.player.y - obj_camera.y);

        for(var i = 0; i < scanCount; i++)
        {
                var _rad = degtorad(scanAng[i]);
                draw_sprite_ext(spr_indicator, 0, _cx + cos(_rad) * 26, _cy - sin(_rad) * 26, 1, 1, scanAng[i], c_white, _pulse * _fade);
        }
}

if(!visible)
        return;

if(!instance_exists(global.player))
        return;
        
draw_sprite_ext(spr_indicator, 0, ceil(global.player.x-obj_camera.x), ceil(global.player.y-obj_camera.y), 1, 1, image_angle, c_white, 1);