// =====================================================================
//  v2.9 — REBOTE contra el mapa (suelo, pared o techo). La bola ya
//  NO se rompe aqui (solo al tocar a un jugador del lado del EXE o
//  al retirarla el server): este cliente clasifica contra QUE se
//  choco mirando por donde puede escapar (retrocediendo a lo sumo
//  2 ticks de velocidad + margen, por si se perdio un tick del
//  server) y se lo cuenta al server, que voltea la velocidad:
//    * bit 0 (pared): invertir la horizontal.
//    * bit 1 (suelo/techo): invertir la vertical.
//  Todos los clientes ven el mismo choque: gana el primer informe
//  (lockout del server) y el throttle local (bounceCd) evita mandar
//  el mismo choque cada frame mientras llega el arreglo.
// =====================================================================
if(isBreaking)
        return;

if(bounceCd > 0)
        return;

var _flipX = false;
var _flipY = false;

if(vx != 0)
{
        var _bx = -sign(vx) * min(2 * abs(vx) + 4, 28);
        _flipX = !place_meeting(x + _bx, y, obj_solid_parent);
}

if(vy != 0)
{
        var _by = -sign(vy) * min(2 * abs(vy) + 4, 60);
        _flipY = !place_meeting(x, y + _by, obj_solid_parent);
}

// esquina (los dos liberan) -> invertir los dos; incrustada rara
// (ninguno libera) -> asumir vertical para no quedar clavada
if(!_flipX && !_flipY)
        _flipY = true;

var _flip = (_flipX ? 1 : 0) | (_flipY ? 2 : 0);

bounceCd = 15;

// chispa de fuego LOCAL en el punto del choque (cada cliente ve su
// propia colision: sin net_quick_effect aqui para no multiplicar el
// efecto por cliente)
scr_effect_quick(x, y, spr_shard_sparkle, 0.5, false, 0, 0);

net_blaze_fireball_bounce(nid, _flip, x, y);
