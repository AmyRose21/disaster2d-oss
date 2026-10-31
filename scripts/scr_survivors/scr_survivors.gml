#macro IDLE 0
#macro WALK 1
#macro RUN 2
#macro JUMP 3
#macro FALL 4
#macro HURT 5
#macro DEAD 6
#macro LOOKUP 7
#macro LOOKDOWN 8
#macro EMOTION1 9
#macro EMOTION2 10
#macro EMOTION3 11
#macro SPIN 12
#macro BALANCING 13

#macro CHARACTER_TAILS 1
#macro CHARACTER_KNUX (CHARACTER_TAILS+1)
#macro CHARACTER_EGGMAN (CHARACTER_TAILS+2)
#macro CHARACTER_AMY (CHARACTER_TAILS+3)
#macro CHARACTER_CREAM (CHARACTER_TAILS+4)
#macro CHARACTER_SALLY (CHARACTER_TAILS+5)
#macro CHARACTER_AMY_CANON (CHARACTER_TAILS+6)
#macro CHARACTER_SONIC (CHARACTER_TAILS+7)
#macro CHARACTER_SALLY_CANON (CHARACTER_TAILS+8)
#macro CHARACTER_VANILLA (CHARACTER_TAILS+9)

/* v2.2 — supervivientes rescatados de TD2D Through the Blood
   (mod abandonado de maxbaxwer). Mismo orden que el CH_* del
   server (betterserver-oss/include/Server.h). */
#macro CHARACTER_METAL (CHARACTER_TAILS+10)   // Metal Sonic
#macro CHARACTER_AMELIA (CHARACTER_TAILS+11)  // Amelia
#macro CHARACTER_BLAZE (CHARACTER_TAILS+12)   // Blaze

global.player_anims = ds_map_create();

//Tails
global.player_anims[? CHARACTER_TAILS] = 
[
        spr_tails_idle, //0
        spr_tails_walk, //1
        spr_tails_run, //2
        spr_tails_jump, //3
        spr_tails_fall, //4
        spr_tails_hurt, //5
        spr_tails_dead, //6
        spr_tails_lookup, //7
        spr_tails_lookdown, //8
        spr_tails_emotion1, //9
        spr_tails_emotion2, //10
        spr_tails_emotion3, //11
        spr_tails_jump, //12
        spr_tails_balancing, //13
        spr_tails_fly, //14
        spr_tails_attack1, //15
        spr_tails_zipline, //16
];

//Knux
global.player_anims[? CHARACTER_KNUX] = 
[
        spr_knux_idle, //0
        spr_knux_walk, //1
        spr_knux_run, //2
        spr_knux_jump, //3
        spr_knux_fall, //4
        spr_knux_hurt, //5
        spr_knux_dead, //6
        spr_knux_lookup, //7
        spr_knux_lookdown, //8
        spr_knux_emotion1, //9
        spr_knux_emotion2, //10
        spr_knux_emotion3, //11
        spr_knux_jump, //12
        spr_knux_balancing, //13
        spr_knux_attack2, //14
        spr_knux_attack1, //15
        spr_knux_glide, //16
        spr_knux_zipline, //17
        spr_knux_stuck //18
];

//Egg
global.player_anims[? CHARACTER_EGGMAN] = 
[
        spr_egg_idle, //0
        spr_egg_walk, //1
        spr_egg_run, //2
        spr_egg_jump, //3
        spr_egg_fall, //4
        spr_egg_hurt, //5
        spr_egg_dead, //6
        spr_egg_lookup, //7
        spr_egg_lookdown, //8
        spr_egg_emotion1, //9
        spr_egg_emotion2, //10
        spr_egg_emotion3, //11
        spr_egg_jump, //12
        spr_egg_balancing, //13
        spr_egg_djump, //14
        spr_egg_zipline //15
];

