// PASIVA AURAVISIÓN — dibujado (Draw GUI: por ENCIMA del mundo, asi
// se ve A TRAVÉS de las paredes; posiciones en pantalla restando la
// camara, como las flechas de obj_amycanon_indicators).
// Todo con mezcla aditiva (bm_add) para que las auras "ardiendo"
// iluminen lo que hay detras, patron del aura de parry de
// obj_player_puppet. Solo en la pantalla de la propia Amelia.
// v84 (QoL + blindaje): guard de camara; desvanecido suave al cruzar
// el borde del alcance; frio (azul, sin latido); destello de entrada;
// marcador de flecha en el borde de la pantalla para firmas fuera de
// la vista (antes simplemente no se veian y la info se perdia).
if(!visible)
        return;

if(!instance_exists(global.player) || auraCount <= 0)
        return;

if(!instance_exists(obj_camera))
        return;

var _cx = obj_camera.x;
var _cy = obj_camera.y;

// v84: limites de la capa GUI con su margen: aqui vive el marcador de
// borde. display_get_gui_width/height = tamano REAL de la capa GUI de
// este cliente, asi que el clamp vale en cualquier resolucion.
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

        // la entidad pudo morir/salir del mapa entre el Step y aqui
        var _inst = auraInst[i];
        if(_inst != noone && !instance_exists(_inst))
                _inst = noone;

        // v84: frio = aturdido/caido: sin latido y en AZUL — una firma
        // fria es una amenaza neutralizada, se lee de un vistazo.
        var _cold = auraCold[i];

        // v84: destello de entrada (contacto nuevo: brilla un instante)
        var _fl = 0;
        if(auraFlash[i] > 0)
                _fl = auraFlash[i] / AMELIA_AURA_FLASH;

        // latido: las auras respiran; la del EXE real late al doble
        var _beat = sin(auraPulse * (auraExe[i] ? 2 : 1));
        if(_cold)
                _beat = 0;

        var _r = auraR[i] + _beat * (auraExe[i] ? AMELIA_AURA_EXE_PULSE_AMP : AMELIA_AURA_MINION_PULSE_AMP);
        _r += _fl * 6;

        // fuerza por distancia: 1 pegada a Amelia, 0 justo en el borde
        // del radio. v84: el borde del ALCANCE se cruza suave ahora
        // (smoothstep sobre el ultimo tramo), no de golpe.
        var _e = auraK[i] / AMELIA_AURA_EDGE_FADE;
        if(_e < 0)
                _e = 0;

        if(_e > 1)
                _e = 1;

        var _k = (0.3 + 0.7 * auraK[i]) * (_e * _e * (3 - 2 * _e)) + _fl * 0.5;
        if(_k > 1)
                _k = 1;

        // colores: exe arde mas; esbirros/clones tenues; frio = azul
        var _colHalo = auraExe[i] ? AMELIA_AURA_EXE_COLOR : AMELIA_AURA_MINION_COLOR;
        var _colCore = auraExe[i] ? AMELIA_AURA_EXE_CORE : AMELIA_AURA_MINION_COLOR;

        if(_cold)
        {
                _colHalo = AMELIA_AURA_COLD_COLOR;
                _colCore = AMELIA_AURA_COLD_CORE;
        }

        // v84: firma DENTRO de la vista -> aura completa + silueta;
        // FUERA -> flecha fina clavada en el borde apuntando hacia
        // ella desde la propia Amelia (el calor no se esconde, pero la
        // pantalla si se acaba).
        var _onscreen = (_sx >= _ex0 && _sx <= _ex1 && _sy >= _ey0 && _sy <= _ey1);

        if(_onscreen)
        {
                if(auraExe[i])
                {
                        // --- EXE REAL: arde MAS FUERTE (el impostor de su
                        // historia se delató con un aura más brillante) ---
                        // halo grande
                        draw_set_alpha((0.16 + 0.06 * _beat) * _k);
                        draw_set_color(_colHalo);
                        draw_circle(_sx, _sy - 6, _r, false);

                        // aro brillante
                        draw_set_alpha(0.5 * _k);
                        draw_set_color(_colCore);
                        draw_circle(_sx, _sy - 6, _r, true);

                        // nucleo caliente
                        draw_set_alpha(0.35 * _k);
                        draw_set_color(_colCore);
                        draw_circle(_sx, _sy - 6, 8 + _beat * 2, false);
                }
                else
                {
                        // --- esbirro o clone: silueta tenue ---
                        draw_set_alpha(0.10 * _k);
                        draw_set_color(_colHalo);
                        draw_circle(_sx, _sy - 6, _r, false);

                        draw_set_alpha(0.3 * _k);
                        draw_set_color(_colCore);
                        draw_circle(_sx, _sy - 6, _r, true);
                }

                // --- silueta de calor a traves de las paredes ---
                // El mismo sprite que dibuja el puppet (Draw_0 del puppet:
                // floor(x), floor(y), image_xscale/yscale, angle) pero
                // tintado de calor y semitransparente, con la mezcla aditiva
                // encendida: es un "fantasma" anaranjado del cuerpo. Los
                // clones usan draw_self() (sprite_index tambien vale). Si la
                // entidad no declara angle (los clones no lo tienen), 0.
                if(_inst != noone && _inst.sprite_index > -1)
                {
                        var _ang = variable_instance_exists(_inst.id, "angle") ? _inst.angle : 0;

                        draw_set_alpha(auraExe[i] ? 0.45 * _k : 0.2 * _k);
                        draw_sprite_ext(_inst.sprite_index, _inst.image_index, floor(_sx), floor(_sy), _inst.image_xscale, _inst.image_yscale, _ang, _colCore, 1);
                }
        }
        else
        {
                // --- v84: marcador de borde (flecha fina) ---
                // Alpha propia (no la del desvanecido del alcance): avisar de
                // la firma al otro lado de la pantalla ES el punto. El anillo
                // chico marca el punto de anclaje en el borde.
                var _mk = 0.35 + 0.45 * auraK[i] + _fl * 0.3;
                if(_mk > 1)
                        _mk = 1;

                var _px = clamp(_sx, _ex0, _ex1);
                var _py = clamp(_sy, _ey0, _ey1);

                // direccion desde la posicion EN PANTALLA de Amelia
                var _dir = point_direction(global.player.x - _cx, global.player.y - _cy, _sx, _sy);

                // flecha: punta hacia afuera, base en el borde
                var _tipX = _px + lengthdir_x(AMELIA_AURA_POINTER, _dir);
                var _tipY = _py + lengthdir_y(AMELIA_AURA_POINTER, _dir);
                var _lX = _px + lengthdir_x(AMELIA_AURA_POINTER_W, _dir + 90);
                var _lY = _py + lengthdir_y(AMELIA_AURA_POINTER_W, _dir + 90);
                var _rX = _px + lengthdir_x(AMELIA_AURA_POINTER_W, _dir - 90);
                var _rY = _py + lengthdir_y(AMELIA_AURA_POINTER_W, _dir - 90);

                draw_set_alpha(_mk);
                draw_set_color(_colCore);
                draw_triangle(_tipX, _tipY, _lX, _lY, _rX, _rY, false);

                draw_set_alpha(_mk * 0.8);
                draw_set_color(_colHalo);
                draw_circle(_px, _py, 3, true);
        }
}

draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);
