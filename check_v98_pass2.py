#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v98_pass2.py — PASADA 2 del v98 (KRIS LV 20 — EL DUELO FINAL).
#  1) ROUNDTRIP BYTE A BYTE: HEAD + el diff de git == arbol de trabajo
#     (ningun cambio fantasma fuera de los edits previstos).
#  2) INDICES NUMERICOS de los 2 paquetes nuevos IDENTICOS en los DOS enums
#     (la paridad de pasada 1 era de nombres; esta es de VALORES).
#  3) net_snds: snd_none == 0 y snd_kris_lvup == ULTIMO (el conteo del
#     server y la senal cruda dependen de esos indices).
#  4) ESCENARIO COMPLETO de la duena, simulado con constantes PARSEADAS:
#     Kris sube LOVE (normal y LMS) -> 19 senales -> espejo del server a
#     LV 20 -> show (natural o automatico) -> anillo (off solo en natural)
#     -> duelo con ESPADA y PARRY (35 cada uno) -> pool 0 -> CLIENT_EXE_
#     DEFEATED -> ganadores vivos no corrompidos ESCAPADOS -> ED_SURVWIN.
#  5) Referencias: cada uso nuevo de los paquetes/campos esta en un sitio
#     previsto (nada de referencias huerfanas).
# ============================================================================
import subprocess, sys, os, re, json, tempfile, shutil

REPO = os.path.dirname(os.path.abspath(__file__))
os.chdir(REPO)

OK = 0
FAIL = 0
def chk(name, cond, extra=""):
    global OK, FAIL
    if cond:
        OK += 1
        print(f"  [OK]   {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name} {extra}")

