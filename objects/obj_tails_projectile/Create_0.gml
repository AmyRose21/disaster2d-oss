isOwner = false;
// v98d: nid del jugador que LANZO este laser. Viaja en el paquete de
// spawn del server desde siempre (net_state_game solo lo usaba para
// calcular isOwner y lo tiraba). Lo necesita: (1) el zap del escudo
// electrico (scr_player_hurt recibe attackerNid: stun EXACTO al dueno
// del laser que rompio el escudo, sin tope de distancia ni estado
// "atacando"); (2) el credito de las cajas item rotas por proyectil
// (obj_itembox manda este nid al server: el DUENO cobra el reward).
// -1 = no conocido (no deberia pasar: el spawn siempre lo trae).
ownerNid = -1;
isBreaking = false;
isExe = false;
dmg = 0;
charge = 0;
image_speed = 1.2;

_destroy = function()
{
	if(isBreaking)
		return;
		
	isBreaking = true;
	switch(charge)
	{
		case 0:
			sprite_index = spr_tail_ray_dead;
			break;
			
		case 1:
			sprite_index = spr_tail_ray_dead1;
			break;
			
		case 2:
			sprite_index = spr_tail_ray_dead2;
			break;
			
		case 3:
			sprite_index = spr_tail_ray_dead3;
			break;
			
		case 4:
			sprite_index = spr_tail_ray_dead4;
			break;
			
		case 5:
			sprite_index = spr_tail_ray_dead4;
			break;
	}
	image_speed = 1.2;
	
	var pk = cpacket_tcp(PacketType.CLIENT_TPROJECTILE_HIT);
	send_server_tcp(pk);
}