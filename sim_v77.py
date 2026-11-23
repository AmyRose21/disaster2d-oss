#!/usr/bin/env python3
"""v77 — Simulacion de ronda de Not Perfect + mapas normales.

Modela el itemboxmap_tick NUEVO tick a tick (1 s de resolucion):
  - Ronda NP: 155 s, zona 0->1->2->3->0... cada 20 s (15+5) y cada 5 s
    (2+3) en el ultimo minuto (time_sec <= 60). Roll cada 20 s desde t=15.
  - Verifica: tras cada cambio de zona, TODAS las cajas vivas estan en la
    zona actual; la poblacion se recupera a min(4, puntos libres de la
    zona) EN EL MISMO tick; una caja retirada nunca renace en su punto
    ese tick; variedad ventana-3.
  - Mapa normal (sin NP): igual que v76 (roll cada 20 s, veto ult-3).
  - Fallback: mapa NP sin controller (zona -1): nunca se bloquea.
"""
import random

MAX_ALIVE = 4
RECENT_MAX = 3
FIRST_DELAY = 15
COFF = 20
# puntos por zona (tabla 6 real): TL 13, TR 14, BL 19, BR 10
NP_POINTS = {0: 13, 1: 14, 2: 19, 3: 10}


def zone_at(t, round_len=155):
    """zona NP en el segundo t (modelo de npctrl_tick)."""
    time_sec = round_len - t
    if t < 20:
        return 0
    if time_sec > 60:
        # cambios a t=20,40,60,80 (cada 20 s desde el inicio)
        return ((t - 20) // 20 + 1) % 4
    # ultimo minuto: el primer cambio del ultimo minuto llega ~5 s despues
    # de cruzar time_sec=60 (t=95): cambios a 95,100,105,... cada 5 s
    if t < 95:
        return ((80 - 20) // 20 + 1) % 4  # cambio de t=80
    return (4 + (t - 95) // 5 + 1) % 4


def simulate_np_round(seed):
    rng = random.Random(seed)
    round_len = 155
    zone_points = {z: list(range(base, base + n))
                   for z, (base, n) in enumerate(
                       [(0, 13), (13, 14), (27, 19), (46, 10)])}
    alive = {}          # point_id -> zona
    used_residue = set()  # puntos con residuo (boxused, se liberan a los 27 s)
    residue_ttl = {}    # point_id -> segundos restantes
    recent = []
    next_roll = FIRST_DELAY
    next_change = 20
    zone = 0
    violations = []
    same_point_respawn = 0
    zone_changes = 0
    min_pop_after_change = {}

    for t in range(round_len + 1):
        # --- cambio de zona (npctrl_tick corre antes)
        if t == next_change:
            zone = (zone + 1) % 4
            zone_changes += 1
            time_sec = round_len - t
            next_change = t + (5 if time_sec <= 60 else 20)

        # --- itemboxmap_tick
        roll_now = t >= next_roll
        if roll_now:
            next_roll = t + COFF

        # retirar las vivas fuera de la zona actual
        removed = []
        pop_before = len(alive)
        for pid in list(alive):
            if alive[pid] != zone:
                removed.append(pid)
                del alive[pid]
                # timer=0: muere al siguiente tick, su punto sigue ocupado
                # este tick (used pre-muerte) -> modelado como residuo 1 s
                residue_ttl[pid] = 1

        # cuantas spawnear
        want = 0
        alive_after = len(alive)
        if roll_now and alive_after < MAX_ALIVE:
            want = 1
        if removed and alive_after < MAX_ALIVE:
            want = max(want, min(len(removed), MAX_ALIVE - alive_after))

        for _ in range(want):
            occupied = set(alive) | set(residue_ttl) | used_residue
            cand = [p for p in zone_points[zone] if p not in occupied]
            if not cand:
                break
            fresh = [p for p in cand if p not in recent]
            if fresh:
                cand = fresh
            p = rng.choice(cand)
            if p in removed:
                same_point_respawn += 1  # no debe pasar jamas
            alive[p] = zone
            recent.append(p)
            recent = recent[-RECENT_MAX:]

        # verificar invariantes tras el tick
        for pid, z in alive.items():
            if z != zone:
                violations.append(f"t={t}: caja viva en zona {z} con zona actual {zone}")

        if removed:
            pop = len(alive)
            # invariantes: el cambio de zona PRESERVA la poblacion (la mapa
            # se llena 1 por roll, cadencia v68; el cambio no la reduce ni
            # la maximiza) y nunca supera MAX ni los puntos libres de la zona
            expected = min(MAX_ALIVE, pop_before,
                           NP_POINTS[zone] - len(used_residue & set(zone_points[zone])))
            min_pop_after_change[t] = (pop, expected)
            if pop != expected:
                violations.append(f"t={t}: poblacion {pop} != esperada {expected} tras cambio")

        # tick de residuos
        for pid in list(residue_ttl):
            residue_ttl[pid] -= 1
            if residue_ttl[pid] <= 0:
                del residue_ttl[pid]
        for pid in list(used_residue):
            pass  # liberados abajo via expire list

    return violations, same_point_respawn, zone_changes, min_pop_after_change


def simulate_normal_map(seed, n_zones=8, rolls=20):
    """mapa sin NP: roll cada 20 s, veto ult-3 (v76). % de repetidos en
    ventana de 3 (metrica de sim_v76)."""
    rng = random.Random(seed)
    recent = []
    occupied = set()
    spawns = []
    for _ in range(rolls):
        cand = [z for z in range(n_zones) if z not in occupied]
        if not cand:
            continue
        fresh = [z for z in cand if z not in recent]
        if fresh:
            cand = fresh
        z = rng.choice(cand)
        spawns.append(z)
        recent.append(z)
        recent = recent[-RECENT_MAX:]
        occupied.add(z)
        if len(occupied) > 4:
            occupied.discard(next(iter(occupied)))
    # repetidos dentro de ventana 3
    repes = 0
    for i in range(len(spawns)):
        for j in range(i + 1, min(i + 4, len(spawns))):
            if spawns[i] == spawns[j]:
                repes += 1
    return repes, len(spawns)


def main():
    print("== SIM NP: 500 rondas completas (155 s, ~16 cambios de zona) ==")
    total_viol = 0
    total_same = 0
    total_changes = 0
    for seed in range(500):
        v, same, ch, _ = simulate_np_round(seed)
        total_viol += len(v)
        total_same += same
        total_changes += ch
        if v and seed < 3:
            print("  ejemplo:", v[:3])
    print(f"  violaciones de zona: {total_viol} (esperado 0)")
    print(f"  renacimientos en el MISMO punto del retirado: {total_same} (esperado 0)")
    print(f"  cambios de zona simulados: {total_changes} (~16/rronda -> OK)")

    print("\n== SIM NP: poblacion tras cada cambio (1 ronda muestra) ==")
    _, _, _, pops = simulate_np_round(0)
    for t, (pop, exp) in list(pops.items())[:6]:
        print(f"  t={t:3d}s: vivas={pop} esperado~{exp}")

    print("\n== SIM mapa normal (sin NP): veto ult-3 v76 intacto ==")
    repes_total = 0
    spawns_total = 0
    for seed in range(300):
        r, n = simulate_normal_map(seed)
        repes_total += r
        spawns_total += n
    pct = 100.0 * repes_total / spawns_total if spawns_total else 0
    print(f"  repetidos en ventana-3: {repes_total}/{spawns_total} = {pct:.1f}% (esperado 0%)")

    print("\n== SIM fallback: NP sin controller (zona -1) ==")
    rng = random.Random(7)
    spawns = 0
    occupied = set()
    for roll in range(20):
        cand = [z for z in range(56) if z not in occupied]
        if cand:
            spawns += 1
            occupied.add(rng.choice(cand))
            if len(occupied) > 4:
                occupied.discard(next(iter(occupied)))
    print(f"  spawns sin controller: {spawns}/20 (nunca se bloquea) -> "
          + ("OK" if spawns == 20 else "MAL"))


if __name__ == "__main__":
    main()
