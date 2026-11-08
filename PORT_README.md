# Porte de mapas de Sonic MAX Engine → TD2D Remake

Porte 1:1 de los dos primeros niveles del **Sonic MAX Engine** a tu proyecto
*Sonic.exe The Disaster 2D Remake*, pensado para testear cómo reacciona el juego
(mapas largos, muchas instancias, sincronía de anillos, anticheat) en niveles
de 10-11 mil píxeles.

| Mapa | Room | Tamaño | Origen |
|---|---|---|---|
| SMax Green Hill | `room_smax_greenhill` | 10240 × 1248 | `roomGreenHill1` |
| SMax Emerald Hill | `room_smax_emeraldhill` | 11264 × 1024 | `roomEmeraldHill1` |

## Contenido de este paquete

**Archivos NUEVOS** (copiar tal cual dentro de la raíz del proyecto):

- `rooms/room_smax_greenhill/` — room + RoomCreationCode
- `rooms/room_smax_emeraldhill/` — room + RoomCreationCode
- `sprites/spr_smax_gh_tiles/` — terreno horneado GH (5 frames 2048×1024, banda y 224-1248)
- `sprites/spr_smax_gh_top/` — franja alta GH (ruta superior, frames mayormente vacíos = autocrop los hace gratis)
- `sprites/spr_smax_eh_tiles/` — terreno horneado EH (6 frames, banda y 16-1040)
- `sprites/background_ehz_sky/` — cielo EHZ animado (10 frames, del MAX)
- `sprites/background_ehz_far/` — montañas EHZ (320×256)
- `sprites/spr_pr_ehz/` + `sprites/spr_pr_ehzbg/` — preview del lobby (grupo Prolet)

**Archivos MODIFICADOS** (reemplazan a los existentes):

- `Sonicexe The Disaster 2D Remake.yyp` — registra rooms/sprites nuevos (+9 recursos, +2 RoomOrderNodes)
- `scripts/scr_globals/scr_globals.gml` — `global.levels` índices **21 y 22** + 2 descripciones
- `objects/obj_lobby_prolet/Create_0.gml` — `mapData` índices 21 y 22 (previews)
- `sprites/spr_mapvote/` — **23 frames** (antes 21): iconos de voto nuevos en los frames 21 y 22
- `betterserver-oss/include/Maps.h` — `MAP_COUNT` 20 → **23**, declara `smap_init`
- `betterserver-oss/include/Zone.h` — arrays de zonas 21 → 23
- `betterserver-oss/include/Config.h` — `map_list[23]`
- `betterserver-oss/disasterserver/Maps.c` — 2 entradas en `g_mapList` (índices 21/22) + `smap_init` (4 min + 25 s/jugador, 6 anillos/jugador)
- `betterserver-oss/disasterserver/Zone.c` — zonas anticheat generadas (GH: 97 rects, EH: 141 rects)
- `betterserver-oss/disasterserver/Config.c` — defaults: mapas 21/22 activados, 20 (Fart) sigue fuera del voto

**Visualización** (`docs/` en este paquete, no se copia al proyecto):

- `smax_gh_mapa.jpg` / `smax_eh_mapa.jpg` — el mapa horneado completo
- `smax_gh_colision.jpg` / `smax_eh_colision.jpg` — overlay de colisión (azul=sólidos, verde=pendientes rotadas, violeta=plataformas one-way, amarillo=anillos, rojo=spawns, blanco=anillos de escape)

## Instalación

1. Copia las carpetas `rooms/`, `sprites/`, `scripts/`, `objects/` y el `.yyp`
   encima de tu proyecto (merge de carpetas: solo añade salvo los archivos
   modificados listados arriba, que reemplazan).
2. Abre el proyecto en GameMaker: los rooms aparecen al final del orden.
3. Recompila el servidor (`compilar_server.bat` / `build_android.sh`):
   los cambios de C++ son retrocompatibles con clientes viejos (los mapas
   nuevos simplemente no salen votados si el cliente es viejo... ojo: un
   cliente viejo que reciba id 21/22 dibujaría icono equivocado y room
   inexistente → **usa cliente y servidor actualizados a la vez**).

## Cómo están construidos

- **Colisión**: se rasterizó la máscara de todos los objetos `objParentTerrain`
  del MAX (a 1 px, apertura morfológica para quitar decoración), se cuantizó a
  celdas de 16 px y se descompuso en rects greedy → `obj_solid_block`
  escalados (como tu room_greenhill). Las **pendientes** se detectan como
  cadenas diagonales de celdas de superficie y se emiten como **bloques
  rotados** (mismo sistema que tus colinas de ±25°), con división recursiva
  para curvas. El suelo principal quedó 100 % continuo (verificado por columna).
- **Plataformas one-way**: `objPlatform01Inv`, `objBridge`, plataformas
  móviles/caídas del MAX → `obj_platform_jumptrough` estáticos en su posición.
- **Springs**: amarillos del MAX → `obj_bspring_up` (potencia 10 = la misma);
  girados 90°/270° → `obj_bspring_right`/`_left`; los rojos (16) usan el mismo
  bspring (no hay equivalente más fuerte); los mirando hacia abajo no existen
  en TD2D y se omitieron (1 en EH).
- **Anillos**: TODOS portados (GH 153, EH 210) como `obj_ring_spawner`
  (máximo estrés para el netcode, como pediste).
- **Visual**: todos los tiles/decoración se hornearon en sprites gigantes de
  2048×1024 y se dibujan con tu propio `scr_level_split` + `obj_tile`
  (culling por cámara incluido). GH reutiliza tus fondos `background_greenhill*`
  + lluvia (`obj_ghz_controller`); EH usa el parallax original del MAX
  (cielo animado + montañas).
- **Spawns**: supervivientes junto al inicio del nivel, EXE en el extremo
  opuesto (~10-11 k px), 6 anillos de escape repartidos, 2 `obj_abyss_target`
  para caídas a pozos.
- **Anticheat**: las zonas del servidor se generaron de los mismos rects de
  colisión (áreas donde un jugador legítimo jamás puede estar).

## Simplificaciones conocidas (decisiones de porte)

1. Enemigos, spikes, monitores, checkpoints y switches de capa del MAX: **no
   portados** (no existen en TD2D o romperían el equilibrio).
2. Plataformas móviles: en realidad los rooms del MAX solo tenían *marcadores*
   de dirección sin plataformas asociadas, así que no hubo nada que portar.
3. Tiles "foreground" de EH (35 instancias delante del jugador en el MAX) se
   hornearon en la capa trasera: el jugador pasa por delante en vez de detrás.
4. Cascadas animadas: se horneó el frame 0 (estáticas).
5. Música: GH usa `mus_hill`; EH usa `mus_kindandfair` para distinguir mapas
   de oído. Cámbialo en el RoomCreationCode si prefieres otra.

## Cómo probar rápido

- **En servidor**: monta el servidor recompilado, crea partida y vota
  "SMax Green Hill" / "SMax Emerald Hill" (salen en el sorteo de 3 mapas).
- **Práctica**: `.sp` puede sortearlos (están en `map_list`).
- Cosas a mirar en el test: framerate con 153/210 anillos + ~600 instancias,
  estabilidad del sensor de ángulo en las pendientes rotadas, teletransporte
  del `obj_abyss_target` en pozos, y falsos positivos del anticheat al correr
  cuesta abajo rápido (las zonas se generaron conservadoras: solo rects
  axis-aligned del interior del terreno).
