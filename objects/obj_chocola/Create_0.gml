// CHOCOLA (Vanilla v2): el chao de Vanilla. v84 (pedido de la duena):
// acompana a Vanilla DESDE EL PRINCIPIO de la ronda — nace en el Create
// de la Vanilla local y, en las demas pantallas, con el primer paquete
// de datos de su puppet (net_udpprocess) — y vive en cada maquina como
// simulacion local pegada al puppet de Vanilla (misma tecnica que las
// mascotas de la tienda). El cliente de VANILLA es la autoridad de las
// senales (stun al exe, tecla V) y el de CREAM arma la custodia cuando
// Chocola llega hasta ella. Si su Vanilla desaparece se autodestruye
// (Step) y el guard de net_udpprocess la re-crea si vuelven los datos.
mode = CHOCOLA_FOLLOW;
homeInst = noone;   // a quien sigue (puppet de Vanilla / la Vanilla local)
targetInst = noone; // a quien va (exe en caza, Cream en la ida)
huntSmall = false;  // true = mini-embestida (stun 2.5 s al exe / 3.5 s a un esbirro), no la caza grande
fromGuard = false;  // true = la embestida salio de la custodia de Cream
authority = false;  // true en el cliente que lanzo esta embestida
huntTimer = 0;      // failsafe de caza
atkTimer = 0;       // frames de la pose de golpe
supportTimer = 0;   // frames del giro de celebracion
guardTimer = 0;     // re-check del ataque en la custodia
targetLostTimer = 0; // v83: frames seguidos sin datos del objetivo (scr_chocola_target_lost)
image_speed = 0.3;
sprite_index = spr_vanilla_chocola_Idle;
