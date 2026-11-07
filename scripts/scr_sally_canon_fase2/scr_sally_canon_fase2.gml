/// @description FASE 2 (Sally Canon) - modo de 4 partes al caer
/// Su 1ra caida JAMAS la mata (regla canonica, igual que la burbuja de
/// Amy Canon o los Nervios de Acero de Sonic): en vez de la agonia de
/// 30 segundos entra en su modo de 2 fases con 4 animaciones:
///   PT1 (spr_sally_fase2_canon_pt1): recibe el golpe y sale volando
///        hacia atras (al lado contrario de donde vino el golpe)
///        HASTA TOCAR EL SUELO tras el impulso (max 1.5 seg de
///        seguridad si nunca aterriza: hoyo/borde). Animacion no
///        repetible: congela en el ultimo frame.
///   PT2 (spr_sally_fase2_canon_pt2): tirada en el suelo 3.5 seg.
///        Tambien congela en el ultimo frame.
///   PT3 (spr_sally_fase2_canon_pt3): salto hacia arriba (como un jump
///        normal, en LOOP mientras este en el aire) con efecto de
///        SQUASH & STRETCH (solo en esta parte).
///   PT4 (spr_sally_fase2_canon_pt4): aterrizo = recuperacion: la vida
///        sube progresivamente hasta 100 (max 1.5 seg). Al levantarse
///        queda inmune al dano 4.5 seg.
/// Durante TODA la fase 2 (pt1 a pt4) es inmune a todo el dano. Si la
/// derriban de nuevo (fase2Used), muere directamente: JAMAS se
/// convierte en exe (parche del servidor, mismo guard que Amy Canon).

// =====================================================================
//  PARAMETROS AJUSTABLES  (60 frames = 1 segundo)
// ---------------------------------------------------------------------
//  * PT1_AIRMIN   = frames minimos de vuelo del pt1 antes de poder
//                   pasar a pt2 (evita que entre directa al suelo si
//                   el golpe la agarro parada: primero el impulso la
//                   despega, luego el aterrizaje la tira).
//  * PT1_TIME     = MAXIMO de frames del retroceso: red de seguridad
//                   para cuando el impulso la deja cayendo sin tocar
//                   suelo (hoyo/borde); 90 = 1.5 seg
//  * PT1_KNOCK_X / PT1_KNOCK_Y = fuerza del vuelo hacia atras. Es como
//                   golpear algo y que este salga despedido: X segun de
//                   donde vino el golpe, Y negativa = despega hacia arriba.
//  * PT2_TIME     = frames tirada en el suelo (210 = 3.5 seg)
//  * PT2_FRICTION = cuanto frena el suelo por frame si la parte 2 la
//                   pilla con velocidad (aterrizo DENTRO de pt2 tras
//                   el hoyo/borde): 0.5 = de 5.5 a 0 en ~11 frames
//                   (~0.2 seg). Un cuerpo tirado en el suelo frena
//                   rapido; sin esto se deslizaria los 3.5 seg enteros.
//  * PT3_AIRMIN   = frames minimos de pt3 antes de poder aterrizar
//                   (evita que si el salto arranca rozando el suelo
//                   salte directo a pt4 sin haber saltado).
//  * PT4_REGEN_TIME = frames maximos de la recuperacion (90 = 1.5 seg
//                   para llenar la vida de 0 a 100; sube parejito).
//  * PT4_INVULN   = frames de inmunidad al terminar pt4 (270 = 4.5 seg)
//  * SQ_STRETCH / SQ_SQUASH = cuanto se estira al saltar (+) y se
//                   aplasta al aterrizar (-). 0.35 = 35%.
//  * SQ_DECAY     = que tan rapido el efecto rebota a la forma normal
//                   (0.12 = suave, tipo resorte).
// =====================================================================
#macro SALLY_CANON_F2_PT1_TIME 90                // PT1: retroceso (1.5 seg)
#macro SALLY_CANON_F2_PT1_KNOCK_X 5.5            // PT1: fuerza horizontal del vuelo
#macro SALLY_CANON_F2_PT1_KNOCK_Y -5             // PT1: despega hacia arriba
#macro SALLY_CANON_F2_PT1_AIRMIN 8               // PT1: frames minimos en el aire
#macro SALLY_CANON_F2_PT2_TIME 210               // PT2: en el suelo (3.5 seg)
#macro SALLY_CANON_F2_PT2_FRICTION 0.5           // PT2: roce del suelo (frena el arrastre)
#macro SALLY_CANON_F2_PT3_AIRMIN 8               // PT3: frames minimos en el aire
#macro SALLY_CANON_F2_PT4_REGEN_TIME 90          // PT4: llenar la vida (1.5 seg)
#macro SALLY_CANON_F2_PT4_INVULN 270             // PT4: inmunidad al final (4.5 seg)
#macro SALLY_CANON_SQ_STRETCH 0.35               // SQ: estiron al despegar
#macro SALLY_CANON_SQ_SQUASH -0.30               // SQ: aplaston al aterrizar
#macro SALLY_CANON_SQ_DECAY 0.12                 // SQ: rebote de vuelta a lo normal

