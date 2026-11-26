/// scr_parry — PARRY DE SONIC (tecla C) Y AMY CANON (tecla V)
// =====================================================================
//  v90 (QoL SONIC: «arreglos a su parry y mejora de estabilidad y
//  fortalezas», pedido de la duena). ARREGLOS DE ESTABILIDAD:
//   (1) DETECCION LASER-VS-ALIADO: leia el bbox por el INDICE del
//       objeto (obj_tails_projectile.bbox_*) en vez de la instancia
//       del laser concreto (other): con 2+ lasers en vuelo podia
//       mirar el que NO estaba tocando al aliado -> no se pedia el
//       desvio y el laser seguia volando. Regla de la casa v88: nada
//       de depender de la semantica del indice de objeto.
//   (2) ARGUMENTOS DE audio_play_sound invertidos en el "ting"
//       (snd, false, 0 -> snd, 0, false; funcionaba de casualidad).
//   (3) DEMONIZADOS: el gate de input no miraba revivalTimes — un
//       Sonic esbirro (o nega) podia abrir la "ventana": su estado 61
//       dibujaba en las demas maquinas el circulo del aura (que NO
//       protege a nadie: los checks filtran isDemonized) = aura FALSA
//       que enganaba a los aliados. Ahora los demonizados no abren el
//       parry y la conversion lo cierra al instante (ademas el Draw_0
//       del puppet filtra isDemonized por si llega un estado viejo).
//   (4) REBOTE DE LA BOLA: un contacto spin del bando EXE con damage 0
//       (el rebote snd_buble de los bloques de contacto de los
//       supervivientes) aplicaba isGrounded=false AUN CON LA VENTANA
//       ABIERTA, y al frame siguiente el parry se cerraba con el CD
//       de FALLO entero — aunque scr_parry_detect ya considera ataque
//       el JUMP/SPIN del bando EXE. La negacion (scr_player_hurt) sube
//       de sitio: se evalua ANTES del guard de hurttime y cubre TAMBIEN
//       el rebote (exeSource + snd_buble): con la ventana abierta ni
//       dano ni empujon, y el atacante recibe el stun por la senal de
//       siempre. De paso la cobertura con i-frames queda consistente
//       (el ting/stun ya existian por la via del atacante, v3.4).
//   (5) BUFFER DE ATERRIZAJE: el parry es SOLO en tierra y un tap de
//       C/V un poco antes de tocar suelo se perdia entero (y el golpe
//       llegaba justo al aterrizar). Ahora el tap en el aire se guarda
//       SONIC_PARRY_LAND_BUFFER frames y el parry arranca al pisar
//       suelo con el gate completo re-evaluado. Pura QoL local: cero
//       paquetes.
//  FORTALEZAS (los 4 numeros, ajustados con comentario en cada macro):
//   gracia 4 -> 6 frames (mas tolerancia a la latencia), aura 58 ->
//   64 px (mas cobertura de aliados), stun del atacante 3,5 -> 4 s
//   (LMS: 6 s) y CD de fallo 14 -> 12 s.
//  v4.2: SONIDO PERFECT_PARRY EN EL EXITO (pedido del usuario): el
//        parry exitoso suena Perfect_Parry en la pantalla del que
//        parrea, para TODO: melee, LASER devueltos y anillos negros
//        (antes los proyectiles no sonaban NADA al devolverlos, otra
//        queja del usuario: cubierto porque TODO pasa por
//        scr_parry_success_now). Es local a proposito: los demas
//        clientes ya oyen el "ting" (snd_parry) por la red de siempre
//        y no se toca el enum de sonidos de red (cero cambios server).
//        ANIMACION DE AMY COMPLETA: su spr_amy_parry_exitoso tiene 10
//        frames (vs 3 el de Sonic) y se comprimia en 22 frames
//        (SONIC_PARRY_EXITO_TIME) viendose cortada; ahora cada
//        personaje dura lo que pide su sprite
//        (scr_parry_exito_time) y el puppet lo refleja solo porque el
//        image_index ya viaja por la red de siempre.
//  v4.0: AMY CANON TIENE SU PROPIO PARRY (mismas fijaciones que el de
//        Sonic: ventana, aura de aliados, cooldowns, stun del atacante,
//        desvio de proyectiles y estados de red 60/61/64 — viajan igual
//        porque el byte `state` es por-jugador y Amy nunca uso el 60+).
//        Tecla V (nueva global.KeyV, remapeable como "special3"),
//        gamepad gp_face4 (Y) y boton tactil nuevo en Android.
//        Sus sprites: spr_amy_parry_inicio / spr_amy_parry_exitoso
//        (los subio el usuario al repo). Aura ROSA en vez de cian.
//        El HUD es el 4o icono de su fila (y=276) con el CD igual que
//        Sonic (parryCooldownMax). La burbuja de secuestro congela el
//        parry (igual que congela los demas CD de Amy). Nada de packets
//        nuevos, cero cambios en el server.
//  v3.6: LOS ATAQUES SPIN (bola al saltar / rodar) AHORA TAMBIEN DEVUELVEN
//        EL STUN AL ATACANTE. Ese dano NO lo aplica el puppet del atacante
//        (como el melee de las garras, que la v3.5 ya cubria) sino el
//        objeto del PROPIO superviviente (obj_sonic, obj_tails, obj_knux,
//        obj_egg, obj_sally, obj_amy...), asi que en la negacion self no
//        era un puppet y la senal v3.5 nunca salia: el dano se negaba pero
//        el EXE/esbirro rodando a toda velocidad se quedaba sin stun (su
//        propio cliente casi nunca caza el contacto: puppet de la victima
//        con lag + rodadura veloz). FIX: cuando la negacion no viene de un
//        puppet, se BUSCA al atacante en el cliente de la victima (donde
//        el contacto SI es exacto): puppet del lado EXE en bola (estado
//        JUMP/SPIN) tocando al jugador local, con los MISMOS filtros que
//        los bloques de dano spin de los supervivientes (Eggman/Amy/Amy
//        Canon/Sally/Sally Canon demonizados en bola no hacen dano y
//        Exeller en slime tampoco -> no se les manda senal). Cero paquetes
//        nuevos, cero cambios en el server.
//  v3.2: ventana 30f, aura SOLO VISIBLE para supervivientes (el EXE y
//        los esbirros no ven el circulo) e icono de HUD con el CD
//        (spr_gui_sonicparry, tecla C, como los demas personajes).
//  v3.3: FIX CRITICO del golpe que entraba tras el exito: la deteccion
//        de exito cerraba la ventana (parryState=4, estado de red 61->64)
//        ANTES de que el ataque interceptado se resolviera en las otras
//        maquinas, asi que el dano entraba igual y el atacante nunca se
//        stuneaba. El EXITO ahora protege igual que la ventana: estado 64
//        activo para el auto-stun del atacante y el aura, y la victima
//        cubierta tambien durante la animacion de exito.
//  v3.5: STUN DEL ATACANTE CUANDO EL GOLPE ES PARA EL PROPIO SONIC.
//        El auto-stun local (scr_parry_try_stun_attacker) solo corre en
//        el cliente del ATACANTE y necesita que ALLI el puppet de Sonic
//        le este tocando con la ventana activa; con el lag del puppet y
//        la mascara de solo-garras del ataque, ese contacto no siempre
//        existe aunque el golpe si entro (la negacion en el cliente de
//        Sonic SI corrio: pantalla roja, cero dano, animacion de exito)
//        -> el exe quedaba campando sin stun. FIX: la negacion, que es
//        la unica maquina con la certeza del golpe, le manda al ATACANTE
//        la misma senal de sonido de siempre (snd_exe_stun posicionado
//        en SU nid, shouldPlay=true via net_sound_emit_at) y el cliente
//        del atacante la reconoce en el CLIENT_SOUND_EMIT y se aplica el
//        stun a si mismo (scr_parry_stun_signal). Solo para el melee de
//        puppets; los proyectiles no stunean al que los tiro (regla del
//        parry) y esos objetos no son obj_player_puppet. Cero paquetes
//        nuevos, cero cambios en el server.
//  v3.4: SENAL DE EXITO PARA EL ALIADO. Cuando el golpe iba dirigido a
//        un aliado del aura, el contacto solo es exacto en el cliente
//        de ESA victima: en el de Sonic el puppet del atacante se queda
//        corto (lag + knockback del stun) y la deteccion local
//        (scr_parry_detect) nunca disparaba -> Sonic solo hacia la
//        animacion de exito cuando el dano era para el. Ahora la
//        negacion de la victima ya emite un "ting" posicionado en el
//        nid del Sonic que cubre (snd_parry viajando por el
//        CLIENT_SOUND_EMIT de siempre): el receptor de ese paquete en
//        la maquina del Sonic lo toma como SENAL de exito
//        (scr_parry_ting_signal). El auto-stun del atacante tambien lo
//        emite (cubre a las victimas con i-frames, que nunca negaban
//        nada) y el receptor deduplica el audio a 200ms. Cero paquetes
//        nuevos, cero cambios en el server.
//
//  COMO FUNCIONA (resumen):
//   * Tap de C -> windup (SONIC_PARRY_WINDUP frames, sin proteccion)
//     -> VENTANA ACTIVA (SONIC_PARRY_WINDOW frames de proteccion +
//     SONIC_PARRY_GRACE de gracia invisible para absorber la latencia).
//   * Durante la ventana activa, cualquier ataque del lado EXE que
//     fuera a golpear a Sonic O a un aliado dentro de su aura
//     (SONIC_PARRY_AURA px) queda INTERCEPTADO:
//       - el dano se niega en el cliente de la victima (igual que el
//         escudo de Sally: return antes de aplicar),
//       - el atacante se aturde A SI MISMO en su propio cliente
//         (scr_parry_try_stun_attacker en obj_player_puppet), IGNORANDO
//         sus i-frames (hurttime), y su escudo se consume entero,
//       - los proyectiles NO stunean al que los tiro (regla del parry):
//         el laser de Tails se DESVIA (pasa al lado de Sonic, en cian,
//         y aturde al EXE/esbirro que toque) y el anillo de Exetior se
//         CONVIERTE en anillo dorado recogible (+1).
//   * Exito -> animacion de exito + cooldown bueno; fallo -> cooldown
//     malo. En fase powerboost (tras usar Nervios de Acero) los
//     cooldowns son mas cortos.
//
//  TODO viaja por la red con lo que ya existia: el byte `state` del
//  paquete UDP lleva SONIC_PARRY_* (el server lo reenvia intacto) y los
//  paquetes nuevos van AL FINAL del enum (compatibles con clientes
//  viejos). Cero cambios en el formato del paquete de estado.
// =====================================================================

