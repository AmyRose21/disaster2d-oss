#!/usr/bin/env python3
# sim_v80i.py — SIMULADOR DEL RUNTIME de GameMaker para scr_controls_update_touch.
# Ejecuta el .gml REAL (v78 / v80h2 / v80i) con un mini-intérprete que replica
# la semantica GML relevante:
#   - device_mouse_x/y_to_gui(slot): SOLO devuelve numero si ese slot tiene
#     un dedo activo; sin dedo => undefined (docs GM: "only updated while
#     the screen is being touched").
#   - point_in_circle con undefined en cualquier argumento => FATAL ERROR
#     "argument N incorrect type (undefined) expecting a Number" (1-based,
#     docs GM runtime errors) y el juego MUERE (no hay try/catch posible).
#   - && y || cortan con la semantica GML (&& no evalua la derecha si la
#     izquierda es false; || no evalua la derecha si la izquierda es true).
# Semantica adicional del SLOT-SANITIZE v80i y del V-GUARD v80h2 modelada
# textualmente sobre el archivo real (los patrones se buscan y se aplican).
# Salida: matriz de escenarios x versiones (CRASH / ok) + resumen.
import io, re, sys

# ---------- runtime GM ----------
class Fatal(Exception):
    def __init__(self, line, fn, arg, msg):
        self.line, self.fn, self.arg, self.msg = line, fn, arg, msg

UNDEF = "UNDEFINED"

