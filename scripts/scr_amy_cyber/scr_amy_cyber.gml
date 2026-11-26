// =====================================================================
//  AMY CYBER GHOST (v3) - shader holograma glitch estilo Frontiers.
//
//  scr_amy_cyber(char, palleteIn, palleteOut, spr, sub, lvl, dx, dy, xs, ys, rot, flash)
//  reemplaza a scr_palette_swap en el Draw (local y puppet): activa
//  shd_amy_cyber (palette swap + overlay cyber); si no aplica cae al
//  scr_palette_swap de siempre y no cambia nada. Es 100% visual: cada
//  cliente lo dibuja solo, sin red ni server.
//
//  v2: blindaje anti-crash. Si el script o el shader no estan
//  registrados en el .yyp (assets fantasma, como les pasaba a los
//  sonidos de Sally), NUNCA explota: siempre cae al palette swap
//  normal y el juego sigue dibujando.
//
//  v3 (v82, duena): el efecto tiene 3 NIVELES y ahora lo usan dos:
//   - AMY CANON: nivel 1 fijo, como siempre, pero con el shader
//     mejorado (contorno luminoso, glow exterior, lineas de datos,
//     rejilla holografica y los pies deshaciendose en pixeles).
//   - SALLY CANON: nivel = su FORMA CYBER (tecla V, scr_sally_cyber_*):
//     1 = SEMI CYBER, 2 = CYBER COMPLETA. En forma NORMAL no pasa
//     por aqui (usa el palette swap de siempre).
//  Todas las macros de look son tablas [apagado, nivel 1, nivel 2].
//
//  Como ajustarlo (macros de abajo, mismo formato que el resto del
//  repo):
//   - AMY_CYBER_ENABLED false  -> apaga el shader para TODOS (todo
//     vuelve a como estaba: palette swap normal). Sally Canon conserva
//     los numeros de sus formas, solo que se ve normal.
//   - AMY_CYBER_CHARS          -> a quien le aplica SIEMPRE. Por defecto solo
//     a Amy Canon. Puedes anadir a quien quieras, p.ej.
//     [CHARACTER_AMY_CANON, CHARACTER_AMY].
//   - AMY_CYBER_ALPHA          -> opacidad holograma. 0.85 = fantasma
//     como en el juego original; 1 = solida.
//   - AMY_CYBER_GLITCH         -> cuantos px se mueven las bandas.
//     0 = sin bandas (solo scanlines + split + chispas).
//   - AMY_CYBER_SCAN           -> fuerza de las scanlines.
//   - AMY_CYBER_SPLIT          -> px del split rojo/cian de bordes.
//   - AMY_CYBER_FLICKER        -> chispas, barrido y parpadeo.
//   - AMY_CYBER_TINT           -> lavado cian en las sombras.
//   - AMY_CYBER_GLOW           -> contorno luminoso del borde del cuerpo.
//   - AMY_CYBER_HALO           -> alfa del glow exterior (0 = sin glow).
//   - AMY_CYBER_HALO_SC        -> cuanto crece la silueta del glow.
//   - AMY_CYBER_DISSOLVE       -> los pies se deshacen en bloques de px.
//   - AMY_CYBER_GRID           -> rejilla holografica sobre el cuerpo.
//   - AMY_CYBER_STREAM         -> lineas de datos que suben por el cuerpo.
// =====================================================================

#macro AMY_CYBER_ENABLED true

// personajes con el efecto SIEMPRE activo (ids) y su nivel (1..2).
// Amy Canon por defecto, nivel 1.
#macro AMY_CYBER_CHARS         [CHARACTER_AMY_CANON]
#macro AMY_CYBER_CHAR_LEVELS   [1]

