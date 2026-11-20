#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v41.py — Validador de la ronda v41 (el pedido de la duena):

  MUSICA NUEVA:
  1. LOBBY: room_lobby/RoomCreationCode.gml ahora reproduce lobby_force
     (antes mus_lobby_1). Cubre TODAS las entradas al lobby porque la
     room se recrea en cada vuelta (net_state_game x3, net_tcpprocess,
     net_state_pending, obj_level/Alarm_2 -> room_goto(room_lobby)).
  2. SELECCION DE PERSONAJE: el paquete SERVER_LOBBY_EXE (que arranca la
     fase de seleccion) se recibe en DOS estados: STATE_LOBBY
     (net_state_lobby.gml) y STATE_VOTE (net_state_vote.gml). Ambos
     ahora reproducen Select_char_force (antes mus_lobby_epic en los
     dos). El fade al arrancar la partida sigue parando la musica
     (obj_lobby/Draw_64 -> scr_stop_music, intacto).

  SOPORTE:
  3. VOLUMEN Options > More: lobby_force y Select_char_force entran a
     global.musList (sin esto el slider MUSIC VOLUME no los alcanzaba
     mientras suenan; el resto de la musica del juego si responde).
     91 -> 93 assets, comentarios actualizados.
  4. Assets ya registrados por la duena en el push (lobby_force,
     Select_char_force, Lobby1_0_TD en .yyp + resource_order):
     verificado que existen y resuelven — esta ronda NO toca .yyp/.yy.

Verifica (estatico, sin GameMaker):
  A-musica lobby, B-musica seleccion (ambos handlers + cero fugas de
  la musica vieja), C-assets (yy/ogg/yyp/resource_order),
  D-volumen (musList 93 + comentarios), E-sintaxis (balance de
  llaves/parentesis), F-regresion git (solo 4 .gml + docs),
  G-anti-cheat (cero red: diffs puros de musica).

Uso: python3 check_v41.py [ruta_repo]
     (por defecto /home/z/my-project/disaster2d-oss)
