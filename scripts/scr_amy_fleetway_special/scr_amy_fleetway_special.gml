// =====================================================================
//  v2.14 — FLEETWAY AMY: moveset completo, portado del mod "The
//  Disaster 2D Fleetway Amy" (GameJolt, idkjustsee — rework de Amy
//  inspirado en Sally.exe CN/FN). Reconstruido del bytecode del
//  data.win del mod (scr_amy_special original).
//
//  HABILIDAD 1 — DJ DOBLE SALTO (tecla A, SOLO en el aire):
//    yspd = -6 (FW_DJ_BOOST), vuela FW_DJ_TIME frames con el sprite
//    de DJ, luego cae normal. Al tocar suelo / atacar se corta.
//    CD: FW_DJ_RECHARGE (10 s) o FW_EDJ_RECHARGE con revival >= 2.
//    Sonido: snd_dj (extraido del mod).
//
//  HABILIDAD 2 — BALLESTA (tecla C):
//    v2.15 («La Torre»): cargador de 3 flechas (recarga de 8 s por
//    flecha, 0,5 s entre disparos). La flecha vuela RECTA, se CLAVA
//    en paredes/suelos 5 s y sirve de plataforma (obj_fw_arrow).
//    Contra el EXE: stun de 3 s con reduccion acumulativa por stuns
//    continuos (-17,5% cada uno, tope 50%, reset tras 7 s). Contra
//    esbirros: siempre 3 s. Con revivalTimes >= 2 la flecha hace 20
//    de daño real (puede MATAR; nunca stunea supervivientes).
//    Tras el disparo lleva la ballesta en la mano FW_CB_TIME frames
//    (sprites cbamy 19-21 del array). Sonido: snd_crossbow.
//
//  HABILIDAD 3 — PUÑO / PATADA (tecla B, en el suelo):
//    Golpe cuerpo a cuerpo direccional (según Izq/Der; si no se
//    aprieta ninguna, hacia donde mira). Alterna puño (attack1) y
//    patada (attack2). Mientras ataca NO se mueve (gspd = 0).
//    CD: FW_ATTACK_RECHARGE (20 s) o FW_EATTACK_RECHARGE (5 s).
//
//  SISTEMA DE REVIVAL: igual que el resto de Amys — con
//  revivalTimes >= 2 (demonizada) TODOS los cooldowns bajan y la
//  flecha pasa de stun a daño real.
// =====================================================================
function scr_amy_fleetway_special()
{
        // --- Bloqueos (patrón Amy Canon) ---

        // Anillo rojo: CDs congelados en 2 frames
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;
                if(djTimer <= 2)
                        djTimer = 2;
                if(crossBow <= 2)
                        crossBow = 2;
                if(fwArrowReload <= 2)
                        fwArrowReload = 2;
                isAttacking = false;
                isDJ = false;
        }

        // Escondida: CDs congelados en 2 s
        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;
                if(djTimer <= 60 * 2)
                        djTimer = 60 * 2;
                if(crossBow <= 60 * 2)
                        crossBow = 60 * 2;
                if(fwArrowReload <= 60 * 2)
                        fwArrowReload = 60 * 2;
                isAttacking = false;
                isDJ = false;
        }

        // --- Habilidad 1: DJ DOBLE SALTO (tecla A, SOLO en el aire) ---
        // v4.9 (COYOTE): si acaba de dejar el suelo y esta dentro de la
        // ventana de salto (coyote, cayendo), el Z se lo lleva el SALTO
        // normal — lo da scr_move_basic justo despues de este script —:
        // asi no se come el input del borde. El DJ sale con la SIGUIENTE
        // pulsacion. (coyoteTimer la declara scr_move_basic en su 1er
        // frame; el guard de variable_instance_exists es por si este
        // special corre antes del 1er frame de move_basic.)
        if(global.playerControls && !isDead && !isHurt && shockedTimer <= 0 &&
        keyboard_check_pressed(global.KeyA) && !isGrounded && djTimer == 0
        && !(variable_instance_exists(id, "coyoteTimer") && coyoteTimer > 0 && yspd >= 0))
        {
                isDJ = true;
                isJumping = false;
                yspd = FW_DJ_BOOST;

                audio_play_sound(snd_dj, 0, false);
                net_sound_emit(snd_dj);

                // el timer vuela en negativo: -1 .. -FW_DJ_TIME
                djTimer = -1;
        }

        // Fin del DJ: aterrizar o atacar lo corta
        if(isDJ)
        {
                if(isGrounded)
                        isDJ = false;
                if(isAttacking)
                        isDJ = false;
        }

        // --- Habilidad 2: BALLESTA (tecla C) — v2.15 cargador de 3 ---
        // 0,5 s entre disparos (crossBow) y municion fwArrows; la
        // recarga de cada flecha (8 s) corre siempre que falte alguna.
        // v4.3 (fix exe): demonizada (revivalTimes >= 2) NO PUEDE usar
        // la ballesta — las flechas son un arma anti-exe (plataformas +
        // stun); en manos del bando exe su daño de 20 hacia los
        // supervivientes era demasiado facil (pedido del usuario:
        // "no seria demasiado facil"). La UI la marca en rojo; el
        // cargador se mantiene congelado mientras dure la demonizacion.
        if(global.playerControls && !isDead && !isHurt && shockedTimer <= 0
        && keyboard_check_pressed(global.KeyC) && crossBow <= 0 && fwArrows > 0
        && revivalTimes < 2)
        {
                audio_play_sound(snd_crossbow, 0, false);
                net_sound_emit(snd_crossbow);

                // Flecha con daño real solo demonizada (revival >= 2),
                // igual que el mod original (dmg 20 / stun)
                var _dmg = revivalTimes >= 2 ? 20 : 0;

                // v4.9 — MODO PARED (video del juego original): si hay un
                // muro REAL a su alcance (FW_WALL_REACH) a la altura de los
                // PIES, la flecha sale a la altura de los pies (ya no del
                // pecho) y nace pegada al muro, clavandose casi al instante
                // (1-2 frames de vuelo): es el disparo de ESCALADA del
                // original. Vale tambien en el aire (saltar y disparar en
                // el punto mas alto = colocar la siguiente flecha mas
                // arriba). Lejos de todo muro el disparo es el de siempre:
                // pecho, vuelo recto y largo.
                var _dir = image_xscale >= 0 ? 1 : -1;
                var _sx = x + 12 * _dir;    // pecho (por defecto)
                var _sy = y - 14;

                for(var _d = 12; _d <= FW_WALL_REACH; _d += 4)
                {
                        // y+14 = tobillo: el bbox de la flecha clavada a
                        // la altura del pie (origen en y+18) cubre y+12..y+16
                        if(scr_fw_wall_point(x + _d * _dir, y + 14))
                        {
                                // nace 24 px antes del muro: el barrido de
                                // obj_fw_bolt la clava con la punta
                                // FW_ARROW_BURY px dentro en el primer Step
                                _sx = x + (_d - 24) * _dir;
                                _sy = y + 18;      // altura de los pies
                                break;
                        }
                }

                if(_sx < 1)
                        _sx = 1;     // u16 del server: jamas negativo

                // Sale hacia donde mira
                net_fw_bolt(_sx, _sy, _dir, _dmg);

                // Ballesta en la mano FW_CB_TIME frames (sprites cbamy)
                cbTimer = FW_CB_TIME;

                // Municion: gasta una flecha y arranca el CD de disparo
                fwArrows--;
                crossBow = FW_ARROW_SHOT_CD;
                if(fwArrowReload <= 0)
                        fwArrowReload = FW_ARROW_RELOAD;
        }

        // --- Habilidad 3: PUÑO / PATADA (tecla B, en el suelo) ---
        if(global.playerControls && !isDead && !isHurt && shockedTimer <= 0 &&
        keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && !isAttacking)
        {
                // Dirección del golpe: según la tecla de dirección apretada;
                // si ninguna, hacia donde mira
                var _dir = 0;
                if(keyboard_check(global.KeyLeft))
                        _dir = -1;
                else if(keyboard_check(global.KeyRight))
                        _dir = 1;
                else
                        _dir = image_xscale >= 0 ? 1 : -1;

                image_xscale = _dir;

                // Alterna puño (attack1) / patada (attack2)
                attackNum = !attackNum;
                isAttacking = true;
                gspd = 0; // mientras ataca no se mueve (mod original)

                attackTimer = revivalTimes >= 2 ? FW_EATTACK_RECHARGE : FW_ATTACK_RECHARGE;
        }

        // --- Estados y timers ---

        // La ballesta en la mano mientras dura cbTimer
        isCB = cbTimer > 0;
        if(cbTimer > 0)
                cbTimer--;

        // El golpe congela el movimiento (mod original)
        if(isAttacking)
                gspd = 0;

        // DJ: mientras djTimer < 0 esta volando; al llegar a -FW_DJ_TIME
        // empieza el cooldown (normal o demonizado)
        if(djTimer < 0)
        {
                djTimer--;
                if(djTimer <= -FW_DJ_TIME)
                        djTimer = revivalTimes >= 2 ? FW_EDJ_RECHARGE : FW_DJ_RECHARGE;
        }
        else if(djTimer > 0)
                djTimer--;

        if(attackTimer > 0)
                attackTimer--;

        // v2.15 («La Torre»): CD corto entre disparos + recarga de la
        // siguiente flecha (8 s por flecha mientras falte alguna).
        if(crossBow > 0)
                crossBow--;

        // v4.3 (fix exe): demonizada no recarga flechas — el cargador
        // queda congelado mientras dure la demonizacion (la ballesta
        // esta bloqueada arriba). Al volver a superviviente (no ocurre
        // en partida normal, pero por consistencia) sigue donde estaba.
        if(fwArrows < FW_ARROW_MAX && revivalTimes < 2)
        {
                if(fwArrowReload > 0)
                        fwArrowReload--;
                else
                {
                        fwArrows++;
                        if(fwArrows < FW_ARROW_MAX)
                                fwArrowReload = FW_ARROW_RELOAD;
                }
        }
}
