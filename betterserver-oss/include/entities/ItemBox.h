#ifndef ITEMBOX_H
#define ITEMBOX_H
#include "../States.h"

/* v62 ITEM BOX v2 (cajas de recompensa aleatorias).
   Extension directa de KAFSpeedBox: la diferencia es que la caja tiene
   TIPO (5 recompensas), POCISION propia (sx,sy difundidas en el paquete:
   el server es la unica verdad de posicion) y el spawn lo sortea el
   servidor entre los spawners libres del mapa (patron Ring.c goto-gen).
   Duraciones/recompensas las aplica cada cliente al pid premiado (patron
   boost Kaf). */

#define ITEMBOX_MAX 4            /* cajas vivas simultaneas */
/* v78 OJO: estos dos macros estan en SEGUNDOS; los usos en ItemBoxMap.c
   multiplican por TICKSPERSEC (elapsed/delta del server cuentan TICKS a
   60/s — el bug v62-v77 era usarlos en crudo: el roll corria cada 20
   TICKS = 0.33 s y una caja destruida se repone casi al instante, el
   "aparece otro de la nada" de la duena). */
#define ITEMBOX_SPAWN_COFF 20    /* s entre intentos de spawn (relleno inicial) */
#define ITEMBOX_FIRST_DELAY 15  /* s sin cajas al inicio de ronda */
/* v78 (duena): "las cajas ahora tienen un enfriamiento de 30 seg por
   caja" — cada caja DESTRUIDA (CLIENT_BOX_ACTIVATE, la rompa quien la
   rompa) agenda su reposicion 30 s despues. El contador NO corre con el
   maximo de cajas vivas cubierto (se pausa hasta que haya hueco) y el
   roll de relleno JAMAS repone una destruida mientras haya enfriamientos
   pendientes (nada de "destruyo 1 y enseguida aparece otro de la nada").
   Las REUBICADAS (lava/abismo/zona v63/v76/v77) siguen renaciendo en el
   mismo tick: eso no es destruccion. */
#define ITEMBOX_RESPAWN_COOLDOWN 30 /* s por caja destruida (v78) */
#define ITEMBOX_RESPAWN (25 + rand() % 5) /* s de cooldown por spawner (valor Kaf) */

/* Tipos de caja (viajan en u8; mismo orden que las macros BOX_* del cliente) */
#define ITEMTYPE_RING 0
#define ITEMTYPE_SHIELD 1
#define ITEMTYPE_INVINCIBILITY 2
#define ITEMTYPE_LIGHTNING 3
#define ITEMTYPE_BOOTS 4

bool itembox_init(Server* server, Entity* entity);
bool itembox_tick(Server* server, Entity* entity);
bool itembox_uninit(Server* server, Entity* entity);

typedef struct
{
        ENTITY_BODY

        uint8_t  nid;
        uint8_t  type;
        double   timer;      /* <0: viva; >=0: countdown a respawn-ready */
        bool     activated;  /* rota (boxused) */
        bool     relocated;  /* v63: el cliente reporto trampolin/abismo -> el tick la re-spawnea en otro punto */
} ItemBox;
#define MakeItemBox(nid, type) ((ItemBox) { MakeEntity("itembox", 0, 0) itembox_init, itembox_tick, itembox_uninit, nid, type, -1, 0, 0, })

/* v98d: el pid llega YA RESUELTO por el caller (ItemBoxMap.c): melee =
   el que la rompio, proyectil = el DUENO del laser (antes is_proj
   forzaba pid 0 y no cobraba nadie). pid 0 = nadie (Exe v74, botas
   rotas por proyectil v98d — "tener la speed activa sin querer seria
   una pendejada"). */
bool itembox_activate(Server* server, ItemBox* box, uint16_t pid);

#endif
