#include <entities/MetalAmyBullet.h>

/* v2.2 (TTB): bala del canon de Metal Amy. Mismo modelo que el laser
   de Tails: spawn (0), tick de posicion (1), despawn (2). */

bool mabul_init(Server* server, Entity* entity)
{
	MetalAmyBullet* mb = (MetalAmyBullet*)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_METALAMY_BULLET_STATE);
	PacketWrite(&pack, packet_write8, 0);
	PacketWrite(&pack, packet_write16, (uint16_t)mb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)mb->pos.y);
	PacketWrite(&pack, packet_write8, mb->dir);
	server_broadcast(server, &pack, true);

	return true;
}

bool mabul_tick(Server* server, Entity* entity)
{
	MetalAmyBullet* mb = (MetalAmyBullet*)entity;

	if (mb->timer <= 0)
		return false;

	/* wrap del mapa YouCan'tRun (13), igual que el laser de Tails */
	if (server->game.map != 13)
	{
		if (mb->pos.x <= 0)
			return false;
	}
	else
	{
		if (mb->pos.x < 0)
			mb->pos.x = 3648;
		else if (mb->pos.x > 3648)
			mb->pos.x = 0;
	}

	Packet pack;
	PacketCreate(&pack, SERVER_METALAMY_BULLET_STATE);
	PacketWrite(&pack, packet_write8, 1);
	PacketWrite(&pack, packet_write16, (uint16_t)mb->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)mb->pos.y);
	server_broadcast(server, &pack, false);

	mb->pos.x += (float)(mb->dir * 14 * server->delta);
	mb->timer -= server->delta;

	return true;
}

bool mabul_uninit(Server* server, Entity* entity)
{
	(void)entity;

	Packet pack;
	PacketCreate(&pack, SERVER_METALAMY_BULLET_STATE);
	PacketWrite(&pack, packet_write8, 2);
	server_broadcast(server, &pack, true);

	return true;
}
