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

/* v2.14 — Fleetway Amy ("The Disaster 2D Fleetway Amy" de GameJolt,
   rework de Amy inspirado en Sally.exe CN/FN). Otra Amy de la
   duena del token: DJ doble salto + ballesta + puños/patadas con
   sistema de revival. Sprites/port/moveset extraidos del data.win
   del mod (1.1.0). SIEMPRE AL FINAL de la lista. */
#macro CHARACTER_FLEETWAY_AMY (CHARACTER_TAILS+13)

/* v4.4 — ROUGE (sprites del TTB ya presentes en el proyecto: set
   completo spr_rouge_* + variante exe spr_erouge_*). Superviviente
   #15: planeo + agarre de pared de Knuckles (scr_rouge_special) +
   patada tierra/aire de Sally. JAMAS se demoniza (regla canonica,
   mismo parche del server que Amy Canon/Sonic/Vanilla): su caida
   es muerte directa. SIEMPRE AL FINAL de la lista. */
#macro CHARACTER_ROUGE (CHARACTER_TAILS+14)

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
        spr_amy_attack1_canon, //23 = HABILIDAD 2 (tecla X) en el aire: impulso de tarot (sprite nuevo de 2 frames)
        spr_none, //24 = hueco del AMY_CANON_HUG: ese estado va interceptado ANTES del array (Draw_76 y puppet Draw_72), nunca se lee
        spr_amy_light_speed_canon, //25 = v5.9 LIGHT DASH (Z en el aire): rayo por la cadena de anillos, rotado por angle
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
        spr_sally_fase2_canon_pt4, //21 = FASE 2 pt4: recuperacion
        spr_sally_fase2_attack_canon, //22 = DUELISTA: patada en tierra (2 patadas)
        spr_sally_spin_charger_canon //23 = DUELISTA: carga del spindash
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
// v2.10 — SPRITES DESCUADRADOS CORREGIDOS: llegaban cruzados desde el
// TTB. spr_metal_attack es Metal DE PIE arropado por un campo de
// chispas (el SPARK FIELD => tecla C) y spr_metal_attack2 es Metal en
// pose de embestida/vuelo dentro de una burbuja de energia con estela
// (el OVERDRIVE => tecla X). Antes cada habilidad mostraba el sprite
// de la otra: la electro se veia como overdrive y el overdrive como
// electro. El puppet de los demas clientes resuelve por estos mismos
// arrays, asi que se corrige solo en todas las pantallas.
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
        spr_metal_attack2, //14 = METAL_ATTACK: OVERDRIVE (tecla X): embestida dentro de la burbuja de energia
        spr_metal_attack, //15 = METAL_ELECTRO: SPARK FIELD (tecla C): campo de chispas a su alrededor
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

// Fleetway Amy (v2.14): 18-21 son las extras del mod original —
// 18 = pose DJ (doble salto, tecla A aérea), 19-21 = Amy CON la
// ballesta en la mano (cbamy idle/walk/run durante cbTimer).
global.player_anims[? CHARACTER_FLEETWAY_AMY] = 
[
        spr_amy_idle_fw, //0
        spr_amy_walk_fw, //1
        spr_amy_run_fw, //2
        spr_amy_jump_fw, //3
        spr_amy_fall_fw, //4
        spr_amy_hurt_fw, //5
        spr_amy_dead_fw, //6
        spr_amy_lookup_fw, //7
        spr_amy_lookdown_fw, //8
        spr_amy_emotion1_fw, //9
        spr_amy_emotion2_fw, //10
        spr_amy_emotion3_fw, //11
        spr_amy_jump_fw, //12 (spin)
        spr_amy_balancing_fw, //13
        spr_amy_attack1_fw, //14 = puño (tecla B)
        spr_amy_attack2_fw, //15 = patada (tecla B, alterna)
        spr_none, //16
        spr_amy_zipline_fw, //17
        spr_amy_dj_fw, //18 = DJ doble salto
        spr_cbamy_idle_fw, //19 = con ballesta
        spr_cbamy_walk_fw, //20 = con ballesta
        spr_cbamy_run_fw //21 = con ballesta
];

