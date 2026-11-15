#!/usr/bin/env python3
"""rouge_verify.py — validación completa de la restauración de sprites de Rouge."""
import json, os, re, sys, hashlib

def load_gm(path):
    """json del formato GM (comas colgantes como el resto del repo)"""
    txt = open(path).read()
    return json.loads(re.sub(r',\s*([}\]])', r'\1', txt))

REPO = "/home/z/my-project/disaster2d-oss"
SPR  = os.path.join(REPO, "sprites")
YYP  = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")
ZIP  = "/home/z/my-project/upload/Sprite de rouge.zip"

fails, warns, oks = [], [], []

def ok(msg): oks.append(msg); print(f"  OK  {msg}")
def fail(msg): fails.append(msg); print(f"  FAIL {msg}")
def warn(msg): warns.append(msg); print(f"  WARN {msg}")

import zipfile
zf = zipfile.ZipFile(ZIP)

# 1) TODAS las tiras referenciadas por el código existen en disco
code_refs = set()
for root, _, files in os.walk(os.path.join(REPO, "scripts")):
    for f in files:
        if f.endswith(".gml"):
            t = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
            code_refs |= {m for m in re.findall(r'\bspr_rouge[a-z0-9_]*\b', t) if m != 'spr_rouge_'}
for root, _, files in os.walk(os.path.join(REPO, "objects")):
    for f in files:
        if f.endswith(".gml"):
            t = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
            code_refs |= set(re.findall(r'\bspr_rouge[a-z0-9_]*\b|\bspr_menu_rouge\b', t))

missing_on_disk = [r for r in sorted(code_refs)
                   if not os.path.isdir(os.path.join(SPR, r))]
if missing_on_disk:
    fail(f"referencias sin sprite en disco: {missing_on_disk}")
else:
    ok(f"las {len(code_refs)} referencias spr_rouge*/menu_rouge del código existen en disco")

# refs en comentarios no cuentan: filtrar refs REALES (sin // line)
real_refs = set()
for root, _, files in os.walk(os.path.join(REPO, "scripts")):
    for f in files:
        if not f.endswith(".gml"): continue
        t = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
        for line in t.split("\n"):
            if "//" in line: line = line.split("//")[0]
            real_refs |= {m for m in re.findall(r'\bspr_rouge[a-z0-9_]*\b|\bspr_menu_rouge\b', line) if m != 'spr_rouge_'}
missing_real = [r for r in sorted(real_refs) if not os.path.isdir(os.path.join(SPR, r))]
if missing_real:
    fail(f"refs REALES sin sprite: {missing_real}")
else:
    ok(f"las {len(real_refs)} referencias REALES (sin comentarios) están en disco")

# 2) cada .yy es JSON válido y sus PNG existen (root + layers/<frame>/<layer>)
tiras = sorted(d for d in os.listdir(SPR)
               if d.startswith("spr_rouge") or d == "spr_menu_rouge")
for name in tiras:
    d = os.path.join(SPR, name)
    yyfile = os.path.join(d, name + ".yy")
    try:
        yy = load_gm(yyfile)
    except Exception as e:
        fail(f"{name}.yy JSON inválido: {e}")
        continue
    frames = [f["%Name"] for f in yy["frames"]]
    layer = yy["layers"][0]["%Name"]
    pngs = [f for f in os.listdir(d) if f.endswith(".png")]
    if len(pngs) != len(frames):
        fail(f"{name}: {len(pngs)} PNG root vs {len(frames)} frames declarados")
    for g in frames:
        if not os.path.exists(os.path.join(d, g + ".png")):
            fail(f"{name}: falta root {g}.png")
        lp = os.path.join(d, "layers", g, layer + ".png")
        if not os.path.exists(lp):
            fail(f"{name}: falta layers/{g}/{layer}.png")
        else:
            # root == layer (mismo contenido)
            h1 = hashlib.md5(open(os.path.join(d, g + ".png"), "rb").read()).hexdigest()
            h2 = hashlib.md5(open(lp, "rb").read()).hexdigest()
            if h1 != h2:
                fail(f"{name}: root y layer difieren en frame {g}")
    # tracks keyframes == frames
    tr = yy["sequence"]["tracks"][0]["keyframes"]["Keyframes"]
    if len(tr) != len(frames):
        fail(f"{name}: {len(tr)} keyframes vs {len(frames)} frames")
    # dimensiones coherentes con los PNG
    from PIL import Image
    im = Image.open(os.path.join(d, frames[0] + ".png"))
    if (im.size[0] != yy["width"]) or (im.size[1] != yy["height"]):
        fail(f"{name}: .yy {yy['width']}x{yy['height']} vs PNG {im.size}")
    # bbox dentro del lienzo
    if not (0 <= yy["bbox_left"] <= yy["bbox_right"] < yy["width"] and
            0 <= yy["bbox_top"] <= yy["bbox_bottom"] < yy["height"]):
        fail(f"{name}: bbox fuera del lienzo {yy['bbox_left']},{yy['bbox_top']},{yy['bbox_right']},{yy['bbox_bottom']}")
    # xorigin/yorigin dentro del lienzo
    seq = yy["sequence"]
    if not (0 <= seq["xorigin"] < yy["width"] and 0 <= seq["yorigin"] < yy["height"]):
        fail(f"{name}: origin ({seq['xorigin']},{seq['yorigin']}) fuera del lienzo {yy['width']}x{yy['height']}")
