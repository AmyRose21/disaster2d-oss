#include "Server.h"
#include <entities/Act9Wall.h>

#define ACT9_ROOM_WIDTH (3072)

/* FIX SPAWN ACT9 V1: gracia maxima (segundos) que cada muro espera a
   los jugadores que todavia no spawnearon (pos == 0,0). Cubre el fade
   de transicion del cliente (~1,6 s) + la carga de texturas del mapa
   en maquinas lentas, con margen sobre el start_timeout (15 s) del
   propio juego. Pasado el tope el muro arranca igual (anti-zombi). */
#define ACT9_WALL_HOLD_SEC 30

bool act9wall_init(Server* server, Entity* entity)
{
	Act9Wall* wall = (Act9Wall*)entity;
	wall->start_time = (server->game.time_sec * TICKSPERSEC + server->game.time);
	return true;
}

bool act9wall_tick(Server* server, Entity* entity)
{
	Act9Wall* wall = (Act9Wall*)entity;

	double time = (server->game.time_sec * TICKSPERSEC + server->game.time);

	/* FIX SPAWN ACT9 V1: el "ready" que arranca la partida se marca con
	   CUALQUIER paquete TCP (states/Game.c, game_state_handletcp) — p. ej.
	   los clicks de personaje spameados durante el fade de transicion ya
	   cuentan como ready. Asi la partida (y estos muros) podian arrancar
	   mientras un cliente seguia cargando la sala: ese cliente spawneaba
	   DENTRO del muro ya avanzado y lo aplastaba al aparecer ("aparece en
	   el suelo", cuenta como muerte). Ahora cada muro NO ARRANCA hasta que
	   TODOS los participantes vivos hayan reportado su primera posicion
	   (pos != 0,0), con tope de gracia de ACT9_WALL_HOLD_SEC por si un
	   cliente queda zombi. Solo se re-captura start_time: el barrido
	   siempre termina justo al acabar la ronda — solo empieza mas tarde. */
	if (server->game.elapsed < ACT9_WALL_HOLD_SEC * TICKSPERSEC)
	{
		for (size_t i = 0; i < server->peers.capacity; i++)
		{
			PeerData* data = (PeerData*)server->peers.ptr[i];
			if (!data)
				continue;

			if (!data->in_game)
				continue;

			if (data->plr.flags & PLAYER_DEAD)
				continue;

			if (data->plr.pos.x == 0 && data->plr.pos.y == 0)
			{
				wall->start_time = time;
				break;
			}
		}
	}
	double off = (double)(wall->start_time - time) / (double)wall->start_time;

	double x = wall->pos.x * off;
	double y = wall->pos.y * off;
	double wx;
	double hy;
	
	Packet pack;
	PacketCreate(&pack, SERVER_ACT9WALL_STATE);
	PacketWrite(&pack, packet_write8, wall->wid);
	PacketWrite(&pack, packet_write16, (uint16_t)x);
	PacketWrite(&pack, packet_write16, (uint16_t)y);
	server_broadcast(server, &pack, false);
	
	switch(wall->wid)
	{
		case 0:
		{
			x = -2240;
			y = y - 768;
			wx = x + (64 * 117);
			hy = y + (64 * 12);
			break;
		}

		case 1:
		{
			x = x - 2240;
			wx = x + (64 * 34);
			hy = y + (64 * 19.5);
			break;
		}

		case 2:
		{
			x = (ACT9_ROOM_WIDTH - x) + 64;
			wx = x + (64 * 34);
			hy = y + (64 * 19.5);
			break;
		}

		default:
		{
			Err("Invalid wall id!");
			return false;
		}
	}
	
	for(size_t i = 0; i < server->peers.capacity; i++)
	{
		PeerData* data = (PeerData*)server->peers.ptr[i];
		if(!data)
			continue;

		if(!data->in_game)
			continue;

		if(data->plr.pos.x == 0 && data->plr.pos.y == 0)
			continue;

		if(data->plr.flags & PLAYER_DEAD)
			continue;

		if(data->plr.pos.x >= x && data->plr.pos.y >= y && data->plr.pos.x <= wx && data->plr.pos.y <= hy)
		{
			server_disconnect(server, data->peer, DR_OTHER, "Inside the wall for too long!");
			continue;
		}
	}

	return true;
}