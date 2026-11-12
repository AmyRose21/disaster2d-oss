#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_exe_cmd.py — validacion del comando .exe N (fijar tu chance de EXE).

Comandos pedidos por la duena: uno para 1% y otro para 99%. Se implementa
como UN comando parametrizado (.exe N, patron .lobby N) que cubre ambos:
  .exe 1   -> exe_chance = 1  (lobby: "your chance to be exe: 1%")
  .exe 99  -> exe_chance = 99 (domina la loteria ponderada)
  .exe 100 -> garantizado (atajo >= 100 de charselect_pick_exe)

Este script verifica el parche (define + case + help) y simula tanto el
parseo del hash como la loteria ponderada de charselect_pick_exe.
"""
import re, sys, random

REPO = "/home/z/my-project/repo"
ST = f"{REPO}/betterserver-oss/include/States.h"
SV = f"{REPO}/betterserver-oss/disasterserver/states/Server.c"

fails = []
def check(name, cond, detail=""):
    print(f"  [{'OK' if cond else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))
    if not cond:
        fails.append(name)

def cmd_hash(s):
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF   # unsigned int del server
    return h

print("== 1. Define CMD_EXE (States.h) ==")
st = open(ST, encoding="utf-8").read()
m = re.search(r"#define CMD_EXE (\d+)", st)
check("define presente", m is not None)
if m:
    val = int(m.group(1))
    check("valor == hash('.exe')", val == cmd_hash(".exe"), f"{val} vs {cmd_hash('.exe')}")
    # sin colisiones con el resto de CMD_*
    others = {k: int(v) for k, v in re.findall(r"#define (CMD_\w+) (\d+)", st) if k != "CMD_EXE"}
    check("sin colision con otros CMD_*", val not in others.values(),
          f"{len(others)} comandos existentes")

print("\n== 2. Case CMD_EXE (states/Server.c) ==")
sv = open(SV, encoding="utf-8").read()
case = re.search(r"case CMD_EXE:\s*\{(.*?)\n        \}", sv, re.S)
check("case presente en server_cmd_handle", case is not None)
if case:
    body = case.group(1)
    check("gate de operador (v->op)", "if (!v->op)" in body)
    check("parse .exe %d (patron .lobby)", 'sscanf(msg->value, ".exe %d", &chance)' in body)
    check("validacion de rango 1-100", "chance < 1 || chance > 100" in body)
    check("asigna v->exe_chance (cast u8)", "v->exe_chance = (uint8_t)chance;" in body)
    check("re-envia SERVER_LOBBY_EXE_CHANCE (UI al instante)",
          "SERVER_LOBBY_EXE_CHANCE" in body and "packet_write8, v->exe_chance" in body)
    check("confirmacion al jugador", "your exe chance is now" in body)
    check("mensajes de ejemplo y rango", "example:" in body and "between 1 and 100" in body)
# el cheat de brazil (101 garantizado) sigue intacto
check("cheat 'i want big burgr' intacto (Lobby.c)", 
      open(f"{REPO}/betterserver-oss/disasterserver/states/Lobby.c", encoding="utf-8").read().count("exe_chance = 101") == 1)
check("help de operadores incluye .exe",
      re.search(r'"\.exe" CLRCODE_RST " set your exe chance \(1-100\)"', sv) is not None)

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
cc = strip_c(sv)
check("balance de llaves C", cc.count('{') == cc.count('}'), f"{{={cc.count('{')} }}={cc.count('}')}")

print("\n== 3. Simulacion del parseo (server_cmd_parse) ==")
def parse_first_word(msg):
    # misma logica: salta espacios iniciales, corta en el 1er espacio, filtra color codes
    CLRS = set("\\@&/|`~℞")  # CLRLIST (el naranja es multibyte, irrelevante aqui)
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
for probe, want in [(".exe 99", ".exe"), (".exe 1", ".exe"), (".exe99", ".exe99"),
                    ("  .exe 50", ".exe"), (".help", ".help"), (".lobby 3", ".lobby")]:
    w = parse_first_word(probe)
    h = cmd_hash(w)
    tag = "CMD_EXE" if h == cmd_hash(".exe") else "otro"
    print(f"  '{probe}' -> '{w}' -> {tag}")
check(".exe 99 / .exe 1 disparan CMD_EXE",
      all(cmd_hash(parse_first_word(p)) == cmd_hash(".exe") for p in [".exe 99", ".exe 1"]))
check(".exe99 (sin espacio) NO es comando (doc: requiere espacio)",
      cmd_hash(parse_first_word(".exe99")) != cmd_hash(".exe"))

print("\n== 4. Simulacion de la loteria (charselect_pick_exe) ==")
def pick_exe(chances):
    """Replica charselect_pick_exe: garantizado >= 100 primero (orden de
    iteracion), luego loteria ponderada; el elegido resetea a 1."""
    for c in chances:
        if c[1] >= 100:
            return c[0]
    total = sum(c[1] for c in chances) or 1
    rnd = random.randrange(total)
    for name, ch in chances:
        if rnd < ch:
            return name
        rnd -= ch
    return None

random.seed(42)
N = 20000
for setup, label in [
    ([("duena", 99), ("p1", 3), ("p2", 7), ("p3", 12), ("p4", 1)], "duena=.exe 99, resto natural (3/7/12/1)"),
    ([("duena", 1), ("p1", 3), ("p2", 7), ("p3", 12), ("p4", 1)], "duena=.exe 1,  resto natural (3/7/12/1)"),
    ([("duena", 1), ("p2", 1)], "duena=.exe 1, 1 amigo (2 jugadores)"),
    ([("duena", 99), ("p2", 99)], "duena=.exe 99 vs amigo .exe 99 (mitad y mitad)"),
    ([("duena", 100), ("p1", 99), ("p2", 99)], "duena=.exe 100 = GARANTIZADO"),
]:
    wins = sum(1 for _ in range(N) if pick_exe(setup) == "duena")
    pct = wins * 100.0 / N
    print(f"  {label}: duena exe en {pct:.1f}% de {N} rondas")

print(f"\n{'='*60}")
if fails:
    print(f"RESULTADO: {len(fails)} FALLOS -> {fails}")
    sys.exit(1)
print("RESULTADO: TODOS LOS CHECKS OK")
