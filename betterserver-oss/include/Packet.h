#ifndef PACKET_H
#define PACKET_H
#include <Log.h>
#include <enet/enet.h>
#include <stdint.h>

typedef enum
{
        IDENTITY,
        SERVER_IDENTITY_RESPONSE,

        SERVER_PLAYER_JOINED,
        SERVER_PLAYER_LEFT,
        SERVER_PLAYER_FORCE_DISCONNECT,

        SERVER_WAITING_PLAYER_INFO,

        SERVER_LOBBY_READY_STATE,
        SERVER_LOBBY_EXE,
        SERVER_LOBBY_COUNTDOWN,
        SERVER_LOBBY_EXE_CHANGE,
        SERVER_LOBBY_CHARACTER_CHANGE,
        SERVER_LOBBY_CHARACTER_RESPONSE,
        SERVER_LOBBY_EXECHARACTER_RESPONSE,
        SERVER_LOBBY_GAME_START,
        SERVER_LOBBY_PLAYER,
        SERVER_LOBBY_EXE_CHANCE,
        SERVER_LOBBY_CORRECT,
        SERVER_LOBBY_CHOOSEVOTEKICK,
        SERVER_LOBBY_CHOOSEBAN,
        SERVER_LOBBY_CHOOSEKICK,
        SERVER_LOBBY_CHOOSEOP,
        SERVER_LOBBY_CHANGELOBBY,
        SERVER_CHAR_TIME_SYNC,

        SERVER_VOTE_MAPS,
        SERVER_VOTE_SET,
        SERVER_VOTE_TIME_SYNC,

        SERVER_GAME_PLAYERS_READY,
        SERVER_GAME_EXE_WINS,
        SERVER_GAME_SURVIVOR_WIN,
        SERVER_GAME_SPAWN_RING,
        SERVER_GAME_PLAYER_ESCAPED,
        SERVER_GAME_BACK_TO_LOBBY,
        SERVER_GAME_TIME_SYNC,
        SERVER_GAME_TIME_OVER,
        SERVER_GAME_PING,
        SERVER_PLAYER_DEATH_STATE,
        SERVER_GAME_DEATHTIMER_TICK,
        SERVER_GAME_DEATHTIMER_END,

        SERVER_REQUEST_INFO,
        SERVER_HEARTBEAT,
        SERVER_PONG,

        SERVER_FORCE_DAMAGE,
        SERVER_GAME_RING_READY,
        SERVER_PLAYER_BACKTRACK,

        // Entities
        SERVER_TPROJECTILE_STATE,
        SERVER_ETRACKER_STATE,
        SERVER_ERECTOR_BRING_SPAWN,
        SERVER_RMZSLIME_STATE,
        SERVER_RMZSLIME_RINGBONUS,
        SERVER_RMZSHARD_STATE,
        SERVER_LCEYE_STATE,
        SERVER_LCCHAIN_STATE,
        SERVER_NPCONTROLLER_STATE,
        SERVER_KAFMONITOR_STATE,
        SERVER_YCRSMOKE_STATE,
        SERVER_YCRSMOKE_READY,
        SERVER_MOVINGSPIKE_STATE,
        SERVER_RING_STATE,
        SERVER_RING_COLLECTED,
        SERVER_ACT9WALL_STATE,
        SERVER_NAPBALL_STATE,
        SERVER_NAPICE_STATE,
        SERVER_PFLIFT_STATE,
        SERVER_BRING_STATE,
        SERVER_BRING_COLLECTED,
        SERVER_VVLCOLUMN_STATE,
        SERVER_VVVASE_STATE,
        SERVER_GHZTHUNDER_STATE,
        SERVER_TCGOM_STATE,
        SERVER_EXELLERCLONE_STATE,
        SERVER_DTTAILSDOLL_STATE,
        SERVER_DTBALL_STATE,
        SERVER_DTASS_STATE,
        SERVER_HDDOOR_STATE,
        SERVER_WDLATERN_ACTIVATE,
        SERVER_FART_STATE,
        SERVER_MJLAVA_STATE,
        SERVER_MJJUDGER_STATE,
        SERVER_MJCRYSTAL_STATE,

        // Entity actions
        CLIENT_ETRACKER,
        CLIENT_ETRACKER_ACTIVATED,
        CLIENT_TPROJECTILE,
        CLIENT_TPROJECTILE_HIT,
        CLIENT_TPROJECTILE_STARTCHARGE,
        CLIENT_ERECTOR_BALLS,
        CLIENT_ERECTOR_BRING_SPAWN,
        CLIENT_EXELLER_SPAWN_CLONE,
        CLIENT_EXELLER_TELEPORT_CLONE,
        CLIENT_MERCOIN_BONUS,

        CLIENT_RMZSLIME_HIT,
        CLIENT_LCEYE_REQUEST_ACTIVATE,
        CLIENT_KAFMONITOR_ACTIVATE,
        CLIENT_RING_COLLECTED,
        CLIENT_RING_BROKE,
        CLIENT_BRING_COLLECTED,
        CLIENT_NAPICE_ACTIVATE,
        CLIENT_SPRING_USE,
        CLIENT_PFLIT_ACTIVATE,
        CLIENT_VVVASE_BREAK,
        CLIENT_RMZSHARD_COLLECT,
        CLIENT_RMZSHARD_LAND,
        CLIENT_DTASS_ACTIVATE,
        CLIENT_HDDOOR_TOGGLE,
        CLIENT_FART_PUSH,

        CLIENT_LOBBY_READY_STATE,
        CLIENT_REQUESTED_INFO,
        CLIENT_PLAYER_DATA,
        CLIENT_PLAYER_HURT,
        CLIENT_SOUND_EMIT,
        CLIENT_PING,

        CLIENT_REVIVAL_PROGRESS,
        CLIENT_PLAYER_HEAL,
        CLIENT_PLAYER_HEAL_PART,
        SERVER_REVIVAL_PROGRESS,
        SERVER_REVIVAL_STATUS,
        SERVER_REVIVAL_RINGSUB,
        SERVER_REVIVAL_REVIVED,

        CLIENT_REQUEST_CHARACTER,
        CLIENT_REQUEST_EXECHARACTER,
        CLIENT_VOTE_REQUEST,

        CLIENT_PLAYER_DEATH_STATE,
        CLIENT_PLAYER_ESCAPED,
        SERVER_PLAYER_ESCAPED,
        CLIENT_LOBBY_PLAYERS_REQUEST,
        CLIENT_CREAM_SPAWN_RINGS,
        CLIENT_SPAWN_EFFECT,
        CLIENT_CHAT_MESSAGE,
        CLIENT_LOBBY_CHOOSEVOTEKICK,
        CLIENT_LOBBY_CHOOSEBAN,
        CLIENT_LOBBY_CHOOSEKICK,
        CLIENT_LOBBY_CHOOSEOP,
        CLIENT_PLAYER_PALETTE,
        CLIENT_PET_PALETTE,

        SERVER_RESULTS,
        SERVER_RESULTS_DATA,
        CLIENT_RESULTS_REQUEST,
        CLIENT_STATS_REPORT,
        SERVER_PREIDENTITY,
        SERVER_FELLA,

        CLIENT_PLAYER_POTATER,

        /* Amy Canon: token de desbloqueo del personaje reservado.
           El cliente lo envia justo despues de IDENTITY; ver el handler
           en states/Server.c y el filtro en states/CharSelect.c */
        CLIENT_AMY_AUTH,

        /* Sonic parry: desvio del laser de Tails (flip de exe/dir + cap de
           dano + rebroadcast _state 3) y conversion del anillo negro de
           Exetior en anillo dorado recogible (bring -> cring). Mismo orden
           que el enum del cliente (net_packets.gml). */
        CLIENT_TPROJECTILE_DEFLECT,
        CLIENT_BRING_DEFLECT,

        /* Sistema de operadores (.op): estado de operador (server ->
           cliente; 1 = es operador). Mismo orden que el enum del
           cliente (net_packets.gml). */
        SERVER_OPERATOR_STATE,

        /* Vanilla v2 (Chocola): des-demonizacion de un esbirro pagada
           con 15 anillos por Vanilla (esbirro ATURDIDO al alcance).
           El server valida, limpia PLAYER_DEMONIZED y avisa a todos.
           Mismo orden que el enum del cliente (net_packets.gml). */
        CLIENT_VANILLA_DEDEMONIZE,
        SERVER_VANILLA_DEDEMONIZE,

        /* v2.2 — personajes de TD2D Through the Blood (mod abandonado).
           Amelia: banana (trampolin resorte) y trampa (vida 60 s /
           pisada: stun 3 s + slow -40% 3.5 s tras el stun).
           Blaze: bola de fuego (proyectil). Metal Amy (killer): bala
           del canon. Mismo orden en el enum del cliente. */
        CLIENT_AMELIA_BANANA,
        CLIENT_AMELIA_TRAP,
        CLIENT_AMELIA_TRAP_TRIGGER,
        SERVER_AMELIA_BANANA_STATE,
        SERVER_AMELIA_TRAP_STATE,
        CLIENT_BLAZE_FIREBALL,
        CLIENT_BLAZE_FIREBALL_HIT,
        SERVER_BLAZE_FIREBALL_STATE,
        CLIENT_METALAMY_BULLET,
        CLIENT_METALAMY_BULLET_HIT,
        SERVER_METALAMY_BULLET_STATE,

        /* v2.9 — Blaze: la bola de fuego REBOTA en suelo/pared/techo.
           El server no tiene colision de mapa: el cliente que ve el
           choque reporta nid + que componentes de velocidad invertir
           + la posicion del primer solape. Mismo orden que el enum
           del cliente (net_packets.gml). */
        CLIENT_BLAZE_FIREBALL_BOUNCE,

        /* v2.11 — Vanilla: progreso del RESCATE DE ESBIRRO (mismo
           sistema que CLIENT_REVIVAL_PROGRESS pero para un esbirro
           ATURDIDO, cuyo stun viaja como estado DEAD): Vanilla encima
           manteniendo ABAJO con 15+ anillos. El server acumula el
           progreso (plr.dedemon_progress), reenvia la MISMA barra
           (SERVER_REVIVAL_PROGRESS) y al completarlo hace lo que
           hacia CLIENT_VANILLA_DEDEMONIZE: limpiar PLAYER_DEMONIZED +
           marcar PLAYER_REVIVED. Mismo orden que el enum del cliente
           (net_packets.gml). */
        CLIENT_VANILLA_DEDEMONIZE_PROGRESS,

        /* v3.0 — «Genio Malvado» (Eggman) + balance de trampas:
           CLIENT_EGG_TRAP_UPGRADE (u8 type: 0 = su sensor eggtrack /
           1 = trampa de Amelia; u16 nid): v3.1 DEPRECATED — mejora
           instantanea sustituida por el estilo RESCATE (los tres IDs
           nuevos de abajo); el valor se conserva para no mover el enum.
           SERVER_TRACKER_PING (u16 pid): lo emite el server al caer
           una TRAMPA MEJORADA pisada por el bando EXE — ejecuta el
           RASTREADOR: la posicion de la victima se revela a todos los
           supervivientes. Mismo orden que el enum del cliente
           (net_packets.gml); anadido AL FINAL en los DOS lados. */
        CLIENT_EGG_TRAP_UPGRADE,
        SERVER_TRACKER_PING,

        /* v3.1 — «Genio Malvado» al estilo del RESCATE de Vanilla
           (v2.11), pero para MEJORAR TRAMPAS: Eggman ENCIMA de la
           trampa manteniendo ABAJO con anillos de sobra (3 sensor /
           5 trampa de Amelia).
           CLIENT_EGG_TRAP_UPGRADE_PROGRESS (u8 type: 0 sensor /
           1 trampa; u16 nid; u8 anillos actuales del cliente): el
           server acumula el progreso en la ENTIDAD (upg_progress,
           se conserva al soltar como la barra del revive) y reenvia
           la barra con SERVER_EGG_UPGRADE_PROGRESS (u8 type, u16 nid,
           double prog). Al llenarla cobra los anillos (plr.rings) y
           marca la entidad mejorada (SERVER_ETRACKER_STATE 2 /
           SERVER_AMELIA_TRAP_STATE 3 de siempre).
           SERVER_EGG_UPGRADE_STATUS (u8 show, u8 type, u16 nid) abre/
           cierra la barra. El contorno dorado y la barra SOLO los
           dibuja el bando superviviente (Draw_0 de las trampas).
           Mismo orden que el enum del cliente (net_packets.gml);
           anadido AL FINAL en los DOS lados. */
        CLIENT_EGG_TRAP_UPGRADE_PROGRESS,
        SERVER_EGG_UPGRADE_PROGRESS,
        SERVER_EGG_UPGRADE_STATUS,

        /* v2.14 — Fleetway Amy: flecha de la ballesta (patron laser
           de Tails, recta sin gravedad). CLIENT_FWBOLT (u16 x, u16 y,
           s8 dir, u8 dmg) -> entidad FwBolt; SERVER_FWBOLT_STATE
           0/1/2 = spawn/tick/destroy; CLIENT_FWBOLT_HIT la retira.
           Mismo orden que el enum del cliente (net_packets.gml);
           anadido AL FINAL en los DOS lados. */
        CLIENT_FWBOLT,
        CLIENT_FWBOLT_HIT,
        SERVER_FWBOLT_STATE,

        /* v5.3 — LMS «El Show Fuerte» POR PERSONAJE: SERVER_GAME_LMS
           (payload u8 char + u8 song = personaje con show + indice de
           SU cancion): el server lo emite UNA VEZ al detectar que el
           unico superviviente vivo tiene show en LMS_SHOWS (Server.h);
           sube el reloj a la duracion de la cancion elegida y los
           clientes entran en el show (su cancion + banner + vida al
           personaje del show; las pasivas de bloqueo/stuns son
           personales de Sonic). Se re-envia en game_state_join para
           reconexiones. Mismo orden que el enum del cliente
           (net_packets.gml); anadido AL FINAL en los DOS lados. */
        SERVER_GAME_LMS,

        /* v1 JINNA (killer de D.I.B.): teletransporte y agarre.
           CLIENT_JINNA_TELEPORT (u16 x, u16 y): la jugadora ya se movio
           en su cliente; el server valida cooldown, abre el grace del
           anticheat (ex_teleport = 60, mismo que el tele de Exeller a
           su clon) y replica los DOS portales (salida = su ultima pos
           conocida aqui, llegada = la del paquete) a todos.
           CLIENT_JINNA_GRAB (u16 pid, s8 dir): agarre al superviviente
           pid mirando hacia dir; el server valida (exe + cooldown +
           victima viva) y reenvia SERVER_JINNA_GRAB_STATE (u16 pid, s8
           dir): la victima se congela y sufre el dano + HITSPARK EN SU
           cliente (la autoridad de su propio jugador) y al soltarla
           sale empujada en dir (v4.1); el resto crea el efecto visual.
           Mismo orden que el enum del cliente (net_packets.gml); anadido
           AL FINAL en los DOS lados. */
        CLIENT_JINNA_TELEPORT,
        CLIENT_JINNA_GRAB,
        SERVER_JINNA_PORTAL_STATE,
        SERVER_JINNA_GRAB_STATE,

        /* v3 JINNA (D.I.B.) — teleport potenciado + PORTAL TRAMPA.
           CLIENT_JINNA_TRAP (u16 x, u16 y): la V+ABAJO planta la trampa;
           el server valida (exe + Jinna + cooldown de la V compartido con
           el agarre) y spawnea la entidad JinnaTrap, que replica
           SERVER_JINNA_TRAP_STATE 0 spawn (id, x, y) / 1 remove (id) /
           2 pisada (id, x, y) a todos.
           CLIENT_JINNA_TRAP_HIT (u16 id, u16 pid): aviso de pisada desde
           el cliente de la victima; el server valida (trampa viva +
           victima superviviente viva) y reenvia SERVER_JINNA_TRAP_HIT
           (u16 pid, u8 kind, u16 jx, u16 jy): kind 0 = daño + TP hasta
           Jinna SIN i-frames para la victima (si los tenia, se le
           remueven); kind 1 = VANILLA, kind 2 = AMY CANON (v4) y kind 3
           = SALLY CANON (v4.1): absorbidas a la otra dimension (fuera
           de juego + potenciacion del kit de Jinna en todos; fuerte con
           Vanilla, "ardua"/la mitad con Amy o Sally Canon).
           SERVER_JINNA_TELE_AOE (u16 pid): rafaga del teleport — el
           server ralentiza a los supervivientes vivos en radio de la
           llegada del CLIENT_JINNA_TELEPORT; la victima aplica el slow
           sobre su propio jugador. Mismo orden que el enum del cliente
           (net_packets.gml); anadido AL FINAL en los DOS lados. */
        CLIENT_JINNA_TRAP,
        CLIENT_JINNA_TRAP_HIT,
        SERVER_JINNA_TRAP_STATE,
        SERVER_JINNA_TRAP_HIT,
        SERVER_JINNA_TELE_AOE,

        /* v6 JINNA (D.I.B.) — CAPTURA UNIVERSAL + MINIONS DEL PORTAL.
           CLIENT_JINNA_MINION: la Jinna local presiono ↓+C; el server
           valida (exe + Jinna + cooldown JINNA_MINION) y reenvia
           SERVER_JINNA_MINION_STATE (u16 jx, u16 jy, u8 count, u8[16]
           pids): TODOS los PLAYER_CAUGHT se invocan a los pies de Jinna
           (jx/jy) como MINIONS — el cliente de CADA minion reusa el
           flujo de demonizacion del server (SERVER_GAME_DEATHTIMER_END
           con demonize=true): reviven con 100 hp, paleta demon y pelean
           para el bando EXE, pero con VIDA REAL: su hp viaja en el UDP
           como el de cualquier superviviente y los golpes de los
           supervivientes les hacen 20 de dano (el cliente del propio
           minion es la autoridad, patron del juego entero). El server
           les marca PLAYER_DEMONIZED (cuentan como caidos para el win
           del EXE) y les LIMPIA PLAYER_CAUGHT.
           SERVER_JINNA_MINION_DOWN (u16 pid): un minion llego a 0 hp —
           su cliente lo reporta (CLIENT_JINNA_MINION_DOWN); el server
           valida (demonizado + en partida) y retransmite: el cliente del
           minion lo manda de vuelta AL PORTAL (fuera de juego otra vez,
           PLAYER_CAUGHT de nuevo; Jinna puede reinvocarlo pasando el
           cooldown). Mismo orden que el enum del cliente
           (net_packets.gml); anadido AL FINAL en los DOS lados. */
        CLIENT_JINNA_MINION,
        CLIENT_JINNA_MINION_DOWN,
        SERVER_JINNA_MINION_STATE,
        SERVER_JINNA_MINION_DOWN
} PacketType;

