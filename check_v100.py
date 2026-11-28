#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v100.py — v100 (EL BLOQUEO SIEMPRE CUENTA). Bug report de la duena:
#  «hay ocasiones que el golpe hace daño a Kris a pesar de que este bloquee;
#   aun bloqueado el ataque, el enemigo a veces no recibe el stun o lo
#   recibe pero no da Love (el pool del LV 20), o simplemente recibe daño y
#   no bloquea ni stunea; pasa con Amy y con Sonic — con Sonic en su momento
#   ni stuneaba, solo negaba».
#  TRES causas raiz encontradas y arregladas (todo GML cliente, cero server):
#   F1 (niega-sin-stun): LA SENAL DE STUN vivia DENTRO del throttle de 200ms
#       de los FX de la negacion -> un 2.o ataque negado en esa ventana
#       quedaba SIN senal, y el camino del propio atacante "casi nunca caza
#       el contacto". Ahora la senal sale SIEMPRE (TCP + dedup del receptor).
#   F2 (stun-sin-Love): el golpe al pool SOLO ocurria si el stun se aplicaba
#       de verdad: (a) el exe ya stuneado (un deflect devuelto) -> dedup ->
#       sin pool; (b) el gate del espejo krisLvNet del ATACANTE atrasado unos
#       frames tras la subida a LV 20. Ahora el pool cae IGUAL en el bloqueo
#       (gates con ringOff de respaldo) + throttle interno de 250ms.
#   F3 (bloquea-pero-dana): el tap de C/V durante isAttacking/isSpinCharging
#       /bounceTimer se PERDIA entero (solo el aire tenia buffer). Ahora el
#       tap vive SONIC_PARRY_LAND_BUFFER frames y el parry arranca cuando el
#       estado transitorio se despeja (gates duros re-evaluados).
#  + llaves balanceadas, v98b/c/d + v99 intactos, tweak de la duena intacto.
# ============================================================================
import subprocess, sys, os, re

REPO = os.path.dirname(os.path.abspath(__file__))
os.chdir(REPO)

OK = 0
FAIL = 0
def chk(name, cond, extra=""):
    global OK, FAIL
    if cond:
        OK += 1
        print(f"  [OK]   {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name} {extra}")

