// =====================================================================
//  VANILLA V2 — CHOCOLA Y LAS PASIVAS DE VANILLA (scr_chocola)
//  Toda la logica nueva de Vanilla the Rabbit en un solo script:
//   - CHOCOLA: su chao. Aparece en la PACIENCIA (1ra caida) stuneando
//     al exe 5 s y desde ahi se queda a su lado en la posicion de las
//     mascotas de la tienda; la defiende (65% bloqueo con i-frames +
//     33% ataque cercano) y con la tecla V puede ir a ayudar a CREAM.
//   - FLOAT RUN: 3ra fase de corrida (el tope sube de 11 a 14) con
//     pose propia (spr_vanilla_float_run) e imagenes residuales.
//   - PACIENCIA (1ra caida): 5 s inmune; a los 2 s sale Chocola desde
//     el lado contrario de la pantalla, stunea al exe y vuelve. El
//     tiempo restante se CONGELA hasta que Chocola logra golpearlo.
//   - MORIBUNDA (2da caida en adelante): nunca muere ni se demoniza.
//   - DES-DEMONIZACION: con 15 anillos le quita la demonizacion a un
//     esbirro ATURDIDO que este al alcance (vuelve a 1 caida de
//     re-demonizarse). Usa el paquete CLIENT_VANILLA_DEDEMONIZE.
//  Los eventos de Chocola viajan como "senales de sonido" (mismo
//  patron que el parry y el carry): cero paquetes nuevos. Solo la
//  des-demonizacion usa un paquete propio (necesita al server para
//  limpiar el flag PLAYER_DEMONIZED del esbirro).
// =====================================================================

// --- estados de red propios de Vanilla (indices 17-19 de sus arrays) ---
#macro VANILLA_FLOAT_RUN 17         // pose de la 3ra fase de corrida
#macro VANILLA_PACIENCIA 18         // enojada: inmune 5 s
#macro VANILLA_PACIENCIA_AGOTADA 19 // agotada al final / moribunda

// --- float run (3ra fase de corrida) ---
#macro VANILLA_FLOAT_SPEED 14              // tope de la 3ra fase
#macro VANILLA_FLOAT_RAMP_DELAY (60 * 0.5) // frames "a tope" antes de acelerar
#macro VANILLA_FLOAT_RAMP_ACC 0.09         // v2.11: cuanto sube el tope por frame (era 0.03: la rampa tardaba 6 s impecables y NUNCA llegaba)
#macro VANILLA_FLOAT_HOLD_SPD (CREAM_MAXSPEED - 1.5) // v2.11: cuenta como "a tope" desde 9.5 (los micro-baches del terreno ya no resetean la rampa)
#macro VANILLA_FLOAT_GHOST_EVERY 5         // una imagen residual cada 5 frames
#macro VANILLA_FLOAT_GHOST_FADE 0.07       // fadeo de cada imagen residual

// --- paciencia (1ra caida) ---
#macro VANILLA_PACIENCIA_TIME (60 * 5)        // duracion total
#macro VANILLA_PACIENCIA_CHOCOLA_AT (60 * 3)  // restante al lanzar a Chocola (= 2 s dentro)
#macro VANILLA_PACIENCIA_HUNT_MAX (60 * 8)    // failsafe de caza
#macro VANILLA_PACIENCIA_EXIT (60 * 1)        // pose agotada al final
#macro VANILLA_PACIENCIA_HEAL 100             // vida al recuperar
#macro VANILLA_PACIENCIA_INVULN (60 * 3.5)    // i-frames al recuperar
#macro VANILLA_PACIENCIA_LEVITATE -0.35       // flota si la caida fue a un hoyo
#macro VANILLA_CHOCOLA_PACIENCIA_STUN (60 * 5) // stun del golpe de Chocola

// --- moribunda (2da caida en adelante) ---
#macro VANILLA_MORIBUNDA_TIME (60 * 6)  // tirada en el suelo
#macro VANILLA_MORIBUNDA_HEAL 40        // se levanta con poca vida
#macro VANILLA_MORIBUNDA_INVULN (60 * 3)