// Estados de la fase 2 (variable fase2State del jugador). Los numeros
// (18-21) son los indices de los sprites en player_anims de
// CHARACTER_SALLY_CANON y viajan por red con el byte de "state" de
// CLIENT_PLAYER_DATA: el puppet del otro cliente muestra la misma
// animacion sin paquetes extra.
#macro SALLY_CANON_F2_OFF 0                      // normal: fase 2 no activa
#macro SALLY_CANON_F2_PT1 BALANCING+5           // 18: golpe + retroceso
#macro SALLY_CANON_F2_PT2 BALANCING+6           // 19: tirada en el suelo
#macro SALLY_CANON_F2_PT3 BALANCING+7           // 20: salto (loop en el aire)
#macro SALLY_CANON_F2_PT4 BALANCING+8           // 21: recuperacion

// =====================================================================
//  FASE DUELISTA (v5.4 — «la Determinacion de la Princesa»)
//  Al terminar la recuperacion de la fase 2 (pt4) Sally Canon cambia
//  PARA SIEMPRE (hasta el fin de la ronda): deja de ser defensiva y
//  pasa a VELLOCISTA DUELISTA. La marca "duelista" del jugador viaja
//  por red con el bitflag PLAYER_POWERBOOST (el byte de bitflags va
//  lleno; POWERBOOST solo lo usan Sonic/Vanilla/Metal/Blaze, jamas
//  colisiona con Sally Canon) y los puppets lo guardan como
//  "duelista" (sticky: una vez vista, se queda).
//
//  Lo que desbloquea la fase duelista (ver scr_sally_special):
//   * PATADA EN TIERRA (tecla X en el suelo): animacion propia de 11
//     frames con 2 patadas -> 2 hitboxes. La UNICA habilidad del
//     juego que puede golpear al bando EXE 2 veces. Ignora TODOS los
//     i-frames: si la 1a patada conecta, el exe se teletransporta al
//     frente de Sally (al alcance de la 2a) y recibe la 2a patada.
//   * SPINDASH (abajo + Z, igual que Amelia/Sonic) + RODADURA:
//     canSpin = true (la rodadura con ABAJO corriendo, la de Tails y
//     los demas) y su salto pasa a spr_sally_fase2_jump_canon (bola).
//   * ESCUDO GRUPAL (tecla C): mismo efecto que el escudo tiene sobre
//     Sally, ahora tambien sobre los companeros cercanos (cada uno
//     absorbe 1 golpe por activacion, con los mismos i-frames). Con
//     poses propias: quieta / agachada / en el aire; caminando o
//     corriendo el efecto se dibuja sin animacion (burbuja fija).
//   * PASIVA INSTINTO DE LA PRINCESA DUELISTA: 20% de evadir TODO el
//     dano de un ataque (+2.5 s de i-frames que se ACUMULAN a los que
//     ya tenga, incluido el escudo). Solo se tira en la instancia de
//     dano real (nunca mientras ya esta inmune): ver scr_player_hurt.
// =====================================================================
#macro SALLY_CANON_F2_ATTACK BALANCING+9        // 22: patada en tierra (duelista)
#macro SALLY_CANON_SPINCHARGE BALANCING+10      // 23: carga del spindash (duelista)

// Ventanas de la patada en tierra: la 1a patada ocupa del frame 0 al
// 6 del sprite (spr_sally_fase2_attack_canon, 11 frames) y la 2a entra
// desde el frame 7. Cada ventana puede golpear 1 vez (2 golpes por
// patada); el image_index viaja sincronizado en CLIENT_PLAYER_DATA,
// asi que el cliente de la victima ve la misma ventana que Sally.
#macro SALLY_CANON_F2_KICK1_END 6               // ultimo frame de la 1a patada
#macro SALLY_CANON_F2_KICK2_START 7             // 1er frame de la 2a patada

