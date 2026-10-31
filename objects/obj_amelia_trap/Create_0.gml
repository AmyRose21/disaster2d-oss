// =====================================================================
//  v2.4 — AMELIA: TRAMPA (cliente). La vida maxima (60 s) la lleva
//  el SERVER (entities/AmeliaTrap.c): al agotarse la retira con
//  SERVER_AMELIA_TRAP_STATE 1 y aqui se desvanece sola por si el
//  paquete se pierde. Cuando alguien del lado del EXE la pisa, ESTE
//  cliente (el de la victima) aplica sobre su propio jugador el STUN
//  de 3 s + el debuff de velocidad (-40%) de 3.5 s al salir del stun,
//  y avisa con CLIENT_AMELIA_TRAP_TRIGGER; el server la revienta a
//  todos con state 2 (efecto y sonido para el resto).
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

        net_amelia_trap_trigger(nid);
}
