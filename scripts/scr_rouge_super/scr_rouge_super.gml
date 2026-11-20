function scr_rouge_super()
{
        // =================================================================
        //  v49 — SUPER ROUGE (test de colores de la duena): V + ARRIBA
        //  (el input lo lee scr_rouge_special). Maquina de fases:
        //    FASE 0 → 1: arranca la TIRA de transformacion
        //    (spr_rouge_super_form) UNA sola pasada — sin recolor todavia
        //    (la tira trae su propia transicion dibujada).
        //    FASE 1 → 2: la tira toca su ultimo frame y Draw_76 llama a
        //    scr_rouge_super_activate: encadena la tabla de recolor "truco
        //    SRB2" DETRAS de la paleta de skin del jugador
        //    (global.palleteFrom/To). Draw_0 ya pinta TODO a Rouge con
        //    scr_palette_swap + shd_colour, asi que CUALQUIER sprite suyo
        //    (run, jump, fly, glide, patada...) sale con los colores super
        //    SIN recolorear un solo sprite a mano — los colores cambian
        //    justo DESPUES de la animacion.
        //    FASE 2 → 0: otra vez V + ARRIBA la apaga (scr_rouge_super_
        //    revert restaura la paleta tal cual estaba antes del test).
        //  En FASE 1 el toggle se ignora (no se corta la tira a medias).
        //  100% LOCAL: cero paquetes, cero estado de red (es una prueba de
        //  colores; la super real va en su ronda).
        // =================================================================
        if(!variable_instance_exists(id, "superFormPhase"))
                superFormPhase = 0;

        if(superFormPhase == 0)
        {
                // FASE 0 → 1: transformando. La tira arranca desde el frame 0
                // — image_index NO se resetea solo al cambiar sprite_index, hay
                // que traerlo a mano o hereda el frame que traia el estado.
                superFormPhase = 1;
                image_index = 0;
                audio_play_sound(snd_buble, 0, false);
        }
        else if(superFormPhase == 2)
        {
                // FASE 2 → 0: apagar el test
                scr_rouge_super_revert();
                audio_play_sound(snd_buble, 0, false);
        }
        // FASE 1: en medio de la tira — se ignora
}

function scr_rouge_super_activate()
{
        // FASE 1 → 2: la tira de transformacion acabo — AHORA SI cambian
        // los colores. Encadena la tabla super DETRAS de la paleta de skin
        // del jugador (la skin gana los empates de color: shd_colour corta
        // en el primer match que encuentra).
        if(!variable_global_exists("rougeSuperPalFrom"))
        {
                // RGBA 0..1 — el MISMO formato que viaja en net_send_palette y
                // consume shd_colour (compara con 0.01 de tolerancia: estos
                // valores casan EXACTO con los pixeles de sus sprites — y los
                // rosas de corazones/botas NO estan en la tabla: la vestimenta
                // se pinta con sus colores de siempre).
                global.rougeSuperPalFrom = [
                        // PELAJE (cabello y cuerpo): grises → lavanda
                        245/255, 245/255, 245/255, 1,       // F5F5F5 claro
                        181/255, 182/255, 181/255, 1,       // B5B6B5 sombra 1
                        148/255, 146/255, 148/255, 1,       // 949294 sombra 2
                        72/255, 72/255, 72/255, 1,          // 484848 sombra 3 / oscuro de alas
                        // NEGRO (contornos + traje + sombras de alas)
                        0, 0, 0, 1,                         // 000000
                        // IRIS: teal → periwinkle/azul super
                        1/255, 104/255, 148/255, 1,         // 016894 sombra
                        2/255, 153/255, 219/255, 1,         // 0299DB brillo
                        // HOCICO (cara): un pelin mas claro
                        252/255, 172/255, 134/255, 1,       // FCAC86
                        172/255, 97/255, 61/255, 1          // AC613D
                ];
                global.rougeSuperPalTo = [
                        // PELAJE → blanco puro + lavandas iluminadas
                        252/255, 252/255, 252/255, 1,       // FCFCFC claro
                        216/255, 216/255, 252/255, 1,       // D8D8FC sombra 1
                        180/255, 180/255, 216/255, 1,       // B4B4D8 sombra 2
                        108/255, 108/255, 144/255, 1,       // 6C6C90 sombra 3 / oscuro de alas
                        // NEGRO → suave (mismo tratamiento del arte super)
                        36/255, 36/255, 36/255, 1,          // 242424
                        // IRIS super
                        108/255, 108/255, 252/255, 1,       // 6C6CFC
                        36/255, 72/255, 216/255, 1,         // 2448D8
                        // HOCICO super
                        252/255, 180/255, 144/255, 1,       // FCB490
                        180/255, 108/255, 72/255, 1         // B46C48
                ];
                global.rougeSuperBackupFrom = -1;
                global.rougeSuperBackupTo = -1;
        }

        if(variable_instance_exists(id, "superFormPhase") && superFormPhase == 1)
        {
                // ACTIVAR: guarda la paleta de skin ACTUAL y encadena la tabla
                // super DETRAS de ella.
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
                superFormPhase = 2;
        }
}

function scr_rouge_super_revert()
{
        // → FASE 0: restaura la paleta de skin tal cual estaba antes del
        // test (el backup guardo el array original; -1 = nunca se encadeno,
        // no hay nada que restaurar). Lo usan el toggle de apagado y la
        // seguridad de Draw_76 (muerte / demonizacion).
        if(variable_global_exists("rougeSuperBackupFrom")
        && global.rougeSuperBackupFrom != -1)
        {
                global.palleteFrom = global.rougeSuperBackupFrom;
                global.palleteTo = global.rougeSuperBackupTo;
                global.rougeSuperBackupFrom = -1;
                global.rougeSuperBackupTo = -1;
        }

        if(variable_instance_exists(id, "superFormPhase"))
                superFormPhase = 0;
}
