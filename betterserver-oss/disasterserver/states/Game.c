#include <io/Time.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include <Player.h>
#include <States.h>
#include <CMath.h>
#include <DyList.h>
#include <Server.h>
#include <Palette.h>
#include <Colors.h>
#include <entities/Ring.h>
#include <entities/CreamRing.h>
#include <entities/BlackRing.h>
#include <entities/TailsProjectile.h>
#include <entities/AmeliaBanana.h>
#include <entities/AmeliaTrap.h>
#include <entities/JinnaTrap.h>
#include <entities/BlazeFireball.h>
#include <entities/FwBolt.h>
#include <entities/MetalAmyBullet.h>
#include <entities/EggmanTracker.h>
#include <entities/ExellerClone.h>

bool game_end(Server* server, Ending ending, bool achiv)
{
        if (server->game.end > 0)
                return true;

        Packet packet;
        switch (ending)
        {
                case ED_EXEWIN:
                {
                        PacketCreate(&packet, SERVER_GAME_EXE_WINS);
                        PacketWrite(&packet, packet_write8, achiv);
                        Info("Ending is ED_EXEWIN");
                        break;
                }

                case ED_SURVWIN:
                {
                        PacketCreate(&packet, SERVER_GAME_SURVIVOR_WIN);
                        PacketWrite(&packet, packet_write8, achiv);
                        Info("Ending is ED_SURVWIN");
                        break;
                }

                case ED_TIMEOVER:
                {
                        PacketCreate(&packet, SERVER_GAME_TIME_OVER);
                        PacketWrite(&packet, packet_write8, achiv);
                        Info("Ending is ED_TIMEOVER");
                        break;
                }
        }

        server_broadcast(server, &packet, true);
        server->game.end = 5 * TICKSPERSEC;
        server->game.ending = ending;
        return true;
}

bool game_state_check(Server* server)
{
        if (server->game.end > 0)
                return true;

        uint8_t escaped = 0;
        uint8_t dead = 0;
        uint8_t exes = 0;

        int total = 0;
        {
                for (size_t i = 0; i < server->peers.capacity; i++)
                {
                        PeerData* v = (PeerData*)server->peers.ptr[i];
                        if (!v)
                                continue;

                        if(!v->in_game)
                                continue;

                        if (v->plr.flags & PLAYER_ESCAPED)
                                escaped++;

                        if (v->plr.flags & PLAYER_DEAD || v->plr.flags & PLAYER_DEMONIZED)
                                dead++;

                        if (v->id == server->game.exe)
                                exes++;
                }

                total = server_ingame(server);
                total -= (exes + dead + escaped);
        }

        if (total <= 0)
        {
                if (escaped > 0)
                {
                        RAssert(game_end(server, ED_SURVWIN, true));
                }
                else
                {
                        RAssert(game_end(server, ED_EXEWIN, true));
                }
        }

        return true;
}

bool game_init(int exe, int8_t map, Server* server)
{
        Debug("Attepting to enter ST_GAME...");
        RAssert(server_ingame(server) > 0);

        server->state = ST_GAME;
        server->game = (Game)
        {
                .map = map,
                .exe = exe,
                .bring_state = BS_NONE,
                .bring_loc = (uint8_t)rand(),
                .sudden_death = false,
                .lms = false,
                .lms_char = 0,
                .lms_song = 0,
                .started = false,
                .end = 0.0,
                .entid = 0,
                .time = TICKSPERSEC,
                .elapsed = 0.0,
                .start_timeout = 15.0 * TICKSPERSEC
        };

        // Setup cooldowns
        time_start(&server->game.tails_last_proj);
        memset(server->game.rings, 0, sizeof(server->game.rings));

        /* v2.1.3: los cooldowns de habilidades son POR JUGADOR: se
         * resetean para todos al empezar la partida (no arrastrar los
         * de la partida anterior). */
        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* data = (PeerData*)server->peers.ptr[i];
                if (!data)
                        continue;

                memset(data->plr_cooldowns, 0, sizeof(data->plr_cooldowns));
        }

        if (!dylist_create(&server->game.entities, 3000))
                return false;
        Debug("Entity list created.");

        if (!dylist_create(&server->game.left, 7))
                return false;
        Debug("Left players list created.");

        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* v = (PeerData*)server->peers.ptr[i];
                if (!v)
                        continue;

                if (!v->in_game)
                        continue;

                memset(&v->plr, 0, sizeof(Player));
                
                if (v->id == server->game.exe)
                        SET_FLAG(v->plr.flags, PLAYER_KILLER);

                v->plr.ready = false;
                v->plr.mod_tool = v->mod_tool;

                for (int i = 0; i < 5; i++)
                        v->plr.revival_init[i] = -1;
        }

        Packet pack;
        PacketCreate(&pack, SERVER_LOBBY_GAME_START);
        server_broadcast(server, &pack, true);

        /* Survivor practice: no real EXE is playing, so drop the fake
         * "EXE" (id 0xFFFF) from the clients player lists before the map
         * loads (it would spawn a ghost puppet / scoreboard row). */
        if (exe == 0xFFFF)
        {
                PacketCreate(&pack, SERVER_PLAYER_LEFT);
                PacketWrite(&pack, packet_write16, 0xFFFF);
                server_broadcast(server, &pack, true);
        }

        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* v = (PeerData*)server->peers.ptr[i];
                if (!v)
                        continue;

                if (v->in_game)
                        continue;

                for (size_t j = 0; j < server->peers.capacity; j++)
                {
                        PeerData* er = (PeerData*)server->peers.ptr[j];
                        if (!er)
                                continue;

                        if (er->id == v->id)
                                continue;

                        PacketCreate(&pack, SERVER_WAITING_PLAYER_INFO);
                        PacketWrite(&pack, packet_write8, er->in_game);
                        PacketWrite(&pack, packet_write16, er->id);
                        PacketWrite(&pack, packet_writestr, er->nickname);

                        if (er->in_game)
                        {
                                PacketWrite(&pack, packet_write8, server->game.exe == er->id);
                                PacketWrite(&pack, packet_write8, server->game.exe == er->id ? er->exe_char : er->surv_char);
                        }
                        else
                        {
                                PacketWrite(&pack, packet_write8, er->lobby_icon);
                        }

                        RAssert(packet_send(v->peer, &pack, true));
                }
        }

        Info(LOG_YLW "Server is now in " LOG_PUR "Game");
        return true;
}

bool game_uninit(Server* server, bool show_results)
{
        if (show_results)
                return results_init(server);
        else
        {
                for (size_t i = 0; i < server->game.entities.capacity; i++)
                {
                        Entity* entity = (Entity*)server->game.entities.ptr[i];
                        if (!entity)
                                continue;

                        free(entity);
                }
                dylist_free(&server->game.entities);

                // Clean up after game
                for (size_t i = 0; i < server->game.left.capacity; i++)
                {
                        PeerData* data = (PeerData*)server->game.left.ptr[i];
                        if (!data)
                                continue;

                        free(data);
                }
                dylist_free(&server->game.left);

                return lobby_init(server);
        }
}

bool game_spawn(Server* server, Entity* entity, size_t len, Entity** out)
{
        entity->id = ++server->game.entid;
        Debug("Allocated entity \"%s\" (id %d, size %d)", entity->tag, entity->id, len);
        
        Entity* ent = (Entity*)malloc(len);
        if(!ent)
                return false;
         
        memcpy(ent, entity, len);
        if (ent->init && !ent->init(server, ent))
        {
                free(ent);
                return false;
        }
        
        dylist_push(&server->game.entities, ent);
        if (out)
                *out = ent;
        return true;
}

bool game_despawn(Server* server, Entity** out, uint16_t id)
{
        bool res = true;
        Entity* tar = NULL;

        for (size_t i = 0; i < server->game.entities.capacity; i++)
        {
                Entity* entity = (Entity*)server->game.entities.ptr[i];
                if (!entity)
                        continue;

                if (entity->id == id)
                {
                        if (entity->uninit && !entity->uninit(server, entity))
                                Warn("uninit failed for entity %d", entity->id);

                        Debug("Deallocated entity \"%s\" (id %d)", entity->tag, entity->id);
                        tar = entity;
                        break;
                }
        }

        res = dylist_remove(&server->game.entities, tar);
        if (res && !out)
                free(tar);
        else if (out)
                *out = tar;
        else
                Warn("Failed to find entity %d", id);

        return res;
}

int game_find(Server* server, Entity** out, char* tag, size_t count)
{
        int i = 0;

        for (size_t it = 0; it < server->game.entities.capacity; it++)
        {
                Entity* entity = (Entity*)server->game.entities.ptr[it];
                if (!entity)
                        continue;

                Debug("Search %s (id %d) vs %s", entity->tag, entity->id, tag);
                if (strcmp(entity->tag, tag) == 0)
                {
                        if (!out)
                                i++;
                        else
                                out[i++] = entity;

                        if ((size_t)i >= count)
                                break;
                }
        }

        Debug("Search for \"%s\" found %d entities", tag, i);
        return i;
}

bool game_bigring(Server* server, BigRingState state)
{
        RAssert(server);

        if (server->game.bring_state == state)
                return true;

        Packet packet;
        switch (state)
        {
                case BS_NONE:
                        break;

                case BS_DEACTIVATED:
                {
                        Info("Big ring is deactivated!");

                        PacketCreate(&packet, SERVER_GAME_SPAWN_RING);
                        PacketWrite(&packet, packet_write8, 0);
                        PacketWrite(&packet, packet_write8, server->game.bring_loc);
                        server_broadcast(server, &packet, true);
                        break;
                }

                case BS_ACTIVATED:
                {
                        Info("Big ring is activated!");

                        PacketCreate(&packet, SERVER_GAME_SPAWN_RING);
                        PacketWrite(&packet, packet_write8, 1);
                        PacketWrite(&packet, packet_write8, server->game.bring_loc);
                        server_broadcast(server, &packet, true);
                        break;
                }
        }

        server->game.bring_state = state;
        return true;
}

bool game_checkstart(Server* server)
{
        if (server->game.started)
                return true;

        uint8_t cnt = 0;
        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* v = (PeerData*)server->peers.ptr[i];
                if (!v)
                        continue;
                
                if(!v->in_game)
                        continue;

                if (v->plr.ready)
                        cnt++;
        }

        if (cnt >= server_ingame(server))
        {
                Packet pack;
                PacketCreate(&pack, SERVER_GAME_PLAYERS_READY);
                server_broadcast(server, &pack, true);

                srand((unsigned int)time(NULL));
                RAssert(g_mapList[server->game.map].cb.init(server));
                Info(LOG_YLW "Game started! " LOG_RST "(Time %ds)", server->game.time_sec);

                server->game.started = true;
        }

        return true;
}

bool game_demonize(Server* server, PeerData* data)
{
        Packet pack;
        PacketCreate(&pack, SERVER_GAME_DEATHTIMER_END);

        /* === AMY CANON / SALLY CANON / SONIC (reglas canonicas) ========
         * Ninguno de los tres JAMAS se convierte en exe/minion. Su
         * muerte real (la 2da caida, ya gastada su pasiva: burbuja de
         * secuestro, fase 2 o nervios de acero) la marca la rama de
         * CLIENT_PLAYER_DEATH_STATE como muerta directa y no llega
         * nunca hasta aqui. Este guard extra cubre cualquier otro
         * camino que los quiera demonizar, p. ej. el bloque de muerte
         * subita que demoniza a todos los PLAYER_DEAD. */
        /* v2: VANILLA tampoco se demoniza JAMAS (su 1ra caida es la
         * PACIENCIA y desde la 2da entra en MORIBUNDA sin avisar al
         * server; este guard cubre cualquier otro camino, p. ej. el
         * bloque de muerte subita). */
        if (data->surv_char == CH_AMY_CANON || data->surv_char == CH_SALLY_CANON || data->surv_char == CH_SONIC
            || data->surv_char == CH_VANILLA)
                return true;

        int players = 0;
        int demonized = 0;

        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* v = (PeerData*)server->peers.ptr[i];
                if (!v)
                        continue;
                
                if(!v->in_game)
                        continue;

                if (v->id == server->game.exe)
                        continue;
                
                if (v->plr.flags & PLAYER_DEMONIZED)
                        demonized++;

                players++;
        }

        if (players / 2 > demonized)
        {
                DEL_FLAG(data->plr.flags, PLAYER_DEAD);
                SET_FLAG(data->plr.flags, PLAYER_DEMONIZED);
                
                data->plr.stats.rings = 0;
                data->plr.dedemon_progress = 0; /* v2.11: rescate fresco al demonizarse */

                // reset cooldown (v2.1.3: POR JUGADOR, en el demonizado)
                switch (data->surv_char)
                {
                        case CH_TAILS:
                        {
                                data->plr_cooldowns[TAILS_RECHARGE] = 0;
                                data->plr_cooldowns[ETAILS_RECHARGE] = 0;
                                break;
                        }

                        case CH_EGGMAN:
                        {
                                data->plr_cooldowns[EGGTRACK_RECHARGE] = 0;
                                break;
                        }

                        case CH_CREAM:
                        case CH_VANILLA: /* Vanilla: mismas habilidades que Cream */
                        {
                                data->plr_cooldowns[CREAM_RING_SPAWN] = 0;
                                break;
                        }

                        /* v2.2 (TTB): cooldowns de los rescatados */
                        case CH_METAL:
                        case CH_AMELIA:
                        case CH_BLAZE:
                        {
                                data->plr_cooldowns[AMELIA_BANANA_SPAWN] = 0;
                                data->plr_cooldowns[AMELIA_TRAP_SPAWN] = 0;
                                data->plr_cooldowns[BLAZE_FIREBALL_SPAWN] = 0;
                                break;
                        }
                }

                Info("%s " LOG_RST "(id %d)" LOG_RED " was demonized!", data->nickname.value, data->id);
                PacketWrite(&pack, packet_write8, 1);
        }
        else
        {
                SET_FLAG(data->plr.flags, PLAYER_CANTREVIVE);

                Info("%s " LOG_RST "(id %d)" LOG_RED " died!", data->nickname.value, data->id);
                PacketWrite(&pack, packet_write8, 0);
        }

        RAssert(packet_send(data->peer, &pack, true));
        return true;
}

