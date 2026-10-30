// CARRY (v1): End Step, DESPUES de toda la fisica del jugador local
// (input + special + colision + maquina de estados de su Step_2). El
// que cuelga se pega aqui al puppet del portador con la posicion
// FRESCA de este frame; su propio step ya corrio con los controles
// apagados y las velocidades a cero.
if(!instance_exists(global.player))
	return;

var _pl = instance_find(global.player, 0);

if(_pl == noone)
	return;

// jugador nuevo (nueva ronda / nuevo personaje): inicializar las vars
// del carry en la instancia (se crean aqui para no tener que tocar el
// Create de los 9 personajes: cualquier superviviente puede colgar)
if(carryInst != _pl)
{
	carryInst = _pl;
	_pl.carryActive = false;
	_pl.carryPartner = noone;
	_pl.carryCooldown = 0;
}

with(_pl)
{
	// lado del que cuelga: agarrarse / mantenerse / soltarse con Z
	scr_carry_step();
	
	// lado del portador (solo hace algo si soy Tails o Cream):
	// soltar con V (la extension de vuelo vive en los specials)
	scr_carry_carrier_step();
}
