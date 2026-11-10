// v1 OPTIONS MORE: solo la fila 0 (displayRow 0) dibuja la descripcion del
// ajuste seleccionado y los indicadores "..." de scroll. Va en Draw GUI
// para quedar POR ENCIMA del fondo del panel (spr_menu_bars es una capa de
// background y taparia un dibujo hecho en Draw normal / Draw Begin).
// Posiciones medidas sobre el port web: descripcion centrada en y=216,
// "..." arriba en y=41 y "..." abajo en y=205, ambos centrados en pantalla.
if(obj_menu.submenu != SUBMENU_OPTIONSMORE || displayRow != 0)
        return;

var _sel = obj_menu.bSelected;

if(_sel >= 0 && _sel < MORE_COUNT)
{
        var _desc = scr_menu_more_desc(_sel);

        if(_desc != "")
        {
                // scr_text_spr devuelve el ancho del texto: se mide una vez fuera
                // de pantalla y se centra con ese ancho
                var _w = scr_text_spr(0, -100, _desc, #646464);
                scr_text_spr(240 - _w / 2, 216, _desc, #646464);
        }
}

var _dw = scr_text_spr(0, -100, "...", #646464);

if(obj_menu.moreScroll > 0)
        scr_text_spr(240 - _dw / 2, 41, "...", #646464);

if(obj_menu.moreScroll < MORE_COUNT - MORE_ROWS)
        scr_text_spr(240 - _dw / 2, 205, "...", #646464);
