if(state == 0)
{
        draw_sprite(spr_lobby_bars, 0, 0, 0);
        
        if(countScale > 1)
                countScale -= 0.02;
                
        if(isCounting && !voteKick)
                draw_sprite_ext(spr_countdown, countdown - 1,  480/2, 13, countScale, countScale, 0, c_white, 1);
        else
                draw_sprite(voteKick ? spr_lobby_votekick : spr_lobby_waiting, (current_time / 300) % 4, 240, 8);
                
        var str = "";
        for(var i = 0; i < array_length(chat); i++)
                str += $"{chat[i]}\n";
        
        scr_text_spr(3, 148-6, str);
        
        var ind = chatMode;
        if(string_length(chatMsg) > 0)
                ind = 1;
        
        draw_sprite(spr_lobby_chatbox, ind, 0, 211);
        scr_text_spr(2, 214, chatMsg);
        scr_text_spr(170, 256, $"\\\your chance to be exe: {obj_netclient.chance}%");
}
else if(state == 1)
{               
        draw_sprite(spr_vote_bars, 0, 0, 0);
        
        if(countScale > 1)
                countScale -= 0.02;
                
        draw_sprite_ext(spr_counter3, voteTimer, 480/2, 13, countScale, countScale, 0, c_white, 1);
        
        var col = c_dkgray;
        if(mapChosen == 0 && !mapChose)
                col = c_white;
        
        draw_sprite_ext(spr_mapvote, map1, 16, 58 + 20 * mapFade - (mapChosen == 0 ? mapOff : 0), 1, 1, 0, col, mapFade);
        
        var col = c_dkgray;
        if(mapChosen == 1 && !mapChose)
                col = c_white;
        
        draw_sprite_ext(spr_mapvote, map2, 179, 58 + 20 * mapFade - (mapChosen == 1 ? mapOff : 0), 1, 1, 0, col, mapFade);
        
        var col = c_dkgray;
        if(mapChosen == 2 && !mapChose)
                col = c_white;
                
        draw_sprite_ext(spr_mapvote, map3, 341, 58 + 20 * mapFade - (mapChosen == 2 ? mapOff : 0), 1, 1, 0, col, mapFade);
        
        if(mapFade < 1)
                mapFade += 0.016;
                
        if(mapOff > 0)
                mapOff -= 0.32;
        
        var _map = map1;
        
        if(mapChosen == 1)
                _map = map2;
                
        if(mapChosen == 2)
                _map = map3;
                
        with(obj_lobby_prolet)
        {
                visible = true;
                image_blend = c_dkgray;

                if(map != _map)
                        setZone(_map);
        }
        
        scr_text_spr(4, 233, global.levelDescriptions[_map]);
        if(!mapChose)
                return;
        
        var col = c_white;
        if(mapChose && mapChosen == 0)
                col = #27ff23;
        
        draw_sprite_ext(spr_counter2, map1Votes, 16 + 61, (58 + 20 * mapFade - (mapChosen == 0 ? mapOff : 0)) + 53, 1, 1, 0, col, 1);
        
        var col = c_white;
        if(mapChose && mapChosen == 1)
                col = #27ff23;
        
        draw_sprite_ext(spr_counter2, map2Votes, 179 + 61, (58 + 20 * mapFade - (mapChosen == 1 ? mapOff : 0)) + 53, 1, 1, 0, col, 1);
        
        var col = c_white;
        if(mapChose && mapChosen == 2)
                col = #27ff23;
        
        draw_sprite_ext(spr_counter2, map3Votes, 341 + 61, (58 + 20 * mapFade - (mapChosen == 2 ? mapOff : 0)) + 53, 1, 1, 0, col, 1);
}
else if(state == 2 || state == 3)
{               
        var sprInd = 0;
        
        with(obj_lobby_icon)
        {
                if(master_id != obj_netclient.nid)
                        continue;
                        
                sprInd = selected - 1;
                
                if(obj_netclient.exeId == obj_netclient.nid)
                        sprInd += CHARACTER_BLAZE; // v2.2: 13 supervivientes + 5 killers
        }
        
        // Personajes reservados ocultos: ni retrato ni placa de info (doble
        // seguro ademas del salto de slot en obj_lobby_icon). Amy Canon sin
        // token; Sally Canon sin ser operador (Sonic es libre).
        // sprInd es 0-based (6 = Amy Canon, 7 = Sonic, 8 = Sally Canon);
        // ver scr_char_locked.
        // Seguro de slots (scr_characters): lectura blindada del array
        // (antes: avCharacters[sprInd+1] crasheaba con "Index [13] out
        // of range [11]" al ciclar hasta un pj nuevo como Blaze, porque
        // alguna copia del literal se quedaba corta).
        // ademas: si un server mas moderno manda un pj que este cliente
        // no conoce, sprInd puede superar chars[] => clamp para que ni
        // chars[sprInd] ni sprite_get_speed() lean fuera de rango.
        if(sprInd < 0)
                sprInd = 0;
        
        if(sprInd >= array_length(chars))
        {
                show_debug_message($"[chars] sprInd {sprInd} fuera de chars[] (pj de un server mas moderno): clamp a {array_length(chars) - 1}");
                sprInd = array_length(chars) - 1;
        }
        
        var _amyHidden = scr_char_locked(sprInd + 1);
        
        if(!_amyHidden && (obj_netclient.exeId == obj_netclient.nid || scr_avchar_get(sprInd + 1)))
                draw_sprite(chars[sprInd], charIndex, 132, 230);
        
        draw_sprite(spr_char_bars, obj_netclient.exeId == obj_netclient.nid, 0, 0);
        // Placa de info: survivors usan su frame (0-6 los originales, 11 = sonic
        // el nuevo). El HOST (EXE) usa los frames 7-10 de los killers; como su
        // sprInd ya viene desplazado (+CHARACTER_VANILLA = +10); se le resta
        // (CHARACTER_VANILLA - 7) = 3 para volver a los frames 7-10.
        var _infoFrame = sprInd;
        if(obj_netclient.exeId == obj_netclient.nid)
        {
                // v2.2: offset killers (exe=13..metalamy=17 -> placas 7-10 + Metal Amy 15)
                _infoFrame = sprInd - (CHARACTER_BLAZE - 7);
                if(sprInd == CHARACTER_BLAZE + 4)
                        _infoFrame = 15; // metal amy (v2.2): su propia placa
        }
        else if(sprInd == 8)
                _infoFrame = 5; // sally canon: usa la placa de Sally
        else if(sprInd == 9)
                _infoFrame = 4; // vanilla: usa la placa de Cream
        else if(sprInd == 7)
                _infoFrame = 11; // sonic
        else if(sprInd == 10)
                _infoFrame = 12; // metal (v2.2): su propia placa
        else if(sprInd == 11)
                _infoFrame = 13; // amelia (v2.2)
        else if(sprInd == 12)
                _infoFrame = 14; // blaze (v2.2)
        if(!_amyHidden)
                draw_sprite(spr_char_info, _infoFrame, 1, 232-5);
        
        if(countScale > 1)
                countScale -= 0.02;
        
        if(global.character == -1 || (global.character == CHARACTER_EXE && global.exeCharacter == -1))
                draw_sprite_ext(spr_counter3, charTimer, 480/2, 13, countScale, countScale, 0, charTimer <= 3 ? c_red : c_white, 1);

        charIndex += (1.0 / 60.0) * sprite_get_speed(chars[sprInd]);
}