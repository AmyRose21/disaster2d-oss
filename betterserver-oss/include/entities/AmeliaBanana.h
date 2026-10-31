#ifndef AMELIA_BANANA_H
#define AMELIA_BANANA_H
#include "../States.h"

bool amelia_banana_init(Server* server, Entity* entity);
bool amelia_banana_tick(Server* server, Entity* entity);
bool amelia_banana_uninit(Server* server, Entity* entity);

/* v2.2 (TTB): resorte-trampa de Amelia. Estatica en el suelo; el
   rebote lo aplica el sistema de resortes del cliente de quien la
   pise. Vive 12 s. */
typedef struct
{
	ENTITY_BODY

	uint16_t owner;
	double	 timer;
} AmeliaBanana;
#define MakeAmeliaBanana(x, y, owner) ((AmeliaBanana) { MakeEntity("aban", x, y) amelia_banana_init, amelia_banana_tick, amelia_banana_uninit, owner, 12 * TICKSPERSEC })

#endif
