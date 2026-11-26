// PASIVA AURAVISIÓN — dibujado (Draw GUI: por ENCIMA del mundo, así
// se ve A TRAVÉS de las paredes; posiciones en pantalla restando la
// cámara, como las flechas de obj_amycanon_indicators).
// Todo con mezcla aditiva (bm_add) para que las auras "ardiendo"
// iluminen lo que hay detrás, patrón del aura de parry de
// obj_player_puppet. Solo en la pantalla de la propia Amelia.
//
// v87 (REWORK VISUAL, SOLO dibujado): la firma se redibuja por CAPAS
// (macros AMELIA_AURA_* en scr_amelia_special). CERO cambios de
// sensado: Step_0 intacta, arrays intactos, radios y colores canon
// iguales; solo cambia CÓMO se pinta lo ya detectado.
//   A. DOMO TÉRMICO  — 2 círculos rellenos concéntricos (gradiente
//                      de calor; antes un halo plano de un solo tono).
//   B. ONDAS SONAR   — anillos que nacen del cuerpo y se apagan al
//                      expandirse: 3 el EXE (al doble de velocidad,
//                      como su latido), 2 el esbirro/clon. Cada firma
//                      va DESINCRONIZADA (fase estable = id mod 59:
//                      dos esbirros juntos no laten al unísono).
//   C. RETÍCULA      — aro principal + marcas que giran por fuera:
//                      8 al derecho el EXE, 4 AL REVÉS el esbirro
//                      (se lee quien es quien sin contar nada) y 6
//                      FIJAS la firma fría (el hielo no gira).
//   D. NÚCLEO        — solo el EXE real: punto caliente al centro.
//   E. SILUETA       — el fantasma de calor a través de las paredes;
//                      el EXE se dibuja en 2 capas (halo + núcleo).
//   F. PING          — contacto nuevo: un anillo expansivo único
//                      (rework del destello plano de la v84).
//   G. BORDE         — firma fuera de pantalla: CHEVRON DOBLE clavado
//                      en el borde (el del EXE más gordo: la firma
//                      grande se lee desde el otro lado de la
//                      pantalla) + PUNTOS DE CERCANÍA (1-3: más
//                      puntos = firma más cerca de Amelia).
//
// v88 (HOTFIX, solo este evento): el «id mod SEED» de v87 reventaba
// en runtimes 2023.8+ («DoMod :2: Malformed variable»: el id de
// instancia ya no es un real del VM, es un handle tipado — «typed
// references»). La fase por firma se calcula ahora por capas, sin
// aritmética sobre el id crudo (ver el bloque _seed). Cero cambios
// de sensado (Step_0 y Create_0 intactos), mismo look, mismas
// macros; solo este Draw cambia.
if(!visible)
        return;

if(!instance_exists(global.player) || auraCount <= 0)
        return;

if(!instance_exists(obj_camera))
        return;

var _cx = obj_camera.x;
var _cy = obj_camera.y;

// límites de la capa GUI con su margen: aquí vive el marcador de
// borde. display_get_gui_width/height = tamaño REAL de la capa GUI de
// este cliente, así que el clamp vale en cualquier resolución.
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ex0 = AMELIA_AURA_EDGE;
var _ex1 = _gw - AMELIA_AURA_EDGE;
var _ey0 = AMELIA_AURA_EDGE;
var _ey1 = _gh - AMELIA_AURA_EDGE;

gpu_set_blendmode(bm_add);
draw_set_circle_precision(32);

var _n = min(auraCount, array_length(auraX));

