#!/usr/bin/env python3
"""check_v62_blindaje_rings.py — valida el fix de anillos v6.x:

1. SINTAXIS: llaves/parens/brackets balanceados en los 2 archivos tocados
   (descontando comentarios // y strings).
2. CONVERSION DE CURA (bug reportado): los 3 caminos de conversion
   (vasijas VV / ring pickup normal / bonus slime RMZ + bring) deben
   restar 10 y CONSERVAR el excedente; ninguno debe vaciar el contador.
3. REGLA DE DANO (pedido): en scr_player_hurt, con 10+ anillos el golpe
   se absorbe (hp NI SE TOCA) y cuesta exactamente 10; con menos de 10
   pierde todos y la vida.
4. SIMULACION: replica el flujo GML y prueba los escenarios del usuario
   y de las pasivas Vanilla/Cream.

Uso: python3 check_v62_blindaje_rings.py   (desde la raiz del repo)
"""
import os, re, sys

REPO = os.path.dirname(os.path.abspath(__file__))
HURT = os.path.join(REPO, 'scripts', 'scr_player_hurt', 'scr_player_hurt.gml')
NETG = os.path.join(REPO, 'scripts', 'net_state_game', 'net_state_game.gml')

passed, failed = 0, 0

def ok(msg):
    global passed; passed += 1
    print(f'  [OK]   {msg}')

def bad(msg):
    global failed; failed += 1
    print(f'  [FAIL] {msg}')

# ---------------------------------------------------------------- 1. sintaxis
def strip_gml(text):
    out = []
    for line in text.split('\n'):
        # quitar strings (simple, suficiente: no hay escapes raros aqui)
        l = re.sub(r'"[^"\n]*"', '""', line)
        # quitar comentario // (no hay // dentro de strings ya que fueron reemplazados)
        i = l.find('//')
        if i >= 0:
            l = l[:i]
        out.append(l)
    return '\n'.join(out)

print('== 1. SINTAXIS (balance de llaves/parens/brackets) ==')
for path in [HURT, NETG]:
    txt = strip_gml(open(path, encoding='utf-8').read())
    rel = os.path.relpath(path, REPO)
    b, p, s = txt.count('{')-txt.count('}'), txt.count('(')-txt.count(')'), txt.count('[')-txt.count(']')
    if b == p == s == 0:
        ok(f'{rel}: llaves {b}, parens {p}, brackets {s}')
    else:
        bad(f'{rel}: DESBALANCE llaves {b}, parens {p}, brackets {s}')

# ------------------------------------------------- 2. conversion de cura (-10)
print('== 2. CONVERSION DE CURA: restar 10 y conservar excedente ==')
net = open(NETG, encoding='utf-8').read()
hurt = open(HURT, encoding='utf-8').read()

sitios = re.findall(
    r'if\(global\.player\.rings >= 10 && global\.player\.hp < 100 && _canHeal\)\s*\{(.*?)\n\s*\}',
    net, re.S)
conversores = 0
for s in sitios:
    if 'global.player.hp = min(100, global.player.hp + 20)' not in s:
        continue
    conversores += 1
    if 'global.player.rings -= 10;' in s:
        ok(f'conversion #{conversores}: resta 10 y conserva excedente')
    else:
        bad(f'conversion #{conversores}: NO resta 10 -> {s[:120]!r}')
if conversores == 3:
    ok(f'total caminos de conversion: {conversores} (VV vase / RING / RMZ slime)')
else:
    bad(f'caminos de conversion inesperados: {conversores} (esperados 3)')

if re.search(r'global\.player\.rings = 0;\s*\n\s*global\.player\.hp = min\(100', net):
    bad('sigue habiendo una conversion que VACIA el contador junto a la cura')
else:
    ok('ninguna conversion vacia el contador')

# ----------------------------------------------------------- 3. regla de dano
print('== 3. REGLA DE DANO en scr_player_hurt ==')
if 'var _ringAbsorb = (damage > 0 && global.player.rings >= 10);' in hurt:
    ok('_ringAbsorb declarado antes del bloque de vida (alcance de funcion)')
else:
    bad('_ringAbsorb no esta declarado donde debe')

# hp -= damage debe estar guardado por if(!_ringAbsorb)
m = re.search(r'if\(!_ringAbsorb\)\s*\{\s*global\.player\.hp -= damage;', hurt)
if m:
    ok('hp -= damage SOLO corre si el golpe NO se absorbe')
else:
    bad('hp -= damage no esta protegido por if(!_ringAbsorb)')

