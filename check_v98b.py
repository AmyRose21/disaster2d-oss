#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================================
#  check_v98b.py — v98b (FIX DEL DUELO FINAL: ANILLO NO-USABLE + TIEMPO
#  INFINITO). Verifica el reporte de la duena:
#   B1  Kris llega a LV 20 ANTES de quedarse solo (show AUTOMATICO del
#       item 7) y luego caen los demas -> el anillo igual se retira
#       (v98 lo dejaba activo para siempre: el gate usaba lms_natural,
#       que el latch del LMS ya no re-evaluaba nunca). Ahora la
#       condicion es VIVA: game_kris_alone() cada tick.
#   B2  El anillo retirado NO se destruye: vuelve a su estado "recien
#       aparecido" (el sprite de los 10 s de espera, spr_bigring sin
#       _ready) — visible en su sitio pero NADIE puede salir por el.
#   B3  Tiempo INFINITO en el 1 vs 1: con ring_off el server no manda
#       TIME_SYNC (la aguja se congela) ni ED_TIMEOVER, y el HUD
#       reemplaza los contadores por el INFINITO (el "8" del contador
#       girado 90 grados, cero sprites nuevos).
#   B4  El server DESCARTA cualquier CLIENT_PLAYER_ESCAPED con ring_off
#       (autoridad del server; cubre a un cliente desincronizado).
#  + archivos tocados (solo los previstos, cero .yy/.yyp), llaves
#    balanceadas, sintaxis C del server (gcc -fsyntax-only con stub de
#    enet), pixel-check del "8" girado y paridad de enums.
# ============================================================================
import subprocess, sys, os, re, json, tempfile, shutil

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
print("=== 1. ARCHIVOS TOCADOS (solo lo previsto, cero .yy/.yyp) ===")
st = run("git status --porcelain")
lines = [l.strip() for l in st.splitlines() if l.strip()]
mod_files = sorted([l[2:].strip() for l in lines if l[:2] in (" M", "M ")])
expected = sorted([
    # 8 archivos de JUEGO del v98b
    "betterserver-oss/disasterserver/states/Game.c",
    "betterserver-oss/include/Packet.h",
    "betterserver-oss/include/Server.h",
    "objects/obj_level/Create_0.gml",
    "objects/obj_level/Draw_64.gml",
    "scripts/net_packets/net_packets.gml",
    "scripts/net_state_game/net_state_game.gml",
    "scripts/scr_globals/scr_globals.gml",
    # 3 docs que actualiza cada version (mismo patron del v98)
    "CACHE.md",
    "LEARNING.md",
    "worklog.md",
])
# ESTADO DEL ARBOL: v98b ya esta commiteado upstream (commit "ewe",
# fd4c159b: la duena subio el zip tal cual, 13 archivos +846/-48). El
# overlay del zip se volvio NO-OP, asi que el estado ya no es solo
# "11 modificados". Estados validos:
#   1) arbol LIMPIO (v98b ya integrado en 'ewe', nada en vuelo);
#   2) overlay v98b clasico: base pre-v98b + zip = los 11 modificados
#      (check_v98b.py / LEEME_V98B sin trackear);
#   3) vuelo del v98c (fix del zap del escudo electrico): los 5 del
#      v98c modificados + check_v98c.py / LEEME_V98C sin trackear.
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
untracked = [l[2:].strip() for l in lines if l[:2] == "??"]
if mod_files == []:
    _estado = "arbol limpio: v98b ya commiteado upstream ('ewe')"
    _untracked_ok = untracked == []
elif mod_files == expected:
    _estado = "overlay v98b clasico (base pre-v98b + zip)"
    _untracked_ok = all("check_v98b.py" in u or "LEEME_V98B" in u for u in untracked)
elif mod_files == V98C_MOD:
    _estado = "vuelo del v98c (fix del zap del escudo electrico)"
    _untracked_ok = sorted(untracked) == V98C_UNTRACKED
elif mod_files == V98D_MOD:
    _estado = "vuelo del v98d (zap al dueno del laser + cajas que cobran al lanzador)"
    _untracked_ok = sorted(untracked) == V98D_UNTRACKED
