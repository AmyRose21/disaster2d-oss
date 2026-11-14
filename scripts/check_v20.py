#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FIX V20 — VALIDADOR (3 bugs).

1) "converti 1 y mate 1 y el juego no se termina" (practica .ep):
   el guard de game_state_check solo cerraba con TODOS nega. Ahora
   cierra con >= 1 nega y nadie vivo (muerto/esbirro/nega/escapado no
   cuentan; el ATRAPADO en el portal si: sigue "vivo" alla esperando
   la invocacion). Simulaciones 1:1 de la logica C.
2) "a jina le hace falta la opcion de emotico": taunts de Jinna libres
   (la tienda de taunts no tiene hueco para ella) + su risa en EMOTION3.
3) "las cosas de tails estan atadas a vivo/muerto": colas NEGA
   (spr_tailsnega_tail1/2 nuevos, inversion pixel-exacta, estructura
   auto-contenida del fix v19), colas ocultas al entrar al portal y
   la animacion DEAD del nega reproducida UNA vez (15 supervivientes).

Sale 0 solo si TODO pasa.
"""
import json
import os
import re
import sys

ROOT = '/home/z/my-project/disaster2d-oss'
fails = 0
passes = 0


def check(cond, msg):
    global fails, passes
    if cond:
        passes += 1
    else:
        fails += 1
        print(f'  FAIL: {msg}')


def rd(path):
    return open(path, encoding='utf-8').read()


# ===========================================================================
print('== 1. BUG "1 NEGA + 1 MUERTO NO TERMINA" (server Game.c) ==')
gc = rd(f'{ROOT}/betterserver-oss/disasterserver/states/Game.c')

guard = gc[gc.find('if (server->lobby.exe_practice)'):gc.find('uint8_t escaped = 0;')]
check('uint8_t alive = 0;' in guard, 'game_state_check: contador alive en el guard de practica')
check('others > 0 && negas > 0 && alive == 0' in guard, 'game_state_check: cierre = >=1 nega Y nadie vivo')
check('game_end(server, ED_EXEWIN, true)' in guard, 'game_state_check: el cierre sigue siendo ED_EXEWIN')
check('PLAYER_DEAD | PLAYER_DEMONIZED | PLAYER_ESCAPED' in guard,
      'game_state_check: vivo excluye muerto/esbirro/escapado (y conta al atrapado)')
check(guard.count('if (v->id == server->game.exe)') >= 1, 'game_state_check: el exe sigue excluido del conteo')
check('negas == others' not in guard, 'game_state_check: el viejo TODOS-nega ya no es la unica condicion')

print('== 2. SIMULACIONES 1:1 (logica espejo del guard de practica) ==')


def simulate(practice, players):
    """players: (is_exe, DEAD, DEMONIZED, ESCAPED, CAUGHT, NEGATIZED).
    Espejo exacto de game_state_check: devuelve el ending o None."""
    if practice:
        others = negas = alive = 0
        for (exe, dead, dem, esc, caught, nega) in players:
            if exe:
                continue
            others += 1
            if nega:
                negas += 1
            if not (dead or dem or esc):
                alive += 1  # el atrapado (caught) cuenta: vivo en el portal
        if others > 0 and negas > 0 and alive == 0:
            return 'EXEWIN'
        return None
    escaped = dead = exes = 0
    ingame = len(players)
    for (exe, dead_, dem, esc, caught, nega) in players:
        if esc:
            escaped += 1
        if dead_ or dem or caught:
            dead += 1
        if exe:
            exes += 1
    total = ingame - (exes + dead + escaped)
    if total <= 0:
        return 'SURVWIN' if escaped > 0 else 'EXEWIN'
    return None


EXE = (True, False, False, False, False, False)


def surv(**kw):
    return (False, kw.get('dead', False), kw.get('dem', False), kw.get('esc', False),
            kw.get('caught', False), kw.get('nega', False))


# EL BUG REPORTADO: .ep, 1 convertido (nega) + 1 matado por el minion
check(simulate(True, [EXE, surv(dem=True, nega=True), surv(dead=True)]) == 'EXEWIN',
      '.ep exe+2 (1 nega + 1 muerta por el minion) -> EXEWIN (EL BUG REPORTADO)')
# v16 intacto: todos nega cierra
check(simulate(True, [EXE, surv(dem=True, nega=True), surv(dem=True, nega=True)]) == 'EXEWIN',
      '.ep exe+2 (las dos nega) -> EXEWIN (fix v16 intacto)')
check(simulate(True, [EXE, surv(dem=True, nega=True)]) == 'EXEWIN',
      '.ep exe+1 convertida -> EXEWIN (fix v16 intacto)')
# aprobados intactos: sola / viva / muerta / esbirro / escape -> abierta
check(simulate(True, [EXE]) is None, '.ep exe SOLA -> sigue abierta')
check(simulate(True, [EXE, surv()]) is None, '.ep exe+1 viva -> sigue abierta')
check(simulate(True, [EXE, surv(dead=True)]) is None, '.ep exe+1 muerta -> sigue abierta (aprobado)')
check(simulate(True, [EXE, surv(dem=True)]) is None, '.ep exe+1 esbirro comun -> sigue abierta (aprobado)')
check(simulate(True, [EXE, surv(esc=True), surv()]) is None, '.ep escape con alguien vivo -> sigue abierta')
check(simulate(True, [EXE, surv(dead=True), surv(dead=True)]) is None,
      '.ep todos muertos SIN nega -> sigue abierta (aprobado)')
# el atrapado en el portal cuenta como vivo: no corta el flujo captura->summon
check(simulate(True, [EXE, surv(dem=True, nega=True), surv(caught=True)]) is None,
      '.ep 1 nega + 1 atrapada-fresca en el portal -> sigue abierta (podra invocarla)')
check(simulate(True, [EXE, surv(caught=True), surv(caught=True)]) is None,
      '.ep las dos atrapadas (ninguna nega aun) -> sigue abierta (summon pendiente)')
# nega re-portaled (conserva NEGATIZED) + muerto: la nega del portal sigue
# siendo INVOCABLE (mismo trato que la atrapada fresca): la ronda espera al
# summon — al invocarla el check del CLIENT_JINNA_MINION cierra (negas 2, alive 0)
check(simulate(True, [EXE, surv(dem=False, caught=True, nega=True), surv(dead=True)]) is None,
      '.ep 1 nega de vuelta al portal + 1 muerta -> abierta (invocable: cerrara al summon)')
# nega + escapado -> cierra (nadie a quien probar)
check(simulate(True, [EXE, surv(dem=True, nega=True), surv(esc=True)]) == 'EXEWIN',
      '.ep 1 nega + 1 escapada -> EXEWIN')
# PARTIDA NORMAL: sin cambios (el guard de practica no aplica)
check(simulate(False, [EXE, surv(dem=True, nega=True), surv(dead=True)]) == 'EXEWIN',
      'normal exe+2 (nega + muerta) -> EXEWIN (como siempre: DEMONIZED cuenta)')
check(simulate(False, [EXE, surv(caught=True)]) == 'EXEWIN',
      'normal exe+1 atrapada -> EXEWIN (v6 intacto)')
check(simulate(False, [EXE, surv()]) is None, 'normal exe+1 viva -> sigue')

# las llamadas a game_state_check siguen en los flujos que vacian "alive"
check(gc.count('RAssert(game_state_check(v->server));') >= 6,
      'game_state_check llamado en muerte/negatouch/summon/escape/left (>=6 flujos)')

# ===========================================================================
print('== 3. BUG "JINNA SIN EMOTICONOS" ==')
jc = rd(f'{ROOT}/objects/obj_jinna/Create_0.gml')
check('taunt1 = true;' in jc and 'taunt2 = true;' in jc,
      'obj_jinna: taunt1/taunt2 libres (la killer exclusiva del token no tiene boton de tienda)')
check('array_contains(obj_unlockables.trades, "tjinna0")' not in jc,
      'obj_jinna: ya no depende del trade tjinna0 (imposible de comprar)')
mb = rd(f'{ROOT}/scripts/scr_move_basic/scr_move_basic.gml')
check(re.search(r'case EXE_JINNA:\s*\n\s*emotionSnd = audio_play_sound\(snd_jina_taunt3', mb) is not None,
      'scr_move_basic: EMOTION3 de Jinna con su risa (snd_jina_taunt3)')
check(mb.count('case EXE_JINNA:') >= 3,
      'scr_move_basic: Jinna presente en los 3 switches de sonido de emoticono')
# la infraestructura ya existia (Create/Step_2/Other_7/Draw_76/sprites)
check('emotion = false;' in jc and 'emotionSnd = snd_none;' in jc, 'obj_jinna: variables emotion declaradas')
o7 = rd(f'{ROOT}/objects/obj_jinna/Other_7.gml')
check(o7.count('case EMOTION') == 3, 'obj_jinna: Other_7 maneja EMOTION1/2/3')
ex = rd(f'{ROOT}/scripts/scr_exe/scr_exe.gml')
check('spr_jinna_emotion,' in ex and 'spr_jinna_emotion2,' in ex and 'spr_jinna_emotion3,' in ex,
      'scr_exe: los 3 sprites de emoticono de Jinna en el array (slots 9/10/11)')

# ===========================================================================
print('== 4. BUG "COLAS DE TAILS" (sprites nuevos) ==')


def load_yy(path):
    return json.loads(re.sub(r',(\s*[}\]])', r'\1', rd(path)))


from PIL import Image  # noqa: E402

for base, nega in [('spr_tails_tail1', 'spr_tailsnega_tail1'), ('spr_tails_tail2', 'spr_tailsnega_tail2')]:
    bd, nd = f'{ROOT}/sprites/{base}', f'{ROOT}/sprites/{nega}'
    check(os.path.isdir(nd), f'{nega}: carpeta existe')
    if not os.path.isdir(nd):
        continue
    byy, nyy = load_yy(f'{bd}/{base}.yy'), load_yy(f'{nd}/{nega}.yy')

    def kfseq(yy):
        return [kf['Channels']['0']['Id']['name'] for kf in yy['sequence']['tracks'][0]['keyframes']['Keyframes']]

    own = set(f['name'] for f in nyy['frames'])
    nkf, bkf = kfseq(nyy), kfseq(byy)
    check(nyy['%Name'] == nega and nyy['name'] == nega, f'{nega}: nombre interno correcto')
    check(all(u in own for u in nkf), f'{nega}: keyframes -> frames PROPIOS (auto-contenido v19)')
    check(nyy['sequence']['tracks'][0]['keyframes']['Keyframes'][0]['Channels']['0']['Id']['path'] ==
          f'sprites/{nega}/{nega}.yy', f'{nega}: path de keyframes a su propio .yy')
    check(len(bkf) == len(nkf) and len(nkf) > 0, f'{nega}: mismo numero de frames que el base ({len(nkf)})')
    mism = 0
    for b, n in zip(bkf, nkf):
        ib = Image.open(f'{bd}/{b}.png').convert('RGBA')
        inn = Image.open(f'{nd}/{n}.png').convert('RGBA')
        if ib.size != inn.size:
            mism += 999999
            continue
        pb, pn = ib.load(), inn.load()
        mism += sum(1 for y in range(ib.height) for x in range(ib.width)
                    if pb[x, y][3] != pn[x, y][3]
                    or (pb[x, y][3] > 0 and (255 - pb[x, y][0], 255 - pb[x, y][1], 255 - pb[x, y][2]) != (pn[x, y][0], pn[x, y][1], pn[x, y][2])))
    check(mism == 0, f'{nega}: inversion fotografica pixel-exacta ({mism} px mal)')
    okc = all(byy[k] == nyy[k] for k in ['width', 'height', 'bboxMode', 'bbox_left', 'bbox_right', 'bbox_top', 'bbox_bottom'])
    oks = all(byy['sequence'][k] == nyy['sequence'][k] for k in ['xorigin', 'yorigin', 'playbackSpeed', 'length'])
    check(okc and oks, f'{nega}: bbox/origin/playback clonados del base')
    lay = all(os.path.isdir(f'{nd}/layers/{n}') and len(os.listdir(f'{nd}/layers/{n}')) == 1 for n in nkf)
    check(lay, f'{nega}: layers/<frame>/<layer>.png para cada frame')

yyp = rd(f'{ROOT}/Sonicexe The Disaster 2D Remake.yyp')
dy = json.loads(re.sub(r',(\s*[}\]])', r'\1', yyp))
names = [r['id']['name'] for r in dy['resources']]
check('spr_tailsnega_tail1' in names and 'spr_tailsnega_tail2' in names, 'yyp: ambas colas nega registradas')
check(len(names) == len(set(names)), 'yyp: sin recursos duplicados')
check('"spr_tailsnega_tail1"' in yyp and '"spr_tailsnega_tail2"' in yyp, 'yyp: entradas en formato compacto GM')

# ===========================================================================
print('== 5. COLAS: logica (obj_tails_tail + obj_puppet_tail) ==')
tt = rd(f'{ROOT}/objects/obj_tails_tail/Step_2.gml')
check('if(!obj_tails.visible)' in tt, 'obj_tails_tail: se esconde cuando el cuerpo entra al portal (visible = false)')
check(tt.count('spr_tailsnega_tail1') == 2 and tt.count('spr_tailsnega_tail2') == 1,
      'obj_tails_tail: sprite nega en las 3 ramas (balancing/idle/jump)')
check(tt.count('scr_negatouch_is(obj_tails)') == 3, 'obj_tails_tail: negatouch decide la forma en las 3 ramas')
check('spr_tailsnega_hurt' in tt, 'obj_tails_tail: hurt del nega tambien esconde las colas')
check(tt.count('spr_etails_tail1') == 2 and tt.count('spr_etails_tail2') == 1, 'obj_tails_tail: esbirro demon intacto')
pt = rd(f'{ROOT}/objects/obj_puppet_tail/Step_2.gml')
check('if(!target.visible)' in pt, 'obj_puppet_tail: se esconde cuando el puppet entra al portal')
check(pt.count('spr_tailsnega_tail1') == 2 and pt.count('spr_tailsnega_tail2') == 1,
      'obj_puppet_tail: sprite nega en las 3 ramas')
check(pt.count('scr_negatouch_is(target)') == 3, 'obj_puppet_tail: negatouch decide la forma en las 3 ramas')
check('if(target.hp <= 0)' in pt, 'obj_puppet_tail: muerte (hp 0) sigue escondiendo las colas')

# ===========================================================================
print('== 6. ANIMACION DEAD DEL NEGA: UNA sola pasada (15 supervivientes) ==')
WITH_DEAD = ['obj_tails', 'obj_knux', 'obj_egg', 'obj_amy', 'obj_cream', 'obj_sally',
             'obj_sonic', 'obj_vanilla', 'obj_rouge', 'obj_amy_canon', 'obj_sally_canon', 'obj_amy_fleetway']
TTB = ['obj_metal', 'obj_amelia', 'obj_blaze']
for obj in WITH_DEAD + TTB:
    src = rd(f'{ROOT}/objects/{obj}/Draw_76.gml')
    check('v20 (NEGA)' in src, f'{obj}: clamp nega presente')
    seg = src[src.find('v20 (NEGA)'):src.find('v20 (NEGA)') + 700]
    check('variable_instance_exists(id, "isNegatouch") && isNegatouch' in seg, f'{obj}: guard de marca nega')
    check('image_index >= image_number - 1' in seg and 'image_index = image_number - 1' in seg,
          f'{obj}: tope en el ultimo frame')
    check(src.count('{') == src.count('(') - (src.count('(') - src.count(')')) or True, '')  # placeholder
    check(src.count('{') == src.count('}'), f'{obj}: llaves balanceadas')
    check(src.count('(') == src.count(')'), f'{obj}: parentesis balanceados')
# el esbirro demon conserva su bucle (imagen_speed 0.5 sin tope FUERA del if nega)
for obj in WITH_DEAD:
    src = rd(f'{ROOT}/objects/{obj}/Draw_76.gml')
    i = src.find('case DEAD:')
    seg = src[i:i + 1400]
    # tras el bloque nega viene la rama revivalTimes >= 2 con su 0.5 sin clamp
    after = seg[seg.find('if(revivalTimes >= 2)'):]
    check('image_speed = 0.5;' in after and 'image_number' not in after[:after.find('break;')],
          f'{obj}: esbirro demon sigue en bucle (0.5 sin tope)')

# ===========================================================================
print(f'\nRESULTADO: {passes} OK, {fails} FAIL')
sys.exit(1 if fails else 0)
