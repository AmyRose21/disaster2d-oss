/* AUTO-GENERADO por derive_spawns_all_v68.py — NO EDITAR A MANO.
   Zonas seguras de ITEM BOX por mapa (reglas v65 de la duena
   generalizadas a los 25 mapas: suelo real bajo el punto
   (solidos + plataformas jump-through, la caja aterriza sobre
   obj_floor_parent en el cliente), sin abismo, sin resorte/hazard
   a 48px, nada de la fila alta, dedupe 96x64, caja APOYADA
   (y = top suelo - 30). Anillos = obj_ring_spawner de cada room. */
#include <entities/ItemBoxMap.h>

/* [0] Hide and Seek 2 (room_hideandseek2) — 8 zonas */
static const uint16_t itembox_spawns_0[][2] = {
        { 2064,  674 },
        { 2320,  674 },
        { 3264,  802 },
        { 3592,  994 },
        { 1208, 1186 },
        { 2136, 1186 },
        { 2232, 1186 },
        { 4520, 1250 },
};
#define ITEMBOX_ZONES_0 8
/* [1] Ravine Mist (room_ravinemist) — 8 zonas */
static const uint16_t itembox_spawns_1[][2] = {
        { 1508, 1246 },
        {  492, 1298 },
        { 2988, 1402 },
        { 2532, 1506 },
        { 2536, 1730 },
        { 2224, 1922 },
        { 1256, 1922 },
        {  356, 2234 },
};
#define ITEMBOX_ZONES_1 8
/* [2] ... (room_dotdotdot) — 8 zonas */
static const uint16_t itembox_spawns_2[][2] = {
        { 3168,  834 },
        { 3584,  834 },
        { 4152,  834 },
        { 4280,  834 },
        { 3872, 1666 },
        { 4192, 1666 },
        { 4032, 1746 },
        { 4360, 1746 },
};
#define ITEMBOX_ZONES_2 8
/* [3] Desert Town (room_deserttown) — 8 zonas */
static const uint16_t itembox_spawns_3[][2] = {
        { 1497,  706 },
        { 2249,  770 },
        { 1577,  866 },
        {  296,  882 },
        {  736, 1042 },
        { 1185, 1202 },
        { 1745, 1202 },
        { 3000, 1282 },
};
#define ITEMBOX_ZONES_3 8
/* [4] You Can't Run (room_youcantrun) — 8 zonas */
static const uint16_t itembox_spawns_4[][2] = {
        { 1124,  930 },
        {  384,  994 },
        {  288, 1074 },
        {  572, 1602 },
        { 1460, 1666 },
        { 1380, 1954 },
        {  956, 2018 },
        { 2952, 2018 },
};
#define ITEMBOX_ZONES_4 8
/* [5] Limp City (room_limpcity) — 8 zonas */
static const uint16_t itembox_spawns_5[][2] = {
        { 2584,  714 },
        {  852,  730 },
        { 1208,  746 },
        {  116,  802 },
        {  440,  802 },
        {  544,  802 },
        { 2736, 1122 },
        {  625, 1250 },
};
#define ITEMBOX_ZONES_5 8
/* [6] Not Perfect (room_notperfect) — 56 zonas.
   v77: la tabla v68 solo tenia puntos en la mitad INFERIOR (zonas 2=BL y
   3=BR del NP controller) porque sembro desde los obj_ring_spawner de
   abajo: con la rotacion de cuadrantes del mapa (SERVER_NPCONTROLLER_STATE
   cada ~20 s, ~5 s en el ultimo minuto) las cajas quedaban fuera de la
   zona jugable la mitad de la ronda. Se anaden 27 puntos para las zonas
   0=TL y 1=TR con el MISMO metodo v68 (verificado 29/29 contra la tabla
   original): semilla = obj_ring_spawner (+24 px), suelo en ventana de
   40 px (los rings flotan ~24 px sobre su plataforma), caja apoyada
   y=top_suelo-30, sin resorte a 48 px, validado contra los rects
   prohibidos del anti-cheat (Zone.c) sobre la posicion final de reposo
   del cliente, dedupe 96x64. Los nid 0..28 son LOS MISMOS de la v68
   (append puro: ningun indice existente cambia). */
