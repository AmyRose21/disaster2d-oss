if(image_alpha < 1)
	image_alpha += 1 / 180.0;
	
image_index = global.ringFrame;

if(used)
	return;

if(visible && image_alpha >= 1 && instance_exists(global.player) && place_meeting(x, y, global.player) && global.character != CHARACTER_EXE)
{       
	// v17 (NEGAGEN): el ANILLO ROJO ya no es trampa para el NEGA — es su
	// CURA: lo recoge (si está herido) y le sube JINNA_NEGA_REDHEAL (10)
	// de vida, SIN sonido (cura sigilosa: los supervivientes cercanos no
	// la oyen). El server le devuelve el SERVER_RING_COLLECTED y su
	// handler aplica la cura en silencio. Con la vida llena no lo gasta:
	// el anillo se queda para los demás.
	if(global.player.revivalTimes >= 2)
	{
		if(scr_negatouch_is(global.player) && global.player.hp > 0 && global.player.hp < 100)
		{
			var packet = cpacket_tcp(PacketType.CLIENT_RING_COLLECTED);
			buffer_write(packet, buffer_u8, iid);
			buffer_write(packet, buffer_u16, nid);
			send_server_tcp(packet);
			used = true;
		}
		
		return;
	}
	
	if(global.player.redRingTimer > 0)
		return;
		
	if(global.player.hp <= 0 || global.player.revivalTimes >= 2)
		return;
		
	var packet = cpacket_tcp(PacketType.CLIENT_RING_COLLECTED);
	buffer_write(packet, buffer_u8, iid);
	buffer_write(packet, buffer_u16, nid);
	send_server_tcp(packet);
	used = true;
}