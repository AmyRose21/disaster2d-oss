// =====================================================================
//  v2.2/v2.9 — BLAZE: bola de fuego (tecla X). El server valida
//  (Blaze + cooldown anti-spam de 4 s), spawnea la entidad
//  BlazeFireball (vida max 4 s) y la reenvia a TODOS como
//  SERVER_BLAZE_FIREBALL_STATE 0 (con nid unico: desde v2.9 pueden
//  convivir varias). Luego la mueve cada tick (state 1: nid + pos +
//  dir + vy, con gravedad integrada por el server) y la retira al
//  agotarse o dar a alguien (state 2 por nid, o CLIENT_BLAZE_
//  FIREBALL_HIT del cliente tocado).
//
//  v2.9: PROYECTIL REBOTANTE. El server no tiene la colision del
//  mapa, asi que el rebote lo reporta CUALQUIER cliente que vea el
//  choque contra obj_solid_parent: manda el nid, que componentes de
//  velocidad invertir (bit 0 = horizontal/pared, bit 1 =
//  vertical/suelo-o-techo) y la posicion del primer solape. El
//  server voltea la velocidad elasticamente y todos ven la nueva
//  trayectoria en el tick siguiente; el lockout del server ignora
//  los informes duplicados del mismo choque.
//
//  El stun al killer (2 s) lo aplica el cliente DEL KILLER cuando el
//  obj_blaze_fireball local lo toca (cada cliente es autoridad de su
//  propio jugador). (betterserver-oss: entities/BlazeFireball.c,
//  states/Game.c)
// =====================================================================
function net_blaze_fireball(xx, yy, dir)
{
        var packet = cpacket_tcp(PacketType.CLIENT_BLAZE_FIREBALL);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        buffer_write(packet, buffer_s8, dir);
        send_server_tcp(packet);
}

// El fuego toco al jugador local (killer): avisar al server CUAL fue
// (nid) para que despawnee esa y solo esa en todos.
function net_blaze_fireball_hit(nid)
{
        var packet = cpacket_tcp(PacketType.CLIENT_BLAZE_FIREBALL_HIT);
        buffer_write(packet, buffer_u16, nid);
        send_server_tcp(packet);
}

// El fuego choco contra el mapa VISTO POR ESTE CLIENTE (suelo, pared
// o techo): nid + flip (bit 0 = invertir horizontal, bit 1 = invertir
// vertical) + posicion del primer solape. El server aplica el primero
// que le llega de cualquier cliente.
function net_blaze_fireball_bounce(nid, flip, xx, yy)
{
        var packet = cpacket_tcp(PacketType.CLIENT_BLAZE_FIREBALL_BOUNCE);
        buffer_write(packet, buffer_u16, nid);
        buffer_write(packet, buffer_u8, flip);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        send_server_tcp(packet);
}
