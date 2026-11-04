// =====================================================================
//  v2.14 — FLEETWAY AMY: flecha de la ballesta (tecla C). Patron del
//  laser de Tails: el cliente de Fleetway pide el disparo con
//  CLIENT_FWBOLT (x, y, dir, dmg); el server valida (personaje + CD
//  anti-spam de 10 s), spawnea la entidad FwBolt (vuelo RECTO, sin
//  gravedad — la flecha de una ballesta no cae) y la reenvia a todos
//  como SERVER_FWBOLT_STATE 0. Cada tick la mueve y manda el estado 1
//  (x, y). Al agotarse o recibir CLIENT_FWBOLT_HIT la retira con el
//  estado 2. (betterserver-oss: entities/FwBolt.c, states/Game.c)
//
//  El efecto sobre el jugador tocado lo decide el cliente DE ESE
//  jugador (cada cliente es autoridad del suyo, como el laser):
//   * dmg 0 (superviviente): stun de 2 s al killer.
//   * dmg 20 (demonizada, revivalTimes >= 2): daño real.
// =====================================================================
function net_fw_bolt(xx, yy, dir, dmg)
{
        var packet = cpacket_tcp(PacketType.CLIENT_FWBOLT);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        buffer_write(packet, buffer_s8, dir);
        buffer_write(packet, buffer_u8, dmg);
        send_server_tcp(packet);
}

// La flecha toco algo solido o al jugador local: retirarla para todos.
function net_fw_bolt_hit()
{
        var packet = cpacket_tcp(PacketType.CLIENT_FWBOLT_HIT, true);
        send_server_tcp(packet);
}
