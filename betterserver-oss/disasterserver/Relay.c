/* =====================================================================
 *  Relay.c — Publica el servidor en relaysc.dr2.site sin abrir puertos.
 *
 *  Port del sistema relay de betterserver-v1.6 (penguinehis), recreado
 *  por ingenieria inversa estatica (ver td2dr/relay_server/RELAY_SPEC.md).
 *  Cero conexiones de prueba con cuentas reales durante el desarrollo.
 *
 *  Arquitectura (3 capas):
 *    1. DIRECTORIO (relaysc.dr2.site:9000 UDP) — autentica la cuenta y
 *       asigna un relay (challenge-response HMAC-SHA256).
 *    2. RELAY (ip:puerto propios) — tunel UDP cifrado permanente.
 *    3. JUGADORES — conectan al relay en base_port..base_port+count-1.
 *
 *  Cada jugador relayeado = un socket UDP local propio (127.0.0.1:puerto)
 *  => el ENet del servidor los ve como jugadores locales ("IPs sinteticas").
 *
 *  El ENet del servidor NO se toca; el hilo "Relay Thr" hace todo el
 *  bombeo tunel <-> sockets locales.
 * ===================================================================== */

#include <Relay.h>
#include <Config.h>
#include <Log.h>
#include <io/Socket.h>
#include <io/Threads.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdbool.h>
#include <stdint.h>

/* ------------------------------------------------------------------ */
/*  Sockets portables (winsock ya inicializada por enet_initialize)   */
/* ------------------------------------------------------------------ */

#ifdef _WIN32
        typedef SOCKET  RSocket;
        #define RSOCK_INVALID  INVALID_SOCKET
#else
        typedef int     RSocket;
        #define RSOCK_INVALID  (-1)
        #include <netdb.h>      /* getaddrinfo / freeaddrinfo */
        #include <unistd.h>     /* close */
#endif

/* ------------------------------------------------------------------ */
/*  SHA-256 (FIPS 180-4) + HMAC-SHA256 estandar (RFC 2104)            */
/*  (verificado contra el binario v1.6: ipad 0x36 / opad 0x5c)        */
/* ------------------------------------------------------------------ */

typedef struct
{
        uint32_t h[8];
        uint64_t len;
        uint8_t  buf[64];
        size_t   buflen;
} Sha256Ctx;

