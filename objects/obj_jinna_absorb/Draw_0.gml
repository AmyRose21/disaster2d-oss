// ABSORCION DE VANILLA — dos fases:
//  0: el portal abierto (spr_jinna_portal, animado) + Vanilla
//     (spr_vanilla_absorb_trap) encogiendose hacia el centro del portal.
//  1: el portal encogiendo hasta eliminarse (Vanilla ya no se dibuja).
var _portalCY = y - 22; // centro visual del portal a escala 0.55

// frame del portal a 20 fps (el objeto no tiene sprite: avanza a mano)
var _pframe = floor(current_time / 50) % 20;

// el portal: animado en fase 0, encogiendose en fase 1
var _pscale = portalScale;
if(phase == 1)
        _pscale = portalScale * max(0, timer / 30);

if(_pscale > 0)
        draw_sprite_ext(spr_jinna_portal, _pframe, floor(x), floor(y), _pscale, _pscale, 0, c_white, 1);

// Vanilla succionandose: escala 1 -> 0 con deriva hacia el centro del
// portal (spr_vanilla_absorb_trap, 31x46, origen centrado)
if(phase == 0)
{
        var _prog = 1 - max(0, timer) / 72;          // 0 -> 1
        var _vscale = (1 - _prog) * (1 - _prog);      // ease-in: se acelera al caer
        var _vy = lerp(y - 14, _portalCY, _prog);     // deriva al centro del portal

        draw_sprite_ext(spr_vanilla_absorb_trap, 0, floor(x), floor(_vy), _vscale, _vscale, 0, c_white, 1);
}