// ===== ESTADOS DE RED (byte `state`; 60+ libres, los golpes usan 20-59) =====
// v3: SOLO EN TIERRA (un unico sprite de inicio). Los 62/63 quedaron
// libres (eran las variantes de AIRE de la v1/v2, ya no se usan).
// v5 (KRIS): el ESCUDO de Kris (Deltarune) reusa esta maquina completa
// con sus propios sprites (spr_kris_block_*): SOLO en tierra (como
// Sonic) pero DIRECCIONAL — solo bloquea lo que viene de frente; un
// ataque de espaldas atraviesa el escudo. Sin aura de aliados: el
// escudo de Kris es personal. Tecla C (la misma que Sonic).
#macro SONIC_PARRY_INICIO 60     // windup (aun sin proteccion)
#macro SONIC_PARRY_INICIO_ACT 61 // VENTANA ACTIVA (protege)
#macro SONIC_PARRY_EXITO 64      // parte de EXITO (al interceptar)

// ===== TIMINGS (frames; 60 = 1 seg) =====
#macro SONIC_PARRY_WINDUP 1       // preparacion (sin proteccion)
#macro SONIC_PARRY_WINDOW 50      // ventana activa (v3.2: era 12)
#macro SONIC_PARRY_GRACE 6        // gracia invisible (latencia de red). v90: 4 -> 6, mas margen
                                   // para que la senal de exito del aliado (que viene por red) y el
                                   // golpe resuelto con lag sigan contando como parreados
#macro SONIC_PARRY_SIGNAL_GRACE 12 // v3.4: margen tras cerrar la ventana para la senal de exito por red
#macro SONIC_PARRY_EXITO_TIME 22  // duracion de la animacion de exito (SONIC; Amy calcula la suya)
#macro AMY_PARRY_EXITO_FRAMES_PER 4.5 // v4.2: frames de juego por cada frame del sprite de exito de Amy
                                       // (ajustable: 4.5 => sus 10 frames duran 45f = 0.75s)

// ===== NUMEROS =====
#macro SONIC_PARRY_AURA 64                    // radio del aura que cubre aliados (px). v90: 58 -> 64,
                                   // un poco mas de cobertura de aliados (el circulo del HUD lo
                                   // dibuja con el mismo macro: siempre coincide)
// (v90: el stun de 3,5 -> 4 s: el castigo del parry exitoso pega un poco mas
//  fuerte; con LMS (Sonic ultimo superviviente) son 4 + 2 = 6 s)
#macro SONIC_PARRY_STUN_TIME (60 * 4)         // stun del atacante parreado (4 seg)
#macro SONIC_PARRY_CD_FAIL (60 * 12)          // fallo  - fase normal. v90: 14 -> 12 seg: el castigo del
                                               // parry fallido sigue doliendo pero ya no desespera
#macro SONIC_PARRY_CD_OK (60 * 7)             // exito  - fase normal (7 seg)
#macro SONIC_PARRY_CD_FAIL_PB (60 * 10)       // fallo  - fase powerboost (10 seg)
#macro SONIC_PARRY_CD_OK_PB (60 * 2)          // exito  - fase powerboost (2 seg)
#macro SONIC_PARRY_LAND_BUFFER 8             // v90 (QoL): frames que se guarda un tap de C/V dado en
                                   // el aire para arrancar el parry al pisar suelo
#macro SONIC_PARRY_LASER_MAXDMG 4             // stun maximo (seg) del laser desviado
#macro SONIC_PARRY_FLASH_FRAMES 18            // anillo cian de activacion

