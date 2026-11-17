// =====================================================================
//  KRIS (Deltarune) — v1. Moveset completo sobre la base Tails:
//
//   * Z EN EL AIRE = NADA. Kris NO vuela ni planea (regla de la
//     duena: "literalmente dije Knuckles porque sus habilidades, el
//     puno = espada; el no tiene glide"). Su "slot glide" lo ocupa el
//     ESCUDO (tecla C, en tierra — ver scr_parry.gml). El Z en tierra
//     es el salto de siempre (scr_move_basic).
//
//   * X = ESPADA (patron puno de Knuckles / patada de Rouge): en
//     tierra un tajo y en el aire el ataque de DOS fases:
//       fase 1 (estado 40): spr_kris_attack1_air1 (4 frames)
//       fase 2 (estado 41): spr_kris_attack1_air2 (8 frames) con
//         hitbox +50% (pad del puppet) e I-FRAMES mientras dura
//         (guard en scr_player_hurt).
//     La fase se fija al iniciar (patron Sonic: si empezo en el aire
//     sigue contando como aire aunque aterrice). Stun de 3 s al bando
//     EXE por contacto (lo aplica el cliente de la victima con el bit
//     PLAYER_ATTACKING de obj_netclient/Step_2). Recarga: la del puno
//     de Knuckles (14,75 s).
//
//   * 1ra caida -> MORIBUNDA (patron Rouge v4.5): 6 s tirado, inmune
//     a todo, se levanta solo con 40 de vida. El server JAMAS se
//     entera de esa caida. La activa scr_player_instakill.
//   * 2da caida -> MUERTE REAL directa: Kris JAMAS se demoniza ni se
//     convierte en subdito negativo (guards del server + de
//     scr_jinna_negatouch) y JAMAS es absorbible por Jinna (la trampa
//     es SIEMPRE kind 0: dano + TP normal).
// =====================================================================

// ---- stats (base Tails: el placeholder de la duena) ----
#macro KRIS_MAXSPEED 11
#macro KRIS_ACC 0.046875

// ---- espada ----
#macro KRIS_ATTACK_RECHARGE (60 * 14.75) // misma cadencia del puno de Knux
#macro KRIS_ATK_GROUND_SPD 0.4           // tajo tierra: 4 frames
#macro KRIS_ATK_AIR1_SPD 0.4             // air1: 4 frames
#macro KRIS_ATK_AIR2_SPD 0.5             // air2: 8 frames
#macro KRIS_AIR2_HITBOX 0.5              // +50% del ancho del bbox (pad del puppet)

// ---- escudo (patron parry) ----
#macro KRIS_BLOCK_EXITO_PER 3.5  // frames de juego por frame del sprite de exito
#macro KRIS_BLOCK_VISION -8      // margen frontal: dx*face >= esto cuenta como "de frente"

// ---- moribunda (patron Rouge v4.5, mismos numeros) ----
#macro KRIS_MORIBUNDA_TIME (60 * 6)  // tirado en el suelo
#macro KRIS_MORIBUNDA_HEAL 40        // se levanta con poca vida
#macro KRIS_MORIBUNDA_INVULN (60 * 3)
#macro KRIS_MORIBUNDA_LEVITATE -0.35 // flota solo si cayo a un hoyo

// ---- estados de red (patron Rouge + dinamicos de Sonic) ----
#macro KRIS_ZIPLINE BALANCING+4   // 17: tirolina (patron Knux)
#macro KRIS_STUCK BALANCING+5     // 18: atascado (sin uso: sin agarre de pared)
#macro KRIS_MORIBUNDA BALANCING+6 // 19: 1ra caida tirada (mismo slot que Rouge/Vanilla)
#macro KRIS_ATK_TIERRA 20         // tajo en tierra (rango 20-39, patron Sonic)
#macro KRIS_ATK_AIRE 40           // air1 = 40, air2 = 41 (rango 40-59, patron Sonic)

