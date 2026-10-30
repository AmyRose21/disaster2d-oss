#ifndef CREAM_RING
#define CREAM_RING
#include "../States.h"

bool cring_init(Server* server, Entity* entity);
bool cring_uninit(Server* server, Entity* entity);

typedef struct
{
	ENTITY_BODY

	uint8_t rid;
	uint8_t red;
	uint8_t worth; /* v1.2: anillos invocados por Vanilla valen 3 */
} CreamRing;
#define MakeCreamRing(x, y, red, worth) ((CreamRing) { MakeEntity("cring", x, y) cring_init, NULL, cring_uninit, 255, red, worth })

#endif