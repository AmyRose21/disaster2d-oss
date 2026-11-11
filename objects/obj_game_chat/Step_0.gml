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

// [v1.3] ANDROID: autodefensa del teclado virtual. En Android el teclado
// muere por cualquier via, no solo por el Done: el auto-hide global de
// scr_controls_update_touch lo esconde si un toque en pantalla se
// mantiene >0.1 s (con el v1, el tap que ABRIO el chat mataba el teclado
// al nacer), y lo mismo el boton atras o un cambio de app — sin disparar
// Enter. Como no hay Enter/Esc fisicos, chatMode quedaba colgado: caja
// de entrada visible, jugador CONGELADO y boton muerto. Si pasado el
// periodo de gracia (kbGrace: el teclado tarda en subir) el teclado ya
// no esta visible, se cierra el chat enviando lo escrito.
if(touchUI && chatMode)
{
        if(kbGrace > 0)
                kbGrace--;
        else if(!keyboard_virtual_status())
                chatClose(true);
}

// boton tactil (Android) [v1.4]: toque corto = abrir chat / enviar (v1.3);
// mantener y mover (>12 px) = ARRASTRAR el boton a donde quieras: al
// soltar se guarda la posicion en obj_config.chatTouch (sobrevive a
// reinicios de la app). Durante el arrastre se apagan los botones
// tactiles de obj_controls (jUse/bUse, mismo criterio que el votekick)
// para que el dedo no dispare habilidades ni mueva el joystick al pasar
// por encima; se restauran al soltar (y en CleanUp si el objeto muere a
// mitad de arrastre). Con el chat ABIERTO no se arrastra: el boton es
// ENVIAR y el teclado esta arriba.
// Se recorren varios dispositivos: el jugador puede tener otro dedo en
// el D-pad (dispositivo 0 ocupado) y tocar el boton con el segundo.
if(touchUI)
{
        if(dragId == -1)
        {
                // dedo nuevo: empezar a seguirlo si nacio sobre el boton
                for(var m = 0; m < 4; m++)
                {
                        if(!device_mouse_check_button_pressed(m, mb_left))
                                continue;

                        var _mx = device_mouse_x_to_gui(m);
                        var _my = device_mouse_y_to_gui(m);

                        if(point_in_rectangle(_mx, _my, btnX, btnY, btnX + btnW, btnY + btnH))
                        {
                                dragId = m;
                                dragging = false;
                                dragOffX = _mx - btnX;
                                dragOffY = _my - btnY;
                                break;
                        }
                }
        }
        else if(device_mouse_check_button(dragId, mb_left))
        {
                // el dedo sigue apoyado: seguirlo
                var _mx = device_mouse_x_to_gui(dragId);
                var _my = device_mouse_y_to_gui(dragId);

                // umbral de 12 px: separa "toque" de "arrastre" (con el
                // chat abierto nunca se arrastra)
                if(!dragging && !chatMode)
                {
                        if(abs(_mx - (btnX + dragOffX)) + abs(_my - (btnY + dragOffY)) > 12)
                        {
                                dragging = true;

                                if(instance_exists(obj_controls))
                                {
                                        wasJuse = obj_controls.jUse;
                                        wasBuse = obj_controls.bUse;
                                        obj_controls.jUse = false;
                                        obj_controls.bUse = false;
                                }
                        }
                }

                if(dragging)
                {
                        btnX = clamp(_mx - dragOffX, 0, 480 - btnW);
                        btnY = clamp(_my - dragOffY, 0, 270 - btnH);
                }
        }
        else
        {
                // solto el dedo
                if(dragging)
                {
                        // fue un arrastre: fijar y guardar la posicion
                        obj_config.bChatX = btnX + btnW / 2;
                        obj_config.bChatY = btnY + btnH / 2;
                        obj_config.save();

                        if(instance_exists(obj_controls))
                        {
                                obj_controls.jUse = wasJuse;
                                obj_controls.bUse = wasBuse;
                        }
                }
                else
                {
                        // fue un toque corto: alternar abrir/enviar (v1.3)
                        if(chatMode)
                                chatClose(true);
                        else
                                chatOpen();
                }

                dragId = -1;
                dragging = false;
        }
}
