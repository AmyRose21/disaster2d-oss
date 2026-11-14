#!/usr/bin/env python3
"""[fix-nega-v16] Validacion: crash is_ds_list en resultados + fin de ronda
al convertir a todos en nega (incluido el entrenamiento .ep).

Checks estaticos + simulaciones 1:1 de la logica C. Sale 0 solo si TODO pasa.
Uso: python3 scripts/check_fix_nega_v16.py
"""
import sys

BS = "betterserver-oss"
NSR = f"scripts/net_state_results/net_state_results.gml"
NSG = f"scripts/net_state_game/net_state_game.gml"
GC = f"{BS}/disasterserver/states/Game.c"
PH = f"{BS}/include/Player.h"

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
        return f.read().decode("utf-8")


def code_only(src):
    """Lineas sin comentarios // (para contar solo codigo ejecutable)."""
    out = []
    for line in src.splitlines():
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        out.append(line)
    return "\n".join(out)


# ---------------------------------------------------------------------------
print("== 1. CRASH is_ds_list (cliente) ==")
nsr = rd(NSR)
nsg = rd(NSG)

check("is_ds_list(" not in code_only(nsr),
      "net_state_results.gml: cero is_ds_list( ejecutable (quedaba en la linea 26 y mataba la PRIMERA fila: el resto de la lista nunca se creaba)")
check("is_ds_list(" not in code_only(nsg),
      "net_state_game.gml: cero is_ds_list( ejecutable (el de v14 reventaba en la SEGUNDA ronda de la misma sesion)")
check(nsr.count("ds_exists(global.resultsNegaNicks, ds_type_list)") == 1,
      "net_state_results.gml: ds_exists(global.resultsNegaNicks, ds_type_list) x1 (patron ds_exists de obj_netclient.players)")
check(nsg.count("ds_exists(global.resultsNegaNicks, ds_type_list)") == 1,
      "net_state_game.gml: ds_exists(global.resultsNegaNicks, ds_type_list) x1")

for path, src in ((NSR, nsr), (NSG, nsg)):
    def strip_sc(s):
        out, i, n = [], 0, len(s)
        while i < n:
            c = s[i]
            if c == "/" and i + 1 < n and s[i + 1] == "/":
                while i < n and s[i] != "\n":
                    i += 1
            elif c == "/" and i + 1 < n and s[i + 1] == "*":
                i += 2
                while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                    i += 1
                i += 2
            elif c in "\"'":
                q = c
                i += 1
                while i < n and s[i] != q:
                    if s[i] == "\\":
                        i += 1
                    i += 1
                i += 1
            else:
                out.append(c)
                i += 1
        return "".join(out)

    s = strip_sc(src)
    check(s.count("{") == s.count("}") and s.count("(") == s.count(")") and s.count("[") == s.count("]"),
          f"{path.split('/')[-1]}: llaves/parentesis/corchetes balanceados")

# ---------------------------------------------------------------------------
print("== 2. FLAG PLAYER_NEGATIZED (server) ==")
ph = rd(PH)
check(ph.count("PLAYER_NEGATIZED = 0x1 << 8") == 1,
      "Player.h: PLAYER_NEGATIZED = 0x1 << 8 x1 (PlayerFlags es enum C = int: 256 cabe)")
check("PLAYER_CAUGHT = 0x1 << 7," in ph,
      "Player.h: PLAYER_CAUGHT conserva su comma (la lista del enum sigue valida)")

# ---------------------------------------------------------------------------
print("== 3. MARCAS DE CONVERSION (Game.c) ==")
gc = rd(GC)
check(gc.count("SET_FLAG(v->plr.flags, PLAYER_NEGATIZED);") == 1,
      "Game.c CLIENT_JINNA_NEGATOUCH: SET_FLAG(v->plr.flags, PLAYER_NEGATIZED) x1 (negatouch = conversion NEGA)")
check(gc.count("SET_FLAG(t->plr.flags, PLAYER_NEGATIZED);") == 1,
      "Game.c CLIENT_JINNA_MINION: SET_FLAG(t->plr.flags, PLAYER_NEGATIZED) x1 (el minion invocado tambien es nega desde v9)")
check(gc.count("RAssert(game_state_check(v->server));") >= 7,
      f"Game.c: game_state_check presente en los 7 flujos (left/escaped/death x3/negatouch/minion): {gc.count('RAssert(game_state_check(v->server));')}")
check(gc.find("server_broadcast(v->server, &pack4, true);") < gc.find("RAssert(game_state_check(v->server));", gc.find("CLIENT_JINNA_MINION:")),
      "Game.c CLIENT_JINNA_MINION: el check va DESPUES del broadcast (los clientes aplican la invocacion antes del EXE_WINS)")

# ---------------------------------------------------------------------------
print("== 4. GUARD DE PRACTICA .ep (game_state_check) ==")
guard = gc[gc.find("if (server->lobby.exe_practice)"):gc.find("uint8_t escaped = 0;")]
check("PLAYER_NEGATIZED" in guard and "others > 0 && negas == others" in guard,
      "game_state_check: la practica cierra SOLO si TODOS los demas estan convertidos a nega (others > 0 && negas == others)")
check("game_end(server, ED_EXEWIN, true)" in guard,
      "game_state_check: el cierre de practica es ED_EXEWIN (exe win, mismo flujo de resultados)")
