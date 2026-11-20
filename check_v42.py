#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v42.py — Validador de la ronda v42 (el pedido de la duena):

  BUG: el ESCUDO ELECTRICO del modo EGGMAN de Rouge congelaba la
  animacion — el estado quedaba CLAVADO en ROUGE_ESHIELD (26, pose de
  idle quieta) durante los 1,5 s del aura: caminaba deslizandose en la
  pose de idle y parada no respiraba. El mismo bug que tuvo el escudo
  de Sally (fix v5.6) — y a Eggman NO le pasa porque su Step_2 no
  tiene rama isAttacking: su escudo es SOLO el aura encima.

  FIX (patron Eggman / Sally v5.6, pedido literal de la duena: "es solo
  el escudo electrico nada mas, no remplazaria ninguna animacion"):
  1. obj_rouge/Step_2: mientras dura el escudo la maquina de estados
     fluye NORMAL (idle/walk/run/jump/...): la rama isAttacking se
     salta con el gate eShieldTimer <= 0 (antes asignaba el 26).
     isAttacking SIGUE en true durante el escudo (igual que Eggman):
     es el canal de red (bit PLAYER_ATTACKING ya viaja para Rouge —
     obj_netclient/Step_2 lo manda desde la v4.4).
  2. Puppets (las pantallas ajenas): el aura y el chispazo se detectan
     por isAttacking + estado que NO sea de sus ataques de verdad
     (14 taladro / 15 tornado / 24 patada) — antes era state == 26.
     Su cuerpo anima NORMAL en las pantallas ajenas (el image_index
     llega sincronizado por el mismo paquete de siempre).
  3. Rebotes genericos del puppet: quedan SOLO para el tornado/taladro
     (14/15) — la patada (24) y el escudo caen a sus efectos propios
     (v33 intacta). CERO cambios de protocolo: mismo u8 de estado, mismos
     bitflags de siempre.

Verifica (estatico, sin GameMaker):
  A-fix local, B-canal del puppet, C-sin regresiones (kick/tornado/
  taladro/scr_rouge_special/obj_egg/tablas/red), D-sintaxis,
  E-regresion git, F-anti-cheat (cero superficie de red nueva).

Uso: python3 check_v42.py [ruta_repo]
     (por defecto /home/z/my-project/disaster2d-oss)
"""
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/disaster2d-oss"
STEP2 = os.path.join(REPO, "objects/obj_rouge/Step_2.gml")
DRAW0 = os.path.join(REPO, "objects/obj_rouge/Draw_0.gml")
DRAW76 = os.path.join(REPO, "objects/obj_rouge/Draw_76.gml")
OTHER7 = os.path.join(REPO, "objects/obj_rouge/Other_7.gml")
CREATE0 = os.path.join(REPO, "objects/obj_rouge/Create_0.gml")
PSTEP = os.path.join(REPO, "objects/obj_player_puppet/Step_0.gml")
PDRAW = os.path.join(REPO, "objects/obj_player_puppet/Draw_0.gml")
SPECIAL = os.path.join(REPO, "scripts/scr_rouge_special/scr_rouge_special.gml")
NETCLIENT = os.path.join(REPO, "objects/obj_netclient/Step_2.gml")
EGG = os.path.join(REPO, "objects/obj_egg/Step_2.gml")
SURV = os.path.join(REPO, "scripts/scr_survivors/scr_survivors.gml")

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print(f"  [OK] {msg}")


def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  [FALLO] {msg}")


def check(cond, msg):
    ok(msg) if cond else bad(msg)


def read(p):
    with open(p, encoding="utf-8", errors="replace") as f:
        return f.read()


def balance(src):
    s = re.sub(r"//[^\n]*", "", src)
    s = re.sub(r'"(\\.|[^"\\])*"', "S", s)
    return s.count("(") == s.count(")") and s.count("{") == s.count("}") and s.count("[") == s.count("]")


print("== A) FIX LOCAL (la animacion deja de congelarse) ==")
s2 = read(STEP2)
check("if(isAttacking && eShieldTimer <= 0)" in s2,
      "Step_2: la rama isAttacking se salta mientras dura el escudo (gate eShieldTimer <= 0)")
check(re.search(r"state\s*=\s*ROUGE_ESHIELD\s*;", s2) is None,
      "Step_2: ya NADIE asigna el estado ROUGE_ESHIELD localmente")
check("if(kickState > 0)" in s2 and "state = ROUGE_KICK;" in s2,
      "Step_2: la PATADA sigue con su estado propio (kickState)")
check("state = ROUGE_AIR_ATTACK;" in s2 and "state = ROUGE_ATTACK;" in s2,
      "Step_2: tornado/taladro siguen con sus estados (14/15)")
check(s2.count("return;") >= 8, "Step_2: la cascada de estados sigue intacta (returns conservados)")
# la cascada normal sigue alcanzable: WALK/RUN/JUMP/FALL mapean
for st in ("state = WALK;", "state = RUN;", "state = JUMP;", "state = FALL;"):
    check(st in s2, f"Step_2: {st[:-1]} intacto (animacion normal con escudo)")
d0 = read(DRAW0)
check("if(eShieldTimer > 0)" in d0 and "draw_sprite(spr_electroshield" in d0,
      "Draw_0 local: el aura se dibuja solo con eShieldTimer (encima del cuerpo, sin tocar el sprite)")
o7 = read(OTHER7)
check("case IDLE:" in o7 and "image_index = image_number - 4;" in o7,
      "Other_7: el clamp del idle (respiracion) intacto — con escudo el idle BREXA en loop normal")
d76 = read(DRAW76)
check("case ROUGE_ESHIELD:" in d76 and "image_speed = 1;" in d76,
      "Draw_76: case ROUGE_ESHIELD defensivo (si algun camino viejo fijara el 26, ANIMA en vez de congelar)")
check("sprite_index = arr[? CHARACTER_ROUGE][state];" in d76,
      "Draw_76: el resolvedor de sprite por estado intacto")

print("== B) CANAL DEL PUPPET (pantallas ajenas, cero protocolo nuevo) ==")
nc = read(NETCLIENT)
check("global.character == CHARACTER_ROUGE" in nc and "bitflags |= PLAYER_ATTACKING;" in nc,
      "obj_netclient ya manda el bit PLAYER_ATTACKING para Rouge (canal preexistente, SIN cambios)")
pd = read(PDRAW)
check("if(isAttacking && state != ROUGE_ATTACK && state != ROUGE_AIR_ATTACK && state != ROUGE_KICK)" in pd
      and "draw_sprite(spr_electroshield" in pd,
      "puppet Draw_0: aura = isAttacking + estado que no es ataque de verdad (patron Eggman)")
check(re.search(r"if\(state == ROUGE_ESHIELD\)", pd) is None,
      "puppet Draw_0: sin referencias al viejo estado 26")
ps = read(PSTEP)
check("if(character == CHARACTER_ROUGE && state != ROUGE_ATTACK && state != ROUGE_AIR_ATTACK && state != ROUGE_KICK)" in ps
      and "stunTime = 2;" in ps and "snd = snd_electroshock;" in ps,
      "puppet Step_0: chispazo electrico = mismo criterio (2 s, sin empujon)")
check(ps.count("(global.character == CHARACTER_ROUGE && (state == ROUGE_ATTACK || state == ROUGE_AIR_ATTACK))") == 1
      and ps.count("(character == CHARACTER_ROUGE && (state == ROUGE_ATTACK || state == ROUGE_AIR_ATTACK))") == 1,
      "puppet Step_0: los 2 rebotes genericos quedan SOLO para tornado/taladro (v33 intacta)")
check(re.search(r"state (?:==|!=) ROUGE_ESHIELD", ps) is None,
      "puppet Step_0: sin referencias vivas al estado 26 (solo en comentarios)")
# simulacion de estados con el escudo activo (isAttacking=1, estado normal):
# el aura/stun/rebotes resuelven igual que antes (26 equivalia a isAttacking+no-ataque)
check("character == CHARACTER_ROUGE && isAttacking && state == ROUGE_KICK" in ps,
      "puppet Step_0: el pad de la PATADA (isAttacking + 24) intacto")

print("== C) SIN REGRESIONES ==")
sp = read(SPECIAL)
check("isAttacking = true;" in sp and "eShieldTimer = ROUGE_ESHIELD_TIME;" in sp,
      "scr_rouge_special: activacion intacta (isAttacking + eShieldTimer — el canal del doctor)")
check("eShieldTimer = 0;" in sp and "isAttacking = false;" in sp,
      "scr_rouge_special: expiracion/muerte/stun apagan el escudo Y el canal juntos")
check("drillState > 0" in sp and "kickState <= 0 && eShieldTimer <= 0" in sp,
      "scr_rouge_special: v37 intacta (el escudo al aterrizar NO arranca tornado; fallback aereo lo excluye)")
egg = read(EGG)
check("if(isAttacking)" not in egg,
      "obj_egg SIN TOCAR: su Step_2 sigue sin rama isAttacking (el escudo del doctor nunca congela)")
surv = read(SURV)
check("spr_rouge_idle //26 = ROUGE_ESHIELD" in surv,
      "tablas de anims intactas (slot 26 reservado; cero .yy/.yyp tocados)")
# el canal es estado u8 + bitflags de siempre: nada de net_* cambio
diff_files = subprocess.run(["git", "diff", "--name-only"], cwd=REPO, capture_output=True, text=True).stdout
net_touched = [f for f in diff_files.splitlines() if f.startswith(("scripts/net_", "objects/obj_netclient"))]
check(not net_touched, f"cero archivos de red tocados ({net_touched or 'confirmado'})")

print("== D) SINTAXIS DE LOS 5 ARCHIVOS EDITADOS ==")
for p in (STEP2, DRAW0, DRAW76, CREATE0, PSTEP, PDRAW):
    check(balance(read(p)), f"llaves/parentesis balanceados: {os.path.relpath(p, REPO)}")

print("== E) REGRESION GIT (solo lo pedido) ==")
st = subprocess.run(["git", "status", "--porcelain"], cwd=REPO, capture_output=True, text=True).stdout
mod = sorted(l[3:] for l in st.splitlines() if l.strip())
expect = sorted([
    "LEEME_ESCUDO_V42.txt",
    "check_v42.py",
    "objects/obj_player_puppet/Draw_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_rouge/Create_0.gml",
    "objects/obj_rouge/Draw_76.gml",
    "objects/obj_rouge/Step_2.gml",
    "worklog.md",
])
check(mod == expect, f"archivos de la ronda exactos: {mod}")
no_touch = [f for f in mod if f.endswith((".yyp", ".yy")) or "/sounds/" in f]
check(not no_touch, f"ningun .yyp/.yy/audio tocado ({no_touch or 'confirmado'})")
full = subprocess.run(["git", "diff", "--stat", "--", "objects/"], cwd=REPO, capture_output=True, text=True).stdout
churn = sum(int(re.search(r"\|\s+(\d+)", x).group(1)) for x in full.splitlines() if "|" in x and "gml" in x)
check(churn <= 80, f"diff de codigo acotado ({churn} lineas: ediciones quirurgicas, sin reescrituras)")

print("== F) ANTI-CHEAT (cero superficie nueva) ==")
diff = subprocess.run(["git", "diff", "-U0", "--", "objects/"], cwd=REPO, capture_output=True, text=True).stdout
added = [l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++")]
code_added = [l for l in added if not l.strip().startswith("//")]
bad_net = [l for l in code_added if re.search(r"buffer_(write|seek|read)|send_|udp_|tcp_|socket|bitflags\s*\|=", l)]
check(not bad_net, f"lineas de codigo nuevas sin red ni bitflags ({bad_net or 'cero'})")
logic_added = [l for l in code_added if not re.search(r"state|isAttacking|eShieldTimer|draw_sprite|image_speed|ROUGE_ESHIELD", l)]
check(not logic_added, f"toda linea nueva es de estado/aura/animacion ({logic_added or 'cero desvios'})")
# el chispazo sigue aplicandolo el cliente de la VICTIMA (autoridad de siempre)
check("net_quick_effect(global.player.x, global.player.y, spr_shockparticle)" in ps,
      "el stun electrico lo aplica el cliente de la victima (patron de autoridad intacto)")

print()
print(f"RESULTADO: {PASS} OK / {FAIL} FALLOS")
sys.exit(1 if FAIL else 0)
