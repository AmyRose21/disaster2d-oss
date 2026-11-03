if(!visible)
        return;

if(!instance_exists(global.player))
        return;

if(!ringVisible)
        return;

var _x = global.player.x;
var _y = global.player.y;

// FLECHA VERDE = la salida (spr_sindicator2, la misma 32x16 del juego
// base que usa Amy Canon): pegada a Amelia, rota hacia el anillo de
// escape. v4.5: PARPADEA (alpha pulsante, ~0,35-1,0) — marca debil para
// una ciega: le avisa de que la salida esta CERCA, sin brujula fija.
var _pulse = 0.35 + 0.65 * abs(sin(current_time / 380));
draw_sprite_ext(spr_sindicator2, 0, ceil(_x - obj_camera.x), ceil(_y - obj_camera.y), 1, 1, ringAngle, c_white, _pulse);
