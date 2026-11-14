# -*- coding: utf-8 -*-
# =====================================================================
#  VALIDADOR fix-nega-v17 — "LA VIDA REAL DEL NEGA"
#  Comprueba que TODOS los cambios de la v17 están presentes y correctos
#  en los archivos del repo. Se ejecuta desde la raíz del proyecto:
#      python3 scripts/check_fix_nega_v17.py
# =====================================================================
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
fails = []
oks = 0

def read(p):
    with open(os.path.join(ROOT, p), encoding='utf-8') as f:
        return f.read()

def check(name, cond):
    global oks
    if cond:
        oks += 1
        print(f"  OK  {name}")
    else:
        fails.append(name)
        print(f"FAIL  {name}")

def strip_gml(src):
    src = re.sub(r'//[^\n]*', '', src)
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    src = re.sub(r'"(?:\\.|[^"\\])*"', '""', src)
    src = re.sub(r"'(?:\\.|[^'\\])*'", "''", src)
    return src

print("== A. NUCLEO DEL NEGA (scr_jinna_negatouch.gml) ==")
nt = read('scripts/scr_jinna_negatouch/scr_jinna_negatouch.gml')
check("macro JINNA_NEGA_STUN_DAMAGE 20", "#macro JINNA_NEGA_STUN_DAMAGE 20" in nt)
check("macro JINNA_NEGA_REDHEAL 10", "#macro JINNA_NEGA_REDHEAL 10" in nt)
check("scr_jinna_negatouch_down existe", "function scr_jinna_negatouch_down()" in nt)
check("down: Sally fase 2 (fase2Used)", "CHARACTER_SALLY_CANON && !global.player.fase2Used" in nt)
check("down: Sally sigue NEGA (revivalTimes 2 tras el start)",
      "scr_sally_canon_fase2_start(0);" in nt and "global.player.revivalTimes = 2;        // sigue siendo NEGA" in nt)
check("down: Vanilla paciencia (pacienciaUsed)", "CHARACTER_VANILLA && !global.player.pacienciaUsed" in nt)
check("down: Sonic nervios (la unica excepcion es Amy)",
      "CHARACTER_SONIC && !global.player.nerviosUsed" in nt and "nerviosState = 1;" in nt)
check("down: Rouge moribunda con gate propio nega (negaMoribundaUsed)",
      "negaMoribundaUsed" in nt and "ROUGE_MORIBUNDA_TIME" in nt)
check("down: Amy SIN burbuja (no hay rama de burbuja en el down)",
      "bubbleState" not in nt[nt.index("function scr_jinna_negatouch_down"):])
check("down: paciencia mantiene el bando (pacienciaState = 1 dentro del with)",
      "pacienciaState = 1;" in nt and "VANILLA_PACIENCIA_TIME" in nt)
check("down: vuelta al portal (CLIENT_JINNA_MINION_DOWN)", "CLIENT_JINNA_MINION_DOWN" in nt)
check("scr_jinna_negatouch_stun_hurt existe", "function scr_jinna_negatouch_stun_hurt()" in nt)
check("stun_hurt: 20 de daño por stun", "global.player.hp -= JINNA_NEGA_STUN_DAMAGE;" in nt)
check("stun_hurt: reporte de stats canal 3", "buffer_write(_pak, buffer_u8, 3);" in nt)
check("stun_hurt: sangre visible", "net_quick_effect(global.player.x, global.player.y, spr_blood3" in nt)
check("stun_hurt: a 0 hp enruta al down", "scr_jinna_negatouch_down();" in nt)
check("stun_hurt: inmune durante fase 2 de Sally", "fase2State != SALLY_CANON_F2_OFF" in nt)
check("stun_hurt: inmune durante paciencia/moribunda de Vanilla", "pacienciaState > 0 || global.player.moribundaState > 0" in nt)
check("stun_hurt: solo negas (marca isNegatouch + revivalTimes 2)",
      'if(!variable_instance_exists(global.player.id, "isNegatouch") || !global.player.isNegatouch)' in nt
      and 'if(global.character == CHARACTER_EXE || global.player.revivalTimes < 2)' in nt)