// LOOK POR NIVEL. Tablas de 3: [apagado, nivel 1 (suave), nivel 2 (intenso)].
// Nivel 1 = Amy Canon y Sally Canon SEMI CYBER. Nivel 2 = Sally Canon CYBER
// COMPLETA. Se leen con scr_amy_cyber_lk(tabla, nivel): una macro-array no
// se puede indexar directo (patron del repo: copiar a una var primero).
#macro AMY_CYBER_SCAN      [0.00, 0.16, 0.20]   // scanlines: cada 2 px se oscurece
#macro AMY_CYBER_SPLIT     [0.0, 1.0, 1.5]      // split RGB en px
#macro AMY_CYBER_GLITCH    [0, 5, 8]            // px maximos de las bandas glitch
#macro AMY_CYBER_FLICKER   [0.00, 0.30, 0.40]   // chispas + barrido + parpadeo
#macro AMY_CYBER_ALPHA     [1.00, 0.85, 0.85]   // opacidad holograma (1 = solida)
#macro AMY_CYBER_TINT      [0.00, 0.15, 0.40]   // lavado cian en sombras
#macro AMY_CYBER_GLOW      [0.0, 0.55, 0.90]    // contorno luminoso del borde del cuerpo
#macro AMY_CYBER_HALO      [0.0, 0.55, 0.75]    // alfa del glow exterior (0 = sin glow)
#macro AMY_CYBER_HALO_SC   [0.0, 0.07, 0.10]    // cuanto crece la silueta del glow
#macro AMY_CYBER_DISSOLVE  [0.00, 0.12, 0.40]   // los pies se deshacen en bloques de 2x2 px
#macro AMY_CYBER_GRID      [0.00, 0.10, 0.22]   // rejilla holografica sobre el cuerpo
#macro AMY_CYBER_STREAM    [0.00, 0.35, 0.70]   // lineas de datos que suben por el cuerpo
#macro AMY_CYBER_HALO_RGB  [0.35, 0.90, 1.00]   // color del glow exterior

// dice si un personaje lleva el efecto siempre activo
function scr_amy_cyber_is(ch)
{
        var _list = AMY_CYBER_CHARS;

        for(var i = 0; i < array_length(_list); i++)
                if(_list[i] == ch)
                        return true;

        return false;
}

// nivel de efecto (0..2) de un personaje con el efecto SIEMPRE activo.
// 0 = no lleva el efecto (o el sistema esta apagado).
function scr_amy_cyber_level(ch)
{
        if(!AMY_CYBER_ENABLED)
                return 0;

        var _chars = AMY_CYBER_CHARS;
        var _lvls  = AMY_CYBER_CHAR_LEVELS;

        for(var i = 0; i < array_length(_chars); i++)
        {
                if(_chars[i] == ch)
                        return (i < array_length(_lvls)) ? _lvls[i] : 1;
        }

        return 0;
}

// valor de una tabla por nivel (0..2). Fuera de rango se queda en el extremo.
function scr_amy_cyber_lk(arr, lvl)
{
        var _list = arr;

        if(lvl < 0)
                lvl = 0;

        if(lvl >= array_length(_list))
                lvl = array_length(_list) - 1;

        return _list[lvl];
}

// cache de los uniforms (se piden una sola vez). Un uniform que el
// compilador de GLSL haya eliminado sale como -1: se guarda igual y
// cada setter comprueba el handle antes de usarlo.
function scr_amy_cyber_u(shd)
{
        if(!variable_global_exists("amyCyberU"))
        {
                global.amyCyberU =
                {
                        pattern:      shader_get_uniform(shd, "u_Pattern"),
                        replacements: shader_get_uniform(shd, "u_Replacements"),
                        count:        shader_get_uniform(shd, "u_ColourCount"),
                        texel:        shader_get_uniform(shd, "uTexel"),
                        time:         shader_get_uniform(shd, "uTime"),
                        scan:         shader_get_uniform(shd, "uScan"),
                        split:        shader_get_uniform(shd, "uSplit"),
                        glitch:       shader_get_uniform(shd, "uGlitch"),
                        flicker:      shader_get_uniform(shd, "uFlicker"),
                        alpha:        shader_get_uniform(shd, "uAlpha"),
                        tint:         shader_get_uniform(shd, "uTint"),
                        solid:        shader_get_uniform(shd, "uSolid"),
                        halo:         shader_get_uniform(shd, "uHaloCol"),
                        glow:         shader_get_uniform(shd, "uGlow"),
                        dissolve:     shader_get_uniform(shd, "uDissolve"),
                        grid:         shader_get_uniform(shd, "uGrid"),
                        stream:       shader_get_uniform(shd, "uStream"),
                        body:         shader_get_uniform(shd, "uBody"),
                        rect:         shader_get_uniform(shd, "uRect"),
                        rectok:       shader_get_uniform(shd, "uRectOK"),
                        pivot:        shader_get_uniform(shd, "uPivot"),
                        rot:          shader_get_uniform(shd, "uRot")
                };
        }

        return global.amyCyberU;
}

