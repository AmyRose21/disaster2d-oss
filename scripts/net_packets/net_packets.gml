enum PacketType
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

        /* Amy Canon: token de desbloqueo del personaje reservado
           (se envia justo despues de IDENTITY; el server lo compara con
           "amy_canon_token" de su Config.json) */
        CLIENT_AMY_AUTH,

        /* Sonic parry: desvio del laser de Tails (el server lo invierte y
           lo rebroadcastea como _state 3) y conversion del anillo negro de
           Exetior en anillo dorado recogible. AL FINAL del enum a proposito:
           mismo orden en el Packet.h del server, y un cliente viejo que no
           los conozca simplemente los ignora. */
        CLIENT_TPROJECTILE_DEFLECT,
        CLIENT_BRING_DEFLECT,

        /* Sistema de operadores (.op) del server: el server envia el
           estado de operador de este cliente (1 = es operador:
           desbloquea a Sally Canon en la seleccion, ver net_tcpprocess
           y scr_char_locked). Lo mandan Server.c y ui/Main.c. Mismo
           orden en el Packet.h del server. */
        SERVER_OPERATOR_STATE,
        
        /* Vanilla v2 (Chocola): des-demonizacion de un esbirro pagada
           con 15 anillos por Vanilla (esbirro ATURDIDO al alcance). El
           server valida estado y distancia, limpia su flag
           PLAYER_DEMONIZED y avisa a todos. Mismo orden que el Packet.h
           del server (betterserver-oss). */
        CLIENT_VANILLA_DEDEMONIZE,
        SERVER_VANILLA_DEDEMONIZE,

        /* v2.2 — personajes de TD2D Through the Blood (rescatados del
           mod abandonado). Mismo orden en el Packet.h del server.
           Amelia: banana (trampolin resorte) y trampa (dura hasta
           60 s o hasta que la pise el lado del EXE: stun 3 s +
           slow -40% 3.5 s tras el stun). Blaze: bola de fuego
           (proyectil que aturde al killer 2 s). Metal Amy (killer):
           bala (proyectil que dana a los sobrevivientes). */
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
           + la posicion del primer solape. Mismo orden que el
           Packet.h del server. */
        CLIENT_BLAZE_FIREBALL_BOUNCE,

        /* v2.11 — Vanilla: el RESCATE DE ESBIRROS usa el mismo sistema
           del revive de los caidos. Progreso del rescate (Vanilla
           encima del esbirro ATURDIDO manteniendo ABAJO, 15+ anillos);
           el server acumula el progreso (plr.dedemon_progress),
           reenvia la MISMA barra (SERVER_REVIVAL_PROGRESS) y al
           llenarla dispara el SERVER_VANILLA_DEDEMONIZE de siempre.
           Mismo orden que el Packet.h del server (anadido AL FINAL en
           los DOS lados, como el BOUNCE de la v2.9). */
        CLIENT_VANILLA_DEDEMONIZE_PROGRESS,

        /* v3.0 — «Genio Malvado» (Eggman) + balance de trampas:
           CLIENT_EGG_TRAP_UPGRADE pedia mejorar una entidad al instante
           (tecla V). v3.1: DEPRECATED — sustituido por el estilo RESCATE
           (CLIENT_EGG_TRAP_UPGRADE_PROGRESS de abajo); el ID se conserva
           para no mover el enum. SERVER_TRACKER_PING lo emite el server
           cuando cae una TRAMPA MEJORADA pisada por el bando EXE: ejecuta
           el RASTREADOR y revela la posicion de la victima a todos los
           supervivientes (mismo obj_surv_indicator que los sensores).
           Mismo orden que el Packet.h del server. */
        CLIENT_EGG_TRAP_UPGRADE,
        SERVER_TRACKER_PING,

        /* v3.1 — «Genio Malvado» al estilo del RESCATE de Vanilla
           (v2.11), pero para MEJORAR TRAMPAS: Eggman encima de la
           trampa manteniendo ABAJO con anillos de sobra (3 sensor /
           5 trampa de Amelia). CLIENT_EGG_TRAP_UPGRADE_PROGRESS
           (u8 type: 0 sensor / 1 trampa; u16 nid; u8 anillos actuales)
           — el server acumula el progreso en la ENTIDAD (upg_progress),
           reenvia la barra con SERVER_EGG_UPGRADE_PROGRESS (u8 type,
           u16 nid, double prog) y al llenarla cobra los anillos y dora
           la trampa (SERVER_ETRACKER_STATE 2 / SERVER_AMELIA_TRAP_STATE
           3 de siempre). SERVER_EGG_UPGRADE_STATUS (u8 show, u8 type,
           u16 nid) abre/cierra la barra. El contorno dorado y la barra
           SOLO los dibuja el bando superviviente (v3.1). Mismo orden
           que el Packet.h del server (AL FINAL en los DOS lados). */
        CLIENT_EGG_TRAP_UPGRADE_PROGRESS,
        SERVER_EGG_UPGRADE_PROGRESS,
        SERVER_EGG_UPGRADE_STATUS,

        /* v2.14 — Fleetway Amy: flecha de la BALLESTA (tecla C).
           CLIENT_FWBOLT (u16 x, u16 y, s8 dir, u8 dmg): el server
           valida (Fleetway + CD anti-spam) y spawnea la entidad
           FwBolt (recta, patron laser de Tails). SERVER_FWBOLT_STATE
           0 spawn (id, x, y, owner, dir, dmg) / 1 tick (id, x, y) /
           2 destroy (id) / 3 clavada-plataforma (id, x, y).
           v2.15 («La Torre»): TODOS los estados llevan el id de la
           entidad (hasta 3 flechas a la vez) y la flecha se CLAVA en
           los solidos (CLIENT_FWBOLT_HIT: u16 id, u8 tipo (0 rompe /
           1 clava), u16 x, u16 y) quedando 5 s como plataforma.
           Mismo orden que el Packet.h del server (AL FINAL en los
           DOS lados). */
        CLIENT_FWBOLT,
        CLIENT_FWBOLT_HIT,
        SERVER_FWBOLT_STATE
}

#macro STATE_PENDING -1
#macro STATE_LOBBY 0
#macro STATE_VOTE 1
#macro STATE_CHARSELECT 2
#macro STATE_GAME 3
#macro STATE_RESULTS 4

#macro PLAYER_EFFECT 1 << 1
#macro PLAYER_HURT 1 << 2
#macro PLAYER_REDRING 1 << 3
#macro PLAYER_ATTACKING 1 << 4
#macro PLAYER_SALLYSHIELD 1 << 5
#macro PLAYER_INVIS 1 << 6
#macro PLAYER_SLIME 1 << 7
// v4.10 FIX: PLAYER_DJ era 1 << 8 = 256 y el bitflag viaja en un
// buffer_u8 (0..255): el bit SE PERDIA (256 & 0xFF = 0) y el stun del
// DJ de FW Amy nunca llego a funcionar. Ahora comparte el bit 7 con
// PLAYER_SLIME: es seguro porque SLIME solo lo usa Chaos (un EXE) y
// DJ solo lo usa Fleetway Amy (superviviente) — jamas colisionan. El
// server solo interpreta PLAYER_ATTACKING y retransmite el byte tal
// cual (states/Game.c), asi que llega intacto a los puppets.
#macro PLAYER_DJ 1 << 7        // v2.15/v4.10 «La Torre»: FW Amy volando con el DJ (stun 3,2 s al exe)
// SONIC: powerboost de Nervios de Acero (estela de fantasmas en el puppet)
#macro PLAYER_POWERBOOST 1 << 0