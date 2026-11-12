// =====================================================================
//  JINNA (v1, killer rescatado de TD2DR Darkness In Blood, GameJolt
//  1104339). Kit reconstruido de los assets y la descripcion oficial
//  del mod (AboutJinna): "fast killer who uses portals and demonic
//  magic [...] teleport toward the nearest survivor [...] her grab can
//  lock a survivor in place for a short time [...] speed, direct
//  attack and sudden repositioning".
//
//   * GOLPE (tecla X): patron del exe basico (isAttacking + attackTimer
//     60/120) con COMMIT: JINNA_ATTACK_LOCK frames frenando el impulso
//     (jinnaAttackLock, lo ejecuta Step_0) — el swing es honesto, no
//     drive-by. Dano estandar del exe (20): lo aplica el cliente de la
//     victima por contacto con el PLAYER_ATTACKING (via ya existente).
//   * TELETRANSPORTE (tecla C): flecha sobre el objetivo (telegraph de
//     JINNA_TELEPORT_WINDUP), portales gemelos (salida y llegada,
//     obj_jinna_portal), aparece DETRAS del superviviente mas cercano
//     con la pose de tele (JINNA_TELE). El server replica los portales
//     a todos (SERVER_JINNA_PORTAL_STATE) y abre el grace del
//     anticheat (ex_teleport, mismo que el teletransporte de Exeller a
//     su clon). Enfriamiento JINNA_TELEPORT_RECHARGE.
//   * AGARRE (tecla V): al superviviente en rango (JINNA_GRAB_RANGE) lo
//     BLOQUEA JINNA_GRAB_LOCK segundos (obj_jinna_grab_effect en la
//     victima: la congela su propio cliente via SERVER_JINNA_GRAB_STATE)
//     y le hace JINNA_GRAB_DAMAGE de dano ("1 HP" en su placa oficial).
//     Enfriamiento JINNA_GRAB_RECHARGE.
//  Stats: la mas rapida del bando EXE (13; Exe/Exeller van a 12).
// =====================================================================
#macro JINNA_MAXSPEED 13
#macro JINNA_ACC 0.056875

// TELETRANSPORTE (tecla C)
#macro JINNA_TELEPORT_RECHARGE (60 * 8)   // 8 s de enfriamiento
#macro JINNA_TELEPORT_WINDUP 25           // ~0,42 s de telegraph (flecha)
#macro JINNA_TELEPORT_POSE 32             // ~0,53 s de pose al aterrizar
#macro JINNA_TELEPORT_OFFSET 34           // px detras del objetivo
#macro JINNA_TELEPORT_MAX_RANGE 2200      // no caza a traves de todo el mapa
// v3 — teleport potenciado
#macro JINNA_TELE_IFRAME (60 * 3)         // 3 s de I-frames al aparecer
#macro JINNA_TELE_HITBOX 0.75             // +25% hitbox del golpe basico (ventana de 3 s)
#macro JINNA_TELE_SLOW_TIME 4             // 3 s de ralentizacion a los objetivos alrededor (server)

// v3 — MARCA MEJORADA (pasiva de lore: creacion de las 3 — Amy, Sally
// y Cream). Version mejorada de la Marca de Debilidad de Metal Amy:
// mismo efecto (8 s de recarga forzada de TODAS las habilidades de la
// victima), pero su enfriamiento POR PERSONAJE es menor (13 s vs 16 s).
#macro JINNA_WEAKMARK_CD (60 * 13)

// AGARRE (tecla V) — v4: la V tiene DOS modos con recargas INDEPENDIENTES
// (antes compartian la de 12 s): sola = agarre, con ABAJO = portal trampa.
#macro JINNA_GRAB_RECHARGE (60 * 12)      // 12 s de enfriamiento del AGARRE (la trampa tiene el suyo: JINNA_TRAP_RECHARGE)
#macro JINNA_GRAB_RANGE 50                // px de alcance cuerpo a cuerpo
#macro JINNA_GRAB_LOCK (60 * 1.6)         // 1,6 s de victima bloqueada
#macro JINNA_GRAB_DAMAGE 25               // "1 HP" (la placa oficial; 15 con Vanilla atrapada)

// v3 — PORTAL TRAMPA (V + ABAJO): se planta en los pies de Jinna. Quien
// caiga recibe daño y es teletransportado HASTA ELLA (sin I-frames para
// la victima: si los tenia, el daño entra igual y se le REMUEVEN). Si
// quien cae es VANILLA, es ABSORBIDA a la otra dimension (obj_jinna_absorb
// + spr_vanilla_absorb_trap): fuera de juego "muerta sin estar muerta" y
// Jinna queda POTENCIADA (spr_vanilla_caught sobre su cabeza; ver LEEME).
// v4: la trampa YA NO COMPARTIR enfriamiento con el agarre — cada modo
// de la V tiene SU recarga (peticion de la duena tras probar la v3).
#macro JINNA_TRAP_RECHARGE (60 * 15)      // 15 s de enfriamiento PROPIO (antes compartia los 12 s del agarre)
#macro JINNA_TRAP_DAMAGE 30               // daño al caer en la trampa (18 con Amy atrapada / 22 con Vanilla)
#macro JINNA_TRAP_LIFE (60 * 20)          // vida maxima del portal trampa (la lleva el server)
#macro JINNA_TRAP_RADIUS 32               // radio de pisada (bbox del portal)

