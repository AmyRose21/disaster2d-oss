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

/* 25 mapas (0-24): [21] SkyBase (porte "TD2DR: Project SkyBase", ColdestTea),
 * [22] Negagen Temple (porte "TD2DR NU Project", Remodify Studios),
 * [23] Wood Zone (porte "Wood zone in td2dr!! MAP MOD!" de DeklynTDH,
 * GameJolt 865011: rework del layout de "..." con arte de madera) y
 * [24] SkySanctuary (porte "TD2DR SkySanctuaryZone mod!" de CranberryStudios,
 * GameBanana 495859: rework del layout de Hide and Seek Act 2). Ambos
 * incluidos como mapas variante. Los dos portes de Sonic MAX siguen
 * RETIRADOS de la seleccion (mapas corruptos). El "Hill" original es el 12. */
#define MAP_COUNT 25
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
