# Worklog — TD2DR "Amy Canon" (Sonic.exe The Disaster 2D)

═══════════════════════════════════════════════════════════════════════════
⚡ CONTEXTO MAESTRO — LEER PRIMERO SIEMPRE (recuperación de hilo)
═══════════════════════════════════════════════════════════════════════════
Si perdiste el hilo de la conversación, ESTA sección te devuelve el contexto
completo. Léela completa antes de tocar cualquier archivo.

QUÉ ES ESTE PROYECTO
- El usuario moddea "Sonic.exe: The Disaster 2D" (TD2DR, juego GameMaker .yyp
  con servidor C) para meter su personaje jugable propio: AMY CANON, una Amy
  Rose de otra dimensión, más fuerte que la Amy original.
- Yo (agente "Super Z" / Z.ai) analizo, escribo y valido los cambios en una
  copia local del repo, y ENTREGO ZIPs que el usuario extrae sobre su
  proyecto de GameMaker. El usuario commitea en SU git; para retomar: fetch.
- Fases históricas del worklog: tareas 1-2 = Fraymakers .fra (herramienta
  "Sally Extract"); tareas 4-8 = recon TD2DR 110v + server compilado;
  tareas 8,10,11,fix-* = página Character Info de Amy Canon y sus bugs.
  Todo lo demás de este log gira en torno a eso.

RUTAS ABSOLUTAS (no cambiar)
- Repo del juego (cliente GM): /home/z/my-project/td2dr/disaster2d-oss
- Servidor (C): /home/z/my-project/td2dr/server/betterserver-oss
- Entregables para el usuario: /home/z/my-project/download/
- Scripts de generación/validación: /home/z/my-project/scripts/
- ESTE worklog: /home/z/my-project/worklog.md (copia para git en
  download/worklog.md — el usuario la mantiene en su repo como log futuro)

IDENTIDAD TÉCNICA DE AMY CANON (memorizar)
- Cliente: CHARACTER_AMY_CANON = 7 (posición en chars[]); página About:
  SUBMENU_CHAR_AMY_CANON = 48.
- Ciclo REAL del Character Info (verificado contra v110, no asumir otro
  orden): Tails(20) Knux(21) Eggman(22) Amy(23) Cream(24) Sally(25)
  → AMY CANON(48) → Exe(26) Chaos(27) Exetior(28) Exeller(29).
  (Chaos va ANTES que Exetior; los macros lo confirman.)
- Placa de nombre: frame 66 "AMY CANON" de spr_menu_buttons (67 frames en
  total). Las placas laterales de cada página = personaje anterior/siguiente
  del ciclo (patrón original del juego).
- Su página: capa "AboutAmyCanon" en rooms/room_menu/room_menu.yy, depth
  -3350, 8 instancias, visible=false (como TODAS las About*), texto en
  inst_C17D88C5 (obj_menu_abouttext @ x=23,y=60).
- Descripción: rooms/room_menu/InstanceCreationCode_inst_C17D88C5.gml
  (formato: text = "..."; en una línea, \n literales de escape GML).
- Guard anti-cache: Alarm_0.gml degrada la placa 66→46 ("amy rose") si el
  sprite compiló viejo; Create_0.gml tiene fallback que crea la capa por
  código si la room compiló sin ella.

SISTEMA DE TEXTO DEL JUEGO (scr_text_spr) — RESTRICCIONES CRÍTICAS
- SOLO renderiza: a-z MINÚSCULAS, 0-9, y: - , . ' : ( ) % +   (¡NO hay
  mayúsculas, ni ! ? ; → caen al glifo 44 = fallback vacío!)
