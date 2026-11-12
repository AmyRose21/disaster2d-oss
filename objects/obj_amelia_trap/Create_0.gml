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

        // v4.3 (fix exe): victima SUPERVIVIENTE (piso una trampa de una
        // Amelia demonizada). Ademas del stun + slow de siempre, la
        // trampa ahora hace DANO REAL.
        var _survSide = !_exeSide && instance_exists(global.player) && !global.player.isDead;

        // STUN 3 s + slow 3.5 s al salir del stun: la victima es el
        // jugador LOCAL (cada cliente es autoridad del suyo, patron
        // de la banana). El slow se pide por el TOTAL (stun + slow)
        // porque durante el stun no hay movimiento: los 3 primeros
        // segundos del debuff quedan "tapados" por el propio stun y
        // los 3.5 restantes corren justo despues, como en el TD.
        // v3.0: mejorada -> 3.75 s de stun y 8.125 s de slow total.
        // v4.3 (fix exe): DANO de la trampa demonizada — DESPUES del
        // stun (si el golpe mata, los salvavidas tipo Nervios de
        // Sonic/la burbuja de Amy Canon limpian el stun por si
        // mismos; el orden evita revivir aturdido). Con ignore=true
        // (pisa aunque la victima tenga i-frames de un golpe
        // anterior: la trampa la coge igual) y exeSource=true (parry
        // de Sonic puede negarlo). scr_player_hurt da los i-frames
        // propios del golpe (hurttime); el refill de los Step durante
        // el stun se neutraliza abajo con el flag.
        if(_survSide)
        {
                var _trapDir = sign(x - global.player.x);
                if(_trapDir == 0)
                        _trapDir = 1;

                scr_player_hurt(AMELIA_TRAP_DAMAGE, _trapDir * 3, -4, snd_hurt, spr_blood2, true, true);

                // stats del golpe (canal 2 de la flecha demonizada,
                // atribuidas a la duena Amelia demonizada)
                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(character != CHARACTER_AMELIA || !isDemonized)
                                        continue;

                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 2);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u16, AMELIA_TRAP_DAMAGE);
                                buffer_write(pak, buffer_u16, max(global.player.hp, 0));
                                send_server_tcp(pak);
                                break;
                        }
                }
        }

        if(instance_exists(global.player) && global.player.shockedTimer <= 0)
        {
                global.player.shockedTimer = round(60 * 3 * (_up ? EGG_GENIUS_BONUS : 1));
                global.player.isAttacking = false;
                global.player.xspd = 0;

                scr_player_slow((3.5 + 3) * (_up ? EGG_GENIUS_BONUS : 1));

                audio_play_sound(snd_exe_stun, 0, false);
                net_sound_emit(snd_exe_stun);

                // v4.7: sonido de stun PROPIO del exe (patron de la bola de
                // fuego de Blaze y del proyectil de Tails: generico + el del
                // personaje; la trampa era la unica fuente de stun que no lo
                // llamaba). Metal Amy -> snd_metal_stun.
                if(global.character == CHARACTER_EXE)
                        scr_exe_stunsound();
        }

        // ECLIPSE (v2.13): la ceguera pisa aunque el stun no aplique
        // (shockedTimer ya > 0 por otro stun): la trampa igual CEGO.
        // v3.0: SOLO al bando EXE (exe real o esbirro). Los ESBIRROS
        // se quedan ciegos 2 s MAS que el exe. Los SUPERVIVIENTES
        // JAMAS: aunque pisen una trampa de una Amelia demonizada
        // (ese caso hace dano + stun + slow, pero sin velo oscuro).
        if(_exeSide)
        {
                var _blind = AMELIA_ECLIPSE_TIME * (_up ? EGG_GENIUS_BONUS : 1);

                if(global.character != CHARACTER_EXE)
                        _blind += 60 * 2;    // esbirro: +2 s de ceguera

                global.eclipseTimer = round(_blind);
        }

        // v4.3 (fix exe): SIN I-FRAMES al caer en la trampa. Todos los
        // Step rellenan hurttime = 60*2 mientras dura el stun "para
        // que no lo rematen", pero en la trampa demonizada eso
        // convertiria el stun de 3 s en 5 s de invulnerabilidad
        // gratis y el exe no podria rematar. Este flag dice a los Step
        // que NO rellenen durante ESTE stun; scr_move_basic lo limpia
        // cuando el stun termina (y con el cualquier resto).
        if(_survSide)
                global.noStunIframes = true;

        net_amelia_trap_trigger(nid);
}
