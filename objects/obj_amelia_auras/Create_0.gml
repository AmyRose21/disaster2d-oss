// PASIVA AURAVISIÓN de Amelia (v2.12) — «los ojos de Nate».
// Este objeto SOLO existe en el cliente de la propia Amelia (lo crea
// obj_amelia en su Create), asi que nadie mas ve estas auras: cada
// cliente dibuja unicamente las suyas. Misma convencion que los
// sensores de Amy Canon (obj_amycanon_indicators).
// Toda la pasiva es local: cero paquetes, cero servidor, ni dano ni
// aturdimiento — informacion pura. Ver Draw_64 para el dibujado.
depth = -200;

// Fase del latido (las auras "respiran"; la del exe late mas rapido)
auraPulse = 0;

// Entidades del bando EXE dentro del radio de vision este frame:
//   auraExe == true  -> el EXE REAL (su aura arde mas fuerte)
//   auraExe == false -> esbirro demonizado o clone del exe (tenue)
// auraK = fuerza por distancia: 1 pegada a Amelia, 0 en el borde.
auraCount = 0;
auraX = array_create(16, 0);
auraY = array_create(16, 0);
auraR = array_create(16, 0);
auraK = array_create(16, 0);
auraExe = array_create(16, false);
auraInst = array_create(16, noone);
