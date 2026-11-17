// KRIS v1 — 3 formas (patron NEGAGEN): 1 normal / 2 NEGA / 3 demonizada.
// En la practica Kris JAMAS es 2 ni 3 (regla canonica de la duena: ni
// subdito negativo ni esbirro), pero el patron del array es el mismo
// de los 15 supervivientes.
var arr = revivalTimes >= 2 ? global.player_eanims : global.player_anims;
if(variable_instance_exists(id, "isNegatouch") && isNegatouch)
        arr = global.player_negaanims;

var _spr = -1;

// ESCUDO (tecla C): estados 60/61/64 (los mismos del parry). El
// sprite lo resuelve scr_parry_sprite contra los spr_kris_block_*
// reales del proyecto (NO por el array de anims): la stance usa
// spr_kris_block_failed y el exito elige _ground/_air segun de donde
// vino el ataque (krisBlockAir en el local; el puppet lo deduce del
// atacante que tenga encima). Va ANTES que la espada (60+ entraria en
// el rango del ataque aereo).
if(scr_parry_state_is(state))
{
        _spr = scr_parry_sprite(state, global.character, false);

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
                        // duracion por sprite (patron Amy v4.2): los block_success_*
                        // de Kris (9/10 frames) duran lo que pide su sprite
                        image_speed = max(image_number / scr_parry_exito_time(global.character), 0.05);
                        break;
        }

        return;
}

// MORIBUNDA (patron Rouge): tirado en el suelo, quieto en el ULTIMO
// frame del sprite de muerte (la pose de completamente caido)
if(state == KRIS_MORIBUNDA)
{
        sprite_index = spr_kris_dead;
        image_speed = 0;

        if(image_index < image_number - 1)
                image_index = image_number - 1;

        return;
}

// ESPADA (tecla X): estados dinamicos (patron Sonic), resueltos
// directamente contra los sprites reales (el array de anims lo relleno
// la Suite a su criterio; los estados custom no dependen de el).
//   20 = tajo en tierra (reusa air1 hasta que haya arte de tierra)
//   40 = ataque aereo FASE 1 (spr_kris_attack1_air1)
//   41 = ataque aereo FASE 2 (spr_kris_attack1_air2: hitbox +50% en
//        el puppet e i-frames en scr_player_hurt mientras dura)
if(state == KRIS_ATK_TIERRA)
{
        sprite_index = spr_kris_attack1_air1;
        image_speed = KRIS_ATK_GROUND_SPD;

        if(image_index >= image_number - 1)
                isAttacking = false;

        return;
}

if(state >= KRIS_ATK_AIRE)
{
        var _air2 = (state == KRIS_ATK_AIRE + 1);
        sprite_index = _air2 ? spr_kris_attack1_air2 : spr_kris_attack1_air1;
        image_speed = _air2 ? KRIS_ATK_AIR2_SPD : KRIS_ATK_AIR1_SPD;

        // El air2 (fase final) apaga el ataque en su ultimo frame. El air1
        // NO: su continuacion (subir a air2 o cerrar por aterrizar) la
        // decide scr_kris_special al frame siguiente — si se apagara aqui,
        // la fase 2 jamas llegaria a verse.
        if(_air2 && image_index >= image_number - 1)
                isAttacking = false;

        return;
}

// resto de estados: el array de anims de la Suite, con guard de
// longitud (patron del puppet: fuera de rango mantiene el sprite)
if(state < array_length(arr[? CHARACTER_KRIS]))
        _spr = arr[? CHARACTER_KRIS][state];

if(_spr != -1 && !is_undefined(_spr))
        sprite_index = _spr;

switch(state)
{
        case IDLE:
                image_speed = 1;
                break;

        case HURT:
                image_speed = 1;
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
                // (MUELLES): frames de subida/bajada configurados con la
                // Suite (global.fallAnims en scr_survivors.gml)
                scr_fall_anim();
                break;

        case RUN:
        case JUMP:
                image_speed = 1;
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
                image_speed = 1;
                break;

        case EMOTION1:
        case EMOTION2:
        case EMOTION3:
                image_speed = 1;
                break;
}