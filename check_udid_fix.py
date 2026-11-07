#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_udid_fix.py — Verificador del FIX UDID V1 (TD2DR).

Parte A: verifica que los cambios del fix estan presentes en los 3 archivos.
Parte B: simula en Python el algoritmo NUEVO de packet_readstr /
         packet_from / string_new con los casos del bug (byte-level).
Parte C (opcional, si hay gcc/cc): extrae las funciones LITERALES de
         Packet.c, las compila y corre el harness C con los mismos casos.

Uso:  python check_udid_fix.py [ruta_del_repo]
      (por defecto asume que esta al lado de betterserver-oss/)
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

RESULTS = []


def check(name, ok):
    RESULTS.append((name, bool(ok)))
    print(("  [PASS] " if ok else "  [FAIL] ") + name)


# ----------------------------------------------------------------------
# Parte A — patrones del fix en los archivos
# ----------------------------------------------------------------------
def parte_a(root):
    print("== A: cambios presentes en el codigo ==")
    pc = os.path.join(root, "betterserver-oss", "disasterserver", "Packet.c")
    sc = os.path.join(root, "betterserver-oss", "disasterserver", "states", "Server.c")
    gml = os.path.join(root, "scripts", "net_indentity", "net_indentity.gml")

    for path in (pc, sc, gml):
        if not os.path.isfile(path):
            check("existe %s" % os.path.relpath(path, root), False)
            return

    src_pc = open(pc, encoding="utf-8").read()
    src_sc = open(sc, encoding="utf-8").read()
    src_gml = open(gml, encoding="utf-8").read()

    check("A1 Packet.c: RAssert(out->len < 128) ELIMINADO del codigo (solo queda mencionado en comentarios)",
          re.search(r"^\s*RAssert\s*\(\s*out->len\s*<\s*128\s*\)", src_pc, re.M) is None)
    check("A2 Packet.c: packet_readstr guarda con tope sizeof(out->value)",
          re.search(r"if\s*\(\s*out->len\s*<\s*sizeof\(out->value\)\s*\)", src_pc) is not None)
    check("A3 Packet.c: packet_readstr fuerza '\\0' si se recorto",
          re.search(r"out->value\[out->len\]\s*=\s*'\\0'", src_pc) is not None)
    check("A4 Packet.c: packet_readstr avisa con Warn al recortar",
          "packet_readstr: string recortada" in src_pc)
    check("A5 Packet.c: packet_from recorta a PACKET_MAXSIZE-1 en vez de wrap uint8_t",
          "paquete de %zu bytes recortado" in src_pc and
          re.search(r"data_len\s*=\s*PACKET_MAXSIZE\s*-\s*1", src_pc) is not None)
    check("A6 Packet.c: packet_from ya NO castea dataLength directo a uint8_t",
          re.search(r"\.len\s*=\s*\(uint8_t\)packet->dataLength", src_pc) is None)
    check("A7 Packet.c: string_new acota a sizeof(str.value) y fuerza '\\0'",
          re.search(r"len\s*>\s*sizeof\(str\.value\)", src_pc) is not None and
          "str.value[len - 1] = '\\0'" in src_pc)
    check("A8 Server.c: redirect marca v->disconnecting = true",
          re.search(r"v->disconnecting\s*=\s*true", src_sc) is not None)
    check("A9 Server.c: identity fallido desconecta con aviso (no solo Debug)",
          "desconectando con aviso" in src_sc and
          re.search(r"if\s*\(\s*!\s*v->disconnecting\s*\)", src_sc) is not None)
    check("A10 cliente: udid con tope string_copy(..., 1, 100)",
              src_gml.count("string_copy(") >= 2 and ", 1, 100)" in src_gml)

    # el ticket y el layout del identity NO cambiaron (compatibilidad)
    check("A11 Server.c: el orden de lectura del identity intacto (udid en 181)",
          "PacketRead(udid, packet, packet_readstr, String);" in src_sc)


# ----------------------------------------------------------------------
# Parte B — simulacion en Python del algoritmo nuevo (mismos casos que C)
# ----------------------------------------------------------------------
VALUE = 250       # sizeof(String.value)
PKT_MAX = 256     # PACKET_MAXSIZE


