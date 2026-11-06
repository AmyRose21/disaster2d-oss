if(sprite_index == spr_eggtrack_destroy && image_index >= image_number - 1)
{
        instance_destroy();
        return;
}

if(!instance_exists(global.player))
{
        upgOver = -1;
        return;
}

depth = global.player.depth - 2;

// v3.1: prompt del GENIO para el Eggman local (patron reviveObj.over del
// rescate de Vanilla): 1 = encima de ESTE sensor con anillos, 0 = faltan
// anillos. Solo corre en el cliente del Eggman; la barra upgShow la ven
// todos los supervivientes (Draw_0).
upgOver = -1;

if(global.character == CHARACTER_EGGMAN
&& global.player.revivalTimes < 2 && !global.player.isDead
&& !upgraded && !activated
&& global.player.geniusTarget == nid && global.player.geniusTargetType == 0)
        upgOver = global.player.rings >= EGG_GENIUS_SENSOR_COST ? 1 : 0;

if(place_meeting(x, y, global.player) && !activated)
{
        if(global.character == CHARACTER_EGGMAN)
                return;
                
        var isDemon = false;
        if(global.character == CHARACTER_EGGMAN)
        {
                isDemon = global.player.revivalTimes >= 2;
        }
        else
        {
                with(obj_player_puppet)
                {
                        if(character != CHARACTER_EGGMAN)
                                continue;
                                
                        isDemon = isDemonized;
                }
        }
        
        if(global.player.isDead)
                return;
        
        if(isDemon && (global.player.revivalTimes >= 2 || global.character == CHARACTER_EXE))
                return;
                
        if(!isDemon && (global.player.revivalTimes < 2 && global.character != CHARACTER_EXE))
                return;
                
        // v3.0 («Genio Malvado»): sensor MEJORADO -> el slow dura +25%
        // (3.75 s en vez de 3 s). Mismo calculo para el exe (alarm 4)
        // y para esbirros/supervivientes (scr_player_slow).
        var _upMul = upgraded ? EGG_GENIUS_BONUS : 1;
        var _slowT = 3 * _upMul;
        var _exeT = round(60 * 3 * _upMul);

        switch(global.character)
        {
                case CHARACTER_EXE:
                        
                        switch(global.exeCharacter)
                        {
                                case EXE_ORIGINAL:
                                        global.player.isSlow = true;
                                        global.player.acc = (EXE_ACC * (100-30)) / 100;
                                        global.player.maxHSpeed = (EXE_MAXSPEED * (100-30)) / 100;
                                        global.player.alarm[4] = _exeT;
                                        break;
                                        
                                case EXE_CHAOS:
                                        global.player.isSlow = true;
                                        global.player.acc = (CHAOS_ACC * (100-30)) / 100;
                                        global.player.maxHSpeed = (CHAOS_MAXSPEED * (100-30)) / 100;
                                        global.player.alarm[4] = _exeT;
                                        break;
                                        
                                case EXE_EXETIOR:
                                        global.player.isSlow = true;
                                        global.player.acc = (EXETIOR_ACC * (100-30)) / 100;
                                        global.player.maxHSpeed = (EXETIOR_MAXSPEED * (100-30)) / 100;
                                        global.player.alarm[4] = _exeT;
                                        break;
                                        
                                        
                                case EXE_EXELLER:
                                        global.player.isSlow = true;
                                        global.player.acc = (EXELLER_ACC * (100-30)) / 100;
                                        global.player.maxHSpeed = (EXELLER_MAXSPEED * (100-30)) / 100;
                                        global.player.alarm[4] = _exeT;
                                        break;
                                        
                                // FIX v4.8.1: faltaba Metal Amy — pisaba el
                                // tracker, este se gastaba (activated = true)
                                // y no le aplicaba NADA de slow. Su Alarm_4 ya
                                // restaura sus stats (METALAMY_*).
                                case EXE_METALAMY:
                                        global.player.isSlow = true;
                                        global.player.acc = (METALAMY_ACC * (100-30)) / 100;
                                        global.player.maxHSpeed = (METALAMY_MAXSPEED * (100-30)) / 100;
                                        global.player.alarm[4] = _exeT;
                                        break;
                        }
                        
                        break;
                        
                default:
                        scr_player_slow(_slowT);
                        break;
        }
         
        audio_play_sound(snd_egg_tracker_activate, 0, false);
        net_sound_emit(snd_egg_tracker_activate);
        
        var packet = cpacket_tcp(PacketType.CLIENT_ETRACKER_ACTIVATED);
        buffer_write(packet, buffer_u16, nid);
        send_server_tcp(packet);
        
        activated = true;
}