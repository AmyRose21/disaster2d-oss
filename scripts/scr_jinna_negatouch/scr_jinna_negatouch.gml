// =====================================================================
//  v7 (D.I.B.) — TOQUE NEGATIVO DE JINNA: el "modo súbditos alternativo"
//  de NEGAGEN (Sally.exe: Eye of Three), extraído del build YYC del mod
//  NU Project (demo con Negagen) y adaptado SOLO para Jina.
//
//  === CÓMO FUNCIONA EN NEGAGEN (reconstruido del desensamblado) =====
//  Negagen dispara un LÁSER y una ESFERA que infligen "daño de energía
//  negativa" (AboutNegagen: "can fire a laser and shoot a sphere that
//  inflicts negative energy damage necessary for the alternative
//  demonization of survivors. negative characters are weaker than
//  usual, but the number of such servants is unlimited compared to
//  regular demonization").
//  - Cada superviviente tiene un contador negatimer (0..100) que SOLO
//    sube con daño negativo (el láser/esfera le meten +4 por golpe; su
//    golpe normal también toca negatimer en la variante esfera/laser).
//  - Al llegar a 100 (y con Antinegatemper <= 0, su anti-píldora) el
//    superviviente se convierte AL INSTANTE en súbdito NEGATIVO: NO
//    pasa por la agonia de 30 s ni por el death-timer del server.
//  - El súbdito negativo es MÁS DÉBIL que un esbirro normal (menos
//    vida/daño) pero el número es ILIMITADO: no respeta el tope de
//    "mitad del lobby" de la demonización común.
//  - En el repositorio del juego original esto equivale a marcar al
//    jugador con PLAYER_DEMONIZED + PLAYER_REVIVED y setearle
//    revivalTimes = 2 con vida reducida, saltándose por completo el
//    flujo de muerte (death_timer) del servidor.
//
//  === ADAPTACIÓN A JINA =================================================
//  * CANAL: el AGARRE (tecla V) y la TRAMPA (V+ABAJO) de Jina ahora
//    acumulan ENERGÍA NEGATIVA además de su daño normal: cada impacto
//    suma JINNA_NEGA_CHARGE (25) al negatimer del superviviente. El
//    GOLPE (X) también mete carga (JINNA_NEGA_CHARGE_X, 25 desde la
//    v10 — antes 15 y la víctima moría antes de llenar la barra)
//    porque el contacto continuo es el corazón del kit de Jina.
        //  * UMBRAL: a 100 de carga el superviviente se convierte EN EL ACTO en
        //    SÚBDITO NEGATIVO: revive donde estaba con el look NEGATIVO
        //    (v8: inversion fotografica shd_negative, sin paleta demon), vida
        //    reducida (JINNA_NEGA_HP, 60) y pelea para el bando EXE. Sin
//    agonia, sin death-timer, sin el tope de "mitad del lobby": puede
//    convertir a TODO el lobby (esa es la gracia del modo alternativo).
//  * DEBILIDAD (fiel a Negagen): el súbdito negativo tiene MENOS vida
//    (60 vs 100 del esbirro común) y su golpe pega 15 (vs 20) — "negative
//    characters are weaker than usual".
        //  * ANTINEGATEMPER: cada conversión le da al resto de supervivientes
        //    3 s de inmunidad a la carga (JINNA_NEGA_GRACE): no se puede
        //    encadenar a todo el lobby en un solo segundo; el láser/esfera de
        //    Negagen tenía el mismo freno con su variable Antinegatemper.
        //  * v9 (PORTAL): los MINIONS invocados del portal (↓+C) TAMBIEN
        //    llevan el look negativo (SERVER_JINNA_MINION_STATE marca
        //    isNegatouch en todos los clientes) pero son MINIONS plenos:
        //    golpe de 20 (el !isMinion del Step_0 del puppet los excluye de
        //    la rebaja) y vuelta al portal al caer (CLIENT_JINNA_MINION_DOWN),
        //    sin purga: Jina los trae "negativizados" de la otra dimension.
        //    Solo cambia la piel.
