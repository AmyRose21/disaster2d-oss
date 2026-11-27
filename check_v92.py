#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v92.py — VERIFICACION PASADA 1 (y re-usable para pasada 2)
v92: (1) Jina V agarre: mas alcance (50->110) + hitbox circular visible;
     (2) escudo electrico: stun "tipo ataque" (3 s) a quien lo rompio,
         sin importar la distancia, si se detecta al rompedor.
Chequeos: sintaxis GML, macros, bloques nuevos, simulaciones de logica,
consistencia entre archivos, regresiones v88-v91, integridad del repo.
"""
import sys, os, re, math, subprocess

# RAIZ DEL PROYECTO: argumento 1 (convencion v90/v91: python3 check_v92.py .)
# Sin argumento cae al repo de verificacion del sandbox.
_DEFAULT_REPO = "/home/z/my-project/work/repo_v92"  # sandbox de verificacion
REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1
                       else (_DEFAULT_REPO if os.path.isdir(_DEFAULT_REPO)
                             else os.path.dirname(os.path.abspath(__file__))))
FAILS = []
OKS = 0

def git_status_paths():
    """git status --porcelain tolerante: None si no hay git / no es repo
    (maquina del dueno sin git: la seccion 7 se salta con nota, no crashea)."""
    try:
        import subprocess as sp
        proc = sp.run(["git", "-C", REPO, "status", "--porcelain"],
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

def strip_gml(code):
    """Quita comentarios // y /* */ y strings para analisis estructural."""
    out, i, n = [], 0, len(code)
    while i < n:
        c = code[i]
        if c == '/' and i + 1 < n and code[i+1] == '/':
            while i < n and code[i] != '\n': i += 1
        elif c == '/' and i + 1 < n and code[i+1] == '*':
            i += 2
            while i + 1 < n and not (code[i] == '*' and code[i+1] == '/'): i += 1
            i += 2
        elif c == '"':
            i += 1
            while i < n and code[i] != '"':
                if code[i] == '\\': i += 1
                i += 1
            i += 1
        elif c == "'":
            i += 1
            while i < n and code[i] != "'":
                if code[i] == '\\': i += 1
                i += 1
            i += 1
        else:
            out.append(c); i += 1
    return ''.join(out)

