// =====================================================================
//  KRIS (Deltarune) — v1. Moveset completo sobre la base Tails:
//
//   * Z EN EL AIRE = DOBLE SALTO (v2, pasiva de la duena: "Su pasiva
//     cris tendra un doble salto (tipo eggman pero tendra enfriamiento").
//     Patron JETPACK de Eggman: solo mientras SUBE de un salto
//     (isJumping), mismo impulso (-8) y con recarga (icono del HUD con
//     el jetpack de Eggman de placeholder). Kris sigue SIN volar ni
//     planear (la regla de "el no vuela" queda intacta: es UN salto
//     extra por recarga, nada de vuelo Tails ni planeo Knux).
//     Su "slot glide" lo ocupa el ESCUDO (tecla C, tierra — scr_parry).
//
//   * X = ESPADA (patron puno de Knuckles / patada de Rouge): en
//     tierra un tajo y en el aire el ataque de DOS fases:
//       fase 1 (estado 40): spr_kris_attack1_air1 (4 frames)
//       fase 2 (estado 41): spr_kris_attack1_air2 (8 frames) con
//         hitbox +50% (pad del puppet) e I-FRAMES mientras dura
//         (guard en scr_player_hurt).
//     La fase se fija al iniciar (patron Sonic: si empezo en el aire
//     sigue contando como aire aunque aterrice). Stun de 3 s al bando
//     EXE por contacto (lo aplica el cliente de la victima con el bit
//     PLAYER_ATTACKING de obj_netclient/Step_2). Recarga: la del puno
//     de Knuckles (14,75 s).
//
//   * 1ra caida -> MORIBUNDA (patron Rouge v4.5): 6 s tirado, inmune
//     a todo, se levanta solo con 40 de vida. El server JAMAS se
//     entera de esa caida. La activa scr_player_instakill.
//   * 2da caida -> MUERTE REAL directa: Kris JAMAS se demoniza ni se
//     convierte en subdito negativo (guards del server + de
//     scr_jinna_negatouch) y JAMAS es absorbible por Jinna (la trampa
//     es SIEMPRE kind 0: dano + TP normal).
// =====================================================================

// ---- stats (base Tails: el placeholder de la duena) ----
#macro KRIS_MAXSPEED 11
#macro KRIS_ACC 0.046875

// ---- espada ----
#macro KRIS_ATTACK_RECHARGE (60 * 4.0) // misma cadencia del puno de Knux
#macro KRIS_ATK_GROUND_SPD 0.4           // tajo tierra: 4 frames
#macro KRIS_ATK_AIR1_SPD 0.4             // air1: 4 frames
#macro KRIS_ATK_AIR2_SPD 0.5             // air2: 8 frames
#macro KRIS_AIR2_HITBOX 0.7              // +50% del ancho del bbox (pad del puppet)

// ---- escudo (patron parry) ----
#macro KRIS_BLOCK_EXITO_PER 4.5  // frames de juego por frame del sprite de exito
#macro KRIS_BLOCK_VISION -8      // margen frontal: dx*face >= esto cuenta como "de frente"

// ---- doble salto (v2, pasiva: patron jetpack de Eggman) ----
#macro KRIS_DJUMP_RECHARGE (60 * 8) // mismo enfriamiento del jetpack de Eggman
#macro KRIS_DJUMP_YSPEED -8         // impulso identico al del jetpack

// ---- ralentizacion post-stun de la espada (v2) ----
#macro KRIS_SLOW_TIME 4             // segundos de slow que arrancan al EXPIRAR el stun de 3 s

// ---- LOVE (v46): nivel de violencia de Kris ----
#macro KRIS_LV_MAX 20           // tope del LV: +100% de stun (2x)
#macro KRIS_LV_STUN_PCT 0.05     // +5% del stun base por LV (LV 10 = +50%, LV 20 = +100%)

