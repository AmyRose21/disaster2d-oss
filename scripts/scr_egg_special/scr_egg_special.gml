// =====================================================================
//  v3.1 — PASIVA «GENIO MALVADO» (Eggman), ahora al estilo del RESCATE
//  de Vanilla (v2.11): sus anillos son PIEZAS. Eggman se pone ENCIMA de
//  una trampa (la suya o una de Amelia) y MANTIENE ABAJO con anillos de
//  sobra: la MISMA barra del revive (spr_revival) se llena del lado del
//  server (0.03 por paquete + bonus por anillos extra, 30 paq/s) y al
//  completarse cobra los anillos y MEJORA la trampa:
//    * SENSOR propio (obj_eggtrack): 3 anillos.
//    * TRAMPA de Amelia (obj_amelia_trap): 5 anillos.
//  Soltar el ABAJO a mitad NO tira el dinero: el progreso queda en el
//  server (igual que la barra del caido / del esbirro rescatado).
//  Una trampa mejorada gana +25% de efectividad (duracion del stun /
//  slow / ceguera de la trampa; slow del sensor) y, si la que cae es
//  una TRAMPA de Amelia mejorada pisada por el bando EXE, ejecuta el
//  RASTREADOR: la posicion de la victima se revela a TODOS los
//  supervivientes 3 s (SERVER_TRACKER_PING, el mismo indicador
//  obj_surv_indicator que usan sus sensores).
//  v3.1 (pedido): el CONTORNO DORADO solo lo dibuja el bando
//  SUPERVIVIENTE — exe y esbirros NO lo ven (Draw_0 de las trampas).
//  Ademas el genio REPARA a Metal: Metal Sonic recupera vida estando
//  cerca del Dr. Eggman (cada 7 s) o de Tails (cada 13 s); si estan
//  los dos, solo aplica la del Dr. (ver scr_metal_special).
//  Valores ajustables abajo (EGG_GENIUS_*).
// =====================================================================
#macro EGG_GENIUS_SENSOR_COST 3      // anillos por mejorar un sensor
#macro EGG_GENIUS_TRAP_COST 5        // anillos por mejorar una trampa de Amelia
#macro EGG_GENIUS_BONUS 1.25         // +25% de efectividad al mejorar
#macro EGG_GENIUS_RANGE 42           // px: distancia maxima a la trampa
#macro EGG_GENIUS_SEND_CD 2          // cadencia de los paquetes de progreso (cada 2 frames = 30/s)

// Progreso de la mejora de una entidad (0 = sensor de Eggman,
// 1 = trampa de Amelia): mismo patron que CLIENT_VANILLA_DEDEMONIZE_
// PROGRESS — el server acumula el progreso en la ENTIDAD (upg_progress),
// reenvia la barra (SERVER_EGG_UPGRADE_PROGRESS) y al llenarla cobra
// 3/5 anillos y marca la entidad; el estado dorado llega a todos con
// SERVER_ETRACKER_STATE 2 / SERVER_AMELIA_TRAP_STATE 3 (mismo patron de
// siempre: el server es la autoridad de las entidades).
function net_egg_upgrade_progress(type, nid, ringcount)
{
        var packet = cpacket_tcp(PacketType.CLIENT_EGG_TRAP_UPGRADE_PROGRESS);
        buffer_write(packet, buffer_u8, type);
        buffer_write(packet, buffer_u16, nid);
        buffer_write(packet, buffer_u8, ringcount);
        send_server_tcp(packet);
}

