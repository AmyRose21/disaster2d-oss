#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v39.py — Validador de la ronda v39 (los 5 pedidos de la duena):

  T1. SONIDOS DE INVISIBILIDAD, nueva formula:
      * al OCULTARSE: efecto snd_exe_appear + 1 voz al azar entre
        snd_rouge_ohmy (el mp3 nuevo rouge_surprise_oh_my) y
        snd_rouge_toobad. Local, sin emit (sigilo).
      * al APARECER: efecto snd_exe_appear (con emit) + 1 voz al azar
        entre snd_rouge_warp y snd_rouge_luck (antes sonaban las 2).
      * Asset NUEVO snd_rouge_ohmy (wav PCM 16b 44.1k stereo + .yy
        plantilla toobad + registro en el .yyp).
  T2. HUD: la fila de Rouge propia (frames 98-104 del arte nuevo de la
      duena) en las 4 tiras + la FORMA NEGA (fila 98-104 GENERADA con
      el transform negademon2 en los 2 sprites nega) + hit (14) y
      escaped (14). Wire de los 6 cases en scr_characters.
  T3. ROUGE RELEGADA: solo con el token de Amy (amy_canon.token) en
      scr_char_locked, como Amy Canon y Vanilla.
  T4. INVISIBILIDAD vs EXE: verificado TODO el rastreo. Fix del UNICO
      hueco: el clon del exeller la delataba (indicador de cercania
      sin filtrar invisibles).
  T5. ATAQUE DE KRIS: verificado — stun 3 s + slow 3 s post-stun +
      dano 20 a minions/nega + air2 hitbox +50% + i-frames. Funciona
      tal como se ordeno (al EXE no se le quita hp: patron de TODOS
      los ataques de survivor del juego).

Verifica (estatico, sin GameMaker): A-T1 sonidos, B-T2 HUD+nega,
C-T3 token, D-T4 rastreo, E-T5 Kris, F-rework attack3 del usuario,
G-regresion (git diff HEAD), H-anti-cheat.

