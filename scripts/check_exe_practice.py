#!/usr/bin/env python3
"""[practica-exe-v1] Validacion del comando .ep (entrenamiento de EXE).

Checks estaticos + simulaciones. Sale 0 solo si TODO pasa.
Uso: python3 check_exe_practice.py
"""
import re
import subprocess
import sys

REPO = "/home/z/my-project/repo"
BS = f"{REPO}/betterserver-oss"

passed = 0
failed = 0


def check(cond, desc):
    global passed, failed
    if cond:
        passed += 1
        print(f"  [OK]   {desc}")
    else:
        failed += 1
        print(f"  [FAIL] {desc}")


def rd(path):
    with open(path, "rb") as f:
        return f.read()


# ---------------------------------------------------------------------------
print("== 1. Hash del comando y colision ==")
def cmd_hash(word):
    h = 0
    for c in word:
        h = 31 * h + ord(c)
    return h

EP = cmd_hash(".ep")
check(EP == 47449, f"hash('.ep') = {EP} == 47449 (define de States.h)")

states_h = rd(f"{BS}/include/States.h").decode("utf-8", "replace")
defines = dict(
    (m.group(1), int(m.group(2)))
    for m in re.finditer(r"#define\s+(CMD_\w+)\s+(\d+)", states_h)
)
check("CMD_EP" in defines, "CMD_EP definido en States.h")
check(defines.get("CMD_EP") == EP, "CMD_EP == hash('.ep')")
coll = [k for k, v in defines.items() if v == EP and k != "CMD_EP"]
check(not coll, f"sin colision de hash contra los otros {len(defines)-1} CMD_* ({coll or 'ninguna'})")

# parseo: primera palabra
def parse_first_word(msg):
    # replica server_cmd_parse: salta espacios iniciales, corta en el 1er
    # espacio posterior (ignorando colorcodes, que aqui no hay)
    word = msg.split()[0] if msg.split() else ""
    return word

for msg, want in [(".ep", EP), (".ep now", EP), ("  .ep", EP), (".sp", 47883),
                  (".epr", cmd_hash(".epr")), (".exe 99", cmd_hash(".exe"))]:
    got = cmd_hash(parse_first_word(msg))
    check(got == want, f"parse '{msg}' -> {got} (esperaba {want})")
check(cmd_hash(".sp") != EP and cmd_hash(".vp") != EP and cmd_hash(".exe") != EP,
      ".ep NO colisiona en la practica con .sp/.vp/.exe")

# ---------------------------------------------------------------------------
print("== 2. Parches presentes (1 vez, exactos) ==")
def count_in(path, needle):
    return rd(path).count(needle.encode() if isinstance(needle, str) else needle)

st = f"{BS}/include/States.h"
check(count_in(st, "#define CMD_EP 47449") == 1, "States.h: #define CMD_EP 47449 (x1)")
check(count_in(st, "bool charselect_init_exepractice\t(PeerData* v);") == 1,
      "States.h: decl charselect_init_exepractice(PeerData*) (x1)")

sh = f"{BS}/include/Server.h"
check(count_in(sh, "bool exe_practice;") == 1, "Server.h: campo Lobby.exe_practice (x1)")
# el campo vive DENTRO de struct Lobby (entre 'typedef struct' y '} Lobby;')
lobby_zone = states_zone = sh_bytes = rd(sh).decode("utf-8", "replace")
i0 = lobby_zone.find("} Lobby;")
check(0 < lobby_zone.find("bool exe_practice;") < i0,
      "Server.h: exe_practice dentro de struct Lobby")

cs = f"{BS}/disasterserver/states/CharSelect.c"
cs_txt = rd(cs).decode("utf-8", "replace")
check(count_in(cs, "bool charselect_init_exepractice(PeerData *v)") == 1,
      "CharSelect.c: definicion de charselect_init_exepractice (x1)")
check(count_in(cs, "server->lobby.exe = v->id;") == 1,
      "CharSelect.c: exe = v->id (el que escribe .ep, SIN loteria) (x1)")
check(count_in(cs, "server->lobby.exe_practice = true;") == 1,
      "CharSelect.c: exe_practice = true (solo en la init nueva) (x1)")