// Rouge (v4.4): 14 = ROUGE_ATTACK (patada AEREA, spr_rouge_attack1
// — la del vuelo), 15 = ROUGE_AIR_ATTACK (patada en TIERRA,
// spr_rouge_attack2 — el barrido bajo; mismo intercambio de slots
// que Knuckles), 16 = ROUGE_GLIDE, 17 = ROUGE_ZIPLINE,
// 18 = ROUGE_STUCK. El nombre del estado y del sprite quedan
// cruzados a proposito para respetar el layout de estados de
// Knuckles que viaja por red (Step_2 de obj_rouge).
global.player_anims[? CHARACTER_ROUGE] =
[
        spr_rouge_idle, //0
        spr_rouge_walk, //1
        spr_rouge_run, //2
        spr_rouge_jump, //3
        spr_rouge_fall, //4
        spr_rouge_hurt, //5
        spr_rouge_dead, //6
        spr_rouge_lookup, //7
        spr_rouge_lookdown, //8
        spr_rouge_emotion1, //9
        spr_rouge_emotion2, //10
        spr_rouge_emotion, //11
        spr_rouge_jump, //12 (spin)
        spr_rouge_balancing, //13
        spr_rouge_attack1, //14 = ROUGE_ATTACK: patada AEREA (tecla X en el aire)
        spr_rouge_attack2, //15 = ROUGE_AIR_ATTACK: patada en TIERRA (tecla X)
        spr_rouge_glide, //16 = ROUGE_GLIDE: planeo (Z aerea, patron Knux)
        spr_rouge_zipline, //17 = ROUGE_ZIPLINE
        spr_rouge_stuck, //18 = ROUGE_STUCK: agarre de pared (patron Knux)
        spr_rouge_hurt //19 = ROUGE_MORIBUNDA (v4.5): 1ra caida, tirada 6 s
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
        spr_amy_attack1_canon, //23 = HABILIDAD 2 (tecla X) en el aire: impulso de tarot (mismo sprite que la jugadora)
        spr_none, //24 = hueco del AMY_CANON_HUG (interceptado antes del array: nunca se lee)
        spr_amy_light_speed_canon, //25 = v5.9 LIGHT DASH (nunca ocurre demonizada —no puede recoger anillos—, pero el indice existe para que el array no quede corto)
];

