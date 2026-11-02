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
   cliente de la victima sobre su propio jugador.
   v3.0: `upgraded` la marca el server cuando Eggman completa la MEJORA
   («Genio Malvado» de Eggman, 5 anillos; v3.1: estilo rescate — barra
   que llena el server con CLIENT_EGG_TRAP_UPGRADE_PROGRESS): +25% de
   efectividad y contorno dorado (state 3, solo para el bando
   superviviente). Si la pisa el bando EXE estando mejorada, el server
   emite SERVER_TRACKER_PING (rastreador). `upg_progress` es esa barra
   (0..1, se conserva al soltar el ABAJO, igual que el revive).
   `owner` sirve para saber de que bando es la duena: si Amelia se
   demonizo, la pueden pisar los SUPERVIVIENTES (sin ceguera). */
typedef struct
{
        ENTITY_BODY

        uint16_t owner;
        double   timer;
        bool     triggered;
        bool     upgraded;
        double   upg_progress;
} AmeliaTrap;
#define MakeAmeliaTrap(x, y, owner) ((AmeliaTrap) { MakeEntity("atrap", x, y) amelia_trap_init, amelia_trap_tick, amelia_trap_uninit, owner, 60 * TICKSPERSEC, false, false, 0.0 })

#endif
