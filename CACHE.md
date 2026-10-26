# ============================================================================
# CACHE.md — Índice de contexto del proyecto (TD2DR "Amy Canon")
# ============================================================================
# "Modo cache" del asistente: mapa de QUE ES cada cosa del proyecto, para no
# re-explorar el repo desde cero en cada sesion. Se lee AL INICIO de cada
# sesion, junto con worklog.md (la bitacora de QUE HICIMOS y CUANDO).
#
# PROTOCOLO (para el asistente, en toda sesion futura):
#   1. Leer ESTE archivo completo + la cola de worklog.md ANTES de tocar nada.
#   2. Antes de editar codigo: buscar el modulo aqui (indice abajo) e ir
#      directo al archivo indicado. No re-explorar con grep a ciegas.
#   3. Tras aplicar un cambio: actualizar la seccion afectada de aqui, anadir
#      linea en el CHANGELOG (seccion 11) y seguir escribiendo worklog.md.
#   4. Si el usuario reporta un bug/feature nuevo: anotarlo en seccion 9
#      (PENDIENTES) en el mismo momento.
#   5. Este archivo = mapa estatico (QUE ES cada cosa). worklog.md = historia
#      cronologica (QUE HICIMOS). No duplicar el worklog aqui.
#
# INDICE: 1 workspace | 2 juego | 3 cliente | 4 personajes | 5 flechas
#         6 server | 7 mods (7.1 = endings v2) | 8 convenciones | 9 pendientes
#         10 herramientas | 11 changelog
# ============================================================================

## 1. WORKSPACE /home/z/my-project
- disaster2d-oss/ ........ EL REPO DEL USUARIO (github.com/AmyRose21/
                          disaster2d-oss), clonado en la raiz del workspace.
                          La RAIZ del repo ES el proyecto GameMaker (.yyp
                          "Sonicexe The Disaster 2D Remake", 1.1.0 FINAL
                          110v): objects/, scripts/, sounds/, sprites/,
                          rooms/, extensions/... 302 objetos, 67 scripts,
                          947 sprites, 30 rooms. DENTRO vive
                          betterserver-oss/ (el server C, ver seccion 6).
                          En la raiz viven tambien worklog.md (bitacora),
                          CACHE.md (este archivo) y LEEME_ENDINGS_V2.txt.
- worklog.md ............. bitacora de TODAS las operaciones (por Task ID).
- CACHE.md ............... este archivo (mapa estatico del proyecto).
- scripts/ ............... (workspace) herramientas Python propias: NO
                          EXISTEN en este sandbox (rollback); si una tarea
                          futura necesita un aplicador/validador, hay que
                          recrearlo (el diseno exacto de cada uno esta
                          descrito en su entrada del worklog).
- download/ .............. entregables (zips) para el usuario.
- upload/ ................ archivos que sube el usuario (capturas, etc).
- skills/, tool-results/ . infraestructura del sandbox. NO tocar.
- (El material de recon original —MODDING_PLAN.md, td2dr/ con 100v y
  servers TTB— ya no existe en este sandbox; lo importante vive resumido
  en worklog Tasks 5-7.)

## 2. EL JUEGO
- Fangame "Sonic.exe: The Disaster 2D Remake" (TD2DR), dev: hander, motor
  GameMaker. Asimetrico 1 vs N: un EXE (asesino) caza a los survivors en un
  mapa con timer; los survivors sobreviven y escapan por el anillo
  (obj_bigring). Version 1.1.0 en hiatus; solo se juega en servidores
  privados (LAN / VPN: Radmin, ZeroTier).
- Flujo de partida: room_logo -> room_menu -> charselect -> room_lobby ->
  votacion de mapa -> room_<mapa> -> room_results -> (repite).
- Red SERVER-AUTHORITATIVE en C (ENet UDP + TCP). Puerto 8606, protocolo
  1101, ping maximo 250 ms (el error "Version Outdated" = ping alto).
- Estados de red (scripts net_state_*): pending, charselect, lobby, game,
  results, vote.

## 3. CLIENTE GAMEMAKER (raiz del repo: objects/, scripts/, sounds/...)
### 3.1 Nucleo del jugador
- global.player ......... el objeto del personaje LOCAL de este cliente.
- obj_player_puppet ..... como ven LOS DEMAS a tu personaje (replica por red).
   En el cliente del EXE los survivors son puppets y viceversa. Su Step_0
   aplica stuns/golpes + hacks especiales (martillo de Amy, pads de hitbox).
- obj_camera ............ camara. Todo Draw GUI dibuja restando
   (obj_camera.x, obj_camera.y); usar ceil() para nitidez.
- Otros: obj_playerui (HUD), obj_damage, obj_corpse_* (cuerpos por personaje),
  obj_revival_puppet (revivir), obj_hiding_parent (esconderse),
  obj_player_sensor{L,R,T,B,TL,TR,BL,BR} (colisiones del cuerpo),
  obj_player_warning, obj_spawnpoint, obj_exespawn.
### 3.2 Red (scripts/)
- net_client (conexion), net_packets (formato de paquetes), net_indentity,
  net_state_{pending,charselect,lobby,game,results,vote}, net_sounds,
  net_projectile, net_wrapper, net_tcpprocess, net_udpprocess.
- Objetos: obj_netclient, obj_connecting, obj_message, obj_warning.
### 3.3 Menu / lobby
- obj_menu + obj_menu_* (characters, skins, taunt, money, votekick,
  waiting, join, pet, secret...), obj_lobby_* (fire, blood, prolet, white,
  waiting, votekick, icon), obj_unlockables, obj_achivements.
