// [v1 IN-GAME CHAT] HUD: ultimos mensajes arriba-izquierda (debajo del
// cluster ping/fps/performance que ocupa y=4..24) con sombra negra para
// que se lean sobre cualquier mapa, y fade-out a los 6 s de cada linea.
// Con el chat abierto: lineas a alpha plena + caja de entrada. El reloj
// (centro) y el marcador TAB no se tocan.
//
// [v1.5] ANDROID: la caja de entrada ya NO va abajo. El teclado virtual
// cubre la mitad inferior de la pantalla y tapaba literalmente lo escrito
// (estaba en y258-268, pegada al borde). Con el chat abierto TODO el chat
// se dibuja en la franja libre de la zona alta — a la derecha de los
// iconos de habilidad (x0-96, y18-69) y debajo del reloj/estado
// (y32-44):
//   caja   x100-316, y48-58   |   ENVIAR x320-334, y47-64
//   log    x102+, 6 lineas desde y61 (la ultima acaba en y115: fuera del
//          alcance de cualquier teclado landscape, que arranca ~y121+)
// PC mantiene el layout de siempre (log arriba-izquierda, caja abajo).
// Cerrado en Android el log baja a y72: antes arrancaba en y25 y se
// dibujaba ENCIMA de los iconos de habilidad (x0-96, y18-69).

var _n = array_length(chatLog);
var _now = current_time;

// _topChat: chat abierto en Android = layout de arriba (ver cabecera)
var _topChat = (touchUI && chatMode);
var _max = chatMode ? (touchUI ? 6 : 8) : 5;
var _logX = _topChat ? 102 : 2;
var _logY = _topChat ? 61 : (touchUI ? 72 : 25);
var _boxY = _topChat ? 48 : 258;
var _count = min(_n, _max);
var _first = _n - _count;

for(var i = _first; i < _n; i++)
{
        var _row = i - _first;
        var _a = 1;

        if(!chatMode)
        {
                var _age = _now - chatTime[i];

                if(_age > 6000)
                        _a = 1 - (_age - 6000) / 1000;
        }

        if(_a <= 0)
                continue;

        // sombra de legibilidad (en PC hasta x=210: el reloj empieza en x=211)
        draw_set_color(c_black);
        draw_set_alpha(0.45 * _a);
        draw_rectangle(_logX, _logY + _row * 9, _logX + 208, _logY + _row * 9 + 9, false);

        draw_set_alpha(_a);
        scr_text_spr(_logX + 2, _logY + _row * 9 + 1, chatLog[i], c_white, _a);
}

draw_set_alpha(1);
draw_set_color(c_white);

// caja de entrada: PC abajo-izquierda (libre del D-pad y del HUD),
// Android ARRIBA (v1.5: abajo queda tapada por el teclado — ver cabecera)
if(chatMode)
{
        draw_set_color(c_black);
        draw_set_alpha(0.8);
        draw_rectangle(_topChat ? 100 : 2, _boxY, _topChat ? 316 : 218, _boxY + 10, false);

        draw_set_alpha(1);
        draw_set_color(c_white);

        var _cur = chatMsg;
        if(floor(current_time / 300) % 2 == 0 && string_length(chatMsg) < 48)
                _cur += "-"; // cursor parpadeante (se apaga al llegar al tope)

        scr_text_spr(_topChat ? 102 : 4, _boxY + 2, _cur);
}

// boton tactil de chat (Android): burbuja en su posicion arrastrable;
// con el chat abierto se convierte en flecha de ENVIO y SUBE junto a la
// caja de entrada (v1.5: su sitio normal, mitad inferior, queda tapado
// por el teclado — la hitbox acompaña al dibujo, ver Step).
// [v1.4] Mientras se arrastra: marco blanco y alpha pleno.
if(touchUI)
{
        var _bx = chatMode ? sendX : btnX;
        var _by = chatMode ? sendY : btnY;

        draw_set_color(make_color_rgb(16, 16, 24));
        draw_set_alpha(dragging ? 1 : (chatMode ? 0.9 : 0.55));
        draw_rectangle(_bx, _by, _bx + btnW, _by + btnH, false);

        draw_set_color(c_white);
        draw_set_alpha(dragging ? 1 : (chatMode ? 1 : 0.8));

        if(chatMode)
        {
                // flecha de envio: palo vertical + punta
                var _cx = _bx + btnW / 2;
                var _cy = _by + btnH / 2;

                draw_rectangle(_cx - 1, _cy - 5, _cx + 1, _cy + 4, false); // palo
                draw_rectangle(_cx - 4, _cy - 2, _cx - 1, _cy + 1, false); // punta <
                draw_rectangle(_cx + 1, _cy - 2, _cx + 4, _cy + 1, false); // punta >
        }
        else
        {
                // tres puntitos = burbuja de dialogo
                for(var d = 0; d < 3; d++)
                        draw_rectangle(_bx + 3 + d * 4, _by + btnH / 2 - 1, _bx + 4 + d * 4, _by + btnH / 2, false);
        }

        if(dragging)
        {
                // marco de "moviendo": contorno blanco alrededor del boton
                draw_set_color(c_white);
                draw_set_alpha(1);
                draw_rectangle(_bx - 1, _by - 1, _bx + btnW + 1, _by + btnH + 1, true);
        }

        draw_set_alpha(1);
        draw_set_color(c_white);
}
