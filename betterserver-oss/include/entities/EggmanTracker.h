#ifndef EGGTRACK
#define EGGTRACK
#include "../States.h"

bool eggtrack_init(Server* server, Entity* entity);
bool eggtrack_uninit(Server* server, Entity* entity);

/* v3.0 («Genio Malvado»): `upgraded` la marca el server cuando
   Eggman completa la MEJORA (v3.1: estilo rescate, barra que llena el
   server con CLIENT_EGG_TRAP_UPGRADE_PROGRESS, 3 anillos): el slow
   del sensor dura +25% y se dibuja con contorno dorado (state 2, solo
   para el bando superviviente). `upg_progress` es esa barra (0..1,
   se conserva al soltar el ABAJO, igual que el revive). */
typedef struct
{
        ENTITY_BODY

        uint16_t activ_id;
        bool     upgraded;
        double   upg_progress;
} EggTracker;
#define MakeEggTrack(x, y) ((EggTracker) { MakeEntity("eggtrack", x, y) eggtrack_init, NULL, eggtrack_uninit, 0, false, 0.0 })

#endif