check(guard.count("if (v->id == server->game.exe)") >= 1 and "v->plr.flags & PLAYER_NEGATIZED" in guard,
      "game_state_check: el exe se excluye del conteo y los nega se cuentan por PLAYER_NEGATIZED (no por DEMONIZED)")

# ---------------------------------------------------------------------------
print("== 5. SIMULACIONES 1:1 (logica espejo de game_state_check) ==")

def simulate(practice, players, end_already=False, exe_practice=None):
    """players: lista de (is_exe, DEAD, DEMONIZED, ESCAPED, CAUGHT, NEGATIZED).
    Espejo exacto de game_state_check: devuelve el ending o None."""
    if end_already:
        return "NONE (ya acabando)"
    if practice:
        others = negas = 0
        for (exe, dead, dem, esc, caught, nega) in players:
            if exe:
                continue
            others += 1
            if nega:
                negas += 1
        if others > 0 and negas == others:
            return "EXEWIN"
        return None
    escaped = dead = exes = 0
    ingame = len(players)
    for (exe, dead_, dem, esc, caught, nega) in players:
        if esc:
            escaped += 1
        if dead_ or dem or caught:
            dead += 1
        if exe:
            exes += 1
    total = ingame - (exes + dead + escaped)
    if total <= 0:
        return "SURVWIN" if escaped > 0 else "EXEWIN"
    return None


EXE = (True, False, False, False, False, False)
def surv(**kw):
    return (False, kw.get("dead", False), kw.get("dem", False), kw.get("esc", False),
            kw.get("caught", False), kw.get("nega", False))

# .ep: exe + 1 surv que se convierte con negatouch -> cierra (EL BUG REPORTADO)
check(simulate(True, [EXE, surv(dem=True, nega=True)]) == "EXEWIN",
      ".ep exe+1: convertirla con negatouch (DEMONIZED+NEGATIZED) -> EXEWIN (el bug reportado)")
# .ep: exe + 1 surv viva -> no cierra
check(simulate(True, [EXE, surv()]) is None,
      ".ep exe+1 viva -> sigue abierta")
# .ep: exe + 1 surv muerta (esbirro comun: DEMONIZED sin NEGATIZED) -> NO cierra (comportamiento aprobado)
check(simulate(True, [EXE, surv(dead=True)]) is None,
      ".ep exe+1 muerta -> sigue abierta (practica intacta)")
check(simulate(True, [EXE, surv(dem=True)]) is None,
      ".ep exe+1 esbirro comun (DEMONIZED sin NEGATIZED) -> sigue abierta")
# .ep: exe sola -> no cierra (total 0 al primer tick)
check(simulate(True, [EXE]) is None,
      ".ep exe SOLA -> sigue abierta (sin EXEWIN instantaneo)")
# .ep: exe + 2, una nega y una viva -> no; las dos nega -> si
check(simulate(True, [EXE, surv(dem=True, nega=True), surv()]) is None,
      ".ep exe+2 (1 nega + 1 viva) -> sigue abierta")
check(simulate(True, [EXE, surv(dem=True, nega=True), surv(caught=True, nega=True)]) == "EXEWIN",
      ".ep exe+2 (nega + atrapada-nega del portal) -> EXEWIN")
# .ep: escape por big ring -> sigue abierta (escenario aprobado del check_exe_practice)
check(simulate(True, [EXE, surv(esc=True), surv()]) is None,
      ".ep escape por big ring -> sigue abierta")
# .ep: exe + 2, una muerta y una nega -> NO cierra (la muerta no es nega)
check(simulate(True, [EXE, surv(dead=True), surv(dem=True, nega=True)]) is None,
      ".ep exe+2 (1 muerta + 1 nega) -> sigue abierta")
# NORMAL: exe + ultima surv convertida -> EXEWIN (fix v15 intacto)
check(simulate(False, [EXE, surv(dem=True, nega=True)]) == "EXEWIN",
      "normal exe+1: ultima convertida -> EXEWIN (fix v15 intacto)")
# NORMAL: exe + ultima surv atrapada+invocada -> EXEWIN (nuevo check del summon)
check(simulate(False, [EXE, surv(dem=True, nega=True)]) == "EXEWIN"
      and simulate(False, [EXE, surv(caught=True)]) == "EXEWIN",
      "normal exe+1: ultima ATRAPADA (PLAYER_CAUGHT cuenta como caida) -> EXEWIN al invocar/check")
# NORMAL: exe + 2 vivas -> sigue
check(simulate(False, [EXE, surv(), surv()]) is None,
      "normal exe+2 vivas -> sigue abierta")
# NORMAL: escape de la ultima -> SURVWIN
check(simulate(False, [EXE, surv(esc=True)]) == "SURVWIN",
      "normal exe+1 escapada -> SURVWIN (flujo escape intacto)")

# ---------------------------------------------------------------------------
print("== 6. RESULTADOS: sin regresiones del v15 ==")
check(nsr.count("_nameLookup") >= 4,
      "net_state_results.gml: el recorte del espacio final (_nameLookup) sigue presente (cubre servers viejos)")
check("ds_list_find_index(global.resultsNegaNicks, _nameLookup)" in nsr,
      "net_state_results.gml: busqueda nega por nick recortado intacta")

print()
print(f"TOTAL: {passed} OK / {failed} FAIL")
sys.exit(1 if failed else 0)
