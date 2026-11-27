var offset = 25;
if(hp > 0)
{
        var frame = 5;

        if(hp >= 100)
                frame = 5;
        else if(hp >= 75)
                frame = 4;
        else if(hp >= 50)
                frame = 3;
        else if(hp >= 25)
                frame = 2;
        else if(hp > 0)
                frame = 1
        else
                frame = 0;

        var _colour = room == room_act9 ? c_dkgray : c_white;
        // Kris JAMAS se convierte en subdito negativo (regla), pero el
        // patron del guard es el mismo de los 15 supervivientes.
        if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
                draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr_nega : spr_hp_nega, frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);
        else
                draw_sprite_ext(redRingTimer > 0 ? spr_hp_rr : spr_hp, revivalTimes == 2 ? 0 : frame, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset, 1, 1, 0, _colour, 1);

        if(isSlow)
                draw_sprite(spr_frozen, 0, ceil(x-obj_camera.x), ceil(y-obj_camera.y) - offset);

        if(obj_netclient.exeId != obj_netclient.nid && revivalTimes < 2)
                scr_number_spr(ceil(x-obj_camera.x) - 2, ceil(y-obj_camera.y) - offset - 12, string(global.player.rings), _colour);

        // v46 (LOVE): el LV de Kris por encima de su barra de vida (una
        // linea mas arriba que el contador de anillos).
        // v47 (duena): color PROGRESIVO - "1 empieza blanco nivel 1 y
        // ira cambiando a color rojo progresivamente mediante el nivel":
        // merge_color del blanco al rojo pleno entre el LV 1 y el LV 20
        // (KRIS_LV_MAX). Act9 lo apaga a gris oscuro como siempre.
        if(variable_instance_exists(id, "krisLv") && krisLv > 0)
                scr_text_spr(ceil(x - obj_camera.x) - 14, ceil(y - obj_camera.y) - offset - 24, "lv " + string(krisLv), room == room_act9 ? c_dkgray : merge_color(c_white, c_red, (krisLv - 1) / (KRIS_LV_MAX - 1)), 1);

        // v95 (duena): "que pueda ver donde se ubica la salida" — la
        // FLECHA VERDE de la salida, patron del sensor de Amy Canon
        // (obj_amycanon_indicators): la flecha spr_sindicator2 PEGADA al
        // cuerpo (mismo anclaje que la de Amy, que tambien es un compass
        // de cuerpo) rotando hacia el obj_bigring MAS CERCANO, activa
        // SIN condiciones desde que el anillo de escape aparece en el
        // mapa. Demonizado (revivalTimes >= 2) no: juega PARA el exe y el
        // juego ya le da su propia flecha (obj_demon_indicator) — patron
        // de apagado de los sensores de Amy Canon. Muerto/caido (hp <= 0)
        // tampoco: este bloque entero vive dentro del if(hp > 0).
        if(revivalTimes < 2 && instance_exists(obj_bigring))
        {
                var _kExit = instance_nearest(x, y, obj_bigring);

                if(_kExit != noone && _kExit != id)
                        draw_sprite_ext(spr_sindicator2, 0, ceil(x - obj_camera.x), ceil(y - obj_camera.y), 1, 1, point_direction(x, y, _kExit.x, _kExit.y), room == room_act9 ? c_dkgray : c_white, 1);
        }
}