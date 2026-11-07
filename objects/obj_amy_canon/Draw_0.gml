if(effectTime > 0)
{
        effectTime--;
        
        if(effectTime % 3 == 0)
        {
                var inst = scr_effect_fade_quick(x, y, sprite_index);
                inst.image_xscale = image_xscale;
                inst.image_index = image_index;
                inst.image_speed = 0;
                inst.depth = depth+10;
                inst.palleteFrom = global.palleteFrom;
                inst.palleteTo = global.palleteTo;
        }
}

// ABRAZO COMBINADO (interaccion con Sonic): mientras Amy abraza, su
// cuerpo NO se dibuja; en su lugar se pinta el sprite combinado de
// los dos (spr_amy_hug_canon, con los corazones) en el punto medio
// entre los dos cuerpos. A Sonic lo esconden los demas clientes con
// el mismo check en vivo (scr_amy_hug_amy_near), asi que aqui solo
// importa el dibujado. El espejado sale de la posicion relativa real
// (si Amy quedo a la derecha de Sonic, se dibuja volteado para que
// cada uno quede en su lado). Nada de paleta ni de cuerpo propio.
if(state == AMY_CANON_HUG)
{
        var _sonic = scr_amy_hug_find_sonic(id, AMY_HUG_KEEP);

        if(_sonic != noone)
        {
                var _mx = floor((x + _sonic.x) / 2);
                var _my = floor((y + _sonic.y) / 2);
                var _side = (x > _sonic.x) ? -1 : 1;

                // pequeña respiracion: sube 1 px y baja cada ~400 ms
                var _bob = ((current_time / 400) mod 2) < 1 ? 0 : -1;

                draw_sprite_ext(spr_amy_hug_canon, 0, _mx, _my + _bob, _side, 1, 0, c_white, 1);
        }

        return;
}

// PARRY (tecla V): aura rosa visible mientras la ventana esta abierta
// (para que los aliados vean el radio que les cubre, igual que el aura
// cian de Sonic). El color lo fija scr_parry_aura_color: rosa para Amy.
if(parryState == 2)
{
        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.13);
        draw_set_color(scr_parry_aura_color(global.character));
        draw_circle(x, y - 6, SONIC_PARRY_AURA, false);
        draw_set_alpha(0.35);
        draw_set_color(scr_parry_aura_color_core(global.character));
        draw_circle(x, y - 6, SONIC_PARRY_AURA, true);
        draw_set_alpha(1);
        draw_set_color(c_white);
        gpu_set_blendmode(bm_normal);
}

// v5.9.4 — LIGHT DASH: la ESTELA FANTASMAL ya NO nace aqui: la pinta el
// propio scr_light_dash (scr_light_dash_ghost: un fantasma en el
// arranque, uno por CADA frame de vuelo y uno final al salir). Antes
// nacia en este Draw y el frame de salida llegaba con isLightDashing ya
// en false — el ultimo tramo se quedaba sin estela y se veia "solo al
// agarrar el anillo" (y a 16 px/frame el viaje entero duraba 2-3
// frames). Ahora, a 10 px/frame y con fantasma por frame, el rayo es
// continuo de punta a punta. La pose rotada de cada fantasma sale de
// lightDashDeg/lightDashFace (lo mismo que dibuja el cuerpo).

//Actual draw
// AMY CYBER: mismo palette swap de siempre pero envuelto en el shader
// holograma (shd_amy_cyber) cuando el efecto esta activo. Si esta
// apagado (AMY_CYBER_ENABLED false) cae al scr_palette_swap normal.
// v2: blindaje. Si scr_amy_cyber no esta cargado (script copiado pero
// sin registrar en el .yyp = asset fantasma), cae al palette swap de
// siempre: se dibuja normal y NUNCA mas salta el "not set before
// reading it".
if(variable_global_exists("scr_amy_cyber"))
        scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, sprite_index, image_index);
else
        scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

// ESTADO BURBUJA: dibuja la burbuja de secuestro ENCIMA de Amy.
// amy_Bubble son 8 frames a 5 fps (200 ms por frame); su origen
// (24,25) la deja perfectamente centrada sobre el sprite de
// captura (37x41). Asi la ve igual el jugador local que el resto
// de clientes (los puppets la dibujan desde obj_player_puppet).
if(bubbleState == AMY_BUBBLE_ACTIVE)
        draw_sprite(amy_Bubble, (current_time / 200) % 8, floor(x), floor(y));

