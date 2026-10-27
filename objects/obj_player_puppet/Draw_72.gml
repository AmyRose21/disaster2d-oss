if(character == -1)
	return;
	
if(potater)
{
	sprite_index = spr_merfurmu;
	return;
}
	
if(character == CHARACTER_EXE)
{
	var arr = global.player_exesanims;
	
	if(state >= array_length(arr[? exeCharacter]))
		return;
		
	var offset = 0;
	if(slimeMode)
		offset = CHAOS_AIRTRANSFORM+1;
		
	sprite_index = arr[? exeCharacter][state + offset];
}
else
{
	// SONIC: el golpe (tecla X) usa estados dinamicos (>=
	// SONIC_ATK_TIERRA) que no estan en el array: el sprite sale del
	// mismo escaneo por nombre que usa el jugador local (misma
	// variante en los dos clientes).
	if(character == CHARACTER_SONIC && state >= SONIC_ATK_TIERRA)
	{
		var _spr = -1;
		
		if(state >= SONIC_ATK_AIRE)
		{
			var _vi = state - SONIC_ATK_AIRE;
			
			if(_vi < array_length(global.sonicAtkAire))
				_spr = global.sonicAtkAire[_vi];
		}
		else
		{
			var _vi = state - SONIC_ATK_TIERRA;
			
			if(_vi < array_length(global.sonicAtkTierra))
				_spr = global.sonicAtkTierra[_vi];
		}
		
		if(_spr != -1)
			sprite_index = _spr;
		
		return;
	}
	
	var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
	
	if(state >= array_length(arr[? character]))
		return;
	
	sprite_index = arr[? character][state];
}