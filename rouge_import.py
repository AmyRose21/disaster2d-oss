#!/usr/bin/env python3
"""
rouge_import.py — restaura los sprites de Rouge al proyecto GM tras el borrado.

FUENTES:
  - ZIP del usuario ("Sprite de rouge.zip"): el arte ORIGINAL TTB ("sprites dignos").
  - git 95ecd6d5 (estado v4.4 que funcionó): PNG exactos de las tiras que el zip
    NO trae (glide, stuck, marijuna, traped, emotion, attack1/attack2) y
    metadatos (bbox/origin/playback) de referencia.

SALIDA (en el clone /home/z/my-project/disaster2d-oss):
  - 20 tiras spr_rouge_*  (player_anims)   — arte zip donde existe, si no arte v4.4
  - 18 tiras spr_rougenega_* (negaanims)   — inversión 255-canal exacta frame a frame
  - spr_menu_rouge (lobby chars[14])       — arte NUEVO del zip (5 frames 210x184)
  - .yyp: re-registra las 39 tiras en sus posiciones antiguas

Estructura de cada sprite (patrón GM del repo):
  sprites/<name>/<name>.yy
  sprites/<name>/<GUIDframe>.png            (frame N)
  sprites/<name>/layers/<GUIDframe>/<GUIDlayer>.png  (copia idéntica)
"""
import io, os, re, sys, json, uuid, zipfile, subprocess
from PIL import Image

REPO   = "/home/z/my-project/disaster2d-oss"
ZIP    = "/home/z/my-project/upload/Sprite de rouge.zip"
GITREF = "95ecd6d5"          # estado v4.4 funcional
YYP    = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")
SPR    = os.path.join(REPO, "sprites")

zf = zipfile.ZipFile(ZIP)

# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
def new_guid():
    return str(uuid.uuid4())

def git_show(path):
    r = subprocess.run(["git", "show", f"{GITREF}:{path}"],
                       capture_output=True, cwd=REPO)
    return r.stdout if r.returncode == 0 else None

def yy_of(name):
    """devuelve el .yy v4.4 de una tira (texto) o None"""
    raw = git_show(f"sprites/{name}/{name}.yy")
    return raw.decode("utf-8", "replace") if raw else None

def zip_frames(base):
    """[(idx, PIL RGBA)] de una base del zip, orden numérico"""
    out = {}
    for n in zf.namelist():
        if not n.endswith(".png"): continue
        parts = n.split("/")
        if parts[0] != base: continue
        idx = int(parts[-1].rsplit("_", 1)[1].split(".")[0])
        out[idx] = Image.open(io.BytesIO(zf.read(n))).convert("RGBA")
    return [out[i] for i in sorted(out)]

def git_frames(name):
    """[(PIL RGBA)] de una tira v4.4 en el ORDEN del .yy"""
    txt = yy_of(name)
    if txt is None: return None
    i = txt.find('"frames"')
    seg = txt[i:]
    guids = re.findall(r'%Name":"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"', seg)
    frames = []
    for g in guids:
        raw = git_show(f"sprites/{name}/{g}.png")
        if raw:
            frames.append(Image.open(io.BytesIO(raw)).convert("RGBA"))
    return frames

def content_bbox(frames):
    """bbox de contenido REAL sobre todos los frames"""
    x0, y0, x1, y1 = 10**9, 10**9, -1, -1
    for im in frames:
        b = im.getbbox()
        if not b: continue
        x0 = min(x0, b[0]); y0 = min(y0, b[1])
        x1 = max(x1, b[2]); y1 = max(y1, b[3])
    return (x0, y0, x1, y1)

def meta_of(name):
    """metadatos v4.4 de una tira: dict con bbox/origin/playback/speed"""
    txt = yy_of(name)
    if txt is None: return {}
    d = {}
    for k in ["bboxMode","bbox_bottom","bbox_left","bbox_right","bbox_top",
              "height","width","origin","collisionKind"]:
        m = re.search(k+r'":(\d+)', txt)
        if m: d[k] = int(m.group(1))
    m = re.search(r'"playbackSpeed":([\d.]+)', txt)
    if m: d["playbackSpeed"] = float(m.group(1))
    return d

