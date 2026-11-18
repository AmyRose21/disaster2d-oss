#!/usr/bin/env python3
# ============================================================================
# check_barras_v10.py — validador del parche "BARRAS IGUAL A LA IMAGEN" (v10)
# TD2DR - Sonicexe The Disaster 2D Remake
#
# Comprueba, SIN ejecutar GameMaker:
#   1. Llaves/parentesis balanceados en los 3 archivos tocados.
#   2. hudAllyBar: firma v10 (tx, ty, hp) y las 4 llamadas con 3 argumentos.
#   3. Geometria exacta de la columna (Draw_64 de obj_level): filas de 26,
#      fila propia 210-236, retratos en x=2, sin restos de la tira horizontal.
#   4. Barra grande v10 (obj_playerui): caja 26x26 en 242-268, barra
#      30-180/248-262, "+NN" con drawBigHpNum, nega reubicada (30,237).
#   5. Iconos: _ico=216, anclaje +370 en drawKeyIcon y los 4 dibujos directos
#      del racimo (332/336/337/517 viejas) desplazados.
#   6. ping/fps/perf en x=268 y badconnection en x=104 (esquina libre).
#   7. Sin choques de nombres de variables nuevas en cada archivo.
# ============================================================================
import re, sys

BASE = "/home/z/my-project/repo/"
FILES = [
    "objects/obj_level/Create_0.gml",
    "objects/obj_level/Draw_64.gml",
    "objects/obj_playerui/Draw_64.gml",
]

fails = []
oks = 0

def check(name, cond):
    global oks
    if cond:
        oks += 1
    else:
        fails.append(name)
        print(f"  [FALLO] {name}")

def read(p):
    with open(BASE + p, encoding="utf-8") as f:
        return f.read()

