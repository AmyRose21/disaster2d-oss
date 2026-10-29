var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;

// EL GOLPE (tecla X) usa estados dinamicos (>= SONIC_ATK_TIERRA) que
// no estan en el array: el sprite sale del escaneo por nombre
// (spr_sonic_attack2_tierra<N> / aereo<N>), igual que en el puppet del
// otro cliente. El resto de estados usan el array, como siempre.
var _spr = -1;

// PARRY (tecla C): estados 60-64, ANTES que los del golpe (60+ entraria
// en el rango del ataque aereo). Sprite por nombre con fallback al
// golpe (scr_parry_sprite), igual que las variantes.
if(scr_parry_state_is(state))
{
        _spr = scr_parry_sprite(state);

        if(_spr != -1)
                sprite_index = _spr;

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
                        // para Sonic devuelve exactamente SONIC_PARRY_EXITO_TIME
                        // (22), igual que siempre; Amy usa la suya (sprite mas largo).
                        image_speed = max(image_number / scr_parry_exito_time(global.character), 0.05);
                        break;
        }

        return;
}

// ABRAZO COMBINADO (interaccion con Amy Canon): estado 65. El cuerpo
// de Sonic no se dibuja mientras lo abrazan (lo tapa el sprite
// combinado de Amy); el estado solo viaja por red. Sprite fijo al idle
// para que si algo llegase a dibujarlo no quedara congelado a medias.
if(state == SONIC_HUGGED)
{
        sprite_index = spr_sonic_idle;
        image_speed = 0;
        image_index = 0;
        return;
}

if(state >= SONIC_ATK_AIRE)
{
        var _vi = state - SONIC_ATK_AIRE;
        
        if(_vi < array_length(global.sonicAtkAire))
                _spr = global.sonicAtkAire[_vi];
}
else if(state >= SONIC_ATK_TIERRA)
{
        var _vi = state - SONIC_ATK_TIERRA;
        
        if(_vi < array_length(global.sonicAtkTierra))
                _spr = global.sonicAtkTierra[_vi];
}
else if(state < array_length(arr[? CHARACTER_SONIC]))
        _spr = arr[? CHARACTER_SONIC][state];

if(_spr != -1)
        sprite_index = _spr;

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
                
        // PASIVA SPIN: el salto de Sonic es giratorio (bola). Mientras
        // dura, el contacto con el EXE en salto/rodadura se repelen.
        // v3: mientras el DROP DASH esta ARMADO (Z mantenido en el aire)
        // la bola gira al doble: se ve (y se oye, con el destello) el
        // instante exacto en que ya puede soltar el drop dash.
        case JUMP:
                image_speed = dropDashReady ? 2.2 : 1.1;
                
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
                
        // NERVIOS DE ACERO: tirado en el suelo. La animacion de espera
        // (..._Idle) va en LOOP durante TODA la fase; el paso a la
        // siguiente lo corta el timer del Step, no la animacion.
        case SONIC_NERVIOS:
                image_speed = SONIC_NERVIOS_IDLE_SPD;
                break;
                
        // NERVIOS DE ACERO: levantandose. La velocidad se calcula para
        // que UNA pasada completa del sprite dure justo el timer de la
        // fase (SONIC_NERVIOS_FINISH_TIME), tenga los frames que tenga.
        case SONIC_NERVIOS_FINISH:
                image_speed = max(image_number / SONIC_NERVIOS_FINISH_TIME, 0.05);
                break;
                
        // SPINDASH: carga de la bola. Mientras mas carga tiene, mas
        // rapido gira la animacion (efecto de revolucadas). v3:
        // proporcional a la carga (0.5 -> 1.7 con la bola llena; antes
        // era fijo por punto y con CHARGE_MAX 10 se disparaba a 2.0).
        case SONIC_SPINDASH:
                image_speed = 0.5 + (spinCharge / SONIC_SPINDASH_CHARGE_MAX) * 1.2;
                break;
                
        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;                
                break;
}

// EL GOLPE (tecla X): variantes dinamicas (estados >= SONIC_ATK_TIERRA).
// La animacion corre una sola vez; al llegar al ultimo frame se apaga
// isAttacking. La variante la fijo scr_sonic_special al iniciar.
if(state >= SONIC_ATK_TIERRA)
{
        image_speed = SONIC_ATTACK_ANIMSPD;
        
        if(image_index >= image_number - 1)
                isAttacking = false;
}
