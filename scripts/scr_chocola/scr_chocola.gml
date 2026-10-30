// =====================================================================
//  VANILLA V2 — CHOCOLA Y LAS PASIVAS DE VANILLA (scr_chocola)
//  Toda la logica nueva de Vanilla the Rabbit en un solo script:
//   - CHOCOLA: su chao. Aparece en la PACIENCIA (1ra caida) stuneando
//     al exe 5 s y desde ahi se queda a su lado en la posicion de las
//     mascotas de la tienda; la defiende (50% bloqueo con i-frames +
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
#macro VANILLA_FLOAT_RAMP_DELAY (60 * 1.5) // frames a tope (11) antes de acelerar
#macro VANILLA_FLOAT_RAMP_ACC 0.03         // cuanto sube el tope por frame
#macro VANILLA_FLOAT_GHOST_EVERY 5         // una imagen residual cada 5 frames
#macro VANILLA_FLOAT_GHOST_FADE 0.07       // fadeo de cada imagen residual

// --- paciencia (1ra caida) ---
#macro VANILLA_PACIENCIA_TIME (60 * 5)        // duracion total
#macro VANILLA_PACIENCIA_CHOCOLA_AT (60 * 3)  // restante al lanzar a Chocola (= 2 s dentro)
#macro VANILLA_PACIENCIA_HUNT_MAX (60 * 8)    // failsafe de caza
#macro VANILLA_PACIENCIA_EXIT (60 * 1)        // pose agotada al final
#macro VANILLA_PACIENCIA_HEAL 100             // vida al recuperar
#macro VANILLA_PACIENCIA_INVULN (60 * 2.5)    // i-frames al recuperar
#macro VANILLA_PACIENCIA_LEVITATE -0.35       // flota si la caida fue a un hoyo
#macro VANILLA_CHOCOLA_PACIENCIA_STUN (60 * 5) // stun del golpe de Chocola

// --- moribunda (2da caida en adelante) ---
#macro VANILLA_MORIBUNDA_TIME (60 * 6)  // tirada en el suelo
#macro VANILLA_MORIBUNDA_HEAL 30        // se levanta con poca vida
#macro VANILLA_MORIBUNDA_INVULN (60 * 3)

// --- chocola: defensa y ataques ---
#macro VANILLA_CHOCOLA_BLOCK_CHANCE 50          // % de bloquear el dano del exe
#macro VANILLA_CHOCOLA_BLOCK_INVULN (60 * 2.5)  // i-frames tras bloquear (semi-transparente)
#macro VANILLA_CHOCOLA_CD (60 * 4.5)            // enfriamiento compartido bloqueo/ataque
#macro VANILLA_CHOCOLA_ATTACK_CHANCE 33         // % de atacar al exe cercano
#macro VANILLA_CHOCOLA_ATTACK_RANGE 90          // px: "el exe se acerca mucho"
#macro VANILLA_CHOCOLA_ATTACK_STUN (60 * 1.5)   // stun del ataque cercano
#macro VANILLA_CHOCOLA_PROX_CHECK 30            // re-check de proximidad (0.5 s)
#macro VANILLA_CHOCOLA_HUNT_SPEED 14            // velocidad de caza (acelerada)
#macro VANILLA_CHOCOLA_SPEED 7                  // velocidad normal (ida a Cream)
#macro VANILLA_CHOCOLA_RETURN_SPEED 12          // vuelta rapida a casa
#macro VANILLA_CHOCOLA_HEAL_CHANCE 15           // % de curar a Cream AL LLEGAR
#macro VANILLA_CHOCOLA_HEAL_HP 30               // hp de esa curacion

