#ifndef AMELIA_TRAP_H
#define AMELIA_TRAP_H
#include "../States.h"

bool amelia_trap_init(Server* server, Entity* entity);
bool amelia_trap_tick(Server* server, Entity* entity);
bool amelia_trap_trigger(Server* server, Entity* entity);
bool amelia_trap_uninit(Server* server, Entity* entity);

/* v2.4 (TTB): trampa de Amelia. Vida maxima de 60 s (la retira el
   server en silencio); se activa cuando la pisa alguien del lado del
   EXE (CLIENT_AMELIA_TRAP_TRIGGER desde el cliente de la victima).
   El stun (3 s) y el slow (-40%, 3.5 s tras el stun) los aplica el
   cliente de la victima sobre su propio jugador. */
typedef struct
{
        ENTITY_BODY

        uint16_t owner;
        double   timer;
        bool     triggered;
} AmeliaTrap;
#define MakeAmeliaTrap(x, y, owner) ((AmeliaTrap) { MakeEntity("atrap", x, y) amelia_trap_init, amelia_trap_tick, amelia_trap_uninit, owner, 60 * TICKSPERSEC, false })

#endif