### 3.4 Mapas (rooms) y sus gimmicks (objetos por prefijo)
- room_greenhill (ghz_*), room_angelisland (aiz_*: zipline/bush/palm),
  room_ravinemist (ravinemist_* + obj_ravintmist_shard),
  room_deserttown (deserttown_*), room_haundream (hd_*: door/hide/crystal),
  room_hideandseek2 (hn2_*), room_kindandfair (kaf_*),
  room_limpcity (limpcity_*: ojos), room_majongforest (majong_*),
  room_marijuna (marijuna_*), room_nastyparadise (nap_*: nieve),
  room_notperfect (np_*), room_volcanovalley (vv_*), room_weedzone (weed_*),
  room_dotdotdot, room_fartzone (fart_*), room_torturecave, room_act9,
  room_you_are_failure, room_youcantrun, room_pricelessfreedom,
  room_darktower (darktower_* + tailsdoll), room_shadertest.
- obj_bigring (anillo de escape) + obj_bigring_teleport, obj_blackring.
- Rings/curacion: obj_ring, obj_ring_spawner, obj_ringspawn, obj_redring,
  scr_survivor_heal/revive.
- Minijuego: obj_minigame + obj_minisnoc_*.
### 3.5 Killers NPC / eventos de mapa (NO son el jugador EXE)
- obj_exeller (+ obj_exeller_clone = CLONES del exe: atacan y NO son
  obj_player_puppet => mi flecha roja los ignora por diseno), obj_exetior
  (+ stompballs), obj_chaos, obj_granny, obj_rmzsonic, obj_abyss,
  obj_darktower_tailsdoll, obj_eggstatue/obj_eggtrack (rastreador del exe).
### 3.6 Extensiones (extensions/)
- MultiClient (v1.1.6) ... post_run_step.bat/.sh: al compilar desde
                          GameMaker lanza N instancias del juego (opciones
                          de extension: Number_Of_Clients, proxy). Asi se
                          prueban 2 ventanas en la misma PC (junto con
                          allow_duplicate_ip:true del server, seccion 6).
- disnet ................. DLL/SO de red del juego (disnet.dll +
                          libdisnet.so + fuente Android).
- disasterserver/, data/ . (auxiliares del proyecto).

## 4. PERSONAJES
### Survivors (macros en scripts/scr_survivors/scr_survivors.gml, base TAILS=1)
- CHARACTER_TAILS(1) ..... obj_tails (vuela; tails_projectile).
- CHARACTER_KNUX(2) ...... obj_knux (glide/planeo).
- CHARACTER_EGGMAN(3) .... obj_egg (eggtrack; scr_egg_special).
- CHARACTER_AMY(4) ....... obj_amy (Amy normal; salto de martillo AMY_HJUMP
                            en obj_amy/Step_2; scr_amy_special).
- CHARACTER_CREAM(5) ..... obj_cream.
- CHARACTER_SALLY(6) ..... obj_sally.
- CHARACTER_AMY_CANON(7) . obj_amy_canon = NUESTRO mod (personaje reservado).
- Logica de habilidad especial de cada uno: scr_*_special.gml. Dano/curacion:
  scr_player_hurt, scr_survivor_heal, scr_survivor_revive.
### EXE (asesino jugador)
- CHARACTER_EXE = 0 (macro en scripts/scr_exe/scr_exe.gml). Objeto: obj_exe
  (+ scr_exe_checkwin/special/stunsound). Sus "minions" son obj_exeller_clone
  (NO puppets) y los demonizados (revivalTimes >= 2 conservan su personaje
  original). REGLA DE ORO: un puppet es EL EXE REAL si y solo si
  puppet.character == CHARACTER_EXE.
### AMY CANON (nuestro personaje, 100% mod)
- obj_amy_canon/: Create_0 (macros AMY_CANON_*: TAROTDASH_HITBOX_PAD=5,
  HJUMP_HITBOX_PAD=5, etc.), Step_0/Step_2 (estados BALANCING),
  Draw_76 (animacion del salto de martillo), Alarm_4, Other_7.
- Scripts: scr_amy_canon_special.gml (habilidades), scr_amy_canon_bubble.gml
  (burbuja: invulnerable, revivalTimes=0, nunca se demoniza).
- Controles: Z = salto normal | ABAJO+Z = salto de martillo (en suelo,
  parada/caminando/corriendo, conserva impulso; swing frames 0-2 con pad
  ~20% mas grande) | X en aire = impulso tarot (stun 2s al exe al impactar,
  hitbox con pad 5) | C = acometida. Ni martillo con Z sola ni durante la
  acometida (isDashing).
- Estados: AMY_CANON_HJUMP == AMY_HJUMP == BALANCING+2 (el hack del puppet
  en obj_player_puppet/Step_0.gml cubre a ambas Amys a la vez).
- obj_amycanon_indicators = sus 2 sensores personales (ver seccion 5),
  solo existen en el cliente de la propia Amy Canon (depth -200).
- Reserva en server: amy_canon_token "SweetPassion" en Config.json; quien
  no la escribe no la ve en charselect (server la valida).

## 5. SISTEMA DE FLECHAS / INDICADORES (todos son Draw_64 = Draw GUI)
### Sprites y sus colores (verificado con analisis de pixels)
- spr_indicator ... ROJA  32x16 (origin 3; bbox visible x[20..31]: la punta
                    queda ~20px a la DERECHA del punto de dibujo).
