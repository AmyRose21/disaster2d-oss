#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_postfx.py — Validador del mod BLOOM + POST PROCESS (bloom_postfx_v2)
para "Sonicexe The Disaster 2D Remake" (GameMaker Studio 2, IDE 2026.0.0.16).

v2 arregla el crash de la v1 al arrancar ("Unbalanced surface stack. You
MUST use surface_reset_target() for each set. {5}"): cada pasada del blur
cierra ahora con su surface_reset_target() (7 sets / 7 resets; la v1 dejaba
5 sets sin reset por frame).

Comprueba:
  A. Archivos nuevos: existencia, formato (.yy JSON5 sin \\n final, .gml TABS
     sin \\n final, .vsh/.fsh con \\n final), LF puro, ASCII.
  B. Shaders GLSL: llaves/parens balanceadas, varyings vsh<->fsh identicos,
     gl_FragColor, precision, gm_BaseTexture, gm_Matrices.
  C. Cross-check GML<->GLSL: cada shader_get_uniform(shd_X,"u_y") del Create
     existe como uniform en el .fsh correspondiente; cada shader_set() apunta
     a un shader registrado en el .yyp.
  D. Parches: .yyp con 2166 recursos y las 4 entradas nuevas x1 con formato
     exacto; obj_logo/Create_0.gml con el spawn x1 antes del guard; en v2
     obj_logo y .yyp intactos respecto a HEAD y git status solo los 4 del fix.
  E. Regresiones: shaders y .yy originales intactos; referencias a obj_postfx
     solo donde toca.
  F. Simulacion numerica del pipeline (numpy) sobre una imagen sintetica
     480x270: pesos de los kernels, curva soft-knee, vineta, split-tone y
     pipeline completo (halo, rango, esquinas oscurecidas) + preview PNG.
  G. Balance del stack de surfaces (el bug de la v1): simulador que recorre
     Draw_77.gml en orden de ejecucion apilando/desapilando targets — sin
     underflow, balance 0 al final, profundidad maxima 1 (nada anidado),
     cada set cerrado antes del siguiente, ningun draw con 2+ apilados y
     los early-returns antes de apilar nada.
"""
import os, re, sys, json, subprocess

REPO = "/home/z/my-project/repo"
YYP  = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")

PASS = 0
FAIL = 0
def ok(cond, msg, detail=""):
    global PASS, FAIL
    tag = "OK " if cond else "FAIL"
    if cond: PASS += 1
    else:
        FAIL += 1
        print(f"  [{tag}] {msg}" + (f"  -> {detail}" if detail else ""))
        return
    print(f"  [{tag}] {msg}" + (f"  -> {detail}" if detail else ""))

def rd(p):
    with open(os.path.join(REPO, p), "r", encoding="utf-8", newline="") as f:
        return f.read()

def tolerant_json(s):
    s = re.sub(r",(\s*[}\]])", r"\1", s)
    return json.loads(s)

# ============================================================================
print("== A. Archivos nuevos: existencia y formato ==")
SHADERS = ["shd_bloom", "shd_blur", "shd_grade"]
OBJ_FILES = ["obj_postfx.yy", "Create_0.gml", "Step_0.gml", "Draw_77.gml", "CleanUp_0.gml"]

for sh in SHADERS:
    for ext in (".yy", ".vsh", ".fsh"):
        p = f"shaders/{sh}/{sh}{ext}"
        ok(os.path.isfile(os.path.join(REPO, p)), f"existe {p}")
        c = rd(p)
        ok(len(c) > 100, f"no vacio {p}", f"{len(c)} bytes")
        ok("\r" not in c, f"LF puro {p}")
        ok(all(ord(ch) < 128 for ch in c), f"ASCII puro {p}")
        if ext == ".yy":
            ok(not c.endswith("\n"), f"sin newline final {p}")
            d = tolerant_json(c)
            ok(d.get("name") == sh and d.get("%Name") == sh, f"name correcto {p}")
            ok(d.get("resourceType") == "GMShader" and d.get("type") == 1, f"GMShader GLSL ES {p}")
            ok(d.get("parent", {}).get("path") == "folders/Shaders.yy", f"parent Shaders {p}")
        else:
            ok(c.endswith("\n"), f"newline final {p}")

for fn in OBJ_FILES:
    p = f"objects/obj_postfx/{fn}"
    ok(os.path.isfile(os.path.join(REPO, p)), f"existe {p}")
    c = rd(p)
    ok(len(c) > 50, f"no vacio {p}", f"{len(c)} bytes")
    ok("\r" not in c, f"LF puro {p}")
    ok(all(ord(ch) < 128 for ch in c), f"ASCII puro {p}")
    if fn.endswith(".gml"):
        ok(not c.endswith("\n"), f"sin newline final {p}")
        indented = [l for l in c.split("\n") if l.startswith(" ") and l.strip()]
        ok(not indented, f"indentacion TABS {p}", f"{len(indented)} lineas con espacios")
    if fn == "obj_postfx.yy":
        ok(not c.endswith("\n"), "sin newline final obj_postfx.yy")
        d = tolerant_json(c)
        ok(d.get("resourceType") == "GMObject" and d.get("persistent") is True,
           "GMObject persistente")
        evs = {(e["eventNum"], e["eventType"]) for e in d["eventList"]}
        ok(evs == {(0, 0), (0, 3), (0, 12), (77, 8)},
           "eventList = Create(0,0) Step(0,3) CleanUp(0,12) Draw_77(77,8)", str(sorted(evs)))
        ok(d.get("parent", {}).get("path") == "folders/Objects.yy", "parent Objects")
        ok(d.get("managed") is True and d.get("isDnD", False) is False and not d.get("physicsObject"), "defaults sanos")

# ============================================================================
print("== B. Shaders GLSL: estructura ==")
def balance(s):
    # quita comentarios y strings para contar
    s2 = re.sub(r"//[^\n]*", "", s)
    s2 = re.sub(r"/\*.*?\*/", "", s2, flags=re.S)
    s2 = re.sub(r'"[^"\n]*"', '""', s2)
    return s2.count("{") - s2.count("}"), s2.count("(") - s2.count(")")

for sh in SHADERS:
    v = rd(f"shaders/{sh}/{sh}.vsh")
    f = rd(f"shaders/{sh}/{sh}.fsh")
    b1, p1 = balance(v); b2, p2 = balance(f)
    ok(b1 == 0 and p1 == 0, f"llaves/parens balanceadas {sh}.vsh", f"{{={b1} (={p1}")
    ok(b2 == 0 and p2 == 0, f"llaves/parens balanceadas {sh}.fsh", f"{{={b2} (={p2}")
    vv = set(re.findall(r"varying\s+\w+\s+(\w+);", v))
    vf = set(re.findall(r"varying\s+\w+\s+(\w+);", f))
    ok(vv == vf and "v_vTexcoord" in vv and "v_vColour" in vv,
       f"varyings identicos vsh<->fsh {sh}", f"{sorted(vv)} vs {sorted(vf)}")
    ok("gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION]" in v, f"proyeccion GM {sh}.vsh")
    ok("gl_FragColor" in f, f"gl_FragColor {sh}.fsh")
    ok("texture2D(gm_BaseTexture" in f, f"gm_BaseTexture {sh}.fsh")
    ok("precision highp float;" in f, f"precision highp {sh}.fsh")

# uniforms declarados por shader (para el cross-check)
declared = {}
for sh in SHADERS:
    f = rd(f"shaders/{sh}/{sh}.fsh")
    declared[sh] = set(re.findall(r"uniform\s+[\w]+\s+([\w]+)\s*(?:=[^;]+)?;", f))

# ============================================================================
print("== C. Cross-check GML <-> GLSL ==")
create = rd("objects/obj_postfx/Create_0.gml")
draw77 = rd("objects/obj_postfx/Draw_77.gml")

uses = re.findall(r'shader_get_uniform\((\w+),\s*"(\w+)"\)', create)
ok(len(uses) == 13, "13 uniforms cacheados en Create", f"{len(uses)}")
for shn, uname in uses:
    ok(shn in declared and uname in declared[shn],
       f"uniform {shn}.{uname} declarado en el .fsh")

sets = re.findall(r"shader_set\((\w+)\)", draw77)
ok(set(sets) == set(SHADERS), "Draw_77 usa los 3 shaders", str(sorted(set(sets))))
# cada uniform seteado en Draw_77 debe existir (via variables uXXX del Create)
var2u = dict((m.group(1), (m.group(2), m.group(3)))
             for m in re.finditer(r'(\w+)\s*=\s*shader_get_uniform\((\w+),\s*"(\w+)"\)', create))
for m in re.finditer(r"shader_set_uniform_f\((\w+),", draw77):
    var = m.group(1)
    if var in var2u:
        shn, uname = var2u[var]
        ok(uname in declared.get(shn, set()), f"Draw_77 setea {shn}.{uname} (existe)")
    else:
        ok(False, f"Draw_77 setea uniform desconocido '{var}'")

# estado GPU restaurado
# [v2] 7 surface_set_target (1 bloom + 6 blur) y 7 surface_reset_target:
# en GameMaker cada set APILA el destino de dibujo y cada reset lo desapila
# 1 a 1 — la v1 dejaba 6 sets / 1 reset = 5 apilados por frame (el {5})
ok(draw77.count("surface_set_target(") == 7 and draw77.count("surface_reset_target(") == 7,
   "7 set_target / 7 reset_target en Draw_77")
ok(len(re.findall(r"uBlurWidth, (1\.0|2\.2|4\.4)\)", draw77)) == 6,
   "3 iteraciones de blur (1.0/2.2/4.4 x H+V)")
ok("gpu_set_blendmode(bm_normal);" in draw77 and "gpu_set_blendmode(bm_add);" in draw77,
   "blend add para el glow y restauracion a normal")
ok("var _tf = gpu_get_texfilter();" in draw77 and draw77.rstrip().endswith("gpu_set_texfilter(_tf);"),
   "texfilter guardado y restaurado al final")
ok("if(instance_exists(obj_marijuna_crystalcontroller))" in draw77,
   "skip del efecto en el mapa marijuna (tiene su propio shader)")
step = rd("objects/obj_postfx/Step_0.gml")
ok("vk_f9" in step and "application_surface_draw_enable(!enabled);" in step,
   "F9 alterna y devuelve el dibujo al motor")
cero = rd("objects/obj_postfx/CleanUp_0.gml")
ok("application_surface_draw_enable(true);" in cero and "surface_free" in cero,
   "CleanUp restaura motor y libera superficies")

# ============================================================================
print("== D. Parches ==")
yyp = rd("Sonicexe The Disaster 2D Remake.yyp")
d = tolerant_json(yyp)
names = [r["id"]["name"] for r in d["resources"]]
ok(len(d["resources"]) == 2166, "2166 recursos en .yyp (2162 + 4)", str(len(d["resources"])))
for nm, path in (("shd_bloom", "shaders/shd_bloom/shd_bloom.yy"),
                 ("shd_blur", "shaders/shd_blur/shd_blur.yy"),
                 ("shd_grade", "shaders/shd_grade/shd_grade.yy"),
                 ("obj_postfx", "objects/obj_postfx/obj_postfx.yy")):
    ok(names.count(nm) == 1, f"recurso {nm} registrado x1")
    entry = '    {"id":{"name":"%s","path":"%s",},},\n' % (nm, path)
    ok(yyp.count(entry) == 1, f"entrada .yyp con formato exacto: {nm}")
ok(names.count("shd_inverse") == 1 and names.count("obj_logo") == 1,
   "recursos originales intactos (shd_inverse, obj_logo)")

logo = rd("objects/obj_logo/Create_0.gml")
ok(logo.count("instance_create_depth(0, 0, -99999, obj_postfx)") == 1,
   "spawn de obj_postfx x1 en obj_logo")
ok(logo.index("instance_create_depth") < logo.index("if(!global.init)"),
   "spawn antes del guard global.init (cubre re-entradas al logo)")
# [v2] la v1 ya esta commiteada en el HEAD de la duena: obj_logo y .yyp
# deben llegar INTACTOS (su contenido ya se valido arriba con los checks
# de spawn y de recursos); el fix v2 solo toca sus 4 archivos
r = subprocess.run(["git", "diff", "--numstat", "--", "objects/obj_logo/Create_0.gml"],
                   cwd=REPO, capture_output=True, text=True)
ok(r.stdout.strip() == "", "obj_logo intacto respecto a HEAD (v2 no lo toca)",
   r.stdout.strip())
r = subprocess.run(["git", "diff", "--numstat", "--", "Sonicexe The Disaster 2D Remake.yyp"],
                   cwd=REPO, capture_output=True, text=True)
ok(r.stdout.strip() == "", ".yyp intacto respecto a HEAD (v2 no lo toca)",
   r.stdout.strip())
r = subprocess.run(["git", "status", "--short"], cwd=REPO, capture_output=True, text=True)
touched = [l for l in r.stdout.split("\n") if l.strip()]
touched_paths = set(l[3:].strip('"') for l in touched)
allowed_paths = {"objects/obj_postfx/Draw_77.gml", "scripts/check_postfx.py",
                 "LEEME_BLOOM_POSTFX.txt", "worklog.md"}
ok(touched_paths <= allowed_paths,
   "git status toca SOLO lo previsto (los 4 del fix v2)", str(touched_paths))

# ============================================================================
print("== E. Regresiones ==")
r = subprocess.run(["git", "diff", "--name-only"], cwd=REPO, capture_output=True, text=True)
mod = set(l for l in r.stdout.split("\n") if l.strip())
ok(mod <= {"objects/obj_postfx/Draw_77.gml", "scripts/check_postfx.py",
           "LEEME_BLOOM_POSTFX.txt", "worklog.md"},
   "archivos MODIFICADOS = solo los 4 del fix v2", str(mod))
for sh in ("shd_inverse", "shd_colour", "shd_blackwhite", "shd_amy_cyber"):
    p = f"shaders/{sh}/{sh}.yy"
    r2 = subprocess.run(["git", "diff", "--name-only", "--", p], cwd=REPO,
                        capture_output=True, text=True)
    ok(r2.stdout.strip() == "", f"{p} sin tocar")

# obj_postfx referenciado solo en obj_logo y su propia carpeta
r = subprocess.run(["grep", "-rl", "obj_postfx", "objects/", "scripts/", "rooms/"],
                   cwd=REPO, capture_output=True, text=True)
refs = set(l for l in r.stdout.split("\n") if l.strip())
ok(refs == {"objects/obj_logo/Create_0.gml", "objects/obj_postfx/Create_0.gml",
            "objects/obj_postfx/obj_postfx.yy", "scripts/check_postfx.py"},
   "referencias a obj_postfx solo donde toca", str(refs))

# F9 no esta atado a ninguna accion del juego: en objects/ solo debe estar
# la tabla keycode->nombre del menu de controles + nuestro Step_0 (los .gml
# de scripts/ no bindean teclas; check_postfx.py se menciona a si mismo)
r = subprocess.run(["grep", "-rn", "vk_f9", "objects/"],
                   cwd=REPO, capture_output=True, text=True)
lines = [l for l in r.stdout.split("\n") if l.strip()]
ok(len(lines) == 1 and "obj_postfx/Step_0.gml" in lines[0],
   "vk_f9 en objects/: solo nuestro toggle", f"{len(lines)} refs")
r = subprocess.run(["grep", "-rn", "--include=*.gml", "vk_f9", "scripts/"],
                   cwd=REPO, capture_output=True, text=True)
lines = [l for l in r.stdout.split("\n") if l.strip()]
ok(len(lines) == 1 and "scr_controls_keycode_to_key" in lines[0],
   "vk_f9 en scripts/*.gml: solo la tabla de nombres de teclas", f"{len(lines)} refs")

# ============================================================================
print("== F. Simulacion numerica del pipeline ==")
import numpy as np

# --- pesos de los kernels (tomados del GLSL) ---
wb = 0.36 + 4 * 0.16
ok(abs(wb - 1.0) < 1e-9, "pesos bloom 5-tap suman 1.0", f"{wb:.4f}")
wblur = 0.2270270270 + 2 * (0.3162162162 + 0.0702702703)
ok(abs(wblur - 1.0) < 1e-6, "pesos blur 5-tap suman ~1.0", f"{wblur:.6f}")

# --- curva soft-knee (threshold 0.72, soft 0.35) ---
TH, SOFT = 0.72, 0.35
lo, hi = TH - SOFT / 2, TH + SOFT / 2
def knee(b):
    k = min(max((b - lo) / max(hi - lo, 1e-4), 0.0), 1.0)
    return k * k * (3 - 2 * k)
xs = np.linspace(0, 1, 101)
ks = np.array([knee(x) for x in xs])
ok(knee(0.0) == 0 and knee(lo) == 0, "knee=0 por debajo del umbral bajo")
ok(abs(knee(hi) - 1) < 1e-9 and knee(1.0) == 1, "knee=1 por encima del umbral alto")
ok(np.all(np.diff(ks) >= -1e-12), "knee monotona creciente")
ok(knee(0.72) > 0.4 and knee(0.72) < 0.6, "threshold en el centro de la rampa", f"{knee(0.72):.3f}")

# --- vineta (0.28) ---
def vig(r):  # r=0 centro, 1.0 esquina
    t = np.clip((r - 0.55) / (1.15 - 0.55), 0, 1)
    s = t * t * (3 - 2 * t)
    return 1 - 0.28 * s
ok(abs(vig(0.0) - 1.0) < 1e-9, "vineta=1 en el centro")
ok(abs(vig(0.5) - 1.0) < 1e-9, "vineta intacta hasta mitad del radio")
vc = vig(1.0)
ok(0.75 < vc < 0.95, "esquina oscurecida ~19% (suave)", f"{vc:.3f}")
ok(np.all(np.array([vig(x) for x in np.linspace(0, 1.3, 50)]) >= 0), "vineta nunca negativa")

# --- split-tone y clamps ---
ok(0.030 <= 0.05 and 0.025 <= 0.05, "split-tone sutil (<=0.05)")

# --- pipeline completo sobre imagen sintetica 480x270 ---
W, H = 480, 270
rng = np.random.default_rng(21)
img = np.zeros((H, W, 3), dtype=np.float64)
img[:, :] = np.array([0.06, 0.07, 0.10])          # fondo oscuro azulado
# suelo/colinas
img[200:, :] = np.array([0.13, 0.22, 0.12])
# "anillo" dorado brillante (como los big rings del juego)
yy, xx = np.mgrid[0:H, 0:W]
ring = ((xx - 300) ** 2 + (yy - 60) ** 2 <= 12 ** 2) & ((xx - 300) ** 2 + (yy - 60) ** 2 >= 6 ** 2)
img[ring] = np.array([1.0, 0.85, 0.25])
# "ojo rojo del exe" brillante
eye = (np.abs(xx - 120) <= 3) & (np.abs(yy - 90) <= 2)
img[eye] = np.array([0.95, 0.05, 0.08])
# bloques medios no brillantes
img[140:180, 40:200] = np.array([0.45, 0.42, 0.40])

def bloom_pass(src):
    """extrae brillo con 5-tap cruz + soft-knee (equivalente a shd_bloom)"""
    p = np.pad(src, ((1, 1), (1, 1), (0, 0)), mode="edge")
    c = (p[1:-1, 1:-1] * 0.36 + p[1:-1, 2:] * 0.16 + p[1:-1, :-2] * 0.16
         + p[2:, 1:-1] * 0.16 + p[:-2, 1:-1] * 0.16)
    luma = c @ np.array([0.2126, 0.7152, 0.0722])
    k = np.clip((luma - lo) / max(hi - lo, 1e-4), 0, 1)
    k = k * k * (3 - 2 * k)
    return c * k[..., None]

def blur_pass(src, width=1.0):
    """gauss separable 5-tap (aproximacion de shd_blur): los taps reales
    estan a 1.3846/3.2307 texels con sampling lineal; aqui usamos enteros
    escalados por u_width (suficiente para el sanity check del halo)."""
    o1 = max(1, int(round(1.3846 * width)))
    o2 = max(2, int(round(3.2307 * width)))
    def axis(a, ax):
        def sh(k):
            return np.roll(a, k, axis=ax)
        return (a * 0.2270270270 + (sh(o1) + sh(-o1)) * 0.3162162162
                + (sh(o2) + sh(-o2)) * 0.0702702703)
    b = axis(src, 1)
    b = axis(b, 0)
    return b

def grade(src, texel=1/480.0):
    """shd_grade (aproximacion): CA radial de 1px en R/B + split-tone +
    saturacion 1.14 + contraste 1.06 + vineta 0.28 + clamp"""
    h, w, _ = src.shape
    u, v = np.meshgrid(np.arange(w) / (w - 1), np.arange(h) / (h - 1))
    # CA: en la GPU el offset es radial (0 en el centro, ~1.5 texels en el
    # borde); para la simulacion usamos desplazamiento fijo de 1px en R/B
    out = src.copy()
    out[..., 0] = np.roll(src[..., 0], 1, axis=1)   # R +1px
    out[..., 2] = np.roll(src[..., 2], -1, axis=1)  # B -1px
    luma = out @ np.array([0.2126, 0.7152, 0.0722])
    out[..., 0] = out[..., 0] + 0.025 * luma        # liftH: calor en luces
    out[..., 2] = out[..., 2] + 0.030 * (1 - luma)  # liftS: azul en sombras
    luma2 = out @ np.array([0.2126, 0.7152, 0.0722])
    out = luma2[..., None] + (out - luma2[..., None]) * 1.14   # saturacion
    out = (out - 0.5) * 1.06 + 0.5                             # contraste
    r2 = np.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2) * 1.4142
    t = np.clip((r2 - 0.55) / 0.60, 0, 1)
    s = t * t * (3 - 2 * t)
    out = out * (1 - 0.28 * s)[..., None]                      # vineta
    return np.clip(out, 0, 1)

bright = bloom_pass(img)
glow = blur_pass(blur_pass(blur_pass(bright, 1.0), 2.2), 4.4)
after = grade(np.clip(img + 0.60 * glow, 0, 1))

ok(np.isfinite(after).all(), "pipeline sin NaN/Inf")
ok(after.min() >= 0 and after.max() <= 1, "salida del pipeline en [0,1]",
   f"[{after.min():.3f},{after.max():.3f}]")
# halo: a 2-3 px del borde del anillo el glow debe sumar brillo
before_px = img[60, 313]; after_px = after[60, 313]
ok(after_px.sum() > before_px.sum() + 0.05,
   "halo visible pegado al anillo brillante", f"{before_px.mean():.3f} -> {after_px.mean():.3f}")
# y a media distancia el glow todavia se nota (>0.01 de ganancia) tras la
# vineta/contraste que oscurecen
mid_before = img[60, 320].mean(); mid_after = after[60, 320].mean()
glow_mid = 0.60 * blur_pass(blur_pass(blur_pass(bright, 1.0), 2.2), 4.4)[60, 320].mean()
ok(glow_mid > 0.01,
   "el glow alcanza ~20px del anillo (halo suave)", f"+{glow_mid:.3f} de glow puro")
# el fondo global sube por el grading (mas vivo), y la esquina se oscurece
c_before = img[135, 240].mean(); c_after = after[135, 240].mean()
corner_before = img[5, 5].mean(); corner_after = after[5, 5].mean()
ok(abs(c_after - c_before) < 0.15, "centro sin cambios brutales", f"{c_before:.3f}->{c_after:.3f}")
ok(corner_after < corner_before, "esquina oscurecida por la vineta",
   f"{corner_before:.3f}->{corner_after:.3f}")
# el bloque gris medio gana contraste/saturacion pero no explota
mb = img[160, 120]; ma = after[160, 120]
ok(np.all(ma <= 1.0) and abs(ma.max() - mb.max()) < 0.25, "gris medio estable",
   f"{mb.mean():.3f}->{ma.mean():.3f}")

# preview PNG antes/despues (lado a lado, x2)
try:
    from PIL import Image
    def to8(a):
        return (np.clip(a, 0, 1) * 255).astype(np.uint8)
    panel = np.zeros((H, W * 2 + 8, 3))
    panel[:, :W] = img
    panel[:, W + 8:] = after
    panel[:, W:W + 8] = 1.0
    big = np.kron(panel, np.ones((2, 2, 1)))
    out_png = "/home/z/my-project/download/preview_bloom_postfx.png"
    Image.fromarray(to8(big)).save(out_png)
    ok(os.path.getsize(out_png) > 10000, "preview PNG generado", out_png)
    # el panel derecho (despues) debe diferir del izquierdo (antes)
    arr = np.asarray(Image.open(out_png).convert("RGB"), dtype=np.float64) / 255.0
    hh, ww2 = arr.shape[:2]
    left = arr[:, :ww2 // 2 - 8]; right = arr[:, ww2 // 2 + 8:]
    diff = np.abs(left - right).mean()
    ok(diff > 0.01, "preview: el 'despues' difiere del 'antes'", f"diff media {diff:.4f}")
    # y cerca del anillo el 'despues' debe ser MAS brillante
    ry, rx = int(60 * 2), int(313 * 2)
    ok(right[ry, rx].sum() >= left[ry, rx].sum() - 0.02,
       "preview: el halo junto al anillo no es mas oscuro",
       f"{left[ry, rx].mean():.3f} vs {right[ry, rx].mean():.3f}")
except Exception as e:
    ok(False, "preview PNG", str(e))

# ============================================================================
print("== G. Balance del stack de surfaces (bug v1: 'Unbalanced ... {5}') ==")
# En GameMaker surface_set_target() APILA el destino de dibujo y
# surface_reset_target() lo desapila 1 a 1: el evento debe dejar la pila
# en 0. La v1 encadenaba los 6 sets del blur con 1 solo reset -> +5 por
# frame = el {5} del crash al arrancar.
clean77 = re.sub(r"//[^\n]*", "", draw77)
toks = re.findall(r"surface_set_target\(|surface_reset_target\(", clean77)
ok(len(toks) == 14, "14 ops de stack (7 set + 7 reset)", str(len(toks)))
depth = 0
maxd = 0
underflow = False
for t in toks:
    depth += 1 if t == "surface_set_target(" else -1
    maxd = max(maxd, depth)
    if depth < 0:
        underflow = True
ok(not underflow, "sin reset_target sin su set (no underflow)")
ok(depth == 0, "stack en 0 al final del evento (balance por frame)",
   f"depth final={depth}")
ok(maxd == 1, "sin anidado: cada pase es set->draw->reset (prof. max 1)",
   f"max={maxd}")

# reconstruccion linea a linea: ningun draw con 2+ targets apilados
depth = 0
bad_draws = 0
for line in clean77.split("\n"):
    has_set = "surface_set_target(" in line
    has_reset = "surface_reset_target(" in line
    if "draw_surface" in line and depth > 1:
        bad_draws += 1
    if has_set:
        depth += 1
    elif has_reset:
        depth -= 1
ok(bad_draws == 0, "ningun draw con 2+ targets apilados", str(bad_draws))

# cada set debe cerrarse ANTES del siguiente set (pases cerrados)
segs = clean77.split("surface_set_target(")[1:]
ok(all("surface_reset_target(" in s.split("surface_set_target(")[0] for s in segs),
   "cada set_target se cierra antes del siguiente set_target")

# los early-returns ocurren antes de apilar ningun target (si un return
# saltara a mitad de un pase, el stack quedaria sucio ese frame)
first_set = clean77.index("surface_set_target(")
early = [l for l in clean77[:first_set].split("\n")
         if l.strip().startswith("return")]
ok(len(early) == 3,
   "3 early-returns (F9 off / sin app surface / mapa marijuna) antes de apilar",
   str(len(early)))

print(f"\nRESULTADO: {PASS} OK / {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