// ===== COLOR DEL AURA (v4.0: rosa para Amy Canon, cian para Sonic) =====
// El circulo que ven los aliados mientras la ventana esta abierta. Se
// usa igual en el jugador local (Draw_0) y en el puppet (obj_player_puppet).
#macro AMY_PARRY_COLOR      make_color_rgb(230, 91, 140)  // rosa de Amy (el de su sprite)
#macro AMY_PARRY_COLOR_CORE make_color_rgb(255, 170, 200) // rosa claro (borde)

// ===== SPRITES =====
// v3: DOS sprites por personaje, solo en tierra:
//   inicio  -> parte inicial del intento (windup+ventana)
//   exitoso -> parte de EXITO (al interceptar)
// v4.0: cada personaje con los SUYOS (mismo patron por nombre):
//   Sonic     -> spr_sonic_parry_*  (fallback: su golpe de tierra)
//   Amy Canon -> spr_amy_parry_*    (fallback: spr_amy_attack1_canon;
//                los subio el usuario al repo). Si no existieran en
//                alguna instalacion, cae al sprite del golpe del propio
//                personaje para que nunca pete.
function scr_parry_sprite(st, _char, _nega)
{
        if(_char == -1)
                _char = global.character; // llamada sin personaje: el local

        if(is_undefined(_nega))
                _nega = false; // llamadas antiguas sin el flag: look normal

        // v11 (NEGAGEN): el subdito NEGATIVO hace el parry con las copias
        // nega de sus sprites (spr_<char>nega_*), igual que su cuerpo.
        var _tok = _nega ? "nega" : "";

        var _name = "";
        var _fb = "";

        if(_char == CHARACTER_AMY_CANON)
        {
                if(st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT)
                        _name = "spr_amy" + _tok + "_parry_inicio";
                else if(st == SONIC_PARRY_EXITO)
                        _name = "spr_amy" + _tok + "_parry_exitoso";
                else
                        return -1;

                _fb = "spr_amy" + _tok + "_attack1_canon";
        }
        else if(_char == CHARACTER_KRIS)
        {
                // v5 (KRIS): el ESCUDO. La stance (windup/ventana) usa la
                // pose de escudo alzado; el EXITO elige _ground/_air segun
                // de donde vino el ataque:
                //   * jugador LOCAL: la marca exacta krisBlockAir (la fijo la
                //     deteccion/negacion en el instante del bloqueo)
                //   * puppet: se deduce del atacante EXE que tenga encima
                //     (si esta en JUMP/FALL o por encima -> venia del aire)
                if(st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT)
                {
                        _name = "spr_kris_block";         // stance propia (si algun dia existe)
                        _fb = "spr_kris_block_failed";     // mientras tanto: la pose de escudo
                }
                else if(st == SONIC_PARRY_EXITO)
                {
                        var _air = false;

                        if(variable_instance_exists(id, "krisBlockAir"))
                                _air = krisBlockAir;
                        else
                        {
                                // puppet (o instancia sin marca): deduccion
                                // por el atacante demonizado mas cercano
                                if(instance_exists(obj_player_puppet))
                                {
                                        with(obj_player_puppet)
                                        {
                                                if(!isDemonized || !visible || isInactive)
                                                        continue;

                                                if(distance_to_object(other) > 96)
                                                        continue;

                                                if(state == JUMP || state == FALL || y < other.y - 10)
                                                        other.krisBlockAir = true;
                                                else
                                                        other.krisBlockAir = false;

                                                break;
                                        }
                                }

                                if(variable_instance_exists(id, "krisBlockAir"))
                                        _air = krisBlockAir;
                        }

                        _name = _air ? "spr_kris_block_success_air" : "spr_kris_block_success_ground";
                        _fb = _air ? "spr_kris_block_success_ground" : "spr_kris_block_success_air";
                }
                else
                        return -1;
        }
        else
        {
                if(st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT)
                        _name = "spr_sonic" + _tok + "_parry_inicio";
                else if(st == SONIC_PARRY_EXITO)
                        _name = "spr_sonic" + _tok + "_parry_exitoso";
                else
                        return -1;

                _fb = "spr_sonic" + _tok + "_attack2_tierra1";
        }

        var _spr = asset_get_index(_name);
        if(!is_undefined(_spr) && _spr >= 0)
                return _spr;

        _spr = asset_get_index(_fb);
        if(!is_undefined(_spr) && _spr >= 0)
                return _spr;

        return -1;
}

// Color del aura de ESTE personaje (v4.0): rosa para Amy Canon, cian
// para Sonic. Lo leen el Draw_0 del jugador local y el del puppet.
function scr_parry_aura_color(_char)
{
        // v5: Kris no tiene aura de aliados; color defensivo por si algo
        // lo consulta antes del filtro (plateado azulado de su escudo)
        if(_char == CHARACTER_KRIS)
                return make_color_rgb(150, 170, 200);

        return (_char == CHARACTER_AMY_CANON) ? AMY_PARRY_COLOR : SONIC_PB_COLOR;
}

function scr_parry_aura_color_core(_char)
{
        return (_char == CHARACTER_AMY_CANON) ? AMY_PARRY_COLOR_CORE : SONIC_PB_COLOR;
}

// ¿este personaje tiene sistema de parry? (v4.0: Sonic y Amy Canon)
// v5: Kris tambien (su escudo). OJO: char_has activa TODA la maquina
// (input, fases, negacion); lo que Kris NO tiene es el AURA de aliados
// (eso lo filtran los dos sitios que la dibujan/aplican).
function scr_parry_char_has(_char)
{
        return _char == CHARACTER_SONIC || _char == CHARACTER_AMY_CANON || _char == CHARACTER_KRIS;
}

// v5: ¿es Kris? (ataajos para las partes que Kris NO hereda del parry)
function scr_parry_char_is_kris(_char)
{
        return _char == CHARACTER_KRIS;
}

// Tecla del parry del personaje local (v4.0): C para Sonic, V para Amy
// Canon. La V es nueva (scr_globals) y tambien va en el remap como
// "special3", asi que el usuario puede cambiarla en el menu.
function scr_parry_key()
{
        return (global.character == CHARACTER_AMY_CANON) ? global.KeyV : global.KeyC;
}

// =====================================================================
//  v4.2 - DURACION DE LA FASE DE EXITO POR PERSONAJE. La animacion de
//  exito de Amy Canon (spr_amy_parry_exitoso, 10 frames) es MAS LARGA
//  que la de Sonic (3 frames) y antes se comprimia en 22 frames
//  (SONIC_PARRY_EXITO_TIME) con lo que se veia cortada (queja del
//  usuario: "debe durar toda su animacion"). Ahora cada personaje
//  dura lo que pide su sprite: Amy reproduce TODA su animacion a ritmo
//  AMY_PARRY_EXITO_FRAMES_PER frames de juego por frame de sprite (4.5
//  => 45 frames = 0.75s con el sprite actual; se recalcula solo si el
//  sprite cambia de frames). Sonic sigue clavado en sus 22. El puppet
//  de los demas clientes no necesita nada: replica el image_index que
//  ya viaja por el paquete de estado de siempre y el estado 64 dura
//  lo mismo porque el timer es del dueno.
// =====================================================================
function scr_parry_exito_time(_char)
{
        if(_char == -1)
                _char = global.character;

        if(_char == CHARACTER_AMY_CANON)
        {
                var _spr = asset_get_index("spr_amy_parry_exitoso");

                if(!is_undefined(_spr) && _spr >= 0)
                {
                        var _n = sprite_get_number(_spr);

                        if(_n > 0)
                                return ceil(_n * AMY_PARRY_EXITO_FRAMES_PER);
                }
        }

        // v5 (KRIS): sus sprites de exito (9/10 frames) duran lo que
        // piden, al ritmo KRIS_BLOCK_EXITO_PER (definido en scr_kris_special)
        if(_char == CHARACTER_KRIS)
        {
                var _kspr = asset_get_index("spr_kris_block_success_ground");

                if(!is_undefined(_kspr) && _kspr >= 0)
                {
                        var _kn = sprite_get_number(_kspr);

                        if(_kn > 0)
                                return ceil(_kn * KRIS_BLOCK_EXITO_PER);
                }
        }

        return SONIC_PARRY_EXITO_TIME;
}