// --- chocola: defensa y ataques ---
#macro VANILLA_CHOCOLA_BLOCK_CHANCE 65          // % de bloquear el dano del exe
#macro VANILLA_CHOCOLA_BLOCK_INVULN (60 * 2.5)  // i-frames tras bloquear (semi-transparente)
#macro VANILLA_CHOCOLA_CD (60 * 2.5)            // enfriamiento compartido bloqueo/ataque
#macro VANILLA_CHOCOLA_ATTACK_CHANCE 33         // % de atacar al exe cercano
#macro VANILLA_CHOCOLA_ATTACK_RANGE 90          // px: "el exe se acerca mucho"
#macro VANILLA_CHOCOLA_ATTACK_STUN (60 * 2.5)   // stun del ataque cercano AL EXE
#macro VANILLA_CHOCOLA_MINION_STUN (60 * 3.5)   // v2.11: stun del ataque cercano a un ESBIRRO (mas largo: abre la ventana del rescate de 15 anillos)
#macro VANILLA_CHOCOLA_PROX_CHECK 30            // re-check de proximidad (0.5 s)
#macro VANILLA_CHOCOLA_HUNT_SPEED 14            // velocidad de caza (acelerada)
#macro VANILLA_CHOCOLA_SPEED 7                  // velocidad normal (ida a Cream)
#macro VANILLA_CHOCOLA_RETURN_SPEED 12          // vuelta rapida a casa
#macro VANILLA_CHOCOLA_HEAL_CHANCE 15           // % de curar a Cream AL LLEGAR
#macro VANILLA_CHOCOLA_HEAL_HP 30               // hp de esa curacion

// --- pasivas ---
#macro VANILLA_FORTALEZA_VANILLA_PCT 15 // % de anillos que pierde Vanilla al ser golpeada
#macro VANILLA_FORTALEZA_CREAM_PCT 30   // % que pierde Cream si Vanilla esta en la partida
#macro VANILLA_FORTALEZA_MIN 5          // v17 nerf dueña: perdida minima de anillos (antes 3)
#macro VANILLA_DEDEMON_COST 15          // anillos del RESCATE de esbirro (v2.11)
#macro VANILLA_DEDEMON_RANGE 64         // px: esbirro aturdido al alcance (prompt)
#macro VANILLA_DEDEMON_SEND_CD 2        // v2.11: cadencia de los paquetes de progreso (cada 2 frames = 30/s)
#macro VANILLA_MADRE_HIJA_DIST 400      // px: distancia a la que sale la flecha madre-hija

// --- modos de la mascota (obj_chocola) ---
#macro CHOCOLA_FOLLOW 0       // junto a Vanilla (posicion de mascota)
#macro CHOCOLA_HUNT 1         // volando hacia el exe
#macro CHOCOLA_RETURN 2       // volando de vuelta a Vanilla
#macro CHOCOLA_GO_CREAM 3     // hacia Cream (tecla V)
#macro CHOCOLA_GUARD 4        // custodiando a Cream
#macro CHOCOLA_ATTACK_PAUSE 5 // pose de golpe

// --- eventos de red de chocola (via senales de sonido, ver net_sounds) ---
#macro CHOCOLA_NET_HUNT 0
#macro CHOCOLA_NET_GO_CREAM 1
#macro CHOCOLA_NET_RECALL 2
#macro CHOCOLA_NET_DUTY_DONE 3
#macro CHOCOLA_NET_SUPPORT 4
#macro CHOCOLA_NET_HUNT_SMALL 5 // v2.1: mini-embestida, la ven todos los clientes

// =====================================================================
//  HELPERS DE BUSQUEDA
// =====================================================================

// La unica instancia de Chocola de este cliente (noone si aun no existe)
function scr_chocola_get()
{
    if(instance_exists(obj_chocola))
        return instance_find(obj_chocola, 0);

    return noone;
}

// La "casa" de Chocola: el jugador local si YO soy Vanilla, o su puppet
function scr_chocola_find_home()
{
    if(instance_exists(global.player) && global.character == CHARACTER_VANILLA)
        return global.player;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive || inst.character != CHARACTER_VANILLA)
                continue;

            return inst;
        }
    }

    return noone;
}

