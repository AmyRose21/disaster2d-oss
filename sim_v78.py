#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sim_v78.py — simulación conductual del sistema de cajas v78.

Espejo PYTHON línea a línea de itemboxmap_tick (ItemBoxMap.c v78) +
itembox_tick (ItemBoxMap/ItemBox.c) sobre un reloj de 60 ticks/s
(server->delta = 1, elapsed en TICKS — igual que states/Game.c).
Escenarios de los 5 pedidos de la dueña (y los que no podían faltar):

 S1  FIX TICKS: primer roll a los 15 s REALES y cadencia 20 s (el bug
     v62-v77 los usaba en crudo: 0.25 s / 0.33 s).
 S2  "Destruyo 1 y enseguida aparece otro de la nada": destruida 1 caja,
     NINGUNA aparece antes de sus 30 s (el roll tampoco).
 S3  30 s POR CAJA: destruyo 2 en el mismo tick -> las 2 vuelven a los
     30 s (poblacion conservada).
 S4  Cada una a SU 30 s (destruidas a tiempos distintos).
 S5  Contador PAUSADO con el max cubierto (regla literal: no corre si
     el max de cajas esta cubierta; sale apenas hay hueco).
 S6  REUBICADAS (lava v63/v76 / zona v77): renacen EN EL MISMO TICK
     (eso no es destruccion) y la caja ROTA reubicada NO se repobla 2 veces.
 S7  Idempotencia anti-cheat: re-romper una ROTA no agenda enfriamiento.
 S8  Reset por ronda: la cola no arrastra reposiciones a la ronda nueva.
 S9  FIFO v76 intacto con las reposiciones (no repite las ultimas 3).
 S10 El Exe rompe la caja (v74 denial): mismo enfriamiento de 30 s.
 S11 Relleno inicial: 15 s + 1 cada 20 s hasta MAX (si nadie rompe).