// ¿el estado es una PROTECCION ACTIVA del parry? (lo miran los otros
// clientes en el puppet de Sonic para saber que esta cubriendo: el
// aura que protege aliados, el circulo que se dibuja y el auto-stun
// del atacante).
// v3.3: INCLUYE EL EXITO (64). La deteccion de exito cierra la ventana
// al instante (parryState=4) pero el ataque interceptado sigue
// resolviendose unos frames despues en las otras maquinas (el golpe
// no es atomico entre clientes): si el 64 no contara como activo, el
// dano entraba un frame despues y el atacante nunca se stuneaba.
function scr_parry_state_active(st)
{
        return st == SONIC_PARRY_INICIO_ACT || st == SONIC_PARRY_EXITO;
}

// ¿el estado es alguno del parry? (para el dibujado del puppet)
function scr_parry_state_is(st)
{
        return st == SONIC_PARRY_INICIO || st == SONIC_PARRY_INICIO_ACT || st == SONIC_PARRY_EXITO;
}

// overlap de bounding boxes entre dos instancias (contacto
// puppet-vs-puppet: place_meeting solo sirve contra el jugador local)
function scr_parry_bbox_overlap(a, b)
{
        return a.bbox_right >= b.bbox_left && a.bbox_left <= b.bbox_right
                && a.bbox_bottom >= b.bbox_top && a.bbox_top <= b.bbox_bottom;
}

// Aplica un cooldown de parry y recuerda su duracion total (para que
// el icono del HUD sepa cuanto dura ESTE cd en concreto: fallo/exito x
// normal/powerboost duran distinto y el relleno siempre arranca lleno).
function scr_parry_apply_cd(_cd)
{
        parryCooldown = _cd;
        parryCooldownMax = _cd;
}

// =====================================================================
//  PROTECCION (cliente de la VICTIMA): ¿hay un Sonic con la ventana
//  activa cubriendo al jugador local?
//    global.player -> el local ES ese Sonic (parry propia)
//    puppet        -> un Sonic remoto lo cubre con su aura
//    noone         -> sin proteccion
// =====================================================================
function scr_parry_protects_me()
{
        if(!instance_exists(global.player))
                return noone;

        // el parry solo protege a sobrevivientes vivos
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
                return noone;

        if(global.player.isDead)
                return noone;

        // 1) yo tengo parry y estoy cubierto: ventana activa (parryActive)
        //    o fase de EXITO (v3.3: el ataque interceptado llega a
        //    resolverse DESPUES de la deteccion de exito; sin esto el
        //    dano entraba igual). v4.0: Amy Canon vale igual que Sonic.
        if(scr_parry_char_has(global.character)
        && (global.player.parryActive || global.player.parryState == 4))
                return global.player;

        // 2) un Sonic o Amy Canon remoto con parry activa y yo dentro de
        //    su aura. v5: Kris NO — su escudo es personal (no cubre a
        //    nadie mas), asi que un Kris remoto bloqueando NO protege
        //    al jugador local.
        if(!instance_exists(obj_player_puppet))
                return noone;

        var _res = noone;
        with(obj_player_puppet)
        {
                if(!scr_parry_char_has(character) || character == CHARACTER_KRIS || isDemonized || isInactive)
                        continue;

                if(!scr_parry_state_active(state))
                        continue;

                if(distance_to_object(global.player) <= SONIC_PARRY_AURA)
                {
                        _res = self;
                        break;
                }
        }
        return _res;
}