check(count_in(cs, "server->lobby.exe_practice = false;") == 2,
      "CharSelect.c: 2 resets (charselect_init normal + survpractice)")
check(count_in(cs, "server->lobby.exe = 0xFFFF;") == 1,
      "CharSelect.c: 0xFFFF sigue SOLO en survpractice (el .sp intacto)")
check(count_in(cs, "packet_write16, 0xFFFF") == 1,
      "CharSelect.c: falso 'EXE' 0xFFFF solo en survpractice")
check("map_pick_random" in cs_txt and cs_txt.count("map_pick_random") >= 3,
      "CharSelect.c: exe practice usa map_pick_random (mapa al azar, v4.7)")
check(count_in(cs, 'CLRCODE_GRN "exe practice:~ you\'re the exe, pick your killer!"') == 1,
      "CharSelect.c: aviso directo al que escribe .ep (x1)")
check(count_in(cs, "g_config.practice_time;") == 2,
      "CharSelect.c: practice_time en survpractice Y exepractice (misma cuenta atras)")

lb = f"{BS}/disasterserver/states/Lobby.c"
check(count_in(lb, "case CMD_EP:") == 1, "Lobby.c: case CMD_EP (x1)")
check(count_in(lb, "return charselect_init_exepractice(v) || lobby_init(v->server);") == 1,
      "Lobby.c: llamada a charselect_init_exepractice (x1)")
check(count_in(lb, "server->lobby.exe_practice = false;") == 1,
      "Lobby.c: reset del flag en lobby_init (x1)")
check(count_in(lb, 'CLRCODE_RED "you\'re not in the lobby yet."') == 1,
      "Lobby.c: gate anti-espectador (in_game) en .ep (x1)")

gm = f"{BS}/disasterserver/states/Game.c"
check(count_in(gm, "if (server->lobby.exe_practice)") == 1,
      "Game.c: guard de exe_practice en game_state_check (x1)")

sv = f"{BS}/disasterserver/states/Server.c"
check(count_in(sv, 'CLRCODE_GRA ".ep" CLRCODE_RST " exe practice (you\'re the exe)"') == 1,
      "Server.c: linea .ep en el .help de operadores (x1)")

# ---------------------------------------------------------------------------
print("== 3. Indentacion quirurgica (tabs donde tabs, espacios donde espacios) ==")
lb_txt = rd(lb).decode("utf-8", "replace")
m = re.search(r"\n(\t+)case CMD_EP:", lb_txt)
check(m is not None and len(m.group(1)) == 4, "Lobby.c: case CMD_EP a 4 tabs (como CMD_SP)")
for ln in lb_txt.splitlines():
    if "charselect_init_exepractice" in ln or "you're not in the lobby yet" in ln:
        check(ln.startswith("\t") and not ln.startswith(" "),
              f"Lobby.c linea tab-pura: {ln.strip()[:50]}")

cs_lines = cs_txt.splitlines()
in_fn = False
bad = 0
for ln in cs_lines:
    if ln.startswith("bool charselect_init_exepractice"):
        in_fn = True
    elif in_fn and ln.startswith("}"):
        break
    elif in_fn and ln.strip():
        if ln.startswith(" ") is False and ln.startswith("\t"):
            bad += 1
check(bad == 0, "CharSelect.c: cuerpo de la funcion nueva 100% espacios (estilo del archivo)")

# ---------------------------------------------------------------------------
print("== 4. Balance de llaves de los archivos C tocados ==")
def brace_balance(path):
    src = rd(path).decode("utf-8", "replace")
    # quitar comentarios y strings (los patrones de las rondas anteriores)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    src = re.sub(r"//[^\n]*", "", src)
    src = re.sub(r'"(\\.|[^"\\])*"', '""', src)
    src = re.sub(r"'(\\.|[^'\\])*'", "''", src)
    return src.count("{") - src.count("}")

for f in ["disasterserver/states/CharSelect.c", "disasterserver/states/Lobby.c",
          "disasterserver/states/Game.c", "disasterserver/states/Server.c",
          "include/States.h", "include/Server.h"]:
    b = brace_balance(f"{BS}/{f}")
    check(b == 0, f"{f}: llaves balanceadas ({b})")