//Amy
global.player_anims[? CHARACTER_AMY] = 
[
        spr_amy_idle, //0
        spr_amy_walk, //1
        spr_amy_run, //2
        spr_amy_jump, //3
        spr_amy_fall, //4
        spr_amy_hurt, //5
        spr_amy_dead, //6
        spr_amy_lookup, //7
        spr_amy_lookdown, //8
        spr_amy_emotion1, //9
        spr_amy_emotion2, //10
        spr_amy_emotion3, //11
        spr_amy_jump, //12
        spr_amy_balancing, //13
        spr_amy_attack1, //14
        spr_amy_attack2, //15
        spr_none, //16
        spr_amy_zipline //17
];

//Amy Canon
global.player_anims[? CHARACTER_AMY_CANON] = 
[
        spr_amy_idle_canon, //0
        spr_amy_walk_canon, //1
        spr_amy_run_canon, //2
        spr_amy_jump_canon, //3
        spr_amy_fall_canon, //4
        spr_amy_hurt_canon, //5
        spr_amy_dead_canon, //6
        spr_amy_lookup_canon, //7
        spr_amy_lookdown_canon, //8
        spr_amy_emotion1_canon, //9
        spr_amy_emotion2_canon, //10
        spr_amy_emotion3_canon, //11
        spr_amy_jump_canon, //12
        spr_amy_balancing, //13
        spr_amy_attack1_canon, //14
        spr_amy_attack2_canon, //15
        spr_none, //16
        spr_amy_zipline_canon, //17
        spr_amy_attack3_canon_, //18 = ATAQUE 3: acometida de martillo (estado AMY_CANON_DASH)
        spr_amy_capture_canon, //19 = SECUESTRO: mira al frente (sin teclas de movimiento)
        spr_amy_capture_canon_left, //20 = SECUESTRO: moviendose a la izquierda
        spr_amy_capture_canon_right, //21 = SECUESTRO: moviendose a la derecha
        spr_amy_tarot_float, //22 = PASIVA TAROT: flotacion lenta al caer
        spr_amy_attack1_canon //23 = HABILIDAD 2 (tecla X) en el aire: impulso de tarot (sprite nuevo de 2 frames)
];

//Sonic
global.player_anims[? CHARACTER_SONIC] = 
[
        spr_sonic_idle, //0
        spr_sonic_walk, //1
        spr_sonic_run, //2
        spr_sonic_jump, //3 = PASIVA: salto giratorio (bola)
        spr_sonic_fall, //4
        spr_sonic_hurt, //5
        spr_sonic_dead, //6
        spr_sonic_lookup, //7
        spr_sonic_lookdown, //8
        spr_sonic_emotion1, //9
        spr_sonic_emotion2, //10
        spr_sonic_emotion3, //11
        spr_sonic_jump, //12 = SPIN (rodar): mismo sprite del salto, como Tails/Knux
        spr_sonic_balancing, //13
        spr_sonic_attack2_tierra1, //14 = el golpe estilo EXE (backup; el golpe ya usa el escaneo dinamico)
        spr_sonic_spin_charger, //15 = ATAQUE 2: carga del spindash (estado SONIC_SPINDASH)
        spr_none, //16
        spr_sonic_zipline, //17 = tirolina (estado SONIC_ZIPLINE, arreglado v2)
        spr_sonic_nervios_de_acero_Idle, //18 = NERVIOS DE ACERO: tirado en el suelo, Idle en LOOP (estado SONIC_NERVIOS)
        spr_sonic_nervios_de_acero_finish //19 = NERVIOS DE ACERO: levantandose (estado SONIC_NERVIOS_FINISH)
        // Las variantes del golpe (spr_sonic_attack2_tierra<N> / aereo<N>)
        // ya NO van aqui: se detectan solas por nombre (bloque de variantes
        // dinamicas al final de este archivo, estados 20-39 / 40-59)
];