# bloque de perdida de anillos con la rama >= 10 -> -10
m = re.search(
    r'if\(_fortLoss > 0\)\s*\n\s*global\.player\.rings = max\(0, global\.player\.rings - min\(_fortLoss, global\.player\.rings\)\);\s*\n'
    r'\s*else if\(global\.player\.rings >= 10\)\s*\n\s*(?://[^\n]*\n\s*)*global\.player\.rings -= 10;\s*\n'
    r'\s*else\s*\n\s*global\.player\.rings = 0;',
    hurt)
if m:
    ok('rama de anillos: pasiva % / else -10 exactos / else todos (por <10)')
else:
    bad('la rama else-if de absorcion (-10 exactos) no esta bien formada')

# sangre solo si no absorbido
m = re.search(r'if\(!_ringAbsorb\)\s*\n\s*net_quick_effect\(global\.player\.x, global\.player\.y, blood', hurt)
if m:
    ok('sangre solo en dano real; absorbido = solo anillos dispersos')
else:
    bad('el efecto de sangre no esta condicionado')

# ------------------------------------------------------------- 4. simulacion
print('== 4. SIMULACION del flujo (escenarios del usuario) ==')

def sim_hurt(rings, hp, dmg, char='otros', vanilla_in_match=False):
    """Replica scr_player_hurt (solo la parte relevante)."""
    absorb = dmg > 0 and rings >= 10
    if char == 'exe':
        pass  # exe no pierde vida por aqui
    elif hp > 0 and not absorb:
        hp -= dmg
    fort = -1
    if char == 'vanilla':
        fort = max(3, (rings * 15) // 100)
    elif char == 'cream' and vanilla_in_match:
        fort = max(3, (rings * 30) // 100)
    if rings > 0 and dmg > 0:
        if fort > 0:
            rings = max(0, rings - min(fort, rings))
        elif rings >= 10:
            rings -= 10
        else:
            rings = 0
    return rings, max(0, hp)

def sim_pickup(rings, hp, heal=True):
    """Replica la conversion de cura del pickup (+1 anillo con cura)."""
    rings = min(rings + 1, 119)
    if rings >= 10 and hp < 100 and heal:
        rings -= 10          # fix v6.x (antes: rings = 0)
        hp = min(100, hp + 20)
    return rings, hp

casos = [
    # (nombre, rings, hp, dmg, char, vim, rings_fin, hp_fin)
    ('15 anillos, golpe 20: absorbe, quedan 5, vida intacta', 15, 100, 20, 'otros', False, 5, 100),
    ('20 anillos: absorbe, quedan 10', 20, 100, 20, 'otros', False, 10, 100),
    ('exactamente 10: absorbe, quedan 0, vida intacta', 10, 100, 20, 'otros', False, 0, 100),
    ('9 anillos, vida 80: pierde TODOS y la vida (-20)', 9, 80, 20, 'otros', False, 0, 60),
    ('0 anillos, vida 80: solo vida', 0, 80, 20, 'otros', False, 0, 60),
    ('vida 40 + 12 anillos: absorbe SIN curar', 12, 40, 20, 'otros', False, 2, 40),
    ('Vanilla 50 anillos: pasiva 15% (pierde 7, no 10), absorbe', 50, 100, 20, 'vanilla', False, 43, 100),
    ('Cream+Vanilla 50 anillos: pasiva 30% (pierde 15), absorbe', 50, 100, 20, 'cream', True, 35, 100),
    ('Cream SIN Vanilla 50 anillos: regla comun (-10)', 50, 100, 20, 'cream', False, 40, 100),
]
for nombre, r0, hp0, dmg, ch, vim, r1, hp1 in casos:
    rf, hpf = sim_hurt(r0, hp0, dmg, ch, vim)
    if rf == r1 and hpf == hp1:
        ok(f'{nombre} -> rings={rf}, hp={hpf}')
    else:
        bad(f'{nombre} -> esperado rings={r1} hp={hp1}, obtenido rings={rf} hp={hpf}')

curas = [
    ('25 anillos al curarse: gana vida y CONSERVA 16 (antes perdia todo)', 25, 80, 16, 100),
    ('10 exactos al curarse: quedan 0', 10, 80, 1, 100),
    ('vida full: no convierte (25 + 1 = 26)', 25, 100, 26, 100),
]
for nombre, r0, hp0, r1, hp1 in curas:
    rf, hpf = sim_pickup(r0, hp0)
    if rf == r1 and hpf == hp1:
        ok(f'{nombre} -> rings={rf}, hp={hpf}')
    else:
        bad(f'{nombre} -> esperado rings={r1} hp={hp1}, obtenido rings={rf} hp={hpf}')

print()
print(f'RESULTADO: {passed} OK / {failed} FAIL')
sys.exit(1 if failed else 0)
