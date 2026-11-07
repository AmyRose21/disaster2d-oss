/// scr_light_dash — LIGHT DASH de Amy Canon (Z en el aire junto a una
// linea de anillos). v5.9.
// =====================================================================
//  La mecanica clasica de Sonic Adventure: pulsar la tecla de salto en
//  el aire cerca de una linea de anillos convierte a Amy en un rayo que
//  recorre la linea tragandose cada anillo, y sale disparada con el
//  impulso del ultimo tramo. En TD es una herramienta de escape y de
//  economia: las columnas verticales de anillos se vuelven ascensores
//  y las filas horizontales carriles de velocidad — con la contra
//  jugada NATIVA de que el EXE puede reventar los anillos de la linea
//  (melee / laser de Metal Amy) y cortarte el camino.
//
//  ROTACION — "el metodo rotativa de las inclinaciones": la pose se
//  apoya en la MISMA variable `angle` que usan las pendientes (el
//  sensor la calcula en el suelo; aqui la escribe el dash en el aire).
//  El draw local usa radtodeg(angle) y por red ya viaja resuelto (s16
//  en grados + image_xscale): el puppet del otro cliente replica la
//  vuelta SIN un solo cambio de red, igual que hoy ve a uno inclinado
//  en una rampa. La correspondencia es la misma de las pendientes:
//  viajando a la derecha el sprite gira la direccion tal cual; viajando
//  a la izquierda el sprite esta espejado y la rotacion se mapea a
//  (direccion - 180), que SIEMPRE cae en -90..+90: nunca queda cabeza
//  abajo y NUNCA viaja de espaldas — siempre guia la cara/pecho hacia
//  donde va. El giro entre tramos se suaviza con un lerp hecho sobre
//  el angulo RENDERIZADO (no el de dibujo): el espejo cambia el
//  forward 180° de golpe, asi que el flip de la mirada se deriva del
//  propio angulo y cae siempre en la vertical (donde ambas miradas
//  dibujan lo mismo): el volteo es continuo, sin saltos, "como en una
//  rampa" — de ahi que cruzar de arriba-derecha a arriba-izquierda
//  pase por arriba y no dibuje un salto de direccion.
//
//  CERO paquetes nuevos: la posicion viaja igual (u16 x/y), el estado
//  es el byte de siempre (AMY_CANON_LIGHTDASH = 25; el 24 es el del
//  abrazo combinado y va interceptado antes del array — ver Step_2)
//  y el server lo reenvia opaco como hizo con los 60/61/64 del parry;
//  la animacion remota sale del image_index que ya viaja sincronizado.
//
//  INTEGRACION: scr_move_basic llama a scr_light_dash_step() justo
//  despues del bloque de muerte. Si devuelve true, este frame es del
//  dash: se corre scr_collision_basic() (sensores/suelo honestos,
//  mismo patron que el early-return de "!isServerReady") y despues
//  scr_light_dash_pose() REAPLICA posicion+pose, porque el collision
//  resetea angle=0 en el aire y sumaria la gravedad del frame. En el
//  frame de SALIDA devuelve false: deja el impulso en xspd/yspd y la
//  fisica normal toma el relevo en ese mismo frame (el angle vuelve a
//  0 solo, en el bloque de aire de scr_move_basic).
//
//  La recogida de cada anillo NO la hace el dash: viaja PASANDO por
//  encima de cada anillo y el Step del propio obj_ring lo detecta con
//  place_meeting y manda su CLIENT_RING_COLLECTED de siempre. Cero
//  cambios en el sistema de anillos.
//
//  v5.9.2 — LA Z TIENE DOS HABILIDADES EN EL AIRE: mantenerla cayendo
//  es la flotacion del tarot (pasiva, Step_0) y tocarla junto a una
//  cadena es este rayo. Para que la eleccion nunca sea ambigua, el
//  escaneo de cadena corre CONTINUO mientras un toque podria arrancar
//  (tambien flotando) y Draw_0 pinta sobre el primer anillo una flecha
//  en la direccion del primer tramo + el keycap de la tecla REAL de
//  salto (scr_hud_keycap_at, respeta remapeos): flecha visible = Z
//  tocada = rayo; sin flecha = Z mantenida = flotacion. Z se mantiene
//  porque es la tecla de habilidad aerea de todo el roster (Tails
//  vuela, Knux planea, Blaze/Cream tocan Z en el aire): mudarla a
//  otra tecla romperia la convencion del juego entero.
//
//  v5.9.3 — ALCANCE AMPLIADO A PETICION DEL USUARIO: radio de captura
//  del primer anillo 56 -> 96 px, tolerancia entre eslabones 48 -> 80
//  (los anillos NO hacen falta que esten pegados) y UN solo anillo ya
//  activa: el dash funciona tambien como lunge de recogida hacia un
//  anillo suelto, saliendo disparada hacia el con la velocidad del
//  tramo (pre-fijada al arrancar, para que un anillo encima no la
//  deje parada muerta en el aire).
//
//  v5.9.4 — RITMO Y ESTELA CONTINUA: velocidad 16 -> 10 px/frame (a 16
//  se sentia teletransporte: "esta ahi y ya agarro el anillo") y la
//  estela ahora nace en el PROPIO STEP (scr_light_dash_ghost: un
//  fantasma en el arranque, en CADA frame de viaje y uno final al
//  salir) — antes nacia en el Draw, que corria con isLightDashing ya
//  en false justo en el frame de salida: el ultimo tramo jamas dejaba
//  fantasma y por eso la estela "solo salia al agarrar el anillo".
//  Con fantasma por frame a 10 px/frame el rayo queda continuo.
// =====================================================================

