#include <entities/ItemBox.h>
#include <CMath.h>
#include <stdlib.h>

/* v62 ITEM BOX v2 — entidad servidor.
   Clona el patron KAFSpeedBox con tres extensiones:
   - TYPE byte: que recompensa da (ITEMTYPE_*), sorteado al spawn con
     pesos desiguales (anillo comun, botas raras).
   - POSICION: el paquete de spawn lleva sx,sy explicitas (el cliente no
     adivina nada con instance_find: el server es la unica verdad).
   - RANDOM SPAWN: el map tick (KindAndFair.c) le pasa spawners libres;
     aqui no hay logica de mapa (igual que KafBox: el mapa decide cuando).

   Estados del SERVER_BOX_STATE (u8 state):
   3 = spawn (nid, type, pid_breaker_dummy, sx, sy)
   2 = rota por pid (nid, type, pid, sx, sy) — el reward lo aplica SOLO
       el cliente del pid (patron boost Kaf)
   1 = reparable/ready (nid, type, dummy, sx, sy) — re-difusion por si
       un cliente se reconecta (roundtrip: todo estado lleva TODO el
       contexto) */

static bool itembox_broadcast(Server* server, uint8_t state, ItemBox* box, uint16_t pid)
{
	Packet pack;
	RAssert(PacketCreate(&pack, SERVER_BOX_STATE));
	RAssert(PacketWrite(&pack, packet_write8, state));
	RAssert(PacketWrite(&pack, packet_write8, box->nid));
	RAssert(PacketWrite(&pack, packet_write8, box->type));
	RAssert(PacketWrite(&pack, packet_write16, pid));
	RAssert(PacketWrite(&pack, packet_write16, (uint16_t)box->pos.x));
	RAssert(PacketWrite(&pack, packet_write16, (uint16_t)box->pos.y));
	server_broadcast(server, &pack, true);
	return true;
}

bool itembox_init(Server* server, Entity* entity)
{
	/* Al crear la entidad el mapa ya puso pos/type/nid (MakeItemBox +
	   asignacion de pos). Difunde el estado SPAWN completo para que
	   cualquier cliente (incluidos los que entren tarde) la construya. */
	ItemBox* box = (ItemBox*)entity;
	itembox_broadcast(server, 3, box, 0);
	return true;
}

bool itembox_tick(Server* server, Entity* entity)
{
	ItemBox* box = (ItemBox*)entity;

	/* KafBox solo cuenta cuando esta activada; aqui al reves: la caja
	   VIVA no tiene countdown (timer<0), y la ROTA cuenta hasta 0 y ahi
	   la entidad muere (el mapa la re-spawnea en el siguiente roll si
	   hay hueco y spawner libre — la pool de respawn es del mapa). */
	if (box->timer < 0)
		return true;

	if (box->timer > 0)
	{
		box->timer -= server->delta;
		return true;
	}

	/* expiro: despawn silencioso de la entidad (la caja rota ya mostro
	   boxused 25+ s; el mapa decide si vuelve a sortear este nid). No
	   difundimos nada: el cliente ya la dejo en boxused y el siguiente
	   spawn con el MISMO nid la resetea via state 3 (redifusion completa
	   con sx,sy — el roundtrip cubre la reconstruccion). */
	return false; /* game_entity_tick la retira */
}

bool itembox_activate(Server* server, ItemBox* box, uint16_t pid, uint8_t is_proj)
{
	if (box->activated)
		return true; /* idempotente: re-romper una rota = no-op (anti-cheat igual que Kaf) */

	box->activated = true;
	box->timer = (double)(25 + rand() % 5) * TICKSPERSEC;

	/* state 2: rota + reward. is_proj: la revento un proyectil de Tails
	   (nadie cobra — mismo convenio Kaf pid=0). */
	itembox_broadcast(server, 2, box, is_proj ? 0 : pid);
	return true;
}