// El EXE REAL (nunca clones/minions): jugador local o su puppet
function scr_chocola_find_exe()
{
    if(instance_exists(global.player) && global.character == CHARACTER_EXE)
        return global.player;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive || inst.character != CHARACTER_EXE)
                continue;

            return inst;
        }
    }

    return noone;
}

// v2.11: el ESBIRRO demonizado (minion) mas cercano a "self" sin
// i-frames, a menos de "range" px. Chocola ahora TAMBIEN los detecta:
// su mini-embestida los stunea 3.5 s (VANILLA_CHOCOLA_MINION_STUN) y
// ese stun abre la ventana del RESCATE de Vanilla (scr_survivor_revive:
// encima + ABAJO + 15 anillos, como revivir a un caido). Un esbirro
// ATURDIDO ya no es candidato (dedup: no re-stunea al que ya cayo).
function scr_chocola_find_minion(range)
{
    var best = noone;
    var bestd = range;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive || inst.character == CHARACTER_EXE || !inst.isDemonized)
                continue;

            if(inst.isHurt)                    // i-frames: no ataca
                continue;

            if(inst.state == DEAD)             // ya stuneado: fuera
                continue;

            var d = distance_to_object(inst);

            if(d < bestd)
            {
                bestd = d;
                best = inst;
            }
        }
    }

    return best;
}

// Cream: jugador local si YO soy Cream, o su puppet
function scr_chocola_find_cream()
{
    if(instance_exists(global.player) && global.character == CHARACTER_CREAM)
        return global.player;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive || inst.character != CHARACTER_CREAM)
                continue;

            return inst;
        }
    }

    return noone;
}

// ¿Hay una Vanilla en la partida? (pasivas que protegen a Cream)
function scr_vanilla_in_match()
{
    if(global.character == CHARACTER_VANILLA)
        return true;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive || inst.character != CHARACTER_VANILLA)
                continue;

            return true;
        }
    }

    return false;
}