// --- PARAMETROS AJUSTABLES (60 frames = 1 segundo) -------------------
#macro LIGHT_DASH_SPEED 8         // px/frame del vuelo (v5.9.4: era 16, muy rapida)
#macro LIGHT_DASH_FIRST_RADIUS 96  // radio de captura del PRIMER anillo (v5.9.3: era 56)
#macro LIGHT_DASH_LINK_DIST 80     // dist max entre eslabones (v5.9.3: era 48; no hace falta que esten pegados)
#macro LIGHT_DASH_MAX_RINGS 20     // tope de anillos por cadena (seguridad)
#macro LIGHT_DASH_MAX_TIME 200     // tope de frames de vuelo (v5.9.4: 180, por la velocidad menor)
#macro LIGHT_DASH_TURN 0.35        // suavizado del volteo (1 = instantaneo)
#macro LIGHT_DASH_ANIMSPD 0.5      // velocidad de la animacion del rayo
// v5.9.1 — ESTELA FANTASMAL (efecto de rayo): un obj_quickeffect_fade
// copiando la pose ROTADA cada N frames, igual que la estela del float
// run de Vanilla y la del powerboost de Sonic (misma tecnica). v5.9.4:
// la estela la spawnea el PROPIO script (scr_light_dash_ghost) en el
// arranque + cada frame de vuelo + la salida, y la cadencia es 1.
#macro LIGHT_DASH_GHOST_EVERY 1     // frames entre fantasmas (1 = rayo continuo)
#macro LIGHT_DASH_GHOST_FADE 0.06   // velocidad de desvanecido (1/0.06 ~ 17f)
// v5.9.2 — FLECHA INDICADORA: mientras un toque podria arrancar el
// rayo, Draw_0 marca el primer anillo de la cadena con una flecha en
// la direccion del primer tramo + el keycap de la tecla REAL de salto.
#macro LIGHT_DASH_ARROW_DIST 16     // px del anillo al ancla de la flecha
#macro LIGHT_DASH_ARROW_SIZE 7      // largo de la punta de la flecha (px)

