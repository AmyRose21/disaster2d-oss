function net_identity()
{
	var pak = cpacket_tcp(PacketType.IDENTITY, false);
	var osInfo = os_get_info();
	
	buffer_write(pak, buffer_u16, BUILD_VER);
	buffer_write(pak, buffer_s32, obj_netclient.want_lobby);
	buffer_write(pak, buffer_string, global.nickname);
	
	/* FIX UDID V1: el UDID de Android ("mod-" + 7 campos de os_get_info)
	   supera los ~128 chars en varios modelos y los servers con el
	   packet_readstr original reventaban (RASSERT out->len < 128) al
	   leerlo => el jugador quedaba colgado en "conectando...". Tope de
	   100 chars (suficiente para bans/uniqueness, seguro para cualquier
	   server). */
	if(os_type != os_android)
	{
		buffer_write(pak, buffer_string, string_copy($"mod-{osInfo[? "udid"]}", 1, 100));
	}
	else
	{
		var udid = $"{osInfo[? "VERSION"]}";
		udid += osInfo[? "CPU_ABI"];
		udid += osInfo[? "RELEASE"];
		udid += osInfo[? "MODEL"];
		udid += osInfo[? "DEVICE"];
		udid += osInfo[? "MANUFACTURER"];
		udid += osInfo[? "BOOTLOADER"];
	
		buffer_write(pak, buffer_string, string_copy($"mod-{udid}", 1, 100));
	}
	
	buffer_write(pak, buffer_s8, obj_unlockables.lobbyIcon);
	buffer_write(pak, buffer_s8, obj_unlockables.pet);
	buffer_write(pak, buffer_u64, 0);
	buffer_write(pak, buffer_u64, 0);
	
	send_server_tcp(pak);

	// Amy Canon: envia el token local (si existe) para que el server
	// desbloquee el personaje reservado SOLO para este cliente.
	if(global.amyCanonToken != "")
	{
		var amyPak = cpacket_tcp(PacketType.CLIENT_AMY_AUTH, false);
		buffer_write(amyPak, buffer_string, global.amyCanonToken);
		send_server_tcp(amyPak);
	}
}