// ---- v96 (ritmo del LOVE): cuantos impactos cuenta cada golpe ----
// Pedido de la duena: "esta vez aumentaremos a 200% lo del aumento de
// nivel en lms y 50% en modo normal" — el Show Fuerte (LMS) acumula
// KRIS_LV_XP_LMS impactos por golpe (+200% = el TRIPLE de rapido) y
// el modo normal KRIS_LV_XP_NORMAL (+50% = 1.5). LV 20 = 56 impactos:
// 19 golpes en LMS / 38 en normal (antes 28 / 56). Tuneable aqui.
// v97: la perilla quedo en 5 en el repo (LV 20 en 12 golpes de LMS) y
// el MULTI-SIGNAL FLUSH de scr_kris_love_event la vuelve LIBRE: ya NO
// importa el espaciado de umbrales — la advertencia "no pasar de 3 por
// golpe" del v96 queda OBSOLETA. Tunear a gusto.
#macro KRIS_LV_XP_NORMAL 5
#macro KRIS_LV_XP_LMS 5

// ---- v95 (LOVE = CRECIMIENTO): la vida de Kris escala con su LV ----
// Pedido de la duena: "cada que suba de nivel su vida max aumente 20 de
// vida max y el se cura esa misma cantidad por cada que sube de nivel".
// LV 1 = 100 (canonico de siempre); LV 20 = 100 + 19*20 = 480. La fuente
// unica de verdad del HUD y el netcode sigue siendo scr_player_maxhp
// (el clamp del CLIENT_PLAYER_DATA y TODOS los gates de cura ya la
// consultan — con esto quedan alineados solos). El anti-cheat del server
// (Game.c, cap por personaje) se sube a 480 en esta misma version.
#macro KRIS_LV_BASE_HP 100
#macro KRIS_LV_HP_BONUS 20

// ---- v95 (CONSECUENCIAS del LV 20): el asesino se vuelve vulnerable ----
// "al llegar al nv 20 (si es que llega) el asesino le aparecera una barra
// de vida el dano de kris seria de 35 por golpe a nv 20 (el solo puede
// danarlo al nv 20)". La vida del EXE vive en global.exeHpPool (un
// global, no en el player del exe: asi vale igual para CUALQUIER
// variante de asesino — Original/Exeller/Exetior/Chaos/Jinna/Metal Amy —
// sin tocar los 6 Create). Lo resetea el Create de obj_level (una por
// ronda). LA AUTORIDAD es el cliente del EXE (patron victima-autoridad
// de TODO el juego): su espada la cuenta el krisLvNet espejado del
// puppet de Kris en SU pantalla (senal silenciosa v46 — no falsificable
// desde el cliente de Kris). Debajo de LV 20 el golpe sigue siendo el
// stun de siempre, SIN dano al pool. A 0 (v98): la partida TERMINA con
// la victoria de los supervivientes vivos no corrompidos (ver
// scr_kris_exe_pool_hit) — ya NO hay refill ni pelea a repeticion.
#macro KRIS_EXE_DAMAGE 35        // dano por cuchillazo a LV 20 (pedido)
#macro KRIS_EXE_MAXHP 350        // vida total del asesino: 10 golpes (tuneable)
#macro KRIS_EXE_DOWN_SEC 10      // knockdown al llegar a 0 (segundos)

// ---- v98 (P4, pedido de la duena: «el enfriamiento general del golpe
// de espada se reducira 2 seg en lms 4 seg»): la espada recarga MAS
// RAPIDO cuando aprieta el final — -2 s mientras el Show Fuerte (LMS)
// este activo y -4 s ADICIONALES a LV 20 (el duelo final). Tabla:
//   normal      10,75 s (645 f, el de siempre)
//   LMS         8,75 s (525 f, -2 s)
//   LV 20+LMS   4,75 s (285 f, -2 s -4 s)
// A LV 20 el LMS siempre esta activo (v98: el server lo dispara solo),
// asi que el escalon completo se pisa una vez ahi. Perillas tuneables
// aqui (KRIS_SWORD_RECHARGE_MIN es el suelo: nunca por debajo de 2 s).
#macro KRIS_SWORD_CUT_LMS (60 * 2)   // recorte del enfriamiento con el LMS activo
#macro KRIS_SWORD_CUT_LV20 (60 * 4)  // recorte ADICIONAL estando ya a LV 20
#macro KRIS_SWORD_RECHARGE_MIN (60 * 2) // suelo del enfriamiento (2 s)