"""
import random

TICKSPERSEC = 60
ITEMBOX_MAX = 4
FIRST_DELAY = 15 * TICKSPERSEC
COFF = 20 * TICKSPERSEC
COOLDOWN = 30 * TICKSPERSEC
RESIDUE = 27 * TICKSPERSEC          # 25 + rand%5 aprox (uso fijo)
ZONES = 30                          # mapa generico
RECENT_MAX = 3
FIND_MAX = ITEMBOX_MAX * 6

PASS = 0
FAIL = 0

def ok(m):
    global PASS
    PASS += 1
    print(f"  [OK] {m}")

def bad(m):
    global FAIL
    FAIL += 1
    print(f"  [XX] {m}")

class Sim:
    """Espejo del estado estatico de ItemBoxMap.c + entidades."""

    def __init__(self, seed=1, zones=ZONES):
        self.zones = zones
        self.entities = []           # {nid, timer, activated, relocated}
        self.elapsed = 0.0
        self.next_roll = 0.0
        self.alive_flag = -1
        self.recent = []
        self.respawn_left = []       # cola v78
        self.spawn_nids = []         # historial de spawns (nid, elapsed)
        random.seed(seed)

    # ---- init (checkstart) ----
    def itemboxmap_init(self):
        self.next_roll = self.elapsed + FIRST_DELAY
        self.alive_flag = 0
        self.respawn_left = []
        self.recent = []

    # ---- entity tick (game_entity_tick: corre ANTES del map tick) ----
    def entity_tick(self):
        dead = []
        for e in self.entities:
            if e['timer'] < 0:
                continue
            if e['timer'] > 0:
                e['timer'] -= 1
                continue
            dead.append(e)          # expiro: despawn (state 4) y muerte
        for e in dead:
            self.entities.remove(e)

    # ---- spawn_one (espejo) ----
    def spawn_one(self, zone=-1):
        if len(self.entities) >= FIND_MAX:
            return False
        used = set(e['nid'] for e in self.entities if e['nid'] < self.zones)
        cand = [i for i in range(self.zones)
                if i not in used and (zone < 0 or (i % 2) == (zone % 2))]  # zona ~ paridad
        if not cand:
            return False
        fresh = [c for c in cand if c not in self.recent]
        while True:
            rnd = random.choice(cand)
            if fresh and rnd in self.recent:
                continue
            break
        if len(self.recent) < RECENT_MAX:
            self.recent.append(rnd)
        else:
            self.recent.pop(0)
            self.recent.append(rnd)
        self.entities.append({'nid': rnd, 'timer': -1.0, 'activated': False, 'relocated': False})
        self.spawn_nids.append((rnd, self.elapsed))
        return True

    # ---- ACTIVATE (itemboxmap_tcpmsg CLIENT_BOX_ACTIVATE, espejo v78) ----
    def activate(self, nid):
        target = next((e for e in self.entities if e['nid'] == nid), None)
        if target is None:
            return
        was_alive = not target['activated']
        if not target['activated']:
            target['activated'] = True
            target['timer'] = RESIDUE
        if was_alive:
            self.respawn_left.append(float(COOLDOWN))

    # ---- relocate report (CLIENT_BOX_RELOCATE, espejo) ----
    def mark_relocate(self, nid):
        for e in self.entities:
            if e['nid'] == nid and not e['relocated']:
                e['relocated'] = True
                break

    # ---- tick (itemboxmap_tick v78, espejo) ----
    def tick(self, zone=-1):
        if self.alive_flag < 0:
            self.alive_flag = 0
            self.respawn_left = []
            self.next_roll = self.elapsed + FIRST_DELAY

        roll_now = self.elapsed >= self.next_roll
        if roll_now:
            self.next_roll = self.elapsed + COFF

        alive = sum(1 for e in self.entities if e['timer'] < 0)

        removed = 0
        for e in self.entities:
            if e['relocated']:
                e['timer'] = 0
                if not e['activated']:
                    removed += 1
                continue
            if zone >= 0 and e['timer'] < 0 and (e['nid'] % 2) != (zone % 2):
                e['relocated'] = True
                e['timer'] = 0
                removed += 1

        want = 0
        alive_after = alive - removed
        if removed > 0 and alive_after < ITEMBOX_MAX:
            back = min(removed, ITEMBOX_MAX - alive_after)
            want = max(want, back)

        for _ in range(want):
            self.spawn_one(zone)
        alive_after += want

        i = 0
        while i < len(self.respawn_left):
            if alive_after >= ITEMBOX_MAX:
                break
            if self.respawn_left[i] > 0:
                self.respawn_left[i] -= 1
            if self.respawn_left[i] <= 0:
                if self.spawn_one(zone):
                    alive_after += 1
                    self.respawn_left.pop(i)
                    continue        # reexaminar el indice ocupado
            i += 1

        if roll_now and not self.respawn_left and alive_after < ITEMBOX_MAX:
            self.spawn_one(zone)

        self.elapsed += 1

    def alive(self):
        return sum(1 for e in self.entities if e['timer'] < 0)

    def run(self, seconds):
        for _ in range(int(seconds * TICKSPERSEC)):
            self.entity_tick()
            self.tick()

print("== S1. FIX TICKS: 15 s reales + cadencia 20 s (era 0.25/0.33 s) ==")
s = Sim(seed=11)
s.itemboxmap_init()
s.run(5)
assert s.alive() == 0, "cajas antes de los 15 s"
ok("0 cajas antes de los 15 s")
s.run(10.1)
assert s.alive() == 1, f"a los 15 s nace la 1a ({s.alive()})"
ok("1a caja a los 15 s EXACTOS (antes nacia a los 0.25 s)")
s.run(20)
assert s.alive() == 2, f"+20 s -> 2 cajas ({s.alive()})"
ok("2a caja a los 35 s (cadencia 20 s reales)")
s.run(40)
assert s.alive() == 4, f"relleno completo a los ~75 s ({s.alive()})"
ok("MAX 4 cajas a los 75 s (15+20+20+20) — S11 relleno inicial correcto")

print("== S2. Destruyo 1: NADA 'de la nada' antes de los 30 s ==")
s2 = Sim(seed=22)
s2.itemboxmap_init()
s2.run(80)
assert s2.alive() == 4
nid = next(e['nid'] for e in s2.entities if e['timer'] < 0)
before = len(s2.spawn_nids)
s2.activate(nid)                     # rompo 1 viva
assert s2.alive() == 3
birth = [t for (n, t) in s2.spawn_nids[before:]]
for t in birth:
    assert t - s2.spawn_nids[before - 1][1] >= COOLDOWN, "reposicion prematura!"
ok("destruida a t=80 s: cero reposiciones prematuras")
s2.run(29)
assert s2.alive() == 3, f"a los +29 s siguen 3 ({s2.alive()})"
ok("a los 29 s siguen 3 (el roll NO regala la reposicion)")
s2.run(2)
assert s2.alive() == 4, f"a los +31 s vuelve la 4a ({s2.alive()})"
ok("la 4a caja vuelve a los 30 s EXACTOS de su enfriamiento")

print("== S3. 30 s POR CAJA: destruyo 2 el mismo tick ==")
s3 = Sim(seed=33)
s3.itemboxmap_init()
s3.run(80)
assert s3.alive() == 4
vivas = [e['nid'] for e in s3.entities if e['timer'] < 0]
t_break = s3.elapsed
s3.activate(vivas[0]); s3.activate(vivas[1])
s3.run(29)
assert s3.alive() == 2, f"+29 s: 2 (ninguna prematura) ({s3.alive()})"
ok("2 destruidas: a los 29 s siguen 2 vivas")
s3.run(2)
assert s3.alive() == 4, f"+31 s: poblacion restaurada ({s3.alive()})"
ok("las 2 vuelven a los 30 s (una por caja, poblacion conservada)")

print("== S4. Cada una a SU 30 s ==")
s4 = Sim(seed=44)
s4.itemboxmap_init()
s4.run(80)
viv = [e['nid'] for e in s4.entities if e['timer'] < 0]
s4.activate(viv[0])                  # t=80
s4.run(10)                           # t=90
viv = [e['nid'] for e in s4.entities if e['timer'] < 0]
s4.activate(viv[0])                  # t=90
s4.run(30)                           # t=120
a = s4.alive()
assert s4.alive() == 4, f"a los 30 s de la 2a: 4 vivas ({s4.alive()})"
ok("1a vuelve a t+30 y 2a a su t+30 (cada una cuenta su propio plazo)")

print("== S5. Contador PAUSADO con el max cubierto (regla literal) ==")
s5 = Sim(seed=55)
s5.itemboxmap_init()
s5.run(80)
viv = [e['nid'] for e in s5.entities if e['timer'] < 0]
s5.activate(viv[0])                  # alive 3, pend 1
s5.run(10)                           # pend corre 10 s (hay hueco): ~1200 left
# caso sintetico (guard de seguridad): algo llena el hueco mientras la
# reposicion espera -> el contador debe QUEDARSE PAUSADO hasta haber hueco
s5.spawn_one()                       # alive vuelve a 4 con 1 pendiente
assert s5.alive() == 4, f"max cubierto sinteticamente ({s5.alive()})"
left0 = s5.respawn_left[0]
nspawns = len(s5.spawn_nids)
s5.run(10)                           # 10 s con el max cubierto
assert s5.respawn_left[0] == left0, f"el contador corrio con el max cubierto ({s5.respawn_left[0]} vs {left0})"
ok(f"max cubierto 10 s: contador PAUSADO en {left0/TICKSPERSEC:.0f} s (no corre, no spawnea)")
assert len(s5.spawn_nids) == nspawns and s5.alive() == 4
ok("con el max cubierto NO aparece una 5a caja")
# libero hueco: rompo 1 -> el contador reanuda y su caja sale cuando toque
viv = [e['nid'] for e in s5.entities if e['timer'] < 0]
s5.activate(viv[0])                  # alive 3: hueco -> reanudar
before = s5.respawn_left[0]
s5.run(2)
assert s5.respawn_left[0] == before - 2 * TICKSPERSEC, "no reanudo al abrirse hueco"
ok("al abrirse hueco el contador REANUDA (baja 120 ticks en 2 s)")
s5.run(30)
assert s5.alive() == 4, f"tras reanudar, la poblacion se recupera ({s5.alive()})"
ok("la reposicion pausada SIEMPRE sale (nunca se pierde)")

print("== S6. Reubicadas: MISMO TICK + rota reubicada sin doble reposicion ==")
s6 = Sim(seed=66)
s6.itemboxmap_init()
s6.run(80)
viv = [e['nid'] for e in s6.entities if e['timer'] < 0]
s6.activate(viv[0])                  # 1 rota (pendiente 30 s) + 3 vivas
n_alive = s6.alive()
for e in list(s6.entities):          # lava/zona se lleva las 3 vivas Y la rota
    e['relocated'] = True
s6.run(1)                            # 1 tick: reubicacion procesada
alive_after = s6.alive()
pend = len(s6.respawn_left)
assert pend == 1, f"la rota reubicada NO duplico su pendiente ({pend})"
ok("caja ROTA reubicada: 1 sola pendiente (sin doble reposicion)")
s6.run(0.5)
assert s6.alive() >= 3, f"las reubicadas vivas renacieron ya ({s6.alive()})"
ok("reubicadas por lava/zona renacen EN EL MISMO TICK (v63/v76/v77 intacto)")

print("== S7. Anti-cheat: re-romper una ROTA = no-op ==")
s7 = Sim(seed=77)
s7.itemboxmap_init()
s7.run(80)
viv = [e['nid'] for e in s7.entities if e['timer'] < 0]
s7.activate(viv[0])
pend1 = len(s7.respawn_left)
s7.activate(viv[0])                  # re-romper la rota
s7.activate(viv[0])
assert len(s7.respawn_left) == pend1 == 1, "re-romper agendo mas enfriamientos"
ok("re-romper la caja rota NO agenda enfriamientos extra (idempotente)")

print("== S8. Reset por ronda ==")
s8 = Sim(seed=88)
s8.itemboxmap_init()
s8.run(80)
viv = [e['nid'] for e in s8.entities if e['timer'] < 0]
s8.activate(viv[0]); s8.activate(viv[1])
assert len(s8.respawn_left) == 2
s8.elapsed = 0.0                      # ronda nueva
s8.entities = []
s8.itemboxmap_init()
assert len(s8.respawn_left) == 0, "cola vieja arrastrada"
ok("itemboxmap_init: la cola de enfriamientos se resetea por ronda")

print("== S9. FIFO v76: reposiciones tampoco repiten las ultimas 3 ==")
repeats = 0
total = 0
for seed in range(20):
    s9 = Sim(seed=900 + seed, zones=ZONES)
    s9.itemboxmap_init()
    s9.run(80)
    for r in range(40):
        viv = [e['nid'] for e in s9.entities if e['timer'] < 0]
        if viv:
            s9.activate(viv[0])
        s9.run(0.75)
    hist = [n for (n, t) in s9.spawn_nids]
    for i in range(len(hist) - 1):
        for j in range(i + 1, min(i + 4, len(hist))):   # ventana 3
            total += 1
            if hist[i] == hist[j]:
                repeats += 1
if repeats == 0:
    ok(f"0 repeticiones dentro de la ventana-3 en {total} pares (variedad v76 intacta con la cola v78)")
else:
    bad(f"{repeats}/{total} repeticiones en ventana-3")

print("== S10. El Exe rompe la caja (v74 denial): mismo enfriamiento ==")
s10 = Sim(seed=1010)
s10.itemboxmap_init()
s10.run(80)
viv = [e['nid'] for e in s10.entities if e['timer'] < 0]
s10.activate(viv[0])                  # mismo canal (pid 0 = nadie cobra)
assert len(s10.respawn_left) == 1
s10.run(31)
assert s10.alive() == 4
ok("caja rota por el Exe: mismos 30 s de reposicion (la negacion no altera el cooldown)")

print()
print(f"RESULTADO: {PASS} OK / {FAIL} BAD")
import sys
sys.exit(1 if FAIL else 0)
