// =====================================================================
//  v2.14 — FLEETWAY AMY: flecha de la ballesta (cliente). Vuelo RECTO
//  integrado por el server (SERVER_FWBOLT_STATE 1: pos). Este objeto
//  solo decide los contactos del lado de ESTE cliente (cada cliente
//  es autoridad de su propio jugador, como el laser de Tails):
//   * si el local es el killer / esbirro y lo toca:
//       - dmg 0 (Fleetway superviviente): stun al EXE
//       - dmg 20 (demonizada, revival >= 2): daño real
//   * contra el mapa (obj_solid_parent): se CLAVA (v2.15) y se
//     convierte en plataforma (obj_fw_arrow) durante 5 s.
//
//  v4.9: la plataforma clavada es ATRAVESABLE (hija de
//  obj_platform_jumptrough, ver obj_fw_arrow): los jugadores la cruzan
//  desde abajo y aterrizan encima, y las flechas en vuelo la ignoran
//  (scr_fw_wall_at excluye la familia saltable) — ya no se apilan en
//  torre, se clavan en el muro de detras, como en el original.
//
//  v2.15 («La Torre»):
//   - fwId: id de la entidad del server (todos los paquetes lo llevan;
//     hasta 3 flechas simultaneas).
//   - El stun de flecha al EXE dura 3 s y cada stun CONTINUO lo reduce
//     un 17,5% (tope 50%); tras 7 s sin stuns de flecha se resetea
//     (global.fwArrowStunStack/Decay, lo descuenta obj_level). Contra
//     ESBIRROS (demonizados) dura siempre los 3 s completos. No
//     funciona contra supervivientes: si Fleetway es exe (revival >= 2)
//     la flecha hace daño 20, no stunea.
//   - Al tocar un solido NO se rompe: se clava (net_fw_bolt_hit tipo 1)
//     y queda como plataforma (obj_fw_arrow, hijo de obj_solid_parent).
// =====================================================================
isOwner = false;
isBreaking = false;
isStuck = false;
fwId = -1;
dmg = 0;
image_speed = 1;

_destroy = function()
{
        if(isBreaking)
                return;

        isBreaking = true;
        image_speed = 1;
        net_fw_bolt_hit(fwId, 0, 0, 0);
}