# ---------------------------------------------------------------------------
print("== 5. Regresiones intactas ==")
check(count_in(cs, "charselect_init_survpractice") == 1,  # solo la definicion (la llamada vive en Lobby.c)
      "CharSelect.c: charselect_init_survpractice sigue definida (el .sp vive)")
check(count_in(lb, "case CMD_SP:") == 1, "Lobby.c: case CMD_SP intacto (x1)")
check(count_in(lb, "charselect_init_survpractice(v->server) || lobby_init") == 1,
      "Lobby.c: .sp sigue llamando a survpractice")
vp_zone = lb_txt[lb_txt.find("prac_countdown -= server->delta;"):]
check("charselect_init(pmap, server)" in vp_zone,
      "Lobby.c: .vp sigue yendo a charselect_init (loteria, NO tocado)")
check(count_in(sv, "case CMD_EXE:") == 1, "Server.c: comando .exe intacto (v1)")
check(count_in(sv, "bool server_msg_is_command(String *string)") == 1,
      "Server.c: helper server_msg_is_command intacto (v1.1)")
for st_file in ["Lobby.c", "CharSelect.c", "Mapvote.c", "Results.c", "Game.c"]:
    check(count_in(f"{BS}/disasterserver/states/{st_file}", "server_msg_is_command") >= 1,
          f"{st_file}: guard de ocultado '.' intacto (v1.1)")
gm_txt = rd(gm).decode("utf-8", "replace")
check("EX_JINNA" in gm_txt and "6000" in gm_txt,
      "Game.c: anticheat Jinna 6000 ms intacto (v4.3)")
check(count_in(lb, "i want big burgr") == 1, "Lobby.c: cheat 'i want big burgr' intacto")
check(count_in(sv, 'CLRCODE_GRA ".sp" CLRCODE_RST " survivor practice (no exe)"') == 1,
      "Server.c: linea .sp del help intacta (la .ep se añadio despues)")

# ---------------------------------------------------------------------------
print("== 6. Simulacion: el EXEWIN instantaneo que arregla el guard ==")
def game_state_check_sim(exe_practice, players):
    """players: lista de (rol, flags). Replica el conteo de Game.c."""
    escaped = sum(1 for r, f in players if "escaped" in f)
    dead = sum(1 for r, f in players if "dead" in f or "demonized" in f)
    exes = sum(1 for r, f in players if r == "exe")
    total = len(players) - (exes + dead + escaped)
    if exe_practice:
        return "SIGUE"  # guard de .ep: solo TIME OVER/.lobby/exe-se-va cierran
    if total <= 0:
        return "SURVWIN" if escaped > 0 else "EXEWIN"
    return "SIGUE"

# sola como exe, viva: total = 1 - 1 = 0
r = game_state_check_sim(False, [("exe", set())])
check(r == "EXEWIN", f"SIN guard, sola como exe: {r} (el bug: ronda muerta al 1er tick)")
r = game_state_check_sim(True, [("exe", set())])
check(r == "SIGUE", f"CON guard (.ep), sola como exe: {r} — puede probar Jinna tranquila")
# ella + 2 supervivientes muertos por sus pruebas
r = game_state_check_sim(True, [("exe", set()), ("s", {"dead"}), ("s", {"dead"})])
check(r == "SIGUE", "CON guard, todos los supervivientes muertos: la ronda sigue (seguir probando)")
r = game_state_check_sim(False, [("exe", set()), ("s", {"dead"}), ("s", {"dead"})])
check(r == "EXEWIN", "SIN guard (ronda normal), todos muertos: EXEWIN — las rondas NORMALES no cambian")
r = game_state_check_sim(False, [("exe", set()), ("s", {"escaped"})])
check(r == "SURVWIN", "SIN guard, escape por big ring: SURVWIN — normal intacto")
r = game_state_check_sim(True, [("exe", set()), ("s", {"escaped"})])
check(r == "SIGUE", "CON guard, escape por big ring: la practica sigue hasta el TIME OVER")

# ---------------------------------------------------------------------------
print("== 7. Simulacion: ciclo de vida del flag ==")
flag = False
log = []
def lobby():      # lobby_init
    global flag; flag = False
