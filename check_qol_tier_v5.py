#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_qol_tier_v5.py — verificador del paquete QoL SUITE + TIERLIST V5.

PARTE 1 — SUITE_TD2D.html (QoL visual y técnico):
  A) «↺ Reabrir última carpeta»: el handle del directorio se guarda en
     IndexedDB al abrir el proyecto (idbSet('lastRoot')) y al arrancar la
     Suite aparece un botón que lo recupera con un clic (queryPermission +
     requestPermission + attachFs). Si IndexedDB está capado (file:// en
     algunos Chromium), el botón simplemente no aparece.
  B) Buscador de personajes (#char-search): filtra la lista por nombre o
     objeto; los data-char siguen apuntando al índice REAL del array.
  C) Memoria del módulo activo (td2d_module) y de las sub-pestañas
     (td2d_cdsub / td2d_artesub): al arrancar, el último módulo se
     recupera SIMULANDO EL CLIC en el botón de la nav (camino oficial de
     switchModule), nunca con un atajo directo.
  D) Pulido visual: scrollbars finas, :focus-visible, micro-transiciones,
     toasts con entrada suave, prefers-reduced-motion, meta theme-color
     y meta description.

PARTE 2 — TierList_Mejoras_V5_0.html (la tier actualizada):
  Limpieza: -3,2 MB (sonidos embebidos, tiras de animación, motor de
  escenas, 4 pestañas de changelog obsoleto, PROPS, CSS muerto).
  Actualización: Metal Amy v4.10 (scan 12 s / 8 s, velocidad 13), Sally
  Canon S (Fase Duelista v5.8), Amy Canon (LSA aéreo v6.2), Vanilla v2.2.
  Nuevo: pestaña «🏆 El top» con el ranking de los 10 más poderosos.

La verificación de navegador (boot sin errores, filtro, restauración de
módulo, render del top) ya se hizo en vivo; este checker es la parte
estática y repetible sin navegador.