//  * PURGA: si Vanilla ya no puede rescatarlos con el dedemonize normal
//    (son "negativos", no caidos), PERO un súbdito negativo a 0 hp NO
//    muere: se purga la carga a 0 y revive con 30 de vida como castigo
//    (sigue en juego como súbdito). La única salida real es que la
//    ronda termine o que Jinna caiga.
//  * RED: cero paquetes nuevos para el daño (la autoridad es el cliente
//    de la víctima, como todo el juego). Solo 1 paquete TCP nuevo para
//    avisar la conversión (CLIENT_JINNA_NEGATOUCH) que el server valida
//    (exe + Jinna + victima con carga llena y sin gracia) y reenvía
//    (SERVER_JINNA_NEGATOUCH_STATE) para que TODOS vean la conversión
//    instantánea. El "más débil" viaja en el propio paquete (vida) y el
//    puppet lo aplica con su flujo de siempre.
// =====================================================================

// Carga de energía negativa por golpe (el "negatimer" de Negagen)
#macro JINNA_NEGA_CHARGE 25         // agarre y trampa: 4 golpes = conversión
// v10: el golpe X sube a 25 (antes 15). Con 15 la víctima MORÍA antes
// de cargar: el X de Jinna pega 20-25 y 100 hp / 20 = 5 golpes = solo
// 75 de carga — se demonizaba por la vía común (esbirro marrón, sin
// look nega) y la conversión NUNCA llegaba. A 25 son 4 golpes = 100:
// la carga llena ANTES de morir (con anillos, todavía más margen) y el
// "modo súbditos alternativo" funciona de verdad por la vía del X.
#macro JINNA_NEGA_CHARGE_X 25       // golpe X: 4 golpes = conversión (v10: era 15)
#macro JINNA_NEGA_MAX 100           // umbral de conversión (negatimer 100 de Negagen)
#macro JINNA_NEGA_GRACE (60 * 3)    // Antinegatemper: 3 s de gracia al resto tras una conversión
#macro JINNA_NEGA_HP 60             // vida del súbdito negativo (más débil que el esbirro común: 100)
#macro JINNA_NEGA_DAMAGE 15         // su golpe pega 15 (el esbirro común: 20)
// v17 (VIDA REAL DEL NEGA): los stuns que los SUPERVIVIENTES le meten al
// bando EXE son el único daño que le entra al nega (los golpes comunes de
// los esbirros jamás le tocan la vida): 20 por stun — con los 60 hp de la
// conversión son 3 stuns y vuelve al portal de Jinna.
#macro JINNA_NEGA_STUN_DAMAGE 20    // v17: vida que pierde el nega POR CADA STUN de un superviviente
#macro JINNA_NEGA_REDHEAL 10        // v17: vida que le cura recoger un ANILLO ROJO (silencioso, solo si está herido)

// =====================================================================
//  v10 (NEGAGEN) — HELPERS DEL LOOK NEGA.
//  scr_negatouch_is(inst): ¿inst es un súbdito NEGATIVO? (la marca
//  isNegatouch, declarada lazy: sin tocar el Create de los ~15
//  supervivientes). La usan los Draw de los objetos para decidir el
//  look (sprites propios + shd_negative) sin repetir el guard en
//  cada sitio.
//
//  scr_esbirro_hud(inst): ¿inst es un ESBIRRO COMÚN a efectos de
//  HUD? (revivalTimes >= 2 PERO sin la marca nega). El súbdito
//  negativo NO es "un exe/esbirro" para el interfaz: conserva SUS
//  iconos de habilidad y SUS recargas de superviviente (el Look
//  completo de Negagen: el nega es un superviviente invertido, no
//  un demonio rojo). obj_playerui la usa en todos sus checks.
// =====================================================================
function scr_negatouch_is(inst)
{
        return inst != noone && variable_instance_exists(inst.id, "isNegatouch") && inst.isNegatouch;
}

