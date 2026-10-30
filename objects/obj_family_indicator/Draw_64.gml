if(!visible)
        return;

if(!instance_exists(global.player))
        return;

// FLECHA AMARILLA (spr_sindicator3, 32x16 origin 3): PEGADA a la
// jugadora, girada hacia la otra (Vanilla -> Cream / Cream -> Vanilla).
draw_sprite_ext(spr_sindicator3, 0, ceil(global.player.x - obj_camera.x), ceil(global.player.y - obj_camera.y), 1, 1, famAngle, c_white, 1);
