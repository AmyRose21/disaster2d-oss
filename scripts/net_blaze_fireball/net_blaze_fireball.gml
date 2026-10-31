// =====================================================================
//  v2.2 — BLAZE: bola de fuego (tecla X). El server valida (Blaze +
//  cooldown), spawnea la entidad BlazeFireball y la reenvia a TODOS
//  (incluido el cliente de Blaze) como SERVER_BLAZE_FIREBALL_STATE 0;
//  luego la mueve cada tick (state 1) y la retira al chocar o salir
//  (state 2, o CLIENT_BLAZE_FIREBALL_HIT del cliente tocado).
//  Mismo modelo que el laser de Tails (net_projectile.gml): sin spawn
//  local, el server es la unica fuente de la verdad.
//  El stun al killer (2 s) lo aplica el cliente DEL KILLER cuando el
//  obj_blaze_fireball local lo toca (cada cliente es autoridad de su
//  propio jugador). (betterserver-oss: entities/BlazeFireball.c)
// =====================================================================
function net_blaze_fireball(xx, yy, dir)
{
        var packet = cpacket_tcp(PacketType.CLIENT_BLAZE_FIREBALL);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        buffer_write(packet, buffer_s8, dir);
        send_server_tcp(packet);
}

// El fuego toco al jugador local (killer): avisar al server para que
// lo despawnee en todos.
function net_blaze_fireball_hit()
{
        var packet = cpacket_tcp(PacketType.CLIENT_BLAZE_FIREBALL_HIT);
        send_server_tcp(packet);
}
