global.ringFrame += 1 / 10.0;
if(global.ringFrame > 4)
        global.ringFrame = 0;

// v2.13 («Sol y Luna» — ECLIPSE): reloj de la ceguera del bando EXE
// de ESTE cliente (lo activa obj_amelia_trap al pisar una trampa de
// Amelia; el velo lo dibuja el Draw_64 de este mismo objeto).
if(global.eclipseTimer > 0)
        global.eclipseTimer--;

// v2.15 («La Torre» — Fleetway Amy): reloj de RESET de la reduccion de
// stun por flechas del EXE de este cliente. Si pasan 7 s sin recibir
// otro stun de flecha, el contador de stuns continuos vuelve a 0 (el
// proximo stun vuelve a durar los 3 s completos).
if(global.fwArrowStunDecay > 0)
{
        global.fwArrowStunDecay--;
        if(global.fwArrowStunDecay == 0)
                global.fwArrowStunStack = 0;
}