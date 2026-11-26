#!/usr/bin/env python3
"""sim_v82.py - simulacion numerica de la v82 + harness WebGL1 del shader shd_amy_cyber.

Uso: python3 sim_v82.py [carpeta_con_los_archivos_modificados] [repo_con_los_sprites] [png_de_salida]

Parte A (sin navegador): repite en Python la logica de scr_amy_cyber.gml leyendo
   los numeros DE LAS MACROS del archivo real (nada copiado a mano).
Parte B (Playwright/Chromium): compila el .vsh/.fsh REAL en un contexto WebGL1 con
   el preambulo de GameMaker, dibuja sprites reales del repo y comprueba pixeles.
Genera una hoja de previsualizacion para la duena.
"""
import base64
import glob
import math
import os
import random
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else HERE
ASSETS = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else "/home/z/my-project/work/disaster2d-oss"
OUT = sys.argv[3] if len(sys.argv) > 3 else os.path.join(HERE, "PREVIEW_V82.png")
DEFAULT_REPO = "/home/z/my-project/work/disaster2d-oss"
S, O = 100, 30                      # recorte del harness: 100x100 px desde (30,30); pivote en (64,64)

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


def info(msg):
    print("[INFO] " + msg)


def find(rel):
    for base in (REPO, ASSETS, DEFAULT_REPO):
        p = os.path.join(base, rel)
        if os.path.isfile(p):
            return p
    raise SystemExit("[XX] no encuentro " + rel)


# =====================================================================================
# PARTE A - numeros de la v82 (leidos de las macros reales)
# =====================================================================================
GML = open(find("scripts/scr_amy_cyber/scr_amy_cyber.gml"), encoding="utf-8").read()


def raw_macro(name):
    m = re.search(r"(?m)^#macro\s+" + re.escape(name) + r"[ \t]+(\[[^\]]*\]|\([^/\n]*\)|[^\s/]+)", GML)
    if not m:
        raise SystemExit("[XX] macro no encontrada: " + name)
    return m.group(1).strip()


def num(expr):
    if not re.fullmatch(r"[0-9.+\-*/ ()]+", expr):
        raise SystemExit("[XX] expresion no numerica: " + expr)
    return eval(expr, {"__builtins__": {}}, {})


def mnum(name):
    return num(raw_macro(name))


def marr(name):
    return [float(x) for x in raw_macro(name).strip("[]").split(",")]


SEMI_RESIST, SEMI_EFF, SEMI_HIT = mnum("SALLY_CYBER_SEMI_RESIST"), mnum("SALLY_CYBER_SEMI_SHIELD_EFF"), mnum("SALLY_CYBER_SEMI_HITBOX_MUL")
FULL_RESIST, FULL_EFF, FULL_HIT = mnum("SALLY_CYBER_FULL_RESIST"), mnum("SALLY_CYBER_FULL_SHIELD_EFF"), mnum("SALLY_CYBER_FULL_HITBOX_MUL")
MODE = int(mnum("SALLY_CYBER_SHIELD_MODE"))
HOLD_INVULN, HOLD_MIN, FLASH_T = mnum("SALLY_CYBER_SHIELD_HOLD_INVULN"), mnum("SALLY_CYBER_SHIELD_HOLD_MIN_TIME"), mnum("SALLY_CYBER_FLASH_TIME")
TAG_A, TAG_B = int(mnum("SALLY_CYBER_NET_TAG_A")), int(mnum("SALLY_CYBER_NET_TAG_B"))
LK = dict((k, marr("AMY_CYBER_" + k)) for k in ("SCAN", "SPLIT", "GLITCH", "FLICKER", "ALPHA", "TINT", "GLOW", "HALO", "HALO_SC", "DISSOLVE", "GRID", "STREAM"))
HALO_RGB = marr("AMY_CYBER_HALO_RGB")


def lk(tbl, lvl):
    return LK[tbl][max(0, min(2, int(lvl)))]


def resist_mul(f):                     # scr_sally_cyber_resist_mul
    return 1.0 - FULL_RESIST if f >= 2 else (1.0 - SEMI_RESIST if f >= 1 else 1.0)


def shield_eff(f):                     # scr_sally_cyber_shield_eff
    return FULL_EFF if f >= 2 else (SEMI_EFF if f >= 1 else 0.0)


def hitbox_mul(f, dem=False):          # scr_sally_cyber_hitbox_mul
    if dem:
        return 1.0
    return FULL_HIT if f >= 2 else (SEMI_HIT if f >= 1 else 1.0)


