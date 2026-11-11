#macro CHARACTER_EXE 0
#macro EXE_ORIGINAL 0
#macro EXE_CHAOS 1
#macro EXE_EXETIOR 2
#macro EXE_EXELLER 3
/* v2.2 — killer rescatado de TD2D Through the Blood. Mismo orden
   que el EX_* del server (betterserver-oss/include/Server.h). */
#macro EXE_METALAMY 4
/* v1 — killer rescatado de TD2DR Darkness In Blood (D.I.B., GameJolt
   1104339). Mismo orden que el EX_* del server. */
#macro EXE_JINNA 5

global.player_exesanims = ds_map_create();
global.player_exesanims[? EXE_ORIGINAL] = 
[
        //Visible
        spr_exe_idle, //0
        spr_exe_walk, //1
        spr_exe_run, //2
        spr_exe_jump, //3
        spr_exe_fall, //4
        spr_exe_hurt, //5
        spr_exe_jump, //6
        spr_exe_lookup, //7
        spr_exe_lookdown, //8
        spr_exe_emotion2, // 9
        spr_exe_emotion3, //10
        spr_exe_emotion, // 11
        spr_exe_jump, //12
        spr_exe_balancing, //13
        spr_exe_attack1, //14
        spr_exe_attack2, //15
        spr_exe_shocked, //16
        spr_exe_emotion, //17
        spr_exe_lost, //18
        spr_exe_zipline, //19
        
        // Invisible
        spr_exe_invis_idle, //0
        spr_exe_invis_walk, //1
        spr_exe_invis_run,  //2
        spr_exe_invis_jump, //3
        spr_exe_invis_fall, //4
        spr_exe_invis_walk, //5
        spr_exe_invis_jump, //6
        spr_exe_invis_lookup, //7
        spr_exe_invis_lookdown, //8
        spr_exe_invis_emotion, //9
        spr_exe_invis_emotion, //10
        spr_exe_invis_emotion, //11
        spr_exe_invis_jump, //12
        spr_exe_invis_balancing, //13
        spr_exe_invis_walk, //14
        spr_exe_invis_walk, //15
        spr_exe_invis_lookdown, //16
        spr_exe_invis_walk, //17
        spr_exe_invis_walk, //18
        spr_exe_invis_zipline //19
];

global.player_exesanims[? EXE_CHAOS] = 
[
        //Visible
        spr_chaos_idle, //0
        spr_chaos_walk, //1
        spr_chaos_run, //2
        spr_chaos_jump, //3
        spr_chaos_fall, //4
        spr_chaos_hurt, //5
        spr_chaos_jump, //6
        spr_chaos_lookup, //7
        spr_chaos_lookdown, //8
        spr_chaos_emotion1, //9
        spr_chaos_emotion2, //10
        spr_chaos_emotion3, //11
        spr_chaos_jump, //12
        spr_chaos_balancing, //13
        spr_chaos_attack1, //14
        spr_chaos_attack2, //15
        spr_chaos_stun, //16
        spr_chaos_won, //17
        spr_chaos_lost, //18
        spr_chaos_lost2, //19
        spr_chaos_zipline, //20
        spr_chaos_stuck, //21
        spr_chaos_stuck2, //22
        spr_chaos_stransform, //23
        spr_chaos_stransformair, //24
        
        // Invisible
        spr_chaos_sidle, //0
        spr_chaos_swalk, //1
        spr_chaos_swalk,  //2
        spr_chaos_sjump, //3
        spr_chaos_sfall, //4
        spr_chaos_swalk, //5
        spr_chaos_sjump, //6
        spr_chaos_sidle, //7
        spr_chaos_sidle, //8
        spr_chaos_sidle, //9
        spr_chaos_sidle, //10
        spr_chaos_sidle, //11
        spr_chaos_sidle, //12
        spr_chaos_sidle, //13
        spr_chaos_sidle, //14
        spr_chaos_sidle, //15
        spr_chaos_sidle, //16
        spr_chaos_sidle, //17
        spr_chaos_sidle, //18
        spr_chaos_sidle, //19
        spr_chaos_sidle, //20
        spr_chaos_sidle, //21
        spr_chaos_sidle, //22
        spr_chaos_sidle, //23
        spr_chaos_sidle, //24
];

global.player_exesanims[? EXE_EXETIOR] = 
[
        //Visible
        spr_exetior_idle, //0
        spr_exetior_walk, //1
        spr_exetior_run, //2
        spr_exetior_jump, //3
        spr_exetior_fall, //4
        spr_exetior_hurt, //5
        spr_exetior_jump, //6
        spr_exetior_lookup, //7
        spr_exetior_lookdown, //8
        spr_exetior_emotion3, // 9
        spr_exetior_emotion2, //10
        spr_exetior_emotion, // 11
        spr_exetior_jump, //12
        spr_exetior_balancing, //13
        spr_exetior_attack1, //14
        spr_exetior_attack2, //15
        spr_exetior_shocked, //16
        spr_exetior_won, //17
        spr_exetior_lost, //18
        spr_exetior_zipline, //19
        spr_exetior_stomp, //20
        spr_exetior_stompland //21
];

