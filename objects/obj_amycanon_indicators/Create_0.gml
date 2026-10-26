// Sensores pasivos de AMY CANON (sus 2 flechas de detector).
// Este objeto solo existe en el cliente de la propia Amy Canon
// (lo crea obj_amy_canon en su Create), asi que nadie mas ve estas
// flechas: cada cliente dibuja unicamente las suyas.
depth = -200;

ringVisible = false; // flecha verde: hacia la SALIDA (anillo de escape)
ringAngle = 0;
exeVisible = false;  // flecha ROJA (spr_indicator): hacia el EXE real
exeAngle = 0;