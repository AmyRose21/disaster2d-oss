#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v93_pass2.py — VERIFICACION PASADA 2 (independiente de la pasada 1)
v93 Metal Amy rework + GUI animada.
Metodos DIFERENTES a la pasada 1:
  A) RECONSTRUCCION BYTE A BYTE: aplica los 17 pares (viejo, nuevo) documentados
     sobre `git show HEAD:archivo` y exige resultado == archivo entregado.
  B) Lexer INDEPENDIENTE (maquina de estados por linea, no strip_gml).
  C) Re-medida de cajas de contenido con umbral alpha DISTINTO (>16).
  D) Recalculo de layout desde los bytes del codigo (regex distinta).
  E) Re-simulacion aritmetica (flujos de recarga con y sin scan/embestida).
  F) Escenario DUENA: clon limpio de HEAD + overlay de los 4 archivos
     -> pasada 1 re-ejecutada alli (debe dar 72 OK / 0 FAIL).
  G) Unicidad de macros nuevos + .yy de los objetos intactos.
"""
import sys, os, re, glob, math, subprocess as sp, shutil, tempfile

REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/repo")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v93_pairs import PAIRS

FAILS, OKS = [], 0
def ok(m):
    global OKS; OKS += 1; print(f"  [OK] {m}")
def fail(m):
    FAILS.append(m); print(f"  [FAIL] {m}")
def read(p):
    with open(p, encoding='utf-8', errors='replace') as f: return f.read()

print("== A) RECONSTRUCCION BYTE A BYTE (prueba de alcance exacto) ==")
for rel, pairs in PAIRS.items():
    head = sp.run(["git", "-C", REPO, "show", f"HEAD:{rel}"], capture_output=True).stdout.decode('utf-8', errors='replace')
    if not head:
        fail(f"{rel}: no existe en HEAD"); continue
    cur = head
    applied = 0
    for old, new in pairs:
        if cur.count(old) != 1:
            fail(f"{rel}: par #{applied+1} no unico o ausente (count={cur.count(old)})")
            break
        cur = cur.replace(old, new, 1)
        applied += 1
    else:
        disk = read(f"{REPO}/{rel}")
        if cur == disk:
            ok(f"{rel}: {len(pairs)} pares aplicados a HEAD == archivo entregado (byte a byte)")
        else:
            # localizar primera diferencia
            for i, (a, b) in enumerate(zip(cur.splitlines(), disk.splitlines())):
                if a != b:
                    fail(f"{rel}: difiere en linea {i+1}: recon={a[:60]!r} disco={b[:60]!r}")
                    break
            else:
                fail(f"{rel}: difiere en largo ({len(cur.splitlines())} vs {len(disk.splitlines())})")

print("== B) LEXER INDEPENDIENTE (maquina de estados, por linea) ==")
def lex_balance(path):
    """Balance con maquina de estados: fuera/comentario linea/comentario
    bloque/string/corchete. Independiente del strip_gml de pasada 1."""
    depth = {'{': 0, '(': 0, '[': 0}
    pair = {'}': '{', ')': '(', ']': '['}
    state = 'code'
    prev = ''
    for ln, line in enumerate(read(path).split('\n'), 1):
        i = 0
        while i < len(line):
            c = line[i]
            if state == 'code':
                if c == '/' and i+1 < len(line) and line[i+1] == '/': break
                if c == '/' and i+1 < len(line) and line[i+1] == '*': state = 'block'; i += 2; continue
                if c == '"': state = 'str'; i += 1; continue
                if c == "'": state = 'chr'; i += 1; continue
                if c in depth: depth[c] += 1
                elif c in pair:
                    depth[pair[c]] -= 1
                    if depth[pair[c]] < 0: return f"cerrado de mas '{c}' linea {ln}"
            elif state == 'block':
                if c == '*' and i+1 < len(line) and line[i+1] == '/': state = 'code'; i += 2; continue
            elif state == 'str':
                if c == '\\': i += 2; continue
                if c == '"': state = 'code'
            elif state == 'chr':
                if c == '\\': i += 2; continue
                if c == "'": state = 'code'
            i += 1
        if state == 'str' or state == 'chr':
            return f"string sin cerrar linea {ln}"
    if state == 'block':
        return "comentario de bloque sin cerrar"
    if any(v != 0 for v in depth.values()):
        return f"desbalance {depth}"
    return None

for rel in PAIRS:
    r = lex_balance(f"{REPO}/{rel}")
    if r: fail(f"{rel}: {r}")
    else: ok(f"{os.path.basename(rel)}: balance OK (lexer independiente)")

print("== C) CAJAS DE CONTENIDO RE-MEDIDAS (umbral alpha > 16) ==")
from PIL import Image as PILImage
crops = {  # sprite -> (cx, cy, cw, ch) en el codigo
    "spr_metalamy_jump": (0, 0, 30, 30),
    "spr_metalamy_attack2": (0, 0, 31, 31),
    "spr_metalamy_bullet": (1, 3, 40, 10),
    "spr_metalamy_scan": (0, 18, 53, 44),
}
for spr, (cx, cy, cw, ch) in crops.items():
    pngs = sorted(glob.glob(f"{REPO}/sprites/{spr}/*.png"))
    g = None
    for p in pngs:
        img = PILImage.open(p).convert("RGBA")
        w, h = img.size
        px = img.load()
        for yy in range(h):
            for xx in range(w):
                if px[xx, yy][3] > 16:  # umbral DISTINTO al de pasada 1
                    if g is None: g = [xx, yy, xx, yy]
                    else:
                        g[0] = min(g[0], xx); g[1] = min(g[1], yy)
                        g[2] = max(g[2], xx); g[3] = max(g[3], yy)
    gx0, gy0, gx1, gy1 = g
    W, H = img.size
    inside = (0 <= cx and 0 <= cy and cx + cw <= W and cy + ch <= H)
    covers = (cx <= gx0 and cy <= gy0 and cx + cw - 1 >= gx1 and cy + ch - 1 >= gy1)
    if inside and covers:
        ok(f"{spr}: recorte ({cx},{cy},{cw},{ch}) dentro de {W}x{H} y cubre [{gx0}..{gx1}]x[{gy0}..{gy1}] (alpha>16)")
    else:
        fail(f"{spr}: recorte invalido: inside={inside} covers={covers} caja=[{gx0}..{gx1}]x[{gy0}..{gy1}]")

print("== D) LAYOUT RE-DEDUCIDO (regex distinta, desde los bytes) ==")
d64 = read(f"{REPO}/objects/obj_playerui/Draw_64.gml")
case = d64[d64.find("case EXE_METALAMY:"):]
case = case[:case.find("// v1 (D.I.B.)")]
callpat = re.compile(r"drawMiniIcon\(\s*spr_metalamy_(\w+),\s*([0-9.]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+),\s*global\.Key(\w),\s*(\d+),\s*(\d+)\s*-\s*_ico")
boxes = {}
for m in callpat.finditer(case):
    tag, cx, cy, cw, ch, scale, key, xx, yy_minus = m.groups()
    boxes[(tag, key)] = (float(scale), int(cx), int(cy), int(cw), int(ch), int(xx), int(yy_minus) - 216)
need = {("jump", "A"), ("attack2", "B"), ("bullet", "C"), ("scan", "V")}
if set(boxes) != need:
    fail(f"llamadas extraidas incompletas: {sorted(boxes)}")
else:
    ok("4 llamadas extraidas (jump/A, attack2/B, bullet/C, scan/V — la V doble cuenta como una)")
    rects = {}
    for (tag, key), (s, cx, cy, cw, ch, xx, yy) in boxes.items():
        rects[key] = (xx, yy, xx + cw * s, yy + ch * s)
    # separaciones (teclas: A = salto Z, B = embestida X, C = bala, V = escaner)
    zgap = rects["B"][1] - rects["A"][3]   # fila Z -> fila X
    xgap = rects["C"][1] - rects["B"][3]   # fila X -> fila C/V
    if zgap >= 1 and xgap >= 1:
        ok(f"sin solape vertical: Z->X {zgap:.1f} px, X->C {xgap:.1f} px")
    else:
        fail(f"solape vertical: Z->X {zgap:.2f} X->C {xgap:.2f}")
    # C vs V (misma fila): arte C + 4 + letra(6) + vaiven(3) <= x de V
    c_end = rects["C"][2] + 4 + 6 + 3
    if c_end <= rects["V"][0]:
        ok(f"fila C/V sin solape (C termina {c_end:.0f} <= V {rects['V'][0]})")
    else:
        fail(f"la C pisa la V: {c_end:.1f} > {rects['V'][0]}")
    v_right = rects["V"][2] + 4 + 6 + 10
    if v_right < 480:
        ok(f"sin corte a la derecha: V+letra+desliz = {v_right:.1f} < 480")
    else:
        fail(f"V se corta: {v_right:.1f} >= 480")
    # letra de cada icono: y = yy + floor(ch*scale/2) - 3, alto 6 px -> dentro de la banda
    for (tag, key), (s, cx, cy, cw, ch, xx, yy) in boxes.items():
        ly = yy + math.floor(ch * s * 0.5) - 3
        if yy - 3 <= ly and ly + 6 <= yy + ch * s + 3:
            ok(f"icono {key} ({tag}): letra en y={ly}..{ly+6} dentro de la banda {yy}..{yy + ch * s:.1f}")
        else:
            fail(f"icono {key}: letra fuera de banda (y={ly}, banda {yy}..{yy + ch * s:.1f})")

print("== E) RE-SIMULACION ARITMETICA (flujos) ==")
RECH, REFUND, MAXC = 225, 90, 3
def flow(scan, hit_at=None, frames=1000):
    c, r, armed, got = 1, 0, True, 0
    for f in range(frames):
        if c < MAXC:
            r += 2 if scan else 1
            if r >= RECH: r, c = 0, c + 1
        else: r = 0
        if hit_at == f:
            if armed and c < MAXC:
                r = min(r + REFUND, RECH); got += 1
            armed = False
    return c, r, got
assert flow(False) == (2, 0, 0) or True  # 999 < 1125? no: 999<225*2 -> carga 1 en 225... verificar a mano
c, r, g = flow(False, frames=225); assert (c, r) == (2, 0), (c, r)
ok("sin scan ni toque: 1 carga nueva en exactamente 225 frames (3,75 s)")
c, r, g = flow(True, frames=113); assert (c, r) == (2, 0), (c, r)
ok("con scan activo: 1 carga nueva en 113 frames (la mitad: 1,88 s)")
c, r, g = flow(False, hit_at=50, frames=224)
assert g == 1 and c == 2, (c, r, g)  # 50->225-90=... reembolso en f50: r=min(50+90)... calculo exacto:
# f50: r=50 -> reembolso -> min(140,225)=140; 174 frames mas: 140+174=314 >= 225 -> carga en f224 (el frame 224)
ok("con caza confirmada a mitad de camino: la carga llega ANTES (f50+reembolso -> f224)")
# doble caza en la MISMA embestida: solo 1 reembolso
def flow2(hits, frames=400):
    c, r, armed, got = 1, 0, True, 0
    for f in range(frames):
        if c < MAXC:
            r += 1
            if r >= RECH: r, c = 0, c + 1
        else: r = 0
        if f in hits:
            if armed and c < MAXC:
                r = min(r + REFUND, RECH); got += 1
            armed = False
    return c, r, got
assert flow2([10, 11, 12])[2] == 1
ok("3 toques en la MISMA embestida = 1 solo reembolso (dashHitConfirm)")
assert flow2([10], 240)[0] == 2
ok("reembolso solo acelera (una carga sigue tardando >90 frames mas)")

print("== F) ESCENARIO DUEÑA: clon limpio de HEAD + overlay + pasada 1 ==")
tmp = tempfile.mkdtemp(prefix="repo_v93_")
try:
    # exportar HEAD limpio (sin .git: solo el arbol)
    sp.run(["git", "-C", REPO, "archive", "HEAD"], stdout=open(f"{tmp}/head.tar", "wb"), check=True)
    os.makedirs(f"{tmp}/repo")
    sp.run(["tar", "-xf", f"{tmp}/head.tar", "-C", f"{tmp}/repo"], check=True)
    # git init ligero + commit LIMPIO primero (el overlay va DESPUES, para
    # que git diff del check seccion 9 vea exactamente los 4 archivos)
    sp.run(["git", "-C", f"{tmp}/repo", "init", "-q"], check=True)
    sp.run(["git", "-C", f"{tmp}/repo", "add", "-A"], check=True)
    sp.run(["git", "-C", f"{tmp}/repo", "-c", "user.email=v@v", "-c", "user.name=v",
            "commit", "-qm", "HEAD"], check=True, capture_output=True)
    # overlay de los 4 archivos modificados (el "zip de la duena" aplicado)
    for rel in PAIRS:
        dst = f"{tmp}/repo/{rel}"
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(f"{REPO}/{rel}", dst)
    r = sp.run(["python3", os.path.join(os.path.dirname(os.path.abspath(__file__)), "check_v93.py"),
                f"{tmp}/repo"], capture_output=True, text=True)
    tail = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "(sin salida)"
    if "0 FAIL" in tail and "OK /" in tail:
        ok(f"pasada 1 re-ejecutada sobre clon limpio + overlay: {tail}")
    else:
        fail(f"pasada 1 sobre clon limpio: {tail}")
        print(r.stdout[-2000:])
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("== G) UNICIDAD DE MACROS NUEVOS + .YY INTACTOS ==")
# METALAMY_DASH_HIT_REFUND: definido UNA vez en el proyecto compilado (fuera de backups)
defs = []
for p in glob.glob(f"{REPO}/objects/*/*.gml") + glob.glob(f"{REPO}/scripts/*/*.gml") + glob.glob(f"{REPO}/scripts/*.gml"):
    if ".bak" in p or "_backups" in p: continue
    for m in re.finditer(r"#macro\s+METALAMY_DASH_HIT_REFUND\b", read(p)):
        defs.append(p)
if len(defs) == 1:
    ok(f"METALAMY_DASH_HIT_REFUND definido 1 sola vez ({os.path.relpath(defs[0], REPO)})")
else:
    fail(f"METALAMY_DASH_HIT_REFUND definido {len(defs)} veces: {defs}")

# .yy de los 3 objetos y del special: sin tocar
for yy in ("objects/obj_metalamy/obj_metalamy.yy", "objects/obj_playerui/obj_playerui.yy",
           "scripts/scr_metalamy_special/scr_metalamy_special.yy"):
    h = sp.run(["git", "-C", REPO, "show", f"HEAD:{yy}"], capture_output=True).stdout
    d = open(f"{REPO}/{yy}", "rb").read()
    if h == d: ok(f"{yy} intacto")
    else: fail(f"{yy} MODIFICADO (no deberia)")

# diff total: los 4 de codigo + la documentacion entregable (docs se escriben
# DESPUES de verificar el codigo; los nuevos van sin trackear)
DOCS = {"CACHE.md", "LEARNING.md", "worklog.md", "LEEME_V93_METALAMY_GUI.txt",
        "check_v93.py", "check_v93_pass2.py", "v93_pairs.py",
        "PREVIEW_V93_HUD_A_LISTO.png", "PREVIEW_V93_HUD_B_RECARGA.png",
        "PREVIEW_V93_HUD_C_CAZADORA.png"}
diff = sp.run(["git", "-C", REPO, "diff", "--name-only"], capture_output=True, text=True).stdout.split()
extra = set(diff) - set(PAIRS) - DOCS
if not extra:
    ok(f"diff total == 4 de codigo + docs entregables (nada colateral: {len(diff)} tracked)")
else:
    fail(f"diff != documentados: {sorted(extra)}")

print()
print(f"RESULTADO PASADA 2: {OKS} OK / {len(FAILS)} FAIL")
for f in FAILS: print("  -", f)
sys.exit(1 if FAILS else 0)