- spr_sindicator .. AZUL  (mismo diseno que la roja, gemela).
- spr_sindicator2 . VERDE (gemela; la de la salida).
- spr_sindicator3 . AMARILLO.
- spr_indicator2 .. VERDE 8x8 (la pequenita del demonizado).
- spr_indicator3 .. (variante, ver obj_exe_sprindicator).
### Tabla de indicadores del juego (vanilla)
- obj_exe_indicator .... ROJA, nace con obj_exe/obj_chaos (Create). La ve el
  EXE: apunta a su presa (survivor marcado por su rastreo/eggtrack).
- obj_surv_indicator ... AZUL, la ven los SURVIVORS: apunta al EXE (el
  "target" lo asigna la red: net_state_game.gml:2226, alarm[0]=3s). La
  respuesta a la duda del usuario: roja=exe->survivors, azul=survivors->exe
  (el juego lo hace asi a proposito; cada bando ve SU color de busqueda).
- obj_surv_lampindicator  AMARILLO, hacia la lampara (se autodestruye si
  demonizado o muerto).
- obj_surv_ringindicator  VERDE (spr_sindicator2) hacia el anillo de escape.
  En vanilla SOLO existe en ravinemist y exige 6 shards.
- obj_demon_indicator VERDE pequenita (spr_indicator2), elevada sobre el
  player (pos 20-36 segun personaje): para demonizados, apunta al exe.
- obj_exe_sprindicator / obj_exeller_indicator(_up/_down) /
  obj_exetior_indicator: flechas rojas de eventos NPC de mapa.
### NUESTROS sensores: obj_amycanon_indicators (solo cliente de Amy Canon)
- VERDE (spr_sindicator2, angulo ringAngle): hacia obj_bigring (la salida),
  activa desde que el anillo existe en el mapa. PEGADA a Amy.
- ROJA (spr_indicator, angulo exeAngle): hacia el EXE REAL (el Step solo
  acepta puppets con character == CHARACTER_EXE; NUNCA minions/clones). En
  la v2 va PEGADA a Amy; solo si salida y exe caen en la misma direccion
  (angle_difference < 20) se desplaza 14px perpendicular para no tapar la
  verde. El Step gestiona visible=(ringVisible||exeVisible); Draw_64 abre
  con if(!visible) return; hay Draw_0 vacio; .yy con 4 eventos.
- Se apaga sola si revivalTimes>=2 (red de seguridad; la burbuja lo evita).

## 6. SERVER C (disaster2d-oss/betterserver-oss, alias "hammer")
- C + CMake (compilar_server.bat, build_android.sh, shell.nix). Logica
  server-authoritative: Server.c, Lobby.c, Player.c, Packet.c, CharSelect.c,
  Maps.c, Palette.c, Config.c, Log.c, DyList.c, Libs.c, Results.c (endings,
  ver 7.1) + states/ + entities/ (~40).
- SUBMODULO ENet: .gitmodules apunta a github.com/lsalzman/enet pero NO
  esta incluido en el repo GitHub => un clone fresco NO compila hasta
  traerlo (git submodule update --init, o clonarlo a mano en
  betterserver-oss/enet/). PENDIENTE decidir si se commitea (ver 9).
- compilar_server.bat (menu de 7 opciones): 1 compilar cambios / 2 limpiar
  y recompilar TODO (BUILD_UI=ON con SDL2 en C:\SDL\SDL2-2.32.10 y
  SDL2_image-2.8.12) / 3 copiar DLLs de SDL / 4 ejecutar GUI / 5 ejecutar
  --nogui / 6 abrir carpeta del exe. Respalda y restaura Config/
  Operators/Bans/Timeouts.json en config_backup/. CMake de VS BuildTools 18.
- Config.json (actual en el repo): puerto 8606, protocolo 1101,
  amy_canon_token "SweetPassion", allow_duplicate_ip true (2 instancias
  misma IP = multijuego local), anticheat true (SOLO valida ticket/paleta
  /zonas: checksum 0 => mod_tool=true, NO desconecta => compatible con
  cliente modificado). Operators.json = IPs op (127.0.0.1 = op local).
- CONFIGURAR_AMY.bat + configurar_amy.ps1 = configurador automatico de la
  frase secreta para el usuario.
- VALIDADO 26/10 (analisis-oss-1): fuente compila 100% limpia (Linux, enet
  clonado) y smoke test OK ("BetterServer v1101", puerto 8606, Lobby).
  OJO: betterserver-oss/build_test/ y run_test/ son artefactos de esa
  validacion en el sandbox — NO commitear.
- REGLA: cambios de stats/habilidades/validacion tocan cliente Y server
  (recompilar); cambios solo visuales (draw/indicadores) no tocan server.

### 6.1 RELAY / PUERTOS (analisis relay-v1, 26/10)
- PREGUNTA: el server v1101 ¿soporta relay o lo bloquea? RESPUESTA: NI LO
  SOPORTA NI LO BLOQUEA — la funcion NO EXISTE en esta version del codigo
  (0 menciones a "relay" en betterserver-oss/). No hay filtro de origen:
  Lib.c allocate_server() escucha en ENET_HOST_ANY => acepta conexiones de
  cualquier IP/puerto de origen (un proxy/relay externo delante funciona).
- El relay de penguinehis es de SU stack: betterserver-v1.6 (file.dr2.site,
  2026-10-01, fuente CERRADA) trae Relay.c (config: relay_enabled,
  relay_directory_host, relay_directory_port, relay_username,
  relay_password) que se conecta SALIENTE al directorio central
  relaysc.dr2.site:9000 (cuentas/regiones/suspensiones), publica cada
  lobby en un puerto publico del relay (relay_public_port(server->id),
  "players can join at %s ports %u-%u"), sin abrir puertos (NAT
  traversal), IPs de jugadores reemplazadas por sinteticas estables.
  v1.6 trae ademas WebGate (WebSocket navegador), 10 gamemodes y reports.
  v1.6 SI habla 1101 (cmp $0x44d; ver relay-recon-v1): el cliente 110v
  CONECTARIA (paquetes desconocidos se ignoran), pero NO conoce a Amy
  Canon (7) ni Sonic (8) => personajes del mod rechazados ahi.