static const uint16_t itembox_spawns_6[][2] = {
        { 1200, 1650 },
        { 1408, 1674 },
        { 1016, 1722 },
        { 1936, 1746 },
        {  816, 1794 },
        { 1360, 1818 },
        { 1192, 1890 },
        { 4624, 1938 },
        {  600, 1962 },
        { 1368, 1962 },
        { 1760, 1962 },
        { 3832, 1986 },
        { 4288, 1986 },
        { 4856, 1986 },
        {  864, 2034 },
        { 1864, 2058 },
        { 1120, 2082 },
        { 3400, 2106 },
        { 1560, 2178 },
        { 1208, 2250 },
        { 1416, 2250 },
        { 3200, 2250 },
        { 4760, 2250 },
        {  656, 2274 },
        { 4168, 2274 },
        { 5080, 2322 },
        {  168, 2346 },
        { 1312, 2346 },
        { 3776, 2346 },
        /* v77: mitad superior — zona 0 (TL) */
        {  272,  954 },
        {  528,  618 },
        {  536,  738 },
        {  752,  666 },
        {  872,  882 },
        {  928,  378 },
        { 1080,  954 },
        { 1168,  522 },
        { 1336,  378 },
        { 1552,  450 },
        { 1552,  666 },
        { 1608,  306 },
        { 1976,  714 },
        /* v77: mitad superior — zona 1 (TR) */
        { 3016, 1026 },
        { 3056, 1002 },
        { 3312,  714 },
        { 3528,  930 },
        { 3552,  714 },
        { 3776,  954 },
        { 4072,  594 },
        { 4096,  882 },
        { 4288,  594 },
        { 4288,  954 },
        { 4616, 1026 },
        { 4784,  594 },
        { 5296,  954 },
        { 5400, 1026 },
};
#define ITEMBOX_ZONES_6 56
/* [7] Kind and Fair (room_kindandfair) — 15 zonas */
static const uint16_t itembox_spawns_7[][2] = {
        {  728,  922 },
        { 1104,  930 },
        { 2792,  930 },
        {  304,  994 },
        { 2992, 1162 },
        { 3068, 1162 },
        { 3240, 1234 },
        { 3580, 1234 },
        { 4080, 1250 },
        { 1132, 1250 },
        { 1188, 1378 },
        { 1412, 1378 },
        { 2560, 1378 },
        { 2656, 1378 },
        { 1296, 1378 },
};
#define ITEMBOX_ZONES_7 15
/* [8] Act 9 (room_act9) — 15 zonas */
static const uint16_t itembox_spawns_8[][2] = {
        { 2224,  546 },
        { 2784,  546 },
        { 1232,  706 },
        {  568,  738 },
        {  312,  802 },
        { 1896,  802 },
        { 1296,  866 },
        { 1776,  866 },
        { 1472,  930 },
        { 1632,  930 },
        { 1112,  930 },
        { 1728,  930 },
        { 2088,  962 },
        { 1696, 1154 },
        { 1800, 1154 },
};
#define ITEMBOX_ZONES_8 15
/* [9] Nasty Paradise (room_nastyparadise) — 11 zonas */
static const uint16_t itembox_spawns_9[][2] = {
        { 2256,  538 },
        { 1352,  554 },
        {  176,  594 },
        { 3536,  726 },
        { 4096,  788 },
        { 3964,  786 },
        { 1324,  850 },
        { 2576,  850 },
        { 2876,  850 },
        { 1964,  914 },
        { 2172,  914 },
};
#define ITEMBOX_ZONES_9 11
/* [10] Priceless Freedom (room_pricelessfreedom) — 11 zonas */
static const uint16_t itembox_spawns_10[][2] = {
        { 2146,  810 },
        { 1096, 1050 },
        { 3480, 1110 },
        {   32, 1170 },
        { 2864, 1320 },
        { 3483, 1500 },
        { 1392, 1570 },
        { 2640, 1650 },
        { 2952, 1650 },
        {  431, 1650 },
        {  607, 1650 },
};
#define ITEMBOX_ZONES_10 11
/* [11] Volcano Valley (room_volcanovalley) — 12 zonas */
static const uint16_t itembox_spawns_11[][2] = {
        {  480,  754 },
        {  704,  754 },
        { 2112,  930 },
        { 1200,  962 },
        { 2944,  994 },
        { 3168, 1058 },
        { 4152, 1058 },
        { 4336, 1058 },
        { 1672, 1074 },
        {  976, 1346 },
        {  384, 1378 },
        { 2976, 1506 },
};
#define ITEMBOX_ZONES_11 12
/* [12] Hill (room_greenhill) — 8 zonas */
static const uint16_t itembox_spawns_12[][2] = {
        {  608,  438 },
        { 2320,  502 },
        { 5480,  506 },
        { 8060,  506 },
        { 3616,  618 },
        {  132,  614 },
        { 1808,  614 },
        { 7088,  617 },
};
#define ITEMBOX_ZONES_12 8
/* [13] Majin Forest (room_majongforest) — 3 zonas */
static const uint16_t itembox_spawns_13[][2] = {
        { 2696,  642 },
        {  616,  706 },
        {  960,  706 },
};
#define ITEMBOX_ZONES_13 3
/* [14] Hide and Seek (room_angelisland) — 11 zonas */
static const uint16_t itembox_spawns_14[][2] = {
        { 2296,  690 },
        { 2592,  690 },
        {  640,  754 },
        { 1544,  754 },
        { 1704,  754 },
        { 2688, 1010 },
        {  480, 1234 },
        { 1416, 1298 },
        {  800, 1330 },
        { 1688, 1330 },
        { 2736, 1330 },
};
#define ITEMBOX_ZONES_14 11
/* [15] Torture Cave (room_torturecave) — 16 zonas */
static const uint16_t itembox_spawns_15[][2] = {
        {  608,  540 },
        { 1872,  543 },
        { 2272,  543 },
        { 2728,  543 },
        { 1336,  543 },
        { 3888,  606 },
        { 4208,  638 },
        { 3880,  766 },
        { 2520,  799 },
        { 3032,  797 },
        {  280,  863 },
        { 1048,  927 },
        { 4528,  924 },
        { 1928,  990 },
        { 3888, 1022 },
        {  392, 1180 },
};
#define ITEMBOX_ZONES_15 16
/* [16] Dark Tower (room_dartower) — 10 zonas */
static const uint16_t itembox_spawns_16[][2] = {
        { 2488,  930 },
        {  216, 1090 },
        { 1192, 1138 },
        { 3688, 1330 },
        { 2232, 1650 },
        { 4232, 1650 },
        { 1832, 1730 },
        {  920, 1810 },
        { 1016, 1810 },
        { 3336, 1810 },
};
#define ITEMBOX_ZONES_16 10
/* [17] Haunting Dream (room_haundream) — 11 zonas */
static const uint16_t itembox_spawns_17[][2] = {
        {  296,  866 },
        {  368,  866 },
        { 2976,  898 },
        { 2416,  898 },
        { 3072,  931 },
        {  248, 1282 },
        { 1136, 1346 },
        { 3624, 1394 },
        {  624, 1506 },
        { 3120, 1746 },
        { 1696, 1810 },
};
#define ITEMBOX_ZONES_17 11
/* [18] WoodDream (room_weedzone) — 12 zonas */
static const uint16_t itembox_spawns_18[][2] = {
        {  568,  482 },
        { 1752,  482 },
        { 2152,  482 },
        { 4520,  514 },
        {  904,  546 },
        { 3032,  674 },
        { 3896,  674 },
        { 2904,  738 },
        {  824,  866 },
        { 2360,  866 },
        { 3312,  930 },
        { 3624,  930 },
};
#define ITEMBOX_ZONES_18 12
/* [19] Marijuna (room_marijuna) — 12 zonas */
static const uint16_t itembox_spawns_19[][2] = {
        { 2592,  834 },
        { 1584,  962 },
        { 3616,  962 },
        { 3968,  962 },
        {  896, 1058 },
        { 3120, 1522 },
        {   56, 1650 },
        { 1072, 1650 },
        { 1304, 1698 },
        { 1776, 1730 },
        { 2160, 1730 },
        { 2816, 1762 },
};
#define ITEMBOX_ZONES_19 12
/* [20] Fart Zone (room_fartzone) — 3 zonas */
static const uint16_t itembox_spawns_20[][2] = {
        {  336, 2450 },
        {  432, 2450 },
        {  528, 2450 },
};
#define ITEMBOX_ZONES_20 3
/* [21] SkyBase (room_skybase) — 4 zonas */
static const uint16_t itembox_spawns_21[][2] = {
        { 1472,  994 },
        { 2742, 1138 },
        { 2924, 1138 },
        {  828, 1250 },
};
#define ITEMBOX_ZONES_21 4
/* [22] Negagen Temple (room_alphagentemple) — 17 zonas */
static const uint16_t itembox_spawns_22[][2] = {
        {  696,  674 },
        {  872,  674 },
        { 1080,  674 },
        { 1256,  674 },
        {  248,  738 },
        { 2088,  802 },
        { 2296,  802 },
        { 1992,  866 },
        {  744,  962 },
        { 1896, 1058 },
        { 2152, 1058 },
        {  312, 1186 },
        {  744, 1186 },
        { 1264, 1250 },
        { 1456, 1250 },
        { 1960, 1250 },
        { 2056, 1250 },
};
#define ITEMBOX_ZONES_22 17
/* [23] Wood Zone (room_woodzone) — 5 zonas */
static const uint16_t itembox_spawns_23[][2] = {
        {  408,  850 },
        { 3416, 1010 },
        { 3368, 1474 },
        { 3496, 1474 },
        {  296, 1618 },
};
#define ITEMBOX_ZONES_23 5
/* [24] SkySanctuary (room_skysanctuary) — 9 zonas */
static const uint16_t itembox_spawns_24[][2] = {
        { 4280,  674 },
        { 2312,  706 },
        { 3264,  802 },
        {  952,  930 },
        { 1960, 1291 },
        { 2072, 1291 },
        { 4312, 1314 },
        { 1816, 1378 },
        { 2168, 1378 },
};
#define ITEMBOX_ZONES_24 9