static const uint32_t sha_k[64] =
{
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

#define SHA_ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

static void sha256_compress(Sha256Ctx* c, const uint8_t* p)
{
        uint32_t w[64];
        uint32_t a, b, cc, d, e, f, g, h;
        int i;

        for (i = 0; i < 16; i++)
                w[i] = ((uint32_t)p[i * 4] << 24) | ((uint32_t)p[i * 4 + 1] << 16) | ((uint32_t)p[i * 4 + 2] << 8) | p[i * 4 + 3];

        for (i = 16; i < 64; i++)
        {
                uint32_t s0 = SHA_ROTR(w[i - 15], 7) ^ SHA_ROTR(w[i - 15], 18) ^ (w[i - 15] >> 3);
                uint32_t s1 = SHA_ROTR(w[i - 2], 17) ^ SHA_ROTR(w[i - 2], 19) ^ (w[i - 2] >> 10);
                w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }

        a = c->h[0]; b = c->h[1]; cc = c->h[2]; d = c->h[3];
        e = c->h[4]; f = c->h[5]; g  = c->h[6]; h = c->h[7];

        for (i = 0; i < 64; i++)
        {
                uint32_t S1 = SHA_ROTR(e, 6) ^ SHA_ROTR(e, 11) ^ SHA_ROTR(e, 25);
                uint32_t ch = (e & f) ^ (~e & g);
                uint32_t t1 = h + S1 + ch + sha_k[i] + w[i];
                uint32_t S0 = SHA_ROTR(a, 2) ^ SHA_ROTR(a, 13) ^ SHA_ROTR(a, 22);
                uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
                uint32_t t2 = S0 + mj;

                h = g; g = f; f = e; e = d + t1;
                d = cc; cc = b; b = a; a = t1 + t2;
        }

        c->h[0] += a; c->h[1] += b; c->h[2] += cc; c->h[3] += d;
        c->h[4] += e; c->h[5] += f; c->h[6] += g;  c->h[7] += h;
}

static void sha256_init(Sha256Ctx* c)
{
        c->h[0] = 0x6a09e667; c->h[1] = 0xbb67ae85; c->h[2] = 0x3c6ef372; c->h[3] = 0xa54ff53a;
        c->h[4] = 0x510e527f; c->h[5] = 0x9b05688c; c->h[6] = 0x1f83d9ab; c->h[7] = 0x5be0cd19;
        c->len = 0;
        c->buflen = 0;
}

static void sha256_update(Sha256Ctx* c, const uint8_t* data, size_t len)
{
        c->len += len;

        while (len > 0)
        {
                if (c->buflen == 0 && len >= 64)
                {
                        sha256_compress(c, data);
                        data += 64;
                        len -= 64;
                        continue;
                }

                size_t take = 64 - c->buflen;
                if (take > len)
                        take = len;

                memcpy(c->buf + c->buflen, data, take);
                c->buflen += take;
                data += take;
                len -= take;

                if (c->buflen == 64)
                {
                        sha256_compress(c, c->buf);
                        c->buflen = 0;
                }
        }
}

static void sha256_final(Sha256Ctx* c, uint8_t out[32])
{
        uint64_t bits = c->len * 8;
        uint8_t pad = 0x80;
        int i;

        sha256_update(c, &pad, 1);

        pad = 0;
        while (c->buflen != 56)
                sha256_update(c, &pad, 1);

        uint8_t tail[8];
        for (i = 0; i < 8; i++)
                tail[i] = (uint8_t)(bits >> (56 - 8 * i));

        c->len -= 8; /* estos 8 bytes no cuentan como datos */
        sha256_update(c, tail, 8);

        for (i = 0; i < 8; i++)
        {
                out[i * 4]     = (uint8_t)(c->h[i] >> 24);
                out[i * 4 + 1] = (uint8_t)(c->h[i] >> 16);
                out[i * 4 + 2] = (uint8_t)(c->h[i] >> 8);
                out[i * 4 + 3] = (uint8_t)(c->h[i]);
        }
}

static void sha256(const uint8_t* data, size_t len, uint8_t out[32])
{
        Sha256Ctx c;
        sha256_init(&c);
        sha256_update(&c, data, len);
        sha256_final(&c, out);
}

/* HMAC-SHA256 estandar (igual que hmac_sha256 @ 0x14000eb50 del v1.6) */
static void hmac_sha256(const uint8_t* key, size_t keylen, const uint8_t* data, size_t datalen, uint8_t out[32])
{
        uint8_t k[64];
        uint8_t kopad[64];
        uint8_t inn[32];
        Sha256Ctx c;
        int i;

        if (keylen > 64)
        {
                sha256(key, keylen, k);
                memset(k + 32, 0, 32);
        }
        else
        {
                memcpy(k, key, keylen);
                memset(k + keylen, 0, 64 - keylen);
        }

        for (i = 0; i < 64; i++)
                kopad[i] = k[i] ^ 0x5c;

        for (i = 0; i < 64; i++)
                k[i] ^= 0x36;

        sha256_init(&c);
        sha256_update(&c, k, 64);
        sha256_update(&c, data, datalen);
        sha256_final(&c, inn);

        sha256_init(&c);
        sha256_update(&c, kopad, 64);
        sha256_update(&c, inn, 32);
        sha256_final(&c, out);
}

/* ------------------------------------------------------------------ */
/*  Constantes del protocolo (verificadas en .rdata del v1.6)         */
/* ------------------------------------------------------------------ */

#define RELAY_MAX_SESSIONS      512     /* g_sessions[512] del original */
#define RELAY_MAX_PAYLOAD       1368    /* 0x558: payload max por frame */
#define RELAY_MAX_FRAME         1400    /* 0x578: buffer RX maximo      */
#define RELAY_POLL_MS           200     /* poll del pump                */
#define RELAY_TIMEOUT_MS        4000    /* 0xfa0: waits del handshake   */
#define RELAY_PING_SECS         15      /* keepalive cada 15s           */
#define RELAY_DEAD_SECS         45      /* sin respuesta 45s -> reconnect */
#define RELAY_RETRY_SECS        10      /* reintento de tunnel_connect  */
#define RELAY_SESSION_IDLE      300     /* limpieza de sesiones zombis (s) */

/* tipos de frame sellado */
#define RS_TUN_OPEN             0x06    /* abrir sesion (IP del jugador en payload) */
#define RS_TUN_RESET            0x07    /* reset/cerrar sesion                      */
#define RS_TUN_DATA             0x08    /* datos del jugador (bidireccional)        */
#define RS_TUN_PING             0x09    /* keepalive / echo                         */

/* tipos del directorio */
#define RD_HELLO                0x10
#define RD_AUTH                 0x12
#define RD_CHALLENGE            0x11
#define RD_ACCEPT               0x13
#define RD_ERROR                0x14

/* tipos del relay */
#define RR_HELLO                0x01
#define RR_CHALLENGE            0x02
#define RR_TICKET               0x03
#define RR_ACCEPT               0x04

static const uint8_t relay_magic_dir_hello[8]  = { 0xBE, 0x01, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t relay_magic_dir_auth[8]   = { 0xBE, 0x01, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t relay_magic_relay_hello[8]= { 0xBE, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t relay_magic_relay_tkt[8]  = { 0xBE, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00 };

static const char relay_label_h2r_enc[7] = "h2r-enc";
static const char relay_label_h2r_mac[7] = "h2r-mac";
static const char relay_label_r2h_enc[7] = "r2h-enc";
static const char relay_label_r2h_mac[7] = "r2h-mac";
static const char relay_label_session[11] = "session-key";

/* ------------------------------------------------------------------ */
/*  Estado global del relay                                           */
/* ------------------------------------------------------------------ */

typedef struct
{
        bool            active;
        uint32_t        id;             /* asignado por el relay            */
        uint8_t         lobby;          /* 0 = lobby 0 -> g_config.port     */
        RSocket         sock;           /* socket UDP local (127.0.0.1)     */
        uint16_t        local_port;     /* puerto local del socket          */
        char            ip[24];         /* IP real del jugador ("0.0.0.0")  */
        int64_t         last_seen;      /* para limpiar sesiones muertas    */
} RelaySession;

typedef struct
{
        uint8_t         h2r_enc[32];    /* cifrado host->relay */
        uint8_t         h2r_mac[32];    /* MAC host->relay     */
        uint8_t         r2h_enc[32];    /* cifrado relay->host */
        uint8_t         r2h_mac[32];    /* MAC relay->host     */
        uint64_t        tx_seq;         /* empieza en 1        */
        uint64_t        rx_seq;         /* ultimo seq aceptado */
        uint64_t        rx_window;      /* ventana anti-replay de 64 bits */
} RelayCrypto;

static RelaySession         g_sessions[RELAY_MAX_SESSIONS];
static Mutex                g_sessions_lock;
static bool                 g_sessions_lock_init = false;

static RelayCrypto          g_crypto;
static RSocket              g_tunnel = RSOCK_INVALID;
static struct sockaddr_in   g_relay_addr;

static uint32_t             g_base_port = 0;      /* puerto publico del relay   */
static uint8_t              g_port_count = 0;     /* cuantos puertos publicos   */
static volatile bool        g_online = false;
static volatile int64_t     g_last_rx = 0;
static volatile bool        g_echo_seen = false;

/* ------------------------------------------------------------------ */
/*  Helpers de bytes                                                  */
/* ------------------------------------------------------------------ */

static void put_le32(uint8_t* p, uint32_t v)
{
        p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8);
        p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24);
}

static uint32_t get_le32(const uint8_t* p)
{
        return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void put_be64(uint8_t* p, uint64_t v)
{
        for (int i = 0; i < 8; i++)
                p[i] = (uint8_t)(v >> (56 - 8 * i));
}

static uint64_t get_be64(const uint8_t* p)
{
        uint64_t v = 0;
        for (int i = 0; i < 8; i++)
                v = (v << 8) | p[i];
        return v;
}

/* ------------------------------------------------------------------ */
/*  Sesiones                                                          */
/* ------------------------------------------------------------------ */

/* Abre una sesion: socket UDP local con puerto efimero en 127.0.0.1.
 * El ENet del servidor le responde a esa direccion. DEBE llamarse con
 * g_sessions_lock tomado (igual que session_open @ 0x1400130f0). */
static RelaySession* session_open(uint32_t id, uint8_t lobby, uint32_t ip)
{
        int slot = -1;
        for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
        {
                if (!g_sessions[i].active)
                {
                        slot = i;
                        break;
                }
        }

        if (slot < 0)
                return NULL;

        RSocket sock = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock == RSOCK_INVALID)
                return NULL;

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(0x7f000001);  /* 127.0.0.1 */
        addr.sin_port = 0;                          /* puerto efimero */

        if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) != 0)
        {
                close(sock);
                return NULL;
        }

        socklen_t alen = sizeof(addr);
        if (getsockname(sock, (struct sockaddr*)&addr, &alen) != 0)
        {
                close(sock);
                return NULL;
        }

        RelaySession* s = &g_sessions[slot];
        s->active = true;
        s->id = id;
        s->lobby = lobby;
        s->sock = sock;
        s->local_port = ntohs(addr.sin_port);
        snprintf(s->ip, sizeof(s->ip), "%u.%u.%u.%u",
                 (ip >> 24) & 0xff, (ip >> 16) & 0xff, (ip >> 8) & 0xff, ip & 0xff);
        s->last_seen = (int64_t)time(NULL);

        /* Igual que el original (Debug), pero las sesiones de jugadores
         * nuevos se muestran siempre: es lo que el host espera ver. */
        if (ip != 0)
                Info("Relay: session %u -> local port %u as %s", id, s->local_port, s->ip);
        else
                Debug("Relay: session %u -> local port %u as %s", id, s->local_port, s->ip);

        return s;
}

