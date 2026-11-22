#!/usr/bin/env python3
# check_v71.py — verificación de regla 6 para v71 (escudo de burbuja para TODOS).
# Chequea los 25 archivos GML editados + la superficie de red (regla 7) + que
# NADA del .yyp/.yy/.resource_order cambió (regla 6) + una simulación de la
# lógica nueva (crash-path de obj_amy_canon, countdown, absorción de golpe).
import subprocess, sys

REPO = "/home/z/my-project/disaster2d-oss"
fails = 0

def check(name, cond, detail=""):
    global fails
    print(f"  [{'OK' if cond else 'FAIL'}] {name}{' — ' + str(detail) if detail and not cond else ''}")
    if not cond:
        fails += 1

def load(rel):
    with open(f"{REPO}/{rel}", encoding="utf-8") as f:
        return f.read()

def bal(txt, a="{", b="}"):
    """Balance de un delimitador fuera de comentarios/strings (lexer GML)."""
    depth, in_str, i = 0, None, 0
    while i < len(txt):
        c = txt[i]
        if in_str:
            if c == "\\" and in_str == '"':
                i += 2; continue
            if c == in_str:
                in_str = None
        elif c == '"':
            in_str = '"'
        elif c == "'":
            in_str = "'"
        elif c == "/" and txt[i:i+2] == "//":
            j = txt.find("\n", i); i = j if j != -1 else len(txt); continue
        elif c == "/" and txt[i:i+2] == "/*":
            j = txt.find("*/", i); i = (j + 2) if j != -1 else len(txt); continue
        elif c == a:
            depth += 1
        elif c == b:
            depth -= 1
        i += 1
    return depth

CHANGED = subprocess.run(["git", "-C", REPO, "diff", "--name-only"],
                         capture_output=True, text=True).stdout.split()
UNTRACKED = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                           capture_output=True, text=True).stdout.splitlines()

print("== A. EL CRASH FIX (net_state_game case 1) ==")
g = load("scripts/net_state_game/net_state_game.gml")
check("lectura SIN guarda fuera (la del crash reportado)",
      "if(global.player.shieldTimer <= 0)" not in g)
check("guarda variable_instance_exists presente (patrón cases 3/4)",
      'if(!variable_instance_exists(global.player, "shieldTimer") || global.player.shieldTimer <= 0)' in g)
check("set con macro ITEMBOX_SHIELD_TIME",
      "global.player.shieldTimer = ITEMBOX_SHIELD_TIME;" in g)
check("las 4 macros ITEMBOX_*_TIME siguen al top (Suite v70 intacto)",
      all(f"#macro ITEMBOX_{m}_" in g for m in ["SHIELD", "INVULN", "ELECTRIC", "BOOTS"]) or
      all(f"#macro ITEMBOX_{n} " in g for n in ["SHIELD_TIME", "INVULN_TIME", "ELECTRIC_TIME", "BOOTS_TIME"]))
check("case 0 anillos y case 2 invencibilidad intactos",
      "global.player.rings = min(global.player.rings + 5, 119);" in g and
      "global.player.hurttime = ITEMBOX_INVULN_TIME;" in g)
check("llaves/paréntesis balanceados", bal(g) == 0 and bal(g, "(", ")") == 0)

print("== B. TICK GENÉRICO (scr_move_basic) ==")
m = load("scripts/scr_move_basic/scr_move_basic.gml")
check("tick shieldTimer presente con guarda",
      'if(variable_instance_exists(id, "shieldTimer") && shieldTimer > 0' in m)
check("skip-list: Sally/SallyCanon/Rouge excluidos (sus specials tickean)",
      m.count("&& global.character != CHARACTER_SALLY\n") == 1 and
      "&& global.character != CHARACTER_SALLY_CANON" in m and
      "&& global.character != CHARACTER_ROUGE" in m)
check("ticks electrico/botas intactos",
      'if(variable_instance_exists(id, "electricShieldTimer") && electricShieldTimer > 0)\n                electricShieldTimer--;' in m and
      'if(variable_instance_exists(id, "bootsTimer") && bootsTimer > 0)' in m)
check("llaves/paréntesis balanceados", bal(m) == 0 and bal(m, "(", ")") == 0)

print("== C. CONSUMO (scr_player_hurt) ==")
h = load("scripts/scr_player_hurt/scr_player_hurt.gml")
check("condición genérica (cualquier personaje)",
      'if(variable_instance_exists(global.player, "shieldTimer") && global.player.shieldTimer > 0)' in h)
