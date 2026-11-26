#!/usr/bin/env python3
"""check_v82.py - validador estatico de la v82 (FORMAS CYBER de Sally Canon + shader amy_cyber v3).

Uso:
    python3 check_v82.py                     (desde la raiz del zip extraido: solo chequeos de archivo)
    python3 check_v82.py <ruta_del_repo>     (repo completo con git: ademas diff de espacios y anclas)

Sale con exito 1 si hay algun [XX].
"""
import json
import os
import re
import subprocess
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else HERE
FULL = os.path.isdir(os.path.join(REPO, ".git"))
YYP = "Sonicexe The Disaster 2D Remake.yyp"

GML_FILES = [
    "objects/obj_amy_canon/Draw_0.gml",
    "objects/obj_netclient/Step_2.gml",
    "objects/obj_player_puppet/Create_0.gml",
    "objects/obj_player_puppet/Draw_0.gml",
    "objects/obj_player_puppet/Step_0.gml",
    "objects/obj_playerui/Draw_64.gml",
    "objects/obj_sally_canon/Create_0.gml",
    "objects/obj_sally_canon/Draw_0.gml",
    "objects/obj_sally_canon/Draw_64.gml",
    "scripts/net_udpprocess/net_udpprocess.gml",
    "scripts/scr_amy_cyber/scr_amy_cyber.gml",
    "scripts/scr_player_hurt/scr_player_hurt.gml",
    "scripts/scr_sally_special/scr_sally_special.gml",
]
SHADERS = [
    "shaders/shd_amy_cyber/shd_amy_cyber.fsh",
    "shaders/shd_amy_cyber/shd_amy_cyber.vsh",
]
CORE = ["scripts/scr_amy_cyber/scr_amy_cyber.gml"] + SHADERS
TAB_FILES = {"objects/obj_sally_canon/Draw_64.gml"}           # archivo indentado con TABs en origen
WS_ALLOWED = {                                                 # su stat cambia al ignorar espacios por motivos conocidos
    "objects/obj_player_puppet/Create_0.gml",                  # ultima linea sin salto (igual que el original)
    "objects/obj_sally_canon/Draw_0.gml",                      # 3 lineas con TAB pasadas a 8 espacios
    "scripts/scr_amy_cyber/scr_amy_cyber.gml",                 # reescrito entero
    "shaders/shd_amy_cyber/shd_amy_cyber.fsh",
    "shaders/shd_amy_cyber/shd_amy_cyber.vsh",
}
ASSETS = ["scr_amy_cyber", "shd_amy_cyber", "snd_parry", "snd_buble", "spr_gui_sallyshield", "fnt_big",
          "scr_sally_special", "scr_player_hurt", "net_udpprocess", "obj_player_puppet", "obj_netclient",
          "obj_playerui", "obj_sally_canon", "obj_amy_canon"]
MEMO_FILES = ["CACHE.md", "LEARNING.md", "worklog.md"]            # memoria que viaja en el zip (secciones v82)
LOOSE_OK = {"check_v82.py", "sim_v82.py", "LEEME_V82_SALLY_CYBER_FORMS.txt", "PREVIEW_V82.png", "tools_v82/"}   # herramientas del zip
UNIFORMS = ["u_Pattern", "u_Replacements", "u_ColourCount", "uTexel", "uTime", "uScan", "uSplit", "uGlitch",
            "uFlicker", "uAlpha", "uTint", "uSolid", "uHaloCol", "uGlow", "uDissolve", "uGrid", "uStream",
            "uBody", "uRect", "uRectOK", "uPivot", "uRot"]
V_BLOCK_VARS = ["revivalTimes", "isDead", "hp", "fase2State", "shockedTimer", "isHurt", "isAttacking",
                "isSliding", "isHiding", "isSpinCharging", "redRingTimer", "isZipline"]
CJK = re.compile(u"[\u3000-\u9fff\uff00-\uffef]")

OK = 0
BAD = 0


def res(state, msg):
    global OK, BAD
    if state:
        OK += 1
        print("[OK]   " + msg)
    else:
        BAD += 1
        print("[XX]   " + msg)


def skip(msg):
    print("[SKIP] " + msg)