global.player_exesanims[? EXE_EXELLER] = 
[
        //Visible
        spr_exeller_idle, //0
        spr_exeller_walk, //1
        spr_exeller_run, //2
        spr_exeller_jump, //3
        spr_exeller_fall, //4
        spr_exeller_hurt, //5
        spr_exeller_jump, //6
        spr_exeller_lookup, //7
        spr_exeller_lookdown, //8
        spr_exeller_emotion3, // 9
        spr_exeller_emotion2, //10
        spr_exeller_emotion, // 11
        spr_exeller_jump, //12
        spr_exeller_balancing, //13
        spr_exeller_attack1, //14
        spr_exeller_attack2, //15
        spr_exeller_shocked, //16
        spr_exeller_won, //17
        spr_exeller_lost, //18
        spr_exeller_zipline, //19
        spr_exeller_lost2, //20
];

/* v2.2 — METAL AMY (killer de TD2D Through the Blood): mismo layout
   que Exeller + slots propios al final. v4.6: el 15 (dash aereo) pasa
   de attack22 a attack2, la animacion de embestida pedida. v4.7: el
   14 (dash en tierra) REUSA attack2 — la vieja attack11 salio del kit
   (al impactar/aterrizar el sprite ya no cambia: se mantiene attack2) —
   y el 21 es la pose de escaneo de la V (scan). El 19 la tirolina.
   NO tiene lost2: reusa lost (defensivo). */
global.player_exesanims[? EXE_METALAMY] = 
[
        //Visible
        spr_metalamy_idle, //0
        spr_metalamy_walk, //1
        spr_metalamy_run, //2
        spr_metalamy_jump, //3
        spr_metalamy_fall, //4
        spr_metalamy_hurt, //5
        spr_metalamy_jump, //6
        spr_metalamy_lookup, //7
        spr_metalamy_lookdown, //8
        spr_metalamy_emotion3, // 9
        spr_metalamy_emotion2, //10
        spr_metalamy_emotion, // 11
        spr_metalamy_jump, //12
        spr_metalamy_balancing, //13
        spr_metalamy_attack2, //14 = dash en tierra v4.7 (reusa attack2; antes attack11)
        spr_metalamy_attack2, //15 = dash aereo v4.6 (antes attack22)
        spr_metalamy_shocked, //16
        spr_metalamy_won, //17
        spr_metalamy_lost, //18
        spr_metalamy_zipline, //19
        spr_metalamy_lazer, //20 = METALAMY_LAZER: pose de disparo (tecla C)
        spr_metalamy_scan  //21 = METALAMY_SCAN: pose de escaneo (tecla V, v4.7)
];

/* v1 (D.I.B.): JINNA — 22 slots. Los base 0-19 y DOS propios:
   20 = JINNA_LOST2 (derrota alterna, patron chaos) y
   21 = JINNA_TELE (pose de teletransporte, tecla C). Los estados
   se declaran en obj_jinna/Step_2 (JINNA_* = BALANCING+N). */
global.player_exesanims[? EXE_JINNA] = 
[
        //Visible
        spr_jinna_idle, //0
        spr_jinna_walk, //1
        spr_jinna_run, //2
        spr_jinna_jump, //3
        spr_jinna_fall, //4
        spr_jinna_hurt, //5
        spr_jinna_jump, //6
        spr_jinna_lookup, //7
        spr_jinna_lookdown, //8
        spr_jinna_emotion, // 9
        spr_jinna_emotion2, //10
        spr_jinna_emotion3, //11
        spr_jinna_jump, //12
        spr_jinna_balancing, //13
        spr_jinna_attack1, //14 = golpe en tierra (JINNA_ATTACK1)
        spr_jinna_attack2, //15 = golpe aereo / pose de agarre (JINNA_ATTACK2)
        spr_jinna_shocked, //16
        spr_jinna_won, //17
        spr_jinna_lost, //18
        spr_jinna_zipline, //19
        spr_jinna_lost2, //20 = JINNA_LOST2: derrota alterna (patron chaos)
        spr_jinna_tele //21 = JINNA_TELE: pose de teletransporte (tecla C)
];


function player_getexe(ind)
{
        switch(ind)
        {
                case 0:
                        return obj_exe;
                        
                case 1:
                        return obj_chaos;
                        
                case 2:
                        return obj_exetior;
                        
                case 3:
                        return obj_exeller;

                case 4:
                        return obj_metalamy;

                case 5:
                        return obj_jinna;
        }
}