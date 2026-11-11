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
draw_sprite_ext(sprite_index, image_index, floor(x), floor(y), image_xscale, image_yscale, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding || shockedTimer > 0) ? 0.5 : image_alpha);
shader_reset();

// TELEGRAPH DEL TELETRANSPORTE: flecha parpadeante (spr_jinna_clonearrow,
// 2 frames) sobre el objetivo mientras dura el windup — es el aviso que
// ve la jugadora de Jinna para saber a quien va a cazar el portal.
if(jinnaTeleWindup > 0 && instance_exists(jinnaTeleTarget))
{
        draw_sprite(spr_jinna_clonearrow, floor(current_time / 100) % 2, jinnaTeleTarget.x, jinnaTeleTarget.y - 46 - jinnaTeleTarget.sprite_yoffset + 8);
}

// v3 — VANILLA ATRAPADA EN LA OTRA DIMENSION: vista de ella atrapada
// (spr_vanilla_caught, 170x94) flotando sobre la cabeza de Jinna. SOLO
// se dibuja en el cliente de la jugadora de Jinna (este Draw no corre
// en los demas): para el resto de supervivientes — y otros exes, si
// algun dia existe el doble trouble — Vanilla simplemente desaparecio.
// Mientras este aqui, su presencia POTENCIA todo el kit (los aumentos
// los aplican los clientes de las victimas con global.jinnaCaughtVanilla).
if(jinnaCaughtShow)
{
        var _bob = sin(current_time / 300) * 3;
        draw_sprite_ext(spr_vanilla_caught, 0, floor(x), floor(y - 78 + _bob), image_xscale, 1, 0, c_white, 0.85);
}

//hakc
if(isDead)
{
        xspd = 0;
        gspd = 0;
        return;
}
