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

// ABRAZO COMBINADO (interaccion con Sonic): mientras Amy abraza, su
// cuerpo NO se dibuja; en su lugar se pinta el sprite combinado de
// los dos (spr_amy_hug_canon, con los corazones) en el punto medio
// entre los dos cuerpos. A Sonic lo esconden los demas clientes con
// el mismo check en vivo (scr_amy_hug_amy_near), asi que aqui solo
// importa el dibujado. El espejado sale de la posicion relativa real
// (si Amy quedo a la derecha de Sonic, se dibuja volteado para que
// cada uno quede en su lado). Nada de paleta ni de cuerpo propio.
if(state == AMY_CANON_HUG)
{
        var _sonic = scr_amy_hug_find_sonic(id, AMY_HUG_KEEP);

        if(_sonic != noone)
        {
                var _mx = floor((x + _sonic.x) / 2);
                var _my = floor((y + _sonic.y) / 2);
                var _side = (x > _sonic.x) ? -1 : 1;

                // pequeña respiracion: sube 1 px y baja cada ~400 ms
                var _bob = ((current_time / 400) mod 2) < 1 ? 0 : -1;

                draw_sprite_ext(spr_amy_hug_canon, 0, _mx, _my + _bob, _side, 1, 0, c_white, 1);
        }

        return;
}

// PARRY (tecla V): aura rosa visible mientras la ventana esta abierta
// (para que los aliados vean el radio que les cubre, igual que el aura
// cian de Sonic). El color lo fija scr_parry_aura_color: rosa para Amy.
if(parryState == 2)
{
        gpu_set_blendmode(bm_add);
        draw_set_circle_precision(32);
        draw_set_alpha(0.13);
        draw_set_color(scr_parry_aura_color(global.character));
        draw_circle(x, y - 6, SONIC_PARRY_AURA, false);
        draw_set_alpha(0.35);
        draw_set_color(scr_parry_aura_color_core(global.character));
        draw_circle(x, y - 6, SONIC_PARRY_AURA, true);
        draw_set_alpha(1);
        draw_set_color(c_white);
        gpu_set_blendmode(bm_normal);
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

// PARRY: anillo de activacion / exito (mismo estilo del powerboost de
// Sonic; el flash es blanco y no lleva color de personaje).
scr_powerboost_fx_flash(floor(x), floor(y - 6), parryFlash);