- ESQUEMA DE PUERTOS DEL V1101 (verificado): Lib.c linea 47
  addr.port = base_port + n => lobby id 0 = g_config.port (8606), id 1 =
  8607, etc. Config actual: server_count 1 => SOLO el 8606 abierto. El
  CHANGELOBBY (.lobby N, redirect por lleno) manda el puerto absoluto
  (g_config.port + id) y el cliente reconecta ahi.
- CLIENTE 110v — APLICADO portfix-gml-v1 (26/10): net_join() en
  scripts/net_wrapper/net_wrapper.gml ahora PARSEA "IP:PUERTO" (puerto
  del net_join de TD2DR-Updated, verbatim adaptado a TABs): guarda ip
  LIMPIA + base_port (nueva var en obj_netclient/Create_0.gml = 8606),
  port = selected_lobby == -1 ? base_port : selected_lobby. Validado
  con scripts/portfix_gml_validate.py (8 casos OK: IP:PUERTO,
  hostname:PUERTO, IP sola, tail vacio/letras/0/>=65536 sin parseo =
  mismo comportamiento que upstream). El textbox del join (obj_menu_
  textbox/Draw_0.gml) solo filtra \r\t\n => el ":" ya se podia escribir.
  Con esto el CHANGELOBBY multi-lobby tambien queda correcto (ip limpia
  + puerto absoluto del server). FALTA recompilar el juego en GMS.
- PARCHE PortFIX de penguinehis (file.dr2.site .../Patchs-Original-game/
  Sonic-PortFIX.zip, 38 KB): disnet_portfix.dll x64 PROXY (mismas 6
  exportaciones + disnet_portfix_marker, marker DISNET_PORTFIX_V1);
  patch.bat/ps1 renombra disnet.dll -> disnet_orig.dll y se pone en su
  lugar; disnet_connect lee "IP:PUERTO" del Join screen y pasa el puerto
  a la original. APLICA DIRECTO a nuestro juego: extensions/disnet/
  disnet.dll es x64 con las MISMAS 6 funciones (patch.ps1 valida
  disnet_connect presente). No toca exe ni data.win. Reversible (-Unpatch).
- MATIZ multi-lobby: RESUELTO por portfix-gml-v1 (ip queda limpia + base
  port guardado => CHANGELOBBY/reconnect van al server correcto). Sin
  ese fix, el proxy DLL reconectaria al puerto del string.
- RE v1.6 (dimensionado, 26/10): exe NO stripped (4837 simbolos);
  superficie relay ~20 funciones: relay_open/start/worker (hilo),
  tunnel_connect/tunnel_pump (g_tunnel), relay_resolve, relay_seal,
  relay_keystream_xor + relay_derive_keys (CIFRADO propio del tunel),
  relay_send_player_data, relay_invalidate_player_data,
  relay_public_port, relay_lookup_ip, relay_tiers +
  relay_mark_priority_near (QoS), g_relay_echoes (ping via relay),
  server_relay_fill/tick. => conectar nuestro server al relay de
  penguinehis = RE completa con cifrado + cuenta en su directorio +
  riesgo de suspension ("suspended by the host of the relay"). NO
  recomendado; relay propio (codigo nuestro + VPS) es la via limpia.
- OPCIONES (detalladas en worklog relay-v1): A) puerto custom directo
  (cambiar "port" en Config.json + clientes con fix IP:PUERTO ya
  aplicado); B) relay casero VPS reenviando UDP 8606 -> IP:8606
  (jugadores SIN parche si el VPS usa 8606; esconde IP del host;
  frp/rathole/socat/playit.gg); C) relay PROPIO completo (yo escribo
  relay-node para VPS + integracion synthetic-IP en betterserver-oss
  para que bans/ops funcionen por jugador — equivalente a lo que hizo
  penguinehis pero a medida, sin depender de relaysc.dr2.site).

### 6.2 RELAY PORTADO E INTEGRADO (relay-port-v1, 26/10)
- ¡EL RELAY DE relaysc.dr2.site YA ESTA EN NUESTRO SERVER! Port completo
  del sistema de penguinehis (betterserver-v1.6) a betterserver-oss,
  recreado 100% por RE estatica (RELAY_SPEC.md v2, mapeo completo).
- ARCHIVOS: include/Relay.h + disasterserver/Relay.c (nuevos, ~1000
  lineas: SHA-256+HMAC propios validados contra RFC 4231/FIPS 180-4,
  tunnel_connect 3 fases, tunnel_pump, frames sellados, sesiones);
  Config.h/.c (seccion "relay" anidada: enabled/directory_host/
  directory_port/username/password, defaults relaysc.dr2.site:9000,
  roundtrip config_save OK); Lib.c (relay_init al final de
  disaster_init); states/Server.c (AMBOS CHANGELOBBY usan
  relay_public_port: base_port+id si online, g_config.port+id si no);
  CMakeLists (+Relay.c, sin libs nuevas); compilar_server.bat (estado
  relay en el menu, anti-exe-bloqueado antes de compilar, opcion 7
  = configurar relay); configurar_relay.ps1 (asistente de cuenta,
  respalda, pone allow_duplicate_ip=true solo).
