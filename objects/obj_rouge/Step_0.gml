/// @description Rouge - logica
if (dead) { sprite_index = spr_rouge_dead; image_speed = 0.3; exit; }

// cooldowns
if (kickCd > 0) kickCd--;

// input
var mv = (keyboard_check(vk_right) || keyboard_check(ord("D")))
       - (keyboard_check(vk_left) || keyboard_check(ord("A")));
var jumph = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
var flyh = keyboard_check(vk_space) || keyboard_check(vk_up) || keyboard_check(ord("W"));

// horizontal
if (mv != 0) {
    facing = mv;
    hspd = approach(hspd, mv * spd, 0.8);
} else {
    hspd = approach(hspd, 0, 1.2);
}

// salto y planeo (Rouge vuela: mantener en el aire da empuje suave)
if (place_meeting(x, y + 1, obj_solid)) {
    vspd = min(vspd + grav, maxFall);
    if (jumph) vspd = -jumpSpd;
    hasZip = false;
} else {
    var gliding = flyh && vspd > -2 && canFly;
    vspd = min(vspd + (gliding ? -flyPow : grav), maxFall);
}

// fisica
phy_hspd = hspd;
phy_vspd = vspd;

// animacion por estado
if (place_meeting(x, y + 1, obj_solid)) {
    if (abs(hspd) > spd * 0.5) { state = "run";  sprite_index = spr_rouge_run; }
    else                        { state = "idle"; sprite_index = spr_rouge_idle; image_speed = 0.25; }
} else {
    if (vspd < 0)      { state = "jump"; sprite_index = spr_rouge_jump; }
    else if (flyh)     { state = "fly";  sprite_index = spr_rouge_fly;  image_speed = 0.5; }
    else               { state = "fall"; sprite_index = spr_rouge_fall; }
}
if (stunned > 0) { stunned--; sprite_index = spr_rouge_hurt; }

image_xscale = facing;