// Hitbox ampliada de la patada (patron _sonicPad/_amyFuerzaPad: pad
// por distancia = % del ANCHO del bbox de Sally). Fase 1: la patada
// aerea +25%. Fase duelista: la de tierra +30% y la aerea +50%.
#macro SALLY_CANON_KICK_PCT_F1 0.25             // patada aerea, fase 1 (+25%)
#macro SALLY_CANON_KICK_PCT_F2_GROUND 0.30      // patada en tierra, duelista (+30%)
#macro SALLY_CANON_KICK_PCT_F2_AIR 0.50         // patada aerea, duelista (+50%)

// TP tras la 1a patada: el exe queda a esa fraccion del pad de la 2a
// patada, justo delante de Sally (0.5 = mitad del alcance: ni pegado
// al cuerpo ni fuera del rango de la 2a patada).
#macro SALLY_CANON_F2_TP_FACTOR 0.5

// Escudo grupal (duelista): radio de proteccion a los companeros y
// segundos de i-frames que recibe quien absorbe un golpe con el
// (los MISMOS que el escudo roto de Sally: SALLY_CANON_SHIELD_BREAK_INVULN).
#macro SALLY_CANON_GROUP_SHIELD_RADIUS 120

// Pasiva INSTINTO DE LA PRINCESA DUELISTA: % de evasion e i-frames
// que otorga (se ACUMULAN a los existentes, no los reemplazan).
#macro SALLY_CANON_EVADE_CHANCE 20              // % de evadir todo el dano
#macro SALLY_CANON_EVADE_INVULN (60 * 2.5)      // 2.5 s de i-frames

// SPINDASH (duelista): valores 1:1 con los de Amelia/Sonic (misma
// movilidad; ver scr_amelia_special / scr_sonic_special).
#macro SALLY_CANON_SPINDASH_BASE 8
#macro SALLY_CANON_SPINDASH_REV 2
#macro SALLY_CANON_SPINDASH_CHARGE_MAX 10
#macro SALLY_CANON_SPINDASH_DECAY 90
#macro SALLY_CANON_SPINDASH_PITCH_STEP 0.8
#macro SALLY_CANON_SPINDASH_DUST_EVERY 10
#macro SALLY_CANON_SPINDASH_BURST_MIN 3
#macro SALLY_CANON_SPINDASH_BURST_MAX 8

// v4.9 (manejo): velocidad MAXIMA desde la que puede ARRANCAR la
// carga frenando en seco (antes exigia gspd == 0 exacto: apretar
// abajo+Z frenando se perdia, o peor, saltabas sin querer). Encaja
// con el umbral de rodadura de scr_move_basic: < 2 = carga, >= 2 =
// rodar (la rodadura la tiene la fase duelista: canSpin).
#macro SALLY_CANON_SPINDASH_START_MAX 2

