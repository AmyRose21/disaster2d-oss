fade = 0;
fadeB = false;
bgnew = background_dotdotdot;
state = true;
BG = layer_background_get_id(layer_get_id("Background"));

fade2 = 0;
fade3 = 0;

depth = -0999;

audio_sound_gain(mus_dotdotdot, obj_config.musicVolume * 0.1, 0); // v1 OPTIONS MORE
audio_play_sound(mus_dotdotdot, 0, true);
audio_sound_gain(mus_dotdotdot2, 0, 0);
audio_play_sound(mus_dotdotdot2, 0, true);