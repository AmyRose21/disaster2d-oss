// =====================================================================
//  v2.2 — AMELIA: pide al server colocar la BANANA (resorte-trampa)
//  en (xx, yy). El server valida (Amelia + cooldown + in_game),
//  spawnea la entidad AmeliaBanana y la reenvia a todos como
//  SERVER_AMELIA_BANANA_STATE 0; a los 12 s la retira con state 1.
//  (betterserver-oss: states/Game.c case CLIENT_AMELIA_BANANA,
//  entities/AmeliaBanana.c)
// =====================================================================
function net_amelia_banana(xx, yy)
{
        var packet = cpacket_tcp(PacketType.CLIENT_AMELIA_BANANA);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        send_server_tcp(packet);
}
