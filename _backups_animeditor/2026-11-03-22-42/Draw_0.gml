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
                // v2.2: el tope ahora es Blaze (13 supervivientes).
                while(selected >= CHARACTER_TAILS && selected <= CHARACTER_BLAZE && scr_char_locked(selected))
                        selected--;
                
                if(obj_netclient.exeId == master_id)
                {
                        if(selected < 1)
                                selected = 4;
                }
                else
                {
                        if(selected < 1)
                        {
                                // wrap: entra por el ultimo slot VISIBLE
                                selected = CHARACTER_BLAZE;
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
                // (ver scr_char_locked). v2.2: tope Blaze.
                while(selected <= CHARACTER_BLAZE && scr_char_locked(selected))
                        selected++;
                
                if(obj_netclient.exeId == master_id)
                {
                        // v2.2: 5 killers (Metal Amy es el 5.o)
                        if(selected > 5)
                                selected = 1;
                }
                else
                {
                        if(selected > CHARACTER_BLAZE)
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
                // Lectura del slot blindada (scr_characters): nunca fuera
                // de rango aunque haya pjs mas nuevos en el server.
                if(obj_netclient.exeId == master_id || (scr_avchar_get(selected) && !scr_char_locked(selected)))
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
                }
                
                image_blend = c_gray;
        }
        else
        {
                // Sally Canon reusa el icono de Sally en el tira de sprites del lobby
                image_index = selected == CHARACTER_SALLY_CANON ? CHARACTER_SALLY + 1 : selected + 1;
                if(selected == CHARACTER_VANILLA)
                        image_index = CHARACTER_CREAM + 1;
                // v2.2 (TTB): Metal/Amelia/Blaze tienen sus propios frames al
                // final de la tira (10/11/12)
                if(selected == CHARACTER_METAL)
                        image_index = 10;
                else if(selected == CHARACTER_AMELIA)
                        image_index = 11;
                else if(selected == CHARACTER_BLAZE)
                        image_index = 12;
                image_blend = c_gray;
        }
}

if(sprite_index != spr_lobby_exeicon5 && obj_netclient.exeId == master_id)
        image_speed = 1;

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