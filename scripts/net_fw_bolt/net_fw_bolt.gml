// =====================================================================
//  v2.14 — FLEETWAY AMY: flecha de la ballesta (tecla C). Patron del
//  laser de Tails: el cliente de Fleetway pide el disparo con
//  CLIENT_FWBOLT (x, y, dir, dmg); el server valida (personaje + CD
//  anti-spam), spawnea la entidad FwBolt (vuelo RECTO, sin gravedad
//  — la flecha de una ballesta no cae) y la reenvia a todos como
//  SERVER_FWBOLT_STATE 0. Cada tick la mueve y manda el estado 1
//  (x, y) por el canal NO fiable (UDP). Al agotarse o recibir
//  CLIENT_FWBOLT tipo 0 la retira con el estado 2.
//  (betterserver-oss: entities/FwBolt.c, states/Game.c)
//
//  v2.15 («La Torre»):
//   - CLIENT_FWBOLT_HIT (u16 id, u8 tipo, u16 x, u16 y): la flecha
//     toco algo. tipo 0 = se rompio (toco al bando EXE); tipo 1 = se
//     CLAVO en un solido en (x, y) -> el server la convierte en
//     plataforma 5 s (estado 3 para todos).
//   - La municion (3 flechas, recarga 8 s, 0,5 s entre disparos) la
//     lleva el cliente (scr_amy_fleetway_special); el server solo
//     respalda el limite (max 3 vivas + CD de 0,5 s).
//
//  El efecto sobre el jugador tocado lo decide el cliente DE ESE
//  jugador (cada cliente es autoridad del suyo, como el laser):
//   * dmg 0 (superviviente): stun de 3 s al killer (con reduccion
//     acumulativa por stuns continuos; esbirros siempre 3 s).
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

// La flecha toco algo solido o al jugador local:
//   tipo 0 = romperse (despawn para todos)
//   tipo 1 = clavarse en (xx, yy) y quedar como plataforma 5 s
function net_fw_bolt_hit(fwid, tipo, xx, yy)
{
        var packet = cpacket_tcp(PacketType.CLIENT_FWBOLT_HIT, true);
        buffer_write(packet, buffer_u16, fwid);
        buffer_write(packet, buffer_u8, tipo);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        send_server_tcp(packet);
}