ok(f"{len(tiras)} tiras validadas (JSON + PNG + layers + bbox + origin)")

# 3) yyp: sin duplicados, rutas correctas
yyp = open(YYP).read()
names = re.findall(r'"id":\{"name":"(spr_rouge[a-z0-9_]*|spr_menu_rouge)"', yyp)
if len(names) != len(set(names)):
    from collections import Counter
    dup = [n for n, c in Counter(names).items() if c > 1]
    fail(f"duplicados en yyp: {dup}")
else:
    ok(f"yyp sin duplicados ({len(names)} entradas rouge)")
for n in set(names) | set(tiras):
    if n not in set(names):
        fail(f"{n} en disco pero NO registrado en yyp")
    if not os.path.exists(os.path.join(SPR, n, n + ".yy")):
        fail(f"yyp registra {n} pero falta sprites/{n}/{n}.yy")
missing_reg = [t for t in tiras if t not in set(names)]
if missing_reg:
    fail(f"sin registrar en yyp: {missing_reg}")
else:
    ok("todas las tiras de disco están registradas en el yyp")

# 4) JSON global del yyp
try:
    j = load_gm(YYP)
    ok(f"yyp es JSON válido ({len(j['resources']) if 'resources' in j else 'n'} recursos)")
except Exception as e:
    # el yyp del repo usa formato con comas colgantes — probar tolerante
    txt = open(YYP).read()
    try:
        json.loads(re.sub(r',\s*([}\]])', r'\1', txt))
        ok("yyp es JSON válido (tras tolerar comas colgantes, como el resto del repo)")
    except Exception as e2:
        fail(f"yyp JSON inválido: {e2}")

# 5) arte == zip (pixel-exacto) para las tiras zip
import io
from PIL import Image
CHECK = ["spr_rouge_idle","spr_rouge_walk","spr_rouge_run","spr_rouge_jump",
         "spr_rouge_fall","spr_rouge_hurt","spr_rouge_dead","spr_rouge_lookup",
         "spr_rouge_lookdown","spr_rouge_emotion1","spr_rouge_emotion2",
         "spr_rouge_emotion3","spr_rouge_balancing","spr_rouge_zipline"]
for base in CHECK:
    zframes = {}
    for n in zf.namelist():
        if n.startswith(base + "/") and n.endswith(".png"):
            idx = int(n.split("/")[-1].rsplit("_", 1)[1].split(".")[0])
            zframes[idx] = Image.open(io.BytesIO(zf.read(n))).convert("RGBA")
    d = os.path.join(SPR, base)
    yy = load_gm(os.path.join(d, base + ".yy"))
    frames = [f["%Name"] for f in yy["frames"]]
    if len(frames) != len(zframes):
        warn(f"{base}: {len(frames)}f importados vs {len(zframes)}f zip")
        continue
    diff = 0
    for k, g in enumerate(frames):
        a = Image.open(os.path.join(d, g + ".png")).convert("RGBA")
        b = zframes[k]
        if list(a.getdata()) != list(b.getdata()): diff += 1
    if diff:
        fail(f"{base}: {diff} frames difieren del zip")
    else:
        ok(f"{base}: {len(frames)} frames pixel-idénticos al zip")

