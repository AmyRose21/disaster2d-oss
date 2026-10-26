#include <Player.h>
#include <Packet.h>
#include <Server.h>
#include <Colors.h>
#include <States.h>

#define PLRSTATE_ESCAPED 4
#define PLRSTATE_ALIVE 3
#define PLRSTATE_DEAD 2
#define PLRSTATE_DEMONIZED 1
#define PLRSTATE_EXE 0

const char* SHAMES_1[] = 
{
	CLRCODE_RED "(my skill issue makes me allergic to moving)",
	CLRCODE_RED "(i'm afraid to leave my camp spot)",
	CLRCODE_RED "(how am i not bored of camping)",
	CLRCODE_RED "(i'm too bad to move around the map)",
	CLRCODE_RED "(i just like being a brick)"
};
#define SHAMES1_CNT 5

const char* SHAMES_2[] = 
{
	CLRCODE_RED "(i can't win without camping bodies)",
	CLRCODE_RED "(i'm afraid revived players will make me lose)",
	CLRCODE_RED "(i camp bodies cuz im bad)"
};
#define SHAMES2_CNT 3

/* >>[endings v2]<< Duracion (segundos) de las pistas de ending del cliente
 * (sounds/*.mp3, medidas con ffprobe). El servidor espera a que termine la
 * cancion antes de volver al lobby. Si reemplazas una pista en GameMaker,
 * actualiza aqui su duracion y recompila el servidor. */
#define ENDINGLEN_BEST      24.17
#define ENDINGLEN_BEST_ALT  20.41
#define ENDINGLEN_DUO       22.73
#define ENDINGLEN_SOLO      27.49
#define ENDINGLEN_SOLO_ALT  21.95
#define ENDINGLEN_STD       24.25
#define ENDINGLEN_STD_ALT   23.23
#define ENDINGLEN_EXEWIN    15.34 /* vanilla mus_exewin (bad ending) */
#define ENDINGLEN_SURVWIN   14.58 /* vanilla mus_survwin (red de seguridad) */
#define ENDINGLEN_TIMEOVER  14.58 /* vanilla mus_timeover */
#define ENDING_MARGIN       1.0

static uint8_t results_plr_type(Server* server, PeerData* data)
{
	/* Misma clasificacion que reciben las filas de resultados: el cliente
	 * (net_state_results) cuenta con estos tipos cuantos escaparon (4) y
	 * cuantos supervivientes hay (>= 1). 0=EXE 1=DEMONIZED 2=DEAD 3=ALIVE 4=ESCAPED */
	uint8_t type = PLRSTATE_ALIVE;

	if (data->plr.flags & PLAYER_ESCAPED)
		type = PLRSTATE_ESCAPED;
	if (data->plr.flags & PLAYER_DEMONIZED)
		type = PLRSTATE_DEMONIZED;
	else if (data->plr.flags & PLAYER_DEAD)
		type = PLRSTATE_DEAD;
	else if (server->game.exe == data->id)
		type = PLRSTATE_EXE;

	return type;
}

static void results_music_countdown(Server* server)
{
	int escaped = 0;
	int surv = 0;

	/* Recorrer las MISMAS listas que CLIENT_RESULTS_REQUEST envia como filas
	 * (jugadores conectados + los que se fueron a mitad de partida) para contar
	 * exactamente lo mismo que contara el cliente al recibirlas. */
	for (size_t i = 0; i < server->peers.capacity; i++)
	{
		PeerData* data = (PeerData*)server->peers.ptr[i];
		if (!data || !data->in_game)
			continue;

		uint8_t type = results_plr_type(server, data);
		if (type == PLRSTATE_ESCAPED)
			escaped++;
		if (type >= PLRSTATE_DEMONIZED)
			surv++;
	}

	for (size_t i = 0; i < server->game.left.capacity; i++)
	{
		PeerData* data = (PeerData*)server->game.left.ptr[i];
		if (!data || !data->in_game)
			continue;

		uint8_t type = results_plr_type(server, data);
		if (type == PLRSTATE_ESCAPED)
			escaped++;
		if (type >= PLRSTATE_DEMONIZED)
			surv++;
	}

	double len = 0.0;

	if (server->game.ending == ED_SURVWIN && escaped > 0)
	{
		/* Misma variante base/Alt que el cliente (obj_results/Alarm_0.gml):
		 * (segundos de ronda + escapados) % 2. Como 60 es par, el % 60 que le
		 * aplica el cliente al tiempo no cambia la paridad: ambos lados derivan
		 * siempre el mismo valor y todos oyen la misma pista. */
		int alt = (server->game.time_sec + escaped) % 2;

		/* Mismo orden de categorias que Alarm_0.gml (incluido 2-de-2 = Best) */
		if (escaped >= surv)
			len = alt ? ENDINGLEN_BEST : ENDINGLEN_BEST_ALT;
		else if (escaped == 1)
			len = alt ? ENDINGLEN_SOLO : ENDINGLEN_SOLO_ALT;
		else if (escaped == 2)
			len = ENDINGLEN_DUO;
		else
			len = alt ? ENDINGLEN_STD : ENDINGLEN_STD_ALT;
	}
	else if (server->game.ending == ED_EXEWIN)
	{
		/* Bad ending vanilla (mus_exewin): solo alargar lo justo para no cortarla */
		len = ENDINGLEN_EXEWIN;
	}
	else if (server->game.ending == ED_SURVWIN)
	{
		/* Ganan los survivors pero nadie escapo (caso imposible): red de
		 * seguridad mus_survwin, tambien sin cortar */
		len = ENDINGLEN_SURVWIN;
	}
	else
	{
		/* ED_TIMEOVER: mus_timeover */
		len = ENDINGLEN_TIMEOVER;
	}

	/* Nunca acortar el vanilla de 15s (mus_survwin y mus_timeover caben en 15s).
	 * El margen cubre el retardo de arranque de la musica en el cliente
	 * (respuesta del request + alarm[0] = 4 frames + latencia de red). */
	if (len + ENDING_MARGIN > 15.0)
		server->results.countdown = (len + ENDING_MARGIN) * TICKSPERSEC;
}

