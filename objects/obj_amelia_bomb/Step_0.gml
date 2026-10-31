// mecha visual: parpadeo cada vez mas rapido al acercarse el final
fuse--;

if(fuse <= 0)
{
        // el server habra mandado el boom; si el paquete se perdio,
        // desvanecer sola para no quedar colgada
        image_alpha -= 0.05;

        if(image_alpha <= 0)
                instance_destroy();

        return;
}

var _period = 30;

if(fuse < 60 * 2)
        _period = 12;

if(fuse < 30)
        _period = 5;

image_blend = (fuse div _period) mod 2 == 0 ? c_white : c_red;

// el killer la pisa: boom inmediato (lo decide el server)
if(!boomSent && instance_exists(global.player))
{
        var _exeSide = (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2);

        if(_exeSide && place_meeting(x, y, global.player))
                amelia_bomb_boom();
}
