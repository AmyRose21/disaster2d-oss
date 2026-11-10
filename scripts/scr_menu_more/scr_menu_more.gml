// ============================================================================
// scr_menu_more — pestana MORE del menu OPTIONS (v1)
// ----------------------------------------------------------------------------
// Porte del menu Options > More del port web de TD2DR (sonicweb.dr2.site,
// port by PenguinEhis). Anade 12 ajustes de video / audio / camara al
// cliente, con su UI (lista con scroll, valores dinamicos, descripcion de
// cada fila y pestañas GENERAL | CONTROLS | MORE | BACK) y sus funciones
// repartidas por el proyecto:
//
//   idx ajuste             funcion                                          donde
//   0  BACKGROUNDS         oculta TODAS las capas de fondo (depth > 0)       obj_parallax
//   1  PARALLAX SCROLLING  fondos pegados a la camara (scroll 1:1)          obj_parallax
//   2  EFFECTS             polvo, chispas, particulas de golpe               scr_effect_quick
//   3  WEATHER             lluvia (GHZ) y nieve (NAP) + sonido de lluvia     controladores
//   4  SCREEN OVERLAYS     vignettes y overlays de pantalla                  obj_level / dotdotdot_i
//   5  PERFORMANCE         tiempos de frame en pantalla                      obj_level
//   6  MUSIC VOLUME        0-10, aplica a los 91 assets de musica           aqui (apply_volumes)
//   7  SOUND VOLUME        0-10, aplica a los 231 assets de sonido          aqui (apply_volumes)
//   8  LOOK AHEAD          off / 5%..50%: cuanto mira adelante la camara     obj_camera
//   9  LOOK AHEAD BY       facing (fijo) / speed (segun velocidad)           obj_camera
//  10  TURN SPEED          1-5: lo rapido que bascula el offset al girar     obj_camera
//  11  CAMERA LAG          off/low/medium/high: la camara se queda atras     obj_camera
//
// La UI se construye POR CODIGO (scr_menu_more_build) al entrar al menu,
// igual que el fix v4.2 de special3 y la pagina AboutAmyCanon: la room no
// se toca para nada, y si el IDE compila una room vieja esto la reconstruye.
//
// Navegacion (teclado): arriba/abajo = filas, izquierda/derecha = ciclar el
// valor (o moverse entre pestañas), Z = activar, X = salir. Raton: clic en
// una fila la cicla, clic en una pestaña la abre.
// ============================================================================

// Layout calibrado contra el port web (medido en vivo): 9 filas visibles
// de 17px de alto, primera fila en y=57, valor a la derecha (x+100).
#macro MORE_ROWS 9    // filas visibles de la lista (de 12)
#macro MORE_COUNT 12  // total de ajustes

// Listas de assets para los volumenes (audio_sound_gain con el ID del ASSET
// cambia las instancias actuales Y las futuras reproducciones: no hace falta
// tocar los 286 audio_play_sound del proyecto).
global.musList = [
        Best_ending, Best_ending_Alt, Duo_ending, Solo_ending, Solo_ending_Alt, Standard_Ending,
        Standard_Ending_Alt, mus_act9, mus_act9_chase, mus_alphagentemple, mus_alphagentemple_chase, mus_angelisland,
        mus_angelisland_chase, mus_bluespheres, mus_darktower, mus_darktower_chase, mus_deserttown, mus_deserttown_chase,
        mus_dotdotdot, mus_dotdotdot2, mus_dotdotdot_chase, mus_exewin, mus_fartzone, mus_fartzone_chase,
        mus_hauntdream, mus_hauntdream_chase, mus_hideandseek2, mus_hideandseek2_chase, mus_hill, mus_hill_chase,
        mus_kindandfair, mus_kindandfair_chase, mus_limpcity, mus_limpcity_chase, mus_lms_10, mus_lms_11,
        mus_lms_12, mus_lms_13, mus_lms_14, mus_lms_15, mus_lms_16, mus_lms_17,
        mus_lms_18, mus_lms_19, mus_lms_2, mus_lms_20, mus_lms_21, mus_lms_22,
        mus_lms_23, mus_lms_24, mus_lms_3, mus_lms_4, mus_lms_5, mus_lms_6,
        mus_lms_7, mus_lms_8, mus_lms_9, mus_lobby, mus_lobby_epic, mus_logo,
        mus_majinforest, mus_majinforest_chase, mus_marijuna, mus_marijuna_chase, mus_menu, mus_mindfuck,
        mus_minigame, mus_nastyparadise, mus_nastyparadise_chase, mus_notperfect, mus_notperfect_chase, mus_pricelessfreedom,
        mus_pricelessfreedom_chase, mus_ravimemist, mus_ravimemist_chase, mus_skybase, mus_skybase_chase, mus_survwin,
        mus_timeover, mus_torturecave, mus_torturecave_chase, mus_undefeatable, mus_volcanovalley, mus_volcanovalley_chase,
        mus_waiting, mus_weedzone, mus_weedzone_chase, mus_woodzone, mus_woodzone_chase, mus_youcantrun,
        mus_youcantrun_chase
];

