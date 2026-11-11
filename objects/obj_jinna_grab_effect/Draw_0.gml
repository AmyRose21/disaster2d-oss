// garra de jinna sujetando a la victima: recorte de su propia pose de
// agarre (spr_jinna_attack2, frame 2) sobre el objetivo, volteada hacia
// donde mire (image_xscale lo fija quien lo crea).
if(instance_exists(target))
        draw_sprite_ext(spr_jinna_attack2, 2, floor(target.x), floor(target.y - target.sprite_yoffset * 0.5),
                        image_xscale, 1, 0, c_white, 0.85);
