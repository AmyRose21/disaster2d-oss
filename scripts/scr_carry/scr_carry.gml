/// scr_carry - LLEVAR ALIADOS VOLANDO (Tails y Cream)
// =====================================================================
//  COMO SE USA (como las lianas/tirolinas del juego):
//   * Un SUPERVIVIENTE en el aire (saltando o cayendo) que TOCA a un
//     Tails o a una Cream que esten VOLANDO se agarra solo y queda
//     colgando debajo de ellos (con el sprite de tirolina de SU
//     propio personaje: todos tienen uno).
//   * El que cuelga se suelta con Z (la tecla de salto): sale con un
//     pequeno saltito hacia arriba. Tras soltar hay 2 segundos de
//     espera antes de poder agarrarse otra vez.
//   * El PORTADOR (Tails o Cream) suelta a su pasajero con la V.
//   * Se sueltan solos si: el portador aterriza / deja de volar / es
//     herido / muere / se desconecta, o si el que cuelga toca el
//     suelo / es herido / muere / se demoniza.
//   * Mientras llevan a alguien colgado, el vuelo de Tails y el
//     planeo de Cream se ALARGAN hasta 5.5 seg (volando solos:
//     su tiempo normal; lo calcula cada especial con su reloj).
//
//  COMO FUNCIONA POR RED (cero cambios del server):
//   * El que cuelga viaja en el estado *_ZIPLINE de SU personaje (el
//     mismo estado de la tirolina: el sprite de tirolina ya esta
//     registrado en los arrays de scr_survivors, en Draw_76 y en el
//     Draw_72 del puppet, asi que TODOS los clientes lo ven colgado
//     sin tocar nada). Su posicion viaja normal en CLIENT_PLAYER_DATA:
//     su propio cliente la pega al puppet del portador cada frame.
//   * El "sueltame" del portador (tecla V) viaja como un snap
//     (snd_snap) SENALADO al nid del pasajero (net_sound_emit_at con
//     shouldPlay=true): el mismo truco de la senal de stun del parry
//     v3.5. El CLIENT_SOUND_EMIT de net_state_game lo reconoce y
//     llama scr_carry_drop_signal. El snap del AGARRE (tirolina y
//     carry) viaja con shouldPlay=false y nunca pasa por esa rama.
//   * Un pasajero por portador: lo comprueba el que se quiere agarrar
//     (si ya hay alguien colgado cerca de ese portador, no se agarra).
//
//  DONDE VIVE:
//   * objects/obj_carry_controller: lo crea obj_spawnpoint cada ronda
//     en cada cliente superviviente (el EXE no lo necesita: no lleva
//     ni cuelga). Desde su End Step (DESPUES de toda la fisica del
//     jugador, en el mismo momento donde la tirolina mueve al player)
//     llama scr_carry_step (lado del que cuelga) y
//     scr_carry_carrier_step (lado Tails/Cream).
//   * scr_carry_drop_signal lo llama net_state_game (rama snd_snap
//     del CLIENT_SOUND_EMIT). Los estados *_ZIPLINE viajan solos en
//     el paquete de estado de siempre.
// =====================================================================

// ===== NUMEROS (ajustables) =====
#macro CARRY_GRAB_RANGE   32    // px: distancia maxima para AGARRARSE del portador
#macro CARRY_HANG_Y       26    // px: cuanto por DEBAJO del portador cuelga el pasajero
#macro CARRY_HOP          -6.5  // velocidad vertical del saltito al soltarse con Z
#macro CARRY_REGRAB_CD    120   // frames sin poder re-agarrarse tras soltarse (2 seg)
#macro CARRY_CHECK_DIST   48    // px: radio del "llevo a alguien colgado" (lado portador)

// =====================================================================
//  ESTADOS Y BUSQUEDAS
// =====================================================================