// scr_light_dash_step(): activacion + viaje. Devuelve true si ESTE
// frame lo controla el dash. Las variables lazy siguen el patron de
// coyoteTimer: se crean en el primer frame, sin tocar el Create de
// ningun personaje (el hook corre para todos, EXE incluido, y sale
// por el gate de personaje antes de tocar nada propio de Amy).
function scr_light_dash_step()
{
        // --- declaracion lazy (patron coyoteTimer) ---
        // v5.9.1: para AMY esto ya lo declara su Create (fix del crash del
        // primer frame: los early-returns de scr_move_basic saltaban este
        // init y el Step_2 leia isLightDashing sin existir). El bloque queda
        // como red de seguridad para el RESTO de personajes, que tambien
        // corren este hook desde scr_move_basic sin leer nunca las vars.
        if(!variable_instance_exists(id, "isLightDashing"))
        {
                isLightDashing = false;
                lightDashChain = [];    // ids de los anillos de la cadena
                lightDashIdx = 0;       // indice del anillo objetivo actual
                lightDashTime = 0;      // frames de vuelo (tope de seguridad)
                lightDashDeg = 0;       // angulo de dibujo actual (grados)
                lightDashFace = 1;      // mirada actual del sprite (±1)
                lightDashToX = x;       // posicion objetivo de este frame
                lightDashToY = y;
                lightDashVX = 0;        // velocidad del tramo (para red/salida)
                lightDashVY = 0;
                lightDashGhostTimer = 0; // contador de la estela (scr_light_dash_ghost)
                lightDashAim = [];       // v5.9.2: cadena para la FLECHA (Draw_0)
                lightDashAimLife = 0;    // v5.9.2: vida de la flecha (caduca sola)
        }

        // v5.9.2 — la FLECHA caduca sola cada frame: la repuebla el escaneo
        // de la seccion 2 solo cuando un toque real podria arrancar el rayo.
        // Si este frame el hook no corre (burbuja, shock, partida aun
        // conectando) o un gate corta antes del escaneo, lightDashAim queda
        // vacia y el Draw no pinta ninguna flecha congelada en pantalla.
        lightDashAim = [];
        lightDashAimLife = 0;

        // ================= 1. VIAJE =================
        if(isLightDashing)
        {
                lightDashTime++;

                // --- cancelaciones duras: mismas que el impulso de tarot ---
                if(isDead || isHurt || shockedTimer > 0 || isZipline
                || bubbleState == AMY_BUBBLE_ACTIVE || hugActive || parryState > 0
                || redRingTimer > 0 || x <= 1 || x >= room_width - 1
                || y > room_height + 60 || lightDashTime > LIGHT_DASH_MAX_TIME)
                        return scr_light_dash_exit();

                // --- objetivo vivo? (el EXE pudo reventarlo / un aliado
                //     recogerlo: se salta el eslabon y se sigue) ---
                var _tgt = noone;
                while(lightDashIdx < array_length(lightDashChain))
                {
                        var _r = lightDashChain[lightDashIdx];

                        if(instance_exists(_r) && !_r.used)
                        {
                                _tgt = _r;
                                break;
                        }

                        lightDashIdx++;
                }

                if(_tgt == noone)
                        return scr_light_dash_exit(); // cadena agotada: fuera con impulso

                // --- mover hacia el anillo gastando LIGHT_DASH_SPEED px ---
                var _dx = _tgt.x - x;
                var _dy = _tgt.y - y;
                var _dist = point_distance(0, 0, _dx, _dy);
                var _budget = LIGHT_DASH_SPEED;

                // un frame puede comerse varios eslabones cortos: se gastan los
                // pixels de a poco, eslabon a eslabon, hasta agotar el budget
                lightDashToX = x;
                lightDashToY = y;

                while(_budget > 0 && _tgt != noone)
                {
                        _dx = _tgt.x - lightDashToX;
                        _dy = _tgt.y - lightDashToY;
                        _dist = point_distance(0, 0, _dx, _dy);

                        if(_dist <= _budget || _dist == 0)
                        {
                                // aterrizo en este anillo: siguiente eslabon
                                lightDashToX = _tgt.x;
                                lightDashToY = _tgt.y;
                                _budget -= max(_dist, 0);
                                lightDashIdx++;

                                // RECOGIDA DIRECTA: a 16 px/frame el presupuesto de un frame
                                // puede saltarse un anillo POR DENTRO (la mascara del jugador
                                // no llega a tocarlo en el frame justo) y quedaria vivo en
                                // mitad de la linea tragada. El dash marca el anillo y manda
                                // el MISMO CLIENT_RING_COLLECTED que mandaria su propio Step
                                // (iid + nid): el server responde igual que siempre (rings,
                                // sonido y posible curacion de los 10 en TODOS los clientes).
                                // El used = true hace que el Step del anillo se salga solo
                                // (ningun paquete duplicado).
                                _tgt.used = true;

                                var _pak = cpacket_tcp(PacketType.CLIENT_RING_COLLECTED);
                                buffer_write(_pak, buffer_u8, _tgt.iid);
                                buffer_write(_pak, buffer_u16, _tgt.nid);
                                send_server_tcp(_pak);

                                _tgt = noone;
                                while(lightDashIdx < array_length(lightDashChain))
                                {
                                        var _r2 = lightDashChain[lightDashIdx];

                                        if(instance_exists(_r2) && !_r2.used)
                                        {
                                                _tgt = _r2;
                                                break;
                                        }

                                        lightDashIdx++;
                                }
                        }
                        else
                        {
                                lightDashToX += _dx / _dist * _budget;
                                lightDashToY += _dy / _dist * _budget;
                                _budget = 0;
                        }
                }

                // --- pose: rotacion por el metodo de las pendientes ---
                // direccion REAL del movimiento de este frame
                var _mx = lightDashToX - x;
                var _my = lightDashToY - y;

                if(_mx != 0 || _my != 0)
                {
                        // El lerp se hace sobre el angulo RENDERIZADO (a donde
                        // apunta el sprite EN PANTALLA), no sobre el de dibujo:
                        // el espejo (image_xscale) cambia el forward 180° de
                        // golpe, asi que girar θ a ciegas atravesaria la
                        // vertical dibujando un salto de direccion. Aqui R =
                        // hacia donde apunta ahora; se gira R por el CAMINO
                        // CORTO hasta la direccion de viaje, y de R se
                        // re-derivan mirada y θ. El flip de la mirada cae
                        // SIEMPRE en R = ±90 (vertical): con θ = 90 mirando
                        // derecha y θ = -90 mirando izquierda el sprite apunta
                        // ARRIBA igual — el cambio es invisible al render y el
                        // volteo queda continuo, como el de una pendiente.
                        var _d = point_direction(0, 0, _mx, _my); // 0=der, 90=arriba
                        var _r = lightDashFace < 0 ? lightDashDeg + 180 : lightDashDeg;

                        _r += angle_difference(_d, _r) * LIGHT_DASH_TURN;

                        if(dcos(_r) >= 0)
                        {
                                lightDashFace = 1;
                                lightDashDeg = _r;
                        }
                        else
                        {
                                lightDashFace = -1;
                                lightDashDeg = _r - 180;
                        }

                        // canonizacion: el lerp converge por el CAMINO CORTO en
                        // espacio envuelto, asi que deg puede acabar fuera de
                        // (-180, 180] (p.ej. -355, que es 5). El render es el
                        // mismo (la rotacion es modulo 360) pero se normaliza
                        // para que el invariante |deg| <= 90 quede garantizado
                        // y el s16 que viaja por red sea siempre canonico.
                        while(lightDashDeg > 180)
                                lightDashDeg -= 360;

                        while(lightDashDeg <= -180)
                                lightDashDeg += 360;

                        // velocidad del tramo (para la red y el impulso de salida)
                        var _len = point_distance(0, 0, _mx, _my);
                        lightDashVX = _mx / _len * LIGHT_DASH_SPEED;
                        lightDashVY = _my / _len * LIGHT_DASH_SPEED;
                }

                // xspd/yspd a 0 ANTES del scr_collision_basic del hook: asi el
                // integrador del collision no suma movimiento encima del dash
                xspd = 0;
                yspd = 0;

                // v5.9.4: estela de ESTE frame de vuelo, en la posicion donde
                // acaba el movimiento (el hook aplica la pose justo despues)
                scr_light_dash_ghost(lightDashToX, lightDashToY);

                return true;
        }

        // ================= 2. FLECHA + ACTIVACION =================
        if(global.character != CHARACTER_AMY_CANON)
                return false;

        // demonizada (revivalTimes >= 2) no puede recoger anillos: el Step
        // del obj_ring se lo impide, la cadena no se tragaria nada
        if(revivalTimes >= 2)
                return false;

        if(!global.playerControls)
                return false;

        // aire, viva, sin estados que peleen el cuerpo
        if(isGrounded || isDead || isHurt || shockedTimer > 0 || isZipline)
                return false;

        if(isDashing || isTarotDashing || isHJ || isAttacking)
                return false;

        if(bubbleState == AMY_BUBBLE_ACTIVE || hugActive || parryState > 0 || redRingTimer > 0)
                return false;

        // v5.9.2 — ESCANEO CONTINUO (la flecha): la cadena se busca SIEMPRE
        // que un toque podria arrancar el rayo, no solo en el frame del
        // toque. Con eso Draw_0 pinta la flecha sobre el primer anillo y el
        // jugador sabe que hace Z ANTES de tocarla: flecha visible = Z
        // tocada = rayo; sin flecha = Z mantenida = flotacion del tarot.
        // Flotando (isTarotFloat) la flecha TAMBIEN sale: soltar y volver a
        // tocar SI arranca el rayo desde la flotacion, y el jugador tiene
        // que verlo. Misma cadena para la flecha y para el arranque: lo que
        // ves es lo que vuela.
        var _chain = scr_light_dash_find();

        lightDashAim = _chain;
        lightDashAimLife = 2; // la gasta el Draw (1 frame de vida + colchon)

        // v5.9.3 — UN anillo BASTA: el dash funciona tambien como lunge
        // de recogida hacia un anillo suelto (recoge y sale disparada
        // hacia el). Con cadena vacia (nada a <= 96 px) no hay nada que
        // hacer. La flecha del Draw tambien sale con 1 solo anillo.
        if(array_length(_chain) < 1)
                return false;

        // Z TOCADA en el aire (tap). MANTENERLA no activa nada: la pasiva
        // del tarot (flotacion) sigue en su sitio con su propio gate (ver
        // obj_amy_canon/Step_0, que exige !isLightDashing). El gate de
        // isTarotFloat va AQUI, despues del escaneo y no arriba con los
        // estados activos: flotando no existe un "toque" de Z sin soltarla
        // antes (keyboard_check_pressed no dispara con la tecla ya abajo),
        // asi que nunca bloquea de verdad — pero deja la regla escrita: el
        // rayo arranca con un toque limpio, nunca desde la mantencion.
        if(isTarotFloat || !keyboard_check_pressed(global.KeyA))
                return false;

        // --- arrancar ---
        isLightDashing = true;
        isTarotFloat = false;
        isJumping = false;
        isGrounded = false;
        image_index = 0;

        lightDashChain = _chain;
        lightDashIdx = 0;
        lightDashTime = 0;
        lightDashDeg = radtodeg(angle); // parte de la pose actual (0 en el aire)
        lightDashFace = image_xscale >= 0 ? 1 : -1;
        lightDashToX = x;
        lightDashToY = y;

        // v5.9.3 — velocidad PRE-FIJADA con la direccion del primer
        // tramo: con un solo anillo muy cerca, el frame de vuelo casi
        // no mide movimiento y la salida quedaria parada muerta en el
        // aire; asi el lunge de 1 anillo siempre sale con sus 16 px/frame
        // hacia el anillo, y el paquete del frame de arranque ya viaja
        // con la direccion buena (los primeros frames de red se ven
        // bien en el puppet). Con cadena larga lo sobreescribe el viaje
        // en cuanto corre el primer frame real.
        var _d0 = point_direction(x, y, _chain[0].x, _chain[0].y);
        lightDashVX = lengthdir_x(LIGHT_DASH_SPEED, _d0);
        lightDashVY = lengthdir_y(LIGHT_DASH_SPEED, _d0);

        // v5.9.4: primer fantasma del rayo (arranque). La estela nace AQUI
        // en el step y no en el Draw: el frame de salida llegaba al Draw con
        // isLightDashing ya en false y el tramo final se quedaba sin
        // fantasmas. Contador a cero: la cadencia arranca limpia.
        lightDashGhostTimer = 0;
        scr_light_dash_ghost(x, y);

        audio_play_sound(snd_dash, 0, false);
        net_sound_emit(snd_dash);

        // el viaje real empieza el frame siguiente; este frame solo fija el
        // estado (la Z ya se consumio en el salto si venia de un borde)
        return true;
}

