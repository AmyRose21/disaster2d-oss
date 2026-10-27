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
        // 3 segundos, se levanta y tiene 4 segundos de invulnerabilidad
        // total (powerboost con estela de fantasmas). Salva inclusive en
        // muerte subita. Solo la 2da caida (nerviosUsed) muere de verdad.
        if(global.character == CHARACTER_SONIC && !global.player.nerviosUsed)
        {
                with(global.player)
                {
                        nerviosState = 1;             // fase 1: tirado en el suelo
                        nerviosUsed = true;            // 1 sola vez por ronda
                        nerviosTimer = SONIC_NERVIOS_TIME;
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

function scr_player_hurt(damage, xpw=4, ypw=-6, sndid=snd_hurt, blood=spr_blood1, ignore=false)
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
        
        if(global.character != CHARACTER_EXE)
        {
                if(damage > 0)
                {
                        if(global.character == CHARACTER_SALLY && global.player.shieldTimer > 0)
                        {
                                if(global.player.revivalTimes < 2 && global.player.hp <= 20)
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
                                global.player.hurttime = 60;
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