global.sfxList = [
        DSTAROT1, DSTAROT2, DSTAROT3, EVASI1, EVASI2, EVASI3,
        Loop_Card, Perfect_Parry, SALLY1, SALLY2, SALLY3, SALLY4,
        SALLY5, hitspark_snd_LOUD, hitspark_snd_awehit1, hitspark_snd_awehit10, hitspark_snd_awehit11, hitspark_snd_awehit12,
        hitspark_snd_awehit13, hitspark_snd_awehit14, hitspark_snd_awehit15, hitspark_snd_awehit16, hitspark_snd_awehit2, hitspark_snd_awehit3,
        hitspark_snd_awehit4, hitspark_snd_awehit5, hitspark_snd_awehit6, hitspark_snd_awehit7, hitspark_snd_awehit8, hitspark_snd_awehit9,
        hitspark_snd_echo, hitspark_snd_heavy, hitspark_snd_hit1, hitspark_snd_hit10, hitspark_snd_hit11, hitspark_snd_hit12,
        hitspark_snd_hit2, hitspark_snd_hit3, hitspark_snd_hit4, hitspark_snd_hit5, hitspark_snd_hit6, hitspark_snd_hit7,
        hitspark_snd_hit8, hitspark_snd_hit9, snd_achivement, snd_acid, snd_amelia_banana_spawn, snd_amelia_trap,
        snd_amelia_trap_goth, snd_amelia_trap_goth_1, snd_blackring, snd_blackring_ball, snd_blaze_go, snd_blaze_goon,
        snd_blaze_shot, snd_blaze_shot_parr, snd_blaze_skak, snd_boohoo, snd_boom, snd_bos,
        snd_break, snd_bubble, snd_buble, snd_cash, snd_chaos_attack, snd_chaos_dash,
        snd_chaos_kill, snd_chaos_kill2, snd_chaos_kill3, snd_chaos_kill4, snd_chaos_kill5, snd_chaos_kill6,
        snd_chaos_kill7, snd_chaos_kill8, snd_chaos_land, snd_chaos_laugh, snd_chaos_pizza, snd_chaos_stun,
        snd_chaos_sturn, snd_chaos_taunt, snd_chaos_taunt2, snd_chaos_vineboom, snd_chocola_dive, snd_clock,
        snd_creamdash, snd_creamring, snd_crossbow, snd_dash, snd_dead, snd_demonization,
        snd_destiny, snd_dj, snd_door, snd_dummy, snd_dummy2, snd_dummy3,
        snd_echain, snd_echain_prepare, snd_egg_djump, snd_egg_shield, snd_egg_tracker, snd_egg_tracker_activate,
        snd_electroshock, snd_exe_appear, snd_exe_appear2, snd_exe_appear3, snd_exe_invisenter, snd_exe_invisenter2,
        snd_exe_kill1, snd_exe_kill2, snd_exe_kill3, snd_exe_kill4, snd_exe_laugh, snd_exe_ringshutter,
        snd_exe_stun, snd_exe_stun2, snd_exe_taunt, snd_exe_taunt1, snd_exe_taunt2, snd_exe_wins,
        snd_exeller_clone, snd_exeller_cloneline, snd_exeller_kill1, snd_exeller_kill2, snd_exeller_kill3, snd_exeller_kill4,
        snd_exeller_kill5, snd_exeller_kill6, snd_exeller_kill7, snd_exeller_laugh, snd_exeller_stun, snd_exeller_taunt1,
        snd_exeller_taunt2, snd_exeller_taunt3, snd_exetior_kill1, snd_exetior_kill2, snd_exetior_kill3, snd_exetior_kill4,
        snd_exetior_kill5, snd_exetior_kill6, snd_exetior_laugh, snd_exetior_ring1, snd_exetior_ring2, snd_exetior_ring3,
        snd_exetior_ring4, snd_exetior_shockwave, snd_exetior_stomp, snd_exetior_stompland, snd_exetior_stun, snd_exetior_taunt1,
        snd_exetior_taunt2, snd_exetior_taunt3, snd_expweak, snd_fart, snd_fnac, snd_heal,
        snd_hurt, snd_ice_break, snd_ice_spawn, snd_judger, snd_jump, snd_lava,
        snd_lavaappear, snd_lavahit, snd_lift, snd_menu_press, snd_menu_select, snd_mermer,
        snd_message, snd_metal_cd, snd_metal_dash, snd_metal_dash_1, snd_metal_dash_2, snd_metal_electro,
        snd_metal_electro_1, snd_metal_hiit, snd_metal_laugh, snd_metal_lazer, snd_metal_stun, snd_metalamy_dash,
        snd_minibal, snd_minidestroy, snd_minidie, snd_miniextra, snd_minispin, snd_ministart,
        snd_movingspike, snd_none, snd_nono, snd_npteleport, snd_parry, snd_penis,
        snd_rain, snd_ready, snd_redring, snd_ring, snd_ringabsorb, snd_ringlose,
        snd_roar, snd_sally_shield, snd_sally_shieldbreak, snd_sally_slide, snd_shard, snd_sisi_notice,
        snd_skybase_target, snd_slime, snd_smoke, snd_snap, snd_snowball_break, snd_snowball_roll,
        snd_spike, snd_spin, snd_spring, snd_spring_reverb, snd_suddendeath, snd_survivor_win,
        snd_tails_charge, snd_tails_fly, snd_tails_hit, snd_tails_shoot, snd_tailsball, snd_tailsball_chase,
        snd_tailsball_jumpscare, snd_tailsball_jumpscare2, snd_teleport, snd_thunder, snd_vasebreak, snd_waterdrops,
        snd_watersplash, snd_wdarms, snd_wdlamp
];

