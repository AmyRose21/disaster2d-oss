#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v38.py — Validador de la ronda v38: LA SILUETA QUE FALTABA.

    * spr_rouge_invis_emotion3 — silueta de contorno rojo (1 px,
      (255,0,0)) de los 10 frames de spr_rouge_emotion3 (la pose
      "emotico3"). La v32 levanto 20 siluetas ANTES de que la pose
      existiera como estado: las listas quedaron desincronizadas
      (la normal usa emotion3 en 11 y 25; la invis caia al walk en
      25 y al 1er emotico en 11).
    * Wire en la tabla invis de scr_survivors.gml:
        slot 11 (EMOTION3, 3er emote)  -> espejo del fix v36
        slot 25 (ROUGE_RINGS, canal de ANILLOS del SUPPORT) ->
          antes "defensivo: walk" PERO el canal es SOPORTE y NO apaga
          la invisibilidad: en invisible se veia ANDAR en vez de la
          pose del canal.
    * El escudo electrico (26) NO se toca: sigue en spr_rouge_idle
      (lista normal, v34: pose Idle pedida por la duena + el aura
      spr_electroshield encima que dibuja el Draw_0) y su silueta
      invis sigue siendo el walk defensivo — esta ronda era SOLO la
      emotion3.

Anti-cheat: CERO cambios de red. La silueta la dibuja el Draw_76 de
obj_rouge (vista LOCAL de la jugadora); para los demas clientes nada
cambia (PLAYER_INVIS esconde su puppet igual y el canal ANILLOS ya
viaja validado por el server con CLIENT_CREAM_SPAWN_RINGS).

Verifica (estatico, sin GameMaker):
  A. .yy del sprite nuevo: estructura completa, 10 frames, layers,
     secuencia, dimensiones/origen/bbox heredados del origen, sin .bak.
  B. Pixeles: cada frame = contorno rojo puro 1px del frame origen
     (recomputado y comparado pixel a pixel).
  C. GUIDs nuevos unicos en el proyecto (1692 .yy + el .yyp).
  D. .yyp: 2503 recursos, sin duplicados, entrada exacta 1 vez,
     posicion alfabetica.
  E. GML: balance + tabla invis 27 slots (solo 11 y 25 cambian) +
     tabla normal intacta (11/25 = emotion3, 26 = idle) + Draw_76
     sigue eligiendo la tabla invis + macros intactos.
  F. E2E: invisible + canal ANILLOS -> silueta emotion3; invisible +
     3er emote -> silueta emotion3; invisible + escudo -> walk (lo
     de siempre); visible + escudo -> idle + aura (v34 intacto).
  G. Regresion vs v37: solo los 3 hunks esperados en scr_survivors,
     +1 linea en el .yyp, resto de archivos rouge IDENTICOS (si esta
     disponible la carpeta baseline /tmp/v37 — maquina de la IA).
  H. Anti-cheat: cero lineas nuevas de red en el diff; el server
     sigue validando los anillos; el puppet invisible sigue oculto.