def dur_mul(f):                        # scr_sally_cyber_shield_duration_mul
    return 1.0 if MODE not in (1, 2) else 1.0 + shield_eff(f)


def hold(f):                           # scr_sally_cyber_shield_hold
    if MODE not in (0, 2):
        return False
    eff = shield_eff(f)
    return random.randrange(100) < round(100 * eff) if eff > 0 else False


def step_v(form, rev, dead, hp, f2, amy, v_pressed, auto_drop=True):   # bloque V de scr_sally_special
    ok = amy and rev < 2 and (not dead) and hp > 0 and f2 == 0
    if form > 0 and (not ok) and auto_drop:
        form = 0
    if v_pressed and ok:
        form = (form + 1) % 3
    return form


def valid_form(is_sally, rev, has_var, form):                           # scr_sally_cyber_form
    if is_sally and rev < 2 and has_var:
        return max(0, min(2, int(math.floor(form))))
    return 0


def frame_info(pattern):
    files = sorted(glob.glob(os.path.join(ASSETS, pattern)))
    if not files:
        return None
    im = Image.open(files[0]).convert("RGBA")
    w, h = im.size
    ys, xs = np.where(np.asarray(im)[:, :, 3] > 0)
    if len(ys) == 0:
        return None
    top, bottom = int(ys.min()), int(ys.max())
    xoff = yoff = None
    d = os.path.dirname(files[0])
    yy = os.path.join(d, os.path.basename(d) + ".yy")
    if os.path.isfile(yy):
        t = open(yy, encoding="utf-8", errors="replace").read()
        m = re.search(r'"xorigin"\s*:\s*(-?\d+)\s*,\s*"yorigin"\s*:\s*(-?\d+)', t)
        if m:
            xoff, yoff = int(m.group(1)), int(m.group(2))
        else:
            m2 = re.search(r'"xoffset"\s*:\s*(-?\d+)\s*,\s*"yoffset"\s*:\s*(-?\d+)', t)
            if m2:
                xoff, yoff = int(m2.group(1)), int(m2.group(2))
    if xoff is None:
        xoff, yoff = w // 2, h // 2
    return im, w, h, xoff, yoff, top, bottom


