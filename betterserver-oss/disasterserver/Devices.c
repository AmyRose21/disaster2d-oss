/* v80c: claims de personajes por dispositivo (ver include/Devices.h
   para el formato del Devices.txt). Se mantiene una copia en RAM
   (g_claims) y se RELEE el archivo antes de cada check/claim para
   que editar el .txt con el Bloc de notas aplique sin reiniciar. */

#include <Devices.h>
#include <SHA256.h>
#include <Config.h>
#include <Log.h>
#include <io/Threads.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#define DEVICES_MAX   16   /* personajes reclamables distintos (rouge hoy) */
#define DEVCHAR_MAX   24   /* "rouge", "sonic", ... */
#define DEVNICK_MAX   32
#define DEVDATE_MAX   24   /* "2026-11-23 22:14" */

/* Salt fija del server: no es secreto criptografico, solo evita que
   un Devices.txt filtrado sirva para identificar telefonos buscando
   los hashes en tablas conocidas de android_ids. */
#define DEVICES_SALT "d2d-rouge-salt-v1"

typedef struct
{
        char character[DEVCHAR_MAX];
        char hash[65];                 /* SHA-256 hex del device_id+salt */
        char nickname[DEVNICK_MAX];    /* informativo */
        char date[DEVDATE_MAX];        /* informativo */
} DeviceClaim;

static DeviceClaim g_claims[DEVICES_MAX];
static Mutex g_devMut;
static bool g_devices_ready = false;

/* hash hex-64 de device_id + salt. Siempre true; vacio produce un
   hash de la salt sola (el CMD_ROUGE igual filtra device_id vacio
   antes de llamar). */
bool devices_hash(const char* device_id, char out[65])
{
        SHA256_CTX ctx;
        uint8_t digest[32];

        sha256_init(&ctx);
        sha256_update(&ctx, (const uint8_t*)DEVICES_SALT, strlen(DEVICES_SALT));
        if (device_id && device_id[0])
                sha256_update(&ctx, (const uint8_t*)device_id, strlen(device_id));
        sha256_final(&ctx, digest);

        static const char hexdig[] = "0123456789abcdef";
        for (int i = 0; i < 32; i++)
        {
                out[i*2]   = hexdig[digest[i] >> 4];
                out[i*2+1] = hexdig[digest[i] & 0xF];
        }
        out[64] = '\0';
        return true;
}

/* Relee Devices.txt a g_claims. Lineas "#..." = comentario, vacias y
   corruptas se saltan sin error (tolerante a edicion a mano). */
static void devices_reload(void)
{
        memset(g_claims, 0, sizeof(g_claims));

        FILE* f = fopen(DEVICES_FILE, "r");
        if (!f)
                return; /* sin archivo = sin claims */

        char line[512];
        int n = 0;
        while (fgets(line, sizeof(line), f) && n < DEVICES_MAX)
        {
                /* quitar \r\n final */
                size_t len = strlen(line);
                while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
                        line[--len] = '\0';

                if (len == 0 || line[0] == '#')
                        continue;

                /* parsear personaje|hash|nick|fecha (nick y fecha opcionales) */
                char* c1 = strchr(line, '|');
                if (!c1)
                        continue; /* basura sin separador: se ignora */
                *c1 = '\0';

                char* c2 = strchr(c1 + 1, '|');
                if (c2)
                        *c2 = '\0';

                const char* character = line;
                const char* hash = c1 + 1;

                /* validar: personaje no vacio, hash hex de 64 */
                if (character[0] == '\0' || strlen(hash) != 64)
                        continue;

                int hexok = 1;
                for (int i = 0; i < 64; i++)
                        if (!isxdigit((unsigned char)hash[i]))
                                hexok = 0;
                if (!hexok)
                        continue;

                snprintf(g_claims[n].character, DEVCHAR_MAX, "%s", character);
                snprintf(g_claims[n].hash, 65, "%s", hash);
                if (c2)
                {
                        char* c3 = strchr(c2 + 1, '|');
                        if (c3)
                                *c3 = '\0';
                        snprintf(g_claims[n].nickname, DEVNICK_MAX, "%s", c2 + 1);
                        if (c3)
                                snprintf(g_claims[n].date, DEVDATE_MAX, "%s", c3 + 1);
                }
                n++;
        }
        fclose(f);
}