- PROTOCOLO (detalle en RELAY_SPEC.md v2): directorio
  relaysc.dr2.site (challenge-response HMAC con password, ticket 88B,
  relay_ip en reply[112..116] puerto en [116..118], relay_key XOR
  session_key), handshake relay (HELLO/CHALLENGE/TICKET/ACCEPT con
  base_port+port_count), 4 llaves HMAC (labels h2r-enc/h2r-mac/
  r2h-enc/r2h-mac), frames sellados [BE 01 tipo lobby sid_le ||
  seq_be || payload-XOR-keystream || MAC16], anti-replay ventana 64
  bits, tipos 06=abrir sesion (IP real en payload)/07=reset/08=datos
  (auto-crea si falta)/09=ping-eco-15s. Muerte a los 45s sin eco ->
  reconexion automatica; reintento connect cada 10s.
- REGLAS DEL PORT: (1) la cuenta NO se registra ni se pide por
  pantalla: vive en Config.json como el original; (2) sin password
  el relay queda apagado con 1 solo Warn (sin spam de reintentos,
  sin llamadas de red) — probado; (3) allow_duplicate_ip debe ser
  true (releados llegan de 127.0.0.1) — ya lo esta y el .ps1 lo
  garantiza; (4) mensajes en el MISMO canal de log que Amy Canon
  (Info/Warn -> consola y GUI): "Relay: online - players can join at
  %s ports %u-%u" al conectar, "Relay: session %u -> local port %u
  as %s" por jugador nuevo, errores de cuenta en ingles (identicos
  al v1.6). El chat del JUEGO no muestra nada del relay.
- VALIDADO (sandbox, sin tocar la cuenta): compila limpio (gcc),
  cripto 9/9 vectores OK, 3 smoke tests (sin seccion relay / enabled
  sin password / config real del usuario). PENDIENTE: prueba en vivo
  del usuario (poner password y ver "Relay: online").
- v1.2 FIX "WRONG RELAY PASSWORD" (26/10, reporte del usuario con
  GUI ya recuperada): el server fallaba con "wrong relay password"
  aunque la clave fuera correcta. Causa raiz: el CHALLENGE del
  directorio trae el salt en reply[8..24] (paquete real capturado:
  be 01 11 00 00 00 00 00 <salt16>; disasm v1.6: movdqu xmm2,[buf+8])
  y Relay.c lo leia en reply+4 -> proof mal calculado. Fix: 1 linea
  (salt = reply+8). Validacion A/B end-to-end: directorio falso en
  Python con el formato REAL capturado + Relay.c real compilado:
  codigo viejo reproduce EXACTAMENTE el error del usuario; codigo
  nuevo completa handshake directorio+relay y queda ONLINE en 0.2s.
  Probe anonimo (SIN credenciales) confirmo ademas: DNS OK
  (177.74.185.42), puerto 9001 OK (9000/443/80 no responden), el
  directorio esta VIVO y contesta CHALLENGE en <6s. El error 2
  (wrong password) y no "does not recognise" prueba que la cuenta
  del usuario EXISTE y su region esta bien. Layout del ACCEPT
  re-verificado en disasm (ticket@8, region@96, relay_ip@112 via
  inet_ntoa, relay_port@116, relay_key XOR session@118..150): sin
  cambios. Tiempos re-verificados en disasm: poll dir 4s (0xfa0),
  reintento 10s (Sleep 10000), ping 15s, muerte tunel 45s (0x2d) -
  identicos a mi port. RELAY_SPEC.md -> v3. Scripts de validacion:
  scripts/relay_dir_probe.py, scripts/fake_directory.py,
  scripts/relay_e2e_test.c (+relay_e2e_test binario).
- DIAGNOSTICO CONEXIONES FANTASMA (26/10, pantallazos 07:32/07:34):
  "session 10 -> local port 52301 as 102.134.82.174" = SCANNER de
  internet (ComX Networks, Sudafrica) golpeando el puerto publico al
  abrirse. El relay de pengu abre sesion por CUALQUIER UDP entrante
  (igual el v1.6 original) -> sesion sin jugador = normal e inofensiva
  (no ocupa slot, se limpia a 300s con nuestro reaper; el original ni
  tenia reaper). El join de Amy Rose con IP 127.0.0.1 = conexion LOCAL
  del usuario, no relay. LEEME_RELAY.txt +seccion "conexiones fantasma"
  con tabla scanner-vs-jugador-real. Cero cambios de codigo.
- v1.3 FIXES DE JUGADORES RELAY (26/10 tarde, comparando tunnel_pump del
  v1.6 en 0x140017b4b/0x140018400 y allocate_server): (1) CRITICO: el
  relay CIFRA TODO payload que manda (keystream HMAC-SHA256 con llave
  r2h_enc y seq del frame, bloque N con contador LE); faltaba el XOR de
  descifrado antes de inyectar en 127.0.0.1:8606 -> el handshake del
  jugador llegaba cifrado y ENet lo ignoraba (conectaba al tunel pero
  nunca hacia "joined", se cortaba a los 45s). (2) MTU clamp 1368 +
  buffers socket 512KB en allocate_server (payload max del tunel 1368 <
  MTU default ENet 1392 -> datagramas grandes se caian silencioso).
  (3) relay_lookup_ip declarado en Relay.h e integrado en CONNECT de
  states/Server.c (los releados mostraban IP: 127.0.0.1 en el join;
  ahora sale la IP real que reporto el relay). Syntax check OK de los
  3 .c. Zip relay_port_v1.3.zip (13 archivos, 81488 B, MD5
  0b461bd9e3d315e48f7d5c3949354ed0) subido a tmpfiles (link directo
  verificado MD5 identico; gofile cayo: /upload devuelve 404 en todos
  los stores, cambio de API).