static RelaySession* session_find(uint32_t id)
{
        for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
        {
                if (g_sessions[i].active && g_sessions[i].id == id)
                        return &g_sessions[i];
        }
        return NULL;
}

/* Cierra el tunel y todas las sesiones (queda listo para reconectar). */
static bool relay_disconnect(void)
{
        MutexLock(g_sessions_lock);
        {
                for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
                {
                        if (!g_sessions[i].active)
                                continue;

                        if (g_sessions[i].sock != RSOCK_INVALID)
                                close(g_sessions[i].sock);

                        g_sessions[i].active = false;
                }
        }
        MutexUnlock(g_sessions_lock);

        if (g_tunnel != RSOCK_INVALID)
                close(g_tunnel);

        g_tunnel = RSOCK_INVALID;
        memset(&g_crypto, 0, sizeof(g_crypto));
        g_online = false;
        g_echo_seen = false;

        return true;
}

/* ------------------------------------------------------------------ */
/*  Frames sellados (tunel cifrado)                                   */
/* ------------------------------------------------------------------ */

/* Frame: [BE 01 tipo lobby sid_le32] [seq_be64] [payload XOR keystream]
 *        [MAC16 = HMAC(mac_key, header16+payload)[0..16]]
 * Keystream bloque N = HMAC(enc_key, seq_be(8) || N_le(4)), 32B por bloque. */
