# LEEME — v4.8: Metal Amy (pasivas de la cazadora + scan visión + láser anti-anillos)

Copia estos 15 archivos sobre tu copia local del repositorio
(`C:\Users\AM\Documents\GitHub\disaster2d-oss`), respetando las carpetas.
Después haz commit y push tú mismo. Todo parte de la v4.7 que ya tienes
aplicada y commiteada.

## Qué se añade / cambia

1. **El scan se vuelve VISIÓN (8 s)**
   - Antes (v4.7): 3 s de agujitas indicadoras alrededor de ella.
   - Ahora: **8 s** (`METALAMY_SCAN_TIME`) viendo a cada superviviente
     vivo: su silueta se dibuja en rojo brillante **encima del mapa**,
     a través de paredes, terreno y escondites (`obj_exe_indicator`
     en capa GUI, con fundido en el último medio segundo).
   - La que cae fuera de la vista de 480×270 no desaparece: su silueta
     queda **fijada al borde de la pantalla** (más tenue, señalando
     hacia dónde está).
   - Los timers del scan pasaron al `Step_0` del objeto: ya no se
     congelan si la stunean a mitad de revelado.
   - Sigue siendo cero paquetes: los puppets ya viajan sincronizados.

2. **Pasiva 1 — Ejecución de los débiles**
   - Si el **láser** impacta a un objetivo con **menos del 30 % de
     vida** (`METALAMY_EXEC_HP`), cae derribado **directamente** (el
     flujo completo de una vida a cero: agonía, revive posible).
   - NO aplica a: quien ya cayó una vez (moribundo), ni a los
     auto-revivibles (Vanilla, Sonic, Amy Canon, Sally Canon), ni a
     Amelia — esos comen el daño normal de 20.
   - El parry de Sonic/Amy Canon, los i-frames y el escudo de Sally se
     respetan ANTES de ejecutar: si el golpe no cala, no hay ejecución.
   - Mismos paquetes que un golpe letal normal (stats modo 2/3 + el
     `CLIENT_PLAYER_DEATH_STATE` del flujo de caída): cero paquetes
     nuevos.

3. **Pasiva 2 — Marca de debilidad**
   - Cada golpe de Metal Amy que cala (láser, dash, contacto, escudo
     roto) pone TODAS las habilidades del golpeado en **6 s de
     recarga** (`METALAMY_WEAKMARK_TIME`); las que ya enfriaban,
     6 s extra.
   - CD **propio de 16 s por superviviente**
     (`METALAMY_WEAKMARK_CD`): marcar a uno no gasta el CD de otro.
   - Implementación: `scr_weak_mark_hit()` en `scr_player_hurt.gml`
     (corre en el cliente de la víctima, como el daño). La llama el
     láser y el contacto del puppet. La variable `weakMarkCd` se crea
     al vuelo — no se tocó ningún Create de los 13 supervivientes.
   - Se respetan las convenciones de cada timer (el vuelo de Tails
     cuenta en negativo; el parry lleva su máximo a la par para que el
     HUD no desfase).

4. **Pasiva 3 — Marca de la cazadora**
   - Con **exactamente 1 superviviente vivo** (esbirros y muertos
     fuera del conteo), la V se apaga y el rastreo sale solo:
     **ventana de 8 s cada 14 s** (`METALAMY_HUNT_TIME`); el
     enfriamiento arranca cuando la ventana TERMINA.
   - Reviven a alguien (2+ vivos) → vuelve al scan manual con la V.
   - El icono V del HUD se vuelve **dorado** en modo caza y su anillo
     refleja el ciclo pasivo.
   - Todo local en el cliente de Metal Amy: cero paquetes.

5. **Pasiva 4 — Adaptabilidad**
   - Si la aturden dentro de los **3 s** siguientes a perder la
     inmunidad por golpe (`METALAMY_ADAPT_WINDOW`), gana **+1 carga
     del dash** (hasta las 3 máximas), con choque metálico y sacudida
     de cámara.
   - Detección genérica del arranque del stun: cubre TODAS las fuentes
     (trampa de Amelia, bola de Blaze, proyectil de Tails, electro de
     Eggman, parry de Sonic…) sin tocarlas.
   - Stun-lockearla la vuelve MÁS peligrosa, no más segura.

6. **Mejora del láser: revienta anillos amarillos**
   - Cada anillo amarillo que el láser cruza en su vuelo estalla
     (`obj_ring/Step_0.gml`, mismo patrón de relay que el láser de
     Tails esbirro: `CLIENT_RING_BROKE` + `CLIENT_RING_COLLECTED`).
   - Solo lo triggerea el cliente de Metal Amy (sin doble proceso).
   - Los anillos ROJOS quedan intactos (son otro objeto).

7. **Tier list actualizada**
   - `TierList_Mejoras_V4_8.html` (nueva página, la v3.2 queda como
     historial): badges v4.7/v4.8, artículos N (scan v4.7), O (visión
     8 s) y P (las cuatro pasivas), **Metal Amy A→S** (ficha completa
     reescrita: pasiva, X/C/V, pros y contras), banner de movimiento
     y verificación de pie.

## Archivos

```
objects/obj_exe_indicator/Create_0.gml   (scanList de referencias)
objects/obj_exe_indicator/Step_2.gml     (recolección de supervivientes)
objects/obj_exe_indicator/Draw_64.gml    (siluetas a través de paredes)
objects/obj_metal_amy_bullet/Step_0.gml  (ejecución + marca del láser)
objects/obj_metalamy/Create_0.gml        (vars huntMode/adaptabilidad)
objects/obj_metalamy/Step_0.gml          (timers + cazadora + adaptabilidad)
objects/obj_player_puppet/Step_0.gml     (marca en el golpe de contacto)
objects/obj_playerui/Draw_64.gml         (icono V: modo caza dorado)
objects/obj_ring/Step_0.gml              (láser revienta anillos)
scripts/scr_metalamy_special/            (macros v4.8 + gateo de la V)
scripts/scr_move_basic/scr_move_basic.gml (tick del weakMarkCd)
scripts/scr_player_hurt/scr_player_hurt.gml (scr_weak_mark_hit)
TierList_Mejoras_V4_8.html               (tier list nueva)
worklog.md                               (registro; opcional)
LEEME.md                                 (este archivo)
```

## Verificación hecha

- Balance de llaves/paréntesis/corchetes de los 12 GML: correcto
  (`verify_v48.py`, junto con 27 marcadores v4.8 y los 6 sonidos
  usados).
- La página nueva renderiza sin errores de consola y los 11 textos
  clave son visibles en sus pestañas (`check_tierlist_v48.py`,
  Playwright).
- Cero paquetes nuevos en todo el v4.8 (ver punto a punto arriba).
- Pendiente: partida real de prueba.

## Macros para ajustar el balance

Todo en `scripts/scr_metalamy_special/scr_metalamy_special.gml`:

- `METALAMY_SCAN_TIME` — 8 s de revelado.
- `METALAMY_SCAN_RECHARGE` — 20 s (uso manual de la V).
- `METALAMY_EXEC_HP` — 30 (% de vida: láser = derribo por debajo).
- `METALAMY_WEAKMARK_TIME` — 6 s de recarga infligida al golpeado.
- `METALAMY_WEAKMARK_CD` — 16 s por superviviente.
- `METALAMY_HUNT_TIME` — 14 s de ciclo del rastreo pasivo.
- `METALAMY_ADAPT_WINDOW` — 3 s de ventana de adaptabilidad.