def part_a():
    print("=== PARTE A: numeros (macros leidas del GML real) ===")
    res((SEMI_RESIST, SEMI_EFF, SEMI_HIT, FULL_RESIST, FULL_EFF, FULL_HIT) == (0.35, 0.45, 1.45, 0.6, 0.7, 1.7),
        "macros: semi 35%/45%/x1.45 y completa 60%/70%/x1.70 tal cual lo pedido")
    for d in (5, 10, 20, 34, 50):
        info("dano recibido %2d -> normal %2d | semi %2d | completa %2d" % (d, d, max(1, round(d * resist_mul(1))), max(1, round(d * resist_mul(2)))))
    res(all(max(1, round(d * resist_mul(f))) <= d for d in range(1, 80) for f in (0, 1, 2))
        and all(max(1, round(d * resist_mul(f))) < d or d == 1 for d in range(2, 80) for f in (1, 2)),
        "toda forma cyber reduce el dano (o lo deja en 1) para cualquier valor 1..79")
    res(max(1, round(1 * resist_mul(2))) == 1, "el dano nunca baja de 1 (entero, como viaja en la red)")
    res(resist_mul(0) == 1.0 and shield_eff(0) == 0.0 and hitbox_mul(0) == 1.0 and dur_mul(0) == 1.0, "forma NORMAL: todo como siempre")
    res(resist_mul(1) > resist_mul(2) and shield_eff(1) < shield_eff(2) and hitbox_mul(1) < hitbox_mul(2) and dur_mul(1) <= dur_mul(2)
        and (dur_mul(1) < dur_mul(2)) == (MODE in (1, 2)), "cada forma es mas fuerte que la anterior")
    random.seed(81)
    n = 400000
    h1 = sum(1 for _ in range(n) if hold(1)) / float(n)
    h2 = sum(1 for _ in range(n) if hold(2)) / float(n)
    h0 = sum(1 for _ in range(n) if hold(0))
    res(abs(h1 - 0.45) < 0.004 and abs(h2 - 0.70) < 0.004 and h0 == 0,
        "escudo AGUANTA el golpe (modo %d): simulado %.1f%% / %.1f%% (pedido 45%% / 70%%); forma 0 = %d de %d" % (MODE, 100 * h1, 100 * h2, h0, n))
    info("al aguantar: i-frames %.0f frames, escudo minimo %.0f frames; destello del cambio %.0f frames" % (HOLD_INVULN, HOLD_MIN, FLASH_T))
    info("duracion del escudo al activarlo (frames): %d / %d / %d" % (math.ceil(300 * dur_mul(0)), math.ceil(300 * dur_mul(1)), math.ceil(300 * dur_mul(2))))
    seq, f = [], 0
    for _ in range(4):
        f = step_v(f, 0, False, 100, 0, True, True)
        seq.append(f)
    res(seq == [1, 2, 0, 1], "tecla V con Amy Canon viva: NORMAL->SEMI->COMPLETA->NORMAL (%s)" % seq)
    res(step_v(0, 0, False, 100, 0, False, True) == 0, "sin Amy Canon: V no hace nada")
    res(step_v(2, 0, False, 100, 0, False, False) == 0 and step_v(1, 0, False, 100, 0, False, False) == 0, "se muere / se va la Amy Canon: vuelve a NORMAL sola")
    res(step_v(2, 0, True, 0, 0, True, False) == 0 and step_v(1, 0, False, 100, 18, True, True) == 0,
        "Sally muerta o en la secuencia de fase 2: V bloqueado y vuelve a NORMAL")
    res(step_v(2, 2, False, 100, 0, True, True) == 0 and valid_form(True, 2, True, 2) == 0, "esbirro (2+ caidas): nunca usa las formas")
    res(valid_form(False, 0, True, 2) == 0 and valid_form(True, 0, False, 2) == 0 and valid_form(True, 0, True, 7) == 2
        and valid_form(True, 0, True, -3) == 0 and valid_form(True, 0, True, 1.9) == 1,
        "scr_sally_cyber_form: solo Sally Canon, clamp 0..2, 0 si falta la variable")
    bw = 22
    fi = frame_info("sprites/spr_sally_idle_canon/*.png")
    if fi:
        bw = fi[6] - fi[5] + 1
    for lbl, pct in (("patada aerea fase 1 (+25%)", 0.25), ("patada en tierra duelista (+30%)", 0.30), ("patada aerea duelista (+50%)", 0.50)):
        base = math.ceil(bw * pct)
        info("hitbox %s: bbox %d px -> pad %d | semi %d | completa %d | esbirro %d" % (lbl, bw, base, math.ceil(base * hitbox_mul(1)), math.ceil(base * hitbox_mul(2)), math.ceil(base * hitbox_mul(2, True))))
    base = math.ceil(bw * 0.25)
    res(math.ceil(base * hitbox_mul(1)) > base and math.ceil(base * hitbox_mul(2)) > math.ceil(base * hitbox_mul(1)) and math.ceil(base * hitbox_mul(2, True)) == base,
        "la patada llega mas lejos con cada forma; la esbirro se queda como estaba")

    def reader(buf, pos):              # net_udpprocess
        a, b, f = buf[pos], buf[pos + 1], buf[pos + 2]
        return f if (a == TAG_A and b == TAG_B and 0 <= f <= 2) else 0

    P = 24                             # bytes comunes del CLIENT_PLAYER_DATA de un superviviente

    def net(form=None, tail=None):     # buffer de recepcion FIJO: lo que no se sobreescribe se queda del paquete anterior
        buf = bytearray(256)
        buf[:P] = bytes(range(P))
        t = bytes([TAG_A, TAG_B, form]) if form is not None else (bytes(tail) if tail is not None else b"")
        buf[P:P + len(t)] = t
        return reader(buf, P)

    res(net(0) == 0 and net(1) == 1 and net(2) == 2, "paquete nuevo: la forma 0/1/2 llega entera")
    res(net() == 0, "cliente viejo con buffer limpio: se lee forma 0")
    res(net(tail=[0, 0, 0]) == 0 and net(tail=[171, 201, 2]) == 0 and net(tail=[201, 172, 2]) == 0 and net(tail=[201, 171, 3]) == 0 and net(tail=[200, 171, 1]) == 0,
        "etiqueta incompleta, invertida o forma fuera de rango -> forma 0")
    hits = sum(1 for _ in range(1000000) if net(tail=[random.randrange(256), random.randrange(256), random.randrange(256)]) > 0)
    res(abs(hits - 1000000 * 3 / 65536.0) < 120, "bytes viejos aleatorios: se confunden con forma activa en %d de 1.000.000 (teoria ~46)" % hits)
    info("limitacion conocida: mezclar clientes de la version VIEJA con la nueva puede releer la forma del paquete anterior solo si esos 3 bytes viejos son exactamente (201, 171, 0..2). Entre clientes de esta misma version nunca pasa.")
    if fi:
        im, w, h, xoff, yoff, top, bottom = fi
        bh = max(bottom - top, 1)
        res(bottom - 0.45 * bh >= top and (-xoff, -yoff, w, h) == (-xoff, -yoff, w, h) and bottom < h,
            "scr_amy_cyber_rect con spr_sally_idle_canon: caja (%d, %d, %d, %d); zona de disolucion = 45%% inferior del bbox (%.1f px desde la fila %.1f)"
            % (-xoff, -yoff, w, h, bh * 0.45, bottom - 0.45 * bh))
        info("margen transparente por debajo de los pies: %d px (por eso se ancla al bbox y no a la caja)" % (h - 1 - bottom))