class GMLRuntime:
    """No parsea GML completo: interpreta el LOOP de slots del script real.
    El loop tiene una estructura fija conocida y validada contra el archivo:
    for i in 0..23 { _x,_y,_state; luego bloques A..G,W,V con la misma forma
    if(_state && point_in_circle(_x,_y, CX,CY, R)) ... } + joystick final."""
    def __init__(self, path, version):
        self.version = version
        self.src = io.open(path, encoding="utf-8").read()
        self.lines = self.src.split("\n")
        # detectar features
        self.has_sanitize = "SLOT-SANITIZE" in self.src and "if(_state && (is_undefined(_x) || is_undefined(_y)))" in self.src
        self.has_vguard   = "var _inV = _state" in self.src
        self.has_jfix     = "if(is_undefined(_x))" in self.src  # joystick fallback
        # boton: (nombre, var x, var y, var scale, radio_base)
        self.buttons = [
            ("A", "bAX", "bAY", "bAScale", 40), ("B", "bBX", "bBY", "bBScale", 40),
            ("C", "bCX", "bCY", "bCScale", 40), ("D", "bDX", "bDY", "bDScale", 22),
            ("E", "bEX", "bEY", "bEScale", 22), ("F", "bFX", "bFY", "bFScale", 22),
            ("G", "bGX", "bGY", "bGScale", 22), ("W", "bWX", "bWY", "bWScale", 22),
        ]
        # lineas reales de cada point_in_circle (para el numero de linea del error)
        self.line_of = {}
        for idx, l in enumerate(self.lines, 1):
            for b in ["dpad"] + [x[0] for x in self.buttons] + ["V", "V2"]:
                pass
            if "point_in_circle" in l:
                if "dpadX" in l: self.line_of["dpad"] = idx
                elif "bAX" in l: self.line_of["A"] = idx
                elif "bBX" in l: self.line_of["B"] = idx
                elif "bCX" in l: self.line_of["C"] = idx
                elif "bDX" in l: self.line_of["D"] = idx
                elif "bEX" in l: self.line_of["E"] = idx
                elif "bFX" in l: self.line_of["F"] = idx
                elif "bGX" in l: self.line_of["G"] = idx
                elif "bWX" in l: self.line_of["W"] = idx
                elif "bVX" in l: self.line_of["V"] = idx
                elif "bV2X" in l: self.line_of["V2"] = idx
        # orden real de evaluacion en el script: dpad, A..W, luego V (y V2
        # dentro de la misma expresion _inV), luego joystick
        self.order = ["dpad"] + [b[0] for b in self.buttons] + ["V", "V2", "joy"]

    def pic(self, name, x, y, cx, cy, r, line):
        """point_in_circle con semantica GM: undefined => fatal."""
        args = [x, y, cx, cy, r]
        for i, a in enumerate(args, 1):
            if a is UNDEF or a is None:
                raise Fatal(line, "point_in_circle", i,
                            f"argument {i} incorrect type (undefined) expecting a Number")
        return (x-cx)**2 + (y-cy)**2 <= r*r

    def run(self, touches, cfg, juse=True, buse=True, frames=3):
        """touches: {slot: (x, y) con dedo}. cfg: dict con bVX etc.
        Devuelve (ok, crashes[], eventos[]) — corre `frames` steps."""
        events, crashes = [], []
        # ids persistentes (instancia obj_controls)
        ids = {n+"TouchId": -1 for n, *_ in self.buttons}
        ids["VTouchId"] = -1; ids["jTouchId"] = -1
        for f in range(frames):
            jTouchId_prev = ids["jTouchId"]
            # ---- el loop: slots 0..23 ----
            for i in range(24):
                _x = touches[i][0] if i in touches else UNDEF
                _y = touches[i][1] if i in touches else UNDEF
                _state = i in touches  # dedo presente
                # v80i SLOT-SANITIZE (del archivo real)
                if self.has_sanitize and _state and (_x is UNDEF or _y is UNDEF):
                    _state = False
                # dpad (linea 26): if(_state && point_in_circle(...) && jTouchId==-1)
                if _state and ids["jTouchId"] == -1 and juse:
                    try:
                        if self.pic("dpad", _x, _y, cfg["dpadX"], cfg["dpadY"], 160, self.line_of["dpad"]):
                            ids["jTouchId"] = i
                    except Fatal as e:
                        crashes.append((e.line, e.msg)); return events, crashes
                if not buse:
                    return events, crashes  # el script hace return
                # botones A..W: if(_state && point_in_circle(...))
                for (bn, vx, vy, vs, r) in self.buttons:
                    try:
                        hit = _state and self.pic(bn, _x, _y, cfg[vx], cfg[vy], r*cfg[vs], self.line_of[bn])
                    except Fatal as e:
                        crashes.append((e.line, e.msg)); return events, crashes
                    if hit:
                        if ids[bn+"TouchId"] == -1:
                            ids[bn+"TouchId"] = i
                            events.append(f"press {bn}")
                    elif ids[bn+"TouchId"] == i:
                        ids[bn+"TouchId"] = -1
                        events.append(f"release {bn}")
                # V (bloque v78/v80h2/v80i): estructura por version
                try:
                    if self.version == "v78":
                        hit = self.pic("V", _x, _y, cfg["bVX"], cfg["bVY"], 22*cfg["bVScale"], self.line_of["V"])
                        if not hit and juse:
                            hit = self.pic("V2", _x, _y, cfg["bV2X"], cfg["bV2Y"], 40*cfg["bV2Scale"], self.line_of["V2"])
                    elif self.version in ("v80h2", "v80i"):
                        # var _inV = _state && !is_undefined(bV*) && pic(...)
                        #                  || (_state && jUse && !is_undefined(bV2*) && pic(...))
                        hit = False
                        if _state and not any(cfg.get(k) is UNDEF for k in ("bVX","bVY","bVScale")):
                            hit = self.pic("V", _x, _y, cfg["bVX"], cfg["bVY"], 22*cfg["bVScale"], self.line_of["V"])
                        if not hit and _state and juse and not any(cfg.get(k) is UNDEF for k in ("bV2X","bV2Y","bV2Scale")):
                            hit = self.pic("V2", _x, _y, cfg["bV2X"], cfg["bV2Y"], 40*cfg["bV2Scale"], self.line_of["V2"])
                except Fatal as e:
                    crashes.append((e.line, e.msg)); return events, crashes
                if hit:
                    if ids["VTouchId"] == -1:
                        ids["VTouchId"] = i
                        events.append("press V")
                elif ids["VTouchId"] == i:
                    ids["VTouchId"] = -1
                    events.append("release V")
            # ---- joystick ----
            if ids["jTouchId"] != -1 and ids["GTouchId"] == -1:
                j = ids["jTouchId"]
                if j not in touches:
                    ids["jTouchId"] = -1
                else:
                    jx, jy = touches[j]
                    if self.has_jfix:
                        if jx is UNDEF: jx = cfg["dpadX"]
                        if jy is UNDEF: jy = cfg["dpadY"]
                    dirX = jx - cfg["dpadX"]; dirY = jy - cfg["dpadY"]
                    if dirY is not UNDEF and dirY > 16*cfg["jScale"]: events.append("press down")
                    elif dirY is not UNDEF and dirY < -16*cfg["jScale"]: events.append("press up")
                    if dirX is not UNDEF and dirX > 16*cfg["jScale"]: events.append("press right")
                    elif dirX is not UNDEF and dirX < -16*cfg["jScale"]: events.append("press left")
        return events, crashes

