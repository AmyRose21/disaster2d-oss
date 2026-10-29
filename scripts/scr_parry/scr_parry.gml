/// scr_parry — PARRY DE SONIC (tecla C, estilo Frontiers)
// =====================================================================
//  COMO FUNCIONA (resumen):
//   * Tap de C -> windup (SONIC_PARRY_WINDUP frames, sin proteccion)
//     -> VENTANA ACTIVA (SONIC_PARRY_WINDOW frames de proteccion +
//     SONIC_PARRY_GRACE de gracia invisible para absorber la latencia).
//   * Durante la ventana activa, cualquier ataque del lado EXE que
//     fuera a golpear a Sonic O a un aliado dentro de su aura
//     (SONIC_PARRY_AURA px) queda INTERCEPTADO:
//       - el dano se niega en el cliente de la victima (igual que el
//         escudo de Sally: return antes de aplicar),
//       - el atacante se aturde A SI MISMO en su propio cliente
//         (scr_parry_try_stun_attacker en obj_player_puppet), IGNORANDO
//         sus i-frames (hurttime), y su escudo se consume entero,
//       - los proyectiles NO stunean al que los tiro (regla del parry):
//         el laser de Tails se DESVIA (pasa al lado de Sonic, en cian,
//         y aturde al EXE/esbirro que toque) y el anillo de Exetior se
//         CONVIERTE en anillo dorado recogible (+1).
//   * Exito -> animacion de exito + cooldown bueno; fallo -> cooldown
//     malo. En fase powerboost (tras usar Nervios de Acero) los
//     cooldowns son mas cortos.
//
//  TODO viaja por la red con lo que ya existia: el byte `state` del
//  paquete UDP lleva SONIC_PARRY_* (el server lo reenvia intacto) y los
//  paquetes nuevos van AL FINAL del enum (compatibles con clientes
//  viejos). Cero cambios en el formato del paquete de estado.
// =====================================================================

// ===== ESTADOS DE RED (byte `state`; 60+ libres, los golpes usan 20-59) =====
// v3: SOLO EN TIERRA (un unico sprite de inicio). Los 62/63 quedaron
// libres (eran las variantes de AIRE de la v1/v2, ya no se usan).
#macro SONIC_PARRY_INICIO 60     // windup (aun sin proteccion)
#macro SONIC_PARRY_INICIO_ACT 61 // VENTANA ACTIVA (protege)
#macro SONIC_PARRY_EXITO 64      // parte de EXITO (al interceptar)

// ===== TIMINGS (frames; 60 = 1 seg) =====
#macro SONIC_PARRY_WINDUP 4       // preparacion (sin proteccion)
#macro SONIC_PARRY_WINDOW 12      // ventana activa
#macro SONIC_PARRY_GRACE 4        // gracia invisible (latencia de red)
#macro SONIC_PARRY_EXITO_TIME 22  // duracion de la animacion de exito

// ===== NUMEROS =====
#macro SONIC_PARRY_AURA 56                    // radio del aura que cubre aliados (px)
#macro SONIC_PARRY_STUN_TIME (60 * 3)         // stun del atacante parreado (3 seg)
#macro SONIC_PARRY_CD_FAIL (60 * 14)          // fallo  - fase normal (14 seg)
#macro SONIC_PARRY_CD_OK (60 * 7)             // exito  - fase normal (7 seg)
#macro SONIC_PARRY_CD_FAIL_PB (60 * 10)       // fallo  - fase powerboost (10 seg)
#macro SONIC_PARRY_CD_OK_PB (60 * 2)          // exito  - fase powerboost (2 seg)
#macro SONIC_PARRY_LASER_MAXDMG 3             // stun maximo (seg) del laser desviado
#macro SONIC_PARRY_FLASH_FRAMES 14            // anillo cian de activacion

// ===== SPRITES =====
// v3: DOS sprites, solo en tierra:
//   spr_sonic_parry_inicio   -> parte inicial del intento (windup+ventana)
//   spr_sonic_parry_exitoso  -> parte de EXITO (al interceptar)
// Ya estan en el proyecto (registrados en el .yyp del repo). Si no
// existieran en alguna instalacion, cae al sprite del golpe
// (spr_sonic_attack2_tierra1) para que nunca pete.
function scr_parry_sprite(st)
{
        var _name = "";
        
        if(st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT)
                _name = "spr_sonic_parry_inicio";
        else if(st == SONIC_PARRY_EXITO)
                _name = "spr_sonic_parry_exitoso";
        else
                return -1;
        
        var _spr = asset_get_index(_name);
        if(!is_undefined(_spr) && _spr >= 0)
                return _spr;
        
        _spr = asset_get_index("spr_sonic_attack2_tierra1");
        if(!is_undefined(_spr) && _spr >= 0)
                return _spr;
        
        return -1;
}

