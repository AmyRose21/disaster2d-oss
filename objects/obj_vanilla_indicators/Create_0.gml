// Sensores pasivos de VANILLA (sus 2 flechas de detector, los mismos
// que Amy Canon). Este objeto solo existe en el cliente de la propia
// Vanilla (lo crea obj_vanilla en su Create): nadie mas ve estas
// flechas, cada cliente dibuja unicamente las suyas.
depth = -200;

ringVisible = false; // flecha verde: hacia la SALIDA (anillo de escape)
ringAngle = 0;
exeVisible = false;  // flecha ROJA (spr_indicator): hacia el EXE real
exeAngle = 0;
