image_speed = 0;
offset = 0;
sY = y;

// v1 OPTIONS MORE: fila reciclable de la pestana MORE.
// displayRow = posicion fija en pantalla (0-8); el bid real (indice del
// ajuste 0-11) lo asigna scr_menu_more_refresh() segun el scroll.
displayRow = 0;

// Red definitivo por si el padre no propagara sus propiedades (bid/bcolumn/
// submenu/tid existen como propiedades de obj_menu_button y se heredan, pero
// asi ningun with(obj_menu_button) puede leer una variable inexistente).
bid = 0;
bcolumn = -1;
submenu = 0;
tid = "";