// ¿el estado es una VENTANA ACTIVA del parry? (lo miran los otros
// clientes en el puppet de Sonic para saber que esta protegiendo)
function scr_parry_state_active(st)
{
        return st == SONIC_PARRY_INICIO_ACT;
}

// ¿el estado es alguno del parry? (para el dibujado del puppet)
function scr_parry_state_is(st)
{
        return st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT || st == SONIC_PARRY_EXITO;
}

// overlap de bounding boxes entre dos instancias (contacto
// puppet-vs-puppet: place_meeting solo sirve contra el jugador local)
function scr_parry_bbox_overlap(a, b)
{
        return a.bbox_right >= b.bbox_left && a.bbox_left <= b.bbox_right
                && a.bbox_bottom >= b.bbox_top && a.bbox_top <= b.bbox_bottom;
}

// =====================================================================
//  PROTECCION (cliente de la VICTIMA): ¿hay un Sonic con la ventana
//  activa cubriendo al jugador local?
//    global.player -> el local ES ese Sonic (parry propia)
//    puppet        -> un Sonic remoto lo cubre con su aura
//    noone         -> sin proteccion
// =====================================================================
function scr_parry_protects_me()
{
        if(!instance_exists(global.player))
                return noone;

        // el parry solo protege a sobrevivientes vivos
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
                return noone;

        if(global.player.isDead)
                return noone;

        // 1) yo soy Sonic y mi ventana esta activa
        if(global.character == CHARACTER_SONIC && global.player.parryActive)
                return global.player;

        // 2) un Sonic remoto con parry activa y yo dentro de su aura
        if(!instance_exists(obj_player_puppet))
                return noone;

        var _res = noone;
        with(obj_player_puppet)
        {
                if(character != CHARACTER_SONIC || isDemonized || isInactive)
                        continue;

                if(!scr_parry_state_active(state))
                        continue;

                if(distance_to_object(global.player) <= SONIC_PARRY_AURA)
                {
                        _res = self;
                        break;
                }
        }
        return _res;
}

// =====================================================================
//  NEGACION (la llama scr_player_hurt con exeSource=true): el dano
//  viene de un ataque/habilidad del lado EXE y hay parry cubriendo al
//  jugador local -> se NIEGA. Devuelve true (el llamador no aplica nada).
//  El STUN del atacante lo resuelve el cliente del propio atacante
//  (scr_parry_try_stun_attacker) con los mismos datos sincronizados.
// =====================================================================
function scr_parry_negate_hit()
{
        var _sonic = scr_parry_protects_me();
        if(_sonic == noone)
                return false;

        var _nid = obj_netclient.nid;
        if(_sonic != global.player)
                _nid = _sonic.master_id;

        // FX + "ting" posicionado en el Sonic que parrea: directo en su
        // pantalla (shouldPlay del emit_at) y 3D desde su puppet en las
        // demas (mismo sistema de sonido de red de siempre). Sin play
        // local extra: en un self-parry el emit_at ya lo suena una vez.
        net_sound_emit_at(snd_parry, _nid);
        net_quick_effect(_sonic.x, _sonic.y - 8, spr_shockparticle, false, 1, 0, 0, 1);
        scr_camera_shake(20, 2, 0.2);

        return true;
}