static bool frame_send_sealed(uint8_t type, uint8_t lobby, uint32_t session_id,
                              const uint8_t* payload, int plen)
{
        if (g_tunnel == RSOCK_INVALID || !g_online)
                return false;

        if (plen < 0 || plen > RELAY_MAX_PAYLOAD)
                return false;

        uint8_t frame[16 + RELAY_MAX_PAYLOAD + 16];
        frame[0] = 0xBE;
        frame[1] = 0x01;
        frame[2] = type;
        frame[3] = lobby;
        put_le32(frame + 4, session_id);

        uint64_t seq = g_crypto.tx_seq++;
        put_be64(frame + 8, seq);

        if (plen > 0 && payload)
                memcpy(frame + 16, payload, (size_t)plen);

        /* cifrar payload con keystream por bloques de 32 */
        uint8_t ks_in[12];
        uint8_t ks[32];
        memcpy(ks_in, frame + 8, 8);   /* seq tal como va en el frame (BE) */

        for (int off = 0, n = 0; off < plen; off += 32, n++)
        {
                put_le32(ks_in + 8, (uint32_t)n);
                hmac_sha256(g_crypto.h2r_enc, 32, ks_in, 12, ks);

                for (int j = 0; j < 32 && (off + j) < plen; j++)
                        frame[16 + off + j] ^= ks[j];
        }

        uint8_t mac[32];
        hmac_sha256(g_crypto.h2r_mac, 32, frame, (size_t)(16 + plen), mac);
        memcpy(frame + 16 + plen, mac, 16);

        int total = 16 + plen + 16;
        return sendto(g_tunnel, (const char*)frame, total, 0,
                      (struct sockaddr*)&g_relay_addr, sizeof(g_relay_addr)) == total;
}

/* ------------------------------------------------------------------ */
/*  Fase 1 + 2: conexion al directorio y al relay                     */
/* ------------------------------------------------------------------ */

static int relay_recv_timeout(RSocket sock, uint8_t* buf, int timeout_ms)
{
        struct pollfd pfd;
        pfd.fd = sock;
        pfd.events = POLLIN;
        pfd.revents = 0;

        if (Poll(&pfd, 1, timeout_ms) <= 0)
                return -1;

        return (int)recvfrom(sock, (char*)buf, RELAY_MAX_FRAME, 0, NULL, NULL);
}

