#include <entities/BlazeFireball.h>

/* v2.2 (TTB): bola de fuego de Blaze (patron laser de Tails).
   v2.9: PROYECTIL REBOTANTE — gravedad + velocidad vertical; los
   rebotes los reportan los clientes (ver Game.c: case
   CLIENT_BLAZE_FIREBALL_BOUNCE) porque solo ellos tienen la colision
   del mapa. El server voltea la velocidad (elasticamente) y sigue
   tick-eando: todo el mundo ve la nueva trayectoria en los ticks. */

bool bfire_init(Server* server, Entity* entity)
{
        BlazeFireball* fb = (BlazeFireball*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
        PacketWrite(&pack, packet_write8, 0);
        PacketWrite(&pack, packet_write16, fb->id);
        PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.y);
        PacketWrite(&pack, packet_write8, (uint8_t)fb->dir);
        server_broadcast(server, &pack, true);

        return true;
}

bool bfire_tick(Server* server, Entity* entity)
{
        BlazeFireball* fb = (BlazeFireball*)entity;

        if (fb->timer <= 0)
                return false;

        if (fb->block > 0)
                fb->block -= server->delta;

        if (fb->vy > 127.0)
                fb->vy = 127.0;
        else if (fb->vy < -127.0)
                fb->vy = -127.0;

        /* wrap del mapa YouCan'tRun (13), igual que el laser de Tails */
        if (server->game.map != 13)
        {
                if (fb->pos.x <= 0)
                        return false;
        }
        else
        {
                if (fb->pos.x < 0)
                        fb->pos.x = 3648;
                else if (fb->pos.x > 3648)
                        fb->pos.x = 0;
        }

        /* v2.9: integracion de la fisica del proyectil rebotante */
        fb->pos.x += (float)(fb->dir * BFIRE_SPEED) * server->delta;
        fb->pos.y += (float)(fb->vy * server->delta);
        fb->vy += (float)(BFIRE_GRAV * server->delta);
        fb->timer -= server->delta;

        /* tick con nid + dir + vy (cuantizada a s8) para que cada
           cliente rote el cometa siguiendo la trayectoria */
        Packet pack;
        PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
        PacketWrite(&pack, packet_write8, 1);
        PacketWrite(&pack, packet_write16, fb->id);
        PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.x);
        PacketWrite(&pack, packet_write16, (uint16_t)fb->pos.y);
        PacketWrite(&pack, packet_write8, (uint8_t)fb->dir);
        PacketWrite(&pack, packet_write8, (uint8_t)(int8_t)fb->vy);
        server_broadcast(server, &pack, false);

        return true;
}

bool bfire_uninit(Server* server, Entity* entity)
{
        BlazeFireball* fb = (BlazeFireball*)entity;

        Packet pack;
        PacketCreate(&pack, SERVER_BLAZE_FIREBALL_STATE);
        PacketWrite(&pack, packet_write8, 2);
        PacketWrite(&pack, packet_write16, fb->id);
        server_broadcast(server, &pack, true);

        return true;
}

/* v2.9: aplica un rebote reportado por un cliente. Devuelve true si
   lo aplico (primer informe del choque) o false si llego duplicado
   (lockout) o la bola no existe. Mueve la posicion al punto del
   solape que vio el cliente y la empuja un tick en la NUEVA direccion
   para desincrustarla ya. */
bool bfire_bounce(Server* server, Entity* entity, uint8_t flip, uint16_t x, uint16_t y)
{
        BlazeFireball* fb = (BlazeFireball*)entity;

        if (fb->block > 0)
                return false;

        fb->block = BFIRE_BLOCK;

        if (flip & 1)
                fb->dir = -fb->dir;

        if (flip & 2)
                fb->vy = fb->vy == 0 ? -3.0 : -fb->vy;

        fb->pos.x = (float)x + (float)(fb->dir * 12);
        fb->pos.y = (float)y + (fb->vy < 0 ? -8.0f : 8.0f);

        return true;
}