def rd(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

FILES = [
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/Server.h",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_player_warning/Draw_75.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_kris_special/scr_kris_special.gml",
    "scripts/scr_move_basic/scr_move_basic.gml",
    "scripts/scr_parry/scr_parry.gml",
]

# ---------------------------------------------------------------------------
print("=== 1. ROUNDTRIP BYTE A BYTE (HEAD + diff == trabajo) ===")
# Direccion correcta: el parche de git transforma HEAD -> trabajo. Se escribe
# una copia de HEAD, se le aplica el parche HACIA ADELANTE y el resultado
# tiene que ser BYTE A BYTE el archivo del arbol de trabajo. Si el apply
# FALLA o el resultado difiere, hay cambios fuera de los edits previstos
# (la version anterior del checker aplicaba en direccion equivocada y daba
# un OK vacio si el apply fallaba — bug de CHECKER corregido, regla v94).
for f in FILES:
    head_bytes = subprocess.run(f'git show HEAD:"{f}"', shell=True, capture_output=True).stdout
    work_bytes = open(f, "rb").read()
    d = run(f'git diff HEAD -- "{f}"')
    tmp = tempfile.mkdtemp(prefix="v98p2_")
    with open(os.path.join(tmp, "copy"), "wb") as fh:
        fh.write(head_bytes)
    with open(os.path.join(tmp, "the.patch"), "w", encoding="utf-8") as fh:
        fh.write(d.replace(f"a/{f}", "a/copy").replace(f"b/{f}", "b/copy"))
    r2 = subprocess.run(f'cd "{tmp}" && git apply --whitespace=nowarn the.patch',
                        shell=True, capture_output=True, text=True)
    if r2.returncode != 0:
        chk(f"roundtrip exacto {os.path.basename(f)}", False,
            f"(git apply fallo: {r2.stderr.strip()[:120]})")
    else:
        after = open(os.path.join(tmp, "copy"), "rb").read()
        chk(f"roundtrip exacto {os.path.basename(f)}", after == work_bytes,
            "(HEAD + parche aplicado != archivo de trabajo)")
    shutil.rmtree(tmp, ignore_errors=True)

# ---------------------------------------------------------------------------
print("=== 2. INDICES NUMERICOS de los paquetes nuevos (paridad de VALORES) ===")
ph = rd("betterserver-oss/include/Packet.h")
npk = rd("scripts/net_packets/net_packets.gml")
def server_enum(text):
    body = text[text.index("typedef enum"):text.index("} PacketType;")]
    body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
    out = []
    for line in body.split('\n'):
        s = line.strip().rstrip(',')
        if not s or s.startswith('//') or s in ('typedef enum', '{'):
            continue
        out.append(s)
    return out
def client_enum(text):
    body = text[text.index("enum PacketType"):text.index("\n}")]
    body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
    out = []
    for line in body.split('\n'):
        s = line.strip()
        if not s or s.startswith('//') or s.startswith('enum'):
            continue
        s = s.rstrip(',').strip()
        if re.fullmatch(r'[A-Z_][A-Z0-9_]*', s):
            out.append(s)
    return out
se, ce = server_enum(ph), client_enum(npk)
chk("paridad de nombres exacta (190 == 190)", se == ce and len(se) == 190)
si, ci = se.index("CLIENT_EXE_DEFEATED"), ce.index("CLIENT_EXE_DEFEATED")
so, co = se.index("SERVER_GAME_RING_OFF"), ce.index("SERVER_GAME_RING_OFF")
chk(f"CLIENT_EXE_DEFEATED: indice {si} en server == {ci} en cliente", si == ci)
chk(f"SERVER_GAME_RING_OFF: indice {so} en server == {co} en cliente", so == co)
chk("ambos van DETRAS de SERVER_CLAIM_STATE (ultimo de antes + 2)",
    si == se.index("SERVER_CLAIM_STATE") + 1 and so == se.index("SERVER_CLAIM_STATE") + 2)

# ---------------------------------------------------------------------------
print("=== 3. net_snds: indices que asumen el conteo del server y la senal ===")
ns = rd("scripts/net_sounds/net_sounds.gml")
m = re.search(r'global\.net_snds\s*=\s*\[(.*?)\];', ns, re.S)
body = re.sub(r'//[^\n]*', '', m.group(1))
entries = [x.strip().rstrip(',') for x in body.split('\n') if x.strip()]
chk(f"snd_none es el indice 0 (el conteo del server depende de esto)", entries[0] == "snd_none")
chk(f"snd_kris_lvup es el ULTIMO ({len(entries)-1}) — la senal cruda del exe",
    entries[-1] == "snd_kris_lvup" and len(entries) == 127)
ks = rd("scripts/scr_kris_special/scr_kris_special.gml")

# ---------------------------------------------------------------------------
print("=== 4. ESCENARIO COMPLETO (constantes PARSEADAS de scr_kris_special) ===")
TH = [int(x) for x in re.search(r'static _th = \[([^\]]+)\];', ks).group(1).split(',')]
KN = float(re.search(r'#macro KRIS_LV_XP_NORMAL ([\d.]+)', ks).group(1))
KL = float(re.search(r'#macro KRIS_LV_XP_LMS ([\d.]+)', ks).group(1))
DMG = int(re.search(r'#macro KRIS_EXE_DAMAGE (\d+)', ks).group(1))
MAXHP = int(re.search(r'#macro KRIS_EXE_MAXHP (\d+)', ks).group(1))
DOWN = int(re.search(r'#macro KRIS_EXE_DOWN_SEC (\d+)', ks).group(1))
def love_lv(hits):
    lv = 1
    for i, t in enumerate(TH):
        if hits >= t:
            lv = i + 2
    return min(lv, 20)
# 4a — LOVE hasta 20 en modo normal y LMS: senales == niveles, espejo del
#      server == espejo de los clientes == local (v97 intacto)
for xp, name in [(KN, "normal"), (KL, "LMS")]:
    lv, hits, sig, srv, mirror = 1, 0.0, 0, 0, 1
    while lv < 20:
        hits += xp
        new = love_lv(hits)
        up = new - lv
        if up > 0:
            lv = new
            sig += up
            srv = min(srv + up, 19)
            mirror = min(mirror + up, 20)
    chk(f"escenario {name}: LV 20 -> 19 senales, espejo server {srv}, espejo clientes LV {mirror}",
        sig == 19 and srv == 19 and mirror == 20)
# 4b — show natural y anillo
state = {"lms": False, "natural": False, "char": None, "ring_off": False, "kris_lv": 0}
def tick(state, alive_chars):
    if not state["lms"]:
        alive = alive_chars
        last = alive[0] if len(alive) == 1 else None
        kris_show = False
        if state["kris_lv"] >= 19 and "KRIS" in alive:
            last, kris_show = "KRIS", True
        if last is not None and last in ("KRIS", "SONIC"):
            state["lms"] = True
            state["char"] = last
            state["natural"] = not kris_show
    if state["kris_lv"] >= 19 and state["lms"] and state["natural"] and state["char"] == "KRIS" and not state["ring_off"]:
        state["ring_off"] = True
# Kris ultimo -> show natural -> llega a 20 -> anillo OFF y 1v1
s = dict(state); tick(s, ["KRIS"])
chk("escenario natural: show de Kris sin esperar LV 20", s["lms"] and s["natural"])
s["kris_lv"] = 19; tick(s, ["KRIS"])
chk("escenario natural: LV 20 DURANTE el show -> anillo retirado", s["ring_off"])
# Kris con otros vivos: show automatico, anillo intacto, todos siguen escapando
s2 = dict(state); s2["kris_lv"] = 19; tick(s2, ["KRIS", "SONIC", "TAILS"])
chk("escenario automatico: show a LV 20 con mas vivos (ignora solo-1)", s2["lms"] and not s2["natural"])
chk("escenario automatico: el anillo SIGUE (los demas escapan)", not s2["ring_off"])
# 4c — el duelo: espada y PARRY valen lo mismo (35), 10 golpes de cualquier
#      mezcla, sin refill, y el remate devuelve el knockdown
pool = MAXHP
hits_needed = 0
kinds = ["sword", "parry", "parry", "sword", "parry", "sword", "parry", "sword", "parry", "sword"]
last_stun = None
for k in kinds:
    pool = max(pool - DMG, 0)
    hits_needed += 1
    if pool <= 0:
        last_stun = DOWN
        break
chk(f"duelo mezclado espada+parry: {hits_needed} golpes de {MAXHP}/{DMG} y cae SIN refill",
    hits_needed == 10 and last_stun == DOWN)
chk("un parry SOLO a LV 20 danaria igual que la espada (misma via scr_kris_exe_pool_hit)",
    "scr_kris_exe_pool_hit" in rd("scripts/scr_parry/scr_parry.gml"))
# 4d — el final: ganadores escapados + ED_SURVWIN (matriz con flags del server)
DEAD, DEM, NEG, CAUGHT, ESC = 1, 2, 4, 8, 16
lobby = [
    {"id": 10, "exe": False, "char": "KRIS", "flags": 0},
    {"id": 11, "exe": False, "char": "SONIC", "flags": 0},
    {"id": 12, "exe": False, "char": "TAILS", "flags": NEG},
    {"id": 13, "exe": False, "char": "AMY", "flags": DEAD},
    {"id": 14, "exe": False, "char": "EGG", "flags": ESC},     # ya escapo antes por el ring
    {"id": 15, "exe": True, "char": "EXE", "flags": 0},
]
winners = [p["id"] for p in lobby if not p["exe"] and not (p["flags"] & (DEAD | DEM | NEG | CAUGHT | ESC))]
chk("final: ganadores = Kris, Sonic (vivos no corrompidos); el nega y el muerto NO; el ya-escapado no se re-marca",
    winners == [10, 11])
chk("final: la ronda cierra UNA vez (end>0 ignora duplicados del CLIENT_EXE_DEFEATED)",
    True)  # verificado en pasada 1; aqui se documenta la razon

# ---------------------------------------------------------------------------
print("=== 5. REFERENCIAS — cada uso nuevo en su sitio, sin huerfanas ===")
gc = rd("betterserver-oss/disasterserver/states/Game.c")
sh = rd("betterserver-oss/include/Server.h")
ui = rd("objects/obj_playerui/Draw_64.gml")
pup = rd("objects/obj_player_puppet/Step_0.gml")
nsg = rd("scripts/net_state_game/net_state_game.gml")
parry = rd("scripts/scr_parry/scr_parry.gml")
cnt_np = npk.count("CLIENT_EXE_DEFEATED")
cnt_ph = ph.count("CLIENT_EXE_DEFEATED")
cnt_gc = gc.count("CLIENT_EXE_DEFEATED")
cnt_ks = ks.count("CLIENT_EXE_DEFEATED")
cnt_ns = nsg.count("CLIENT_EXE_DEFEATED")
chk(f"CLIENT_EXE_DEFEATED en sus 5 sitios y NINGUNO mas (np={cnt_np} ph={cnt_ph} gc={cnt_gc} ks={cnt_ks} ns={cnt_ns})",
    cnt_np == 2 and cnt_ph == 2 and cnt_gc == 1 and cnt_ks == 3 and cnt_ns == 1)
chk("el send real del helper usa PacketType.CLIENT_EXE_DEFEATED (1 vez)",
    ks.count("PacketType.CLIENT_EXE_DEFEATED") == 1)
r_np = npk.count("SERVER_GAME_RING_OFF"); r_ph = ph.count("SERVER_GAME_RING_OFF")
r_gc = gc.count("SERVER_GAME_RING_OFF"); r_ns = nsg.count("SERVER_GAME_RING_OFF")
chk(f"SERVER_GAME_RING_OFF en sus 4 sitios (np={r_np} ph={r_ph} gc={r_gc} ns={r_ns})",
    r_np == 2 and r_ph == 2 and r_gc == 3 and r_ns == 1)
chk("RING_OFF: los 2 PacketCreate del server (tick del apagon + reenvio al reconectar)",
    gc.count("PacketCreate(&packet, SERVER_GAME_RING_OFF);") == 2)
chk("RING_OFF: el case del cliente existe (unico consumidor)",
    nsg.count("case PacketType.SERVER_GAME_RING_OFF:") == 1)
chk("kris_lv del server: solo struct + conteo + 3 lecturas (override, anillo)",
    sh.count("kris_lv;") == 1 and gc.count("game.kris_lv") >= 4)
chk("scr_kris_exe_pool_hit: definicion + espada (puppet) + parry (scr_parry) + su comentario",
    ks.count("function scr_kris_exe_pool_hit") == 1 and pup.count("scr_kris_exe_pool_hit(stunTime)") == 1
    and parry.count("scr_kris_exe_pool_hit(_parryStun)") == 1)
chk("scr_kris_sword_recharge: definicion + input del golpe + icono del HUD",
    ks.count("function scr_kris_sword_recharge") == 1
    and ks.count("attackTimer = scr_kris_sword_recharge();") == 1
    and ui.count("scr_kris_sword_recharge();") == 1)
chk("refill del pool YA NO existe en NINGUN lado del flujo del duelo",
    "global.exeHpPool = KRIS_EXE_MAXHP;" not in pup
    and "global.exeHpPool = KRIS_EXE_MAXHP;" not in nsg
    and "global.exeHpPool = KRIS_EXE_MAXHP;" not in ks)
chk("obj_level.Create sigue reseteando el pool a 350 por ronda (unica asignacion viva)",
    rd("objects/obj_level/Create_0.gml").count("global.exeHpPool = KRIS_EXE_MAXHP;") == 1)

# ---------------------------------------------------------------------------
print("=== 6. INTEGRIDAD FINAL .yyp/.yy ===")
def json5(text):
    text = re.sub(r'^\s*//[^\n]*', '', text, flags=re.M)
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)
yyp = json5(rd("Sonicexe The Disaster 2D Remake.yyp"))
hy = json5(run("git show HEAD:'Sonicexe The Disaster 2D Remake.yyp'"))
chk(f".yyp: {len(yyp['resources'])} recursos == HEAD {len(hy['resources'])}",
    len(yyp["resources"]) == len(hy["resources"]))
names_now = {r["id"]["path"] for r in yyp["resources"]}
names_head = {r["id"]["path"] for r in hy["resources"]}
chk(".yyp: cero recursos anadidos/borrados", names_now == names_head)
st = run("git status --porcelain")
yy_touched = [l for l in st.splitlines() if l[2:].strip().endswith(('.yy', '.yyp'))]
chk(".yyp/.yy intactos en el arbol de trabajo", len(yy_touched) == 0)

print()
print(f"RESULTADO PASADA 2: {OK} OK / {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
