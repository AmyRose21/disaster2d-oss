#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v98c.py — v98c (FIX DEL CRASH DEL ESCUDO ELECTRICO). Reporte
#  literal de la duena (runner del juego):
#    ERROR in action number 1 of Step Event0 for object
#    obj_tails_projectile:
#    Variable obj_player_puppet.isJumping(100191, -2147483648) not set
#    before reading it. at gml_Script_scr_player_hurt
#    gml_Script_scr_player_hurt (line -1)
#    gml_Object_obj_tails_projectile_Step_0
#
#  CAUSA RAIZ (bug v92 PREEXISTENTE — v98b NO lo causo, sus 13 archivos
#  no tocan ni scr_player_hurt ni obj_player_puppet): al romperse el
#  escudo electrico de la caja, scr_player_hurt busca al atacante por
#  "ataque activo en CUALQUIER forma" — _pp.isAttacking || _pp.isJumping
#  || _pp.isSpinning — sobre TODOS los puppets del room. isAttacking,
#  isDead, isHiding e isInactive tienen default defensivo en el Create
#  del puppet (patron documentado v76/v2.1.1), pero isJumping e
#  isSpinning NUNCA se inicializaron alli (ni viajan por red): el
#  primer puppet NO-atacando hace reventar la lectura. (Si isAttacking
#  fuera true el || corta antes de leer isJumping — por eso el crash
#  nombra isJumping y no isAttacking: solo revienta con un puppet
#  no-atacando en el room.)
#
#  FIX: defaults defensivos isJumping/isSpinning en el Create del
#  puppet, mismo patron del isDead (v76) e isGrounded (v2.1.1).
#
#  NOTA DE REPO: v98b ya esta commiteado upstream (commit "ewe",
#  fd4c159b — la duena subio el zip tal cual). Este check corre sobre
#  ese arbol y confirma ademas que v98b sigue intacto.
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
print("=== 1. ARCHIVOS TOCADOS (v98c sobre 'ewe': 1 de juego + 2 checks + 3 docs) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
untracked = sorted([l[2:].strip() for l in lines if l[:2] == "??"])
V98C_MOD = sorted([
    "objects/obj_player_puppet/Create_0.gml",
    "check_v98b.py",
    "worklog.md",
    "CACHE.md",
    "LEARNING.md",
])
V98C_UNTRACKED = sorted(["check_v98c.py", "LEEME_V98C_FIX_ESCUDO_ELECTRICO.txt"])
V98D_MOD = sorted([
    "betterserver-oss/disasterserver/entities/ItemBox.c",
    "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/entities/ItemBox.h",
    "objects/obj_itembox/Step_2.gml",
    "objects/obj_player_puppet/Create_0.gml",
    "objects/obj_tails_projectile/Create_0.gml",
    "objects/obj_tails_projectile/Step_0.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_collision_objects/scr_collision_objects.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    "check_v98b.py",
    "worklog.md",
    "CACHE.md",
    "LEARNING.md",
])
V98D_UNTRACKED = sorted([
    "check_v98c.py", "LEEME_V98C_FIX_ESCUDO_ELECTRICO.txt",
    "check_v98d.py", "LEEME_V98D_ATRIBUCION_DEL_LASER.txt",
])
V99_MOD = sorted([
    "betterserver-oss/compilar_server.bat",
    "betterserver-oss/disasterserver/entities/BlazeFireball.c",
    "betterserver-oss/disasterserver/entities/ItemBox.c",
    "betterserver-oss/disasterserver/entities/ItemBoxMap.c",
    "betterserver-oss/disasterserver/entities/MetalAmyBullet.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/entities/ItemBox.h",
    "check_v98b.py",
    "objects/obj_blaze_fireball/Create_0.gml",
    "objects/obj_blaze_fireball/Step_0.gml",
    "objects/obj_fw_bolt/Create_0.gml",
    "objects/obj_fw_bolt/Step_0.gml",
    "objects/obj_itembox/Step_2.gml",
    "objects/obj_metal_amy_bullet/Create_0.gml",
    "objects/obj_metal_amy_bullet/Step_0.gml",
    "objects/obj_player_puppet/Create_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "objects/obj_tails_projectile/Create_0.gml",
    "objects/obj_tails_projectile/Step_0.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_collision_objects/scr_collision_objects.gml",
    "scripts/scr_parry/scr_parry.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    "worklog.md", "CACHE.md", "LEARNING.md",
])
V99_UNTRACKED = sorted([
    "LEEME_V98C_FIX_ESCUDO_ELECTRICO.txt", "LEEME_V98D_ATRIBUCION_DEL_LASER.txt",
    "check_v98c.py", "check_v98d.py",
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
])
# v100: upstream commiteo v98c ("asuewe") + v98d ("ewe") — el vuelo se
# reduce a lo que DIFIERE del HEAD nuevo (v99 pendiente + v100).
V100B_MOD = sorted([
    "betterserver-oss/compilar_server.bat",
    "betterserver-oss/disasterserver/entities/BlazeFireball.c",
    "betterserver-oss/disasterserver/entities/MetalAmyBullet.c",
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "check_v98b.py", "check_v98c.py", "check_v98d.py",
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
    "worklog.md", "CACHE.md", "LEARNING.md",
])
V100B_UNTRACKED = sorted([
    "check_v99.py", "LEEME_V99_PARRY_Y_BALANCE.txt",
    "check_v100.py", "LEEME_V100_EL_BLOQUEO_CUENTA.txt",
])
# v101: mismos mods + los 2 del v101 (gate v3.0 retirado por la duena)
V101_UNTRACKED = sorted(V100B_UNTRACKED + [
    "check_v101.py", "LEEME_V101_CASTIGO_AUN_CON_LAG.txt",
])
# estado del arbol (lecciones del 'ewe' del v98b): limpio (v98c commiteado
# upstream) / vuelo propio del v98c / vuelo del v98d (los 5 del v98c + 11
# del v98d — check_v98c.py va como UNTRACKED, nunca commiteado).
if mod_files == []:
    _estado = "arbol limpio: v98c ya commiteado upstream"
    _mods_ok = untracked == []
elif mod_files == V98C_MOD:
    _estado = "vuelo del v98c"
    _mods_ok = untracked == V98C_UNTRACKED
elif mod_files == V98D_MOD:
    _estado = "vuelo del v98d (zap al dueno + cajas al lanzador)"
    _mods_ok = untracked == V98D_UNTRACKED
elif mod_files == V99_MOD:
    _estado = "vuelo del v99 (parry devuelve todo + balance)"
    _mods_ok = untracked == V99_UNTRACKED
elif mod_files == V100B_MOD:
    _estado = "vuelo del v100 (el bloqueo siempre cuenta) sobre el HEAD nuevo"
    _mods_ok = untracked in (V100B_UNTRACKED, V101_UNTRACKED)
else:
    _estado = "NO RECONOCIDO"
    _mods_ok = False
chk(f"estado del arbol: {_estado} — ni un archivo de mas, cero .yy/.yyp",
    _mods_ok and not any(f.endswith((".yy", ".yyp")) for f in mod_files),
    f"real mods: {mod_files} untracked: {untracked}")

pupcr = rd("objects/obj_player_puppet/Create_0.gml")
hurt = rd("scripts/scr_player_hurt/scr_player_hurt.gml")
draw64 = rd("objects/obj_level/Draw_64.gml")
nsg = rd("scripts/net_state_game/net_state_game.gml")
glb = rd("scripts/scr_globals/scr_globals.gml")
lvlcr = rd("objects/obj_level/Create_0.gml")
game_c = rd("betterserver-oss/disasterserver/states/Game.c")

# ---------------------------------------------------------------------------
print("=== 2. EL FIX: defaults defensivos en el Create del puppet ===")
chk("isJumping = false en el Create del puppet",
    re.search(r"^isJumping = false;$", pupcr, re.M) is not None)
chk("isSpinning = false en el Create del puppet",
    re.search(r"^isSpinning = false;$", pupcr, re.M) is not None)
chk("el comentario cita el patron de la casa (isDead v76 / isGrounded v2.1.1)",
    "fix v76" in pupcr and "fix v2.1.1" in pupcr)
chk("el comentario documenta al lector (zap v92 del escudo electrico, scr_player_hurt)",
    "zap v92" in pupcr and "isAttacking || isJumping ||" in pupcr)
chk("estan pegados al bloque del isGrounded (mismo sitio del patron v2.1.1)",
    re.search(r"isGrounded = true;[\s\S]{0,900}?isJumping = false;", pupcr) is not None)

# ---------------------------------------------------------------------------
print("=== 3. FIX COMPLETO: TODAS las vars que lee el zap tienen default ===")
# Este es el check que habria atrapado el bug v92 ANTES de que llegara al
# juego: extrae los _pp.VAR REALES que lee scr_player_hurt sobre puppets y
# exige default en el Create para cada uno que no sea built-in (x/y/bbox_*).
# v92 anadio las lecturas de isJumping/isSpinning sin defaults -> crash.
lecturas = sorted(set(re.findall(r"_pp\.(\w+)", hurt)))
BUILTINS = {"x", "y", "id"}
faltantes = []
for v in lecturas:
    if v in BUILTINS or v.startswith("bbox_"):
        continue
    if not re.search(rf"^{v} = ", pupcr, re.M):
        faltantes.append(v)
chk(f"scr_player_hurt lee {lecturas} en puppets: TODAS con default en el Create",
    not faltantes, f"faltan: {faltantes}")
chk("isDead sigue con su default defensivo (patron v76)",
    re.search(r"^isDead = false;$", pupcr, re.M) is not None)
chk("isGrounded sigue con su default defensivo (patron v2.1.1)",
    re.search(r"^isGrounded = true;$", pupcr, re.M) is not None)
chk("isInactive / isHiding / isAttacking siguen inicializados",
    all(re.search(rf"^{v} = ", pupcr, re.M) for v in ("isInactive", "isHiding", "isAttacking")))
chk("el lector existe de verdad: _pp.isAttacking || _pp.isJumping || _pp.isSpinning",
    re.search(r"_pp\.isAttacking \|\| _pp\.isJumping \|\| _pp\.isSpinning", hurt) is not None)
chk("el zap sigue detras del guard del escudo (electricShieldTimer > 0): cero cambio de gameplay",
    re.search(r"electricShieldTimer\"\) && global\.player\.electricShieldTimer > 0", hurt) is not None)

# ---------------------------------------------------------------------------
print("=== 4. v98b SIGUE INTACTO (upstream 'ewe') ===")
chk("Draw_64: el infinito sigue dibujado en (238, 15) con rotacion 90",
    "draw_sprite_ext(spr_counter, 8, 238, 15, 1, 1, 90, c_white, 1);" in draw64)
chk("net_state_game: handler RING_OFF marca global.ringOff = true",
    "SERVER_GAME_RING_OFF" in nsg and "global.ringOff = true;" in nsg)
chk("scr_globals: global.ringOff = false en el arranque",
    glb.count("global.ringOff = false;") == 1)
chk("obj_level Create: global.ringOff = false por ronda",
    lvlcr.count("global.ringOff = false;") == 1)
chk("Game.c: helper game_kris_alone (condicion viva del retiro del anillo)",
    "static bool game_kris_alone" in game_c)

# ---------------------------------------------------------------------------
print("=== 5. check_v98b.py parcheado (state-aware post-'ewe') ===")
chk("check_v98b reconoce los 3 estados de arbol (limpio / overlay v98b / vuelo v98c)",
    "V98C_MOD" in rd("check_v98b.py"))

print()
print(f"RESULTADO: {OK} OK, {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
