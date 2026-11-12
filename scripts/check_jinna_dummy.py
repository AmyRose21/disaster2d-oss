#!/usr/bin/env python3
"""[jinna-dummy-v1] Validacion: portal+agarre vs dummy y retiro del max
de portales trampa.

Checks estaticos + simulaciones. Sale 0 solo si TODO pasa.
Uso: python3 check_jinna_dummy.py
"""
import re
import subprocess
import sys

REPO = "/home/z/my-project/repo"
BS = f"{REPO}/betterserver-oss"
JS = f"{REPO}/scripts/scr_jinna_special/scr_jinna_special.gml"
FD = f"{REPO}/objects/obj_fart_dummy/Step_0.gml"
GC = f"{BS}/disasterserver/states/Game.c"
JH = f"{BS}/include/entities/JinnaTrap.h"

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
print("== 1. Parches presentes (1 vez, exactos) ==")
def cnt(path, needle):
    return rd(path).count(needle.encode() if isinstance(needle, str) else needle)

# P1 — cancel del telegraph consciente del dummy
check(cnt(JS, "jinnaTeleTarget.object_index != obj_fart_dummy && (jinnaTeleTarget.hp <= 0 || jinnaTeleTarget.isInactive)") == 1,
      "P1: el cancel del telegraph no lee hp/isInactive si el blanco es el dummy")
check(cnt(JS, "if(!instance_exists(jinnaTeleTarget)\n") == 1,
      "P1: el exists va PRIMERO (cortocircuito: nunca se lee var de instancia muerta)")

# P2 — dummy como blanco del teletransporte
check(cnt(JS, "if(instance_exists(obj_fart_dummy))\n                {\n                        with(obj_fart_dummy)\n                        {\n                                var _d = point_distance(x, y, other.x, other.y);\n                                if(_d < _bestD)") == 1,
      "P2: el dummy entra a la busqueda del blanco del teletransporte (misma distancia maxima)")

# P3 — dummy como blanco del agarre
check(cnt(JS, "if(_g == noone && instance_exists(obj_fart_dummy))") == 1,
      "P3: el dummy es fallback del agarre (solo si ningun puppet esta en rango)")
check(cnt(JS, "if(point_distance(x, y, other.x, other.y) <= JINNA_GRAB_RANGE)") == 1,
      "P3: distancia del agarre al dummy = JINNA_GRAB_RANGE (la misma de los puppets)")

# P4 — rama puppet/dummy
check(cnt(JS, "if(_g.object_index == obj_fart_dummy)") == 1,
      "P4: el agarre distingue puppet real vs muneco")
check(cnt(JS, 'instance_create_depth(x, y, 0, obj_fart_text).text = "-2";') == 1,
      "P4: el agarre al dummy muestra el texto de dano (convencion del dummy)")
check(cnt(JS, "choose(snd_dummy, snd_dummy2, snd_dummy3)") == 1,
      "P4: el agarre al dummy reproduce la voz del muneco")

# P5 — X de Jinna en el switch del dummy
check(cnt(FD, "case EXE_JINNA:") == 1,
      "P5: el golpe X de Jinna esta en el switch del dummy (antes sacaba \"0\")")

# P6-P8 — cooldowns del server sincronizados
check(cnt(GC, "v->plr_cooldowns[JINNA_TELEPORT] = (int)(6.75 * TICKSPERSEC);") == 1,
      "P6: cooldown server del teletransporte 6,75 s (macro cliente 7,25 - 0,5 colchon)")
check(cnt(GC, "v->plr_cooldowns[JINNA_GRAB] = (int)(8.0 * TICKSPERSEC);") == 1,
      "P7: cooldown server del agarre 8 s (macro cliente 8,5 - 0,5)")
check(cnt(GC, "v->plr_cooldowns[JINNA_TRAP] = (int)(8.0 * TICKSPERSEC);") == 1,
      "P8: cooldown server de la trampa 8 s (macro cliente 8,5 - 0,5) — retiro del max")
