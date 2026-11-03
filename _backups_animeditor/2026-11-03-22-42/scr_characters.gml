/// @desc Registro central de personajes y slots (avCharacters).
///
/// SEGURO DE SLOTS (v2.2.3): antes el array avCharacters estaba
/// copiado a mano en 7 sitios y al agregar Blaze (v2.2) solo se
/// actualizaron 3 de ellas => "Variable Index [13] out of range
/// [11]" en el Draw del lobby (crash al ciclar hasta Blaze o al
/// recibir su CHARACTER_CHANGE). Ahora:
///   * scr_avchars_reset() dimensiona el array SOLO, segun los
///     macros de personaje de scr_survivors / scr_exe. Las 7
///     copias del literal desaparecen.
///   * scr_avchar_get() / scr_avchar_set() son el UNICO modo
///     valido de leer/escribir el array: jamas crashean, y el
///     set crea slots nuevos al vuelo si un server mas moderno
///     manda un personaje que este cliente aun no conoce (queda
///     marcado como ocupado: nadie puede elegirlo, pero nadie
///     crashea).
///   * scr_characters_sanity() (lo llama obj_lobby al crearse,
///     una sola vez) revisa que TODO registro indexado por
///     personaje (chars[], palettes, player_anims, player_get)
///     cubra hasta el ultimo personaje y avisa por consola lo
///     que falte, en vez de crashear en mitad de una partida.
///
/// PARA AGREGAR UN PERSONAJE NUEVO (un solo sitio por cosa):
///   1. scr_survivors.gml: #macro CHARACTER_XXX AL FINAL de la
///      lista (nunca reordenar los existenes) + sus player_anims
///      + case en player_get().
///   2. scr_exe.gml (si es killer): macro EXE_XXX al final.
///   3. AQUI NO HAY QUE TOCAR NADA: CHARACTER_SURV_MAX apunta al
///      ultimo macro, asi que el array de slots y el sanity se
///      ajustan solos. (Solo scr_char_name() para los logs.)
///   4. Server (betterserver): enum CH_XXX al final en
///      include/Server.h + nombre en states/CharSelect.c
///      (survs[]/exes[]); avail[] ya se dimensiona con el tope
///      del enum.
///   5. Assets: retrato en obj_lobby chars[], frame en la tira
///      spr_lobby_icon, placa spr_char_info, icono exe si es
///      killer, y paleta default en obj_unlockables. Si algo de
///      esto se te olvida, [charsanity] te lo dice al arrancar.

// Tope de supervivientes: el ULTIMO macro de la lista de
// scr_survivors. Al agregar un pj nuevo al final, este macro
// queda apuntando al nuevo automaticamente.
#macro CHARACTER_SURV_MAX CHARACTER_BLAZE

// Total de slots de personaje (exe + supervivientes).
#macro CHARACTER_COUNT (CHARACTER_SURV_MAX + 1)

// Total de killers (scr_exe). EXE_METALAMY es el ultimo macro.
#macro EXE_CHAR_COUNT (EXE_METALAMY + 1)

// Entradas que necesita chars[] del lobby: los supervivientes
// (indices 0..SURV_MAX-1) + los killers (offset SURV_MAX).
#macro LOBBY_CHARS_MIN (CHARACTER_SURV_MAX + EXE_CHAR_COUNT)

// Nombre corto para logs/debugs. NO usar para logica.
function scr_char_name(ch)
{
        switch(ch)
        {
                case CHARACTER_EXE: return "Exe";
                case CHARACTER_TAILS: return "Tails";
                case CHARACTER_KNUX: return "Knuckles";
                case CHARACTER_EGGMAN: return "Eggman";
                case CHARACTER_AMY: return "Amy";
                case CHARACTER_CREAM: return "Cream";
                case CHARACTER_SALLY: return "Sally";
                case CHARACTER_AMY_CANON: return "Amy Canon";
                case CHARACTER_SONIC: return "Sonic";
                case CHARACTER_SALLY_CANON: return "Sally Canon";
                case CHARACTER_VANILLA: return "Vanilla";
                case CHARACTER_METAL: return "Metal Sonic";
                case CHARACTER_AMELIA: return "Amelia";
                case CHARACTER_BLAZE: return "Blaze";
        }

        return "desconocido #" + string(ch);
}

// Array de slots fresco: [exe=false, resto=true]. Se dimensiona
// SOLO segun CHARACTER_SURV_MAX: agregar un pj nuevo no requiere
// tocar ningun literal mas. Reemplaza a las 7 copias que habia
// (obj_netclient Create, net_wrapper, net_tcpprocess,
// net_state_game x3, obj_level Alarm_2).
function scr_avchars_reset()
{
        var _a = array_create(CHARACTER_COUNT, true);
        _a[CHARACTER_EXE] = false; // el slot 0 (exe) nunca esta libre
        return _a;
}

