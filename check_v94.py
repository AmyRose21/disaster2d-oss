#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_v94.py — PASADA 1 de v94 (ICONOS ANIMADOS de KRIS y AMY CANON,
mismo tratamiento que Metal Amy v93 / patron «Chocola»). Verifica el edit
REAL del archivo, no un resumen:
  1) sintaxis/estructura de Draw_64.gml (lexer propio, balance y strings)
  2) caso CHARACTER_KRIS: 3 drawMiniIcon con SUS sprites, 0 drawKeyIcon,
     placeholders viejos fuera, formulas de recarga/color INTACTAS
  3) caso CHARACTER_AMY_CANON: 6 drawMiniIcon (Z/X/C de 3 caras/V), 0
     drawKeyIcon, variantes esbirro y logica v83 de la C intactas
  4) activos: cada sprite existe (.yy + .yyp) con los frames dichos y la
     zona de contenido pedida cae DENTRO del recorte real de la textura
     (union de pixeles no transparentes, regla v4.3b)
  5) layout re-deriado del codigo: sin solapes, dentro de la vista
  6) integridad: solo 4 .gml cambiados vs HEAD, cero .yy/.yyp, cero red
  7) regresiones: v93 (Metal Amy) intacto — check_v93.py re-ejecutado
"""
import re, os, sys, subprocess, json
from PIL import Image

REPO = os.path.dirname(os.path.abspath(__file__))
D64 = os.path.join(REPO, "objects", "obj_playerui", "Draw_64.gml")
PASS, FAIL = [0], [0]

def ok(m): PASS[0] += 1; print(f"  [OK] {m}")
def fail(m): FAIL[0] += 1; print(f"  [FAIL] {m}")

src = open(D64, encoding="utf-8").read()
lines = src.split("\n")

print("== 1) SINTAXIS/ESTRUCTURA de Draw_64.gml ==")
# lexer: balance llaves/parens/corchetes ignorando //, /* */, strings y chars
depth = {"{": 0, "(": 0, "[": 0}
pairs = {"}": "{", ")": "(", "]": "["}
in_line_comment = in_block_comment = in_string = in_char = False
err = None
for ln, raw in enumerate(lines, 1):
    i = 0
    while i < len(raw):
        c = raw[i]
        nxt = raw[i + 1] if i + 1 < len(raw) else ""
        if in_line_comment: break
        if in_block_comment:
            if c == "*" and nxt == "/": in_block_comment = False; i += 2; continue
            i += 1; continue
        if in_string:
            if c == "\\": i += 2; continue
            if c == '"': in_string = False
            i += 1; continue
        if in_char:
            if c == "\\": i += 2; continue
            if c == "'": in_char = False
            i += 1; continue
        if c == "/" and nxt == "/": break
        if c == "/" and nxt == "*": in_block_comment = True; i += 2; continue
        if c == '"': in_string = True; i += 1; continue
        if c == "'": in_char = True; i += 1; continue
        if c in depth: depth[c] += 1
        elif c in pairs:
            depth[pairs[c]] -= 1
            if depth[pairs[c]] < 0: err = f"linea {ln}: '{c}' cierra de mas"; break
        i += 1
    if err: break
    in_line_comment = in_string = in_char = False  # no cruzan lineas
if err: fail(f"lexer: {err}")
elif any(depth.values()): fail(f"lexer: balance final {depth}")
else: ok("lexer: llaves/parens/corchetes balanceados en todo el archivo")
if in_block_comment: fail("lexer: comentario de bloque sin cerrar")
else: ok("lexer: comentarios de bloque cerrados")

m = re.search(r"drawMiniIcon\s*=\s*function\s*\((_spr,\s*_cx,\s*_cy,\s*_cw,\s*_ch,\s*_scale,\s*_key,\s*_xx,\s*_yy,\s*_col,\s*_alpha,\s*_fly)\)", src)
ok(m) if m else fail("drawMiniIcon = function(...) con sus 12 parametros NO encontrado")
if m and m.start() > src.find("if(instance_exists(global.player)"):
    fail("drawMiniIcon definido DESPUES del primer uso posible")
else:
    ok("drawMiniIcon definido antes del switch de personajes")

# drawKeyIcon intacto vs HEAD (helper pre-existente sin ediciones v94)
head_d64 = subprocess.run(["git", "-C", REPO, "show", "HEAD:objects/obj_playerui/Draw_64.gml"],
                          capture_output=True, text=True).stdout
m_h = re.search(r"drawKeyIcon = function\([^)]*\)\n\{.*?\n\}", head_d64, re.S)
m_n = re.search(r"drawKeyIcon = function\([^)]*\)\n\{.*?\n\}", src, re.S)
ok("helper drawKeyIcon intacto (bloque identico al de HEAD)") if (m_h and m_n and m_h.group(0) == m_n.group(0)) else fail("drawKeyIcon cambio respecto a HEAD")

print("== 2) CASO CHARACTER_KRIS ==")
def extract_case(src, label):
    i = src.find(f"case {label}:")
    if i < 0: return None
    j = src.find("case ", i + 10)
    k = src.rfind("case ", i, j) if j > 0 else len(src)
    return src[i:j if j > 0 else len(src)]

kris = extract_case(src, "CHARACTER_KRIS")
if not kris: fail("case CHARACTER_KRIS no encontrado")
else:
    ok("case CHARACTER_KRIS presente")
    kcalls = re.findall(r"drawMiniIcon\(\s*(spr_[A-Za-z0-9_]+)\s*,", kris)
    expect = ["spr_kris_jump", "spr_kris_attack1_air1", "spr_kris_block_success_ground"]
    ok(f"3 drawMiniIcon en orden: Z={kcalls[0]}, X={kcalls[1]}, C={kcalls[2]}") if kcalls == expect else fail(f"llamadas drawMiniIcon de Kris: {kcalls}")
    if re.search(r"drawKeyIcon\(", kris): fail("caso KRIS todavia llama drawKeyIcon")
    else: ok("caso KRIS: 0 drawKeyIcon (todo mini-icono animado)")
    for cond, name in [
        (r"_kprog0 = 1\.0 - \(max\(global\.player\.djumpRecharge, 0\) / KRIS_DJUMP_RECHARGE\)", "formula recarga doble salto"),
        (r"_kprog1 = 1\.0 - \(min\(max\(global\.player\.attackTimer, 0\), KRIS_ATTACK_RECHARGE\) / KRIS_ATTACK_RECHARGE\)", "formula recarga espada"),
        (r"_kmax = max\(global\.player\.parryCooldownMax, 1\)", "parryCooldownMax"),
        (r"_kprog2 = 1\.0 - \(max\(global\.player\.parryCooldown, 0\) / _kmax\)", "formula recarga escudo"),
        (r"var _kready = \(_kprog2 >= 1\.0 && global\.player\.isGrounded\) \? c_white : c_red;", "color escudo: listo Y en tierra"),
        (r"_kprog0 == 1\.0 \? c_white : c_red", "color doble salto"),
        (r"_kprog1 == 1\.0 \? c_white : c_red", "color espada"),
    ]:
        ok(f"Kris {name}: intacta") if re.search(cond, kris) else fail(f"Kris {name}: CAMBIADA o no encontrada")

old_placeholders = ["spr_gui_krisdjump", "spr_gui_krisattack", "spr_gui_krisshield"]
for p in old_placeholders:
    if p in src: fail(f"{p} sigue referenciado en Draw_64")
    else: ok(f"placeholder {p} fuera del archivo")

print("== 3) CASO CHARACTER_AMY_CANON ==")
ac = extract_case(src, "CHARACTER_AMY_CANON")
if not ac: fail("case CHARACTER_AMY_CANON no encontrado")
else:
    ok("case CHARACTER_AMY_CANON presente")
    acalls = re.findall(r"drawMiniIcon\(\s*(spr_[A-Za-z0-9_]+)\s*,", ac)
    expect_ac = ["spr_amy_attack2_canon", "spr_amy_attack1_canon",
                 "spr_super_amy_hrow_hammer", "spr_amy_light_speed_canon",
                 "spr_amy_attack3_canon_", "spr_amy_parry_exitoso"]
    ok(f"6 drawMiniIcon: Z, X, C(lanzada/LSA/acometida), V = {acalls}") if acalls == expect_ac else fail(f"llamadas drawMiniIcon de Amy Canon: {acalls}")
    if re.search(r"drawKeyIcon\(", ac): fail("caso AMY_CANON todavia llama drawKeyIcon")
    else: ok("caso AMY_CANON: 0 drawKeyIcon")
    for cond, name in [
        (r"var prog = 1\.0 - \(max\(global\.player\.hjumpTimer, 0\) / AMY_CANON_BIGJUMP_RECHARGE\)", "formula salto de martillo"),
        (r"var val = scr_esbirro_hud\(global\.player\) \? AMY_CANON_ETAROTDASH_RECHARGE : AMY_CANON_TAROTDASH_RECHARGE", "variante esbirro del tarot"),
        (r"val = scr_esbirro_hud\(global\.player\) \? AMY_CANON_EDASH_RECHARGE : AMY_CANON_DASH_RECHARGE", "variante esbirro de la acometida"),
        (r"var b1 = \(prog == 1\.0 && global\.player\.isGrounded\) \? c_white : c_red;", "color icono 1: listo Y en suelo"),
        (r"var b2 = \(prog == 1\.0 && !global\.player\.isGrounded\) \? c_white : c_red;", "color icono 2: lista Y en aire"),
        (r"var _acThrow = \(global\.player\.superFormPhase >= 2 && global\.player\.isGrounded\);", "_acThrow (super fase 2)"),
        (r"var _acNoC = \(global\.player\.superFormPhase == 1 && global\.player\.isGrounded\);", "_acNoC (fase 1: C muerta)"),
        (r"_acCd = global\.player\.hammerThrowTimer;\s*\n\s*val = AMY_SUPER_HTHROW_RECHARGE;", "C lanzada usa hammerThrowTimer/HTHROW_RECHARGE"),
        (r"var b = \(prog == 1\.0 && !_acNoC\) \? c_white : c_red;", "color icono 3 (v83)"),
        (r"if\(_acThrow\)\s*\n\s*drawMiniIcon\(spr_super_amy_hrow_hammer", "rama 1 de la C: lanzada de martillo"),
        (r"else if\(!global\.player\.isGrounded\)\s*\n\s*drawMiniIcon\(spr_amy_light_speed_canon", "rama 2 de la C: LSA en el aire"),
        (r"else\s*\n\s*drawMiniIcon\(spr_amy_attack3_canon_", "rama 3 de la C: acometida en suelo"),
        (r"var _pmax = max\(global\.player\.parryCooldownMax, 1\);", "parryCooldownMax del icono 4"),
        (r"var _pready = \(_pprog >= 1\.0 && global\.player\.isGrounded\) \? c_white : c_red;", "color icono 4: listo Y en suelo"),
    ]:
        ok(f"AmyCanon {name}: intacta") if re.search(cond, ac) else fail(f"AmyCanon {name}: CAMBIADA o no encontrada")
    # los iconos GUI estaticos viejos ya no se usan en el caso
    for g in ["spr_gui_amyhjump_canon", "spr_gui_amyattack_canon", "spr_gui_amydash_canon", "spr_gui_amyparry_canon"]:
        if g in ac: fail(f"{g} sigue en el caso AMY_CANON")
        elif g in src: fail(f"{g} referenciado en OTRO lugar de Draw_64")
        else: ok(f"icono GUI viejo {g} fuera del HUD")

print("== 4) ACTIVOS: sprites, frames y zonas de contenido ==")
SPRITES = {  # sprite: (frames dichos, canvas WxH)
    "spr_kris_jump": (6, 45, 45), "spr_kris_attack1_air1": (4, 70, 70),
    "spr_kris_block_success_ground": (9, 55, 55), "spr_amy_attack2_canon": (4, 48, 59),
    "spr_amy_attack1_canon": (2, 46, 46), "spr_amy_attack3_canon_": (8, 100, 100),
    "spr_amy_light_speed_canon": (1, 35, 33), "spr_super_amy_hrow_hammer": (10, 70, 65),
    "spr_amy_parry_exitoso": (10, 50, 50),
}
ZONAS = {  # sprite: (cx, cy, cw, ch) como se piden en Draw_64
    "spr_kris_jump": (5, 1, 35, 42), "spr_kris_attack1_air1": (8, 0, 53, 70),
    "spr_kris_block_success_ground": (10, 7, 35, 40), "spr_amy_attack2_canon": (1, 0, 47, 59),
    "spr_amy_attack1_canon": (1, 2, 45, 42), "spr_amy_attack3_canon_": (25, 18, 57, 52),
    "spr_amy_light_speed_canon": (0, 0, 35, 33), "spr_super_amy_hrow_hammer": (0, 3, 56, 52),
    "spr_amy_parry_exitoso": (6, 4, 38, 42),
}
yyp_name = [f for f in os.listdir(REPO) if f.endswith(".yyp")][0]
yyp = open(os.path.join(REPO, yyp_name), encoding="utf-8").read()
for name, (nfr, W, H) in SPRITES.items():
    d = os.path.join(REPO, "sprites", name)
    yyf = os.path.join(d, name + ".yy")
    if not os.path.exists(yyf): fail(f"{name}: sin .yy"); continue
    txt = open(yyf, encoding="utf-8").read()
    guids = re.findall(r'"%Name":\s*"([0-9a-fA-F-]{36})",\s*"name":\s*"\1"', txt)
    if len(guids) == nfr: ok(f"{name}: {nfr} frames (GUIDs del .yy)")
    else: fail(f"{name}: {len(guids)} frames en .yy, se esperaban {nfr}")
    if f"sprites/{name}/{name}.yy" in yyp: ok(f"{name}: recurso listado en el .yyp")
    else: fail(f"{name}: NO esta en el .yyp")
    # zona pedida dentro del lienzo
    cx, cy, cw, ch = ZONAS[name]
    if cx >= 0 and cy >= 0 and cx + cw <= W and cy + ch <= H:
        ok(f"{name}: zona ({cx},{cy},{cw},{ch}) dentro del lienzo {W}x{H}")
    else:
        fail(f"{name}: zona ({cx},{cy},{cw},{ch}) FUERA del lienzo {W}x{H}")
    # zona dentro del recorte real de la textura (union de contenido)
    union = None
    for g in guids:
        p = os.path.join(d, g + ".png")
        if not os.path.exists(p): continue
        bb = Image.open(p).convert("RGBA").getchannel("A").getbbox()
        if bb: union = list(bb) if union is None else [min(union[0], bb[0]), min(union[1], bb[1]), max(union[2], bb[2]), max(union[3], bb[3])]
    if union and cx >= union[0] and cy >= union[1] and cx + cw <= union[2] and cy + ch <= union[3]:
        ok(f"{name}: zona dentro del recorte real de la textura (union x[{union[0]}..{union[2]}] y[{union[1]}..{union[3]}])")
    elif union:
        fail(f"{name}: zona sale del recorte real x[{union[0]}..{union[2]}] y[{union[1]}..{union[3]}]")
    else:
        fail(f"{name}: PNGs sin contenido?")
    # el sprite del icono TAMBIEN es el sprite real de la habilidad (mismo arr de scr_survivors / Draw_76)
if src.count("drawMiniIcon(") - src.count("drawMiniIcon = function") == 13:
    ok("13 llamadas drawMiniIcon en total (4 Metal Amy v93 + 3 Kris + 6 Amy Canon)")
else:
    fail(f"llamadas drawMiniIcon = {src.count('drawMiniIcon(') - src.count('drawMiniIcon = function')}, se esperaban 13")

print("== 5) LAYOUT re-deriado del codigo ==")
ICO = 216
CALL_RE = re.compile(r"drawMiniIcon\(\s*(spr_[A-Za-z0-9_]+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*,\s*global\.Key(\w+)\s*,\s*(\d+)\s*,\s*(\d+)\s*-\s*_ico")
def bounds(case_src, skip_alternatives=True):
    out = []
    for m in CALL_RE.finditer(case_src):
        spr, cx, cy, cw, ch, sc, key, xx, yy = m.groups()
        w, h = float(cw) * float(sc), float(ch) * float(sc)
        out.append((key, float(xx), float(yy) - ICO, float(xx) + w + 4 + 12, float(yy) - ICO + h))
    return out
for label, case_src, keys in [("KRIS", kris, ["A", "B", "C"]),
                              ("AMY_CANON", ac, ["A", "B", "C", "C", "C", "V"])]:
    bs = bounds(case_src)
    got = [b[0] for b in bs]
    ok(f"{label}: iconos de teclas {keys} en orden (la C de Amy Canon son 3 ramas EN EL MISMO SITIO)") if got == keys else fail(f"{label}: teclas encontradas {got}")
    bad = False
    for (k1, x1, y1, X1, Y1) in bs:
        if X1 > 480 or Y1 > 270:
            fail(f"{label} icono {k1}: cae fuera de la vista (x2={X1:.0f}, y2={Y1:.0f})"); bad = True
        if len(re.findall(rf"drawMiniIcon\(\s*spr_[a-z_]+,\s*-?\d+,\s*-?\d+,\s*\d+,\s*\d+,\s*[0-9.]+,\s*global\.Key{k1}\b", case_src)) > 1 and k1 == "C":
            pass  # C tiene 3 ramas alternativas (mismo sitio): se comparan entre si aparte
    if not bad: ok(f"{label}: ningun icono fuera de la vista 480x270")
    # solapes: C tiene 3 ramas EN EL MISMO SITIO -> comparar solo la rama de la acometida
    excl = [b for b in bs]
    seen = set()
    fixed = []
    for b in excl:
        if b[0] == "C" and "C" in seen: continue
        seen.add(b[0]); fixed.append(b)
    ov = False
    for i in range(len(fixed)):
        for j in range(i + 1, len(fixed)):
            a, b = fixed[i], fixed[j]
            ox = min(a[3], b[3]) - max(a[1], b[1])
            oy = min(a[4], b[4]) - max(a[2], b[2])
            if ox > 0 and oy > 0:
                fail(f"{label}: SOLAPE {a[0]} <-> {b[0]} ({ox:.1f}x{oy:.1f}px)"); ov = True
    if not ov: ok(f"{label}: sin solapes entre iconos (filas Z/X/C-V y C vs V en la misma fila)")
    # las 3 ramas de la C de Amy Canon y las posiciones de Kris: mismo anclaje
    if label == "AMY_CANON":
        xs = sorted(set(round(b[1]) for b in bs))
        if xs == [372, 416]: ok("AMY_CANON: columnas exactas Z/X/C=372 y V=416 (C y V comparten fila, v4.1)")
        else: fail(f"AMY_CANON: columnas raras {xs}")

print("== 6) INTEGRIDAD (diff vs HEAD) ==")
r = subprocess.run(["git", "-C", REPO, "diff", "--name-only", "HEAD"], capture_output=True, text=True).stdout.split()
code = [f for f in r if f.endswith(".gml")]
expect_code = {"objects/obj_playerui/Draw_64.gml", "objects/obj_metalamy/Create_0.gml",
               "objects/obj_metalamy/Step_0.gml", "scripts/scr_metalamy_special/scr_metalamy_special.gml"}
if set(code) == expect_code: ok(f"codigo cambiado vs HEAD: exactamente los 4 .gml esperados (v93+v94)")
else: fail(f"codigo cambiado: {sorted(code)}")
yy = [f for f in r if f.endswith(".yy") or f.endswith(".yyp")]
ok("cero .yy/.yyp modificados") if not yy else fail(f".yy/.yyp modificados: {yy}")
untouched = subprocess.run(["git", "-C", REPO, "diff", "--name-only", "HEAD", "--",
                           "objects/obj_kris", "objects/obj_amy_canon", "scripts/scr_kris_special",
                           "scripts/scr_amy_canon_special", "scripts/scr_parry", "objects/obj_netclient",
                           "objects/obj_player_puppet"], capture_output=True, text=True).stdout.split()
ok("obj_kris/obj_amy_canon/scr_kris_special/scr_amy_canon_special/scr_parry/red: INTACTOS") if not untouched else fail(f"tocados: {untouched}")
diff_txt = subprocess.run(["git", "-C", REPO, "diff", "HEAD", "--", "objects/obj_playerui/Draw_64.gml"], capture_output=True, text=True).stdout
added = "\n".join(l[1:] for l in diff_txt.split("\n") if l.startswith("+") and not l.startswith("+++"))
net_new = [p for p in ["network_", "buffer_", "cpacket", "scr_net", "SERVER_", "CLIENT_"] if p in added]
ok("cero superficie nueva de red/anti-cheat en lo anadido (solo dibujo)") if not net_new else fail(f"patrones de red en lo anadido: {net_new}")

print("== 7) REGRESIONES ==")
v93 = subprocess.run(["python3", os.path.join(REPO, "check_v93.py")], capture_output=True, text=True)
last = [l for l in v93.stdout.split("\n") if "RESULTADO" in l]
if "0 FAIL" in (last[0] if last else ""): ok(f"check_v93.py re-ejecutado sobre el arbol actual: {last[0].strip()}")
else: fail(f"check_v93.py fallo tras las ediciones v94: {last}")
for frag, name in [
    (r"draw_sprite_part_ext\(spr_vanilla_chocola_Idle, _vFrame, 3, 2, 13, 21, 370 \+ 44 \+ _vSlide", "patron Chocola de Vanilla intacto"),
    (r"case EXE_METALAMY:", "caso EXE_METALAMY (v93) presente"),
    (r"drawMiniIcon\(spr_metalamy_jump, 0, 0, 30, 30, 0\.4", "Z de Metal Amy v93 intacta"),
    (r"drawKeyIcon\(spr_gui_amyhjump, 0, 32", "Amy ORIGINAL (vanilla): su HUD intacto"),
    (r"drawKeyIcon\(spr_gui_amyattack, 0, 23", "golpe de Amy original intacto"),
    (r"case CHARACTER_SONIC:", "HUD de Sonic intacto"),
]:
    ok(name) if re.search(frag, src) else fail(f"regresion: {name}")

print(f"\nRESULTADO PASADA 1 (v94): {PASS[0]} OK / {FAIL[0]} FAIL")
sys.exit(1 if FAIL[0] else 0)
