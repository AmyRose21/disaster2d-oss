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

// v3.0: ¿de que bando es la DUENA? Si Amelia se demonizo, sus trampas
// cambian de objetivo: las pisan los SUPERVIVIENTES. Patron exacto del
// obj_eggtrack (lee el puppet de Amelia en este cliente; si YO soy
// Amelia, mi propio revivalTimes).
var _ameliaDemon = false;
if(global.character == CHARACTER_AMELIA)
        _ameliaDemon = global.player.revivalTimes >= 2;
else if(instance_exists(obj_player_puppet))
{
        with(obj_player_puppet)
        {
                if(character != CHARACTER_AMELIA)
                        continue;

                _ameliaDemon = isDemonized;
        }
}

// la pisa el bando CONTRARIO a su duena (jugador LOCAL de este
// cliente): stun + slow sobre la victima y aviso al server (patron
// v2.2 de la bomba; ahora sin radio: solo la victima que la pisa).
//   Amelia superviviente -> la pisa el EXE o un ESBIRRO (minions
//   tambien activan: revivalTimes >= 2).
//   Amelia demonizada    -> la pisa un SUPERVIVIENTE (sin ceguera,
//   esa regla vive en el Create/amelia_trap_trigger).
if(!triggerSent && instance_exists(global.player))
{
        var _exeSide = !global.player.isDead && (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2);
        var _survSide = !global.player.isDead && global.character != CHARACTER_EXE && global.player.revivalTimes < 2;

        if(((!_ameliaDemon && _exeSide) || (_ameliaDemon && _survSide)) && place_meeting(x, y, global.player))
                amelia_trap_trigger();
}