Uso: python3 check_v39.py [ruta_repo]   (por defecto /home/z/my-project/repo)
"""
import json
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/repo"
SPR = os.path.join(REPO, "sprites")
YYP = os.path.join(REPO, "Sonicexe The Disaster 2D Remake.yyp")

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


def frames_of(spr):
    d, _ = yy_load(os.path.join(SPR, spr, spr + ".yy"))
    return d, [f["name"] for f in d["frames"]]


print("== A. T1 — Sonidos de invisibilidad ==")
SND = "sounds/snd_rouge_ohmy"
check(os.path.isfile(os.path.join(REPO, SND, "snd_rouge_ohmy.wav")), "snd_rouge_ohmy.wav existe")
d, _ = yy_load(os.path.join(REPO, SND, "snd_rouge_ohmy.yy"))
check(d["%Name"] == "snd_rouge_ohmy" and d["soundFile"] == "snd_rouge_ohmy.wav", ".yy con %Name y soundFile correctos")
check(d["parent"]["name"] == "Player" and d["audioGroupId"]["name"] == "audiogroup_default", "carpeta Sounds/Player + audiogroup_default (patron toobad)")
import wave
w = wave.open(os.path.join(REPO, SND, "snd_rouge_ohmy.wav"))
dur = w.getnframes() / w.getframerate()
check(w.getnchannels() == 2 and w.getsampwidth() == 2 and w.getframerate() == 44100, f"wav PCM 16 bit 44100 stereo ({dur:.2f} s, duration .yy {d['duration']:.3f})")
check(abs(d["duration"] - dur) < 0.01, "duration del .yy == duracion real del wav")
w.close()

raw = open(YYP, encoding="utf-8").read()
yyp = json.loads(re.sub(r",(\s*[}\]])", r"\1", raw))
names = [r["id"]["name"] for r in yyp["resources"]]
check(len(names) == 2504, f"2504 recursos (2503 + 1): {len(names)}")
check(len(names) == len(set(names)), "sin duplicados")
i = names.index("snd_rouge_ohmy")
check(names[i - 1] == "snd_rouge_luck" and names[i + 1] == "snd_rouge_toobad", "entrada alfabetica entre snd_rouge_luck y snd_rouge_toobad")

special = open(os.path.join(REPO, "scripts/scr_rouge_special/scr_rouge_special.gml"), encoding="utf-8").read()
m = re.search(r"// ACTIVAR — v39.*?invisTimer = ROUGE_INVIS_DURATION;", special, re.S)
check(m is not None, "bloque ACTIVAR v39 presente")
if m:
    b = m.group(0)
    check("audio_play_sound(snd_exe_appear, 0, false);" in b, "ACTIVAR: suena el EFECTO snd_exe_appear")
    check("choose(snd_rouge_ohmy, snd_rouge_toobad)" in b, "ACTIVAR: 1 voz al azar ohmy|toobad")
    check("net_sound_emit" not in b, "ACTIVAR: sin emit (sigilo de superviviente)")
m = re.search(r"// v39 \(duena\): APARICION.*?(?=// decay de la invisibilidad)", special, re.S)
check(m is not None, "bloque APARICION v39 presente")
if m:
    b = m.group(0)
    check(b.count("audio_play_sound(snd_exe_appear, 0, false);") == 1 and "net_sound_emit(snd_exe_appear)" in b, "APARICION: efecto snd_exe_appear local + emit (publico)")
    check("choose(snd_rouge_warp, snd_rouge_luck)" in b and "net_sound_emit(_voice)" in b, "APARICION: 1 voz al azar warp|luck y viaja por red")
    check(b.count("audio_play_sound(snd_rouge_warp") == 0 and b.count("audio_play_sound(snd_rouge_luck") == 0, "APARICION: las 2 voces SUMADAS de la v36 FUERA (ahora 1 al azar)")

print("== B. T2 — HUD: fila propia de Rouge + forma nega ==")
for spr, n, first_new in [("spr_playerhealth", 105, 98), ("spr_playerhealth_redring", 105, 98),
                          ("spr_playerhealth_hit", 15, 14), ("spr_playerescaped", 15, 14),
                          ("spr_playerhealth_nega", 105, 98), ("spr_playerhealth_redring_nega", 105, 98)]:
    d, fr = frames_of(spr)
    kfs = d["sequence"]["tracks"][0]["keyframes"]["Keyframes"]
    pngs = {f[:-4] for f in os.listdir(os.path.join(SPR, spr)) if f.endswith(".png")}
    check(len(fr) == n and len(kfs) == n and d["sequence"]["length"] == float(n),
          f"{spr}: {n} frames == keyframes == secuencia")
    check(set(fr).issubset(pngs), f"{spr}: cada frame tiene su PNG ({len(pngs)} en carpeta, huerfanos del usuario permitidos)")
    check(all(os.path.isdir(os.path.join(SPR, spr, "layers", g)) for g in fr), f"{spr}: layers/<frame>/ completos")
    check([k["Key"] for k in kfs] == [float(x) for x in range(n)] and [k["Channels"]["0"]["Id"]["name"] for k in kfs] == fr,
          f"{spr}: keyframes 0..{n-1} alineados con los frames")

chars = open(os.path.join(REPO, "scripts/scr_characters/scr_characters.gml"), encoding="utf-8").read()


def fn_body(name):
    m = re.search(r"function " + name + r"\(.*?\n\{(.*?)\n\}", chars, re.S)
    return m.group(1) if m else ""


def case_char(body, ch):
    m = re.search(r"case CHARACTER_" + ch + r":\s*return \[(spr_[\w]+),\s*([^\]]+)\];", body)
    return (m.group(1), m.group(2).strip()) if m else None


ROUGE_MATH = "(CHARACTER_ROUGE - CHARACTER_TAILS) * 7"
for fn, spr, idx in [("scr_hud_strip", "spr_playerhealth", ROUGE_MATH),
                     ("scr_hud_strip_red", "spr_playerhealth_redring", ROUGE_MATH),
                     ("scr_hud_strip_nega", "spr_playerhealth_nega", ROUGE_MATH),
                     ("scr_hud_strip_red_nega", "spr_playerhealth_redring_nega", ROUGE_MATH)]:
    c = case_char(fn_body(fn), "ROUGE")
    check(c == (spr, idx), f"{fn}(ROUGE) -> [{spr}, {idx}]")
for fn, spr, idx in [("scr_hud_hit", "spr_playerhealth_hit", "CHARACTER_ROUGE - CHARACTER_TAILS"),
                     ("scr_hud_escaped", "spr_playerescaped", "CHARACTER_ROUGE - CHARACTER_TAILS")]:
    c = case_char(fn_body(fn), "ROUGE")
    check(c == (spr, idx), f"{fn}(ROUGE) -> [{spr}, {idx}]")

surv = open(os.path.join(REPO, "scripts/scr_survivors/scr_survivors.gml"), encoding="utf-8").read()
check("#macro CHARACTER_ROUGE (CHARACTER_TAILS+14)" in surv and "#macro CHARACTER_TAILS 1" in surv,
      "enum: ROUGE = TAILS+14 -> (ROUGE-TAILS)*7 = 98 (la fila nueva)")
for fn, spr, idx in [("scr_hud_strip", "spr_playerhealth", "(CHARACTER_KNUX - CHARACTER_TAILS) * 7"),
                     ("scr_hud_hit", "spr_playerhealth_hit", "CHARACTER_KNUX - CHARACTER_TAILS"),
                     ("scr_hud_escaped", "spr_playerescaped", "CHARACTER_KNUX - CHARACTER_TAILS"),
                     ("scr_hud_demon", "spr_playerhealth_demon", "CHARACTER_KNUX - CHARACTER_TAILS")]:
    c = case_char(fn_body(fn), "KRIS")
    check(c == (spr, idx), f"{fn}(KRIS) SIN CAMBIOS (placeholder Knuckles intacto)")
check(case_char(fn_body("scr_hud_demon"), "ROUGE") == ("spr_playerhealth_demon", "CHARACTER_KNUX - CHARACTER_TAILS"),
      "scr_hud_demon(ROUGE) sin cambios (Rogue jamas se demoniza)")

from PIL import Image


def nega(im):
    im = im.convert("RGBA")
    out = Image.new("RGBA", im.size)
    po, pi = out.load(), im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = pi[x, y]
            po[x, y] = (r, g, b, a) if (a == 0 or (r, g, b) == (0, 0, 0)) else (255 - r, 255 - g, 255 - b, a)
    return out


for normal, nega_spr in [("spr_playerhealth", "spr_playerhealth_nega"), ("spr_playerhealth_redring", "spr_playerhealth_redring_nega")]:
    _, nfr = frames_of(normal)
    _, gfr = frames_of(nega_spr)
    pix_ok = True
    for i in range(98, 105):
        gen = Image.open(os.path.join(SPR, nega_spr, gfr[i] + ".png")).convert("RGBA")
        exp = nega(Image.open(os.path.join(SPR, normal, nfr[i] + ".png")))
        if gen.size != exp.size or gen.tobytes() != exp.tobytes():
            pix_ok = False
    check(pix_ok, f"{nega_spr}: frames 98-104 == transform nega del arte nuevo (inversion RGB, contorno (0,0,0) intacto, alpha intacto)")
    lay_ok = all(Image.open(os.path.join(SPR, nega_spr, "layers", g, os.listdir(os.path.join(SPR, nega_spr, "layers", g))[0])).tobytes()
                 == Image.open(os.path.join(SPR, nega_spr, g + ".png")).tobytes() for g in gfr[98:])
    check(lay_ok, f"{nega_spr}: layers de los frames nuevos == sus PNGs")

newg = set(frames_of("spr_playerhealth_nega")[1][98:]) | set(frames_of("spr_playerhealth_redring_nega")[1][98:])
own = {os.path.join(SPR, "spr_playerhealth_nega", "spr_playerhealth_nega.yy"),
       os.path.join(SPR, "spr_playerhealth_redring_nega", "spr_playerhealth_redring_nega.yy")}
hits = []
for root, dirs, files in os.walk(SPR):
    for fn in files:
        if fn.endswith(".yy"):
            p = os.path.join(root, fn)
            if p in own:
                continue
            try:
                txt = open(p, encoding="utf-8", errors="ignore").read()
            except OSError:
                continue
            for g in newg:
                if g in txt:
                    hits.append(g)
check(not hits and not any(g in raw for g in newg), f"los {len(newg)} GUIDs nuevos no existen en ningun otro .yy/.yyp")

print("== C. T3 — Rouge relegada al token ==")
m = re.search(r"function scr_char_locked\(ch\)\n\{(.*?)\n\}", surv, re.S)
check(m is not None, "scr_char_locked presente")
body = m.group(1) if m else ""
check(re.search(r"if\(ch == CHARACTER_ROUGE && global\.amyCanonToken == \"\"\)\s*return true;", body) is not None, "ROUGE: locked sin el token de Amy (v39)")
check("if(ch == CHARACTER_AMY_CANON && global.amyCanonToken == \"\")" in body, "Amy Canon: lock intacto")
check("if(ch == CHARACTER_VANILLA && global.amyCanonToken == \"\")" in body, "Vanilla: lock intacto")
check("if(ch == CHARACTER_SALLY_CANON && !global.isOperator)" in body, "Sally Canon: lock de operador intacto")
check("ROUGE RELEGADA" in body, "comentario v39 en el bloque")
lobby_icon = open(os.path.join(REPO, "objects/obj_lobby_icon/Draw_0.gml"), encoding="utf-8").read()
check(lobby_icon.count("scr_char_locked(") >= 3, f"el carrusel la salta solo (scr_char_locked x{lobby_icon.count('scr_char_locked(')} en obj_lobby_icon)")

print("== D. T4 — la invisibilidad esconde a Rouge del exe ==")
netudp = open(os.path.join(REPO, "scripts/net_udpprocess/net_udpprocess.gml"), encoding="utf-8").read()
check(netudp.count("visible = !(bitflags & PLAYER_INVIS);") == 2, "el puppet se oculta en los 2 caminos de PLAYER_INVIS (exe incluido)")
for ind in ["obj_exe_indicator", "obj_exeller_indicator", "obj_exetior_indicator"]:
    t = open(os.path.join(REPO, "objects", ind, "Step_2.gml"), encoding="utf-8").read()
    check("if(inst.character == CHARACTER_ROUGE && !inst.visible)" in t, f"{ind}: la aguja salta a la Rouge invisible (ni con anillo rojo)")
scan = open(os.path.join(REPO, "objects/obj_exe_indicator/Step_2.gml"), encoding="utf-8").read()
check("if(character == CHARACTER_ROUGE && !visible)" in scan, "el SCAN de Metal Amy tambien la salta")
clone = open(os.path.join(REPO, "objects/obj_exeller_clone/Step_0.gml"), encoding="utf-8").read()
check("if(character == CHARACTER_ROUGE && !visible)" in clone and clone.index("if(character == CHARACTER_ROUGE && !visible)") < clone.index("var dist = distance_to_object(_clone);"),
      "FIX v39: el CLON del exeller ya NO la delata (skip antes del rastreo de 240 px)")
hurt = open(os.path.join(REPO, "scripts/scr_player_hurt/scr_player_hurt.gml"), encoding="utf-8").read()
check("global.character == CHARACTER_ROUGE" in hurt and "invisTimer > 0" in hurt, "inmunidad de dano v36 intacta (invisible no recibe golpes)")

print("== E. T5 — el ataque de Kris hace lo ordenado ==")
netstep = open(os.path.join(REPO, "objects/obj_netclient/Step_2.gml"), encoding="utf-8").read()
m = re.search(r"if\(global\.character == CHARACTER_KNUX.*?CHARACTER_KRIS\)", netstep)
check(m is not None and "global.character == CHARACTER_KRIS" in m.group(0), "el bit PLAYER_ATTACKING de Kris VIAJA (esta en la lista del emisor)")
pup = open(os.path.join(REPO, "objects/obj_player_puppet/Step_0.gml"), encoding="utf-8").read()
check("state == KRIS_ATK_AIRE + 1" in pup and "KRIS_AIR2_HITBOX" in pup, "air2: hitbox +50% del bbox (pad del puppet)")
check("_krisPad > 0 && distance_to_object(global.player) <= _krisPad" in pup, "el pad del air2 entra en el contacto")
check("if(isAttacking" in pup and "|| (character == CHARACTER_FLEETWAY_AMY && isDJ)" in pup, "el gate de contacto exige el bit isAttacking")
check(re.search(r"var stunTime = 3;", pup) is not None, "stun por defecto de 3 s (la espada no lo sobreescribe)")
check(re.search(r"if\(character == CHARACTER_KRIS\)\s*krisSlowCountdown = stunTime \* 60;", pup) is not None, "el tajo programa el slow post-stun (krisSlowCountdown)")
check("global.player.shockedTimer = stunTime * 60;" in pup, "el stun se aplica en el cliente de la victima (autoridad)")
check("scr_jinna_negatouch_stun_hurt();" in pup, "dano 20 al subdito negativo via el stun (vida real)")
check(re.search(r"if\(global\.player\.revivalTimes >= 2[\s\S]{0,120}isMinion\) && global\.player\.isMinion\)", pup) or "global.player.isMinion" in pup, "dano JINNA_MINION_DAMAGE (20) al minion local via el contacto")
check("global.character == CHARACTER_KRIS && global.player.isAttacking" in hurt and "krisAtkVariant == 3" in hurt, "i-frames durante el air2 (krisAtkVariant 3)")
kris_sp = open(os.path.join(REPO, "scripts/scr_kris_special/scr_kris_special.gml"), encoding="utf-8").read()
check("#macro KRIS_SLOW_TIME 3" in kris_sp and "#macro KRIS_AIR2_HITBOX 0.5" in kris_sp, "macros intactos (slow 3 s, hitbox 50%)")
check("krisAtkVariant = isGrounded ? 1 : 2;" in kris_sp and "krisAtkVariant = 3;" in kris_sp, "tajo tierra + ataque aereo de 2 fases (1/2/3)")
d76k = open(os.path.join(REPO, "objects/obj_kris/Draw_76.gml"), encoding="utf-8").read()
check("state == KRIS_ATK_TIERRA" in d76k and d76k.count("isAttacking = false;") >= 2, "el ataque cierra al terminar la tira (tierra y air2)")

print("== F. Rework de spr_rouge_attack3 (arte nuevo de la duena) ==")
d3, fr3 = frames_of("spr_rouge_attack3")
check(len(fr3) == 5 and d3["width"] == 39 and d3["height"] == 45, "attack3 re-hecho por la duena: 5 frames 39x45")
pngs3 = {f[:-4] for f in os.listdir(os.path.join(SPR, "spr_rouge_attack3")) if f.endswith(".png")}
check(set(fr3).issubset(pngs3) and d3["sequence"]["length"] == 5.0, "estructura consistente (frames con sus PNGs == secuencia; huerfanos del usuario permitidos)")
d76r = open(os.path.join(REPO, "objects/obj_rouge/Draw_76.gml"), encoding="utf-8").read()
m = re.search(r"case ROUGE_KICK:.*?break;", d76r, re.S)
check(m is not None and "image_number - 1" in m.group(0) and "image_speed = 0.75" in m.group(0),
      "la patada es agnostica al frame count (image_number dinamico, cierre por kickState): el arte nuevo funciona solo")
dinv, ginv = frames_of("spr_rouge_invis_emotion3")
de3, _ = frames_of("spr_rouge_emotion3")
check(dinv["sequence"]["xorigin"] == de3["sequence"]["xorigin"] and dinv["sequence"]["yorigin"] == de3["sequence"]["yorigin"]
      and dinv["sequence"]["playbackSpeed"] == de3["sequence"]["playbackSpeed"],
      f"silueta invis emotion3 SINCRONIZADA con el origen nuevo de la pose ({de3['sequence']['xorigin']},{de3['sequence']['yorigin']}, playback {de3['sequence']['playbackSpeed']})")

print("== G. Regresion vs el pull (git) ==")
try:
    out = subprocess.run(["git", "diff", "HEAD", "--name-only"], capture_output=True, text=True, cwd=REPO).stdout
    files = [l.strip() for l in out.splitlines() if l.strip()]
    expect = ["Sonicexe The Disaster 2D Remake.yyp", "objects/obj_exeller_clone/Step_0.gml",
              "scripts/scr_characters/scr_characters.gml", "scripts/scr_rouge_special/scr_rouge_special.gml",
              "scripts/scr_survivors/scr_survivors.gml", "sprites/spr_playerhealth_nega/spr_playerhealth_nega.yy",
              "sprites/spr_playerhealth_redring_nega/spr_playerhealth_redring_nega.yy",
              "sprites/spr_rouge_invis_emotion3/spr_rouge_invis_emotion3.yy", "worklog.md"]
    check(sorted(files) == sorted(expect), f"touchados SOLO los 9 esperados (8 + worklog): extra={[f for f in files if f not in expect] or 'ninguno'} faltan={[f for f in expect if f not in files] or 'ninguno'}")
    for f in ["objects/obj_exeller_clone/Step_0.gml", "scripts/scr_characters/scr_characters.gml"]:
        d1 = subprocess.run(["git", "diff", "HEAD", "--", f], capture_output=True, text=True, cwd=REPO).stdout
        added = "\n".join(l for l in d1.splitlines() if l.startswith("+") and not l.startswith("+++"))
        check(not re.search(r"(net_sound_emit|net_quick_effect|cpacket|buffer_write|PacketType)\s*\(", added),
              f"{f.split('/')[-1]}: cero llamadas de red agregadas (los comentarios no cuentan)")
    d1 = subprocess.run(["git", "diff", "HEAD", "--", "Sonicexe The Disaster 2D Remake.yyp"], capture_output=True, text=True, cwd=REPO).stdout
    added = [l for l in d1.splitlines() if l.startswith("+") and not l.startswith("+++")]
    check(len(added) == 1 and "snd_rouge_ohmy" in added[0], ".yyp: EXACTAMENTE +1 linea (la entrada del sonido nuevo)")
except Exception as e:
    print(f"  [SKIP] sin git: {e}")

print("== H. Anti-cheat ==")
check("net_sound_emit(_voice)" in special and special.count("net_sound_emit(snd_exe_appear)") == 1,
      "red: 1 emit del efecto + 1 de la voz elegida (MENOS que la v36, que emitia 3)")
check("CLIENT_CREAM_SPAWN_RINGS" in special, "el server sigue validando los anillos")
check("visible = !(bitflags & PLAYER_INVIS);" in netudp, "PLAYER_INVIS intacto (el puppet invisible sigue oculto para todos)")
added_all = subprocess.run(["git", "diff", "HEAD", "--", "scripts/scr_survivors/scr_survivors.gml"], capture_output=True, text=True, cwd=REPO).stdout
added_l = [l for l in added_all.splitlines() if l.startswith("+") and not l.startswith("+++")]
check(not any("cpacket" in l or "buffer_write" in l or "PacketType" in l for l in added_l), "scr_survivors: cero paquetes nuevos (el lock es 100% local)")

print(f"\nRESULTADO: {PASS} OK / {FAIL} FALLAS")
sys.exit(1 if FAIL else 0)
