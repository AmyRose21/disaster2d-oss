#include <entities/JinnaTrap.h>

/* v3 (D.I.B.): portal trampa de Jinna. La vida maxima (v4: 70 s, era
   20 s) la lleva el server: al agotarse se retira en silencio (state
   1) y al pisarla un superviviente (CLIENT_JINNA_TRAP_HIT desde el
   cliente de la victima) se reenvia state 2 a todos y Game.c emite
   SERVER_JINNA_TRAP_HIT con los efectos (dano + TP hasta Jinna sin
   i-frames, o la absorcion si la victima es Vanilla). */

bool jinna_trap_trigger(Server* server, Entity* entity)
{
        JinnaTrap* trap = (JinnaTrap*)entity;

        if (trap->triggered)
                return false;

        trap->triggered = true;

        Packet pack;
        PacketCreate(&pack, SERVER_JINNA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 2);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);

        return false; /* despawn */
}

bool jinna_trap_init(Server* server, Entity* entity)
{
        JinnaTrap* trap = (JinnaTrap*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_JINNA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 0);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);
        return true;
}

bool jinna_trap_tick(Server* server, Entity* entity)
{
        JinnaTrap* trap = (JinnaTrap*)entity;

        trap->timer -= server->delta;

        if (trap->timer <= 0)
                return false; /* 70 s agotados (v4): retirada silenciosa (state 1) */

        return true;
}

bool jinna_trap_uninit(Server* server, Entity* entity)
{
        JinnaTrap* trap = (JinnaTrap*)entity;

        /* solo avisar remove si NO se activo (el trigger ya mando el
           state 2 y los clientes la destruyeron) */
        if (trap->triggered)
                return true;

        Packet pack;
        PacketCreate(&pack, SERVER_JINNA_TRAP_STATE);
        PacketWrite(&pack, packet_write8, 1);
        PacketWrite(&pack, packet_write16, trap->id);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)trap->pos.y);
        server_broadcast(server, &pack, true);
        return true;
}
