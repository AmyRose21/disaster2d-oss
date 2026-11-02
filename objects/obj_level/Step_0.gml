global.ringFrame += 1 / 10.0;
if(global.ringFrame > 4)
        global.ringFrame = 0;

// v2.13 («Sol y Luna» — ECLIPSE): reloj de la ceguera del bando EXE
// de ESTE cliente (lo activa obj_amelia_trap al pisar una trampa de
// Amelia; el velo lo dibuja el Draw_64 de este mismo objeto).
if(global.eclipseTimer > 0)
        global.eclipseTimer--;