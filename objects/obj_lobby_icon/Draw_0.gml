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
		
		// Amy Canon oculta: sin token local se salta su slot por completo
		// (quien no tiene amy_canon.token ni siquiera pasa por ahi al ciclar)
		if(selected == CHARACTER_AMY_CANON && global.amyCanonToken == "")
			selected--;
		
		if(obj_netclient.exeId == master_id)
		{
			if(selected < 1)
				selected = 4;
		}
		else
		{
			if(selected < 1)
				selected = CHARACTER_SALLY_CANON;
		}
			
		audio_play_sound(snd_menu_select, 0, false);
	}
	else if(keyboard_check_pressed(global.KeyRight))
	{
		offset = 3;
		selected++;
		
		// Amy Canon oculta: sin token local se salta su slot por completo
		if(selected == CHARACTER_AMY_CANON && global.amyCanonToken == "")
			selected++;
		
		if(obj_netclient.exeId == master_id)
		{
			if(selected > 4)
				selected = 1;
		}
		else
		{
			if(selected > CHARACTER_SALLY_CANON)
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
				
		// Amy Canon reservada: sin token local ni siquiera se puede pedir
		if(obj_netclient.exeId == master_id || (obj_netclient.avCharacters[selected] && (selected != CHARACTER_AMY_CANON || global.amyCanonToken != "")))
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
		}
		
		image_blend = c_gray;
	}
	else
	{
		// Sally Canon reusa el icono de Sally en el tira de sprites del lobby
		image_index = selected == CHARACTER_SALLY_CANON ? CHARACTER_SALLY + 1 : selected + 1;
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