"""
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/disaster2d-oss"
ROOM_CRE = os.path.join(REPO, "rooms/room_lobby/RoomCreationCode.gml")
NET_LOBBY = os.path.join(REPO, "scripts/net_state_lobby/net_state_lobby.gml")
NET_VOTE = os.path.join(REPO, "scripts/net_state_vote/net_state_vote.gml")
SCR_MORE = os.path.join(REPO, "scripts/scr_menu_more/scr_menu_more.gml")
YYP = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")
RORDER = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.resource_order")

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print(f"  [OK] {msg}")


def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  [FALLO] {msg}")


def check(cond, msg):
    if cond:
        ok(msg)
    else:
        bad(msg)


def read(p):
    with open(p, encoding="utf-8", errors="replace") as f:
        return f.read()


def yyp_json():
    raw = read(YYP)
    raw = re.sub(r",(\s*[}\]])", r"\1", raw)  # trailing commas de GM
    import json
    return json.loads(raw)


def balance(src):
    s = re.sub(r"//[^\n]*", "", src)
    s = re.sub(r'"(\\.|[^"\\])*"', "S", s)
    return s.count("(") == s.count(")") and s.count("{") == s.count("}") and s.count("[") == s.count("]")


print("== A) MUSICA DEL LOBBY ==")
cre = read(ROOM_CRE)
calls_cre = re.findall(r"scr_play_music\s*\(\s*([^)]+?)\s*\)", cre)
check("scr_play_music(lobby_force)" in cre, "room_lobby/RoomCreationCode reproduce lobby_force")
check(calls_cre == ["lobby_force"], f"la unica musica reproducida en la room es lobby_force ({calls_cre})")
check(re.search(r"scr_play_music\s*\(\s*mus_lobby_1", cre) is None, "mus_lobby_1 ya no se reproduce al entrar al lobby")
check(cre.count("scr_play_music(") == 1, "1 sola llamada de musica en la creacion de la room")

# toda vuelta al lobby recrea la room -> cubre los returns:
gml_all = []
for root, _dirs, files in os.walk(os.path.join(REPO, "scripts")):
    if "_backups_animeditor" in root:
        continue
    for fn in files:
        if fn.endswith(".gml"):
            gml_all.append(os.path.join(root, fn))
for extra in ("objects", "rooms"):
    for root, _dirs, files in os.walk(os.path.join(REPO, extra)):
        if "_backups_animeditor" in root:
            continue
        for fn in files:
            if fn.endswith(".gml"):
                gml_all.append(os.path.join(root, fn))
goto_lobby = sum(read(p).count("room_goto(room_lobby)") for p in gml_all)
check(goto_lobby >= 5, f"las {goto_lobby} vueltas a room_goto(room_lobby) recrean la room (lobby_force suena en todas)")

print("== B) MUSICA DE LA SELECCION DE PERSONAJE ==")
nl = read(NET_LOBBY)
nv = read(NET_VOTE)
check("scr_play_music(Select_char_force)" in nl, "net_state_lobby: SERVER_LOBBY_EXE reproduce Select_char_force")
check("scr_play_music(Select_char_force)" in nv, "net_state_vote: SERVER_LOBBY_EXE reproduce Select_char_force")
check("case PacketType.SERVER_LOBBY_EXE:" in nl, "case SERVER_LOBBY_EXE intacto en net_state_lobby")
check("case PacketType.SERVER_LOBBY_EXE:" in nv, "case SERVER_LOBBY_EXE intacto en net_state_vote")
cl = re.findall(r"scr_play_music\s*\(\s*([^)]+?)\s*\)", nl)
cv = re.findall(r"scr_play_music\s*\(\s*([^)]+?)\s*\)", nv)
check(cl == ["Select_char_force"] and cv == ["Select_char_force"], f"1 sola llamada por archivo y es la pista nueva (lobby: {cl}, vote: {cv})")
# cero fugas en todo el proyecto (solo la room y los 2 handlers deben tocar musica de lobby/select):
leaks = []
for p in gml_all:
    t = read(p)
    for pat in ("mus_lobby_1", "mus_lobby_epic"):
        if re.search(r"scr_play_music\s*\(\s*" + pat, t):
            leaks.append((os.path.relpath(p, REPO), pat))
check(not leaks, f"cero reproducciones activas de mus_lobby_1/mus_lobby_epic en el proyecto ({leaks or 'limpio'})")
# el arranque de partida sigue parando la musica (fade en obj_lobby):
draw64 = read(os.path.join(REPO, "objects/obj_lobby/Draw_64.gml"))
check("scr_stop_music()" in draw64, "fade al iniciar partida (obj_lobby/Draw_64) sigue parando la musica")

print("== C) ASSETS NUEVOS (ya subidos por la duena) ==")
for snd, f in (("lobby_force", "lobby_force.ogg"), ("Select_char_force", "Select_char_force.ogg")):
    yy = os.path.join(REPO, f"sounds/{snd}/{snd}.yy")
    ogg = os.path.join(REPO, f"sounds/{snd}/{f}")
    size = os.path.getsize(ogg) // 1024 if os.path.isfile(ogg) else 0
    check(os.path.isfile(yy), f"sounds/{snd}/{snd}.yy existe")
    check(os.path.isfile(ogg) and size > 100, f"{f} existe y pesa {size} KB")
    t = read(yy)
    check(f'"name":"{snd}"' in t.replace(" ", "") or f'"%Name":"{snd}"' in t.replace(" ", ""), f"nombre del asset = {snd}")
    check(f'"soundFile":"{f}"' in t.replace(" ", ""), f"soundFile = {f}")
yyp = yyp_json()
snd_paths = [r["id"]["path"] for r in yyp["resources"] if r["id"]["path"].startswith("sounds/")]
for snd in ("lobby_force", "Select_char_force"):
    check(f"sounds/{snd}/{snd}.yy" in snd_paths, f"{snd} registrado en el .yyp ({len(snd_paths)} sounds)")
ro = read(RORDER)
for snd in ("lobby_force", "Select_char_force"):
    check(snd in ro, f"{snd} presente en resource_order")

print("== D) VOLUMEN OPTIONS > MORE (musList) ==")
more = read(SCR_MORE)
m = re.search(r"global\.musList = \[(.*?)\];", more, re.S)
names = [n.strip() for n in m.group(1).split(",") if n.strip()]
check("lobby_force" in names, "lobby_force en global.musList")
check("Select_char_force" in names, "Select_char_force en global.musList")
check(len(names) == 93, f"musList = 93 assets (91 + 2 nuevos); conteo real: {len(names)}")
dups = [n for n in set(names) if names.count(n) > 1]
check(not dups, f"sin duplicados en musList ({dups or 'limpio'})")
s = re.search(r"global\.sfxList = \[(.*?)\];", more, re.S)
sfx = [n.strip() for n in s.group(1).split(",") if n.strip()]
check(len(sfx) == 238, f"sfxList intacta: 238 assets")
check("93 assets de musica" in more, "comentario del header actualizado a 93")
check("musica (93)" in more, "comentario de apply_volumes actualizado a 93")
# gain al reproducir (scr_play_music sigue aplicando el volumen en vivo):
scm = read(os.path.join(REPO, "scripts/scr_music/scr_music.gml"))
check("audio_sound_gain(global.music, obj_config.musicVolume * 0.1, 0)" in scm, "scr_play_music sigue aplicando musicVolume al reproducir")

print("== E) SINTAXIS DE LOS ARCHIVOS MODIFICADOS ==")
for p in (ROOM_CRE, NET_LOBBY, NET_VOTE, SCR_MORE):
    check(balance(read(p)), f"llaves/parentesis balanceados: {os.path.relpath(p, REPO)}")

print("== F) REGRESION GIT (solo lo pedido) ==")
st = subprocess.run(["git", "status", "--porcelain"], cwd=REPO, capture_output=True, text=True).stdout
mod = sorted(l[3:] for l in st.splitlines() if l.strip())
expect = sorted([
    "LEEME_MUSICA_V41.txt",
    "check_v41.py",
    "rooms/room_lobby/RoomCreationCode.gml",
    "scripts/net_state_lobby/net_state_lobby.gml",
    "scripts/net_state_vote/net_state_vote.gml",
    "scripts/scr_menu_more/scr_menu_more.gml",
    "worklog.md",
])
check(mod == expect, f"archivos de la ronda exactos: {mod}")
no_touch = [f for f in mod if f.endswith((".yyp", ".yy")) or f.endswith((".ogg", ".mp3"))]
check(not no_touch, f"ningun .yyp/.yy/audio tocado por esta ronda ({no_touch or 'confirmado'})")

print("== G) ANTI-CHEAT (cero superficie de red) ==")
diff = subprocess.run(["git", "diff", "-U0", "--", "rooms/", "scripts/"], cwd=REPO, capture_output=True, text=True).stdout
added = [l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++")]
code_added = [l for l in added if not l.strip().startswith("//")]
bad_net = [l for l in code_added if re.search(r"buffer_(write|seek|read)|send_|udp_|tcp_|PacketType\s*\w+\s*[:=]|socket", l)]
check(not bad_net, f"lineas nuevas de CODIGO sin red ({bad_net or 'cero'})")
check(all(re.search(r"scr_play_music|lobby_force|Select_char_force|Best_ending|Standard_|mus_", l) for l in code_added),
      "toda linea de codigo nueva es de musica (comentarios aparte)")
# formateo: la edicion no convirtio tabs ni reescribio archivos enteros
full = subprocess.run(["git", "diff", "--stat", "--", "rooms/", "scripts/"], cwd=REPO, capture_output=True, text=True).stdout
churn = sum(int(re.search(r"\|\s+(\d+)", x).group(1)) for x in full.splitlines() if "|" in x and "gml" in x)
check(churn <= 40, f"diff total de codigo acotado ({churn} lineas: sin reescritura de archivos enteros)")

print()
print(f"RESULTADO: {PASS} OK / {FAIL} FALLOS")
sys.exit(1 if FAIL else 0)
