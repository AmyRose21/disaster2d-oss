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

// v3/v4/v18 — ATRAPADAS EN LA OTRA DIMENSION: senales flotando sobre la
// cabeza de Jinna, SOLO en su cliente (este Draw no corre en los demas).
// v18: si Jinna atrapa a MAS DE UNA, cada nueva especial se ACOMODA AL
// LADO de la que ya capturaba — LA FILA SE ACUMULA. Ojo: SOLO las que
// tienen animacion especial entran a la fila (Amy Canon, Sally Canon,
// Vanilla y ahora Amelia con su muneco spr_amelia_doll_placed); Rouge y
// las capturas genericas conservan su fantasma individual, visible solo
// mientras NINGUNA especial flota. Cada una mantiene su estilo propio:
//   * VANILLA: su pantalla (spr_vanilla_caught, 170x94) al 72%.
//   * AMY CANON / SALLY CANON: version SEMI-TRANSPARENTE de su pose canon.
//   * AMELIA: su muneco colocadito (spr_amelia_doll_placed).
// Mientras esten aqui, su presencia POTENCIA el kit con mejoras DIRECTAS
// acumulativas (scr_jinna_power en scr_jinna_special).
// v18: cuantas especiales de la fila ya salieron (delay agotado). La fila
// es AUTONOMA: cada muneco se muestra solo cuando SU cuenta atras termina
// (no depende del flag del fantasma individual — si la primera captura es
// una especial, su muneco aparece sin pasar por jinnaCaughtShow).
var _dollN = array_length(jinnaCaughtDolls);
var _dollShown = 0;

for(var _ji = 0; _ji < _dollN; _ji++)
{
        if(jinnaCaughtDollDelay[_ji] <= 0)
                _dollShown++;
}

if(_dollShown > 0)
{
        var _bob = sin(current_time / 300) * 3;

        // ancho total del grupo (14 px de separacion entre munecos)
        var _wT = 0;

        for(var _ji = 0; _ji < _dollN; _ji++)
        {
                if(jinnaCaughtDollDelay[_ji] > 0)
                        continue;

                var _js = jinnaCaughtDolls[_ji];
                _wT += sprite_get_width(_js) * ((_js == spr_vanilla_caught) ? 0.72 : 1) + 14;
        }

        _wT -= 14;

        // el grupo se CENTRA sobre su cabeza y se dibuja de izq a der
        // en ORDEN DE CAPTURA: la nueva queda al lado de las viejas
        var _xcur = floor(x) - _wT / 2;

        for(var _ji = 0; _ji < _dollN; _ji++)
        {
                if(jinnaCaughtDollDelay[_ji] > 0)
                        continue;

                var _js = jinnaCaughtDolls[_ji];
                var _jsc = (_js == spr_vanilla_caught) ? 0.72 : 1;
                var _jw = sprite_get_width(_js) * _jsc;
                var _jcx = floor(_xcur + _jw / 2);

                // pantalla de Vanilla: mas solida (0.85) y mas abajo;
                // fantasmas canon semitransparentes (0.5) y el muneco
                // de Amelia colocado al estilo canon
                if(_js == spr_vanilla_caught)
                        draw_sprite_ext(_js, 0, _jcx, floor(y - 44 + _bob), image_xscale * _jsc, _jsc, 0, c_white, 0.85);
                else
                        draw_sprite_ext(_js, 0, _jcx, floor(y - 65 + _bob), image_xscale * _jsc, _jsc, 0, c_white, 0.5);

                _xcur += _jw + 14;
        }
}
else if(jinnaCaughtShow)
{
        var _bob = sin(current_time / 300) * 3;

        // sin especiales en la fila: el fantasma individual de siempre
        // (Rouge / captura generica — el sprite llega en jinnaCaughtSprite)
        if(jinnaCaughtKind == JINNA_CAUGHT_AMY)
                draw_sprite_ext(jinnaCaughtSprite, 0, floor(x), floor(y - 65 + _bob), image_xscale, 1, 0, c_white, 0.5);
        else
                draw_sprite_ext(jinnaCaughtSprite, 0, floor(x), floor(y - 44 + _bob), image_xscale * 0.72, 0.72, 0, c_white, 0.85);
}

//hakc
if(isDead)
{
        xspd = 0;
        gspd = 0;
        return;
}
