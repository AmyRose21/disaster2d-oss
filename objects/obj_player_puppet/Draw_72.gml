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
        // PARRY (tecla C): estados 60-64, se resuelven ANTES que los del
        // golpe (60+ entraria en el rango del ataque aereo). Mismo
        // escaneo por nombre + fallback, asi el puppet muestra la misma
        // animacion de parry que ve el Sonic local.
        if(character == CHARACTER_SONIC && scr_parry_state_is(state))
        {
                var _pspr = scr_parry_sprite(state);

                if(_pspr != -1)
                        sprite_index = _pspr;

                return;
        }

        // ABRAZO COMBINADO (interaccion Amy Canon + Sonic): estados 65
        // (Sonic abrazado) y 24 (Amy abrazando). Ninguno va por el array
        // (el 65 entraria en el rango del golpe aereo): el cuerpo de
        // ambos lo gestionan sus Draw_0 (el de Amy dibuja el sprite
        // combinado en el punto medio; el de Sonic no dibuja nada).
        if(character == CHARACTER_SONIC && state == SONIC_HUGGED)
        {
                sprite_index = spr_sonic_idle;
                return;
        }

        if(character == CHARACTER_AMY_CANON && state == AMY_CANON_HUG)
        {
                sprite_index = spr_amy_hug_canon;
                return;
        }

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