- v1.1 FIX GUI (26/10, reporte del usuario): al recompilar tras
  aplicar la v1.0 el exe salio en MODO CONSOLA (sin ventana SDL de
  ~770 KB). Causa raiz: los "unset(BUILD_UI CACHE)" al final del
  CMakeLists ORIGINAL borraban el flag del cache; al editar ese
  archivo (para +Relay.c) CMake se auto-reconfiguraba y option()
  recreaba BUILD_UI=OFF -> exe consola. Fix doble: (1) CMakeLists
  sin los unset (flag persiste); (2) compilar_server.bat opcion 1
  re-aplica -DBUILD_UI=ON antes de cada build y al terminar verifica
  el subsistema PE del exe (GUI=2/consola=3, via PowerShell) avisando
  si salio consola. Exe GUI original del usuario verificado: PE32+
  subsystem 2, SDL2+SDL2_image, "DisasterServer v1101 (Modified)".
  Relay.c no usa printf directo (17 llamadas Log/Info/Err) -> todos
  los avisos del relay SI salen en el chat de la ventana GUI.
- LIMITACIONES conocidas vs v1.6: ping_send_record/QoS tiers no
  portados (cosmetico); bans/ops de jugadores releados caen en
  127.0.0.1 (el UDID sigue funcionando); con server_count=1 y
  port_count=1 todo cuadra (1 puerto publico).

## 7. MODS APLICADOS (historial; el detalle exacto esta en worklog.md)
| Task ID            | Que hace                                                       | Entregable (download/) |
|--------------------|----------------------------------------------------------------|------------------------|
| 1                  | Extractor formato .fra de Fraymakers                           | charactertemplate_extraido.zip |
| 2                  | Sally Extract GUI (recomprimir .fra)                           | sally_extract.html |
| 4                  | Sprites de Amy 100v extraidos                                  | td2dr_amy_100v.zip |
| 5                  | Recon modding TD2DR + server TTB                               | MODDING_PLAN.md |
| 6                  | Diagnostico "version desactualizada" (ping>250ms)              | (solo analisis) |
| 7                  | Guia compilacion DisasterServer (VS/CMake)                     | td2dr_server_fuente.zip |
| sensors-v1         | Sensores Amy Canon v1 (verde salida + azul exe)                | (en zip bugfix) |
| reserved-v1        | Amy Canon RESERVADA: token server, nadie mas la ve             | (server) |
| reserved-v3        | CONFIGURAR_AMY.bat / .ps1 (frase automatica)                   | (server) |
| hammer-v1          | Salto de martillo ABAJO+Z + allow_duplicate_ip                 | amy_canon_martillo_y_multijuego.zip |
| bugfix-tarot-v1    | Macro TAROTDASH_HITBOX_PAD=5 + sensores visibles + pad martillo | amy_canon_bugfix_tarot_sensores(_v2).zip |
| flecha-pegada-v2   | Flecha roja pegada a Amy (antes flotaba +24px hacia el exe)    | amy_canon_flecha_pegada_v2.zip |
| endings-v2         | Musica de ending por escapados + espera sincronizada (ver 7.1)| (instalado directo en el repo) |
| analisis-oss-1     | Analisis completo del repo GitHub + validacion server (26/10) | (solo analisis) |
| relay-port-v1      | Relay relaysc.dr2.site INTEGRADO al server (ver 6.2)          | relay_port_v1.zip |
| relay-gui-v1.1     | Fix exe consola -> vuelve GUI SDL (unset BUILD_UI) (ver 6.2)  | relay_port_v1.1.zip |
| relay-fix-v1.2     | Fix salt CHALLENGE (offset 8): adiós "wrong password" (ver 6.2)| relay_port_v1.2.zip |
| relay-v1.3         | Fix r2h-enc + MTU 1368 + IP real en join (ver 6.2)             | relay_port_v1.3.zip |

### 7.1 ENDINGS MUSIC v2 (instalado en el repo; detalle: LEEME_ENDINGS_V2.txt)
Musica de ending SEGUN CUANTOS ESCAPARON (estilo TD original) + el server
espera a que TERMINA la cancion antes de volver al lobby (antes: 15s fijos
y las pistas nuevas de 20-28s se cortaban).
- PISTAS (sounds/, 7 nuevas ya registradas en .yyp; duraciones ffprobe):
  Best_ending 24.17s | Best_ending_Alt 20.41s  (escaparon TODOS)
  Solo_ending 27.49s | Solo_ending_Alt 21.95s  (escapa exactamente 1)
  Duo_ending 22.73s                             (escapan exactamente 2)
  Standard_Ending 24.25s | _Alt 23.23s         (mas de 2, no todos)
  vanilla: mus_exewin 15.34 | mus_survwin 14.58 (red de seguridad) |
  mus_timeover 14.58
- ARCHIVOS cliente: objects/obj_results/Create_0.gml (escapedCnt=0,
  survTotal=0, manda CLIENT_RESULTS_REQUEST, audio_stop_all);
  scripts/net_state_results/net_state_results.gml (por cada fila: type 4
  => escapedCnt++, type >= 1 => survTotal++); objects/obj_results/
  Alarm_0.gml (elige pista: result 0 = mus_exewin, 1 = por escapados,
  2 = mus_timeover; alarm[0]=4 frames tras la ultima fila).
- ARCHIVOS server: disasterserver/states/Results.c
  (results_music_countdown + #define ENDINGLEN_* + ENDING_MARGIN 1.0;
  re-sync en el primer CLIENT_RESULTS_REQUEST con flag music_synced usando
  las MISMAS filas peers + game.left y la misma clasificacion PLRSTATE);
  include/Server.h (Results.music_synced; enum Ending ED_EXEWIN=0,
  ED_SURVWIN=1, ED_TIMEOVER=2; game.time_sec u16).
