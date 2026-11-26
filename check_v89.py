#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v89.py — Verificador del FIX v89: Jinna y las lianas (tirolinas)
de Angel Island / modo HideAndSeek.

Reporte que atiende (duena, 2026-11-27): «cuando se agarra de las
lianas esas que te ayudan a pasar de lado a lado ella se queda en la
pose de agarre y no puede usar otra vez ese agarre otra vez».

DIAGNOSTICO (verificado contra los 23 personajes del repo):
  * obj_aiz_zipline (la liana) pone global.player.isZipline = true en
    _holdPlayer() mientras viaja, y SOLO lo apaga ella misma si el
    jugador se suelta con salto (KeyA) o muere. Si el viaje termina
    solo (progress -> 1), el flag queda ENCENDIDO.
  * TODOS los personajes apagan ese flag en su propio Step_2 al pisar
    suelo («if(isZipline) { if(isGrounded) isZipline = false; ...}»)
    — menos Jinna, que solo tenia un «else if(isZipline) state =
    JINNA_ZIPLINE;» al FINAL de la cadena (solo alcanzable PARADA Y
    QUIETA EN EL SUELO).
  * Consecuencia 1 (la «pose de agarre»): al aterrizar, cada vez que
    Jinna quedaba quieta caia en JINNA_ZIPLINE (spr_jinna_zipline).
  * Consecuencia 2 (no poder reusar la liana): el guard de la liana
    «if(global.player.isZipline) return;» (el que impide agarrar a
    quien ya viaja en otra, anadido con el CARRY v2) le negaba TODAS
    las lianas para siempre.

FIX (1 archivo: objects/obj_jinna/Step_2.gml):
  * Bloque estandar de tirolina (el de Sonic/Tails/Metalamy — su
    plantilla — y el resto) insertado tras el bloque de isAttacking:
    en el aire = pose de liana (JINNA_ZIPLINE, slot 19), al pisar
    suelo el flag se apaga y la maquina sigue su curso.
  * El viejo «else if(isZipline)» del final queda en codigo muerto y
    se retira (solo era alcanzable de pie: el sintoma exacto).

QUE VERIFICA ESTE SCRIPT (5 suites, todo debe salir OK):
  S1. Estructura del Step_2.gml parcheado: llaves/parentesis
      balanceados, bloque v89 presente y en su sitio (despues de
      isAttacking, antes de !isGrounded), sin TABs, indentacion de
      8, cierre del archivo identico al original («;\\n»), UTF-8.
  S2. EJECUCION del archivo REAL con un mini-interprete de GML del
      subconjunto exacto que usa Step_2 (if/else, ternario, !, &&,
      ||, comparaciones, asignaciones, return, macros JINNA_*):
        A. Viaje que termina solo (el del reporte): colgada = 19,
           al aterrizar el flag SE APAGA y el estado vuelve a IDLE
           (y sigue IDLE en los frames siguientes), el guard de la
           liana vuelve a dejarla agarrar -> segunda liana completa.
        C. Soltar con SALTO (camino que nunca estuvo roto): el flag
           lo apaga la propia liana; JUMP/FALL al aire, IDLE en
           suelo. Mismo resultado que el archivo viejo (sin
           regresion).
        D. CARRY (scr_carry): colgada de un Tails/Cream = 19 (como
           todos), scr_carry_end apaga el flag, aterriza a IDLE.
        E. Prioridades de la plantilla intactas: hurt/shocked/tele/
           trampa/minions/grabVisual/isAttacking/won/lost/spin/
           lookups/edge/movimiento pisan a la liana como en
           obj_metalamy, y con el flag encendido en el suelo el
           estado NUNCA vuelve a quedar en 19.
  S3. REGRESION: el archivo VIEJO (git show origin/main) ejecutado
      por el mismo interprete REPRODUCE el bug (en plena liana
      mostraba FALL en vez de 19; al aterrizar y quedarse quieta
      caia en 19 PARA SIEMPRE y el flag nunca se apagaba -> el guard
      le negaba todas las lianas). El nuevo archivo no reproduce
      ninguno de los dos sintomas.
  S4. Cableado cruzado (las conexiones que hacen el fix completo):
      guard y release de la liana, _holdPlayer, case JINNA_ZIPLINE
      en Draw_76 con image_speed=0 (sin Animation End), slot 19 =
      spr_jinna_zipline en scr_exe.gml y 19 < 22 slots (bounds del
      puppet), case CHARACTER_EXE en el switch de alturas de la
      liana (Jinna viaja con character==CHARACTER_EXE), ciclo de
      vida del flag en scr_carry, macros JINNA_* unicos.
  S5. Alcance del parche via git: SOLO Step_2.gml de codigo (+ los
      docs de la casa CACHE/LEARNING/worklog), NINGUN .yyp/.yy.

