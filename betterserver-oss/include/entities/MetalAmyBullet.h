#ifndef METALAMY_BULLET_H
#define METALAMY_BULLET_H
#include "../States.h"

bool mabul_init(Server* server, Entity* entity);
bool mabul_tick(Server* server, Entity* entity);
bool mabul_uninit(Server* server, Entity* entity);

/* v2.2 (TTB): bala del canon de Metal Amy (killer). Mismo modelo que
   el laser de Tails: el server la mueve; el dano (20) lo aplica el
   cliente de la victima al ser tocada. */
typedef struct
{
	ENTITY_BODY

	uint16_t owner;
	int8_t	 dir;
	double	 timer;
} MetalAmyBullet;
#define MakeMetalAmyBullet(x, y, owner, dir) ((MetalAmyBullet) { MakeEntity("mabul", x, y) mabul_init, mabul_tick, mabul_uninit, owner, dir, 4 * TICKSPERSEC })

#endif