/* escribe g_claims de vuelta al archivo (con cabecera de comentarios) */
static bool devices_save(void)
{
        FILE* f = fopen(DEVICES_FILE, "w");
        if (!f)
        {
                Warn("devices: no puedo escribir %s", DEVICES_FILE);
                return false;
        }

        fputs("# Claims de personajes por dispositivo (v80c)\n", f);
        fputs("# Formato: personaje|hash-del-dispositivo|nick|fecha\n", f);
        fputs("# BORRAR la linea = liberar el claim (aplica solo, sin reiniciar)\n", f);

        for (int i = 0; i < DEVICES_MAX; i++)
        {
                if (g_claims[i].character[0] == '\0')
                        continue;
                fprintf(f, "%s|%s|%s|%s\n",
                        g_claims[i].character, g_claims[i].hash,
                        g_claims[i].nickname, g_claims[i].date);
        }

        fclose(f);
        return true;
}

/* busca el claim de un personaje; NULL si esta libre */
static DeviceClaim* devices_find(const char* character)
{
        for (int i = 0; i < DEVICES_MAX; i++)
                if (g_claims[i].character[0] != '\0' &&
                    strcmp(g_claims[i].character, character) == 0)
                        return &g_claims[i];
        return NULL;
}

static int devices_free_slot(void)
{
        for (int i = 0; i < DEVICES_MAX; i++)
                if (g_claims[i].character[0] == '\0')
                        return i;
        return -1;
}

bool devices_init(void)
{
        MutexCreate(g_devMut);
        devices_reload();

        /* crear el archivo vacio si no existe, para que la duena lo
           vea al lado del exe desde el primer arranque */
        FILE* f = fopen(DEVICES_FILE, "r");
        if (!f)
        {
                memset(g_claims, 0, sizeof(g_claims));
                devices_save();
        }
        else
                fclose(f);

        g_devices_ready = true;
        Info("Devices: claims cargados desde %s", DEVICES_FILE);
        return true;
}

bool devices_check(const char* character, const char* device_id)
{
        if (!character || !device_id)
                return false;

        char hash[65];
        devices_hash(device_id, hash);

        MutexLock(g_devMut);
        devices_reload(); /* edicion manual del .txt aplica ya */
        DeviceClaim* c = devices_find(character);
        bool res = c != NULL && strcmp(c->hash, hash) == 0;
        MutexUnlock(g_devMut);

        return res;
}

DeviceClaimResult devices_claim(const char* character, const char* device_id, const char* nickname)
{
        if (!character || !device_id || !character[0])
                return DEVCLAIM_ERROR;

        char hash[65];
        devices_hash(device_id, hash);

        DeviceClaimResult res = DEVCLAIM_ERROR;

        MutexLock(g_devMut);
        devices_reload(); /* edicion manual del .txt aplica ya */

        DeviceClaim* c = devices_find(character);
        if (c)
        {
                res = strcmp(c->hash, hash) == 0 ? DEVCLAIM_ALREADY : DEVCLAIM_TAKEN;
        }
        else
        {
                int slot = devices_free_slot();
                if (slot < 0)
                {
                        res = DEVCLAIM_TAKEN; /* tabla llena: se comporta como ocupado */
                }
                else
                {
                        time_t now = time(NULL);
                        struct tm* tm = localtime(&now);

                        snprintf(g_claims[slot].character, DEVCHAR_MAX, "%s", character);
                        snprintf(g_claims[slot].hash, 65, "%s", hash);
                        snprintf(g_claims[slot].nickname, DEVNICK_MAX, "%s",
                                 nickname ? nickname : "");
                        if (tm)
                                strftime(g_claims[slot].date, DEVDATE_MAX, "%Y-%m-%d %H:%M", tm);
                        else
                                snprintf(g_claims[slot].date, DEVDATE_MAX, "unknown");

                        if (devices_save())
                                res = DEVCLAIM_OK;
                        else
                                memset(&g_claims[slot], 0, sizeof(DeviceClaim)); /* rollback en RAM */
                }
        }

        MutexUnlock(g_devMut);
        return res;
}
