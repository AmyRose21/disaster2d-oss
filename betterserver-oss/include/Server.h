#ifndef SERVER_H
#define SERVER_H

#include <Auth.h>
#include <DyList.h>
#include <Lib.h>
#include <Log.h>
#include <Vote.h>
#include <DyList.h>
#include <Player.h>
#include <Packet.h>
#include <io/Threads.h>
#include <io/Time.h>
#include <enet/enet.h>
#include <stdbool.h>
#include <stdint.h>

#define TICKSPERSEC 60
/* v80c: 1101 -> 1102. El paquete IDENTITY gano el campo device_id
   (entre pet y los u64 del anticheat): cliente y server se actualizan
   JUNTOS o no conectan (version mismatch intencional, como siempre
   que se movio el protocolo).
   v81: 1102 -> 1103. El enum de paquetes gano SERVER_CLAIM_STATE al
   final (estados de los claims .sonic/.kris/.sally): misma regla,
   cliente y server se actualizan JUNTOS. */
#define BUILD_VERSION 1102

#define BRACKET "-----------------------"

#define STR_HELPER(x) #x
#define STRINGIFY(x) STR_HELPER(x)

struct Server;
struct auth_peer_data;

/* v2.1.3: cooldowns de habilidades POR JUGADOR (PeerData.plr_cooldowns).
   Antes vivian en Game.cooldowns, GLOBALES a toda la partida: con dos
   jugadores con la misma habilidad (Vanilla y Cream soltando anillos,
   dos Eggman con el rastreador, dos Tails con el laser) el assert del
   2.o en usarla dentro de la ventana fallaba y el server lo desconectaba
   (y su cliente crasheaba leyendo `type` sin definir en net_tcpprocess:
   fix cliente v2.1.3). */
/* v84: 15 -> 17: dos cooldowns nuevos para las senales de Chocola (ver
   CHOCOLA_* abajo y el bloque de CLIENT_SOUND_EMIT en states/Game.c).
   Solo cambia el LAYOUT EN MEMORIA del server (plr_cooldowns), no el
   protocolo de red: recompilar el server al desplegar. */
#define PLAYER_COOLCOUNT 17
// Cooldown indices (dentro de PeerData.plr_cooldowns)
#define TAILS_RECHARGE 0
#define CREAM_RING_SPAWN 1
#define EXETIOR_BRING_SPAWN 2
#define EXELLER_CLONE_SPAWN 3
#define EGGTRACK_RECHARGE 4
#define ETAILS_RECHARGE 5
/* v2.2 (TTB): habilidades de los rescatados */
#define AMELIA_BANANA_SPAWN 6
#define AMELIA_TRAP_SPAWN 7
#define BLAZE_FIREBALL_SPAWN 8
#define METALAMY_BULLET 9
/* v2.14: Fleetway Amy */
#define FWBOLT_SPAWN 10
/* v1 (D.I.B.): habilidades de Jinna */
#define JINNA_TELEPORT 11
#define JINNA_GRAB 12
/* v4 (D.I.B.): el portal trampa YA NO comparte cooldown con el agarre
   (peticion de la duena tras probar la v3): indice propio. */
#define JINNA_TRAP 13
/* v6 (minions): invocacion de esbirros desde el portal (↓+C de Jinna).
   La invoca TODOS los atrapados a la vez con su propia recarga de 25 s
   (JINNA_MINION_RECHARGE en el cliente; si cambias una, cambia la otra). */
#define JINNA_MINION 14
/* v7 (toque negativo): freno anti-spam de la CONVERSION negativa de
   Jinna (CLIENT_JINNA_NEGATOUCH). No es el cooldown de una habilidad:
   es el margen minimo entre conversiones anunciadas por el server (la
   gracia de 3 s vive en el cliente como jinnaNegaGrace; esto es la
   red de seguridad del lado server). */
#define JINNA_NEGATOUCH 14
/* v7: JINNA_NEGATOUCH comparte indice con JINNA_MINION a proposito:
   ambas son conversiones de bando y no deben pisarse entre si. */

/* v84 (Chocola, pedido de la duena): tope de ritmo SERVER-SIDE para sus
   senales de stun DIRIGIDAS en CLIENT_SOUND_EMIT. El cliente sano de v84
   comparte chocolaCd = 2.5 s entre bloqueo y ataque (+26 frames de pose
   de golpe), asi que CHOCOLA_DIVE_STUN (snd_vasebreak, indice REAL 110
   en global.net_snds) con 2 s JAMAS corta juego legitimo; la caza grande
   (snd_nono, 109) ya no existe en v84 (la paciencia es solo gesto), tope
   holgado de 10 s. Cream (custodia de Chocola) no lleva enfriamiento de
   cliente: sin tope para ella. */