static bool tunnel_connect(void)
{
        const char* host = g_config.relay.directory_host;
        int port = g_config.relay.directory_port;
        const char* username = g_config.relay.username;
        const char* password = g_config.relay.password;

        if (!host[0])
        {
                Warn("Relay: no directory host set in Config.json.");
                return false;
        }

        /* Resolver el directorio (IP directa o DNS) */
        uint32_t dir_ip = (uint32_t)inet_addr(host);
        if (dir_ip == INADDR_NONE)
        {
                struct addrinfo hints;
                struct addrinfo* res = NULL;
                memset(&hints, 0, sizeof(hints));
                hints.ai_family = AF_INET;
                hints.ai_socktype = SOCK_DGRAM;

                if (getaddrinfo(host, NULL, &hints, &res) != 0 || !res)
                {
                        Err("Relay: could not resolve the directory host '%s'.", host);
                        return false;
                }

                dir_ip = ((struct sockaddr_in*)res->ai_addr)->sin_addr.s_addr;
                freeaddrinfo(res);
        }

        RSocket sock = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock == RSOCK_INVALID)
                return false;

        struct sockaddr_in dir_addr;
        memset(&dir_addr, 0, sizeof(dir_addr));
        dir_addr.sin_family = AF_INET;
        dir_addr.sin_addr.s_addr = dir_ip;
        dir_addr.sin_port = htons((uint16_t)port);

        int ulen = (int)strlen(username);
        if (ulen > 32)
                ulen = 32;

        /* ---- HELLO: magic + username (sin NUL; vacio = anonimo) ---- */
        uint8_t hello[8 + 32];
        memcpy(hello, relay_magic_dir_hello, 8);
        if (ulen > 0)
                memcpy(hello + 8, username, (size_t)ulen);

        if (sendto(sock, (const char*)hello, 8 + ulen, 0,
                   (struct sockaddr*)&dir_addr, sizeof(dir_addr)) < 0)
        {
                close(sock);
                return false;
        }

        uint8_t reply[RELAY_MAX_FRAME];
        int len = relay_recv_timeout(sock, reply, RELAY_TIMEOUT_MS);

        if (len <= 23 || reply[0] != 0xBE || reply[1] != 0x01 || reply[2] != RD_CHALLENGE)
        {
                Err("Relay: no answer from the directory at %s:%d.", host, port);
                close(sock);
                return false;
        }

        /* ---- challenge-response ----
         * proof      = HMAC(password, salt[16] || username)
         * session    = HMAC(password, salt[16] || "session-key")
         * Paquete CHALLENGE real (capturado + verificado en el disasm v1.6,
         * movdqu xmm2,[buf+8]): el salt vive en reply[8..24], NO en +4.     */
        uint8_t salt[16];
        memcpy(salt, reply + 8, 16);

        uint8_t proof_in[16 + 32];
        memcpy(proof_in, salt, 16);
        if (ulen > 0)
                memcpy(proof_in + 16, username, (size_t)ulen);

        uint8_t proof[32];
        hmac_sha256((const uint8_t*)password, strlen(password), proof_in, (size_t)(16 + ulen), proof);

        uint8_t sess_in[16 + 11];
        memcpy(sess_in, salt, 16);
        memcpy(sess_in + 16, relay_label_session, 11);

        uint8_t session_key[32];
        hmac_sha256((const uint8_t*)password, strlen(password), sess_in, 27, session_key);

        /* ---- AUTH: magic || proof[32] || username ---- */
        uint8_t auth[8 + 32 + 32];
        memcpy(auth, relay_magic_dir_auth, 8);
        memcpy(auth + 8, proof, 32);
        if (ulen > 0)
                memcpy(auth + 40, username, (size_t)ulen);

        if (sendto(sock, (const char*)auth, 40 + ulen, 0,
                   (struct sockaddr*)&dir_addr, sizeof(dir_addr)) < 0)
        {
                close(sock);
                return false;
        }

        len = relay_recv_timeout(sock, reply, RELAY_TIMEOUT_MS);

        if (len <= 7 || reply[0] != 0xBE || reply[1] != 0x01)
        {
                Err("Relay: the directory stopped answering during sign-in.");
                close(sock);
                return false;
        }

        if (reply[2] == RD_ERROR)
        {
                uint8_t err = (len > 8) ? reply[8] : 0;

                if (err == 2)
                        Err("Relay: wrong relay password for '%s'.", username);
                else if (err == 4)
                        Err("Relay: this server has been suspended by the host of the relay.");
                else
                        Err("Relay: the directory does not recognise '%s'. Either the account is gone, its region was removed, or the directory cannot read its account file.", username);

                close(sock);
                return false;
        }

        if (reply[2] != RD_ACCEPT || len <= 149)
        {
                Err("Relay: unexpected reply from the directory (type %u).", (unsigned)reply[2]);
                close(sock);
                return false;
        }

        /* ---- ACCEPT del directorio ----
         * reply[8..96]   ticket (88B, opaco)
         * reply[96..112] region (string, solo para el log)
         * reply[112..116] relay_ip   (network order)
         * reply[116..118] relay_port (host order)
         * reply[118..150] relay_key XOR session_key                    */
        uint8_t ticket[88];
        memcpy(ticket, reply + 8, 88);

        char region[17];
        memcpy(region, reply + 96, 16);
        region[16] = '\0';

        uint32_t relay_ip;
        memcpy(&relay_ip, reply + 112, 4);          /* network order      */

        uint16_t relay_port = (uint16_t)(reply[116] | (reply[117] << 8));

        uint8_t relay_key[32];
        for (int i = 0; i < 32; i++)
                relay_key[i] = reply[118 + i] ^ session_key[i];

        char relay_host[32];
        struct in_addr ia;
        ia.s_addr = relay_ip;
        snprintf(relay_host, sizeof(relay_host), "%s", inet_ntoa(ia));

        Info("Relay: region %s at %s:%u", region, relay_host, (unsigned)relay_port);

        /* Ya no necesitamos el socket del directorio */
        close(sock);

        /* ---- Fase 2: handshake con el relay ---- */
        g_tunnel = socket(AF_INET, SOCK_DGRAM, 0);
        if (g_tunnel == RSOCK_INVALID)
                return false;

        memset(&g_relay_addr, 0, sizeof(g_relay_addr));
        g_relay_addr.sin_family = AF_INET;
        g_relay_addr.sin_addr.s_addr = relay_ip;
        g_relay_addr.sin_port = htons(relay_port);

        if (sendto(g_tunnel, (const char*)relay_magic_relay_hello, 8, 0,
                   (struct sockaddr*)&g_relay_addr, sizeof(g_relay_addr)) < 0)
        {
                close(g_tunnel);
                g_tunnel = RSOCK_INVALID;
                return false;
        }

        len = relay_recv_timeout(g_tunnel, reply, RELAY_TIMEOUT_MS);

        if (len <= 7 || reply[0] != 0xBE || reply[1] != 0x01 || reply[2] != RR_CHALLENGE)
        {
                Err("Relay: no answer from the relay at %s:%u.", relay_host, (unsigned)relay_port);
                close(g_tunnel);
                g_tunnel = RSOCK_INVALID;
                return false;
        }

        /* ---- presentar ticket ---- */
        uint8_t tkt[8 + 88];
        memcpy(tkt, relay_magic_relay_tkt, 8);
        memcpy(tkt + 8, ticket, 88);

        if (sendto(g_tunnel, (const char*)tkt, sizeof(tkt), 0,
                   (struct sockaddr*)&g_relay_addr, sizeof(g_relay_addr)) < 0)
        {
                close(g_tunnel);
                g_tunnel = RSOCK_INVALID;
                return false;
        }

        len = relay_recv_timeout(g_tunnel, reply, RELAY_TIMEOUT_MS);

        if (len <= 12 || reply[0] != 0xBE || reply[1] != 0x01 || reply[2] != RR_ACCEPT)
        {
                Err("Relay: the relay rejected our ticket.");
                close(g_tunnel);
                g_tunnel = RSOCK_INVALID;
                return false;
        }

        /* ---- ACCEPT del relay: puertos publicos + llaves ---- */
        g_base_port = get_le32(reply + 8);
        g_port_count = reply[12];

        hmac_sha256(relay_key, 32, (const uint8_t*)relay_label_h2r_enc, 7, g_crypto.h2r_enc);
        hmac_sha256(relay_key, 32, (const uint8_t*)relay_label_h2r_mac, 7, g_crypto.h2r_mac);
        hmac_sha256(relay_key, 32, (const uint8_t*)relay_label_r2h_enc, 7, g_crypto.r2h_enc);
        hmac_sha256(relay_key, 32, (const uint8_t*)relay_label_r2h_mac, 7, g_crypto.r2h_mac);

        g_crypto.tx_seq = 1;
        g_crypto.rx_seq = 0;
        g_crypto.rx_window = 0;

        g_last_rx = (int64_t)time(NULL);
        g_echo_seen = false;
        g_online = true;

        Info("Relay: online - players can join at %s ports %u-%u",
             relay_host, (unsigned)g_base_port, (unsigned)(g_base_port + g_port_count - 1));

        return true;
}

