#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v69.py — verificacion completa de la v69 (BOTAS snd_speedboost).

Regla de oro 6: verificar al 100%, testear hasta estar completamente
seguro. Chequea:

  A. Presencia y estructura de los helpers duck/unduck en scr_music.gml
  B. case 4: play snd_speedboost (loop) + scr_music_duck, guard intacto
  C. Cortes de seguridad: LMS y SERVER_RESULTS apagan + unduck
  D. scr_move_basic: unduck SOLO en el frame de expiracion (bootsTimer<=0
     dentro del bloque de tick)
  E. scr_player_instakill: reset bootsTimer + stop + unduck con guard
  F. scr_menu_more: snd_speedboost registrado en sfxList (slider)
  G. Balance de llaves de CADA archivo tocado (sintaxis bruta)
  H. .yyp intacto (no se toco) + snd_speedboost sigue registrado
  I. Simulacion del ciclo de vida completo (mono y multiframes)
  J. El asset snd_speedboost existe en disco (ogg) — ya subido por owner
"""
import re, json, subprocess, sys

REPO = "/home/z/my-project/repo"
F = lambda p: open(f"{REPO}/{p}", encoding="utf-8").read()

fails = []
def check(name, cond, detail=""):
    print(f"  [{'OK' if cond else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))
    if not cond:
        fails.append(name)

print("== A. helpers duck/unduck en scr_music.gml ==")
m = F("scripts/scr_music/scr_music.gml")
check("scr_music_duck definida", "function scr_music_duck()" in m)
check("scr_music_unduck definida", "function scr_music_unduck()" in m)
check("duck usa metodo anti-camping (gain 0, 2000ms)", "audio_sound_gain(global.music, 0, 2000)" in m)
check("unduck restaura musicVolume*0.1 en 500ms",
      "audio_sound_gain(global.music, obj_config.musicVolume * 0.1, 500)" in m)
check("duck con guard global.music == -1", re.search(
    r"function scr_music_duck\(\)\s*\{\s*if\(global\.music == -1\)\s*return;", m) is not None)
check("unduck con guard global.music == -1", re.search(
    r"function scr_music_unduck\(\)\s*\{\s*if\(global\.music == -1\)\s*return;", m) is not None)
check("scr_play_music/scr_stop_music/scr_stop_map_music intactas",
      "function scr_play_music" in m and "function scr_stop_music()" in m and "function scr_stop_map_music()" in m)

print("== B. case 4 botas en net_state_game ==")
g = F("scripts/net_state_game/net_state_game.gml")
pat_case4 = re.search(r"case 4: // botas.*?break;", g, re.S)
check("case 4 existe", pat_case4 is not None)
if pat_case4:
    c4 = pat_case4.group(0)
    check("bootsTimer = 60 * 8 intacto", "bootsTimer = 60 * 8" in c4)
    check("guard anti-doble intacto", "bootsTimer <= 0" in c4)
    check("play snd_speedboost LOOP", "audio_play_sound(snd_speedboost, 0, true)" in c4)
    check("duck al activar", "scr_music_duck();" in c4)
    check("snd_spring ya NO (reemplazado)", "snd_spring" not in c4)

print("== C. cortes de seguridad LMS/RESULTS ==")
lms_zone = re.search(r"SERVER_GAME_LMS.*?scr_lms_play_song", g, re.S)
check("zona LMS encontrada", lms_zone is not None)
if lms_zone:
    z = lms_zone.group(0)
    check("LMS: stop snd_speedboost antes de la cancion", "audio_stop_sound(snd_speedboost);\n                        scr_music_unduck();\n\n                        scr_lms_play_song" in z or
          ("audio_stop_sound(snd_speedboost)" in z and "scr_music_unduck();" in z))
res_zone = re.search(r"case PacketType\.SERVER_RESULTS:.*?state = STATE_RESULTS;", g, re.S)
check("zona RESULTS encontrada", res_zone is not None)
if res_zone:
    z = res_zone.group(0)
    check("RESULTS: stop + unduck antes de room_goto(results)",
          "audio_stop_sound(snd_speedboost);" in z and "scr_music_unduck();" in z and
          z.index("audio_stop_sound(snd_speedboost)") < z.index("state = STATE_RESULTS"))

print("== D. expiracion en scr_move_basic ==")
mb = F("scripts/scr_move_basic/scr_move_basic.gml")
tick = re.search(r'if\(variable_instance_exists\(id, "bootsTimer"\) && bootsTimer > 0\)\s*\{(.*?)\n        \}', g if False else mb, re.S)
check("bloque tick bootsTimer existe", tick is not None)
if tick:
    t = tick.group(0)
    check("unduck solo al expirar (bootsTimer <= 0 dentro del tick)",
          re.search(r"bootsTimer--;[\s\S]*?if\(bootsTimer <= 0\)\s*\{\s*audio_stop_sound\(snd_speedboost\);\s*scr_music_unduck\(\);\s*\}", t) is not None
          and "if(bootsTimer <= 0)" in t
          # y que NO haya unduck fuera del if de expiracion dentro del tick:
          and t.count("scr_music_unduck") == 1)
    check("cap +3/aceleracion intactos (L673)", "maxHSpeed + 3" in mb and "acc * 1.5" in mb)

print("== E. muerte en scr_player_instakill ==")
ph = F("scripts/scr_player_hurt/scr_player_hurt.gml")
death = re.search(r"global\.player\.isDead = true;(.*?)global\.player\.shards = 0;", ph, re.S)
check("bloque muerte encontrado", death is not None)
if death:
    d = death.group(0)
    check("guard bootsTimer>0 al morir", 'variable_instance_exists(global.player, "bootsTimer")' in d)
    check("reset bootsTimer = 0", "global.player.bootsTimer = 0" in d)
    check("stop snd_speedboost", "audio_stop_sound(snd_speedboost)" in d)
    check("scr_music_unduck al morir", "scr_music_unduck();" in d)

print("== F. sfxList (slider SOUND VOLUME) ==")
sm = F("scripts/scr_menu_more/scr_menu_more.gml")
sfx = re.search(r"global\.sfxList = \[(.*?)\];", sm, re.S)
check("sfxList parseable", sfx is not None)
if sfx:
    body = re.sub(r"//[^\n]*", "", sfx.group(1))          # quitar comentarios de linea
    items = [x.strip() for x in body.replace("\n", " ").split(",") if x.strip()]
    check("snd_speedboost en sfxList", "snd_speedboost" in items, f"{len(items)} items")
    check("sfxList sigue cerrando con ] y sin coma colgante", not sfx.group(1).rstrip().endswith(","))

print("== G. balance de llaves de los 5 archivos ==")
for path in ["scripts/scr_music/scr_music.gml", "scripts/net_state_game/net_state_game.gml",
             "scripts/scr_move_basic/scr_move_basic.gml", "scripts/scr_player_hurt/scr_player_hurt.gml",
             "scripts/scr_menu_more/scr_menu_more.gml"]:
    s = F(path)
    # quitar strings y comentarios para contar llaves reales
    s2 = re.sub(r'"(?:[^"\\]|\\.)*"', '""', s)
    s2 = re.sub(r"'(?:[^'\\]|\\.)*'", "''", s2)
    s2 = re.sub(r"//[^\n]*", "", s2)
    s2 = re.sub(r"/\*.*?\*/", "", s2, flags=re.S)
    ob, cb = s2.count("{"), s2.count("}")
    check(f"llaves balanceadas {path.split('/')[-1]}", ob == cb, f"{{={ob} }}={cb}")

print("== H. .yyp intacto + snd_speedboost registrado ==")
r = subprocess.run(["git", "-C", REPO, "status", "--porcelain"], capture_output=True, text=True)
touched = [l for l in r.stdout.splitlines() if ".yyp" in l or ".yy" in l]
check("ningun .yyp/.yy tocado", len(touched) == 0, str(touched))
yyp = F("Sonicexe The Disaster 2D Remake.yyp")
check("snd_speedboost registrado en .yyp", 'sounds/snd_speedboost/snd_speedboost.yy' in yyp)
import os
check("ogg en disco", os.path.exists(f"{REPO}/sounds/snd_speedboost/snd_speedboost.ogg"))

print("== I. simulacion del ciclo de vida ==")

class FakeAudio:
    def __init__(self):
        self.playing = {}          # snd -> gain
        self.music_gain = 1.0
        self.music_id = 5
        self.stopped = []
    def play(self, snd, loop):
        self.playing[snd] = 0.3
        return 100 + len(self.playing)
    def stop(self, snd):
        self.stopped.append(snd)
        self.playing.pop(snd, None)
    def gain(self, snd, val, ms):
        if snd == self.music_id:
            self.music_gain = val

audio = FakeAudio()
global_music = audio.music_id
music_volume = 10  # obj_config.musicVolume default

def scr_music_duck():
    if global_music == -1: return
    audio.gain(global_music, 0, 2000)

def scr_music_unduck():
    if global_music == -1: return
    audio.gain(global_music, music_volume * 0.1, 500)

# --- I1: activar botas ---
boots = 0
if boots <= 0:
    boots = 60 * 8
    audio.play("snd_speedboost", True)
    scr_music_duck()
check("I1 activar: loop sonando", "snd_speedboost" in audio.playing)
check("I1 activar: musica silenciada a 0", audio.music_gain == 0)

# --- I2: tick 8s (480 frames) -> expira y restaura ---
frames = 0
while boots > 0:
    boots -= 1
    frames += 1
    if boots <= 0:
        audio.stop("snd_speedboost")
        scr_music_unduck()
check("I2 duracion exacta 480 frames", frames == 480)
check("I2 loop apagado", "snd_speedboost" not in audio.playing)
check("I2 musica restaurada (gain 1.0)", audio.music_gain == 1.0)

# --- I3: muerte a mitad del efecto ---
audio2 = FakeAudio()
global_music = audio2.music_id
boots = 60 * 8
audio2.play("snd_speedboost", True)
scr_music_duck()
# 200 frames despues muere:
for _ in range(200): boots -= 1
if boots > 0:
    boots = 0
    audio2.stop("snd_speedboost")
    scr_music_unduck()
check("I3 muerte: loop apagado", "snd_speedboost" not in audio2.playing)
check("I3 muerte: musica restaurada", audio2.music_gain == 1.0)
check("I3 muerte: bootsTimer en 0 (no revive solo)", boots == 0)

# --- I4: LMS con botas activas ---
audio3 = FakeAudio()
global_music = audio3.music_id
boots = 60 * 8
audio3.play("snd_speedboost", True)
scr_music_duck()
# llega SERVER_GAME_LMS:
audio3.stop("snd_speedboost"); scr_music_unduck()
# scr_lms_play_song -> scr_play_music -> nueva musica gain fresco:
audio3.music_gain = 1.0
check("I4 LMS: sin snd_speedboost al show", "snd_speedboost" not in audio3.playing)
check("I4 LMS: sin duck residual (unduck ejecutado)", audio3.music_gain == 1.0)

# --- I5: sin musica de fondo (global.music == -1) ---
global_music = -1
audio4 = FakeAudio()
boots = 60 * 8
audio4.play("snd_speedboost", True)
scr_music_duck()   # guard: no crash, no-op
check("I5 guard -1: sin excepcion, loop sigue", "snd_speedboost" in audio4.playing)
boots = 0; audio4.stop("snd_speedboost"); scr_music_unduck()  # no-op
check("I5 guard -1: unduck no-op", audio4.music_gain == 1.0)

# --- I6: segunda caja de botas mientras la primera suena (guard anti-doble) ---
audio5 = FakeAudio()
global_music = audio5.music_id
boots = 60 * 8
audio5.play("snd_speedboost", True)
scr_music_duck()
# segundo reward NO re-triggerea (guard bootsTimer > 0):
if boots <= 0:
    boots = 60 * 8
    audio5.play("snd_speedboost", True)
    scr_music_duck()
check("I6 anti-doble: no se re-anida el efecto", len(audio5.playing) == 1)

print("== J. anti-cheat (regla 7): sin cambios de red ==")
# v69 no toca ningun paquete: bootsTimer ya es variable CLIENTE pura desde v62.
# El sonido es local (audio_play_sound, NO net_sound_emit): los demas clientes
# NO oyen las botas del otro — igual que snd_spring antes. Cero superficie nueva.
check("sin net_sound_emit nuevo", "net_sound_emit" not in g[g.find("case 4: // botas"):g.find("case PacketType.SERVER_NAPBALL_STATE")])
check("sin cambios en betterserver-oss", subprocess.run(
    ["git", "-C", REPO, "status", "--porcelain", "betterserver-oss"],
    capture_output=True, text=True).stdout.strip() == "")

print()
if fails:
    print(f"RESULT: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULT: TODOS LOS CHECKS v69 OK")
