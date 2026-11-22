#include <maps/KindAndFair.h>
#include <entities/KAFSpeedBox.h>
#include <entities/ItemBox.h>
#include <States.h>
#include <CMath.h>
#include <stdlib.h>

/* v63 ITEM BOX v3 — tabla RE-DERIVADA de los ring spawners REALES del
   room (regla de la duena: las cajas aparecen como zonas de posible
   aparicion de ANILLOS, PERO solo los que estan CERCA DEL SUELO, nunca
   los que estan muy arriba; y sin resorte/trampolin debajo). Derivacion
   (scripts/derive_spawns_v63.py, datos de room_kindandfair.yy):
   de los 32 obj_ring_spawner quedaron 9 — se descartaron los altos
   (y<900: fila de 496/537), los que caen al abismo (sin solido debajo
   en 400px: 280,1000 / 640,1064 / 680-728,924 / 1832-2024,1328 /
   2916,952 / 3068,1168 / 3556,1240...), los que tienen resorte en
   radio 48px (680,924 pega con obj_bspring_right) y redundancias
   (<96px entre si). Offset +24px en x para no pisar la fila de anillos.
   La pista de boost Kaf (y=610, x 3477-3952) queda FUERA (ninguno de
   los 9 la toca: sus y van de 940 a 1388). */
static const uint16_t kaf_itembox_spawns[][2] = {
	{ 1104,  940}, { 2792,  956}, { 2992, 1168}, { 3240, 1240},
	{ 4080, 1256}, { 1132, 1276}, { 2560, 1376}, { 2656, 1376},
	{ 1296, 1388},
};
#define KAF_ITEMBOX_SPAWN_COUNT (int)(sizeof(kaf_itembox_spawns) / sizeof(kaf_itembox_spawns[0]))

/* v63: nunca-repetir — el ultimo spawner usado queda vetado en el
   siguiente roll (la caja "nunca nace en el mismo lugar" de la duena;
   con 9 puntos y max 4 vivas hay holgura siempre). */
static uint8_t itembox_last_spawner = 255;

/* Sorteo con pesos desiguales: anillo comun (35%), escudo 20%, los tres
   raros 15% c/u. Misma tabla en el cliente (macros BOX_*_WEIGHT). */
static uint8_t itembox_roll_type(void)
{
	int r = rand() % 100;

	if (r < 35)
		return ITEMTYPE_RING;
	if (r < 55)
		return ITEMTYPE_SHIELD;
	if (r < 70)
		return ITEMTYPE_INVINCIBILITY;
	if (r < 85)
		return ITEMTYPE_LIGHTNING;
	return ITEMTYPE_BOOTS;
}

bool kaf_init(Server* server)
{
	RAssert(map_time(server, 3 * TICKSPERSEC, 20)); //180
	RAssert(map_ring(server, 5));

	for (uint8_t i = 0; i < 11; i++)
		RAssert(game_spawn(server, (Entity*)&(MakeKafBox(i)), sizeof(KafBox), NULL));

	/* v62: cero cajas al inicio (los primeros 15 s la caza arranca
	   limpia); el primer tick de spawn llega via server->game.time_sec. */
	return true;
}