// ============================================================================
// build: crea la capa OptionsMore con sus 9 filas + 4 pestañas, y anade la
// pestaña MORE a las otras vistas de options. Idempotente: si ya existe, no
// hace nada. Se llama desde obj_menu/Alarm_0 (1 frame despues de crear la
// room, cuando TODAS las instancias ya existen) y como respaldo desde
// changeSubmenu(SUBMENU_OPTIONSMORE).
// ============================================================================
function scr_menu_more_build()
{
        if(room != room_menu)
                return;

        if(!layer_exists("OptionsMore"))
        {
                var _l = layer_create(-1500, "OptionsMore");
                layer_set_visible(_l, false);

                // 9 filas reciclables (como el port): displayRow fijo en pantalla,
                // bid = displayRow + scroll. x=290 alinea los labels con las filas
                // de las otras vistas de options (labels a ~200, valores a ~390).
                for(var i = 0; i < MORE_ROWS; i++)
                {
                        var _ry = 57 + i * 17;
                        var _r = instance_create_layer(290, _ry, _l, obj_menu_valuebutton);
                        _r.displayRow = i;
                        _r.bid = i;
                        _r.bcolumn = -1;
                        _r.submenu = SUBMENU_OPTIONSMORE;
                        _r.image_index = i;
                        _r.sY = _ry;
                }

                // pestañas inferiores (patron de las otras vistas; el frame 68
                // "MORE" respalda al 1 "OPTIONS" si el sprite quedo viejo)
                var _frameMore = sprite_get_number(spr_menu_buttons) > 68 ? 68 : 1;

                // y=252: misma linea de tabs que las vistas General/Controls/Back
                var _b = instance_create_layer(124, 252, _l, obj_menu_button);
                _b.bid = 12; _b.bcolumn = 0; _b.submenu = SUBMENU_OPTIONSMORE;
                _b.image_speed = 0; _b.image_index = 7;  // GENERAL

                _b = instance_create_layer(299, 252, _l, obj_menu_button);
                _b.bid = 13; _b.bcolumn = 0; _b.submenu = SUBMENU_OPTIONSMORE;
                _b.image_speed = 0; _b.image_index = 8;  // CONTROLS

                _b = instance_create_layer(420, 252, _l, obj_menu_button);
                _b.bid = 14; _b.bcolumn = 0; _b.submenu = SUBMENU_OPTIONSMORE;
                _b.image_speed = 0; _b.image_index = _frameMore;  // MORE

                _b = instance_create_layer(495, 252, _l, obj_menu_button);
                _b.bid = 15; _b.bcolumn = 0; _b.submenu = SUBMENU_OPTIONSMORE;
                _b.image_speed = 0; _b.image_index = 4;  // BACK (salir)
        }

        // pestaña MORE anadida a las vistas General/Controls/Back (bid unico en
        // cada vista, manejado en buttonPressed). Auto-curacion por instancia:
        // si una capa faltara (room compilada vieja), se crea oculta igual que
        // el fix v4.2 de special3 antes de usarla.
        var _frameMore2 = sprite_get_number(spr_menu_buttons) > 68 ? 68 : 1;
        var _found = false;

        if(!layer_exists("OptionsGeneral"))
        {
                var _lg = layer_create(-1400, "OptionsGeneral");
                layer_set_visible(_lg, false);
        }

        with(obj_menu_button)
        {
                if(submenu == 2 && bid == 6)
                {
                        _found = true;
                        break;
                }
        }

        if(!_found)
        {
                var _bg = instance_create_layer(420, 252, layer_get_id("OptionsGeneral"), obj_menu_button);
                _bg.bid = 6; _bg.bcolumn = 0; _bg.submenu = 2;
                _bg.image_speed = 0; _bg.image_index = _frameMore2;
        }

        _found = false;

        if(!layer_exists("OptionsControls"))
        {
                var _lc = layer_create(-1500, "OptionsControls");
                layer_set_visible(_lc, false);
        }

        with(obj_menu_button)
        {
                if(submenu == 3 && bid == 11)
                {
                        _found = true;
                        break;
                }
        }

        if(!_found)
        {
                var _bc = instance_create_layer(420, 252, layer_get_id("OptionsControls"), obj_menu_button);
                _bc.bid = 11; _bc.bcolumn = 0; _bc.submenu = 3;
                _bc.image_speed = 0; _bc.image_index = _frameMore2;
        }

        _found = false;

        if(!layer_exists("OptionsBack"))
        {
                var _lb = layer_create(-1500, "OptionsBack");
                layer_set_visible(_lb, false);
        }

        with(obj_menu_button)
        {
                if(submenu == 4 && bid == 3)
                {
                        _found = true;
                        break;
                }
        }

        if(!_found)
        {
                var _bb = instance_create_layer(420, 252, layer_get_id("OptionsBack"), obj_menu_button);
                _bb.bid = 3; _bb.bcolumn = 0; _bb.submenu = 4;
                _bb.image_speed = 0; _bb.image_index = _frameMore2;
        }

        scr_menu_more_refresh();
}

