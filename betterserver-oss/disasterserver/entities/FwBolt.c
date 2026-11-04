#include <entities/FwBolt.h>

/* v2.14 — Fleetway Amy: flecha de la ballesta (patron laser de Tails,
   patron recto sin gravedad: la flecha de una ballesta no cae).
   Spawn (estado 0) con owner + dir + damage; tick (estado 1) con la
   posicion integrada por el server; despawn (estado 2) al agotarse o
   cuando el cliente tocado/solido reporta CLIENT_FWBOLT_HIT.
   v2.15 («La Torre»): todos los paquetes llevan el id de la entidad
   (hasta 3 flechas simultaneas); al clavarse en un solido pasa a
   estado 3 (plataforma durante FWBOLT_STICK_TIME) y deja de moverse;
   expirada esa vida, despawn normal. */

bool fwbolt_init(Server* server, Entity* entity)
{
        FwBolt* bolt = (FwBolt*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_FWBOLT_STATE);
        PacketWrite(&pack, packet_write8, 0);
        PacketWrite(&pack, packet_write16, bolt->id);
        PacketWrite(&pack, packet_write16, (uint16_t)bolt->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)bolt->pos.y);
        PacketWrite(&pack, packet_write16, bolt->owner);
        PacketWrite(&pack, packet_write8, (uint8_t)bolt->dir);
        PacketWrite(&pack, packet_write8, bolt->damage);
        server_broadcast(server, &pack, true);

        return true;
}

bool fwbolt_tick(Server* server, Entity* entity)
{
        FwBolt* bolt = (FwBolt*)entity;

        if (bolt->timer <= 0)
                return false;

        /* Clavada (v2.15): no se mueve ni se reenvia; solo consume la
         * vida de plataforma. El cliente ya la tiene posicionada por el
         * estado 3 (fiable); reenviar la posicion seria ruido. */
        if (bolt->stuck)
        {
                bolt->timer -= server->delta;
                return true;
        }

        /* wrap del mapa YouCan'tRun (13), igual que el laser de Tails */
        if (server->game.map != 13)
        {
                if (bolt->pos.x <= 0)
                        return false;
        }
        else
        {
                if (bolt->pos.x < 0)
                        bolt->pos.x = 3648;
                else if (bolt->pos.x > 3648)
                        bolt->pos.x = 0;
        }

        /* v2.15.1 — FIX «LA FLECHA TRASPASA LA PARED»: ya NO se difunde el
         * tick de posicion (estado 1). El server no conoce el mapa y sus
         * saltos de 14 px por UDP hacian que los clientes vieran la flecha
         * saltarse la pared de un teleport (el evento de colision de GM
         * solo dispara con solape al final del frame). Ahora el vuelo lo
         * simula cada cliente localmente (obj_fw_bolt/Step: barrido
         * sub-pixel con la misma velocidad, FW_ARROW_FLIGHT = FWBOLT_SPEED)
         * y el primer cliente que la ve clavarse reporta
         * CLIENT_FWBOLT_HIT tipo 1; el server fija la posicion para todos
         * con el estado 3. Esta posicion interna solo sirve para el wrap
         * y el limite izquierdo de arriba. */
        bolt->pos.x += (float)(bolt->dir * FWBOLT_SPEED * server->delta);
        bolt->timer -= server->delta;

        return true;
}

bool fwbolt_uninit(Server* server, Entity* entity)
{
        FwBolt* bolt = (FwBolt*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_FWBOLT_STATE);
        PacketWrite(&pack, packet_write8, 2);
        PacketWrite(&pack, packet_write16, bolt->id);
        server_broadcast(server, &pack, true);

        return true;
}
