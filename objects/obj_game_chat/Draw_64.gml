// [v1 IN-GAME CHAT] HUD: ultimos mensajes arriba-izquierda (debajo del
// cluster ping/fps/performance que ocupa y=4..24) con sombra negra para
// que se lean sobre cualquier mapa, y fade-out a los 6 s de cada linea.
// Con el chat abierto: 8 lineas a alpha plena + caja de entrada abajo
// (la misma esquina que el chatbox del lobby). El reloj (centro) y el
// marcador TAB no se tocan.

var _n = array_length(chatLog);
var _now = current_time;

var _max = chatMode ? 8 : 5;
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

        // sombra de legibilidad (hasta x=210: el reloj empieza en x=211)
        draw_set_color(c_black);
        draw_set_alpha(0.45 * _a);
        draw_rectangle(2, 25 + _row * 9, 210, 34 + _row * 9, false);

        draw_set_alpha(_a);
        scr_text_spr(4, 26 + _row * 9, chatLog[i], c_white, _a);
}

draw_set_alpha(1);
draw_set_color(c_white);

// caja de entrada (abajo-izquierda: libre del D-pad tactil y del HUD)
if(chatMode)
{
        draw_set_color(c_black);
        draw_set_alpha(0.8);
        draw_rectangle(2, 258, 218, 268, false);

        draw_set_alpha(1);
        draw_set_color(c_white);

        var _cur = chatMsg;
        if(floor(current_time / 300) % 2 == 0 && string_length(chatMsg) < 48)
                _cur += "-"; // cursor parpadeante (se apaga al llegar al tope)

        scr_text_spr(4, 260, _cur);
}

// boton tactil de chat (Android): burbuja en la columna derecha; con el
// chat abierto se convierte en flecha de ENVIO (tap = enviar y cerrar).
// [v1.4] Mientras se arrastra: marco blanco y alpha pleno.
if(touchUI)
{
        draw_set_color(make_color_rgb(16, 16, 24));
        draw_set_alpha(dragging ? 1 : (chatMode ? 0.9 : 0.55));
        draw_rectangle(btnX, btnY, btnX + btnW, btnY + btnH, false);

        draw_set_color(c_white);
        draw_set_alpha(dragging ? 1 : (chatMode ? 1 : 0.8));

        if(chatMode)
        {
                // flecha de envio: palo vertical + punta
                var _cx = btnX + btnW / 2;
                var _cy = btnY + btnH / 2;

                draw_rectangle(_cx - 1, _cy - 5, _cx + 1, _cy + 4, false); // palo
                draw_rectangle(_cx - 4, _cy - 2, _cx - 1, _cy + 1, false); // punta <
                draw_rectangle(_cx + 1, _cy - 2, _cx + 4, _cy + 1, false); // punta >
        }
        else
        {
                // tres puntitos = burbuja de dialogo
                for(var d = 0; d < 3; d++)
                        draw_rectangle(btnX + 3 + d * 4, btnY + btnH / 2 - 1, btnX + 4 + d * 4, btnY + btnH / 2, false);
        }

        if(dragging)
        {
                // marco de "moviendo": contorno blanco alrededor del boton
                draw_set_color(c_white);
                draw_set_alpha(1);
                draw_rectangle(btnX - 1, btnY - 1, btnX + btnW + 1, btnY + btnH + 1, true);
        }

        draw_set_alpha(1);
        draw_set_color(c_white);
}
