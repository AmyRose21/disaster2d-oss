// =====================================================================
//  v2.15 («La Torre») — FLEETWAY AMY: la flecha toco un solido. Ya NO
//  se rompe: se CLAVA y se convierte en plataforma (obj_fw_arrow,
//  hijo de obj_solid_parent) durante FW_ARROW_STICK_TIME (5 s). El
//  reporte al server (tipo 1) hace que el resto de clientes la claven
//  en la misma posicion (estado 3, fiable) y que el server deje de
//  moverla. Un jugador parado ENCIMA no la rompe: la plataforma cae
//  sola al expirar (server estado 2 / timer local de obj_fw_arrow).
//  Las flechas en vuelo SI chocan contra las clavadas (heredan de
//  obj_solid_parent): se pueden apilar en torre, como en la wiki.
// =====================================================================
if(isBreaking || isStuck)
        exit;

isStuck = true;

// plataforma local inmediata (el estado 3 del server llega 1 RTT
// despues y solo re-posiciona: scr_fw_arrow_spawn es idempotente)
scr_fw_arrow_spawn(fwId, x, y, image_xscale);

// reporte al server: tipo 1 = clavarse en (x, y)
net_fw_bolt_hit(fwId, 1, x, y);

// este objeto ya cumplio: la flecha visible es la plataforma
instance_destroy();