// =====================================================================
//  NEGACION (la llama scr_player_hurt con exeSource=true): el dano
//  viene de un ataque/habilidad del lado EXE y hay parry cubriendo al
//  jugador local -> se NIEGA. Devuelve true (el llamador no aplica nada).
//  El STUN del atacante lo resuelven DOS caminos (el que llegue primero
//  gana; el otro se deduplica con el guard de shockedTimer):
//    1) su propio cliente (scr_parry_try_stun_attacker), con los mismos
//       datos sincronizados, y
//    2) v3.5/v3.6: la SENAL que emite esta negacion hacia el nid del
//       atacante (snd_exe_stun posicionado, mismo paquete de sonido de
//       siempre), porque el contacto exacto solo existe AQUI (cliente de
//       la victima) y el camino 1 fallaba justo cuando el golpe iba
//       dirigido al propio Sonic (v3.5, melee) o cuando el ataque era
//       un spin de bola al saltar/rodar (v3.6): el atacante a toda
//       velocidad casi nunca caza el contacto en su propia pantalla.
// =====================================================================
function scr_parry_negate_hit()
{
        var _sonic = scr_parry_protects_me();
        if(_sonic == noone)
                return false;

        // v5 (KRIS): el escudo es DIRECCIONAL — solo bloquea lo que viene
        // DE FRENTE (o del aire hacia donde mira). `self` aqui es la
        // FUENTE del dano (el puppet atacante en el melee, el laser, la
        // bola...): si esta detras de Kris, la negacion NO procede y el
        // golpe entra completo ("si el ataque viene de espaldas no lo
        // bloqueara"). Antes de decidir se fija krisBlockAir: la marca
        // exacta de si el atacante estaba EN EL AIRE (elige la animacion
        // de exito _air/_ground en scr_parry_sprite).
        if(_sonic != noone && _sonic.object_index == obj_kris)
        {
                if(!scr_kris_block_front(_sonic, id))
                        return false;

                _sonic.krisBlockAir = scr_kris_block_attacker_air(id, _sonic);
        }

        var _nid = obj_netclient.nid;
        if(_sonic != global.player)
                _nid = _sonic.master_id;

        // FX + "ting" posicionado en el Sonic que parrea: directo en su
        // pantalla (shouldPlay del emit_at) y 3D desde su puppet en las
        // demas (mismo sistema de sonido de red de siempre). Sin play
        // local extra: en un self-parry el emit_at ya lo suena una vez.
        // v3.3: en rafaga (throttle 200ms). Con el EXITO protegiendo, el
        // MISMO ataque interceptado vuelve a pedir la negacion varios
        // frames seguidos (hasta que el stun del atacante le llega y le
        // cancela el ataque); sin esto el "ting", el shake y el paquete
        // de sonido salian una vez por frame.
        static _fxLast = -9999;
        if(current_time - _fxLast >= 200)
        {
                // v83: la senal viaja como snd_parry (indice 107 de global.net_snds):
                // Perfect_Parry NO esta en ese array, el indice -1 llegaba como 255 y el
                // receptor lo descartaba (el ting del aliado cubierto nunca entraba)
                net_sound_emit_at(snd_parry, _nid);

                // v3.5 / v3.6: SENAL DE STUN AL ATACANTE, con el mismo
                // paquete de sonido de siempre (shouldPlay=true): el cliente
                // del atacante lo recibe posicionado en su nid, lo reconoce
                // en el CLIENT_SOUND_EMIT y se aturde solo
                // (scr_parry_stun_signal).
                //
                // MELEE (garras/golpe): aqui `self` es el PUPPET ATACANTE
                // (scr_player_hurt la llama desde el Step del puppet con el
                // melee del lado EXE), asi que master_id es SU nid.
                //
                // SPIN (v3.6, bola al saltar / rodar): ese dano NO lo aplica
                // el puppet del atacante sino el objeto del PROPIO
                // superviviente (obj_sonic, obj_tails, obj_knux, obj_egg,
                // obj_sally, obj_sally_canon, obj_amy, obj_amy_canon), asi
                // que self no es un puppet y no hay master_id a mano. En
                // ESTE cliente el contacto si es exacto (por eso el dano
                // nego): se busca al puppet del lado EXE en bola (estado
                // JUMP/SPIN) tocando al jugador local y se le manda la
                // senal a SU nid. Mismos filtros que los bloques de dano
                // spin de los supervivientes (Eggman/Amy/Amy Canon/Sally/
                // Sally Canon demonizados en bola no hacen dano, Exeller en
                // slime tampoco) para no stunear a inocentes que rueden
                // cerca. Si hay VARIOS tocando a la vez, se les manda a
                // todos (el receptor deduplica con shockedTimer).
                //
                // En los objetos que no son ni puppet ni superviviente
                // (laser de Tails, bolas de Exetior, cadenas, pinchos de
                // mapa) no se emite: los proyectiles no stunean al que
                // los tiro y los peligros del mapa no tienen dueno. Y si la
                // negacion viene de uno de esos pero ningun puppet en bola
                // esta tocando, la busqueda no encuentra a nadie -> nada.
                if(object_index == obj_player_puppet)
                        net_sound_emit_at(snd_exe_stun, master_id);
                else if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                // mismo predicado del bloque de dano spin de
                                // los supervivientes: del lado EXE, visible,
                                // activo y EN BOLA...
                                if(!isDemonized || !visible || isInactive)
                                        continue;
                                
                                if(state != JUMP && state != SPIN)
                                        continue;
                                
                                // ...con las mismas exclusiones de ahi
                                if(character == CHARACTER_EGGMAN || character == CHARACTER_AMY || character == CHARACTER_AMY_CANON || character == CHARACTER_SALLY || character == CHARACTER_SALLY_CANON)
                                        continue;
                                
                                if(character == CHARACTER_EXE && exeCharacter == 1 && slimeMode)
                                        continue;
                                
                                // el contacto exacto de ESTA maquina: es lo
                                // que disparo el dano que se acaba de negar
                                if(!place_meeting(x, y, global.player))
                                        continue;
                                
                                net_sound_emit_at(snd_exe_stun, master_id);
                        }
                }

                net_quick_effect(_sonic.x, _sonic.y - 8, spr_shockparticle, false, 1, 0, 0, 1);
                scr_camera_shake(20, 2, 0.2);
                _fxLast = current_time;
        }

        return true;
}

// =====================================================================
//  STEP DEL PARRY (solo el Sonic local; lo llama obj_sonic/Step_0):
//  maquina de fases + deteccion de exito + desvios de proyectil.
// =====================================================================
function scr_parry_step()
{
        if(parryFlash > 0)
                parryFlash--;

        if(parryCooldown > 0)
                parryCooldown--;

        // v3.4: margen de la senal de exito por red
        if(parryLateSignal > 0)
                parryLateSignal--;

        // v90 (QoL): reloj del BUFFER DE ATERRIZAJE (ver el bloque de INPUT
        // de abajo): un tap de C/V en el aire vive estos frames para arrancar
        // el parry justo al pisar suelo
        if(parryLandBuffer > 0)
                parryLandBuffer--;

        // cancelacion: si lo hieren/stunean matando el parry, cuenta como
        // fallo. v3: TAMBIEN si se va al aire (el parry es SOLO en tierra;
        // la parte de EXITO se deja terminar para no cortar la animacion).
        // v90: TAMBIEN si se DEMONIZA (conversion a esbirro o subdito
        // negativo a mitad de ventana): los demonizados no parrean y su
        // estado 61 dejaria un circulo de aura falso en las otras maquinas.
        if(parryState > 0 && (isDead || isHurt || shockedTimer > 0 || nerviosState > 0 || revivalTimes >= 2 || (!isGrounded && parryState != 4)))
        {
                if(parryState != 4 && !parrySuccess && parryCooldown <= 0)
                        scr_parry_apply_cd(nerviosUsed ? SONIC_PARRY_CD_FAIL_PB : SONIC_PARRY_CD_FAIL);

                parryState = 0;
                parryActive = false;
                parryLateSignal = 0;
        }

        // fase EXITO: solo termina la animacion
        if(parryState == 4)
        {
                parryTimer--;
                if(parryTimer <= 0)
                        parryState = 0;
                return;
        }

        if(parryState > 0)
        {
                parryTimer--;

                if(parryTimer <= 0)
                {
                        if(parryState == 1)
                        {
                                // fin del windup -> se abre la ventana
                                parryState = 2;
                                parryTimer = SONIC_PARRY_WINDOW + SONIC_PARRY_GRACE;
                                parryActive = true;
                                parryFlash = SONIC_PARRY_FLASH_FRAMES;
                        }
                        else if(parryState == 2)
                        {
                                // cerro la ventana sin interceptar nada: FALLO
                                parryActive = false;
                                parryState = 0;

                                if(!parrySuccess)
                                {
                                        scr_parry_apply_cd(nerviosUsed ? SONIC_PARRY_CD_FAIL_PB : SONIC_PARRY_CD_FAIL);

                                        // v3.4: la SENAL de exito del aliado viene por red y
                                        // puede llegar un poco despues de cerrar la ventana
                                        // (latencia de ida y vuelta del paquete de sonido).
                                        // La negacion ocurrio DENTRO de la ventana en el
                                        // cliente de la victima, asi que se admite dentro
                                        // de este margen; luego ya no.
                                        parryLateSignal = SONIC_PARRY_SIGNAL_GRACE;
                                }
                        }
                }

                // deteccion de exito (solo con la ventana abierta)
                if(parryState == 2 && !parrySuccess)
                        scr_parry_detect();

                return;
        }

        // ===== INPUT: tap de C (Sonic) / V (Amy Canon). v3: SOLO EN TIERRA =====
        // v90: BUFFER DE ATERRIZAJE — un tap en el AIRE con todo lo demas en
        // orden ya no se pierde: se guarda SONIC_PARRY_LAND_BUFFER frames y
        // el parry arranca al pisar suelo (con el MISMO gate re-evaluado en
        // el aterrizaje). v90: REVIVALTIMES < 2 — los demonizados (esbirros
        // y subditos negativos, que SI conservan el control) no pueden
        // abrir el parry: su estado 61 dibujaria el circulo del aura en las
        // demas maquinas sin proteger a nadie.
        if(global.playerControls && parryCooldown <= 0 && revivalTimes < 2
        && !isHurt && !isDead && shockedTimer <= 0 && !isZipline && !isHiding
        && !isAttacking && !isSpinCharging && nerviosState == 0
        && bounceTimer <= 0
        // v51 — SUPER AMY: V + ARRIBA ya no dispara el parry de Amy
        // Canon (esa combinacion es el toggle de la super forma en
        // scr_amy_canon_special); V sola sigue pariando igual.
        && !((global.character == CHARACTER_AMY_CANON) && keyboard_check(global.KeyUp)))
        {
                // tap en el AIRE: se guarda para el aterrizaje
                if(!isGrounded && keyboard_check_pressed(scr_parry_key()))
                        parryLandBuffer = SONIC_PARRY_LAND_BUFFER;

                // en TIERRA: tap fresco O el buffer del aterrizaje vivo
                if(isGrounded && (keyboard_check_pressed(scr_parry_key()) || parryLandBuffer > 0))
                {
                        parryState = 1;
                        parryTimer = SONIC_PARRY_WINDUP;
                        parrySuccess = false;
                        parryActive = false;
                        parryLandBuffer = 0;
                }
        }
}