check("lectura vieja Sally-gated fuera",
      "if((global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON) && global.player.shieldTimer > 0)" not in h)
check("bloque Rouge duplicado fuera (fusionado arriba)",
      "if(global.character == CHARACTER_ROUGE && global.player.shieldTimer > 0)" not in h)
check("logro de Sally intacto (rSallyShield anidado)",
      "obj_achivements.rSallyShield++;" in h and
      "if(global.character == CHARACTER_SALLY && global.player.revivalTimes < 2 && global.player.hp <= 20)" in h)
check("invuln de rotura SallyCanon intacta",
      "global.player.hurttime = global.character == CHARACTER_SALLY_CANON ? SALLY_CANON_SHIELD_BREAK_INVULN : 60;" in h)
check("consumo eléctrico intacto (L679)",
      'if(variable_instance_exists(global.player, "electricShieldTimer") && global.player.electricShieldTimer > 0)' in h)
check("llaves/paréntesis balanceados", bal(h) == 0 and bal(h, "(", ")") == 0)

print("== D. SINCRONIZACIÓN (net_udpprocess + obj_netclient) ==")
u = load("scripts/net_udpprocess/net_udpprocess.gml")
check("sallyShield escrito SIEMPRE (patrón electroShield L173)",
      "\n                                                sallyShield = bitflags & PLAYER_SALLYSHIELD;" in u)
check("gate viejo Sally/SallyCanon fuera",
      "if(character == CHARACTER_SALLY || character == CHARACTER_SALLY_CANON)\n                                                        sallyShield" not in u)
check("electroShield incondicional intacto",
      "electroShield = bitflags & PLAYER_ELECTROSHIELD;" in u)
check("bloque Rouge (visible/invis) intacto",
      "visible = !(bitflags & PLAYER_INVIS);" in u)
check("llaves/paréntesis balanceados", bal(u) == 0 and bal(u, "(", ")") == 0)

n = load("objects/obj_netclient/Step_2.gml")
check("bit genérico PLAYER_SALLYSHIELD para todos (patrón eléctrico)",
      'if(global.character != CHARACTER_EXE\n                        && variable_instance_exists(global.player, "shieldTimer")\n                        && global.player.shieldTimer > 0)\n                                bitflags |= PLAYER_SALLYSHIELD;' in n)
check("bloques Sally/SallyCanon y Rouge históricos intactos",
      "if(global.character == CHARACTER_SALLY || global.character == CHARACTER_SALLY_CANON)" in n and
      "if(global.character == CHARACTER_ROUGE)" in n)
check("bit eléctrico intacto",
      "bitflags |= PLAYER_ELECTROSHIELD;" in n)
check("llaves/paréntesis balanceados", bal(n) == 0 and bal(n, "(", ")") == 0)

print("== E. VISUALES (puppet + 19 Draw_0) ==")
d = load("objects/obj_player_puppet/Draw_0.gml")
check("burbuja genérica en el puppet con exclusión de los 3 con case propio",
      "if(sallyShield && character != CHARACTER_SALLY && character != CHARACTER_SALLY_CANON && character != CHARACTER_ROUGE)" in d)
check("cases Sally/SallyCanon/Rouge del switch intactos",
      d.count("if(sallyShield)") == 3)
check("electroShield del puppet intacto",
      "if(electroShield)" in d)
check("Create del puppet declara sallyShield=false (sin tocar)",
      "sallyShield = false;" in load("objects/obj_player_puppet/Create_0.gml"))
check("llaves/paréntesis balanceados", bal(d) == 0 and bal(d, "(", ")") == 0)

CHARS = ["obj_sonic", "obj_chaos", "obj_vanilla", "obj_tails", "obj_amelia",
         "obj_amy_canon", "obj_amy", "obj_metal", "obj_exe", "obj_amy_fleetway",
         "obj_knux", "obj_exetior", "obj_kris", "obj_exeller", "obj_metalamy",
         "obj_jinna", "obj_blaze", "obj_egg", "obj_cream"]
BAD = []
for o in CHARS:
    t = load(f"objects/{o}/Draw_0.gml")
    c = load(f"objects/{o}/Create_0.gml")
    ok = ('if(variable_instance_exists(id, "shieldTimer") && shieldTimer > 0)' in t
          and "spr_sallyshield2 : spr_sallyshield" in t
          and "spr_electroshield" in t
          and "^revivalTimes = " .strip("^") in c
          and bal(t) == 0)
    if not ok:
        BAD.append(o)