// Estado ZIPLINE de cada personaje: es EL MISMO estado de la tirolina
// (viaja por red tal cual y todos los clientes ya saben dibujarlo con
// el sprite de tirolina del personaje). Amy Canon y Sally Canon
// comparten estado con sus versiones originales (misma macro BALANCING+4).
function scr_carry_zipline_state(ch)
{
        switch(ch)
        {
                case CHARACTER_TAILS:       return TAILS_ZIPLINE;
                case CHARACTER_KNUX:        return KNUX_ZIPLINE;
                case CHARACTER_EGGMAN:      return EGG_ZIPLINE;
                case CHARACTER_AMY:         return AMY_ZIPLINE;
                case CHARACTER_AMY_CANON:   return AMY_CANON_ZIPLINE;
                case CHARACTER_SONIC:       return SONIC_ZIPLINE;
                case CHARACTER_CREAM:       return CREAM_ZIPLINE;
                case CHARACTER_SALLY:       return SALLY_ZIPLINE;
                case CHARACTER_SALLY_CANON: return SALLY_ZIPLINE;
                case CHARACTER_VANILLA:      return CREAM_ZIPLINE; // Vanilla vuela como Cream
                case CHARACTER_AMELIA:       return CREAM_ZIPLINE; // v2.2: Amelia vuela como Cream
        }
        
        return -1;   // el EXE y variantes: nunca cuelgan del carry
}

// ¿El puppet p es un portador VOLANDO ahora mismo? (Tails o Cream;
// su estado de red cambia a JUMP/FALL/HURT/DEAD en cuanto aterriza,
// se queda sin vuelo o le pasa algo, y eso suelta al pasajero solo)
function scr_carry_partner_flying(p)
{
        if(p.character == CHARACTER_TAILS)
                return p.state == TAILS_FLY;
        
        if(p.character == CHARACTER_CREAM)
                return p.state == CREAM_FLY;

        if(p.character == CHARACTER_VANILLA)
                return p.state == CREAM_FLY;

        // v2.2 (TTB): Amelia vuela como Cream
        if(p.character == CHARACTER_AMELIA)
                return p.state == AMELIA_FLY;
        
        return false;
}

// El portador (puppet de Tails/Cream volando) mas cercano a "from" a
// menos de "rng" px. Solo puppets: el portador SIEMPRE es otro
// jugador, nunca el cliente local. Se excluyen inactivos
// (desconectados), demonizados (son del equipo EXE) y muertos.
function scr_carry_find_carrier(from, rng)
{
        if(from == noone)
                return noone;
        
        var _best = noone;
        var _bd = rng;
        
        with(obj_player_puppet)
        {
                if(isInactive || isDemonized || hp <= 0)
                        continue;
                
                if(!scr_carry_partner_flying(self))
                        continue;
                
                var _d = point_distance(from.x, from.y, x, y);
                
                if(_d <= _bd)
                {
                        _bd = _d;
                        _best = self;
                }
        }
        
        return _best;
}

// ¿Hay alguien ya colgado de "from"? (puppet en estado ZIPLINE de su
// personaje, cerca y por debajo de "from"). Lo usa quien se quiere
// agarrar (para respetar el UN pasajero por portador) y el propio
// portador (tecla V y el gasto extra de vuelo de Tails). OJO: un
// jugador en una tirolina REAL de mapa tambien va en estado ZIPLINE;
// si pasa cerca de un portador puede dar un falso positivo, pero es
// inofensivo (la senal de drop la ignora quien no esta colgado de
// verdad porque su carryActive esta en false).
function scr_carry_find_hanger(from, rng)
{
        if(from == noone)
                return noone;
        
        var _best = noone;
        var _bd = rng;
        
        with(obj_player_puppet)
        {
                if(isInactive)
                        continue;
                
                var _zs = scr_carry_zipline_state(character);
                
                if(_zs < 0 || state != _zs)
                        continue;
                
                // colgado: siempre por debajo del portador
                if(y < from.y - 16)
                        continue;
                
                var _d = point_distance(from.x, from.y, x, y);
                
                if(_d <= _bd)
                {
                        _bd = _d;
                        _best = self;
                }
        }
        
        return _best;
}

// =====================================================================
//  LADO DEL QUE CUELGA (jugador local)
// =====================================================================

