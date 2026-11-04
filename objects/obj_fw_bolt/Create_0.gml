// =====================================================================
//  v2.14 — FLEETWAY AMY: flecha de la ballesta (cliente). Vuelo RECTO
//  integrado por el server (SERVER_FWBOLT_STATE 1: pos). Este objeto
//  solo decide los contactos del lado de ESTE cliente (cada cliente
//  es autoridad de su propio jugador, como el laser de Tails):
//   * si el local es el killer / esbirro y lo toca:
//       - dmg 0 (Fleetway superviviente): stun 2 s
//       - dmg 20 (demonizada, revival >= 2): daño real
//   * contra el mapa (obj_solid_parent): se rompe (CLIENT_FWBOLT_HIT)
// =====================================================================
isOwner = false;
isBreaking = false;
dmg = 0;
image_speed = 1;

_destroy = function()
{
        if(isBreaking)
                return;

        isBreaking = true;
        image_speed = 1;
        net_fw_bolt_hit();
}
