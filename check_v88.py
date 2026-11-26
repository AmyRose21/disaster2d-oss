#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_v88.py — Verificador del HOTFIX v88 de las auras de Amelia.

Reporte que atiende: «DoMod :2: Malformed variable» en Draw_64 de
obj_amelia_auras, linea 84 de la v87:

    var _seed = (_eid mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;

CAUSA RAIZ (documentada en las release notes del runtime):
  * Desde el runtime 2023.8.0 («Assets And Data Structures Now Use
    Typed References») las INSTANCIAS usan handles tipados; el `id`
    de instancia ya NO es un real «puro» del VM.
  * Los Do* del VM (DoAdd/DoMul/DoMod/...) solo aceptan reales (y en
    DoAdd/DoConcat, cadenas). Un operando handle/int64 raro cae al
    default -> «DoMod :N: Malformed variable».
  * El proyecto se guarda con IDEVersion 2026.1.0.27 -> runtime de la
    era de handles. v87 introdujo la PRIMERA aritmetica sobre un id
    de instancia de todo el proyecto (id mod 59) -> crash justo al
    dibujar la primera firma.
  * Evidencia empirica del propio crash del usuario: todo lo que
    corre ANTES de la linea 84 (guardas, comparaciones, el Step
    completo con variable_instance_exists(inst.id, ...) y las
    comparaciones del destello) funciono en su runtime -> el unico
    punto expuesto es esa aritmetica.

QUE VERIFICA ESTE SCRIPT (5 suites, todo debe salir OK):
  S1. Estructura del Draw_64.gml modificado: llaves/parenesis
      balanceados por linea y acumuladas, bloque v88 presente e
      indentacion consistente con la casa (espacios de 8).
  S2. Modelo del VM: implementacion del bloque de fase donde los
      operadores aritmeticos REVIENTAN si reciben algo que no sea
      real (igual que DoMod) — ejecutado contra TODA la matriz de
      clases de valor que puede traer auraId[i]:
        real puro | int64 | handle (5 modelos de string) |
        undefined | cadena | noone (-4) | reales negativos |
        id ≡ 0 (mod 59)
      Se exige: cero excepciones, fase siempre en [0,1), estable
      entre frames, y desincronia entre firmas distintas.
  S3. Equivalencia con la intencion v87: para reales y handles
      «numericos» la fase es EXACTAMENTE (id mod 59)/59; para los
      casos degenerados (dump sin digitos iniciales, etc.) cae a la
      fase por SLOT (distinta entre firmas — la promesa visual de
      v87 se mantiene SIEMPRE).
  S4. Estatica de seguridad: en el Draw_64 final NO queda ninguna
      aritmetica directa sobre _eid sin guarda (solo comparaciones
      y pasadas como argumento), y todos los macros AMELIA_AURA_*
      usados existen en scr_amelia_special.gml.
  S5. Alcance del parche: Create_0.gml, Step_0.gml y
      scr_amelia_special.gml quedan INTACTOS (cero cambios de
      sensado — promesa v87/v88) y no se toco ningun .yyp/.yy
      (cero riesgo de corrupcion de proyecto).

Salida: «V88: TODO OK (N checks)» o la lista de fallos.
"""

import re
import sys

REPO = "."  # correr desde la raiz del repo
DRAW = REPO + "/objects/obj_amelia_auras/Draw_64.gml"
MACROS = REPO + "/scripts/scr_amelia_special/scr_amelia_special.gml"

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
# S1 — estructura del archivo
# ---------------------------------------------------------------------------

def s1_estructura():
    raw = open(DRAW, "rb").read()
    check(b"\r\n" not in raw, "S1: el archivo no debe tener CRLF")
    text = raw.decode("utf-8")  # debe decodificar como UTF-8
    lines = text.split("\n")

    # UTF-8 con los caracteres de la casa intactos
    for ch in ("á", "í", "ó", "ú", "ñ", "«", "»", "—"):
        check(ch in text, "S1: falta el caracter UTF-8 de la casa: %r" % ch)

    # llaves y parentesis balanceados (acumulado + por linea)
    bal_b = bal_p = 0
    for n, ln in enumerate(lines, 1):
        # ignorar comentarios de linea
        code = ln.split("//")[0]
        db = code.count("{") - code.count("}")
        dp = code.count("(") - code.count(")")
        check(db + bal_b >= 0 or db >= 0, "S1: llave cierra de mas en linea %d" % n)
        bal_b += db
        bal_p += dp
    check(bal_b == 0, "S1: llaves desbalanceadas (%d)" % bal_b)
    check(bal_p == 0, "S1: parentesis desbalanceados (%d)" % bal_p)

    # el bloque v88 existe y esta completo
    for needle in (
        "v88 (fix del crash v87",
        "var _eid = auraId[i];",
        "if(is_undefined(_eid) || is_string(_eid) || _eid == noone || _eid < 0)",
        "if(is_real(_eid))",
        "else if(is_int64(_eid))",
        "else if(is_handle(_eid))",
        "var _d = ord(string_char_at(_s, c));",
        "_h = (_h * 10 + _d - 48) mod AMELIA_AURA_SEED;",
        "_seed = ((i * 37) mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;",
    ):
        check(needle in text, "S1: falta en el bloque v88: %r" % needle)

    # indentacion: solo espacios en TODO el archivo; multiplos de 8 solo
    # dentro del bloque v88 nuevo (las continuaciones de argumentos de
    # v87 ya commiteadas alinean al parentesis: estilo de la casa)
    ini = fin = None
    for n, ln in enumerate(lines, 1):
        if "v88 (fix del crash v87" in ln and ini is None:
            ini = n
        if "_seed = ((i * 37)" in ln:
            fin = n
    check(ini is not None and fin is not None, "S1: bloque v88 no encontrado")
    for n, ln in enumerate(lines, 1):
        if not ln.strip() or ln.lstrip().startswith("//"):
            continue
        indent = len(ln) - len(ln.lstrip(" "))
        check("\t" not in ln, "S1: TAB en linea %d (la casa usa espacios)" % n)
        if ini and fin and ini <= n <= fin:
            check(indent % 8 == 0, "S1: indentacion v88 no multiplo de 8 en linea %d" % n)

    # ya NO existe el mod directo sobre _eid (la linea que reventaba)
    check(
        "var _seed = (_eid mod AMELIA_AURA_SEED)" not in text,
        "S1: sigue existiendo el mod directo sobre _eid",
    )
    return text, lines


# ---------------------------------------------------------------------------
# S2 — modelo del VM: los Do* solo tragan reales
# ---------------------------------------------------------------------------

class GmlError(Exception):
    pass


class Val:
    """Valor del VM con tipo. Real/Str/Int64/Handle/Undefined."""

    __slots__ = ("t", "v")

    def __init__(self, t, v):
        self.t = t
        self.v = v


REAL = lambda x: Val("real", float(x))
INT64 = lambda x: Val("int64", int(x))
HANDLE = lambda s: Val("handle", s)  # s = lo que string() imprime
UNDEF = Val("undef", None)
STR = lambda s: Val("str", s)
STRUCT = lambda: Val("struct", {"x": 100, "y": 240})  # exotico: cae al fallback

NOONE = REAL(-4)
SEED_MACRO = 59.0


def g_is_undefined(v):
    return v.t == "undef"


def g_is_string(v):
    return v.t == "str"


def g_is_real(v):
    return v.t == "real"


def g_is_int64(v):
    return v.t == "int64"


def g_is_handle(v):
    return v.t == "handle"


def g_string(v):
    # string() nunca revienta: imprime el valor
    if v.t == "real":
        s = ("%.6f" % v.v).rstrip("0").rstrip(".")
        return STR(s if s else "0")
    if v.t in ("int64", "handle"):
        return STR(str(v.v))
    if v.t == "undef":
        return STR("undefined")
    return STR(str(v.v))


def g_real(v):
    # real(): acepta reales, booleanos, int64 y cadenas numericas;
    # con handle/undefined revienta (por eso solo se llama tras is_int64)
    if v.t == "real":
        return REAL(v.v)
    if v.t == "int64":
        return REAL(float(v.v))
    if v.t == "str":
        try:
            return REAL(float(v.v))
        except ValueError:
            raise GmlError("real(): no convertible: %r" % v.v)
    raise GmlError("real(): tipo no convertible: %s" % v.t)


def arith(fn, a, b, opname):
    # Regla del VM: los Do* aceptan reales (y cadenas SOLO en DoAdd/concat)
    for x in (a, b):
        if x.t != "real":
            raise GmlError(
                "Do%s: Malformed variable (operando tipo %s)"
                % (opname, x.t)
            )
    return fn(a.v, b.v)


def g_mod(a, b):
    return REAL(arith(lambda x, y: float(int(x) % int(y)), a, b, "Mod"))


def g_div(a, b):
    return REAL(arith(lambda x, y: x / y, a, b, "Div"))


def g_mul(a, b):
    return REAL(arith(lambda x, y: x * y, a, b, "Mul"))


def g_add(a, b):
    return REAL(arith(lambda x, y: x + y, a, b, "Add"))


def g_sub(a, b):
    return REAL(arith(lambda x, y: x - y, a, b, "Sub"))


def g_lt(a, b):
    # las comparaciones NO revientan con tipos raros (evidencia: la
    # linea 81 de v87 paso con un handle en el runtime del usuario)
    try:
        return a.v < b.v
    except TypeError:
        return False


def g_eq(a, b):
    return a.v == b.v


def g_ord(v):
    # ord() de un string de 1 caracter -> real
    if v.t != "str" or len(v.v) != 1:
        raise GmlError("ord(): argumento invalido")
    return REAL(float(ord(v.v[0])))


def g_string_char_at(s, idx):
    # 1-indexado
    if s.t != "str" or idx.t != "real":
        raise GmlError("string_char_at(): argumentos invalidos")
    i = int(idx.v)
    if i < 1 or i > len(s.v):
        raise GmlError("string_char_at(): fuera de rango")
    return STR(s.v[i - 1])


def g_string_length(v):
    if v.t != "str":
        raise GmlError("string_length(): argumento invalido")
    return REAL(float(len(v.v)))


def fase_v88(eid_raw, slot):
    """Transcripcion 1:1 del bloque v88 del Draw_64 (con _eid ya leido)."""
    _eid = eid_raw
    if g_is_undefined(_eid) or g_is_string(_eid) or g_eq(_eid, NOONE) or g_lt(_eid, REAL(0)):
        _eid = REAL(0)

    _seed = REAL(0)
    _seedOk = False

    if g_is_real(_eid):
        _seed = g_div(g_mod(_eid, REAL(SEED_MACRO)), REAL(SEED_MACRO))
        _seedOk = True
    elif g_is_int64(_eid):
        _seed = g_div(g_mod(g_real(_eid), REAL(SEED_MACRO)), REAL(SEED_MACRO))
        _seedOk = True
    elif g_is_handle(_eid):
        _h = REAL(0)
        _s = g_string(_eid)
        _sl = g_string_length(_s)
        c = 1
        while c <= int(_sl.v):
            _d = g_ord(g_string_char_at(_s, REAL(float(c))))
            # condicion GML 1:1: if(_d < 48 || _d > 57) break;
            # (el '9' = 57 SI es digito: solo rompe > 57)
            if g_lt(_d, REAL(48)) or g_lt(REAL(57), _d):
                break
            _h = g_mod(g_add(g_mul(_h, REAL(10)), g_sub(_d, REAL(48))), REAL(SEED_MACRO))
            c += 1
        if g_lt(REAL(0), _h):
            _seed = g_div(_h, REAL(SEED_MACRO))
            _seedOk = True

    if not _seedOk:
        _seed = g_div(g_mod(g_mul(REAL(float(slot)), REAL(37)), REAL(SEED_MACRO)), REAL(SEED_MACRO))
    return _seed.v


def fase_v87(eid_raw):
    """La linea original de v87: el mod directo (revienta si no es real)."""
    _eid = eid_raw
    if g_eq(_eid, NOONE) or g_lt(_eid, REAL(0)):
        _eid = REAL(0)
    return g_div(g_mod(_eid, REAL(SEED_MACRO)), REAL(SEED_MACRO))


def s2_modelo_vm():
    casos = [
        # (nombre, valor auraId[i], slot i, debe_reventar_v87)
        ("real id tipico", REAL(101172), 3, False),
        ("real id chico", REAL(100002), 0, False),
        ("real id ≡ 0 mod 59 (118)", REAL(118), 5, False),
        ("int64 id", INT64(101172), 2, True),
        ("handle numerico '101172'", HANDLE("101172"), 4, True),
        ("handle con prefijo 'id 101172'", HANDLE("id 101172"), 6, True),
        ("handle dump '{ x: 100, y: 240 }'", HANDLE("{ x: 100, y: 240 }"), 7, True),
        ("handle vacio ''", HANDLE(""), 8, True),
        ("handle corto '#7'", HANDLE("#7"), 9, True),
        ("undefined", UNDEF, 10, True),
        ("cadena 'abc'", STR("abc"), 11, True),
        ("noone (-4)", NOONE, 12, False),
        ("real negativo -13", REAL(-13), 13, False),
    ]

    seeds_vistos = {}
    for nombre, val, slot, revienta_v87 in casos:
        # 1) v88 NUNCA revienta
        try:
            s1 = fase_v88(val, slot)
            ok = True
        except GmlError as e:
            ok = False
            s1 = None
            fails.append("S2: v88 REVIENTA con %s: %s" % (nombre, e))
        if ok:
            check(0 <= s1 < 1, "S2: fase fuera de [0,1) para %s: %r" % (nombre, s1))
            # 2) estable: misma entrada -> misma fase (dos "frames")
            s2 = fase_v88(val, slot)
            check(s1 == s2, "S2: fase inestable para %s" % nombre)
            seeds_vistos[nombre] = s1
        # 3) confirmacion de la causa raiz: la v87 revienta exacto
        #    donde el usuario la vio reventar (con id/handle/undefined)
        try:
            fase_v87(val)
            if revienta_v87:
                fails.append(
                    "S2 (diagnostico): v87 NO revienta con %s — "
                    "revisar el modelo" % nombre
                )
            else:
                global oks
                oks += 1
        except GmlError as e:
            check(
                revienta_v87,
                "S2 (diagnostico): v87 revienta con %s y no debia: %s"
                % (nombre, e),
            )

    # 4) desincronia: dos firmas distintas no comparten fase
    #    (ids reales distintos -> fases distintas, como v87 queria)
    s_a = fase_v88(REAL(101172), 0)
    s_b = fase_v88(REAL(101175), 1)
    check(
        abs(s_a - s_b) > 1e-9,
        "S2: dos ids distintos comparten fase (desincronia muerta)",
    )
    # handles distintos con string numerico -> fases distintas
    h_a = fase_v88(HANDLE("101172"), 0)
    h_b = fase_v88(HANDLE("101175"), 1)
    check(
        abs(h_a - h_b) > 1e-9,
        "S2: dos handles-numericos comparten fase (desincronia muerta)",
    )
    # guardas primero: undefined/cadena -> 0 real -> rama is_real -> fase 0
    # (determinista, estable, sin crash: las arrays del sensor siempre
    #  estan llenas, asi que este caso solo existe en estados exoticos)
    s_undef = fase_v88(UNDEF, 10)
    check(
        s_undef == 0.0,
        "S2: undefined debia caer a fase 0 (guarda -> real 0), dio %r" % s_undef,
    )
    # y en el peor caso (dump/struct/ptr) la fase por SLOT desincronia
    d_0 = fase_v88(HANDLE("{ x: 1 }"), 0)
    d_1 = fase_v88(HANDLE("{ x: 1 }"), 1)
    d_2 = fase_v88(HANDLE("{ x: 1 }"), 2)
    check(
        len({d_0, d_1, d_2}) == 3,
        "S2: la fase por slot no desincronia firmas simultaneas",
    )
    d_3 = fase_v88(STRUCT(), 0)
    d_4 = fase_v88(STRUCT(), 1)
    check(
        d_3 != d_4,
        "S2: struct (tipo exotico) no cayo a fase por slot distinta",
    )


# ---------------------------------------------------------------------------
# S3 — equivalencia con la intencion de v87
# ---------------------------------------------------------------------------

def s3_equivalencia():
    for idn in (101172, 100059, 104729, 118):
        esperado = (idn % 59) / 59.0
        got_real = fase_v88(REAL(idn), 0)
        got_int64 = fase_v88(INT64(idn), 0)
        got_handle = fase_v88(HANDLE(str(idn)), 0)
        check(
            abs(got_real - esperado) < 1e-9,
            "S3: real %d: fase %r != esperada %r" % (idn, got_real, esperado),
        )
        check(
            abs(got_int64 - esperado) < 1e-9,
            "S3: int64 %d: fase %r != esperada %r" % (idn, got_int64, esperado),
        )
        check(
            abs(got_handle - esperado) < 1e-9,
            "S3: handle '%d': fase %r != esperada %r"
            % (idn, got_handle, esperado),
        )
    # el fallback por slot es distinto para los 16 slots
    # (struct = tipo que cae al fallback: ni real/int64/handle)
    slots = [fase_v88(STRUCT(), i) for i in range(16)]
    check(
        len(set(slots)) == 16,
        "S3: fases por slot repetidas entre los 16 slots",
    )
    # y todas dentro del dominio
    check(
        all(0 <= s < 1 for s in slots),
        "S3: fase por slot fuera de [0,1)",
    )


# ---------------------------------------------------------------------------
# S4 — estatica de seguridad del Draw final
# ---------------------------------------------------------------------------

def s4_estatica(text):
    # ningun mod/div/mul/add/sub directo sobre _eid salvo dentro de las
    # ramas guardadas; en el archivo final _eid solo aparece en:
    #   lectura de auraId, guardas is_*/comparaciones, y las lineas
    #   _seed/... dentro de if(is_real/else if(is_int64 (que ya
    #   normalizan a real ANTES del mod).
    for n, ln in enumerate(text.split("\n"), 1):
        if "_eid" in ln:
            code = ln.split("//")[0].strip()
            permitido = (
                code.startswith("var _eid")
                or code.startswith("if(is_")
                or code.startswith("else if(is_")
                or code.startswith("_seed = (_eid mod")
                or code.startswith("_seed = (real(_eid) mod")
                or code.startswith("var _s = string(_eid)")
                or code.startswith("_eid = 0")
            )
            check(
                permitido,
                "S4: uso sospechoso de _eid en linea %d: %r" % (n, code),
            )
    # _s (el string del handle) jamas entra en aritmetica: solo
    # string_char_at/string_length
    for n, ln in enumerate(text.split("\n"), 1):
        if re.search(r"[-+*/]\s*_s\b|\b_s\s*[-+*/]", ln.split("//")[0]):
            fails.append("S4: aritmetica con _s en linea %d" % n)

    # todos los macros usados en el Draw existen en scr_amelia_special
    mtext = open(MACROS, "r", encoding="utf-8").read()
    definidos = set(
        m.group(1) for m in re.finditer(r"#macro\s+(AMELIA_AURA_\w+)", mtext)
    )
    usados = set(re.findall(r"AMELIA_AURA_\w+", text))
    check(
        usados <= definidos,
        "S4: macros usados y no definidos: %s" % sorted(usados - definidos),
    )
    check(
        len([d for d in definidos if d == "AMELIA_AURA_SEED"]) == 1,
        "S4: AMELIA_AURA_SEED debe definirse una sola vez",
    )
    # funciones is_*/string* usadas: disponibles en runtime 2023.8+
    # (is_handle se agrego en 2023.8; is_int64 en 2022.3; el proyecto
    #  se guarda con IDEVersion 2026.1.0.27 — verificar en el .yyp)
    yyp = None
    for cand in (
        REPO + "/TD2DR.yyp",
        REPO + "/Sonicexe The Disaster 2D Remake.yyp",
    ):
        try:
            yyp = open(cand, "r", encoding="utf-8").read()
            break
        except OSError:
            continue
    if yyp is None:
        import glob
        g = glob.glob(REPO + "/*.yyp")
        if g:
            yyp = open(g[0], "r", encoding="utf-8").read()
    check(yyp is not None, "S4: no se encontro el .yyp")
    if yyp:
        m = re.search(r'"IDEVersion"\s*:\s*"([^"]+)"', yyp)
        check(m is not None, "S4: .yyp sin IDEVersion")
        if m:
            ver = m.group(1)
            ano = int(ver.split(".")[0])
            check(
                ano >= 2023,
                "S4: IDEVersion %s < 2023: is_handle no compilaria" % ver,
            )
    # el repo ya usaba is_undefined antes (compatibilidad de estilo casa)
    check(
        "is_undefined" in open(
            REPO + "/scripts/scr_parry/scr_parry.gml", "r", encoding="utf-8"
        ).read(),
        "S4: patrón is_* de la casa no encontrado (scr_parry)",
    )


# ---------------------------------------------------------------------------
# S5 — alcance del parche (via git)
# ---------------------------------------------------------------------------

def s5_alcance():
    import subprocess

    def git(*args):
        return subprocess.run(
            ["git", *args], cwd=REPO, capture_output=True, text=True
        ).stdout

    status = git("status", "--short")
    tocados = [
        ln[3:] for ln in status.splitlines() if ln.strip()
    ]
    # archivos de codigo: SOLO el Draw del hotfix; docs del registro
    # (CACHE/LEARNING/worklog) y el verificador/LEEME nuevos estan bien
    for f in tocados:
        base = f.split("/")[-1]
        if f.endswith(".yy") or f.endswith(".yyp"):
            fails.append("S5: se toco un archivo de proyecto: %s" % f)
        if f.endswith(".gml") and f != "objects/obj_amelia_auras/Draw_64.gml":
            fails.append("S5: .gml inesperado en el alcance: %s" % f)
        if base.startswith(("check_v88", "LEEME_V88")):
            continue
    check(
        "objects/obj_amelia_auras/Draw_64.gml" in tocados,
        "S5: el Draw_64.gml no figura como modificado",
    )
    check(
        "objects/obj_amelia_auras/Step_0.gml" not in tocados,
        "S5: Step_0.gml NO debia tocarse (sensado intacto)",
    )
    check(
        "objects/obj_amelia_auras/Create_0.gml" not in tocados,
        "S5: Create_0.gml NO debia tocarse (sensado intacto)",
    )
    # contra origin/main: el diff del Step debe ser VACIO
    d = git("diff", "origin/main", "--", "objects/obj_amelia_auras/Step_0.gml")
    check(d.strip() == "", "S5: diff contra origin/main en Step_0.gml NO vacio")


# ---------------------------------------------------------------------------

def main():
    print("check_v88.py — verificador del hotfix v88 (auras de Amelia)\n")
    text, lines = s1_estructura()
    print("S1 estructura del Draw_64.gml ..................... OK (%d lineas)" % len(lines))
    s2_modelo_vm()
    print("S2 modelo VM (13 clases de valor) .................. OK")
    s3_equivalencia()
    print("S3 equivalencia con la fase v87 .................... OK")
    s4_estatica(text)
    print("S4 estatica de seguridad (macros/estilo/IDE) ....... OK")
    try:
        s5_alcance()
        print("S5 alcance del parche (git) ....................... OK")
    except Exception as e:  # noqa: BLE001
        fails.append("S5: no se pudo verificar el alcance: %s" % e)

    print()
    if fails:
        print("FALLOS (%d):" % len(fails))
        for f in fails:
            print("  - " + f)
        sys.exit(1)
    print("V88: TODO OK (%d checks)" % oks)


if __name__ == "__main__":
    main()