//Cream
global.player_anims[? CHARACTER_CREAM] = 
[
        spr_cream_idle, //0
        spr_cream_walk, //1
        spr_cream_run, //2
        spr_cream_jump, //3
        spr_cream_fall, //4
        spr_cream_hurt, //5
        spr_cream_dead, //6
        spr_cream_lookup, //7
        spr_cream_lookdown, //8
        spr_cream_emotion1, //9
        spr_cream_emotion2, //10
        spr_cream_emotion3, //11
        spr_cream_jump, //12
        spr_cream_balancing, //13
        spr_cream_fly, //14
        spr_cream_srings, //15
        spr_cream_zipline //16
];

//Sally
global.player_anims[? CHARACTER_SALLY] = 
[
        spr_sally_idle, //0
        spr_sally_walk, //1
        spr_sally_run, //2
        spr_sally_jump, //3
        spr_sally_fall, //4
        spr_sally_hurt, //5
        spr_sally_dead, //6
        spr_sally_lookup, //7
        spr_sally_lookdown, //8
        spr_sally_emotion1, //9
        spr_sally_emotion2, //10
        spr_sally_emotion3, //11
        spr_sally_jump, //12
        spr_sally_balancing, //13
        spr_sally_attack, //14
        spr_sally_slide, //15
        spr_none, // 16
        spr_sally_zipline // 17
];

//Sally Canon (reusa el retrato de menu y el icono de vida de Sally;
//sus sprites propios son los _canon. 18-21 = fase 2, ver
//scr_sally_canon_fase2.gml)
global.player_anims[? CHARACTER_SALLY_CANON] =
[
        spr_sally_idle_canon, //0
        spr_sally_walk_canon, //1
        spr_sally_run_canon, //2
        spr_sally_jump_canon, //3
        spr_sally_fall_canon, //4
        spr_sally_hurt_canon, //5
        spr_sally_dead_canon, //6
        spr_sally_lookup_canon, //7
        spr_sally_lookdown_canon, //8
        spr_sally_emotion1_canon, //9
        spr_sally_emotion2_canon, //10
        spr_sally_emotion3_canon, //11
        spr_sally_jump_canon, //12
        spr_sally_balancing_canon, //13
        spr_sally_attack_canon, //14
        spr_sally_slide_canon, //15
        spr_none, // 16
        spr_sally_zipline_canon, //17
        spr_sally_fase2_canon_pt1, //18 = FASE 2 pt1: golpe + retroceso
        spr_sally_fase2_canon_pt2, //19 = FASE 2 pt2: tirada en el suelo
        spr_sally_fase2_canon_pt3, //20 = FASE 2 pt3: salto (loop)
        spr_sally_fase2_canon_pt4 //21 = FASE 2 pt4: recuperacion
];

//Vanilla (mod): superviviente #10. Habilidades = Cream (scr_cream_special);
//sprites propios spr_vanilla_*. Retrato de menu y barra de vida reusan
//los de Cream (obj_lobby / obj_level). Indices 14-16 = vuelo/anillos/
//tirolina (mismos estados CREAM_* que viajan por red para Cream).
global.player_anims[? CHARACTER_VANILLA] =
[
        spr_vanilla_idle, //0
        spr_vanilla_walk, //1
        spr_vanilla_run, //2
        spr_vanilla_jump, //3
        spr_vanilla_fall, //4
        spr_vanilla_hurt, //5
        spr_vanilla_dead, //6
        spr_vanilla_lookup, //7
        spr_vanilla_lookdown, //8
        spr_vanilla_emotion1, //9
        spr_vanilla_emotion2, //10
        spr_vanilla_emotion3, //11
        spr_vanilla_jump, //12
        spr_vanilla_balancing, //13
        spr_vanilla_fly, //14
        spr_vanilla_srings, //15
        spr_vanilla_zipline, //16
        spr_vanilla_float_run, //17 = V2: 3ra fase de corrida (estado VANILLA_FLOAT_RUN)
        spr_vanilla_paciencia, //18 = V2: PACIENCIA (1ra caida, inmune)
        spr_vanilla_paciencia_agotada //19 = V2: agotada al final / moribunda
];

// =====================================================================
//  v2.2 — SUPERVIVIENTES DE TD2D THROUGH THE BLOOD
//  (sprites rescatados del mod abandonado). Estados propios de cada
//  uno definidos en su Step_2 (patron BALANCING+N).
// =====================================================================

