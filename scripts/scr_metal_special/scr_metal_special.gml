// =====================================================================
//  METAL SONIC (v2.2, rescatado de TD2D Through the Blood).
//  v2.7: kit con los nombres de su placa del TTB —
//   * OVERDRIVE (tecla X; placa: "DEFENSE: OVERDRIVE 2 SEC."):
//     impulsion AUTOMATICA (v2.7, pedido del usuario). Una pulsacion
//     de X y Metal sale solo, sin mantener nada: su velocidad AUMENTA
//     de la carrera (11) al tope (16) en 0.4 s y se mantiene; dura
//     2 s (placa) o hasta CHOCHAR CONTRA UNA PARED (corte con
//     polvareda + mini-temblor de camara). Al killer que lo toque en
//     pleno overdrive lo aturde 3 s (via isAttacking, el mismo canal
//     del escudo de Eggman: el stun lo aplica el cliente del killer
//     en obj_player_puppet). Recarga 40 s. (v2.2-v2.6 era "dash":
//     exiga mantener X y duraba hasta 10 s.)
//   * SPARK FIELD (tecla C; placa: "SPARK FIELD 2 SEC."): el
//     electrocampo de v2.2 con su nombre de placa. Electrificado 1
//     segundo; cualquier killer que lo toque queda aturdido 3 s (el
//     golpe electrico lo pone el cliente del killer: caso METAL en
//     obj_player_puppet, con spr_shockparticle + snd_metal_electro).
//     Recarga 30 s. NOTA: la placa dice 2 s y el juego usa 1 s desde
//     v2.2 — sin tocar (misma decision pendiente que la TRAP 2/3 s
//     de Amelia); si lo quieres alineado, cambia METAL_ELECTRO_TIME.
//  Stats: carrera de superviviente estandar (11); como robot que es,
//  arranca un pelin mas pesado (acc 0.040). El overdrive es su
//  velocidad real (16, ver METAL_OVERDRIVE_SPEED): ahi si supera a
//  los EXE.
//  Valores canonicos del 110v: survivors 11 / EXE 12.
// =====================================================================
#macro METAL_MAXSPEED 11
#macro METAL_ACC 0.040
#macro METAL_OVERDRIVE_RECHARGE (60 * 28)
#macro EMETAL_OVERDRIVE_RECHARGE (60 * 15)
#macro METAL_OVERDRIVE_TIME (60 * 2)   // duracion maxima (placa: 2 s)
#macro METAL_OVERDRIVE_SPEED 16       // velocidad tope del overdrive
#macro METAL_OVERDRIVE_RAMP 24        // frames en subir de 11 a 16
#macro METAL_ELECTRO_RECHARGE (60 * 21)
#macro EMETAL_ELECTRO_RECHARGE (60 * 12)
#macro METAL_ELECTRO_TIME 60         // 1 s electrificado (placa: 2 s, ver nota)

// v3.0 («GENIO MALVADO», la otra mitad de la pasiva del Dr. Eggman):
// el genio REPARA a Metal por proximidad. Valores ajustables:
//  * HEAL_HP        = vida por tictac de reparacion
//  * HEAL_CD_EGG    = cada 7 s cerca del DR. EGGMAN (prioridad)
//  * HEAL_CD_TAILS  = cada 13 s cerca de TAILS (manos de mecanico)
//  * HEAL_RANGE     = px de "estar cerca"
// Si estan los DOS cerca NO se acumula: solo aplica la del Dr.
#macro METAL_GENIUS_HEAL_HP 10
#macro METAL_GENIUS_HEAL_CD_EGG (60 * 8)
#macro METAL_GENIUS_HEAL_CD_TAILS (60 * 14)
#macro METAL_GENIUS_HEAL_RANGE 90

