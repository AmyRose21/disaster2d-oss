// v4.8 (SCAN de Metal Amy): «VISION» de supervivientes — NO agujas.
// Mientras dura el revelado se dibuja la silueta de cada superviviente
// vivo ENCIMA de todo el mapa (capa GUI): se ve a traves de paredes,
// terreno, matorrales y escondites, con brillo rojo aditivo pulsante y
// fundido en el ultimo medio segundo. La que cae FUERA de la vista de
// 480x270 no desaparece: su silueta queda FIJADA al borde de la pantalla
// (mas tenue, como un fantasma) apuntando hacia donde esta. NO depende
// de `visible` (esa aguja unica es la del anillo rojo / invisibilidad /
// slime, con sus propias condiciones): el scan es un HUD propio del
// jugador Metal Amy. Las referencias las recoge el Step_2 (mismos
// filtros: muertos, esbirros y el velo de Amelia fuera).
if(scanCount > 0 && instance_exists(global.player) && instance_exists(obj_camera))
{
        var _pulse = 0.55 + 0.3 * sin(current_time / 90);
        var _fade = min(1, global.player.scanTimer / 30);

        gpu_set_blendmode(bm_add);

        for(var i = 0; i < scanCount; i++)
        {
                var _t = scanList[i];

                if(!instance_exists(_t))
                        continue;

                var _sx = _t.x - obj_camera.x;
                var _sy = _t.y - obj_camera.y;
                var _alpha = _pulse * _fade;

                // fuera de la vista: la silueta se fija al borde de la
                // pantalla (margen de 24 px para que el cuerpo se vea),
                // mas tenue — un fantasma que senala la direccion
                if(_sx < 0 || _sx > 480 || _sy < 0 || _sy > 270)
                {
                        _sx = clamp(_sx, 24, 456);
                        _sy = clamp(_sy, 24, 246);
                        _alpha *= 0.45;
                }

                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, c_red, _alpha);
        }

        gpu_set_blendmode(bm_normal);
}

// FIX SCAN v4.9: la aguja se gatea con su bandera propia (`needle`, la
// calcula el Step_2) y NO con `visible`: esa ahora es el interruptor del
// MOTOR que tambien enciende el scan (el bloque de arriba), y si se
// gateara aqui con visible, el revelado de Metal Amy arrastraria la
// flecha consigo. Invisibilidad EXE / anillo rojo / slime de Chaos:
// identico comportamiento de siempre (needle == la vieja condicion).
if(!needle)
        return;

if(!instance_exists(global.player))
        return;

draw_sprite_ext(spr_indicator, 0, ceil(global.player.x-obj_camera.x), ceil(global.player.y-obj_camera.y), 1, 1, image_angle, c_white, 1);