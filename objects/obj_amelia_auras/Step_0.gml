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
if(global.player.revivalTimes >= 2)
{
        auraCount = 0;
        visible = false;
        return;
}

auraCount = 0;

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
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
                if(auraCount >= 16)
                        break;

                var inst = instance_find(obj_player_puppet, i);

                if(inst.isInactive)
                        continue;

                var _isExe = (inst.character == CHARACTER_EXE);
                if(!_isExe && inst.revivalTimes < 2)
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
                auraCount++;
        }
}

// Clones del exe (obj_exeller_clone): tambien bando EXE, silueta
// tenue. No son obj_player_puppet (los enumera aparte el amycanon),
// asi que van en su propia pasada. Mismo radio y misma regla.
if(instance_exists(obj_exeller_clone))
{
        for(var i = 0; i < instance_number(obj_exeller_clone); i++)
        {
                if(auraCount >= 16)
                        break;

                var cl = instance_find(obj_exeller_clone, i);

                var _d = point_distance(global.player.x, global.player.y, cl.x, cl.y);
                if(_d > AMELIA_AURA_RADIUS)
                        continue;

                auraX[auraCount] = cl.x;
                auraY[auraCount] = cl.y;
                auraR[auraCount] = AMELIA_AURA_MINION_R;
                auraK[auraCount] = 1 - (_d / AMELIA_AURA_RADIUS);
                auraExe[auraCount] = false;
                auraInst[auraCount] = cl;
                auraCount++;
        }
}

// Como obj_amycanon_indicators: el evento Draw GUI de este objeto
// solo corre cuando visible esta en true, asi que hay que encenderlo
// cada frame que haya al menos un aura que dibujar (y apagarlo cuando
// no). Sin esto el objeto nace con visible = false (ver su .yy) y las
// auras nunca se dibujan.
visible = (auraCount > 0);
