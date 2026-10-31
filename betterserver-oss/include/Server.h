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
#define BUILD_VERSION 1101

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
#define PLAYER_COOLCOUNT 10
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
                CH_BLAZE
                } surv_char;

        enum
        {
                EX_NONE = -1,

                EX_ORIGINAL,
                EX_CHAOS,
                EX_EXETIOR,
                EX_EXELLER,

                /* v2.2 (TTB): killer #5 rescatado de TD2D Through the Blood */
                EX_METALAMY
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
        bool avail[CH_BLAZE + 1];
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

typedef struct
{
        int exe;
        int8_t map;
        bool started;
        bool sudden_death;

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