// ¿Puede ESTE jugador (self = jugador local) agarrarse ahora mismo?
// Las vars exclusivas de un personaje solo se leen detras del check
// de global.character (el && cortocircuita, mismo patron del bugfix
// del tarot: si no es ese personaje, la var ni se evalua).
function scr_carry_grab_ok()
{
        // universales de todos los personajes
        if(!global.playerControls || isGrounded || isDead || isHurt || shockedTimer > 0
        || isZipline || isHiding || redRingTimer > 0 || revivalTimes >= 2 || hp <= 0
        || isAttacking || emotion)
                return false;
        
        // Amy Canon: ni dentro de la burbuja, ni en el impulso/flotacion
        // de tarot, ni en el salto de martillo, ni en la acometida, ni
        // en el parry
        if(global.character == CHARACTER_AMY_CANON && (bubbleState == AMY_BUBBLE_ACTIVE
        || isTarotDashing || isTarotFloat || isHJ || isDashing || parryState > 0))
                return false;
        
        // Sonic: ni en Nervios de Acero ni en el parry
        if(global.character == CHARACTER_SONIC && (nerviosState > 0 || parryState > 0))
                return false;
        
        // Knux: ni planeando
        if(global.character == CHARACTER_KNUX && isGliding)
                return false;
        
        return true;
}

// STEP del que cuelga (lo llama obj_carry_controller en End Step con
// self = el jugador local): agarrarse / mantenerse / soltarse.
function scr_carry_step()
{
        if(carryCooldown > 0)
                carryCooldown--;
        
        // ---- COLGANDO: mantener o soltar ----
        if(carryActive)
        {
                // el portador sigue volando? (aterrizo, se quedo sin
                // vuelo, lo hirieron, murio, se desconecto, se
                // demonizo... su estado de red deja de ser el de vuelo)
                var _ok = false;
                
                if(instance_exists(carryPartner) && carryPartner.object_index == obj_player_puppet)
                {
                        if(!carryPartner.isInactive && !carryPartner.isDemonized
                        && carryPartner.hp > 0 && scr_carry_partner_flying(carryPartner))
                                _ok = true;
                }
                
                // salidas forzosas (sin saltito): perdio al portador,
                // toco el suelo, fue herido, murio o se demonizo
                if(!_ok || isGrounded || isDead || isHurt || shockedTimer > 0
                || hp <= 0 || revivalTimes >= 2)
                {
                        scr_carry_end(false, false);
                        return;
                }
                
                // SOLTARSE CON Z (igual que la tirolina)
                if(keyboard_check_pressed(global.KeyA))
                {
                        scr_carry_end(true, false);
                        return;
                }
                
                // mantener: pegado al portador, quieto y sin input.
                // playerControls se re-afirma CADA FRAME porque el
                // netclient lo vuelve a poner en true en sus frames de
                // reconexion (sendTimeout cruzando el 0): mismo
                // defensivismo que la tirolina con su _holdPlayer.
                global.playerControls = false;
                x = carryPartner.x;
                y = carryPartner.y + CARRY_HANG_Y;
                gspd = 0;
                xspd = 0;
                yspd = 0;
                angle = 0;
                return;
        }
        
        // ---- LIBRE: intentar AGARRARSE de un Tails/Cream que vuela ----
        if(!scr_carry_grab_ok() || carryCooldown > 0)
                return;
        
        var _c = scr_carry_find_carrier(id, CARRY_GRAB_RANGE);
        
        if(_c == noone)
                return;
        
        // un pasajero por portador: ¿ya hay alguien colgado de el?
        if(scr_carry_find_hanger(_c, CARRY_GRAB_RANGE + 16) != noone)
                return;
        
        // ---- AGARRE (estilo tirolina: snap + input fuera + snap) ----
        carryActive = true;
        carryPartner = _c;
        carryCooldown = 0;
        isZipline = true;          // estado *_ZIPLINE por red + bloquea habilidades
        global.playerControls = false;
        emotion = false;
        isSpinning = false;
        isJumping = false;
        isAttacking = false;
        angle = 0;
        gspd = 0;
        xspd = 0;
        yspd = 0;
        
        // si el que se agarra es Tails o Cream, deja de volar (cuelga):
        // su propio Step_2 apaga el sonido del vuelo al ver isFlying=false
        if(global.character == CHARACTER_TAILS || global.character == CHARACTER_CREAM || global.character == CHARACTER_VANILLA)
                isFlying = false;
        
        // mira hacia donde mira el portador (su image_xscale viaja por red)
        image_xscale = _c.image_xscale;
        
        x = _c.x;
        y = _c.y + CARRY_HANG_Y;
        
        audio_play_sound(snd_snap, 0, false);
        net_sound_emit(snd_snap);
}

