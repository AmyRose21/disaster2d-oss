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
#define ITEMBOX_SPAWN_COFF 20    /* s entre intentos de spawn */
#define ITEMBOX_FIRST_DELAY 15  /* s sin cajas al inicio de ronda */
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

	uint8_t	 nid;
	uint8_t	 type;
	double	 timer;      /* <0: viva; >=0: countdown a respawn-ready */
	bool	 activated;  /* rota (boxused) */
	bool	 relocated;  /* v63: el cliente reporto trampolin/abismo -> el tick la re-spawnea en otro punto */
} ItemBox;
#define MakeItemBox(nid, type) ((ItemBox) { MakeEntity("itembox", 0, 0) itembox_init, itembox_tick, itembox_uninit, nid, type, -1, 0, 0, })

bool itembox_activate(Server* server, ItemBox* box, uint16_t pid, uint8_t is_proj);

#endif
