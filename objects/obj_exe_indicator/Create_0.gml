target = noone;
depth = -200;
redRings = false;

// v4.8 (SCAN de Metal Amy): referencias a cada superviviente vivo
// mientras dura el revelado (las llena el Step_2; el Draw_64 dibuja sus
// siluetas a traves de paredes/escondites, y fijadas al borde de la
// pantalla si estan fuera de la vista de 480x270)
scanList = 0;
scanCount = 0;

spring = false;
sprX = 0;
sprY = 0;

image_alpha = 0.7;