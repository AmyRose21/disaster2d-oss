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
#macro CHARACTER_SURV_MAX CHARACTER_FLEETWAY_AMY

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
                case CHARACTER_FLEETWAY_AMY: return "Fleetway Amy";
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

// ===== [Suite TD2D v3.7] retratos con brillo (auto: no editar) =====
function scr_lobby_shiny_setup(char)
{
    var _c = char;
    if(_c == CHARACTER_SALLY_CANON) _c = CHARACTER_SALLY;
    if(_c == CHARACTER_VANILLA) _c = CHARACTER_CREAM;
    var _spr = -1;
    switch(_c)
    {
        case CHARACTER_AMY_CANON: _spr = spr_lobby_icon_sh_amycanon; break;
    }
    if(_spr < 0)
    {
        sprite_index = spr_lobby_icon;
        image_speed = 0;
        image_index = char + 1;
        if(char == CHARACTER_SALLY_CANON) image_index = CHARACTER_SALLY + 1;
        if(char == CHARACTER_VANILLA) image_index = CHARACTER_CREAM + 1;
        if(char == CHARACTER_METAL) image_index = 10;
        else if(char == CHARACTER_AMELIA) image_index = 11;
        else if(char == CHARACTER_BLAZE) image_index = 12;
    }
    else
    {
        sprite_index = _spr;
        image_speed = 1;
        if(image_index < 0 || image_index >= sprite_get_number(_spr)) image_index = 0;
    }
}

function scr_lobby_shiny_resolve(inst)
{
    with(inst)
    {
        if(obj_netclient.exeId == master_id) return;
        if(obj_lobby.state == 2 && obj_netclient.nid == master_id && !isSelected) return;
        var _ch = -1;
        if(master_id == obj_netclient.nid)
            _ch = global.character;
        else if(ds_map_exists(obj_netclient.players, master_id) && !obj_netclient.players[? master_id].pending)
            _ch = obj_netclient.players[? master_id].character;
        if(_ch < CHARACTER_TAILS || _ch == CHARACTER_EXE || _ch > CHARACTER_BLAZE) return;
        scr_lobby_shiny_setup(_ch);
    }
}

function scr_lobby_shiny_escape(char, xx, yy)
{
    var _c = char;
    if(_c == CHARACTER_SALLY_CANON) _c = CHARACTER_SALLY;
    if(_c == CHARACTER_VANILLA) _c = CHARACTER_CREAM;
    var _spr = -1;
    switch(_c)
    {
        case CHARACTER_AMY_CANON: _spr = spr_lobby_esc_sh_amycanon; break;
    }
    if(_spr < 0) return false;
    // [Suite TD2D v3.9.1] El brillo puede medir lo que sea (58x62, 24x24...):
    // su lienzo se CENTRA sobre el hueco del icono 26x26 de la barra
    // (origen abajo-izquierda => centro del hueco en xx+13, yy-13), igual
    // que los exeicon van centrados en su slot del lobby. Antes se dibujaba
    // en (xx, yy) a secas y cualquier brillo mas grande que 26x26 quedaba
    // desplazado (el de Amy Canon 58x62, unos 17px arriba a la derecha).
    var _w = sprite_get_width(_spr);
    var _h = sprite_get_height(_spr);
    var _ox = sprite_get_xoffset(_spr);
    var _oy = sprite_get_yoffset(_spr);
    draw_sprite(_spr, current_time / 150 % sprite_get_number(_spr),
        xx + 13 - _w / 2 + _ox,
        yy - 13 - _h / 2 + _oy);
    return true;
}
// ===== fin [Suite TD2D v3.7] retratos con brillo =====