for(var i = 0; i < _n; i++)
{
        var _sx = ceil(auraX[i] - _cx);
        var _sy = ceil(auraY[i] - _cy);
        var _ay = _sy - 6;

        // la entidad pudo morir/salir del mapa entre el Step y aquí
        var _inst = auraInst[i];
        if(_inst != noone && !instance_exists(_inst))
                _inst = noone;

        // frío = aturdido/caído: sin ondas y en AZUL, retícula
        // congelada — una firma fría es una amenaza neutralizada,
        // se lee de un vistazo.
        var _cold = auraCold[i];

        // v87: fase estable POR FIRMA (su id de instancia, id mod
        // AMELIA_AURA_SEED): las ondas sonar de varias firmas
        // cercanas NO viajan sincronizadas, y la desincronía no
        // cambia entre frames (el id no cambia).
        // v88 (fix del crash v87: «DoMod :2: Malformed variable»):
        // desde el runtime 2023.8 las instancias usan HANDLES tipados
        // («typed references»), no enteros, y el `mod` del VM solo
        // traga reales — reventaba justo al dibujar la primera firma.
        // La fase se calcula SIN aritmética sobre el id crudo, por
        // capas (runtimes viejos incluidos):
        //   * real puro  -> mod directo, igual que v87;
        //   * int64      -> real() antes del mod;
        //   * handle     -> los DÍGITOS de su texto (el runner imprime
        //                   el número del id; se corta en el primer
        //                   carácter no dígito, así nunca se tragan
        //                   valores que cambian entre frames);
        //   * otra cosa  -> fase por SLOT: distinta entre firmas (dos
        //                   juntas nunca laten al unísono, la promesa
        //                   de v87) y sin crash NUNCA.
        var _eid = auraId[i];
        if(is_undefined(_eid) || is_string(_eid) || _eid == noone || _eid < 0)
                _eid = 0;

        var _seed = 0;
        var _seedOk = false;

        if(is_real(_eid))
        {
                _seed = (_eid mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;
                _seedOk = true;
        }
        else if(is_int64(_eid))
        {
                _seed = (real(_eid) mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;
                _seedOk = true;
        }
        else if(is_handle(_eid))
        {
                // solo los primeros dígitos del texto: el número del
                // id, jamás un dump de variables (x/y se mueven)
                var _h = 0;
                var _s = string(_eid);
                var _sl = string_length(_s);

                for(var c = 1; c <= _sl; c++)
                {
                        var _d = ord(string_char_at(_s, c));

                        if(_d < 48 || _d > 57)
                                break;

                        _h = (_h * 10 + _d - 48) mod AMELIA_AURA_SEED;
                }

                if(_h > 0)
                {
                        _seed = _h / AMELIA_AURA_SEED;
                        _seedOk = true;
                }
        }

        if(!_seedOk)
                _seed = ((i * 37) mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;

        // destello de entrada (contacto nuevo: alimenta el ping)
        var _fl = 0;
        if(auraFlash[i] > 0)
                _fl = auraFlash[i] / AMELIA_AURA_FLASH;

        // latido: solo respira el aro del EXE real (late al doble);
        // frío = congelado, sin latido.
        var _beat = sin(auraPulse * (auraExe[i] ? 2 : 1));
        if(_cold)
                _beat = 0;

        var _r = auraR[i] + _beat * (auraExe[i] ? AMELIA_AURA_EXE_PULSE_AMP : AMELIA_AURA_MINION_PULSE_AMP) + _fl * 2;

        // fuerza por distancia: 1 pegada a Amelia, 0 justo en el
        // borde del radio. El borde del ALCANCE se cruza suave
        // (smoothstep sobre el último tramo), no de golpe.
        var _e = auraK[i] / AMELIA_AURA_EDGE_FADE;
        if(_e < 0)
                _e = 0;

        if(_e > 1)
                _e = 1;

        var _k = (0.3 + 0.7 * auraK[i]) * (_e * _e * (3 - 2 * _e)) + _fl * 0.5;
        if(_k > 1)
                _k = 1;

        // colores: exe arde más; esbirros/clones tenues; frío = azul
        var _colHalo = auraExe[i] ? AMELIA_AURA_EXE_COLOR : AMELIA_AURA_MINION_COLOR;
        var _colCore = auraExe[i] ? AMELIA_AURA_EXE_CORE : AMELIA_AURA_MINION_COLOR;

        if(_cold)
        {
                _colHalo = AMELIA_AURA_COLD_COLOR;
                _colCore = AMELIA_AURA_COLD_CORE;
        }

        // v87: firma DENTRO de la vista -> aura completa + silueta;
        // FUERA -> chevron en el borde apuntando hacia ella desde la
        // propia Amelia (el calor no se esconde, pero la pantalla sí
        // se acaba).
        var _onscreen = (_sx >= _ex0 && _sx <= _ex1 && _sy >= _ey0 && _sy <= _ey1);

        if(_onscreen)
        {
                var _isExe = auraExe[i];

                // --- A. DOMO TÉRMICO: gradiente de 2 capas ---
                // Exterior tenue + interior más brillante: sin
                // sprites ni shaders, un círculo dentro del otro.
                draw_set_color(_colHalo);
                draw_set_alpha(0.05 * _k);
                draw_circle(_sx, _ay, _r, false);

                var _dome = 0.10 * _k;

                if(_isExe)
                        _dome += 0.05 * _beat * _k;

                draw_set_alpha(_dome);
                draw_circle(_sx, _ay, _r * 0.62, false);

                // --- B. ONDAS SONAR: anillos que nacen del cuerpo,
                // se expanden hasta AMELIA_AURA_RIPPLE_SPREAD px más
                // allá del aro y se apagan con el cuadrado de lo que
                // les queda de vida. Frío = congelado: NINGUNA.
                if(!_cold)
                {
                        var _waves = AMELIA_AURA_RIPPLES_MINION;
                        var _wa = AMELIA_AURA_RIPPLE_A_MINION * _k;
                        var _colWave = _colHalo;
                        var _wspd = AMELIA_AURA_PULSE_SPD / (pi * 2);

                        if(_isExe)
                        {
                                _waves = AMELIA_AURA_RIPPLES_EXE;
                                _wa = AMELIA_AURA_RIPPLE_A_EXE * _k;
                                _colWave = _colCore;
                                _wspd = _wspd * 2; // como su latido: al doble
                        }

                        for(var w = 0; w < _waves; w++)
                        {
                                var _t = frac(auraPulse * _wspd + w / _waves + _seed);
                                draw_set_alpha(_wa * (1 - _t) * (1 - _t));
                                draw_set_color(_colWave);
                                draw_circle(_sx, _ay, _r * 0.55 + _t * (_r + AMELIA_AURA_RIPPLE_SPREAD - _r * 0.55), true);
                        }
                }

                // --- C. RETÍCULA: aro principal + marcas que giran
                // por fuera (1.5 px de ancho). El EXE gira al derecho,
                // el esbirro AL REVÉS: se distinguen de reojo sin
                // leer el tamaño. Frío: marcas FIJAS (hielo).
                draw_set_alpha((_isExe ? 0.5 : 0.3) * _k);
                draw_set_color(_colCore);
                draw_circle(_sx, _ay, _r, true);

                var _ticks = AMELIA_AURA_TICKS_MINION;
                var _tlen = AMELIA_AURA_TICK_LEN;
                var _tbase = auraPulse * AMELIA_AURA_RETICLE_SPD_MINION;

                if(_isExe)
                {
                        _ticks = AMELIA_AURA_TICKS_EXE;
                        _tlen = AMELIA_AURA_TICK_LEN_EXE;
                        _tbase = auraPulse * AMELIA_AURA_RETICLE_SPD_EXE;
                }

                if(_cold)
                {
                        _ticks = AMELIA_AURA_TICKS_COLD;
                        _tbase = -45; // estático: el hielo no gira
                }

                draw_set_alpha(0.4 * _k);
                draw_set_color(_colCore);

                for(var t = 0; t < _ticks; t++)
                {
                        var _a = _tbase + 360 / _ticks * t;
                        draw_line_width(_sx + lengthdir_x(_r + 2, _a), _ay + lengthdir_y(_r + 2, _a),
                                        _sx + lengthdir_x(_r + 2 + _tlen, _a), _ay + lengthdir_y(_r + 2 + _tlen, _a), 1.5);
                }

                // --- D. NÚCLEO: solo el EXE real arde al centro
                // (frío: fijo, azul — el beat ya es 0).
                if(_isExe)
                {
                        draw_set_alpha(0.35 * _k);
                        draw_set_color(_colCore);
                        draw_circle(_sx, _ay, 8 + _beat * 2, false);
                }

                // --- E. SILUETA de calor a través de las paredes ---
                // El mismo sprite que dibuja el puppet (Draw_0 del
                // puppet: floor(x), floor(y), image_xscale/yscale,
                // angle) pero tintado de calor y semitransparente,
                // con la mezcla aditiva encendida: es un "fantasma"
                // anaranjado del cuerpo. v87: el EXE se dibuja en DOS
                // capas (halo + núcleo caliente): el fantasma gordo
                // es el de siempre y el fino y brillante es suyo.
                // Si la entidad no declara angle (los clones no lo
                // tienen), 0.
                if(_inst != noone && _inst.sprite_index > -1)
                {
                        var _ang = variable_instance_exists(_inst.id, "angle") ? _inst.angle : 0;

                        if(_isExe)
                        {
                                draw_set_alpha(0.22 * _k);
                                draw_sprite_ext(_inst.sprite_index, _inst.image_index, floor(_sx), floor(_sy), _inst.image_xscale, _inst.image_yscale, _ang, _colHalo, 1);
                                draw_set_alpha(0.38 * _k);
                                draw_sprite_ext(_inst.sprite_index, _inst.image_index, floor(_sx), floor(_sy), _inst.image_xscale, _inst.image_yscale, _ang, _colCore, 1);
                        }
                        else
                        {
                                draw_set_alpha(0.2 * _k);
                                draw_sprite_ext(_inst.sprite_index, _inst.image_index, floor(_sx), floor(_sy), _inst.image_xscale, _inst.image_yscale, _ang, _colCore, 1);
                        }
                }

                // --- F. PING de entrada: anillo expansivo único al
                // detectar una firma nueva (nace chico y brillante,
                // muere grande y tenue — al revés que las ondas).
                if(_fl > 0)
                {
                        draw_set_alpha(AMELIA_AURA_PING_A * _fl);
                        draw_set_color(_colCore);
                        draw_circle(_sx, _ay, 4 + (1 - _fl) * AMELIA_AURA_PING_R, true);
                }
        }
        else
        {
                // --- G. marcador de borde (chevron doble + puntos de
                // cercanía). Alpha propia (no la del desvanecido del
                // alcance): avisar de la firma al otro lado de la
                // pantalla ES el punto.
                var _mk = 0.35 + 0.45 * auraK[i] + _fl * 0.3;
                if(_mk > 1)
                        _mk = 1;

                var _px = clamp(_sx, _ex0, _ex1);
                var _py = clamp(_sy, _ey0, _ey1);

                // dirección desde la posición EN PANTALLA de Amelia
                var _dir = point_direction(global.player.x - _cx, global.player.y - _cy, _sx, _sy);

                // el chevron del EXE real es MÁS GRANDE: la firma
                // gorda se lee desde el otro lado de la pantalla.
                var _cs = auraExe[i] ? AMELIA_AURA_POINTER_EXE : 1;

                var _fd = AMELIA_AURA_POINTER * _cs;
                var _fw = AMELIA_AURA_POINTER_W * _cs;

                // cola del chevron (tenue, color halo): la misma
                // punta pero más chica y retrasada — se lee ">>"
                // apuntando hacia afuera.
                var _bX = _px - lengthdir_x(_fd * 1.1, _dir);
                var _bY = _py - lengthdir_y(_fd * 1.1, _dir);
                var _bw = _fw * 0.65;

                draw_set_alpha(_mk * 0.45);
                draw_set_color(_colHalo);
                draw_triangle(_bX + lengthdir_x(_fd * 0.85, _dir), _bY + lengthdir_y(_fd * 0.85, _dir),
                              _bX + lengthdir_x(_bw, _dir + 90), _bY + lengthdir_y(_bw, _dir + 90),
                              _bX + lengthdir_x(_bw, _dir - 90), _bY + lengthdir_y(_bw, _dir - 90), false);

                // punta del chevron (sólida, color núcleo): clavada
                // en el borde y apuntando hacia afuera.
                var _nX = _px - lengthdir_x(_fd * 0.4, _dir);
                var _nY = _py - lengthdir_y(_fd * 0.4, _dir);

                draw_set_alpha(_mk);
                draw_set_color(_colCore);
                draw_triangle(_nX + lengthdir_x(_fd, _dir), _nY + lengthdir_y(_fd, _dir),
                              _nX + lengthdir_x(_fw, _dir + 90), _nY + lengthdir_y(_fw, _dir + 90),
                              _nX + lengthdir_x(_fw, _dir - 90), _nY + lengthdir_y(_fw, _dir - 90), false);

                // anillo de anclaje en el borde
                draw_set_alpha(_mk * 0.8);
                draw_set_color(_colHalo);
                draw_circle(_px, _py, 3, true);

                // PUNTOS DE CERCANÍA (1-3): más puntos = firma MÁS
                // CERCA de Amelia; van hacia DENTRO de la pantalla
                // (hacia donde está ella).
                var _pips = 1;
                if(auraK[i] > 0.66)
                        _pips = 3;
                else if(auraK[i] > 0.33)
                        _pips = 2;

                draw_set_alpha(_mk * 0.8);
                draw_set_color(_colCore);

                for(var p = 0; p < _pips; p++)
                {
                        var _pd = AMELIA_AURA_PIP_0 + p * AMELIA_AURA_PIP_STEP;
                        draw_circle(_px - lengthdir_x(_pd, _dir), _py - lengthdir_y(_pd, _dir), AMELIA_AURA_PIP_R, false);
                }
        }
}

draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);
