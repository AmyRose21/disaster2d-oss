/// [v1.2 IN-GAME CHAT] chat durante la partida — SOLO SUPERVIVIENTES
// Una instancia por nivel: la crea obj_level/Create si el jugador local
// NO es el EXE (el EXE no ve ni usa el chat, por ahora) y muere sola con
// el cambio de room (lobby/results/menu) — CleanUp restaura controles y
// teclado si el jugador se va con el chat abierto. Refuerzo: Step se
// autodestruye si el local resulta ser el EXE.
//
// Entrada:  Enter abre/envia (PC) o el boton tactil (Android, columna
//           derecha). Mientras se escribe el jugador queda CONGELADO
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

// boton tactil: columna derecha, en el hueco entre el boton F (y~98-130)
// y el boton V de Amy Canon (y~176). Solo se dibuja en Android.
btnX = 466;
btnY = 142;
btnW = 14;
btnH = 28;
touchUI = (os_type == os_android);

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