elif mod_files == V99_MOD:
    _estado = "vuelo del v99 (parry devuelve todo + balance)"
    _untracked_ok = sorted(untracked) == V99_UNTRACKED
elif mod_files == V100B_MOD:
    _estado = "vuelo del v100 (el bloqueo siempre cuenta) sobre el HEAD nuevo"
    _untracked_ok = sorted(untracked) in (V100B_UNTRACKED, V101_UNTRACKED)
else:
    _estado = "NO RECONOCIDO"
    _untracked_ok = False
chk(f"estado del arbol: {_estado} — ni un archivo de mas, cero .yy/.yyp",
    _untracked_ok and not any(f.endswith((".yy", ".yyp")) for f in mod_files),
    f"real mods: {mod_files} untracked: {untracked}")

game_c = rd("betterserver-oss/disasterserver/states/Game.c")
srv_h  = rd("betterserver-oss/include/Server.h")
pkt_h  = rd("betterserver-oss/include/Packet.h")
nsg    = rd("scripts/net_state_game/net_state_game.gml")
nps    = rd("scripts/net_packets/net_packets.gml")
draw64 = rd("objects/obj_level/Draw_64.gml")
lvlcr  = rd("objects/obj_level/Create_0.gml")
glb    = rd("scripts/scr_globals/scr_globals.gml")

# ---------------------------------------------------------------------------
print("=== 2. B1 — HELPER game_kris_alone (condicion VIVA, cada tick) ===")
m = re.search(r"static bool game_kris_alone\(Server\* server\)\n\{(.*?)\n\}", game_c, re.S)
chk("existe el helper estatico game_kris_alone", bool(m))
if m:
    body = m.group(1)
    chk("helper vive ARRIBA de game_state_tick (accesible en el gate)",
        game_c.find("static bool game_kris_alone") < game_c.find("bool game_state_tick"))
    chk("helper usa los MISMOS criterios del gatillo LMS (no exe, no DEAD/DEMONIZED/ESCAPED)",
        "v->id == server->game.exe" in body and "PLAYER_DEAD" in body
        and "PLAYER_DEMONIZED" in body and "PLAYER_ESCAPED" in body)
    chk("helper pide UNICO superviviente Y que sea Kris",
        "alive == 1" in body and "last->surv_char == CH_KRIS" in body)
    # CAUGHT cuenta como vivo (mismo criterio que el conteo del LMS)
    chk("helper NO excluye PLAYER_CAUGHT (identico al conteo del LMS)",
        "PLAYER_CAUGHT" not in body)

print("=== 3. B1 — GATE DEL RETIRO: VIVO, sin lms_natural ===")
g = re.search(r"if \(server->game\.kris_lv >= KRIS_LV20_SIGNALS && server->game\.lms\n(.*?)\n        \{\n(.*?)\n        \}", game_c, re.S)
chk("el gate existe (kris_lv + lms + ...)", bool(g))
cond = g.group(1) if g else ""
blk = g.group(2) if g else ""
chk("el gate llama a game_kris_alone (chequeo vivo)",
    "game_kris_alone(server)" in cond)
chk("el gate YA NO depende de lms_natural (el fix del caso normal)",
    "lms_natural" not in cond)
chk("el gate sigue pidiendo lms_char == CH_KRIS y !ring_off (latch)",
    "server->game.lms_char == CH_KRIS" in cond and "!server->game.ring_off" in cond)
chk("el gate latched ring_off y difunde SERVER_GAME_RING_OFF",
    "server->game.ring_off = true" in blk and "SERVER_GAME_RING_OFF" in blk
    and "server_broadcast" in blk)

print("=== 4. B3 — SERVER: reloj DETENIDO con ring_off ===")
t = re.search(r"if \(server->game\.time <= TICKSPERSEC\)\n        \{\n(.*?)\n        \}", game_c, re.S)
tb = t.group(1) if t else ""
chk("bloque del reloj existe", bool(t))
chk("con ring_off el reloj se congela (time += server->delta, neto cero)",
    "if (server->game.ring_off)" in tb and "server->game.time += server->delta;" in tb)