function scr_egg_special()
{
        if(redRingTimer > 0)
        {
                if(djumpRecharge <= 2)
                        djumpRecharge = 2;
                
                if(shieldRechrage >= 0 && shieldRechrage <= 2)
                        shieldRechrage = 2;
                        
                if(trackerRecharge <= 2)
                        trackerRecharge = 2;
                        
                isAttacking = false;
        }
        
        // v4.4 (emboscada en el escondite): el RASTREADOR ya se puede
        // colocar oculto — solo se cortan el movimiento y el combate
        // (doble salto y escudo). isAttacking = false se mantiene:
        // pelear rompe el sigilo; colocar, no. El combo viene gratis:
        // para esconderse ya mantienes ABAJO, que es el modificador
        // del sensor (KeyC mirando abajo).
        if(isHiding)
        {
                if(djumpRecharge <= 60 * 2)
                        djumpRecharge = 60 * 2;

                if(shieldRechrage >= 0 && shieldRechrage <= 60 * 2)
                        shieldRechrage = 60 * 2;

                isAttacking = false;
        }
        
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && isJumping && djumpRecharge == 0)
        {
                isJumping = false;
                yspd = -8;
                
                audio_play_sound(snd_egg_djump, 0, false);
                net_sound_emit(snd_egg_djump);
                
                djumpRecharge = -1;
        }
        
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && shieldRechrage == 0)
        {
                isAttacking = true;
                
                audio_play_sound(snd_egg_shield, 0, false);
                net_sound_emit(snd_egg_shield);
                
                shieldRechrage = -1;
        }
        
        var xx = image_xscale > 0 ? 12 : -12;
        isColliding = isGrounded && !place_meeting(x, y, obj_angleanuller) && position_meeting(x + xx, y+18, obj_floor_parent);
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && trackerRecharge <= 0 && isLookingDown && isColliding)
        {
                audio_play_sound(snd_egg_tracker, 0, false);
                net_sound_emit(snd_egg_tracker);

                var pack = cpacket_tcp(PacketType.CLIENT_ETRACKER);
                buffer_write(pack, buffer_u16, x);
                buffer_write(pack, buffer_u16, y + 18);
                send_server_tcp(pack);

                trackerRecharge = EGGMAN_TRACKER_RECHARGE;
        }

        // ---- GENIO MALVADO v3.1 (manten ABAJO sobre la trampa): mejora
        // al estilo del RESCATE de Vanilla. Solo el Eggman SUPERVIVIENTE
        // (un esbirro no hereda el genio). Prioridad v3.0: primero una
        // TRAMPA de Amelia (5 anillos) y si no, un SENSOR suyo (3),
        // a menos de EGG_GENIUS_RANGE px. Mientras se mantenga ABAJO con
        // anillos de sobra salen los paquetes de progreso (30/s); la
        // barra la llena el SERVER y al completarla cobra los anillos y
        // dora la trampa. El progreso hecho SE CONSERVA en el server si
        // sueltas el ABAJO o te alejas a mitad (igual que el revive).
        if(global.playerControls && revivalTimes < 2 && !isDead)
        {
                // 1) mantener el LOCK mientras la trampa siga valida y
                // cerca (patron dedemonTarget de Vanilla: sin cambios de
                // objetivo a mitad de barra)
                if(geniusTarget != -1)
                {
                        var _lockNid = geniusTarget;
                        var _lockType = geniusTargetType;
                        var _keep = noone;

                        with(_lockType == 1 ? obj_amelia_trap : obj_eggtrack)
                        {
                                if(nid != _lockNid)
                                        continue;

                                if((_lockType == 1 && (upgraded || triggerSent))
                                || (_lockType == 0 && (upgraded || activated))
                                || distance_to_object(global.player) > EGG_GENIUS_RANGE * 1.5)
                                        continue;

                                _keep = self;
                                break;
                        }

                        if(!instance_exists(_keep))
                        {
                                // lock liberado: la barra a medio llenar se
                                // conserva en el server, no se tira nada
                                geniusTarget = -1;
                                geniusTargetType = -1;
                        }
                }

                // 2) sin lock: buscar la TRAMPA de Amelia mas cercana y si
                // no hay, un SENSOR (misma prioridad v3.0)
                if(geniusTarget == -1)
                {
                        var _trap = noone;
                        if(instance_exists(obj_amelia_trap))
                        {
                                var _best = EGG_GENIUS_RANGE;
                                with(obj_amelia_trap)
                                {
                                        if(upgraded || triggerSent)
                                                continue;

                                        var _d = distance_to_object(global.player);
                                        if(_d <= _best)
                                        {
                                                _best = _d;
                                                _trap = self;
                                        }
                                }
                        }

                        var _sensor = noone;
                        if(!instance_exists(_trap) && instance_exists(obj_eggtrack))
                        {
                                var _best2 = EGG_GENIUS_RANGE;
                                with(obj_eggtrack)
                                {
                                        if(upgraded || activated)
                                                continue;

                                        var _d = distance_to_object(global.player);
                                        if(_d <= _best2)
                                        {
                                                _best2 = _d;
                                                _sensor = self;
                                        }
                                }
                        }

                        if(instance_exists(_trap))
                        {
                                geniusTarget = _trap.nid;
                                geniusTargetType = 1;
                        }
                        else if(instance_exists(_sensor))
                        {
                                geniusTarget = _sensor.nid;
                                geniusTargetType = 0;
                        }
                }

                // 3) prompt (upgOver en el Step de cada trampa) + envio
                // del progreso mientras se mantiene ABAJO con anillos
                if(geniusTarget != -1 && isLookingDown
                && rings >= (geniusTargetType == 1 ? EGG_GENIUS_TRAP_COST : EGG_GENIUS_SENSOR_COST)
                && geniusSendCd <= 0)
                {
                        geniusSendCd = EGG_GENIUS_SEND_CD;

                        net_egg_upgrade_progress(geniusTargetType, geniusTarget, rings);
                }
        }
        
        if(shieldRechrage < 0)
        {
                shieldRechrage--;
                
                if(shieldRechrage <= -(60 * 1.5))
                {
                        isAttacking = false;
                        shieldRechrage = revivalTimes >= 2 ? EEGGMAN_SHIELD_RECHARGE : EGGMAN_SHIELD_RECHARGE;
                }
        }
        
        if(djumpRecharge < 0)
        {
                djumpRecharge--;
                
                if(djumpRecharge <= -30)
                        djumpRecharge = EGGMAN_DJUMP_RECHARGE;
        }
        
        if(djumpRecharge > 0)
                djumpRecharge--;

        if(shieldRechrage > 0)
                shieldRechrage--;

        if(trackerRecharge > 0)
                trackerRecharge--;

        if(geniusSendCd > 0)
                geniusSendCd--;
}