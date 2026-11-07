var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_SALLY_CANON][state];

// --- FASE DUELISTA: overrides de sprite ---
// El salto pasa a la bola (spr_sally_fase2_jump_canon) y la rodadura
// (SPIN) a su bola de spindash. El escudo grupal tiene poses propias
// (quieta / agachada / en el aire); caminando o corriendo conserva el
// sprite normal y el efecto se dibuja aparte sin animacion (Draw_0).
if(duelista)
{
        if(state == JUMP)
                sprite_index = spr_sally_fase2_jump_canon;
        else if(state == SPIN)
                sprite_index = spr_sally_spindash_canon;

        if(shieldTimer > 0)
        {
                if(state == IDLE)
                        sprite_index = spr_sally_shield_canon;
                else if(state == LOOKDOWN)
                        sprite_index = spr_sally_shield_down_canon;
                else if(state == JUMP || state == FALL)
                        sprite_index = spr_sally_shield_air_canon;
        }
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
