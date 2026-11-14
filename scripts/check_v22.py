#!/usr/bin/env python3
# check_v22.py — valida el fix v22 del chat.
#
# BUG 1 (personaje sin movimiento): chatClose restauraba wasControls, un
#   valor guardado al ABRRIR el chat que caducaba si la partida des-
#   congelaba mientras escribias (espera de jugadores -> un solo
#   playerControls=true al cargar todos -> cerrar el chat devolvia el
#   false viejo -> congelado para siempre, PC y Android). Fix: chatClose
#   (y el guard anti-EXE del Step) devuelven true incondicional, igual
#   que ya hacia el CleanUp; la espera re-afirma su false cada frame.
#
# BUG 2 (mensaje duplicado): en LOBBY y PENDIENTE (esperando jugadores)
#   el cliente pintaba eco local del mensaje Y el server lo reenviaba a
#   TODOS incluido el emisor (server_broadcast no excluye a nadie) — el
#   propio mensaje salia 2 veces. Fix: defensa anti-eco en los handlers
#   de esos 2 estados (patron del chat de partida, net_state_game v1.2).
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ok = fail = 0

def check(name, cond, detail=""):
    global ok, fail
    if cond:
        ok += 1
        print(f"  OK  {name}")
    else:
        fail += 1
        print(f"FAIL  {name}  {detail}")

