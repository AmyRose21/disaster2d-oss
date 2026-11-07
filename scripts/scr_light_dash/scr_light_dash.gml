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
//
// v5.9.5 — PATHFINDING DEL RAYO (cadena consciente del terreno): la cadena
//  codiciosa de v5.9.3 no veia el mapa y armaba lineas que cruzaban el
//  piso o un muro (anillo en el suelo, anillo al otro lado de la pared):
//  el vuelo REAPLICA la posicion por encima del collision
//  (scr_light_dash_pose), asi que Amy atravesaba el terreno y quedaba
//  ATASCADA dentro o del otro lado. Solucion: un anillo solo encadena si
//  el tramo hasta el esta LIMPIO de terreno (linea de vision con
//  collision_line contra LIGHT_DASH_TERRAIN, el padre universal de
//  pisos/muros/pendientes/puertas/plataformas). Es el pathfinding
//  natural de esta mecanica: en el Sonic clasico el diseñador coloca los
//  anillos por caminos limpios; aqui se exige en codigo. La FLECHA usa
//  la misma cadena, asi que lo que ves sigue siendo lo que vuela:
//  anillo tras muro = sin flecha = sin rayo — PERO si ese anillo tiene
//  otros anillos visibles que rodean el obstaculo, la cadena los sigue
//  ALREDEDOR y llega hasta el: «si hay una pared, buscar el angulo
//  posible para rodear y llegar» es el comportamiento emergente del
//  encadenado visible (ver scr_light_dash_find). Los tramos se prueban
//  con LIGHT_DASH_LOS_TRIM px de margen en cada extremo para no castigar
//  a los anillos que APOYAN sobre una superficie (el lunge de recogida de
//  un anillo caido sigue funcionando: vuela hasta el, lo recoge y
//  aterriza). Y si un hijo MOVIL del terreno (una puerta, un bloque de
//  hielo) cierra sobre el rayo a mitad de vuelo, NO hay rescate propio:
//  el juego ya tiene su sistema anti-atasco que saca al jugador de
//  dentro del solido, y ese sistema la rescata igual que a cualquiera.
//
// v5.10 — PATHFINDING A* REAL (el rodeo de verdad): la linea de vision
//  de v5.9.5 sabia que habia una pared en medio, pero si NINGUN anillo
//  tenia tramo limpio la cadena simplemente moria — y en TD los anillos
//  escasean y aparecen bastante separados, asi que "esperar al siguiente
//  anillo visible" casi nunca pasa. Ahora el rayo traza su propia RUTA:
//  cuando el anillo mas cercano no tiene linea de vision pero existe un
//  camino AEREO a su alrededor, el A* NATIVO de GameMaker (mp_grid, con
//  diagonales) calcula la ruta por las celdas libres y un string-pulling
//  (el "Theta* practico": tirar de la cuerda con la misma scr_light_dash
//  _clear) la endereza a tramos con linea de vision real. Esos quiebres
//  entran a la ruta como WAYPOINTS ({x, y} structs) y el vuelo los sigue
//  igual que a los anillos: el rayo PEGA EL RODEO aunque no haya un solo
//  anillo guiandolo. Presupuesto del desvio: LIGHT_DASH_ROUTE_FACTOR por
//  la distancia tope del tramo (si el rodeo es mas largo, se descarta y
//  se prueba el siguiente candidato, como en v5.9.5). Con linea de vision
//  directa NO corre ningun A* — el caso comun queda intacto. La FLECHA
//  apunta al primer tramo de la ruta (recto o el primer giro del desvio)
//  y sigue marcando el anillo objetivo con el halo. Cero paquetes nuevos
//  (la posicion ya viaja resuelta), cero objetos nuevos.
//
// v6.0 — LSA + I-FRAMES + FRENADO + FIXES (la habilidad completa;
//     el DISEÑO del LSA se CORRIGIO en v6.1 — ver su bloque al final):
//  1. LIGHT SPEED ATTACK (tecla C): la misma maquina de vuelo pero
//     DISPARADA A UN OBJETIVO del bando EXE (exe real o esbirro
//     demonizado: el mas cercano a menos de LSA_RANGE, vivo, sin
//     i-frames ni stun previo). El rayo va A POR EL con homing
//     (mientras no se aleje de LSA_PURSUIT: si corre, el eslabon se
//     congela y el golpe no entra — esquivado) y le pega al llegar
//     (stun de 3 s por senal de red: snd_dash con shouldPlay=true al
//     nid del objetivo, la rama del CLIENT_SOUND_EMIT la traduce en SU
//     cliente, cero paquetes nuevos). Mientras vuela lleva isAttacking:
//     cualquier exe que TOQUE el rayo queda aturdido por el sistema de
//     contacto del juego (el mismo de la acometida). La Z NUNCA dispara
//     el LSA (solo anillos). (v6.0 lo lanzaba desde el suelo y la C sin
//     objetivo caia al martillo; v6.1 lo mando al aire y devolvio la
//     C del suelo al martillo: las reglas del usuario.)
//  2. I-FRAMES: durante el vuelo (dash y LSA) es intocable (hurttime
//     siempre > 0) y al SALIR quedan 2 s gratis (LIGHT_DASH_IFRAME_EXIT).
//  3. FRENADO DE EMERGENCIA (X): SOLO el dash de anillos se frena en
//     seco (parada total, sin impulso de salida); el LSA es un ataque
//     comprometido y no se corta. El latch apaga el impulso de tarot
//     de ese mismo toque de X (frenar no es encadenar).
//  4. FIX "pegada al piso" (el pozo de la burbuja de secuestro): el
//     Step_0 de Amy corre scr_collision_basic OTRA VEZ despues del pose
//     del dash, y con isGrounded en true la rama de suelo (y = winner)
//     le pisaba la elevacion cada frame: el dash que tocaba el piso
//     persiguiendo anillos bajos quedaba CONGELADO ahi hasta que el
//     tiempo de paciencia (MAX_TIME) se agotaba. Mismo seguro que la
//     burbuja: isGrounded = false CADA FRAME en el pose.
//  5. FIX rotacion invisible: saltar EN BOLA conserva isSpinning (v5.3
//     del manejo) y el Draw local forzaba angle = 0 con ese flag — el
//     rayo volaba DE LADO hacia los anillos de ARRIBA sin girar. Ahora
//     el dash manda: (isSpinning && !isLightDashing) ? 0 : angle.
//
// v6.1 — CORRECCION DE DISEÑO DEL LSA (las reglas de verdad del
//  usuario, punto por punto):
//  1. EL LSA ES AEREO: la C EN EL AIRE dispara el LSA con dash; la C
//     EN EL SUELO es el MARTILLO de siempre (scr_amy_canon_special).
//     El bloque del LSA vive DENTRO del if(!isGrounded), antes que la
//     Z, para que sus caidas no le roben el turno a nadie.
//  2. CADENA DE ENEMIGOS: "golpea a uno, salta a otro, JAMAS repite
//     objetivos". Cada objetivo alcanzado se marca en lsaHit y el
//     re-plan (scr_lsa_next_leg) engancha el SIGUIENTE enemigo valido
//     mas cercano a menos de LSA_NEXT_DIST; cuando no queda nadie, se
//     lanza por los ANILLOS de la zona (scr_light_dash_chain desde el
//     ultimo objetivo).
//  3. INTERCEPCION POR EL CAMINO: mientras vuela por ANILLOS (o waypoints
//     del desvio), si aparece un enemigo no golpeado a menos de
//     LSA_INTERCEPT, el resto de la ruta se descarta y el rayo se desvia
//     a por el; tras golpearlo, la cadena sigue. En la fase
//     enemigo->enemigo no hay intercepcion: la cadena secuencia sola.
//  4. SIN I-FRAMES COMO OBJETIVO: el enemigo con isHurt (el
//     semitransparente) JAMAS se detecta como objetivo — ni al arrancar,
//     ni en el re-plan, ni en la intercepcion — y si el objetivo gana
//     i-frames a mitad de vuelo, el golpe no entra (esquivado).
// =====================================================================

