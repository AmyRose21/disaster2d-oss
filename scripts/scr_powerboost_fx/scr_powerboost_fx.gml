/// @description POWERBOOST DE SONIC - efectos visuales estilo Frontiers
/// Todas las capas son procedurales (cero assets nuevos): aura aditiva,
/// rayos electricos, tinte cargado, speed lines y anillo de activacion.
/// Se dibuja en DOS pasadas alrededor del cuerpo: scr_powerboost_fx_back()
/// va DETRAS del sprite del jugador (llamarla ANTES del draw del cuerpo)
/// y scr_powerboost_fx_front() ENCIMA (llamarla DESPUES). El anillo de
/// activacion lo dibuja scr_powerboost_fx_flash() los primeros frames.
/// La usan el jugador local (obj_sonic) y el puppet remoto: el estado
/// viaja por red con el bitflag PLAYER_POWERBOOST (fase 3 de Nervios de
/// Acero o reviveBoost tras ser revivido).

// --- PARAMETROS AJUSTABLES (60 frames = 1 segundo) -------------------
//  COLOR / COLOR_CORE : tono cian del aura y nucleo de los rayos.
//  AURA_SCALE         : cuanto se ensancha el halo (1.22 = 22% mas
//                       grande; la "sombra azulada" de Frontiers).
//  LIGHTNINGS         : rayos que crepitan por frame (2 = electrico).
//  FLASH_FRAMES       : duracion del anillo de activacion (~0.25 seg).
// ---------------------------------------------------------------------
#macro SONIC_PB_COLOR make_color_rgb(90, 220, 255)
#macro SONIC_PB_COLOR_CORE make_color_rgb(180, 245, 255)
#macro SONIC_PB_AURA_SCALE 1.22
#macro SONIC_PB_LIGHTNINGS 2
#macro SONIC_PB_FLASH_FRAMES 14

// --- PASADA 1: aura DETRAS del cuerpo --------------------------------
function scr_powerboost_fx_back(_spr, _frame, _x, _y, _xs, _ys, _ang, _t)
{
        // el aura "respira" (~1 ciclo por segundo)
        var _pulse = 0.85 + abs(dsin(_t * 3)) * 0.3;

        gpu_set_blendmode(bm_add);

        // halo ancho y tenue (envuelve el cuerpo)
        draw_sprite_ext(_spr, _frame, _x, _y, _xs * SONIC_PB_AURA_SCALE, _ys * SONIC_PB_AURA_SCALE, _ang, SONIC_PB_COLOR, 0.16 * _pulse);

        // capa pegada al cuerpo, mas brillante
        draw_sprite_ext(_spr, _frame, _x, _y, _xs, _ys, _ang, SONIC_PB_COLOR, 0.28 * _pulse);

        gpu_set_blendmode(bm_normal);
}

// --- PASADA 2: rayos + tinte + speed lines ENCIMA del cuerpo ---------
function scr_powerboost_fx_front(_spr, _frame, _x, _y, _xs, _ys, _ang, _t, _moving)
{
        gpu_set_blendmode(bm_add);

        // tinte "cargado": su propia silueta con alpha baja (electrificado)
        draw_sprite_ext(_spr, _frame, _x, _y, _xs, _ys, _ang, SONIC_PB_COLOR, 0.14);

        // rayos: lineas quebradas entre dos puntos al azar alrededor del
        // cuerpo; al regenerarse cada frame crepitan solos
        draw_set_color(SONIC_PB_COLOR_CORE);

        for(var n = 0; n < SONIC_PB_LIGHTNINGS; n++)
        {
                var _a1 = random(360);
                var _a2 = _a1 + random_range(120, 240);
                var _px = _x + lengthdir_x(random_range(12, 18), _a1);
                var _py = _y + lengthdir_y(random_range(12, 18), _a1);
                var _ex = _x + lengthdir_x(random_range(16, 26), _a2);
                var _ey = _y + lengthdir_y(random_range(16, 26), _a2);

                for(var i = 1; i <= 4; i++)
                {
                        var _nx = lerp(_px, _ex, i / 4) + random_range(-5, 5);
                        var _ny = lerp(_py, _ey, i / 4) + random_range(-5, 5);

                        draw_line_width(_px, _py, _nx, _ny, 1.5);

                        _px = _nx;
                        _py = _ny;
                }
        }

        // speed lines: solo en movimiento (parado se ve cargado; corriendo
        // corta el aire, como el boost de Frontiers)
        if(_moving)
        {
                var _dir = -sign(_xs);

                for(var i = 0; i < 5; i++)
                {
                        var _sy = _y + random_range(-20, 20);
                        var _sx = _x + _dir * random_range(18, 34);

                        draw_set_alpha(random_range(0.08, 0.22));
                        draw_line_width(_sx, _sy, _sx + _dir * random_range(12, 28), _sy, random_range(1, 2));
                }

                draw_set_alpha(1);
        }

        draw_set_color(c_white);
        gpu_set_blendmode(bm_normal);
}

// --- Anillo de activacion: dibujar mientras _framesLeft baja de
//     SONIC_PB_FLASH_FRAMES a 0 (quien lo llama baja el contador en su
//     Step). Devuelve true mientras dure el flash.
function scr_powerboost_fx_flash(_x, _y, _framesLeft)
{
        if(_framesLeft <= 0)
                return false;

        var _k = 1 - (_framesLeft / SONIC_PB_FLASH_FRAMES);

        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.55 * (1 - _k));
        draw_set_color(c_white);
        draw_circle(_x, _y, 46 * _k, false);
        draw_set_alpha(1);
        gpu_set_blendmode(bm_normal);

        return true;
}