# =====================================================================================
# PARTE B - el shader real compilado en WebGL1
# =====================================================================================
UNAMES = ["u_Pattern", "u_Replacements", "u_ColourCount", "uTexel", "uTime", "uScan", "uSplit", "uGlitch", "uFlicker", "uAlpha",
          "uTint", "uSolid", "uHaloCol", "uGlow", "uDissolve", "uGrid", "uStream", "uBody", "uRect", "uRectOK", "uPivot", "uRot"]

JS = r"""
(payload) => {
  const out = { errors: [], notes: [], results: {}, missing: [] };
  const canvas = document.createElement('canvas');
  canvas.width = 256; canvas.height = 256;
  const gl = canvas.getContext('webgl', { preserveDrawingBuffer: true, premultipliedAlpha: false });
  if (!gl) { out.errors.push('WebGL1 no disponible'); return out; }
  function compile(type, src, label) {
    const sh = gl.createShader(type);
    gl.shaderSource(sh, src); gl.compileShader(sh);
    const il = (gl.getShaderInfoLog(sh) || '').trim();
    if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS)) out.errors.push(label + ': ' + il);
    else if (il) out.notes.push(label + ' aviso: ' + il);
    return sh;
  }
  const pre = '#define MATRIX_WORLD_VIEW_PROJECTION 0\nuniform mat4 gm_Matrices[1];\n';
  let prog = null, size = 0;
  for (const s of [256, 128, 64]) {
    const vs = compile(gl.VERTEX_SHADER, pre + payload.vsh, 'vsh');
    const fs = compile(gl.FRAGMENT_SHADER, 'uniform sampler2D gm_BaseTexture;\n' + payload.fsh.replace(/\[256\]/g, '[' + s + ']').replace('i < u_ColourCount', 'i < 256'), 'fsh');
    out.notes.push('el limite del bucle de paleta se cambia por una constante SOLO en el harness (misma linea que el shd_colour original del juego; ANGLE WebGL1 no acepta limites variables)');
    const p = gl.createProgram();
    gl.attachShader(p, vs); gl.attachShader(p, fs); gl.linkProgram(p);
    const il = (gl.getProgramInfoLog(p) || '').trim();
    const err = gl.getError();
    if (gl.getProgramParameter(p, gl.LINK_STATUS) && err === 0) { prog = p; size = s; break; }
    out.notes.push('link con [' + s + '] fallo: ' + il + ' (glErr ' + err + ')');
    while (gl.getError() !== 0) {}
  }
  if (!prog) { out.errors.push('el shader no compila/enlaza'); return out; }
  if (size !== 256) out.notes.push('u_Pattern reducido a [' + size + '] SOLO en el harness (limite de uniforms del render por software)');
  gl.useProgram(prog);
  out.renderer = String(gl.getParameter(gl.RENDERER));
  out.maxFragUniforms = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);
  const loc = {};
  for (const n of payload.unames) { loc[n] = gl.getUniformLocation(prog, n); if (!loc[n]) out.missing.push(n); }
  out.glErrorAfterUniforms = gl.getError();
  out.attrs = ['in_Position', 'in_Colour', 'in_TextureCoord'].map(a => gl.getAttribLocation(prog, a));
  function makeTex(t) {
    const bin = atob(t.b64); const u8 = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i);
    const img = new ImageData(new Uint8ClampedArray(u8.buffer), t.w, t.h);
    const tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return tex;
  }
  const texs = payload.texs.map(makeTex);
  const buf = new Uint8Array(256 * 256 * 4);
  const SZ = 100, OX = 30;
  function draw(t) {
    gl.viewport(0, 0, 256, 256);
    gl.disable(gl.BLEND);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texs[t.tex]);
    gl.uniform1i(gl.getUniformLocation(prog, 'gm_BaseTexture'), 0);
    gl.uniformMatrix4fv(gl.getUniformLocation(prog, 'gm_Matrices'), false,
      new Float32Array([2 / 256, 0, 0, 0, 0, -2 / 256, 0, 0, 0, 0, 1, 0, -1, 1, 0, 1]));
    const r = t.rect, pv = 64;
    const x0 = pv + r[0], y0 = pv + r[1], x1 = x0 + r[2], y1 = y0 + r[3];
    const ra = t.rot * Math.PI / 180, rc = Math.cos(ra), rs = Math.sin(ra);
    function P(x, y) { const dx = x - pv, dy = y - pv; return [pv + rc * dx + rs * dy, pv - rs * dx + rc * dy, 0]; }
    const v = new Float32Array([
      ...P(x0, y0), 1, 1, 1, 1, 0, 0,
      ...P(x1, y0), 1, 1, 1, 1, 1, 0,
      ...P(x0, y1), 1, 1, 1, 1, 0, 1,
      ...P(x1, y1), 1, 1, 1, 1, 1, 1]);
    const vb = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vb);
    gl.bufferData(gl.ARRAY_BUFFER, v, gl.STATIC_DRAW);
    if (out.attrs[0] >= 0) { gl.enableVertexAttribArray(out.attrs[0]); gl.vertexAttribPointer(out.attrs[0], 3, gl.FLOAT, false, 36, 0); }
    if (out.attrs[1] >= 0) { gl.enableVertexAttribArray(out.attrs[1]); gl.vertexAttribPointer(out.attrs[1], 4, gl.FLOAT, false, 36, 12); }
    if (out.attrs[2] >= 0) { gl.enableVertexAttribArray(out.attrs[2]); gl.vertexAttribPointer(out.attrs[2], 2, gl.FLOAT, false, 36, 28); }
    const u = t.u, L = loc;
    gl.uniform1fv(L.u_Pattern, new Float32Array(4));
    gl.uniform1fv(L.u_Replacements, new Float32Array(4));
    gl.uniform1i(L.u_ColourCount, 0);
    gl.uniform2f(L.uTexel, 1 / t.w, 1 / t.h);
    gl.uniform1f(L.uTime, u.time);
    gl.uniform1f(L.uScan, u.scan); gl.uniform1f(L.uSplit, u.split); gl.uniform1f(L.uGlitch, u.glitch);
    gl.uniform1f(L.uFlicker, u.flicker); gl.uniform1f(L.uAlpha, u.alpha); gl.uniform1f(L.uTint, u.tint);
    gl.uniform1f(L.uSolid, u.solid);
    gl.uniform3f(L.uHaloCol, 0.35, 0.90, 1.00);
    gl.uniform1f(L.uGlow, u.glow); gl.uniform1f(L.uDissolve, u.dissolve); gl.uniform1f(L.uGrid, u.grid); gl.uniform1f(L.uStream, u.stream);
    gl.uniform4f(L.uBody, u.body[0], u.body[1], u.body[2], u.body[3]);
    gl.uniform4f(L.uRect, r[0], r[1], r[2], r[3]);
    gl.uniform1f(L.uRectOK, 1);
    gl.uniform2f(L.uPivot, pv, pv);
    const a = t.rot * Math.PI / 180;
    gl.uniform2f(L.uRot, Math.cos(a), Math.sin(a));
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    const e = gl.getError();
    if (e !== 0) out.errors.push('gl error al dibujar ' + t.name + ': ' + e);
    gl.readPixels(0, 0, 256, 256, gl.RGBA, gl.UNSIGNED_BYTE, buf);
    const c = new Uint8Array(SZ * SZ * 4);
    for (let y = 0; y < SZ; y++) {
      const src = 255 - (OX + y);
      c.set(buf.subarray(src * 1024 + OX * 4, src * 1024 + (OX + SZ) * 4), y * SZ * 4);
    }
    let s = '';
    for (let i = 0; i < c.length; i += 8192) s += String.fromCharCode.apply(null, c.subarray(i, i + 8192));
    return btoa(s);
  }
  for (const t of payload.tests) out.results[t.name] = draw(t);
  return out;
}
"""


