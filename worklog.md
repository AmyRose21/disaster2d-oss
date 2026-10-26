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
