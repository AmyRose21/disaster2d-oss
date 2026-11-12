if(isBreaking && image_index >= image_number - 1)
{
        instance_destroy();
        return;
}

// throttle local de informes de rebote (v2.9): mientras llega el
// arreglo del server no volvemos a informar el mismo choque
if(bounceCd > 0)
        bounceCd--;

if(!instance_exists(global.player))
        return;

// el fuego arde mientras viaja
if(!isBreaking && floor(x) mod 6 == 0)
        net_quick_effect(x - 6 * dir, y, spr_shard_sparkle);

// v4.3 — FIX «EL FUEGO DE UNA BLAZE DEMONIZADA LA ESTUNEABA A ELLA
// MISMA»: el contacto solo miraba el bando del jugador LOCAL, asi que
// una Blaze demonizada (revivalTimes >= 2) que disparaba su propia
// bola quedaba aturdida 2 s por ella y la bola JAMAS tocaba a un
// superviviente (le atravesaba). Mismo modelo que la trampa de Amelia
// (v3.0): la bola pertenece al BANDO DE SU DUEÑA, que se lee del
// puppet de la Blaze en este cliente (o de mi propio revivalTimes si
// yo soy la Blaze). El dueño y los de su bando la atraviesan;
// el bando contrario recibe el efecto.
//   Blaze superviviente -> aturde 2 s al killer/esbirros (como siempre).
//   Blaze demonizada    -> aturde 2 s a los SUPERVIVIENTES.
var _blazeDemon = false;

if(global.character == CHARACTER_BLAZE && instance_exists(global.player))
        _blazeDemon = global.player.revivalTimes >= 2;
else if(instance_exists(obj_player_puppet))
{
        with(obj_player_puppet)
        {
                if(character != CHARACTER_BLAZE)
                        continue;

                _blazeDemon = isDemonized;
        }
}

var _blazeOppSide = !global.player.isDead && (
        (_blazeDemon && global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
        || (!_blazeDemon && (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)));

if(_blazeOppSide && place_meeting(x, y, global.player))
{
        if(isBreaking)
                return;

        if(global.player.isDead)
                return;

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

        // v4.3: dueña demonizada -> la bola es un ARMA DEL EXE: daño
        // real de 20 (canal estandar de la flecha demonizada, con
        // exeSource=true para el parry de Sonic) + reporte de stats
        // del golpe al server. Dueña superviviente -> el stun de 2 s
        // de siempre.
        if(_blazeDemon)
        {
                scr_player_hurt(20, -sign(global.player.x - x) * 3, -4, snd_hurt, spr_blood2, false, true);

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(character != CHARACTER_BLAZE)
                                        continue;

                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 2);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u16, 20);
                                buffer_write(pak, buffer_u16, global.player.hp);
                                send_server_tcp(pak);
                                break;
                        }
                }

                _destroy();
                return;
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
