#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera v94_pairs.py con los 2 pares EXACTOS (viejo, nuevo) de los edits de
v94 en Draw_64 (caso KRIS completo con su comentario de cabecera, y caso
AMY_CANON completo), extraidos de verdad de HEAD y del arbol actual. Los
anclajes son unicos; el segmento viejo sale de `git show HEAD`, el nuevo
del archivo entregado."""
import subprocess, os, re, sys

REPO = os.path.dirname(os.path.abspath(__file__))
PATH = "objects/obj_playerui/Draw_64.gml"
head = subprocess.run(["git", "-C", REPO, "show", f"HEAD:{PATH}"], capture_output=True, text=True).stdout
cur = open(os.path.join(REPO, PATH), encoding="utf-8").read()

def segment(text, a_start, a_end, what):
    i = text.find(a_start)
    assert i >= 0, f"{what}: ancla inicial no encontrada"
    assert text.find(a_start, i + 1) < 0, f"{what}: ancla inicial NO unica"
    j = text.find(a_end, i)
    assert j > i, f"{what}: ancla final no encontrada"
    assert text.find(a_end, j + 1) < 0 or what == "AMY", f"{what}: ancla final NO unica"
    return text[i:j]

A_KRIS_S = "                // v5/v2 (KRIS): DOBLE SALTO (Z aire) + ESPADA (X) + ESCUDO"
A_KRIS_E = "                case CHARACTER_EGGMAN:"
A_AC_S = "                case CHARACTER_AMY_CANON:"
A_AC_E = "                case CHARACTER_FLEETWAY_AMY:"

old_kris = segment(head, A_KRIS_S, A_KRIS_E, "KRIS-old")
new_kris = segment(cur, A_KRIS_S, A_KRIS_E, "KRIS-new")
old_ac = segment(head, A_AC_S, A_AC_E, "AC-old")
new_ac = segment(cur, A_AC_S, A_AC_E, "AC-new")

assert head.count(A_AC_S) == 1 and cur.count(A_AC_S) == 1

def lit(s):
    return "'''".join(("")) + repr(s)  # placeholder, replaced below

# emitir con repr() seguro para saltos de linea exactos
out = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""v94_pairs.py — pares (viejo, nuevo) EXACTOS de los 2 edits de v94 en
obj_playerui/Draw_64.gml (caso KRIS con su comentario de cabecera y caso
AMY_CANON completo), extraidos programaticamente de HEAD y del archivo
entregado. check_v94_pass2.py los aplica sobre
HEAD + pares v93 y exige igualdad BYTE A BYTE."""

PAIRS_V94 = {{
{PATH!r}: [
({old_kris!r},
{new_kris!r}),
({old_ac!r},
{new_ac!r}),
],
}}
'''
open(os.path.join(REPO, "v94_pairs.py"), "w", encoding="utf-8").write(out)
print("v94_pairs.py generado:")
print(f"  KRIS: viejo {len(old_kris)} bytes -> nuevo {len(new_kris)} bytes")
print(f"  AMY:  viejo {len(old_ac)} bytes -> nuevo {len(new_ac)} bytes")
# prueba inmediata de que los pares reconstruyen el archivo con v93
sys.path.insert(0, REPO)
import v93_pairs, importlib
import v94_pairs as v94p
rec = head
for old, new in v93_pairs.PAIRS[PATH]:
    assert rec.count(old) == 1, f"par v93 no unico en HEAD: {old[:60]!r}"
    rec = rec.replace(old, new)
for old, new in v94p.PAIRS_V94[PATH]:
    assert rec.count(old) == 1, f"par v94 no unico: {old[:60]!r}"
    rec = rec.replace(old, new)
print("RECONSTRUCCION HEAD+v93+v94 == archivo entregado:", "SI (byte a byte)" if rec == cur else "NO — DIFIERE")
if rec != cur:
    for k, (a, b) in enumerate(zip(rec.split("\n"), cur.split("\n"))):
        if a != b:
            print(f"  primera diferencia en linea {k+1}:\n    rec={a!r}\n    cur={b!r}"); break
