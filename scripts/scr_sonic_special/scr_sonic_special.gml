function scr_sonic_special()
{
        // =================================================================
        //  ATAQUE 1: EL GOLPE (tecla X) - estilo EXE
        //  Sonic pega como pegan los killers: mismo sprite
        //  (spr_sonic_attack2) y mismo sonido (snd_dash) que el ataque
        //  normal del EXE original / Exetior. No se frena al golpear
        //  (conserva el impulso, como los EXE). El EXE o demonizado que
        //  lo toque mientras pega queda aturdido 3s (sistema estandar).
        //  CD: attackTimer (SONIC_ATTACK_RECHARGE / EATTACK demonizado).
        // =================================================================
        
        // --- Bloqueos (mismo patron que Amy Canon) ---
        
        // Con el anillo rojo puesto no puede usar el golpe: se cancela
        // y el CD queda congelado en 2 frames.
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;
                
                isAttacking = false;
                isSpinCharging = false;   // el anillo rojo corta la carga
        }
        
        // Escondida (agachado en un escondite): no puede golpear y el
        // CD queda congelado en 2 segundos.
        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;
                
                isAttacking = false;
                isSpinCharging = false;
        }
        
        // --- ATAQUE 1: inicio del golpe (tecla X) ---
        if(global.playerControls && !isAttacking && !isSpinCharging
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && keyboard_check_pressed(global.KeyB) && attackTimer <= 0)
        {
                // Direccion: si aprietas izquierda/derecha al iniciar,
                // el golpe va hacia ese lado; si no, hacia donde miras.
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;
                
                image_index = 0;
                attackTimer = revivalTimes >= 2 ? SONIC_EATTACK_RECHARGE : SONIC_ATTACK_RECHARGE;
                isAttacking = true;        // el EXE que te toque queda aturdido 3s (sistema del juego)
                isJumping = false;
                isSpinning = false;
                
                // VARIANTE del golpe (se decide al INICIARLO y no cambia a
                // mitad de animacion): en el AIRE sale SIEMPRE una variante
                // aerea (spr_sonic_attack2_aereo<N>); en TIERRA una terrestre
                // (spr_sonic_attack2_tierra<N>). Cualquier sprite con ese
                // nombre + numero cuenta como variante (escaneo automatico
                // en scr_survivors). Hitbox: aire +30%; tierra v1 normal y
                // v2+ +20% (pads en el puppet). Sonic es inmune al dano
                // mientras dura el golpe (scr_player_hurt).
                if(!isGrounded)
                {
                        atkAir = true;
                        atkNum = irandom(array_length(global.sonicAtkAire) - 1) + 1;
                }
                else
                {
                        atkAir = false;
                        atkNum = irandom(array_length(global.sonicAtkTierra) - 1) + 1;
                }
                
                // Mismo sonido que el ataque normal de los EXE.
                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
        }
        
        // =================================================================
        //  ATAQUE 2: SPINDASH (abajo + Z repetido; soltar abajo lanza)
        //  Como los Sonic clasicos: agachado y PARADO (gspd == 0), cada
        //  pulsacion de Z suma carga (SONIC_SPINDASH_REV, con sonido
        //  snd_spin). Se puede girar la mirada con izquierda/derecha
        //  sin salir de la carga. Al SOLTAR ABAJO se dispara en bola a
        //  (SONIC_SPINDASH_BASE + carga) pixeles/frame. La carga baja
        //  sola 1 punto cada SONIC_SPINDASH_DECAY frames sin pulsar Z.
        // =================================================================
        
        // --- Entrada / revolucadas: abajo + Z (solo en el suelo, parado) ---
        if(global.playerControls && !isSpinCharging && isGrounded && !isAttacking
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && keyboard_check(global.KeyDown) && gspd == 0 && keyboard_check_pressed(global.KeyA))
        {
                isSpinCharging = true;
                spinCharge = min(spinCharge + SONIC_SPINDASH_REV, SONIC_SPINDASH_CHARGE_MAX);
                spinChargeDecay = 0;
                image_index = 0;
                
                audio_play_sound(snd_spin, 0, false);
                net_sound_emit(snd_spin);
        }
        
        if(isSpinCharging)
        {
                // Revolucadas adicionales: Z de nuevo (sigue agachado).
                if(global.playerControls && keyboard_check_pressed(global.KeyA))
                {
                        spinCharge = min(spinCharge + SONIC_SPINDASH_REV, SONIC_SPINDASH_CHARGE_MAX);
                        spinChargeDecay = 0;
                        
                        audio_play_sound(snd_spin, 0, false);
                        net_sound_emit(snd_spin);
                }
                
                // Quieto mientras carga, pero puede girar la mirada.
                gspd = 0;
                
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;
                
                // La carga decae sola si dejas de dar revolucadas.
                spinChargeDecay++;
                if(spinChargeDecay >= SONIC_SPINDASH_DECAY)
                {
                        spinChargeDecay = 0;
                        spinCharge = max(0, spinCharge - 1);
                }
                
                // Cancelaciones: dano, stun, muerte, tirolina, saltar
                // fuera del suelo, o que sueltes ABAJO (lanzamiento).
                if(isHurt || isDead || shockedTimer > 0 || isZipline || !isGrounded)
                {
                        isSpinCharging = false;
                        spinCharge = 0;
                }
                else if(!global.playerControls || !keyboard_check(global.KeyDown))
                {
                        // --- LANZAMIENTO del spindash ---
                        isSpinCharging = false;
                        isSpinning = true;    // sale en bola (estado SPIN)
                        isJumping = false;
                        gspd = (SONIC_SPINDASH_BASE + spinCharge) * image_xscale;
                        spinCharge = 0;
                        
                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);
                }
        }
        
        if(attackTimer > 0)
                attackTimer--;
}