bool game_state_join(PeerData* v)
{
        (void)v; // dont fucking remember why this exists ~~

        /* v5.0 LMS: el SERVER_GAME_LMS fue un broadcast UNICO; quien entre
           o se reconecte a una partida ya avanzada se lo pierde. Re-enviarlo
           solo a este peer para que su cliente tambien viva el show (el
           reloj extendido ya le llega con el TIME_SYNC de siempre). */
        if (v->server->game.lms)
        {
                Packet packet;
                PacketCreate(&packet, SERVER_GAME_LMS);
                /* v5.3: el mismo personaje y la misma cancion que sono
                   al disparar el show. v5.3.1: +1 = numeracion
                   CHARACTER_* del cliente (igual que el broadcast). */
                PacketWrite(&packet, packet_write8, v->server->game.lms_char + 1);
                PacketWrite(&packet, packet_write8, v->server->game.lms_song);
                RAssert(packet_send(v->peer, &packet, true));
        }

        return true;
}

bool game_state_left(PeerData* v)
{
        if (v->server->game.end > 0)
                return true;

        if (!v->in_game)
                return true;

        RAssert(g_mapList[v->server->game.map].cb.left(v));

        if(server_ingame(v->server) <= 1)
                return game_uninit(v->server, false);

        if (!v->server->game.started)
        {
                if (v->id == v->server->game.exe)
                        return game_uninit(v->server, false);

                return game_checkstart(v->server);
        }

        PeerData* data = (PeerData*)malloc(sizeof(PeerData));
        RAssert(data);
        memcpy(data, v, sizeof(PeerData));

        // Add player to the list
        SET_FLAG(data->plr.flags, PLAYER_LEFT);
        dylist_push(&v->server->game.left, data);

        if (v->id == v->server->game.exe)
                return game_end(v->server, ED_SURVWIN, v->server->game.elapsed >= TICKSPERSEC * TICKSPERSEC);

        RAssert(game_state_check(v->server));
        return true;
}

