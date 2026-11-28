#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v101.py — v101 (CASTIGO AUN CON LAG). Pedido de la duena:
#  «el bloqueo debe castigar ataques terminados. Porque estoy seguro que
#   si el jugador tiene demasiado lag entonces, ejemplo, el termina el
#   ataque antes de que el server se entere, entonces como termino en su
#   cliente entonces el juego no lo cuenta.»
#  CAMBIO: se RETIRA el gate v3.0 de scr_parry_stun_signal (solo castigar
#  ataques ACTIVOS en la pantalla del atacante). Ese gate regalaba
#  inmunidad por lag al atacante: la negacion ocurrio de verdad en el
#  cliente de la VICTIMA (la autoridad del golpe, patron de todo el
#  juego) y su senal viaja por TCP — si el ataque termino en la pantalla
#  del atacante antes de que la senal llegue, ES el caso a castigar.
#  El golpe al pool ya contaba igual desde el v100; ahora el stun aplica
#  siempre. El dedup (shockedTimer) queda: no se re-aplica un stun nuevo
#  por cada senal repetida del MISMO bloqueo.
#  + todo el v100/v99/v98 intacto, tweak de la duena intacto, llaves.
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
print("=== 1. ARCHIVOS TOCADOS (v101: mismo vuelo del v100 + check/LEEME) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
untracked = sorted([l[2:].strip() for l in lines if l[:2] == "??"])
V101_MOD = sorted([
    # juego (18): v99 + v100
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
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_kris_special/scr_kris_special.gml",
    "scripts/scr_parry/scr_parry.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    # docs + checks
    "worklog.md", "CACHE.md", "LEARNING.md",
    "check_v98b.py", "check_v98c.py", "check_v98d.py",
])
V101_UNTRACKED = sorted([
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
    "check_v100.py", "LEEME_V100_EL_BLOQUEO_CUENTA.txt",
    "check_v101.py", "LEEME_V101_CASTIGO_AUN_CON_LAG.txt",
])
chk("modificados = 24 (18 de juego + 3 docs + 3 checks), ni uno mas",
    mod_files == V101_MOD, f"real: {mod_files}")
chk("nuevos sin trackear: checks + LEEMEs del v99/v100/v101 (6)",
    untracked == V101_UNTRACKED, f"real: {untracked}")
chk("cero .yy/.yyp tocados", not any(f.endswith((".yy", ".yyp")) for f in mod_files))
chk("KAF INTACTO: ni el monitor ni KindAndFair.c en la lista",
    "kaf" not in st.lower() and "KindAndFair" not in st)
chk("tweak de la duena INTACTO: KRIS_LV_XP_NORMAL sigue en 3",
    re.search(r"#macro KRIS_LV_XP_NORMAL 3\b", rd("scripts/scr_kris_special/scr_kris_special.gml")) is not None)

parry = rd("scripts/scr_parry/scr_parry.gml")
ksp = rd("scripts/scr_kris_special/scr_kris_special.gml")
pupst = rd("objects/obj_player_puppet/Step_0.gml")
hurt = rd("scripts/scr_player_hurt/scr_player_hurt.gml")

m = re.search(r"function scr_parry_stun_signal[\s\S]*?\n\}", parry)
sig = m.group(0) if m else ""

# ---------------------------------------------------------------------------
print("=== 2. EL CAMBIO v101 — CASTIGO AUN CON EL ATAQUE TERMINADO ===")
chk("scr_parry_stun_signal existe", m is not None)
chk("EL GATE v3.0 ESTA RETIRADO (ya no exige isAttacking/isJumping/isSpinning)",
    "if(!(global.player.isAttacking" not in sig,
    "(el gate seguia ahi)")
chk("el comentario del pedido de la duena queda documentado en el gate",
    "el bloqueo debe castigar ataques terminados" in sig)
chk("EL DEDUP SIGUE: no se re-aplica un stun por cada senal repetida del mismo bloqueo",
    "if(global.player.shockedTimer > 0)" in sig
    and sig.find("if(global.player.shockedTimer > 0)") < sig.find("scr_parry_apply_stun("))
chk("EL STUN SIGUE APLICANDOSE AL FINAL (apply_stun con la victima)",
    sig.rstrip().endswith("scr_parry_apply_stun(_victimNid, -global.player.image_xscale * 4, false, _victimChar);\n}"))
chk("los gates duros siguen: exe/esbirro + vivo",
    "global.character != CHARACTER_EXE && global.player.revivalTimes < 2" in sig
    and "if(global.player.isDead)" in sig)
chk("el golpe al pool SIGUE antes de todo lo demas (v100 intacto)",
    sig.find("scr_kris_exe_pool_hit(0);") < sig.find("if(global.player.shockedTimer > 0)")
    and "scr_kris_exe_pool_ready()" in sig)

# ---------------------------------------------------------------------------
print("=== 3. v100 INTACTO (el bloqueo siempre cuenta) ===")
m1 = re.search(r"function scr_parry_negate_hit[\s\S]*?\n\}", parry)
nh = m1.group(0) if m1 else ""
chk("negate_hit: las senales de stun siguen ANTES del throttle de FX (fuera)",
    nh.find("net_sound_emit_at(snd_exe_stun, master_id);") < nh.find("static _fxLast")
    and nh.count("net_sound_emit_at(snd_exe_stun, master_id);") == 2)
m2 = re.search(r"var _hardOk = \(global\.playerControls[\s\S]*?parryLandBuffer = 0;\n\s*\}", parry)
chk("buffer general del tap (bloquea-pero-dana) sigue",
    m2 is not None and re.search(r"if\(_hardOk && keyboard_check_pressed\(scr_parry_key\(\)\)\)", parry) is not None)
m3 = re.search(r"function scr_parry_try_stun_attacker[\s\S]*?\n\}", parry)
tsa = m3.group(0) if m3 else ""
chk("try_stun_attacker: el dedup baja al pool si el que cubre es Kris",
    re.search(r"if\(global\.player\.shockedTimer > 0\)\s*\{\s*\n\s*if\(_parrySonic\.character == CHARACTER_KRIS[\s\S]*?scr_kris_exe_pool_hit\(0\);", tsa) is not None)
chk("pool_hit: throttle interno de 250 ms sigue",
    re.search(r"static _lastHit = -9999;[\s\S]*?if\(current_time - _lastHit < 250\)", ksp) is not None)
chk("helper scr_kris_exe_pool_ready sigue (ringOff o espejo >= 20)",
    re.search(r"function scr_kris_exe_pool_ready\(\)[\s\S]*?if\(global\.ringOff\)", ksp) is not None)
chk("apply_stun: gate del pool con ringOff de respaldo sigue",
    "(_klvP >= KRIS_LV_MAX || global.ringOff))" in parry)
chk("espada (puppet Step_0): OR ringOff en su gate sigue",
    "(global.ringOff || (variable_instance_exists(id, \"krisLvNet\") ? krisLvNet : 1) >= KRIS_LV_MAX)" in pupst)

# ---------------------------------------------------------------------------
print("=== 4. v99 / v98 / REGLAS INTACTAS ===")
chk("v99: los deflects siguen (trio de paquetes en scr_parry)",
    all(s in parry for s in ["PacketType.CLIENT_METALAMY_BULLET_DEFLECT", "PacketType.CLIENT_FWBOLT_DEFLECT", "PacketType.CLIENT_BLAZE_FIREBALL_DEFLECT"]))
chk("v99: la negacion sigue cubriendo exeSource antes del guard de hurttime",
    "if(exeSource && (damage > 0 || sndid == snd_buble) && scr_parry_negate_hit())" in hurt)
chk("v99: daños por asesino siguen (Exetior 50 / normal 45 / Exeller 40 / Chaos 35 / Metal Amy 30 / Jinna 45)",
    all(re.search(r"case " + mm + r":\s*\n\s*damage = " + vv + ";", pupst) for mm, vv in
        [("EXE_EXETIOR", "50"), ("EXE_ORIGINAL", "45"), ("EXE_EXELLER", "40"), ("EXE_CHAOS", "35"), ("EXE_METALAMY", "30"), ("EXE_JINNA", "45")]))
chk("el escudo sigue siendo DIRECCIONAL (KRIS_BLOCK_VISION -8)",
    "return _dx * _face >= KRIS_BLOCK_VISION;" in ksp)
chk("el parry sigue solo en tierra (isGrounded en el arranque del buffer)",
    "&& isGrounded && !isAttacking && !isSpinCharging && bounceTimer <= 0)" in parry)
chk("checks viejos parcheados: reconocen el vuelo del v101",
    all("check_v101.py" in rd(f) for f in ["check_v99.py", "check_v98b.py", "check_v98c.py", "check_v98d.py"])
    and "_v101" in rd("check_v100.py"))

# ---------------------------------------------------------------------------
print("=== 5. LLAVES BALANCEADAS (GML tocados) ===")
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
