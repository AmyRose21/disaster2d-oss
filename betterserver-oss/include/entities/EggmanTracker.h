#ifndef EGGTRACK
#define EGGTRACK
#include "../States.h"

bool eggtrack_init(Server* server, Entity* entity);
bool eggtrack_uninit(Server* server, Entity* entity);

/* v3.0 («Genio Malvado»): `upgraded` la marca el server con
   CLIENT_EGG_TRAP_UPGRADE (3 anillos de Eggman): el slow del sensor
   dura +25% y se dibuja con contorno dorado (state 2 a todos). */
typedef struct
{
	ENTITY_BODY

	uint16_t activ_id;
	bool     upgraded;
} EggTracker;
#define MakeEggTrack(x, y) ((EggTracker) { MakeEntity("eggtrack", x, y) eggtrack_init, NULL, eggtrack_uninit, 0, false })

#endif
