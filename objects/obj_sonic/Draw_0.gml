// ABRAZO COMBINADO (interaccion con Amy Canon): mientras lo estan
// abrazando (o Amy acaba de empezar y su estado de abrazo todavia no
// le llego por red: el check en vivo lo cubre), el cuerpo de Sonic no
// se dibuja: el sprite combinado (spr_amy_hug_canon) ya lo incluye y
// lo dibuja la Amy de cada cliente. La barra de HP (Draw_64) sigue
// igual: el abrazo no oculta el estado del jugador.
if(state == SONIC_HUGGED || scr_amy_hug_amy_near(id, AMY_HUG_KEEP) != noone)
        return;

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

// PARRY: aura cian visible mientras la ventana esta abierta (para que
// los aliados vean el radio que les cubre) + anillo de activacion.
if(parryState == 2)
{
        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.13);
        draw_set_color(SONIC_PB_COLOR);
        draw_circle(x, y - 6, SONIC_PARRY_AURA, false);
        draw_set_alpha(0.35);
        draw_circle(x, y - 6, SONIC_PARRY_AURA, true);
        draw_set_alpha(1);
        draw_set_color(c_white);
        gpu_set_blendmode(bm_normal);
}

//Actual draw
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

if(_pb)
{
        scr_powerboost_fx_front(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), pbTime, !isGrounded || abs(xspd) + abs(gspd) > 0.5);
        scr_powerboost_fx_flash(floor(x), floor(y), pbFlash);
}

// PARRY: anillo cian de activacion / exito (mismo estilo del powerboost)
scr_powerboost_fx_flash(floor(x), floor(y - 6), parryFlash);