def rd(rel):
    with open(os.path.join(REPO, rel), "rb") as fh:
        return fh.read()


def strip_gml(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '"' or c == "'":
            q = c
            i += 1
            while i < n and src[i] != q:
                if src[i] == "\\":
                    i += 1
                i += 1
            i += 1
            out.append('""')
        elif c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                i += 1
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def balance(code):
    mins = {"{": 0, "(": 0, "[": 0}
    cnt = {"{": 0, "(": 0, "[": 0}
    pairs = {"}": "{", ")": "(", "]": "["}
    for ch in code:
        if ch in cnt:
            cnt[ch] += 1
            if cnt[ch] == 1:
                pass
        elif ch in pairs:
            o = pairs[ch]
            cnt[o] -= 1
            if cnt[o] < mins[o]:
                mins[o] = cnt[o]
    return cnt, mins


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True).stdout


def numstat(args):
    out = {}
    for line in git("diff", "--numstat") if not args else git("diff", "--numstat", args):
        pass
    return out


def parse_numstat(text):
    out = {}
    for line in text.decode("utf-8", "replace").splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            out[parts[2]] = (parts[0], parts[1])
    return out


def first_idx(t, needle, label, res_list):
    k = t.find(needle)
    res_list.append((k >= 0, "ancla presente: " + label))
    return k