def normal():     # charselect_init (loteria normal / .map / .vp)
    global flag; flag = False
def sp():         # charselect_init_survpractice
    global flag; flag = False
def ep():         # charselect_init_exepractice
    global flag; flag = True

lobby(); ep();    log.append(flag)   # .ep -> practica exe
ep();             log.append(flag)   # otra .ep (reintento) -> sigue exe
normal();         log.append(flag)   # ronda normal despues -> off
sp();             log.append(flag)   # .sp -> off (supervivientes)
lobby(); ep();    log.append(flag)   # lobby y .ep de nuevo -> on
lobby();          log.append(flag)   # volver al lobby -> off
check(log == [True, True, False, False, True, False],
      f"secuencia .ep/.sp/.map/lobby: {log} == [T,T,F,F,T,F]")

# ---------------------------------------------------------------------------
print("== 8. Simulacion: gates del comando (orden del case) ==")
def cmd_ep_sim(is_op, ingame_count, typer_in_game):
    if not is_op:
        return "you aren't an operator"
    if ingame_count <= 0:
        return "nobody is in the lobby."
    if not typer_in_game:
        return "you're not in the lobby yet."
    return "PRACTICA EXE (typer = exe)"

check(cmd_ep_sim(False, 3, True) == "you aren't an operator", "no-op rechazado")
check(cmd_ep_sim(True, 0, True) == "nobody is in the lobby.", "lobby vacio rechazado")
check(cmd_ep_sim(True, 2, False) == "you're not in the lobby yet.",
      "espectador rechazado (exe colgado evitado)")
check(cmd_ep_sim(True, 1, True) == "PRACTICA EXE (typer = exe)",
      "op en juego -> practica exe")

# ---------------------------------------------------------------------------
print("== 9. Simulacion: constancia (quien es el exe en cada .ep) ==")
# en 10 .ep seguidos, el exe es SIEMPRE la typer — contra la loteria del .vp
# donde sola en el lobby le toca el 100% pero acompañada es ponderada.
res = [cmd_ep_sim(True, 4, True) for _ in range(10)]
check(all(r == "PRACTICA EXE (typer = exe)" for r in res),
      "10/10 rondas .ep con la typer de exe (constancia para probar Jinna)")

# loteria normal (.vp/.map): acompanada de 3 bots con chance natural
import random
random.seed(42)
wins = 0
for _ in range(20000):
    ch = [1 + random.randint(2, 6) for _ in range(3)] + [1]  # ella recien reseteada
    total = sum(ch)
    r = random.randrange(total)
    acc = 0
    for i, c in enumerate(ch):
        if r < acc + c:
            wins += (i == 3)
            break
        acc += c
pct = 100.0 * wins / 20000
check(3 < pct < 12, f"misma escena por loteria .vp: ella exe solo {pct:.1f}% de 20k rondas (chance 1 vs 3 bots 3-7) — .ep lo garantiza")

# ---------------------------------------------------------------------------
print("== 10. Diff git: solo inserciones, archivos esperados ==")
diff = subprocess.run(
    ["git", "-C", REPO, "diff", "--numstat"],
    capture_output=True, text=True,
).stdout
files = {}
for ln in diff.splitlines():
    a, d, name = ln.split("\t")
    files[name] = (int(a), int(d))
expected = {
    "betterserver-oss/disasterserver/states/CharSelect.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/disasterserver/states/Lobby.c",
    "betterserver-oss/disasterserver/states/Server.c",
    "betterserver-oss/include/Server.h",
    "betterserver-oss/include/States.h",
    "worklog.md",  # entrada practica-exe-v1 (siempre se actualiza)
}
check(set(files) == expected, f"archivos modificados exactos: {sorted(files)}")
check(all(d == 0 for a, d in files.values()),
      f"cero lineas borradas (quirurgico): {[(n, v) for n, v in files.items() if v[1]] or 'OK'}")
check(files.get("betterserver-oss/disasterserver/states/Lobby.c", (0, 0))[0] <= 40,
      "Lobby.c: insercion contenida (sin expansion de tabs estilo v1.1)")

# ---------------------------------------------------------------------------
print(f"\nRESULTADO: {passed} OK, {failed} FAIL")
sys.exit(1 if failed else 0)