// Metal Sonic: 14 = METAL_ATTACK (overdrive), 15 = METAL_ELECTRO,
// 16 = METAL_ZIPLINE
// METAL (demonizado): no tiene dead, reusa hurt (defensivo, como Vanilla)
global.player_anims[? CHARACTER_METAL] =
[
        spr_metal_idle, //0
        spr_metal_walk, //1
        spr_metal_run, //2
        spr_metal_jump, //3
        spr_metal_fall, //4
        spr_metal_hurt, //5
        spr_metal_dead, //6
        spr_metal_lookup, //7
        spr_metal_lookdown, //8
        spr_metal_emotion1, //9
        spr_metal_emotion2, //10
        spr_metal_emotion3, //11
        spr_metal_jump, //12 (spin)
        spr_metal_balancing, //13
        spr_metal_attack, //14 = METAL_ATTACK: dash (tecla X)
        spr_metal_attack2, //15 = METAL_ELECTRO: electrocutado (tecla C)
        spr_metal_zipline //16 = METAL_ZIPLINE
];

// Amelia: 14 = AMELIA_FLY, 15 = AMELIA_SPINDASH (v2.6),
// 16 = AMELIA_ZIPLINE
global.player_anims[? CHARACTER_AMELIA] =
[
        spr_amelia_idle, //0
        spr_amelia_walk, //1
        spr_amelia_run, //2
        spr_amelia_jump, //3
        spr_amelia_fall, //4
        spr_amelia_hurt, //5
        spr_amelia_dead, //6
        spr_amelia_lookup, //7
        spr_amelia_lookdown, //8
        spr_amelia_emotion1, //9
        spr_amelia_emotion2, //10
        spr_amelia_emotion3, //11
        spr_amelia_jump, //12 (spin)
        spr_amelia_balancing, //13
        spr_amelia_fly, //14 = AMELIA_FLY (tecla Z en el aire)
        spr_amelia_spindash, //15 = AMELIA_SPINDASH: carga del spindash (v2.6)
        spr_amelia_zipline //16 = AMELIA_ZIPLINE
];

// Blaze: 14 = BLAZE_FIREBALL (posicion de disparo), 15 = BLAZE_BURNING,
// 16 = BLAZE_ZIPLINE
global.player_anims[? CHARACTER_BLAZE] =
[
        spr_blaze_idle, //0
        spr_blaze_walk, //1
        spr_blaze_run, //2
        spr_blaze_jump, //3
        spr_blaze_fall, //4
        spr_blaze_hurt, //5
        spr_blaze_dead, //6
        spr_blaze_lookup, //7
        spr_blaze_lookdown, //8
        spr_blaze_emotion1, //9
        spr_blaze_emotion2, //10
        spr_blaze_emotion3, //11
        spr_blaze_jump, //12 (spin)
        spr_blaze_balancing, //13
        spr_blaze_go, //14 = BLAZE_FIREBALL: lanzar bola (tecla X)
        spr_blaze_goon, //15 = BLAZE_BURNING: forma ardiente (tecla C)
        spr_blaze_zipline //16 = BLAZE_ZIPLINE
];

global.player_eanims = ds_map_create();

//Tails
global.player_eanims[? CHARACTER_TAILS] = 
[
        spr_etails_idle, //0
        spr_etails_walk, //1
        spr_etails_run, //2
        spr_etails_jump, //3
        spr_etails_fall, //4
        spr_etails_hurt, //5
        spr_etails_stun, //6
        spr_etails_lookup, //7
        spr_etails_lookdown, //8
        spr_etails_emotion1, //9
        spr_etails_emotion2, //10
        spr_etails_emotion3, //11
        spr_etails_jump, //12
        spr_etails_balancing, //13
        spr_etails_fly, //14
        spr_etails_attack1, //15
        spr_etails_zipline //16
];

