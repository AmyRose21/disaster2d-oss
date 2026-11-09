#ifndef MAPS_H
#define MAPS_H
#include <Server.h>

typedef struct
{
        const char* name;

        struct
        {
                bool (*init)(Server*);
                bool (*tick)(Server*);
                bool (*tcp_msg)(PeerData*, Packet*);
                bool (*left)(PeerData*);
        } cb;

        uint8_t  spawn_red_rings;
        uint8_t  ring_count;
} Map;

/* 22 mapas (0-21): [21] SkyBase, porte del mod abandonado "TD2DR:
 * Project SkyBase" de ColdestTea (GameJolt 855567). Los dos portes de
 * Sonic MAX ("SMax Green Hill" 21 y "SMax Emerald Hill" 22) siguen
 * RETIRADOS de la seleccion porque estaban corruptos (la descripcion del
 * 22 quedaba fuera de rango en el lobby y crasheaba a los clientes).
 * El "Hill" original es el 12. */
#define MAP_COUNT 22
extern Map g_mapList[MAP_COUNT];

bool map_init   (Server* server);
bool map_tick   (Server* server);
bool map_tcpmsg (PeerData* v, Packet* packet);
bool map_left   (PeerData* v);

bool map_time (Server* server, double seconds, float mul);
bool map_ring (Server* server, int ringcoff);

/* v4.7: sortea un mapa al azar (mapas activos del Config.json, sin
 * repetir el ultimo): lo usan las rutas de practica */
int8_t map_pick_random (Server* server);

#endif
