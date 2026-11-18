// ============================================================================
// scr_player_maxhp(char) — v13 (REWORK ROUGE): vida MAXIMA por personaje.
// Fuente unica de verdad para TODO el HUD y el netcode de vida:
//   * ROUGE  = 125 (pedido: "ella poseera un total de 125 de vida")
//   * METAL = 150 (pedido: "metal sonic tendra un total de 150 de vida
//     pero solo tendra 1 sola vida" — ver el guard de Game.c)
//   * los demas supervivientes = 100 (valor canonico de siempre)
// Uso: tira de retratos del HUD (frame por vida), hudAllyBar (relleno),
// gateo de curas y el clamp del hp que viaja por CLIENT_PLAYER_DATA
// (obj_netclient Step_2, s16 desde v13).
// ============================================================================
function scr_player_maxhp(char)
{
        switch(char)
        {
                case CHARACTER_ROUGE: return 125;
                case CHARACTER_METAL: return 150;
        }
        return 100;
}
