/// =====================================================================
///  scr_hud_keycap — v4.3: TECLAS DINAMICAS EN EL HUD
///
///  PROBLEMA: los iconos de habilidad del HUD (obj_playerui) tienen la
///  letra de la tecla HORNEADA en el PNG (keycap blanco + letra negra).
///  Si el usuario remapea (ej: special2 de X a F), el juego responde a
///  la F pero el icono seguia diciendo (X).
///
///  SOLUCION: este script dibuja ENCIMA de cada keycap horneado un
///  keycap limpio (spr_gui_keycap, el mismo arte sin letra) y la letra
///  de la tecla ACTUAL (global.KeyA/KeyB/KeyC/KeyV/KeyEm*), tomada en
///  vivo cada frame -> si el usuario cambia la tecla en Opciones ->
///  Controles, el HUD se actualiza AL INSTANTE, sin reiniciar nada.
///
///  Las letras se dibujan con la micro-fuente solida spr_gui_keyletter
///  (3x5 px, negra, misma talla que las letras horneadas originales),
///  no con spr_letter1: esa fuente es "cara blanca + sombra negra" y al
///  mezclarla con negro se vuelve un bloque ilegible.
///
///  Tambien corrige de paso letras horneadas inconsistentes:
///   - spr_gui_eggshield (X horneada) usado por Metal para su campo
///     electrico que es tecla C -> ahora muestra la C real.
///   - spr_gui_sonicdropdash (X horneada) siendo habilidad de Z.
///   - spr_gui_chaosslime / amelia_trap con letra rara horneada.
///   - spr_gui_metalamyattack no tenia NINGUNA tecla -> ahora si.
///
///  FUNCIONES:
///   scr_hud_icon(_spr, _frame, _x, _y, _key, _blend, _alpha)
///      Reemplaza a draw_sprite_ext para los iconos del HUD: dibuja el
///      icono Y su keycap dinamico de una vez.
///   scr_hud_keycap(_spr, _x, _y, _key, _blend, _alpha)
///      Dibuja solo el keycap dinamico sobre el horneado del sprite
///      (busca la posicion en la tabla de abajo).
///   scr_hud_keycap_at(_kx, _ky, _key, _blend, _alpha, _maxW)
///      Nucleo: dibuja keycap + letra en coordenadas exactas de pantalla.
///
///  En Android el HUD usa las mismas llamadas (solo cambia la Y con el
///  offset -200 que ya hacia obj_playerui), y como el touch simula
///  global.Key*, las letras siempre coinciden con los botones en pantalla.
/// =====================================================================

/// Dibuja un icono del HUD + su keycap con la tecla ACTUAL.
/// Sustituye a: draw_sprite_ext(_spr, _frame, _x, _y, 1, 1, 0, _blend, _alpha)
function scr_hud_icon(_spr, _frame, _x, _y, _key, _blend, _alpha)
{
        draw_sprite_ext(_spr, _frame, _x, _y, 1, 1, 0, _blend, _alpha);
        scr_hud_keycap(_spr, _x, _y, _key, _blend, _alpha);
}