bool game_state_handletcp(PeerData* v, Packet* packet)
{
        // Read header
        PacketRead(passtrough, packet, packet_read8, uint8_t);
        PacketRead(type, packet, packet_read8, uint8_t);
        
        switch (type)
        {
                default:
                        RAssert(server_msg_handle(v->server, type, v, packet));
                        break;
                        
                case CLIENT_PLAYER_POTATER:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        server_broadcast_ex(v->server, packet, true,  v->id);
                        break;
                }

                case CLIENT_SOUND_EMIT:
                {
                        AssertOrDisconnect(v->server, v->in_game);

                        /* v5.2 FIX "blud used a portal gun lmfao" (server-side,
                         * GENERICO — no depende del mapa, vale para los actuales
                         * y para cualquiera futuro): cuando un jugador cae en un
                         * pozo (obj_abyss) el cliente lo teletransporta al punto
                         * de retorno y SE HACE 20 DE DANO EN EL MISMO FRAME. Ese
                         * dano SIEMPRE viaja como sonido de dolor (snd_hurt) o de
                         * anillos perdidos (snd_ringlose) via net_sound_emit, para
                         * TODOS los personajes (exe incluido) y con o sin anillos.
                         * El server no simula pozos ni conoce la geometria de las
                         * salas, pero si puede ver esa senal y usarla como
                         * corroboracion de que el teleport fue mecanica del juego
                         * y no trampa. Indices = posicion en global.net_snds
                         * (scripts/net_sounds/net_sounds.gml); la convencion del
                         * proyecto es anadir sonidos NUEVOS solo AL FINAL del
                         * array, asi que 6 y 9 son estables. Leer nid/sndidx no
                         * rompe el rebroadcast: packet_send resetea pos=0 y envia
                         * buff[0..len] completo. */
                        PacketRead(nid, packet, packet_read16, uint16_t);
                        PacketRead(sndidx, packet, packet_read8, uint8_t);

                        if (nid == v->id && (sndidx == 6 /* snd_ringlose */ || sndidx == 9 /* snd_hurt */))
                        {
                                time_start(&v->plr.last_self_hurt);
                                v->plr.portal_pending = 0;
                        }

                        server_broadcast_ex(v->server, packet, true,  v->id);
                        break;
                }

                case CLIENT_SPAWN_EFFECT: 
                case CLIENT_PET_PALETTE:
                case CLIENT_SPRING_USE:
                case CLIENT_MERCOIN_BONUS:
                case CLIENT_RING_BROKE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        server_broadcast_ex(v->server, packet, true,  v->id);
                        break;
                }

                case CLIENT_PLAYER_PALETTE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, !g_config.anticheat || palette_player_validate(v, packet));
                        server_broadcast_ex(v->server, packet, true,  v->id);
                        break;
                }

                case CLIENT_PLAYER_HEAL_PART:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(rings, packet, packet_read16, uint16_t);
                        v->plr.heal_rings = v->plr.rings;

                        if (rings < 10)
                        {
                                server_disconnect(v->server, v->peer, DR_OTHER, "pusy");
                                return true;
                        }

                        if (rings >= 140 && v->server->game.map != 20)
                        {
                                server_disconnect(v->server, v->peer, DR_OTHER, "dicus");
                                return true;
                        }

                        server_broadcast_ex(v->server, packet, true, v->id);
                        break;
                }

                case CLIENT_PLAYER_HEAL:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(id, packet, packet_read16, uint16_t);
                        PacketRead(rings, packet, packet_read16, uint16_t);

                        if (rings < 10)
                        {
                                server_disconnect(v->server, v->peer, DR_OTHER, "pusy");
                                return true;
                        }

                        if (rings >= 140 && v->server->game.map != 20)
                        {
                                server_disconnect(v->server, v->peer, DR_OTHER, "dicus");
                                return true;
                        }

                        if (v->plr.mod_tool)
                        {
                                Packet pack;
                                PacketCreate(&pack, SERVER_RING_COLLECTED);
                                PacketWrite(&pack, packet_write8, 0);
                                PacketWrite(&pack, packet_write16, 0);
                                PacketWrite(&pack, packet_write8, true);
                                PacketWrite(&pack, packet_write8, false);
                                PacketWrite(&pack, packet_write8, 1); /* v1.2: byte worth (fake = 1) */
                                RAssert(packet_send(v->peer, &pack, true));
                                break;
                        }

                        v->plr.heal_rings = 0;
                        v->plr.stats.hp_restored++;

                        server_broadcast_ex(v->server, packet, true, v->id);
                        break;
                }

                case CLIENT_STATS_REPORT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(type, packet, packet_read8, uint8_t);

                        switch (type)
                        {
                                case 0:
                                {
                                        v->plr.stats.hp_restored++;
                                        break;
                                }

                                case 1:
                                {
                                        PacketRead(recv, packet, packet_read16, uint16_t);
                                        PacketRead(dmgr, packet, packet_read16, uint16_t);
                                        PacketRead(sec, packet, packet_read8, uint8_t);

                                        PeerData* rec = server_find_peer(v->server, recv);
                                        PeerData* damager = server_find_peer(v->server, dmgr);
                                        if (!rec || !damager)
                                                break;

                                        rec->plr.stats.stun_time += sec;
                                        damager->plr.stats.stuns++;
                                        break;
                                }

                                case 2:
                                {
                                        PacketRead(id, packet, packet_read16, uint16_t);
                                        PacketRead(dmg, packet, packet_read16, uint16_t);
                                        PacketRead(hp, packet, packet_read16, uint16_t);
                                        
                                        PeerData* data = server_find_peer(v->server, id);
                                        if (!data)
                                                break;

                                        if (hp <= 0)
                                                data->plr.stats.kills++;

                                        data->plr.stats.damage += dmg / 20;
                                        break;
                                }

                                case 3:
                                {
                                        PacketRead(dmg, packet, packet_read8, uint8_t);
                                        v->plr.stats.damage_taken += dmg / 20;

                                        /* v5.2 FIX "blud used a portal gun lmfao":
                                         * corroboracion por dano propio reportado.
                                         * El pozo hace exactamente 20; vale cualquier
                                         * golpe >= 20. Cubre al superviviente sin
                                         * anillos (con 10+ el golpe se absorbe y NO
                                         * hay reporte, pero entonces el snd_ringlose
                                         * del CLIENT_SOUND_EMIT si viaja) y cualquier
                                         * otro dano ambiente. */
                                        if (dmg >= 20)
                                        {
                                                time_start(&v->plr.last_self_hurt);
                                                v->plr.portal_pending = 0;
                                        }
                                        break;
                                }
                        }
                        break;
                }

                case CLIENT_PLAYER_HURT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        server_broadcast_ex(v->server, packet, true, v->id);
                        break;
                }

                case CLIENT_TPROJECTILE_STARTCHARGE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        time_start(&v->server->game.tails_last_proj);
                        break;
                }

                case CLIENT_TPROJECTILE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_TAILS);
                        AssertOrDisconnect(v->server, game_find(v->server, NULL, "tproj", 10) <= 2);

                        /* v2.1.3: cooldown POR JUGADOR (antes: global, con
                         * kick + mensaje). Con 2+ Tails en la partida, el
                         * 2.o en disparar dentro de la ventana era
                         * desconectado sin razon. Ahora se IGNORA el
                         * paquete (el laser no sale, sin kick): solo un
                         * cliente modificado puede topar con esto. */
                        int cooldown_id = v->plr.flags & PLAYER_DEMONIZED ? ETAILS_RECHARGE : TAILS_RECHARGE;
                        if (v->plr_cooldowns[cooldown_id] > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        PacketRead(dmg, packet, packet_read8, uint8_t);
                        PacketRead(exe, packet, packet_read8, uint8_t);
                        PacketRead(chg, packet, packet_read8, uint8_t);
                        AssertOrDisconnect(v->server, dir >= -1 && dir <= 1);

                        if (v->mod_tool)
                        {
                                if (dir > 0)
                                        dir = -1;
                                else if (dir < 0)
                                        dir = 1;
                        }

                        bool check_balls = true;
                        if (v->plr.flags & PLAYER_DEMONIZED)
                        {
                                AssertOrDisconnect(v->server, dmg <= 60);

                                if (dmg >= 60)
                                {
                                        double last = time_end(&v->server->game.tails_last_proj);
                                        check_balls = last > 1500 && last < 12000;
                                        AssertOrDisconnect(v->server, check_balls);
                                }
                        }
                        else
                        {
                                AssertOrDisconnect(v->server, dmg <= 6);

                                if (dmg >= 6)
                                {
                                        double last = time_end(&v->server->game.tails_last_proj);
                                        check_balls = last > 1500 && last < 12000;
                                        AssertOrDisconnect(v->server, check_balls);
                                }
                        }

                        if (!check_balls)
                                break;

                        RAssert(game_spawn(v->server, (Entity*)&(MakeTailsProj(x, y, v->id, dir, v->plr.flags & PLAYER_DEMONIZED, chg, dmg)), sizeof(TProjectile), NULL));
                        v->plr_cooldowns[cooldown_id] = 10 * TICKSPERSEC;
                        break;
                }

                case CLIENT_FWBOLT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_FLEETWAY_AMY);
                        /* v2.15 («La Torre»): cargador de 3 flechas — mantienen el
                         * tope de 3 vivas del server (<= 2 existentes permite el
                         * spawn de la 3.a). El CD por jugador baja a 0,5 s: el
                         * limite real lo pone la municion del cliente. */
                        AssertOrDisconnect(v->server, game_find(v->server, NULL, "fwbolt", 10) <= 2);

                        /* Cooldown por jugador (patron laser de Tails): sin
                         * kick, solo se ignora el paquete. v2.15: 0,5 s entre
                         * disparos (FW_ARROW_SHOT_CD del cliente). */
                        if (v->plr_cooldowns[FWBOLT_SPAWN] > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        PacketRead(dmg, packet, packet_read8, uint8_t);
                        AssertOrDisconnect(v->server, dir >= -1 && dir <= 1);
                        /* dmg 0 (stun) superviviente / 20 (daño) demonizada */
                        AssertOrDisconnect(v->server, dmg == 0 || dmg == 20);
                        AssertOrDisconnect(v->server, dmg == 0 || (v->plr.flags & PLAYER_DEMONIZED));

                        RAssert(game_spawn(v->server, (Entity*)&(MakeFwBolt(x, y, v->id, dir, dmg)), sizeof(FwBolt), NULL));
                        v->plr_cooldowns[FWBOLT_SPAWN] = TICKSPERSEC / 2;
                        break;
                }

                case CLIENT_FWBOLT_HIT:
                {
                        AssertOrDisconnect(v->server, v->in_game);

                        /* v2.15 («La Torre»): el reporte ahora lleva el id de la
                         * flecha y el tipo de contacto:
                         *   tipo 0 = se rompio (toco al exe / esbirro / limite)
                         *   tipo 1 = se CLAVO en un solido (x, y) -> plataforma */
                        PacketRead(fid, packet, packet_read16, uint16_t);
                        PacketRead(htype, packet, packet_read8, uint8_t);
                        AssertOrDisconnect(v->server, htype <= 1);

                        Entity* ent = NULL;
                        for (size_t i = 0; i < v->server->game.entities.capacity; i++)
                        {
                                Entity* e = (Entity*)v->server->game.entities.ptr[i];
                                if (!e)
                                        continue;

                                if (e->id == fid && strcmp(e->tag, "fwbolt") == 0)
                                {
                                        ent = e;
                                        break;
                                }
                        }

                        if (!ent)
                                break;

                        FwBolt* bolt = (FwBolt*)ent;

                        if (htype == 1)
                        {
                                /* Clavarse: deja de volar y queda FWBOLT_STICK_TIME
                                 * como plataforma. Los primeros reportes que lleguen
                                 * despues ya la encuentran clavada y se ignoran
                                 * (varios clientes ven el mismo choque). */
                                if (bolt->stuck)
                                        break;

                                PacketRead(hx, packet, packet_read16, uint16_t);
                                PacketRead(hy, packet, packet_read16, uint16_t);

                                bolt->stuck = true;
                                bolt->timer = FWBOLT_STICK_TIME;
                                bolt->pos.x = hx;
                                bolt->pos.y = hy;

                                Packet pack;
                                PacketCreate(&pack, SERVER_FWBOLT_STATE);
                                PacketWrite(&pack, packet_write8, 3);
                                PacketWrite(&pack, packet_write16, bolt->id);
                                PacketWrite(&pack, packet_write16, hx);
                                PacketWrite(&pack, packet_write16, hy);
                                server_broadcast(v->server, &pack, true);
                        }
                        else
                        {
                                /* Romperse (patron original): despawn para todos. */
                                game_despawn(v->server, NULL, ent->id);
                        }

                        break;
                }

                case CLIENT_TPROJECTILE_HIT:
                {
                        AssertOrDisconnect(v->server, v->in_game);

                        Entity* ents;
                        if (game_find(v->server, &ents, "tproj", 1))
                                game_despawn(v->server, NULL, ents->id);

                        break;
                }

                /* Sonic parry: el laser del lado EXE fue parreado. Se invierte
                   (exe=0, direccion al reves, dano capado a 3) y se rebroadcastea
                   como _state 3: a partir de ahi es un ataque del lado de los
                   sobrevivientes y aturde al EXE/esbirro que toque (rama que ya
                   existe en el cliente). Idempotente: solo aplica si exe==1, asi
                   que varios clientes pidiendolo a la vez no rompen nada. */
                case CLIENT_TPROJECTILE_DEFLECT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);

                        Entity* ents;
                        if (game_find(v->server, &ents, "tproj", 1))
                        {
                                TProjectile* tproj = (TProjectile*)ents;

                                if (tproj->exe)
                                {
                                        tproj->exe = 0;
                                        tproj->damage = 3;

                                        if (tproj->dir > 0)
                                                tproj->dir = -1;
                                        else if (tproj->dir < 0)
                                                tproj->dir = 1;

                                        Packet pack;
                                        PacketCreate(&pack, SERVER_TPROJECTILE_STATE);
                                        PacketWrite(&pack, packet_write8, 3);
                                        PacketWrite(&pack, packet_write8, tproj->dir);
                                        server_broadcast(v->server, &pack, true);
                                }
                        }

                        break;
                }

                case CLIENT_RING_COLLECTED:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(id, packet, packet_read8, uint8_t);
                        PacketRead(eid, packet, packet_read16, uint16_t);

                        Ring* ent = NULL;
                        bool res = game_despawn(v->server, (Entity**)&ent, eid);
                        if (res)
                        {
                                PeerData* data = server_find_peer(v->server, v->id);
                                RAssert(data);

                                if (!ent->red)
                                {
                                        time_start(&data->plr.last_rings);
                                        data->plr.rings += ent->worth;
                                        data->plr.stats.rings += ent->worth;
                                }

                                Packet pack;
                                PacketCreate(&pack, SERVER_RING_COLLECTED);
                                PacketWrite(&pack, packet_write8, id);
                                PacketWrite(&pack, packet_write16, eid);
                                PacketWrite(&pack, packet_write8, ent->red);
                                PacketWrite(&pack, packet_write8, data->plr.rings > 0);
                                PacketWrite(&pack, packet_write8, ent->worth); /* v1.2 */

                                free(ent);
                                RAssert(packet_send(v->peer, &pack, true));
                        }
                        break;
                }

                case CLIENT_CREAM_SPAWN_RINGS:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        /* Vanilla usa las mismas habilidades que Cream:
                           el paquete de anillos tambien es valido para ella.
                           v2.13 «Sol y Luna»: tambien para Amy Canon —
                           su SOL gotea 1 ring cada 7 s por este mismo
                           camino (ver scr_amy_canon_special). */
                        AssertOrDisconnect(v->server, v->surv_char == CH_CREAM || v->surv_char == CH_VANILLA || v->surv_char == CH_AMY_CANON);
                        /* v2.1.3: cooldown POR JUGADOR (antes: GLOBAL a
                         * toda la partida). Vanilla y Cream soltando
                         * anillos casi a la vez reventaban este assert y el
                         * server desconectaba al 2.o (crash del cliente en
                         * net_tcpprocess). Ahora: si ESTE jugador la uso
                         * hace poco, se ignora el paquete (sin spawn, sin
                         * kick). */
                        if (v->plr_cooldowns[CREAM_RING_SPAWN] > 0)
                                break;

                        if (v->mod_tool)
                        {
                                Packet pack;
                                PacketCreate(&pack, SERVER_RING_COLLECTED);
                                PacketWrite(&pack, packet_write8, 0);
                                PacketWrite(&pack, packet_write16, 0);
                                PacketWrite(&pack, packet_write8, true);
                                PacketWrite(&pack, packet_write8, false);
                                PacketWrite(&pack, packet_write8, 1); /* v1.2: byte worth (fake = 1) */
                                RAssert(packet_send(v->peer, &pack, true));
                                break;
                        }

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(red_ring, packet, packet_read8, uint8_t);

                        Vector2 pos = { (float)x, (float)y };
                        AssertOrDisconnect(v->server, vector2_dist(&pos, &v->plr.pos) <= 40);

                        static double PI = 0.0;
                        if(PI == 0.0) 
                                PI = acos(-1);

                        /* v2.13 «Sol y Luna»: el SOL de Amy Canon gotea
                         * 1 SOLO anillo (worth 1) cada 7 s — la economia
                         * del duo, no un flood. red_ring se ignora para
                         * ella: nunca se demoniza (la burbuja lo fuerza),
                         * asi que un byte true solo puede venir de un
                         * cliente hackeado. */
                        if (v->surv_char == CH_AMY_CANON)
                        {
                                RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(x, y, false, 1)), sizeof(CreamRing), NULL));
                        }
                        else if (red_ring)
                        {                               
                                CreamRing* rings[128];
                                int cnt = game_find(v->server, (Entity**)rings, "cring", 128);
                                
                                for(int i = 0; i < cnt; i++)
                                {
                                        CreamRing* ring = rings[i];
                                        if(!ring->red)
                                                continue;

                                        AssertOrDisconnect(v->server, vector2_dist(&ring->pos, &pos) >= 150);
                                }
                                
                                uint16_t posX[2] = { 25, -27 };
                                uint16_t posY[2] = { 0, 0 };
                                for (int i = 0; i < 2; i++)
                                {
                                        uint16_t rX = x + posX[i];
                                        uint16_t rY = y + posY[i];

                                        RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(rX, rY, red_ring, 1)), sizeof(CreamRing), NULL));
                                }
                        }
                        else
                        {
                                /* v2: los anillos de VANILLA valen 4 al recogerlos y los de
                                 * CREAM valen 2 si hay una Vanilla en la partida (pasiva
                                 * "Inspiracion de una madre": la presencia de su madre
                                 * inspira a Cream). */
                                int cream_worth = 1;
                                for (size_t p = 0; p < v->server->peers.capacity; p++)
                                {
                                        PeerData* vp = (PeerData*)v->server->peers.ptr[p];

                                        if (vp == NULL || !vp->in_game)
                                                continue;

                                        if (vp->surv_char == CH_VANILLA)
                                        {
                                                cream_worth = 2;
                                                break;
                                        }
                                }

                                uint16_t posX[3] = { 26, 0, -27 };
                                uint16_t posY[3] = { 0, -26, 0 };
                                for (int i = 0; i < 3; i++)
                                {
                                        uint16_t rX = x + posX[i];
                                        uint16_t rY = y + posY[i];

                                        RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(rX, rY, red_ring, v->surv_char == CH_VANILLA ? 4 : cream_worth)), sizeof(CreamRing), NULL));
                                }
                        }

                        /* v2.1.3: POR JUGADOR y 10 s = la recarga de
                         * cliente mas corta (EVANILLA_RINGS_RECHARGE,
                         * Vanilla demonizada), para que un jugador legitimo
                         * jamas tope con este limite: solo frena el spam.
                         * v2.13 «Sol y Luna»: el goteo legitimo del SOL de
                         * Amy Canon es cada 7 s — su suelo baja a 6 s
                         * (margen de jitter de red/frame pacing); el de
                         * Cream/Vanilla sigue en 10 s. */
                        v->plr_cooldowns[CREAM_RING_SPAWN] = (v->surv_char == CH_AMY_CANON ? 6 : 10) * TICKSPERSEC;
                        break;
                }

                case CLIENT_VANILLA_DEDEMONIZE:
                {
                        /* VANILLA V2: con 15 anillos le quita la demonizacion a un
                         * esbirro ATURDIDO que este a su alcance. La valida el
                         * cliente de Vanilla (stun + anillos + distancia); aqui se
                         * re-valida el estado del objetivo con los datos del server
                         * y se limpia el flag PLAYER_DEMONIZED (sin esto, la
                         * siguiente caida del jugador lo desconectaria por el
                         * AssertOrDisconnect de CLIENT_PLAYER_DEATH_STATE). Al
                         * marcarlo PLAYER_REVIVED, su siguiente caida lo
                         * re-demoniza directo: "1 caida mas para demonizarse". */
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->surv_char == CH_VANILLA);

                        PacketRead(pid, packet, packet_read16, uint16_t);

                        PeerData* target = server_find_peer(v->server, pid);

                        if (target == NULL)
                                break;

                        if (target == v || !target->in_game)
                                break;

                        if (!(target->plr.flags & PLAYER_DEMONIZED))
                                break;

                        if (vector2_dist(&target->plr.pos, &v->plr.pos) > 150)
                                break;

                        DEL_FLAG(target->plr.flags, PLAYER_DEMONIZED);
                        SET_FLAG(target->plr.flags, PLAYER_REVIVED);
                        target->plr.dedemon_progress = 0;

                        Packet pack;
                        PacketCreate(&pack, SERVER_VANILLA_DEDEMONIZE);
                        PacketWrite(&pack, packet_write16, target->id);
                        server_broadcast(v->server, &pack, true);

                        Info("%s (id %d) de-demonized by Vanilla!", target->nickname.value, target->id);
                        break;
                }

                case CLIENT_VANILLA_DEDEMONIZE_PROGRESS:
                {
                        /* v2.11 — RESCATE DE ESBIRRO "como revivir a un
                         * caido": Vanilla mantiene ABAJO sobre un esbirro
                         * ATURDIDO (su estado por red es DEAD; lo valida su
                         * cliente en scr_survivor_revive, igual que el revive
                         * normal valida el PLAYER_DEAD) con 15+ anillos.
                         * Mismo patron que CLIENT_REVIVAL_PROGRESS: el
                         * progreso vive AQUI (plr.dedemon_progress y se
                         * CONSERVA si suelta el boton a mitad, como la barra
                         * del caido), la barra es la misma
                         * (SERVER_REVIVAL_PROGRESS + SERVER_REVIVAL_STATUS)
                         * y al llenarse hace exactamente lo del
                         * CLIENT_VANILLA_DEDEMONIZE de arriba: limpiar
                         * PLAYER_DEMONIZED + marcar PLAYER_REVIVED ("a 1
                         * caida de re-demonizarse"). Los 15 anillos los
                         * cobra el cliente de Vanilla al recibir el
                         * SERVER_VANILLA_DEDEMONIZE (lock dedemonTarget). */
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_VANILLA);

                        if (v->server->game.end > 0)
                                break;

                        PacketRead(pid, packet, packet_read16, uint16_t);
                        PacketRead(rings, packet, packet_read8, uint8_t);

                        PeerData* target = server_find_peer(v->server, pid);

                        if (target == NULL)
                                break;

                        if (target == v || !target->in_game)
                                break;

                        if (!(target->plr.flags & PLAYER_DEMONIZED))
                                break;

                        if (rings < 15)
                                break;

                        /* misma tolerancia de distancia que el handler
                         * instantaneo de la v2 (tocando al esbirro) */
                        if (vector2_dist(&target->plr.pos, &v->plr.pos) > 150)
                                break;

                        Packet pack;

                        if (target->plr.dedemon_progress <= 0)
                        {
                                /* misma senal que abre la barra del revive normal */
                                PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                                PacketWrite(&pack, packet_write8, 1);
                                PacketWrite(&pack, packet_write16, target->id);
                                server_broadcast(v->server, &pack, true);
                        }

                        /* base 0.03 por paquete (30 paq/s = ~1.1 s, cabe
                         * comodo en el stun de 3.5 s de Chocola) + bonus
                         * por anillos de sobra (tope +25, como el revive
                         * del caido acelera con anillos) */
                        {
                                int bonus = rings - 15;

                                if (bonus > 25)
                                        bonus = 25;

                                target->plr.dedemon_progress += 0.03 + 0.002 * bonus;
                        }

                        if (target->plr.dedemon_progress < 1)
                        {
                                PacketCreate(&pack, SERVER_REVIVAL_PROGRESS);
                                PacketWrite(&pack, packet_write16, target->id);
                                PacketWrite(&pack, packet_writedouble, target->plr.dedemon_progress);
                                server_broadcast(v->server, &pack, false);
                                break;
                        }

                        /* completado: rescate! mismo efecto que el handler
                         * instantaneo + cerrar la barra del revive */
                        target->plr.dedemon_progress = 0;
                        DEL_FLAG(target->plr.flags, PLAYER_DEMONIZED);
                        SET_FLAG(target->plr.flags, PLAYER_REVIVED);

                        PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                        PacketWrite(&pack, packet_write8, 0);
                        PacketWrite(&pack, packet_write16, target->id);
                        server_broadcast(v->server, &pack, true);

                        PacketCreate(&pack, SERVER_VANILLA_DEDEMONIZE);
                        PacketWrite(&pack, packet_write16, target->id);
                        server_broadcast(v->server, &pack, true);

                        Info("%s (id %d) rescued from demonization by Vanilla!", target->nickname.value, target->id);
                        break;
                }


                /* ============================================================
                 *  v2.2 (TTB) — habilidades de los personajes rescatados
                 * ============================================================ */
                case CLIENT_AMELIA_BANANA:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_AMELIA);

                        /* cooldown POR JUGADOR (patron v2.1.3): ignorar, sin kick */
                        if (v->plr_cooldowns[AMELIA_BANANA_SPAWN] > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);

                        RAssert(game_spawn(v->server, (Entity*)&(MakeAmeliaBanana(x, y, v->id)), sizeof(AmeliaBanana), NULL));
                        v->plr_cooldowns[AMELIA_BANANA_SPAWN] = 10 * TICKSPERSEC;
                        break;
                }

                case CLIENT_AMELIA_TRAP:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_AMELIA);

                        /* cooldown POR JUGADOR (patron v2.1.3): ignorar,
                           sin kick. v2.8: 15 s = la recarga legitima mas
                           rapida del cliente (EAMELIA_TRAP_RECHARGE de la
                           Amelia demonizada; la superviviente tarda 35 s),
                           para que el server JAMAS se coma en silencio una
                           colocacion que el cliente ya cobro con su
                           recarga (30 s viejos bloqueaban a la demonizada
                           cada 2.a trampa). */
                        if (v->plr_cooldowns[AMELIA_TRAP_SPAWN] > 0)
                                break;

                        /* v2.8: SIN limite de trampas vivas. El chequeo
                           "max 1 viva por Amelia" de v2.4 rompia la
                           mecanica: la trampa vive 60 s y la recarga es
                           de 35 s (15 s demonizada), asi que TODA
                           colocacion entre los 35 y los 60 s llegaba
                           aqui, pasaba el cooldown y se descartaba sin
                           avisar (el cliente ya habia gastado la recarga
                           y sonado el spawn). Ahora cada colocacion
                           spawnea su propia entidad con id unico; el
                           ritmo real lo marca la recarga del cliente y
                           este cooldown anti-spam. */
                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);

                        RAssert(game_spawn(v->server, (Entity*)&(MakeAmeliaTrap(x, y, v->id)), sizeof(AmeliaTrap), NULL));
                        v->plr_cooldowns[AMELIA_TRAP_SPAWN] = 15 * TICKSPERSEC;
                        break;
                }

                case CLIENT_AMELIA_TRAP_TRIGGER:
                {
                        /* la piso alguien del lado del EXE (killer o
                           demonizado): su cliente ya aplico el stun (3 s) y
                           el slow (3.5 s tras el stun) sobre su propio
                           jugador; aqui solo queda reventarla YA con state 2
                           para que todo el mundo vea el efecto a la vez.
                           v3.0: la trampa CAMBIA DE BANDO con su duena —
                           si Amelia se demonizo, sus trampas las pisan los
                           SUPERVIVIENTES (el cliente de la victima ya
                           filtro la ceguera: ellos solo stun + slow). Se
                           localiza la trampa ANTES del assert para conocer
                           a su duena (owner). */
                        AssertOrDisconnect(v->server, v->in_game);

                        PacketRead(nid, packet, packet_read16, uint16_t);

                        Entity* target = NULL;
                        for (size_t it = 0; it < v->server->game.entities.capacity; it++)
                        {
                                Entity* ent = (Entity*)v->server->game.entities.ptr[it];

                                if (ent && strcmp(ent->tag, "atrap") == 0 && ent->id == nid)
                                {
                                        target = ent;
                                        break;
                                }
                        }

                        bool owner_demon = false;
                        if (target)
                        {
                                PeerData* owner = server_find_peer(v->server, ((AmeliaTrap*)target)->owner);
                                if (owner)
                                        owner_demon = (owner->plr.flags & PLAYER_DEMONIZED) != 0;
                        }

                        AssertOrDisconnect(v->server, v->id == v->server->game.exe || (v->plr.flags & PLAYER_DEMONIZED) || owner_demon);

                        if (target)
                        {
                                bool was_upgraded = ((AmeliaTrap*)target)->upgraded;
                                bool victim_exe_side = (v->id == v->server->game.exe) || (v->plr.flags & PLAYER_DEMONIZED);

                                amelia_trap_trigger(v->server, target);

                                /* v3.0 («Genio Malvado»): si la trampa estaba
                                   MEJORADA y la victima es del bando EXE,
                                   ejecuta el RASTREADOR (lo que suele hacer
                                   el sensor de Eggman): la posicion de la
                                   victima se revela a TODOS los
                                   supervivientes durante 3 s
                                   (SERVER_TRACKER_PING + obj_surv_indicator
                                   en el cliente). Solo pasa si Eggman la
                                   mejoro. */
                                if (was_upgraded && victim_exe_side)
                                {
                                        Packet pack;
                                        PacketCreate(&pack, SERVER_TRACKER_PING);
                                        PacketWrite(&pack, packet_write16, v->id);
                                        server_broadcast(v->server, &pack, true);
                                }

                                game_despawn(v->server, NULL, target->id);
                        }

                        break;
                }

                case CLIENT_EGG_TRAP_UPGRADE_PROGRESS:
                {
                        /* v3.1 («Genio Malvado», estilo RESCATE de Vanilla
                           v2.11): Eggman ENCIMA de la trampa manteniendo
                           ABAJO con anillos de sobra. Mismo patron que
                           CLIENT_VANILLA_DEDEMONIZE_PROGRESS: el progreso
                           vive AQUI (ent.upg_progress y se CONSERVA si
                           suelta el boton a mitad, como la barra del
                           caido), la barra es la misma del revive
                           (SERVER_EGG_UPGRADE_PROGRESS + STATUS) y al
                           llenarla hace lo que hacia el instantaneo de la
                           v3.0: cobrar 3/5 anillos (plr.rings, contador
                           del server) y marcar la entidad mejorada
                           (SERVER_ETRACKER_STATE 2 / SERVER_AMELIA_TRAP_
                           STATE 3). El pago LOCAL del cliente lo hace el
                           handler de esos states con el lock geniusTarget
                           (patron dedemonTarget). Sin kick ante datos
                           raros: se ignora en silencio (patron cooldowns),
                           salvo no ser Eggman / no estar en partida. */
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_EGGMAN);
                        AssertOrDisconnect(v->server, !(v->plr.flags & PLAYER_DEMONIZED));

                        if (v->server->game.end > 0)
                                break;

                        PacketRead(type, packet, packet_read8, uint8_t);
                        PacketRead(nid, packet, packet_read16, uint16_t);
                        PacketRead(rings, packet, packet_read8, uint8_t);

                        AssertOrDisconnect(v->server, type <= 1);

                        int cost = (type == 1) ? 5 : 3;

                        if (rings < (uint8_t)cost)
                                break;

                        if (v->plr.rings < (uint16_t)cost)
                                break;

                        Entity* ents[50];
                        int found = game_find(v->server, ents, (char*)(type == 1 ? "atrap" : "eggtrack"), 50);

                        for (int i = 0; i < found; i++)
                        {
                                Entity* ent = ents[i];

                                if (ent->id != nid)
                                        continue;

                                bool* upgraded;
                                double* progress;

                                if (type == 1)
                                {
                                        AmeliaTrap* trap = (AmeliaTrap*)ent;

                                        if (trap->upgraded || trap->triggered)
                                                break;

                                        upgraded = &trap->upgraded;
                                        progress = &trap->upg_progress;
                                }
                                else
                                {
                                        EggTracker* egg = (EggTracker*)ent;

                                        if (egg->upgraded)
                                                break;

                                        upgraded = &egg->upgraded;
                                        progress = &egg->upg_progress;
                                }

                                /* misma tolerancia del rescate de Vanilla
                                   (tocando la trampa; el cliente manda a
                                   <= 42 px de la entidad) */
                                if (vector2_dist(&ent->pos, &v->plr.pos) > 150)
                                        break;

                                Packet pack;

                                if (*progress <= 0)
                                {
                                        /* misma senal que abre la barra del
                                           revive normal */
                                        PacketCreate(&pack, SERVER_EGG_UPGRADE_STATUS);
                                        PacketWrite(&pack, packet_write8, 1);
                                        PacketWrite(&pack, packet_write8, type);
                                        PacketWrite(&pack, packet_write16, ent->id);
                                        server_broadcast(v->server, &pack, true);
                                }

                                /* base 0.03 por paquete (30 paq/s = ~1.1 s)
                                   + bonus por anillos de sobra (tope +25,
                                   como el revive del caido acelera con
                                   anillos) */
                                {
                                        int bonus = rings - cost;

                                        if (bonus > 25)
                                                bonus = 25;

                                        *progress += 0.03 + 0.002 * bonus;
                                }

                                if (*progress < 1)
                                {
                                        PacketCreate(&pack, SERVER_EGG_UPGRADE_PROGRESS);
                                        PacketWrite(&pack, packet_write8, type);
                                        PacketWrite(&pack, packet_write16, ent->id);
                                        PacketWrite(&pack, packet_writedouble, *progress);
                                        server_broadcast(v->server, &pack, false);
                                        break;
                                }

                                /* completado: cobrar y DORAR (mismo efecto
                                   que el instantaneo v3.0 + cerrar la
                                   barra) */
                                *progress = 0;
                                *upgraded = true;
                                v->plr.rings -= cost;

                                PacketCreate(&pack, SERVER_EGG_UPGRADE_STATUS);
                                PacketWrite(&pack, packet_write8, 0);
                                PacketWrite(&pack, packet_write8, type);
                                PacketWrite(&pack, packet_write16, ent->id);
                                server_broadcast(v->server, &pack, true);

                                if (type == 1)
                                {
                                        PacketCreate(&pack, SERVER_AMELIA_TRAP_STATE);
                                        PacketWrite(&pack, packet_write8, 3);
                                        PacketWrite(&pack, packet_write16, ent->id);
                                        PacketWrite(&pack, packet_write16, (uint16_t)ent->pos.x);
                                        PacketWrite(&pack, packet_write16, (uint16_t)ent->pos.y);
                                        server_broadcast(v->server, &pack, true);
                                }
                                else
                                {
                                        PacketCreate(&pack, SERVER_ETRACKER_STATE);
                                        PacketWrite(&pack, packet_write8, 2);
                                        PacketWrite(&pack, packet_write16, ent->id);
                                        PacketWrite(&pack, packet_write16, (uint16_t)ent->pos.x);
                                        PacketWrite(&pack, packet_write16, (uint16_t)ent->pos.y);
                                        server_broadcast(v->server, &pack, true);
                                }

                                Info("Eggman (id %d) upgraded %s %d!", v->id, type == 1 ? "Amelia trap" : "eggtrack", ent->id);
                                break;
                        }

                        break;
                }

                case CLIENT_BLAZE_FIREBALL:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_BLAZE);

                        /* v2.9: cooldown anti-spam 4 s = EBLAZE_FIREBALL_
                           RECHARGE (la recarga legitima mas rapida del
                           cliente; la normal es 9 s), para que el server
                           JAMAS se coma en silencio un disparo que el
                           cliente ya cobro con su recarga (los 8 s viejos
                           bloqueaban a la demonizada cada 2.a bola). */
                        if (v->plr_cooldowns[BLAZE_FIREBALL_SPAWN] > 0)
                                break;

                        /* v2.9: SIN limite de bolas vivas (patron v2.8 de
                           la trampa): cada disparo spawnea su entidad con
                           nid unico. El limite global de v2.2 hacia que
                           dos Blazes se robaran la bola entre ellas (la
                           2.a se descartaba en silencio) y la vida de 4 s
                           ya limita la densidad por jugadora. */

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        AssertOrDisconnect(v->server, dir >= -1 && dir <= 1);

                        RAssert(game_spawn(v->server, (Entity*)&(MakeBlazeFireball(x, y, v->id, dir)), sizeof(BlazeFireball), NULL));
                        v->plr_cooldowns[BLAZE_FIREBALL_SPAWN] = 4 * TICKSPERSEC;
                        break;
                }

                case CLIENT_BLAZE_FIREBALL_HIT:
                {
                        /* v2.9: la bola aturdio al jugador LOCAL del que
                           reporta (su cliente ya aplico el stun): solo
                           despawnea ESA bola (nid), no la primera que
                           encuentre como hacia v2.2. */
                        AssertOrDisconnect(v->server, v->in_game);

                        PacketRead(nid, packet, packet_read16, uint16_t);

                        for (size_t it = 0; it < v->server->game.entities.capacity; it++)
                        {
                                Entity* ent = (Entity*)v->server->game.entities.ptr[it];

                                if (ent && strcmp(ent->tag, "bfire") == 0 && ent->id == nid)
                                {
                                        game_despawn(v->server, NULL, ent->id);
                                        break;
                                }
                        }

                        break;
                }

                case CLIENT_BLAZE_FIREBALL_BOUNCE:
                {
                        /* v2.9: la bola REBOTA. El server no tiene la
                           colision del mapa: cualquier cliente que vea
                           el choque reporta cual bola (nid), que
                           componentes de velocidad invertir (flip) y en
                           que posicion estaba el primer solape. Todos
                           los clientes ven el mismo choque casi al mismo
                           tiempo: el primero gana y el lockout de la
                           entidad ignora los duplicados. */
                        AssertOrDisconnect(v->server, v->in_game);

                        PacketRead(nid, packet, packet_read16, uint16_t);
                        PacketRead(flip, packet, packet_read8, uint8_t);
                        AssertOrDisconnect(v->server, flip >= 1 && flip <= 3);
                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);

                        for (size_t it = 0; it < v->server->game.entities.capacity; it++)
                        {
                                Entity* ent = (Entity*)v->server->game.entities.ptr[it];

                                if (ent && strcmp(ent->tag, "bfire") == 0 && ent->id == nid)
                                {
                                        bfire_bounce(v->server, ent, flip, x, y);
                                        break;
                                }
                        }

                        break;
                }

                /* v1 JINNA (D.I.B.): teletransporte hacia el superviviente
                 * mas cercano. La jugadora YA se movio en su cliente
                 * (killers cliente-autoritativos): aqui solo se valida el
                 * cooldown, se abre el grace del anticheat (ex_teleport,
                 * mismo que el tele de Exeller a su clon) y se replican los
                 * DOS portales (salida = ultima pos conocida del server,
                 * llegada = la del paquete) a todos los clientes. */
                case CLIENT_JINNA_TELEPORT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_JINNA);

                        if (v->plr_cooldowns[JINNA_TELEPORT] > 0)
                                break;

                        PacketRead(tx, packet, packet_read16, uint16_t);
                        PacketRead(ty, packet, packet_read16, uint16_t);

                        uint16_t ox = (uint16_t)v->plr.pos.x;
                        uint16_t oy = (uint16_t)v->plr.pos.y;

                        Packet pack;
                        PacketCreate(&pack, SERVER_JINNA_PORTAL_STATE);
                        PacketWrite(&pack, packet_write16, (uint16_t)v->id);
                        PacketWrite(&pack, packet_write16, ox);
                        PacketWrite(&pack, packet_write16, oy);
                        PacketWrite(&pack, packet_write16, tx);
                        PacketWrite(&pack, packet_write16, ty);
                        server_broadcast(v->server, &pack, true);

                        /* v3 — RAFAGA DEL TELETRANSPORTE: todos los
                         * supervivientes VIVOS dentro de un radio de 90 px
                         * de la llegada quedan ralentizados 3 s (el slow
                         * lo aplica el cliente de cada victima sobre su
                         * propio jugador al recibir SERVER_JINNA_TELE_AOE;
                         * 4,5 s si Jinna ya atrapo a Vanilla). El server
                         * computa el area con las posiciones que ya
                         * sincroniza: nada de confiar en la lista de la
                         * cliente. */
                        #define JINNA_TELE_SLOW_RANGE 90.0f
                        for (size_t it = 0; it < v->server->peers.capacity; it++)
                        {
                                PeerData* surv = (PeerData*)v->server->peers.ptr[it];
                                if (!surv || !surv->in_game)
                                        continue;
                                if (surv->id == v->server->game.exe)
                                        continue;
                                if (surv->plr.flags & (PLAYER_DEAD | PLAYER_ESCAPED | PLAYER_DEMONIZED))
                                        continue;

                                float sdx = surv->plr.pos.x - (float)tx;
                                float sdy = surv->plr.pos.y - (float)ty;
                                if (sdx * sdx + sdy * sdy > JINNA_TELE_SLOW_RANGE * JINNA_TELE_SLOW_RANGE)
                                        continue;

                                Packet slow;
                                PacketCreate(&slow, SERVER_JINNA_TELE_AOE);
                                PacketWrite(&slow, packet_write16, surv->id);
                                server_broadcast(v->server, &slow, true);
                        }

                        v->plr_cooldowns[JINNA_TELEPORT] = 8 * TICKSPERSEC;
                        v->plr.ex_teleport = 60;
                        break;
                }

                /* v1 JINNA: agarre. Valida (exe + cooldown + que la victima
                 * este en la partida y viva) y reenvia a todos: la victima
                 * se congela y sufre el dano EN SU cliente (la autoridad de
                 * su propio jugador, mismo lado que el stun), el resto
                 * crea el efecto visual sobre su puppet. */
                case CLIENT_JINNA_GRAB:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_JINNA);

                        if (v->plr_cooldowns[JINNA_GRAB] > 0)
                                break;

                        PacketRead(pid, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        AssertOrDisconnect(v->server, dir >= -1 && dir <= 1);

                        PeerData* victim = server_find_peer(v->server, pid);
                        AssertOrDisconnect(v->server, victim != NULL);
                        AssertOrDisconnect(v->server, victim->in_game);
                        AssertOrDisconnect(v->server, victim->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, !(victim->plr.flags & (PLAYER_DEAD | PLAYER_ESCAPED | PLAYER_DEMONIZED)));

                        Packet pack2;
                        PacketCreate(&pack2, SERVER_JINNA_GRAB_STATE);
                        PacketWrite(&pack2, packet_write16, pid);
                        PacketWrite(&pack2, packet_write8, (int8_t)dir);
                        server_broadcast(v->server, &pack2, true);

                        v->plr_cooldowns[JINNA_GRAB] = 12 * TICKSPERSEC;
                        break;
                }

                /* v3/v4 (D.I.B.) JINNA: PORTAL TRAMPA (tecla V+ABAJO). La
                 * jugadora la planta en sus pies; aqui se valida (exe +
                 * Jinna + recarga PROPIA de la trampa — v4: ya NO comparte
                 * la del agarre, cada modo de la V tiene su cooldown) y se
                 * spawnea la entidad JinnaTrap (20 s de vida), que se
                 * replica sola a todos con SERVER_JINNA_TRAP_STATE 0. */
                case CLIENT_JINNA_TRAP:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_JINNA);

                        if (v->plr_cooldowns[JINNA_TRAP] > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);

                        RAssert(game_spawn(v->server, (Entity*)&(MakeJinnaTrap(x, y, v->id)), sizeof(JinnaTrap), NULL));
                        v->plr_cooldowns[JINNA_TRAP] = 15 * TICKSPERSEC;
                        break;
                }

                /* v3/v4 (D.I.B.) JINNA: alguien piso el PORTAL TRAMPA. El
                 * aviso llega DESDE el cliente de la victima (cada cliente
                 * es la autoridad de su propio jugador). Se valida: el
                 * reportero ES la victima (superviviente vivo), la trampa
                 * existe y el esta encima (radio anti-reporte-remoto). Se
                 * consume la trampa (state 2 a todos) y se emite
                 * SERVER_JINNA_TRAP_HIT (pid, kind, jx, jy) con la posicion
                 * ACTUAL de Jinna: la victima aplica dano + teletransporte
                 * en SU cliente (SIN i-frames: si los tenia, el dano entra
                 * igual y se le remueven). kind 1 = VANILLA: absorcion a
                 * la otra dimension (fuera de juego + potenciacion fuerte).
                 * kind 2 = AMY CANON (v4): misma absorcion, pero su cliente
                 * la dibuja con su pose de secuestro y la potenciacion es
                 * la "ardua" (la mitad de los aumentos). */
                case CLIENT_JINNA_TRAP_HIT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, !(v->plr.flags & (PLAYER_DEAD | PLAYER_ESCAPED | PLAYER_DEMONIZED)));

                        PacketRead(tid, packet, packet_read16, uint16_t);
                        PacketRead(pid, packet, packet_read16, uint16_t);
                        AssertOrDisconnect(v->server, v->id == pid);

                        Entity* target = NULL;
                        for (size_t it = 0; it < v->server->game.entities.capacity; it++)
                        {
                                Entity* ent = (Entity*)v->server->game.entities.ptr[it];

                                if (ent && strcmp(ent->tag, "jtrap") == 0 && ent->id == tid)
                                {
                                        target = ent;
                                        break;
                                }
                        }

                        if (!target)
                                break; /* ya consumida, expirada o paquete repetido */

                        /* anti-reporte remoto: la victima tiene que estar
                         * ENCIMA de la trampa (64 px de tolerancia por la
                         * latencia del estado de posicion) */
                        float rdx = v->plr.pos.x - target->pos.x;
                        float rdy = v->plr.pos.y - target->pos.y;
                        if (rdx * rdx + rdy * rdy > 64.0f * 64.0f)
                                break;

                        /* a donde cae la victima: la posicion ACTUAL de Jinna */
                        PeerData* exe = server_find_peer(v->server, v->server->game.exe);
                        if (!exe || !exe->in_game)
                        {
                                game_despawn(v->server, NULL, target->id);
                                break;
                        }

                        uint8_t kind = 0;
                        if (v->surv_char == CH_VANILLA)
                                kind = 1;
                        else if (v->surv_char == CH_AMY_CANON) /* v4: Amy Canon tambien es absorbida (spr_amy_capture_canon) */
                                kind = 2;

                        jinna_trap_trigger(v->server, target);
                        game_despawn(v->server, NULL, target->id);

                        Packet pack3;
                        PacketCreate(&pack3, SERVER_JINNA_TRAP_HIT);
                        PacketWrite(&pack3, packet_write16, pid);
                        PacketWrite(&pack3, packet_write8, kind);
                        PacketWrite(&pack3, packet_write16, (uint16_t)exe->plr.pos.x);
                        PacketWrite(&pack3, packet_write16, (uint16_t)exe->plr.pos.y);
                        server_broadcast(v->server, &pack3, true);
                        break;
                }

                case CLIENT_METALAMY_BULLET:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_METALAMY);

                        if (v->plr_cooldowns[METALAMY_BULLET] > 0)
                                break;

                        if (game_find(v->server, NULL, "mabul", 1) > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        AssertOrDisconnect(v->server, dir >= -1 && dir <= 1);

                        RAssert(game_spawn(v->server, (Entity*)&(MakeMetalAmyBullet(x, y, v->id, dir)), sizeof(MetalAmyBullet), NULL));
                        v->plr_cooldowns[METALAMY_BULLET] = 0 * TICKSPERSEC;
                        break;
                }

                case CLIENT_METALAMY_BULLET_HIT:
                {
                        AssertOrDisconnect(v->server, v->in_game);

                        Entity* ents;
                        if (game_find(v->server, &ents, "mabul", 1))
                                game_despawn(v->server, NULL, ents->id);

                        break;
                }
                case CLIENT_ETRACKER:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, v->surv_char == CH_EGGMAN);
                        /* v2.1.3: cooldown POR JUGADOR (antes: global; con
                         * 2+ Eggman en la partida, el 2.o rastreador dentro
                         * de la ventana desconectaba a su dueno). Ignorar
                         * el paquete, sin kick. */
                        if (v->plr_cooldowns[EGGTRACK_RECHARGE] > 0)
                                break;
                        
                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        
                        game_spawn(v->server, (Entity*)&(MakeEggTrack(x, y)), sizeof(EggTracker), NULL);
                        v->plr_cooldowns[EGGTRACK_RECHARGE] = 10 * TICKSPERSEC; 
                        break;
                }

                case CLIENT_ETRACKER_ACTIVATED:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        PacketRead(eid, packet, packet_read16, uint16_t);
                        
                        Entity* ents[50];
                        int found = game_find(v->server, ents, "eggtrack", 50);

                        for (int i = 0; i < found; i++)
                        {
                                EggTracker* entity = (EggTracker*)ents[i];
                                
                                if (entity->id == eid)
                                {
                                        entity->activ_id = v->id;
                                        game_despawn(v->server, NULL, eid);
                                        break;
                                }
                        }

                        break;
                }

                case CLIENT_ERECTOR_BRING_SPAWN:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_EXETIOR);
                        /* v2.1.3: cooldown POR JUGADOR (el Exetior es unico:
                         * mismo comportamiento que antes, ahora por jugador) */
                        if (v->plr_cooldowns[EXETIOR_BRING_SPAWN] > 0)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);

                        if (v->mod_tool)
                        {
                                RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(x, y, false, 1)), sizeof(CreamRing), NULL));
                                break;
                        }

                        BRing* rings[128];
                        int cnt = game_find(v->server, (Entity**)rings, "bring", 128);
                        
                        Vector2 pos = { x, y };
                        for(int i = 0; i < cnt; i++)
                        {
                                BRing* ring = rings[i];
                                AssertOrDisconnect(v->server, vector2_dist(&ring->pos, &pos) >= 100);
                        }
                        
                        game_spawn(v->server, (Entity*)(&(MakeBlackRing(x, y))), sizeof(BRing), NULL);
                        v->plr_cooldowns[EXETIOR_BRING_SPAWN] = 6.5 * TICKSPERSEC;
                        break;
                }

                case CLIENT_BRING_COLLECTED:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        PacketRead(eid, packet, packet_read16, uint16_t);

                        if (game_despawn(v->server, NULL, eid))
                        {
                                Packet pack;
                                PacketCreate(&pack, SERVER_BRING_COLLECTED);
                                packet_send(v->peer, &pack, true);
                        }
                        break;
                }

                /* Sonic parry: el anillo negro de Exetior fue parreado. Se
                   quita el anillo negro (bring_uninit avisa a los clientes) y
                   en el mismo sitio aparece un anillo REAL (cring_init hace el
                   broadcast del SERVER_RING_STATE _state 2): dorado, recogible
                   con el flujo normal de siempre (+1 anillo incluido), nunca
                   la trampa de los -5 anillos. */
                case CLIENT_BRING_DEFLECT:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        PacketRead(eid, packet, packet_read16, uint16_t);

                        Entity* brings[128];
                        int cnt = game_find(v->server, (Entity**)brings, "bring", 128);

                        for (int i = 0; i < cnt; i++)
                        {
                                if (brings[i]->id != eid)
                                        continue;

                                float bx = brings[i]->pos.x;
                                float by = brings[i]->pos.y;

                                if (game_despawn(v->server, NULL, eid))
                                        RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(bx, by, false, 1)), sizeof(CreamRing), NULL));

                                break;
                        }
                        break;
                }

                case CLIENT_ERECTOR_BALLS:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);

                        PacketRead(x, packet, packet_readfloat, float);
                        PacketRead(y, packet, packet_readfloat, float);

                        if(!v->mod_tool) 
                        {
                                Packet pack;
                                PacketCreate(&pack, CLIENT_ERECTOR_BALLS);
                                PacketWrite(&pack, packet_writefloat, x);
                                PacketWrite(&pack, packet_writefloat, y);
                                server_broadcast(v->server, &pack, true);
                        }
                        else
                        {
                                for(int i = -3; i < 3; i++)
                                {
                                        RAssert(game_spawn(v->server, (Entity*)&(MakeCreamRing(x + i * 8, y, false, 1)), sizeof(CreamRing), NULL));
                                }
                        }

                        break;
                }

                case CLIENT_EXELLER_SPAWN_CLONE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_EXELLER);
                        AssertOrDisconnect(v->server, game_find(v->server, NULL, "exclone", 3) < 2);

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(dir, packet, packet_read8, int8_t);
                        game_spawn(v->server, (Entity*)&(MakeExellerClone(x, y, dir, v->id)), sizeof(ExellerClone), NULL);
                        break;
                }

                case CLIENT_EXELLER_TELEPORT_CLONE:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id == v->server->game.exe);
                        AssertOrDisconnect(v->server, v->exe_char == EX_EXELLER);
                        
                        PacketRead(eid, packet, packet_read16, uint16_t);

                        ExellerClone* clone;
                        if (game_despawn(v->server, (Entity**)&clone, eid))
                        {
                                if (v->mod_tool)
                                {
                                        Packet pack;
                                        PacketCreate(&pack, SERVER_EXELLERCLONE_STATE);
                                        PacketWrite(&pack, packet_write8, 0);
                                        PacketWrite(&pack, packet_write16, clone->id);
                                        PacketWrite(&pack, packet_write16, clone->owner);
                                        PacketWrite(&pack, packet_write16, (uint16_t)v->plr.pos.x);
                                        PacketWrite(&pack, packet_write16, (uint16_t)v->plr.pos.y);
                                        PacketWrite(&pack, packet_write8, clone->dir);
                                        RAssert(packet_send(v->peer, &pack, true));
                                        free(clone);
                                        break;
                                }

                                Packet pack;
                                PacketCreate(&pack, SERVER_EXELLERCLONE_STATE);
                                PacketWrite(&pack, packet_write8, 1);
                                PacketWrite(&pack, packet_write16, clone->id);
                                server_broadcast(v->server, &pack, true);

                                free(clone);
                                v->plr.ex_teleport = 60;
                        }
                        break; 
                }

                case CLIENT_PLAYER_ESCAPED:
                {
                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);

                        if (v->mod_tool)
                        {
                                RAssert(server_disconnect(v->server, v->peer, DR_SERVERTIMEOUT, NULL));
                                break;
                        }

                        if (v->plr.flags & PLAYER_DEAD || v->plr.flags & PLAYER_DEMONIZED)
                                break;

                        if (v->plr.flags & PLAYER_ESCAPED)
                                break;

                        SET_FLAG(v->plr.flags, PLAYER_ESCAPED);

                        Packet pack;
                        PacketCreate(&pack, SERVER_PLAYER_ESCAPED);
                        RAssert(packet_send(v->peer, &pack, true));

                        PacketCreate(&pack, SERVER_GAME_PLAYER_ESCAPED);
                        PacketWrite(&pack, packet_write16, v->id);
                        server_broadcast(v->server, &pack, true);

                        RAssert(game_state_check(v->server));
                        break;
                }

                case CLIENT_PLAYER_DEATH_STATE:
                {
                        if (v->server->game.end > 0)
                                break;

                        AssertOrDisconnect(v->server, v->in_game);
                        AssertOrDisconnect(v->server, v->id != v->server->game.exe);
                        AssertOrDisconnect(v->server, !(v->plr.flags & PLAYER_DEMONIZED));

                        PacketRead(dead, packet, packet_read8, uint8_t);
                        PacketRead(rtimes, packet, packet_read8, uint8_t);

                        Packet pack;
                        PacketCreate(&pack, SERVER_PLAYER_DEATH_STATE);
                        PacketWrite(&pack, packet_write16, v->id);
                        PacketWrite(&pack, packet_write8, dead);
                        PacketWrite(&pack, packet_write8, rtimes);
                        server_broadcast(v->server, &pack, true);

                        PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                        PacketWrite(&pack, packet_write8, false)
                        PacketWrite(&pack, packet_write16, v->id);
                        server_broadcast(v->server, &pack, true);

                        if (dead)
                        {
                                if (v->plr.flags & PLAYER_DEAD || v->plr.flags & PLAYER_ESCAPED)
                                        break;

                                SET_FLAG(v->plr.flags, PLAYER_DEAD);

                                /* === AMY CANON (reglas canonicas) =====================
                                 * Su 1ra caida NUNCA llega a este paquete: el cliente la
                                 * encierra en la burbuja de secuestro (spr_amy_capture_canon
                                 * + amy_Bubble), por lo que el servidor no la marca como
                                 * muerta -> la partida NO termina mientras este secuestrada
                                 * (aunque sea la ultima con vida) y la muerte subita tampoco
                                 * puede tocarla (solo demoniza a los PLAYER_DEAD).
                                 * Su muerte real (2da caida) es directa: muerta sin agonia,
                                 * sin timer de 30s y sin poder revivir. JAMAS se demoniza. */
                                /* AMY CANON / SALLY CANON / SONIC: muerte
                                 * directa (sin agonia, sin timer de 30s, sin
                                 * poder revivir). JAMAS se demonizan. */
                                /* v2: VANILLA muere directa igual que los canon (solo
                                 * posible desde un cliente viejo sin el patch: el v2 jamas
                                 * reporta sus caidas). JAMAS se demoniza. */
                                if (v->surv_char == CH_AMY_CANON || v->surv_char == CH_SALLY_CANON || v->surv_char == CH_SONIC
                                    || v->surv_char == CH_VANILLA)
                                {
                                        SET_FLAG(v->plr.flags, PLAYER_CANTREVIVE);
                                        v->plr.death_timer_sec = 0;
                                        v->plr.death_timer = 0;
                                        RAssert(game_state_check(v->server));
                                        break;
                                }

                                if (v->plr.flags & PLAYER_REVIVED || v->server->game.time_sec < TICKSPERSEC * 2)
                                {
                                        RAssert(game_demonize(v->server, v));
                                }
                                else
                                {
                                        PeerData* exe = server_find_peer(v->server, v->server->game.exe);
                                        v->plr.death_timer_sec = 30;

                                        PacketCreate(&pack, SERVER_GAME_DEATHTIMER_TICK);
                                        PacketWrite(&pack, packet_write8, exe && vector2_dist(&v->plr.pos, &exe->plr.pos) <= 240);
                                        PacketWrite(&pack, packet_write16, v->id);
                                        PacketWrite(&pack, packet_write8, v->plr.death_timer_sec);
                                        server_broadcast(v->server, &pack, true);
                                }
                        }
                        else
                        {
                                AssertOrDisconnect(v->server, v->plr.death_timer_sec > 0);
                                DEL_FLAG(v->plr.flags, PLAYER_DEAD);
                        }

                        RAssert(game_state_check(v->server));
                        break;
                }

                case CLIENT_REVIVAL_PROGRESS:
                {
                        if (v->server->game.end > 0)
                                break;

                        PacketRead(pid, packet, packet_read16, uint16_t);
                        PacketRead(rings, packet, packet_read8, uint8_t);

                        PeerData* to_revive = server_find_peer(v->server, pid);
                        AssertOrDisconnect(v->server, to_revive);

                        if (!to_revive || !(to_revive->plr.flags & PLAYER_DEAD))
                                break;

                        Packet pack;
                        if (to_revive->plr.flags & PLAYER_CANTREVIVE)
                        {
                                to_revive->plr.death_timer_sec = 0;
                                to_revive->plr.death_timer = 0;

                                PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                                PacketWrite(&pack, packet_write8, 0);
                                PacketWrite(&pack, packet_write16, to_revive->id);
                                server_broadcast(v->server, &pack, true);
                                break;
                        }

                        if (to_revive->plr.revival <= 0)
                        {
                                PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                                PacketWrite(&pack, packet_write8, 1);
                                PacketWrite(&pack, packet_write16, to_revive->id);
                                server_broadcast(v->server, &pack, true);
                        }

                        to_revive->plr.revival += 0.015 + (0.004 * rings);
                        if (to_revive->plr.revival < 1)
                        {
                                PacketCreate(&pack, SERVER_REVIVAL_PROGRESS);
                                PacketWrite(&pack, packet_write16, to_revive->id);
                                PacketWrite(&pack, packet_writedouble, to_revive->plr.revival);
                                server_broadcast(v->server, &pack, false);

                                // add itself to the list
                                {
                                        bool has = false;
                                        int ind = 0;

                                        for (int i = 0; i < 5; i++)
                                        {
                                                if (to_revive->plr.revival_init[i] == -1)
                                                {
                                                        ind = i;
                                                        break;
                                                }

                                                if (to_revive->plr.revival_init[i] == v->id)
                                                        has = true;
                                        }

                                        if (!has)
                                                to_revive->plr.revival_init[ind] = v->id;
                                }
                        }
                        else
                        {
                                to_revive->plr.stats.rings = 0;

                                SET_FLAG(to_revive->plr.flags, PLAYER_REVIVED);
                                DEL_FLAG(to_revive->plr.flags, PLAYER_DEAD);

                                PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                                PacketWrite(&pack, packet_write8, 0);
                                PacketWrite(&pack, packet_write16, to_revive->id);
                                server_broadcast(v->server, &pack, true);

                                PacketCreate(&pack, SERVER_REVIVAL_REVIVED);
                                packet_send(to_revive->peer, &pack, true);

                                for (int i = 0; i < 5; i++)
                                {
                                        if (to_revive->plr.revival_init[i] == -1)
                                                break;

                                        PeerData* data = server_find_peer(v->server, to_revive->plr.revival_init[i]);
                                        if(!data)
                                                continue;
                                        
                                        PacketCreate(&pack, SERVER_REVIVAL_RINGSUB);
                                        packet_send(data->peer, &pack, true);

                                        Debug("Removed rings from %d", to_revive->plr.revival_init[i]);
                                }

                                // Print player's name
                                Info("%s " LOG_RST "(id %d)" LOG_GRN " was revived!", to_revive->nickname.value, to_revive->id);
                        }
                        break;
                }

                case CLIENT_CHAT_MESSAGE:
                {
                        /* [v1.2 IN-GAME CHAT] Antes: `if (v->in_game) break;`
                           bloqueaba el chat a los jugadores DENTRO de la
                           ronda (solo hablaban los de la sala de espera).
                           Ahora los SUPERVIVIENTES chatean entre ellos:
                             - el EXE no envia ni recibe chat en partida
                             - el emisor no recibe su propio mensaje (el
                               cliente ya pinta el eco local al enviar)
                             - la sala de espera conserva su canal propio
                               (emisor y destinatarios del mismo lado) */
                        v->timeout = 0;

                        PacketRead(pid, packet, packet_read16, uint16_t);
                        PacketRead(msg, packet, packet_readstr, String);
                        /* 48: tope del HUD del cliente (obj_game_chat/Step);
                           antes 40, y un mensaje de 41-48 desconectaba al
                           jugador por este assert */
                        AssertOrDisconnect(v->server, string_length(&msg) <= 48);

                        Info("%s " LOG_RST "(id %d): %s", v->nickname.value, v->id, msg.value);

                        if (server_cmd_handle(v->server, server_cmd_parse(&msg), v, &msg))
                                break;

                        if (!g_config.chatfix)
                                break;

                        /* el EXE no usa el chat (por ahora) */
                        if (v->id == v->server->game.exe)
                                break;

                        Packet pack;
                        PacketCreate(&pack, CLIENT_CHAT_MESSAGE);
                        PacketWrite(&pack, packet_write16, v->id);
                        PacketWrite(&pack, packet_writestr, msg);

                        for (size_t i = 0; i < v->server->peers.capacity; i++)
                        {
                                PeerData* w = (PeerData*)v->server->peers.ptr[i];
                                if (!w)
                                        continue;

                                if (w->id == v->id)
                                        continue; /* eco local en el cliente */

                                if (w->id == v->server->game.exe)
                                        continue; /* el EXE no ve el chat */

                                if (w->in_game != v->in_game)
                                        continue; /* partida vs sala de espera */

                                if (!packet_send(w->peer, &pack, true))
                                        server_disconnect(v->server, w->peer, DR_SERVERTIMEOUT, NULL);
                        }

                        break;
                }
                
                case CLIENT_PING:
                {
                        if (!v->server->game.started)
                                break;

                        if (v->plr.mod_tool)
                        {
                                if (v->server->game.time_sec <= TICKSPERSEC * 2 + 5)
                                        break;
                        }

                        Packet pack;
                        PacketCreate(&pack, SERVER_PONG);
                        PacketWrite(&pack, packet_write16, v->peer->roundTripTime);
                        packet_send(v->peer, &pack, false);
                        v->plr.ping_last = v->peer->roundTripTime;

                        PacketCreate(&pack, SERVER_GAME_PING);
                        PacketWrite(&pack, packet_write16, v->id);
                        PacketWrite(&pack, packet_write16, v->peer->roundTripTime);
                        server_broadcast_ex(v->server, &pack, false, v->id);
                        break;
                }

                case CLIENT_PLAYER_DATA:
                {
                        if (!v->server->game.started)
                                break;

                        PacketRead(x, packet, packet_read16, uint16_t);
                        PacketRead(y, packet, packet_read16, uint16_t);
                        PacketRead(_xspd, packet, packet_read16, uint16_t);
                        PacketRead(_yspd, packet, packet_read16, uint16_t);
                        
                        PacketRead(state, packet, packet_read8, uint8_t);
                        PacketRead(_angle, packet, packet_read16, int16_t);
                        PacketRead(_index, packet, packet_read8, uint8_t);
                        PacketRead(_xscale, packet, packet_read8, int8_t);

                        Vector2 new_pos = { x, y };
                        #define PLAYER_ATTACKING 1 << 4
                        
                        int duration = 2000;
                        if(v->server->game.exe != v->id)
                        {
                                PacketRead(hp, packet, packet_read8, int8_t);
                                PacketRead(revival, packet, packet_read8, uint8_t);
                                PacketRead(rings, packet, packet_read16, int16_t);
                                PacketRead(flags, packet, packet_read8, uint8_t);

                                if(!(v->plr.flags & PLAYER_DEAD) && !(v->plr.flags & PLAYER_DEMONIZED))
                                {
                                        if (v->server->game.exe != v->id)
                                        {
                                                v->plr.rings = rings;
                                                if (revival < 2)
                                                {
                                                        if (rings < 0 || (v->server->game.map != 20 && rings >= 120))
                                                        {
                                                                server_disconnect(v->server, v->peer, DR_OTHER, "gomunkulus");
                                                                return true;
                                                        }

                                                        if (hp > 100)
                                                        {
                                                                server_disconnect(v->server, v->peer, DR_OTHER, "garic forn — Сьогодні о 04:31");
                                                                return true;
                                                        }
                                                }
                                        }
                                }

                                v->plr.is_attacking = flags & PLAYER_ATTACKING;
                                switch(v->surv_char)
                                {
                                        case CH_EGGMAN:
                                        {
                                                duration = 3000;
                                                break;
                                        }

                                        /* Amy Canon (LSA v6.x): el rayo lleva el bit
                                           PLAYER_ATTACKING TODO el vuelo (hasta
                                           LSA_MAX_TIME = 300 frames = 5 s a 60 fps)
                                           para el stun por contacto del kit. Sin esta
                                           excepcion el anticheat generico (2 s de
                                           ataque continuo) la bota con "nuh-uh!" a
                                           mitad de vuelo. Mismo mecanismo que la
                                           excepcion de Eggman: subir el tepe, no
                                           apagar el anticheat. 6000 ms cubre el
                                           vuelo maximo (5000) con margen. */
                                        case CH_AMY_CANON:
                                        {
                                                duration = 6000;
                                                break;
                                        }
                                }
                        }
                        else
                        {
                                PacketRead(flags, packet, packet_read8, uint8_t);
                                v->plr.is_attacking = flags & PLAYER_ATTACKING;
                                //      if (v->server->game.map == 20) // Exception for a specific map
                                //      {
                                //      switch (v->exe_char) // Use it if your new exe has a long attack.
                                //      {
                                //              case EX_EXETIOR:
                                //                      duration = 3000;
                                //                      break;
                                //              }
                                //      }
                        }

                        if(v->server->game.end <= 0 && v->plr.is_attacking)
                        {
                                if(v->plr.attack_timer <= 0)
                                {
                                        time_start(&v->plr.last_attack);
                                        v->plr.attack_timer = 1;
                                }
                                else
                                {
                                        double elapsed = time_end(&v->plr.last_attack);
                                        v->plr.attack_timer += elapsed;
                                        if(v->plr.attack_timer >= duration)
                                        {
                                                server_disconnect(v->server, v->peer, DR_KICKEDBYHOST, "nuh-uh!");
                                                return true;
                                        }
                                        time_start(&v->plr.last_attack);
                                }
                        }
                        else
                                v->plr.attack_timer = 0;
                        
                        // ping limit disabled
                        if(g_config.ping_limit == UINT16_MAX)
                        {
                                // Calc distance before setting new posx
                                float dist = vector2_dist(&v->plr.pos, &new_pos);
                                if (v->server->game.started && !v->plr.mod_tool && v->plr.pos.x != 0 && v->plr.pos.y != 0)
                                {
                                        if (v->plr.ex_teleport == 0)
                                        {
                                                /* v5.2 FIX "blud used a portal gun lmfao"
                                                 * (server-side, GENERICO: cualquier mapa
                                                 * actual o futuro): los saltos >700px
                                                 * LEGITIMOS del juego (pozos de obj_abyss
                                                 * y caidas por debajo de la sala) van
                                                 * SIEMPRE acompanados de dano propio en el
                                                 * mismo frame (scr_player_hurt(20,0,0)), y
                                                 * ese dano llega al server como
                                                 * CLIENT_STATS_REPORT(3) y/o
                                                 * CLIENT_SOUND_EMIT(snd_hurt/snd_ringlose).
                                                 * Con corroboracion reciente (ventana de 3 s:
                                                 * cubre los i-frames de hasta 3 s, durante
                                                 * los que el pozo teleporta sin sonido ni
                                                 * dano) el salto se PERDONA. Sin ella, el
                                                 * kick se DIFIERE 1.5 s (portal_pending)
                                                 * porque la senal de dano viaja por TCP y
                                                 * puede llegar DESPUES del paquete UDP de
                                                 * posicion. Un segundo salto grande sin
                                                 * corroborar mientras hay uno pendiente =
                                                 * trampa: kick inmediato. La exencion de los
                                                 * mapas 15/13/8/6 se CONSERVA (warps
                                                 * legitimos SIN dano de los mapas
                                                 * originales). */
                                                bool corroborated = v->plr.last_self_hurt != 0.0 && time_end(&v->plr.last_self_hurt) <= 3000.0;

                                                if (dist > 700)
                                                {
                                                        switch (v->server->game.map)
                                                        {
                                                                case 15:
                                                                case 13:
                                                                case 8:
                                                                case 6:
                                                                        break;

                                                        default:
                                                                        if (corroborated)
                                                                                break;

                                                                        if (v->plr.portal_pending > 0)
                                                                        {
                                                                                server_disconnect(v->server, v->peer, DR_OTHER, "blud used a portal gun lmfao");
                                                                                return true;
                                                                        }

                                                                        /* sin corroborar TODAVIA: kick diferido
                                                                         * (expira en game_player_tick) */
                                                                        v->plr.portal_pending = 1.5 * TICKSPERSEC;
                                                                        break;
                                                        }
                                                }

                                                /* El error de "dial-up" (dist > 60) no se
                                                 * acumula mientras el salto esta pendiente
                                                 * de corroborar ni cuando ya esta
                                                 * corroborado: una caida legitima al pozo
                                                 * no es "lag". */
                                                if (dist > 60 && !corroborated && v->plr.portal_pending <= 0)
                                                {
                                                        if (!player_add_error(v->server, v, 500))
                                                                return true;
                                                }
                                        }
                                        else
                                                v->plr.ex_teleport--;
                                }
                        }
                        
                        v->plr.pos = new_pos;
                        v->plr.timeout = 0;

                        if (v->plr.mod_tool)
                        {
                                if (v->plr.mod_tool_timer < 61)
                                        v->plr.mod_tool_timer++;
                                else
                                {
                                        float dist = vector2_dist(&v->plr.pos, &v->plr.start_pos);
                                        if (dist > 240)
                                        {
                                                Packet pack;
                                                PacketCreate(&pack, SERVER_PLAYER_BACKTRACK);
                                                PacketWrite(&pack, packet_writefloat, v->plr.start_pos.x);
                                                PacketWrite(&pack, packet_writefloat, v->plr.start_pos.y);
                                                packet_send(v->peer, &pack, true);
                                        }
                                        else if (dist >= 300)
                                        {
                                                // purpl men
                                                server_disconnect(v->server, v->peer, DR_OTHER,
                                                        "@@@@@@@......@@@\n"
                                                        "@@@@@@@......@@@\n"
                                                        "@@@@@@@.......@@\n"
                                                        "@@@@@@@@@@@@....\n"
                                                        "@@@@@@@@@@......\n"
                                                        "....@@..........\n"
                                                        "................\n"
                                                        "@@@@@@@@@@@@....\n"
                                                        "@@@@@@@@@@@@....\n"
                                                        "@@@@@@@@@@@@@...\n"
                                                        "@@@@@@@@@@@@@...\n"
                                                        "@@@@@@@@@@@....."
                                                );
                                        }
                                        break;
                                }

                                if (v->plr.mod_tool_timer == 60)
                                {
                                        v->plr.start_pos = v->plr.pos;

                                        Packet pack;
                                        PacketCreate(&pack, SERVER_FELLA);
                                        PacketWrite(&pack, packet_write16, v->id);
                                        PacketWrite(&pack, packet_writefloat, v->plr.start_pos.x);
                                        PacketWrite(&pack, packet_writefloat, v->plr.start_pos.y);
                                        server_broadcast(v->server, &pack, true);
                                        break;
                                }
                        }

                        if(v->plr.state != state || time_end(&v->plr.last_packet) >= 15 * 2.9)
                        {
                                v->plr.state = state;
                                time_start(&v->plr.last_packet);

                                Packet pack;
                                PacketCreate(&pack, CLIENT_PLAYER_DATA);
                                PacketWrite(&pack, packet_write16, v->id);

                                RAssert(packet_seek(packet, 2));
                                while (packet->pos < packet->len)
                                {
                                        PacketRead(i, packet, packet_read8, uint8_t);
                                        PacketWrite(&pack, packet_write8, i);
                                }

                                server_broadcast_ex(v->server, &pack, false, v->id);
                        }
                        break;
                }
        }

        if (!v->server->game.started)
        {
                if(!v->plr.ready)
                {
                        time_start(&v->plr.last_packet);
                        v->plr.ready = true;
                }

                RAssert(game_checkstart(v->server));
                return true;
        }

        RAssert(packet_seek(packet, 0));
        RAssert(g_mapList[v->server->game.map].cb.tcp_msg(v, packet));
        return true;
}

