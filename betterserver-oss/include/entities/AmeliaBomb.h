#ifndef AMELIA_BOMB_H
#define AMELIA_BOMB_H
#include "../States.h"

bool amelia_bomb_init(Server* server, Entity* entity);
bool amelia_bomb_tick(Server* server, Entity* entity);
bool amelia_bomb_boom(Server* server, Entity* entity);
bool amelia_bomb_uninit(Server* server, Entity* entity);

/* v2.2 (TTB): bomba de Amelia. Mecha de 5 s; explota sola (tick) o
   cuando el killer la pisa (CLIENT_AMELIA_BOMB_BOOM). El stun lo
   aplica el cliente de cada jugador (radio 90 px, lado EXE). */
typedef struct
{
	ENTITY_BODY

	uint16_t owner;
	double	 timer;
	bool	 boomed;
} AmeliaBomb;
#define MakeAmeliaBomb(x, y, owner) ((AmeliaBomb) { MakeEntity("abomb", x, y) amelia_bomb_init, amelia_bomb_tick, amelia_bomb_uninit, owner, 5 * TICKSPERSEC, false })

#endif