// =====================================================================
//  PASO PRINCIPAL DE VANILLA (lo llama specialFunc cada frame; self =
//  la Vanilla local, solo en SU cliente)
// =====================================================================
function scr_vanilla_v2_step()
{
    // timers comunes
    if(chocolaCd > 0)
        chocolaCd--;

    if(dedemonCd > 0)
        dedemonCd--;

    // ---------------- MORIBUNDA (2da caida en adelante) ----------------
    // Tirada en el suelo (pose agotada), inmune a todo; a los 6 s se
    // levanta con poca vida. El server JAMAS se entera: para todos los
    // efectos sigue viva (y como canonica, jamas se demoniza).
    if(moribundaState > 0)
    {
        gspd = 0;
        xspd = 0;

        // MINI FIX v2.2 (mismo que PACIENCIA): debilitada EN EL AIRE cae al
        // suelo en vez de quedarse flotando en vilo; la levitacion queda
        // SOLO para el hoyo de verdad (sin terreno en la columna de abajo).
        if(isGrounded)
                yspd = 0;
        else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
                yspd = VANILLA_PACIENCIA_LEVITATE;
        else
                yspd = min(yspd + yAccel, maxYSpeed);

        isJumping = false;
        isFlying = false;
        isSpinning = false;
        ringsSpawn = 0;
        dashing = 0;

        moribundaTimer--;

        if(moribundaTimer <= 0)
        {
            moribundaState = 0;
            hp = VANILLA_MORIBUNDA_HEAL;
            hurttime = VANILLA_MORIBUNDA_INVULN;
            isHurt = false;
            flyTimer = 0;   // misericordia materna: todo listo al levantarse
            dashTimer = 0;
            ringsTimer = 0;
        }

        return;
    }

    // ---------------- PACIENCIA (1ra caida) ----------------
    if(pacienciaState > 0)
    {
        // enojada: quieta, inmune (guard en scr_player_hurt), y si la
        // caida fue a un hoyo levita suave hasta salir
        gspd = 0;
        xspd = 0;

        // MINI FIX v2.2 (pedido del usuario): "si la debilitan en el aire
        // no se queda flotando, debe caer al suelo". Antes este bloque
        // ponia yspd = LEVITATE siempre que no estuviera en el suelo, asi
        // que una Vanilla debilitada EN EL AIRE sobre suelo normal se
        // quedaba clavada flotando los 5 s enteros de la fase (la
        // levitacion es para HOYOS). Ahora: (1) en el suelo, quieta como
        // siempre; (2) con terreno en la columna de abajo CAE con su
        // gravedad y su tope de caida (la fase la hace en el suelo, como
        // pide el sprite de paciencia); (3) sin terreno debajo — el hoyo
        // de siempre, el abismo que la mato en vilo — levita suave hasta
        // salir, EXACTAMENTE como antes: cero cambio en los hoyos.
        if(isGrounded)
                yspd = 0;
        else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
                yspd = VANILLA_PACIENCIA_LEVITATE;
        else
                yspd = min(yspd + yAccel, maxYSpeed);

        isJumping = false;
        isFlying = false;
        isSpinning = false;
        ringsSpawn = 0;
        dashing = 0;

        // fase final: agotada, un segundo y se recupera
        if(pacienciaState == 2)
        {
            pacienciaTimer--;

            if(pacienciaTimer <= 0)
            {
                pacienciaState = 0;
                hp = VANILLA_PACIENCIA_HEAL;
                hurttime = VANILLA_PACIENCIA_INVULN;
                isHurt = false;
            }

            return;
        }

        // pacienciaState == 1: el reloj se CONGELA mientras Chocola no
        // haya golpeado al exe (pacienciaWaitChocola)
        if(!pacienciaWaitChocola)
        {
            pacienciaTimer--;

            // a los 2 s: CHOCOLA sale desde el lado contrario de la
            // pantalla a stunar al exe
            if(!pacienciaChocolaOut && pacienciaTimer <= VANILLA_PACIENCIA_CHOCOLA_AT)
            {
                pacienciaChocolaOut = true;
                pacienciaWaitChocola = true; // congela el resto del tiempo

                var _exe = scr_chocola_find_exe();
                var _choc = scr_chocola_get();

                if(_choc == noone)
                    _choc = instance_create_depth(x, y - 140, 0, obj_chocola);

                _choc.mode = CHOCOLA_HUNT;
                _choc.huntSmall = false;
                _choc.fromGuard = false;
                _choc.authority = true;
                _choc.huntTimer = 0;
                _choc.targetInst = _exe;

                // lado contrario de la pantalla respecto al exe
                var _side = 1;

                if(_exe != noone && _exe.x > x)
                        _side = -1;

                _choc.x = x + _side * 520;
                _choc.y = y - 140;

                // broadcast: el resto de clientes crean/lanzan la suya
                net_sound_emit(snd_mermer);

                if(_exe == noone)
                {
                    // sin exe en juego: no hay caza posible
                    pacienciaWaitChocola = false;
                    _choc.mode = CHOCOLA_RETURN;
                }
            }

            if(pacienciaTimer <= 0 && !pacienciaWaitChocola)
            {
                pacienciaState = 2;
                pacienciaTimer = VANILLA_PACIENCIA_EXIT;
            }
        }

        return;
    }

    // ---------------- FLOAT RUN (3ra fase de corrida) ----------------
    // Corriendo a tope (11) de forma sostenida, el tope sube solo hasta
    // 14; al alcanzarlo Vanilla toma la pose float_run y deja imagenes
    // residuales (aqui solo el tope y el flag; la pose la elige Step_2,
    // la estela local Draw_0 y la remota el bitflag POWERBOOST).
    // v2.11 (fix "nunca entra a la fase 3"): con el umbral viejo
    // (|xspd| >= 10.75) hacian falta ~6 s de carrera PERFECTA y cualquier
    // micro-bache del terreno reseteaba la rampa entera. Ahora cuenta
    // desde 9.5 y la rampa sube 3x mas rapido: ~1.5 s a tope y despega.
    floatRunCap = CREAM_MAXSPEED;

    if(isGrounded && !isSlow && global.playerControls && !isFlying && ringsSpawn <= 0 && dashing <= 0 && abs(xspd) >= VANILLA_FLOAT_HOLD_SPD)
        runHold++;
    else
        runHold = 0;

    if(runHold > VANILLA_FLOAT_RAMP_DELAY)
        floatRunCap = min(VANILLA_FLOAT_SPEED, CREAM_MAXSPEED + (runHold - VANILLA_FLOAT_RAMP_DELAY) * VANILLA_FLOAT_RAMP_ACC);

    isFloatRunning = isGrounded && abs(xspd) >= VANILLA_FLOAT_SPEED - 0.25;

    // ---------------- TECLA V: CHOCOLA <-> CREAM ----------------
    if(global.playerControls && keyboard_check_pressed(global.KeyV) && pacienciaState == 0 && moribundaState == 0)
    {
        // no pisar el drop del carry: si llevo a alguien colgado, la V
        // es para soltarlo (scr_carry_carrier_step)
        if(scr_carry_find_hanger(id, CARRY_CHECK_DIST) == noone && instance_exists(obj_chocola))
        {
            var _vc = scr_chocola_get();

            if(_vc.mode == CHOCOLA_FOLLOW)
            {
                var _cream = scr_chocola_find_cream();

                // v17 (NEGAGEN): Vanilla NEGA no puede mandar a Chocola a
                // PROTEGER a Cream salvo que la propia Cream TAMBIÉN sea nega
                // ("si en ese estado Vanilla no puede llamar a que Chocola vaya
                // a proteger a Cream, a menos claro que ya esa misma Cream esté
                // en nega"): la Vanilla del bando EXE no protege supervivientes.
                var _negVanilla = revivalTimes >= 2 && variable_instance_exists(id, "isNegatouch") && isNegatouch;

                // no puede ir si Cream no existe, esta caida (hp <= 0)
                // o demonizada — y con la Vanilla nega, salvo nega-Cream
                if(_cream != noone && !_cream.isInactive && _cream.hp > 0
                && (!_negVanilla || (variable_instance_exists(_cream.id, "isNegatouch") && _cream.isNegatouch)))
                {
                    _vc.mode = CHOCOLA_GO_CREAM;
                    _vc.fromGuard = false;
                    _vc.targetInst = _cream;

                    // velocidad NORMAL de ida (no la acelerada de caza)
                    net_sound_emit(snd_ready);
                }
            }
            else if(_vc.mode == CHOCOLA_GO_CREAM || _vc.mode == CHOCOLA_GUARD)
            {
                // V otra vez: la llama de vuelta (cancela a mitad de
                // trayectoria; la vuelta es mas rapida)
                _vc.mode = CHOCOLA_RETURN;
                net_sound_emit(snd_npteleport);
            }
        }
    }

    // ---------------- ATAQUE CERCANO DE CHOCOLA (33%) ----------------
    // Un enemigo se acerca demasiado a Vanilla: el EXE (stun 2.5 s) o
    // v2.11 un ESBIRRO demonizado (stun 3.5 s: el que abre la ventana
    // del rescate de 15 anillos). Chocola NO ataca si el objetivo tiene
    // i-frames (isHurt en su puppet). Mismo enfriamiento de 2.5 s que
    // el bloqueo.
    if(chocolaCd <= 0 && instance_exists(obj_chocola))
    {
        chocolaProxTimer--;

        if(chocolaProxTimer <= 0)
        {
            chocolaProxTimer = VANILLA_CHOCOLA_PROX_CHECK;

            var _choc = scr_chocola_get();
            var _exe2 = scr_chocola_find_exe();
            var _tgt = noone;

            // v2.11: el objetivo de la embestida es el MAS CERCANO entre
            // el exe y los esbirros a rango (si el exe esta stuneado o
            // fuera de rango, el esbirro manda)
            if(_exe2 != noone && !_exe2.isHurt && distance_to_object(_exe2) < VANILLA_CHOCOLA_ATTACK_RANGE)
                _tgt = _exe2;

            var _minion = scr_chocola_find_minion(VANILLA_CHOCOLA_ATTACK_RANGE);

            if(_minion != noone && (_tgt == noone || distance_to_object(_minion) < distance_to_object(_tgt)))
                _tgt = _minion;

            if(_choc != noone && _choc.mode == CHOCOLA_FOLLOW && _tgt != noone)
            {
                if(random(100) < VANILLA_CHOCOLA_ATTACK_CHANCE)
                {
                    // mini-embestida: al llegar manda la senal de stun
                    // corto (snd_vasebreak) al nid del objetivo — exe o
                    // esbirro: cada receptor decide su propia duracion
                    // (2.5 / 3.5 s, ver net_state_game). v2.1: se
                    // anuncia por red (snd_chocola_dive broadcast) para
                    // que TODOS los clientes — el del EXE incluido — la
                    // vean volar hacia el (antes solo la veia este
                    // cliente y al exe el stun le llegaba de la nada)
                    chocolaCd = VANILLA_CHOCOLA_CD;
                    _choc.mode = CHOCOLA_HUNT;
                    _choc.huntSmall = true;
                    _choc.fromGuard = false;
                    _choc.authority = true;
                    _choc.huntTimer = 0;
                    _choc.targetInst = _tgt;

                    audio_play_sound(snd_chocola_dive, 0, false);
                    net_sound_emit(snd_chocola_dive);
                }
            }
        }
    }

    // ---------------- RESCATE DE ESBIRROS (15 anillos) ----------------
    // v2.11: la des-demonizacion ya NO es el "toque instantaneo" de la
    // v2 (requeria un esbirro ATURDIDO al alcance, y NADA del kit de
    // Vanilla podia stunear esbirros: la pasiva era imposible de usar
    // y nadie entendia como activarla). Ahora es EL MISMO SISTEMA que
    // revivir a un caido por 3 anillos: Chocola stunca al esbirro
    // (3.5 s, deteccion nueva de arriba), sobre el esbirro caido le
    // aparece el prompt de revive a Vanilla, se pone encima MANTENIENDO
    // ABAJO, la MISMA barra de progreso se llena (server: paquete nuevo
    // CLIENT_VANILLA_DEDEMONIZE_PROGRESS + SERVER_REVIVAL_PROGRESS) y al
    // completar gasta los 15 anillos y el esbirro vuelve a la normalidad.
    // Toda la interaccion vive en scr_survivor_revive (la ejecuta el
    // puppet del esbirro, igual que la del caido); aqui ya no queda
    // nada del sistema viejo. El handler CLIENT_VANILLA_DEDEMONIZE se
    // conserva en el server por compatibilidad con clientes viejos.
}