// Recarga REAL de la espada segun el estado de la ronda (v98 P4). La
// usan el input del golpe (scr_kris_special) y el icono del HUD
// (obj_playerui/Draw_64): el relleno siempre cuadra con el maximo
// vigente. Un cooldown ya en marcha NO se recorta (la mejora entra con
// el siguiente golpe).
function scr_kris_sword_recharge()
{
        var _cd = KRIS_ATTACK_RECHARGE;

        if(global.lmsActive)
                _cd -= KRIS_SWORD_CUT_LMS;

        if(instance_exists(global.player) && variable_instance_exists(global.player.id, "krisLv")
        && global.player.krisLv >= KRIS_LV_MAX)
                _cd -= KRIS_SWORD_CUT_LV20;

        return max(_cd, KRIS_SWORD_RECHARGE_MIN);
}

// ---- moribunda (patron Rouge v4.5, mismos numeros) ----
#macro KRIS_MORIBUNDA_TIME (60 * 6)  // tirado en el suelo
#macro KRIS_MORIBUNDA_HEAL 100        // se levanta con poca vida
#macro KRIS_MORIBUNDA_INVULN (60 * 3)
#macro KRIS_MORIBUNDA_LEVITATE -0.35 // flota solo si cayo a un hoyo

// ---- estados de red (patron Rouge + dinamicos de Sonic) ----
#macro KRIS_ZIPLINE BALANCING+4   // 17: tirolina (patron Knux)
#macro KRIS_STUCK BALANCING+5     // 18: atascado (sin uso: sin agarre de pared)
#macro KRIS_MORIBUNDA BALANCING+6 // 19: 1ra caida tirada (mismo slot que Rouge/Vanilla)
#macro KRIS_ATK_TIERRA 20         // tajo en tierra (rango 20-39, patron Sonic)
#macro KRIS_ATK_AIRE 40           // air1 = 40, air2 = 41 (rango 40-59, patron Sonic)

