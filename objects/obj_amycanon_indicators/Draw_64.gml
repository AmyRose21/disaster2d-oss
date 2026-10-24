if(!instance_exists(global.player))
	return;

if(!ringVisible && !exeVisible)
	return;

var _x = global.player.x;
var _y = global.player.y;

// FLECHA VERDE = la salida (anillo de escape): pegada a Amy, igual que el
// indicador del anillo del juego (spr_sindicator2 de obj_surv_ringindicator).
if(ringVisible)
	draw_sprite_ext(spr_sindicator2, 0, ceil(_x - obj_camera.x), ceil(_y - obj_camera.y), 1, 1, ringAngle, c_white, 1);

// FLECHA AZUL = el exe (sensor de eggman permanente): dibujada un poco mas
// lejos que la verde (24 px en la direccion del exe) para que nunca se
// tapen la una a la otra cuando apunten al mismo lado.
if(exeVisible)
{
	var a = degtorad(exeAngle);
	draw_sprite_ext(spr_sindicator, 0, ceil(_x + cos(a) * 24 - obj_camera.x), ceil(_y - sin(a) * 24 - obj_camera.y), 1, 1, exeAngle, c_white, 1);
}