# sin comentarios (el propio comentario del fix nombra TIME_SYNC/ED_TIMEOVER)
tb_code = re.sub(r"/\*.*?\*/", "", tb, flags=re.S)
chk("TIME_SYNC y ED_TIMEOVER quedan DENTRO del else (no en el duelo)",
    "SERVER_GAME_TIME_SYNC" not in tb_code.split("else")[0] and "ED_TIMEOVER" not in tb_code.split("else")[0])
chk("el descuento del reloj sigue intacto en el else",
    "server->game.time_sec--;" in tb and "server->game.time += TICKSPERSEC;" in tb)
chk("sin anillos por reloj en el duelo (spawn dentro del else)",
    "ring_coff" in tb and "ring_coff" not in tb_code.split("else")[0])
chk("game_player_tick y map tick siguen CORRIENDO SIEMPRE (fuera del gate)",
    re.search(r"\}\n\n        RAssert\(game_player_tick\(server\)\);", game_c) is not None)

print("=== 5. B4 — SERVER: CLIENT_PLAYER_ESCAPED descartado con ring_off ===")
e_start = game_c.find("case CLIENT_PLAYER_ESCAPED:")
e_end = game_c.find("SET_FLAG(v->plr.flags, PLAYER_ESCAPED);")
chk("bloque del escape existe", e_start >= 0 and e_end > e_start,
    f"start={e_start} end={e_end}")
eb = game_c[e_start:e_end] if e_start >= 0 and e_end > e_start else ""
chk("guard ring_off ANTES del SET_FLAG(PLAYER_ESCAPED)",
    "if (v->server->game.ring_off)" in eb)
gpos = eb.find("game.ring_off)")
tail260 = eb[gpos:gpos+260] if gpos >= 0 else ""
chk("el guard descarta en silencio (break, sin kick)",
    tail260.find("break;") >= 0 and "server_disconnect" not in tail260)

# ---------------------------------------------------------------------------
print("=== 6. B2 — CLIENTE: anillo a estado 'recien aparecido' (NO destruir) ===")
h = re.search(r"case PacketType\.SERVER_GAME_RING_OFF:\n                \{(.*?)\n                \}", nsg, re.S)
hb = h.group(1) if h else ""
chk("handler RING_OFF existe", bool(h))
chk("el anillo vuelve al sprite NO-listo (spr_bigring, el de los 10 s)",
    "sprite_index = spr_bigring;" in hb)
chk("el handler YA NO destruye el obj_bigring",
    "instance_destroy" not in hb)
chk("marca global.ringOff para el reloj infinito del HUD",
    "global.ringOff = true;" in hb)
chk("sigue apagando el banner Escape (state = 0) y el npring",
    "state = 0" in hb and "obj_npring" in hb)
chk("el Step del obj_bigring SOLO acepta spr_bigring_ready (no-listo = no escape)",
    "sprite_index == spr_bigring_ready" in rd("objects/obj_bigring/Step_0.gml"))

print("=== 7. B3 — CLIENTE: reloj INFINITO en el HUD ===")
chk("Draw_64 dibuja el infinito con global.ringOff (8 girado 90, frame 8) en (238, 15)",
    re.search(r"if\(global\.ringOff\)\n        \{\n\s+draw_sprite_ext\(spr_counter, 8, 238, 15, 1, 1, 90, c_white, 1\);", draw64) is not None)
chk("el comentario documenta la rotacion GM (+90 = antihorario: contenido ARRIBA-DERECHA)",
    "ARRIBA-DERECHA" in draw64 and "(238, 15)" in draw64)
chk("el else conserva los contadores originales intactos",
    re.search(r"draw_sprite\(spr_counter, 10, 233, 4\);\n\s+scr_counter_draw\(global\.timeMinutes, 224, 4\);\n\s+scr_counter_draw_m\(global\.timeSeconds, 244, 4, 2\);", draw64) is not None)
chk("la aguja del reloj se sigue dibujando (congelada: sin TIME_SYNC no avanza timeFrame)",
    "draw_sprite_ext(spr_clockhand" in draw64)
chk("init de global.ringOff en obj_level Create (reset por ronda)",
    lvlcr.count("global.ringOff = false;") == 1)
chk("init de global.ringOff en scr_globals (arranque de la app)",
    glb.count("global.ringOff = false;") == 1)