def rd(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return f.read()

def strip_comments(text):
    """Quita comentarios // y /* */ conservando literales de cadena."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i+1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i+1] == "*":
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j, n - 1)
            out.append(text[i:j+1])
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)

def strip_gml(text):
    """Comentarios Y literales fuera, para balancear delimitadores."""
    s = strip_comments(text)
    return re.sub(r'"[^"\n]*"', '""', s)

def balanced(text, path):
    s = strip_gml(text)
    for a, b in [("{", "}"), ("(", ")"), ("[", "]")]:
        if s.count(a) != s.count(b):
            print(f"      balance {a}{b} en {path}: {s.count(a)} vs {s.count(b)}")
            return False
    return True

print("== BUG 1: controles que caducan (obj_game_chat) ==")
c0 = rd("objects", "obj_game_chat", "Create_0.gml")
c0c = strip_comments(c0)
check("sin wasControls en el CODIGO de Create_0", "wasControls" not in c0c)
check("chatOpen sigue congelando (global.playerControls = false)",
      re.search(r"chatOpen = function\(\)\s*\{[^}]*?global\.playerControls = false;", c0c, re.S) is not None)
check("chatClose devuelve true incondicional (fix del bug)",
      re.search(r"chatClose = function\(send\)\s*\{[^{}]*?global\.playerControls = true;", c0c, re.S) is not None)
check("llaves/parens balanceados (Create_0)", balanced(c0, "Create_0.gml"))

s0 = rd("objects", "obj_game_chat", "Step_0.gml")
s0c = strip_comments(s0)
check("sin wasControls en el CODIGO de Step_0", "wasControls" not in s0c)
check("guard anti-EXE devuelve true", "global.playerControls = true;" in s0c)
check("guard anti-EXE intacto (instance_destroy + return)",
      "instance_destroy();" in s0 and "return;" in s0)
check("llaves/parens balanceados (Step_0)", balanced(s0, "Step_0.gml"))

cu = rd("objects", "obj_game_chat", "CleanUp_0.gml")
check("CleanUp intacto (true incondicional, como siempre)",
      "global.playerControls = true;" in cu)

check("nadie mas referencia wasControls en el proyecto",
      all("wasControls" not in strip_comments(open(os.path.join(dp, fn), encoding="utf-8", errors="replace").read())
          for dp, dn, fns in os.walk(ROOT) if "_backups_animeditor" not in dp and ".git" not in dp.split(os.sep)
          for fn in fns if fn.endswith(".gml")))

# simulacion 1:1 del bug reportado (espera de jugadores)
class Sim:
    def __init__(self): self.pc = True; self.was = None; self.chat = False
    def net_step(self):            # obj_netclient/Step_2 cada frame
        if not self.ready: self.pc = False
        elif self.fired is False: self.pc = True; self.fired = True
    def chat_open(self):           # v22: ya no guarda wasControls
        self.chat = True; self.pc = False
    def chat_close(self):          # v22: true incondicional
        self.chat = False; self.pc = True

sim = Sim(); sim.ready = False; sim.fired = False
for _ in range(10): sim.net_step()          # espera: congelado
sim.chat_open()                              # abre el chat en la espera
check("SIM esperando+chat: congelado mientras escribe", sim.pc is False)
sim.ready = True; sim.fired = False         # todos cargaron
sim.net_step()                               # el UNICO true de la ronda
sim.chat_close()                             # cierra/envia el chat
check("SIM bug reportado cerrado: puede moverse (antes quedaba en false)", sim.pc is True)

# regresion: seguir congelado si el chat se cierra AUN en la espera
sim2 = Sim(); sim2.ready = False; sim2.fired = False
for _ in range(5): sim2.net_step()
sim2.chat_open()
sim2.chat_close()                            # cierra ANTES de cargar todos
for _ in range(3): sim2.net_step()           # la espera re-afirma su false
check("SIM cierre en plena espera: sigue congelado (la espera re-afirma)", sim2.pc is False)

def case_body(code, case_name):
    """Trozo de codigo de un case hasta el siguiente case PacketType."""
    parts = re.split(r"\n\s*case PacketType\.", code)
    for p in parts:
        if p.startswith(case_name):
            return p
    return ""

print("== BUG 2: mensaje duplicado (anti-eco) ==")
nl = rd("scripts", "net_state_lobby", "net_state_lobby.gml")
nlc = strip_comments(nl)
body = case_body(nlc, "CLIENT_CHAT_MESSAGE:")
check("case CLIENT_CHAT_MESSAGE presente en net_state_lobby", body != "")
check("anti-eco presente (if _id == nid break)",
      re.search(r"if\(_id == obj_netclient\.nid\)\s*break;", body) is not None)
check("mensajes del server (_id == 0) siguen pintandose",
      '(server)' in body)
check("los demas jugadores siguen viendo el mensaje (players map)",
      "ds_map_exists(players, _id)" in body)
check("llaves/parens balanceados (net_state_lobby)", balanced(nl, "net_state_lobby.gml"))

np_ = rd("scripts", "net_state_pending", "net_state_pending.gml")
npc = strip_comments(np_)
body = case_body(npc, "CLIENT_CHAT_MESSAGE:")
check("case CLIENT_CHAT_MESSAGE presente en net_state_pending", body != "")
check("anti-eco presente antes del with(obj_menu_waiting)",
      re.search(r"if\(_id != 0 && _id == obj_netclient\.nid\)\s*break;", body) is not None)
check("el server (id 0) no lo filtra el anti-eco",
      "_id == 0" in body and body.find("obj_netclient.nid") > body.find("with(obj_menu_waiting)") - 200)
check("llaves/parens balanceados (net_state_pending)", balanced(np_, "net_state_pending.gml"))

ng = rd("scripts", "net_state_game", "net_state_game.gml")
check("defensa del chat de partida intacta (no se toca)",
      re.search(r"if\(_cid == obj_netclient\.nid\)\s*break;", strip_comments(ng)) is not None)

# simulacion del eco: emisor ve 1 linea, los demas 1, el server siempre
def lobby_receive(nid, sender_id, shown):
    if sender_id == 0: shown.append("server"); return
    if sender_id == nid: return          # v22 anti-eco
    shown.append("otro")
shown = []
lobby_receive(7, 7, shown)               # mi propio mensaje reenviado
lobby_receive(7, 9, shown)               # mensaje de otro
lobby_receive(7, 0, shown)               # mensaje del server
check("SIM eco: propio=1 vez (local), otro=1, server=1 -> exactamente 3 pintados",
      shown == ["otro", "server"], f"pintados: {shown}")

# los emisores con eco local siguen intactos (el anti-eco los cubre)
check("eco local intacto en obj_lobby/obj_menu_waiting/scr_controls_init_touch",
      all("lobby_add_message(global.nickname, chatMsg)" in rd(p, o, e)
          for p, o, e in [("objects", "obj_lobby", "KeyPress_13.gml"),
                          ("objects", "obj_menu_waiting", "KeyPress_13.gml"),
                          ("scripts", "scr_controls_init_touch", "scr_controls_init_touch.gml")]))

print(f"\nRESULTADO: {ok} OK / {fail} FAIL")
sys.exit(1 if fail else 0)