function scr_kris_special()
{
        // ---------------- MORIBUNDA (1ra caida, patron Rouge) ----------------
        if(moribundaState > 0)
        {
                gspd = 0;
                xspd = 0;

                // mismo mini-fix de Vanilla/Rouge: debilitado EN EL AIRE cae al
                // suelo en vez de quedarse flotando; la levitacion queda SOLO
                // para el hoyo de verdad (sin terreno en la columna de abajo)
                if(isGrounded)
                        yspd = 0;
                else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
                        yspd = KRIS_MORIBUNDA_LEVITATE;
                else
                        yspd = min(yspd + yAccel, maxYSpeed);

                isJumping = false;
                isSpinning = false;
                isAttacking = false;
                krisAtkVariant = 0;

                // el escudo no sobrevive a la caida (mismo trato que el parry
                // recibe del stun: cuenta como fallo y entra en recarga)
                if(parryState > 0 && parryState != 4)
                {
                        if(parryCooldown <= 0)
                                scr_parry_apply_cd(SONIC_PARRY_CD_FAIL);

                        parryState = 0;
                        parryActive = false;
                        parryLateSignal = 0;
                }

                if(isStuck)
                {
                        canMove = true;
                        isStuck = false;
                }

                moribundaTimer--;

                if(moribundaTimer <= 0)
                {
                        moribundaState = 0;
                        hp = KRIS_MORIBUNDA_HEAL;
                        hurttime = KRIS_MORIBUNDA_INVULN;
                        isHurt = false;
                        attackTimer = 0; // misericordia: espada lista al levantarse
                }

                return;
        }

        // anillo rojo / esconderse: sin espada (patron Knux/Rouge)
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;

                isAttacking = false;
                krisAtkVariant = 0;
        }

        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;

                isAttacking = false;
                krisAtkVariant = 0;
        }

        // ---------------- Z EN EL AIRE: NADA ----------------
        // Kris (Deltarune) no vuela ni planea: NO hay vuelo patron Tails ni
        // planeo patron Knux en el slot Z aereo. Su "slot glide" es el
        // ESCUDO (tecla C, en tierra): ver scr_parry_step en scr_parry.gml.

        // ---------------- ESPADA (tecla X) ----------------
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && !isAttacking)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                attackTimer = KRIS_ATTACK_RECHARGE;
                isAttacking = true;

                // fase fija al iniciar (patron Sonic): 1 = tierra, 2 = air1.
                // La subida a air2 la decide el bloque de abajo con la fase 1
                // terminada (ataque aereo de DOS fases, no combo de input).
                krisAtkVariant = isGrounded ? 1 : 2;

                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
        }

        // FASE 2 AEREA: al terminar air1 salta directamente a air2 (el
        // tajo grande: hitbox +50% del puppet e i-frames). Solo si sigue
        // en el aire: aterrizar a mitad cierra el ataque con normalidad.
        // (El Draw_76 del estado 40 NO apaga isAttacking en su ultimo frame
        // a proposito: este bloque es quien sabe si hay fase 2 que correr.)
        if(isAttacking && krisAtkVariant == 2)
        {
                if(!isGrounded && sprite_index == spr_kris_attack1_air1 && image_index >= image_number - 1)
                {
                        krisAtkVariant = 3;
                        image_index = 0;
                }
                else if(isGrounded && image_index >= image_number - 1)
                        isAttacking = false;
        }

        if(isAttacking)
        {
                // empujoncito del tajo (patron puno de Knux / patada de Rouge)
                gspd = 0;
                xspd = image_xscale * (isGrounded ? .5 : 2);
        }
        else if(krisAtkVariant != 0)
                krisAtkVariant = 0;

        if(attackTimer > 0)
                attackTimer--;
}

// =====================================================================
//  HELPERS DEL ESCUDO (los usa scr_parry.gml). El escudo de Kris es
//  DIRECCIONAL: solo bloquea lo que viene DE FRENTE o del aire hacia
//  donde mira ("si esta al frente de el o en orientacion aerea a donde
//  el mira; si el ataque viene de espaldas no lo bloqueara").
// =====================================================================

// ¿el punto/instancia _from esta en la vision frontal de _target
// (el Kris que bloquea)?Margen KRIS_BLOCK_VISION para cubrir "justo
// encima" (un ataque aereo que cae sobre su cabeza si cuenta).
function scr_kris_block_front(_target, _from)
{
        var _dx = _from.x - _target.x;
        var _face = _target.image_xscale >= 0 ? 1 : -1;
        return _dx * _face >= KRIS_BLOCK_VISION;
}

// ¿el atacante _from estaba EN EL AIRE? (elige la animacion de exito:
// spr_kris_block_success_air vs _ground). Puppets: por su estado de
// red (JUMP/FALL); otras fuentes (laser, etc.): por altura relativa.
function scr_kris_block_attacker_air(_from, _target)
{
        if(variable_instance_exists(_from.id, "state"))
                return (_from.state == JUMP || _from.state == FALL);

        return _from.y < _target.y - 10;
}