// ============================================================================
// refresh: reasigna cada fila visible al ajuste que le toca segun el scroll.
// El frame del sprite coincide con el indice del ajuste (spr_menu_more).
// ============================================================================
function scr_menu_more_refresh()
{
        with(obj_menu_valuebutton)
        {
                bid = displayRow + obj_menu.moreScroll;
                image_index = bid;
        }
}

// ============================================================================
// ensure_visible: ajusta el scroll para que la fila seleccionada se vea.
// Lo llama buttonSelected() antes de resaltar, asi el resaltado siempre
// encuentra su instancia (el bid de la fila ya esta actualizado).
// ============================================================================
function scr_menu_more_ensure_visible(_sel)
{
        if(_sel < 0 || _sel >= MORE_COUNT)
                return;

        var _new = obj_menu.moreScroll;

        if(_new < _sel - (MORE_ROWS - 1))
                _new = _sel - (MORE_ROWS - 1);

        if(_new > _sel)
                _new = _sel;

        if(_new < 0)
                _new = 0;

        if(_new > MORE_COUNT - MORE_ROWS)
                _new = MORE_COUNT - MORE_ROWS;

        if(_new != obj_menu.moreScroll)
        {
                obj_menu.moreScroll = _new;
                scr_menu_more_refresh();
        }
}

