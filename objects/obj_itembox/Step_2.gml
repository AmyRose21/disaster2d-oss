// v63 ITEM BOX v3 — GRAVEDAD PROPIA (regla de la duena: nada de cajas
// naciendo en el aire como si nada; como en los juegos clasicos la caja
// CAE desde su spawn y se CLAVA donde hay suelo). Fisica local con la
// gravedad de las entidades de la casa (yspd += 0.2 como obj_darktower_
// sisipart; el mismo obj_floor_parent de siempre como suelo).
//   grounded == true  -> apoyada en su sitio (la mayoria nace a <=32px
//                        del suelo: la caida es un peloton instantaneo)
//   grounded == false -> cayendo (vspd acumula gravedad)
// Todos los clientes ejecutan la MISMA caida deterministica, y el
// PUNTO de spawn sigue siendo del server (sx,sy del paquete).
if(grounded)
{
	// higiene del emitter (copia exacta del Step_2 del kaf_speedboobster:
	// la caja ES su propio posicional de audio).
	var gain = 1.0 - (min(distance_to_point(obj_camera.x + 240, obj_camera.y + 135), 700) / 700.0);
	audio_emitter_position(emitter, x, y-16, 0);
	audio_emitter_gain(emitter, gain);
}
else
{
	// ===== CAIDA CLASICA =====
	vspd += 0.2;
	if(vspd > 12)
		vspd = 12;

	y += vspd;

	// clavar al suelo (el mismo floor parent que camina el player).
	// place_meeting usa el bbox del sprite de la caja (30px, origin arriba):
	// el while RETROCEDE hasta que el bbox deja de tocar — la base queda
	// EXACTAMENTE sobre la superficie. (v64 metio aqui un y += 30 que
	// la VOLVIA A ENTERRAR 30px dentro del suelo -> caja invisible en
	// pantalla: eso era lo que se veia en la captura. El while es todo.)
	if(place_meeting(x, y, obj_floor_parent))
	{
		while(place_meeting(x, y, obj_floor_parent))
			y -= 1;
		grounded = true;
		vspd = 0;
		// aterrizaje con polvita en la BASE de la caja.
		scr_effect_quick(x + 15, y + 30, spr_dust, 0.5, true);
	}
	// ===== TRAMPOLIN / ABISMO -> reporte al server =====
	// La caja cayo sobre un resorte (el trampolin la lanzaria al vacio)
	// o se salio del room / cayo al precipicio inferior sin encontrar
	// suelo: reportamos UNA vez (reported) y escondemos la instancia;
	// el server marca la entidad y la re-spawnea en OTRO punto libre
	// (CLIENT_BOX_RELOCATE — el server no tiene colision de mapa, el
	// reporte del cliente es la unica fuente, como CLIENT_FWBOLT_HIT).
	else if(!reported)
	{
		if(place_meeting(x, y, obj_spring_parent)
		|| x < 0 || y < 0 || x > room_width || y > room_height)
			report_relocate();
	}
}

// Rotura por proyectil de Tails (copia del Step_2 del Kaf: el cliente del
// dueno del proyectil reporta, el server difunde; proj=true => pid 0, no
// cobra nadie). v63: solo rompible apoyada (en plena caida no).
if(!instance_exists(obj_tails_projectile))
	return;

if(grounded && place_meeting(x, y, obj_tails_projectile))
{
	isBroken = true;

	var pack = cpacket_tcp(PacketType.CLIENT_BOX_ACTIVATE);
	buffer_write(pack, buffer_u8, nid);
	buffer_write(pack, buffer_bool, true);
	send_server_tcp(pack);
}