def readstr_new(buff, pos, ln):
    """packet_readstr FIXEADO. Devuelve (ok, value_bytes, nueva_pos, warn)."""
    out = bytearray()
    warn = False
    while True:
        if not (pos < ln):
            return False, bytes(out), pos, warn      # RAssert(pos < len)
        ch = buff[pos]
        pos += 1
        if len(out) < VALUE:
            out.append(ch)
        if ch == 0:
            break
    if len(out) > 0 and out[-1] != 0:
        if len(out) >= VALUE:
            out = out[:VALUE - 1]
        out.append(0)
        warn = True
    return True, bytes(out), pos, warn


def packet_from_new(data):
    data_len = len(data)
    if data_len > PKT_MAX - 1:
        data_len = PKT_MAX - 1
    return data[:data_len], data_len


def string_new_new(text):
    b = text.encode("utf-8")
    if len(b) + 1 > VALUE:
        b = b[:VALUE - 1] + b"\x00"
        return b
    return b + b"\x00"


def readstr_OLD(buff, pos, ln):
    """packet_readstr ORIGINAL (para contrastar): falla si len >= 128."""
    out = bytearray()
    while True:
        if not (pos < ln):
            return False, bytes(out), pos
        if len(out) >= 128:          # RAssert(out->len < 128)
            return False, bytes(out), pos
        ch = buff[pos]
        pos += 1
        out.append(ch)
        if ch == 0:
            return True, bytes(out), pos


def parte_b():
    print("== B: simulacion byte-level del algoritmo nuevo ==")
    # T1: udid Android de 144 chars (el caso del bug) dentro de un identity
    udid = b"mod-" + b"A" * 140 + b"\x00"
    stream = b"Sonic\x00" + udid + bytes([7, 3])
    pos = 6
    ok, v, pos, warn = readstr_new(stream, pos, len(stream))
    check("B1 udid de 144 chars: lee OK y COMPLETO (el viejo reventaba)",
          ok and v == udid and not warn)
    ok_old, _, _ = readstr_OLD(stream, 6, len(stream))
    check("B2 contraste: el algoritmo VIEJO si fallaba con el mismo stream",
          not ok_old)
    check("B3 campos siguientes en sync (icon=7, pet=3)",
          stream[pos] == 7 and stream[pos + 1] == 3 and pos + 2 == len(stream))

    # T2: string de 251 chars => recorte a 249 + '\0' + sync
    big = b"B" * 251 + b"\x00" + bytes([7, 3])
    ok, v, pos, warn = readstr_new(big, 0, len(big))
    check("B4 string de 251 chars: no falla, recorta a 249 con '\\0'",
          ok and warn and len(v) == 250 and v[249] == 0 and v[:249] == b"B" * 249)
    check("B5 pos sincronizado tras el recorte (icon/pet legibles)",
          big[pos] == 7 and big[pos + 1] == 3)

    # T3: casos normales intactos
    ok, v, pos, warn = readstr_new(b"hola\x00\x07", 0, 6)
    check("B6 string corto 'hola' identico (5 bytes, sin warn)",
          ok and v == b"hola\x00" and pos == 5 and not warn)
    ok, v, pos, warn = readstr_new(b"\x00", 0, 1)
    check("B7 string vacio (len=1) intacto", ok and v == b"\x00" and not warn)
    for n in (249, 250):
        s = b"C" * n + b"\x00"
        ok, v, pos, warn = readstr_new(s, 0, len(s))
        visibles = n if n <= 249 else 249
        check("B%d string de %d chars: %d visibles + '\\0' en rango"
              % (8 + (n - 249), n, visibles),
              ok and len(v.rstrip(b"\x00")) == visibles and v.rstrip(b"\x00") == b"C" * visibles)

    # T4: packet_from
    d, ln = packet_from_new(b"D" * 300)
    check("B10 paquete ENet de 300 bytes: len=255 (antes 300%256=44)",
          ln == 255 and len(d) == 255)
    d, ln = packet_from_new(b"D" * 256)
    check("B11 paquete de 256 bytes: len=255 (antes 0!)", ln == 255)
    d, ln = packet_from_new(b"D" * 172)
    check("B12 paquete normal de 172 bytes intacto", ln == 172)

    # T5: string_new
    v = string_new_new("M" * 400)
    check("B13 string_new con 400 chars: 249 visibles + '\\0' (antes overflow)",
          len(v) == 250 and v[249] == 0)
    v = string_new_new("hola mundo")
    check("B14 string_new texto normal intacto", v == b"hola mundo\x00")

    # T6: UTF-8
    ok, v, pos, warn = readstr_new("Sónic\x00".encode("utf-8"), 0, 7)
    check("B15 UTF-8 byte-a-byte intacto", ok and v == "Sónic\x00".encode("utf-8"))


