// Maquina de estados de Chocola (ver scr_chocola.gml para las macros
// y las senales de red). El sprite lo elige cada modo; en FOLLOW usa la
// MISMA posicion de las mascotas de la tienda (lerp + bob).
homeInst = scr_chocola_find_home();

if(homeInst == noone)
{
        instance_destroy();
        return;
}

if(guardTimer > 0)
        guardTimer--;

switch(mode)
{
        case CHOCOLA_FOLLOW:
        {
                // --- posicion de mascota (misma formula que obj_pet_*) ---
                image_xscale = homeInst.image_xscale;
                image_speed = 0.2 + distance_to_object(homeInst) / 150.0;

                if(homeInst == global.player)
                        image_alpha = homeInst.isHiding ? 0.5 : 1;
                else
                        image_alpha = homeInst.isHiding ? 0 : 1;

                if(distance_to_object(homeInst) > 200)
                {
                        x = homeInst.x - image_xscale * 32;
                        y = homeInst.y - 10;
                }

                x = lerp(x, homeInst.x - image_xscale * (homeInst.isHiding ? 16 : 32), 0.21);
                y = lerp(y, homeInst.y - 10 + sin(current_time / 500) * 5, 0.21);

                // --- sprite: quieta = Idle, Vanilla en movimiento = move ---
                if(supportTimer > 0)
                {
                        sprite_index = spr_vanilla_chocola_support_power;
                        image_speed = 0.5;
                        supportTimer--;
                }
                else
                {
                        // "en movimiento": xspd e yspd SI viajan por red al
                        // puppet (net_udpprocess: CLIENT_PLAYER_DATA), asi que
                        // la misma regla vale para la Vanilla local y para su
                        // puppet en las demas pantallas. isGrounded NO viaja:
                        // existe en el puppet solo por el default defensivo
                        // de su Create (antes leerlo ahi CRASHEABA el juego).
                        if(abs(homeInst.xspd) > 0.5 || abs(homeInst.yspd) > 0.5 || !homeInst.isGrounded)
                                sprite_index = spr_vanilla_chocola_move;
                        else
                                sprite_index = spr_vanilla_chocola_Idle;
                }

                break;
        }

        case CHOCOLA_HUNT:
        {
                // volando hacia el exe (acelerada). Sin exe en juego (o
                // caza demasiado larga): vuelve sin golpear.
                if(targetInst == noone || !instance_exists(targetInst) || huntTimer > VANILLA_PACIENCIA_HUNT_MAX)
                {
                        // solo la CAZA GRANDE (paciencia) descongela su timer
                        if(authority && !huntSmall)
                                scr_vanilla_paciencia_chocola_fail();

                        mode = CHOCOLA_RETURN;
                        break;
                }

                huntTimer++;
                sprite_index = spr_vanilla_chocola_move;
                image_speed = 0.5;

                var _dir = point_direction(x, y, targetInst.x, targetInst.y);
                x += lengthdir_x(VANILLA_CHOCOLA_HUNT_SPEED, _dir);
                y += lengthdir_y(VANILLA_CHOCOLA_HUNT_SPEED, _dir);

                if(targetInst.x != x)
                        image_xscale = sign(targetInst.x - x);

                if(distance_to_object(targetInst) < 20)
                {
                        // GOLPE: la autoridad manda la senal de stun al nid
                        // del exe (5 s en la caza grande, 1.5 s en la mini)
                        if(authority)
                        {
                                if(huntSmall)
                                        net_sound_emit_at(snd_vasebreak, targetInst.master_id);
                                else
                                {
                                        net_sound_emit_at(snd_nono, targetInst.master_id);
                                        scr_vanilla_paciencia_chocola_hit(); // descongela la paciencia
                                }

                                if(fromGuard)
                                        scr_chocola_guard_consume();
                        }

                        mode = CHOCOLA_ATTACK_PAUSE;
                        atkTimer = 26;
                        image_index = 0;
                }

                break;
        }

        case CHOCOLA_ATTACK_PAUSE:
        {
                sprite_index = spr_vanilla_chocola_attack;
                image_speed = 0.5;
                atkTimer--;

                if(atkTimer <= 0)
                        mode = CHOCOLA_RETURN;

                break;
        }

        case CHOCOLA_RETURN:
        {
                // vuelta rapida a casa
                sprite_index = spr_vanilla_chocola_move;
                image_speed = 0.5;

                var _rd = point_direction(x, y, homeInst.x, homeInst.y);
                x += lengthdir_x(VANILLA_CHOCOLA_RETURN_SPEED, _rd);
                y += lengthdir_y(VANILLA_CHOCOLA_RETURN_SPEED, _rd);

                if(homeInst.x != x)
                        image_xscale = sign(homeInst.x - x);

                if(distance_to_object(homeInst) < 24)
                        mode = CHOCOLA_FOLLOW;

                break;
        }

        case CHOCOLA_GO_CREAM:
        {
                // ida a velocidad NORMAL (no la acelerada de la caza)
                if(targetInst == noone || !instance_exists(targetInst))
                {
                        mode = CHOCOLA_RETURN;
                        break;
                }

                // Cream cayo o se demonizo a mitad del camino: vuelta
                if(targetInst.hp <= 0 || targetInst.revivalTimes >= 2)
                {
                        mode = CHOCOLA_RETURN;
                        break;
                }

                sprite_index = spr_vanilla_chocola_move;
                image_speed = 0.4;

                var _gd = point_direction(x, y, targetInst.x, targetInst.y);
                x += lengthdir_x(VANILLA_CHOCOLA_SPEED, _gd);
                y += lengthdir_y(VANILLA_CHOCOLA_SPEED, _gd);

                if(targetInst.x != x)
                        image_xscale = sign(targetInst.x - x);

                if(distance_to_object(targetInst) < 22)
                {
                        mode = CHOCOLA_GUARD;

                        // CURACION (15%) SOLO al llegar (la rolla el
                        // cliente de Cream: el es la autoridad de su hp)
                        if(targetInst == global.player && global.character == CHARACTER_CREAM)
                        {
                                if(random(100) < VANILLA_CHOCOLA_HEAL_CHANCE && !global.player.isDead && global.player.revivalTimes < 2 && global.player.hp < 100)
                                {
                                        global.player.hp = min(100, global.player.hp + VANILLA_CHOCOLA_HEAL_HP);
                                        audio_play_sound(snd_heal, 0, false);
                                        net_sound_emit(snd_heal);
                                }
                        }
                }

                break;
        }

        case CHOCOLA_GUARD:
        {
                // custodia junto a Cream: posicion de mascota
                if(targetInst == noone || !instance_exists(targetInst) || targetInst.hp <= 0 || targetInst.revivalTimes >= 2)
                {
                        mode = CHOCOLA_RETURN;
                        break;
                }

                image_xscale = targetInst.image_xscale;
                x = lerp(x, targetInst.x - image_xscale * 32, 0.21);
                y = lerp(y, targetInst.y - 10 + sin(current_time / 500) * 5, 0.21);
                sprite_index = spr_vanilla_chocola_Idle;
                image_speed = 0.3;

                // (cliente de Cream) ataque cercano al exe: 33%, stun de
                // 1.5 s, no si tiene i-frames. Cumplida la mision (stun o
                // bloqueo), Chocola vuelve con Vanilla.
                if(targetInst == global.player && global.character == CHARACTER_CREAM && guardTimer <= 0)
                {
                        var _gexe = scr_chocola_find_exe();

                        if(_gexe != noone && !_gexe.isHurt && distance_to_object(_gexe) < VANILLA_CHOCOLA_ATTACK_RANGE)
                        {
                                if(random(100) < VANILLA_CHOCOLA_ATTACK_CHANCE)
                                {
                                        mode = CHOCOLA_HUNT;
                                        huntSmall = true;
                                        fromGuard = true;
                                        authority = true;
                                        huntTimer = 0;
                                        targetInst = _gexe;

                                        // v2.1: anuncia la embestida por
                                        // red (snd_chocola_dive): el exe
                                        // y los demas la ven venir
                                        audio_play_sound(snd_chocola_dive, 0, false);
                                        net_sound_emit(snd_chocola_dive);
                                }
                                else
                                {
                                        guardTimer = VANILLA_CHOCOLA_PROX_CHECK; // re-roll en 0.5 s
                                }
                        }
                }

                break;
        }
}