// FIN del colgado. hop = soltar con saltito (Z o senal del portador).
// quiet = no re-emite el snap por red (la senal de drop ya lo hizo
// sonar en 3D para todos los demas).
function scr_carry_end(hop, quiet)
{
        carryActive = false;
        carryPartner = noone;
        carryCooldown = CARRY_REGRAB_CD;
        isZipline = false;
        
        // mismo guard que usa la tirolina al soltar
        if(!obj_netclient.gameEnds)
                global.playerControls = true;
        
        if(hop)
        {
                // el saltito de soltarse (como soltar la liana). El
                // keyboard_key_release evita que este mismo Z pulsado
                // dispare otra cosa justo despues (truco de la tirolina;
                // por ejemplo el vuelo de Cream, que tambien es Z).
                keyboard_key_release(global.KeyA);
                isGrounded = false;
                isJumping = true;
                justJumped = true;
                image_index = 0;
                yspd = CARRY_HOP;
                
                if(!quiet)
                {
                        audio_play_sound(snd_snap, 0, false);
                        net_sound_emit(snd_snap);
                }
        }
}

// =====================================================================
//  LADO DEL PORTADOR (Tails o Cream). Lo llama obj_carry_controller
//  en End Step con self = el jugador local.
// =====================================================================
function scr_carry_carrier_step()
{
        if(global.character != CHARACTER_TAILS && global.character != CHARACTER_CREAM && global.character != CHARACTER_VANILLA && global.character != CHARACTER_AMELIA)
                return;
        
        // herido/muerto/stuneado: nada que hacer (el pasajero se entera
        // solo al ver el estado del puppet cambiar y se suelta el mismo)
        if(!global.playerControls || isDead || isHurt || shockedTimer > 0)
                return;
        
        // ¿llevo a alguien colgado? (check en vivo contra los puppets,
        // igual que hace el abrazo con los cuerpos)
        var _hanger = scr_carry_find_hanger(id, CARRY_CHECK_DIST);
        
        // V = soltar al pasajero: manda un snap SENALADO a su nid; su
        // cliente lo reconoce en el CLIENT_SOUND_EMIT y se suelta con
        // saltito (los demas oyen el snap en 3D desde su posicion)
        if(_hanger != noone && keyboard_check_pressed(global.KeyV))
                net_sound_emit_at(snd_snap, _hanger.master_id);
        
        // (v1.2) Fuera la penalizacion 1.5x de Tails: llevar a
        // alguien ahora ALARGA el vuelo. El tope mientras hay
        // pasajero colgado (TAILS_FLY_CARRY / CREAM_FLY_CARRY =
        // 5.5 seg) lo calcula cada especial con su propio reloj.
}

// =====================================================================
//  RECEPTOR DE LA SENAL DE DROP: lo llama net_state_game cuando llega
//  un snd_snap SENALADO a mi nid (shouldPlay=true). Solo lo emite el
//  portador con la V. Si no estoy colgado de verdad (falso positivo
//  con alguien en una tirolina de mapa), la senal no hace nada.
// =====================================================================
function scr_carry_drop_signal()
{
        // el "para ti" del paquete: el portador ya oyo su propio snap
        // en 3D desde la posicion del pasajero
        audio_play_sound(snd_snap, false, 0);
        
        if(!instance_exists(global.player))
                return;
        
        with(global.player)
        {
                if(!variable_instance_exists(id, "carryActive") || !carryActive)
                        return;
                
                scr_carry_end(true, true);
        }
}
