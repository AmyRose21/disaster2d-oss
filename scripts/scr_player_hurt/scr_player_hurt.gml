function scr_player_instakill() 
{
        if(global.player.isDead) //Нельзя умереть 2 раза :rage:
                return;
                
        if(obj_netclient.gameEnds)
                return;
        
        // === BURBUJA DE SECUESTRO (solo Amy Canon - reglas canonicas) ===
        // Su 1ra caida JAMAS la mata: la encierra en la burbuja (alli
        // levita, no puede ser herida y un companero puede liberarla).
        // Mientras este dentro es inmune a TODO, incluidas zonas de
        // muerte y hoyos. Solo muere de verdad en su 2da caida: entonces
        // sigue el flujo normal de abajo pero el servidor (parche de
        // betterserver-oss) la marca como muerta directa: sin agonia,
        // sin timer de 30s y JAMAS se transforma en exe.
        if(global.character == CHARACTER_AMY_CANON)
        {
                if(global.player.bubbleState == AMY_BUBBLE_ACTIVE)
                        return; // dentro de la burbuja: inmune, no muere
                
                if(global.player.bubbleState == AMY_BUBBLE_NONE)
                {
                        scr_amy_canon_capture(); // 1ra caida -> secuestro en burbuja
                        return;
                }
                // bubbleState == OVER: 2da caida -> cae al flujo normal (muerte directa)
        }
        
        // === NERVIOS DE ACERO (Sonic): su 1ra caida NO lo mata ===
        // Igual que la burbuja de Amy: en vez de la agonia, cae al suelo
        // 4 segundos, se levanta y tiene 4 segundos de invulnerabilidad
        // total (powerboost con estela de fantasmas). Salva inclusive en
        // muerte subita. Solo la 2da caida (nerviosUsed) muere de verdad.
        if(global.character == CHARACTER_SONIC && !global.player.nerviosUsed)
        {
                with(global.player)
                {
                        nerviosState = 1;             // fase 1: tirado en el suelo
                        nerviosUsed = true;            // 1 sola vez por ronda
                        nerviosTimer = SONIC_NERVIOS_TIME;
                        image_index = 0; // el Idle en loop empieza desde el frame 0
                        ghostTimer = 0;
                        
                        hp = max(hp, 0);               // normaliza la vida que la dejo la caida
                        hurttime = 0;                  // sin invulnerabilidad ni knockback heredado
                        shockedTimer = 0;              // por si la caida venia de un stun
                        isDead = false;                // la pasiva NO cuenta como muerte
                        rings = 0;
                        gspd = 0;
                        xspd = 0;
                        yspd = 0;
                        isAttacking = false;
                        isSpinCharging = false;
                        spinCharge = 0;
                        isJumping = false;
                        isSpinning = false;
                        isBoosting = false;
                        isZipline = false;
                        isHiding = false;
                        isHurt = false;
                        emotion = false;
                }
                
                return; // el server nunca sabe que "murio": sigue vivo para todos
        }
        
        // === FASE 2 (Sally Canon): su 1ra caida NO la mata ===
        // Igual que la burbuja de Amy o los Nervios de Sonic: en vez de
        // la agonia entra en su modo de 4 partes (retroceso del golpe ->
        // suelo -> salto con squash & stretch -> recuperacion con la vida
        // subiendo sola). Inmune a TODO mientras dure. Salva inclusive en
        // muerte subita. Solo la 2da caida (fase2Used) muere de verdad,
        // y el server (parche) la marca muerta directa: JAMAS se hace exe.
        if(global.character == CHARACTER_SALLY_CANON && !global.player.fase2Used)
        {
                scr_sally_canon_fase2_start(global.player.fase2HitX);
                return; // el server nunca sabe que "murio": sigue viva para todos
        }
        
        // === PACIENCIA / MORIBUNDA (Vanilla v2): NUNCA cae muerta ===
        // 1ra caida -> PACIENCIA: 5 s inmune; a los 2 s sale Chocola
        // desde el lado contrario de la pantalla y stunea al exe 5 s
        // (el reloj se congela hasta que golpea). 2da caida en adelante
        // -> MORIBUNDA: 6 s tirada y se levanta con 30 de vida. El
        // server JAMAS sabe que cayo (y de todos modos la trata como
        // canonica: jamas se demoniza, ver Game.c del betterserver).
        if(global.character == CHARACTER_VANILLA)
        {
                // dentro de paciencia/moribunda no puede "volver a caer"
                if(global.player.pacienciaState > 0 || global.player.moribundaState > 0)
                        return;
                
                if(!global.player.pacienciaUsed)
                {
                        with(global.player)
                        {
                                pacienciaState = 1;
                                pacienciaUsed = true;
                                pacienciaTimer = VANILLA_PACIENCIA_TIME;
                                pacienciaWaitChocola = false;
                                pacienciaChocolaOut = false;
                                image_index = 0;
                                
                                hp = max(hp, 0);
                                hurttime = 0;
                                shockedTimer = 0;
                                isDead = false;
                                isHurt = false;
                                gspd = 0;
                                xspd = 0;
                                yspd = 0;
                                isAttacking = false;
                                isJumping = false;
                                isSpinning = false;
                                isBoosting = false;
                                isZipline = false;
                                isHiding = false;
                                emotion = false;
                                isFlying = false;
                                dashing = 0;
                        }
                        
                        return; // el server nunca sabe que "cayo": paciencia
                }
                
                // 2da caida (o posterior): MORIBUNDA (tampoco muere)
                with(global.player)
                {
                        moribundaState = 1;
                        moribundaTimer = VANILLA_MORIBUNDA_TIME;
                        image_index = 0;
                        
                        hp = max(hp, 0);
                        hurttime = 0;
                        shockedTimer = 0;
                        isDead = false;
                        isHurt = false;
                        gspd = 0;
                        xspd = 0;
                        yspd = 0;
                        isAttacking = false;
                        isJumping = false;
                        isSpinning = false;
                        isBoosting = false;
                        isZipline = false;
                        isHiding = false;
                        emotion = false;
                        isFlying = false;
                        dashing = 0;
                }
                
                return; // se levanta en 6 s
        }
        
        var packet = cpacket_tcp(PacketType.CLIENT_PLAYER_DEATH_STATE);
        buffer_write(packet, buffer_bool, true);
        buffer_write(packet, buffer_u8, global.player.revivalTimes);
        send_server_tcp(packet);
        
        global.cameraMode = 3;
        
        global.player.hp = 0;
        global.player.deadTimer = 31;
        global.player.alarm[0] = 60;
        global.player.rings = 0;
        global.player.xspd = image_xscale * 2;
        global.player.isGrounded = false;
        global.player.isSpinning = false;
        global.player.isLookingDown = false;
        global.player.isLookingUp = false;
        global.player.isDead = true;
        global.player.shards = 0;
        global.player.chunkX = -1000;
        global.player.chunkY = -1000;
        global.player.chunkTimer = 0;
        obj_achivements.rShardsCollected = 0;
        
        if(instance_exists(obj_deserttown_i))
                with(obj_deserttown_i)
                        show = false;
        
        audio_play_sound(snd_dead, 0, false);
        net_quick_effect(global.player.x, global.player.y, spr_blood2, false, 1, 0, 0, 1);
        net_sound_emit(snd_dead);
}

