function scr_exe_stunsound()
{
        switch(global.exeCharacter)
        {
                case EXE_ORIGINAL:
                        audio_play_sound(snd_exe_stun2, 0, false);
                        net_sound_emit(snd_exe_stun2);
                        break;
                        
                case EXE_CHAOS:
                        audio_play_sound(snd_chaos_stun, 0, false);
                        net_sound_emit(snd_chaos_stun);
                        break;
                        
                case EXE_EXELLER:
                        audio_play_sound(snd_exeller_stun, 0, false);
                        net_sound_emit(snd_exeller_stun);
                        break;
                        
                case EXE_EXETIOR:
                        audio_play_sound(snd_exetior_stun, 0, false);
                        net_sound_emit(snd_exetior_stun);
                        break;

                // v4.7: el stun de Metal Amy suena con snd_metal_stun (ultima
                // entrada de global.net_snds, posicion real 115; antes no
                // existia el case).
                case EXE_METALAMY:
                        audio_play_sound(snd_metal_stun, 0, false);
                        net_sound_emit(snd_metal_stun);
                        break;
        }
}