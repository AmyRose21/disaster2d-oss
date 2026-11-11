#ifndef JINNA_TRAP_H
#define JINNA_TRAP_H
#include "../States.h"

bool jinna_trap_init(Server* server, Entity* entity);
bool jinna_trap_tick(Server* server, Entity* entity);
bool jinna_trap_trigger(Server* server, Entity* entity);
bool jinna_trap_uninit(Server* server, Entity* entity);

/* v3 (D.I.B.): PORTAL TRAMPA de Jinna (tecla V+ABAJO; comparte la
   recarga de la V con el agarre: JINNA_GRAB). Vida maxima de 70 s
   (v4: era 20 s; la retira el server en silencio con state 1). La
   pisa un SUPERVIVIENTE vivo (CLIENT_JINNA_TRAP_HIT desde el cliente
   de la victima, que es la autoridad de su propia posicion) y el
   server valida y reenvia SERVER_JINNA_TRAP_HIT (pid, kind, jx, jy)
   con la posicion ACTUAL de Jinna: la victima sufre el dano SIN
   i-frames y es teletransportada hasta ella en su propio cliente — o
   es ABSORBIDA a la otra dimension si la victima es Vanilla (kind 1:
   fuera de juego "muerta sin estar muerta" + potenciacion del kit de
   Jinna en todos los clientes). */
typedef struct
{
        ENTITY_BODY

        uint16_t owner;
        double   timer;
        bool     triggered;
} JinnaTrap;

/* v4: vida de la trampa 70 s (antes 20 s) — pedido de la duena:
   "el tiempo de la trampa durara hasta 70 seg" */
#define JINNA_TRAP_LIFE_S 70
#define MakeJinnaTrap(x, y, owner) ((JinnaTrap) { MakeEntity("jtrap", x, y) jinna_trap_init, jinna_trap_tick, jinna_trap_uninit, owner, JINNA_TRAP_LIFE_S * TICKSPERSEC, false })

#endif
