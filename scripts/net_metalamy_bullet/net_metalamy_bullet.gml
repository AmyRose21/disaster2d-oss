// =====================================================================
//  v2.2 — METAL AMY (killer): bala del canon (tecla C). Mismo modelo
//  que el laser de Tails lado exe: el server valida (killer Metal Amy
//  + cooldown), spawnea la entidad MetalAmyBullet y la reenvia a
//  TODOS como SERVER_METALAMY_BULLET_STATE 0; la mueve cada tick
//  (state 1) y la retira al chocar (state 2 o CLIENT_METALAMY_BULLET_
//  HIT del cliente de la victima). El dano (20) lo aplica el cliente
//  DE LA VICTIMA (parry de Sonic puede desviarlo).
//  (betterserver-oss: entities/MetalAmyBullet.c)
// =====================================================================
function net_metalamy_bullet(xx, yy, dir)
{
        var packet = cpacket_tcp(PacketType.CLIENT_METALAMY_BULLET);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        buffer_write(packet, buffer_s8, dir);
        send_server_tcp(packet);
}

// La bala toco al jugador local (sobreviviente): avisar al server
// para que la despawnee en todos.
function net_metalamy_bullet_hit()
{
        var packet = cpacket_tcp(PacketType.CLIENT_METALAMY_BULLET_HIT);
        send_server_tcp(packet);
}
