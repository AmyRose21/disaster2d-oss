if(!instance_exists(global.player))
{
        ringVisible = false;
        exeVisible = false;
        visible = false;
        return;
}

// Demonizada (revivalTimes >= 2): el juego ya le daria la flecha
// estandar (obj_demon_indicator). Vanilla JAMAS se demoniza (regla
// canonica del server + paciencia/moribunda), asi que esto es solo
// red de seguridad.
if(global.player.revivalTimes >= 2)
{
        ringVisible = false;
        exeVisible = false;
        visible = false;
        return;
}

// --- SENSOR 1: LA SALIDA (flecha verde) ---
// Activa desde el momento en que el anillo de escape (obj_bigring)
// aparece en el mapa: Vanilla siempre sabe donde esta la salida.
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

// --- SENSOR 2: EL EXE (flecha ROJA) ---
// Apunta SIEMPRE a donde esta el EXE REAL (su puppet; nunca minions,
// clones ni demonizados, que conservan su personaje original).
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

// El evento Draw GUI de este objeto solo corre con visible = true (nace
// en false en el .yy): hay que re-activarlo cada frame que toque.
visible = (ringVisible || exeVisible);