check("LA PURGA SE RETIRO (0 usos en todo el proyecto)",
      all("scr_jinna_negatouch_purge" not in read(os.path.join(dp, f))
          for dp, _, fs in os.walk(os.path.join(ROOT, 'objects')) for f in fs if f.endswith('.gml'))
      and "scr_jinna_negatouch_purge" not in nt)

print("== B. PUERTA EN scr_player_instakill (0 hp por cualquier via) ==")
ph = read('scripts/scr_player_hurt/scr_player_hurt.gml')
inst = ph[ph.index("function scr_player_instakill"):]
bub = inst.index("BURBUJA DE SECUESTRO")
gate = inst.index("scr_jinna_negatouch_down()")
check("instakill: la puerta nega va ANTES de la burbuja de Amy", gate < bub)
check("instakill: comentario v17 presente", "VIDA REAL DEL NEGA" in inst[:2000])

print("== C. LOS 10 GANCHOS DE STUN (20 de vida cada uno) ==")
hooks = [
    ('objects/obj_player_puppet/Step_0.gml', 2),      # golpe comun + patada duelista
    ('scripts/scr_parry/scr_parry.gml', 1),            # parry de Sonic
    ('objects/obj_fw_bolt/Step_0.gml', 1),             # flecha de Fleetway Amy
    ('objects/obj_tails_projectile/Step_0.gml', 1),    # laser de Tails
    ('objects/obj_blaze_fireball/Step_0.gml', 1),      # bola de fuego de Blaze
    ('objects/obj_amelia_trap/Create_0.gml', 1),       # trampa de Amelia
    ('scripts/scr_chocola/scr_chocola.gml', 1),        # mini-embestida de Chocola
    ('scripts/scr_light_dash/scr_light_dash.gml', 1),  # light dash de Sonic
]
total_hooks = 0
for f, n in hooks:
    c = read(f).count("scr_jinna_negatouch_stun_hurt();")
    total_hooks += c
    check(f"ganchos en {f} ({n})", c == n)
check("total de ganchos = 9 (todas las fuentes de stun de superviviente)", total_hooks == 9)

print("== D. TRAMPA DE AMELIA NEGA (ceguera a los otros, excepto Amy Canon) ==")
tr = read('objects/obj_amelia_trap/Create_0.gml')
check("deteccion de la duena nega (_ameliaNega)", "_ameliaNega" in tr)
check("ceguera nega con excepcion Amy Canon",
      "_negaBlind = _survSide && _ameliaNega && global.character != CHARACTER_AMY_CANON" in tr)
check("el eclipse nega no hereda los +2 s de esbirro", "if(_exeSide && global.character != CHARACTER_EXE)" in tr)

print("== D2. EL ECLIPSE INVERTIDO (el cegado ve 'esfumarse' al otro bando) ==")
pd0 = read('objects/obj_player_puppet/Draw_0.gml')
pd64 = read('objects/obj_player_puppet/Draw_64.gml')
lv64 = read('objects/obj_level/Draw_64.gml')
check("Draw_0 del puppet: exe cegado no ve supervivientes / superviviente cegado no ve al EXE",
      "((global.character == CHARACTER_EXE || global.player.revivalTimes >= 2) ? !isDemonized : isDemonized)" in pd0)
check("Draw_64 del puppet: igual para el HUD",
      "((global.character == CHARACTER_EXE || global.player.revivalTimes >= 2) ? !isDemonized : isDemonized)" in pd64)
check("velo de obj_level: vale para la victima de cualquier bando",
      "if(global.eclipseTimer > 0 && instance_exists(global.player))" in lv64
      and "(global.character == CHARACTER_EXE || global.player.revivalTimes >= 2))\n{" not in lv64)

