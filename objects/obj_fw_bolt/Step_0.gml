if(isBreaking)
{
        if(image_index >= image_number - 1)
                instance_destroy();
        return;
}

if(!instance_exists(global.player))
        return;

if(place_meeting(x, y, global.player))
{
        if(global.player.isDead)
                return;

        // La flecha solo golpea al bando del EXE (killer / esbirros):
        // a los supervivientes los atraviesa (es un arma anti-exe)
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
        {
                // EXE invisible no puede ser tocado (regla del laser)
                if(global.character == CHARACTER_EXE && global.player.invisTimer > 0)
                        return;

                if(global.player.hurttime > 0)
                        return;

                // dmg 0 = stun 2 s (Fleetway superviviente);
                // dmg 20 = daño real (demonizada, revivalTimes >= 2)
                if(dmg <= 0)
                {
                        global.player.isHurt = false;
                        global.player.shockedTimer = 60 * 2;
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
