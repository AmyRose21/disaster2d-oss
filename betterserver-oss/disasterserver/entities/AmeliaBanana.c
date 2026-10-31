#include <entities/AmeliaBanana.h>

/* v2.2 (TTB): resorte-trampa de Amelia. Spawn/remove reenviados a
   todos; sin tick (la fisica del rebote es 100% cliente). */

bool amelia_banana_init(Server* server, Entity* entity)
{
	AmeliaBanana* ban = (AmeliaBanana*)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_AMELIA_BANANA_STATE);
	PacketWrite(&pack, packet_write8, 0);
	PacketWrite(&pack, packet_write16, ban->id);
	PacketWrite(&pack, packet_write16, (uint16_t)ban->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)ban->pos.y);
	server_broadcast(server, &pack, true);
	return true;
}

bool amelia_banana_tick(Server* server, Entity* entity)
{
	AmeliaBanana* ban = (AmeliaBanana*)entity;

	ban->timer -= server->delta;

	return ban->timer > 0;
}

bool amelia_banana_uninit(Server* server, Entity* entity)
{
	AmeliaBanana* ban = (AmeliaBanana*)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_AMELIA_BANANA_STATE);
	PacketWrite(&pack, packet_write8, 1);
	PacketWrite(&pack, packet_write16, ban->id);
	PacketWrite(&pack, packet_write16, (uint16_t)ban->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)ban->pos.y);
	server_broadcast(server, &pack, true);
	return true;
}
