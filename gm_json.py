#!/usr/bin/env python3
"""gm_json.py — JSON tolerante para proyectos GameMaker.

json_repair(text) repara, SIN tocar cadenas ni numeros:
  1. coma colgante antes de } o ]        (el error del usuario)
  2. comillas tipograficas “ ” ‘ ’ -> " "
  3. BOM / CRLF / tabs
  4. NaN / Infinity / -Infinity -> null
  5. comentarios // y /* */ (GameMaker no los escribe, pero los edits a mano si)

Devuelve (objeto_o_None, lista_de_reparos). Si tras reparar sigue sin parsear,
(None, [error]) para que el llamador lo reporte sin tocar el archivo.
"""
import json
import re


def _strip_comments(text):
    # fuera de cadenas: usamos un escaneo simple con estado
    out = []
    i, n = 0, len(text)
    in_str = False
    esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _fix_quotes(text):
    return (text.replace("\u201c", '"').replace("\u201d", '"')
                .replace("\u2018", "'").replace("\u2019", "'"))


def _fix_constants(text):
    text = re.sub(r"\bNaN\b", "null", text)
    text = re.sub(r"\bInfinity\b", "null", text)
    text = re.sub(r"\b-Infinity\b", "null", text)
    return text


def _fix_trailing_commas(text):
    """Quita comas colgantes que estan FUERA de cadenas."""
    out = []
    i, n = 0, len(text)
    in_str = False
    esc = False
    fixed = 0
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == ",":
            # mirar el siguiente caracter no-espacio (y no comentario)
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                fixed += 1
                i += 1  # saltar la coma
                continue
        out.append(c)
        i += 1
    return "".join(out), fixed


def json_repair(text):
    """Devuelve (obj, reparos). obj es None si no se pudo parsear."""
    repairs = []
    raw = text
    if raw.startswith("\ufeff"):
        raw = raw.lstrip("\ufeff")
        repairs.append("BOM UTF-8 eliminado")
    if "\r\n" in raw:
        raw = raw.replace("\r\n", "\n")
        repairs.append("CRLF -> LF")

    # 1a pasada: reparaciones seguras
    no_comments = _strip_comments(raw)
    if no_comments != raw:
        repairs.append("comentarios // /* */ eliminados")
        raw = no_comments
    fixed_q = _fix_quotes(raw)
    if fixed_q != raw:
        repairs.append("comillas tipograficas corregidas")
        raw = fixed_q
    fixed_c = _fix_constants(raw)
    if fixed_c != raw:
        repairs.append("NaN/Infinity -> null")
        raw = fixed_c

    # intentar parsear; si falla por coma, reparar y reintentar
    for attempt in range(2):
        try:
            return json.loads(raw), repairs
        except json.JSONDecodeError:
            stripped, count = _fix_trailing_commas(raw)
            if count == 0:
                break
            repairs.append(f"{count} coma(s) colgante(s) eliminada(s)")
            raw = stripped
    try:
        return json.loads(raw), repairs
    except json.JSONDecodeError as e:
        return None, [f"JSON invalido: {e}"]


def load_repair(path):
    """Lee un archivo y devuelve (obj, reparos). No escribe nada."""
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        return json_repair(f.read())


if __name__ == "__main__":
    import sys
    obj, reps = load_repair(sys.argv[1])
    if obj is None:
        print("NO PARSEA:", reps[0])
        sys.exit(1)
    print("PARSE OK")
    for r in reps:
        print("  reparo:", r)