print("=== 8. PIXEL-CHECK: el '8' girado es un infinito de verdad ===")
try:
    from PIL import Image
    yy = json.loads(re.sub(r",(\s*[}\]])", r"\1", rd("sprites/spr_counter/spr_counter.yy")))
    frames = yy["frames"]
    ok_size = ok_eight = ok_holes = False
    if len(frames) > 8:
        im = Image.open(f"sprites/spr_counter/{frames[8]['name']}.png").convert("RGBA")
        w, hh = im.size
        px = im.load()
        ok_size = (w, hh) == (11, 15)
        grid = [[1 if (0.3*px[x,y][0]+0.5*px[x,y][1]+0.2*px[x,y][2]) > 100 and px[x,y][3] > 0 else 0
                 for x in range(w)] for y in range(hh)]
        # huecos encerrados (regiones de 0 que no tocan el borde): un 8 tiene 2
        seen = [[False]*w for _ in range(hh)]
        holes = 0
        for y in range(hh):
            for x in range(w):
                if grid[y][x] == 0 and not seen[y][x]:
                    stack = [(x, y)]
                    touches = False
                    seen[y][x] = True
                    while stack:
                        cx, cy = stack.pop()
                        if cx in (0, w-1) or cy in (0, hh-1):
                            touches = True
                        for nx, ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                            if 0 <= nx < w and 0 <= ny < hh and grid[ny][nx] == 0 and not seen[ny][nx]:
                                seen[ny][nx] = True
                                stack.append((nx, ny))
                    if not touches:
                        holes += 1
        ok_eight = holes == 2  # dos bucles apilados
        ok_holes = holes == 2
    chk("frame 8 del contador = '8' clasico de DOS bucles (girado 90 = infinito)",
        ok_size and ok_eight, f"size_ok={ok_size} huecos={holes if ok_size else '?'} (necesarios 2)")

    # ---- POSICION del infinito: render PIL vs el bloque real "4:37" ----
    # (el +90 de GM gira ANTIHORARIO en pantalla: el contenido cae
    #  ARRIBA-DERECHA del punto de dibujo, x' en [px, px+14], y' en
    #  [py-10, py]. PIL rotate(90) = misma convencion.)
    def brillo_bbox(img, x0=200, x1=280, y0=0, y1=25):
        p = img.load()
        xs, ys = [], []
        for yy_ in range(y0, min(y1, img.height)):
            for xx_ in range(x0, min(x1, img.width)):
                r, g, b, a = p[xx_, yy_]
                if a > 0 and (0.3*r + 0.5*g + 0.2*b) > 100:
                    xs.append(xx_); ys.append(yy_)
        if not xs:
            return None
        return (min(xs), min(ys), max(xs), max(ys))

    W, H = 480, 28
    def lienzo():
        return Image.new("RGBA", (W, H), (0, 0, 0, 0))
    def pegar(img, frame, x, y):
        img.paste(frames_img[frame], (x, y), frames_img[frame])
    frames_img = [Image.open(f"sprites/spr_counter/{f['name']}.png").convert("RGBA")
                  for f in yy["frames"][:11]]

    # bloque viejo "4:37" SOLO digitos (sin icono del reloj: su cara
    # brilla hasta x 224 y ensuciaria el bbox)
    viejo = lienzo()
    pegar(viejo, 4, 224, 4)    # minutos "4" (scr_counter_draw: 1 frame)
    pegar(viejo, 10, 233, 4)  # ":" (frame 10)
    pegar(viejo, 3, 244, 4)   # segundos "3"
    pegar(viejo, 7, 255, 4)   # segundos "7"
    bv = brillo_bbox(viejo)
    vcentro = ((bv[0]+bv[2])/2.0, (bv[1]+bv[3])/2.0)

    # el infinito: frame 8 girado 90 (antihorario, como GM), pegado con la
    # esquina sup-izq en (draw_x, draw_y-10) == draw_sprite_ext(draw_x, draw_y)
    m = re.search(r"draw_sprite_ext\(spr_counter, 8, (\d+), (\d+), 1, 1, 90", draw64)
    dx, dy = (int(m.group(1)), int(m.group(2))) if m else (None, None)
    chk("Draw_64 expone el draw del infinito con coords literales", m is not None)
    if m:
        nuevo = lienzo()
        ocho = frames_img[8].rotate(90, expand=True, resample=Image.NEAREST)
        nuevo.paste(ocho, (dx, dy - 10), ocho)
        bn = brillo_bbox(nuevo)
        ncentro = ((bn[0]+bn[2])/2.0, (bn[1]+bn[3])/2.0)
        dd = (ncentro[0]-vcentro[0], ncentro[1]-vcentro[1])
        dentro = 224 <= bn[0] and bn[2] <= 266 and 4 <= bn[1] and bn[3] <= 19
        chk("posicion del infinito: centrado en el bloque de numeros "
            f"(delta {dd[0]:+.1f}/{dd[1]:+.1f} px, tolerancia 3)",
            dentro and abs(dd[0]) <= 3 and abs(dd[1]) <= 3,
            f"bloque '4:37' bbox={bv} centro={vcentro} | ∞ bbox={bn} centro={ncentro}")
