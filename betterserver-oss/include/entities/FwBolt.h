#ifndef FWBOLT_H
#define FWBOLT_H
#include "../States.h"

bool fwbolt_init(Server* server, Entity* entity);
bool fwbolt_tick(Server* server, Entity* entity);
bool fwbolt_uninit(Server* server, Entity* entity);

/* v2.14 — Fleetway Amy: flecha de la ballesta (patron laser de Tails:
   vuelo RECTO sin gravedad, 5 s de vida). dmg 0 = stun (superviviente),
   dmg 20 = daño real (demonizada). */
typedef struct
{
	ENTITY_BODY

	uint16_t owner;
	int8_t	 dir;
	uint8_t	 damage;

	double	 timer;
} FwBolt;

#define FWBOLT_SPEED 14
#define FWBOLT_LIFE (5 * TICKSPERSEC)
#define MakeFwBolt(x, y, owner, dir, damage) ((FwBolt) { MakeEntity("fwbolt", x, y) fwbolt_init, fwbolt_tick, fwbolt_uninit, owner, dir, damage, FWBOLT_LIFE })

#endif
