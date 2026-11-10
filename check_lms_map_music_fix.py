#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_lms_map_music_fix.py — Verificador del FIX LMS MUSICA DE MAPA V1 (TD2DR).

BUG: al arrancar el show LMS ("El Show Fuerte") en Wood Zone, "..." y Act9,
la musica del mapa seguia sonando ENCIMA de la cancion del show (dos
canciones a la vez hasta el final de la ronda).

CAUSA (verificada en el codigo):
  Esos 3 mapas tocan su musica con audio_play_sound DIRECTO (capas con
  crossfade: mus_dotdotdot/mus_dotdotdot2 via obj_dotdotdot_i en "..." y
  Wood Zone; mus_act9/mus_act9_chase via RoomCreationCode en Act9) y NO
  pasan por global.music. scr_play_music (que usa el show) solo para
  global.music -> las capas del mapa ni se enteran.

FIX (5 cambios, todo cliente):
  1) scr_music.gml: nueva scr_stop_map_music() que para esas capas.
  2) net_state_game.gml SERVER_GAME_LMS: se llama ANTES de scr_lms_play_song.
  3) net_state_game.gml SERVER_RESULTS: se llama antes de room_goto(room_results)
     (los loops directos no mueren con el cambio de room y se colaban sobre
     la musica del ending).
  4) net_state_game.gml SERVER_GAME_SPAWN_RING: room_woodzone entra en la rama
     de room_dotdotdot (antes caia al else y su chase se montaba sobre
     mus_dotdotdot sin pararla).
  5) obj_dotdotdot_i/Step_0.gml: los triggers de zona no tocan gains de
     mus_dotdotdot mientras global.lmsActive (el fondo sigue cruzando).

Parte estatica: presencia exacta de los 5 cambios + invariantes que no
deben romperse (el show sigue llamando a scr_lms_play_song, el guard
!global.lmsActive del anillo sigue intacto, el crossfade visual de
obj_dotdotdot_i sigue intacto, dotdotdot_chase sigue siendo el chase de
"...").

Uso:  python check_lms_map_music_fix.py [ruta_del_repo]
      (por defecto asume que esta al lado de betterserver-oss/)
"""
import os
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))

OK = 0
FAIL = 0


def check(name, path, needles, notneedles=()):
    global OK, FAIL
    try:
        src = open(path, encoding="utf-8", errors="replace").read()
    except OSError as e:
        print(f"[FAIL] {name}: no se pudo abrir {path} ({e})")
        FAIL += 1
        return
    bad = [n for n in needles if n not in src]
    bad2 = [n for n in notneedles if n in src]
    if bad or bad2:
        for n in bad:
            print(f"[FAIL] {name}: falta '{n}' en {path}")
        for n in bad2:
            print(f"[FAIL] {name}: NO debia estar '{n}' en {path}")
        FAIL += 1
    else:
        print(f"[ OK ] {name}")
        OK += 1


# ----------------------------------------------------------------Fix 1
check(
    "1) scr_stop_map_music() existe y para las capas de los 3 mapas",
    os.path.join(REPO, "scripts/scr_music/scr_music.gml"),
    [
        "function scr_stop_map_music()",
        "audio_stop_sound(mus_dotdotdot);",
        "audio_stop_sound(mus_dotdotdot2);",
        "audio_stop_sound(mus_act9);",
        "audio_stop_sound(mus_act9_chase);",
        "room == room_dotdotdot || room == room_woodzone",
        "room == room_act9",
    ],
)

# ----------------------------------------------------------------Fix 2
check(
    "2) SERVER_GAME_LMS para la musica del mapa antes de la cancion del show",
    os.path.join(REPO, "scripts/net_state_game/net_state_game.gml"),
    [
        "case PacketType.SERVER_GAME_LMS:",
        "scr_stop_map_music();",
        "scr_lms_play_song(_lmsChar, _lmsSong);",
    ],
)

# ----------------------------------------------------------------Fix 3
check(
    "3) SERVER_RESULTS para la musica del mapa antes de ir a results",
    os.path.join(REPO, "scripts/net_state_game/net_state_game.gml"),
    [
        "case PacketType.SERVER_RESULTS:",
        "scr_stop_map_music();",
        "room_goto(room_results);",
    ],
)

# ----------------------------------------------------------------Fix 4
check(
    "4) SPAWN_RING: Wood Zone en la rama de dotdotdot (chase sin capas)",
    os.path.join(REPO, "scripts/net_state_game/net_state_game.gml"),
    [
        "if(!global.lmsActive)",
        "if(room == room_dotdotdot || room == room_woodzone)",
        "scr_play_music(room == room_dotdotdot ? mus_dotdotdot_chase : global.levels[lvlId].chaseMusic);",
        "audio_sound_gain(mus_act9_chase, 1, 1000);",
    ],
    # la rama vieja (solo dotdotdot, chase fijo) ya no debe existir tal cual:
    notneedles=["if(room == room_dotdotdot)\n\t\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\taudio_stop_sound(mus_dotdotdot);"],
)

# ----------------------------------------------------------------Fix 5
check(
    "5) obj_dotdotdot_i: sin gains de musica durante el show (fondo intacto)",
    os.path.join(REPO, "objects/obj_dotdotdot_i/Step_0.gml"),
    [
        "if(!global.lmsActive)",
        "audio_sound_gain(mus_dotdotdot2, 1, 2000);",
        "audio_sound_gain(mus_dotdotdot2, 0, 2000);",
        "layer_background_alpha(BG, fade);",
    ],
)

# ----------------------------------------------------------------Invariantes
check(
    "I) El show LMS sigue igual (cancion + banner + vida)",
    os.path.join(REPO, "scripts/scr_lms/scr_lms.gml"),
    [
        "function scr_lms_play_song",
        "scr_play_music(_list[idx]);",
        "#macro LMS_HP 100",
    ],
)

check(
    "I) Los 3 mapas siguen lanzando su musica de mapa al empezar ronda",
    os.path.join(REPO, "objects/obj_dotdotdot_i/Create_0.gml"),
    ["audio_play_sound(mus_dotdotdot, 0, true);", "audio_play_sound(mus_dotdotdot2, 0, true);"],
)
check(
    "I) Act9 sigue lanzando sus 2 capas en el RoomCreationCode",
    os.path.join(REPO, "rooms/room_act9/RoomCreationCode.gml"),
    ["audio_play_sound(mus_act9, 0, true);", "audio_play_sound(mus_act9_chase, 0, true);"],
)

print()
if FAIL == 0:
    print(f"TODO OK ({OK} verificaciones): FIX LMS MUSICA DE MAPA V1 completo.")
    sys.exit(0)
else:
    print(f"PROBLEMAS: {FAIL} verificaciones fallidas de {OK + FAIL}.")
    sys.exit(1)
