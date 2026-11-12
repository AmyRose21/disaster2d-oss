// v4.2 — encogido del portal al terminar su animacion (JINNA_PORTAL_SHRINK
// frames): escala 1 -> 0 lineal y MUERTE al llegar a 0. Patron calcado de
// la fase 1 del obj_jinna_absorb ("como cuando atrapa a Vanilla que el
// portal se hace mas pequeno hasta desaparecer"). Mientras shrink == 0 el
// portal se dibuja normal (draw_self: animado a 20 fps).
if(shrink > 0)
{
        shrink--;

        var _scale = shrink / JINNA_PORTAL_SHRINK;

        if(_scale <= 0)
                instance_destroy();
        else
        {
                // origin abajo-centro (origin 9): al escalar se encoge hacia
                // los pies, el agujero se cierra contra el suelo
                draw_sprite_ext(sprite_index, image_index, floor(x), floor(y),
                                image_xscale * _scale, _scale, 0, image_blend, image_alpha);
        }
}
else
        draw_self();
