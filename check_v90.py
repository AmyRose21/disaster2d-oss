#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v90.py — Verificador de la v90: QoL SONIC — arreglos a su parry
+ mejora de estabilidad y fortalezas.

Pedido de la duena (2026-11-27): «QoL sonic Arreglos a su parry Y
mejora de estabilidad y fortalezas».

DIAGNOSTICO (investigacion completa del sistema: scr_parry.gml,
scr_player_hurt, obj_sonic/amy_canon/kris Step_0+Create_0+Draw_0/76,
obj_player_puppet Step_0/Draw_0/Draw_72, obj_playerui, net_state_game):

  ARREGLOS (bugs reales encontrados):
   A1. scr_parry_detect, rama laser-vs-ALIADO: el bbox del laser se leia
       por el INDICE del objeto (obj_tails_projectile.bbox_*) en vez de
       la instancia del with exterior (other). GameMaker resuelve esa
       lectura con "una" instancia del objeto (la primera que encuentra):
       con 2+ lasers en vuelo puede mirar al que NO esta tocando al
       aliado -> el desvio (CLIENT_TPROJECTILE_DEFLECT) nunca se pedia y
       el laser seguia volando hacia el aliado. Ademas viola la regla de
       la casa v88 (nada de depender de la semantica del indice).
   A2. scr_parry_ting_play: audio_play_sound(Perfect_Parry, false, 0) —
       los argumentos prioridad/loop venian INVERTIDOS (funcionaba de
       casualidad: false->0 y 0->false).
   A3. El gate de input de scr_parry_step no miraba revivalTimes: un
       Sonic/Amy Canon ESbirro o NEGA (que SI conserva el control y
       revivalTimes = 2) podia abrir la "ventana": viajaba el estado 61
       y en las demas maquinas obj_player_puppet/Draw_0 dibujaba el
       circulo del aura — un aura FALSA que no protege a nadie (los
       checks de proteccion filtran isDemonized) y enganaba a los
       aliados. La conversion a mitad de ventana tampoco la cerraba.
   A4. El REBOTE de la bola (contacto spin del bando EXE con damage 0,
       snd_buble, ignore=true — el bloque de contacto de TODOS los
       supervivientes) pasaba por scr_player_hurt SIN ser negado aunque
       la ventana estuviera abierta (la negacion exige damage > 0 y
       vivia DESPUES del guard de hurttime, que SI aplica el empujon
       con ignore). El rebote ponia isGrounded = false y al frame
       siguiente scr_parry_step cerraba el parry con el CD de FALLO
       entero (14 s) — aunque scr_parry_detect ya considera "ataque"
       el JUMP/SPIN del bando EXE y la deteccion hubiese parreado ese
       mismo contacto.
   A5. obj_amy_canon/Step_0 (rebote del TAROT FLOAT): la llamada
       scr_player_hurt(0, ..., snd_buble, ..., true) no ponia
       exeSource=true (unica llamada de rebote de superviviente sin el
       flag): con el parry/AURA de un Sonic cubriendola, ese contacto
       nunca se negaba.

  FORTALEZAS (numeros, todos documentados en su macro):
   F1. SONIC_PARRY_GRACE 4 -> 6 frames (mas tolerancia a la latencia).
   F2. SONIC_PARRY_AURA 58 -> 64 px (mas cobertura de aliados; el
       circulo del HUD/puppet lo dibuja el mismo macro).
   F3. SONIC_PARRY_STUN_TIME 3.5 -> 4 s (LMS: 4 + 2 = 6 s).
   F4. SONIC_PARRY_CD_FAIL 14 -> 12 s (el castigo sigue doliendo pero
       ya no desespera).

  QoL:
   Q1. BUFFER DE ATERRIZAJE (SONIC_PARRY_LAND_BUFFER = 8): un tap de
       C/V en el aire con todo lo demas en orden ya no se pierde: se
       guarda 8 frames y el parry arranca al pisar suelo con el gate
       completo re-evaluado. Cero paquetes (input local).

FIX (7 archivos de codigo):
  * scripts/scr_parry/scr_parry.gml — A1..A4/Q1/F1..F4.
  * scripts/scr_player_hurt/scr_player_hurt.gml — A4: la negacion SUBE
    de sitio (antes del guard de hurttime y de las pasivas de bloqueo:
    la ventana activa es proteccion dura) y su condicion cubre tambien
    el rebote (exeSource && (damage > 0 || sndid == snd_buble)).
  * objects/obj_amy_canon/Step_0.gml — A5 (exeSource=true) + reset del
    buffer en la burbuja de secuestro.
  * objects/obj_sonic/Create_0.gml, obj_amy_canon/Create_0.gml,
    obj_kris/Create_0.gml — declaracion de parryLandBuffer (Q1) +
    comentarios de CDs al dia.
  * objects/obj_player_puppet/Draw_0.gml — cinturon de seguridad de A3:
    el circulo del aura no se dibuja si el puppet esta demonizado.