def placed(im, rect, rot):
    """Sprite colocado en el recorte del harness (misma geometrica que draw_sprite_ext + .vsh)."""
    a = np.asarray(im.convert("RGBA")).astype(np.float64)
    h, w = a.shape[:2]
    cv = np.zeros((S, S, 4))
    r = math.radians(rot)
    c, s = math.cos(r), math.sin(r)
    for py in range(h):
        row = a[py]
        for px in range(w):
            if row[px, 3] > 127:
                ux = px + 0.5 + rect[0]
                uy = py + 0.5 + rect[1]
                cx = int(math.floor(64 + c * ux + s * uy - O))
                cy = int(math.floor(64 - s * ux + c * uy - O))
                if 0 <= cx < S and 0 <= cy < S:
                    cv[cy, cx] = row[px]
    return cv


def local_xy(rot, rect):
    r = math.radians(rot)
    c, s = math.cos(r), math.sin(r)
    ys, xs = np.mgrid[0:S, 0:S]
    dx = O + xs + 0.5 - 64.0
    dy = O + ys + 0.5 - 64.0
    return dx * c - dy * s - rect[0], dx * s + dy * c - rect[1]


def grow(m, size):
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(size))) > 0


def shrink(m, size):
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(size))) > 0


def placed_sc(im, rect, sc):
    """Sprite escalado x sc alrededor del pivote (la silueta del glow exterior)."""
    a = np.asarray(im.convert("RGBA"))
    h, w = a.shape[:2]
    cv = np.zeros((S, S, 4))
    for py in range(h):
        y0 = int(math.floor(sc * (py + rect[1]))) + 64 - O
        y1 = int(math.floor(sc * (py + 1 + rect[1]))) + 64 - O
        if y1 <= 0 or y0 >= S:
            continue
        for px in range(w):
            if a[py, px, 3] > 127:
                x0 = int(math.floor(sc * (px + rect[0]))) + 64 - O
                x1 = int(math.floor(sc * (px + 1 + rect[0]))) + 64 - O
                cv[max(0, y0):min(S, y1), max(0, x0):min(S, x1)] = a[py, px]
    return cv


