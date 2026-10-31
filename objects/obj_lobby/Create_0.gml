playerCnt = 0;
countdown = -1;
isCounting = false;
isReady = false;
state = 0;
nextMap = -1;
fade = 0;
countScale = 1;
chat = [ ];
chatMsg = "";
chatMode = false;
charIndex = 0;

chars = 
[
        spr_menu_tails,
        spr_menu_knux,
        spr_menu_egg,
        spr_menu_amy,
        spr_menu_cream,
        spr_menu_sally,
        spr_menu_amy_canon,
        spr_menu_sonic_canon,
        spr_menu_sally, // 8: Sally Canon reusa el retrato de Sally
        spr_menu_cream, // 9: Vanilla reusa el retrato de Cream
        // v2.2 (TTB): los 3 rescatados
        spr_menu_metal, // 10: Metal Sonic
        spr_menu_amelia, // 11: Amelia
        spr_menu_blaze, // 12: Blaze
        // killers (offset CHARACTER_BLAZE = 13)
        spr_menu_exe,
        spr_menu_chaos,
        spr_menu_exetior,
        spr_menu_exeller,
        spr_menu_metalamy, // 17: Metal Amy (v2.2)
];

// Vote
map1 = 0;
map2 = 0;
map3 = 0;
mapOff = 4;
map1Votes = 0;
map2Votes = 0;
map3Votes = 0;
mapChose = false;
mapFade = 0;
mapChosen = 0;
voteTimer = 20;
canUse = false;

charTimer = 30;

voteKick = false;

if(obj_netclient.isConnected && obj_netclient.isReady && obj_netclient.nid != -1)
        instance_create_depth(0, 0, -100, obj_blackfadeout);

// Seguro de slots (ver scr_characters): revisa UNA sola vez que
// chars[], palettes, player_anims y player_get cubran a todos los
// personajes hasta CHARACTER_SURV_MAX. Solo loguea por consola.
scr_characters_sanity();