check(f"los 19 Draw_0 nuevos (bloque + eléctrico intacto + revivalTimes + llaves)", not BAD, BAD)

NOGEN = ["obj_sally", "obj_sally_canon", "obj_rouge"]
BAD2 = [o for o in NOGEN if "v71 ITEM BOX v3 — escudo de burbuja de la caja" in load(f"objects/{o}/Draw_0.gml")]
check("Sally/SallyCanon/Rouge SIN bloque genérico (evita doble burbuja)", not BAD2, BAD2)
BAD3 = [o for o in NOGEN if bal(load(f"objects/{o}/Draw_0.gml")) != 0]
check("Sally/SallyCanon/Rouge Draw_0 sin tocar y balanceados", not BAD3, BAD3)

print("== F. Regla 6: NADA de .yyp/.yy/.resource_order tocado ==")
touched = [f for f in CHANGED if f.endswith((".yyp", ".yy", ".resource_order")) or f.startswith("_backups")]
check("cero archivos de proyecto GameMaker modificados", not touched, touched)

print("== G. Regla 7: superficie de red/anti-cheat intacta ==")
netdiff = subprocess.run(["git", "-C", REPO, "diff", "--name-only", "--",
                          "scripts/net_packets/", "betterserver-oss/", "scripts/net_tcpprocess/",
                          "scripts/net_poll/", "scripts/net_state_client/"],
                         capture_output=True, text=True).stdout.strip()
check("net_packets/ + server + protocolo TCP intactos", netdiff == "", netdiff)

print("== H. SIMULACIÓN de la lógica nueva ==")
# Mini-runtime del ciclo completo con un obj_amy_canon (el del crash reportado)
player = {}                      # SIN shieldTimer, como obj_amy_canon real
def exists(inst, name): return name in inst
def case1(inst):                 # net_state_game reward tipo 1
    if not exists(inst, "shieldTimer") or inst["shieldTimer"] <= 0:
        inst["shieldTimer"] = 300  # ITEMBOX_SHIELD_TIME (60 * 5) del arbol ACTUAL
        return True              # sonó snd_sally_shield
    return False
check("Amy Canon SIN la variable: NO revienta y setea", case1(player) and player["shieldTimer"] == 300)
check("segunda caja con escudo vivo: NO resetea (idempotente)", case1(player) is False)
for _ in range(300):             # scr_move_basic tick x300 (Amy Canon pasa el skip-list)
    if exists(player, "shieldTimer") and player["shieldTimer"] > 0:
        player["shieldTimer"] -= 1
check("tick agota el escudo en 300 frames exactos", player["shieldTimer"] == 0)
check("caja nueva tras expirar: vuelve a setear", case1(player) and player["shieldTimer"] == 300)
# absorción de golpe (scr_player_hurt genérico)
player["hurttime"] = 0
if exists(player, "shieldTimer") and player["shieldTimer"] > 0:
    player["hurttime"] = 60
    player["shieldTimer"] = 0
    absorbed = True
check("el golpe consume el escudo (hurttime 60, sin dano)", absorbed and player["hurttime"] == 60 and player["shieldTimer"] == 0)
# Sally NO doble-tick: su countdown viene del special, no de move_basic
sally = {"shieldTimer": 300, "character": "SALLY"}
for _ in range(5):
    if exists(sally, "shieldTimer") and sally["shieldTimer"] > 0:
        if sally["character"] not in ("SALLY", "SALLY_CANON", "ROUGE"):  # skip-list
            sally["shieldTimer"] -= 1
    if exists(sally, "shieldTimer") and sally["shieldTimer"] > 0:        # scr_sally_special L277
        sally["shieldTimer"] -= 1
check("Sally: solo UN decremento por frame (skip-list funciona)", sally["shieldTimer"] == 295)

print("== I. El zip llevará solo modificados (regla 2) ==")
allmod = sorted(CHANGED + [l[3:] for l in UNTRACKED if l.startswith("?? ")])
print(f"  manifiesto ({len(allmod)}):")
for f in allmod:
    print(f"    {f}")

print()
if fails:
    print(f"RESULT: {fails} FALLOS"); sys.exit(1)
print(f"RESULT: TODOS LOS CHECKS v71 OK ({len(allmod)} archivos en el manifiesto)")
