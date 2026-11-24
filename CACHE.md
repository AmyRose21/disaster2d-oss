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
#   4b. REGLAS DE ORO del duena (2026-11-22): (1) fetch SIEMPRE al iniciar;
#       (2) zip SOLO modificados/creados vs origin/main; (3) re-analizar
#       solo archivos editados recientemente o editados por mi antes del
#       pull; (4) investigar a fondo + registrar en worklog/CACHE;
#       (5) LEARNING.md (ingles) siempre actualizado e incluido en el zip;
#       (6) verificar al 100% (incluye .yyp/.yy/.gml sin errores);
#       (7) pendiente del anti-cheat (nuevos ataques -> excepciones);
#       (8) nada se escapa al editor. Detalle completo: LEARNING.md.
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
  scr_survivor_heal/revive. V76: red ring y anillo normal son LA MISMA
  entidad server-side (Ring.c: flag `red` al 10% al azar) — comparten
  tabla de spawns (obj_ring_spawner por rid) POR DISENO. Variedad de
  spawns = memoria ult-4 en Ring.c (ver 3.4.2 v76).
- Minijuego: obj_minigame + obj_minisnoc_*.

### 3.4.1 ITEM BOX (MONITOR) SYSTEM — "Kafmonitors" (investigated 2026-11-22)
- WHAT IT IS: Sonic-style item monitors ("TV boxes"). In TD2DR they exist
  ONLY in room_kindandfair ("Kind And Fair" / KAF) — no other map uses
  them. Server-authoritative like every other map gimmick.
- THE ONE OBJECT: objects/obj_kaf_speedboobster (folder: Level Specific/
  Kind And Fair; sprite: 30x30, 2 frames: [0]=whole box, [1]=broken).
  Events: Create_0 (nid=0, isBroken=false, audio emitter w/ falloff
  250-500), Destroy_0 (frees emitter), Step_2 (=Step normal event; keeps
  emitter gain tied to camera distance AND breaks on Tails' projectile:
  CLIENT_KAFMONITOR_ACTIVATE nid+proj=true). NO Draw event: the sprite is
  drawn by GameMaker default. image_index doubles as the broken-state
  visual (no sprite change needed).
- BREAKING IT (client side, scripts/scr_collision_objects/
  scr_collision_objects.gml ~L356, inside scr_collision_objects_after()):
  player rect (x±6, y-20..y+20) vs box. Conditions to break:
  !isBroken && image_index==0 && (_isAttacking OR isBoosting).
  _isAttacking covers: EXE, Amy(+canon), Knux, Eggman, Sally(+canon),
  Sonic basic attack; Amy jump/landing (AMY_HJUMP or FALL), anyone
  spinning (isSpinning), Sally slide. EXE with invisTimer>0 CANNOT break
  boxes (anti-grief/stealth design). isBoosting players BREAK boxes on
  touch (boost chains through boxes). The LOCAL client sends
  CLIENT_KAFMONITOR_ACTIVATE (TCP): u8 nid, bool proj=false.
- SERVER (betterserver-oss/disasterserver/entities/KAFSpeedBox.{c,h} +
  maps/KindAndFair.c): kaf_init spawns 11 KafBox entities (nid 0..10),
  kaf_tcpmsg handles the CLIENT packet with AssertOrDisconnect(in_game)
  (anti-cheat: only in-game players, TCP-ordered), nid read WITHOUT
  bounds check on the wire but clamped in effect: client maps nid ->
  instance via instance_find(nid % instance_number). kafbox_activate
  broadcasts SERVER_KAFMONITOR_STATE(2, nid, pid|0) and sets timer =
  (25+rand()%5)*TICKSPERSEC. kafbox_tick: on timer end broadcasts
  state=1 (box REGENERATES/repairs: clients reset image_index=0,
  isBroken=false). kafbox_init (state 0) is the initial-sync frame.
- BOOST (the reward): handled in net_state_game.gml SERVER_KAFMONITOR_STATE
  case (~L2260): state 2 => every client marks the box broken +
  scr_audio_play_3d(snd_break) + net_quick_effect(x+15,y+15,
  spr_explosion) [NOTE: spr_explosion is NOT in global.net_effs array —
  the effect packet writes index -1, so the explosion visual is
  effectively local-only; other clients still see the broken frame].
  ONLY the client whose obj_netclient.nid == _pid (and only if
  !isBoosting already) gets: isBoosting=true, isSpinning=false,
  isJumping=false. If broken by projectile, pid=0 => nobody gets boost.
- BOOST MECHANICS (scripts/scr_move_basic/scr_move_basic.gml ~L267):
  while isBoosting && isGrounded: gspd = 12*image_xscale (fastest run
  in the game), gspd -= 0.125*sin(angle) (slope correction), xspd=
  gspd*cos(angle), yspd = gspd*-sin(angle), then RETURN (skips normal
  control: it's a forced run). effectTime=16 starts the speed-lines
  afterimage (obj Draw_0: every 3 frames spawns scr_effect_fade_quick
  clone). Boost is CANCELLED by: hitting a wall (scr_collision_basic
  xspd=0 on sens collide), springs (scr_collision_objects L171/328
  isBoosting=false), player hurt (scr_player_hurt 5x), move_basic
  clamps, per-character interactions (Knux/Rogue unstick glide,
  Sally shield drop, Eggman shield recharge, Amy canon dash cancel,
  Chaos stuckTimer reset). Amelia docs note (scr_amelia_special header):
  isBoosting is EXCLUSIVE to the boots since v2.4 — her jump no longer
  triggers it (bug: uncontrollable forced run).
- THE TIP: scr_globals.gml L132 (in-game tips array, Kind And Fair tip):
  "avoid breaking speed monitors, as they will launch you right in the
  spikes without letting you stop running until you meet a wall or get
  hurt" — the boost is a HAZARD, not a power-up, in this map's design.
- ROOM PLACEMENT: 11 instances in room_kindandfair "Instances" layer:
  (613,1122) (1810,1378) (2085,530) (2268,530) (2441,530) (2977,930)
  (3371,1234) (3477,610) (3632,610) (3792,610) (3952,610). The
  cluster (3477..3952, y=610) is a runway of 4 boxes.
- NEW ART (owner's commit 9dff8484 "up", 2026-11-21 — she is EXPANDING
  the system): 6 new sprites in folders/Sprites/Objects/Itembox/
  (registered in .yyp + resource_order, all integrity-verified: parse OK,
  frame PNGs + layer PNGs on disk, playbackSpeed 30/5, 30x30 except
  boxused 64x64 1 frame): spr_ring_box (4f), spr_shield_box (4f),
  spr_invincibility_box (2f @5fps), spr_lightning_shield_box (4f),
  spr_speedboots_box (4f, playbackSpeed 0.0 — deliberate: static icon,
  the OLD spr_kindnfair_speedboobs [2f, folder Zones/KindAndFair] still
  exists for the live object), spr_boxused (1f 64x64 — likely the
  post-break "empty box" visual). No new objects/code wired to these
  sprites yet: art-only commit. To USE them: either swap sprite_index on
  obj_kaf_speedboobster per-box-type, or clone the object per type and
  add a boxtype var to the nid/pid protocol (extend the u8 payload —
  protocol 1101 has room; mirror server entities in maps/KindAndFair.c
  kaf_init/kaf_tcpmsg; keep 11-instance nid modulo mapping).
- EXTENDING IT (the recipe): (1) new sprite folder files + .yyp +
  resource_order registration (all 3 must move together — lesson 8.17);
  (2) object variant with its own reward logic in the same
  CLIENT/SERVER_KAFMONITOR_STATE packets (add type byte after nid) OR
  new PacketType entries in net_packets.gml + include/Packet.h (they must
  stay IN SYNC, same numeric order); (3) reward application point for
  local-player effects is the net_state_game case block; (4) boxused
  sprite suggests reusing frame 1 "broken" convention with a dedicated
  empty-box sprite instead of image_index=1.

### 3.4.2 ITEM BOX v2 — random spawn + 5 types (IMPLEMENTED 2026-11-22 as v62; design above executed)
- OWNER REQUEST (v1 spec): used boxes show spr_boxused; the 5 reward types:
  ring_box = +5 rings; shield_box = Sally's shield; invincibility_box =
  invulnerability sparks; lightning_shield_box = Eggman's electric shield
  (same sprite) but stuns attacker and lasts 1 s LONGER than Eggman's;
  speedboots_box = Sonic-classic power sneakers (NOT the Kaf forced run —
  same ghosts/effect visuals OK, but controllable top-speed boost).
- RANDOM SPAWN ANSWER (her question: "how do boxes appear randomly without
  spawning inside walls or pits?"): reuse the house's own proven pattern —
  MANUAL SPAWN POINTS (obj_ring_spawner style), server picks randomly.
  NO runtime collision detection. In KAF there are 32 hand-placed
  obj_ring_spawner positions (280,1000)...(4056,1256) that are valid by
  construction. RECOMMENDED OPTION B: new obj_box_spawner object with
  ~20 hand-placed positions (owner drags them in the GM editor where she
  wants boxes; her level-design workflow is manual placement everywhere:
  32 ring spawners, 5 ringspawn, 4 spawnpoint, 4 exespawn in KAF alone).
  Server holds bool taken[N] (like game.rings[256]) and rolls every
  BOX_SPAWN_COFF=20 s while active boxes < 4 (MAX_BOXES), no boxes in
  first 15 s of round, respawn cooldown 25 s per spawner (Kaf value).
  Weights: ring 35% / shield 20% / invincibility 15% / lightning 15% /
  boots 15% (macros, editable).
- REWARD NUMBERS (exact values reused from code, all verified):
  +5 rings, capped 119 (anti-cheat disconnects at 120+ — net_state_game
  SERVER_RING_COLLECTED); Sally shield = shieldTimer 5*60 (scr_sally_special
  L223) + 60f invuln on break (scr_player_hurt L657, works for any char
  after extending the SALLY condition to any shieldTimer>0 — 1-line);
  invincibility = hurttime 3*60 (scr_player_hurt L802; 1*60 last minute;
  guard: never re-activate while hurttime>0); lightning shield =
  NEW electricShieldTimer 60*2.5 (Eggman's is 60*1.5 = +1 s longer, per
  owner request; draws spr_electroshield like obj_egg/Draw_0 L22 and
  puppet Draw_0 L235; attacker that hits the bearer gets shockedTimer=60
  in THEIR client, same side as damage; does not stack with Sally shield);
  boots = NEW bootsTimer 60*8: controllable speed (effective maxHSpeed+3,
  acc*1.5, effectTime ghosts) — explicitly NOT isBoosting (Kaf trap stays
  untouched; scr_amelia_special header lesson: isBoosting is boots-only
  by design since Amelia v2.4).
- PROTOCOL (extend, don't invent): CLIENT_BOX_ACTIVATE (was
  CLIENT_KAFMONITOR_ACTIVATE): u8 sid + bool proj, same semantics.
  NEW SERVER_BOX_SPAWN (state=3): u8 sid, u8 type, u16 sx, u16 sy —
  coordinates travel IN THE PACKET (server is the single truth of
  position; more robust than instance_find(nid%n)). SERVER_BOX_STATE
  (was SERVER_KAFMONITOR_STATE): u8 state (2=broken+reward, 1=repair),
  u8 sid, u8 type (travels every state so late joiners rebuild), u16 pid.
  All TCP + AssertOrDisconnect(in_game): identical anti-cheat surface
  (golden rule 7); cheaters can at most re-break a broken box = no-op.
  CRITICAL: net_packets.gml (210 entries) and include/Packet.h (212)
  MUST stay in the same numeric order — new PacketTypes go at the end of
  BOTH in the same commit (protocol 1101 breaks silently otherwise).
- CLIENT OBJECT: new obj_itembox (clone of obj_kaf_speedboobster pattern:
  Create sid/type/isBroken/audio emitter falloff 250-500, Step emitter
  gain + tails-projectile break with proj=true, NO Draw event, sprite per
  type: spr_ring_box / spr_shield_box / spr_invincibility_box /
  spr_lightning_shield_box / spr_speedboots_box, broken → spr_boxused).
  Body-break stays centralized in scr_collision_objects_after (~L356):
  same rect (x±6, y-20..y+20), same _isAttacking conditions (all
  characters covered), EXE invisible cannot break (anti-grief kept),
  isBoosting players break on touch. Reward applied ONLY in
  net_state_game case (local pid match, same guard pattern as boost).
- SERVER ENTITY: clone Ring.c pattern into entities/ItemBox.c + extend
  kaf_init/kaf_tcpmsg in maps/KindAndFair.c (fields: sid, type, timer,
  activated; spawn roll = rand()%free_spawners with goto-gen retry,
  EXACTLY Ring.c ring_init's loop). Lazy vars convention (coyoteTimer
  pattern) for electricShieldTimer/bootsTimer — do NOT touch ~20 Create
  events of characters.
- ROOM: obj_box_spawner instances hand-placed (Option B). AVOID the Kaf
  boost runway (y=610, x 3477-3952) so the trap is not reward-stacked.
  KAF room is 4352x1536; solids are obj_solid_block/2 (spr_block 128x128,
  collisionKind 0 = full-bbox), 70 spikes, 61 blocks, 32 ring spawners.
- IMPLEMENTATION ORDER (4 phases, each independently testable):
  F1 object+protocol (one hand-placed box: break→+5 rings→respawn);
  F2 spawners+server roll; F3 the 5 reward types (touches the 2 most
  sensitive files: scr_player_hurt + scr_move_basic — golden rule 6
  full power + check_vXX.py validator per house convention); F4 balance
  macros + LEEME + CACHE update + live full-game test.
- OPEN DECISIONS LEFT TO OWNER: box count (proposed 4 live), spawn
  interval (proposed 20 s), exact ~20 spawner positions (her level
  design), boots jump-boost (proposed NO), lightning shield persist
  after box break (proposed YES, 2.5 s is short anyway).

- IMPLEMENTATION v62 (same day, 2026-11-22): ALL 4 phases landed in one pass.
  Deliverables: obj_itembox (Create/Step_2/Destroy + .yy, folder Spawners,
  registered in .yyp between obj_hn2_slope2/obj_jack_in_the_box); entities
  ItemBox.h/.c (broadcast carries state/nid/type/pid/sx,sy — server is the
  only truth of position; timer<0 alive, countdown 25+rand(5) then entity
  dies; activate idempotent); KindAndFair.c kaf_tick (18 hand-placed
  spawners in kaf_itembox_spawns[] derived from ring-spawner ground
  heights, off the Kaf boost runway; roll every 20 s after first 15 s,
  max 4 alive; weights 35/20/15/15/15 via itembox_roll_type; goto-gen
  over free spawners exactly Ring.c pattern; Maps.c entry now uses
  kaf_tick — declared in KindAndFair.h; CMakeLists has ItemBox.c).
- Protocol: CLIENT_BOX_ACTIVATE + SERVER_BOX_STATE appended AT THE END of
  BOTH enums (verified 184=184 positional sync). SERVER_BOX_STATE states:
  3=spawn / 2=broken+reward to pid / 1=ready. Client case in net_state_game
  (before SERVER_NAPBALL_STATE): spawn creates/reuses obj_itembox at
  (sx,sy) with sprite by type; broken switches to spr_boxused + 3D break
  + explosion; ONLY pid client applies reward: ring +5 capped 119 /
  shield shieldTimer = ITEMBOX_SHIELD_TIME macro (v71: TRULY works for
  ANY char — guarded set in net_state_game, generic tick in
  scr_move_basic EXCEPT Sally/SallyCanon/Rouge whose specials own the
  full cycle, generic consume in scr_player_hurt, bubble overlay in all
  22 Draw_0, PLAYER_SALLYSHIELD bit sent for every character and written
  unconditionally on the puppet; before v71 it CRASHED on every char
  except Sally/SallyCanon/Rouge), invincibility hurttime 3*60 (guard:
  only if hurttime<=0), lightning electricShieldTimer 60*2.5 (lazy var),
  boots bootsTimer 60*8 (lazy var) + snd_spring.
- Body-break: scr_collision_objects block cloned from Kaf L356 (same rect
  x±6/y±20, same _isAttacking character list, isBoosting breaks on touch,
  EXE invisible cannot) but sends CLIENT_BOX_ACTIVATE with the ITEMBOX nid.
  Tails-projectile break copied in obj_itembox/Step_2.gml (proj=true,
  nobody collects).
- Electric shield visuals: all 22 character Draw_0.gml got the 2-line
  overlay (pattern obj_egg/Draw_0 L22, lazy-var guard). Puppet side:
  NEW bit PLAYER_ELECTROSHIELD shares bit 7 with PLAYER_SLIME (safe:
  slime is Chaos-EXE-only, electroshield is survivor-only — same
  non-collision argument as PLAYER_DJ; byte passes through Game.c
  untouched). obj_netclient/Step_2 sets it while electricShieldTimer>0;
  net_udpprocess reads it into puppet.electroShield; puppet Draw_0 draws
  the same spr_electroshield overlay after the character switch.
- Electric shield STUN on attacker: the house channel for victim->attacker
  stun is net_sound_emit_at(snd_metal_stun, attacker_nid) (shouldPlay=true
  targeted CLIENT_SOUND_EMIT — EXACTLY scr_parry_stun_signal's pattern
  with snd_exe_stun). Receiver added in net_state_game CLIENT_SOUND_EMIT:
  if sid==snd_metal_stun and I'm EXE/demon attacking (isAttacking or
  isJumping or isSpinning) and not already stunned: shockedTimer=60,
  knockback -3/-2, shockparticle quick effect + snd_exe_stun. Victim side
  (scr_player_hurt): electricShieldTimer>0 consumes the shield, 60f
  i-frames, shockparticle broadcast, finds nearest attacking puppet
  within 64px for the nid, sends the targeted signal.
- Boots: scr_move_basic ticks electricShieldTimer/bootsTimer BEFORE the
  isBoosting block (independent: NOT the Kaf forced run); boots set
  effectTime=16 so the EXISTING ghost-trail (PLAYER_EFFECT bit + all 22
  Draw "effectTime % 3" fades + puppet fade ghosts) just works, zero new
  draw code. Speed: flat-run caps left/right now use _capH/_acc computed
  per frame (maxHSpeed+3, acc*1.5 while bootsTimer>0); slopes/friction
  untouched. CONTROL TOTAL kept: no forced gspd, brakes when the player
  wants (explicitly NOT isBoosting — Amelia v2.4 lesson stands).
- Owner-bug fixed on arrival: commit 0f989734 had spr_invincibility_box
  in .yyp but MISSING from resource_order (8.16 failure mode: sprite
  invisible in editor). Inserted entry (order 6, before spr_kris_attack1
  _air1 alphabetically among present names).
- check_v62.py: 34-assert validator (enum sync 184=184 + tail order,
  object files + yyp registration, case states + all 5 reward values +
  pid-only guard + sprites/boxused, collision rect + anti-grief,
  server files + weights + goto-gen + in_game + idempotente, bit macro +
  emitter + receiver + puppet overlay + hurt block, boots caps/acc/
  ghosts, 6 sprites in yyp+resource_order). ALL OK. Also ran: brace
  balance on 12 modified GML files (all balanced) and gcc -fsyntax-only
  on ItemBox.c/KindAndFair.c/Maps.c (clean; Log.h RAssert-if expansion
  artifacts are pre-existing — identical on untouched Ring.c... note
  Ring.c baseline shows 0 because it doesn't use PacketCreate at
  top-level statement position; the 7 Log.h errors on ItemBox.c match
  the KAFSpeedBox.c pattern with stdlib included).
- FIX POST-ENTREGA (2026-11-22 mismo dia, reporte de la dueña con el
  build MSVC real): ItemBox.c linea 25 C2059/C2449 — habia envuelto
  PacketCreate/PacketWrite en un RAssert(...) exterior. Esas macros YA
  expanden a RAssert(...) (Packet.h L429-433, Log.h L52), asi que
  RAssert(if(...)) no compila. Corregido al patron exacto de la casa
  (KAFSpeedBox.c L8/Ring.c L31: PacketCreate/PacketWrite desnudos);
  verificado gcc -fsyntax-only -I include (con stub enet) = 0 errores en
  ItemBox.c/KindAndFair.c/Maps.c. La nota previa sobre "7 errores de
  Log.h en ItemBox.c" era ESTE bug mal diagnosticado (no un artefacto
  preexistente): KAFSpeedBox.c no lo mostraba porque nunca anido. ZIP
  v62_itembox reempaquetado con el fix + LEEME nota FIX POST-ENTREGA.
