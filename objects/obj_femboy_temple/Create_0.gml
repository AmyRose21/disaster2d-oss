// Negagen "femboy": su forma flota en su templo mientras haya jugadores en
// partida (patron obj_corpse: char -1 = nadie juega a Negagen aqui, asi que
// su forma siempre "reaparece" en cuanto empieza la ronda).
char = -1;

exists = false;
for (var k = ds_map_find_first(obj_netclient.players); !is_undefined(k); k = ds_map_find_next(obj_netclient.players, k)) 
{
	var plr = ds_map_find_value(obj_netclient.players, k);
	
	if(plr.character == char)
		exists = true;
}