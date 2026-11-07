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

// FIX SCAN v4.9: la aguja (invisibilidad del EXE / anillo rojo / slime
// de Chaos) pasa a su PROPIA bandera. Hasta aqui esa informacion vivia
// en la variable `visible` del MOTOR, y como el indicador nace
// visible:false (el .yy), para Metal Amy nunca se encendia: en este
// runtime una instancia invisible NO ejecuta su Draw GUI, asi que las
// siluetas del scan — que no dependen de la aguja — jamas se dibujaban
// aunque scanList estuviera lleno (v4.8.1 arreglo el gate del Step_2
// pero el evento de dibujo seguia sin correr ni una vez). Ahora
// `visible` queda como puro interruptor del MOTOR (la enciende el
// Step_2 con la aguja O el scan) y `needle` decide si la aguja se
// dibuja, para que el scan no arrastre la flecha consigo.
needle = false;

spring = false;
sprX = 0;
sprY = 0;

image_alpha = 0.7;