#include <maps/Act9.h>
#include <entities/Act9Wall.h>
#include <States.h>

bool act9_init(Server* server)
{
	RAssert(map_time(server, 2.17 * TICKSPERSEC, 10)); // 130
	RAssert(map_ring(server, 3));

	if (g_config.random_mode) {
		int random = rand() % 8;

		if (random == 0 || random == 3 || random == 4 || random == 6)
			RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(0, 0, 1025)), sizeof(Act9Wall), NULL));
		if (random == 1 || random == 3 || random == 5 || random == 6)
			RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(1, 1663, 0)), sizeof(Act9Wall), NULL));
		if (random == 2 || random == 4 || random == 5 || random == 6)
			RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(2, 1663, 0)), sizeof(Act9Wall), NULL));
		if (random == 7)
			Info("Act9: No walls!");
	}
	else {
		RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(0, 0, 1025)), sizeof(Act9Wall), NULL));
		RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(1, 1663, 0)), sizeof(Act9Wall), NULL));
		RAssert(game_spawn(server, (Entity*)&(MakeAct9Wall(2, 1663, 0)), sizeof(Act9Wall), NULL));
		Info("Act9: All Walls");
	}

	return true;
}