# ----------------------------------------------------------------------------
# generador de .yy (plantilla exacta del formato del repo, 1 capa por sprite)
# ----------------------------------------------------------------------------
def make_yy(name, w, h, frame_guids, layer_guid, bbox, origin, playback,
            folder="folders/Sprites/Player/Survivors/Rouge.yy", xorig=None, yorig=None):
    if xorig is None: xorig = w // 2
    if yorig is None: yorig = h // 2
    bl, bt, br, bb = bbox
    fr = ",\n".join(
        f'    {{"$GMSpriteFrame":"v1","%Name":"{g}","name":"{g}","resourceType":"GMSpriteFrame","resourceVersion":"2.0",}}'
        for g in frame_guids)
    n = len(frame_guids)
    return f'''{{
  "$GMSprite":"v2",
  "%Name":"{name}",
  "bboxMode":0,
  "bbox_bottom":{bb},
  "bbox_left":{bl},
  "bbox_right":{br},
  "bbox_top":{bt},
  "collisionKind":1,
  "collisionTolerance":0,
  "DynamicTexturePage":false,
  "edgeFiltering":false,
  "For3D":false,
  "frames":[
{fr}
  ],
  "gridX":0,
  "gridY":0,
  "height":{h},
  "HTile":false,
  "layers":[
    {{"$GMImageLayer":"","%Name":"{layer_guid}","blendMode":0,"displayName":"default","isLocked":false,"name":"{layer_guid}","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,}},
  ],
  "name":"{name}",
  "nineSlice":null,
  "origin":{origin},
  "parent":{{
    "name":"Rouge",
    "path":"{folder}",
  }},
  "preMultiplyAlpha":false,
  "resourceType":"GMSprite",
  "resourceVersion":"2.0",
  "sequence":{{
    "$GMSequence":"v1",
    "%Name":"{name}",
    "autoRecord":true,
    "backdropHeight":768,
    "backdropImageOpacity":0.5,
    "backdropImagePath":"",
    "backdropWidth":1366,
    "backdropXOffset":0.0,
    "backdropYOffset":0.0,
    "events":{{
      "$KeyframeStore<MessageEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MessageEventKeyframe>",
      "resourceVersion":"2.0",
    }},
    "eventStubScript":null,
    "eventToFunction":{{}},
    "length":{n}.0,
    "lockOrigin":false,
    "moments":{{
      "$KeyframeStore<MomentsEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MomentsEventKeyframe>",
      "resourceVersion":"2.0",
    }},
    "name":"{name}",
    "playback":1,
    "playbackSpeed":{playback},
    "playbackSpeedType":0,
    "resourceType":"GMSequence",
    "resourceVersion":"2.0",
    "showBackdrop":true,
    "showBackdropImage":false,
    "timeUnits":1,
    "tracks":[
      {{"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[
{",".join(keyframe(name, g, k) for k, g in enumerate(frame_guids))}
      ]}},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0}},
    ],
    "visibleRange":null,
    "volume":1.0,
    "xorigin":{xorig},
    "yorigin":{yorig},
  }},
  "swatchColours":null,
  "swfPrecision":2.525,
  "textureGroupId":{{
    "name":"Game",
    "path":"texturegroups/Game",
  }},
  "type":0,
  "VTile":false,
  "width":{w},
}}
'''

def keyframe(name, g, k):
    kid = new_guid()
    return f'''            {{"$Keyframe<SpriteFrameKeyframe>":"","Channels":{{
                "0":{{"$SpriteFrameKeyframe":"","Id":{{"name":"{g}","path":"sprites/{name}/{name}.yy",}},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",}},
              }},"Disabled":false,"id":"{kid}","IsCreationKey":false,"Key":{k}.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false}}'''