// Fleetway Amy (demonizada): set eamy_fw del mod original. 18 = pose
// DJ, 19-21 = con ballesta (cbeamy). El stun usa el mismo sprite que
// la Amy demonizada vanilla pero en su versión Fleetway.
global.player_eanims[? CHARACTER_FLEETWAY_AMY] = 
[
        spr_eamy_idle_fw, //0
        spr_eamy_walk_fw, //1
        spr_eamy_run_fw, //2
        spr_eamy_jump_fw, //3
        spr_eamy_fall_fw, //4
        spr_eamy_hurt_fw, //5
        spr_eamy_stun_fw, //6
        spr_eamy_lookup_fw, //7
        spr_eamy_lookdown_fw, //8
        spr_eamy_emotion1_fw, //9
        spr_eamy_emotion2_fw, //10
        spr_eamy_emotion3_fw, //11
        spr_eamy_jump_fw, //12
        spr_eamy_balancing_fw, //13
        spr_eamy_attack1_fw, //14
        spr_eamy_attack2_fw, //15
        spr_none, //16
        spr_eamy_zipline_fw, //17
        spr_eamy_dj_fw, //18 = pose DJ (demonizada)
        spr_cbeamy_idle_fw, //19 = con ballesta
        spr_cbeamy_walk_fw, //20 = con ballesta
        spr_cbeamy_run_fw //21 = con ballesta
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
        spr_sally_fase2_canon_pt4, //21
        spr_sally_fase2_attack_canon, //22 = DUELISTA: patada en tierra
        spr_sally_spin_charger_canon //23 = DUELISTA: carga del spindash
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
// v2.10: mismo cruce corregido que la forma normal — 14 = burbuja del
// overdrive (X), 15 = campo de chispas de la electro (C).
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
        spr_emetal_attack2, //14 = OVERDRIVE (tecla X): burbuja de energia
        spr_emetal_attack, //15 = ELECTRO (tecla C): campo de chispas
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

// ROUGE (demonizada): JAMAS se demoniza (regla canonica, parche del
// server), asi que este bloque es SOLO DEFENSIVO — mismo criterio
// que el eanims de Sally Canon/Vanilla: si algun camino llegara a
// leerlo con revivalTimes >= 2, que pinte algo coherente. El set
// erouge_* existe completo (viene del TTB).
global.player_eanims[? CHARACTER_ROUGE] =
[
        spr_erouge_idle, //0
        spr_erouge_walk, //1
        spr_erouge_run, //2
        spr_erouge_jump, //3
        spr_erouge_fall, //4
        spr_erouge_hurt, //5
        spr_erouge_stun, //6
        spr_erouge_lookup, //7
        spr_erouge_lookdown, //8
        spr_erouge_emotion1, //9
        spr_erouge_emotion2, //10
        spr_erouge_emotion3, //11
        spr_erouge_jump, //12
        spr_erouge_balancing, //13
        spr_erouge_attack2, //14
        spr_erouge_attack1, //15
        spr_erouge_glide, //16
        spr_erouge_zipline, //17
        spr_erouge_stuck, //18
        spr_erouge_hurt //19 = ROUGE_MORIBUNDA defensivo
];

// =====================================================================
//  v11 (NEGAGEN) — FORMA 2: player_negaanims. Copias NEGA de los
//  sprites de CADA superviviente (spr_<char>nega_*: inversion pura de
//  spr_<char>_*), con el mismo criterio del canon Negagen (los
//  spr_amynega_* / spr_eggnega_* del build original). Las usa el
//  subdito NEGATIVO de Jinna (toque negativo): mismo personaje,
//  mismas animaciones y timing, colores invertidos.
//    1 normal (player_anims) / 2 NEGA (aqui) / 3 demonizada (eanims).
// =====================================================================
global.player_negaanims = ds_map_create();

//Tails
global.player_negaanims[? CHARACTER_TAILS] = 
[
        spr_tailsnega_idle, //0
        spr_tailsnega_walk, //1
        spr_tailsnega_run, //2
        spr_tailsnega_jump, //3
        spr_tailsnega_fall, //4
        spr_tailsnega_hurt, //5
        spr_tailsnega_dead, //6
        spr_tailsnega_lookup, //7
        spr_tailsnega_lookdown, //8
        spr_tailsnega_emotion1, //9
        spr_tailsnega_emotion2, //10
        spr_tailsnega_emotion3, //11
        spr_tailsnega_jump, //12
        spr_tailsnega_balancing, //13
        spr_tailsnega_fly, //14
        spr_tailsnega_attack1, //15
        spr_tailsnega_zipline //16
];

//Knux
global.player_negaanims[? CHARACTER_KNUX] = 
[
        spr_knuxnega_idle, //0
        spr_knuxnega_walk, //1
        spr_knuxnega_run, //2
        spr_knuxnega_jump, //3
        spr_knuxnega_fall, //4
        spr_knuxnega_hurt, //5
        spr_knuxnega_dead, //6
        spr_knuxnega_lookup, //7
        spr_knuxnega_lookdown, //8
        spr_knuxnega_emotion1, //9
        spr_knuxnega_emotion2, //10
        spr_knuxnega_emotion3, //11
        spr_knuxnega_jump, //12
        spr_knuxnega_balancing, //13
        spr_knuxnega_attack2, //14
        spr_knuxnega_attack1, //15
        spr_knuxnega_glide, //16
        spr_knuxnega_zipline, //17
        spr_knuxnega_stuck //18
];

//Egg
global.player_negaanims[? CHARACTER_EGGMAN] = 
[
        spr_eggnega_idle, //0
        spr_eggnega_walk, //1
        spr_eggnega_run, //2
        spr_eggnega_jump, //3
        spr_eggnega_fall, //4
        spr_eggnega_hurt, //5
        spr_eggnega_dead, //6
        spr_eggnega_lookup, //7
        spr_eggnega_lookdown, //8
        spr_eggnega_emotion1, //9
        spr_eggnega_emotion2, //10
        spr_eggnega_emotion3, //11
        spr_eggnega_jump, //12
        spr_eggnega_balancing, //13
        spr_eggnega_djump, //14
        spr_eggnega_zipline //15
];

//Amy
global.player_negaanims[? CHARACTER_AMY] = 
[
        spr_amynega_idle, //0
        spr_amynega_walk, //1
        spr_amynega_run, //2
        spr_amynega_jump, //3
        spr_amynega_fall, //4
        spr_amynega_hurt, //5
        spr_amynega_dead, //6
        spr_amynega_lookup, //7
        spr_amynega_lookdown, //8
        spr_amynega_emotion1, //9
        spr_amynega_emotion2, //10
        spr_amynega_emotion3, //11
        spr_amynega_jump, //12
        spr_amynega_balancing, //13
        spr_amynega_attack1, //14
        spr_amynega_attack2, //15
        spr_none, //16
        spr_amynega_zipline //17
];

//Amy Canon
global.player_negaanims[? CHARACTER_AMY_CANON] = 
[
        spr_amynega_idle_canon, //0
        spr_amynega_walk_canon, //1
        spr_amynega_run_canon, //2
        spr_amynega_jump_canon, //3
        spr_amynega_fall_canon, //4
        spr_amynega_hurt_canon, //5
        spr_amynega_dead_canon, //6
        spr_amynega_lookup_canon, //7
        spr_amynega_lookdown_canon, //8
        spr_amynega_emotion1_canon, //9
        spr_amynega_emotion2_canon, //10
        spr_amynega_emotion3_canon, //11
        spr_amynega_jump_canon, //12
        spr_amynega_balancing, //13
        spr_amynega_attack1_canon, //14
        spr_amynega_attack2_canon, //15
        spr_none, //16
        spr_amynega_zipline_canon, //17
        spr_amynega_attack3_canon_, //18
        spr_amynega_capture_canon, //19
        spr_amynega_capture_canon_left, //20
        spr_amynega_capture_canon_right, //21
        spr_amynega_tarot_float, //22
        spr_amynega_attack1_canon, //23
        spr_none, //24
        spr_amynega_light_speed_canon //25
];

//Sonic
global.player_negaanims[? CHARACTER_SONIC] = 
[
        spr_sonicnega_idle, //0
        spr_sonicnega_walk, //1
        spr_sonicnega_run, //2
        spr_sonicnega_jump, //3
        spr_sonicnega_fall, //4
        spr_sonicnega_hurt, //5
        spr_sonicnega_dead, //6
        spr_sonicnega_lookup, //7
        spr_sonicnega_lookdown, //8
        spr_sonicnega_emotion1, //9
        spr_sonicnega_emotion2, //10
        spr_sonicnega_emotion3, //11
        spr_sonicnega_jump, //12
        spr_sonicnega_balancing, //13
        spr_sonicnega_attack2_tierra1, //14
        spr_sonicnega_spin_charger, //15
        spr_none, //16
        spr_sonicnega_zipline, //17
        spr_sonicnega_nervios_de_acero_Idle, //18
        spr_sonicnega_nervios_de_acero_finish //19
];

//Cream
global.player_negaanims[? CHARACTER_CREAM] = 
[
        spr_creamnega_idle, //0
        spr_creamnega_walk, //1
        spr_creamnega_run, //2
        spr_creamnega_jump, //3
        spr_creamnega_fall, //4
        spr_creamnega_hurt, //5
        spr_creamnega_dead, //6
        spr_creamnega_lookup, //7
        spr_creamnega_lookdown, //8
        spr_creamnega_emotion1, //9
        spr_creamnega_emotion2, //10
        spr_creamnega_emotion3, //11
        spr_creamnega_jump, //12
        spr_creamnega_balancing, //13
        spr_creamnega_fly, //14
        spr_creamnega_srings, //15
        spr_creamnega_zipline //16
];

//Sally
global.player_negaanims[? CHARACTER_SALLY] = 
[
        spr_sallynega_idle, //0
        spr_sallynega_walk, //1
        spr_sallynega_run, //2
        spr_sallynega_jump, //3
        spr_sallynega_fall, //4
        spr_sallynega_hurt, //5
        spr_sallynega_dead, //6
        spr_sallynega_lookup, //7
        spr_sallynega_lookdown, //8
        spr_sallynega_emotion1, //9
        spr_sallynega_emotion2, //10
        spr_sallynega_emotion3, //11
        spr_sallynega_jump, //12
        spr_sallynega_balancing, //13
        spr_sallynega_attack, //14
        spr_sallynega_slide, //15
        spr_none, //16
        spr_sallynega_zipline //17
];

//Sally Canon
global.player_negaanims[? CHARACTER_SALLY_CANON] = 
[
        spr_sallynega_idle_canon, //0
        spr_sallynega_walk_canon, //1
        spr_sallynega_run_canon, //2
        spr_sallynega_jump_canon, //3
        spr_sallynega_fall_canon, //4
        spr_sallynega_hurt_canon, //5
        spr_sallynega_dead_canon, //6
        spr_sallynega_lookup_canon, //7
        spr_sallynega_lookdown_canon, //8
        spr_sallynega_emotion1_canon, //9
        spr_sallynega_emotion2_canon, //10
        spr_sallynega_emotion3_canon, //11
        spr_sallynega_jump_canon, //12
        spr_sallynega_balancing_canon, //13
        spr_sallynega_attack_canon, //14
        spr_sallynega_slide_canon, //15
        spr_none, //16
        spr_sallynega_zipline_canon, //17
        spr_sallynega_fase2_canon_pt1, //18
        spr_sallynega_fase2_canon_pt2, //19
        spr_sallynega_fase2_canon_pt3, //20
        spr_sallynega_fase2_canon_pt4, //21
        spr_sallynega_fase2_attack_canon, //22
        spr_sallynega_spin_charger_canon //23
];

//Vanilla
global.player_negaanims[? CHARACTER_VANILLA] = 
[
        spr_vanillanega_idle, //0
        spr_vanillanega_walk, //1
        spr_vanillanega_run, //2
        spr_vanillanega_jump, //3
        spr_vanillanega_fall, //4
        spr_vanillanega_hurt, //5
        spr_vanillanega_dead, //6
        spr_vanillanega_lookup, //7
        spr_vanillanega_lookdown, //8
        spr_vanillanega_emotion1, //9
        spr_vanillanega_emotion2, //10
        spr_vanillanega_emotion3, //11
        spr_vanillanega_jump, //12
        spr_vanillanega_balancing, //13
        spr_vanillanega_fly, //14
        spr_vanillanega_srings, //15
        spr_vanillanega_zipline, //16
        spr_vanillanega_float_run, //17
        spr_vanillanega_paciencia, //18
        spr_vanillanega_paciencia_agotada //19
];

//Metal
global.player_negaanims[? CHARACTER_METAL] = 
[
        spr_metalnega_idle, //0
        spr_metalnega_walk, //1
        spr_metalnega_run, //2
        spr_metalnega_jump, //3
        spr_metalnega_fall, //4
        spr_metalnega_hurt, //5
        spr_metalnega_dead, //6
        spr_metalnega_lookup, //7
        spr_metalnega_lookdown, //8
        spr_metalnega_emotion1, //9
        spr_metalnega_emotion2, //10
        spr_metalnega_emotion3, //11
        spr_metalnega_jump, //12
        spr_metalnega_balancing, //13
        spr_metalnega_attack2, //14
        spr_metalnega_attack, //15
        spr_metalnega_zipline //16
];

//Amelia
global.player_negaanims[? CHARACTER_AMELIA] = 
[
        spr_amelianega_idle, //0
        spr_amelianega_walk, //1
        spr_amelianega_run, //2
        spr_amelianega_jump, //3
        spr_amelianega_fall, //4
        spr_amelianega_hurt, //5
        spr_amelianega_dead, //6
        spr_amelianega_lookup, //7
        spr_amelianega_lookdown, //8
        spr_amelianega_emotion1, //9
        spr_amelianega_emotion2, //10
        spr_amelianega_emotion3, //11
        spr_amelianega_jump, //12
        spr_amelianega_balancing, //13
        spr_amelianega_fly, //14
        spr_amelianega_spindash, //15
        spr_amelianega_zipline //16
];

//Blaze
global.player_negaanims[? CHARACTER_BLAZE] = 
[
        spr_blazenega_idle, //0
        spr_blazenega_walk, //1
        spr_blazenega_run, //2
        spr_blazenega_jump, //3
        spr_blazenega_fall, //4
        spr_blazenega_hurt, //5
        spr_blazenega_dead, //6
        spr_blazenega_lookup, //7
        spr_blazenega_lookdown, //8
        spr_blazenega_emotion1, //9
        spr_blazenega_emotion2, //10
        spr_blazenega_emotion3, //11
        spr_blazenega_jump, //12
        spr_blazenega_balancing, //13
        spr_blazenega_go, //14
        spr_blazenega_goon, //15
        spr_blazenega_zipline //16
];

//Fleetway Amy
global.player_negaanims[? CHARACTER_FLEETWAY_AMY] = 
[
        spr_amynega_idle_fw, //0
        spr_amynega_walk_fw, //1
        spr_amynega_run_fw, //2
        spr_amynega_jump_fw, //3
        spr_amynega_fall_fw, //4
        spr_amynega_hurt_fw, //5
        spr_amynega_dead_fw, //6
        spr_amynega_lookup_fw, //7
        spr_amynega_lookdown_fw, //8
        spr_amynega_emotion1_fw, //9
        spr_amynega_emotion2_fw, //10
        spr_amynega_emotion3_fw, //11
        spr_amynega_jump_fw, //12
        spr_amynega_balancing_fw, //13
        spr_amynega_attack1_fw, //14
        spr_amynega_attack2_fw, //15
        spr_none, //16
        spr_amynega_zipline_fw, //17
        spr_amynega_dj_fw, //18
        spr_cbamynega_idle_fw, //19
        spr_cbamynega_walk_fw, //20
        spr_cbamynega_run_fw //21
];

//Rouge
global.player_negaanims[? CHARACTER_ROUGE] = 
[
        spr_rougenega_idle, //0
        spr_rougenega_walk, //1
        spr_rougenega_run, //2
        spr_rougenega_jump, //3
        spr_rougenega_fall, //4
        spr_rougenega_hurt, //5
        spr_rougenega_dead, //6
        spr_rougenega_lookup, //7
        spr_rougenega_lookdown, //8
        spr_rougenega_emotion1, //9
        spr_rougenega_emotion2, //10
        spr_rougenega_emotion, //11
        spr_rougenega_jump, //12
        spr_rougenega_balancing, //13
        spr_rougenega_attack1, //14
        spr_rougenega_attack2, //15
        spr_rougenega_glide, //16
        spr_rougenega_zipline, //17
        spr_rougenega_stuck, //18
        spr_rougenega_hurt //19
];

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

// v11 (NEGAGEN): variantes NEGA del golpe de Sonic (mismo escaneo por
// nombre, sobre las copias nega spr_sonicnega_attack2_*): las usa el
// subdito NEGATIVO para que el golpe salga con SU look invertido.
global.sonicAtkTierraNega = [];
global.sonicAtkAireNega = [];

_sonicScanN = 1;
while(_sonicScanN <= SONIC_ATK_TIERRA_MAX)
{
        var _sonicScanSpr = asset_get_index("spr_sonicnega_attack2_tierra" + string(_sonicScanN));

        if(is_undefined(_sonicScanSpr) || _sonicScanSpr < 0)
                break;

        array_push(global.sonicAtkTierraNega, _sonicScanSpr);
        _sonicScanN++;
}

_sonicScanN = 1;
while(_sonicScanN <= SONIC_ATK_AIRE_MAX)
{
        var _sonicScanSpr = asset_get_index("spr_sonicnega_attack2_aereo" + string(_sonicScanN));

        if(is_undefined(_sonicScanSpr) || _sonicScanSpr < 0)
                break;

        array_push(global.sonicAtkAireNega, _sonicScanSpr);
        _sonicScanN++;
}

if(array_length(global.sonicAtkTierraNega) == 0)
        array_push(global.sonicAtkTierraNega, spr_sonicnega_attack2_tierra1);

if(array_length(global.sonicAtkAireNega) == 0)
        array_push(global.sonicAtkAireNega, spr_sonicnega_attack2_aereo1);



// >>>>>>> MUELLES: inicio (bloque generado con Suite_TD2D.html) >>>>>>
// Caida "tipo trampolin" por sprite, para el case FALL del Draw_76:
//   [sprite, frameSubida, nFramesSubida, frameBajada, nFramesBajada, velBucle]
//   nFrames = 1 -> pose fija · nFrames > 1 -> bucle de esos frames a velBucle.
//   Subida = mientras asciende (yspd < 0) · bajada = el resto (yspd >= 0).
//   En el personaje:  case FALL:  scr_fall_anim();  (una sola linea).
//   Un sprite que NO este en la lista usa la caida clasica de siempre
//   (fallback seguro: ni errores ni cambios para personajes sin configurar).
global.fallAnims = [
        [spr_metal_fall,        0, 1, 1, 1, 0.15], // Metal Sonic
        [spr_emetal_fall,       0, 1, 1, 1, 0.15], // Metal Sonic (demonizado)
        [spr_blaze_fall,        0, 1, 1, 1, 0.15], // Blaze
        [spr_eblaze_fall,       0, 1, 1, 1, 0.15], // Blaze (demonizada)
        [spr_sally_fall_canon,  0, 1, 4, 1, 0.15], // SALLY_CANON
        [spr_amelia_fall,       0, 1, 1, 1, 0.15], // AMELIA
        [spr_eamelia_fall,      0, 1, 1, 1, 0.15], // AMELIA (demonizado)
        [spr_metalnega_fall,    0, 1, 1, 1, 0.15], // Metal Sonic (nega)
        [spr_blazenega_fall,     0, 1, 1, 1, 0.15], // Blaze (nega)
        [spr_sallynega_fall_canon, 0, 1, 4, 1, 0.15], // SALLY_CANON (nega)
        [spr_amelianega_fall,    0, 1, 1, 1, 0.15]  // AMELIA (nega)
];

// La llama el case FALL del Draw_76 del personaje: busca el sprite en
// global.fallAnims y aplica su configuracion; si no esta, caida clasica.
function scr_fall_anim()
{
        for(var i = 0; i < array_length(global.fallAnims); i++)
        {
                var cfg = global.fallAnims[i];

                if(cfg[0] != sprite_index)
                        continue;

                var rising = yspd < 0;
                var start  = rising ? cfg[1] : cfg[3];
                var frames = rising ? cfg[2] : cfg[4];

                if(frames <= 1)
                {
                        image_speed = 0;
                        image_index = start;
                }
                else
                {
                        image_speed = cfg[5];

                        if(image_index < start || image_index >= start + frames)
                                image_index = start;
                }

                return;
        }

        // Fuera de la lista: caida clasica (bucle que acelera al caer)
        image_speed = 0.15 + min(abs(yspd), 12) * 0.02;
}
// <<<<<<< MUELLES: fin <<<<<<<

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

                case CHARACTER_FLEETWAY_AMY:
                        return obj_amy_fleetway;

                case CHARACTER_ROUGE:
                        return obj_rouge;
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

        // v6.2 (D.I.B.): ROUGE INABILITADA — su set de sprites no
        // convencio a la duena ("estan mal"). Bloqueo total para
        // todos (ni token ni operador la desbloquean) hasta que
        // entre arte nuevo. Se salta al ciclar, no se ve su retrato
        // y el server la rechaza por si solo (CharSelect.c): mismo
        // doble seguro que Vanilla.
        if(ch == CHARACTER_ROUGE)
                return true;

        // v3 (D.I.B.): Fleetway Amy PASA A SER PUBLICA (pedido de la
        // duena: "la amy fw sera publica"). Salio del token — ahora
        // es un personaje normal del carrusel para todos. Su pasiva
        // de torre se nerfeo a cambio (ver scr_player_hurt: bloqueo
        // solo con daño real + porcentaje que cae 10% por bloqueo).

        return false;
}