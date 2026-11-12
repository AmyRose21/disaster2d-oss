#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_dot_hidden.py — validacion de exe-cmd-v1.1: los comandos '.' no se
ven para los demas.

Que hace el parche: los comandos CONOCIDOS ya estaban ocultos (server_cmd_handle
devuelve true y el estado no hace broadcast). El hueco eran los mensajes '.'
que el server NO conoce (typos tipo ".exe99", puntos suspensivos, comandos
sin registrar): caian al broadcast como chat normal. El parche anade
server_msg_is_command() y un guard en los 5 estados con chat: lo que arranque
en '.' jamas se reenvia, lo reconozca el server o no.

Este script verifica el parche y simula el helper + la decision de broadcast
de cada estado (antes vs despues).
"""
import re, sys

REPO = "/home/z/my-project/repo"
BASE = f"{REPO}/betterserver-oss"
ST = f"{BASE}/include/States.h"
SH = f"{BASE}/include/Server.h"
STATES = ["Server", "Lobby", "CharSelect", "Mapvote", "Results", "Game"]
PATHS = {n: f"{BASE}/disasterserver/states/{n}.c" for n in STATES}

fails = []
def check(name, cond, detail=""):
    print(f"  [{'OK' if cond else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))
    if not cond:
        fails.append(name)

def rd(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

# ---------------------------------------------------------------- 1. helper
print("== 1. Helper server_msg_is_command (Server.c + Server.h) ==")
sh = rd(SH)
check("Server.h declara la funcion",
      "bool server_msg_is_command(String *string);" in sh)

sv = rd(PATHS["Server"])
m = re.search(
    r"bool server_msg_is_command\(String \*string\)\s*\{(.*?)\n\}",
    sv, re.S)
check("Server.c define la funcion", m is not None)
if m:
    body = m.group(1)
    check("recorre string->len con isspace skip",
          "for (int i = 0; i < string->len; i++)" in body
          and "isspace((unsigned char)string->value[i])" in body
          and "continue;" in body)
    check("devuelve value[i] == '.' en el 1er no-espacio",
          "return string->value[i] == '.';" in body)
    check("return false si no hay puntos (fin de loop)", "return false;" in body)

pos_parse = sv.find("unsigned long server_cmd_parse")
pos_helper = sv.find("bool server_msg_is_command")
pos_handle = sv.find("bool server_cmd_handle")
check("helper entre server_cmd_parse y server_cmd_handle",
      0 < pos_parse < pos_helper < pos_handle)

# ------------------------------------------------------- 2. guards x estado
print("\n== 2. Guard en los 5 estados con chat ==")
GUARD_SIMPLE = "if (!server_cmd_handle(v->server, server_cmd_parse(&msg), v, &msg) && g_config.chatfix && !server_msg_is_command(&msg))"
GUARD_GAME = "if (server_msg_is_command(&msg))"

srcs = {n: rd(PATHS[n]) for n in STATES}

check("Lobby.c: guard en el broadcast (!ignore ...)",
      srcs["Lobby"].count("\t\t\tif (!ignore && g_config.chatfix && !server_msg_is_command(&msg))") == 1)
for n in ["CharSelect", "Mapvote", "Results"]:
    check(f"{n}.c: guard en el broadcast (cmd_handle ... &&)",
          srcs[n].count(GUARD_SIMPLE) == 1)
check("Game.c: break temprano con el helper",
      srcs["Game"].count(GUARD_GAME) == 1)

gpos = srcs["Game"].find(GUARD_GAME)
cpos = srcs["Game"].find("if (server_cmd_handle(v->server, server_cmd_parse(&msg), v, &msg))")
check("Game.c: el guard corre DESPUES de server_cmd_handle (respuestas privadas)",
      0 < cpos < gpos)

for n in ["Lobby", "CharSelect", "Mapvote", "Results", "Game"]:
    check(f"{n}.c: comentario [exe-cmd-v1.1]", "[exe-cmd-v1.1]" in srcs[n])

# indentacion preservada (el editor de la sesion expandia tabs -> espacios)
for n in ["Lobby", "Mapvote", "Results"]:
    line = [l for l in srcs[n].splitlines() if "server_msg_is_command" in l and "if (" in l][0]
    check(f"{n}.c: linea del guard indentada con TABS (sin expansion)",
          line.startswith("\t\t\t"), repr(line[:12]))
for n in ["CharSelect", "Game"]:
    line = [l for l in srcs[n].splitlines() if "server_msg_is_command" in l and "if (" in l][0]
    check(f"{n}.c: linea del guard indentada con espacios",
          not line.startswith("\t") and line.startswith(" " * 16), repr(line[:12]))

# ------------------------------------------------------------- 3. integridad
print("\n== 3. Integridad y regresiones ==")
def strip_c(code):
    out, i, n = [], 0, len(code)
    while i < n:
        c = code[i]
        if c == '/' and i+1 < n and code[i+1] == '/':
            while i < n and code[i] != '\n': i += 1
        elif c == '/' and i+1 < n and code[i+1] == '*':
            i += 2
            while i+1 < n and not (code[i] == '*' and code[i+1] == '/'): i += 1
            i += 2
        elif c == '"':
            i += 1
            while i < n and code[i] != '"':
                if code[i] == '\\': i += 1
                i += 1
            i += 1
        else:
            out.append(c); i += 1
    return ''.join(out)

for n in STATES:
    cc = strip_c(srcs[n])
    check(f"{n}.c: balance de llaves", cc.count('{') == cc.count('}'),
          f"{{={cc.count('{')} }}={cc.count('}')}")

# regresion v1: el comando .exe sigue vivo
check("CMD_EXE sigue definido (States.h)", re.search(r"#define CMD_EXE \d+", rd(ST)) is not None)
check("case CMD_EXE sigue en Server.c", "case CMD_EXE:" in srcs["Server"])
check("help de operadores sigue listando .exe", 'set your exe chance (1-100)' in srcs["Server"])
# regresion upstream: cheat y salidas publicas por diseno
check("cheat 'i want big burgr' intacto (Lobby.c)", srcs["Lobby"].count("exe_chance = 101") == 1)
check("salida publica de .stink intacta (Server.c)",
      'RAssert(server_broadcast_msg(v->server, 0, format));' in srcs["Server"])
check("anuncios de votekick intactos (Lobby.c)",
      srcs["Lobby"].count('"voted~."') >= 2)

# --------------------------------------------------- 4. simulacion del helper
print("\n== 4. Simulacion de server_msg_is_command ==")
def is_cmd(msg):
    for ch in msg:
        if ch.isspace():
            continue
        return ch == '.'
    return False

for probe, want in [(".exe 99", True), (".exe 1", True), (".exe99", True),
                    ("  .exe 50", True), ("...", True), (".mute", True),
                    ("hola", False), ("hola.exe", False), ("", False),
                    (" . ", True), (".exe 99 jeje", True)]:
    check(f"is_cmd({probe!r}) == {want}", is_cmd(probe) == is_cmd(probe) and is_cmd(probe) == want)

# --------------------------------------- 5. broadcast por estado: antes/despues
print("\n== 5. Broadcast por estado — ANTES vs DESPUES del parche ==")
def cmd_hash(s):
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF
    return h

def parse_first_word(msg):
    CLRS = set("\\@&/|`~\u211e")
    word, started = "", False
    for ch in msg:
        if not started and ch.isspace():
            continue
        started = True
        if ch.isspace():
            break
        if ch in CLRS:
            continue
        word += ch
    return word

# set de hashes que server_cmd_handle reconoce (case CMD_* del switch)
defines = {k: int(v) for k, v in re.findall(r"#define (CMD_\w+) (\d+)", rd(ST))}
handle_body = sv[sv.find("bool server_cmd_handle"):sv.find("\nbool ", sv.find("bool server_cmd_handle") + 10)]
handled_server = {defines[n] for n in re.findall(r"case (CMD_\w+):", handle_body) if n in defines}
# casos explicitos del switch del chat en Lobby.c (CMD_MAP, CMD_SP, ...)
lob = srcs["Lobby"]
chat_blk = lob[lob.find("case CLIENT_CHAT_MESSAGE:"):lob.find("Info(\"%s \" LOG_RST")]
handled_lobby_extra = {defines[n] for n in re.findall(r"case (CMD_\w+):", chat_blk) if n in defines}

def handled(msg, lobby=False):
    if lobby and "i want big burgr" in msg:   # rama cheat SOLO en Lobby.c (return true)
        return True
    h = cmd_hash(parse_first_word(msg))
    return h in handled_server or (lobby and h in handled_lobby_extra)

def old_broadcast(state, msg):
    if state == "lobby":
        return not handled(msg, lobby=True)            # chatfix=true
    return not handled(msg, lobby=False)               # charselect/mapvote/results/game

def new_broadcast(state, msg):
    return old_broadcast(state, msg) and not is_cmd(msg)

STATES_SIM = ["lobby", "charselect", "mapvote", "game", "results"]
CASES = [".exe 99", ".exe 1", ".exe 100", ".exe99 (typo)", "  .exe 99", ".map 3",
         ".kick amy", ".yes", ".stink baller", "hola que tal", "gg",
         "i want big burgr", "hola.exe"]

print(f"  {'mensaje':<20} " + " ".join(f"{s[:9]:>11}" for s in STATES_SIM))
regresiones = 0
for msg in CASES:
    raw = msg.split(" (typo)")[0]
    row_old = [old_broadcast(s, raw) for s in STATES_SIM]
    row_new = [new_broadcast(s, raw) for s in STATES_SIM]
    cells = []
    for o, nw in zip(row_old, row_new):
        cells.append(f"{'SI' if o else '-':>4}->{'SI' if nw else '-':<6}")
    print(f"  {msg:<20} " + " ".join(f"{c:>11}" for c in cells))
    # invariantes
    for s, o, nw in zip(STATES_SIM, row_old, row_new):
        if nw and not o:
            regresiones += 1   # nunca debe EMPEZAR a broadcastear algo que no broadcasteaba
        if is_cmd(raw) and nw:
            regresiones += 1   # ningun mensaje '.' puede broadcastearse

check("cero comandos '.' broadcasteados y cero chats normales nuevos ocultos...",
      regresiones == 0, f"infracciones={regresiones}")

# demo explicita del hueco tapado
check("ANTES: el typo '.exe99' se veia para los demas (bug)",
      old_broadcast("lobby", ".exe99") is True)
check("DESPUES: el typo '.exe99' ya no se ve para los demas",
      new_broadcast("lobby", ".exe99") is False)
check("comandos conocidos (.exe 99) ya estaban ocultos y siguen ocultos",
      old_broadcast("lobby", ".exe 99") is False and new_broadcast("lobby", ".exe 99") is False)
check("'.map 3' en charselect (solo existe en lobby) antes se veia, ahora no",
      old_broadcast("charselect", ".map 3") is True and new_broadcast("charselect", ".map 3") is False)
check("el chat normal sigue broadcasteandose en los 5 estados",
      all(new_broadcast(s, "hola que tal") for s in STATES_SIM))

print(f"\n{'='*60}")
if fails:
    print(f"RESULTADO: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK")
