if(effectTime > 0)
{
        effectTime--;
        
        if(effectTime % 3 == 0)
        {
                var inst = scr_effect_fade_quick(x, y, sprite_index);
                inst.image_xscale = image_xscale;
                inst.image_index = image_index;
                inst.image_speed = 0;
                inst.depth = depth+10;
                inst.palleteFrom = global.palleteFrom;
                inst.palleteTo = global.palleteTo;
        }
}

// POWERBOOST (fase 3 de Nervios de Acero o fase 2 del revive): efectos
// visuales estilo Frontiers en dos pasadas: el aura DETRAS del cuerpo
// y los rayos/tinte ENCIMA, mas el anillo de activacion. Todo
// procedural (scr_powerboost_fx): sin assets nuevos.
var _pb = (nerviosState == 3 || reviveBoost);

if(_pb)
        scr_powerboost_fx_back(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), pbTime);

//Actual draw
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

if(_pb)
{
        scr_powerboost_fx_front(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), pbTime, !isGrounded || abs(xspd) + abs(gspd) > 0.5);
        scr_powerboost_fx_flash(floor(x), floor(y), pbFlash);
}