#define CHOCOLA_HUNT_STUN 15
#define CHOCOLA_DIVE_STUN 16

typedef struct PeerData
{
        uint16_t id;
        String ip;
        ENetPeer *peer;

        /* General info */
        Player plr;
        String nickname;
        String udid;
        uint8_t lobby_icon;
        int8_t pet;

        bool verified;
        bool in_game;
        bool op;
        bool ready;
        bool mod_tool;
        bool is_mobile;
        bool can_vote;
        bool voted;
        bool disconnecting;
        bool amy_authed; /* Amy Canon: envio el token correcto (CLIENT_AMY_AUTH) */

        /* v80c: Rouge por dispositivo. device_id = identificador real
           del telefono/PC (ANDROID_ID en Android, udid en PC; vacio en
           clientes sin soporte = no pueden reclamar). rouge_claimed =
           este dispositivo tiene el claim de Rouge en Devices.txt
           (recalculado en cada conexion; los operadores y el token de
           Amy no lo necesitan). */
        String device_id;
        bool rouge_claimed;

        /* v81: Sonic/Kris/Sally Canon por dispositivo (misma mecanica
           que rouge_claimed, un flag por personaje; se recalculan en
           cada conexion desde Devices.txt y los avisa SERVER_CLAIM_STATE
           en un solo paquete). */
        bool sonic_claimed;
        bool kris_claimed;
        bool sally_claimed;

        auth_peer_data auth;

        /* Character */
        enum
        {
                CH_NONE = -1,

                CH_TAILS,
                CH_KNUX,
                CH_EGGMAN,
                CH_AMY,
                CH_CREAM,
                CH_SALLY,

                /* Copia clasica de Amy (sprites v100) */
                CH_AMY_CANON,

                /* Sonic (mod): sobreviviente #8, mismo orden que el cliente */
                CH_SONIC,

                /* Sally Canon (mod): sobreviviente #9, mismo orden que el cliente */
                CH_SALLY_CANON,

                /* Vanilla (mod): sobreviviente #10, mismo orden que el cliente.
                   SOLO se desbloquea con el token de Amy (amy_canon_token),
                   igual que Amy Canon: ni operadores ni publica. */
                CH_VANILLA,

                /* v2.2 (TTB): supervivientes #11-13 rescatados de TD2D Through
                   the Blood, LIBRES para todos. Mismo orden que el cliente. */
                CH_METAL,
                CH_AMELIA,
                CH_BLAZE,

                /* v2.14: Fleetway Amy (port del mod de GameJolt). Como Amy
                   Canon y Vanilla: SOLO con el token de Amy (amy_authed).
                   Mismo orden que el cliente (scr_survivors.gml). */
                CH_FLEETWAY_AMY,

                /* v4.4: Rouge (set de sprites rouge/erouge del TTB ya en
                   el proyecto). Superviviente #15: planeo + agarre de
                   pared de Knux + patada tierra/aire de Sally. JAMAS
                   se demoniza (regla canonica): muerte directa.
                   Mismo orden que el cliente (scr_survivors.gml). */
                CH_ROUGE,

                /* v5: KRIS (Deltarune, set spr_kris_* de la duena).
                   Superviviente #16: espada (X, patron puno de Knux)
                   + escudo (C, patron parry: solo tierra y solo de
                   frente; sin aura de aliados). 1ra caida = MORIBUNDA
                   (la resuelve su cliente, el server nunca se entera);
                   2da = muerte directa. JAMAS se demoniza, JAMAS subdito
                   negativo y JAMAS absorbible por Jinna (trampa = kind 0
                   siempre). Mismo orden que el cliente (scr_survivors.gml). */
                CH_KRIS
                } surv_char;

        enum
        {
                EX_NONE = -1,

                EX_ORIGINAL,
                EX_CHAOS,
                EX_EXETIOR,
                EX_EXELLER,

                /* v2.2 (TTB): killer #5 rescatado de TD2D Through the Blood */
                EX_METALAMY,

                /* v1 (D.I.B.): killer #6 rescatado de TD2DR Darkness In
                   Blood (GameJolt 1104339) */
                EX_JINNA
                } exe_char;

        bool should_timeout;

        /* State info */
        uint8_t exe_chance;
        double timeout;
        double vote_cooldown;

        /* v2.1.3: cooldowns de habilidades de ESTE jugador (indices de arriba).
           Se resetean en game_init y al demonizarse (states/Game.c). */
        double plr_cooldowns[PLAYER_COOLCOUNT];

        struct Server *server;
} PeerData;

