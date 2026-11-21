#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v54_2.py — validador independiente de la ronda v54.2.
Uso: python check_v54_2.py   (desde la raiz del proyecto del juego)

Verifica:
  A) REPARACION del juego (crash "spr_char_info_rouge not set"):
     A1 las 2 lineas del obj_lobby/Draw_0.gml usan sprInd 0-based (14/15)
        y ya no comparan contra macros 1-based;
     A2 los sprites spr_char_info_kris/rouge ESTAN registrados en el .yyp;
     A3 el .yyp parsea como JSON y no hay duplicados;
     A4 resource_order tiene las 2 entradas nuevas;
     A5 los .yy de ambos sprites parsean y sus PNG existen.
  B) EDITOR (Suite_TD2D.html) — fixes del writer:
     B1 pjYypName fallback cubre fs-mode (rootHandle);
     B2 el writer construye 'sprInd == N' 0-based para supervivientes;
     B3 las lineas escritas llevan el comentario FUERA del parentesis;
     B4 registro .yyp con relectura-verificacion + resource_order;
     B5 el trio absurdo 'ent.uid =' no existe (uid 100+ re-deducido);
     B6 la regex de undo admite condicion con digito;
     B7 aviso de GameMaker abierto antes de crear placas nuevas;
     B8 el parser del mapa tolera comentario tras la condicion;
     B9 sprite propio existente GANA al redirect de tira en el mapa.
"""
import io, json, re, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = HERE if not os.path.basename(HERE).startswith('scripts') else os.path.dirname(HERE)
ROOT = os.path.abspath(ROOT)

ok = n = 0
def C(cond, label):
    global ok, n
    n += 1
    if cond:
        ok += 1; print('OK  :', label)
    else:
        print('FAIL:', label)

def slurp(p):
    try:
        return io.open(os.path.join(ROOT, p), encoding='utf-8', errors='replace').read()
    except Exception:
        return None

def lenient(txt):
    return json.loads(re.sub(r',(\s*[}\]])', r'\1', txt))

# ---------- A) juego ----------
gml = slurp('objects/obj_lobby/Draw_0.gml')
C(gml is not None, 'A0 obj_lobby/Draw_0.gml legible')
if gml:
    C(re.search(r'else if \(sprInd == 14\)[^\n]*\n\s*draw_sprite\(spr_char_info_rouge', gml) is not None,
      'A1a Rouge: sprInd == 14 -> spr_char_info_rouge (0-based)')
    C(re.search(r'else if \(sprInd == 15\)[^\n]*\n\s*draw_sprite\(spr_char_info_kris', gml) is not None,
      'A1b Kris: sprInd == 15 -> spr_char_info_kris (0-based)')
    C(not re.search(r'sprInd == CHARACTER_ROUGE\)\s*\n\s*draw_sprite\(spr_char_info_rouge', gml),
      'A1c la macro 1-based de Rouge ya no esta')
    C(not re.search(r'sprInd == CHARACTER_KRIS\)\s*\n\s*draw_sprite\(spr_char_info_kris', gml),
      'A1d la macro 1-based de Kris ya no esta')
    C(gml.count('{') == gml.count('}'), 'A1e llaves balanceadas')
    C(gml.count('(') == gml.count(')'), 'A1f parentesis balanceados')

yyp = None
for f in os.listdir(ROOT):
    if f.endswith('.yyp') and not f.endswith('.yyp.bak'):
        yyp = slurp(f); yypName = f; break
C(yyp is not None, 'A2a .yyp encontrado: ' + (yypName if yyp else '?'))
if yyp:
    d = lenient(yyp)
    names = [r['id']['name'] for r in d['resources']]
    C('spr_char_info_kris' in names, 'A2b spr_char_info_kris registrado')
    C('spr_char_info_rouge' in names, 'A2c spr_char_info_rouge registrado')
    C(len(names) == len(set(names)), 'A2d sin nombres duplicados en resources')
    paths = [r['id']['path'] for r in d['resources'] if r['id']['name'] in ('spr_char_info_kris', 'spr_char_info_rouge')]
    C(all(os.path.exists(os.path.join(ROOT, p)) for p in paths), 'A2e los .yy apuntados existen en disco')

ro = None
for f in os.listdir(ROOT):
    if f.endswith('.resource_order'):
        ro = slurp(f); roName = f; break
C(ro is not None, 'A3a resource_order encontrado: ' + (roName if ro else '?'))
if ro:
    dro = lenient(ro)
    rnames = [x['name'] for x in dro['ResourceOrderSettings']]
    C('spr_char_info_kris' in rnames and 'spr_char_info_rouge' in rnames, 'A3b kris+rouge en resource_order')
    C(len(rnames) == len(set(rnames)), 'A3c resource_order sin duplicados')

for s in ('spr_char_info_kris', 'spr_char_info_rouge'):
    yy = slurp('sprites/%s/%s.yy' % (s, s))
    C(yy is not None, 'A5a %s.yy legible' % s)
    if yy:
        dd = lenient(yy)
        C(len(dd['frames']) == 1 and dd['width'] == 478 and dd['height'] == 40,
          'A5b %s: 1 frame 478x40' % s)
        fg = dd['frames'][0]['name']
        C(os.path.exists(os.path.join(ROOT, 'sprites', s, fg + '.png')),
          'A5c %s: PNG del frame existe' % s)
        ly = dd['layers'][0]['name']
        C(os.path.exists(os.path.join(ROOT, 'sprites', s, 'layers', fg, ly + '.png')),
          'A5d %s: PNG del layer existe' % s)

# ---------- B) editor ----------
suite = slurp('Suite_TD2D.html')
C(suite is not None, 'B0 Suite_TD2D.html legible')
if suite:
    C("S.mode === 'fs' && S.rootHandle" in suite and 'for await (const [name, h] of S.rootHandle.entries())' in suite,
      'B1 pjYypName fallback recorre la raiz en fs-mode')
    C('const charsIdx = (!r.isExe && r.idx != null && r.idx > 0) ? (r.idx - 1) : r.idx;' in suite,
      'B2 writer: charsIdx 0-based (macro-1) para supervivientes')
    C("const condNote = (!r.isExe && charsIdx != null)" in suite and "' // ' + (r.macro || e.key)" in suite,
      'B3 comentario FUERA del parentesis (condNote)')
    C('v54.2 FIX: RELEER y VERIFICAR' in suite and 'resource_order' in suite,
      'B4 registro .yyp: relectura-verificacion + resource_order')
    C('ent.uid = -newPlaqueUid' not in suite and 'while (used.has(u)) u++;' in suite,
      'B5 uid: trio absurdo eliminado, uid 100+ re-deducido')
    C('v54.2: la condicion ya no es solo macro' in suite,
      'B6 undo: regex cubre condicion con digito')
    C('Cierra GameMaker antes de continuar' in suite,
      'B7 aviso GameMaker abierto al crear placas')
    C(r'(?:\s*\/\/[^\n]*)?\s*\r?\n\s*([^\n]+);' in suite,
      'B8 parser del mapa tolera comentario tras la condicion')
    C('v54.2b: placa propia EXISTENTE GANA al redirect de tira' in suite,
      'B9 sprite propio gana al redirect de tira (orden del juego)')

print('\\n%d/%d checks OK' % (ok, n))
sys.exit(0 if ok == n else 1)
