#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# =====================================================================
# check_player_warning_fix.py - v1
#
# Verificador del fix del crash de obj_player_warning:
#   "ERROR in action number 1 of Draw Event for object obj_player_warning:
#    Unable to find instance for object index 300
#    at gml_Object_obj_player_warning_Draw_75 (line 4) -
#    if(global.player.isDead || global.player.revivalTimes >= 2)"
#
# Estatica + simulacion 1:1 del Draw GUI (estilo casa).
# Exit 0 = todo OK / exit 1 = cualquier fallo.
# =====================================================================
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
DRAW    = os.path.join(ROOT, "objects", "obj_player_warning", "Draw_75.gml")
CREATE  = os.path.join(ROOT, "objects", "obj_player_warning", "Create_0.gml")
CLEANUP = os.path.join(ROOT, "objects", "obj_player_warning", "CleanUp_0.gml")
YY      = os.path.join(ROOT, "objects", "obj_player_warning", "obj_player_warning.yy")
SLOW    = os.path.join(ROOT, "scripts", "scr_player_slow", "scr_player_slow.gml")
HURT    = os.path.join(ROOT, "scripts", "scr_player_hurt", "scr_player_hurt.gml")
NETGAME = os.path.join(ROOT, "scripts", "net_state_game", "net_state_game.gml")

