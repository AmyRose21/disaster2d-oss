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

//Actual draw
scr_palette_swap(global.palleteFrom, global.palleteTo);
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
shader_reset();

// ESTADO BURBUJA: dibuja la burbuja de secuestro ENCIMA de Amy.
// amy_Bubble son 8 frames a 5 fps (200 ms por frame); su origen
// (24,25) la deja perfectamente centrada sobre el sprite de
// captura (37x41). Asi la ve igual el jugador local que el resto
// de clientes (los puppets la dibujan desde obj_player_puppet).
if(bubbleState == AMY_BUBBLE_ACTIVE)
        draw_sprite(amy_Bubble, (current_time / 200) % 8, floor(x), floor(y));