function scr_metal_special()
{
        // Red ring / esconderse: cooldowns al minimo y sin atacar
        if(redRingTimer > 0 || isHiding)
        {
                if(dashTimer <= 60 * 2)
                        dashTimer = 60 * 2;

                if(electroTimer <= 60 * 2)
                        electroTimer = 60 * 2;

                isAttacking = false;
                metalDashing = 0;
        }

        // ---- OVERDRIVE (tecla X) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && dashTimer <= 0 && !metalDashing && !isElectro && isGrounded)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                metalDashing = METAL_OVERDRIVE_TIME;
                isAttacking = true;
                isSpinning = false;
                image_index = 0;

                audio_play_sound(snd_metal_dash, 0, false);
                net_sound_emit(snd_metal_dash);
        }

        if(metalDashing > 0)
        {
                // v2.7 IMPULSO AUTOMATICO: ya no hay que mantener X —
                // una pulsacion y sigue solo. Solo lo cortan dano,
                // stun, muerte (y abajo la pared, el rebote en resorte
                // de scr_collision_objects o el anillo rojo/esconderse).
                if(isHurt || isDead || shockedTimer > 0)
                        metalDashing = 1; // cortar en el siguiente bloque

                // v2.7 AUMENTO DE VELOCIDAD: arranca a la velocidad de
                // carrera y sube linealmente hasta el tope en
                // METAL_OVERDRIVE_RAMP frames; luego se mantiene.
                var _ovElapsed = METAL_OVERDRIVE_TIME - metalDashing;
                var _ovSpeed = METAL_MAXSPEED + (METAL_OVERDRIVE_SPEED - METAL_MAXSPEED) * min(_ovElapsed / METAL_OVERDRIVE_RAMP, 1);

                // velocidad en la direccion del overdrive
                maxHSpeed = _ovSpeed;
                xspd = _ovSpeed * image_xscale;
                gspd = xspd;
                acc = 1;

                // estela
                if(floor(x) mod 3 == 0)
                        net_quick_effect(x - 10 * image_xscale, y, spr_dust);

                // CHOQUE CONTRA PARED: corta el overdrive con polvareda
                // y mini-temblor de camara (mismo feedback que el
                // lanzamiento del spindash de Amelia v2.6)
                if(place_meeting(x + 4 * image_xscale, y, obj_floor_parent) || place_meeting(x - 4 * image_xscale, y, obj_floor_parent))
                {
                        metalDashing = 1;
                        scr_camera_shake(12, 2, 0.2);

                        repeat(4)
                                net_quick_effect(x + 8 * image_xscale + random_range(-6, 6), y + random_range(-10, 4), spr_dust);
                }

                metalDashing--;

                if(metalDashing <= 0)
                {
                        isAttacking = false;
                        dashTimer = revivalTimes >= 2 ? EMETAL_OVERDRIVE_RECHARGE : METAL_OVERDRIVE_RECHARGE;
                }
        }
        else
        {
                if(isSlow)
                {
                        maxHSpeed = (METAL_MAXSPEED * (100-30)) / 100;
                        acc = (METAL_ACC * (100-30)) / 100;
                }
                else
                {
                        maxHSpeed = METAL_MAXSPEED;
                        acc = METAL_ACC;
                }
        }

        // ---- ELECTRO (tecla C) ----
        if(global.playerControls && keyboard_check_pressed(global.KeyC) && electroTimer <= 0 && metalDashing <= 0)
        {
                isElectro = METAL_ELECTRO_TIME;
                isAttacking = true;
                image_index = 0;

                audio_play_sound(snd_metal_electro, 0, false);
                net_sound_emit(snd_metal_electro);

                net_quick_effect(x, y, spr_shockparticle);
        }

        if(isElectro > 0)
        {
                isElectro--;

                // chispas alrededor mientras dura
                if(isElectro mod 8 == 0)
                        net_quick_effect(x + random_range(-14, 14), y + random_range(-20, 4), spr_shockparticle);

                if(isElectro <= 0 || isHurt || isDead || shockedTimer > 0)
                {
                        isElectro = 0;

                        if(metalDashing <= 0)
                                isAttacking = false;

                        electroTimer = revivalTimes >= 2 ? EMETAL_ELECTRO_RECHARGE : METAL_ELECTRO_RECHARGE;
                }
        }

        // ---- GENIO MALVADO: REPARACION por proximidad (v3.0) ----
        // Corre en el cliente del PROPIO Metal (el es la autoridad de
        // su hp, mismo modelo que la curacion de Chocola): busca al Dr.
        // Eggman o a Tails entre los puppets vivos y sin demonizar.
        // Con los DOS cerca NO se acumula: manda la del Dr. (7 s).
        if(!isDead && revivalTimes < 2 && hp < 100)
        {
                var _eggNear = false;
                var _tailsNear = false;

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(isDemonized || isInactive || hp <= 0)
                                        continue;

                                if(character != CHARACTER_EGGMAN && character != CHARACTER_TAILS)
                                        continue;

                                if(distance_to_object(global.player) > METAL_GENIUS_HEAL_RANGE)
                                        continue;

                                if(character == CHARACTER_EGGMAN)
                                        _eggNear = true;
                                else
                                        _tailsNear = true;
                        }
                }

                if(geniusHealTimer > 0)
                {
                        geniusHealTimer--;

                        if(geniusHealTimer <= 0 && (_eggNear || _tailsNear))
                        {
                                hp = min(100, hp + METAL_GENIUS_HEAL_HP);

                                audio_play_sound(snd_heal, 0, false);
                                net_sound_emit(snd_heal);

                                net_quick_effect(x, y - 14, spr_shockparticle, false, 1, 0, -1, 1);

                                geniusHealTimer = _eggNear ? METAL_GENIUS_HEAL_CD_EGG : METAL_GENIUS_HEAL_CD_TAILS;
                        }
                }
                else if(_eggNear || _tailsNear)
                        geniusHealTimer = _eggNear ? METAL_GENIUS_HEAL_CD_EGG : METAL_GENIUS_HEAL_CD_TAILS;
        }

        if(dashTimer > 0)
                dashTimer--;

        if(electroTimer > 0)
                electroTimer--;
        // (la reparacion del Genio Malvado se PAUSA a vida llena, muerto
        //  o demonizado: no gasta tictacs, retoma donde iba)
}