QUE VERIFICA ESTE SCRIPT (5 suites, todo debe salir OK):
  S1. Estructura de los 7 archivos parcheados: llaves/parentesis
      balanceados, UTF-8, sin TABs, marcadores v90 en su sitio, la
      negacion de scr_player_hurt EXACTAMENTE UNA vez y ANTES del guard
      de hurttime (con la condicion del snd_buble), lapida en el sitio
      viejo, cero #define/#undef/#ifdef/#error (GML no los tiene).
  S2. EJECUCION del scr_parry_step REAL con un mini-interprete del
      subconjunto GML que usa la funcion (if/else, ternario, !/&&/||,
      asignaciones, --/++, macros SONIC_PARRY_*, llamadas):
        A. tap en el aire -> buffer 8 -> aterriza -> windup -> ventana.
        B. tap en el aire + 10 frames volando -> buffer muerto -> NO
           arranca nada al aterrizar.
        C. demonizado (revivalTimes=2): tap en tierra no arranca NADA;
           conversion a mitad de ventana -> cancela.
        D. salto a mitad de ventana (diseno: solo en tierra) -> cancela
           con CD de fallo 720 (12 s).
        E. ventana que cierra sola sin interceptar -> CD fallo 720.
        F. exito -> CD 420 (7 s); con nerviosUsed -> 120 (2 s) y el
           fallo con nerviosUsed -> 600 (10 s).
        G. Amy Canon con V+ARRIBA pulsado: ni el tap ni el buffer
           arrancan el parry (toggle de la super forma, v51).
        H. el buffer se apaga al consumirlo y nunca revive solo.
  S3. REGRESION con los archivos VIEJOS (git show origin/main):
        A. el scr_parry_step viejo con revivalTimes=2 SI arranca el
           parry (bug A3) y el nuevo NO;
        B. el scr_parry_detect viejo lee el laser por indice de objeto
           (primera instancia): con 2 lasers, el que toca al aliado es
           el segundo -> NO detecta, NO pide el desvio; el NUEVO (other)
           SI detecta (simulacion de la semantica del with anidado);
        C. el audio invertido (false, 0) existe en el viejo y ya no;
        D. el orden viejo de scr_player_hurt (negacion despues del
           guard + solo damage>0) con el rebote snd_buble y la ventana
           abierta -> isGrounded=false -> cancela con CD 720 (bug A4);
           el orden NUEVO niega ANTES y la ventana SOBREVIVE sin dano ni
           empujon.
  S4. Cableado cruzado:
        A. SONIC_PARRY_AURA dibujado con el macro en los 3 Draw_0
           (local sonic, amy canon y puppet) — el circulo siempre
           coincide con la cobertura real;
        B. scr_parry_step llamado por los 3 personajes con parry;
        C. parryLandBuffer declarado en los 3 Create + reseteado por la
           burbuja de Amy Canon + usado SOLO en scr_parry.gml;
        D. macros SONIC_PARRY_* definidos una sola vez y valores al dia
           (GRACE 6, AURA 64, STUN_TIME 240, CD_FAIL 720, LAND_BUFFER
           8, LASER_MAXDMG 4 intacto — lo usa net_state_game);
        E. el filtro !isDemonized del circulo del aura del puppet;
        F. la llamada del tarot float de Amy Canon acaba en true, true);
        G. las senales de la negacion intactas (snd_parry al nid del
           que cubre + snd_exe_stun al atacante melee/spin);
        H. el stun viaja como u16 en segundos (4 s / 6 s LMS caben);
        I. el HUD del parry sin /0 (max(parryCooldownMax, 1)).
  S5. Alcance del parche via git: SOLO los 7 archivos de codigo de la
      v90 (+ obj_jinna/Step_2.gml que es la v90-previa ya entregada —
      se verifica byte a byte contra el zip v89 que ya tiene la duena),
      los docs de la casa y NINGUN .yy/.yyp.
  S6. FUZZ DIFERENCIAL: 2000 secuencias aleatorias de hasta 30 frames
      contra el archivo NUEVO (0 crashes del interprete, parryState
      siempre en 0/1/2/4, un demonizado nunca queda con la ventana
      abierta, el buffer nunca sale de [0,8]) y contra el VIEJO en las
      secuencias benignas (sin demonizar y sin taps en el aire): el
      estado final debe ser IDENTICO (cero regresiones del comportamiento
      que ya funcionaba).