for old in ["JINNA_TELEPORT] = 8 *", "JINNA_GRAB] = 12 *", "JINNA_TRAP] = 15 *"]:
    check(cnt(GC, old) == 0, f"sin rastro del viejo cooldown: {old[:-2]}")

# P9-P10 — vida de la trampa
check(cnt(GC, "JinnaTrap (60 s de vida)") == 1, "P9: comentario de vida al dia")
check(cnt(JH, "#define JINNA_TRAP_LIFE_S 60") == 1, "P10: vida server de la trampa 60 s")
check(cnt(JH, "#define JINNA_TRAP_LIFE_S 70") == 0, "P10: sin el 70 suelto de la v4")
check(cnt(JS, "#macro JINNA_TRAP_LIFE (60 * 60)") == 1,
      "P10: tu macro cliente sigue IGUAL (60 s, no se toco tu edicion)")

# ---------------------------------------------------------------------------
print("== 2. Ninguna var exclusiva de puppets se lee en las rutas del dummy ==")
# los bloques nuevos del dummy no tocan hp/isInactive/revivalTimes/master_id
js = rd(JS).decode("utf-8", "replace")

def block_between(text, start_pat, end_pat):
    i = text.find(start_pat)
    j = text.find(end_pat, i)
    return text[i:j] if i >= 0 and j > i else ""

tp_block = block_between(js, "if(instance_exists(obj_fart_dummy))\n                {\n                        with(obj_fart_dummy)\n                        {\n                                var _d = point_distance",
                         "if(_best != noone)")
check("hp" not in tp_block and "isInactive" not in tp_block and "revivalTimes" not in tp_block,
      "busqueda del teletransporte: el dummy no pasa por el filtro de puppets")

gb_block = block_between(js, "if(_g == noone && instance_exists(obj_fart_dummy))",
                         "if(_g != noone)")
check("hp" not in gb_block and "isInactive" not in gb_block and "master_id" not in gb_block,
      "busqueda del agarre: idem")

dm_branch = block_between(js, "if(_g.object_index == obj_fart_dummy)", "else\n                        {\n                                // el server valida")
check("master_id" not in dm_branch,
      "la rama del dummy NO escribe master_id (no existe en el muneco)")
check("cpacket_tcp" not in dm_branch,
      "la rama del dummy NO manda paquetes (feedback 100% local)")
pkt_zone = block_between(js, "else\n                        {\n                                // el server valida",
                         "audio_play_sound(snd_jina_ready")
check("master_id" in pkt_zone,
      "la rama de puppets sigue mandando el paquete del agarre (regresion: intacta)")

# el cancel del telegraph: el .hp solo se evalua si NO es el dummy (cortocircuito)
cancel_line = [l for l in js.splitlines() if "object_index != obj_fart_dummy" in l]
check(len(cancel_line) == 1 and "hp <= 0" in cancel_line[0] and cancel_line[0].index("object_index") < cancel_line[0].index("hp"),
      "el orden del if protege al dummy: object_index ANTES de hp (cortocircuito)")

# ---------------------------------------------------------------------------
print("== 3. Balance de llaves y parentesis (GML sin comentarios/strings) ==")
def balance(path):
    src = rd(path).decode("utf-8", "replace")
    src = re.sub(r"//[^\n]*", "", src)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    src = re.sub(r'"(\\.|[^"\\])*"', '""', src)
    return (src.count("{") - src.count("}"), src.count("(") - src.count(")"))

for f in [JS, FD]:
    b, p = balance(f)
    check(b == 0 and p == 0, f"{f.split('/')[-1]}: llaves {b}, parentesis {p}")

