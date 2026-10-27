#ifndef CONFIG_H
#define CONFIG_H

#include <cJSON.h>
#include <Api.h>
#include <io/Threads.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdbool.h>

#ifndef SYS_ANDROID
        #define CONFIG_FILE "Config.json"
        #define BANS_FILE "Bans.json"
        #define OPERATORS_FILE "Operators.json"
        #define TIMEOUTS_FILE "Timeouts.json"
#else
        #define ANDROID_DIR "/data/data/com.teamexeempire.disaster2d/files/"
        #define CONFIG_FILE ANDROID_DIR "Config.json"
        #define BANS_FILE ANDROID_DIR "Bans.json"
        #define OPERATORS_FILE ANDROID_DIR "Operators.json"
        #define TIMEOUTS_FILE ANDROID_DIR "Timeouts.json"
#endif

/* Relay: publicar el servidor en el directorio central (relaysc.dr2.site)
 * sin abrir puertos. La cuenta NO se registra desde el server: se escribe
 * directamente en Config.json (seccion "relay"), como en el original. */
typedef struct
{
        bool    enabled;
        char    directory_host[66];
        int32_t directory_port;
        char    username[32];
        char    password[32];
} RelayConfig;

typedef struct
{
        int32_t port;
        int32_t server_count;
        int32_t ping_limit;
        bool    log_debug;
        bool    log_file;
        bool    anticheat;
        bool    pride;
        bool    map_list[20];
        Mutex   map_list_lock;
        char    motd[256];
        bool    random_mode;
        bool    chatfix;

        /* Timers del lobby (segundos, configurables en Config.json).
           Si falta la clave en un Config.json viejo se usan estos defaults. */
        int32_t afk_kick_time;     /* Kick AFK en la sala de espera (default 25, min 10, max 3600) */
        int32_t charselect_time;   /* TIME UP seleccion de personaje (default 30, min 10, max 255) */
        int32_t practice_time;     /* TIME UP practica sin EXE (default 60, min 10, max 255) */
        int32_t lobby_countdown;   /* Cuenta atras cuando todos estan ready (default 5, min 1, max 60) */
        int32_t mapvote_time;      /* Votacion de mapa (default 30, min 10, max 255) */

        char    amy_canon_token[65];    /* Amy Canon: frase secreta (max 64); vacia = bloqueada para todos */
        bool    allow_duplicate_ip;     /* Amy Canon: true = permite conectar 2 juegos desde la misma PC/IP (test local).
                                           CON RELAY ACTIVO DEBE SER true: todos los jugadores relayeados
                                           llegan desde 127.0.0.1 y sin esto solo entraria uno. */
        RelayConfig relay;              /* Relay de relaysc.dr2.site (port del sistema de penguinehis) */
} Config;

SERVER_API extern Config g_config;
SERVER_API extern cJSON* g_bans;
SERVER_API extern cJSON* g_timeouts;
SERVER_API extern cJSON* g_ops;
SERVER_API extern Mutex g_banMut;
SERVER_API extern Mutex g_timeoutMut;
SERVER_API extern Mutex g_opMut;

SERVER_API bool config_init(void);
SERVER_API bool config_save(void);

SERVER_API bool ban_add(const char* nickname, const char* udid, const char* ip);
SERVER_API bool ban_revoke(const char* udid, const char* ip);
SERVER_API bool ban_check(const char* udid, const char* ip, bool* result);

SERVER_API bool timeout_set(const char* nickname, const char* udid, const char* ip, uint64_t timestamp);
SERVER_API bool timeout_revoke(const char* udid, const char* ip);
SERVER_API bool timeout_check(const char* udid, const char* ip, uint64_t* result);

SERVER_API bool op_add(const char* nickname, const char* ip);
SERVER_API bool op_revoke(const char* ip);
SERVER_API bool op_check(const char* ip, bool* result);

bool collection_save(const char* file, cJSON* value);

#endif