// Chocola logro golpear al exe (la llama obj_chocola desde el cliente
// de Vanilla): descongela el reloj de la paciencia
function scr_vanilla_paciencia_chocola_hit()
{
    if(!instance_exists(global.player) || global.character != CHARACTER_VANILLA)
        return;

    global.player.pacienciaWaitChocola = false;
}

// La caza se cancela sin golpear (exe fuera de juego / failsafe)
function scr_vanilla_paciencia_chocola_fail()
{
    if(!instance_exists(global.player) || global.character != CHARACTER_VANILLA)
        return;

    global.player.pacienciaWaitChocola = false;
}

// =====================================================================
//  EVENTOS DE RED DE CHOCOLA (los llaman las ramas del CLIENT_SOUND_EMIT
//  en net_state_game; nid = quien emitio la senal)
// =====================================================================
function scr_chocola_net_event(kind, nid)
{
    var _choc = scr_chocola_get();

    // las unicas senales que pueden CREAR a Chocola en este cliente
    // son las de caza (la grande de la paciencia y la mini-embestida);
    // las demas la ignoran si no existe
    if(_choc == noone)
    {
        if(kind != CHOCOLA_NET_HUNT && kind != CHOCOLA_NET_HUNT_SMALL)
            return;

        _choc = instance_create_depth(0, 0, 0, obj_chocola);

        // nace junto a su casa (por si este cliente aun no la tenia: la
        // mini-embestida NO reposiciona, arranca desde donde este)
        var _home0 = scr_chocola_find_home();

        if(_home0 != noone)
        {
            _choc.x = _home0.x - _home0.image_xscale * 32;
            _choc.y = _home0.y - 10;
        }
    }

    switch(kind)
    {
        case CHOCOLA_NET_HUNT:
        {
            var _home = scr_chocola_find_home();
            var _exe = scr_chocola_find_exe();

            _choc.mode = CHOCOLA_HUNT;
            _choc.huntSmall = false;
            _choc.fromGuard = false;
            _choc.authority = false;
            _choc.huntTimer = 0;
            _choc.targetInst = _exe;

            // lado contrario de la pantalla respecto al exe
            var _side = 1;

            if(_exe != noone && _home != noone && _exe.x > _home.x)
                _side = -1;

            if(_home != noone)
            {
                _choc.x = _home.x + _side * 520;
                _choc.y = _home.y - 140;
            }

            if(_exe == noone)
                _choc.mode = CHOCOLA_RETURN;

            break;
        }

        case CHOCOLA_NET_HUNT_SMALL:
        {
            // v2.1: mini-embestida (ataque cercano 33% o custodia de
            // Cream). Los demas clientes ven a Chocola salir volando
            // hacia el exe DESDE DONDE ESTA (junto a Vanilla o Cream):
            // sin esta senal el exe recibia el stun sin verla venir.
            // v2.11: la embestida tambien puede ir contra un ESBIRRO
            // demonizado (quien la lanzo eligio al objetivo mas cercano):
            // este cliente resuelve el mismo objetivo — exe o esbirro a
            // rango — para que todos la vean volar hacia quien va de
            // verdad (cosmetico: el stun lo aplica siempre el cliente
            // del objetivo con la senal dirigida a su nid).
            var _exeS = scr_chocola_find_exe();
            var _tgtS = noone;

            if(_exeS != noone && !_exeS.isHurt && distance_to_object(_exeS) < VANILLA_CHOCOLA_ATTACK_RANGE)
                _tgtS = _exeS;

            var _minS = scr_chocola_find_minion(VANILLA_CHOCOLA_ATTACK_RANGE);

            if(_minS != noone && (_tgtS == noone || distance_to_object(_minS) < distance_to_object(_tgtS)))
                _tgtS = _minS;

            _choc.mode = CHOCOLA_HUNT;
            _choc.huntSmall = true;
            _choc.fromGuard = false;
            _choc.authority = false;
            _choc.huntTimer = 0;
            _choc.targetInst = _tgtS;

            if(_tgtS == noone)
                _choc.mode = CHOCOLA_RETURN;

            break;
        }

        case CHOCOLA_NET_GO_CREAM:
        {
            if(_choc.mode == CHOCOLA_FOLLOW)
            {
                _choc.mode = CHOCOLA_GO_CREAM;
                _choc.fromGuard = false;
                _choc.targetInst = scr_chocola_find_cream();
            }

            break;
        }

        case CHOCOLA_NET_RECALL:
        {
            if(_choc.mode == CHOCOLA_GO_CREAM || _choc.mode == CHOCOLA_GUARD)
                _choc.mode = CHOCOLA_RETURN;

            break;
        }

        case CHOCOLA_NET_DUTY_DONE:
        {
            if(_choc.mode == CHOCOLA_GO_CREAM || _choc.mode == CHOCOLA_GUARD || _choc.mode == CHOCOLA_HUNT)
                _choc.mode = CHOCOLA_RETURN;

            break;
        }

        case CHOCOLA_NET_SUPPORT:
        {
            // Vanilla solto su poder de anillos: Chocola celebra con su
            // giro de 360 (spr_vanilla_chocola_support_power, como el
            // Cheese de Cream: la animacion del sprite hace el giro)
            _choc.supportTimer = 40;
            break;
        }
    }
}

