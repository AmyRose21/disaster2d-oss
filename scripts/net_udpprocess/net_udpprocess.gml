function net_udpprocess(rbuff)
{
        obj_netclient.udp_timeout = 60 * 5;
        var passtrough = buffer_read_s(rbuff, buffer_u8);
        
        //Other clients
        switch(buffer_read_s(rbuff, buffer_u8))
        {               
                case PacketType.SERVER_GAME_PING:
                {
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _ms = buffer_read_s(rbuff, buffer_u16);
                        obj_netclient.pings[? _pid] = _ms;
                        break;
                }
                
                case PacketType.SERVER_FART_STATE:
                {                       
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(!instance_exists(obj_fart_dummy))
                                return;
                        
                        with(obj_fart_dummy)
                        {
                                x = _x;
                                y = _y;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_REVIVAL_PROGRESS:
                {
                        if(passtrough)
                                 break;

                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _prog = buffer_read_s(rbuff, buffer_f64);

                        with(obj_revival_puppet)
                        {
                                if(master_id != _pid)
                                        continue;

                                progress = _prog;
                                break;
                        }

                        break;
                }

                case PacketType.SERVER_EGG_UPGRADE_PROGRESS:
                {
                        // v3.1 («Genio Malvado» estilo rescate): progreso de
                        // la MEJORA de una trampa (0 sensor / 1 trampa de
                        // Amelia) — misma barra del revive, pero dibujada
                        // por la propia trampa (upgShow/upgProg) y SOLO para
                        // el bando superviviente (Draw_0 de cada trampa).
                        if(passtrough)
                                break;

                        var _gtype = buffer_read_s(rbuff, buffer_u8);
                        var _gnid = buffer_read_s(rbuff, buffer_u16);
                        var _gprog = buffer_read_s(rbuff, buffer_f64);

                        with(_gtype == 1 ? obj_amelia_trap : obj_eggtrack)
                        {
                                if(nid != _gnid)
                                        continue;

                                upgProg = _gprog;
                                upgShow = true;
                                break;
                        }

                        break;
                }
                
                case PacketType.CLIENT_PLAYER_DATA:
                {
                        if(state != STATE_GAME)
                                break;
                        
                        var pid = buffer_read_s(rbuff, buffer_u16);
                        if(instance_exists(obj_player_puppet))
                        {                               
                                with(obj_player_puppet)
                                {
                                        if(pid != master_id)
                                                continue;
                                                
                                        isInactive = false;
                                        alarm[1] = 60;
                                        alarm[2] = 5;
                                        
                                        pX = x;
                                        pY = y;
                                        x = net_unwrap_coord(buffer_read_s(rbuff, buffer_u16));
                                        y = net_unwrap_coord(buffer_read_s(rbuff, buffer_u16));
                                        xspd = net_sanitize_speed(buffer_read_s(rbuff, buffer_f16));
                                        yspd = net_sanitize_speed(buffer_read_s(rbuff, buffer_f16));
                                        
                                        state = buffer_read_s(rbuff, buffer_u8);
                                        angle = buffer_read_s(rbuff, buffer_s16);
                                        image_index = buffer_read_s(rbuff, buffer_u8);
                                        image_xscale = buffer_read_s(rbuff, buffer_s8);
                                        
                                        if(image_xscale > 1)
                                                image_xscale = 1;
                                        else if(image_xscale < -1)
                                                image_xscale = -1;
                                        
                                        if(character == CHARACTER_EXE)
                                        {
                                                var bitflags = buffer_read_s(rbuff, buffer_u8);
                                                
                                                isAttacking = bitflags & PLAYER_ATTACKING;
                                                isHurt = bitflags & PLAYER_HURT;
                                                effect = bitflags & PLAYER_EFFECT;
                                                
                                                switch(exeCharacter)
                                                {
                                                        case 0:
                                                                visible = !(bitflags & PLAYER_INVIS);
                                                                break;
                                                        case 1:
                                                                slimeMode = bitflags & PLAYER_SLIME ? CHAOS_AIRTRANSFORM+1 : 0;
                                                                break;
                                                }
                                        }
                                        else
                                        {
                                                hp = buffer_read_s(rbuff, buffer_s8);
                                                revivalTimes = buffer_read_s(rbuff, buffer_u8);
                                                rings = buffer_read_s(rbuff, buffer_s16);
                                                
                                                var bitflags = buffer_read_s(rbuff, buffer_u8);
                                                if(character == CHARACTER_TAILS)
                                                {
                                                        tailsCharge = buffer_read_s(rbuff, buffer_u8);
                                                        
                                                        if(instance_exists(obj_puppet_tail))
                                                                obj_puppet_tail.image_angle = buffer_read_s(rbuff, buffer_s16);
                                                }
                                                
                                                // SONIC v4: sin esta linea el puppet de Sonic nunca queda
                                                // isAttacking en el cliente del EXE -> el golpe no aturdia.
                                                if(character == CHARACTER_KNUX || character == CHARACTER_EGGMAN || (character == CHARACTER_AMY || character == CHARACTER_AMY_CANON) || character == CHARACTER_SALLY || character == CHARACTER_SALLY_CANON || character == CHARACTER_SONIC)
                                                        isAttacking = bitflags & PLAYER_ATTACKING;
                                                        
                                                isHurt = bitflags & PLAYER_HURT;
                                                hasRedRing = bitflags & PLAYER_REDRING;
                                                effect = bitflags & PLAYER_EFFECT;
                                                
                                                if(character == CHARACTER_SALLY || character == CHARACTER_SALLY_CANON)
                                                        sallyShield = bitflags & PLAYER_SALLYSHIELD;
                                                
                                                // SONIC: powerboost de Nervios de Acero
                                                // (estela de fantasmas en este puppet)
                                                if(character == CHARACTER_SONIC)
                                                        powerBoost = bitflags & PLAYER_POWERBOOST;

                                                // SALLY CANON fase DUELISTA (v5.4): viaja
                                                // con el MISMO bit PLAYER_POWERBOOST (el
                                                // byte va lleno y ese bit solo lo usan
                                                // Sonic/Vanilla/Metal/Blaze: jamas
                                                // colisiona con ella). Aqui NO se toca
                                                // powerBoost (solo Sonic tiene estela):
                                                // se guarda aparte como "duelista" y
                                                // STICKY: una vez vista, se queda (la
                                                // fase nunca se apaga hasta el fin de la
                                                // ronda; el bit viaja vivo de todos
                                                // modos, el sticky solo blinda contra
                                                // un paquete perdido).
                                                if(character == CHARACTER_SALLY_CANON && (bitflags & PLAYER_POWERBOOST))
                                                        duelista = true;

                                                // v2.15 «La Torre»: FW Amy volando con el DJ (el
                                                // cliente del EXE lo necesita para el stun de 3,2 s)
                                                if(character == CHARACTER_FLEETWAY_AMY)
                                                        isDJ = bitflags & PLAYER_DJ;
                                        }
                                        break;
                                }
                        }
                        break;
                }
                        
                case PacketType.SERVER_TPROJECTILE_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        if(state != STATE_GAME)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state != 1) //impossible
                                break;
                        
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);
                        
                        // If doesnt exist then spawn ig
                        if(!instance_exists(obj_tails_projectile))
                                break;
                        
                        with(obj_tails_projectile)
                        {
                                if(isBreaking)
                                        continue;
                                        
                                x = _xx;
                                y = _yy;
                                break;
                        }
                        break;
                }
                
                // v2.15 («La Torre») — FIX FLECHA DE LA BALLESTA: el server
                // manda el tick de posicion (SERVER_FWBOLT_STATE 1) como NO
                // confiable (server_broadcast(..., false) en fwbolt_tick), o
                // sea por ESTE canal (UDP). El case solo existia en
                // net_state_game (canal TCP), por el que ese estado JAMAS
                // llegaba: la flecha nacia quieta en la mano de Fleetway y no
                // avanzaba ("el proyectil no avanza"). Mismo arreglo que el
                // laser de Tails, la bola de Blaze (v2.9b) y la bala de Metal
                // Amy. El paquete lleva el id de la entidad para poder mover
                // la flecha correcta con hasta 3 en vuelo.
                // v2.15.1 — FIX «LA FLECHA TRASPASA LA PARED»: los ticks de
                // posicion del server YA NO SE APLICAN. El server no conoce
                // el mapa y sus saltos de 14 px por UDP hacian que la flecha
                // se saltara la pared en las rafagas (el evento de colision
                // de GM solo dispara con solape al final del frame). Ahora
                // cada cliente simula el vuelo LOCALMENTE en obj_fw_bolt/Step
                // (barrido sub-pixel, misma velocidad FW_ARROW_FLIGHT); el
                // server dejo de emitir este estado. El case se conserva
                // leyendo los campos para no desalinear el buffer si algun
                // server viejo todavia lo manda.
                case PacketType.SERVER_FWBOLT_STATE:
                {
                        if(passtrough)
                                break;

                        if(state != STATE_GAME)
                                break;

                        var _state = buffer_read_s(rbuff, buffer_u8);

                        if(_state != 1) //impossible (0/2/3 van por TCP fiable)
                                break;

                        var _fwid = buffer_read_s(rbuff, buffer_u16);
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);

                        // v2.15.1: posicion descartada a proposito (vuelo
                        // local; ver obj_fw_bolt/Step_0). _xx/_yy/_fwid se
                        // leen arriba solo para mantener el buffer alineado.
                        break;
                }
                
                // v2.9b — FIX BOLA DE FUEGO DE BLAZE: mismo arreglo que el
                // laser de Metal Amy (v2.2b) y el de Tails. El server envia
                // el tick de posicion (SERVER_BLAZE_FIREBALL_STATE 1) como
                // NO confiable (server_broadcast(..., false) en bfire_tick),
                // o sea por ESTE canal (UDP). El case solo existia en
                // net_state_game (canal TCP), por el que ese estado jamas
                // llegaba: la bola nacia quieta y solo reaccionaba a los
                // rebotes. Mismo patron que el Tails de arriba: nid + pos +
                // dir + vy para que cada cliente rote el cometa siguiendo
                // su trayectoria rebotante.
                case PacketType.SERVER_BLAZE_FIREBALL_STATE:
                {
                        if(passtrough)
                                 break;

                        if(state != STATE_GAME)
                                break;

                        var _state = buffer_read_s(rbuff, buffer_u8);

                        if(_state != 1) //impossible
                                break;

                        var _nid = buffer_read_s(rbuff, buffer_u16);
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);
                        var _dir = buffer_read_s(rbuff, buffer_s8);
                        var _vy = buffer_read_s(rbuff, buffer_s8);

                        if(!instance_exists(obj_blaze_fireball))
                                break;

                        with(obj_blaze_fireball)
                        {
                                if(nid != _nid || isBreaking)
                                        continue;

                                vx = _dir * 10;
                                vy = _vy;
                                dir = _dir;
                                x = _xx;
                                y = _yy;
                                image_xscale = 1;
                                image_angle = point_direction(0, 0, vx, vy);
                                break;
                        }
                        break;
                }

                // v2.2b — FIX LASER DE METAL AMY: el server envia el tick de
                // posicion de la bala (SERVER_METALAMY_BULLET_STATE 1) como
                // NO confiable (server_broadcast(..., false) en mabul_tick),
                // o sea por ESTE canal (UDP), igual que el laser de Tails.
                // El case solo existia en net_state_game (canal TCP), por el
                // que ese estado jamas llegaba: la bala nacia y quedaba quieta
                // hasta romperse. Mismo patron que el Tails de arriba.
                case PacketType.SERVER_METALAMY_BULLET_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        if(state != STATE_GAME)
                                break;
                        
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state != 1) //impossible
                                break;
                        
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);
                        
                        // If doesnt exist then spawn ig
                        if(!instance_exists(obj_metal_amy_bullet))
                                break;
                        
                        with(obj_metal_amy_bullet)
                        {
                                if(isBreaking)
                                        continue;
                                        
                                x = _xx;
                                y = _yy;
                                break;
                        }
                        break;
                }
                
                case PacketType.SERVER_RMZSLIME_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var type =  buffer_read_s(rbuff, buffer_u8);
                        
                        if(type != 1)
                                return;
                                
                        var _uid = buffer_read_s(rbuff, buffer_u16);
                        var _xx = buffer_read_s(rbuff, buffer_u16);
                        var _yy = buffer_read_s(rbuff, buffer_u16);
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_rmzsonic))
                                break;
                        
                        with(obj_rmzsonic)
                        {
                                if(nid != _uid)
                                        continue;
                                
                                x = _xx;
                                y = _yy;
                                state = _state;
                                        
                                break;
                        }
                        break;
                }
                
                case PacketType.SERVER_ACT9WALL_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        if(state != STATE_GAME)
                                break;
                        
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        with(obj_act9_wall)
                        {
                                if(nid != _id)
                                        continue;
                                
                                if(nid == 0)
                                {
                                        x = -2240;
                                        y = _y - 768;
                                }
                                else if(nid == 1)
                                {
                                        x = _x - 2240;
                                        y = _y;
                                }
                                else if(nid == 2)
                                {
                                        x = room_width - _x;
                                        y = _y; 
                                }
                                break;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_NAPBALL_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _nid = buffer_read_s(rbuff, buffer_u8);
                        
                        if(_state == 1)
                        {
                                var _waypoint = buffer_read_s(rbuff, buffer_u8);
                                var _frame = buffer_read_s(rbuff, buffer_u8);
                                var _waypointProgress = buffer_read_s(rbuff, buffer_f64);
                                
                                var _first = noone;
                                var _next = noone;
                                
                                with(obj_nap_snowball_waypoint)
                                { 
                                        if(nid != _nid)
                                                continue;
                                        
                                        if(wid == _waypoint)
                                                _first = self;
                                                
                                        if(wid == _waypoint + 1)
                                                _next = self;
                                }
                                
                                if(_first == noone)
                                        break;
                                        
                                if(_next == noone)
                                        break;
                                
                                if(!instance_exists(obj_nap_snowball))
                                        break;
                                
                                with(obj_nap_snowball)
                                {
                                        if(nid != _nid)
                                                continue;
                                                
                                        x = _first.x + ((_next.x - _first.x) * _waypointProgress) + 32;
                                        y = _first.y + ((_next.y - _first.y) * _waypointProgress) + 64;
                                        image_index = _frame;
                                        break;
                                }
                        }
                        break;
                }
                
                case PacketType.CLIENT_SPRING_USE:
                {
                        if(state != STATE_GAME)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                }
                
                case PacketType.SERVER_PFLIFT_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        if(state != STATE_GAME)
                                break;
                                
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _pid = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(!instance_exists(obj_pf_lift))
                                break;
                                        
                        var inst = noone;
                        with(obj_pf_lift)
                        {
                                if(nid != _id)
                                        continue;
                                        
                                if(!activated)
                                        return;
                                        
                                y = _y;
                                self.pid = _pid;
                                break;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_VVLCOLUMN_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _y = buffer_read_s(rbuff, buffer_f32);
                        
                        if(!instance_exists(obj_vv_lavacolumn))
                                break;
                                
                        with(obj_vv_lavacolumn)
                        {
                                if(nid != _id)
                                        continue;
                                
                                state = _state;
                                if(prevState != _state)         
                                        prevState = _state;
                                
                                y = _y;
                                
                                break;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_DTTAILSDOLL_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        var _tar = buffer_read_s(rbuff, buffer_u8);
                        
                        if(!instance_exists(obj_darktower_tailsdoll))
                                instance_create_depth(_x, _y, 0, obj_darktower_tailsdoll);
                                
                        obj_darktower_tailsdoll.pX = obj_darktower_tailsdoll.x;
                        obj_darktower_tailsdoll.pY = obj_darktower_tailsdoll.y;
                        obj_darktower_tailsdoll.x = _x;
                        obj_darktower_tailsdoll.y = _y;
                        obj_darktower_tailsdoll.image_index = _tar;
                        break;
                }
                
                case PacketType.SERVER_DTBALL_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var _state = buffer_read_s(rbuff, buffer_f32);
                        
                        if(!instance_exists(obj_darktower_ball))
                                break;
                        
                        with(obj_darktower_ball)
                                y = sY + (_state * dir * dist);
                        
                        break;
                }
                
                case PacketType.SERVER_DTASS_STATE:
                {
                        if(passtrough)
                                 break;
                                 
                        var _id = buffer_read_s(rbuff, buffer_u8);
                        var _x = buffer_read_s(rbuff, buffer_u16);
                        var _y = buffer_read_s(rbuff, buffer_u16);
                        
                        if(!instance_exists(obj_darktower_sisi))
                                break;
                                
                        with(obj_darktower_sisi)
                        {
                                if(nid != _id)
                                        continue;
                                
                                damage = true;
                                x = _x;
                                y = _y;
                                break;
                        }
                        break;
                }
                
                case PacketType.SERVER_MJLAVA_STATE:
                {                                
                        if(passtrough)
                                 break;
                                 
                        var _state = buffer_read_s(rbuff, buffer_u8);
                        var _y = buffer_read_s(rbuff, buffer_f32);
                        
                        if(!instance_exists(obj_marijuna_lavaplatform))
                                break;
                                
                        with(obj_marijuna_lavaplatform)
                        {
                                state = _state;
                                if(prevState != _state)
                                        prevState = _state;
                                
                                if((_state == 2 || _state == 4) && instance_exists(obj_player_sensorBL))
                                {
                                        if(place_meeting(x, y, obj_player_sensorBL) || place_meeting(x, y, obj_player_sensorBR))
                                        {
                                                global.player.y = _y - 17;
                                        }
                                }
                                
                                y = _y;
                                break;
                        }
                        
                        break;
                }
                
                case PacketType.SERVER_PONG:
                {
                        if(state != STATE_GAME)
                                break;
                                
                        ping = buffer_read(rbuff, buffer_u16);
                        break;
                }
        }
}