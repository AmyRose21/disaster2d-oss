// Al morir el objeto (cambio de room: lobby/results/menu o desconexion):
// si el jugador se fue con el chat abierto, restaurar controles y teclado.
keyboard_virtual_hide();
keyboard_string = "";
global.playerControls = true;