typedef struct
{
        #define PACKET_MAXSIZE 256

        uint8_t buff[PACKET_MAXSIZE];
        uint8_t pos;
        uint8_t len;
} Packet;

/* UTF-8 supporting string */
typedef struct
{
        char            value[250];
        uint16_t        len;
} String;

String string_new(const char* value);
size_t string_length(String* str);
String string_lower(String str);
#define __Str(x) string_new(x)

bool    packet_new(Packet* packet, PacketType type);
Packet  packet_from(ENetPacket* packet);

struct Server;
bool packet_send(ENetPeer* peer, Packet* packet, bool reliable);
bool packet_send_id(struct Server* server, uint16_t id, Packet* packet, bool reliable);
bool packet_seek(Packet* packet, int wh);

bool packet_read8(Packet* packet, uint8_t* out);
bool packet_read16(Packet* packet, uint16_t* out);
bool packet_read32(Packet* packet, uint32_t* out);
bool packet_read64(Packet* packet, uint64_t* out);
bool packet_readfloat(Packet* packet, float* out);
bool packet_readdouble(Packet* packet, double* out);
bool packet_readstr(Packet* packet, String* out);

bool packet_write8(Packet* packet, uint8_t value);
bool packet_write16(Packet* packet, uint16_t value);
bool packet_write32(Packet* packet, uint32_t value);
bool packet_write64(Packet* packet, uint64_t value);
bool packet_writefloat(Packet* packet, float value);
bool packet_writedouble(Packet* packet, double value);
bool packet_writestr(Packet* packet, String value);

#define PacketCreate(packet, type) RAssert(packet_new(packet, type))
#define PacketRead(outname, packet, func, type)\
type outname;\
RAssert(func(packet, (void*)&outname))
#define PacketWrite(packet, func, val) RAssert(func(packet, val))

#endif