int compare(const PeerData** plr1, const PeerData** plr2)
{
	const PeerData* a = *plr1;
	const PeerData* b = *plr2;

	if (a->plr.flags & PLAYER_KILLER || b->plr.flags & PLAYER_KILLER)
		return ((b->plr.flags & PLAYER_KILLER) > 0) - ((a->plr.flags & PLAYER_KILLER) > 0);

	if (a->plr.flags & PLAYER_LEFT || b->plr.flags & PLAYER_LEFT)
		return ((a->plr.flags & PLAYER_LEFT) > 0) - ((b->plr.flags & PLAYER_LEFT) > 0);

	if (a->plr.flags & PLAYER_DEMONIZED || b->plr.flags & PLAYER_DEMONIZED)
		return ((a->plr.flags & PLAYER_DEMONIZED) > 0) - ((b->plr.flags & PLAYER_DEMONIZED) > 0);

	if (a->plr.flags & PLAYER_DEAD || b->plr.flags & PLAYER_DEAD)
		return ((a->plr.flags & PLAYER_DEAD) > 0) - ((b->plr.flags & PLAYER_DEAD) > 0);

	return 0;
}

int compare2(const PeerData** plr1, const PeerData** plr2)
{
	const PeerData* a = *plr1;
	const PeerData* b = *plr2;

	if (a->plr.flags & PLAYER_KILLER || b->plr.flags & PLAYER_KILLER)
		return ((b->plr.flags & PLAYER_KILLER) > 0) - ((a->plr.flags & PLAYER_KILLER) > 0);

	if (a->plr.flags & PLAYER_LEFT || b->plr.flags & PLAYER_LEFT)
		return 0;

	if (a->plr.flags & PLAYER_DEMONIZED || b->plr.flags & PLAYER_DEMONIZED)
		return 0;

	if ((a->plr.flags & PLAYER_DEAD) > 0 == (b->plr.flags & PLAYER_DEAD) > 0)
		return (int)(b->plr.stats.danger_time - a->plr.stats.danger_time);

	return 0;
}

bool results_send(Server* server, PeerData* v, PeerData* data, bool has_quit)
{
	uint8_t type = results_plr_type(server, data);

	Packet pack;
	PacketCreate(&pack, SERVER_RESULTS_DATA);

	String nickname;
	const char* postfix = "";

	if (g_config.pride)
	{
		if (data->plr.stats.brain_damage && (data->plr.flags & PLAYER_ESCAPED))
			postfix = SHAMES_1[rand() % SHAMES1_CNT];

		if (data->plr.stats.camp_time >= 30 * TICKSPERSEC)
			postfix = SHAMES_2[rand() % SHAMES2_CNT];
	}

	nickname.len = snprintf(nickname.value, 129, "%s %s", data->nickname.value, postfix) + 1;

	PacketWrite(&pack, packet_writestr, nickname);
	PacketWrite(&pack, packet_write8, 	data->exe_char != EX_NONE ? data->exe_char : data->surv_char);
	PacketWrite(&pack, packet_write8,	server->game.ending);
	PacketWrite(&pack, packet_write16,	server->game.time_sec)
	PacketWrite(&pack, packet_write8,	has_quit);
	PacketWrite(&pack, packet_write8,	type);

	PacketWrite(&pack, packet_write16,		data->plr.stats.rings);
	PacketWrite(&pack, packet_write16,		data->plr.stats.kills);
	PacketWrite(&pack, packet_write16,		data->plr.stats.damage);
	PacketWrite(&pack, packet_write16,		data->plr.stats.damage_taken);
	PacketWrite(&pack, packet_write16,		data->plr.stats.stun_time);
	PacketWrite(&pack, packet_write16,		data->plr.stats.stuns);
	PacketWrite(&pack, packet_write16,		data->plr.stats.hp_restored);
	PacketWrite(&pack, packet_writedouble,	data->plr.stats.survive_time);
	PacketWrite(&pack, packet_writedouble,	data->plr.stats.danger_time);

	return packet_send(v->peer, &pack, true);
}

