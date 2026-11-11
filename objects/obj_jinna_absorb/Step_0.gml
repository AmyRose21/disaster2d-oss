// congelar a la victima ya (patron del agarre: quitar el control UNA
// sola vez si la ronda no lo habia quitado) y frenarla en seco
if(instance_exists(global.player))
{
        if(!tookControl && global.playerControls && !obj_netclient.gameEnds)
        {
                tookControl = true;
                global.playerControls = false;
        }

        with(global.player)
        {
                gspd = 0;
                xspd = 0;
                yspd = 0;
                isJumping = false;
                isAttacking = false;
                isSpinning = false;
                visible = false; // ya no es de este mundo: solo se ve la absorcion
        }
}

if(!absorbSnd)
{
        absorbSnd = true;
        audio_play_sound(snd_teleport, 0, false);
        net_sound_emit(snd_teleport);
        scr_camera_shake(16, 0.7, 0.15);
}

timer--;

// fase 0 -> 1: Vanilla ya desaparecio en el centro; el portal se encoge
if(phase == 0 && timer <= 0)
{
        phase = 1;
        timer = 30; // ~0,5 s de portal encogiendose
}

// fase 1 -> fin: fuera de juego (muerte directa, como los canon)
if(phase == 1 && timer <= 0)
{
        // si la ronda termino a mitad de la absorcion (p. ej. el EXE
        // mato al resto), el server ya esta fuera del estado de juego y
        // el paquete de muerte la desconectaria: no enviarlo
        if(!obj_netclient.gameEnds && instance_exists(global.player))
        {
                // mismo paquete que scr_player_instakill para el server:
                // muerte directa (Vanilla jamas se agonia ni se demoniza;
                // sus salvaciones de paciencia/moribunda NO aplican aqui)
                var pak = cpacket_tcp(PacketType.CLIENT_PLAYER_DEATH_STATE, false);
                buffer_write(pak, buffer_bool, true);
                buffer_write(pak, buffer_u8, global.player.revivalTimes);
                send_server_tcp(pak);

                global.cameraMode = 3;   // camara de espectador (UI de muerta)
                global.player.hp = 0;
                global.player.isDead = true;

                audio_play_sound(snd_dead, 0, false);
        }

        instance_destroy();
}