- FIX POST-ENTREGA 2 (LNK2019 reportado por la duena con el build MSVC):
  itembox_uninit estaba declarado en ItemBox.h y referenciado por el
  macro MakeItemBox pero NUNCA definido en ItemBox.c -> linker sin
  resolver desde KindAndFair.obj (kaf_tick expande el macro). Definido
  (silencioso, NULL-convenio invertido: Ring.c define uninit, KafBox
  pasa NULL — itembox necesita definido porque el macro lo nombra).
  Bonus del diagnostico: al expirar la rota ahora se difunde
  SERVER_BOX_STATE state=4 despawn y el cliente DESTRUYE la instancia
  boxused (net_state_game bloque _state==4 antes del _state==1);
  antes quedaba colgada indefinidamente si ese nid no re-salia
  sorteado. Packet.h comment actualizado con el state 4. Verificacion
  END-TO-END nueva: no solo sintaxis — gcc -c de ItemBox.o/
  KindAndFair.o/KAFSpeedBox.o reales + LINK con stubs de infra
  (packet_new, server_broadcast, game_spawn/find, map_*) = 0
  undefined references (scripts/link_check_v62.c + link_stubs_v62.c
  guardados). check_v62.py 50/50 OK tras el cambio de cliente.
- v63 (mismo dia, pedido de la duena tras probar la v62: "algunas cajas
  estaban en el aire... se me ocurrio una idea"): 4 reglas suyas ->
  implementadas todas:
  (1) GRAVEDAD: obj_itembox nace CAYENDO (grounded=false, vspd con la
  gravedad de entidades de la casa 0.2 — patron obj_darktower_sisipart)
  y el Step_2 la clava en obj_floor_parent con polvo scr_effect_quick.
  (2) NUNCA-REPETIR: itembox_last_spawner veta el spawner del roll
  anterior (goto-gen con free_count>1).
  (3) RESIDUO GIGANTE (bug real): spr_boxused 64x64 con contenido
  abajo (y 32-63, midido con PIL: bbox opaco 64x32) vs cajas 30x30 ->
  Create pone image_xscale/yscale 0.47 y el state 3 las resetea (el
  residuo ocupa ~30px como la caja).
  (4) ZONAS = ring spawners FILTRADOS (derive_spawns_v63.py sobre
  room_kindandfair.yy real): de 32 quedaron 9 — descartados los altos
  (y<900: fila 496/537), sin-suelo-en-400px (abismo real: 280,1000 /
  640,1064 / 680-728,924 / 1832-2024,1328 / 2916,952 / 3068,1168 /
  3556,1240), con-resorte-cerca (680,924 vs obj_bspring_right 640,952,
  radio 48) y redundantes (<96px). Tabla final +24px offset de la fila
  de anillos: (1104,940)(2792,956)(2992,1168)(3240,1240)(4080,1256)
  (1132,1276)(2560,1376)(2656,1376)(1296,1388).
  (5) TP SI TRAMPOLIN/ABISMO: nuevo paquete CLIENT_BOX_RELOCATE(nid) al
  FINAL de los DOS enums (186=186 sync, enum_sync_v63.py con strip de
  comentarios /* */ — el check v62 contaba items dentro de comentarios
  y por eso daba 324 vs 333: falsos positivos); handler KindAndFair.c
  marca box->relocated (nuevo campo bool en ItemBox.h, MakeItemBox
  pasa 0 extra); kaf_tick fuerza timer=0 en las relocated (mueren via
  uninit=state 4) y el MISMO tick sortea el reemplazo. Cliente:
  report_relocate() method en Create (cpacket+send, reported 1x,
  visible=false), Step reporta si place_meeting(obj_spring_parent) o
  fuera de room. Rotura (cuerpo y proyectil) solo grounded && !reported.
  Verificado: gcc+LINK REAL 0 undefined, GML balanceado, check_v63.py
  TODO OK (v2+v3, 64 checks), enum 186=186.
- v64 (mismo dia, tras capturas de la duena en juego real: "salen debajo
  de tierra... la caja se ve diminuta" — VLM midio la viva a ~16px vs
  ~24px que debe, flotando/mal ubicada; la rota OK): DOS bugs medibles:
  (A) el 0.47 del residuo se ponia en Create -> TODAS las cajas vivas
  diminutas; (B) derive asumiendo tiles de suelo 64x64 cuando spr_block
  es 128x128 (yy_sprite_parse) -> suelo corrido 64px -> cajas bajo
  tierra. FIX: Create/state3 escala 1.0 en la viva; SOLO state2 (rota)
  pone image_xscale/yscale 0.47 + y -= 15 (contenido del boxused vive
  en y 32-63: residuo visible ~30x15 en la mitad superior del hueco,
  matematica validada por script); tabla re-derivada con derive_spawns_
  v64.py (tiles 128, y = top_suelo - 30 = APOYADA, x+24 re-verificado
  en el x final): 13 zonas (vuelve 304,994 que la v63 descarto por
  falso abismo del tile corrido; la 704,924 recupera suelo a 128px);
  Step del aterrizaje: tras el while retrocede+30 (se apoya con la
  BASE), polvo en y+30. Verificado: gcc+LINK 0 undefined, check_v64.py
  TODO OK (66 checks: escala 1.0 viva en codigo real sin comentarios,
  residuo 0.47+y-15, tabla 13 con 304,994/728,922/1296,1378).
- v65 (tras captura 660x480 de la duena: CERO cajas visibles; los 2
  monitores grises con estatica son TV del shelter obj_angleallower
  spr_red 32x32, decorativos — VLM 2 rondas: sin icono, marco gris,
  ~70px escalados): dos bugs reales: (A) Step_2 v64 tenia "y += 30"
  tras el while(place_meeting) y-=1 -> caja ENTERRADA 30px bajo la
  superficie = invisible ("salen debajo de la tierra"); (B) derive v64
  aplicaba +24 en x SIEMPRE -> 6/13 zonas con x final fuera del ancho
  del solido -> caja cayendo al vacio en bucle de RELOCATE (por eso
  tampoco se veian). FIX: Step_2 sin el +=30 (while apoya exacto,
  polvo en y+30); derive_spawns_v65.py con ground_below (top a 0..64px
  bajo el anillo, tiles 128 reales) y x condicional (+24 solo con
  suelo en x final, si no columna del anillo): 15 zonas, verificacion
  final 0 sin suelo (recupera 1188/1412 injustamente descartadas).
  Verificado: gcc+LINK 0 undefined, check_v65.py TODO OK (68 checks:
  tabla 15 con 1188/1412/3068 sin 3092, sin "y += 30" en codigo real,
  polvo y+30). El zoom visual de la captura: TV 32px se ve ~70px ->
  escala ~2.2; nuestras cajas 30px se veran ~66px en pantalla.
- v66 (captura 144x144 de la duena, VLM x4 + pixeles): (A) residuo
  rota FLOTABA ~15px sobre el suelo — el "y -= 15" del estado 2 en
  net_state_game.gml estaba INVERTIDO: contenido spr_boxused (filas
  32-63) a escala 0.47 cae en local y 15-30 del area de 30px = YA
  apoya; fix = quitar el -=15 (solo 0.47 + grounded). (B) 2 cajas en
  un slot: used[] del roll solo marcaba vivas (timer<0) — rota en
  countdown (residuo 25-30s) liberaba su spawner; fix = used[] marca
  TODA entidad existente + sin re-freesado del relocated ("zona OTRA"
  estricta). check_v66.py TODO OK (73 checks); gcc+LINK 0 undefined.
- v67 (sim C real de 2 rondas): RE-ENTRADA a Kind sin cajas para
  siempre — UB en kaf_tick: "ItemBox boxes[N]" por VALOR castearlo a
  (Entity**) (game_find escribe PUNTEROS) y leer boxes[i].timer/.nid
  in-place = basura; en MSVC alive puede leer >=4 -> roll bloqueado
  para siempre (y used[] leia nid falsos -> slots fantasma). Fix:
  ItemBox* boxes[] + -> (patron de la casa, igual que kaf_tcpmsg).
  Extra cliente: state 1 re-difusion crea la instancia faltante como
  ROTA (boxused 0.47) si no existe. Sim: antes nid=0/timer=0/pos=(0,0)
  en todas (UB directo); con fix 4-6 cajas por ronda rompiendo cada
  30 s. check_v67.py TODO OK (79 checks).
- v68 (duena: "hay que aplicarselo a todos los mapas" + reglas de oro
  1-8): SISTEMA CENTRAL ItemBoxMap.c/.h (roll + ACTIVATE/RELOCATE) para
  TODOS los mapas con tabla auto-generada ItemBoxSpawnTables.c
  (derive_spawns_all_v68.py: semillas obj_ring_spawner, suelo real =
  familia obj_floor_parent resuelta por CADENA DE PARENTS dinamica con
  dims del sprite escalado; Torture Cave/Haunting Dream = mega-sprites
  de colision per-pixel leidos del PNG (verde 0,255,27 / amarillo
  251,242,54); vetos resorte/hazard 48px, nada de fila alta 40%,
  dedupe 96x64, y=top_suelo-30). 25/25 mapas (min 3, total 262).
  Hooks en states/Game.c (el REAL de CMake; el disasterserver/Game.c
  de la raiz es copia vieja QUE NO COMPILA — no tocar): checkstart ->
  itemboxmap_init (reset por ronda EXPLICITO, sin heuristicas de
  elapsed), state_tick -> itemboxmap_tick, handletcp ->
  itemboxmap_tcpmsg (packet_seek(0) tras el tcp_msg del mapa).
  KindAndFair.c vuelve a stock (KafBox monitors; tabla v65 = mapa 7
  en el dispatch). Sim multimap 10/10 rondas OK (5 mapas x 2,
  rompiendo cada 30 s) + link 0 undefined + check_v68.py TODO OK
  (30 checks). NUEVOS ARCHIVOS DE CONOCIMIENTO: LEARNING.md (ingles,
  regla 5) + CACHE.md en ingles pendiente de migrar seccion por
  seccion (se mantiene comoindice bilingue).
- Known deltas vs design doc (doc said "extend KAFMONITOR pair"; final
  choice was a cleaner NEW pair + activation kept as new CLIENT_BOX_
  ACTIVATE — same semantics, no versioning ambiguity between states with
  and without type byte): SERVER_BOX_STATE is new (not KAFMONITOR
  renamed); state 1 'ready' kept for re-broadcast only.
- v69 (BOT AUDIO, entregada como zip v69 — el repo de GitHub aún NO la
  tiene): snd_speedboost.ogg (owner upload 6977f00a, 32.8 s) suena en
  LOOP durante las botas y la música del nivel se silencia con el
  método del anti-camping (obj_player_warning: duck
  audio_sound_gain(global.music, 0, 2000) / restore
  audio_sound_gain(global.music, obj_config.musicVolume * 0.1, 500)),
  vía helpers scr_music_duck/scr_music_unduck en scripts/scr_music/
  scr_music.gml (guard global.music == -1). Fin del efecto en 4
  caminos (todos restauran): expiración natural (scr_move_basic, frame
  exacto), muerte (scr_player_instakill resetea bootsTimer + stop +
  unduck), LMS (SERVER_GAME_LMS antes de la canción del show), fin de
  ronda (SERVER_RESULTS antes de room_goto). snd_speedboost en
  global.sfxList (slider SOUND VOLUME en vivo). Archivos: scr_music,
  net_state_game, scr_move_basic, scr_player_hurt, scr_menu_more.
  NET: cero paquetes nuevos (regla 7 limpia).
- v70 SUITE CAJAS (owner: "añade al suite la opcion para configurar el
  tiempo de las cajas (speed y invulnerabilidad)"): the four reward
  durations are now MACROS at the top of scripts/net_state_game/
  net_state_game.gml (GM convention: ALL ~745 repo macros live at file
  level, never inside a function): ITEMBOX_SHIELD_TIME (60*5),
  ITEMBOX_INVULN_TIME (60*3), ITEMBOX_ELECTRIC_TIME (60*2.5),
  ITEMBOX_BOOTS_TIME (60*8). The four case literals in switch(_type)
  now assign the macros. SUITE_TD2D.html gains a NEW module "📦 Cajas"
  (Sistema category, data-mod="boxes"): reads net_state_game.gml,
  renders 4 .cdrow rows (slider+number in SECONDS, house CSS), edits
  via AnimCore.setMacro (preserves (60 * N) format), syncs to
  S.pendingFiles/S.edits, writes via T.writeEdits (backup
  _backups_animeditor + undo), re-enters via S.onAfterWrite chain,
  discards via T.discardModulePending (Bx.ready=false re-reads disk).
  NOTE hurttime: the box grants the SAME i-frame timer the standard
  hit uses, but this macro only feeds the BOX value (the hit's own 60
  in scr_player_hurt is untouched).

- v73 (2026-11-23, feedback de la duena) — 2 reglas nuevas sobre este
  sistema:
  (A) EXE DENIAL: "los Exes no podran obtener buff pero si pueden
      destruir las cajas negandole el buff al que esta pasando por
      ahi". Server-side (la capa que manda, regla 7):
      ItemBoxMap.c CLIENT_BOX_ACTIVATE calcula
      uint16_t reward = (v->server->game.exe == v->id) ? 0 : v->id;
      (game.exe = peer id del Exe de la ronda, expresion exacta de
      Lib.c disaster_server_peer) y itembox_activate difunde el
      break con pid 0 = NADIE cobra (el convenio que ya existia para
      breaks por proyectil de Tails: peer ids empiezan en 1, Server.c
      v->id = incomingPeerID + 1, peer_msg rechaza id 0 => pid 0
      nunca coincide con un cliente real). El Exe rompe atacando
      (scr_collision_objects SIN cambios: EXE en la lista de ataque,
      invisible sigue sin poder — anti-grief) y todos ven la caja
      romperse; nadie aplica el buff. v74: los monitores Kaf de
      KindAndFair.c QUEDAN FUERA del veto (orden de la duena) —
      KindAndFair.c byte-a-byte intacto; quien rompe un monitor Kaf
      cobra el boost, Exe incluido, como siempre. Cliente (defensa en
      profundidad contra binarios mezclados viejo/nuevo):
      net_state_game.gml tiene 1 guarda nueva if(global.character ==
      CHARACTER_EXE) break; justo tras el check obj_netclient.nid !=
      _pid, SOLO en el case SERVER_BOX_STATE state 2 (rewards de
      caja); la seccion SERVER_KAFMONITOR_STATE queda SIN guarda
      (KAF original). CHARACTER_EXE lo
      comparten las 6 variantes de killer (Original/Chaos/Exetior/
      Exeller/MetalAmy/Jinna: global.exeCharacter lleva la variante).
      Cero paquetes nuevos / protocolo intacto.
  (B) FIX INMUNIDAD: "si el jugador obtenia otra inmunidad (cajas
      invulnerable) no se reiniciaba la duracion max". El case 2 del
      reward tenia guard if(global.player.hurttime <= 0) (patron
      !ya-activo del boost Kaf) => con CUALQUIER inmunidad vigente
      (otra caja o los i-frames del golpe de 180f) la caja nueva se
      gastaba en vacio. Ahora la asignacion es incondicional:
      global.player.hurttime = ITEMBOX_INVULN_TIME (= 60*6.25 = 375f)
      — cada caja invulnerable SIEMPRE reinicia al maximo. Los cases
      1/3/4 (escudo/electrico/botas) CONSERVAN su guard !ya-activo
      (semantica intencional de la casa: no apilan ni refrescan).

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

### 3.7 SQUASH & STRETCH — WSS v72 (port del mod Lua de SRB2, 2026-11-23; RETUNED v73, ENTREGADO EN v74)
- scripts/scr_wss/scr_wss.gml = TODO el sistema (4 funciones + 16 macros
  WSS_*): scr_wss_update (jugador local, la engancha el FINAL de
  scr_collision_basic — los 22 personajes la llaman desde su Step_0
  despues de resolver el suelo), scr_wss_puppet_update (puppets,
  enganchada en obj_player_puppet/Step_0 antes del bloque f2 de Sally
  Canon), scr_wss_return (vuelta al reposo, compartida) y scr_wss_draw
  (devuelve [fx, fy, yoff]; identidad [1,1,0] si wssSq==0/apagado/sin
  datos => el draw queda bit-a-bit igual).
- QUE HACE: el cuerpo se estira al despegar (salto/pendiente) y se
  aplasta al aterrizar (impacto = ultimo yspd en el aire), con vuelta
  sharp/smooth/jelly. Estilos por macro (como el Lua): STRETCH Classic
  (flanco de despegue + justJumped para el coyote) / Airflow (continuo
  por |yspd|); SQUASH Landing (impacto) / State (cambio de sprite en
  suelo, salta bola/carga/aterrizaje) / Speed (postura por |gspd|,
  saturando en WSS_SPEED_FULL=12, asignacion absoluta como el Lua);
  RETURN Sharp/Smooth (decay 0.10)/Jelly (muelle
  K=0.035 D=0.88, overshoot -0.138 (~31% de la amplitud, misma
  proporcion que v72), 3 cruces, 60 frames — calibrado por
  simulacion).
- v73/v74 RETUNE (feedback: "la caida se nota un poco pero el salto y
  lo demas no se nota mucho"; la v73 nunca se aplico — v74 la entrega): WSS_STRETCH_MAX 0.35->0.45,
  WSS_TAKEOFF_GAIN 0.045->0.085, WSS_AIRFLOW_GAIN 0.030->0.055,
  WSS_SQUASH_MAX 0.30->0.42, WSS_IMPACT_GAIN 0.030->0.050,
  WSS_STATE_SQUASH 0.18->0.24, WSS_SMOOTH_DECAY 0.12->0.10.
  Numeros nuevos (salto jumpForce 7): estiron 0.450 (SATURA el tope;
  antes 0.315), visible frame 1: 0.405 (antes 0.277), aplaste salto
  normal -0.35 (antes -0.21), caida fuerte -0.42 (satura), Smooth
  37f (antes 28f), Sharp 15f, Jelly 60f/3 cruces/-0.138. Solo macros:
  cero logica nueva, las formulas/anclaje red intactas.
- ANCLAJE AL SUELO (mismo metodo que _f2yoff): yoff = (sprite_height -
  sprite_yoffset) * (1 - escalaY_total) => el pie queda plantado.
- DONDE SE APLICA: los 22 Draw_0 de personajes (linea base
  draw_sprite_ext del cuerpo + helper scr_wss_draw; la rotacion/alpha
  propios de cada uno quedan intactos), obj_sally_canon Draw (compone
  con su fase2Sq: multiplicativo, yoff sobre la escala TOTAL) y
  obj_player_puppet Draw (compone con f2Sq igual). NO aplica a: estelas
  ghost (copian image_xscale crudo), powerboost aura, escudos/burbujas
  (draw aparte), Draw_64/72/76 (GUI/animacion, no dibujan cuerpo).
- PUPPETS: SOLO eventos discretos (despegue/aterrizaje) derivados del
  yspd + state JUMP/FALL que YA viajan en CLIENT_PLAYER_DATA — cero
  bytes nuevos de red. LIMITACION CONOCIDA: el salto en bola viaja
  como state SPIN => en pantallas ajenas ese salto no estira (en la
  del dueno si). Correr pendiente (WALK + yspd!=0) NO dispara squash
  falso (verificado por simulacion en check_v72).
- image_xscale/image_yscale JAMAS se tocan (image_xscale es la
  DIRECCION: gspd = 12 * image_xscale en el spindash; y la mascara de
  colision escala con ellos) — la escala WSS solo entra multiplicada
  en los argumentos del draw_sprite_ext.
- Guards (leccion v71): scr_wss_update exige isGrounded+yspd
  declarados; scr_wss_puppet_update exige yspd (pre-primer-paquete);
  scr_wss_draw exige wssSq. Lecturas de justJumped/isSpinning/
  isSpinCharging/gspd siempre tras variable_instance_exists (&& puede
  cortocircuitar en el codigo original y no existen en todos).
- Macros tuneables desde el Suite (motor #macro de AnimCore, patron
  ITEMBOX_*_TIME v70). WSS_ENABLED 0 = sistema apagado, draws
  identicos. Validador: check_v75.py (SUSTITUYE a check_v73.py: lexer
  balance 28 GML, parches v72 intactos + valores v74 exactos, fix
  inmunidad y exe-denial SOLO-cajas-nuevas verificados, KindAndFair.c
  PRISTINO exigido, musica de botas de la duena protegida como
  invariante, gcc -fsyntax-only de los .c del server con stub enet
  auto-generado, .yyp 2542 recursos sin dupes, superficie git nucleo
  v74, cero protocolo/netclient, simulacion numerica completa con los
  macros nuevos).

### 3.4.3 v76 — HAZARD RELOCATE + SPAWN VARIETY (2026-11-23, commit base 61a5e248)
- PEDIDO: (a) cajas que caen en lava/precipicio se reubican solas en otro
  spawn ring; (b) spawns SIEMPRE variados (rings y cajas), nunca el mismo
  sitio una y otra vez.
- CLIENTE obj_itembox/Step_2.gml: bloque v76 NUEVO (tras la fisica v63,
  corre en CUALQUIER estado cayendo o apoyada, guard !reported):
  place_meeting contra obj_abyss (precipicio: teleporta players, las
  cajas lo atraviesan), obj_vv_lavacolumn (lava VV: su y la sincroniza
  el server — puede ERUPCIONAR sobre una caja apoyada) y obj_spike
  (estaticos); rect MANUAL para obj_marijuna_lavaplatform (x+48..x+113 /
  y+48..y+672 — EXACTO al rect que lastima al player, su mascara no
  representa la zona letal). Reporta por el canal v63 existente
  CLIENT_BOX_RELOCATE (one-shot `reported` cliente + `relocated` server).
  EXCLUIDOS A PROPOSITO (spawn valido: la caja es alcanzable):
  obj_ghz_water (nadable), obj_ycr_smokearea (roba 1 ring/s), barridos
  periodicos (movingspike, limpcity_echain1, darktower_ball/sisi,
  marijuna_judgerpor).
- SERVER Ring.c: memoria FIFO ult-4 slots (ring_recent[4] en Game struct
  — SE AUTO-RESET por ronda via el literal compuesto, patron bring_loc;
  nada de reset manual). Veto: si hay slots libres NO-recientes, los
  recientes quedan vetados (goto gen). Simulacion: caidas en ventana
  ult-4 6.4% -> 0%. ANTES solo se vetaban los OCUPADOS (un anillo
  recogido en X podia renacer en X). Roll rojo/paquetes INTACTOS.
- SERVER ItemBoxMap.c: itembox_last_spawner (ult-1) -> FIFO ult-3
  (itembox_recent[]). Simulacion: caidas en ventana ult-3 14% -> 0%.
  El veto v74 exe-denial y el flujo relocate quedan INTACTOS. Una caja
  reubicada NUNCA renace en su misma zona (used[] se computa antes de
  la muerte del tick; 100% en simulacion).
- SERVER Server.h: +ring_recent[4]/ring_recent_len en Game (struct
  interno, CERO protocolo: Packet.h y net_packets.gml sin cambios).
- Ring.c ahora incluye <stdlib.h> explicito (rand() iba implicito;
  ItemBoxMap.c ya lo hacia asi — gcc moderno lo exige).
- Validador: check_v76.py (SUSTITUYE a check_v75.py): lexer GML, nucleo
  v63 intacto, bloque v76 completo, rect Marijuna cross-checkeado contra
  el Step del player, gcc -fsyntax-only Ring.c+ItemBoxMap.c con stub
  enet, superficie v74 preservada, .yyp 2542, CJK-clean. Simulador:
  sim_v76.py (metrica de ventana + deadlock + relocate != misma zona).

### 3.4.4 v77 — NOT PERFECT: CAJAS QUE SIGUEN A LA ZONA (2026-11-23, commit base 847cf443)
- PEDIDO: "fix para Not Perfect — la zona cambia cada cuanto? en las
  distintas fases las cajas solo se quedan en un solo lugar".
- DIAGNOSTICO (evidencia de codigo): Not Perfect (map id 6) rota su area
  jugable entre 4 CUADRANTES del room 5520x2736 (state 0=TL,1=TR,2=BL,
  3=BR; teleport ±2904 x / ±1368 y en net_state_game.gml al recibir
  SERVER_NPCONTROLLER_STATE del NPController "npctrl"). La zona cambia
  cada ~20 s (15 s NPC_NONE + 5 s NPC_PREPARE) y cada ~5 s (2 s + 3 s)
  en el ultimo minuto (~16 cambios por ronda de 155 s). La tabla v68
  (itembox_spawns_6) tenia sus 29 puntos SOLO en la mitad inferior
  (19 BL + 10 BR, y 1650..2346): en las zonas 0/1 (mitad superior) NO
  EXISTIA ninguna caja alcanzable y las vivas de 2/3 quedaban lejos,
  ocupando la pool de ITEMBOX_MAX=4 => "las cajas se quedan en un solo
  lugar".
- METODO v68 RECUPERADO (reversado de la tabla existente, verificado
  29/29 EXACTO): cada punto v68 = obj_ring_spawner + 24 px en x, con el
  suelo en ventana de 40 px bajo el ring (los rings flotan ~24 px sobre
  su plataforma), caja apoyada y=top_suelo-30, dedupe 96x64, sin
  resorte a 48 px. La mitad superior tiene 30 ring spawners propios
  (posiciones validadas por la autora del mapa).
- SERVER ItemBoxSpawnTables.c: itembox_spawns_6 29 -> 56 zonas (APPEND
  puro: nid 0..28 IDENTICOS — ningun indice existente cambia). 27
  nuevos: 13 TL (zona 0) + 14 TR (zona 1), generados con el metodo
  v68 y validados: suelo real (obj_solid_block 128x128*scale /
  obj_platform_jumptrough 64x32*scale, parser robusto de instancias
  multi-linea del .yy), posicion FINAL de reposo del cliente (el while
  de Step_2 empuja la caja al top mas alto) fuera de TODOS los rects
  prohibidos del anti-cheat (Zone.c room_notperfect, BLOCK_SIZE=128:
  los rects son los cuerpos solidos; + margen de player de pie), sin
  resorte a 48 px. Nota: el editor reindento tabs->espacios todo el
  archivo (mismo patron v76 en Ring.c/ItemBoxMap.c; solo estetica).
- SERVER ItemBoxMap.c:
  (a) np_current_zone(): game_find tag "npctrl" -> stage%4 (-1 si no
  hay controller o mapa != 6: fallback al comportamiento v76, NUNCA
  bloquea el spawn). np_zone_of(px,py) = (x>=2904) + 2*(y>=1368).
  (b) itembox_spawn_one(): roll refactorizado a candidatos pre-filtrados
  por zona actual (en NP solo spawnea DENTRO de la zona); FIFO ult-3
  v76 INTACTO sobre los candidatos; goto gen termina siempre (los
  candidatos libres existen por construccion).
  (c) itemboxmap_tick(): el procesado de relocate/zona corre CADA TICK
  (antes solo en el tick del roll de 20 s): npctrl_tick corre ANTES en
  el mismo tick (game_state_tick: entity tick -> map tick -> itemboxmap)
  => la reubicacion sale en el MISMO tick que el teleport de players.
  Las VIVAS fuera de la zona actual -> relocated=true + timer=0 (mismo
  canal v63: despawn state 4 + respawn en OTRO punto, su spawner queda
  ocupado ese tick => nunca renace en su punto).
  (d) Repoblacion inmediata: want = max(1 si roll, min(removed,
  MAX-alive_after)) — las cajas SIGUEN a la zona (poblacion preservada
  en cada cambio, verificado 8000 cambios simulados) y las reubicadas
  por lava v63/v76 TAMBIEN renacen ya (antes hasta 20 s de espera).
  (e) ITEMBOX_FIND_MAX = ITEMBOX_MAX*6 = 24 (era *3=12: con 4 vivas + 8
  residuos boxused concurrentes el find se saturaba y podia bloquear
  la repoblacion; aplicado en tick + spawn_one + ACTIVATE + RELOCATE).
- CLIENTE: CERO cambios (todo server-driven por SERVER_BOX_STATE; el
  teleport de players ya existia; los puntos TL/TR no tienen hazards —
  el room solo tiene bspring_up como peligro de caja, excluido a 48 px).
- ANTI-CHEAT (regla 7): CERO protocolo nuevo (Packet.h/net_packets.gml
  intactos). El nuevo relocate es SERVER-INITIATED (sin input cliente).
  Los 27 puntos validados contra player_check_zone (ningun player de
  pie junto a una caja cae en rect prohibido; el mapa 6 ya tenia la
  excepcion suave +30 errores por tick por sus areas grandes).
- Validador: check_v77.py (SUSTITUYE a check_v76.py): tabla 56 + append
  puro + 27 puntos fisicamente validados contra el room + FASE 1 29/29
  + 28 checks de logica + gcc -fsyntax-only -Wall -Wextra + superficies
  intactas + .yyp 2542 + CJK-clean. Simulador: sim_v77.py (500 rondas
  x ~16 cambios: 0 cajas fuera de zona, 0 renacimientos en el mismo
  punto, poblacion preservada; mapa normal 0% ventana-3; fallback 20/20).
- GENERADORES (workspace): scripts/gen_np_top_v77.py (FASE 1 reverso +
  FASE 2 TL/TR), scripts/analyze_np_v77.py + analyze_np2_v77.py
  (geometria del room: 4 cuadrantes NO copias, blocks/rects/springs).

### 3.4.5 v78 — CINCO PEDIDOS DE LA DUEÑA (2026-11-23, base 9a9f909a con v77 aplicada + sus macros retuneados por ella: SHIELD 7.5 s / INVULN 7 s / ELECTRIC 7 s / BOOTS 17 s en net_state_game.gml)
1) SONIC y KRIS SOLO DE OPERADORES ("no se puede usar de manera normal"):
   el mismo doble-seguro que Sally Canon. SERVER: states/CharSelect.c
   CLIENT_REQUEST_CHARACTER gana 2 bloques (id == CH_SONIC / CH_KRIS con
   !v->op -> SERVER_LOBBY_CHARACTER_RESPONSE result=0, ANTES de tocar
   lobby.avail[]; el slot queda libre) con Info() de auditoria. CLIENTE:
   scr_char_locked (scr_survivors.gml) gana 2 ifs (CHARACTER_SONIC /
   CHARACTER_KRIS && !global.isOperator): el no-op ni los ve al ciclar
   (obj_lobby/obj_lobby_icon ya llaman scr_char_locked). El comentario
   viejo "Sonic libre para todos" se retiro de ambos lados. Amy Canon /
   Vanilla / Rouge siguen siendo solo-token; Sally Canon solo-op.
   CERO protocolo nuevo (SERVER_OPERATOR_STATE ya existia).
2) ENFRIAMIENTO 30 s POR CAJA DESTRUIDA (ItemBoxMap.c + ItemBox.h):
   - BUG RAIZ del "destruyo 1 y enseguida aparece otro de la nada":
     ITEMBOX_FIRST_DELAY (15) y ITEMBOX_SPAWN_COFF (20) se usaban en
     CRUDO contra server->game.elapsed — que cuenta TICKS a 60/s (delta=1
     por tick de 1000/60 ms, ver states/Server.c loop + game_state_tick).
     Resultado real desde v62: primer roll a 0.25 s y roll cada 0.33 s —
     el mapa se reponia casi al instante. v78: *TICKSPERSEC en los 3
     usos (init, recovery, roll_now) = 15 s reales + cadencia 20 s reales.
   - COLA v78: itembox_respawn_left[8]/n (static, reset por ronda en
     itemboxmap_init Y en la recovery <0). CLIENT_BOX_ACTIVATE agenda
     push(30 s) SOLO si la caja estaba VIVA (was_alive = !activated ANTES
     de itembox_activate: la rota re-rompida es no-op idempotente, no
     agenda nada — anti-cheat intacto). El Exe que rompe (v74 denial)
     genera el MISMO enfriamiento.
   - TICK: la cola decrementa SOLO mientras alive_after < ITEMBOX_MAX
     ("el contador no empezara a ir hacia atras si el max de cajas esta
     cubierta" — regla LITERAL de la duena); cada entrada que llega a 0
     spawnea su caja y sale (pop-compacto con reexamen del indice); si
     el sorteo no encontro punto libre, la entrada queda en 0 y
     REINTENTA (itembox_last_spawn_ok: spawn_one devuelve true SIEMPRE —
     semantica RAssert — el flag dice si spawneo de verdad).
   - El roll de relleno corre SOLO con itembox_respawn_n == 0: JAMAS
     repone una destruida antes de sus 30 s. En la practica el roll solo
     llena el arranque (15 s + 1/20 s hasta MAX 4 = 75 s).
   - REUBICACIONES (lava v63/v76, zona v77) SIGUEN INMEDIATAS (no son
     destruccion): el want/back v77 intacto. NUEVO: una caja que ya estaba
     ROTA (activated) cuando le toco reubicarse NO cuenta como removed
     (su reposicion ya tiene su cooldown agendado — sin doble repoblar).
   - Macros ItemBox.h: ITEMBOX_RESPAWN_COOLDOWN 30 (s); FIRST_DELAY y
     SPAWN_COFF ahora documentados en segundos (multiplican TICKSPERSEC
     en ItemBoxMap.c).
3) FIX RINGS DE LA CAJA (net_state_game.gml, SERVER_BOX_STATE state 2,
   case 0): antes solo hacia rings = min(+5, 119) + snd_ring — los
   anillos de la caja NUNCA pasaban por la cura de 10 anillos (solo los
   del mapa la aplican, 3 copias: SERVER_RING_COLLECTED y 2 handlers de
   SERVER_RING_STATE). Ahora case 0 aplica la cura IDENTICA: rings>=10 &&
   hp < maxhp && rings>0 (mirror local del canHeal del server = plr.rings
   > 0) -> rings -= 10, hp +20 con techo, snd_heal + net_sound_emit,
   CLIENT_STATS_REPORT tipo 0 (hp_restored++) y contador del logro de 3
   curas. Sin cura -> snd_ring como siempre.