def strip_comments(code):
    out, i, n = [], 0, len(code)
    in_str = None
    while i < n:
        c = code[i]
        if in_str:
            out.append(c)
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in "\"'":
            in_str = c
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and code[i+1] == "/":
            while i < n and code[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and code[i+1] == "*":
            i += 2
            while i + 1 < n and not (code[i] == "*" and code[i+1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)

# ---------------------------------------------------------------- 1. balance
print("== 1. llaves/parentesis balanceados ==")
for p in FILES:
    code = strip_comments(read(p))
    for op, cl, nm in [("{", "}", "llaves"), ("(", ")", "parentesis"), ("[", "]", "corchetes")]:
        check(f"{p}: {nm} ({code.count(op)}/{code.count(cl)})", code.count(op) == code.count(cl))

# ------------------------------------------------------- 2. hudAllyBar v10
print("== 2. hudAllyBar firma y llamadas ==")
crt = read("objects/obj_level/Create_0.gml")
code = strip_comments(crt)
check("firma v10 (tx, ty, hp)", "hudAllyBar = function(tx, ty, hp)" in code)
check("funda granate 48x8 (tx+28..tx+76)", "draw_rectangle(tx + 28, _cy - 4, tx + 76, _cy + 4, false)" in code)
check("relleno rojo 6 (0.46 px/HP)", "_hp * 0.46" in code)
check("+NN dentro de la barra", '"+" + string(floor(_hp))' in code)
check("sin paleta v9 (c_lime fuera de hudAllyBar)", "c_lime" not in crt[crt.find("hudAllyBar = function"):])

drw = read("objects/obj_level/Draw_64.gml")
code_d = strip_comments(drw)
calls = re.findall(r"hudAllyBar\(([^)]*)\)", code_d)
check("4 llamadas", len(calls) == 4)
check("todas con 3 argumentos", all(c.count(",") == 2 for c in calls))
check("llamadas ancladas a la columna (_colX)", all("_colX" in c for c in calls))
check("fila propia: hudAllyBar(_colX, _selfBot - 26", "_selfBot - 26" in code_d)
check("aliados: hudAllyBar(_colX, _rowBot - 26", "_rowBot - 26" in code_d)

# ------------------------------------------------- 3. geometria de la columna
print("== 3. columna del equipo (obj_level/Draw_64) ==")
check("fila propia _selfBot = 236", "_selfBot = 236" in code_d)
check("columna x fija _colX = 2", "_colX = 2" in code_d)
check("paso 26 con compresion", "(_nRows <= 8) ? 26 : floor(206 / _nRows)" in code_d)
check("fila del aliado: _rowBot = 2 + _rowPitch * i + 26", "_rowBot = 2 + _rowPitch * i + 26" in code_d)
check("sin pos horizontal (var pos = 480/2", "var pos = 480/2" not in code_d)
check("sin pos + i * 28", "pos + i * 28" not in code_d)
check("sin pos += 28", "pos += 28" not in code_d)
check("sin anclas 268 de la tira vieja", re.search(r", 268\)", code_d) is None)
check("numeros de tile en fila: _selfBot - 4", "_selfBot - 4" in code_d)
check("numeros de aliado en fila: _rowBot - 4", "_rowBot - 4" in code_d)

# --------------------------------------------------- 4. barra grande v10
print("== 4. barra grande v10 (obj_playerui/Draw_64) ==")
pui = read("objects/obj_playerui/Draw_64.gml")
code_p = strip_comments(pui)
check("bloque v10 presente", 'BARRA DE VIDA "IGUAL A LA IMAGEN"' in pui)
check("caja blanca 26x26 (2..28 x 242..268)", "draw_rectangle(2, _hbY, 28, _hbY + 26, false)" in code_p and "_hbY = 242" in code_p)
check("barra negra 30-180 x 248-262", "draw_rectangle(30, 248, 180, 262, false)" in code_p)
check("relleno 148 px", "ceil(148 * _hpPct)" in code_p)
check("4 tramos (37 * _t)", "31 + 37 * _t" in code_p)
check("+NN grande via drawBigHpNum", "drawBigHpNum(186, 249" in code_p)
check("drawBigHpNum definido", "drawBigHpNum = function" in code_p)
check("glifos 2x con sombra", code_p.count("spr_letter1, _ind") == 2 and "make_color_rgb(60, 0, 0)" in code_p)
check("nega reubicada (30, 237)", "_negaX = 30" in code_p and "_negaY = 237" in code_p)
check("nega ancho 150 como la barra", "_negaX + 150 * _negaPct" in code_p)
check("v8 vieja fuera (222 ya no)", "_hbY = 222" not in code_p)
check("scr_text_spr viejo del +NN fuera", 'scr_text_spr(128, _hbY + 5' not in code_p)

# ------------------------------------------------------- 5. iconos arriba-derecha
print("== 5. iconos de habilidad (racimo superior derecho) ==")
check("_ico = 216", "_ico = 216" in code_p)
check("drawKeyIcon ancla +370", "_xx += 370" in code_p)
check("tailsattack directo +370", "370 + prog * 12," in code_p)
check("tecla KeyB directa +370", "370 + prog * 12 + 27" in code_p)
check("(hold) +370", "370 + prog * 12 + 3" in code_p)
check("pips de flechas +372", "372 + _pi * 7" in code_p and "377 + _pi * 7" in code_p)

# ---------------------------------------------- 6. ping/badconnection libres
print("== 6. ping/fps/perf y badconnection ==")
check("ping en 268", "scr_text_spr(268, 4" in code_d)
check("fps en 268", "scr_text_spr(268, 10" in code_d)
check("perf en 268", "scr_text_spr(268, 16" in code_d)
check("sin ping en 4,4", "scr_text_spr(4, 4" not in code_d)
check("badconnection x=104", "spr_badconnection, floor(current_time/200) % 6, 104, 0" in code_d)

# ------------------------------------------------- 7. colisiones de nombres
print("== 7. colisiones de variables nuevas ==")
for p, names in [
    ("objects/obj_level/Draw_64.gml", ["_colX", "_selfBot", "_nRows", "_rowPitch", "_rowBot"]),
    ("objects/obj_playerui/Draw_64.gml", ["drawBigHpNum"]),
]:
    code = strip_comments(read(p))
    for nm in names:
        decl = len(re.findall(rf"var {nm}\s*=", code))
        check(f"{p}: '{nm}' declarado 1 vez (hay {decl})", decl <= 1)

# ------------------------------------------------------------------------------
print()
print(f"RESULTADO: {oks}/{oks + len(fails)} OK")
if fails:
    print("FALLOS:")
    for f in fails:
        print("  -", f)
    sys.exit(1)
print("TODO OK — parche v10 consistente.")
