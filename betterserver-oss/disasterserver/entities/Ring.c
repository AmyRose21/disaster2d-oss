#include <entities/Ring.h>
#include <stdint.h>
#include <stdlib.h> /* v76: rand() declarado explicito (patron ItemBoxMap.c) —
                      antes iba implicito y gcc moderno lo rechaza */
#include <CMath.h>

/* v76 RING VARIETY (regla de la duena): los spawns de anillos deben ser
   VARIADOS — nunca "siempre en el mismo lugar". El roll original solo
   vetaba los slots OCUPADOS, asi que un anillo recogido en el punto X
   podia volver a salir en X una y otra vez. Ahora se guarda un FIFO de
   los ultimos RING_RECENT_MAX slots usados (vive en Server->game: el
   literal compuesto del game_start lo pone a cero cada ronda — cero
   reset manual, patron bring_loc). Red ring y anillo normal son LA
   MISMA entidad (flag red al 10%): comparten tabla de spawners por
   diseno, y la variedad aplica a ambos. */

#define RING_RECENT_MAX 4

static bool ring_recent_has(Server* server, int rid)
{
        for (int i = 0; i < server->game.ring_recent_len; i++)
                if (server->game.ring_recent[i] == rid)
                        return true;
        return false;
}

bool ring_init(Server* server, Entity* entity)
{
        Ring* ring = (Ring*)entity;

        int cnt = 0;
        for (int i = 0; i < g_mapList[server->game.map].ring_count; i++)
        {
                if (server->game.rings[i])
                        cnt++;
        }

        if (cnt >= g_mapList[server->game.map].ring_count)
                return false;

        /* v76: cuantos slots libres NO estan en la memoria reciente. Si
           hay al menos uno, el sorteo veta los recientes (goto gen); si no
           hay ninguno (mapa saturado de anillos vivos), se acepta
           cualquiera para no bloquear el spawn. */
        int fresh = 0;
        for (int i = 0; i < g_mapList[server->game.map].ring_count; i++)
        {
                if (!server->game.rings[i] && !ring_recent_has(server, i))
                        fresh++;
        }

        int rnd;
gen:
        rnd = rand() % g_mapList[server->game.map].ring_count;

        if (server->game.rings[rnd])
                goto gen;

        /* v76 nunca-repetir: con alternativas frescas disponibles, los
           ultimos slots usados quedan vetados (el mismo patron
           nunca-repetir del itembox_last_spawner, generalizado a N). */
        if (fresh > 0 && ring_recent_has(server, rnd))
                goto gen;

        /* push FIFO en la memoria reciente */
        if (server->game.ring_recent_len < RING_RECENT_MAX)
        {
                server->game.ring_recent[server->game.ring_recent_len] = (uint8_t)rnd;
                server->game.ring_recent_len++;
        }
        else
        {
                for (int i = 1; i < RING_RECENT_MAX; i++)
                        server->game.ring_recent[i - 1] = server->game.ring_recent[i];
                server->game.ring_recent[RING_RECENT_MAX - 1] = (uint8_t)rnd;
        }

        server->game.rings[rnd] = true;
        ring->rid = (uint8_t)rnd;
        ring->red = g_mapList[server->game.map].spawn_red_rings && (rand() % 100 <= 10);

        Packet pack;
        PacketCreate(&pack, SERVER_RING_STATE);
        PacketWrite(&pack, packet_write8, 0);
        PacketWrite(&pack, packet_write8, ring->rid);
        PacketWrite(&pack, packet_write16, ring->id);
        PacketWrite(&pack, packet_write8, ring->red);
        server_broadcast(server, &pack, true);

        return true;
}

bool ring_uninit(Server* server, Entity* entity)
{
        Ring* ring = (Ring*)entity;
        server->game.rings[ring->rid] = 0;

        Packet pack;
        PacketCreate(&pack, SERVER_RING_STATE);
        PacketWrite(&pack, packet_write8, 1);
        PacketWrite(&pack, packet_write8, ring->rid);
        PacketWrite(&pack, packet_write16, ring->id);
        server_broadcast(server, &pack, true);

        return true;
}
