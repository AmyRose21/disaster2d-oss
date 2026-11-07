if(!instance_exists(global.player))
	return;

// ============ FIX ACT9 SPAWN V1: teletransporte SEGURO tras el aplastamiento ============
// El punto clasico de reaparicion (1535, 943) — el suelo central — queda
// DENTRO de un muro al final de la ronda (el techo baja hasta el suelo y
// los muros laterales convergen justo hacia el centro): teletransportar
// ahi era re-aplastamiento instantaneo = 2.a muerte gratis ("aparecen en
// el suelo y la pared los aplasta"). Ahora: si el punto clasico esta
// cubierto por algun muro se escanea el suelo hacia los costados (paso de
// un tile, dentro del mapa); si TODO esta cubierto (fin de ronda) NO se
// teletransporta (el jugador ya cayo herido donde estaba y el revive
// tarda mas que la ronda que queda).
var _tpOK = false;
var _tpX = 1535;
var _tpY = 943;
var _tpCovered = false;
with(obj_act9_wall)
{
	if(_tpX >= bbox_left - 24 && _tpX <= bbox_right + 24
	&& _tpY >= bbox_top - 24 && _tpY <= bbox_bottom + 24)
	{
		_tpCovered = true;
		break;
	}
}
if(!_tpCovered)
	_tpOK = true;
else
{
	for(var _d = 64; _d <= 1536 && !_tpOK; _d += 64)
	{
		for(var _di = 0; _di < 2 && !_tpOK; _di++)
		{
			var _cx = _tpX + (_di == 0 ? -_d : _d);
			
			if(_cx < 64 || _cx > 3008)
				continue;
			
			var _cov = false;
			with(obj_act9_wall)
			{
				if(_cx >= bbox_left - 24 && _cx <= bbox_right + 24
				&& _tpY >= bbox_top - 24 && _tpY <= bbox_bottom + 24)
				{
					_cov = true;
					break;
				}
			}
			
			if(!_cov)
			{
				_tpX = _cx;
				_tpOK = true;
			}
		}
	}
}

if(nid == 1)
{
	if(global.player.x - 8 <= bbox_right)
		global.player.x = ceil(bbox_right) + 8;
		
	if(position_meeting(obj_player_sensorL.x, obj_player_sensorL.y, self))
	{
		if(obj_player_sensorL.coll && obj_player_sensorR.coll)
		{			
			if(!global.player.isDead && global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
			{
				scr_player_instakill();
				audio_play_sound(snd_dead, 0, false);
				net_sound_emit(snd_dead);
				net_quick_effect(global.player.x, global.player.y, spr_blood2, false, sign(x - global.player.x), 0, 0, 1);
			}
				
			if(_tpOK)
			{
				global.player.x = _tpX;
				global.player.y = _tpY;
			}
			global.player.gspd = 0;
			global.player.xspd = 0;
			global.player.yspd = 0;
			global.player.isHurt = false;
			global.player.hurttime = 0;
		}
	}
}

if(nid == 2)
{			
	if(global.player.x+8 >= bbox_left)
		global.player.x = ceil(bbox_left) - 8;
		
	if(position_meeting(obj_player_sensorR.x, obj_player_sensorR.y, self))
	{
		if(obj_player_sensorL.coll && obj_player_sensorR.coll)
		{
			if(!global.player.isDead && global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
			{
				scr_player_instakill();
				audio_play_sound(snd_dead, 0, false);
				net_sound_emit(snd_dead);
				net_quick_effect(global.player.x, global.player.y, spr_blood2, false, sign(bbox_right - global.player.x), 0, 0, 1);
			}
				
			if(_tpOK)
			{
				global.player.x = _tpX;
				global.player.y = _tpY;
			}
			global.player.gspd = 0;
			global.player.xspd = 0;
			global.player.yspd = 0;
			global.player.isHurt = false;
			global.player.hurttime = 0;
		}
	}
}

if(nid == 0)
{
	if(global.player.y <= bbox_bottom + 16)
	{
		if(!global.player.isDead && global.player.y <= bbox_bottom + 8)
		{		
			if(global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
			{
				scr_player_instakill();
				audio_play_sound(snd_dead, 0, false);
				net_sound_emit(snd_dead);
				net_quick_effect(global.player.x, global.player.y, spr_blood2, false, sign(bbox_right - global.player.x), 0, 0, 1);
			}
			
			if(_tpOK)
			{
				global.player.x = _tpX;
				global.player.y = _tpY;
			}
			global.player.gspd = 0;
			global.player.xspd = 0;
			global.player.yspd = 0;
			global.player.isHurt = false;
			global.player.hurttime = 0;
		}
		else
			global.player.y = bbox_bottom + 16;
	}
}