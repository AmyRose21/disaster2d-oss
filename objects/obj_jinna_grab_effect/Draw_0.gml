// GARRA de jinna sujetando a la victima.
// v4.2 FIX ("aparece un clon de ella pegada al survivor"): antes se dibujaba
// el frame 2 COMPLETO de spr_jinna_attack2 (46x56: cuerpo entero de Jinna +
// garra) sobre el objetivo — parecia un CLON pegado a la victima. Ahora se
// dibuja SOLO la garra (spr_jinna_claw, recorte 16x33 de ese mismo frame:
// la region del brazo extendido sin cuerpo), volteada hacia donde mire
// (image_xscale lo fija quien lo crea).
//
// Posicionamiento: la garra nace del hombro de Jinna (origen del recorte en
// la base del brazo) y su punta apunta a la victima; se ancla en el centro
// del pecho de la victima (x, y - mitad de su sprite_yoffset) con un pequeño
// adelanto en la direccion del agarre para que las puntas la "claven".
if(instance_exists(target))
{
        var _cx = floor(target.x);
        var _cy = floor(target.y - target.sprite_yoffset * 0.5);

        draw_sprite_ext(spr_jinna_claw, 0, _cx, _cy, image_xscale, 1, 0, c_white, 0.85);
}
