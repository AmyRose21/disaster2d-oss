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
                        // v13 (MAX HP POR PERSONAJE): el hp viaja ahora como S16
                        // (antes s8: 150 de Metal Sonic NO cabia en un int8 con
                        // signo) y clampeado a la vida TOTAL del personaje
                        // (scr_player_maxhp: Rouge 125 / Metal 150 / resto 100).
                        // El reader de TODOS los clientes (net_udpprocess) y el
                        // anti-cheat del server (Game.c, cap por personaje) ya
                        // leen s16 en la misma posicion — mismo build = alineado.
                        buffer_write(buffer, buffer_s16, clamp(hp, 0, scr_player_maxhp(global.character)));
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
                        if(global.character == CHARACTER_KNUX || (global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON) || global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON || global.character == CHARACTER_EGGMAN || global.character == CHARACTER_SONIC || global.character == CHARACTER_METAL || global.character == CHARACTER_ROUGE || global.character == CHARACTER_KRIS)
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
                        
                        // v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer,
                        // 2.5 s): mismo bit 7 que PLAYER_SLIME (jamas colisionan: slime es
                        // de Chaos EXE, esto es de supervivientes) para que los demas
                        // clientes dibujen spr_electroshield en el puppet del portador.
                        if(global.character != CHARACTER_EXE
                        && variable_instance_exists(global.player, "electricShieldTimer")
                        && global.player.electricShieldTimer > 0)
                                bitflags |= PLAYER_ELECTROSHIELD;

                        // v71 ITEM BOX v3 — ESCUDO DE BURBUJA para TODOS: mismo bit
                        // PLAYER_SALLYSHIELD de siempre. Sally/SallyCanon/Rouge lo
                        // siguen mandando en sus bloques de abajo (redundante e
                        // inocuo: OR del mismo bit); el RESTO de personajes con
                        // escudo de caja manda AQUÍ (patrón exacto del eléctrico de
                        // arriba). Con este bit el puppet remoto dibuja la burbuja en
                        // su Draw_0 (genérico nuevo).
                        if(global.character != CHARACTER_EXE
                        && variable_instance_exists(global.player, "shieldTimer")
                        && global.player.shieldTimer > 0)
                                bitflags |= PLAYER_SALLYSHIELD;
                        if(global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON)
                        {
                                if(shieldTimer > 0)
                                        bitflags |= PLAYER_SALLYSHIELD;
                        }

                        // v32 (HABILIDAD V de Rouge): el ESCUDO DE SALLY del
                        // modo SUPPORT manda el MISMO bit que la de Sally (la
                        // burbuja la dibuja su puppet en los demas clientes) y
                        // la INVISIBILIDAD de su set normal manda el MISMO bit
                        // del sonic.exe original (PLAYER_INVIS: los demas
                        // clientes esconden su puppet entero y las agujas de
                        // rastreo la saltan, vease net_udpprocess).
                        if(global.character == CHARACTER_ROUGE)
                        {
                                if(shieldTimer > 0)
                                        bitflags |= PLAYER_SALLYSHIELD;

                                if(invisTimer > 0)
                                        bitflags |= PLAYER_INVIS;
                        }

                        // SALLY CANON fase DUELISTA (v5.4): tras su 1ra caida
                        // manda PLAYER_POWERBOOST hasta el fin de la ronda. Los
                        // puppets de los demas clientes lo guardan como
                        // "duelista" (net_udpprocess) y con el ven: el spindash,
                        // la bola del salto, las poses del escudo grupal y el
                        // pad +50% de la patada aerea. (v84: la patada en tierra
                        // de 2 golpes ya NO depende del flag: viaja sola con su
                        // estado 22 en el byte de state de siempre.) OJO: no se
                        // toca powerBoost del puppet (esa estela es solo de
                        // Sonic).
                        if(global.character == CHARACTER_SALLY_CANON && duelista)
                                bitflags |= PLAYER_POWERBOOST;
                
                        buffer_write(buffer, buffer_u8, bitflags);
                        if(global.character == CHARACTER_TAILS)
                        {
                                buffer_write(buffer, buffer_u8, attackCharge);
                                buffer_write(buffer, buffer_s16, -radtodeg(arctan2(obj_tails.yspd, obj_tails.isGrounded ? obj_tails.gspd : obj_tails.xspd)));
                        }

                        // v82 (duena): FORMA CYBER de Sally Canon (tecla V) - 3 bytes
                        // AL FINAL del paquete: [SALLY_CYBER_NET_TAG_A, TAG_B, forma].
                        // El server retransmite todo lo que viene despues del bitflags
                        // sin mirarlo (Game.c: while pos < len), asi que no hace falta
                        // tocar ni el server ni los tipos de paquete. DOBLE etiqueta:
                        // el buffer de recepcion es FIJO y un cliente viejo (que no
                        // manda estos bytes) se leeria como basura vieja, no como -1.
                        if(global.character == CHARACTER_SALLY_CANON && variable_instance_exists(id, "cyberForm"))
                        {
                                buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_A);
                                buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_B);
                                buffer_write(buffer, buffer_u8, clamp(floor(cyberForm), 0, 2));
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