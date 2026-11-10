// v1 OPTIONS MORE: WEATHER off = sin gotas de lluvia (y sin su sonido)
if(!obj_config.optWeather)
{
	if(audio_is_playing(snd_rain))
		audio_stop_sound(snd_rain);
	
	return;
}

for(var i = 0; i < (optimize ? 1 : 3); i++)
	instance_create_depth(obj_camera.x + random_range(-120, 560), obj_camera.y - 1, -200, obj_ghz_rain);
	
for(var i = 0; i < (optimize ? 1 : 2); i++)
	instance_create_depth(obj_camera.x + 481, obj_camera.y + random_range(-120, 350), -200, obj_ghz_rain);

for(var i = 0; i < (optimize ? 1 : 3); i++)
	instance_create_depth(obj_camera.x + random_range(-120, 560), obj_camera.y - 1, -200, obj_ghz_rain);
	
for(var i = 0; i < (optimize ? 1 : 2); i++)
	instance_create_depth(obj_camera.x + 481, obj_camera.y + random_range(-120, 350), -200, obj_ghz_rain);