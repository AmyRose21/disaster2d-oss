# Rogue — paquete GameMaker (Sonicexe The Disaster 2D Remake)

## Contenido
- `sprites/` — 18 sprites (los 212 PNG renombrados a GUIDs + `.yy` listos):
  menu_rouge_2, attack, balancing, dead, emotion1/2/3, fall, fly, hurt,
  idle (134 frames, timing de Aseprite incluido), jump, lookdown, lookup,
  run, slide, walk, zipline.
- `objects/obj_rouge/` — objeto jugable: Create/Step/Draw en GML
  (salto, planeo con alas, run/idle/fly/jump/fall/hurt, facing).
- `yyp_check.py` — auditor del proyecto (encuentra la causa del
  "Object reference not set to an instance of an object").
- `yyp_add_rouge.py` — integra este paquete en tu .yyp automaticamente.

## POR QUE EL IDE NO ABRIO TU PROYECTO
"Failed to load project / Object reference not set to an instance of an
object" en GameMaker 2022+ casi siempre es UNA REFERENCIA ROTA dentro del
.yyp o en un .yy:
1. un recurso listado en el .yyp cuyo archivo .yy no existe en disco,
2. un GMSpriteFrame que apunta a un PNG inexistente (frame huérfano),
3. un .yy invalido como JSON (edicion a mano / mezcla de git),
4. ids duplicados en Resources.
El IDE no dice cual: hay que auditar. `yyp_check.py` lista cada una y las
repara donde es seguro (con backup .yyp.bak).

## RUTA A — ARREGLAR EL PROYECTO (1 minuto)
Abre PowerShell/cmd en la carpeta del proyecto y ejecuta:

    py yyp_check.py "Sonicexe The Disaster 2D Remake.yyp" --fix

(primero copia `yyp_check.py` junto al .yyp). Vuelve a abrir el IDE.
Si algo no cuadra, el backup `Sonicexe The Disaster 2D Remake.yyp.bak`
esta intacto.

## RUTA B — ANADIR ROGUE (1 minuto mas)
Con el proyecto ya abriendo:

    py yyp_add_rouge.py "Sonicexe The Disaster 2D Remake.yyp"

Eso copia los 18 sprites + obj_rouge y los REGISTRA en el .yyp con el
formato correcto (ids GUID nuevos, resourcePath). Abre el IDE y veras
Rouge en Sprites y Objects.

Alternativa manual: abre el IDE y arrastra la carpeta `sprites/` y
`objects/` sobre la ventana Resources (importar), NO pegues carpetas a
mano en el disco sin registrarlas en el .yyp — eso es justo lo que rompe
el load.

## NOTAS DE JUEGO
- obj_rouge usa `scr_insert_id("rouge")` y stats estilo survivor:
  spd 4.5, jump 12, planeo manteniendo salto (flyPow 1.4).
- si tu proyecto ya tiene scr_insert_id/obj_solid con otros nombres,
  ajusta esas 3 referencias en Create/Step (son las unicas externas).
- spr_menu_rouge_2 (210x184, 5 frames) es el retrato del menu de seleccion.