//Knux
global.player_eanims[? CHARACTER_KNUX] = 
[
        spr_eknux_idle, //0
        spr_eknux_walk, //1
        spr_eknux_run, //2
        spr_eknux_jump, //3
        spr_eknux_fall, //4
        spr_eknux_hurt, //5
        spr_eknux_stun, //6
        spr_eknux_lookup, //7
        spr_eknux_lookdown, //8
        spr_eknux_emotion1, //9
        spr_eknux_emotion2, //10
        spr_eknux_emotion3, //11
        spr_eknux_jump, //12
        spr_eknux_balancing, //13
        spr_eknux_attack2, //14
        spr_eknux_attack1, //15
        spr_eknux_glide, //16
        spr_eknux_zipline, //17
        spr_eknux_stuck //18
];

//Egg
global.player_eanims[? CHARACTER_EGGMAN] = 
[
        spr_eegg_idle, //0
        spr_eegg_walk, //1
        spr_eegg_run, //2
        spr_eegg_jump, //3
        spr_eegg_fall, //4
        spr_eegg_hurt, //5
        spr_eegg_stun, //6
        spr_eegg_lookup, //7
        spr_eegg_lookdown, //8
        spr_eegg_emotion1, //9
        spr_eegg_emotion2, //10
        spr_eegg_emotion3, //11
        spr_eegg_jump, //12
        spr_eegg_balancing, //13
        spr_eegg_djump, //14
        spr_eegg_zipline //15
];

//Amy
global.player_eanims[? CHARACTER_AMY] = 
[
        spr_eamy_idle, //0
        spr_eamy_walk, //1
        spr_eamy_run, //2
        spr_eamy_jump, //3
        spr_eamy_fall, //4
        spr_eamy_hurt, //5
        spr_eamy_stun, //6
        spr_eamy_lookup, //7
        spr_eamy_lookdown, //8
        spr_eamy_emotion1, //9
        spr_eamy_emotion2, //10
        spr_eamy_emotion3, //11
        spr_eamy_jump, //12
        spr_eamy_balancing, //13
        spr_eamy_attack1, //14
        spr_eamy_attack2, //15
        spr_none, // 16
        spr_eamy_zipline //17
];

//Amy Canon
global.player_eanims[? CHARACTER_AMY_CANON] = 
[
        spr_eamy_idle_canon, //0
        spr_eamy_walk_canon, //1
        spr_eamy_run_canon, //2
        spr_eamy_jump_canon, //3
        spr_eamy_fall_canon, //4
        spr_eamy_hurt_canon, //5
        spr_eamy_stun_canon, //6
        spr_eamy_lookup_canon, //7
        spr_eamy_lookdown_canon, //8
        spr_eamy_emotion1_canon, //9
        spr_eamy_emotion2_canon, //10
        spr_eamy_emotion3_canon, //11
        spr_eamy_jump_canon, //12
        spr_eamy_balancing, //13
        spr_eamy_attack1_canon, //14
        spr_eamy_attack2_canon, //15
        spr_none, // 16
        spr_eamy_zipline_canon, //17
        spr_amy_attack3_canon_, //18 = ATAQUE 3: acometida (variante demonizada). Cuando crees spr_eamy_attack3_canon, cambialo aqui
        spr_amy_capture_canon, //19 = SECUESTRO (frente) — antes faltaban los 19-21 en eanims: hueco arreglado
        spr_amy_capture_canon_left, //20 = SECUESTRO: izquierda
        spr_amy_capture_canon_right, //21 = SECUESTRO: derecha
        spr_amy_tarot_float, //22 = PASIVA TAROT (demonizada flota igual)
        spr_amy_attack1_canon //23 = HABILIDAD 2 (tecla X) en el aire: impulso de tarot (mismo sprite que la jugadora)
];

