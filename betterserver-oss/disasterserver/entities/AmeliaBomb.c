#include <entities/AmeliaBomb.h>

/* v2.2 (TTB): bomba de Amelia. La mecha la lleva el server; el BOOM
   (state 2) se reenvia a todos y cada cliente aplica su propio stun
   al jugador local del lado del EXE si esta en el radio. La explosion
   por pisada la pide el cliente del killer (CLIENT_AMELIA_BOMB_BOOM)
   y tambien pasa por amelia_bomb_boom. */

bool amelia_bomb_boom(Server* server, Entity* entity)
{
	AmeliaBomb* bomb = (AmeliaBomb*)entity;

	if (bomb->boomed)
		return false;

	bomb->boomed = true;

	Packet pack;
	PacketCreate(&pack, SERVER_AMELIA_BOMB_STATE);
	PacketWrite(&pack, packet_write8, 2);
	PacketWrite(&pack, packet_write16, bomb->id);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.y);
	server_broadcast(server, &pack, true);

	return false; // despawn
}

bool amelia_bomb_init(Server* server, Entity* entity)
{
	AmeliaBomb* bomb = (AmeliaBomb*)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_AMELIA_BOMB_STATE);
	PacketWrite(&pack, packet_write8, 0);
	PacketWrite(&pack, packet_write16, bomb->id);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.y);
	server_broadcast(server, &pack, true);
	return true;
}

bool amelia_bomb_tick(Server* server, Entity* entity)
{
	AmeliaBomb* bomb = (AmeliaBomb*)entity;

	bomb->timer -= server->delta;

	if (bomb->timer <= 0)
		return amelia_bomb_boom(server, entity);

	return true;
}

bool amelia_bomb_uninit(Server* server, Entity* entity)
{
	AmeliaBomb* bomb = (AmeliaBomb*)entity;

	/* solo avisar remove si NO exploto (la explosion ya mando el
	   state 2 y el cliente la destruyo) */
	if (bomb->boomed)
		return true;

	Packet pack;
	PacketCreate(&pack, SERVER_AMELIA_BOMB_STATE);
	PacketWrite(&pack, packet_write8, 1);
	PacketWrite(&pack, packet_write16, bomb->id);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)bomb->pos.y);
	server_broadcast(server, &pack, true);
	return true;
}