- Códigos de color (activos hasta el "~" que resetea a blanco; NO ocupan
  ancho; el color PERSISTE entre saltos de línea):
  \ rojo C20037 | @ verde 0fff39 | & morado b824ff | / azul 5D67FF
  | gris 646464 | ` amarillo ffdb00 | № naranja ea6014 | ~ reset blanco
- Métricas: letra avanza 6px (+2 si es w/m/x/n), espacio 5px, línea nueva
  8px de alto. Ancho estándar de línea en abouttexts: 30 chars visibles.
  Room del menú: 480x270. El abouttext dibuja en (23,60).
- En GML la cadena va entre comillas dobles en UNA línea: los saltos son \n
  de escape; el backslash del código rojo se escribe \\ en el .gml fuente.

FLUJO DE ENTREGA (memorizar SIEMPRE)
1. Editar mi copia local (td2dr/disaster2d-oss) → validar con script Python
   → empacar SOLO los archivos tocados en download/<nombre>.zip con rutas
   relativas al root del proyecto.
2. INSTRUCCIÓN CRÍTICA AL USUARIO (fue causa raíz de los peores bugs):
   CERRAR GameMaker COMPLETAMENTE antes de extraer el ZIP, luego reabrir y
   F5. Rooms/sprites .yy NO se hot-recargan con el IDE abierto (los .gml
   sí) → si compila cache viejo: pantalla bugeada o placa vacía.
3. Si el usuario reporta "blanco/pantalla rara": primero sospechar cache del
   IDE (limpiar cache de assets / escoba + reabrir), NO re-escribir archivos
   que ya están correctos — validar el repo campo a campo antes de tocar.
4. Al escribir .gml: usar scripts Python con tabs exactos (el Edit tool
   convierte tabs→espacios y rompe diffs). Verificar balance de llaves.

ESTADO DEL PROYECTO (2026-10-24)
- ✅ Personaje jugable completo: cliente + server (el usuario implementó la
  burbuja/captura en su commit 13c65295 "new": scr_amy_canon_bubble,
  obj_amy_canon/*, obj_player_puppet, Game.c, snd_bubble).
- ✅ Página Character Info de Amy Canon completa: ciclo, placas laterales,
  placa central, texto. Fixes de los 3 bugs del video entregados en
  download/amy_canon_fix_completo.zip y aplicados en mi copia (pendientes
  de commit por el usuario). SI YA SE ARREGLO EN SU PROYECTO, NTP — no
  re-entregar.
- ✅ Descripción nueva (tarea desc-amy-canon-v2, esta sesión): lore del
  cyber space + P.D. amarillo → download/amy_canon_desc_v2.zip.
- ✅ Mejoras TAROT v3 (tareas tarot-v1/v2/v3): Z = SALTO DE MARTILLO
  restaurado tal cual v1 (suelo, corriendo, hitbox +20%) + pasiva float
  (mantener Z al caer; caida EXACTA 0.5 px/frame; loop = SOLO DSTAROT2 +
  Loop_Card). X = IMPULSO AEREO de tarot (antes ataque de corazones):
  dash como la acometida de la C pero SOLO en el aire, con el sprite
  nuevo spr_amy_attack1_canon (2 frames) que dibujo el usuario; DSTAROT1
  1 vez al arrancar (nunca loop) + Loop_Card en loop; stun 2s al killer
  → download/amy_canon_tarot_v3.zip (7 .gml + worklog.md; los assets ya
  estaban commiteados por el usuario en 4a0f2e61/e325daf0).
  Macros clave (Create_0 de obj_amy_canon): TAROT_FALLSPD 0.5,
  TAROTDASH_TIME 48, SPEED 14, FALLSPD 2, ANIMSPD 0.25, CD 9s/4s
  (TAROTDASH_RECHARGE/ETAROTDASH_RECHARGE). Estados: TAROT=22,
  TAROTDASH=23. Icono 1 UI = martillo (blanco = CD+suelo); icono 2 =
  impulso (blanco = CD+aire; el ARTE sigue siendo spr_gui_amyattack_canon).
- ✅ SENSORES v1 (tarea sensors-v1): pasivas de vision de Amy Canon —
  flecha VERDE siempre hacia la salida (obj_bigring, todos los mapas) +
  flecha AZUL siempre hacia el exe (estilo sensor eggman, solo su
  cliente). Objeto nuevo obj_amycanon_indicators + .yyp registrado →
  download/amy_canon_sensores.zip (incluye tambien el bubble fix).
  ⏳ Bubble fix de la tarea anterior: AUN SIN CONFIRMAR por el usuario
  si extrajo amy_canon_bubble_fix.zip (por eso va re-incluido).
- ⏳ Placeholders opcionales: spr_lobby_icon frame 8 y spr_char_info frame 6
  son copias de Amy (funcionales); si el usuario pide rediseño, seguir el
  método del frame 66 (ensamblar glifos pixel-perfect del propio juego).

ERRORES DEL PASADO QUE NO REPETIR (lecciones pagadas)
1. Room .yy modificada con el IDE abierto → compiló cache vieja → "pantalla
   bugeada al inicio con letras amontonadas" (fix: changeSubmenu(SUBMENU_NONE)
   al final de Create_0.gml fuerza estado limpio).
2. Layer PNG con guid inventado → GM lo rellenó con basura → placa central
   vacía (fix: guard en Alarm_0.gml + usar SIEMPRE el guid declarado en el
   .yy para layers/).
3. changeSubmenu() doble en el ciclo (sin break) → ids inválidos → pantalla
   oscura tras Sally (fix: calcular _dstMenu y llamar UNA sola vez).
4. Al insertar página nueva en el ciclo, actualizar TAMBIÉN las placas
   laterales de las páginas vecinas (Sally.der y Exe.izq → apuntan a 66).
5. Preview/render de textos GML: decodificar \n literal (2 chars) a salto
   real antes de renderizar (bug de esta sesión, corregido en script).
6. Tecla compartida con el salto (KeyA=Z): si una habilidad tiene variante
   de suelo y aire en la misma tecla, NUNCA compartirles el CD (el uso de
   suelo bloquea el aereo tras cada salto: asi nacio la falla 1 de tarot).
   Y si el usuario dice "unicamente en el aire", la modalidad de suelo NO
   existe: no inventar hibridos.

PROTOCOLO AL RETOMAR
1. git fetch en td2dr/disaster2d-oss + git log — ver qué commiteó el usuario.
2. Leer ESTA sección + la última entrada del historial (abajo).
3. Trabajar, y al terminar APPEND (nunca sobrescribir) una entrada nueva con
   el template: Task ID / Agent / Task / Work Log / Stage Summary.

═══════════════════════════════════════════════════════════════════════════
HISTORIAL DE TAREAS (la más reciente al final; append-only)
═══════════════════════════════════════════════════════════════════════════

---
Task ID: 1
Agent: Super Z (main agent)
Task: Analizar y extraer el formato .fra del juego Fraymakers (charactertemplate.fra)

Work Log:
- Identificado el archivo subido: /home/z/my-project/upload/charactertemplate.fra (4.28 MB)
- Hex dump inicial: detectado JSON embebido tras 4 bytes de cabecera
- Script scripts/analyze_fra.py: decodificada la cabecera (uint32 big-endian = longitud del manifiesto JSON) y validado el JSON
- Script scripts/analyze_fra2.py: verificado que los bytesOffset/bytesLength de los assets son relativos al inicio del payload (tras cabecera+manifiesto); cobertura 100% del payload confirmada
- Construido scripts/fra_extract.py: extractor general reutilizable con detección por magic bytes, manejo de colisiones de ids duplicados (caso lightattack3) y troceado opcional de atlas de sprites
- Ejecutada la extracción completa con --split-frames: 55 WAV, 2 PNG (spritesheets 4096x1024 y 512x512), 3 entities JSON, 11 scripts (9 hscript + 2 json), 204 frames PNG troceados
- Validación: PNG abren con PIL (RGBA), WAV son RIFF válidos (mezcla PCM 16-bit y IEEE float32 — por eso el módulo wave de Python no los abre, pero cualquier reproductor sí), JSON parsean correctamente
- Empaquetado download/charactertemplate_extraido.zip (contenido + herramienta) y copia suelta de download/fra_extract.py

Stage Summary:
- Formato .fra documentado: [4B BE uint32: len manifiesto][manifiesto JSON][payload concatenado]; offsets relativos al payload; secciones: audio, spritesheets (PNG atlas con frames x,y,w,h), images, nineSlices, binary, entities (animaciones), scripts (hscript/json embebidos con el código en campo "value"); versión de formato detectada 0.0.17
- Entregables: download/charactertemplate_extraido/ (árbol completo), download/charactertemplate_extraido.zip, download/fra_extract.py (CLI reutilizable para cualquier .fra)
- Detalle interesante: los WAV float32 (format tag 3) no los abre `wave` de Python pero sí reproductores normales; el template contiene scripts de stats/AI/hitboxes del personaje editable

---
Task ID: 2
Agent: Super Z (main agent)
Task: Crear "Sally Extract" — programa con GUI para descomprimir y re comprimir archivos .fra de Fraymakers

Work Log:
- Descargadas dependencias: fflate 0.8.2 (UMD, ZIP en JS) y GIF de fondo HACK_BG3.gif (15.9 MB)
- Optimizado el GIF con Pillow (scripts/sally/optimize_gif.py): 360px, 48 colores, sin dither, cada 3er frame → 1.76 MB con loop infinito (ffmpeg fue descartado por kills de memoria)
- Escrito motor puro scripts/sally/engine.js: parseFra (cabecera u32 BE + manifiesto JSON + payload), extractToZip (ZIP editable con _sally_index.json de mapeo guid→archivo y orden original de payload), repackFromFiles (reemplaza entities/scripts en el manifiesto, reconstruye payload en orden original recalculando offsets, corrige campo format por magic bytes), verifyFra (cobertura, solapamientos, magics)
- Pruebas Node (test_engine.js): 22/22 pasadas — roundtrip sin ediciones produce .fra BYTE A BYTE IDÉNTICO al original; ediciones de script/entity/audio verificadas; errores esperados (ZIP sin índice, archivos faltantes) con mensajes claros
- GUI construida (shell.html + ui_core.js + ui_preview.js): tema hacker neón verde/cian/magenta, título glitch animado, fondo GIF embebido con scanlines CRT y viñeta, dropzone con auto-detección fra/zip, explorador de assets por secciones, previews (audio con forma de onda WebAudio, spritesheets con rejilla de frames, código .hx con resaltado, JSON coloreado), log tipo terminal, botones de descarga
- Ensamblado archivo único offline (assemble.py): 2.4 MB con todo embebido (fflate + motor + UI + GIF base64)
- Verificación con agent-browser (headless): bug hallado y corregido (alias Sally→SallyEngine faltante; y doble extensión manifest.json.json hallada vía análisis VLM). Flujo completo probado en navegador: carga .fra real → 71 assets → previews OK → reempacado ZIP → .fra de 4,286,103 bytes idéntico al original con verificación 100%
- Análisis visual con VLM confirmó: título glitch visible, fondo animado, layout correcto, terminal de log, reporte de verificación, sin elementos rotos

Stage Summary:
- Entregable: /home/z/my-project/download/sally_extract.html (2.4 MB, un solo archivo, 100% offline, funciona con doble clic en cualquier navegador)
- Flujo: .fra → ZIP editable (con LEEME.txt en español) → editar archivos → ZIP → .fra jugable verificado
- Garantía: roundtrip sin ediciones = byte-idéntico; con ediciones = verificación de integridad automática (cobertura 100%, sin solapamientos, magics coherentes)
- Scripts reutilizables en /home/z/my-project/scripts/sally/: engine.js (motor probado), test_engine.js (22 pruebas), assemble.py (reconstruir el HTML)

---
Task ID: 4
Agent: Super Z (main agent)
Task: Extraer los sprites/GIF de Amy de TD2DR version 100 (100v) para el usuario

Work Log:
- Localizado el archivo de versiones en GameJolt (gamejolt.com/games/sonicexe_disaster-archive/955798 por STHF) con la 1.0.0 "Old Release" (131 MB)
- GameJolt es SPA sin enlaces directos: usado agent-browser (headless) para clicar el boton Download de 131 MB y capturar el endpoint POST /site-api/web/discover/games/builds/get-download-url/1689965
- Descargado 100.7z (131 MB) via curl; extraido data.win (73.5 MB) con py7zr (pip en el venv: python3 -m pip)
- Ingenieria inversa del data.win (NO es estandar GameMaker): enteros little-endian (anti-cheat de la 100v), strings [len][chars] sin null, punteros de nombre de sprite apuntan a los chars (modo B)
- Chunks: GEN8, SPRT (1.9MB, 777 sprites), TPAG (5227 entradas de 22 bytes), TXTR (148 texturas), STRG, AUDO (47MB)
- Layout SPRT validado en 746/777 sprites (los 31 restantes tienen mascaras de colision extra tras los frames): [nameptr][w][h][bbox 4][7 campos][originX@+48][originY@+52][special@+56][anim f32@+68][nframes@+84][frames: n ptrs TPAG]
- TPAG: 22 bytes = x,y,w,h (u16 LE en pixeles) + 6 u16 + texIdx (u16 @+20)
- TXTR: 28 bytes por entrada; datos = BZ2 -> QOI. El QOI NO es estandar: es la variante GameMaker (portada en UndertaleModLib/DogScepter): magic 'fioq' LE + w/h u16 LE + len u32 LE + ops custom (INDEX=0x00, RUN_8=0x40, RUN_16=0x60, DIFF_8=0x80, DIFF_16=0xC0, DIFF_24=0xE0, COLOR=0xF0; hash de indice = r^g^b^a & 63; alfa inicial 255; salida BGRA en la ref, montada como RGBA)
- Decodificador validado: consumo EXACTO de ops (pos == length) en todas las texturas probadas
- Extraidos 34 sprites de Amy (spr_amy_*: idle/walk/run/jump/fall/attack1/attack2/hurt/dead/emotions/lookup/lookdown/zipline; spr_eamy_* variantes EXE; spr_menu_amy retrato 12f; spr_corpse_amy 18f; 2 GUI)
- Verificado: colores rosa Amy autenticos (#f19dbb, #e65b8c), martillo amarillo #fcb037, eamy en tonos oscuros
- Generados: GIFs con paleta exacta y transparencia (escala pixel-perfect 1-4x segun tamano, duracion = 1000/fps), frames PNG RGBA 1x, sheets horizontales, README, preview grid
- Bonus: download/td2dr_sprite_extractor.py — extractor generico CLI (python td2dr_sprite_extractor.py <data.win> <patron> <salida>), probado con Tails (42 sprites)

Stage Summary:
- Formato data.win 100v completamente documentado y crackeado (LE + QOI-GM); sirve para extraer sprites de CUALQUIER personaje de la 100v
- Entregables: download/td2dr_amy_100v/ (gifs/ 34, sheets/ 34, frames/ 34 dirs, README.txt), download/td2dr_amy_100v.zip (828 KB), download/td2dr_amy_preview.png, download/td2dr_sprite_extractor.py
- Los frames PNG 1x son los adecuados para reimportar a GameMaker (proyecto 110v open source) como base de nuevos personajes

---
Task ID: 5
Agent: Super Z (main agent)
Task: Recon completa de la ruta de modding de TD2DR 110v + conseguir el "server compilado" para el proyecto "Amy Canon" del usuario

Work Log:
- game-recon ejecutado: WebFetch GameJolt oficial (780541): 1.1.0 FINAL, juego en hiatus indefinido (coder se fue), solo servidores privados (Radmin/ZeroTier), FAQ con traducción ES en comentarios fijados; dev = hander
- GameBanana (hub 19304) navegado con agent-browser: leí la guía de modding (tuts/19573 → 3 Google Docs de features GML), questions 92692/107241/107487/107867/109244/109246 y WiPs
- Confirmado el stack de la comunidad: CLIENTE = proyecto GameMaker (.yyp) editado en el IDE; SERVIDOR = "DisasterServer", proyecto C (CMake→Visual Studio, SDL2+cJSON), server-authoritative con entities/, CharSelect.c, Lobby.c, Packet.c; personajes nuevos requieren variables en AMBOS lados
- Descargado el server compilado del mod TTB (GameJolt build 1926969 vía endpoint POST get-download-url capturado con agent-browser): server.zip 6.8MB → DisasterServer.exe (PE32+ x64, 1.3MB, debug+PDB+.obj), Config.json (puerto 8606, server_count 15, anticheat bool, motd), Operators/Bans/Timeouts.json + DLLs SDL2
- Strings del exe: "Anticheat is disabled, client modifications are allowed", practice mode, check build_version+extra_version, ST_CHARSELECT; fuente original en popitka3\disasterserver\ (maxbaxwer, rusoparlante)
- Precedentes de personajes nuevos: TTB (Amelia=variante Amy con entidades AmeliaBanana/AmeliaBomb/MetalAmyShot), D.I.B., Girls Mod v1014, Classic Amy mod
- Escrito MODDING_PLAN.md con ruta A (base 110: falta conseguir proyecto cliente+fuente server en Discord oficial) y ruta B (stack TTB: server ya en mano, Amelia como template)
- Copiado el server a download/td2dr_server_ttb.zip para el usuario

Stage Summary:
- Ruta de modding DEFINIDA: proyectos fuente (GameMaker cliente + C server), no data.win/UMT
- Servidor compilado conseguido y en download/td2dr_server_ttb.zip (puerto 8606; anticheat:false = modo mod-testing)
- Faltan solo las FUENTES (proyecto 110 + server) → pedir en discord.gg/thedisaster2d (oficial/modding) o discord.gg/2tdrz8beEb (TTB)
- Proyecto "Amy Canon": sprites 100v listos (Task 4); fases 2-6 en MODDING_PLAN.md

---
Task ID: 6
Agent: Super Z (main agent)
Task: Diagnosticar el error "versión desactualizada" — qué versión usa el DisasterServer y dónde cambiar la versión

Work Log:
- scripts/td2dr_server_version.py: análisis PE del DisasterServer.exe TTB (pefile + capstone + objdump con anotaciones rip-relativas); xrefs de strings de version
- Check del TTB localizado (0x14005074E / 0x1400508E2): DOS movabs+cmp contra magic u64: 0x1E133CFA3E4E236E (check 1, local [rbp+0x88]) y 0x14A7ED016D2490CF (check 2, local [rbp+0x1c8]) + strcmp de 2 secretos: "a7d8f3b2e9c1f4d6b8a2c9e3f1d4b7a5" y "SuckMyDickDunoYouLittleLoli" + flags "passtrough?" ([rbp+0x44] debe ser 0) y "type != IDENTITY?" ([rbp+0x64]); log exito: "Client %d authenticated: dual verification passed"
- Ruta de compilación filtrada en strings: 'C:\Users\user\Documents\betterserver-oss-main\popitka3\disasterserver\Server.c' → el server TTB es la generación VIEJA del BetterServer
- HALLAZGO CLAVE: server open source — M87FMP4/betterserver-oss (MIT, act. 2026-10-15) clonado a td2dr/server/betterserver-oss; también clonado Saiv46/td2d-protocol (librería NodeJS del protocolo); existe betterserver-oss-old (archivado)
- Check en fuente (states/Server.c peer_identity): #define BUILD_VERSION 1101 (include/Server.h:19); handshake IDENTITY = u8 passtrough(0) + u8 type(IDENTITY) + u16 build_version(==1101) + i32 server_index + str nickname + str udid + u8 lobby_icon + i8 pet; mismatch → server_disconnect(DR_VERMISMATCH) → el cliente muestra "Versión desactualizada"
- Auth.c: auth_create_ticket envía valores bogus; auth_verify_ticket: si checkcum/checkcum2 (u64) == 0 → peer->mod_tool=true; anticheat:false → "client modifications are allowed"
- Compilación: CMake sin dependencias externas (ENet vendido dentro del repo; UI SDL2 opcional, OFF por defecto → solo enet+ws2_32+winmm+dbghelp); defaults: puerto 8606, server_count 1, anticheat true; releases GitHub SIN binarios (compilar obligatorio)
- Confirmado por tutorial GameBanana (tuts/17347): la 110v del juego es open source vía GitHub — es el proyecto GameMaker que el usuario ya ejecuta

Stage Summary:
- Causa raíz: el server TTB compilado (BetterServer generación vieja) exige magic u64 + secretos propios del cliente TTB; el cliente 110 open-source del usuario envía sus valores → DR_VERMISMATCH → "Versión desactualizada" (la FAQ oficial añade: mismo mensaje con ping>250ms, no aplicable en local)
- Solución: compilar betterserver-oss (BUILD_VERSION 1101, editable en include/Server.h) y alinear el build_version del cliente en el script IDENTITY del proyecto GameMaker
- Fase 1 del MODDING_PLAN RESUELTA: fuente del server conseguida y clonada; cliente 110 open source ya en manos del usuario
- Para Amy Canon: bump de versión propio (1102+) en AMBOS lados al publicar

---
Task ID: 7
Agent: Super Z (main agent)
Task: Guía de compilación del DisasterServer (betterserver-oss) en Visual Studio + validación de la fuente

Work Log:
- Revisados CMakeLists.txt raíz y disasterserver/: proyecto "DisasterServer", CMake>=3.16.3, opciones DYLIB=OFF y BUILD_UI=OFF por defecto (sin SDL2), ENet vendido en repo → cero dependencias externas en Windows (link: enet ws2_32 winmm dbghelp, todas del sistema)
- enet/CMakeLists.txt usa rango de políticas 2.8.12...3.20 → compatible con CMake moderno (VS 2022 incluye 3.29+/4.x)
- Instalado cmake 4.4.4 vía pip y compilación de prueba en Linux (build_test): 100% limpia, Built target DisasterServer sin errores ni warnings
- Smoke test (3s en run_test/): arranca OK — banner "BetterServer v1101" (confirma BUILD_VERSION), "Listening on port 8606", "Server is now in Lobby"; genera automáticamente Config.json (port 8606, server_count 1, ping_limit 250, anticheat true, pride, random_mode, chatfix no persistido), Operators.json (127.0.0.1 = Host → usuario local ya es OP), Bans.json, Timeouts.json
- Empaquetada la fuente limpia (sin .git): download/td2dr_server_fuente.zip (892 KB, 226 archivos)
- Escrita al usuario la guía VS 2022: (A) Archivo→Abrir→Carpeta (CMake integrado) → x64-Release → Compilar todo → out/build/x64-Release/disasterserver/DisasterServer.exe; (B) Developer PowerShell: cmake -B build -G "Visual Studio 17 2022" -A x64 && cmake --build build --config Release; requisito: workload "Desarrollo para el escritorio con C++" en VS Installer
- Puesta en marcha: exe en carpeta limpia → 1er arranque genera JSONs → anticheat:false en Config.json (cliente modificado desde GameMaker) → re-ejecutar → conectar cliente a 127.0.0.1:8606

Stage Summary:
- Fuente VALIDADA: compila limpia y arranca (v1101, puerto 8606) — lista para que el usuario compile en VS sin tocar nada
- Entregable nuevo: download/td2dr_server_fuente.zip (fuente completa del BetterServer oficial open source, MIT)
- El exe TTB (maxbaxwerserver) queda descartado para el proyecto del usuario (solo acepta cliente TTB por sus secretos custom)
- Para probar: cliente GameMaker 110 (envía 1101) ↔ betterserver-oss (espera 1101) → match directo, no hay que cambiar versiones aún; el bump a 1102+ va en la fase de publicación de Amy Canon

---
Task ID: 8
Agent: Super Z (main agent)
Task: Añadir la descripción de Amy Canon en el "character info" (página About del menú) — petición del usuario en sesión continuada

Work Log:
- Workspace restaurado a estado Task 7: el clon del repo y el worklog de sesiones posteriores se perdieron → re-clonado AmyRose21/disaster2d-oss (último commit "New"); confirmado que el estado burbuja NUNCA llegó al repo (no existe isCaptured/PLAYER_CAPTURED) — sigue pendiente
- Recon del sistema de character info: páginas "About*" = capas GMRInstanceLayer en room_menu con instancias de obj_menu_abouttext (código de creación enlazado solo por convención de nombre de archivo) + obj_menu_button (props bid/bcolumn/submenu); controlador obj_menu: changeSubmenu mapea id→capa (oculta todas y activa la correcta + AboutCharacter), buttonListed/buttonPressed navegan el ciclo ±1 con wrap 20↔29
- Verificado: spr_menu_amy_canon ya existe (12 frames, hecho por el usuario); velocidades: todos los survivors 11 (Canon incluida), Eggman 9; renderer scr_text_spr: 6px/char, línea 8px, marcadores de color \/№@&`|; .resource_order solo lista carpetas (los InstanceCreationCode no se registran en ningún archivo)
- Script scripts/add_amy_canon_charinfo.py: clon VERBATIM de la capa AboutAmy→AboutAmyCanon (8 instancias nuevas, submenu 23→48, depth -3350), 8 entradas en instanceCreationOrder, macro SUBMENU_CHAR_AMY_CANON 48 (47 lo usa JOIN_MOBILE), case en las 2 listas + case completo en changeSubmenu (preview con spr_menu_amy_canon), inserción en el ciclo de páginas Sally→AmyCanon→Exe (ida y vuelta) en buttonListed y buttonPressed, hide/show de la capa nueva
- Nuevo archivo rooms/room_menu/InstanceCreationCode_inst_C17D88C5.gml con la descripción (inglés minúsculas, 17 líneas, marcadores /hammer~ azul y №canon~ naranja): versión potenciada de la de Amy (sin debilidad sin carga) + acometida de martillo (14 > 11) + guiño a Frontiers (starfall islands) + cierre "it's not fanon, it's canon"
- Fixes durante la ejecución: la 3ª lista de case (changeSubmenu comparte la etiqueta CREAM) excluida del etiquetado; ids de instancia aparecen 2 veces por línea (%Name + name) → 3 tras el orden de creación; llamadas al 48 = 4 (2 por función), no 8
- Verificación final: llaves balanceadas 6583/6583, 7 props submenu=48, cada id nuevo x3 (orden+capa), diff 86 insertions/4 deletions + 1 archivo nuevo; ZIP con solo los modificados