// --- pasivas ---
#macro VANILLA_FORTALEZA_VANILLA_PCT 15 // % de anillos que pierde Vanilla al ser golpeada
#macro VANILLA_FORTALEZA_CREAM_PCT 30   // % que pierde Cream si Vanilla esta en la partida
#macro VANILLA_FORTALEZA_MIN 3          // perdida minima de anillos
#macro VANILLA_DEDEMON_COST 15          // anillos de la des-demonizacion
#macro VANILLA_DEDEMON_RANGE 64         // px: esbirro aturdido al alcance
#macro VANILLA_DEDEMON_CD 90            // anti-spam entre des-demonizaciones (1.5 s)
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
        yspd = isGrounded ? 0 : VANILLA_PACIENCIA_LEVITATE;
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
        yspd = isGrounded ? 0 : VANILLA_PACIENCIA_LEVITATE;
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
    floatRunCap = CREAM_MAXSPEED;

    if(isGrounded && !isSlow && global.playerControls && !isFlying && ringsSpawn <= 0 && dashing <= 0 && abs(xspd) >= CREAM_MAXSPEED - 0.25)
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

                // no puede ir si Cream no existe, esta caida (hp <= 0)
                // o demonizada
                if(_cream != noone && !_cream.isInactive && _cream.hp > 0 && _cream.revivalTimes < 2)
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
    // El exe se acerca demasiado: probabilidad de stun de 1.5 s. Chocola
    // NO ataca si el exe tiene i-frames (isHurt en su puppet). Mismo
    // enfriamiento de 4.5 s que el bloqueo.
    if(chocolaCd <= 0 && instance_exists(obj_chocola))
    {
        chocolaProxTimer--;

        if(chocolaProxTimer <= 0)
        {
            chocolaProxTimer = VANILLA_CHOCOLA_PROX_CHECK;

            var _choc = scr_chocola_get();
            var _exe2 = scr_chocola_find_exe();

            if(_choc != noone && _choc.mode == CHOCOLA_FOLLOW && _exe2 != noone && !_exe2.isHurt && distance_to_object(_exe2) < VANILLA_CHOCOLA_ATTACK_RANGE)
            {
                if(random(100) < VANILLA_CHOCOLA_ATTACK_CHANCE)
                {
                    // mini-embestida local: al llegar manda la senal de
                    // stun corto (snd_vasebreak) al nid del exe
                    chocolaCd = VANILLA_CHOCOLA_CD;
                    _choc.mode = CHOCOLA_HUNT;
                    _choc.huntSmall = true;
                    _choc.fromGuard = false;
                    _choc.authority = true;
                    _choc.huntTimer = 0;
                    _choc.targetInst = _exe2;
                }
            }
        }
    }

    // ---------------- DES-DEMONIZACION (15 anillos) ----------------
    // Un esbirro ATURDIDO al alcance + 15 anillos = le quita la
    // demonizacion (queda a 1 caida de re-demonizarse). El server valida
    // y avisa a todos (SERVER_VANILLA_DEDEMONIZE).
    if(dedemonCd <= 0 && rings >= VANILLA_DEDEMON_COST && instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            // esbirro = demonizado que no es el exe (los demonizados
            // conservan su personaje). ATURDIDO = su estado por red es
            // DEAD (los esbirros jamas estan "caidos", solo stuneados)
            if(inst.isInactive || inst.character == CHARACTER_EXE)
                continue;

            if(inst.revivalTimes >= 2 && inst.state == DEAD && distance_to_object(inst) < VANILLA_DEDEMON_RANGE)
            {
                rings -= VANILLA_DEDEMON_COST;
                dedemonCd = VANILLA_DEDEMON_CD;

                var pk = cpacket_tcp(PacketType.CLIENT_VANILLA_DEDEMONIZE, false);
                buffer_write(pk, buffer_u16, inst.master_id);
                send_server_tcp(pk);

                audio_play_sound(snd_heal, 0, false);
                break;
            }
        }
    }
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

    // la unica senal que puede CREAR a Chocola en este cliente es la
    // de caza de la paciencia; las demas la ignoran si no existe
    if(_choc == noone)
    {
        if(kind != CHOCOLA_NET_HUNT)
            return;

        _choc = instance_create_depth(0, 0, 0, obj_chocola);
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
//  SENAL DE STUN AL EXE (la rama shouldPlay del CLIENT_SOUND_EMIT la
//  llama EN EL CLIENTE DEL EXE). Duracion en frames.
// =====================================================================
function scr_chocola_stun_signal(frames)
{
    if(!instance_exists(global.player))
        return;

    // la senal viaja al nid del exe: este cliente ES el exe
    if(global.character != CHARACTER_EXE)
        return;

    // dedup: ya stuneado (auto-stun local, parry u otra senal)
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

    // shake de camara del exe (mismo paquete que usa el parry)
    var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
    buffer_write(_buffer, buffer_u16, obj_netclient.nid);
    buffer_write(_buffer, buffer_u16, floor(global.player.x));
    buffer_write(_buffer, buffer_u16, floor(global.player.y));
    buffer_write(_buffer, buffer_u16, frames div 60);
    send_server_tcp(_buffer);

    // sonido de stun canonico por exeCharacter (ademas lo emite por red:
    // todos oyen el grito del exe en su posicion)
    scr_exe_stunsound();
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
