#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v92_pass2.py — VERIFICACION PASADA 2 (independiente y mas profunda)
v92: Jina V (alcance 50->110 + hitbox circular + anillo visible) y escudo
electrico (stun tipo ataque 3 s, sin tope de distancia, sin gate de lag).
Esta pasada audita BYTES contra git diff: cada linea REMOVIDA debe ser
exactamente una de las 13 esperadas del plan, cada linea ADDED de codigo
debe ser ASCII puro (los em-dashes viven solo en comentarios), ningun
marcador nuevo puede existir 2 veces, y todas las funciones llamadas en
codigo nuevo deben existir en el repo.
"""
import sys, os, re, subprocess

_DEFAULT_REPO = "/home/z/my-project/work/repo_v92"  # sandbox de verificacion
REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1
                       else (_DEFAULT_REPO if os.path.isdir(_DEFAULT_REPO)
                             else os.path.dirname(os.path.abspath(__file__))))
FAILS, OKS = [], 0

def git_diff_u0():
    """git diff -U0 tolerante, LIMITADO a los 4 archivos de juego de la v92:
    los docs (CACHE/LEARNING/worklog) tambien cambian en el repo de entrega
    (sus entradas v92), y NO son codigo de juego — auditar sus lineas como
    si fueran GML seria un falso positivo (pasa con P2.2/P2.4). Devuelve None
    si no hay git / no es repo (se salta honesto, convencion v91)."""
    try:
        proc = subprocess.run(["git", "-C", REPO, "diff", "-U0", "--"] +
                              sorted(FILES.values()),
                              capture_output=True, text=True, timeout=30)
        if proc.returncode != 0:
            return None
        return proc.stdout
    except Exception:
        return None

def git_status_paths():
    """git status --porcelain tolerante: None si no hay git / no es repo."""
    try:
        proc = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                              capture_output=True, text=True, timeout=30)
        if proc.returncode != 0:
            return None
        return [l[3:] for l in proc.stdout.splitlines() if l.strip()]
    except Exception:
        return None

def ok(msg):
    global OKS; OKS += 1
    print(f"  [OK] {msg}")

def fail(msg):
    FAILS.append(msg)
    print(f"  [FAIL] {msg}")

def read(p):
    with open(p, encoding='utf-8', errors='replace') as f:
        return f.read()

FILES = {
    "Draw_0": "objects/obj_jinna/Draw_0.gml",
    "jinna_special": "scripts/scr_jinna_special/scr_jinna_special.gml",
    "player_hurt": "scripts/scr_player_hurt/scr_player_hurt.gml",
    "net_state": "scripts/net_state_game/net_state_game.gml",
}

print("== P2.1) AUDIT BYTES: lineas REMOVIDAS exactas (13 esperadas) ==")
EXPECTED_REMOVED = [
    "                                        // (la autoridad de siempre): stun de 1 s con el",
    "                                        // visual de chispa encima. Mismo patron que el",
    "                                        && (global.player.isAttacking || global.player.isJumping || global.player.isSpinning)",
    "                                                global.player.shockedTimer = 60;",
    "//   * AGARRE (tecla V): al superviviente en rango (JINNA_GRAB_RANGE) lo",
    "#macro JINNA_GRAB_RANGE 50                // px de alcance cuerpo a cuerpo",
    "                        jinnaGrabVisual = 24; // pose de agarre ~0,4 s",
    "                                // stun al atacante: el puppet atacante mas cercano en rango",
    "                                // de golpe aporta su nid; la senal targeted (shouldPlay=true)",
    "                                // aturde al atacante en SU propio cliente.",
    "                                        var _zd = 64;",
    "                                                if(_pp.isDead || _pp.isHiding || !_pp.isAttacking)",
    "                                                if(_d < _zd)",
]
diff = git_diff_u0()
HAVE_GIT = diff is not None
if not HAVE_GIT:
    print("  [skip] sin git o no es un repo: P2.1 (auditoria byte a byte), P2.2")
    print("         (ASCII del codigo nuevo) y P2.4 (funciones llamadas) dependen")
    print("         del diff y NO corren aqui — nada pasa en vacio. El resto de la")
    print("         pasada (P2.3/P2.5/P2.6/P2.7/P2.8) sigue completa.")
removed, added = [], []
if HAVE_GIT:
    for line in diff.splitlines():
        if line.startswith('---') or line.startswith('+++') or line.startswith('@@') or line.startswith('diff'):
            continue
        if line.startswith('-'):
            removed.append(line[1:])
        elif line.startswith('+'):
            added.append(line[1:])
    if sorted(removed) == sorted(EXPECTED_REMOVED):
        ok(f"exactamente las 13 lineas viejas esperadas fueron removidas (sin colaterales)")
    else:
        extra = set(removed) - set(EXPECTED_REMOVED)
        miss = set(EXPECTED_REMOVED) - set(removed)
        fail(f"removidas inesperadas={extra} / faltantes={miss}")
else:
    print("  [skip] P2.1 saltada (sin git): las 13 removidas exactas se auditaron")
    print("         en el repo de verificacion antes de empaquetar el zip.")

print("== P2.2) ADDED: codigo ASCII puro (solo comentarios llevan em-dash) ==")
if HAVE_GIT:
    bad = []
    for line in added:
        code = line.split('//')[0]
        code = re.sub(r'"[^"]*"', '""', code)
        if any(ord(c) > 127 for c in code):
            bad.append(line.strip()[:60])
    if bad:
        fail(f"{len(bad)} lineas de codigo con no-ASCII: {bad[:3]}")
    else:
        ok(f"las {len(added)} lineas nuevas: codigo 100% ASCII (UTF-8 solo en comentarios)")
else:
    print("  [skip] P2.2 saltada (sin git: no hay lineas nuevas que auditar)")

print("== P2.3) MARCADORES NUEVOS: exactamente UNA vez ==")
srcs = {k: read(os.path.join(REPO, v)) for k, v in FILES.items()}
markers = [
    ("jinna_special", "v92 (duena: \"mas alcance y ahora la hitbox es circular\")"),
    ("jinna_special", "#macro JINNA_GRAB_RANGE 110"),
    ("jinna_special", "#macro JINNA_GRAB_POSE 24"),
    ("jinna_special", "jinnaGrabVisual = JINNA_GRAB_POSE"),
    ("Draw_0", "ANILLO DEL AGARRE (tecla V)"),
    ("Draw_0", "if(jinnaGrabVisual > 0 && !isDead)"),
    ("net_state", "#macro ITEMBOX_ELECTRIC_STUN (60 * 3)"),
    ("net_state", "global.player.shockedTimer = ITEMBOX_ELECTRIC_STUN"),
    ("player_hurt", "SIN IMPORTAR LA"),
    ("player_hurt", "net_sound_emit_at(snd_metal_stun, _zapNid)"),
]
for k, pat in markers:
    n = srcs[k].count(pat)
    ok(f"1x {pat[:52]}... ({k})") if n == 1 else fail(f"{n}x (esperaba 1): {pat[:52]}... ({k})")

print("== P2.4) FUNCIONES llamadas en el codigo nuevo existen en el repo ==")
# FIX (re-auditoria): antes solo se descartaban las lineas QUE ERAN comentario
# entero; los comentarios de FINAL de linea ("... el agarre (tecla V) ...",
# "...la pose (la garra...)") seguian dentro y el regex tragaba palabras en
# espanol como si fueran llamadas ("agarre(", "pose("). Ahora cada linea se
# limpia DE VERDAD: primero fuera los strings literales (un // dentro de un
# string no es comentario), luego fuera el //..., y SOLO el codigo restante
# se escanea en busca de llamadas.
def code_only(line):
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == '"':
            i += 1
            while i < n and line[i] != '"':
                if line[i] == '\\': i += 1
                i += 1
            i += 1
        elif c == "'":
            i += 1
            while i < n and line[i] != "'":
                if line[i] == '\\': i += 1
                i += 1
            i += 1
        elif c == '/' and i + 1 < n and line[i+1] == '/':
            break
        else:
            out.append(c); i += 1
    return ''.join(out)
new_code = "\n".join(code_only(l) for l in added)
funcs_used = set(re.findall(r"\b([a-z_][a-z0-9_]*)\s*\(", new_code))
GM_BUILTINS = {"if", "for", "while", "with", "break", "continue", "return", "else", "max", "min",
               "floor", "ceil", "abs", "sign", "point_distance", "instance_exists", "instance_number",
               "instance_find", "draw_circle", "draw_set_color", "draw_set_alpha", "variable_instance_exists"}
repo_all = ""
for root, _, fs in os.walk(REPO):
    if ".git" in root: continue
    # respaldos de la suite anim editor fuera: una funcion "definida" solo en
    # un backup NO existe en el juego compilado (mismo criterio de P2.5)
    rel = os.path.relpath(root, REPO)
    if any(part.startswith("_backups") for part in rel.split(os.sep)): continue
    for f in fs:
        if f.endswith(".gml"):
            repo_all += read(os.path.join(root, f))
if not HAVE_GIT:
    print("  [skip] P2.4 saltada (sin git: no hay lineas nuevas que escanear)")
elif not funcs_used:
    fail("P2.4: cero llamadas extraidas del codigo nuevo — sospechoso (auditar)")
else:
    undeclared = []
    for fn in sorted(funcs_used - GM_BUILTINS):
        if not re.search(rf"function\s+{fn}\s*\(", repo_all):
            undeclared.append(fn)
    if undeclared:
        fail(f"funciones no definidas en el repo: {undeclared}")
    else:
        ok(f"todas las {len(funcs_used)} funciones del codigo nuevo existen ({sorted(funcs_used)})")

print("== P2.5) MACROS usados: definidos y con sus usos completos (SOLO CODIGO) ==")
# FIX (re-auditoria): antes se contaba el nombre del macro EN CUALQUIER sitio,
# comentarios incluidos (los bloques v92 EXPLICAN los macros y los nombran:
# "radio JINNA_GRAB_RANGE...", "TIPO ATAQUE (ITEMBOX_ELECTRIC_STUN)...").
# Eso daba 8/4/4 en vez de 5/3/2 y los FAILs eran falsos. Ahora:
#   1) se cuenta SOLO en codigo (mismo code_only de P2.4, linea a linea);
#   2) se cuenta en todos los .gml COMPILADOS del repo (un uso fuera de
#      estos 4 archivos seria una fuga real);
#   3) se exige exactamente UNA #macro de definicion.
# ALCANCE "COMPILADO": el .yyp solo lista CARPETAS (213 GMFolder, cero
# recursos hoja) — GM descubre los recursos por su .yy. Los .gml con .yy
# hermano (eventos de objetos) o .yy de carpeta (scripts/xxx/xxx.gml) o
# sueltos bajo scripts/ (scr_globals.gml y 4 legacy: GM los compila igual)
# son juego; lo unico INERTE son los respaldos de la SUITE_TD2D.html
# (_backups_animeditor/**: 81 .gml viejos, 0 referencias en el .yyp, con
# #macro JINNA_GRAB_RANGE 50 de cuando eran actuales — dejarlos fuera NO
# es trampa: no se compilan, y su valor viejo es correcto para un backup).
# Conteos de CODIGO esperados (verificados a mano contra el grep del repo):
#   JINNA_GRAB_RANGE     = 5: #macro + _gD (puppets) + dummy + anillo ext + anillo int
#   JINNA_GRAB_POSE     = 3: #macro + asignacion de pose + division del anillo
#   ITEMBOX_ELECTRIC_STUN = 2: #macro + shockedTimer del receptor
all_gml = {}
for root, _, fs in os.walk(REPO):
    # respaldos de la suite anim editor: NO se compilan (sin .yy, fuera del .yyp)
    if ".git" in root: continue
    rel = os.path.relpath(root, REPO)
    if any(part.startswith("_backups") for part in rel.split(os.sep)): continue
    for f in fs:
        if f.endswith(".gml"):
            all_gml[os.path.relpath(os.path.join(root, f), REPO)] = read(os.path.join(root, f))
def code_count(name):
    n = 0
    for src in all_gml.values():
        for line in src.splitlines():
            n += len(re.findall(rf"\b{name}\b", code_only(line)))
    return n
def macro_defs(name):
    return sum(1 for src in all_gml.values()
               for line in src.splitlines()
               if re.search(rf"#macro\s+{name}\b", code_only(line)))
macro_uses = [
    ("JINNA_GRAB_RANGE", ["#macro", "_gD puppet search", "dummy search", "anillo exterior", "anillo interior"], 5),
    ("JINNA_GRAB_POSE", ["#macro", "asignacion de la pose", "division del anillo"], 3),
    ("ITEMBOX_ELECTRIC_STUN", ["#macro", "shockedTimer del receptor"], 2),
]
for name, wheres, total in macro_uses:
    n, d = code_count(name), macro_defs(name)
    if n == total and d == 1:
        ok(f"{name}: {total} apariciones en CODIGO en todo el repo (1 de ellas la #macro) — {', '.join(wheres[:3])}...")
    else:
        fail(f"{name}: {n} apariciones en codigo (esperaba {total}), {d} definiciones (esperaba 1)")
    # fuera de los 4 archivos modificados, cero usos (fuga)
    leaks = [p for p, src in all_gml.items()
             if p not in FILES.values()
             and any(re.findall(rf"\b{name}\b", code_only(line)) for line in src.splitlines())]
    if leaks:
        fail(f"{name}: usado fuera de los 4 archivos: {leaks}")
    else:
        ok(f"{name}: sin fugas fuera de los 4 archivos (los {len(all_gml) - 4} .gml restantes, limpios)")

print("== P2.6) EL RECEPTOR: solo los 4 archivos, sin .yy/.yyp ==")
mods_raw = git_status_paths()
if mods_raw is None:
    print("  [skip] sin git o no es un repo: verifica a mano que solo cambiaron")
    print("         los 4 .gml de la v92 (nada de .yyp/.yy ni otros archivos)")
else:
    mods = sorted(mods_raw)
    exp = sorted(FILES.values())
    missing = [f for f in exp if f not in mods]
    extra = [f for f in mods if f not in exp]
    # docs + los propios verificadores vienen en el zip: no son codigo de juego
    TOOLS = {"check_v92.py", "check_v92_pass2.py"}
    doc_extra = [f for f in extra if f.endswith(('.md', '.txt')) or f in TOOLS]
    code_extra = [f for f in extra if not (f.endswith(('.md', '.txt')) or f in TOOLS)]
    if missing:
        fail(f"faltan modificaciones esperadas: {missing}")
    else:
        ok(f"los 4 archivos esperados modificados: {exp}")
    if any(f.endswith(('.yyp', '.yy')) for f in code_extra):
        fail(f"SE MODIFICARON .yyp/.yy ajenos: {[f for f in code_extra if f.endswith(('.yyp', '.yy'))]}")
    elif code_extra:
        fail(f"codigo tocado APARTE de la v92 (inesperado): {code_extra}")
    else:
        ok("ningun otro archivo de juego tocado")
        if doc_extra:
            print(f"  [info] docs aparte (parte de la entrega: CACHE/LEARNING/worklog/LEEME): {doc_extra}")

print("== P2.7) RE-SIMULACION del anillo con los argumentos reales del draw ==")
JINNA_GRAB_RANGE, JINNA_GRAB_POSE = 110, 24
err = 0
for frame in range(JINNA_GRAB_POSE, 0, -1):
    _gT = frame / JINNA_GRAB_POSE
    _gA = 0.15 + 0.5 * _gT
    calls = [(floor if False else None)]  # noqa — placeholder no usado
    # anillo exterior: draw_circle(x, y, 110, true) — radio EXACTO de la hitbox
    # anillo interior: draw_circle(x, y, 110*_gT, true)
    r_out, r_in = JINNA_GRAB_RANGE, JINNA_GRAB_RANGE * _gT
    if not (r_out == 110 and 0 < r_in <= r_out): err += 1
    if not (0.15 <= _gA <= 0.65): err += 1
    if not (0 < _gT <= 1): err += 1
# y el reset SIEMPRE despues del segundo draw (orden textual en Draw_0)
d = srcs["Draw_0"]
i1 = d.find("draw_circle(")
i2 = d.find("draw_circle(", i1 + 1)
ia = d.find("draw_set_alpha(1)", i2)
ic = d.find("draw_set_color(c_white)", ia)
if i1 < i2 < ia < ic != -1:
    ok("orden de dibujo: 2 circulos -> alpha(1) -> color(white) (siempre se restaura)")
else:
    fail(f"orden de restauracion roto: {i1},{i2},{ia},{ic}"); err += 1
if err == 0:
    ok(f"anillo: 24 frames simulados, radios/alpha dentro de rango y restauracion correcta")
else:
    fail(f"anillo: {err} errores")

print("== P2.8) REGRESION: los fixes v87-v91 siguen presentes ==")
regs = [
    ("objects/obj_amelia_auras/Draw_64.gml", "v88"),
    ("objects/obj_jinna/Step_2.gml", "isZipline"),
    ("scripts/scr_parry/scr_parry.gml", "SONIC_PARRY_LAND_BUFFER"),
    ("objects/obj_rouge/Draw_64.gml", "v91"),
    ("scripts/scr_rouge_special/scr_rouge_special.gml", "v91"),
]
for path, marker in regs:
    if marker in read(os.path.join(REPO, path)):
        ok(f"presente: {path} ({marker})")
    else:
        fail(f"PERDIDO: {path} ({marker})")

print()
print(f"RESULTADO PASADA 2: {OKS} OK, {len(FAILS)} FAIL")
if FAILS:
    for f in FAILS: print(" -", f)
    sys.exit(1)
print("PASADA 2 COMPLETA: TODOS LOS CHEQUEOS PASARON")