// =====================================================================
//  DISPARO DEL EXITO (v3.4): lo comparten la deteccion local
//  (scr_parry_detect) y la senal de red (scr_parry_ting_play, el caso
//  del aliado). `self` tiene que ser el Sonic local.
// =====================================================================
function scr_parry_success_now()
{
        parrySuccess = true;
        parryState = 4; // parte de EXITO
        parryTimer = scr_parry_exito_time(global.character); // v4.2: Amy dura lo que pide su sprite
        parryActive = false;
        parryFlash = SONIC_PARRY_FLASH_FRAMES;
        parryLateSignal = 0;
        scr_parry_apply_cd(nerviosUsed ? SONIC_PARRY_CD_OK_PB : SONIC_PARRY_CD_OK);
        scr_camera_shake(30, 2, 0.25);

        // v4.2 (pedido del usuario): SONIDO DE PARRY PERFECTO en la pantalla
        // del que parrea. Cubre TODOS los caminos de exito porque todos
        // pasan por aqui: melee detectado, LASER DEVUELTO (antes sin ningun
        // sonido), anillo negro convertido y la senal del aliado (ting).
        // Local a proposito: los demas clientes ya oyen el "ting" (snd_parry)
        // por la red de siempre y asi no se toca el enum de sonidos de red.
        audio_play_sound(Perfect_Parry, 0, false);

        // v47 (T3): el bloqueo exitoso YA cuenta en su lugar de verdad -
        // el CLIENT_PLAYER_HURT que el cliente del exe aturdido manda
        // con pid == el nid de Kris (el v46 lo contaba DOS veces: aqui
        // y en ese paquete; ahora una sola, cuando el stun aterriza).
        // Las fuentes del LV quedan: cuchillazo acertado + bloqueo
        // exitoso, 1 impacto cada una, siempre contadas por red.
}

// =====================================================================
//  RECEPTOR DEL "TING" (v3.4): lo llama el CLIENT_SOUND_EMIT de
//  net_state_game cuando el sonido es snd_parry y llega posicionado en
//  el nid del jugador local. Ese sonido SOLO lo emiten la negacion de la
//  victima (scr_parry_negate_hit) y el auto-stun del atacante
//  (scr_parry_try_stun_attacker), siempre con el nid del Sonic que
//  cubria: o sea, "mi parry acaba de salvar a alguien". En el caso del
//  aliado es la UNICA forma fiable de enterarse (el contacto alli solo
//  es exacto en el cliente de la victima). El audio se deduplica a
//  200ms porque la negacion y el auto-stun emiten casi a la vez.
// =====================================================================
function scr_parry_ting_play()
{
        static _tingLast = -99999;

        if(current_time - _tingLast >= 200)
        {
                _tingLast = current_time;
                // v90: argumentos en su sitio (snd, prioridad, loop) — antes
                // venian (false, 0) invertidos y funcionaba de casualidad
                audio_play_sound(Perfect_Parry, 0, false);
        }

        scr_parry_ting_signal();
}

// La parte de la senal: convierte el "ting" en animacion de exito del
// Sonic local (si procede). Idempotente: si ya esta en fase de exito o
// ya conto como exito, no hace nada.
function scr_parry_ting_signal()
{
        if(!scr_parry_char_has(global.character)) // v4.0: Sonic o Amy Canon
                return;

        if(!instance_exists(global.player))
                return;

        with(global.player)
        {
                if(parryState == 4 || parrySuccess)
                        return;

                // ventana activa -> exito normal
                if(parryState == 2)
                        scr_parry_success_now();
                else if(parryState == 0 && parryLateSignal > 0)
                {
                        // cerro hace un instante y la senal llego con retraso:
                        // la negacion ocurrio DENTRO de la ventana -> cuenta
                        scr_parry_success_now();
                }
        }
}

