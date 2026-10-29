// =====================================================================
//  ABRAZO COMBINADO  (interaccion especial Amy Canon + Sonic)
// =====================================================================
//  COMO SE USA:
//   * Amy Canon pulsa la tecla del EMOTE 3 estando quieta (IDLE).
//   * Si hay un Sonic cerca (48 px) y ese Sonic esta "abrazable" (ni
//     caminando ni haciendo ninguna accion: parado o emoteando), en
//     vez del emote normal se genera EL ABRAZO: Amy se coloca a su
//     lado y en las pantallas de todos aparece el sprite combinado
//     spr_amy_hug_canon (Amy abrazando a Sonic con corazones).
//   * Si no hay Sonic cerca, el EMOTE 3 funciona igual que siempre.
//   * Dura mientras Amy mantenga la tecla. Sonic puede soltarse en
//     cualquier momento pulsando cualquier tecla de accion/movimiento.
//
//  COMO FUNCIONA POR RED (sin tocar el server):
//   * El estado de cada jugador viaja solo en CLIENT_PLAYER_DATA
//     (campo state, u8) y el server lo rebotea tal cual. Nada nuevo
//     que compilar del lado del server.
//   * Amy viaja en el estado AMY_CANON_HUG; Sonic responde solo:
//     su cliente ve el puppet de Amy en estado de abrazo cerca de el
//     y, si es abrazable, entra en SONIC_HUGGED y lo rebotea.
//   * El sprite combinado lo dibuja LA ENTIDAD DE AMY (el jugador
//     local de Amy o su puppet en las demas maquinas) en el punto
//     medio entre los dos; el cuerpo de Sonic (local o puppet) no se
//     dibuja mientras dura (check en vivo, no depende del estado
//     sincronizado, para cubrir los ~200 ms de latencia de entrada).
//   * Amy queda pegada a Sonic con un snap al iniciar (su posicion
//     viaja normal, asi el resto de clientes la ven al lado suyo).
//
//  ESTADOS (no estan en los arrays de scr_survivors: se interceptan
//  en Draw_76/Draw_72 antes del array, igual que el parry de Sonic):
//   * AMY_CANON_HUG  = BALANCING+11 = 24 (libre: Canon usa 14..23)
//   * SONIC_HUGGED   = 65            (libre: parry usa 60/61/64)
//
//  DONDE SE ENGANCHA:
//   * scr_move_basic.gml: la tecla del EMOTE 3 llama scr_amy_hug_try_start
//     y los dos estados nuevos se anaden al reset automatico de emotion.
//   * obj_amy_canon: Create_0 (vars), Step_0 (scr_amy_hug_step_amy),
//     Step_2 (estado), Draw_76 (sprite), Draw_0 (sprite combinado).
//   * obj_sonic: Create_0 (vars), Step_0 (scr_amy_hug_step_sonic),
//     Step_2 (estado 65), Draw_76, Draw_0 (cuerpo oculto).
//   * obj_player_puppet: Draw_72 (estados) y Draw_0 (dibujo combinado
//     de Amy + cuerpo de Sonic oculto, para las otras maquinas).
// =====================================================================

// ===== ESTADOS DE RED =====
#macro AMY_CANON_HUG  (BALANCING+11)   // 24: Amy abrazando (sprite combinado)
#macro SONIC_HUGGED   65               // Sonic abrazado (cuerpo oculto)

// ===== NUMEROS =====
#macro AMY_HUG_RANGE   48   // px: distancia maxima para INICIAR el abrazo
#macro AMY_HUG_KEEP    72   // px: si se separan mas que esto, se rompe
#macro AMY_HUG_DIST    14   // px: separacion exacta de los cuerpos (del sprite)
#macro AMY_HUG_YDIST   12   // px: diferencia de altura maxima para iniciar

// ¿Sonic esta "abrazable"? Parado (IDLE) o emoteando, o ya en el
// abrazo (el SONIC_HUGGED se necesita para el hueco de latencia:
// mientras su 65 viaja de vuelta, su puppet sigue en IDLE/EMOTION).
function scr_amy_hug_state_ok(st)
{
        return st == IDLE || st == EMOTION1 || st == EMOTION2 || st == EMOTION3 || st == SONIC_HUGGED;
}

// =====================================================================
//  BUSQUEDA DE ENTIDADES (mix jugador local + puppets)
// =====================================================================

// El Sonic mas cercano a "from" (instancia), a menos de "rng" px y en
// un estado abrazable. La usa Amy para iniciar y su puppet (en las
// otras maquinas) para dibujar el sprite combinado.
function scr_amy_hug_find_sonic(from, rng)
{
        if(from == noone)
                return noone;

        var _best = noone;
        var _bd = rng;

        // Sonic local (solo existe si ESTE cliente juega Sonic)
        if(global.character == CHARACTER_SONIC && instance_exists(global.player)
        && !global.player.isDead && scr_amy_hug_state_ok(global.player.state))
        {
                var _d = point_distance(from.x, from.y, global.player.x, global.player.y);
                if(_d <= _bd)
                {
                        _bd = _d;
                        _best = global.player;
                }
        }

        // puppets de Sonic
        with(obj_player_puppet)
        {
                if(character != CHARACTER_SONIC || isInactive || isDemonized)
                        continue;

                if(!scr_amy_hug_state_ok(state))
                        continue;

                var _d2 = point_distance(from.x, from.y, x, y);
                if(_d2 <= _bd)
                {
                        _bd = _d2;
                        _best = self;
                }
        }

        return _best;
}

