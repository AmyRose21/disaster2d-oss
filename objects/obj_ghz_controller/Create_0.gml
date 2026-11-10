bgX = 0;
bgY = 0;
lay = layer_get_id("Background");
optimize = os_type == os_android;

// v1 OPTIONS MORE: con WEATHER en off no suena la lluvia
if(obj_config.optWeather)
	audio_play_sound(snd_rain, 0, true);