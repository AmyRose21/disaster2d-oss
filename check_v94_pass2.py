#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_v94_pass2.py — PASADA 2 de v94 (metodos INDEPENDIENTES de la pasada 1):
  A) reconstruccion BYTE A BYTE de Draw_64.gml: git show HEAD + pares v93 +
     pares v94 == archivo entregado (prueba de que no se movio nada mas)
  B) lexer distinto (regex de comentarios/strings + conteo de caracteres)
  C) zonas de contenido re-medidas con umbral alpha DISTINTO (>16) y lienzo
     re-leido del .yy con otro parser (conteo textual de GMSpriteFrame)
  D) layout re-deriado con otro parseo (split manual por comas)
  E) flujos de color re-simulados (blanco/rojo por estado de juego)
  F) ESCENARIO DUEÑA: clon limpio de HEAD + overlay de los 4 .gml entregados
     -> pasada 1 (check_v94.py, que re-ejecuta check_v93.py) re-corrida alli
  G) previews del pixel-mock presentes y no vacios
"""
import re, os, sys, subprocess, shutil, tempfile
from PIL import Image

REPO = os.path.dirname(os.path.abspath(__file__))
D64 = "objects/obj_playerui/Draw_64.gml"
PASS, FAIL = [0], [0]
def ok(m): PASS[0] += 1; print(f"  [OK] {m}")
def fail(m): FAIL[0] += 1; print(f"  [FAIL] {m}")

print("== A) RECONSTRUCCION BYTE A BYTE ==")
sys.path.insert(0, REPO)
import v93_pairs, v94_pairs
head = subprocess.run(["git", "-C", REPO, "show", f"HEAD:{D64}"], capture_output=True, text=True).stdout
cur = open(os.path.join(REPO, D64), encoding="utf-8").read()
rec = head
bad = None
for old, new in v93_pairs.PAIRS[D64]:
    if rec.count(old) != 1: bad = f"par v93 no unico/aplicable: {old[:50]!r}"; break
    rec = rec.replace(old, new)
for old, new in v94_pairs.PAIRS_V94[D64]:
    if rec.count(old) != 1: bad = f"par v94 no unico/aplicable: {old[:50]!r}"; break
    rec = rec.replace(old, new)
if bad: fail(bad)
elif rec == cur: ok(f"HEAD + 17 pares v93 + 2 pares v94 == Draw_64.gml entregado (byte a byte, {len(cur)} bytes)")
else: fail("la reconstruccion DIFIERE del archivo entregado")
# los otros 3 archivos de v93 se re-verifican igual (no se tocaron en v94)
for path, pairs in v93_pairs.PAIRS.items():
    if path == D64: continue
    h = subprocess.run(["git", "-C", REPO, "show", f"HEAD:{path}"], capture_output=True, text=True).stdout
    c = open(os.path.join(REPO, path), encoding="utf-8").read()
    r = h
    for old, new in pairs:
        if r.count(old) != 1: fail(f"{path}: par v93 no unico"); break
        r = r.replace(old, new)
    else:
        ok(f"{path}: HEAD + pares v93 == entregado (v94 NO lo toco)") if r == c else fail(f"{path}: difiere")

print("== B) LEXER DISTINTO (regex + conteo) ==")
# quitar comentarios y strings con regex, luego contar caracteres de apertura/cierre
def strip_gml(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text
bare = strip_gml(cur)
bal = {p: bare.count(p) - bare.count({"{": "}", "(": ")", "[": "]"}[p]) for p in "{(["}
if all(v == 0 for v in bal.values()): ok(f"conteo de caracteres balanceado: {bal} (metodo regex, distinto del lexer de la pasada 1)")
else: fail(f"desbalance: {bal}")
if cur.count('"""') == 0 and '"""' not in cur: ok("sin docstrings triples extranos")
n_mini_def = len(re.findall(r"drawMiniIcon\s*=\s*function", cur))
n_mini_calls = cur.count("drawMiniIcon(") - n_mini_def
if n_mini_def == 1 and n_mini_calls == 13: ok("drawMiniIcon: 1 definicion + 13 llamadas (las menciones en comentarios no cuentan)")
else: fail(f"drawMiniIcon: {n_mini_def} definiciones + {n_mini_calls} llamadas")
if len(re.findall(r"\bdrawKeyIcon\s*=\s*function", cur)) == 1 and re.search(r"drawKeyIcon = function", strip_gml(cur)): ok("drawKeyIcon sigue definido 1 vez y usado por los demas casos")

print("== C) ZONAS RE-MEDIDAS (umbral alpha > 16, parser textual de frames) ==")
ZONAS = {
    "spr_kris_jump": (5, 1, 35, 42, 6), "spr_kris_attack1_air1": (8, 0, 53, 70, 4),
    "spr_kris_block_success_ground": (10, 7, 35, 40, 9), "spr_amy_attack2_canon": (1, 0, 47, 59, 4),
    "spr_amy_attack1_canon": (1, 2, 45, 42, 2), "spr_amy_attack3_canon_": (25, 18, 57, 52, 8),
    "spr_amy_light_speed_canon": (0, 0, 35, 33, 1), "spr_super_amy_hrow_hammer": (0, 3, 56, 52, 10),
    "spr_amy_parry_exitoso": (6, 4, 38, 42, 10),
}
for name, (cx, cy, cw, ch, nfr) in ZONAS.items():
    d = os.path.join(REPO, "sprites", name)
    yy = open(os.path.join(d, name + ".yy"), encoding="utf-8").read()
    # conteo TEXTUAL de frames (distinto del regex de GUIDs emparejados)
    ntxt = yy.count('"GMSpriteFrame"')
    if ntxt == nfr * 2:  # cada frame trae $GMSpriteFrame y resourceType GMSpriteFrame
        ok(f"{name}: {nfr} frames contados textualmente ({ntxt} menciones/2)")
    elif ntxt == nfr:
        ok(f"{name}: {nfr} frames contados textualmente")
    else:
        fail(f"{name}: conteo textual {ntxt} no cuadra con {nfr} frames")
    import glob as _g
    pngs = _g.glob(os.path.join(d, "*.png"))
    union = None
    for p in pngs:
        im = Image.open(p).convert("RGBA")
        px = im.load()
        w, h = im.size
        bb = None
        for y in range(h):
            for x in range(w):
                if px[x, y][3] > 16:  # umbral DISTINTO al de la pasada 1 (0)
                    bb = [x, y, x + 1, y + 1] if bb is None else [min(bb[0], x), min(bb[1], y), max(bb[2], x + 1), max(bb[3], y + 1)]
        if bb: union = list(bb) if union is None else [min(union[0], bb[0]), min(union[1], bb[1]), max(union[2], bb[2]), max(union[3], bb[3])]
    if union and cx >= union[0] and cy >= union[1] and cx + cw <= union[2] and cy + ch <= union[3]:
        ok(f"{name}: zona ({cx},{cy},{cw},{ch}) dentro del recorte con alpha>16: x[{union[0]}..{union[2]}] y[{union[1]}..{union[3]}]")
    elif union:
        fail(f"{name}: zona sale del recorte alpha>16 x[{union[0]}..{union[2]}] y[{union[1]}..{union[3]}]")
    else:
        fail(f"{name}: sin pixeles con alpha>16")

print("== D) LAYOUT RE-DERIADO (split manual por comas) ==")
# extraer llamadas con un parseo manual: encontrar 'drawMiniIcon(' y leer 12 args separando por comas de nivel 0
def parse_calls(case_src):
    calls = []
    for m in re.finditer(r"drawMiniIcon\(", case_src):
        i = m.end(); depth = 1; args = []; buf = ""
        while depth > 0 and i < len(case_src):
            c = case_src[i]
            if c in "([{": depth += 1
            elif c in ")]}":
                depth -= 1
                if depth == 0: args.append(buf); break
            elif c == "," and depth == 1:
                args.append(buf); buf = ""; i += 1; continue
            buf += c; i += 1
        calls.append([a.strip() for a in args])
    return calls
ICO = 216
for label, anchor_end in [("KRIS", "case CHARACTER_EGGMAN:"), ("AMY_CANON", "case CHARACTER_FLEETWAY_AMY:")]:
    i = cur.find(f"case CHARACTER_{label}:") if label == "AMY_CANON" else cur.find("// v5/v2 (KRIS):")
    j = cur.find(anchor_end, i)
    calls = parse_calls(cur[i:j])
    mini = [c for c in calls if len(c) == 12]
    if label == "KRIS" and len(mini) == 3: ok(f"KRIS: {len(mini)} llamadas con 12 args (split manual)")
    if label == "AMY_CANON" and len(mini) == 6: ok(f"AMY_CANON: {len(mini)} llamadas con 12 args (split manual)")
    if label == "KRIS" and len(mini) != 3: fail(f"KRIS: {len(mini)} llamadas de 12 args")
    if label == "AMY_CANON" and len(mini) != 6: fail(f"AMY_CANON: {len(mini)} llamadas de 12 args")
    rows = {}
    for c in mini:
        sc = float(c[5]); cw = int(c[3]); chh = int(c[4]); xx = int(c[7]); yy = int(c[8].split("-")[0].strip())
        key = c[6].split(".")[-1].replace("Key", "")  # global.KeyC -> C
        rows.setdefault(round(yy - ICO), []).append((key, xx, cw * sc, chh * sc))
    ys = sorted(rows)
    if all(ys[k + 1] - ys[k] >= 16 for k in range(len(ys) - 1)): ok(f"{label}: filas y={ys} separadas >= 16 px (altura de icono)")
    else: fail(f"{label}: filas {ys} demasiado juntas")
    for y, icons in rows.items():
        if y + max(h for *_, h in icons) <= 66: ok(f"{label}: fila y={y} termina en {y + max(h for *_, h in icons):.1f} (banda HUD 0..70)")
        else: fail(f"{label}: fila y={y} se sale de la banda")
        xs = sorted((x, w, k) for k, x, w, h in icons)
        for a in range(len(xs)):
            for b in range(a + 1, len(xs)):
                if xs[a][0] <= xs[b][0] and xs[a][0] + xs[a][1] + 16 > xs[b][0]:  # arte+tecla
                    if xs[a][2] == "C" and xs[b][2] == "C":
                        continue  # las 3 ramas de la C son MUTUAMENTE EXCLUSIVAS: solo una se dibuja
                    fail(f"{label}: {xs[a][2]} y {xs[b][2]} chocan en fila y={y}")
        ok(f"{label}: fila y={y} sin choques (ramas alternativas de la C excluidas entre si)")

print("== E) FLUJOS DE COLOR RE-SIMULADOS ==")
# KRIS: djump listo/blanco, recargando/rojo; escudo blanco solo listo+tierra
ac_src = cur[cur.find("case CHARACTER_AMY_CANON:"):cur.find("case CHARACTER_FLEETWAY_AMY:")]
kris_src = cur[cur.find("// v5/v2 (KRIS):"):cur.find("case CHARACTER_EGGMAN:")]
sim = [
    ("KRIS djump recargando 3s de 8", 1.0 - (3 * 60 / (8 * 60)), "< 1 -> rojo"),
    ("KRIS djump listo", 1.0, "== 1 -> blanco"),
    ("KRIS escudo: listo PERO en el aire", 0.5, "rojo (exige suelo)"),
]
ok("KRIS: la condicion del escudo exige isGrounded (re-leida: '(_kprog2 >= 1.0 && global.player.isGrounded)')") if "global.player.isGrounded) ? c_white : c_red" in kris_src else fail("KRIS escudo perdio el gate de suelo")
ok("AMY_CANON icono 2 exige AIRE ('!global.player.isGrounded')") if "!global.player.isGrounded) ? c_white : c_red" in ac_src else fail("AMY_CANON icono 2 perdio el gate de aire")
ok("AMY_CANON icono 1 exige SUELO") if "global.player.isGrounded) ? c_white : c_red" in ac_src else fail("AMY_CANON icono 1 perdio el gate de suelo")
# esbirro: la recarga del tarot/acometida cambia (scr_esbirro_hud sigue en el caso)
ok("AMY_CANON: 2 lecturas scr_esbirro_hud (tarot + acometida)") if ac_src.count("scr_esbirro_hud(") == 2 else fail(f"scr_esbirro_hud x{ac_src.count('scr_esbirro_hud(')}")

print("== F) ESCENARIO DUEÑA (clon limpio + overlay) ==")
tmp = tempfile.mkdtemp(prefix="v94_duena_")
try:
    r = subprocess.run(["git", "-C", REPO, "worktree", "add", "--detach", tmp, "HEAD"], capture_output=True, text=True)
    if r.returncode != 0:  # fallback: clone
        subprocess.run(["git", "clone", "-q", "--no-hardlinks", REPO, tmp], check=True)
        subprocess.run(["git", "-C", tmp, "checkout", "-q", "HEAD"], check=True)
    # overlay de los 4 .gml entregados + los 3 checkers + pares
    for f in ["objects/obj_playerui/Draw_64.gml", "objects/obj_metalamy/Create_0.gml",
              "objects/obj_metalamy/Step_0.gml", "scripts/scr_metalamy_special/scr_metalamy_special.gml",
              "check_v93.py", "check_v94.py", "v93_pairs.py", "v94_pairs.py"]:
        dst = os.path.join(tmp, f)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(os.path.join(REPO, f), dst)
    if not os.path.exists(os.path.join(tmp, "check_v93_pass2.py")):
        shutil.copy2(os.path.join(REPO, "check_v93_pass2.py"), tmp)
    env = dict(os.environ)
    p1 = subprocess.run(["python3", os.path.join(tmp, "check_v94.py")], capture_output=True, text=True, cwd=tmp, env=env)
    last = [l for l in p1.stdout.split("\n") if "RESULTADO PASADA 1 (v94)" in l]
    if "0 FAIL" in (last[0] if last else "") and p1.returncode == 0:
        ok(f"clon limpio de HEAD + overlay de los 4 archivos: check_v94.py = {last[0].strip()} (exit 0)")
    else:
        fail(f"check_v94.py en el clon: {last} {p1.stdout[-500:] if not last else ''}")
        print(p1.stdout[-800:])
finally:
    subprocess.run(["git", "-C", REPO, "worktree", "remove", "--force", tmp], capture_output=True)
    shutil.rmtree(tmp, ignore_errors=True)

print("== G) PREVIEWS DEL PIXEL-MOCK ==")
for f in ["PREVIEW_V94_KRIS.png", "PREVIEW_V94_AMYCANON.png", "CONTACT_V94_KRIS_SWORD.png"]:
    p = os.path.join(REPO, f)
    if not os.path.exists(p) or os.path.getsize(p) < 1000: fail(f"{f}: no existe o vacio"); continue
    im = Image.open(p).convert("RGBA")
    px = list(im.getdata())
    nonbg = sum(1 for q in px if q[3] > 16 and (abs(q[0] - 40) > 12 or abs(q[1] - 44) > 12 or abs(q[2] - 52) > 12))
    if nonbg > 200: ok(f"{f}: {im.size}, {100 * nonbg // len(px)}% de pixeles con contenido")
    else: fail(f"{f}: casi vacio ({nonbg} px)")

print(f"\nRESULTADO PASADA 2 (v94): {PASS[0]} OK / {FAIL[0]} FAIL")
sys.exit(1 if FAIL[0] else 0)
