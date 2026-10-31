// =====================================================================
//  v2.2 — BLAZE: bola de fuego (cliente). La posicion la tick-ea el
//  SERVER (SERVER_BLAZE_FIREBALL_STATE 1 en net_state_game); este
//  objeto solo decide los contactos con el jugador LOCAL (cada
//  cliente es autoridad de su propio jugador):
//   * si el local es el killer / esbirro y lo toca -> stun 2 s
//     (canal estandar del laser de Tails) + hit al server.
//   * contra pared (obj_solid_parent) se rompe sola.
// =====================================================================
isBreaking = false;
dir = 1;
image_speed = 1;
isLocal = false;

_destroy = function()
{
        if(isBreaking)
                return;

        isBreaking = true;
        sprite_index = spr_blaze_fireball_exploid;
        image_index = 0;
        image_speed = 0.8;

        net_blaze_fireball_hit();
}
