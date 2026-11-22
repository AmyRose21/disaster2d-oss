#include <maps/KindAndFair.h>
#include <entities/KAFSpeedBox.h>
#include <entities/ItemBox.h>
#include <States.h>
#include <CMath.h>
#include <stdlib.h>

/* v68 ITEM BOX v7 — CENTRALIZACION: el roll de cajas (v62-v67) y los
   cases CLIENT_BOX_ACTIVATE / CLIENT_BOX_RELOCATE se mudaron al sistema
   central ItemBoxMap.c/.h (hooks en Game.c: checkstart/state_tick/
   handletcp) y ahora corren para TODOS los mapas con tabla derivada
   (ItemBoxSpawnTables.c). Kind and Fair sigue con su tabla v65
   verificada (la del mapa 7 en el dispatch). Este archivo vuelve a
   su logica propia de la casa: monitores Kaf y timers de mapa.
   Historial completo del sistema: LEEME_ITEMBOX_V62.txt v62-v68. */

bool kaf_init(Server* server)
{
	RAssert(map_time(server, 3 * TICKSPERSEC, 20)); //180
	RAssert(map_ring(server, 5));

	for (uint8_t i = 0; i < 11; i++)
		RAssert(game_spawn(server, (Entity*)&(MakeKafBox(i)), sizeof(KafBox), NULL));

	/* v62: cero cajas al inicio (los primeros 15 s la caza arranca
	   limpia); el primer roll llega via itemboxmap_tick central. */
	return true;
}

bool kaf_tick(Server* server)
{
	/* v68: el roll de ITEM BOX vive ahora en Game.c -> itemboxmap_tick
	   (sistema central para todos los mapas). Aqui queda solo la logica
	   de mapa de la casa. */
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

		/* v68: CLIENT_BOX_ACTIVATE y CLIENT_BOX_RELOCATE los maneja el
		   sistema central (itemboxmap_tcpmsg en Game.c, tras este
		   tcp_msg — packet_seek(0) re-lee el cuerpo). */
	}

	return true;
}
