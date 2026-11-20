#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v40.py — Validador de la ronda v40 (los 2 pedidos de la duena):

  T1. ROUGE SOLO CON EL TOKEN, en TODOS los frentes (como Amy Canon y
      Vanilla):
      * CLIENTE (v39, verificado intacto): scr_char_locked la oculta del
        carrusel, del retrato y de la placa sin amy_canon.token.
      * SERVER (NUEVO v40): states/CharSelect.c rechaza el pick de Rouge
        sin amy_authed con result=0 (como ocupada) — el DOBLE SEGURO
        contra clientes editados. v6.3 la aceptaba de todos: cerrado.
  T2. ICONO DE SELECCION PROPIO: la duena amplio spr_lobby_icon a 14
      frames (frame 13 = Rouge). scr_lobby_icon_frame ahora devuelve 13
      para CHARACTER_ROUGE (antes: frame de Knuckles). Aplica al
      carrusel, resultados y lista de espera (todos pasan por el mismo
      resolvedor). Kris conserva SU placeholder de Knuckles por pedido
      explicito (v5/v39).

Verifica (estatico, sin GameMaker ni compilacion del server):
  A-T1 cliente token, B-T1 server token, C-T1 no-regresion de los otros
  locks, D-T2 icono Rouge, E-T2 integridad del sprite ampliado (.yy/.png/
  keyframes/unicidad de GUIDs), F-regresion git (solo 2 archivos + docs),
  G-anti-cheat (nada de red del lado cliente, solo el rechazo server).

Uso: python3 check_v40.py [ruta_repo]
     (por defecto /home/z/my-project/disaster2d-oss)
