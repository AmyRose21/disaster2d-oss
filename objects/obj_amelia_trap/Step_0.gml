// vida visual: si el server ya retiro la trampa (60 s) pero el
// paquete se perdio, desvanecer sola para no quedar colgada
life--;

if(life <= 0)
{
        image_alpha -= 0.05;

        if(image_alpha <= 0)
                instance_destroy();

        return;
}

// la pisa alguien del lado del EXE (jugador LOCAL de este cliente):
// stun + slow sobre la victima y aviso al server (patron v2.2 de la
// bomba; ahora sin radio: solo la victima que la pisa)
if(!triggerSent && instance_exists(global.player))
{
        var _exeSide = !global.player.isDead && (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2);

        if(_exeSide && place_meeting(x, y, global.player))
                amelia_trap_trigger();
}
