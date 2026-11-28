// =====================================================================
//  v2.2 — METAL AMY (killer): bala del canon (cliente). Posicion
//  tick-eada por el server (SERVER_METALAMY_BULLET_STATE). Contactos
//  con el jugador LOCAL:
//   * si el local es un SOBREVIVIENTE y la toca -> 20 de dano
//     (exeSource=true: el parry de Sonic puede desviarlo) + hit.
//   * contra pared (obj_solid_parent) se rompe.
//  Mismo modelo que el laser de Tails del lado exe.
// =====================================================================
isBreaking = false;
// v99: nid del JUGADOR que disparo esta bala (la killer Metal Amy: el
// server ya tenia el owner guardado y ahora lo difunde en el spawn).
// Lo usa el zap del escudo electrico (scr_player_hurt con attackerNid:
// si la bala rompe un escudo electrico, el stun cae sobre su DUEÑO —
// el EXE mismo — igual que el laser de Tails con su tirador).
// deflected: la devolvio un parry (vuela hacia el bando del exe).
ownerNid = -1;
deflected = false;
dir = 1;
image_speed = 1;

_destroy = function()
{
        if(isBreaking)
                return;

        isBreaking = true;
        image_speed = 0;
        image_index = image_number - 1; // frame de impacto fijo

        net_metalamy_bullet_hit();
}