// =====================================================================
//  STEP DEL PARRY (solo el Sonic local; lo llama obj_sonic/Step_0):
//  maquina de fases + deteccion de exito + desvios de proyectil.
// =====================================================================
function scr_parry_step()
{
        if(parryFlash > 0)
                parryFlash--;

        if(parryCooldown > 0)
                parryCooldown--;

        // cancelacion: si lo hieren/stunean matando el parry, cuenta como
        // fallo. v3: TAMBIEN si se va al aire (el parry es SOLO en tierra;
        // la parte de EXITO se deja terminar para no cortar la animacion).
        if(parryState > 0 && (isDead || isHurt || shockedTimer > 0 || nerviosState > 0 || (!isGrounded && parryState != 4)))
        {
                if(parryState != 4 && !parrySuccess && parryCooldown <= 0)
                        parryCooldown = nerviosUsed ? SONIC_PARRY_CD_FAIL_PB : SONIC_PARRY_CD_FAIL;

                parryState = 0;
                parryActive = false;
        }

        // fase EXITO: solo termina la animacion
        if(parryState == 4)
        {
                parryTimer--;
                if(parryTimer <= 0)
                        parryState = 0;
                return;
        }

        if(parryState > 0)
        {
                parryTimer--;

                if(parryTimer <= 0)
                {
                        if(parryState == 1)
                        {
                                // fin del windup -> se abre la ventana
                                parryState = 2;
                                parryTimer = SONIC_PARRY_WINDOW + SONIC_PARRY_GRACE;
                                parryActive = true;
                                parryFlash = SONIC_PARRY_FLASH_FRAMES;
                        }
                        else if(parryState == 2)
                        {
                                // cerro la ventana sin interceptar nada: FALLO
                                parryActive = false;
                                parryState = 0;

                                if(!parrySuccess)
                                        parryCooldown = nerviosUsed ? SONIC_PARRY_CD_FAIL_PB : SONIC_PARRY_CD_FAIL;
                        }
                }

                // deteccion de exito (solo con la ventana abierta)
                if(parryState == 2 && !parrySuccess)
                        scr_parry_detect();

                return;
        }

        // ===== INPUT: tap de C (v3: SOLO EN TIERRA) =====
        if(global.playerControls && parryCooldown <= 0 && isGrounded
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
        && !isAttacking && !isSpinCharging && nerviosState == 0
        && bounceTimer <= 0
        && keyboard_check_pressed(global.KeyC))
        {
                parryState = 1;
                parryTimer = SONIC_PARRY_WINDUP;
                parrySuccess = false;
                parryActive = false;
        }
}

// =====================================================================
//  DETECCION DE EXITO (cliente de Sonic, ventana activa):
//   1) puppet del lado EXE atacando y tocando a Sonic o a un aliado
//      dentro del aura -> exito (el stun lo resuelve el atacante)
//   2) laser de Tails esbirro tocando a Sonic o a un aliado del aura
//      -> se pide el desvio al server (lo invierte y lo vuelve cian)
//   3) anillo negro de Exetior dentro del aura -> se convierte en
//      anillo dorado recogible (el server lo cambia por un anillo real)
// =====================================================================
function scr_parry_detect()
{
        var _hit = false;
        var _me = self; // Sonic (el que llama): dentro de with anidados `other` cambia

        if(instance_exists(obj_player_puppet))
        {
                // aliados vivos dentro del aura (victimas potenciales)
                var _victims = ds_list_create();
                with(obj_player_puppet)
                {
                        if(isDemonized || isInactive)
                                continue;

                        if(distance_to_object(_me) <= SONIC_PARRY_AURA)
                                ds_list_add(_victims, self);
                }

                // atacantes del lado EXE con el ataque activo
                with(obj_player_puppet)
                {
                        if(!isDemonized || !visible || isInactive)
                                continue;

                        if(!(isAttacking || state == JUMP || state == SPIN))
                                continue;

                        // ¿su ataque toca al propio Sonic?
                        if(scr_parry_bbox_overlap(self, _me))
                        {
                                _hit = true;
                                break;
                        }

                        // ¿o toca a un aliado cubierto por el aura?
                        for(var _i = 0; _i < ds_list_size(_victims); _i++)
                        {
                                if(scr_parry_bbox_overlap(self, _victims[| _i]))
                                {
                                        _hit = true;
                                        break;
                                }
                        }

                        if(_hit)
                                break;
                }

                ds_list_destroy(_victims);
        }

        // laser de Tails (isExe) tocando a Sonic o a un aliado del aura
        if(!_hit && instance_exists(obj_tails_projectile))
        {
                with(obj_tails_projectile)
                {
                        if(isBreaking || !isExe)
                                continue;

                        if(scr_parry_bbox_overlap(self, _me))
                        {
                                _hit = true;
                                break;
                        }

                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(isDemonized || isInactive)
                                                continue;

                                        if(distance_to_object(_me) > SONIC_PARRY_AURA)
                                                continue;

                                        if(scr_parry_bbox_overlap(self, obj_tails_projectile))
                                        {
                                                _hit = true;
                                                break;
                                        }
                                }
                        }

                        if(_hit)
                                break;
                }

                if(_hit)
                {
                        var _pk = cpacket_tcp(PacketType.CLIENT_TPROJECTILE_DEFLECT);
                        send_server_tcp(_pk);
                }
        }

        // anillo negro de Exetior dentro del aura -> anillo dorado
        if(instance_exists(obj_blackring))
        {
                with(obj_blackring)
                {
                        if(used || image_alpha < 1)
                                continue;

                        if(distance_to_object(_me) > SONIC_PARRY_AURA)
                                continue;

                        var _pk = cpacket_tcp(PacketType.CLIENT_BRING_DEFLECT);
                        buffer_write(_pk, buffer_u16, nid);
                        send_server_tcp(_pk);

                        used = true; // local: no reenviar el mismo
                        _hit = true;
                }
        }

        if(_hit)
        {
                parrySuccess = true;
                parryState = 4; // parte de EXITO
                parryTimer = SONIC_PARRY_EXITO_TIME;
                parryActive = false;
                parryFlash = SONIC_PARRY_FLASH_FRAMES;
                parryCooldown = nerviosUsed ? SONIC_PARRY_CD_OK_PB : SONIC_PARRY_CD_OK;
                scr_camera_shake(30, 2, 0.25);
        }

        return _hit;
}

