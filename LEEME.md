# LEEME — v4.7: Metal Amy (fix sprite del dash + sonido de stun + SCAN)

Copia estos 13 archivos sobre tu copia local del repositorio
(`C:\Users\AM\Documents\GitHub\disaster2d-oss`), respetando las carpetas.
Después haz commit y push tú mismo. Todo parte de la v4.6 que ya tienes
aplicada y probada.

## Qué se arregla / añade

1. **Fix del sprite al impactar con el dash (X)**
   - Antes: al aterrizar o impactar durante el impulso aparecía
     `spr_metalamy_attack11`.
   - Ahora: el dash usa SIEMPRE `spr_metalamy_attack2`, en el aire y en
     tierra; al golpear o aterrizar el sprite se mantiene igual.
   - `spr_metalamy_attack11` queda fuera del kit: ninguna referencia
     activa (el slot 14 del array de animaciones reusa `attack2`).
   - Visible también para los demás jugadores (el estado viaja igual y
     el puppet de cada cliente usa el mismo array).

2. **Sonido al ser stuneada: `snd_metal_stun`**
   - Caso nuevo `EXE_METALAMY` en `scr_exe_stunsound`.
   - Suena con las tres fuentes de stun: trampa de Amelia, bola de
     fuego de Blaze y proyectil de Tails (la trampa era la única que no
     invocaba el sonido propio del personaje; se le añadió la llamada
     con el mismo patrón).
   - Los demás clientes lo oyen por red: `snd_metal_stun` entra al
     final de `global.net_snds` (posición real 115).

3. **Habilidad nueva: SCAN (tecla V)**
   - Rastreador: revela la dirección de TODOS los supervivientes
     durante 3 s con una aguja por objetivo en anillo alrededor de ella
     (pulsado y con fundido al expirar).
   - Enfriamiento: 20 s.
   - Pose propia: `spr_metalamy_scan` (0,8 s, solo en tierra; el dash y
     la bala la pisan; el stun la corta).
   - Sonido: `snd_egg_tracker` (el sonido del rastreador del juego).
   - Cero paquetes nuevos: los supervivientes ya viajan sincronizados,
     el scan es solo visual.
   - Filtros de la aguja normal respetados: muertos, esbirros y el velo
     de gracia de Amelia quedan ocultos.
   - Macros ajustables en `scr_metalamy_special.gml`:
     `METALAMY_SCAN_RECHARGE` (20 s), `METALAMY_SCAN_TIME` (3 s),
     `METALAMY_SCAN_POSE` (0,8 s).

4. **Tu pregunta sobre los iconos y la letra de la tecla**
   - No hace falta editar ningún PNG. El mecanismo v4.3/v4.3b
     (`drawKeyIcon`) afecta a todos los iconos de habilidad: recorta el
     arte para saltarse la letra horneada y dibuja la tecla REAL
     (remapeable) al lado.
   - Con `spr_gui_metalamy_indy` igual: la V horneada y su keycap
     (columnas 24–31 del PNG) quedan recortadas con `artW = 14` (solo
     se dibuja el ojo) y la tecla real se dibuja dinámica.
   - Si remapeas la V en Opciones, el icono se actualiza al instante.

## Archivos

```
objects/obj_metalamy/Create_0.gml        (variables del scan)
objects/obj_metalamy/Step_0.gml          (el stun corta la pose)
objects/obj_metalamy/Step_2.gml          (estado del dash + pose scan)
objects/obj_metalamy/Draw_76.gml         (animaciones fusionadas + scan)
objects/obj_amelia_trap/Create_0.gml     (sonido de stun del personaje)
objects/obj_exe_indicator/Create_0.gml   (init de las agujas del scan)
objects/obj_exe_indicator/Step_2.gml     (recolección de ángulos)
objects/obj_exe_indicator/Draw_64.gml    (anillo de agujas)
objects/obj_playerui/Draw_64.gml         (icono V en el HUD)
scripts/scr_exe/scr_exe.gml              (slot 14 = attack2, slot 21 = scan)
scripts/scr_exe_stunsound/scr_exe_stunsound.gml  (caso Metal Amy)
scripts/net_sounds/net_sounds.gml        (snd_metal_stun al final)
scripts/scr_metalamy_special/scr_metalamy_special.gml  (macros + activación)
worklog.md                               (registro; opcional)
```

## Verificación hecha

- Balance de llaves/paréntesis/corchetes de los 13 GML: correcto.
- `net_snds`: 116 entradas reales (0–115); última, `snd_metal_stun`.
- Array de animaciones de Metal Amy: 22 slots (14 y 15 = `attack2`,
  21 = `scan`).
- Ninguna referencia activa a `spr_metalamy_attack11`.
- El receptor de `CLIENT_SOUND_EMIT` ignora índices fuera de rango: un
  cliente sin la v4.7 que reciba el índice del sonido de stun no se
  cuelga, solo no lo reproduce.
- Pendiente: partida real de prueba.

## Nota sobre los índices de `net_snds`

Los comentarios de índice de ese array venían arrastrando un desfase
histórico (p. ej. `snd_egg_tracker` dice 28 y su posición real es 29).
No afecta al juego: el índice se calcula en tiempo de ejecución con
`array_find_index` a ambos lados de la conexión; lo que importa es el
orden. El bloque de Metal Amy quedó verificado contra el array real.