def rd(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

# ---------------------------------------------------------------------------
print("=== 1. ARCHIVOS TOCADOS (v100: 3 de juego + 21 del v99 pendiente + docs) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
untracked = sorted([l[2:].strip() for l in lines if l[:2] == "??"])
V100_MOD = sorted([
    # v100 (3): los fixes del bloqueo
    "scripts/scr_parry/scr_parry.gml",
    "scripts/scr_kris_special/scr_kris_special.gml",
    "objects/obj_player_puppet/Step_0.gml",
    # v99 pendiente (17): atribucion + deflects + daños + barra + bat
    "betterserver-oss/compilar_server.bat",
    "betterserver-oss/disasterserver/entities/BlazeFireball.c",
    "betterserver-oss/disasterserver/entities/MetalAmyBullet.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "objects/obj_blaze_fireball/Create_0.gml",
    "objects/obj_blaze_fireball/Step_0.gml",
    "objects/obj_fw_bolt/Create_0.gml",
    "objects/obj_fw_bolt/Step_0.gml",
    "objects/obj_metal_amy_bullet/Create_0.gml",
    "objects/obj_metal_amy_bullet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    # docs + checks parcheados
    "worklog.md", "CACHE.md", "LEARNING.md",
    "check_v98b.py", "check_v98c.py", "check_v98d.py",
])
V100_UNTRACKED = sorted([
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
    "check_v100.py", "LEEME_V100_EL_BLOQUEO_CUENTA.txt",
])
# v101 (duena: «el bloqueo debe castigar ataques terminados»): mismo
# vuelo de mods (scr_parry ya estaba modificado) + los 2 del v101.
V101_UNTRACKED = sorted(V100_UNTRACKED + [
    "check_v101.py", "LEEME_V101_CASTIGO_AUN_CON_LAG.txt",
])
chk("modificados = 24 (1 nuevo del v100 + 17 de juego del v99 + 3 docs + 3 checks), ni uno mas",
    mod_files == V100_MOD, f"real: {mod_files}")
chk("nuevos sin trackear: checks + LEEMEs del v99/v100 (4) o vuelo v101 (6)",
    untracked in (V100_UNTRACKED, V101_UNTRACKED), f"real: {untracked}")
chk("cero .yy/.yyp tocados", not any(f.endswith((".yy", ".yyp")) for f in mod_files))
chk("KAF INTACTO: ni el monitor ni KindAndFair.c en la lista",
    "kaf" not in st.lower() and "KindAndFair" not in st)
chk("tweak de la duena INTACTO: KRIS_LV_XP_NORMAL sigue en 3",
    re.search(r"#macro KRIS_LV_XP_NORMAL 3\b", rd("scripts/scr_kris_special/scr_kris_special.gml")) is not None)

parry = rd("scripts/scr_parry/scr_parry.gml")
ksp = rd("scripts/scr_kris_special/scr_kris_special.gml")
pupst = rd("objects/obj_player_puppet/Step_0.gml")
hurt = rd("scripts/scr_player_hurt/scr_player_hurt.gml")

# ---------------------------------------------------------------------------
print("=== 2. F1 — LA SENAL DE STUN SALE SIEMPRE (fuera del throttle de FX) ===")
m = re.search(r"function scr_parry_negate_hit[\s\S]*?\n\}", parry)
nh = m.group(0) if m else ""
chk("scr_parry_negate_hit existe", m is not None)
chk("las 2 senales de stun (melee + spin) van ANTES del bloque _fxLast",
    nh.find("net_sound_emit_at(snd_exe_stun, master_id);") < nh.find("static _fxLast")
    and nh.count("net_sound_emit_at(snd_exe_stun, master_id);") == 2
    and nh.find("net_sound_emit_at(snd_exe_stun, master_id);", nh.find("net_sound_emit_at(snd_exe_stun, master_id);") + 10) < nh.find("static _fxLast"))
chk("el throttle de 200 ms queda SOLO para cosmeticos (ting + FX + shake)",
    re.search(r"static _fxLast[\s\S]*?net_sound_emit_at\(snd_parry, _nid\);[\s\S]*?net_quick_effect[\s\S]*?scr_camera_shake[\s\S]*?_fxLast = current_time;", nh) is not None)
chk("el receptor sigue deduplicando el stun (shockedTimer en stun_signal)",
    "if(global.player.shockedTimer > 0)" in parry)

# ---------------------------------------------------------------------------
print("=== 3. F3 — BUFFER GENERAL DEL TAP (bloquea-pero-dana) ===")
m2 = re.search(r"var _hardOk = \(global\.playerControls[\s\S]*?parryLandBuffer = 0;\n\s*\}", parry)
chk("el gate duro vive en _hardOk (sin isAttacking/isSpinCharging/bounceTimer dentro)",
    m2 is not None and "isAttacking" not in m2.group(0).split("parryLandBuffer = SONIC_PARRY_LAND_BUFFER")[0].split("_hardOk && parryLandBuffer")[0])
chk("el tap se guarda SIEMPRE que los duros pasen (no solo en el aire)",
    re.search(r"if\(_hardOk && keyboard_check_pressed\(scr_parry_key\(\)\)\)\n\s*parryLandBuffer = SONIC_PARRY_LAND_BUFFER;", parry) is not None)
chk("el arranque exige los transitorios despejados (tierra + sin ataque/spin/rebote)",
    re.search(r"if\(_hardOk && parryLandBuffer > 0\n\s*&& isGrounded && !isAttacking && !isSpinCharging && bounceTimer <= 0\)", parry) is not None)
chk("los gates duros de siempre siguen duros (dead/hurt/stun/CD/demonizado/nervios)",
    all(s in parry for s in ["!isHurt && !isDead && shockedTimer <= 0", "parryCooldown <= 0", "revivalTimes < 2", "nerviosState == 0"]))

# ---------------------------------------------------------------------------
print("=== 4. F2 — EL BLOQUEO SIEMPRE DA EL GOLPE AL POOL ===")
m3 = re.search(r"function scr_parry_try_stun_attacker[\s\S]*?\n\}", parry)
tsa = m3.group(0) if m3 else ""
chk("try_stun_attacker: el dedup baja al pool si el que cubre es Kris a LV 20",
    re.search(r"if\(global\.player\.shockedTimer > 0\)\s*\{\s*\n\s*if\(_parrySonic\.character == CHARACTER_KRIS[\s\S]*?scr_kris_exe_pool_hit\(0\);", tsa) is not None)
chk("try_stun_attacker: el dedup SIGUE sin re-aplicar el stun (return false)",
    re.search(r"scr_kris_exe_pool_hit\(0\);\s*\n\s*return false;", tsa) is not None)
m4 = re.search(r"function scr_parry_stun_signal[\s\S]*?\n\}", parry)
sig = m4.group(0) if m4 else ""
# v101 (duena: «el bloqueo debe castigar ataques terminados»): el gate
# v3.0 se RETIRA — los asserts de abajo se adaptan al vuelo.
_v101 = os.path.exists("LEEME_V101_CASTIGO_AUN_CON_LAG.txt")
_primerBlando = ("if(!(global.player.isAttacking" if not _v101
                 else "if(global.player.shockedTimer > 0)")
chk("stun_signal: la busqueda de la victima SUBIO antes de los gates blandos",
    sig.find("_victimChar = character;") < sig.find(_primerBlando))
chk("stun_signal: el golpe al pool va ANTES de los gates blandos (ataque cerrado / ya stuneado)",
    sig.find("scr_kris_exe_pool_hit(0);") < sig.find(_primerBlando)
    and sig.find("scr_kris_exe_pool_hit(0);") < sig.rfind("if(global.player.shockedTimer > 0)"))
chk("stun_signal: el pool gated a victima Kris + exe real + pool_ready",
    re.search(r"if\(_victimChar == CHARACTER_KRIS\s*\n\s*&& global\.character == CHARACTER_EXE\s*\n\s*&& scr_kris_exe_pool_ready\(\)\)", sig) is not None)
_gate_v30 = "if(!(global.player.isAttacking || global.player.isJumping || global.player.isSpinning))" in sig
chk("gate v3.0 del stun: presente (vuelo v100) o retirado por pedido de la duena (v101)",
    _gate_v30 != _v101)
chk("apply_stun: el gate del pool gana ringOff de respaldo (TCP)",
    "(_klvP >= KRIS_LV_MAX || global.ringOff))" in parry)
chk("espada (puppet Step_0): el mismo OR ringOff en su gate",
    "(global.ringOff || (variable_instance_exists(id, \"krisLvNet\") ? krisLvNet : 1) >= KRIS_LV_MAX)" in pupst)
chk("pool_hit: dedup interno de 250 ms (una sola resta por bloqueo)",
    re.search(r"function scr_kris_exe_pool_hit[\s\S]*?static _lastHit = -9999;[\s\S]*?if\(current_time - _lastHit < 250\)[\s\S]*?_lastHit = current_time;", ksp) is not None)
chk("helper nuevo scr_kris_exe_pool_ready (ringOff o espejo krisLvNet >= 20)",
    re.search(r"function scr_kris_exe_pool_ready\(\)[\s\S]*?if\(global\.ringOff\)[\s\S]*?krisLvNet : 1\) >= KRIS_LV_MAX", ksp) is not None)
chk("el pool SIGUE sin tocar a esbirros (global.character == CHARACTER_EXE en los gates)",
    tsa.count("global.character == CHARACTER_EXE") >= 1 and sig.count("global.character == CHARACTER_EXE") >= 1)

# ---------------------------------------------------------------------------
print("=== 5. LO DEMAS SIGUE INTACTO ===")
chk("v99: los deflects siguen (trio de paquetes en scr_parry)",
    all(s in parry for s in ["PacketType.CLIENT_METALAMY_BULLET_DEFLECT", "PacketType.CLIENT_FWBOLT_DEFLECT", "PacketType.CLIENT_BLAZE_FIREBALL_DEFLECT"]))
chk("v99: la negacion sigue cubriendo exeSource antes del guard de hurttime",
    "if(exeSource && (damage > 0 || sndid == snd_buble) && scr_parry_negate_hit())" in hurt)
chk("v99: los daños por asesino siguen (Exetior 50 / normal 45 / Exeller 40 / Chaos 35 / Metal Amy 30 / Jinna 45)",
    all(re.search(r"case " + mm + r":\s*\n\s*damage = " + vv + ";", pupst) for mm, vv in
        [("EXE_EXETIOR", "50"), ("EXE_ORIGINAL", "45"), ("EXE_EXELLER", "40"), ("EXE_CHAOS", "35"), ("EXE_METALAMY", "30"), ("EXE_JINNA", "45")]))
chk("v99: el escudo de Kris sigue bloqueando los proyectiles nuevos (los 3 bloques frontales)",
    parry.count("scr_kris_block_front(_me, self)") >= 4)  # laser + 3 nuevos
chk("el bloqueo direccional del escudo queda INTACTO (KRIS_BLOCK_VISION -8)",
    "return _dx * _face >= KRIS_BLOCK_VISION;" in ksp)
chk("v98d: el zap del escudo electrico sigue con atribucion exacta",
    re.search(r"if\(attackerNid >= 0\)\s*\n\s*_zapNid = attackerNid;", hurt) is not None)
chk("checks viejos parcheados: reconocen el vuelo del v100",
    "V100_MOD" in rd("check_v99.py"))

# ---------------------------------------------------------------------------
print("=== 6. LLAVES BALANCEADAS (GML tocados) ===")
for f in ["scripts/scr_parry/scr_parry.gml", "scripts/scr_kris_special/scr_kris_special.gml",
          "objects/obj_player_puppet/Step_0.gml"]:
    txt = rd(f)
    txt2 = re.sub(r'"(?:[^"\\]|\\.)*"', '""', txt)
    txt2 = re.sub(r"//[^\n]*", "", txt2)
    txt2 = re.sub(r"/\*.*?\*/", "", txt2, flags=re.S)
    chk(f"{f}: llaves y parens balanceadas",
        txt2.count("{") == txt2.count("}") and txt2.count("(") == txt2.count(")"))

print()
print(f"RESULTADO: {OK} OK, {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