function scr_sally_canon_fase2_start(hitDir = 0)
{
        // --- ENTRA EN FASE 2 (1ra caida de Sally Canon) ---
        // Se llama desde scr_player_instakill(): en vez de morir, arranca
        // la parte 1 (retroceso del golpe). El estado viaja solo con el byte
        // de "state" de CLIENT_PLAYER_DATA, igual que la burbuja de Amy.
        with(global.player)
        {
                fase2State = SALLY_CANON_F2_PT1;
                fase2Used = true;              // 1 sola vez por ronda
                fase2Timer = SALLY_CANON_F2_PT1_TIME;
                fase2Air = 0;
                fase2Sq = 0;
                
                hp = max(hp, 0);               // normaliza la vida que dejo la caida
                hurttime = 0;                  // sin invulnerabilidad ni knockback heredado
                shockedTimer = 0;              // por si la caida venia de un stun
                isDead = false;                // la fase 2 NO cuenta como muerte
                revivalTimes = 0;              // jamas pasa a 2: nunca se hace exe
                isAttacking = false;
                isSliding = false;
                slideSpeed = 0;
                isJumping = false;
                isSpinning = false;
                isBoosting = false;
                isZipline = false;
                isHiding = false;
                isHurt = false;
                emotion = false;
                shieldTimer = 0;               // la caida apaga el escudo (no lo rompe)
                
                // DUELISTA: si la caida la pilla cargando el spindash,
                // corta la carga (la fase 2 sustituye todo su control)
                isSpinCharging = false;
                spinCharge = 0;
                
                if(spinRevSnd != -1)
                        audio_stop_sound(spinRevSnd);
                
                deadTimer = 31;
                image_index = 0;               // pt1 empieza desde el frame 0
                
                // Retroceso: al lado CONTRARIO de donde recibio el golpe (como
                // cuando golpeas algo y este sale volando hacia atras). Si no se
                // sabe la direccion (hoyo, zona de dano), usa su propia mirada.
                var _dir = hitDir != 0 ? sign(hitDir) : -sign(image_xscale);
                gspd = 0;
                xspd = _dir * SALLY_CANON_F2_PT1_KNOCK_X;
                yspd = SALLY_CANON_F2_PT1_KNOCK_Y;
                isGrounded = false;
                
                // Impacto visible para todos. El sonido del golpe queda igual
                // que siempre (snd_hurt por red) y su grito de dolor (1 de
                // SALLY1-5 al azar) suena ADICIONAL encima: en su pantalla y en
                // la de los demas, con el mismo paquete de sonido de siempre.
                net_quick_effect(x, y, spr_blood2, false, -_dir, 0, 0, 1);
                net_sound_emit(snd_hurt);
                var _snd = choose(SALLY1, SALLY2, SALLY3, SALLY4, SALLY5);
                audio_play_sound(_snd, 0, false);
                net_sound_emit(_snd);
        }
}

