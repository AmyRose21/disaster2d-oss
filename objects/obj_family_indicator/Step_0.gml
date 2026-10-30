if(!instance_exists(global.player))
{
        visible = false;
        return;
}

// solo los clientes de Vanilla y de Cream llevan esta flecha
if(global.character != CHARACTER_VANILLA && global.character != CHARACTER_CREAM)
{
        visible = false;
        return;
}

// demonizada (Cream): cambia de bando, flecha fuera
if(global.player.revivalTimes >= 2)
{
        visible = false;
        return;
}

// a quien senalo: la otra de la pareja madre-hija
var _target = noone;
var _want = global.character == CHARACTER_VANILLA ? CHARACTER_CREAM : CHARACTER_VANILLA;

if(instance_exists(obj_player_puppet))
{
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
                var inst = instance_find(obj_player_puppet, i);

                if(inst.isInactive || inst.character != _want)
                        continue;

                _target = inst;
                break;
        }
}

// sin la otra, o cerca (menos de VANILLA_MADRE_HIJA_DIST): nada que senalar
if(_target == noone || distance_to_object(_target) < VANILLA_MADRE_HIJA_DIST)
{
        visible = false;
        return;
}

famAngle = point_direction(global.player.x, global.player.y, _target.x, _target.y);
visible = true;
