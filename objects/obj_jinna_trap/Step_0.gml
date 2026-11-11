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
        send_server_tcp(pak);
}
