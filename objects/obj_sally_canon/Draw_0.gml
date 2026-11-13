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

// FASE 2: SQUASH & STRETCH (solo pt3/pt4). fase2Sq > 0 = estirada
// (despegue del salto), fase2Sq < 0 = aplastada (aterrizaje). Rebota
// sola a 0 (scr_sally_canon_fase2). La escala se ancla al SUELO: los
// pies quedan plantados y el cuerpo se estira/aplasta hacia arriba.
var _f2xs = image_xscale;
var _f2ys = image_yscale;
var _f2yoff = 0;

if(fase2Sq != 0)
{
        _f2ys = image_yscale * (1 + fase2Sq);
        _f2xs = image_xscale * (1 - fase2Sq * 0.6);
        _f2yoff = (sprite_height - sprite_yoffset) * (1 - _f2ys);
}

//Actual draw

// POSES DEL ESCUDO (v5.8): mientras dura la animacion de ACTIVACION
// (los primeros frames tras pulsar la habilidad) el cuerpo se dibuja
// con la pose (quieta / agachada / aire) usando SU propio contador
// shieldPoseT — no se toca sprite_index ni image_index, asi que
// ningun clamp (el switch de Draw_76, el Other_7 de Animation End)
// puede congelarla, cortarla o reiniciarla. Se ve UNA vez y el cuerpo
// vuelve a su sprite normal. La burbuja animada va siempre encima.
var _bodySpr = sprite_index;
var _bodyIdx = image_index;

if(shieldPoseOn)
{
        _bodySpr = shieldPoseSpr;
        _bodyIdx = floor(shieldPoseT);
}

	scr_palette_swap(global.palleteFrom, global.palleteTo);
	draw_sprite_ext(_bodySpr, _bodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, isSpinning ? 0 : radtodeg(angle), image_blend, (hurttime > 0 || isHiding) ? 0.5 : image_alpha);
	shader_reset();

// ESCUDO (v5.6, fix reportado): la burbuja animada se dibuja SIEMPRE
// que el escudo este activo, igual que el escudo de la Sally vanilla
// (y que el codigo original del canon): es un efecto APARTE que va
// ENCIMA del cuerpo en cualquier estado (quieta, andando, corriendo,
// saltando, cayendo, agachada...) y NO va atado a la animacion del
// cuerpo. v5.4 lo habia atado a poses de cuerpo (quieta/agachada/
// aire) y la burbuja quedaba congelada en un frame o directamente
// invisible segun el estado; eso ya no existe. (v5.8: durante la pose
// de activacion la burbuja sigue encima igual: la pose es del cuerpo,
// la burbuja es del escudo.)
if(shieldTimer > 0)
        draw_sprite(spr_sallyshield_canon, (current_time / 30) % 41, floor(x), floor(y));
