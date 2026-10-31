// =====================================================================
//  v2.4/v2.8 — AMELIA: pide al server plantar la TRAMPA en (xx, yy).
//  El server valida (Amelia + cooldown anti-spam de 15 s) y la spawnea
//  como entidad AmeliaTrap (vida max 60 s), reenviada a TODOS los
//  clientes como SERVER_AMELIA_TRAP_STATE 0; a los 60 s la retira con
//  state 1. SIN limite de trampas vivas desde v2.8: cada colocacion es
//  su propia entidad con nid unico, asi que pueden convivir varias a
//  la vez (el ritmo lo marca la recarga del cliente: 35 s / 15 s
//  demonizada). Cuando alguien del lado del EXE pisa una, el cliente
//  de la victima avisa con CLIENT_AMELIA_TRAP_TRIGGER (nid = id de esa
//  entidad) y el server la revienta a todos con state 2.
//  (betterserver-oss: states/Game.c, entities/AmeliaTrap.c)
// =====================================================================
function net_amelia_trap(xx, yy)
{
        var packet = cpacket_tcp(PacketType.CLIENT_AMELIA_TRAP);
        buffer_write(packet, buffer_u16, xx);
        buffer_write(packet, buffer_u16, yy);
        send_server_tcp(packet);
}

// La trampa la piso yo (lado del EXE): avisar al server cual fue
// (nid) para que la reviente a todos (state 2: efecto + sonido en
// cada cliente; el stun + slow ya me los aplique en local).
function net_amelia_trap_trigger(nid)
{
        var packet = cpacket_tcp(PacketType.CLIENT_AMELIA_TRAP_TRIGGER);
        buffer_write(packet, buffer_u16, nid);
        send_server_tcp(packet);
}
