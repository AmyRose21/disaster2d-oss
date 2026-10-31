if(!global.showHud)
        return;
        
if(instance_exists(global.player) && !global.player.isDead)
{                       
        switch(global.character)
        {
                case CHARACTER_EXE: //exe
                {
                        switch(global.exeCharacter)
                        {
                                case EXE_ORIGINAL:
                                        var prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        draw_sprite_ext(spr_gui_exeattack, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        
                                        var prog = global.playerControls && global.player.isJumping;
                                        draw_sprite_ext(spr_gui_exefreejump, 0, 3, 218 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog ? c_white : c_red, prog ? 1 : 0.5);
                                        
                                        var prog = (min(global.player.invisTimer, 0) / EXE_INVIS_RECHARGE);
                                        draw_sprite_ext(spr_gui_exeinvisability, 0, prog * 4, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        break;
                                        
                                case EXE_CHAOS:
                                        if(global.player.stuckTimer <= 30/2)
                                        {
                                                var prog = global.player.slimeTimer > 0 ? 0 : 1.0 - (min(global.player.attackTimer, 120) / 120.0);
                                                draw_sprite_ext(spr_gui_chaosattack, !global.player.isGrounded, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        }
                                        else
                                        {
                                                var frame = 2;
                                                
                                                if(global.player.isGrounded && global.player.stuckDir > 0)
                                                        frame = 1;
                                                        
                                                if(global.player.isGrounded && global.player.stuckDir < 0)
                                                        frame = 0;
                                                
                                                var prog = 1;
                                                draw_sprite_ext(spr_gui_chaoswalldash, frame, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        }
                                        
                                        var prog = global.playerControls && global.player.isJumping;
                                        draw_sprite_ext(spr_gui_exefreejump, 0, 3, 218 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog && global.player.slimeTimer <= 0 ? c_white : c_red, global.player.slimeTimer <= 0 ? (prog ? 1 : 0.5) : 0);
                                        
                                        var prog = global.player.slimeTimer > 0 ? 1 : (min(global.player.slimeTimer, 0) / -CHAOS_INVIS_RECHARGE);
                                        draw_sprite_ext(spr_gui_chaosslime, 0, prog * 4, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        break;
                                        
                                case EXE_EXETIOR:
                                        var prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        draw_sprite_ext(spr_gui_exetiorattack, !global.player.isGrounded, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        
                                        var prog = global.playerControls && global.player.isJumping;
                                        draw_sprite_ext(spr_gui_exefreejump, 0, 3, 218 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog ? c_white : c_red, prog ? 1 : 0.5);
                                        
                                        var prog = (1.0 - (global.player.bringTimer / EXETIOR_BRING_RECHARGE));
                                        draw_sprite_ext(spr_gui_exetiorring, 0, prog * 4, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 && global.player.canSpawnRings ? c_white : c_red, prog);
                                        break;
                                        
                                case EXE_EXELLER:
                                        var prog = 1.0 - (min(global.player.attackTimer, 180) / 180.0);
                                        draw_sprite_ext(spr_gui_exeattack, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        
                                        var prog = global.playerControls && global.player.isJumping;
                                        draw_sprite_ext(spr_gui_exefreejump, 0, 3, 218 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog ? c_white : c_red, prog ? 1 : 0.5);
                                        
                                        var prog = 1.0 - (global.player.cloneTimer / EXELLER_CLONE_RECHARGE);
                                        var spr = spr_gui_exellerclone;
                                        
                                        if((keyboard_check(global.KeyDown) || keyboard_check(global.KeyUp)))
                                        {
                                                if(global.player.cloneCount > 0)
                                                {
                                                        spr = spr_gui_exellerclone2;
                                                        prog = 1;
                                                }
                                        }
                                        
                                        if(spr == spr_gui_exellerclone && global.player.cloneCount >= 2)
                                                prog = 0;
                                        
                                        draw_sprite_ext(spr, 0, prog * 4, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        break;
                                
                                case EXE_METALAMY:
                                {
                                        // v2.2 (TTB): golpe (X) y bala del canon (C)
                                        var prog = 1.0 - (min(global.player.attackTimer, 120) / 120.0);
                                        draw_sprite_ext(spr_gui_metalamyattack, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        
                                        var prog = global.playerControls && global.player.isJumping;
                                        draw_sprite_ext(spr_gui_exefreejump, 0, 3, 218 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog ? c_white : c_red, prog ? 1 : 0.5);
                                        
                                        var prog = 1.0 - (global.player.bulletTimer / METALAMY_BULLET_RECHARGE);
                                        draw_sprite_ext(spr_gui_metal_amy_lazer, 0, prog * 4, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                                        break;
                                }
                        }
                        
                        break;
                }
                
                case CHARACTER_TAILS: //tails
                {
                        var prog = (min(global.player.flyTimer, 0) / -420.0);
                        draw_sprite_ext(spr_gui_tailsfly, global.player.revivalTimes >= 2, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var val = global.player.revivalTimes >= 2 ? ETAILS_ATTACK_RECHARGE : TAILS_ATTACK_RECHARGE;
                        var prog = 1.0 - (global.player.attackTimer / val);
                        draw_sprite_ext(spr_gui_tailsattack, 0, prog * 12, 250 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        break;
                }
                
                case CHARACTER_KNUX:
                {
                        var prog = 1.0 - (min(global.player.glideTimer, KNUX_GLIDE_RECHARGE) / KNUX_GLIDE_RECHARGE);
                        draw_sprite_ext(spr_gui_knuxglide, global.player.revivalTimes >= 2, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var val = global.player.revivalTimes >= 2 ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        var prog = 1.0 - (min(global.player.attackTimer, val) / val);
                        draw_sprite_ext(spr_gui_knuxattack, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);       
                        break;
                }
                
                case CHARACTER_EGGMAN:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / EGGMAN_DJUMP_RECHARGE);
                        draw_sprite_ext(spr_gui_eggdjump, 0, prog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.shieldRechrage, 0) / EGGMAN_SHIELD_RECHARGE);
                        draw_sprite_ext(spr_gui_eggshield, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);        
                        
                        var prog = 1.0 - (max(global.player.trackerRecharge, 0) / EGGMAN_TRACKER_RECHARGE);
                        draw_sprite_ext(spr_gui_eggtrack, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, (global.player.isColliding && prog == 1.0) ? c_white : c_red, prog);  
                        break;
                }
                
                case CHARACTER_AMY:
                {
                        var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_BIGJUMP_RECHARGE);
                        draw_sprite_ext(spr_gui_amyhjump, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var val = global.player.revivalTimes >= 2 ? KNUX_EXEATTACK_RECHARGE : KNUX_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        draw_sprite_ext(spr_gui_amyattack, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);        
                        break;
                }
                
                case CHARACTER_AMY_CANON:
                {
                                // Icono 1: SALTO DE MARTILLO (tecla Z, en el suelo). El relleno
                                // muestra el CD; blanco = listo Y en el suelo (espejo del icono 3).
                                var prog = 1.0 - (max(global.player.hjumpTimer, 0) / AMY_CANON_BIGJUMP_RECHARGE);
                                var b1 = (prog == 1.0 && global.player.isGrounded) ? c_white : c_red;
                                draw_sprite_ext(spr_gui_amyhjump_canon, 0, prog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, b1, prog);
                        
                                // Icono 2: IMPULSO AEREO DE TAROT (tecla X, SOLO en el aire).
                                // El relleno muestra el CD; blanco = lista Y en el aire
                                // (espejo del icono 3, que exige estar en el suelo).
                                var val = global.player.revivalTimes >= 2 ? AMY_CANON_ETAROTDASH_RECHARGE : AMY_CANON_TAROTDASH_RECHARGE;
                                var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                                var b2 = (prog == 1.0 && !global.player.isGrounded) ? c_white : c_red;
                                draw_sprite_ext(spr_gui_amyattack_canon, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, b2, prog);
                        
                        // Icono 3: ACOMETIDA DE MARTILLO (tecla C). Muestra la letra C
                        // (como los demas iconos de tecla C del juego). El relleno
                        // muestra el CD; blanco = lista y en el suelo.
                        var val = global.player.revivalTimes >= 2 ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;
                        var prog = 1.0 - (max(global.player.dashTimer, 0) / val);
                        var b = (prog == 1.0 && global.player.isGrounded) ? c_white : c_red;
                        draw_sprite_ext(spr_gui_amydash_canon, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, b, prog);        
                        
                        // Icono 4: PARRY (tecla V, v4.0). Mismas fijaciones que el de
                        // Sonic (estados 60/61/64). El relleno muestra el CD que falta:
                        // como el CD depende de COMO termino el ultimo intento
                        // (fallo/exito), se guarda la duracion total en
                        // parryCooldownMax al aplicarlo y asi el icono siempre arranca
                        // lleno. Blanco = listo Y en el suelo (el parry es solo en
                        // tierra); rojo = lo demas. Si spr_gui_amyparry_canon no
                        // existiera en el proyecto, no se dibuja pero tampoco crashea
                        // (mismo patron que el parry de Sonic y el spindash).
                                                // v4.1: se dibuja AL LADO del icono de la acometida (misma fila
                        // que la C, a su derecha) y no DEBAJO: la vista mide 480x270 y una
                        // cuarta fila apilada (y=276) caia FUERA de pantalla (por eso no
                        // salia). C y V comparten fila, como Z X C V en el teclado; en
                        // Android (y-200) tampoco choca con el boton G (23,81).
                        var _sprParry = asset_get_index("spr_gui_amyparry_canon");
                        if(_sprParry >= 0)
                        {
                                var _pmax = max(global.player.parryCooldownMax, 1);
                                var _pprog = 1.0 - (max(global.player.parryCooldown, 0) / _pmax);
                                var _pready = (_pprog >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                                draw_sprite_ext(_sprParry, 0, 44 + _pprog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, _pready, _pprog);
                        }
                        break;
                }
                case CHARACTER_SONIC:
                {
                        // Icono (tecla C): PARRY (v3.2). El relleno muestra el CD
                        // que falta: como el CD depende de COMO termino el ultimo
                        // intento (fallo/exito x normal/powerboost), se guarda la
                        // duracion total en parryCooldownMax al aplicarlo y asi el
                        // icono siempre arranca lleno. Blanco = listo Y en el
                        // suelo (el parry es solo en tierra); rojo = lo demas.
                        // Si spr_gui_sonicparry no existiera en el proyecto, no se
                        // dibuja pero tampoco crashea (mismo patron que el
                        // spindash de abajo).
                        var _sprParry = asset_get_index("spr_gui_sonicparry");
                        if(_sprParry >= 0)
                        {
                                var _pmax = max(global.player.parryCooldownMax, 1);
                                var _pprog = 1.0 - (max(global.player.parryCooldown, 0) / _pmax);
                                var _pready = (_pprog >= 1.0 && global.player.isGrounded) ? c_white : c_red;
                                draw_sprite_ext(_sprParry, 0, _pprog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, _pready, _pprog);
                        }
                        
                        // Icono (tecla X): EL GOLPE. Reutiliza el icono generico del
                        // ataque de Amy; cuando crees spr_gui_sonicattack, cambialo aqui.
                        var val = global.player.revivalTimes >= 2 ? SONIC_EATTACK_RECHARGE : SONIC_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        draw_sprite_ext(spr_gui_amyattack, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);        
                        
                        // Icono (abajo + Z): SPINDASH. Sin cooldown: su coste es el
                        // tiempo de revolucioneo. Siempre visible: blanco = listo para
                        // cargar; rojo = cargando la bola (brilla mas al llenarse).
                        // Icono extraido del mod TD2DR X SONIC de Renx Diamond.
                        // Si spr_gui_sonicspindash no existe (aun sin crear en el IDE),
                        // no se dibuja pero tampoco crashea.
                        var _sprSpindash = asset_get_index("spr_gui_sonicspindash");
                        if(_sprSpindash >= 0)
                        {
                                if(global.player.isSpinCharging)
                                {
                                        var charge = global.player.spinCharge / SONIC_SPINDASH_CHARGE_MAX;
                                        draw_sprite_ext(_sprSpindash, 0, charge * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, charge >= 1.0 ? c_white : c_red, 0.4 + charge * 0.6);
                                }
                                else
                                        draw_sprite_ext(_sprSpindash, 0, 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, c_white, 1);
                        }
                        
                        // Icono (Z en el aire): DROP DASH (v3). Sin cooldown: su coste
                        // es medio segundo de agarre en el aire. Se dibuja AL LADO del
                        // spindash, en su misma fila (como el parry de Amy Canon v4.1:
                        // la vista mide 480x270 y una fila mas caeria fuera de
                        // pantalla). El relleno es el armado (dropDashTimer / HOLD);
                        // blanco = en el aire tras saltar (se puede armar), rojo = en
                        // tierra o vuelo sin salto; lleno y fijo = ARMADO: al aterrizar
                        // sale disparado. Usa el sprite spr_gui_sonicdropdash (existia
                        // en el proyecto sin usar). Si no existiera, no se dibuja pero
                        // tampoco crashea (mismo patron que el parry y el spindash).
                        var _sprDropdash = asset_get_index("spr_gui_sonicdropdash");
                        if(_sprDropdash >= 0)
                        {
                                if(global.player.dropDashReady)
                                        draw_sprite_ext(_sprDropdash, 0, 54, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, c_white, 1);
                                else
                                {
                                        var _ddprog = min(global.player.dropDashTimer / SONIC_DROPDASH_HOLD, 1.0);
                                        var _ddcol = (global.player.dropDashFromJump && !global.player.isGrounded) ? c_white : c_red;
                                        draw_sprite_ext(_sprDropdash, 0, 44 + _ddprog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, _ddcol, 0.4 + _ddprog * 0.6);
                                }
                        }
                        break;
                }
                case CHARACTER_CREAM:
                {
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        draw_sprite_ext(spr_gui_creamfly, global.player.revivalTimes >= 2, prog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        draw_sprite_ext(spr_gui_creamdash, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.ringsTimer, 0) / (global.player.revivalTimes >= 2 ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        draw_sprite_ext(spr_gui_creamrings, global.player.revivalTimes >= 2, prog * 10, 257 - (os_type == os_android ? 200 : 0), 1, 1, 0, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog);
                        break;
                }

                case CHARACTER_VANILLA:
                {
                        // VANILLA: mismas habilidades que Cream (scr_cream_special),
                        // reusa sus iconos del HUD (vuelo Z, dash X, anillos C)
                        var prog = 1.0 - (max(global.player.flyTimer, 0) / CREAM_FLY_RECHARGE);
                        draw_sprite_ext(spr_gui_creamfly, global.player.revivalTimes >= 2, prog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);

                        var prog = 1.0 - (max(global.player.dashTimer, 0) / CREAM_DASH_RECHARGE);
                        draw_sprite_ext(spr_gui_creamdash, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);

                        var prog = 1.0 - (max(global.player.ringsTimer, 0) / (global.player.revivalTimes >= 2 ? ECREAM_RINGS_RECHARGE : CREAM_DASH_RECHARGE));
                        draw_sprite_ext(spr_gui_creamrings, global.player.revivalTimes >= 2, prog * 10, 257 - (os_type == os_android ? 200 : 0), 1, 1, 0, (prog == 1.0 && !global.player.isColliding) ? c_white : c_red, prog);
                        break;
                }
                
                // ============================================================
                // v2.2 (TTB) — METAL SONIC: dash (X) y electro (C)
                case CHARACTER_METAL:
                {
                        var prog = 1.0 - (max(global.player.dashTimer, 0) / (global.player.revivalTimes >= 2 ? EMETAL_DASH_RECHARGE : METAL_DASH_RECHARGE));
                        draw_sprite_ext(spr_gui_creamdash, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.electroTimer, 0) / (global.player.revivalTimes >= 2 ? EMETAL_ELECTRO_RECHARGE : METAL_ELECTRO_RECHARGE));
                        draw_sprite_ext(spr_gui_eggshield, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        break;
                }
                
                // ============================================================
                // v2.4 (TTB) — AMELIA: trampolin (X) y trampa (C).
                // (v2.2 tenia 3 iconos: el de vuelo se elimino junto a
                // la habilidad; se reusan los sprites ya registrados)
                case CHARACTER_AMELIA:
                {
                        var prog = 1.0 - (max(global.player.bananaTimer, 0) / (global.player.revivalTimes >= 2 ? EAMELIA_BANANA_RECHARGE : AMELIA_BANANA_RECHARGE));
                        draw_sprite_ext(spr_gui_amelia_trap, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.trapTimer, 0) / (global.player.revivalTimes >= 2 ? EAMELIA_TRAP_RECHARGE : AMELIA_TRAP_RECHARGE));
                        draw_sprite_ext(spr_gui_eggtrack, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, (prog == 1.0 && global.player.isColliding) ? c_white : c_red, prog);
                        break;
                }
                
                // ============================================================
                // v2.2 (TTB) — BLAZE: salto de fuego (Z), bola (X) y ardiente (C)
                case CHARACTER_BLAZE:
                {
                        var prog = 1.0 - (max(global.player.djumpRecharge, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_DJUMP_RECHARGE : BLAZE_DJUMP_RECHARGE));
                        draw_sprite_ext(spr_gui_eggdjump, 0, prog * 10, 222 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.fireballTimer, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_FIREBALL_RECHARGE : BLAZE_FIREBALL_RECHARGE));
                        draw_sprite_ext(spr_gui_amyattack, 0, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        
                        var prog = 1.0 - (max(global.player.burningTimer, 0) / (global.player.revivalTimes >= 2 ? EBLAZE_BURNING_RECHARGE : BLAZE_BURNING_RECHARGE));
                        draw_sprite_ext(spr_gui_sallyshield, 0, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        break;
                }
                
                case CHARACTER_SALLY:
                {
                        var val = global.player.revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        
                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;
                        
                        if(global.player.isGrounded)
                                b = c_red;
                        
                        draw_sprite_ext(spr_gui_sallyattack, global.player.revivalTimes >= 2, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, b, prog);
                        
                        var val = global.player.revivalTimes >= 2 ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE;
                        var prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        draw_sprite_ext(spr_gui_sallyshield, global.player.revivalTimes >= 2, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        break;
                }
                case CHARACTER_SALLY_CANON:
                {
                        // SALLY CANON: tiene las mismas habilidades que Sally
                        // (scr_sally_special), asi que usa sus mismos iconos del
                        // HUD: la PATADA aerea (tecla Z) y el ESCUDO (tecla C).
                        // El relleno de cada icono muestra el CD que le falta;
                        // blanco = listo (la patada ademas exige estar en el
                        // aire, igual que en el HUD de Sally).
                        var val = global.player.revivalTimes >= 2 ? SALLY_EATTACK_RECHARGE : SALLY_ATTACK_RECHARGE;
                        var prog = 1.0 - (max(global.player.attackTimer, 0) / val);
                        
                        var b = c_red;
                        if(prog == 1.0)
                                b = c_white;
                        
                        if(global.player.isGrounded)
                                b = c_red;
                        
                        draw_sprite_ext(spr_gui_sallyattack, global.player.revivalTimes >= 2, prog * 10, 240 - (os_type == os_android ? 200 : 0), 1, 1, 0, b, prog);
                        
                        var val = global.player.revivalTimes >= 2 ? SALLY_ESHIELD_RECHARGE : SALLY_SHIELD_RECHARGE;
                        var prog = 1.0 - (max(global.player.shieldRechrage, 0) / val);
                        draw_sprite_ext(spr_gui_sallyshield, global.player.revivalTimes >= 2, prog * 10, 258 - (os_type == os_android ? 200 : 0), 1, 1, 0, prog == 1.0 ? c_white : c_red, prog);
                        break;
                }
        }
        
        if(global.character != CHARACTER_EXE && (global.player.state == IDLE || global.player.emotion))
                draw_sprite(spr_gui_emotions, 0, 470, 222 - (os_type == os_android ? 200 : 0));
}