- LOGICA (IDENTICA en ambos lados): categorias en este orden: escaped >=
  survTotal => Best | escaped == 1 => Solo | escaped == 2 => Duo | resto =>
  Standard (2-de-2 = Best; para hacerlo Duo mover el bloque ==2 ARRIBA en
  AMBOS archivos). Variante base/Alt = (time_sec + escapados) % 2; el
  cliente usa timeSec = _time % 60 (60 par => misma paridad) => todos
  oyen LA MISMA pista y el server sabe exactamente cuanto esperar. La
  espera nunca baja de 15s (vanilla); countdown = (len + 1.0) * 60 solo si
  supera 15s.
- MANTENIMIENTO: reemplazar un mp3 => medir con ffprobe, actualizar su
  ENDINGLEN_* en Results.c y recompilar el server. No bajar
  ENDING_MARGIN de 0.5 (con ping alto se cortaria).

## 8. CONVENCIONES Y TRAMPAS DEL CODIGO (lecciones pagadas — leer ANTES de editar)
1. SANGRIA MIXTA: la mayoria de .gml usan TABs, pero ALGUNOS usan 8 espacios
   literales (obj_amycanon_indicators, estilo vanilla). Verificar SIEMPRE con
   `sed -n 'Np' archivo | cat -A` antes de intentar un match.
2. Editar .gml SIEMPRE con script aplicador (scripts/apply_*.py) con
   verificacion de match exacto == 1 vez. Nunca Edit directo en archivos
   grandes (incidente: 554 lineas de diff por TAB->espacios).
