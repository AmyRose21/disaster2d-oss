// =====================================================================
//  v5.0 — LMS «EL SHOW FUERTE» (Last Man Standing de SONIC).
//
//  Cuando Sonic queda como ULTIMO superviviente de la partida, el server
//  dispara SERVER_GAME_LMS: el reloj sube a la duracion de la cancion
//  (Undefeatable), todos los clientes la escuchan y las pasivas del show
//  se activan (global.lmsActive). Este script centraliza las macros y el
//  bloqueo de daño para no regar la logica por el proyecto.
//
//  PASIVAS DEL SHOW (todas SOLO mientras global.lmsActive):
//   - CURA TOTAL: al arrancar el show Sonic sube a 100 de vida (lo aplica
//     el handler del paquete en net_state_game).
//   - BLOQUEO 55%: cada golpe que le entra tiene 55% de probabilidad de
//     ser BLOQUEADO COMPLETO (scr_lms_sonic_try_block, llamado desde
//     scr_player_hurt). Bloqueado = ni vida ni anillos ni retroceso.
//   - INMUNIDAD A METAL AMY: la MARCA DE DEBILIDAD (sus recargas forzadas
//     de 6 s) no le aplica (gate en scr_weak_mark_hit).
//   - STUNS +2 s: TODO lo que Sonic aturde dura 2 s mas — el golpe X
//     (3 -> 5 s), la bola del spindash/dropdash (contacto, 3 -> 5 s) y el
//     parry (3,5 -> 5,5 s). Lo aplica el cliente de la victima.
//
//  Macros ajustables (mismo formato que el resto del repo).
// =====================================================================

#macro LMS_BLOCK_CHANCE 55     // % de probabilidad de bloquear TODO el daño de un golpe
#macro LMS_BLOCK_INVULN 60     // i-frames tras un bloqueo (60 = 1 s, como el escudo roto de Sally)
#macro LMS_STUN_BONUS 2        // segundos EXTRA en todos los stuns que Sonic causa durante el show
#macro LMS_SPIN_STUN true      // la bola (spindash/dropdash rodando) aturde al bando EXE por contacto

function scr_lms_sonic_try_block()
{
        // La tirada del show: 55% de BLOQUEAR TODO el daño del golpe que
        // acaba de entrar. Sale bloqueo -> escudo roto (visible y sonoro
        // para todos via net_*) + 1 s de invulnerabilidad, para que el
        // siguiente golpe sea otra tirada LIMPIA (sin esto, un contacto
        // continuado re-tiraria cada frame y el 55% no significaria nada).
        // Sale fallo -> el golpe entra COMPLETO por el camino normal de
        // scr_player_hurt (que es quien llama aqui).
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
