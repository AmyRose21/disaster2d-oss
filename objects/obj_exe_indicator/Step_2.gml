if(!instance_exists(global.player))
        return;

target = noone;
redRings = false;
scanCount = 0;

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

visible = (global.character != CHARACTER_EXE || global.player.invisTimer > 0 || (global.exeCharacter == 1 && global.player.slimeTimer > 0)) || redRings;

// v4.7 (SCAN de Metal Amy): mientras dura el revelado, una aguja por CADA
// superviviente (la aguja normal de arriba solo marca al mas cercano o al
// del anillo rojo). Mismos filtros que arriba: muertos y esbirros fuera,
// y el velo de gracia de Amelia tambien esconde aqui. Solo corre en el
// cliente del Metal Amy (la instancia la crea su Create_0) y es TODO
// local: los puppets ya viajan sincronizados, cero paquetes nuevos.
if(global.character == CHARACTER_EXE
&& global.exeCharacter == EXE_METALAMY
&& variable_instance_exists(global.player, "scanTimer")
&& global.player.scanTimer > 0
&& instance_exists(obj_player_puppet))
{
        with(obj_player_puppet)
        {
                if(hp <= 0 || revivalTimes >= 2)
                        continue;

                if(character == CHARACTER_AMELIA && isHiding && lunaGrace > 0)
                        continue;

                other.scanAng[other.scanCount] = point_direction(global.player.x, global.player.y, x, y);
                other.scanCount++;
        }
}