# 6) nega = inversión exacta
for neg, base in [("spr_rougenega_idle","spr_rouge_idle"),
                  ("spr_rougenega_walk","spr_rouge_walk"),
                  ("spr_rougenega_balancing","spr_rouge_balancing"),
                  ("spr_rougenega_attack1","spr_rouge_attack1")]:
    dy = os.path.join(SPR, neg); dx = os.path.join(SPR, base)
    yyb = load_gm(os.path.join(dx, base + ".yy"))
    yyh = load_gm(os.path.join(dy, neg + ".yy"))
    fb = [f["%Name"] for f in yyb["frames"]]
    fn = [f["%Name"] for f in yyh["frames"]]
    if len(fb) != len(fn):
        fail(f"{neg}: {len(fn)}f vs base {len(fb)}f"); continue
    bad = 0
    for gb, gn in zip(fb, fn):
        a = Image.open(os.path.join(dx, gb + ".png")).convert("RGBA")
        b = Image.open(os.path.join(dy, gn + ".png")).convert("RGBA")
        for x, y in zip(a.getdata(), b.getdata()):
            if y[:3] != (255 - x[0], 255 - x[1], 255 - x[2]) or y[3] != x[3]:
                bad += 1; break
    if bad: fail(f"{neg}: {bad} frames no son inversión exacta")
    else: ok(f"{neg}: {len(fn)} frames inversión 255-canal exacta")

# 7) attack1/attack2 = frames 0/1 del zip attack
zip_atk = [n for n in zf.namelist() if n.startswith("spr_rouge_attack/") and n.endswith(".png")]
if len(zip_atk) == 2:
    for name, zidx in [("spr_rouge_attack1", 0), ("spr_rouge_attack2", 1)]:
        d = os.path.join(SPR, name)
        yy = load_gm(os.path.join(d, name + ".yy"))
        g = yy["frames"][0]["%Name"]
        a = Image.open(os.path.join(d, g + ".png")).convert("RGBA")
        b = Image.open(io.BytesIO(zf.read(f"spr_rouge_attack/spr_rouge_attack_{zidx}.png"))).convert("RGBA")
        if list(a.getdata()) == list(b.getdata()):
            ok(f"{name} == zip attack frame {zidx} (pixel-exacto)")
        else:
            fail(f"{name} != zip attack frame {zidx}")


# 8) ESTRUCTURA RECURSIVA canon: cada .yy generado debe tener EXACTAMENTE
#    las mismas claves (mismo orden) que spr_knux_idle en todos los niveles
def keys_shape(obj, prefix=""):
    """firma recursiva de claves/orden de un objeto GM (valores ignorados)"""
    if isinstance(obj, dict):
        return tuple((k, keys_shape(v, prefix + "." + k)) for k, v in obj.items())
    if isinstance(obj, list):
        if not obj: return ("EMPTYLIST",)
        return ("LIST", keys_shape(obj[0], prefix))
    return ("ATOM", type(obj).__name__)

canon_spr = load_gm(os.path.join(SPR, "spr_knux_idle", "spr_knux_idle.yy"))
canon_shape = keys_shape(canon_spr)

bad = 0
for name in tiras:
    try:
        yy = load_gm(os.path.join(SPR, name, name + ".yy"))
    except Exception as e:
        fail(f"{name}: no parsea ({e})"); bad += 1; continue
    if keys_shape(yy) != canon_shape:
        # localizar la diferencia
        def walk(a, b, path):
            if isinstance(a, dict) and isinstance(b, dict):
                ka, kb = list(a.keys()), list(b.keys())
                if ka != kb:
                    return path + f" claves {ka} vs {kb}"
                for k in ka:
                    r = walk(a[k], b[k], path + "." + k)
                    if r: return r
                return None
            if isinstance(a, list) and isinstance(b, list):
                if len(a) != len(b):
                    return path + f" largo {len(a)} vs {len(b)}"
                for i, (x, y) in enumerate(zip(a, b)):
                    r = walk(x, y, path + f"[{i}]")
                    if r: return r
                return None
            if type(a) is not type(b):
                return path + f" tipo {type(a).__name__} vs {type(b).__name__}"
            return None
        diff = walk(load_gm(os.path.join(SPR, name, name + ".yy")), canon_spr, name)
        fail(f"{name}: estructura != canon -> {diff}")
        bad += 1
if not bad:
    ok(f"las {len(tiras)} tiras tienen la MISMA estructura de claves que spr_knux_idle (canon, recursivo)")

print(f"\n===== RESULTADO: {len(oks)} OK / {len(warns)} WARN / {len(fails)} FAIL =====")
sys.exit(1 if fails else 0)

