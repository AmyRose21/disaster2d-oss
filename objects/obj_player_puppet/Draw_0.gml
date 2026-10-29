if(effect)
{
        if(character == CHARACTER_EXE)
        {
                if(exeCharacter == 1)
                {
                        if(effectTimer % irandom_range(5, 6) == 0)
                                instance_create_depth(x + irandom_range(-8, 8), y, depth+10, obj_chaos_kapla);
                }
        }
        
        if(effectTimer % 3 == 0)
        {
                var inst = scr_effect_fade_quick(x, y, sprite_index);
                inst.depth = depth + 1;
                inst.image_xscale = image_xscale;
                inst.image_index = image_index;
                inst.image_speed = 0;
                inst.palleteFrom = fromPallete;
                inst.palleteTo = toPallete;
        }
        
        effectTimer++;
}
 
switch(character)
{               
        case CHARACTER_KNUX:            
                if(state == KNUX_GLIDE)
                        image_xscale = 1;
                break;
}

// SONIC POWERBOOST (fase 3 de Nervios o fase 2 del revive): mismo look
// Frontiers que el jugador local (aura detras, rayos/tinte encima).
// El estado llega con el bitflag PLAYER_POWERBOOST de CLIENT_PLAYER_DATA.
var _pb = (character == CHARACTER_SONIC && powerBoost);

if(_pb)
        scr_powerboost_fx_back(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, angle, current_time / 16);

// SONIC PARRY: aura cian visible en el puppet mientras su ventana esta
// abierta (estado SONIC_PARRY_*_ACT viajando por UDP), para que los
// ALIADOS vean el radio que esta cubriendo.
// v3.2: SOLO LA VEN LOS SUPERVIVIENTES. El EXE y los demonizados
// (esbirros, revivalTimes >= 2) NO ven el circulo: si lo vieran, el
// EXE sabria exactamente hasta donde llega la proteccion y le daria
// la vuelta en vez de atacar. La animacion del parry si la ve todo el
// mundo (Sonic se pone en pose delante de todos); lo que se oculta es
// el radio exacto del aura. Misma convencion de bando que
// scr_parry_protects_me (EXE o demonizado = lado EXE).
var _parryAuraVisible = (global.character != CHARACTER_EXE);
if(_parryAuraVisible && instance_exists(global.player) && global.player.revivalTimes >= 2)
        _parryAuraVisible = false; // esbirro: mismo bando que el EXE

if(_parryAuraVisible && character == CHARACTER_SONIC && scr_parry_state_active(state))
{
        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.13);
        draw_set_color(SONIC_PB_COLOR);
        draw_circle(x, y - 6, SONIC_PARRY_AURA, false);
        draw_set_alpha(0.35);
        draw_set_color(SONIC_PB_COLOR);
        draw_circle(x, y - 6, SONIC_PARRY_AURA, true);
        draw_set_alpha(1);
        draw_set_color(c_white);
        gpu_set_blendmode(bm_normal);
}

// SALLY CANON fase 2: squash & stretch remoto (estira al despegar del
// salto de pt3, se aplasta al aterrizar en pt4), anclado al suelo igual
// que en el jugador local. El valor lo deriva el Step de este puppet.
var _f2xs = image_xscale;
var _f2ys = image_yscale;
var _f2yoff = 0;

if(character == CHARACTER_SALLY_CANON && f2Sq != 0)
{
        _f2ys = image_yscale * (1 + f2Sq);
        _f2xs = image_xscale * (1 - f2Sq * 0.6);
        _f2yoff = (sprite_height - sprite_yoffset) * (1 - _f2ys);
}

scr_palette_swap(fromPallete, toPallete);
draw_sprite_ext(is_cheating ? spr_merfurmu : sprite_index, image_index, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle, image_blend, (isHurt || isHiding) ? 0.5 : image_alpha);
shader_reset();

if(_pb)
        scr_powerboost_fx_front(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, angle, current_time / 16, abs(x - xprevious) + abs(y - yprevious) > 0.1);

if(potater)
        draw_sprite(spr_goodperson, potatoTimer, floor(x), floor(y)); 
        
if(is_cheating)
        draw_sprite(spr_some, 0, x, y);

switch(character)
{
        case CHARACTER_EXE:
                switch(exeCharacter)
                {
                        case EXE_ORIGINAL:
                                if(state == EXE_ZIPLINE)
                                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                                break;
                                
                                
                        case EXE_CHAOS:
                                if(state == CHAOS_ZIPLINE)
                                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                                break;
                                
                                
                        case EXE_EXELLER:
                                if(state == EXELLER_ZIPLINE)
                                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                                break;
                                
                                
                        case EXE_EXETIOR:
                                if(state == EXETIOR_ZIPLINE)
                                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                                break;
                }
                break;
                
        case CHARACTER_TAILS:   
                if(state == TAILS_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 11 - 19);
                
                if(tailsCharge > 0)
                        draw_sprite_ext(spr_tailscharge, floor((((tailsCharge / 60)) / 5.0) * 100), x + image_xscale * 24, y, image_xscale, 1, 0, c_white, 1);
                break;
                
        case CHARACTER_KNUX:
                if(state == KNUX_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                break;
                
        case CHARACTER_EGGMAN:
                if(state == EGG_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 25 - 19);
                
                if(isAttacking)
                        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));
                break;
                
        case CHARACTER_AMY:
                if(state == AMY_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 21 - 19);
                break;
                
        case CHARACTER_AMY_CANON:
                // ESTADO BURBUJA (secuestro): el resto de clientes ven a Amy
                // Canon atrapada dentro de la burbuja. El state 19/20/21
                // (frente/izquierda/derecha) llega solo con la sincronizacion
                // normal de CLIENT_PLAYER_DATA, y el sprite de captura lo
                // elige Draw_72 con el array de scr_survivors.gml.
                if(state >= AMY_CANON_CAPTURE && state <= AMY_CANON_CAPTURE_R)
                        draw_sprite(amy_Bubble, (current_time / 200) % 8, floor(x), floor(y));
                
                if(state == AMY_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 21 - 19);
                break;
                
        case CHARACTER_CREAM:
                if(state == CREAM_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 8 - 19);
                break;
                
        case CHARACTER_SALLY:
                if(state == SALLY_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 18 - 19);
                
                if(sallyShield)
                        draw_sprite(revivalTimes >= 2 ? spr_sallyshield2 : spr_sallyshield, (current_time / 30) % 41, floor(x), floor(y));
                break;
                
        case CHARACTER_SONIC:
                // TIROLINA de Sonic: la cuerda. Antes Sonic se volvia
                // invisible en la tirolina (el estado apuntaba a
                // spr_none); ya esta arreglado (SONIC_ZIPLINE -> idx
                // 17). Si la cuerda queda un pelin alta o baja, ajusta
                // el 22 de abajo.
                if(state == SONIC_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                break;
}