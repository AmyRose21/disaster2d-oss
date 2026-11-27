// ============================================================================
// scr_player_maxhp(char, inst = noone) — v13 (REWORK ROUGE): vida MAXIMA por
// personaje. Fuente unica de verdad para TODO el HUD y el netcode de vida:
//   * ROUGE  = 125 (pedido: "ella poseera un total de 125 de vida")
//   * METAL = 150 (pedido: "metal sonic tendra un total de 150 de vida
//     pero solo tendra 1 sola vida" — ver el guard de Game.c)
//   * KRIS (v95) = 100 + 20 por nivel de LOVE (LV 1 = 100, LV 20 = 480).
//     Pedido de la duena: "cada que suba de nivel su vida max aumente 20
//     de vida max". El LV lo saca de krisLv (el Kris LOCAL, cuando se
//     pregunta por global.character) o de krisLvNet (el puppet de Kris
//     en las pantallas ajenas, espejado por la senal silenciosa v46) —
//     para eso sirve el parametro opcional inst: el llamador que tiene
//     el PUPPET se lo pasa y su barra escala con el LV espejado. Sin
//     inst (todas las llamadas del jugador local) vale krisLv.
//   * los demas supervivientes = 100 (valor canonico de siempre)
// Uso: tira de retratos del HUD (frame por vida), hudAllyBar (relleno),
// gateo de curas y el clamp del hp que viaja por CLIENT_PLAYER_DATA
// (obj_netclient Step_2, s16 desde v13).
// ============================================================================
function scr_player_maxhp(char, inst = noone)
{
        switch(char)
        {
                case CHARACTER_ROUGE: return 125;
                case CHARACTER_METAL: return 150;
                case CHARACTER_KRIS:
                {
                        // v95: la vida total de Kris crece con su LOVE.
                        var _lv = 1;

                        // el puppet de Kris en una pantalla ajena: su LV
                        // espejado (krisLvNet, senal silenciosa v46).
                        if(instance_exists(inst) && variable_instance_exists(inst.id, "krisLvNet"))
                                _lv = inst.krisLvNet;
                        else if(instance_exists(global.player) && variable_instance_exists(global.player.id, "krisLv"))
                                _lv = global.player.krisLv;

                        return KRIS_LV_BASE_HP + KRIS_LV_HP_BONUS * (_lv - 1);
                }
        }
        return 100;
}
