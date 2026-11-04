if(isBreaking)
{
        if(image_index >= image_number - 1)
                instance_destroy();
        return;
}

// Clavada: la plataforma obj_fw_arrow ya existe; este objeto solo
// espera el despawn del server (estado 2 -> _destroy) o se destruyo
// localmente al clavarse (el spawn de obj_fw_arrow lo destruye).
if(isStuck)
        return;

// =====================================================================
//  v2.15.1 — FIX «LA FLECHA TRASPASA LA PARED»: VUELO LOCAL CON
//  BARRIDO. Antes la posicion la integraba el server (que NO conoce
//  el mapa) y llegaba por UDP como teleports de 14 px: en las rafagas
//  de paquetes la posicion que caia DENTRO de la pared se sobrescribia
//  por una que ya la habia pasado -> el evento de colision de GM (que
//  solo dispara si hay solape al FINAL del frame) jamas se disparaba y
//  la flecha la atravesaba. Ahora cada cliente mueve SU copia con
//  sub-pasos de FW_ARROW_SWEEP px y busqueda binaria del punto exacto
//  de contacto: la flecha nunca atraviesa nada y se clava clavando la
//  punta FW_ARROW_BURY px dentro (visual de flecha incrustada).
//  Todos los clientes parten del mismo spawn (TCP fiable: x, y, dir) y
//  a la misma velocidad (FW_ARROW_FLIGHT = FWBOLT_SPEED del server).
//  El primer cliente que la ve clavarse reporta CLIENT_FWBOLT_HIT
//  tipo 1 y el server fija la posicion para todos (estado 3).
// =====================================================================
var _dir = sign(image_xscale);

if(_dir != 0)
{
        // wrap del mapa YouCan'tRun (mapa 13 del server), igual que
        // fwbolt_tick: la flecha da la vuelta al nivel
        if(room == room_youcantrun)
        {
                if(x < 0)
                        x = 3648;
                else if(x > 3648)
                        x = 0;
        }
        else if(x <= 0)
        {
                // limite izquierdo del server (pos.x <= 0 = despawn):
                // la retiramos tambien aqui para no divergir
                _destroy();
                return;
        }

        // disparo a bocajarro: nacio ya dentro de un solido
        if(place_meeting(x, y, obj_solid_parent))
        {
                isStuck = true;
                scr_fw_arrow_spawn(fwId, x, y, image_xscale);
                net_fw_bolt_hit(fwId, 1, round(x), round(y));
                instance_destroy();
                return;
        }

        // barrido del frame: FW_ARROW_FLIGHT px en sub-pasos
        var _todo = FW_ARROW_FLIGHT;

        while(_todo > 0)
        {
                var _paso = min(FW_ARROW_SWEEP, _todo);
                _todo -= _paso;

                if(place_meeting(x + _paso * _dir, y, obj_solid_parent))
                {
                        // punto exacto de contacto: busqueda binaria de
                        // 0,5 px (el ultimo x que NO toca el solido)
                        var _lo = 0;
                        var _hi = _paso;
                        while(_hi - _lo > 0.5)
                        {
                                var _mid = (_lo + _hi) / 2;
                                if(place_meeting(x + _mid * _dir, y, obj_solid_parent))
                                        _hi = _mid;
                                else
                                        _lo = _mid;
                        }

                        // clavar la punta FW_ARROW_BURY px dentro
                        x += (_lo + FW_ARROW_BURY) * _dir;

                        isStuck = true;
                        scr_fw_arrow_spawn(fwId, x, y, image_xscale);
                        net_fw_bolt_hit(fwId, 1, round(x), round(y));
                        instance_destroy();
                        return;
                }

                x += _paso * _dir;
        }
}

if(!instance_exists(global.player))
        return;

if(place_meeting(x, y, global.player))
{
        if(global.player.isDead)
                return;

        // La flecha solo golpea al bando del EXE (killer / esbirros):
        // a los supervivientes los atraviesa (es un arma anti-exe).
        // Si Fleetway SE VUELVE exe (demonizada) la flecha hace daño
        // real (dmg 20) y JAMAS stunea a un superviviente.
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
        {
                // EXE invisible no puede ser tocado (regla del laser)
                if(global.character == CHARACTER_EXE && global.player.invisTimer > 0)
                        return;

                if(global.player.hurttime > 0)
                        return;

                // dmg 0 = stun (Fleetway superviviente);
                // dmg 20 = daño real (demonizada, revivalTimes >= 2)
                if(dmg <= 0)
                {
                        // v2.15 («La Torre»): stun de 3 s al EXE con reduccion
                        // acumulativa por stuns CONTINUOS de flecha (-17,5% cada
                        // vez, tope 50%; reset tras 7 s sin stuns de flecha —
                        // global.fwArrowStunStack/Decay, los descuenta obj_level).
                        // Contra ESBIRROS (demonizados locales) dura siempre los
                        // 3 s completos: la reduccion solo la sufre el EXE.
                        var _stun = FW_ARROW_STUN;

                        if(global.character == CHARACTER_EXE)
                        {
                                var _red = min(FW_ARROW_STUN_STEP * global.fwArrowStunStack, FW_ARROW_STUN_CAP);
                                _stun = max(1, round(FW_ARROW_STUN * (1.0 - _red)));
                                global.fwArrowStunStack = min(global.fwArrowStunStack + 1, 3);
                                global.fwArrowStunDecay = FW_ARROW_STUN_RESET;
                        }

                        global.player.isHurt = false;
                        global.player.shockedTimer = _stun;
                        audio_play_sound(snd_exe_stun, 0, false);
                        net_sound_emit(snd_exe_stun);

                        // reporte de stats igual que el laser (estado 3 = exe stun)
                        var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                        buffer_write(buffer, buffer_u8, 3);
                        send_server_tcp(buffer);
                }
                else
                {
                        // daño real (canal estandar): exeSource=true
                        scr_player_hurt(dmg, -sign(global.player.x - x) * 3, -4, snd_hurt, spr_blood2, false, true);

                        var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                        buffer_write(buffer, buffer_u8, 2);
                        buffer_write(buffer, buffer_u16, obj_netclient.nid);
                        buffer_write(buffer, buffer_u16, dmg);
                        buffer_write(buffer, buffer_u16, global.player.hp);
                        send_server_tcp(buffer);
                }

                _destroy();
        }

        return;
}