# ---------------------------------------------------------------- git
def git_show(rel):
    r = subprocess.run(["git", "-C", ROOT, "show", "HEAD:" + rel],
                       capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git show fallo para %s: %s" % (rel, r.stderr))
    return r.stdout.decode("utf-8")

# ---------------------------------------- bloques del fix (byte a byte)
OLD_BLOCK = (
    "if(global.timeMinutes < 1)\n"
    "\tmoved = true;\n"
    "\t\n"
    "if(global.player.isDead || global.player.revivalTimes >= 2)\n"
    "\tmoved = true;\n"
)

NEW_BLOCK = (
    "if(global.timeMinutes < 1)\n"
    "\tmoved = true;\n"
    "\n"
    "// v1 FIX CRASH \"Unable to find instance for object index 300\": en el frame\n"
    "// de transicion de fin de ronda el codigo de red reescribe global.player\n"
    "// (noone en game over; obj_exe, INDICE de objeto, al volver a vote/lobby)\n"
    "// ANTES de que el cambio de room destruya este aviso, y leer una variable\n"
    "// de algo que ya no es una instancia viva mataba el Draw GUI (line 4).\n"
    "// Mismo guard de la casa que scr_player_hurt / scr_player_slow /\n"
    "// net_state_game (game over): sin player vivo se toma el MISMO camino que\n"
    "// \"muerto\" -> fade-out y autodestruccion limpia (el CleanUp restaura la\n"
    "// musica).\n"
    "if(!instance_exists(global.player))\n"
    "\tmoved = true;\n"
    "else if(global.player.isDead || global.player.revivalTimes >= 2)\n"
    "\tmoved = true;\n"
)

RESULTS = []

def run_check(name, fn):
    try:
        fn()
        RESULTS.append(True)
        print("[OK]   %s" % name)
    except AssertionError as e:
        RESULTS.append(False)
        print("[FAIL] %s :: %s" % (name, e))
    except Exception as e:  # noqa
        RESULTS.append(False)
        print("[FAIL] %s :: EXCEPCION %r" % (name, e))

# =====================================================================
# PARTE 1 - CHECKS ESTATICOS
# =====================================================================

def s01_archivos():
    for p in (DRAW, CREATE, CLEANUP, YY, SLOW, HURT, NETGAME):
        assert os.path.isfile(p), "no existe: %s" % p

def s02_diff_quirurgico():
    """El nuevo Draw_75.gml es EXACTAMENTE el original con el bloque del
    guard insertado - ni un byte mas."""
    original = git_show("objects/obj_player_warning/Draw_75.gml")
    with open(DRAW, "r", encoding="utf-8") as f:
        nuevo = f.read()
    assert OLD_BLOCK in original, "bloque viejo no hallado en HEAD (¿pull?)"
    expected = original.replace(OLD_BLOCK, NEW_BLOCK, 1)
    assert nuevo == expected, (
        "el Draw_75.gml nuevo difiere del cambio quirurgico esperado "
        "(len nuevo=%d, esperado=%d)" % (len(nuevo), len(expected)))

def s03_un_solo_dotaccess():
    """Solo puede haber UNA LINEA con dot-access global.player.<var> en el
    evento: la del else if (tras el guard). Los 2 dot-access legitimos de
    esa linea (isDead y revivalTimes, igual que la linea 4 original) se
    conservan — pero no puede haber ninguno mas en el archivo."""
    with open(DRAW, "r", encoding="utf-8") as f:
        lineas = f.readlines()
    con_dot = [i for i, l in enumerate(lineas) if re.search(r"global\.player\.", l)]
    assert len(con_dot) == 1, \
        "esperaba 1 linea con dot-access, hay %d" % len(con_dot)
    assert "else if(global.player.isDead || global.player.revivalTimes >= 2)" in lineas[con_dot[0]], \
        "la linea con dot-access no es la del else if"
    idx_guard = next((i for i, l in enumerate(lineas)
                      if l.strip() == "if(!instance_exists(global.player))"), -1)
    assert 0 <= idx_guard < con_dot[0], "el guard debe preceder a la linea del dot-access"

def s04_condicion_intacta():
    """La formula del apagado queda identica: isDead || revivalTimes >= 2."""
    with open(DRAW, "r", encoding="utf-8") as f:
        src = f.read()
    assert "else if(global.player.isDead || global.player.revivalTimes >= 2)" in src, \
        "condicion original alterada"

def s05_estructura_sana():
    """Llaves y parentesis balanceados, sin tabs/espacios raros de mas."""
    with open(DRAW, "r", encoding="utf-8") as f:
        src = f.read()
    assert src.count("{") == src.count("}"), \
        "llaves desbalanceadas (%d/%d)" % (src.count("{"), src.count("}"))
    assert src.count("(") == src.count(")"), \
        "parentesis desbalanceados (%d/%d)" % (src.count("("), src.count(")"))
    # el resto del evento sigue ahi, pieza a pieza
    for pieza in ("if(!moved)", "instance_destroy();", "scr_player_slow(5);",
                  "timer += 0.50;", "if(terraria)", "fade -= 0.016;"):
        assert pieza in src, "falta pieza del evento original: %s" % pieza

def s06_hermanos_intactos():
    """Create / CleanUp / .yy / scr_player_slow / scr_player_hurt /
    net_state_game quedan byte a byte igual que HEAD."""
    pares = [
        ("objects/obj_player_warning/Create_0.gml", CREATE),
        ("objects/obj_player_warning/CleanUp_0.gml", CLEANUP),
        ("objects/obj_player_warning/obj_player_warning.yy", YY),
        ("scripts/scr_player_slow/scr_player_slow.gml", SLOW),
        ("scripts/scr_player_hurt/scr_player_hurt.gml", HURT),
        ("scripts/net_state_game/net_state_game.gml", NETGAME),
    ]
    for rel, path in pares:
        with open(path, "r", encoding="utf-8") as f:
            actual = f.read()
        assert actual == git_show(rel), "archivo tocado que NO debia tocarse: %s" % rel

def s07_patron_de_la_casa():
    """Los guards de referencia siguen vivos (patron que copia el fix)."""
    with open(SLOW, "r", encoding="utf-8") as f:
        slow = f.read()
    assert "if(!instance_exists(global.player))" in slow, \
        "scr_player_slow perdio su guard"
    with open(HURT, "r", encoding="utf-8") as f:
        hurt = f.read()
    assert "if(!instance_exists(global.player))" in hurt, \
        "scr_player_hurt perdio su guard"
    with open(NETGAME, "r", encoding="utf-8") as f:
        net = f.read()
    assert "instance_exists(global.player) && global.player.revivalTimes >= 2" in net, \
        "net_state_game perdio el patron del game over"

def s08_yy_intacto():
    """El .yy del warning no se toca: evento Draw 75/8, no persistente."""
    with open(YY, "r", encoding="utf-8") as f:
        yy = f.read()
    assert '"eventNum":75' in yy and '"persistent":false' in yy, \
        ".yy del warning alterado"

# =====================================================================
# PARTE 2 - SIMULACION 1:1 DEL RUNTIME
# =====================================================================
# Semantica modelada del runtime GML para global.player:
#   - instancia viva                -> dot-access OK
#   - instancia DESTRUIDA           -> error "Unable to find instance for
#                                       object index <obj de la instancia>"
#   - INDICE de objeto sin instancias -> error "Unable to find instance for
#                                       object index <indice>"
#   - noone                         -> sin instancia (error en dot-access)
#   - instance_exists() acepta los 4 casos sin explotar (patron de la casa,
#     ya usado en vivo por scr_player_slow con global.player = noone)

class GMLRuntimeError(Exception):
    pass

NOONE = object()  # noone

class Instance:
    def __init__(self, iid, obj_index, isDead=False, revivalTimes=0):
        self.iid = iid
        self.obj_index = obj_index
        self.isDead = isDead
        self.revivalTimes = revivalTimes
        self.alive = True

    def destroy(self):
        self.alive = False

class Runtime:
    def __init__(self):
        self.global_player = None
        self.instances = []

    def instance_exists(self, val):
        if val is NOONE or val is None:
            return False
        if isinstance(val, Instance):
            return val.alive
        if isinstance(val, int):  # indice de objeto
            return any(i.alive and i.obj_index == val for i in self.instances)
        return False

    def dot(self, val):
        """global.player.<var> - resuelve la instancia o explota."""
        if isinstance(val, Instance):
            if val.alive:
                return val
            raise GMLRuntimeError(
                "Unable to find instance for object index %d" % val.obj_index)
        if isinstance(val, int):
            vivos = [i for i in self.instances if i.alive and i.obj_index == val]
            if vivos:
                return vivos[0]
            raise GMLRuntimeError(
                "Unable to find instance for object index %d" % val)
        raise GMLRuntimeError(
            "Unable to find instance for object index %r" % (val,))

class Warning:
    """obj_player_warning: Create + Draw_75 (transcripcion 1:1)."""

    def __init__(self, terraria=False):
        self.moved = False
        self.fade = 0.0
        self.terraria = terraria
        self.destroyed = False
        self.bos_stopped = False
        self.music_restored = False   # CleanUp: audio_sound_gain(global.music, 1, 500)
        self.slow_calls = 0           # scr_player_slow(5) cada frame
        self.slow_aplicado = 0        # solo cuando el player existe (guard interno)

    def _comun(self, rt):
        # if(!moved) { fade sube } else { fade baja / destroy }
        if not self.moved:
            self.fade = self.fade + 0.016 if self.fade < 1.0 else 1.0
        else:
            if self.fade > 0:
                self.fade = max(0.0, self.fade - 0.016)
            else:
                if self.terraria:
                    self.bos_stopped = True   # audio_stop_sound(snd_bos)
                self.fade = 0
                self.destroyed = True         # instance_destroy()
                self.music_restored = True    # CleanUp event
        # dibujo del texto (no modelado mas alla del fade) + scr_player_slow(5)
        self.slow_calls += 1
        if rt.instance_exists(rt.global_player):
            self.slow_aplicado += 1           # guard interno de scr_player_slow

    def draw_old(self, rt, timeMinutes):
        # VIEJO (linea 4 del error): dot-access directo
        if timeMinutes < 1:
            self.moved = True
        pl = rt.dot(rt.global_player)
        if pl.isDead or pl.revivalTimes >= 2:
            self.moved = True
        self._comun(rt)

    def draw_new(self, rt, timeMinutes):
        # NUEVO: guard de la casa + else if
        if timeMinutes < 1:
            self.moved = True
        if not rt.instance_exists(rt.global_player):
            self.moved = True
        else:
            pl = rt.dot(rt.global_player)
            if pl.isDead or pl.revivalTimes >= 2:
                self.moved = True
        self._comun(rt)

def correr(warn, rt, timeMinutes, frames):
    """Corre `frames` draws y devuelve la traza (frame, moved, fade, destroyed)."""
    traza = []
    for n in range(frames):
        warn.draw(rt, timeMinutes)
        traza.append((n, warn.moved, round(warn.fade, 6),
                      warn.destroyed, warn.slow_calls))
        if warn.destroyed:
            break
    return traza

def sim01_repro_gameover_noone():
    """REPRO: campero con aviso activo; frame de transicion de fin de ronda
    (game over individual) pone global.player = noone ANTES del draw."""
    # VIEJO: 63 frames subiendo el fade, luego noone -> crash
    rt = Runtime()
    p = Instance(100077, 300)
    rt.instances.append(p)
    rt.global_player = p
    wv = Warning()
    for _ in range(70):
        wv.draw_old(rt, 3)
    assert abs(wv.fade - 1.0) < 1e-9 and not wv.destroyed, "montaje del repro"
    rt.global_player = NOONE        # net_state_game: game over -> noone
    try:
        wv.draw_old(rt, 3)
        raise AssertionError("VIEJO no crasheo con noone (repro fallo)")
    except GMLRuntimeError:
        pass                        # crash reproducido: el Draw GUI muere
    # NUEVO: mismo frame, sin crash, apagado limpio
    rt = Runtime()
    p = Instance(100077, 300)
    rt.instances.append(p)
    rt.global_player = p
    wn = Warning()
    for _ in range(70):
        wn.draw_new(rt, 3)
    rt.global_player = NOONE
    wn.draw_new(rt, 3)              # NO explota
    assert wn.moved, "nuevo debe marcar moved con player ausente"
    for _ in range(80):
        if wn.destroyed:
            break
        wn.draw_new(rt, 3)
    assert wn.destroyed and wn.music_restored, \
        "nuevo debe autodestruirse y restaurar la musica"

def sim02_repro_indice_objeto_300():
    """REPRO EXACTO del reporte: global.player = obj_exe (INDICE de objeto
    300, valor default de scr_globals / vote / lobby) y CERO instancias de
    ese objeto en el room -> 'Unable to find instance for object index 300'."""
    rt = Runtime()
    rt.global_player = 300          # indice de objeto obj_exe
    wv = Warning()
    wv.fade = 1.0
    try:
        wv.draw_old(rt, 3)
        raise AssertionError("VIEJO no crasheo con indice de objeto (repro fallo)")
    except GMLRuntimeError as e:
        assert "object index 300" in str(e), "mensaje inesperado: %s" % e
    rt = Runtime()
    rt.global_player = 300
    wn = Warning()
    wn.fade = 1.0
    wn.draw_new(rt, 3)              # NO explota
    for _ in range(80):
        if wn.destroyed:
            break
        wn.draw_new(rt, 3)
    assert wn.destroyed and wn.music_restored

def sim03_repro_instancia_destruida():
    """REPRO: la instancia del player fue destruida y global.player sigue
    apuntando a su id muerto."""
    rt = Runtime()
    p = Instance(100077, 300)
    rt.instances.append(p)
    rt.global_player = p
    p.destroy()
    wv = Warning()
    wv.fade = 1.0
    try:
        wv.draw_old(rt, 3)
        raise AssertionError("VIEJO no crasheo con instancia destruida")
    except GMLRuntimeError as e:
        assert "object index 300" in str(e)
    rt = Runtime()
    p = Instance(100077, 300)
    rt.instances.append(p)
    rt.global_player = p
    p.destroy()
    wn = Warning()
    wn.fade = 1.0
    wn.draw_new(rt, 3)
    for _ in range(80):
        if wn.destroyed:
            break
        wn.draw_new(rt, 3)
    assert wn.destroyed and wn.music_restored

def sim04_regresion_campero_vivo():
    """REGRESION: campero vivo y coleando - viejo y nuevo IDENTICOS frame a
    frame (el aviso funciona exactamente igual: fade sube, texto, slow)."""
    def traza(metodo):
        rt = Runtime()
        p = Instance(100077, 300, isDead=False, revivalTimes=0)
        rt.instances.append(p)
        rt.global_player = p
        w = Warning()
        w.draw = getattr(w, metodo)
        return correr(w, rt, 3, 120)
    tv, tn = traza("draw_old"), traza("draw_new")
    assert tv == tn, "regresion: la traza del campero vivo difiere viejo vs nuevo"
    assert len(tn) == 120, "el aviso no debe morir con el player vivo"
    assert tn[-1][2] == 1.0, "fade debe llegar a 1.0"
    assert all(not t[3] for t in tn), "no debe destruirse"

def sim05_regresion_muerto_en_medio():
    """REGRESION: el exe lo mata a mitad del aviso (isDead=true, instancia
    VIVA) - mismo apagado con fade viejo vs nuevo."""
    def traza(metodo):
        rt = Runtime()
        p = Instance(100077, 300)
        rt.instances.append(p)
        rt.global_player = p
        w = Warning()
        w.draw = getattr(w, metodo)
        out = []
        for n in range(120):
            if n == 30:
                p.isDead = True     # scr_player_hurt: global.player.isDead = true
            w.draw(rt, 3)
            out.append((n, w.moved, round(w.fade, 6), w.destroyed))
            if w.destroyed:
                break
        return out
    tv, tn = traza("draw_old"), traza("draw_new")
    assert tv == tn, "regresion: apagado por muerte difiere viejo vs nuevo"
    assert tn[-1][3], "debe destruirse tras el fade"

def sim06_regresion_demonizado():
    """REGRESION: demonizado (revivalTimes = 2) campeando - la linea 4
    original ya lo apagaba; debe seguir apagandose igual."""
    def traza(metodo):
        rt = Runtime()
        p = Instance(100077, 300, revivalTimes=2)
        rt.instances.append(p)
        rt.global_player = p
        w = Warning()
        w.fade = 1.0
        w.draw = getattr(w, metodo)
        return correr(w, rt, 3, 80)
    tv, tn = traza("draw_old"), traza("draw_new")
    assert tv == tn, "regresion: demonizado difiere viejo vs nuevo"
    assert tn[0][1], "moved desde el primer frame"
    assert tn[-1][3], "debe destruirse"

def sim07_regresion_primer_minuto():
    """REGRESION: durante el primer minuto (timeMinutes < 1) el aviso se
    apaga al instante - identico viejo vs nuevo."""
    def traza(metodo):
        rt = Runtime()
        p = Instance(100077, 300)
        rt.instances.append(p)
        rt.global_player = p
        w = Warning()
        w.draw = getattr(w, metodo)
        return correr(w, rt, 0, 5)
    tv, tn = traza("draw_old"), traza("draw_new")
    assert tv == tn and tn[-1][3], "regresion: primer minuto difiere o no apaga"

def sim08_regresion_chunk_move():
    """REGRESION: scr_move_basic (linea 298-299) apaga el aviso por fuera
    (moved = true al cambiar de chunk) - identico viejo vs nuevo."""
    def traza(metodo):
        rt = Runtime()
        p = Instance(100077, 300)
        rt.instances.append(p)
        rt.global_player = p
        w = Warning()
        w.draw = getattr(w, metodo)
        out = []
        for n in range(80):
            if n == 10:
                w.moved = True      # obj_player_warning.moved = true externo
            w.draw(rt, 3)
            out.append((n, w.moved, round(w.fade, 6), w.destroyed))
            if w.destroyed:
                break
        return out
    tv, tn = traza("draw_old"), traza("draw_new")
    assert tv == tn and tn[-1][3], "regresion: apagado por chunk move difiere"

def sim09_slow_es_noop_sin_player():
    """La ultima linea del evento (scr_player_slow(5)) ya tenia guard propio
    (v4.8.1): con player ausente es no-op y NO revienta el frame final."""
    rt = Runtime()
    rt.global_player = NOONE
    w = Warning()
    w.fade = 0.005                  # un frame antes del destroy
    for _ in range(3):
        w.draw_new(rt, 3)
    assert w.destroyed and w.music_restored
    assert w.slow_calls >= 1 and w.slow_aplicado == 0, \
        "scr_player_slow debia quedar en no-op (guard interno)"

# =====================================================================
def main():
    print("check_player_warning_fix.py - v1")
    print("=" * 60)
    estaticos = [
        ("S-01 archivos presentes", s01_archivos),
        ("S-02 diff quirurgico byte a byte vs HEAD", s02_diff_quirurgico),
        ("S-03 un solo dot-access, tras el guard", s03_un_solo_dotaccess),
        ("S-04 condicion isDead/revivalTimes intacta", s04_condicion_intacta),
        ("S-05 evento estructuralmente sano", s05_estructura_sana),
        ("S-06 hermanos byte a byte intactos", s06_hermanos_intactos),
        ("S-07 guards de la casa vivos (slow/hurt/netgame)", s07_patron_de_la_casa),
        ("S-08 .yy del warning intacto", s08_yy_intacto),
        ("SIM-01 REPRO game over -> noone (viejo crashea)", sim01_repro_gameover_noone),
        ("SIM-02 REPRO indice objeto 300 (mensaje exacto)", sim02_repro_indice_objeto_300),
        ("SIM-03 REPRO instancia destruida", sim03_repro_instancia_destruida),
        ("SIM-04 regresion campero vivo identico", sim04_regresion_campero_vivo),
        ("SIM-05 regresion muerto en medio identico", sim05_regresion_muerto_en_medio),
        ("SIM-06 regresion demonizado identico", sim06_regresion_demonizado),
        ("SIM-07 regresion primer minuto identico", sim07_regresion_primer_minuto),
        ("SIM-08 regresion chunk move identico", sim08_regresion_chunk_move),
        ("SIM-09 scr_player_slow no-op sin player", sim09_slow_es_noop_sin_player),
    ]
    for name, fn in estaticos:
        run_check(name, fn)
    total = len(RESULTS)
    ok = sum(RESULTS)
    print("=" * 60)
    print("RESULTADO: %d/%d OK" % (ok, total))
    if ok != total:
        sys.exit(1)
    print("TODO OK")

if __name__ == "__main__":
    main()