Salida: «V89: TODO OK (N checks)» o la lista de fallos.
"""

import os
import re
import subprocess
import sys

REPO = "."  # correr desde la raiz del repo
STEP2 = REPO + "/objects/obj_jinna/Step_2.gml"
SURV = REPO + "/scripts/scr_survivors/scr_survivors.gml"
EXE = REPO + "/scripts/scr_exe/scr_exe.gml"
ZIPS = REPO + "/objects/obj_aiz_zipline/Step_2.gml"
ZIP_CREATE = REPO + "/objects/obj_aiz_zipline/Create_0.gml"
DRAW76 = REPO + "/objects/obj_jinna/Draw_76.gml"
OTHER7 = REPO + "/objects/obj_jinna/Other_7.gml"
CARRY = REPO + "/scripts/scr_carry/scr_carry.gml"
NETSTATE = REPO + "/scripts/net_state_game/net_state_game.gml"

fails = []
oks = 0


def check(cond, msg):
    global oks
    if cond:
        oks += 1
    else:
        fails.append(msg)
    return cond


# ---------------------------------------------------------------------------
# Mini-interprete GML (el subconjunto exacto de obj_jinna/Step_2.gml)
# ---------------------------------------------------------------------------

class GmlError(Exception):
    pass


class ReturnSignal(Exception):
    pass


TOKEN_RE = re.compile(r"&&|\|\||==|!=|>=|<=|[><!+\-*/?:=,(){};]|[A-Za-z_][A-Za-z0-9_]*|[0-9]+(?:\.[0-9]+)?")


def tokenize(src):
    toks = []
    for line in src.split("\n"):
        code = line.split("//", 1)[0]
        pos = 0
        while pos < len(code):
            if code[pos].isspace():
                pos += 1
                continue
            m = TOKEN_RE.match(code, pos)
            if not m:
                raise GmlError("token ilegal en: %r" % line)
            toks.append(m.group(0))
            pos = m.end()
    return toks


class Parser:
    def __init__(self, toks):
        self.toks = toks
        self.i = 0

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else None

    def next(self):
        t = self.peek()
        self.i += 1
        return t

    def expect(self, t):
        got = self.next()
        if got != t:
            raise GmlError("esperaba %r, llego %r" % (t, got))

    def parse_program(self):
        stmts = []
        while self.peek() is not None:
            stmts.append(self.parse_stmt())
        return ("block", stmts)

    def parse_stmt_or_block(self):
        if self.peek() == "{":
            self.next()
            stmts = []
            while self.peek() != "}":
                if self.peek() is None:
                    raise GmlError("} sin cerrar")
                stmts.append(self.parse_stmt())
            self.next()  # }
            return ("block", stmts)
        return self.parse_stmt()

    def parse_stmt(self):
        t = self.peek()
        if t == "if":
            return self.parse_if()
        if t == "return":
            self.next()
            self.expect(";")
            return ("return",)
        if re.match(r"^[A-Za-z_]", t or ""):
            name = self.next()
            self.expect("=")
            value = self.parse_expr()
            self.expect(";")
            return ("assign", name, value)
        raise GmlError("statement inesperado: %r" % t)

    def parse_if(self):
        self.expect("if")
        self.expect("(")
        cond = self.parse_expr()
        self.expect(")")
        body = self.parse_stmt_or_block()
        els = None
        if self.peek() == "else":
            self.next()
            if self.peek() == "if":
                els = self.parse_if()
            else:
                els = self.parse_stmt_or_block()
        return ("if", cond, body, els)

    # --- expresiones (precedencia GML: ?: < || < && < == != < rel < + - < * / %) ---

    def parse_expr(self):
        cond = self.parse_or()
        if self.peek() == "?":
            self.next()
            a = self.parse_expr()
            self.expect(":")
            b = self.parse_expr()
            return ("ternary", cond, a, b)
        return cond

    def parse_or(self):
        l = self.parse_and()
        while self.peek() == "||":
            self.next()
            l = ("or", l, self.parse_and())
        return l

    def parse_and(self):
        l = self.parse_eq()
        while self.peek() == "&&":
            self.next()
            l = ("and", l, self.parse_eq())
        return l

    def parse_eq(self):
        l = self.parse_rel()
        while self.peek() in ("==", "!="):
            op = self.next()
            l = ("bin", op, l, self.parse_rel())
        return l

    def parse_rel(self):
        l = self.parse_add()
        while self.peek() in (">", "<", ">=", "<="):
            op = self.next()
            l = ("bin", op, l, self.parse_add())
        return l

    def parse_add(self):
        l = self.parse_mul()
        while self.peek() in ("+", "-"):
            op = self.next()
            l = ("bin", op, l, self.parse_mul())
        return l

    def parse_mul(self):
        l = self.parse_unary()
        while self.peek() in ("*", "/", "%"):
            op = self.next()
            l = ("bin", op, l, self.parse_unary())
        return l

    def parse_unary(self):
        if self.peek() == "!":
            self.next()
            return ("not", self.parse_unary())
        if self.peek() == "-":
            self.next()
            return ("neg", self.parse_unary())
        return self.parse_primary()

    def parse_primary(self):
        t = self.next()
        if t == "(":
            e = self.parse_expr()
            self.expect(")")
            return e
        if re.match(r"^[0-9]", t):
            return ("num", float(t) if "." in t else int(t))
        if t == "true":
            return ("num", 1)
        if t == "false":
            return ("num", 0)
        if re.match(r"^[A-Za-z_]", t):
            # llamada a funcion nativa (abs(...) en este archivo)
            if self.peek() == "(":
                self.next()
                args = []
                if self.peek() != ")":
                    args.append(self.parse_expr())
                    while self.peek() == ",":
                        self.next()
                        args.append(self.parse_expr())
                self.expect(")")
                return ("call", t, args)
            return ("id", t)
        raise GmlError("primario inesperado: %r" % t)


def ev(node, env, macros):
    k = node[0]
    if k == "num":
        return node[1]
    if k == "id":
        name = node[1]
        if name in macros:
            return ev(macros[name], env, macros)
        if name in env:
            return env[name]
        raise GmlError("variable sin declarar en el entorno: %s" % name)
    if k == "not":
        return 0 if truthy(ev(node[1], env, macros)) else 1
    if k == "neg":
        return -ev(node[1], env, macros)
    if k == "ternary":
        return ev(node[2] if truthy(ev(node[1], env, macros)) else node[3], env, macros)
    if k == "or":
        a = ev(node[1], env, macros)
        return a if truthy(a) else ev(node[2], env, macros)
    if k == "and":
        a = ev(node[1], env, macros)
        return ev(node[2], env, macros) if truthy(a) else a
    if k == "call":
        args = [ev(a, env, macros) for a in node[2]]
        fn = {
            "abs": lambda a: abs(a[0]),
            "min": lambda a: min(a),
            "max": lambda a: max(a),
            "sign": lambda a: (a[0] > 0) - (a[0] < 0),
            "floor": lambda a: int(a[0] // 1),
            "ceil": lambda a: int(-(-a[0] // 1)),
            "round": lambda a: int(round(a[0])),
        }.get(node[1])
        if fn is None:
            raise GmlError("funcion no soportada por el interprete: %s" % node[1])
        return fn(args)
    if k == "bin":
        op = node[1]
        a = ev(node[2], env, macros)
        b = ev(node[3], env, macros)
        if op == "==":
            return 1 if a == b else 0
        if op == "!=":
            return 1 if a != b else 0
        if op == ">":
            return 1 if a > b else 0
        if op == "<":
            return 1 if a < b else 0
        if op == ">=":
            return 1 if a >= b else 0
        if op == "<=":
            return 1 if a <= b else 0
        if op == "+":
            return a + b
        if op == "-":
            return a - b
        if op == "*":
            return a * b
        if op == "/":
            if b == 0:
                raise GmlError("division por cero")
            return a / b
        if op == "%":
            return a % b
    raise GmlError("nodo desconocido: %r" % (node,))


def truthy(v):
    return bool(v) and v != 0


def run_stmt(node, env, macros):
    k = node[0]
    if k == "block":
        for s in node[1]:
            run_stmt(s, env, macros)
        return
    if k == "return":
        raise ReturnSignal()
    if k == "assign":
        env[node[1]] = ev(node[2], env, macros)
        return
    if k == "if":
        if truthy(ev(node[1], env, macros)):
            run_stmt(node[2], env, macros)
        elif node[3] is not None:
            run_stmt(node[3], env, macros)
        return
    raise GmlError("statement desconocido: %r" % (node,))


def load_macros_from(text):
    out = {}
    for m in re.finditer(r"#macro\s+([A-Za-z_][A-Za-z0-9_]*)\s+(.+)", text):
        name, body = m.group(1), m.group(2).split("//", 1)[0].strip()
        toks = tokenize(body)
        out[name] = Parser(toks).parse_expr()
    return out


def strip_macro_lines(src):
    return "\n".join(l for l in src.split("\n") if not l.strip().startswith("#macro"))


def compile_step2(src, base_macros):
    macros = dict(base_macros)
    macros.update(load_macros_from(src))
    tree = Parser(tokenize(strip_macro_lines(src))).parse_program()
    return tree, macros


def run_frame(tree, macros, env):
    try:
        run_stmt(tree, env, macros)
    except ReturnSignal:
        pass
    return env


def fresh_env(**over):
    env = {
        "emotion": 0, "won": 0, "lost": 0, "jinnaLostState": 18,
        "isHurt": 0, "shockedTimer": 0, "jinnaTelePose": 0,
        "jinnaTrapVisual": 0, "jinnaMinionPose": 0, "jinnaGrabVisual": 0,
        "isAttacking": 0, "isZipline": 0, "isSpinning": 0,
        "isGrounded": 1, "yspd": 0, "gspd": 0, "xspd": 0,
        "maxHSpeed": 13, "isLookingUp": 0, "isLookingDown": 0,
        "isOnEdge": 0, "state": 0,
    }
    env.update(over)
    return env


# ---------------------------------------------------------------------------
# S1 — estructura del archivo parcheado
# ---------------------------------------------------------------------------

def s1_estructura(new_src):
    check(new_src.endswith(";\n") and not new_src.endswith("\n\n"),
          "S1: el archivo debe cerrar con «;\\n» exacto (convencion de la casa)")
    check("﻿" not in new_src, "S1: sin BOM")
    check("\t" not in new_src, "S1: sin TABs en Step_2.gml")

    # balance de llaves/parenesis global y por linea
    depth_b, depth_p = 0, 0
    for ln, line in enumerate(new_src.split("\n"), 1):
        depth_b += line.count("{") - line.count("}")
        depth_p += line.count("(") - line.count(")")
        check(depth_b >= 0, "S1: llave cerrada de mas en linea %d" % ln)
        check(depth_p >= 0, "S1: parentesis cerrado de mas en linea %d" % ln)
    check(depth_b == 0, "S1: llaves balanceadas al final del archivo (%d)" % depth_b)
    check(depth_p == 0, "S1: parentesis balanceados al final del archivo (%d)" % depth_p)

    lines = new_src.split("\n")

    def find_line(needle, start=0):
        for i, l in enumerate(lines):
            if i < start:
                continue
            if needle in l:
                return i
        return -1

    i_atk = find_line("state = isGrounded ? JINNA_ATTACK1 : JINNA_ATTACK2;")
    i_zip = find_line("if(isZipline)", start=i_atk)
    i_air = find_line("if(!isGrounded)", start=i_atk)
    i_spin = find_line("if(isSpinning)", start=i_atk)
    check(i_atk >= 0, "S1: bloque isAttacking presente")
    check(i_zip >= 0, "S1: bloque isZipline presente")
    check(i_air >= 0, "S1: bloque !isGrounded presente")
    check(i_spin >= 0, "S1: cierre isSpinning presente")
    check(i_atk < i_zip < i_air,
          "S1: el bloque isZipline vive entre isAttacking y !isGrounded (orden de la plantilla)")
    check(i_spin > i_air, "S1: isSpinning sigue al final (como el original)")

    # el bloque v89 completo, en orden interno exacto
    block = """if(isZipline)
{
        if(isGrounded)
                isZipline = false;
        else
        {
                state = JINNA_ZIPLINE;
                return;
        }
}"""
    check(block in new_src, "S1: bloque estandar de tirolina (forma exacta de Sonic/Metalamy)")

    # el viejo else-if muerto ya no existe (se mira el CODIGO, sin comentarios:
    # la nota v89 del final cita el texto retirado)
    code_only = "\n".join(l.split("//", 1)[0] for l in lines)
    check("else if(isZipline)" not in code_only,
          "S1: el «else if(isZipline)» muerto del final fue retirado")

    # indentacion: dentro del bloque, multiplos de 8 (las llaves de apertura/
    # cierre van a nivel del bloque y no cuentan)
    in_block = False
    for ln, line in enumerate(lines, 1):
        if line.strip() == "if(isZipline)" and not in_block:
            in_block = True
            continue
        if in_block:
            if line.strip() == "}":
                break
            if line.strip() in ("", "{"):
                continue
            ind = len(line) - len(line.lstrip(" "))
            check(ind % 8 == 0 and ind > 0,
                  "S1: indentacion %d no es multiplo de 8 positiva (linea %d)" % (ind, ln))
    # la nota v89 explica el porque
    check("v89" in new_src, "S1: nota v89 en el codigo")
    check("pose de agarre" in new_src, "S1: la nota cita el sintoma reportado")
    # sin BOM raro, UTF-8 valido
    try:
        new_src.encode("utf-8")
        check(True, "")
    except Exception as e:
        check(False, "S1: UTF-8 invalido: %s" % e)


# ---------------------------------------------------------------------------
# S2/S3 — ejecucion del archivo real (nuevo) y del viejo (regresion)
# ---------------------------------------------------------------------------

def ride_scenario(tree, macros, natural_end=True, frames_riding=3):
    """Viaje completo: agarre -> (fin natural: flag queda on | salto: flag off).
    Devuelve la traza de (state, isZipline) por frame."""
    trace = []
    env = fresh_env(isZipline=1, isGrounded=0)
    for _ in range(frames_riding):
        run_frame(tree, macros, env)
        trace.append((env["state"], env["isZipline"]))
    # fin del viaje: la liana la lanza (xspd) sin tocar el flag (natural)
    # o lo apaga ella (salto/muerte)
    if not natural_end:
        env["isZipline"] = 0
    # caida y aterrizaje
    env["isGrounded"] = 0
    env["yspd"] = 2
    run_frame(tree, macros, env)
    trace.append((env["state"], env["isZipline"]))
    env["yspd"] = 0
    env["isGrounded"] = 1
    run_frame(tree, macros, env)
    trace.append((env["state"], env["isZipline"]))
    for _ in range(4):  # frames quietos en el suelo
        run_frame(tree, macros, env)
        trace.append((env["state"], env["isZipline"]))
    return trace, env


def s2_nuevo(tree, macros):
    # --- A: viaje que termina SOLO (el reporte) ---
    trace, env = ride_scenario(tree, macros, natural_end=True)
    for i, (st, fl) in enumerate(trace[:4]):
        check(fl == 1, "S2A: flag sigue on mientras viaja (frame %d)" % i)
        check(st == 19, "S2A: en la liana/aire la pose es JINNA_ZIPLINE=19 (frame %d, state=%d)" % (i, st))
    # frame de aterrizar (indice 4: el primero del suelo)
    st_land, fl_land = trace[4]
    check(fl_land == 0, "S2A: al pisar suelo el flag SE APAGA (tenia que quedar en 0)")
    check(st_land == 0, "S2A: al pisar suelo vuelve a IDLE=0, no a la pose de agarre (state=%d)" % st_land)
    for i, (st, fl) in enumerate(trace[5:], start=5):
        check(st == 0 and fl == 0,
              "S2A: quieta en el suelo se mantiene IDLE y flag off (frame %d, state=%d)" % (i, st))

    # el guard de la liana: con el flag apagado puede volver a agarrar
    guard = fresh_env()["isZipline"]  # simbolico: el guard lee isZipline
    check(env["isZipline"] == 0,
          "S2A: «if(global.player.isZipline) return;» de la liana ahora LA DEJA agarrar otra vez")

    # --- A2: SEGUNDA liana (reuso completo) ---
    env["isZipline"] = 1
    env["isGrounded"] = 0
    env["yspd"] = 0
    run_frame(tree, macros, env)
    check(env["state"] == 19, "S2A2: segunda liana: viaja de nuevo en pose 19")
    env["isGrounded"] = 1
    run_frame(tree, macros, env)
    check(env["isZipline"] == 0 and env["state"] == 0,
          "S2A2: segunda liana: aterriza limpia (flag 0, IDLE)")

    # --- C: soltar con SALTO (camino nunca roto) ---
    trace, env = ride_scenario(tree, macros, natural_end=False)
    # frames: 0-2 viajando (flag ON), 3 en el aire YA SUELTA (flag off)
    for i in range(3):
        st, fl = trace[i]
        check(fl == 1 and st == 19, "S2C: viajando antes del salto (frame %d)" % i)
    st_air, fl_air = trace[3]
    check(fl_air == 0, "S2C: al soltar con salto la liana apaga el flag (el camino viejo intacto)")
    check(st_air == 4, "S2C: al aire con flag off = FALL=4 como siempre (state=%d)" % st_air)
    # con el flag apagado en el aire, la maquina muestra JUMP/FALL, no 19:
    env2 = fresh_env(isZipline=0, isGrounded=0, yspd=-6)
    run_frame(tree, macros, env2)
    check(env2["state"] == 3, "S2C: subiendo con flag off = JUMP=3 (state=%d)" % env2["state"])
    env3 = fresh_env(isZipline=0, isGrounded=0, yspd=4)
    run_frame(tree, macros, env3)
    check(env3["state"] == 4, "S2C: cayendo con flag off = FALL=4 (state=%d)" % env3["state"])
    env4 = fresh_env(isZipline=0, isGrounded=1)
    run_frame(tree, macros, env4)
    check(env4["state"] == 0, "S2C: aterriza a IDLE=0")

    # --- D: CARRY (colgada de un Tails/Cream volando) ---
    env5 = fresh_env(isZipline=1, isGrounded=0, yspd=0)
    run_frame(tree, macros, env5)
    check(env5["state"] == 19,
          "S2D: colgada del portador = 19 como todos los personajes (state=%d)" % env5["state"])
    env5["isZipline"] = 0  # scr_carry_end apaga el flag (hop)
    env5["yspd"] = -2
    run_frame(tree, macros, env5)
    check(env5["state"] == 3, "S2D: al soltarse del carry = JUMP=3 (state=%d)" % env5["state"])
    env5["yspd"] = 0
    env5["isGrounded"] = 1
    run_frame(tree, macros, env5)
    check(env5["state"] == 0 and env5["isZipline"] == 0, "S2D: aterriza limpia tras el carry")

    # --- E: prioridades de la plantilla (todas pisan a la liana) ---
    def prio(name, expected_state, **over):
        env = fresh_env(isZipline=1, isGrounded=0, **over)
        run_frame(tree, macros, env)
        check(env["state"] == expected_state,
              "S2E/%s: esperaba state=%d, salio %d" % (name, expected_state, env["state"]))

    prio("hurt", 5, isHurt=1)
    prio("shock_aire", 5, shockedTimer=60)
    env = fresh_env(isZipline=1, isGrounded=1, shockedTimer=60)
    run_frame(tree, macros, env)
    check(env["state"] == 16, "S2E/shock_suelo: esperaba JINNA_SHOCKED=16, salio %d" % env["state"])
    prio("tele", 21, jinnaTelePose=10)
    prio("trampa", 21, jinnaTrapVisual=10)
    prio("minions", 21, jinnaMinionPose=10)
    env = fresh_env(isZipline=1, isGrounded=1, jinnaGrabVisual=10)
    run_frame(tree, macros, env)
    check(env["state"] == 15, "S2E/grab_visual: esperaba JINNA_ATTACK2=15, salio %d" % env["state"])
    prio("ataque_aire", 15, isAttacking=1)
    env = fresh_env(isZipline=1, isGrounded=1, isAttacking=1)
    run_frame(tree, macros, env)
    check(env["state"] == 14, "S2E/ataque_suelo: esperaba JINNA_ATTACK1=14, salio %d" % env["state"])
    # spin EN EL SUELO con flag encendido: flag apagado y rueda normal (12)
    env = fresh_env(isZipline=1, isGrounded=1, isSpinning=1)
    run_frame(tree, macros, env)
    check(env["state"] == 12, "S2E/spin_suelo: esperaba SPIN=12, salio %d" % env["state"])
    check(env["isZipline"] == 0, "S2E/spin_suelo: flag apagado al pisar suelo")
    # spin EN EL AIRE con flag encendido: gana la pose de liana (19) — mismo
    # orden que Sonic/Tails/... (su bloque *_ZIPLINE hace return antes del spin)
    env = fresh_env(isZipline=1, isGrounded=0, isSpinning=1)
    run_frame(tree, macros, env)
    check(env["state"] == 19,
          "S2E/spin_aire: con la liana agarrada gana 19 como en Sonic (salio %d)" % env["state"])

    # won/lost con el flag encendido: la pose de victoria gana y el flag se apaga en suelo
    env = fresh_env(isZipline=1, isGrounded=1, won=1)
    run_frame(tree, macros, env)
    check(env["state"] == 17, "S2E/won: esperaba JINNA_WON=17, salio %d" % env["state"])
    check(env["isZipline"] == 0, "S2E/won: al estar en suelo el flag se apaga igual (gane colgada)")
    env = fresh_env(isZipline=1, isGrounded=1, lost=1)
    run_frame(tree, macros, env)
    check(env["state"] == 18, "S2E/lost: esperaba jinnaLostState=18, salio %d" % env["state"])
    check(env["isZipline"] == 0, "S2E/lost: flag apagado al perder en suelo")

    # en el suelo CON el flag: nunca mas 19 — cada estado normal gana
    for name, over, exp in [
        ("idle", {}, 0), ("walk", {"gspd": 4}, 1), ("run", {"gspd": 13}, 2),
        ("lookup", {"isLookingUp": 1}, 7), ("lookdown", {"isLookingDown": 1}, 8),
        ("edge", {"isOnEdge": 1}, 13),
    ]:
        env = fresh_env(isZipline=1, isGrounded=1, **over)
        run_frame(tree, macros, env)
        check(env["state"] == exp,
              "S2E/suelo_%s: esperaba %d, salio %d (el flag debio apagarse)" % (name, exp, env["state"]))
        check(env["isZipline"] == 0, "S2E/suelo_%s: flag apagado al pisar suelo" % name)

    # en el aire con flag encendido: JUMP si sube, 19 si cae
    env = fresh_env(isZipline=1, isGrounded=0, yspd=-1)
    run_frame(tree, macros, env)
    check(env["state"] == 19, "S2E/aire_subiendo: con flag on es 19 aunque suba (state=%d)" % env["state"])


def s3_regresion(old_tree, old_macros, new_tree, new_macros):
    # el archivo VIEJO reproduce exactamente los dos sintomas del reporte
    trace, env = ride_scenario(old_tree, old_macros, natural_end=True)
    # sintoma visual durante el viaje: FALL en vez de la pose de la liana
    st_ride = trace[0][0]
    check(st_ride == 4,
          "S3/viejo: en plena liana mostraba FALL=4, no la pose 19 (salio %d) — confirma el diagnostico" % st_ride)
    # sintoma 1: pose de agarre para siempre al quedarse quieta en el suelo
    for i, (st, fl) in enumerate(trace[4:], start=4):
        check(st == 19 and fl == 1,
              "S3/viejo: frame %d en suelo: state=%d flag=%d (el bug: 19 para siempre)" % (i, st, fl))
    # sintoma 2: el guard de la liana la bloquea para siempre
    check(env["isZipline"] == 1,
          "S3/viejo: «if(global.player.isZipline) return;» la deja sin lianas para siempre")
    # y el camino del salto SIEMPRE funciono en el viejo (sin regresion): flag off -> aire = FALL
    env2 = fresh_env(isZipline=0, isGrounded=0, yspd=4)
    run_frame(old_tree, old_macros, env2)
    check(env2["state"] == 4, "S3/viejo: suelta con salto = FALL=4 como siempre (state=%d)" % env2["state"])
    env2["isGrounded"] = 1
    run_frame(old_tree, old_macros, env2)
    check(env2["state"] == 0 and env2["isZipline"] == 0,
          "S3/viejo: aterriza a IDLE tras soltar con salto (camino nunca roto)")


# ---------------------------------------------------------------------------
# S4 — cableado cruzado con el resto del sistema
# ---------------------------------------------------------------------------

def s4_cableado(new_src):
    # la liana: guard de re-agarre + release + hold
    zsrc = open(ZIPS, encoding="utf-8").read()
    check("if(global.player.isZipline)" in zsrc and "return;" in zsrc,
          "S4: guard de re-agarre de la liana presente (el que bloqueaba a Jinna)")
    check(zsrc.count("global.player.isZipline = false;") >= 1,
          "S4: la liana apaga el flag al soltar con salto/morir (camino viejo intacto)")
    csrc = open(ZIP_CREATE, encoding="utf-8").read()
    check("global.player.isZipline = true;" in csrc,
          "S4: _holdPlayer enciende el flag (quien lo setea)")
    # Draw_76: case JINNA_ZIPLINE con image_speed = 0
    dsrc = open(DRAW76, encoding="utf-8").read()
    check("case JINNA_ZIPLINE:" in dsrc, "S4: Draw_76 ya dibuja el case JINNA_ZIPLINE")
    m = re.search(r"case HURT:\s*\n\s*case JINNA_ZIPLINE:\s*\n\s*image_speed = 0;", dsrc)
    check(m is not None,
          "S4: JINNA_ZIPLINE comparte case con HURT: image_speed=0 (frame fijo, sin Animation End)")
    check("global.player_exesanims[? EXE_JINNA][state]" in dsrc,
          "S4: Draw_76 resuelve el sprite por state en la tabla EXE_JINNA")
    # Other_7 (Animation End): sin case para el 19 (y con image_speed=0 nunca dispara)
    osrc = open(OTHER7, encoding="utf-8").read()
    check("JINNA_ZIPLINE" not in osrc,
          "S4: Other_7 no tiene case JINNA_ZIPLINE (y nunca dispara con image_speed=0)")
    # scr_exe: slot 19 = spr_jinna_zipline y la tabla tiene MAS de 19 slots
    esrc = open(EXE, encoding="utf-8").read()
    m = re.search(r"global\.player_exesanims\[\? EXE_JINNA\] =\s*\[(.*?)\];", esrc, re.S)
    check(m is not None, "S4: tabla de anims EXE_JINNA encontrada en scr_exe.gml")
    if check(m is not None, ""):
        slots = re.findall(r"(spr_[A-Za-z0-9_]+)", m.group(1))
        check(len(slots) >= 20, "S4: la tabla EXE_JINNA tiene al menos 20 slots (tiene %d)" % len(slots))
        check(len(slots) > 19 and slots[19] == "spr_jinna_zipline",
              "S4: slot 19 = spr_jinna_zipline (sale %r)" % (slots[19] if len(slots) > 19 else None))
    # macros: JINNA_ZIPLINE = BALANCING+6 = 19, unico
    jm = re.findall(r"#macro\s+JINNA_ZIPLINE\s+(.+)", new_src)
    check(len(jm) == 1, "S4: #macro JINNA_ZIPLINE definido una sola vez en Step_2")
    surv = open(SURV, encoding="utf-8").read()
    check("#macro BALANCING 13" in surv, "S4: BALANCING = 13 en scr_survivors.gml")
    check("JINNA_ZIPLINE" not in surv, "S4: JINNA_ZIPLINE no se redefine en otro lado")
    # la liana cuelga a los EXE con case propio (Jinna viaja con character==CHARACTER_EXE)
    check("case CHARACTER_EXE:" in zsrc,
          "S4: la liana tiene case CHARACTER_EXE (altura de cuelgue de Jinna cubierta)")
    check("#macro CHARACTER_EXE 0" in esrc, "S4: CHARACTER_EXE = 0 (Jinna es variante EXE, no case propio)")
    # carry: ciclo de vida del flag cerrado
    ksrc = open(CARRY, encoding="utf-8").read()
    check(re.search(r"isZipline = true;", ksrc) is not None,
          "S4: scr_carry enciende isZipline al colgarse (comentario «estado *_ZIPLINE por red»)")
    check(re.search(r"isZipline = false;", ksrc) is not None,
          "S4: scr_carry_end apaga isZipline al soltarse")
    # red: el state viaja como u8 (19 cabe de sobra)
    nsrc = open(NETSTATE, encoding="utf-8").read()
    check(re.search(r"buffer_read_s\(rbuff, buffer_u8\)", nsrc) is not None,
          "S4: el estado viaja por red como buffer_u8 (19 < 256)")
    # anti-cheat: cero superficie nueva — ni paquetes ni velocidades cambian;
    # el unico cambio de comportamiento es local (maquina de estados) y el
    # valor de state 19, el mismo slot que Metalamy usa desde siempre.
    check("packet" not in new_src.lower() and "buffer" not in new_src.lower(),
          "S4: Step_2 no toca paquetes (sin superficie anti-cheat nueva)")


# ---------------------------------------------------------------------------
# S5 — alcance del parche via git
# ---------------------------------------------------------------------------

def s5_alcance():
    try:
        diff = subprocess.run(["git", "diff", "--name-only", "origin/main"],
                              capture_output=True, text=True, check=True).stdout
        names = [n for n in diff.strip().split("\n") if n]
    except Exception as e:
        check(False, "S5: git diff fallo: %s" % e)
        return
    allowed = {
        "objects/obj_jinna/Step_2.gml",
        "CACHE.md", "LEARNING.md", "worklog.md",
    }
    for n in names:
        check(n in allowed, "S5: archivo inesperado en el diff: %s" % n)
        check(not n.endswith(".yy") and not n.endswith(".yyp"),
              "S5: NINGUN .yy/.yyp tocado (%s)" % n)
    check("objects/obj_jinna/Step_2.gml" in names,
          "S5: el unico archivo de codigo cambiado es obj_jinna/Step_2.gml")
    try:
        st = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True,
                            check=True).stdout
    except Exception as e:
        check(False, "S5: git status fallo: %s" % e)
        return
    for line in st.strip().split("\n"):
        if not line:
            continue
        code, path = line[:2], line[3:]
        if code.strip() == "??":
            check(path in ("check_v89.py", "LEEME_V89_JINNA_LIANA_FIX.txt"),
                  "S5: untracked inesperado: %s" % path)


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] in ("-h", "--help")):
        print("uso: python check_v89.py [raiz_del_repo]")
        return 1
    global REPO, STEP2, SURV, EXE, ZIPS, ZIP_CREATE, DRAW76, OTHER7, CARRY, NETSTATE
    if len(sys.argv) == 2:
        REPO = sys.argv[1]
        STEP2 = REPO + "/objects/obj_jinna/Step_2.gml"
        SURV = REPO + "/scripts/scr_survivors/scr_survivors.gml"
        EXE = REPO + "/scripts/scr_exe/scr_exe.gml"
        ZIPS = REPO + "/objects/obj_aiz_zipline/Step_2.gml"
        ZIP_CREATE = REPO + "/objects/obj_aiz_zipline/Create_0.gml"
        DRAW76 = REPO + "/objects/obj_jinna/Draw_76.gml"
        OTHER7 = REPO + "/objects/obj_jinna/Other_7.gml"
        CARRY = REPO + "/scripts/scr_carry/scr_carry.gml"
        NETSTATE = REPO + "/scripts/net_state_game/net_state_game.gml"

    if not os.path.isfile(STEP2):
        print("no encuentro %s (corre desde la raiz del repo)" % STEP2)
        return 1

    new_src = open(STEP2, encoding="utf-8").read()

    # macros base (estados compartidos de todos los personajes)
    base_macros = load_macros_from(open(SURV, encoding="utf-8").read())

    try:
        new_tree, new_macros = compile_step2(new_src, base_macros)
        check(True, "")
    except GmlError as e:
        check(False, "S2: el Step_2 nuevo no parsea: %s" % e)
        new_tree, new_macros = None, None

    try:
        old_src = subprocess.run(
            ["git", "show", "origin/main:objects/obj_jinna/Step_2.gml"],
            capture_output=True, text=True, check=True).stdout
        old_tree, old_macros = compile_step2(old_src, base_macros)
        check(True, "")
    except Exception as e:
        check(False, "S3: no pude compilar el Step_2 viejo desde git: %s" % e)
        old_tree, old_macros = None, None

    s1_estructura(new_src)
    if new_tree is not None:
        s2_nuevo(new_tree, new_macros)
    if old_tree is not None:
        s3_regresion(old_tree, old_macros, new_tree, new_macros)
    s4_cableado(new_src)
    s5_alcance()

    if fails:
        print("V89: %d OK, %d FALLOS:" % (oks, len(fails)))
        for f in fails:
            if f:
                print("  FALLO: " + f)
        return 1
    print("V89: TODO OK (%d checks)" % oks)
    return 0


if __name__ == "__main__":
    sys.exit(main())
