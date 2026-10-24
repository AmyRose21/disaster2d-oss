if(!instance_exists(global.player))
{
	ringVisible = false;
	exeVisible = false;
	return;
}

// Demonizada (revivalTimes >= 2): en ese caso el juego ya le da la flecha
// estandar que apunta al exe (obj_demon_indicator), asi que sus sensores
// personales se apagan para no duplicarla. Amy Canon nunca se demoniza
// (la burbuja fuerza revivalTimes = 0); esto es solo red de seguridad.
if(global.player.revivalTimes >= 2)
{
	ringVisible = false;
	exeVisible = false;
	return;
}

// --- SENSOR 1: LA SALIDA (flecha verde) ---
// Activa desde el momento en que el anillo de escape (obj_bigring)
// aparece en el mapa, sin condiciones: Amy Canon siempre sabe donde esta
// la salida. (La version original del juego, obj_surv_ringindicator, solo
// existe en el mapa ravinemist y exige tener 6 shards recogidos.)
ringVisible = false;
if(instance_exists(obj_bigring))
{
	var ring = instance_nearest(global.player.x, global.player.y, obj_bigring);
	if(ring != noone)
	{
		ringAngle = point_direction(global.player.x, global.player.y, ring.x, ring.y);
		ringVisible = true;
	}
}

// --- SENSOR 2: EL EXE (flecha azul, sensor de eggman permanente) ---
// Apunta SIEMPRE a donde esta el exe, como si el rastreador de eggman
// estuviera activado sobre el, pero permanente y visible unicamente para
// Amy Canon. Mismo metodo que la flecha de los demonizados
// (obj_demon_indicator): busca el puppet del exe y lo senala.
exeVisible = false;
if(instance_exists(obj_player_puppet))
{
	for(var i = 0; i < instance_number(obj_player_puppet); i++)
	{
		var inst = instance_find(obj_player_puppet, i);
		
		if(inst.character != CHARACTER_EXE)
			continue;
		
		exeAngle = point_direction(global.player.x, global.player.y, inst.x, inst.y);
		exeVisible = true;
		break;
	}
}