bool game_entity_tick(Server* server)
{
        int32_t entits[100];
        int entit = 0;

        for(int i = 0; i < 100; i++)
                entits[i] = -1;

        for (size_t i = 0; i < server->game.entities.capacity; i++)
        {
                Entity* ent = (Entity*)server->game.entities.ptr[i];
                if (!ent)
                        continue;

                if (ent->tick && !ent->tick(server, ent))
                        entits[entit++] = ent->id;
        }

        for (int i = 0; i < 100; i++)
        {
                if (entits[i] == -1)
                        break;

                game_despawn(server, NULL, (uint16_t)entits[i]);
        }

        return true;
}

bool game_player_tick(Server* server)
{
        /* Update cooldowns (v2.1.3: POR JUGADOR) */
        for (size_t p = 0; p < server->peers.capacity; p++)
        {
                PeerData* data = (PeerData*)server->peers.ptr[p];
                if (!data)
                        continue;

                for (int i = 0; i < PLAYER_COOLCOUNT; i++)
                {
                        if (data->plr_cooldowns[i] > 0)
                                data->plr_cooldowns[i] -= server->delta;
                        else
                                data->plr_cooldowns[i] = 0;
                }
        }
        
        PeerData* exe = server_find_peer(server, server->game.exe);
        if(!exe)
                return true;

        bool exe_camp = false;
        int survivors = 0, demonized = 0;

        for(size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* data = (PeerData*)server->peers.ptr[i];
                if (!data)
                        continue;

                if(!data->in_game)
                        continue;

                player_check_zone(server, data);

                /* v5.2 FIX "blud used a portal gun lmfao": expiracion del kick
                 * diferido. Si en 1.5 s no llego ninguna senal de dano propio
                 * (CLIENT_STATS_REPORT(3) / snd_hurt / snd_ringlose) que
                 * justifique el salto >700px, era un teleport de verdad:
                 * desconectar con el mismo mensaje de siempre. A un jugador
                 * muerto no se le expira nada (no hay nada que corroborar). */
                if (data->plr.portal_pending > 0)
                {
                        if (data->plr.flags & PLAYER_DEAD)
                                data->plr.portal_pending = 0;
                        else
                        {
                                data->plr.portal_pending -= server->delta;
                                if (data->plr.portal_pending <= 0)
                                {
                                        data->plr.portal_pending = 0;
                                        server_disconnect(server, data->peer, DR_OTHER, "blud used a portal gun lmfao");
                                        continue;
                                }
                        }
                }

                // ping check
                if (server->delta < 2.5)
                {
                        data->plr.ping_timer += server->delta;
                        data->plr.ping_total += data->plr.ping_last * server->delta;

                        if (data->plr.ping_timer >= 20 * TICKSPERSEC)
                        {
                                double avg_ping = data->plr.ping_total / data->plr.ping_timer;
                                if (avg_ping >= g_config.ping_limit)
                                {
                                        char msg[130];
                                        snprintf(msg, 130, "Bad connection, try picking closest region for better experience!\nYour average ping for last 20s: %dms", (int)avg_ping);
                                        server_disconnect(server, data->peer, DR_OTHER, msg);
                                        continue;
                                }

                                data->plr.ping_total = 0;
                                data->plr.ping_timer = 0;
                        }
                }

                if((data->plr.flags & PLAYER_DEAD) && !(data->plr.flags & PLAYER_CANTREVIVE) && vector2_dist(&exe->plr.pos, &data->plr.pos) < 300)
                        exe_camp = true;

                if (exe->id != data->id && !(data->plr.flags & PLAYER_DEAD) && !(data->plr.flags & PLAYER_DEMONIZED))
                {
                        // calc danger time
                        if (!(data->plr.flags & PLAYER_ESCAPED))
                        {
                                bool in_danger = exe && vector2_dist(&data->plr.pos, &exe->plr.pos) < 300;
                                if (in_danger)
                                        data->plr.stats.danger_time += server->delta;
                                
                                if(server->game.map != 8 && server->game.map != 6)
                                {
                                        // calc balls
                                        uint32_t chunk = ((uint32_t)data->plr.pos.x / 480) + ((uint32_t)data->plr.pos.y / 270);
                                        if (data->plr.chunk != chunk)
                                        {
                                                data->plr.stats.braindead_time = 0;
                                                data->plr.chunk = chunk;
                                        }
                                        else
                                        {
                                                data->plr.stats.braindead_time += server->delta * (in_danger ? 0.5 : 1);
                                                if (data->plr.stats.braindead_time >= 25 * TICKSPERSEC)
                                                        data->plr.stats.brain_damage = true;
                                        }
                                }
                        }

                        data->plr.stats.survive_time += server->delta;
                }
                
                // subpussy revival time
                if(data->plr.flags & PLAYER_DEAD && !(data->plr.flags & PLAYER_CANTREVIVE))
                {
                        if(data->plr.revival > 0)
                        {
                                data->plr.revival -= 0.0025 * server->delta;
                                
                                Packet pack;
                                if(data->plr.revival <= 0)
                                {
                                        for(int i = 0; i < 5; i++)
                                                data->plr.revival_init[i] = -1;

                                        PacketCreate(&pack, SERVER_REVIVAL_STATUS);
                                        PacketWrite(&pack, packet_write8, 0);
                                        PacketWrite(&pack, packet_write16, data->id);
                                        server_broadcast(server, &pack, true);
                                }
                                else
                                {
                                        PacketCreate(&pack, SERVER_REVIVAL_PROGRESS);
                                        PacketWrite(&pack, packet_write16, data->id);
                                        PacketWrite(&pack, packet_writedouble, data->plr.revival);
                                        server_broadcast(server, &pack, false);
                                }
                        }
                }

                if (!(data->plr.flags & PLAYER_ESCAPED))
                {
                        data->plr.timeout += server->delta;
                        if (data->plr.timeout >= 4.f * TICKSPERSEC)
                                server_disconnect(server, data->peer, DR_AFKTIMEOUT, NULL);
                        continue;
                }

                if (data->id == server->game.exe)
                        continue;

                if (data->plr.flags & PLAYER_DEMONIZED)
                        demonized++;
                else if (!(data->plr.flags & PLAYER_DEAD))
                        survivors++;
        }

        if(server->game.map != 8 && exe_camp)
                exe->plr.stats.camp_time += server->delta;

        // Start demonization
        if (!server->game.sudden_death && server->game.time_sec <= TICKSPERSEC * 2)
        {
                server->game.sudden_death = true;

                PeerData* sort[6];
                int len = 0;
                memset(sort, 0, sizeof(Player*) * 6);

                for (size_t i = 0; i < server->peers.capacity; i++)
                {
                        PeerData* data = (PeerData*)server->peers.ptr[i];
                        if (!data)
                                continue;

                        if(!data->in_game)
                                continue;

                        if (!(data->plr.flags & PLAYER_DEAD))
                                continue;

                        sort[len++] = data;
                }

                for (int i = 0; i < len; ++i)
                {
                        for (int j = i + 1; j < len; ++j)
                        {
                                double totalA = sort[i]->plr.death_timer_sec + (sort[i]->plr.death_timer / 60.0);
                                double totalB = sort[j]->plr.death_timer_sec + (sort[j]->plr.death_timer / 60.0);
                                
                                if (totalA > totalB)
                                {
                                        PeerData* a = sort[i];
                                        sort[i] = sort[j];
                                        sort[j] = a;
                                }
                        }
                }

                Debug("Demonization order:");
                for (int i = 0; i < len; i++)
                {
                        Debug("%d: %f", sort[i]->id, sort[i]->plr.death_timer_sec + (sort[i]->plr.death_timer / 60.0));
                        game_demonize(server, sort[i]);
                }
        }

        for (size_t i = 0; i < server->peers.capacity; i++)
        {
                PeerData* data = (PeerData*)server->peers.ptr[i];
                if (!data)
                        continue;

                if(!data->in_game)
                        continue;

                if (data->plr.flags & PLAYER_CANTREVIVE)
                        continue;

                if (data->plr.flags & PLAYER_DEAD && data->plr.death_timer_sec > 0)
                {
                        Packet packet;
                        bool exe_near = false;
                        bool demonized_near = false;

                        // check if exe is nearby
                        for (size_t j = 0; j < server->peers.capacity; j++)
                        {
                                PeerData* check = (PeerData*)server->peers.ptr[j];
                                if (!check)
                                        continue;

                                if(!check->in_game)
                                        continue;

                                if (check->id != server->game.exe && !(check->plr.flags & PLAYER_DEMONIZED))
                                        continue;

                                if (vector2_dist(&data->plr.pos, &check->plr.pos) <= 240)
                                {
                                        if (check->plr.flags & PLAYER_DEMONIZED)
                                                demonized_near = true;
                                        else
                                        {
                                                demonized_near = false;
                                                exe_near = true;
                                                break;
                                        }
                                }
                        }

                        if (server->game.time_sec < TICKSPERSEC * 2)
                        {
                                game_demonize(server, data);
                                continue;
                        }

                        if (data->plr.death_timer >= TICKSPERSEC)
                        {
                                if (!exe_near)
                                {
                                        if (--data->plr.death_timer_sec <= 0)
                                        {
                                                game_demonize(server, data);
                                                continue;
                                        }
                                }

                                PacketCreate(&packet, SERVER_GAME_DEATHTIMER_TICK);
                                PacketWrite(&packet, packet_write8, exe_near);
                                PacketWrite(&packet, packet_write16, data->id);
                                PacketWrite(&packet, packet_write8, data->plr.death_timer_sec);
                                server_broadcast(server, &packet, true);

                                data->plr.death_timer = 0;
                        }

                        data->plr.death_timer += (demonized_near ? 0.5f : 1.0f) * server->delta;
                }
        }

        return true;
}