// ============================================================================
// cycle: cambia el ajuste _data en la direccion _dir (+1/-1) y guarda.
// ============================================================================
function scr_menu_more_cycle(_data, _dir)
{
        switch(_data)
        {
                case 0: obj_config.optBackgrounds = !obj_config.optBackgrounds; break;
                case 1: obj_config.optParallax = !obj_config.optParallax; break;
                case 2: obj_config.optEffects = !obj_config.optEffects; break;
                case 3: obj_config.optWeather = !obj_config.optWeather; break;
                case 4: obj_config.optOverlays = !obj_config.optOverlays; break;
                case 5: obj_config.optPerf = !obj_config.optPerf; break;

                case 6:
                        var _mv = obj_config.musicVolume + _dir;

                        if(_mv > 10) _mv = 0; // wrap como el port (todos sus cyclers envuelven)
                        if(_mv < 0) _mv = 10;

                        obj_config.musicVolume = _mv;
                        scr_menu_more_apply_volumes();
                        break;

                case 7:
                        var _sv = obj_config.soundVolume + _dir;

                        if(_sv > 10) _sv = 0;
                        if(_sv < 0) _sv = 10;

                        obj_config.soundVolume = _sv;
                        scr_menu_more_apply_volumes();
                        break;

                case 8: // off / 5% / ... / 50% / off (wrap verificado en el port)
                {
                        var _la = obj_config.lookAhead + _dir;

                        if(_la > 10) _la = 0;
                        if(_la < 0) _la = 10;

                        obj_config.lookAhead = _la;
                        break;
                }
                case 9: obj_config.lookAheadBy = 1 - obj_config.lookAheadBy; break; // facing <-> speed

                case 10:
                        var _t = obj_config.turnSpeed + _dir;

                        if(_t > 5) _t = 1;
                        if(_t < 1) _t = 5;

                        obj_config.turnSpeed = _t;
                        break;

                case 11:
                        var _c = obj_config.cameraLag + _dir;

                        if(_c > 3) _c = 0;
                        if(_c < 0) _c = 3;

                        obj_config.cameraLag = _c;
                        break;
        }

        obj_config.save();
}

// ============================================================================
// toggle_state / value_text / desc: lectura para la UI.
// ============================================================================
function scr_menu_more_toggle_state(_data)
{
        switch(_data)
        {
                case 0: return obj_config.optBackgrounds;
                case 1: return obj_config.optParallax;
                case 2: return obj_config.optEffects;
                case 3: return obj_config.optWeather;
                case 4: return obj_config.optOverlays;
                case 5: return obj_config.optPerf;
        }

        return false;
}

function scr_menu_more_value_text(_data)
{
        switch(_data)
        {
                case 0: return obj_config.optBackgrounds ? "on" : "off";
                case 1: return obj_config.optParallax ? "on" : "off";
                case 2: return obj_config.optEffects ? "on" : "off";
                case 3: return obj_config.optWeather ? "on" : "off";
                case 4: return obj_config.optOverlays ? "on" : "off";
                case 5: return obj_config.optPerf ? "on" : "off";
                case 6: return string(obj_config.musicVolume);
                case 7: return string(obj_config.soundVolume);
                case 8: return obj_config.lookAhead == 0 ? "off" : string(obj_config.lookAhead * 5) + "%";
                case 9: return obj_config.lookAheadBy == 0 ? "facing" : "speed";
                case 10: return string(obj_config.turnSpeed);

                case 11:
                        switch(obj_config.cameraLag)
                        {
                                case 0: return "off";
                                case 1: return "low";
                                case 2: return "medium";
                                case 3: return "high";
                        }

                        return "off";
        }

        return "";
}

// Descripciones tal cual el port web (minusculas: scr_text_spr es minusculas)
function scr_menu_more_desc(_data)
{
        switch(_data)
        {
                case 0: return "the layers behind the level";
                case 1: return "depth scrolling of the backgrounds";
                case 2: return "dust, sparkles, shards, hit effects";
                case 3: return "rain, snow and similar particles";
                case 4: return "vignettes and full-screen overlays";
                case 5: return "frame timings on screen";
                case 6: return "how loud the music is";
                case 7: return "how loud the sounds are";
                case 8: return "how far the camera looks ahead (of the view)";
                case 9: return "facing: always. speed: more the faster you go";
                case 10: return "how fast it swings over when you turn";
                case 11: return "at speed the camera falls behind and catches up (like the classic games)";
        }

        return "";
}

// ============================================================================
// apply_volumes: fija el gain por ASSET para musica (91) y sonido (231).
// Con el ID del asset, audio_sound_gain cambia las instancias sonando ahora
// y todas las reproducciones futuras. Se llama al cargar la config y al
// mover los sliders.
// ============================================================================
function scr_menu_more_apply_volumes()
{
        var _m = obj_config.musicVolume * 0.1;

        for(var i = 0; i < array_length(global.musList); i++)
                audio_sound_gain(global.musList[i], _m, 0);

        var _s = obj_config.soundVolume * 0.1;

        for(var j = 0; j < array_length(global.sfxList); j++)
                audio_sound_gain(global.sfxList[j], _s, 0);
}
