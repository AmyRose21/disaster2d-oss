net_poll();

if(!isConnected)
        return;
        
if(!isInit)
        return;
        
if(!isServerReady)
{
        global.playerControls = false;
}
else
{
        if(sendTimeout > 0)
        {
                sendTimeout--;
                global.playerControls = false;
        }
        else
        {
                if(sendTimeout == 0 && isServerReady)
                        global.playerControls = true;
                        
                if(sendTimeout-- %  60 == 0)
                {
                        var packet = cpacket_udp(PacketType.CLIENT_PING);
                        send_server_udp(packet);
                }
        }
}

if(!instance_exists(global.player))
        return;

//Send player packet
with(global.player)
{
        if(obj_netclient.isReady)
        {
                var buffer = cpacket_udp(PacketType.CLIENT_PLAYER_DATA);
                buffer_write(buffer, buffer_u16, x);
                buffer_write(buffer, buffer_u16, y);
                buffer_write(buffer, buffer_f16, xspd);
                buffer_write(buffer, buffer_f16, yspd);
                
                buffer_write(buffer, buffer_u8, state);
                buffer_write(buffer, buffer_s16, radtodeg(angle));
                buffer_write(buffer, buffer_u8, image_index);
                buffer_write(buffer, buffer_s8, image_xscale);
        
                var bitflags = 0;
        
                if(effectTime > 0)
                        bitflags |= PLAYER_EFFECT;
        
                if(global.character != CHARACTER_EXE)
                {
                        // v4.10 blindaje «garic forn»: el anticheat del server
                        // (states/Game.c) desconecta con hp > 100 en el
                        // CLIENT_PLAYER_DATA. Las curas ya viajan clampeadas
                        // (v4.8/v4.9) pero esto garantiza que NINGUNA ruta
                        // futura pueda mandar un hp fuera de rango: aqui es
                        // fisicamente imposible que viaje > 100.
                        buffer_write(buffer, buffer_s8, clamp(hp, 0, 100));
                        buffer_write(buffer, buffer_u8, revivalTimes);
                        buffer_write(buffer, buffer_s16, rings);
                
                        if(hurttime > 0)
                                bitflags |= PLAYER_HURT;
                        
                        if(redRingTimer > 0)
                                bitflags |= PLAYER_REDRING;
                
                        // v2.8 (reporte del usuario) — METAL tambien viaja: sin
                        // este bit el stun de contacto del overdrive y del spark
                        // field era CODIGO MUERTO (el cliente del EXE jamas veia
                        // al puppet atacando: el caso METAL de obj_player_puppet
                        // Step_0 no se ejecutaba nunca, y de ahi el "no tiene
                        // sentido que los haga"). Para Metal isAttacking solo
                        // esta en true durante sus 2 ataques (scr_metal_special),
                        // asi que el bit es exacto.
                        if(global.character == CHARACTER_KNUX || (global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON) || global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON || global.character == CHARACTER_EGGMAN || global.character == CHARACTER_SONIC || global.character == CHARACTER_METAL || global.character == CHARACTER_ROUGE)
                        {
                                if(isAttacking)
                                        bitflags |= PLAYER_ATTACKING;
                        }
                        
                        // v2.15 («La Torre»): FW Amy volando con el DJ doble
                        // salto. Con este bitflag el cliente del EXE ve el vuelo
                        // en su puppet y aplica el stun de 3,2 s por contacto
                        // (obj_player_puppet Step_0, mismo modelo que el resto
                        // de stuns: la victima es la autoridad).
                        if(global.character == CHARACTER_FLEETWAY_AMY && isDJ)
                                bitflags |= PLAYER_DJ;
                        
                        // SONIC: powerboost de Nervios de Acero (fase 3) o el boost
                        // persistente del revive (fase 2). Con este bitflag el resto de
                        // clientes dibujan la estela y los efectos Frontiers en su puppet.
                        if(global.character == CHARACTER_SONIC && (nerviosState == 3 || reviveBoost))
                                bitflags |= PLAYER_POWERBOOST;
                        
                        // VANILLA V2: FLOAT RUN (3ra fase de corrida a 14) manda el mismo
                        // bitflag que el powerboost de Sonic: el resto de clientes dibuja
                        // la estela de fantasmas en su puppet (obj_player_puppet Step_0).
                        if(global.character == CHARACTER_VANILLA && isFloatRunning)
                                bitflags |= PLAYER_POWERBOOST;
                
                
                        // v2.2 (TTB): el dash de Metal y la forma ardiente de Blaze
                        // mandan el mismo bitflag: los demas clientes ven la estela
                        // de imagenes residuales en su puppet.
                        if(global.character == CHARACTER_METAL && metalDashing > 0)
                                bitflags |= PLAYER_POWERBOOST;
                        
                        if(global.character == CHARACTER_BLAZE && burning > 0)
                                bitflags |= PLAYER_POWERBOOST;
                        if(global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON)
                        {
                                if(shieldTimer > 0)
                                        bitflags |= PLAYER_SALLYSHIELD;
                        }

                        // SALLY CANON fase DUELISTA (v5.4): tras su 1ra caida
                        // manda PLAYER_POWERBOOST hasta el fin de la ronda. Los
                        // puppets de los demas clientes lo guardan como
                        // "duelista" (net_udpprocess) y con el ven: la patada
                        // en tierra de 2 golpes, el spindash, la bola del salto,
                        // las poses del escudo grupal y el pad +50% de la
                        // patada aerea. OJO: no se toca powerBoost del puppet
                        // (esa estela es solo de Sonic).
                        if(global.character == CHARACTER_SALLY_CANON && duelista)
                                bitflags |= PLAYER_POWERBOOST;
                
                        buffer_write(buffer, buffer_u8, bitflags);
                        if(global.character == CHARACTER_TAILS)
                        {
                                buffer_write(buffer, buffer_u8, attackCharge);
                                buffer_write(buffer, buffer_s16, -radtodeg(arctan2(obj_tails.yspd, obj_tails.isGrounded ? obj_tails.gspd : obj_tails.xspd)));
                        }
                }
                else
                {
                        var attacking = isAttacking;
                
                        switch(global.exeCharacter)
                        {
                                case 0:
                                        if(!((state == EXE_ATTACK && image_index > 0)   || (state == EXE_AIR_ATTACK && image_index >= 3)))
                                                attacking = false;
                                        break;
                        }
                
                        if(attacking)
                                bitflags |= PLAYER_ATTACKING;
                        
                        if(hurttime > 0)
                                bitflags |= PLAYER_HURT;
                
                        switch(global.exeCharacter)
                        {
                                case 0:
                                        if(invisTimer > 0)
                                                bitflags |= PLAYER_INVIS;
                                        break;
                                case 1:
                                        if(slimeTimer > 0 && (state != CHAOS_TRANSFORM && state != CHAOS_AIRTRANSFORM))
                                                bitflags |= PLAYER_SLIME;
                                        break;
                        }
                
                        buffer_write(buffer, buffer_u8, bitflags);
                }
        
                send_server_udp(buffer);
        }
}