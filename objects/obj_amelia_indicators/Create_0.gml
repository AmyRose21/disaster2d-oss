// v4.5 — MARCA DE LA SALIDA de Amelia (version LIMITADA de los sensores
// de Amy Canon). Este objeto solo existe en el cliente de la propia
// Amelia (lo crea obj_amelia en su Create), asi que nadie mas ve esta
// flecha: cada cliente dibuja unicamente la suya. Misma convencion que
// obj_amycanon_indicators / obj_vanilla_indicators / obj_amelia_auras.
// Toda la pasiva es local: cero paquetes, cero servidor — informacion
// pura. Ver Draw_64 para el dibujado.
#macro AMELIA_EXIT_SENSE 720 // px: radio en el que Amelia "siente" la salida (v4.9: era 400)

depth = -200;

ringVisible = false; // flecha verde: hacia la SALIDA (anillo de escape)
ringAngle = 0;