// La Amy Canon mas cercana a "from" que este EN ABRAZO (estado
// AMY_CANON_HUG), a menos de "rng" px. La usa el Sonic local para
// entrar solo al abrazo y el dibujado del Sonic (local o puppet)
// para saber si debe esconder su cuerpo (check en vivo).
function scr_amy_hug_amy_near(from, rng)
{
        if(from == noone)
                return noone;

        var _best = noone;
        var _bd = rng;

        // Amy Canon local (solo existe si ESTE cliente juega Amy Canon)
        if(global.character == CHARACTER_AMY_CANON && instance_exists(global.player)
        && !global.player.isDead && global.player.state == AMY_CANON_HUG)
        {
                var _d = point_distance(from.x, from.y, global.player.x, global.player.y);
                if(_d <= _bd)
                {
                        _bd = _d;
                        _best = global.player;
                }
        }

        // puppets de Amy Canon abrazando
        with(obj_player_puppet)
        {
                if(character != CHARACTER_AMY_CANON || isInactive || isDemonized)
                        continue;

                if(state != AMY_CANON_HUG)
                        continue;

                var _d2 = point_distance(from.x, from.y, x, y);
                if(_d2 <= _bd)
                {
                        _bd = _d2;
                        _best = self;
                }
        }

        return _best;
}

// =====================================================================
//  LADO DE AMY (jugador local)
// =====================================================================

// INICIO: la llama scr_move_basic cuando Amy Canon pulsa la tecla del
// EMOTE 3 estando IDLE. Si hay un Sonic abrazable cerca arranca EL
// ABRAZO en vez del emote normal. Devuelve true solo si lo inicio.
function scr_amy_hug_try_start()
{
        if(global.character != CHARACTER_AMY_CANON)
                return false;

        // Amy tiene que estar "emoticable" igual que para un emote:
        // en tierra, sin nada en manos, viva, sin stun/burbuja
        if(!global.playerControls || !isGrounded || isDead || isHurt || shockedTimer > 0
        || bubbleState == AMY_BUBBLE_ACTIVE || isAttacking || isDashing || isTarotDashing
        || isTarotFloat || isHJ || isZipline || isOnEdge || revivalTimes >= 2)
                return false;

        // v4.0: con el PARRY en curso no se abraza (el abrazo congela a
        // Amy y dejaria un hugActive invisible conviviendo con la
        // ventana del parry; sale el emote normal y ya podra abrazar
        // cuando termine)
        if(parryState > 0)
                return false;

        var _sonic = scr_amy_hug_find_sonic(id, AMY_HUG_RANGE);
        if(_sonic == noone)
                return false;

        // no abrazar a alguien muy arriba/abajo (escaleras, plataformas)
        if(abs(_sonic.y - y) > AMY_HUG_YDIST)
                return false;

        // estado inicial
        hugActive = true;
        hugPartner = _sonic;
        hugSide = (x <= _sonic.x) ? 1 : -1;   // 1 = Amy queda a la IZQUIERDA (sprite tal cual)
        emotion = true;
        image_index = 0;

        // SNAP: Amy queda exactamente a AMY_HUG_DIST del cuerpo de
        // Sonic, como estan los dos dentro del sprite combinado. Solo
        // al iniciar: si la colision la empuja un par de px no pasa
        // nada (el sprite se ancla al punto medio, nadie ve la
        // diferencia). Su posicion viaja normal por red.
        x = _sonic.x - hugSide * AMY_HUG_DIST;
        y = _sonic.y;
        gspd = 0;
        xspd = 0;
        yspd = 0;

        return true;
}