function scr_kris_special()
{
        // ---------------- MORIBUNDA (1ra caida, patron Rouge) ----------------
        if(moribundaState > 0)
        {
                gspd = 0;
                xspd = 0;

                // mismo mini-fix de Vanilla/Rouge: debilitado EN EL AIRE cae al
                // suelo en vez de quedarse flotando; la levitacion queda SOLO
                // para el hoyo de verdad (sin terreno en la columna de abajo)
                if(isGrounded)
                        yspd = 0;
                else if(!collision_line(x, y, x, room_height + 64, obj_floor_parent, true, true))
                        yspd = KRIS_MORIBUNDA_LEVITATE;
                else
                        yspd = min(yspd + yAccel, maxYSpeed);

                isJumping = false;
                isSpinning = false;
                isAttacking = false;
                krisAtkVariant = 0;

                // el escudo no sobrevive a la caida (mismo trato que el parry
                // recibe del stun: cuenta como fallo y entra en recarga)
                if(parryState > 0 && parryState != 4)
                {
                        if(parryCooldown <= 0)
                                scr_parry_apply_cd(SONIC_PARRY_CD_FAIL);

                        parryState = 0;
                        parryActive = false;
                        parryLateSignal = 0;
                }

                if(isStuck)
                {
                        canMove = true;
                        isStuck = false;
                }

                moribundaTimer--;

                if(moribundaTimer <= 0)
                {
                        moribundaState = 0;
                        hp = KRIS_MORIBUNDA_HEAL;
                        hurttime = KRIS_MORIBUNDA_INVULN;
                        isHurt = false;
                        attackTimer = 0; // misericordia: espada lista al levantarse
                }

                return;
        }

        // anillo rojo / esconderse: sin espada (patron Knux/Rouge)
        if(redRingTimer > 0)
        {
                if(attackTimer <= 2)
                        attackTimer = 2;

                // v2: sin doble salto tampoco (patron Eggman: recarga pisada)
                if(djumpRecharge <= 2)
                        djumpRecharge = 2;

                isAttacking = false;
                krisAtkVariant = 0;
        }

        if(isHiding)
        {
                if(attackTimer <= 60 * 2)
                        attackTimer = 60 * 2;

                // v2: sin doble salto tampoco (patron Eggman)
                if(djumpRecharge <= 60 * 2)
                        djumpRecharge = 60 * 2;

                isAttacking = false;
                krisAtkVariant = 0;
        }

        // ---------------- Z EN EL AIRE: DOBLE SALTO (v2, patron Eggman) ----------------
        // Kris NO vuela ni planea (regla intacta): es UN salto extra en
        // el aire, patron JETPACK de Eggman — solo mientras sube de un
        // salto (isJumping; caerse de una plataforma NO cuenta), misma
        // fuerza (-8) y con enfriamiento (KRIS_DJUMP_RECHARGE). El icono
        // del HUD usa el jetpack de Eggman de placeholder.
        if(global.playerControls && keyboard_check_pressed(global.KeyA) && isJumping && djumpRecharge == 0)
        {
                isJumping = false;
                yspd = KRIS_DJUMP_YSPEED;

                audio_play_sound(snd_jump, 0, false);
                net_sound_emit(snd_jump);

                djumpRecharge = KRIS_DJUMP_RECHARGE;
        }

        // ---------------- ESPADA (tecla X) ----------------
        if(global.playerControls && keyboard_check_pressed(global.KeyB) && attackTimer <= 0 && !isAttacking)
        {
                if(keyboard_check(global.KeyLeft))
                        image_xscale = -1;
                else if(keyboard_check(global.KeyRight))
                        image_xscale = 1;

                image_index = 0;
                attackTimer = scr_kris_sword_recharge(); // v98 (P4): 10,75 s base, -2 s en LMS, -4 s mas a LV 20
                isAttacking = true;

                // fase fija al iniciar (patron Sonic): 1 = tierra, 2 = air1.
                // La subida a air2 la decide el bloque de abajo con la fase 1
                // terminada (ataque aereo de DOS fases, no combo de input).
                krisAtkVariant = isGrounded ? 1 : 2;

                audio_play_sound(snd_dash, 0, false);
                net_sound_emit(snd_dash);
        }

        // FASE 2 AEREA: al terminar air1 salta directamente a air2 (el
        // tajo grande: hitbox +50% del puppet e i-frames). Solo si sigue
        // en el aire: aterrizar a mitad cierra el ataque con normalidad.
        // (El Draw_76 del estado 40 NO apaga isAttacking en su ultimo frame
        // a proposito: este bloque es quien sabe si hay fase 2 que correr.)
        if(isAttacking && krisAtkVariant == 2)
        {
                if(!isGrounded && sprite_index == spr_kris_attack1_air1 && image_index >= image_number - 1)
                {
                        krisAtkVariant = 3;
                        image_index = 0;
                }
                else if(isGrounded && image_index >= image_number - 1)
                        isAttacking = false;
        }

        if(isAttacking)
        {
                // empujoncito del tajo (patron puno de Knux / patada de Rouge)
                gspd = 0;
                xspd = image_xscale * (isGrounded ? .5 : 2);
        }
        else if(krisAtkVariant != 0)
                krisAtkVariant = 0;

        if(attackTimer > 0)
                attackTimer--;

        // v2: recarga del doble salto (el HUD la pinta como el jetpack)
        if(djumpRecharge > 0)
                djumpRecharge--;
}

// =====================================================================
//  HELPERS DEL ESCUDO (los usa scr_parry.gml). El escudo de Kris es
//  DIRECCIONAL: solo bloquea lo que viene DE FRENTE o del aire hacia
//  donde mira ("si esta al frente de el o en orientacion aerea a donde
//  el mira; si el ataque viene de espaldas no lo bloqueara").
// =====================================================================

// ¿el punto/instancia _from esta en la vision frontal de _target
// (el Kris que bloquea)?Margen KRIS_BLOCK_VISION para cubrir "justo
// encima" (un ataque aereo que cae sobre su cabeza si cuenta).
function scr_kris_block_front(_target, _from)
{
        var _dx = _from.x - _target.x;
        var _face = _target.image_xscale >= 0 ? 1 : -1;
        return _dx * _face >= KRIS_BLOCK_VISION;
}

