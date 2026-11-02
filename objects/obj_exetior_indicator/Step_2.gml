if(!instance_exists(global.player))
	return;

target = noone;
redRings = false;

if(instance_exists(obj_player_puppet))
{
	var dist = 999999999;
	for(var i = 0; i < instance_number(obj_player_puppet); i++)
	{
		var inst = instance_find(obj_player_puppet, i);
		
		if(inst.hp <= 0 || inst.revivalTimes >= 2)
			continue;
			
		// v2.13 (LUNA de Sol y Luna): velo de gracia de Amelia oculta.
		// Durante los primeros 3 s tras ocultarse, ni el indicador ni los
		// sensores del EXE la marcan (como si se hubiera esfumado); pasado
		// el velo vuelve a ser indicable (su cuerpo jamas: invisible EXE).
		if(inst.character == CHARACTER_AMELIA && inst.isHiding && inst.lunaGrace > 0)
			continue;
		
		if(inst.hasRedRing && (global.character != CHARACTER_EXE || global.player.invisTimer <= 0))
		{
			redRings = true;
			target = inst;
			break;
		} 
		
		if(dist > point_distance(global.player.x, global.player.y, inst.x, inst.y))
		{
			dist = point_distance(global.player.x, global.player.y, inst.x, inst.y);
			target = inst;
		}
	}
	
	if(target != noone)
		image_angle = point_direction(global.player.x, global.player.y, target.x, target.y);
}

visible = showTimer > 0 || redRings;

if(showTimer > 0)
	showTimer--;