bool kaf_tick(Server* server)
{
	/* v62 ITEM BOX v2 — el corazon del spawn aleatorio.
	   Cadena de estado:
	   - server->game.elapsed acumula segundos desde el init del mapa.
	   - Cada ITEMBOX_SPAWN_COFF segundos (y tras ITEMBOX_FIRST_DELAY):
	     si hay menos de ITEMBOX_MAX entidades "itembox" VIVAS, se sortea
	     un spawner libre (patron Ring.c: goto-gen sobre libres) y se
	     spawnea una caja de tipo sorteado EN esa pocision exacta.
	   - La entidad muere sola cuando expira su respawn (itembox_tick
	     devolvio false), liberando el hueco para el siguiente roll.
	   - Spawner "libre" = ninguno con entidad viva viviendo en el.
	   Todo TCP ordenado + difusion completa (state 3 lleva sx,sy,type):
	   cualquier cliente reconstruye sin depender de orden de instancias
	   (mas robusto que instance_find(nid % n) del Kaf). */

	static double itembox_next_roll = 0; /* ver nota de reset abajo */
	static int itembox_alive = -1;

	/* reset por ronda: el elapsed se pone a 0 en map start, asi que
	   detectamos ronda nueva cuando elapsed < ITEMBOX_FIRST_DELAY y el
	   estado interno apunta a una ronda vieja (alive >= 0 con roll ya
	   agendado en el futuro lejano). Barato y sin tocar el Server. */
	if (server->game.elapsed < 1.0 && itembox_alive >= 0)
	{
		itembox_next_roll = 0;
		itembox_alive = -1;
	}

	if (itembox_alive < 0)
	{
		/* primera llamada de la ronda: agenda el primer roll */
		itembox_alive = 0;
		itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY;
	}

	if (server->game.elapsed >= itembox_next_roll)
	{
		itembox_next_roll = server->game.elapsed + ITEMBOX_SPAWN_COFF;

		/* contar vivas (timer < 0) — las rotas en countdown todavia
		   ocupan visualmente boxused, pero la pool de spawn son las
		   VIVAS unicamente (max 4 cajas rompibles a la vez). */
		ItemBox boxes[ITEMBOX_MAX * 3];
		int found = game_find(server, (Entity**)boxes, "itembox", ITEMBOX_MAX * 3);		int alive = 0;
		for (int i = 0; i < found; i++)
			if (boxes[i].timer < 0)
				alive++;

		/* v63 RELOCATE: las cajas marcadas por CLIENT_BOX_RELOCATE se
		   retiran AQUI (despawn state 4 al cliente via uninit) y devuelven
		   su spawner a la pool del roll de abajo — la nueva nace en OTRO
		   punto libre en el MISMO tick (el duena pidio tp inmediato a
		   otra zona aleatoria, no esperar 20 s). */
		for (int i = 0; i < found; i++)
		{
			if (!boxes[i].relocated)
				continue;
			/* forzar su muerte en este tick: el game_entity_tick llama
			   uninit (difunde state 4) y retira la entidad. */
			boxes[i].timer = 0;
		}

		if (alive < ITEMBOX_MAX && found < ITEMBOX_MAX * 3)
		{
			/* spawners ocupados: un nid por entidad viva (el nid ES el
			   spawner: la caja vive y muere en el mismo punto). */
			uint8_t used[KAF_ITEMBOX_SPAWN_COUNT];
			memset(used, 0, sizeof(used));
			for (int i = 0; i < found; i++)
				if (boxes[i].nid < KAF_ITEMBOX_SPAWN_COUNT && boxes[i].timer < 0)
					used[boxes[i].nid] = 1;
			/* v63: la caja relocalizada tambien desocupa su punto — su
			   reemplazo puede nacer incluso en el MISMO spawner... no:
			   mejor vetarlo este roll tambien (duena: "tp a zona
			   aleatoria OTRA"); used[] ya lo libera abajo, lo vetamos
			   via itembox_last_spawner solo si era el unico usado. */
			for (int i = 0; i < found; i++)
				if (boxes[i].relocated && boxes[i].nid < KAF_ITEMBOX_SPAWN_COUNT && boxes[i].nid != itembox_last_spawner)
					used[boxes[i].nid] = 0;

			int free_count = 0;
			for (int i = 0; i < KAF_ITEMBOX_SPAWN_COUNT; i++)
				if (!used[i])
					free_count++;

			if (free_count > 0)
			{
				int rnd;
			gen:
				rnd = rand() % KAF_ITEMBOX_SPAWN_COUNT;
				if (used[rnd])
					goto gen;
				/* v63 nunca-repetir: vetar el ultimo spawner que uso el
				   roll anterior (si hay alternativa libre). */
				if (rnd == itembox_last_spawner && free_count > 1)
					goto gen;

				itembox_last_spawner = (uint8_t)rnd;
				ItemBox box = MakeItemBox((uint8_t)rnd, itembox_roll_type());
				box.pos.x = (double)kaf_itembox_spawns[rnd][0];
				box.pos.y = (double)kaf_itembox_spawns[rnd][1];
				RAssert(game_spawn(server, (Entity*)&box, sizeof(ItemBox), NULL));
			}
		}
	}

	return map_tick(server);
}

bool kaf_tcpmsg(PeerData* v, Packet* packet)
{
	PacketRead(passtrough, packet, packet_read8, uint8_t);
	PacketRead(type, packet, packet_read8, uint8_t);

	switch (type)
	{
		case CLIENT_KAFMONITOR_ACTIVATE:
		{
			AssertOrDisconnect(v->server, v->in_game);
			PacketRead(nid, packet, packet_read8, uint8_t);
			PacketRead(proj, packet, packet_read8, uint8_t);

			KafBox* box[11];
			if (!game_find(v->server, (Entity**)box, "kafbox", 11))
				break;

			RAssert(kafbox_activate(v->server, box[nid], v->id, proj));
			break;
		}

		/* v62 ITEM BOX v2 — misma superficie anti-cheat que Kaf:
		   AssertOrDisconnect(in_game) + idempotencia en el activate +
		   game_find por tag (cheaters pueden re-romper una rota = no-op). */
		case CLIENT_BOX_ACTIVATE:
		{
			AssertOrDisconnect(v->server, v->in_game);
			PacketRead(nid, packet, packet_read8, uint8_t);
			PacketRead(proj, packet, packet_read8, uint8_t);

			ItemBox* box[KAF_ITEMBOX_SPAWN_COUNT];
			int found = game_find(v->server, (Entity**)box, "itembox", KAF_ITEMBOX_SPAWN_COUNT);
			if (found <= 0)
				break;

			ItemBox* target = NULL;
			for (int i = 0; i < found; i++)
				if (box[i]->nid == nid)
				{
					target = box[i];
					break;
				}
			if (target)
				RAssert(itembox_activate(v->server, target, v->id, proj));
			break;
		}

		/* v63: la caja del nid cayo en un trampolin o al abismo en el
		   cliente que la ve (el server no tiene colision de mapa — el
		   reporte es la unica fuente, patron CLIENT_FWBOLT_HIT). El server
		   marca la entidad "relocate" y el SIGUIENTE kaf_tick la retira y
		   sortea un spawner libre distinto. El cliente la destruyo ya:
		   el despawn llega como SERVER_BOX_STATE 4 normal. */
		case CLIENT_BOX_RELOCATE:
		{
			AssertOrDisconnect(v->server, v->in_game);
			PacketRead(nid, packet, packet_read8, uint8_t);

			ItemBox* box[KAF_ITEMBOX_SPAWN_COUNT];
			int found = game_find(v->server, (Entity**)box, "itembox", KAF_ITEMBOX_SPAWN_COUNT);
			for (int i = 0; i < found; i++)
			{
				if (box[i]->nid != nid || box[i]->relocated)
					continue;
				/* solo una vez por caja (anti-spam): marcamos y dejamos
				   que el tick haga el trabajo ordenado. */
				box[i]->relocated = true;
				break;
			}
			break;
		}
	}

	return true;
}