/* dispatch por map id (g_mapList index). Mapas con 0 zonas:
   NULL -> el sistema central queda inactivo en ese mapa. */
const ItemBoxSpawnTable g_itembox_tables[MAP_COUNT] = {
        { itembox_spawns_0, ITEMBOX_ZONES_0 }, /* [0] Hide and Seek 2 */
        { itembox_spawns_1, ITEMBOX_ZONES_1 }, /* [1] Ravine Mist */
        { itembox_spawns_2, ITEMBOX_ZONES_2 }, /* [2] ... */
        { itembox_spawns_3, ITEMBOX_ZONES_3 }, /* [3] Desert Town */
        { itembox_spawns_4, ITEMBOX_ZONES_4 }, /* [4] You Can't Run */
        { itembox_spawns_5, ITEMBOX_ZONES_5 }, /* [5] Limp City */
        { itembox_spawns_6, ITEMBOX_ZONES_6 }, /* [6] Not Perfect */
        { itembox_spawns_7, ITEMBOX_ZONES_7 }, /* [7] Kind and Fair */
        { itembox_spawns_8, ITEMBOX_ZONES_8 }, /* [8] Act 9 */
        { itembox_spawns_9, ITEMBOX_ZONES_9 }, /* [9] Nasty Paradise */
        { itembox_spawns_10, ITEMBOX_ZONES_10 }, /* [10] Priceless Freedom */
        { itembox_spawns_11, ITEMBOX_ZONES_11 }, /* [11] Volcano Valley */
        { itembox_spawns_12, ITEMBOX_ZONES_12 }, /* [12] Hill */
        { itembox_spawns_13, ITEMBOX_ZONES_13 }, /* [13] Majin Forest */
        { itembox_spawns_14, ITEMBOX_ZONES_14 }, /* [14] Hide and Seek */
        { itembox_spawns_15, ITEMBOX_ZONES_15 }, /* [15] Torture Cave */
        { itembox_spawns_16, ITEMBOX_ZONES_16 }, /* [16] Dark Tower */
        { itembox_spawns_17, ITEMBOX_ZONES_17 }, /* [17] Haunting Dream */
        { itembox_spawns_18, ITEMBOX_ZONES_18 }, /* [18] WoodDream */
        { itembox_spawns_19, ITEMBOX_ZONES_19 }, /* [19] Marijuna */
        { itembox_spawns_20, ITEMBOX_ZONES_20 }, /* [20] Fart Zone */
        { itembox_spawns_21, ITEMBOX_ZONES_21 }, /* [21] SkyBase */
        { itembox_spawns_22, ITEMBOX_ZONES_22 }, /* [22] Negagen Temple */
        { itembox_spawns_23, ITEMBOX_ZONES_23 }, /* [23] Wood Zone */
        { itembox_spawns_24, ITEMBOX_ZONES_24 }, /* [24] SkySanctuary */
};