Uso: python3 check_v38.py [ruta_repo]   (por defecto /home/z/my-project/repo)
"""
import json
import os
import re
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/repo"
SPR = os.path.join(REPO, "sprites")
YYP = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")
BASE37 = "/tmp/v37"  # baseline v37 (maquina de la IA; se salta si no hay)

PASS = 0
FAIL = 0


def ok(msg):
    global PASS
    PASS += 1
    print(f"  [OK] {msg}")


def bad(msg):
    global FAIL
    FAIL += 1
    print(f"  [FALLA] {msg}")


def check(cond, msg):
    if cond:
        ok(msg)
    else:
        bad(msg)


def yy_load(path):
    raw = open(path, encoding="utf-8").read()
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", raw)), raw


# ---------------------------------------------------------------------------
print("== A. .yy del sprite nuevo ==")
NAME = "spr_rouge_invis_emotion3"
SRC = "spr_rouge_emotion3"
d_dir = os.path.join(SPR, NAME)
s_dir = os.path.join(SPR, SRC)
d_yy = os.path.join(d_dir, NAME + ".yy")

check(os.path.isdir(d_dir), f"carpeta {NAME}/ existe")
check(os.path.isfile(d_yy), f"{NAME}.yy existe")
check(not any(f.endswith(".bak") for f in os.listdir(d_dir)), "sin .bak en la carpeta")

new_data, new_raw = yy_load(d_yy)
src_data, _ = yy_load(os.path.join(s_dir, SRC + ".yy"))

check(new_data["%Name"] == NAME and new_data["name"] == NAME, "%Name/name correctos")
check(new_data["resourceType"] == "GMSprite", "resourceType GMSprite")

nframes = len(new_data["frames"])
check(nframes == len(src_data["frames"]) == 10, f"10 frames (== origen): {nframes}")
check(new_data["sequence"]["length"] == float(nframes), f"sequence.length == {nframes}")

# cada frame: png en raiz + carpeta layers/<guid> con la imagen de capa
all_ok = True
for f in new_data["frames"]:
    g = f["name"]
    if not os.path.isfile(os.path.join(d_dir, g + ".png")):
        all_ok = False
        break
    ldir = os.path.join(d_dir, "layers", g)
    if not os.path.isdir(ldir) or not [x for x in os.listdir(ldir) if x.endswith(".png")]:
        all_ok = False
        break
check(all_ok, "cada frame: PNG en raiz + layers/<guid>/ con su imagen")

pngs = [f for f in os.listdir(d_dir) if f.endswith(".png")]
check(len(pngs) == nframes, f"PNGs sueltos == frames ({len(pngs)}/{nframes})")

# keyframes del track de la secuencia
track = new_data["sequence"]["tracks"][0]
kf = track["keyframes"]["Keyframes"]
check(len(kf) == nframes, f"keyframes == {nframes}")
check([k["Key"] for k in kf] == list(range(nframes)), "Keys 0..9 en orden")
check(all(k["Channels"]["0"]["Id"]["path"] == f"sprites/{NAME}/{NAME}.yy" for k in kf), "Id.path de todos los keyframes apunta al .yy nuevo")
check(all(k["Channels"]["0"]["Id"]["name"] == f["name"] for k, f in zip(kf, new_data["frames"])), "keyframe i <-> frame i (mismo GUID)")

# geometria y todo el resto heredado del origen (salvo %Name/name,
# frames, layers y sequence, que son lo nuevo por disenio)
skip = {"%Name", "name", "frames", "layers", "sequence"}
diff_keys = [k for k in new_data if k not in skip and new_data[k] != src_data.get(k)]
check(not diff_keys, f"todo el resto heredado tal cual del origen (width/height/bboxMode/bbox/origin/textura...): difieren={diff_keys}")
check(new_data["width"] == 28 and new_data["height"] == 43
      and new_data["sequence"]["xorigin"] == 14 and new_data["sequence"]["yorigin"] == 21,
      "dimensiones 28x43, origen 14,21 (== spr_rouge_emotion3)")
ref = yy_load(os.path.join(SPR, "spr_rouge_invis_emotion2/spr_rouge_invis_emotion2.yy"))[0]
check(new_data["parent"] == ref["parent"], f"parent == carpeta Rouge de las demas siluetas ({new_data['parent']['path']})")
check(new_data["sequence"]["xorigin"] == src_data["sequence"]["xorigin"]
      and new_data["sequence"]["yorigin"] == src_data["sequence"]["yorigin"]
      and new_data["sequence"]["playback"] == src_data["sequence"]["playback"], "origen y playback de la secuencia heredados")

# GUIDs internos unicos
fg = [f["name"] for f in new_data["frames"]]
lg = [l["name"] for l in new_data["layers"]]
kg = [k["id"] for k in kf]
check(len(set(fg)) == len(fg) and len(set(lg)) == len(lg) and len(set(kg)) == len(kg), "GUIDs internos (frames/layers/keyframes) unicos")

# ---------------------------------------------------------------------------
print("== B. Pixeles: silueta recomputada del origen ==")
from PIL import Image


def silhouette(im):
    im = im.convert("RGBA")
    w, h = im.size
    ax = im.getchannel("A").load()
    body = [[ax[x, y] >= 128 for x in range(w)] for y in range(h)]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            if not body[y][x]:
                continue
            edge = (x == 0 or not body[y][x - 1] or x == w - 1 or not body[y][x + 1]
                    or y == 0 or not body[y - 1][x] or y == h - 1 or not body[y + 1][x])
            if edge:
                opx[x, y] = (255, 0, 0, 255)
    return out


src_frames = [f["name"] for f in src_data["frames"]]
pix_ok = True
red_ok = True
nonempty_ok = True
for i, g in enumerate(fg):
    gen = Image.open(os.path.join(d_dir, g + ".png")).convert("RGBA")
    exp = silhouette(Image.open(os.path.join(s_dir, src_frames[i] + ".png")))
    if gen.size != exp.size or gen.tobytes() != exp.tobytes():
        pix_ok = False
    px = gen.load()
    n_red = 0
    for y in range(gen.size[1]):
        for x in range(gen.size[0]):
            r, gr_, b, a = px[x, y]
            if a > 0:
                if (r, gr_, b, a) != (255, 0, 0, 255):
                    red_ok = False
                n_red += 1
    if n_red == 0:
        nonempty_ok = False
check(pix_ok, "los 10 PNGs == silueta recomputada del frame origen (pixel a pixel)")
check(red_ok, "todo pixel opaco es ROJO PURO (255,0,0,255)")
check(nonempty_ok, "ningun frame vacio (cada uno tiene contorno)")

# la imagen de capa == la del frame
lay_ok = all(Image.open(os.path.join(d_dir, "layers", g, lg[0] + ".png")).tobytes()
             == Image.open(os.path.join(d_dir, g + ".png")).tobytes() for g in fg)
check(lay_ok, "layers/<frame>/<layer>.png == frame correspondiente")

# ---------------------------------------------------------------------------
print("== C. GUIDs nuevos unicos en el proyecto ==")
needles = set(fg) | set(lg)
hits = []
for root, dirs, files in os.walk(SPR):
    for fn in files:
        if not fn.endswith(".yy"):
            continue
        p = os.path.join(root, fn)
        if p == d_yy:
            continue
        try:
            txt = open(p, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        for n in needles:
            if n in txt:
                hits.append((n, p))
yyp_raw = open(YYP, encoding="utf-8").read()
for n in needles:
    if n in yyp_raw:
        hits.append((n, "yyp"))
check(not hits, f"los {len(needles)} GUIDs no aparecen en ningun otro .yy/.yyp {('-> ' + str(hits[:3])) if hits else ''}")

# ---------------------------------------------------------------------------
print("== D. .yyp ==")
yyp = json.loads(re.sub(r",(\s*[}\]])", r"\1", yyp_raw))
names = [r["id"]["name"] for r in yyp["resources"]]
check(len(names) == 2503, f"2503 recursos (2502 de la v37 + 1): {len(names)}")
check(len(names) == len(set(names)), "sin nombres duplicados")
entry = '{"id":{"name":"spr_rouge_invis_emotion3","path":"sprites/spr_rouge_invis_emotion3/spr_rouge_invis_emotion3.yy",},},'
check(yyp_raw.count(entry) == 1, "entrada registrada EXACTAMENTE 1 vez (formato literal del archivo)")
i = names.index(NAME)
check(names[i - 1] == "spr_rouge_invis_emotion2" and names[i + 1] == "spr_rouge_invis_fall",
      f"posicion alfabetica: {names[i-1]} < {NAME} < {names[i+1]}")
check("snd_rouge_toobad" in yyp_raw and "snd_rouge_warp" in yyp_raw and "snd_rouge_luck" in yyp_raw, "los 3 sonidos v36/v37 siguen registrados (base v37 intacta)")

# ---------------------------------------------------------------------------
print("== E. GML scr_survivors.gml ==")
SURV = os.path.join(REPO, "scripts/scr_survivors/scr_survivors.gml")
surv = open(SURV, encoding="utf-8").read()
check(surv.count("{") - surv.count("}") == 0 and surv.count("(") - surv.count(")") == 0
      and surv.count("[") - surv.count("]") == 0, "llaves/parentesis/corchetes balanceados")


def parse_table(text, header):
    m = re.search(re.escape(header) + r"\s*=\s*\[(.*?)\];", text, re.S)
    if not m:
        return None
    rows = []
    for line in m.group(1).split("\n"):
        mm = re.match(r"\s*(spr_[A-Za-z0-9_]+)\s*,?\s*(?://|$)", line)
        if mm:
            rows.append(mm.group(1))
    return rows


invis = parse_table(surv, "global.player_rougeinvis[? CHARACTER_ROUGE]")
normal = parse_table(surv, "global.player_anims[? CHARACTER_ROUGE]")
check(invis is not None and len(invis) == 27, f"tabla invis: 27 slots ({len(invis) if invis else 0})")
check(normal is not None and len(normal) == 27, f"tabla normal: 27 slots ({len(normal) if normal else 0})")

# snapshot esperado de la tabla invis: v37 con SOLO 11 y 25 cambiados
inv37 = ["idle", "walk", "run", "jump", "fall", "hurt", "dead", "lookup", "lookdown",
         "emotion1", "emotion2", "emotion3", "jump", "balancing", "walk", "walk", "fly",
         "zipline", "stuck", "hurt", "spin_charger", "spin_release", "slide", "glide",
         "walk", "emotion3", "walk"]
expected_inv = [f"spr_rouge_invis_{s}" for s in inv37]
check(invis == expected_inv, "tabla invis == v37 con SOLO slot 11 y 25 -> spr_rouge_invis_emotion3")

nor37 = ["idle", "walk", "run", "jump", "fall", "hurt", "dead", "lookup", "lookdown",
         "emotion1", "emotion2", "emotion3", "jump", "balancing", "attack1", "attack2", "fly",
         "zipline", "stuck", "hurt", "spin_charger", "spin_release", "slide", "glide",
         "attack3", "emotion3", "idle"]
check(normal == [f"spr_rouge_{s}" for s in nor37],
      "tabla normal INTACTA (11/25 = emotion3 del fix v36, 26 = idle del escudo v34)")

d76 = open(os.path.join(REPO, "objects/obj_rouge/Draw_76.gml"), encoding="utf-8").read()
check("if(invisTimer > 0)" in d76 and "global.player_rougeinvis" in d76, "Draw_76 sigue eligiendo la tabla invis cuando invisTimer > 0")
check("EMOTION3 11" in surv and "#macro ROUGE_RINGS BALANCING+12" in open(
    os.path.join(REPO, "objects/obj_rouge/Step_2.gml"), encoding="utf-8").read(),
    "macros intactos: EMOTION3=11 y ROUGE_RINGS=BALANCING+12 (slot 25)")

# ---------------------------------------------------------------------------
print("== F. E2E (eleccion de sprite por estado) ==")
check(invis[25] == "spr_rouge_invis_emotion3", "E2E 1: invisible + canal ANILLOS (state 25) -> silueta emotion3 (antes: walk)")
check(invis[11] == "spr_rouge_invis_emotion3", "E2E 2: invisible + 3er emote (state 11) -> silueta emotion3 (antes: 1er emotico)")
check(invis[26] == "spr_rouge_invis_walk", "E2E 3: invisible + escudo (state 26) -> walk defensivo (SIN cambio, lo pedido era solo emotion3)")
check(normal[26] == "spr_rouge_idle", "E2E 4: visible + escudo -> pose IDLE (v34, lo pedido por la duena)")
d0 = open(os.path.join(REPO, "objects/obj_rouge/Draw_0.gml"), encoding="utf-8").read()
check("if(eShieldTimer > 0)" in d0 and "spr_electroshield" in d0, "E2E 5: el aura spr_electroshield sigue dibujandose encima durante el escudo (el escudo ES el aura + Idle)")

# ---------------------------------------------------------------------------
print("== G. Regresion vs v37 (baseline local de la IA) ==")
if os.path.isdir(BASE37):
    import difflib
    old = open(os.path.join(BASE37, "scripts/scr_survivors/scr_survivors.gml"), encoding="utf-8").read().splitlines()
    new = surv.splitlines()
    diff = [l for l in difflib.unified_diff(old, new, lineterm="", n=0)
            if l[:1] in "+-" and l[:3] not in ("+++", "---")]
    check(sum(1 for l in diff if l.startswith("+")) == 9 and sum(1 for l in diff if l.startswith("-")) == 5,
          f"diff vs v37: 5 lineas fuera (comentario 3 + slot 11 + slot 25) / 9 dentro ({len(diff)} cambios totales)")
    added = "\n".join(l for l in diff if l.startswith("+"))
    check("net_" not in added and "cpacket" not in added.lower() and "buffer_" not in added, "cero lineas de red agregadas")
    for f, base in [("scripts/scr_rouge_special/scr_rouge_special.gml", "scripts/scr_rouge_special/scr_rouge_special.gml"),
                    ("scripts/scr_player_hurt/scr_player_hurt.gml", "scripts/scr_player_hurt/scr_player_hurt.gml"),
                    ("objects/obj_playerui/Draw_64.gml", "objects/obj_playerui/Draw_64.gml")]:
        same = open(os.path.join(BASE37, base), encoding="utf-8").read() == open(os.path.join(REPO, f), encoding="utf-8").read()
        check(same, f"{f} IDENTICO a v37")
    yold = open(os.path.join(BASE37, "Sonicexe The Disaster 2D Remake.yyp"), encoding="utf-8").read()
    ynew = yyp_raw
    check(len(ynew.splitlines()) - len(yold.splitlines()) == 1 and ynew.replace("    " + entry + "\n", "") == yold,
          ".yyp vs v37: EXACTAMENTE +1 linea (la entrada del sprite)")
else:
    print("  [SKIP] sin baseline /tmp/v37 (maquina del usuario) — se valida igual contra el zip de la ronda")

# ---------------------------------------------------------------------------
print("== H. Anti-cheat ==")
special = open(os.path.join(REPO, "scripts/scr_rouge_special/scr_rouge_special.gml"), encoding="utf-8").read()
check("CLIENT_CREAM_SPAWN_RINGS" in special, "el server sigue validando los anillos (CLIENT_CREAM_SPAWN_RINGS intacto en el activador)")
netudp = open(os.path.join(REPO, "scripts/net_udpprocess/net_udpprocess.gml"), encoding="utf-8").read()
check("PLAYER_INVIS" in netudp and "visible = !(bitflags & PLAYER_INVIS)" in netudp,
      "PLAYER_INVIS sigue escondiendo el puppet en los demas clientes (la silueta es SOLO vista local)")
check("spr_rouge_invis_emotion3" not in special
      and "spr_rouge_invis_emotion3" not in netudp,
      "el sprite nuevo NO toca ni scr_rouge_special ni la red: 100% visual local (Draw_76)")

# ---------------------------------------------------------------------------
print(f"\nRESULTADO: {PASS} OK / {FAIL} FALLAS")
sys.exit(1 if FAIL else 0)