// scr_light_dash_pose(): REAPLICA la pose del dash DESPUES de
// scr_collision_basic (que resetea angle=0 en el aire y suma la
// gravedad del frame). La llama el hook de scr_move_basic.
function scr_light_dash_pose()
{
        if(!isLightDashing)
                return;

        x = lightDashToX;
        y = lightDashToY;
        angle = degtorad(lightDashDeg);
        image_xscale = lightDashFace;

        // velocidad real para la red (el paquete viaja justo despues) y
        // para el impulso del frame de salida
        xspd = lightDashVX;
        yspd = lightDashVY;
}

// scr_light_dash_ghost(): deja UN fantasma de la estela en (xx, yy) con
// la pose rotada actual del dash. v5.9.4: la estela nace en el STEP (la
// llama este script en el arranque, en CADA frame de vuelo y al salir)
// y no en el Draw — el Draw corria cuando isLightDashing ya podia estar
// en false (frame de salida) y el tramo final jamas dejaba fantasma: por
// eso la estela "solo salia al agarrar el anillo". Con fantasma por
// frame (LIGHT_DASH_GHOST_EVERY 1) y 10 px/frame, el rayo es continuo.
function scr_light_dash_ghost(xx, yy)
{
        lightDashGhostTimer++;

        if(lightDashGhostTimer mod LIGHT_DASH_GHOST_EVERY != 0)
                return;

        var _ghost = instance_create_depth(xx, yy, 0, obj_quickeffect_fade);
        _ghost.sprite_index = sprite_index;
        _ghost.image_index = image_index;
        _ghost.image_xscale = lightDashFace;
        _ghost.image_yscale = 1;
        _ghost.image_angle = lightDashDeg; // grados, ya canonizado
        _ghost.fadeSpeed = LIGHT_DASH_GHOST_FADE;
        _ghost.depth = depth + 1; // detras del jugador
        _ghost.palleteFrom = global.palleteFrom;
        _ghost.palleteTo = global.palleteTo;
}

