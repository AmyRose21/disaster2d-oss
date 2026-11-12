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

        // === MORIBUNDA (Rouge v4.5): su UNICA salvacion ===
        // 1ra caida -> tirada 6 s (inmune a todo) y se levanta sola con
        // 40 de vida (patron Vanilla). El server NUNCA sabe que cayo: la
        // ronda sigue y nadie puede "revivirla" (no hay barra). Su retrato
        // si marca el hit (cayo 1 vez: revivalTimes=1 local). La 2da caida
        // cae al flujo normal de abajo: MUERTE REAL de una (con la X en
        // el retrato) — el server ya la trata como canonica (guard de
        // Game.c): sin agonia de 30 s, sin demonizarse, jamas.
        if(global.character == CHARACTER_ROUGE)
        {
                // dentro de la moribunda no puede "volver a caer"
                if(global.player.moribundaState > 0)
                        return;

                if(global.player.revivalTimes < 1)
                {
                        with(global.player)
                        {
                                moribundaState = 1;
                                moribundaTimer = ROUGE_MORIBUNDA_TIME;
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
                                isGliding = false;

                                if(isStuck)
                                {
                                        canMove = true;
                                        isStuck = false;
                                }

                                // marca el "hit" del retrato (cayo 1 vez);
                                // viaja en el paquete UDP de siempre para
                                // el tab de los demas. NUNCA pasa de 1:
                                // no hay barra de revive que la suba.
                                revivalTimes = 1;
                        }

                        audio_play_sound(snd_hurt, 0, false);
                        return; // el server nunca sabe que "cayo": moribunda
                }
                // revivalTimes >= 1: 2da caida -> MUERTE REAL (flujo de abajo)
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

        // v2.8 (reporte del usuario) — I-FRAMES EN LOS 2 ATAQUES DE METAL:
        // el OVERDRIVE y el SPARK FIELD son de contacto defensivo (su unico
        // efecto es aturdir 3 s al killer que lo toque), pero un golpe a
        // mitad del ataque los cortaba (isHurt corta metalDashing e
        // isElectro) y el ataque moria sin haber servido de nada — de ahi
        // el «no tiene sentido que los haga». Mientras dure cualquiera de
        // los dos, Metal no recibe dano: mismo modelo que el golpe de Sonic
        // o el dash/tarot de Amy Canon. El stun que el CAUSA corre en el
        // cliente del EXE (obj_player_puppet, bit PLAYER_ATTACKING que
        // ahora si viaja), asi que no depende de este guard. Los peligros
        // que matan sin dano (caer al vacio, scr_player_instakill) siguen
        // funcionando igual.
        if(global.character == CHARACTER_METAL && (global.player.metalDashing > 0 || global.player.isElectro > 0))
                return;
        
        // FASE 2 (Sally Canon): inmune a TODO durante las 4 partes
        // (desde el retroceso del golpe hasta levantarse ya con vida llena).
        if(global.character == CHARACTER_SALLY_CANON && global.player.fase2State > 0)
                return;
        
        // SLIDE (Sally): i-frames durante TODO el slide (y solo
        // durante el slide): mientras se desliza no puede ser herida.
        // v3.0 (balance): ahora tambien la Sally VANILLA — antes solo
        // lo tenia la Sally Canon (pedido del usuario).
        if((global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON) && global.player.isSliding)
                return;

        // v2.15 («La Torre») — PASIVA FUERZA (Amy vanilla): mientras
        // lanza el martillo (isAttacking) Amy tiene i-frames contra el
        // daño, PERO solo si alguna de las otras Amys (Canon / Amelia /
        // Fleetway) esta presente en el campo («Reflejo de una misma
        // alma»: la familia la sostiene). Sin ellas: sin iframes.
        // (Los i-frames contra el STUN de contacto del exe ya existian
        // en obj_player_puppet; estos amplian la proteccion al daño.)
        if(global.character == CHARACTER_AMY && global.player.isAttacking && scr_amy_soul_otras())
                return;

        // v4.10 («La Torre») — PASIVA LA TORRE (Fleetway Amy): el bloqueo
        // COMPLETO vivia aqui, ANTES del guard de hurttime: re-destellaba
        // (sonido + escudo) incluso con i-frames ya activos de un golpe
        // anterior, igual que le pasaba al bloqueo LMS de Sonic antes del
        // fix v5.4. v3 (D.I.B.): la pasiva se NERFEO y se mudo ABAJO, tras
        // el guard — solo se evalua cuando el daño iba a entrar de verdad,
        // y su porcentaje decae 10% por bloqueo consumido (ver el bloque
        // nuevo mas abajo).

        // (v5.4: el BLOQUEO del show LMS de Sonic vivia AQUI, antes del
        // guard de hurttime: re-tiraba el 55% incluso mientras estaba
        // inmune por un bloqueo anterior, y pegado a una fuente de daño
        // continuo quedaba inmune practicamente para siempre. Ahora
        // vive ABAJO, tras el guard: solo se tira en la instancia de
        // daño REAL — cuando el golpe de verdad iba a entrar.)

        // === VANILLA V2 ===
        // PACIENCIA / MORIBUNDA: inmune a TODO mientras duran (enojada
        // o tirada en el suelo: ni el exe ni el entorno le hacen nada).
        if(global.character == CHARACTER_VANILLA && (global.player.pacienciaState > 0 || global.player.moribundaState > 0))
                return;

        // v4.5 — MORIBUNDA DE ROUGE: igual que Vanilla, inmune a TODO
        // mientras esta tirada (ni el exe ni el entorno le hacen nada)
        if(global.character == CHARACTER_ROUGE && global.player.moribundaState > 0)
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

        // v3 (D.I.B.) — LA TORRE (Fleetway Amy), version nerf para su
        // salida a PUBLICA: el bloqueo SOLO se evalua cuando el golpe
        // iba a entrar DE VERDAD (ya paso el guard de hurttime: nada de
        // destellos de escudo con i-frames ya activos — mismo fix que el
        // bloqueo LMS de Sonic en v5.4) y ya no es infalible: fwTowerPct
        // arranca en 100% y CADA bloqueo consumido le resta 10% (100 ->
        // 90 -> 80 -> ... -> 0; se resetea al empezar la ronda). Mientras
        // la tirada aguante, el golpe se detiene entero (ni vida ni
        // anillos ni retroceso: solo el destello + su sonido); cuando
        // falla, el daño entra completo. El stun y los peligros ambiente
        // que matan sin daño (caer al vacio) SIGUEN funcionando: la Torre
        // bloquea daño, no la gravedad. La FW demonizada (revival >= 2)
        // pelea para el exe y pierde la pasiva, como siempre.
        if(global.character == CHARACTER_FLEETWAY_AMY
        && global.player.revivalTimes < 2
        && damage > 0
        && irandom(99) < global.player.fwTowerPct)
        {
                global.player.fwTowerPct = max(0, global.player.fwTowerPct - 10);

                audio_play_sound(snd_sally_shieldbreak, 0, false);
                net_sound_emit(snd_sally_shieldbreak);
                net_quick_effect(global.player.x, global.player.y - 20, spr_shieldbreak, false, 1, 0, 0, 1);
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
        
        // v5.0 LMS / v5.4 FIX — «EL SHOW FUERTE» (Sonic, ultimo
        // superviviente): 55% de BLOQUEAR TODO el daño del golpe. El
        // bloqueo se tira SOLO en la instancia de daño REAL (aqui ya
        // paso el guard de hurttime de arriba): mientras este inmune
        // no se tira nada, asi una fuente de daño continuo no lo deja
        // inmune para siempre — cada bloqueo se gana con una tirada
        // limpia tras gastarse los i-frames del anterior. Bloqueado =
        // ni vida ni anillos ni retroceso: escudo roto + 1.5 s de
        // invulnerabilidad (LMS_BLOCK_INVULN), y tras ese 1.5 s el
        // siguiente golpe es otra tirada limpia. Corre en el cliente
        // de la victima (quien aplica el daño).
        if(global.character == CHARACTER_SONIC && global.lmsActive
        && damage > 0 && scr_lms_sonic_try_block())
                return;
        
        // CHOCOLA (Vanilla v2): 65% de BLOQUEAR el dano del lado EXE.
        // Si sale, Vanilla no pierde vida y queda semi-transparente con
        // i-frames de 2.5 s (hurttime, como el escudo roto de Sally).
        // Enfriamiento compartido de 2.5 s con su ataque cercano.
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
        
        // ESCUDO GRUPAL (Sally Canon duelista, v5.4): mientras el escudo
        // de una Sally Canon en fase duelista esta activo, los companeros
        // cercanos (radio SALLY_CANON_GROUP_SHIELD_RADIUS) reciben EL
        // MISMO efecto que el escudo tiene sobre ella: el golpe se
        // absorbe entero (ni vida ni anillos ni retroceso), efecto de
        // escudo roto + los MISMOS i-frames (SALLY_CANON_SHIELD_BREAK_INVULN).
        // Cada companero absorbe 1 golpe por activacion (hasta que el bit
        // del escudo se apaga: roto por un golpe sobre ella o agotado su
        // tiempo). Todo local al cliente de la victima (autoridad de su
        // propia vida), dirigido por el bit PLAYER_SALLYSHIELD del puppet:
        // cero paquetes nuevos.
        if(global.character != CHARACTER_EXE && global.character != CHARACTER_SALLY_CANON
        && damage > 0 && global.player.revivalTimes < 2)
        {
                var _gsActive = false;
                var _gsNear = noone;
                
                with(obj_player_puppet)
                {
                        if(character != CHARACTER_SALLY_CANON)
                                continue;
                        
                        if(sallyShield)
                        {
                                _gsActive = true;
                                
                                if(distance_to_object(global.player) <= SALLY_CANON_GROUP_SHIELD_RADIUS)
                                        _gsNear = id;
                        }
                }
                
                if(!_gsActive)
                {
                        // su escudo se apago (golpe sobre ella o timeout):
                        // re-arma la absorcion de este companero
                        if(variable_instance_exists(global.player.id, "gsAbsorbDone"))
                                global.player.gsAbsorbDone = false;
                }
                else if(_gsNear != noone
                && !(variable_instance_exists(global.player.id, "gsAbsorbDone") && global.player.gsAbsorbDone))
                {
                        global.player.gsAbsorbDone = true;
                        global.player.hurttime = SALLY_CANON_SHIELD_BREAK_INVULN;
                        
                        audio_play_sound(snd_sally_shieldbreak, 0, false);
                        net_quick_effect(global.player.x, global.player.y, spr_shieldbreak, false, 1, 0, 0, 1);
                        net_sound_emit(snd_sally_shieldbreak);
                        return;
                }
        }
        
        // v6.3 «BLINDAJE DE ANILLOS» (pedido del usuario): con 10 o mas
        // anillos en el contador un golpe NO toca la vida — se absorbe:
        // abajo se restan EXACTAMENTE 10 anillos (o menos con la pasiva %
        // de Vanilla/Cream) y el golpe sigue dando retroceso, i-frames y
        // sonido de anillos perdidos. Con MENOS de 10 cae al flujo
        // original: pierde la vida y todos los anillos que le queden.
        // Se declara aqui para que viva en todo el alcance de la funcion.
        var _ringAbsorb = (damage > 0 && global.player.rings >= 10);
        
        if(global.character != CHARACTER_EXE)
        {
                if(damage > 0)
                {
                        // PASIVA INSTINTO DE LA PRINCESA DUELISTA (Sally Canon
                        // fase duelista, v5.4): 20% de evadir TODO el daño del
                        // ataque (ni vida ni anillos ni retroceso; el escudo ni
                        // se entera: el ataque pasa de largo). Al evadir gana
                        // 2.5 s de i-frames que se ACUMULAN a los que ya tenga
                        // (no los reemplazan). Solo se tira AQUI — en la
                        // instancia de daño real, ya pasado el guard de
                        // hurttime: nunca mientras ya esta inmune (mismo fix
                        // que el bloqueo LMS de Sonic de arriba).
                        if(global.character == CHARACTER_SALLY_CANON && global.player.duelista
                        && random(100) < SALLY_CANON_EVADE_CHANCE)
                        {
                                global.player.hurttime += SALLY_CANON_EVADE_INVULN;
                                
                                // esquiva: polvo en la direccion del golpe + pop
                                net_quick_effect(global.player.x + sign(xpw) * -10, global.player.y + 14, spr_dust);
                                audio_play_sound(snd_buble, 0, false);
                                net_sound_emit(snd_buble);
                                return;
                        }
                        
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
                        // (v4.10: el bloqueo COMPLETO de La Torre de Fleetway Amy
                        // ahora vive ARRIBA con las pasivas de inmunicion total:
                        // llegados aqui ya no es FW superviviente pura.)
                        
                        // v6.3: si el golpe se absorbe con anillos, la vida
                        // NI SE TOCA y no hay reporte al server (no hubo
                        // dano para las stats de «damage_taken»).
                        if(!_ringAbsorb)
                        {
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
                // personajes: con 10+ anillos el golpe se absorbe y cuesta
                // EXACTAMENTE 10 (v6.3); con menos de 10 los pierde todos,
                // como siempre.
                var _fortLoss = -1;
                
                if(global.character == CHARACTER_VANILLA)
                        _fortLoss = max(VANILLA_FORTALEZA_MIN, floor(global.player.rings * VANILLA_FORTALEZA_VANILLA_PCT / 100));
                else if(global.character == CHARACTER_CREAM && scr_vanilla_in_match())
                        _fortLoss = max(VANILLA_FORTALEZA_MIN, floor(global.player.rings * VANILLA_FORTALEZA_CREAM_PCT / 100));
                
                if(_fortLoss > 0)
                        global.player.rings = max(0, global.player.rings - min(_fortLoss, global.player.rings));
                else if(global.player.rings >= 10)
                        // golpe absorbido (v6.3): cuesta EXACTAMENTE 10,
                        // el excedente se queda en el contador
                        global.player.rings -= 10;
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
                
                // v6.3: golpe absorbido por anillos = sin sangre (los
                // anillos ya dispersan con spr_ringlose arriba); la sangre
                // es la marca del dano REAL de vida.
                if(!_ringAbsorb)
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

// =====================================================================
//  v4.8 — MARCA DE DEBILIDAD (pasiva 2 de Metal Amy).
//  La llama el cliente de la VICTIMA cuando un golpe de Metal Amy calo
//  de verdad (el laser en obj_metal_amy_bullet/Step_0 o el contacto del
//  dash/cualquier ataque en obj_player_puppet/Step_0). Efecto: TODOS los
//  enfriamientos de habilidad del superviviente entran en 6 s de
//  recarga — los que ya estaban enfriando, esos 6 s se les SUMAN (las
//  convenciones de cada timer se respetan: el vuelo de Tails cuenta en
//  negativo y el parry lleva su maximo a la par para que el relleno del
//  icono no desfase). El CD de la marca es PROPIO de cada superviviente:
//  16 s (weakMarkCd lo hace bajar scr_move_basic). Cero paquetes: corre
//  en el cliente de la victima sobre su propio jugador, como el dano.
//  Aviso LOCAL con snd_metal_cd (la marca es invisible para los demas:
//  el marcado lo nota porque sus iconos de habilidad se ponen rojos).
//  v3 (D.I.B.): _cd opcional — la MARCA MEJORADA de JINNA reusa esta
//  misma funcion con su propio enfriamiento (JINNA_WEAKMARK_CD, 13 s:
//  "un poco menor" que los 16 de Metal Amy, pero igual POR PERSONAJE,
//  no global). El efecto (los 8 s de recarga forzada) es identico.
// =====================================================================
function scr_weak_mark_hit(_cd = METALAMY_WEAKMARK_CD)
{
        if(!instance_exists(global.player))
                return;

        if(obj_netclient.gameEnds)
                return;

        // solo supervivientes vivos y sin demonizar
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
                return;

        if(global.player.isDead)
                return;

        // v5.0 LMS: Sonic en el LMS es INMUNE a la MARCA DE DEBILIDAD de
        // Metal Amy («No servira contra Sonic en LMS»): sus habilidades
        // jamas entran en la recarga forzada de 6 s mientras dure el show.
        if(global.character == CHARACTER_SONIC && global.lmsActive)
                return;

        // CD propio de 16 s por superviviente (la variable la creamos aqui
        // mismo la primera vez: no hacia falta tocar los Create de los 13
        // supervivientes, y scr_move_basic la hace bajar con un guard)
        // FIX v4.8.1: variable_instance_exists/set piden el ID DE INSTANCIA,
        // no el indice del objeto (global.player es el indice): igual que
        // obj_ghz_water, se resuelve con .id. Antes el exists devolvia false
        // siempre -> el set re-creaba la variable a 0 en cada golpe y el CD
        // de 16 s por superviviente nunca se aplicaba (la marca salia en
        // TODOS los golpes). instance_exists ya se comprobo arriba.
        if(!variable_instance_exists(global.player.id, "weakMarkCd"))
                variable_instance_set(global.player.id, "weakMarkCd", 0);

        if(global.player.weakMarkCd > 0)
                return;

        // v3 (D.I.B.): el enfriamiento POR SUPERVIVIENTE llega por
        // parametro (16 s Metal Amy / 13 s Jinna, su version mejorada)
        global.player.weakMarkCd = _cd;

        var _t = METALAMY_WEAKMARK_TIME;

        with(global.player)
        {
                switch(global.character)
                {
                        case CHARACTER_TAILS:
                                // el vuelo de Tails cuenta en NEGATIVO hacia -420
                                // (listo): la recarga de 6 s es -60. Si esta volando
                                // (positivo) el vuelo en curso sigue su curso.
                                if(flyTimer <= 0)
                                        flyTimer = max(flyTimer, -420 + _t);
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                break;

                        case CHARACTER_KNUX:
                                glideTimer = (glideTimer <= 0) ? _t : glideTimer + _t;
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                break;

                        case CHARACTER_EGGMAN:
                                djumpRecharge = (djumpRecharge <= 0) ? _t : djumpRecharge + _t;
                                shieldRechrage = (shieldRechrage <= 0) ? _t : shieldRechrage + _t;
                                trackerRecharge = (trackerRecharge <= 0) ? _t : trackerRecharge + _t;
                                break;

                        case CHARACTER_AMY:
                                hjumpTimer = (hjumpTimer <= 0) ? _t : hjumpTimer + _t;
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                break;

                        case CHARACTER_AMY_CANON:
                                hjumpTimer = (hjumpTimer <= 0) ? _t : hjumpTimer + _t;
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                dashTimer = (dashTimer <= 0) ? _t : dashTimer + _t;
                                parryCooldown = (parryCooldown <= 0) ? _t : parryCooldown + _t;
                                parryCooldownMax = max(parryCooldownMax, parryCooldown);
                                break;

                        case CHARACTER_SONIC:
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                parryCooldown = (parryCooldown <= 0) ? _t : parryCooldown + _t;
                                parryCooldownMax = max(parryCooldownMax, parryCooldown);
                                break;

                        case CHARACTER_CREAM:
                        case CHARACTER_VANILLA:
                                flyTimer = (flyTimer <= 0) ? _t : flyTimer + _t;
                                dashTimer = (dashTimer <= 0) ? _t : dashTimer + _t;
                                ringsTimer = (ringsTimer <= 0) ? _t : ringsTimer + _t;
                                break;

                        case CHARACTER_METAL:
                                dashTimer = (dashTimer <= 0) ? _t : dashTimer + _t;
                                electroTimer = (electroTimer <= 0) ? _t : electroTimer + _t;
                                break;

                        case CHARACTER_AMELIA:
                                bananaTimer = (bananaTimer <= 0) ? _t : bananaTimer + _t;
                                trapTimer = (trapTimer <= 0) ? _t : trapTimer + _t;
                                break;

                        case CHARACTER_BLAZE:
                                djumpRecharge = (djumpRecharge <= 0) ? _t : djumpRecharge + _t;
                                fireballTimer = (fireballTimer <= 0) ? _t : fireballTimer + _t;
                                burningTimer = (burningTimer <= 0) ? _t : burningTimer + _t;
                                break;

                        case CHARACTER_SALLY:
                        case CHARACTER_SALLY_CANON:
                                attackTimer = (attackTimer <= 0) ? _t : attackTimer + _t;
                                shieldRechrage = (shieldRechrage <= 0) ? _t : shieldRechrage + _t;
                                break;
                }
        }

        audio_play_sound(snd_metal_cd, 0, false);
}
