/// scr_amy_super_hammer — v52 SUPER AMY: la SENAL del golpe del
/// HAMMER THROW. La rama shouldPlay del CLIENT_SOUND_EMIT (net_state_game)
/// la llama EN EL CLIENTE DEL OBJETIVO, igual que scr_lsa_stun_signal con
/// el rayo y scr_chocola_stun_signal con la mascota de Vanilla: la victima
/// se aturde a si misma (el modelo de confianza del juego, cero paquetes
/// nuevos).
///
/// LA REGLA DE LA DUEÑA: el martillo IGNORA i-frames — NO hay dedup contra
/// shockedTimer ni guard de hurttime (a diferencia del LSA, que respeta los
/// i-frames del objetivo): aunque el objetivo ya este inmune o aturdido,
/// el stun entra igual y REFRESCA a los 3.5 s completos (AMY_SUPER_HTHROW_STUN,
/// el mismo criterio de la patada duelista de Sally Canon F2). El golpe
/// canonico + grito suenan SIEMPRE (la leccion v2.1.4 de Chocola: nunca
/// pegar en silencio).
function scr_amy_super_hammer_signal()
{
        if(!instance_exists(global.player))
                return;

        var _exe = global.character == CHARACTER_EXE;
        var _esbirro = !_exe && global.player.revivalTimes >= 2;

        if(!_exe && !_esbirro)
                return;   // los supervivientes no se aturden con el martillo

        if(global.player.isDead)
                return;   // a un muerto no se le aplica nada

        // golpe canonico + grito, SIEMPRE
        audio_play_sound(snd_exe_stun, 0, false);
        net_sound_emit(snd_exe_stun);

        if(_exe)
                scr_exe_stunsound();
        else
        {
                net_quick_effect(global.player.x, global.player.y, spr_shockparticle, false, 1, 0, 0, 1);
                scr_camera_shake(30, 2, 0.25);
        }

        // IGNORA i-frames: el stun se aplica SIEMPRE y refresca completo
        with(global.player)
        {
                isAttacking = false;
                hurttime = 0;
                shockedTimer = AMY_SUPER_HTHROW_STUN;
                xspd = 0;
                yspd = -2;
                isGrounded = false;
        }

        // v17 (VIDA REAL DEL NEGA): el martillo de Super Amy es otro stun
        // de superviviente — al nega local le cuesta 20 de vida
        scr_jinna_negatouch_stun_hurt();

        // camara del golpeado (el mismo paquete que usan el LSA y Chocola)
        var _buffer = cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true);
        buffer_write(_buffer, buffer_u16, obj_netclient.nid);
        buffer_write(_buffer, buffer_u16, floor(global.player.x));
        buffer_write(_buffer, buffer_u16, floor(global.player.y));
        buffer_write(_buffer, buffer_u16, AMY_SUPER_HTHROW_STUN div 60);
        send_server_tcp(_buffer);
}