/* ------------------------------------------------------------------ */
/*  Bombeo: tunel <-> sockets locales                                 */
/* ------------------------------------------------------------------ */

static bool tunnel_pump(void)
{
        struct pollfd fds[RELAY_MAX_SESSIONS + 1];
        int session_idx[RELAY_MAX_SESSIONS + 1];
        int count = 0;

        /* [0] = tunel; el resto = sesiones activas */
        fds[0].fd = (g_tunnel != RSOCK_INVALID) ? (int)g_tunnel : -1;
        fds[0].events = POLLIN;
        fds[0].revents = 0;
        count = 1;

        MutexLock(g_sessions_lock);
        {
                for (int i = 0; i < RELAY_MAX_SESSIONS && count <= RELAY_MAX_SESSIONS; i++)
                {
                        if (!g_sessions[i].active)
                                continue;

                        fds[count].fd = (int)g_sessions[i].sock;
                        fds[count].events = POLLIN;
                        fds[count].revents = 0;
                        session_idx[count] = i;
                        count++;
                }
        }
        MutexUnlock(g_sessions_lock);

        if (Poll(fds, count, RELAY_POLL_MS) <= 0)
                return true;

        for (int i = 0; i < count; i++)
        {
                if (!(fds[i].revents & POLLIN))
                        continue;

                if (i == 0)
                {
                        /* ---------- datos desde el RELAY ---------- */
                        uint8_t buf[RELAY_MAX_FRAME];
                        int len = (int)recvfrom(g_tunnel, (char*)buf, RELAY_MAX_FRAME, 0, NULL, NULL);

                        if (len <= 31)
                                continue;

                        if (buf[0] != 0xBE || buf[1] != 0x01)
                                continue;

                        if (!g_online)
                                continue;

                        int plen = len - 32;   /* payload = total - header16 - MAC16 */

                        /* MAC = HMAC(r2h_mac, frame[0..16+plen])[0..16] */
                        uint8_t mac[32];
                        hmac_sha256(g_crypto.r2h_mac, 32, buf, (size_t)(len - 16), mac);

                        if (memcmp(mac, buf + len - 16, 16) != 0)
                                continue;

                        /* anti-replay con ventana de 64 bits (como el v1.6) */
                        uint64_t seq = get_be64(buf + 8);
                        if (seq == 0)
                                continue;

                        if (seq > g_crypto.rx_seq)
                        {
                                uint64_t diff = seq - g_crypto.rx_seq;
                                if (diff > 63)
                                        g_crypto.rx_window = 1;
                                else
                                        g_crypto.rx_window = (g_crypto.rx_window << diff) | 1;

                                g_crypto.rx_seq = seq;
                        }
                        else
                        {
                                uint64_t diff = g_crypto.rx_seq - seq;
                                if (diff > 63)
                                        continue;

                                uint64_t bit = (uint64_t)1 << diff;
                                if (g_crypto.rx_window & bit)
                                        continue;

                                g_crypto.rx_window |= bit;
                        }

                        g_last_rx = (int64_t)time(NULL);

                        /* ---------- desencriptar el payload (r2h-enc) ----------
                         * El relay cifra TODO payload que manda (0x06/0x08)
                         * con el mismo keystream que nosotros usamos para TX
                         * pero con la llave r2h_enc y el seq DEL FRAME:
                         *   bloque N = HMAC(r2h_enc, seq_be(8) || N_le(4))
                         * Sin esto el ENet local recibe ciphertext y el
                         * handshake del jugador nunca se completa (ver
                         * tunnel_pump+0x419 del v1.6: hace exactamente
                         * este XOR antes del dispatch). */
                        if (plen > 0)
                        {
                                uint8_t ks_in[12];
                                uint8_t ks[32];
                                memcpy(ks_in, buf + 8, 8);   /* seq tal como vino (BE) */

                                for (int off = 0, n = 0; off < plen; off += 32, n++)
                                {
                                        put_le32(ks_in + 8, (uint32_t)n);
                                        hmac_sha256(g_crypto.r2h_enc, 32, ks_in, 12, ks);

                                        for (int j = 0; j < 32 && (off + j) < plen; j++)
                                                buf[16 + off + j] ^= ks[j];
                                }
                        }

                        uint8_t type = buf[2];

                        if (type == RS_TUN_PING)
                        {
                                g_echo_seen = true;
                                continue;
                        }

                        uint8_t lobby = buf[3];
                        uint32_t sid = get_le32(buf + 4);
                        uint8_t* payload = buf + 16;

                        if (type == RS_TUN_OPEN && plen > 3)
                        {
                                /* abrir sesion (IP real del jugador en el payload) */
                                MutexLock(g_sessions_lock);
                                {
                                        if (!session_find(sid))
                                                session_open(sid, lobby, get_le32(payload));
                                }
                                MutexUnlock(g_sessions_lock);
                        }
                        else if (type == RS_TUN_RESET)
                        {
                                /* cerrar todas las sesiones con ese id */
                                MutexLock(g_sessions_lock);
                                {
                                        for (int j = 0; j < RELAY_MAX_SESSIONS; j++)
                                        {
                                                if (!g_sessions[j].active || g_sessions[j].id != sid)
                                                        continue;

                                                if (g_sessions[j].sock != RSOCK_INVALID)
                                                        close(g_sessions[j].sock);

                                                g_sessions[j].active = false;
                                        }
                                }
                                MutexUnlock(g_sessions_lock);
                        }
                        else if (type == RS_TUN_DATA)
                        {
                                /* datos del jugador -> ENet local */
                                MutexLock(g_sessions_lock);
                                {
                                        RelaySession* s = session_find(sid);

                                        /* si el 0x07 se perdio, el primer 0x08 crea
                                         * la sesion igual (como el original, ip=0) */
                                        if (!s)
                                                s = session_open(sid, lobby, 0);

                                        if (s)
                                        {
                                                struct sockaddr_in local;
                                                memset(&local, 0, sizeof(local));
                                                local.sin_family = AF_INET;
                                                local.sin_addr.s_addr = htonl(0x7f000001);
                                                local.sin_port = htons((uint16_t)(g_config.port + s->lobby));

                                                sendto(s->sock, (const char*)payload, (size_t)plen, 0,
                                                       (struct sockaddr*)&local, sizeof(local));
                                                s->last_seen = (int64_t)time(NULL);
                                        }
                                }
                                MutexUnlock(g_sessions_lock);
                        }

                        /* otros tipos: se descartan igual que en el original */
                }
                else
                {
                        /* ---------- datos desde el ENet local -> RELAY ---------- */
                        int si = session_idx[i];
                        RSocket sock;
                        uint32_t sid;
                        uint8_t slobby;

                        MutexLock(g_sessions_lock);
                        {
                                if (!g_sessions[si].active)
                                {
                                        MutexUnlock(g_sessions_lock);
                                        continue;
                                }

                                sock = g_sessions[si].sock;
                                sid = g_sessions[si].id;
                                slobby = g_sessions[si].lobby;
                                g_sessions[si].last_seen = (int64_t)time(NULL);
                        }
                        MutexUnlock(g_sessions_lock);

                        uint8_t buf[RELAY_MAX_FRAME];
                        int len = (int)recvfrom(sock, (char*)buf, RELAY_MAX_FRAME, 0, NULL, NULL);

                        if (len <= 0)
                                continue;

                        if (len > RELAY_MAX_PAYLOAD)
                                continue;

                        frame_send_sealed(RS_TUN_DATA, slobby, sid, buf, len);
                }
        }

        /* limpiar sesiones que no recibieron nada en mucho tiempo
         * (el relay suele mandar el reset, esto es red de seguridad) */
        int64_t now = (int64_t)time(NULL);
        MutexLock(g_sessions_lock);
        {
                for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
                {
                        if (!g_sessions[i].active)
                                continue;

                        if (now - g_sessions[i].last_seen > RELAY_SESSION_IDLE)
                        {
                                if (g_sessions[i].sock != RSOCK_INVALID)
                                        close(g_sessions[i].sock);

                                g_sessions[i].active = false;
                                Debug("Relay: session %u idle, closed.", g_sessions[i].id);
                        }
                }
        }
        MutexUnlock(g_sessions_lock);

        return true;
}

