// v11 (NEGAGEN, 3 FORMAS): 1 normal / 2 NEGA / 3 demonizada.
// El subdito NEGATIVO usa la TIRA NEGA propia del personaje
// (spr_<char>nega_*: inversion pura de SUS sprites, mismo canon
// que los spr_amynega_* / spr_eggnega_* del build Negagen).
// El esbirro comun sigue con sus eanims; el superviviente igual.
// v32 — INVISIBILIDAD (patron sonic.exe original): mientras dure,
// la jugadora local se ve como CONTORNO ROJO (la tabla
// global.player_rougeinvis de siluetas spr_rouge_invis_*, misma
// idea que la mitad "invisible" de la tabla del exe). Para los
// demas clientes NO hay nada que elegir: el bit PLAYER_INVIS
// esconde su puppet por completo (como al exe invisible).
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;
if(invisTimer > 0)
        arr = global.player_rougeinvis;
sprite_index = arr[? CHARACTER_ROUGE][state];

switch(state)
{
        case IDLE:
                image_speed = 1;
                break;

        case HURT:
                image_speed = 0;
                image_index = 0;
                break;

        case BALANCING:
                image_xscale = edgeDir;
                image_speed = 1;
                break;

        case WALK:
                image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
                break;

        case FALL:
                // Rouge trae 2 frames de caida (subida/bajada, patron Knux)
                image_index = yspd > 0 ? 1 : 0;
                break;

        case RUN:
        case JUMP:
                image_speed = max(abs(xspd) / 20, 0.5);
                break;

        case DEAD:
                // v20 (NEGA): la tira DEAD del subdito negativo hace de
                // animacion de STUN (el slot 6 del mirror nega copio el
                // dead del superviviente): UNA pasada y se queda en el
                // ultimo frame, no en bucle como el stun del esbirro demon.
                if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
                {
                        image_speed = 0.5;

                        if(image_index >= image_number - 1)
                        image_index = image_number - 1;

                        break;
                }

                if(revivalTimes >= 2)
                {
                        image_speed = 0.5;
                        break;
                }

                if(isGrounded)
                        image_speed = 1;
                else
                        image_speed = 0;

                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;

        case LOOKUP:
        case LOOKDOWN:
                image_speed = 1;

                // Stop on last frame
                if(image_index >= 1)
                        image_index = 1;

                break;

        case SPIN:
                image_speed = abs(xspd) / 5;
                break;

        case ROUGE_ATTACK:
                // v24 TALADRO AEREO (spr_rouge_attack1 girando rapido =
                // taladro en picada): mientras dure drillState NO termina
                // por animacion — lo cierra scr_rouge_special (aterrizar
                // -> tornado, dano, stun o muerte; v25: en el aire ya no
                // expira). El cierre por animacion del final es SOLO
                // defensivo y exige que NINGUN timer este vivo: en el frame
                // de aterrizar el drillState todavia va > 0 y cerrar ahi
                // mataba el cambio de modo al tornado.
                // v25 (LOOP REAL): image_speed 2 en una tira de 2 frames
                // CLAVA el image_index en 0 (0 + 2 = 2 -> wrap a 0): la
                // tira quedaba congelada. Con 1 alterna 0/1 cada frame =
                // giro de taladro en loop de verdad.
                if(variable_instance_exists(id, "drillState") && drillState > 0)
                {
                        image_speed = 1;
                        break;
                }

                image_speed = 1.5;

                // v27: este cierre defensivo respeta los DOS timers (el
                // v24 le puso el drillState; el tornado aereo pasa por AQUI
                // en el frame en que un trampolin/borde la despega: sin la
                // puerta del tornadoState mataba isAttacking a mitad del
                // remolino — la "animacion muerta que seguia empujando").
                if(image_index >= image_number - 1 && drillState <= 0 && tornadoState <= 0)
                {
                        isAttacking = false;
                        isGrounded = false;
                }
                break;

        case ROUGE_AIR_ATTACK:
                // v13 TORNADO (spr_rouge_attack2, 2 frames de remolino):
                // mientras dure el tornadoState NO termina por animacion —
                // lo cierra scr_rouge_special (timer, pared, stun o muerte).
                // v25 (LOOP DE VERDAD, pedido de la duena): la tira de 2
                // frames con image_speed 2 quedaba CLAVADA en el frame 0
                // (0 + 2 = 2 -> wrap a 0). Con 0.5 los frames alternan
                // 0,0,1,1,... = remolino girando en LOOP durante TODA la
                // duracion de la habilidad (3 s) y no solo al principio.
                // v24: el drillState tambien la mantiene girando — cubre el
                // frame de ATERRIZAJE del taladro (estado 15 con el
                // tornadoState todavia en 0: el cambio de modo arranca al
                // frame siguiente) para que el cierre por animacion no
                // mate la transicion.
                if((variable_instance_exists(id, "tornadoState") && tornadoState > 0)
                || (variable_instance_exists(id, "drillState") && drillState > 0))
                {
                        image_speed = 0.5;
                if(image_index >= 1)
                        image_index = 0;
                        break;
                }

                image_speed = 1.5;

                if(image_index >= image_number - 1)
                {
                        isAttacking = false;
                        isGrounded = false;
                }
                break;

        // v13: estado de VUELO patron VANILLA (subir y bajar con Z): la tira
        // spr_rouge_fly (4 frames, alas batiendo) corre en loop — ya NO es
        // la tira direccional de 5 frames del viejo planeo (el frame lo
        // anima la tira sola, image_speed normal, xscale de siempre).
        case ROUGE_GLIDE:
                image_speed = 1;
                break;

        // v13 — SPINDASH: la carga gira MAS RAPIDA cuanta mas carga lleva
        // (patron del charger de Sonic: 0.5 f/frame vacia -> 1.7 llena).
        case ROUGE_SPINDASH:
                image_speed = 0.5 + (spinCharge / ROUGE_SPINDASH_CHARGE_MAX) * 1.2;
                break;

        // v13 — bola LANZADA: gira con la velocidad real de rodado (igual
        // que el SPIN clasico).
        case ROUGE_SPIN_RELEASE:
                image_speed = abs(xspd) / 5;
                image_xscale = sign(gspd) == 0 ? image_xscale : sign(gspd);
                break;

        // v14 — SLIDE (patron Sally): tira de 1 frame, quieta.
        case ROUGE_SLIDE:
                image_speed = 0;
                break;

        // v14 — GLIDE PASIVA tipo Knuckles: tira DIRECCIONAL de 5 frames
        // (spr_rouge_glide): el frame lo fija scr_rouge_special segun el
        // glide_xspd (0=fuerte derecha ... 4=fuerte izquierda) — aqui no
        // se anima: image_speed 0 y el image_index ya viajo por red.
        // v23 (fix espejo): xscale = 1 AQUI, igual que el case KNUX_GLIDE
        // de obj_knux. El bloque "In Air" de scr_move_basic corre DESPUES
        // del special y pisa image_xscale a -1 al mantener izquierda: sin
        // esta linea la tira direccional quedaba ESPEJADA y Rouge planeaba
        // mirando al lado contrario (el puppet ya lo tenia, esto falta).
        case ROUGE_GLIDE_AIR:
                image_speed = 0;
                image_xscale = 1;
                break;

        // v4.5 — MORIBUNDA: tirada (spr_rouge_hurt), quieta en su frame
        case ROUGE_MORIBUNDA:
                image_speed = 0;
                image_index = 0;
                break;

        // v32 — PATADA (modo ATTACK, spr_rouge_attack3): tira de 8
        // frames a 0.75; se MANTIENE en el ultimo frame y el cierre
        // lo da el kickState de scr_rouge_special (i-frames hasta el
        // final). Mismo cierre-por-timer del tornado.
        case ROUGE_KICK:
                image_speed = 0.75;

                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;

        // v32 — CANAL DE ANILLOS (modo SUPPORT): la pose "emotico3"
        // (spr_rouge_emotion3) en loop mientras dure el canal quieto
        // de 1 s (patron del CREAM_SPAWN de Vanilla).
        case ROUGE_RINGS:
                image_speed = 1;
                break;

        // v32 — ESCUDO ELECTRICO (modo EGGMAN, patron del doctor):
        // aura de contacto sin pose propia. v42: este estado ya NO se
        // asigna (la animacion fluye normal y el aura la dibuja Draw_0
        // con eShieldTimer); el case queda SOLO defensivo por si algun
        // camino viejo llegara a fijar el 26: que ANIME en vez de
        // congelarse en un frame.
        case ROUGE_ESHIELD:
                image_speed = 1;
                break;

        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;
                break;
}

// v49 — SUPER FORM (prueba): mientras el test de la super forma este
// activo se dibuja su animacion propia (spr_rouge_super_form, la tira
// del transform con sus frames de flash) en lugar de la resuelta por
// estado — el recolor SRB2 lo aplica Draw_0 con la paleta global
// encadenada (ver scr_rouge_super). Muerta o demonizada muestra la
// tira de siempre: la prueba no pisa la muerte.
if(variable_instance_exists(id, "superFormTest") && superFormTest
&& !isDead && revivalTimes < 2)
{
        sprite_index = spr_rouge_super_form;
        image_speed = 1;
}
