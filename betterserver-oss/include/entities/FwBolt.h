#ifndef FWBOLT_H
#define FWBOLT_H
#include "../States.h"

bool fwbolt_init(Server* server, Entity* entity);
bool fwbolt_tick(Server* server, Entity* entity);
bool fwbolt_uninit(Server* server, Entity* entity);

/* v2.14 — Fleetway Amy: flecha de la ballesta (patron laser de Tails:
   vuelo RECTO sin gravedad). dmg 0 = stun (superviviente),
   dmg 20 = daño real (demonizada).
   v2.15 («La Torre»): rework completo de la ballesta:
   - TODOS los paquetes llevan el id de la entidad (u16) para poder
     tener hasta 3 flechas simultaneas en el aire (antes el cliente
     solo podia distinguir "la primera flecha").
   - La flecha ya NO se rompe contra los solidos: se CLAVA
     (CLIENT_FWBOLT_HIT tipo 1) y queda 5 s como plataforma
     (FWBOLT_STICK_TIME); el estado 3 la clava para todos los
     clientes. Al expirar, despawn normal (estado 2). */
typedef struct
{
        ENTITY_BODY

        uint16_t owner;
        int8_t   dir;
        uint8_t  damage;

        double   timer;
        bool     stuck;
} FwBolt;

#define FWBOLT_SPEED 14
#define FWBOLT_LIFE (5 * TICKSPERSEC)
#define FWBOLT_STICK_TIME (5 * TICKSPERSEC)
#define MakeFwBolt(x, y, owner, dir, damage) ((FwBolt) { MakeEntity("fwbolt", x, y) fwbolt_init, fwbolt_tick, fwbolt_uninit, owner, dir, damage, FWBOLT_LIFE, false })

#endif
