//
// Spawns effect
//
// v1 OPTIONS MORE: con EFFECTS en off los efectos se crean igual (los
// llamadores configuran la instancia devuelta: image_xscale, etc.) pero
// quedan invisibles y mueren solos al acabar su animacion, como siempre.
function scr_effect_quick(xx, yy, effSpr, effSpeed=0.5, fade = false, xspd = 0, yspd = 0)
{
	if(!obj_config.optEffects)
	{
		var _hid = instance_create_depth(xx, yy, 0, fade ? obj_quickeffect_fade : obj_quickeffect);
		_hid.sprite_index = effSpr;
		_hid.visible = false;
		
		if(fade)
			_hid.fadeSpeed = effSpeed;
		else
			_hid.image_speed = effSpeed;
		
		_hid.hspeed = xspd;
		_hid.vspeed = yspd;
		
		if(room == room_act9)
			_hid.image_blend = c_black;
		
		return _hid;
	}

	if(fade)
	{
		var inst = instance_create_depth(xx, yy, 0, obj_quickeffect_fade);
		inst.sprite_index = effSpr;
		inst.fadeSpeed = effSpeed;
		inst.hspeed = xspd;
		inst.vspeed = yspd;
		
		if(room == room_act9)
			inst.image_blend = c_black
			
		return inst;
	}
	else
	{
		var inst = instance_create_depth(xx, yy, 0, obj_quickeffect);
		inst.sprite_index = effSpr;
		inst.image_speed = effSpeed;
		inst.hspeed = xspd;
		inst.vspeed = yspd;
		
		if(room == room_act9)
			inst.image_blend = c_black;
			
		return inst;
	}
}

//
// Spawns effect with fade
//
function scr_effect_fade_quick(xx, yy, effSpr, effSpeed=0.05)
{
	// v1 OPTIONS MORE: mismo gate de EFFECTS que scr_effect_quick
	if(!obj_config.optEffects)
	{
		var _hid = instance_create_depth(xx, yy, 0, obj_quickeffect_fade);
		_hid.sprite_index = effSpr;
		_hid.visible = false;
		_hid.fadeSpeed = effSpeed;
		
		if(room == room_act9)
			_hid.image_blend = c_black;
		
		return _hid;
	}
	
	var inst = instance_create_depth(xx, yy, 0, obj_quickeffect_fade);
	inst.sprite_index = effSpr;
	inst.fadeSpeed = effSpeed;
	
	if(room == room_act9)
		inst.image_blend = c_black;
	
	return inst;
}