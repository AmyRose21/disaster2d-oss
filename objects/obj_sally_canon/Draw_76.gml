// v11 (NEGAGEN, 3 FORMAS): 1 normal / 2 NEGA / 3 demonizada.
// El subdito NEGATIVO usa la TIRA NEGA propia del personaje
// (spr_<char>nega_*: inversion pura de SUS sprites, mismo canon
// que los spr_amynega_* / spr_eggnega_* del build Negagen).
// El esbirro comun sigue con sus eanims; el superviviente igual.
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;
sprite_index = arr[? CHARACTER_SALLY_CANON][state];

// --- FASE DUELISTA: overrides de sprite ---
// El salto pasa a la bola (spr_sally_fase2_jump_canon) y la rodadura
// (SPIN) a su bola de spindash. El escudo ya NO toca el cuerpo: la
// burbuja es un efecto aparte animado que se dibuja encima en
// cualquier estado (Draw_0), igual que el escudo de la Sally
// vanilla (v5.6: antes habia poses atadas al escudo y la burbuja
// quedaba congelada o invisible segun el estado).
// v5.8: las poses de ACTIVACION del escudo (un solo pase al pulsar
// la habilidad) TAMPOCO pasan por aqui: las dibuja Draw_0 con un
// contador propio, sin tocar sprite_index ni image_index — asi este
// switch y sus clamps no pueden cortarlas ni reiniciarlas (era el
// origen de los loops de las v5.4-v5.7).
if(duelista)
{
        // v11 (NEGAGEN): overrides de la fase duelista en nega
        var _negaSc = variable_instance_exists(id, "isNegatouch") && isNegatouch;
        
        if(state == JUMP)
                sprite_index = _negaSc ? spr_sallynega_fase2_jump_canon : spr_sally_fase2_jump_canon;
        else if(state == SPIN)
                sprite_index = _negaSc ? spr_sallynega_spindash_canon : spr_sally_spindash_canon;
}

switch(state)
{
        case IDLE:
                image_speed = 1;
                break;
                
        case BALANCING:
                image_xscale = edgeDir;
                image_speed = 1;
                break;
                
        case HURT:
                image_speed = 0.4;
                break;
                
        case WALK:
                image_speed = 0.2 + (abs(xspd) / (maxHSpeed));
                break;
                
        case FALL:
                // (MUELLES): frames de subida/bajada configurados con la
                // Suite (global.fallAnims en scr_survivors.gml)
                scr_fall_anim();
                break;

        case RUN:
                image_speed = max(abs(xspd) / 20, 0.5);
                break;
                
        case JUMP:
                // v5.5 FIX (reporte del usuario): el salto DUELISTA es tipo
                // SPIN (bola de 8 frames): tiene que girar CONTINUO durante
                // TODO el arco del salto, subiendo y bajando. Antes heredaba
                // el comportamiento del salto vanilla (pose fija mientras
                // sube + animacion de caida clavada en el ultimo frame) y la
                // bola se quedaba congelada hasta que empezaba a caer. Misma
                // velocidad de giro que la bola del salto de Sonic (1.1).
                // v5.6: con el escudo activo la bola gira igual y la burbuja
                // se dibuja ENCIMA (Draw_0), como el escudo de la Sally
                // vanilla sobre su salto. El image_index viaja por red
                // (CLIENT_PLAYER_DATA), asi que el puppet en los demas
                // clientes gira continuo igual.
                if(duelista)
                {
                        image_speed = 1.1;
                        break;
                }

                if(yspd > 0)
                {
                        image_speed = 1;
                        if(image_index >= image_number - 1)
                                image_index = image_number - 1;
                }
                else
                        image_speed = 0;
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
                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                        
                break;
                
        case SPIN:
                image_speed = abs(xspd) / 5;
                break;
                
        case SALLY_SLIDE:
                image_speed = 0;
                break;
                
        case SALLY_ATTACK:
                image_speed = 1;
                if(image_index >= image_number - 1)
                {
                        isAttacking = false;
                        image_index = image_number - 1;
                }
                break;

        // DUELISTA: patada en tierra (2 patadas). Misma salida que la
        // aerea: al terminar la animacion se apaga sola. El estado 22
        // solo existe en fase duelista, asi que este case es todo suyo.
        case SALLY_CANON_F2_ATTACK:
                image_speed = 1;
                if(image_index >= image_number - 1)
                {
                        isAttacking = false;
                        groundKick = false;
                        image_index = image_number - 1;
                }
                break;

        // DUELISTA: carga del spindash. La bola gira mas rapido cuanto
        // mas cargada (mismo feel que Sonic/Amelia).
        case SALLY_CANON_SPINCHARGE:
                image_speed = 0.5 + (spinCharge / SALLY_CANON_SPINDASH_CHARGE_MAX) * 1.2;
                break;
                
        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
        case 16:
                image_speed = 1;
                break;
                
        // --- FASE 2: las 4 partes ---
        case SALLY_CANON_F2_PT1:
                // Golpe + retroceso: no repetible, congela en el ultimo frame
                image_speed = 1;
                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;
                
        case SALLY_CANON_F2_PT2:
                // Tirada en el suelo: no repetible, congela en el ultimo frame
                image_speed = 1;
                if(image_index >= image_number - 1)
                        image_index = image_number - 1;
                break;
                
        case SALLY_CANON_F2_PT3:
                // El salto: SI esta en loop mientras este en el aire
                image_speed = 1;
                break;
                
        case SALLY_CANON_F2_PT4:
                // Recuperacion (1 frame): frame fijo mientras la vida sube
                image_speed = 0;
                image_index = 0;
                break;
        
}
