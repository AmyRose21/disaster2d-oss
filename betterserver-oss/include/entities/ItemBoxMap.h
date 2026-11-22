#ifndef ITEMBOXMAP_H
#define ITEMBOXMAP_H
#include "../States.h"

/* v68 ITEM BOX v7 — SISTEMA CENTRAL PARA TODOS LOS MAPAS.
   Hasta v67 el roll vivia dentro de kaf_tick (Kind and Fair unico);
   la duena pidio cajas en TODOS los mapas. Este modulo es el roll
   generico: recibe el map id del Server y sortea spawners de la
   tabla derivada de cada room (ItemBoxSpawnTables.c, generado por
   derive_spawns_all_v68.py con las reglas v65 generalizadas).

   Integracion (cero cambios en los 25 mapas .c de la casa):
   - game_checkstart/Game.c llama itemboxmap_init(server) tras el
     map init de cada ronda (resetea la cadena de estado por ronda).
   - game_state_tick/Game.c llama itemboxmap_tick(server) cada tick.
   - game_state_handletcp/Game.c llama itemboxmap_tcpmsg(v, packet)
     (CLIENT_BOX_ACTIVATE / CLIENT_BOX_RELOCATE; anti-cheat igual
     que KindAndFair: AssertOrDisconnect + idempotencia + 1-shot).
   - KindAndFair.c ya NO tiene roll ni cases BOX: el sistema central
     manda (la tabla del mapa 7 es la v65 verificada). */

typedef struct
{
	const uint16_t (*points)[2];  /* tabla por mapa (NULL = inactivo) */
	int8_t zones;                  /* zonas de la tabla */
} ItemBoxSpawnTable;

extern const ItemBoxSpawnTable g_itembox_tables[MAP_COUNT];

bool itemboxmap_init  (Server* server);  /* reset por ronda */
bool itemboxmap_tick  (Server* server);  /* roll cada COFF s */
bool itemboxmap_tcpmsg(PeerData* v, Packet* packet); /* ACTIVATE/RELOCATE */

#endif