// ¿el atacante _from estaba EN EL AIRE? (elige la animacion de exito:
// spr_kris_block_success_air vs _ground). Puppets: por su estado de
// red (JUMP/FALL); otras fuentes (laser, etc.): por altura relativa.
function scr_kris_block_attacker_air(_from, _target)
{
        if(variable_instance_exists(_from.id, "state"))
                return (_from.state == JUMP || _from.state == FALL);

        return _from.y < _target.y - 10;
}

// =====================================================================
//  v46 - LOVE (nivel de violencia de Kris, Undertale/Deltarune)
//
//  Pedido de la duena: "el lv debe aparecerle por encima de su barra
//  de vida; mientras mas cuchillazos acierte con la habilidad o
//  bloquee, sube su nivel de violencia, y mientras mas nivel el stun
//  durara mas (lv 10 = +50%, lv 20 = +100%)".
//
//  Fuentes de progreso (1 impacto cada una):
//   * CUCHILLAZO ACERTADO: cada stun que la espada le provoca al bando
//     EXE en la pantalla de la victima. Lo cuenta el propio cliente de
//     Kris con el CLIENT_PLAYER_HURT que llega con pid == su nid (lo
//     emite el cliente de la victima, que es la autoridad: esa senal
//     NO se puede falsificar desde el cliente de Kris).
//   * BLOQUEO EXITOSO del escudo: todos los caminos de exito pasan por
//     scr_parry_success_now (melee, laser devuelto, anillo negro y el
//     ting del aliado).
//  El LV sube con la LISTA de scr_kris_love_lv, se pinta sobre la
//  barra de vida (obj_kris/Draw_64) y alarga el stun de la espada
//  +5% por LV en las pantallas ajenas (obj_player_puppet/Step_0):
//  LV 10 = +50%, LV 20 = +100% (tope). La victima sigue siendo la
//  autoridad de siempre y el slow post-stun queda fijo en 3 s.
//  La subida de LV viaja por la SENAL SILENCIOSA net_sound_emit
//  (snd_none) - 0 frames, nada suena; Exeller ya emite snd_none por
//  red hoy (choose de su clon), el canal esta probado. Cero paquetes
//  nuevos, cero server (regla 7 intacta).
// =====================================================================

// La LISTA de impactos necesarios (acumulados) para cada LV - la duena
// puede tunear estos numeros: lv 2 = 2 impactos, +3 por nivel hasta
// lv 20 = 56 impactos (cada impacto = 1 cuchillazo acertado O 1 bloqueo
// exitoso).
function scr_kris_love_lv(_hits)
{
        static _th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56];

        var _lv = 1;
        for(var _i = 0; _i < array_length(_th); _i++)
        {
                if(_hits >= _th[_i])
                        _lv = _i + 2;
        }

        return min(_lv, KRIS_LV_MAX);
}

