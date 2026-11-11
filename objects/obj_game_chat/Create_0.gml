/// [v1.2 IN-GAME CHAT] chat durante la partida — SOLO SUPERVIVIENTES
// Una instancia por nivel: la crea obj_level/Create si el jugador local
// NO es el EXE (el EXE no ve ni usa el chat, por ahora) y muere sola con
// el cambio de room (lobby/results/menu) — CleanUp restaura controles y
// teclado si el jugador se va con el chat abierto. Refuerzo: Step se
// autodestruye si el local resulta ser el EXE.
//
// Entrada:  Enter abre/envia (PC) o el boton tactil (Android, columna
//           derecha; al SOLTAR el dedo — ver Step). Con el chat abierto el
//           boton pasa a ser ENVIAR. En Android el teclado puede morir por
//           cualquier via (Done sin Enter, boton atras, el auto-hide
//           global de scr_controls_update_touch al tocar pantalla): el
//           Step lo detecta (keyboard_virtual_status) y cierra el chat
//           enviando lo escrito — el jugador nunca queda colgado.
//           Mientras se escribe el jugador queda CONGELADO
//           (global.playerControls = false): sin movimiento, habilidades
//           ni emotes — scr_move_basic y los specials ya respetan ese
//           flag (lo usan la zipline y los cutscenes).
// Comandos: .mute / .m (identico al lobby).
// Red:      reusa el paquete CLIENT_CHAT_MESSAGE de siempre. El server
//           (Game.c mod v1.2) reenvia a los jugadores de la ronda menos
//           al emisor y menos al EXE; el eco es local (chatClose).

depth = -1200; // por encima del HUD de obj_level (-1000)

chatLog = [];    // lineas listas para scr_text_spr
chatTime = [];   // current_time de cada linea (para el fade)
chatMode = false;
chatMsg = "";
wasControls = true;
kbGrace = 0; // [v1.3] frames de gracia hasta que sube el teclado virtual

// boton tactil: columna derecha, en el hueco de ~19 px entre el boton F
// (circulo y~90-134) y el boton V del parry de Amy Canon (y~154-198).
// v1 lo ponia en y 142-170: la mitad inferior pisaba el circulo del V y
// un tap en el chat disparaba tambien el parry.
// [v1.4] La posicion vive en obj_config.chatTouch (CENTRO, como los
// demas botones) y se puede ARRASTRAR en partida: mantener el dedo y
// moverlo mas de 12 px = mover el boton (se guarda al soltar); toque
// corto = abrir/enviar. Solo se dibuja en Android.
btnW = 14;
btnH = 17;
btnX = obj_config.bChatX - btnW / 2;
btnY = obj_config.bChatY - btnH / 2;
touchUI = (os_type == os_android);

// estado del arrastre (ver Step)
dragId = -1;       // dispositivo tactil que empezo en el boton (-1 = nadie)
dragging = false;  // supero el umbral: es arrastre, no toque
dragOffX = 0;      // agarre: distancia dedo -> esquina del boton
dragOffY = 0;
wasJuse = true;    // jUse/bUse de obj_controls antes del arrastre
wasBuse = true;

// [v1.5] boton ENVIAR con el chat abierto (Android): en vez de quedarse en
// su sitio de siempre (columna derecha, mitad inferior — TAPADO por el
// teclado virtual), sube junto a la caja de entrada de arriba. Coordenadas
// fijas de la franja libre de la zona alta (ver Draw para el mapa).
sendX = 320;
sendY = 47;
dragOnSend = false; // el dedo nacio sobre ese ENVIAR (al soltar no reabre)

// ancho maximo de linea (en caracteres) antes de partir el mensaje
wrapLen = 34;

// -------------------------------------------------------------------------
// Empujar un mensaje al log (sonido + filtro + wrap). Espejo de
// lobby_add_message (net_state_lobby) pero con timestamps para el fade
// de partida y tope propio de lineas.
addMsg = function(sender, msg)
{
        if(global.muteChat)
                return;

        audio_stop_sound(snd_message);
        audio_play_sound(snd_message, 0, false);

        var lines = wrapLines(sender + ": " + scr_chat_filter(msg) + "~");

        for(var i = 0; i < array_length(lines); i++)
        {
                array_push(chatLog, lines[i]);
                array_push(chatTime, current_time);
        }

        while(array_length(chatLog) > 8)
        {
                array_delete(chatLog, 0, 1);
                array_delete(chatTime, 0, 1);
        }
};

// Parte una linea en trozos de <= wrapLen caracteres respetando espacios
// (las palabras kilometricas se cortan a lo bruto: el chat capta 48).
wrapLines = function(line)
{
        var out = [];
        var cur = "";
        var word = "";
        var len = string_length(line);

        for(var i = 1; i <= len; i++)
        {
                var ch = string_char_at(line, i);

                if(ch == " ")
                {
                        if(cur != "" && string_length(cur) + 1 + string_length(word) > wrapLen)
                        {
                                array_push(out, cur);
                                cur = word;
                        }
                        else
                                cur = cur == "" ? word : cur + " " + word;

                        word = "";
                }
                else
                        word += ch;

                // palabra kilometrica: cortar en seco
                if(string_length(word) >= wrapLen)
                {
                        if(cur != "")
                        {
                                array_push(out, cur);
                                cur = "";
                        }

                        array_push(out, word);
                        word = "";
                }
        }

        if(word != "")
        {
                if(cur != "" && string_length(cur) + 1 + string_length(word) > wrapLen)
                {
                        array_push(out, cur);
                        array_push(out, word);
                }
                else
                        cur = cur == "" ? word : cur + " " + word;
        }

        if(cur != "")
                array_push(out, cur);

        return out;
};

// -------------------------------------------------------------------------
chatOpen = function()
{
        chatMode = true;
        wasControls = global.playerControls;
        global.playerControls = false;

        keyboard_string = chatMsg; // recupera el borrador
        keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_none, true);

        // [v1.3] margen para que el teclado suba antes de que el Step
        // empiece a vigilar keyboard_virtual_status (dispositivos lentos)
        kbGrace = 45;
};

chatClose = function(send)
{
        chatMode = false;
        keyboard_virtual_hide();
        global.playerControls = wasControls;

        if(send && chatMsg != "")
        {
                switch(chatMsg)
                {
                        case ".mute":
                        case ".m":
                                // mismo orden que el lobby: el aviso de mute
                                // se pinta ANTES de activar el silencio (y el
                                // de unmute DESPUES de quitarlo)
                                if(global.muteChat)
                                {
                                        global.muteChat = false;
                                        addMsg("(mute)", "@chat is now unmuted.~");
                                }
                                else
                                {
                                        addMsg("(mute)", "\\chat is now muted.~");
                                        global.muteChat = true;
                                }
                                break;

                        default:
                                var packet = cpacket_tcp(PacketType.CLIENT_CHAT_MESSAGE, true);
                                buffer_write(packet, buffer_u16, obj_netclient.nid);
                                buffer_write(packet, buffer_string, scr_chat_filter(chatMsg));
                                send_server_tcp(packet);

                                // eco local: ver comentario de cabecera
                                addMsg(global.nickname, chatMsg);
                                break;
                }
        }

        chatMsg = "";
        keyboard_string = "";
};