// =====================================================================
//  DETECCION DE EXITO (cliente de Sonic, ventana activa):
//   1) puppet del lado EXE atacando y tocando a Sonic o a un aliado
//      dentro del aura -> exito (el stun lo resuelve el atacante)
//   2) laser de Tails esbirro tocando a Sonic o a un aliado del aura
//      -> se pide el desvio al server (lo invierte y lo vuelve cian)
//   3) anillo negro de Exetior dentro del aura -> se convierte en
//      anillo dorado recogible (el server lo cambia por un anillo real)
// =====================================================================
function scr_parry_detect()
{
        var _hit = false;
        var _me = self; // Sonic (el que llama): dentro de with anidados `other` cambia

        // v5 (KRIS): deteccion DIRECCIONAL y personal. Solo cuenta lo que
        // viene DE FRENTE (scr_kris_block_front); sin lista de victimas
        // del aura (su escudo no cubre a nadie mas) y sin conversion de
        // anillos negros (eso es del parry de Sonic). El laser de Tails
        // esbirro SI dispara el EXITO si esta de frente — el dano lo
        // niega scr_parry_negate_hit como el melee, pero NO se desvia:
        // el escudo bloquea, no devuelve.
        if(scr_parry_char_is_kris(global.character))
        {
                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(!isDemonized || !visible || isInactive)
                                        continue;

                                if(!(isAttacking || state == JUMP || state == SPIN))
                                        continue;

                                if(!scr_parry_bbox_overlap(self, _me))
                                        continue;

                                // de espaldas no lo bloquea (regla de la duena)
                                if(!scr_kris_block_front(_me, self))
                                        continue;

                                _me.krisBlockAir = scr_kris_block_attacker_air(self, _me);
                                _hit = true;
                                break;
                        }
                }

                // laser de Tails esbirro DE FRENTE: exito (sin desvio)
                if(!_hit && instance_exists(obj_tails_projectile))
                {
                        with(obj_tails_projectile)
                        {
                                if(isBreaking || !isExe)
                                        continue;

                                if(!scr_parry_bbox_overlap(self, _me))
                                        continue;

                                if(!scr_kris_block_front(_me, self))
                                        continue;

                                _me.krisBlockAir = scr_kris_block_attacker_air(self, _me);
                                _hit = true;
                                break;
                        }
                }

                if(_hit)
                        scr_parry_success_now();

                return _hit;
        }

        if(instance_exists(obj_player_puppet))
        {
                // aliados vivos dentro del aura (victimas potenciales)
                var _victims = ds_list_create();
                with(obj_player_puppet)
                {
                        if(isDemonized || isInactive)
                                continue;

                        if(distance_to_object(_me) <= SONIC_PARRY_AURA)
                                ds_list_add(_victims, self);
                }

                // atacantes del lado EXE con el ataque activo
                with(obj_player_puppet)
                {
                        if(!isDemonized || !visible || isInactive)
                                continue;

                        if(!(isAttacking || state == JUMP || state == SPIN))
                                continue;

                        // ¿su ataque toca al propio Sonic?
                        if(scr_parry_bbox_overlap(self, _me))
                        {
                                _hit = true;
                                break;
                        }

                        // ¿o toca a un aliado cubierto por el aura?
                        for(var _i = 0; _i < ds_list_size(_victims); _i++)
                        {
                                if(scr_parry_bbox_overlap(self, _victims[| _i]))
                                {
                                        _hit = true;
                                        break;
                                }
                        }

                        if(_hit)
                                break;
                }

                ds_list_destroy(_victims);
        }

        // laser de Tails (isExe) tocando a Sonic o a un aliado del aura
        if(!_hit && instance_exists(obj_tails_projectile))
        {
                with(obj_tails_projectile)
                {
                        if(isBreaking || !isExe)
                                continue;

                        if(scr_parry_bbox_overlap(self, _me))
                        {
                                _hit = true;
                                break;
                        }

                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(isDemonized || isInactive)
                                                continue;

                                        if(distance_to_object(_me) > SONIC_PARRY_AURA)
                                                continue;

                                        // v90: el bbox del laser CONCRETO que estamos mirando
                                        // (other = la instancia del with de afuera). Antes se leia
                                        // por el INDICE del objeto (obj_tails_projectile.bbox_*),
                                        // que con varios lasers en vuelo mira al PRIMERO y no al que
                                        // esta tocando al aliado: el desvio nunca se pedia.
                                        if(scr_parry_bbox_overlap(self, other))
                                        {
                                                _hit = true;
                                                break;
                                        }
                                }
                        }

                        if(_hit)
                                break;
                }

                if(_hit)
                {
                        var _pk = cpacket_tcp(PacketType.CLIENT_TPROJECTILE_DEFLECT);
                        send_server_tcp(_pk);
                }
        }

        // anillo negro de Exetior dentro del aura -> anillo dorado
        if(instance_exists(obj_blackring))
        {
                with(obj_blackring)
                {
                        if(used || image_alpha < 1)
                                continue;

                        if(distance_to_object(_me) > SONIC_PARRY_AURA)
                                continue;

                        var _pk = cpacket_tcp(PacketType.CLIENT_BRING_DEFLECT);
                        buffer_write(_pk, buffer_u16, nid);
                        send_server_tcp(_pk);

                        used = true; // local: no reenviar el mismo
                        _hit = true;
                }
        }

        if(_hit)
                scr_parry_success_now();

        return _hit;
}

// =====================================================================
//  STUN DEL ATACANTE (lo llama obj_player_puppet/Step_0 en el cliente
//  del ATACANTE). `self` ahi es el puppet VICTIMA que el ataque local
//  esta tocando. Si esa victima esta cubierta por la ventana activa
//  del parry de un Sonic, el jugador local (EXE/esbirro) se aturde a
//  si mismo IGNORANDO sus i-frames y su escudo se consume entero.
//  Devuelve true si aplico el parry.
// =====================================================================
function scr_parry_try_stun_attacker()
{
        if(!instance_exists(global.player))
                return false;

        if(global.player.isDead)
                return false;

        // v3.5: deduplicacion. La negacion de la victima ya mando la SENAL
        // de stun por red (y puede llegar ANTES de que este contacto local
        // se resuelva); si ya estoy stuneado por ahi o por un stun normal
        // del juego, no se re aplica (no reinicia el timer, no duplica
        // sonidos ni paquetes).
        if(global.player.shockedTimer > 0)
                return false;

        var _parrySonic = noone;
        if(instance_exists(obj_player_puppet))
        {
                with(obj_player_puppet)
                {
                        if(!scr_parry_char_has(character) || isDemonized || isInactive)
                                continue;

                        if(!scr_parry_state_active(state))
                                continue;

                        // la victima de este ataque (other) dentro del aura
                        if(distance_to_object(other) > SONIC_PARRY_AURA)
                                continue;

                        _parrySonic = self;
                        break;
                }
        }

        if(_parrySonic == noone)
                return false;

        // v3.5: el cuerpo del stun vive en scr_parry_apply_stun (lo
        // comparten este auto-stun local y la senal de red de la victima).
        // Knockback: AWAY de la victima (self = puppet victima aqui);
        // _emitSound=true porque el sonido viaja con el net_sound_emit de
        // siempre hacia los demas clientes.
        scr_parry_apply_stun(master_id, -sign(x - global.player.x) * 4, true, _parrySonic.character);

        // v3.4: SENAL hacia el Sonic que cubria (el mismo "ting" que emite
        // la negacion de la victima, posicionado en su nid). Cubre a las
        // victimas con i-frames: su cliente nunca llamo a scr_player_hurt
        // -> nunca nego -> nunca emitio, pero este stun SI es un exito del
        // parry y Sonic tiene que ver su animacion. Cuando la victima si
        // nego, los dos "ting" llegan casi juntos y el receptor los
        // deduplica (200ms).
        // v83: la senal viaja como snd_parry (indice 107 de global.net_snds):
        // Perfect_Parry NO esta en ese array, el indice -1 llegaba como 255 y el
        // receptor lo descartaba (el ting del aliado cubierto nunca entraba)
        net_sound_emit_at(snd_parry, _parrySonic.master_id);

        return true;
}

