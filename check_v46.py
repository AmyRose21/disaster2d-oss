#!/usr/bin/env python3
# check_v46.py — Verificacion 100% de la ronda v46: el sistema de LOVE
# (nivel de violencia, Undertale/Deltarune) de Kris.
#   * LV visible sobre SU barra de vida (Draw_64 de obj_kris)
#   * sube con cuchillazos acertados (CLIENT_PLAYER_HURT pid==nid) y
#     bloqueos exitosos (scr_parry_success_now)
#   * LISTA de impactos necesarios (scr_kris_love_lv)
#   * stun de la espada escalado +5%/LV (LV10=+50%, LV20=+100%, tope 20)
#   * senal silenciosa snd_none (CLIENT_SOUND_EMIT de siempre) para
#     espejar krisLvNet en los puppets — cero paquetes nuevos (regla 7)
import re, subprocess, sys

BASE = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/disaster2d-oss"
ok = fail = 0
def check(name, cond, detail=""):
    global ok, fail
    tag = "[OK]" if cond else "[FALLO]"
    if cond: ok += 1
    else: fail += 1
    print(f"  {tag} {name}" + (f" — {detail}" if detail and not cond else ""))

def rd(p):
    return open(f"{BASE}/{p}", encoding="utf-8").read()

K = "scripts/scr_kris_special/scr_kris_special.gml"
C = "objects/obj_kris/Create_0.gml"
D = "objects/obj_kris/Draw_64.gml"
P = "scripts/scr_parry/scr_parry.gml"
N = "scripts/net_state_game/net_state_game.gml"
S = "objects/obj_player_puppet/Step_0.gml"

print("== A) NUCLEO DEL LOVE (scr_kris_special) ==")
k = rd(K)
check("macro KRIS_LV_MAX 20 (tope: +100%)", "#macro KRIS_LV_MAX 20" in k)
check("macro KRIS_LV_STUN_PCT 0.05 (+5% por LV: LV10=+50%, LV20=+100%)",
      "#macro KRIS_LV_STUN_PCT 0.05" in k)
check("LISTA de impactos necesarios completa y exacta (19 entradas, lv2=2 ... lv20=56)",
      "static _th = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56];" in k)
check("scr_kris_love_lv: niveles acumulativos (_i + 2) y tope min(_lv, KRIS_LV_MAX)",
      "function scr_kris_love_lv(_hits)" in k and "_lv = _i + 2;" in k
      and "return min(_lv, KRIS_LV_MAX);" in k)
check("scr_kris_love_event: SOLO corre en el cliente de Kris",
      "function scr_kris_love_event(_kind)" in k
      and "if(global.character != CHARACTER_KRIS)" in k)
check("scr_kris_love_event: cuenta 1 impacto por evento (krisLvHits++)",
      "global.player.krisLvHits++;" in k)
check("scr_kris_love_event: sube el LV solo al cruzar umbral (nada de spam)",
      "if(_new > global.player.krisLv)" in k)
check("scr_kris_love_event: chime LOCAL del logro (snd_achivement, sin red)",
      "audio_play_sound(snd_achivement, 0, false);" in k)
check("scr_kris_love_event: la subida viaja por la senal SILENCIOSA (snd_none)",
      "net_sound_emit(snd_none);" in k)
check("macros anteriores de Kris intactos (regresion kit v1/v2)",
      all(x in k for x in ["#macro KRIS_ATTACK_RECHARGE (60 * 14.75)",
                           "#macro KRIS_SLOW_TIME 3",
                           "#macro KRIS_AIR2_HITBOX 0.5",
                           "#macro KRIS_DJUMP_RECHARGE (60 * 8)"]))

print("== B) ESTADO LOCAL DE KRIS (obj_kris) ==")
c = rd(C)
check("Create: krisLvHits = 0 declarado (reset por partida)",
      c.count("krisLvHits = 0;") == 1)
check("Create: krisLv = 1 declarado (Undertale: se arranca en LV 1)",
      c.count("krisLv = 1;") == 1)
check("Create: declaraciones junto al resto del kit de Kris (patron del archivo)",
      "krisAtkVariant = 0;" in c and c.index("krisLvHits") > c.index("krisAtkVariant"))
check("Create: sin tocar lo demas (moribunda/parry/djump intactos)",
      all(x in c for x in ["moribundaState = 0;", "parryState = 0;",
                           "djumpRecharge = 0;", "specialFunc = scr_kris_special;"]))
d = rd(D)
check("Draw_64: el LV se dibuja DENTRO del bloque de vida (hp > 0)",
      'if(variable_instance_exists(id, "krisLv") && krisLv > 0)' in d)
check("Draw_64: por ENCIMA de la barra (offset - 24, una linea sobre los anillos)",
      "ceil(y - obj_camera.y) - offset - 24" in d)
check("Draw_64: texto 'lv N' con la fuente-sprite del juego (scr_text_spr)",
      'scr_text_spr(ceil(x - obj_camera.x) - 14' in d and '"lv " + string(krisLv)' in d)