// Cuenta un impacto de LOVE y sube el LV si toca (y solo entonces):
// chime local del LV Up (snd_kris_lvup, v47) + senal silenciosa para que el puppet de Kris
// suba krisLvNet en las demas pantallas (ellas escalan su stun con su
// propia autoridad). Solo corre en el cliente del propio Kris.
// v96 (ritmo, pedido): "aumentaremos a 200% lo del aumento de nivel
// en lms y 50% en modo normal" — durante el Show Fuerte (global.
// lmsActive: el server lo confirma con SERVER_GAME_LMS cuando queda
// UN solo superviviente) cada impacto cuenta KRIS_LV_XP_LMS (perilla,
// hoy 5); en modo normal cuenta KRIS_LV_XP_NORMAL (1.5). Si Kris esta
// vivo con el show activo, EL es el ultimo: nadie mas puede acumular.
// v97 (SINCRONIZACION, bug reportado): con perillas > 3 un mismo
// golpe CRUZA DOS umbrales (estan espaciados de 3) — el LV local
// saltaba 2 niveles de un golpe mientras la senal silenciosa viajaba
// UNA sola vez y el espejo krisLvNet solo hace +1 por senal: los
// demas se quedaban atras (local LV 20 contra LV 13 espejado tras 12
// golpes de LMS a 5). FIX = MULTI-SIGNAL FLUSH: una senal POR NIVEL
// cruzado — el espejo queda EXACTO con CUALQUIER perilla.
function scr_kris_love_event(_kind)
{
        if(global.character != CHARACTER_KRIS)
                return;

        if(!instance_exists(global.player) || !variable_instance_exists(global.player.id, "krisLvHits"))
                return;

        global.player.krisLvHits += global.lmsActive ? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL;

        var _new = scr_kris_love_lv(global.player.krisLvHits);
        var _up = _new - global.player.krisLv; // niveles cruzados (0 = no sube)

        if(_up > 0)
        {
                global.player.krisLv = _new;

                // v95 (duena): "y el se cura esa misma cantidad por cada
                // que sube de nivel" — +20 de vida MAXIMA por LV (la nueva
                // vida total la calcula scr_player_maxhp con el LV recien
                // subido) y cura LOS MISMOS 20 POR CADA subida (v97: un
                // golpe que cruza 2 niveles cura 2x20 y sube 2x20 de vida
                // maxima — antes contaba +20 una sola vez). Con la vida ya
                // al tope no gana nada (el clamp del min). El hp viaja
                // clampeado a la nueva vida total en el CLIENT_PLAYER_DATA
                // (obj_netclient Step_2 ya consulta scr_player_maxhp).
                global.player.hp = min(global.player.hp + KRIS_LV_HP_BONUS * _up, scr_player_maxhp(CHARACTER_KRIS));

                // v47 (duena): el sonido de la subida de LV es el SUYO -
                // el mp3 "Undertale Sound Effect - LV Up" que subio,
                // registrado como asset nuevo snd_kris_lvup. Local como
                // siempre: los demas no oyen nada, la senal viaja
                // silenciosa.
                audio_play_sound(snd_kris_lvup, 0, false);

                // v97 MULTI-SIGNAL FLUSH: una senal silenciosa POR NIVEL
                // cruzado (antes UNA por golpe: con perillas > 3 un golpe
                // cruzaba 2 umbrales y el espejo krisLvNet — que sube +1
                // por senal — se quedaba atras para siempre, sin resync).
                // El receptor (net_state_game, rama del snd_none con gate
                // de personaje) espeja +1 por senal: queda EXACTO con
                // cualquier perilla. El server reenvia el broadcast sin
                // dedup (solo valida las senales DIRIGIDAS de stun): las
                // N senales llegan siempre.
                repeat(_up)
                        net_sound_emit(snd_none);
        }
}