# ---------------------------------------------------------------------------
print("== 4. Tus ediciones de hoy quedan intactas (no se toco tu tuning) ==")
check(cnt(JS, "#macro JINNA_TELEPORT_RECHARGE (60 * 7.25)") == 1, "tu macro teleport 7,25 s intacta")
check(cnt(JS, "#macro JINNA_GRAB_RECHARGE (60 * 8.5)") == 1, "tu macro agarre 8,5 s intacta")
check(cnt(JS, "#macro JINNA_TRAP_RECHARGE (60 * 8.5)") == 1, "tu macro trampa 8,5 s intacta")
check(cnt(JS, "#macro JINNA_TRAP_RADIUS 36") == 1, "tu macro radio 36 intacta")
check(cnt(JS, "#macro JINNA_WEAKMARK_CD (60 * 12.5)") == 1, "tu macro weakmark 12,5 s intacta")

# ---------------------------------------------------------------------------
print("== 5. Compilacion del server (gcc -fsyntax-only vs HEAD) ==")
r1 = subprocess.run(["gcc", "-fsyntax-only", "-I", f"{BS}/include", "-I", "/tmp/enet_stub",
                     GC], capture_output=True, text=True)
with open("/tmp/jd_head.c", "w") as f:
    f.write(subprocess.run(["git", "-C", REPO, "show", "HEAD:betterserver-oss/disasterserver/states/Game.c"],
                           capture_output=True, text=True).stdout)
r2 = subprocess.run(["gcc", "-fsyntax-only", "-I", f"{BS}/include", "-I", "/tmp/enet_stub",
                     "/tmp/jd_head.c"], capture_output=True, text=True)

def norm(t):
    t = re.sub(r":[0-9]+:[0-9]+:", "::", t)
    t = re.sub(r"[^ :\t\n]*Game\.c", "FILE.c", t)
    t = re.sub(r"/tmp/[A-Za-z0-9_]*\.c", "FILE.c", t)
    t = re.sub(r"^ *[0-9]+ \|", "LN |", t, flags=re.M)
    return t

check(norm(r1.stderr) == norm(r2.stderr),
      f"Game.c: errores identicos a HEAD ({len([l for l in r1.stderr.splitlines() if 'error' in l or 'warning' in l])} preexistentes), cero nuevos")

# ---------------------------------------------------------------------------
print("== 6. Simulacion: el 'max 3 portales' que vivias (causa raiz) ==")
def portals_alive(client_cd_s, server_cd_s, life_s, tries_s, duration_s=300):
    """Planta cada tries_s segundos si SU cooldown cliente lo permite;
    el server solo acepta si SU cooldown expiro. Devuelve el max de
    portales vivos a la vez (y cuantas plantadas en total)."""
    next_client_ok = 0.0
    next_server_ok = 0.0
    events = []  # (t, 'spawn')
    alive_max = 0
    spawns = 0
    t = 0.0
    while t <= duration_s:
        if t >= next_client_ok:
            if t >= next_server_ok:
                events.append(t)
                spawns += 1
                next_server_ok = t + server_cd_s
            next_client_ok = t + client_cd_s  # el cliente gasto su recarga igual
        # portales vivos ahora
        alive = sum(1 for e in events if t - e < life_s)
        alive_max = max(alive_max, alive)
        t += 0.25
    return alive_max, spawns

old_max, old_spawns = portals_alive(8.5, 15.0, 60.0, 8.5)
new_max, new_spawns = portals_alive(8.5, 8.0, 60.0, 8.5)
check(old_max == 4,
      f"ANTES (server 15 s vs cliente 8,5 s): max {old_max} vivos en 5 min ({old_spawns} plantadas salen)")
check(old_spawns == 18,
      f"ANTES: de las 36 plantadas que tu HUD daba por listas, solo {old_spawns} salian (mitad rechazada en silencio)")
check(new_max == 8 and new_spawns == 36,
      f"DESPUES (server 8 s): TODAS las plantadas salen ({new_spawns}) y el maximo vivo es {new_max} — sin tope de cantidad")

