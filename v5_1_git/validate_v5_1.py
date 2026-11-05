#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_v5_1.py — validación completa de la v5.1 «Copias propias + LMS multi-canción»
sobre un working tree de disaster2d-oss.

Comprueba (nada se escribe):
  A) Los 14 sprites copia (Sally Canon <- Sally · Vanilla <- Cream):
     .yy legible, dimensiones/origen/frames correctos, PNG raíz + layers
     presentes y con EL MISMO contenido que el frame fuente.
  B) Registro en .yyp (JSON válido, 14 entradas, sin duplicados) y .resource_order.
  C) scr_characters.gml: bloque v5.1 completo (13 funciones), sin bloque v3.7,
     llaves balanceadas.
  D) Redirecciones en 8 archivos GML (marcadores nuevos presentes, remapeos
     viejos ausentes, llaves balanceadas).
  E) LMS multi-canción: Server.h / Game.c / Packet.h / scr_lms.gml /
     net_state_game.gml.
  F) Suite_TD2D.html v5.2: módulo LMS + editor de supervivientes + placas
     agrupadas (marcadores y bloques JS presentes).

Uso: python3 validate_v5_1.py [ruta-del-repo]
"""

import json
import os
import re
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/repo"
OK = 0
FAIL = 0


def check(name, cond, detail=""):
    global OK, FAIL
    if cond:
        OK += 1
    else:
        FAIL += 1
        print("  ! FAIL: %s %s" % (name, detail))


def rd(rel):
    with open(os.path.join(REPO, rel), "rb") as f:
        return f.read()


def txt(rel):
    return rd(rel).decode("utf-8", errors="replace")


def balanced(s):
    # solo llaves: los paréntesis de comentarios/strings desequilibran de fábrica
    return s.count("{") == s.count("}")


# ---------------------------------------------------------------- A) sprites
COPIES = [
    # (nuevo, fuente, frames_fuente, w, h, xo, yo, nframes)
    ("spr_lobby_icon_sallycanon", "spr_lobby_icon", [7], 24, 24, 12, 12, 1),
    ("spr_lobby_icon_vanilla", "spr_lobby_icon", [6], 24, 24, 12, 12, 1),
    ("spr_char_info_sallycanon", "spr_char_info", [5], 478, 40, 0, 0, 1),
    ("spr_char_info_vanilla", "spr_char_info", [4], 478, 40, 0, 0, 1),
    ("spr_playerhealth_sallycanon", "spr_playerhealth", list(range(35, 42)), 26, 26, 0, 26, 7),
    ("spr_playerhealth_vanilla", "spr_playerhealth", list(range(28, 35)), 26, 26, 0, 26, 7),
    ("spr_playerhealth_hit_sallycanon", "spr_playerhealth_hit", [5], 26, 26, 0, 26, 1),
    ("spr_playerhealth_hit_vanilla", "spr_playerhealth_hit", [4], 26, 26, 0, 26, 1),
    ("spr_playerhealth_demon_sallycanon", "spr_playerhealth_demon", [5], 26, 26, 0, 26, 1),
    ("spr_playerhealth_demon_vanilla", "spr_playerhealth_demon", [4], 26, 26, 0, 26, 1),
    ("spr_playerescaped_sallycanon", "spr_playerescaped", [5], 26, 26, 0, 26, 1),
    ("spr_playerescaped_vanilla", "spr_playerescaped", [4], 26, 26, 0, 26, 1),
]

print("== A) sprites copia ==")
for name, src, sframes, w, h, xo, yo, nf in COPIES:
    rel = "sprites/%s/%s.yy" % (name, name)
    ok_yy = os.path.exists(os.path.join(REPO, rel))
    check(name + " .yy existe", ok_yy)
    if not ok_yy:
        continue
    t = txt(rel)
    frames = re.findall(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', t)
    layers = re.findall(r'\{"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', t)
    check(name + " frames=%d" % nf, len(frames) == nf, "(%d)" % len(frames))
    check(name + " 1 layer", len(layers) == 1)
    check(name + " %dx%d" % (w, h), ('"width":%d' % w) in t and ('"height":%d' % h) in t)
    check(name + " origin(%d,%d)" % (xo, yo), ('"xorigin":%d' % xo) in t and ('"yorigin":%d' % yo) in t)
    # PNGs raíz + layers con el contenido del fuente
    st = txt("sprites/%s/%s.yy" % (src, src))
    sfr = re.findall(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', st)
    sla = re.findall(r'\{"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', st)[0]
    for i, sf in enumerate(sframes):
        root_new = "sprites/%s/%s.png" % (name, frames[i])
        lay_new = "sprites/%s/layers/%s/%s.png" % (name, frames[i], layers[0])
        root_old = "sprites/%s/%s.png" % (src, sfr[sf])
        lay_old = "sprites/%s/layers/%s/%s.png" % (src, sfr[sf], sla)
        for a, b in ((root_new, root_old), (lay_new, lay_old)):
            pa = os.path.join(REPO, a)
            if not os.path.exists(pa):
                check(name + " PNG " + a.split("/")[-1], False)
            else:
                check(name + " PNG f%d == fuente" % i, rd(a) == rd(b))

# retratos animados: solo presencia y nº de frames
for name, src in (("spr_menu_sallycanon", "spr_menu_sally"), ("spr_menu_vanilla", "spr_menu_cream")):
    okp = os.path.exists(os.path.join(REPO, "sprites/%s/%s.yy" % (name, name)))
    check(name + " .yy existe", okp)
    if okp:
        a = len(re.findall(r'\{"\$GMSpriteFrame":"v1"', txt("sprites/%s/%s.yy" % (name, name))))
        b = len(re.findall(r'\{"\$GMSpriteFrame":"v1"', txt("sprites/%s/%s.yy" % (src, src))))
        check(name + " frames == fuente (%d)" % b, a == b, "(%d)" % a)

# ---------------------------------------------------------------- B) registro
print("== B) registro .yyp / .resource_order ==")
yyp = txt("Sonicexe The Disaster 2D Remake.yyp")
try:
    d = json.loads(re.sub(r",(\s*[}\]])", r"\1", yyp))
    check(".yyp JSON válido", True)
    names = [r["id"]["name"] for r in d["resources"]]
    for name, *_ in COPIES:
        check(".yyp registra " + name, name in names)
    for name in ("spr_menu_sallycanon", "spr_menu_vanilla"):
        check(".yyp registra " + name, name in names)
    check(".yyp sin duplicados", len(names) == len(set(names)))
except Exception as e:
    check(".yyp JSON válido", False, str(e))
ro = txt("Sonicexe The Disaster 2D Remake.resource_order")
for name, *_ in COPIES:
    check(".resource_order " + name, ('"name":"%s"' % name) in ro)

# ---------------------------------------------------------------- C) scr_characters
print("== C) scr_characters.gml ==")
sc = txt("scripts/scr_characters/scr_characters.gml")
BEG = "// ===== [Suite TD2D v5.1] iconos de selección y HUD por personaje (auto: no editar) ====="
END = "// ===== fin [Suite TD2D v5.1] ====="
check("bloque v5.1 presente", BEG in sc and END in sc)
check("bloque v3.7 retirado", "// ===== [Suite TD2D v3.7] retratos con brillo (auto: no editar) =====" not in sc)
for fn in ("scr_lobby_icon_sprite", "scr_lobby_icon_frame", "scr_lobby_icon_animated", "scr_lobby_icon_pair",
           "scr_lobby_shiny_setup", "scr_lobby_shiny_resolve", "scr_lobby_shiny_escape",
           "scr_hud_strip", "scr_hud_strip_red", "scr_hud_hit", "scr_hud_demon",
           "scr_hud_escaped", "scr_hud_escaped_draw"):
    check("función " + fn, ("function %s(" % fn) in sc)
check("llaves balanceadas", balanced(sc))
check("caso Sally Canon en strip", "case CHARACTER_SALLY_CANON: return [spr_playerhealth_sallycanon, 0];" in sc)
check("caso Vanilla en strip", "case CHARACTER_VANILLA: return [spr_playerhealth_vanilla, 0];" in sc)
check("llaves balanceadas", balanced(sc))

# ---------------------------------------------------------------- D) redirecciones
print("== D) redirecciones GML ==")
def has(rel, s): return s in txt(rel)
def lbal(rel): return balanced(txt(rel))

REL = "objects/obj_lobby/Create_0.gml"
check("lobby chars[8] retrato propio", has(REL, "spr_menu_sallycanon, // 8"))
check("lobby chars[9] retrato propio", has(REL, "spr_menu_vanilla, // 9"))
check("lobby chars[8] viejo ausente", "spr_menu_sally, // 8" not in txt(REL))

REL = "objects/obj_lobby/Draw_0.gml"
check("placa propia sc", has(REL, "draw_sprite(spr_char_info_sallycanon, 0, 1, 232-5);"))
check("placa propia vn", has(REL, "draw_sprite(spr_char_info_vanilla, 0, 1, 232-5);"))
check("remapeo viejo placas ausente", "_infoFrame = 5; // sally canon" not in txt(REL))
check("llaves", lbal(REL))

REL = "objects/obj_lobby_icon/Draw_0.gml"
check("nav por resolvedor", has(REL, "scr_lobby_shiny_setup(selected);"))
check("resolve por fotograma", has(REL, "scr_lobby_shiny_resolve(self);"))
check("remapeos viejos ausentes", "image_index = selected == CHARACTER_SALLY_CANON" not in txt(REL))
check("llaves", lbal(REL))

REL = "scripts/net_state_charselect/net_state_charselect.gml"
check("response por resolvedor", has(REL, "scr_lobby_shiny_setup(char);"))
check("change por resolvedor", txt(REL).count("scr_lobby_shiny_setup(char);") == 2)
check("viejo ausente", "sprite_index = spr_lobby_icon_fw;" not in txt(REL))
check("llaves", lbal(REL))

REL = "objects/obj_menu_waiting/Draw_64.gml"
check("lista de sala por resolvedor", has(REL, "scr_lobby_icon_sprite(_ch);"))
check("viejo ausente", "index = (plr.char == 8 ? 5 : plr.char) + 2;" not in txt(REL))
check("llaves", lbal(REL))

REL = "objects/obj_level/Draw_64.gml"
for pat in ("scr_hud_strip(_hudChar)", "scr_hud_strip_red(_hudChar)", "scr_hud_hit(_hudChar)",
            "scr_hud_demon(_hudChar)", "scr_hud_escaped_draw(_hudChar, pos, 268)",
            "scr_hud_strip(_pch)", "scr_hud_hit(_pch)", "scr_hud_demon(_pch)",
            "scr_hud_escaped_draw(_ech, pos + i * 28, 268)"):
    check("HUD: " + pat, has(REL, pat))
check("remapeo _hudChar viejo ausente", "var _hudChar = global.character == CHARACTER_SALLY_CANON ?" not in txt(REL))
check("llaves", lbal(REL))

REL = "objects/obj_level/Create_0.gml"
check("TAB por resolvedor", has(REL, "scr_hud_demon(char) : scr_hud_hit(char);"))
check("remapeo TAB viejo ausente", "hchar = CHARACTER_SALLY - 1;" not in txt(REL))
check("llaves", lbal(REL))

REL = "scripts/net_state_results/net_state_results.gml"
for pat in ("scr_hud_demon(_char + 1)", "scr_hud_strip(_char + 1)", "scr_lobby_icon_pair(_char + 1)",
            "scr_hud_escaped(_char + 1)"):
    check("results: " + pat, has(REL, pat))
check("remapeo results viejo ausente", "_char = 5;" not in txt(REL))
check("_isFw retirado", "_isFw" not in txt(REL))
check("llaves", lbal(REL))

# ---------------------------------------------------------------- E) LMS
print("== E) LMS multi-canción ==")
sh = txt("betterserver-oss/include/Server.h")
check("LMS_SONG_COUNT", "#define LMS_SONG_COUNT 1" in sh)
check("LMS_SONG_SEC", "static const uint16_t LMS_SONG_SEC[LMS_SONG_COUNT] = { 282 };" in sh)
check("campo lms_song", "uint8_t lms_song;" in sh)
check("LMS_TIME_SEC retirado", "#define LMS_TIME_SEC" not in sh)

gc = txt("betterserver-oss/disasterserver/states/Game.c")
check("elección al azar", "rand() % LMS_SONG_COUNT" in gc)
check("reloj por canción", "server->game.time_sec = LMS_SONG_SEC[server->game.lms_song];" in gc)
check("paquete con índice", "PacketWrite(&packet, packet_write8, server->game.lms_song);" in gc)
check("reenvío join con índice", "PacketWrite(&packet, packet_write8, v->server->game.lms_song);" in gc)
check("init .lms_song", ".lms_song = 0," in gc)

ph = txt("betterserver-oss/include/Packet.h")
check("comentario payload u8", "payload u8 song" in ph)

sl = txt("scripts/scr_lms/scr_lms.gml")
check("lista lmsSongs", "global.lmsSongs = [mus_undefeatable];" in sl)
check("scr_lms_play_song", "function scr_lms_play_song(idx)" in sl)
check("macro LMS_HP", "#macro LMS_HP 100" in sl)

ng = txt("scripts/net_state_game/net_state_game.gml")
check("lee índice u8", "buffer_read_s(rbuff, buffer_u8)" in ng and "_lmsSong" in ng)
check("reproduce por índice", "scr_lms_play_song(_lmsSong);" in ng)
check("vida por macro", "global.player.hp = LMS_HP;" in ng)
check("reproducción directa vieja ausente", "scr_play_music(mus_undefeatable);" not in ng)

# ---------------------------------------------------------------- F) Suite
print("== F) Suite_TD2D.html v5.2 ==")
st = txt("Suite_TD2D.html")
for pat in ('<div id="mod-lms" class="mod hidden">', "window.enterLms", 'data-mod="lms"',
            "buildSoundYy", "decodeAudioData", "LMS_SONG_SEC", 'id="sv-list"', "SURV_CHARS",
            "regenIconRouterBlock", "EXTRA_PLAQUES", 'id="sv-edit"', "writeSv",
            "módulo 🎤 Show LMS no arrancó", "copias propias"):
    check("Suite: " + pat, pat in st)
check("título v5.2", "<title>Suite TD2D v5.2" in st)
# scripts JS legibles
import subprocess
scripts = re.findall(r"<script>(.*?)</script>", st, re.S)
check("Suite: 8 scripts", len(scripts) == 8, "(%d)" % len(scripts))
for i, s in enumerate(scripts):
    p = "/tmp/_suite_check_%d.js" % i
    open(p, "w", encoding="utf-8").write(s)
    r = subprocess.run(["node", "--check", p], capture_output=True)
    check("Suite: script %d sintaxis" % i, r.returncode == 0, r.stderr.decode()[:120])

# ----------------------------------------------------------------
print("\n=== RESULTADO: %d OK · %d FAIL ===" % (OK, FAIL))
sys.exit(1 if FAIL else 0)
