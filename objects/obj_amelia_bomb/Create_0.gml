// =====================================================================
//  v2.2 — AMELIA: BOMBA (cliente). La mecha (5 s) la lleva el SERVER
//  (entities/AmeliaBomb.c) y al agotarse (o al pisarla el killer:
//  CLIENT_AMELIA_BOMB_BOOM desde aqui) reenvia SERVER_AMELIA_BOMB_
//  STATE 2 (boom) a todos: en cada cliente se ve la explosion y, si
//  el jugador LOCAL es del lado del EXE y esta a menos de 90 px, se
//  aplica su propio stun de 2 s (cada cliente es autoridad de su
//  jugador; ver el handler en net_state_game).
//  Este objeto solo lleva el visual de la mecha y detecta el pisoton
//  del killer.
// =====================================================================
fuse = 60 * 5;  // mecha visual (el server manda el boom real)
boomSent = false;

function amelia_bomb_boom()
{
        if(boomSent)
                return;

        boomSent = true;
        net_amelia_bomb_boom();
}