// caja del sprite sin rotar, relativa al punto de dibujo (pivote).
// Los efectos "de dentro del sprite" (disolucion de los pies, rejilla,
// lineas de datos) la necesitan para saber en que pixel del sprite esta
// cada fragmento aunque este volteado, girado o escalado.
// Devuelve [x, y, ancho, alto, bbox_top, bbox_bottom, ancho_px, alto_px]:
// la caja ya multiplicada por la escala y, aparte, el tamano en px.
function scr_amy_cyber_rect(spr, xs, ys)
{
        var _sw   = 1;
        var _sh   = 1;
        var _xoff = 0;
        var _yoff = 0;
        var _top  = 0;
        var _bot  = 1;

        if(sprite_exists(spr))
        {
                _sw   = sprite_get_width(spr);
                _sh   = sprite_get_height(spr);
                _xoff = sprite_get_xoffset(spr);
                _yoff = sprite_get_yoffset(spr);
                _top  = sprite_get_bbox_top(spr);
                _bot  = sprite_get_bbox_bottom(spr);
        }

        // sanity: sprites de 0 px o bbox sin area
        if(_sw < 1 || _sh < 1 || _bot <= _top)
        {
                _sw  = max(_sw, 1);
                _sh  = max(_sh, 1);
                _top = 0;
                _bot = _sh;
        }

        return [-_xoff * xs, -_yoff * ys, _sw * xs, _sh * ys, _top, _bot, _sw, _sh];
}

// reemplaza a scr_palette_swap en el Draw: activa el shader cyber con
// la paleta que le pases (igual que scr_palette_swap) + el overlay.
//
// lvl  = -1 -> automatico (AMY_CYBER_CHARS); 0 -> palette swap normal;
//         1 = suave, 2 = intenso.
// dx/dy/xs/ys/rot = los MISMOS valores con los que se dibuja el sprite
//   justo despues (draw_sprite_ext). rot en grados. Sin ellos (los
//   defaults) los efectos de dentro del sprite se apagan solos.
// flash = 0..1: subida extra de glitch + parpadeo (cambio de forma).
function scr_amy_cyber(char, palleteIn, palleteOut, spr, sub, lvl = -1, dx = 0, dy = 0, xs = 1, ys = 1, rot = 0, flash = 0)
{
        if(lvl < 0)
                lvl = scr_amy_cyber_level(char);

        lvl = clamp(floor(lvl), 0, 2);

        if(!AMY_CYBER_ENABLED || lvl <= 0)
        {
                scr_palette_swap(palleteIn, palleteOut);
                return;
        }

        // v2: blindaje. El shader se busca POR NOMBRE (asset_get_index):
        // si shd_amy_cyber no esta registrado en el .yyp (asset fantasma),
        // cae al palette swap de siempre en vez de crashear. Los asset
        // por nombre no son variables: no se pueden leer con el identificador
        // directo si no existen, pero SI se pueden buscar sin tocarlos.
        var _shd = asset_get_index("shd_amy_cyber");

        if(_shd < 0)
        {
                scr_palette_swap(palleteIn, palleteOut);
                return;
        }

        var _u = scr_amy_cyber_u(_shd);

        shader_set(_shd);

        // paleta: identico a scr_palette_swap, pero a prueba de arrays
        // vacios o desiguales: no se sube nada y el swap no actua (el
        // holograma sale con los colores del sprite).
        var _cnt = floor(min(array_length(palleteIn), array_length(palleteOut)) / 4);

        if(_cnt > 0 && _u.pattern >= 0 && _u.replacements >= 0)
        {
                shader_set_uniform_f_array(_u.pattern, palleteIn);
                shader_set_uniform_f_array(_u.replacements, palleteOut);
        }
        else
                _cnt = 0;   // sin paleta o sin uniforms: el swap no actua

        if(_u.count >= 0)
                shader_set_uniform_i(_u.count, _cnt);

        // texel REAL de la textura (para convertir px -> uv): el
        // sprite vive en una texture page grande, el paso de 1 px es
        // 1/tamano de pagina, no 1/tamano del sprite.
        var _tw = 1.0 / 64.0;
        var _th = 1.0 / 64.0;

        if(sprite_exists(spr))
        {
                var _tex = sprite_get_texture(spr, max(0, floor(sub)));

                if(_tex >= 0)
                {
                        _tw = texture_get_texel_width(_tex);
                        _th = texture_get_texel_height(_tex);
                }
        }

        var _fl    = clamp(flash, 0, 1);
        var _glit  = scr_amy_cyber_lk(AMY_CYBER_GLITCH, lvl) * (1 + 1.5 * _fl);
        var _flick = min(1, scr_amy_cyber_lk(AMY_CYBER_FLICKER, lvl) + 0.5 * _fl);
        var _rc    = scr_amy_cyber_rect(spr, xs, ys);
        var _rcOk  = (xs != 0 && ys != 0) ? 1 : 0;

        if(_u.texel >= 0)
                shader_set_uniform_f(_u.texel, _tw, _th);

        if(_u.time >= 0)
                shader_set_uniform_f(_u.time, current_time / 1000);

        if(_u.scan >= 0)
                shader_set_uniform_f(_u.scan, scr_amy_cyber_lk(AMY_CYBER_SCAN, lvl));

        if(_u.split >= 0)
                shader_set_uniform_f(_u.split, scr_amy_cyber_lk(AMY_CYBER_SPLIT, lvl));

        if(_u.glitch >= 0)
                shader_set_uniform_f(_u.glitch, _glit);

        if(_u.flicker >= 0)
                shader_set_uniform_f(_u.flicker, _flick);

        if(_u.alpha >= 0)
                shader_set_uniform_f(_u.alpha, scr_amy_cyber_lk(AMY_CYBER_ALPHA, lvl));

        if(_u.tint >= 0)
                shader_set_uniform_f(_u.tint, scr_amy_cyber_lk(AMY_CYBER_TINT, lvl));

        if(_u.solid >= 0)
                shader_set_uniform_f(_u.solid, 0);

        if(_u.glow >= 0)
                shader_set_uniform_f(_u.glow, scr_amy_cyber_lk(AMY_CYBER_GLOW, lvl));

        if(_u.dissolve >= 0)
                shader_set_uniform_f(_u.dissolve, scr_amy_cyber_lk(AMY_CYBER_DISSOLVE, lvl));

        if(_u.grid >= 0)
                shader_set_uniform_f(_u.grid, scr_amy_cyber_lk(AMY_CYBER_GRID, lvl));

        if(_u.stream >= 0)
                shader_set_uniform_f(_u.stream, scr_amy_cyber_lk(AMY_CYBER_STREAM, lvl));

        if(_u.body >= 0)
                shader_set_uniform_f(_u.body, _rc[6], _rc[7], _rc[4], _rc[5]);

        if(_u.rect >= 0)
                shader_set_uniform_f(_u.rect, _rc[0], _rc[1], _rc[2], _rc[3]);

        if(_u.rectok >= 0)
                shader_set_uniform_f(_u.rectok, _rcOk);

        if(_u.pivot >= 0)
                shader_set_uniform_f(_u.pivot, dx, dy);

        if(_u.rot >= 0)
                shader_set_uniform_f(_u.rot, dcos(rot), dsin(rot));
}

