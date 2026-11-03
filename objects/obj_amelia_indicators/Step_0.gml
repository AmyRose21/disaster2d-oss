if(!instance_exists(global.player))
{
        ringVisible = false;
        visible = false;
        return;
}

// Demonizada (revivalTimes >= 2): en ese caso el juego ya le da la
// flecha estandar que apunta al exe (obj_demon_indicator), asi que su
// marca de la salida se apaga para no duplicar capas (red de seguridad,
// mismo patron que obj_amycanon_indicators).
if(global.player.revivalTimes >= 2)
{
        ringVisible = false;
        visible = false;
        return;
}

// --- MARCA DE LA SALIDA (flecha verde, VERSION LIMITADA) ---
// Amy Canon ve la salida SIEMPRE que el anillo de escape (obj_bigring)
// existe, sin condiciones (obj_amycanon_indicators). Amelia (v4.5): la
// "siente" solo si esta a <= AMELIA_EXIT_SENSE px — y encima PARPADEA
// (ver Draw_64): menos efectiva que la de Amy Canon, como pidio el
// diseno del buff. Flecha roja del exe NO hay: para eso ya esta su
// Auravisión (obj_amelia_auras, 350 px).
ringVisible = false;
if(instance_exists(obj_bigring))
{
        var ring = instance_nearest(global.player.x, global.player.y, obj_bigring);
        if(ring != noone && point_distance(global.player.x, global.player.y, ring.x, ring.y) <= AMELIA_EXIT_SENSE)
        {
                ringAngle = point_direction(global.player.x, global.player.y, ring.x, ring.y);
                ringVisible = true;
        }
}

// Como los indicadores originales del juego, el evento Draw GUI de este
// objeto solo corre cuando visible esta en true (nace apagado en su
// .yy): hay que activarlo cada frame que haya flecha que mostrar.
visible = ringVisible;