def read(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        return f.read()

def balanced(path):
    code = strip_gml(read(path))
    pairs = {'{': '}', '(': ')', '[': ']'}
    stack = []
    ln = 1
    for ch in code:
        if ch == '\n': ln += 1
        if ch in pairs: stack.append((ch, ln))
        elif ch in pairs.values():
            if not stack or pairs[stack[-1][0]] != ch:
                fail(f"{os.path.basename(path)}: desbalance '{ch}' linea ~{ln}")
                return
            stack.pop()
    if stack:
        fail(f"{os.path.basename(path)}: sin cerrar '{stack[-1][0]}' linea ~{stack[-1][1]}")
    else:
        ok(f"{os.path.basename(path)}: llaves/parentesis/corchetes balanceados")

# ---------------------------------------------------------------- archivos
FILES = {
    "jinna_special": f"{REPO}/scripts/scr_jinna_special/scr_jinna_special.gml",
    "jinna_draw":    f"{REPO}/objects/obj_jinna/Draw_0.gml",
    "player_hurt":  f"{REPO}/scripts/scr_player_hurt/scr_player_hurt.gml",
    "net_state":    f"{REPO}/scripts/net_state_game/net_state_game.gml",
}
srcs = {k: read(v) for k, v in FILES.items()}

print("== 1) SINTAXIS ESTRUCTURAL ==")
for k, v in FILES.items():
    balanced(v)

print("== 2) MACROS v92 ==")
def has(k, pat, msg):
    if re.search(pat, srcs[k]): ok(msg)
    else: fail(msg)
has("jinna_special", r"#macro\s+JINNA_GRAB_RANGE\s+110\b", "JINNA_GRAB_RANGE = 110 (mas alcance)")
has("jinna_special", r"#macro\s+JINNA_GRAB_POSE\s+24\b", "JINNA_GRAB_POSE = 24 (pose/anillo)")
has("net_state",    r"#macro\s+ITEMBOX_ELECTRIC_STUN\s+\(60\s*\*\s*3\)", "ITEMBOX_ELECTRIC_STUN = (60 * 3) (stun tipo ataque)")

# el rango viejo ya no existe en ningun lado como definicion
if re.search(r"#macro\s+JINNA_GRAB_RANGE\s+50\b", srcs["jinna_special"]):
    fail("quedo la definicion vieja JINNA_GRAB_RANGE 50")
else:
    ok("no queda la definicion vieja JINNA_GRAB_RANGE 50")

print("== 3) BLOQUES NUEVOS ==")
# ring del agarre en Draw_0
ring_needed = ["jinnaGrabVisual > 0", "JINNA_GRAB_RANGE, true", "draw_set_alpha(1)", "draw_set_color(c_white)"]
for pat in ring_needed:
    if pat in srcs["jinna_draw"]: ok(f"Draw_0 contiene: {pat}")
    else: fail(f"Draw_0 NO contiene: {pat}")
# el ring restaura color/alpha SIEMPRE dentro del bloque (aparece 1 vez cada uno tras los dos draw_circle)
if srcs["jinna_draw"].count("draw_circle(") >= 2:
    ok("Draw_0 dibuja los 2 anillos (exterior + interior)")
else:
    fail("Draw_0 no dibuja los 2 anillos")

# pose usa el macro (no literal): revisa TODAS las asignaciones
assigns = re.findall(r"jinnaGrabVisual\s*=\s*([^;]+);", srcs["jinna_special"])
pose_ok = any("JINNA_GRAB_POSE" in a for a in assigns)
lit_24 = [a.strip() for a in assigns if a.strip() == "24"]
if pose_ok and not lit_24:
    ok("jinnaGrabVisual = JINNA_GRAB_POSE (macro, y ninguna asignacion con literal 24)")
else:
    fail(f"jinnaGrabVisual: asignaciones = {assigns}")

# emisor: sin tope de 64 px, contact-first, isJumping/isSpinning incluidos
ph = srcs["player_hurt"]
if "_zd = 64" in ph: fail("player_hurt: sigue el tope _zd = 64")
else: ok("player_hurt: sin tope de 64 px (cualquier distancia)")
if "!_pp.isAttacking" in ph: fail("player_hurt: sigue excluyendo a no-isAttacking")
else: ok("player_hurt: ya no excluye a los que no estan isAttacking")
if "_pp.isInactive" in ph: ok("player_hurt: filtra puppets desconectados (isInactive)")
else: fail("player_hurt: NO filtra isInactive")
for pat in ["isAttacking || _pp.isJumping || _pp.isSpinning",
            "bbox_right >= global.player.bbox_left",
            "bbox_top <= global.player.bbox_bottom",
            "net_sound_emit_at(snd_metal_stun, _zapNid)"]:
    if pat in ph: ok(f"player_hurt contiene: {pat[:48]}...")
    else: fail(f"player_hurt NO contiene: {pat[:48]}...")

# receptor: gate sin 'seguir atacando', con dedup y lado EXE, duracion macro
ns = srcs["net_state"]
blk = re.search(r"else if\(global\.net_snds\[sid\]\s*==\s*snd_metal_stun\)(.*?)\n\s+else if\(global\.net_snds\[sid\]\s*==\s*snd_exe_stun\)", ns, re.S)
if not blk:
    fail("no se encontro el bloque receptor de snd_metal_stun")
else:
    b = blk.group(1)
    checks = [
        ("gate lado EXE/esbirro", "global.character == CHARACTER_EXE || global.player.revivalTimes >= 2" in b),
        ("gate vivo (!isDead)", "!global.player.isDead" in b),
        ("gate dedup (shockedTimer <= 0)", "global.player.shockedTimer <= 0" in b),
        ("stun usa ITEMBOX_ELECTRIC_STUN", "shockedTimer = ITEMBOX_ELECTRIC_STUN" in b),
        ("empujon del ataque", "-global.player.image_xscale * 3" in b),
        ("chispa + sonido", "spr_shockparticle" in b and "snd_exe_stun" in b),
    ]
    for name, cond in checks:
        ok(f"receptor: {name}") if cond else fail(f"receptor: falta {name}")
    if "isAttacking || global.player.isJumping || global.player.isSpinning" in b:
        fail("receptor: SIGUE el gate de ataque activo (el bug del lag)")
    else:
        ok("receptor: retirado el gate de 'seguir atacando' (fix del lag)")
    if "shockedTimer = 60;" in b:
        fail("receptor: quedo el stun viejo de 60f")
    else:
        ok("receptor: sin stun viejo de 60f")

print("== 4) VARIABLES: escritas antes de leerse (bloques nuevos) ==")
# bloque emisor: orden de aparicion de cada var local
emitter = re.search(r"var _zapNid = -1;(.*?)net_sound_emit_at\(snd_metal_stun", ph, re.S).group(1)
for var in ["_zapper", "_zd", "_pcount", "_pi", "_pp", "_d"]:
    first_write = emitter.find(f"{var} =")
    if first_write == -1 and var == "_zapper":
        first_write = emitter.find("_zapper = noone")
    first_read = emitter.find(f"({var},") # cualquier uso en firma de llamada
    ok(f"emisor: {var} se inicializa en el bloque") if first_write >= 0 else fail(f"emisor: {var} sin inicializar")
# Draw_0: _gT/_gA antes de uso
ring = re.search(r"if\(jinnaGrabVisual > 0 && !isDead\)(.*?)\n}", srcs["jinna_draw"], re.S).group(1)
if ring.find("_gT =") < ring.find("_gA") and ring.find("_gA =") < ring.find("draw_circle"):
    ok("Draw_0 ring: _gT y _gA se calculan antes de dibujar")
else:
    fail("Draw_0 ring: uso antes de calculo")

print("== 5) SIMULACIONES DE LOGICA ==")
# 5a. circulo del agarre (puppet: < 110, dummy: <= 110) — sin filtro de direccion
def grab_puppet(dx, dy): return math.hypot(dx, dy) < 110
cases = [
    ((77, 77),  True,  "diagonal 109px delante-arriba: DENTRO (77,77 = 108.9 < 110)"),
    ((-100, 0), True,  "detras 100px: DENTRO (sin filtro de direccion)"),
    ((0, -105), True,  "arriba 105px: DENTRO (agarra tambien en el aire)"),
    ((110, 0),  False, "al borde exacto 110px: FUERA (strict <)"),
    ((90, 90),  False, "diagonal 127px: FUERA"),
]
for (dx, dy), expect, desc in cases:
    got = grab_puppet(dx, dy)
    ok(f"agarre circular: {desc} -> {got}") if got == expect else fail(f"agarre circular: {desc} -> {got}, esperaba {expect}")

# 5b. deteccion del rompedor: contacto primero, luego mas cercano A CUALQUIER distancia
class PP:
    def __init__(self, x, y, atk=False, jmp=False, spn=False, dead=False, hid=False, mid=1, inactive=False):
        self.x, self.y, self.isAttacking, self.isJumping, self.isSpinning = x, y, atk, jmp, spn
        self.isDead, self.isHiding, self.isInactive, self.master_id = dead, hid, inactive, mid
        self.bl, self.br, self.bt, self.bb = x-19, x+19, y-28, y+28
def detect(carrier, pps):
    zapper, zd = None, 0
    for pp in pps:
        if pp.isDead or pp.isHiding or pp.isInactive: continue
        if not (pp.isAttacking or pp.isJumping or pp.isSpinning): continue
        if (pp.br >= carrier['bl'] and pp.bl <= carrier['br']
            and pp.bb >= carrier['bt'] and pp.bt <= carrier['bb']):
            return pp.master_id  # quien toca, rompio
        d = math.hypot(pp.x - carrier['x'], pp.y - carrier['y'])
        if zapper is None or d < zd:
            zd, zapper = d, pp.master_id
    return zapper if zapper is not None else -1
C = {'x': 100, 'y': 100, 'bl': 81, 'br': 119, 'bt': 72, 'bb': 128}
scen = [
    ([PP(130, 100, atk=True)], 1, "rompedor en contacto (golpe X): stun"),
    ([PP(400, 100, atk=True)], 1, "rompedor a 300px (pad de Jinna/martillo): stun — SIN tope de distancia"),
    ([PP(130, 100, jmp=True)], 1, "rompedor con SALTO (isJumping, no isAttacking): stun"),
    ([PP(620, 100, spn=True)], 1, "rompedor con SPINDASH a 520px: stun"),
    ([PP(130, 100, atk=True), PP(150, 100, atk=True, mid=2)], 1, "dos en contacto: el PRIMERO que toca (paso 1)"),
    ([PP(500, 100, atk=True, mid=3), PP(150, 100, jmp=True, mid=4)], 4, "uno lejos y otro en contacto (salto): gana el CONTACTO"),
    ([PP(600, 100, atk=True, mid=5), PP(900, 100, atk=True, mid=6)], 5, "nadie toca: el MAS CERCANO a cualquier distancia"),
    ([PP(300, 100, atk=True, dead=True)], -1, "rompedor muerto: sin stun (se filtra)"),
    ([PP(200, 100, jmp=True, inactive=True)], -1, "puppet DESCONECTADO congelado (isInactive): sin senal"),
    ([PP(300, 100, atk=False, jmp=False, spn=False)], -1, "nadie atacando: sin senal (si NO detecta, no stunea)"),
    ([], -1, "sin puppets: sin senal"),
]
def _s(v): return f"nid {v}" if v >= 0 else "sin stun"
for pps, expect, desc in scen:
    got = detect(C, pps)
    ok(f"deteccion: {desc} -> {_s(got)}") if got == expect else fail(f"deteccion: {desc} -> {_s(got)}, esperaba {_s(expect)}")

# 5c. receptor: el gate nuevo
def receiver(is_exe, is_dead, shocked, attacking_now):
    if not (is_exe and not is_dead and shocked <= 0): return None
    return 180  # ITEMBOX_ELECTRIC_STUN
rc = [
    (True, False, 0, False, 180, "exe VIVO sin stun aunque YA NO ataca (lag): STUN 3 s — el fix"),
    (True, False, 0, True,  180, "exe VIVO atacando aun: STUN 3 s"),
    (True, False, 90, True,  None, "exe YA stuneado: dedup, no re-stun"),
    (True, True,  0, True,  None, "exe muerto: sin stun"),
    (False, False, 0, True, None, "supervivente receptor: sin stun (solo bando EXE)"),
]
for is_exe, dead, shocked, atk, expect, desc in rc:
    got = receiver(is_exe, dead, shocked, atk)
    ok(f"receptor: {desc} -> {got}") if got == expect else fail(f"receptor: {desc} -> {got}")

# 5d. matematica del anillo
bad = 0
for t in range(24, 0, -1):
    gT = t / 24
    a = 0.15 + 0.5 * gT
    if not (0.15 <= a <= 0.65): bad += 1
    if not (0 < gT <= 1): bad += 1
    r_out, r_in = 110, 110 * gT
    if not (0 <= r_in <= r_out): bad += 1
ok("anillo: alpha en [0.15, 0.65], radios en [0, 110] en los 24 frames") if bad == 0 else fail(f"anillo: {bad} frames fuera de rango")

print("== 6) REGRESIONES v88-v91 (fixes anteriores presentes) ==")
reg = [
    (f"{REPO}/objects/obj_amelia_auras/Draw_64.gml", "v88", "fix DoMod crash de Amelia"),
    (f"{REPO}/objects/obj_jinna/Step_2.gml", "isZipline", "fix liana de Jina (v89)"),
    (f"{REPO}/scripts/scr_parry/scr_parry.gml", "v90", "parry QoL Sonic (v90)"),
    (f"{REPO}/objects/obj_rouge/Draw_64.gml", "v91", "rework Rouge (v91)"),
    (f"{REPO}/scripts/scr_rouge_special/scr_rouge_special.gml", "v91", "rework Rouge especial (v91)"),
]
for path, marker, desc in reg:
    if marker in read(path): ok(f"presente: {desc}")
    else: fail(f"PERDIDO: {desc}")

print("== 7) INTEGRIDAD DEL REPO: solo los 4 .gml modificados ==")
mods = git_status_paths()
expected = {"scripts/scr_jinna_special/scr_jinna_special.gml", "objects/obj_jinna/Draw_0.gml",
            "scripts/scr_player_hurt/scr_player_hurt.gml", "scripts/net_state_game/net_state_game.gml"}
if mods is None:
    print("  [skip] sin git o no es un repo: verifica a mano que solo estos 4")
    print("         archivos del juego cambiaron (la pasada 2 lo audita byte a byte)")
else:
    missing = expected - set(mods)
    extra = [f for f in mods if f not in expected]
    if missing:
        fail(f"faltan modificaciones esperadas: {sorted(missing)}")
    else:
        ok("los 4 archivos esperados estan modificados")
    if extra:
        # docs + los propios verificadores vienen en el zip: no son codigo de juego
        TOOLS = {"check_v92.py", "check_v92_pass2.py"}
        doc_extra = [f for f in extra if f.endswith(('.md', '.txt')) or f in TOOLS]
        code_extra = [f for f in extra if not (f.endswith(('.md', '.txt')) or f in TOOLS)]
        if any(f.endswith(('.yyp', '.yy')) for f in code_extra):
            fail("SE MODIFICARON .yyp/.yy — prohibido tocarlos salvo crear archivos nuevos: "
                 f"{[f for f in code_extra if f.endswith(('.yyp', '.yy'))]}")
        else:
            if code_extra:
                fail(f"codigo tocado APARTE de la v92 (inesperado): {code_extra}")
            else:
                ok("ningun otro archivo de juego tocado (ni .yyp/.yy)")
                print(f"  [info] docs aparte (parte de la entrega: CACHE/LEARNING/worklog/LEEME): {doc_extra}")

print("== 8) BASURA / PLACEHOLDERS ==")
for k, s in srcs.items():
    for token in ["TODO", "XXX", "FIXME", "undefined", "NaN", "PLACEHOLDER"]:
        if re.search(rf"\b{token}\b", strip_gml(s)):
            fail(f"{k}: contiene {token}")
ok("sin TODO/XXX/FIXME/undefined/NaN en los 4 archivos")

print()
print(f"RESULTADO PASADA: {OKS} OK, {len(FAILS)} FAIL")
if FAILS:
    print("FALLOS:")
    for f in FAILS: print(" -", f)
    sys.exit(1)
print("TODOS LOS CHEQUEOS PASARON")
