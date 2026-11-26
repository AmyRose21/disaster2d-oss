// v84 (blindaje): si la Amelia que me creo ya no existe, me apago sola —
// nunca queda un objeto huerfano sensando y dibujando auras de una
// partida que ya recambio a su jugador local.
if(auraOwner != noone && !instance_exists(auraOwner))
{
        instance_destroy();
        return;
}

if(!instance_exists(global.player))
{
        auraCount = 0;
        visible = false;
        return;
}

// El latido avanza siempre (así no se "congela" entre frames sin
// entidades cerca ni al reaparecer la partida).
auraPulse += AMELIA_AURA_PULSE_SPD;

// Amelia demonizada (revivalTimes >= 2): pasa al bando del EXE y el
// juego ya le da la flecha estandar que apunta al exe
// (obj_demon_indicator), asi que sus auras se apagan para no
// duplicarla. Misma red de seguridad que los sensores de Amy Canon.
// v84: lectura protegida (patron del repo: variable_instance_exists
// antes de leer con punto una variable de otra instancia).
var _demon = false;
if(variable_instance_exists(global.player.id, "revivalTimes"))
        _demon = global.player.revivalTimes >= 2;

if(_demon)
{
        auraCount = 0;
        visible = false;
        return;
}

auraCount = 0;

// v84: tope real de slots = min(macros, arrays). El ORDEN tambien es
// nuevo: dos pasadas sobre los puppets — primero el EXE REAL, luego el
// resto — asi que si un mapa trae 16+ esbirros el tope JAMAS desaloja
// al exe de la lista (la firma que mas importa leer).
var _max = min(AMELIA_AURA_MAX, array_length(auraX));

// --- SENSOR AURAVISIÓN: bando EXE dentro del radio, A TRAVÉS de las
// paredes (se dibuja en GUI por encima del mundo). Amelia ve firmas
// de CALOR: solo arden los del lado del EXE —
//   * el EXE REAL (puppet con character == CHARACTER_EXE): su aura
//     arde MAS FUERTE, como el impostor de su historia, que se
//     delató con un aura más brillante;
//   * esbirros (puppet demonizado: revivalTimes >= 2) y clones del
//     exe (obj_exeller_clone): silueta tenue.
// Los supervivientes no arden: nada que dibujar para ellos. Un EXE
// escondido o invisible sigue ardiendo (el calor no se esconde).
if(instance_exists(obj_player_puppet))
{
        var _n = instance_number(obj_player_puppet);

        for(var _pass = 0; _pass < 2; _pass++)
        {
                for(var i = 0; i < _n; i++)
                {
                        if(auraCount >= _max)
                                break;

                        var inst = instance_find(obj_player_puppet, i);

                        // v84 (blindaje): todo lo que se lee del puppet va
                        // detras de su guard de existencia.
                        if(inst == noone || !instance_exists(inst))
                                continue;

                        if(!variable_instance_exists(inst.id, "isInactive") || inst.isInactive)
                                continue;

                        if(!variable_instance_exists(inst.id, "character"))
                                continue;

                        var _isExe = (inst.character == CHARACTER_EXE);

                        // pasada 0 = SOLO el exe real; pasada 1 = el resto
                        if(_pass == 0 && !_isExe)
                                continue;

                        if(_pass == 1 && _isExe)
                                continue;

                        if(!_isExe && (!variable_instance_exists(inst.id, "revivalTimes") || inst.revivalTimes < 2))
                                continue; // superviviente: sin aura

                        var _d = point_distance(global.player.x, global.player.y, inst.x, inst.y);
                        if(_d > AMELIA_AURA_RADIUS)
                                continue;

                        auraX[auraCount] = inst.x;
                        auraY[auraCount] = inst.y;
                        auraR[auraCount] = _isExe ? AMELIA_AURA_EXE_R : AMELIA_AURA_MINION_R;
                        auraK[auraCount] = 1 - (_d / AMELIA_AURA_RADIUS);
                        auraExe[auraCount] = _isExe;
                        auraInst[auraCount] = inst;

                        // v84: frio = aturdido o caido. El exe viaja con su
                        // propio enum (EXE_SHOCKED aturdido en tierra /
                        // EXE_LOST vencido); los esbirros, con DEAD. Una
                        // firma fria es una amenaza neutralizada: aura azul
                        // y sin latido (lectura tactica nueva).
                        var _st = 0;
                        if(variable_instance_exists(inst.id, "state"))
                                _st = inst.state;

                        if(_isExe)
                                auraCold[auraCount] = (_st == EXE_SHOCKED || _st == EXE_LOST);
                        else
                                auraCold[auraCount] = (_st == DEAD);

                        // v84: destello de entrada — el slot venia apuntando
                        // a otra firma (o vacio): es un contacto NUEVO y
                        // brilla un instante mas (Draw_64).
                        if(auraId[auraCount] != inst.id)
                        {
                                auraId[auraCount] = inst.id;
                                auraFlash[auraCount] = AMELIA_AURA_FLASH;
                        }
                        else if(auraFlash[auraCount] > 0)
                                auraFlash[auraCount]--;

                        auraCount++;
                }
        }
}

// Clones del exe (obj_exeller_clone): tambien bando EXE, silueta
// tenue. No son obj_player_puppet (los enumera aparte el amycanon),
// asi que van en su propia pasada. Mismo radio y misma regla.
if(instance_exists(obj_exeller_clone))
{
        var _nc = instance_number(obj_exeller_clone);

        for(var i = 0; i < _nc; i++)
        {
                if(auraCount >= _max)
                        break;

                var cl = instance_find(obj_exeller_clone, i);

                if(cl == noone || !instance_exists(cl))
                        continue;

                var _d = point_distance(global.player.x, global.player.y, cl.x, cl.y);
                if(_d > AMELIA_AURA_RADIUS)
                        continue;

                auraX[auraCount] = cl.x;
                auraY[auraCount] = cl.y;
                auraR[auraCount] = AMELIA_AURA_MINION_R;
                auraK[auraCount] = 1 - (_d / AMELIA_AURA_RADIUS);
                auraExe[auraCount] = false;
                auraInst[auraCount] = cl;
                auraCold[auraCount] = false;

                if(auraId[auraCount] != cl.id)
                {
                        auraId[auraCount] = cl.id;
                        auraFlash[auraCount] = AMELIA_AURA_FLASH;
                }
                else if(auraFlash[auraCount] > 0)
                        auraFlash[auraCount]--;

                auraCount++;
        }
}

// v84: slots libres — limpiar restos del frame anterior para que el
// Draw no herede siluetas muertas ni destellos colgados.
for(var _cl = auraCount; _cl < _max; _cl++)
{
        auraInst[_cl] = noone;
        auraId[_cl] = noone;
        auraFlash[_cl] = 0;
}

// NOTA v4.7: este objeto SOLO dibuja las AURAS de calor. La MARCA DE
// LA SALIDA (flecha verde) vive en su propio objeto obj_amelia_indicators.

// Como obj_amycanon_indicators: el evento Draw GUI de este objeto
// solo corre cuando visible esta en true, asi que hay que encenderlo
// cada frame que haya al menos un aura que dibujar (y apagarlo cuando
// no). Sin esto el objeto nace con visible = false (ver su .yy) y
// las auras nunca se dibujan.
visible = (auraCount > 0);