//Sonic (demonizado: aun no hay sprites esonic_*; se usan los normales.
// Cuando crees spr_esonic_*, cambia este bloque por los suyos.)
global.player_eanims[? CHARACTER_SONIC] = 
[
        spr_sonic_idle, //0
        spr_sonic_walk, //1
        spr_sonic_run, //2
        spr_sonic_jump, //3
        spr_sonic_fall, //4
        spr_sonic_hurt, //5
        spr_sonic_jump, //6 = stun (variante demonizada; cambiar por spr_esonic_stun cuando exista)
        spr_sonic_lookup, //7
        spr_sonic_lookdown, //8
        spr_sonic_emotion1, //9
        spr_sonic_emotion2, //10
        spr_sonic_emotion3, //11
        spr_sonic_jump, //12
        spr_sonic_balancing, //13
        spr_sonic_attack2_tierra1, //14
        spr_sonic_spin_charger, //15
        spr_none, //16
        spr_sonic_zipline, //17 = tirolina (arreglado v2)
        spr_sonic_nervios_de_acero_Idle, //18 = NERVIOS DE ACERO (demonizado: igual)
        spr_sonic_nervios_de_acero_finish //19 = NERVIOS DE ACERO: levantandose
];

//Cream
global.player_eanims[? CHARACTER_CREAM] = 
[
        spr_ecream_idle, //0
        spr_ecream_walk, //1
        spr_ecream_run, //2
        spr_ecream_jump, //3
        spr_ecream_fall, //4
        spr_ecream_hurt, //5
        spr_ecream_stun, //6
        spr_ecream_lookup, //7
        spr_ecream_lookdown, //8
        spr_ecream_emotion1, //9
        spr_ecream_emotion2, //10
        spr_ecream_emotion3, //11
        spr_ecream_jump, //12
        spr_ecream_balancing, //13
        spr_ecream_fly, //14
        spr_ecream_srings, //15
        spr_ecream_zipline //16
];

//Sally
global.player_eanims[? CHARACTER_SALLY] = 
[
        spr_esally_idle, //0
        spr_esally_walk, //1
        spr_esally_run, //2
        spr_esally_jump, //3
        spr_esally_fall, //4
        spr_esally_hurt, //5
        spr_esally_stun, //6
        spr_esally_lookup, //7
        spr_esally_lookdown, //8
        spr_esally_emotion1, //9
        spr_esally_emotion2, //10
        spr_esally_emotion3, //11
        spr_esally_jump, //12
        spr_esally_balancing, //13
        spr_esally_attack, //14
        spr_esally_slide, //15
        spr_none, // 16
        spr_esally_zipline // 17
];

//Sally Canon (demonizada): JAMAS se demoniza (regla canonica, parche
//del server), asi que reusa sus sprites normales. Solo defensivo por
//si algun camino llegara a leer eanims con revivalTimes >= 2.
global.player_eanims[? CHARACTER_SALLY_CANON] =
[
        spr_sally_idle_canon, //0
        spr_sally_walk_canon, //1
        spr_sally_run_canon, //2
        spr_sally_jump_canon, //3
        spr_sally_fall_canon, //4
        spr_sally_hurt_canon, //5
        spr_sally_dead_canon, //6
        spr_sally_lookup_canon, //7
        spr_sally_lookdown_canon, //8
        spr_sally_emotion1_canon, //9
        spr_sally_emotion2_canon, //10
        spr_sally_emotion3_canon, //11
        spr_sally_jump_canon, //12
        spr_sally_balancing_canon, //13
        spr_sally_attack_canon, //14
        spr_sally_slide_canon, //15
        spr_none, // 16
        spr_sally_zipline_canon, //17
        spr_sally_fase2_canon_pt1, //18
        spr_sally_fase2_canon_pt2, //19
        spr_sally_fase2_canon_pt3, //20
        spr_sally_fase2_canon_pt4 //21
];