// --- PARAMETROS AJUSTABLES (60 frames = 1 segundo) -------------------
#macro LIGHT_DASH_SPEED 5         // px/frame del vuelo (v5.9.4: era 16, muy rapida)
#macro LIGHT_DASH_FIRST_RADIUS 220  // radio de captura del PRIMER anillo (v5.9.3: era 56)
#macro LIGHT_DASH_LINK_DIST 275     // dist max entre eslabones (v5.9.3: era 48; no hace falta que esten pegados)
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
// v5.9.5 — PATHFINDING: el terreno que corta la cadena y el margen de los
// tramos. TERRAIN es el padre universal (pisos, muros, pendientes
// obj_majong_slope, puertas obj_hd_door, bloques de hielo, plataformas
// obj_platform_jumptrough): todo lo que scr_collision_basic trata de
// solido cuelga de el. TRIM recorta cada extremo del tramo probado para
// que un anillo APOYADO en el suelo (su centro puede rozar la mascara)
// siga encadenando: el rayo llega AL anillo, no lo atraviesa.
#macro LIGHT_DASH_TERRAIN obj_floor_parent
#macro LIGHT_DASH_LOS_TRIM 8
// v5.10 — PATHFINDING A*: el presupuesto del desvio y el grid.
// ROUTE_FACTOR multiplica la distancia tope del tramo (FIRST_RADIUS al
// arrancar, LINK_DIST al extender): un rodeo mas largo que eso se
// descarta. GRID_CELL es el tamano de celda del mp_grid (16 px: fino
// para rodear muros, barato para el A*); GRID_REFRESH cada cuantos
// frames se reconstruye el grid (puertas y terreno movil se recalifican
// solos).
#macro LIGHT_DASH_ROUTE_FACTOR 1.5
#macro LIGHT_DASH_GRID_CELL 16
#macro LIGHT_DASH_GRID_REFRESH 30
// v6.0 — LSA (LIGHT SPEED ATTACK, tecla C EN EL AIRE desde v6.1): la
// otra cara de la habilidad. RANGE es el alcance de captura del
// objetivo (exe o esbirro demonizado); PURSUIT es hasta donde persigue
// el homing antes de congelar el eslabon (el contrajuego: CORRER);
// HIT_RADIUS es lo cerca que tiene que estar el objetivo del eslabon al
// llegar para que el golpe entre; STUN_TIME son los 3 s de
// aturdimiento; MAX_TIME es el tope de vuelo propio del LSA (la cadena
// de enemigos + los anillos puede ser mas larga que la de un dash
// normal de anillos).
#macro LSA_RANGE 400
#macro LSA_PURSUIT (LSA_RANGE * 1.5)
#macro LSA_HIT_RADIUS 48
#macro LSA_STUN_TIME (60 * 3)
#macro LSA_MAX_TIME 300
// v6.1 — la CADENA de enemigos: NEXT_DIST es el alcance de captura del
// SIGUIENTE objetivo desde la posicion del recien golpeado (la regla
// "golpea a uno, salta a otro"); INTERCEPT es el radio de desvio a
// mitad de vuelo ("si encuentra otro enemigo por el camino que no haya
// sido golpeado, lo golpeara"); MAX_TARGETS es el tope de objetivos por
// vuelo (seguridad: la cadena siempre termina).
#macro LSA_NEXT_DIST LSA_RANGE
#macro LSA_INTERCEPT 140
#macro LSA_MAX_TARGETS 6
// v6.0 — I-FRAMES del rayo: durante el vuelo hurttime se mantiene > 0
// (intocable) y al SALIR quedan 2 segundos gratis (pedido del usuario).
#macro LIGHT_DASH_IFRAME_EXIT (60 * 2)

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
                lightDashAimX = 0;       // v5.10: primer punto de la RUTA (flecha)
                lightDashAimY = 0;
                lightDashAimDir = 0;     // v5.10: direccion del primer tramo
                isLSA = false;           // v6.0: este vuelo es un LSA (C, ataque)
                lightDashBrakeLatch = 0; // v6.0: silencio del impulso de tarot tras frenar
                lsaHit = [];             // v6.1: objetivos ya golpeados (o fallados) en ESTE vuelo — JAMAS se repiten
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
                || y > room_height + 60 || lightDashTime > (isLSA ? LSA_MAX_TIME : LIGHT_DASH_MAX_TIME))
                        return scr_light_dash_exit();

                // (v5.9.5 NOTA: aqui NO hay rescate propio contra terreno
                // movil que cierre sobre el rayo — el juego ya tiene su
                // sistema anti-atasco que saca al jugador de dentro del
                // solido, y ese sistema la rescata igual que a cualquiera.)

                // v6.0 — FRENADO DE EMERGENCIA (X): SOLO el dash de anillos
                // (el de la Z); el LSA es un ataque comprometido y no se
                // corta. Detiene el rayo EN SECO: parada total sin impulso
                // de salida, y los 2 s de i-frames de cualquier salida
                // igualmente (salir es salir). El latch evita que ESTE mismo
                // toque de X encienda el impulso de tarot al frame siguiente.
                if(!isLSA && keyboard_check_pressed(global.KeyB))
                        return scr_light_dash_brake();

                // v6.0 — I-FRAMES del vuelo: mientras vuela es intocable
                // (hurttime siempre > 0 para el guard de scr_player_hurt;
                // el Step la baja 1 y aqui se repone). Al SALIR, el exit
                // deja los 2 segundos completos.
                hurttime = max(hurttime, 2);

                // --- objetivo vivo? (el EXE pudo reventarlo / un aliado
                //     recogerlo: se salta el eslabon y se sigue; los
                //     waypoints del desvio v5.10 nunca mueren) ---
                var _tgt = noone;
                while(lightDashIdx < array_length(lightDashChain))
                {
                        var _r = lightDashChain[lightDashIdx];

                        if(is_struct(_r) || (instance_exists(_r) && !_r.used))
                        {
                                _tgt = _r;
                                break;
                        }

                        lightDashIdx++;
                }

                // v6.0 — LSA homing: el eslabon del objetivo persigue al exe
                // VIVO (es un struct {x, y, exe}); si huye mas alla de
                // LSA_PURSUIT el eslabon se congela en su ultima posicion
                // (el rayo llega tarde y el golpe no entra: esquivado).
                if(_tgt != noone && is_struct(_tgt) && variable_struct_exists(_tgt, "exe"))
                {
                        var _live = _tgt.exe;

                        if(instance_exists(_live) && point_distance(x, y, _live.x, _live.y) < LSA_PURSUIT)
                        {
                                _tgt.x = _live.x;
                                _tgt.y = _live.y;
                        }
                }

                // v6.1 — INTERCEPCION A MITAD DE VUELO (fase de anillos):
                // "luego se lanza por rings; si encuentra otro enemigo por
                // el camino que no haya sido golpeado, lo golpeara". Cuando
                // el eslabon en curso NO es un objetivo (anillos o waypoints
                // del desvio), cada frame se re-escanea un enemigo valido
                // NO golpeado a menos de LSA_INTERCEPT de la posicion
                // actual: si aparece, el resto de la ruta se DESCARTA y el
                // rayo se desvia a por el — tras golpearlo, el re-plan
                // decide (siguiente enemigo o anillos). En la fase
                // enemigo->enemigo NO hay intercepcion: la cadena ya
                // secuencia solita (primero el cercano, sin desviarse a
                // por uno mas lejos). Con i-frames no hay objetivo.
                if(isLSA && _tgt != noone && !(is_struct(_tgt) && variable_struct_exists(_tgt, "exe")) && array_length(lsaHit) < LSA_MAX_TARGETS)
                {
                        var _snap = scr_lsa_find_target_at(x, y, LSA_INTERCEPT, lsaHit, noone);

                        if(_snap != noone)
                        {
                                var _leg = scr_lsa_leg_to(x, y, _snap);

                                if(_leg != noone)
                                {
                                        lightDashChain = _leg;
                                        lightDashIdx = 0;
                                        _tgt = lightDashChain[0];
                                }
                        }
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
                                // (ningun paquete duplicado). v5.10: solo los ANILLOS se
                                // recogen; los waypoints del desvio solo se sobrevuelan.
                                if(!is_struct(_tgt))
                                {
                                        _tgt.used = true;

                                        var _pak = cpacket_tcp(PacketType.CLIENT_RING_COLLECTED);
                                        buffer_write(_pak, buffer_u8, _tgt.iid);
                                        buffer_write(_pak, buffer_u16, _tgt.nid);
                                        send_server_tcp(_pak);
                                }
                                else if(variable_struct_exists(_tgt, "exe"))
                                {
                                        // v6.0/v6.1 — LSA: LLEGADA a un objetivo. El
                                        // golpe (senal de stun + efectos) lo resuelve
                                        // scr_lsa_hit; los waypoints del desvio no
                                        // entran aqui (no tienen "exe"). El objetivo
                                        // queda MARCADO en lsaHit (golpeado o
                                        // esquivado: JAMAS se repite un objetivo en
                                        // este vuelo) y LA CADENA CONTINUA: el
                                        // re-plan engancha el SIGUIENTE enemigo
                                        // valido mas cercano, o los anillos de la
                                        // zona si ya no queda nadie.
                                        scr_lsa_hit(_tgt);

                                        if(instance_exists(_tgt.exe) && array_find_index(lsaHit, _tgt.exe.id) == -1)
                                                array_push(lsaHit, _tgt.exe.id);

                                        var _leg = scr_lsa_next_leg(_tgt.x, _tgt.y);

                                        for(var i = 0; i < array_length(_leg); i++)
                                                array_push(lightDashChain, _leg[i]);
                                }

                                _tgt = noone;
                                while(lightDashIdx < array_length(lightDashChain))
                                {
                                        var _r2 = lightDashChain[lightDashIdx];

                                        if(is_struct(_r2) || (instance_exists(_r2) && !_r2.used))
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

        // ============ GATES COMUNES (Z y LSA, los dos EN EL AIRE) ============
        if(global.character != CHARACTER_AMY_CANON)
                return false;

        // demonizada (revivalTimes >= 2) no puede recoger anillos: el Step
        // del obj_ring se lo impide, la cadena no se tragaria nada (y ya
        // esta en el bando del exe: no puede atacarlo)
        if(revivalTimes >= 2)
                return false;

        if(!global.playerControls)
                return false;

        // viva, sin estados que peleen el cuerpo (las dos mitades viven
        // EN EL AIRE: la Z a por anillos, la C a por enemigos)
        if(isDead || isHurt || shockedTimer > 0 || isZipline)
                return false;

        if(isDashing || isTarotDashing || isHJ || isAttacking)
                return false;

        if(bubbleState == AMY_BUBBLE_ACTIVE || hugActive || parryState > 0 || redRingTimer > 0)
                return false;

        // escondida en un escondite: fuera (igual que la acometida)
        if(isHiding)
                return false;

        // ============ 2. LSA — LIGHT SPEED ATTACK (C, EN EL AIRE) ============
        // v6.1 — LA CORRECCION DE DISEÑO PEDIDA: el LSA VUELA. La C EN EL
        // AIRE con un objetivo del bando EXE a la vista (exe real o
        // esbirro demonizado: el mas cercano a menos de LSA_RANGE, vivo,
        // sin i-frames y sin stun previo — quien tiene i-frames JAMAS es
        // objetivo) dispara el rayo A POR EL con la misma maquina de
        // vuelo del dash. LA CADENA ES LA REGLA DE ORO: golpea a uno,
        // salta a otro, JAMAS repite objetivos (lsaHit); cuando no queda
        // nadie, se lanza por los ANILLOS de la zona; y a mitad de vuelo
        // cualquier enemigo no golpeado que aparezca por el camino
        // (LSA_INTERCEPT) tambien cae. La C EN EL SUELO es el MARTILLO
        // de siempre (scr_amy_canon_special, que corre despues del hook y
        // exige isGrounded): mismo boton, dos caras, mismo CD compartido
        // (dashTimer, el del icono 3 del HUD). El bloque va PRIMERO
        // dentro del aire: sus caidas (sin objetivo / sin CD / objetivo
        // inalcanzable) no le roban el turno a la Z.
        if(!isGrounded)
        {
                if(keyboard_check_pressed(global.KeyC) && dashTimer <= 0)
                {
                        lsaHit = [];       // vuelo NUEVO: la banda de la cadena nace limpia

                        var _exe = scr_lsa_find_target();

                        if(_exe != noone)
                        {
                                // ruta hasta el primer objetivo: RECTA con linea de
                                // vision, o RODEO A* (waypoints, el mismo pathfinding
                                // del dash) si hay un muro en medio
                                var _lsaChain = scr_lsa_leg_to(x, y, _exe);

                                if(_lsaChain != noone)
                                {
                                        // --- arrancar (mismo ritual del dash de la Z) ---
                                        isLightDashing = true;
                                        isLSA = true;
                                        isAttacking = true; // el exe que TOQUE el rayo queda aturdido (sistema de contacto del juego, bit PLAYER_ATTACKING)
                                        isTarotFloat = false;
                                        isJumping = false;
                                        isGrounded = false; // BUGFIX burbuja: despega de verdad
                                        image_index = 0;

                                        lightDashChain = _lsaChain;
                                        lightDashIdx = 0;
                                        lightDashTime = 0;
                                        lightDashDeg = radtodeg(angle); // parte de la pose actual (0 en el aire)
                                        lightDashFace = image_xscale >= 0 ? 1 : -1;
                                        lightDashToX = x;
                                        lightDashToY = y;

                                        // velocidad PRE-FIJADA hacia el primer punto de la
                                        // ruta (ritual del lunge de v5.9.3)
                                        var _d0 = point_direction(x, y, _lsaChain[0].x, _lsaChain[0].y);
                                        lightDashVX = lengthdir_x(LIGHT_DASH_SPEED, _d0);
                                        lightDashVY = lengthdir_y(LIGHT_DASH_SPEED, _d0);

                                        lightDashGhostTimer = 0;
                                        scr_light_dash_ghost(x, y);

                                        // CD COMPARTIDO con la acometida de martillo (el que
                                        // muestra el icono 3 del HUD de Amy)
                                        dashTimer = revivalTimes >= 2 ? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE;

                                        audio_play_sound(snd_dash, 0, false);
                                        net_sound_emit(snd_dash);

                                        // el vuelo real empieza el frame siguiente
                                        return true;
                                }
                        }
                }

        // ================= 3. FLECHA + ACTIVACION (Z, SOLO EN EL AIRE) =================
        // v6.1 — la Z sigue AEREA, ahora DETRAS del LSA dentro del mismo
        // bloque del aire: sus return false tempranos ya no le roban el
        // turno a nadie (la C ya se proceso arriba en su propio gate, y
        // en el suelo este hook no activa nada: ahi manda el martillo).
                // v5.9.2 — ESCANEO CONTINUO (la flecha): la cadena se busca SIEMPRE
                // que un toque podria arrancar el rayo, no solo en el frame del
                // toque. Con eso Draw_0 pinta la flecha sobre el primer anillo y el
                // jugador sabe que hace Z ANTES de tocarla: flecha visible = Z
                // tocada = rayo; sin flecha = Z mantenida = flotacion del tarot.
                // Flotando (isTarotFloat) la flecha TAMBIEN sale: soltar y volver a
                // tocar SI arranca el rayo desde la flotacion, y el jugador tiene
                // que verlo. Misma cadena para la flecha y para el arranque: lo que
                // ves es lo que vuela.
                var _route = scr_light_dash_find();

                // la FLECHA solo marca ANILLOS (los waypoints no llevan halo);
                // el vuelo se come la ruta completa
                lightDashAim = [];

                for(var i = 0; i < array_length(_route); i++)
                {
                        if(!is_struct(_route[i]))
                                array_push(lightDashAim, _route[i]);
                }

                // flecha: el PRIMER PUNTO de la ruta (anillo en vuelo recto, o el
                // primer quiebre del desvio A*) y la direccion del primer tramo —
                // con rodeo apunta hacia donde sale el rayo, no hacia la pared
                if(array_length(_route) > 0)
                {
                        lightDashAimX = _route[0].x;
                        lightDashAimY = _route[0].y;
                        lightDashAimDir = point_direction(x, y, _route[0].x, _route[0].y);
                }

                lightDashAimLife = 2; // la gasta el Draw (1 frame de vida + colchon)

                // v5.9.3 — UN anillo BASTA: el dash funciona tambien como lunge
                // de recogida hacia un anillo suelto (recoge y sale disparada
                // hacia el). Con cadena vacia (nada a <= 96 px) no hay nada que
                // hacer. La flecha del Draw tambien sale con 1 solo anillo.
                if(array_length(_route) < 1)
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
                isLSA = false;      // v6.0: el dash de la Z NUNCA es un LSA
                isTarotFloat = false;
                isJumping = false;
                isGrounded = false;
                image_index = 0;

                lightDashChain = _route;
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
                var _d0 = point_direction(x, y, _route[0].x, _route[0].y);
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

        // En el SUELO este hook no activa nada con la C: el MARTILLO
        // (acometida) vive en scr_amy_canon_special, que corre despues
        // del hook en scr_move_basic y exige isGrounded (v6.1: mismo
        // boton, dos caras de la misma habilidad).
        return false;
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

        // v6.0 — BUGFIX "pegada al piso" (el pozo de la burbuja de
        // secuestro): el Step_0 de Amy corre scr_collision_basic OTRA VEZ
        // despues de este pose, y con isGrounded en true su rama de suelo
        // (y = winner) le pisaba la elevacion cada frame: el dash que
        // tocaba el piso persiguiendo anillos bajos quedaba CONGELADO ahi
        // sin avanzar hasta agotar la paciencia del MAX_TIME. El seguro
        // de la burbuja (isGrounded = false) aplicado CADA FRAME: la rama
        // aerea solo aterriza cayendo de verdad (yspd > 0), nunca clava.
        isGrounded = false;

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
        isLSA = false;         // v6.0: reset del modo (dash puro la proxima)
        isAttacking = false;   // v6.0: el contacto-stun del vuelo muere con el vuelo

        // v6.0 — 2 SEGUNDOS de i-frames GRATIS al salir (pedido del
        // usuario): da igual como termino (cadena agotada, cancelacion,
        // tope de tiempo) — la salida siempre deja el colchon. Se ve con
        // el semitransparente de siempre (alpha 0.5 del hurttime).
        hurttime = LIGHT_DASH_IFRAME_EXIT;

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

// scr_light_dash_brake(): v6.0 — FRENADO DE EMERGENCIA del dash (tecla X
// en pleno vuelo). Salida EN SECO: sin el impulso del ultimo tramo
// (parada total, la gravedad toma el relevo y cae), con los 2 s de
// i-frames de cualquier salida y la ultima estela. El latch de 2 frames
// apaga el impulso de tarot (que ESTE mismo toque de X no lo encienda
// un frame despues: frenar no es encadenar — ver scr_amy_canon_special).
function scr_light_dash_brake()
{
        isLightDashing = false;
        isLSA = false;
        isAttacking = false;

        xspd = 0;
        yspd = 0;
        gspd = 0;

        hurttime = LIGHT_DASH_IFRAME_EXIT;
        lightDashBrakeLatch = 2;

        scr_light_dash_ghost(x, y);

        audio_play_sound(snd_snap, 0, false);
        net_sound_emit(snd_snap);

        return false;
}

// light_dash_turn_to(): (retirada — el lerp ahora vive en el espacio
// del angulo renderizado R, dentro de scr_light_dash_step: ver el
// bloque de pose y su comentario).

// scr_light_dash_clear(): true si el tramo (x1,y1)->(x2,y2) se puede
// volar sin atravesar terreno — la LINEA DE VISION del pathfinding del
// rayo (v5.9.5). collision_line contra LIGHT_DASH_TERRAIN con colision
// precisa (las pendientes obj_majong_slope son mascaras diagonales). Los
// extremos se recortan LIGHT_DASH_LOS_TRIM px: un anillo APOYADO en el
// suelo tiene el centro rozando la mascara del piso y Amy despegandose de
// un muro puede arrancar a 2 px de la cara — el rayo llega AL anillo, no
// lo atraviesa, y esos pixeles finales no deben condenar el tramo. Un
// muro de verdad (mas de 2*TRIM px de terreno en medio) SI corta.
function scr_light_dash_clear(x1, y1, x2, y2)
{
        var _d = point_distance(x1, y1, x2, y2);

        if(_d <= LIGHT_DASH_LOS_TRIM * 2)
                return true; // tramo cortisimo: no cabe un muro en medio

        var _nx = (x2 - x1) / _d;
        var _ny = (y2 - y1) / _d;

        return !collision_line(x1 + _nx * LIGHT_DASH_LOS_TRIM,
                               y1 + _ny * LIGHT_DASH_LOS_TRIM,
                               x2 - _nx * LIGHT_DASH_LOS_TRIM,
                               y2 - _ny * LIGHT_DASH_LOS_TRIM,
                               LIGHT_DASH_TERRAIN, true, true);
}

// scr_light_dash_grid(): el mp_grid del rayo (cacheado en globals). Se
// reconstruye cada LIGHT_DASH_GRID_REFRESH frames o al cambiar de sala:
// las puertas y el terreno movil se recalifican solos. Celdas de
// LIGHT_DASH_GRID_CELL px; bloquea todo lo que cuelga de
// LIGHT_DASH_TERRAIN (el padre universal) con mp_grid_add_instances
// (precise: las pendientes son mascaras diagonales). El path para
// mp_grid_path tambien se cachea (global.__ldPath). Devuelve el id del
// grid o -1 si no se pudo crear.
function scr_light_dash_grid()
{
        if(!variable_global_exists("__ldGrid"))
        {
                global.__ldGrid = -1;
                global.__ldGridRoom = -4;
                global.__ldGridTimer = 0;
                global.__ldPath = path_add();
        }

        global.__ldGridTimer--;

        if(global.__ldGridTimer <= 0 || global.__ldGridRoom != room)
        {
                if(global.__ldGrid != -1)
                        mp_grid_destroy(global.__ldGrid);

                var _cw = LIGHT_DASH_GRID_CELL;
                var _hw = max(1, room_width div _cw);
                var _hh = max(1, room_height div _cw);

                global.__ldGrid = mp_grid_create(0, 0, _hw, _hh, _cw, _cw);

                mp_grid_add_instances(global.__ldGrid, LIGHT_DASH_TERRAIN, true);

                global.__ldGridRoom = room;
                global.__ldGridTimer = LIGHT_DASH_GRID_REFRESH;
        }

        return global.__ldGrid;
}

// scr_light_dash_route(): el PATHFINDING A* del rayo (v5.10). Traza una
// ruta AEREA de (x1,y1) a (x2,y2) por las celdas libres del mp_grid
// (mp_grid_path: el A* nativo de GameMaker, con diagonales) y la
// ENDEREZA con string pulling — tirar de la cuerda con la misma
// scr_light_dash_clear (el "Theta* practico"): solo sobreviven los
// quiebres con linea de vision REAL. Devuelve los PUNTOS DE QUIEBRE
// (sin el inicio y sin la meta, que el llamador anade como anillo) o
// [] si no hay camino o el recorrido completo se pasa de maxLen (el
// presupuesto del desvio). El A* corre por CENTROS de celda: la celda
// de salida y la de meta se desbloquean un momento (Amy pegada a un
// muro / anillo apoyado en el suelo no deben ahogar el A*) y se vuelven
// a bloquear despues, para no dejar agujeros en el mapa.
function scr_light_dash_route(x1, y1, x2, y2, maxLen)
{
        var _grid = scr_light_dash_grid();

        if(_grid == -1)
                return [];

        var _path = global.__ldPath;
        var _cw = LIGHT_DASH_GRID_CELL;
        var _hw = max(1, room_width div _cw);
        var _hh = max(1, room_height div _cw);

        // coordenadas dentro del grid
        var _x1 = clamp(x1, 0, _hw * _cw - 1);
        var _y1 = clamp(y1, 0, _hh * _cw - 1);
        var _x2 = clamp(x2, 0, _hw * _cw - 1);
        var _y2 = clamp(y2, 0, _hh * _cw - 1);

        // desbloquear salida y meta un momento — y re-bloquear despues
        // SOLO las que de verdad tienen terreno (collision_rectangle sobre
        // la celda: misma semantica que mp_grid_add_instances). Re-bloquear
        // a ciegas dejaria celdas FANTASMA en el aire libre cada vez que
        // Amy o un anillo estan en sitio despejado, y el grid se llenaria
        // de muros inexistentes hasta el proximo refresh.
        var _c1h = _x1 div _cw;
        var _c1v = _y1 div _cw;
        var _c2h = _x2 div _cw;
        var _c2v = _y2 div _cw;
        var _b1 = collision_rectangle(_c1h * _cw, _c1v * _cw, (_c1h + 1) * _cw - 1, (_c1v + 1) * _cw - 1, LIGHT_DASH_TERRAIN, true, true);
        var _b2 = collision_rectangle(_c2h * _cw, _c2v * _cw, (_c2h + 1) * _cw - 1, (_c2v + 1) * _cw - 1, LIGHT_DASH_TERRAIN, true, true);

        mp_grid_clear_cell(_grid, _c1h, _c1v);
        mp_grid_clear_cell(_grid, _c2h, _c2v);

        var _ok = mp_grid_path(_grid, _path, _x1, _y1, _x2, _y2, true);

        if(_b1)
                mp_grid_add_cell(_grid, _c1h, _c1v);

        if(_b2)
                mp_grid_add_cell(_grid, _c2h, _c2v);

        if(!_ok)
                return [];

        // --- string pulling: puntos del path (centros de celda) + la META
        //     REAL al final; de la cuerda quedan solo los quiebres con
        //     linea de vision (cada tramo conservado pasa clear) ---
        var _n = path_get_number(_path);

        if(_n <= 0)
                return [];

        var _pts = [];
        var _ax = _x1;
        var _ay = _y1;
        var _i = 0;

        while(_i <= _n)
        {
                var _far = _i;

                for(var _j = _n; _j >= _i; _j--)
                {
                        var _qx = (_j == _n) ? _x2 : path_get_point_x(_path, _j);
                        var _qy = (_j == _n) ? _y2 : path_get_point_y(_path, _j);

                        if(scr_light_dash_clear(_ax, _ay, _qx, _qy))
                        {
                                _far = _j;
                                break;
                        }
                }

                var _lx = (_far == _n) ? _x2 : path_get_point_x(_path, _far);
                var _ly = (_far == _n) ? _y2 : path_get_point_y(_path, _far);

                array_push(_pts, [_lx, _ly]);

                _ax = _lx;
                _ay = _ly;
                _i = _far + 1;
        }

        // presupuesto: el recorrido completo hasta la meta real
        var _len = point_distance(_x1, _y1, _pts[0][0], _pts[0][1]);

        for(var i = 1; i < array_length(_pts); i++)
                _len += point_distance(_pts[i - 1][0], _pts[i - 1][1], _pts[i][0], _pts[i][1]);

        if(_len > maxLen)
                return [];

        // devolver los QUIEBRES: todo menos la meta (el llamador la anade
        // como anillo al final de la ruta)
        array_delete(_pts, array_length(_pts) - 1, 1);

        return _pts;
}

// scr_light_dash_find(): construye la RUTA del rayo (v5.10: anillos +
// waypoints de desvio). El primer eslabon es el anillo vivo mas cercano
// dentro del radio de captura; a partir de ahi, vecino mas cercano
// encadenado (codicioso), con los topes de siempre (FIRST_RADIUS al
// arrancar, LINK_DIST al extender, MAX_RINGS de tope). v5.9.5: cada
// candidato exige linea de vision limpia (scr_light_dash_clear).
// v5.10 — PATHFINDING A*: cuando el candidato mas cercano NO tiene
// linea de vision pero existe un camino AEREO a su alrededor, el A*
// nativo (mp_grid) traza el rodeo y el string pulling lo deja en
// quiebres con linea de vision real: esos quiebres entran a la ruta
// como WAYPOINTS ({x, y} structs) y el vuelo los sigue igual que a los
// anillos — el rayo RODEA la pared aunque ningun anillo lo guie, con
// un presupuesto de LIGHT_DASH_ROUTE_FACTOR x la distancia tope (si el
// rodeo es mas largo, el candidato se descarta y se prueba el
// siguiente). Con linea de vision directa no corre NINGUN A*: el caso
// comun queda exactamente como v5.9.5. Devuelve la RUTA completa
// (waypoints + anillos en orden de vuelo); scr_light_dash_step filtra
// los anillos para la FLECHA.
// scr_light_dash_find(): la ruta del dash de la Z — la cadena de
// anillos + waypoints que cuelga del punto donde esta Amy. v6.0: quedó
// como envoltorio del buscador generico scr_light_dash_chain, que el
// LSA reutiliza para encadenar anillos DESDE la posicion del objetivo.
function scr_light_dash_find()
{
        return scr_light_dash_chain(x, y, LIGHT_DASH_FIRST_RADIUS);
}

// scr_light_dash_chain(): el buscador de la cadena (v5.10) generalizado
// en v6.0: anillos + waypoints de desvio colgando de (_fromX, _fromY),
// con _firstReach de captura para el PRIMER eslabon (FIRST_RADIUS para
// el dash de la Z; LINK_DIST para la extension del LSA desde el exe).
function scr_light_dash_chain(_fromX, _fromY, _firstReach)
{
        var _route = [];  // lo que vuela: waypoints (structs) + anillos
        var _chain = [];  // solo anillos (membresia / flecha)
        var _px = _fromX; // punto actual de la ruta (arranca donde pidan)
        var _py = _fromY;

        while(array_length(_chain) < LIGHT_DASH_MAX_RINGS)
        {
                // alcance del tramo: captura del primer eslabon, tolerancia
                // de eslabon al extender
                var _reach = (array_length(_chain) == 0) ? _firstReach : LIGHT_DASH_LINK_DIST;

                // candidatos del tramo (vivos, fuera de la cadena y a
                // menos de _reach del punto actual), con su distancia
                var _cand = [];

                with(obj_ring)
                {
                        if(used || !visible || image_alpha < 1)
                                continue;

                        // v5.10: higiene de candidatos — un anillo ENTERRADO
                        // (centro dentro del terreno) no lo recoge nadie y el
                        // A* no debe zambullirse a buscarlo
                        if(collision_point(x, y, LIGHT_DASH_TERRAIN, true, true))
                                continue;

                        var _in = false;

                        for(var i = 0; i < array_length(_chain); i++)
                        {
                                if(_chain[i] == id)
                                {
                                        _in = true;
                                        break;
                                }
                        }

                        if(_in)
                                continue;

                        var _d = point_distance(x, y, _px, _py);

                        if(_d < _reach)
                                array_push(_cand, [_d, id]);
                }

                if(array_length(_cand) == 0)
                        break;

                // 1) el mas cercano con linea de vision (caso normal:
                //    cero A*, mismo comportamiento que v5.9.5)
                var _next = noone;
                var _nextD = _reach + 1;

                for(var i = 0; i < array_length(_cand); i++)
                {
                        var _r = _cand[i][1];

                        if(_cand[i][0] >= _nextD)
                                continue;

                        if(scr_light_dash_clear(_px, _py, _r.x, _r.y))
                        {
                                _nextD = _cand[i][0];
                                _next = _r;
                        }
                }

                // 2) nadie visible: el mas cercano RUTABLE por A* — el
                //    rodeo de "buscar el angulo posible para llegar"
                var _wps = [];

                if(_next == noone)
                {
                        var _pool = _cand;

                        while(array_length(_pool) > 0 && _next == noone)
                        {
                                // extraer el candidato mas cercano
                                var _mi = 0;

                                for(var i = 1; i < array_length(_pool); i++)
                                        if(_pool[i][0] < _pool[_mi][0])
                                                _mi = i;

                                var _r2 = _pool[_mi][1];

                                array_delete(_pool, _mi, 1);

                                _wps = scr_light_dash_route(_px, _py, _r2.x, _r2.y,
                                        _reach * LIGHT_DASH_ROUTE_FACTOR);

                                if(array_length(_wps) > 0)
                                        _next = _r2;
                        }
                }

                if(_next == noone)
                        break; // ni recto ni rodeando: la ruta termina aqui

                // los quiebres del rodeo primero, luego el anillo
                for(var i = 0; i < array_length(_wps); i++)
                        array_push(_route, {x: _wps[i][0], y: _wps[i][1]});

                array_push(_route, _next);
                array_push(_chain, _next);

                _px = _next.x;
                _py = _next.y;
        }

        return _route;
}

// =====================================================================
//  v6.0/v6.1 — LSA (LIGHT SPEED ATTACK): la mitad AEREA de la habilidad
//  (tecla C EN EL AIRE). Busqueda del objetivo, la CADENA de enemigos
//  (golpea uno, salta a otro, jamas repite), el tramo hasta cada uno y
//  la senal de stun.
// =====================================================================

// scr_lsa_find_target_at(): el buscador de objetivos GENERALIZADO (v6.1)
// — el jugador del bando EXE (exe real o esbirro demonizado) mas cercano
// a (_fx, _fy) a menos de _maxD, vivo, sin i-frames, sin stun previo y
// visible, EXCLUYENDO a los ya golpeados en este vuelo (_hitList: la
// regla "JAMAS repite objetivos") y al que ya persigue el eslabon en
// curso (_skipExe: la intercepcion no se desvia hacia su propio
// destino). Mismos filtros que la deteccion de Chocola (la convencion
// del juego para "objetivo atacable del bando del exe"). Devuelve el
// puppet o noone.
function scr_lsa_find_target_at(_fx, _fy, _maxD, _hitList, _skipExe)
{
        var _best = noone;
        var _bestD = _maxD;

        if(!instance_exists(obj_player_puppet))
                return noone;

        with(obj_player_puppet)
        {
                if(isInactive || !visible)
                        continue;

                if(isHurt)          // i-frames: no se le pega al transparente
                        continue;

                if(state == DEAD)   // ya stuneado / fuera de combate
                        continue;

                if(character != CHARACTER_EXE && !isDemonized)
                        continue;   // solo el bando del exe

                if(_skipExe != noone && id == _skipExe)
                        continue;   // el que ya persigue este eslabon

                if(array_find_index(_hitList, id) != -1)
                        continue;   // JAMAS se repite un objetivo

                var _d = point_distance(x, y, _fx, _fy);

                if(_d < _bestD)
                {
                        _bestD = _d;
                        _best = id;
                }
        }

        return _best;
}

// scr_lsa_find_target(): el PRIMER objetivo del LSA, desde Amy y a
// alcance LSA_RANGE (v6.1: envoltorio fino del buscador general — el
// vuelo todavia no ha golpeado a nadie, la banda va vacia).
function scr_lsa_find_target()
{
        return scr_lsa_find_target_at(x, y, LSA_RANGE, lsaHit, noone);
}

// scr_lsa_leg_to(): el TRAMO del LSA hasta un objetivo (v6.1): RECTA si
// hay linea de vision (scr_light_dash_clear) o RODEO A* con waypoints
// (el mismo pathfinding del dash) si hay un muro en medio, + el ESLABON
// del objetivo (struct VIVO {x, y, exe}: persigue al exe durante el
// vuelo con el homing y el golpe lo aplica scr_lsa_hit al llegar).
// Devuelve el array del tramo (waypoints + eslabon) o noone si el
// objetivo es inalcanzable por el terreno.
function scr_lsa_leg_to(_fx, _fy, _exe)
{
        if(!instance_exists(_exe))
                return noone;

        var _wps = [];
        var _direct = scr_light_dash_clear(_fx, _fy, _exe.x, _exe.y);

        if(!_direct)
                _wps = scr_light_dash_route(_fx, _fy, _exe.x, _exe.y, LSA_RANGE * LIGHT_DASH_ROUTE_FACTOR);

        if(!_direct && array_length(_wps) == 0)
                return noone; // ni recto ni rodeando: inalcanzable

        var _leg = [];

        for(var i = 0; i < array_length(_wps); i++)
                array_push(_leg, {x: _wps[i][0], y: _wps[i][1]});

        array_push(_leg, {x: _exe.x, y: _exe.y, exe: _exe});

        return _leg;
}

// scr_lsa_next_leg(): LA CADENA de enemigos del LSA (v6.1) — la regla de
// oro del usuario: "golpea a uno, salta a otro, JAMAS repite objetivos,
// y luego se lanza por rings". Desde la posicion (_fx, _fy) del objetivo
// recien golpeado: 1) el SIGUIENTE enemigo valido mas cercano a menos
// de LSA_NEXT_DIST que NO este en lsaHit (sin i-frames, sin stun, del
// bando del exe); 2) si no queda nadie (o el siguiente es inalcanzable
// por el terreno), LOS ANILLOS de la zona (scr_light_dash_chain, el
// mismo buscador del dash de la Z). El tope LSA_MAX_TARGETS corta la
// cadena solo: el vuelo siempre termina.
function scr_lsa_next_leg(_fx, _fy)
{
        if(array_length(lsaHit) < LSA_MAX_TARGETS)
        {
                var _exe = scr_lsa_find_target_at(_fx, _fy, LSA_NEXT_DIST, lsaHit, noone);

                if(_exe != noone)
                {
                        var _leg = scr_lsa_leg_to(_fx, _fy, _exe);

                        if(_leg != noone)
                                return _leg;

                        // inalcanzable (muro cerrado): no bloquea los anillos
                }
        }

        return scr_light_dash_chain(_fx, _fy, LIGHT_DASH_LINK_DIST);
}

// scr_lsa_hit(): el golpe del LSA al LLEGAR al eslabon del objetivo (lo
// llama el vuelo en el bloque 1). El stun viaja como SENAL dirigida al
// nid del objetivo (net_sound_emit_at de snd_dash con shouldPlay=true:
// el mismo canal de senales del parry y de Chocola) y SU CLIENTE se
// aturde a si mismo con scr_lsa_stun_signal — el modelo de confianza del
// juego, cero paquetes nuevos. Si el objetivo corrio mas alla del
// eslabon congelado (esquivo el rayo huyendo), no hay golpe; y si gano
// I-FRAMES a mitad de vuelo, tampoco (v6.1: al transparente no se le
// pega). Efectos locales del impacto: particula + shake de camara (el
// sonido canonico lo emite el propio stun del receptor y llega en 3D
// para todos).
function scr_lsa_hit(_slot)
{
        var _exe = _slot.exe;

        if(!instance_exists(_exe))
                return;

        if(point_distance(_slot.x, _slot.y, _exe.x, _exe.y) > LSA_HIT_RADIUS)
                return; // esquivo: el eslabon quedo congelado lejos del exe

        if(_exe.isHurt)
                return; // v6.1: gano i-frames a mitad de vuelo — el golpe no entra (esquivado)

        net_quick_effect(_exe.x, _exe.y, spr_shockparticle, false, 1, 0, 0, 1);
        scr_camera_shake(20, 2, 0.2);

        // LA SENAL: snd_dash posicionado EN el nid del objetivo — la rama
        // shouldPlay del CLIENT_SOUND_EMIT (net_state_game) la traduce a
        // scr_lsa_stun_signal en SU cliente. El snd_dash BROADCAST del
        // arranque (shouldPlay=false) nunca entra por esa rama.
        net_sound_emit_at(snd_dash, _exe.master_id);
}

// scr_lsa_stun_signal(): la SENAL del golpe del LSA (la rama shouldPlay
// del CLIENT_SOUND_EMIT la llama EN EL CLIENTE DEL OBJETIVO, igual que
// scr_chocola_stun_signal con el stun de Chocola). Duracion
// LSA_STUN_TIME. El receptor se aturde a si mismo: golpe canonico +
// grito SIEMPRE (antes del dedup — la leccion v2.1.4 de Chocola: nunca
// pegar en silencio), y stun/knockback/paquetes solo si no estaba ya
// stuneado por otra fuente.
function scr_lsa_stun_signal()
{
        if(!instance_exists(global.player))
                return;

        var _exe = global.character == CHARACTER_EXE;
        var _esbirro = !_exe && global.player.revivalTimes >= 2 && !global.player.isDead;

        if(!_exe && !_esbirro)
                return;

        // golpe canonico + grito, SIEMPRE
        audio_play_sound(snd_exe_stun, 0, false);
        net_sound_emit(snd_exe_stun);

        if(_exe)
                scr_exe_stunsound();
        else
        {
                net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
                scr_camera_shake(30, 2, 0.25);
        }

        // dedup: ya stuneado por otra fuente — suena, pero no se re-aplica
        if(global.player.shockedTimer > 0)
                return;

        with(global.player)
        {
                isAttacking = false;
                hurttime = 0;
                shockedTimer = LSA_STUN_TIME;
                xspd = 0;
                yspd = -2;
                isGrounded = false;
        }

        // camara del golpeado + estadisticas (el mismo paquete que usan el
        // parry y el stun de Chocola)
        var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
        buffer_write(_buffer, buffer_u16, obj_netclient.nid);
        buffer_write(_buffer, buffer_u16, floor(global.player.x));
        buffer_write(_buffer, buffer_u16, floor(global.player.y));
        buffer_write(_buffer, buffer_u16, LSA_STUN_TIME div 60);
        send_server_tcp(_buffer);
}
