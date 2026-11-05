function net_state_results(rbuff, nps, isPasstrough)
{
        show_debug_message(nps);
        switch(nps)
        {
                case PacketType.SERVER_RESULTS_DATA:
                {
                        var _name = buffer_read_s(rbuff, buffer_string);
                        var _char = buffer_read_s(rbuff, buffer_s8);
                // 6 = Amy Canon (valor crudo del server): reusa los iconos de
                // Amy (3) en las tiras. v5.1: Sally Canon (8) y Vanilla (9) ya
                // NO se remapean — los resolvedores usan sus tiras PROPIAS
                // (copias independientes de las de Sally/Cream).
                if(_char == 6)
                        _char = 3;
                        var _end = buffer_read_s(rbuff, buffer_u8);
                        var _time = buffer_read_s(rbuff, buffer_u16);
                        var _quit = buffer_read_s(rbuff, buffer_u8);
                        var _type = buffer_read_s(rbuff, buffer_u8);
                        
                        var _rings = buffer_read_s(rbuff, buffer_u16);
                        var _kills = buffer_read_s(rbuff, buffer_u16);
                        var _damage = buffer_read_s(rbuff, buffer_u16);
                        var _damageTaken = buffer_read_s(rbuff, buffer_u16);
                        var _stunTime = buffer_read_s(rbuff, buffer_u16);
                        var _stuns = buffer_read_s(rbuff, buffer_u16);
                        var _restored = buffer_read_s(rbuff, buffer_u16);
                        
                        var _survTime = floor(buffer_read_s(rbuff, buffer_f64) / 60.0);
                        var _dangerTime = floor(buffer_read_s(rbuff, buffer_f64) / 60.0);
                        
                        var _inst = instance_create_layer(3, 33 + (30 * obj_results.index++), "Results", obj_results_icon);
                        
                        with(_inst)
                        {
                                image_blend = _quit ? c_gray : c_white;
                                nick = _name;
                                type = _type;
                                rings = _rings;
                                kills = _kills;
                                damage = _damage;
                                damage_taken = _damageTaken;
                                stuns = _stuns;
                                hp_restored = _restored;
                                surv_time = _survTime;
                                stun_time = _stunTime;
                                danger_time = _dangerTime;
                        }
                        
                        switch(_type)
                        {
                                case 0:
                                {
                                        switch(_char)
                                        {
                                                case 0:
                                                        _inst.icon = spr_lobby_exeicon;
                                                        break;
                                                        
                                                case 1:
                                                        _inst.icon = spr_lobby_exeicon2;
                                                        break;
                                                        
                                                case 2:
                                                        _inst.icon = spr_lobby_exeicon3;
                                                        break;
                                                        
                                                case 3:
                                                        _inst.icon = spr_lobby_exeicon4;
                                                        break;
                                                        
                                                case 4:
                                                        // v2.2.4: Metal Amy (5.o killer, EX_METALAMY=4). Sin
                                                        // este case el icono quedaba en 0 (sprite incorrecto).
                                                        _inst.icon = spr_lobby_exeicon6;
                                                        break;
                                                        
                                        }
                                        break;
                                }
                                
                                case 1:
                                {
                                        var _rsDem = scr_hud_demon(_char + 1);
                                        _inst.icon = _rsDem[0];
                                        _inst.frame = _rsDem[1];
                                        break;
                                }
                                
                                case 2:
                                {
                                        var _rsStr = scr_hud_strip(_char + 1);
                                        _inst.icon = _rsStr[0];
                                        _inst.frame = _rsStr[1] + 6;
                                        break;
                                }
                                
                                case 3:
                                {
                                        // [Suite v5.1] icono por resolvedor (brillo > propio > tira)
                                        var _rsIco = scr_lobby_icon_pair(_char + 1);
                                        _inst.icon = _rsIco[0];
                                        _inst.frame = _rsIco[1];
                                        break;
                                }
                                
                                case 4:
                                {
                                        var _rsEsc = scr_hud_escaped(_char + 1);
                                        _inst.icon = _rsEsc[0];
                                        _inst.frame = _rsEsc[1];
                                        break;
                                }
                        }
                        
                        with(obj_results)
                        {
                                timeMin = floor(_time / 60);
                                timeSec = _time % 60;
                                showBlack = false;
                                result = _end;
                                
                                // Endings por escapados: PLRSTATE 4 = ESCAPED,
                                // 1/2/3 = demonizado/muerto/vivo (supervivientes), 0 = EXE
                                if(_type == 4)
                                        escapedCnt++;
                                if(_type >= 1)
                                        survTotal++;
                                
                                alarm[0] = 4;
                        }
                        
                        with(obj_lobby_prolet)
                        {
                                if(_end == 0)
                                        blackwhite = true;
                        }
                        
                        instance_create_layer(0, 0, "Instances_1", obj_blackfadeout);
                        break;
                }
        }
        
        return false;
}