// PASIVA AURAVISIÓN — dibujado (Draw GUI: por ENCIMA del mundo, asi
// se ve A TRAVÉS de las paredes; posiciones en pantalla restando la
// camara, como las flechas de obj_amycanon_indicators).
// Todo con mezcla aditiva (bm_add) para que las auras "ardiendo"
// iluminen lo que hay detras, patron del aura de parry de
// obj_player_puppet. Solo en la pantalla de la propia Amelia.
if(!visible)
        return;

if(!instance_exists(global.player) || auraCount <= 0)
        return;

gpu_set_blendmode(bm_add);
draw_set_circle_precision(32);

for(var i = 0; i < auraCount; i++)
{
        var _sx = ceil(auraX[i] - obj_camera.x);
        var _sy = ceil(auraY[i] - obj_camera.y);

        // latido: las auras respiran; la del EXE real late al doble
        var _beat = sin(auraPulse * (auraExe[i] ? 2 : 1));
        var _r = auraR[i] + _beat * (auraExe[i] ? AMELIA_AURA_EXE_PULSE_AMP : AMELIA_AURA_MINION_PULSE_AMP);

        // fuerza por distancia: 1 pegada a Amelia, 0 justo en el
        // borde del radio (asi el aura entra desvaneciendose en vez
        // de aparecer de golpe, pero nunca desaparece del todo dentro
        // del radio: minimo un 30%)
        var _k = 0.3 + 0.7 * auraK[i];

        // la entidad pudo morir/salir del mapa entre el Step y aqui
        var _inst = auraInst[i];
        if(!instance_exists(_inst))
                continue;

        if(auraExe[i])
        {
                // --- EXE REAL: arde MAS FUERTE (el impostor de su
                // historia se delató con un aura más brillante) ---
                // halo grande
                draw_set_alpha((0.16 + 0.06 * _beat) * _k);
                draw_set_color(AMELIA_AURA_EXE_COLOR);
                draw_circle(_sx, _sy - 6, _r, false);

                // aro brillante
                draw_set_alpha(0.5 * _k);
                draw_set_color(AMELIA_AURA_EXE_CORE);
                draw_circle(_sx, _sy - 6, _r, true);

                // nucleo caliente
                draw_set_alpha(0.35 * _k);
                draw_set_color(AMELIA_AURA_EXE_CORE);
                draw_circle(_sx, _sy - 6, 8 + _beat * 2, false);
        }
        else
        {
                // --- esbirro o clone: silueta tenue ---
                draw_set_alpha(0.10 * _k);
                draw_set_color(AMELIA_AURA_MINION_COLOR);
                draw_circle(_sx, _sy - 6, _r, false);

                draw_set_alpha(0.3 * _k);
                draw_set_color(AMELIA_AURA_MINION_COLOR);
                draw_circle(_sx, _sy - 6, _r, true);
        }

        // --- silueta de calor a traves de las paredes ---
        // El mismo sprite que dibuja el puppet (Draw_0 del puppet:
        // floor(x), floor(y), image_xscale/yscale, angle) pero
        // tintado de calor y semitransparente, con la mezcla aditiva
        // encendida: es un "fantasma" anaranjado del cuerpo. Los
        // clones usan draw_self() (sprite_index tambien vale). Si la
        // entidad no declara angle (los clones no lo tienen), 0.
        if(_inst.sprite_index > -1)
        {
                var _ang = variable_instance_exists(_inst.id, "angle") ? _inst.angle : 0;

                draw_set_alpha(auraExe[i] ? 0.45 * _k : 0.2 * _k);
                draw_sprite_ext(_inst.sprite_index, _inst.image_index, floor(_sx), floor(_sy), _inst.image_xscale, _inst.image_yscale, _ang, auraExe[i] ? AMELIA_AURA_EXE_CORE : AMELIA_AURA_MINION_COLOR, 1);
        }
}

draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);
