function scr_survivor_revive()
{
        if(!instance_exists(global.player))
                return;
                
        // BURBUJA DE SECUESTRO (Amy Canon): mientras esta secuestrada NO
        // se muestra el prompt de revivir ni se envian paquetes de revive.
        // Ella no esta muerta (se salto la agonia): esta atrapada, y se
        // libera tocandola un companero, no reviviendola con anillos.
        if(character == CHARACTER_AMY_CANON)
        {
                if(state >= AMY_CANON_CAPTURE && state <= AMY_CANON_CAPTURE_R)
                {
                        reviveObj.over = -1;
                        reviveObj.show = false;
                        return;
                }
        }
        
        // FASE 2 (Sally Canon): durante sus 4 partes NO esta muerta (el
        // server nunca la marco como tal): sin prompt de revive ni paquetes.
        if(character == CHARACTER_SALLY_CANON)
        {
                if(state >= SALLY_CANON_F2_PT1 && state <= SALLY_CANON_F2_PT4)
                {
                        reviveObj.over = -1;
                        reviveObj.show = false;
                        return;
                }
        }
                
        // === v2.11: RESCATE DE ESBIRRO (Vanilla) ======================
        // Un esbirro demonizado ATURDIDO se revive EXACTAMENTE como un
        // caido: Vanilla encima MANTENIENDO ABAJO, el MISMO prompt
        // (spr_revival / spr_revival2), la MISMA barra de progreso
        // (SERVER_REVIVAL_PROGRESS, la llena el server) y 15 anillos al
        // completar (los cobra el handler de SERVER_VANILLA_DEDEMONIZE
        // en net_state_game). "ATURDIDO" = su estado por red es DEAD
        // (los esbirros jamas estan "caidos": su stun viaja como DEAD,
        // ver Step_2 de cada personaje). El stun lo abre el propio kit:
        // la mini-embestida de Chocola ahora detecta esbirros (3.5 s,
        // scr_chocola_find_minion) — tambien vale cualquier otro stun
        // (parry de Sonic, laser de Tails...).
        // NOTA de ambito: self = el puppet del esbirro, esto corre en
        // TODOS los clientes; el prompt solo lo ve el de Vanilla y el
        // paquete solo lo manda ese (mismo patron que el revive de abajo).
        if(revivalTimes >= 2 && state == DEAD && character != CHARACTER_EXE)
        {
                var _vanilla = instance_exists(global.player) && global.character == CHARACTER_VANILLA;

                // se des-volvio normal a mitad (isDemonized se refresca
                // en el Step_0 del puppet con el revivalTimes por red):
                // fuera prompt y bar
                if(isInactive || !_vanilla || global.player.hp <= 0 || global.player.isDead)
                {
                        if(_vanilla && global.player.dedemonTarget == master_id)
                                global.player.dedemonTarget = -1;

                        reviveObj.over = -1;
                        reviveObj.show = false;
                        return;
                }

                if(place_meeting(x, y, global.player))
                {
                        reviveObj.over = global.player.rings >= VANILLA_DEDEMON_COST ? 1 : 0;

                        // envio del progreso: solo el esbirro con el LOCK
                        // (o si no hay lock) y solo manteniendo ABAJO
                        if(global.playerControls && global.player.isLookingDown && global.player.rings >= VANILLA_DEDEMON_COST
                           && (global.player.dedemonTarget == -1 || global.player.dedemonTarget == master_id))
                        {
                                global.player.dedemonTarget = master_id;

                                // cadencia de 2 frames (30 paq/s): el progreso
                                // por paquete lo pone el server (0.03 base)
                                if(global.player.dedemonCd <= 0)
                                {
                                        global.player.dedemonCd = VANILLA_DEDEMON_SEND_CD;

                                        var dpak = cpacket_tcp(PacketType.CLIENT_VANILLA_DEDEMONIZE_PROGRESS, false);
                                        buffer_write(dpak, buffer_u16, master_id);
                                        buffer_write(dpak, buffer_u8, global.player.rings);
                                        send_server_tcp(dpak);
                                }
                        }
                        else if(global.player.dedemonTarget == master_id && !global.player.isLookingDown)
                        {
                                // solto el ABAJO: libera el lock. El progreso
                                // ya hecho SE CONSERVA en el server (igual que
                                // el revive del caido: soltar y volver a apoyar
                                // no reinicia la barra)
                                global.player.dedemonTarget = -1;
                        }
                }
                else
                {
                        reviveObj.over = -1;

                        if(global.player.dedemonTarget == master_id)
                                global.player.dedemonTarget = -1;
                }

                return;
        }

        if(hp > 0)
        {
                reviveObj.over = -1;
                reviveObj.show = false;
                return;
        }
        
        if(revivalTimes != 0 || isDemonized)
        {
                reviveObj.over = -1;
                reviveObj.show = false;
                return;
        }
        
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
        {
                reviveObj.over = -1;
                return;
        }
        
        if(global.player.hp <= 0)
        {
                reviveObj.over = -1;
                return;
        }
        
        if(place_meeting(x, y, global.player))
        {       
                reviveObj.over = global.player.rings >= 3 ? 1 : 0;
                        
                if(global.playerControls && global.player.isLookingDown)
                {
                        if(global.player.rings >= 3)
                        {
                                var pak = cpacket_tcp(PacketType.CLIENT_REVIVAL_PROGRESS, false);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u8, global.player.rings - 3);
                                send_server_tcp(pak);   
                        }
                }
        }
        else 
                reviveObj.over = -1;
}