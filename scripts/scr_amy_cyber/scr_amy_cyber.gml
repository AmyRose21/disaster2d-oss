// =====================================================================
//  AMY CYBER GHOST (v1) — shader holograma glitch estilo Frontiers.
//
//  scr_amy_cyber(char, palleteIn, palleteOut, spr, sub) reemplaza a
//  scr_palette_swap en el Draw de Amy Canon (local y puppet): si el
//  personaje esta en AMY_CYBER_CHARS activa shd_amy_cyber (palette
//  swap + overlay cyber); si no, cae al scr_palette_swap de siempre
//  y no cambia nada. Es 100% visual: cada cliente lo dibuja solo, sin
//  red ni server.
//
//  Como ajustarlo (macros de abajo, mismo formato que el resto del
//  repo):
//   - AMY_CYBER_ENABLED false  -> apaga el efecto (todo vuelve a como
//     estaba, usa el palette swap normal).
//   - AMY_CYBER_CHARS          -> a quien le aplica. Por defecto solo
//     a Amy Canon. Puedes añadir a quien quieras, p.ej.
//     [CHARACTER_AMY_CANON, CHARACTER_AMY].
//   - AMY_CYBER_ALPHA          -> opacidad holograma. 0.85 = fantasma
//     como en el juego original; 1 = solida.
//   - AMY_CYBER_GLITCH         -> cuantos px se mueven las bandas.
//     0 = sin bandas (solo scanlines + split + chispas).
//   - AMY_CYBER_SCAN           -> fuerza de las scanlines.
//   - AMY_CYBER_SPLIT          -> px del split rojo/cian de bordes.
//   - AMY_CYBER_FLICKER        -> chispas, barrido y parpadeo.
//   - AMY_CYBER_TINT           -> lavado cian en las sombras.
// =====================================================================

#macro AMY_CYBER_ENABLED true

// personajes con el efecto (id -> shader). Amy Canon por defecto.
#macro AMY_CYBER_CHARS   [CHARACTER_AMY_CANON]

// look
#macro AMY_CYBER_SCAN    0.16     // scanlines: cada 2 px se oscurece
#macro AMY_CYBER_SPLIT   1.0      // split RGB en px
#macro AMY_CYBER_GLITCH  5        // px maximos de las bandas glitch
#macro AMY_CYBER_FLICKER 0.30     // chispas + barrido + parpadeo
#macro AMY_CYBER_ALPHA   0.85     // opacidad holograma (1 = solida)
#macro AMY_CYBER_TINT    0.15     // lavado cian en sombras

// dice si un personaje lleva el efecto
function scr_amy_cyber_is(ch)
{
        var _list = AMY_CYBER_CHARS;

        for(var i = 0; i < array_length(_list); i++)
                if(_list[i] == ch)
                        return true;

        return false;
}

// reemplaza a scr_palette_swap en el Draw: activa el shader cyber con
// la paleta que le pases (igual que scr_palette_swap) + el overlay.
function scr_amy_cyber(char, palleteIn, palleteOut, spr, sub)
{
        if(!AMY_CYBER_ENABLED || !scr_amy_cyber_is(char))
        {
                scr_palette_swap(palleteIn, palleteOut);
                return;
        }

        // cache de los uniforms (se piden una sola vez)
        if(!variable_global_exists("amyCyberU"))
        {
                global.amyCyberU =
                {
                        pattern:      shader_get_uniform(shd_amy_cyber, "u_Pattern"),
                        replacements: shader_get_uniform(shd_amy_cyber, "u_Replacements"),
                        count:        shader_get_uniform(shd_amy_cyber, "u_ColourCount"),
                        texel:        shader_get_uniform(shd_amy_cyber, "uTexel"),
                        time:         shader_get_uniform(shd_amy_cyber, "uTime"),
                        scan:         shader_get_uniform(shd_amy_cyber, "uScan"),
                        split:        shader_get_uniform(shd_amy_cyber, "uSplit"),
                        glitch:       shader_get_uniform(shd_amy_cyber, "uGlitch"),
                        flicker:      shader_get_uniform(shd_amy_cyber, "uFlicker"),
                        alpha:        shader_get_uniform(shd_amy_cyber, "uAlpha"),
                        tint:         shader_get_uniform(shd_amy_cyber, "uTint")
                };
        }

        var _u = global.amyCyberU;

        shader_set(shd_amy_cyber);

        // paleta: identico a scr_palette_swap
        shader_set_uniform_f_array(_u.pattern, palleteIn);
        shader_set_uniform_f_array(_u.replacements, palleteOut);
        shader_set_uniform_i(_u.count, array_length(palleteIn) / 4);

        // texel REAL de la textura (para convertir px -> uv): el
        // sprite vive en una texture page grande, el paso de 1 px es
        // 1/tamano de pagina, no 1/tamano del sprite.
        var _tw = 1.0 / 64.0;
        var _th = 1.0 / 64.0;

        if(sprite_exists(spr))
        {
                var _tex = sprite_get_texture(spr, max(0, floor(sub)));
                _tw = texture_get_texel_width(_tex);
                _th = texture_get_texel_height(_tex);
        }

        shader_set_uniform_f(_u.texel, _tw, _th);
        shader_set_uniform_f(_u.time, current_time / 1000);
        shader_set_uniform_f(_u.scan, AMY_CYBER_SCAN);
        shader_set_uniform_f(_u.split, AMY_CYBER_SPLIT);
        shader_set_uniform_f(_u.glitch, AMY_CYBER_GLITCH);
        shader_set_uniform_f(_u.flicker, AMY_CYBER_FLICKER);
        shader_set_uniform_f(_u.alpha, AMY_CYBER_ALPHA);
        shader_set_uniform_f(_u.tint, AMY_CYBER_TINT);
}
