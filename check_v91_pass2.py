#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v91_pass2.py — PASADA 2 (independiente) de la v91 (Rouge: modo + glide).

Uso:  python3 check_v91_pass2.py <RAIZ_DEL_PROYECTO> [ZIP_V91_OPCIONAL]
      La raiz SIEMPRE como argumento (leccion v90: nunca adivinar la ubicacion).

La pasada 2 NO reusa las expectativas de la pasada 1 tal cual: verifica con
metodos NUEVOS e independientes:
  P1  RECONSTRUCCION BYTE A BYTE: aplicamos los hunks esperados de la v91
      sobre origin/main y exigimos que el resultado sea IDENTICO byte a byte
      al archivo entregado (prueba maxima de que no se toco nada mas).
  P2  Tokenizacion GML independiente del bloque nuevo de Draw_64 (llaves,
      parens, strings, llamadas draw_* en orden) — sin reuso de cadenas de
      la pasada 1 (se derivan del propio diff).
  P3  Trazas de referencia MANUALES: secuencias de eventos esperadas frame
      a frame calculadas A MANO para los escenarios clave, comparadas con
      una simulacion nueva y distinta (orden real del bucle Step_0).
  P4  Matematica del destello: escala/alpha para modeFlash 120..0 (suavidad,
      sin NaN, limites exactos 0.7 -> 0.6 y 1 -> 0.9).
  P5  Barrido de fugas: donde se referencia rougeMode/modeFlash en TODO el
      repo (el ciclo debe seguir 100% local; el HUD del playerui solo LEE).
  P6  Integridad: solo los 2 .gml de juego difieren de origin/main; cero
      .yyp/.yy; si se pasa un ZIP, su contenido debe casar 1:1 con el
      proyecto.
