#ifndef DEVICES_H
#define DEVICES_H

/* v80c: Rouge (y futuros personajes) por DISPOSITIVO, diseño de la
   dueña. El claim vive en Devices.txt (al lado del exe, junto a
   Bans.json y compania), UNA LINEA POR CLAIM, editable con el Bloc
   de notas:

        rouge|1a2b3c...64letras|nick|2026-11-23 22:14

   La primera columna es el personaje (la clave), la segunda el
   SHA-256 del device_id (con salt del server: no se puede revertir),
   nick y fecha son informativos. Lineas que empiecen con # son
   comentarios; las lineas corruptas se ignoran y no rompen nada.
   BORRAR la linea = liberar el claim: el server RELEE el archivo
   antes de cada check/claim, asi que aplica SIN reiniciar. No hay
   comando para quitarlo (decision de la dueña: solo el .txt). */

#include <Server.h>
#include <stdbool.h>

typedef enum
{
        DEVCLAIM_OK = 0,      /* registrado: este dispositivo ahora tiene el personaje */
        DEVCLAIM_ALREADY,     /* este dispositivo ya lo tenia (idempotente) */
        DEVCLAIM_TAKEN,       /* otro dispositivo ya lo reclamo */
        DEVCLAIM_ERROR        /* fallo de E/O (archivo no escribible) */
} DeviceClaimResult;

SERVER_API bool devices_init(void);
SERVER_API bool devices_check(const char* character, const char* device_id);
SERVER_API DeviceClaimResult devices_claim(const char* character, const char* device_id, const char* nickname);
SERVER_API bool devices_hash(const char* device_id, char out[65]);

#endif
