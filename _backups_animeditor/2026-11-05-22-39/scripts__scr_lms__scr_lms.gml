// =====================================================================
//  v5.3 — LMS «EL SHOW FUERTE» POR PERSONAJE (lista editable).
//
//  Cuando queda UN unico superviviente vivo, el server mira si SU
//  personaje esta en la lista del show (LMS_SHOWS del server, que
//  espeja global.lmsCharSongs de aqui). Si esta, dispara
//  SERVER_GAME_LMS con el personaje (u8) y la cancion elegida al azar
//  de SU lista (u8): todos los clientes oyen esa cancion, ven el
//  banner y al personaje del show le sube la vida (LMS_HP). Si NO
//  esta en la lista, no pasa nada: la ronda sigue normal.
//
//  global.lmsCharSongs: ds_map id de personaje -> array de canciones.
//  El Suite TD2D (modulo Show LMS) edita esta lista: añade personajes
//  y sus mus_lms_N (.mp3/.ogg/.wav) con sus duraciones en el server.
//  La #1 de Sonic es mus_undefeatable (Undefeatable, la original).
//
//  EL SHOW GENERICO SOLO PONE: cancion + banner + vida al 100.
//  Las demas pasivas son PERSONALES DE SONIC (quedaron de su show
//  original v5.0 porque fueron personalizadas para el) y SOLO aplican
//  mientras el show es de Sonic:
//   - BLOQUEO 55%: cada golpe que le entra tiene 55% de probabilidad de
//     ser BLOQUEADO COMPLETO (scr_lms_sonic_try_block, llamado desde
//     scr_player_hurt). Bloqueado = ni vida ni anillos ni retroceso.
//   - INMUNIDAD A METAL AMY: la MARCA DE DEBILIDAD (sus recargas
//     forzadas de 6 s) no le aplica (gate en scr_weak_mark_hit).
//   - STUNS +2 s: TODO lo que Sonic aturde dura 2 s mas — el golpe X
//     (3 -> 5 s), la bola del spindash/dropdash (contacto, 3 -> 5 s) y
//     el parry (3,5 -> 5,5 s). Lo aplica el cliente de la victima.
//
//  Macros ajustables (mismo formato que el resto del repo).
// =====================================================================

#macro LMS_HP 100              // vida a la que sube el personaje del show al arrancarlo
#macro LMS_BLOCK_CHANCE 55     // (solo Sonic) % de bloquear TODO el daño de un golpe
#macro LMS_BLOCK_INVULN 90     // (solo Sonic) i-frames tras un bloqueo (60 = 1 s)
#macro LMS_STUN_BONUS 2        // (solo Sonic) segundos EXTRA en sus stuns durante el show
#macro LMS_SPIN_STUN true      // (solo Sonic) la bola (spindash/dropdash) aturde al bando EXE por contacto

// v5.3 — LISTA DEL SHOW POR PERSONAJE: id -> [canciones]. El server
// SOLO dispara el show para los personajes de esta lista. El Suite
// TD2D la reescribe entera al guardar (no editar a mano si se usa el
// Suite: se sobreescribiria).
global.lmsCharSongs = ds_map_create();
global.lmsCharSongs[? CHARACTER_AMY_CANON] = [mus_lms_2];
global.lmsCharSongs[? CHARACTER_SONIC] = [mus_undefeatable];

function scr_lms_play_song(ch, idx)
{
        // Toca la cancion idx de la lista del personaje ch. Server v5.0
        // sin payload => -1 => Sonic y su #1. Personaje sin lista no
        // deberia llegar nunca (el server ya lo filtra): no suena nada.
        if(ch < 0)
                ch = CHARACTER_SONIC;

        if(!ds_map_exists(global.lmsCharSongs, ch))
                return;

        var _list = global.lmsCharSongs[? ch];
        if(array_length(_list) == 0)
                return;

        if(idx < 0 || idx >= array_length(_list))
                idx = 0;

        scr_play_music(_list[idx]);
}

function scr_lms_sonic_try_block()
{
        // (PERSONAL DE SONIC) La tirada del show: 55% de BLOQUEAR TODO el
        // daño del golpe que acaba de entrar. Sale bloqueo -> escudo roto
        // (visible y sonoro para todos via net_*) + 1 s de invulnerabilidad,
        // para que el siguiente golpe sea otra tirada LIMPIA (sin esto, un
        // contacto continuado re-tiraria cada frame y el 55% no significaria
        // nada). Sale fallo -> el golpe entra COMPLETO por el camino normal
        // de scr_player_hurt (que es quien llama aqui).
        if(global.character != CHARACTER_SONIC || !global.lmsActive)
                return false;

        if(random(100) >= LMS_BLOCK_CHANCE)
                return false;

        global.player.hurttime = LMS_BLOCK_INVULN;

        audio_play_sound(snd_sally_shieldbreak, 0, false);
        net_sound_emit(snd_sally_shieldbreak);
        net_quick_effect(global.player.x, global.player.y - 20, spr_shieldbreak, false, 1, 0, 0, 1);

        return true;
}
