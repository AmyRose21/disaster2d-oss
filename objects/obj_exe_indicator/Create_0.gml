target = noone;
depth = -200;
redRings = false;

// v4.8 (SCAN de Metal Amy): referencias a cada superviviente vivo
// mientras dura el revelado (las llena el Step_2; el Draw_64 dibuja sus
// siluetas a traves de paredes/escondites, y fijadas al borde de la
// pantalla si estan fuera de la vista de 480x270)
// FIX v4.8.1: array de verdad desde el Create (antes era un 0 al que el
// Step_2 le asignaba indices: la conversion real->array funciona pero es
// fragil; asi queda explicito).
scanList = [];
scanCount = 0;

spring = false;
sprX = 0;
sprY = 0;

image_alpha = 0.7;