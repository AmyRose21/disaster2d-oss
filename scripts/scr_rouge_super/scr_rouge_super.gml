function scr_rouge_super()
{
        // =================================================================
        //  v49 — SUPER ROUGE: toggle del TEST VISUAL de colores de la
        //  super forma (V + ARRIBA — el input lo lee scr_rouge_special).
        //  Hace DOS cosas y nada mas:
        //    1) Draw_76 de obj_rouge dibuja la animacion propia
        //       spr_rouge_super_form mientras el test este activo.
        //    2) Encadena esta tabla de recolor ("truco SRB2") DETRAS de
        //       la paleta de skin del jugador (global.palleteFrom/To):
        //       Draw_0 ya pinta TODO a Rouge con scr_palette_swap +
        //       shd_colour, asi que CUALQUIER sprite suyo (y la anim
        //       nueva incluida) sale con los colores super SIN recolorear
        //       un solo sprite a mano. Asi el resto del kit (run, jump,
        //       fly, glide, patada...) ya tiene el look super gratis.
        //  La tabla remapea SOLO lo que cambia entre su arte normal y su
        //  arte super (los valores salen del spr_rouge_super_form que
        //  subio la duena, que ya trae la traduccion hecha pixel a
        //  pixel): pelaje gris -> LAVANDA iluminado, iris teal -> AZUL
        //  periwinkle, negro suavizado (contornos, traje y sombras de
        //  alas) y hocico un pelin mas claro. La VESTIMENTA sigue
        //  igual: los rosas de corazones/botas y las botas blancas NO
        //  estan en la tabla y se pintan con sus colores de siempre.
        //  100% LOCAL: cero paquetes, cero estado de red (es una
        //  prueba de colores; la super real va en su ronda).
        // =================================================================
        if(!variable_global_exists("rougeSuperPalFrom"))
        {
                // RGBA 0..1 — el MISMO formato que viaja en
                // net_send_palette y consume shd_colour (compara con
                // 0.01 de tolerancia: estos valores casan EXACTO con
                // los pixeles del sprite).
                global.rougeSuperPalFrom = [
                        // PELAJE (cabello y cuerpo): grises -> lavanda
                        245/255, 245/255, 245/255, 1,       // F5F5F5 claro
                        181/255, 182/255, 181/255, 1,       // B5B6B5 sombra 1
                        148/255, 146/255, 148/255, 1,       // 949294 sombra 2
                        72/255, 72/255, 72/255, 1,          // 484848 sombra 3 / oscuro de alas
                        // NEGRO (contornos + traje + sombras de alas)
                        0, 0, 0, 1,                         // 000000
                        // IRIS: teal -> periwinkle/azul super
                        1/255, 104/255, 148/255, 1,        // 016894 sombra
                        2/255, 153/255, 219/255, 1,        // 0299DB brillo
                        // HOCICO (cara): un pelin mas claro
                        252/255, 172/255, 134/255, 1,      // FCAC86
                        172/255, 97/255, 61/255, 1          // AC613D
                ];
                global.rougeSuperPalTo = [
                        // PELAJE -> blanco puro + lavandas iluminadas
                        252/255, 252/255, 252/255, 1,      // FCFCFC claro
                        216/255, 216/255, 252/255, 1,      // D8D8FC sombra 1
                        180/255, 180/255, 216/255, 1,      // B4B4D8 sombra 2
                        108/255, 108/255, 144/255, 1,      // 6C6C90 sombra 3 / oscuro de alas
                        // NEGRO -> suave (mismo tratamiento del arte super)
                        36/255, 36/255, 36/255, 1,         // 242424
                        // IRIS super
                        108/255, 108/255, 252/255, 1,      // 6C6CFC
                        36/255, 72/255, 216/255, 1,        // 2448D8
                        // HOCICO super
                        252/255, 180/255, 144/255, 1,      // FCB490
                        180/255, 108/255, 72/255, 1        // B46C48
                ];
                global.rougeSuperBackupFrom = -1;
                global.rougeSuperBackupTo = -1;
        }

        if(!variable_instance_exists(id, "superFormTest"))
                superFormTest = false;

        if(!superFormTest)
        {
                // ACTIVAR: guarda la paleta de skin ACTUAL y encadena la
                // tabla super DETRAS (la skin gana los empates de color:
                // shd_colour corta en el primer match que encuentra).
                global.rougeSuperBackupFrom = global.palleteFrom;
                global.rougeSuperBackupTo = global.palleteTo;

                var _n = array_length(global.palleteFrom);
                var _m = array_length(global.rougeSuperPalFrom);
                var _from = array_create(_n + _m);
                var _to = array_create(_n + _m);

                for(var i = 0; i < _n; i++)
                {
                        _from[i] = global.palleteFrom[i];
                        _to[i] = global.palleteTo[i];
                }

                for(var j = 0; j < _m; j++)
                {
                        _from[_n + j] = global.rougeSuperPalFrom[j];
                        _to[_n + j] = global.rougeSuperPalTo[j];
                }

                global.palleteFrom = _from;
                global.palleteTo = _to;
                superFormTest = true;
        }
        else
        {
                // QUITAR: restaura la paleta de skin tal cual estaba
                // antes del test (el backup guardo el array original).
                global.palleteFrom = global.rougeSuperBackupFrom;
                global.palleteTo = global.rougeSuperBackupTo;
                global.rougeSuperBackupFrom = -1;
                global.rougeSuperBackupTo = -1;
                superFormTest = false;
        }

        // feedback local del toggle (mismo sonido del ciclo de modos)
        audio_play_sound(snd_buble, 0, false);
}