// =====================================================================
//  APLICACION DEL STUN AL ATACANTE (v3.5): lo comparten el auto-stun
//  local (scr_parry_try_stun_attacker) y la SENAL de la negacion de la
//  victima (scr_parry_stun_signal). `self` NO se usa aqui: todo va sobre
//  global.player (el jugador local = el atacante).
//    _victimNid  : nid del puppet VICTIMA para los paquetes de camara y
//                  estadisticas (-1 = no identificada: solo se stunea)
//    _kx         : empujon horizontal del knockback
//    _emitSound  : true  -> auto-stun local: el sonido sale con el
//                  net_sound_emit de siempre (lo escuchan los demas en 3D)
//                  false -> senal de red: el sonido ya viajo dentro del
//                  propio paquete de la senal (snd_exe_stun posicionado
//                  en mi nid), reenviarlo sonaria doble
// =====================================================================
function scr_parry_apply_stun(_victimNid, _kx, _emitSound, _parryChar)
{
        // ESCUDO ELECTRICO DE EGGMAN esbirro: se consume el RESTO del
        // tiempo del escudo (pasa directo al cooldown completo)
        if(global.character == CHARACTER_EGGMAN && global.player.shieldRechrage < 0)
        {
                global.player.shieldRechrage = global.player.revivalTimes >= 2 ? EEGGMAN_SHIELD_RECHARGE : EGGMAN_SHIELD_RECHARGE;
                global.player.isAttacking = false;

                net_quick_effect(global.player.x, global.player.y, spr_shieldbreak, false, 1, 0, 0, 1);
                audio_play_sound(snd_sally_shieldbreak, 0, false);
                net_sound_emit(snd_sally_shieldbreak);
        }

        // ESCUDO DE SALLY esbirro: se rompe
        if((global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON) && global.player.shieldTimer > 0)
        {
                global.player.shieldTimer = 0;

                net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                audio_play_sound(snd_sally_shieldbreak, 0, false);
                net_sound_emit(snd_sally_shieldbreak);
        }

        // STUN DIRECTO: ignora los i-frames del atacante (hurttime) —
        // regla del parry: aturde aunque este transparente
        global.player.isAttacking = false;
        global.player.isSpinCharging = false;
        global.player.spinCharge = 0;
        global.player.hurttime = 0;
        // v5.0 LMS: con Sonic como ultimo superviviente, el stun del parry
        // dura +2 s (4 -> 6 s). Vale para el parry de SONIC: durante el
        // LMS el es el unico que puede tener la ventana activa (los
        // demonizados no parrean y Amy Canon ya cayo).
        // v47 (T3, duena): "el aumento de stun tanto del parry como el
        // propio corte" - el parry de KRIS alarga el stun con su nivel
        // de violencia, MISMO factor del corte (+5% por LV: LV 10 =
        // +50%, LV 20 = +100%). El LV lo espeja en ESTE cliente (el
        // del atacante parreado, que se aturde a si mismo: la
        // autoridad de siempre) el puppet del Kris con krisLvNet - la
        // senal silenciosa v46 - y sin senales recibidas vale 1.
        // _parryChar llega de los DOS llamadores con el personaje del
        // superviviente que parreo: SOLO Kris escala (el parry de Sonic
        // y el de Amy Canon quedan en sus 3,5 s de siempre + LMS).
        var _parryStun = SONIC_PARRY_STUN_TIME + (global.lmsActive ? LMS_STUN_BONUS * 60 : 0);

        if(_parryChar == CHARACTER_KRIS)
        {
                var _klvP = 1;

                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(character != CHARACTER_KRIS || isDemonized || isInactive)
                                        continue;

                                _klvP = variable_instance_exists(id, "krisLvNet") ? krisLvNet : 1;
                                break;
                        }
                }

                _parryStun = _parryStun * (1 + KRIS_LV_STUN_PCT * _klvP);
        }

        global.player.shockedTimer = _parryStun;
        global.player.xspd = _kx;
        global.player.yspd = -2;
        global.player.isGrounded = false;
        
        // v17 (VIDA REAL DEL NEGA): el parry de Sonic es otro stun DE
        // SUPERVIVIENTE — al nega atacante le cuesta 20 de vida (a 0 hp:
        // fase 2 de Sally / paciencia de Vanilla / portal de Jinna).
        // Para el exe y el esbirro comun no cambia nada.
        scr_jinna_negatouch_stun_hurt();

        audio_play_sound(snd_exe_stun, 0, false);
        if(_emitSound)
                net_sound_emit(snd_exe_stun);
        net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
        scr_camera_shake(30, 2, 0.25);

        // los mismos paquetes que ya usa el stun normal del juego
        // (camara de la victima + estadisticas de la partida); solo si la
        // victima esta identificada
        if(_victimNid >= 0)
        {
                // v47: el paquete lleva los segundos YA escalados por el LV
                var _stunSec = _parryStun div 60;

                var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
                buffer_write(_buffer, buffer_u16, _victimNid);
                buffer_write(_buffer, buffer_u16, floor(global.player.x));
                buffer_write(_buffer, buffer_u16, floor(global.player.y));
                buffer_write(_buffer, buffer_u16, _stunSec);
                send_server_tcp(_buffer);

                var _pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                buffer_write(_pak, buffer_u8, 1);
                buffer_write(_pak, buffer_u16, obj_netclient.nid);
                buffer_write(_pak, buffer_u16, _victimNid);
                buffer_write(_pak, buffer_u8, _stunSec);
                send_server_tcp(_pak);
        }

        if(global.character == CHARACTER_EXE)
                scr_exe_stunsound();
}

// =====================================================================
//  RECEPTOR DE LA SENAL DE STUN (v3.5): lo llama el CLIENT_SOUND_EMIT de
//  net_state_game cuando llega snd_exe_stun posicionado EN MI nid con
//  shouldPlay=true. Ese paquete SOLO lo emite la negacion de la victima
//  (scr_parry_negate_hit: mi golpe melee acaba de ser parreado por un
//  Sonic). Corre en el cliente del ATACANTE: me aturdo a mi mismo con las
//  mismas reglas del auto-stun local (escudos esbirros incluidos).
// =====================================================================
function scr_parry_stun_signal()
{
        if(!instance_exists(global.player))
                return;

        // solo el lado EXE puede ser parreado (EXE o esbirro demonizado)
        if(global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
                return;

        if(global.player.isDead)
                return;

        // v3.0 (arreglos a Sonic, pedido del usuario): la senal de red
        // puede llegar UNOS FRAMES TARDE (lag) y aturdia al exe DESPUES
        // de que su ataque (spin / golpe normal / bola) ya habia
        // terminado — "castigo gratis" por un ataque que ya no existe.
        // Mismo predicado que el auto-stun local (obj_player_puppet):
        // el parry SOLO castiga ataques ACTIVOS. La negacion del dano
        // en la victima no cambia (eso lo resuelve su propio cliente).
        if(!(global.player.isAttacking || global.player.isJumping || global.player.isSpinning))
                return;

        // deduplicacion: el auto-stun local ya me stuneo (caso del aliado,
        // donde el contacto en MI cliente si existia) o ya estoy stuneado
        // por otra cosa -> esta senal no hace nada
        if(global.player.shockedTimer > 0)
                return;

        // victima para los paquetes de camara/estadisticas: el superviviente
        // que mi ataque esta tocando ahora mismo en MI pantalla (la negacion
        // ocurrio en SU cliente con el contacto exacto; aqui aproximamos con
        // el contacto local, que tras el lag suele ser el mismo puppet).
        var _victimNid = -1;
        var _victimChar = -1; // v47: el personaje del parreador (escala del parry de Kris)
        if(instance_exists(obj_player_puppet))
        {
                with(obj_player_puppet)
                {
                        if(isDemonized || isInactive)
                                continue;

                        if(place_meeting(x, y, global.player))
                        {
                                _victimNid = master_id;
                                _victimChar = character;
                                break;
                        }
                }
        }

        // knockback hacia atras de donde miro (estoy pegandole a alguien que
        // tengo delante); el sonido NO se reenvia: ya viajo en el paquete de
        // esta senal (los demas lo oyen en 3D desde mi puppet)
        scr_parry_apply_stun(_victimNid, -global.player.image_xscale * 4, false, _victimChar);
}