except ImportError:
    print("  [SKIP] sin PIL: pixel-check salteado")

# ---------------------------------------------------------------------------
print("=== 9. COMENTARIOS/DOC Y PARIDAD DE ENUMS ===")
chk("Packet.h documenta el chequeo vivo + anillo no-usable + SIN LIMITE DE TIEMPO",
    "UNICO superviviente vivo" in pkt_h and "recien aparecido" in pkt_h and "SIN" in pkt_h and "LIMITE DE TIEMPO" in pkt_h)
chk("net_packets.gml documenta lo mismo (lado cliente)",
    "global.ringOff" in nps and "INFINITO" in nps)
chk("Server.h: lms_natural queda documental (ya NO gatilla nada)",
    "ya NO gatilla nada" in srv_h)
chk("Server.h: ring_off documenta reloj congelado + escape descartado",
    "congela el reloj" in srv_h and "CLIENT_PLAYER_ESCAPED" in srv_h.split("bool ring_off;")[1][:300])
# paridad: RING_OFF al FINAL en los DOS lados (hasta v98d). v99: el trio
# del parry se anade DESPUES (tambien AL FINAL) — paridad = el MISMO
# sufijo en los dos enums, sea la era que sea.
ph = re.search(r"CLIENT_EXE_DEFEATED,\n\s+SERVER_GAME_RING_OFF\n\}", pkt_h)
pg = re.search(r"CLIENT_EXE_DEFEATED,\n\s+SERVER_GAME_RING_OFF\n\}", nps)
pv_h = re.search(r"CLIENT_METALAMY_BULLET_DEFLECT,\n\s+CLIENT_FWBOLT_DEFLECT,\n\s+CLIENT_BLAZE_FIREBALL_DEFLECT\n\}", pkt_h)
pv_g = re.search(r"CLIENT_METALAMY_BULLET_DEFLECT,\n\s+CLIENT_FWBOLT_DEFLECT,\n\s+CLIENT_BLAZE_FIREBALL_DEFLECT\n\}", nps)
chk("enums en paridad (RING_OFF ultimo hasta v98d / el trio v99 cierra el enum en los DOS lados)",
    bool(ph and pg) or bool(pv_h and pv_g))

# ---------------------------------------------------------------------------
print("=== 10. LLAVES BALANCEADAS (archivos GML tocados) ===")
for f in ["scripts/net_state_game/net_state_game.gml", "scripts/net_packets/net_packets.gml",
          "objects/obj_level/Draw_64.gml", "objects/obj_level/Create_0.gml",
          "scripts/scr_globals/scr_globals.gml"]:
    txt = rd(f)
    # quitar strings y comentarios de forma burda
    txt2 = re.sub(r'"(?:[^"\\]|\\.)*"', '""', txt)
    txt2 = re.sub(r"//[^\n]*", "", txt2)
    txt2 = re.sub(r"/\*.*?\*/", "", txt2, flags=re.S)
    chk(f"{f}: llaves y parens balanceadas",
        txt2.count("{") == txt2.count("}") and txt2.count("(") == txt2.count(")"))

