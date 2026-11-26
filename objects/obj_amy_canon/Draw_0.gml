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
                // v51: fantasma SIN paleta mientras la super este activa
                inst.palleteFrom = (variable_instance_exists(id, "superFormPhase") && superFormPhase > 0) ? [] : global.palleteFrom;
                inst.palleteTo = (variable_instance_exists(id, "superFormPhase") && superFormPhase > 0) ? [] : global.palleteTo;
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

        // v51 — SUPER AMY: los sprites super traen los colores
        // HORNEADOS — mientras la super este activa NO se aplica paleta
        // de skin ni modo cyber (recolorearia arte que ya viene
        // coloreado de fabrica). Se dibuja tal cual; el shader_reset
        // de abajo queda inocuo sin ningun shader puesto.
        // v82 (duena): el holograma mejora (contorno luminoso, glow exterior,
        // lineas de datos, pies que se deshacen) y necesita saber DONDE se
        // dibuja el cuerpo: mismo punto, escala, rotacion y alfa que el
        // draw_sprite_ext de abajo. Por eso scr_wss_draw() sube aqui (es
        // pura: da igual llamarla antes) y sale una sola vez.
        var _wss = scr_wss_draw();
        var _cyRot = (isSpinning && !isLightDashing) ? 0 : radtodeg(angle);
        var _cyAlp = (hurttime > 0 || isHiding) ? 0.5 : image_alpha;

        if(!(variable_instance_exists(id, "superFormPhase") && superFormPhase > 0))
        {
                if(variable_global_exists("scr_amy_cyber"))
                {
                        scr_amy_cyber_halo(global.character, sprite_index, image_index, -1, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot, _cyAlp);
                        scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, sprite_index, image_index, -1, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot);
                }
                else
                        scr_palette_swap(global.palleteFrom, global.palleteTo);
        }
        // v6.0 — FIX ROTACION INVISIBLE: saltar EN BOLA conserva isSpinning (v5.3
        // del manejo) y este ternario forzaba angle = 0 con ese flag — durante el
        // light dash el rayo volaba DE LADO hacia los anillos de ARRIBA sin girar
        // (el puppet remoto si giraba: el local era el unico ciego). Ahora el
        // dash manda sobre la bola: si esta volando como rayo, SIEMPRE rota.
        // v72 WSS: escala squash & stretch del cuerpo (scr_wss),
        // anclada al suelo — solo visual: la fisica y la mascara
        // de colision no cambian. [fx, fy, yoff].
        // (v82: la llamada a scr_wss_draw() subio al bloque de arriba; aqui
        // solo se dibuja el cuerpo con los mismos valores que el shader.)
        draw_sprite_ext(sprite_index, image_index, floor(x), floor(y + _wss[2]), image_xscale * _wss[0], image_yscale * _wss[1], _cyRot, image_blend, _cyAlp);
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

// v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer, 2.5 s).
// Mismo dibujo que el escudo de Eggman (patron obj_egg/Draw_0 L22): sprite
// compartido spr_electroshield, anim por current_time. Lazy var (coyoteTimer
// pattern): los personajes sin la variable no la tocan.
if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)
        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));

// v71 ITEM BOX v3 — escudo de burbuja de la caja (shieldTimer): mismo
// patrón del eléctrico de arriba — burbuja animada encima del cuerpo en
// cualquier estado. Lazy var (coyoteTimer pattern): personajes sin la
// variable (o sin caja) no la tocan; Sally/SallyCanon/Rouge la dibujan
// en su propio Draw.
if(variable_instance_exists(id, "shieldTimer") && shieldTimer > 0)
        draw_sprite(revivalTimes >= 2 ? spr_sallyshield2 : spr_sallyshield, (current_time / 30) % 41, floor(x), floor(y));
