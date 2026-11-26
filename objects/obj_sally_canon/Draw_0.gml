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
// v72 WSS: la escala del fase 2 se compone con la del WSS generico
// (scr_wss). El anclaje al suelo se calcula sobre la escala TOTAL;
// con los dos sistemas en reposo el draw queda igual que siempre.
var _wss = scr_wss_draw();
var _f2xs = image_xscale * _wss[0] * (1 - fase2Sq * 0.6);
var _f2ys = image_yscale * _wss[1] * (1 + fase2Sq);
var _f2yoff = (sprite_height - sprite_yoffset) * (1 - _f2ys);

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

        // v82 (duena): FORMAS CYBER (tecla V). SEMI CYBER / CYBER COMPLETA
        // dibujan el cuerpo con el shader holograma (nivel 1 / 2) y su glow
        // exterior; NORMAL usa el palette swap de siempre. El esbirro
        // siempre devuelve forma 0 (scr_sally_cyber_form). cyberFlash sube
        // el glitch un instante al cambiar de forma.
        var _cyLvl = scr_sally_cyber_form();
        var _cyRot = isSpinning ? 0 : radtodeg(angle);
        var _cyAlp = (hurttime > 0 || isHiding) ? 0.5 : image_alpha;
        var _cyFls = cyberFlash / SALLY_CYBER_FLASH_TIME;

        if(_cyLvl > 0)
        {
                scr_amy_cyber_halo(global.character, _bodySpr, _bodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, _cyAlp);
                scr_amy_cyber(global.character, global.palleteFrom, global.palleteTo, _bodySpr, _bodyIdx, _cyLvl, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, _cyFls);
        }
        else
                scr_palette_swap(global.palleteFrom, global.palleteTo);

        draw_sprite_ext(_bodySpr, _bodyIdx, floor(x), floor(y + _f2yoff), _f2xs, _f2ys, _cyRot, image_blend, _cyAlp);
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

// v62 ITEM BOX v2 — escudo electrico de la caja (electricShieldTimer, 2.5 s).
// Mismo dibujo que el escudo de Eggman (patron obj_egg/Draw_0 L22): sprite
// compartido spr_electroshield, anim por current_time. Lazy var (coyoteTimer
// pattern): los personajes sin la variable no la tocan.
if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)
        draw_sprite(spr_electroshield, (current_time / 30) % 41, floor(x), floor(y));
