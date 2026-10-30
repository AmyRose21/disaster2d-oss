// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

function hitspark(xpos = x,ypos = x ,xscle = image_xscale,yscle = image_yscale,type = hitspark_light ,audio = []){
	randomize()
	if not instance_exists(hitinit) {instance_create_depth(0,0,0,hitinit);}
	//show_debug_message(string(instance_count))
	global.hitsparklayer += 1
	lyrname = string_concat("hitspark",string(global.hitsparklayer))
	layer_create(-100,lyrname)
	fx = fx_create("_filter_hue")
	fx_set_parameter(fx, "g_HueShift", random_range(0,1));
	fx_set_parameter(fx, "g_HueSaturation", 1.1);
	fx_set_single_layer(fx,true)
	layer_set_fx(lyrname, fx)
	for (i = 0; i < array_length(audio); i += 1)
	{
		audio_play_sound(audio[i][0],10,false,audio[i][1])
	}
	struct = {
	image_xscale : xscle/2,
	image_yscale :	yscle/2,
	sprite_index : type
	}
	instance_create_layer(xpos,ypos,lyrname,hitsparkobject,struct)

	delete struct;
	delete fx;
}