// scr_light_dash_exit(): fin del dash. Deja el impulso del ultimo
// tramo en xspd/yspd (y gspd por si termina rozando el suelo) y
// devuelve false: la fisica normal toma el relevo ESTE frame.
function scr_light_dash_exit()
{
        isLightDashing = false;

        xspd = lightDashVX;
        yspd = lightDashVY;
        gspd = lightDashVX;

        // v5.9.4: ultima estela del rayo (con la pose del ultimo tramo):
        // sin esta, el final se quedaba sin fantasma justo en el frame en
        // que el Draw ya no veia el dash activo
        scr_light_dash_ghost(x, y);

        // el angle vuelve a 0 solo en el bloque de aire de scr_move_basic
        return false;
}

// light_dash_turn_to(): (retirada — el lerp ahora vive en el espacio
// del angulo renderizado R, dentro de scr_light_dash_step: ver el
// bloque de pose y su comentario).

// scr_light_dash_find(): construye la cadena de anillos. El primer
// eslabon es el anillo vivo mas cercano dentro del radio de captura
// (en CUALQUIER direccion: asi las columnas verticales se pescan
// llegando por el lateral); a partir de ahi, vecino mas cercano
// encadenado (codicioso). v5.9.3: captura a 96 px y eslabones hasta
// de 80 px — con las lineas/columnas/arcos de los mapas (anillos a
// 24-36 px) sigue el camino exacto, pero ahora tambien engancha
// lineas sueltas o dispersas y UN anillo solo forma cadena (lunge).
function scr_light_dash_find()
{
        var _chain = [];

        // --- primer anillo ---
        var _best = noone;
        var _bestDist = LIGHT_DASH_FIRST_RADIUS;

        with(obj_ring)
        {
                if(used || !visible || image_alpha < 1)
                        continue;

                var _d = point_distance(x, y, other.x, other.y);

                if(_d < _bestDist)
                {
                        _bestDist = _d;
                        _best = id;
                }
        }

        if(_best == noone)
                return _chain;

        array_push(_chain, _best);

        // --- extension de la cadena ---
        while(array_length(_chain) < LIGHT_DASH_MAX_RINGS)
        {
                var _last = _chain[array_length(_chain) - 1];
                var _next = noone;
                var _nextDist = LIGHT_DASH_LINK_DIST;

                with(obj_ring)
                {
                        if(used || !visible || image_alpha < 1)
                                continue;

                        // ya esta en la cadena?
                        var _inChain = false;

                        for(var i = 0; i < array_length(_chain); i++)
                        {
                                if(_chain[i] == id)
                                {
                                        _inChain = true;
                                        break;
                                }
                        }

                        if(_inChain)
                                continue;

                        var _d = point_distance(x, y, _last.x, _last.y);

                        if(_d < _nextDist)
                        {
                                _nextDist = _d;
                                _next = id;
                        }
                }

                if(_next == noone)
                        break;

                array_push(_chain, _next);
        }

        return _chain;
}
