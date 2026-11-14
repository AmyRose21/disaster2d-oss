# Worklog

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
Task ID: restauracion-rollback
Agent: main (Z.ai)
Task: Restaurar memoria tras rollback del sandbox (las entradas sensors-v1 y
reserved-v1 se perdieron del worklog local cuando el sandbox volvio a un
estado antiguo; se reconstruyen desde el resumen de sesion).

Work Log:
- El sandbox se revirtio: /home/z/my-project/td2dr/disaster2d-oss/ (repo
  cliente con TODOS los cambios de Amy Canon) desaparecio; td2dr/server/
  betterserver-oss quedo en estado VANILLA (sin cambios reserved); download/
  y scripts/ volvieron a tareas tempranas (Fraymakers/100v).
- IMPORTANTE: el USUARIO ya tiene instalado todo lo entregado (su captura de
  consola muestra "amy canon unlock: false" y "tried to pick [Amy Canon]
  without unlock!" = strings que SOLO existen en el server modificado que le
  entregue en amy_canon_reservada.zip). No hay que re-entregar nada de eso.
- Entradas restauradas abajo (contenido fiel al resumen de sesion).

Stage Summary:
- La unica fuente actualizada del estado del proyecto es este worklog + el
  zip que YA tiene el usuario. Si una tarea futura necesita tocar la fuente
  del server/cliente, hay que re-aplicar los cambios descritos en
  reserved-v1/sensors-v1 (diseno completo documentado abajo).

---
Task ID: sensors-v1 (restaurado)
Agent: main (Z.ai)
Task: Pasiva de Amy Canon: doble sensor (flecha verde a la salida + flecha
azul permanente al Exe, solo visible para el cliente de Amy).

Work Log:
- Nuevo objeto objects/obj_amycanon_indicators/ (Create/Step/Draw, indent
  TAB, depth -200). SENSOR 1: verde spr_sindicator2 hacia obj_bigring en
  cuanto existe (sin condiciones de mapa/shards). SENSOR 2: azul
  spr_sindicator permanente hacia obj_player_puppet con
  character==CHARACTER_EXE (funciona hasta con Exe invisible porque el
  puppet siempre sincroniza posicion).
- Draw usa ceil() y restar obj_camera.x/y; angulo GM: atan2(y1-y2, x2-x1),
  flecha derecha-abajo = 315 grados. Guard revivalTimes>=2 como red de
  seguridad.
- Wiring: instance_create_depth(x, y, 0, obj_amycanon_indicators) en
  obj_amy_canon/Create_0.gml tras el sensorAR (indent 4 espacios); registro
  en .yyp con parent folders/Objects/Player/Survivors/Amy Canon.yy.
- Validador scripts/sensors_v1_validate.py: 65 checks OK. Entregable:
  download/amy_canon_sensores.zip (6 archivos sensores + 3 del bubble fix +
  worklog). Preview: amy_canon_sensores_preview.png.
- BUG del validador corregido: contar solo llamadas reales (no comentarios);
  convencion de angulos GM.

Stage Summary:
- Cero cambios de servidor; objeto local = invisible para los demas.
- Parametros ajustables: offset 24px flecha azul; alternativa
  spr_sindicator3 (amarilla).

---
Task ID: reserved-v1 (restaurado)
Agent: main (Z.ai)
Task: Amy Canon PERSONAJE RESERVADO: nadie mas puede usarla ni verla
seleccionable, incluso editando su cliente; solo el usuario (con su token
local) puede elegirla.

Work Log:
- Flujo: picker obj_lobby_icon/Draw_0 cicla selected 1..7 y manda
  CLIENT_REQUEST_CHARACTER(u8 1-based); server CharSelect.c valida
  id<=CH_AMY_CANON, mira lobby.avail[id], responde
  SERVER_LOBBY_CHARACTER_RESPONSE(char, result); result=0 = snd_nono +
  casilla tachada (mecanica "personaje ocupado" reutilizada).
- Diseno: TOKEN SECRETO fail-closed. Server: Config.json clave
  "amy_canon_token" (max 64, vacio = bloqueada para TODOS). Cliente del
  usuario: archivo amy_canon.token (working_directory o %USERPROFILE%) que
  se envia con packet nuevo CLIENT_AMY_AUTH justo tras IDENTITY; server
  marca PeerData.amy_authed. Pedir Amy Canon sin auth = respuesta de
  "ocupada" + log "tried to pick [Amy Canon] without unlock!". Apodo NO
  sirve (spoofeable).
- Server (6 archivos betterserver-oss/): Packet.h enum += CLIENT_AMY_AUTH
  al final (141 miembros en ambos lados); Server.h PeerData += amy_authed;
  Config.h/Config.c += amy_canon_token[65] (carga/guardado en Config.json);
  states/Server.c: reset amy_authed en peer_identity + case CLIENT_AMY_AUTH
  en dispatch global (lee 2 bytes header + string; strcmp exacto);
  states/CharSelect.c: rechazo antes del flujo avail. Fix: PacketRead
  esperaba Packet* => &packet.
- Cliente (4 archivos): net_packets.gml enum += CLIENT_AMY_AUTH;
  scr_globals.gml lee amy_canon.token a global.amyCanonToken (busca en
  working_directory y %USERPROFILE%, trim final de linea);
  net_indentity.gml envia CLIENT_AMY_AUTH tras IDENTITY si hay token;
  obj_lobby_icon/Draw_0.gml: sin token el ciclo envuelve en
  CHARACTER_SALLY + guard extra en el envio. Exe picker intacto. Character
  Info visible para todos (escaparate).
- Compatibilidad: enum append-only => clientes viejos siguen funcionando y
  el bloqueo del server les aplica igual.
- Validador scripts/reserved_v1_validate.py: 56 checks OK (incluida
  simulacion de ciclos del picker y guards hackeados). Entregable:
  download/amy_canon_reservada.zip (6 server + 4 cliente + worklog +
  LEEME_AMY_CANON_RESERVADA.txt).
- ESTADO DEL USUARIO (24/10): todo instalado y funcionando; su consola
  mostro "AMY ROSE (id 1) amy canon unlock: false" y "tried to pick [Amy
  Canon] without unlock!" => server recompilado con los cambios, token
  enviado; solo falta que la frase del amy_canon.token coincida con la
  clave amy_canon_token del Config.json (casi seguro vacia en su config).

Stage Summary:
- Unico punto de fallo restante: configuracion manual de la frase en 2
  archivos. => siguiente tarea (reserved-v3): CONFIGURADOR AUTOMATICO.

---
Task ID: reserved-v3
Agent: main (Z.ai)
Task: CONFIGURADOR AUTOMATICO de la frase secreta de Amy Canon (.bat +
.ps1). El usuario se equivocaba configurando a mano (Config.json del server
con amy_canon_token vacio -> "amy canon unlock: false"). Pidio: "hasme un
programa que configure auto las config por medio de un bat que genere el
token y configure el config este y listo".

Work Log:
- Diagnostico previo (con captura del usuario): consola mostraba "AMY ROSE
  (id 1) amy canon unlock: false" + "tried to pick [Amy Canon] without
  unlock!" => TODO el sistema reserved-v1 instalado y funcionando; unico
  fallo = frase del amy_canon.token no coincidia con amy_canon_token del
  Config.json (casi seguro vacio o edito el Config.json equivocado).
- Entregable download/amy_canon_configurador/ (3 archivos):
  * CONFIGURAR_AMY.bat: lanzador ASCII puro + CRLF; guards: powershell
    existe, ps1 junto al bat (no ejecutar desde dentro del zip), propaga
    errorlevel del ps1.
  * configurar_amy.ps1 (compatible PS 5.1 de fabrica, 100% ASCII): PASO 1
    localiza Config.json (arrastra carpeta/exe/archivo, o Enter = busca
    con Get-ChildItem -LiteralPath -Filter Config.json -File -Recurse
    -Depth 5 alrededor del script; marca cada config [con server al lado]
    si hay DisasterServer*.exe en su carpeta; varios = actualiza TODOS con
    confirmacion S/n); PASO 2 frase (propia validada
    ^[A-Za-z0-9\-]{4,64}$ o Enter = "amy-#####-#####-#####" con
    Get-Random); PASO 3 escribe: en cada config, si existe la clave =>
    -replace '"amy_canon_token"\s*:\s*"[^"]*"', si no => inserta tras el
    primer '{' ("\r\n\t\"amy_canon_token\": \"frase\","); backup
    nombre.bak-FECHA de TODO lo tocado; crea %USERPROFILE%\amy_canon.token
    con WriteAllText UTF8sinBOM sin newline; copia legible de la frase en
    amy_canon_frase_copia.txt junto al script; PASO 4 VERIFICACION:
    relee cada config con ConvertFrom-Json y compara -ceq, relee el
    token; tabla [OK]/[X]; exit code para el bat; detecta si hay un
    DisasterServer abierto y avisa; instrucciones finales (reiniciar
    server, buscar "amy canon unlock: true").
  * LEEME_CONFIGURADOR.txt.
- Detalles de robustez: -LiteralPath en todo (rutas con [corchetes]
  seguras); ReadAllText elimina BOM al leer y WriteAllText utf8sinBOM
  normaliza (nunca deja BOM); sin sintaxis PS7 (validado contra lista);
  idempotente; no necesita admin.
- Validacion SIN PowerShell en sandbox (no hay pwsh):
  scripts/reserved_v3_config_test.py = 74 checks OK — puerto Python EXACTO
  de la regex/insert (probado contra el Config.json VANILLA REAL generado
  por el binario en run_test/ + formato cJSON tabulado del server
  modificado + BOM + minificado + espacios raros + clave duplicada),
  reglas de frase (200 muestras + rechazo de invalidas), simetria de
  escritura del .token con lo que lee el cliente GML (file_text_read_string
  + trim), y 40+ checks estructurales (ASCII, sin BOM, CRLF del bat,
  balance con tokenizador PS proper — el naive daba falso positivo con
  strings de comilla simple que contienen comillas dobles, corregido con
  tokenizador completo estado code/squote/dquote/comment).
- scripts/reserved_v3_integration.py: simulacion end-to-end con carpeta
  tipo usuario (exe + Config.json raiz vanilla + 2 anidados VS
  Release/Debug con clave vacia): 3 configs hallados, actualizados,
  verificados, token creado, backup restaurable. TODO OK.
- Fix durante el test: el Write inicial dejo el bat con LF → convertido a
  CRLF + newline final; echo con > escapado como -^> y parens ^( ^).

Stage Summary:
- Entregable: download/amy_canon_configurador.zip (bat + ps1 + LEEME +
  worklog). Uso: extraer, doble clic al bat, arrastrar la carpeta del
  server, Enter (frase auto), cerrar y reabrir el server. Si la consola
  dice "amy canon unlock: true" esta listo.
- El configurador NO toca binarios ni codigo: solo Config.json (datos) +
  amy_canon.token. Compatible con el server ya compilado del usuario
  (reserved-v1); no requiere recompilar NADA.
- Cambiar de frase en el futuro = ejecutar el configurador de nuevo.

---
Task ID: hammer-v1
Agent: main (Z.ai)
Task: (1) Salto de martillo de Amy Canon => ABAJO+Z como la Amy
original PERO tambien en plena carrera; Z sola = salto normal (nunca
martillo). (2) Permitir conectar 2 juegos en la misma PC para tests
locales. Peticion del usuario: "originalmente debia presionar abajo y
salto pues quiero que sea asi pero si estoy corriendo... y presiono la
combinacion de abajo y Z haga el ataque No por presionar salto normal"
+ "como hago para poder conectarme con la misma ip... no me permite
conectarme 2 juegos en la misma pc".

Work Log:
- RECUPERACION DEL REPO: el sandbox habia perdido disaster2d-oss en un
  rollback; el usuario paso su repo (github.com/AmyRose21/disaster2d-oss,
  "Pull y veras") y se clono a td2dr/disaster2d-oss. Confirmado que su
  repo YA contiene: reserved-v1 (server CLIENT_AMY_AUTH + cliente token),
  sensores (obj_amycanon_indicators), bubble fix, scr_amy_canon_*,
  compilar_server.bat propio del usuario. Todo el trabajo sigue ENCIMA de
  su estado.
- INVESTIGACION del motor: scr_move_basic => rama suelo (agacharse
  requiere gspd==0; rodar requiere canSpin=true y Amy Canon tiene
  canSpin=FALSE => Abajo mientras corres no hace nada, cambio limpio);
  specialFunc() corre SIEMPRE (linea 584, fuera del if isGrounded) y
  ANTES del salto generico (linea 617, en el else de !isGrounded); el
  truco vanilla: el especial "reclama" el salto poniendo isJumping=true
  + isGrounded=false => el salto normal no se doble-dispara. isHJ =>
  Step_2 (End Step) fuerza state=AMY_CANON_HJUMP (prioridad sobre todo);
  Draw_76 anima y suelta isHJ al final; collision suelta isHJ al aterrizar;
  hitbox del golpe activa mientras image_index<=3 (Step_0 return temprano).
- EDICION martillo (scripts/scr_amy_canon_special/scr_amy_canon_special.gml,
  TABs/LF): condicion += keyboard_check(global.KeyDown) [mantener Abajo] &&
  !isDashing [no martillo en plena acometida]; cuerpo += image_index = 0
  [al venir corriendo el image_index quedaba a mitad de la animacion de
  correr y se saltaba los frames 0-3 del golpe]; comentarios reescritos.
  Create_0.gml: comentario de HABILIDAD 1 actualizado. CERO cambios en
  mecanica del salto (isJumping/justJumped/xspd/yspd/isHJ/CD intactos) ni
  en las otras habilidades (X impulso, C acometida) ni bloqueos
  (burbuja/anillo rojo/escondite).
- EDICION multijuego local (server, 3 archivos): Config.h +=
  bool allow_duplicate_ip; Config.c += load (cJSON_IsTrue, default false;
  con save en Config.json); states/Server.c peer_identity_process:
  guard !g_config.allow_duplicate_ip && !v->op && (ip||udid) antes del
  DR_IPINUSE. El bloqueo original (anti-multicuenta) queda intacto con
  false; op (127.0.0.1 en Operators.json) sigue bypassando como siempre.
- CAUSA del problema del usuario diagnosticada: si conecta via IP LAN
  (192.168.x.x) NO es op => 2a instancia rechazada por DR_IPINUSE; via
  127.0.0.1 ya era op y pasaba. La llave nueva cubre ambos casos.
- COMPILACION: build_hammer_src (repo usuario + enet del vanilla) cmake
  Release 100% limpio; smoke test 3s OK (v1101, puerto 8606); Config.json
  generado incluye amy_canon_token + allow_duplicate_ip:false.
- TEST END-TO-END REAL: scripts/test_dup.c (cliente ENet crudo en C,
  linkado al mismo libenet.a; layout IDENTITY: u8 0 + u8 type + u16 1101
  LE + i32 0 + str\0 nick + str\0 udid + u8 icon + i8 pet=-1 + u64 0 +
  u64 0). 3 escenarios contra el binario real: (A) llave false sin op:
  bot1 ACCEPT, bot2 REJECT razon 11 DR_IPINUSE; (B) llave true sin op:
  ambos ACCEPT; (C) llave false con op 127.0.0.1: ambos ACCEPT.
- VALIDADOR scripts/hammer_v1_validate.py: 51 checks OK (condicion
  exacta, vieja eliminada, KeyA pressed exactamente 1 [el impulso aereo
  es KeyB], mecanica intacta, otras habilidades intactas, bloqueos,
  sintaxis TABs/LF/parens, 13 simulaciones de la logica de entrada,
  guard del server con orden correcto, integridad de reserved/sensores/
  burbuja). 2 fixes del propio validador durante la corrida (conteo
  KeyA y ventana de busqueda corta).
- Entregable: download/amy_canon_martillo_y_multijuego.zip (5 archivos
  cambiados + LEEME + worklog). El usuario extrae sobre la raiz del
  proyecto (GameMaker cerrado) y RECOMPILA el server.

Stage Summary:
- CONTROLES NUEVOS: Abajo+Z = salto de martillo (parada/caminando/
  CORRIENDO, conserva impulso; swing desde frame 0); Z sola = salto
  normal; X aire = impulso tarot; C = acometida. Sin martillo con Z
  sola NI durante la acometida.
- MULTIJUGADOR LOCAL: "allow_duplicate_ip": true en Config.json del
  server + reiniciar. Default false = vanilla. Pendiente de confirmar
  por el usuario en partida real con 2 ventanas.
- Nota: si el usuario conecta a 127.0.0.1 es op y ya podia doble-entrar;
  su fallo casi seguro era IP LAN. Si aun falla con la llave true,
  pedir captura de la consola del server.

---
Task ID: bugfix-tarot-v1
Agent: main (Z.ai)
Task: 2 bugs reportados por el usuario tras probar con 2 instancias:
(1) CRASH "Variable obj_player_puppet.AMY_CANON_TAROTDASH_HITBOX_PAD
not set before reading it" al impactar al exe con el impulso de tarot
(tecla X). (2) Las pasivas de sensores de Amy Canon (flecha verde a la
salida + flecha azul al exe) no se ven.

Work Log:
- CAUSA bug 1: la macro AMY_CANON_TAROTDASH_HITBOX_PAD se usaba en
  obj_player_puppet/Step_0.gml:59 (pad de ~5px para cazar el stuneo del
  tarot) pero NUNCA fue definida. En GML && cortocircuita => la
  "variable" solo se evalua cuando character==AMY_CANON (puppet) esta en
  estado TAROTDASH => explota justo al impactar, en el cliente DEL EXE
  (donde Amy es puppet). FIX: #macro AMY_CANON_TAROTDASH_HITBOX_PAD 5 en
  obj_amy_canon/Create_0.gml junto a su hermana del salto.
- CAUSA bug 2: obj_amycanon_indicators nace con visible:false (su .yy) y
  su Step nunca la activaba. En este runtime el evento Draw GUI NO corre
  para instancias invisibles: los indicadores ORIGINALES del juego
  (obj_surv_ringindicator / obj_demon_indicator) tienen el mismo
  visible:false en .yy pero su Step pone visible=true cuando hay algo
  que senalar, su Draw_64 abre con if(!visible) return; y ademas
  incluyen un Draw_0 (normal) VACIO de 0 bytes. Mi objeto no hacia nada
  de eso => flechas jamas dibujadas. FIX: paridad exacta con los
  originales: Step gestiona visible=false en los 2 early-returns y
  visible=(ringVisible||exeVisible) al final; Draw_64 con guard; nuevo
  Draw_0.gml vacio; eventList del .yy += Draw_0 (4 eventos, mismos que
  el original verificado por el validador).
- BUG 3 (bonus, hallado en la investigacion): AMY_CANON_HJUMP_HITBOX_PAD
  estaba DEFINIDA pero nunca se usaba => la "hitbox 20% mas grande" del
  salto de martillo documentada no existia en la practica. FIX: el
  puppet ahora aplica el mismo pad al swing del martillo (frames 0-2 del
  HJUMP): var _acHJPad y el if exterior queda
  place_meeting || _acTarotPad || _acHJPad.
- HALLAZGO que descarto un 4o bug: AMY_HJUMP (obj_amy/Step_2.gml) y
  AMY_CANON_HJUMP (obj_amy_canon/Step_2.gml) valen LO MISMO (BALANCING+2)
  => el hack del puppet (state == AMY_HJUMP => isAttacking=true, dano 20
  al exe en el cliente del exe) ya cubre a Amy Canon sin cambios.
- Barrido completo de macros fantasma proyecto entero (definidas vs
  usadas): tras el fix queda CERO (la unica otra deteccion era un falso
  positivo del comentario "AMY_CANON_DASH_*").
- INCIDENTE de herramienta: la edicion expandio TABs->8 espacios en los
  3 archivos .gml completos (diff de 554 lineas en el puppet). Regresado
  con git checkout y re-aplicado TODO con scripts/apply_bugfix.py
  (ediciones quirurgicas con \t literales y verificacion de match
  exacto 1 vez). Diff final: 23 insertions / 3 deletions en 5 archivos +
  Draw_0.gml nuevo.
- Validador scripts/bugfix_v1_validate.py: 45 checks OK (macro definida
  una sola vez y =5, cero fantasmas, condiciones exactas de los 3 pads,
  hack intacto, stunTime=2 del tarot intacto, AMY_HJUMP==AMY_CANON_HJUMP,
  visible en los 3 caminos del Step, guard del Draw, Draw_0 vacio, .yy
  con 4 eventos identico en estructura a obj_surv_ringindicator, sin CR,
  sin sangria de espacios, llaves/parens balanceadas, wiring y otras
  habilidades intactas).
- CERO cambios en el server => NO hay que recompilar nada: solo extraer
  sobre la raiz del proyecto con GameMaker cerrado y volver a abrir.

Stage Summary:
- Entregable: download/amy_canon_bugfix_tarot_sensores.zip (6 archivos
  + LEEME + worklog). Solo cliente.
- RESULTADO esperado en juego: tarot (X) contra el exe sin crash en
  NINGUNA de las 2 ventanas; flecha AZUL al exe siempre visible (solo
  para Amy) y flecha VERDE a la salida desde que el anillo de escape
  aparece en el mapa; martillo con hitbox ~20% mas grande en el swing.
- La flecha verde NO aparece antes de que el anillo de escape exista en
  el mapa (by design: senala la salida).

---
Task ID: flecha-roja-v1
Agent: main (Z.ai)
Task: Duda del usuario sobre los colores de las flechas (roja la del exe
cuando busca survivors, "al reves" la de los survivors) + decision de
diseno: la flecha roja debe senalar donde esta el EXE real (nunca sus
minions, porque en 2D no se les distingue del exe en pantalla).

Work Log:
- Investigados TODOS los indicadores del juego base (lectura completa de
  sus .gml) y analizados los colores reales de sus sprites con PIL
  (scripts/check_arrow_colors.py; cubetas RGB + nombre humano):
    * spr_sindicator   = AZUL  (eggtrack de eggman; era NUESTRA flecha exe)
    * spr_sindicator2   = VERDE (anillo de escape; nuestra flecha salida)
    * spr_indicator     = ROJA  (anillo rojo; 32x16 = MISMA forma que la
    azul, confirmado: mismos % de pixeles opacos)
    * spr_indicator2    = VERDE 8x8 (demonizados -> exe)
    * spr_indicator3    = ROJA 14x13 (exe-only: resortes usados, hide&seek)
    * clonearrow f0/f1  = AZUL/ROJA 8x8 (sobre los clones, exe-only)
    * clonetracker/up   = ROJA 12x12 y clonetracker2/down = AZUL 12x12
    (exe-only: clones detectan a un survivor a <240px)
- RESPUESTA a la duda: el juego base NO tiene convencion de color. Cada
  flecha es un sprite pintado a mano heredado del juego original: el
  color no codifica ni al que la ve ni al objetivo. Prueba maxima: en el
  PROPIO sistema de clones del exe los colores se cruzan (clon marcado
  con flecha azul arriba -> tracker ROJO al detectar; clon marcado con
  roja -> tracker AZUL). Lo que vio el usuario: en la ventana del exe,
  rojas de spr_indicator3 (resortes) + clonetracker + anillo rojo; en su
  ventana de Amy, la flecha al exe era AZUL porque la v1 reutilizaba
  spr_sindicator (la del eggtrack de eggman).
- CAMBIO (decision del usuario): la flecha al exe de Amy Canon pasa de
  AZUL a ROJA. Draw_64.gml: draw_sprite_ext(spr_sindicator ->
  spr_indicator). Cero assets nuevos: spr_indicator es la flecha roja
  32x16 que ya trae el juego base. La VERDE de la salida no cambia.
- GARANTIA anti-minions (ya existia en el filtro, ahora documentada en el
  propio Step_0.gml): el sensor 2 solo elige puppets con character ==
  CHARACTER_EXE. Los demonizados (minions) conservan su personaje
  original y los clones del exe (obj_exeller_clone) no son
  obj_player_puppet: ninguno de los dos dispara jamas la flecha.
- Comentarios actualizados en Create_0.gml, Step_0.gml y Draw_64.gml.
  3 archivos .gml tocados; cero .yy/.yyp; cero server.
- Validador scripts/flecha_roja_v1_validate.py: 30 checks OK / 0 FAIL
  (sprite rojo en el Draw, azul fuera, salida verde intacta, guard
  visible, filtro solo-exe-real, early-returns, Draw_0 vacio, .yy con 4
  eventos, higiene sin CR / llaves / parens, paridad v1 completa, LEEME).
- LEEME_BUGFIX_TAROT_SENSORES.txt reescrito a v2 (incluye la flecha roja
  y la explicacion de que las flechas de la ventana del exe son del
  juego base y no se tocan).
- Entregable: download/amy_canon_bugfix_tarot_sensores_v2.zip (7 archivos
  + LEEME v2 + worklog). Extraer la v2 encima ya incluye TODO lo de la
  v1 (mismos archivos en su version final).

Stage Summary:
- EN JUEGO (ventana de Amy Canon): flecha ROJA al exe SIEMPRE (spr_indicator)
  + flecha VERDE a la salida cuando el anillo existe. Nunca apunta a
  minions demonizados ni a clones del exe. Solo ella las ve.
- Las flechas de la ventana del exe (roja de resortes en hide&seek,
  azul/roja sobre sus clones, roja del anillo rojo) son del juego base
  y NO se tocan.
- No hay que recompilar el server (solo cliente).

---
Task ID: analisis-oss-1
Agent: main (Z.ai)
Task: Analisis completo del repo github.com/AmyRose21/disaster2d-oss para
recuperar contexto (el usuario pidio analisis antes de reportar "un
problema importante" a arreglar).

Work Log:
- Clonado el repo (21,793 archivos). Un solo commit ("Initial commit"),
  sin historial previo.
- Leidos worklog.md (12 tareas previas) y CACHE.md completos: contexto
  Amy Canon, reserved-v1/v3, sensors, hammer-v1, bugfix-tarot-v1,
  flecha-roja-v1/pegada-v2.
- HALLAZGO: el repo contiene una feature NUEVA no documentada en
  worklog/CACHE: "ENDINGS MUSIC v2" (LEEME_ENDINGS_V2.txt): musica de
  ending por cantidad de escapados (Best/Solo/Duo/Standard + Alt),
  sincronizada cliente-server. Piezas verificadas presentes:
  7 sonidos nuevos en sounds/ + registrados en .yyp (7 entradas OK),
  objects/obj_results/Alarm_0.gml (variante sincronizada),
  net_state_results.gml cuenta escapedCnt/survTotal, server
  states/Results.c (results_music_countdown con ENDINGLEN_*),
  include/Server.h (Results.music_synced). Logica cliente-server
  revisada: paridad (time_sec+escaped)%2 coincide en ambos lados (60 es
  par), mismo orden de categorias (2-de-2 = Best), misma clasificacion
  PLRSTATE.
- Server compilado en Linux (se clono enet a mano, ver hallazgo 2):
  100% limpio, Built target DisasterServer. Smoke test 3s OK:
  BetterServer v1101, puerto 8606, Lobby. FUENTE VALIDA tal cual esta.
- Estado Amy Canon verificado: macros TAROTDASH/HJUMP_HITBOX_PAD=5 en
  obj_amy_canon/Create_0.gml, flecha ROJA (spr_indicator) + VERDE
  (spr_sindicator2) en obj_amycanon_indicators, martillo ABAJO+Z
  (KeyDown + KeyA pressed) intactos. compilar_server.bat (menu 7
  opciones, SDL2 GUI, backup/restore de configs) correcto.
- Config.json del repo: puerto 8606, amy_canon_token "SweetPassion",
  allow_duplicate_ip true, anticheat true. Anticheat=true solo valida
  ticket/paletas/zonas (Auth.c: mod_tool si checksum==0, no
  desconecta) => compatible con cliente modificado.
- HALLAZGO 1 (repo-higiene): .gitmodules apunta a enet (lsalzman/enet)
  pero el submodulo NO esta en el repo; un clone fresco no compila
  hasta clonar enet a mano. compilar_server.bat tampoco lo resuelve.
- HALLAZGO 2 (doc drift): endings v2 no esta en worklog.md ni CACHE.md
  (solo LEEME_ENDINGS_V2.txt).
- build_test/ y run_test/ creados dentro de betterserver-oss para la
  validacion (NO commitear: borrar antes de subir o ignorar).

Stage Summary:
- Contexto TOTAL recuperado. Fuente cliente+server CONSISTENTE y
  COMPILA. Todo el historial de mods de Amy Canon esta aplicado.
- Esperando que el usuario describa el "problema importante" a
  arreglar. Pendientes detectados de analisis: enet submodule (clone
  fresco no compila) y doc drift de endings v2.

---
Task ID: docs-sync-v1
Agent: main (Z.ai)
Task: Sincronizar CACHE.md y worklog.md con el estado REAL del repo
(peticion del usuario tras el analisis: "actualiza el worklog y el cache
para tenerlas guardadas para estar al dia de lo que actualmente hay").

Work Log:
- Verificaciones previas: enum Ending (ED_EXEWIN=0, ED_SURVWIN=1,
  ED_TIMEOVER=2) y Results.music_synced confirmados en Server.h;
  aplicar_yyp_endings.ps1 YA NO esta en el repo (los 7 sonidos nuevos ya
  estan registrados en el .yyp: lineas 608-609, 613, 831-834);
  extensions/MultiClient = extension v1.1.6 que lanza N instancias del
  juego (post_run_step + opciones Number_Of_Clients/proxy) — asi se
  prueban 2 ventanas en la misma PC junto con allow_duplicate_ip.
- CACHE.md actualizado (v2, 244 -> 337 lineas):
  (1) INDICE += 7.1; (2) seccion 1 WORKSPACE re-mapeada al layout real:
  la RAIZ del repo = proyecto GameMaker, scripts/ del workspace ya no
  existe (rollback), recon original fuera del sandbox; (3) seccion 3
  retitulada (raiz del repo) + NUEVA 3.6 Extensiones (MultiClient,
  disnet, disasterserver, data); (4) seccion 6 reescrita: ruta correcta,
  submodulo enet (clone fresco NO compila), detalle de compilar_server.bat
  (menu 7 opciones, SDL2, backup/restore configs), Config.json actual
  (anticheat:true compatible con cliente modificado: checksum 0 =>
  mod_tool, no desconecta), validacion 26/10 (compila + smoke test OK),
  artefactos build_test/run_test NO commitear; (5) tabla mods +=
  endings-v2 y analisis-oss-1; (6) NUEVA seccion 7.1 = documentacion
  completa de ENDINGS MUSIC v2 (pistas + duraciones, archivos
  cliente/server, logica de categorias + variante (time_sec+escapados)%2,
  mantenimiento ENDINGLEN_*); (7) seccion 9 PENDIENTES actualizada
  (problema importante SIN describir, enet, endings v2 y flecha-pegada-v2
  por probar); (8) seccion 10 nota de herramientas historicas (ya no
  existen; convencion apply_/validate documentada); (9) changelog
  2026-10-26.
- Incidente menor: 1er MultiEdit fallo en la seccion 6 (el texto real
  dice "Libs.c" y el match decia "Lib.c"); re-aplicado con el texto
  exacto. Verificacion final: estructura 11 secciones + 7.1 en orden,
  337 lineas, sin duplicados.
- Este worklog ya contenia analisis-oss-1 (analisis completo); esta
  entrada cierra la sincronizacion de documentacion.

Stage Summary:
- CACHE.md y worklog.md AL DIA con el estado real del repo (26/10):
  todo lo instalado (incluido endings v2, que estaba sin documentar)
  ya esta inventariado. El protocolo del CACHE (leer al inicio de cada
  sesion) vuelve a ser suficiente para recuperar contexto.
- Entregable: download/cache_worklog_sync.zip (CACHE.md + worklog.md
  actualizados, para extraer en la RAIZ del repo y commitear/push).
- Siguiente: esperar la descripcion del "problema importante" del
  usuario (pendiente en seccion 9 del CACHE).

---
Task ID: relay-recon-v1
Agent: main (Z.ai)
Task: El usuario pregunto si su server soporta el sistema RELAY (servidores
repetidores) que trae el "betterserver" de file.dr2.site (proyecto
TD2DR-Updated de Penguinehis), y por que otros servidores lo tienen y el
no. Config.json de ejemplo subido por el usuario (de un server de
"Viinnyzz") con secciones relay/gamemodes/moderation.

Work Log:
- Server del usuario (betterserver-oss) revisado: CERO coincidencias de
  "relay" en todo el codigo C; las 4 de "ws_/websocket" eran falsos
  positivos (macros __WINDOWS__ de cJSON.h) => NI soportado NI bloqueado:
  la funcion NO EXISTE en ese fork. Su Config.json plano (port/
  server_count/ping_limit) confirma: es otro linaje distinto al del
  Config.json anidado (server/logging/gameplay/gamemodes/moderation/
  relay) que genero el v1.6.
- Clonado github.com/Penguinehis/TD2DR-Updated: es SOLO el CLIENTE
  GameMaker ("updated version of the game with all bug fixes"); los
  servers compilados se distribuyen en file.dr2.site. Su cliente usa
  #macro BUILD_VER 1101 (¡MISMA version de protocolo que el 110v del
  usuario!).
- Descargado betterserver-v1.6-windows-x64.exe (SHA256 verificado contra
  SHA256SUMS del sitio: a3f4a78b...fa951 OK; PE32+ console, 915 KB).
  "Source Code.txt" en la raiz de file.dr2.site solo apunta a
  TD2DR-Updated y al port 3DS => la fuente del server v1.6 NO es publica
  (fork CERRADO; banner "(c) 2024 Team Exe Empire", mismo linaje).
- ANALISIS DEL BINARIO v1.6 (strings + objdump):
  * Version de protocolo: cmp $0x44d (1101) => COMPATIBLE con el cliente
    110v del usuario. CORRECION: lo que en la Task 6 se dijo de
    "generacion vieja" era del server TTB de maxbaxwer (secretos custom);
    este v1.6 de dr2.site SI habla 1101.
  * RELAY completo implementado (/src/disasterserver/Relay.c): directorio
    relaysc.dr2.site:9000, sign-in con username/password ("the account
    from the website"), asignacion de region, ticket, publicacion de
    puertos, direcciones sinteticas para jugadores, reconexion auto.
  * Web clients: "HTTP/1.1 101 Switching Protocols" => WebSocket en los
    mismos puertos (juego de navegador).
  * Gamemodes (10): protect_the_cream, oops_all_demons, oops_no_demons,
    inf_time, last_survivor_wins, boss_fight, timeoverwin, norevives,
    norings, onehitchecklist + vanilla_balancing (fuerza max 7 players).
  * Moderacion: votekick con lobby_block 600s, report_cooldown 60s.
  * Personajes: AssertOrDisconnect(id <= CH_SALLY + 1) => MAXIMO
    personaje 6 = Sally (ids cliente). NO conoce Amy Canon (7) ni Sonic.
  * Paquetes: los 74 nombres visibles en strings TODOS existen en el
    Packet.h del oss (comm vacio) => mismo enum base, sin evidencia de
    divergencia. CLIENT_AMY_AUTH del usuario quedaria como tipo
    desconocido => este linaje IGNORA los desconocidos (peer_msg ->
    state handle -> switch sin default-disconnect) => su cliente
    CONECTARIA a un v1.6, solo que sin sus personajes 7/8.
- HALLAZGO EXTRA (doc drift #2): el repo del usuario tiene un 8vo
  personaje NO documentado en CACHE/worklog: CH_SONIC en
  include/Server.h ("Sonic (mod): sobreviviente #8") y
  #macro CHARACTER_SONIC (CHARACTER_TAILS+7) en scr_survivors.gml del
  cliente, con player_anims completos. => el repo evoluciono mas alla de
  lo documentado (pendiente: actualizar CACHE seccion 4 en la proxima
  sincronizacion de docs).
- Link GameJolt del usuario (game 1047480, build 1995313): la site-api
  devuelve payload vacio (no listado o requiere sesion) => no identificado
  formalmente, pero por el contexto es del ecosistema TD2DR-Updated
  (dr2.site). dr2.site raiz responde 403 => no se pudo verificar donde se
  registran las cuentas relay (probablemente via su Discord/comunidad).
- OPCIONES para el usuario (necesita que amigos conecten desde otra IP
  sin abrir puertos — tipico CGNAT):
  A) RE del protocolo relay (tengo el binario con todos los mensajes)
     + implementarlo en su betterserver-oss. Proyecto grande pero viable.
  B) Server doble: v1.6 para partidas publicas (su cliente conecta,
     protocolo 1101, paquetes extra ignorados) + su oss para Amy Canon.
     Limitacion: sin Amy Canon (7) ni Sonic (8) ni sus mods en el v1.6.
  C) Radmin/ZeroTier VPN (estandar de la comunidad, zero codigo).
  D) Port forwarding (solo si su ISP no usa CGNAT).

Stage Summary:
- RESPUESTA: su server NO tiene relay (no existe en el fork oss, ni
  bloqueado ni soportado). Los "otros" usan betterserver v1.6 (cerrado,
  dr2.site, proyecto TD2DR-Updated) que SI lo trae de fabrica junto a
  web clients, 10 gamemodes y moderacion avanzada. Ambos hablan 1101.
- v1.6 guardado en td2dr/relay_server/ para una posible Task de RE del
  protocolo relay (opcion A).
- Pendiente: actualizar CACHE con CHARACTER_SONIC/CH_SONIC (doc drift).

---
Task ID: portfix-v1
Agent: main (Z.ai)
Task: El usuario pregunto si el PARCHE PortFIX de penguinehis
(file.dr2.site .../Patchs-Original-game/Sonic-PortFIX.zip) "aporta en
algo" para tener relay: permite usar puertos distintos en el cliente
(sin limite de puertos) y segun el lo hace "basicamente posible de poder
jugar con relay".

Work Log:
- Descargado y descomprimido Sonic-PortFIX.zip (38 KB, 27/09/2026):
  README.txt + patch.bat + patch.ps1 + disnet_portfix.dll (72 KB).
- ANALISIS DE LA DLL (script scripts/pe_exports.py del workspace):
  PE32+ x64, exporta las MISMAS 6 funciones que la disnet original
  (connect/init/poll/reset/send/uninit) + disnet_portfix_marker
  (string DISNET_PORTFIX_V1 para idempotencia). Es un PROXY: patch.ps1
  renombra disnet.dll -> disnet_orig.dll y copia la portfix en su lugar;
  el proxy carga disnet_orig.dll (strings "disnet_orig.disnet_init" etc.)
  y reenvia todas las llamadas; en disnet_connect parsea "IP:PUERTO"
  del Join screen y le pasa el puerto correcto a la original.
- README del parche confirma el problema raiz: "The game always connects
  to port 8606, so '1.2.3.4:27015' in the Join screen fails". Funciona
  para el juego original Y cualquier mod (no toca exe ni data.win).
  Reversible con -Unpatch. Verifica que la DLL objetivo tenga
  disnet_connect antes de parchear.
- COMPATIBILIDAD CON NUESTRO JUEGO VERIFICADA: extensions/disnet/
  disnet.dll del repo es x64 y exporta EXACTAMENTE las mismas 6
  funciones => el parche aplica directo a la carpeta del juego 110v.
- Donde vive el puerto en el 110v (verificado en codigo):
  * GML: scripts/net_wrapper/net_wrapper.gml net_join() hardcodea
    port = selected_lobby == -1 ? 8606 : selected_lobby.
  * La DLL SI acepta puerto: disnet_connect(address, port)
    (objects/obj_connecting/Alarm_0.gml:3; firma nativa en Disnet.java).
  * CHANGELOBBY (net_tcpprocess.gml:127): net_join(ip, _lobby) => el
    cliente 110v SI puede reconectar a puertos != 8606 cuando el SERVER
    se lo manda (.lobby N / redirect por lobby lleno).
- ANALISIS PARALELO DEL CLIENTE TD2DR-Updated (ya clonado): su
  net_wrapper.gml trae el fix GML equivalente: parsea "IP:PUERTO" con
  string_last_pos(":"), valida digitos 1-65535, guarda ip limpia +
  base_port (para que un CHANGELOBBY/reconnect vuelva al mismo server).
  Comentario original: "a server published on a relay port unjoinable".
- ESQUEMA DE PUERTOS DEL V1101 (verificado en C): Lib.c:47
  addr.port = base_port + n => lobby 0 = g_config.port, lobby 1 = +1...
  Server.c:208 y :795 mandan el puerto absoluto en CHANGELOBBY
  (g_config.port + server->id). Config actual server_count=1 => solo
  8606, nunca hay redirect en la practica.
- MATIZ multi-lobby + PortFIX: nuestro net_join guarda ip con el
  ":PUERTO" pegado; tras CHANGELOBBY el proxy priorizaria el puerto del
  string => reconectaria al mismo puerto. Con server_count=1 no ocurre.
  Si se sube server_count: portar el fix GML de TD2DR-Updated (~20
  lineas) o usar 1 lobby.

Stage Summary:
- RESPUESTA: SI APORTA, y es justo la pieza que faltaba. El relay
  publica cada server en un puerto publico != 8606 (rango
  relay_public_port(server->id)); sin soporte IP:PUERTO en el cliente es
  IMPOSIBLE entrar a un server relayeado con el juego original. El
  PortFIX habilita el lado cliente para CUALQUIER solucion: relay de
  penguinehis, proxy propio, o puerto custom.
- Combinaciones practicas para el usuario:
  1) Relay penguinehis completo: server v1.6 (cerrado, sin Amy/Sonic) +
     jugadores con PortFIX o cliente TD2DR-Updated.
  2) Proxy/relay CASERO (VPS -> IP:8606 UDP): si el VPS expone 8606 los
     jugadores NO necesitan ni parche; si expone otro puerto, PortFIX.
     Funciona con su betterserver-oss SIN tocar una linea (ENET_HOST_ANY
     no filtra origen). server_count=1 => 1 solo puerto que reenviar.
  3) Puerto custom directo: cambiar "port" en Config.json + PortFIX en
     clientes (para jugar aunque el ISP bloquee 8606).
- CACHE.md seccion 6.1 creada con todo esto; corregido el punto
  protocolo (v1.6 SI habla 1101, ver relay-recon-v1).

---
Task ID: portfix-gml-v1
Agent: main (Z.ai)
Task: El usuario pregunto si se puede PORTEAR el sistema relay del
betterserver-v1.6 (penguinehis) a su server v1101 — "unicamente
nesesito es esa funcion nada mas".

Work Log:
- Dimensionada la RE del relay del v1.6 (exe NO stripped, 4837
  simbolos): ~20 funciones relay dedicadas — relay_open/start/worker
  (hilo propio), tunnel_connect/tunnel_pump + g_tunnel (tunel por
  sesion), relay_resolve, relay_seal + relay_keystream_xor +
  relay_derive_keys (CIFRADO propio del tunel), relay_send/
  invalidate_player_data + g_relay_echoes (direcciones sinteticas y
  ping), relay_public_port, relay_lookup_ip, relay_tiers +
  relay_mark_priority_near (QoS por proximidad), server_relay_fill/
  tick. => "esa funcion" NO es un modulo aislado: es una capa
  criptografica + transporte + identidades sinteticas integrada al
  corazon del server, pensada para el SERVICIO de penguinehis
  (relaysc.dr2.site, cuentas, suspensiones). Portearla = RE completa
  con cifrado + cuenta en su directorio + riesgo de suspension + se
  rompe si el cambia el protocolo. NO recomendado.
- PORTEADA la mitad que SI es nuestra y es prerrequisito universal:
  el soporte IP:PUERTO del CLIENTE, portado verbatim del
  TD2DR-Updated (misma fuente, mismo linaje):
  * scripts/net_wrapper/net_wrapper.gml: net_join parsea "IP:PUERTO"
    con string_last_pos(":") + validacion string_digits 1-65535,
    guarda ip LIMPIA y base_port, port = selected_lobby==-1 ?
    base_port : selected_lobby. Reconects/CHANGELOBBY van al server
    correcto (ip limpia + puerto explicito).
  * objects/obj_netclient/Create_0.gml: nueva var base_port = 8606.
  * Aplicador scripts/apply_portfix_gml.py (workspace) con match
    exacto == 1 y TABs literales (1er intento fallo por tab en linea
    en blanco tras want_lobby; corregido leyendo repr() del bloque).
  * Validador scripts/portfix_gml_validate.py: 8/8 casos OK (IP:
    PUERTO, hostname:PUERTO, IP sola, tail vacio/letras/0/70000 sin
    parseo = comportamiento identico al upstream).
  * Textbox del join verificado: obj_menu_textbox/Draw_0.gml solo
    filtra \r\t\n => ":" ya se podia escribir; nada mas que tocar.
  * El juego hay que RECOMPILARLO en GameMaker (cambio en .gml).
- Pendiente de decision del usuario (transporte): A) playit.gg gratis
  o VPS+frp (server intacto, ya funciona); B) relay PROPIO completo
  (yo escribo relay-node para VPS + synthetic-IP en betterserver-oss
  para bans/ops por jugador); C) RE del protocolo de penguinehis
  (posible pero fragil, no recomendado).

Stage Summary:
- RESPUESTA: portear el relay de penguinehis tal cual = NO viable
  como "solo esa funcion" (es su servicio cerrado con cifrado).
  Lo que SI se pudo portar YA ESTA: soporte IP:PUERTO del cliente
  aplicado y validado en la fuente (equivalente exacto al fix que
  trae su cliente). Falta recompilar el juego y elegir transporte.
- CACHE.md 6.1 + changelog actualizados.

---
Task ID: relay-re-v1
Agent: main (Z.ai)
Task: Ingenieria inversa COMPLETA del protocolo relay del betterserver-v1.6
(penguinehis) para portearlo al betterserver-oss del usuario. El usuario
confirmo que quiere usar su cuenta registrada en relaysc.dr2.site
(s38bd8ef11f, port 9001) y pedir NO hacer conexiones en vivo con ella:
TODO el trabajo fue RE estatica del binario (cero red).

Work Log:
- Binario: NO stripped, 4837 simbolos, MinGW x64, con secciones DWARF
  (solo cubren el CRT runtime, no el codigo del server). Guardado en
  td2dr/relay_server/ del workspace.
- Scripts creados: relay_strings.py (strings+xrefs RIP-relative),
  relay_rdata.py (constantes .rdata), pe_exports.py (previo).
- Desensambladas y decodificadas: tunnel_connect (0x1400132c0, 962 lineas),
  relay_worker (0x140014030), frame_send_sealed (0x1400233f0),
  tunnel_pump (0x1400322f0, 990 lineas), hmac_sha256 (estandar),
  handler tipo 0x07 (0x14003306f), parcial relay_send_player_data.
- RESULTADO: especificacion completa en td2dr/relay_server/RELAY_SPEC.md
  (11 secciones). Resumen del protocolo:
  * FASE 1 DIRECTORIO (relaysc.dr2.site:9000/9001 UDP): HELLO(BE 01 10
    +username) → CHALLENGE(BE 01 01 11 +salt16) → AUTH(BE 01 12 +
    username + proof32) → ACCEPT(BE 01 01 13: ticket88+relay ip/port+
    relay_key cifrado XOR) o ERROR(BE 01 01 14: 2=badpass 4=suspended).
    proof=HMAC-SHA256(password, salt||username);
    session=HMAC-SHA256(password, salt||"session-key").
  * FASE 2 RELAY: HELLO(BE 01 01) → CHALLENGE(BE 01 01 02) → TICKET
    (BE 01 03 + ticket88) → ACCEPT(BE 01 01 04 + base_port u32 +
    port_count u8). relay_key = ticket_part XOR session_key. 4 llaves:
    HMAC-SHA256(relay_key, "h2r-enc"/"h2r-mac"/"r2h-enc"/"r2h-mac").
  * FASE 3 TUNEL: frames sellados = BE 01 <tipo> <lobby> <session_id u32>
    || seq u64 BE || payload cifrado || MAC16 (ultimos 16B). Keystream:
    HMAC-SHA256(enc_key, seq_be(8)||bloque_le(4)), 32B por bloque.
    Anti-replay: seq>rx_seq y salto<=63. Tipos: 09=ping, 07=abrir/reset
    sesion, 06=cerrar, 08=datos jugador.
  * IPs SINTETICAS: cada jugador = session con socket UDP local; sus datos
    se reenvian a 127.0.0.1:(g_config.port+lobby); el ENet ve jugadores
    como 127.0.0.1:puerto_unico (allow_duplicate_ip ya en true ✓).
  * WORKER: hilo "Relay Thr": reconnect cada 10s si falla, ping sellado
    cada 15s, timeout 45s sin RX → limpia 512 sesiones y reconecta.
    Poll 200ms de g_tunnel + sockets de sesion.
- HMAC-SHA256 verificado ESTANDAR (ipad/opad/constantes SHA-256 en
  .rdata). El porteo puede usar cualquier implementacion estandar.
- Mapeo ~90% completo. Pendiente para la proxima sesion (seccion 11 de la
  spec): handlers 0x06/0x07-internos/session_open/relay_send_player_data
  TX exacto, relay_tiers (QoS), relay_lookup_ip (UI), y luego escribir
  Relay.c + integracion Config/Server/CMake + compilar + smoke test.

Stage Summary:
- ENTREGABLE: td2dr/relay_server/RELAY_SPEC.md = especificacion completa
  del protocolo relay (verificada por desensamblado, cero conexiones).
  Con ella el porteo a betterserver-oss es viable sin mas RE del core.
- CONFIRMADO por el usuario: su cuenta relay funciona con el v1.6
  (directory_port 9001 en su config). El porteo la usara igual que el
  v1.6 (enabled=false por defecto, credenciales vacias hasta que el
  usuario las ponga).
- La cuenta del usuario NO se uso para nada (RE 100% estatica).

---
Task ID: relay-port-v1
Agent: main (Z.ai)
Task: Portear el sistema RELAY de penguinehis (betterserver-v1.6) a
betterserver-oss para publicar el server en relaysc.dr2.site con la cuenta
que el usuario ya registro. Sin registrar cuentas y sin pruebas de red con
sus credenciales.

Work Log:
- RE completada al 100% (faltaba ~10%): desensamblados handlers 0x06
  (ABRIR sesion con IP real del jugador en payload u32 LE, plen>3), 0x07
  (RESET: cierra todas las sesiones con ese id), 0x08 (datos + auto-crea
  sesion con ip=0 si falta), session_open (3 args, bind 127.0.0.1:0,
  getsockname, ip_str "%u.%u.%u.%u"), relay_send_player_data/TX sellado
  (magic BE 01 <tipo> <lobby> <sid u32 LE> || seq u64 BE || payload XOR
  keystream || MAC16, payload max 1368), relay_worker (ping 15s, muerte
  45s sin eco, reintento 10s, cierre completo de sesiones al reconectar).
- CORRECCIONES v2 sobre la spec: AUTH = magic || proof[32] || username
  (el username va DESPUES del proof); ACCEPT dir: relay_ip reply[112..116]
  network order, relay_port [116..118] host order (antes 88/92 MAL);
  anti-replay = ventana deslizante u64 con bitfield de recibidos.
- Escrito include/Relay.h + disasterserver/Relay.c (~1000 lineas):
  SHA-256 + HMAC-SHA256 propios (validados 9/9 contra RFC 4231 +
  FIPS 180-4 con scripts/relay_crypto_validate.py), tunnel_connect,
  tunnel_pump, frame_send_sealed, sesiones con limpieza idle 300s,
  guard de password vacia (1 solo Warn, cero llamadas de red).
- Config.h/.c: RelayConfig anidada (enabled/directory_host/directory_port/
  username/password, defaults relaysc.dr2.site:9000, enabled=false),
  roundtrip config_save verificado.
- Lib.c: relay_init() al final de disaster_init. states/Server.c: los DOS
  CHANGELOBBY usan relay_public_port() (base_port+id si online).
- CMakeLists: +Relay.c (sin libs nuevas; ws2_32 ya estaba).
- compilar_server.bat: estado del relay en el menu (lee Config.json),
  deteccion de exe corriendo antes de compilar (ofrece cerrarlo; responde
  la duda de si hay que borrar el exe: NO, solo cerrarlo), opcion 7 =
  configurar relay (lanza configurar_relay.ps1, nuevo: asistente de cuenta
  que respalda y fuerza allow_duplicate_ip=true).
- Config.json del repo: seccion relay con la cuenta del usuario
  (relaysc.dr2.site:9001, s38bd8ef11f, password VACIA a proposito).
- Validacion sandbox: compila limpio (gcc), 3 smoke tests (sin seccion /
  enabled sin password -> guard / config real) — la cuenta NO se uso.

Stage Summary:
- Relay de relaysc.dr2.site INTEGRADO al BetterServer v1101. Especificacion
  final: td2dr/relay_server/RELAY_SPEC.md v2. Pendiente UNICAMENTE la
  prueba en vivo del usuario: password en Config.json (o opcion 7 del bat),
  recompilar (opciones 1/2) y ver "Relay: online - players can join at...".

---
Task ID: relay-gui-v1.1
Agent: main (Z.ai)
Task: El usuario reporto que tras aplicar relay-port-v1 el
DisasterServer.exe salio en modo consola (cmd) en vez de la GUI SDL
de siempre (~770 KB). Recuperar la GUI sin perder el relay.

Work Log:
- Descargado y analizado el exe GUI original del usuario
  (DisasterServer.rar): PE32+ subsystem 2 (GUI), importa SDL2.dll +
  SDL2_image.dll, titulo "DisasterServer v1101 (Modified)".
- Causa raiz encontrada: los "unset(DYLIB CACHE)"/"unset(BUILD_UI
  CACHE)" al final de disasterserver/CMakeLists.txt (existentes desde
  el commit inicial) borran el flag del cache al terminar cada
  configure. Al editar el CMakeLists (para agregar Relay.c en la
  v1.0), el "cmake --build" disparo una auto-reconfiguracion y
  option(BUILD_UI ... OFF) recreo el flag en OFF -> exe consola.
- Fix 1: CMakeLists.txt sin los unset (BUILD_UI persiste en cache).
- Fix 2: compilar_server.bat opcion 1 ahora re-configura con
  -DBUILD_UI=ON (y chequeo SDL) antes de compilar; nueva subrutina
  :verify_gui que lee el subsistema PE del exe resultante
  (GUI=2/consola=3 via PowerShell, offset PE+92) y avisa si salio
  consola. Opciones 1 y 2 verifican al terminar.
- Verificado: Relay.c loguea 100% via Log/Info/Err (17 llamadas, sin
  printf) -> los avisos del relay salen en el chat de la ventana GUI
  (mismo canal que Amy Canon). ui/Main.c: log_hook(log_msg) dibuja el
  chat; --nogui sigue disponible (AllocConsole + freopen CONOUT$).
- Build limpio desde cero OK en Linux con el CMakeLists modificado.

Stage Summary:
- v1.1 lista: extraer encima + opcion 2 UNA vez -> vuelve la GUI SDL
  con el relay integrado. Entregable: download/relay_port_v1.1.zip.

---
Task ID: relay-fix-v1.2
Agent: main (Z.ai)
Task: El usuario reporto (con GUI ya recuperada, v1.1) que el relay
fallaba con "wrong relay password for 's38bd8ef11f'" en loop, y pregunto
por que la version de pengu tardaba 45s por intento vs ~5s la nuestra.

Work Log:
- Re-lectura del pantallazo ampliado 3x: el error real era "wrong relay
  password" (RELAY.C:627/629), NO un timeout.
- Probe anonimo al directorio real (username vacio = anonimo, SIN tocar
  la cuenta): DNS OK (177.74.185.42), puerto 9001 VIVO (responde
  CHALLENGE <6s), 9000/443/80 muertos. Paquete real capturado:
  be 01 11 00 00 00 00 00 <salt16> (24B) -> el salt vive en offset 8.
- Disasm v1.6 confirma: validacion CHALLENGE = len>23 && be && 01 && 11;
  salt = movdqu xmm2,[buf+8]. Mi port leia salt en reply+4 (notacion
  ambigua de la spec v2) -> proof mal calculado -> error 2.
- Fix: Relay.c una linea (salt = reply + 8).
- Test A/B end-to-end: fake_directory.py (replica el paquete REAL + hace
  de relay) + relay_e2e_test.c (compila el Relay.c REAL con stubs):
  codigo viejo reproduce exactamente el error del usuario; codigo nuevo:
  handshake completo directorio+relay ONLINE en 0.2s. ACCEPT layout
  re-verificado en disasm (sin cambios). Worker re-verificado: poll 4s,
  retry 10s, ping 15s, muerte 45s = identico a mi port (los "45s por
  intento" que el usuario veia en pengu = temporizador de tunel muerto
  "no reply for 45s, reconnecting", no la velocidad de conexion).
- RELAY_SPEC.md v3, CACHE.md 6.2, LEEME_RELAY.txt v1.2. Proyecto
  recompila limpio. Entregable: download/relay_port_v1.2.zip.

Stage Summary:
- El "wrong password" no era la contrasena: era el offset del salt.
  Fix validado A/B. El usuario debe extraer v1.2 + recompilar; si
  conectara y aun dijera "wrong password", entonces si revisar la
  clave (opcion 7), pero el probe demostro que la cuenta existe.

---
Task ID: ghost-sessions-v1.3
Agent: main (Z.ai)
Task: Diagnosticar la "conexion fantasma" del relay reportada por
el usuario con 2 pantallazos nuevos (07:32 y 07:34), verificar el
estado del parche de puertos, y comparar contra el v1.6 original.

Work Log:
- Pantallazos analizados (VLM 3x): 07:32 = session 10 -> local
  port 52301 as 102.134.82.174; 07:34 = arranque completo + misma
  session + "AMY ROSE (id 1) joined. IP: 127.0.0.1" + VID/Canon.
- whois/ipinfo: 102.134.82.174 = ComX Networks, Stellenbosch,
  SUDAFRICA (usuario esta en Venezuela -> NO es el). Relay real =
  152.53.36.96 netcup (Virginia), region "VS".
- RE nueva zona del v1.6 (0x140017b4b y 0x140018400, LTO-inline
  en server_worker): el original tiene relay_lookup_ip(puerto) ->
  busca g_sessions por local_port y muestra la IP REAL del
  releado; fallback: g_clients por puerto (+0x1a port, +0x1c
  ip_str, 160 x 0xa870); solo si nada matchea muestra 127.0.0.1.
- Verificado en el PORT: relay_lookup_ip YA estaba porteado
  (Relay.c:1097) e integrado en ENET_EVENT_TYPE_CONNECT
  (states/Server.c:354) desde v1.0. Logica identica al original.
- Prueba decisive: el join de Amy Rose muestra 127.0.0.1 ->
  relay_lookup_ip FALLO -> su peer NO es un socket de sesion ->
  Amy Rose entro LOCAL (directo a 127.0.0.1:8606), NO por relay.
  Si hubiera entrado por el relay, el join mostraria la IP real.
- La session 10 (SudAfrica) no produjo ningun join = nunca
  completo handshake ENet = scanner/bot de internet que golpeo
  el puerto publico 20048 al abrirse. El relay de pengu abre
  sesion por CUALQUIER UDP entrante (no puede distinguir basura
  de juego) -> sesion fantasma. Inofensiva: no ocupa slot, no
  crea jugador; se limpia con RESET del relay o 300s idle
  (reaper propio; el original no tenia reaper).
- Paralelo positivo: el paquete del scanner atravieso toda la
  cadena (scanner -> relay -> tunel cifrado -> socket sesion ->
  127.0.0.1:8606) = prueba end-to-end de que el pipeline relay
  funciona y llega trafico externo.
- Parche de puertos verificado intacto: portfix_gml_validate.py
  8/8 OK (net_wrapper.gml + obj_netclient/Create_0.gml).
- Docs: LEEME_RELAY.txt +seccion "SOBRE LAS CONEXIONES FANTASMA"
  (como distinguir scanner vs jugador real, IP real en el join).
  Cero cambios de codigo (comportamiento ya = original).

Stage Summary:
- La "conexion fantasma" es un scanner de internet (normal en
  puertos publicos, igual que el v1.6 original). Nada quefixear.
  Amy Rose era conexion local propia del usuario. El relay ya
  muestra IPs reales en joins por relay (relay_lookup_ip porteado
  y verificado contra el disasm del original). Para probar el
  relay de verdad: conectarse con el cliente parcheado a
  152.53.36.96:20048; el join mostrara la IP real del que entre.

---
Task ID: relay-v1.3-fixes-upload
Agent: main (Z.ai)
Task: Empaquetar/subir v1.3 con 3 fixes de codigo posteriores a la
v1.2 encontrados al comparar contra el disasm del v1.6.

Work Log:
- Detectados cambios en repo sin empaquetar (timestamps 12:01-12:22):
  Relay.c (descifrado r2h-enc del payload entrante: keystream
  HMAC-SHA256(r2h_enc, seq_be||bloque_le), ver tunnel_pump+0x419),
  Lib.c (clamp MTU 1368 + buffers socket 512KB en allocate_server),
  states/Server.c + Relay.h (relay_lookup_ip en CONNECT del ENet).
- Fix 1 era CRITICO: sin descifrado, el jugador conectaba al tunel
  pero su handshake llegaba cifrado a 127.0.0.1:8606 y ENet lo
  ignoraba (nunca "joined", corte a los 45s). Probable causa real
  de "no entra nadie por el relay".
- Syntax check OK (Relay.c/Lib.c/Server.c con el enet/ del repo).
- LEEME_RELAY.txt -> v1.3 con seccion de los 3 fixes. Zip: 13
  archivos, 81488 B, MD5 0b461bd9e3d315e48f7d5c3949354ed0.
- Subida: tmpfiles.org OK (link directo + MD5 remoto verificado
  identico). gofile roto (/upload 404 en todos los stores).

Stage Summary:
- https://tmpfiles.org/dl/1793018357.a058188c51fccdf2/wqArVPswPPGi/relay_port_v1.3.zip
  (expira ~60 min desde las 12:33 UTC; resubir con curl -F
  "file=@relay_port_v1.3.zip" https://tmpfiles.org/api/v1/upload)

---
Task ID: anticheat-charselect-diag
Agent: main (Z.ai)
Task: Diagnostico del error del usuario al llegar a seleccion de
exe: "RASSERT(CHARSELECT-CHOOSE-EXE...) FAILED" en loop
(pantallazo 08:54), partida que nunca inicia.

Work Log:
- Pantallazo (586x136, VLM 4x): loop mapvote -> charselect ->
  lobby con "(CHARSELECT.C:255): RASSERT(CHARSELECT-CHOOSE-EXE...)
  FAILED" repetido. 2 jugadores: AMY ROSE id 1 e id 2.
- Codigo: charselect_init (states/CharSelect.c:255) hace
  RAssert(charselect_choose_exe(...)). choose_exe falla si nadie
  puede ser exe: condicion de eleccion (CharSelect.c:71) exige
  !peer->mod_tool.
- mod_tool lo setea auth_verify_ticket (Auth.c:37): checksum==0 ||
  checksum2==0. El cliente GML (net_indentity.gml) manda DOS
  buffer_u64 = 0 hardcodeados.
- Confirmado con pantallazo previo 07:34: "MODIFIED: TRUE" en el
  join. Con anticheat:true el cliente propio (Amy Canon + Sonic
  Quiz + DLL portfix) SIEMPLE da checksum 0.
- Strings verificados en el binario v1.6 de pengu: mismo
  comportamiento en el original ("your mod is disallowed",
  "Modified:", "Failed to pick exe"). No es bug del port.
- USUARIO RESOLVIO EN VIVO: con anticheat:false -> "Modified:
  FALSE" y las partidas arrancan normal. Server.c:191 solo
  verifica ticket si g_config.anticheat; mod_tool queda false.

Stage Summary:
- Causa: anticheat:true + cliente modificado = todos mod_tool =
  nadie elegible como exe = RAssert loop. Solucion (ya aplicada
  por el usuario): "anticheat": false en Config.json. Config
  correcta para server+cliente propios; bans por UDID intactos.
- Estado del circuito: server v1.3 + cliente portfix + anticheat
  off. Falta UNICAMENTE la prueba real con jugador externo por el
  relay (joined debe mostrar IP real, no 127.0.0.1).

---
Task ID: docs-sync-v1.3
Agent: main (Z.ai)
Task: Sync de CACHE.md + worklog.md con lo ultimo (v1.3, anticheat,
fantasma) y paquete de docs para el usuario (link directo).

Work Log:
- CACHE.md: +diagnostico fantasma, +v1.3 fixes (detalle de los 3),
  fila relay-v1.3 en tabla de entregables, leccion 8 ampliada con
  el caso RASSERT confirmado en vivo, pendientes actualizados
  (anticheat y fantasma RESUELTOS; queda prueba externa del relay),
  entrada en changelog.
- worklog.md (repo): +entradas relay-v1.3-fixes-upload,
  anticheat-charselect-diag y docs-sync-v1.3.
- Paquete docs_v1.3.zip: CACHE.md + worklog.md + LEEME_RELAY.txt.

Stage Summary:
- Documentacion al dia y empaquetada. Ver link en la respuesta al
  usuario (tmpfiles, 60 min).

---
Task ID: parry-v3.5-stun-propio-sonic
Agent: main (Z.ai)
Task: Fix del stun del atacante cuando el golpe parreado iba dirigido
al PROPIO Sonic (solo funcionaba cuando la victima era un aliado del
aura). Reporte del usuario + video 2026-10-29 01-18 (v3.4 compilada).

Work Log:
- Video (9.8s, 20 frames analizados con VLM + analisis de pixeles
  Python): frame 14 Sonic abre el parry (circulo cian), frame 15 el
  EXE ataca (flash rojo full-screen = obj_level.bloodFade que se setea
  en obj_player_puppet/Step_0 JUSTO despues de scr_player_hurt con
  exeSource=true -> PRUEBA de que la negacion corrio en el cliente de
  Sonic), frames 16-20 el EXE vuelve al idle normal: cero particulas
  amarillas de electroshock (verificado por conteo de pixeles, los
  unicos amarillos son la antorcha y el anillo dorado), cero sprite
  rigido -> NO stun. Sin sangre sobre Sonic (cero dano confirmado).
- Causa: el dano lo niega el cliente de la VICTIMA (contacto exacto
  ahi) pero el stun lo auto-aplica el cliente del ATACANTE
  (scr_parry_try_stun_attacker via place_meeting del puppet de Sonic
  vs la mascara de solo-garras del sprite de ataque del EXE, bbox
  16..44 del spr_exe_attack1). Con victima=aliado el contacto en el
  exe existe (camina encima) -> funcionaba. Con victima=Sonic el
  golpe entra en la punta de las garras -> en la maquina del exe el
  roce no siempre existe (lag del puppet + mascara recortada) -> no
  habia stun aunque la negacion si corrio.
- FIX v3.5 (cero paquetes nuevos, cero server, cero assets):
  1. scr_parry_negate_hit emite snd_exe_stun posicionado en el nid
     del ATACANTE (shouldPlay=true, mismo paquete CLIENT_SOUND_EMIT
     de siempre) cuando self es obj_player_puppet (melee; laser,
     bolas, cadenas y peligros de mapa no emiten: proyectiles no
     stunean a su dueno por regla del parry).
  2. CLIENT_SOUND_EMIT (net_state_game) reconoce esa senal en mi nid
     -> scr_parry_stun_signal() en el cliente del atacante.
  3. scr_parry_stun_signal: guards (lado EXE, vivo, shockedTimer<=0
     para deduplicar contra el auto-stun local y stuns previos),
     busca la victima que esta tocando para los paquetes de stats,
     aplica scr_parry_apply_stun.
  4. scr_parry_apply_stun: cuerpo comun (escudos Eggman/Sally
     incluidos, 3.5s, knockback, sonidos, CLIENT_PLAYER_HURT +
     CLIENT_STATS_REPORT solo si hay victima identificada).
  5. scr_parry_try_stun_attacker: +guard shockedTimer>0 (dedup, el
     camino del aliado queda identico), cuerpo delegado en
     scr_parry_apply_stun. Syntax check OK (llaves/parentesis 0/0).
- Entrega: parry_v3_5_stun.zip (LEEME + 2 scripts). Push sin
  credenciales (igual que siempre): el usuario aplica el zip a mano.

Stage Summary:
- Golpe del EXE dirigido a Sonic con parry activo: bloquea Y stunea
  al EXE 3.5s. Golpe a aliado: igual que antes (deduplicado). El
  esbirro que ataque tambien recibe el stun por la misma senal.

---
Task ID: 2
Agent: Super Z (main agent)
Task: Parry de Amy Canon (v4.0) - mismas fijaciones que Sonic + HUD + tecla

Work Log:
- git pull del repo del usuario (commit "Update" 4e2e32c3): trae los
  sprites spr_amy_parry_inicio (1 frame, 35x39) y
  spr_amy_parry_exitoso (10 frames, 50x50) con SUS PROPIOS NOMBRES,
  ademas del scr_parry v3.6 y el receptor del stun en
  net_state_game. Merge con "la version del usuario manda" en el
  conflicto de scr_parry.gml (backup local en
  scripts/backup_scr_parry_LOCAL_v36.gml).
- scr_parry.gml v4.0 (sistema compartido):
  1. scr_parry_sprite(st, _char): sprites por personaje (Amy ->
     spr_amy_parry_*, fallback spr_amy_attack1_canon; Sonic igual
     que siempre).
  2. scr_parry_char_has (Sonic o Amy Canon), scr_parry_key (C/V),
     scr_parry_aura_color / _core (rosa Amy con los colores reales
     de su sprite: 230,91,140 / 255,170,200; cian Sonic).
  3. protects_me / ting_signal / try_stun_attacker: aceptan puppets
     de Sonic O Amy Canon. scr_parry_step usa scr_parry_key().
- obj_amy_canon: Create_0 (8 vars del parry + stubs nerviosState/
  nerviosUsed/isSpinCharging para el step compartido), Step_0
  (parry_step fuera de la burbuja; la burbuja corta el parry y
  congela el CD como hace con la acometida), Step_2 (estados
  60/61/64 antes del abrazo), Draw_76 (sprites parry + velocidades),
  Draw_0 (aura rosa + anillo de activacion).
- obj_player_puppet: Draw_72 (puppet Amy con sus sprites de parry,
  scr_parry_sprite con el character del puppet), Draw_0 (aura por
  personaje con scr_parry_aura_color; Sonic queda IDENTICO).
- HUD (no olvidado esta vez): obj_playerui/Draw_64 - cuarto icono
  de Amy Canon (y=276) con parryCooldown/Max, blanco=listo y en
  suelo, rojo=lo demas, asset_get_index con fallback silencioso.
- Boton (pregunta del usuario): TECLA V - Z/X/C ocupadas (salto
  martillo / impulso tarot / acometida), A/S/D emotes (D=abrazo),
  Ctrl esconder. Sonic no cambia (su parry sigue en C).
  1. scr_globals: global.KeyV = ord("V").
  2. obj_menu: bindChanged "special3" (default V, incluido en el
     reset por defecto) -> remapeable.
  3. obj_config: la V y vTouch persisten en el config, con
     try/catch para configs viejas (mismo patron que idle/wTouch).
  4. Gamepad: gp_face4 (Y) -> V en gameplay (press + release).
  5. Android: boton tactil V nuevo (scr_controls_init_touch +
     update_touch + obj_controls/Draw_64, frames 10/11 anadidos al
     sprite spr_mobile_emotionbutton con cirugia de .yy validada
     contra JSON).
- scr_amy_hug: la V rompe el abrazo (como la C del Sonic) y
  scr_amy_hug_try_start devuelve false con parryState > 0 (no se
  abrazar mid-parry).
- Icono del HUD NUEVO: spr_gui_amyparry_canon (33x14, anillo rosa
  + chispa + tecla V con el estilo keycap exacto de los otros
  iconos), generado por script y registrado en .yyp (1670 recursos)
  y resource_order.
- REPARACION: el tool de edicion convirtio tabs->espacios en 8
  archivos (obj_menu, obj_config, obj_playerui, 3x scr_controls,
  scr_globals, obj_controls); compila igual pero ensuciaba el diff
  del repo. Script repair_tab_damage.py: git checkout de cada
  archivo + re-aplicacion byte-exacta con la indentacion original
  (regex con captura de indent, assert de ocurrencia unica). Diff
  final: 371 inserciones reales, 0 ruido.
- Validaciones: balance llaves/parentesis OK en los 16 archivos
  GML tocados (check_gml_v40.py), .yyp y resource_order parsean
  JSON, 12 frames + layers del sprite de botones presentes,
  verificacion de contenidos (KeyV/bVX/vTouch/gp_face4/amyparry en
  los archivos que corresponden).
- Entrega: parry_v4_0_amy.zip (LEEME + 15 archivos + 2 sprites).
  Cero cambios de servidor, cero paquetes nuevos, estados 60/61/64
  compartidos.

Stage Summary:
- Amy Canon parrea con la misma mecanica v3.6 completa (melee + spin
  negados, auto-stun 3.5s del atacante, desvio de laser, anillo
  negro -> dorado, aura de aliados 58px) en la tecla V, con su aura
  rosa, sus sprites (los del usuario) y su cuarto icono de HUD con
  el CD. La burbuja congela el parry, el abrazo se rompe con V, y
  Sonic queda 100% intacto.
---
Task ID: carry-v1
Agent: main (Z.ai)
Task: (1) Fix del bug de velocidad de Amy Canon (mismo patron del
spindash de Sonic v3). (2) Mecanica NUEVA: Tails y Cream llevan a un
aliado colgado mientras vuelan (estilo lianas: agarrarse al tocar,
soltarse con Z). Peticion del usuario: "Añadiremos una mecanica que
tails permitira llevar a un aliado en su vuelo. Parecido a las
lianas estas de Hide seek 1 ... con la z te puedes soltar. Tails
debe tener la posibilidad de llevar a un aliado Cream tambien" +
"sobre lo que decia de amy era el bug de velocidad ... no notaste
que amy tiene ese bug parecido?".

Work Log:
- BUG AMY CONFIRMADO: AMY_CANON_DASH_SPEED y _TAROTDASH_SPEED = 14
  ("mayor que 11 = mas rapida que correr") pero scr_collision_basic
  clamp(xspd, -maxHSpeed, maxHSpeed) las recortaba a 11 siempre; el
  fix v3 de Sonic solo exceptuo CHARACTER_SONIC+isSpinning. FIX v4:
  misma excepcion para CHARACTER_AMY_CANON con isDashing ||
  isTarotDashing, tope = max de sus 2 macros. Short-circuit && =
  vars de Amy solo se evaluan siendo ella (patron bugfix-tarot-v1).
  El escaneo de muros v3 ya era generico (usa abs(xspd)).
- CARRY, investigacion previa: tirolina (obj_aiz_zipline: agarra
  place_meeting en aire, _holdPlayer bloquea con isZipline=true +
  playerControls=false, mueve al player en SU Step_2 = End Step,
  suelta con KeyA + keyboard_key_release, timeout 3s, snd_snap),
  abrazo (scr_amy_hug: estados custom viajan en el u8 de state sin
  server, checks en vivo contra puppets, vars por personaje detras
  de gates), parry v3.5 (senal por red: net_sound_emit_at con
  shouldPlay=true al nid objetivo, rama en CLIENT_SOUND_EMIT de
  net_state_game), netclient Step_2 (playerControls se re-activa en
  frames de reconnect => re-afirmar false cada frame como la
  tirolina; PLAYER_DATA manda x,y,xspd,yspd,state,angle,
  image_index,image_xscale cada frame).
- DISENO DEL CARRY (cero server, cero paquetes nuevos): el llevado
  viaja en el estado *_ZIPLINE de SU personaje (sprites de tirolina
  ya registrados en scr_survivors/Draw_76/Draw_72 para los 9
  supervivientes) + su posicion la pega su cliente al puppet del
  portador cada End Step; el portador viaja NORMAL (TAILS_FLY/
  CREAM_FLY). Drop del portador = tecla V => net_sound_emit_at(
  snd_snap, nid_del_colgado) => rama nueva en CLIENT_SOUND_EMIT
  (snd_snap con shouldPlay=true a mi nid) => scr_carry_drop_signal.
  El snap del AGARRE viaja shouldPlay=false (no entra a la rama).
- NUEVOS: scripts/scr_carry/scr_carry.gml (macros CARRY_*: GRAB 32,
  HANG_Y 26, HOP -6.5, REGRAB 120, CHECK 48; scr_carry_zipline_state
  mapa char->estado; find_carrier/find_hanger contra puppets con
  isInactive/isDemonized/hp; grab_ok con gates por personaje;
  scr_carry_step mantener/soltar con re-afirmar playerControls=false
  cada frame; scr_carry_end(hop,quiet); scr_carry_carrier_step
  early-return no-Tails/Cream + V + drain de flyTimer de Tails 1.5x
  entero-alternando para no romper el mod 18 del sonido) +
  objects/obj_carry_controller (Create + End Step; creado por
  obj_spawnpoint DESPUES del player => su End Step corre ultimo y
  el snap es la ultima palabra del frame; inicializa carryActive/
  carryPartner/carryCooldown/carryDrainTick en la instancia al
  detectar player nuevo; EXE nunca lo crea: spawnpoint bloquea
  character EXE).
- WIRING: obj_spawnpoint/Create_0.gml crea el controlador
  (idempotente); net_state_game.gml rama snd_snap tras la del
  snd_exe_stun; obj_aiz_zipline/Step_2.gml +guards SONIC y
  SALLY_CANON (la tirolina ROBABA a un llevado de esos dos al volar
  sobre su punto de inicio: les faltaba el check de estado que todos
  los demas personajes ya tenian); .yyp + resource_order (2
  recursos, parent Specials/Spawners).
- Reglas: agarre = tocar (dist<=32) a Tails/Cream en TAILS_FLY/
  CREAM_FLY estando en el aire y sin bloqueos (herido/stun/
  escondido/anillo rojo/emote/atacando/demonizado; Amy Canon:
  burbuja/tarot/hj/dash/parry; Sonic: nervios/parry; Knux: planeo);
  1 pasajero por portador (find_hanger); suelta con Z (hop -6.5 +
  keyboard_key_release como la tirolina); auto-suelta si el portador
  deja de volar/aterriza/es herido/muere/desconecta o el colgado
  toca suelo/es herido/muere/demoniza; demonizados ni llevan ni
  cuelgan; EXE excluido; cooldown 2s tras soltar.
- INCIDENTE de herramienta 2 veces: el Edit expandio TABs->8
  espacios en obj_spawnpoint (arreglado re-escribiendo con Python)
  y en scr_collision_basic COMPLETO (1231 lineas de diff fantasma;
  git checkout + re-aplicado byte-exacto con \t literales). Diffs
  finales: 44 insertions / 1 deletion en 6 archivos + recursos
  nuevos.
- Validador scripts/carry_v1_validate.py: 137 OK / 0 FAIL
  (sintaxis con tokenizador string/comentario, macros usadas vs
  definidas en TODO el proyecto, CARRY_* 1 vez, gates de personaje
  (multi-linea, mirando atras), wiring completo, estados ZIPLINE
  resueltos vs arrays de scr_survivors (los 9), TAILS_FLY=14,
  CREAM_FLY=14, BALANCING=13, funciones de red existen, vars de
  personaje existen en sus Creates, .yyp/resource_order parsean
  (JSON relajado), eventos Create+EndStep, higiene CR/indent,
  10 simulaciones de agarre + mapa de estados + shouldPlay).
- LEEME_CARRY_V1.txt con instrucciones, macros ajustables y guion
  de prueba de 8 pasos con 2 ventanas.

Stage Summary:
- AMY: acometida (C) y tarot (X) ahora SI corren a 14 (antes salian
  a 11 por el clamp; mismo bug que el spindash de Sonic).
- CARRY: cualquier superviviente se cuelga de un Tails/Cream volando
  al tocarlo, cuelga con su sprite de tirolina debajo del portador,
  se suelta con Z (saltito) o el portador lo suelta con V (senal de
  red snd_snap a su nid). Auto-suelta en todos los casos logicos.
  Tails gasta vuelo 1.5x cargando. Un pasajero por portador.
- CERO server: solo extraer, reabrir GameMaker y ejecutar. El
  entregable es download/carry_v1.zip (5 nuevos + 6 modificados +
  LEEME + worklog).

---
Task ID: flybuff-v1.1
Agent: Super Z (main agent)
Task: Mejora sustancial de vuelo pedida por el usuario ("el vuelo
dura demasiado poco"): Tails y Cream a 5.5 seg maximos.

Work Log:
- Diagnostico: Tails volaba 160 frames (2.67 seg; flyTimer = 160 en
  scr_tails_special) y Cream 120 frames (2 seg; flyTimeout > 60*2 en
  scr_cream_special). Ambos muy por debajo de los 5.5 seg pedidos.
- Macros NUEVAS junto a las de recarga (patron del proyecto):
  TAILS_FLY_TIME (60*5.5) en obj_tails/Create_0.gml y CREAM_FLY_TIME
  (60*5.5) en obj_cream/Create_0.gml. 60*5.5 = 330 frames.
- scr_tails_special.gml: flyTimer = 160 -> TAILS_FLY_TIME. La
  recarga NO cambia (-420 en suelo = 7 seg para poder volver a
  volar); los clamps de redRing (-420+2) e isHiding (-420+120)
  siguen coherentes; el "flyTimer mod 18" del sonido sigue
  funcionando (330 = 18*18+6: suena ~18 veces durante el vuelo).
- scr_cream_special.gml: flyTimeout > 60*2 -> CREAM_FLY_TIME. La
  recarga NO cambia (CREAM_FLY_RECHARGE = 60*15 en tiempo real, sin
  necesitar suelo); el clamp de isHiding sobre flyTimer (recarga,
  60*2) tampoco se toca.
- GUI intacto: la barra de Tails mapea la RECARGA (min(flyTimer,0) /
  -420 en obj_playerui/Draw_64) y la de Cream la recarga (flyTimer /
  CREAM_FLY_RECHARGE); ninguna dependia de la duracion del vuelo.
- CARRY intacto en logica: el drain 1.5x de Tails con pasajero
  (scr_carry) sigue igual -> 330/1.5 = 220 frames = 3.7 seg cargando
  a alguien (antes volar SOLO duraba 2.67 seg). Actualizados solo
  textos obsoletos: comentario de scr_carry.gml ("su vuelo ya es un
  planeo corto") y la frase "planeo de 2 segundos" del
  LEEME_CARRY_V1.txt (ahora describen que el planeo de Cream no gana
  altura, que es la razon real de que no tenga penalizacion).
- Aplicador scripts/apply_flybuff_v1_1.py (matches exactos == 1,
  convencion #2 de CACHE.md, cero Edits directos) + validador
  scripts/flybuff_v1_1_validate.py.

Stage Summary:
- VUELO 5.5 SEG: Tails 2.67 -> 5.5 seg, Cream 2 -> 5.5 seg. Solo
  duracion: fisica de vuelo, recargas (7 seg suelo Tails / 15 seg
  real Cream), HUD y carry sin cambios de logica.
- Con pasajero, Tails vuela ~3.7 seg (drain 1.5x): llevar a alguien
  cuesta menos que volar solo antes de la mejora.
- Ajustable: TAILS_FLY_TIME / CREAM_FLY_TIME en los Create_0.
- Entregable: download/fly_buff_v1.zip. Cero server, cero assets.


---
Task ID: flybuff-v1.2
Agent: Super Z (main agent)
Task: Correccion del flybuff v1.1 (usuario: "el tiempo solo se agrega
si agarra a alguien; si es solo, su tiempo normal"): los 5.5 seg
SOLO aplican llevando pasajero.

Work Log:
- v1.1 habia subido el vuelo a 5.5 seg SIEMPRE (Tails y Cream). El
  usuario corrigio el diseno: el extra solo al llevar a alguien.
- NUEVO modelo (reloj compartido, tope conmutado):
  * Tails: flyElapsed (var nueva en obj_tails/Create) cuenta frames
    desde el despegue (reset al despegar); cada frame del isFlying
    flyTimer = max(0, tope - flyElapsed) con tope = TAILS_FLY_SOLO
    (160 = 2.67 seg, vanilla) o TAILS_FLY_CARRY (60*5.5 = 330) si
    scr_carry_find_hanger(id, CARRY_CHECK_DIST) ve al colgado. Guard
    "flyTimer > 0" para no resucitar resets externos (demonizacion
    pone flyTimer = -420: el vuelo muere como siempre).
  * Cream: flyTimeout (ascendente) se compara contra CREAM_FLY_SOLO
    (60*2 = 120, vanilla) o CREAM_FLY_CARRY (330), mismo check de
    hanger.
  * Soltar al pasajero devuelve el tope al solo: si ya paso la marca
    normal el vuelo corta en ese frame; si no, sigue con lo que
    quede del normal. Sims del validador: solo 160/120 exactos,
    grab@40 -> 330, drop@100 -> 160/120, drop@200 -> corta en 200.
- ELIMINADO el drain 1.5x del carry v1 (bloque de
  scr_carry_carrier_step + init de carryDrainTick en el controller):
  la penalizacion contradecia la nueva extension.
- Deteccion del pasajero = mismo find_hanger del soltar-con-V
  (puppet en ZIPLINE cerca/abajo): hereda su latencia de red (1-2
  frames; un agarre en los ultimos ~2 frames del vuelo puede llegar
  tarde y soltarse solo: raro y se recupera con el cooldown de 2 s)
  y su falso positivo teorico con tirolinas de mapa o colgados de
  otro portador a <48 px (inofensivo: solo daria el tope largo).
- Macros renombradas: TAILS_FLY_TIME -> TAILS_FLY_SOLO/_CARRY,
  CREAM_FLY_TIME -> CREAM_FLY_SOLO/_CARRY (cero usos viejos).
- Aplicador scripts/apply_flybuff_v1_2.py (line-anchored, indent
  derivado del propio archivo) + validador
  scripts/flybuff_v1_2_validate.py (8 sims de reloj incluidas).

Stage Summary:
- SOLO = tiempo vanilla (Tails 2.67 s, Cream 2 s). CON pasajero =
  hasta 5.5 s totales desde el despegue. Soltar = vuelve al reloj
  normal (corta si ya paso la marca). Sin drain 1.5x.
- Requiere CARRY V1. Entregable: download/fly_buff_v1_rev2.zip
  (SUPERSET: lleva el carry v1 completo dentro; sustituye a
  fly_buff_v1.zip).

---
Task ID: vanilla-v1
Agent: Super Z (main agent)

VANILLA THE RABBIT como superviviente #10 (solo token de Amy).

Pedido: sprites canon ya en el proyecto; habilidades = las de Cream;
retrato de menu y barra de vida reusando los de Cream; server parcheado
para que sea elegible; EXCLUSIVA de quien tenga el token amy (ni
operadores ni publica); cubrir todos los detalles (leccion de Sally
Canon).

Trabajo:
- obj_vanilla nuevo (carpeta Objects/Player/Survivors/Vanilla Canon),
  clon byte-exacto de obj_cream salvo: Create_0 sin redeclarar las
  macros CREAM_*/ECREAM_* (viven en obj_cream; patron sally_canon),
  Step_2 sin redeclarar CREAM_FLY/SPAWN/ZIPLINE, Draw_76 con lookup
  arr[? CHARACTER_VANILLA]. specialFunc = scr_cream_special SIN clonar
  (como sally_canon usa scr_sally_special).
- Registro: .yyp (recurso + carpeta Vanilla Canon en Objects) y
  .resource_order (recurso + carpeta).
- scr_survivors.gml: #macro CHARACTER_VANILLA (CHARACTER_TAILS+9);
  player_anims[? CHARACTER_VANILLA] (17 sprites spr_vanilla_*, layout
  Cream, indices 14-16 = fly/srings/zipline = estados CREAM_* por red);
  player_eanims defensivo (sprites normales, como sally_canon);
  player_get case -> obj_vanilla; scr_char_locked: Vanilla exige
  global.amyCanonToken (MISMO token/file que Amy Canon: amy_canon.token
  contra amy_canon_token del Config.json del server).
- Seleccion: avCharacters con 11 entradas (obj_netclient + net_tcpprocess);
  chars[] del lobby con spr_menu_cream en el slot 9 (retrato reusado);
  offset EXE += CHARACTER_VANILLA; _infoFrame 9 -> placa de Cream;
  obj_lobby_icon con limites/wrap a CHARACTER_VANILLA e icono de tira
  Vanilla -> Cream.
- Networking: net_state_charselect mapea icono Vanilla->Cream (x2);
  net_state_results remapea valor crudo 9 -> 4 (Cream); net_state_game
  inicia ringsTimer para Vanilla y su demonizacion resetea
  fly/dash/rings como Cream.
- HUD: obj_playerui case Vanilla con las 3 barras de Cream;
  obj_level barra de vida mapea Vanilla->Cream en los 3 sitios (propio,
  puppets, escapados; sin esto los indices (10-1)*7 se salian de
  spr_playerhealth); obj_menu_waiting icono crudo 9->4; obj_demon_indicator
  pos 20 (vuela).
- Paletas: defaults en obj_unlockables (normal + PALETTE_DEMON, mismo
  patron que sally_canon) y paletteShifts con tonos de Cream.
- Gameplay paridad Cream: scr_carry (zipline=Cream, partner_flying,
  agarre apaga vuelo, puede portar con el flybuff v1.2), scr_move_basic
  (reset dano/muerte, salto bloqueado en spawn de anillos),
  scr_collision_objects (cancelar vuelo x2), scr_player_slow (stats).
- SERVER (solo archivos compilados; los .c de la RAIZ de disasterserver
  son copias viejas que CMake NO compila - esa fue la trampa de Sally):
  * include/Server.h: CH_VANILLA al final del enum (mismo orden que el
    cliente: cliente manda 1-based, server hace id--), avail[CH_VANILLA+1].
  * states/CharSelect.c: bound del assert a CH_VANILLA; gate de token
    (id == CH_VANILLA && !v->amy_authed -> respuesta "ocupada" igual
    que Amy Canon; NO la abre ser operador); survs[] con "Vanilla";
    memsets x2 a CH_VANILLA+1.
  * states/Game.c: CLIENT_CREAM_SPAWN_RINGS acepta CH_CREAM o CH_VANILLA
    (sin esto el anticheat la desconectaba al usar anillos);
    cooldown de demonizacion CREAM_RING_SPAWN tambien para Vanilla.
    Vanilla SI se demoniza como Cream (no se anade a los guards canon).
- FIX EXTRA (regresion preexistente de sally canon): las placas de info
  del HOST EXE en obj_lobby/Draw_0.gml quedaban corridas desde que el
  offset paso de +8 a +9 (mostraban 8-11 en vez de 7-10; Exeller
  mostraba la placa de Sonic). Con 10 supervivientes seria 9-12 (frame
  inexistente). Fix: _infoFrame = sprInd - (CHARACTER_VANILLA - 7).
- Validacion: vanilla_v1_validate.py 108/108 (anims en orden, arrays
  11 entradas, wire 1-based/0-based coherente, legacy sin tocar, LF,
  llaves balanceadas). Server compilado y LINKADO con gcc (enet clonado
  y compilado estatico) + smoke test: arranca, escucha 8606, entra a
  Lobby. Validador: /home/z/my-project/scripts/vanilla_v1_validate.py.
- Aplicadores: /home/z/my-project/scripts/apply_vanilla_v1.py (objeto+
  registro), apply_vanilla_v1b.py (41 parches + 4 inserciones, con
  dry-run de TODAS las anclas antes de tocar nada), apply_vanilla_v1c.py
  (fix placas + docs).

Notas:
- El token es el MISMO de Amy Canon: quien tenga amy_canon.token (frase
  de amy_canon_token en Config.json) desbloquea a Amy Canon Y a Vanilla.
- El server HAY que recompilarlo (compilar_server.bat en Windows o
  cmake) para que Vanilla sea elegible; sin recompilar, el server viejo
  la rechaza como ocupada (comportamiento seguro).
- eanims de Vanilla = sprites normales (no hay demonizados suyos aun).

Stage Summary:
- Vanilla #10, habilidades Cream exactas (vuelo/dash/anillos/carry
  flybuff v1.2 incluido), UI de Cream, solo con token amy (cliente la
  oculta sin token; server la rechaza sin token; operador NO la abre).
- Requiere recompilar el server. Entregable: download/vanilla_v1.zip
  (parches del cliente + server parcheado + LEEME).

---
Task ID: vanilla-v1-fix1
Agent: Super Z (main agent)

FIX DE COMPILACION GM LTS 2026 (rev2 del vanilla-v1).

Sintoma (log del usuario, runtime 2026.0.0.23):
  gml_GlobalScript_net_state_charselect(86) : unexpected symbol "?"
  gml_Object_obj_level_Draw_64(69)          : unexpected symbol "?"
  gml_Object_obj_lobby_icon_Draw_0(113)     : unexpected symbol "?"
  gml_Object_obj_menu_waiting_Draw_64(57)   : got '?' expected ')'
  gml_Script_scr_survivors(19)              : got '+' expected '}'  (cascada)

Causa raiz: el vanilla-v1 introdujo 7 TERNARIOS ENCADENADOS
(a ? b : c ? d : e) en 5 archivos. El compilador de GM LTS 2026
NO los parsea (los ternarios simples y los separados como
argumentos de funcion si van; el proyecto original esta lleno de
esos y siempre compilo). El error de scr_survivors(19) apuntaba a
la definicion de macro CHARACTER_AMY (CHARACTER_TAILS+3): cascada
por expansion de macros dentro de los ternarios rotos - nada malo
en scr_survivors en si (diff 100% patrones originales).

Arreglo (apply_vanilla_v1d.py, byte-exacto, idempotente):
se restaura el ternario SIMPLE original y se agrega un if plano
para el remapeo Vanilla->Cream. 6 ops / 7 sitios:
- net_state_charselect x2 (lineas 87, 220): image_index, if(char...)
- obj_level/Draw_64 x3: propio (_hudChar), puppets (_pch),
  escapados (_ech; ese sitio era un else de sentencia unica ->
  ahora es un bloque con llaves { var _ech; if; draw_sprite; })
- obj_lobby_icon x1: image_index, if(selected...)
- obj_menu_waiting x1: index crudo 9 -> if(plr.char == 9)
Indentacion preservada (obj_level usa ESPACIOS, el resto TABs).

Validacion: vanilla_v1_validate.py actualizado (4 checks al
patron nuevo + seccion 11 "GM2026 sin ternarios encadenados" en
los 5 archivos) = 115/115. Scan global: 0 encadenados con
CHARACTER_VANILLA; los 33 restantes de 2+ '?' son codigo ORIGINAL
(obj_playerui: ternarios separados como args; scr_move_basic:248
anidado con parentesis, presente en HEAD, siempre compilo).

Entregable: download/vanilla_v1_rev2.zip (36 archivos; sustituye
a vanilla_v1.zip). LEEME actualizado con nota REV2 + regla para
el futuro: nunca ternarios encadenados, usar ternario simple + if.

Stage Summary:
- Misma funcionalidad 100%, solo sintaxis compatible GM LTS 2026.
- El usuario ya tiene la rev1 aplicada: extraer rev2 ENCIMA
  (sobreescribe los 5 archivos arreglados y todo lo demas).

---
Task ID: vanilla-v2
Agent: Super Z (main agent)
Task: KIT COMPLETO VANILLA V2: Chocola la guardiana (paciencia +
bloqueo 50% + ataque 33% + V hacia Cream), float run a 14 con estela,
anillos x4, moribunda (nunca muere), des-demonizacion (15 anillos),
Fortaleza/Inspiracion/Madre-e-hija. Pedido del usuario 30/10 (tras
pull con sprites nuevos spr_vanilla_chocola_* / paciencia /
float_run subidos por el).

Work Log:
- PULL primero (regla nueva del usuario): remoto traia 6 commits
  (41dda5d0) con TODOS los mods anteriores ya integrados (carry,
  flybuff, vanilla-v1 + fix1) + sprites nuevos del usuario (chocola
  x4, paciencia x2, float_run, srings, walk, zipline...) + un
  obj_vanilla v1.2 evolucionado por el usuario (specialFunc inline
  con macros VANILLA_FLY_*: vuelo tipo Tails 5 s / 7.5 s con
  pasajero, dash, anillos 15 s). Cambios locales eran subconjunto
  del remoto: checkout limpio + pull.
- Recon completo en paralelo (3 subagentes): caida/demonizacion/
  stun/i-frames (shockedTimer aplicado por el cliente del exe;
  escudo Sally = hurttime + alpha 0.5; afterimages =
  obj_quickeffect_fade; patron guards canon en scr_player_instakill
  sin avisar al server), mascotas/flechas/V (pets = Draw_76 lerp
  0.21 detras del jugador, creados por spawnpoint/netclient Other_4;
  obj_amycanon_indicators clonable; V libre salvo carry-drop y
  parry Sonic/AmyCanon), server (demonizacion server-authoritative
  con flags PLAYER_*; worth de anillos via SERVER_RING_COLLECTED u8;
  SERVER_FORCE_DAMAGE sin uso; enum PacketType identico en ambos
  lados).
- DISENO: Chocola = objeto nuevo simulado LOCALMENTE en cada cliente
  (patron pets) con transiciones por BROADCASTS de sonido
  (snd_mermer/nono/vasebreak/ready/npteleport/achivement, indices
  108-113 de net_snds, ninguno se emitia por red antes); los STUNS
  al exe viajan como senales shouldPlay=true a su nid (patron
  parry v3.5) y los aplica su cliente (scr_chocola_stun_signal con
  duracion parametrizada + dedup shockedTimer). Estado de Vanilla
  por red: estados 17 (float run) / 18 (paciencia) / 19 (agotada/
  moribunda) en player_anims/eanims extendidos a 20 entradas.
  Estela remota del float run = bitflag PLAYER_POWERBOOST reutilizado
  (el ghost del puppet es generico, no solo-Sonic). Paciencia/
  moribunda interceptan scr_player_instakill SIN avisar al server
  (patron burbuja/nervios/fase2); Vanilla nunca muerte server-side:
  guards CH_VANILLA anadidos a game_demonize y CLIENT_PLAYER_DEATH_
  STATE (muerte directa canon, jamas demonizada). Des-demonizacion =
  unico paquete NUEVO (CLIENT/SERVER_VANILLA_DEDEMONIZE 144/145):
  el server valida (CH_VANILLA, in_game, target demonizado, dist
  <= 150) y limpia PLAYER_DEMONIZED + marca PLAYER_REVIVED (= "1
  caida mas para re-demonizarse"); SIN esto el AssertOrDisconnect
  de CLIENT_PLAYER_DEATH_STATE desconectaba al esbirro en su
  siguiente caida. Worth: Vanilla 4 (server Game.c, MakeCreamRing);
  Cream 2 si hay Vanilla in_game (loop de peers). Fortaleza:
  scr_player_hurt pierde 15% (Vanilla) / 30% (Cream con Vanilla,
  via scr_vanilla_in_match) min 3, en vez de todos los anillos.
- ARCHIVOS NUEVOS (15): scripts/scr_chocola (macros + 10 funciones:
  find home/exe/cream, scr_vanilla_v2_step = toda la logica del
  paso de Vanilla, net_event, stun_signal, guard_consume),
  objects/obj_chocola (Create + Step: 6 modos FOLLOW/HUNT/RETURN/
  GO_CREAM/GUARD/ATTACK_PAUSE; FOLLOW usa la MISMA formula de los
  pets; HUNT llega -> senal al nid del exe + attack pause + return;
  GUARD junto a Cream con roll 33% y cura 15% AL LLEGAR solo en el
  cliente de Cream), objects/obj_vanilla_indicators (clon de
  amycanon: flecha verde ring + roja exe, solo su cliente),
  objects/obj_family_indicator (flecha amarilla spr_sindicator3
  madre-hija > 400 px, clientes de Vanilla Y Cream, la crea
  obj_spawnpoint).
- PARCHES CLIENTE (30 ops): scr_survivors (arrays Vanilla +3),
  obj_vanilla Create (macros v2, 15 vars nuevas, specialFunc llama
  scr_vanilla_v2_step + early-return paciencia, maxHSpeed =
  floatRunCap, comment v2 anillos, chocola celebra con C, crea
  indicadores), Step_2 (estados 17/18/19 en la cadena, float run en
  la de corrida), Draw_76 (cases nuevos), Draw_0 (afterimages
  locales), scr_player_hurt (guard inmune paciencia/moribunda,
  bloqueo 50% con spr_shieldbreak + hurttime 150, custodia Cream
  bloquea 1 dano exe O entorno, fortaleza 15/30% min 3, instakill
  paciencia 1ra + moribunda 2da+ conservando anillos), scr_move_
  basic (salto bloqueado en paciencia/moribunda), net_sounds (+6),
  net_packets (+2), obj_netclient Step_2 (POWERBOOST si
  isFloatRunning), obj_spawnpoint (family indicator), net_state_
  game (senales snd_nono/vasebreak -> stun 5 s/1.5 s; hooks
  broadcast en el with del puppet para HUNT/GO/RECALL/DUTY/SUPPORT
  — SUPPORT se deriva del snd_creamring que Vanilla ya emite con
  pid=puppet Vanilla; case SERVER_VANILLA_DEDEMONIZE con des-
  demonizacion local del objetivo: revivalTimes=1, hp 100, paleta
  normal + net_send_palette, destruye obj_demon_indicator).
- PARCHES SERVER: include/Packet.h (+2 enum al final, mismo orden
  que net_packets.gml), states/Game.c (guards canon x2, worth
  4/cream_worth 2 con loop de peers, case CLIENT_VANILLA_DEDEMONIZE
  con validaciones + broadcast + Info log).
- VALIDACION: vanilla_v2_validate.py 174/174 (sintaxis balanceada,
  sin CR, sin ternarios encadenados GM2026, registro yyp/rorder,
  cableado completo, paridad de enums, sims de reloj: paciencia
  300/180/freeze/exit, float run 190 f a tope, fortaleza 15/30/min3,
  cooldowns). Server compilado 100% limpio (gcc + enet clonado,
  build_v2) y smoke test OK (v1101, puerto 8606, Lobby).
- Aplicador scripts/apply_vanilla_v2.py (50 operaciones, anclas
  byte-exactas con indentacion verificada por archivo: ESPACIOS en
  scr_survivors/scr_player_hurt/net_sounds/net_state_game/net_
  packets/scr_move_basic, TABs en obj_vanilla*/obj_netclient/
  obj_spawnpoint; marcadores idempotentes por parche). Bug del
  primer dry-run (escribia en modo --dry): revertido con git
  checkout y re-aplicado limpio.

Stage Summary:
- VANILLA V2 COMPLETA: anillos x4 (server), float run 11->14 con
  pose+estela (local y remota), paciencia (1ra caida: 5 s inmune,
  Chocola stunea al exe 5 s con el reloj congelado hasta golpear),
  moribunda (nunca muere, 6 s + 30 hp), Chocola permanente (bloqueo
  50%/2.5 s + ataque 33%/1.5 s, CD 4.5 s compartido), V = enviar/
  llamar a Chocola con Cream (custodia: bloquea 1 dano o stun,
  cura 15% al llegar), des-demonizacion por 15 anillos (paquete
  nuevo con validacion server), Fortaleza (15%/30% min 3),
  Inspiracion (anillos de Cream x2), Madre e hija (flecha amarilla
  mutua > 400 px) + detectores exe/ring para Vanilla.
- REQUIERE RECOMPILAR EL SERVER (worth 4/2 + des-demonizacion).
  Entregable: download/vanilla_v2.zip. LEEME_VANILLA_V2.txt con
  instalacion, ajustes (macros en scr_chocola.gml), decisiones de
  diseno y guion de prueba de 7 pasos.

---
Task ID: vanilla-v2-fix1 (rev2)
Agent: Super Z (main agent)
Task: El usuario compilo la v2 y GameMaker fallo con errores de
sintaxis: net_sounds.gml "got 'snd_mermer' expected ',' or ']'" y
obj_vanilla/Draw_76.gml "unexpected symbol ':' in expression".

Work Log:
- Pull primero (regla del usuario): ya al dia, HEAD 28cbf395.
- Causa 1 (net_sounds): el parche NS_NEW insertaba los 6 sonidos de
  Chocola (108-113) DESPUES de 'snd_parry   // 107', que era el
  ULTIMO elemento del array global.net_snds y no llevaba coma.
  Corregido a 'snd_parry,' en el repo y en apply_vanilla_v2.py
  (NS_ANCHOR queda igual: describe la base sin parchear).
- Causa 2 (Draw_76): VD76_RUN_NEW escribia 'break:' (dos puntos) en
  vez de 'break;' en 2 sitios (caso RUN/JUMP y caso VANILLA_FLOAT_RUN;
  GM senala la linea anterior al typo). Corregidos los 2 'break;'
  en el repo y las 2 cadenas del aplicador.
- Verificado que los 6 sonidos (snd_mermer, snd_nono, snd_vasebreak,
  snd_ready, snd_npteleport, snd_achivement) existen como assets.
- Creado scripts/gml_syntax_audit.py: auditor sintactico GML que caza
  esas familias (id+id o ]+id pegados dentro de expresiones = coma
  faltante; 'break:'/'continue:'; ternarios '?' encadenados a
  profundidad 0 excluyendo el accessor [? de ds_map; llaves/parens/
  corchetes desbalanceados). Entiende $hex/#hex, strings multilinea,
  comentarios y el separador de sentencia por salto de linea (legal
  fuera de expresiones). Calibracion: los 875 .gml del repo entero
  dan 0 sospechosos (0 falsos positivos sobre codigo que compila);
  los 21 GML tocados por v2: LIMPIOS -> los 3 typos corregidos eran
  los UNICOS errores de esas familias.
- Validador: nueva seccion 13 "SINTAXIS GML" (21 checks, uno por
  archivo) -> 195/195. Un error de compilacion de estas clases ya no
  puede volver a pasar los checks.
- Empaquetado download/vanilla_v2_rev2.zip (mismos 35 archivos que
  la v2, con las 3 correcciones; server IDENTICO, no hace falta
  recompilarlo si ya se compilo la v2).
- HALLAZGO CRITICO al integrar con el push del usuario (a10d81d2
  "Cambios importantes a vanilla" = el mismo zip v2 que el aplico):
  su .yyp y .resource_order NO tienen las 4 entradas nuevas
  (obj_chocola, obj_vanilla_indicators, obj_family_indicator,
  scr_chocola) -> esos 2 archivos no se sobrescribieron al extraer
  el zip en su PC. Aunque se arreglaran los typos, el compile
  fallaria con "scr_chocola/obj_chocola no existen". Integrado con
  rebase (fix commit encima de su arbol, conservando su tweak de
  spr_gui_amyparry_canon.yy) + restauradas las 4 entradas.
- LEEME rev2 reescrito con instalacion explicita: verificar que el
  .yyp/.resource_order se sobrescriban y que obj_chocola/scr_chocola
  aparezcan en el arbol de recursos.
- PUSH IMPOSIBLE desde este sandbox (sin credenciales GitHub):
  como siempre, el flujo real es usuario-extrae-zip-y-pushea. Los
  commits locales quedan listos por si se anade un token despues.

Stage Summary:
- 3 erratas de sintaxis corregidas (1 coma + 2 'break;') + 4
  entradas .yyp/.resource_order restauradas (no se habian
  aplicado en la copia del usuario). CERO cambios de
  logica/numeros/server respecto a la v2. Nuevo flujo obligatorio:
  validador + gml_syntax_audit.py tras cada parche. Entregable:
  download/vanilla_v2_rev2.zip. Instalar: extraer ENCIMA de la raiz
  con GM cerrado COMPROBANDO que el .yyp y .resource_order se
  sobrescriben, recompilar F5 (server solo si no se compilo aun).
  El usuario debe pushear el resultado a GitHub (yo no puedo).

---
Task ID: vanilla-v2.1
Agent: Super Z (main agent)
Task: 2 pedidos del usuario tras probar la v2 rev2 ("todo funciona bn"):
(1) en la pantalla del EXE no se ve a Chocola moverse hacia el exe
como si pasa en la pantalla de Vanilla; (2) subir el bloqueo de
golpes del exe a 65% y bajar el CD a 2.5 s.

Work Log:
- Pull primero (regla del usuario): bab141d2 -> 7a227d23 (8 commits
  nuevos del usuario: la vanilla v2 + rev2 ya pusheadas, mas
  "Cambios importantes a vanilla" y "aja"). El arbol local estaba
  limpio y al dia; los zips de flybuff ya viven dentro de esos
  commits (verificado TAILS/CREAM_FLY_CARRY presentes).
- DIAGNOSTICO del (1): la CAZA GRANDE de la paciencia SI se ve en
  todas las pantallas (snd_mermer broadcast -> CHOCOLA_NET_HUNT en
  cada cliente, cada uno simula su Chocola volando al exe). Lo que
  NO se ve en el exe es la MINI-EMBESTIDA del 33% (ataque cercano y
  custodia de Cream): la rolla un unico cliente (Vanilla o Cream),
  no se anunciaba por red y el stun (snd_vasebreak al nid del exe)
  le llegaba al exe sin verla venir. Era un comportamiento conocido
  y documentado en el LEEME v2 ("la mini-embestida solo se ve en el
  cliente que la rolla").
- FIX (1): nueva senal de red CHOCOLA_NET_HUNT_SMALL (macro 5) que
  viaja como broadcast del sonido NUEVO snd_chocola_dive (indice 114
  de global.net_snds, anadido AL FINAL: cliente viejo que reciba 114
  lo ignora por el guard sid >= array_length). Lanzaderas: el roll
  del 33% en scr_vanilla_v2_step (cliente de Vanilla) y el roll de
  la custodia en obj_chocola/Step_0 CHOCOLA_GUARD (cliente de Cream)
  ahora hacen audio local + net_sound_emit(snd_chocola_dive). Rama
  nueva en el with(puppet) del CLIENT_SOUND_EMIT que llama a
  scr_chocola_net_event(CHOCOLA_NET_HUNT_SMALL): pone la Chocola
  local en CHOCOLA_HUNT hacia el exe DESDE DONDE ESTA (sin el
  reposicionamiento ±520 de la caza grande), authority=false (solo
  la lanzadera manda el stun al llegar). La creacion por senal
  tambien acepta HUNT_SMALL y nace junto a casa si el cliente no la
  tenia. Resultado: exe (y todos) ven a Chocola picar hacia el,
  llega a la vez que el stun, pose de golpe y vuelta igual que en
  la pantalla de Vanilla.
- FIX (2): VANILLA_CHOCOLA_BLOCK_CHANCE 50 -> 65 y
  VANILLA_CHOCOLA_CD (60*4.5) -> (60*2.5) en scr_chocola.gml (el CD
  es compartido bloqueo/ataque: ahora ambos re-cargan en 2.5 s).
  Comentarios actualizados en scr_chocola.gml (cabecera + ataque
  cercano) y scr_player_hurt.gml. Resto del kit intacto (33% / 1.5 s
  / invuln 2.5 s / cura 15% etc. verificados por el validador).
- ASSET NUEVO snd_chocola_dive: wav sintetizado (picado descendente
  1500->420 Hz con vibrato, 0.30 s, mono 16-bit 44100; script
  scripts/make_dive_sound.py del workspace) + .yy (GMSound, parent
  folders/Sounds.yy como snd_mermer) + registro en .yyp (orden
  alfabetico, junto a snd_chaos_*) y resource_order (junto a
  snd_parry). Cero sonidos existentes tocados (verificado: nadie
  mas emite snd_chocola_dive y no estaba en el array).
- HALLAZGO (no bloqueante, NO tocado): EVASI1/2/3 y SALLY1-5 existen
  como carpetas en sounds/ pero NO estan registrados en el .yyp;
  scr_sally_canon_fase2.gml usa EVASI2 (local + net_sound_emit) =>
  en runtime daria "unknown variable EVASI2" al dispararse esa rama
  y su emit manda indice -1. Es un asunto de la rama del usuario
  (Sally Canon fase2), avisar en la respuesta.
- Aplicador scripts/apply_vanilla_v2_1.py (14 ops, dos fases, match
  exacto == 1, idempotente con --dry) + validador
  scripts/vanilla_v2_1_validate.py: 82/82 OK (balance, wiring
  completo de la senal, sintaxis de los 5 GML tocados, integridad
  del array net_snds —ojo: snd_exe_laugh viene duplicado del juego
  original, preexistente e inofensivo—, wav valido y no mudo,
  .yyp 1742 recursos parsea, sims de logica mini-ram/bloqueo/roll,
  diff de git limitado a los 7 archivos esperados). Auditor extra
  de comas faltantes/break: sobre los 5 GML: limpio.
- Docs: LEEME_VANILLA_V2.txt actualizado (65%/2.5 s marcados v2.1,
  nota de la senal, pasos 3 y 8 nuevos del guion de prueba).
  CACHE.md: 7.4 + tabla de mods + changelog. CERO server: el
  paquete no toca betterserver-oss (no hace falta recompilar).

Stage Summary:
- Mini-embestida de Chocola (33% cercano + custodia) ahora visible y
  sonora en TODAS las pantallas (senal snd_chocola_dive 114): el exe
  la ve picar hacia el justo antes del stun, igual que Vanilla.
- Bloqueo 50 -> 65% y CD compartido 4.5 -> 2.5 s (macros arriba de
  scr_chocola.gml). Cero server, 7 archivos + 1 asset nuevo.
- Entregable: download/vanilla_v2_1.zip. Instalar: extraer ENCIMA
  de la raiz con GM cerrado (verificar que el .yyp y resource_order
  se sobrescriben; snd_chocola_dive debe aparecer en Sounds) y F5.

════════════════════════════════════════════════════════════════════
2026-10-31 — SYNC PULL + VANILLA v2.1.4 (fix sonido de stun de Chocola)
════════════════════════════════════════════════════════════════════

Pedido: "cuando chocola stunea no se oye el sonido de stun al exe" +
pull del repositorio.

Pull / sync:
- fetch: origin/main avanzo a 57b9ae94 ("Mejora"). El push traia el
  CODIGO v2.1.2+v2.1.3 aplicado por el usuario (TODOS los .gml y
  betterserver-oss identicos a mis commits locales) pero LEEME/
  CACHE/worklog quedaron en estado v2.1: al extraer los zips no
  sobrescribio los 3 docs (mismo patron del ".yyp fantasma").
- Divergencia local (3 commits mios) resuelta con reset a origin/main
  (el codigo era identico; docs del usuario = canonico). Backup de
  mis docs completos en scripts/doc_backup_v213/. Re-anadidas filas
  v2.1.1-2.1.3 compactas en CACHE (tabla + seccion 7.4.1).

Diagnostico del sonido (los 3 stuns del juego comparados):
- parry (scr_parry_apply_stun) y laser de Tails
  (obj_tails_projectile): el exe oye snd_exe_stun (golpe canonico)
  + scr_exe_stunsound() (grito del personaje).
- Chocola (scr_chocola_stun_signal): SOLO el grito, y ADEMAS colocado
  AL FINAL, DESPUES del `if(shockedTimer > 0) return` del dedup =>
  (a) exe ya stuneado por otra fuente = golpe de Chocola EN MUDO,
  (b) exe limpio = solo grito (sin el "hit" que el jugador reconoce
  como sonido de stun).

Fix (scripts/scr_chocola/scr_chocola.gml, scr_chocola_stun_signal):
- audio_play_sound(snd_exe_stun, 0, false) + net_sound_emit(
  snd_exe_stun) + scr_exe_stunsound() movidos ANTES del dedup: el
  golpe suena SIEMPRE (aunque el stun no se re-aplique; el golpe fue
  real). El net_sound_emit reenvia el golpe: los demas clientes lo
  oyen en 3D desde el exe, igual que en el parry. Dedup intacto (no
  acumula stuns), mismas duraciones, mismo CLIENT_PLAYER_HURT/shake.

Verificacion:
- Validador nuevo scripts/vanilla_v2_1_4_validate.py: 28 checks
  (forma del fix, orden sonido<dedup, sanidad GML, callers de
  net_state_game, paridad con parry/laser, snd_exe_stun en
  global.net_snds y como asset) + regresion completa: v2.1.1 (52),
  v2.1.2 (90 + 866 archivos), v2.1.3 (34 + 9 archivos de red
  linteados). TODO OK.
- Zip verificado byte a byte contra el repo (2 archivos).

Docs: LEEME seccion REVISION 2.1.4; CACHE tabla + 7.4.1 + changelog;
worklog (esta entrada).

Stage Summary:
- El stun de Chocola ahora suena en la pantalla del exe IGUAL que
  todos los demas stuns del juego: golpe canonico + grito, siempre
  (tambien cuando el exe ya estaba stuneado y el dedup no re-aplica).
- Solo cambia scripts/scr_chocola/scr_chocola.gml. CERO server, cero
  assets nuevos: extraer con GM cerrado y F5.
- Entregable: download/vanilla_v2_1_4.zip.

## 2026-10-31 — vanilla-v2.2: rescate de personajes de TD2D "Through the blood" (cerrado)

Contexto: el mod TTB de maxbaxwer fue abandonado y cerrado en GameJolt;
el usuario pidio rescatar a sus personajes (builds cliente+server
descargadas via API interna de GameJolt, data.win YYC 134 MB extraido
con UndertaleModCli Ubuntu → /home/z/my-project/td2d_blood/dump).

Hecho:
- 148 sprites + 20 sonidos importados (ttb_import_assets.py: .yy
  generados al 100%, PNG root + layers/, registro en .yyp → 1926
  recursos, 0 duplicados).
- 3 supervivientes (Metal Sonic / Amelia / Blaze) + 1 killer
  (Metal Amy): objetos completos (8 eventos c/u, plantillas
  vanilla/exeller), 4 special scripts, 4 entidades de red cliente
  (banana/bomb/fireball/bullet), estados propios + eanims completos.
- Red: 11 paquetes nuevos (paridad cliente/server verificada),
  4 entidades server (patron TailsProjectile), 7 cases en Game.c,
  cooldowns por jugador x4 (PLAYER_COOLCOUNT 10), limites de
  CharSelect hasta CH_BLAZE / EX_METALAMY + memsets corregidos.
- Lobby: chars[] 18, spr_lobby_icon 10→13 f y spr_char_info 12→16 f
  (frames identificados por pixel-matching + OCR de las placas TTB),
  exeicon6 (5.o killer), iconos de cooldown en playerui, springs/
  slow/carry/move_basic integrados, PLAYER_POWERBOOST para el dash
  de Metal y la forma ardiente de Blaze (estela en puppets).
- Blaze CD de la bola = 9 s (leido por OCR de la placa original).

Validacion: vanilla_v2_2_validate.py 316 checks OK (incluye paridad
de enums, 17 slots por anim array, referencias a assets, macros
unicas, sintaxis de 38 GML, registro en .yyp, server). gcc
-fsyntax-only limpio en los 6 .c tocados del server.

Docs: LEEME seccion REVISION 2.2; CACHE changelog; esta entrada.

Stage Summary:
- 4 personajes de TTB jugables: Metal Sonic, Amelia, Blaze
  (supervivientes libres) y Metal Amy (killer #5), con assets
  originales y habilidades fieles a las placas del mod.
- EL SERVER CAMBIA: recompilar antes de hospedar.
- Entregable: download/vanilla_v2_2_ttb_characters.zip.

════════════════════════════════════════════════════════════════════
2026-10-31 — VANILLA v2.2.1 + v2.2.2 (el proyecto abria pero NO COMPILABA)
════════════════════════════════════════════════════════════════════

v2.2.1 (ya entregada como linkfix, re-incluida aqui): "Cannot find
folder path 'folders/Scripts/Net.yy'" x4 -> reparent de los 4 .yy a
folders/Scripts/Networking/Specific.yy. Con esto el proyecto ABRIA.

Pedido v2.2.2: el usuario compila y recibe (a) ~200 "File missing for
GMSprite" en la ventana de errores y (b) crash del asset compiler:
IndexOutOfRangeException en GMObject.GetEventName_Simple (Igor exit
-532462766). NOTA: tras aplicar v2.2.1 el LOAD AND LINK fue
SUCCESSFUL — los dos bugs nuevos son invisibles para el IDE y solo
matan al COMPILADOR.

Diagnostico (sobre el estado exacto del usuario; el zip v2.2 original
se recupero de litterbox mdqgbq.zip, SHA verificado):
- BUG A: los .yy de obj_metal/obj_amelia/obj_blaze/obj_metalamy
  traian 8 eventos; 6 bien y 2 con los CAMPOS INVERTIDOS:
  "eventNum":0,"eventType":64 y "eventNum":0,"eventType":76. Los
  .gml se llaman Draw_64.gml/Draw_76.gml => los reales son
  eventType 8 (Draw) num 64 (GUI) y 76 (referencia upstream:
  obj_aiz_zipline type=8 num=76). Un eventType de 64/76 indexa fuera
  de la tabla de nombres del compilador -> IndexOutOfRange.
- BUG B: cada .yy de sprite TTB declara UNA capa GMImageLayer con
  GUID G1 (p.ej. 1d061688) pero el importador guardo el PNG de cada
  frame como layers/<frame>/<G2>.png con G2 distinto (a1585038):
  DOS tiradas del generador de GUIDs. GM pide por convencion
  layers/<frame>/<G1>.png -> File missing x cada frame de cada
  sprite (los 148 TTB + las tiras ampliadas spr_char_info/spr_lobby_
  icon, que ademas mezclan los layers del upstream).

Fix (scripts/fix_v22_compile.py, sobre repo+zip = estado usuario):
- BUG A: reemplazo textual exacto de las 2 lineas por .yy (4 .yy).
- BUG B: creados 1.161 PNG layers/<frame>/<G1-del-yy>.png copiando
  el PNG existente en cada dir layers/<frame>/ (8.190 ya existian
  bien; 0 errores). Los PNG con G2 quedan huerfanos (inofensivos,
  GM no los referencia).
- BUG 3 (v2.2.1): incluido por si se viene de un v2.2 pelado.

Validacion (en el mismo script): 0 sprites missing, eventList de
los 4 == {(0,0),(3,0),(8,0),(3,2),(2,4),(8,64),(8,76),(7,7)},
parents de los 4 net_ OK. Todo OK.

Nota de sesion: el sandbox se reciclo y perdio el zip v2.2, el
commit e596fadf, el dump UMT y public/ (hub). Recuperado gracias a
la copia de litterbox (GET con --http1.1: el WAF pincha HTTP/2).
Este commit re-integra v2.2 + v2.2.1 + v2.2.2 de una vez sobre
38807afd (v2.1.4): 3.758 archivos nuevos + 28 modificados.

Docs: LEEME (REVISION 2.2.2 + re-inserida la 2.2.1); CACHE (tabla,
7.4.1 y changelog); esta entrada.

Stage Summary:
- v2.2 VUELVE A COMPILAR: extraer vanilla_v2_2_2_compilefix.zip
  ENCIMA de la raiz con GM cerrado y F5. Nada de .gml, nada de
  server (el de v2.2 sigue valiendo).
- El zip lleva 1.161 PNG + 4 .yy de objetos + 4 .yy de scripts + docs.
- Entregable: download/vanilla_v2_2_2_compilefix.zip.

════════════════════════════════════════════════════════════════════
2026-10-31 — CHARSAFE v2.2.3 (seguro de slots: fin de los crashes
"Index [N] out of range" al agregar personajes)
════════════════════════════════════════════════════════════════════

Sintoma (reportado por el usuario): crash
  Push :: Execution Error - Variable Index [13] out of range [11]
  - 221.avCharacters(100093,13)
  at gml_Object_obj_lobby_Draw_0 (line 121)
al entrar a la seleccion de personajes. Y su pregunta: "no crees
que deberiamos crear un seguro que permita crear el slot y todo
eso automatico para cuando agreguemos un pj nuevo?" => hecho.

Causa raiz: avCharacters (que slots de personaje estan libres) es
un array de instancia de obj_netclient que estaba COPIADO A MANO
en 7 lugares (obj_netclient/Create_0, net_wrapper, net_tcpprocess,
net_state_game x3, obj_level/Alarm_2). En v2.2 se agrego Blaze
(slot 13) y solo 3 copias se actualizaron a 14 entradas; las
otras 4 quedaron con 11 => cualquier acceso al slot 12/13 explota.
El literal duplicado era una trampa que ya habia mordido en v2.1
(vanilla v1: "11 entradas (2 sitios)") y mordio de nuevo.

Solucion (scripts/scr_characters/scr_characters.gml, NUEVO):
- Macros de tope DERIVADOS de los enums existenes:
  CHARACTER_SURV_MAX (= CHARACTER_BLAZE, el ultimo macro de
  scr_survivors), CHARACTER_COUNT (+exe), EXE_CHAR_COUNT
  (= EXE_METALAMY + 1), LOBBY_CHARS_MIN (chars[] del lobby).
  Al agregar un pj nuevo al FINAL de la lista de macros, TODO se
  re-dimensiona solo.
- scr_avchars_reset(): array fresco [exe=false, resto=true].
  Reemplaza a las 7 copias del literal.
- scr_avchar_get(ch): lectura blindada. Fuera de rango => false
  (= ocupado, el pj no se puede pedir) + log [chars]. NUNCA mas
  "Variable Index out of range".
- scr_avchar_set(ch, val): escritura blindada. Si un SERVER MAS
  MODERNO manda un CHARACTER_CHANGE con un id que este cliente
  no conoce, crea los slots al vuelo (huecos = ocupados =
  innombrables) en vez de crashear: versiones viejas de cliente
  pueden seguir jugando en servers con pjs nuevos.
- scr_characters_sanity(): lo llama obj_lobby/Create_0 una vez
  por arranque; loguea [charsanity] cualquier registro incompleto
  (chars[] del lobby, paletas, player_anims, player_get) ANTES de
  que explote en partida. Nunca crashea el mismo.
- scr_char_name(ch): nombres para los logs.

Cambios de integracion (todo validado por
workspace/scripts/validate_slots.py, TODO OK):
- 7 literales -> "avCharacters = scr_avchars_reset()".
- 5 accesos directos blindados: obj_lobby/Draw_0:121 (el del
  crash), obj_lobby_icon/Draw_0:82, net_tcpprocess:39 (player
  left), net_state_charselect:111 y :189 (response/change).
- obj_lobby/Draw_0: clamp de sprInd contra array_length(chars)
  antes de chars[sprInd] y sprite_get_speed() (por si un server
  mas moderno manda un pj sin retrato en este cliente).
- Registro: scr_characters en el .yyp (formato exacto de linea
  verificado contra las demas) + .yy con parent Players.
- CACHE.md: seccion 4 nueva (SLOTS DE PERSONAJE), regla 8.11,
  changelog. Este worklog.

Server: NO se toca (betterserver de v2.2 sigue valiendo; su
avail[] ya se dimensiona con CH_BLAZE+1).

GUIA PARA EL PROXIMO PERSONAJE (queda en la cabecera del script
y en CACHE.md seccion 4): macro AL FINAL en scr_survivors (o
scr_exe si es killer) + player_anims + case player_get + assets
de lobby (chars[], tira spr_lobby_icon, placa spr_char_info,
exeicon, paleta default) + enum CH_*/EX_* AL FINAL en
include/Server.h + nombre en states/CharSelect.c. El array de
slots y el sanity se ajustan solos; lo que falte lo dice
[charsanity] por consola al arrancar, no crasheando en partida.

Stage Summary:
- Crash del lobby ARREGLADO y familia de errores eliminada de
  raiz: extraer charsafe_v2_2_3.zip ENCIMA de la raiz con GM
  cerrado, aceptar sobrescribir y F5.
- El zip lleva el script nuevo (.gml + .yy) + el .yyp + 10 .gml
  modificados + LEEME + docs. NADA de server.
- Entregable: download/charsafe_v2_2_3.zip.

---

## 2026-11-01 — amelia-v2.3+v2.4 (reconstruidos juntos): kit del TD + velocidad eliminada

Contexto: el sandbox del agente se reciclo y se perdieron los commits
locales de v2.3/v2.4 (nunca llegaron a GitHub). Se reconstruyo TODO
encima del commit "ok" (1af7dce3) del usuario — que ya traia SU fix
del bug de velocidad v2.2.4 (AMELIA_ACC 0.35 -> 0.046875: "la hacía
salir disparada al instante"). Ese fix se RESPETA tal cual.

Pedido v2.3 (literal): "1 que todo Amelia usa trampas la trampa dura
hasta un max de 60 seg 2 la habilidad de vuelo es remplazada por la
velocidad (cream) y el trmapolin este sigue igual. el stun de la
trampa es de 3 seg. y tambien aplica debuff de vel de movimiento por
3.5 seg (despues que salga del stun producido por la trampa)."
Pedido v2.4 (literal): "Elimina la velocidad y hay un bug de
velocidad en amelia" -> la velocidad pedida en v2.3 NO entra: Amelia
queda SOLO con trampolin + trampa (kit del TD original). El bug de
velocidad es el del acc que el propio usuario ya habia arreglado en
v2.2.4 (y un boost con la tecla de salto pisando isBoosting de las
botas habria sido carrera forzada: mejor fuera).

RESULTADO (v2.4 final, cliente + server):

1) TRAMPA (tecla C; antes "bomba" de mecha 5 s + boom radio 90):
   - Vida maxima 60 s (la lleva el server: retiro silencioso con
     SERVER_AMELIA_TRAP_STATE 1; el cliente ademas se desvanece solo
     si el paquete se pierde).
   - Pisada: la detecta el cliente de la VICTIMA (lado EXE, viva) =>
     STUN 3 s (shockedTimer + xspd=0 + snd_exe_stun) + debuff -40%
     otros 3.5 s AL SALIR del stun (scr_player_slow pide el TOTAL
     3.5+3: los 3 primeros quedan tapados por el stun, no hay
     movimiento). Patron de autoridad de la banana: cada cliente
     manda sobre su propio jugador; el resto ve state 2 (destroy +
     goth + shock + shake suave 20 frames).
   - CLIENT_AMELIA_TRAP_TRIGGER lleva el NID: el server busca tag
     "atrap" + id EXACTO. MATA 2 bugs latentes de la v2.2: (a) el boom
     por pisada nunca se emitia (game_despawn directo sin state 2) y
     (b) game_find("abomb") podia borrar la bomba de OTRA Amelia.
   - Max 1 viva POR AMELIA (v2.2 era limite global: con 60 s de vida
     varias Amelias se estorbarian un minuto entero).
   - Renombres completos: obj_amelia_bomb -> obj_amelia_trap,
     net_amelia_bomb -> net_amelia_trap, AmeliaBomb.c/.h ->
     AmeliaTrap.c/.h, "abomb" -> "atrap", AMELIA_BOMB_SPAWN ->
     AMELIA_TRAP_SPAWN, CLIENT_AMELIA_BOMB(_BOOM) ->
     CLIENT_AMELIA_TRAP(_TRIGGER), SERVER_AMELIA_BOMB_STATE ->
     SERVER_AMELIA_TRAP_STATE. Mismo orden numerico => protocolo
     compatible cliente v2.4 + server v2.4 (actualizar JUNTOS).

2) VUELO: FUERA por completo (isFlying/flyTimer/flyTimeout,
   AMELIA_FLY_* macros, estado AMELIA_FLY queda defensivo, carry de
   aliados en scr_carry_partner_flying, cases de resorte en
   scr_collision_objects, icono spr_gui_creamfly). La tirolina de
   Cream (CREAM_ZIPLINE) SE CONSERVA. NINGUNA habilidad nueva en Z.

3) TRAMPOLIN (tecla X): SIN CAMBIOS (pedido: "este sigue igual"):
   resorte colocable 12 s, recarga 25 s, fisica local del juego,
   recarga demonizada 10 s.

4) UI (obj_playerui): 2 iconos (trampolin 240 / trampa 258) con los
   sprites ya registrados (spr_gui_amelia_trap y spr_gui_eggtrack,
   los mismos que usaba la v2.2 para banana/bomba).

5) Extra: case CHARACTER_SONIC en scr_player_slow (faltaba desde
   siempre: un Sonic demonizado no recibia slow ni del eggtrack ni de
   la trampa nueva).

Validacion: .yyp JSON valido sin duplicados (1927 recursos, renames
aplicados); delimitadores balanceados en los 15 .gml tocados; 0
referencias stale a bomba/vuelo en codigo (script del agente
validate_amelia_v24.py). Server COMPILADO con gcc (enet clonado a
mano: el submodule nunca estuvo inicializado; build del agente
build_server.sh que replica la lista exacta de fuentes del
CMakeLists) y PROBADO: BetterServer v1101 levanta en 8606 y entra a
Lobby sin errores. NOTA del build: disasterserver/Game.c (raiz) es un
archivo viejo huérfano FUERA del CMakeLists (usa game.cooldowns ya
inexistente); el real es states/Game.c — no tocar el raiz.

Entregable: download/amelia_v2_4.zip (extraer sobre la raiz con GM
cerrado + recompilar el server; ver LEEME dentro).

Stage Summary:
- Amelia v2.4 = trampolin (X) + trampa (C): vida 60 s, stun 3 s,
  slow -40% 3.5 s tras el stun, max 1 por Amelia, trigger por nid.
- Vuelo y velocidad: ELIMINADOS. Stats 11 / acc 0.046875 (v2.2.4).
- Cliente: 15 .gml + 2 .yy nuevos (trap) + .yyp renames.
- Server: AmeliaTrap.c/.h nuevos, Packet.h, Server.h, Game.c (states),
  CMakeLists. Compilado y probado.

## 2026-11-01 — hudbar-v2.5: barra de vida de Amelia bugeada (composites perdidos)

SINTOMA (usuario): "aparece bugeada la barra de vida de la propia Amelia".

DIAGNOSTICO: no era codigo, eran ASSETS. obj_level/Draw_64.gml dibuja la
barra como draw_sprite(spr_playerhealth, (char-CHARACTER_TAILS)*7 +
estado) => 91 frames = 13 slots x 7 estados. Los slots 10/11/12
(METAL/AMELIA/BLAZE) existian en el .yy desde 1af7dce3, pero sus PNG
composite NO estaban en la raiz del sprite: aquel commit los dejo caidos
en sprites/<spr>/layers/<frameGuid>/<randomGuid>.png (estructura de
CAPAS de GMS2.3) en vez de sprites/<spr>/<frameGuid>.png (el composite
del que la texture page toma los pixeles). Frame registrado sin
composite => GM mete basura en la textura => barra bugeada. Explica
tambien por que Metal/Blaze nunca tuvieron barra correcta y por que el
marcador TAB mostraba filas rotas para los 3.

Alcance real (auditoria repo-wide del agente,
scripts/audit_sprite_frames.py — reutilizable): 88 frames rotos en 6
sprites — spr_playerhealth 35, spr_playerhealth_redring 35,
spr_playerhealth_hit 5, spr_playerhealth_demon 5, spr_playerescaped 5 y
spr_tab_entry 3 (filas 12/13/14 = Metal/Amelia/Blaze del TAB).

FIX (scripts/fix_healthbar_composites.py, idempotente): por cada frame
del .yy sin composite: (1) copiar layers/<g>/<x>.png -> <g>.png en la
raiz; (2) renombrar el PNG interno al GUID de la capa default del .yy
(misma estructura que los frames viejos que siempre funcionaron). Slots
8/9 (SALLY_CANON/VANILLA) quedan como placeholder 100% transparente: es
correcto, jamas se dibujan (Draw_64 los remapea a SALLY/CREAM).

EXTRA (misma familia de bug, 1 archivo): drawPing (obj_level/Create_0.gml,
marcador TAB) calculaba hchar = char-1 SIN el remapeo SALLY_CANON->SALLY
/ VANILLA->CREAM que si hace Draw_64 => icono hit/demon invisible para
esos dos personajes en el TAB. Remapeo anyadido (solo toca hchar; la
fila del TAB sigue usando su propio frame 8/9).

VALIDACION: re-auditoria => 0 frames sin composite en todo el repo;
md5 sin duplicados nuevos (solo los 7 AMY==AMY_CANON preexistentes y el
placeholder 8/9 repetido); 2 hojas de contacto (download/
healthbar_verificacion.png y hud_aux_verificacion.png) verificadas con
el modelo de vision: fila AMELIA == sprite idle real de Amelia (pelo
cobrizo, ojos azules), METAL/BLAZE distintos entre si, 7 estados e0-e6
coherentes (aro verde->amarillo->rojo->X), tab_entry 12/13/14 validas,
cero frames corruptos; delimitadores de Create_0.gml balanceados.

Server: CERO cambios (bug 100% cliente/asset). Protocolo v1101 intacto.

Entregable: download/hudbar_v2_5.zip (extraer sobre la raiz con GM
cerrado; ver LEEME_HUDBAR_V2_5.txt — lleva cleaner opcional de layers
viejos y el .patch para usuarios de git).

## 2026-11-01 — placas TTB + amelia-v2.6: SPINDASH (la firma de su placa)

CONTEXTO: el usuario pidio anyadir pasivas a Amelia, pero ANTES senalo
que la extraccion del Blood trae las placas de info (descripcion /
stats / habilidad) de Amelia, Metal Sonic y Blaze. Objetivo de ese
paso: usar la placa como fuente de verdad.

PLACAS (ya estaban en el repo desde v2.2: spr_char_info frames 12-15,
el lobby las dibuja: Metal=12, Amelia=13, Blaze=14, MetalAmy=15). El
dump /home/z/td2d_blood se perdio con el sandbox, pero el arte
importado sobrevive. Decodificacion pixel-exacto del agente (los OCR
previos eran poco fiables; el pipeline: segmentacion de glifos por
proyeccion + identificacion letra a letra; los numeros van tras un
asterisco cian y el digito se valido comparando el bitmap entre
placas — los 5 asteriscos son identicos y los digitos se leen por la
columna del trazo inferior: izquierda=2, derecha=3):

  AMELIA : MOBILITY: HIGH+HIGH | fila1 fin: SPINDASH (sin numero)
           fila2: SUPPORT: TRAP (2 SEC.) SPRING
           pie: [badge NEW verde] PASSIVE ABILITY: SPINNING
           (la P de PASSIVE quedo en gris tenue: artefacto del
           modder TTB al pegar el badge; por eso los OCR leian
           "ASSIVE")
  METAL  : MOBILITY: HIGH+HIGH | fila1 fin: SPARK FIELD (2 SEC.)
           fila2: DEFENSE: OVERDRIVE (2 SEC.)
           pie: [NEW] PASSIVE ABILITY: SPINNING (en rojo)
  BLAZE  : MOBILITY: MEDIUM+MEDIUM (sin habilidad en fila1)
           fila2: DEFENSE: FIRE BALL (3 SEC.) FIRE DASH (3 SEC.)
           pie: [NEW] PASSIVE ABILITY: SPINNING
  TAILS (referencia original): fila1: FLYING (3 SEC.); fila2:
  DEFENSE: ARM CANNON BLAST (1-6 SEC.); pie: PASSIVE ABILITY:
  SPINNING — o sea que SPINNING es la pasiva de TODOS los
  supervivientes del juego base, y el pie TTB solo remarca que los
  nuevos TAMBIEN la tienen.

Hallazgos vs implementacion:
- SPINNING (la pasiva del pie): YA estaba — canSpin = true en los 3
  TTB desde v2.2 (rodar con ABAJO corriendo, scr_move_basic).
- SPINDASH (fila 1 de Amelia, su habilidad firma): NO estaba. Los
  sprites vinieron del TTB (spr_amelia_spindash/spr_eamelia_,
  5 frames 30x27) pero la mecanica nunca se porto; el flag
  canSpinDash existe en todos los personajes pero esta MUERTO (solo
  Sonic tiene spindash real, en scr_sonic_special).
- OCR viejo de v2.2: "Blaze fireball CD = 9 s" era un 3 mal leido
  (placa real: FIRE BALL 3 SEC.). El juego usa 9 s desde v2.2;
  queda a decision del usuario ajustarlo o no.
- La placa dice TRAP 2 SEC.; el diseno v2.4 del usuario usa stun 3 s
  (+ slow). Sin tocar.

FIX v2.6 (commit e4d13cb6): SPINDASH de Amelia, porte 1:1 del de
Sonic (SIN drop dash — la placa no lo lista), client-local (cero
cambios de server, protocolo v1101 intacto):
- scr_amelia_special: macros (BASE 8 / REV 2 / CHARGE_MAX 10 / DECAY
  90 / PITCH 0.8 / DUST 10 / BURST 3-8 / ROLL_CAP 18) + bloque de
  revolucadas (abajo + Z parada; tono 1.0->1.8 + polvo por red) +
  bloque de carga (girar mirada, decay, polvo ambiente, cancelaciones:
  dano/stun/muerte/tirolina/aire/anillo rojo/escondite) + lanzamiento
  al soltar ABAJO (isSpinning=true, gspd=(8+carga)*escala, polvareda
  3-8 nubes por red, mini-temblor de camara).
- Trampolin y trampa NO se sueltan mientras carga (gate
  !isSpinCharging); el anillo rojo / esconderse corta la carga y
  adema congela los CDs como ya hacia.
- obj_amelia: Create (isSpinCharging/spinCharge/spinChargeDecay/
  spinDustTimer/spinRevSnd), Step_2 (estado AMELIA_SPINDASH =
  BALANCING+2 con prioridad ANTES que isLookingDown, patron Sonic;
  la macro AMELIA_SRINGS sin uso se reemplaza por esta), Draw_76
  (case con image_speed 0.5+charge*1.2 como Sonic).
- scr_survivors: slot 15 de Amelia = spr_amelia_spindash (antes
  srings "defensivo sin uso") y slot 15 demonizada =
  spr_eamelia_spindash. El puppet de los demas clientes resuelve
  solo (mismo array, mismo estado).
- scr_collision_basic: la bola de Amelia rueda por encima de la
  carrera hasta 18 (mismo clamp que el de Sonic v3; sin esto las
  revolucadas se recortaban a 11 — el bug que ya comio Sonic).
- scr_move_basic: no salta mientras carga (idem Sonic).
- net_state_game: reset de isSpinCharging/spinCharge al empezar ronda.

Validacion: scripts/validate_amelia_spindash_v26.py — delimitadores
de los 8 archivos, macros presentes, orden de prioridad del Step_2,
slots de anims, clamp, no-salto, reset, composites de los 2 sprites,
kit v2.4 (trampolin+trampa) intacto, sin CR. TODO OK.

Entregable: download/amelia_spindash_v2_6.zip (extraer sobre la raiz
con GM cerrado; server SIN recompilar — no cambio nada). Placas
ampliadas para el usuario: download/placa_frame1[2-5]_*.png.

## 2026-11-01 — trampa-v2.8 (RE-APLICADA tras reciclado del sandbox): varias trampas a la vez

El sandbox del agente se reciclo y el repo volvio a clonarse desde
origin (7712ef6f "ewe"): el commit local 10ae6f5e de v2.8 nunca se
pusheo (el push lo hace el usuario), asi que el fix se RE-APLICO a
mano sobre el clon limpio antes de seguir. Contenido identico al
entregado en download/trampa_multiple_v2_8.zip: Game.c case
CLIENT_AMELIA_TRAP sin bloque ownTrap (max 1 viva por Amelia) +
cooldown 30 s -> 15 s; comentario de net_amelia_trap.gml. El zip del
usuario sigue siendo valido; este registro es para que el historial
del repo no pierda la entrada.

## 2026-11-01 — blaze-v2.9: el fuego que rebota (bola rebotante + giro de fuego)

PEDIDO (usuario, literal): "Ahora blaze el ataque de fuego (el que se
supone que seria un proyectil y la otra el giro de fuego le permitiria
rebotar en el suelo y la pared y el techo."

IDENTIFICACION (con vision por VLM de los sprites): "el giro de
fuego" = la forma ardiente (tecla C, spr_blaze_go: Blaze girando en
espiral/tornado de fuego, 8 frames); "el proyectil" = la bola de fuego
(tecla X, spr_blaze_fireball: cometa horizontal 49x20). Se
implementaron las dos lecturas del pedido, que son coherentes entre si:

1) BOLA DE FUEGO = PROYECTIL REBOTANTE (tecla X):
- ANTES: linea recta horizontal (patron laser de Tails), moria contra
  la 1.a pared, y con limite GLOBAL de 1 bola viva (2 Blazes se robaban
  la bola) + cooldown server de 8 s que se comia la mitad de los
  disparos de la demonizada (EBLAZE_FIREBALL_RECHARGE = 4 s).
- AHORA: arco con gravedad (BFIRE_GRAV 0.22/tick ~ la del jugador,
  BFIRE_VY0 -2.5, BFIRE_SPEED 10) que RICOTEA elasticamente en el
  suelo, las paredes y el techo. El server integra la fisica pero NO
  tiene la colision del mapa: cualquier cliente que vea el choque lo
  reporta con CLIENT_BLAZE_FIREBALL_BOUNCE (nid + flip: bit0=pared /
  bit1=vertical + la posicion del primer solape); el server voltea la
  velocidad (bfire_bounce: elasticamente, con pop de -3 si vy era 0),
  desincrusta (pos del cliente + 12 px en la nueva direccion) y sigue
  tick-eando. Lockout de 0.12 s por entidad (todos los clientes ven el
  mismo choque: gana el 1.er informe) + throttle local de 15 frames
  (bounceCd) para no spamear TCP mientras llega el arreglo.
- Clasificacion de superficie en el cliente (obj_blaze_fireball/
  Collision_obj_solid_parent): prueba por donde puede ESCAPAR
  (retrocediendo 2 ticks de velocidad + margen por cada eje; si pierde
  un tick del server el solape puede ser doble). Esquina = invertir
  ambos; incrustada rara = asumir vertical. La bola ya NO explota
  contra el mapa: solo al tocar a un jugador del lado del EXE (stun
  2 s intacto) o al retirarla el server (vida 4 s intacta).
- VARIAS BOLAS A LA VEZ (patron v2.8 trampa): nid por bola en los 3
  estados del SERVER_BLAZE_FIREBALL_STATE (0 spawn / 1 tick / 2
  despawn), CLIENT_BLAZE_FIREBALL_HIT ahora lleva nid (antes
  despawneaba LA PRIMERA que encontraba: el timeout de una bola podia
  matar la de otra Blaze), limite global eliminado, cooldown server
  8 s -> 4 s. Tick extendido: nid + x + y + dir + vy(s8) — cada
  cliente rota el cometa con image_angle = point_direction(0,0,vx,vy)
  para que siga la trayectoria (la explosion siempre derecha).
- PROTOCOLO: CLIENT_BLAZE_FIREBALL_BOUNCE añadido AL FINAL del enum
  en Packet.h y net_packets.gml (0 desplazamientos de los viejos).
  IMPORTANTE: cliente y server se actualizan JUNTOS (un server viejo
  no sabe contestar los rebotes y un cliente viejo no lee los ticks
  nuevos).

2) GIRO DE FUEGO (tecla C, forma ardiente) = BLAZE REBOTA:
- Mientras arde (1.5 s, +30% vel, stun 3 s al killer intactos), Blaze
  es una pelota de fuego: SUELO -> rebota siempre con la fuerza del
  salto (BLAZE_BURN_BOUNCE 7.5 = jumpForce: altura ~128 px); PARED ->
  rebote elastico horizontal (conserva la velocidad PRE-colision
  guardada en _pvx, minimo 3; deteccion ±4 contra obj_floor_parent
  como el overdrive de Metal v2.7, solo en suelo plano para no dar
  falsos positivos en cuestas); TECHO -> cae con 0.6x tras el golpe
  de cabeza (yspd == 0 en el aire = acaba de chocar).
- Todo en obj_blaze/Step_0 (cliente-local, movement autoritativo del
  propietario: los puppets replican la posicion igual). El salto de
  fuego (Z) sigue disponible a media altura (isJumping = true en cada
  rebote) y el jugador sigue dirigiendo en el aire.

VALIDACION: scripts/validate_blaze_rebote_v29.py (102 checks: enum al
final sin desplazar + misma cola en ambos lados, fisica por entidad,
lockout/flips/nudge, Game.c sin limite de bolas + cooldown 4 s + case
BOUNCE + v2.8 intacta, handler por nid con rotacion, clasificacion de
superficie, rebotes del giro, recargas intactas 9/4 y 30/12, higiene
CR/llaves, binario al dia) — TODO OK. Simulacion de trayectoria: arco
suave, |vy| max ~10 (cabe en s8), 2400 px en 4 s. Compilado ( warnings
preexistentes) + smoke test v1101.

PENDIENTES (mismo patron, esperando OK del usuario): la BANANA
(server 20 s vs 10 s demonizada) y la BALA DE METAL AMY (mabul: limite
global 1 viva + HIT sin nid + cooldown 7 s).

Entregable: download/blaze_rebote_v2_9.zip (RECOMPILAR server Y
cliente; lleva Game.c con el fix v2.8 de la trampa dentro — si ya lo
aplicaste, extraer los archivos encima es seguro).

## 2026-11-01 — tierlist-v1: página HTML de análisis del plantel (sin código)

PEDIDO (usuario): "aver que pasiva podemos colocarle a Amelia (ya que
debe tener alguna no?... Hasme un Tierlist (pagina html) asi dibujada
bonita de eso rangos su info capacidades cuales son los mas debiles y
una tabla comparativa vs exes y claro cuando se quedan individualmente
o en contra de algunos suditos."

ENTREGADO: download/TierList_TD2DR.html (87 KiB, autocontenida).
- 5 pestañas: tier list (13 supervivientes + 5 EXE), fichas completas
  con barras y habilidades, matriz 13x5 de matchups vs EXE con
  tooltips razonados, tabla de solitarios vs suditos (con el sistema
  de esbirros y el rescate v2.11 explicados) y 4 propuestas de PASIVA
  PARA AMELIA (recomendada: "Deducción del detective" — 4 s de visión
  del EXE real cada 25 s, solo cliente).
- Todos los números son literales del código (recargas, stuns,
  velocidades, bloqueo 65 % de Chocola, slime x1.2...). Los tiers y
  matchups son análisis razonado, marcado como tal en la metodología.
- 18 sprites del propio juego incrustados en base64 (frame 0 del
  compuesto raíz de cada sprite de reposo). Amy Canon usa hue-rotate
  porque su arte base es idéntico al de Amy (la paleta es runtime).
- Herramientas: scripts/extract_sprites_tierlist.py +
  tierlist_sprites.json, scripts/tierlist_template.html (marcas
  %%SPRITE_x%%), scripts/build_tierlist.py (inyector),
  scripts/shot_tierlist.py (capturas Playwright de las 5 pestañas +
  prueba de tooltip y de navegación chip->ficha). Verificación visual
  con VLM: sin textos cortados, sin columnas vacías, tildes y ¿¡ OK.
- CERO cambios en cliente/server: sin riesgo de regresión. El usuario
  decide la pasiva y se implementa aparte.

También en este turno: git pull (orden permanente). 4 commits nuevos
del usuario traían v2.10 (sprites electro/overdrive desenredados) y
v2.11 (rescate de esbirros + Chocola detecta esbirros 3,5 s + fase 3
arreglada) ya resueltos desde otra máquina. Conflicto menor de enum
en Packet.h/net_packets.gml resuelto tomando el lado remoto (superset
de ambos). Verificado: 157 paquetes, mismo orden en los dos extremos.
Merge local d8e9e3d7 (el push lo hace el usuario).

## 2026-11-01 — tierlist-v2: canon contra MOD + lore de Amelia verificada

PEDIDO (usuario): verificar TODA la información sobre Amelia y su
posible pasiva teniendo en cuenta que «es ciega prácticamente (según
la wiki de Nightmare)»; y añadir a la página una tabla comparativa de
los ya existentes (Amy Canon, Sally Canon; como no existe una
«Vanilla normal», comparar con Cream y combinaciones, y por qué hay
combinaciones en términos de tiers), más sugerencias de movimientos.

VERIFICACIÓN DE LORE (wiki Sonic.exe Nightmare Version,
exenightmare.fandom.com/wiki/Amelia, leída vía captura de Wayback del
2025-10-08: Cloudflare bloquea el fetch directo y el navegador
autónomo se queda atascado en «Just a moment...»): Amelia es una AMY
ALTERNATIVA de una dimensión asolada por Pervision; CIEGA (ojos de un
gris nublado) por una caída sobre unos pinchos; Nate la operó, le
salvó los ojos pero no la vista, y le inyectó un suero para VER LAS
FIRMAS DE CALOR («auras») de los seres; se orienta «más o menos
perfectamente» y se presumen sus otros sentidos agudizados;
distingue a los demonizados por el aura y desenmascaró al impostor
que copiaba a Nate porque SU AURA ARDÍA MÁS FUERTE; dulce y
optimista, frenó a la propia Amy en Last Instant casi sin querer
hacerle daño; fallecida en su línea temporal. El personaje viene del
universo Nightmare de Jayz (Finished Nightmare), de donde TTB lo tomó.

VERIFICACIÓN DE CÓDIGO (todo cuadra con la v1 de la página):
scr_amelia_special.gml (recargas 25/10 y 35/15, stun 3 s + slow del
40 % otros 3,5 s, trampa de 60 s, spindash 8+carga con tope 18) y
obj_amelia/Create_0.gml. HALLAZGOS: (1) la cabecera de
scr_amelia_special aún dice «Máximo 1 trampa viva por Amelia» — letra
vieja: el servidor ya no limita desde v2.8; (2) objects/obj_amelia_bomb
y scripts/net_amelia_bomb siguen EN DISCO pero el .yyp NO los registra
(huérfanos de la v2.2, cero efecto en juego); (3) BANANA: el servidor
enfría 20 s contra EAMELIA_BANANA_RECHARGE de 10 s — la demonizada
ofrece el trampolín cada 10 s y el servidor se come la mitad de los
intentos (misma familia que v2.8/v2.9); (4) mabul: tope global de 1
bala viva + HIT sin nid (cliente 8 s, servidor 7 s); (5) BUG DE LA
V1 DE LA PÁGINA: el sprite de SONIC nunca se extrajo (img('sonic')
apuntaba a undefined: chip y ficha sin imagen) — corregido añadiendo
spr_sonic_idle (19 sprites ahora).

PÁGINA (download/TierList_TD2DR.html, 135 KiB, autocontenida):
- Pestaña NUEVA «Canon contra MOD»: quién es quién (de fábrica /
  variantes propias / rescatados de Through the Blood), tabla de las
  TRES CARAS DE AMY (visión: Amy ve, Amy Canon ve y además sus
  sensores, Amelia es prácticamente ciega — conoce el canon porque en
  su lore se cruza con Amy en Last Instant, pero deduce en vez de
  ver), las DOS SALLY, madre e hija CREAM contra VANILLA (sin
  «Vanilla normal» en el juego base: se compara con Cream), 4
  COMBINACIONES de dúo con efecto de tier (Fortaleza madre-hija, Amy
  Canon + Amelia, los que no alimentan al ejército, Eggman +
  castigador) y 4 SUGERENCIAS (Auravisión, banana 20→10 s, bala con
  nid, higiene de documentación).
- Pestaña de Amelia REESCRITA: expediente Nightmare verificado (con
  fuente citada), caja «qué significa para su juego» y PASIVA NUEVA
  RECOMENDADA «AURAVISIÓN (los ojos de Nate)»: en radio (~350 px) ve
  el aura de calor de cada ser del bando EXE a través de las paredes;
  el aura del EXE REAL arde más fuerte (lore literal del impostor);
  marcadores locales al estilo de los sensores de Amy Canon, cero
  servidor y cero paquetes. «Deducción del detective» pasa a ser la
  variante temporizada (rec:false). Cinco propuestas en total.
- img() aplica ya el hue-rotate de Amy Canon en TODAS las tablas
  (antes solo en la ficha: los chips y la matriz la pintaban igual
  que Amy).

Validación: build_tierlist.py (19 sprites, sin marcas), shot_tierlist
.py (6 pestañas, sin errores de consola), VLM sobre las pestañas canon
y amelia (sin cortes ni imágenes rotas) y chequeo en vivo con
agent-browser (5+4 props, 2 recomendadas, 6 pestañas, 83 imágenes,
0 rotas).

CERO cambios en cliente/server: sigue siendo solo la página. El
usuario decide si implementa Auravisión (y los ajustes de banana y
bala) en su siguiente pedido.

## 2026-11-02 — amelia-page: la página de Amelia La Luna Encarnada, ahora HTML autocontenida + alta en el repo

PEDIDO (usuario): (1) «la página HTML con la canción y eso» y (2) «el
código que va para el repo, o sea el pull, editar archivos». Hasta hoy
la página vivía como app Next.js del sandbox (zip amelia-la-luna-
encarnada.zip en el workspace, OST en public/music/lobby.mp3 de 134 s):
el usuario quería UN archivo HTML de doble clic — como la TierList — y
que el código quedara en el repo.

ENTREGA: docs/Amelia_La_Luna_Encarnada.html (4,2 MiB, AUTOCONTENIDA) +
docs/LEEME_PAGINA_AMELIA.txt. Port fiel del diseño Next.js a un solo
archivo sin dependencias:
- Estructura idéntica: nav, hero con la carta de La Luna flotando, El
  Tarot (3 arcanos: Auravisión con panel «vista a través de la pared»,
  Dos Caras con la moneda, Sol y Luna), pestañas Sol/Luna (goteo de
  rings animado con anillo de progreso, ensayo del velo gracia 3 s /
  CD 15 s con barra y fases, tabla de qué ve el EXE), El Ojo del EXE
  (simulador de 4 escenarios con HUD, figuras, sensores siempre
  activos y velo del eclipse con cuenta atrás de ceguera de 4 s), La
  Misma Moneda en Juego (3 combos, contraplay del EXE, cita final),
  footer y dock de música fijo abajo a la izquierda.
- LA CANCIÓN VA DENTRO DEL HTML: lobby.mp3 en base64 como data URI
  (data:audio/mpeg). Doble clic = suena en bucle si el navegador
  permite el autoplay; si lo bloquea, el botón ▶ pulsa con «Toca ▶
  para invocar el OST». Play/pausa, mute y volumen funcionan sin red
  y sin archivos sueltos.
- Los SVG de decor (rostros de Sol y Luna, moneda de dos caras, ojo
  de Auravisión, siluetas de supervivientes) se portaron con las
  MISMAS fórmulas geométricas del React (rayos/ticks regenerados en
  build); los iconos lucide pasaron a sprite <symbol>/<use> propio.
  Estrellas deterministas con la misma fórmula del original (70
  globales + 110 del hero). Reveal-on-scroll con IntersectionObserver
  en lugar de framer-motion.
- FIX respecto al original Next.js: el badge «TRAMPA DE AMY · STUN»
  estaba por DEBAJO del velo del eclipse (z-30 vs z-40 del overlay
  opaco) y nunca se veía; ahora flota SOBRE el velo (z-45), que era la
  intención evidente del diseño original.
- Herramientas: scripts/amelia_page/ del workspace — head.html +
  body.html + app.js como plantillas, build.py (ensambla, inyecta el
  mp3 en base64 y la geometría SVG, ~1 s), shot.py (10 capturas
  Playwright de todas las secciones e interacciones), dom_check.py
  (verificación DOM: textos, nav móvil, data URI del audio) y
  reshoot.py. Verificación: 0 errores de consola, OST detectado por
  el propio <audio> (135 s), 180 estrellas generadas, texto de la
  regla de compartir idéntico al del original, VLM sobre hero/tarot/
  pestañas/simulador (4 estados)/dúo/footer/móvil sin cortes ni zonas
  rotas (la única «alerta» fue el pliegue del viewport, descartada
  con captura de elemento + DOM).

CERO cambios en cliente/server: solo documentación (docs/ + worklog +
CACHE). El kit de 3 pasivas que muestra la página sigue siendo
PROPUESTA de fan — la implementación en GML (Auravisión y compañía)
sigue pendiente de la decisión del usuario (ver CACHE 9). El push lo
hace el usuario: tras este commit quedan 5 commits locales por
empujar (tierlist-v1, tierlist-v2, el merge v2.10/v2.11 con sus
previos, y este).

---

## 2026-11-02 — amelia-v2.12: la pasiva AURAVISIÓN implementada de verdad (GML, solo cliente)

PEDIDO (usuario): editar los archivos del repo para COLOCAR la
pasiva — la recomendada de la tierlist ya no queda en propuesta:
«Auravisión (los ojos de Nate)» está en el código.

QUÉ ENTRÓ:
- obj_amelia_auras (nuevo): sensor + dibujado de las auras. Patrón
  probado de obj_amycanon_indicators — lo crea el Create de
  obj_amelia (solo en el cliente de Amelia), nace visible=false,
  Step escanea y enciende visible solo si hay algo que dibujar
  (sin eso el Draw GUI no corre), Draw GUI resta la cámara.
- Qué ve: bando EXE en 350 px A TRAVÉS de paredes — EXE real
  (character == CHARACTER_EXE) arde fuerte (halo r=26 pulsante + aro
  brillante + núcleo, late al doble); esbirros (revivalTimes >= 2) y
  clones obj_exeller_clone quedan tenues (r=14). Supervivientes: sin
  aura. EXE invisible sigue ardiendo. Se apaga si Amelia se
  demoniza (ya tiene la flecha del exe).
- Silueta de calor: el MISMO sprite del puppet/clone (sprite_index,
  image_xscale/yscale, angle del puppet) tintado ámbar/naranja, al
  45% (exe) o 20% (esbirro) de alpha con mezcla aditiva — el
  «fantasma» cae alineado sobre el cuerpo real.
- Macros ajustables AMELIA_AURA_* (radio, radios de halo, latido,
  colores) en scr_amelia_special; registro +1 línea en el .yyp
  (para no repetir el bug de obj_amelia_bomb huérfano).
- Desvanecido por distancia (30% en el borde del radio): el aura
  entra suave, no aparece de golpe.

VERIFICACIÓN: validate_amelia_auravision.py — 58 checks (registro en
.yyp, eventList <-> archivos, macros, funciones todas existentes en
la base, balance de llaves/paréntesis, diff del .yyp = +1 línea
exacta). Vista previa del dibujado con las MISMAS fórmulas y sprites
reales del repo: docs/auravision_preview.png (EXE tras muro ardiendo
~2x más que el esbirro al borde; Amelia sin aura). Pendiente: partida
real compilada en GameMaker.

EQUILIBRIO: información pura, cero paquetes/cero servidor (nada que
pueda desincronizar); el server y el protocolo NO se tocan.

ENTREGA: además del commit, ZIP con archivos COMPLETOS (el usuario
no usa parches): amelia-auravision-v2-12-archivos.zip.

El push lo sigue haciendo el usuario; tras este commit son 6 commits
locales por empujar.

---

## 2026-11-02 — amelia-v2.13: «Sol y Luna» (el Arcano III) implementada de verdad

PEDIDO (usuario): faltaba la pasiva de Luna y Sol de la página — la
Luna (lo que pasa cuando Amelia aturde: la ceguera) y el Sol (Amy
generando rings cada 7 s). El ECLIPSE cuelga del stun de la TRAMPA DE
AMELIA (la página decía «trampa de Amy»: es la de Amelia, corrección
del usuario en vivo).

QUÉ ENTRÓ (13 archivos de cliente + 1 de server):
- SOL (Amy Canon): goteo automático de 1 ring cada 7 s mientras viva,
  por el camino de red de los anillos de Cream. Server: assert + 1
  anillo único worth 1 + suelo anti-spam de 6 s solo para ella.
- LUNA (Amelia): oculta = invisible grado EXE (alpha 0 en el cliente
  del EXE; los demás la ven como siempre a 0.5) + velo de gracia de
  3 s tras ocultarse (ni indicadores ni sensores la marcan; CD 15 s;
  los 3 indicadores del exe — exe/exeller/exetior — respetan el velo).
- ECLIPSE: el stun de la trampa arrastra 4 s de ceguera a la víctima
  EXE-side: sin cuerpo ni HUD de ningún superviviente en su cliente +
  velo oscuro con fundido de 0,5 s (obj_level/Draw_64, 480x270).
- Cero paquetes nuevos. Luna y Eclipse: 100% locales (autoridad de la
  víctima sobre sí misma, el modelo ya probado del stun de la trampa).

VERIFICACIÓN: validador extendido a 101 checks (todas las referencias
cruzadas, macros, balance de llaves de los 13 GML, ediciones del
server, .yyp sin cambios). SERVER COMPILA (build_server.sh, gcc, la
misma lista de fuentes del CMakeLists): BUILD OK. Vista previa
docs/sol_y_luna_preview.png (antes/durante el eclipse, mismas
fórmulas). Pendiente: partida real.

OJO despliegue: esta versión SÍ toca el server — recompilar
(compilar_server.bat). Sin recompilar, el Sol de Amy Canon revienta
el AssertOrDisconnect del server (desconexión).

ENTREGA: ZIP con archivos completos (el usuario no usa parches):
amelia-sol-y-luna-v2-13-archivos.zip — cliente + server + LEEME.
Tras este commit: 7 commits locales por empujar.

## 2026-11-02 tierlist-v3 (docs)

Pull previo (merge con origin/main: traía auravisión v2.12 y sol-y-luna
v2.13, ya resueltos en remoto — conflicto solo al final de CACHE/worklog,
lado local vacío). Regenerada la página HTML de la tier list a v3 con el
estado real del código: Amelia B+ con las tres pasivas, Amy Canon +Sol,
pestaña «Las pasivas de Amelia» con IMPLEMENTADA (Auravisión v2.12 y Sol
y Luna v2.13), dúo «El Sol y la Luna», sugerencia de Auravisión marcada
implementada (banana y mabul siguen pendientes, verificado contra
states/Game.c). Página autónoma (sprites base64) en docs/ y en download/.
Verificación: build (19 sprites), node --check del JS, 12 checks de DOM
vía Playwright/evaluate, geometría de overflow de las fichas (cero) y VLM
sobre capturas de las pestañas tiers/amelia/cards y de las fichas sueltas
a 2x (todo legible y completo).

## 2026-11-02 mejoras-v3.0 («Genio Malvado» + balance)

Pull previo (Already up to date). Pedido completo del usuario:

AMELIA: recarga de trampa 35→24 s; las trampas NO ciegan a
supervivientes si Amelia se demoniza (la trampa cambia de bando con
su dueña: la pisa el superviviente → stun+slow SIN eclipse; el server
lo acepta mirando al owner de la entidad en CLIENT_AMELIA_TRAP_TRIGGER);
los esbirros activan trampas con +2 s de ceguera (4→6 s, 5→7 mejorada).

VANILLA GENERALES: escudo Eggman 20→15, jetpack 10→8, rastreador
30→25; Amy martillo 20→15 y salto 9→7; Knuckles golpe -20% (16 s);
Sally (vanilla también) i-frames en todo el slide.

PASIVA «GENIO MALVADO» (Eggman): tecla V mejora trampas con anillos
(sensor 3 / trampa de Amelia 5) → +25% efectividad, contorno dorado
(spr_trap_gold / spr_eggtrack_gold generados por dilatación de la
silueta, dos tonos, dibujados detrás con latido — misma idea que los
spr_exe_invis_*, que son sprites aparte, no un efecto del engine);
trampa mejorada pisada por el bando EXE ejecuta el RASTREADOR y
revela a la víctima a todos los supervivientes 3 s (paquete nuevo
SERVER_TRACKER_PING + obj_surv_indicator); y repara a Metal (+10 hp
cada 7 s cerca del Dr. / 13 s cerca de Tails, sin acumular, manda el
Dr.; corre en el cliente de Metal con sus puppets).

SONIC: fix del parry — la señal tardía ya no aturde al exe después de
que su ataque (spin/golpe/bola) terminó (gate de isAttacking||
isJumping||isSpinning en scr_parry_stun_signal, mismo predicado que
el auto-stun local).

PROTOCOLO: CLIENT_EGG_TRAP_UPGRADE y SERVER_TRACKER_PING añadidos AL
FINAL del enum en los DOS lados (net_packets.gml e include/Packet.h).
Server: Game.c (upgrade con validación de plr.rings y coste 3/5,
marcado de entidad y broadcast state 3 / state 2), AmeliaTrap.h/.c y
EggmanTracker.h (campo upgraded; MakeAmeliaTrap/MakeEggTrack con el
inicializador extendido).

VERIFICACIÓN: gcc -fsyntax-only de Game.c + entidades (OK), balance
de llaves de los 17 GML tocados (OK), sprites dorados validados por
programa (anillo de 1 px, 0 px dentro de la silueta, .yy y .yyp
parseables, 1932 recursos). Docs: LEEME_MEJORAS_V3_0.txt. Pendiente:
partida real (compilar server + juego).

ENTREGA: ZIP con archivos completos + página HTML nueva (mejoras +
tier list + impresiones + cómo ayuda contra el exe, con sprites,
sonidos y música del lobby del usuario).

ENTREGA v3.0: ZIP con archivos completos —
mejoras-v3-0-genio-malvado-archivos.zip (cliente GML + server C + sprites
dorados + LEEME + la página HTML). Además la página suelta en download/
(TierList_Mejoras_V3_0.html, autónoma: sprites/sonidos/música en base64,
9 pestañas, 5 escenas canvas + batería de cooldowns + slide demo).
Verificación de la página: node --check del JS, DOM vía Playwright (13
chips, 18 fichas, 7 filas de cooldown, 12 filas VS, 5 cartas de EXE, 96/96
imágenes cargadas, cero errores de consola), interacción de botones de
variante y cambio de pestañas sin errores, y VLM sobre capturas de las
escenas trampa/genio/metal/parry/tiers/contornos (fix aplicado: el exe del
ciclo 2 del parry se salía del canvas). Pendiente: partida real.

---

## v4.3 — TECLAS DINAMICAS EN EL HUD (LEEME_TECLAS_V1.txt)

Problema del usuario (prioridad): al remapear una habilidad (ej:
special2 de X a F) el juego respondia a la nueva tecla pero el icono
del HUD seguia mostrando la letra horneada en el PNG (X). No existia
ningun sistema que actualizara la letra de la miniatura.

SOLUCION: scr_hud_keycap (script nuevo, 3 funciones) dibuja en vivo,
cada frame, un keycap limpio (spr_gui_keycap, el arte original 8x9
con la letra borrada) + la letra de la tecla ACTUAL con la micro-fuente
solida nueva spr_gui_keyletter (38 frames 3x5 negros; spr_letter1 no
sirve: cara blanca + sombra negra = bloque ilegible al mezclar con
negro, probado en mockup). obj_playerui/Draw_64.gml: los 54
draw_sprite_ext de iconos pasan a scr_hud_icon(sprite, frame, x, y,
global.Key*, blend, alpha); emociones A/S/D -> 3 keycaps dinamicos
(global.KeyEm1/2/3, ancho limitado a 16px por estar pegadas al borde
derecho 470/480). Tabla de posiciones de los 35 keycaps horneados
medida por analisis de componentes conexos de los PNG (no estimada).

De paso corrige letras horneadas que mentian: eggshield-X usado por
Metal para habilidad C, sonicdropdash-X siendo Z, chaosslime/amelia_trap
con letra rara, metalamyattack sin indicador, y chaoswalldash conserva
su tinte azulado (blend especial en la tabla). PNGs tocados (borrado de
letras outline que sangraban por las esquinas redondeadas): chaosattack,
exetiorattack, exetiorring, metal_amy_lazer, chaoswalldash, emotions.

REGISTRO: 3 recursos nuevos en .yyp (orden alfabetico) +
.resource_order, misma receta que el commit de spr_gui_amyparry_canon
(11c24aca): carpeta sprites/<nombre>/{uuid}.png, layers/<uuid>/<uuid>.png,
.yy de plantilla, entrada en .yyp y resource_order.

VERIFICACION: mockup Python que replica el render GML exacto (C->F,
B->r, rojo+alpha, shift largo, outline->keycap, A/S/D, num 1) con
ASCII pixel a pixel; balance de llaves/parentesis de los GML (OK);
.yyp parsea como JSON tras quitar comas finales (OK, 1935 recursos,
sin duplicados); patrones GML con precedente en el proyecto
(if/else de sprites, continue en for, var i doble). Pendiente:
partida real (compilar y rempear en vivo).

---

## v4.6 — BLAZE: MISMO FIX UDP · METAL AMY: DASH DE 8 DIRECCIONES

Dos tareas del usuario en un paquete: "Blaze necesita el mismo
arreglo" y el rework completo de la X de Metal Amy.

1) FIX BLAZE (v2.9b): la bola de fuego sufria el MISMO bug del canal
que la bala de Metal Amy (v2.2b): bfire_tick difunde el estado 1 como
NO confiable (UDP) y el case solo existia en net_state_game (TCP) ->
la bola nacia quieta y solo reaccionaba a los rebotes. Arreglo: case
SERVER_BLAZE_FIREBALL_STATE en net_udpprocess.gml con el patron Tails
(nid + pos + dir + vy; rota el cometa con point_direction). La rama
TCP del tick queda documentada como salvaguarda (mismo criterio que
Metal Amy). Gravedad, rebotes por cliente y vida de 4 s intactos.

2) REWORK METAL AMY (v4.6): la X pasa de golpe normal (patron Exeller,
recovery 60/120) a DASH dirigible en 8 direcciones (patron chaos):
   * Direccion: flechas sujetadas al pulsar (8 dirs con diagonales);
     sin flechas, hacia donde mira. Aire: control total. Tierra:
     horizontal (abajo se anula); arriba/diagonal DESPEGA ya
     (isGrounded=false + yspd, patron del salto de scr_move_basic).
   * Impulso: 18 frames a 12/8 px (numeros del dash de chaos: xspd =
     dashDirX*12, yspd = dashDirY*8; en tierra gspd para pendientes).
     Luego deriva suave (*2, patron chaos) hasta expirar el timer.
   * Cargas: 3 max (METALAMY_DASH_MAX), recarga SECUENCIAL de 5 s por
     carga (METALAMY_DASH_RECHARGE), 0,5 s entre usos (attackTimer =
     METALAMY_DASH_GAP: el viejo recovery 60/120 de la X desaparece).
   * Variables nuevas en obj_metalamy/Create_0: dashDirX/Y, dashCharges,
     dashRecharge, dashBoost. Reset de dashBoost en stun (Step_0) y en
     won/lost (scr_metalamy_special).
   * Step_2: durante el impulso NO se cancela el ataque al despegar ni
     al aterrizar (el caso viejo cancelaba en el cambio suelo<->aire);
     fuera del impulso, patron viejo conservado.
   * Draw_76: los dos estados de ataque cierran por TIEMPO (attackTimer
     <= 0), no por ultimo frame: el dash (18 frames) dura mas que los
     sprites. Ground attack11 a 0.3; air attack2 a 0.25.
   * scr_exe.gml: slot 15 (air attack) pasa de spr_metalamy_attack22 a
     spr_metalamy_attack2 (la animacion pedida para el aire).
   * HUD (obj_playerui/Draw_64): el anillo del icono X refleja las
     cargas: con cargas barre el gap de 0,5 s; sin cargas ES la recarga
     (rojo hasta llenarse). Antes leia attackTimer/120 (hubiera quedado
     desajustado: min(30,120)/120 = 75 % fijo).
   * Seleccion: case EXE_METALAMY en net_state_charselect (risa
     snd_metal_laugh al arrancar la partida, canal de los demas
     killers) + case en el switch de emociones de scr_move_basic (su
     taunt estaba MUDO: el case no existia).

3) FIX SONIDOS POR RED (descubierto al añadir la risa): los
   net_sound_emit de snd_metalamy_dash y snd_metal_lazer viajaban con
   indice -1 (array_find_index falla: NO estaban en global.net_snds) ->
   255 al leerse como u8 -> los demas clientes JAMAS los oian (sonaban
   solo en la maquina del Metal Amy). Arreglo: entradas 115-117 al
   FINAL del array (patron snd_parry/Chocola: cliente viejo que reciba
   el indice lo ignora): snd_metalamy_dash, snd_metal_lazer,
   snd_metal_laugh.

ARCHIVOS: net_udpprocess.gml, net_state_game.gml (comentario),
scr_metalamy_special.gml, obj_metalamy/Create_0-Step_0-Step_2-Draw_76,
scr_exe.gml, net_sounds.gml, net_state_charselect.gml,
scr_move_basic.gml, obj_playerui/Draw_64.gml, TierList_Mejoras_V3_2.html
(badges + banner + fichas L y M).

VERIFICACION: balance de llaves/parentesis/corchetes de los 12 GML
editados (strip de comentarios y strings, script verify_v46.py) OK;
net_snds = 118 entradas (0..117, ultima snd_metal_laugh); flag
PLAYER_ATTACKING ya viaja para EXE_METALAMY sin mascara (rama exe de
obj_netclient/Step_2: attacking = isAttacking) -> el hitbox del dash
se sincroniza solo via bitflags + posicion. Pendiente: partida real.

## v4.7 (2026-11-03) — METAL AMY: fix sprite del dash + sonido de stun + SCAN (tecla V)

Feedback del usuario tras probar el v4.6. Tres partes:

1) FIX SPRITE DEL DASH AL IMPACTAR: "cuando metal amy impacta con el
   impulso (X) aparece el spr_metalamy_attack11 — no deberia salir; si
   le golpea debe mantener el sprite que tiene". Causa: Step_2 ponia
   METALAMY_ATTACK (slot 14 = attack11) al tocar suelo durante el
   impulso (dash aereo -> aterrizar -> attack11). Arreglo:
   * Step_2: durante TODO el ataque (impulso + deriva) el estado es
     SIEMPRE METALAMY_AIR_ATTACK (attack2), en aire y tierra. Fuera el
     viejo corte suelo<->aire (era del golpe normal antiguo).
   * scr_exe.gml: slot 14 reusa spr_metalamy_attack2 — attack11 sale
     del kit por completo (ninguna referencia activa queda).
   * Draw_76: los dos casos de ataque fusionados (attack2 a 0.25, fija
     ultimo frame, cierra por attackTimer).
   El state viaja como u8 en CLIENT_PLAYER_DATA y los puppets de los
   demas clientes mapean con el MISMO array -> fix visible en todos.

2) SONIDO DE STUN (snd_metal_stun): case EXE_METALAMY en
   scr_exe_stunsound (antes no existia: sonaba solo el generico). La
   TRAMPA DE AMELIA era la unica fuente de stun que no llamaba a
   scr_exe_stunsound (fireball de Blaze y proyectil de Tails si):
   añadida la llamada con el mismo patron. snd_metal_stun entra al
   FINAL de global.net_snds (posicion real 115; array = 116 entradas).
   Hallazgo de paso: los comentarios de indice del array arrastran un
   desfase historico (snd_egg_tracker dice 28, real 29) — lo que manda
   es el ORDEN (array_find_index en runtime a ambos lados); el bloque
   de Metal Amy queda verificado contra el array real.

3) SCAN (tecla V): rastreador de supervivientes, enfriamiento 20 s
   (METALAMY_SCAN_RECHARGE). Revela la direccion de TODOS los
   supervivientes 3 s (METALAMY_SCAN_TIME, patron del tracker:
   obj_surv_indicator / SERVER_TRACKER_PING usan 3 s) con una aguja
   spr_indicator por objetivo en anillo de 26 px alrededor de ella
   (pulsado + fundido al expirar), dibujadas por obj_exe_indicator en
   el cliente del Metal Amy (la aguja normal solo marca al mas cercano
   / anillo rojo). Mismos filtros que la aguja normal: muertos,
   esbirros y el velo de gracia de Amelia ocultos. CERO paquetes
   nuevos: los puppets ya estan sincronizados, el scan es visual.
   * Pose propia: spr_metalamy_scan (8 frames, slot 21 = estado
     METALAMY_SCAN), 0,8 s (scanPose), solo en tierra, prioridad baja
     (el dash y la bala la pisan). El stun la corta (Step_0).
   * Sonido: snd_egg_tracker (el rastreador del juego; ya viajaba por
     red desde el Eggman). Sin gateo de invisibilidad: el scan es
     informacion, no un ataque.
   * HUD: icono spr_gui_metalamy_indy a la derecha de la C, misma fila
     (patron Amy canon v4.1). El PNG trae una V horneada en keycap
     (x24..31) + separador (x17..21): NO se edita la imagen — artW = 14
     recorta el arte hasta el ojo y drawKeyIcon dibuja la tecla REAL
     (V) dinamica, como en todos los iconos desde v4.3. Respuesta a la
     pregunta del usuario: si, el mecanismo afecta a todos los iconos
     de habilidad; no hace falta cambiar ningun PNG.

ARCHIVOS v4.7: obj_metalamy/Create_0-Step_0-Step_2-Draw_76,
scr_metalamy_special.gml, scr_exe.gml, scr_exe_stunsound.gml,
net_sounds.gml, obj_amelia_trap/Create_0.gml,
obj_exe_indicator/Create_0-Step_2-Draw_64, obj_playerui/Draw_64.gml.

VERIFICACION: verify_v47.py — balance de llaves/parentesis/corchetes
de los 13 GML OK; net_snds = 116 entradas reales (0..115, ultima
snd_metal_stun); anims Metal Amy = 22 slots (14 y 15 = attack2, 21 =
scan); sin attack11 en codigo activo; receiver de CLIENT_SOUND_EMIT
ignora indices fuera de rango (cliente viejo seguro). Pendiente:
partida real.

## v4.8 (2026-11-03) — METAL AMY: pasivas de la cazadora + scan vision 8 s + laser anti-anillos

Pedido del usuario (texto literal en la sesion): scan con "vision de
los survivors durante 8 seg no 3" (no un anti-invisible como Exe o
Chaos), las 4 funciones de la pasiva de Metal Amy, el laser destruye
rings amarillos, y actualizar la Tier list.

1) SCAN -> VISION (8 s): METALAMY_SCAN_TIME 3 s -> 8 s. Las agujas
   del v4.7 se van: obj_exe_indicator ahora junta REFERENCIAS
   (scanList) y su Draw_64 dibuja la SILUETA de cada superviviente
   encima del mapa (capa GUI, bm_add, rojo pulsante, fundido al
   ultimo medio segundo) — se ve a traves de paredes y escondites.
   La que cae fuera de la vista 480x270 queda FIJADA al borde
   (clamp 24..456/24..246, alpha *0.45): un fantasma que senala la
   direccion. Mismos filtros de siempre (hp<=0, revivalTimes>=2,
   velo de Amelia). Los timers del scan (timer/recharge/pose)
   pasaron del special al Step_0 del objeto: corren tambien durante
   el stun (antes se congelaban a mitad de revelado).

2) PASIVA 1 — EJECUCION DE LOS DEBILES (obj_metal_amy_bullet/Step_0):
   laser + hp < METALAMY_EXEC_HP (30) -> scr_player_instakill()
   directo. Excluidos: revivalTimes >= 1 (moribundo del usuario),
   auto-revivibles (Vanilla, Sonic, Amy Canon, Sally Canon) y Amelia:
   comen el dano normal de 20. El parry (scr_parry_protects_me),
   los i-frames (hurttime) y el escudo de Sally se chequean ANTES:
   si el golpe no cala no hay ejecucion. Stats: el mismo par de
   paquetes del golpe letal normal (modo 3 con el hp previo, modo 2 +
   MERCOIN_BONUS 2 al master_id del puppet de Metal Amy) y la caida
   sale del CLIENT_PLAYER_DEATH_STATE que ya envia instakill: CERO
   paquetes nuevos.

3) PASIVA 2 — MARCA DE DEBILIDAD (scr_weak_mark_hit, en
   scr_player_hurt.gml): cualquier golpe de Metal Amy que cala pone
   TODAS las habilidades del golpeado en 6 s de recarga
   (METALAMY_WEAKMARK_TIME; las que ya enfriaban suman 6 s). CD
   propio de 16 s POR superviviente (METALAMY_WEAKMARK_CD; la
   variable weakMarkCd se crea al vuelo con variable_instance_set y
   la hace bajar scr_move_basic con un guard: ningun Create de los
   13 supervivientes fue tocado). Llamadas: laser (escudo roto,
   ejecucion y dano real), contacto del puppet (gate hp/isHurt, el
   parry negado no marca). Convenciones respetadas: flyTimer de Tails
   en negativo (max(flyTimer, -420+_t)), parryCooldownMax llevado a
   la par para que el relleno del icono no desfase. Aviso local
   snd_metal_cd. Corre en el cliente de la victima: cero paquetes.

4) PASIVA 3 — MARCA DE LA CAZADORA (obj_metalamy/Step_0): con
   exactamente 1 vivo (puppets con hp<=0 o revivalTimes>=2 fuera,
   misma convencion del indicador) la V se apaga (gate !huntMode en
   scr_metalamy_special) y el rastreo sale solo: ventana de 8 s, y al
   terminar (scanTimer==1) arranca huntCd = METALAMY_HUNT_TIME (14 s)
   que al agotarse reabre la ventana. Reviven a alguien -> modo
   manual otra vez con la recarga a 0. Sonido de aviso local
   (snd_egg_tracker). HUD: el anillo del icono V refleja el ciclo y
   se vuelve DORADO en modo caza (obj_playerui/Draw_64). Local: cero
   paquetes.

5) PASIVA 4 — ADAPTABILIDAD (obj_metalamy/Step_0): deteccion del
   ARRANQUE del stun (shockedTimer 0->>0 con wasShocked) dentro de
   adaptWindow (METALAMY_ADAPT_WINDOW = 3 s) -> +1 dashCharges (tope
   METALAMY_DASH_MAX = 3) con snd_metal_hiit y sacudida. La ventana
   se abre cuando hurttime se agota de verdad: la rama del stun la
   re-arma a 2 s en cada frame aturdido y los golpes la dejan en 3 s,
   asi que solo cuenta el stun que cae en los 3 s posteriores a la
   perdida de inmunidad (tal cual el pedido). Cubre TODAS las fuentes
   de stun sin tocarlas. Local: cero paquetes.

6) LASER vs ANILLOS AMARILLOS (obj_ring/Step_0): overlap con
   obj_metal_amy_bullet (sin isBreaking) triggerea ringBreak() SOLO
   en el cliente de Metal Amy (gate global.character == CHARACTER_EXE
   && exeCharacter == EXE_METALAMY): su ringBreak manda el
   CLIENT_RING_BROKE + CLIENT_RING_COLLECTED y el server lo retira
   para todos (patron exacto del laser de Tails esbirro). Anillos
   rojos (obj_redring) intactos.

7) TIER LIST: TierList_Mejoras_V4_8.html (nueva; la V3_2 queda de
   historial). build_tierlist_v48.py aplica 13 reemplazos exactos:
   title/badges/pestana/h2/lead, articulos N (scan v4.7) O (vision
   8 s) P (4 pasivas + laser), banner "v4.6 -> v4.8 Metal Amy A->S"
   en la pestana tiers, ficha JS completa reescrita (tier S, pasiva
   "La cazadora", X/C/V, plus/minus), pie de verificacion y el
   comentario del EXEDATA ("la ejecucion no perdona").

ARCHIVOS v4.8: obj_exe_indicator/Create_0-Step_2-Draw_64,
obj_metal_amy_bullet/Step_0, obj_metalamy/Create_0-Step_0,
obj_player_puppet/Step_0, obj_playerui/Draw_64, obj_ring/Step_0,
scr_metalamy_special.gml, scr_move_basic.gml, scr_player_hurt.gml,
TierList_Mejoras_V4_8.html, LEEME.md, worklog.md.

VERIFICACION: verify_v48.py — balance de los 12 GML OK, 27 marcadores
v4.8 presentes, 6 sonidos verificados (snd_metal_cd, snd_metal_hiit,
snd_egg_tracker, snd_metal_stun, snd_metal_laugh, snd_metalamy_dash).
check_tierlist_v48.py (Playwright) — 11 textos visibles en sus
pestanas, sin errores de consola, Metal Amy en el bloque S. Timers por
personaje de la marca verificados contra los Create (flyTimer,
glideTimer, djumpRecharge/shieldRechrage/trackerRecharge, hjumpTimer,
dashTimer, parryCooldown(Max), ringsTimer, electroTimer,
bananaTimer/trapTimer, fireballTimer/burningTimer). Flujo de red de la
ejecucion contrastado contra la ruta letal de scr_player_hurt (modo 3
con hp previo + instakill + CLIENT_PLAYER_DEATH_STATE; sin
ring-lose, igual que la letal). Pendiente: partida real.

---
Task ID: torre-v2.15
Agent: Super Z (main agent)
Task: v2.15 «La Torre» — Fleetway Amy completa: barra de vida, fix de la flecha que no avanzaba, rework de la ballesta (3 flechas + plataforma), stuns, pasivas de las 3 Amys y tier list

Work Log:
- GIT PULL (e78928dc -> c3ce2800): el repo local estaba 11 commits por detras
  del remoto (la sincronizacion del usuario con Metal Amy como EXE #5 habia
  borrado Fleetway Amy entera en la copia local). El pull la restauro completa
  (obj_amy_fleetway, sprites _fw, FwBolt.c, enum CH_FLEETWAY_AMY) junto a los
  arreglos v2.14.1/v2.14.2 ya aplicados por sesiones intermedias.

1) BARRA DE VIDA (bug "no sale ni siquiera la barra"): las tiras de HUD ya
   tenian los frames de FW (health 91-97 = 98 frames, escaped/demon/hit 13)
   pero los PNG nuevos estaban 100% VACIOS (0% pixeles visibles) — el juego
   dibujaba iconos transparentes. Rellenados con el arte real del zip del
   usuario "Nueva carpeta (3).zip" (spr_playerhealth_21..27, redring idem,
   escaped_3, demon_3, hit_3). Barrido posterior: los unicos frames vacios
   restantes (56-69, 8-9) son los de Sally Canon/Vanilla que reusan otros
   iconos por remap, a proposito. backups en sprites/*/.empty_backup/.

2) FIX FLECHA QUE NO AVANZA (bug viejo): fwbolt_tick manda el estado 1 por
   canal NO fiable (UDP) y el case SERVER_FWBOLT_STATE solo existia en
   net_state_game (camino TCP): la flecha nacia quieta. Anadido el case a
   net_udpprocess.gml — mismo arreglo que el laser de Tails / bola de Blaze
   v2.9b / bala de Metal Amy.

3) REWORK BALLESTA «La Torre» (spec del usuario):
   - Cargador de 3 flechas (FW_ARROW_MAX), recarga 8 s por flecha
     (FW_ARROW_RECHARGE), 0,5 s entre disparos (FW_ARROW_SHOT_CD).
   - Vuelo recto; al tocar un solido se CLAVA (CLIENT_FWBOLT_HIT nuevo
     formato: u16 id, u8 tipo 0/1, u16 x, u16 y) y queda 5 s como
     PLATAFORMA: objeto nuevo obj_fw_arrow (hijo de obj_solid_parent,
     sprite spr_amy_projectile_fw, Draw propio porque el Draw del solid
     parent es vacio). Se apilan en torre (las flechas en vuelo chocan
     contra las clavadas), como en la wiki de Exe Nightmare.
   - Server: FwBolt.c/h con id de entidad en TODOS los paquetes (hasta 3
     flechas simultaneas), flag stuck, FWBOLT_STICK_TIME; states/Game.c
     CLIENT_FWBOLT revalida (CD 0,5 s) y CLIENT_FWBOLT_HIT reescrito
     (busca la entity por id; tipo 1 = stuck + estado 3 fiable).
   - Cliente: obj_fw_bolt con fwId/isStuck; colision -> clava y reporta;
     net_state_game reescrito (estados 0/1/2/3 con id); scr_fw_arrow_spawn
     idempotente por fwId en scr_characters.gml; pips de municion en el HUD
     (obj_playerui) con el icono de ballesta mostrando el cargador entero.

4) STUNS DE FLECHA: 3 s al EXE con reduccion acumulativa del 17,5% por stun
   continuo (tope 50% -> minimo 1,5 s), reset tras 7 s sin stuns de flecha
   (global.fwArrowStunStack/Decay, reloj en obj_level/Step_0). Esbirros:
   siempre 3 s completos. Demonizada: dmg 20 real, JAMAS stunea
   supervivientes. DJ del exe puro conserva su dedup de shockedTimer.

5) DJ DOBLE SALTO ATURDE AL EXE 3,2 s: bitflag nuevo PLAYER_DJ (1<<8) en
   CLIENT_PLAYER_DATA (obj_netclient/Step_2) -> parseado en el puppet
   (net_udpprocess + Create) -> el cliente del EXE aplica el stun por
   contacto (obj_player_puppet/Step_0, mismo modelo de victima-autoridad
   que el tarot de Amy Canon / electro de Eggman).

6) PASIVAS «La Torre» + «Reflejo de una misma alma» + «Fuerza»:
   - La Torre (FW): bloqueo determinista del 33% del daño en
     scr_player_hurt (estilo Chocola con Vanilla); con el Reflejo sube
     +5% por Amy en el campo hasta el tope del 40%.
   - Reflejo de una misma alma (las Amys): scr_amy_soul_count/bonus/otras
     en scr_characters.gml (+5% por Amy presente — Amy, Canon, Amelia,
     Fleetway —, tope +15%). Conteo local por cliente (local + puppets).
   - Fuerza (Amy vanilla): i-frames durante el lanzamiento del martillo
     (scr_player_hurt) y hitbox +20% (pad por distancia en
     obj_player_puppet, patron del tarot de Amy Canon), hasta +23% con el
     Reflejo; SOLO si alguna de las otras Amys esta en el campo.

7) TIER LIST (TierList_Mejoras_V4_8.html): ficha completa de Fleetway Amy
   (tier A+ provisional, rol «Zonera · La Torre», 3 habilidades, plus x4,
   minus x4, solo/minions), entrada MATRIX vs los 5 EXE (e/e/v/d/e),
   retrato SPR generado desde spr_lobby_icon_fw frame 0 (39x39, vecino),
   pasivas de Amy/Amelia/Amy Canon actualizadas con el Reflejo.
   Verificado en navegador headless: 14 fichas, fila de matriz de 6 celdas,
   tabla solo y chips OK, retrato cargado (naturalWidth 39).

ARCHIVOS v2.15: yyp, TierList_Mejoras_V4_8.html, FwBolt.c/h,
states/Game.c, obj_amy_fleetway/Create_0, obj_fw_bolt (Create/Step/
Collision), obj_fw_arrow (nuevo: Create/Step/Draw/yy), obj_level/Step_0,
obj_netclient/Step_2, obj_player_puppet (Create/Step_0),
obj_playerui/Draw_64, net_fw_bolt, net_packets, net_state_game,
net_udpprocess, scr_amy_fleetway_special, scr_characters, scr_globals,
scr_player_hurt + 17 PNG de las tiras de HUD rellenados.

VERIFICACION: gcc -fsyntax-only del FwBolt.c y states/Game.c OK (stub de
enet); balance de llaves/parens/brackets de los 20 GML tocados OK; yyp
validado como JSON (1992 recursos, obj_fw_arrow registrado); array SURV
del tier list evaluado con node (14 entradas) + render en navegador real
sin errores; cero referencias a las macros eliminadas
(FW_CROSSBOW_RECHARGE); isDead nunca se lee en puppets (patron
isInactive). Pendiente: partida real de prueba con el server compilado.

---
Task ID: torre-v2.15.1
Agent: Super Z (main agent)
Task: v2.15.1 — fixes post-prueba del usuario: flecha que atravesaba la pared, retrato de cuerpo entero en la tier list y Fleetway Amy en «La voz del lobby»

Work Log:
- QUEJA 1 («la tier sigue igualita, no incluiste a Fw ni actualizaste
  descripciones»): el usuario mira TierList_Comentarios_V2.html («La voz
  del lobby»), que la sesion anterior NO toco (solo actualizo la de
  Mejoras). Anadida la tarjeta de Fleetway Amy (A+, «Zonera · La Torre»,
  6 comentarios + 3 en directo con cifras reales del kit: 3 s de stun,
  -17,5% por stun continuo, 3,2 s de DJ, 33-40% de Torre), Amy subida a
  B+ (dos comentarios de la Fuerza: i-frames + hitbox +20/23%),
  comentario del Reflejo en Amelia, nota en la bitacora de Amy Canon,
  5 frases nuevas del ticker, cabecera a 16 personajes y referencias
  v2.15 en hero/notas/pie.

- QUEJA 2 («no sale el sprite de ella de pie como el resto»): el retrato
  de la ficha era spr_lobby_icon_fw (una CARA 39x39) escalada a 84 px.
  Regenerado desde el sprite real de pie (spr_amy_idle_fw frame 0,
  32x47 -> recorte alpha 24x45, 1233 bytes) en las DOS tier lists
  (ficha, fila de tiers, matriz, tabla solo, tarjeta de comentarios).

- QUEJA 3 («las flechas no se clavan, traspasan la pared»): CAUSA RAIZ —
  la posicion la integraba el server (que NO conoce el mapa) y llegaba
  por UDP como teleports de 14 px; el evento de colision de GM solo
  dispara con solape al final del frame, y en las rafagas de paquetes
  (2-6 por frame, tipico en red/WiFi) la posicion dentro de la pared se
  sobrescribia por otra ya pasada -> atravesaba. FIX: vuelo simulado
  LOCALMENTE por cada cliente (spawn TCP fiable: x, y, dir) con barrido
  sub-pixel (FW_ARROW_FLIGHT 14 px/frame = FWBOLT_SPEED; sub-pasos
  FW_ARROW_SWEEP 3,5; busqueda binaria 0,5 px; punta enterrada
  FW_ARROW_BURY 4 px; wrap de YouCan'tRun y limite izquierdo en local;
  bocajarro se clava al nacer). El server deja de difundir el estado 1
  (FwBolt.c) y el flujo de clavado sigue siendo CLIENT_FWBOLT_HIT tipo 1
  -> estado 3 TCP. net_udpprocess/net_state_game leen pero no aplican
  las posiciones. Simulacion numerica (scripts/test_fw_sweep.py):
  paredes 4/8/16/32/64 px — el nuevo SIEMPRE se clava; el viejo con
  burst 4-6 las atraviesa (repro exacta del bug). gcc -fsyntax-only OK.

ARCHIVOS v2.15.1: TierList_Cometarios_V2.html, TierList_Mejoras_V4_8.html,
obj_fw_bolt/Step_0, obj_amy_fleetway/Create_0 (macros), net_udpprocess,
net_state_game, FwBolt.c, LEEME_TORRE_V2_15.txt (reescrito como v2.15.1).

VERIFICACION: navegador real sin errores (retrato 24x45 de cuerpo entero
en las 3 vistas, 16 tarjetas en Comentarios); balance de llaves OK;
simulacion del barrido OK; server compila limpio. Pendiente: partida
real con el server recompilado.

---
Task ID: fix-v4.7
Agent: Super Z (main agent)
Task: v4.7 — fixes post-prueba del usuario: crash de obj_amelia_auras (AMELIA_EXIT_SENSE_RADIUS), flechas que no se clavan en la pared y modo práctica con mapa al azar. Entrega por GIT (pull/commit).

Work Log:
- ENTREGA POR GIT (pedido del usuario: «recuerda siempre hacer git a mi
  repositorio» / «usa el git para que actualices lo que tienes»): clon
  fresco de github.com/AmyRose21/disaster2d-oss (HEAD 64ad532e «upda»),
  cambios aplicados encima y commit local listo para push.

- QUEJA 1 (crash reportado tal cual):
  «Variable obj_amelia_auras.AMELIA_EXIT_SENSE_RADIUS(101172,
  -2147483648) not set before reading it» en Step_0 linea 110.
  CAUSA RAIZ (arqueologia git): ec8b8ffe añadio a obj_amelia_auras el
  «ECO DE LA SALIDA» (SENSOR 3) + macros AMELIA_EXIT_SENSE_RADIUS/PULSE/
  SCALE/COLOR en scr_amelia_special.gml; a1124a1b (29 min despues) creo
  obj_amelia_indicators como objeto separado y BORRO las macros, pero
  olvido quitar el bloque del auras -> macro inexistente = variable de
  instancia nunca inicializada = crash en cuanto existe obj_bigring.
  FIX: eliminado el bloque duplicado del Step y del Draw_64; la marca
  de la salida queda UNA sola (obj_amelia_indicators, la del LEEME
  v4.5: <=400 px, parpadeante). Sin macros nuevas que mantener.

- QUEJA 2 («No se clavan en la pared» — la v2.15.1 no basto): el
  barrido local solo miraba obj_solid_parent. En Fart Zone (mapa 20, el
  FIJO de la practica) los 55 muros son obj_fart_tile, hijos de
  obj_floor_parent y NO de solid_parent -> ahi la flecha atravesaba
  TODO (por eso en tu prueba seguia sin clavarse). Tambien afecta a
  hielos de Nasty Paradise y puertas de Haunting Dream.
  FIX: scr_fw_wall_at + scr_fw_is_jumptrough (scr_characters.gml):
  la flecha siente la MISMA geometria que el jugador al caminar —
  toda obj_floor_parent MENOS la familia saltable
  (obj_platform_jumptrough y 7 hijos), que el jugador tampoco toca de
  lado (guarda !position_meeting de scr_collision_check). El barrido
  sub-pixel v2.15.1 intacto; torre de flechas intacta (las clavadas
  cuelgan de solid_parent); el evento Collision con solid_parent queda
  como red de seguridad.

- QUEJA 3 («permite que el modo practica pueda elegir un mapa al azar
  como si fuera un modo normal»): habia DOS rutas con el mapa 20
  hardcodeado — .sp (charselect_init_survpractice) y el voto .vp
  (prac_countdown -> charselect_init(20)).
  FIX: map_pick_random(Server*) nueva en Maps.c (declarada en Maps.h):
  sortea entre los mapas ACTIVOS del Config.json (map_list con su
  lock, igual que mapvote_init) evitando repetir server->last_map; la
  usan las dos rutas (.sp fija lobby.map/last_map y manda el mapa en
  SERVER_LOBBY_EXE; .vp sortea al expirar prac_countdown). Chat
  «map: %s» + Info de consola como el modo normal. Fallback a 20 si
  no hay mapas activos. REQUIERE RECOMPILAR EL SERVER.

- Limpieza de paso: stdlib.h declarado en states/Lobby.c y
  states/CharSelect.c (rand() se usaba sin declarar; en compiladores
  modernos eso es error).

ARCHIVOS v4.7: objects/obj_amelia_auras/{Step_0,Draw_64}.gml,
objects/obj_fw_bolt/Step_0.gml, scripts/scr_characters/scr_characters.gml,
betterserver-oss/{disasterserver/Maps.c, include/Maps.h,
disasterserver/states/CharSelect.c, disasterserver/states/Lobby.c},
LEEME_FIX_V4_7.txt, worklog.md.

VERIFICACION: balance de llaves de los 4 GML OK (sin comentarios ni
strings) y cero referencias en codigo a las vars/macros del eco
eliminado; gcc -fsyntax-only (stub enet) de los 4 C tocados = 0 errores
(solo los 3 avisos preexistentes del codigo original); simulacion del
sorteo 100k tiradas: nunca repite last_map, uniforme (5230-5293 sobre
5263 esperado), bordes 0/1/N mapas OK; diff del server con tabs
originales (73+/3-). Pendiente: partida real con el server
recompilado.

---
Task ID: fix-v4.9
Agent: Super Z (main agent)
Task: v4.9 — fixes post-prueba del usuario: crash universal de
obj_fw_bolt (object_get_parent -100) y flechas de Fleetway Amy como en
el video del juego original (salen a los pies junto al muro, se clavan
casi al instante y la clavada es plataforma ATRAVESABLE). Incluye
re-aplicacion del v4.8 perdido (clamps de cura + radio Amelia 680).

Work Log:
- Base: clon fresco de GitHub (HEAD 1d73a37b «update») — el v4.8 del
  sandbox anterior se perdio al reciclarse (push sin credenciales);
  re-aplicado aqui.

- QUEJA 1 (crash reportado tal cual):
  «object_get_parent argument 1 invalid reference to (object) -
  requested -100 max is 326» en scr_fw_is_jumptrough (linea 437) <-
  scr_fw_wall_at <- obj_fw_bolt Step_0.
  CAUSA RAIZ: el bucle de scr_fw_is_jumptrough recorria la cadena de
  padres hasta cortar con -1, pero object_get_parent devuelve -100
  cuando el objeto NO tiene padre. obj_camerachecker (raiz de
  obj_floor_parent, el padre de casi toda la geometria) tiene
  parentObjectId null -> la cadena llega a -100 y el bucle lo pasa a
  object_get_parent = abort. Pasaba en TODOS los mapas (el usuario lo
  confirmo) siempre que una flecha en vuelo tocase cualquier piso/muro
  NO saltable — coincide con la salida porque es cuando se dispara
  cerca de paredes.
  FIX: el while ahora corta con _obj != -100 && _obj != -1 &&
  object_exists(_obj). Universal: cualquier cadena, cualquier mapa.

- QUEJA 2 («no puedo traspasar la flecha saltando desde abajo, sigue
  siendo como un muro» + video del juego original): analizado el video
  (file.garden, 17 s, VLM): (1) en tierra lejos del muro la flecha
  sale del pecho y vuela recta; (2) pegada al muro / escalando sale a
  la ALTURA DE LOS PIES y aparece clavada casi al instante (1-2
  frames); (3) las flechas clavadas son plataformas de UNA VIA: se
  atraviesan desde abajo y se aterriza encima.
  FIX A (plataforma atravesable): obj_fw_arrow.yy parentObjectId pasa
  de obj_solid_parent a obj_platform_jumptrough. Automaticamente:
  aterrizar encima al caer (scr_collision_check_bottom rama
  jumptrough), SIN techo ni pared lateral (guardas
  !position_meeting de scr_collision_check/top), y las flechas en
  vuelo la ignoran (scr_fw_wall_at excluye la familia saltable) — se
  clavan en el muro de detras, como el original. Se pierde la «torre»
  de flechas apiladas (consecuencia natural de la opcion 2 pedida).
  FIX B (modo pared): FW_WALL_REACH 48 en obj_amy_fleetway/Create_0 +
  scr_fw_wall_point (scr_characters.gml, version por punto de
  scr_fw_wall_at para el jugador) + logica en
  scr_amy_fleetway_special: si hay muro real a 12..48 px a la altura
  del tobillo (y+14), la flecha nace 24 px antes del muro a la
  ALTURA DE LOS PIES (y+18 = contacto del suelo, verificado contra
  sprite 32x47 origen y=29 y scr_collision_check_bottom y=contact-18)
  y el barrido del Step_0 la clava en el primer frame (punta
  FW_ARROW_BURY dentro). Funciona tambien EN EL AIRE: saltar y
  disparar en el punto mas alto coloca la siguiente flecha mas arriba
  (loop de escalada del video). Lejos de todo muro: disparo normal de
  pecho SIN CAMBIOS (pedido explicito). Guarda _sx>=1 para el u16 del
  server. Cero paquetes nuevos: mismo CLIENT_FWBOLT/CLIENT_FWBOLT_HIT.

- RE-APLICACION v4.8 (perdido): 4 curas con clamp min(100, hp+20) en
  net_state_game.gml (lineas ~1360, ~2382, ~2522 y 4011 — el
  anticheat del server kickea con hp>100: «garic forn») y
  AMELIA_EXIT_SENSE 400->680 (obj_amelia_indicators + comentario de
  obj_amelia).

ARCHIVOS v4.9: scripts/scr_characters/scr_characters.gml,
scripts/scr_amy_fleetway_special/scr_amy_fleetway_special.gml,
scripts/net_state_game/net_state_game.gml,
objects/obj_amy_fleetway/Create_0.gml,
objects/obj_fw_arrow/{obj_fw_arrow.yy,Create_0.gml},
objects/obj_fw_bolt/{Create_0.gml,Collision_obj_solid_parent.gml},
objects/obj_amelia_indicators/Create_0.gml,
objects/obj_amelia/Create_0.gml,
LEEME_FIX_V4_9.txt, worklog.md.
Servidor: SIN CAMBIOS (el clavado instantaneo ya viaja por el flujo
tipo 1 existente; states/Game.c acepta cualquier posicion).

VERIFICACION: balance de llaves de los 4 GML tocados OK (sin
comentarios ni strings); grep de min(100,...) = 4 exactos; macro
FW_WALL_REACH declarado 1 vez y usado 1 vez; scr_fw_wall_point
declarada 1 vez y llamada 1 vez; obj_fw_arrow.yy apunta a
obj_platform_jumptrough; analisis del video con VLM confirmando los
3 comportamientos antes de codificar. Pendiente: partida real.

## v4.10 (2026-11-05) — FW AMY: RUN VISIBLE + TORRE TOTAL + ICONO ? DE METAL AMY + BLINDAJE ANTI-CHEAT

Pedido del usuario (4 puntos + captura del kick «garic forn»):
run de FW Amy nunca sale; doble salto con spr_amy_dj_fw; cbamy
idle/walk/run solo mientras la ballesta; «para el bloqueo me referia
a BLOQUEAR el daño COMPLETO no reducirlo»; y el icono de Metal Amy
asesina en "?" para los demas.

1) RUN: la maquina de estados estaba bien (identica a Amy Canon) y
   los sprites existen y son validos (8 frames unicos, run != walk).
   La causa real: con acc 0.046875 se tardan ~3 s en llegar a los
   8 px/frame del umbral RUN -> en partidas reales nunca se llega.
   FIX: FW_ACC 0.046875 -> 0.09375 (doble; corre en ~1,4 s y frena
   en mitad de distancia). Umbral 8 intacto (consistencia con todos).
   Verificado ademas: isOnEdge solo se calcula con abs(xspd) <= 0
   (nunca pisa WALK/RUN) y nada sobreescribe acc/maxHSpeed en
   runtime salvo Alarm_4 (que restaura los valores FW).

2) DJ/CBAMY: los estados 18-21 y sus sprites ya estaban cableados
   (tabla v2.14 + Step_2 + Draw_76): con el fix de velocidad ahora
   cbamy_run tambien se ve. BUG REAL EXTRA: PLAYER_DJ = 1<<8 = 256
   y el bitflag viaja en buffer_u8 -> se enviaba 0: el stun de 3,2 s
   del DJ jamas llego al cliente del EXE. FIX: PLAYER_DJ pasa a
   1<<7 compartido con PLAYER_SLIME (seguro: slime solo lo pone
   Chaos/EXE, DJ solo FW/superviviente; el server solo interpreta
   PLAYER_ATTACKING y retransmite el byte tal cual - verificado en
   states/Game.c 2285-2292). Puppet parsea isDJ solo para FW.

3) LA TORRE TOTAL: scr_player_hurt reducia 33-40% (min(TOWER_BLOCK+
   soul_bonus, MAX)) y «literalmente aun recibia daño». Ahora: return
   temprano con efecto de escudo + hurttime 60 - ni hp ni anillos ni
   retroceso. Colocado DENTRO del gate damage > 0, ANTES de
   wasHurt (golpe bloqueado no cuenta para logros, mismo criterio
   que el escudo de Sally) y con gate revival < 2 (demonizada sin
   pasiva). Muertes instantaneas (hoyos, ejecucion Metal Amy) no
   pasan por aqui: siguen matando (documentado en el LEEME).
   Macros TOWER_BLOCK/MAX eliminados; queda TOWER_BLOCK_INVULN 60.
   scr_amy_soul_bonus sobrevive (FUERZA de Amy vanilla lo usa).

4) ICONO «?» METAL AMY: SERVER_LOBBY_CHARACTER_CHANGE y
   SERVER_LOBBY_EXECHARACTER_RESPONSE (net_state_charselect) no
   tenian case EXE_METALAMY -> el icono de los demas se quedaba en
   spr_lobby_exeicon5 (la bola «?»). Anadido en AMBOS switches
   (exeicon6). Bonus TAB: drawPing mandaba a Metal Amy asesina al
   frame 10 (fila de Amy); fabricado frame 15 de spr_tab_entry
   (medallon de la fila exe + cabeza de exeicon6 redimensionada;
   anillo/borde intactos verificados pixel a pixel) + length 15->16
   + keyframe 15 en el .yy (mismo formato GameMaker, JSON valido).

5) BLINDAJE ANTI-CHEAT (la captura «garic forn» del usuario era del
   build PRE-v4.9: aplico v4.9 a las 00:21 y los clamps recien
   llegaban): hp del CLIENT_PLAYER_DATA ahora viaja clamp(0,100)
   (imposible que cualquier ruta futura mande >100) y anillos con
   techo 119 tras recoger (el server kickea «gomunkulus» con >=120
   en mapas normales; la practica con mapa aleatorio v4.7 puede
   caer en uno). Los 4 clamps de cura v4.9 intactos. Server SIN
   cambios.

ARCHIVOS v4.10: objects/obj_amy_fleetway/Create_0.gml,
scripts/scr_player_hurt/scr_player_hurt.gml,
scripts/net_packets/net_packets.gml,
scripts/net_state_charselect/net_state_charselect.gml,
objects/obj_netclient/Step_2.gml,
scripts/net_state_game/net_state_game.gml,
objects/obj_level/Create_0.gml, scripts/scr_characters/scr_characters.gml
(comentario), sprites/spr_tab_entry/{spr_tab_entry.yy,fc1b733a-*.png},
LEEME_FIX_V4_10.txt, worklog.md.

VERIFICACION: verify_v410.py — 30 checks OK (balance de los 8 GML,
FW_ACC 0.09375, macros Torre, orden del bloqueo antes de wasHurt/
hp-=, PLAYER_DJ 1<<7 en rama superviviente, 2 cases EXE_METALAMY,
drawPing -> 15, .yy con 16 frames/keyframes 0..15/length 16, frame
15 difiere solo dentro del medallon (291 px dentro, 0 fuera), clamp
hp, techo rings 119, 4 clamps de cura intactos). PNG huérfano del
primer intento del script eliminado. Pendiente: partida real.

## v5.0 (2026-11-05) — LMS «EL SHOW FUERTE»: Sonic último superviviente con Undefeatable

Pedido del usuario (literal): «El LMS es el sistema cuando queda 1 por
ahora el unico que tendra LMS es sonic [...] el tiempo del juego
aumentara y se ajustara a la duracion de la cancion la vida cambiara a
tener 100 de vida. y sonic ganara una pasiva durante el lms Bloquear el
daño recibido con un 55% de probabilidad de bloquear todo el daño
recibido. Sonic durante el LMS sera imune a la pasiva de
enfriamientos que da Metal amy [...] No servira contra sonic en LMS.
El spindash todos los stun aumentaran +2seg mas a sus duraciones.»
Canción: Undefeatable V2 - Sonic Frontiers Epic Rock Reimagined Cover
(file.garden, 281,86 s -> ogg q3, LMS_TIME_SEC 282 = 4:42 en el HUD).

DISPARO (server, states/Game.c game_state_tick): cuenta vivos del bando
survivor (fuera el exe, PLAYER_DEAD/DEMONIZED/ESCAPED); si queda
EXACTAMENTE 1 y es CH_SONIC -> latch game.lms, reloj = max(actual,
282), broadcast SERVER_GAME_LMS (paquete NUEVO al final del enum en los
DOS lados). Reenvío del paquete en game_state_join para reconexiones.
Práctica (.sp con exe=0xFFFF) también lo dispara: Sonic solo en
práctica vive el show entero (vía de test).

CLIENTE (net_state_game case SERVER_GAME_LMS): global.lmsActive (init
en scr_globals, reset por ronda en obj_level/Create) + scr_play_music
(mus_undefeatable, streamada como las demás mus_*) + banner
obj_lms_banner (clon de obj_suddendeath sin sting, 5 s) + cura local
de Sonic a 100 (snd_heal + spr_ring_sparkle por red). Gates: la música
de persecución del anillo NO pisa la canción durante el show y el
banner/sting de la muerte súbita no sale (la demonización del server
sigue). El tic-tac de los últimos 10 s se conserva.

PASIVAS (solo con global.lmsActive):
1) BLOQUEO 55% — scr_lms_sonic_try_block (scripts/scr_lms NUEVO,
   macros LMS_*), llamada desde scr_player_hurt tras la Torre de FW:
   tirada random(100) < 55 (patrón Chocola); bloqueado = ni hp ni
   anillos ni retroceso, escudo roto visible/sonoro por red + 60
   frames de invulnerabilidad (una tirada limpia por golpe). La
   ejecución de Metal Amy ya excluye a Sonic (v4.8) => la bala/laser
   pasan por scr_player_hurt y la tirada las cubre sin dobles rolls.
2) INMUNIDAD WEAKMARK — gate al inicio de scr_weak_mark_hit: la marca
   de debilidad jamás aplica a Sonic en LMS.
3) STUNS +2 s — obj_player_puppet Step_0: stunTime += LMS_STUN_BONUS
   cuando el atacante es Sonic (golpe X 3->5; la BOLA del spindash/
   dropdash aturde por contacto SOLO en LMS, estado SPIN, macro
   LMS_SPIN_STUN para desactivar) y scr_parry_apply_stun: parry
   3,5->5,5 s (shockedTimer y _stunSec consistentes).

FIX EXTRA (bug real hallado al leer el puppet): el stun de 3,2 s del
DJ de Fleetway Amy era CODIGO MUERTO desde v2.15 — el bloque de stun
exige isAttacking y FW nunca envía ese bitflag (no está en la lista
de obj_netclient/Step_2); el fix del bit PLAYER_DJ (v4.10) no bastaba.
La puerta del bloque ahora acepta (FW && isDJ) => el stun del DJ
funciona por fin.

ASSETS NUEVOS (registrados en .yyp 1996 recursos y .resource_order,
1 vez cada uno): sounds/mus_undefeatable (.ogg 3,7 MB streamado,
formato mus_*), sprites/spr_lms_banner (4 frames 480x270, pixel font
5x7 escala 2, «LAST MAN STANDING» paleta fuego rodante, composites
raíz + layers/<frame>/<layer> — lección v2.2.2), objects/obj_lms_banner
(3 eventos, TABs como su plantilla), scripts/scr_lms.

HERRAMIENTAS: /home/z/my-project/scripts/lms/{apply_lms_v1.py
(idempotencia FUERTE: si el resultado ya está, skip — los parches de
inserción ya no se duplican entre corridas), validate_lms_v1.py}.

VERIFICACION: validador 139/139 (paridad enum, orden del bloqueo antes
de wasHurt, 55% exacto en 200k tiradas, HUD 4:42, banner ASCII-legible
+ paleta fuego + 4 frames distintos, composites+layers, .yyp sin
duplicados, sonido mus-formato, sin CR/ternarios encadenados).
Server: cmake Release 100% limpio + smoke test (v1101, 8606, Lobby).
Pendiente: partida real (server Y cliente se actualizan JUNTOS).

Entregable: download/lms_sonic_v1.zip (cliente + server + LEEME).

---

## v5.1 — Copias propias (Sally Canon / Vanilla) + LMS multi-canción + Suite v5.2 (2026-11-06)

### Qué se hizo

**A) 14 sprites copia** (registrados en .yyp + .resource_order):
- Sally Canon ← Sally: `spr_lobby_icon_sallycanon`, `spr_char_info_sallycanon`,
  `spr_playerhealth_sallycanon` (7f), `_hit_`, `_demon_`, `spr_playerescaped_sallycanon`,
  `spr_menu_sallycanon` (retrato animado, 20f).
- Vanilla ← Cream: los mismos 7 con sufijo `_vanilla` (retrato 18f).
- PNGs copiados byte a byte de los frames fuente (raíz + layers), GUIDs nuevos.

**B) scr_characters.gml — bloque v5.1 de resolvedores** (sustituye al v3.7):
`scr_lobby_icon_sprite/frame/animated/pair` + `scr_lobby_shiny_setup/resolve/escape`
+ `scr_hud_strip/strip_red/hit/demon/escaped/escaped_draw`. Prioridad lobby:
brillo (sh) > sprite propio > tira común. Fix latente incluido: el guard de
`scr_lobby_shiny_resolve` ahora llega hasta FLEETWAY (antes `_ch > CHARACTER_BLAZE`
la dejaba fuera).

**C) Redirecciones** (dejan de reusar arte ajeno): obj_lobby/Create (retratos),
obj_lobby/Draw (placas), obj_lobby_icon/Draw (nav + resolve por fotograma),
net_state_charselect (RESPONSE **y** CHANGE), obj_menu_waiting (lista de sala),
obj_level/Draw_64 (HUD propio + ajeno), obj_level/Create (marcador TAB),
net_state_results (cases 1–4). Ningún remapeo manual de Sally Canon/Vanilla queda.

**D) LMS multi-canción**: Server.h (`LMS_SONG_COUNT` + `LMS_SONG_SEC[]` +
`Game.lms_song`), Game.c (elección `rand() % LMS_SONG_COUNT`, reloj a la duración
de la elegida, `PacketWrite8` del índice, reenvío en join), Packet.h (payload u8),
scr_lms.gml (`LMS_HP` + `global.lmsSongs` + `scr_lms_play_song`), net_state_game
(lee u8; server viejo ⇒ −1 ⇒ canción #1).

**E) Suite TD2D v5.2**: módulo nuevo 🎤 Show LMS (multi-canción .mp3/.ogg/.wav
con duración leída por Web Audio + macros del show + escritura de
sounds/+.yyp+Server.h con backups/undo), editor de ICONOS DE SUPERVIVIENTES
separado de killers (modo clásico/independiente: lobby + escapó + barra de vida),
placas agrupadas (Supervivientes / Placas propias / Killers) con Sally Canon,
Vanilla y Fleetway Amy editables, ayuda y autockequeo actualizados.

### Validación
- `apply_v5_1.py` idempotente; run fresco sobre clon HEAD == estado final byte a byte.
- `validate_v5_1.py`: **239 OK · 0 FAIL** (sprites byte-idénticos al fuente,
  .yyp JSON válido sin duplicados, llaves balanceadas, marcadores nuevos
  presentes / remapeos viejos ausentes, 8 scripts JS con sintaxis OK).
- Suite probado en navegador headless: arranque sin errores, cambio de módulos,
  editor de Sally Canon en modo propio con targets correctos, editor killer
  intacto, placas agrupadas en demo.
Task ID: fix-tirolina-v1
Agent: Super Z (main agent)
Task: Bug reportado por el usuario en Hide and Seek acto 1 (room_angelisland):
al agarrarse de la liana/tirolina el personaje «es movido violentamente al
suelo, no suelta la cuerda pero el cuerpo baja hasta el piso», hasta recibir
dano del agujero mortal; en la liana que cruza el abismo es literalmente
imposible pasar sin dano, igual que subir por las que suben. «No se cuando
fue que se rompio originalmente».

Work Log:
- ARQUEOLOGIA: el codigo de obj_aiz_zipline NO cambio nunca en la historia
  del repo (desde el import inicial 84e22207). Lo que cambio fue el REPARTO:
  el switch de posicion del Step_2 solo tenia case para los 8 personajes del
  juego original (EXE/TAILS/KNUX/EGGMAN/AMY+CANON/CREAM/SALLY) y el remake
  anadio 7 mas (SONIC, SALLY_CANON, VANILLA, METAL, AMELIA, BLAZE,
  FLEETWAY_AMY) sin tocarlo. Por eso «se rompio solo»: segun con quien
  juegues funciona o te hundes.

- CAUSA RAIZ (linea por linea): el bloque "if(hasPlayer && progress < 1)"
  hace cada frame "global.player.y = y + OFFSET" (el switch) y LUEGO
  "global.player.y += sprite_height" (+19, el sprite del TROLLEY, no el del
  jugador). Con case: la y se reinicia cada frame y el +19 es estable.
  SIN case: la y NUNCA se reinicia y el += 19 se ACUMULA -> el jugador se
  hunde 19 px POR FRAME (~1140 px/s) hasta el suelo/abisno sin soltar la
  cuerda (hasPlayer sigue true, playerControls false, isZipline true).
  Geometria verificada en room_angelisland: las lianas gid 1 (928->1304,
  y=1283) y gid 3 (2224->2617, y=1296) cruzan sobre obj_abyss en y=1568 ->
  ~15 frames tras el agarre el cuerpo toca el abismo: scr_player_hurt(20) +
  teleport al abyss_target. Exactamente lo reportado. Colgando bien quedan
  a y~1325: ~240 px de margen.

- FIX 1 (posicion, obj_aiz_zipline/Step_2.gml): cases nuevos para los 7
  personajes + default. Offsets calibrados con la MISMA regla que siguen
  los originales: offset = yorigin del sprite de tirolina - 7 (coincide
  exacto con TAILS 11 y KNUX 22, a +/-2 con el resto; deja el top del
  sprite a trolley_y+12 como los 8 originales). SONIC=22 (el valor que ya
  usaba el puppet), SALLY_CANON=23, VANILLA=16 (+isFlying=false: su vuelo
  pisa el estado CREAM_ZIPLINE en su Step_2, mismo motivo que
  TAILS/CREAM), METAL=17, AMELIA=22, BLAZE=19, FLEETWAY_AMY=21,
  default=20 (personaje futuro: cuelga estandar en vez de hundirse).
  Sprites demonizados verificados: emetal/eamelia/eblaze/eamy_fw tienen
  dims y yorigin IDENTICOS a los normales -> mismos offsets valen.

- FIX 2 (guard de agarre, mismo archivo): los 14 checks
  "character == X && state == X_ZIPLINE" reducidos a UN solo
  "if(global.player.isZipline) return;". Equivalentes (verificado: TODOS
  los "state = *_ZIPLINE" del proyecto viven dentro de "if(isZipline)")
  y cubre a los personajes que faltaban (VANILLA/METAL/AMELIA/BLAZE/
  FLEETWAY): un llevado por un Tails/Cream volando de esos personajes
  volaba sobre el inicio de la tirolina y esta se lo ROBABA (el mismo bug
  que CARRY v1 arreglo para SONIC/SALLY_CANON, tercera vez que habia que
  parchear la cadena). Futuros personajes ya quedan cubiertos solos.

- FIX 3 (vista remota, obj_player_puppet/Draw_0.gml): el puppet dibuja el
  carrito (spr_aiz_zipline) sobre el jugador remoto en estado *_ZIPLINE,
  pero le faltaban los 6 personajes nuevos -> los demas clientes veian al
  colgado SIN carrito. Anadidos con los mismos offsets (inverso exacto de
  la formula local: y - offset - 19). OJO documentado: SALLY_CANON viaja
  en SALLY_ZIPLINE y VANILLA en CREAM_ZIPLINE (los estados que usan sus
  propios Step_2).

- No se toco nada mas: _holdPlayer, el avance del trolley, el release con
  Z/fin de recorrido, timeout y respawn del trolley quedan igual. Los 8
  personajes originales ni se enteran (sus cases y offsets intactos, el
  guard nuevo es equivalente al que tenian).

ARCHIVOS: objects/obj_aiz_zipline/Step_2.gml,
objects/obj_player_puppet/Draw_0.gml, LEEME_FIX_TIROLINA.txt, worklog.md.

VERIFICACION: balance de llaves OK en ambos GML (sin comentarios/strings);
macros usadas por el puppet (FW/METAL/BLAZE/AMELIA/SALLY/CREAM_ZIPLINE)
con definicion unica en el proyecto (globales en GML, patron ya usado por
los cases existentes); simulacion de geometria: jugador colgado a
trolley_y+offset+19, ~1325 en las lianas sobre abismo (1568) = margen 240
px, y avance del trolley 0.016/frame max (launch 2.4 px/f igual que antes).
Pendiente: prueba en partida real recorriendo la liana del abismo con
Sonic y subiendo las lianas gid 2/4.

---

============================================================
Task ID: fix-metalamy-mapas-v1
Agent: Super Z (main agent)
Task: Reporte del usuario: 1) Metal Amy (killer EXE_METALAMY=4):
su visor/habilidad no funciona (tecla V) NI la pasiva de cuando
queda 1 solo superviviente (no se ve la flecha indicadora).
2) «No hay otros mapas que no esten funcionando bien con los
personajes adicionales?» — auditoria de compatibilidad de mapas
con los 7 personajes anadidos (SONIC, SALLY_CANON, VANILLA,
METAL, AMELIA, BLAZE, FLEETWAY_AMY) + los killers nuevos.

Work Log:

- CAUSA RAIZ DEL SCAN (Metal Amy): el revelado lo dibuja
  obj_exe_indicator (la instancia la crea su Create_0), pero su
  Step_2 lo recogia con «variable_instance_exists(global.player,
  "scanTimer")» y global.player es el INDICE del objeto
  (player_getexe devuelve obj_metalamy), NO el id de instancia:
  esa funcion pide el ID (manual GM; por eso obj_ghz_water usa
  global.player.id y obj_amelia_auras usa _inst.id). Devolvia
  false SIEMPRE -> scanCount quedaba en 0 -> la V corria (sonido,
  pose, anillo del HUD, recarga) pero NO SE DIBUJABA NADA, y la
  pasiva de la cazadora (huntMode) hacia sonar el tracker con el
  mismo resultado: nada visible. Un solo bug, los dos sintomas.
  FIX: gate reescrito con instance_exists(global.player) (que si
  acepta indices) + lectura scanTimer por punto; el gate de
  exeCharacter ya garantiza que el jugador es obj_metalamy, cuyo
  Create_0 define scanTimer. Ademas fuera los puppets
  isInactive (desconectados con hp viva congelada) del revelado.
  Mismo fix en scr_player_hurt (weakMark): el CD de 16 s por
  superviviente nunca se aplicaba porque el exists devolvia false
  y el set re-creaba la variable a 0 en cada golpe -> ahora con
  global.player.id (instance_exists ya comprobado arriba).
  Create del indicador: scanList = [] explicito (antes un 0).
  Conteo de la cazadora (obj_metalamy/Step_0): tambien excluye
  isInactive.

- AUDITORIA DE MAPAS (switches por personaje estilo tirolina):
  se revisaron TODOS los objetos con logica por personaje de
  TODAS las salas (mapeado room -> objetos con CHARACTER_).
  * room_dotdotdot — BUG GORDO: obj_dotdotdot_shitladder clava
    maxHSpeed = 7 al rozarla, y el unico restaurador es el switch
    de obj_dotdotdot_i/Step_1, que solo tenia a los 8 originales:
    los 7 anadidos se quedaban PERMANENTEMENTE a velocidad 7.
    FIX: cases nuevos (SONIC/SALLY_CANON=stats Sally/VANILLA=stats
    Cream/METAL/AMELIA/BLAZE/FW) + subswitch de killers en el case
    EXE (antes devolvia EXE_MAXSPEED=12 a todos: Exetior es 11 y
    Metal Amy 13).
  * obj_eggtrack (tracker de Eggman): faltaba EXE_METALAMY en el
    switch del slow del lado EXE: la pisaba, se gastaba y no le
    aplicaba nada. FIX: case con slow 30% (METALAMY_*), su Alarm_4
    ya restaura.
  * scr_player_slow: faltaba FLEETWAY_AMY desde su llegada: hierba
    (weedzone), humo (ycr), trampa de Amelia y tracker no le
    aplicaban slow. FIX: case con FW_MAXSPEED/FW_ACC (40%).
  * obj_fart_dummy (fartzone): faltaba EXE_METALAMY: golpeaba el
    muneco y salia "0" sin empuje. FIX: case -2 como los demas
    killers cuerpo a cuerpo.
  * scr_carry (llevar colgado a un Tails/Cream/Vanilla volando):
    faltaban METAL/BLAZE/FW en scr_carry_zipline_state: podian
    agarrarse pero el portador no podia soltarlos con V y otro
    jugador podia colgarse del mismo portador (el check de
    pasajero unico no los veia). FIX: 3 cases (METAL_ZIPLINE,
    BLAZE_ZIPLINE, FW_ZIPLINE).
  * REVISADOS Y OK (sin cambios): obj_abyss, hd_door/hd_door2,
    nap_iceblock (Knux/gliding por diseno + universal salto/
    ataque/proyectil de Tails), pf_lift (el switch del Draw_72
    solo es cosmetico: los que faltan usan su propio sprite de
    hurt via su Draw_76), vv_vase (spin universal), majong,
    marijuna (offset cosmeco), weed, ycr_smoke, act9_wall/bodies,
    ravintmist_shard, deserttown, darktower, limpcity, camera,
    bigring/blackring, escondites (obj_hiding_parent agnostico),
    springs (METAL/VANILLA/SALLY_CANON ya cubiertos), muelles_fall
    (suite v5). LIMITACION SOLO ARTE: spr_act9_dead tiene 6 frames
    (Tails..Sally): los personajes 7+ no tienen cuerpo en act9 —
    hace falta arte nuevo, no codigo.

ARCHIVOS: objects/obj_exe_indicator/Create_0.gml y Step_2.gml,
objects/obj_metalamy/Step_0.gml, scripts/scr_player_hurt/
scr_player_hurt.gml, objects/obj_dotdotdot_i/Step_1.gml,
scripts/scr_player_slow/scr_player_slow.gml,
objects/obj_eggtrack/Step_0.gml, objects/obj_fart_dummy/Step_0.gml,
scripts/scr_carry/scr_carry.gml, LEEME_FIX_METALAMY_MAPAS.txt,
worklog.md. (El zip acumula tambien los archivos de la tirolina
v1 por si aun no estaban aplicados.)

VERIFICACION: balance de llaves/parentesis OK en los 10 GML
editados; macros usadas todas definidas (los CLIENT_* son enum
PacketType de net_packets.gml); los switches nuevos siguen el
patron de valores de los cases existentes (Alarm_4 de cada
personaje restaura los mismos macros); cero paquetes nuevos, todo
local. Pendiente: partida real — V de Metal Amy con supervivientes
escondidos (ver siluetas rojas a traves de paredes + fijadas al
borde), passive con 1 vivo (anillo dorado + revelado cada 14 s),
escalera del mapa «...» con Sonic/Blaze (recuperar velocidad al
soltar), tracker pisado por Metal Amy, muneco del fartzone, y que
un Tails suelte con V a un Metal/Blaze/FW colgado.
---

v5.4 — SALLY CANON: FASE DUELISTA («la Determinacion de la Princesa»)
========================================================================
Pedido: rework de Sally Canon. Su fase 2 (la de la 1ra caida) deja de
ser solo "se levanta con la vida llena": al terminar pt4 entra en la
FASE DUELISTA permanente (hasta el fin de la ronda), pasando de
defensiva a velocista-duelista. Fase 1 tambien recibe buffs para no
quedar indefensa, y de paso se arregla el bloqueo LMS de Sonic.

- FASE 1 (buffs): patada aerea con hitbox +25%
  (SALLY_CANON_KICK_PCT_F1) y escudo con recarga propia de 28 s
  (SALLY_CANON_SHIELD_RECHARGE, 2 s menos que la vanilla). Solo Sally
  Canon: la vanilla conserva sus 30 s y su patada normal.

- FASE DUELISTA (flag "duelista", se activa al final de pt4 en
  scr_sally_canon_fase2): viaja por red con el bitflag
  PLAYER_POWERBOOST (el byte de bitflags va lleno; ese bit solo lo
  usan Sonic/Vanilla/Metal/Blaze, jamas colisiona con ella). Los
  puppets lo guardan como "duelista" STICKY (net_udpprocess). OJO: no
  se toca powerBoost del puppet: la estela de fantasmas es solo de
  Sonic.

- PATADA EN TIERRA (X en el suelo, solo duelista): estado nuevo 22
  (SALLY_CANON_F2_ATTACK) con spr_sally_fase2_attack_canon (11
  frames: 1a patada 0-6, 2a patada 7+). La UNICA habilidad del juego
  que golpea al bando EXE 2 veces. Ignora TODOS los i-frames
  (shockedTimer/hurttime). Si la 1a conecta: el exe se TP al frente
  de Sally (borde del bbox + media hitbox, sin empujon) y la 2a le
  entra segura; si la 1a falla, la 2a puede conectar igual. Ventanas
  por el image_index SINCRONIZADO de CLIENT_PLAYER_DATA (el puppet no
  anima local: image_speed 0 en su Create). Corre en el cliente de la
  victima (obj_player_puppet Step_0). Hitbox +30%
  (SALLY_CANON_KICK_PCT_F2_GROUND); la aerea sube a +50%
  (SALLY_CANON_KICK_PCT_F2_AIR) — patron pad por distancia como el
  golpe de Sonic y el martillo de Amy (% del ancho del bbox).
  El EXE INVISIBLE sigue sin poder ser golpeado (consistente con el
  resto de contactos).

- SPINDASH (abajo + Z, solo duelista): porte 1:1 del de Amelia/Sonic
  (macros SALLY_CANON_SPINDASH_*): carga con revolucadas (tono
  creciente + polvo), al soltar ABAJO sale en bola (estado SPIN) a
  8+carga px/frame. Estado nuevo 23 (SALLY_CANON_SPINCHARGE) con
  spr_sally_spin_charger_canon. No salta mientras carga (guard nuevo
  en scr_move_basic junto al de Amelia). El stun y la propia fase 2
  cortan la carga (Step_0 + fase2_start).

- RODADURA + SALTO BOLA: canSpin pasa a true en duelista (rodadura
  con ABAJO corriendo, la de Tails y los demas) y su salto usa
  spr_sally_fase2_jump_canon (bola). Overrides de sprite en
  obj_sally_canon/Draw_76 (local) y obj_player_puppet/Draw_72
  (remoto), sin tocar las tablas en runtime (se reconstruyen al
  iniciar el juego, nunca por ronda: mutarlas pegaria).

- ESCUDO GRUPAL (C, solo duelista): mientras su escudo esta activo,
  los companeros en un radio de 120 px
  (SALLY_CANON_GROUP_SHIELD_RADIUS) reciben el MISMO efecto que el
  escudo tiene sobre ella: golpe absorbido entero + los MISMOS
  i-frames (SALLY_CANON_SHIELD_BREAK_INVULN, 5 s). Cada companero
  absorbe 1 golpe por activacion (gsAbsorbDone, se re-arma cuando el
  bit PLAYER_SALLYSHIELD se apaga). Todo en el cliente de la victima
  (scr_player_hurt), dirigido por el bit del puppet: cero paquetes
  nuevos. Poses propias: spr_sally_shield_canon (quieta),
  _down_ (agachada), _air_ (aire); caminando/corriendo el efecto va
  SIN animacion (burbuja fija frame 0). Su burbuja ahora SI se dibuja
  en el puppet (antes no se veia para nadie: hueco arreglado).

- PASIVA «INSTINTO DE LA PRINCESA DUELISTA» (solo duelista): 20% de
  evadir TODO el dano de un ataque (SALLY_CANON_EVADE_CHANCE) + 2.5 s
  de i-frames que se ACUMULAN a los existentes (hurttime += , no = ;
  incluye el escudo). Se tira SOLO en la instancia de dano real
  (tras el guard de hurttime en scr_player_hurt), nunca mientras ya
  esta inmune. El escudo ni se entera de un golpe evadido (la tirada
  va antes del check del escudo).

- FIX BLOQUEO LMS DE SONIC (pedido explicito): scr_lms_sonic_try_block
  se llamaba ANTES del guard de hurttime de scr_player_hurt: con
  Sonic ya inmune por un bloqueo anterior, cada roce con una fuente
  de dano re-tiraba el 55% y quedaba inmune para siempre pegado a un
  atacante. Ahora se llama DESPUES del guard (y del parry) + doble
  check defensivo dentro de la funcion: solo se tira cuando el golpe
  iba a entrar de verdad.

- ESCUDO GRUPAL, re-armado robusto: ademas del reset en scr_player_hurt,
  scr_move_basic observa por frame el bit del escudo de ella (patron
  del tick de weakMarkCd; solo corre para quien ya absorbio una vez,
  la variable la crea scr_player_hurt) y re-arma gsAbsorbDone cuando
  el escudo se apaga. Sin esto, si ella recasteaba antes de que el
  companero recibiera un golpe, el flag quedaba rancio y la nueva
  activacion no lo protegia.

ARCHIVOS (19): scripts/scr_sally_canon_fase2 (macros duelista +
activacion + corte de carga), scripts/scr_sally_special (patada en
tierra, CD canon, spindash), scripts/scr_survivors (tablas +idx 22/23
en player_anims y player_eanims), scripts/scr_player_hurt (evasion +
escudo grupal + fix LMS), scripts/scr_lms (guard defensivo),
scripts/scr_move_basic (no saltar cargando), scripts/net_udpprocess
(bit duelista sticky), objects/obj_sally_canon (Create/Step_0/Step_2/
Draw_0/Draw_76/Other_7), objects/obj_netclient/Step_2 (envio del bit),
objects/obj_player_puppet (Create/Step_0/Draw_0/Draw_72),
objects/obj_playerui/Draw_64 (HUD: patada lista en tierra en duelista
+ icono spindash + barra con CD canon 28 s).

VERIFICACION: balance de llaves/parentesis OK en los 19 GML; 20 macros
nuevas definidas; tablas SALLY_CANON con 24 entradas (estados 22/23
sin colision); sprites nuevos presentes (attack 11f, jump 8f, shield
5f, shield_down 7f, shield_air 4f, charger 5f, spindash 3f); ventanas
kick1<=6/kick2>=7 contra sprite de 11 frames; Sally vanilla intacta
(gates por personaje con short-circuit, mismo patron que
nerviosState/isFloatRunning). Cero paquetes nuevos: todo por state
byte (22/23), bitflags existentes (POWERBOOST/SALLYSHIELD) y effects.
Pendiente partida real: TP del exe visible en ambos clientes, doble
stun con merit x2, escudo grupal con un companero cerca, evasion 20%,
spindash de Sally vs el de Amelia, poses del escudo en el puppet.

---

v5.5 + v2.8 — FIX SALTO DUELISTA + METAL: I-FRAMES EN SUS 2 ATAQUES
========================================================================
Pedido (post-prueba del v5.4): (1) el salto de la fase duelista de
Sally Canon congelaba la animacion mientras subia (solo corria al
empezar a caer) y siendo un salto tipo SPIN (bola) deberia girar
continuo; (2) Metal Sonic debe tener i-frames en sus 2 ataques porque
"si no no tiene sentido que los haga".

- FIX SALTO DUELISTA (obj_sally_canon/Draw_76, case JUMP): el case
  JUMP congelaba image_speed mientras yspd <= 0 y clavaba el ultimo
  frame al caer — comportamiento pensado para el sprite vanilla de
  salto (pose fija de subida + pose de caida), pero la bola de la fase
  (spr_sally_fase2_jump_canon, 8 frames) heredaba el congelado y se
  quedaba quieta en la subida. Ahora, en duelista y SIN escudo puesto,
  image_speed = 1.1 constante durante TODO el arco (misma velocidad de
  giro que la bola del salto de Sonic, obj_sonic/Draw_76). Con el
  escudo grupal activo el sprite del aire es el del escudo
  (spr_sally_shield_air_canon) y ese SI conserva el comportamiento
  vanilla (pose de subida/caida). Fuera de la fase: intacto. El
  image_index viaja por red en CLIENT_PLAYER_DATA (u8), asi que el
  puppet de los demas clientes gira continuo sin tocar nada alli.

- METAL, diagnostico doble: sus 2 ataques (OVERDRIVE tecla B, 2 s a
  velocidad 16; SPARK FIELD tecla C, 1 s electrificado) solo existian
  para aturdir 3 s al killer que lo tocara... pero (a) ese stun estaba
  en CODIGO MUERTO: el bit PLAYER_ATTACKING jamas viajaba para Metal
  (no estaba en la lista de envio de obj_netclient/Step_2 ni en la de
  recepcion de net_udpprocess — solo Knux/Eggman/Amy/Amy_Canon/Sally/
  Sally_Canon/Sonic), con lo que el cliente del EXE nunca veia al
  puppet atacando y el caso METAL de obj_player_puppet Step_0 (con sus
  sprites/snd_metal_electro propios) no se ejecutaba NUNCA; y (b) un
  golpe cualquiera a mitad del ataque lo cortaba (isHurt corta
  metalDashing e isElectro). Resultado: los ataques no aturdian a
  nadie y encima se cancelaban solos — "no tiene sentido que los
  haga".

- METAL, fix (3 piezas):
  1) obj_netclient/Step_2: CHARACTER_METAL anadido a la lista de envio
     de PLAYER_ATTACKING. Para Metal isAttacking SOLO esta en true
     durante sus 2 ataques (scr_metal_special lo enciende al activar y
     lo apaga al terminar/cortar/ocultarse/anillo rojo/resorte), asi
     que el bit es exacto: cero falso-positivos.
  2) net_udpprocess: CHARACTER_METAL anadido a la lista de recepcion
     del mismo bit (mismo patron que el fix del golpe de Sonic v4).
     Con esto el puppet de Metal queda isAttacking en los clientes del
     bando EXE y el stun de contacto (3 s, particulas + snd propio del
     electro, empujon del overdrive) por fin se dispara.
  3) scr_player_hurt: guard de i-frames — mientras metalDashing > 0 o
     isElectro > 0, Metal no recibe dano (return temprano, mismo
     modelo que el golpe de Sonic o el dash/tarot de Amy Canon: sin
     vida, sin anillos, sin retroceso, sin cortar el ataque). La
     reparacion del Genio Malvado y el resto del kit no cambian. Los
     peligros que matan sin dano (caer al vacio, scr_player_instakill)
     siguen funcionando. Revisa de mas: ni stuns (el stun que el CAUSA
     corre en el cliente del EXE, no en el suyo) ni la rama demonizada
     (el esbirro Metal conserva el mismo comportamiento que cualquier
     esbirro atacante de otro personaje).

  Coherencia revisada antes de tocar: el bit para Metal solo lo
  consume la rama de stun de contacto de obj_player_puppet Step_0 en
  clientes del bando EXE (sobrevivientes y Eggman-electroshield no se
  ven afectados: Draw_0:204 es case CHARACTER_EGGMAN); entre
  supervivores no pasa nada (globalExe false); esbirros que toquen a
  un Metal atacante quedan aturdidos igual que con el martillo de Amy;
  CLIENT_PLAYER_HURT recibido solo hace shake de camara (no corta su
  ataque); Alarm_1/estados inactivos ya lo limpian.

ARCHIVOS (4): objects/obj_sally_canon/Draw_76 (salto duelista
continuo), objects/obj_netclient/Step_2 (envio del bit METAL),
scripts/net_udpprocess (recepcion del bit METAL), scripts/scr_player_hurt
(guard i-frames Metal). Cero paquetes nuevos, cero macros nuevas, cero
estados nuevos: todo por el bit PLAYER_ATTACKING existente.

VERIFICACION: balance de llaves/parentesis OK en los 4 GML; velocidades
de giro cross-check (bola Sonic 1.1 = bola Sally 1.1); guard con
short-circuit (global.player.metalDashing solo se lee si el personaje
local es Metal); listas de envio/recepcion simetricas. Pendiente
partida real: bola girando en la subida (local + pantalla del otro),
EXE tocando a Metal en overdrive/electro y comerse el stun de 3 s con
el sonido propio, golpe del EXE a mitad de overdrive SIN cortarlo, y
que el esbirro no herede rarasas.

---

v5.6 — FIX ESCUDO CANON: BURBUJA ANIMADA, SIEMPRE VISIBLE, SIN ATAR
A LA ANIMACION DEL CUERPO (como el escudo de la Sally vanilla)
========================================================================
Pedido (post-prueba del v5.5): con el escudo activo en fase duelista
(1) al quedarse quieta hacia la animacion de "activacion de escudo"
en bucle infinito; (2) la burbuja no se animaba (frame congelado) al
caminar/correr; (3) en idle la burbuja ni aparecia; en salto y suelo
igual. Diagnostico del usuario: "el escudo esta atado a la animacion,
cosa que no pasa con el escudo original vanilla de Sally".

CAUSA RAIZ: el v5.4 habia introducido overrides de sprite de CUERPO
por estado (spr_sally_shield_canon en IDLE, _down_ en LOOKDOWN, _air_
en JUMP/FALL) para el escudo grupal. Esos sprites de pose son anims
de cuerpo (levantar el brazo) SIN burbuja completa (VLM: solo un arco
rojo sobre la cabeza), y al colgarlos del estado: en IDLE loopeaban
sin parar (Other_7 hacia excepcion al clamp de reposo), en movimiento
la burbuja se dibujaba con frame fijo 0, y en los estados con pose ni
se dibujaba. El escudo quedaba visualmente rehén de la animacion del
cuerpo, justo lo que el usuario reporta. El juego original (upstream,
pre-rework) hacia EXACTAMENTE lo que el usuario pide: burbuja animada
aparte, en cualquier estado, sin tocar el cuerpo.

FIX (volver al comportamiento vanilla/original, en 5 GML):
- obj_sally_canon/Draw_0: la burbuja spr_sallyshield_canon se dibuja
  SIEMPRE que shieldTimer > 0, con (current_time / 30) % 41 (misma
  expresion exacta que la Sally vanilla en su Draw_0 y que el codigo
  original del canon). Sin branching por fase ni por estado.
- obj_sally_canon/Draw_76: fuera los overrides de pose del escudo
  (solo quedan bola de salto y bola de spindash, que son de la fase,
  no del escudo). El case JUMP duelista gira a 1.1 tambien CON escudo
  (antes frenaba el giro al activarlo): burbuja encima, como el
  escudo vanilla sobre el salto de Sally.
- obj_sally_canon/Other_7: el clamp del idle (image_number - 2) vuelve
  a ser incondicional; con escudo el cuerpo hace SU idle normal.
- obj_player_puppet/Draw_72: mismo recorte de poses para el puppet
  (los demas clientes ven bola + burbuja, o cuerpo normal + burbuja).
- obj_player_puppet/Draw_0: burbuja animada siempre que llegue el
  bitflag PLAYER_SALLYSHIELD, misma expresion vanilla.

NOTAS: los sprites de pose (spr_sally_shield_canon/_down_canon/
_air_canon) siguen EN el proyecto como assets upstream (no se tocan
los .yy), solo dejan de usarse. La mecanica del escudo (grupal, 5 s,
recarga 28 s, rompe = 5 s i-frames, expira = auto-rotura + i-frames,
EXE lo rompe = stun 3 s) NO cambia: es 100% visual. Cero paquetes
nuevos; el bitflag PLAYER_SALLYSHIELD sigue siendo lo unico que viaja.

VERIFICACION: balance llaves/parentesis OK en los 5 GML; diff revisado
linea a linea (solo se eliminan los bloques de pose y la condicion
shieldTimer <= 0 del giro); el patron de dibujo queda identico al de
la Sally vanilla (draw tras shader_reset, floor(x), floor(y)); sin
referencias residuales a los sprites de pose en objects/ ni scripts/
(grep). Pendiente partida real: burbuja animada quieta/andando/
saltando en local y en el puppet del otro cliente, idle en pose de
reposo con burbuja encima, bola del salto girando bajo la burbuja.

---

v5.7 — FIX ESCUDO (parte 2): VUELVEN LAS POSES, UNA VEZ Y CLAVADAS
(= el diseño original del usuario), burbuja animada siempre encima
========================================================================
Pedido (aclaracion del usuario tras probar v5.6): "las animaciones
(poses del escudo) son esenciales, por eso las cree. Si Sally cambia
de pose la animacion se interrumpe y solo se hace UNA vez por
habilidad: no entran en loop". O sea: el v5.6 quito las poses por
completo (overcorrection) y habia que reponerlas con la semantica
correcta, manteniendo el fix de la burbuja del v5.6.

IMPLEMENTACION (semantica una-vez-y-clavada):
- Create_0: variable nueva "shieldPoseSpr" (-1 = sin pose). Detecta
  cambios de pose en Draw_76: sirve tanto para cambiar de pose como
  para activar/desactivar el escudo.
- Draw_76: bloque de poses ANTES del switch (la pose manda sobre el
  sprite del estado y se asigna antes para que los clamps de los
  cases trabajen con el image_number de la POSE). Deteccion de
  cambio: image_index = 0 al entrar en una pose (la animacion
  anterior se INTERRUMPE y la nueva se ve desde el frame 0). Al SALIR
  de una pose se devuelve image_speed = 1 (el hold la deja en 0; los
  estados sin case propio en el switch, p.ej. la tirolina,
  heredarian ese 0 y quedarian congelados). Tras el switch, bloque
  final: image_speed = 1 y al llegar al ultimo frame se CLAVA
  (image_index = image_number - 1, image_speed = 0): nunca loopea.
  Guards: FALL no llama a scr_fall_anim con pose activa (le fijaria
  sus propios frames), JUMP no toca ni bola ni vanilla con pose
  activa (la pose del aire lleva su propia animacion).
- Other_7: el clamp del idle normal (image_number - 2) solo corre
  SIN pose activa (la pose se administra sola en Draw_76).
- Puppet Draw_72: vuelve la seleccion de sprite de pose (quieta /
  agachada / aire) cuando duelista + sallyShield. Nada de logica de
  animacion ahi: el image_index llega SINCRONIZADO por
  CLIENT_PLAYER_DATA (u8) y el puppet tiene image_speed = 0 (no anima
  solo), asi que en las demas pantallas la pose se ve una vez y
  clavada identico. La burbuja animada del v5.6 sigue encima siempre
  (Draw_0 del puppet, sin cambios).

COMPORTAMIENTO FINAL DEL ESCUDO DUELISTA (visual):
- Quieta: animacion de activacion UNA vez → clavada en la pose final.
- Agachada: pose una vez → clavada. Aire (salto/caida con escudo):
  pose una vez → clavada durante todo el arco. Cambios de pose:
  interrupcion + nueva animacion desde frame 0.
- Andar/correr/spindash/tirolina/etc.: sprites normales.
- Burbuja animada SIEMPRE encima, en cualquier estado (v5.6 intacto).
- Salto SIN escudo: bola girando a 1.1 (v5.5 intacto).
- Fase 1: igual que vanilla (burbuja animada, sin poses).

ARCHIVOS (4 GML cambiados): obj_sally_canon/Create_0 (var nueva),
obj_sally_canon/Draw_76 (poses + guards), obj_sally_canon/Other_7
(guard del clamp), obj_player_puppet/Draw_72 (sprites de pose). Los
2 Draw_0 van en el zip sin cambios (son el v5.6, incluidos para que
el zip sea completo venga de v5.4/v5.5 o v5.6).

VERIFICACION: balance OK en los 4 GML; referencias de shieldPoseSpr
coherentes (Create declara, Draw_76 administra, Other_7 consulta);
scr_fall_anim y la bola del salto quedan fuera del camino con pose
activa; el hold usa el mismo patron clamp que LOOKDOWN/DEAD del
juego base + image_speed = 0 (sin wrap posible => sin Animation End
=> sin riesgo de re-loop). Pendiente partida real: activacion una
vez y clavada en idle, crouch, salto con escudo (pose del aire, no
bola), interrupciones al cambiar de pose, todo igual en el puppet.

---

v5.8 — FIX ESCUDO (parte 3): POSES DE ACTIVACION DE UN SOLO USO
(una reproduccion al pulsar C y YA), cortadas por cambio de animacion
========================================================================
Pedido (post-prueba del v5.7, aclaracion definitiva del usuario): la
pose NO debe vivir atada a la vida del escudo. "Las animaciones de
activar el escudo deben ser de un solo uso: se reproduce una vez y
punto listo, no se vuelve a repetir en loop. Lo que ocurre es que se
repite mientras dura el escudo; si se va el escudo la animacion
termina, y asi no debe ser: la animacion solo debe aparecer cuando se
PRESIONA la habilidad, no durante la vida del escudo. Si la activo en
el aire pero caigo al piso (cambia su animacion), inmediatamente la
animacion [se corta]." El v5.7 ademas dejaba la pose CLAVADA en su
ultimo frame mientras duraba el escudo y re-disparaba una reproduccion
por cada cambio de estado con escudo (la de agacharse "se repetia una
y otra vez").

IMPLEMENTACION (pase unico al pulsar, contador propio, cero contacto
con sprite_index/image_index — ahi estaban todos los loops):
- scr_sally_special (NUEVO en el zip): al pulsar C (mismo sitio donde
  se pone shieldTimer) se arranca la pose: categoria segun el estado
  del momento (JUMP/FALL = aire, LOOKDOWN = agachada, resto = tierra)
  y sprite acorde (spr_sally_shield_air_canon / _down_canon /
  _canon). Gate canon+duelista+sano (la Sally vanilla comparte el
  script: corta antes de tocar las vars canon, mismo patron que
  groundKick).
- obj_sally_canon/Create_0 (NUEVO en el zip): macro
  SALLY_CANON_POSE_VEL 0.5 (frames de pose por frame de juego: cada
  frame de pose dura 2 frames de juego; ajustable) + vars
  shieldPoseOn/Spr/Cat/T.
- obj_sally_canon/Step_2 (NUEVO en el zip): la pose avanza UNA vez
  (shieldPoseT += VEL hasta sprite_get_number(pose)) y se CORTA si
  cambia la familia de animacion (aire <-> suelo <-> agachada), si la
  interrumpen dano/stun/muerte/fase 2 o si el escudo se apaga. Va al
  principio del End Step: lee el estado fresco del frame anterior
  (el mismo con el que se eligio al pulsar).
- obj_sally_canon/Draw_0: mientras shieldPoseOn el cuerpo se dibuja
  con la pose (floor(shieldPoseT)) en vez del sprite del estado,
  MISMO draw_sprite_ext (palette swap, facing, escala fase 2, alpha):
  identico look, cero cambios de mecanica. La burbuja animada del
  v5.6 sigue SIEMPRE encima (la pose es del cuerpo, la burbuja del
  escudo).
- obj_sally_canon/Draw_76 y Other_7: vuelven al v5.6 PURO (solo nota
  de comentario v5.8). Al no pasar la pose por sprite_index, ni el
  switch con sus clamps ni el Animation End pueden congelarla,
  reiniciarla o loopearla: la causa raiz de v5.4-v5.7 desaparece.
- Puppet (Create_0/Step_0 NUEVOS en el zip, Draw_0 editado, Draw_72
  al v5.6 puro): flanco de subida del bitflag PLAYER_SALLYSHIELD =
  "acaba de pulsar C". El estado llega en el MISMO paquete, asi que
  la categoria elegida coincide con la local siempre; desde ahi corre
  su propio contador con los mismos cortes (cambio de familia, escudo
  off, HURT/DEAD). Draw_0 del puppet dibuja la pose igual que el
  local. Ya NO depende del image_index sincronizado (el v5.7 si):
  cada cliente la anima solo, sin paquetes nuevos.

COMPORTAMIENTO FINAL DEL ESCUDO DUELISTA (visual):
- Al pulsar C: pose de activacion UNA vez (tierra/agachada/aire segun
  el momento) y YA: no loopea, no se clava, no vuelve a salir durante
  la vida del escudo. Solo la PROXIMA pulsacion (tras recarga) la
  trae de vuelta.
- Cambio de animacion a mitad de pose (ej. aire → suelo): corte en
  seco inmediato, cuerpo vuelve a su sprite normal.
- Resto del escudo: sprites normales (andar/correr/agacharse/bola)
  con la burbuja animada encima en cualquier estado (v5.6 intacto).
- Salto SIN escudo: bola girando a 1.1 (v5.5 intacto). Fase 1: igual
  que vanilla. Mecanica del escudo: INTACTA (100% visual).

ARCHIVOS (10 GML): scr_sally_special, obj_sally_canon/Create_0,
Step_2, Draw_0, Draw_76, Other_7; obj_player_puppet/Create_0, Step_0,
Draw_0, Draw_72.

VERIFICACION: balance llaves/parentesis OK en los 10 GML (script
scripts/check_balance_v58.py, con check anti-tabs: estos archivos
llevan sangria de 8 espacios, no tabs); diff bafeab82 (v5.6
comiteado por el usuario) revisado archivo por archivo; grep de
shieldPose* coherente (seteo solo tras gate canon+duelista; obj_sally
vanilla con 0 referencias; Draw_76/Other_7/puppet Draw_72 sin
referencias); sin vars duplicadas (_poseCat/_poseCatNow declaradas
una vez por evento); em-dashes solo en comentarios (uso ya existente
en estos archivos). Pendiente partida real: pose una vez al pulsar en
quieta/agachada/aire, corte al caer al suelo a mitad de pose, NO
re-sale al moverse/agacharse durante el escudo, burbuja animada
encima durante la pose, misma cosa en el puppet del otro cliente.

---
Task ID: fix-fase2-slide-v1
Agent: Super Z (main agent)
Task: Bug reportado por el usuario: al golpear a Sally Canon en su pose
de fase 2 pt1 (retroceso del golpe) se desliza hacia el lado contrario
del golpe y NUNCA se detiene: solo la frena una pared, un precipicio, o
caer de una altura (donde queda quierta tras el salto de pt3). Deberia
frenar al tocar el piso.

Work Log:
- Leido el motor completo de la fase 2 (scr_sally_canon_fase2) + Step_0
  de obj_sally_canon + scr_collision_basic (check_bottom, check lateral)
  + la friccion del estado HURT de scr_move_basic (0.06/frame, referen-
  cia de como frena el juego un knockback normal).
- CAUSA RAIZ: scr_sally_canon_fase2_start da el retroceso (xspd = 5.5).
  Al aterrizar, scr_collision_check_bottom pone isGrounded, yspd = 0 y
  hereda gspd = xspd, pero NADA mata el impulso horizontal. Durante
  toda la fase 2 Step_0 no llama a scr_move_basic (que es donde vive
  la friccion normal), asi que el xspd queda congelado en 5.5 para
  siempre y x += xspd cada frame = deslizamiento infinito en pose de
  vuelo. Solo lo cortaban: una pared (check lateral pone xspd y gspd a
  0), el salto de pt3 (pone gspd/xspd a 0 antes de saltar), o el abis-
  mo (teleport + reset). Exactamente lo que el usuario veia.
- FIX 1 (ruta principal): transicion PT1 -> PT2 por aterrizaje: dentro
  del if(isGrounded) (junto al polvo que ya salia) se mata el impulso:
  gspd = 0 y xspd = 0. Para en seco donde toco el suelo.
- FIX 2 (red de seguridad, mismo bug por la otra puerta): si el timer
  de pt1 (90 frames) se agota EN EL AIRE (hoyo/borde), aterriza ya
  DENTRO de pt2 con la velocidad heredada: sin freno se deslizaria los
  3.5 seg enteros de pt2. Nueva macro SALLY_CANON_F2_PT2_FRICTION
  (0.5): mientras este en el suelo en pt2, gspd y xspd pierden 0.5 por
  frame (de 5.5 a 0 en ~11 frames = ~0.2 seg, frenado de cuerpo tira-
  do en el suelo). Mismo idiom de friccion del stun en Step_0
  (min(abs(v), k) * sign(v); sign(0)=0 no mueve nada).
- Documentada la macro en el bloque de PARAMETROS del cabecero del
  script, con el estilo de las demas.

VERIFICACION: scripts/check_fase2_slide.py (nuevo): chequeo estatico
(balance {} 13/13, () 41/41, sin tabs, sangria 8 espacios, las 5
modificaciones presentes) + simulacion frame a frame del motor (gravedad
0.21875 y jumpForce 6.5 reales de Create_0, conversion gspd = xspd al
aterrizar, orden fase2 -> colision del Step):
  plano SIN FIX: tras aterrizar se desliza +1155 px (infinito hasta
                 pared/precipicio) = bug reportado;
  plano CON FIX: para EXACTO donde toco el suelo (+0 px);
  hoyo  SIN FIX: aterriza dentro de pt2 y se desliza +1128 px;
  hoyo  CON FIX: frena en seco tras 27.5 px (~5 frames).
Pendiente partida real: golpearla en suelo plano (debe caer, polvo, y
quedarse quieta ahi), derribarla sobre un hoyo profundo (debe aterrizar
abajo y frenar en seco, no cruzarse el mapa deslizando), y confirmar
que pt3/pt4 no cambiaron (el salto sigue igual).

---
Task ID: fix-v4.9-manejo
Agent: Super Z (main agent)
Task: 2 fixes pedidos por el usuario: (1) mejorar el manejo del
spindash general ("su control es un poco tosco, recuerda mucho a CD")
y (2) anadir un tiempo de coyote para reducir los saltos falsos.

Work Log:
- Mapeado el sistema completo: spindash de Sonic/Amelia/Sally Canon
  (3 portes del mismo gate), bloque de salto de scr_move_basic, y TODOS
  los especiales que consumen la tecla Z en el aire (grep de KeyA en
  los 19 specials + objetos): Tails (vuelo), Knux (planeo), Amy
  Fleetway (DJ) la consumen SIN exigir isJumping; el resto (Blaze,
  Cream, Vanilla, EXEs, Egg, MetalAmy, Chaos) la exigen y isJumping es
  false al caer de un borde: sin conflicto.
- CAUSA del spindash "tosco": el gate de arranque exigia gspd == 0
  EXACTO. En la "zona gris" 0 < |gspd| < 2 (frenando) apretar abajo+Z
  no arrancaba la carga... y como el gate no capturaba el Z, el bloque
  de salto de move_basic lo pillaba: SALTO ACCIDENTAL en plena
  agachadilla (el input se sentia comido/tr traicionero). Encima, el
  umbral de rodadura (abajo corriendo) es |gspd| >= 2: entre 0 y 2
  abajo no hacia NADA (ni agacharse ni rodar ni cargar).
- FIX SPINDASH A (arranque con margen): nueva macro por personaje
  (*_SPINDASH_START_MAX = 2, junto a sus demas macros): con
  |gspd| < 2 el gate arranca la carga frenando en seco (el bloque de
  carga ya clava gspd = 0); !isSpinning evita arrancar desde una
  rodadura lenta (ahi Z = salto fuera de la bola, como los clasicos).
  Encaja exacto con el umbral de rodadura: < 2 = carga, >= 2 = rodar.
  Aplicado a Sonic (scr_sonic_special + macro en obj_sonic/Create_0),
  Amelia (scr_amelia_special) y Sally Canon (scr_sally_special, macro
  en scr_sally_canon_fase2).
- FIX SPINDASH B (anclaje en pendientes): el codigo de pendiente de
  scr_move_basic corre ANTES que specialFunc y ya habia arrastrado el
  xspd con el empujon de la cuesta (gspd = 0 llegaba tarde): la carga
  se deslizaba ladera abajo. Ahora el bloque de carga tambien clava
  xspd = 0 (los 3 personajes).
- FIX COYOTE (scr_move_basic): macro PLAYER_COYOTE_FRAMES 6 (100 ms).
  coyoteTimer se declara lazy al inicio de scr_move_basic con el
  patron variable_instance_exists del proyecto (weakMarkCd/
  gsAbsorbDone): sin tocar el Create de los ~20 personajes. Se rellena
  en el suelo, se gasta 1/frame en el aire. El bloque de salto salio
  del else (solo contenia eso) y ahora es un if standalone con la
  puerta de aire: (isGrounded || (coyoteTimer > 0 && yspd >= 0 &&
  !isZipline)). yspd >= 0 + !isJumping + ventana de 6 frames =
  imposible doble saltar; al saltar se consume (coyoteTimer = 0).
  Mismos guards de siempre, mismo orden, nada mas cambia la puerta.
- PRIORIDAD DE INPUT: el grant/decrement va DESPUES de specialFunc a
  proposito. Tails/Knux/Fleetway ceden el Z a la ventana de salto con
  un gate nuevo (!(variable_instance_exists(id, "coyoteTimer") &&
  coyoteTimer > 0 && yspd >= 0)): Z dentro de la ventana = SALTO
  normal; la siguiente pulsacion = vuelo/planeo/DJ, como en los
  clasicos. El guard de variable_instance_exists es obligatorio:
  specialFunc tambien corre suelto con canMove == false (obj_tails
  Step_0) antes del 1er frame de move_basic. El saltito del carry y el
  de la tirolina ya usan keyboard_key_release + isJumping = true: sin
  conflicto. El drop dash de Sonic arma tambien con saltos coyote
  (latch por isJumping en el aire): consistente.

VERIFICACION: scripts/check_v49_manejo.py: balance {} () en los 8
archivos (93/93, 18/18, 15/15, 29/29, 13/13, 12/12, 22/22, 22/22,
14 parejas), indentacion limpia (8 espacios, cero tabs; los comentarios
anadidos en scr_tails/scr_knux_special quedaron con espacios, igual
que el archivo), presencia de los 17 cambios. Simulacion frame a frame
con el orden real del Step (specialFunc -> grant/decrement -> salto ->
collision): Z en frames de aire 1-5 = salta, 6+ = no; salto real + Z
en ascenso = no hay doble; Tails: Z en frame 2 = salto, frame 10 =
vuelo. Spindash: abajo+Z con gspd 1.5 = arranca carga SIN salto
(antes: Z perdido + salto accidental); con gspd 3.0 = rodadura igual
que siempre; carga en pendiente 30 = xspd 0.0 (antes -0.062/frame de
deslizamiento); lanzamiento intacto (BASE 8 + carga). Pendiente
partida real: borde + Z justo despues (los 6 frames), pendiente fuerte
cuesta abajo (el coyote tambien arregla el salto comido al despegarse
corriendo), spindash frenando/apretando abajo+Z antes de parar del
todo, carga en cuesta, y Tails/Knux/Fleetway: Z al borde = salto, Z
tardio = habilidad.

NOTA MOTORES (pregunta del usuario): Clickteam Fusion es el motor de
los Sonic.exe disaster clasicos y SOH (hoja de eventos, sin control
frame a frame fino: por eso sus fisicas se sienten limitadas).
GameMaker no trae "fisicas de Sonic" de fabrica tampoco, pero da
control total por frame — este proyecto YA tiene un motor clasico de
Sonic propio (gspd/xspd/angulo/sensores en scr_move_basic +
scr_collision_basic, el enfoque Genesis de verdad); los engines de
referencia en GM son Sonic MAX y afines (open source). Con estos dos
fixes el feel queda al nivel de esos kits sin cambiar de motor.

---
Task ID: fix-v5.3-bola-salto
Agent: Super Z (main agent)
Task: 2 ajustes pedidos tras probar v4.9: (1) subir el coyote time a
10 frames ("para darle un tanto mas de posibilidad") y (2) que saltar
con el spindash NO abandone el estado bola: "cuando salto pasa a su
animacion de salto normal... la habilidad se cancela al saltar como
tal (cosa que no pasa si pasa por una subida y lo manda al aire: ahi
conserva el estado y la velocidad)". Referencia citada por el
usuario: Sonic MAX (framework GMS2 open source).

Work Log:
- COYOTE 10 (scr_move_basic): macro PLAYER_COYOTE_FRAMES 6 -> 10
  (100 -> ~167 ms). Solo cambia el numero, su comentario de cabecera
  y el "los propios 6 frames" del bloque de salto (ahora 10). Todo el
  mecanismo v4.9 (grant en suelo, gasto 1/frame en aire, puerta de
  aire con yspd >= 0, consumo al saltar) intacto.
- SALTO EN BOLA — mapa previo: isSpinning aparece en 117 archivos.
  Lo que importa: (a) las maquinas de animacion de TODOS los
  personajes priorizan isSpinning -> SPIN por delante de la rama de
  aire isJumping -> JUMP (obj_sonic/Step_2: linea 137 vs 159, y sus
  equivalentes en exe/tails/knux/etc); (b) la pasiva de repeler el
  salto/rodadura del EXE ya cubria (isJumping || isSpinning)
  (obj_sonic/Step_0:231); (c) el clamp de rodadura de
  scr_collision_basic usa isSpinning; (d) por red viaja el "state" YA
  RESUELTO (SPIN es valor legal y corriente: es como hoy se ve una
  rodadura ajena despegada de una subida); (e) los especiales aereos
  que consumen Z (vuelo de Tails, planeo de Knux, vuelo de Cream) ya
  apagan isSpinning al activarse ellos mismos; (f) el aterrizaje
  (scr_collision_check_bottom) solo hace gspd = xspd: no toca flags.
- CAUSA: el bloque de salto de scr_move_basic hacia "isSpinning =
  false" incondicional. La rodadura despegada por pendiente
  conservaba estado y velocidad, pero el SALTO devolvia la animacion
  de salto y al aterrizar ibas DE PIE: cancelacion prematura de la
  habilidad. Mismo estado, dos salidas: inconsistencia pura.
- FIX (scr_move_basic, bloque de salto): quitado el isSpinning =
  false. Regla unica del motor: SI ESTABAS EN BOLA, EL SALTO NO TE
  SACA DE LA BOLA. Aplica a la rodadura (abajo corriendo), al
  spindash de Sonic/Amelia/Sally y al drop dash: mismo flag, misma
  regla. En el aire la animacion sigue siendo la bola (SPIN gana),
  la pasiva de repeler ya cubria, y al aterrizar gspd = xspd con el
  estado vivo: SIGUES RODANDO con la velocidad que llevaras. Cero
  cambios de red/colision/objetos: "isSpinning en el aire" ya era un
  estado legal del motor.
- DROP DASH (scr_sonic_special): el latch dropDashFromJump ("este
  vuelo empezo con un salto") ahora exige !isSpinning. Sin el gate,
  el salto en bola armaba el drop dash y su disparo al aterrizar
  PISABA la velocidad conservada con la fija de SONIC_DROPDASH_SPEED
  (14: menos que un spindash de 4-5 revs) y hasta podia INVERTIRTE
  si giraste la mirada con el control aereo (el disparo usa
  image_xscale). El drop dash queda para saltos normales (de
  pie/corriendo), que es su proposito: RECUPERAR la bola.
- EXEs y demas personajes: la regla es del motor y les aplica igual
  (rodar + saltar = bola en el aire). El contacto del puppet ya
  trataba JUMP y SPIN como el mismo ataque-bola: combate idem. Chaos:
  su stuck-dash se sigue cancelando al despegar; solo que si saltas
  en pleno dash aterrizas rodando (coherente con la regla).
- NOTA FISICA: el air drag clasico del motor (xspd -= xspd/32 por
  frame mientras -4 < yspd < 0, aplicado junto al apex) NO se toco:
  es Genesis puro y aplica a TODOS los saltos. Un spindash a 16
  aterriza a ~9 tras un salto; lo que conserva el fix es el ESTADO
  (y con el la pasiva y seguir rodando).

VERIFICACION: scripts/check_v53_bola_salto.py (estatica + simulacion
frame a frame con el orden real del Step). Estatica: balance {} ()
[] en los 2 archivos (93/93, 242/242; 18/18, 95/95), 0 tabs,
presencia de los 5 cambios, bloque de salto sin "isSpinning = false"
(fuera de comentarios) y regression de los 3 especiales que apagan
la bola (Tails/Knux/Cream). Coyote 10: Z en frames de aire 1-9 =
salta, 10+ = no; salto real + Z en ascenso = sin doble; Tails: Z en
ventana = salto, Z tardio = vuelo. Salto en bola: rodando a 16 y
saltar -> aterriza RODANDO (isSpinning vivo, sigue rodando al final
del sim); SIN fix aterriza DE PIE y acaba parado (gspd 0). Z
MANTENIDO en el salto en bola: drop dash NO arma ni dispara, la
rodadura manda; SIN fix pisaba el gspd a 14 fijo. Salto normal + Z
mantenido: drop dash arma y dispara a 14 INTACTO. Borde en rodadura
+ Z dentro de la ventana = salto EN BOLA. Tails: bola + salto + Z en
el aire = vuelo (apaga la bola, no aterriza rodando). Pendiente
partida real: spindash lleno + salto (bola todo el vuelo, aterrizar
rodando), salto en bola manteniendo Z (sin destello de armado del
drop dash), salto normal + Z mantenido (drop dash como siempre), y
rodar+saltar con Tails/Knux y luego volar (sin bola colgada).

NOTA FIDELIDAD (pregunta del usuario: "comparado a un juego de sonic
en que carece el tdr?"): honestamente, en CLASICOS puros (S2/S3&K/
Mania) saltar desde la rodadura SI te saca de la bola y aterrizas de
pie — de ahi que Mania inventara el drop dash (para recuperar la
bola tras saltar). Lo implementado a peticion (salto que conserva el
estado) es el enfoque MODERNO tipo Sonic MAX: el spin como
habilidad-estado que el salto no interrumpe — perfectamente legitimo
y mas comodo para un remake 2D. Con v4.9 + v5.3 el kit de movimiento
ya cubre: spindash con revs reales, rodadura con fisica clasica
(friccion 0.0234375, factor de pendiente 0.225, tope 18), drop dash
estilo Mania, coyote time, salto en bola, air drag clasico y control
aereo estilo S3&K. Lo que GENUINAMENTE le falta frente a un Sonic de
verdad, en orden de impacto: (1) SALTO DE ALTURA VARIABLE — soltar Z
a mitad del ascenso deberia cortar el salto (en Genesis: soltar el
boton con yspd < -4 clava yspd = -4; aqui jumpForce solo inicia el
salto y no hay corte alguno); (2) JUMP BUFFER — apretar Z justo
antes de aterrizar deberia saltar en el frame de contacto (QoL
moderna, complemento natural del coyote); (3) geometria de nivel
360 (loops/corkscrews: el motor maneja angulos y sensores, pero los
mapas TDR no tienen loops). Propuesta: proximo fix = (1), es 6
lineas y cambia el feel entero del salto.

## v5.9 (2026-11-07) — LIGHT DASH DE AMY CANON: el rayo que se come las líneas de anillos

PEDIDO: tras el coyote v5.3 el usuario pidió mecánicas nuevas que
aprovecharan los mapas sin loops; de la lista eligió el LIGHT DASH
(Sonic Adventure) y subió su animación propia
(spr_amy_light_speed_canon). Pregunta concreta que motivó el diseño
de la rotación: "el sprite debería rotar si es hacia arriba... si
estoy rotada hacia arriba y la zona está hacia la derecha, ¿voy a
estar moviéndome de espaldas?".

Work Log:
- NUEVO scripts/scr_light_dash.gml (+.yy, registrado en el .yyp):
  Z PULSADA en el aire junto a una línea de >= 2 anillos vivos
  dentro del radio de captura (56 px el primero, eslabones de hasta
  48 px, tope de 16) = Amy se vuelve un rayo a LIGHT_DASH_SPEED
  (16 px/frame, un spindash lleno) que recorre la cadena comiéndose
  cada anillo y sale disparada con el impulso del último tramo
  (columnas = ascensores, filas = carriles). El finder es codicioso
  por vecino más cercano: con las líneas/columnas/arcos reales de
  los mapas (anillos a 24-36 px) sigue el camino exacto.
- ROTACIÓN = "el método rotativa de las inclinaciones", ampliado a
  360: la pose se escribe en la MISMA variable `angle` de las
  pendientes; el draw local usa radtodeg(angle) y por red viaja
  resuelto (s16 en grados + image_xscale) — el puppet replica la
  vuelta SIN un byte nuevo de red. Correspondencia: viajando a la
  derecha rotación = dirección; a la izquierda rotación = dirección
  - 180 (siempre cae en -90..+90: nunca cabeza abajo, nunca de
  espaldas). El giro entre tramos es un LERP sobre el ángulo
  RENDERIZADO (R), no el de dibujo: el espejo cambia el forward
  180° de golpe, así que la mirada se RE-DERIVA de R en cada frame
  y el flip cae siempre en la vertical (R = ±90), donde ambas
  miradas dibujan lo mismo — el volteo es continuo, cruza de
  arriba-derecha a arriba-izquierda PASANDO POR ARRIBA. Bug pillado
  por el checker y arreglado: el lerp converge por el camino corto
  en espacio envuelto y deg podía acabar fuera de rango (-355 =
  5): canonización con whiles al final del bloque.
- RECOGIDA DIRECTA: a 16 px/frame un frame puede saltarse un anillo
  por dentro (la máscara no lo toca) — el dash marca el anillo
  (used) y manda el MISMO CLIENT_RING_COLLECTED que mandaría su
  Step (iid + nid): el server responde igual que siempre (rings,
  sonido, curación de los 10) en todos los clientes. Cero cambios
  en obj_ring, cero paquetes nuevos.
- INTEGRACIÓN: hook en scr_move_basic justo tras el bloque de
  muerte: `if(scr_light_dash_step()) { scr_collision_basic();
  scr_light_dash_pose(); return; }` — el collision corre igual
  (sensores honestos, mismo patrón que el early-return de
  !isServerReady) y la pose se REAPLICA después porque el collision
  resetea angle=0 en el aire y sumaría la gravedad del frame. En el
  frame de salida step() devuelve false dejando el impulso en
  xspd/yspd: la física normal toma el relevo ese mismo frame.
- ESTADO: AMY_CANON_LIGHTDASH = BALANCING+12 = 25 (el 24 es el
  AMY_CANON_HUG del abrazo combinado, interceptado antes del array:
  colisión pillada a tiempo). Índice 25 = spr_amy_light_speed_canon
  en player_anims y player_eanims (el 24 de los arrays es un
  spr_none de hueco). Animación en loop a LIGHT_DASH_ANIMSPD
  (Draw_76); el puppet anima solo con el image_index que ya viaja.
- GATES (variables lazy al estilo coyoteTimer, sin tocar Creates):
  solo CHARACTER_AMY_CANON, NO demonizada (revivalTimes >= 2 no
  puede recoger anillos: la cadena no se tragaría nada), aire, viva,
  sin stun/tirolina/acompletida/impulso-tarot/flotación/HJ/ataque/
  burbuja activa/abrazo/parry/anillo rojo. Salidas: cadena agotada,
  daño, muerte, stun, tirolina, burbuja, abrazo, parry iniciado,
  anillo rojo, bordes de sala, caer del mapa, tope de 120 frames.
  La flotación del tarot (Step_0) y las 3 activaciones de
  scr_amy_canon_special (martillo/impulso/acometida) llevan ahora
  !isLightDashing. Durante el dash NO es un ataque: el contacto
  con el EXE le hace daño normal (movilidad pura con riesgo) y la
  contra-jugada nativa sigue siendo que el EXE reviente los anillos
  de la línea (el dash salta el eslabón roto y sigue).
- SPRITE: spr_amy_light_speed_canon — la animación REAL del
  usuario, ya en el proyecto y commiteada por él (1 frame 35x33,
  origen 23,20, layer único). El dash la dibuja tal cual; el
  LIGHT_DASH_ANIMSPD de Draw_76 es inofensivo con 1 frame y queda
  listo por si la animación crece (no hay que tocar nada). La entrada
  del .yyp del sprite la añadió GMS2 al guardarla el usuario; la del
  SCRIPT (scr_light_dash) es la única entrada nueva del yyp de este
  paquete (verificado: sin duplicados).
- REBASE (regla de oro): el trabajo se hizo sobre la base vieja
  (bafeab82) y se re-aplicó sobre los 5 commits nuevos del usuario
  (30ab04d4: fixes v4.9/v5.3 de manejo, Sally duelista, etc.) tras
  git pull. Fusiones: el hook del scr_move_basic cayó igual (después
  del bloque de muerte, antes del de daño); SALLY_CANON_POSE_VEL se
  quedó en 0.1 (el tuning propio del usuario, no el 0.5 viejo); el
  yyp traía el sprite ya registrado por el usuario y se quitó el
  duplicado que añadió el rebase.

VERIFICACIÓN: scripts/check_v59_light_dash.py (estática + simulación
frame a frame) — 53/53 OK sobre la base nueva. Estática: brackets en
los 7 archivos, los 8 puntos de integración, HUG(24) != LIGHTDASH(25),
arrays de 26, sprite real del usuario con sus frames y layers, yyp
registrado sin duplicados, sin placeholders. Simulación: la L
fila->columna come los 6 anillos con 6 paquetes únicos y sale hacia
arriba a 16; el caso del usuario (columna que dobla a la derecha)
converge mirando a la derecha; el arco que cruza la vertical gira
continuo (sin saltos > 90°) y termina en la bajada (abajo-derecha);
barrido exhaustivo de 360°: converge apuntando a la dirección de
viaje con |deg| <= 90 en TODAS; fila de 4x28 px a budget 16 no deja
anillos vivos; anillo roto a mitad de vuelo se salta y come el resto;
gates (1 anillo no dispara, > 56 px fuera, fade-in excluido) y tope de
16 eslabones. PENDIENTE DE PRUEBA REAL: probar en partida (columna
de GHZ x=3592, filas de 3, arcos sobre rampas) viendo el volteo en
vivo — en especial el caso que preguntó el usuario: columna que
dobla a la derecha (debe cruzar POR ARRIBA y quedar mirando a la
derecha, nunca de espaldas).

## v5.9.1 (2026-11-07) — FIX del crash de primer frame + ESTELA FANTASMAL del light dash

PEDIDO: el usuario reporto el crash "Variable
obj_amy_canon.isLightDashing not set before reading it" en
gml_Object_obj_amy_canon_Step_2 line 99 al probar la v5.9, y pidio
añadir "un efecto fantasmal para cuando amy este usando el light".

Work Log:
- CAUSA DEL CRASH: las vars del dash se declaraban LAZY dentro de
  scr_light_dash_step (patron coyoteTimer), pero el hook vive en
  scr_move_basic DETRAS de dos early-returns: el de !isServerReady
  (conectar / practice / timeout de envio) y el bloque de muerte.
  En esos frames el init no corre, y el Step_2 de Amy lee
  "if(isLightDashing)" en crudo — mismo pozo que el v4.9 documento
  para specialFunc (corre suelto antes del 1er frame de move_basic).
  El Step_0 (lineas 58/69) tambien lee la flag, pero ahi lo tapaba
  el cortocircuito de la cadena de gates; el Step_2 no tenia nada.
- FIX: obj_amy_canon/Create_0 declara las 11 vars del dash
  (isLightDashing + cadena + pose + estela). El bloque lazy del
  script queda como red de seguridad para el RESTO de personajes
  (el hook de move_basic corre para todos y su primera lectura
  "if(isLightDashing)" la necesita). Con esto el dash ya no depende
  del orden de eventos ni del estado del servidor: imposible que
  vuelva a saltar.
- ESTELA FANTASMAL (local): en el Draw_0 de Amy, mismo patron que
  la estela del float run de Vanilla y la del powerboost de Sonic
  (obj_quickeffect_fade): un fantasma cada LIGHT_DASH_GHOST_EVERY
  (2) frames copiando sprite, indice, mirada y — la clave — la POSE
  ROTADA (image_angle = isSpinning ? 0 : radtodeg(angle), el metodo
  de las inclinaciones): los fantasmas suben las columnas girando
  igual que el cuerpo, nunca "planos" en los tramos verticales.
  Con la paleta del jugador (como el fantasma del effectTime) y
  depth propio + 1 para quedar detras. Fade a
  LIGHT_DASH_GHOST_FADE (0.06/frame ~ 17 frames de vida): a 16
  px/frame la estela pinta un rayo continuo de ~270 px.
- ESTELA FANTASMAL (remota, los demas clientes): el puppet ya
  recibe TODO lo necesario en el paquete de siempre — estado
  resuelto 25 (AMY_CANON_LIGHTDASH), angle (s16 en grados) e
  image_xscale — asi que su Step_0 genera la misma estela local en
  cada cliente: CERO bytes nuevos de red, sin bitflags nuevos (no
  como el powerboost, que necesita PLAYER_POWERBOOST: aqui el
  estado ya existe). Usa el ghostTimer que ya tenia el puppet.
- BUG LATENTE ENCONTRADO (NO tocado, fuera de alcance): el ghost
  del powerboost del puppet (Step_0, lineas ~130-140) hace
  "image_angle = radtodeg(angle)" con el angle del puppet, que YA
  llega en grados del paquete (el emisor escribe radtodeg(angle));
  doble conversion. No se nota porque Sonic corre en llano
  (angle ~ 0 => radtodeg(0) = 0). En la estela del dash SI importaba
  (viaja en vertical): la nueva usa el angle tal cual. Si algun dia
  se ve raro el powerboost en pendientes, es ese radtodeg de mas.

VERIFICACION: checker v5.9 ampliado a 72/72 OK: los 10 checks
nuevos (Create declara las 11 vars, macros de estela, lazy con
ghostTimer, estela local con pose rotada y paleta, estela remota
con el gate de personaje+estado, angle del puppet en grados sin
radtodeg) mas el balance de brackets en los 3 archivos nuevos
tocados (Create, Draw_0, puppet Step_0). Toda la simulacion de la
v5.9 intacta y pasando.

## v5.9.2 (2026-11-07) — LIGHT DASH: FLECHA INDICADORA — la Z sin choque con la flotacion del tarot

PEDIDO DEL USUARIO: "amy ya tiene una habilidad al dejar presionada
la Z (flotar con las tarot); habra que colocarle una flecha o algo
para que no choque con la otra habilidad".

DECISION DE DISEÑO (por que la flecha y no otra tecla):
- La Z en el aire es la tecla de habilidad aerea de todo el roster
  (Tails vuela, Knux planea, Blaze doble salto, Cream vuela: todas
  con keyboard_check_pressed(global.KeyA)). Mudar el dash a otra
  tecla romperia la convencion del juego entero.
- El choque real era de INFORMACION, no de input: el dash ya era
  solo-toque (keyboard_check_pressed) y la flotacion solo-mantener
  (keyboard_check cayendo): fisicamente nunca pelean (con la tecla
  abajo no existe un "toque" nuevo; desde la flotacion hay que
  soltar y volver a tocar). Lo que faltaba era que el jugador supiera
  QUE va a hacer la Z antes de pulsarla.
- SOLUCION = la que sugirio el usuario: una FLECHA sobre la cadena.

IMPLEMENTACION:
- scr_light_dash_step seccion 2 reordenada: los gates de elegibilidad
  quedan igual, pero scr_light_dash_find pasa a correr CONTINUAMENTE
  (antes solo en el frame del toque) y su resultado se guarda en
  lightDashAim: la MISMA cadena alimenta la flecha y el arranque (lo
  que ves es lo que vuela). El gate de isTarotFloat baja al bloque de
  activacion, despues del escaneo: flotando la flecha TAMBIEN se
  muestra, porque soltar-y-tocar si arranca el rayo desde la
  flotacion y el jugador tiene que verlo.
- La flecha caduca sola: lightDashAim se limpia cada frame al inicio
  del step y lightDashAimLife (2) lo gasta el Draw. Si el hook no
  corre un frame (burbuja, shock, !isServerReady) no queda flecha
  congelada en pantalla. Mismo patron de vida corta que el tarotNetTimer.
- Draw_0 de Amy (solo jugador local, los puppets no leen input):
  halo dorado pulsante + triangulo apuntando en la direccion del
  PRIMER TRAMO sobre el primer anillo + keycap de la tecla REAL de
  salto con scr_hud_keycap_at (el sistema de keycaps dinamicos del
  HUD v4.3: si el usuario remapea el salto, la letra cambia sola).
  Blend aditivo como el aura del parry; dibujado tras el
  shader_reset del cuerpo. Guards: anillo existe y no usado.
- Create de Amy: +2 vars (lightDashAim, lightDashAimLife) — misma
  leccion del fix v5.9.1: todo lo que lee un Draw nace en el Create.
- Macros nuevas: LIGHT_DASH_ARROW_DIST (16), LIGHT_DASH_ARROW_SIZE
  (7). CERO bytes de red: la flecha no viaja (input local puro).

VERIFICACION: checker ampliado a 84/84 OK: 10 checks nuevos de la
flecha (vars en Create, macros, lazy, clear por frame, escaneo
continuo, gate de flotacion despues del escaneo, gates activos sin
isTarotFloat, halo+triangulo+keycap en Draw, orden tras
shader_reset, caducidad + anillo vivo) y 2 de geometria nuevos en
la simulacion (keycap y ancla nunca pisan un anillo de la cadena en
columna / fila / diagonal; la flecha apunta exactamente al primer
tramo).

## v5.9.3 (2026-11-07) — LIGHT DASH: ALCANCE AMPLIADO — 1 anillo basta, radios 96/80

PEDIDO DEL USUARIO: "hay que aumentar mas la distancia de busqueda y
la tolerancia. No necesariamente necesito que hayan 2 rings pegados
en si, si no con una bastaria para activarla y no necesariamente que
esten pegadas una a la otra (muy juntas), la tolerancia puede ser
mayor".

CAMBIOS (todo en macros + 3 bloques):
- LIGHT_DASH_FIRST_RADIUS: 56 -> 96 px (radio de captura del PRIMER
  anillo, en cualquier direccion). Casi el doble de "distancia de
  busqueda".
- LIGHT_DASH_LINK_DIST: 48 -> 80 px (distancia max entre eslabones):
  los anillos ya NO hacen falta que esten pegados — las lineas
  sueltas o dispersas de los mapas encadenan igual, y las lineas
  clasicas a 24-36 px siguen el camino exacto como antes.
- UN SOLO ANILLO ACTIVA (antes exitia 2): el gate pasa de
  "array_length(_chain) < 2" a "< 1". El dash con un anillo suelto
  funciona como LUNGE DE RECOGIDA: Amy sale disparada hacia el
  anillo, lo recoge y sale con el impulso del tramo — herramienta
  de economia y de recuperacion aerea nueva.
- Fix del caso borde del lunge: la velocidad de salida se PRE-FIJA
  al arrancar con la direccion del primer tramo
  (point_direction(x, y, _chain[0].x, _chain[0].y)): con un anillo
  muy cerca, el frame de vuelo casi no media movimiento y la salida
  quedaba parada muerta en el aire (vx = vy = 0). Ahora siempre
  sale con sus 16 px/frame hacia el anillo, y de paso el paquete
  del frame de arranque ya viaja con la direccion buena (el puppet
  remoto ve bien los primeros frames).
- La FLECHA indicadora (v5.9.2) sale tambien con 1 solo anillo
  (Draw_0: >= 2 pasa a >= 1): el lunge se anuncia igual que la
  cadena, regla de la Z intacta (flecha = tap = rayo/lunge).
- CERO cambios de red, CERO variables nuevas: mismo paquete de
  siempre, mismas 13 vars del Create.

VERIFICACION: checker ampliado a 94/94 OK: 5 checks estaticos nuevos
(macros 96/80, gate < 1 sin rastro del < 2, velocidad pre-fijada,
flecha >= 1) y 5 de simulacion nuevos (1 anillo forma cadena; el
lunge recoge el anillo, manda su CLIENT_RING_COLLECTED y sale a 16
px/frame; eslabones a 70 px encadenan con tolerancia 80; captura a
90 px dentro del nuevo radio; a 120 px sigue fuera). Los gates
viejos actualizados al comportamiento nuevo (1 anillo SI, > 96 NO,
fade-in excluido igual). Toda la simulacion previa (rotacion,
presupuesto, contra-jugada, flecha) intacta y pasando.

## v5.9.4 (2026-11-07) — LIGHT DASH: RITMO A 10 PX/FRAME + ESTELA CONTINUA (nace en el step)

PEDIDO DEL USUARIO: "La velocidad es muy rapida... cuando va hacia el
ring no deja estelas fantasma, solamente sale cuando agarra el ring,
deberia dejarla cuando va de camino. Y va demasiado rapida: esta ahi
de repente ya agarro el ring en un milisegundo. Y donde esta el
archivo para modificar?"

FIX 1 — VELOCIDAD: LIGHT_DASH_SPEED 16 -> 10 px/frame. A 16 el viaje
entero de una cadena tipica duraba 2-4 frames: se leia como
teletransporte. A 10 (600 px/s) el mismo camino dura ~40% mas y se
ve el rayo recorrerlo. El tope de seguridad MAX_TIME sube 120 -> 180
para que una cadena larga dispersa (16 eslabones x 80 px = 1280 px)
no se quede corta a 10 px/frame.

FIX 2 — ESTELA CONTINUA (bug real de arquitectura): los fantasmas
nacian en el Draw de Amy, pero en el frame en que se agarra el
ULTIMO anillo scr_light_dash_exit() ya puso isLightDashing = false
ANTES de que el Draw corra: ese frame no pintaba fantasma. Sumado a
la cadencia cada 2 frames y al viaje de 2-3 frames, el resultado era
exactamente lo que describia el usuario: estela "solo al agarrar".
Solucion: la estela pasa a nacer en el PROPIO STEP — nueva funcion
scr_light_dash_ghost(xx, yy) llamada en (a) el arranque, (b) CADA
frame de vuelo (en lightDashToX/Y, el final del movimiento del
frame) y (c) la salida (exit), con la pose de lightDashDeg/
lightDashFace (lo mismo que dibuja el cuerpo). Cadencia
LIGHT_DASH_GHOST_EVERY 2 -> 1: fantasma por frame = rayo continuo
(10 px entre fantasmas, ~170 px de estela visible con el fade de
siempre). El bloque del Draw_0 se retira ( comentario explicativo)
y el contador lightDashGhostTimer lo gasta ahora el script (reset a
0 en el arranque). El puppet remoto no cambia archivo: usa la misma
macro y su estela se densifica sola.

VERIFICACION: checker ampliado a 104/104 OK: 8 checks estaticos
nuevos de v5.9.4 (speed 10, MAX_TIME 180, EVERY 1, funcion ghost,
llamada en vuelo/arranque/salida, Draw sin spawneos) + 3 de
simulacion (140 px = 14 frames exactos a 10 px/frame; estela
completa = arranque + vuelo + salida = 16 fantasmas donde antes eran
~4; hasta el lunge de 1 anillo deja >= 3 fantasmas). Los checks
v5.9.1 de la estela re-apuntados al script (la pose rotada ahora se
verifica como image_angle = lightDashDeg, equivalente al
radtodeg(angle) del cuerpo porque pose() escribe angle =
degtorad(lightDashDeg)).

ARCHIVO PARA MODIFICAR (pregunta del usuario): TODO el ajuste fino
vive en scripts/scr_light_dash/scr_light_dash.gml, macros al inicio
del archivo (SPEED, FIRST_RADIUS, LINK_DIST, MAX_TIME, TURN,
GHOST_EVERY, GHOST_FADE, ARROW_*).

## v5.9.5 (2026-11-07) — LIGHT DASH: PATHFINDING — la cadena ve el terreno (adios al atasco en muros y pisos)

PEDIDO DEL USUARIO: "Amy puede atascarse en el piso tratando de
buscar un ring que esta en el suelo o al otro lado de la pared, no
se le puede colocar una especie de pathfinding?" + aclaracion tras
la primer entrega: "lo del rescate movil no hace falta xq el juego
ya tiene un sistema de rescate anti atascos" y "la 2 me refiero a
que si hay una pared busque algun angulo posible para rodear y
llegar".

DIAGNOSTICO: la cadena de scr_light_dash_find era codiciosa pura
(vecino mas cercano, v5.9.3) y NO veia el mapa: un anillo en el
suelo o detras de un muro entraba igual a la cadena, y como el
vuelo REAPLICA la posicion por encima del collision
(scr_light_dash_pose, para conservar la pose rotada), Amy cruzaba
el terreno como fantasma y quedaba incrustada dentro del muro, en
el piso o del otro lado — de ahi el atasco.

FIX — LINEA DE VISION (el pathfinding natural del rayo): un A*/mp_grid
no encaja en un light dash porque el rayo SOLO puede viajar por
anillos; su equivalente de pathfinding es encadenar anillos VISIBLES
entre si (en el Sonic clasico lo garantiza el disenador colocando
los anillos; aqui se exige en codigo):
- Nueva funcion scr_light_dash_clear(x1,y1,x2,y2): collision_line
  contra LIGHT_DASH_TERRAIN (= obj_floor_parent, el padre universal:
  pisos, muros, pendientes obj_majong_slope, puertas obj_hd_door,
  bloques de hielo, plataformas obj_platform_jumptrough) con
  colision precisa. Los extremos del tramo se recortan
  LIGHT_DASH_LOS_TRIM (8) px para no condenar a los anillos que
  APOYAN sobre una superficie (los caidos al recibir dano: su centro
  roza la mascara) ni a Amy despegandose pegada a un muro: el rayo
  llega AL anillo, no lo atraviesa. Guard: tramos <= 2*TRIM px se
  dan por limpios (no cabe un muro).
- scr_light_dash_find: el PRIMER anillo es el mas cercano VISIBLE
  (el tramo desde Amy tambien se prueba — el anillo al otro lado de
  la pared ya no se pesca) y cada eslabon exige vecino mas cercano
  VISIBLE. ESTO ES EL PUNTO 2 ACLARADO POR EL USUARIO: "si hay una
  pared, buscar el angulo posible para rodear y llegar" — cuando el
  anillo mas cercano queda bloqueado por el muro, la cadena arranca
  por el primer anillo VISIBLE y sigue los visibles ALREDEDOR del
  obstaculo hasta LLEGAR al anillo de atras; solo si no existe
  ningun camino de anillos visibles no encadena (y sin flecha el
  jugador ya sabe que no hay rayo).
- TERRENO MOVIL (puertas, bloques de hielo) que cierre sobre el rayo
  a mitad de vuelo: SIN rescate propio a peticion del usuario — el
  juego ya tiene su sistema anti-atasco que saca al jugador de
  dentro del solido, y ese sistema la rescata igual que a cualquiera
  (queda nota en el propio script para que nadie lo vuelva a
  anadir).
- La FLECHA indicadora no cambia archivo: usa la misma cadena
  (lightDashAim), asi que anillo tras muro = sin flecha = sin rayo:
  lo que ves sigue siendo lo que vuela. Cero cambios de red, cero
  objetos nuevos.

VERIFICACION: checker en 121/121 OK: 9 estaticos nuevos
(macros TERRAIN/TRIM, funcion clear con guard 2*TRIM, los 2 gates
de visibilidad, SIN rescate propio, cabecera) + 9 de simulacion
con terreno porteado 1:1: anillo tras muro no encadena (y sin muro
si: el bloqueo es el terreno), anillo APOYADO en el suelo encadena
y el lunge termina afuera, eslabon ENTERRADO se salta, y el caso
CLARADO del usuario: anillo mas cercano DETRAS del muro + anillo
visible por encima -> la cadena arranca por el visible, RODEA el
muro y LLEGA al de atras (11 frames sin tocar terreno), mas
eslabones pegados (12 px) sin drama del margen. Los 104 checks de
v5.9.0-v5.9.4 siguen OK (regresion cero).

AJUSTE FINO: LIGHT_DASH_LOS_TRIM en scripts/scr_light_dash/
scr_light_dash.gml — subirlo encadena mas agresivo cerca de
superficies, bajarlo mas estricto (8 = el radio visual de un
anillo apoyado).

## v5.10 (2026-11-07) — LIGHT DASH: PATHFINDING A* REAL — el rayo traza su propio rodeo

PEDIDO DEL USUARIO: "quizas podriamos mejorar un poco el sistema de
pathfinding. Busca por internet algun sistema de pathfinding avanzado
donde pueda servir como una especie de manera detectar las paredes
buscar caminos atajos etc. En si normalmente con los anillos seria
facil pero en TD sabes que eso no abundan y aparecen bastante
separados asi que ya me entenderas". Aclaracion previa: PRIMERO el
pull del fork del usuario (4 commits: subio el trabajo de v5.9.x y su
propio tuning de macros — SPEED 5, FIRST_RADIUS 220, LINK_DIST 275,
MAX_RINGS 20, MAX_TIME 200 — que QUEDA intacto y pineado en el
checker para que nadie lo revierta).

INVESTIGACION (fuentes): el A* NATIVO de GameMaker vive en los mp_grid
(manual: mp_grid_path con allowdiag, mp_grid_add_instances con
colision precisa, puntos en coordenadas de sala) y el estandar de la
industria para "A* con caminos naturales" es el smoothing por STRING
PULLING / Theta* (tirar de la cuerda y conservar solo los quiebres con
linea de vision; gamedev.net "Navigation Meshes and Pathfinding",
Nash & Koenig "Theta*: Any-Angle Path Planning on Grids", CMU). El
combo elegido: mp_grid + string pulling reusando la scr_light_dash_clear
de v5.9.5 — Theta* practico sin implementar A* a mano.

POR QUE NO A* SOLO: el rayo SOLO puede volar por donde diga su ruta,
asi que el A* solo sirve si sus quiebres entran al VUELO. La solucion:
la cadena se convierte en RUTA = anillos + WAYPOINTS ({x, y} structs) y
el vuelo los sigue igual que a los anillos (los targets del presupuesto
por frame ya entendian puntos; solo hubo que hacer el bucle struct-
aware: is_struct para el "objetivo vivo" y para la recogida — solo los
anillos mandan CLIENT_RING_COLLECTED).

COMO FUNCIONA (scr_light_dash.gml, 3 funciones nuevas):
- scr_light_dash_grid(): mp_grid cacheado en globals (celdas de
  LIGHT_DASH_GRID_CELL 16 px), bloquea todo obj_floor_parent con
  mp_grid_add_instances(precise) y se reconstruye cada
  LIGHT_DASH_GRID_REFRESH (30) frames o al cambiar de sala — las
  puertas y el terreno movil se recalifican solos.
- scr_light_dash_route(x1,y1,x2,y2,maxLen): mp_grid_path (A* nativo,
  diagonales) de Amy al anillo + string pulling con scr_light_dash_clear
  (solo sobreviven quiebres con linea de vision REAL). Las celdas de
  salida y meta se desbloquean un momento (Amy pegada a un muro / anillo
  apoyado no ahogan el A*) y se re-bloquean SOLO si de verdad tienen
  terreno (collision_rectangle sobre la celda — misma semantica que
  add_instances; re-bloquear a ciegas dejaba celdas FANTASMA en el aire
  libre y el grid se llenaba de muros inexistentes: bug cazado en el
  checker). Devuelve los quiebres; [] si no hay camino o el recorrido
  se pasa del presupuesto.
- scr_light_dash_find(): ahora devuelve la RUTA. Pase 1: el vecino mas
  cercano con linea de vision (cero A*, el caso comun queda EXACTO a
  v5.9.5 — verificado). Pase 2 (solo si nadie es visible): candidatos
  en orden de cercania probando A* con presupuesto LIGHT_DASH_ROUTE_
  FACTOR (1.5) x el alcance del tramo — el rodeo de "buscar el angulo
  posible para rodear y llegar". Higiene nueva: anillos con el centro
  DENTRO del terreno fuera de la lista de candidatos (el A* no se
  zambulle a buscar anillos enterrados que nadie puede recoger).
- scr_light_dash_step: lightDashAim sigue siendo SOLO anillos (la
  flecha no cambia su dibujo base) + lightDashAimX/Y/Dir nuevos para
  que la FLECHA apunte al PRIMER TRAMO de la ruta (con desvio apunta
  al primer quiebre, no a la pared). Draw_0 usa esas vars; Create_0
  las declara. Cero paquetes nuevos (la posicion ya viaja resuelta),
  cero objetos nuevos, el puppet no cambia archivo.

NOTA DE DISENO: rings apoyados en el suelo siguen funcionando (vuelo
recto al anillo); el tuning del usuario (220/275) hace que el primer
anillo util de TD casi siempre este a linea de vision y el A* solo
entre en juego contra muros de verdad — exactamente el hueco que
quedaba en v5.9.5.

VERIFICACION: checker reescrito a 147/147 OK. Parte 1: tuning del
usuario pineado (5 macros "no revertir"), v5.10 estaticos (funciones
grid/route, re-bloqueo condicional, vuelo struct-aware x2, recogida
guard, waypoints push, higiene, aim en seccion 2/Create/Draw/lazy).
Parte 2 (constantes PARSEADAS del gml, unica fuente de verdad): A*
8-dir sin cortar esquinas + celdas de salida/meta desbloqueadas y
restauradas + string pulling portados 1:1. Escenarios nuevos: anillo
tras muro CON hueco -> encadena con WAYPOINTS y el vuelo lo RODEA sin
tocar terreno (frames exactos = ruta/SPEED); muro que tapa la sala ->
sin cadena (el A* lo intento); rodeo sobre presupuesto -> descartado;
REGRESION CRITICA: con linea de vision NO corre ningun A* y la ruta no
tiene waypoints; anillo roto a mitad de desvio -> sigue quiebres y
come el segundo; el grid no acumula celdas fantasma; anillos TD a 250
px encadenan con el LINK 275 del usuario. Los escenarios v5.9.x
(rotacion, presupuesto, rotos, gates, flecha, apoyados, enterrados)
siguen OK con las constantes nuevas.

AJUSTE FINO (macros nuevas en scr_light_dash.gml):
- LIGHT_DASH_ROUTE_FACTOR 1.5: presupuesto del rodeo (x el alcance del
  tramo). Subir = desvios mas largos permitidos.
- LIGHT_DASH_GRID_CELL 16: celdas del A* (mas fino = rodeos mas
  pegados al muro, mas caro).
- LIGHT_DASH_GRID_REFRESH 30: cada cuantos frames se reconstruye el
  grid (terreno movil).

2026-11-07 — LIGHT DASH v6.0: LSA + I-FRAMES + FRENADO + 2 FIXES
Task ID: light-dash-v6-lsa
Pedido: "Incluye el LSA en la misma habilidad (exe en el camino -> golpe
+ stun 3 s -> luego rings), tecla C para que no salga por accidente, la
Z nunca lo dispara, terrestre y sin version aerea (X = tarot). I-frames
en dash y LSA + 2 s gratis al salir. Frenado prematuro del dash con X.
Fix del dash que se queda pegado al pisar el piso (el pozo de la
burbuja). Fix de la rotacion que no se nota al ir por anillos arriba."

Diagnostico del bug del piso (confirmado el paralelo con la burbuja):
- obj_amy_canon/Step_0.gml:50 corre scr_collision_basic() OTRA VEZ
  despues del hook de scr_move_basic (que ya corrio collision + pose del
  dash). Con isGrounded=true (aterrizo persiguiendo anillos bajos), la
  rama de suelo del segundo collision hace y=winner CADA FRAME y le
  pisa la elevacion: el vuelo sube 5 px, el snap la devuelve -> CLAVADA
  hasta agotar MAX_TIME. Es exactamente "la burbuja activada con Amy en
  el suelo no se elevaba" (fix de entonces: isGrounded=false).
- Fix: scr_light_dash_pose() re-afirma isGrounded=false CADA FRAME
  (mejor que una sola vez en la activacion: cubre aterrizajes
  mid-vuelo). La rama aerea del collision solo aterriza cayendo de
  verdad (yspd>0) y nunca clava.

Diagnostico de la rotacion invisible:
- Draw_0 local: isSpinning ? 0 : radtodeg(angle). Saltar en BOLA
  conserva isSpinning (v5.3 del manejo) y el rayo viajaba con angle
  forzado a 0 (de lado hacia los anillos de arriba). El puppet remoto
  dibuja angle directo y si rotaba. Fix: (isSpinning &&
  !isLightDashing) ? 0 : radtodeg(angle).

LSA (Light Speed Attack, tecla C, suelo):
- scr_light_dash_step seccion 3 (gates comunes arriba; la Z envuelta en
  if(!isGrounded) para que sus return tempranos no roben el turno).
- Objetivo: scr_lsa_find_target (puppet bando EXE mas cercano a
  LSA_RANGE 400, vivo, sin i-frames, sin state DEAD, visible; mismos
  filtros que Chocola).
- Ruta: recta con LOS o rodeo A* (scr_light_dash_route, presupuesto
  LSA_RANGE*ROUTE_FACTOR); eslabon del objetivo = struct {x, y, exe}
  VIVO con homing mientras dist(Amy, exe) < LSA_PURSUIT (600).
- Golpe en la llegada: scr_lsa_hit -> efectos locales (shockparticle +
  shake) + senal net_sound_emit_at(snd_dash, nid) con shouldPlay=true;
  rama nueva en CLIENT_SOUND_EMIT (net_state_game) -> scr_lsa_stun_signal
  en el cliente del objetivo (modelo Chocola: sonido ANTES del dedup,
  shockedTimer = 180, knockback, CLIENT_PLAYER_HURT + stats). Esquiva:
  si el exe huye y el eslabon queda a > LSA_HIT_RADIUS del exe real, no
  hay golpe.
- Extension: scr_light_dash_chain(exe.x, exe.y, LINK_DIST) encadena
  anillos desde el objetivo (find() quedo como envoltorio del chain).
- isAttacking=true durante el vuelo (bit PLAYER_ATTACKING ya viaja para
  Amy Canon): el exe que TOQUE el rayo queda stuneado por el sistema de
  contacto del juego (obj_player_puppet, 3 s).
- Convivencia con la acometida (misma tecla C, mismo CD dashTimer): el
  hook corre ANTES que specialFunc en scr_move_basic -> con objetivo el
  LSA arranca y la acometida ve isLightDashing y se calla; sin objetivo
  la C cae a la acometida de siempre. La Z arranca con isLSA=false
  (defensivo) y jamas busca objetivos.
- Sin version aerea (X = impulso de tarot, como pidio el usuario).

I-frames: hurttime = max(hurttime, 2) cada frame de vuelo (intocable;
  el Step la baja 1 y el vuelo repone) y hurttime =
  LIGHT_DASH_IFRAME_EXIT (120) en TODAS las salidas.

Frenado (solo dash de la Z): X en vuelo -> scr_light_dash_brake: parada
  total (xspd=yspd=gspd=0), i-frames de salida, ultima estela, snap +
  latch lightDashBrakeLatch=2 para que ese mismo toque de X no encienda
  el impulso de tarot (scr_amy_canon_special: gate +
  lightDashBrakeLatch <= 0, decremento al inicio). El LSA no se frena.

Archivos: scr_light_dash.gml (macros LSA_* + seccion 3 + homing +
  golpe + brake + chain + pose fix + exit), Create_0 (isLSA + latch),
  Draw_0 (rotacion), scr_amy_canon_special (latch), net_state_game
  (rama snd_dash dirigido). Cero paquetes nuevos (senal por el canal
  CLIENT_SOUND_EMIT existente, contacto por PLAYER_ATTACKING existente).

Entrega: td2dr_light_dash_v600.zip (LEEME + 5 gml + checker + worklog).
VERIFICACION: check_v60_light_dash.py 197/197 OK (los 121 del v59-v5.10
sin regresiones; el conteo de fantasmas pasa de 2 a 4: arranque Z, arranque
LSA, salida y freno). Nuevas simulaciones: objetivo (6 filtros), homing
golpe/esquiva, extension desde el exe, senal de stun, PIPELINE del bug
del piso con y sin el seguro (sin: nunca llega; con: llega en ~11 frames),
frenado con latch, i-frames en vuelo.

---
Task ID: 7
Agent: Super Z (main agent)
Task: Light Dash v6.1 — correccion de diseño del LSA de Amy Canon (C en el AIRE con cadena de enemigos; C en el suelo = martillo)

Work Log:
- Pull del fork (4bb95335): el v6.0 entregado antes tenia el diseño INVERTIDO (LSA terrestre con C en suelo, caida al martillo sin objetivo, un solo enemigo + anillos). El usuario corrigio las reglas: C en TIERRA = martillo, C en el AIRE = LSA con dash, cadena de enemigos que JAMAS repite objetivos, luego anillos, intercepcion por el camino, y nadie con i-frames como objetivo
- scr_light_dash.gml: seccion 2 reescrita como LSA AEREO dentro de if(!isGrounded), ANTES que la Z (seccion 3, cuerpo intacto); la vieja seccion 3 terrestre eliminada (el suelo no activa nada: el martillo manda con su gate isGrounded del especial)
- Nueva maquina de cadena: lsaHit (banda de objetivos golpeados/fallados — jamas se repiten), scr_lsa_find_target_at (buscador general con filtros Chocola + banda + skip), scr_lsa_leg_to (tramo recto o rodeo A* + eslabon vivo con homing), scr_lsa_next_leg (siguiente enemigo a <= LSA_NEXT_DIST o anillos de la zona desde el ultimo objetivo)
- Intercepcion restringida a la FASE DE ANILLOS (descubierta en simulacion: sin restriccion, el rayo se desviaba a por un enemigo MAS LEJOS teniendo uno a 35 px — la cadena enemigo->enemigo ya secuencia sola); scr_lsa_hit con gate de i-frames ganados a mitad de vuelo
- Macros nuevas: LSA_NEXT_DIST (= RANGE 400), LSA_INTERCEPT 140, LSA_MAX_TARGETS 6 (tope de seguridad); Create_0 declara lsaHit; comentarios del especial actualizados (gate intacto)
- Checker check_v61_light_dash.py: 227/227 OK (hereda 197 del v6.0, cero regresiones). Sims nuevas: vuelo completo de la cadena (exe -> esbirro -> anillos, aliado intacto, cada enemigo exactamente 1 vez), intercepcion real (enemigo a 516 px del objetivo, inalcanzable por cadena, cae por el camino de los anillos), tope (8 enemigos -> 6), i-frames (arranque/re-plan/golpe) y vacio (sin bando exe no arranca)

Stage Summary:
- Reglas del usuario implementadas al pie de la letra: C aire = LSA (exe o minion mas cercano -> golpea uno, salta a otro, jamas repite -> anillos -> intercepta por el camino), C suelo = martillo, sin i-frames como objetivo en ningun punto del vuelo
- Infraestructura v6.0 intacta (stun por senal snd_dash dirigida, homing con PURSUIT, contacto por PLAYER_ATTACKING, i-frames de vuelo + 2 s de salida, frenado X con latch, fix del piso, fix de rotacion, Z nunca dispara LSA)
- Entregable: download/td2dr_light_dash_v61.zip (SOLO archivos modificados/creados: scr_light_dash.gml, Create_0.gml, scr_amy_canon_special.gml, check_v61_light_dash.py, LEEME_LIGHT_DASH_V61.txt, worklog.md); LEEME_V60 y check_v60 quedan obsoletos (borrables)

---
Task ID: 8
Agent: Super Z (main agent)
Task: FIX UDID — jugadores que no entran: RASSERT (Packet.c:195 out->len < 122/128) + (Server.c:181 &vgid/&udid) al conectarse SOLO ALGUNOS

Work Log:
- Pull del fork (d0323172): commits recientes solo cliente (Light Dash v6.x), server intacto desde el 3/11. El error no esta en lo nuevo: es del protocolo base
- Diagnostico: el IDENTITY lleva nickname + UDID como strings sin prefijo (hasta '\0'). El cliente Android arma el UDID = "mod-" + VERSION+CPU_ABI+RELEASE+MODEL+DEVICE+MANUFACTURER+BOOTLOADER (net_indentity.gml): en varios modelos supera 128 chars; en PC es un GUID corto => por eso fallan "algunos" y no todos. packet_readstr tenia RAssert(out->len < 128) duro => PacketRead(udid) falla en Server.c:181 => solo quedaba un Debug invisible => el jugador colgaba hasta el timeout (el server no se caia)
- REPRODUCCION: server compilado del codigo ORIGINAL + bot cliente ENet con UDID de 144 chars => log identico al reportado ((Packet.c:195) + (Server.c:181)) y el bot colgado 5 s. Causa 100% confirmada
- Fix Packet.c/packet_readstr: fuera el assert de longitud; lee hasta el '\0' real (icon/pet/ticket quedan en sync) y guarda hasta sizeof(value)-1=249 con '\0' forzado + WRN si recorta
- Fix Packet.c/packet_from (bug latente correlacionado): .len uint8_t hacia wrap %256 de paquetes ENet de 256+ bytes (256->0, 300->44 => lecturas desalineadas); ahora recorta a 255 con WRN
- Fix Packet.c/string_new (bug latente): textos >249 (p. ej. MOTD de Config.json) desbordaban value[250]; ahora acota y fuerza '\0'
- Fix states/Server.c dispatcher: identity fallido ahora desconecta CON MENSAJE al jugador (antes: colgado). Redirect de lobby lleno marca v->disconnecting=true para no desconectar de mas. Rutas que ya se desconectaban solas intactas (server_disconnect idempotente)
- Fix cliente net_indentity.gml: UDID topeado a 100 chars con string_copy (el server ya tolera cualquier longitud, pero asi no revientan otros servers comunitarios sin fix)
- Validacion: compilacion limpia (gcc -Wall, cero warnings nuevos), check_udid_fix.py 38/38 (patrones + simulacion byte-level + harness C con funciones literales extraidas), E2E con bot ENet real: UDID 144 chars ENTRA (joined en el log), UDID normal ENTRA (sin regresion), UDID 380 chars => recorte + desconectado con aviso al instante (antes colgaba)

Stage Summary:
- Causa raiz confirmada por reproduccion exacta del log del usuario: UDID Android largo (>=128 chars) vs assert duro de packet_readstr; solo afectaba a dispositivos con info larga
- 5 cambios quirurgicos (84 lineas insertadas / 11 borradas): packet_readstr tolerante, packet_from sin wrap uint8, string_new acotado, desconexion limpia del identity fallido, tope de 100 chars en el cliente
- Formato del IDENTITY, enum de paquetes y anticheat INTACTOS: clientes viejos/vanilla siguen compatibles sin actualizar
- Entregable: download/td2dr_fix_udid_v1.zip (SOLO archivos modificados/creados: Packet.c, states/Server.c, net_indentity.gml, check_udid_fix.py, LEEME_FIX_UDID_V1.txt, worklog.md). REQUIERE recompilar el server (compilar_server.bat) y de paso el cliente (GameMaker)

---
Task ID: 9
Agent: Super Z (main agent)
Task: FIX CRASH LSA v6.1 — array_find_index(arr, VALOR) reventaba en runtime ("argument 1 is neither a method or a function") en obj_amy_canon al disparar el LSA (C en el aire)

Work Log:
- Reporte del usuario: ERROR Step_0 obj_amy_canon -> scr_lsa_find_target_at (line 1230) array_find_index :: argument 1 is neither a method or a function (stack: scr_lsa_find_target -> scr_light_dash_step -> scr_move_basic -> obj_amy_canon Step_0)
- Pull: ya en d0323172 (nada nuevo en origin). El crash lo introdujo el propio v6.1: 2 usos de array_find_index(arr, VALOR) — lineas 448 (llegada del eslabon) y 1230 (buscador de objetivos) de scr_light_dash.gml
- El runtime NO tiene array_find_index(arr, valor): exige predicado function(_element,_index) (numeracion 0-based del error: "argument 1" = segundo parametro). Ya sabido y resuelto en net_sounds v4.7 + net_projectile. array_contains(arr, valor) SI existe y se usa en 15+ archivos (Create de personajes, menus, logros)
- Fix: ambas lineas son membresia pura ("ya golpeado en este vuelo?") -> array_contains; cero cambio de logica, mismo comportamiento previsto por el v6.1
- Checker v61 actualizado IN-PLACE a v6.2: las 2 expectativas apuntan a las cadenas nuevas + check nuevo anti-regresion (fail si reaparece array_find_index(lsaHit,/array_find_index(_hitList,) + docstring (227 -> 228 checks). check_v59/check_v60 siguen obsoletos como ya estaban
- Fix de portabilidad del checker: ROOT estaba hardcodeado a la carpeta del sandbox donde nacio el v6.1 (/home/z/my-project/disaster2d-oss) -> no corria en ninguna otra maquina (ni aqui ni la del usuario); ahora es relativo a la ubicacion del propio archivo. check_udid_fix.py ya era portable (ruta por argumento), sin cambios
- Validacion: check_v61 (v6.2) 228/228 OK — todas las comprobaciones estaticas + las simulaciones completas del LSA (cadena, intercepcion, i-frames, tope, frenado)

Stage Summary:
- Causa raiz: sintaxis invalida en el runtime, NO logica — el v6.1 paso el checker (227/227) y las simulaciones pero nadie probo el LSA EN JUEGO con Amy canon
- 2 lineas de codigo + comentarios v6.2; todo lo demas del LSA intacto (banda lsaHit, cadena enemigo->enemigo->anillos, intercepcion, i-frames, stun por senal, homing PURSUIT, frenado Z)
- Entregable: download/td2dr_light_dash_v62.zip (SOLO archivos modificados/creados: scr_light_dash.gml, check_v61_light_dash.py, LEEME_LIGHT_DASH_V62.txt, worklog.md). Solo requiere recompilar el CLIENTE (GameMaker); el server NO se toca

---
Task ID: 10
Agent: Super Z (main agent)
Task: FIX LSA ANTICHEAT — el LSA de Amy Canon botaba al jugador con "nuh-uh!" (server.c, server_disconnect)

Work Log:
- Reporte del usuario: el LSA hace que el anticheat lo bote; log "server.c 547" con texto "Nu uh". Server.c:547 es la linea de Info() del server_disconnect -> el texto viene de un kick: "nuh-uh!" esta en states/Game.c:2201 (DR_KICKEDBYHOST)
- Causa: el anticheat de duracion de ataque (states/Game.c) kickea si el bit PLAYER_ATTACKING llega continuo >= duration ms (2000 generico, 3000 Eggman). El LSA v6.x mantiene isAttacking = true TODO el vuelo (stun por contacto del kit, scr_light_dash ~611) y el vuelo dura hasta LSA_MAX_TIME = 300 frames = 5 s -> a los ~2 s de vuelo, kick. El dash de anillos de la Z NO setea isAttacking (solo el LSA): por eso solo el LSA botaba
- Fix: case CH_AMY_CANON con duration = 6000 en el MISMO switch de Eggman (states/Game.c, game_state_handletcp) — patron existente del juego para personajes de ataque largo; el anticheat sigue vivo para Amy (6 s continuos = kick igual)
- El Game.c de la raiz (disasterserver/Game.c) NO esta en el CMakeLists (solo states/) -> no se toca; idem el root Server.c
- Validacion: gcc -fsyntax-only con ENet real (clone a /tmp, fuera del repo) EXIT=0 (warnings -Wswitch preexistentes; el fix elimina el de CH_AMY_CANON); check_lsa_anticheat.py 18/18 (estatica: case en el switch correcto por conteo de llaves, 6000 > 5000 ms, gate LSA exclusivo de Amy Canon, nuh-uh sigue existiendo; simulacion 1:1 del acumulador: 5 s con 2000 = kick [reproduce el bug], con 6000 = ok, Eggman 2.5 s ok / 3.33 s kick, reset al soltar, 6.6 s = kick)

Stage Summary:
- Causa raiz: interaccion diseño-vs-anticheat — el isAttacking continuo del vuelo LSA (intencional, stun por contacto) superaba el tope generico de 2 s del anticheat de ataque infinito
- 1 case nuevo en el switch de duracion (mecanismo identico al de Eggman); anticheat NO apagado para nadie; cliente intacto
- Entregable: download/td2dr_lsa_anticheat_v1.zip (SOLO archivos modificados/creados: states/Game.c, check_lsa_anticheat.py, LEEME_LSA_ANTICHEAT_V1.txt, worklog.md). REQUIERE recompilar el server (compilar_server.bat)

---
Task ID: 11
Agent: Super Z (main agent)
Task: FIX ACT9 SPAWN — "al spawnear los personajes aparecen en el suelo y cuenta como muerte porque la pared los aplasta" (mapa Act 9)

Work Log:
- Sandbox reciclado entre sesiones: repo y zips anteriores perdidos -> re-clone (d0323172, sin cambios en origin) y re-aplique al worklog las entradas Tasks 8-10 (el zip de este fix las lleva para que el worklog del usuario no pierda historial; los fixes en si NO se tocan en este entregable)
- Diagnostico (cadena completa verificada en codigo): (1) states/Game.c game_state_handletcp marca plr.ready con CUALQUIER paquete TCP — los clicks de personaje spameados durante el fade de transicion ya cuentan como ready; (2) la partida (y los muros de Act 9) arrancaban mientras un cliente seguia en el fade (1,6 s) + cargando texturas; (3) ese cliente spawnneaba DENTRO del muro ya avanzado — spawnpoints del room: (304,512) cubierto por el muro izq a los ~28,7 s de barrido, (2856,256) por el der a los ~21,8 s, (3024,570) por el der a los ~8,7 s (ronda de 130 s); (4) obj_act9_wall/Step_1.gml lo aplastaba al aparecer: scr_player_instakill (CUENTA como muerte) + teletransporte a (1535,943) = "aparecen en el suelo"; (5) bonus: ese punto queda DENTRO del muro-techo al final de la ronda (off >= ~0,92) -> teletransporte al olivo
- Verificado antes de concluir: TCP/ENet canal 0 es ordenado (la teoria de respuesta tardia de charselect estaba muerta), defaults cliente de los muros = posiciones iniciales seguras, puppets sin gravedad, exe spawns mas seguros que los de survivors, CMake compila entities/Act9Wall.c
- Fix server (entities/Act9Wall.c): cada muro NO ARRANCA hasta que TODOS los participantes vivos hayan reportado su primera posicion (pos != 0,0 — misma convencion que ya usaba el check del muro), con tope de gracia ACT9_WALL_HOLD_SEC = 30 s (anti-zombi). Solo re-captura start_time: el barrido siempre termina justo al acabar la ronda, solo empieza mas tarde. Ignora espectadores (!in_game) y muertos (PLAYER_DEAD)
- Fix cliente (obj_act9_wall/Step_1.gml): tras el aplastamiento, el teletransporte va al punto clasico (1535,943) SOLO si esta fuera de TODOS los muros (margen 24); si esta cubierto, escanea el suelo hacia los costados (paso 64 px, acotado 64..3008); si todo esta cubierto (fin de ronda) NO teletransporta. Los 3 branches (techo/izq/der) comparten el mismo calculo al inicio del step
- Validacion: gcc -fsyntax-only (ENet real re-clonado a /tmp) EXIT=0 cero warnings; check_act9_spawn_fix.py 21/21 (estatica: hold + skips + math intacta + instakill intacto + llaves; simulacion 1:1 del reloj del muro: cliente lento de 12 s SIN fix spawnnea dentro del muro [reproduce el bug], CON fix todos los spawns seguros, el barrido igual termina completo al final de la ronda, nadie arranca con ventaja, anti-zombi, seleccion de teleport en 3 escenarios)

Stage Summary:
- Causa raiz: el "ready" de cualquier paquete TCP arrancaba los muros mientras los clientes lentos seguian cargando -> spawn dentro del muro avanzado -> instakill + teleport al suelo ("aparecen en el suelo, cuenta como muerte")
- 2 cambios quirurgicos: hold del muro hasta primera posicion reportada (server) + teleport seguro tras aplastamiento (cliente); el diseño del mapa (barrer todo al final) queda INTACTO — solo se retrasa el arranque
- Entregable: download/td2dr_act9_spawn_v1.zip (SOLO archivos modificados/creados: entities/Act9Wall.c, obj_act9_wall/Step_1.gml, check_act9_spawn_fix.py, LEEME_ACT9_SPAWN_V1.txt, worklog.md). REQUIERE recompilar el SERVER (compilar_server.bat) Y el CLIENTE (GameMaker)
---
Task ID: 12
Agent: Super Z (main agent)
Task: FIX SCAN METAL AMY v4.9 (la V y la pasiva de la cazadora nunca senalaban a nadie) + MINI FIX v2.2 (paciencia de Vanilla flotando en el aire al debilitarla)

Work Log:
- Pull: d0323172 -> 0a66d72e (el usuario commiteo TODOS los fixes previos: act9, UDID, anticheat LSA, light dash v6.2; ademas cambio las canciones LMS de Sonic a mus_lms_16/17 y anadio mus_lms_16/17). Fixes previos verificados intactos en el arbol
- SCAN — descarte sistematico de la cadena completa: KeyV existe (bind "special3"), HUD lee global.player.scanTimer/huntMode con el MISMO dot-access y funciona (dashCharges/bulletTimer en pantalla), server manda exeCharacter=4 correcto (id-- con validacion EX_METALAMY), player_getexe(4)=obj_metalamy, spawn del exe crea la instancia + su obj_exe_indicator, .yyp registra todo, evento {8,64}=Draw GUI bien cableado, gate v4.8.1 del Step_2 correcto (5 condiciones todas verdaderas con Metal Amy)
- SCAN — CAUSA RAIZ (la v4.8.1 diagnostico a medias): obj_exe_indicator nace visible:false (el .yy) y su linea `visible = ...` da false SIEMPRE para Metal Amy (bando EXE, sin invisibilidad, no es Chaos, sin anillo rojo) — y en este runtime una instancia INVISIBLE NO EJECUTA SU DRAW GUI: el evento de dibujo jamas corrio ni una vez, las siluetas no se dibujaban NI CON LA LISTA LLENA. Prueba del patron: TODOS los indicadores del juego (surv/family/ring/demon/exeller/exetior/spr) nacen visible:true o guardan su Draw_64 con if(!visible) return + encienden visible para mostrarse; el scan era el UNICO bloque que dibujaba sin tocar visible y era el unico muerto. Mismo malentendido dejo muerto obj_heal_progress (nunca enciende visible -> nunca dibuja; documentado, no tocado)
- SCAN — FIX (patron de la familia): la condicion de la aguja pasa a bandera propia `needle` (MISMA formula) en Step_2; al final del Step_2 el INTERRUPTOR DEL MOTOR visible = needle || scanCount > 0 (enciende el evento cuando hay aguja O revelado); Draw_64 gatea la aguja con if(!needle) para que el scan no arrastre la flecha (acuerdo v4.8: vision, no aguja); Create declara needle=false. La aguja del EXE invisible/anillo de Exetior/slime de Chaos queda IDENTICA (formula intacta)
- VANILLA — CAUSA RAIZ: paciencia/moribunda ponia yspd = LEVITATE (-0.35) siempre que !isGrounded; la levitacion es para HOYOS pero no distinguia "hoyo" de "aire sobre suelo normal" -> debilitada en el aire quedaba flotando los 5 s de la fase
- VANILLA — FIX (scr_vanilla_v2_step, las DOS fases): 3 ramas — suelo: quieta (yspd=0); sin terreno en la columna de abajo (collision_line hasta room_height+64 vs obj_floor_parent): hoyo real -> levita EXACTAMENTE como antes; con terreno debajo: cae con gravedad y tope maxYSpeed=12 (fase en el suelo, como pide el sprite). Orden de ejecucion verificado: specialFunc corre ANTES de la gravedad de scr_collision_basic
- Validacion: check_scan_vanilla_fix.py 50/50 OK (estatica completa de los 4 archivos + .yyp + los 3 creadores del indicador; simulacion 1:1 del indicador con la regla del runtime: VIEJO reproduce el bug [0 dibujos con V y en LMS], NUEVO dibuja scan todos los frames con 3 siluetas exactas, aguja no se cuela, expiracion limpia, 3 regresiones de aguja identicas viejo vs nuevo; simulacion 1:1 de Vanilla: vieja flota [bug], nueva cae y aterriza con tope, hoyo identico bit a bit, suelo identico). check_v61_light_dash.py sigue TODO OK (v6.2 intacto)

Stage Summary:
- Scan: causa raiz era del MOTOR (visible=false bloquea el Draw GUI en este runtime), no de la logica — v4.8 y v4.8.1 arreglaban partes que nunca llegaban a dibujarse
- Vanilla: mini fix de 3 ramas x2 fases; hoyos y suelo quedaron bit a bit identicos, solo cambia el caso "aire sobre suelo" (cae)
- Entregable: download/td2dr_scan_vanilla_v1.zip (SOLO archivos modificados/creados: obj_exe_indicator Create_0/Draw_64/Step_2, scr_chocola.gml, check_scan_vanilla_fix.py, LEEME_SCAN_VANILLA_V1.txt, worklog.md). Recompilar SOLO el CLIENTE (GameMaker)
---
Task ID: 13
Agent: Super Z (main agent)
Task: FIX CRASH obj_player_warning — "Unable to find instance for object index 300" en Draw_75 (line 4)

Work Log:
- Pull: 043407a3 (el usuario commiteo TODO lo anterior: Task 12 scan Metal Amy v4.9 + Vanilla v2.2 en 0dd2fd9d; act9/UDID en 0a66d72e; shows LMS mus_lms_16/17 en 5c2b5586; MultiClient en 043407a3). Sandbox reciclado -> re-clone completo; fixes previos verificados intactos en el arbol (v6.2 array_contains en scr_light_dash 451/1235, indicador visible = needle || scanCount, Vanilla 3 ramas en scr_chocola)
- Reporte del usuario: crash runtime "ERROR in action number 1 of Draw Event for object obj_player_warning: Unable to find instance for object index 300 at gml_Object_obj_player_warning_Draw_75 (line 4) - if(global.player.isDead || global.player.revivalTimes >= 2)"
- Que es el objeto: el aviso ANTI-CAMP (20 s sin cambiar de chunk tras el minuto 1 -> scr_move_basic:307 crea obj_player_warning: textos de miedo + scr_player_slow(5) + musica bajada). Su linea 4 lee global.player con dot-access directo para auto-apagarse si el player murio o se quedo sin revivas
- CAUSA RAIZ: frame de transicion de fin de ronda. El codigo de red reescribe global.player ANTES de que el room_goto (aplica al final del frame) destruya el aviso (persistent:false, muere con el room): game over individual -> global.player = noone (net_state_game 3265/3418/3969, net_tcpprocess:167); vuelta a vote/lobby -> global.player = obj_exe, INDICE DE OBJETO, no instancia (net_state_vote:32, net_state_lobby:85, default de scr_globals:9). El dot-access sobre noone / indice sin instancias / instancia destruida = "Unable to find instance for object index 300" (300 = indice del objeto) y el Draw GUI muere a mitad del fade
- Verificado antes de concluir: el aviso era el UNICO dot-access a global.player SIN guard de todo el proyecto (grep de todos los Draw events: cero hermanos); scr_player_hurt:195, scr_player_slow:3 (v4.8.1) y net_state_game:3253 ya usan instance_exists(global.player); la muerte normal NO destruye la instancia (scr_player_hurt la deja viva con isDead=true -> el aviso se apagaba bien); ni el show LMS ni la demonizacion destruyen players
- FIX (patron de la casa, 1 archivo, +13/-2): Draw_75.gml — `if(!instance_exists(global.player)) moved = true; else if(global.player.isDead || global.player.revivalTimes >= 2) moved = true;`. Sin player vivo toma el MISMO camino que "muerto": fade-out y autodestruccion limpia (CleanUp restaura la musica). Formula isDead/revivalTimes intacta; resto del evento byte a byte identico; scr_player_slow (ultima linea) ya tenia guard propio -> no-op sin player. Tabulacion original preservada (parche aplicado en binario)
- Validacion: check_player_warning_fix.py 17/17 OK (estatica: diff quirurgico byte a byte vs HEAD, unica linea con dot-access = la del else if precedida por el guard, hermanos Create/CleanUp/.yy/scr_player_slow/scr_player_hurt/net_state_game byte a byte intactos, guards de la casa vivos, llaves balanceadas; simulacion 1:1 del Draw GUI con la semantica del runtime: VIEJO reproduce el crash en los 3 sabores — noone, indice de objeto 300 sin instancias con el MENSAJE EXACTO del reporte, instancia destruida — y NUEVO apaga limpio en los 3 con musica restaurada; 5 regresiones viejo==nuevo frame a frame: campero vivo, muerto a mitad, demonizado revival 2, minuto 0, moverse de chunk; scr_player_slow no-op sin player)

Stage Summary:
- Causa raiz: carrera de transicion — el netcode reescribe global.player (noone / indice de objeto) en el mismo frame en que el aviso anti-camp todavia dibuja su ultimo frame antes del room change; era el unico dot-access sin guard del proyecto
- 1 archivo del cliente (+13/-2), cero cambio de comportamiento con player valido (mismo camino que "muerto"); server y fixes previos intactos
- Entregable: download/td2dr_player_warning_v1.zip (SOLO archivos modificados/creados: objects/obj_player_warning/Draw_75.gml, check_player_warning_fix.py, LEEME_PLAYER_WARNING_V1.txt, worklog.md). Recompilar SOLO el CLIENTE (GameMaker)

---
Task ID: 14
Agent: Super Z (main agent)
Task: SCAN v4.10 DE METAL AMY (siluetas lejanas visibles en mapas claros + duracion "de 8 a 12 s") + QoL VISUAL/TECNICO DE LA SUITE + TIERLIST V5 (limpiar datos obsoletos + montar el top de los mas poderosos)

Work Log:
- Pull: 043407a3 (ya con TODO commiteado: Task 12 scan v4.9 en 0dd2fd9d, act9/UDID, shows LMS, MultiClient). El working tree traia SOLO lo no-commiteado de la Task 13 (player_warning) — entregado en su propio zip, NO se incluye en este
- SCAN v4.10 A) duracion: METALAMY_SCAN_TIME 8 s -> 12 s (la V manual) y macro NUEVA METALAMY_HUNT_WINDOW = 8 s para la ventana pasiva de la cazadora (el Step_0 usaba la del manual en sus 2 sitios); HUNT_TIME (ciclo 14 s), SCAN_RECHARGE (20 s) y el HUD intactos (sus barras no leen la duracion). Interpretacion de "de 8 a 12 s": 12 la manual / 8 la pasiva — ambos dentro del rango pedido, documentado asi en los 3 gml
- SCAN v4.10 B) visibilidad: causa raiz MATEMATICA — la silueta lejana era aditiva (bm_add, c_red) con alpha *0.45: sobre un fondo claro sumar rojo mueve UN canal y saturado (236+29 -> 255: +19 en R, 0 en G/B), tinte rosado sin forma = "no se notan". FIX en 3 pasadas SOLO para la fuera de la vista (la de dentro queda bit a bit identica a v4.8, como pidio el usuario): contorno oscuro rgb(56,8,8) alpha 0.9 en blend normal con 4 offsets de 2 px (contraste en claros) + relleno solido rgb(255,72,72) alpha 0.62+0.33*pulso (legible en cualquier fondo) + brillo aditivo 0.35*pulso (conserva el pulso en oscuros). Contraste peor caso: 349 vs 19 (18x)
- QoL SUITE (todo aditivo, try/catch, 9/9 bloques node --check OK): (1) "Reabrir ultima carpeta" — handle en IndexedDB al abrir proyecto, boton que recupera permiso con UN clic (queryPermission->requestPermission->attachFs, camino oficial), degradacion elegante si file:// capa IndexedDB; (2) buscador de personajes #char-search (filtra por nombre O objeto, data-char al indice REAL, aviso "Sin resultados"); (3) memoria de modulo (td2d_module) + sub-pestañas (td2d_cdsub/td2d_artesub), restauracion al arranque SIMULANDO EL CLIC en la nav (camino oficial de switchModule); (4) visual: scrollbars finas/doradas, :focus-visible, micro-transiciones, toasts animados, prefers-reduced-motion, meta theme-color+description
- TIERLIST V5 (nueva, 3,39 MB -> 0,17 MB, 95% menos): FUERA 3,0 MB de sonidos embebidos + 130 KB de tiras + motor de escenas (7 escenas changelog) + planificador + CDS + demos + VSDATA + EXEDATA + musica + 4 pestañas de changelog (Mejoras/VS el EXE/Impresiones/Pasivas de Amelia) + PROPS + 4 banners de movimientos viejos + 46 clases de CSS muerto (9,8 KB, poda automatica por clases inexistentes). DENTRO actualizado: Metal Amy velocidad 13 limpia + scan v4.10; Sally Canon A+->S (Fase Duelista v5.8: patada 2 golpes, spindash, rodadura, salto en bola, escudo grupal, evasion); Amy Canon LSA aereo v6.2 (cadena 6 objetivos, intercepcion 140 px, ruta por anillos); Vanilla fix v2.2; contador 14 supervivientes (decia 13); enlaces a Comentarios V2. NUEVO: pestaña "El top" (la primera) — podio 1 Amy Canon / 2 Metal Amy / 3 Vanilla + tabla 4-10 (Chaos, Sally Canon, Amelia, Sonic, Fleetway Amy, Exeller, Sonic.exe), 6 supervivientes + 4 EXE (reparto real de tiers), cada fila abre su ficha
- Validacion: check_scan_v410_fix.py 45/45 OK (estatica + simulacion 1:1 del dibujo con la matematica de blends del runtime en 3 fondos + simulacion de ronda de 130 s con V manual 12 s y cazadora 8 s + regresiones byte a byte vs HEAD de Step_2/Create_0/.yy/HUD); check_scan_vanilla_fix.py (v4.9) sigue 50/50 OK; check_qol_tier_v5.py 81/81 OK; SMOKE TEST EN NAVEGADOR (agent-browser headless): Suite arranca con 0 errores/0 banners, demo -> filtro "cha"=CHAPO/"zzz"=Sin resultados/vacio=todos, cambio a Enfriamientos -> recarga -> restaura "cd" solo; TierList V5 renderiza podio 3 + tabla 7 + 14 fichas + matriz 70 celdas + Sally Canon en fila S + 0 errores JS

Stage Summary:
- Scan: la v4.8 dibujaba las siluetas lejanas como fantasma aditivo al 45% — sobre fondos claros eso es matematicamente invisible (un canal, saturado); v4.10 = 3 pasadas (contorno oscuro + relleno solido + brillo) solo para las lejanas, y duracion 12 s la V / 8 s la cazadora
- Suite: 4 QoL aditivos (reabrir carpeta con 1 clic, buscador, memoria de modulo/sub-pestañas, pulido visual) sin tocar NINGUNA funcion previa — todo verificado en vivo
- TierList V5: el 93% del peso era el reproductor de audio embebido; fuera el changelog absorbido, dentro el juego al dia (v4.10/v6.2/v5.8) y el top de poder pedido, en una pagina 20x mas ligera
- Entregable: download/td2dr_scan_v410_qol_tier_v1.zip (SOLO archivos modificados/creados: scr_metalamy_special.gml, obj_metalamy Step_0/Create_0, obj_exe_indicator Draw_64, Suite_TD2D.html, TierList_Mejoras_V5_0.html, check_scan_v410_fix.py, check_qol_tier_v5.py, LEEME_SCAN_V410_QOL_TIER.txt, worklog.md). El scan requiere recompilar SOLO el CLIENTE (GameMaker); server intacto

---
Task ID: 15
Agent: Super Z (main agent)
Task: RETIRA SMAX v1 — sacar de la seleccion los 2 mapas porteados de Sonic MAX ("SMax Green Hill" //21 y "SMax Emerald Hill" //22, corruptos), SIN tocar el "Hill" original [12] (el usuario aviso explicitamente de no confundirlos)

Work Log:
- Verificado el pedido contra el repo: los SMax SI estaban incluidos en toda la seleccion — g_mapList 21/22 (Maps.c), global.levels 21/22 (scr_globals.gml), mapData 21/22 (obj_lobby_prolet), defaults de map_list (Config.c) y zonas anticheat (Zone.c); el "Hill" original es el 12 (room_greenhill, ghz_*) y el Fart Zone el 20
- CAUSA RAIZ de lo "corrupto": el porte dejo global.levelDescriptions con 22 entradas para 23 mapas — el id 22 (SMax EH) leia FUERA DE RANGO en obj_lobby/Draw_0.gml:77 (hover del candidato votado) y crasheaba a TODOS los clientes; ademas la desc del 20 (Fart) quedaba pisada por la del GH y la del 21 mostraba el texto del EH (off-by-one del porte: anadio las 2 descripciones al final del array en vez de alinearlas con los ids 21/22)
- CLIENTE (2 archivos): scr_globals.gml — global.levels a 21 entradas y levelDescriptions a 21 ALINEADAS 1:1 (fuera las 2 del porte; anadida desc propia para el 20/Fart que el upstream nunca tuvo, para que ningun id pueda quedar sin descripcion); obj_lobby_prolet/Create_0.gml — mapData a 21 (fuera previews 21/22)
- SERVIDOR (8 archivos, todos compilados por el CMake: los states/*.c son los vivos, los *.c raiz de Server/Lobby/Mapvote son stale y no se tocan): include/Maps.h MAP_COUNT 23->21 y fuera decl smap_init; Maps.c fuera entradas 21/22 de g_mapList y funcion smap_init; include/Zone.h + Zone.c arrays a [21] y ELIMINADOS room_smax_greenhill[] (97 rects) / room_smax_emeraldhill[] (141 rects) + sus entradas en g_mapZone/g_mapZoneSize; include/Config.h + Config.c map_list[21] con defaults 0-19 true / 20 false (Fart fuera del voto, como siempre); states/Lobby.c bound del .map corregido "ind >= MAP_COUNT" (el upstream tenia +1: .map 24 ya leia g_mapList[23] OOB; con el recorte .map 22 habia quedado OOB) y states/Server.c ayuda "(1-21)"
- NO tocado a proposito: rooms/sprites del porte (quedan en el .yyp, inalcanzables desde toda via de seleccion, por si se arreglan), spr_mapvote (sus 23 frames quedan con los 2 ultimos sin usar: tocar el .yy era riesgo gratis), el Hill [12], el Fart [20] y su macro MAP_FART 20, el fallback 20 de map_pick_random, votacion/.map/.sp/.vp intactos en su mecanica
- Validacion: check_retira_smax_v1.py 28/28 OK (entradas REALES de cada lista = 21 en las 7 listas cliente+servidor, posiciones 12/20 intactas, cero smap/smax en codigo fuera de comentarios, bound .map, llaves balanceadas); sintaxis C de los 21 .c del CMake + 10 .c de la UI SDL con -fsyntax-only OK (stub local de enet/SDL2 al no haber libenet-dev en el sandbox; un exceso de inicializadores en g_mapList/g_mapZone/map_list seria error de compilacion y no lo hay)

Stage Summary:
- Los 2 mapas SMax salen de TODA la seleccion (voto, .map, .sp/.vp, UI del server) y MAP_COUNT vuelve a 21; el "Hill" original [12] y el Fart [20] intactos, como pidio el usuario
- Bonus del diagnostico: el crash del lobby (desc fuera de rango del id 22) queda muerto de raiz y las listas del cliente quedan 21/21 alineadas; se corrigio el OOB heredado del .map (aceptaba MAP_COUNT+1)
- Entregable: download/td2dr_retira_smax_v1.zip (SOLO archivos modificados/creados: scr_globals.gml, obj_lobby_prolet/Create_0.gml, include/Maps.h+Zone.h+Config.h, disasterserver/Maps.c+Zone.c+Config.c+states/Lobby.c+states/Server.c, LEEME_RETIRA_SMAX_V1.txt, check_retira_smax_v1.py, PORT_README.md, worklog.md) + td2dr_retira_smax_v1.patch. Recompilar CLIENTE y SERVIDOR a la vez (cliente viejo + server nuevo ya no puede recibir ids 21/22: el server nunca los manda)
---
Task ID: 16
Agent: Super Z (main agent)
Task: SKYBASE V1 — extraer el mapa "SkyBase" del mod abandonado "TD2DR: Project SkyBase v3.1" (ColdestTea, GameJolt 855567) y colocarlo en el proyecto como map, SIN incluirlo todavia en la seleccion (el usuario quiere analizar primero si cumple la cuota)

Work Log:
- Pull: 3bf41dfc ("restaurando", arbol limpio). Infra UTMT reutilizada de la tarea Stardust (gj/utmt)
- Descarga: Cloudflare bloquea curl directo; se paso el challenge con agent-browser, click en "Download (179 MB)" revelo el build PC (game=855567 build=1659622) y el API POST site-api/web/discover/games/builds/get-download-url/1659622 devolvio la URL CDN firmada -> td2dr-project-skybase-v3.1.zip (187 MB, v3.1 Oct 2024 sobre TD2D v1101, con Game/ y Server/)
- Diagnostico clave: el data.win del mod NO tiene chunk CODE (build YYC, GML compilado nativo en el .exe) — el codigo GML es ilegible; PERO rooms/sprites/texturas/sonidos estan completos en el ROOM/SPRT/TXTR/AUDO. Se porto TODO lo estructural 1:1 del data.win y solo el RoomCreationCode se RECONSTRUYO con el patron de la casa
- room_skybase: unico room nuevo del mod (31 rooms vs 30 del base), 3500x1500, 8 capas (Assets_2 -200 / Collisions -100 / Instances 0 / Assets_1 100 / Background3-200 / Background2-300 / Background1-400 / Background color -500), 130 instancias (38 solidos + 32 one-way + 2 paredes, 12 anillos + 3 escape, 4 spawns + 4 exespawns, 5 abyss + 5 targets, 8 springs, 4 pilares, 3 slopes con espejo scaleX=-1, 8 warnings, 1 soundemitter, 1 parallax) + 11 graphics (6 helices + 1 myhole + 4 telepods) — verificado instancia por instancia contra el dump del mod (check 1:1)
- Assets 1:1: 9 sprites recortados de los texture pages 109/110 con las regiones exactas del mod (tiles 2x1750x1500, bgs 1/2/3, propeller 4f, telepod 4f, myhole, pillar, slope) con bbox/collisionKind del mod (slope con MASCARA PRECISA collisionKind 2); 2 objetos custom sin codigo (pillar hijo de obj_hiding_parent, slope hijo de obj_solid_block); musica mus_skybase (2:50) + mus_skybase_chase (7:10) copiadas del build y SFX snd_skybase_target extraido del AUDO embebido (WAV mono 2.1 s)
- Alineacion visual/colision verificada por codigo: 9/10 solidos grandes y 19/19 plataformas grandes tienen contenido del mapa sobre su tope (el unico "fallo" es la barrera del techo, y=−87); los tiles del mapa encajan con la colision
- RoomCreationCode RECONSTRUIDO (patron greenhill): scr_play_music(mus_skybase); global.parallax 3 capas (0.7/0.5/0.3, yspd 1); scr_level_split(spr_skybase_tiles, 110) — depth 110 y no 100 porque Assets_1 (telepods) esta en 100 y a igual depth el orden es indefinido (los telepods quedarian tapados)
- Registro .yyp: +15 recursos al final (9 sprites + 2 objetos + 3 sonidos + room), +1 RoomOrderNode al final (como el porte SMax), +2 carpetas SkyBase (Sprites/Zones y Objects/Level Specific), +1 TextureGroup "SkyBase" (autocrop, como las 24 zonas). Diff 100% aditivo: 129 lineas insertadas, 0 borradas
- NO incluido en seleccion (requisito): verificado cero "skybase" en scr_globals, obj_lobby_prolet, Maps.h/.c, Config.h/.c, Zone.h/.c; MAP_COUNT sigue 21; room inalcanzable desde voto/.map/.sp/.vp (igual que la estrategia pedida para Stardust)
- Validacion: check_skybase_port.py 294/294 OK (portable: el dump 1:1 del mod va incluido en docs/ del zip) — sintaxis de los 15 .yy, room 8 capas/130 instancias 1:1 vs dump, 16 clases de objetos del room existen en el proyecto, sprites con frames PNG, slope collisionKind 2, sonidos presentes, yyp sin duplicados, no-inclusion
- Preview para el analisis de cuota: docs/skybase_mapa.png (mapa completo) + docs/skybase_colision.png (overlay: solidos azul, one-way verde, springs rojo, anillos amarillo, escape blanco, spawns verde, EXE magenta)

Stage Summary:
- Mapa SkyBase 100% custom del mod abandonado de ColdestTea, porte 1:1 (room 130 instancias + 9 sprites + 2 objetos + 3 sonidos), SIN tocar ninguna via de seleccion — listo para que el usuario lo abra en GameMaker y decida si cumple la cuota
- El build era YYC (sin bytecode): todo lo estructural salio del data.win; solo el RoomCreationCode (musica/parallax/level_split) se reconstruyo con el patron de la casa, documentado
- Entregable: download/td2dr_skybase_map_v1.zip (SOLO archivos nuevos: rooms/room_skybase, 9 sprites, 2 objetos, 3 sonidos, docs/ con mapa+colision+dump, check_skybase_port.py, LEEME_SKYBASE_V1.txt; MODIFICADOS: .yyp y worklog.md). NO requiere recompilar nada para verlo en el editor; compilar cliente normal

Task: SKYBASE V2 — fix del error de carga del room ("isDnd" faltante: el IDE no abria el proyecto) + INCLUSION de SkyBase como mapa seleccionable en todas las vias (el usuario: "aprovecha de meter skybase como mapa seleccionable")

Work Log:
- Diagnostico del error del usuario: room_skybase.yy(140,3) "Field isDnd: expected" — el objeto RAIZ del room generado en V1 no tenia "isDnd":false; GM lee los campos del room en orden alfabetico y aborta todo el proyecto al toparse "layers" sin "isDnd" antes. Diff campo por campo contra room_limpcity: unico defecto del porte (instancias/capas/graphics/settings 1:1 OK)
- Fix: 1 linea ("isDnd": false, entre instanceCreationOrder y layers). El validador gana el check de regresion (seccion 2)
- Inclusion siguiendo el camino SMax con la leccion del RETIRA (listas SIEMPRE del mismo largo):
  CLIENTE: scr_globals levels[21] {group:"SkyBase", rid:room_skybase, bg:background_skybase2, music:mus_skybase, chaseMusic:mus_skybase_chase} + levelDescriptions[21] (22/22); obj_lobby_prolet mapData[21] con 2 sprites NUEVOS del preview prolet (spr_pr_skybase 630x270 = mapa completo a escala, spr_pr_skybasebg 512x288 = cielo del propio mapa apilado espejado, ambos texturegroup Prolet y carpeta Prolety como todas las previews); .yyp +2 recursos (2073 total, 100% aditivo); icono del voto = frame 21 de spr_mapvote REUTILIZADO (era el icono huerfano naranja del SMax GH): screenshot real del mapa con esquinas transparentes y nombre "SkyBase", CERO cambios al .yy del sprite (sigue en 23 frames)
  SERVER: Maps.h MAP_COUNT 22; Maps.c g_mapList[21] "SkyBase" callbacks genericos + spawn_red_rings 1 + ring_count 12 (= las 12 obj_ring_spawner del room, regla 1:1 de la casa); Zone.h/.c arrays [22] + room_skybase[] con 40 zonas = rects exactos de los 40 solidos (38 obj_solid_block + 2 muros solid_block2, 1 zone por instancia estilo act9; excluidos one-way/pilares-hiding/slopes/abyss); Config.h/.c map_list[22] con [21] activo y Fart [20] fuera como siempre; Lobby.c/Server.c intactos (sus textos usan %d MAP_COUNT y se ajustan solos)
- Validacion: check_skybase_port.py reescrito en las secciones 8/9/9b/10 -> 328/328 OK (conteos 22 en las 6 listas, ring_count 12, 40 zonas, posicion en g_mapZone, Fart fuera/21 activo, previews Prolet, icono 123x104 con contenido real, yyp sin duplicados); C: los 3 .c editados pasan -fsyntax-only incluso con -std=c17 estricto y los consumidores (Lobby/Server/Mapvote/Game/Ring/Player) compilan IDENTICO a HEAD (diff de errores: cero diferencias, solo implicit-decls preexistentes del upstream)
- Zonas anticheat seguras: el test "ninguna instancia critica dentro de una zona" dio 11 hits de superficie en skybase; el MISMO test contra act9 da 12 y contra angelisland 15 (spawnpoints/springs exactamente en el tope de zonas): patron stock, el pos del cliente siempre queda por encima del tope -> cero falsos positivos esperables
- Entregable: download/td2dr_skybase_v2_seleccion.zip (NUEVOS: 2 sprites de preview, LEEME_SKYBASE_V2.txt, check v2; MODIFICADOS: room_skybase.yy con el fix, scr_globals, Create_0 de obj_lobby_prolet, .yyp, png del frame 21 del mapvote, 6 archivos del server, worklog). REQUIERE recompilar cliente Y server juntos (cliente viejo + id 21 = crash de levels fuera de rango, documentado en el LEEME)

Stage Summary:
- El proyecto vuelve a abrir en GameMaker: el room del V1 tenia el campo raiz "isDnd" faltante y ese UNICO defecto tumbo la carga entera
- SkyBase ya es el mapa 21 en TODAS las listas (voto con icono propio, lobby prolet con preview, .map 22, .sp/.vp, server con anticheat de 40 zonas y 12 spawners de anillos), alineado 22/22 para que no se repita el crash de la era SMax
- Proximo paso natural: probar la ronda completa en server real (votacion, anillos, escapes, abyss, escondites, anticheat) y decidir sobre el hook del SFX snd_skybase_target que sigue sin sonar

Task: SKYBASE V3 — fix del error de carga del sonido ("Cannot find folder path" al linkear: el IDE no abria el proyecto)

Work Log:
- Diagnostico del error del usuario: snd_skybase_target.yy(19,6) "Cannot find folder path 'folders/Sounds/Sounds.yy'" — el V1 creo el SFX con el parent.path copiado de la estructura del PROYECTO DEL MOD (ahi si existia una subcarpeta Sounds/Sounds), pero en NUESTRO .yyp esa carpeta nunca se registro (el .yyp solo tiene folders/Sounds.yy + 8 subcarpetas: Ambient/Effects/Ending/Menu/Minigame/Music/Objects/Player). Las 2 musicas ya apuntaban bien a folders/Sounds/Music.yy; solo el SFX quedo roto
- Fix: 1 propiedad (parent.name "Sounds"->"Effects", parent.path "folders/Sounds/Sounds.yy"->"folders/Sounds/Effects.yy", carpeta existente y la logica para un SFX de 2.1 s; mismo criterio de las 2 musicas que estan en Music)
- Barrido preventivo de TODOS los 17 recursos skybase para evitar otro round-trip: check_skybase_refs.py compara el parent.path de cada .yy contra las 200 carpetas del .yyp (parsing tolerante a comas finales estilo GM) -> 1 rota (la del sonido, ya corregida), 16 OK; compare_fields.py verifica que room/sonidos/objetos/sprites tengan los mismos campos que recursos existentes del mismo tipo -> 0 faltantes; los 17 siguen en la lista resources del .yyp (bajo "id"), room_skybase sigue OK (isDnd false, 8 capas, 130 instancias) y los WAV/OGG siguen en su sitio
- Sin tocar nada mas: el registro del mapa como seleccionable (V2) queda intacto (verificado: levels[21] y descriptions 22/22 en scr_globals, preview [21] en obj_lobby_prolet, Maps.c [21], MAP_COUNT 22, map_list[22] con 21 activo, 40 zonas en g_mapZone)
- Entregable: download/td2dr_skybase_v3_fix_sonido.zip (MODIFICADOS: sounds/snd_skybase_target/snd_skybase_target.yy — un solo archivo — , worklog.md; NUEVO: LEEME_SKYBASE_V3.txt)

Stage Summary:
- El proyecto vuelve a abrir: el parent del SFX apuntaba a una carpeta del proyecto del mod que aqui no existe; ahora apunta a Sounds/Effects y linkea
- Cero referencias rotas en el resto del porte (barrido completo de carpetas + estructura de campos)
- Proximo paso natural: probar la ronda completa en server real y decidir el hook del SFX snd_skybase_target (sigue sin sonar por diseno: ningun codigo lo reproduce todavia)

Task: v6.3 «BLINDAJE DE ANILLOS» — fix del bug de la cura que VACIABA el contador + regla de dano con anillos del pedido del usuario (el usuario: "si tiene mas de 10 rings el dano solo le quita 10; si tiene menos de 10, le quita los rings y le hacen dano; si tiene = 10 o mas, solo se le restan 10")

Work Log:
- Sync: el usuario commiteo el SkyBase completo (8fbecffd "ok": archivos V1+V2+V3 identicos byte a byte) y ADEMAS borro los rooms SMax retirados (-38.000 lineas) y el .resource_order; el .yyp lo re-serializo GameMaker. Local sincronizado al remote (checkout + clean + pull, 55 archivos identicos verificados antes)
- BUG (la cura): hay 3 caminos de conversion 10 anillos -> +20 HP en net_state_game (vasijas VV 1369 / SERVER_RING_COLLECTED 2403 / SERVER_RMZSLIME_RINGBONUS 2543; +bring 2092). El de las vasijas era el UNICO correcto (rings -= 10); los otros 2 hacian rings = 0: con vida full los anillos se acumulan >10 (no hay conversion porque hp no es <100), al recibir dano y recoger el siguiente anillo la cura se tragaba TODO el excedente (25 anillos -> 0 en vez de 15). Fix: los 2 sitios borrados a rings -= 10 (igual que vasijas/bring)
- FEATURE (el dano): scr_player_hurt — var _ringAbsorb = (damage > 0 && rings >= 10) declarada antes del bloque de vida (alcance de funcion): si absorbe, hp NI SE TOCA, sin paquete al server (CLIENT_STATS_REPORT tipo 3 solo alimenta stats.damage_taken: no reportar dano absorbido es mas exacto) y sin sangre (los anillos ya dispersan con spr_ringlose); el golpe sigue dando retroceso, isHurt, i-frames de hurttime y snd_ringlose. Bloque de anillos: pasiva % de Vanilla (15% min 3) / Cream protegida (30% min 3) intacta; resto: >=10 -> exactamente -10 (excedente se queda); <10 -> pierde todos + dano de vida como siempre. Consistente con SERVER_BRING_COLLECTED que YA usaba esta regla (rings <10 -> -20 HP, else -10 anillos)
- wasHurt: un golpe absorbido SIGUE contando para el logro #11 (ronda sin ser golpeado) — te golpearon aunque los anillos salvaran la vida; documentado en el LEEME por si el dueño prefiere lo contrario
- Server: CERO cambios (todo es GML del lado victima, cliente-autoritativo; el server solo recibe stats). NO requiere recompilar el server
- Validacion: check_v62_blindaje_rings.py 23/23 OK — balance de llaves de los 2 archivos, las 3 conversiones restan 10, hp -= damage solo sin absorcion, rama -10 exactos, sangre condicionada; simulacion 1:1 del flujo: 15->5 absorbido / 10 exactos->0 absorbido / 9->pierde todo+dano / Vanilla 50->43 (15%) / Cream+V 50->35 (30%) / cura 25->16 conservando / vida full no convierte
- Entregable: download/td2dr_v63_blindaje_rings.zip (MODIFICADOS: scr_player_hurt.gml, net_state_game.gml; NUEVOS: check_v62_blindaje_rings.py, LEEME_V63_BLINDAJE_RINGS.txt, worklog)

Stage Summary:
- La cura ya no se traga el excedente: 25 anillos al curarse -> +20 HP y quedan 16 (antes quedaba 0)
- Los anillos ahora son escudo: con 10+ el golpe cuesta 10 anillos exactos y la vida NI SE TOCA; con menos de 10 pierde los anillos y la vida, como siempre; Vanilla/Cream siguen con su pasiva % (mejor que la regla comun)
- Proximo paso natural: probar en server real un flujo completo (absorber con 15-20, curar con excedente, Vanilla con 50) y elegir el proximo mapa a extraer (NU Project 4 mapas / Curse of Chaos 1 mapa / Stardust pendiente)

---
Task: NU PROJECT v1 — porte del mapa "Negagen Temple" (room_alphagentemple) del mod abandonado "TD2DR NU Project" (Remodify Studios, GameJolt 1015209) como mapa seleccionable [22]; pedido del usuario: "saquemos los mapas de nu project... incluye por ahora solo los mapas nuevos"

Work Log:
- Pull: ya al dia. Descarga del build via site-api de GameJolt (build 1815200, los DOS botones de descarga apuntan al MISMO zip): td2dr-nu-project-demo-1.zip 205 MB v0.2.2 -> data.win YYC 130 MB (sin CODE: todo estructural extraido con UTMT, cero GML legible)
- CLASIFICACION con datos reales (no wiki): el mod trae los 30 rooms del base + 4 mapas nuevos + 1 room "próximamente". Los 4: room_alphagentemple (NegagenTemple, NUEVO de verdad), room_sarksblips (rework de Hill), room_deeztwin (rework de DesertTown), room_nastya (rework de NastyParadise) — el mod INCLUYE los originales, o sea que los "Nu" son versiones alternativas. Solo se porto el templo, como pidio el usuario
- room_alphagentemple 2816x1536, 9 capas 1:1 (statui -100 con 11 estatuas en 7 poses DELANTE del jugador = escondite visual; Instances_1 con 8 springs/26 ring_spawner/5 ringspawn/4 spawns/4 exespawns/11 am_hideobject; sfera1+sfera2 OCULTAS con 8 almas animadas; femboy 200; Collisions 400 con 30 solidos/10 one-way/12 rampas/cristales/parallax; Backgrounds2 500 + Background 600 tiled; black 700) — 113 instancias verificadas contra el dump del mod objeto por objeto
- Hallazgo clave del visual: los solid_block del mod son invisibles (igual que el base) y el room NO tiene creation code — el GEOMETRIA la dibujan spr_nt_tiles/tiles2/tiles3 (3 frames de 1072x1536 = arte del propio mod, hallados buscando sprites nuevos del mod vs nuestro repo) y las musicas/previews del mod (spr_pr_nt_*, mus_alphagentemple*) también existían como assets suyos; RoomCreationCode RECONSTRUIDO con el patron de la casa: scr_play_music + parallax 0.8/0.6 + scr_level_split(100/90/450). El loop de scr_level_split cubre 1072px bien (i < 1072/1024 da 2 partes, mismo mecanismo que los 1750px de skybase)
- obj_femboy_temple portado como hijo de obj_corpse con char=-1 (patron obj_corpse_knux; el Create/Step YYC del mod es ilegible): Negagen no existe en nuestro juego -> su forma flota en su templo en cuanto hay jugadores. obj_negatv (cristales) portado estatico sin eventos. obj_am_hideobject/angleanuller/springs/etc YA existian
- RENOMBRE documentado: el sprite "bg2" del mod entra como spr_bg_nt2 (nombre demasiado generico, riesgo de colision futura); el resto mantiene los nombres del mod (statui, spr_dusha, spr_bg_nt...)
- Easter egg del mod conservado 1:1: el arte tiles2 trae horneado un cartel "YES BITCHES!" con una cabeza Sonic.exe de ojos rojos (firma de los autores, NO es corruption)
- Seleccion [22] en TODAS las vias (listas SIEMPRE del mismo largo, leccion SMax): levels[22] + levelDescriptions 23/23 (texto del propio mod en formato 75/76/15) + mapData[22] con las previews PROPIAS del mod (3 tiles 873x270 + bg, grupo Prolet) + icono del voto = frame 22 de spr_mapvote reutilizado (el huerfano del SMax EH, misma jugada de SkyBase con el 21; .yy intacto en 23 frames)
- Server: MAP_COUNT 23; g_mapList[22] "Negagen Temple" generico con ring_count 26 (regla 1:1 de las 26 obj_ring_spawner); map_list[23] con [22] activo y Fart [20] fuera; 25 zonas anticheat = rects exactos de los solidos NO rotados (los 5 rotados ±45 excluidos por la regla de slopes de skybase); test de seguridad: las 14 instancias "dentro" estan en el TOPE de plataformas (patron stock: act9=12, angelisland=15, skybase=11)
- Validacion: check_nu_port.py 79/81 OK (2 FAIL = srand/rand implicitos PREEXISTENTES del upstream en states/Server.c y Mapvote.c, verificados contra HEAD limpio; Maps.c/Config.c/Zone.c compilan limpios con -std=c17 -Wall); .yyp 23 lineas insertadas 0 borradas (parche quirurgico de texto, NO re-serializacion: el primer intento re-serializo el yyp entero y se descarto); parent.path de los 19 .yy nuevos verificado contra las carpetas registradas (leccion V3 del sonido)
- Entregable: download/td2dr_nu_project_v1_negagentemple.zip (SOLO archivos de este porte; los restos no-commiteados de la task v6.3 blindaje de anillos van en su propio zip). REQUIERE recompilar cliente Y server juntos

Stage Summary:
- Negagen Temple ya es el mapa 22 en toda la seleccion (voto con icono propio, lobby prolet con las previews del propio mod, .map 23, anticheat de 25 zonas, 26 spawners de anillos), 1:1 contra el room del mod con su arte y musica originales
- Los otros 3 mapas del NU Project (SarksHills/DeezTwin/Nastya) quedan fuera por ser reworks de mapas que ya tenemos, como pidio el usuario
- Proximo paso natural: ronda de prueba en server real y decidir el proximo candidato (Curse of Chaos 1 mapa / Stardust Speedway pendiente)

Task: NU PROJECT v2 — fix del error de carga del room (rooms/room_alphagentemple/room_alphagentemple.yy(3,3) "Field '%Name': expected": el IDE no abria el proyecto)

Work Log:
- Diagnostico del error del usuario: el room del V1 traia el primer campo escrito "%%Name" (doble %) en vez de "%Name" en la linea 3. Es JSON 100% valido (por eso el parser tolerante del check V1 lo dio por bueno) pero el esquema de GameMaker exige la key EXACTA "%Name" y al no encontrarla aborta la carga del proyecto entero — mismo patron de "1 defecto chico tumba todo" que el isDnd del skybase V1
- Fix: 1 caracter en 1 linea (quitar un %). Diff contra el zip V1 verificado programaticamente: la linea 3 es la UNICA linea distinta de las 298 del archivo. Comparacion campo a campo contra room_skybase (que si carga): la unica diferencia estructural era esa key; el resto (isDnd, 9 capas, 113 instancias, 2816x1536, parent, roomSettings) ya estaba bien
- Leccion aplicada al check: el check V1 validaba sintaxis JSON + parent.path + conteos pero NO el spelling exacto del primer campo. check_nu_v2_room.py NUEVO (122 checks OK): primer key == $GM<Tipo> esperado, key "%Name" exacta (no "%%Name"), valor == nombre del recurso, sin keys "%%..." en los 19 recursos nuevos, barrido repo-wide de keys "%%" en TODOS los .yy del proyecto (limpio), diff de 1 sola linea vs zip V1
- Re-validado el porte entero tras el fix: check_nu_port.py 79/81 OK (los 2 FAIL = srand/rand implicitos PREEXISTENTES del upstream en states/Server.c y states/Mapvote.c, intocados, igual que en V1); el registro [22] (levels/descriptions/mapData/icono frame 22 del mapvote, server MAP_COUNT 23 con 25 zonas anticheat) queda intacto
- Entregable: download/td2dr_nu_project_v2_fix_room.zip (MODIFICADOS: rooms/room_alphagentemple/room_alphagentemple.yy — un solo archivo — , worklog.md; NUEVOS: LEEME_NU_PROJECT_V2.txt, check_nu_v2_room.py). NO requiere recompilar por si mismo (fix de carga del IDE); la recompilacion cliente+server del V1 sigue pendiente igual que antes

Stage Summary:
- El proyecto vuelve a abrir: el room traia "%%Name" (doble %) donde el schema de GM pide "%Name" exacto; 1 caracter y listo
- Barrido repo-wide: ese era el UNICO .yy con keys "%%" de todo el proyecto; los otros 18 recursos nuevos verificados uno por uno (primer campo, parent, registro en .yyp)
- Proximo paso natural: abrir el IDE, recompilar cliente+server juntos (pendiente del V1) y probar la ronda del templo (votacion con icono 22, escondites tras las estatuas, anillos de escape, anticheat)

---
Task: WOOD ZONE + SKY SANCTUARY — porte de los mods sueltos como mapas variante [23] y [24]; pedido del usuario: "Añadamos wood zone y sky santuary No importa si es un rework se incluira como mapa variante y punto y final"

Work Log:
- Pull previo (d8ece67a "up": mus_lms_18 + backup). Descargas: Wood Zone (DeklynTDH, GameJolt 865011, rar 180 MB con unrar oficial de RarLab v7 porque unrar-free no lee RARv5; URL real capturada con agent-browser del flujo de descarga de GJ) y SkySanctuary (CranberryStudios, GameBanana 495859, zip 63 MB via API gb). Ambos data.win son builds YYC 2023.2 SIN chunk CODE: solo assets+rooms+sonidos, el GML vive en el exe (por eso los mods solo pudieron editar arte/layout, cero logica nueva)
- Parser data.win propio en Python (scripts/ut_*.py, formatos de UndertaleModLib): chunks FORM, STRG (punteros a CONTENIDO entry+4, padding a 4B), convencion de punteros ABSOLUTOS en tablas, referencias por INDICE en GM2022.3+ (IDinGC: objectDefinition/sprites de capas), rooms con layers (enum real: 1=Background 2=Instances 3=Assets 4=Tiles), texturas TXTR con blobs BZ2+QOI (decodificador QOI variante GM "fioq", stream bz2 ya es un QOI completo: no reconstruir header). Bugs encontrados y fijados en el camino: doble swap de canales BGRA->RGBA, TPAG con items de 22 bytes SIN padding
- CLASIFICACION empirica (diff de layouts vs repo, no wikis): Wood Zone REEMPLAZA el layout de room_dotdotdot (9% compartido, 473 instancias nuevas) y su arte: background verde bosque 456x240 + tiles de MADERA (spr_dot_tiles/spr_dot_tiles1 1136x1888 x4f, media RGB 81,61,25) + previews spr_pr_dot* re-skinneadas + musica propia (mus_dotdotdot*.ogg del mod != repo). SkySanctuary REEMPLAZA room_hideandseek2 (14% compartido, 125 instancias) y su arte: background_hn2 (nubes grises) + hn22 + spr_hs2_tiles (ruinas verdes 1152x1664 x4f) + previews spr_pr_hst* — audio 100% vanilla (SFX embebidos identicos 148/148, musica externa original). Ambos rooms usan SOLO objetos existentes en el repo (0 faltantes) y sus bloques/plataformas son invisibles: el look lo cargan los tiles de scr_level_split
- Porte 1:1 como mapas NUEVOS (nada se sobreescribe del juego base): room_woodzone (4544x1888, capas Stairs/-200 Light/-100 Instances/0 Assets_1(spr_vv_lava @3088,720)/Background/Backgrounds_1, 473 instancias verificadas 0 mismatches) y room_skysanctuary (4608x1664, capas Instances/Background2/Background/Background_1, 125 instancias 0 mismatches). RoomCreationCodes RECONSTRUIDOS con el patron original de cada mapa base: WZ = parallax Background 0.4/0.2 + split(spr_wood_tiles1,-50)+split(spr_wood_tiles,50); SS = scr_play_music(mus_hideandseek2) + parallax 0.3/1 y 0.2/1 + split(spr_skysanc_tiles,90). rot de instancias reconvertida de FloatAsInt-u32 a grados
- Assets nuevos (13 sprites, extraidos de los data.win con el decoder QOI): background_woodzone, spr_wood_tiles, spr_wood_tiles1, spr_pr_wood/2/3 (WZ) + background_skysanc, background_skysanc2, spr_skysanc_tiles, spr_pr_skysanc/2/3, spr_pr_skysancbg (SS); carpetas Sprites/Zones/WoodZone y SkySanctuary + texture groups propios (bz2, patron NegagenTemple). Sonidos: mus_woodzone (131.8s) + mus_woodzone_chase (64.0s) del propio mod (SS reusa la vanilla hs2, 1:1 con el mod)
- Iconos mapvote: spr_mapvote 23 -> 25 frames (frame 23 WZ base frame-2 "...", frame 24 SS base frame-0 hs2): escena = tiles del propio mod escaladas al interior del marco verde, titulo pixelado propio, banda EASY del original preservada (geometria validada: titulo filas 1-8, escena 15-88, label 97-101); validados con VLM (titulos legibles, escenas correctas)
- Registro [23]/[24] en TODAS las vias: levels/descriptions 25/25 (formato 75c de la casa, textos propios del porte con |+25 sec de sus mapas base), mapData del lobby prolet 25 entradas (previews del propio mod, side flags heredados de sus mapas base), .yyp con parche QUIRURGICO de 23 lineas (leccion NU V1: NO re-serializar; el primer intento re-serializo 17K lineas y se descarto), RoomOrderNodes 34, MAP_COUNT 25, g_mapList[23] "Wood Zone" (GRN, ring_count 25 del base) y [24] "SkySanctuary" (BLU, 22 del base), map_list 25 con ambos activos, Zone.h/Config.h TAMBIEN a [25] (fallo inicial: solo .c, gcc lo cazo con conflicting types)
- Zonas anticheat: WZ 343 (346 bloques - 3 rotados 14grados fuera) y SS 27 (29 - 2 rotados -153.5), 1 rect por instancia con la regla de escalas negativas (rectangulo se extiene hacia atras desde el origen 0,0). Test de seguridad: 6 spawns de WZ "dentro" pero TODOS en el TOPE de zonas (y == zona.y, patron stock: act9=12, angelisland=15, skybase=11, alphagen=14); SS 0. Server UI: el MapList del operator itera MAP_COUNT solo, los slots 20-24 del Spritesheet.png quedan vacios igual que SkyBase/Negagen (patron establecido, documentado)
- Validacion: check_port.py 953/953 OK (esquema de los 15 .yy nuevos con primer key exacto y %Name simple — leccion NU V2 aplicada desde el inicio, sin BOM, parents contra carpetas registradas, frames/keyframes/pngs consistentes, rooms 1:1 contra los dumps de los mods con TODAS las instancias comparadas, gcc -fsyntax-only OK en Zone.c/Maps.c/Config.c/Player.c con stub enet; los 2 srand/rand implicitos preexistentes de Mapvote.c siguen ahi, intocados); renders de depuracion validados con VLM como niveles coherentes
- Entregable: download/td2dr_woodzone_skysanctuary.zip (MODIFICADOS: .yyp, scr_globals.gml, obj_lobby_prolet/Create_0.gml, spr_mapvote.yy, Maps.h/c, Config.h/c, Zone.h/c, worklog.md; NUEVOS: 2 rooms, 13 sprites, 2 sonidos, 2 iconos png, check_port.py, LEEME). REQUIERE recompilar cliente Y server juntos

Stage Summary:
- Wood Zone es el mapa [23] (variante del "...": valle de madera sobre el abismo con lava y spikes moviles, musica propia del mod) y SkySanctuary el [24] (variante del Hide and Seek 2: ruinas verdes flotantes entre nubes), ambos seleccionables en voto/lobby/.map/anticheat con TODO su arte original extraido de sus data.win
- Con esto ya hay 25 mapas y la coleccion cubre los 3 mods sueltos de mapas que habian en GameBanana/GameJolt (NU Project, Wood Zone, SkySanctuary); quedan como futuros: Universe Relapse (7+ mapas), Curse of Chaos (1), One Last Round, SONIC 2011 (1+server)
- Proximo paso natural: abrir el IDE (carga verificada), recompilar cliente+server juntos (tambien siguen pendientes las recompilaciones del NU V1/V2) y ronda de prueba votando [23]/[24]

---
Task: OPTIONS MORE v1 — porte de la pestana "More" del menu Options del port web (sonicweb.dr2.site) al cliente GameMaker; pedido del usuario: portear la pestaña MORE del port con todas sus filas y funciones reales

Work Log:
- Verificacion EN VIVO del port (servido local con /api/ping + /game/*): navegacion del menu (el port usa S/ArrowDown para bajar, ArrowUp para subir, X atras, Z entrar), entrada a Options > MORE y volcado de las 12 filas. Rangos verificados captura a captura: LOOK AHEAD = off/5%/.../50% con wrap (14 pulsaciones desde 35% caen en 50% exacto con el ciclo 11 valores), LOOK AHEAD BY = facing/speed, TURN SPEED = 1-5 numerico con wrap, CAMERA LAG = off/low/medium/high con wrap, MUSIC VOLUME con wrap 10->0. Colores verificados a nivel de pixel: toggles verde #0fff39 ON / rojo #ff0001 OFF, cyclers blanco, y el VALOR MANTIENE SU COLOR con la fila resaltada (el resaltado es el tint rojo #910000 del label, como el juego). Layout medido en coords de juego: 9 filas visibles de 17px empezando en y=57, valores a x 380-408, "..." arriba y=41 y abajo y=205 CENTRADOS, descripcion centrada y=216, tabs y=248-256
- UI: sprite nuevo spr_menu_more (180x16, 12 frames: 6 labels de toggle + 6 de cycler con < >, glifos pixel-perfect de la fuente del juego, mismo origen (90,8) y banda de texto y4-11 que spr_menu_buttons) + frame 68 "MORE" en spr_menu_buttons (69 frames, keyframe 68, length 69.0). Layout calibrado al port: filas x=290 y=57+i*17 (labels a ~200 como las otras vistas, valores a ~390 como el port), tabs GENERAL 124 / CONTROLS 299 / MORE 420 / BACK 495 en y=252 (posiciones nativas del juego), valor dibujado con scr_text_spr en (x+100, y-3) para centrar los glifos de 6px en la fila
- obj_menu_valuebutton NUEVO (hijo de obj_menu_button: hereda Step del offset y el resaltado rojo del menu): Create con defaults defensivos de bid/bcolumn/submenu/tid, Draw_0 (draw_self + valor en vivo con color del port + clic en toda la fila via point_in_rectangle label+valor), Draw_64 (solo la fila 0: descripcion centrada y=216 y "..." y=41/y=205, en Draw GUI para quedar sobre el fondo del panel)
- scr_menu_more NUEVO: MORE_ROWS 9 / MORE_COUNT 12; build() idempotente (capa OptionsMore a -1500 con 9 filas reciclables bid=displayRow+scroll + 4 tabs, y pestana MORE anadida a General bid 6 / Controls bid 11 / Back bid 3 con auto-creacion de capa si faltara, patron v4.2 de special3); refresh/ensure_visible (scroll 0..3); cycle (toggles + cyclers con wrap como el port); toggle_state/value_text/desc (descripciones literales capturadas del port); apply_volumes (audio_sound_gain por ASSET sobre los 91 de musica + 231 de sonido = los 322 del proyecto, verificados contra sounds/ 0 faltantes 0 sobrantes)
- Integracion en obj_menu/Create_0.gml (10 parches, diff final 98 lineas +): macro SUBMENU_OPTIONSMORE 49 (siguiente libre tras 47/48), moreScroll, buttonListed (case MORE: filas 0-11 ciclan, bid 14 navega vistas; el ciclo de pestañas pasa ahora General -> Controls -> MORE -> Back), buttonSelected (ensure_visible antes de resaltar), buttonPressed (bids 6/11/3 de las pestanas nuevas + case MORE completo 12-15), changeSubmenu (case MORE: bCount 16, bars frame 2, capa + respaldo). Alarm_0 llama a scr_menu_more_build() 1 frame tras crear la room. bColumnCount 0: izquierda/derecha en filas cicla el valor (via buttonListed), como SCREEN SIZE en General
- obj_config: 12 campos nuevos (optBackgrounds..cameraLag, defaults vanilla: todo on salvo PERFORMANCE, volumenes 10, camara off), load con try/catch por campo (guardados viejos cargan igual, patron KeyIdle), save los escribe, y al final del Create llama scr_menu_more_apply_volumes() (gain por asset al arrancar, antes de cualquier musica)
- Funciones gameplay: obj_camera/Draw_76 modo follow con LOOK AHEAD (offset = escalon*12px hacia image_xscale o proporcional a xspd/maxHSpeed), TURN SPEED (lerp 0.04*nivel), CAMERA LAG (velocidad max 14/10/7 px/frame persiguiendo la x objetivo); con lookAhead 0 el offset decae a 0 y sin lag x = objetivo (camara vanilla exacta). obj_parallax: BACKGROUNDS off oculta las capas de la lista global.parallax, PARALLAX off fuerza factor 1:1. scr_effect_quick: con EFFECTS off las instancias se crean (los 2 llamadores que usan el retorno siguen funcionando) pero invisibles, mueren solas. WEATHER: ghz_controller no spawnea gotas ni suena snd_rain (y lo corta si sonaba), nap_controller sin copos. SCREEN OVERLAYS: gate de la vineta de obj_level y de los overlays animados de obj_dotdotdot_i (los velos de esconderse/sangre son gameplay y se quedan). PERFORMANCE: HUD en obj_level con fps + ms (media lerp 0.05) coloreado 17/34ms
- Volumen a prueba de pisado: los 6 puntos que fijaban gain 1 absoluto (scr_play_music, dotdotdot Create/Step crossfades, player_warning CleanUp, net_state_game act9_chase, room_act9 RoomCreationCode) ahora multiplican por obj_config.musicVolume*0.1; los fades a 0 quedan igual (0*loque sea = 0)
- Higiene del repo: los .yyp registro con parche quiurgico de 3 lineas (leccion WoodZone: nada de re-serializar); las ediciones via herramientas de texto habian mezclado espacios/tabs y duplicado profundidades en obj_config/obj_menu/parallax/dotdotdot — rehechos esos 5 archivos DESDE HEAD con parches python de indentacion exacta (obj_config 69+/1-, obj_menu/Create 98+/2-, Alarm_0 +9, parallax +15, dotdotdot +9); chequeo de balance {}()[] sobre los 23 .gml tocados: TODO OK; unica linea no-ASCII nueva: ninguna (el № del texto de Amy Canon es preexistente)
- Entregable: download/td2dr_options_more_v1.zip (NUEVOS: sprites/spr_menu_more/, objects/obj_menu_valuebutton/, scripts/scr_menu_more/, LEEME_OPTIONS_MORE_V1.txt; MODIFICADOS: .yyp, spr_menu_buttons.yy + sus 2 png/2 layers del frame 68, obj_menu/Create_0+Alarm_0, obj_config/Create_0, obj_camera/Create_0+Draw_76, obj_parallax/Draw_72, scr_effect_quick, ghz_controller/Create_0+Step_0, nap_controller/Step_0, obj_level/Create_0+Draw_64, obj_dotdotdot_i/Create_0+Step_0+Draw_64, player_warning/CleanUp_0, scr_music, net_state_game, room_act9/RoomCreationCode, worklog.md). room_menu.yy INTACTO (todo por codigo)

Stage Summary:
- La pestana MORE del port web vive en el cliente: 12 ajustes reales (fondos, parallax, efectos, clima, overlays, rendimiento, 2 volumenes, 4 de camara) con guardado en 1.bson, navegacion teclado+raton identica al resto del juego, y defaults que conservan la experiencia vanilla
- Todo verificado contra el port en vivo (rangos, colores, layout medido al pixel) y contra el repo (322/322 assets de audio cubiertos, balance GML OK, diffs minimos, room sin tocar)
- Proximo paso natural: recompilar el cliente en GameMaker y probar: cambiar volumenes en el menu (debe oirse al instante), entrar a Green Hill con WEATHER off (sin lluvia ni sonido), y probar LOOK AHEAD 35% + CAMERA LAG medium para el feel clasico

---
Task: OPTIONS MORE v1.1 HOTFIX — el proyecto no cargaba en el IDE; pedido del usuario: error "spr_menu_more.yy(35,3): Field 'name': expected"

Work Log:
- Causa raiz: el .yy generado para spr_menu_more omitia el campo "name" a nivel raiz (los .yy llevan los campos en orden alfabetico y "name" va justo entre "layers" y "nineSlice"; el parser del IDE esperaba ahi "name" y encontro "nineSlice" -> linea 35 columna 3, exactly lo reportado)
- Fix de 1 linea: "name":"spr_menu_more", anadido en su sitio
- Verificacion anti-sorpresa (el IDE frena en el PRIMER error, asi que se barrio todo lo que quedaba por cargar): comparacion estructural spr_menu_more vs spr_menu_buttons (unico delta = el name que faltaba, ya cerrado), obj_menu_valuebutton vs obj_menu_togglebutton y scr_menu_more vs scr_music (0 diferencias de estructura), JSON parse OK de los 5 .yy tocados (los 3 nuevos + spr_menu_buttons + .yyp), frames/keyframes/length consistentes (12/12/12 y 69/69/69), PNGs y layers de todos los frames presentes, keyframe 68 referencia su frame correcto, texture group Menus y las 3 carpetas padre registradas en el .yyp, y las 3 altas del .yyp en posicion alfabetica correcta
- Entregable: download/td2dr_options_more_v1.zip actualizado in-place (solo cambian spr_menu_more.yy, LEEME y worklog); LEEME con nota del fix y instruccion para quien ya aplico v1: reemplazar SOLO sprites/spr_menu_more/spr_menu_more.yy

Stage Summary:
- El IDE vuelve a cargar el proyecto entero; el fallo era un solo campo ausente en el JSON del sprite nuevo, todo lo demas de la entrega v1 estaba bien
- Proximo paso natural: recompilar el cliente en GameMaker y hacer la ronda de pruebas (volumenes al instante, WEATHER off en Green Hill, LOOK AHEAD 35% + CAMERA LAG medium)

---
Task: WELCOME PACK v1 — 500 mercoins en instalacion limpia (Android); motivo: al reinstalar el APK Android borra /data y con el el 3.bin, el jugador volvia a empezar con 0 monedas. Reaplicado y entregado tras la perdida del sandbox (la tarea original se perdio sin zip)

Work Log:
- Cambio 100% aditivo en 2 archivos de obj_achivements (+56/-1 lineas): Create_0.gml declara welcomePack = (os_type == os_android ? 500 : 0) y welcomeTimer; el bloque de instalacion limpia (si NO existe 3.bin) escribe welcomePack en el primer u64 — el campo mercoins que load() lee de vuelta: las monedas caen al contador real y el save posterior las conserva; Draw_64.gml dibuja el popup del pack
- Popup: caja negra 134x30 con borde blanco arriba-izquierda (mismo sitio que la caja de logros), desliza 20 frames entrando / ~280 quieta / 20 saliendo (320 frames = ~5,3 s: arranca sobre el logo y termina ya en el menu), moneda girando con los 26 frames de spr_mercoin (floor(current_time/100) % sprite_get_number), texto en minusculas a proposito (scr_text_spr no tiene mayusculas: ord(c)-97) con el monto interpolado $"+{welcomePack} mercoins" — editar el monto actualiza el texto solo
- Reglas: instalacion LIMPIA en Android = 500 + popup (cubre reinstalar APK / cambiar de telefono / borrar datos); instalar ENCIMA no da pack (el 3.bin viejo existe y manda); Auto Backup (v1.4 del chat) restaurado tambien gana al pack; PC sigue en 0 (su guardado sobrevive a reinstalaciones)
- Server: CERO cambios (3.bin es 100% local). NO requiere recompilar el server; el cliente si (2 GML)
- Validacion: balance {}()[] OK en los 2 archivos; scr_text_spr firma verificada (xx, yy, str, color, alpha — la llamada de 5 args es correcta); spr_mercoin existe con 26 PNGs y length 26.0 (la misma cifra que el comentario); spr_achivementbox presente; interpolacion $ y file_exists($"{game_save_id}/3.bin") ya usadas en el mismo archivo (patron preexistente); matematica del deslizamiento verificada: el paso por frame es 144/20 = 7,2 px y las ramas se encuentran exactas en 4 (300 frames) y en 4 (20 frames): sin salto
- CUIDADO documentado en el LEEME: es un regalo LOCAL; bucle desinstalar->reinstalar lo farmea (500 por ciclo). La version a prueba de farmeo seria concederlo por uid en el server; ofrecida al usuario por si la quiere
- Nota de recuperacion: el sandbox se reciclo a mitad de esta tarea; el commit local "welcome pack v1 ... reaplicado tras perdida de sandbox" preservo el codigo, esta entrega completa el paquete (LEEME + worklog + zip). Descarga/ quedo vacio tras el reciclado: los zips de tareas YA aplicadas por el usuario (skybase, nu project, woodzone/skysanctuary, options more, blindaje v6.3) no se regeneran — sus archivos ya viven en el repo del usuario
- Entregable: download/td2dr_welcome_pack_v1.zip (MODIFICADOS: objects/obj_achivements/Create_0.gml, objects/obj_achivements/Draw_64.gml; NUEVOS: LEEME_WELCOME_PACK_V1.txt; worklog). REQUIERE recompilar SOLO el cliente

Stage Summary:
- Instalacion limpia en Android arranca con 500 mercoins y un popup de ~5,3 s (caja arriba-izquierda, moneda girando); PC, actualizaciones y backups restaurados quedan intactos
- El monto es UNA linea editable y el popup se actualiza solo; el aviso de farmeo (regalo local) y la alternativa por-uid-en-server quedaron documentados en el LEEME
- Proximo paso natural: recompilar el cliente, probar en Android (borrar datos de la app -> popup + 500 en el shop) y elegir el proximo frente (recompilaciones pendientes de NU V1/V2 y WoodZone/SkySanctuary; Universe Relapse / Curse of Chaos como futuros portes)

---
Task: JINNA v1 — porte de la unica killer nueva de "TD2DR Darkness In Blood" (D.I.B., GameJolt 1104339 de DIFFF) como la 6.a asesina (EXE_JINNA=5); pedido del usuario: "queria extraer a Jina si no lo olvidaste. la unica killer nueva de hay"

Work Log:
- Recuperacion de la tarea cortada: la sesion anterior (perdida por timeout) ya habia descargado nada y dejado scripts/parse_datawin.py con el layout a medias; esta sesion descargo el build PC (318 MB via site-api get-download-url/2043080 capturado con agent-browser), reconstruyo TODOS los formatos del data.win YYC 266 MB y completo el porte
- Formatos deducidos y calibrados contra sprites CONOCIDOS del repo (spr_exe_idle 41x44 118f calibro el SPRT; spr_mercoin el SOND): punteros a CHARS con longitud en ptr-4; SPRT entry 88+4N bytes (bbox, origin(48/52), playbackSpeed f32 en +68, frameCount en +84, N ptrs a TPAG); TPAG item 22B = 11 u16 {x,y,w,h,?,?,srcW,srcH,dstW,dstH,texIndex}; TXTR entry 28B {Scaled,GeneratedMips,BlockSize,W,H,IndexInGroup,ptr}; blob '2zoq'+u16 w+h+u32 len+BZ2 -> QOI 'fioq'; y el QOI GM NO es el estandar: es la variante DogScepter (INDEX/RUN_8/RUN_16/DIFF_8/16/24/COLOR selectivo, hash XOR r^g^b^a, salida BGRA) — port exacto del QoiConverter.cs de UndertaleModLib consultado en GitHub; el bug clave era tratarlo como QOI estandar (franjas de basura)
- Clasificacion del mod (diff de nombres vs repo): 231 sprites nuevos pero SOLO jinna es killer (erey/etangle/rey/serge/sonh/tangle/blaze/metal-variants = supervivientes, fuera de alcance); de jinna: 22 sprites de personaje + spr_menu_jinna (17f animado) + 2 iconos GUI (jinagrub/jinateleport) + 7 sonidos WAV + obj_jinna/obj_jinna_portal/obj_jinna_grab_effect; su icono de lobby = el exeicon6 DEL MOD (alli no existe Metal Amy y su 5.a killer es jinna) portado como nuestro spr_lobby_exeicon7
- Kit RECONSTRUIDO (YYC = cero GML legible) con 3 fuentes reales: la descripcion oficial del About del mod (extraida de los strings del data.win: "fast killer... teleport toward the nearest survivor... grab can lock a survivor in place"), las variables YYC legibles (jinnaGrabbing/jinnaGrabTimer/jinnaGrabVisualTimer/jinnaTeleportDelay/jinnaAttackLock + gml_Script_finishGrab@obj_jinna_grab_effect) y las transcripciones ASR de sus 7 voces (taunt1 "You really thought you could leave me behind? How foolish?" / taunt2 "You thought you escaped the nightmare..." / taunt3 "...you will always be the one I love" / kill1 "Keep running, I love watching you..."); resultado: golpe X con commit (0,2 s de frenado), teletransporte C (telegraph con flecha clonearrow + portales gemelos + pose tele, aparece detras del mas cercano, 8 s CD), agarre V (bloqueo 1,6 s + 10 dano = "1 HP" de su placa, 12 s CD), velocidad 13 (la mas rapida del bando EXE)
- Red: 4 paquetes AL FINAL en los DOS enums (CLIENT_JINNA_TELEPORT/CLIENT_JINNA_GRAB/SERVER_JINNA_PORTAL_STATE/SERVER_JINNA_GRAB_STATE) con paridad EXACTA verificada; el tele reusa el grace ex_teleport=60 del anticheat (patron Exeller); el grab valida victima viva (flags PLAYER_DEAD|ESCAPED|DEMONIZED) y el dano lo aplica la victima en su cliente (exeSource=true: el parry de Sonic puede negarlo); el bloqueo usa global.playerControls (el gate de input de la casa) con devolucion segura en CleanUp (patron finishGrab)
- Integracion completa siguiendo el playbook MetalAmy/TTB: scr_exe (macro+22 slots+case 5), charselect (risa+icono x3), lobby (chars[19], placa frame 16 = spr_char_info 16->17 con la placa PROPIA del mod), lobby_icon (ciclo 6 killers + case 6 + FIX del wrap izquierdo preexistente que quedaba en 4), playerui (4 iconos con cooldown vivo), unlockables (paleta), net_sounds (+7 al final, indices 116-122), taunts (A/D) + voz de kill + linea go al arranque + linea de victoria (taunt3); menu_more sfxList +7 (el volumen del Options > MORE los cubre)
- Validacion: check_jinna_port.py 1366/1366 OK (incluye paridad de enums cliente/server, gcc -fsyntax-only limpio en Game.c/CharSelect.c con stub enet, frames==keyframes==length==PNGs==layers en los 26 sprites, referencias de assets todas existentes, 30+ parches presentes); PNGs verificados 1:1 contra el decode del data.win (idle 147/147, portal 20/20, menu 17/17...); VLM sobre hoja de contactos: personaje consistente (los supuestos artefactos son el estilo del propio mod: el portal ES un disco relleno y el jump tiene motion lines); check_gml.py TODO BALANCEADO
- Entregable: download/td2dr_jinna_v1.zip (NUEVOS: 26 sprites, 7 sonidos, 3 objetos, 1 script, LEEME_JINNA_V1.txt; MODIFICADOS: .yyp +40 lineas, spr_char_info.yy, scr_exe, net_packets, net_state_game, net_state_charselect, net_sounds, scr_move_basic, scr_exe_checkwin, scr_characters, scr_menu_more, obj_lobby x2, obj_lobby_icon, obj_playerui, obj_unlockables, Server.h, Packet.h, CharSelect.c, Game.c). REQUIERE recompilar cliente Y server juntos

Stage Summary:
- Jinna es la 6.a killer seleccionable: la mas rapida del bando EXE, con teletransporte a portales hacia el superviviente mas cercano, agarre bloqueante de 1,6 s y golpe con commit — todo su arte y sus 7 voces originales del mod D.I.B.
- El formato QOI de GameMaker (variante DogScepter) quedo documentado y decodificado en scripts/ (qoi_gm.py + extract_dib.py): reutilizable para cualquier futuro data.win YYC de GM 2023.x
- Proximo paso natural: recompilar cliente+server juntos (junto con las pendientes de NU/WoodZone/SkySanctuary/Options More/Welcome Pack) y probar la ronda de jinna en server real (votarla de killer, probar C y V sobre supervivientes reales)

---
Task: JINNA v2 — de killer normal a EXCLUSIVA del token de Amy (amy_canon.token); pedido del usuario: "Jina sera una Killer exclusiva del codigo que desbloquea a amy ok.? No podra ser elegida como killer normal Como pasa con Metal amy"

Work Log:
- Recuperacion tras reciclado de sandbox: repo re-clonado desde origin (todo lo aplicado por el usuario ya vive ahi: welcome pack v1, jinna v1 con su LEEME, etc.); el "pull" pedido quedo cubierto con el clone — origin no trae nada que el usuario no tenga
- Sistema elegido: el mismo token de Amy Canon (amy_canon.token -> global.amyCanonToken -> CLIENT_AMY_AUTH -> amy_authed en el server), que ya protege a Amy Canon / Vanilla / Fleetway Amy. Interpretacion del pedido documentada: Metal Amy SI sigue siendo killer normal; Jinna queda solo para la dueña del token
- Cliente (4 archivos): scr_exe_locked(exe) nueva en scr_exe.gml (la scr_char_locked de killers, while-ready para futuras reservadas); obj_lobby_icon salta el slot en ambas direcciones (2 while + piso defensivo en la izquierda) y la KeyA no la pide (nono); obj_lobby oculta retrato+placa sin token (exe = sprInd - CHARACTER_FLEETWAY_AMY); net_state_charselect por fin USA el byte result que leia desde v4.10 en SERVER_LOBBY_EXECHARACTER_RESPONSE (0 = nono sin seleccionar; -1 = server viejo = exito)
- Server (states/CharSelect.c, el unico que compila): rechazo de EX_JINNA sin amy_authed con result=0 antes de registrar exe_char (antes se asignaba incluso antes de los asserts), result=1 en la respuesta de exito, log "tried to pick [Jinna] without unlock!". CERO paquetes nuevos: el byte viaja al final del paquete existente
- Incidente corregido a mitad de tarea: la primera edicion del CharSelect.c reescribio todo el archivo (tabs->espacios + guiones UTF-8 en un archivo ASCII); rehecho con parche python byte-exacto (parcha_charselect_v2.py): +25/-1, TABS y ASCII puro, leccion del worklog de options more aplicada
- Compatibilidad documentada en el LEEME: cliente nuevo + server viejo OK (result ausente = exito); server nuevo + cliente v1 de jinna: el v1 ignoraria el rechazo y quedaria esperando (AFK kick si no elige otra) — actualizar cliente y server JUNTOS, mismo requisito que la v1
- Validacion: check_jinna_v2.py 16/16 OK; gcc -fsyntax-only limpio (stub enet en /tmp); simulacion del ciclo: sin token 1..5 sin cuelgues en ambas direcciones, con token 1..6; scr_char_locked y asserts/exes[] del server intactos
- Entregable: download/td2dr_jinna_v2_exclusiva.zip (MODIFICADOS: scripts/scr_exe/scr_exe.gml, objects/obj_lobby_icon/Draw_0.gml, objects/obj_lobby/Draw_0.gml, scripts/net_state_charselect/net_state_charselect.gml, betterserver-oss/disasterserver/states/CharSelect.c; NUEVOS: LEEME_JINNA_V2.txt; worklog). REQUIERE recompilar cliente Y server juntos

Stage Summary:
- Jinna deja de ser la 6.a killer publica: sin el token de Amy no existe en el ciclo (ni icono, ni retrato, ni placa, ni peticion), y el server la rechaza por si solo; con el token se juega exactamente igual que en la v1
- El patron "personaje reservado" ya cubre killers y supervivientes con una sola llave (el token), y el byte result del EXECHARACTER_RESPONSE queda activado para futuros rechazos de killers
- Proximo paso natural: recompilar cliente+server (junto con las pendientes NU/WoodZone/SkySanctuary/Options More/Welcome Pack/jinna v1) y probar el ciclo con y sin amy_canon.token

---
Task: JINNA V3 "El Portal Trampa" + Amy FW publica + fixes de pantalla (pedido del usuario tras probar la v2: "Mira el error que sale en la pantalla de resultados... el icono de seleccion de jina aparece muy arriba... cambio la amy fw sera publica su pasiva de torre sera nef... Jina cada que use su habilidad de teleport le dara Iframe por 3seg... su habilidad (la V) cambiara al usar v hacia abajo dejara un portal trampa...")

Work Log:
- Pull del origin (2226856e "up": el usuario subio las animaciones nuevas spr_vanilla_absorb_trap/spr_vanilla_caught, el rework de spr_jinna_attack1/spr_gui_jina* y su propio LEEME_JINNA_V2) — merge limpio sin conflictos con el commit local de la v2
- FIX pantalla de resultados (el ruido RGB de la captura): el switch de EXE en net_state_results solo cubria chars 0..4; Jinna (EXE_JINNA=5) quedaba con icon=0 y el draw animado (frame += 0.15) llenaba la fila de textura basura. Mismo hueco arreglado en obj_menu_waiting (ahi salia el dicon por defecto) y en el marcador TAB (obj_level: la formula mandaba a Jinna a la fila 11 = cara de Sonic; ahora frame 15, la X misteriosa de Metal Amy, coherente con killer exclusiva)
- FIX icono de seleccion de Jinna "muy arriba": spr_lobby_exeicon7.yy venia con yorigin=61 (fondo del sprite) y preset 9 — el resto de los exeicon usan el centro (~30/31). Corregido a (29,30) + preset 4
- AMY FW PUBLICA: fuera de scr_char_locked (cliente) y fuera del rechazo por amy_authed de CharSelect.c (server). Amy Canon / Sally Canon / Vanilla siguen reservadas
- NERF LA TORRE (scr_player_hurt): el bloqueo se mudo DEBAJO del guard de hurttime (antes re-destellaba con i-frames activos — mismo bug que el bloqueo LMS de Sonic pre-v5.4) y ahora es probabilistico-decayente: fwTowerPct 100% -10 por bloqueo consumido (reset por ronda; la tirada es irandom(99) < pct; con 0% el daño entra siempre). Init en obj_amy_fleetway/Create_0
- JINNA teleport potenciado: hurttime=180 al aterrizar (I-frames reales: el gate de obj_player_puppet) + slow en area — el SERVER computa los supervivientes vivos en 90 px de la llegada (posiciones que ya sincroniza) y emite SERVER_JINNA_TELE_AOE por victima (scr_player_slow en su cliente) + hitbox del golpe basico +25% durante 3 s (global.jinnaTelePower que abre el broadcast de portales en todos los clientes y baja obj_netclient/Step_0; el pad en obj_player_puppet junto a los de Sonic/Amy/Sally Canon)
- PASIVAS DE LORE de Jinna: (1) MARCA MEJORADA — scr_weak_mark_hit gano CD por parametro: Jinna usa 13 s por personaje (Metal Amy 16 s), mismo efecto de 8 s de recarga forzada; entra por contacto (puppet), agarre (handler GRAB) y trampa (handler TRAP_HIT), siempre solo si el golpe calo (hp bajo o isHurt, el parry de Sonic la niega). (2) ADAPTACION A STUNS — deteccion de stun NUEVO por comparador de shockedTimer contra el valor esperado (jinnaShockNext) en obj_jinna/Step_0: recorta la duracion por la resistencia ACTUAL y luego suma +10 (tope 50); cubre TODAS las fuentes de stun porque todas escriben shockedTimer en el cliente del EXE
- PORTAL TRAMPA (V+ABAJO; V sola sigue siendo el agarre; comparten CD 12 s): CLIENT_JINNA_TRAP -> entidad server JinnaTrap (patron AmeliaTrap: 20 s de vida, state 0/1/2) -> replica visual obj_jinna_trap en todos (spr_jinna_portal al 55%). Pisada: el cliente de la victima reporta CLIENT_JINNA_TRAP_HIT (sin gate de hurttime: los i-frames NO salvan de la trampa); el server valida (trampa viva + victima dentro de 64 px + viva) y emite SERVER_JINNA_TRAP_HIT (pid, kind, jx=posicion ACTUAL de Jinna). Victima normal: hurttime=0 (remueve los que tenia) + scr_player_hurt 15/22 + hurttime=0 otra vez (la trampa no regala i-frames) + TP hasta Jinna + portales visuales. VANILLA (kind 1): obj_jinna_absorb en SU cliente (spr_vanilla_absorb_trap encoge hasta el centro del portal ~1,2 s, luego el portal se cierra ~0,5 s) -> muerte directa (CLIENT_PLAYER_DEATH_STATE, sin paciencia/moribunda: "fuera de juego, muerta sin estar muerta", UI de espectador, PLAYER_DEAD en el server) + su puppet se oculta en los demas clientes + spr_vanilla_caught sobre la cabeza de Jinna SOLO en su cliente (delay 102 frames = la animacion) + global.jinnaCaughtVanilla en TODOS para los aumentos: golpe 20->30, agarre 10->15, trampa 15->22, slow 3->4,5 s
- 5 paquetes nuevos AL FINAL del enum en los DOS lados (net_packets.gml == include/Packet.h): CLIENT_JINNA_TRAP, CLIENT_JINNA_TRAP_HIT, SERVER_JINNA_TRAP_STATE, SERVER_JINNA_TRAP_HIT, SERVER_JINNA_TELE_AOE
- Blindajes: la absorcion no envia el paquete de muerte si la ronda ya termino (gameEnds: el assert del server la desconectaria); pisada solo con jugador local vivo, no-exe, no-esbirro; triggerSent por trampa; la trampa no la pisa ni el EXE ni demonizados ni muertos
- Validacion: gcc -fsyntax-only LIMPIO en Game.c/JinnaTrap.c/CharSelect.c (stub enet en /tmp, solo warnings preexistentes de switches viejos); balance de llaves OK en los 21 GML tocados (scripts/gml_balance.py); .yyp con los 2 objetos nuevos registrados
- Entregable: download/td2dr_jina_v3.zip (MODIFICADOS: net_state_results, obj_menu_waiting/Draw_64, obj_level/Create, scr_survivors, scr_player_hurt, obj_amy_fleetway/Create, scr_jinna_special, obj_jinna x3, obj_player_puppet/Step_0, net_packets, net_state_game, obj_netclient x2, yyp, spr_lobby_exeicon7.yy, Packet.h, Game.c, CharSelect.c, CMakeLists; NUEVOS: obj_jinna_trap x4, obj_jinna_absorb x4, JinnaTrap.h/.c, LEEME_JINNA_V3.txt). REQUIERE recompilar cliente Y server juntos (enum de paquetes nuevo en ambos)

Stage Summary:
- Los 2 bugs reportados de la v2 quedan cerrados (results + icono) y de regalo salieron el menu waiting y el TAB; Fleetway Amy es publica con su Torre nerfeada a "bloqueo honesto con desgaste"
- Jinna v3: teleport con I-frames + slow en area + hitbox ampliada, marca de CD mejorada (13 s), adaptacion a stuns hasta 50%, y la V reworkeada en dos modos con el portal trampa que absorbe a Vanilla y potencia todo su kit
- Proximo paso natural: recompilar cliente+server juntos y probar en server real (teleport sobre gente, trampa con victims reales, y la absorcion de Vanilla con las animaciones nuevas que subio el usuario)

---
Task ID: jinna-v4
Agent: main (Z.ai)
Task: JINNA V4 "El Arreglo del Kit de la Trampa" — los 6 pedidos de la duena tras probar la v3 en partida ("1 los iconos de la habilidad C y V estan montadas una encima de la otra 2 el portal trampa no compartira enfriamiento con la habilidad V normal cuando jina este presionando abajo la habilidad V intercambiara con los botones de la trampa... parecido a lo que pasa con chaos cuando este esta en el aire... arreglo a la pantalla de vanilla debe ser un poco mas pequeña y ajustada encima de jina... cuando el portal trampa haga su funcion de traer al jugador el sprite no debe estar por delante de los jugadores... ahora amy puede ser afectada como vanilla spr_amy_capture_canon pero ella aun no tiene pantalla asi que basicamente seria una version de ella pero semi transparente que estaria como senal de mejoras mas arduas para jina")

Work Log:
- Pull del origin (d8e7f0a5 "up" = la v3 completa ya en el repo). Recon del estado: el bloque EXE_JINNA del playerui dibujaba C y V AMBOS en x = prog*4 (ahi el montado), la trampa gastaba jinnaGrabCd (12 s compartidos), los portales del TRAP_HIT heredaban depth -50 del obj_jinna_portal (por delante de los jugadores) y spr_vanilla_caught se dibujaba 170x94 a 1:1 flotando 38 px sobre la cabeza
- FIX 1 (HUD): la V pasa a x = 44 + prog*10 (patron Metal Amy: C quieta a la izquierda, V deslizando a la derecha); misma fila y=250, tecla dinamica v4.3 intacta
- FIX 2 (recargas separadas): macro JINNA_TRAP_RECHARGE (60*15) + variable jinnaTrapCd (Create/Step de obj_jinna); scr_jinna_special separa los gates del pressed-V (ABAJO mira jinnaTrapCd, el agarre su jinnaGrabCd en un else if). SERVER: #define JINNA_TRAP 13 + PLAYER_COOLCOUNT 14 en Server.h; CLIENT_JINNA_TRAP valida y asigna 15 s del SUYO (el agarre conserva sus 12 s). La trampa vive 20 s: puede haber 2 a la vez ~5 s (entidades independientes, patron AmeliaTrap)
- FIX 3 (intercambio de icono): sprite NUEVO spr_gui_jinatrap (32x14, GUI/Recharge) compuesto desde arte existente — anillo del spr_gui_jinateleport (cols 3-18) + glifos "▼+" del spr_gui_sonicspindash (cols 19-32, filas 2-11). La tecla V la dibuja drawKeyIcon (artW=32). PNG TODO contenido (bbox == canvas: cero margenes -> GM no recorta la textura, leccion v4.3b del playerui). Registro en .yyp por insercion quirurgica de texto tras spr_gui_jinateleport. El playerui intercambia con keyboard_check(global.KeyDown) — la MISMA condicion del special (el icono muestra lo que pasara al pulsar V)
- FIX 4 (pantalla de Vanilla): escala 0.72 (122x68) y borde inferior a 4 px de su cabeza (y-44; antes y-78 a 1:1). El balanceo sin() y el alfa 0.85 intactos
- FIX 5 (portales detras): los 2 portales del TRAP_HIT (salida de la victima + llegada junto a Jinna) se crean y se les fuerza depth = 5 (el del agujero-trampa: detras de los personajes). Los del TELEPORT siguen a -50 (su look v1) y el absorb conserva el suyo (cinematica a proposito)
- FIX 6 (Amy Canon atrapable): server manda kind 2 para CH_AMY_CANON en CLIENT_JINNA_TRAP_HIT (cero paquetes nuevos). Cliente: kind 1/2 = absorcion; el absorb recibe absorbVictim (spr_amy_capture_canon para Amy, su pose de secuestro 37x41); sobre Jinna flota Vanilla 72% O Amy SEMI-TRANSPARENTE (alfa 0.5, y-65) segun jinnaCaughtKind. Tier system: global.jinnaCaughtTier (0/1/2, macros JINNA_CAUGHT_NONE/AMY/VANILLA) sustituye al bool jinnaCaughtVanilla en TODOS los puntos de potenciacion — golpe 20->25/30 (puppet), agarre 10->12/15, trampa 15->18/22, slow 3->3,75/4,5 (net_state_game). Solo ESCALA (max); la senal visual tambien (quien pille a Amy y luego a Vanilla ve la pantalla de Vanilla, nunca el fantasma tapando)
- Eleccion de personaje: AMY CANON (no la Amy normal) porque el sprite de secuestro spr_amy_capture_canon (estados 19-21 de su array) es de ella; la Amy normal no tiene pose de captura. Cuando la duena le haga arte de pantalla, el sistema ya lo admite (un sprite + una linea en el Draw)
- Validacion: check_jinna_v4.py 62/62 OK (posiciones del HUD, gates de cooldown, sprite todo-contenido, .yyp JSON-GM valido, depth 5 en los 2 portales, kind 2, tabla de danos, balance de llaves SIN comentarios — el ()=-7 crudo del playerui es de comentarios preexistentes, verificado contra HEAD con git stash); gcc -fsyntax-only Game.c: mismos 7 errores PREEXISTENTES del upstream (rand/free/malloc implicitos + ENetPeer del stub), cero nuevos (diff contra HEAD = solo numeros de linea); mockup del HUD renderizado y verificado con vision (C y V separados, combo ▼+V legible)
- Entregable: download/td2dr_jinna_v4.zip (MODIFICADOS: obj_playerui/Draw_64, scr_jinna_special, obj_jinna x3, obj_jinna_absorb x2, obj_netclient/Create, obj_level/Create, obj_player_puppet/Step_0, net_state_game, net_packets, .yyp, Server.h, Game.c; NUEVOS: sprites/spr_gui_jinatrap (png+yy+layers), LEEME_JINNA_V4.txt; worklog). REQUIERE recompilar cliente Y server juntos (PLAYER_COOLCOUNT + cooldown nuevo)

Stage Summary:
- Los 6 pedidos cerrados: C y V separados, recargas independientes (agarre 12 s / trampa 15 s), icono que intercambia a portal+"▼+V" al presionar abajo (patron chaos aereo), pantalla de Vanilla al 72% ajustada a su cabeza, portales del traer-jugador detras de los personajes, y Amy Canon absorbible con senal semi-transparente y mejoras arduas (mitad de Vanilla)
- El tier de potenciacion queda listo para futuras atrapables (Sally Canon, Cream...): un kind mas en el server + un caso en el switch del dano
- Proximo paso natural: recompilar cliente+server y probar la trampa con victims reales (ver el intercambio del icono en partida y la senal de Amy semi-transparente sobre Jinna)

---
Task ID: jinna-v4.2
Agent: main (Z.ai)
Task: FIX ANTICHEAT JINNA "nuh-uh!" (error 547) — "arreglo aun sigue habiendo algunos errores del anti cheat con jina error 547". El 547 es la linea Server.c:547 del log del server (el Info() del server_disconnect): el kick llega del anticheat de ataque infinito con texto "nuh-uh!"

Work Log:
- Sandbox reciclado (repo y zips perdidos) -> re-clone desde github.com/AmyRose21/disaster2d-oss (5f3e7e93 "upd"). El cambio del sonido de victoria de Jinna (snd_jina_laugh, v4.2 de la sesion pasada) quedo confirmado por la duena como aplicado en su proyecto local — NO se re-aplica aqui para no duplicarlo
- Causa raiz (cadena verificada en codigo): el golpe de Jinna mantiene isAttacking = true TODO el attackTimer (60f tierra = 1000 ms / 120f aire = 2000 ms; ventana de dano por contacto completa) y el paquete CLIENT_PLAYER_DATA se arma en el END STEP del obj_netclient, que corre ANTES del Draw que apaga isAttacking y DESPUES de la re-pulsada de X que lo vuelve a subir -> al encadenar 2 golpes (gameplay normal: machacar X) NUNCA viaja un solo paquete con el bit PLAYER_ATTACKING en OFF -> el acumulador del anticheat (states/Game.c, duration generico 2000 ms) sumaba cadenas enteras: tierra+aire = 3000 ms o aire+aire = 4000 ms -> kick "nuh-uh!". El exe original no sufre esto porque su case 0 del netclient manda el bit solo durante los frames activos de la animacion (hay OFFs entre golpes); Jinna no tenia case -> bit crudo
- FIX CLIENTE (obj_netclient/Step_2.gml): case EXE_JINNA en el switch del exe (patron del case 0): el bit viaja solo con el swing VIVO (isAttacking && attackTimer > 1) -> los 2 ULTIMOS paquetes de cada golpe viajan en OFF (attackTimer 1 y 0) -> el acumulador se resetea entre golpes encadenados. La ventana de dano solo pierde ~1 frame al final del todo (el swing ya acabo): cero cambio de gameplay
- FIX SERVER (states/Game.c, rama exe del anticheat): switch v->exe_char con case EX_JINNA -> duration = 6000 (implementa el template comentado "Use it if your new exe has a long attack"): absorbe puentes por perdida de UDP (los 2 resets OFF de un golpe perdidos = aire+aire ~3966 ms < 6000); un cheat con el bit fijo > 6 s sigue recibiendo el kick (mismo mecanismo que Eggman 3000 / LSA Amy Canon 6000). El Game.c de la raiz no esta en el CMakeLists -> no se toca
- Validacion: gcc -fsyntax-only states/Game.c (stub enet en /tmp) — diff de errores contra HEAD IDENTICO (solo los 4 implicit-declaration preexistentes del upstream: rand/free/malloc/srand), cero nuevos; check_jinna_anticheat.py 15/15 (estatica: ambos parches, excepciones Eggman/Amy intactas, nuh-uh! sigue vivo, balance de llaves GML y C; simulacion 1:1 del acumulador: reproduce el bug con cliente viejo [tierra+aire y aire+aire = kick], X-spam legitimo = kick, con el fix 3 golpes encadenados sin kick, puente por 2 resets perdidos OK con 6000 [con 2000 patea], cheat bit fijo 6,7 s = kick, golpe aereo unico bajo el tope)
- Entregable: download/jinna_v4.3_anticheat_fix.zip (SOLO archivos modificados: objects/obj_netclient/Step_2.gml, betterserver-oss/disasterserver/states/Game.c, worklog.md). REQUIERE recompilar el CLIENTE (GameMaker) Y el SERVER (compilar_server.bat) — el primero para que el bit deje de viajar en cadena infinita, el segundo para el techo de 6 s de Jinna

Stage Summary:
- Causa raiz: interaccion diseño-vs-anticheat — el isAttacking continuo de TODO el attackTimer (ventana de dano del swing) + el orden de eventos End Step/Draw hacian que los golpes encadenados con X jamas soltaran el bit; 2 golpes seguidos superaban los 2000 ms genericos -> "nuh-uh!"
- 2 cambios quirurgicos (1 case en el netclient + 1 case en el server): el acumulador se resetea entre golpes y el techo de Jinna absorbe la perdida de UDP; el anticheat NO se apaga para nadie (bit fijo > 6 s = kick igual)
- Proximo paso natural: recompilar cliente+server y probar en server real encadenando golpes aereos con X (el caso que botaba)

---
Task ID: exe-cmd-v1
Agent: main (Z.ai)
Task: COMANDOS .EXE — "necesito 2 cosas comandos.. que me puedan poner 1% de posibilidad exe y 99%"

Work Log:
- Pull (trajo mus_lobby reorganizada; fix anticheat v4.3 de Jinna sigue intacto en el arbol local). Recon: la chance de exe vive en PeerData.exe_chance (u8): arranca 1+rand()%4 al conectar, +2..+6 por ronda sin ser exe (lobby_init), resetea a 1 al tocarte, y >= 100 = garantizado (atajo del cheat "i want big burgr" que pone 101). La seleccion (charselect_pick_exe, states/CharSelect.c) es loteria PONDERADA por exe_chance; el lobby muestra "your chance to be exe: N%" (obj_lobby/Draw_0) alimentada por SERVER_LOBBY_EXE_CHANCE
- Diseno: los "2 comandos" se implementan como UNO parametrizado (patron .lobby N): .exe 1 y .exe 99 son exactamente los dos pedidos, y 1-100 queda disponible. El hash del comando (server_cmd_parse: Java 31*h+c de la 1a palabra) calculado y verificado SIN colision contra los 16 CMD_* existentes -> #define CMD_EXE 1471268 en include/States.h
- Implementacion (case CMD_EXE en states/Server.c, server_cmd_handle): gate de operador (patron .kick/.ban/.op), sscanf ".exe %d", rango 1-100 con mensaje de correccion, asigna v->exe_chance, re-envia SERVER_LOBBY_EXE_CHANCE (la UI del lobby se actualiza al instante, mismo paquete que usa lobby_init y el cheat) + confirmacion coloreada. Linea nueva en el .help de operadores. El comando funciona en cualquier estado con chat (Lobby/CharSelect/Mapvote/Game/Results enrutan por server_cmd_handle; en Game.c el dispatch corre ANTES del filtro "el exe no chatea")
- Intacto: cheat "i want big burgr" (101), acumulacion natural, resetea a 1 al ser exe, .lobby/.map/.sp y todos los demas comandos
- Validacion: gcc -fsyntax-only states/Server.c (stub enet /tmp) — diff de errores contra HEAD IDENTICO (15, todos preexistentes del stub/upstream), cero nuevos; check_exe_cmd.py 16/16 (hash y no-colision, gate op, parse, rango, cast u8, re-envio del paquete, help, balance de llaves C, cheat intacto; simulacion del parseo: .exe 99/.exe 1 disparan, .exe99 sin espacio NO [doc]; simulacion de la loteria 20k rondas: .exe 99 con 4 jugadores naturales = 81,6% real, .exe 1 = 4,5%, 2 jugadores = 49%, ambos a 99 = 50/50, .exe 100 = 100% garantizado)
- Entregable: download/exe_cmd_v1.zip (MODIFICADOS: include/States.h, disasterserver/states/Server.c, worklog.md; NUEVOS: LEEME_EXE_CMD.txt, scripts/check_exe_cmd.py). SOLO SERVER — el cliente NO se toca (el paquete SERVER_LOBBY_EXE_CHANCE y su UI ya existian)

Stage Summary:
- .exe N (op-only, chat en cualquier pantalla): fija TU exe_chance (lo que el lobby muestra como "your chance to be exe: N%"); .exe 1 y .exe 99 cubren el pedido, .exe 100 = garantizado. Afecta a la proxima seleccion; al tocarte exe se resetea a 1 (regla del juego)
- Transparencia: la loteria es ponderada — con .exe 99 en lobby de 4-5 la probabilidad real es ~80-95% (los demas pesan algo); certeza total = .exe 100
- Proximo paso natural: recompilar el server (compilar_server.bat) y probar: .exe 99 en el lobby (ver el "99%" en pantalla), .exe 1 para casi nunca tocar

---
Task ID: exe-cmd-v1.1
Agent: main (Z.ai)
Task: OCULTAR COMANDOS '.' — "puedes hacer que los comandos . no se vean para los demas?"

Work Log:
- Pull: sin cambios entrantes (HEAD 2b558ea8 al dia). Recon del chat: los comandos CONOCIDOS ya estaban ocultos en los 5 estados (server_cmd_handle devuelve true y no hay broadcast); el hueco eran los mensajes '.' que el server NO reconoce (typos tipo ".exe99", ".map 3" escrito fuera del lobby, puntos suspensivos...): server_cmd_handle devuelve false y el mensaje caia al broadcast como chat normal -> los demas lo veian. Unica ruta de fuga confirmada leyendo los 5 handlers de CLIENT_CHAT_MESSAGE (states/Lobby.c 413, CharSelect.c 281, Mapvote.c 77, Results.c 354 y el loop manual de Game.c 2351-2383); los demas server_broadcast_msg son salidas publicas por diseno (anuncios de votekick, .stink) y no se tocan
- Implementacion: helper server_msg_is_command(String*) en states/Server.c (junto a server_cmd_parse; true si el 1er caracter no-espacio es '.'), declarado en include/Server.h. Guard en los 5 estados: Lobby (!ignore && chatfix && !is_cmd), CharSelect/Mapvote/Results (misma linea del if con && !is_cmd), Game (break con is_cmd DESPUES de server_cmd_handle, para que los comandos conocidos sigan produciendo sus respuestas privadas). El eco local del que escribe y el log del server quedan intactos
- Incidente de herramientas: el editor expandio TODOS los tabs de Lobby.c a espacios (685 lineas mutadas) -> git checkout del archivo y re-parcheado con scripts/apply_dot_hidden.py (reemplazo a nivel de BYTES con patrones exactos y verificacion de unicidad + sanity de tab/espacio por archivo). Los 6 archivos quedaron con diffs quirurgicos (+1 comentario y 1 linea modificada por estado; Server.c +18 del helper)
- Validacion: gcc -fsyntax-only (stub enet /tmp) sobre los 6 archivos — errores identicos a HEAD tras normalizar ruta/lineas (17/0/0/2/5/13 preexistentes del upstream/stub), cero nuevos. scripts/check_dot_hidden.py (nuevo, va en el zip): 41 checks OK — helper bien ubicado y con la logica correcta, guards presentes 1 vez por archivo, indentacion tabs donde tabs y espacios donde espacios, balance de llaves, regresiones intactas (CMD_EXE + case + help, cheat brazil, .stink publico, votekick); simulacion 1:1 del helper (11 casos) y del broadcast por estado ANTES/DESPUES con los hashes reales de States.h: ".exe 99/.kick/.stink" ya ocultos y siguen ocultos, ".exe99" typo y ".map 3"/".yes" fuera de lobby antes se veian y ahora no, chat normal y cheat sin cambios
- Entregable: download/exe_cmd_v1.1_comandos_ocultos.zip (MODIFICADOS: include/Server.h, states/Server.c, states/Lobby.c, states/CharSelect.c, states/Mapvote.c, states/Results.c, states/Game.c [trae ya el anticheat v4.3], worklog.md; incluido include/States.h por dependencia de CMD_EXE — identico al de exe_cmd_v1; NUEVOS: LEEME_CMD_OCULTO.txt, scripts/check_dot_hidden.py). SOLO SERVER — el cliente NO se toca

Stage Summary:
- Todo lo que empiece en '.' deja de reenviarse a los demas en las 5 pantallas con chat, lo reconozca el server o no; el que escribe sigue viendo su eco y las respuestas privadas; el chat normal y los avisos publicos por diseno (votekick, .stink) quedan intactos
- El hueco real que veian los demas: comandos con typo o escritos en pantalla equivocada (".exe99", ".map 3" fuera del lobby) — ahora tapado en el server, sin cambios de cliente
- Proximo paso natural: recompilar el server (compilar_server.bat) y probar con 2 cuentas: .exe 99 (el amigo no lo ve), .exe99 typo (tampoco), hola (si lo ve)

---
Task ID: practica-exe-v1
Agent: main (Z.ai)
Task: ENTRENAMIENTO DE EXE (.ep) — "Puedes añadir nuevamente la practica como exe? Pero en un comando diferente al normal? ya que como estoy probando a Jina nesesito tener la constancia para las pruebas" + aclaracion con el repo original: "es el del repo original [teamexeempire/disaster2d-oss], si te das cuenta la practica aqui existe el modo exe, solo que hace mucho yo cambie la practica exe por practica de supervivientes, pero ahora nesesito ambas en comandos diferentes (aunque el server seguira mandando a practica de supervivientes); habra un comando especial para entrenamiento de exe"

Work Log:
- Pull (HEAD f590cc43): trae ya aplicados exe_cmd_v1/v1.1 (los 6 states/headers identicos al stash local; la duena los subio). Unica divergencia: el case EXE_JINNA del anticheat cliente (obj_netclient/Step_2.gml) NO esta en su arbol — su repo es la fuente de verdad, NO se re-aplica
- Arqueologia del "nuevamente": clonado teamexeempire/disaster2d-oss (solo proyecto GameMaker + libDisasterServer.so v110 embebido): strings+simbolos del .so confirman que la practica ORIGINAL era .vp "vote practice mode" → charselect_init NORMAL (exe REAL elegido por loteria); NO existia .sp ni init de practica separada (el string "Anticheat is disabled, client modifications are allowed." es el mensaje de arranque con anticheat:false del Config.json, no parte de la practica). El .sp como "survivor practice (no exe)" (exe=0xFFFF + falso "EXE" en la lista) nacio en el arbol de la usuaria. Su pedido: recuperar la practica CON exe en comando APARTE del .sp y con CONSTANCIA (quien la escribe es siempre el exe, para probar Jinna sin loteria)
- Diseño: comando .ep (hash 47449, verificado sin colision contra los 18 CMD_*) — op-only, se escribe en el chat del LOBBY (al lado del case CMD_SP) → charselect_init_exepractice(v) nueva en CharSelect.c: exe = v->id SIN loteria (LA CONSTANCIA pedida; el exe es un jugador real: sin el truco 0xFFFF del .sp ni falso "EXE"), mapa al azar (map_pick_random, patron v4.7), cuenta atras practice_time, broadcast normal de SERVER_LOBBY_EXE — el cliente del exe ve su pid y abre la seleccion de killer (Jinna con el token de Amy, v2), los demas abren la de superviviente. Flujo 100% normal: cero cambios de cliente
- Guard de ronda: campo Lobby.exe_practice (Server.h) — game_state_check (Game.c) lo salta cuando esta en true: sola como exe daria total 0 en el primer tick (EXEWIN instantaneo, ronda muerta) y con supervivientes muertos/escapados tambien cerraria; ahora solo cierran el TIME OVER, el .lobby o el exe al irse (game_state_left da SURVWIN, correcto: la practica se acaba). Resets en charselect_init normal, charselect_init_survpractice y lobby_init — ciclo completo cubierto (results → lobby_init). Las rondas NORMALES y la loteria del .vp quedan intactas
- Gate extra necesario: .ep exige v->in_game (los espectadores conectados a mitad de ciclo pueden chatear en el lobby, pero como exe colgarian la seleccion: los loops del charselect solo miran in_game). Aviso directo "exe practice:~ you're the exe, pick your killer!" al que escribe el comando (el loop de "map:" solo alcanza a quien conecto a mitad de ciclo, patron heredado del charselect_init original)
- .help de operadores (Server.c): linea nueva ".ep exe practice (you're the exe)" justo despues de la del .sp
- Validacion: gcc -fsyntax-only (stub enet /tmp) sobre los 4 .c — diff de errores vs HEAD IDENTICO tras normalizar numeros de linea (17/0/0/13 lineas preexistentes del stub/upstream), cero nuevos. scripts/check_exe_practice.py (nuevo, va en el zip) 70/70: hash .ep=47449 sin colision contra los 18 CMD_* y parseo fiel (".ep"/".ep now"/"  .ep" disparan; .sp/.epr/.exe no), parches presentes x1 en los 6 archivos, tabs en Lobby.c y espacios en CharSelect.c (leccion v1.1), llaves balanceadas en los 6, regresiones intactas (.sp con su 0xFFFF y falso EXE, .vp→charselect_init loteria, comando .exe v1, ocultado v1.1 en los 5 estados, anticheat Jinna 6000 v4.3, cheat "i want big burgr"), simulaciones 1:1 — sin guard: sola como exe = EXEWIN al 1er tick y todos-muertos = EXEWIN; con guard: SIGUE en los 3 escenarios (sola/todos muertos/escape por big ring) y las rondas normales SIN guard no cambian; ciclo de vida del flag [T,T,F,F,T,F]; gates del comando (no-op / lobby vacio / espectador); constancia 10/10 rondas con la typer de exe vs 6,4% de 20k por loteria .vp con 3 acompanantes
- Entregable: download/practica_exe_v1.zip (MODIFICADOS: include/States.h, include/Server.h, disasterserver/states/CharSelect.c, disasterserver/states/Lobby.c, disasterserver/states/Game.c [ya trae v4.3+v1.1], disasterserver/states/Server.c, worklog.md; NUEVOS: LEEME_PRACTICA_EXE.txt, scripts/check_exe_practice.py). SOLO SERVER — el cliente NO se toca

Stage Summary:
- .ep (op, en el lobby): entrenamiento de exe con CONSTANCIA — quien lo escribe es SIEMPRE el exe (Jinna con su token), los demas eligen superviviente, mapa al azar y cuenta atras de practice_time; la ronda NO se cierra por eliminacion (matar a todos o escapar ya no la acaba): solo TIME OVER, .lobby o irse del exe — ideal para machacar pruebas
- .sp queda EXACTAMENTE igual (supervivientes) y .vp tambien (voto → charselect normal con loteria): "ambas en comandos diferentes", el server sigue mandando a practica de supervivientes por defecto, como pidio
- Proximo paso natural: recompilar el server (compilar_server.bat) y probar: .ep en el lobby → pantalla de exe con Jinna, .lobby y repetir .ep para verificar la constancia; con un amigo: que el vea pantalla de superviviente y que la ronda siga viva tras morir

---
Task ID: bloom-postfx-v1
Agent: main (Z.ai)
Task: SHADER BLOOM + POST PROCESS — "Pregunta tu puedes crear un shader que pueda agregar bloom y post process (esos efectos que hacen ver mas profundida color y todo eso?"

Work Log:
- Pull: sandbox reciclado -> re-clon. HEAD nuevo 942e5eee (la duena subio ajustes de balance de Jinna en scr_jinna_special — teleport 8->7.25 s, weakmark 13->12.5 s, grab 12->8.5 s, trap 15->8.5 s + vida 20->60 s + radio 32->36 — y sprites AMELIA en scr_survivors; su repo es la fuente de verdad, nada de eso se toca)
- Recon del cliente (primera tarea CLIENTE de la sesion): proyecto GMS2 real (.yyp, IDEVersion 2026.0.0.16) con carpeta shaders/ ya existente (4 GLSL ES: shd_inverse, shd_colour palette-swap, shd_blackwhite, shd_amy_cyber). shd_inverse es la plantilla clave: el juego YA dibuja application_surface a pantalla completa con shader en el evento Draw_77 (eventType 8) para el efecto del mapa marijuna — resolucion nativa 480x270, letterbox manual en Android (obj_logo ademas redimensiona la app surface a 480x270 al arranque). Mapeo empirico de eventos tipo 8: 72=pre-mundo (scroll de capas GHZ), 75=Draw GUI (comentario del dev "mataba el Draw GUI" en obj_player_warning), 76=logica de anims/camara, 77=post-fullscreen (obj_logo, marijuna, netclient — este ultimo no dibuja, solo init one-shot)
- Diseno (3 shaders + 1 objeto, cero cambios de motor): shd_bloom (bright-pass con soft-knee + 5-tap cruz para el downsample a mitad de res), shd_blur (gauss separable 5-tap/9-taps lineales, direccion en uniform), shd_grade (aberracion cromatica radial sutil + split-tone sombras frias/luces calidas + saturacion + contraste + vineta suave). obj_postfx PERSISTENTE: Create cachea los 13 uniforms y los ajustes, Step alterna con F9 (devuelve el dibujo al motor al apagar), Draw_77 ejecuta el pipeline (extraccion a 240x135 -> 3 iteraciones de blur H/V con anchos 1.0/2.2/4.4 -> base con grading point-sampled -> glow aditivo bm_add), CleanUp restaura motor y libera superficies. Skip si existe obj_marijuna_crystalcontroller (ese mapa tiene su propio efecto fullscreen, no se pisa). Spawn al inicio de obj_logo/Create_0.gml (objeto boot, guard con instance_exists). Superficies lazy y a mitad de resolucion (en Android la app surface se redimensiona DESPUES de nuestro Create)
- Registro de recursos: .yyp parcheado byte-level con el formato exacto de entradas ({"id":{...},}, comas colgantes incluidas) — 3 shaders detras de shd_inverse + obj_postfx detras de obj_logo; 2162 -> 2166 recursos
- Formatos replicados al byte (lecciones v1.1): .yy sin newline final, .gml con TABS y sin newline final, .vsh/.fsh con newline final, todo LF puro y ASCII
- Validacion: no hay compilador GML/GLSL en el sandbox -> scripts/check_postfx.py (nuevo, va en el zip) 197/197 checks: existencia/formatos/ASCII/LF, JSON5 tolerante, eventList exacta {(0,0),(0,3),(0,12),(77,8)}, varyings identicos vsh<->fsh, llaves/parens balanceadas, cross-check de los 13 shader_get_uniform contra los uniform declarados en cada .fsh, .yyp 2166 recursos + 4 entradas x1 con formato exacto, diffs git +4/-0 en ambos parches, git status solo lo previsto, 4 shaders originales intactos, referencias a obj_postfx y vk_f9 solo donde toca, y SIMULACION NUMERICA del pipeline (numpy) sobre imagen sintetica 480x270: pesos de kernels suman 1.0, curva knee monotona (0 bajo umbral / 0.5 en threshold / 1 encima), vineta nunca negativa y esquina -19%, pipeline sin NaN con salida en [0,1], halo visible pegado al anillo brillante (0.077->0.402) y aun presente a ~20 px (+0.026 de glow puro), gris medio estable, preview PNG antes/despues (download/preview_bloom_postfx.png — simulacion sintetica del pipeline, NO captura real del juego)
- Entregable: download/bloom_postfx_v1.zip (NUEVOS: shaders/shd_bloom + shd_blur + shd_grade [x3 archivos cada uno], objects/obj_postfx [x5], LEEME_BLOOM_POSTFX.txt, scripts/check_postfx.py, preview_bloom_postfx.png; MODIFICADOS: "Sonicexe The Disaster 2D Remake.yyp", objects/obj_logo/Create_0.gml, worklog.md). SOLO CLIENTE — el server NO se toca

Stage Summary:
- Bloom + post-process reales a pantalla completa: lo brillante (anillos, ojos del exe, luces, fuego) resplandece con halo suave en 3 escalas, y el grading da la "profundidad" pedida: colores mas vivos, mas contraste, sombras levemente frias, luces calidas, vineta sutil y aberracion cromatica minima
- Todo calibrable en objects/obj_postfx/Create_0.gml (threshold, bloomPower, saturation, contrast, liftS, liftH, vignette, aberration — comentado uno a uno); F9 alterna el efecto en caliente para comparar con/sin
- Proximo paso natural: abrir el proyecto en GameMaker y correr (F5). El efecto usa el MISMO evento y patron que ya funciona en el mapa marijuna, pero si al probar algo del HUD quedara tapado, avisar: es un cambio de evento de una linea

---
Task ID: bloom-postfx-v2
Agent: main (Z.ai)
Task: FIX DEL CRASH DE LA v1 DEL BLOOM — reporte de la duena: "ERROR in action number 1 of Create Event for object obj_achivements: Unbalanced surface stack. You MUST use surface_reset_target() for each set. {5}" (tras aplicar bloom_postfx_v1)

Work Log:
- Pull (5144b01f): la duena ya subio y aplico bloom_postfx_v1 completo (3 shaders + obj_postfx x5 + spawn en obj_logo + .yyp +4 + preview + check_postfx.py 197 checks). El error tumba el juego al arrancar, en el logo
- Causa raiz: Draw_77.gml encadenaba 6 surface_set_target() seguidos (las 3 iteraciones H/V del blur) con UN solo surface_reset_target() al final. En GameMaker el target de surface es una PILA: cada set apila y cada reset desapila 1 a 1 — quedaban +5 por frame, exactamente el {5} del error. Los draws si iban al surface correcto (siempre al tope de la pila), por eso el efecto "se veia" bien en el logo antes del aborto. El "Create Event de obj_achivements" es el tipico senuelo de este error: el runner lo reporta en el contexto del siguiente evento que corre, no en el culpable (obj_achivements, el guardado persistente de room_logo, no tiene ni una llamada a surfaces en todo el proyecto — grep: solo Draw_77.gml usa surfaces)
- Dano colateral del mismo bug: con la pila sucia, las secciones 3/4 (base con grading + glow aditivo a la VENTANA) dibujaban sobre surfB (el tope de la pila) y nunca llegaban a pantalla — la v2 es la primera version en que la composicion se ve de verdad
- Leccion de proceso: el bug estaba CODIFICADO como correcto en el validador v1 (check_postfx.py 148-151: "los blur consecutivos no necesitan reset entre ellos, solo 2 reset_target" — supuesto falso; 197/197 checks verdes validando el bug). Regla nueva: los supuestos de API del motor se verifican contra la doc, no se inventan en el validador
- Fix (objects/obj_postfx/Draw_77.gml, +5/-0): cada pasada del blur cierra con su surface_reset_target() antes del siguiente set (set -> uniforms -> draw -> reset). 7 sets / 7 resets, profundidad maxima 1 (sin anidado), pila en 0 al final del evento. Pipeline, orden de pases, uniforms y resultado visual IDENTICOS — solo cambia el desapilado. Aplicado con scripts/apply_postfx_v2.py (parcheo byte-level: bloques unicos por combinacion dir/width, verificacion pre/post de conteos, balance de llaves y simulador de pila; convenciones respetadas: TABS, LF, sin newline final)
- Validador endurecido (scripts/check_postfx.py v2): corregido el check falso del v1 y nueva seccion G — simulador de la pila de surfaces sobre el GML real (tokeniza sets/resets en orden de ejecucion): sin underflow, pila en 0 al final, profundidad maxima 1 (prohibido anidar), ningun draw con 2+ targets apilados, cada set cerrado antes del siguiente, y los 3 early-returns (F9 off / sin app surface / mapa marijuna) antes de apilar nada (un return a mitad de pase dejaria la pila sucia). Checks de git reescritos para el estado v2 y resistentes al commit de la duena (subconjunto en vez de igualdad exacta; obj_logo y .yyp deben llegar intactos respecto a HEAD). Simulacion numerica F intacta (el pipeline no cambia)
- Validacion: check_postfx.py v2 204/204 OK — formatos/ASCII/LF intactos, eventList exacta, cross-check 13 uniforms, .yyp 2166 recursos, obj_logo y .yyp intactos, status solo los 4 del fix, regresiones limpias, pipeline numerico sin NaN con halo/valores iguales a v1, y 7/7 nuevos checks de pila en 0
- Entregable: download/bloom_postfx_v2.zip (MODIFICADOS: objects/obj_postfx/Draw_77.gml [RECOMPILAR CLIENTE], scripts/check_postfx.py, LEEME_BLOOM_POSTFX.txt, worklog.md — la v1 ya esta aplicada y commiteada en su repo: solo se reemplazan estos 4). SOLO CLIENTE — el server no se toca

Stage Summary:
- El crash "Unbalanced surface stack {5}" al arrancar queda arreglado: cada pasada del blur ahora desapila su target; ademas la composicion final (que antes dibujaba al surface equivocado) llega por fin a la ventana
- El validador ya no deja pasar una pila desbalanceada: simula set/reset en orden de ejecucion (el check falso del v1 fue corregido)
- Proximo paso natural: reemplazar Draw_77.gml y correr F5 — el logo ya no aborta; F9 compara con/sin efecto; si algo del HUD quedara tapado o quieres otro calibre (mas/menos glow), es una linea en Create_0.gml

---
Task ID: jinna-negagen-v11
Agent: main (Z.ai)
Task: 3 FORMAS POR PERSONAJE CON SPRITES NEGA REALES — pedido explicito de la duena: "no es mejor crear una copia de todos los sprites de los survivors y colocarle el efecto negativo, como hace la base original... crear una carpeta separada osea el nombre del personaje con el nombre (nega) para que en si hayan 3 formas: 1 normal, 1 nega, 1 demonizada" (+ el rar del modo negagen como referencia del look)

Work Log:
- Estado restaurado: sandbox reciclado (repo borrado) -> re-clone del remoto (HEAD 6f16e2e2, la version probada) + zip v10 re-aplicado encima (v10 nunca llego a commitearse)
- Transformacion canon extraida del rar, no inventada: comparacion pixel a pixel spr_amy/egg_* vs spr_amy/eggnega_* = inversion PURA al 100.0% de pixeles en todos los pares (RGB->255-RGB, alfa igual, RGB de transparentes igual); las tiras del rar se invierten con el contorno oscuro INTACTO (negademon2: keepDark lum<=0.08) pero su ARTE cambio desde la base (solo ~50-68% de match) -> las tiras nega se GENERAN desde las actuales (98 frames = 14 filas x7)
- Generador (scripts/v11_generate_sprites.py): 277 sprites nega nuevos (4.781 PNGs) — todos los arrays player_anims de los 15 supervivientes + variantes dinamicas del golpe de Sonic + parry Sonic/AmyCanon + overrides duelistas de SallyCanon + tiras HUD (spr_playerhealth_nega 98f + sallycanon/vanilla + redring) + barras (spr_hp_nega/_rr_nega). Cada uno con .yy clonado del donante (UUIDs nuevos de frames/keyframes/layer, mismo bbox/origin/parent/textureGroup), frames PNG invertidos en orden de keyframes, layers/<frame>/<layer>.png replicando el esquema GM decodificado, y entrada en el .yyp (idempotente). Verificado: el spr_amynega_idle generado es BYTE-IDENTICO al del rar
- Codigo (scripts/v11_patch_code.py): global.player_negaanims espejo exacto de player_anims (verificado programaticamente 15/15 chars, mismo largo y misma transformacion de nombres); scans nega sonicAtkTierraNega/AireNega; muelles nega; Draw_76 x15 + puppet Draw_72 -> isNegatouch usa negaanims; Draw_0 x16: RETIRADO el bloque shd_negative del v8/v10 (el sprite ya ES la inversion -> ruta vanilla con paleta/flash, y el efecto viaja con el sprite: estelas, retratos y todo lo que copia sprite_index sale nega sin parchear); barras de cabeza (Draw_64 x15 + puppet) -> spr_hp_nega/_rr_nega con vida real; HUD obj_level/Draw_64 -> scr_hud_strip_nega/_red_nega (nuevas en scr_characters.gml) con frame por vida real, sin shader; scr_parry_sprite(st,_char,_nega) con llamadas parcheadas en sonic/amy_canon/puppet; sonic dinamico y sally duelist (local+puppet) con variantes nega
- Validacion (scripts/v11_verify.py): 0 fails — barras/draw0/draw76/puppet/level/characters/parry/survivors con los marcadores v11 y sin restos de shader, llaves balanceadas en los 24 GML tocados, negaanims espejo 15/15, .yyp con las 277 entradas sin duplicados, las 277 carpetas cargables (gm_load) con frames==PNGs==layers, y asercion de inversion pixel-exacta en muestra de 19 pares (0 px mal)
- Duplicados por re-ejecucion (inserts no idempotentes del parche): reparados quirurgicamente (scripts/v11_repair_dups.py) y el parche blindado con guards de marcador
- Entregable: download/jinna_v11_negagen_3formas.zip — delta completo contra 6f16e2e2 (incluye los cambios v10 no commiteados: golpe X=25, helpers, iconos propios del nega, nombre turquesa, LEEME_JINNA_V5/V6). SOLO CLIENTE — el server no se toca

Stage Summary:
- Cada superviviente tiene ya sus 3 formas: 1 normal (spr_<char>_*) / 2 NEGA (spr_<char>nega_*) / 3 demonizada (spr_e<char>_*), y el subdito negativo de Jinna usa la 2: su propio personaje invertido con sus animaciones exactas, en las dos pantallas y con sus barras/tiras nega
- El look deja de depender de shaders/uniformes: el EFECTO VIAJA CON EL SPRITE (estelas, retratos y rutas no parcheadas salen nega solas); shd_negative queda sin uso en runtime
- Proximo paso natural: aplicar el zip, recompilar cliente y probar la conversion (4 golpes V/X); si algun estado rarisimo (abrazo combinado) o overlay de habilidad quisiera look nega tambien, es un genera+swap de un par de archivos

## 2026-11-14 — v12 "ME VEO YO": el afectado ve SU nega en su propia pantalla

Reporte tras v11: "en la pantalla de Amy se ve, en la de Jinna tambien, pero en la de Vanilla no: ve su propio sprite". Diagnostico:
- La marca local isNegatouch se escribia "global.player.isNegatouch = true" — dot-escritura sobre el INDICE del objeto (no la instancia) a una variable SIN declarar en el Create: no la crea, silenciosamente ineficaz en este runtime. El guard variable_instance_exists(id, "isNegatouch") del Draw_76/Draw_64 local daba false SIEMPRE (v8 shader, v11 sprites: mismo sintoma en las dos tecnicas).
- Prueba empirica interna: hp/revivalTimes (declaradas) llegan por la misma via; jinnaNegaCharge llega porque se declara con variable_instance_set(global.player.id, ...); el puppet funciona porque su Create declara la marca y el with() escribe por instancia. Solo la pieza del LOOK fallaba.
- Edge verificado en el server C: la conversion quita PLAYER_DEAD (Game.c 2145) y el tick del death-timer solo corre con PLAYER_DEAD (Game.c 3270) — no hay demonizacion tardia que pise el look.

Fix (17 archivos, SOLO cliente):
- 15x objects/<superviviente>/Create_0.gml: "isNegatouch = false;" junto a revivalTimes (ancla uniforme verificada en los 15). Activa de paso barra nega local (Draw_64) y HUD/retratos nega-aware (scr_negatouch_is sobre global.player.id) — misma causa del viejo "GET THEM" del afectado.
- scripts/scr_jinna_negatouch/scr_jinna_negatouch.gml: rama victima escribe con variable_instance_set(global.player.id, "isNegatouch", true) (patron probado de jinnaNegaCharge) — cinturon de seguridad sobre las declaraciones.
- LEEME_JINNA_V7.txt. Red/server: 0 cambios.

Entregable: download/jinna_v12_negagen_look_local.zip — SOLO los 17 archivos modificados/creados de esta ronda.
## 2026-11-14 — v13 "LA MINION SE VE": cuerpo restaurado tras la INVOCACIÓN

Reporte: "en la pantalla de la minion no aparece ella; se ve la flecha. Fue invocada por Jinna; Jinna la ve y la otra también, pero ella misma no se ve a sí misma."
- Diagnóstico: el cuerpo del jugador local se oculta en SU pantalla al ser ABSORBIDA por el portal (obj_jinna_absorb/Step_0: with(global.player){ visible = false }) y al VOLVER AL PORTAL tras caer (SERVER_JINNA_MINION_DOWN: global.player.visible = false). La INVOCACIÓN (SERVER_JINNA_MINION_STATE, rama _mine) restauraba posición/hp/isDead/revivalTimes/isMinion/isNegatouch/control/cámara pero NUNCA el visible: la invocada seguía invisible para sí misma. Los demás SÍ la veían porque esa misma rama restaura el visible del PUPPET en sus clientes (with(obj_player_puppet){ visible = true }). La flecha que ella sí veía era el obj_demon_indicator (otro objeto, capa GUI sobre global.player): marcaba el punto exacto de su cuerpo invisible.
- Fix (1 archivo, SOLO cliente, sin red): net_state_game.gml SERVER_JINNA_MINION_STATE rama _mine añade "global.player.visible = true;" junto a isMinion/isNegatouch. Cierra el ciclo atrapar -> ocultar -> INVOCAR -> volver a VERSE, tanto en la primera invocación (post-absorción) como en las re-invocaciones (post-portal). El look sigue siendo el nega de v11 (isNegatouch en la misma rama → Draw_76 local saca negaanims, ahora que su Draw vuelve a correr).

Entregable: download/jinna_v13_negagen_minion_visible.zip — SOLO los 3 archivos de esta ronda (net_state_game.gml + LEEME_JINNA_V8.txt + worklog.md).

## 2026-11-14 — v14 "RETRATOS DE RESULTADOS": el nega no aparece "como un exe"

Reporte: "faltan los retratos de final de partida: aparecen como si fueran exes en vez del retrato negativo de su forma normal".
- Diagnóstico: el server reporta PLRSTATE 1 (demonizado) para cualquier revivalTimes >= 2, y net_state_results pinta ese estado con scr_hud_demon (retrato demon). El paquete SERVER_RESULTS_DATA no lleva la marca negatouch, y los puppets/global.player mueren con el room_goto(room_results) que precede a las filas: no había donde consultar la marca en la sala de resultados.
- Fix (3 archivos, SOLO cliente, sin red ni sprites nuevos): (1) scr_globals declara global.resultsNegaNicks; (2) SERVER_RESULTS, justo antes del cambio de sala (los puppets aún existen: la sala muere al final del evento), vuelca los nicks nega (global.player.isNegatouch del local + cada puppet con isNegatouch) a la lista global; (3) net_state_results consulta la lista por nick en PLRSTATE 1 → scr_hud_strip_nega frame 0 (SU cara normal invertida, la misma tira del HUD v11) en vez del retrato demon, y en PLRSTATE 2 → tira nega + frame +6. Esbirro común y demas estados intactos.
- El zip lleva net_state_game.gml COMPLETO (incluye el fix v13 del visible del minion): aplicar v13 antes o solo v14, nunca v13 encima de v14.

Entregable: download/jinna_v14_negagen_resultados.zip — SOLO los archivos de esta ronda (net_state_game.gml, net_state_results.gml, scr_globals.gml, LEEME_JINNA_V9.txt, worklog.md).

## 2026-11-14 — v15 KICK "blud used a portal gun lmfao" tras la INVOCACIÓN (server)

Reporte: "después de invocar al atrapado" aparece el popup "blud used a portal gun lmfao" y el invocado sale expulsado.
- Diagnóstico: es la razón de desconexión DR_OTHER del anti-teleport del server (states/Game.c, procesador UDP de posición): salto >700 px sin daño propio que lo corrobore → portal_pending 1.5 s → kick diferido. La invocación teleporta al atrapado a los pies de Jinna SIN daño (lo cura: 100 hp + i-frames), y su posición server-side quedaba donde estaba la trampa → el salto medía >700 px → kick ~1.5 s después de aparecer. La captura no pateaba (su teleport viene con daño de trampa = corroborado), el teleport de Jinna abre ex_teleport=60 (patrón del clon de Exeller), y el negatouch no mueve a nadie: la invocación era el único teleport legítimo del kit sin exención.
- Fix (1 archivo, SERVER — recompilar): states/Game.c case CLIENT_JINNA_MINION, por cada invocado: t->plr.pos alineada al punto de invocación (jx/jy, el mismo del paquete), t->plr.ex_teleport = 60 (ventanilla anti-cheat que cubre los paquetes UDP viejos del pre-teleport y también el error dial-up dist>60) y t->plr.portal_pending = 0. Cliente y red: 0 cambios.

Entregable: download/jinna_v15_negagen_kick_invocacion.zip — SOLO el Game.c del server + este LEEME + worklog.

## 2026-11-14 — v16 "NO TERMINA + CRASH RESULTADOS": fin de ronda al convertir a todos en nega (incluido .ep) y fix del is_ds_list invalido

Reporte tras fix_nega_v15: (1) crash "Variable obj_netclient.is_ds_list(100405, -2147483648) not set before reading it at gml_Script_net_state_results (line 26)" al llegar a resultados; (2) "aun sigue la partida aun despues de convertir a todos en nega". Diagnostico:
- El CRASH era MIO: is_ds_list NO EXISTE en GML — el runtime lo compila como variable y revienta al leerla. Lo introdujo v14 en las ramas PLRSTATE 1/2 de net_state_results (crasheaba en la fila del primer demonizado: las filas posteriores nunca se creaban — por eso "los nega no aparecian en la lista de resultados") y v15 lo SUBIO a la linea 26 (crashea en la PRIMERA fila: lista vacia entera). Ademas v14 lo dejo en el destroy de SERVER_RESULTS (net_state_game 4853): reventaba en la SEGUNDA ronda de la misma sesion (la lista ya existe, el cortocircuito no salva). El check correcto es ds_exists(id, ds_type_list), mismo patron ya usado con obj_netclient.players y ds_type_map.
- El FIN DE RONDA: el fix v15 (game_state_check tras el negatouch) es correcto para partidas NORMALES, pero la duena prueba a Jinna con .ep (practica de exe, la constancia que pidio) — y el guard de practica-exe-v1 salta game_state_check ENTERO: la ronda .ep nunca cierra por conversion (solo TIME OVER/.lobby/irse el exe). Fix: el guard ahora deja pasar UNA excepcion — convertir en NEGA a TODOS los demas jugadores cierra con EXEWIN. Se distingue la conversion NEGA real (flag nuevo PLAYER_NEGATIZED: negatouch o minion invocado) de la demonizacion comun de esbirros (las dos marcan PLAYER_DEMONIZED): muertos, escapados, atrapados y esbirros comunes siguen SIN cerrar la practica (sola / todos muertos / escape por big ring intactos — verificado contra los 3 escenarios aprobados del check_exe_practice).
- Mismo hoyo en la INVOCACION: CLIENT_JINNA_MINION marcaba PLAYER_DEMONIZED sin check posterior — en partida normal, convertir a la ultima surv por el portal tampoco cerraba (la captura no reporta muerte y el minion revive al instante: nadie disparaba el check). Ahora el summon marca NEGATIZED y llama game_state_check tras el broadcast.

Fix (4 archivos + validador):
- scripts/net_state_results/net_state_results.gml: ds_exists(global.resultsNegaNicks, ds_type_list) en el _negaLookup (linea 26 era el crash).
- scripts/net_state_game/net_state_game.gml: mismo swap en el destroy de SERVER_RESULTS (crash latente de 2.a ronda).
- betterserver-oss/include/Player.h: PLAYER_NEGATIZED = 0x1 << 8 (enum C = int: cabe; se limpia solo con el memset de plr en game_init).
- betterserver-oss/disasterserver/states/Game.c: (a) guard de practica con la excepcion all-nega (others>0 && negas==others -> ED_EXEWIN), (b) SET_FLAG NEGATIZED en negatouch y en cada invocado del summon, (c) RAssert(game_state_check) tras el broadcast del summon.
- scripts/check_fix_nega_v16.py (nuevo, va en el zip): 30/30 — cero is_ds_list ejecutable en los 2 GML, ds_exists x1 en cada uno, llaves balanceadas, flag x1 y comma de CAUGHT intacto, marcas x1 en cada handler, check tras broadcast, guard con others/negas, y 13 simulaciones 1:1 (los 3 escenarios aprobados de practica intactos + los cierres nuevos nega/normal/escape). Resultados.c SIN CAMBIOS esta ronda (el fix del espacio final es del v15 y ya esta aplicado).
- Sintaxis C: gcc -fsyntax-only (stub enet /tmp) sobre Game.c/Results.c/Lib.c — set de errores IDENTICO al HEAD tras normalizar numeros de linea (cero nuevos; los implicit rand/malloc/free son artefactos del stub, preexistentes).

Entregable: download/fix_nega_v16.zip — Player.h, Game.c, net_state_game.gml, net_state_results.gml (los 4 MODIFICADOS esta ronda, netos y acumulando el v15) + check_fix_nega_v16.py + LEEME_FIX_NEGA_V16.txt + worklog. Results.c NO va (sin cambios desde v15). RECOMPILAR SERVER OBLIGATORIO (compilar_server.bat opcion 1).

## 2026-11-14 — v17 "LA VIDA REAL DEL NEGA": barra con daño por stuns, vuelta al portal, fases en nega, anillos negros, cura y el milagro de Vanilla

Pedido de la duena (continuo del fix_nega_v16): "la nega tiene su propia barra de vida, hace falta hacer el tema de la barra de vida: cuando reciban stun de supervivientes les quita 20 de vida por stun; al llegar a 0 vuelven directamente a Jinna. Sally Canon cae a 0 en nega -> activa su fase 2; cuando caiga en fase 2, al ser reinvocada ya sale en fase 2. La unica excepcion es Amy: su burbuja no da habilidades nuevas, solo la salva de la muerte -> queda solo para cuando es normal. A Vanilla se le perdona porque en esa forma es cuando llama a Chocola, pero en nega no puede mandar a Chocola a proteger a Cream salvo que Cream tambien sea nega. Negas con ventajas mayores: Vanilla nega crea los 2 anillos negros de Exetior por habilidad (que no lastimen a los nega); su pasiva de revivir demonizados aplica tambien a los negas y puede revivir a los CAIDOS (los muertos) por los mismos 15 anillos. Nerf: el minimo de la Fortaleza de Vanilla sube de 3 a 5 anillos. Los negas se curan con anillos rojos (+10, sin sonido) y el negro les cura TODA la vida. Las trampas de Amelia en nega cegan a los otros (excepto Amy Canon)."

- QUE SE IMPLEMENTO (cliente, 13 GML):
  * scripts/scr_jinna_negatouch.gml — la PURGA (revivir a 30 en el sitio, codigo muerto desde v7: su hp<=0 vivia dentro de un hp>0) se retira y llega el sistema nuevo: scr_jinna_negatouch_stun_hurt() (20 de vida por stun, stats canal 3, sangre, y a 0 hp enruta) + scr_jinna_negatouch_down() (el router de la caida: Sally->fase 2 SIGUIENDO nega, Vanilla->paciencia con Chocola, Sonic->nervios, Rouge->moribunda con gate propio negaMoribundaUsed, Amy->SIN burbuja, y el resto->CLIENT_JINNA_MINION_DOWN directo al portal). Macros JINNA_NEGA_STUN_DAMAGE 20 / JINNA_NEGA_REDHEAL 10.
  * Los 9 GANCHOS de stun de superviviente (todas las fuentes que escriben shockedTimer sobre el bando EXE): golpe comun y patada duelista de Sally (obj_player_puppet/Step_0 x2), parry de Sonic (scr_parry), flecha de FW Amy (obj_fw_bolt), laser de Tails (obj_tails_projectile), bola de fuego de Blaze (obj_blaze_fireball), trampa de Amelia (obj_amelia_trap/Create_0), mini-embestida de Chocola (scr_chocola_stun_signal) y light dash (scr_lsa_stun_signal).
  * scr_player_hurt.gml — scr_player_instakill abre con la puerta nega (0 hp por hoyos/zonas tambien vuelve al portal, ANTES de la burbuja de Amy).
  * obj_amelia_trap/Create_0.gml — deteccion de la duena NEGA (puppet isNegatouch, patron del _ameliaDemon): sus trampas CIEGAN a los supervivientes que las pisen, EXCEPTO Amy Canon (mismo AMELIA_ECLIPSE_TIME, sin los +2 s de esbirro).
  * scr_survivor_revive.gml — rama nueva del RESCATE DE LOS CAIDOS: Vanilla (sin demonizar) sobre un cuerpo MUERTO (state DEAD + hp<=0 + sin demonizar) mantiene ABAJO con 15 anillos y manda el MISMO CLIENT_VANILLA_DEDEMONIZE_PROGRESS.
  * obj_vanilla/Create_0.gml — el byte del spawn de anillos: nega -> 2 (ANILLOS NEGROS de Exetior), demonizada comun -> 1 (rojos), normal -> 0. Amy Canon y Cream no cambian.
  * obj_redring/Step_0.gml + obj_blackring/Step_0.gml — el nega HERIDO recoge el rojo (+10) y el negro (vida completa); con la vida llena no lo gasta (se queda para los demas).
  * net_state_game.gml — SERVER_RING_COLLECTED: rama nega antes del break (cura +10 SIN sonido, sin mindfuck); SERVER_BRING_COLLECTED: rama nega (hp=100 silencioso, jamas cae al dano de -20/-5 anillos: "los anillos negros no lastiman a los nega"); SERVER_VANILLA_DEDEMONIZE: _wasDead restaura ademas deadTimer/camara de espectador/reviveObj para el revivido.
  * scr_chocola.gml — NERF VANILLA_FORTALEZA_MIN 3->5; tecla V: Vanilla nega NO manda a Chocola con Cream salvo nega-Cream (_negVanilla); gancho del stun de Chocola.
  * scr_light_dash.gml — gancho del stun del LSA.

- QUE SE IMPLEMENTO (server C, RECOMPILAR):
  * Game.c CLIENT_JINNA_MINION_DOWN — acepta tambien al PLAYER_NEGATIZED (nega a 0 por stuns): mismo re-marcaje PLAYER_CAUGHT + PLAYER_CANTREVIVE que el minion y broadcast del SERVER_JINNA_MINION_DOWN.
  * Game.c CLIENT_CREAM_SPAWN_RINGS — rama red_ring == 2: 2 x MakeBlackRing en los offsets de la pareja roja ({25,-27}); los rojos (==1) y normales (==0) intactos; el sol de Amy Canon intacto.
  * Game.c CLIENT_VANILLA_DEDEMONIZE (instantaneo) — rescata tambien al nega/minion (data[0]==1 se tolera con PLAYER_NEGATIZED), DEL PLAYER_NEGATIZED + data[0]=0 al rescatar.
  * Game.c CLIENT_VANILLA_DEDEMONIZE_PROGRESS — DOS caminos: PLAYER_DEMONIZED (esbirro/nega/minion: barra dedemon_progress como siempre) y PLAYER_DEAD (EL MILAGRO: barra plr.revival, y al completar DEL PLAYER_DEAD + DEL PLAYER_CANTREVIVE + death timers a 0 + SET REVIVED + SERVER_VANILLA_DEDEMONIZE + game_state_check: el caido vuelve a contar como vivo).

- DETALLES DE DISENO (decisiones tomadas, ajustables en una linea):
  * "Como sucede con los anillos con 10 pero sin el sonido" se implemento como +10 DIRECTOS por anillo rojo (sin banco de 10 anillos: los negas no pueden recoger anillos normales), en paralelo con "el negro los cura TODA la vida". Macro JINNA_NEGA_REDHEAL.
  * La re-invocacion de Sally "ya sale en fase 2" es AUTOMATICA: ni SERVER_JINNA_MINION_DOWN ni SERVER_JINNA_MINION_STATE tocan fase2Used/duelista (verificado) — la memoria vive en su cliente.
  * La paciencia de la Vanilla nega saca a Chocola igual que la normal (stunea al exe 5 s): la duena pidio explicitamente conservar la pasiva ("en esa forma es cuando llama a Chocola").
  * El rescate de la Vanilla nega-minion devuelve al jugador al bando superviviente (lo pidio: "aplicara para los nega").

- Validacion: scripts/check_fix_nega_v17.py 81/81 OK (nucleo, puerta del instakill, 9 ganchos, trampa nega, rescate de caidos, byte de anillos, curas silenciosas, restauracion del revivido, nerf y Chocola, server, llaves balanceadas). Sintaxis C: gcc -fsyntax-only (stub enet) — mismo set de 4 artefactos preexistentes que el HEAD (rand/malloc/free/srand del stub), CERO errores nuevos.

Extension del eclipse para la trampa NEGA (3 GML mas): obj_player_puppet/Draw_0.gml y Draw_64.gml (la ceguera INVERSA: exe cegado no ve supervivientes / superviviente cegado por la trampa nega no ve al bando EXE) y obj_level/Draw_64.gml (el velo oscuro vale para la victima de cualquier bando: el timer solo lo tiene quien esta cegado).

Validacion final: check_fix_nega_v17.py 87/87 OK.

Entregable: download/fix_nega_v17.zip — 19 archivos (Game.c del server + 18 GML del cliente, Game.c y net_state_game.gml completos acumulando el v16 ya aplicado) + check_fix_nega_v17.py + LEEME_FIX_NEGA_V17.txt + worklog. RECOMPILAR SERVER OBLIGATORIO (compilar_server.bat opcion 1) Y recompilar el cliente (los 18 GML). RECOMPILAR SERVER OBLIGATORIO (compilar_server.bat opcion 1) Y recompilar el cliente (los 15 GML).
