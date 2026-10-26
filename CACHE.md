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
#         6 server | 7 mods | 8 convenciones | 9 pendientes | 10 herramientas
#         11 changelog
# ============================================================================

## 1. WORKSPACE /home/z/my-project
- client/ ................ EL juego. Proyecto GameMaker (.yyp "Sonicexe The
                          Disaster 2D Remake", 1.1.0 FINAL 110v). 302 objetos,
                          67 scripts, 947 sprites, 30 rooms. DENTRO vive
                          betterserver-oss/ (el server C, ver seccion 6).
- MODDING_PLAN.md ........ recon completo del juego + ruta de modding + info
                          de la comunidad (leer si hace falta contexto).
- worklog.md ............. bitacora de TODAS las operaciones (por Task ID).
- CACHE.md ............... este archivo.
- scripts/ ............... herramientas Python propias (aplicadores de
                          parches, validadores, extractores).
- download/ .............. entregables (zips) para el usuario.
- upload/ ................ archivos que sube el usuario (capturas, etc).
- td2dr/ ................. material de recon (100v, servers TTB, texturas).
- skills/, tool-results/ . infraestructura del sandbox. NO tocar.

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

## 3. CLIENTE GAMEMAKER (client/)
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

## 6. SERVER C (client/betterserver-oss, alias "hammer")
- C + CMake (compilar_server.bat, build_android.sh, shell.nix). Logica
  server-authoritative: Server.c, Lobby.c, Player.c, Packet.c, CharSelect.c,
  Maps.c, Palette.c, Config.c, Log.c, DyList.c, Libs.c + entities/ (~40).
- Config.json: puerto 8606, protocolo 1101, amy_canon_token "SweetPassion",
  allow_duplicate_ip (false=vanilla; true=2 instancias misma IP = multijuego
  local). Operators.json = IPs op (127.0.0.1 pasa por op en local).
- CONFIGURAR_AMY.bat + configurar_amy.ps1 = configurador automatico de la
  frase secreta para el usuario.
- REGLA: cambios de stats/habilidades/validacion tocan cliente Y server
  (recompilar); cambios solo visuales (draw/indicadores) no tocan server.

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
9. angle_difference/point_direction/degtorad: built-ins disponibles. En
   pantalla Y crece hacia abajo => los draws usan _y - sin(a)*d.

## 9. PENDIENTES / esperando al usuario
- flecha-pegada-v2: pendiente PROBAR en partida (calibracion 14px / 20 grados
  ajustable en un minuto si no convence).
- (nada mas abierto. Los 2 bugs originales del tarot y los sensores ya estan
  cerrados por bugfix-tarot-v1.)

## 10. HERRAMIENTAS PROPIAS (scripts/)
- Aplicadores de parches: apply_bugfix.py, apply_arrowfix.py.
- Validadores: bugfix_v1_validate.py, flecha_roja_v1_validate.py,
  hammer_v1_validate.py, td2dr_validate.py.
- Recon/extraccion del juego: td2dr_parse.py, td2dr_qoi_*.py,
  td2dr_extract.py, td2dr_amy_final.py, td2dr_server_*.py.
- Fraymakers: fra_extract.py, analyze_fra.py, analyze_fra2.py, sally/.
- Misc: check_arrow_colors.py (colores de sprites de flecha).

## 11. CHANGELOG DEL CACHE
- 2026-10-24: v1 creada con barrido completo del proyecto: workspace, juego,
  cliente (302 objetos clasificados), personajes, mapa de flechas con
  colores verificados por pixels (roja=exe->survivor, azul=survivor->exe,
  verde=salida, amarilla=lampara), server, historial de mods, convenciones.