/* ------------------------------------------------------------------ */
/*  Hilo del relay                                                    */
/* ------------------------------------------------------------------ */

static void* relay_worker(void* arg)
{
        (void)arg;

        ThreadVarSet(g_threadName, "Relay Thr");

        int64_t next_ping = 0;

        while (true)
        {
                if (!g_online)
                {
                        if (!tunnel_connect())
                        {
                                Warn("Relay: retrying in %d seconds.", RELAY_RETRY_SECS);
                                ThreadSleep(RELAY_RETRY_SECS * 1000);
                                continue;
                        }

                        next_ping = 0;   /* ping inmediato tras conectar */
                }

                tunnel_pump();

                int64_t now = (int64_t)time(NULL);

                if (now >= next_ping)
                {
                        frame_send_sealed(RS_TUN_PING, 0, 0, NULL, 0);
                        next_ping = now + RELAY_PING_SECS;
                }

                if (g_online && g_echo_seen && (now - g_last_rx) > RELAY_DEAD_SECS)
                {
                        Warn("Relay: no reply for %ds, reconnecting.", RELAY_DEAD_SECS);
                        relay_disconnect();
                }
        }

        return NULL;
}

/* ------------------------------------------------------------------ */
/*  API publica                                                       */
/* ------------------------------------------------------------------ */