// =====================================================================
//  v2.15 («La Torre») — REFLEJO DE UNA MISMA ALMA (pasiva compartida
//  de las tres Amys: Amy vanilla / Amy Canon / Amelia / Fleetway).
//  Dualidad de la Torre: Amelia representa la luz en la oscuridad,
//  Amy original la parte alegre y optimista, y la Amy de Fleetway la
//  fortaleza temperamental. Por cada Amy presente en el campo la
//  eficacia de los efectos de sus pasivas sube un 5% (tope 15%):
//   * FW Amy  -> bloqueo de LA TORRE (33% -> hasta 40%)
//   * Amy     -> hitbox de FUERZA (+20% -> hasta +23%)
//  Se evalua EN CADA CLIENTE con los datos que ya tiene (jugador local
//  + puppets sincronizados): el conteo coincide sin paquetes extra.
// =====================================================================
function scr_amy_soul_count()
{
    var _cnt = 0;

    // la Amy de ESTE cliente (si esta viva y jugando)
    if(instance_exists(global.player) && !global.player.isDead
    && (global.character == CHARACTER_AMY || global.character == CHARACTER_AMY_CANON
        || global.character == CHARACTER_AMELIA || global.character == CHARACTER_FLEETWAY_AMY))
        _cnt++;

    // las Amys remotas (puppets vivos y activos)
    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive)
                continue;

            if(inst.character == CHARACTER_AMY || inst.character == CHARACTER_AMY_CANON
            || inst.character == CHARACTER_AMELIA || inst.character == CHARACTER_FLEETWAY_AMY)
                _cnt++;
        }
    }

    return _cnt;
}

// Bonus de eficacia de Reflejo de una misma alma: +5% por Amy en el
// campo, tope +15% (3 o mas Amys). Ej.: bloqueo de La Torre =
// min(TOWER_BLOCK + scr_amy_soul_bonus(), TOWER_BLOCK_MAX).
function scr_amy_soul_bonus()
{
    return min(SOUL_STEP * scr_amy_soul_count(), SOUL_CAP);
}

// FUERZA (Amy vanilla): sus efectos SOLO se activan si alguna de las
// OTRAS Amys (Canon / Amelia / Fleetway) esta presente en el campo.
function scr_amy_soul_otras()
{
    if(global.character != CHARACTER_AMY
    && (global.character == CHARACTER_AMY_CANON || global.character == CHARACTER_AMELIA
        || global.character == CHARACTER_FLEETWAY_AMY)
    && instance_exists(global.player) && !global.player.isDead)
        return true;

    if(instance_exists(obj_player_puppet))
    {
        for(var i = 0; i < instance_number(obj_player_puppet); i++)
        {
            var inst = instance_find(obj_player_puppet, i);

            if(inst.isInactive)
                continue;

            if(inst.character == CHARACTER_AMY_CANON || inst.character == CHARACTER_AMELIA
            || inst.character == CHARACTER_FLEETWAY_AMY)
                return true;
        }
    }

    return false;
}

// =====================================================================
//  v2.15 («La Torre») — plataforma de la flecha clavada de Fleetway.
//  Idempotente por fwId: la crea si no existe o la REPOSICIONA con la
//  posicion autoritativa del server (estado 3). La llama el evento de
//  colision de obj_fw_bolt (reporte local inmediato) y net_state_game
//  (confirmacion del server).
// =====================================================================
function scr_fw_arrow_spawn(fwid, xx, yy, dir)
{
    // ¿ya existe la plataforma de esta flecha?
    var _found = noone;
    with(obj_fw_arrow)
    {
        if(fwId == fwid)
        {
            _found = id;
            break;
        }
    }

    if(_found != noone)
    {
        _found.x = xx;
        _found.y = yy;
        _found.image_xscale = sign(dir);
        return _found;
    }

    var _arrow = instance_create_depth(xx, yy, 0, obj_fw_arrow);
    _arrow.fwId = fwid;
    _arrow.image_xscale = sign(dir);
    return _arrow;
}