def invert(im):
    """inversión 255-canal exacta (RGB), alpha intacto"""
    px = [(255-r, 255-g, 255-b, a) for (r, g, b, a) in im.getdata()]
    out = Image.new("RGBA", im.size)
    out.putdata(px)
    return out

# ----------------------------------------------------------------------------
# definición de las tiras a crear
# ----------------------------------------------------------------------------
# (name, fuente) fuente: ("zip", base) o ("git", name_v44) o ("zip1", base) 1er frame
# metadatos base: 95ecd6d5 cuando existe (adaptados al arte nuevo), si no patrón knux.
STRIPS = [
    # tiras con arte ZIP
    ("spr_rouge_idle",      ("zip", "spr_rouge_idle")),
    ("spr_rouge_walk",      ("zip", "spr_rouge_walk")),
    ("spr_rouge_run",       ("zip", "spr_rouge_run")),
    ("spr_rouge_jump",      ("zip", "spr_rouge_jump")),
    ("spr_rouge_fall",      ("zip", "spr_rouge_fall")),
    ("spr_rouge_hurt",      ("zip", "spr_rouge_hurt")),
    ("spr_rouge_dead",      ("zip", "spr_rouge_dead")),
    ("spr_rouge_lookup",    ("zip", "spr_rouge_lookup")),
    ("spr_rouge_lookdown",  ("zip", "spr_rouge_lookdown")),
    ("spr_rouge_emotion1",  ("zip", "spr_rouge_emotion1")),
    ("spr_rouge_emotion2",  ("zip", "spr_rouge_emotion2")),
    ("spr_rouge_emotion3",  ("zip", "spr_rouge_emotion3")),
    ("spr_rouge_balancing", ("zip", "spr_rouge_balancing")),
    ("spr_rouge_attack1",   ("zip1", "spr_rouge_attack")),   # frame 0: patada aérea
    ("spr_rouge_attack2",   ("zip1", "spr_rouge_attack")),   # frame 1: barrido bajo
    ("spr_rouge_zipline",   ("zip", "spr_rouge_zipline")),
    # tiras sin arte zip -> PNG v4.4 de git
    ("spr_rouge_glide",     ("git", "spr_rouge_glide")),
    ("spr_rouge_stuck",     ("git", "spr_rouge_stuck")),
    ("spr_rouge_marijuna",  ("git", "spr_rouge_marijuna")),
    ("spr_rouge_traped",    ("git", "spr_rouge_traped")),
    ("spr_rouge_emotion",   ("git", "spr_rouge_emotion")),
]

# metadatos v4.4 por tira (estado que funcionó)
META = {}
for nm in [s[0] for s in STRIPS]:
    m = meta_of(nm)
    if m: META[nm] = m

# playback por defecto cuando no hay referencia v4.4
DEF_PLAYBACK = 30.0