bool relay_init(void)
{
        if (!g_config.relay.enabled)
                return true;

        /* Sin password no hay nada que hacer: la cuenta se coloca en
         * Config.json, no se registra ni se pide por pantalla (igual
         * que el original). */
        if (!g_config.relay.password[0])
        {
                Warn("Relay: enabled but no password set in Config.json - relay disabled.");
                return true;
        }

        if (!g_sessions_lock_init)
        {
                MutexCreate(g_sessions_lock);
                g_sessions_lock_init = true;
        }

        memset(g_sessions, 0, sizeof(g_sessions));
        for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
                g_sessions[i].sock = RSOCK_INVALID;

        Info("Relay: connecting to directory at %s:%d...",
             g_config.relay.directory_host, g_config.relay.directory_port);

        Thread th;
        ThreadSpawn(th, relay_worker, NULL);
        return true;
}

bool relay_online(void)
{
        return g_online;
}

uint32_t relay_public_port(uint16_t server_id)
{
        if (g_online && g_port_count > 0)
                return g_base_port + (uint32_t)server_id;

        return (uint32_t)g_config.port + (uint32_t)server_id;
}

bool relay_lookup_ip(uint16_t local_port, char* out, size_t outlen)
{
        bool found = false;

        if (!out || outlen == 0)
                return false;

        out[0] = '\0';

        MutexLock(g_sessions_lock);
        {
                for (int i = 0; i < RELAY_MAX_SESSIONS; i++)
                {
                        if (!g_sessions[i].active || g_sessions[i].local_port != local_port)
                                continue;

                        snprintf(out, outlen, "%s", g_sessions[i].ip);
                        found = true;
                        break;
                }
        }
        MutexUnlock(g_sessions_lock);

        return found;
}
