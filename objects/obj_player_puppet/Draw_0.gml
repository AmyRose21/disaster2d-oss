// v2.13 (ECLIPSE de «Sol y Luna»): la CEGUERA que arrastra el stun de
// una trampa de Amelia. En el cliente del bando EXE cegado, NINGUN
// superviviente renderiza — «como si todos se hubieran esfumado».
// Sus esbirros (isDemonized) y el propio EXE siguen visibles. Puro
// dibujado: la logica de juego (colisiones, dano, parry) no cambia.
if(!isDemonized && global.eclipseTimer > 0
&& instance_exists(global.player)
&& (global.character == CHARACTER_EXE || global.player.revivalTimes >= 2))
        return;

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

// ABRAZO COMBINADO (interaccion Amy Canon + Sonic): la AMY que esta
// abrazando dibuja el sprite combinado de los dos (spr_amy_hug_canon)
// en el punto medio con SU Sonic de este cliente (puppet o jugador
// local, lo encuentra scr_amy_hug_find_sonic) y no dibuja su cuerpo.
// El SONIC abrazado no se dibuja: lo tapa el sprite combinado. El
// check en vivo (scr_amy_hug_amy_near) cubre tambien el hueco de
// latencia en el que su propio estado 65 todavia no llego por red.
if(character == CHARACTER_AMY_CANON && state == AMY_CANON_HUG)
{
        var _hsonic = scr_amy_hug_find_sonic(id, AMY_HUG_KEEP);

        if(_hsonic != noone)
        {
                var _hmx = floor((x + _hsonic.x) / 2);
                var _hmy = floor((y + _hsonic.y) / 2);
                var _hside = (x > _hsonic.x) ? -1 : 1;
                var _hbob = ((current_time / 400) mod 2) < 1 ? 0 : -1;

                draw_sprite_ext(spr_amy_hug_canon, 0, _hmx, _hmy + _hbob, _hside, 1, 0, c_white, 1);
        }

        return;
}

if(character == CHARACTER_SONIC
&& (state == SONIC_HUGGED || scr_amy_hug_amy_near(id, AMY_HUG_KEEP) != noone))
        return;
 
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

// SONIC / AMY CANON PARRY: aura visible en el puppet mientras su ventana
// esta abierta (estado SONIC_PARRY_*_ACT viajando por UDP), para que los
// ALIADOS vean el radio que esta cubriendo. Rosa para Amy Canon, cian
// para Sonic (scr_parry_aura_color).
// v3.2: SOLO LA VEN LOS SUPERVIVIENTES. El EXE y los demonizados
// (esbirros, revivalTimes >= 2) NO ven el circulo: si lo vieran, el
// EXE sabria exactamente hasta donde llega la proteccion y le daria
// la vuelta en vez de atacar. La animacion del parry si la ve todo el
// mundo (el personaje se pone en pose delante de todos); lo que se
// oculta es el radio exacto del aura. Misma convencion de bando que
// scr_parry_protects_me (EXE o demonizado = lado EXE).
var _parryAuraVisible = (global.character != CHARACTER_EXE);
if(_parryAuraVisible && instance_exists(global.player) && global.player.revivalTimes >= 2)
        _parryAuraVisible = false; // esbirro: mismo bando que el EXE

if(_parryAuraVisible && scr_parry_char_has(character) && scr_parry_state_active(state))
{
        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.13);
        draw_set_color(scr_parry_aura_color(character));
        draw_circle(x, y - 6, SONIC_PARRY_AURA, false);
        draw_set_alpha(0.35);
        draw_set_color(scr_parry_aura_color_core(character));
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

// v2.13 (LUNA de «Sol y Luna»): Amelia OCULTA es INVISIBLE GRADO EXE —
// el cliente del EXE jamas renderiza su cuerpo («el indicador la
// senala, su cuerpo jamas»). El resto de clientes la ve igual que a
// cualquier escondido: semitransparente. Su nick/HP ya no se dibujan
// escondida para NADIE (el Draw_64 lo corta con !isHiding).
var _hideAlpha = (isHurt || isHiding) ? 0.5 : image_alpha;

if(isHiding && character == CHARACTER_AMELIA && global.character == CHARACTER_EXE)
        _hideAlpha = 0;

// AMY CYBER: mismo palette swap pero con el shader holograma para los
// personajes de AMY_CYBER_CHARS (Amy Canon). El resto cae al palette
// swap normal y no cambia nada. Es visual: cada cliente lo dibuja solo.
// v2: blindaje. Si scr_amy_cyber no esta cargado (script copiado pero
// sin registrar en el .yyp = asset fantasma), cae al palette swap de
// siempre: se dibuja normal y NUNCA mas salta el "not set before
// reading it".
if(variable_global_exists("scr_amy_cyber"))
        scr_amy_cyber(character, fromPallete, toPallete, is_cheating ? spr_merfurmu : sprite_index, image_index);
else
        scr_palette_swap(fromPallete, toPallete);
draw_sprite_ext(is_cheating ? spr_merfurmu : sprite_index, image_index, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, angle, image_blend, _hideAlpha);
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
                
        // v3: tirolina de los personajes que faltaban (mismos offsets que
        // obj_aiz_zipline/Step_2.gml, asi el carrito cae en el mismo sitio
        // que ve el jugador que viaja). OJO: SALLY_CANON viaja en
        // SALLY_ZIPLINE y VANILLA en CREAM_ZIPLINE (son los estados que
        // usan sus Step_2).
        case CHARACTER_SALLY_CANON:
                if(state == SALLY_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 23 - 19);
                
                // ESCUDO (v5.4): burbuja de su escudo activo (bitflag
                // PLAYER_SALLYSHIELD). Fase 1: animada como la de la Sally
                // vanilla (hasta hoy no se dibujaba nada en el puppet: hueco
                // arreglado). Fase DUELISTA: quieta / agachada / en el aire
                // el cuerpo usa la POSE (override del Draw_72), asi que la
                // burbuja solo sale en los demas estados (caminando o
                // corriendo) y SIN animacion (frame fijo), igual que en su
                // propio cliente.
                if(sallyShield)
                {
                        if(!duelista)
                                draw_sprite(spr_sallyshield_canon, (current_time / 30) % 41, floor(x), floor(y));
                        else if(state != IDLE && state != LOOKDOWN && state != JUMP && state != FALL)
                                draw_sprite(spr_sallyshield_canon, 0, floor(x), floor(y));
                }
                break;
                
        case CHARACTER_VANILLA:
                if(state == CREAM_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 16 - 19);
                break;
                
        case CHARACTER_METAL:
                if(state == METAL_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 17 - 19);
                break;
                
        case CHARACTER_AMELIA:
                if(state == AMELIA_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 22 - 19);
                break;
                
        case CHARACTER_BLAZE:
                if(state == BLAZE_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 19 - 19);
                break;
                
        case CHARACTER_FLEETWAY_AMY:
                if(state == FW_ZIPLINE)
                        draw_sprite(spr_aiz_zipline, 0, floor(x) - 12, floor(y) - 21 - 19);
                break;
}