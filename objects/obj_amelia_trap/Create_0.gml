// =====================================================================
//  v2.4 — AMELIA: TRAMPA (cliente). La vida maxima (60 s) la lleva
//  el SERVER (entities/AmeliaTrap.c): al agotarse la retira con
//  SERVER_AMELIA_TRAP_STATE 1 y aqui se desvanece sola por si el
//  paquete se pierde. Cuando alguien del lado del EXE la pisa, ESTE
//  cliente (el de la victima) aplica sobre su propio jugador el STUN
//  de 3 s + el debuff de velocidad (-40%) de 3.5 s al salir del stun,
//  y avisa con CLIENT_AMELIA_TRAP_TRIGGER; el server la revienta a
//  todos con state 2 (efecto y sonido para el resto).
//  v2.13 («Sol y Luna» — ECLIPSE): el stun ARRASTRA CEGUERA. La
//  victima (siempre del lado del EXE: el Step solo dispara con
//  _exeSide) deja de ver a CUALQUIER superviviente durante
//  AMELIA_ECLIPSE_TIME frames (4 s): los puppets supervivientes no se
//  dibujan en su cliente (obj_player_puppet/Draw_0 y Draw_64) y un
//  velo oscuro cubre su pantalla (obj_level/Draw_64). Misma autoridad
//  que el propio stun: el cliente de la victima sobre si mismo. Cero
//  paquetes nuevos.
// =====================================================================
life = 60 * 60;    // vida visual (el server manda el remove real)
triggerSent = false;

function amelia_trap_trigger()
{
        if(triggerSent)
                return;

        triggerSent = true;

        // STUN 3 s + slow 3.5 s al salir del stun: la victima es el
        // jugador LOCAL (cada cliente es autoridad del suyo, patron
        // de la banana). El slow se pide por el TOTAL (stun + slow)
        // porque durante el stun no hay movimiento: los 3 primeros
        // segundos del debuff quedan "tapados" por el propio stun y
        // los 3.5 restantes corren justo despues, como en el TD.
        if(instance_exists(global.player) && global.player.shockedTimer <= 0)
        {
                global.player.shockedTimer = 60 * 3;
                global.player.isAttacking = false;
                global.player.xspd = 0;

                scr_player_slow(3.5 + 3);

                audio_play_sound(snd_exe_stun, 0, false);
                net_sound_emit(snd_exe_stun);
        }

        // ECLIPSE (v2.13): la ceguera pisa aunque el stun no aplique
        // (shockedTimer ya > 0 por otro stun): la trampa igual CEGO.
        // El velo se dibuja solo si ESTE cliente es del bando EXE
        // (obj_level/Draw_64 lo filtra), y la victima de la trampa
        // siempre lo es.
        global.eclipseTimer = AMELIA_ECLIPSE_TIME;

        net_amelia_trap_trigger(nid);
}
