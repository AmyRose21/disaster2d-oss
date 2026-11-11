// [v1.2] blindaje anti-EXE: si el jugador local es el EXE, este HUD no
// debe existir — ni ver ni escribir. Normalmente obj_level ya no lo crea
// (exeId se asigna en la votacion); esto cubre cualquier cambio de rol a
// mitad de ronda. Se devuelve el control antes de morir.
if(obj_netclient.exeId == obj_netclient.nid)
{
        if(chatMode)
        {
                chatMode = false;
                keyboard_virtual_hide();
                global.playerControls = wasControls;
                keyboard_string = "";
        }

        instance_destroy();
        return;
}

// captura del teclado mientras se escribe (igual que obj_lobby/Step)
if(chatMode)
{
        if(keyboard_check(vk_control) && keyboard_check_pressed(ord("V")))
                keyboard_string = clipboard_get_text();

        chatMsg = string_copy(string_lower(keyboard_string), 0, 48);
        if(string_length(keyboard_string) > 48)
                keyboard_string = chatMsg;
}

// boton tactil (Android): abre el chat. Para enviar/cerrar esta el "Done"
// del teclado virtual (dispara el KeyPress_13), igual que en el lobby.
// Se recorren varios dispositivos: el jugador puede tener otro dedo en
// el D-pad (dispositivo 0 ocupado) y tocar el boton con el segundo.
if(touchUI && !chatMode)
{
        for(var m = 0; m < 4; m++)
        {
                if(!device_mouse_check_button_pressed(m, mb_left))
                        continue;

                var _mx = device_mouse_x_to_gui(m);
                var _my = device_mouse_y_to_gui(m);

                if(point_in_rectangle(_mx, _my, btnX, btnY, btnX + btnW, btnY + btnH))
                {
                        chatOpen();
                        break;
                }
        }
}
