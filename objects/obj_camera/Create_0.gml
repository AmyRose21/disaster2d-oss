/// @description Insert description here
// You can write your code in this editor
global.cameraMode = 0; //Follow player

target = noone;
prevMode = -1;
dist = 32;
look_timer = 0;
shake = false;
shakeTime = 0;
shakeMagnitude = 0;
shakeFade = 0.25;
spectatingInd = 0;
spectatingObj = noone;
locked = false;

// v1 OPTIONS MORE: estado del look-ahead horizontal (Options > More).
// laOffset es el desplazamiento actual; se suaviza hacia el objetivo con
// la TURN SPEED del jugador y se aplica solo en el modo follow (0).
laOffset = 0;

//setup viewport
view_camera[0] = camera_create_view(0, 0, 480, 270);
view_enabled[0] = true;
view_visible[0] = true;

x = floor(global.player.x) - 240;
y = floor(global.player.y) - 135;