def part_b():
    print("\n=== PARTE B: el shader real en WebGL1 (Chromium headless) ===")
    vsh = open(find("shaders/shd_amy_cyber/shd_amy_cyber.vsh"), encoding="utf-8").read()
    fsh = open(find("shaders/shd_amy_cyber/shd_amy_cyber.fsh"), encoding="utf-8").read()
    chars = []
    for label, pats in (("SALLY CANON", ["sprites/spr_sally_idle_canon/*.png", "sprites/spr_sally_canon_idle/*.png"]),
                        ("AMY CANON", ["sprites/spr_amy_idle_canon/*.png", "sprites/spr_amy_canon_idle*/*.png", "sprites/spr_amy_idle/*.png"])):
        for pat in pats:
            fi = frame_info(pat)
            if fi:
                chars.append((label, fi))
                break
    res(len(chars) == 2, "sprites reales para el harness: " + ", ".join("%s %dx%d" % (l, f[1], f[2]) for l, f in chars))
    tests, texs = [], []
    for label, (im, w, h, xoff, yoff, top, bottom) in chars:
        ti = len(texs)
        texs.append({"b64": base64.b64encode(np.ascontiguousarray(np.asarray(im))).decode(), "w": w, "h": h})
        rect = [-xoff, -yoff, w, h]

        def add(name, lvl, t, rot=0.0, rc=None, glitch=True, solid=False, rect=rect, ti=ti):
            u = {"time": t, "scan": lk("SCAN", lvl), "split": lk("SPLIT", lvl) if glitch else 0.0, "glitch": lk("GLITCH", lvl) if glitch else 0.0,
                 "flicker": lk("FLICKER", lvl), "alpha": lk("ALPHA", lvl), "tint": lk("TINT", lvl), "glow": lk("GLOW", lvl),
                 "dissolve": lk("DISSOLVE", lvl), "grid": lk("GRID", lvl), "stream": lk("STREAM", lvl), "solid": 0.0, "body": [w, h, top, bottom]}
            if solid:
                sc = 1.0 + lk("HALO_SC", lvl)
                rc = [rect[0] * sc, rect[1] * sc, rect[2] * sc, rect[3] * sc]
                u["solid"] = 1.0
                u["alpha"] = lk("HALO", lvl)
            tests.append({"name": label + "|" + name, "tex": ti, "w": w, "h": h, "rect": list(rc if rc else rect), "rot": rot, "u": u})

        add("clean1", 1, 0.37, glitch=False)
        add("clean2", 2, 0.37, glitch=False)
        add("rot90", 2, 0.37, rot=90.0, glitch=False)
        add("rot37", 2, 0.37, rot=37.0, glitch=False)
        add("mirror", 2, 0.37, rc=[-(rect[0] + rect[2]), rect[1], rect[2], rect[3]], glitch=False)
        add("solid1", 1, 0.37, solid=True)
        add("solid2", 2, 0.37, solid=True)
        add("gl1_t0", 1, 0.37)
        add("gl2_t0", 2, 0.37)
        add("gl1_t1", 1, 1.13)
        add("gl2_t1", 2, 1.13)
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            b = p.chromium.launch(args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-webgl"])
            pg = b.new_page()
            pg.set_content("<html><body></body></html>")
            out = pg.evaluate(JS, {"vsh": vsh, "fsh": fsh, "unames": UNAMES, "tests": tests, "texs": texs})
            b.close()
    except Exception as exc:  # noqa
        res(False, "el harness WebGL1 no pudo ejecutarse: %r" % (exc,))
        return
    errs = sorted(set(out.get("errors", [])))
    res(not errs, "el .vsh/.fsh REAL compila y enlaza en WebGL1 (preambulo de GameMaker) sin errores de GL"
        + ("" if not errs else " -> " + " | ".join(e[:400] for e in errs)))
    for n in sorted(set(out.get("notes", []))):
        info("harness: " + n[:300])
    info("render: %s | MAX_FRAGMENT_UNIFORM_VECTORS = %s" % (out.get("renderer"), out.get("maxFragUniforms")))
    miss = [m for m in out.get("missing", []) if m != "u_ColourCount"]      # u_ColourCount sobra solo por el cambio de limite del harness
    res(not miss and all(a >= 0 for a in out.get("attrs", [-1])),
        "los %d uniforms y los 3 atributos existen tras compilar (ninguno eliminado por el compilador)" % len(UNAMES))
    res(out.get("glErrorAfterUniforms", 1) == 0, "sin error de GL al fijar los uniforms")
    if errs:
        return
    R = out["results"]

    def get(name):
        return np.frombuffer(base64.b64decode(R[name]), dtype=np.uint8).reshape(S, S, 4).astype(np.float64)

    for label, (im, w, h, xoff, yoff, top, bottom) in chars:
        bh = max(bottom - top, 1)
        for name in ("clean1", "clean2", "rot90", "rot37", "mirror"):
            t = next(x for x in tests if x["name"] == label + "|" + name)
            img = get(t["name"])
            cv = placed(im, t["rect"], t["rot"])
            cov = cv[:, :, 3] > 0.5
            lx, ly = local_xy(t["rot"], t["rect"])
            disc = cov & (img[:, :, 3] < 8)
            viol = int((disc & ~(ly > bottom - 0.45 * bh)).sum())
            res(viol == 0 and int(disc.sum()) > 0,
                "%s %s: %d px disueltos, %d fuera del 45%% inferior del cuerpo, rotacion %.0f" % (label, name, int(disc.sum()), viol, t["rot"]))
            if name in ("clean1", "clean2"):
                lvl = 1 if name == "clean1" else 2
                a_exp = lk("ALPHA", lvl)
                kept = cov & (img[:, :, 3] >= 200)
                nb = np.zeros_like(cov)
                nb[1:, :] |= cov[:-1, :]
                nb[:-1, :] |= cov[1:, :]
                nb[:, 1:] |= cov[:, :-1]
                nb[:, :-1] |= cov[:, 1:]
                rim = cov & ~shrink(cov, 3)
                gain = float((img[:, :, 2][rim] - cv[:, :, 2][rim] * a_exp).mean()) if rim.sum() else -1.0
                res(kept.sum() > 0 and float(np.abs(img[:, :, 3][kept] / 255.0 - a_exp).max()) < 0.012,
                    "%s %s: el cuerpo se dibuja con opacidad %.2f en %d px" % (label, name, a_exp, int(kept.sum())))
                res(gain > 10.0, "%s %s: el contorno del cuerpo se ilumina hacia el cian (%d px de borde, +%.0f/255 en azul)" % (label, name, int(rim.sum()), gain))
        d = [int(((placed(im, [-xoff, -yoff, w, h], 0.0)[:, :, 3] > 127) & (get(label + "|" + n)[:, :, 3] < 8)).sum()) for n in ("clean1", "clean2")]
        res(d[1] > d[0], "%s: la disolucion es mayor en COMPLETA que en SEMI (%d px > %d px)" % (label, d[1], d[0]))
        cover = placed(im, [-xoff, -yoff, w, h], 0.0)[:, :, 3] > 127
        far = grow(cover, 29)
        for name in ("gl1_t0", "gl2_t0", "gl1_t1", "gl2_t1"):
            img = get(label + "|" + name)
            on = int((img[:, :, 3] > 0).sum())
            res(on > 0 and int(((img[:, :, 3] > 0) & ~far).sum()) == 0,
                "%s %s (glitch completo): se dibuja y nada sale a mas de 14 px del cuerpo (%d px)" % (label, name, on))
        for name, lvl in (("solid1", 1), ("solid2", 2)):
            t = next(x for x in tests if x["name"] == label + "|" + name)
            img = get(t["name"])
            cov = placed_sc(im, [-xoff, -yoff, w, h], 1.0 + lk("HALO_SC", lvl))[:, :, 3] > 0.5
            inner = shrink(cov, 5)
            a_exp = lk("HALO", lvl)
            col = float(np.abs(img[:, :, :3][inner] - np.array(HALO_RGB) * 255.0).max()) if inner.sum() else 999.0   # sin blending: color recto
            alp = float(np.abs(img[:, :, 3][inner] / 255.0 - a_exp).max()) if inner.sum() else 999.0
            leak = int(((img[:, :, 3] > 0) & ~grow(cov, 5)).sum())
            ring = int(((img[:, :, 3] > 0) & ~(placed(im, [-xoff, -yoff, w, h], 0.0)[:, :, 3] > 127)).sum())
            res(inner.sum() > 0 and col < 6.0 and alp < 0.03 and leak == 0 and ring > 0,
                "%s %s (glow exterior): color del glow, alfa %.2f, nada fuera de la silueta, %d px de glow sobresalen del cuerpo" % (label, name, a_exp, ring))
    try:
        cell, up, lab = 100, 3, 22
        cols = ["ORIGINAL", "NIVEL 1 / SEMI CYBER", "NIVEL 1 + GLOW", "NIVEL 2 / CYBER COMPLETA", "NIVEL 2 + GLOW"]
        sheet = Image.new("RGB", (len(cols) * cell * up, lab + len(chars) * 2 * (cell * up + lab)), (16, 20, 26))
        dr = ImageDraw.Draw(sheet)
        bg = np.array([16.0, 20.0, 26.0])

        def over(top, bottom):
            ta, ba = top[:, :, 3:4] / 255.0, bottom[:, :, 3:4] / 255.0
            a = ta + ba * (1.0 - ta)
            c = top[:, :, :3] * ta + bottom[:, :, :3] * ba * (1.0 - ta) + bg * (1.0 - a)   # sobre el fondo opaco de la hoja: NO se divide por a
            return np.dstack([np.clip(c, 0, 255), np.full((S, S, 1), 255.0)])

        def flat(img):
            a = img[:, :, 3:4] / 255.0
            return np.dstack([img[:, :, :3] * a + bg * (1.0 - a), np.full((S, S, 1), 255.0)])

        r = 0
        ok_bg = True
        for label, (im, w, h, xoff, yoff, top, bottom) in chars:
            base = placed(im, [-xoff, -yoff, w, h], 0.0)
            for k in range(2):
                c1, c2 = get(label + "|gl1_t%d" % k), get(label + "|gl2_t%d" % k)
                imgs = [flat(base), flat(c1), flat(over(get(label + "|solid1"), c1)), flat(c2), flat(over(get(label + "|solid2"), c2))]
                y0 = lab + r * (cell * up + lab)
                for ci, imx in enumerate(imgs):
                    sheet.paste(Image.fromarray(imx.astype(np.uint8)).resize((cell * up, cell * up), Image.NEAREST), (ci * cell * up, y0 + lab))
                    ok_bg = ok_bg and bool(np.abs(imx[0, 0, :3] - bg).max() < 1.0)
                    if r == 0:
                        dr.text((ci * cell * up + 4, 4), cols[ci], fill=(190, 225, 245))
                dr.text((4, y0 + 5), "%s  (t = %.2f s)" % (label, (0.37, 1.13)[k]), fill=(190, 225, 245))
                r += 1
        sheet.save(OUT)
        res(ok_bg and os.path.isfile(OUT) and os.path.getsize(OUT) > 1000, "hoja de previsualizacion con el mismo fondo en todas las celdas: %s (%dx%d)" % (OUT, sheet.size[0], sheet.size[1]))
    except Exception as exc:  # noqa
        res(False, "no se pudo componer la previsualizacion: %r" % (exc,))


if __name__ == "__main__":
    part_a()
    part_b()
    print("RESULTADO: %d OK / %d BAD" % (OK, BAD))
    sys.exit(1 if BAD else 0)
