# LEARNING.md — Agent knowledge base for disaster2d-oss (TD2DR)

This file is the accumulated learning log for working on this repo. It is
included in every delivery zip together with CACHE.md so any future chat
can pick up where we left off. Written in English on purpose (owner's rule #5).

## Project layout (crash course)

- GameMaker (GM 2022+) project at repo root: rooms/, objects/, sprites/,
  scripts/ (GML). The `.yyp` is the project file; never hand-edit unless a
  resource is added (v62 did that once for obj_itembox + sprites).
- C server ("betterserver-oss/", MSVC on Windows, gcc-friendly):
  - `disasterserver/states/*.c` are the REAL state files used by CMake
    (`states/Game.c` etc). The copies at `disasterserver/Game.c`,
    `disasterserver/Lobby.c`... at the root of disasterserver/ are OLD
    duplicates that do NOT compile (stale, mention `Game.cooldowns` which
    was moved to `PeerData.plr_cooldowns`). DO NOT edit those by accident —
    always edit `states/<Name>.c`.
  - Entities in `disasterserver/entities/*.c` + headers in
    `include/entities/*.h`.
  - Maps in `disasterserver/maps/*.c`, registered in `disasterserver/Maps.c`
    (`g_mapList[MAP_COUNT]`, index = map id 0..24, same order as client).
  - Map lifecycle: `game_checkstart` calls `cb.init` when all players ready;
    `game_state_tick` calls `cb.tick` each tick; TCP packets go
    `game_state_handletcp` -> `cb.tcp_msg` (cursor advances per call, use
    `packet_seek(packet, 0)` to re-read); between rounds
    `results_uninit` frees ALL entities + `game_init` resets
    `elapsed=0, entid=0` and creates a fresh entity DyList.
  - Round timing: `server->game.elapsed` += delta every tick from map start.

## Client↔server mapping (map id → room)

- Server `g_mapList` index → client `global.levels[map].rid` (scr_globals.gml)
  → `room_*`. Same order, 25 entries. Map ids used by the itembox tables
  were written to match this order EXACTLY (see ItemBoxSpawnTables.c).

## GameMaker ground truth (how collision actually works)

- ALL walkable ground belongs to the `obj_floor_parent` family. The player
  (scr_move_basic.gml `place_meeting(..., obj_floor_parent)`) and our box
  (obj_itembox/Step_2.gml) collide with that parent. `obj_solid_parent`
  ITSELF inherits from `obj_floor_parent`, so both full solids and
  jump-through platforms are one family.
- Floors are instance tiles in each room's `GMRInstanceLayer`s with real
  sprite sizes (obj_solid_block 128x128, obj_platform_jumptrough 64x32,
  obj_kaf_slope1 178x128, obj_ghz_slope2 194x117, obj_ghz_slope3 134x55,
  obj_hn2_slope1 255x127, obj_skybase_slope 119x72, obj_weed_slope 256x64,
  obj_ycr_slope 512x96...) — READ dims from sprites/<spr>/<spr>.yy
  ("width"/"height") and scale by instance scaleX/scaleY.
- Two rooms (Torture Cave, Haunting Dream) draw their whole terrain in ONE
  "mega collision sprite": obj_am_collision (spr 4864x1280) and
  obj_hd_collision (spd_hd_colliison 4096x1984, house typo in the name).
  Pixel color = collision: TC solid green (0,255,27), HD solid yellow
  (251,242,54), rest transparent. We read the frame PNG with PIL and do
  per-pixel ground detection (derive_spawns_all_v68.py `mega_sprite_ground`).
- `obj_ring_spawner` instances mark traversable spots in every room — the
  best candidate seed for spawn zones.
- Springs (`obj_spring_parent` family) launch things to their death: veto
  zones within 48px. Hazards (spike/damage/lava/acid/mine/fire/thunder in
  the name): veto within 48px.
- Room .yy format: `roomSettings.Width/Height` (NOT top-level width!),
  instances have objectId.name, x, y, scaleX, scaleY. JSON needs the
  trailing-comma fix `re.sub(r',\s*([}\]])', r'\1', txt)` before json.loads.
- GML style: 8-char indents (tabs) in scripts/net_state_game.gml, GML
  switch in `case room_x:` form; state handlers keep per-entity variables
  (nid, type, isBroken...) — server is the only source of truth for positions.

## Hard-won lessons (bugs that cost us days)

1. **v67 — game_find UB (THE big one)**: `game_find(server, (Entity**)arr, tag, n)`
   writes POINTERS. Declaring `ItemBox boxes[N]` (structs by value) and
   casting to (Entity**) makes every `boxes[i].field` read garbage
   (undefined behavior). On MSVC the garbage can read `timer<0` for all →
   alive>=4 → roll blocked FOREVER ("re-enter Kind, no boxes"). Correct
   house pattern: `ItemBox* box[N]; ... box[i]->field` (see VolcanoValley.c,
   DarkTower.c). ALSO: `used[nid]` marking read garbage nids → phantom
   occupied slots → boxes stacked on residues (v66 symptom).
2. **v64 — box spawned 30px under the floor**: Step_2 had `y += 30` AFTER
   the collision `while` loop → buried/invisible. The while loop alone is
   the correct landing.
3. **v63 — box scale 0.47 applied to LIVE boxes**: the 0.47 residue scale
   belongs ONLY to the broken state (spr_boxused 64x64). Live boxes always
   scale 1.0.
4. **client state 1 (READY re-diffusion)**: if the instance is missing
   (client re-entered mid-round), CREATE it as broken boxused — else the
   server thinks the box lives there and the client never sees it.
5. **Packet cursor**: `PacketRead` advances a local cursor per handler;
   after `cb.tcp_msg` consumed a packet, `packet_seek(packet, 0)` before
   passing it on (v68 central tcpmsg hook relies on this).
6. **gcc link-check harness** (scripts/link_stubs_v62.c, link_check_v62.c,
   sim harness in /tmp/linkcheck + /tmp/enet_stub): stub enet types
   (ENetPeer needs `roundTripTime` member), stub g_config, mini
   game_spawn/game_find + real DyList.c compiled in. If gcc links 0
   undefined references, MSVC LNK2019 is dead.
7. **Do not trust room tile objects without checking parents**:
   obj_fart_tile inherits floor (it IS ground), obj_abadon_cloud does NOT
   (decor). Resolve parent chains dynamically instead of maintaining a
   hand list (derive_spawns_all_v68.py `is_floor()`).

## The ITEM BOX system (v62→v68 state of the art)

- Server entity ItemBox.c (tag "itembox"): nid = spawner index, type (5
  rewards, weighted 35/20/15/15/15), timer<0 alive / countdown when broken
  (25-30s), `relocated` flag one-shot, activate is idempotent.
- v68: CENTRAL system for ALL maps — ItemBoxMap.c (roll + ACTIVATE/
  RELOCATE handlers) + ItemBoxSpawnTables.c (auto-generated zones per map,
  dispatch `g_itembox_tables[MAP_COUNT]`) + 3 hooks in states/Game.c:
  init after map init (per-round reset, no elapsed heuristics), tick after
  map tick, tcpmsg after map tcpmsg (packet_seek 0 first).
- KindAndFair.c went back to stock (KafBox monitors only); its spawn table
  (v65, map id 7) lives in the generated tables now.
- Zone derivation rules (owner's rules, generalized): ring spawner seeds,
  real ground within 64px below (floor-family rect OR per-pixel mega
  sprite), no abyss, no spring/hazard within 48px, nothing on the high row
  (y < 40% room height), dedupe 96x64 px, box placed ON TOP
  (y = ground_top - 30). Result: 25/25 maps, min 3 zones, 262 total.
- Client is map-independent (all via SERVER_BOX_STATE states 1-4 in
  net_state_game.gml). STATES: 1 READY(re-diffuse; create-as-broken if
  missing), 2 BROKEN(+reward to pid), 3 SPAWN(x,y,type), 4 DESPAWN.

## Owner's golden rules (recorded 2026-11-22, verbatim summary)

1. ALWAYS fetch the repo before working, every chat, no exceptions.
2. Delivery zip carries ONLY modified/created files vs origin/main —
   nothing intact. (git reset origin/main; git status is the manifest.)
3. Only re-analyze recently edited files / files I edited before the pull.
4. Investigate everything AND keep a work log file for future chats.
5. Keep a learning file (this one) + a cache file (CACHE.md) ALWAYS
   updated and ALWAYS included in the zip; English to make it easy.
6. Verify 100%: test until fully sure; watch for .yyp/.yy/GML errors;
   re-check edited files open correctly and don't runtime-error.
7. Stay on top of anti-cheat: any new attack vector needs an exception/
   guard added.
8. Research EVERYTHING needed — nothing escapes to the editor.
9. ALWAYS write what was learned into LEARNING.md (this file) — it is
   the agent's memory: log hits and misses so knowledge accumulates
   across chats.

## Anti-cheat surface (rule 7 current state)

- CLIENT_BOX_ACTIVATE: AssertOrDisconnect(v->in_game) + entity lookup by
  tag + nid, idempotent activate (broken box can't re-break → no ring
  farming), reward only goes to the reporting pid.
- CLIENT_BOX_RELOCATE: one-shot per entity (`relocated` flag), tick
  performs the removal — no repeated teleport spam.
- New maps inherit all of this automatically (central handler, v68).
- If a new CLIENT_* packet gets added to the enum: net_packets.gml and
  Packet.h MUST be updated in lockstep (enum sync check in check_v6X.py).

## v70 — Suite "Cajas" module (item box durations) — lessons

- Owner asked to "add to the suite the option to configure the time of
  the boxes (speed and invulnerability)". Best lever: convert the four
  duration literals in net_state_game.gml's reward switch into
  #macro ITEMBOX_*_TIME entries — the Suite already has a battle-tested
  macro editing engine (AnimCore.parseMacros/setMacro + T.writeEdits
  with backups/undo), so the new module is ~200 lines of UI on top of
  existing machinery instead of a new patcher.
- GM macro placement convention (verified across the whole repo): ALL
  745 #macro lines live at FILE level (column 0), NONE inside a
  function. First attempt put them indented inside net_state_game's
  reward switch (they compile fine — macros are compile-time
  substitution), but house convention wins: moved to the top of the
  file, right before the first function. Check conventions with a
  repo-wide grep BEFORE placing new macros.
- Suite module anatomy (the pattern every module follows):
  1. nav button `data-mod="key"` in a category group (Sistema);
  2. `<div id="mod-key" class="mod hidden">` panel — side/mid/right
     three-column layout already styled;
  3. switchModule(): `$('#mod-key').classList.toggle('hidden', mod !==
     'key')` + dispatch `else if (mod === 'key' && window.enterKey)
     window.enterKey()`;
  4. module JS in its own <script> IIFE: state object (Bx = { ready,
     orig, work }), ensureData (read once), renderRows (reuse .cdrow
     CSS!), setMacroVal-style edit, sync to S.edits/S.pendingFiles,
     write via T.writeEdits, undo via T.undoLast, refresh by chaining
     S.onAfterWrite (call prev chain!), discard via
     T.discardModulePending (set ready=false to force disk re-read).
- E2E-testing a browser-only tool without a display: serve the repo
  over `python3 -m http.server` (file:// frames are cross-origin and
  block contentWindow access), load a driver page that embeds the real
  Suite in an iframe, and drive it with agent-browser eval. Fake the
  File System Access API by stubbing S.rootHandle with a plain object
  tree ({ files:{}, dirs:{}, getDirectoryHandle, getFileHandle,
  createWritable }) — writeEdits is closured over the REAL ensureDir/
  fsWalkFile so T.fsWalkFile stubs DON'T work; only S.rootHandle does.
- DOM-edit test gotcha: after each edit the module re-renders rows, so
  cached row elements go STALE. Query the DOM fresh after every change
  (users do this naturally by looking; tests must too).
- The Suite's own <script> count regex can lie: an HTML Parser
  (html.parser) is the truth. The original file "had 10 <script> vs 9
  </script>" — actually a <script> MENTIONED inside a JS comment
  ("orden de <script>") fooled the regex. Line-anchored tags
  (^<script> / ^</script>) match the real structure.
- AnimCore is UMD (module.exports in Node / window.AnimCore in
  browser): to test its parseMacros/setMacro in Node, isolate the
  factory function and `new Function('return (' + factorySrc + ')')()`
  — the factory ends before the final '});' (that closes factory+UMD
  wrapper together; slice needs + '}' to close the function body).

## v71 — the shieldTimer crash (bug class + template fix)

- **The error**: "Variable obj_amy_canon.shieldTimer(100297, -2147483648)
  not set before reading it" at net_state_game L2519 — a dot-READ of a
  variable THIS instance never declared. In this runtime dot-WRITES
  create the variable on the instance (the v62/v70 rewards rely on it:
  `global.player.electricShieldTimer = ...` works), but dot-READS on an
  instance without it are FATAL.
- **Who declares what matters**: only obj_sally (Create L21),
  obj_sally_canon (Create L30) and obj_rouge (Create L150) declare
  shieldTimer. The other 19 character objects don't. ANY new code reading
  a character-specific timer on `global.player` MUST use
  variable_instance_exists first — that is the house pattern (reward
  cases 3/4, every electricShieldTimer site).
- **The template** for "box reward that works for EVERY character" is the
  v62 electricShieldTimer lifecycle (clone it 1:1): guarded set in
  net_state_game -> guarded tick in scr_move_basic -> guarded consume in
  scr_player_hurt -> overlay in every character Draw_0 -> bitflag sent
  from obj_netclient Step_2 -> written UNCONDITIONALLY on the puppet in
  net_udpprocess -> drawn generically in obj_player_puppet Draw_0.
- **Countdown skip-list**: when adding a generic per-frame tick for a
  timer that SOME characters already tick in their own special script,
  EXCLUDE those characters or it runs at 2x speed. shieldTimer skip-list:
  Sally+SallyCanon (they SHARE scr_sally_special L275, which also keeps
  shieldRechrage and the demonized-expiry effect) and Rouge
  (scr_rouge_special L912). The three projectile paths
  (obj_tails_projectile / obj_blaze_fireball / obj_metal_amy_bullet)
  keep their Sally-only shield-break by original design — same as the
  electric shield, which doesn't stop projectiles either.
- **Puppet bit vars must be written EVERY packet** (net_udpprocess):
  conditionally writing leaves stale TRUEs that never clear when the
  bit drops. Unconditional `var = bitflags & BIT` is safe (false for
  those who don't use it) and self-cleaning. electroShield L173 is the
  reference; sallyShield now follows it.
- **Draw exclusions**: characters that already draw their own version of
  an overlay (Sally/SallyCanon/Rouge for the bubble) must be excluded
  from the GENERIC overlay — locally (don't add the block to their
  Draw_0) and on puppets (`character != CHARACTER_X` guards) — else
  double draw.
- **Redundant OR of the same bitflag is harmless**: the historical
  Sally/Rouge PLAYER_SALLYSHIELD send blocks in obj_netclient Step_2
  were left intact (least-risk edit policy — every untouched line is a
  line that cannot break).
- **scr_move_basic runs for ALL 22 characters including killers**
  (obj_exe/obj_exetior/obj_exeller/obj_metalamy call it from Step_0),
  so a tick there covers every playable object; hurt-consumption stays
  behind `global.character != CHARACTER_EXE`, exactly like the electric
  shield's.
- **Twin consume blocks**: Rouge's shield-break block in scr_player_hurt
  was behavior-identical (minus an achievement) to the Sally block —
  generalizing the Sally block's condition preserved Rouge exactly and
  allowed deleting the twin. When merging, diff the two blocks FIRST
  and keep every character-specific line nested inside the generic one.