// STEP de Amy (lo llama obj_amy_canon/Step_0 arriba del todo).
function scr_amy_hug_step_amy()
{
        if(!hugActive)
                return;

        // salidas forzosas: cualquier cosa que le pase a Amy
        if(isDead || isHurt || shockedTimer > 0 || bubbleState == AMY_BUBBLE_ACTIVE
        || isZipline || !global.playerControls)
        {
                scr_amy_hug_end_amy();
                return;
        }

        // Amy suelta la tecla del emote 3 -> fin (como los emotes)
        if(!keyboard_check(global.KeyEm3))
        {
                scr_amy_hug_end_amy();
                return;
        }

        // cualquier otra tecla de accion/movimiento la saca del abrazo
        // (la V del parry tambien: puede romper el abrazo y parrear en
        // el mismo frame, como hace Sonic con su C)
        if(keyboard_check(global.KeyLeft) || keyboard_check(global.KeyRight)
        || keyboard_check_pressed(global.KeyUp) || keyboard_check_pressed(global.KeyDown)
        || keyboard_check_pressed(global.KeyA) || keyboard_check_pressed(global.KeyB)
        || keyboard_check_pressed(global.KeyC) || keyboard_check_pressed(global.KeyV)
        || keyboard_check_pressed(global.KeyHide))
        {
                scr_amy_hug_end_amy();
                return;
        }

        // el Sonic objetivo sigue abrazable? (se fue, lo hirieron,
        // empezo a caminar, murio, se desconecto...)
        var _ok = false;

        if(instance_exists(hugPartner) && hugPartner.object_index == obj_player_puppet)
        {
                if(!hugPartner.isInactive && !hugPartner.isDemonized
                && scr_amy_hug_state_ok(hugPartner.state)
                && point_distance(x, y, hugPartner.x, hugPartner.y) <= AMY_HUG_KEEP)
                        _ok = true;
        }

        if(!_ok)
        {
                scr_amy_hug_end_amy();
                return;
        }

        // mantener: quieta, sprite fijo
        gspd = 0;
        xspd = 0;
        if(isGrounded)
                yspd = 0;

        image_index = 0;
}

// FIN del abrazo para Amy (estado -> IDLE en el proximo Step_2).
function scr_amy_hug_end_amy()
{
        hugActive = false;
        hugPartner = noone;
        emotion = false;
        image_speed = 1;
}

// =====================================================================
//  LADO DE SONIC (jugador local)
// =====================================================================

// STEP de Sonic (lo llama obj_sonic/Step_0 arriba del todo): entrada
// automatica al abrazo (cuando el puppet de Amy cerca ya esta en
// estado de abrazo) + mantenimiento + salidas.
function scr_amy_hug_step_sonic()
{
        // ---- entrada: solo si soy abrazable y hay una Amy abrazandome ----
        if(!hugged)
        {
                if(!global.playerControls || !isGrounded || isDead || isHurt
                || shockedTimer > 0 || nerviosState > 0 || parryState > 0
                || isAttacking || isSpinCharging || isZipline || isOnEdge
                || revivalTimes >= 2)
                        return;

                // ni caminando ni haciendo ninguna accion: parado o emoteando
                if(state != IDLE && state != EMOTION1 && state != EMOTION2 && state != EMOTION3)
                        return;

                var _amy = scr_amy_hug_amy_near(id, AMY_HUG_RANGE);
                if(_amy == noone)
                        return;

                if(abs(_amy.y - y) > AMY_HUG_YDIST)
                        return;

                hugged = true;
                hugAmy = _amy;
                emotion = true;   // bloquea sus emotes mientras dura
                image_index = 0;
                gspd = 0;
                xspd = 0;
                if(isGrounded)
                        yspd = 0;

                return;
        }

        // ---- salidas forzosas ----
        if(isDead || isHurt || shockedTimer > 0 || nerviosState > 0
        || isZipline || !global.playerControls)
        {
                scr_amy_hug_end_sonic();
                return;
        }

        // Sonic se quiere ir: cualquier tecla de accion/movimiento rompe
        // el abrazo (C incluida: puede romper el abrazo y parrear)
        if(keyboard_check(global.KeyLeft) || keyboard_check(global.KeyRight)
        || keyboard_check_pressed(global.KeyUp) || keyboard_check_pressed(global.KeyDown)
        || keyboard_check_pressed(global.KeyA) || keyboard_check_pressed(global.KeyB)
        || keyboard_check_pressed(global.KeyC) || keyboard_check_pressed(global.KeyHide))
        {
                scr_amy_hug_end_sonic();
                return;
        }

        // Amy dejo de abrazar? (solto la tecla, la hirieron, murio, se
        // desconecto...) su estado de red ya no es AMY_CANON_HUG
        var _ok = false;

        if(instance_exists(hugAmy))
        {
                if(hugAmy.object_index == obj_player_puppet)
                {
                        if(!hugAmy.isInactive && hugAmy.state == AMY_CANON_HUG
                        && point_distance(x, y, hugAmy.x, hugAmy.y) <= AMY_HUG_KEEP)
                                _ok = true;
                }
                else
                {
                        // la Amy local de ESTE cliente (no deberia pasar:
                        // Sonic y Amy Canon no comparten cliente; por si
                        // acaso, con el estado basta)
                        if(hugAmy.state == AMY_CANON_HUG)
                                _ok = true;
                }
        }

        if(!_ok)
        {
                scr_amy_hug_end_sonic();
                return;
        }

        // mantener: quieto
        gspd = 0;
        xspd = 0;
        if(isGrounded)
                yspd = 0;

        image_index = 0;
}

// FIN del abrazo para Sonic (estado -> IDLE en el proximo Step_2).
function scr_amy_hug_end_sonic()
{
        hugged = false;
        hugAmy = noone;
        emotion = false;
        image_speed = 1;
}