/// Dibuja el keycap dinamico sobre el keycap horneado de un icono del HUD.
/// La posicion del keycap horneado (en pixeles del sprite, desde su
/// esquina superior izquierda) esta en la tabla: se midio analizando los
/// PNG de cada sprite (bloque 8x9 del borde derecho o de la letra outline).
/// Se usa una cadena de if/else con comparacion directa de sprite (mismo
/// patron que "spr == spr_gui_exellerclone" que ya usaba Draw_64.gml).
function scr_hud_keycap(_spr, _x, _y, _key, _blend, _alpha)
{
        var _kc = undefined;

        // --- EXE y variantes ---
        if(_spr == spr_gui_exeattack)             _kc = [21, 0];              // X golpe
        else if(_spr == spr_gui_exefreejump)      _kc = [28, 6];              // Z salto libre
        else if(_spr == spr_gui_exeinvisability)  _kc = [27, 5];              // C invisibilidad
        else if(_spr == spr_gui_chaosattack)      _kc = [21, 3];              // X golpe (antes letra outline)
        else if(_spr == spr_gui_chaoswalldash)    _kc = [21, 3, make_color_rgb(135, 200, 247)]; // keycap azulado del original
        else if(_spr == spr_gui_chaosslime)       _kc = [20, 3];              // C slime (letra horneada rara)
        else if(_spr == spr_gui_exetiorattack)    _kc = [21, 0];              // X golpe (antes letra outline)
        else if(_spr == spr_gui_exetiorring)      _kc = [22, 3];              // C anillos (antes letra outline)
        else if(_spr == spr_gui_exellerclone)     _kc = [22, 5];              // C clon
        else if(_spr == spr_gui_exellerclone2)    _kc = [48, 2];              // C clon (2 iconos)
        else if(_spr == spr_gui_metalamyattack)   _kc = [21, 0];              // X golpe (no tenia tecla!)
        else if(_spr == spr_gui_metal_amy_lazer)  _kc = [25, 2];              // C bala (antes letra outline)

        // --- Supervivientes ---
        else if(_spr == spr_gui_tailsfly)         _kc = [28, 0];              // Z vuelo
        else if(_spr == spr_gui_tailsattack)      _kc = [26, 2];              // X cola
        else if(_spr == spr_gui_knuxglide)        _kc = [21, 0];              // Z planeo
        else if(_spr == spr_gui_knuxattack)       _kc = [21, 0];              // X golpe
        else if(_spr == spr_gui_eggdjump)         _kc = [22, 3];              // Z doble salto
        else if(_spr == spr_gui_eggshield)        _kc = [22, 0];              // X escudo / C campo (Metal)
        else if(_spr == spr_gui_eggtrack)         _kc = [39, 1];              // C rastreador
        else if(_spr == spr_gui_amyhjump)         _kc = [33, 1];              // Z salto martillo
        else if(_spr == spr_gui_amyattack)        _kc = [25, 5];              // X golpe (Amy/Sonic/Blaze)
        else if(_spr == spr_gui_amyhjump_canon)   _kc = [33, 1];              // Z salto martillo
        else if(_spr == spr_gui_amyattack_canon)  _kc = [25, 5];              // X tarot aereo
        else if(_spr == spr_gui_amydash_canon)    _kc = [25, 5];              // C acometida
        else if(_spr == spr_gui_amyparry_canon)   _kc = [25, 5];              // V parry
        else if(_spr == spr_gui_amydj_fw)         _kc = [26, 0];              // A DJ doble salto (Fleetway)
        else if(_spr == spr_gui_amyattack_fw)     _kc = [25, 5];              // B puño/patada (Fleetway)
        else if(_spr == spr_gui_amycrossbow_fw)   _kc = [24, 5];              // C ballesta (Fleetway)
        else if(_spr == spr_gui_sonicparry)       _kc = [25, 5];              // C parry (Sonic)
        else if(_spr == spr_gui_sonicspindash)    _kc = [34, 2];              // Z spindash (Sonic/Amelia)
        else if(_spr == spr_gui_sonicdropdash)    _kc = [35, 3];              // Z drop dash (tenia X horneada!)
        else if(_spr == spr_gui_creamfly)         _kc = [27, 6];              // Z vuelo
        else if(_spr == spr_gui_creamdash)        _kc = [23, 2];              // X dash (Cream/Vanilla/Metal)
        else if(_spr == spr_gui_creamrings)       _kc = [23, 2];              // C anillos
        else if(_spr == spr_gui_sonicspring)      _kc = [34, 0];              // X trampolin (Amelia)
        else if(_spr == spr_gui_amelia_trap)      _kc = [40, 2];              // C trampa
        else if(_spr == spr_gui_sallyattack)      _kc = [20, 1];              // X patada (Sally)
        else if(_spr == spr_gui_sallyshield)      _kc = [21, 1];              // C escudo (Sally/Blaze)

        if(_kc == undefined)
                return; // sprite sin keycap conocido: no dibujar (no crashea)

        // El draw coloca el ORIGEN del sprite en (_x, _y): convertir la
        // posicion del keycap (px del sprite) a coordenadas de pantalla.
        var _kx = _x - sprite_get_xoffset(_spr) + _kc[0];
        var _ky = _y - sprite_get_yoffset(_spr) + _kc[1];

        // Blend especial (chaoswalldash conserva el tinte azulado original)
        var _blendK = _blend;
        if(array_length(_kc) >= 3)
                _blendK = _kc[2];

        scr_hud_keycap_at(_kx, _ky, _key, _blendK, _alpha, 0);
}

/// Nucleo: dibuja el keycap (spr_gui_keycap) + la letra de la tecla
/// ACTUAL en (_kx, _ky) con el blend/alpha del icono. Letras negras con
/// la micro-fuente solida del juego (spr_gui_keyletter, 3x5), misma
/// talla que las letras horneadas originales. Nombres largos ("shift",
/// "enter"...) ensanchan el keycap. _maxW > 0 limita el ancho (para
/// zonas pegadas al borde derecho de la pantalla, como las emociones).
function scr_hud_keycap_at(_kx, _ky, _key, _blend, _alpha, _maxW = 0)
{
        var _sprKc = asset_get_index("spr_gui_keycap");
        var _sprLt = asset_get_index("spr_gui_keyletter");
        if(_sprKc < 0 || _sprLt < 0)
                return; // sin los sprites no se dibuja, pero no crashea (patron del juego)

        var _name = scr_controls_keycode_to_key(_key);
        var _len = string_length(_name);
        if(_len <= 0)
        {
                _name = "?";
                _len = 1;
        }

        // ancho del texto: avance 4px por glifo (3 del dibujo + 1 de
        // espaciado), 3px el espacio; el espaciado final no cuenta
        var _tw = 0;
        for(var i = 1; i <= _len; i++)
                _tw += (string_char_at(_name, i) == " ") ? 3 : 4;
        _tw -= 1;

        // recortar el nombre si hay ancho maximo y no cabe
        if(_maxW > 0)
        {
                while(_len > 1 && _tw + 2 > _maxW)
                {
                        _name = string_copy(_name, 1, _len - 1);
                        _len--;
                        _tw -= 4;
                }
        }

        // keycap: ancho minimo 8px, ensanchado si el nombre es largo
        var _kw = max(8, _tw + 3);
        draw_sprite_ext(_sprKc, 0, _kx, _ky, _kw / 8, 1, 0, _blend, _alpha);

        // letra centrada dentro del keycap (glifos 3x5, fila y+2)
        var _lx = _kx + floor((_kw - _tw) * 0.5);
        var _ly = _ky + 2;

        for(var i = 1; i <= _len; i++)
        {
                var c = string_char_at(_name, i);

                if(c == " ")
                {
                        _lx += 3;
                        continue;
                }

                // frame en spr_gui_keyletter: a-z (0-25), 0-9 (26-35), '-' (36), '?' (37)
                var ind = 37;
                var _ord = ord(c);
                if(_ord >= ord("a") && _ord <= ord("z"))
                        ind = _ord - 97;
                else if(c == "0")
                        ind = 26;
                else if(_ord >= ord("1") && _ord <= ord("9"))
                        ind = 27 + (_ord - ord("1"));
                else if(c == "-")
                        ind = 36;

                draw_sprite_ext(_sprLt, ind, _lx, _ly, 1, 1, 0, _blend, _alpha);
                _lx += 4;
        }
}
