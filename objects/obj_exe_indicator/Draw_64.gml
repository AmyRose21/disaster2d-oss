// v4.8/v4.10 (SCAN de Metal Amy): «VISION» de supervivientes — NO agujas.
// Mientras dura el revelado se dibuja la silueta de cada superviviente
// vivo ENCIMA de todo el mapa (capa GUI): se ve a traves de paredes,
// terreno, matorrales y escondites. La que cae DENTRO de la vista de
// 480x270 lleva el brillo rojo aditivo pulsante de siempre (v4.8, intacto)
// con fundido en el ultimo medio segundo. La que cae FUERA de la vista
// no desaparece: su silueta queda FIJADA al borde de la pantalla
// apuntando hacia donde esta — y desde la v4.10 se dibuja en TRES
// pasadas (contorno oscuro + relleno rojo brillante en blend NORMAL +
// brillo aditivo encima) para que se lea hasta en los mapas con MUY
// poca oscuridad: el brillo 100% aditivo de la v4.8 se lavaba contra
// fondos claros (sumar rojo a un fondo casi blanco no cambia nada) y
// las siluetas lejanas "no se notaban". El contorno oscuro garantiza
// el contraste en claros y el relleno solido la lee igual en oscuros.
// NO depende de `visible` (esa aguja unica es la del anillo rojo /
// invisibilidad / slime, con sus propias condiciones): el scan es un
// HUD propio del jugador Metal Amy. Las referencias las recoge el
// Step_2 (mismos filtros: muertos, esbirros y el velo de Amelia fuera).
if(scanCount > 0 && instance_exists(global.player) && instance_exists(obj_camera))
{
        var _pulse = 0.55 + 0.3 * sin(current_time / 90);
        var _fade = min(1, global.player.scanTimer / 30);

        // v4.10 — colores de la silueta lejana: contorno rojo-negro profundo
        // (contraste en mapas claros) y relleno rojo vivo (legible en oscuros)
        var _farEdge = make_color_rgb(56, 8, 8);
        var _farFill = make_color_rgb(255, 72, 72);

        gpu_set_blendmode(bm_add);

        for(var i = 0; i < scanCount; i++)
        {
                var _t = scanList[i];

                if(!instance_exists(_t))
                        continue;

                var _sx = _t.x - obj_camera.x;
                var _sy = _t.y - obj_camera.y;

                // DENTRO de la vista: brillo aditivo pulsante — IDENTICO a
                // la v4.8 (el pedido era solo para las siluetas LEJANAS)
                if(_sx >= 0 && _sx <= 480 && _sy >= 0 && _sy <= 270)
                {
                        draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, c_red, _pulse * _fade);
                        continue;
                }

                // FUERA de la vista: la silueta se fija al borde de la
                // pantalla (margen de 24 px para que el cuerpo se vea)
                _sx = clamp(_sx, 24, 456);
                _sy = clamp(_sy, 24, 246);

                // pasada 1 — CONTORNO OSCURO (blend normal, 4 offsets de
                // 2 px): lo que la hace visible contra fondos claros
                gpu_set_blendmode(bm_normal);

                var _eA = 0.9 * _fade;
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx) + 2, ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, _farEdge, _eA);
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx) - 2, ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, _farEdge, _eA);
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy) + 2, _t.image_xscale, _t.image_yscale, _t.angle, _farEdge, _eA);
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy) - 2, _t.image_xscale, _t.image_yscale, _t.angle, _farEdge, _eA);

                // pasada 2 — RELLENO ROJO VIVO (blend normal): silueta
                // solida que se lee igual de bien en claros y en oscuros
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, _farFill, (0.62 + 0.33 * _pulse) * _fade);

                // pasada 3 — BRILLO ADITIVO: conserva el pulso «vivo» del
                // scan sobre el relleno (en mapas oscuros es lo que mas se nota)
                gpu_set_blendmode(bm_add);
                draw_sprite_ext(_t.sprite_index, _t.image_index, ceil(_sx), ceil(_sy), _t.image_xscale, _t.image_yscale, _t.angle, c_red, 0.35 * _pulse * _fade);
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