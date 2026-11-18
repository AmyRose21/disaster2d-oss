#!/usr/bin/env python3
"""check_allybars_v1.py — valida las barras de vida de aliados (tira del equipo).

Comprueba sobre los archivos REALES:
  1. obj_level/Create_0.gml: metodo hudAllyBar definido una vez, balance
     de llaves/parens del archivo, geometria exacta (fondo 24x6 filas
     255-260, relleno 22px=100HP ceil(hp*0.22), paleta 25/50 igual que
     la barra propia v8), sin marcadores pendientes.
  2. obj_level/Draw_64.gml: 4 llamadas hudAllyBar (propio, propio nega,
     aliado, aliado nega) en las ramas correctas (NO en demon/escaped),
     balance de llaves/parens, y que las llamadas usan los hp reales
     (global.player.hp / inst.hp).
  3. obj_playerui/Draw_64.gml intacto en su bloque v8 (la barra propia
     no se toco: geometria y gate iguales).
  4. Sin dano de pipeline (secuencias raras, 'mus' perdido, etc.).
"""
import re, sys

OK = 0; FAIL = 0
def chk(cond, msg):
    global OK, FAIL
    print(('OK   ' if cond else 'FAIL ') + msg)
    if cond: OK += 1
    else: FAIL += 1

def balance(text, name):
    # fuera de strings y comentarios
    depth_b = depth_p = 0; i = 0; n = len(text); in_str = False; esc = False; in_lc = in_bc = False
    while i < n:
        c = text[i]
        if in_lc:
            if c == '\n': in_lc = False
            i += 1; continue
        if in_bc:
            if c == '*' and i+1 < n and text[i+1] == '/': in_bc = False; i += 2; continue
            i += 1; continue
        if in_str:
            if esc: esc = False
            elif c == '\\': esc = True
            elif c == '"': in_str = False
            i += 1; continue
        if c == '/' and i+1 < n and text[i+1] == '/': in_lc = True; i += 2; continue
        if c == '/' and i+1 < n and text[i+1] == '*': in_bc = True; i += 2; continue
        if c == '"': in_str = True; i += 1; continue
        if c == "'":  # literal char GML
            i += 1
            while i < n and text[i] != "'": i += 1
            i += 1; continue
        if c == '{': depth_b += 1
        elif c == '}': depth_b -= 1
        elif c == '(': depth_p += 1
        elif c == ')': depth_p -= 1
        if depth_b < 0 or depth_p < 0: break
        i += 1
    chk(depth_b == 0 and depth_p == 0, f'{name}: llaves/parens balanceados (b={depth_b}, p={depth_p})')

# ---------- 1. Create_0.gml ----------
c = open('objects/obj_level/Create_0.gml', encoding='utf-8').read()
chk(c.count('hudAllyBar = function') == 1, 'Create_0: hudAllyBar definido exactamente 1 vez')
balance(c, 'Create_0')
chk('draw_rectangle(tx + 1, 255, tx + 24, 260, false)' in c, 'Create_0: fondo negro 24x6 filas 255-260')
chk('draw_rectangle(tx + 2, 256, tx + 1 + ceil(_hp * 0.22), 259, false)' in c, 'Create_0: relleno 22px = 100 HP (ceil 0.22/hp)')
chk('var _col = c_lime;' in c and '_col = c_red;' in c and '_col = c_yellow;' in c, 'Create_0: paleta por tramos lime/red/yellow')
chk(c.count('draw_set_color(c_white);') >= 1 and c.rstrip().endswith('};'), 'Create_0: metodo cierra y restaura color')
chk('clamp(hp, 0, 100)' in c, 'Create_0: hp clampeada 0..100')
chk('if(_hp > 0)' in c, 'Create_0: sin relleno cuando hp <= 0 (muerto = barra vacia)')

