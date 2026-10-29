//Создать игрока и камеру
if(global.player == noone)
	return;

if(!instance_exists(global.player) && global.character != CHARACTER_EXE)
{
	var inst = instance_find(obj_spawnpoint, irandom(instance_number(obj_spawnpoint) - 1));
	instance_create_depth(inst.x, inst.y-18, 0, global.player);
	instance_create_depth(inst.x, inst.y, 0, obj_camera);
	instance_create_depth(inst.x, inst.y, 0, obj_level);
	instance_create_depth(inst.x, inst.y-18, 0, obj_surv_indicator);

	// CARRY (v1): controlador de la mecanica de llevar aliados volando
	// (Tails/Cream con un compañero colgado, estilo liana). Se crea
	// DESPUES del jugador para que su End Step corra despues del suyo
	// (el snap al portador tiene que ser la ultima palabra del frame).
	// Idempotente por si acaso.
	if(!instance_exists(obj_carry_controller))
		instance_create_depth(inst.x, inst.y, 0, obj_carry_controller);

	if(room == room_ravinemist)
		instance_create_depth(inst.x, inst.y, 0, obj_surv_ringindicator);
	
	if(obj_unlockables.pet != -1)
	{
		var pet = instance_create_depth(inst.x, inst.y, 0, global.pets[clamp(obj_unlockables.pet, 0, 7)]);
		pet.secret = obj_unlockables.pet - 7;
	}
}