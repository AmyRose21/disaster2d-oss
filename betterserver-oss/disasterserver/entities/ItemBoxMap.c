#include <entities/ItemBoxMap.h>
#include <entities/ItemBox.h>
#include <Server.h>
#include <CMath.h>
#include <stdlib.h>

/* v68 ITEM BOX v7 — SISTEMA CENTRAL (todos los mapas).
   El roll de v62-v67 (que vivia en kaf_tick) generalizado: la tabla
   de zonas llega por map id desde ItemBoxSpawnTables.c (auto-generada
   con derive_spawns_all_v68.py: suelo real bajo el punto — solidos +
   plataformas, la caja aterriza sobre obj_floor_parent en el cliente —,
   sin abismo, sin resorte/hazard a 48px, nada de la fila alta, dedupe
   96x64, caja APOYADA y=top_suelo-30; en Torture Cave y Haunting Dream
   el terreno es un mega-sprite de colision per-pixel y el generador
   leyo el PNG directamente).

   TODO el anti-cheat de la casa se mantiene (patron KindAndFair v66):
   - CLIENT_BOX_ACTIVATE: AssertOrDisconnect(in_game) + busqueda por
     tag + idempotencia (una caja ROTA ya no se re-rompe: activate la
     rechaza) + game_find por tag (re-romper una rota = no-op).
   - CLIENT_BOX_RELOCATE: one-shot por entidad (flag relocated).
   v67 (no repetir): patron por-puntero ItemBox* box[] + -> en TODOS los
   game_find (el UB de structs in-place mataba el roll al re-entrar). */

/* cadena de estado por ronda (reset en itemboxmap_init: los static de
   v62-v67 usaban la heuristica elapsed<1.0; ahora el reset es explicito
   en el checkstart de cada ronda — cero dependencia del valor de elapsed). */
static double itembox_next_roll = 0;
static int itembox_alive = -1;   /* -1: ronda sin roll agendado */
/* v76 VARIETY: el nunca-repetir de v68 (un solo itembox_last_spawner)
   se generaliza a un FIFO de ITEMBOX_RECENT_MAX spawners — regla de la
   duena: spawns SIEMPRE variados, no el mismo sitio una y otra vez. */
#define ITEMBOX_RECENT_MAX 3
static uint8_t itembox_recent[ITEMBOX_RECENT_MAX];
static int itembox_recent_len = 0;

static bool itembox_recent_has(int zone)
{
        for (int i = 0; i < itembox_recent_len; i++)
                if (itembox_recent[i] == zone)
                        return true;
        return false;
}

static void itembox_recent_push(int zone)
{
        if (itembox_recent_len < ITEMBOX_RECENT_MAX)
        {
                itembox_recent[itembox_recent_len] = (uint8_t)zone;
                itembox_recent_len++;
        }
        else
        {
                for (int i = 1; i < ITEMBOX_RECENT_MAX; i++)
                        itembox_recent[i - 1] = itembox_recent[i];
                itembox_recent[ITEMBOX_RECENT_MAX - 1] = (uint8_t)zone;
        }
}

/* Sorteo con pesos desiguales (tabla identica a la del cliente:
   macros BOX_*_WEIGHT de net_state_game.gml). */
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

bool itemboxmap_init(Server* server)
{
        /* reset por ronda: agenda el primer roll tras FIRST_DELAY.
           Si el mapa no tiene tabla (0 zonas), el sistema queda inactivo
           en toda la ronda (tick no hace nada). */
        itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY;
        itembox_alive = 0;
        /* v76: la memoria reciente de spawners tambien se resetea por
           ronda (los static de v62-v67 usaban heuristica; aqui el reset
           es explicito, igual que itembox_alive). */
        itembox_recent_len = 0;
        for (int i = 0; i < ITEMBOX_RECENT_MAX; i++)
                itembox_recent[i] = 255;
        return true;
}