function scr_esbirro_hud(inst)
{
        return inst != noone && inst.revivalTimes >= 2 && !scr_negatouch_is(inst);
}

// =====================================================================
//  LADO VÍCTIMA (corre en el cliente de CADA superviviente golpeado
//  por Jina: la autoridad del daño es suya, como en todo el juego).
//  La llaman: el handler de SERVER_JINNA_GRAB_STATE (agarre), el de
//  SERVER_JINNA_TRAP_HIT (trampa) y obj_player_puppet/Step_0 (golpe X
//  con exeSource). _charge llega según el canal que haya calado.
// =====================================================================
function scr_jinna_negatouch_hit(_charge = JINNA_NEGA_CHARGE)
{
        if(!instance_exists(global.player))
                return false;

        if(obj_netclient.gameEnds)
                return false;

        // solo supervivientes sin demonizar. OJO: se admite isDead — si el
        // MISMO golpe que relleno la carga la mato, la energia negativa la
        // SOSTIENE (es la gracia del modo alternativo de Negagen: la
        // conversion revive donde la agonia no empieza).
        if(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2)
                return false;

        // la carga se declara lazy (patrón weakMarkCd: sin tocar el
        // Create de los ~13 supervivientes)
        if(!variable_instance_exists(global.player.id, "jinnaNegaCharge"))
                variable_instance_set(global.player.id, "jinnaNegaCharge", 0);

        if(!variable_instance_exists(global.player.id, "jinnaNegaGrace"))
                variable_instance_set(global.player.id, "jinnaNegaGrace", 0);

        // Antinegatemper: en gracia no acumula (el freno de Negagen
        // para no vacunar al lobby entero en un segundo)
        if(global.player.jinnaNegaGrace > 0)
                return false;

        global.player.jinnaNegaCharge += _charge;

        // aviso de carga (visual: el propio jugador lo nota; los demas
        // aun no — patron de la marca de debilidad de Metal Amy)
        if(global.player.jinnaNegaCharge < JINNA_NEGA_MAX)
        {
                audio_play_sound(snd_metal_cd, 0, false);
                net_quick_effect(global.player.x, global.player.y - 24, spr_ringlose, false, 1, 0, 0, 1);
                return false;
        }

        // UMBRAL: conversión a súbdito negativo. La valida y anuncia
        // el SERVER (exe + Jinna + victima): el paquete vuelve como
        // SERVER_JINNA_NEGATOUCH_STATE y TODO el mundo aplica la
        // conversión instantánea (paleta demon + revivalTimes 2).
        global.player.jinnaNegaCharge = JINNA_NEGA_MAX;
        var pak = cpacket_tcp(PacketType.CLIENT_JINNA_NEGATOUCH, false);
        send_server_tcp(pak);
        return true;
}

