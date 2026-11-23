#include <entities/ItemBoxMap.h>
#include <entities/ItemBox.h>
#include <entities/NotPerfect.h>
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

/* v78 COOLDOWN 30 s POR CAJA (regla de la duena: "despues de tirar una
   caja, cuando sea destruida se generara 30 seg por caja; el contador
   no empezara a ir hacia atras si el max de cajas esta cubierta, y no
   hara que aparezca otra de la nada"). Cola de reposiciones pendientes:
   cada entrada es el TIEMPO RESTANTE (en ticks) de la reposicion de UNA
   caja destruida. Decrementa SOLO mientras haya hueco (alive < MAX:
   cubierto el maximo, el contador queda en pausa — regla literal), y al
   llegar a 0 spawnea su caja (si sigue habiendo hueco; si no, espera a
   que lo haya en el siguiente tick). El roll de relleno NO corre con
   pendientes > 0: destruir una caja JAMAS se repone antes de sus 30 s. */
#define ITEMBOX_RESPAWN_QUEUE_MAX 8
static double itembox_respawn_left[ITEMBOX_RESPAWN_QUEUE_MAX];
static int itembox_respawn_n = 0;

static void itembox_respawn_push(double ticks)
{
        if (itembox_respawn_n < ITEMBOX_RESPAWN_QUEUE_MAX)
                itembox_respawn_left[itembox_respawn_n++] = ticks;
}

/* cadena de estado por ronda (reset en itemboxmap_init: los static de
   v62-v67 usaban la heuristica elapsed<1.0; ahora el reset es explicito
   en el checkstart de cada ronda — cero dependencia del valor de elapsed). */
static double itembox_next_roll = 0;
static int itembox_alive = -1;   /* -1: ronda sin roll agendado */
/* v76 VARIETY: el nunca-repetir de v68 (un solo itembox_last_spawner)
   se generaliza a un FIFO de ITEMBOX_RECENT_MAX spawners — regla de la
   duena: spawns SIEMPRE variados, no el mismo sitio una y otra vez. */
#define ITEMBOX_RECENT_MAX 3
/* v77: techo de busqueda (vivas + residuos boxused en countdown ~27 s).
   Era ITEMBOX_MAX*3=12: con 4 vivas + 8 residuos concurrentes (ronda
   movida) el find se saturaba y la repoblacion por zona quedaba bloqueada
   — ahora 24, holgado (las reubicadas mueren instantaneo, no dejan
   residuo: solo lo roto por PLAYER cuenta aca). */
#define ITEMBOX_FIND_MAX (ITEMBOX_MAX * 6)
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

/* ===== v77 NOT PERFECT: ZONA ACTUAL =====
   Not Perfect rota su area jugable entre 4 cuadrantes del room
   (SERVER_NPCONTROLLER_STATE: state 0=TL, 1=TR, 2=BL, 3=BR; offsets
   +2904 x / +1368 y — ver net_state_game.gml). La zona cambia cada
   ~20 s (15 s NONE + 5 s PREPARE) y cada ~5 s en el ultimo minuto
   (2 s + 3 s), ~16 veces por ronda de 155 s. Regla de la duena: las
   cajas deben SEGUIR a la zona (antes quedaban clavadas en el mismo
   cuadrante — la tabla v68 solo cubria la mitad inferior — y en las
   zonas 0/1 no habia NINGUNA caja alcanzable). */
#define NP_MAP_ID   6
#define NP_ZONE_W   2904.0
#define NP_ZONE_H   1368.0

static int np_zone_of(uint16_t px, uint16_t py)
{
        return (px >= NP_ZONE_W ? 1 : 0) + (py >= NP_ZONE_H ? 2 : 0);
}

/* zona actual segun el NPController (-1: mapa sin rotacion o sin
   controller — comportamiento v76 normal, nunca bloquea el spawn) */
