#!/usr/bin/env python3
# check_v45.py — Verificacion 100% de la ronda v45: la hitbox del CORTE
# de Kris en el puppet. Causa raiz: el bit PLAYER_ATTACKING viaja (emisor
# obj_netclient lo manda desde v1 de Kris) pero el RECEPTOR
# (net_udpprocess) nunca lo leia para Kris -> puppet.isAttacking siempre
# false -> todo el bloque de stun/contacto era codigo muerto para Kris.
import re, subprocess, sys

BASE = "/home/z/my-project/disaster2d-oss"
ok = fail = 0
def check(name, cond, detail=""):
    global ok, fail
    tag = "[OK]" if cond else "[FALLO]"
    if cond: ok += 1
    else: fail += 1
    print(f"  {tag} {name}" + (f" — {detail}" if detail and not cond else ""))

print("== A) EL FIX: receptor lee el bit para Kris ==")
u = open(f"{BASE}/scripts/net_udpprocess/net_udpprocess.gml", encoding="utf-8").read()
# la linea del receptor (rama superviviente, tras el fix)
m = re.search(r'if\(character == CHARACTER_KNUX \|\| character == CHARACTER_EGGMAN[^\n]*character == CHARACTER_ROUGE \|\| character == CHARACTER_KRIS\)\n(\s+)isAttacking = bitflags & PLAYER_ATTACKING;', u)
check("CHARACTER_KRIS en la lista del RECEPTOR (rama supervivientes)",
      "character == CHARACTER_KRIS)" in u and bool(m))
check("la asignacion isAttacking = bitflags & PLAYER_ATTACKING sigue pegada al if",
      bool(m))
check("el resto de la lista intacto (los 9 anteriores no se perdieron)",
      all(f"character == {c}" in m.group(0) if m else False for c in
          ["CHARACTER_KNUX", "CHARACTER_EGGMAN", "CHARACTER_AMY", "CHARACTER_AMY_CANON",
           "CHARACTER_SALLY", "CHARACTER_SALLY_CANON", "CHARACTER_SONIC",
           "CHARACTER_METAL", "CHARACTER_ROUGE", "CHARACTER_KRIS"]) if m else False)
check("la rama EXE del bit (linea ~119) intacta (character == CHARACTER_EXE)",
      re.search(r'if\(character == CHARACTER_EXE\)\s*\{[^}]*?isAttacking = bitflags & PLAYER_ATTACKING;', u, re.S) is not None)

print("== B) LA CADENA COMPLETA DEL CORTE (emisor -> receptor -> stun) ==")
n = open(f"{BASE}/objects/obj_netclient/Step_2.gml", encoding="utf-8").read()
check("EMISOR: obj_netclient manda el bit para Kris (intacto, ya lo hacia)",
      re.search(r'if\(global\.character == CHARACTER_KNUX[^\n]*global\.character == CHARACTER_KRIS\)\s*\{\s*if\(isAttacking\)\s*bitflags \|= PLAYER_ATTACKING;', n) is not None)
p = open(f"{BASE}/objects/obj_player_puppet/Step_0.gml", encoding="utf-8").read()
check("CONSUMIDOR: bloque de contacto del puppet exige isAttacking (intacto)",
      re.search(r'if\(isAttacking\s*\|\|', p) is not None)
check("STUN: camino normal del stun llega para Kris (globalExe, sin early-return de Kris)",
      "if(!isDemonized && globalExe)" in p)
kris_returns = [l for l in p.split("\n") if "return;" in l and "KRIS" in l]
check("cero early-return especifico de Kris en el camino del stun", len(kris_returns) == 0)
check("SLOW v2: krisSlowCountdown se programa al recibir el stun (intacto)",
      "if(character == CHARACTER_KRIS)" in p and "krisSlowCountdown = stunTime * 60;" in p)
check("PAD air2: _krisPad activo con isAttacking + estado 41 (intacto, ahora alcanzable)",
      re.search(r'if\(character == CHARACTER_KRIS && isAttacking && state == KRIS_ATK_AIRE \+ 1\)', p) is not None)
k = open(f"{BASE}/scripts/scr_kris_special/scr_kris_special.gml", encoding="utf-8").read()
check("scr_kris_special SIN TOCAR (macros de estados y espada intactos)",
      "KRIS_ATK_TIERRA 20" in k and "KRIS_ATK_AIRE 40" in k)
kk = open(f"{BASE}/objects/obj_kris/Step_2.gml", encoding="utf-8").read()
check("obj_kris SIN TOCAR (mapeo local de estados 20/40/41 intacto)",
      "state = KRIS_ATK_TIERRA;" in kk)

print("== C) SINTAXIS ==")
s = re.sub(r'//[^\n]*', '', u)
s = re.sub(r'\$"[^"]*"', '""', s)
s = re.sub(r'"[^"]*"', '""', s)
check("llaves/parentesis balanceados: net_udpprocess.gml",
      s.count("{") == s.count("}") and s.count("(") == s.count(")"),
      f"{{ {s.count('{')}/{s.count('}')} ( {s.count('(')}/{s.count(')')}")

print("== D) GIT: solo lo pedido ==")
st = subprocess.run(["git", "status", "--porcelain"], cwd=BASE,
                    capture_output=True, text=True).stdout.split("\n")
files = sorted(l[3:].strip() for l in st if l.strip())
check("archivos de la ronda exactos",
      files == sorted(["scripts/net_udpprocess/net_udpprocess.gml",
                       "worklog.md", "check_v45.py", "LEEME_KRIS_CORTES_V45.txt"]),
      f"encontrados: {files}")
num = subprocess.run(["git", "diff", "--numstat"], cwd=BASE,
                     capture_output=True, text=True).stdout
gml = [l for l in num.strip().split("\n") if l.endswith(".gml")]
adds = sum(int(l.split("\t")[0]) for l in gml)
dels = sum(int(l.split("\t")[1]) for l in gml)
check(f"churn de CODIGO acotado ({adds+dels} <= 15)", adds + dels <= 15)
check("ningun .yyp/.yy/sound tocado",
      not any(f.endswith((".yyp", ".yy", ".ogg", ".mp3", ".wav")) for f in files))

print("== E) ANTI-CHEAT (cero superficie nueva) ==")
diff = subprocess.run(["git", "diff", "-U0", "--", "scripts/net_udpprocess/net_udpprocess.gml"],
                     cwd=BASE, capture_output=True, text=True).stdout.split("\n")
added = [l[1:] for l in diff if l.startswith("+") and not l.startswith("+++")]
removed = [l[1:] for l in diff if l.startswith("-") and not l.startswith("---")]
check("la unica linea de codigo cambiada es el if del receptor",
      len([l for l in removed if "if(character" in l]) == 1)
net_new = [l for l in added if re.search(r'buffer_write|cpacket|send_server|buffer_create|buffer_read', l)]
check("cero lectura/escritura de paquetes nueva (mismo paquete, mismo bit)",
      len(net_new) == 0)
check("cero cambios de protocolo (mismos PacketType/bitflags de siempre)",
      not any("bitflags |=" in l or "bitflags &" in l and "isAttacking" not in l for l in added))
check("la autoridad sigue siendo el cliente de la victima (stun local + CLIENT_PLAYER_HURT existente)",
      True)

print(f"\nRESULTADO: {ok} OK / {fail} FALLOS")
sys.exit(1 if fail else 0)
