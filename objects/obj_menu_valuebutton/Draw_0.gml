if(submenu == 999)
        image_blend = #666666;

draw_self();

// v1 OPTIONS MORE: valor de la fila al estilo del port web
// (toggles en verde/rojo, cyclers en blanco; el port mantiene el color del
// valor tambien con la fila resaltada — verificado pixel a pixel). Se dibuja
// en vivo desde obj_config asi que cualquier cambio (teclado o raton) se ve
// al instante. x+100 deja el valor en ~390 (zona derecha, como el port) y
// y-3 centra los glifos de 6px en la fila de 16px.
var _txt = scr_menu_more_value_text(bid);

if(_txt != "")
{
        var _clr = #ffffff;

        if(bid <= 5) // toggles: verde ON / rojo OFF
                _clr = scr_menu_more_toggle_state(bid) ? #0fff39 : #ff0001;

        scr_text_spr(x + 100, y - 3, _txt, _clr);
}

// clic en cualquier punto de la fila (label + valor, como el port)
if(mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, x - 90, y - 8, x + 130, y + 8))
        obj_menu.buttonPressed(bid, bcolumn);