# ---------------------------------------------------------------------------
print("=== 11. SINTAXIS C DEL SERVER (gcc -fsyntax-only, stub de enet) ===")
stub_dir = tempfile.mkdtemp(prefix="enet_stub_")
os.makedirs(os.path.join(stub_dir, "enet"), exist_ok=True)
with open(os.path.join(stub_dir, "enet", "enet.h"), "w") as f:
    f.write("""#ifndef ENET_STUB_H
#define ENET_STUB_H
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#define ENET_HOST_ANY 0
#define ENET_PACKET_FLAG_RELIABLE 1
typedef struct { uint32_t host; uint16_t port; } ENetAddress;
typedef struct { uint8_t *data; size_t dataLength; } ENetPacket;
typedef struct ENetPeer { int dummy; uint32_t roundTripTime; uint32_t sessionID; void *data;
        uint16_t incomingPeerID; ENetAddress address; } ENetPeer;
typedef struct ENetHost { int dummy; size_t mtu; int socket; } ENetHost;
typedef struct { int type; ENetPeer *peer; ENetPacket *packet; } ENetEvent;
typedef enum { ENET_EVENT_TYPE_NONE = 0, ENET_EVENT_TYPE_CONNECT, ENET_EVENT_TYPE_DISCONNECT, ENET_EVENT_TYPE_RECEIVE } ENetEventType;
typedef int ENetSocket;
typedef enum { ENET_SOCKOPT_RCVBUF = 0, ENET_SOCKOPT_SNDBUF } ENetSocketOption;
int enet_initialize(void); void enet_deinitialize(void);
ENetHost* enet_host_create(const ENetAddress*, ...);
int enet_host_service(ENetHost*, ENetEvent*, uint32_t);
void enet_packet_destroy(ENetPacket*);
int enet_peer_send(ENetPeer*, uint8_t, ENetPacket*);
void enet_peer_disconnect(ENetPeer*, uint32_t);
void enet_peer_disconnect_now(ENetPeer*, uint32_t);
void enet_peer_reset(ENetPeer*);
ENetPacket* enet_packet_create(const void*, size_t, uint32_t);
void enet_host_flush(ENetHost*); void enet_host_broadcast(ENetHost*, uint8_t, ENetPacket*);
int enet_address_get_host_ip(ENetAddress* a, char* b, size_t c);
void enet_socket_set_option(ENetSocket, ENetSocketOption, int);
void enet_host_destroy(ENetHost*);
#endif
""")
import subprocess as sp
r = sp.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/states/Game.c",
           shell=True, capture_output=True, text=True, cwd="betterserver-oss")
chk("states/Game.c compila limpio (gcc -fsyntax-only)", r.returncode == 0, r.stderr[:300])
for extra in ["states/CharSelect.c", "states/Lobby.c", "states/Mapvote.c", "states/Results.c", "entities/ItemBoxMap.c", "entities/Ring.c"]:
    r2 = sp.run(f"gcc -fsyntax-only -w -I{stub_dir} -I./include -I./disasterserver disasterserver/{extra}",
                shell=True, capture_output=True, text=True, cwd="betterserver-oss")
    chk(f"{extra} sigue compilando (Server.h/Packet.h sanos)", r2.returncode == 0, r2.stderr[:200])
shutil.rmtree(stub_dir, ignore_errors=True)

# ---------------------------------------------------------------------------
print("=== 12. SIMULACION DE LOS CAMINOS DEL DUELO (texto del gate) ===")
chk("camino duena (LV 20 con gente -> show automatico -> caen los demas): "
    "el gate ya no mira lms_natural -> ring_off DISPARA",
    "game_kris_alone" in cond and "lms_natural" not in cond)
chk("camino show automatico CON MAS GENTE VIVA: game_kris_alone=false -> NO retira",
    "alive == 1" in re.search(r"static bool game_kris_alone.*?\n\}", game_c, re.S).group(0))
chk("camino ultimo superviviente NO-Kris (show de otro): lms_char==CH_KRIS falla -> NO retira",
    "server->game.lms_char == CH_KRIS" in cond)
chk("reconexion al duelo: RING_OFF se reenvia y el handler es idempotente "
    "(sprite + flag se pueden re-aplicar)",
    "if (v->server->game.ring_off)" in game_c and "sprite_index = spr_bigring;" in hb)

# ---------------------------------------------------------------------------
print()
print(f"RESULTADO: {OK} OK, {FAIL} FAIL")
sys.exit(1 if FAIL else 0)