made = []
def build_strip(name, source, nega=False):
    kind, src = source
    if kind == "zip":
        frames = zip_frames(src)
    elif kind == "zip1":
        frames = zip_frames(src)[:1] if src == "spr_rouge_attack" else zip_frames(src)[1:2]
        if src == "spr_rouge_attack":
            frames = [zip_frames(src)[0 if name.endswith("1") else 1]]
    else:
        frames = git_frames(src)
    if not frames:
        print(f"  !! sin frames para {name}"); return None

    if nega:
        frames = [invert(f) for f in frames]

    w, h = frames[0].size
    # uniformar (todas las tiras zip son constantes; las v4.4 también)
    for f in frames:
        assert f.size == (w, h), f"{name}: frames desiguales {f.size} vs {(w,h)}"

    m = META.get(name, {})
    # bbox: al contenido REAL de los frames nuevos (el v4.4 venía de tiras
    # recortadas de otro tamaño; bbox fuera del lienzo rompería el IDE)
    x0, y0, x1, y1 = content_bbox(frames)
    if x1 < 0:  # tira vacía
        x0, y0, x1, y1 = 0, 0, w - 1, h - 1
    bbox = (x0, y0, x1 - 1, y1 - 1)
    playback = m.get("playbackSpeed", DEF_PLAYBACK)

    # los rougenega viven en la MISMA carpeta Survivors/Rouge que los rouge
    # (canon del repo: knuxnega está en Survivors/Knuckles)
    folder = "folders/Sprites/Player/Survivors/Rouge.yy"
    d = os.path.join(SPR, name)
    os.makedirs(d, exist_ok=True)
    layer_guid = new_guid()
    frame_guids = []
    for f in frames:
        g = new_guid()
        frame_guids.append(g)
        f.save(os.path.join(d, g + ".png"))
        ld = os.path.join(d, "layers", g)
        os.makedirs(ld, exist_ok=True)
        f.save(os.path.join(ld, layer_guid + ".png"))
    yy = make_yy(name, w, h, frame_guids, layer_guid, bbox, 9, playback, folder)
    open(os.path.join(d, name + ".yy"), "w").write(yy)
    made.append(name)
    print(f"  {name}: {w}x{h} x{len(frames)}f  bbox={bbox}  pb={playback}  [{'NEGA' if nega else 'ZIP' if kind.startswith('zip') else 'GIT'}]")
    return (w, h, len(frames))

print("== TIRAS ROUGE ==")
norm_info = {}
for nm, src in STRIPS:
    norm_info[nm] = build_strip(nm, src)

print("== TIRAS ROUGE NEGA (inversión exacta) ==")
NEGA_MAP = [   # negaanims slot -> tira rouge base
    ("spr_rougenega_idle",      "spr_rouge_idle"),
    ("spr_rougenega_walk",      "spr_rouge_walk"),
    ("spr_rougenega_run",       "spr_rouge_run"),
    ("spr_rougenega_jump",      "spr_rouge_jump"),
    ("spr_rougenega_fall",      "spr_rouge_fall"),
    ("spr_rougenega_hurt",      "spr_rouge_hurt"),
    ("spr_rougenega_dead",      "spr_rouge_dead"),
    ("spr_rougenega_lookup",    "spr_rouge_lookup"),
    ("spr_rougenega_lookdown",  "spr_rouge_lookdown"),
    ("spr_rougenega_emotion1",  "spr_rouge_emotion1"),
    ("spr_rougenega_emotion2",  "spr_rouge_emotion2"),
    ("spr_rougenega_emotion",   "spr_rouge_emotion"),
    ("spr_rougenega_balancing", "spr_rouge_balancing"),
    ("spr_rougenega_attack1",   "spr_rouge_attack1"),
    ("spr_rougenega_attack2",   "spr_rouge_attack2"),
    ("spr_rougenega_glide",     "spr_rouge_glide"),
    ("spr_rougenega_zipline",   "spr_rouge_zipline"),
    ("spr_rougenega_stuck",     "spr_rouge_stuck"),
]
for neg, base in NEGA_MAP:
    # leer los frames recién escritos de la tira base (orden del .yy) e invertirlos
    d = os.path.join(SPR, base)
    txt = open(os.path.join(d, base + ".yy")).read()
    i = txt.find('"frames"')
    # GUIDs de frame en orden: los primeros nf son los frames (tras ellos viene
    # el GUID del layer); el corte [:400*40] causaba tiras truncadas
    nf = txt.count('"$GMSpriteFrame"')
    guids = re.findall(r'%Name":"([0-9a-f-]{36})"', txt[i:])[:nf]
    frames = [Image.open(os.path.join(d, g + ".png")).convert("RGBA") for g in guids]
    w, h = frames[0].size
    m = META.get(base, {})
    # bbox idéntico al de la tira base (la inversión conserva el contenido)
    txt_base = open(os.path.join(d, base + ".yy")).read()
    bx = [int(v) for k in ("bbox_left", "bbox_top", "bbox_right", "bbox_bottom")
          for v in re.findall(k + r'":(\d+)', txt_base)]
    bbox = tuple(bx) if len(bx) == 4 else (0, 0, w - 1, h - 1)
    playback = m.get("playbackSpeed", DEF_PLAYBACK)
    dn = os.path.join(SPR, neg)
    os.makedirs(dn, exist_ok=True)
    layer_guid = new_guid()
    fgs = []
    for f in frames:
        fi = invert(f)
        g = new_guid()
        fgs.append(g)
        fi.save(os.path.join(dn, g + ".png"))
        ld = os.path.join(dn, "layers", g)
        os.makedirs(ld, exist_ok=True)
        fi.save(os.path.join(ld, layer_guid + ".png"))
    yy = make_yy(neg, w, h, fgs, layer_guid, bbox, 9, playback,
                 "folders/Sprites/Player/Survivors/Rouge.yy")
    open(os.path.join(dn, neg + ".yy"), "w").write(yy)
    made.append(neg)
    print(f"  {neg}: {w}x{h} x{len(frames)}f (inversión de {base})")