// LECTURA blindada de un slot: fuera de rango => false + log.
// NUNCA leer con avCharacters[ch] directo.
function scr_avchar_get(ch)
{
        if(!instance_exists(obj_netclient))
                return false;

        var _a = obj_netclient.avCharacters;

        if(!is_array(_a))
                return false;

        if(ch < 0 || ch >= array_length(_a))
        {
                show_debug_message($"[chars] lectura fuera de rango {ch} (max {array_length(_a) - 1}) - se toma como ocupado");
                return false;
        }

        return _a[ch];
}

// ESCRITURA blindada de un slot. Si ch cae mas alla del tope
// (server mas moderno con un pj que este cliente no conoce),
// crea los slots que falten al vuelo en vez de crashear. Los
// huecos nuevos quedan en 0 (false = ocupado), que es lo SEGURO:
// un pj desconocido para este cliente queda innombrable.
function scr_avchar_set(ch, val)
{
        if(ch < 0)
                return false;

        if(!instance_exists(obj_netclient))
        {
                show_debug_message($"[chars] set de {ch} sin obj_netclient: ignorado");
                return false;
        }

        if(!is_array(obj_netclient.avCharacters))
        {
                show_debug_message("[chars] avCharacters no era un array: recreado con scr_avchars_reset()");
                obj_netclient.avCharacters = scr_avchars_reset();
        }

        var _len = array_length(obj_netclient.avCharacters);

        if(ch >= _len)
        {
                // En GML escribir fuera de rango expande el array el
                // solo (los huecos quedan en 0 = ocupado), asi que no
                // hace falta array_resize: la escritura de abajo crea
                // el slot por si misma.
                show_debug_message($"[chars] slot {ch} ({scr_char_name(ch)}) creado automaticamente (antes habia {_len}): server mas moderno que este cliente");
        }

        obj_netclient.avCharacters[ch] = val;
        return true;
}

// Chequeo de integridad de TODOS los registros indexados por
// personaje. Lo llama obj_lobby al crearse (solo la primera vez)
// y unicamente LOGUEA por consola lo que falte: convierte un
// futuro crash critico en un warning legible al arrancar.
// El propio sanity nunca crashea: si algo no existe todavia, lo
// anota y sigue.
function scr_characters_sanity()
{
        if(variable_global_exists("__charsanity") && global.__charsanity)
                return;
        global.__charsanity = true;

        var _missing = 0;

        // 1) array de slots
        if(!instance_exists(obj_netclient))
        {
                show_debug_message("[charsanity] obj_netclient no existe todavia: chequeo de slots omitido");
        }
        else
        {
                var _av = obj_netclient.avCharacters;
                if(!is_array(_av) || array_length(_av) < CHARACTER_COUNT)
                {
                        var _avLen = is_array(_av) ? array_length(_av) : 0;
                        show_debug_message($"[charsanity] avCharacters tiene {_avLen} slots, se esperaban {CHARACTER_COUNT}: usa scr_avchars_reset()");
                        _missing++;
                }
        }

        // 2) retratos del lobby (supervivientes + killers)
        if(instance_exists(obj_lobby))
        {
                var _chars = obj_lobby.chars;
                if(!is_array(_chars) || array_length(_chars) < LOBBY_CHARS_MIN)
                {
                        var _chLen = is_array(_chars) ? array_length(_chars) : 0;
                        show_debug_message($"[charsanity] obj_lobby.chars tiene {_chLen} entradas, se esperaban {LOBBY_CHARS_MIN} (retratos + killers)");
                        _missing++;
                }
        }

        // 3) paletas + 4) anims + 5) player_get de cada superviviente
        // (el codigo global de scr_survivors corre al arrancar el juego,
        // antes que cualquier room: con solo comprobar que la variable
        // global existe alcanza)
        var _haveAnims = variable_global_exists("player_anims");
        for(var ch = CHARACTER_TAILS; ch <= CHARACTER_SURV_MAX; ch++)
        {
                if(instance_exists(obj_unlockables) && !ds_map_exists(obj_unlockables.palettes, ch))
                {
                        show_debug_message($"[charsanity] sin paleta default para {scr_char_name(ch)} (obj_unlockables)");
                        _missing++;
                }

                if(_haveAnims && !ds_map_exists(global.player_anims, ch))
                {
                        show_debug_message($"[charsanity] sin anims para {scr_char_name(ch)} (scr_survivors)");
                        _missing++;
                }

                if(is_undefined(player_get(ch)))
                {
                        show_debug_message($"[charsanity] player_get() no devuelve objeto para {scr_char_name(ch)}");
                        _missing++;
                }
        }

        if(_missing == 0)
                show_debug_message($"[charsanity] OK: {CHARACTER_SURV_MAX} supervivientes + {EXE_CHAR_COUNT} killers = {CHARACTER_COUNT} slots");
}