// =====================================================================
//  v2.15.2 — FIX «LA FLECHA NO SE CLAVA EN LA PARED» (Fart Zone y
//  demas mapas con pisos fuera de obj_solid_parent).
//  CAUSA RAIZ: el barrido de vuelo de obj_fw_bolt solo miraba
//  obj_solid_parent, pero NO TODA la geometria del juego cuelga de
//  ahi: Fart Zone (mapa 20) tiene 55 muros obj_fart_tile hijos de
//  obj_floor_parent (el padre del que SI cuelgan), igual que los
//  bloques de hielo de Nasty Paradise o las puertas de Haunting
//  Dream. En esos mapas la flecha atravesaba TODAS las paredes.
//  El jugador colisiona contra obj_floor_parent
//  (scr_collision_basic, collision_circle_list), asi que esa es la
//  jerarquia "solida" real — CON UNA EXCEPCION: la familia de las
//  plataformas saltables (obj_platform_jumptrough y sus pendientes),
//  que el propio jugador NO toca de lado (guarda
//  !position_meeting(..., obj_platform_jumptrough) de
//  scr_collision_check). La flecha hereda esa misma regla.
// =====================================================================

// ¿inst forma parte de la familia saltable de obj_platform_jumptrough?
// (obj_ghz_slope*, obj_ycr_slope*, obj_weed_slopus,
//  obj_marijuna_lavaplatform...: se recorren los padres del objeto)
function scr_fw_is_jumptrough(inst)
{
    var _obj = inst.object_index;

    // v4.9 — FIX CRASH (bosque majin): object_get_parent devuelve -100
    // cuando el objeto NO tiene padre. El bucle anterior solo cortaba con
    // -1, asi que al llegar a la raiz (obj_camerachecker) volvia a llamar
    // object_get_parent(-100) y GameMaker abortaba con "invalid reference
    // (object) -100". Pasaba en el bosque majin porque su terreno
    // (obj_majong_slope) NO pertenece a la familia saltable y el recorrido
    // llegaba hasta el fondo de la cadena. Cortar en -100/-1/no-existente.
    while(_obj != -100 && _obj != -1 && object_exists(_obj))
    {
        if(_obj == obj_platform_jumptrough)
            return true;

        _obj = object_get_parent(_obj);
    }

    return false;
}

// v4.9 — ¿el punto (xx, yy) cae dentro de un muro/piso REAL (toda la
// jerarquia obj_floor_parent MENOS la familia saltable, incluidas las
// flechas clavadas de Fleetway)? Version por PUNTO de scr_fw_wall_at:
// aquella usa el bbox del bolt; esta sirve para el jugador. La usa
// scr_amy_fleetway_special en el "modo pared" (detectar muro al alcance
// a la altura de los pies para el disparo de escalada del video).
function scr_fw_wall_point(xx, yy)
{
    var _list = ds_list_create();
    var _n = collision_point_list(xx, yy, obj_floor_parent, false, false, _list, false);

    var _wall = false;
    for(var i = 0; i < _n; i++)
    {
        if(!scr_fw_is_jumptrough(_list[| i]))
        {
            _wall = true;
            break;
        }
    }

    ds_list_destroy(_list);
    return _wall;
}

// ¿la flecha (self = obj_fw_bolt) colocada en (xx, yy) toca un muro /
// piso REAL? Corre en el contexto del bolt: usa SU mascara (bbox del
// spr_amy_projectile_fw). true = hay solido (clavarse); false = libre
// o solo plataformas saltables (atravesarlas, como el jugador).
function scr_fw_wall_at(xx, yy)
{
    // via rapida: si ni siquiera toca piso, nada que mirar
    if(!place_meeting(xx, yy, obj_floor_parent))
        return false;

    // toca ALGUN piso: place_meeting no permite excluir la familia
    // saltable (se queda con la primera instancia), asi que se miran
    // TODAS las que solapa el bbox del bolt a mano
    var _list = ds_list_create();
    var _n = collision_rectangle_list(xx + bbox_left, yy + bbox_top,
            xx + bbox_right, yy + bbox_bottom, obj_floor_parent,
            false, true, _list, false);

    var _wall = false;
    for(var i = 0; i < _n; i++)
    {
        if(!scr_fw_is_jumptrough(_list[| i]))
        {
            _wall = true;
            break;
        }
    }

    ds_list_destroy(_list);
    return _wall;
}
// ===== fin v2.15.2 «La Torre» — flecha que clava en toda pared =====