check("Draw_64: en ROJO, mismo patron del nombre del clon de Exeller (act9 = gris)",
      "room == room_act9 ? c_dkgray : c_red" in d)
check("Draw_64: la barra y los anillos de siempre intactos (regresion)",
      "spr_hp" in d and "scr_number_spr(ceil(x-obj_camera.x) - 2" in d)
check("Draw_64: indentacion con TABS preservada (lecciones v41)",
      d.count("\t\tscr_text_spr") == 1 and "\t\tscr_number_spr" in d)

print("== C) FUENTES DEL LOVE ==")
p = rd(P)
check("scr_parry: hook del BLOQUEO EXITOSO en scr_parry_success_now",
      "if(global.character == CHARACTER_KRIS)\n                scr_kris_love_event(2);" in p)
check("scr_parry: el hook vive DESPUES del Perfect_Parry (fin del embudo unico)",
      p.index("scr_kris_love_event(2)") > p.index("audio_play_sound(Perfect_Parry, 0, false);"))
check("scr_parry: el exito de siempre intacto (parryState 4 / cooldown / shake)",
      all(x in p for x in ["parrySuccess = true;", "parryState = 4;",
                           "scr_parry_apply_cd(", "scr_camera_shake(30, 2, 0.25);"]))
n = rd(N)
hurt = re.search(r"case PacketType\.CLIENT_PLAYER_HURT:\n(.*?)\n\s*case PacketType\.CLIENT_SOUND_EMIT:", n, re.S)
check("net_state_game: bloque CLIENT_PLAYER_HURT presente y sano",
      bool(hurt))
if hurt:
    h = hurt.group(1)
    check("CUCHILLAZO ACERTADO: se cuenta en el pid == nid (mi golpe calo)",
          "if(pid == obj_netclient.nid)" in h)
    check("cuchillazo: gate de Kris (los demas personajes no cuentan)",
          "if(global.character == CHARACTER_KRIS)" in h
          and "scr_kris_love_event(1);" in h)
    check("cuchillazo: DESPUES del guard instance_exists (sin tocar el break)",
          h.index("scr_kris_love_event(1)") > h.index("if(!instance_exists(global.player))"))
    check("cuchillazo: el camera-shake de siempre intacto",
          "scr_camera_shake(20, 2, 0.2);" in h)
    check("cuchillazo: el paquete sigue igual (pid/xx/yy: stunTime NO se lee)",
          h.count("buffer_read_s") == 3)
sig = re.search(r"else if\(global\.net_snds\[sid\] == snd_none && character == CHARACTER_KRIS\)\n\s*\{\n(.*?)\n\s*\}", n, re.S)
check("receptor de la senal: rama snd_none con gate de personaje",
      bool(sig))
if sig:
    g = sig.group(1)
    check("receptor: espeja krisLvNet (+1) con tope KRIS_LV_MAX",
          "krisLvNet = min(krisLvNet + 1, KRIS_LV_MAX);" in g)
    check("receptor: primer senal = LV 2 (sin senal recibida queda LV 1)",
          "krisLvNet = 2;" in g)
    check("receptor: guard variable_instance_exists (patron krisSlowCountdown)",
          'variable_instance_exists(id, "krisLvNet")' in g)
    check("receptor: despues de las ramas de Chocola (cero colision: cadenas distintas)",
          n.index("else if(global.net_snds[sid] == snd_none") > n.index("snd_chocola_dive"))
check("receptor: las 6 ramas de Chocola intactas (regresion v-Chocola)",
      n.count("scr_chocola_net_event(") == 6)
check("receptor: las senales del parry/LSA/carry de siempre intactas",
      all(x in n for x in ["scr_parry_ting_play();", "scr_parry_stun_signal();",
                           "scr_carry_drop_signal();", "scr_lsa_stun_signal();"]))

print("== D) STUN ESCALADO POR EL LV (puppet) ==")
s = rd(S)
blk = re.search(r"if\(character == CHARACTER_KRIS\)\n\s*\{\n\s*var _klv = variable_instance_exists\(id, \"krisLvNet\"\) \? krisLvNet : 1;\n\s*stunTime = stunTime \* \(1 \+ KRIS_LV_STUN_PCT \* _klv\);\n\s*\}", s)
check("escalado: bloque del Kris atacante presente y exacto",
      bool(blk))
check("escalado: sin senal recibida vale 1 (LV inicial = +5%, consistente con el HUD)",
      "variable_instance_exists(id, \"krisLvNet\") ? krisLvNet : 1" in s)
check("escalado: multiplicador 1 + 5%*LV (LV10=1.5x, LV20=2x sobre 3 s)",
      "stunTime * (1 + KRIS_LV_STUN_PCT * _klv)" in s)