# ----------------------------------------------------------------------
# Parte C — harness C con las funciones LITERALES de Packet.c (si hay gcc)
# ----------------------------------------------------------------------
HARNESS = r"""
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#define PACKET_MAXSIZE 256
typedef struct { uint8_t buff[PACKET_MAXSIZE]; uint8_t pos; uint8_t len; } Packet;
typedef struct { char value[250]; uint16_t len; } String;
static int warns = 0;
#define Warn(fmt, ...) do { warns++; } while (0)
#define Err(fmt, ...) do { } while (0)
#define RAssert(x) if (!(x)) { return false; }
typedef struct { uint8_t* data; size_t dataLength; } ENetPacket;
static void enet_packet_destroy(ENetPacket* p) { (void)p; }
/* === CODIGO EXTRAIDO === */
@FNEW@
@FFROM@
@FREAD@
/* === FIN === */
@FNUMS@
static int fails = 0;
#define CHECK(c, n) do { if (c) printf("[PASS] %s\n", n); else { printf("[FAIL] %s\n", n); fails++; } } while (0)
static bool read8(Packet* p, uint8_t* o){ return packet_read8(p,o); }
int main(void)
{
    { char u[141]; memset(u,'A',140); u[140]=0;
      Packet p; memset(&p,0,sizeof(p));
      memcpy(p.buff,"\0\0\0\0\0\0\0\0",8); p.len=8;
      memcpy(p.buff+p.len,"Sonic\0",6); p.len+=6;
      memcpy(p.buff+p.len,u,141); p.len+=141;
      p.buff[p.len++]=7; p.buff[p.len++]=3;
      uint64_t tk1=0x1111, tk2=0x2222;
      memcpy(p.buff+p.len,&tk1,8); p.len+=8;
      memcpy(p.buff+p.len,&tk2,8); p.len+=8;
      String nick={0},udid={0}; uint8_t pas,type,icon; int8_t pet; uint16_t b; int32_t si; uint64_t t1,t2;
      bool ok = read8(&p,&pas)&&read8(&p,&type)&&packet_read16(&p,&b)&&packet_read32(&p,(uint32_t*)&si)
                &&packet_readstr(&p,&nick)&&packet_readstr(&p,&udid)&&read8(&p,&icon)&&read8(&p,(uint8_t*)&pet)
                &&packet_read64(&p,&t1)&&packet_read64(&p,&t2);
      CHECK(ok, "C1 identity con udid 140 chars parsea completo");
      CHECK(udid.len==141 && strcmp(udid.value,u)==0, "C2 udid completo (antes RASSERT)");
      CHECK(icon==7 && pet==3 && p.pos==p.len && t1==0x1111 && t2==0x2222, "C3 icon/pet/ticket/final en sync"); }
    { char big[260]; memset(big,'B',251); big[251]=0;
      Packet p; memset(&p,0,sizeof(p));
      memcpy(p.buff,big,252); p.len=252; p.buff[p.len++]=7; p.buff[p.len++]=3;
      String s={0};
      bool ok = packet_readstr(&p,&s);
      uint8_t icon,pet;
      CHECK(ok && s.len==249 && s.value[249]==0, "C4 string 251 recortada a 249 + NULL");
      CHECK(packet_read8(&p,&icon)&&packet_read8(&p,(uint8_t*)&pet)&&icon==7&&pet==3, "C5 sync tras recorte");
      CHECK(warns>0, "C6 Warn emitido"); }
    { uint8_t d[300]; memset(d,'D',sizeof(d));
      ENetPacket e={d,300}; Packet p=packet_from(&e);
      CHECK(p.len==255, "C7 packet_from 300B -> 255");
      ENetPacket e2={d,256}; Packet q=packet_from(&e2);
      CHECK(q.len==255, "C8 packet_from 256B -> 255 (antes 0)");
      ENetPacket e3={d,172}; Packet r=packet_from(&e3);
      CHECK(r.len==172, "C9 packet_from 172B intacto"); }
    { char m[401]; memset(m,'M',400); m[400]=0;
      String s=string_new(m);
      CHECK(s.len==250 && s.value[249]==0, "C10 string_new 400 chars acotada");
      String n=string_new("hola mundo");
      CHECK(n.len==11 && strcmp(n.value,"hola mundo")==0, "C11 string_new normal"); }
    printf("%s: %d fallos\n", fails?"HAY FALLOS":"HARNESS C OK", fails);
    return fails?1:0;
}
"""


