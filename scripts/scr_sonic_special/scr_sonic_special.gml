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
        // (parryState == 0: mientras dura el parry no se pueden empezar
        // otras acciones — el parry reemplaza el golpe)
        if(global.playerControls && !isAttacking && !isSpinCharging
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline
        && parryState == 0
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
        //
        //  v3 - REVOLUCADAS DE VERDAD (fix del "machacar Z no aumenta
        //  la velocidad"): DOS bugs de fondo arreglados:
        //  1) La 1a pulsacion contaba DOBLE: el bloque de entrada y el
        //     de revolucadas extra sumaban carga en el MISMO frame (la
        //     bola se llenaba con 2 pulsaciones en vez de 5). Ahora hay
        //     UN solo camino para la 1a y las siguientes.
        //  2) La colision recortaba SIEMPRE xspd a maxHSpeed (11): todo
        //     lanzamiento por encima de 11 salia a 11 y machacar Z no
        //     servia de nada. Ahora la bola de Sonic puede rodar por
        //     encima de la velocidad de carrera (clamp de
        //     scr_collision_basic con tope SONIC_ROLL_SPEED_CAP).
        //  Con CHARGE_MAX a 10: 5 revolucadas reales, salida de 10 a 18
        //  px/frame (los EXE corren a 12: la bola llena los deja atras).
        // =================================================================
        
        // --- Revolucadas: abajo + Z (solo en el suelo, parado) ---
        // UN solo camino para la 1a pulsacion y las siguientes (v3).
        // (parryState == 0: idem golpe, no durante el parry; escondido o
        // anillo rojo puesto: tampoco, igual que el golpe)
        if(global.playerControls && isGrounded && !isAttacking && !isHurt
        && !isDead && shockedTimer <= 0 && !isZipline && parryState == 0
        && !isHiding && redRingTimer <= 0
        && keyboard_check(global.KeyDown) && gspd == 0 && keyboard_check_pressed(global.KeyA))
        {
                isSpinCharging = true;
                spinCharge = min(spinCharge + SONIC_SPINDASH_REV, SONIC_SPINDASH_CHARGE_MAX);
                spinChargeDecay = 0;
                spinDustTimer = 0;
                image_index = 0;
                
                // JUGO: cada revolucada suena MAS AGUDA (tono 1.0 -> 1.8
                // con la bola llena, en proporcion a la carga) y patea
                // polvo detras. El polvo viaja por red (net_quick_effect):
                // los demas jugadores ven cada revolucada a la vez que les
                // llega el sonido. El tono solo lo oye el local: el
                // paquete de sonido del protocolo no lleva pitch (y no
                // vale la pena tocarlo por 5 revolucadas).
                if(spinRevSnd != -1)
                        audio_stop_sound(spinRevSnd);
                spinRevSnd = audio_play_sound(snd_spin, 0, false);
                audio_sound_pitch(spinRevSnd, 1.0 + (spinCharge / SONIC_SPINDASH_CHARGE_MAX) * SONIC_SPINDASH_PITCH_STEP);
                net_sound_emit(snd_spin);
                
                net_quick_effect(x - image_xscale * 12, y + 16, spr_dust, false, -image_xscale, -image_xscale * 2, -1);
        }
        
        if(isSpinCharging)
        {
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
                
                // JUGO: polvo ambiente detras mientras carga, como el motor
                // en marcha entre rev y rev (solo local: el de cada
                // revolucada y el de la salida ya viajan por red).
                spinDustTimer++;
                
                if(spinDustTimer >= SONIC_SPINDASH_DUST_EVERY)
                {
                        spinDustTimer = 0;
                        scr_effect_quick(x - image_xscale * (10 + irandom(4)), y + 14 + irandom(3), spr_dust, 0.4, false, -image_xscale, -0.5);
                }
                
                // Cancelaciones: dano, stun, muerte, tirolina, saltar
                // fuera del suelo, o que sueltes ABAJO (lanzamiento).
                if(isHurt || isDead || shockedTimer > 0 || isZipline || !isGrounded)
                {
                        isSpinCharging = false;
                        spinCharge = 0;
                        
                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);   // corte del motor al estrellarse
                }
                else if(!global.playerControls || !keyboard_check(global.KeyDown))
                {
                        // --- LANZAMIENTO del spindash ---
                        var _chg = spinCharge;   // carga ANTES de limpiarla: define la polvareda
                        isSpinCharging = false;
                        isSpinning = true;    // sale en bola (estado SPIN)
                        isJumping = false;
                        gspd = (SONIC_SPINDASH_BASE + _chg) * image_xscale;
                        spinCharge = 0;
                        
                        if(spinRevSnd != -1)
                                audio_stop_sound(spinRevSnd);   // el snd_dash toma el relevo
                        
                        audio_play_sound(snd_dash, 0, false);
                        net_sound_emit(snd_dash);
                        
                        // JUGO: polvareda de salida detras (3 nubes sin carga
                        // -> 8 con la bola llena). Viaja por red: todos ven el
                        // disparazon. Cada nube nace donde estaba Sonic y
                        // deriva atras y un poco arriba.
                        var _burst = SONIC_SPINDASH_BURST_MIN + floor(_chg / SONIC_SPINDASH_CHARGE_MAX * (SONIC_SPINDASH_BURST_MAX - SONIC_SPINDASH_BURST_MIN));
                        
                        for(var i = 0; i < _burst; i++)
                        {
                                var _dx = x - image_xscale * (6 + irandom(12));
                                var _dy = y + 12 + irandom(5);
                                
                                net_quick_effect(_dx, _dy, spr_dust, false, -image_xscale, -image_xscale * (1 + irandom(2)), -irandom(1));
                        }
                        
                        // JUGO: mini-temblor de camara proporcional a la carga
                        // (local: cada cliente tiembla con su propio Sonic).
                        if(_chg > 0)
                                scr_camera_shake(12, 1 + _chg * 0.15, 0.2);
                }
        }
        
        // =================================================================
        //  ATAQUE 2b: DROP DASH (mantener Z en el aire; aterrizar)
        //  Estilo Sonic Mania: tras SALTAR, mantén Z pulsado en el aire
        //  SONIC_DROPDASH_HOLD frames (30 = medio segundo) y la bola
        //  queda ARMADA (destello + tono agudo, el destello viaja por
        //  red). Al ATERRIZAR sale disparado en rodadura (estado SPIN)
        //  a SONIC_DROPDASH_SPEED (14: mas que correr, menos que un
        //  spindash de 4-5 revolucadas). Soltar Z en el aire lo desarma.
        //  Sin cooldown: el coste es medio segundo de agarre en el aire.
        //  La rodadura hereda la pasiva SPIN (el salto/rodadura del EXE
        //  no le hace dano: se repelen, como siempre).
        // =================================================================
        
        // Latch "este vuelo empezo con un salto". isJumping se apaga solo
        // con que la ANIMACION de la bola termine (Draw_76), mucho antes
        // de aterrizar, asi que no sirve de condicion directa: en cuanto
        // el salto pone la bola en marcha, dropDashFromJump queda fijado
        // hasta volver al suelo (o cancelar por dano/stun/etc).
        if(!isGrounded && isJumping)
                dropDashFromJump = true;
        
        var _ddFired = false;
        
        // --- Aterrizaje ARMADO: disparo del drop dash ---
        // Requiere seguir MANTENIENDO Z al tocar suelo (como en Mania:
        // soltarla en el aire desarma y aqui ya no dispara).
        if(global.playerControls && dropDashReady && isGrounded
        && !isAttacking && !isSpinCharging && !isHurt && !isDead
        && shockedTimer <= 0 && !isZipline && !isHiding && redRingTimer <= 0
        && parryState == 0 && keyboard_check(global.KeyA))
        {
                _ddFired = true;
                dropDashReady = false;
                dropDashTimer = 0;
                dropDashFromJump = false;
                
                isSpinning = true;      // sale rodando (estado SPIN)
                isJumping = false;
                isLookingDown = false;  // aterrizo agachado: sin glitch de 1 frame
                isLookingUp = false;
                gspd = SONIC_DROPDASH_SPEED * image_xscale;
                
                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
                
                // JUGO: polvareda de aterrizaje (por red): el golpe al
                // suelo de Mania. 4 nubes detras del punto de impacto.
                for(var i = 0; i < 4; i++)
                {
                        var _ddx = x - image_xscale * (6 + irandom(10));
                        var _ddy = y + 12 + irandom(5);
                        
                        net_quick_effect(_ddx, _ddy, spr_dust, false, -image_xscale, -image_xscale * (1 + irandom(2)), -irandom(1));
                }
                
                // JUGO: mini-temblor al pegar el suelo (local).
                scr_camera_shake(12, 2, 0.2);
        }
        
        // --- Armado: en el aire, tras un salto, manteniendo Z ---
        if(!_ddFired && global.playerControls && dropDashFromJump && !isGrounded
        && !isAttacking && !isSpinCharging && !isHurt && !isDead
        && shockedTimer <= 0 && !isZipline && !isHiding && redRingTimer <= 0
        && parryState == 0 && keyboard_check(global.KeyA))
        {
                dropDashTimer++;
                
                if(!dropDashReady && dropDashTimer >= SONIC_DROPDASH_HOLD)
                {
                        dropDashReady = true;
                        
                        // Aviso de ARMADO: tono agudo (solo local: el
                        // paquete de sonido del protocolo no lleva pitch)
                        // + destello POR RED: los demas ven el destello
                        // en el mismo instante en que el Sonic local ya
                        // tiene el drop dash listo.
                        var _ddSnd = audio_play_sound(snd_spin, 0, false);
                        audio_sound_pitch(_ddSnd, 1.8);
                        net_sound_emit(snd_spin);
                        
                        net_quick_effect(x, y, spr_shockparticle, false, 1, 0, 0, 1);
                }
                
                // JUGO: chispitas alrededor de la bola mientras espera
                // armado el aterrizaje (solo local: el destello de
                // armado ya viajo por red).
                if(dropDashReady && (dropDashTimer mod 6) == 0)
                        scr_effect_quick(x + irandom(6) - 3, y + irandom(6) - 3, spr_dust, 0.4, false, 0, -0.5);
        }
        
        // --- Reset: solto Z en el aire, aterrizo sin disparar o cancelacion ---
        // (si acaba de disparar no entra: ya quedo todo en false/0)
        if(!_ddFired && (isGrounded || isHurt || isDead || shockedTimer > 0
        || isZipline || isAttacking || isSpinCharging || isHiding
        || redRingTimer > 0 || !keyboard_check(global.KeyA)))
        {
                dropDashTimer = 0;
                dropDashReady = false;
        }
        
        // Fin del vuelo o cancelacion gorda: suelta el latch.
        if(isGrounded || isHurt || isDead || shockedTimer > 0 || isZipline)
                dropDashFromJump = false;
        
        if(attackTimer > 0)
                attackTimer--;
}