//Vanilla (demonizada): no hay sprites demonizados suyos todavia;
//reusa sus sprites normales (la demonizacion se ve en el HUD, el
//icono y el palette shift demon). Defensivo, igual que el eanims
//de Sally Canon: solo se lee si algun camino llega aqui con
//revivalTimes >= 2.
global.player_eanims[? CHARACTER_VANILLA] =
[
        spr_vanilla_idle, //0
        spr_vanilla_walk, //1
        spr_vanilla_run, //2
        spr_vanilla_jump, //3
        spr_vanilla_fall, //4
        spr_vanilla_hurt, //5
        spr_vanilla_dead, //6
        spr_vanilla_lookup, //7
        spr_vanilla_lookdown, //8
        spr_vanilla_emotion1, //9
        spr_vanilla_emotion2, //10
        spr_vanilla_emotion3, //11
        spr_vanilla_jump, //12
        spr_vanilla_balancing, //13
        spr_vanilla_fly, //14
        spr_vanilla_srings, //15
        spr_vanilla_zipline, //16
        spr_vanilla_run, //17 = V2: float run (defensivo; Vanilla no se demoniza)
        spr_vanilla_paciencia, //18 = V2: paciencia
        spr_vanilla_paciencia_agotada //19 = V2: agotada / moribunda
];

// METAL SONIC (demonizado): set completo de emetal_* (TTB). El slot 6
// de las formas demonizadas es el STUN (patron etails/eknux).
global.player_eanims[? CHARACTER_METAL] =
[
        spr_emetal_idle, //0
        spr_emetal_walk, //1
        spr_emetal_run, //2
        spr_emetal_jump, //3
        spr_emetal_fall, //4
        spr_emetal_hurt, //5
        spr_emetal_stun, //6
        spr_emetal_lookup, //7
        spr_emetal_lookdown, //8
        spr_emetal_emotion1, //9
        spr_emetal_emotion2, //10
        spr_emetal_emotion3, //11
        spr_emetal_jump, //12
        spr_emetal_balancing, //13
        spr_emetal_attack, //14
        spr_emetal_attack2, //15
        spr_emetal_zipline //16
];

// AMELIA (demonizada): set completo de eamelia_*. El 6 es stun (no
// existe sprite stun propio: reusa hurt, defensivo).
global.player_eanims[? CHARACTER_AMELIA] =
[
        spr_eamelia_idle, //0
        spr_eamelia_walk, //1
        spr_eamelia_run, //2
        spr_eamelia_jump, //3
        spr_eamelia_fall, //4
        spr_eamelia_hurt, //5
        spr_eamelia_hurt, //6 (stun defensivo)
        spr_eamelia_lookup, //7
        spr_eamelia_lookdown, //8
        spr_eamelia_emotion1, //9
        spr_eamelia_emotion2, //10
        spr_eamelia_emotion3, //11
        spr_eamelia_jump, //12
        spr_eamelia_balancing, //13
        spr_eamelia_fly, //14
        spr_eamelia_spindash, //15 = AMELIA_SPINDASH (v2.6)
        spr_eamelia_zipline //16
];

// BLAZE (demonizada): set completo de eblaze_* (incluye su propio
// stun y el disparo wshot para la forma demonizada).
global.player_eanims[? CHARACTER_BLAZE] =
[
        spr_eblaze_idle, //0
        spr_eblaze_walk, //1
        spr_eblaze_run, //2
        spr_eblaze_jump, //3
        spr_eblaze_fall, //4
        spr_eblaze_hurt, //5
        spr_eblaze_stun, //6
        spr_eblaze_lookup, //7
        spr_eblaze_lookdown, //8
        spr_eblaze_emotion1, //9
        spr_eblaze_emotion2, //10
        spr_eblaze_emotion3, //11
        spr_eblaze_jump, //12
        spr_eblaze_balancing, //13
        spr_eblaze_wshot, //14
        spr_eblaze_goon, //15
        spr_eblaze_zipline //16
];

// =====================================================================
//  SONIC: variantes dinamicas del golpe (tecla X). Cualquier sprite
//  llamado spr_sonic_attack2_tierra<N> o spr_sonic_attack2_aereo<N>
//  (N = 1, 2, 3...) cuenta como una variante mas: se detecta solo al
//  arrancar el juego, sin tocar este archivo. Para anadir una variante
//  nueva solo crea el sprite con ese nombre. El golpe elige una al azar
//  segun donde empezo (aire -> aereo<N>, tierra -> tierra<N>) y el
//  estado que viaja por red hace que el puppet del otro cliente
//  muestre exactamente la misma animacion.
// =====================================================================
global.sonicAtkTierra = [];
global.sonicAtkAire = [];

