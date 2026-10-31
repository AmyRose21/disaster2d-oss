if(isBreaking && image_index >= image_number - 1)
{
        instance_destroy();
        return;
}

if(!instance_exists(global.player))
        return;

// el fuego arde mientras viaja
if(!isBreaking && floor(x) mod 6 == 0)
        net_quick_effect(x - 6 * dir, y, spr_shard_sparkle);

if(place_meeting(x, y, global.player))
{
        if(isBreaking)
                return;

        if(global.player.isDead)
                return;

        // solo aturde al lado del EXE (killer / esbirros)
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
        {
                // EXE invisible no puede ser tocado (regla del laser)
                if(global.character == CHARACTER_EXE && global.player.invisTimer > 0)
                        return;

                if(global.player.hurttime > 0)
                        return;

                // escudo de Sally: se rompe y salva
                if(global.character == CHARACTER_SALLY)
                {
                        if(global.player.shieldTimer > 0)
                        {
                                global.player.isHurt = true;
                                global.player.hurttime = 60;
                                global.player.shieldTimer = 0;

                                audio_play_sound(snd_sally_shieldbreak, 0, false);
                                net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                                net_sound_emit(snd_sally_shieldbreak);

                                _destroy();
                                return;
                        }

                        global.player.isSliding = false;
                }

                // stun de 2 s (el fuego de Blaze)
                global.player.shockedTimer = 60 * 2;
                global.player.xspd = -sign(x - global.player.x) * 4;
                global.player.yspd = -2;
                global.player.isGrounded = false;
                global.player.isAttacking = false;

                audio_play_sound(snd_exe_stun, 0, false);
                net_sound_emit(snd_exe_stun);

                if(global.character == CHARACTER_EXE)
                        scr_exe_stunsound();

                // stats: Blaze aturdio al killer
                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(character != CHARACTER_BLAZE)
                                        continue;

                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 1);
                                buffer_write(pak, buffer_u16, obj_netclient.nid);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u8, 2);
                                send_server_tcp(pak);
                                break;
                        }
                }

                _destroy();
                return;
        }
}
