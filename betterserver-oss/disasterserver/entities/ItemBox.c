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
   4 = despawn al expirar (nid, type, dummy, sx, sy) — el cliente destruye
       la instancia boxused (sin esto quedaba colgada indefinidamente)
   1 = reparable/ready (nid, type, dummy, sx, sy) — re-difusion por si
       un cliente se reconecta (roundtrip: todo estado lleva TODO el
       contexto) */

static bool itembox_broadcast(Server* server, uint8_t state, ItemBox* box, uint16_t pid)
{
	Packet pack;
	/* ojo: PacketCreate/PacketWrite YA se expanden a RAssert(...) (Log.h),
	   no se envuelven en otro RAssert — RAssert(if(...)) no compila (C2059).
	   Patron exacto de KAFSpeedBox.c/Ring.c. */
	PacketCreate(&pack, SERVER_BOX_STATE);
	PacketWrite(&pack, packet_write8, state);
	PacketWrite(&pack, packet_write8, box->nid);
	PacketWrite(&pack, packet_write8, box->type);
	PacketWrite(&pack, packet_write16, pid);
	PacketWrite(&pack, packet_write16, (uint16_t)box->pos.x);
	PacketWrite(&pack, packet_write16, (uint16_t)box->pos.y);
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

	/* expiro: difundir DESPAWN (state 4) y morir. Sin esto la boxused
	   quedaria colgada en el cliente hasta que el azar re-sortee ese
	   nid; con esto la instancia se destruye limpia (ring_uninit
	   difunde su remocion igual). El mapa re-sortea el hueco cuando
	   quiera — si vuelve a salir este nid, su state 3 la crea de
	   cero (reusa solo si existe, y ya no existe). */
	itembox_broadcast(server, 4, box, 0);
	return false; /* game_entity_tick la retira via uninit */
}

bool itembox_uninit(Server* server, Entity* entity)
{
	/* Definido porque MakeItemBox lo referencia (LNK2019 si falta) y
	   porque broadcast-aqui es el convenio Ring.c. La muerte por tick
	   ya difundio el state 4 arriba; este hook cubre los despawns
	   que NO pasan por el tick (game_despawn directo: fin de ronda,
	   limpieza de mapa). Silencioso y sin paquete: mismo NULL-safe de
	   Game.c (uninit se llama solo si != NULL). */
	ItemBox* box = (ItemBox*)entity;
	(void)box;
	(void)server;
	return true;
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