// v4 — NIVELES DE POTENCIACION del kit (a quien absorbio el portal
// trampa). La senal visual vive sobre la cabeza de Jinna (Draw_0):
//   * NINGUNO: kit base.
//   * AMY CANON (kind 2): "mejoras mas arduas" — la MITAD de los
//     aumentos de Vanilla; sobre Jinna flota una version SEMI-TRANSPARENTE
//     de Amy (spr_amy_capture_canon: ella aun no tiene pantalla propia,
//     la semi-transparencia ES la senal del estado intermedio).
//   * VANILLA (kind 1): las mejoras fuertes originales de la v3 y su
//     pantalla completa (spr_vanilla_caught) ajustada sobre la cabeza.
// El nivel solo SUBE (quien pille a Amy y luego a Vanilla llega al tope).
#macro JINNA_CAUGHT_NONE 0
#macro JINNA_CAUGHT_AMY 1
#macro JINNA_CAUGHT_VANILLA 2

// GOLPE (tecla X): commit del swing
#macro JINNA_ATTACK_LOCK 12               // ~0,2 s frenando el impulso

function scr_jinna_special()
{
        if(won || lost)
        {
                isAttacking = false;
                attackTimer = 0;
                jinnaTeleWindup = 0;
                jinnaTelePose = 0;
                jinnaGrabVisual = 0;
                jinnaTrapVisual = 0;
                jinnaAttackLock = 0;
        }

        // cancelar el salto en el aire (patron killers)
        if(global.playerControls && isJumping && keyboard_check_pressed(global.KeyA))
                isJumping = false;

        // ---- GOLPE (tecla X): patron exe + commit ----
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && jinnaTeleWindup <= 0)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                attackSpeed = xspd;
                attackTimer = isGrounded ? 60 : 120;
                isAttacking = true;
                isJumping = false;
                isSpinning = false;
                jinnaAttackLock = JINNA_ATTACK_LOCK; // el swing frena el impulso
                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
        }

        if(isAttacking)
        {
                if(yspd > 0)
                        yspd = isGrounded ? 0 : 2.5;

                if(isGrounded && abs(xspd) > 0 && floor(x) mod 4 == 0)
                        net_quick_effect(x - 8 * sign(image_xscale), y + 20, spr_dust);
        }

        // ---- TELETRANSPORTE (tecla C) ----
        // Fase 1: pulsar C marca al superviviente mas cercano (telegraph con
        // flecha, ver Draw_0). Fase 2: al agotarse el windup, portales + salto.
        if(jinnaTeleWindup > 0)
        {
                // el objetivo se escapo/murio/agoniza: el telegraph se cancela
                if(!instance_exists(jinnaTeleTarget) || jinnaTeleTarget.hp <= 0 || jinnaTeleTarget.isInactive)
                {
                        jinnaTeleWindup = 0;
                        jinnaTeleTarget = noone;
                }
                else
                {
                        jinnaTeleWindup--;

                        if(jinnaTeleWindup == 0 && instance_exists(jinnaTeleTarget))
                        {
                                var _t = jinnaTeleTarget;
                                var _tx = _t.x - _t.image_xscale * JINNA_TELEPORT_OFFSET;
                                var _ty = _t.y;

                                // portal de SALIDA en mis pies
                                instance_create_depth(x, y, 0, obj_jinna_portal);

                                // aviso al server: valida cooldown, abre el grace
                                // del anticheat y replica los DOS portales a todos
                                var pak = cpacket_tcp(PacketType.CLIENT_JINNA_TELEPORT, false);
                                buffer_write(pak, buffer_u16, floor(_tx));
                                buffer_write(pak, buffer_u16, floor(_ty));
                                send_server_tcp(pak);

                                // salto
                                x = _tx;
                                y = _ty;
                                xspd = 0;
                                gspd = 0;
                                yspd = 0;
                                isJumping = false;
                                image_xscale = sign(_t.x - x) == 0 ? image_xscale : sign(_t.x - x);
                                jinnaTelePose = JINNA_TELEPORT_POSE;
                                jinnaTeleTarget = noone;

                                // v3 — APARICION POTENCIADA: 3 s de I-frames
                                // (hurttime: el gate de los ataques de los
                                // supervivientes en obj_player_puppet; el
                                // parpadeo translucido del Draw es el aviso
                                // visual de la inmunidad). La ralentizacion
                                // a los objetivos alrededor la calcula y
                                // reparte el SERVER con las posiciones que
                                // ya sincroniza (SERVER_JINNA_TELE_AOE), y la
                                // ventana de +25% de hitbox del golpe basico
                                // la abre el broadcast de los portales en
                                // TODOS los clientes (global.jinnaTelePower).
                                hurttime = JINNA_TELE_IFRAME;

                                audio_play_sound(snd_teleport, 0, false);
                                net_sound_emit(snd_teleport);

                                scr_camera_shake(12, 0.5, 0.1);
                        }
                }
        }
        else if(global.playerControls && keyboard_check_pressed(global.KeyC) && jinnaTeleCd <= 0 && shockedTimer <= 0 && !won && !lost)
        {
                // marcar al superviviente mas cercano vivo (excluye esbirros,
                // agonizantes, desconectados y huyendo)
                var _best = noone;
                var _bestD = JINNA_TELEPORT_MAX_RANGE;

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(isDemonized || isInactive || hp <= 0 || revivalTimes >= 2)
                                        continue;

                                var _d = point_distance(x, y, other.x, other.y);
                                if(_d < _bestD)
                                {
                                        _bestD = _d;
                                        _best = id;
                                }
                        }
                }

                if(_best != noone)
                {
                        jinnaTeleTarget = _best;
                        jinnaTeleWindup = JINNA_TELEPORT_WINDUP;
                        jinnaTeleCd = JINNA_TELEPORT_RECHARGE;

                        // voz de caza (la risita "ready" del mod)
                        audio_play_sound(snd_jina_ready, 0, false);
                        net_sound_emit(snd_jina_ready);
                }
        }

        // (el conteo del telegraph corre en Step_0 junto al resto de
        // timers: nunca se congela aturdida — leccion v4.8 de Metal Amy)

        // ---- AGARRE (tecla V) / PORTAL TRAMPA (V + ABAJO) ----
        // v4: la V tiene dos modos con recargas INDEPENDIENTES: sola agarra
        // al objetivo cercano (12 s) y con ABAJO plantará un PORTAL TRAMPA
        // en sus pies con SU PROPIA recarga de 15 s (CLIENT_JINNA_TRAP:
        // el server lo valida con su cooldown separado, spawnea la entidad
        // y la replica a todos). El icono del HUD intercambia al presionar
        // abajo (ver obj_playerui: garra = agarre, portal+"▼+" = trampa).
        if(global.playerControls && keyboard_check_pressed(global.KeyV) && shockedTimer <= 0 && !won && !lost)
        {
                if(keyboard_check(global.KeyDown) && jinnaTrapCd <= 0)
                {
                        // ---- MODO TRAMPA (V + ABAJO) ----
                        jinnaTrapCd = JINNA_TRAP_RECHARGE; // v4: recarga PROPIA (no toca la del agarre)
                        jinnaTrapVisual = 24; // v4: pose de plantar la trampa ~0,4 s (spr_jinna_tele, ver Step_2)

                        if(keyboard_check(global.KeyLeft))
                                image_xscale = -1;
                        else if(keyboard_check(global.KeyRight))
                                image_xscale = 1;

                        var _trap = cpacket_tcp(PacketType.CLIENT_JINNA_TRAP, false);
                        buffer_write(_trap, buffer_u16, max(1, floor(x)));
                        buffer_write(_trap, buffer_u16, max(1, floor(y)));
                        send_server_tcp(_trap);

                        audio_play_sound(snd_teleport, 0, false);
                        net_sound_emit(snd_teleport);
                }
                else if(jinnaGrabCd <= 0)
                {
                var _g = noone;
                var _gD = JINNA_GRAB_RANGE;

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(isDemonized || isInactive || hp <= 0 || revivalTimes >= 2)
                                        continue;

                                var _d = point_distance(x, y, other.x, other.y);
                                if(_d < _gD)
                                {
                                        _gD = _d;
                                        _g = id;
                                }
                        }
                }

                if(_g != noone)
                {
                        jinnaGrabCd = JINNA_GRAB_RECHARGE; // v4: recarga del AGARRE (independiente de la trampa)
                        jinnaGrabVisual = 24; // pose de agarre ~0,4 s

                        if(keyboard_check(global.KeyLeft))
                                image_xscale = -1;
                        else if(keyboard_check(global.KeyRight))
                                image_xscale = 1;

                        // el server valida (exe + cooldown + victima viva) y
                        // reenvia a todos: la victima se congela y sufre el
                        // dano en SU cliente, el resto ve el efecto
                        // v4.1 FIX: falta el byte de DIRECCION (s8) — el
                        // server lee pid + dir y el paquete se rechazaba
                        // sin él (el agarre nunca calaba). dir = hacia donde
                        // mira Jinna al agarrar (voltea la garra y manda el
                        // empujon al soltar).
                        var pak2 = cpacket_tcp(PacketType.CLIENT_JINNA_GRAB, false);
                        buffer_write(pak2, buffer_u16, _g.master_id);
                        buffer_write(pak2, buffer_s8, sign(image_xscale));
                        send_server_tcp(pak2);

                        audio_play_sound(snd_jina_ready, 0, false);
                }
                } // fin del modo agarre (else de la trampa)
        }

        if(attackTimer > 0)
                attackTimer--;
}
