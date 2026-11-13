// =====================================================================
//  v6 (D.I.B.) — SPRITE DE CAPTURA DE RELEVO.
//  Devuelve el sprite con el que se dibuja a un superviviente cuando
//  cae ATRAPADO en el portal trampa de Jinna (SERVER_JINNA_TRAP_HIT
//  kind 5: captura generica). Los que tienen regla canon viajan con
//  SU sprite propio (Vanilla: spr_vanilla_absorb_trap, Amy Canon:
//  spr_amy_capture_canon, Sally Canon: spr_sally_capture_canon, Rouge:
//  spr_rouge_traped) — este script es para EL RESTO del reparto,
//  mientras llega el arte de captura personalizado de cada uno: usan
//  su sprite de DOLOR (spr_(personaje)_hurt) como relevo, tal cual
//  pidio la duena ("por mientras hago las personalizadas").
//
//  El mismo mapeo sirve para las DOS puntas:
//   * el cliente de la VICTIMA: obj_jinna_absorb (la animacion de
//     succion que corre en su propia maquina),
//   * el cliente de la JINNA: el fantasma semitransparente que flota
//     sobre su cabeza (obj_jinna/Draw_0, jinnaCaughtSprite).
//  Recibe el CHARACTER_* (el de la victima o el character de su
//  puppet, que viaja en el UDP) y devuelve el sprite de relevo.
//  Actualizalo cuando agregues el arte final de cada captura: solo
//  cambia el return de ese case.
// =====================================================================
function scr_jinna_capture_sprite(_char)
{
        switch(_char)
        {
                case CHARACTER_TAILS:
                        return spr_tails_hurt;

                case CHARACTER_KNUX:
                        return spr_knux_hurt;

                case CHARACTER_EGGMAN:
                        return spr_egg_hurt;

                case CHARACTER_AMY:
                        return spr_amy_hurt;

                case CHARACTER_CREAM:
                        return spr_cream_hurt;

                case CHARACTER_SALLY:
                        return spr_sally_hurt;

                // canon con regla directa (kinds 1-4): nunca llegan aqui,
                // pero por defensivo devuelven su sprite de captura real
                case CHARACTER_AMY_CANON:
                        return spr_amy_capture_canon;

                case CHARACTER_SONIC:
                        return spr_sonic_hurt;

                case CHARACTER_SALLY_CANON:
                        return spr_sally_capture_canon;

                case CHARACTER_VANILLA:
                        return spr_vanilla_absorb_trap;

                case CHARACTER_METAL:
                        return spr_metal_hurt;

                case CHARACTER_AMELIA:
                        return spr_amelia_hurt;

                case CHARACTER_BLAZE:
                        return spr_blaze_hurt;

                case CHARACTER_FLEETWAY_AMY:
                        return spr_amy_hurt_fw;

                case CHARACTER_ROUGE:
                        return spr_rouge_traped;

                default:
                        return spr_sonic_hurt; // fallback defensivo
        }
}
