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
