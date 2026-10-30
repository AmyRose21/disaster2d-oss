#ifndef RING_H
#define RING_H
#include "../States.h"

bool ring_init(Server* server, Entity* entity);
bool ring_uninit(Server* server, Entity* entity);

typedef struct
{
        ENTITY_BODY

	uint8_t rid;
	uint8_t red;
	uint8_t worth; /* v1.2: anillos invocados valen 'worth' (Vanilla: 3); los de mapa siempre 1. Mismo offset que CreamRing.worth */
} Ring;
#define MakeRing() ((Ring) { MakeEntity("ring", 0, 0) ring_init, NULL, ring_uninit, 0, 0, 1 })

#endif