print("== MENU ROUGE (lobby chars[14]) ==")
menu_frames = zip_frames("spr_menu_rouge_2")
d = os.path.join(SPR, "spr_menu_rouge")
os.makedirs(d, exist_ok=True)
layer_guid = new_guid()
fgs = []
for f in menu_frames:
    g = new_guid()
    fgs.append(g)
    f.save(os.path.join(d, g + ".png"))
    ld = os.path.join(d, "layers", g)
    os.makedirs(ld, exist_ok=True)
    f.save(os.path.join(ld, layer_guid + ".png"))
w, h = menu_frames[0].size
yy = make_yy("spr_menu_rouge", w, h, fgs, layer_guid, (0, 0, w - 1, h - 1), 0, 15.0,
             "folders/Sprites/Main Menu/Gifs.yy")
open(os.path.join(d, "spr_menu_rouge.yy"), "w").write(yy)
made.append("spr_menu_rouge")
print(f"  spr_menu_rouge: {w}x{h} x{len(menu_frames)}f (arte nuevo del zip)")

# ----------------------------------------------------------------------------
# registrar en el .yyp (posiciones del estado viejo: spr_rouge* tras spr_roseheart,
# spr_rougenega* tras spr_rouge_zipline, spr_menu_rouge junto a los demás menu)
# ----------------------------------------------------------------------------
lines = open(YYP).readlines()
entry = '    {{"id":{{"name":"{n}","path":"sprites/{n}/{n}.yy",}},}},\n'

# localizar puntos de inserción
def find_line(name):
    for i, l in enumerate(lines):
        if f'"name":"{name}"' in l and '"id":' in l:
            return i
    return None

# 1) spr_rouge_* y spr_rougenega_*: insertar tras spr_roseheart (posición histórica:
#    los spr_rouge iban justo después de roseheart, los rougenega tras el último rouge)
i_rose = find_line("spr_roseheart")
# el vecino siguiente HOY es spr_sally_*; insertar ahí
insert_at = i_rose + 1
rouge_names = sorted([n for n in made if n.startswith("spr_rouge_")])
nega_names  = sorted([n for n in made if n.startswith("spr_rougenega_")])
block = [entry.format(n=n) for n in rouge_names + nega_names]
lines[insert_at:insert_at] = block

# 2) spr_menu_rouge: tras spr_menu_rings (posición histórica exacta)
i_menu = find_line("spr_menu_rings")
if i_menu is None:
    i_menu = find_line("spr_menu_lobbyicon")
lines.insert(i_menu + 1, entry.format(n="spr_menu_rouge"))

open(YYP, "w").writelines(lines)

print(f"\nTOTAL tiras creadas: {len(made)}")
print("yyp actualizado:", YYP)