4) INMUNIDADES AL ROMPERSE LOS ESCUDOS (scr_player_hurt + 2 macros nuevos
   en net_state_game.gml, junto a los que la duena retuneo):
   - ITEMBOX_ELECTRIC_BREAK_INVULN (60*2.5): al EXPLOTAR el escudo
     electrico absorbiendo un golpe, hurttime pasa de 60f (1 s) a 2.5 s
     de inmunidad de dano. El stun al atacante (net_sound_emit_at
     snd_metal_stun) INTACTO.
   - ITEMBOX_SHIELD_BREAK_INVULN (60*4): la invulnerabilidad tras
     romperse el escudo de burbuja (el de Sally, caja tipo 1) pasa de
     60f a 4 s (1 s base + 3 s pedidos). Sally Canon conserva su macro
     propia (SALLY_CANON_SHIELD_BREAK_INVULN).
   - AMBOS con max(hurttime, X): nunca ACORTAN una inmunidad vigente
     (p.ej. quedaban 7 s de caja invulnerable y explota el electrico ->
     se conservan los 7 s).
5) BOTON V MOVIL 4o PRINCIPAL (spr_mobile_button frames 6/7): pixel-art
   generado con la paleta EXACTA de los frames A/B/C (tonos
   k=16,16,16 / L=161,157,166 / m=105,105,105 / d=61,61,61 y version
   roja del pressed; erase del glifo viejo + V nueva en la zona de letra
   x16-31/y17-30; fuera de esa zona identico al frame 0/1). YY: 2
   GMSpriteFrame + 2 keyframes Key 6.0/7.0 + sequence length 8 (validado
   JSON). Flujo completo:
   - obj_config.vMainTouch {xx:378, yy:121} (rombo: V arriba de A,
     B arriba-derecha, A/C abajo; 100 px del dpad, 104 de la columna de
     emotes) + defaults + load() con try/catch (guardados pre-v78 caen al
     rombo) + save(). Variables bV2X/bV2Y/bV2Scale/bV2Opacity.
   - obj_controls/Draw_64 (bloque bUse): frame 6 normal / 7 presionado,
     SOLO en partida (if(jUse) — en lobby la V no hace nada, igual que
     antes). obj_controls/Create: buttonSetProp/buttonSetPos case 10.
   - scr_controls_update_touch: el bloque V pasa a DOS circulos con UN
     solo VTouchId (pequeno r22 + principal r40): prende dentro de
     cualquiera, suelta fuera de ambos (un dedo que deslice entre ellos
     no re-dispara — patron casa W/emotes). El principal solo responde
     con jUse. VPressed (global.KeyV, v4.0 parry de Amy Canon) REUTILIZADO.
   - scr_controls_init_touch: defaults bV2 (378,121).
   - Editor de Options > Controls: obj_menu_mobilebutton Draw_0 case 10
     (handle grande), sliderChanged de obj_menu acepta bid 10 en la rama
     de botones grandes, instancia room_menu inst_7B84C2DA (bid 10,
     imageIndex 6, x 378 y 121) en la capa OptionsControlsMobile +
     instanceCreationOrder + FALLBACK POR CODIGO en obj_menu/Create_0
     (patron AboutAmyCanon: si el IDE compilo un room_menu viejo, el
     handle se crea por codigo — cero duplicados si la room cargo bien).
   VERIFICACION: check_v78.py (86 checks: contenido exacto de los 5,
   anti-cheat superficial congelado, gcc -fsyntax-only los 3 .c, .yyp
   2542 intacto, room lenient-JSON, CJK-clean) + sim_v78.py (20 checks:
   S1 15 s/20 s reales, S2-S4 30 s por caja exactos, S5 pausa con el max
   cubierto + reanudar, S6 reubicadas mismo tick, S7 idempotencia, S8
   reset por ronda, S9 FIFO ventana-3 0%, S10 Exe igual) + lint de
   llaves/parens de los 10 GML tocados (0 desbalance).
   ZIP: download/v78_operator_only_box_cooldown.zip. RECOMPILAR EL SERVER
   (CharSelect.c + ItemBoxMap.c + ItemBox.h cambiaron).

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
- RESERVA DE PERSONAJES (todo el estado al 2026-11-23 v78): solo-token de
  Amy (amy_authed) = Amy Canon, Vanilla, Rouge; solo-OPERADOR (v->op /
  global.isOperator) = Sally Canon, SONIC y KRIS (v78: "Sonic y kris
  pasaran solamente para uso de operador"); publicos = Tails, Knux,
  Eggman, Amy, Cream, Sally, Metal, Amelia, Blaze, Fleetway Amy. La capa
  que manda es el SERVER (states/CharSelect.c responde result=0 como si
  estuviera ocupado, ANTES de tocar avail[]); scr_char_locked es la cara
  del cliente (el no-op ni los VE). Ver 3.4.5 punto 1.
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

### SLOTS DE PERSONAJE (avCharacters) — seguro v2.2.3 (2026-10-31)
- scripts/scr_characters/scr_characters.gml = UNICO dueno del array
  avCharacters (slots libres/ocupados por pj; indice = macro CHARACTER_*).
  Nacio del crash "Variable Index [13] out of range [11]" en
  obj_lobby/Draw_0:121: el literal estaba copiado en 7 sitios y v2.2
  (Blaze=13) solo actualizo 3.
- Macros derivados solos: CHARACTER_SURV_MAX (ultimo survivor, apunta al
  ULTIMO macro de scr_survivors), CHARACTER_COUNT (+exe), EXE_CHAR_COUNT
  (ultimo macro de scr_exe), LOBBY_CHARS_MIN (entradas de chars[]).
- API: scr_avchars_reset() array fresco (exe=false resto=true) |
  scr_avchar_get(ch) lectura blindada (fuera de rango = OCUPADO + log) |
  scr_avchar_set(ch,val) escritura blindada (crea slots al vuelo si un
  server mas moderno manda un pj desconocido; huecos nuevos = ocupados
  = innombrables) | scr_characters_sanity() lo llama obj_lobby/Create_0
  UNA vez por arranque: loguea [charsanity] lo que falte en
  chars[]/palettes/player_anims/player_get, nunca crashea |
  scr_char_name(ch) nombres para logs.
- Los 7 ex-literales ahora son "avCharacters = scr_avchars_reset()":
  obj_netclient/Create_0, net_wrapper, net_tcpprocess, net_state_game
  x3, obj_level/Alarm_2. Accesos blindados ademas: obj_lobby/Draw_0
  (+clamp de sprInd contra chars[]), obj_lobby_icon/Draw_0,
  net_tcpprocess (player left), net_state_charselect x2.
- PARA AGREGAR UN PJ NUEVO: macro AL FINAL en scr_survivors (o scr_exe
  si es killer) + player_anims + case en player_get + assets del lobby
  (chars[], tira spr_lobby_icon, placa spr_char_info, exeicon, paleta
  default) + enum CH_*/EX_* AL FINAL en betterserver include/Server.h
  + nombre en states/CharSelect.c (survs[]/exes[]). El array de slots y
  el sanity se ajustan solos; si falta un asset, [charsanity] avisa al
  arrancar en vez de crashear en partida.

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
- v73/v74 (2026-11-23): PRIMER cambio server-side desde v68 —
  entities/ItemBoxMap.c gana el veto de Exe en el handler
  CLIENT_BOX_ACTIVATE (reward pid 0 si game.exe == v->id; ver 3.4.2
  v73-A). v74: maps/KindAndFair.c QUEDA INTACTO por orden de la
  duena (monitores Kaf con comportamiento original). gcc
  -fsyntax-only con stub enet (punteros opacos: ENetPeer/ENetHost/
  ENetPacket + ENetPeer.roundTripTime) verifica ambos .c sin traer
  el submodule. La expresion game.exe == v->id es la MISMA que Lib.c
  usa en produccion (disaster_server_peer) => riesgo MSVC ~0.
  OJO: el usuario debe RECOMPILAR el server (compilar_server.bat
  opcion 2) para el veto server-side; sin recompilar, las guardas
  del cliente siguen negando el buff en el cliente del Exe.

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
| parry-v3.5/v4.x    | Parry Sonic(C)/Amy(V) + auto-stun + HUD (ver 7.2)              | (zips parry) |
| carry-v1           | Tails/Cream LLEVAN aliados volando + fix velocidad Amy (ver 7.3)| carry_v1.zip |
| vanilla-v2         | Vanilla v2: Chocola, paciencia, float run, pasivas (ver 7.4)  | vanilla_v2.zip |
| vanilla-v2.1       | Chocola visible en el exe (senal dive) + bloqueo 65%/CD 2.5 s (ver 7.4) | vanilla_v2_1.zip |
| vanilla-v2.1.1     | HOTFIX crash puppet.isGrounded en pantallas donde Vanilla es remota (ver 7.4) | vanilla_v2_1_1.zip |
| vanilla-v2.1.2     | HOTFIX crash cream.pacienciaState al saltar (ver 7.4)           | vanilla_v2_1_2.zip |
| vanilla-v2.1.3     | HOTFIX crash net_tcpprocess.type + cooldowns de habilidades POR JUGADOR en el server (ver 7.4) | vanilla_v2_1_3.zip |
| vanilla-v2.1.4     | FIX sonido de stun de Chocola en la pantalla del exe (ver 7.4)  | vanilla_v2_1_4.zip |
| vanilla-v2.2.2     | FIX de compilacion de v2.2: crash eventList invertido + 1.161 PNG de layers (ver 7.4.1) | vanilla_v2_2_2_compilefix.zip |

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

### 7.3 CARRY v1: Tails y Cream llevan aliados volando (ver LEEME_CARRY_V1.txt)
- FIX velocidad Amy Canon: scr_collision_basic v4 exceptua el clamp para
  CHARACTER_AMY_CANON con isDashing||isTarotDashing (tope max de sus macros
  14/14). Antes la acometida (C) y el tarot aereo (X) salian a 11 (=maxHSpeed)
  aunque sus macros prometian 14: mismo bug que el spindash de Sonic (fix v3
  que solo exceptuaba a Sonic+isSpinning).
- MECANICA: cualquier superviviente en el aire que TOCA a un Tails/Cream en
  estado TAILS_FLY/CREAM_FLY se agarra (dist<=32px) y cuelga CARRY_HANG_Y=26px
  debajo, viajando en el estado *_ZIPLINE de SU personaje (sprite de tirolina
  ya existente para los 9) mientras su cliente pega su x/y al puppet del
  portador cada End Step. Suelta con Z (hop -6.5 + keyboard_key_release,
  patron tirolina; cooldown 2s) o el portador con V (senal: net_sound_emit_at
  snd_snap al nid del colgado; rama nueva en CLIENT_SOUND_EMIT de
  net_state_game junto a las del parry). Auto-suelta en todos los casos
  logicos (portador aterriza/para/herido/muerto/desconecta/demoniza; colgado
  toca suelo/herido/muerto/demoniza). 1 pasajero por portador. Tails gasta
  vuelo 1.5x (drain entero alternando frames: no rompe el mod 18 del sonido).
- ARQUITECTURA: scripts/scr_carry/scr_carry.gml (toda la logica; macros
  CARRY_* ajustables al inicio) + objects/obj_carry_controller (Create + End
  Step; lo crea obj_spawnpoint DESPUES del player => su End Step corre
  ultimo: el snap es la ultima palabra del frame, como la tirolina;
  inicializa las 4 vars del carry en la instancia al cambiar de player; el
  EXE nunca lo crea). Guards por personaje con short-circuit (bubbleState/
  isTarotDashing/etc solo se leen siendo Amy Canon, nerviosState siendo
  Sonic, isGliding siendo Knux, isFlying/flyTimer siendo Tails/Cream).
- Guards anti-robo en obj_aiz_zipline/Step_2.gml: SONIC y SALLY_CANON no
  tenian check de estado ZIPLINE (a todos los demas ya los cubria el
  original): sin ellos la tirolina ROBABA a un llevado al pasar sobre su
  punto de inicio.
- CERO server, cero paquetes nuevos, cero assets: estados ZIPLINE y
  PLAYER_DATA existentes + 1 rama de sonido. Extraer + reabrir GameMaker.

### 7.4 VANILLA V2: Chocola + paciencia + float run + pasivas (ver LEEME_VANILLA_V2.txt)
- ARQUITECTURA CHOCOLA: obj_chocola existe en TODOS los clientes como
  simulacion local (patron pets: lerp 0.21 + bob, sprite Idle/move/
  attack/support_power del usuario). Transiciones por BROADCASTS de
  sonido: snd_mermer(108)=caza, snd_ready(111)=va con Cream,
  snd_npteleport(112)=recall, snd_achivement(113)=custodia cumplida,
  snd_creamring CON EMISOR Vanilla = support power (hook en el with
  del CLIENT_SOUND_EMIT, net_state_game). STUNS al exe: senales
  shouldPlay=true a su nid (snd_nono(109)=5 s paciencia,
  snd_vasebreak(110)=1.5 s cercano) -> scr_chocola_stun_signal en el
  cliente del exe (dedup shockedTimer, +CLIENT_PLAYER_HURT para el
  shake + scr_exe_stunsound). NINGUNO de los 6 sonidos se emitia por
  red antes (verificado): las ramas son exclusivas.
- PACIENCIA (1ra caida, scr_player_instakill intercepta SIN avisar al
  server, patron burbuja/nervios/fase2): 5 s quieta+inmune (guard en
  scr_player_hurt; salto bloqueado en scr_move_basic); a los 2 s sale
  Chocola desde el lado contrario de la pantalla (x±520) y el reloj
  se CONGELA hasta golpear al exe (failsafe 8 s / exe fuera); exit:
  agotada 1 s -> hp 100 + i-frames 2.5 s. CONSERVA sus anillos.
- MORIBUNDA (2da caida y TODAS las siguientes): 6 s tirada (pose
  agotada) + se levanta con 30 hp + 3 s i-frames. Vanilla NUNCA
  muere server-side: guards CH_VANILLA en game_demonize y
  CLIENT_PLAYER_DEATH_STATE (muerte directa canon por si un cliente
  viejo la mata: jamas demonizada).
- FLOAT RUN: correr sostenido a 11 (1.5 s) -> tope rampa +0.03/f
  hasta 14 (~3.2 s totales); pose estado 17 (spr_vanilla_float_run)
  + afterimages locales (Draw_0, obj_quickeffect_fade 0.07/5f) +
  REMOTAS via bitflag PLAYER_POWERBOOST en obj_netclient (el ghost
  del puppet en Step_0 es generico if(powerBoost), NO solo-Sonic).
  maxHSpeed = floatRunCap (var del player, seteada por
  scr_vanilla_v2_step); el clamp de scr_collision_basic usa
  maxHSpeed -> NO hacia falta excepcion como en el fix v3/v4.
- ESTADOS 17/18/19 en player_anims/eanims[VANILLA] (20 entradas);
  paciencia pisa la cadena de Step_2 tras shockedTimer.
- PASIVAS: anillos Vanilla VALEN 4 (server Game.c MakeCreamRing;
  viaja en el u8 worth de SERVER_RING_COLLECTED); Cream 2 si hay
  Vanilla in_game (loop de peers server-side). FORTALEZA:
  scr_player_hurt pierde 15% (Vanilla) / 30% (Cream con Vanilla via
  scr_vanilla_in_match) min 3 anillos, en vez de todos. Bloqueo
  Chocola 65% v2.1 (exeSource) con hurttime 150 + spr_shieldbreak;
  ataque 33% a <90 px (no si exe isHurt) stun 1.5 s; CD compartido
  2.5 s v2.1 (chocolaCd en el player). MINI-EMBESTIDA V2.1: se anuncia
  por red (snd_chocola_dive, indice 114, asset nuevo) desde el cliente
  que la rolla (Vanilla en el 33% cercano, Cream en la custodia) ->
  rama CHOCOLA_NET_HUNT_SMALL del CLIENT_SOUND_EMIT: cada cliente pone
  su Chocola en CHOCOLA_HUNT hacia el exe DESDE DONDE ESTA (sin
  reposicionar, authority=false). Antes solo la veia el cliente que la
  rollaba y el exe recibia el stun sin verla venir.
- TECLA V (scr_vanilla_v2_step): FOLLOW -> GO_CREAM (velocidad 7,
  NO la de caza 14; valida Cream hp>0 y revivalTimes<2); GO/GUARD ->
  RETURN rapido (12). Gate scr_carry_find_hanger == noone (no pisar
  el drop del carry). Custodia en Cream: cura 15% AL LLEGAR (+30 hp,
  rolla el cliente de Cream) + bloquea 1 dano (exe O entorno) o
  stun 33%; consumida -> snd_achivement broadcast -> todos vuelven.
- DES-DEMONIZACION: unico paquete NUEVO (CLIENT/SERVER_VANILLA_
  DEDEMONIZE = 144/145, al final del enum en AMBOS lados, mismo
  orden). Trigger automatico en scr_vanilla_v2_step: esbirro con
  revivalTimes>=2 && state DEAD (stuneado; los esbirros nunca estan
  caidos) a <64 px y rings>=15 -> CLIENT_VANILLA_DEDEMONIZE(nid).
  Server valida (CH_VANILLA, in_game, target != v, PLAYER_DEMONIZED,
  dist<=150 server-side) -> DEL PLAYER_DEMONIZED + SET PLAYER_REVIVED
  ("1 caida mas para re-demonizarse") + broadcast. Cliente objetivo:
  revivalTimes=1, hp 100, i-frames 2 s, paleta normal +
  net_send_palette, destruye obj_demon_indicator. SIN el DEL_FLAG el
  AssertOrDisconnect de CLIENT_PLAYER_DEATH_STATE desconectaba al
  esbirro en su siguiente caida (flag demonizado en server vs
  revivalTimes 1 del cliente).
- MADRE E HIJA: obj_family_indicator (flecha amarilla
  spr_sindicator3, depth -200, >400 px, clientes de Vanilla Y Cream,
  la crea obj_spawnpoint con gate character). Detectores exe/ring de
  Vanilla: obj_vanilla_indicators (clon exacto de amycanon, lo crea
  obj_vanilla en su Create). Cream NO los tiene.
- REQUIERE RECOMPILAR SERVER (worth 4/2 + dedemonize). Validador:
  scripts/vanilla_v2_validate.py (174 checks + sims de reloj).
  Aplicador: scripts/apply_vanilla_v2.py (50 ops, marcadores
  idempotentes; OJO: versiones < final tenian un bug y escribian en
  --dry — siempre git status antes/despues de un dry).

### 7.4.1 HOTFIXES v2.1.1 - v2.2.2 (todos aplicados en el repo del usuario)
- v2.1.1 (crash "obj_player_puppet.isGrounded not set" en obj_chocola
  Step_0 cuando Vanilla es remota): puppet Create_0 + `isGrounded =
  true;` y la regla de sprite FOLLOW usa xspd/yspd (SI viajan por red)
  en vez de isGrounded. Validador: vanilla_v2_1_1_validate.py.
- v2.1.2 (crash "obj_cream.pacienciaState not set" en scr_move_basic:652,
  Cream salta con Chocola encima): la rama CREAM||VANILLA leia vars
  solo-Vanilla; defaults defensivos en obj_cream/Create (pacienciaState,
  moribundaState, ringsSpawn...). Validador: vanilla_v2_1_2_validate.py.
- v2.1.3 (crash "obj_netclient.type not set" en net_tcpprocess:81 cuando
  Vanilla y Cream sueltan anillos casi a la vez): DOBLE bug — el server
  expulsaba al 2.o jugador (cooldowns de habilidades GLOBALES) y el
  handler del paquete de kick leia `type` sin definir (bug del juego
  base). Fix cliente: leer [u8 reason][string msg] + break que faltaba.
  Fix server: cooldowns POR JUGADOR (PeerData.plr_cooldowns, Server.h +
  states/Game.c). REQUIERE recompilar server. Validador:
  vanilla_v2_1_3_validate.py (incluye lint del stack de red completo).
- v2.1.4 (fix de sonido, "cuando Chocola stunea no se oye el sonido de
  stun al exe"): en scr_chocola_stun_signal el grito vivia DESPUES del
  return del dedup (exe ya stuneado => golpe de Chocola mudo) y cuando
  sonaba era SOLO el grito. Ahora suena golpe canonico (snd_exe_stun,
  mismo que parry/laser/contra-golpe) + grito (scr_exe_stunsound),
  ANTES del dedup y siempre; el golpe viaja por red (3D en los demas
  clientes). Solo cambia scr_chocola.gml, CERO server. Validador:
  vanilla_v2_1_4_validate.py (regresion 2.1.1+2.1.2+2.1.3 incluida).
- v2.2.1 (linking, el proyecto NO ABRIA tras v2.2): los .yy de los 4
  net_* traian parent folders/Scripts/Net.yy (carpeta nunca dada de
  alta en el .yyp) -> reparent a folders/Scripts/Networking/
  Specific.yy (junto a net_projectile/net_sounds). Cero .yyp/.gml/server.
- v2.2.2 (el proyecto ABRIA pero NO COMPILABA — dos bugs del
  importador TTB invisibles para el IDE):
  * CRASH IndexOutOfRange en GMObject.GetEventName_Simple: los .yy
    de obj_metal/obj_amelia/obj_blaze/obj_metalamy traian el
    eventList con DOS entradas de campos invertidos:
    "eventNum":0,"eventType":64 y "eventNum":0,"eventType":76
    (tipos de evento inexistentes; la tabla del compilador llega a
    ~14). Los reales: eventType 8, num 64 (Draw GUI) y 76; ref
    upstream obj_aiz_zipline (type=8 num=76). Fix: reescritura
    textual de esas 2 lineas en los 4 .yy.
  * ~200 "File missing for GMSprite": cada .yy declara su capa
    GMImageLayer con GUID G1 pero el PNG de cada frame se guardo
    como layers/<frame>/<G2>.png (G2 distinto: dos tiradas del
    generador). Fix: creados los 1.161 layers/<frame>/<G1>.png
    copiando el PNG existente en cada dir (8.190 ya existian bien).
    Abarca los 148 sprites TTB + spr_char_info (16 f) y
    spr_lobby_icon (13 f), que mezclan layers del upstream.
    Los <G2>.png viejos quedan huerfanos (inofensivos).
  Fix integrado + validador: scripts/fix_v22_compile.py (0 missing,
  eventList exacto {(0,0),(3,0),(8,0),(3,2),(2,4),(8,64),(8,76),
  (7,7)}, parents OK). Entregable: vanilla_v2_2_2_compilefix.zip.

## 8. CONVENCIONES Y TRAMPAS DEL CODIGO (lecciones pagadas — leer ANTES de editar)
1. SANGRIA MIXTA (mapa verificado en vanilla-v2): ESPACIOS de 4 en
   scripts/scr_survivors, scr_player_hurt, scr_carry, scr_parry,
   net_sounds, net_state_game, net_packets, scr_move_basic y
   obj_amycanon_indicators (este a 8); TABs en objects/obj_vanilla*,
   obj_netclient, obj_spawnpoint, pets y la mayoria de objects/*.
   Verificar SIEMPRE con `sed -n 'Np' archivo | cat -A` (o python
   repr) antes de intentar un match; hay espacios finales tras
   'else' y '{' en archivos del usuario (ej. obj_vanilla/Create_0).
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
10. ERRATAS QUE ROMPEN LA COMPILACION (vanilla-v2-fix1): el validador
    comprobaba logica pero NO sintaxis pura. Dos clases se colaron:
    (a) insertar elementos despues del ULTIMO de un array (snd_parry
    era el final de global.net_snds sin coma -> pegar snd_mermer:
    "expected ',' or ']'"); (b) 'break:' con DOS PUNTOS en un switch
    ("unexpected symbol ':'"). Ambas vivian en las CADENAS del
    aplicador (apply_vanilla_v2.py). REGLA: todo parche que empalma
    con el final de una lista debe anadir la coma al elemento previo;
    y tras aplicar, correr scripts/gml_syntax_audit.py (0 sospechosos
    = compile limpio de esas familias; calibrado: 875 .gml del repo,
    0 falsos positivos). Ya integrado como seccion 13 del validador
    de vanilla v2 (check 'sintaxis <archivo>' por cada GML tocado).
11. avCharacters (slots de pj): NUNCA acceder directo con
    avCharacters[ch] ni duplicar el literal (causa del crash "Index [13]
    out of range [11]" del 31/10: 4 de 7 copias quedaron con 11 slots
    tras v2.2). Todo pasa por scr_avchar_get / scr_avchar_set /
    scr_avchars_reset de scr_characters.gml. Lo mismo chars[] del lobby:
    obj_lobby/Draw_0 ya clampa sprInd antes de indexar.

12. SPRITES LAYERED (hudbar-v2.5): al anyadir frames a un sprite por
    script, el composite <frameGuid>.png en la RAIZ de sprites/<spr>/ es
    OBLIGATORIO (la texture page NO mira layers/). El PNG interno va en
    layers/<frameGuid>/<capaDefault>.png con el GUID de la capa default
    del .yy (no un GUID aleatorio). Sintoma de composite perdido:
    sprite renderiza basura/nothing solo para los frames nuevos. Auditor
    reutilizable: scripts/audit_sprite_frames.py del workspace del agente.
    Los ~85 PNG huerfanos por carpeta (raiz+layers, GUIDs del TTB
    original) son casi seguro el arte de Silver/Shadow/Lord X/Koloosos
    para el port futuro: NO borrarlos.


14. COOLDOWN DEL SERVER vs RECARGA DEL CLIENTE (trampa-v2.8): el
    server JAMAS debe ser mas lento que la recarga legitima MAS RAPIDA
    del cliente (o come paquetes en silencio: el cliente ya gasto su
    recarga y sueno el spawn). Y ojo con los "max N vivas POR jugador"
    compuestos con entidades de vida larga: si vida > recarga, TODA
    colocacion del hueco vida-recarga se descarta sin feedback. Sintoma
    universal: "el cliente lo hace pero en el server no aparece".
    REGLA: cooldown server <= recarga minima legitima (trampa 15 s,
    bola de fuego 4 s) y sin limites de vivas: nid por entidad.
15. FISICA DE PROYECTILES EN EL SERVER SIN COLISION DE MAPA
    (blaze-v2.9): el server no tiene el tilemap; para que un proyectil
    REBOTE, cualquier cliente reporta el choque (nid + componentes a
    invertir + posicion del solape) y el server voltea la velocidad.
    DOS sincronizaciones obligatorias: lockout por entidad (todos los
    clientes ven el mismo choque y reportan casi a la vez: gana el
    primero) y throttle local (no re-reportar cada frame mientras
    llega el arreglo por TCP). Clasificar el eje del choque probando
    POR DONDE ESCAPA la mascara (retroceder 2 ticks de velocidad por
    eje), nunca con 1 px (el solape llega a ser de un tick entero).
    La chispa del choque va con scr_effect_quick LOCAL (net_quick_
    effect la reenvia a todos y se multiplica por cliente).

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
- LMS v5.0: pendiente PROBAR en partida real (2 ventanas: EXE mata al
  2do superviviente -> banner + Undefeatable + reloj 4:42 + Sonic a
  100; mitad de golpes bloqueados; stuns de 5 s; sin marca de Metal
  Amy). OJO: RECOMPILAR el server (enum nuevo en los 2 lados).
- carry-v1: pendiente PROBAR en partida real (2 ventanas: colgarse de un
  Tails volando, soltar con Z, soltar con V, auto-sueltas, y notar la
  acometida/tarot de Amy a 14). Guion de 8 pasos en LEEME_CARRY_V1.txt.
- (Los 2 bugs originales del tarot y los sensores ya estan cerrados por
  bugfix-tarot-v1. Worklog y CACHE sincronizados con el repo 26/10.)
- v76: pendiente PROBAR en partida real (recompilar server OBLIGATORIO):
  (1) caja en Volcano Valley cuando erupciona la columna -> se reubica
  sola; (2) anillos/cajas apareciendo en sitios variados (no repiten
  zona reciente); (3) romper cajas normal (regresion del nucleo v63).
- v77: pendiente PROBAR en partida real (recompilar server OBLIGATORIO):
  en Not Perfect las cajas deben aparecer DENTRO de la zona actual y
  mudarse con cada cambio (cada ~20 s, ~5 s al final); antes de que
  cambie la zona, romper una caja (regresion v63/v74); verificar que en
  el ultimo minuto (cambios cada 5 s) el server no se cae y las cajas
  siguen la rotacion; en OTROS mapas todo igual que v76.

## 10. HERRAMIENTAS PROPIAS (scripts/)
- IMPORTANTE (26/10): la carpeta scripts/ del workspace NO existe en este
  sandbox (rollback). La lista de abajo es el inventario HISTORICO; si se
  necesita una herramienta, recrearla segun la descripcion de su entrada
  en worklog.md. Convencion del proyecto: scripts/apply_<task>.py =
  aplicador de ediciones quirurgicas (match exacto == 1 vez, TABs
  literales); scripts/<task>_validate.py = validador post-edicion.
- (30/10, vanilla-v2) scripts/ EXISTE de nuevo en este sandbox con:
  apply_vanilla_v2.py (+v2_content.py), vanilla_v2_validate.py (195
  checks, seccion 13 = sintaxis), apply_flybuff_v1_*.py,
  flybuff/carry validadores, y gml_syntax_audit.py (AUDITOR
  SINTACTICO GML reutilizable: `python3 scripts/gml_syntax_audit.py`
  audita los GML de la ultima task; `--all` audita los 875 del repo.
  Caza: comas faltantes id+id/]+id dentro de expresiones, 'break:'/
  'continue:', ternarios encadenados a profundidad 0 (excluye
  accessor [?), desbalance de llaves. Entiende $hex, #hex, strings
  multilinea y el separador de sentencia por salto de linea).
- Aplicadores de parches (historico): apply_bugfix.py, apply_arrowfix.py.
- Validadores (historico): bugfix_v1_validate.py, flecha_roja_v1_validate.py,
  hammer_v1_validate.py, td2dr_validate.py.
- Recon/extraccion del juego (historico): td2dr_parse.py, td2dr_qoi_*.py,
  td2dr_extract.py, td2dr_amy_final.py, td2dr_server_*.py.
- Fraymakers (historico): fra_extract.py, analyze_fra.py, analyze_fra2.py.
- Misc (historico): check_arrow_colors.py (colores de sprites de flecha).

## 11. CHANGELOG DEL CACHE
- 2026-11-23 (v78 — OPERATOR-ONLY + ENFRIAMIENTO POR CAJA + FIX CURA RINGS + INMUNIDADES DE ESCUDO + BOTON V MOVIL): 5 pedidos de la
  dueña en una tanda. (1) Sonic/Kris solo-operador (doble seguro
  CharSelect.c + scr_char_locked, sección 3.4.5). (2) Enfriamiento 30 s
  por caja destruida en el server + FIX del bug raíz v62-v77:
  FIRST_DELAY/SPAWN_COFF se usaban en ticks sin *TICKSPERSEC (roll cada
  0.33 s = el "aparece otro de la nada"). (3) Rings de la caja cuentan
  para la cura de 10 (case 0 de SERVER_BOX_STATE). (4) Eléctrico explota
  -> 2.5 s inmunidad; escudo Sally (caja) roto -> 4 s (macros
  ITEMBOX_ELECTRIC_BREAK_INVULN/ITEMBOX_SHIELD_BREAK_INVULN con max()).
  (5) Botón V móvil 4º principal: frames 6/7 de spr_mobile_button con
  paleta exacta de la casa + config vMainTouch + handle bid 10 + fallback
  por código. Validadores check_v78.py (86 OK) + sim_v78.py (20 OK).
  Sección 3.4.5. ZIP: v78_operator_only_box_cooldown.zip. RECOMPILAR
  SERVER OBLIGATORIO (3 archivos C cambiaron).
- 2026-11-23 (v77 — NOT PERFECT ZONE FOLLOW): pedido de la duena para
  Not Perfect ("la zona cambia, las cajas se quedan en un solo lugar").
  Diagnosticado: tabla v68 mitad-inferior-only + zonas rotantes 4
  cuadrantes. Entrega: (1) ItemBoxSpawnTables.c 29->56 zonas (27 nuevas
  TL/TR, metodo v68 reversado y verificado 29/29); (2) ItemBoxMap.c
  zona-aware (spawn dentro de la zona actual + relocate por cambio de
  zona cada tick + repoblacion inmediata + FIND_MAX 24). Cero cambios
  de cliente/protocolo. Validadores check_v77.py + sim_v77.py.
  Seccion nueva 3.4.4. ZIP: v77_notperfect_zone_follow.zip.
- 2026-10-30 (vanilla-v2-fix1/rev2): el usuario compilo la v2 y GM
  fallo: (1) net_sounds.gml 'snd_parry' sin coma (los 6 sonidos de
  Chocola se insertaron tras el ULTIMO elemento del array), error
  "got 'snd_mermer' expected ',' or ']'"; (2) obj_vanilla/Draw_76
  dos 'break:' con dos puntos (RUN/JUMP y VANILLA_FLOAT_RUN), error
  "unexpected symbol ':'". Corregidos en repo + en las cadenas del
  aplicador. NUEVA HERRAMIENTA scripts/gml_syntax_audit.py
  (lecciones seccion 8.10): 21 GML de v2 y 875 del repo = 0 errores/
  0 falsos positivos -> los 3 typos eran los unicos. Validador
  195/195 (seccion 13 nueva de sintaxis). HALLAZGO 2: el .yyp y
  .resource_order del usuario (a10d81d2) NO tenian las 4 entradas
  nuevas (no se sobrescribieron al extraer el zip) -> restauradas
  con rebase encima de su arbol. Entregable:
  download/vanilla_v2_rev2.zip (misma logica y server que v2). EL
  PUSH A GITHUB LO HACE EL USUARIO (sandbox sin credenciales).
- 2026-10-30 (vanilla-v2): KIT COMPLETO de Vanilla top-3 (seccion
  7.4): Chocola la guardiana (paciencia 5 s + stun 5 s al exe con
  reloj congelado, bloqueo 50%, ataque 33%, V hacia Cream con cura
  15% y custodia), float run 11->14 con estela local+remota,
  anillos x4 (Cream x2 con Vanilla), moribunda (NUNCA muere ni se
  demoniza, guards CH_VANILLA server), des-demonizacion por 15
  anillos (PAQUETE NUEVO 144/145 con validacion server — sin el
  DEL_FLAG el esbirro se desconectaba en su siguiente caida),
  Fortaleza 15%/30% min 3, madre-hija flecha amarilla > 400 px,
  detectores exe/ring de Vanilla. 6 senales de sonido nuevas en
  net_snds (108-113). Validador 174/174, server compilado+smoke.
  Requiere recompilar server. Entregable: download/vanilla_v2.zip.
  REGLA NUEVA del usuario: SIEMPRE git pull antes de empezar.
- 2026-10-30: carry-v1 (seccion 7.3): Tails/Cream llevan aliados (agarrarse
  al tocar en el aire, soltar con Z, portador suelta con V, estado ZIPLINE
  reutilizado, senal snd_snap por red) + fix v4 del clamp para la velocidad
  real (14) de la acometida/tarot de Amy Canon. Tabla de mods actualizada.
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

- 2026-10-30 (flybuff-v1.1): MEJORA DE VUELO (usuario: "el vuelo dura
  demasiado poco"): Tails 2.67 -> 5.5 seg y Cream 2 -> 5.5 seg.
  Macros nuevas TAILS_FLY_TIME / CREAM_FLY_TIME (60*5.5 = 330) en los
  Create_0 de cada personaje; scr_tails_special usa TAILS_FLY_TIME
  para el flyTimer inicial y scr_cream_special usa CREAM_FLY_TIME
  para el limite del flyTimeout. Recargas intactas (Tails: -420 en
  suelo = 7 seg; Cream: CREAM_FLY_RECHARGE = 15 seg reales), GUI
  intacto (barras mapean recarga, no duracion), carry intacto (drain
  1.5x de Tails => ~3.7 seg cargando pasajero). Textos obsoletos
  actualizados en scr_carry.gml y LEEME_CARRY_V1.txt. Entregable:
  download/fly_buff_v1.zip. Detalle tecnico completo: worklog
  flybuff-v1.1.


- 2026-10-30 (flybuff-v1.2): CORRECCION por diseno del usuario: los
  5.5 seg aplican SOLO llevando pasajero; solos = tiempos vanilla
  (Tails 160 = 2.67 s; Cream 120 = 2 s). Modelo: reloj compartido con
  tope conmutado (Tails: flyElapsed nuevo + flyTimer = max(0, tope -
  flyElapsed), guard flyTimer > 0 para respetar resets externos;
  tope *_FLY_SOLO/_CARRY segun find_hanger; Cream: flyTimeout >
  tope). Soltar pasajero = tope vuelve al solo (corta si ya paso la
  marca). ELIMINADO drain 1.5x del carry + var carryDrainTick.
  Macros renombradas *_FLY_SOLO/_CARRY en los Create_0. Sims:
  solo 160/120, grab@40 -> 330, drop@100 -> 160/120, drop@200 -> 200.
  Requiere carry v1. Entregable: download/fly_buff_v1_rev2.zip
  (superset con carry v1 dentro).


- 2026-10-30 (vanilla-v1): Vanilla the Rabbit superviviente #10 (solo
  token amy). obj_vanilla = clon byte-exacto de obj_cream SIN
  redeclarar macros (CREAM_*/ECREAM_* viven en obj_cream: patron
  sally_canon con las de Sally); specialFunc = scr_cream_special
  directo; estados por red = CREAM_* (layout anims 14-16). UI: retrato
  spr_menu_cream (slot 9 de chars[]), barra de vida/escapados/iconos
  mapeados Vanilla->Cream en obj_level (x3), net_state_charselect (x2),
  menu_waiting (crudo 9->4), results (crudo 9->4), placa 9->4.
  CHARACTER_VANILLA = TAILS+9 = 10 (1-based cliente); server
  CH_VANILLA = 9 (0-based tras id--). Gate: MISMO token de Amy Canon
  (amyCanonToken cliente / amy_authed server); operador NO la abre.
  Server: SOLO states/*.c + include/ son compilados (los .c raiz de
  disasterserver son legacy SIN el codigo de sally/amy canon: NO
  parchearlos). CLIENT_CREAM_SPAWN_RINGS acepta CH_VANILLA (si no,
  anticheat la kickea). Vanilla SI se demoniza (cooldown
  CREAM_RING_SPAWN reset como Cream). FIX regresion sally canon:
  placas EXE en obj_lobby iban 8-11 en vez de 7-10 (offset +9 sin
  ajustar el -1); ahora sprInd - (CHARACTER_VANILLA - 7) = 7-10 ok.
  avCharacters = 11 entradas (2 sitios). Server compilado+linkeado con
  gcc (enet estatico) y smoke-testeado. 108/108 checks. Requiere
  recompilar el server (compilar_server.bat). Entregable:
  download/vanilla_v1.zip.

## 2026-10-30 vanilla-v1-fix1 (GM LTS 2026)
- GM LTS 2026 (runtime 2026.0.0.23) NO compila ternarios encadenados
  `a ? b : c ? d : e` -> "unexpected symbol ?" / "got '?' expected ')'".
  Ternarios simples y separados-por-argumento: OK (originales compilan).
  REGLA: segundo remapeo = ternario simple + if plano.
  Cascada tipica: error atribuido a la DEFINICION de macro en
  scr_survivors ("got '+' expected '}'") cuando la macro se expande
  dentro de un ternario roto en OTRO archivo.
- obj_level/Draw_64.gml usa ESPACIOS; net_state_charselect,
  obj_lobby_icon, obj_menu_waiting usan TABs (verificar repr antes
  de parchear).
- Entregable: download/vanilla_v1_rev2.zip (115/115 checks).

## 2026-10-30 vanilla-v2-fix1 (erratas de sintaxis que rompen compilacion)
- El validador de vanilla-v2 daba 174/174 pero GM no compilaba: los
  checks miraban LOGICA, no sintaxis. Dos erratas en las cadenas del
  APLICADOR (apply_vanilla_v2.py) y por tanto clonadas al repo:
  1. net_sounds.gml: NS_NEW empalmaba los 6 sonidos de Chocola tras
     'snd_parry   // 107', que era el ULTIMO elemento de
     global.net_snds SIN coma -> "got 'snd_mermer' expected ',' or
     ']'". Fix: 'snd_parry,'. LECCION: al insertar al final de una
     lista, anadir la coma al que era ultimo.
  2. obj_vanilla/Draw_76.gml: VD76_RUN_NEW tenia 2 'break:' con dos
     puntos (casos RUN/JUMP y VANILLA_FLOAT_RUN) -> "unexpected
     symbol ':' in expression". GM reporta la linea ANTERIOR a la del
     typo (senalaba la 32 cuando el ':' estaba en la 33).
- Creado scripts/gml_syntax_audit.py + seccion 13 del validador (ver
  seccion 8.10 y 10). Flujo nuevo OBLIGATORIO tras aplicar cualquier
  parche: validador de la task + gml_syntax_audit.py (o --all).
- 2a LECCION (yyp fantasma): el push del usuario (a10d81d2) demostro
  que al extraer el zip en su PC NO se sobrescribieron el .yyp ni el
  .resource_order -> los 4 recursos nuevos (obj_chocola,
  obj_vanilla_indicators, obj_family_indicator, scr_chocola) NO
  existian para GM. REGLA: todo zip que cree recursos DEBE incluir
  .yyp + .resource_order y el LEEME debe decir EXPLICITAMENTE que se
  verifique su sobrescritura (y como comprobarlo: obj_chocola debe
  aparecer en el arbol de recursos). Sin eso, arreglar los typos
  solo cambia el error por "scr_chocola no existe".
- 3a LECCION (flujo git real): este sandbox NO tiene credenciales de
  GitHub (push falla). El flujo real es: yo commit local + zip ->
  usuario extrae + compila + pushea. Ante un push nuevo del usuario
  con contenido de un zip mio: rebase de mis commits (git rebase
  --onto origin/main <mi-commit-viejo> main) y diff contra mi
  version para detectar archivos que el NO sobrescribio.
- 2026-10-30 (vanilla-v2.1): pedido del usuario tras probar la rev2.
  (1) La mini-embestida del 33% (y la de la custodia) solo la veia
  el cliente que la rollaba -> nueva senal snd_chocola_dive (114,
  asset nuevo sintetizado: picado 1500->420 Hz, 0.30 s) lanzada en
  broadcast desde scr_vanilla_v2_step y obj_chocola CHOCOLA_GUARD;
  rama CHOCOLA_NET_HUNT_SMALL (macro 5) que pone la Chocola local a
  cazar al exe SIN reposicionar + authority=false. El exe ahora la
  ve venir en su pantalla. (2) Balance: BLOCK_CHANCE 50->65 y CD
  compartido 4.5->2.5 s (macros en scr_chocola.gml). Cero server.
  Validador 82/82. Entregable download/vanilla_v2_1.zip.
- HALLAZGO pendiente de avisar al usuario (su rama, no la nuestra):
  EVASI1/2/3 y SALLY1-5 NO estan registrados en el .yyp pero
  scr_sally_canon_fase2.gml usa EVASI2 (local y por red): fallaria
  en runtime con "unknown variable EVASI2". Si Sally Canon fase2 se
  juega sin errores, su .yyp local tiene sonidos que el repo no
  recibio al pushear.
- 2026-10-31 (sync tras pull + vanilla-v2.1.4): el push del usuario
  ("Mejora" 57b9ae94) traia el CODIGO v2.1.2+v2.1.3 aplicado (todos
  los .gml identicos a mis commits) pero los docs (LEEME/CACHE/
  worklog) quedaron en estado v2.1 — al extraer los zips no
  sobrescribio los 3 docs (mismo patron del .yyp fantasma, leccion
  2a). Resincronizado con reset a origin/main y re-anadidas las
  filas/entradas de v2.1.1-2.1.3 (compactas, seccion 7.4.1).
  v2.1.4 (fix de sonido del stun de Chocola): scr_chocola_stun_signal
  tenia el grito (scr_exe_stunsound) DESPUES del return del dedup =>
  exe ya stuneado = golpe mudo; y cuando sonaba era solo el grito, no
  el golpe canonico. Fix: audio_play_sound(snd_exe_stun) +
  net_sound_emit(snd_exe_stun) + scr_exe_stunsound() ANTES del dedup
  (patron exacto de scr_parry_apply_stun / obj_tails_projectile /
  obj_player_puppet). Solo scr_chocola.gml, cero server, cero assets.
  Validador vanilla_v2_1_4_validate.py 28 checks + regresion completa
  (52+90+34). Entregable download/vanilla_v2_1_4.zip.
- 2026-10-31 (vanilla-v2.2 — RESCATE TTB): el mod "TD2D Through the
  blood" (maxbaxwer, GameJolt, CERRADO) fue rescatado de sus builds
  (data.win 134 MB, YYC): 1343 sprites + 297 sonidos extraidos con
  UndertaleModCli (scripts/ttb_export*.csx). PORTADOS 4 personajes
  con assets completos (148 sprites + 20 sonidos via
  ttb_import_assets.py, .yy generados + .yyp 1926 recursos):
  METAL SONIC (dash 10 s stun 3 s CD 40 + electro 1 s stun 3 s CD 30,
  scr_metal_special), AMELIA (vuelo estilo Cream con carry + BANANA =
  resorte-trampa colocable [entidad server aban, 12 s, el rebote lo
  aplica el sistema de resortes del cliente que la pisa] + BOMBA
  [abomb, mecha 5 s o pisada del killer, boom state 2, stun 2 s radio
  90 en el cliente del exe], scr_amelia_special), BLAZE (salto de
  fuego + BOLA DE FUEGO [bfire, patron laser de Tails, stun 2 s en el
  cliente del killer, parry-able, CD 9 s = placa TTB] + forma
  ARDIENTE 1.5 s [+30% vel, stun 3 s contacto, estela POWERBOOST en
  puppets], scr_blaze_special) y el killer METAL AMY (EXE_METALAMY:
  golpe estandar + BALA DEL CANON [mabul, patron laser exe de Tails,
  dano 20 en el cliente de la victima, parry-able, CD 7 s],
  scr_metalamy_special). Estados propios BALANCING+1..7 en sus
  Step_2; eanims completos (emetal_/eamelia_/eblaze_); puppet
  PLAYER_POWERBOOST para dash/burning (obj_netclient Step_2).
  Integracion: enums CH_METAL/CH_AMELIA/CH_BLAZE + EXE_METALAMY
  (mismo orden cliente/server), avCharacters x3 +11..13, lobby
  (chars[] 18, tiras spr_lobby_icon 13 f [met 10/amel 11/blaze 12,
  pixel-matching contra TTB] y spr_char_info 16 f [placas 12-15, OCR
  para identificarlas], exeicon6 = 5.o killer), playerui iconos CD,
  resortes cancelan dash/electro/vuelo, scr_player_slow, scr_carry
  (Amelia portadora), scr_move_basic gates. SERVER: Packet.h +11
  paquetes (paridad byte a byte verificada), Server.h CH_*/EX_* +
  PLAYER_COOLCOUNT 10 (cooldowns por jugador banana/bomb/bfire/mabul),
  4 entidades (AmeliaBanana/AmeliaBomb/BlazeFireball/MetalAmyBullet,
  patron TailsProjectile), Game.c 7 cases + resets al demonizar,
  CharSelect.c limites CH_BLAZE/EX_METALAMY + memsets + nombres.
  Blaze fireball CD = 9 s (dato de la placa original del mod, OCR).
  Validador vanilla_v2_2_validate.py 316 checks (paridad enums,
  anims 17 slots, referencias, macros unicas, sintaxis, registro,
  lobby, player_get, server) + gcc -fsyntax-only limpio en los 6 .c.
  Entregable download/vanilla_v2_2_ttb_characters.zip (~230 entradas,
  server incluido: RECOMPILAR antes de hospedar).
- 2026-10-31 (vanilla-v2.2.1 + v2.2.2 — v2.2 abria pero no compilaba):
  v2.2.1 (linkfix, ya entregado): parents Net.yy x4 ->
  Networking/Specific (proyecto no abria). v2.2.2: (a) crash
  IndexOutOfRange en GetEventName_Simple: eventList de los 4 objetos
  player con "eventNum":0,"eventType":64/76 (campos invertidos;
  reales: eventType 8, num 64/76 = Draw_64/Draw_76, ref obj_aiz_
  zipline); (b) ~200 "File missing for GMSprite": el importador
  declaro la capa GMImageLayer con un GUID y guardo el PNG con otro
  -> creados 1.161 layers/<frame>/<GUID-del-yy>.png (copia del PNG
  existente en el dir; 8.190 ya existian). Abarca los 148 TTB + las
  2 tiras ampliadas (char_info/lobby_icon). Fix integrado:
  scripts/fix_v22_compile.py; validacion 0 missing + eventList exacto.
  Zip v2.2 original recuperado de litterbox (SHA verificado) tras el
  reciclado del sandbox. Entregable download/vanilla_v2_2_2_compilefix.zip.
- 2026-10-31 (charsafe-v2.2.3 — SEGURO DE SLOTS de personaje): el
  usuario reporto crash "Variable Index [13] out of range [11]" en
  obj_lobby Draw_0:121 y pidio un sistema que evite esta familia de
  errores al agregar pjs. Causa: literal avCharacters duplicado en 7
  sitios, v2.2 solo actualizo 3. CREADO scripts/scr_characters
  (seccion 4 nueva arriba: macros de tope derivados de los
  CHARACTER_*/EXE_*, reset/get/set blindados, sanity [charsanity] al
  crear obj_lobby, scr_char_name). Sustituidas las 7 copias + 5
  accesos directos blindados + clamp de sprInd en obj_lobby/Draw_0.
  Validador workspace scripts/validate_slots.py TODO OK (sin
  literales/accesos directos fuera del script, registro .yyp con
  formato exacto, delimitadores balanceados en los 10 .gml tocados).
  NO toca el server (el de v2.2 sigue valiendo). Entregable:
  download/charsafe_v2_2_3.zip (extraer sobre la raiz con GM cerrado).
- 2026-11-01 (amelia-v2.3+v2.4 reconstruidos sobre 1af7dce3 "ok"):
  el sandbox del agente se reciclo (commits locales perdidos) y se
  rehizo TODO sobre el commit del usuario, que ya traia SU fix
  v2.2.4 del acc (0.35 -> 0.046875, "salía disparada al instante")
  — respetado tal cual. KIT FINAL: trampolin (X, sin cambios) +
  TRAMPA (C): vida 60 s server (retiro state 1), pisada detectada
  por el cliente de la victima (lado EXE) => stun 3 s + slow -40%
  3.5 s tras el stun (scr_player_slow por el total 6.5 s),
  CLIENT_AMELIA_TRAP_TRIGGER con nid y busqueda tag "atrap"+id
  exacto (mata los 2 bugs latentes de la bomba v2.2: boom por
  pisada jamas emitido y game_find("abomb") cruzando Amelias), max
  1 viva POR Amelia. VUELO fuera (macros, estado defensivo, carry,
  resortes, icono); velocidad NUNCA entra (pedido v2.4 tras el bug;
  ademas habria pisado isBoosting de las botas con la tecla de
  salto = carrera forzada). Renombres bomb->trap completos cliente+
  server (mismo orden numerico, actualizar juntos). UI 2 iconos con
  sprites ya registrados. Extra: case SONIC en scr_player_slow.
  Validado (.yyp 1927 sin duplicados, delimitadores OK, 0 stale) y
  server compilado+probado con gcc (v1101 en 8606, Lobby OK; enet
  clonado a mano, build agent scripts/build_server.sh replica el
  CMakeLists). OJO: disasterserver/Game.c raiz es huerfano (usa
  game.cooldowns inexistente, fuera del build real = states/Game.c).
  Entregable: download/amelia_v2_4.zip.
- 2026-11-01 (hudbar-v2.5): barra de vida bugeada de Amelia = ASSETS,
  no codigo. 1af7dce3 anyadio los frames 56-90 de spr_playerhealth (y los
  de redring/hit/demon/escaped/tab_entry) dejando los PNG en
  layers/<frameGuid>/ (capas GMS2.3) en vez de la raiz (composite que
  consume la texture page) => GM renderiza basura para esos frames. 88
  frames en 6 sprites reparados (composite a raiz + layer renombrado al
  GUID default; scripts del agente fix_healthbar_composites.py +
  audit_sprite_frames.py reutilizables). Slots 8/9 = placeholder
  transparente a proposito (remapeados en el draw, jamas se renderizan).
  Extra: remapeo SALLY_CANON/VANILLA anyadido a drawPing (marcador TAB),
  que Draw_64 ya tenia (icono hit/demon invisible para ellos). Server: 0
  cambios. Entregable: download/hudbar_v2_5.zip.
- 2026-11-01 (placas TTB + amelia-v2.6): decodificacion pixel-exacto
  de las placas de spr_char_info (12-15): Amelia = MOBILITY HIGH/HIGH +
  SPINDASH + SUPPORT: TRAP (2 SEC) + SPRING + NEW PASSIVE ABILITY:
  SPINNING; Metal = SPARK FIELD (2s) + OVERDRIVE (2s); Blaze = FIRE BALL
  (3s) + FIRE DASH (3s); todos con la pasiva SPINNING (que ya tenian:
  canSpin=true v2.2). Hallazgos: el "FIRE BALL 9 SEC" del OCR de v2.2
  era un 3 mal leido (juego usa 9s, ajustable a pedido); la P de
  "PASSIVE" en las placas TTB quedo en gris tenue (artefacto del
  modder, por eso los OCR leian "ASSIVE"). IMPLEMENTADO el SPINDASH de
  Amelia (la firma de su fila 1, faltante desde v2.2): porte del de
  Sonic sin drop dash, abajo+Z parada = revolucadas (tono creciente +
  polvo por red), soltar abajo = bola a 8+carga (tope 18 con clamp
  propio en scr_collision_basic), estado AMELIA_SPINDASH=BALANCING+2
  con slot 15 = spr_[e]amelia_spindash (reemplaza el srings sin uso),
  sin salto/trampolin/trampa mientras carga, cancelaciones completas,
  reset de ronda. Server: 0 cambios. Scripts del agente:
  letters_placas.py / apply_amelia_spindash_v26.py /
  validate_amelia_spindash_v26.py. Entregable:
  download/amelia_spindash_v2_6.zip.

- 2026-11-01 (trampa-v2.8 RE-APLICADA + blaze-v2.9 "el fuego que
  rebota"): el sandbox se reciclo y el repo se reclono desde 7712ef6f
  ("ewe"); el fix v2.8 (commit local 10ae6f5e nunca pusheado) se
  volvio a aplicar a mano: identico al zip trampa_multiple_v2_8.zip.
  v2.9 Blaze: (1) BOLA DE FUEGO = proyectil rebotante: gravedad +
  vy en el server (BFIRE_*), rebotes reportados por los clientes con
  CLIENT_BLAZE_FIREBALL_BOUNCE (nid+flip+pos; bfire_bounce voltea
  elasticamente con lockout 0.12 s; throttle local 15 frames; chispa
  local), nid por bola (varias simultaneas, HIT por nid, sin limite
  global, cooldown 8->4 s), tick con dir+vy y cometa rotando con
  point_direction; paquete añadido AL FINAL del enum en ambos lados
  (cliente y server JUNTOS o nada). (2) GIRO DE FUEGO (C, spr_blaze_go
  = tornado confirmado por VLM): mientras arde Blaze rebota en suelo
  (BLAZE_BURN_BOUNCE 7.5) / paredes (elastico min 3, ±4, solo suelo
  plano) / techo (0.6x tras yspd==0); TODO lo demas intacto (stun 3 s,
  +30%, 1.5 s, recargas 9/4 y 30/12). Validador
  validate_blaze_rebote_v29.py (102 checks) + sim de trayectoria.
  Entregable: download/blaze_rebote_v2_9.zip (recompilar server Y
  cliente). Pendientes mismo patron: banana (20 vs 10 s) y bala de
  Metal Amy (limite 1 + sin nid).

- 2026-11-01 (tierlist-v1 + sync v2.10/v2.11): pull con merge (4
  commits del usuario: metal-sprites v2.10 = electro/overdrive
  DESCRUZADOS; vanilla-rescate v2.11 = Chocola detecta esbirros con
  stun 3,5 s + rescate con la barra del revive + CLIENT_VANILLA_
  DEDMONIZE_PROGRESS + float run arreglado). Conflicto de enum
  resuelto al lado remoto (superset); 157 paquetes alineados.
  NUEVA HERRAMIENTA: tier list HTML del plantel completo (descarga
  TierList_TD2DR.html) — extract_sprites_tierlist.py saca el frame 0
  del compuesto RAIZ de cada sprite (los .png con GUID de frame en
  sprites/<spr>/), build_tierlist.py inyecta los base64 sobre
  tierlist_template.html (marcas %%SPRITE_x%%), shot_tierlist.py
  captura las 5 pestañas con Playwright. PENDIENTE: decision del
  usuario sobre la pasiva de Amelia (4 propuestas en la pagina;
  recomendada "Deducción del detective", solo cliente).

- 2026-11-01 (tierlist-v2 + verificación de Amelia): la lore de
  personajes se puede verificar VÍA WAYBACK aunque Fandom esté tras
  Cloudflare: curl y WebFetch directo fallan (WebFetch además tira la
  query string de api.php) y agent-browser no pasa el challenge
  interactivo; en cambio web.archive.org/cdx/search/cdx?url=... lista
  las capturas y la captura archivada carga completa. Wiki clave:
  exenightmare.fandom.com (universo Nightmare de Jayz): Amelia = Amy
  alternativa CIEGA que ve AURAS DE CALOR (suero de Nate; el impostor
  la delató con un aura MÁS FUERTE) — de ahí la pasiva recomendada
  «Auravisión» (radio ~350 px, EXE real más brillante, marcadores
  locales estilo Amy Canon). LECCIÓN de la v1: el array SPR de la
  página y sprites.json deben cubrir TODAS las keys de SURV/EXES
  (faltaba sonic: img() devolvía src="undefined" y el chip quedaba sin
  imagen SIN error de consola — detectar con
  Array.from(document.images).filter(i=>!i.complete||i.naturalWidth===0)).
  Hallazgos de código al verificar a Amelia: banana del servidor
  20 s vs 10 s demonizada (familia v2.8), mabul con tope global 1 viva
  + HIT sin nid, comentario viejo «máximo 1 trampa» en
  scr_amelia_special (v2.8 lo quitó) y carpetas huérfanas
  obj_amelia_bomb/net_amelia_bomb presentes en disco pero fuera del
  .yyp.

- 2026-11-02 (amelia-page): la página de fan de Amelia existe ahora
  como HTML AUTOCONTENIDO en docs/Amelia_La_Luna_Encarnada.html
  (4,2 MiB con el OST «Lobby Music» incrustado en base64: doble clic
  y suena en bucle; play/mute/volumen en el dock). Es el port del
  Next.js del sandbox (zip amelia-la-luna-encarnada.zip): mismo
  diseño y textos, interacciones en JS plano (pestañas Sol/Luna,
  goteo de rings, velo gracia 3 s/CD 15 s, simulador del EXE con
  eclipse y cuenta atrás). LEEME propio en docs/. Build: scripts/
  amelia_page/build.py del workspace (plantillas head/body/app +
  inyección del mp3 y de la geometría SVG de decor.tsx). LECCIONES:
  (1) los elementos DENTRO de un <symbol> usado con <use> no reciben
  CSS de clases externas — las animaciones internas (p. ej.
  flame-flicker del ojo de Auravisión) deben ir con style= inline;
  (2) revisar el z-index de badges sobre overlays opacos: el de
  «TRAMPA DE AMY · STUN» quedó invisible tras el velo del eclipse
  (z-30 < z-40) hasta subirlo a z-45 — mismo bug tenía el React
  original; (3) para verificar «texto cortado» reportado por VLM,
  confirmar con captura DEL ELEMENTO + comparación DOM: suele ser el
  pliegue del viewport, no un recorte real.

- 2026-11-02 (amelia-auravision v2.12): la pasiva de Amelia YA ESTÁ
  EN EL CÓDIGO (antes era solo propuesta de la tierlist):
  «Auravisión», la de su biografía — ciega, ve firmas de calor (el
  suero de Nate). obj_amelia_auras (nuevo, patrón obj_amycanon_
  indicators: lo crea el Create de obj_amelia, SOLO en su cliente)
  escanea en el Step el bando EXE en 350 px (EXE real por
  character == CHARACTER_EXE; esbirros por revivalTimes >= 2; clones
  obj_exeller_clone en pasada aparte; isInactive fuera) y lo dibuja
  en Draw GUI con mezcla aditiva: halo que late + silueta del
  PROPIO sprite del puppet tintado de calor, A TRAVÉS de paredes e
  invisibilidad. EXE real arde más fuerte (r=26 + aro + núcleo, late
  al doble) que esbirros/clones (r=14 tenue): la diferencia de
  tamaño ES la lectura táctica. Se apaga si Amelia se demoniza (el
  juego ya da la flecha del exe). Macros AMELIA_AURA_* en
  scr_amelia_special. Registro en el .yyp (+1 línea en resources).
  LECCIONES: (1) registrar el objeto NUEVO en el .yyp o queda
  huérfano (bug conocido de obj_amelia_bomb); (2) los clones NO
  declaran angle — variable_instance_exists antes de leer un var de
  instancia ajena (patrón obj_ghz_water); (3) var re-declarado en un
  mismo evento es legal en GML y es estilo local (obj_unlockables
  tiene 13 bucles for(var i)); (4) el puppet dibuja con
  _f2xs=image_xscale (salvo squash de Sally fase 2) y pasa angle
  TAL CUAL al draw_sprite_ext (obj_amelia en cambio usa
  radtodeg(angle): convenciones cruzadas) — la silueta copia la del
  puppet para caer sobre el sprite real que se ve en pantalla.

- 2026-11-02 (sol-y-luna v2.13): el ARCANO III de la página de Amelia
  entra al código. SOL: Amy Canon gotea 1 ring cada 7 s mientras viva
  (pausa escondida/muerta) por el camino de Cream (CLIENT_CREAM_SPAWN_
  RINGS): server acepta CH_AMY_CANON, spawnea 1 solo anillo worth 1 y
  su suelo anti-spam baja a 6 s (Cream/Vanilla siguen a 10). LUNA:
  Amelia oculta = invisible GRADO EXE (Draw_0 del puppet: alpha 0 solo
  en el cliente del EXE; el resto la sigue viendo a 0.5; nick/HP ya
  cortados por !isHiding para todos) + VELO DE GRACIA 3 s / CD 15 s
  (flanco de subida de isHiding en el Step del puppet — cada cliente
  lo deriva IGUAL: posicion + LOOKDOWN + escondite — y los 3
  indicadores del exe la saltan durante la gracia). ECLIPSE: el stun
  de la trampa arrastra CEGUERA de 4 s a la victima EXE-side
  (global.eclipseTimer en obj_level: reloj en Step, velo 480x270 con
  envelope triangular de 30 frames en Draw_64; puppets supervivientes
  sin cuerpo NI HUD en su cliente; esbirros y el propio EXE visibles).
  Cero paquetes nuevos; el Sol reusa el paquete de Cream. LECCIONES:
  (1) el isHiding del puppet NO viaja por red: cada cliente lo deriva
  de position+estado, perfecto para flancos consistentes; (2) el
  Game.c de la RAIZ del server es legacy SIN compilar — el vivo es
  states/Game.c (confirmado contra disasterserver/CMakeLists.txt);
  (3) el GUI del juego es 480x270 (spr_screenoverlay) para rectángulos
  de pantalla completa; (4) el suelo anti-spam del server debe quedar
  POR DEBAJO del ritmo legitimo del cliente (6 < 7 s) o se come
  paquetes sanos por jitter.
- 2026-11-05 (v5.0 LMS «El Show Fuerte»): Sonic último superviviente
  => el show: reloj a 282 s (LMS_TIME_SEC = duración de Undefeatable
  V2, descargada de file.garden y convertida a ogg q3), canción para
  TODOS (mus_undefeatable streamada), banner obj_lms_banner/spr_
  lms_banner (4 frames pixel-art «LAST MAN STANDING»), cura a 100,
  bloqueo 55% de TODO el daño (scr_lms_sonic_try_block tras la Torre
  en scr_player_hurt, patrón Chocola + 60f i-frames), inmunidad a la
  MARCA DE DEBILIDAD de Metal Amy (gate en scr_weak_mark_hit) y
  TODOS los stuns de Sonic +2 s (golpe X 3->5, parry 3,5->5,5 y la
  BOLA del spindash aturde por contacto SOLO en LMS — estado SPIN
  del puppet, macro LMS_SPIN_STUN). Paquete NUEVO SERVER_GAME_LMS al
  final del enum en los DOS lados (server: detección en game_state_
  tick con latch game.lms + reenvío en game_state_join; el reloj
  solo SUBE). Práctica (.sp) también dispara el show (exe=0xFFFF no
  cuenta). Gates de música: la chase del anillo y el banner de
  muerte súbita no pisan la canción (la demonización del server
  sigue). FIX EXTRA: el stun de 3,2 s del DJ de FW Amy era código
  muerto (el bloque de stun exige isAttacking y FW no lo envía);
  la puerta ahora acepta (FW && isDJ). REQUIERE RECOMPILAR SERVER.
  Validador 139/139 + server cmake limpio + smoke test OK. LEEME_
  LMS_V1.txt con macros ajustables y guion de prueba. Pendiente:
  partida real.

- 2026-11-21 (editor-v54): RONDA DEL EDITOR (Suite_TD2D.html, la
  herramienta web de la raiz del repo — NO es el juego). BUG OFF-BY-ONE
  en plaqueMapFor (v53.1): cruzaba los redirects de obj_lobby/Draw_0.gml
  (comparan sprInd, idx 0-based de chars[]) con el idx de la MACRO
  CHARACTER_* (1-based) => cada redirect caia en el personaje ANTERIOR;
  Rouge heredaba el placeholder Knux de Kris y Kris quedaba missing.
  FIX: clave sprInd real = macroIdx-1 (survivors); killers tal cual.
  Rouge ahora = "sin placa" + boton crear (el juego hoy le dibuja la
  placa de BLAZE cruda, peor que placeholder); Kris = frame 1 (su
  placeholder Knux real del juego). GENERADOR regenIconRouterBlock
  sincronizado 1:1 con el bloque ACTUAL (v39/v40: Rouge icono 13 + fila
  propia (CHARACTER_ROUGE-CHARACTER_TAILS)*7 + hit/demon/escaped propios;
  antes escribia Rouge=Knux en todo y un "Escribir" BORRABA el estado
  real). NUEVOS en el editor: nombre con tags de color {r}..{w} (igual
  que las lineas; decodePlaque emite name.tagged por runs con
  tagOfColor), 8 presets "nombre rapido", y boton "+ propio" en TODAS
  las filas de la tira = CARTEL INDEPENDIENTE para cualquier personaje
  (mismo flujo del "+ crear": placeholder editable + Escribir crea
  sprites/spr_char_info_<key> + redirect + .yyp). fw/sallycanon/
  vanilla ya eran sprites propios (v53.1, se mantiene). Version del
  Suite: v6.4. Validador scripts/check_v54.py (32/32) + E2E Node con
  archivos reales + browser vivo (agent-browser). LECCION NUEVA (8.16):
  al cruzar sprInd (chars[]) con roster (macro): restar 1 en survivors;
  y CADA generador que reescribe un bloque GML debe regenerarse 1:1 con
  el bloque ACTUAL del repo, no con la version congelada de cuando se
  escribio (regenIconRouterBlock v5.2 borraba v39/v40).

- 2026-11-21 (editor-v54.2): CRASH REAL EN EL JUEGO por el writer de
  placas v54: "Variable spr_char_info_rouge not set" en obj_lobby
  Draw_0 line 193 al pasar de Rouge a Kris. CAUSA DOBLE: (1) el writer
  escribia 'else if (sprInd == CHARACTER_ROUGE)' — macro 1-based (15)
  contra sprInd 0-based (Rouge 14): la linea se disparaba con KRIS
  seleccionado (15==15) y llamaba draw_sprite(spr_char_info_rouge);
  (2) el sprite NUNCA se registro en el .yyp porque pjYypName (fallback
  local del bloque Arte, que corre ANTES que el modulo PJ setee
  window.__pjHelpers) solo escaneaba S.files (modo files, solo lectura)
  => en modo fs devolvia null => newPlaqueRegisterYyp fallaba con un
  toast y seguia. REPARACION del juego: Draw_0.gml con 'sprInd == 14'
  (Rouge) y 'sprInd == 15' (Kris) + registro de los 2 sprites en el .yyp
  (2530->2532) + 2 entradas en .resource_order. WRITER FIXEADO (8
  parches + v54.2b + v54.2c): pjYypName robusto (fs recorre raiz),
  condicion 0-based con comentario FUERA del parentesis (v54.2c: dentro
  del parentesis la regex del mapa no la veia), reemplazo de linea
  vieja mal indexada ANTES del reDone (idempotente), registro .yyp con
  RELECTURA-VERIFICACION + resource_order, uid 100+ re-deducido (trio
  'ent.uid=' absurdo eliminado), undo con regex de digito, aviso
  "cierra GameMaker" al crear placas nuevas, parser del mapa tolera
  comentario tras la condicion, y sprite propio EXISTENTE gana al
  redirect de tira en plaqueMapFor (orden del juego: la cadena
  draw_sprite propia va antes del else de la tira; sin esto Kris
  editaria el frame 1 Knux). Validador check_v54_2.py 33/33 + E2E Node
  6/6 (malo->fixed, bueno->already sin duplicar, killers macro, parser
  ve lineas nuevas, yypName 3 modos) + browser vivo (mapa: Rouge y Kris
  = sprites propios, Jinna frame 16 intacta, click Rouge abre su placa,
  0 errores). LECCION NUEVA (8.17): un writer que emite GML debe emitir
  SOLO sintaxis que el propio parser del Suite puede releer — el
  comentario dentro del parentesis rompia el roundtrip; y CADA
  escritura de recurso (.yyp) debe re-leerse y verificarse, porque el
  paso anterior puede haber fallado en silencio (toast perdido) o
  GameMaker abierto puede pisarla al guardar.

- 2026-11-21 (editor-v54.3): DENUNCIA de la duena: "quitaste otra vez del
  editor a Rouge" (screenshot). INVESTIGACION COMPLETA: la fila de Rouge
  NUNCA fue quitada — su Suite (78e6d5fa, con la v54.2 aplicada) lista
  22/22 filas en el orden correcto (... Metal Sonic, Amelia, Blaze,
  Fleetway Amy, ROUGE, KRIS, [Killers] EXE Original... Jinna). El
  screenshot mostraba la lista SCROLLEADA: la ventana visible terminaba en
  Fleetway Amy con scrollbar; Rouge y Kris estan UNA vuelta de rueda por
  debajo. Pruebas: top bar "22 personajes", SIN seccion "Sin placa
  (aún)" (solo aparece si alguien falta), SIN boton "+ crear", botones
  "+ propio" solo en filas de tira (Amelia/Blaze) — todo consistente con
  el mapa completo. Browser en vivo: click en fila Rouge/Kris funciona,
  selecciona y abre su placa propia. FIX REAL (v54.3, UX): (U1)
  scrollSelIntoView() — al construir la lista/seleccionar/click, la fila
  elegida se lleva SIEMPRE a la vista (scrollIntoView block:'nearest');
  sin esto una seleccion por codigo quedaba bajo el fold y PARECIA que el
  personaje no existia; (U2) igual al abrir placeholder nuevo (fila al
  final de "Sin placa"); (U3) contador "22 filas · ▼" junto al header
  con tooltip "los killers van DESPUÉS de Kris, baja con la rueda". La
  duena tambien re-guardo el sprite de Rouge desde GameMaker (GUIDs
  nuevos 72756c26/f2a76dea; los viejos 7ed4d01e/46440f23 salieron
  limpios) y retoco el arte de Kris — ambos estados verificados: .yy
  parsea, PNG+layer existen, registro .yyp y resource_order intactos.
  LECCION (8.18): antes de responder a una denuncia de "X desaparecio",
  verificar si X esta bajo el fold de una lista scrolled — y arreglar el
  UX (auto-scroll + contador) para que la sospecha no pueda volver a
  nacer. Validador check_v54_3 additions en check_v54_2.py.

- 2026-11-22 (v70 SUITE CAJAS): duraciones de las cajas configurables
  desde el Suite. GML: 4 macros ITEMBOX_*_TIME al top de net_state_game.gml
  (SHIELD 5 s / INVULN 3 s / ELECTRIC 2.5 s / BOOTS 8 s, defaults de la
  casa v62) reemplazan los literales del switch(_type) — convención del
  repo verificada: las 745 macros existentes viven TODAS a nivel de
  archivo, ninguna dentro de función. SUITE_TD2D.html: módulo nuevo
  «📦 Cajas» (categoría Sistema): 4 filas con slider/número de segundos,
  edición por el motor real de macros (AnimCore.setMacro), escritura con
  T.writeEdits (backup + deshacer), panel de notas explicando cada
  recompensa y que la invulnerabilidad comparte timer con el golpe pero
  solo cambia el valor de la caja. VERIFICACIÓN (regla 6): check_v70.js
  37/37 (ejecuta el motor REAL del Suite extraído del HTML contra el GML
  real: parse de las 4 macros, setMacro 8→12 s, idempotencia, formato
  (60*N), 1 línea de diff, sintaxis de los 10 bloques JS, tags balance,
  superficie de red intacta) + E2E en navegador real (agent-browser +
  driver iframe + http.server): módulo clicable, 4 filas con valores
  reales (5/3/2.5/8 s), edición por input 12 s, reconfiguración de las 4
  (7/4.5/3.25/20 s), slider con decimales (6.25), writeEdits escribe el
  archivo COMPLETO con (60*12), backup con el original (60*8), undoLast
  restaura, 0 errores JS. Cero cambios de red/server (regla 7).
  NOTA v69: la v69 (botas snd_speedboost + duck anti-camping) fue
  entregada como zip v69 en download/ pero GitHub sigue SIN ella: este
  v70 se construyó sobre origin/main (6977f00a). Aplicar v69 y v70 es
  independiente y no chocan (v69 = audio, v70 = macros de duración).
- 2026-11-22 (itembox-investigation): FETCH found new owner commit
  9dff8484 ("up"): applies our v54.3 editor fix + ADDS 6 new item box
  sprites (ring/shield/invincibility/lightning-shield/speedboots/
  boxused) in a new folder sprites/folders Itembox + .yyp +
  resource_order — she is expanding the Kafmonitor system. Full
  investigation of the CURRENT system added as section 3.4.1: the one
  object (obj_kaf_speedboobster), break conditions in
  scr_collision_objects, the CLIENT/SERVER_KAFMONITOR_STATE protocol,
  server KafSpeedBox.c entity (11 boxes, 25-30 s respawn), the boost
  reward (isBoosting=true forced 12px/frame run, cancelled by walls/
  springs/hurt), Tails projectile interaction, the in-map hazard tip,
  and the exact recipe to extend it for the 6 new box types.

- 2026-11-22 (itembox-v2-design): owner specced the 5 reward types + asked
  how to spawn boxes randomly without walls/pits. Full investigation of
  the reusable mechanics (ring collect flow + 119 cap, Sally shield
  shieldTimer 5*60 + 60f invuln, hurttime 3*60 i-frames, Eggman electric
  shield 60*1.5 + spr_electroshield + 15 s recharge, speeds: chars run
  9-12 px/f via *_MAXSPEED macros, Kaf boost 12 forced, spindash base 8)
  and the random-spawn answer: hand-placed spawner objects + server-side
  random pick (Ring.c goto-gen pattern), server sends sx,sy IN the packet.
  Design recorded as section 3.4.2 + delivered as
  download/Diseno_Cajas_Items_Aleatorias.docx (Spanish, 10 sections,
  4 tables). NOT implemented yet — implementation order F1-F4 recorded.

- 2026-11-22 (v62 IMPLEMENTED): the item-box system of 3.4.2 landed
  end-to-end in one session (owner approved the design: "podemos
  probarla"). 18 spawners, 20 s cadence, max 4 alive, weights
  35/20/15/15/15, rewards with exact house values, electric shield stun
  via the parry signal channel, boots as controllable speed, ghost trail
  reused via effectTime, PLAYER_ELECTROSHIELD bit 7 shared. 37 files
  (3 new C, 4 new obj_itembox event files, 22 Draw overlays, LEEME_
  ITEMBOX_V62.txt, check_v62.py). Fixed owner's resource_order gap for
  spr_invincibility_box from commit 0f989734. check_v62.py = TODO OK.

- 2026-11-22 (v71 FIX crash + shield-for-all): owner reported the runtime
  crash "Variable obj_amy_canon.shieldTimer(100297, -2147483648) not set
  before reading it" at net_state_game L2519 (case 1 = shield reward of
  SERVER_BOX_STATE, the v70 itembox). Root cause: only obj_sally (Create
  L21) / obj_sally_canon (Create L30) / obj_rouge (Create L150) declare
  shieldTimer; the other 19 character objects do NOT, and v70's reward
  read it unguarded. The v70 comment claimed "works for any character"
  but scr_player_hurt only consumed it for Sally/SallyCanon (+Rouge in a
  separate identical block), and no tick/draw/net-sync existed for the
  rest. Fix = exact mirror of the battle-tested v62 electricShieldTimer
  template, 7 sites / 25 files: (1) net_state_game case 1 guarded
  read+set (same shape as cases 3/4); (2) scr_move_basic generic tick
  with SKIP-LIST — Sally/SallyCanon/Rouge excluded because their own
  scr_sally_special L275 / scr_rouge_special L912 cycles maintain
  shieldRechrage + demonized expiry (a second tick would halve their
  duration); (3) scr_player_hurt generic consume (variable_instance_
  exists guard; Sally achievement + SallyCanon SALLY_CANON_SHIELD_BREAK_
  INVULN ternary kept; Rouge's redundant twin block deleted — it was
  behavior-identical); (4) net_udpprocess writes puppet sallyShield
  UNCONDITIONALLY (electroShield L173 pattern: no stale bubble when the
  bit drops); (5) obj_netclient Step_2 sends PLAYER_SALLYSHIELD for every
  non-EXE character with shieldTimer>0 (historical Sally/Rouge send
  blocks left intact — redundant OR of the same bit is harmless); (6)
  obj_player_puppet Draw_0 generic bubble (spr_sallyshield/spr_
  sallyshield2) for every character EXCEPT Sally/SallyCanon/Rouge (their
  switch cases keep their own sprites: spr_sallyshield_canon for
  SallyCanon); (7) the 19 character Draw_0.gml files (22 minus the 3
  shield-native) draw the bubble locally right after the electric
  overlay, same lazy-var guard. Zero .yyp/.yy/.resource_order changes;
  zero net_packets/server changes (rule 7: the shield stays a
  client-local reward exactly like Sally's own — no new net surface).
  check_v71.py: 43/43 OK (old unguarded reads gone, Sally/Rouge cycles
  intact, brace+paren balance on all 25 touched files, no GameMaker
  project files touched, net surface clean, logic simulation: AmyCanon
  set -> tick 300 frames -> expire -> re-set, hit absorption hurttime=60
  shieldTimer=0, Sally single decrement per frame via skip-list).

- 2026-11-23 (WSS v72): port del mod Lua de SRB2
  "L_WackyStretchyandSquashy" (squash & stretch del cuerpo) — seccion
  3.7 nueva. 30 archivos: scr_wss.gml+scr_wss.yy NUEVOS (carpeta
  Scripts/Players), hook al final de scr_collision_basic, 21 Draw_0 de
  personajes (linea base del cuerpo + scr_wss_draw), obj_sally_canon
  Draw (compone con fase2Sq), puppet Create/Step/Draw (vars + update +
  composicion), .yyp 2541->2542 y .resource_order +1. Cero red/cero
  server/cero fisica (solo args del draw_sprite_ext del cuerpo;
  image_xscale direccion intacto). Validador check_v72.py TODO OK
  (lexer balance 27 GML, parches 1-vez, JSON de proyecto, superficie
  git exacta, simulacion: takeoff 0.315, impacto satura, sharp 12f /
  smooth 28f / jelly 51f 3 cruces overshoot -0.108, anclaje al suelo
  exacto, puppet sin squash falso en pendientes). Entregable:
  download/v72_wss_squash_stretch.zip.
- 2026-11-23 (v73 WSS retune + Exe sin buffs + fix inmunidad): feedback
  de la duena en 3 puntos, los 3 entregados. (1) "la caida se nota un
  poco pero el salto y lo demas no se nota mucho" => retune de 7 macros
  del WSS (ver 3.7): estiron del salto 0.315->0.450 (satura tope),
  aplaste normal 0.21->0.35, Smooth 28f->37f, Jelly misma proporcion
  (60f, 3 cruces, -0.138). (2) "los exes no podran obtener buff pero
  si pueden destruir las cajas negandole el buff al que esta pasando
  por hay" => exe denial a 2 capas (server ItemBoxMap.c/KindAndFair.c
  pid 0 + 2 guardas cliente en net_state_game; ver 3.4.2 v73-A y 6).
  (3) "fix a un bug de inmunidad: si el jugador obtenia otra inmunidad
  (cajas invulnerable) no se reiniciaba la duracion max" => case 2 del
  reward ahora asigna hurttime = ITEMBOX_INVULN_TIME incondicional
  (ver 3.4.2 v73-B). Validador check_v73.py (59 checks, SUSTITUYE a
  check_v72.py) TODOS OK: lexer balance 28 GML, parches v72 intactos,
  macros v73 exactos, fix + denial verificados, gcc -fsyntax-only 2 .c
  con stub enet, .yyp/.resource_order OK, superficie git nucleo v73
  (+v72 sin commitear) sin protocolo/netclient, simulacion numerica
  completa + logica de las 2 reglas portada. Entregable:
  download/v73_exe_denial_invuln_fix_wss.zip. El usuario debe
  RECOMPILAR el server. El push a GitHub lo hace la duena.

- 2026-11-23 (v74 CORRECCION DE ALCANCE + rebase sobre el commit de la
  duena): su mensaje fue "espera los de KAF no los cambies esos que
  trae eso no los cambies en si seguiran funcionando me referia a las
  cajas nuevas" => (A) KindAndFair.c y la seccion SERVER_KAFMONITOR
  STATE quedan con comportamiento ORIGINAL (quien rompe cobra, Exe
  incluido) — el exe-denial aplica SOLO a las cajas nuevas
  (ItemBoxMap.c + guarda cliente en SERVER_BOX_STATE state 2). (B) El
  fetch (regla 1) revelo SU commit ef3c5d87 ("ewe"): v72 aplicada
  byte-exact + SU restauracion de la musica de botas v69 (loop
  snd_speedboost + scr_music_duck en el case 4 y cortes
  audio_stop_sound/scr_music_unduck antes del show LMS y de resultados,
  TODO dentro de net_state_game.gml) — la v73 nunca se aplico. Rebase:
  arbol reseteado a ef3c5d87 y los 3 parches re-aplicados ENCIMA de su
  musica (verificado como invariante nuevo en el validador). El zip
  trae el net_state_game.gml MERGEADO (su musica + fix inmunidad +
  guarda Exe) — extraerlo sobre su repo al dia es todo lo que hace
  falta. Validador check_v74.py (SUSTITUYE a check_v73.py) TODOS OK:
  KindAndFair.c identico a HEAD exigido, 1 guarda (no 2), seccion KAF
  sin veto y flujo original intacto, musica de botas 1/1/2/2, resto
  superset del v73. Entregable: download/v74_kaf_original_cajas_exe.zip.
  OJO si aplico la v73 antes: git checkout -- KindAndFair.c (instruido
  en LEEME_V74.txt). Server: RECOMPILAR igual (ItemBoxMap.c cambio).

- 2026-11-23 (v75 — KAF afecta al Exe de nuevo + restauracion de la
  musica de botas): la duena reporto "el efecto de la caja Kaf no afecta
  al exe te dije que la caja de Kaf original tendria su comportamiento
  normal que le afectaria tanto al exe como al survi solo las cajas
  normales creadas rings speedboost invencibilidad escudo normal y
  electrica serian para survivors". CAUSA RAIZ: ella aplico el ZIP DE LA
  v73 (commit 8ec415a1), que llevaba el veto Kaf (mal entendido de v73,
  corregido solo en el chat como v74 — nunca aplicado). ADEMAS el zip
  v73 borro SIN QUERER su musica de botas: su net_state_game.gml quedo
  byte-identico al de la v73, que fue construido ANTES de su commit
  ef3c5d87 (boots music) — extraer el zip reemplazo el archivo completo
  y se llevo puesto el loop snd_speedboost + scr_music_duck + los 2
  cortes (verificado: 0 referencias a snd_speedboost en 8ec415a1).
  v75 (encima de 8ec415a1): (1) KindAndFair.c restaurado BYTE-A-BYTE al
  original pre-v73 (ef3c5d87) — quien rompe el monitor cobra el boost,
  Exe incluido (el bloque del boost en scr_move_basic L311 hasta maneja
  a EXE_CHAOS: diseno original para todos); (2) guard KAF del cliente
  REMOVIDA de SERVER_KAFMONITOR_STATE; (3) musica de botas RESTAURADA
  (3 hunks de ef3c5d87); (4) se conserva TODO lo demas: guarda Exe SOLO
  en SERVER_BOX_STATE (los 5 tipos de caja nueva — rings, botas,
  invencibilidad, escudo, electrico — son survivors-only, lista
  confirmada por la duena), fix de inmunidad, veto ItemBoxMap.c, retune
  WSS. ItemBoxMap.c y scr_wss.gml SIN cambios (los de la v73 aplicada
  son identicos en funcion). OBLIGATORIO: RECOMPILAR el server — el
  binario v73 lleva el pid-0 del Kaf y sin recompilar el Exe seguira
  sin cobrar el boost aunque el cliente ya no tenga la guarda (pid 0 no
  coincide con ningun nid). Validador check_v75.py (SUSTITUYE a
  check_v73.py y check_v74.py). Entregable:
  download/v75_kaf_exe_boost_boots_music.zip.

- 2026-11-23 (v76 — HAZARD RELOCATE + SPAWN VARIETY): pedido de la duena
  sobre las cajas: "si caen en lava, precipicios y eso, que la caja se
  reubique automaticamente en otro spawn ring" + "que los spawns sean
  SIEMPRE variados, no siempre en el mismo lugar" (confirmo: red ring y
  anillo normal COMPARTEN tabla de spawns — misma entidad Ring.c con
  flag red al 10%, por diseno). Entregado sobre el commit 61a5e248:
  (1) cliente obj_itembox/Step_2.gml — bloque v76 que reubica la caja
  (CLIENT_BOX_RELOCATE de siempre, one-shot) si toca obj_abyss /
  obj_vv_lavacolumn / obj_spike (place_meeting) o la lava de Marijua
  (rect manual identico al del player), en CUALQUIER estado (cayendo o
  apoyada: las columnas de VV erupcionan DESPUES sobre cajas apoyadas);
  (2) server Ring.c — memoria FIFO ult-4 slots de anillo (ring_recent[]
  en Game struct, auto-reset por ronda): con alternativa fresca los
  recientes quedan vetados (6.4% -> 0% de caidas en la ventana); (3)
  server ItemBoxMap.c — veto ult-1 -> FIFO ult-3 zonas (14% -> 0%);
  (4) Server.h — campos nuevos (struct interno, CERO protocolo);
  (5) Ring.c +<stdlib.h> explicito (rand implicito no compila en gcc
  moderno). Veto v74 exe-denial + flujo relocate + nucleo v63 INTACTOS
  (verificado por contenido). Validador check_v76.py (SUSTITUYE a
  check_v75.py) + simulador sim_v76.py. Entregable:
  download/v76_hazard_relocate_spawn_variety.zip. RECOMPILAR el server
  (Ring.c/ItemBoxMap.c/Server.h cambiaron).

## v80h2 — 2026-11-24 — CRASH "point_in_circle argument 1 undefined" (REAL CAUSE, verified against this repo)

ERROR (Android, on startup, no input needed):
  point_in_circle: argument 1 incorrect type (undefined) expecting a Number
  at gml_script_scr_controls_update_touch (line 223)
  called from gml_object_obj_controls_step_1 (line 5)

ROOT CAUSE (3 evidences, all verifiable):
  1. GameMaker runner error docs: "argument (index)... where an index of 1
     is the FIRST argument" => argument 1 = _x (the touch coordinate), NOT
     an obj_config variable.
  2. device_mouse_x_to_gui docs: on mobile "this will only be updated while
     the screen is being touched" => an untouched touch slot can return
     undefined for _x/_y.
  3. House pattern in this repo: all 10 other point_in_circle calls in the
     touch loop sit behind "_state &&" (short-circuit when no finger), and
     obj_game_chat/Step_0 only reads device_mouse_*_to_gui after
     device_mouse_check_button. The v78 V-block was the ONLY unguarded
     call: it ran 24x per frame for all slots with no finger down =>
     _x undefined => instant crash on startup.

  (The earlier v80h guess — "obj_config.bV2X undefined" — was WRONG:
  obj_config Create/load define bVX and bV2X with try/catch + defaults.
  A corrupt 1.bson could still leave them undefined because json_parse
  does NOT throw on missing fields; the V-GUARD is_undefined checks also
  cover that case.)

FIX (v80h2 "V-GUARD") in scripts/scr_controls_update_touch:
  Replaced the 2-line `var _inV = point_in_circle(...) || (jUse && ...);`
  with the same expression guarded by _state FIRST (house pattern) plus
  is_undefined armor on bVX/bVY/bVScale and bV2X/bV2Y/bV2Scale.
  Behavior with a finger down is IDENTICAL to v78 (verified by simulation:
  finger on small V, finger on main V diamond in-match, lobby, finger
  elsewhere); without a finger it now returns false instead of crashing.

FILES CHANGED BY v80h2: only scripts/scr_controls_update_touch/
scr_controls_update_touch.gml (nothing else). Reparador .bat PASO 5b was
also rewritten to apply this same patch (3 paths: literal, whitespace-
tolerant regex, upgrade from old v80h V-DEFENSE; idempotent; .bak stamp).

MAP (quick cache for future sessions):
  scripts/scr_controls_update_touch.gml — per-slot touch loop (24 slots):
    lines ~26-213: dpad joystick claim + A/B/C (40px) + D/E/F/G/W (22px)
      buttons, ALL guarded by "_state &&".
    line ~215-243: V block (v78): small V (emote column, 22px, bV*) +
      main V diamond (A/B/C cluster, 40px, bV2*, in-match only via jUse),
      one shared VTouchId so sliding between both keeps the key held.
      v80h2: _inV now guarded by _state + is_undefined (see above).
    line ~245-301: joystick direction -> keyboard_key_press/release.
  objects/obj_config/Create_0.gml — defaults + load()/save() of 1.bson;
    bV* = vTouch entry, bV2* = vMainTouch entry, both try/catch armored
    (but json_parse missing-field => undefined is silent; that's why the
    is_undefined armor exists in the V-GUARD).
  objects/obj_controls/Create_0.gml — isMobile (os_android) +
    scr_controls_init_touch() call; Step_1 calls scr_controls_update_touch
    every step when isMobile.
  objects/obj_controls/Draw_64.gml — draws V small (frame 10/11 of
    spr_mobile_emotionbutton) and main V diamond (frame 6/7 of
    spr_mobile_button) reading the same bV*/bV2* vars.
  objects/obj_game_chat/Step_0.gml — the house reference pattern for
    safe touch reads (only read coordinates after check_button).

## v80i — 2026-11-24 — PERSISTENT "line 223" crash: forensics + SLOT-SANITIZE

CONTEXT: user reported the SAME crash still happening after v80h2 was
already committed to the repo (commit "ewe", HEAD 79f4035b). The error
still said "line 223" — but in the CURRENT file line 223 is a COMMENT
(the v80h2 V-GUARD header). A comment cannot crash. Forensic conclusion:
the phone is running an APK built from the OLD script, OR the user's PC
copy was patched by the old v80h .bat (V-DEFENSE), which this session
found to DELETE the whole `var _inV` when "upgrading" (bug: the v80h
block contained the var; removing the block removed the var; the .bat
then failed to find anything to patch and left a script with NO _inV
definition at all). Possible failure chain now closed.

ROOT-CAUSE MODEL (validated by sim_v80i.py, 8 scenarios x 3 versions):
  - v78 script: crashes at line 223 in ALL scenarios (no _state guard on
    the V block; device_mouse_*_to_gui returns undefined for untouched
    slots on mobile — GM docs: "only updated while the screen is being
    touched").
  - v80h2 script: only crashes if _state is true while coords are still
    undefined (S7 edge: press frame / physical mouse without touch data
    => dpad line 26). Rare but real.
  - v80i script: no crash in any scenario (S7 closed by SLOT-SANITIZE).

FIX v80i (3 changes, all in this zip):
  1) SLOT-SANITIZE right after `var _state = ...` in the slot loop:
     `if(_state && (is_undefined(_x) || is_undefined(_y))) _state = false;`
     Covers dpad + all buttons A..W + V in one place.
  2) Joystick fallback: if the drag finger coords are undefined, treat
     them as the pad center (releases all 4 directions, keeps jTouchId).
  3) BUILD TAG in objects/obj_controls/Draw_64.gml: draws "v80i" in the
     bottom-left corner (Android only, alpha 0.55, outside the HUD if so
     it shows even with HUD hidden). PURPOSE: the user can SEE which
     build the phone is running. No tag = old APK => uninstall first.

