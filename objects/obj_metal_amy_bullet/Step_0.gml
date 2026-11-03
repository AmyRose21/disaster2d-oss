if(isBreaking)
{
        // la bala rota un instante y se va
        image_alpha -= 0.08;

        if(image_alpha <= 0)
                instance_destroy();

        return;
}

if(!instance_exists(global.player))
        return;

if(place_meeting(x, y, global.player))
{
        if(global.player.isDead)
                return;

        // dana al lado de los sobrevivientes (y a los esbirros no: la
        // bala es del killer, a los demonizados no les hace nada, igual
        // que el laser exe de Tails)
        if(global.character != CHARACTER_EXE && global.player.revivalTimes < 2)
        {
                // PARRY DE SONIC: la bala iba a golpear al jugador local
                // pero un Sonic con la ventana activa lo cubre -> se
                // desvia sin dano (regla del laser: proyectil = desvio)
                if(scr_parry_protects_me() != noone)
                        return;

                if(global.player.hurttime > 0)
                        return;

                // escudo de Sally: se rompe y salva
                if(global.character == CHARACTER_SALLY)
                {
                        if(global.player.shieldTimer > 0)
                        {
                                global.player.isHurt = true;
                                global.player.hurttime = 60;
                                global.player.shieldTimer = 0;

                                audio_play_sound(snd_sally_shieldbreak, 0, false);
                                net_quick_effect(global.player.x, global.player.y, global.player.revivalTimes >= 2 ? spr_shieldbreak2 : spr_shieldbreak, false, 1, 0, 0, 1);
                                net_sound_emit(snd_sally_shieldbreak);

                                // v4.8: MARCA DE DEBILIDAD — el laser callo en el
                                // escudo, igual fue un golpe de Metal Amy
                                scr_weak_mark_hit();

                                _destroy();
                                return;
                        }

                        global.player.isSliding = false;
                }

                // =====================================================
                //  v4.8 — EJECUCION DE LOS DEBILES (pasiva 1): si la
                //  victima esta por debajo del 30% de vida y el laser la
                //  toca, cae derribada DIRECTAMENTE (el flujo completo de
                //  una vida a cero: agonia, revive posible). NO aplica a:
                //  quien ya cayo una vez (revivalTimes >= 1: ese es el
                //  "efecto de moribundo" del que habla el usuario), ni a
                //  los personajes con pasivas de revivir solos (Vanilla,
                //  Sonic, Amy Canon, Sally Canon), ni a Amelia (fuera de
                //  la ecuacion). Los excluidos comen el dano normal.
                // =====================================================
                var _exec = (global.player.hp < METALAMY_EXEC_HP
                && global.player.revivalTimes == 0
                && global.character != CHARACTER_VANILLA
                && global.character != CHARACTER_SONIC
                && global.character != CHARACTER_AMY_CANON
                && global.character != CHARACTER_SALLY_CANON
                && global.character != CHARACTER_AMELIA);

                if(_exec)
                {
                        // stats: reportar el dano como TODA la vida que le
                        // quitaba (mismo par de paquetes del golpe normal,
                        // con el hp ANTES de tirarla a cero)
                        if(instance_exists(obj_player_puppet))
                        {
                                with(obj_player_puppet)
                                {
                                        if(character != CHARACTER_EXE || exeCharacter != EXE_METALAMY)
                                                continue;

                                        var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS);
                                        buffer_write(pak, buffer_u16, master_id);
                                        buffer_write(pak, buffer_u8, 2);
                                        send_server_tcp(pak);

                                        var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                        buffer_write(buffer, buffer_u8, 2);
                                        buffer_write(buffer, buffer_u16, master_id);
                                        buffer_write(buffer, buffer_u16, global.player.hp);
                                        buffer_write(buffer, buffer_u16, 0);
                                        send_server_tcp(buffer);
                                        break;
                                }
                        }

                        var pak = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                        buffer_write(pak, buffer_u8, 3);
                        buffer_write(pak, buffer_u8, global.player.hp);
                        send_server_tcp(pak);

                        // v4.8: la marca entra igual (fue golpeada por el laser)
                        scr_weak_mark_hit();

                        scr_player_instakill();

                        _destroy();
                        return;
                }

                // dano: 20 (exeSource: el parry ya fue chequeado arriba)
                scr_player_hurt(20, -sign(x - global.player.x) * 4, 2, snd_hurt, spr_blood1, false, true);

                // v4.8: MARCA DE DEBILIDAD (pasiva 2) — el golpe del laser callo
                // (scr_player_hurt ya paso parry/i-frames/escudo, y la vida bajo o
                // quedo marcada por el golpe: isHurt). Cero si el dano fue negado.
                if(global.player.isHurt || global.player.hp <= 0)
                        scr_weak_mark_hit();

                // stats: reportar el golpe para el Metal Amy remoto
                // (modo 2 = dano infligido: atacante = master_id del
                // puppet del Metal Amy, igual que el flujo del golpe
                // del exe en obj_egg/Step_0)
                if(instance_exists(obj_player_puppet))
                {
                        with(obj_player_puppet)
                        {
                                if(character != CHARACTER_EXE || exeCharacter != EXE_METALAMY)
                                        continue;

                                var pak = cpacket_tcp(PacketType.CLIENT_MERCOIN_BONUS);
                                buffer_write(pak, buffer_u16, master_id);
                                buffer_write(pak, buffer_u8, 2);
                                send_server_tcp(pak);

                                var buffer = cpacket_tcp(PacketType.CLIENT_STATS_REPORT);
                                buffer_write(buffer, buffer_u8, 2);
                                buffer_write(buffer, buffer_u16, master_id);
                                buffer_write(buffer, buffer_u16, 20);
                                buffer_write(buffer, buffer_u16, global.player.hp);
                                send_server_tcp(buffer);
                                break;
                        }
                }

                _destroy();
                return;
        }
}