var _sonicScanN = 1;
while(_sonicScanN <= SONIC_ATK_TIERRA_MAX)
{
        var _sonicScanSpr = asset_get_index("spr_sonic_attack2_tierra" + string(_sonicScanN));
        
        if(is_undefined(_sonicScanSpr) || _sonicScanSpr < 0)
                break;
        
        array_push(global.sonicAtkTierra, _sonicScanSpr);
        _sonicScanN++;
}

_sonicScanN = 1;
while(_sonicScanN <= SONIC_ATK_AIRE_MAX)
{
        var _sonicScanSpr = asset_get_index("spr_sonic_attack2_aereo" + string(_sonicScanN));
        
        if(is_undefined(_sonicScanSpr) || _sonicScanSpr < 0)
                break;
        
        array_push(global.sonicAtkAire, _sonicScanSpr);
        _sonicScanN++;
}

// Failsafe (no deberia pasar nunca): que el golpe nunca quede sin sprite
if(array_length(global.sonicAtkTierra) == 0)
        array_push(global.sonicAtkTierra, spr_sonic_attack2_tierra1);

if(array_length(global.sonicAtkAire) == 0)
        array_push(global.sonicAtkAire, spr_sonic_attack2_aereo1);

function player_get(ind)
{
        switch(ind)
        {
                case CHARACTER_EXE:
                        return obj_exe;
                
                case CHARACTER_TAILS:
                        return obj_tails;
                        
                case CHARACTER_KNUX:
                        return obj_knux;
                        
                case CHARACTER_EGGMAN:
                        return obj_egg;
                        
                case CHARACTER_AMY:
                        return obj_amy;

                case CHARACTER_AMY_CANON:
                        return obj_amy_canon;

                case CHARACTER_SONIC:
                        return obj_sonic;
                        
                case CHARACTER_CREAM:
                        return obj_cream;
                        
                case CHARACTER_SALLY:
                        return obj_sally;

                case CHARACTER_SALLY_CANON:
                        return obj_sally_canon;

                case CHARACTER_VANILLA:
                        return obj_vanilla;

                case CHARACTER_METAL:
                        return obj_metal;

                case CHARACTER_AMELIA:
                        return obj_amelia;

                case CHARACTER_BLAZE:
                        return obj_blaze;
        }
}

// Personajes RESERVADOS (sistema de seguridad alternativo al token
// de Amy Canon). Devuelve true si ESTE cliente no puede usar al
// personaje ch (enum 1-based: CHARACTER_TAILS..CHARACTER_SALLY_CANON):
//   * Amy Canon: solo con el token local (amy_canon.token)
//   * Sally Canon: solo siendo operador del server
//     (global.isOperator, seteado por SERVER_OPERATOR_STATE)
//   * Sonic: libre para todos
// Quien no cumple NO ve el personaje al ciclar en la seleccion ni
// puede pedirlo (obj_lobby_icon / obj_lobby); y si igual lo pide con
// un cliente editado, el server se lo rechaza como si estuviera
// ocupado (states/CharSelect.c del betterserver).
function scr_char_locked(ch)
{
        // Amy Canon: solo token
        if(ch == CHARACTER_AMY_CANON && global.amyCanonToken == "")
                return true;

        // Sally Canon: solo operador
        if(ch == CHARACTER_SALLY_CANON && !global.isOperator)
                return true;

        // Vanilla: SOLO el token de Amy (amy_canon.token), igual
        // que Amy Canon. Ni operadores ni publica: exclusiva de
        // la duena del token. El server tambien la rechaza por si
        // solo (states/CharSelect.c): doble seguro.
        if(ch == CHARACTER_VANILLA && global.amyCanonToken == "")
                return true;

        return false;
}