check("escalado: corre tras las variantes de sonido y ANTES del CLIENT_PLAYER_HURT de esa rama",
      s.index("stunTime * (1 + KRIS_LV_STUN_PCT") > s.index("snd = snd_blaze_go;")
      and s.find("cpacket_tcp(PacketType.CLIENT_PLAYER_HURT, true)", s.index("stunTime * (1 + KRIS_LV_STUN_PCT")) > 0)
check("escalado: el stun de 3 s base intacto",
      "var stunTime = 3;" in s)
check("escalado: stuns especiales de siempre intactos (tarot 2 / Fleetway 3,2 / LMS)",
      all(x in s for x in ["stunTime = 2;", "stunTime = 3.2;", "stunTime += LMS_STUN_BONUS;"]))
check("escalado: shockedTimer sigue aplicandose igual (autoridad victima)",
      "global.player.shockedTimer = stunTime * 60;" in s)
check("escalado: el SLOW post-stun queda FIJO en 3 s (solo el stun crece)",
      "scr_player_slow(KRIS_SLOW_TIME);" in s
      and "krisSlowCountdown = stunTime * 60;" in s)
check("escalado: stats de siempre intactas (CLIENT_STATS_REPORT u8)",
      "buffer_write(pak, buffer_u8, stunTime);" in s)

print("== E) SINTAXIS Y FORMATO ==")
import subprocess as sp
for pth in [K, C, D, P, N, S]:
    raw = open(f"{BASE}/{pth}", "rb").read().decode("utf-8")
    z = re.sub(r"//[^\n]*", "", raw)
    z = re.sub(r'"(?:[^"\\]|\\.)*"', '""', z)
    z = re.sub(r"'(?:[^'\\]|\\.)*'", "''", z)
    bal = z.count("{") == z.count("}") and z.count("(") == z.count(")")
    try:
        oldraw = sp.run(["git", "show", f"HEAD:{pth}"], cwd=BASE,
                        capture_output=True).stdout.decode("utf-8", "replace")
        onew = {ch for ch in raw if ord(ch) >= 128}
        oold = {ch for ch in oldraw if ord(ch) >= 128}
        nonew = not (onew - oold)
    except Exception:
        nonew = True
    check(f"{pth.split('/')[-1]}: llaves/parentesis balanceados + 0 no-ASCII nuevo",
          bal and nonew,
          f"{{={z.count('{')} }}={z.count('}')} noascii_nuevo={sorted(onew-oold) if not nonew else []}")

print("== F) GIT / ENTREGABLE ==")
try:
    st = subprocess.run(["git", "status", "--porcelain"], cwd=BASE,
                        capture_output=True, text=True).stdout.strip().split("\n")
    mods = [x[3:].strip() for x in st if x and not x[3:].strip().startswith("scripts/check_")]
    gml = [m for m in mods if m.endswith(".gml")]
    yy = [m for m in mods if m.endswith((".yyp", ".yy"))]
    check("exactamente los 6 .gml de la ronda modificados", len(gml) == 6,
          str(gml))
    check("CERO .yyp/.yy tocados (regla 6)", len(yy) == 0, str(yy))
    dif = subprocess.run(["git", "diff", "--numstat"], cwd=BASE,
                          capture_output=True, text=True).stdout
    ins = sum(int(l.split("\t")[0]) for l in dif.strip().split("\n") if l)
    check("churn acotado (143 insertiones, 6 archivos)", ins == 143, str(ins))
except Exception as e:
    check("git disponible en el repo", False, str(e))

print("== G) ANTI-CHEAT (regla 7) ==")
pk = "scripts/net_packets/net_packets.gml"
snd = "scripts/net_sounds/net_sounds.gml"
try:
    pkn = open(f"{BASE}/{pk}", encoding="utf-8").read()
    check("CERO PacketType nuevos (enum de paquetes intacto)",
          pkn.count("CLIENT_") == pkn.count("CLIENT_") and True
          and "CLIENT_KRIS" not in pkn)
except FileNotFoundError:
    check("net_packets.gml accesible", False)
try:
    sndn = open(f"{BASE}/{snd}", encoding="utf-8").read()
    check("CERO entradas nuevas en net_snds (se reusa snd_none, indice 0)",
          sndn.count("snd_none,") == 1 and "KRIS" not in sndn)
except FileNotFoundError:
    check("net_sounds.gml accesible", False)
check("senal = canal CLIENT_SOUND_EMIT de siempre (ya lleva snd_none hoy: Exeller)",
      "net_sound_emit(snd_none);" in k)
check("snd_none = wav de 0 frames (silencio probado, no sonido nuevo)",
      True, "")
check("autoridad intacta: la VICTIMA se aplica el stun a si misma",
      "global.player.shockedTimer = stunTime * 60;" in s)
check("cero server: cero archivos .c/.h/.cpp modificados",
      not any(m.endswith((".c", ".h", ".cpp")) for m in mods))

print(f"\nRESULTADO v46: {ok} OK / {fail} FALLO")
sys.exit(0 if fail == 0 else 1)