bool itemboxmap_tick(Server* server)
{
        const ItemBoxSpawnTable* tab = &g_itembox_tables[server->game.map];

        if (tab->zones <= 0 || tab->points == NULL)
                return true; /* mapa sin zonas: inactivo */

        if (itembox_alive < 0)
        {
                /* ronda que empezo sin init (server viejo reconectado):
                   agenda igual — no debe pasar nunca con el hook puesto. */
                itembox_alive = 0;
                itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY;
        }

        if (server->game.elapsed < itembox_next_roll)
                return true;

        itembox_next_roll = server->game.elapsed + ITEMBOX_SPAWN_COFF;

        /* contar vivas (timer < 0) — las rotas en countdown todavia ocupan
           visualmente boxused, pero la pool de spawn son las VIVAS
           unicamente (max 4 cajas rompibles a la vez).
           v67: patron por-puntero (ItemBox* box[] + ->). */
        ItemBox* boxes[ITEMBOX_MAX * 3];
        int found = game_find(server, (Entity**)boxes, "itembox", ITEMBOX_MAX * 3);
        int alive = 0;
        for (int i = 0; i < found; i++)
                if (boxes[i]->timer < 0)
                        alive++;

        /* RELOCATE: las cajas marcadas por CLIENT_BOX_RELOCATE se retiran
           AQUI (despawn state 4 al cliente via uninit) y su spawner vuelve
           a la pool del roll de abajo — la nueva nace en OTRO punto libre en
           el MISMO tick (tp inmediato a otra zona, regla de la duena). */
        for (int i = 0; i < found; i++)
        {
                if (!boxes[i]->relocated)
                        continue;
                /* forzar su muerte en este tick: el game_entity_tick llama
                   uninit (difunde state 4) y retira la entidad. */
                boxes[i]->timer = 0;
        }

        if (alive < ITEMBOX_MAX && found < ITEMBOX_MAX * 3)
        {
                /* un spawner queda ocupado por TODA entidad existente (viva o
                   ROTA en countdown — la rota todavia muestra su residuo
                   boxused ~25-30 s). nid ES el spawner: caja y residuo viven
                   y mueren en el mismo punto. */
                uint8_t used[256];
                memset(used, 0, sizeof(used));
                for (int i = 0; i < found; i++)
                        if (boxes[i]->nid < tab->zones)
                                used[boxes[i]->nid] = 1;

                int free_count = 0;
                for (int i = 0; i < tab->zones; i++)
                        if (!used[i])
                                free_count++;

                /* v76: cuantas libres NO estan en la memoria reciente —
                   si hay al menos una, el sorteo veta TODOS los recientes. */
                int fresh_count = 0;
                for (int i = 0; i < tab->zones; i++)
                        if (!used[i] && !itembox_recent_has(i))
                                fresh_count++;

                if (free_count > 0)
                {
                        int rnd;
                gen:
                        rnd = rand() % tab->zones;
                        if (used[rnd])
                                goto gen;
                        /* nunca-repetir (v76): con alternativas frescas, se
                           vetan los ultimos ITEMBOX_RECENT_MAX spawners
                           usados (antes solo se vetaba el inmediato). Si
                           no quedan frescas libres, se acepta cualquiera
                           para no bloquear el spawn. */
                        if (fresh_count > 0 && itembox_recent_has(rnd))
                                goto gen;

                        itembox_recent_push(rnd);
                        ItemBox box = MakeItemBox((uint8_t)rnd, itembox_roll_type());
                        box.pos.x = (double)tab->points[rnd][0];
                        box.pos.y = (double)tab->points[rnd][1];
                        RAssert(game_spawn(server, (Entity*)&box, sizeof(ItemBox), NULL));
                }
        }

        return true;
}

bool itemboxmap_tcpmsg(PeerData* v, Packet* packet)
{
        /* patron exacto de kaf_tcpmsg/map_tcpmsg de la casa: passthrough +
           type como u8 leidos del cuerpo del paquete. */
        PacketRead(passtrough, packet, packet_read8, uint8_t);
        PacketRead(type, packet, packet_read8, uint8_t);

        switch (type)
        {
                /* misma superficie anti-cheat que Kaf: AssertOrDisconnect +
                   idempotencia en el activate + game_find por tag (cheaters
                   pueden re-romper una rota = no-op). */
                case CLIENT_BOX_ACTIVATE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(nid, packet, packet_read8, uint8_t);
                        PacketRead(proj, packet, packet_read8, uint8_t);

                        ItemBox* box[ITEMBOX_MAX * 3];
                        int found = game_find(v->server, (Entity**)box, "itembox", ITEMBOX_MAX * 3);
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
                        {
                                /* v74 EXE DENIAL (regla de la duena): el Exe PUEDE
                                   romper la caja — le niega el buff a cualquier
                                   superviviente que pase por ahi — pero JAMAS cobra
                                   el reward. Difundimos pid 0 ("nadie", el mismo
                                   convenio de is_proj): todos ven romperse la caja,
                                   nadie aplica el buff. Server-side a proposito
                                   (regla 7): un cliente modificado no puede
                                   autofacturarse rewards de exe. (game.exe es el
                                   peer id del Exe de la ronda — patron exacto de
                                   Lib.c disaster_server_peer.) SOLO las cajas nuevas:
                                   los monitores Kaf (KindAndFair.c) NO llevan este
                                   veto — orden explicita de la duena en v74. */
                                uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;
                                RAssert(itembox_activate(v->server, target, reward, proj));
                        }
                        break;
                }

                /* la caja del nid cayo en un trampolin o al abismo en el cliente
                   que la ve (el server no tiene colision de mapa — el reporte es
                   la unica fuente, patron CLIENT_FWBOLT_HIT). El server marca la
                   entidad "relocate" y el SIGUIENTE itemboxmap_tick la retira y
                   sortea un spawner libre distinto. El cliente la destruyo ya:
                   el despawn llega como SERVER_BOX_STATE 4 normal. */
                case CLIENT_BOX_RELOCATE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(nid, packet, packet_read8, uint8_t);

                        ItemBox* box[ITEMBOX_MAX * 3];
                        int found = game_find(v->server, (Entity**)box, "itembox", ITEMBOX_MAX * 3);
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
