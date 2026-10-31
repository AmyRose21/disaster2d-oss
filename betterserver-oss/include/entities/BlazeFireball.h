#ifndef BLAZE_FIREBALL_H
#define BLAZE_FIREBALL_H
#include "../States.h"

bool bfire_init(Server* server, Entity* entity);
bool bfire_tick(Server* server, Entity* entity);
bool bfire_uninit(Server* server, Entity* entity);

/* v2.2 (TTB): bola de fuego de Blaze. Proyectil horizontal (mismo
   modelo que el laser de Tails): el server la mueve y reenvia la
   posicion; el stun al killer lo aplica el cliente del killer al ser
   tocado (2 s). */
typedef struct
{
	ENTITY_BODY

	uint16_t owner;
	int8_t	 dir;
	double	 timer;
} BlazeFireball;
#define MakeBlazeFireball(x, y, owner, dir) ((BlazeFireball) { MakeEntity("bfire", x, y) bfire_init, bfire_tick, bfire_uninit, owner, dir, 4 * TICKSPERSEC })

#endif