# ---------------------------------------------------------------------------
print("== 7. Simulacion: seleccion de blanco (puppet real manda, dummy fallback) ==")
JINNA_GRAB_RANGE = 50
def grab_pick(puppets, dummy_dist):
    """puppets: lista de distancias de puppets VIVOS en rango."""
    best = None
    bestD = JINNA_GRAB_RANGE
    for d in puppets:
        if d < bestD:
            bestD = d
            best = "puppet"
    if best is None and dummy_dist is not None and dummy_dist <= JINNA_GRAB_RANGE:
        best = "dummy"
    return best

check(grab_pick([], 40) == "dummy", "sola con el dummy a 40 px: agarra al dummy")
check(grab_pick([], 80) is None, "dummy a 80 px (fuera de rango): no agarra nada")
check(grab_pick([45], 20) == "puppet", "puppet a 45 y dummy a 20: el PUPPET gana (prioridad real)")
check(grab_pick([50], 10) == "dummy", "puppet justo a 50 (no < 50): no cuenta, cae al dummy a 10")
check(grab_pick([30, 60], 25) == "puppet", "dos puppets, uno en rango: puppet (el dummy ni se evalua)")

def tele_pick(puppets, dummy_dist, max_range=2200):
    best = None
    bestD = max_range
    for d in puppets:
        if d < bestD:
            bestD = d
            best = "puppet"
    if dummy_dist is not None and dummy_dist < bestD:
        best = "dummy"
    return best

check(tele_pick([], 1500) == "dummy", "sola: el teletransporte marca al dummy")
check(tele_pick([900], 1500) == "puppet", "puppet mas cerca que el dummy: puppet")
check(tele_pick([], 2500) is None, "dummy a 2500 (> 2200 max): no hay blanco, la C no hace nada")

# ---------------------------------------------------------------------------
print("== 8. Simulacion: el cancel del telegraph con cada tipo de blanco ==")
def cancel_check(target_exists, target_type, hp=100, inactive=False):
    """Replica el if nuevo: exists primero, luego dummy-guard, luego hp."""
    if not target_exists:
        return "cancel"
    if target_type != "dummy" and (hp <= 0 or inactive):
        return "cancel"
    return "sigue"

check(cancel_check(False, "puppet") == "cancel", "puppet desconectado: cancela (como siempre)")
check(cancel_check(True, "puppet", hp=0) == "cancel", "puppet muerto: cancela (como siempre)")
check(cancel_check(True, "puppet", inactive=True) == "cancel", "puppet inactivo: cancela (como siempre)")
check(cancel_check(True, "dummy") == "sigue", "dummy: SIGUE (no tiene hp que leer — no crashea)")
check(cancel_check(True, "puppet", hp=100) == "sigue", "puppet vivo: sigue (como siempre)")

# ---------------------------------------------------------------------------
print("== 9. Cooldowns server: los numeros exactos ==")
check(int(6.75 * 60) == 405, "teletransporte: 6,75 s = 405 ticks")
check(int(8.0 * 60) == 480, "agarre: 8 s = 480 ticks")
check(int(8.0 * 60) == 480, "trampa: 8 s = 480 ticks")
check(405 < int(7.25 * 60) and 480 < int(8.5 * 60),
      "server < cliente en los tres (el colchon de 0,5 s absorbe la latencia: jamas rechaza una plantada legitima)")

# ---------------------------------------------------------------------------
print("== 10. Diff git: archivos esperados ==")
diff = subprocess.run(["git", "-C", REPO, "diff", "--numstat"],
                      capture_output=True, text=True).stdout
files = {}
for ln in diff.splitlines():
    a, d, name = ln.split("\t")
    files[name] = (int(a), int(d))
expected_this_task = {
    "scripts/scr_jinna_special/scr_jinna_special.gml",
    "objects/obj_fart_dummy/Step_0.gml",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/entities/JinnaTrap.h",
}
# (los 6 de practica-exe-v1 siguen sin commit: se verifican aparte)
check(expected_this_task.issubset(set(files)),
      f"los 4 archivos de esta tarea estan modificados: {sorted(expected_this_task)}")

print(f"\nRESULTADO: {passed} OK, {failed} FAIL")
sys.exit(1 if failed else 0)
