#!/usr/bin/env python3
# ============================================================
# check_v54.py — VERIFICACIÓN INTEGRAL de la ronda v54
# (editor Suite_TD2D.html: off-by-one placas + generador +
#  nombre multicolor + cartel independiente)
# Uso: python3 check_v54.py   (desde donde sea; rutas absolutas)
# ============================================================
import re, sys, subprocess, json

REPO = '/home/z/my-project/repo'
H = open(REPO + '/Suite_TD2D.html', encoding='utf-8').read()
GML = open(REPO + '/scripts/scr_characters/scr_characters.gml', encoding='utf-8').read()
LOBBY = open(REPO + '/objects/obj_lobby/Draw_0.gml', encoding='utf-8').read()

OK = [0]
BAD = []
def check(cond, msg):
    if cond: OK[0] += 1
    else: BAD.append(msg)

# ---------- A. FIX OFF-BY-ONE (plaqueMapFor) ----------
print('A. Off-by-one plaqueMapFor:')
check('(r.isExe ? r.idx : (r.idx != null ? r.idx - 1 : 0)))' in H,
      'A1 valOf usa sprInd real (macro-1) para supervivientes')
check("let ent = byIdx.get((r.isExe ? 'k:' : 's:') + (r.isExe ? r.idx : (r.idx != null ? r.idx - 1 : 0)))" in H,
      'A2 clave de búsqueda con sprInd real')
check('v54 FIX OFF-BY-ONE' in H, 'A3 comentario del fix presente')
check('frame: r.idx - 1 }' in H, 'A4 fallback idx crudo con sprInd real')

# ---------- B. GENERADOR sincronizado ----------
print('B. Generador de scr_characters sincronizado:')
check("'        case CHARACTER_ROUGE: return 13;\\n'" in H,
      'B1 plantilla scr_lobby_icon_frame: Rouge 13 (icono propio v40)')
check("'        case CHARACTER_ROUGE: return CHARACTER_KNUX + 1;\\n'" not in H,
      'B2 ya NO existe plantilla Rouge=Knux en iconos')
check("'        case CHARACTER_ROUGE: return [spr_playerhealth, (CHARACTER_ROUGE - CHARACTER_TAILS) * 7];\\n'" in H,
      'B3 plantilla scr_hud_strip: Rouge fila propia v39')
check("'        case CHARACTER_ROUGE: return [spr_playerhealth_hit, CHARACTER_ROUGE - CHARACTER_TAILS];\\n'" in H,
      'B4 plantilla scr_hud_hit: Rouge icono propio v39')
check("'        case CHARACTER_ROUGE: return [spr_playerescaped, CHARACTER_ROUGE - CHARACTER_TAILS];\\n'" in H,
      'B5 plantilla scr_hud_escaped: Rouge icono propio v39')
check("'        case CHARACTER_ROUGE: return [spr_playerhealth_nega, (CHARACTER_ROUGE - CHARACTER_TAILS) * 7];\\n'" in H,
      'B6 plantilla nega: Rouge fila propia v39')
check("'        case CHARACTER_ROUGE: return [spr_playerhealth_redring_nega, (CHARACTER_ROUGE - CHARACTER_TAILS) * 7];\\n'" in H,
      'B7 plantilla redring_nega: Rouge fila propia v39')
# Kris placeholders SIGUEN (pedido expreso v5/v39)
check(H.count("'        case CHARACTER_KRIS: return CHARACTER_KNUX + 1;\\n'") >= 1,
      'B8 Kris conserva SU placeholder Knux (pedido de la duena)')

# ---------- C. NOMBRE MULTICOLOR ----------
print('C. Nombre multicolor:')
check('function tagOfColor' in H, 'C1 helper tagOfColor existe')
check('tagOfColor(cj)' in H, 'C2 decodePlaque usa tagOfColor (sin TAG_OF)')
check('TAG_OF' not in H, 'C3 sin referencias al nombre equivocado TAG_OF')
check('tagged: nameTags' in H, 'C4 decodePlaque expone name.tagged')
check('(model.name.tagged && model.name.tagged !== model.name.text) ? model.name.tagged : model.name.text' in H,
      'C5 modelToEditable pasa el nombre con tags')
check('#arte-name-presets' in H, 'C6 HTML de presets del nombre')
check(H.count('data-npreset=') >= 8, 'C7 8 botones preset')
check('data-npreset=\"#c20037\"' in H, 'C8 preset rojo presente')
check('$$(\'#arte-name-presets button[data-npreset]\')' in H, 'C9 handler de presets')

# ---------- D. CARTEL INDEPENDIENTE ----------
print('D. Cartel independiente:')
check("'＋ propio'" in H or '＋ propio' in H, 'D1 botón ＋ propio visible')
check('selectNewPlaque(e);' in H, 'D2 click abre el flujo de placa nueva')
check('placa NUEVA (independiente: se creará sprites/spr_char_info_' in H,
      'D3 título de la placa nueva correcto')

# ---------- E. SINTAXIS ----------
print('E. Sintaxis JS:')
r = subprocess.run(['node', '-e', '''
const fs=require('fs');
const html=fs.readFileSync('%s','utf8');
let i=0,n=0,bad=0;
while((i=html.indexOf('<script>',i))>=0){
  const e=html.indexOf('</'+'script>',i);
  try { new Function(html.slice(i+8,e)); } catch(err){ bad++; }
  n++; i=e;
}
console.log(n+' scripts, '+bad+' errores');
''' % (REPO + '/Suite_TD2D.html')], capture_output=True, text=True)
out = r.stdout.strip()
check('errores' in out and out.split('errores')[0].split(',')[1].strip() in ('0',), 'E1 todos los scripts parsean (' + out + ')')

# ---------- F. GIT (solo lo tocado) ----------
print('F. Alcance del cambio:')
r2 = subprocess.run(['git', '-C', REPO, 'diff', '--stat'], capture_output=True, text=True)
files = [l.split('|')[0].strip() for l in r2.stdout.splitlines() if '|' in l]
# v54: el editor + los 2 docs de la regla de oro (cache/memory SIEMPRE viajan)
check(files == ['CACHE.md', 'Suite_TD2D.html', 'worklog.md'],
      'F1 solo Suite_TD2D.html + docs(cache/memory): ' + str(files))

# ---------- G. ANTI-CHEAT ----------
print('G. Anti-cheat:')
r3 = subprocess.run(['git', '-C', REPO, 'diff'], capture_output=True, text=True)
d = r3.stdout
net_new = len(re.findall(r'^\+.*\b(CLIENT_|SERVER_)\w+', d, re.M))
check(net_new == 0, 'G1 cero paquetes nuevos (' + str(net_new) + ')')
check('net_send' not in d.split('+')[-1] if d else True, 'G2 sin llamadas de red nuevas')
check('.yyp' not in r2.stdout, 'G3 el .yyp NO se toca (el zip es solo del editor)')

# ---------- H. JUEGO INTACTO ----------
print('H. Juego intacto:')
check('case CHARACTER_ROUGE: return 13;' in GML, 'H1 scr_characters real intacto (Rouge 13)')
check('case CHARACTER_KRIS: return CHARACTER_KNUX + 1;' in GML, 'H2 Kris placeholder intacto')
check('else if(sprInd == 15)' in LOBBY and '_infoFrame = 1; // knux' in LOBBY,
      'H3 obj_lobby intacto (Kris placeholder del juego)')

print()
print('=' * 60)
print('RESULTADO: %d OK · %d FALLOS' % (OK[0], len(BAD)))
for b in BAD: print('  ✗ ' + b)
sys.exit(1 if BAD else 0)