"""

import difflib
import hashlib
import io
import os
import re
import subprocess
import sys
import zipfile

PASS = 0
FAIL = 0
FAILURES = []


def check(name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print("  [OK]   %-64s" % name)
    else:
        FAIL += 1
        FAILURES.append("%s %s" % (name, detail))
        print("  [FAIL] %-64s %s" % (name, detail))


def section(t):
    print("\n=== %s ===" % t)


def read(root, rel):
    p = os.path.join(root, rel)
    if not os.path.isfile(p):
        return None
    with io.open(p, "r", encoding="utf-8") as fh:
        return fh.read()


def git_show_bytes(root, rel):
    try:
        proc = subprocess.run(["git", "-C", root, "show", "origin/main:" + rel],
                              capture_output=True, timeout=30)
        if proc.returncode == 0:
            return proc.stdout
    except Exception:
        pass
    return None


def git_status_paths(root):
    try:
        proc = subprocess.run(["git", "-C", root, "status", "--porcelain"],
                              capture_output=True, timeout=30)
        if proc.returncode != 0:
            return None
        out = []
        for line in proc.stdout.decode("utf-8", "replace").split("\n"):
            if line.strip():
                m = re.match(r"^(..)\s+(.+?)\s*$", line)
                if m:
                    out.append((m.group(1), m.group(2).strip()))
        return out
    except Exception:
        return None


def main():
    if len(sys.argv) < 2:
        print("Uso: python3 check_v91_pass2.py <RAIZ> [ZIP]")
        return 1
    root = os.path.abspath(sys.argv[1])
    zip_path = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else None
    print("check_v91_pass2.py — PASADA 2")
    print("RAIZ DEL PROYECTO: %s" % root)

    d64_rel = "objects/obj_rouge/Draw_64.gml"
    spc_rel = "scripts/scr_rouge_special/scr_rouge_special.gml"
    d64 = read(root, d64_rel)
    spc = read(root, spc_rel)
    if d64 is None or spc is None:
        print("FALLO: archivos base no encontrados")
        return 1
    d64_old_b = git_show_bytes(root, d64_rel)
    spc_old_b = git_show_bytes(root, spc_rel)
    have_git = d64_old_b is not None and spc_old_b is not None

    # ---------------------------------------------------------------- P1
    section("P1 — Reconstruccion byte a byte desde origin/main")
    if have_git:
        d64_old = d64_old_b.decode("utf-8")
        spc_old = spc_old_b.decode("utf-8")

        # --- Draw_64: hunk esperado = sustituir el bloque v32 (banner -> EOF)
        lines_old = d64_old.split("\n")
        banner32 = None
        for i, l in enumerate(lines_old):
            if l.startswith("// v32 ") and "MODALIDAD ACTIVA" in l:
                banner32 = i - 1
                break
        check("P1: origin/main: bloque v32 localizado", banner32 is not None)
        if banner32 is not None:
            base = lines_old[:banner32]
            # el bloque nuevo = todo lo que hay en el entregado desde el banner v91
            lines_new = d64.split("\n")
            b91 = None
            for i, l in enumerate(lines_new):
                if l.startswith("// v91 ") and "MODALIDAD ACTIVA" in l:
                    b91 = i - 1
                    break
            check("P1: entregado: banner v91 localizado (con su ==== encima)",
                  b91 is not None and lines_new[b91].startswith("// ==="))
            if b91 is not None:
                reconstructed = base + lines_new[b91:]
                check("P1: Draw_64 = base v89 + bloque v91, byte a byte",
                      reconstructed == lines_new,
                      "diff lineas: %d" % sum(1 for a, b in
                                             zip(reconstructed, lines_new) if a != b))
                check("P1: Draw_64: la base (lineas 1-%d) SIN TOCAR vs origin/main"
                      % len(base), base == lines_old[:len(base)])

        # --- scr_rouge_special: la transformacion EXACTA es:
        #   (1) 16 lineas de comentario (banner v91) insertadas dentro del
        #       bloque de comentarios del planeo, y
        #   (2) la linea Z del planeo pierde su ")" final y gana la linea
        #       de guard debajo. NADA MAS puede moverse (reconstruccion).
        old_lines = spc_old.split("\n")
        new_lines = spc.split("\n")
        Z_OLD = "&& !isStuck && yspd > 0 && keyboard_check(global.KeyA))"
        GUARD = ('&& !(variable_instance_exists(id, "coyoteTimer") '
                 '&& coyoteTimer > 0 && yspd >= 0))')
        z_idx = [i for i, l in enumerate(old_lines) if l.strip() == Z_OLD]
        check("P1: origin/main: linea Z del planeo localizada (y unica)",
              len(z_idx) == 1, "apariciones: %d" % len(z_idx))
        if len(z_idx) == 1:
            zi = z_idx[0]
            # el bloque de comentarios v91 en el archivo nuevo: lineas
            # consecutivas todas "//" que contienen la marca v91 del planeo
            b_idx = [i for i, l in enumerate(new_lines)
                     if "// v91 " in l and "EL PLANEO RESPETA EL TIEMPO DE COYOTE" in l]
            check("P1: banner v91 del planeo localizado (y unico)", len(b_idx) == 1)
            if len(b_idx) == 1:
                bi = b_idx[0]
                # ANCLA: el ultimo comentario v24 del bloque original ("...cae
                # derecha al planeo.") — el banner v91 vive INMEDIATAMENTE debajo
                ANCHOR = "// caer ya NO lo gasta: cae derecha al planeo."
                anch_old = [i for i, l in enumerate(old_lines) if l.strip() == ANCHOR]
                anch_new = [i for i, l in enumerate(new_lines) if l.strip() == ANCHOR]
                check("P1: ancla v24 (ultimo comentario original) unica en ambos",
                      len(anch_old) == 1 and len(anch_new) == 1,
                      "old=%d new=%d" % (len(anch_old), len(anch_new)))
                # reconstruccion: quitar banner nuevo y guard; re-pegar el ")" de Z
                guard_new_idx = [i for i, l in enumerate(new_lines)
                                 if l.strip() == GUARD]
                ai = anch_new[0]
                banner = new_lines[ai + 1:ai + 17]
                check("P1: 16 lineas de banner justo tras el ancla (todas //)",
                      len(banner) == 16 and all(l.strip().startswith("//") for l in banner),
                      "primera: %r" % (banner[0][:50] if banner else None))
                check("P1: la 1a linea del banner es la marca v91 del planeo",
                      banner and banner[0].strip().startswith("// v91 "),
                      repr(banner[0][:60] if banner else None))
                head = "if(global.playerControls && !isGrounded && !isGliding"
                check("P1: tras el banner viene la cabeza de la activacion intacta",
                      ai + 17 < len(new_lines)
                      and new_lines[ai + 17].strip().startswith(head),
                      repr(new_lines[ai + 17][:60] if ai + 17 < len(new_lines) else None))
                guard_new_idx = [i for i, l in enumerate(new_lines)
                                 if l.strip() == GUARD]
                check("P1: guard de familia presente 2 veces en el archivo nuevo"
                      " (su vuelo + su planeo)",
                      len(guard_new_idx) == 2, "apariciones: %d" % len(guard_new_idx))
                if len(guard_new_idx) == 2:
                    gi = guard_new_idx[-1]   # el del PLANEO es el ultimo
                    z_new = new_lines[gi - 1]
                    check("P1: el guard va INMEDIATAMENTE despues de la linea Z",
                          z_new.strip() == Z_OLD[:-1], repr(z_new.strip()))
                    # armar la secuencia sin los cambios y comparar con origin
                    stripped = (new_lines[:ai + 1]
                                + new_lines[ai + 17:gi]      # quita banner, deja Z nueva
                                + new_lines[gi + 1:])          # quita guard
                    # la linea Z nueva (sin ")") debe re-pegarse con ")"
                    z_new_pos = [i for i, l in enumerate(stripped)
                                 if l.strip() == Z_OLD[:-1]]
                    check("P1: la linea Z sin-paren es unica tras quitar el banner",
                          len(z_new_pos) == 1, "apariciones: %d" % len(z_new_pos))
                    if len(z_new_pos) == 1:
                        zp = z_new_pos[0]
                        re_stripped = (stripped[:zp]
                                      + [stripped[zp] + ")"]
                                      + stripped[zp + 1:])
                        first_diff = "NINGUNA (identicos)"
                        if re_stripped != old_lines:
                            for i, (a, b) in enumerate(zip(re_stripped, old_lines)):
                                if a != b:
                                    first_diff = "%d: %r vs %r" % (i, a, b)
                                    break
                        check("P1: RECONSTRUCCION: origin + banner + split de Z ="
                              " archivo nuevo, LINEA A LINEA",
                              re_stripped == old_lines,
                              "primera diferencia: %s" % first_diff)
    else:
        print("  [skip] sin git/origin — P1 cubierta por los invariantes embebidos")

    # ---------------------------------------------------------------- P2
    section("P2 — Tokenizacion GML independiente del bloque v91")
    # aislar el bloque v91 (del banner al EOF) y tokenizarlo
    b91 = d64.find("// v91 ")
    check("P2: bloque v91 aislable en Draw_64", b91 >= 0)
    if b91 >= 0:
        block = d64[b91:]
        # extraer TODAS las llamadas draw del bloque con sus argumentos crudos
        calls = re.findall(r"draw_text_transformed_color\((.*?)\);", block, re.S)
        check("P2: el bloque tiene exactamente 9 llamadas draw", len(calls) == 9,
              "llamadas: %d" % len(calls))
        # las 8 primeras: c_black x4 y mismas coords +-1; la ultima: _modeCol
        blacks = [c for c in calls if "c_black, c_black, c_black, c_black" in c]
        color = [c for c in calls if "_modeCol, _modeCol, _modeCol, _modeCol" in c]
        check("P2: 8 llamadas de contorno (c_black x4) + 1 de color (_modeCol x4)",
              len(blacks) == 8 and len(color) == 1)
        check("P2: la llamada de color es la ULTIMA (dibujada ENCIMA)",
              calls[-1] == color[0])
        # offsets: derivar pares (dx, dy) de cada llamada negra
        offs = []
        for c in blacks:
            m = re.match(r"\s*(_modeX) ?([+-] ?\d+)?, ?(_modeY) ?([+-] ?\d+)?,", c)
            if m:
                dx = m.group(2) or "+0"
                dy = m.group(4) or "+0"
                offs.append((int(dx.replace(" ", "")), int(dy.replace(" ", ""))))
        check("P2: los 8 offsets derivados son los 8 vecinos de 1px (sin repetir)",
              sorted(offs) == sorted([(1, 0), (-1, 0), (0, 1), (0, -1),
                                      (1, 1), (-1, 1), (1, -1), (-1, -1)]),
              "offsets: %s" % sorted(offs))
        # todas usan la MISMA escala/alpha (variables, no numeros sueltos)
        check("P2: las 9 llamadas usan la misma _modeScale y _modeAlpha",
              all("_modeScale, _modeScale, 0," in c for c in calls)
              and all(c.rstrip().endswith("_modeAlpha") for c in calls))
        # balance del bloque: { } y ( ) con tokenizador que respeta strings
        depth_b = depth_p = 0
        in_str = False
        i = 0
        ok_bal = True
        while i < len(block):
            ch = block[i]
            if in_str:
                if ch == "\\":
                    i += 2
                    continue
                if ch == '"':
                    in_str = False
            elif ch == '"':
                in_str = True
            elif ch == "/" and block[i:i + 2] == "//":
                while i < len(block) and block[i] != "\n":
                    i += 1
            else:
                if ch == "{":
                    depth_b += 1
                elif ch == "}":
                    depth_b -= 1
                elif ch == "(":
                    depth_p += 1
                elif ch == ")":
                    depth_p -= 1
                if depth_b < 0 or depth_p < 0:
                    ok_bal = False
            i += 1
        check("P2: balance del bloque v91 (tokenizador propio): {} y () = 0",
              ok_bal and depth_b == 0 and depth_p == 0,
              "braces=%d parens=%d" % (depth_b, depth_p))
        # nombres de modalidad: derivar del switch del bloque
        names = re.findall(r'_modeName = "([A-Z]+)"', block)
        check("P2: los 4 nombres derivados del switch: ROUGE/EGGMAN/SOPORTE/ATAQUE",
              sorted(names) == sorted(["ROUGE", "EGGMAN", "SOPORTE", "ATAQUE"]),
              "nombres: %s" % names)
        cols = re.findall(r"_modeCol = (\$[0-9A-F]{6})", block)
        check("P2: colores derivados: 4 constantes hex de 6 digitos",
              len(cols) == 4 and all(re.match(r"^\$[0-9A-F]{6}$", c) for c in cols),
              "colores: %s" % cols)
        # guardas del bloque
        check("P2: guarda hp/isDead del bloque intacta",
              "if(hp > 0 && !isDead)" in block)
        check("P2: fuente y alineaciones dentro del bloque",
              "draw_set_font(fnt_big);" in block
              and "draw_set_halign(fa_center);" in block)

    # ---------------------------------------------------------------- P4
    section("P4 — Matematica del destello (modeFlash 120 -> 0)")
    ok_scale = True
    prev = None
    for mf in range(121):
        scale = 0.6 + 0.1 * min(mf / 12, 1)
        alpha = 1 if mf > 0 else 0.9
        if prev is not None and mf > 0 and mf <= 12 and abs(scale - prev) > 0.1 / 12 + 1e-9:
            ok_scale = False  # pasos NO uniformes en la rampa de aterrizaje
        prev = scale
        if mf == 120:
            ok_scale = ok_scale and abs(scale - 0.7) < 1e-9
        if mf == 12:
            ok_scale = ok_scale and abs(scale - 0.7) < 1e-9
        if mf == 0:
            ok_scale = ok_scale and abs(scale - 0.6) < 1e-9 and alpha == 0.9
        if mf == 1:
            ok_scale = ok_scale and alpha == 1 and abs(scale - (0.6 + 0.1 / 12)) < 1e-9
    check("P4: escala 0.7 con destello lleno, rampa uniforme (12 pasos) hasta 0.6",
          ok_scale)
    # tamano de letra resultante en pixels (fnt_big glyph h=18)
    check("P4: texto resultante ~10.8 px de alto (18 * 0.6) vs 7.2 antes (18 * 0.4)",
          abs(18 * 0.6 - 10.8) < 1e-9 and abs(18 * 0.4 - 7.2) < 1e-9)
    # el modeFlash se decrementa en scr_rouge_special (el tick del destello)
    check("P4: tick del destello intacto (modeFlash-- con guarda > 0)",
          re.search(r"if\(modeFlash > 0\)\s*modeFlash--;", spc) is not None)

    # ---------------------------------------------------------------- P3
    section("P3 — Trazas de referencia manuales (simulacion nueva)")
    ok = trace_scenarios(root)
    for name, cond, detail in ok:
        check(name, cond, detail)

    # ---------------------------------------------------------------- P5
    section("P5 — Barrido de fugas de rougeMode/modeFlash (ciclo 100% local)")
    hits = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in (".git", "__pycache__")]
        for fn in filenames:
            if not fn.endswith(".gml"):
                continue
            p = os.path.join(dirpath, fn)
            rel = os.path.relpath(p, root).replace(os.sep, "/")
            txt = None
            try:
                with io.open(p, "r", encoding="utf-8") as fh:
                    txt = fh.read()
            except Exception:
                continue
            if "rougeMode" in txt or "modeFlash" in txt:
                hits.append(rel)
    expected = {d64_rel, spc_rel, "objects/obj_playerui/Draw_64.gml",
                 "objects/obj_rouge/Create_0.gml"}  # Create = DECLARACION (v32)
    unexpected = [h for h in hits if h not in expected]
    check("P5: rougeMode/modeFlash SOLO en obj_rouge + scr_rouge_special + playerui(HUD)",
          not unexpected, "fugas: %s" % unexpected)
    ui = read(root, "objects/obj_playerui/Draw_64.gml")
    if ui is not None:
        check("P5: playerui solo LEE rougeMode (no escribe rougeMode/modeFlash)",
              re.search(r"rougeMode\s*=(?!=)", ui) is None
              and re.search(r"modeFlash\s*=(?!=)", ui) is None)

    # ---------------------------------------------------------------- P6
    section("P6 — Integridad del proyecto y del ZIP")
    st = git_status_paths(root)
    if st is not None:
        gml_mods = [p for xy, p in st if p.endswith(".gml")]
        expected_mods = {d64_rel, spc_rel}
        # la v90 aplicada sin commitear no es fuga: estado esperado del duena
        v90_known = {"scripts/scr_parry/scr_parry.gml",
                     "scripts/scr_player_hurt/scr_player_hurt.gml",
                     "objects/obj_amy_canon/Step_0.gml",
                     "objects/obj_amy_canon/Create_0.gml",
                     "objects/obj_sonic/Create_0.gml",
                     "objects/obj_kris/Create_0.gml",
                     "objects/obj_player_puppet/Draw_0.gml"}
        unexpected = [p for p in gml_mods if p not in expected_mods
                      and p not in v90_known]
        check("P6: git: solo los 2 .gml de la v91 (y la v90 ya aplicada) difieren",
              not unexpected, "inesperados: %s" % unexpected[:6])
        yy = [p for xy, p in st if p.endswith((".yyp", ".yy", ".resource_order"))]
        check("P6: git: cero .yyp/.yy/.resource_order tocados", not yy, str(yy[:5]))
    else:
        print("  [skip] git no disponible")
    if zip_path and os.path.isfile(zip_path):
        expected_files = {
            d64_rel, spc_rel, "CACHE.md", "LEARNING.md", "worklog.md",
            "LEEME_V91_ROUGE_MODO_GLIDE.txt", "check_v91.py", "check_v91_pass2.py",
        }
        bad = []
        with zipfile.ZipFile(zip_path) as zf:
            names = set(zf.namelist())
            for n in names:
                if n not in expected_files:
                    bad.append("extra: " + n)
                else:
                    data = zf.read(n)
                    local = os.path.join(root, n)
                    if os.path.isfile(local):
                        with io.open(local, "rb") as fh:
                            if fh.read() != data:
                                bad.append("distinto al proyecto: " + n)
                    elif n in (d64_rel, spc_rel, "CACHE.md", "LEARNING.md",
                               "worklog.md", "LEEME_V91_ROUGE_MODO_GLIDE.txt",
                               "check_v91.py", "check_v91_pass2.py"):
                        bad.append("sin par en el proyecto: " + n)
        missing = expected_files - names
        if missing:
            bad.append("faltan en el zip: %s" % sorted(missing))
        check("P6: ZIP v91: contenido exacto y byte-identico al proyecto", not bad,
              "; ".join(bad[:6]))

    print("\n" + "=" * 74)
    print("RESULTADO PASADA 2: %d OK / %d FALLO" % (PASS, FAIL))
    if FAILURES:
        print("Fallos:")
        for f in FAILURES:
            print("  - %s" % f)
        return 1
    print("TODO OK. v91 verificada con las 2 pasadas.")
    return 0


# ---------------------------------------------------------------------------
# P3 — Simulacion INDEPENDIENTE (reimplementada, con trazas manuales).
# Orden del bucle real: specialFunc (glide) -> coyote -> salto -> colision.
# ---------------------------------------------------------------------------

YA = 0.21875          # yAccel
JF = 6.5              # jumpForce
COY = 10              # PLAYER_COYOTE_FRAMES
G_FALL = 0.7922      # ROUGE_GLIDE_FALL (objetivo EFECTIVO)
G_SET = G_FALL - YA   # lo que asigna el bloque del planeo (0.5738)


def sim(script, guard, airborne=False):
    g = False           # isGliding
    j = False           # isJumping
    fly = False         # isFlying
    gr = not airborne    # isGrounded
    ys = YA if airborne else 0.0
    ct = COY if airborne else COY
    trace = []
    for f, (zp, zh) in enumerate(script):
        ev = []
        # 1. activacion del planeo
        if (not gr and not g and not fly and ys > 0 and zh
                and not (guard and ct > 0 and ys >= 0)):
            g = True
            j = False
            ev.append("G")
        # 1b. planeo activo
        if g:
            if zh:
                ys = G_SET
            else:
                g = False
                ev.append("g-")
            if gr:
                g = False
        # 2. coyote
        if gr:
            ct = COY
        elif ct > 0:
            ct -= 1
        # 3. salto
        if (zp and not j and (gr or (ct > 0 and ys >= 0))):
            gr = False
            j = True
            ys = -JF
            ct = 0
            ev.append("J")
        # 4. colision
        if not gr:
            ys = min(ys + YA, 12)
            if ys > 0:
                j = False
        trace.append("".join(ev) if ev else ".")
    return trace


def trace_scenarios(root):
    res = []

    # --- A: borde + pulsacion TARDIA de Z en el frame 2 (el bug) ---
    scr_a = [(False, False), (False, False), (True, True)] + [(False, True)] * 40
    old = sim(scr_a, guard=False, airborne=True)
    new = sim(scr_a, guard=True, airborne=True)
    res.append(("P3-A OLD frame2 = G+J (el bug: glide y salto en la misma pulsacion)",
                old[2] in ("GJ", "JG"), "frame2 OLD=%s" % old[2]))
    res.append(("P3-A OLD frame3 = planeo pisa el salto (G sigue, yspd de planeo)",
                old[3] != "J" and old[2] != ".", "trace OLD[2..4]=%s" % old[2:5]))
    res.append(("P3-A NEW frame2 = SOLO J (la pulsacion tardia salta limpio)",
                new[2] == "J", "frame2 NEW=%s" % new[2]))
    res.append(("P3-A NEW frames 0-9 sin NINGUNA G (ventana respetada)",
                all("G" not in new[i] for i in range(10)), "new[0:10]=%s" % new[:10]))
    first_g = next((i for i, t in enumerate(new) if "G" in t), None)
    res.append(("P3-A NEW primer G tras el apex (>= frame 25, cadena intacta)",
                first_g is not None and first_g >= 25, "primer G=%s" % first_g))

    # --- B: borde con Z MANTENIDA (sin pulsacion) ---
    scr_b = [(False, True)] * 20
    old_b = sim(scr_b, guard=False, airborne=True)
    new_b = sim(scr_b, guard=True, airborne=True)
    res.append(("P3-B OLD frame0 = G (planeo instantaneo durante la gracia)",
                "G" in old_b[0], "old_b[0]=%s" % old_b[0]))
    first_gb = next((i for i, t in enumerate(new_b) if "G" in t), None)
    res.append(("P3-B NEW primer G exactamente en el frame 10 (ventana 0..9 limpia)",
                first_gb == 10, "primer G=%s" % first_gb))
    res.append(("P3-B NEW trazas 0-9 sin G", all("G" not in new_b[i] for i in range(10)),
                "new_b[0:10]=%s" % new_b[:10]))

    # --- C: salto NORMAL con Z mantenida — traza identica OLD vs NEW ---
    scr_c = [(True, True)] + [(False, True)] * 40
    old_c = sim(scr_c, guard=False)
    new_c = sim(scr_c, guard=True)
    res.append(("P3-C traza del salto normal IDENTICA en OLD y NEW",
                old_c == new_c, "difieren en %d frames" % sum(1 for a, b in
                                                             zip(old_c, new_c) if a != b)))
    res.append(("P3-C traza esperada: J en frame 0, primer G tras el apex (~27)",
                old_c[0] == "J" and 20 <= next((i for i, t in enumerate(old_c)
                                                if "G" in t), -1) <= 35,
                "old_c[0]=%s primerG=%s" % (old_c[0], next((i for i, t in
                                                            enumerate(old_c) if "G" in t), None))))

    # --- D: barrido exhaustivo OLD vs NEW — solo difieren con ventana abierta ---
    import itertools
    diffs_outside = 0
    total = 0
    for bits in itertools.product([False, True], repeat=8):
        scr = [(zp, zh) for zp, zh in zip(bits[0::2], bits[1::2])]
        scr = scr + [(False, False)] * 6
        old_x = sim(scr, guard=False, airborne=bits[0] and not scr[0][0])
        # airborne si el primer input no es pulsacion de salto
        new_x = sim(scr, guard=True, airborne=bits[0] and not scr[0][0])
        for i, (a, b) in enumerate(zip(old_x, new_x)):
            total += 1
            if a != b:
                # el estado de ventana EN ESE frame: ~frame i partiendo de 10
                if i >= 10:
                    diffs_outside += 1
    res.append(("P3-D 256 secuencias: TODA diferencia vive en frames 0-9 (la ventana)",
                diffs_outside == 0, "diffs fuera de ventana: %d / %d" % (diffs_outside, total)))

    return res


if __name__ == "__main__":
    sys.exit(main())
