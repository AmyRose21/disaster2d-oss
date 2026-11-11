// Al morir el objeto (cambio de room: lobby/results/menu o desconexion):
// si el jugador se fue con el chat abierto, restaurar controles y teclado.
// [v1.4] Si murio en mitad de un arrastre del boton, devolver jUse/bUse a
// obj_controls (se apagan durante el arrastre para no disparar habilidades
// al pasar el dedo por encima de otros botones — ver Step).
if(dragging && instance_exists(obj_controls))
{
        obj_controls.jUse = wasJuse;
        obj_controls.bUse = wasBuse;
}

keyboard_virtual_hide();
keyboard_string = "";
global.playerControls = true;