# ---------- 2. Draw_64.gml ----------
d = open('objects/obj_level/Draw_64.gml', encoding='utf-8').read()
balance(d, 'Draw_64')
calls = re.findall(r'hudAllyBar\((pos|pos \+ i \* 28), (global\.player\.hp|inst\.hp)\);', d)
chk(len(calls) == 4, f'Draw_64: 4 llamadas hudAllyBar (hay {len(calls)})')
chk(('pos', 'global.player.hp') in calls, 'Draw_64: llamada del retrato propio (pos, global.player.hp)')
chk(('pos', 'inst.hp') not in calls and ('pos + i * 28', 'global.player.hp') not in calls, 'Draw_64: sin llamadas cruzadas mal')
chk(('pos + i * 28', 'inst.hp') in calls, 'Draw_64: llamada de aliado (pos + i*28, inst.hp)')
# las llamadas caen en ramas de vida real, no en demon/escaped
seg_demon = d[d.find('var _hudDem = scr_hud_demon'):d.find('else \n\t\t\t\t\t\t{\n\t\t\t\t\t\t\tvar _ech')]
chk('hudAllyBar' not in d[d.find('scr_hud_demon(_hudChar)'):d.find('pos += 28')], 'Draw_64: rama demon propia SIN barra')
chk('hudAllyBar' not in d[d.find('scr_hud_demon(_pch)'):], 'Draw_64: rama demon del aliado SIN barra')
chk('hudAllyBar' not in d[d.find('scr_lobby_shiny_escape(_ech'):], 'Draw_64: rama escapado SIN barra')
# contexto: llamada aliado tras los numeros (264)
def after(txt, anchor, needle, maxdist=500, label=''):
    a = txt.find(anchor)
    chk(a >= 0, f'Draw_64: ancla encontrada {label or anchor[:30]}')
    if a < 0: return False
    b = txt.find(needle, a)
    return b > a and b - a < maxdist

chk(after(d, 'scr_number_spr(pos + i * 28 + 12, 264, string(inst.shards), #27ff23);', 'hudAllyBar(pos + i * 28, inst.hp);'),
    'Draw_64: barra del aliado dibujada tras los numeros (filas 255-260, numeros en 264+)')
chk(after(d, 'scr_number_spr(pos + 12, 264, string(global.player.shards), #27ff23);', 'hudAllyBar(pos, global.player.hp);'),
    'Draw_64: barra propia tras sus numeros')
# negas: la llamada sigue al draw_sprite(_ngPair/_ngPair2) de la tira nega
chk(after(d, 'draw_sprite(_ngPair[0], _ngPair[1] + _ngFrame, pos, 268);', 'hudAllyBar(pos, global.player.hp);', 400),
    'Draw_64: nega propio con barra de vida real')
chk(after(d, 'draw_sprite(_ngPair2[0], _ngPair2[1] + _ngFrame2, pos + i * 28, 268);', 'hudAllyBar(pos + i * 28, inst.hp);', 400),
    'Draw_64: nega del aliado con barra de vida real')

# ---------- 3. barra propia v8 intacta ----------
p = open('objects/obj_playerui/Draw_64.gml', encoding='utf-8').read()
chk('var _hbY = 222;' in p, 'playerui: barra propia v8 sigue en 222 (intacta)')
chk('draw_rectangle(22, _hbY + 5, 22 + ceil(100 * _hpPct), _hbY + 12, false)' in p, 'playerui: relleno v8 intacto')
chk('scr_text_spr(128, _hbY + 5, "+" + string(floor(max(global.player.hp, 0))), c_white, 1);' in p, 'playerui: +NN v8 intacto')

# ---------- 4. sin dano de pipeline ----------
for name, txt in [('Create_0', c), ('Draw_64', d)]:
    chk('[m' not in txt.replace('/*', ''), f'{name}: sin secuencias [m sueltas')
    chk(re.search(r'\bTODO\b(?!S)', txt) is None, f'{name}: sin marcador TODO')
    for bad in ['XXX', 'NaN', 'PENDING']:
        chk(bad not in txt, f'{name}: sin marcador {bad}')
    chk(re.search(r'(?<!is_)\bundefined\b', txt) is None, f'{name}: sin undefined suelto (is_undefined es legito)')

print(f'\n{OK} OK / {FAIL} FAIL' + (' — TODO VALIDADO' if FAIL == 0 else ' — HAY FALLOS'))
sys.exit(1 if FAIL else 0)
