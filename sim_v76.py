#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sim_v76.py — Simulacion de variedad de spawns (rings + cajas).
Compara la logica vieja vs la nueva con la MISMA metrica: probabilidad
de que un spawn caiga dentro de la ventana de slots recientemente
usados (mas baja = mas variado). El historial (ventana) se trackea
SEPARADO de la memoria de veto para comparar manzanas con manzanas."""
import random


def sim(n_slots, n_rolls, veto_max, window, seed, max_alive):
    """veto_max: tamano de la memoria de veto del algoritmo (0=viejo rings,
    1=viejo cajas, 4/3=nuevo). window: ventana de la METRICA (igual para
    ambos lados de la comparacion)."""
    random.seed(seed)
    used = set()          # slots ocupados ahora mismo
    veto = []             # memoria de veto del algoritmo
    history = []          # historial completo (para la metrica)
    in_window = 0
    for _ in range(n_rolls):
        fresh = [s for s in range(n_slots)
                 if s not in used and s not in veto]
        while True:
            rnd = random.randrange(n_slots)
            if rnd in used:
                continue
            if fresh and rnd in veto:
                continue
            break
        # metrica: cayo dentro de la ventana de la historia reciente?
        if rnd in history[-window:]:
            in_window += 1
        history.append(rnd)
        veto.append(rnd)
        if len(veto) > veto_max:
            veto.pop(0)
        used.add(rnd)
        # liberar slots viejos (vida util ~ max_alive entidades)
        if len(used) >= max_alive:
            used.discard(random.choice(list(used)))
    return in_window


print("== RINGS: 22 slots (Hide and Seek 2), 40 spawns/round, metrica = "
      "ventana de 4 ==")
old = sum(sim(22, 40, 0, 4, s, 6) for s in range(300))
new = sum(sim(22, 40, 4, 4, s, 6) for s in range(300))
print(f"  viejo (sin memoria):   {old/12000*100:5.1f}%  ({old}/12000)")
print(f"  nuevo (veto ult-4):    {new/12000*100:5.1f}%  ({new}/12000)")

print("== BOXES: 8 zonas, 20 rolls/round, metrica = ventana de 3 ==")
old = sum(sim(8, 20, 1, 3, s, 4) for s in range(300))
new = sum(sim(8, 20, 3, 3, s, 4) for s in range(300))
print(f"  viejo (veto ult-1):    {old/6000*100:5.1f}%  ({old}/6000)")
print(f"  nuevo (veto ult-3):    {new/6000*100:5.1f}%  ({new}/6000)")

# Sanidad: la nueva logica nunca se cuelga con mapas chicos (12 slots min)
print("\n== SANIDAD: anillo con 12 slots (SkyBase) nunca deadlock ==")
for seed in range(50):
    sim(12, 60, 4, 4, seed, 8)
print("  50 simulaciones x 60 spawns: sin deadlock (fallback a 'cualquier libre')")

# Sanidad 2: caja reubicada NUNCA vuelve a su misma zona (used[] del tick)
def relocate_test(seed):
    random.seed(seed)
    zones = 8
    used = set(random.sample(range(zones), 3))  # 3 cajas vivas
    relocated_zone = random.choice(list(used))
    # el tick: la caja reubicada muere PERO used[] se calculo ANTES
    # -> su zona sigue ocupada en este tick para la nueva
    used_now = set(used)  # incluye la zona reubicada
    free = [z for z in range(zones) if z not in used_now]
    new_zone = random.choice(free)
    return new_zone != relocated_zone

res = sum(relocate_test(s) for s in range(1000))
print(f"  caja reubicada renace en OTRA zona: {res}/1000 = {res/10:.0f}% (esperado 100%)")