function scr_sally_canon_fase2()
{
        // --- MOTOR DE LA FASE 2 (cada frame, en vez de scr_move_basic) ---
        // Corre en el ambito de obj_sally_canon (la llama su Step_0). La
        // gravedad y las colisiones las sigue sumando scr_collision_basic,
        // que corre justo despues de esto en el Step del objeto.

        // El squash & stretch siempre rebota hacia 0 (la forma normal)
        fase2Sq += (0 - fase2Sq) * SALLY_CANON_SQ_DECAY;
        if(abs(fase2Sq) < 0.01)
                fase2Sq = 0;

        // Mientras dura la fase 2 no puede engancharse a nada
        isZipline = false;
        isAttacking = false;
        isSliding = false;
        isJumping = false;
        isLookingDown = false;
        isLookingUp = false;
        emotion = false;

        if(fase2State == SALLY_CANON_F2_PT1)
        {
                // PT1: volando hacia atras por el golpe. La parte 1
                // termina al TOCAR EL SUELO tras el impulso (no por
                // tiempo): nunca queda deslizandose por el piso en pose
                // de vuelo ni se tira ahi misma donde estaba parada.
                // AIRMIN garantiza que el impulso la despegue primero
                // (aunque el golpe la agarre parada); el timer queda
                // solo de red de seguridad si nunca aterriza (hoyo).
                fase2Air++;
                fase2Timer--;

                if((fase2Air >= SALLY_CANON_F2_PT1_AIRMIN && isGrounded) || fase2Timer <= 0)
                {
                        // impacto contra el suelo: polvo para todos (mismo
                        // patron que el aterrizaje del salto de pt3)
                        if(isGrounded)
                        {
                                net_quick_effect(x, y + 20, spr_dust);

                                // FIX deslizamiento infinito: el impulso del
                                // golpe MUERE al tocar el suelo. Antes el
                                // aterrizaje solo cambiaba de estado: el xspd
                                // del retroceso (5.5) sobrevivia y, como en
                                // fase 2 no corre scr_move_basic (donde vive
                                // la friccion normal), nada lo frenaba: se
                                // quedaba deslizando en pose de vuelo hasta
                                // chocar una pared o caerse otra vez. El
                                // aterrizaje ya le pasa el xspd al gspd
                                // (scr_collision_check_bottom): hay que
                                // matar AMBOS, como hace el salto de pt3.
                                gspd = 0;
                                xspd = 0;
                        }

                        fase2State = SALLY_CANON_F2_PT2;
                        fase2Timer = SALLY_CANON_F2_PT2_TIME;
                        fase2Air = 0;
                        image_index = 0;
                }
        }
        else if(fase2State == SALLY_CANON_F2_PT2)
        {
                // FIX deslizamiento (red de seguridad): si el timer de pt1 se
                // agoto en el aire (hoyo/borde), aterriza YA dentro de pt2 y
                // el aterrizaje le hereda el xspd al gspd. Sin este freno se
                // iria deslizando los 3.5 seg ENTEROS de la parte (mismo bug
                // del pt1, por la otra puerta). Frena rapido, como un cuerpo
                // tirado rozando el suelo: 0.5/frame = parada en ~0.2 seg.
                // (sign(0) = 0: con la velocidad ya a 0 no mueve nada.)
                if(isGrounded)
                {
                        gspd -= min(abs(gspd), SALLY_CANON_F2_PT2_FRICTION) * sign(gspd);
                        xspd -= min(abs(xspd), SALLY_CANON_F2_PT2_FRICTION) * sign(xspd);
                }

                // PT2: tirada en el suelo esperando. Si el retroceso la dejo
                // cayendo (hoyo, borde), la gravedad la baja sola: el timer corre
                // igual y al acabarse salta desde donde este.
                fase2Timer--;

                if(fase2Timer <= 0)
                {
                        // PT3: el salto hacia arriba. SQUASH & STRETCH: se estira
                        // al despegar (solo en esta parte de la animacion).
                        fase2State = SALLY_CANON_F2_PT3;
                        fase2Air = 0;
                        fase2Sq = SALLY_CANON_SQ_STRETCH;
                        image_index = 0;

                        gspd = 0;
                        xspd = 0;
                        yspd = -jumpForce;
                        isGrounded = false;

                        audio_play_sound(snd_jump, 0, false);
                        net_sound_emit(snd_jump);
                }
        }
        else if(fase2State == SALLY_CANON_F2_PT3)
        {
                // PT3: en el aire con la animacion en loop. Aterrizar = PT4.
                fase2Air++;

                if(fase2Air >= SALLY_CANON_F2_PT3_AIRMIN && isGrounded)
                {
                        // PT4: aterrizo. SQUASH & STRETCH: se aplasta al caer y
                        // rebota a lo normal mientras se recupera.
                        fase2State = SALLY_CANON_F2_PT4;
                        fase2Timer = SALLY_CANON_F2_PT4_REGEN_TIME;
                        fase2Sq = SALLY_CANON_SQ_SQUASH;
                        image_index = 0;

                        gspd = 0;
                        xspd = 0;
                        yspd = 0;

                        // Polvo del aterrizaje (visible en todos los clientes)
                        net_quick_effect(x, y + 20, spr_dust);

                        // EVASI2: su grito de evasion suena 1 SOLA vez, justo al
                        // entrar en la parte final de la fase 2 (pt4). Como la
                        // transicion PT3 -> PT4 ocurre una unica vez, nunca se
                        // repite. En su pantalla + en la de los demas por red
                        // (mismo patron que el salto de pt3).
                        audio_play_sound(EVASI2, 0, false);
                        net_sound_emit(EVASI2);
                }
        }
        else if(fase2State == SALLY_CANON_F2_PT4)
        {
                // PT4: la vida sube progresivamente hasta 100. Con
                // PT4_REGEN_TIME frames para llenarla toda sube parejo
                // (100/90 = ~1.1 por frame), como recuperar anillos.
                hp = min(100, hp + 100 / SALLY_CANON_F2_PT4_REGEN_TIME);
                fase2Timer--;

                if(fase2Timer <= 0 || hp >= 100)
                {
                        hp = 100;

                        // FIN de la fase 2: se levanta con 4.5 seg de inmunidad.
                        // Si la derriban otra vez muere directo (fase2Used): el
                        // server jamas la convierte en exe (parche, como Amy Canon).
                        fase2State = SALLY_CANON_F2_OFF;
                        fase2Sq = 0;
                        hurttime = SALLY_CANON_F2_PT4_INVULN;
                        isGrounded = true;

                        // FASE DUELISTA: al levantarse de su 1ra caida cambia
                        // para siempre (hasta el fin de la ronda). Desbloquea la
                        // patada en tierra, el spindash, la rodadura con ABAJO
                        // corriendo (canSpin: la de Tails y los demas), el escudo
                        // grupal y la pasiva de evasion. El flag viaja por red
                        // con PLAYER_POWERBOOST (lo manda obj_netclient/Step_2
                        // y lo guardan los puppets como "duelista").
                        duelista = true;
                        canSpin = true;
                        canSpinDash = true;
                }
        }
}