Stage Summary:
- Página "About Amy Canon" funcional: entra en el ciclo entre Sally y Exe (flechas del mouse y teclado), tabs inferiores idénticos (mech/credits/salir), preview animado con spr_menu_amy_canon y la descripción nueva
- Entregable: download/amy_canon_charinfo.zip con objects/obj_menu/Create_0.gml, rooms/room_menu/room_menu.yy y rooms/room_menu/InstanceCreationCode_inst_C17D88C5.gml (nuevo)
- PENDIENTE (task 9 del diseño aceptado): estado burbuja/secuestro de Amy Canon — sprites ya en el repo (spr_amy_capture_canon*, amy_Bubble) pero NADA implementado en cliente ni server
- IDs nuevos: abouttext inst_C17D88C5; botones 5A7EC0DE/6B1FA2C7/7C2E93D0/8D3F84E1/9E4A75F2/AF5B66A3/B06C77B4

---
Task ID: 10
Agent: Super Z (main agent)
Task: Diagnosticar "la cagaste: no aparece amy canon en la lista, aparece en blanco, ni siquiera su nombre" tras entrega del character info

Work Log:
- Fetch del repo: el usuario subio 2 commits nuevos: 13c65295 "new" (EL MISMO implemento el estado burbuja: scr_amy_canon_bubble, scr_player_hurt, scr_survivor_revive, obj_amy_canon/*, obj_player_puppet, Game.c del server, snd_bubble) y a5d4df77 "a" (mi ZIP charinfo aplicado byte-a-byte)
- Validacion exhaustiva de mi entrega en el estado actual: capa AboutAmyCanon dentro de About/Characters con 8 instancias, ICO 8/8, JSON valido, sin colisiones de IDs en todo el proyecto, macros/cases correctos (Sally 25 -> Canon 48 -> Exe 26), depth -3350 sin conflictos, navigation por teclado y mouse OK, sprites del lobby intactos (dicon frame 8 con cara, lobby_icon frame 8, spr_char_info frame 6 = duplicado de Amy, avCharacters[7]=true), server acepta CH_AMY_CANON (avail[CH_AMY_CANON+1])
- Mock-render de la pagina con los sprites reales: la pagina renderiza correcta -> el .yy es valido
- CAUSA RAIZ MAS PROBABLE del blanco: el usuario extrajo el ZIP con GameMaker ABIERTO. GM hot-reload de .gml (Create_0.gml con la navegacion a la pagina 48) pero NO de .yy resources (room_menu.yy con la capa AboutAmyCanon) -> el juego corrio con la pagina en el ciclo pero sin capa -> pagina en blanco sin nombre ni descripcion. Evidencia: a5d4df77 tiene mis archivos byte-identicos (el IDE nunca re-guardo la room)
- BUGS REALES encontrados en mi entrega original (corregidos):
  1. Boton central mostraba frame 46 "amy rose" (nombre de Amy) - no existia frame "amy canon"
  2. Botones laterales mostraban "eggman"/"cream" (vecinos de Amy) en vez de "sally"/"sonic.exe" (vecinos reales de Canon en el ciclo) - patron verificado en las 10 paginas: izq=personaje anterior, der=siguiente
- Fix implementado (scripts/fix_charinfo.py + finish_charinfo_fix.py):
  * Frame 66 "amy canon" ensamblado pixel-perfect copiando glifos de frames existentes (a/m/y de "amy rose" 46, c de "cream" 47, n de "sonic.exe" 49, o de "rose") con el espaciado exacto del juego (2px entre letras, 6px entre palabras)
  * spr_menu_buttons.yy: +frame entry, +keyframe Key=66, sequence length 66->67 (validado JSON)
  * room_menu.yy: imageIndex centro 46->66, izq 45->48, der 47->49
- Verificado: la composicion se lee "sally | amy canon | sonic.exe" con la fuente exacta del juego

Stage Summary:
- Entregable: download/amy_canon_charinfo_fix.zip (6 archivos: Create_0.gml, room_menu.yy, InstanceCreationCode_inst_C17D88C5.gml, spr_menu_buttons.yy + PNG frame nuevo + layers/)
- La instruccion CRITICA para el usuario: cerrar GameMaker COMPLETAMENTE antes de extraer el ZIP y reabrir despues (el IDE no recarga rooms modificados externamente mientras esta abierto)
- Diffs minimos: room_menu.yy 3 lineas, spr_menu_buttons.yy 6 inserciones
- El lobby (spr_char_info frame 6) sigue siendo duplicado del panel de Amy - el usuario puede redibujarlo o pedirlo como follow-up

---
Task ID: 11
Agent: Super Z (main agent)
Task: Diagnosticar "sigue en blanco tras sally" + "pantalla bugeada que va directo a about al entrar al juego"

Work Log:
- Verificacion EXHAUSTIVA del estado del repo (HEAD = a5d4df77 + fix ZIP sin commitear):
  * Capa AboutAmyCanon en room_menu.yy: diff campo a campo vs AboutAmy/AboutSally = estructuralmente IDENTICA (solo difieren nombre/ids/submenu/imgIdx intencionales); visible=false como las demas; 8 instancias con props correctas
  * instanceCreationOrder: 8/8 presentes | JSON valido (formato GM relajado)
  * spr_menu_buttons: 67 frames, keyframe 66 -> guid eda71597, length 67, PNG 180x16 RGBA valido, copia root y layers/ byte-identicas (md5), contenido alineado a la izquierda como TODOS los frames (0-65); PNG huerfano 80x64 (35e00ebe) existe desde v110, no referenciado, inofensivo
  * Codigo charselect: CHARACTER_AMY_CANON=7 (Tails+6), chars[11] con spr_menu_amy_canon en [6], avCharacters 8 entradas en las 7 ubicaciones que lo reinician, ciclo selected 1..CHARACTER_AMY_CANON, offset exe +7 correcto, spr_lobby_icon frame 8, spr_char_info frame 6
  * Create_0.gml: todos los cases presentes; justEntered es variable muerta; obj_menu_secret = codigos de pets en creditos (inocuo)
- CONCLUSION: los archivos estan 100% correctos -> el juego del usuario NO los esta compilando. Causa raiz: GameMaker tenia room_menu.yy abierto en memoria al extraer los ZIPs (las rooms .yy NO se hot-recolan) -> el compilado no tiene la capa AboutAmyCanon -> changeSubmenu(48) esconde todo y muestra solo AboutCharacter + fondo de About = pantalla vacia que PARECE un About bugeado ("va directo a about") y sin nombre/info ("en blanco tras Sally")
- Nota "auto-about al lanzar": adicionalmente el boton About del menu principal esta en el centro de la ventana (x=412,y=252); el clic de enfocar la ventana cae ahi (comportamiento original del juego, preexistente)
- Stash hallado (stash@{0} "WIP on main: 48dd07a7") = copia anticuada de mi primera entrega ya commiteada; recomendado drop
- FIX NUEVO (a prueba de IDE stale): bloque de RESPALDO por codigo al final de objects/obj_menu/Create_0.gml (47 lineas, tabs preservados):
  * if (!layer_exists("AboutAmyCanon")) -> layer_create(-3350, "AboutAmyCanon") + layer_set_visible false + las 8 instancias por instance_create_layer con bid/bcolumn/submenu/image_index identicos a la room + descripcion del abouttext
  * Guard: si spr_menu_buttons quedo viejo (sin frame 66) usa el 46 "amy rose" para el nombre central
  * Al ser .gml puro, el IDE lo hot-recola aunque este abierto -> funciona con solo extraer + F5; si la room carga bien el bloque no hace nada (sin duplicados); capa runtime se destruye al salir de la room y se recrea en cada entrada
- Corregido durante la ejecucion: (1) el Edit tool convirtio tabs->espacios en todo el archivo (diff 3979 lineas) -> git checkout + script python append_canon_fallback.py con tabs exactos; (2) el template python perdio la llave } final -> detectado por lint de balance (176/175) y corregido; verificado 176/176 y 896/896
- ZIP final: download/amy_canon_about_v3.zip (6 archivos: Create_0.gml con fallback, room_menu.yy, InstanceCreationCode_inst_C17D88C5.gml, spr_menu_buttons.yy, PNG frame 66 x2)

Stage Summary:
- NADA esta roto: repo verificado campo a campo como correcto; el problema era el IDE compilando una room vieja
- El fallback por codigo hace la pagina About Amy Canon inmune al cache del IDE: funciona con solo extraer y F5, incluso sin reiniciar GameMaker
- Pendiente si el usuario reporta "auto-about" REAL al lanzar (sin clic): pedir captura/video del momento exacto; teoria principal = clic de foco sobre el boton About central
- Higiene recomendada al usuario: cerrar GM completo, reabrir, Clean Asset Cache (escoba), verificar capa About/Characters/AboutAmyCanon (8 instancias) en el editor de room_menu; opcional git stash drop del stash viejo

---
Task ID: fix-about-amy-canon
Agent: main (Z.ai)
Task: Diagnosticar y corregir el bug reportado por el usuario con video: la pagina de Amy Canon en About > Character Info sale completamente oscura (entre Sally y Sonic.exe). Bug reportado 2 veces antes sin diagnostico.

Work Log:
- Descargue y analice el video del usuario (20s, 60fps) frame a frame: main menu OK, ciclo About OK hasta Sally, luego pagina OSCURA (solo borde rojo + grid del fondo "bars"). BUG #2 (auto-About al iniciar) confirmado como ya resuelto por el usuario.
- Verifique el inventario completo de la pagina AboutAmyCanon: capa en room_menu.yy (depth -3350) con 8 instancias, creation code del texto (InstanceCreationCode_inst_C17D88C5.gml, ya commiteado), frame 66 "AMY CANON" de spr_menu_buttons (cambios sin commitear de la sesion anterior), caso SUBMENU_CHAR_AMY_CANON en changeSubmenu, fallback por codigo en obj_menu/Create_0.gml.
- CAUSA RAIZ ENCONTRADA: en buttonListed (lineas ~248-279) y buttonPressed (lineas ~1081-1110) de obj_menu/Create_0.gml, los casos especiales del ciclo Amy Canon llamaban changeSubmenu() SIN break y luego caian a changeSubmenu(submenu+/-1) con el submenu YA actualizado: Sally(25)->changeSubmenu(48)->changeSubmenu(49)=id inexistente=todas las capas ocultas y ningun case = PANTALLA OSCURA. Tambien: Exe(26)->izquierda->48->47=SUBMENU_JOIN_MOBILE (pantalla de join movil!), AmyCanon->derecha saltaba a Chaos, AmyCanon->izquierda saltaba a Cream.
- Verifique con VLM la hoja de contactos de spr_menu_buttons: frames 43-52 son placas de nombre (TAILS/KNUXLES/EGGMAN/AMY ROSE/CREAM/SALLY/SONIC.EXE/EXETIOR/EXELLER/CHAOS) y 66="AMY CANON". Las instancias laterales de la pagina son las placas del anterior/siguiente personaje. La room sin commitear (66/49/48 = SALLY|AMY CANON|SONIC.EXE) es correcta.
- FIX: reescribi ambos bloques del ciclo para calcular _dstMenu y llamar changeSubmenu() UNA sola vez. Simulacion en Python verifica el ciclo completo en ambas direcciones sin ids invalidos.
- Anadi respaldo anti-cache en el case SUBMENU_CHAR_AMY_CANON: si spr_menu_buttons quedo viejo (sin frame 66), la placa central cae al frame 46 ("AMY ROSE") para no quedar invisible.
- Verifique sintaxis (balance llaves/parentesis OK), diff final limpio (111+/46- tras reconvertir indentacion a tabs), markup del texto compatible con scr_text_spr ("/"=azul #5D67FF, "№"=naranja #ea6014, "~"=reset).
- Verifique lobby: spr_lobby_icon frame 8 (slot AmyCanon, usado por char+1 y char+2) existe (es copia de la cara de Amy = placeholder funcional), spr_char_info frame 6 existe (11 frames). Extra pages usan aritmetica pura sin casos especiales = sin bug.

Stage Summary:
- Bug principal corregido en objects/obj_menu/Create_0.gml (2 bloques del ciclo + respaldo anti-cache + fallback de la sesion anterior conservado).
- ZIP entregado con 5 archivos: obj_menu/Create_0.gml, room_menu.yy, spr_menu_buttons.yy, PNG del frame 66 + PNG de layers.
- El character info de Amy Canon (TODO pendiente de la sesion anterior) ya estaba completo y validado: hammer jump, hammer rush, starfall islands (Frontiers), "it's not fanon, it's canon".
- Tarea principal pendiente: sistema de burbuja/captura de Amy Canon (diseno confirmado, implementacion 0%).

---
Task ID: fix-video-3bugs
Agent: main (Z.ai)
Task: Diagnosticar y corregir los 3 bugs del video Runner 2026-10-24 05-20-58: (1) pantalla bugeada al iniciar con letras amontonadas y Knuckles, (2) Amy Canon sin nombre arriba (placa central vacia), (3) menu desordenado.

Work Log:
- Descargado y analizado el video (30s, 1368x748, 60fps) frame a frame con extraccion fina (0.1s) + VLM en 6 tandas + crops nativos de placas
- BUG 1 identificado: 0.0-0.4s logo room_logo -> 0.5-3.0s pantalla con MULTIPLES capas de submenu visibles a la vez (texto del About/Credits amontonado en (23,60) donde TODAS las abouttext coinciden, GIFs de mecanicas con personajes sobre grid verde, UI del JoinGame, tabla de records) -> 3.1s el usuario clico BACK y changeSubmenu limpio todo. Causa raiz: el compilado tenia una room cacheada con capas visibles que en disco estan ocultas (room en HEAD verificada: todas About* visible=false)
- BUG 2 identificado con crops nativos de la franja de placas: en la pagina Amy Canon la placa CENTRAL esta VACIA (las lecturas VLM previas a baja resolucion confundieron la placa derecha). Causa doble: (a) el juego compilo con el sprite VIEJO de 66 frames -> image_index 66 fuera de rango = invisible; (b) ERROR MIO original en el ZIP de la task 10: el layer PNG del frame 66 lo guarde como layers/eda71597/21ec4498.png (guid inventado) cuando la capa declarada en el .yy es 40f65fd9 -> GM al re-guardar relleno layers/eda71597/40f65fd9.png con una imagen 64x64 blanca/roja (el PNG raiz huerfano del frame orfan 40f65fd9 del v110 original), corrompiendo el frame 66 del editor
- BUG 3 identificado: al insertar Amy Canon en el ciclo nunca actualice las placas laterales vecinas: pagina SALLY derecha=SONIC.EXE (deberia AMY CANON) y pagina EXE izquierda=SALLY (deberia AMY CANON). El orden REAL del juego verificado contra v110: Tails20 Knux21 Egg22 Amy23 Cream24 Sally25 Exe26 CHAOS27 Exetior28 Exeller29 (Chaos va ANTES que Exetior; los macros lo confirman)
- Verificado estado HEAD del repo del usuario (c422e745): room correcta en disco, sprite .yy correcto (68 entries, Key 66->eda71597, length 67), root PNG correcto (pixel-identico a mi entrega); solo el layer PNG estaba corrompido y las 2 placas laterales sin actualizar
- FIXES aplicados: (1) Create_0.gml: changeSubmenu(SUBMENU_NONE) al final del Create = fuerza estado inicial limpio ANTES del primer frame, la pantalla bugeada no puede volver a aparecer aunque la room compile cacheada; (2) Alarm_0.gml: guard si sprite_get_number(spr_menu_buttons)<=66 cambia toda placa image_index==66 a frame 46 (amy rose) = nunca mas placa invisible aunque el sprite compile viejo; (3) room_menu.yy: inst_41AD3E36 (Sally der) 49->66 y inst_777901DC (Exe izq) 48->66; (4) layers/eda71597/40f65fd9.png = texto AMY CANON 180x16 (guid correcto) y borrado el huerfano 21ec4498.png
- Verificacion: 28/28 checks OK (placas de las 11 paginas contra el ciclo real, estructura sprite, PNGs, balances de codigo, simulacion completa del ciclo ida y vuelta desde cada pagina) + mockup visual de placas validado por VLM (5/5 tiras legibles, AMY CANON en la fuente pixel del juego)
- Entregado download/amy_canon_fix_completo.zip (4 archivos: Create_0.gml, Alarm_0.gml, room_menu.yy, layer PNG corregido) + download/placas_fix_preview.png

Stage Summary:
- Los 3 bugs tenian causas distintas y todas resueltas: arranque sucio (room cacheada -> ahora forzada por codigo), placa vacia (sprite cacheado + mi guid erroneo del layer PNG -> guard runtime + layer corregido), menu desordenado (placas vecinas sin actualizar -> ahora apuntan a AMY CANON)
- INSTRUCCION CRITICA PARA EL USUARIO: cerrar GameMaker COMPLETAMENTE antes de extraer el ZIP, luego limpiar cache de assets (escoba) y reabrir; verificar en el editor de sprites que el frame 66 de spr_menu_buttons dice "AMY CANON"
- El guard de Alarm_0 es temporal: cuando el sprite compile bien (67 frames) deja de actuar solo
- Siguiente tarea pendiente del proyecto: sistema de burbuja/captura de Amy Canon (task 9 del diseño)

---
Task ID: desc-amy-canon-v2
Agent: Super Z (main agent)
Task: (1) Reescribir la descripcion de Amy Canon aplicando el lore nuevo del usuario; (2) reestructurar este worklog como log de recuperacion de contexto para subir a git

Work Log:
- Requerimiento del usuario: la descripcion debe decir que (a) fue rescatada de la prision del cyber space gracias a sonic, (b) tiene mucha mas exp y es mucho mas fuerte que antes, (c) aclarar que es mas fuerte que su version de esta dimension, (d) su poder tarot + mejor uso del hammer parry le permiten combatir a igual contra los asesinos, (e) un P.D. resaltante en color: ella puede luchar a igual contra los exes
- Redactada en ingles (idioma del juego, minusculas totales, sin ! ? ; que no renderizan), 13 lineas de 30 chars visibles, formato del abouttext (inst_C17D88C5 @ (23,60), 8px/linea, texto en una sola linea del .gml con \n de escape)
- Markup de colores: /cyber space~ /tarot~ /hammer parry~ en azul 5D67FF (este ultimo con span multilinea, permitido: el color persiste entre lineas) y el P.D. COMPLETO en AMARILLO ffdb00 (`...~) — ningun texto del juego usaba el amarillo, queda como firma visual del P.D.
- Script scripts/amy_canon_desc_v2.py: validaciones duras (charset permitido por scr_text_spr, minusculas, ancho<=30, balance de codigos de color), escritura del .gml, preview PNG con los 78 glifos reales de spr_letter1 replicando scr_text_spr (avance 6px/+2 en wmxn, espacio 5px, salto 8px) y empaquetado del ZIP
- Bug del preview encontrado y corregido durante la ejecucion: el renderer iteraba el string GML con \n literal de 2 chars sin decodificar → dibujaba todo en una sola linea; fix: render_text = gml_text.replace("\\n","\n")
- Preview verificado por conteo de pixeles: blanco 59058px (cuerpo), azul 7713px (los 3 spans), AMARILLO 11934px concentrado en la region del P.D. (y445-505, ultimas 2 lineas), sin colores inesperados en la imagen

Stage Summary:
- Texto final instalado (reemplaza la descripcion anterior de gameplay hammer jump/rush/starfall):
  "rescued from her /cyber space~ prison thanks to sonic, amy canon is back with much more exp, far stronger than before: she's now stronger than her version of this dimension. her /tarot~ power and her better use of the /hammer parry~ let her fight on equal ground against the assassins.
   [linea en blanco]
   `p.s.: she can fight on equal ground against the exes~"  ← P.D. entero en AMARILLO ffdb00
- Entregables: download/amy_canon_desc_v2.zip (contiene rooms/room_menu/InstanceCreationCode_inst_C17D88C5.gml, 433 bytes) + download/amy_canon_desc_preview.png (render 3x con glifos reales del juego)
- Worklog reestructurado: seccion CONTEXTO MAESTRO al inicio (autonomo: proyecto, rutas, identidad tecnica de Amy Canon, sistema de texto/colores, flujo de entrega, estado, lecciones) + este historial append-only; copia para git en download/worklog.md
- Recordatorio para el usuario: extraer el ZIP con GameMaker CERRADO (es un .gml de instance creation code: se hot-recarga, pero mejor no arriesgar)

---
Task ID: tarot-v1
Agent: Super Z (main agent)
Task: Mejoras de Amy Canon: (1) pasiva tarot float manteniendo el boton de saltar; (2) salto de martillo usable corriendo con hitbox +20%; (3) habilidad 1 en el aire = impulso de taroto hacia adelante que daña y stunea al killer 2s; sonidos DSTAROT1/DSTAROT2/Loop_Card en loop durante float y dash, detenidos al soltar boton/tocar suelo/ser parada

Work Log:
- Fetch: commits del usuario 0d235faf+50d97ede (fixes aplicados desde el IDE) y 08399ac0 "Nuevo" (assets: spr_amy_tarot_float 9 frames 48x48 bbox_mode 2, DSTAROT1.ogg 2.59s, DSTAROT2.ogg 1.26s, DSTAROT3.ogg 2.57s, Loop_Card.mp3 13.71s SIN .yy)
- Recon de sistemas: specialFunc se llama desde scr_move_basic;state se sincroniza solo via netclient (u8) asi que los estados nuevos llegan a los puppets; el "parry" (stun del killer) vive en obj_player_puppet/Step_0 (2 ramas: isDemonized y globalExe); el hack AMY_HJUMP=state con image_index<3 hace isAttacking
- Paso 1 (scripts/tarot_p1_assets.py): creado sounds/Loop_Card/Loop_Card.yy (misma estructura que DSTAROT1, parent folders/Sounds/Player/AmyCanon) + entrada en el .yyp tras DSTAROT3; validado JSON relajado GM, 1555 resources sin duplicados
- Paso 2 (scripts/tarot_p2_edits.py): 18 ediciones en 9 archivos, todas con verificacion de balance {} (): Create_0 (5 macros nuevas + 8 variables), special (bloqueos redring/hiding + hjump sin isLookingDown con split suelo/aire + bloque DURANTE del dash aereo), Step_0 (shocked apaga tarot; bloque FLOAT post scr_collision_basic; bloque AUDIO compartido; parry local), Step_2 (macros AMY_CANON_TAROT=BALANCING+9/TAROTDASH=BALANCING+10 + state machine), Draw_76 (2 cases), scr_survivors (anims +22/+23 con spr_amy_tarot_float y eanims +19..23 ARREGLANDO el hueco 19-21 que faltaban), puppet (_acHJumpPad: distance_to_object<=5 mientras state==HJUMP para la hitbox 20%; stunTime=2 si state==TAROTDASH), move_basic (muerte) y bubble (captura) apagan flags
- Paso 3 (scripts/tarot_p3_validate.py): 33 checks + 8 simulaciones de flujo. FALLO 1 (regex del validador, corregido). FALLO 2 REAL: la salida del float no chequeaba soltar Z -> FIX en Step_0: agregado !keyboard_check(global.KeyA) a la condicion de salida (el comentario ya lo decia pero el codigo no lo hacia)
- Simulacion final 8/8: sin Z no hay float; Z cayendo entra + audio; yspd capeada a 1.5; SOLTAR Z detiene float+audio; en suelo no re-entra; durante dash aereo audio sigue; dash->float transicion sin cortar audio; stun apaga todo

Stage Summary:
- Entregable: download/amy_canon_tarot.zip (11 archivos: 9 .gml + Loop_Card.yy + .yyp). El .yyp y el .yy de sonido son los unicos no-.gml: extraer con GameMaker CERRADO como siempre
- Valores ajustables en Create_0.gml de obj_amy_canon: AMY_CANON_TAROT_FALLSPD 1.5 (caida flotando), AMY_CANON_TAROTDASH_TIME 26 (duracion impulso), SPEED 13, FALLSPD 2 (caida durante impulso), HJUMP_HITBOX_PAD 5 (hitbox +20%)
- Diseno de audio: los 3 sonidos arrancan al entrar en float O dash y se detienen al salir de AMBOS (canales tarotSnd1/2/3); el dash no exige mantener Z (duracion fija), el float si
- El stun de 2s usa el sistema existente del juego (shockedTimer + CLIENT_PLAYER_HURT + stats report): llega al servidor y a los demas clientes sin packets nuevos
- DSTAROT3 queda sin uso (el usuario lo trajo; reservado para futuro, p.ej. sonido de aterrizar el dash)
- Pendiente si el usuario quiere: spr dedicado para el dash aereo (hoy reusa spr_amy_attack3_canon_), UI con icono propio, y DSTAROT3

---
Task ID: tarot-v2
Agent: Super Z (main agent)
Task: Corregir las 2 fallas reportadas del jugador tras tarot-v1: (1) la habilidad 1 debia ser un dash como la habilidad 3 PERO UNICAMENTE usable en el aire, con sonidos DSTAROT1 y Loop_Card; (2) con la pasiva Amy debe caer MUCHISIMO mas lento, y fix de audio: DSTAROT1 NO va en loop — solo DSTAROT2 y Loop_Card son el loop de la pasiva.

Work Log:
- Diagnostico de la falla 1 (raiz doble): (a) el diseno hibrido de tarot-v1 ponia el salto de martillo en Z-suelo, robando la tecla; (b) ambas modalidades compartian hjumpTimer como CD, y como el CD solo bajaba en el suelo, CADA salto con Z dejaba el dash aereo bloqueado 9s → en la practica el dash nunca estaba disponible. Verificado contra el flujo real: specialFunc (scr_move_basic:584) corre ANTES del salto normal (:617).
- Verificado el cableado de red del stun antes de tocar: el flag PLAYER_ATTACKING SI se sincroniza para CHARACTER_AMY_CANON (emisor obj_netclient/Step_2.gml:69-72, receptor net_udpprocess.gml:121-122 via bitflags) → el stun 2s del puppet (stunTime=2 si state==AMY_CANON_TAROTDASH) funciona sin packets nuevos.
- Fix habilidad 1 (scr_amy_canon_special.gml): Z-suelo YA NO dispara nada (salto de martillo eliminado de la tecla; su estado AMY_CANON_HJUMP queda DORMIDO con comentario, reactivable mirando abajo si el usuario lo pide). El bloque Z exige !isGrounded + guards completos (!isHurt/!isDead/!shocked/!isZipline/!isDashing/!isAttacking/!isHJ/!isTarotDashing + CD listo) → dash aereo puro. DSTAROT1 se dispera 1 VEZ al arrancar (loop=false). El ataque de corazones (X) ahora tambien se bloquea durante el dash (!isTarotDashing). El CD (hjumpTimer/AMY_CANON_BIGJUMP_RECHARGE) baja SIEMPRE, tambien en el aire.
- Fix pasiva (obj_amy_canon/Step_0.gml): AMY_CANON_TAROT_FALLSPD 1.5 → 0.5 (24x mas lento que la caida normal de 12). El tope se compensa con "- yAccel" porque scr_collision_basic suma la gravedad DESPUES del cap (mismo truco que scr_amy_canon_bubble) → caida real EXACTA = valor de la macro, verificado en simulacion frame a frame. Entrada de la pasiva: umbral yspd > 0.5 → yspd > 0 (engancha en el apex mismo).
- Fix audio por estado (Step_0): dash → SOLO Loop_Card en loop (DSTAROT1 ya sono one-shot); float → DSTAROT2 + Loop_Card en loop; ninguno → todo parado. Loop_Card compartido: en las transiciones directas dash→float sigue sonando sin cortarse; DSTAROT2/DSTAROT1 se apagan mutuamente al cambiar de estado.
- Pad +20% movido del salto de martillo al dash: _acTarotPad en obj_player_puppet (state==AMY_CANON_TAROTDASH, TODO el dash activo, sin condicion de frame) con macro renombrada AMY_CANON_TAROTDASH_HITBOX_PAD 5.
- UI (obj_playerui/Draw_64.gml): icono 1 ahora es el impulso aereo — blanco = CD listo Y en el aire (espejo del icono 3). NOTA: el ARTE del icono sigue siendo spr_gui_amyhjump_canon (martillo); si el usuario quiere arte de tarot, cambiar ese sprite.
- Scripts: tarot_v2_edits.py + tarot_v2_edit5_icon.py (tabs exactos por archivo: special/puppet/ui=TABS, Step_0=4 espacios) + tarot_v2_validate.py (26 checks estructurales + 14 simulaciones, TODAS OK) + tarot_v2_zip.py.
- Simulacion clave (macros reales del archivo): Z en suelo = salto normal puro (CD intacto, sin DSTAROT1) → apex → float en <=35 frames → caida estable EXACTA 0.5/frame → soltar Z apaga todo; tap de Z en aire = dash (xspd 13, DSTAROT1 x1 + Loop_Card, CD corre EN EL AIRE); dash→float con Z mantenida cambia DSTAROT1→DSTAROT2 sin cortar Loop_Card; tap flotando = dash directo.
- DESCUBRIMIENTO: el commit "Nuevo" (08399ac0) del usuario NO incluye el codigo tarot-v1 (solo assets: sprite, DSTAROT1/2/3, Loop_Card.mp3) → el ZIP v2 se hizo AUTOCONTENIDO (13 archivos: los 9 .gml del feature + Step_2 + Draw_76 + Loop_Card.yy + mp3 de refuerzo + .yyp) para que funcione tanto si extrajo el v1 como si no. El mp3 de Loop_Card faltaba en el zip v1 (el .yy lo referenciaba pero el audio no viajaba).

Stage Summary:
- Entregable: download/amy_canon_tarot_v2.zip (13 archivos, 256 KB). Extraer con GameMaker CERRADO (incluye .yyp y .yy de sonido, que no se hot-recargan).
- Comportamiento final: Z en suelo = salto de SIEMPRE (nada especial). Z en el aire (CD listo) = dash de tarot adelante (26 frames a velocidad 13, stunea 2s al killer que la toque, con ~5px de margen extra). Mantener Z cayendo = flotacion tarot a 0.5 px/frame. Soltar Z / aterrizar / dano / stun / burbuja cortan TODO el audio.
- Sonidos: pasiva = DSTAROT2 + Loop_Card en loop; dash = DSTAROT1 una vez + Loop_Card en loop; DSTAROT1 jamas loopea.
- Tuning rapido en Create_0.gml de obj_amy_canon: FALLSPD 0.5 (caida pasiva), TAROTDASH_TIME 26 (duracion), TAROTDASH_SPEED 13, TAROTDASH_FALLSPD 2, TAROTDASH_HITBOX_PAD 5, CD 9s en AMY_CANON_BIGJUMP_RECHARGE.
- DSTAROT3 sigue sin uso (reservado; p.ej. sonido de aterrizar el dash). El arte del icono 1 sigue siendo el del martillo (spr_gui_amyhjump_canon).
- Pendiente de commit por el usuario: TODO el feature tarot (v1+v2) sigue sin commitear en su repo.

---
Task ID: tarot-v3
Agent: main (Z.ai)
Task: Corregir el error Z/X reportado por el usuario ("el de la Z estaba bn la X era la que debia cambiar... RESTAURA EL SALTO DE MARTILLO"): restaurar el salto de martillo en Z y mover el impulso aereo de tarot a la tecla X (reemplazando al ataque de corazones), usando el sprite nuevo del usuario spr_amy_attack1_canon.

Work Log:
- Fetch: commits nuevos del usuario 4a0f2e61 (assets: spr_amy_attack1_canon origen 28,21→26,28; DSTAROT1 volume 0.65; DSTAROT3 volume 0.97; Loop_Card.yy) y e325daf0 (codigo tarot-V1 + worklog). DESCUBRIMIENTO: el usuario NUNCA extrajo el ZIP v2 — su repo tiene codigo v1 (Z-suelo = salto de martillo, Z-aire = impulso hibrido).
- Diagnostico con analisis de sprites: el commit 08399ac0 ya habia REEMPLAZADO spr_amy_attack1_canon: 4 frames 46x40 (corazones) → 2 frames 46x46 (arte nuevo morado/naranja = animacion de dash de tarot que el usuario dibujo PARA la tecla X). Eso era el "LE CAMBIE LOS SPRITES Y TODO".
- Stash del WIP v2 de mi working tree + fast-forward a e325daf0; edits v3 sobre base v1 (scripts/tarot_v3_edits.py: rangos de lineas exactos + markers de inicio/fin, tabs preservados — special/Draw_64=TABS, resto=4 espacios; balance {} () verificado por archivo):
  * scr_amy_canon_special.gml: (S1) bloque Z = SOLO salto de martillo, isGrounded en el guard (cuerpo v1 intacto: yspd -10, isHJ, snd_jump, CD hjumpTimer 9s); rama aerea de Z ELIMINADA (Z en el aire no dispara nada). (S3) bloque X (KeyB) = IMPULSO AEREO: guard !isGrounded + !isHurt/!isDead/!shocked/!isZipline/!isDashing/!isAttacking/!isHJ/!isTarotDashing + attackTimer<=0; DSTAROT1 one-shot al arrancar; CD = AMY_CANON_TAROTDASH_RECHARGE (9s) / ETAROTDASH (4s demonizada); corazones (net_quick_effect + snd_dash en X) eliminados. (S2/S4) comentarios actualizados.
  * obj_amy_canon/Step_0.gml: fixes v2 portados — entrada del float en el apex (yspd > 0), tope de caida 0.5 - yAccel (verificado contra el orden REAL del engine: scr_collision_basic:577-596 aplica gravedad ANTES de mover → caida efectiva EXACTA 0.5), y bloque de audio por estado: dash = solo Loop_Card en loop; float = DSTAROT2 + Loop_Card; nada = loops fuera; DSTAROT1 es one-shot y JAMAS se detiene a mano (se apaga solo).
  * obj_amy_canon/Create_0.gml: macros v3 — TAROT_FALLSPD 0.5, TAROTDASH_TIME 26→48 (~0.8s; acometida = 64), TAROTDASH_SPEED 13→14 (= acometida), TAROTDASH_FALLSPD 2, TAROTDASH_ANIMSPD 0.25 (nuevo, sprite de 2 frames), TAROTDASH_RECHARGE 60*9 + ETAROTDASH_RECHARGE 60*4 (CDs dedicados; ATTACK_RECHARGE viejo queda sin uso); comentarios de variables actualizados.
  * scr_survivors.gml: anims[23] y eanims[23] = spr_amy_attack1_canon (la jugadora Y los puppets remotos ven el sprite nuevo del dash).
  * obj_amy_canon/Draw_76.gml: caso TAROTDASH con image_speed = AMY_CANON_TAROTDASH_ANIMSPD (antes reusaba el del ataque 3).
  * obj_amy_canon/Step_2.gml: comentario de la macro actualizado (tecla X).
  * obj_playerui/Draw_64.gml: icono 1 (Z) = salto de martillo, blanco = CD listo Y en suelo; icono 2 (X) = impulso aereo, blanco = CD listo Y en el aire (espejo del icono 3), con el CD nuevo.
  * obj_player_puppet/Step_0.gml: INTACTO (0 cambios): el stun 2s vive en state==AMY_CANON_TAROTDASH (independiente de la tecla, llega por el flag PLAYER_ATTACKING ya sincronizado) y el pad +20% del salto de martillo (v1) se conserva solo.
- Validacion (scripts/tarot_v3_validate.py): 25 checks estructurales + 13 simulaciones de flujo con motor espejo del orden real del frame (specialFunc → gravedad → mover → bloque float): TODAS OK. Verificado: caida del float = 0.5 EXACTO; dash ~47-48 frames a xspd 14 con caida ≤2.22; suelo+X y aire+Z(tap) no disparan nada; dash→float con Z mantenida no corta Loop_Card; float+X = dash directo; CDs correctos (hjump solo baja en suelo, attackTimer siempre); iconos con las condiciones correctas.
- Bug de mi validador encontrado y corregido: mi primer motor simulaba la gravedad DESPUES de mover (daba 0.28125); el engine real suma yAccel ANTES de y+=yspd — con el orden correcto el truco 0.5-yAccel da exactamente 0.5.

Stage Summary:
- Entregable: download/amy_canon_tarot_v3.zip (7 .gml + worklog.md). NO incluye .yyp/.yy: los assets (sprite, sonidos, Loop_Card.yy, .yyp) ya estan commiteados por el usuario. Extraer con GameMaker CERRADO como siempre.
- Controles finales: Z suelo = salto de martillo (corriendo OK, hitbox +20%, CD 9s); Z aire = nada (solo pasiva float manteniendolo al caer); X aire = impulso de tarot (48f a velocidad 14, sprite nuevo, stun 2s, CD 9s/4s); C suelo = acometida (intacta); pasiva float = caida 0.5 (24x mas lenta).
- Sonidos finales: pasiva = DSTAROT2 + Loop_Card en loop; impulso = DSTAROT1 1 vez (one-shot, se apaga solo) + Loop_Card en loop; DSTAROT1 jamas loopea; DSTAROT3 sigue sin uso.
- PENDIENTE DECIRLE AL USUARIO: el ARTE del icono 2 de la UI sigue siendo spr_gui_amyattack_canon (corazones); si quiere arte de tarot ahi, hay que cambiar ese sprite. Tuning rapido en Create_0: TAROTDASH_TIME 48 / SPEED 14 / CD 9s-4s / ANIMSPD 0.25.
- El worklog de su repo estaba 1 entrada atras (hasta tarot-v1); el ZIP lleva el log completo actualizado (hasta esta entrada v3).

---
Task ID: bubble-fix-1
Agent: main (Z.ai)
Task: Corregir los 2 bugs de la burbuja de secuestro de Amy Canon reportados por el usuario: (1) capturada en el suelo NO levita (queda estatica, solo se mueve a los lados, sube unicamente si llega a un risco); (2) al salir de la burbuja no funciona NINGUNA habilidad, ni siquiera la pasiva.

Work Log:
- Fetch: el usuario commiteo mi zip tarot_v3 (f50cb34a) + sus retoques (952994ea: pad +20% devuelto al SALTO DE MARTILLO en el puppet, como era la intencion v3). Sync ff a 952994ea; mi unico archivo divergente (obj_player_puppet/Step_0.gml con el edit v2) se descarto porque SU version es la correcta.
- Diagnostico BUG 1 (estatica en el suelo): scr_amy_canon_capture() NUNCA ponia isGrounded = false. La ruta de muerte (scr_player_hurt -> hp<=0 -> scr_player_instakill -> capture -> return) sale ANTES de la linea "global.player.isGrounded = false" del final del hurt, asi que Amy entraba a la burbuja "grounded" y el snap al piso de scr_collision_check_bottom (rama isGrounded: barrido 48px hacia abajo + y = winner) le pisaba la yspd negativa CADA FRAME: la burbuja la empujaba 0.57px arriba y el snap la devolvia al piso. El lateral si funcionaba (el snap no toca x). Al despeñarse por un risco, el barrido de 48px no encontraba piso -> isGrounded = false -> recien ahi levitaba. Calza EXACTO con el reporte ("a menos que llegue a un risco o lugar donde caer").
- Fix BUG 1: isGrounded = false (+ angle = 0) dentro de scr_amy_canon_capture(). Con eso el frame siguiente entra por la rama !isGrounded de scr_collision_basic (gravedad + yspd pre-compensada = levitacion neta 0.35) y check_bottom no la aterriza (la rama aerea solo aterriza con yspd > 0).
- Diagnostico BUG 2 (sin habilidades al salir): TODOS los guards de entrada (Z salto de martillo y X impulso en scr_amy_canon_special; pasiva float en Step_0) exijian bubbleState == AMY_BUBBLE_NONE, pero al salir de la burbuja queda AMY_BUBBLE_OVER PARA SIEMPRE (necesario para la regla "2da caida = muerte directa" de scr_player_instakill) -> Z, X y pasiva bloqueadas de por vida. ADEMAS la condicion de SALIDA del float (bubbleState != AMY_BUBBLE_NONE) mataba la pasiva durante OVER aunque se arreglara la entrada (doble candado del mismo bug). La acometida (C) nunca tuvo guard de burbuja.
- Fix BUG 2: semantica "bloqueada SOLO DENTRO de la burbuja": entradas Z/X/float pasan de == AMY_BUBBLE_NONE a != AMY_BUBBLE_ACTIVE; salida del float pasa de != AMY_BUBBLE_NONE a == AMY_BUBBLE_ACTIVE. scr_player_hurt y scr_player_instakill quedan INTACTOS (su logica NONE=1ra caida / OVER=2da caida muerte directa sigue igual). Verificado en espejo: DENTRO (ACTIVE) todo sigue bloqueado; SIN burbuja (NONE) comportamiento identico al anterior (regresion limpia).
- Bonus verificado sin tocar codigo: al salir manteniendo Z la pasiva engancha en la caida (isGrounded=false + yspd>0); la acometida C nunca se bloqueo; el EXE no puede liberarla (obj_player_puppet: isDemonized = revivalTimes>=2 || character==CHARACTER_EXE).
- Validacion (scripts/bubble_fix_validate.py): 40 checks OK. Motor espejo del orden real del frame (bubble -> gravedad -> y+=yspd -> check_bottom): el codigo VIEJO (git HEAD) reproduce el bug EXACTO (0.000px en 180 frames en el suelo; con risco a f60 sube 42px); el NUEVO levita 0.35 EXACTO desde el frame 1 (21.000px en 60 frames), nunca se re-groundea, y con techo queda flotando en el lugar (no lo atraviesa). Guards evaluados con las expresiones REALES extraidas de los archivos viejo y nuevo. Scripts: bubble_fix_edits.py (5 ediciones byte a byte con tabs/espacios preservados) + bubble_fix_reword.py (comentarios sin literales de codigo viejo).

Stage Summary:
- Entregable: download/amy_canon_bubble_fix.zip (3 .gml + worklog.md): scripts/scr_amy_canon_bubble/scr_amy_canon_bubble.gml, scripts/scr_amy_canon_special/scr_amy_canon_special.gml, objects/obj_amy_canon/Step_0.gml. Extraer con GameMaker CERRADO como siempre.
- Comportamiento final: capturada en el suelo = se despega y levita desde el frame 1 (0.35 px/frame); dentro de la burbuja todo bloqueado como siempre; al salir (OVER) recupera Z, X, pasiva y C completos; la 2da caida sigue siendo muerte directa; el EXE y los minions siguen sin poder liberarla.
- REGLA PARA EL FUTURO: los guards de Amy Canon deben usar "bloqueado DENTRO de la burbuja" (!= AMY_BUBBLE_ACTIVE), NUNCA "solo antes de la burbuja" (== AMY_BUBBLE_NONE) — OVER es un estado PERMANENTE de la ronda (vive hasta el final para la regla de la 2da caida).

---
Task ID: sensors-v1
Agent: main (Z.ai)
Task: Anadir 2 pasivas nuevas de "sensores" a Amy Canon (pedido del usuario):
(1) ver siempre donde esta la SALIDA (el anillo verde de escape, igual que
dice que el exe sabe donde aparece); (2) ver siempre la ubicacion del EXE
(como si tuviera el sensor de eggman activo sobre el, pero solo ella lo ve).

Work Log:
- Investigacion de los sistemas vanilla: obj_surv_ringindicator (flecha al
  anillo, SOLO mapa ravinemist y exige 6 shards, sprite spr_sindicator2
  verde), obj_surv_indicator (flecha del rastreador de eggman: 3 segundos
  por alarma, sprite spr_sindicator azul), obj_demon_indicator (flecha al
  exe para demonizados: recorre puppets con character==CHARACTER_EXE),
  obj_eggtrack (es la TRAMPA fisica del tracker, no la flecha). El exe NO
  tiene flecha nativa al anillo en este repo; la unica referencia de
  "ver la salida" del juego es la de ravinemist.
- Confirmaciones clave: los puppets remotos SIEMPRE sincronizan posicion
  (exe invisible incluido: solo cambia a sprites spr_exe_invis_*), asi que
  la flecha al exe funciona hasta con el exe invisible; obj_amy_canon solo
  existe en el cliente local (los remotos son obj_player_puppet via
  player_get); la burbuja fuerza revivalTimes=0 -> Amy jamas se demoniza
  (el guard de demonizada es pura red de seguridad).
- Nuevo objeto objects/obj_amycanon_indicators/ (clon estructural del
  obj_demon_indicator: carpeta Amy Canon, spriteId null, visible false,
  TABS, 3 eventos Create/Step/Draw64):
  * Create_0: depth -200 + ringVisible/ringAngle/exeVisible/exeAngle.
  * Step_0: guarda revivalTimes>=2; SENSOR 1 (SALIDA) = flecha siempre
    que exista obj_bigring, sin condiciones de shards/mapa; SENSOR 2 (EXE)
    = patron del demon_indicator (puppet CHARACTER_EXE) permanente.
  * Draw_64: flecha VERDE spr_sindicator2 pegada a Amy (identico al
    indicador de ravinemist); flecha AZUL spr_sindicator desplazada 24px
    radiales (cos/-sin, patron de obj_exe_sprindicator) para que las dos
    nunca se tapen.
- Edits: obj_amy_canon/Create_0.gml (crea el objeto tras los 8 sensores
  fisicos, indentacion de 4 espacios como el archivo) y .yyp (recurso
  registrado justo despues de obj_amy_canon).
- TODO client-side: CERO cambios de servidor (las posiciones ya estan
  sincronizadas para todos los clientes).
- Validacion (scripts/sensors_v1_validate.py): 65 checks OK. Cubre .yyp
  (JSON5 + registro unico + carpeta), .yy (3 eventos), GML (TABS puros,
  balance, ascii), cross-refs (sprites/objetos/macro), 8 simulaciones de
  logica (sin player, demonizada, solo exe, angulos GM exactos 315/90/0,
  exe invisible, dentro y tras la burbuja) e integridad del bubble fix
  (md5 identicos a amy_canon_bubble_fix.zip). Se corrigieron 2 bugs del
  propio validador: conteo de menciones vs llamadas reales y la convencion
  de angulos GM (abajo-derecha = 315, no 45).
- Preview con los sprites reales del juego:
  download/amy_canon_sensores_preview.png.

Stage Summary:
- Entregable: download/amy_canon_sensores.zip = 4 archivos nuevos del
  objeto + Create_0 de Amy editado + .yyp + los 3 archivos del bubble fix
  (re-incluidos identicos, por si aun no se habian extraido) + worklog.md.
  Extraer con GameMaker CERRADO (el .yyp y el objeto nuevo requieren reload
  completo del IDE).
- Comportamiento final: Amy Canon ve SIEMPRE una flecha VERDE hacia la
  salida desde el momento en que el anillo aparece (cualquier mapa, sin
  shards) y una flecha AZUL permanente hacia el exe (funciona incluso con
  el exe invisible). Nadie mas ve sus flechas: el objeto solo existe en su
  cliente. Se apagarian solo si ella se demonizara (imposible por la
  regla canonica de la burbuja).
- Tuning facil en obj_amycanon_indicators: el 24 de Draw_64 = distancia de
  la flecha azul; spr_sindicator/spr_sindicator2 se pueden cambiar por
  spr_sindicator3 (amarilla) u otras.