typedef struct
{
        /* Lobby */
        double countdown;
        double prac_countdown;
        uint8_t countdown_sec;
        Vote vote;
        PeerData kick_target;

        /* Map Vote */
        uint8_t maps[3];
        uint8_t votes[3];

        /* Character Select */
        int8_t map;
        uint16_t exe;
        bool exe_practice; /* [practica-exe-v1]: ronda iniciada con .ep — no termina por eliminacion (solo TIME OVER / .lobby / exe se va) */
        bool avail[CH_KRIS + 1];
} Lobby;

typedef enum
{
        BS_NONE,
        BS_DEACTIVATED,
        BS_ACTIVATED,
} BigRingState;

typedef enum
{
        ED_EXEWIN,
        ED_SURVWIN,
        ED_TIMEOVER
} Ending;

/* v5.3 — LMS «El Show Fuerte» POR PERSONAJE: la lista de QUIEN tiene
   show. Cada entrada lleva SU(S) cancion(es) (duraciones en segundos,
   redondeadas); al disparar el show el server elige UNA al azar de las
   del personaje, sube el reloj a ESA duracion (solo si queda menos) y
   avisa a todos con SERVER_GAME_LMS (payload u8 char + u8 song). El
   reloj SOLO sube: si quedaba mas tiempo, se conserva.
   CH_* van en el mismo orden que los CHARACTER_* del cliente
   (scr_survivors.gml); la lista de canciones del lado cliente es
   global.lmsCharSongs (scr_lms.gml), que el Suite TD2D mantiene
   sincronizada con esta tabla. Editar con el Suite (modulo Show LMS). */
#define LMS_MAX_SONGS 16

/* v98 (KRIS LV 20 — EL DUELO FINAL): cuantas senales silenciosas
   (snd_none, indice 0 de global.net_snds) equivalen al LV 20 de Kris.
   LV 1 = 0 senales, +1 senal por nivel cruzado (el MULTI-SIGNAL FLUSH
   de v97: 1 por nivel, sea cual sea la perilla KRIS_LV_XP_*): LV 20
   = 19. Espejo del KRIS_LV_MAX (20) del cliente (scr_kris_special). */
#define KRIS_LV20_SIGNALS 19

typedef struct
{
        uint8_t ch;    /* CH_* del personaje con show */
        uint8_t songs; /* cuantas canciones tiene (1..LMS_MAX_SONGS) */
        uint16_t sec[LMS_MAX_SONGS]; /* duracion de cada una (s) */
} LmsShow;

#define LMS_SHOW_COUNT 16
static const LmsShow LMS_SHOWS[LMS_SHOW_COUNT] = {
        { CH_TAILS, 1, { 205 } },
        { CH_KNUX, 2, { 251, 140 } },
        { CH_EGGMAN, 1, { 195 } },
        { CH_AMY, 3, { 213, 235, 163 } },
        { CH_CREAM, 1, { 218 } },
        { CH_SALLY, 2, { 206, 183 } },
        { CH_AMY_CANON, 1, { 163 } },
        { CH_SONIC, 4, { 163, 164, 275, 282 } },
        { CH_SALLY_CANON, 2, { 183, 206 } },
        { CH_VANILLA, 2, { 182, 213 } },
        { CH_METAL, 1, { 216 } },
        { CH_AMELIA, 1, { 206 } },
        { CH_BLAZE, 1, { 213 } },
        { CH_FLEETWAY_AMY, 1, { 216 } },
        { CH_ROUGE, 3, { 187, 212, 198 } },
        { CH_KRIS, 1, { 232 } },
};