bool results_init(Server* server)
{
	Debug("Attepting to enter ST_RESULTS...");
	server->state = ST_RESULTS;
	server->results.countdown = 15 * TICKSPERSEC;
	server->results.music_synced = false;

	/* >>[endings v2]<< Esperar a que termine la musica de ending en vez de
	 * cortarla a los 15s. Estimacion inicial; se re-sincroniza con las filas
	 * exactas al llegar el primer CLIENT_RESULTS_REQUEST. */
	results_music_countdown(server);

	Packet pack;
	PacketCreate(&pack, SERVER_RESULTS);
	PacketWrite(&pack, packet_write8, server->game.map);
	server_broadcast(server, &pack, true);

	Info("Server is now in " LOG_PUR "Results");
	return true;
}

bool results_uninit(Server* server)
{
	for (size_t i = 0; i < server->game.entities.capacity; i++)
	{
		Entity* entity = (Entity*)server->game.entities.ptr[i];
		if (!entity)
			continue;

		free(entity);
	}
	dylist_free(&server->game.entities);

	// Clean up after game
	for (size_t i = 0; i < server->game.left.capacity; i++)
	{
		PeerData* player = (PeerData*)server->game.left.ptr[i];
		if (!player)
			continue;

		free(player);
	}
	dylist_free(&server->game.left);

	return lobby_init(server);
}

bool results_state_tick(Server* server)
{
	server->results.countdown -= server->delta;
	
	if (server->results.countdown <= 0)
		return results_uninit(server);

	return true;
}

bool results_state_handle(PeerData* v, Packet* packet)
{
	PacketRead(_passtrough, packet, packet_read8, uint8_t);
	PacketRead(type, packet, packet_read8, uint8_t);

	switch (type) 
	{
		case CLIENT_RESULTS_REQUEST:
		{
			/* >>[endings v2]<< Re-sincronizar la espera con las filas EXACTAS
			 * que se envian ahora (lo mismo que contara el cliente). Solo la
			 * primera peticion: las siguientes traen datos identicos. */
			if (!v->server->results.music_synced)
			{
				results_music_countdown(v->server);
				v->server->results.music_synced = true;
			}

			PeerData* sort[7];
			int len = 0;
			memset(sort, 0, sizeof(PeerData*) * 7);

			for (size_t i = 0; i < v->server->peers.capacity; i++)
			{
				PeerData* data = (PeerData*)v->server->peers.ptr[i];
				if (!data)
					continue;

				if(!data->in_game)
					continue;

				sort[len++] = data;
			}

			for (size_t i = 0; i < v->server->game.left.capacity; i++)
			{
				PeerData* data = (PeerData*)v->server->game.left.ptr[i];
				if (!data)
					continue;

				if(!data->in_game)
					continue;

				sort[len++] = data;
			}

			qsort(sort, len, sizeof(PeerData*), (int (*)(const void *, const void *))compare);
			qsort(sort, len, sizeof(PeerData*), (int (*)(const void *, const void *))compare2);

			for (size_t i = 0; i < len; i++)
			{
				PeerData* data = (PeerData*)sort[i];
				if (!data)
					continue;

				RAssert(results_send(v->server, v, data, data->plr.flags & PLAYER_LEFT));
			}
			break;
		}
		
		case CLIENT_CHAT_MESSAGE:
		{
			if (v->in_game)
				break;

			PacketRead(pid, packet, packet_read16, uint16_t);
			PacketRead(msg, packet, packet_readstr, String);
			AssertOrDisconnect(v->server, string_length(&msg) <= 40);

			v->timeout = 0;

			Info("[%s] (id %d): %s", v->nickname.value, v->id, msg.value);
			if (!server_cmd_handle(v->server, server_cmd_parse(&msg), v, &msg) && g_config.chatfix)
				server_broadcast_msg(v->server, v->id, msg.value);

			break;
		}
	}

	return true;
}