// GLOW EXTERIOR (v82): silueta del personaje en cian, un poco mas
// grande, dibujada DETRAS del cuerpo. Se llama ANTES de scr_amy_cyber +
// draw_sprite_ext y con los MISMOS argumentos de dibujo; cierra el
// shader el sola. Devuelve true si dibujo algo.
// Mismo lvl que scr_amy_cyber (-1 = automatico, 0..2).
function scr_amy_cyber_halo(char, spr, sub, lvl = -1, dx = 0, dy = 0, xs = 1, ys = 1, rot = 0, alpha = 1)
{
        if(!AMY_CYBER_ENABLED)
                return false;

        if(lvl < 0)
                lvl = scr_amy_cyber_level(char);

        lvl = clamp(floor(lvl), 0, 2);

        var _ha = scr_amy_cyber_lk(AMY_CYBER_HALO, lvl);

        if(lvl <= 0 || _ha <= 0 || !sprite_exists(spr))
                return false;

        var _shd = asset_get_index("shd_amy_cyber");

        if(_shd < 0)
                return false;

        var _u    = scr_amy_cyber_u(_shd);
        var _sc   = 1 + scr_amy_cyber_lk(AMY_CYBER_HALO_SC, lvl);
        var _col  = AMY_CYBER_HALO_RGB;

        // en modo silueta el shader solo lee uSolid, uHaloCol y uAlpha
        shader_set(_shd);

        if(_u.solid >= 0)
                shader_set_uniform_f(_u.solid, 1);

        if(_u.rectok >= 0)
                shader_set_uniform_f(_u.rectok, 0);   // silueta: sin efectos de dentro del sprite

        if(_u.halo >= 0)
                shader_set_uniform_f(_u.halo, _col[0], _col[1], _col[2]);

        if(_u.alpha >= 0)
                shader_set_uniform_f(_u.alpha, _ha * clamp(alpha, 0, 1));

        draw_sprite_ext(spr, max(0, floor(sub)), dx, dy, xs * _sc, ys * _sc, rot, c_white, 1);
        shader_reset();

        return true;
}

