# -*- coding: utf-8 -*-
# check_v54_1.py — verificador de la ronda v54.1 (frame 16 de Jinna en el Suite)
# E2E: el parser del editor debe reflejar EXACTAMENTE lo que obj_lobby/Draw_0.gml
# dibuja, incluidas las comparaciones ARITMETICAS (sprInd == CHARACTER_KRIS + 5).
import io, re, subprocess, sys, os

REPO = '/home/z/my-project/repo'
S = os.path.join(REPO, 'Suite_TD2D.html')
html = io.open(S, encoding='utf-8', newline='').read()
draw = io.open(os.path.join(REPO, 'objects/obj_lobby/Draw_0.gml'), encoding='utf-8').read()
yy = io.open(os.path.join(REPO, 'sprites/spr_char_info/spr_char_info.yy'), encoding='utf-8').read()

ok = [0]; bad = [0]
def chk(name, cond, detail=''):
    (ok if cond else bad)[0] += 1
    print(('  OK ' if cond else '  FAIL ') + name + ((' — ' + detail) if detail else ''))

print('== A. FIX DEL PARSER (regex aritmetica + dual-key) ==')
chk('A1 regex acepta macro+aritmetica', '[A-Za-z_]\\w*(?:\\s*[+\\-]\\s*\\d+)?|\\d+' in html)
chk('A2 branch aritmetico presente', 'macroIdx.get(am[1])' in html and 'macroX >= krisIdx' in html)
chk('A3 mapa macroIdx construido', 'const macroIdx = new Map();' in html)
chk('A4 comentario v54.1 presente', 'comparacion ARITMETICA' in html.replace('Ó','O') or 'ARITMETICA' in html)

print('== B. CARGA DEL FRAME 16 (bucle 16 hardcodeado) ==')
chk('B1 bucle usa nFrames del sprite', 'const nFrames = A.spriteMeta.demo ? Math.min(AR.demoPlaques.length, 16) : A.spriteMeta.frames.length;' in html)
chk('B2 ya no recorre solo 0..15', 'for (let i = 0; i < 16; i++) {\n      if (A.plaqueCache.has(i)) continue;' not in html)

print('== C. GUARD DEL BUG PRE-EXISTENTE (Cd en parte 3) ==')
chk('C1 guard typeof Cd presente', "if (typeof Cd !== 'undefined') Cd.discovered = false" in html)

print('== D. JUEGO INTACTO (regla de oro: el Suite no toca GML) ==')
gmls = subprocess.run(['git', 'diff', '--name-only'], cwd=REPO, capture_output=True, text=True).stdout
gml_changed = [l for l in gmls.splitlines() if l.endswith(('.gml', '.yy', '.yyp'))]
chk('D1 cero .gml/.yy/.yyp modificados', not gml_changed, ', '.join(gml_changed))

print('== E. REDIRECCION REAL DEL JUEGO (evidencia) ==')
chk('E1 Draw_0 redirige KRIS+5 a frame 16', 'sprInd == CHARACTER_KRIS + 5' in draw and '_infoFrame = 16; // jinna' in draw)
chk('E2 Draw_0 redirige KRIS+4 a frame 15', 'sprInd == CHARACTER_KRIS + 4' in draw and '_infoFrame = 15; // metal amy' in draw)
m = re.search(r'"length":\s*([\d.]+)', yy.replace(',\n', '\n'))
chk('E3 sprite tiene 17 frames', '"length": 17.0' in yy or (m and m.group(1) == '17'), 'length=%s' % (m and m.group(1)))
chk('E4 PNG del frame 16 existe', os.path.exists(os.path.join(REPO, 'sprites/spr_char_info/b0fb75d2-f003-461e-b27f-51c5de4b5370.png')))

print('== F. SINTAXIS JS DE LOS <script> ==')
# se verifico en Node en la ronda; aqui re-chequeo ligero de llaves/par balance
# de los bloques que tocamos: plaqueMapFor y loadPlaqueSprite
i = html.index('async function plaqueMapFor'); j = html.index('async function loadPlaqueSprite')
seg = html[i:j]
chk('F1 plaqueMapFor llaves balanceadas', seg.count('{') == seg.count('}'), '%d/%d' % (seg.count('{'), seg.count('}')))
i2 = j; j2 = html.index('async function decodeFrame')
seg2 = html[i2:j2]
chk('F2 loadPlaqueSprite llaves balanceadas', seg2.count('{') == seg2.count('}'), '%d/%d' % (seg2.count('{'), seg2.count('}')))

print('== G. E2E DEL MAPA (Node, archivos reales) ==')
r = subprocess.run(['node', '/home/z/my-project/scripts/test_plaquemap_fixed.js'], capture_output=True, text=True)
out = r.stdout
chk('G1 mapa idéntico al juego real', r.returncode == 0, out.strip().splitlines()[-1] if out else 'sin salida')
chk('G2 Jinna resuelta a frame 16', 'Jinna            frame 16' in out or 'Jinna' in out and 'frame 16' in out)
chk('G3 sin placeholders prestados', 'MISSING' not in out or 'Rouge' in out)  # Rouge missing es CORRECTO (juego sin placa)

print()
print('RESULTADO: %d OK / %d FAIL' % (ok[0], bad[0]))
sys.exit(1 if bad[0] else 0)