print("== E. RESCATE DE LOS CAIDOS (Vanilla revive muertos, 15 anillos) ==")
rv = read('scripts/scr_survivor_revive/scr_survivor_revive.gml')
check("prompt del rescate de muertos (rama v17)",
      "RESCATE DE LOS CA\u00cdDOS" in rv and "state == DEAD && hp <= 0 && revivalTimes < 2" in rv)
check("solo la Vanilla sin demonizar revive muertos", "global.character == CHARACTER_VANILLA\n        && global.player.revivalTimes < 2" in rv)
check("manda el MISMO paquete del rescate (DEDEMONIZE_PROGRESS)",
      rv.count("CLIENT_VANILLA_DEDEMONIZE_PROGRESS") >= 2)
check("cobra con el MISMO coste (VANILLA_DEDEMON_COST)", rv.count("VANILLA_DEDEMON_COST") >= 4)

print("== F. ANILLOS DE VANILLA NEGA (los 2 anillos negros de Exetior) ==")
vn = read('objects/obj_vanilla/Create_0.gml')
check("byte 2 para los anillos negros de la Vanilla nega",
      '(revivalTimes >= 2 && variable_instance_exists(id, "isNegatouch") && isNegatouch) ? 2 : (revivalTimes >= 2 ? 1 : 0)' in vn)
check("los demas emisores no cambian (Amy Canon sigue mandando bool false)",
      'buffer_write(pk, buffer_bool, false);' in read('scripts/scr_amy_canon_special/scr_amy_canon_special.gml'))

print("== G. CURA DE LOS NEGAS CON ANILLOS ==")
rr = read('objects/obj_redring/Step_0.gml')
br = read('objects/obj_blackring/Step_0.gml')
check("redring: el nega herido lo recoge", "scr_negatouch_is(global.player)" in rr and "hp < 100" in rr)
check("blackring: el nega herido lo recoge", "scr_negatouch_is(global.player)" in br and "hp < 100" in br)
ng = read('scripts/net_state_game/net_state_game.gml')
check("RING_COLLECTED: cura +10 silenciosa del anillo rojo",
      "min(100, global.player.hp + JINNA_NEGA_REDHEAL)" in ng)
check("BRING_COLLECTED: cura COMPLETA del anillo negro", "global.player.hp = 100;" in ng)
seg_ring = ng[ng.index("case PacketType.SERVER_RING_COLLECTED"):]
check("RING_COLLECTED: el nega no recibe mindfuck (break antes del debuff)",
      seg_ring.index("JINNA_NEGA_REDHEAL") < seg_ring.index("mus_mindfuck"))
seg_bring = ng[ng.index("case PacketType.SERVER_BRING_COLLECTED"):]
check("BRING_COLLECTED: el nega no recibe el daño (-20/-5 anillos)",
      seg_bring.index("global.player.hp = 100;") < seg_bring.index("obj_achivements.wasHurt = true;"))

print("== H. RESTAURACION DEL REVIVIDO (SERVER_VANILLA_DEDEMONIZE) ==")
check("captura _wasDead antes de revivir", "var _wasDead = global.player.isDead;" in ng)
check("restaura camara/agonia/barrita solo si venia muerto",
      "_wasDead" in ng and "global.cameraMode = 0; // vuelve de la cámara de espectador" in ng)

print("== I. NERF Y CHOCOLA (scr_chocola.gml) ==")
ch = read('scripts/scr_chocola/scr_chocola.gml')
check("NERF: fortaleza minima 5 (antes 3)", "#macro VANILLA_FORTALEZA_MIN 5" in ch)
check("Vanilla nega NO manda a Chocola con Cream normal (_negVanilla)",
      'var _negVanilla = revivalTimes >= 2 && variable_instance_exists(id, "isNegatouch") && isNegatouch;' in ch)
check("...salvo que Cream tambien sea nega",
      '(!_negVanilla || (variable_instance_exists(_cream.id, "isNegatouch") && _cream.isNegatook))' in ch
      or '(!_negVanilla || (variable_instance_exists(_cream.id, "isNegatouch") && _cream.isNegatouch))' in ch)

