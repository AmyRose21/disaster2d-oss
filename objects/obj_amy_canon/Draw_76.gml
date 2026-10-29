// PARRY (tecla V): estados 60-64, ANTES que el abrazo y que el array de
// scr_survivors (el 60 no existe en el array). Sprite por nombre con
// fallback al suyo de ataque (scr_parry_sprite), igual que hace Sonic
// con los suyos. Mismas velocidades de animacion que el de Sonic.
if(scr_parry_state_is(state))
{
        var _pspr = scr_parry_sprite(state, global.character);

        if(_pspr != -1)
                sprite_index = _pspr;

        switch(state)
        {
                case SONIC_PARRY_INICIO:
                        image_index = 0;
                        image_speed = max(image_number / SONIC_PARRY_WINDUP, 0.05);
                        break;

                case SONIC_PARRY_INICIO_ACT:
                        image_speed = max(image_number / (SONIC_PARRY_WINDOW + SONIC_PARRY_GRACE), 0.05);
                        break;

                case SONIC_PARRY_EXITO:
                        // v4.2: duracion por personaje (scr_parry_exito_time):
                        // su animacion de 10 frames ya NO se comprime en 22
                        // frames; se reproduce COMPLETA a su ritmo (pedido del
                        // usuario: "debe durar toda su animacion").
                        image_speed = max(image_number / scr_parry_exito_time(global.character), 0.05);
                        break;
        }

        return;
}

// ABRAZO COMBINADO: el estado AMY_CANON_HUG NO va por el array de
// scr_survivors (se intercepta aqui, igual que el parry de Sonic en
// su Draw_76): mientras Amy abraza su cuerpo ni siquiera se dibuja;
// Draw_0 pinta el sprite combinado en el punto medio con Sonic.
// Poner esto ANTES de leer el array (el indice 24 no existe en el).
if(state == AMY_CANON_HUG)
{
        sprite_index = spr_amy_hug_canon;
        image_speed = 0;
        image_index = 0;
        return;
}

var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
sprite_index = arr[? CHARACTER_AMY_CANON][state];

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
                image_index = 0;
                break;
                
        case RUN:
                image_speed = max(abs(xspd) / 20, 0.5);
                break;
                
        case JUMP:
                image_speed = 1.1;
                
                if(image_index >= image_number - 1)
                        isJumping = false;
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
                if(image_index >= 1)
                        image_index = 1;
                        
                break;
                
        case SPIN:
                image_speed = abs(xspd) / 5;
                break;
                
        case AMY_CANON_ATTACK:
                image_speed = 0.3;

                if(image_index >= image_number - 1)
                        isAttacking = false;
                break;
                
        // ATAQUE 3: acometida de martillo. La animacion corre en LOOP
        // a la velocidad AMY_CANON_DASH_ANIMSPD (ajustable en Create_0.gml).
        // El fin de la acometida lo controla dashTimeLeft en
        // scr_amy_canon_special.gml, no la animacion.
        case AMY_CANON_DASH:
                image_speed = AMY_CANON_DASH_ANIMSPD;
                
                if(!isDashing)
                        isAttacking = false;
                break;
                
        // PASIVA TAROT: flotacion (sprite de 9 frames en loop).
        case AMY_CANON_TAROT:
                image_speed = 0.5;
                break;
                
        // HABILIDAD 2 (tecla X) en el aire: impulso de tarot con el sprite
        // nuevo spr_amy_attack1_canon (2 frames en loop; el fin lo controla
        // tarotDashTimeLeft en scr_amy_canon_special).
        case AMY_CANON_TAROTDASH:
                image_speed = AMY_CANON_TAROTDASH_ANIMSPD;
                break;
                
        // ESTADO BURBUJA (secuestro): sprites de 1 frame; la variante
        // (frente/izquierda/derecha) la elige Step_2 segun bubbleDir.
        case AMY_CANON_CAPTURE:
        case AMY_CANON_CAPTURE_L:
        case AMY_CANON_CAPTURE_R:
                image_speed = 0;
                image_index = 0;
                break;
                
        case AMY_CANON_HJUMP:
                image_speed = 0.3;
                
                if(image_index >= image_number - 1)
                        isHJ = false;
                break;
                
        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;                
                break;
}