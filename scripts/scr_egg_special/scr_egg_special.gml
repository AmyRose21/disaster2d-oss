// =====================================================================
//  v3.0 — PASIVA «GENIO MALVADO» (Eggman): sus anillos ya no son solo
//  puntos — son PIEZAS. Acercandose a una trampa (la suya o una de
//  Amelia) y pulsando V, Eggman la MEJORA gastando anillos:
//    * SENSOR propio (obj_eggtrack): 3 anillos.
//    * TRAMPA de Amelia (obj_amelia_trap): 5 anillos.
//  Una trampa mejorada gana +25% de efectividad (duracion del stun /
//  slow / ceguera de la trampa; slow del sensor), se dibuja con un
//  CONTORNO DORADO alrededor del sprite (spr_trap_gold /
//  spr_eggtrack_gold, la misma idea de los spr_exe_invis_*) y, si la
//  que cae es una TRAMPA de Amelia mejorada pisada por el bando EXE,
//  ejecuta el RASTREADOR: la posicion de la victima se revela a TODOS
//  los supervivientes 3 s (SERVER_TRACKER_PING, el mismo indicador
//  obj_surv_indicator que usan sus sensores).
//  Ademas el genio REPARA a Metal: Metal Sonic recupera vida estando
//  cerca del Dr. Eggman (cada 7 s) o de Tails (cada 13 s); si estan
//  los dos, solo aplica la del Dr. (ver scr_metal_special).
//  Valores ajustables abajo (EGG_GENIUS_*).
// =====================================================================
#macro EGG_GENIUS_SENSOR_COST 3      // anillos por mejorar un sensor
#macro EGG_GENIUS_TRAP_COST 5        // anillos por mejorar una trampa de Amelia
#macro EGG_GENIUS_BONUS 1.25         // +25% de efectividad al mejorar
#macro EGG_GENIUS_RANGE 42           // px: distancia maxima a la trampa
#macro EGG_GENIUS_CD (60 * 2)        // anti-spam entre mejoras

// Pide al server mejorar una entidad (0 = sensor de Eggman,
// 1 = trampa de Amelia). El server valida anillos y marca la entidad;
// el estado dorado llega a todos con SERVER_ETRACKER_STATE 2 /
// SERVER_AMELIA_TRAP_STATE 3 (mismo patron de siempre: el server es
// la autoridad de las entidades).
function net_egg_upgrade(type, nid)
{
        var packet = cpacket_tcp(PacketType.CLIENT_EGG_TRAP_UPGRADE);
        buffer_write(packet, buffer_u8, type);
        buffer_write(packet, buffer_u16, nid);
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
        
        if(isHiding)
        {
                if(djumpRecharge <= 60 * 2)
                        djumpRecharge = 60 * 2;
                
                if(shieldRechrage >= 0 && shieldRechrage <= 60 * 2)
                        shieldRechrage = 60 * 2;
                        
                if(trackerRecharge <= 60 * 2)
                        trackerRecharge = 60 * 2;
                        
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

        // ---- GENIO MALVADO (tecla V): mejorar trampas con anillos ----
        // Solo el Eggman SUPERVIVIENTE (un esbirro no hereda el genio).
        // Busca primero una TRAMPA de Amelia (5 anillos) y si no, un
        // SENSOR suyo (3 anillos) a menos de EGG_GENIUS_RANGE px. El
        // paquete lo valida el server con SU contador de anillos
        // (plr.rings); el estado dorado llega de vuelta para todos.
        if(global.playerControls && geniusCd <= 0 && revivalTimes < 2 && !isDead
        && keyboard_check_pressed(global.KeyV))
        {
                var _upgType = -1;
                var _upgNid = -1;
                var _upgCost = 0;

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
                        _upgType = 1;
                        _upgNid = _trap.nid;
                        _upgCost = EGG_GENIUS_TRAP_COST;
                }
                else if(instance_exists(_sensor))
                {
                        _upgType = 0;
                        _upgNid = _sensor.nid;
                        _upgCost = EGG_GENIUS_SENSOR_COST;
                }

                if(_upgType != -1 && rings >= _upgCost)
                {
                        rings -= _upgCost;
                        geniusCd = EGG_GENIUS_CD;

                        // chispas doradas sobre la trampa (efecto rapido
                        // por red: lo ven todos) + sonido del genio
                        repeat(6)
                                net_quick_effect(x + random_range(-14, 14), y - random_range(0, 20), spr_shockparticle, false, 1, random_range(-0.5, 0.5), -1, 1);

                        audio_play_sound(snd_heal, 0, false);
                        net_sound_emit(snd_heal);

                        net_egg_upgrade(_upgType, _upgNid);
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

        if(geniusCd > 0)
                geniusCd--;
}