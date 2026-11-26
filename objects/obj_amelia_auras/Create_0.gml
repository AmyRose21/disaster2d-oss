// PASIVA AURAVISIÓN de Amelia (v2.12) — «los ojos de Nate».
// Este objeto SOLO existe en el cliente de la propia Amelia (lo crea
// obj_amelia en su Create), asi que nadie mas ve estas auras: cada
// cliente dibuja unicamente las suyas. Misma convencion que los
// sensores de Amy Canon (obj_amycanon_indicators).
// Toda la pasiva es local: cero paquetes, cero servidor, ni dano ni
// aturdimiento — informacion pura. Ver Draw_64 para el dibujado.
// v84 (QoL + blindaje): auraOwner (la Amelia que me creo: si esa
// instancia desaparece, me apago sola en el Step), lectura de frio
// (aturdido/caido), destello de entrada y marcador de borde (Draw_64),
// y arrays al tamano de AMELIA_AURA_MAX en vez de un 16 suelto.
depth = -200;

// La Amelia que me creo (id de instancia) o noone.
auraOwner = noone;

// Fase del latido (las auras "respiran"; la del exe late mas rapido)
auraPulse = 0;

// Entidades del bando EXE dentro del radio de vision este frame:
//   auraExe == true  -> el EXE REAL (su aura arde mas fuerte)
//   auraExe == false -> esbirro demonizado o clone del exe (tenue)
// auraK = fuerza por distancia: 1 pegada a Amelia, 0 en el borde.
// auraCold == true  -> v84: aturdido o caido (exe en EXE_SHOCKED /
//                      EXE_LOST, esbirro en DEAD): aura FRIA (azul).
// auraId/auraFlash  -> v84: firma vista en el slot el frame anterior
//                      y destello de entrada al detectar una nueva.
auraCount = 0;
auraX = array_create(AMELIA_AURA_MAX, 0);
auraY = array_create(AMELIA_AURA_MAX, 0);
auraR = array_create(AMELIA_AURA_MAX, 0);
auraK = array_create(AMELIA_AURA_MAX, 0);
auraExe = array_create(AMELIA_AURA_MAX, false);
auraInst = array_create(AMELIA_AURA_MAX, noone);
auraCold = array_create(AMELIA_AURA_MAX, false);
auraId = array_create(AMELIA_AURA_MAX, noone);
auraFlash = array_create(AMELIA_AURA_MAX, 0);