def main():
    global OK, BAD
    print("REPO = " + REPO + ("  (repo completo)" if FULL else "  (solo archivos del zip)"))
    raw = {}
    ok_files = True
    for rel in GML_FILES + SHADERS:
        p = os.path.join(REPO, rel)
        if not os.path.isfile(p):
            print("[XX]   falta el archivo " + rel)
            ok_files = False
        else:
            raw[rel] = rd(rel)
    res(ok_files, "existen los %d archivos GML/shader de la v82" % len(GML_FILES + SHADERS))
    if not ok_files:
        return finish()

    # ---------- 1. lexer + balance + trampas conocidas de GML ----------
    code = {}
    for rel in GML_FILES:
        src = raw[rel].decode("utf-8", "replace")
        c = strip_gml(src)
        code[rel] = c
        cnt, mins = balance(c)
        res(all(v == 0 for v in cnt.values()) and all(v == 0 for v in mins.values()),
            "llaves/parentesis/corchetes balanceados :: " + rel)
        res(re.search(r"\bbreak\s*:", c) is None, "sin 'break:' (rompe el compilador) :: " + rel)
        res("\r" not in src, "sin CRLF :: " + rel)
        res(CJK.search(src) is None, "sin caracteres CJK/fullwidth :: " + rel)
    for rel in SHADERS:
        src = raw[rel].decode("utf-8", "replace")
        res(CJK.search(src) is None, "sin caracteres CJK/fullwidth :: " + rel)

    # ternarios encadenados: en el nucleo entero y en las lineas anadidas de los ganchos
    def chained(text):
        bad = []
        for st in text.split(";"):
            if st.count("?") > 1:
                bad.append(st.strip().replace("\n", " ")[:70])
        return bad
    for rel in CORE[:1]:
        res(not chained(code[rel]), "sin ternarios encadenados en el nucleo :: " + rel)
    added = {}
    if FULL:
        for rel in GML_FILES:
            d = git("diff", "-U0", "--", rel).decode("utf-8", "replace")
            added[rel] = [l[1:] for l in d.splitlines() if l.startswith("+") and not l.startswith("+++")]
            res(not chained(strip_gml("\n".join(added[rel]))), "sin ternarios encadenados en las lineas nuevas :: " + rel)

    # ---------- 2. identificadores y macros ----------
    core = raw[CORE[0]].decode("utf-8")
    allgml = "\n".join(code.values())
    funcs_used = set(re.findall(r"\b(scr_sally_cyber_[a-z_]+|scr_amy_cyber[a-z_]*)(?=\s*\()", allgml))
    funcs_def = set(re.findall(r"(?m)^function\s+([A-Za-z0-9_]+)", core))
    res(funcs_used <= funcs_def, "todas las funciones scr_*cyber* usadas estan definidas (%d usadas, %d definidas): %s"
        % (len(funcs_used), len(funcs_def), ", ".join(sorted(funcs_def))))
    macros_used = set(re.findall(r"\b(SALLY_CYBER_[A-Z0-9_]+|AMY_CYBER_[A-Z0-9_]+)\b", allgml))
    defs = Counter()
    for base in ("objects", "scripts"):
        for root, _dirs, files in os.walk(os.path.join(REPO, base)):
            for fn in files:
                if fn.endswith(".gml"):
                    txt = strip_gml(open(os.path.join(root, fn), "rb").read().decode("utf-8", "replace"))
                    for m in re.findall(r"(?m)^#macro\s+([A-Za-z0-9_]+)", txt):
                        defs[m] += 1
    missing = sorted(m for m in macros_used if defs.get(m, 0) == 0)
    dup = sorted(m for m in macros_used if defs.get(m, 0) > 1)
    if missing:
        if FULL:
            res(False, "macros sin definicion: " + ", ".join(missing))
        else:
            skip("macros definidas en archivos que no van en el zip (normal fuera del repo): " + ", ".join(missing))
    else:
        res(True, "las %d macros SALLY_CYBER_*/AMY_CYBER_* usadas estan definidas" % len(macros_used))
    res(not dup, "ninguna macro de la v82 definida dos veces" + (": " + ", ".join(dup) if dup else ""))
    for want in ("SALLY_CYBER_SEMI_RESIST 0.35", "SALLY_CYBER_SEMI_SHIELD_EFF 0.45", "SALLY_CYBER_SEMI_HITBOX_MUL 1.45",
                 "SALLY_CYBER_FULL_RESIST 0.60", "SALLY_CYBER_FULL_SHIELD_EFF 0.70", "SALLY_CYBER_FULL_HITBOX_MUL 1.70"):
        name, val = want.split()
        res(re.search(r"(?m)^#macro\s+%s\s+%s\b" % (re.escape(name), re.escape(val)), core) is not None,
            "numero pedido por la duena tal cual :: " + want)
    res(re.search(r"(?m)^#macro\s+SALLY_CYBER_NET_TAG_A\s+201\b", core) is not None
        and re.search(r"(?m)^#macro\s+SALLY_CYBER_NET_TAG_B\s+171\b", core) is not None,
        "etiquetas de red 201/171 (no chocan con una forma 0..2)")

    # ---------- 3. variables que lee el bloque de la tecla V ----------
    sc = raw["objects/obj_sally_canon/Create_0.gml"].decode("utf-8")
    lack = [v for v in V_BLOCK_VARS if not re.search(r"(?m)^\s*(?:var\s+)?%s\s*=" % re.escape(v), sc)]
    res(not lack, "variables del bloque V declaradas en el Create de Sally Canon" + (": faltan " + ", ".join(lack) if lack else ""))
    res(re.search(r"(?m)^cyberForm\s*=\s*0;", sc) is not None and re.search(r"(?m)^cyberFlash\s*=\s*0;", sc) is not None,
        "cyberForm / cyberFlash creados en obj_sally_canon/Create_0")
    pc = raw["objects/obj_player_puppet/Create_0.gml"]
    res(pc.endswith(b"cyberForm = 0;") and not pc.endswith(b"\n"), "puppet Create_0: cyberForm = 0 al final y sin salto final (como el original)")

    # ---------- 4. anclas semanticas ----------
    hurt = raw["scripts/scr_player_hurt/scr_player_hurt.gml"].decode("utf-8")
    i_dead = first_idx(hurt, "if(global.player.isDead)", "guardia isDead (scr_player_hurt)", [])
    i_res = first_idx(hurt, "damage = max(1, round(damage * scr_sally_cyber_resist_mul(", "resistencia al dano (scr_player_hurt)", [])
    i_hold = first_idx(hurt, "scr_sally_cyber_shield_hold(scr_sally_cyber_form())", "escudo aguanta el golpe (scr_player_hurt)", [])
    i_v78 = first_idx(hurt, '// v78 (duena): "aumenta la invulerabilidad del escudo de', "comentario v78 (scr_player_hurt)", [])
    res(i_dead >= 0 and i_res > i_dead and i_hold > i_res and i_v78 > i_hold,
        "orden en scr_player_hurt: guardia isDead < resistencia < escudo-aguanta < bloque de romper escudo v78")
    res(hurt.count("scr_sally_cyber_shield_hold(") == 1 and hurt.count("scr_sally_cyber_resist_mul(") == 1,
        "resistencia y escudo-aguanta aparecen una sola vez (sin duplicados)")

    reader = raw["scripts/net_udpprocess/net_udpprocess.gml"].decode("utf-8")
    i_rd = first_idx(reader, "cyberForm = (_cyA == SALLY_CYBER_NET_TAG_A", "lector de la forma (net_udpprocess)", [])
    ok_last = False
    if i_rd >= 0:
        m = re.compile(r"(?m)^[ \t]*break;[ \t]*$").search(reader, i_rd)
        ok_last = bool(m) and "buffer_read" not in reader[i_rd:m.start()]
    res(ok_last, "la forma es la ULTIMA lectura del case CLIENT_PLAYER_DATA (3 bytes al final del paquete)")

    snd = raw["objects/obj_netclient/Step_2.gml"].decode("utf-8")
    a = snd.find("buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_A);")
    b = snd.find("buffer_write(buffer, buffer_u8, SALLY_CYBER_NET_TAG_B);")
    f = snd.find("buffer_write(buffer, buffer_u8, clamp(floor(cyberForm), 0, 2));")
    res(0 <= a < b < f and snd[a:f].count("buffer_write(") == 2
        and snd.count("SALLY_CYBER_NET_TAG_A);") == 1 and snd.count("SALLY_CYBER_NET_TAG_B);") == 1,
        "emisor: escribe TAG_A, TAG_B y forma (en ese orden, pegados) en obj_netclient/Step_2")

    draw_checks = [
        ("objects/obj_player_puppet/Draw_0.gml", "scr_amy_cyber_halo(character, _cySpr",
         "draw_sprite_ext(is_cheating ? spr_merfurmu : _poseBodySpr, _poseBodyIdx"),
        ("objects/obj_sally_canon/Draw_0.gml", "scr_amy_cyber_halo(global.character, _bodySpr",
         "draw_sprite_ext(_bodySpr, _bodyIdx, floor(x)"),
        ("objects/obj_amy_canon/Draw_0.gml", "scr_amy_cyber_halo(global.character, sprite_index", None),
    ]
    for rel, halo, body in draw_checks:
        t = raw[rel].decode("utf-8")
        ih = t.find(halo)
        m = re.search(r"\bscr_amy_cyber\(", t[ih:]) if ih >= 0 else None
        ic = ih + m.start() if m else -1
        if body is None:
            ib = t.find("draw_sprite_ext(", ic)
        else:
            ib = t.find(body)
        ireset = t.find("shader_reset()", ib)
        res(0 <= ih < ic < ib and ireset > ib and t.count("scr_amy_cyber_halo(") == 1,
            "orden de dibujo: glow (detras) < shader del cuerpo < draw_sprite_ext < shader_reset :: " + rel)
    amy = raw["objects/obj_amy_canon/Draw_0.gml"].decode("utf-8")
    res(amy.count("var _wss = scr_wss_draw();") == 1 and amy.count("scr_amy_cyber(") == 1,
        "obj_amy_canon/Draw_0: _wss declarado una sola vez y una sola llamada al shader")

    hud = raw["objects/obj_playerui/Draw_64.gml"].decode("utf-8")
    res(hud.count("spr_gui_sallyshield, scr_esbirro_hud(global.player), 19, global.KeyV, 10, 276 - _ico") == 1
        and "scr_sally_cyber_amy_present()" in hud and "global.KeyV, 10, 276 - _ico" in hud,
        "HUD: icono V de la forma en la fila libre (10, 276 - _ico), una sola vez")
    sp = raw["scripts/scr_sally_special/scr_sally_special.gml"].decode("utf-8")
    iv = sp.find("cyberForm = (cyberForm + 1) mod 3;")
    ic = sp.find("if(global.playerControls && keyboard_check_pressed(global.KeyC) && shieldRechrage <= 0)")
    res(0 <= iv < ic and sp.count("cyberForm = (cyberForm + 1) mod 3;") == 1
        and "if(global.character == CHARACTER_SALLY_CANON && SALLY_CYBER_ENABLED)" in sp
        and "scr_sally_cyber_shield_duration_mul(scr_sally_cyber_form())" in sp,
        "tecla V: ciclo 0->1->2->0 detras del gate de Sally Canon, antes del escudo; duracion del escudo multiplicada")
    st = raw["objects/obj_player_puppet/Step_0.gml"].decode("utf-8")
    res(st.count("scr_sally_cyber_hitbox_mul(cyberForm, revivalTimes >= 2)") == 2,
        "hitbox de la patada: pad normal + pad de la patada de fase 2 (obj_player_puppet/Step_0)")
    d64 = raw["objects/obj_sally_canon/Draw_64.gml"].decode("utf-8")
    res('draw_text_transformed_color(ceil(x - obj_camera.x), ceil(y - obj_camera.y) - offset + 12, _cyName, 0.4, 0.4, 0' in d64,
        "nombre de la forma bajo la vida (obj_sally_canon/Draw_64)")

    # ---------- 5. shaders ----------
    fsh = raw[SHADERS[0]].decode("utf-8")
    vsh = raw[SHADERS[1]].decode("utf-8")
    queried = re.findall(r'shader_get_uniform\(\s*shd\s*,\s*"([A-Za-z0-9_]+)"\s*\)', core)
    res(sorted(set(queried)) == sorted(UNIFORMS) and len(queried) == len(UNIFORMS),
        "el GML pide exactamente los %d uniforms previstos" % len(UNIFORMS))
    undeclared = [u for u in UNIFORMS if not re.search(r"\buniform\b[^;]*\b%s\b" % re.escape(u), fsh + ";" + vsh)]
    head_f, code_f = fsh.split("void main()", 1)
    used_f = set(re.findall(r"\b(u[A-Z][A-Za-z0-9_]*)\b", code_f))
    decl_f = set(re.findall(r"\buniform[^;{]*?\b([A-Za-z0-9_]+)\s*(?:\[\d+\])?\s*;", head_f))
    res(used_f <= decl_f, "todo uniform usado dentro del FRAGMENT shader esta declarado en el propio .fsh"
        + (": faltan " + ", ".join(sorted(used_f - decl_f)) if used_f - decl_f else " (%d declarados)" % len(decl_f)))
    head_v, code_v = vsh.split("void main()", 1)
    used_v = set(re.findall(r"\b(u[A-Z][A-Za-z0-9_]*)\b", code_v))
    decl_v = set(re.findall(r"\buniform[^;{]*?\b([A-Za-z0-9_]+)\s*;", head_v))
    res(used_v <= decl_v, "todo uniform usado dentro del VERTEX shader esta declarado en el propio .vsh"
        + (": faltan " + ", ".join(sorted(used_v - decl_v)) if used_v - decl_v else " (%d declarados)" % len(decl_v)))
    res(not undeclared, "todo uniform pedido esta declarado en .fsh/.vsh" + (": faltan " + ", ".join(undeclared) if undeclared else ""))
    res("varying vec2 v_vLocal;" in fsh and "varying vec2 v_vLocal;" in vsh, "varying v_vLocal declarado en ambos shaders")
    res("uniform highp float u_Pattern[256];" in fsh and "for(int i = 0; i < u_ColourCount; i++)" in fsh,
        "el palette swap sigue siendo el de shd_colour (u_Pattern[256] / u_ColourCount)")
    res(fsh.count("discard;") == 1 and "if(uSolid > 0.5)" in fsh and "gm_BaseTexture" in fsh,
        "modo silueta (uSolid) y un solo discard en el fragment shader")
    res(re.search(r"[^\x00-\x7f]", core + fsh + vsh) is None, "los 3 archivos del nucleo son ASCII puro (UTF-8 sin sorpresas)")

    # ---------- 6. yyp + assets ----------
    yyp_path = os.path.join(REPO, YYP)
    if os.path.isfile(yyp_path):
        txt = open(yyp_path, encoding="utf-8").read()
        try:
            load_json_loose(txt)
            res(True, YYP + " parsea como JSON")
        except Exception as exc:  # noqa
            res(False, YYP + " NO parsea: %s" % exc)
        names = set(re.findall(r'"name"\s*:\s*"([^"]+)"', txt))
        lack = [a for a in ASSETS if a not in names]
        res(not lack, "assets usados por la v82 registrados en el .yyp" + (": faltan " + ", ".join(lack) if lack else ""))
        pal = subprocess.run(["grep", "-rlE", "^function[[:space:]]+scr_palette_swap[[:space:]]*[(]", os.path.join(REPO, "scripts"),
                              os.path.join(REPO, "objects")], capture_output=True).stdout
        res(bool(pal.strip()), "scr_palette_swap (el palette swap de siempre) sigue definido en el repo")
    else:
        skip("sin .yyp en esta carpeta (normal en el zip: no se toco)")

    # ---------- 7. git: lista de archivos, espacios, anclas de sangria ----------
    if not FULL:
        skip("sin .git: no se compara contra HEAD (se hace en el roundtrip del repo completo)")
        return finish()
    st_lines = [l for l in git("status", "--porcelain").decode("utf-8", "replace").splitlines() if l.strip()]
    untracked = sorted(l[3:] for l in st_lines if l.startswith("??"))
    changed = sorted(l[3:] for l in st_lines if not l.startswith("??"))
    expected = sorted(GML_FILES + SHADERS + MEMO_FILES)
    res(changed == expected, "git status: exactamente los %d archivos de la v82 (%d de codigo + %d de memoria), nada mas (no .yyp/.yy)"
        % (len(expected), len(GML_FILES + SHADERS), len(MEMO_FILES)))
    res(set(untracked) <= LOOSE_OK, "sin archivos nuevos sin registrar salvo las herramientas del zip (%d)" % len(untracked))
    res(all(not c.endswith((".yyp", ".yy", ".resource_order")) for c in changed), "ningun .yyp / .yy / resource_order tocado")
    plain = parse_numstat(git("diff", "--numstat"))
    loose = parse_numstat(git("diff", "--numstat", "--ignore-all-space"))
    diff_ws = sorted(p for p in plain if plain[p] != loose.get(p))
    res(set(diff_ws) <= WS_ALLOWED, "cambios de solo-espacios unicamente donde esta previsto: " + ", ".join(diff_ws))
    for rel in GML_FILES + SHADERS:
        head = git("show", "HEAD:" + rel)
        work = raw[rel]
        problems = []
        if head.count(b"\r\n") == 0 and work.count(b"\r\n") > 0:
            problems.append("CRLF anadido")
        if head.endswith(b"\n") != work.endswith(b"\n") and rel not in WS_ALLOWED:
            problems.append("cambia el salto de linea final")
        h_tabs = sum(1 for l in head.split(b"\n") if l.startswith(b"\t"))
        w_tabs = sum(1 for l in work.split(b"\n") if l.startswith(b"\t"))
        if rel not in TAB_FILES and h_tabs == 0 and w_tabs > 0 and rel not in ("objects/obj_sally_canon/Draw_0.gml",):
            problems.append("TABs anadidos a un archivo de espacios")
        if rel in TAB_FILES:
            bad_indent = [l for l in added.get(rel, []) if l[:1] not in ("\t", "{", "}", "", "i", "/")]
            if bad_indent:
                problems.append("linea nueva sin TAB en archivo de TABs")
        else:
            bad_indent = [l for l in added.get(rel, []) if l[:1] in ("\t", " ")]
            wrong = [l for l in bad_indent if l[:1] == "\t"]
            if wrong:
                problems.append("linea nueva indentada con TAB en archivo de espacios: " + wrong[0][:40])
        if rel in CORE and work.count(b"\n\n\n") > 0:
            problems.append("dos lineas vacias seguidas en el nucleo")
        if rel not in CORE and work.count(b"\n\n\n") > head.count(b"\n\n\n"):
            problems.append("se anadio una linea vacia de mas")
        res(not problems, "perfil de espacios intacto :: " + rel + (("  -> " + "; ".join(problems)) if problems else ""))
    return finish()


def load_json_loose(txt):
    return json.loads(re.sub(r",\s*([\]}])", r"\1", txt))


def finish():
    print("RESULTADO: %d OK / %d BAD" % (OK, BAD))
    sys.exit(1 if BAD else 0)


if __name__ == "__main__":
    main()
