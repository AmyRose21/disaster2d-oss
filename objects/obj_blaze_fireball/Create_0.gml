// =====================================================================
//  v2.2/v2.9 — BLAZE: bola de fuego (cliente). La fisica la integra
//  el SERVER (SERVER_BLAZE_FIREBALL_STATE 1 en net_state_game: pos +
//  dir + vy, con gravedad); este objeto solo decide los contactos del
//  lado de ESTE cliente (cada cliente es autoridad de su propio
//  jugador):
//   * si el local es el killer / esbirro y lo toca -> stun 2 s
//     (canal estandar del laser de Tails) + hit al server (por nid).
//   * contra el mapa (obj_solid_parent) NO se rompe: REBOTA. Este
//     cliente clasifica la superficie (pared = invertir horizontal,
//     suelo/techo = invertir vertical) y se lo cuenta al server
//     (CLIENT_BLAZE_FIREBALL_BOUNCE); el voltea la velocidad y toda
//     la partida ve la nueva trayectoria. El throttle local evita
//     spamear el mismo choque mientras llega el arreglo.
// =====================================================================
nid = -1;        // id de la entidad del server (por bola)
dir = 1;
vx = 10;         // velocidad que nos dijo el ultimo tick (para clasificar)
vy = 0;
bounceCd = 0;    // throttle local de informes de rebote
image_speed = 1;
isBreaking = false;
isLocal = false;

_destroy = function(sendHit = true)
{
        if(isBreaking)
                return;

        isBreaking = true;
        sprite_index = spr_blaze_fireball_exploid;
        image_index = 0;
        image_speed = 0.8;
        image_angle = 0; // la explosion siempre derecha

        // sendHit: solo cuando la toca el jugador local (el despawn
        // del server ya la retiro de su lado; los demas clientes solo
        // reproducen la explosion)
        if(sendHit)
                net_blaze_fireball_hit(nid);
}
