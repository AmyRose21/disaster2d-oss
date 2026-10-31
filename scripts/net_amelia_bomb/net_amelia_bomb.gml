// =====================================================================
//  v2.2 — AMELIA: pide al server plantar la BOMBA en (xx, yy).
//  El server valida, spawnea la entidad AmeliaBomb (mecha 5 s) y la
//  reenvia a todos como SERVER_AMELIA_BOMB_STATE 0; explota sola
//  (mecha) o cuando el killer la toca (CLIENT_AMELIA_BOMB_BOOM) con
//  SERVER_AMELIA_BOMB_STATE 2.
//  (betterserver-oss: states/Game.c, entities/AmeliaBomb.c)
// =====================================================================
function net_amelia_bomb(xx, yy)
{
        var packet = cpacket_tcp(PacketType.CLIENT_AMELIA_BOMB);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        send_server_tcp(packet);
}

// La bomba exploto en el cliente del killer (la toco): avisar al
// server para que la reviente a todos.
function net_amelia_bomb_boom()
{
        var packet = cpacket_tcp(PacketType.CLIENT_AMELIA_BOMB_BOOM);
        send_server_tcp(packet);
}