// =====================================================================
//  SALLY CANON - FORMAS CYBER (v82, duena)
//
//  Sally Canon tiene 3 formas y se cambian con la tecla V
//  (global.KeyV, "special3" en la configuracion, reconfigurable).
//  Cada una es mas fuerte que la anterior:
//
//    NORMAL          todo como siempre.
//    SEMI CYBER      resiste el 35% del dano, escudo 45% de efectividad,
//                    hitbox de la patada x1.45.
//    CYBER COMPLETA  60% de reduccion de dano, escudo 70% de efectividad,
//                    hitbox de la patada x1.70.
//
//  CONDICION: solo puede cambiar de forma si en la partida hay una
//  AMY CANON viva y que no sea esbirro (puede ser la jugadora que la
//  lleva o su puppet). Si la Amy Canon muere o se vuelve esbirro, la
//  Sally Canon vuelve a NORMAL sola (SALLY_CYBER_AUTO_DROP). La esbirro
//  Sally Canon (2+ caidas) no usa las formas: es del bando del EXE.
//
//  Donde actua cada cosa:
//   - tecla V, ciclo y auto-drop ..... scr_sally_special (antes del escudo)
//   - resistencia al dano ............ scr_player_hurt (cliente de la victima)
//   - escudo (aguantar / duracion) ... scr_player_hurt + scr_sally_special
//   - hitbox de la patada ............ obj_player_puppet/Step_0 (pad del kick)
//   - sincronizacion ................. 3 bytes al final de CLIENT_PLAYER_DATA
//   - dibujo ......................... scr_amy_cyber nivel 1/2 (local + puppet)
//   - HUD ........................... obj_playerui/Draw_64 (icono V) y
//                                     obj_sally_canon/Draw_64 (nombre)
// =====================================================================

#macro SALLY_CYBER_ENABLED          true
#macro SALLY_CYBER_FORM_NORMAL      0
#macro SALLY_CYBER_FORM_SEMI        1
#macro SALLY_CYBER_FORM_FULL        2
#macro SALLY_CYBER_NEED_AMY_CANON   true     // false = se puede cambiar sin Amy Canon
#macro SALLY_CYBER_AUTO_DROP        true     // sin Amy Canon viva vuelve a NORMAL sola

// SEMI CYBER
#macro SALLY_CYBER_SEMI_RESIST          0.35     // resistencia al dano (35%)
#macro SALLY_CYBER_SEMI_SHIELD_EFF      0.45     // efectividad de escudo (45%)
#macro SALLY_CYBER_SEMI_HITBOX_MUL      1.45     // alcance de la patada (x1.45)

// CYBER COMPLETA
#macro SALLY_CYBER_FULL_RESIST          0.60     // reduccion de dano (60%)
#macro SALLY_CYBER_FULL_SHIELD_EFF      0.70     // efectividad de escudo (70%)
#macro SALLY_CYBER_FULL_HITBOX_MUL      1.70     // alcance de la patada (x1.70)

// QUE SIGNIFICA "EFECTIVIDAD DE ESCUDO" (los % de arriba):
//   0 = PROBABILIDAD DE AGUANTAR: al recibir un golpe con el escudo
//       puesto, en vez de romperse tiene un 45% / 70% de aguantarlo.
//   1 = DURACION: el escudo dura un 45% / 70% mas de tiempo.
//   2 = LOS DOS.
#macro SALLY_CYBER_SHIELD_MODE          0
#macro SALLY_CYBER_SHIELD_HOLD_INVULN   (60 * 0.8)   // i-frames al aguantar un golpe
#macro SALLY_CYBER_SHIELD_HOLD_MIN_TIME (60 * 0.5)   // tiempo minimo que le queda al escudo
#macro SALLY_CYBER_FLASH_TIME           (60 * 0.6)   // destello al cambiar de forma
#macro SALLY_CYBER_SWITCH_SND           snd_buble    // sonido al cambiar de forma