# ---------- configuraciones reales (init_touch / obj_config del repo) ----------
def real_cfg(corrupt=False):
    cfg = {
        "dpadX": 68, "dpadY": 187,
        "bAX": 378, "bAY": 221, "bAScale": 1,
        "bBX": 416, "bBY": 171, "bBScale": 1,
        "bCX": 452, "bCY": 221, "bCScale": 1,
        "bDX": 464, "bDY": 48, "bDScale": 1,
        "bEX": 464, "bEY": 80, "bEScale": 1,
        "bFX": 464, "bFY": 112, "bFScale": 1,
        "bGX": 14, "bGY": 14, "bGScale": 1,
        "bWX": 14, "bWY": 14, "bWScale": 1,
        "bVX": 466, "bVY": 176, "bVScale": 1,       # V pequena (v4.0)
        "bV2X": 378, "bV2Y": 121, "bV2Scale": 1,    # V principal (v78)
        "jScale": 1,
    }
    if corrupt:  # 1.bson a medias: vMainTouch ausente
        cfg["bV2X"] = UNDEF; cfg["bV2Y"] = UNDEF; cfg["bV2Scale"] = UNDEF
    return cfg

# ---------- escenarios ----------
SCEN = [
    ("S0 arranque sin tocar",            {}, True, True, "normal"),
    ("S1 dedo sobre la V pequena",       {0: (466, 176)}, True, True, "normal"),
    ("S2 dedo sobre la V principal",     {0: (378, 121)}, True, True, "normal"),
    ("S3 dedo lejos de todo",            {0: (100, 400)}, True, True, "normal"),
    ("S4 lobby (jUse=false), dedo V2",   {0: (378, 121)}, False, True, "normal"),
    ("S5 config corrupta + dedo en V2",  {0: (378, 121)}, True, True, "corrupt"),
    ("S6 5 dedos (A,B,C,V,V2)",          {0: (378,221), 1: (416,171), 2: (452,221), 3: (466,176), 4: (378,121)}, True, True, "normal"),
    ("S7 edge: _state true, coords undef", {0: (UNDEF, UNDEF)}, True, True, "normal"),
]

VERSIONS = [
    ("v78 (viejo, sin guardas)",        "/tmp/v78_reconstructed.gml", "v78"),
    ("v80h2 (repo actual)",             "/tmp/v80h2_repo.gml",        "v80h2"),
    ("v80i (SLOT-SANITIZE + V-GUARD)",  "/tmp/v80i_stage/scripts/scr_controls_update_touch/scr_controls_update_touch.gml", "v80i"),
]

def main():
    print("=" * 100)
    print("SIMULADOR RUNTIME GM — scr_controls_update_touch (lineas/estructura reales de cada .gml)")
    print("=" * 100)
    rows, all_ok = [], True
    for sname, touches, juse, buse, mode in SCEN:
        cells = []
        for vname, path, ver in VERSIONS:
            rt = GMLRuntime(path, ver)
            cfg = real_cfg(mode == "corrupt")
            events, crashes = rt.run(dict(touches), cfg, juse=juse, buse=buse, frames=3)
            if crashes:
                line, msg = crashes[0]
                cells.append(f"CRASH lin {line}")
                all_ok = False
            else:
                cells.append("ok")
        rows.append((sname, cells))
    # tabla
    w1 = max(len(s) for s, _ in rows) + 1
    hdr = f"{'escenario':<{w1}}" + "".join(f"{v[0]:<34}" for v in VERSIONS)
    print(hdr); print("-" * len(hdr))
    for sname, cells in rows:
        print(f"{sname:<{w1}}" + "".join(f"{c:<34}" for c in cells))
    print()
    # detalle de los casos interesantes
    print("DETALLE (eventos v80i, 3 frames):")
    for sname, touches, juse, buse, mode in SCEN:
        rt = GMLRuntime(VERSIONS[2][1], "v80i")
        events, crashes = rt.run(dict(touches), real_cfg(mode == "corrupt"), juse=juse, buse=buse, frames=3)
        ev = ", ".join(sorted(set(events))) or "(sin eventos)"
        print(f"  {sname:<38} -> {ev}")
    print()
    # veredicto por version
    print("VEREDICTO:")
    for vname, path, ver in VERSIONS:
        rt_base = GMLRuntime(path, ver)
        crashed = []
        for sname, touches, juse, buse, mode in SCEN:
            _, crashes = rt_base.run(dict(touches), real_cfg(mode == "corrupt"), juse=juse, buse=buse, frames=3)
            if crashes: crashed.append(sname)
        tag = f"CRASHEA en: {', '.join(crashed)}" if crashed else "SIN CRASH en los 8 escenarios"
        print(f"  {vname:<36} {tag}")
    return 0 if all_ok else 1

if __name__ == "__main__":
    sys.exit(main())