// =====================================================================
//  STUN DEL ATACANTE (lo llama obj_player_puppet/Step_0 en el cliente
//  del ATACANTE). `self` ahi es el puppet VICTIMA que el ataque local
//  esta tocando. Si esa victima esta cubierta por la ventana activa
//  del parry de un Sonic, el jugador local (EXE/esbirro) se aturde a
//  si mismo IGNORANDO sus i-frames y su escudo se consume entero.
//  Devuelve true si aplico el parry.
// =====================================================================
function scr_parry_try_stun_attacker()
{
        if(!instance_exists(global.player))
                return false;

        if(global.player.isDead)
                return false;

        var _parrySonic = noone;
        if(instance_exists(obj_player_puppet))
        {
                with(obj_player_puppet)
                {
                        if(character != CHARACTER_SONIC || isDemonized || isInactive)
                                continue;

                        if(!scr_parry_state_active(state))
                                continue;

                        // la victima de este ataque (other) dentro del aura
                        if(distance_to_object(other) > SONIC_PARRY_AURA)
                                continue;

                        _parrySonic = self;
                        break;
                }
        }

        if(_parrySonic == noone)
                return false;

        // ESCUDO ELECTRICO DE EGGMAN esbirro: se consume el RESTO del
        // tiempo del escudo (pasa directo al cooldown completo)
        if(global.character == CHARACTER_EGGMAN && global.player.shieldRechrage < 0)
        {
                global.player.shieldRechrage = global.player.revivalTimes >= 2 ? EEGGMAN_SHIELD_RECHARGE : EGGMAN_SHIELD_RECHARGE;
                global.player.isAttacking = false;

                net_quick_effect(global.player.x, global.player.y, spr_shieldbreak, false, 1, 0, 0, 1);
                audio_play_sound(snd_sally_shieldbreak, 0, false);
                net_sound_emit(snd_sally_shieldbreak);
        }

        // ESCUDO DE SALLY esbirro: se rompe
        if((global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON) && global.player.shieldTimer > 0)
        {
                global.player.shieldTimer = 0;

                net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                audio_play_sound(snd_sally_shieldbreak, 0, false);
                net_sound_emit(snd_sally_shieldbreak);
        }

        // STUN DIRECTO: ignora los i-frames del atacante (hurttime) —
        // regla del parry: aturde aunque este transparente
        global.player.isAttacking = false;
        global.player.isSpinCharging = false;
        global.player.spinCharge = 0;
        global.player.hurttime = 0;
        global.player.shockedTimer = SONIC_PARRY_STUN_TIME;
        global.player.xspd = -sign(x - global.player.x) * 4;
        global.player.yspd = -2;
        global.player.isGrounded = false;

        audio_play_sound(snd_exe_stun, 0, false);
        net_sound_emit(snd_exe_stun);
        net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
        scr_camera_shake(30, 2, 0.25);

        // los mismos paquetes que ya usa el stun normal del juego
        // (camara del atacante + estadisticas de la partida)
        var _stunSec = SONIC_PARRY_STUN_TIME div 60;

        var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
        buffer_write(_buffer, buffer_u16, master_id);
        buffer_write(_buffer, buffer_u16, x);
        buffer_write(_buffer, buffer_u16, y);
        buffer_write(_buffer, buffer_u16, _stunSec);
        send_server_tcp(_buffer);

        var _pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
        buffer_write(_pak, buffer_u8, 1);
        buffer_write(_pak, buffer_u16, obj_netclient.nid);
        buffer_write(_pak, buffer_u16, master_id);
        buffer_write(_pak, buffer_u8, _stunSec);
        send_server_tcp(_pak);

        if(global.character == CHARACTER_EXE)
                scr_exe_stunsound();

        return true;
}
