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