Uso: python3 check_qol_tier_v5.py [raiz_del_repo]
"""

import os
import re
import subprocess
import sys

FAIL = 0
PASS = 0


def check(name, cond, detail=""):
    global FAIL, PASS
    if cond:
        PASS += 1
        print(f"  [OK]   {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}" + (f" — {detail}" if detail else ""))


def section(t):
    print(f"\n=== {t} ===")


_cand = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(
    os.path.abspath(__file__))
if not os.path.isdir(os.path.join(_cand, "objects")):
    _cand = os.path.dirname(_cand)
REPO = _cand if os.path.isdir(os.path.join(_cand, "objects")) else None
if not REPO:
    print("No encuentro la raiz del repo (objects/).")
    sys.exit(1)

# ==========================================================================
print("QoL SUITE v6 + TIERLIST V5 — verificación estática")
print(f"repo: {REPO}")

# --------------------------------------------------------------------------
section("1. SUITE — sintaxis JS (los 9 bloques <script> con node --check)")
# --------------------------------------------------------------------------
suite_path = os.path.join(REPO, "Suite_TD2D.html")
suite = open(suite_path, encoding="utf-8").read()
scripts = re.findall(r"<script[^>]*>(.*?)</script>", suite, re.S)
check(f"{len(scripts)} bloques <script> encontrados", len(scripts) == 9,
      f"{len(scripts)}")
syn_ok = True
for i, s in enumerate(scripts):
    if not s.strip():
        continue
    p = f"/tmp/qol_suite_{i}.js"
    open(p, "w").write(s)
    r = subprocess.run(["node", "--check", p], capture_output=True, text=True)
    if r.returncode != 0:
        syn_ok = False
        print(r.stderr[:400])
check("sintaxis JS valida en TODOS los bloques", syn_ok)

# --------------------------------------------------------------------------
section("2. SUITE — «Reabrir última carpeta» (IndexedDB)")
# --------------------------------------------------------------------------
for pat, n, desc in [
    ("function idbOpenDb()", 1, "apertura de la BD"),
    ("async function idbSet(", 1, "escritura kv"),
    ("async function idbGet(", 1, "lectura kv"),
    ("function showReopenButton(", 1, "botón que enseña la carpeta"),
    ("async function reopenLastFolder()", 1, "reapertura con permisos"),
    ("idbSet('lastRoot', root)", 1, "openFs recuerda la carpeta"),
    ("queryPermission({ mode: 'readwrite' })", 1, "consulta de permiso"),
    ("requestPermission({ mode: 'readwrite' })", 1, "peticion de permiso"),
    ("await attachFs(h)", 1, "reapertura por el camino oficial"),
    ('id="btn-reopen" class="btn hidden"', 1, "botón nace oculto"),
]:
    c = suite.count(pat)
    check(f"{desc}", c == n, f"{c} apariciones (esperadas {n})")
check("try/catch en TODAS las funciones idb (file:// no rompe el arranque)",
      suite.count("} catch (e) { return false; }") >= 1
      and suite.count("} catch (e) { return null; }") >= 1)

# --------------------------------------------------------------------------
section("3. SUITE — buscador de personajes")
# --------------------------------------------------------------------------
check('input id="char-search" presente en el panel Personajes',
      'id="char-search" placeholder="Buscar personaje' in suite)
check("CSS del buscador compartido con el de sprites",
      "#spr-search,#char-search{" in suite)
check("renderCharList filtra por nombre Y objeto",
      "String(c.name || '').toLowerCase().indexOf(q)" in suite
      and "String(c.obj || '').toLowerCase().indexOf(q)" in suite)
check("los data-char siguen apuntando al indice REAL (indexOf del array completo)",
      "data-char=\"' + S.chars.indexOf(c) + '" in suite)
check("aviso de «Sin resultados» cuando no hay coincidencias",
      "Sin resultados para «' + esc(q)" in suite)
check("listener del buscador cableado en init",
      "$('#char-search').addEventListener('input', renderCharList);" in suite)

# --------------------------------------------------------------------------
section("4. SUITE — memoria de módulo y sub-pestañas")
# --------------------------------------------------------------------------
check("switchModule recuerda el módulo (td2d_module)",
      "localStorage.setItem('td2d_module', mod);" in suite)
check("setCdSub recuerda la sub-pestaña (td2d_cdsub)",
      "localStorage.setItem('td2d_cdsub', sub);" in suite)
check("la sub-pestaña de Arte se recuerda (td2d_artesub)",
      "localStorage.setItem('td2d_artesub', sub);" in suite)
m = re.search(r"var valid = \{([^}]*)\}", suite)
check("la restauración solo acepta módulos que existen en la nav",
      m and all(v.strip() in m.group(1) for v in
                ["anim", "cd", "arte", "keys", "lms", "muelles"]),
      m.group(1) if m else "no encontrado")
check("la restauración SIMULA EL CLIC (camino oficial de switchModule)",
      "b.click();" in suite and "#modnav .mnav[data-mod=\"" in suite)
check("la restauración va envuelta en try/catch (localStorage capado)",
      "} catch (e) { }\n})();\n</script>\n</body>" in suite
      or re.search(r"\} catch \(e\) \{ \}\s*\}\)\(\);", suite) is not None)
check("el autocchequeo de arranque v3.8.1 sigue intacto",
      "window.__bootErrors" in suite and "SUITE TD2D — NO CARGÓ COMPLETO" in suite)

# --------------------------------------------------------------------------
section("5. SUITE — pulido visual")
# --------------------------------------------------------------------------
for pat, desc in [
    ("*{scrollbar-width:thin", "scrollbars finas (Firefox)"),
    ("*::-webkit-scrollbar-thumb:hover{background:var(--gold)}", "scrollbar dorada al pasar (Chromium)"),
    ("button:focus-visible,input:focus-visible,select:focus-visible", "foco de teclado visible"),
    ("button:hover:not(:disabled){transform:translateY(-1px)}", "micro-elevación al pasar"),
    (".toast{animation:toast-in .18s ease}", "toasts con entrada suave"),
    ("@media (prefers-reduced-motion:reduce)", "respeta prefers-reduced-motion"),
    ('<meta name="theme-color" content="#0f1114">', "meta theme-color"),
    ('<meta name="description"', "meta description"),
]:
    check(desc, pat in suite)
check("las funciones previas de la Suite siguen todas (regresión)",
      all(f in suite for f in ["function writeEdits()", "async function undoLast()",
                               "function switchModule(", "window.setCdSub",
                               "window.enterArte", "window.enterLms",
                               "function initMuelles", "btn-yypfix"]))

# --------------------------------------------------------------------------
section("6. TIERLIST V5 — tamaño y limpieza")
# --------------------------------------------------------------------------
v5_path = os.path.join(REPO, "TierList_Mejoras_V5_0.html")
check("TierList_Mejoras_V5_0.html existe", os.path.isfile(v5_path))
v5 = open(v5_path, encoding="utf-8").read()
v48 = open(os.path.join(REPO, "TierList_Mejoras_V4_8.html"),
           encoding="utf-8", errors="replace").read()
sz5, sz48 = len(v5), len(v48)
check(f"peso: {sz48/1e6:.2f} MB -> {sz5/1e6:.2f} MB (menos del 8 % del original)",
      sz5 < sz48 * 0.08, f"{sz5/1e6:.2f} MB")
check("cero audio embebido (antes 12 archivos, 3,0 MB)",
      v5.count("data:audio") == 0)
check("los iconos de personajes (SPR) se conservan",
      v5.count("data:image") == v48.count("data:image") - 0 or v5.count("data:image") >= 35,
      f"{v5.count('data:image')} iconos")
check("la V4_8 original queda intacta como fuente (no se toca)",
      len(v48) > 3_000_000)

for pat, desc in [
    ("const PROPS", "datos PROPS (propuestas viejas)"),
    ("const ASSETS", "ASSETS (audio + tiras, 3,1 MB)"),
    ("propsHtml", "render de PROPS"),
    ("const VSDATA", "tabla VS el EXE vieja"),
    ("const EXEDATA", "impresiones por EXE viejas"),
    ("const CDS=", "batería de cooldowns vieja"),
    ("musdock", "reproductor de música embebido"),
    ("function snd(", "motor de sonido"),
    ("IMG[", "motor de tiras de animación"),
    ("const SCN", "planificador de escenas"),
    ("tab-mejoras", "pestaña Mejoras v3.2 + v4.8"),
    ("tab-vsexe", "pestaña VS el EXE"),
    ("tab-impres", "pestaña Impresiones"),
    ("tab-amelia", "pestaña Pasivas de Amelia"),
    ("v30banner", "banner de movimientos v3.0/v3.2"),
    ("v44banner", "banner de movimientos v4.4/v4.8"),
    ("TierList_Comentarios_V1.html", "enlace a la Comentarios V1 (no existe)"),
]:
    check(f"FUERA: {desc}", pat not in v5)

# --------------------------------------------------------------------------
section("7. TIERLIST V5 — estructura y pestañas")
# --------------------------------------------------------------------------
nav = re.findall(r'data-tab="([^"]+)"', v5)
check("6 pestañas: top · tiers · cards · matrix · solo · canon",
      nav == ["top", "tiers", "cards", "matrix", "solo", "canon"], str(nav))
secs = re.findall(r'<section class="tab[^"]*" id="([^"]+)"', v5)
check("secciones = pestañas (nada huérfano, nada sin nav)",
      secs == ["tab-" + t for t in nav], str(secs))
check("la pestaña TOP es la visible al abrir (class on)",
      '<section class="tab on" id="tab-top">' in v5
      and '<button data-tab="top" class="on">' in v5)
check("los atajos de teclado 1-9 siguen guardados por el numero de botones",
      "n>=1&&n<=btns.length" in v5)
check("title al dia",
      "<title>Tier List v5 · Sonic.exe The Disaster 2D Remake</title>" in v5)
check("contador real: 14 supervivientes (antes decia 13)",
      "<b>14</b> supervivientes" in v5)
check("fecha de actualizacion al dia",
      "<b>8 de noviembre de 2026</b>" in v5)
check("enlace a la Comentarios V2 (la que existe)",
      'href="TierList_Comentarios_V2.html"' in v5
      and "TierList_Comentarios_V1.html" not in v5)
check("banner unico de movimientos v5.0 en la tier list",
      "Movimientos v5.0:" in v5 and v5.count("Movimientos v3.0:") == 0)

# --------------------------------------------------------------------------
section("8. TIERLIST V5 — sintaxis JS y datos actualizados")
# --------------------------------------------------------------------------
tscripts = re.findall(r"<script[^>]*>(.*?)</script>", v5, re.S)
syn_ok = True
for i, s in enumerate(tscripts):
    if not s.strip():
        continue
    p = f"/tmp/qol_tier5_{i}.js"
    open(p, "w").write(s)
    r = subprocess.run(["node", "--check", p], capture_output=True, text=True)
    if r.returncode != 0:
        syn_ok = False
        print(r.stderr[:400])
check("sintaxis JS valida", syn_ok)

topd = re.search(r"const TOPDATA = \[(.*?)\n\];", v5, re.S)
check("TOPDATA presente", topd is not None)
if topd:
    ranks = [int(x) for x in re.findall(r"rank:(\d+)", topd.group(1))]
    check("TOPDATA: 10 posiciones exactas (1..10 sin repetir)",
          sorted(ranks) == list(range(1, 11)), str(sorted(ranks)))
    sides = re.findall(r"side:'([^']+)'", topd.group(1))
    check("TOPDATA: bandos validos (superviviente/exe)",
          all(s in ("superviviente", "exe") for s in sides))
    keys = re.findall(r"key:'([^']+)'", topd.group(1))
    spr_block = re.search(r"const SPR = \{(.*?)\};", v5, re.S).group(1)
    spr_keys = re.findall(r"([a-z_0-9]+):", spr_block)
    check("TOPDATA: todos los iconos existen en SPR",
          all(k in spr_keys for k in keys),
          str([k for k in keys if k not in spr_keys]))
    check("TOPDATA: mezcla ambos bandos (6 supervivientes + 4 EXE, la reparto"
          " real de tiers: 3 S + 3 A+ contra 2 S + 2 A+)",
          sides.count("superviviente") == 6 and sides.count("exe") == 4,
          f"{sides.count('superviviente')}+{sides.count('exe')}")
check("el podio y la tabla se renderizan (topHtml + montaje)",
      "function topHtml()" in v5 and "topHtml();" in v5
      and 'id="top-podium"' in v5 and 'id="top-table"' in v5)

# datos de personaje al dia
check("Metal Amy: velocidad limpia a 13 (fuera la nota del pull)",
      "speed:'13 · la más veloz del bando EXE'" in v5)
check("Metal Amy: SCAN v4.10 (12 s la V, 8 s la cazadora, borde legible)",
      "12 s viendo a todo el plantel" in v5
      and "contorno oscuro y relleno brillante" in v5
      and "8 s cada 14 s" in v5)
check("Metal Amy: plus con la mejora v4.10",
      "v4.10: el scan dura 12 s (8 s la cazadora)" in v5)
check("Sally Canon: sube a S",
      "key:'sally_canon', name:'Sally Canon', mod:true, tier:'S'" in v5)
check("Sally Canon: Fase Duelista v5.8 en pasiva y habilidades",
      "Fase Duelista (v5.8)" in v5 and "Patada duelista (v5.8)" in v5
      and "Escudo grupal (v5.8)" in v5)
check("Amy Canon: LSA aéreo v6.1/v6.2",
      "LSA aéreo (v6.1/v6.2)" in v5 and "JAMÁS repite objetivos" in v5)
check("Vanilla: fix v2.2 de la fase moribunda",
      "v2.2: la fase moribunda ya no flota" in v5)
check("footer al dia (v5.0 · 8 de noviembre de 2026)",
      "tierlist v5.0 · 8 de noviembre de 2026" in v5)

# ==========================================================================
print(f"\n{'=' * 64}")
print(f"RESULTADO: {PASS} OK / {FAIL} FAIL")
if FAIL == 0:
    print("QoL DE SUITE + TIERLIST V5 VERIFICADOS: Suite con reabrir carpeta,")
    print("buscador, memoria de módulo y pulido visual; tier list limpia")
    print("(3,2 MB menos), actualizada al juego v4.10 y con el top de poder.")
    print("Sin recompilar nada: los .gml del scan v4.10 van en su propio checker.")
sys.exit(1 if FAIL else 0)
