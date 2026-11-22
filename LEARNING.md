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

## v71 — boots music lost after v70 zip — lessons

- ROOT CAUSE (process bug, not code bug): v70 was built on origin/main
  BEFORE the owner pushed v69, and its net_state_game.gml came from the
  OLD base + new macros. When the owner unzipped v70 over their game
  (which already had v69) and committed, the file LOST the 3 boots-music
  hunks. Music died. The other 4 v69 files survived (not in the zip).
- NEW GOLDEN RULE (recorded): when building any new version, FIRST
  fetch and check whether the owner has already pushed previous zips.
  NEVER build a zip from a base that predates delivered zips touching
  the same files. Reconstruct from the owner's HEAD (it already
  integrates the previous zips) or merge the previous zips into the
  base explicitly. Consequence of skipping: silent feature removal
  that looks like a regression of someone else's change.
- Detection was instant because the symptom was precise ("the boots
  music stopped") and the v69 feature was fully documented in CACHE.
  grep for the feature's code markers (snd_speedboost refs in
  net_state_game) vs the delivered zip's content told the whole story
  in one diff. Keep feature markers greppable in CACHE for this.
- The fix was SURGICAL: re-apply only the lost hunks (adapted to the
  new context — bootsTimer now reads the v70 macro; comment updated to
  document the audio-loop-vs-time interaction: 32.8 s loop covers the
  owner's edited 15 s, and the Suite can keep editing time without
  ever touching the music lines — verified: AnimCore.setMacro changes
  exactly 1 line and the music survives).
- Checker hygiene: three of my own checker bugs produced false FAILs
  (template-string double-escaped \b regex, hardcoded wrong .yyp
  filename, counting comment mentions as code refs, and new Function
  returning the FACTORY instead of calling it — `factory()` vs
  `factory`). Manual verification of the underlying truth BEFORE
  trusting a checker's FAIL output: the checker is code too, and a
  FAIL can be the checker's bug, not the feature's.
