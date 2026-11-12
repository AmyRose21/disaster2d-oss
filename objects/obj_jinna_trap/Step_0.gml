// vida visual: si el server ya retiro la trampa (20 s) pero el paquete
// se perdio, desvanecer sola para no quedar colgada (patron Amelia)
life--;

if(life <= 0)
{
        image_alpha -= 0.05;

        if(image_alpha <= 0)
                instance_destroy();

        return;
}

// PISADA: solo el jugador LOCAL superviviente (cada cliente es la
// autoridad del suyo). El EXE, los esbirros (revival >= 2) y los muertos
// no la activan (quien ya escapo ni llega: su player se destruye al
// salir). SIN gate de hurttime: los i-frames no protegen de caer en la
// trampa (el dano igual entra y se remueven: ver el handler de
// SERVER_JINNA_TRAP_HIT).
if(!triggerSent && !obj_netclient.gameEnds && instance_exists(global.player)
&& global.character != CHARACTER_EXE && global.player.revivalTimes < 2
&& !global.player.isDead
&& point_distance(global.player.x, global.player.y - 8, x, y - 8) <= JINNA_TRAP_RADIUS)
{
        triggerSent = true;

        var pak = cpacket_tcp(PacketType.CLIENT_JINNA_TRAP_HIT, false);
        buffer_write(pak, buffer_u16, nid);
        buffer_write(pak, buffer_u16, obj_netclient.nid);

        // v4.5 (ROUGE): flag fatal al final del reporte. Su trampa hace
        // JINNA_TRAP_DAMAGE (30; 18/22 con tier activo) PISANDO i-frames,
        // y con 10+ anillos el golpe se absorbe (cuesta 10 anillos: ver
        // scr_player_hurt). El golpe la "mataria" (hp tras dano <= 0)
        // solo si: no le salvan los anillos Y (le queda la moribunda o
        // ya la gasto). En ese caso el server la ABSORBE (kind 4) en vez
        // del dano + TP. Un server viejo ignora el byte extra.
        if(global.character == CHARACTER_ROUGE)
        {
                var _jtrapDmg = (global.jinnaCaughtTier == JINNA_CAUGHT_VANILLA) ? 22 : ((global.jinnaCaughtTier == JINNA_CAUGHT_AMY) ? 18 : JINNA_TRAP_DAMAGE);
                var _ringAbsorb = global.player.rings >= 10;
                var _hpAfter = _ringAbsorb ? global.player.hp : (global.player.hp - _jtrapDmg);
                // en moribunda el golpe NO la tumbaria (esta salvandose ya):
                // trampa normal, sin absorcion
                var _fatal = (global.player.moribundaState <= 0 && _hpAfter <= 0) ? 1 : 0;
                buffer_write(pak, buffer_u8, _fatal);
        }

        send_server_tcp(pak);
}