// =====================================================================
//  CONVERSIÓN (corre en TODOS los clientes al recibir
//  SERVER_JINNA_NEGATOUCH_STATE; el propio negativo además revive).
//  Réplica del flujo de SERVER_JINNA_MINION_STATE (demonización
//  instantánea de los minions v6) con los números DEBILITADOS de
//  Negagen: 60 hp y golpe de 15. Es la pieza que saltó copiada del
//  desensamblado: scr_player_hurt_alternative + el bloque negatimer
//  >= 100 de los Step_0 de los supervivientes.
// =====================================================================
function scr_jinna_negatouch_convert(_vpid)
{
        if(_vpid == obj_netclient.nid)
        {
                if(!instance_exists(global.player))
                        return;

                // YO SOY EL SÚBDITO NEGATIVO: revivo EN EL ACTO donde
                // estaba (sin agonia, sin death-timer: el modo
                // alternativo de Negagen no pasa por el server para
                // matar — solo para anunciar). Vida DEBILITADA.
                global.player.isDead = false;
                global.player.hp = JINNA_NEGA_HP;
                global.player.rings = 0;
                global.player.hurttime = 60 * 2;      // 2 s de i-frames al convertirse
                global.player.isHurt = false;
                global.player.shockedTimer = 0;
                global.player.deadTimer = 31;
                global.player.revivalTimes = 2;       // esbirro: pelea para el EXE
                global.player.isMinion = false;       // esbirro COMUN del bando negativo (sin vida real de minion)
                // v12: escritura GARANTIZADA con variable_instance_set sobre
                // global.player.id (el patron PROBADO de jinnaNegaCharge): la
                // dot-escritura sobre el indice del objeto no crea variables
                // inexistentes y la marca nunca aterrizo en el jugador local
                // (v8-v11: el afectado se veia su propio sprite en su pantalla).
                // Los Create de los 15 supervivientes ya la declaran: esto es el
                // cinturon de seguridad del mismo patron de la carga.
                variable_instance_set(global.player.id, "isNegatouch", true); // v7: marca de súbdito NEGATIVO (golpe de 15)
                global.player.xspd = 0;
                global.player.yspd = 0;
                global.player.gspd = 0;

                // la carga se consume: queda a tope SOLO como marca de que
                // este es un negativo (la purga la consulta)
                // (jinnaNegaCharge ya vale JINNA_NEGA_MAX: la fijo la hit)

                // v8 (NEGAGEN): SIN paleta demon — el look del subdito
                // negativo es la INVERSION FOTOGRAFICA del sprite original
                // (shd_negative en el Draw de cada objeto), verificada pixel
                // a pixel contra los spr_amynega_* / spr_eggnega_* del build
                // Negagen. Aqui no se toca global.palleteFrom/To ni se
                // avisa paleta: el sprite original viaja como siempre y cada
                // cliente lo invierte al dibujar con la marca isNegatouch.

                // el control vuelve SI estaba apagado (patrón del
                // obj_jinna_absorb: congelar quita el control UNA vez)
                global.playerControls = true;

                with(obj_demon_indicator)
                        instance_destroy();

                instance_create_depth(global.player.x, global.player.y, 0, obj_demon_indicator);
                net_quick_effect(global.player.x, global.player.y + 32, spr_ring_teleport, false, 1, 0, 0, 2);
                audio_play_sound(snd_demonization, 0, false);
                net_sound_emit(snd_demonization);
                scr_camera_shake(16, 0.7, 0.15);

                global.cameraMode = 0;
        }
        else if(instance_exists(obj_player_puppet))
        {
                // el resto: estallido visual sobre su puppet + MARCA de
                // súbdito negativo (isNegatouch: patron de isMinion — la
                // marca viaja con ESTE paquete, la carga local no). La paleta
                // demon y el revivalTimes 2 llegan solos con el siguiente
                // paquete UDP de estado; la marca es lo que rebaja su golpe
                // a 15 en obj_player_puppet.
                with(obj_player_puppet)
                {
                        if(master_id != _vpid)
                                continue;

                        isNegatouch = true; // v7: súbdito negativo (golpe de 15)
                        scr_effect_quick(x, y - 20, spr_ring_teleport, 1, false, 0, 0);
                        audio_play_sound(snd_demonization, 0, false);
                        break;
                }

                // ANTINEGATEMPER grupal (fiel a Negagen): ver convertir a
                // un companero alerta a los demas supervivientes — 3 s de
                // inmunidad a la carga en cada cliente local (la carga es
                // local: la gracia tambien). El exe y los ya demonizados
                // no acumulan de todos modos (guard de scr_jinna_negatouch_hit).
                if(instance_exists(global.player)
                && global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
                {
                        if(!variable_instance_exists(global.player.id, "jinnaNegaGrace"))
                                variable_instance_set(global.player.id, "jinnaNegaGrace", 0);

                        global.player.jinnaNegaGrace = JINNA_NEGA_GRACE;
                }
        }
}

// =====================================================================
//  v17 (VIDA REAL DEL NEGA) — LA PURGA SE RETIRA.
//  El diseño de v7 sostenía al nega a 0 hp (revivía con 30 de vida donde
//  cayó: "débiles pero ilimitados"). El pedido nuevo de la dueña cambia
//  el final del ciclo: el nega tiene VIDA REAL en su barra, los STUNS de
//  los supervivientes le quitan 20 cada uno y AL LLEGAR A 0 vuelve
//  DIRECTAMENTE al portal de Jinna (como los minions: fuera de juego
//  hasta que ella lo re-invoque con ↓+C). La purga quedó además en
//  código muerto desde v7 (su llamada vivía dentro de un "hp > 0" que
//  hacía imposible su propio "hp <= 0"). Las dos excepciones al portal:
//   * SALLY CANON nega, 1ra caída: activa su FASE 2 (la pasiva que SÍ da
//     habilidades nuevas — "la única excepción a la regla es Amy"). Al
//     caer YA EN fase 2 sí vuelve al portal, y al ser RE-INVOCADA sale
//     directamente en fase 2 (el flag duelista viaja con SU cliente y
//     ni el portal ni la invocación lo tocan).
//   * VANILLA nega, 1ra caída: su PACIENCIA (Chocola) — "a Vanilla se le
//     perdona porque en esa forma es cuando llama a Chocola". Tras la
//     paciencia usada, la siguiente caída ya es portal.
//   * AMY CANON: SIN burbuja en nega (su burbuja no da habilidades
//     nuevas, solo la salva de la muerte: "esa queda solamente para
//     cuando es normal") — el nega Amy cae directo al portal.
// =====================================================================
function scr_jinna_negatouch_down()
{
        if(!instance_exists(global.player))
                return false;

        if(obj_netclient.gameEnds)
                return false;

        // solo súbditos NEGATIVOS (marca local + esbirro del bando EXE)
        if(global.character == CHARACTER_EXE || global.player.revivalTimes < 2)
                return false;

        if(!variable_instance_exists(global.player.id, "isNegatouch") || !global.player.isNegatouch)
                return false;

        // SALLY CANON nega, 1ra caída: su FASE 2 (mismo flujo canónico del
        // golpe, pero SIN perder el bando: el start canónico la vuelve
        // "normal" con revivalTimes 0 — aquí se lo devolvemos)
        if(global.character == CHARACTER_SALLY_CANON && !global.player.fase2Used)
        {
                scr_sally_canon_fase2_start(0);

                global.player.revivalTimes = 2;        // sigue siendo NEGA
                variable_instance_set(global.player.id, "isNegatouch", true);
                return true;
        }

        // VANILLA nega, 1ra caída: PACIENCIA (Chocola sale a stunearte 5 s
        // y ella se levanta al final con la vida llena). Copia del bloque
        // canónico de scr_player_instakill, MANTENIENDO el bando nega.
        if(global.character == CHARACTER_VANILLA && !global.player.pacienciaUsed && global.player.moribundaState <= 0)
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

                return true;
        }

        // SONIC nega, 1ra caída: NERVIOS DE ACERO (la única excepción a la
        // regla es Amy — el nervio de Sonic sí es una fase con poder nuevo:
        // se levanta con 100 de vida y 4 s de powerboost). Misma copia del
        // bloque canónico de scr_player_instakill; el bando nega no cambia.
        if(global.character == CHARACTER_SONIC && !global.player.nerviosUsed)
        {
                with(global.player)
                {
                        nerviosState = 1;
                        nerviosUsed = true;
                        nerviosTimer = SONIC_NERVIOS_TIME;
                        image_index = 0;
                        ghostTimer = 0;

                        hp = max(hp, 0);
                        hurttime = 0;
                        shockedTimer = 0;
                        isDead = false;
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

                return true;
        }

        // ROUGE nega, 1ra caída: MORIBUNDA (tirada 6 s y se levanta con 40
        // de vida). El gate canónico (revivalTimes < 1) no le sirve al nega
        // (su revivalTimes YA vale 2): se usa la marca propia negaMoribunda.
        // Tras usarla, la siguiente caída ya es portal.
        if(global.character == CHARACTER_ROUGE && global.player.moribundaState <= 0)
        {
                if(!variable_instance_exists(global.player.id, "negaMoribundaUsed"))
                        variable_instance_set(global.player.id, "negaMoribundaUsed", false);

                if(!global.player.negaMoribundaUsed)
                {
                        variable_instance_set(global.player.id, "negaMoribundaUsed", true);

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
                        }

                        audio_play_sound(snd_hurt, 0, false);
                        return true;
                }
        }

        // EL RESTO (Amy sin burbuja, Sally ya en fase 2, Vanilla tras la paciencia):
        // de vuelta AL PORTAL de Jinna. Reusa el paquete del minion
        // (CLIENT_JINNA_MINION_DOWN): el server lo acepta para negas
        // (PLAYER_NEGATIZED, fix v17 en Game.c), le re-marca
        // PLAYER_CAUGHT y lo reenvía a todos — el handler de
        // SERVER_JINNA_MINION_DOWN hace el resto (portal, fuera de
        // juego, cámara de espectador a la espera de la re-invocación).
        global.player.hp = 0;

        var _mdown = cpacket_tcp(PacketType.CLIENT_JINNA_MINION_DOWN, false);
        send_server_tcp(_mdown);

        return true;
}