// etiqueta del protocolo: 3 bytes al final del CLIENT_PLAYER_DATA de
// Sally Canon = [TAG_A, TAG_B, forma]. Dos bytes de etiqueta para que un
// cliente viejo (que no los manda) nunca se lea como una forma por
// accidente: el buffer de recepcion es FIJO y relee bytes viejos.
#macro SALLY_CYBER_NET_TAG_A            201
#macro SALLY_CYBER_NET_TAG_B            171

// forma cyber VALIDA de la jugadora local (0/1/2). 0 si no es Sally
// Canon, si el sistema esta apagado o si es esbirro (revivalTimes >= 2).
function scr_sally_cyber_form()
{
        if(!SALLY_CYBER_ENABLED || global.character != CHARACTER_SALLY_CANON)
                return SALLY_CYBER_FORM_NORMAL;

        if(!instance_exists(global.player))
                return SALLY_CYBER_FORM_NORMAL;

        if(global.player.revivalTimes >= 2 || !variable_instance_exists(global.player.id, "cyberForm"))
                return SALLY_CYBER_FORM_NORMAL;

        return clamp(floor(global.player.cyberForm), 0, 2);
}

// multiplicador de dano RECIBIDO (1 = sin resistencia)
function scr_sally_cyber_resist_mul(form)
{
        if(form >= SALLY_CYBER_FORM_FULL)
                return 1.0 - SALLY_CYBER_FULL_RESIST;

        if(form >= SALLY_CYBER_FORM_SEMI)
                return 1.0 - SALLY_CYBER_SEMI_RESIST;

        return 1.0;
}

// efectividad de escudo de la forma (0..1)
function scr_sally_cyber_shield_eff(form)
{
        if(form >= SALLY_CYBER_FORM_FULL)
                return SALLY_CYBER_FULL_SHIELD_EFF;

        if(form >= SALLY_CYBER_FORM_SEMI)
                return SALLY_CYBER_SEMI_SHIELD_EFF;

        return 0.0;
}

// multiplicador del alcance (pad) de la patada de Sally Canon.
// demonized = true (esbirro) -> 1: su patada no se amplia nunca.
function scr_sally_cyber_hitbox_mul(form, demonized = false)
{
        if(demonized)
                return 1.0;

        if(form >= SALLY_CYBER_FORM_FULL)
                return SALLY_CYBER_FULL_HITBOX_MUL;

        if(form >= SALLY_CYBER_FORM_SEMI)
                return SALLY_CYBER_SEMI_HITBOX_MUL;

        return 1.0;
}

// duracion del escudo al ACTIVARLO (1 = la de siempre)
function scr_sally_cyber_shield_duration_mul(form)
{
        if(SALLY_CYBER_SHIELD_MODE != 1 && SALLY_CYBER_SHIELD_MODE != 2)
                return 1.0;

        return 1.0 + scr_sally_cyber_shield_eff(form);
}

// true si el escudo AGUANTA este golpe en vez de romperse (tirada de
// dados con la efectividad de la forma). Con forma 0 no consume azar.
function scr_sally_cyber_shield_hold(form)
{
        if(SALLY_CYBER_SHIELD_MODE != 0 && SALLY_CYBER_SHIELD_MODE != 2)
                return false;

        var _eff = scr_sally_cyber_shield_eff(form);

        if(_eff <= 0)
                return false;

        return irandom(99) < round(100 * _eff);
}

// hay una AMY CANON viva (y que no sea esbirro) en la partida?
// Mismo patron que scr_amy_soul_otras: la jugadora local o el bucle de
// puppets (saltando los inactivos). El isDead de un puppet no viaja:
// vivo = hp > 0 y revivalTimes < 2.
function scr_sally_cyber_amy_present()
{
        if(instance_exists(global.player) && !global.player.isDead
        && global.player.revivalTimes < 2 && global.character == CHARACTER_AMY_CANON)
                return true;

        if(instance_exists(obj_player_puppet))
        {
                for(var i = 0; i < instance_number(obj_player_puppet); i++)
                {
                        var inst = instance_find(obj_player_puppet, i);

                        if(inst.isInactive)
                                continue;

                        if(inst.character == CHARACTER_AMY_CANON && inst.revivalTimes < 2 && inst.hp > 0)
                                return true;
                }
        }

        return false;
}
