if(hidden)
        return;

if(obj_lobby.state == 0)
{
        sprite_index = spr_lobby_dicon;

        if(obj_netclient.nid == master_id)
                image_index = obj_unlockables.lobbyIcon;
        else if(ds_map_exists(obj_netclient.players, master_id))
                image_index = obj_netclient.players[? master_id].icon;
}

if(obj_lobby.state == 2 && obj_netclient.nid == master_id && !isSelected)
{       
        if(keyboard_check_pressed(global.KeyLeft))
        {
                offset = 3;
                selected--;
                
                // Personajes reservados (Amy Canon / Sally Canon):
                // quien no puede usarlos no pasa por sus slots al ciclar
                // (ver scr_char_locked). El while salta varios seguidos.
                // v4.4: el tope ahora es Rouge (15 supervivientes).
                while(selected >= CHARACTER_TAILS && selected <= CHARACTER_ROUGE && scr_char_locked(selected))
                        selected--;
                
                if(obj_netclient.exeId == master_id)
                {
                        // v1 (D.I.B.): 6 killers — y FIX del wrap izquierdo
                        // (quedaba en 4 desde la epoca de 4 killers: al
                        // ciclar hacia atras desde Exe se saltaba a Metal
                        // Amy y a Jinna)
                        if(selected < 1)
                                selected = 6;

                        // v2 (D.I.B.): killers RESERVADAS tampoco se ciclan
                        // (mismo patron que los personajes reservados de
                        // arriba, pero con el enum de killers: selected-1).
                        // Jinna es exclusiva del token de Amy: sin el
                        // token, el wrap a la 6.a se sigue de largo
                        // (aqui solo hay una reservada, el while aguanta
                        // varias en el futuro)
                        while(selected >= 1 && selected <= 6 && scr_exe_locked(selected - 1))
                                selected--;

                        // defensivo: si TODAS las killers quedaran
                        // reservadas, piso en Exe (no quedar colgado)
                        if(selected < 1)
                                selected = 1;
                }
                else
                {
                        if(selected < 1)
                        {
                                // wrap: entra por el ultimo slot VISIBLE
                                // (v4.4: tope Rouge)
                                selected = CHARACTER_ROUGE;
                                while(selected >= CHARACTER_TAILS && scr_char_locked(selected))
                                        selected--;
                        }
                }
                        
                audio_play_sound(snd_menu_select, 0, false);
        }
        else if(keyboard_check_pressed(global.KeyRight))
        {
                offset = 3;
                selected++;

                // Personajes reservados: se saltan por completo al ciclar
                // (ver scr_char_locked). v4.4: tope Rouge.
                while(selected <= CHARACTER_ROUGE && scr_char_locked(selected))
                        selected++;
                
                if(obj_netclient.exeId == master_id)
                {
                        // v1 (D.I.B.): 6 killers (Jinna es la 6.a)
                        if(selected > 6)
                                selected = 1;

                        // v2 (D.I.B.): killers reservadas se saltan por
                        // completo al ciclar (Jinna sin token: de Metal
                        // Amy se cae directo a Exe)
                        while(selected >= 1 && selected <= 6 && scr_exe_locked(selected - 1))
                                selected++;

                        if(selected > 6)
                                selected = 1;
                }
                else
                {
                        if(selected > CHARACTER_ROUGE)
                                selected = 1;
                }
                        
                audio_play_sound(snd_menu_select, 0, false);
        }
        
        if(keyboard_check_pressed(global.KeyA))
        {
                var packet;
                if(obj_netclient.exeId == master_id)
                        packet = cpacket_tcp(PacketType.CLIENT_REQUEST_EXECHARACTER);
                else
                        packet = cpacket_tcp(PacketType.CLIENT_REQUEST_CHARACTER);
                                
                // Personajes reservados (Amy Canon / Sally Canon):
                // sin permiso ni siquiera se piden al server (que tambien los
                // rechaza por si solo: doble seguro; ver scr_char_locked).
                // v2 (D.I.B.): Jinna es igual pero de killers: sin el token
                // de Amy ni se pide (scr_exe_locked; el server tambien la
                // rechaza por si solo: doble seguro).
                // Lectura del slot blindada (scr_characters): nunca fuera
                // de rango aunque haya pjs mas nuevos en el server.
                if((obj_netclient.exeId == master_id && !scr_exe_locked(selected - 1))
                || (obj_netclient.exeId != master_id && scr_avchar_get(selected) && !scr_char_locked(selected)))
                {
                        buffer_write(packet, buffer_u8, selected);
                        send_server_tcp(packet);
                }
                else audio_play_sound(snd_nono, 0, false);
        }
        
        if(obj_netclient.exeId == master_id)
        {               
                switch(selected)
                {
                        case 1:
                                sprite_index = spr_lobby_exeicon;
                                break;
                                
                        case 2:                                                 
                                sprite_index = spr_lobby_exeicon2;
                                break;
                                
                        case 3:
                                sprite_index = spr_lobby_exeicon3;
                                break;
                                
                        case 4:
                                sprite_index = spr_lobby_exeicon4;
                                break;
                                
                        case 5:
                                // v2.2 (TTB): Metal Amy
                                sprite_index = spr_lobby_exeicon6;
                                break;

                        case 6:
                                // v1 (D.I.B.): Jinna
                                sprite_index = spr_lobby_exeicon7;
                                break;
                }
                
                image_blend = c_gray;
        }
        else
        {
                // [Suite TD2D v5.1] icono de navegación por resolvedor:
                // brillo > sprite propio (Sally Canon/Vanilla = COPIAS,
                // Fleetway su tira) > tira común. (antes: remapeos a mano)
                scr_lobby_shiny_setup(selected);
                image_blend = c_gray;
        }
}

if(sprite_index != spr_lobby_exeicon5 && obj_netclient.exeId == master_id)
        image_speed = 1;

// [Suite TD2D v5.1] resolver el icono del personaje de este jugador
// cada fotograma (brillo animado / propio / tira común)
if(obj_lobby.state > 0 && !hidden)
        scr_lobby_shiny_resolve(self);

y = aY - offset;
draw_self();
var _size = scr_text_spr(-2000, -200, nickname);
scr_text_spr(x - _size/2, aY + 16, nickname);

if(obj_lobby.state == 2 && !isSelected)
{
        if(master_id == obj_netclient.nid)
        {
                draw_sprite(spr_lobby_icon_arrow, current_time / 150 % 3, x, y);
                
                for (var k = ds_map_find_first(obj_netclient.players); !is_undefined(k); k = ds_map_find_next(obj_netclient.players, k))
                {
                        if(obj_netclient.players[? k].character == selected && obj_netclient.exeId != master_id)
                        {
                                draw_sprite(spr_lobby_icon_used, 0, x-12, y-12);
                                break;
                        }
                        
                }
        }
}
else if(isSelected)
        image_blend = c_white;