// CHOCOLA (Vanilla v2): el chao de Vanilla. Nace en TODOS los clientes
// con la senal de caza de la PACIENCIA (snd_mermer, ver scr_chocola) y
// desde ahi vive en cada maquina como simulacion local pegada al puppet
// de Vanilla (misma tecnica que las mascotas de la tienda). El cliente
// de VANILLA es la autoridad de las senales (stun al exe, tecla V) y el
// de CREAM arma la custodia cuando Chocola llega hasta ella.
mode = CHOCOLA_FOLLOW;
homeInst = noone;   // a quien sigue (puppet de Vanilla / la Vanilla local)
targetInst = noone; // a quien va (exe en caza, Cream en la ida)
huntSmall = false;  // true = mini-embestida (stun 1.5 s), no la caza grande
fromGuard = false;  // true = la embestida salio de la custodia de Cream
authority = false;  // true en el cliente que lanzo esta embestida
huntTimer = 0;      // failsafe de caza
atkTimer = 0;       // frames de la pose de golpe
supportTimer = 0;   // frames del giro de celebracion
guardTimer = 0;     // re-check del ataque en la custodia
image_speed = 0.3;
sprite_index = spr_vanilla_chocola_Idle;
