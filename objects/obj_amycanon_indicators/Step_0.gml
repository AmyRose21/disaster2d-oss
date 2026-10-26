if(!instance_exists(global.player))
{
        ringVisible = false;
        exeVisible = false;
        visible = false;
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
        visible = false;
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

// --- SENSOR 2: EL EXE (flecha ROJA, spr_indicator) ---
// Apunta SIEMPRE a donde esta el exe, permanente y visible unicamente para
// Amy Canon. Mismo metodo que la flecha de los demonizados
// (obj_demon_indicator): busca el puppet del exe y lo senala.
// SOLO al EXE REAL, nunca a sus minions: los demonizados (revivalTimes >= 2)
// conservan su personaje original (character != CHARACTER_EXE) y los clones
// del exe (obj_exeller_clone) ni siquiera son obj_player_puppet. En 2D no se
// distinguen del exe en pantalla, asi que esta flecha es la unica brujula
// fiable que le queda a Amy.
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

// Como los indicadores originales del juego (obj_surv_ringindicator y
// obj_demon_indicator), el evento Draw GUI de este objeto solo corre
// cuando visible esta en true: hay que activarlo cada frame que haya al
// menos una flecha que mostrar (y apagarlo cuando no). Sin esto el objeto
// nace con visible = false (ver su .yy) y sus flechas nunca se dibujan.
visible = (ringVisible || exeVisible);