#ifndef RELAY_H
#define RELAY_H

#include <Api.h>
#include <stdbool.h>
#include <stdint.h>

/* =====================================================================
 *  Relay (port del sistema de penguinehis / betterserver-v1.6)
 *
 *  Publica este servidor en un directorio central (relaysc.dr2.site)
 *  SIN abrir puertos: el server se conecta SALIENTE al directorio,
 *  este le asigna un relay, y los jugadores conectan al relay en
 *  base_port..base_port+port_count-1. El trafico llega por un tunel
 *  UDP cifrado (HMAC-SHA256) y cada jugador se ve localmente como
 *  127.0.0.1:puerto ("IP sintetica").
 *
 *  Config.json (seccion "relay"):
 *    enabled, directory_host, directory_port, username, password
 *
 *  IMPORTANTE: con relay activo, "allow_duplicate_ip" debe ser true
 *  (todos los jugadores relayeados comparten la IP 127.0.0.1).
 * ===================================================================== */

/* Arranca el hilo "Relay Thr" si relay.enabled (y hay password).
 * Llamar una sola vez tras config_init(). No registra cuentas:
 * el usuario/clave se leen de Config.json, igual que el original. */
SERVER_API bool relay_init(void);

/* ¿El tunel esta conectado y publicado? */
SERVER_API bool relay_online(void);

/* Puerto que hay que enviar al cliente en CHANGELOBBY para el lobby
 * server_id: si el relay esta online devuelve el puerto PUBLICO del
 * relay (base_port + id); si no, el local (g_config.port + id). */
SERVER_API uint32_t relay_public_port(uint16_t server_id);

#endif