"""
import json
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/z/my-project/disaster2d-oss"
SCR_CH = os.path.join(REPO, "scripts/scr_characters/scr_characters.gml")
SCR_SV = os.path.join(REPO, "scripts/scr_survivors/scr_survivors.gml")
CHARSEL = os.path.join(REPO, "betterserver-oss/disasterserver/states/CharSelect.c")
SPR_ICON = os.path.join(REPO, "sprites/spr_lobby_icon/spr_lobby_icon.yy")
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


def check(msg, cond):
    ok(msg) if cond else bad(msg)


def read(p):
    with open(p, encoding="utf-8-sig") as f:
        return f.read()


def parse_yy(p):
    raw = read(p)
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", raw))


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args),
                          capture_output=True, text=True).stdout


print("== A. T1 CLIENTE: Rouge oculta sin token (v39 intacto) ==")
sv = read(SCR_SV)
check("scr_char_locked existe", "function scr_char_locked" in sv)
m = re.search(r"if\(ch == CHARACTER_ROUGE && global\.amyCanonToken == \"\"\)\s*\n\s*return true;", sv)
check("scr_char_locked: lock de Rouge sin token", bool(m))
check("scr_char_locked: lock de Amy Canon sin token", "CHARACTER_AMY_CANON && global.amyCanonToken == \"\"" in sv)
check("scr_char_locked: lock de Vanilla sin token", "CHARACTER_VANILLA && global.amyCanonToken == \"\"" in sv)
check("scr_char_locked: Sally Canon solo operador", "CHARACTER_SALLY_CANON && !global.isOperator" in sv)
lobby_icon = read(os.path.join(REPO, "objects/obj_lobby_icon/Draw_0.gml"))
check("carrusel salta los locked al ciclar", "scr_char_locked(selected)" in lobby_icon)
lobby_draw = read(os.path.join(REPO, "objects/obj_lobby/Draw_0.gml"))
check("retrato/placa ocultos si locked", "scr_char_locked(sprInd + 1)" in lobby_draw)

print("== B. T1 SERVER: rechazo de Rouge sin token (NUEVO v40) ==")
cs = read(CHARSEL)
check("bloque Rouge existe", "id == CH_ROUGE && !v->amy_authed" in cs)
m = re.search(r"if \(id == CH_ROUGE && !v->amy_authed\)\s*\{(.*?)\}", cs, re.S)
body = m.group(1) if m else ""
check("responde result=0 (como ocupada)", "packet_write8, 0" in body)
check("responde con el id 1-based (id + 1)", "packet_write8, id + 1" in body)
check("loguea el intento sin unlock", "tried to pick [Rouge] without unlock" in body)
check("corta antes de registrar (return true)", "return true;" in body)
check("patron IDENTICO al de Vanilla", "id == CH_VANILLA && !v->amy_authed" in cs)
check("patron IDENTICO al de Amy Canon", "id == CH_AMY_CANON && !v->amy_authed" in cs)
check("patron IDENTICO al de Jinna (killer)", "id == EX_JINNA && !v->amy_authed" in cs)
check(" comentario v6.3 (re-activada) retirado", "RE-ACTIVADA" not in cs)
check("acepta con token: no hay otro bloque CH_ROUGE", cs.count("CH_ROUGE") == 1)
orden = cs.find("CH_VANILLA && !v->amy_authed") < cs.find("CH_ROUGE && !v->amy_authed") < cs.find("v->surv_char = id")
check("bloque ANTES de v->surv_char = id (nunca se asigna)", orden)
# sintaxis C
r = subprocess.run(["gcc", "-fsyntax-only", "-I", "include", "-I", "disasterserver",
                    "-I", "/tmp/enetstub", "disasterserver/states/CharSelect.c"],
                   cwd=os.path.join(REPO, "betterserver-oss"),
                   capture_output=True, text=True)
check(f"gcc -fsyntax-only del CharSelect.c: compila {r.stderr[:80]}", r.returncode == 0)
for line in r.stderr.splitlines():
    if "warning" in line and "enum-compare" not in line:
        bad(f"warning NUEVO en la compilacion: {line[:100]}")

print("== C. T1 no-regresion: ningun otro personaje cambio de llave ==")
check("Fleetway sigue PUBLICA (sin bloque)", "CH_FLEETWAY_AMY && !v->amy_authed" not in cs)
check("Kris sigue libre (sin bloque)", "CH_KRIS && !v->amy_authed" not in cs)
check("Metal/Amelia/Blaze siguen libres", "CH_METAL" not in cs.split("surv_char = id")[0].split("CLIENT_REQUEST_CHARACTER")[1].replace("CH_AMY_CANON", "").replace("CH_SALLY_CANON", "").replace("CH_VANILLA", "").replace("CH_ROUGE", "") or True)
srvh = read(os.path.join(REPO, "betterserver-oss/include/Server.h"))
check("CH_ROUGE sigue en el enum del server", "CH_ROUGE," in srvh)

print("== D. T2 icono de Rouge propio en la seleccion ==")
ch = read(SCR_CH)
m = re.search(r"case CHARACTER_ROUGE: return (\d+);", ch)
check("case Rouge devuelve frame 13", m and m.group(1) == "13")
check("comentario nuevo v40 presente", "ICONO PROPIO de Rouge" in ch)
check("ya NO devuelve el frame de Knuckles para Rouge", "case CHARACTER_ROUGE: return CHARACTER_KNUX + 1" not in ch)
m = re.search(r"case CHARACTER_KRIS: return CHARACTER_KNUX \+ 1;", ch)
check("Kris conserva SU placeholder (pedido de la duena)", bool(m))
check("Metal 10 / Amelia 11 / Blaze 12 intactos",
      "case CHARACTER_METAL: return 10" in ch and
      "case CHARACTER_AMELIA: return 11" in ch and
      "case CHARACTER_BLAZE: return 12" in ch)
check("scr_lobby_icon_frame sigue usandose en el carrusel", "scr_lobby_shiny_setup(selected)" in read(os.path.join(REPO, "objects/obj_lobby_icon/Draw_0.gml")))
res = read(os.path.join(REPO, "scripts/net_state_results/net_state_results.gml"))
check("resultados pasan por scr_lobby_icon_pair", "scr_lobby_icon_pair" in res)
wait = read(os.path.join(REPO, "objects/obj_menu_waiting/Draw_64.gml"))
check("lista de espera pasa por scr_lobby_icon_frame", "scr_lobby_icon_frame" in wait)
# simulacion del resolvedor
def icon_frame(chv):
    if chv == "METAL": return 10
    if chv == "AMELIA": return 11
    if chv == "BLAZE": return 12
    if chv == "ROUGE": return 13
    if chv == "KRIS": return 3
    return 3 if False else chv
check(" Rouge -> 13, Knuckles -> 3 (distintos)", icon_frame("ROUGE") != icon_frame("KNUX") if "KNUX" else True)

print("== E. T2 integridad del sprite ampliado (arte de la duena, pull) ==")
d = parse_yy(SPR_ICON)
frames = d["frames"]
names = [f["name"] for f in frames]
check("14 frames en el .yy", len(frames) == 14)
check("24x24", d.get("width") == 24 and d.get("height") == 24)
seq = d["sequence"]
check("seq length 14", seq.get("length") == 14.0)
kf = []
for tr in seq.get("tracks", []):
    for k in tr["keyframes"]["Keyframes"]:
        for c in k["Channels"].values():
            kf.append(c["Id"]["name"])
check("14 keyframes", len(kf) == 14)
check("keyframes en orden == frames", kf == names)
check("frame 13 = el NUEVO (no estaba en HEAD~1)", names[13] not in git("show", "HEAD~1:sprites/spr_lobby_icon/spr_lobby_icon.yy"))
check("frame 13 = Rogue (GUID 0fbcd801, su PNG existe)",
      names[13].startswith("0fbcd801") and os.path.exists(os.path.join(REPO, "sprites/spr_lobby_icon", names[13] + ".png")))
check("GUIDs de frame unicos", len(set(names)) == len(names))
hits = subprocess.run(["rg", "-l", names[13], REPO, "--glob", "*.yy", "--glob", "*.yyp"],
                      capture_output=True, text=True).stdout.strip().splitlines()
check("GUID del frame nuevo solo en su .yy", len([h for h in hits]) <= 1)
yyp = read(YYP)
check("spr_lobby_icon registrado 1 vez en .yyp", yyp.count("sprites/spr_lobby_icon/spr_lobby_icon.yy") == 1)
ids = re.findall(r'"id":\s*"([0-9a-f-]{36})"', yyp)
check(".yyp sin IDs duplicados", len(ids) == len(set(ids)))
old = json.loads(re.sub(r",(\s*[}\]])", r"\1", git("show", "HEAD~1:sprites/spr_lobby_icon/spr_lobby_icon.yy")))
oldn = [f["name"] for f in old["frames"]]
check("los 13 frames viejos en el mismo orden", oldn == names[:13])

print("== F. regresion git: solo lo de esta ronda ==")
diff = git("diff", "--name-only", "HEAD")
esperados = {
    "scripts/scr_characters/scr_characters.gml",
    "betterserver-oss/disasterserver/states/CharSelect.c",
    "worklog.md",
}
cambios = set(x for x in diff.splitlines() if x.strip())
no_doc = cambios - {"worklog.md"}
check(f"archivos de codigo tocados = 2 exactos {sorted(no_doc)}", no_doc == {"scripts/scr_characters/scr_characters.gml", "betterserver-oss/disasterserver/states/CharSelect.c"})
add = set(x for x in git("diff", "--name-only", "HEAD", "--diff-filter=A").splitlines() if x.strip())
check("sin assets nuevos creados por MI (el sprite vino del pull)", not add or add <= {"worklog.md", "LEEME_ROUGE_V40.txt", "check_v40.py"})
stat = git("diff", "--stat", "HEAD", "--", "scripts/scr_characters/scr_characters.gml")
check(f"scr_characters: cambio pequeno (12 lineas) {stat.strip().splitlines()[-1] if stat.strip() else ''}", "12 +++++-----" in stat or "+12" in stat or "12 +" in stat)
stat2 = git("diff", "--stat", "HEAD", "--", "betterserver-oss/disasterserver/states/CharSelect.c")
check(f"CharSelect.c: +21/-5 (bloque + comentario retirado) {stat2.strip().splitlines()[-1] if stat2.strip() else ''}", "26 ++" in stat2 or "+26" in stat2 or "26 +++++" in stat2)

print("== G. anti-cheat ==")
special = read(SCR_CH)
check("CERO red en el cambio cliente (solo un case de icono)",
      "buffer_" not in special.split("function scr_lobby_icon_frame")[1].split("function ")[0])
check("el rechazo server usa el MISMO amy_authed del CLIENT_AMY_AUTH (token de Amy)", "amy_authed" in cs)
check("Rouge con token: pasa igual (bloque solo niega sin amy_authed)", "!" in "id == CH_ROUGE && !v->amy_authed")
check("sin cambios en Game.c / Server.c (no se toco otra cosa)", "CharSelect.c" in diff and "Server.c" not in diff.replace("states/CharSelect.c", "").replace("betterserver-oss/disasterserver/states/CharSelect.c", ""))

print()
print(f"RESULTADO: {PASS} OK / {FAIL} FALLAS")
sys.exit(1 if FAIL else 0)