// =====================================================================
//  v17 (VIDA REAL DEL NEGA) — STUN = 20 DE DAÑO.
//  Lo llaman TODAS las fuentes de stun "de superviviente" sobre el
//  jugador local (contacto del golpe en obj_player_puppet, patada en
//  tierra de Sally Canon fase 2, parry de Sonic, flecha de Fleetway
//  Amy, laser de Tails, bola de fuego de Blaze y trampa de Amelia).
//  La autoría es del cliente de la VÍCTIMA (patrón de todo el daño).
//  Solo cala en súbditos NEGATIVOS (marca isNegatouch + revivalTimes 2:
//  los minions invocados del portal TAMBIÉN la llevan — mismo look,
//  mismo ciclo de vida). A 0 hp enruta a scr_jinna_negatouch_down
//  (fase 2 de Sally / paciencia de Vanilla / portal de Jinna).
// =====================================================================
function scr_jinna_negatouch_stun_hurt()
{
        if(!instance_exists(global.player))
                return false;

        if(obj_netclient.gameEnds)
                return false;

        if(global.character == CHARACTER_EXE || global.player.revivalTimes < 2)
                return false;

        if(!variable_instance_exists(global.player.id, "isNegatouch") || !global.player.isNegatouch)
                return false;

        if(global.player.isDead || global.player.hp <= 0)
                return false;

        // estados de inmunidad total: ni daño ni caída mientras duren
        // (la fase 2 de Sally, la paciencia/moribunda de Vanilla, los
        // nervios de Sonic y la moribunda de Rouge son intocables
        // también para el nega — mismo trato que el original)
        if(global.character == CHARACTER_SALLY_CANON && global.player.fase2State != SALLY_CANON_F2_OFF)
                return false;

        if(global.character == CHARACTER_VANILLA && (global.player.pacienciaState > 0 || global.player.moribundaState > 0))
                return false;

        if(global.character == CHARACTER_SONIC && global.player.nerviosState > 0)
                return false;

        if(global.character == CHARACTER_ROUGE && global.player.moribundaState > 0)
                return false;

        global.player.hp -= JINNA_NEGA_STUN_DAMAGE;

        // stats de daño recibido (canal 3, mismo reporte que el minion)
        var _pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT, true);
        buffer_write(_pak, buffer_u8, 3);
        buffer_write(_pak, buffer_u8, JINNA_NEGA_STUN_DAMAGE);
        send_server_tcp(_pak);

        // sangre: el golpe de stuneo se VE en la vida del nega
        net_quick_effect(global.player.x, global.player.y, spr_blood3, false, 1, 0, 0, 1);

        if(global.player.hp <= 0)
                scr_jinna_negatouch_down();

        return true;
}