// PARRY DE SONIC: param opcional exeSource — true solo en las llamadas
// cuyo dano viene de un ataque/habilidad del lado EXE (golpe de puppets
// EXE/esbirros, escudo electrico de Eggman, laser de Tails esbirro,
// bolas de Exetior, cadenas, etc). Los peligros ambientales (pinchos,
// lava, hoyos, agua) NO lo ponen: el parry no salva del escenario.
function scr_player_hurt(damage, xpw=4, ypw=-6, sndid=snd_hurt, blood=spr_blood1, ignore=false, exeSource=false)
{       
        if(!instance_exists(global.player))
                return;
                
        if(obj_netclient.gameEnds)
                return;
                
        if(global.player.isDead)
                return;
        
        // BURBUJA DE SECUESTRO (Amy Canon): mientras esta dentro de la
        // burbuja no puede ser herida por nada (golpes del EXE, esbirros,
        // pinchos, huecos...). Solo sale de ahi con el toque de un
        // companero o cuando la burbuja se rompe sola.
        if(global.character == CHARACTER_AMY_CANON)
        {
                if(global.player.bubbleState == AMY_BUBBLE_ACTIVE)
                        return;
                
                // HABILIDADES DE AMY CANON: durante el impulso de tarot
                // (tarot shock) y la acometida de martillo (hammer rush)
                // Amy no recibe dano mientras dure la habilidad.
                if(global.player.isDashing || global.player.isTarotDashing)
                        return;
        }
        
        // NERVIOS DE ACERO (Sonic): inmune a TODO en sus 3 fases (tirado
        // en el suelo, levantandose y powerboost de 4 seg). Ademas, el
        // golpe (ataque en aire o tierra) lo blinda mientras dura la
        // animacion: no puede recibir dano durante el uso de la habilidad.
        if(global.character == CHARACTER_SONIC && (global.player.nerviosState > 0 || global.player.isAttacking))
                return;
        
        // FASE 2 (Sally Canon): inmune a TODO durante las 4 partes
        // (desde el retroceso del golpe hasta levantarse ya con vida llena).
        if(global.character == CHARACTER_SALLY_CANON && global.player.fase2State > 0)
                return;
        
        // SLIDE (Sally Canon): i-frames durante TODO el slide (y solo
        // durante el slide): mientras se desliza no puede ser herida.
        if(global.character == CHARACTER_SALLY_CANON && global.player.isSliding)
                return;

        // === VANILLA V2 ===
        // PACIENCIA / MORIBUNDA: inmune a TODO mientras duran (enojada
        // o tirada en el suelo: ni el exe ni el entorno le hacen nada).
        if(global.character == CHARACTER_VANILLA && (global.player.pacienciaState > 0 || global.player.moribundaState > 0))
                return;
        
        if(global.player.hurttime > 0)
        {
                if(ignore)
                {
                        global.player.isGrounded = false;
                        global.player.isSpinning = false;
                        global.player.isLookingDown = false;
                        global.player.isLookingUp = false;
                        
                        global.player.xspd = xpw;
                        global.player.yspd = ypw;
                }
                
                return;
        }
        
        // =============================================================
        //  PARRY DE SONIC (negacion, lado de la VICTIMA): el golpe viene
        //  de un ataque del lado EXE (exeSource) y habria caido de
        //  verdad (ya paso los i-frames). Si un Sonic con la ventana
        //  activa cubre al jugador local — el mismo Sonic o un aliado
        //  dentro de su aura de 56px — el dano se NIEGA por completo.
        //  El stun del atacante lo aplica el cliente del propio atacante
        //  (scr_parry_try_stun_attacker) con los mismos datos sincronizados.
        // =============================================================
        if(exeSource && damage > 0 && scr_parry_negate_hit())
                return;
        
        // CHOCOLA (Vanilla v2): 50% de BLOQUEAR el dano del lado EXE.
        // Si sale, Vanilla no pierde vida y queda semi-transparente con
        // i-frames de 2.5 s (hurttime, como el escudo roto de Sally).
        // Enfriamiento compartido de 4.5 s con su ataque cercano.
        if(global.character == CHARACTER_VANILLA && exeSource && damage > 0 && global.player.chocolaCd <= 0 && instance_exists(obj_chocola))
        {
                var _vchoc = scr_chocola_get();
                
                if(_vchoc != noone && _vchoc.mode == CHOCOLA_FOLLOW && random(100) < VANILLA_CHOCOLA_BLOCK_CHANCE)
                {
                        global.player.chocolaCd = VANILLA_CHOCOLA_CD;
                        global.player.hurttime = VANILLA_CHOCOLA_BLOCK_INVULN;
                        _vchoc.supportTimer = 26; // celebra el bloqueo girando
                        
                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                        net_quick_effect(global.player.x, global.player.y, spr_shieldbreak, false, 1, 0, 0, 1);
                        net_sound_emit(snd_sally_shieldbreak);
                        return;
                }
        }
        
        // CHOCOLA CUSTODIA (Cream v2): si Chocola llego hasta Cream y aun
        // no cumplio su mision, BLOQUEA 1 dano (del exe o del entorno).
        // Consumida la custodia, Chocola vuelve con Vanilla.
        if(global.character == CHARACTER_CREAM && damage > 0 && !global.player.isDead && global.player.revivalTimes < 2 && instance_exists(obj_chocola))
        {
                var _gchoc = scr_chocola_get();
                
                if(_gchoc != noone && _gchoc.mode == CHOCOLA_GUARD && _gchoc.targetInst == global.player)
                {
                        scr_chocola_guard_consume();
                        global.player.hurttime = VANILLA_CHOCOLA_BLOCK_INVULN;
                        
                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                        net_quick_effect(global.player.x, global.player.y, spr_shieldbreak, false, 1, 0, 0, 1);
                        net_sound_emit(snd_sally_shieldbreak);
                        return;
                }
        }
        
        if(global.character != CHARACTER_EXE)
        {
                if(damage > 0)
                {
                        if((global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON) && global.player.shieldTimer > 0)
                        {
                                if(global.character == CHARACTER_SALLY && global.player.revivalTimes < 2 && global.player.hp <= 20)
                                {
                                        obj_achivements.rSallyShield++;
                                        
                                        if(obj_achivements.rSallyShield >= 2 && room != room_fartzone && !obj_achivements.achivements[32])
                                        {
                                                obj_achivements.achivements[32] = true;
                                                obj_achivements.show();
                                                obj_achivements.save();
                                                
                                                obj_achivements.mercoins += 75;
                                                obj_achivements.save();
                                        }
                                }
                                global.player.hurttime = global.character == CHARACTER_SALLY_CANON ? SALLY_CANON_SHIELD_BREAK_INVULN : 60; // Canon: 1 seg base + 2 extra
                                global.player.shieldTimer = 0;
                                
                                audio_play_sound(snd_sally_shieldbreak, 0, false);
                                net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                                net_sound_emit(snd_sally_shieldbreak);
                                return;
                        }
                }
                        
                if(global.player.revivalTimes < 2) // ignore if we're demonized
                {
                        obj_achivements.wasHurt = true;
                        
                        // SALLY CANON: guarda la direccion del golpe para el
                        // retroceso de su fase 2 (parte 1)
                        if(global.character == CHARACTER_SALLY_CANON)
                                global.player.fase2HitX = xpw;
                        
                        global.player.hp -= damage;
                        
                        if(global.player.hp <= 0)
                        {
                                var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(pak, buffer_u8, 3);
                                buffer_write(pak, buffer_u8, global.player.hp + damage);
                                send_server_tcp(pak);
                                
                                scr_player_instakill();
                                return;
                        }
                        
                        var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                        buffer_write(pak, buffer_u8, 3);
                        buffer_write(pak, buffer_u8, damage);
                        send_server_tcp(pak);
                }
        }
        else
        {
                if(global.player.invisTimer > 0 || global.player.won || global.player.lost)
                        return;
        }
        
        if(global.player.rings > 0 && damage > 0)
        {
                // FORTALEZA DE UNA MADRE (Vanilla v2): Vanilla solo pierde
                // el 15% de sus anillos al ser golpeada (minimo 3); Cream
                // pierde el 30%, pero SOLO si Vanilla esta en la partida
                // (la presencia de su madre la protege). El resto de
                // personajes pierde todos, como siempre.
                var _fortLoss = -1;
                
                if(global.character == CHARACTER_VANILLA)
                        _fortLoss = max(VANILLA_FORTALEZA_MIN, floor(global.player.rings * VANILLA_FORTALEZA_VANILLA_PCT / 100));
                else if(global.character == CHARACTER_CREAM && scr_vanilla_in_match())
                        _fortLoss = max(VANILLA_FORTALEZA_MIN, floor(global.player.rings * VANILLA_FORTALEZA_CREAM_PCT / 100));
                
                if(_fortLoss > 0)
                        global.player.rings = max(0, global.player.rings - min(_fortLoss, global.player.rings));
                else
                        global.player.rings = 0;
                
                audio_play_sound(snd_ringlose, 0, false);
                
                net_sound_emit(snd_ringlose);
                net_quick_effect(global.player.x, global.player.y, spr_ringlose);
                
                scr_camera_shake(25, 1, 0.2);
        }
        else if(damage > 0 || sndid == snd_buble)
        {
                audio_play_sound(sndid, 0, false);
                net_sound_emit(sndid);
                scr_camera_shake(25, 1, 0.2);
        }
        
        if(damage > 0)
        {
                global.player.isHurt = true;
                global.player.isJumping = false;
                net_quick_effect(global.player.x, global.player.y, blood, false, sign(xpw), 0, 0, 1);
        }
        
        global.player.isGrounded = false;
        global.player.isSpinning = false;
        global.player.isLookingDown = false;
        global.player.isLookingUp = false;
        
        global.player.xspd = xpw;
        global.player.yspd = ypw;
        
        if(damage != 0)
                global.player.hurttime = (global.timeMinutes <= 0 && global.timeSeconds <  60) ? 1 * 60 : 3 * 60;
        else
                global.player.hurttime = 0;
        
}