typedef struct
{
        int exe;
        int8_t map;
        bool started;
        bool sudden_death;
        bool lms; /* v5.0: LMS «El Show Fuerte» activo (ultimo superviviente con show) */
        uint8_t lms_char; /* v5.3: personaje del show (se reenvia al reconectar) */
        uint8_t lms_song; /* v5.3: indice de la cancion elegida DENTRO de la lista del personaje */

        /* v98 (KRIS LV 20 — EL DUELO FINAL): espejo minimo del LOVE de
           Kris en el server. kris_lv cuenta las SENALES SILENCIOSAS de
           subida de LV del jugador de Kris (snd_none = indice 0 de
           global.net_snds, broadcast: nid == emisor; las cuenta el
           CLIENT_SOUND_EMIT) — con el flush 1-senal-por-nivel de v97 son
           EXACTAS: LV del server = kris_lv + 1, tope 19 senales = LV 20
           (KRIS_LV20_SIGNALS). Se consume en el tick de la partida:
           LV 20 ANTES del LMS -> el show de Kris arranca SOLO aunque
           queden mas vivos (lms latched, lms_natural = false); LV 20
           DURANTE el show NATURAL de Kris (el arranco por quedarse
           como ultimo) -> ring_off: el anillo verde NO aparece (o se
           apaga) y la ronda solo acaba con Kris o el exe en el suelo. */
        uint8_t kris_lv; /* senales snd_none de Kris recibidas (0..KRIS_LV20_SIGNALS) */
        bool lms_natural; /* v98: el show activo arranco por la regla del ultimo superviviente (no por el LV 20) */
        bool ring_off; /* v98: anillo de escape retirado (duelo final Kris vs exe): game_bigring ignora todo */

        double start_timeout;
        double time;
        double elapsed;
        uint16_t time_sec;
        double end;
        Ending ending;

        BigRingState bring_state;
        uint8_t bring_loc;

        /* Entities */
        uint16_t entid;
        DyList entities;

        /* Rings */
        bool rings[256];
        uint8_t ring_coff;
        /* v76 RING VARIETY: FIFO memory of the last RING_RECENT_MAX
           spawner slots used (anti "same spot over and over"). Lives in
           the Game struct ON PURPOSE: the compound literal at round
           start zero-inits it, so the memory resets per round with NO
           manual reset call (same pattern as bring_loc). */
        uint8_t ring_recent[4];
        uint8_t ring_recent_len;

        /* Lists */
        DyList left;

        TimeStamp tails_last_proj;
} Game;

typedef struct Results
{
        double countdown;
        bool music_synced; /* >>[endings v2]<< la espera ya se ajusto a la pista real */
} Results;

typedef struct Server
{
        uint16_t id;
        bool running;

        enum
        {
                ST_LOBBY,
                ST_MAPVOTE,
                ST_CHARSELECT,
                ST_GAME,
                ST_RESULTS
        } state;
        Mutex state_lock;

        /* States */
        Lobby lobby;
        Game game;
        Results results;

        int8_t last_map;
        int16_t map_pickrates[30];

        /* v5.3.2 — FIX LMS VARIEDAD V1: bolsa anti-repeticion de las
           canciones del show, POR PERSONAJE. Vive en Server (no en Game)
           para NO resetearse entre rondas: cada show saca una cancion de
           la bolsa y la bolsa solo se rellena cuando se vacia, asi las
           canciones de un personaje NO se repiten hasta que han sonado
           TODAS (shuffle-bag). Con rand() puro una lista de 2 repetia la
           misma el 50% de las veces seguidas (4: el 25%) y sonaba como
           "siempre la misma cancion". lms_bag_count guarda el tamaño de
           la lista con la que se relleno (si el Suite cambia la tabla,
           la bolsa se rellena sola). */
        uint8_t lms_bag[CH_KRIS + 1][LMS_MAX_SONGS];
        uint8_t lms_bag_left[CH_KRIS + 1];
        uint8_t lms_bag_count[CH_KRIS + 1];

        /* v5.3.2: ultima cancion que SONO por personaje (para el anti-eco
           entre ciclos de la bolsa: la primera extraccion tras rellenar
           no puede caer en la misma que cerro el ciclo anterior). Se
           inicializa a 0xFF en server_new (Lib.c). */
        uint8_t lms_last[CH_KRIS + 1];

        double delta;
        DyList peers;
        ENetHost *host;
} Server;

bool server_state_joined(PeerData *v);
bool server_state_left(PeerData *v);
bool server_state_handle(PeerData *v, Packet *packet);
bool server_msg_handle(Server *server, PacketType type, PeerData *v, Packet *packet);
bool server_cmd_handle(Server *server, unsigned long hash, PeerData *v, String *msg);
unsigned long server_cmd_parse(String *string);
bool server_msg_is_command(String *string);

bool server_worker(Server *server);
bool server_broadcast(Server *server, Packet *packet, bool reliable);
bool server_broadcast_ex(Server *server, Packet *packet, bool reliable, uint16_t ignore);
bool server_send_msg(Server *server, ENetPeer *peer, const char *message);
bool server_broadcast_msg(Server* server, uint16_t sender, const char* message);

int server_total(Server *server);
int server_ingame(Server *server);
PeerData *server_find_peer(Server *server, uint16_t id);
bool server_disconnect(Server *server, ENetPeer *peer, DisconnectReason reason, const char *text);
bool server_disconnect_id(Server *server, uint16_t id, DisconnectReason reason, const char *text);

#endif