// =====================================================================
//  v95 — SENAL DE DANO REAL AL ASESINO (Kris LV 20)
//
//  La emite el CLIENTE DEL EXE (la victima = la autoridad de siempre)
//  cada vez que la espada de un Kris con krisLvNet >= KRIS_LV_MAX le
//  baja KRIS_EXE_DAMAGE de vida real al pool (global.exeHpPool). La
//  reciben TODOS los clientes en el CLIENT_SOUND_EMIT: la rama del
//  puppet del EXE espeja el -35 en SU global.exeHpPool local — desde
//  v98 la barra del asesino la dibujan TODOS (Draw_64 del playerui)
//  en cuanto el Kris espejado llega a LV 20.
//  v98: EL REFILL DERIVADO SE RETIRO. Antes los dos lados (el exe
//  autoridad y los espejos) rellenaban el pool al tocar 0 y la pelea
//  podia repetirse. Ahora a 0 la partida TERMINA (victoria de los
//  supervivientes vivos no corrompidos): el aviso al server lo manda
//  scr_kris_exe_pool_hit con CLIENT_EXE_DEFEATED, y los espejos del
//  receptor se quedan en 0 — ya no derivan nada.
//
//  PORQUE UN PAQUETE CRUDO y no net_sound_emit: la funcion de la casa
//  silencia TODOS los sonidos del exe mientras esta INVISIBLE
//  (net_sounds.gml: solo snd_spring pasa) — la espada SI golpea al exe
//  invisible (el stun de contacto de siempre no mira invisTimer) y sin
//  esto la senal se perderia y la barra de Kris quedaria desincronizada
//  para siempre (drift acumulado, sin resincronizacion). Esta senal es
//  un DATO, no un sonido: el cliente del exe NO puede esconder sus
//  heridas volviendose invisible. En el receptor el sonido NUNCA suena
//  (la rama del espejo esta excluida del scr_audio_play_3d de abajo),
//  asi que tampoco regala la posicion del exe invisible.
//
//  INDICE: snd_kris_lvup al FINAL de global.net_snds (indice nuevo de
//  la casa — patron Chocola/MetalAmy/Jinna: un cliente viejo que lo
//  recibe simplemente lo ignora). El server reenvia CLIENT_SOUND_EMIT
//  sin validar indices (solo valida las senales DIRIGIDAS de stun), y
//  esta viaja con shouldPlay=false y nid propio: pasa libre.
function scr_kris_exe_hp_signal()
{
        var buffer = cpacket_tcp(PacketType.CLIENT_SOUND_EMIT, true);

        global.tmp_sndid = snd_kris_lvup;
        buffer_write(buffer, buffer_u16, obj_netclient.nid);
        buffer_write(buffer, buffer_u8, array_find_index(global.net_snds, function(_element, _index)
        {
            return _element == global.tmp_sndid;
        }));
        buffer_write(buffer, buffer_bool, false);
        send_server_tcp(buffer);
}

// =====================================================================
//  v98 — EL GOLPE REAL AL POOL, COMPARTIDO (espada Y parry, items 3+6).
//
//  Corre SOLO en el cliente del EXE (la autoridad de su propia vida,
//  patron victima-autoridad). Lo llaman:
//    * la ESPADA: obj_player_puppet/Step_0 (el stun de contacto del
//      cuchillazo de un Kris con krisLvNet >= KRIS_LV_MAX), y
//    * el PARRY: scr_parry_apply_stun (item 3: "el parry tambien
//      contara como dano" — mismo golpe real de 35 cuando el Kris a
//      LV 20 bloquea con exito el ataque que le entra).
//  Ambos ya consultan el krisLvNet espejado ANTES de llamar (el gate
//  vive en cada llamador). Hace TODO lo de siempre del golpe real:
//  -35 al pool, la senal silenciosa para los espejos de todas las
//  pantallas y el chime local. A 0 (v98): ya NO se rellena — avisa al
//  server con CLIENT_EXE_DEFEATED (lo valida: solo el exe de la ronda
//  puede reportar su caida; los supervivientes vivos no corrompidos
//  ganan contados como ESCAPADOS por el anillo y la ronda cierra con
//  ED_SURVWIN) y devuelve el KNOCKDOWN completo para el stun que lo
//  remato. Antes: refill + pelea a repeticion (retirado).
// =====================================================================
function scr_kris_exe_pool_hit(_stunTime)
{
        global.exeHpPool = max(global.exeHpPool - KRIS_EXE_DAMAGE, 0);

        // el espejo de TODAS las pantallas (la barra del asesino que
        // desde v98 dibuja todo el mundo): senal silenciosa con el
        // chime como portador (paquete CRUDO a proposito, ver arriba)
        scr_kris_exe_hp_signal();

        // el exe OYE su herida (local, como el stun): el chime de
        // Kris = "tocado de verdad"
        audio_play_sound(snd_kris_lvup, 0, false);

        if(global.exeHpPool <= 0)
        {
                // v98 (item 6): la partida finaliza — sin refill. El
                // server marca a los ganadores como escapados por el
                // anillo y cierra con la victoria de los supervivientes;
                // este cliente solo reporta su propia caida.
                var _pak = cpacket_tcp(PacketType.CLIENT_EXE_DEFEATED, true);
                send_server_tcp(_pak);

                // el knockdown completo: la caida se VE aunque la ronda
                // se este cerrando (el stun de remate sigue su camino
                // normal por el llamador)
                return KRIS_EXE_DOWN_SEC;
        }

        return _stunTime;
}
