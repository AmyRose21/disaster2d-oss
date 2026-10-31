#ifndef BLAZE_FIREBALL_H
#define BLAZE_FIREBALL_H
#include "../States.h"

bool bfire_init(Server* server, Entity* entity);
bool bfire_tick(Server* server, Entity* entity);
bool bfire_uninit(Server* server, Entity* entity);
bool bfire_bounce(Server* server, Entity* entity, uint8_t flip, uint16_t x, uint16_t y);

/* v2.2 (TTB): bola de fuego de Blaze. Patron laser de Tails: el server
   la mueve y reenvia la posicion; el stun al killer lo aplica el
   cliente del killer al ser tocado (2 s).
   v2.9: PROYECTIL REBOTANTE. El server integra gravedad + velocidad
   vertical; los choques contra suelo/pared/techo los reporta cualquier
   cliente (CLIENT_BLAZE_FIREBALL_BOUNCE con nid + componentes a
   invertir) porque solo los clientes tienen la colision del mapa, y el
   server voltea la velocidad y sigue. Cada bola lleva nid unico
   (varias simultaneas: patron v2.8 de la trampa). */
typedef struct
{
        ENTITY_BODY

        uint16_t owner;
        int8_t   dir;    /* signo de la velocidad horizontal: -1 / 1 */
        double   timer;
        double   vy;     /* v2.9: velocidad vertical (gravedad + rebotes) */
        double   block;  /* v2.9: lockout anti multi-reporte del mismo choque */
} BlazeFireball;

/* v2.9: constantes de la fisica (por tick de 1/60 s) */
#define BFIRE_SPEED 10.0 /* velocidad horizontal constante */
#define BFIRE_GRAV  0.22 /* gravedad (casi la del jugador: 0.21875) */
#define BFIRE_VY0   -2.5 /* lanzamiento con arco suave hacia arriba */
#define BFIRE_BLOCK 0.12 /* s de bloqueo tras aplicar un rebote */

#define MakeBlazeFireball(x, y, owner, dir) ((BlazeFireball) { MakeEntity("bfire", x, y) bfire_init, bfire_tick, bfire_uninit, owner, dir, 4 * TICKSPERSEC, BFIRE_VY0, 0.0 })

#endif