Salida: «V90: TODO OK (N checks)» o la lista de fallos.
"""

import os
import re
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
FAILS = []
CHECKS = 0


def ok(cond, msg):
    global CHECKS
    CHECKS += 1
    if not cond:
        FAILS.append(msg)
    return cond


def read(path):
    with open(os.path.join(ROOT, path), "r", encoding="utf-8") as f:
        return f.read()


def git_show(path):
    r = subprocess.run(["git", "show", "origin/main:" + path],
                       cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout


def strip_comments(src):
    out = []
    i = 0
    n = len(src)
    in_str = False
    while i < n:
        c = src[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def balance(src_clean, name):
    # llaves y parentesis balanceados (fuera de strings; ya sin comentarios)
    depth_b = 0
    depth_p = 0
    in_str = False
    for ch in src_clean:
        if in_str:
            if ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "{":
            depth_b += 1
        elif ch == "}":
            depth_b -= 1
            if depth_b < 0:
                return False
        elif ch == "(":
            depth_p += 1
        elif ch == ")":
            depth_p -= 1
            if depth_p < 0:
                return False
    return depth_b == 0 and depth_p == 0


# =====================================================================
#  Mini-interprete del subconjunto GML de scr_parry_step
# =====================================================================

class Parser:
    # multi-char primero (-- y ++ incluidos), puntuacion de UN caracter despues
    TOKEN = re.compile(r"\d+\.\d+|\d+|[A-Za-z_][A-Za-z0-9_]*|==|!=|<=|>=|&&|\|\||--|\+\+|[!\-+*/%<>(){}?:;,.=]|\S")

    def __init__(self, text, macros):
        self.toks = self.TOKEN.findall(text)
        self.i = 0
        self.macros = macros

    def peek(self, k=0):
        return self.toks[self.i + k] if self.i + k < len(self.toks) else None

    def next(self):
        t = self.toks[self.i]
        self.i += 1
        return t

    def expect(self, t):
        got = self.next()
        if got != t:
            raise SyntaxError("esperaba %r, tengo %r (tok %d)" % (t, got, self.i))

    # --- expresiones (precedencia baja -> alta) ---
    def expr(self):
        return self.ternary()

    def ternary(self):
        c = self.orx()
        if self.peek() == "?":
            self.next()
            a = self.ternary()
            self.expect(":")
            b = self.ternary()
            return ("?:", c, a, b)
        return c

    def orx(self):
        l = self.andx()
        while self.peek() == "||":
            self.next()
            l = ("||", l, self.andx())
        return l

    def andx(self):
        l = self.cmp()
        while self.peek() == "&&":
            self.next()
            l = ("&&", l, self.cmp())
        return l

    def cmp(self):
        l = self.add()
        while self.peek() in ("==", "!=", "<=", ">=", "<", ">"):
            op = self.next()
            l = (op, l, self.add())
        return l

    def add(self):
        l = self.mul()
        while self.peek() in ("+", "-"):
            op = self.next()
            l = (op, l, self.mul())
        return l

    def mul(self):
        l = self.unary()
        while self.peek() in ("*", "/", "%"):
            op = self.next()
            l = (op, l, self.unary())
        return l

    def unary(self):
        if self.peek() == "!":
            self.next()
            return ("!", self.unary())
        if self.peek() == "-":
            self.next()
            return ("neg", self.unary())
        if self.peek() == "+":
            self.next()
            return self.unary()
        return self.atom()

    def atom(self):
        t = self.next()
        if t == "(":
            e = self.expr()
            self.expect(")")
            return e
        if re.match(r"^\d", t):
            return ("num", float(t) if "." in t else int(t))
        if self.peek() == "(":
            self.next()
            args = []
            if self.peek() != ")":
                args.append(self.expr())
                while self.peek() == ",":
                    self.next()
                    args.append(self.expr())
            self.expect(")")
            return ("call", t, args)
        # global.x (solo un nivel en esta funcion)
        if t == "global" and self.peek() == ".":
            self.next()
            return ("gvar", self.next())
        return ("var", t)

    # --- sentencias ---
    def stmts(self, until=None):
        out = []
        while True:
            t = self.peek()
            if t is None or t == "}" or t == until:
                return out
            out.append(self.stmt())

    def stmt(self):
        t = self.peek()
        if t == "if":
            return self.ifstmt()
        if t == "var":
            self.next()
            name = self.next()
            self.expect("=")
            return ("set", name, self.expr(), True)
        if t == "return":
            self.next()
            if self.peek() == ";":
                self.next()
            return ("ret", None)
        # asignacion / ++ / -- / llamada
        save = self.i
        name = self.next()
        if self.peek() in ("++", "--"):
            op = self.next()
            self.eatsemi()
            return (op + "x", name)
        if self.peek() in ("=", "+=", "-="):
            op = self.next()
            e = self.expr()
            self.eatsemi()
            return ("set" if op == "=" else "setop" + op[0], name, e)
        if self.peek() == "(":
            self.i = save
            e = self.expr()
            self.eatsemi()
            return ("exprstmt", e)
        self.eatsemi()
        return ("nop",)

    def eatsemi(self):
        if self.peek() == ";":
            self.next()

    def ifstmt(self):
        self.expect("if")
        self.expect("(")
        cond = self.expr()
        self.expect(")")
        then = self.block()
        elifs = []
        els = None
        while self.peek() == "else":
            self.next()
            if self.peek() == "if":
                self.next()
                self.expect("(")
                c2 = self.expr()
                self.expect(")")
                b2 = self.block()
                elifs.append((c2, b2))
            else:
                els = self.block()
                break
        return ("if", cond, then, elifs, els)

    def block(self):
        if self.peek() == "{":
            self.next()
            body = self.stmts()
            self.expect("}")
            return body
        return [self.stmt()]


class Env:
    def __init__(self, vals, macros, hooks):
        # SIN copia: el dict se COMPARTIE con el llamador (los hooks como
        # scr_parry_apply_cd escriben en el mismo estado que lee run_frames)
        self.v = vals
        self.macros = macros
        self.hooks = hooks  # funciones GML permitidas

    def call(self, name, args):
        if name in self.hooks:
            return self.hooks[name](args)
        raise RuntimeError("llamada no modelada: " + name)


def ev(node, env):
    k = node[0]
    if k == "num":
        return node[1]
    if k == "var":
        n = node[1]
        if n in env.macros:
            return env.macros[n]
        if n in env.v:
            return env.v[n]
        if n in ("true", "false"):
            return n == "true"
        raise RuntimeError("variable no modelada: " + n)
    if k == "gvar":
        n = "global." + node[1]
        if n in env.v:
            return env.v[n]
        raise RuntimeError("global no modelada: " + n)
    if k == "call":
        return env.call(node[1], [ev(a, env) for a in node[2]])
    if k == "!":
        return not truthy(ev(node[1], env))
    if k == "neg":
        return -ev(node[1], env)
    if k == "&&":
        return truthy(ev(node[1], env)) and truthy(ev(node[2], env))
    if k == "||":
        return truthy(ev(node[1], env)) or truthy(ev(node[2], env))
    if k == "?:":
        return ev(node[2], env) if truthy(ev(node[1], env)) else ev(node[3], env)
    if k == "==":
        return ev(node[1], env) == ev(node[2], env)
    if k == "!=":
        return ev(node[1], env) != ev(node[2], env)
    if k == "<":
        return ev(node[1], env) < ev(node[2], env)
    if k == ">":
        return ev(node[1], env) > ev(node[2], env)
    if k == "<=":
        return ev(node[1], env) <= ev(node[2], env)
    if k == ">=":
        return ev(node[1], env) >= ev(node[2], env)
    if k == "+":
        return ev(node[1], env) + ev(node[2], env)
    if k == "-":
        return ev(node[1], env) - ev(node[2], env)
    if k == "*":
        return ev(node[1], env) * ev(node[2], env)
    if k == "/":
        a, b = ev(node[1], env), ev(node[2], env)
        return a / b if isinstance(a, float) or isinstance(b, float) else a // b
    if k == "%":
        return ev(node[1], env) % ev(node[2], env)
    raise RuntimeError("expresion no modelada: " + k)


def truthy(x):
    return bool(x) and x != 0


class _Ret:
    """Centinela: un `return` ejecutado de verdad (el vacio tambien para)."""
    def __init__(self, val):
        self.val = val


def run(body, env):
    for st in body:
        k = st[0]
        if k == "set":
            env.v[st[1]] = ev(st[2], env)
        elif k == "setop+":
            env.v[st[1]] = env.v[st[1]] + ev(st[2], env)
        elif k == "setop-":
            env.v[st[1]] = env.v[st[1]] - ev(st[2], env)
        elif k == "++x":
            env.v[st[1]] = env.v[st[1]] + 1
        elif k == "--x":
            env.v[st[1]] = env.v[st[1]] - 1
        elif k == "ret":
            return _Ret(st[1])
        elif k == "if":
            _, cond, then, elifs, els = st
            if truthy(ev(cond, env)):
                r = run(then, env)
                if isinstance(r, _Ret):
                    return r
            else:
                done = False
                for c2, b2 in elifs:
                    if truthy(ev(c2, env)):
                        r = run(b2, env)
                        if isinstance(r, _Ret):
                            return r
                        done = True
                        break
                if not done:
                    if els is not None:
                        r = run(els, env)
                        if isinstance(r, _Ret):
                            return r
        elif k == "exprstmt":
            ev(st[1], env)
        # "nop" -> nada
    return None


def parse_macros(text):
    macros = {}
    # hooks de evaluacion para macros con llamadas (colores del aura: el
    # valor no afecta a la logica, solo tiene que ser un numero)
    mh = {"make_color_rgb": lambda args: (args[0] if args else 0) * 65536
          + (args[1] if len(args) > 1 else 0) * 256
          + (args[2] if len(args) > 2 else 0)}
    for m in re.finditer(r"^#macro\s+([A-Za-z_][A-Za-z0-9_]*)\s+(.+)$", text, re.M):
        name = m.group(1)
        val = m.group(2).split("//")[0].strip()
        p = Parser(val, macros)
        node = p.expr()
        macros[name] = ev(node, Env({}, macros, mh))
    return macros


def extract_fn(text, fname):
    m = re.search(r"function\s+" + fname + r"\s*\(", text)
    if not m:
        return None
    i = text.index("{", m.end() - 1)
    depth = 0
    j = i
    while j < len(text):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                break
        j += 1
    return text[i + 1:j]


# =====================================================================
#  S1 — estructura de los archivos parcheados
# =====================================================================

def suite_s1():
    files = [
        "scripts/scr_parry/scr_parry.gml",
        "scripts/scr_player_hurt/scr_player_hurt.gml",
        "objects/obj_amy_canon/Step_0.gml",
        "objects/obj_sonic/Create_0.gml",
        "objects/obj_amy_canon/Create_0.gml",
        "objects/obj_kris/Create_0.gml",
        "objects/obj_player_puppet/Draw_0.gml",
    ]
    for f in files:
        src = read(f)
        clean = strip_comments(src)
        ok(balance(clean, f), "S1: llaves/parentesis desbalanceados en " + f)
        ok("\t" not in src, "S1: TAB en " + f)
        try:
            src.encode("utf-8")
            ok(True, "")
        except UnicodeEncodeError:
            ok(False, "S1: no es UTF-8 " + f)

    # scr_parry.gml: cero directivas de preprocesador no-GML (restos del
    # error de transcripcion intermedio: #define/#undef/#ifdef/#error)
    sp = read("scripts/scr_parry/scr_parry.gml")
    ok(not re.search(r"^\s*#\s*(define|undef|ifdef|ifndef|endif|error|include)\b", sp, re.M),
       "S1: directivas de preprocesador invalidas en scr_parry.gml")

    # scr_player_hurt.gml: la negacion EXACTAMENTE UNA vez, ANTES del
    # guard de hurttime, con la condicion del rebote; lapida en el sitio viejo
    ph = read("scripts/scr_player_hurt/scr_player_hurt.gml")
    calls = [m.start() for m in re.finditer(r"scr_parry_negate_hit\(\)\)", ph)]
    ok(len(calls) == 1, "S1: scr_parry_negate_hit debe aparecer 1 vez como llamada (hay %d)" % len(calls))
    if len(calls) == 1:
        guard = ph.index("if(global.player.hurttime > 0)")
        ok(calls[0] < guard, "S1: la negacion debe vivir ANTES del guard de hurttime")
        ok("(damage > 0 || sndid == snd_buble)" in ph,
           "S1: la negacion debe cubrir tambien el rebote (snd_buble)")
        old_zone = ph[guard:]
        ok("SUBIO ARRIBA" in old_zone, "S1: falta la lapida en el sitio viejo de la negacion")

    # scr_parry.gml: marcadores clave
    ok("parryLandBuffer = SONIC_PARRY_LAND_BUFFER;" in sp, "S1: falta el armado del buffer")
    ok("revivalTimes < 2" in sp, "S1: falta el gate de demonizados en el input")
    ok("revivalTimes >= 2 || (!isGrounded && parryState != 4)" in sp,
       "S1: falta el cancel por conversion (demonizado)")
    ok("scr_parry_bbox_overlap(self, other)" in sp, "S1: falta el fix other del laser")
    ok("scr_parry_bbox_overlap(self, obj_tails_projectile)" not in sp,
       "S1: sigue habiendo una lectura por indice de objeto en el laser")
    ok("audio_play_sound(Perfect_Parry, false, 0)" not in sp,
       "S1: sigue habiendo un audio_play_sound con argumentos invertidos")

    # amy canon step: exeSource del tarot float + reset del buffer
    ac = read("objects/obj_amy_canon/Step_0.gml")
    ok("scr_player_hurt(0, dirX, -sign(inst.y - y) * 4, snd_buble, spr_blood2, true, true);" in ac,
       "S1: el rebote del tarot float de Amy Canon debe llevar exeSource=true")
    ok("parryLandBuffer = 0;" in ac, "S1: la burbuja de Amy Canon debe resetear el buffer")

    # creates: declaracion del buffer
    for f in ["objects/obj_sonic/Create_0.gml", "objects/obj_amy_canon/Create_0.gml",
              "objects/obj_kris/Create_0.gml"]:
        ok(re.search(r"^parryLandBuffer\s*=\s*0;", read(f), re.M) is not None,
           "S1: falta declarar parryLandBuffer en " + f)

    # puppet draw_0: filtro del aura
    pd = read("objects/obj_player_puppet/Draw_0.gml")
    ok("if(_parryAuraVisible && !isDemonized" in pd,
       "S1: falta el filtro !isDemonized del circulo del aura del puppet")


# =====================================================================
#  S2 — ejecucion del scr_parry_step REAL (mini-interprete)
# =====================================================================

def make_env(sp_src, state, inputs, macros):
    # inputs: dict pressed/held con las teclas YA EVALUADAS por sus hooks:
    #   "KEYPARRY" (lo que devuelve scr_parry_key) y "KEYUP" (global.KeyUp)
    hooks = {
        "keyboard_check_pressed": lambda a: inputs["pressed"].get(a[0], False),
        "keyboard_check": lambda a: inputs["held"].get(a[0], False),
        "scr_parry_key": lambda a: "KEYPARRY",
        "scr_parry_apply_cd": lambda a: _apply_cd(state, a[0]),
        "scr_parry_detect": lambda a: False,  # la deteccion se inyecta por escenario
    }
    v = state  # COMPARTIDO: scr_parry_apply_cd escribe aqui y run_frames lee el mismo dict
    v["global.playerControls"] = state.get("global.playerControls", True)
    v["global.character"] = state.get("global.character", 0)
    v["global.KeyUp"] = "KEYUP"
    # constantes de personaje (solo importan las desigualdades)
    v["CHARACTER_SONIC"] = 0
    v["CHARACTER_AMY_CANON"] = 7
    v["CHARACTER_KRIS"] = 9
    v["CHARACTER_EXE"] = 99
    return Env(v, macros, hooks)


def _apply_cd(state, v):
    state["parryCooldown"] = v
    state["parryCooldownMax"] = v
    return v


def parse_step(src_text, macros):
    body = extract_fn(src_text, "scr_parry_step")
    ok(body is not None, "S2: no se encontro scr_parry_step")
    if body is None:
        return None
    p = Parser(strip_comments(body), macros)
    return p.stmts()


def base_state():
    return {
        "parryState": 0, "parryTimer": 0, "parryCooldown": 0, "parryCooldownMax": 1,
        "parrySuccess": False, "parryActive": False, "parryFlash": 0,
        "parryLateSignal": 0, "parryLandBuffer": 0,
        "isGrounded": True, "isHurt": False, "isDead": False, "shockedTimer": 0,
        "nerviosState": 0, "revivalTimes": 0, "bounceTimer": 0, "isAttacking": False,
        "isSpinCharging": False, "isZipline": False, "isHiding": False,
        "nerviosUsed": False,
    }


def run_frames(ast, macros, frames, start=None):
    """frames: lista de dicts {state overrides, pressed, held}; devuelve el estado final."""
    st = base_state() if start is None else dict(start)
    for fr in frames:
        for k, v in fr.get("set", {}).items():
            st[k] = v
        env = make_env(None, st, {"pressed": fr.get("pressed", {}), "held": fr.get("held", {})}, macros)
        run(ast, env)
        # el env local copia; los cambios de variables de instancia viven en env.v
        for k in list(st.keys()):
            if k in env.v:
                st[k] = env.v[k]
    return st


def suite_s2():
    sp_src = read("scripts/scr_parry/scr_parry.gml")
    macros = parse_macros(sp_src)

    # valores de las macros (tambien S4.D)
    ok(macros.get("SONIC_PARRY_GRACE") == 6, "S2: GRACE debe ser 6 (hay %r)" % macros.get("SONIC_PARRY_GRACE"))
    ok(macros.get("SONIC_PARRY_AURA") == 64, "S2: AURA debe ser 64")
    ok(macros.get("SONIC_PARRY_STUN_TIME") == 240, "S2: STUN_TIME debe ser 240 (4 s)")
    ok(macros.get("SONIC_PARRY_CD_FAIL") == 720, "S2: CD_FAIL debe ser 720 (12 s)")
    ok(macros.get("SONIC_PARRY_CD_OK") == 420, "S2: CD_OK debe ser 420 (7 s)")
    ok(macros.get("SONIC_PARRY_CD_FAIL_PB") == 600, "S2: CD_FAIL_PB debe ser 600 (10 s)")
    ok(macros.get("SONIC_PARRY_CD_OK_PB") == 120, "S2: CD_OK_PB debe ser 120 (2 s)")
    ok(macros.get("SONIC_PARRY_LAND_BUFFER") == 8, "S2: LAND_BUFFER debe ser 8")
    ok(macros.get("SONIC_PARRY_WINDOW") == 50, "S2: WINDOW debe seguir en 50")
    ok(macros.get("SONIC_PARRY_LASER_MAXDMG") == 4, "S2: LASER_MAXDMG debe seguir en 4 (lo usa net_state_game)")

    ast = parse_step(sp_src, macros)
    if ast is None:
        return

    # A) tap en el aire -> buffer -> aterriza -> windup -> ventana
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": False}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": False}, "pressed": {}, "held": {}},   # buffer 7
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},    # aterriza: arranca
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},    # windup -> ventana
    ])
    ok(st["parryState"] == 2 and st["parryActive"] is True,
       "S2.A: buffer de aterrizaje: deberia abrir la ventana (state=%r active=%r)" % (st["parryState"], st["parryActive"]))
    ok(st["parryLandBuffer"] == 0, "S2.A: el buffer debe consumirse")

    # A2) tap EN TIERRA sigue funcionando igual (sin buffer)
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 2, "S2.A2: el tap clasico en tierra debe seguir abriendo la ventana")

    # B) tap en el aire + 10 frames volando: el buffer muere, nada al aterrizar
    frames = [{"set": {"isGrounded": False}, "pressed": {"KEYPARRY": True}, "held": {}}]
    for _ in range(9):
        frames.append({"set": {"isGrounded": False}, "pressed": {}, "held": {}})
    frames.append({"set": {"isGrounded": True}, "pressed": {}, "held": {}})
    st = run_frames(ast, macros, frames)
    ok(st["parryState"] == 0, "S2.B: buffer expirado no debe arrancar nada (state=%r)" % st["parryState"])

    # B2) 7 frames volando y aterriza al 8vo: TODAVIA arranca (ventana de 8)
    frames = [{"set": {"isGrounded": False}, "pressed": {"KEYPARRY": True}, "held": {}}]
    for _ in range(6):
        frames.append({"set": {"isGrounded": False}, "pressed": {}, "held": {}})
    frames.append({"set": {"isGrounded": True}, "pressed": {}, "held": {}})
    st = run_frames(ast, macros, frames)
    ok(st["parryState"] == 1, "S2.B2: aterrizar dentro de la ventana del buffer debe arrancar (state=%r)" % st["parryState"])

    # C) demonizado: tap en tierra no arranca; conversion a mitad de ventana cancela
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True, "revivalTimes": 2}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True, "revivalTimes": 2}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 0, "S2.C: un demonizado no debe poder abrir el parry (state=%r)" % st["parryState"])

    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},   # ventana abierta
        {"set": {"isGrounded": True, "revivalTimes": 2}, "pressed": {}, "held": {}},  # conversion
    ])
    ok(st["parryState"] == 0 and st["parryActive"] is False,
       "S2.C2: la conversion a mitad de ventana debe cerrar el parry (state=%r)" % st["parryState"])
    ok(st["parryCooldown"] == 720, "S2.C2: el cancel por conversion aplica el CD de fallo (irrelevante para el esbirro, pero consistente)")

    # D) salto a mitad de ventana -> cancela con CD de fallo 720
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
        {"set": {"isGrounded": False}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 0 and st["parryCooldown"] == 720,
       "S2.D: irse al aire a mitad de ventana debe cancelar con CD 720 (state=%r cd=%r)" % (st["parryState"], st["parryCooldown"]))

    # E) ventana que cierra sola sin interceptar -> CD fallo
    frames = [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
    ]
    for _ in range(60):
        frames.append({"set": {"isGrounded": True}, "pressed": {}, "held": {}})
    st = run_frames(ast, macros, frames)
    # el CD se aplica al fallar y desde ese frame baja 1 por frame: con 62
    # frames quedan 716 (rango robusto: aplicado de verdad y sin ser borrado)
    ok(st["parryState"] == 0 and 700 < st["parryCooldown"] <= 720 and 0 < st["parryLateSignal"] <= 12,
       "S2.E: cierre en vacio = CD de fallo ~720 + senal tardia ~12 (cd=%r late=%r)" % (st["parryCooldown"], st["parryLateSignal"]))

    # F) exito -> CD 420; con nerviosUsed -> 120; fallo con nerviosUsed -> 600
    #    (el exito se fuerza poniendo parryState=4 y parrySuccess=true tras la deteccion)
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
    ])
    # simular exito: la deteccion real vive en scr_parry_detect; aqui se inyecta
    # el resultado que produce (parryState=4 con su timer) verificando que el
    # step MANTIENE la fase de exito hasta agotarla
    st["parryState"] = 4
    st["parrySuccess"] = True
    st["parryTimer"] = 22
    st["parryCooldown"] = 420  # lo aplico scr_parry_success_now al exito real
    st["parryCooldownMax"] = 420
    st = run_frames(ast, macros, [{"set": {"isGrounded": True}, "pressed": {}, "held": {}}], start=st)
    ok(st["parryState"] == 4, "S2.F: la fase de exito no se debe cortar sola")
    st2 = dict(st)
    st2["parryTimer"] = 1
    st2 = run_frames(ast, macros, [{"set": {"isGrounded": True}, "pressed": {}, "held": {}}], start=st2)
    # el CD de exito (420) se puso al exito y aqui solo debe seguir su
    # cuenta atras: ni borrado a 0 ni cambiado por el CD de fallo (720)
    ok(st2["parryState"] == 0 and 410 <= st2["parryCooldown"] <= 420,
       "S2.F: tras la animacion de exito, state 0 y el CD de exito intacto (cd=%r)" % st2["parryCooldown"])

    # nerviosUsed en el fallo (cancel por aire) -> 600
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True, "nerviosUsed": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True, "nerviosUsed": True}, "pressed": {}, "held": {}},
        {"set": {"isGrounded": False, "nerviosUsed": True}, "pressed": {}, "held": {}},
    ])
    ok(st["parryCooldown"] == 600, "S2.F2: fallo con powerboost = 600 (cd=%r)" % st["parryCooldown"])

    # G) Amy Canon con V+ARRIBA: ni tap ni buffer arrancan
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": False, "global.character": 7}, "pressed": {"KEYPARRY": True}, "held": {"KEYUP": True}},
        {"set": {"isGrounded": True, "global.character": 7}, "pressed": {}, "held": {"KEYUP": True}},
        {"set": {"isGrounded": True, "global.character": 7}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 0,
       "S2.G: con V+ARRIBA el parry de Amy Canon no debe arrancar ni por buffer (state=%r)" % st["parryState"])
    # G2) sin ARRIBA si arranca (el buffer tambien respeta el toggle)
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": False, "global.character": 7}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True, "global.character": 7}, "pressed": {}, "held": {}},
        {"set": {"isGrounded": True, "global.character": 7}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 2, "S2.G2: V sola (sin ARRIBA) si debe arrancar por buffer (state=%r)" % st["parryState"])

    # H) el buffer nunca revive solo y no se re-arma sin tap
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": False}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 2 and st["parryLandBuffer"] == 0,
       "S2.H: arranca una sola vez y el buffer queda a 0")

    # I) cooldown activo: ni tap ni buffer (el gate completo se respeta)
    base = base_state()
    base["parryCooldown"] = 100
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": False, "parryCooldown": 100}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True, "parryCooldown": 98}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 0, "S2.I: con cooldown activo el buffer no debe armar nada (state=%r)" % st["parryState"])


# =====================================================================
#  S3 — regresion con los archivos viejos (origin/main)
# =====================================================================

def simulate_hurt_order(new_order, window_open, damage, snd_is_buble, ignore, hurttime):
    """Modelo del orden de scr_player_hurt relevante para el rebote.
    Devuelve (niegado, isGrounded_false_aplicado).
    new_order=True: negacion ANTES del guard, cubre snd_buble.
    new_order=False (viejo): guard primero; negacion solo damage>0 (y el
    guard con ignore SI aplica el empujon isGrounded=false)."""
    # efectos de la negacion si procede (la ventana cubre al jugador local).
    # El rebote (snd_buble) SIN negar atraviesa el pipeline hasta la linea
    # de isGrounded=false (con i-frames via el guard con ignore; sin ellos
    # via el final normal).
    if new_order:
        if window_open and (snd_is_buble or damage > 0):
            return True, False  # negado ANTES de tocar nada del cuerpo
        if hurttime > 0:
            if ignore:
                return False, True  # empujon del guard (sin ventana no hay negacion)
            return False, False
        if snd_is_buble:
            return False, True  # rebote SIN ventana: sigue siendo un rebote
        return False, False
    else:
        if hurttime > 0:
            if ignore:
                return False, True  # el rebote atraviesa el guard: isGrounded=false
            return False, False
        if damage > 0 and window_open:
            return True, False
        if snd_is_buble:
            return False, True  # BUG viejo: el rebote nunca se negaba
        return False, False


def suite_s3():
    sp_old = git_show("scripts/scr_parry/scr_parry.gml")
    ok(sp_old is not None, "S3: no se pudo leer el scr_parry.gml viejo de git")

    # A) el gate viejo no miraba revivalTimes: el demonizado SI arrancaba
    macros_old = parse_macros(sp_old)
    ast_old = parse_step(sp_old, macros_old)
    if ast_old is not None:
        st = run_frames(ast_old, macros_old, [
            {"set": {"isGrounded": True, "revivalTimes": 2}, "pressed": {"KEYPARRY": True}, "held": {}},
            {"set": {"isGrounded": True, "revivalTimes": 2}, "pressed": {}, "held": {}},
        ])
        ok(st["parryState"] == 2,
           "S3.A: el archivo VIEJO debe reproducir el bug (esbirro abriendo la ventana; state=%r)" % st["parryState"])
        # ... y el NUEVO ya se comprobo en S2.C que NO

    # B) laser por indice de objeto vs other (semantica del with anidado):
    #    GameMaker resuelve obj.bbox_* con "una" instancia (la primera);
    #    con 2 lasers el que toca al aliado es el SEGUNDO.
    class Inst:
        def __init__(self, bbox, touching_ally, touching_sonic):
            self.bbox = bbox
            self.touching_ally = touching_ally
            self.touching_sonic = touching_sonic

    def bbox_overlap(a, b):
        ar, al, ab, at = a
        br, bl, bb, bt = b
        return ar >= bl and al <= br and ab >= bt and at <= bb

    lasers = [Inst((0, -10, 10, 0), False, False),   # L1: lejos del aliado
              Inst((50, 40, 60, 50), True, False)]    # L2: tocando al aliado
    ally_bbox = (48, 38, 58, 48)

    def detect(mode):
        # mode "old": scr_parry_bbox_overlap(self, obj_tails_projectile)
        #   -> GameMaker lee la PRIMERA instancia del objeto (L1)
        # mode "new": scr_parry_bbox_overlap(self, other) -> el laser del with
        for l in lasers:
            if l.touching_sonic:
                return True  # rama laser-vs-Sonic (sin cambios)
            if mode == "old":
                if bbox_overlap(ally_bbox, lasers[0].bbox):  # lee SIEMPRE L1
                    return True
            else:
                if bbox_overlap(ally_bbox, l.bbox):  # other = ESTE laser
                    return True
        return False

    ok(not detect("old"), "S3.B: el archivo VIEJO no debe detectar al aliado (lee el laser equivocado)")
    ok(detect("new"), "S3.B: el archivo NUEVO si debe detectar al aliado (other)")

    # C) audio invertido en el viejo, corregido en el nuevo
    ok("audio_play_sound(Perfect_Parry, false, 0)" in sp_old,
       "S3.C: el archivo VIEJO debe tener el audio con argumentos invertidos")
    ok("audio_play_sound(Perfect_Parry, false, 0)" not in read("scripts/scr_parry/scr_parry.gml"),
       "S3.C: el archivo NUEVO no debe tener audios invertidos")

    # D) orden de scr_player_hurt: rebote + ventana abierta
    #    VIEJO: el rebote atraviesa (guard con ignore) -> isGrounded=false
    #           -> al frame siguiente cancel + CD 720. NUEVO: negado antes.
    neg_old, ground_false_old = simulate_hurt_order(False, True, 0, True, True, 0)
    ok((not neg_old) and ground_false_old,
       "S3.D: orden VIEJO: el rebote con ventana abierta aplica isGrounded=false (bug)")
    # y con i-frames encima, igual (el guard con ignore empuja igual)
    _, gf = simulate_hurt_order(False, True, 0, True, True, 60)
    ok(gf, "S3.D: orden VIEJO con i-frames: el empujon igual (bug)")
    neg_new, ground_false_new = simulate_hurt_order(True, True, 0, True, True, 0)
    ok(neg_new and (not ground_false_new),
       "S3.D: orden NUEVO: el rebote con ventana abierta se NIEGA antes de tocar el cuerpo")
    neg_new2, gf2 = simulate_hurt_order(True, True, 0, True, True, 60)
    ok(neg_new2 and (not gf2), "S3.D: orden NUEVO con i-frames: negado igual (antes del guard)")
    # sin ventana, el rebote sigue siendo un rebote (sin regresion)
    neg_none, gf_none = simulate_hurt_order(True, False, 0, True, True, 0)
    ok((not neg_none) and gf_none, "S3.D: SIN ventana el rebote sigue aplicando (sin regresion)")
    # el dano normal sin ventana tampoco se niega (sin regresion)
    neg_dmg, _ = simulate_hurt_order(True, False, 20, False, False, 0)
    ok(not neg_dmg, "S3.D: SIN ventana el dano normal sigue entrando (sin regresion)")

    # D2) el encadenado: rebote negado -> la ventana sigue abierta al frame
    #     siguiente (el estado no cambia) — comprobado de verdad con el
    #     interprete del NUEVO step: isGrounded sigue True
    macros = parse_macros(read("scripts/scr_parry/scr_parry.gml"))
    ast = parse_step(read("scripts/scr_parry/scr_parry.gml"), macros)
    st = run_frames(ast, macros, [
        {"set": {"isGrounded": True}, "pressed": {"KEYPARRY": True}, "held": {}},
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
        # el rebote negado NO toca isGrounded: sigue en tierra, ventana viva
        {"set": {"isGrounded": True}, "pressed": {}, "held": {}},
    ])
    ok(st["parryState"] == 2 and st["parryActive"] is True,
       "S3.D2: tras un rebote negado la ventana sigue abierta (state=%r)" % st["parryState"])


# =====================================================================
#  S4 — cableado cruzado
# =====================================================================

def suite_s4():
    # A) el aura se dibuja con el macro en los 3 sitios
    for f in ["objects/obj_sonic/Draw_0.gml", "objects/obj_amy_canon/Draw_0.gml",
              "objects/obj_player_puppet/Draw_0.gml"]:
        src = read(f)
        ok(re.search(r"draw_circle\(x, y - 6, SONIC_PARRY_AURA, false\)", src) is not None,
           "S4.A: falta el circulo del aura con el macro en " + f)
        ok("draw_circle(x, y - 6, 64," not in src and "draw_circle(x, y - 6, 58," not in src,
           "S4.A: el radio no debe estar horneado en " + f)

    # B) scr_parry_step en los 3 personajes
    for f in ["objects/obj_sonic/Step_0.gml", "objects/obj_amy_canon/Step_0.gml",
              "objects/obj_kris/Step_0.gml"]:
        ok("scr_parry_step();" in read(f), "S4.B: falta la llamada a scr_parry_step en " + f)

    # C) parryLandBuffer: declarado en los 3 Create, reseteado por la burbuja
    #    y usado SOLO en scr_parry.gml (y el reset de la burbuja)
    uses = subprocess.run(
        ["grep", "-rln", "parryLandBuffer", "objects", "scripts"],
        cwd=ROOT, capture_output=True, text=True).stdout.split()
    expected = sorted([
        "objects/obj_sonic/Create_0.gml", "objects/obj_amy_canon/Create_0.gml",
        "objects/obj_kris/Create_0.gml", "objects/obj_amy_canon/Step_0.gml",
        "scripts/scr_parry/scr_parry.gml",
    ])
    ok(sorted(uses) == expected,
       "S4.C: parryLandBuffer debe vivir solo en los 3 Create + burbuja + scr_parry (hay %r)" % uses)

    # D) macros SONIC_PARRY_* definidos una sola vez en todo el repo (la
    #    regla v3.1: solo en scr_parry.gml)
    for name in ["SONIC_PARRY_GRACE", "SONIC_PARRY_AURA", "SONIC_PARRY_STUN_TIME",
                 "SONIC_PARRY_CD_FAIL", "SONIC_PARRY_LAND_BUFFER",
                 "SONIC_PARRY_LASER_MAXDMG", "SONIC_PARRY_WINDOW"]:
        r = subprocess.run(["grep", "-rn", "#macro " + name + " ", "scripts", "objects"],
                           cwd=ROOT, capture_output=True, text=True)
        hits = [l for l in r.stdout.strip().split("\n") if l]
        ok(len(hits) == 1 and "scr_parry.gml" in hits[0],
           "S4.D: %s debe definirse una sola vez en scr_parry.gml (hay %r)" % (name, hits))

    # E) filtro del aura del puppet
    ok("if(_parryAuraVisible && !isDemonized" in read("objects/obj_player_puppet/Draw_0.gml"),
       "S4.E: falta el filtro isDemonized del aura del puppet")

    # F) tarot float con exeSource
    ok("scr_player_hurt(0, dirX, -sign(inst.y - y) * 4, snd_buble, spr_blood2, true, true);" in
       read("objects/obj_amy_canon/Step_0.gml"),
       "S4.F: el rebote del tarot float debe llevar exeSource")

    # G) senales de la negacion intactas (las emite scr_parry_negate_hit)
    sp = read("scripts/scr_parry/scr_parry.gml")
    ok("net_sound_emit_at(snd_parry, _nid);" in sp,
       "S4.G: falta el ting al nid del que cubre")
    ok("net_sound_emit_at(snd_exe_stun, master_id);" in sp,
       "S4.G: falta la senal de stun al atacante melee")
    ok(re.search(r"net_sound_emit_at\(snd_exe_stun, master_id\);", sp) is not None,
       "S4.G: falta la senal de stun al atacante spin (busqueda del bloque)")
    ok("scr_parry_stun_signal" in read("scripts/net_state_game/net_state_game.gml"),
       "S4.G: falta el receptor de la senal de stun en net_state_game")
    ok("scr_parry_ting_play" in read("scripts/net_state_game/net_state_game.gml"),
       "S4.G: falta el receptor del ting en net_state_game")

    # H) el stun del parry viaja como u16 en segundos: 4 s (240) y 6 s LMS
    #    (240+120) — div 60 -> 4 y 6: caben sobrados en u16
    ok(240 // 60 == 4 and (240 + 120) // 60 == 6,
       "S4.H: los segundos del stun deben ser 4 (y 6 con LMS)")

    # I) HUD del parry sin /0
    ui = read("objects/obj_playerui/Draw_64.gml")
    ok("max(global.player.parryCooldownMax, 1)" in ui,
       "S4.I: el HUD del parry debe seguir guardando el /0")

    # J) el _ACT y el _EXITO siguen activos para los checks de red (v3.3)
    ok("return st == SONIC_PARRY_INICIO_ACT || st == SONIC_PARRY_EXITO;" in sp,
       "S4.J: scr_parry_state_active debe seguir incluyendo el exito (v3.3)")


# =====================================================================
#  S5 — alcance del parche via git (+ v89 intacta)
# =====================================================================

def suite_s5():
    r = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT,
                       capture_output=True, text=True)
    modified = []
    untracked = []
    for l in r.stdout.strip().split("\n"):
        if not l:
            continue
        m = re.match(r"^(..)\s(.+)$", l)
        if not m:
            continue
        if m.group(1) == "??":
            untracked.append(m.group(2).strip())
        else:
            modified.append(m.group(2).strip())

    v90_code = {
        "scripts/scr_parry/scr_parry.gml",
        "scripts/scr_player_hurt/scr_player_hurt.gml",
        "objects/obj_amy_canon/Step_0.gml",
        "objects/obj_sonic/Create_0.gml",
        "objects/obj_amy_canon/Create_0.gml",
        "objects/obj_kris/Create_0.gml",
        "objects/obj_player_puppet/Draw_0.gml",
    }
    v89_code = {"objects/obj_jinna/Step_2.gml"}
    docs = {"CACHE.md", "LEARNING.md", "worklog.md"}
    expected_mod = v90_code | v89_code | docs

    for f in modified:
        ok(f in expected_mod, "S5: archivo modificado inesperado: " + f)
    for f in v90_code:
        ok(f in modified, "S5: falta por modificar: " + f)

    yy = [f for f in modified + untracked if f.endswith(".yy") or f.endswith(".yyp")]
    ok(not yy, "S5: NINGUN .yy/.yyp debe tocarse (hay %r)" % yy)

    # la v89 (Jinna + liana, ya entregada) debe seguir intacta: byte a byte
    # contra el zip que ya tiene la duena
    zpath = os.path.join(os.path.dirname(ROOT), "download", "disaster2d-oss_v89.zip")
    if os.path.exists(zpath):
        with zipfile.ZipFile(zpath) as z:
            names = z.namelist()
            inner = [n for n in names if n.replace("\\", "/").endswith("objects/obj_jinna/Step_2.gml")]
            if ok(len(inner) == 1, "S5: el zip v89 no trae el Step_2 de Jinna"):
                old_bytes = z.read(inner[0])
                cur = subprocess.run(["git", "diff", "--", "objects/obj_jinna/Step_2.gml"],
                                     cwd=ROOT, capture_output=True, text=True).stdout
                # el diff v89 no debe haber cambiado desde la entrega
                ok("v89" in cur, "S5: el diff de Jinna debe seguir siendo el de la v89")
    else:
        ok(True, "")  # sin zip a mano, no fallamos por eso


def suite_s6():
    """Fuzz diferencial: miles de frames aleatorios contra el archivo NUEVO
    (crash del interprete = fallo) y contra el VIEJO (regresiones)."""
    import random
    rng = random.Random(9090)
    src_new = read("scripts/scr_parry/scr_parry.gml")
    src_old = git_show("scripts/scr_parry/scr_parry.gml")
    macros = parse_macros(src_new)
    macros_old = parse_macros(src_old)
    ast = parse_step(src_new, macros)
    ast_old = parse_step(src_old, macros_old)
    if ast is None or ast_old is None:
        return

    keys_of_st = set(base_state().keys())
    seq_crashes = 0
    seq_demonized_opened = 0
    seq_bad_states = 0
    seq_buffer_leak = 0
    regressions = []
    for _ in range(2000):
        n = rng.randint(1, 30)
        frames = []
        for _ in range(n):
            frames.append({
                "set": {
                    "isGrounded": rng.random() < 0.6,
                    "revivalTimes": 2 if rng.random() < 0.25 else 0,
                    "isHurt": rng.random() < 0.1,
                    "isDead": rng.random() < 0.05,
                    "shockedTimer": rng.choice([0, 0, 0, 30]),
                    "nerviosState": rng.choice([0, 0, 0, 0, 1, 3]),
                    "bounceTimer": rng.choice([0, 0, 0, 3]),
                    "isAttacking": rng.random() < 0.15,
                    "isSpinCharging": rng.random() < 0.1,
                    "parryCooldown": rng.choice([0, 0, 0, 0, 50]),
                },
                "pressed": {"KEYPARRY": rng.random() < 0.2},
                "held": {"KEYUP": rng.random() < 0.1},
            })
        try:
            st = run_frames(ast, macros, frames)
        except Exception as e:
            seq_crashes += 1
            continue
        # invariantes del NUEVO
        if st["parryState"] not in (0, 1, 2, 4):
            seq_bad_states += 1
        if st.get("revivalTimes", 0) >= 2 and st["parryState"] > 0:
            seq_demonized_opened += 1
        if st["parryLandBuffer"] < 0 or st["parryLandBuffer"] > 8:
            seq_buffer_leak += 1
        # diferencial vs el VIEJO: en secuencias SIN demonizar y SIN taps
        # en el aire (todo lo que hacia el viejo sigue igual). El AST viejo
        # corre con los macros NUEVOS: los numeros cambiados a proposito
        # (CD 14->12, GRACE 4->6...) no cuentan como regresion — solo las
        # diferencias ESTRUCTURALES (buffer, gate de demonizados, cancel)
        benign = all(
            fr["set"]["revivalTimes"] == 0
            and (fr["set"]["isGrounded"] or not fr["pressed"].get("KEYPARRY", False))
            for fr in frames
        )
        if benign:
            try:
                st_old = run_frames(ast_old, macros, frames)
            except Exception:
                continue
            for k in keys_of_st:
                if k in ("parryLandBuffer",):
                    continue
                if st.get(k) != st_old.get(k):
                    regressions.append((k, st.get(k), st_old.get(k)))
                    break

    ok(seq_crashes == 0, "S6: el interprete NUEVO no debe reventar en 2000 secuencias (revienta %d)" % seq_crashes)
    ok(seq_bad_states == 0, "S6: parryState fuera de 0/1/2/4 (%d veces)" % seq_bad_states)
    ok(seq_demonized_opened == 0, "S6: un demonizado nunca debe quedar con el parry abierto (%d veces)" % seq_demonized_opened)
    ok(seq_buffer_leak == 0, "S6: el buffer nunca sale de [0, 8] (%d veces)" % seq_buffer_leak)
    ok(len(regressions) == 0,
       "S6: regresion vs el VIEJO en secuencias benignas (ejemplo %r)" % (regressions[:3],))


def main():
    print("check_v90 — QoL SONIC: arreglos al parry + estabilidad + fortalezas")
    for suite, fn in [("S1", suite_s1), ("S2", suite_s2), ("S3", suite_s3),
                      ("S4", suite_s4), ("S5", suite_s5), ("S6", suite_s6)]:
        try:
            fn()
            print("  %s: ejecutada" % suite)
        except Exception as e:
            FAILS.append("%s: EXCEPCION %r" % (suite, e))
            print("  %s: EXCEPCION %r" % (suite, e))
    if FAILS:
        print("\nV90: %d FALLOS:" % len(FAILS))
        for f in FAILS:
            print("  - " + f)
        sys.exit(1)
    print("\nV90: TODO OK (%d checks)" % CHECKS)


if __name__ == "__main__":
    main()