// =====================================================================
//  SENAL DE STUN (la rama shouldPlay del CLIENT_SOUND_EMIT la llama EN
//  EL CLIENTE DEL OBJETIVO: el exe en la caza grande y la mini-embestida,
//  v2.11 tambien el ESBIRRO demonizado que Chocola acaba de embestir).
//  Duracion en frames. Mismo modelo de confianza que el stun del parry
//  (scr_parry_apply_stun): el receptor se aturde a si mismo.
// =====================================================================
function scr_chocola_stun_signal(frames)
{
    if(!instance_exists(global.player))
        return;

    // v2.11: la senal ya no llega solo al cliente del EXE. La
    // mini-embestida de Chocola tambien apunta a ESBIRROS (deteccion
    // nueva): si este cliente es un esbirro demonizado vivo, el golpe
    // es para el (la duracion la decidio el receptor en net_state_game:
    // 2.5 s exe / 3.5 s esbirro).
    var _exe = global.character == CHARACTER_EXE;
    var _esbirro = !_exe && global.player.revivalTimes >= 2 && !global.player.isDead;

    if(!_exe && !_esbirro)
        return;

    // SONIDO DE STUN — SIEMPRE, ANTES del dedup (v2.1.4). Antes el
    // unico sonido (el grito, scr_exe_stunsound) vivia AL FINAL: si el
    // exe ya estaba stuneado (shockedTimer > 0 por un contra-golpe, un
    // parry u otra senal) el return del dedup se lo comia y Chocola le
    // pegaba EN SILENCIO. Y cuando sonaba, sonaba SOLO el grito del
    // personaje: en todos los demas stuns del juego (parry de Sonic,
    // laser de Tails, contra-golpe de Knux/Sally) el exe oye PRIMERO el
    // golpe canonico (snd_exe_stun) y ENCIMA el grito. Ahora igual:
    // golpe + grito, aunque el stun en si se dedupe (el golpe fue real,
    // se tiene que oir). El net_sound_emit reenvia el golpe por red:
    // los demas clientes lo oyen en 3D desde la posicion del exe (el
    // grito ya lo reenvia scr_exe_stunsound por su cuenta). Para el
    // ESBIRRO: golpe + chispa + shake de camara (mismo combo que el
    // stun del parry a un atacante esbirro; el "grito" es exclusivo
    // del lado EXE).
    audio_play_sound(snd_exe_stun, 0, false);
    net_sound_emit(snd_exe_stun);

    if(_exe)
        scr_exe_stunsound();
    else
    {
        net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
        scr_camera_shake(30, 2, 0.25);
    }

    // dedup: ya stuneado (auto-stun local, parry u otra senal): no se
    // re-aplica el stun ni el knockback ni el shake (igual que el dedup
    // del parry); el sonido de arriba si sono
    if(global.player.shockedTimer > 0)
        return;

    with(global.player)
    {
        isAttacking = false;
        hurttime = 0;
        shockedTimer = frames;
        xspd = 0;
        yspd = -2;
        isGrounded = false;
    }

    // v17 (VIDA REAL DEL NEGA): la mini-embestida de Chocola (bando
    // superviviente) es otro stun que le cuesta 20 de vida al nega
    // local (a 0 hp: fase 2 de Sally / paciencia de Vanilla / portal
    // de Jinna). Para el exe y el esbirro comun no cambia nada.
    scr_jinna_negatouch_stun_hurt();

    // shake de camara del golpeado (mismo paquete que usa el parry):
    // su propia pantalla tiembla y el resto lo oye en 3D
    var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
    buffer_write(_buffer, buffer_u16, obj_netclient.nid);
    buffer_write(_buffer, buffer_u16, floor(global.player.x));
    buffer_write(_buffer, buffer_u16, floor(global.player.y));
    buffer_write(_buffer, buffer_u16, frames div 60);
    send_server_tcp(_buffer);
}

// =====================================================================
//  CUSTODIA DE CREAM CUMPLIDA (la llama el cliente de Cream cuando
//  Chocola bloqueo un dano o stuneo al exe): Chocola vuelve a casa.
// =====================================================================
function scr_chocola_guard_consume()
{
    var _choc = scr_chocola_get();

    if(_choc == noone)
        return;

    _choc.mode = CHOCOLA_RETURN;
    _choc.fromGuard = false;

    // avisa al resto de clientes (incluido el de Vanilla)
    net_sound_emit(snd_achivement);
}