3. Tras editar, correr el validador (scripts/*_validate.py). Checks fijos:
   sin CR, sangria consistente, llaves/parens balanceadas, contenido intacto.
4. .yy de indicadores: nacen con visible:false y en este runtime Draw GUI NO
   corre para invisibles. Todo indicador necesita: Step que ponga
   visible=true cuando haya algo que senalar + if(!visible) return en
   Draw_64 + Draw_0.gml VACIO (0 bytes) + eventList del .yy con los eventos.
5. && cortocircuita en GML: una macro/variable no definida explota SOLO
   cuando esa rama se evalua (crash a destiempo, caso del tarot). Las macros
   AMY_CANON_* se definen en obj_amy_canon/Create_0.gml junto a sus hermanas.
6. Sprites de flecha: 32x16 origin 3 pero bbox visible x[20..31] => la punta
   queda a la derecha del punto de dibujo. Dibujar PEGADO al player en
   (player.x, player.y) rotando hacia el objetivo. NUNCA anadir offsets
   extra hacia el objetivo (leccion de flecha-pegada-v2).
7. Instalar zips: extraer sobre la RAIZ del proyecto (la carpeta con .yyp)
   con GameMaker CERRADO; aceptar sobrescribir; recompilar F5. El server
   solo se recompila si el zip toca .c/Config (el worklog de cada task lo
   dice).
8. Server: anticheat:false permite mods de cliente. Conectar por 127.0.0.1
   = op (pasa duplicados); por IP LAN no es op (necesita allow_duplicate_ip:
   true para 2 ventanas en el mismo PC).
   CONFIRMADO EN VIVO (26/10): con anticheat:true, nuestro cliente (Amy
   Canon + Sonic Quiz + DLL portfix) da checksum 0 -> mod_tool=true ->
   NO puede ser elegido exe (CharSelect.c:71 exige !mod_tool) -> si TODOS
   son modificados charselect_choose_exe devuelve false -> RAssert de
   CHARSELECT.C:255 falla -> loop mapvote->charselect->lobby sin iniciar
   partida NUNCA. Con anticheat:false, mod_tool queda false y arranca
   normal. Config correcta para server + cliente propios de comunidad:
   anticheat:false (los bans por UDID siguen funcionando).
9. angle_difference/point_direction/degtorad: built-ins disponibles. En
   pantalla Y crece hacia abajo => los draws usan _y - sin(a)*d.

## 9. PENDIENTES / esperando al usuario
- relay-v1.3: pendiente PRUEBA REAL CON JUGADOR EXTERNO por el relay.
  Setup listo: server v1.3 + cliente con DLL portfix IP:PUERTO +
  anticheat:false CONFIRMADO arrancando partidas. Solo falta: alguien
  de fuera entra con IP:PUERTO al puerto del log "players can join
  at" -> debe ver el join con SU IP REAL (no 127.0.0.1). Avisar de
  cualquier rareza con pantallazo.
- anticheat: RESUELTO (26/10) — era el loop RASSERT de CharSelect con
  todos los clientes modificados; solucion = anticheat:false (ya
  documentado en lecciones, punto 8).
- conexiones fantasma: RESUELTO (26/10) — scanners de internet, normal
  e inofensivo (ver 6.2, diagnostico completo).
- enet: submodulo sin incluir en el repo GitHub => un clone fresco no
  compila (ver seccion 6). Decidir: commitear enet/ o dejar instrucciones
  de clonado en el LEEME.
- endings-v2: pendiente CONFIRMAR en partida real (prueba rapida en
  LEEME_ENDINGS_V2.txt: ronda con escapados => musica completa y salto
  al lobby ~1s despues de que termine la cancion).
- flecha-pegada-v2: pendiente PROBAR en partida (calibracion 14px / 20 grados
  ajustable en un minuto si no convence).
- (Los 2 bugs originales del tarot y los sensores ya estan cerrados por
  bugfix-tarot-v1. Worklog y CACHE sincronizados con el repo 26/10.)

## 10. HERRAMIENTAS PROPIAS (scripts/)
- IMPORTANTE (26/10): la carpeta scripts/ del workspace NO existe en este
  sandbox (rollback). La lista de abajo es el inventario HISTORICO; si se
  necesita una herramienta, recrearla segun la descripcion de su entrada
  en worklog.md. Convencion del proyecto: scripts/apply_<task>.py =
  aplicador de ediciones quirurgicas (match exacto == 1 vez, TABs
  literales); scripts/<task>_validate.py = validador post-edicion.
- Aplicadores de parches (historico): apply_bugfix.py, apply_arrowfix.py.
- Validadores (historico): bugfix_v1_validate.py, flecha_roja_v1_validate.py,
  hammer_v1_validate.py, td2dr_validate.py.
- Recon/extraccion del juego (historico): td2dr_parse.py, td2dr_qoi_*.py,
  td2dr_extract.py, td2dr_amy_final.py, td2dr_server_*.py.
- Fraymakers (historico): fra_extract.py, analyze_fra.py, analyze_fra2.py.
- Misc (historico): check_arrow_colors.py (colores de sprites de flecha).

## 11. CHANGELOG DEL CACHE
- 2026-10-24: v1 creada con barrido completo del proyecto: workspace, juego,
  cliente (302 objetos clasificados), personajes, mapa de flechas con
  colores verificados por pixels (roja=exe->survivor, azul=survivor->exe,
  verde=salida, amarilla=lampara), server, historial de mods, convenciones.
- 2026-10-26: sync con el repo GitHub real del usuario (analisis-oss-1 +
  docs-sync-v1): workspace re-mapeado (la raiz del repo = proyecto GM),
  documentado ENDINGS MUSIC v2 completo (NUEVA seccion 7.1: estaba
  instalado pero sin documentar), anotada la extension MultiClient (3.6),
  server VALIDADO (compila limpio + smoke test v1101 OK), pendiente del
  submodulo enet anotado (secciones 6 y 9), estado Amy Canon verificado
  intacto (macros, flechas, martillo, token, allow_duplicate_ip).
- 2026-10-26 (relay-v1): NUEVA seccion 6.1 RELAY/PUERTOS: analisis del
  sistema relay de penguinehis (betterserver v1.6 + relaysc.dr2.site),
  veredicto (v1101 ni soporta ni bloquea relay; no existe en el codigo),
  esquema de puertos verificado (base_port+id), parche PortFIX analizado
  (DLL proxy x64 compatible con nuestro juego), matiz CHANGELOBBY y las
  3 opciones para tener relay. Repo td2dr-updated clonado en workspace.
- 2026-10-26 (portfix-gml-v1): APLICADO el soporte IP:PUERTO del cliente
  en la fuente del juego (net_join parsea ":", ip limpia + base_port en
  obj_netclient/Create_0.gml; validador 8/8 OK; ver seccion 6.1).
  Dimensionada la RE del relay v1.6 (~20 funciones con cifrado propio,
  no stripped) => via recomendada = relay propio o proxy, no RE.
- 2026-10-26 (relay-re-v1): RE estatica COMPLETA del protocolo relay del
  v1.6 (cero conexiones, cuenta del usuario intacta). Especificacion
  guardada en td2dr/relay_server/RELAY_SPEC.md: 3 fases (directorio
  relaysc.dr2.site:9000/9001 con challenge-response HMAC-SHA256; handshake
  relay con ticket; tunel cifrado con 4 llaves h2r/r2h-enc/mac derivadas
  por HMAC con labels de 7B, keystream HMAC-SHA256(seq_be||bloque_le),
  frames sellados BE 01 <tipo> <lobby> <session_id> || seq_be || payload
  || MAC16, tipos 09/07/06/08, sesiones=sockets UDP locales que mandan a
  127.0.0.1:(port+lobby) = IPs sinteticas). Mapeo ~90%; pendiente
  handlers 0x06/TX/session_open y escribir Relay.c (ver spec seccion 11).
  El usuario confirmo: usara su cuenta relay real (port 9001) y pidio NO
  probarla en vivo — porteo con enabled=false y credenciales vacias.
- 2026-10-26 (relay-port-v1): RELAY PORTADO E INTEGRADO (NUEVA seccion
  6.2). RE completada al 100% (correcciones v2: AUTH = magic||proof||
  username, relay_ip en reply[112..116], 0x06=abrir/0x07=reset, sid u32
  LE, ventana anti-replay 64b, ping 15s/muerte 45s). Relay.c+Relay.h
  nuevos (SHA-256/HMAC propios 9/9 vectores OK), Config relay anidada,
  CHANGELOBBY x2 con relay_public_port, .bat con estado relay + opcion
  7 + anti-exe-bloqueado, configurar_relay.ps1. Config.json del repo ya
  trae la cuenta del usuario (password vacia a proposito). Validado
  compilando + 3 smoke tests SIN usar la cuenta.
- 2026-10-26 (tarde, sesion 2): v1.3 empaquetada y subida (r2h-enc +
  MTU + IP real). Diagnostico anticheat RESUELTO EN VIVO con el
  usuario: loop RASSERT CHARSELECT.C:255 = todos los jugadores
  modificados (checksum 0 -> mod_tool) -> nadie elegible como exe;
  con anticheat:false arranca normal. Diagnostico conexiones
  fantasma: scanners (Sudafrica), inofensivos. LEEME_RELAY.txt
  v1.3 con seccion fantasma. Links tmpfiles (60 min) para v1.3.
