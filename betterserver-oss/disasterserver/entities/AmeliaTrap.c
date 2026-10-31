#include <entities/AmeliaTrap.h>

/* v2.4 (TTB): trampa de Amelia. La vida maxima (60 s) la lleva el
   server: al agotarse se retira en silencio (state 1) y al pisarla
   alguien del lado del EXE (CLIENT_AMELIA_TRAP_TRIGGER desde el
   cliente de la victima) se reenvia state 2 a todos. El stun y el
   slow los aplica el cliente de la victima. */

bool amelia_trap_trigger(Server* server, Entity* entity)
{
        AmeliaTrap* trap = (AmeliaTrap*)entity;

        if (trap->triggered)
                return false;

        trap->triggered = true;

        Packet pack;
        PacketCreate(&pack, SERVER_AMELIA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 2);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);

        return false; // despawn
}

bool amelia_trap_init(Server* server, Entity* entity)
{
        AmeliaTrap* trap = (AmeliaTrap*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_AMELIA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 0);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);
        return true;
}

bool amelia_trap_tick(Server* server, Entity* entity)
{
        AmeliaTrap* trap = (AmeliaTrap*)entity;

        trap->timer -= server->delta;

        if (trap->timer <= 0)
                return false; /* 60 s agotados: retirada silenciosa (state 1) */

        return true;
}

bool amelia_trap_uninit(Server* server, Entity* entity)
{
        AmeliaTrap* trap = (AmeliaTrap*)entity;

        /* solo avisar remove si NO se activo (el trigger ya mando el
           state 2 y el cliente la destruyo) */
        if (trap->triggered)
                return true;

        Packet pack;
        PacketCreate(&pack, SERVER_AMELIA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 1);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);
        return true;
}