bool game_state_tick(Server* server)
{
        // We wait 15 seconds, before kicking out everyone
        if (!server->game.started)
        {
                server->game.start_timeout -= server->delta;
                if (server->game.start_timeout <= 0)
                {
                        Warn("Waiting for players took too long, kicking out inactive players!");

                        for (size_t j = 0; j < server->peers.capacity; j++)
                        {
                                PeerData* data = (PeerData*)server->peers.ptr[j];
                                if (!data)
                                        continue;

                                if(!data->in_game)
                                        continue;

                                if (!data->plr.ready)
                                {
                                        server_disconnect(server, data->peer, DR_PACKETSNOTRECV, NULL);
                                        break;
                                }
                        }

                }
                return true;
        }

        if (server->game.end > 0)
        {
                server->game.end -= server->delta;
                if (server->game.end <= 0)
                        RAssert(game_uninit(server, true));

                return true;
        }

        /* v5.3 — LMS «EL SHOW FUERTE» POR PERSONAJE: cuando el unico
           jugador vivo del bando survivor tiene show en LMS_SHOWS
           (Server.h), este arranca: el server elige UNA cancion al azar
           de LAS SUYAS, sube el reloj a SU duracion (solo si queda
           menos) y avisa a todos con SERVER_GAME_LMS (u8 char + u8 song
           + musica + banner + cura a LMS_HP del lado cliente).
           DISPARO UNICO (game.lms latch): si un companero caido revive
           despues, el show ya empezo y sigue su curso. La practica
           tambien lo dispara (exe = 0xFFFF no matchea a nadie): un
           personaje solo en .sp puede probar su show entero. */
        if (!server->game.lms)
        {
                int alive = 0;
                PeerData* last = NULL;

                for (size_t i = 0; i < server->peers.capacity; i++)
                {
                        PeerData* v = (PeerData*)server->peers.ptr[i];
                        if (!v || !v->in_game)
                                continue;

                        if (v->id == server->game.exe)
                                continue;

                        if (v->plr.flags & PLAYER_DEAD || v->plr.flags & PLAYER_DEMONIZED || v->plr.flags & PLAYER_ESCAPED)
                                continue;

                        alive++;
                        last = v;
                }

                if (alive == 1 && last)
                {
                        /* v5.3: el show es del ULTIMO SUPERVIVIENTE que
                           esté en la lista (LMS_SHOWS). Sin entrada en
                           la lista no hay show: la ronda sigue normal. */
                        const LmsShow* show = NULL;
                        for (int i = 0; i < LMS_SHOW_COUNT; i++)
                        {
                                if (LMS_SHOWS[i].ch == (uint8_t)last->surv_char)
                                {
                                        show = &LMS_SHOWS[i];
                                        break;
                                }
                        }

                        if (show)
                        {
                                /* v5.3.2 — FIX LMS VARIEDAD V1: la cancion ya
                                   NO sale de rand() % songs (con listas de
                                   2/4 repetia la misma el 50%/25% de las
                                   veces SEGUIDAS y sonaba a "siempre la
                                   misma cancion"). Sale de una BOLSA por
                                   personaje (shuffle-bag) que vive en el
                                   Server (persiste entre rondas): cada show
                                   saca una, y la bolsa solo se rellena cuando
                                   se vacia -> suenan TODAS las del personaje
                                   antes de repetir NINGUNA. */
                                uint8_t* bag = server->lms_bag[show->ch];
                                uint8_t* bag_left = &server->lms_bag_left[show->ch];
                                uint8_t* bag_count = &server->lms_bag_count[show->ch];
                                bool refilled = false;

                                if (*bag_count != show->songs || *bag_left == 0)
                                {
                                        /* bolsa vacia (o la tabla cambio de
                                           tamaño via el Suite): rellenar con
                                           0..songs-1 y mezclar (Fisher-Yates) */
                                        *bag_count = show->songs;
                                        *bag_left = show->songs;
                                        refilled = true;

                                        for (uint8_t j = 0; j < *bag_left; j++)
                                                bag[j] = j;

                                        for (uint8_t j = *bag_left - 1; j > 0; j--)
                                        {
                                                uint8_t k = (uint8_t)(rand() % (j + 1));
                                                uint8_t tmp = bag[j];
                                                bag[j] = bag[k];
                                                bag[k] = tmp;
                                        }
                                }

                                uint8_t pick;
                                if (refilled && show->songs > 1)
                                {
                                        /* ANTI-ECO entre ciclos: sin esto, la
                                           primera extraccion tras rellenar
                                           podia caer (1 de N) en la misma
                                           cancion que cerro el ciclo anterior
                                           -> "la misma DOS VECES SEGUIDAS".
                                           Se sortea entre las otras N-1. */
                                        uint8_t skip = 0xFF;
                                        for (uint8_t j = 0; j < *bag_left; j++)
                                        {
                                                if (bag[j] == server->lms_last[show->ch])
                                                {
                                                        skip = j;
                                                        break;
                                                }
                                        }

                                        if (skip != 0xFF)
                                        {
                                                pick = (uint8_t)(rand() % (*bag_left - 1));
                                                if (pick >= skip)
                                                        pick++;
                                        }
                                        else
                                                pick = (uint8_t)(rand() % *bag_left);
                                }
                                else
                                        pick = (uint8_t)(rand() % *bag_left);

                                server->game.lms = true;
                                server->game.lms_char = show->ch;
                                server->game.lms_song = bag[pick];
                                server->lms_last[show->ch] = bag[pick];

                                /* la sacada se reemplaza por la ultima
                                   pendiente (quedan bag_left-1 sin ella) */
                                bag[pick] = bag[*bag_left - 1];
                                (*bag_left)--;

                                uint16_t song_sec = show->sec[server->game.lms_song];
                                if (server->game.time_sec < song_sec)
                                        server->game.time_sec = song_sec;

                                Packet packet;
                                PacketCreate(&packet, SERVER_GAME_LMS);
                                /* v5.3.1: el personaje viaja en numeracion
                                   CHARACTER_* del cliente (CH_TAILS=0 ->
                                   CHARACTER_TAILS=1), igual que todo
                                   id+1 de CharSelect.c. Sin el +1 el
                                   cliente lee el id del personaje
                                   ANTERIOR de la lista y suena la
                                   cancion del vecino. */
                                PacketWrite(&packet, packet_write8, server->game.lms_char + 1);
                                PacketWrite(&packet, packet_write8, server->game.lms_song);
                                RAssert(server_broadcast(server, &packet, true));

                                Info(LOG_YLW "LMS: ch %u is the last survivor - El Show Fuerte! (song %u/%u, time %ds)" LOG_RST,
                                     (unsigned)server->game.lms_char, (unsigned)server->game.lms_song + 1u, (unsigned)show->songs, (int)server->game.time_sec);
                        }
                }
        }

        server->game.elapsed += server->delta;
        if (server->game.time <= TICKSPERSEC)
        {
                server->game.time_sec--;
                server->game.time += TICKSPERSEC;

                if (server->game.time_sec % server->game.ring_coff == 0)
                {
                        if (!game_spawn(server, (Entity*)&(MakeRing()), sizeof(Ring), NULL))
                                Debug("Not enough space for rings");
                }

                Packet packet;
                PacketCreate(&packet, SERVER_GAME_TIME_SYNC);
                PacketWrite(&packet, packet_write16, (uint16_t)server->game.time_sec * TICKSPERSEC);
                server_broadcast(server, &packet, true);

                if (server->game.time_sec <= 0)
                        RAssert(game_end(server, ED_TIMEOVER, true));
        }

        RAssert(game_player_tick(server));
        RAssert(game_entity_tick(server));
        RAssert(g_mapList[server->game.map].cb.tick(server));

        server->game.time -= server->delta;
        return true;
}