static int np_current_zone(Server* server)
{
        if (server->game.map != NP_MAP_ID)
                return -1;

        Entity* ctrl[1];
        if (game_find(server, ctrl, "npctrl", 1) <= 0)
                return -1;

        return (int)(((NPController*)ctrl[0])->stage % 4);
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

/* v78: flag de exito del ultimo itembox_spawn_one (spawn_one devuelve
   true SIEMPRE — semantica RAssert de la casa — asi que la cola de
   enfriamientos mira este flag para saber si spawneo de verdad y solo
   entonces consumir la pendiente; si no habia punto libre en la zona,
   la pendiente queda en 0 y reintenta el tick siguiente). */
static bool itembox_last_spawn_ok = false;

/* un solo intento de spawn (lo llama el roll de COFF y la repoblacion
   por reubicacion). zone < 0: cualquier spawner libre (resto de mapas);
   zone 0..3: solo spawners DENTRO de esa zona de Not Perfect. */
static bool itembox_spawn_one(Server* server, const ItemBoxSpawnTable* tab, int zone)
{
        itembox_last_spawn_ok = false;
        ItemBox* boxes[ITEMBOX_FIND_MAX];
        int found = game_find(server, (Entity**)boxes, "itembox", ITEMBOX_FIND_MAX);
        if (found >= ITEMBOX_FIND_MAX)
                return true;

        /* un spawner queda ocupado por TODA entidad existente (viva o
           ROTA en countdown — y tambien las recien marcadas timer=0 en
           este mismo tick: una caja reubicada NUNCA renace en su punto). */
        uint8_t used[256];
        memset(used, 0, sizeof(used));
        for (int i = 0; i < found; i++)
                if (boxes[i]->nid < tab->zones)
                        used[boxes[i]->nid] = 1;

        /* v77: candidatos libres (filtrados por zona en Not Perfect) */
        int cand[128];
        int cand_count = 0;
        for (int i = 0; i < tab->zones; i++)
                if (!used[i] && (zone < 0 || np_zone_of(tab->points[i][0], tab->points[i][1]) == zone))
                        cand[cand_count++] = i;
        if (cand_count <= 0)
                return true; /* zona sin puntos libres: sin spawn esta vez */

        /* v76 nunca-repetir: con alternativas frescas, vetar los
           ultimos ITEMBOX_RECENT_MAX spawners usados. Si no quedan
           frescas, se acepta cualquiera (no bloquear el spawn). */
        int fresh = 0;
        for (int c = 0; c < cand_count; c++)
                if (!itembox_recent_has(cand[c]))
                        fresh++;

        int rnd;
gen:
        rnd = cand[rand() % cand_count];
        if (fresh > 0 && itembox_recent_has(rnd))
                goto gen;

        itembox_recent_push(rnd);
        ItemBox box = MakeItemBox((uint8_t)rnd, itembox_roll_type());
        box.pos.x = (double)tab->points[rnd][0];
        box.pos.y = (double)tab->points[rnd][1];
        RAssert(game_spawn(server, (Entity*)&box, sizeof(ItemBox), NULL));
        itembox_last_spawn_ok = true;
        return true;
}

bool itemboxmap_init(Server* server)
{
        /* reset por ronda: agenda el primer roll tras FIRST_DELAY.
           Si el mapa no tiene tabla (0 zonas), el sistema queda inactivo
           en toda la ronda (tick no hace nada).
           v78: FIRST_DELAY/SPAWN_COFF son SEGUNDOS — game.elapsed cuenta
           TICKS a 60/s (server->delta = 1 por tick de 1000/60 ms), asi
           que SIEMPRE multiplicar por TICKSPERSEC. El bug v62-v77 era
           usarlos en crudo: primer roll a 15 TICKS (0.25 s) y roll cada
           20 TICKS (0.33 s) — una caja destruida se reponia casi al
           instante ("aparece otro de la nada", reporte de la duena). */
        itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY * TICKSPERSEC;
        itembox_alive = 0;
        /* v78: la cola de enfriamientos tambien se resetea por ronda
           (las cajas destruidas de la ronda anterior no arrastran
           reposiciones a la ronda nueva). */
        itembox_respawn_n = 0;
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
                   agenda igual — no debe pasar nunca con el hook puesto.
                   v78: FIRST_DELAY en segundos -> ticks (ver init). */
                itembox_alive = 0;
                itembox_respawn_n = 0;
                itembox_next_roll = server->game.elapsed + ITEMBOX_FIRST_DELAY * TICKSPERSEC;
        }

        /* v77 NOT PERFECT: zona actual. El npctrl_tick corre ANTES en el
           mismo tick (game_state_tick: entity tick -> map tick -> este),
           asi que el cambio de zona ya esta visible aqui — la reubicacion
           de cajas sale en el MISMO paquete-tick que el teleport de los
           players. */
        int zone = np_current_zone(server);

        bool roll_now = server->game.elapsed >= itembox_next_roll;
        if (roll_now)
                itembox_next_roll = server->game.elapsed + ITEMBOX_SPAWN_COFF * TICKSPERSEC; /* v78: s -> ticks */

        /* v77: el procesado de reubicaciones corre CADA tick (antes solo
           en el tick del roll): la zona de Not Perfect rota cada ~20 s
           (5 s en el ultimo minuto) y las cajas marcadas por lava/abismo
           (v63/v76) tampoco deben esperar hasta 20 s para renacer. El
           game_find de ~12 entidades por tick es trivial. */
        ItemBox* boxes[ITEMBOX_FIND_MAX];
        int found = game_find(server, (Entity**)boxes, "itembox", ITEMBOX_FIND_MAX);
        int alive = 0;
        for (int i = 0; i < found; i++)
                if (boxes[i]->timer < 0)
                        alive++;

        /* RELOCATE (v63) + zona NP (v77): retirar las marcadas y las VIVAS
           que quedaron fuera de la zona actual. timer=0 -> el itembox_tick
           de la entidad difunde el despawn (state 4) y la retira; su
           spawner sigue ocupado este tick (used[] pre-muerte) -> la nueva
           nace SIEMPRE en otro punto.
           v78: una caja que ya estaba ROTA (activated) cuando le toco
           reubicarse NO cuenta como removed — su reposicion ya tiene su
           enfriamiento de 30 s agendado desde el activate; contarla aqui
           la repoblaria dos veces. */
        int removed = 0;
        for (int i = 0; i < found; i++)
        {
                if (boxes[i]->relocated)
                {
                        boxes[i]->timer = 0;
                        if (!boxes[i]->activated)
                                removed++;
                        continue;
                }
                if (zone >= 0 && boxes[i]->timer < 0
                    && np_zone_of(tab->points[boxes[i]->nid][0], tab->points[boxes[i]->nid][1]) != zone)
                {
                        boxes[i]->relocated = true;
                        boxes[i]->timer = 0;
                        removed++;
                }
        }

        /* cuantas spawnear este tick:
           - v78 COOLDOWN: cada caja DESTRUIDA spawnea su reposicion cuando
             su contador de 30 s llega a cero (y hay hueco: el contador NO
             corre con el maximo cubierto — se decrementa solo si
             alive_after < MAX, regla literal de la duena). Solo una
             reposicion por pendiente: destruyo 1 -> vuelve 1 a los 30 s,
             destruyo 2 -> vuelven 2, cada una a su 30 s.
           - reubicacion (lava v63/v76 o cambio de zona v77): repoblar LO
             RETIRADO en el mismo tick (bounded por MAX), para que las
             cajas "siguen" a la zona y el player nunca ve un mapa vacio
             tras un cambio. Esto NO es destruccion: sin enfriamiento.
           - roll de RELLENO cada COFF s (20 s reales ahora): solo si NO
             hay enfriamientos pendientes (el roll JAMAS regala una caja
             antes de los 30 s de una destruida) y hay hueco. En la
             practica solo llena el arranque de ronda (15 s + 1/20 s) —
             el resto de la ronda la poblacion la lleva la cola v78. */
        int want = 0;
        int alive_after = alive - removed;

        /* reubicadas: mismo tick (v63/v76/v77 sin cambios) */
        if (removed > 0 && alive_after < ITEMBOX_MAX)
        {
                int back = removed;
                if (back > ITEMBOX_MAX - alive_after)
                        back = ITEMBOX_MAX - alive_after;
                if (back > want)
                        want = back;
        }

        /* v78: primero se reubican las retiradas (nacen ya), DESPUES se
           procesa la cola para que los huecos que dejen se respeten. */
        for (int s = 0; s < want; s++)
                RAssert(itembox_spawn_one(server, tab, zone));
        alive_after += want;

        /* v78: cola de enfriamientos — decrementa SOLO con hueco libre
           ("el contador no empezara a ir hacia atras si el max de cajas
           esta cubierta"). Cada entrada que llega a 0 spawnea SU caja
           y sale de la cola SOLO si el sorteo encontro punto (si la zona
           no tenia ninguno libre, queda en 0 y reintenta el tick que
           viene — nunca se pierde la reposicion). */
        for (int i = 0; i < itembox_respawn_n; i++)
        {
                if (alive_after >= ITEMBOX_MAX)
                        break; /* max cubierto: todos los contadores en pausa */

                if (itembox_respawn_left[i] > 0)
                        itembox_respawn_left[i] -= server->delta;

                if (itembox_respawn_left[i] <= 0)
                {
                        RAssert(itembox_spawn_one(server, tab, zone));
                        if (itembox_last_spawn_ok)
                        {
                                alive_after++;
                                /* pop de la entrada consumida (compacta) */
                                for (int j = i + 1; j < itembox_respawn_n; j++)
                                        itembox_respawn_left[j - 1] = itembox_respawn_left[j];
                                itembox_respawn_n--;
                                i--; /* reexaminar el indice ahora ocupado por la siguiente */
                        }
                }
        }

        /* v78: roll de relleno SOLO sin pendientes (con pendientes el
           relleno anticipado seria "aparecer de la nada" a < 30 s). */
        if (roll_now && itembox_respawn_n == 0 && alive_after < ITEMBOX_MAX)
                RAssert(itembox_spawn_one(server, tab, zone));

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

                        ItemBox* box[ITEMBOX_FIND_MAX];
                        int found = game_find(v->server, (Entity**)box, "itembox", ITEMBOX_FIND_MAX);
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
                                   veto — orden explicita de la duena en v74.
                                   v78: una caja VIVA que se rompe agenda su
                                   enfriamiento de 30 s (la rota re-rompida es no-op
                                   idempotente: ni reward ni enfriamiento nuevo).
                                   La rompa quien la rompa (Exe negando el buff o
                                   survivor cobrandolo) la reposicion es la misma:
                                   30 s por caja. */
                                bool was_alive = !target->activated;
                                uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;
                                RAssert(itembox_activate(v->server, target, reward, proj));
                                if (was_alive)
                                        itembox_respawn_push(ITEMBOX_RESPAWN_COOLDOWN * TICKSPERSEC);
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

                        ItemBox* box[ITEMBOX_FIND_MAX];
                        int found = game_find(v->server, (Entity**)box, "itembox", ITEMBOX_FIND_MAX);
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
