#include <entities/BlazeFireball.h>

/* v2.2 (TTB): bola de fuego de Blaze. Mismo modelo que el laser de
   Tails: spawn (0), tick de posicion (1), despawn (2). */

bool bfire_init(Server* server, Entity* entity)
{
	BlazeFireball* fb = (BlazeFireball*)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
	PacketWrite(&pack, packet_write8, 0);
	PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.y);
	PacketWrite(&pack, packet_write8, fb->dir);
	server_broadcast(server, &pack, true);

	return true;
}

bool bfire_tick(Server* server, Entity* entity)
{
	BlazeFireball* fb = (BlazeFireball*)entity;

	if (fb->timer <= 0)
		return false;

	/* wrap del mapa YouCan'tRun (13), igual que el laser de Tails */
	if (server->game.map != 13)
	{
		if (fb->pos.x <= 0)
			return false;
	}
	else
	{
		if (fb->pos.x < 0)
			fb->pos.x = 3648;
		else if (fb->pos.x > 3648)
			fb->pos.x = 0;
	}

	Packet pack;
	PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
	PacketWrite(&pack, packet_write8, 1);
	PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.y);
	server_broadcast(server, &pack, false);

	fb->pos.x += (float)(fb->dir * 10 * server->delta);
	fb->timer -= server->delta;

	return true;
}

bool bfire_uninit(Server* server, Entity* entity)
{
	(void)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
	PacketWrite(&pack, packet_write8, 2);
	server_broadcast(server, &pack, true);

	return true;
}
