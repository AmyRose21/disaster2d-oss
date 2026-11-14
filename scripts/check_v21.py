#!/usr/bin/env python3
# check_v21.py — valida el fix v21 (fuera snd_jina_taunt3 de Jinna).
#
# Cambios esperados (base = proyecto con v20 aplicado):
#   1. objects/obj_jinna/Step_2.gml  : el bloque won ya NO reproduce
#      snd_jina_taunt3 (ni local ni por red); la pose JINNA_WON se
#      conserva. La risa de la victoria es la del jingle (snd_jina_laugh
#      en net_state_game), que NO se toca.
#   2. objects/obj_jinna/Create_0.gml: fuera la variable jinnaWonSnd
#      (huerfana); los taunts libres del v20 intactos.
#   3. scripts/scr_move_basic.gml    : el case EXE_JINNA del switch del
#      KeyEm3 queda MUDO (solo break). Los cases del KeyEm1 (taunt1) y
#      KeyEm2 (taunt2) INTACTOS.
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ok = fail = 0

def check(name, cond, detail=""):
    global ok, fail
    if cond:
        ok += 1
        print(f"  OK  {name}")
    else:
        fail += 1
        print(f"FAIL  {name}  {detail}")

def rd(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return f.read()

def strip_gml(text):
    """Quita comentarios // y /* */ y literales de cadena para balancear."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i+1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i+1] == "*":
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
        elif c == '"':
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
            i += 1
        elif c == "'":
            i += 1
            while i < n and text[i] != "'":
                i += 2 if text[i] == "\\" else 1
            i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)

def strip_comments(text):
    """Quita SOLO comentarios (// y /* */); deja strings y codigo."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i+1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i+1] == "*":
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)

def balanced(text, path):
    s = strip_gml(text)
    checks = [("{", "}"), ("(", ")"), ("[", "]")]
    for a, b in checks:
        if s.count(a) != s.count(b):
            print(f"FAIL  balance {a}{b} en {path}: {s.count(a)} vs {s.count(b)}")
            return False
    return True

print("== 1) Victoria de Jinna (obj_jinna/Step_2.gml) ==")
s2 = rd("objects", "obj_jinna", "Step_2.gml")
s2c = strip_comments(s2)
check("sin snd_jina_taunt3 en el CODIGO (los comentarios del fix no cuentan)",
      "snd_jina_taunt3" not in s2c)
check("sin jinnaWonSnd (bloque retirado)", "jinnaWonSnd" not in s2)
check("pose de victoria intacta (state = JINNA_WON)",
      re.search(r"if\(won\)\s*\{\s*if\(isGrounded\)\s*state = JINNA_WON;\s*\}", s2) is not None,
      "el bloque won debe asignar JINNA_WON")
check("llaves/parens balanceados", balanced(s2, "Step_2.gml"))

print("== 2) Create_0 (limpieza + v20 intacto) ==")
c0 = rd("objects", "obj_jinna", "Create_0.gml")
check("sin jinnaWonSnd (variable retirada)", "jinnaWonSnd" not in c0)
check("v20 intacto: taunts libres (taunt1/taunt2 = true)",
      "taunt1 = true" in c0 and "taunt2 = true" in c0)
check("jinnaGoSnd conservado (linea de arranque)", "jinnaGoSnd = false" in c0)
check("llaves/parens balanceados", balanced(c0, "Create_0.gml"))

print("== 3) Emoticono 3 mudo (scr_move_basic.gml) ==")
mb = rd("scripts", "scr_move_basic", "scr_move_basic.gml")
mbc = strip_comments(mb)
check("sin snd_jina_taunt3 en el CODIGO", "snd_jina_taunt3" not in mbc)
cases = mbc.count("case EXE_JINNA:")
check("3 cases EXE_JINNA (KeyEm1+KeyEm2 con voz; KeyEm3 mudo)",
      cases == 3, f"encontrados {cases}")
# el case del KeyEm3 (el que sigue al de Metal Amy, el ultimo del switch)
# no debe reproducir ni emitir nada entre case y break
m_pos = mbc.rfind("case EXE_METALAMY:")
j_pos = mbc.find("case EXE_JINNA:", m_pos)
b_pos = mbc.find("break;", j_pos)
body = mbc[j_pos:b_pos]
check("el case del KeyEm3 esta MUDO (sin audio_play_sound / net_sound_emit)",
      "audio_play_sound" not in body and "net_sound_emit" not in body)
check("voz del emoticono 1 intacta (snd_jina_taunt1)",
      "audio_play_sound(snd_jina_taunt1" in mb)
check("voz del emoticono 2 intacta (snd_jina_taunt2)",
      "audio_play_sound(snd_jina_taunt2" in mb)
seg = mb[mb.find("KeyEm3"):]
check("case mudo en su sitio (EXE_JINNA: break en el switch del KeyEm3)",
      re.search(r"case EXE_JINNA:\s*break;", seg) is not None)
check("llaves/parens balanceados", balanced(mb, "scr_move_basic.gml"))

print("== 4) Nada mas reproduce snd_jina_taunt3 en todo el proyecto ==")
plays = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in ("_backups_animeditor", ".git")]
    for fn in filenames:
        if not fn.endswith(".gml"):
            continue
        p = os.path.join(dirpath, fn)
        rel = os.path.relpath(p, ROOT)
        if rel.startswith(os.path.join("scripts", "net_sounds")) or \
           rel.startswith(os.path.join("scripts", "scr_menu_more")):
            continue  # registro del asset y lista de volumen: el wav existe, no suena
        t = open(p, encoding="utf-8", errors="replace").read()
        if "audio_play_sound(snd_jina_taunt3" in t or "net_sound_emit(snd_jina_taunt3" in t or \
           "net_sound_emit_at(snd_jina_taunt3" in t:
            plays.append(rel)
check("cero llamadas de reproduccion/emision", not plays, f"encontradas en: {plays}")

print("== 5) La risa de la victoria sigue en su sitio (no se toca) ==")
ng = rd("scripts", "net_state_game", "net_state_game.gml")
check("jingle EXE_WINS/TIME_OVER = snd_jina_laugh (2 sitios)",
      ng.count("_exeChar == EXE_JINNA ? snd_jina_laugh : snd_exe_wins") == 2)
cs = rd("scripts", "net_state_charselect", "net_state_charselect.gml")
check("risa de seleccion intacta", "audio_play_sound(snd_jina_laugh" in cs)
ex = rd("scripts", "scr_exe", "scr_exe.gml")
check("spr_jinna_won sigue cableado (slot 17 del array de Jinna)",
      "spr_jinna_won, //17" in ex)
check("array de sonidos net_sounds intacto (taunt3 sigue registrado = asset no roto)",
      "snd_jina_taunt3" in rd("scripts", "net_sounds", "net_sounds.gml"))

print(f"\nRESULTADO: {ok} OK / {fail} FAIL")
sys.exit(1 if fail else 0)
