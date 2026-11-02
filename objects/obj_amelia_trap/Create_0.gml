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
//  v3.0 (balance + «Genio Malvado»):
//   * La trampa CAMBIA DE BANDO con su duena: si Amelia se demonizo,
//     sus trampas las pisan los SUPERVIVIENTES (stun + slow, SIN
//     ceguera — pedido: "las trampas no pueden cegar a los
//     supervivientes"). La duena se lee del puppet de Amelia (patron
//     del obj_eggtrack con su Eggman).
//   * Los ESBIRROS (minions) tambien activan las trampas del bando
//     superviviente y reciben 2 s MAS de ceguera que el exe real.
//   * EGGMAN puede MEJORARLA con 5 anillos (tecla V): +25% en stun /
//     slow / ceguera, contorno dorado (Draw_0) y, al caer pisada por
//     el bando EXE, el RASTREADOR revela a la victima a todos los
//     supervivientes (SERVER_TRACKER_PING desde el server).
// =====================================================================
life = 60 * 60;    // vida visual (el server manda el remove real)
triggerSent = false;
upgraded = false;  // v3.0 «Genio Malvado»: llega con el state 3 del server
// v3.1 (estilo RESCATE de Vanilla): barra de mejora del Genio —
// upgShow/upgProg llegan del server (SERVER_EGG_UPGRADE_STATUS /
// SERVER_EGG_UPGRADE_PROGRESS) y upgOver es el prompt para el Eggman
// local (1 = puede pagar, 0 = faltan anillos), patron reviveObj.
upgShow = false;
upgProg = 0;
upgOver = -1;

function amelia_trap_trigger()
{
        if(triggerSent)
                return;

        triggerSent = true;

        // v3.0: bonus de la mejora del Genio Malvado (+25%) y lado de
        // la victima (exe real / esbirro / superviviente con Amelia
        // demonizada) para decidir la ceguera.
        var _up = upgraded;
        var _exeSide = global.character == CHARACTER_EXE || global.player.revivalTimes >= 2;

        // STUN 3 s + slow 3.5 s al salir del stun: la victima es el
        // jugador LOCAL (cada cliente es autoridad del suyo, patron
        // de la banana). El slow se pide por el TOTAL (stun + slow)
        // porque durante el stun no hay movimiento: los 3 primeros
        // segundos del debuff quedan "tapados" por el propio stun y
        // los 3.5 restantes corren justo despues, como en el TD.
        // v3.0: mejorada -> 3.75 s de stun y 8.125 s de slow total.
        if(instance_exists(global.player) && global.player.shockedTimer <= 0)
        {
                global.player.shockedTimer = round(60 * 3 * (_up ? EGG_GENIUS_BONUS : 1));
                global.player.isAttacking = false;
                global.player.xspd = 0;

                scr_player_slow((3.5 + 3) * (_up ? EGG_GENIUS_BONUS : 1));

                audio_play_sound(snd_exe_stun, 0, false);
                net_sound_emit(snd_exe_stun);
        }

        // ECLIPSE (v2.13): la ceguera pisa aunque el stun no aplique
        // (shockedTimer ya > 0 por otro stun): la trampa igual CEGO.
        // v3.0: SOLO al bando EXE (exe real o esbirro). Los ESBIRROS
        // se quedan ciegos 2 s MAS que el exe. Los SUPERVIVIENTES
        // JAMAS: aunque pisen una trampa de una Amelia demonizada
        // (ese caso hace stun + slow, pero sin velo oscuro).
        if(_exeSide)
        {
                var _blind = AMELIA_ECLIPSE_TIME * (_up ? EGG_GENIUS_BONUS : 1);

                if(global.character != CHARACTER_EXE)
                        _blind += 60 * 2;    // esbirro: +2 s de ceguera

                global.eclipseTimer = round(_blind);
        }

        net_amelia_trap_trigger(nid);
}
