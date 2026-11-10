global.music = -1;
global.musicGain = 1;

function scr_play_music(bid)
{
        if(global.music != -1)
                scr_stop_music();
        
        global.music = audio_play_sound(bid, 0, true);
        audio_sound_gain(global.music, 1, 0);
}

function scr_stop_music()
{
        audio_stop_sound(global.music);
        global.music = -1;
}

function scr_stop_map_music()
{
        // FIX LMS musica de mapa (v1): "...", Wood Zone (su rework) y Act9
        // tocan su musica con audio_play_sound DIRECTO (capas con crossfade
        // propias del mapa) y NO pasan por global.music — scr_play_music/
        // scr_stop_music no las alcanzan. Cualquier cosa que ponga musica
        // "de verdad" (show LMS, final de ronda) tiene que silenciarlas
        // a mano, o suenan DOS canciones a la vez.
        //
        // Room condicionado (mismo estilo que el spawn del anillo): estas
        // capas solo pueden estar sonando dentro de estos rooms. Wood Zone
        // arrastra las layers de mus_dotdotdot porque monta obj_dotdotdot_i.
        if(room == room_dotdotdot || room == room_woodzone)
        {
                audio_stop_sound(mus_dotdotdot);
                audio_stop_sound(mus_dotdotdot2);
        }
        else if(room == room_act9)
        {
                audio_stop_sound(mus_act9);
                audio_stop_sound(mus_act9_chase);
        }
}