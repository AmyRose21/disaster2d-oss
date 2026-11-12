// v1 POSTFX: bloom + grading a pantalla completa (persistente, F9 lo alterna)
if(!instance_exists(obj_postfx))
	instance_create_depth(0, 0, -99999, obj_postfx);

if(!global.init)
{
	global.init = true;
}
else
{
	room_goto(room_menu);
	return;
}

display_reset(0, true);
start = false;
ind = 0;

if(os_type == os_android)
{
	surface_resize(application_surface, 480, 270);
	window_set_size(480, 270);
	window_set_fullscreen(true);
}

image_speed = 0;