/// @description Rouge - inicial
event_inherited();
// ---- identidad
scr_insert_id("rouge");
// ---- stats (mismas claves que los demas sobrevivientes)
spd = 4.5;              // velocidad base
jumpSpd = 12;           // impulso de salto
grav = 0.7;             // gravedad
maxFall = 15;
flyPow = 1.4;           // empuje de planeo
canFly = true;
dead = false;
stunned = 0;
hasZip = false;
// ---- animacion/estado
state = "idle";
facing = 1;
image_speed = 0.4;
image_xscale = 1;
// ---- ataques (Rouge: patada giratoria)
kickCd = 0;
kickCdMax = 30;
// ---- override del menu
scr_hud_target();