print("== J. SERVER (Game.c) ==")
gc = read('betterserver-oss/disasterserver/states/Game.c')
check("MINION_DOWN: acepta al nega (PLAYER_NEGATIZED)",
      "if (v->plr.data[0] != 1 && !(v->plr.flags & PLAYER_NEGATIZED))" in gc)
seg = gc[gc.index("case CLIENT_CREAM_SPAWN_RINGS"):]
check("anillos negros: rama red_ring == 2 con MakeBlackRing",
      "else if (red_ring == 2)" in seg and "MakeBlackRing(bX, bY)" in seg)
check("anillos negros: la pareja (2 offsets {25,-27})", "uint16_t bposX[2] = { 25, -27 };" in seg)
check("los anillos rojos siguen igual (rama red_ring generica)", "else if (red_ring)" in seg)
check("dedemonize instantaneo: rescata tambien al nega/minion",
      "if (target->plr.data[0] == 1 && !(target->plr.flags & PLAYER_NEGATIZED))" in gc)
check("dedemonize: limpia PLAYER_NEGATIZED al rescatar",
      gc.count("DEL_FLAG(target->plr.flags, PLAYER_NEGATIZED);") >= 2)
seg2 = gc[gc.index("case CLIENT_VANILLA_DEDEMONIZE_PROGRESS"):]
check("progress: dos caminos (dedemon_path / fallen_path)",
      "bool dedemon_path" in seg2 and "bool fallen_path" in seg2)
check("milagro: limpia PLAYER_DEAD + PLAYER_CANTREVIVE",
      "DEL_FLAG(target->plr.flags, PLAYER_DEAD);" in seg2 and "DEL_FLAG(target->plr.flags, PLAYER_CANTREVIVE);" in seg2)
check("milagro: corta el death-timer",
      "target->plr.death_timer_sec = 0;" in seg2 and "target->plr.death_timer = 0;" in seg2)
check("milagro: reenvia el SERVER_VANILLA_DEDEMONIZE", "SERVER_VANILLA_DEDEMONIZE" in seg2)
check("tras el rescate/revive: game_state_check (lo vuelve a contar vivo)",
      seg2.index("revived from death by Vanilla") < seg2.index("RAssert(game_state_check(v->server));"))
check("la barra del caido usa plr.revival (la del revive normal)",
      "target->plr.revival += 0.03 + 0.002 * bonus;" in seg2)

print("== K. LLAVES BALANCEADAS (GML tocado) ==")
gml_files = [f for f, _ in hooks] + [
    'scripts/scr_jinna_negatouch/scr_jinna_negatouch.gml',
    'scripts/scr_player_hurt/scr_player_hurt.gml',
    'scripts/scr_survivor_revive/scr_survivor_revive.gml',
    'objects/obj_vanilla/Create_0.gml',
    'objects/obj_redring/Step_0.gml',
    'objects/obj_blackring/Step_0.gml',
    'scripts/net_state_game/net_state_game.gml',
    'scripts/scr_chocola/scr_chocola.gml',
    'scripts/scr_light_dash/scr_light_dash.gml',
    'objects/obj_player_puppet/Draw_0.gml',
    'objects/obj_player_puppet/Draw_64.gml',
    'objects/obj_level/Draw_64.gml',
]
for f in gml_files:
    s = strip_gml(read(f))
    check(f"llaves balanceadas: {f}", s.count('{') == s.count('}'))

s = strip_gml(gc)
check("llaves balanceadas: Game.c", s.count('{') == s.count('}'))

print()
print(f"RESULTADO: {oks} OK / {len(fails)} FAIL")
if fails:
    print("FALLOS:")
    for f in fails:
        print(f"  - {f}")
    sys.exit(1)
print("TODOS LOS CHECKS DE LA v17 EN VERDE")