def extract(src, pattern):
    m = re.search(pattern, src, re.S)
    return m.group(0) if m else ""


def parte_c(root):
    print("== C: harness C con codigo LITERAL de Packet.c ==")
    cc = shutil.which("gcc") or shutil.which("cc") or shutil.which("clang")
    if not cc:
        print("  [SKIP] sin gcc/cc/clang: se omite (A y B ya validaron)")
        return
    pc = os.path.join(root, "betterserver-oss", "disasterserver", "Packet.c")
    src = open(pc, encoding="utf-8").read()
    fns = [
        extract(src, r"String string_new\(.*?\n\}"),
        extract(src, r"Packet packet_from\(.*?\n\}"),
        extract(src, r"bool packet_readstr\(.*?\n\}"),
        extract(src, r"bool packet_read8\(.*?\n\}"),
        extract(src, r"bool packet_read16\(.*?\n\}"),
        extract(src, r"bool packet_read32\(.*?\n\}"),
        extract(src, r"bool packet_read64\(.*?\n\}"),
    ]
    if not all(fns):
        check("C0 extraccion de funciones de Packet.c", False)
        return
    code = (HARNESS
            .replace("@FNEW@", fns[0])
            .replace("@FFROM@", fns[1])
            .replace("@FREAD@", fns[2])
            .replace("@FNUMS@", "\n".join(fns[3:])))
    with tempfile.TemporaryDirectory() as td:
        cf = os.path.join(td, "t.c")
        ex = os.path.join(td, "t")
        open(cf, "w").write(code)
        r = subprocess.run([cc, "-O2", "-w", cf, "-o", ex],
                           capture_output=True, text=True)
        if r.returncode != 0:
            check("C0 compilacion del harness", False)
            print(r.stderr[:600])
            return
        r = subprocess.run([ex], capture_output=True, text=True)
        for line in r.stdout.strip().splitlines():
            if line.startswith("[PASS] ") or line.startswith("[FAIL] "):
                check(line[7:].strip(), line.startswith("[PASS] "))
        if "HARNESS C OK" in r.stdout:
            check("C-harness completo (todas las C del binario)", True)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    if not os.path.isdir(os.path.join(root, "betterserver-oss")):
        root = os.path.join(root, "..")
    print("Verificador FIX UDID V1 — repo: %s\n" % os.path.abspath(root))
    parte_a(root)
    print()
    parte_b()
    print()
    try:
        parte_c(root)
    except Exception as e:
        print("  [SKIP] parte C: %s" % e)
    total = len(RESULTS)
    ok = sum(1 for _, o in RESULTS if o)
    print("\nRESULTADO: %d/%d OK %s" % (ok, total, "— TODO BIEN" if ok == total else "— HAY FALLOS"))
    sys.exit(0 if ok == total else 1)


if __name__ == "__main__":
    main()