BAT: reparar_disaster2d.bat upgraded v80g -> v80i (PASO 5b/5c/6b):
  - PASO 5b applies the full v80i to whatever it finds (v78 / v80h
    V-DEFENSE / v80h2 / already-v80i); all 4 paths converge to a file
    byte-identical to the one in this zip (verified).
  - Writes with [IO.File]::WriteAllText = UTF-8 WITHOUT BOM (the old
    Set-Content -Encoding UTF8 in PS 5.1 writes a BOM; if GM's compiler
    choked on it, that alone could explain the fix never reaching the
    APK).
  - PASO 5c adds the BUILD TAG to Draw_64.gml.
  - PASO 6b prints the anti-old-APK checklist (uninstall before install).

VERIFICATION (all re-runnable):
  - sim_v80i.py: GM-runtime simulator over the REAL .gml of each version
    (undefined propagation, short-circuit && / ||, point_in_circle arg
    check 1-based, fatal error = game over). 8 scenarios x 3 versions:
    v78 = crash everywhere (line 223 = the user's exact error), v80h2 =
    ok except S7 edge, v80i = no crash 8/8. Also runs the 4 .bat OUTPUT
    files: all identical, all no-crash (roundtrip TODO OK).
  - verify_bat_v80i.py: applies the .bat's own regex/blocks (extracted
    from the .bat text) to the 4 input versions; checks CRLF/ASCII/
    here-strings/no-BOM/idempotency; found and fixed 3 real .bat bugs
    (jx pattern missing trailing \r?\n glued a comment onto a code
    line; V-DEFENSE removal deleted var _inV; BUILD TAG ate the closing
    brace).
  - lint: braces/parens balanced, 11 point_in_circle, tabs preserved,
    LF endings, ASCII-only insertions (immune to PS5 BOM issues).

DECISION RULE for future crash reports (scr_controls_update_touch):
  - "line 223" + no "v80i" tag on screen => OLD APK (uninstall, rebuild).
  - "line 26/27" (dpad) => coords undefined while _state true: already
    closed by SLOT-SANITIZE in v80i; if it still happens, the APK is not
    v80i (check the tag).
  - Any OTHER line => send me the ~10 log lines around it.

FILES CHANGED BY v80i: scripts/scr_controls_update_touch/
scr_controls_update_touch.gml, objects/obj_controls/Draw_64.gml,
reparar_disaster2d.bat (v80g -> v80i). Nothing else.