// PARRY: anillo de activacion / exito (mismo estilo del powerboost de
// Sonic; el flash es blanco y no lleva color de personaje).
scr_powerboost_fx_flash(floor(x), floor(y - 6), parryFlash);

// v5.9.2 — LIGHT DASH: FLECHA INDICADORA. La Z de Amy tiene DOS
// habilidades en el aire (mantener = flotacion del tarot, tocar junto
// a una cadena = rayo): mientras un toque ARRANCARIA el rayo, se pinta
// sobre el PRIMER anillo de la cadena una flecha en la direccion del
// primer tramo y al lado el keycap de la tecla REAL de salto
// (scr_hud_keycap_at: si el usuario remapea el salto en Opciones, la
// letra cambia aqui tambien). Flecha visible = Z tocada = rayo; sin
// flecha = Z mantenida = flotacion. Solo lo dibuja el jugador local
// (los puppets no leen input). La vida (lightDashAimLife) la repone
// el escaneo continuo del script cada frame y caduca sola: si el hook
// no corrio (burbuja, shock, partida conectando) no queda ninguna
// flecha congelada en pantalla.
if(lightDashAimLife > 0)
{
        lightDashAimLife--;

        // v5.9.3: UN anillo basta — la flecha marca tambien el lunge de
        // recogida hacia un anillo suelto (no solo lineas de 2+)
        var _ring = (array_length(lightDashAim) >= 1) ? lightDashAim[0] : noone;

        if(_ring != noone && instance_exists(_ring) && !_ring.used)
        {
                // v5.10: direccion del PRIMER TRAMO DE LA RUTA — recto al
                // anillo o el primer giro del desvio A*: hacia donde saldra
                // disparada de verdad
                var _dir = lightDashAimDir;
                var _pulse = 0.75 + 0.25 * dsin(current_time / 4);

                // ancla de la flecha: un poco antes del PRIMER PUNTO de la
                // ruta (el anillo en vuelo recto; el primer quiebre con
                // desvio), sobre la linea del tramo (del lado de Amy)
                var _ax = lightDashAimX + lengthdir_x(LIGHT_DASH_ARROW_DIST, _dir + 180);
                var _ay = lightDashAimY + lengthdir_y(LIGHT_DASH_ARROW_DIST, _dir + 180);

                gpu_set_blendmode(bm_add);
                draw_set_color(make_color_rgb(255, 216, 64));

                // halo doble sobre el primer anillo
                draw_set_alpha(0.30 * _pulse);
                draw_circle(_ring.x, _ring.y, 11 + 2 * _pulse, false);
                draw_set_alpha(0.55 * _pulse);
                draw_circle(_ring.x, _ring.y, 13, true);

                // la flecha: triangulo apuntando en la direccion del tramo
                var _s = LIGHT_DASH_ARROW_SIZE * (0.85 + 0.15 * _pulse);
                var _bx = _ax + lengthdir_x(-_s * 0.6, _dir);
                var _by = _ay + lengthdir_y(-_s * 0.6, _dir);

                draw_set_alpha(0.85 * _pulse);
                draw_triangle(_ax + lengthdir_x(_s, _dir),
                              _ay + lengthdir_y(_s, _dir),
                              _bx + lengthdir_x(_s * 0.55, _dir + 90),
                              _by + lengthdir_y(_s * 0.55, _dir + 90),
                              _bx + lengthdir_x(_s * 0.55, _dir - 90),
                              _by + lengthdir_y(_s * 0.55, _dir - 90),
                              false);

                draw_set_alpha(1);
                draw_set_color(c_white);
                gpu_set_blendmode(bm_normal);

                // keycap de la tecla REAL (Z remapeable) al lado del
                // anillo, sobre el lateral derecho del tramo — asi nunca
                // tapa la cadena ni a Amy
                scr_hud_keycap_at(_ring.x + lengthdir_x(16, _dir - 90) - 4,
                                  _ring.y + lengthdir_y(16, _dir - 90) - 4,
                                  global.KeyA, c_white, 0.7 + 0.3 * _pulse, 0);
        }
}