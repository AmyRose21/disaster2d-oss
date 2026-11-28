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

## v72 — WSS port (squash & stretch from SRB2 Lua) — lessons

- **The port target already existed**: Sally Canon's fase 2 (f2Sq /
  fase2Sq, macros SALLY_CANON_SQ_* at scr_sally_canon_fase2 L61-63) is
  a one-shot squash&stretch with the ground-anchoring formula
  `yoff = (sprite_height - sprite_yoffset) * (1 - ys)` — the exact
  technique WSS needed. When porting a mechanic, grep for a partial
  implementation first: it sets the house formula AND the feel values.
- **NEVER touch image_xscale/image_yscale on TD2DR characters**:
  image_xscale IS the facing direction (scr_move_basic sets ±1 at
  L706/724/809/814, and the spindash uses `gspd = 12 * image_xscale`
  — L351 — as a SIGNED speed), and the collision mask scales with
  both. Cosmetic scale must enter ONLY as multiplicative factors in
  the body draw_sprite_ext call: `image_xscale * fx, image_yscale * fy`
  plus a y offset. Physics and hitboxes stay byte-identical.
- **The body draw line is unique per character file** — all 22 Draw_0
  share the prefix `draw_sprite_ext(sprite_index, image_index,
  floor(x), floor(y), image_xscale, image_yscale,` and then diverge
  (tails: attackCharge in rotation; chaos: _angle var; amy_canon:
  isLightDashing; killers: shockedTimer in alpha). Patch the shared
  prefix, keep each file's own tail. Verify count==1 per file first.
- **scr_collision_basic is the perfect once-per-frame hook**: all 22
  character Step_0 files call it directly AFTER scr_move_basic (which
  only calls it itself in early-return paths and Amy Canon's light
  dash). It resolves isGrounded inside (L376-462 check functions), so
  its END sees the frame's final grounding. Double calls on rare
  frames (light dash, not-ready) are harmless if the update is
  designed re-runnable: edge triggers consume state, decays are
  per-call — design for idempotence anyway.
- **Puppets already receive yspd/xspd/state in CLIENT_PLAYER_DATA**
  (net_udpprocess L97-104) and JUMP=3/FALL=4 are SHARED state macros
  (scr_survivors L4-5) used generically across characters — so remote
  squash&stretch costs ZERO new network bytes. But only DISCRETE
  events work there: continuous styles would read slope-running
  (WALK state with yspd≈2-4) as "airborne". Known gap: spin-jumps
  travel as state SPIN (`if(isSpinning) { state = SPIN; return; }`
  in Step_2 state machines) so they don't stretch on remote screens.
- **Read-after-exists for lazily declared vars**: justJumped /
  isSpinCharging / gspd are NOT declared in every character's Create
  (the original code only reads them behind && short-circuits or in
  character-specific branches). Every new read of a non-universal var
  goes behind variable_instance_exists — the v71 crash class.
- **Tuning by simulation instead of guessing**: the jelly spring
  constants (K=0.035, DAMP=0.88) were picked by porting the exact
  per-frame math to Python and sweeping (K, DAMP) until overshoot
  ~-0.108 with 3 crossings settling in 51 frames. check_v72.py re-runs
  that simulation against the MACRO VALUES PARSED FROM THE GML, so
  retuning via Suite macros that breaks the feel budget fails the
  validator.
- **Validator gotchas this round**: (a) git porcelain quotes paths
  with spaces ("Sonicexe The Disaster 2D Remake.yyp") — strip quotes
  before comparing; (b) untracked NEW directories appear as the dir
  (?? scripts/scr_wss/), not per-file; (c) decorative comment banners
  (`// ====...`) trip naive `===` regexes — strip comments (with a
  string-aware lexer) before syntax pattern checks; (d) macro-usage
  checks must ignore comments (the Lua function names in prose match
  WSS_\\w+); (e) NEVER `.strip()` the whole `git status --porcelain`
  output — the first line " M path" loses its leading space and
  `l[3:]` then eats the first letter of the filename (CACHE.md ->
  ACHE.md). Parse per-line only.
- **Zip manifest from `git status` must expand untracked dirs**: the
  porcelain line for a brand-new directory is the DIRECTORY itself;
  feeding that list to `zip -@` ships an empty dir entry and NO files
  (caught in verification: fresh clone + unzip + diff showed
  "Only in repo: scr_wss.gml" — the whole feature would have been
  missing). Always `find <dir> -type f` each directory entry before
  zipping, then verify the roundtrip: fresh clone -> unzip -> diff -rq
  -> run the validator FROM THE EXTRACTED TREE (that is the exact
  state the owner's repo will be in).
- **Decay on the trigger frame is Lua parity**: SRB2's PreThinkFrame
  runs Stretch→Squash→ReturnScale in sequence, so the return animation
  eats into the trigger's first frame (0.35 → 0.277 visible). Keep it
  when porting, and encode it in the simulation assertions.

## v73 — exe denial + invuln reset + WSS retune — lessons

- **"Refresh to max" vs "guard !already-active" are different reward
  semantics — confirm which one each reward needs.** The v62 reward
  switch cloned the Kaf boost's `if(timer <= 0)` guard for ALL four
  timed rewards; for the invulnerability box that was a BUG to the
  owner (picking a second invuln box while immune wasted it). Fix =
  unconditional `hurttime = ITEMBOX_INVULN_TIME` (always resets to
  max). Shield/electric/boots KEEP the guard (intended no-stack
  semantics). When porting a guard pattern to N sites, ask which of
  the N want refresh-to-max.
- **The exe denial reused TWO existing house conventions, so the
  diff is one line per site**: (1) `pid 0 = nobody collects` — the
  Tails-projectile break convention (`is_proj ? 0 : pid` in
  ItemBox.c/kafbox_activate); peer ids start at 1
  (`v->id = incomingPeerID + 1`, Server.c; `peer_msg` rejects id 0),
  so pid 0 can never match a real client. (2) `server->game.exe ==
  v->id` is the production "is this peer the round's exe" expression
  (Lib.c `disaster_server_peer`) — mirror it verbatim instead of
  inventing a new check.
- **SCOPE (the v74 lesson): one rule can map to SEVERAL similar
  systems — confirm the target list with the owner BEFORE patching
  all of them.** v73 applied "exes get no buffs" to BOTH the new item
  boxes AND the KAF monitors; the owner corrected: "los de KAF no los
  cambies ... me referia a las cajas nuevas". v74 reverted the KAF
  half (KindAndFair.c pristine, no client guard on
  SERVER_KAFMONITOR_STATE). Cheap prevention: when the delivery names
  a rule that will touch N systems, LIST the N systems in the delivery
  note so the owner can veto in one line.
- **Server-side denial beats client-side for rule 7**: the reward pid
  is decided by the SERVER (itemboxmap_tcpmsg knows PeerData* v), so
  a modded exe client cannot self-award. Client guards
  (`global.character == CHARACTER_EXE` after the `nid != _pid` check)
  are still worth adding as defense-in-depth for MIXED BINARIES (new
  client + old un-recompiled server), which WILL happen because the
  owner compiles client and server at different times.
- **All 6 killer variants share `global.character == CHARACTER_EXE`**
  (Original/Chaos/Exetior/Exeller/MetalAmy/Jinna — the variant lives
  in `global.exeCharacter` / server `exe_char`). One check covers
  every killer.
- **`gcc -fsyntax-only` + a 10-line enet stub verifies server .c
  edits without the submodule**: the project headers only use
  ENetPeer/ENetHost/ENetPacket as opaque pointers, so a stub with
  those typedefs (+ `roundTripTime` for .c files) is enough for
  syntax AND struct-member checking (`v->server->game.exe` fails
  loudly if the field didn't exist). check_v73.py regenerates the
  stub in a tempdir at run time; on Windows (no gcc) the check is
  skipped with a note, not a failure.
- **Retuning preserves FEEL RATIOS, not absolute numbers**: doubling
  WSS_TAKEOFF_GAIN raised the jump stretch 0.315→0.450 (now
  saturates the cap); the Jelly spring (linear system) keeps its
  overshoot RATIO (~31% of amplitude: -0.108→-0.138) and crossing
  count automatically — only the settle frames grew (51→60, absolute
  epsilon cutoffs). Simulate before/after and assert the ratios.
- **Validator false positives to remember**: (1) counting a packet
  NAME in a file counts comments too — count the send line
  (`cpacket_tcp(PacketType.X)`) instead; (2) "TODO" is the Spanish
  word for "all" in this codebase's comments ("TODO el anti-cheat")
  — use `TODO:`/FIXME (with colon) for leftover-markers in C files;
  (3) when a per-file set is derived from a list that EXCLUDES one
  special case (obj_sally_canon has a different Draw patch), the
  git-surface check built from the same list forgets it too.
- **The git-status surface check must tolerate BOTH owner states**:
  v72 still uncommitted (v72 files appear as modified) or already
  committed (only v73 files appear). Encode: core-v73 must be
  present; v72 files are allowed-but-optional; anything else fails.
  The owner extracts zips over their tree in either state.
- **THE EDIT TOOL CAN REINDENT WHOLE TAB-INDENTED FILES**: editing
  ItemBoxMap.c/KindAndFair.c (server .c files use TABs) converted
  EVERY tab in the file to spaces — the raw diff showed 329+68
  changed lines vs 21 real ones (`git diff --stat` vs
  `git diff --ignore-all-space --stat` — run BOTH after every edit;
  they must match). Fix protocol: `git checkout --` the file, then
  re-apply via a Python script with literal `\t` anchors, assert
  count==1, and open with `newline=""` so line endings stay
  byte-identical (scripts/reapply_v73_c.py is the template). From
  now on: server .c (TAB) patches go through byte-exact Python,
  never the interactive editor.

## v74 — KAF scope correction + rebase onto the owner's own commit — lessons

- **THE OWNER COMMITS THEIR OWN WORK IN PARALLEL — inside the very
  files we patch.** Fetch found ef3c5d87: v72 applied byte-exact PLUS
  the owner's own restoration of their lost v69 boots music, with 3
  new hunks inside net_state_game.gml (the same file the v73 patches
  targeted). Never assume our previous working tree is the base:
  FETCH (rule 1), diff remote vs local tree first, then RESET to
  their commit and re-apply patches on top. The delivered file must
  carry their work + ours MERGED, or extracting the zip would silently
  delete their music.
- **Encode the owner's changes as validator invariants.** check_v74.py
  gained a section asserting the boots-music lines survive (play+duck
  1x each, stop+unduck 2x each) — any future rebase/extraction that
  clobbers their work now fails loudly. When rebasing onto an owner
  commit that touches a file you patch, protect their hunks too.
- **Superseding a delivery has a mechanical rule: the new zip carries
  FULL final versions of every file it touches** (so extracting over
  any prior state converges to the correct end state) — and for files
  the OLD delivery touched but the new one must NOT (KindAndFair.c),
  the LEEME must carry the explicit restore command
  (`git checkout -- <file>`). A correction without a restore
  instruction leaves the owner's tree in a half-old state forever.
- **Divergence analysis before reset:** local tree had v72+v73
  uncommitted; remote had v72+their music. Comparing
  `git diff origin/main --stat` per path group proved the 21 draws /
  puppet / hook / .yyp / scr_wss.yy were byte-identical, so only 3
  files needed real re-merging — 10 minutes of diffing saved a blind
  full rebase and documented exactly what the owner applied.

## v75 — owner applied the STALE v73 zip over their newer repo — lessons

- **A DELIVERED ZIP IS A TIME CAPSULE — the owner can apply it at any
  moment, over a repo that has moved on.** They applied the v73 zip
  AFTER committing their own boots-music work (ef3c5d87). The zip's
  net_state_game.gml was built on the pre-music base, so extracting it
  wholesale DELETED their music (0 snd_speedboost refs in the result).
  Full-file zips must be built from the owner's CURRENT commit — fetch
  immediately before zipping — and the LEEME must name the required
  base commit. When the owner reports a symptom, FIRST check what state
  their repo is actually in (fetch + diff) — the "KAF boost doesn't
  affect the exe" report was 100% explained by `git show` of their new
  commit, not by any bug in v74.
- **Versioning discipline when a correction supersedes an applied
  version:** the owner had v73 applied while v74 (the correction)
  existed only in chat. v75 therefore ships as a full-state delivery
  ON TOP of their actual commit (8ec415a1): remove the wrong v73 parts
  (KAF veto), re-add what the stale zip destroyed (their boots music),
  keep what is already right (item-box denial, WSS retune — do NOT
  re-ship identical files, golden rule 2). The symptom diagnosis lives
  in the worklog so future sessions can trace it.
- **The KAF boost was DESIGNED to affect the exe**: isBoosting is
  declared by all 22 characters and consumed in scr_move_basic L311
  (forced gspd 12) with an explicit EXE_CHAOS special case — original
  behavior includes the killer. scr_collision_objects breaks monitors
  on `_isAttacking || isBoosting` for everyone (invis exe still cannot:
  anti-grief). "Comportamiento normal" for a house feature = READ THE
  ORIGINAL CODE PATHS for every character class before scoping rules.
- **A server-side veto outlives its client removal**: with the v73
  server binary still compiled, the exe breaking a KAF monitor gets pid
  0 from the server and NOTHING reaches the client guard (pid 0 != nid
  → break). Reverting a server-side rule REQUIRES a server recompile to
  take effect — say so loudly in the LEEME.

## v76 — hazard relocate + spawn variety — lessons

- **Lava in this engine is NOT floor**: obj_vv_lavacolumn and
  obj_marijuna_lavaplatform hurt players via place_meeting/manual-rect
  but are not obj_floor_parent children — a falling item box passes
  THROUGH them and would rest at the pit bottom, under the lava,
  forever (unreachable, visually wrong). Hazard relocation must run as
  a RUNTIME overlap check, not rely on the spawn-table generator
  (derive_spawns_all_v68.py only guarantees "no hazard within 48px AT
  SPAWN TIME" — hazards MOVE/APPEAR later: the VV lava column's y is
  server-synced per eruption cycle, the Marijua lava platform rises).
- **obj_abyss teleports PLAYERS only**: its Step moves global.player
  and calls scr_player_hurt — any other entity (box, shard has its own
  special case) falls through untouched. "Falling into the void" for a
  non-player needs its own check (or the out-of-room-bounds fallback).
- **Mirror each hazard's OWN player check, don't invent one**: VV
  column and abyss use place_meeting (their masks are the trigger);
  Marijua lava uses a manual rect (x+48..x+113 / y+48..y+672) because
  its 160x672 sprite mask does NOT represent the lethal zone. The box
  check must use the same geometry, cross-checked in the validator
  (check_v76.py parses the player line and compares constants).
- **Thin triggers cannot be tunnel-skipped at max fall speed**: box
  bbox is 30px, max fall 12px/frame, smallest hazard trigger 32px →
  overlap window 62px > 12px steps → at least one frame always
  overlaps. Verified arithmetic, not luck.
- **DELIBERATE hazard exclusions (reachable = valid spawn)**:
  obj_ghz_water is swimmable (box reachable), obj_ycr_smokearea only
  drains 1 ring/sec (reachable, risk-reward), and periodic SWEEP
  hazards (obj_movingspike, obj_limpcity_echain1, darktower balls,
  marijuna judgerpor) pass by — the box stays breakable between
  sweeps. Relocating on sweep overlap would make boxes hop forever.
  Document exclusions in the code comment so future sessions don't
  "fix" them into false positives.
- **Red ring vs normal ring: same entity, same spawn table BY DESIGN**:
  Ring.c rolls `red` (10%) at spawn; the client picks obj_redring vs
  obj_ring from the flag at the same obj_ring_spawner slot. The owner
  guessed this ("comparten spawns" — they do). Variety therefore
  applies to the shared slot table (ring_recent memory), not to
  per-type tables.
- **Anti-repeat memory pattern (server, generalize from
  itembox_last_spawner)**: (1) count `fresh` = free slots NOT in
  recent memory; (2) goto-gen veto `fresh > 0 && recent_has(rnd)`; (3)
  FIFO push; (4) reset per round. For RING memory we put it in the
  Game struct (ring_recent[4]) so the compound literal at game_start
  zero-inits it — NO manual reset hook needed (pattern bring_loc);
  ItemBoxMap keeps statics + its existing itemboxmap_init reset.
  Simulations: window-hit rate 6.4%→0% (rings, 22 slots) and 14%→0%
  (boxes, 8 zones); no deadlock at 12 slots (fallback = any free).
- **A relocated box NEVER respawns at its own zone**: used[] is
  computed from game_find BEFORE the relocated entity dies this tick,
  so the just-freed zone is still "occupied" for the replacement roll
  (100% in simulation) — no extra code needed.
- **gcc ≥14 makes implicit-function-declaration an ERROR**: original
  Ring.c called rand() with only <CMath.h> (= math.h) included. Their
  build tolerated it; our -fsyntax-only did not. Fix = explicit
  <stdlib.h> (ItemBoxMap.c already did). When porting verification to
  a NEW .c file, expect pre-existing implicit decls — fix them, don't
  disable the check.
- **var locals ARE writable inside with() blocks** (GML): `_hz = true`
  inside with(obj_marijuna_lavaplatform) writes the enclosing event's
  local — used for the manual-rect hazard scan; `break` exits the with
  loop. Standard GML, but worth recording because it looks risky.
- **Tooling regression guard**: check_v76.py enforces CJK-clean
  deliverables — a draft of the v76 comment accidentally contained
  Chinese characters (model glitch); the checker now catches that
  class of bug forever.

## v77 — Not Perfect zone-follow — lessons
- **Read the user's words literally against the asset list**: "un fix
  para not perfect" sounded like "it's not perfect"; NotPerfect.c (map
  id 6) exists. ALWAYS grep the entity/object list for the phrase
  before interpreting a complaint as generic.
- **Zone maps need zone-aware item spawning**: Not Perfect rotates its
  playable area between 4 room quadrants (offsets 2904 x / 1368 y,
  SERVER_NPCONTROLLER_STATE every ~20 s, ~5 s in the last minute).
  A static spawn table (all 29 v68 points in the bottom half) means
  half the round has ZERO reachable boxes, and alive-but-unreachable
  boxes eat the ITEMBOX_MAX=4 pool. Fix = (a) spawn points in all 4
  quadrants, (b) server filters spawns to the current zone, (c) alive
  boxes outside the zone relocate same-tick, (d) repopulate what was
  removed so population follows the zone.
- **The v68 spawn-table generator is REPRODUCIBLE from room data**:
  every v68 point = obj_ring_spawner + 24 px x, floor top within a
  40 px window below the ring, box at top-30, dedupe 96x64, no spring
  at 48 px. Re-deriving the bottom half with those rules reproduces
  the shipped table 29/29 EXACTLY. Ring spawner positions are the
  author-validated "playable spot" seeds — better than raw collision
  scanning. Keep gen_np_top_v77.py as the reference implementation.
- **GMRInstance v4 property ORDER**: "resourceType":"GMRInstance"
  comes BEFORE scaleX/scaleY/x/y in room .yy files; multi-line
  instances (with overridden properties) break single-line regexes.
  Robust pattern: match from {"$GMRInstance":"v4" through
  "scaleX":N,"scaleY":N,"x":N,"y":N,} with re.S.
- **Validate new spawn points against the CLIENT's final resting
  position, not the spawn point**: Step_2's while-loop pushes a box UP
  to the highest overlapping floor top (e.g. (864,2034) grazes a side
  block 6 px and settles 24 px higher). Anti-cheat (player_check_zone,
  Zone.c rects = solid bodies, BLOCK_SIZE=128) must be checked at that
  final resting spot with a player standing there — checking the raw
  spawn point produces false rejects.
- **Tick order matters and is exploitable**: game_state_tick runs
  entity tick -> map tick (npctrl advances stage + broadcasts) ->
  itemboxmap_tick. Because the zone controller runs BEFORE the item
  system in the same tick, zone-following relocation can happen in the
  SAME tick as the player teleport with zero extra synchronization.
- **RAssert expands to `if(!(x)) return false;`** — never call it
  inside a void function (gcc -Wreturn-mismatch). House pattern: make
  the helper `static bool` and `return true` on the no-op paths.
- **FIND arrays bound FEATURES, not just memory**: the old
  ItemBox* boxes[ITEMBOX_MAX*3] capped game_find at 12 entities; with
  4 alive + 8 boxused residues (~27 s countdown each) a busy round
  could saturate it, silently blocking relocation repopulation (and
  even ACTIVATE visibility). Bumped to 24 (= ITEMBOX_MAX*6) in all 4
  call sites. When a find-result array gates a gameplay decision,
  size it for worst-case concurrent entities, not "expected" counts.
- **Simulation models must match the intended invariant, not an
  idealized one**: the first sim expected population to jump to 4
  after every zone change, but the map fills 1 box per 20 s roll
  (v68 cadence) — zone changes must PRESERVE population, not maximize
  it. 500 rounds x ~16 changes: 0 out-of-zone boxes, 0 same-point
  respawns, population preserved.
- **The editor (Edit tool) re-indents whole files tabs->spaces** when
  large blocks are replaced (ItemBoxSpawnTables.c: 619-line diff that
  is 95% whitespace). Harmless for C, but diff-stat discipline checks
  must normalize whitespace before comparing (check_v77.py does).

## v78 (2026-11-23) — operator-only chars, per-box respawn cooldown, box-ring heal, shield-break invulns, mobile V button
- **READ THE CLOCK BEFORE TRUSTING COMMENTS**: the v62 comment claimed
  "server->game.elapsed acumula segundos" — FALSE. It accumulates TICKS
  (delta=1 per tick at 60 Hz; states/Server.c loop TARGET_FPS 1000/60,
  game_state_tick per tick). ITEMBOX_FIRST_DELAY(15)/ITEMBOX_SPAWN_COFF(20)
  were used RAW against elapsed since v62: the real cadence was 0.25 s /
  0.33 s — the "destroy 1 and another appears instantly" was a 16-version
  old UNITS bug, not a logic bug. Proof pattern: entity timers that DO work
  multiply by TICKSPERSEC ((25+rand%5)*TICKSPERSEC in itembox_activate);
  game.time decrements by delta and time_sec-- every TICKSPERSEC ticks.
  RULE: anything compared against game.elapsed must be in TICKS.
- **Fix requests often name a symptom whose real spec is a redesign**: the
  owner asked for "30 s cooldown per box"; the honest fix replaced the
  roll-refill (which was refilling destroyed boxes in <1 s) with a pending
  queue: destroy -> push 30 s -> spawn when it hits 0 (paused while
  alive == MAX — her literal words), roll only refills when the queue is
  empty. Relocations (lava/zone) are NOT destructions and stay instant —
  keeping v63/v76/v77 semantics intact required one guard: a box already
  BROKEN (activated) when relocated must NOT count as `removed` (its
  cooldown is already queued; counting it double-fills).
- **House API smell: spawn helpers that "always return true"** (RAssert
  friendly). When a queue needs to know if a spawn actually happened, add
  a static `last_spawn_ok` flag set at the real game_spawn site instead of
  changing the return contract (RAssort(spawn_one) call sites would abort
  the server on a benign "no free spawner"). Pop the queue entry ONLY on
  real success; on failure keep it at 0 to retry next tick.
- **TWO touch circles sharing ONE TouchId** (small emotion-V + new big
  main-V, same KeyV): naive duplication flickers — button A's release
  branch (`else if(VTouchId == i)`) fires every tick while the finger
  holds button B. Correct pattern: one merged test
  `inCircle1 || (jUse && inCircle2)` -> press on enter-any / release on
  leave-both. A finger sliding between buttons never re-triggers.
- **The Edit tool normalizes tabs->spaces on WHOLE FILES** (re-confirmed on
  obj_menu/Create_0.gml, obj_config, obj_controls, init_touch: ~4,000
  whitespace-only diff lines). Workflow that survived: git checkout the
  file, redo with python byte-exact anchors (git show HEAD:file), assert
  count==1 per anchor. Diff-stat BEFORE zipping is the tripwire.
- **GM room instance = 3 mentions**: instanceCreationOrder (top of .yy) +
  %Name + name inside the layer's instances array. Missing the order list
  compiles but alters creation order; a name collision is undefined.
- **GM .yy/.yyp are trailing-comma JSON**: json.loads fails on room_menu.yy
  and the .yyp. Validate with re.sub(r',\s*([\]}])', r'\1', raw) first.
- **Sprite frame registration** (spr_mobile_button 6->8 frames): add 2
  GMSpriteFrame entries + 2 SpriteFrameKeyframe entries (Key 6.0/7.0 with
  fresh uuids) + sequence.length bump; PNG must exist TWICE (top-level
  <frameguid>.png AND layers/<frameguid>/<layerguid>.png, byte-identical).
  Pixel surgery on house sprites: diff frames to isolate the glyph zone
  (letters live in x16-31/y17-30), extract the EXACT tone palette from the
  letter pixels, erase with the face color (black 0,0,0,255), stamp the
  new glyph with the same tones — everything outside the zone stays
  byte-identical to the donor frame (checked programmatically).
- **Code-created fallback for room edits** (AboutAmyCanon precedent): when
  the user's IDE may compile a STALE room (zip extracted with the room
  open), ALSO create the instance from obj_menu/Create_0 guarded by
  `layer_exists && !instance-with-bid` — both paths coexist without
  duplicates. The settings-handle bid numbering must stay collision-free
  (mobSelectedButton routes 1-3 to obj_menu_mobilebutton, 4-9 to
  obj_menu_mobilebutton2; new bid 10 lives in the FIRST object and the
  slider branch gained `|| mobSelectedButton == 10`).
- **Invulnerability writes should never SHORTEN**: break-invulns now use
  max(current, new) — a shield popping while the player holds a LONGER
  invuln (box invulnerability 7 s) must not cut it to 2.5/4 s. The house
  already had the accumulate pattern (Sally evade +=); max() is the
  correct variant when the values are absolute durations.

## v79 (2026-11-23) — Android startup crash: GameMaker runtime mismatch (TOOLCHAIN bug, not project)

**Symptom**: owner built "Android Run" from GM LTS2026 IDE; APK installs,
app opens (splash) and closes itself after ~2-3 s, every launch. Windows
target of the same project runs fine.

**Root cause (verified 34/34 checks, script scripts/.../check_v79_android.py)**:
Igor mixed TWO runtime versions inside one APK:
- Asset compiler (writes game.droid): ran from `runtime-2026.1.0.28`.
- Android runner files (build.gradle, Java, res, and libyoyo.so for
  arm64+armv7): ALL 54+3 copied from `runtime-2026.0.0.23`. ZERO runner
  files from 2026.1.0.28.
Result: old native runner cannot parse the new compiler's object chunk
format -> `SIGSEGV (SEGV_ACCERR)` in `CObjectGM::LoadFromChunk+764` <-
`Object_Load` <- `LoadGameData` <- `DoTheWork` <- `BeginToEnd` <-
`Java_com_yoyogames_runner_RunnerJNILib_Startup`. Crashes 3/3 launches at
the same offset, BEFORE any GML executes — nothing in the repo can cause
or fix this; it is a build-toolchain state on the owner's PC.
Precedent class: YoYoYoGames bug #15043 (LTS 2026.0 IDE pulled runtimes
from the wrong feed; official fix = align runtime, DELETE stale runtime
folders, reinstall IDE if needed).

**Fix given to the owner (LEEME_V79.txt)**: close GM, delete
`C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\`,
run IDE broom (clean asset cache), rebuild Android; uninstall old APK on
device (or adb install -r). Confirmation tripwire: next Igor log must show
ALL "Copying ..." lines from runtime-2026.1.0.28 (esp. jniLibs libyoyo.so)
and none from 2026.0.0.23. Plan B: Check Android Setup + Runtime Feeds
(single 2026.1.0.28), nuke GMS2CACHE project cache
(`...\Cache\GMS2CACHE\Sonicexe_T_EAB73F4B`), full IDE reinstall last.

**Lessons for future sessions**:
1. "App opens then closes on Android" with a *successful* build+install =
   read the logcat FIRST. `F DEBUG : signal 11` + a `LoadFromChunk` frame
   in libyoyo.so = data/runner format mismatch, NOT game code. If the
   crash is before "Game Start" (no GML ran), stop auditing GML entirely.
2. Check Igor's "Copying ..." lines against the asset compiler's runtime
   path — they MUST be the same runtime folder. One compiler + another
   runner = guaranteed native crash at load.
3. The device-side runner prints its true version: `GameMaker v1.0.0.32908`
   (matches the OLD 2026.0.0.23 runner, not 2026.1.0.28). Cross-check it
   when unsure which libyoyo.so got packaged.
4. v78 integrity re-verified end-to-end during this diagnosis (rule 6):
   .yyp 2542 resources no dupes, spr_mobile_button 8 frames + keyframes
   0..7 + both PNGs 48x48 valid, room_menu instance V (378,121) present
   + in instanceCreationOrder, 10 touched GML files brace/paren balanced.
   The repo was NEVER the problem; do not "fix" it for this symptom.
5. Room layer gotcha (burned 15 min here): room_menu nests
   `OptionsControlsMobile` (GMRInstanceLayer) INSIDE the `Options`
   (GMRLayer) folder — a flat scan of root layers finds 0 mobile buttons.
   Always walk `layers` recursively (`yield from` helper).

### v79 addendum — owner's question: "must I clean the cache every VM↔YYC switch (Android only? PC never needs it)"

Short answer given: NO, not every time — switching VM↔YYC is supported
without cleaning. But Android is genuinely more fragile than Windows
here, and the v79 crash was NOT a VM↔YYC issue (that log was a pure VM
build: output folder suffix `_VM`, assetcompiler flag `/cvm`).

Why Android is the fragile one (mechanism):
- Windows builds have ONE pipeline: assetcompiler writes game.win /
  links the exe, runner loaded straight from the runtime folder every
  build. No second build system, no "is this file still valid?" logic.
- Android has THREE layers: (1) GMS2CACHE project cache holds the
  generated gradle project with the COPIED runner files (libyoyo.so);
  (2) gradle's own incremental build with UP-TO-DATE task skipping
  (v79 log: 38 of 41 tasks UP-TO-DATE, only 3 executed — gradle will
  happily skip re-copying a stale libyoyo.so it thinks is unchanged);
  (3) temp output folders are per-build-type (`..._E732935_VM` vs
  `..._YYC` suffix), so VM and YYC outputs don't collide — but the
  gradle project cache layer is SHARED between them.
- YYC on Android = no game.droid bytecode; GML is emitted as C++ and
  compiled by the NDK into the app. Switching modes regenerates that
  gradle project; any stale bit at that layer = startup crash or link
  errors that "shouldn't" be there.

Practical rule taught to the owner:
- Normal GML edits, same build type, same runtime → NEVER clean
  (incremental cache is what makes rebuilds fast).
- After a RUNTIME UPDATE (the v79 case) → clean is mandatory + delete
  the stale runtime folder (ProgramData runtimes are NOT touched by
  the broom — two different caches!).
- VM↔YYC switch on Android, arch toggles (armv7/arm64), SDK/NDK/JDK
  or extension changes → not required, but "if the next build errors
  or the app crash-starts with no code reason, broom + rebuild once
  BEFORE suspecting your code" (cheap insurance, ~1 min).
- Windows: same relaxed rule; almost never needs it for mode switches.


### v80-next research — device identification for exclusive characters (PLAN ONLY)

Owner asked: bind exclusive characters to the DEVICE because "it's the
only thing that can't be manipulated". Verified facts before answering:

1. GameMaker os_get_info() on Android has NO "udid" key (manual LTS:
   udid exists only on Windows/macOS/Ubuntu). Our net_indentity.gml
   Android "udid" is a concat of 7 PUBLIC Build fields (MODEL, DEVICE,
   MANUFACTURER, BOOTLOADER...) => MODEL fingerprint, identical on two
   same-model phones. It is NOT a per-device identifier. PC builds DO
   send a real machine udid. Lesson: always check what an identifier
   actually contains per-platform before trusting it for auth.

2. ANDROID_ID (SSAID) facts (Android official docs): 64-bit, per-app
   (scoped by app signature) since Android 8; survives uninstall/
   reinstall; regenerates only on factory reset or signature rotation;
   spoofable on rooted devices (Magisk modules). Conclusion taught to
   owner: "device ID" is NOT unspoofable — it raises the bar a lot vs
   a shared secret phrase, but a determined rooted user can rotate it.
   For this game's threat model (friends sharing a phrase), device
   binding + phrase-as-voucher is the right cost/benefit.

3. Architecture recommended (NOT implemented): two-factor binding —
   device (ANDROID_ID via ~20-line Java extension; PC udid already
   exists) + secret phrase used ONLY to link a NEW device. Server
   stores SHA-256(android_id + MODEL + salt), never the raw ID.
   Fail-closed by design: unknown device => no unlock, no advantage.
   Anti-cheat untouched (rule 7). Reuse existing patterns: amy_authed
   bool in PeerData, server_cmd_handle for .grant/.devices/.revoke,
   Bans.json-style Config/Devices.json, opcode appended at END of both
   enums (v73/v74 golden rule).

4. Golden rules reinforced: research the platform reality before
   promising security properties ("no se puede manipular" was half
   true); every security recommendation must name the threat model it
   defends against; prefer fail-closed designs where a forged client
   gains nothing.


### v80b rev2 — owner's own design: character claim by device via chat command

The owner came back with HER design (better fitted than my v80 draft):
exclusive chars visible to ops + Amy-token holders ALWAYS, and anyone
else can type ".rouge" in chat — the FIRST device to run it registers
a claim on that character forever (survives reinstall); every other
device gets "already claimed". One device per character.

Lessons recorded:
1. Validate the owner's design against real code before approving it.
   Script check_v80b_rouge_design.py verified 10/10 integration points
   in the repo (command handler template CMD_EXE, char guards, client
   visibility function, chat flow reaching server_cmd_handle from BOTH
   Lobby and CharSelect states). The design slots into existing
   patterns with ~120 server lines + ~25 client lines.
2. Command hash: server_cmd_parse uses Java hash 31*h+c over the first
   word INCLUDING the leading dot. Verified by reproducing
   CMD_EXE ".exe" = 1471268 exactly, then computed CMD_ROUGE
   (".rouge") = 1425644872 and checked no collision with the other 18
   CMD_* defines. Always recompute and check collisions when adding a
   chat command — a collision would silently run the wrong handler.
3. State-push pattern for client visibility: SERVER_OPERATOR_STATE is
   sent on connect (and on .op) and processed in the MAIN switch of
   net_tcpprocess regardless of connection state — copy this for
   SERVER_ROUGE_STATE so the claim survives reconnects. Visibility
   function scr_char_locked() is the single client-side gate; server
   CharSelect.c keeps the authoritative mirror (double lock).
4. Owner's design kills my v80 extras (link phrase, 3-device cap,
   .grant) — simpler UX wins when the threat model is friends sharing
   a game, not APTs. Keep: Java extension for ANDROID_ID, SHA-256+
   salt storage, append-only packet bytes, fail-closed, anti-cheat
   untouched (rule 7).


### v80c — implementing the owner's device-claim design end to end

Implemented .rouge (character claimed per device via chat command).
The owner's final decision simplified my v80b plan further: claims are
removed ONLY by deleting a line in the server's Devices.txt — no op
commands, and the file must be .txt (not JSON) so she can edit it in
Notepad.

Lessons recorded:
1. Verification-first workflow paid off again: the unit test caught a
   REAL bug — include/SHA256.h used memcpy/memset with only stdint/
   stddef included. On the Windows build another header would have
   masked it; the sandbox gcc caught it. Always run new headers through
   a real compiler, not just eyeball them.
2. Writing a stub enet.h for -fsyntax-only: the struct definitions
   matter (ENetPeer needs `void *data` AND `ENetAddress address`,
   declare ENetAddress FIRST), and you need the enum flags
   (ENET_PACKET_FLAG_RELIABLE) plus enet_peer_disconnect{,_now,_later}.
   Getting the stub right turned "maybe compiles" into a conclusive
   6/6 check.
3. GameMaker .yy extension format: functions in AndroidSource Java are
   kind 4; returnType 1 = string, 2 = double (verified against the 8
   existing returnType:2 functions that all return double). A Java
   method returning String must be returnType 1 or GML gets garbage.
4. The Java wrapper class (${YYAndroidPackageName} template package)
   can call Settings.Secure via RunnerJNILib.ms_activity directly — no
   extra gradle permission needed for ANDROID_ID, and wrap it in
   try/catch returning "" so a weird device fails closed instead of
   crashing the runner.
5. Protocol append discipline held: new string field in IDENTITY goes
   BETWEEN pet and the anticheat u64s on BOTH sides in the same order,
   new packet opcode at the END of both enums, BUILD_VERSION bumped on
   both sides so mismatched pairs fail cleanly. This is the third time
   this recipe works without migration code.
6. Devices.txt reload-on-every-use (inside check/claim, under mutex)
   is what makes "delete the line in Notepad" work without restarting
   the server — that was an explicit owner requirement, and it costs
   nothing at this file size. First-line-wins on duplicate character
   entries keeps hand-edits safe.
7. Scripted mirror checks must parse the enum BLOCK, not the file tail:
   both Packet.h (typedef enum { ... } PacketType;) and net_packets.gml
   (enum PacketType { ... }) have macros/definitions after the enum, so
   endswith() on the whole file gives false negatives.

## v80h2 (2026-11-24) — Lecciones del crash "argument 1 undefined"
1. INDICE DE ARGUMENTOS: la doc oficial de errores del runner dice
   "argument (index)... where an index of 1 is the first argument".
   "argument 1" = PRIMER argumento (base 1). Antes asumi base 0 y diagnostique
   la variable equivocada (obj_config.bVX en vez de _x). VERIFICAR la base
   del indice ANTES de diagnosticar.
2. TOUCH EN ANDROID: device_mouse_x_to_gui/y_to_gui "will only be updated
   while the screen is being touched" (doc oficial). Un slot sin dedo puede
   devolver undefined. TODO uso de esas funciones debe ir detras de
   device_mouse_check_button/_pressed (el patron de los 10 botones
   originales y de obj_game_chat del propio juego).
3. DIAGNOSTICO SIN FUENTE = APUESTA: el v80h diagnostico bV2X undefined sin
   tener el script real; con el repo real (AmyRose21) resulto que obj_config
   define todo bien y la causa era otra. Regla: pedir/clonar el archivo real
   ANTES de cerrar un diagnostico de runtime.
4. json_parse Y CAMPOS FALTANTES: leer struct.campo cuando campo no existe
   devuelve undefined SIN lanzar excepcion. Los try/catch del load() del
   juego NO protegen contra 1.bson con campos faltantes. Blindar con
   is_undefined (o variable_instance_exists para instancias).
5. REPO REAL DEL USUARIO: github.com/AmyRose21/disaster2d-oss (fork con
   todos nuestros parches). upstream: teamexeempire/disaster2d-oss (v110,
   1 commit). Usar el de AmyRose como fuente de verdad y hacer fetch en
   CADA consulta (regla 1 del usuario).
6. VERIFICACION EN CADENA: cada fix se verifica (a) lint del snippet,
   (b) parche sobre el archivo REAL con la MISMA logica del PowerShell,
   (c) simulacion semantica de los casos de runtime (incluido el del bug),
   (d) idempotencia, (e) las 3 vias de aplicacion. Solo entonces se
   regenera el bat y se re-verifica el bat extraido.

## v81 (2026-11-25) — Sonic/Kris/Sally Canon device claims — lessons
1. EXTEND, DON'T INVENT: when the owner says "add the same system as X
   for characters A/B/C", the correct move is to REUSE the existing
   machinery (Devices.c unchanged — its key IS the character string)
   and only add: one command hash per character, one peer flag per
   character, guards, and ONE packet carrying all the new states.
   Zero changes to the claim registry = zero new failure modes.
2. ONE PACKET, MANY STATES: three booleans went into a single
   SERVER_CLAIM_STATE (u8 x3) instead of three packet types. The
   enum is a shared contract — every new member costs a BUILD_VERSION
   bump and an "old APK can't connect" wave, so batch related states.
3. FACTOR THE HANDLER: the 3 command cases delegate to one static
   server_cmd_claim(v, key, name, &flag). The Rouge case kept its
   original inline shape (untouched = unregressed); the new code is
   one auditable function. When "same as X" is the requirement,
   copying X three times guarantees drift; referencing X once doesn't.
4. CHECK BOTH GATES: a character unlock lives in TWO places that must
   stay mirrored — scr_char_locked (client carousel) AND the CharSelect
   guard (server, anti-edited-client). This round changed both; the
   checker asserts old operator-only guards are GONE (not just new
   ones present), because a leftover old guard would silently win.
5. THE REPO KEEPS DUPLICATE COPIES: the owner's repo tracks BOTH
   scripts/foo.gml and scripts/foo/foo.gml (root + folder), identical
   in HEAD. GameMaker only loads the folder one, but a zip that updates
   only one side leaves the repo inconsistent — ship both, byte-equal.
   (v80d taught the folder rule; v81 adds: check `git ls-files` for
   mirrors before deciding the zip's file list.)
6. VERSION BUMP IS PART OF THE PROTOCOL CHANGE: adding an enum member
   (SERVER_CLAIM_STATE) requires BUILD_VERSION/BUILD_VER 1102->1103 on
   BOTH sides; old APKs get "version mismatch" — intentional, same
   policy as v80c. The server's .ver command shows it automatically
   (STRINGIFY), no extra edit needed.

## v82 (2026-11-25) - Sally Canon cyber forms + shd_amy_cyber v3 - lessons
1. THE MEMORY LIVES IN THE REPO. After a sandbox rollback nothing under
   /home/z/my-project/ remembers the old CACHE/LEARNING/worklog, but the
   owner COMMITS them at the repo root. So: fetch first, read THOSE files
   (CACHE.md was 2771 lines, LEARNING.md 929), then append your own section
   to them and ship them as modified files. This session first wrote fresh
   ones in download/ and had to throw them away: 2.7k lines of history
   would have been replaced by one page.
2. VERSION LABELS COLLIDE BETWEEN SESSIONS. Another session shipped "v81"
   (claims for Sonic/Kris/Sally Canon) while this one was being built as
   v81 on the same base. After the fetch, check `git ls-files | grep
   LEEME_` and the tail of CACHE.md BEFORE choosing a label; relabel with a
   script that proves the old label never existed in HEAD in the touched
   files (`git grep -c <label> <base> -- <files>` must be empty).
3. FAST-FORWARD WITH A DIRTY TREE IS SAFE WHEN THE SETS DO NOT OVERLAP:
   `comm -12` of (files changed upstream) and (my modified files) came out
   empty, so `git merge --ff-only origin/main` moved HEAD and kept the 15
   edits untouched. Then re-read only what the upstream touched NEXT TO
   your hooks: v81 changed the TCP enum, BUILD_VER 1102 -> 1103 and
   scr_char_locked, but not CLIENT_PLAYER_DATA, net_udpprocess.gml or the
   relay loop in Game.c, so the 3 tail bytes were still valid.
4. A SHADER BUG THE STATIC CHECK MISSED: the fragment shader read uRectOK
   while only the vertex shader declared it -> GameMaker would have
   refused the shader. Lessons: check uniforms PER STAGE (a union of both
   texts hides it), and COMPILE the real shader. A WebGL1 harness
   (Playwright Chromium + --use-angle=swiftshader, GameMaker preamble:
   `#define MATRIX_WORLD_VIEW_PROJECTION 0` + `uniform mat4
   gm_Matrices[1];` in the vsh, `uniform sampler2D gm_BaseTexture;` in the
   fsh) found it in seconds.
5. HARNESS LESSONS (each one cost a run):
   a) the harness draws with blending OFF, so colors come out STRAIGHT,
      never premultiplied; a test that expected premultiplied output
      failed on a correct shader;
   b) the reference geometry must mirror what the draw call does: the glow
      is a SCALED silhouette, so the test has to compare against the
      scaled sprite (placed_sc), not the 1:1 one;
   c) compositing a preview over an OPAQUE background: never divide by
      the alpha (it produced black boxes, then white boxes, and the vision
      model flagged both as broken);
   d) ANGLE WebGL1 rejects `i < u_ColourCount` (non-constant loop bound;
      the line is identical to the game's shd_colour and compiles in
      GameMaker) -> harness-only substitution, and the uniform then gets
      optimized out;
   e) rotate the quad with the GameMaker convention: room = (c*ux + s*uy,
      -s*ux + c*uy) for image_angle = a; a non-rotated quad made the
      vertex-shader un-rotation disagree (445 false "dissolved" pixels).
6. VISION-MODEL FEEDBACK IS A TEST, NOT A VERDICT: "the outline is not
   clearly visible" was a real weakness (fixed with an additive rim boost
   + a stronger level-2 tint); "black boxes" was a preview-only bug.
   Separate "the shader is wrong" from "my preview is wrong" before
   touching the shader, and ask the model again after the fix.
7. THE GENERATOR IS THE SOURCE OF TRUTH OR IT GETS RESYNCED. A marker
   (`uniform float uRectOK;`) matched inside the wrong literal (the VSH)
   and silently skipped the FSH patch. Fix: resync the generator literals
   FROM the repo files, then prove it by rebuilding from the HEAD blobs
   and comparing byte-for-byte (34/34).
8. APPEND-ONLY NETWORK FIELDS: 3 tagged bytes at the tail of an existing
   UDP packet = zero server changes and no BUILD_VER bump (old and new
   clients interoperate). The receive buffer is fixed and refilled by the
   native extension, so a shorter packet leaves STALE bytes: tag the field
   twice and accept it only when both tags match.
9. SMALL THINGS THAT STILL BITE: a `#` comment dropped in the middle of a
   Python expression (my own sed) swallowed the rest of the line ->
   py_compile every tool before running it; a replacement marker must be
   unique across ALL the literals of a file, not just present once.


## v83 (2026-11-26) - Vanilla robustness + Amy Canon skill/GUI fixes + anti-cheat (base commit 2db92702)

### Hits (found by reading the code, then fixed)

1. **Remote trail of Vanilla's float run was dead code.** `objects/obj_netclient/Step_2.gml` sets the
   `PLAYER_POWERBOOST` bit while `isFloatRunning`, but `scripts/net_udpprocess/net_udpprocess.gml`
   applied the bit only when `character == CHARACTER_SONIC`. The ghost trail of
   `obj_player_puppet/Step_0.gml` (`if(powerBoost)`) never ran for a remote Vanilla. Metal and Blaze
   send the same bit and have the same dead path (not fixed here, reported).
2. **`Perfect_Parry` is not in `global.net_snds`.** `scr_parry.gml` (2 sites) sent the ally-cover "ting"
   with `net_sound_emit_at(Perfect_Parry, nid)`. The emitter writes `array_find_index(...)` as u8: not
   found = -1 = 255, and the receiver drops any `sid >= array_length(global.net_snds)`. The network
   path of the ally ting could never work. Fixed: send `snd_parry`, the sound the receiver compares against.
3. **The `// NN` comments in `scripts/net_sounds/net_sounds.gml` are off by one.** The array starts with
   `snd_none` (0) while the first comment says `snd_dash // 0`. REAL indices (counted, 126 entries):
   snd_none 0, snd_dash 1, snd_dead 2, snd_ringlose 6, snd_hurt 9, snd_exe_stun 12, snd_snap 37,
   snd_parry 107, snd_mermer 108, snd_nono 109, snd_vasebreak 110, snd_ready 111, snd_npteleport 112,
   snd_achivement 113, snd_chocola_dive 114, snd_metal_stun 118, snd_jina_kill1 120. The two hard-coded
   indices of the server (6 = ring lost, 9 = hurt) are correct.
4. **Amy Canon HUD** (`obj_playerui/Draw_64.gml`): icon 3 (C) was drawn red in the air although C in
   the air is the Light Speed Attack (same `dashTimer`), and the super hammer throw
   (`hammerThrowTimer`) had no recharge display at all. The icon now shows whichever of the two the C
   key will do; red only while cooling, or on the ground in super phase 1 where C does nothing.
5. **Amy Canon bubble** (`scr_amy_canon_bubble.gml`): the liberator contact counted `isInactive`
   puppets (puppets are never destroyed when their player leaves).
6. **Chocola** (Vanilla): GO_CREAM / GUARD only checked that the target puppet existed, so an inactive
   Cream puppet (disconnect / 1 s without data) kept Chocola hanging forever and Vanilla lost her
   passive (the 65 % block and the 33 % attack need Chocola at home). New
   `scr_chocola_target_lost()`: 60 consecutive frames of an inactive target = target lost.
7. **Weak mark** (`scr_player_hurt.gml`, `scr_weak_mark_hit`): Amy Canon's `hammerThrowTimer` and
   Vanilla's `chocolaCd` were not put on cooldown by the mark.
8. **Vanilla had no icon for the V key** (Chocola command). Added icon 4 in the C row.
9. **Server**: `CLIENT_SOUND_EMIT` relayed targeted stun signals with no validation (any client could
   send the i-frame-ignoring hammer stun to any player); `CLIENT_CREAM_SPAWN_RINGS` accepted ring byte
   2 (black rings) / 1 (red rings) from players that are neither nega nor demonized.

### Errors made in this session (do not repeat)

- `count_anims.py`: the regex used `\[\\?\s*` (optional BACKSLASH) instead of the real `?` accessor,
  so every table printed "NOT FOUND". Correct: `\[\?\s*`.
- Ran a `cmp` between `net_sounds.gml` and `net_packets/net_packets.gml` believing they were a
  loose-dup pair. They are unrelated; the real pair is `scripts/net_packets.gml` <->
  `scripts/net_packets/net_packets.gml`. Confirm a pair by NAME before comparing.
- Assumed Vanilla's V key was "the Chocola attack". It is the Chocola -> Cream / recall command; the
  close attack is automatic (33 %).
- Nearly copied the stale `// N` comments into the server rule. Rule: every index hard-coded in C
  comes from `net_snd_index.py`.
- First draft of the patcher anchored a weak-mark edit on a bare statement line that a sibling `case`
  could repeat; rewritten to locate the `case` label first and then the statement inside it. Lesson:
  anchor on the enclosing block, never on a line a sibling block can repeat.
- First draft of `check_v83.py` concatenated a generator with a list and had an unbalanced
  comprehension; both would have crashed at runtime. Lesson: re-read generated helper code for
  Python-level syntax before trusting a run.
- A strict `if\(...\)` regex anchor matched 0 lines because it forgot the closing paren of the `if`
  itself. For one-line conditions anchor on the END of the stripped line, or work line by line.

### Facts learned (verified in code)

- `scr_survivors.gml` tables: Amy Canon has 26 entries in `player_anims` / `player_eanims` /
  `player_negaanims` (states 0..25); Vanilla has 20.
- LSA gates: `!isGrounded`, C pressed, `dashTimer <= 0`, the common gates (alive, not hurt / shocked /
  zipline / dashing / tarot / HJ / attacking, no bubble, hug, parry, red ring, hiding,
  `revivalTimes < 2`) and a valid target inside `LSA_RANGE` (400) without i-frames. Up to
  `LSA_MAX_TARGETS` (6) hits per flight, one targeted `snd_dash` each; the receiver dedups with
  `shockedTimer > 0`.
- Hammer throw: super phase 2 + C on the ground; the hammer lives 240 frames; its stun ignores
  i-frames. The super form is client-local (not synced): only the hit travels (`snd_none`, targeted).
- Server flags: `PLAYER_DEMONIZED` is set by `game_demonize`, `CLIENT_JINNA_NEGATOUCH` and
  `CLIENT_JINNA_MINION` (the last two also set `PLAYER_NEGATIZED`), cleared by Vanilla's rescue and by
  `CLIENT_JINNA_MINION_DOWN`. Amy Canon, Sally Canon, Sonic, Vanilla, Rouge and Kris die directly
  (never demonized by dying), so their only "esbirro" state is the nega conversion.
- A dot read of an instance variable that the instance does not declare is a fatal error in GameMaker:
  guard with `variable_instance_exists(<id>, "name")` before reading puppet-only variables.

### How this was verified (and what could NOT be verified)

- No GameMaker IDE / runtime in the sandbox. GML: string-aware lexer (bracket balance, LF only, no
  chained ternary, macro uniqueness project-wide, symbol and asset existence), byte-exact anchor
  patching, numeric simulation of the new logic. Server C: `gcc -fsyntax-only` on the original vs the
  patched file, comparing the normalized diagnostics.
- NOT verified: in-game behaviour, a real match against a v83 server, the look of the new HUD icon
  (designed by numeric pixel measurement: 13x21 px of content at half scale next to the real V key).


## v84 (2026-11-26) - Chocola from frame 0 + Amelia auras QoL/shields + anti-cheat (base commit b3ab984d)

### Hits (found by reading the code, then implemented)

1. **Chocola only existed after Vanilla's first knockdown.** The 65% block and the 33% close
   attack (both require Chocola at home) were dead for the whole early game. v84: she is born
   in `obj_vanilla/Create_0` (local) and in `net_udpprocess` `CLIENT_PLAYER_DATA` (remote, at
   the puppet's live position). The net guard doubles as a SELF-HEAL: Chocola self-destructs
   when her home has no data for 1 s, and the guard re-creates her the moment data returns.
2. **The paciencia hunt is now dead code by design** (owner's order: with Chocola out the
   paciencia is the gesture only). `snd_mermer` is no longer emitted by `scr_vanilla_v2_step`;
   `CHOCOLA_NET_HUNT` handling and `scr_vanilla_paciencia_chocola_hit/_fail` stay for old
   v83 clients. Server keeps 109 legal from Vanilla (capped at 10 s) so v83 clients still work.
3. **Aura cap could evict the real EXE.** The sensor loop stopped at 16 entities in
   instance-creation order; with 16+ demonized puppets the exe (usually the OLDEST puppet,
   created first) was the one dropped... in fact creation order makes the exe FIRST, so the
   real risk was the opposite: any future re-ordering. The two-pass scan (exe first) makes
   the invariant explicit and permanent.
4. **Off-screen auras were invisible** (350 px radius vs a 480x270 view: most detections are
   off-screen!). v84 draws a small triangle marker clamped to the screen edge pointing at the
   aura; alpha of the marker is NOT scaled by the reach-edge fade (a distant-but-detected
   entity is exactly the thing to show).
5. **Auras popped in/out at the reach edge** (`_k` floored at 0.3 inside, 0 outside): now a
   smoothstep over the last 12% of the radius.
6. **Cold reading** (QoL): a stunned/downed exe (`EXE_SHOCKED`/`EXE_LOST`) or a downed minion
   (`DEAD`) draws blue with no pulse - "neutralized" at a glance.
7. **METAL/BLAZE remote ghost trail was dead code** (the powerBoost bit was never applied to
   their puppets) - v83 had reported it; v84 applies it (4 characters total now).
8. **Server: 109/110 had no emitter-character rule and no rate limit.** With Chocola alive
   from frame 0, a hacked Vanilla could spam 2.5 s self-stuns on the exe nonstop. Rules added:
   109 = Vanilla only, 110 = Vanilla or Cream, Vanilla's 110 capped at 2 s (< the legit 2.5 s
   shared chocolaCd + travel time, so a healthy client is NEVER clipped), 109 capped at 10 s.

### Errors made in this session (do not repeat)

- The sandbox was RECYCLED mid-task: `/home/z/my-project/work/disaster2d-oss` came back EMPTY
  (other dirs survived). Re-cloned and re-fetched; HEAD/origin were still b3ab984d. Lesson:
  re-check the workspace tree at the start of every continuation, not only the summary.
- First patcher run aborted: `obj_vanilla/Create_0.gml` has NO final newline (net_udpprocess
  and net_state_game too). Keep each file's own final-newline convention; do not "normalize".
- check_v84.py had 4 self-inflicted FAILs: a wrong `pacienciaTimer--` count (2, not 3), a
  wrong gate count (4 including the pre-existing creamring gate, not 3), a hard "ends with
  newline" rule (must compare against the HEAD convention instead), and a broken simulation
  clause (`inactive_at not in packets` contradicted the model). Fix the CHECK, not the patch,
  when the diff is provably right.
- gcc without `-Wall` printed 0 warnings and made the "45 pre-existing warnings" baseline
  unreproducible: always use the same flags as the saved baseline (`-std=gnu11 -Wall
  -fsyntax-only` + the enet include order).
- A `grep -cF` loop with `||` inside the pattern needs no escaping for -F but the shell needs
  the pattern quoted; one anchor printed 0 for a quoting artifact, not because the line was
  missing. Always re-verify a 0-count by reading the file region.

### Facts learned (verified in code)

- exe state macros live in `objects/obj_exe/Step_2.gml`: `EXE_SHOCKED = BALANCING+3` (16),
  `EXE_LOST = BALANCING+5` (18), `BALANCING = 13` (scr_survivors). A stunned exe ON THE
  GROUND is `EXE_SHOCKED`; in the AIR it is `HURT`; defeated is `EXE_LOST`.
- `global.player.id` is the id of the FIRST instance of the player object (dot-read on an
  object index resolves instance variables): the correct argument for
  `variable_instance_exists` (pattern used at scr_amy_cyber L450).
- The mini-embestida stun signal is TARGETED `snd_vasebreak` (110) — 2.5 s exe / 3.5 s minion
  (the RECEIVER decides); the big paciencia hunt was TARGETED `snd_nono` (109), 5 s.
  `scr_chocola_stun_signal` also broadcasts `snd_exe_stun` (12) so everyone hears the hit.
- Chocola's V key only needs `instance_exists(obj_chocola)` + mode FOLLOW/GO_CREAM/GUARD, so
  it works unchanged with Chocola born at frame 0. The v83 HUD icon colours too.
- Legit interval between two 110 signals from Vanilla >= chocolaCd (150 f) + flight +
  ATTACK_PAUSE (26 f) + RETURN flight ~ 190 frames > the 120-frame server cap. Verified by
  simulation in check_v84.py.

### How this was verified (and what could NOT be verified)

- No GameMaker IDE / runtime in the sandbox. GML: string-aware lexer (bracket balance, LF
  only, final-newline convention kept, no new chained ternary vs HEAD, macro uniqueness
  project-wide, symbol/asset existence), byte-exact atomic patching, numeric simulations
  (paciencia clock, Chocola birth/self-heal, two-pass cap, smoothstep fade, marker triangle,
  server rule table + rate limits). Server C: `gcc -std=gnu11 -Wall -fsyntax-only` with the
  real upstream enet headers: HEAD = 0 errors / 45 pre-existing warnings; patched = 0 errors /
  the same 45 warnings, zero new diagnostics. Roundtrip: fresh clone of HEAD + the v84 zip is
  byte-identical to the patched tree and the validator passes inside it.
- NOT verified: in-game behaviour, a real match (local or networked), the look of the new aura
  markers/fade/flash, and the recompiled server actually running. No GameMaker exists here.


## v85 (2026-11-26) - Sally Canon ground kick from phase 1 (base commit b3ab984d)

### Hits

1. **The whole "phase 2 only" rule was one token.** `scr_sally_special`'s ground-kick branch
   read `else if(global.character == CHARACTER_SALLY_CANON && duelista && ...)`: removing
   `&& duelista` is the entire functional change. Everything else (victim-side effect,
   anim tables for state 22 in BOTH player and puppet tables, Draw_76 case, shared 15 s
   recharge, HUD icon) was already phase-blind. Verified BEFORE designing: reading the
   consumer code first turned a "maybe need state plumbing" fear into a one-line patch.
2. **Trust model confirmed again:** the ground kick's damage/stun/TP runs on the VICTIM's
   client keyed on `state == 22` + synced `image_index` windows; the launcher only
   broadcasts `snd_dash` (not even a stun signal index). So no server-side rule applies and
   none was needed (the duelista bit was never server-validated anyway).
3. **v84-not-pushed packaging strategy:** when origin still sits on the previous version,
   re-apply the prior patch locally (patchers are deterministic), build the new version on
   top, and zip ONLY the new version's files. House docs (CACHE/LEARNING/worklog) then
   carry both versions and must be applied in order; code files that don't overlap apply in
   either order (verified with a second roundtrip without the old zip).
4. The sandbox can be recycled BETWEEN user messages too (not just mid-session): this time
   the whole clone directory was gone. Re-clone, fetch, and re-check HEAD before anything.

### Errors made (do not repeat)

- check_v85 first run had 2 self-inflicted FAILs: (a) `groundKick = false;` counted once —
  it appears TWICE in scr_sally_special (auto-off at the top + the air-kick branch); (b) a
  naive "no duelista in the kick window" string search matched the word inside a COMMENT
  ("la patada duelista..."). Rule: for content assertions about CODE, strip comments first
  (reuse `strip_gml`), and always re-count identifiers across the whole file before
  asserting an exact occurrence count.

### Facts learned (verified in code)

- Sally Canon states: 18-21 = fase2 pt1..pt4, 22 = ground kick, 23 = spindash charge
  (`BALANCING+9/+10`); anim tables have 24+ entries per character; state 22 exists in the
  player AND puppet tables.
- Sally Canon NEVER demonizes (server patch, like Amy Canon): 2nd knockdown kills her
  outright, so the ground kick can never be used by an esbirro Canon (vanilla Sally
  esbirros exist, but the kick gate requires CHARACTER_SALLY_CANON).
- The kick's window constants live in scr_sally_canon_fase2 (`KICK1_END 6`,
  `KICK2_START 7`); the victim-side block also guards the invisible-exe case (return above
  it) and only runs for `!isDemonized && globalExe` puppets.
- Legit interval between kicks = `attackTimer` 15 s (900 frames), shared by air and ground
  kick; esbirro 4 s (`SALLY_EATTACK_RECHARGE`).


## v86 (2026-11-26) - Sally Canon unified pads + exit radar (base commit b3ab984d)

### Hits

1. **Reuse the owner's own precedent instead of inventing.** Rouge's v25 "RADAR DE LA SALIDA" is a
   character-local, zero-network, inline-in-Draw-GUI green arrow — exactly what "la flecha que tiene amy
   canon para saber donde esta la salida" means for Sally Canon. Copying THAT (same sprite, guard, anchor,
   rotation) beat spawning `obj_amycanon_indicators` (would need a .yy or a Create_0 hook) and beat writing
   a new indicators object. The red exe arrow stays exclusive, exactly as Rouge's request established.
2. **Unifying the pads was deleting a ternary.** The victim-side pad line was the ONLY phase-dependent
   piece (`duelista ? F2_AIR : F1`); renaming the macros (`_F2_GROUND`->`_GROUND`, `_F2_AIR`->`_AIR`,
   delete `_F1`) keeps comments truthful and grep-able. `grep -rn` for the old names must return nothing
   — that is the whole migration.
3. **Per-file idempotent patchers pay off.** Making each file's edit skip itself when its v86 marker is
   present allowed a surgical repair: `git checkout -- <file>` + re-run patched ONLY the broken file.
4. Patchers should skip re-creating an existing backup zip (the first run's backup is the correct
   pre-patch state; a re-run's would be post-patch and useless for rollback).

### Errors made (do not repeat)

1. **THE BIG ONE — a real brace-cut bug in the patcher.** Appending a block to a file whose tail ends in
   `}`, I "reconstructed" it as `t[:-len(tail)] + tail[:-1] + "\n" + BLOCK` — `tail[:-1]` silently DROPPED
   the cyber block's closing `}` and left a `{` unclosed: GML would not compile. The v86 validator's
   bracket check caught it (4 `{` vs 3 `}`) BEFORE any delivery. Rules: (a) when appending after an exact
   tail, just `t + BLOCK` — never slice the tail by hand; (b) run the lexer check IMMEDIATELY after the
   first patch application, not only at the end; (c) count braces in the post-conditions of the PATCHER
   itself, not only in the validator.
2. **Assumed `.gml` files end with a newline — `obj_player_puppet/Step_0.gml` does NOT** (nor does
   `obj_sally_canon/Draw_64.gml`). Post-conditions must compare the convention with `git show HEAD:`
   (v85 already did this in the validator; the v86 patcher initially demanded `endswith("\n")` and
   false-alarmed).
3. **False assertion: "no instance_create_depth in Create_0".** Her Create legitimately spawns sensors and
   the revive puppet. Assert only the SPECIFIC danger (`obj_amycanon_indicators` not spawned), never a
   generic API name that the file already used before the patch.
4. Minor: `grep "A\|B"` inside a Python string -> SyntaxWarning; use `["-e", "A", "-e", "B"]`.

### Facts learned (verified in code)

- Rouge's radar (v25) and the amycanon indicators use `spr_sindicator2` (green, 32x16-ish game sprite);
  the red exe arrow is `spr_indicator`; both anchored at the player body, drawn in Draw GUI with
  `ceil(x - obj_camera.x)` coordinates (this project draws GUI-space HUD with manual camera subtraction).
- `obj_bigring` = the escape ring; the vanilla game's own `obj_surv_ringindicator` only exists in ravinemist
  and needs 6 shards — that is why Amy Canon (and now Rouge/vanilla/Sally Canon) get a personal sensor.
- Draw_64 (Draw GUI) events run even when the instance is invisible — that is why the radar works while
  hidden (Rouge's comment says the same).
- The esbirro (demonized) players keep `revivalTimes >= 2` and the game gives them the standard
  `obj_demon_indicator`; every personal-sensor object turns itself off at `revivalTimes >= 2` to not
  duplicate it.


## v87 — Amelia auras VISUAL rework (2026-11-26, base 752f5bd2 = origin/main WITH v84-v86)

Request: "QoL amelia rediseño de su sistema de auras (esto es solo visual), rework visual."
Outcome: draw-only layered signature (dome / sonar waves / reticle / core / 2-layer
silhouette / entry ping / double chevron + proximity pips). Step_0 sensing is
byte-identical; Create_0 comments-only; +19 AMELIA_AURA_* visual macros.

### What worked (keep doing)

1. **"Draw-only" is provable, not promised.** The validator asserts `git show HEAD:Step_0.gml`
   == working file (byte-exact) and Create_0 code (comments stripped, blank lines dropped)
   == HEAD. That turns the owner's "solo visual" requirement into two hard checks.
2. **A full symbol table beats eyeballing GML.** Collecting every identifier of the new
   Draw_64 (locals via `var`, instance fields from Create_0, every project #macro, a builtin
   whitelist) and failing on ANY unknown caught typos the bracket check cannot.
3. **A PIL mock that mirrors the formulas 1:1 is cheap visual QA** when no GameMaker exists:
   render dome/waves/reticle/chevron/pips with the exact constants, then probe pixel regions
   numerically (hot-pixel share per signature, chevron extent, pip column groups).
4. **Per-entity stable randomness without state: `id mod PRIME`.** auraId is already written
   by Step_0; `(auraId mod 59)/59` gives 59 distinct phases in [0,1) that survive every frame.
   No new instance variables needed for desynchronised animation.

### Errors made (do not repeat)

1. **The mock caught a real overlap before delivery:** proximity pips at 8/13/18 px from the
   anchor landed ON TOP of the chevron tail (which reaches 1.1*11*1.4 ≈ 17 px inward).
   Fix: start the pips beyond the tail (PIP_0 22) + add the invariant `PIP_0 > 1.1*POINTER*
   POINTER_EXE` to the validator. Pixel-probing the mock is what exposed it.
2. **Python float traps in my OWN sims:** `0.10+0.05 > 0.15` (epsilon must go on ONE side of
   a chained comparison, adding it to both sides cancels nothing) and `0.55*14 != 7.7`
   (compare with tolerance, never ==). Also once wrote the assertion backwards
   (`-1e-9 <= -0.25*fd` is always false — the back apex IS negative along the axis; the
   correct property is `back < front`).
3. **Simulated directions must be geometrically possible.** "All 24 dirs at every corner
   anchor" includes dirs a real edge marker can never have (dir always points from the
   on-screen Amelia outwards through the anchor). Use realistic dirs (center -> anchor
   ±30 deg) for on-screen bounds, and invariants (tip offset 0.6*POINTER*POINTER_EXE =
   9.24 < EDGE-2) for the impossible-to-violate cases.

### Facts learned (verified in code)

- `draw_line_width(x1,y1,x2,y2,w)` is already used by `scr_powerboost_fx` — safe vocabulary
  for this project's GML style (no one had used it in an event before v87).
- GameMaker constants: `noone` == -4, so `auraId` (a real instance id > 0) is always safe to
  feed `mod`; still guard `== noone || < 0` in case a stale slot slips through.
- The GML event locals are function-scope in practice, so reusing `var w` / `var t` loop
  counters inside the same event is fine (v87 does; the lexer still balances).
- The v84 auras object draws GUI-space with `ceil(x - obj_camera.x)` and silhouettes at
  `floor()` puppet coords; the -6 px vertical offset (body center vs feet) is canon.


## v88 — HOTFIX: «DoMod :2: Malformed variable» in the auras Draw (2026-11-27, base 057d0d92)

Request: user ran the v87 zip in their game and hit the exact report:
`DoMod :2: Malformed variable at gml_Object_obj_amelia_auras_Draw_64 (line 84) -
var _seed = (_eid mod AMELIA_AURA_SEED) / AMELIA_AURA_SEED;` (crash on the first
aura signature drawn).
Outcome: 1-file hotfix in Draw_64 — the per-signature phase is now computed in
tiers (real / int64 / leading digits of string(handle) / slot fallback) so NO
runtime state can ever feed a non-real to an arithmetic op. 745-check verifier.

### Root cause (this is the lesson, keep it forever)

1. Runtime 2023.8.0 ("Assets And Data Structures Now Use Typed References"):
   INSTANCES (and objects/sprites/ds/*) use TYPE-SPECIFIC HANDLES, not integer
   indices. `is_handle()` was added then; `..._exists()` functions accept any
   reference. This project's `.yyp` MetaData says `IDEVersion 2026.1.0.27`, so
   the user's runtime is deep in the handle era: `inst.id` is NOT a VM real.
2. The VM's arithmetic ops (DoAdd/DoMul/DoMod/...) only accept reals (strings
   only for concat); anything else falls into the default branch that throws
   «DoX :N: Malformed variable». Comparisons and dot-access stay permissive.
3. v87 introduced the FIRST instance-id arithmetic in the whole project
   (`id mod 59`) — that is why v84/v2.12 never crashed on their sensors and why
   exactly one line of v87 did. `AMELIA_AURA_SEED` being a macro literal, the
   malformed operand could only be `_eid` (a stored `inst.id`/`cl.id`).
4. My sandbox verification could not catch it: there is no GameMaker here, and
   static analysis assumes `id` is a real (true for runtimes < 2023.8 only).

### Evidence chain that nailed it (reuse this method)

- The crash fires at line 84, NOT at line 81 (`_eid < 0` on the same handle) and
  not at line 62 (`ceil(auraX[i] - _cx)`): so comparisons on handles pass, the
  macro resolved (else the v4.7-style "not set before reading it" error would
  appear instead — precedent inside LEARNING), and the other 8 arrays are fine.
  Only the one value the sensor stores raw (`inst.id`) can be the bad operand.
- `git diff origin/main` proved the user runs exactly the shipped v87 (they
  committed the zip as "ewe"), and the zip is byte-identical to the repo tree.
- The repo has zero other `.id`-in-arithmetic usages; the house always passes
  ids to `instance_exists` / `variable_instance_exists` / dot-access — all safe
  under typed handles.

### What worked (keep doing)

1. **Treating the crash line as a truth table.** Every line BEFORE the crash
   empirically works on the user's runtime; that eliminated whole bug families
   (stale caches, missing macros, unknown variables) in seconds.
2. **Tiered normalization instead of a single "int64 cast".** The fix handles
   real, int64, handle (digits of its string, cut at the first non-digit so a
   variable dump can never leak changing values), and everything else via a
   slot-based fallback — crash-free on every GM runtime, and the v87 promise
   (two signatures never pulse in unison) survives in all tiers.
3. **Re-running the full verifier after every edit** caught my own Python
   transcription bug (I broke on the '9' digit: GML's `_d > 57` does NOT break
   on 57 — the model now mirrors the GML condition 1:1).

### Errors made (do not repeat)

1. **v87 assumed "noone == -4, so auraId (a real instance id > 0) is always
   safe to feed mod" (previous LEARNING entry). WRONG on runtimes 2023.8+**:
   ids are typed handles there. Corrected in the v88 rule below; treat that
   v87 "fact" as superseded.
2. My first Python model of the digit fold used `not (d < 57)` where the GML
   says `d > 57` — it broke on the digit '9' (= 57). When transcribing GML
   conditions 1:1, do not "simplify" them.

### Facts learned (verified in docs/code)

- NEW CODEBASE RULE: never use an instance id / object index / asset reference
  in arithmetic (`+ - * / mod`). Safe with handles: comparisons, dot access,
  passing to `instance_exists`/`variable_instance_exists`/`instance_find`,
  storing in vars/arrays, `with`. For a numeric seed from an id: fold the
  LEADING DIGITS of `string(id)` (see the v88 `_seed` block in
  `obj_amelia_auras/Draw_64.gml`).
- `is_handle()` exists since runtime 2023.8; `is_int64()` since 2022.3; the
  project's IDEVersion (2026.1) guarantees both compile. Check the `.yyp`
  MetaData IDEVersion before using runtime-era functions.
- The runner's Do* error suffix «:N:» does NOT reliably map to source operand
  order — do not use it to pick the culprit operand; eliminate by type instead
  (a macro literal cannot be malformed, a stored id can).
- The user's workflow: they commit our delivered zips to origin/main themselves
  (v87 arrived as commit "ewe"); after `git reset origin/main` the local working
  tree diff shows exactly the new hotfix — do that before scoping any patch.

## v89 — Jinna + the Angel Island vines: stuck in the grab pose, lianas forever unusable (2026-11-27, base 273d5d01)

Request: user reported that in HideAndSeek (room_angelisland — the AIZ vines map), when
Jinna grabs the lianas (the ziplines that carry you side to side) she stays in the grab
pose and can never use that grab again.
Outcome: 1-file fix in `objects/obj_jinna/Step_2.gml` — the standard family zipline block
that all 22 other characters have. 391-check verifier + fuzz + template-parity run.

### Root cause (the lesson, keep forever)

1. **The "lianas" are `obj_aiz_zipline`** (the Angel Island ziplines, sprite
   `spr_aiz_liana`; `HideAndSeek` in `scr_globals.gml` maps to `room_angelisland` — that
   is why the bug "lives" in Hide&Seek: it is the vines map, not a mode-specific code
   path).
2. **Cross-object flag lifecycle:** `_holdPlayer()` (defined in the zipline's Create_0,
   called from its Step_2 AND Step_0 AND Draw_72 AND Draw_76) sets
   `global.player.isZipline = true` while the player rides. The zipline clears that flag
   ITSELF only on jump-release or death — **when the ride ends naturally
   (`progress -> 1`), the flag stays ON**. Every character therefore self-clears it in
   its own Step_2 on landing:
   `if(isZipline){ if(isGrounded) isZipline = false; else { state = XXX_ZIPLINE; return; } }`.
3. **Family invariant violated by one member:** an automated sweep of all 23
   `objects/obj_*/Step_2.gml` proved Jinna was the ONLY character without that block;
   her only handling was a dead tail `else if(isZipline) state = JINNA_ZIPLINE;`
   reachable ONLY while standing still ON THE GROUND. Two symptoms from one missing
   block: (a) idle-on-ground fell into JINNA_ZIPLINE (slot 19, `spr_jinna_zipline` =
   the vine-grab pose the user saw); (b) the zipline re-grab guard
   `if(global.player.isZipline) return;` (added with CARRY v2) refused her forever —
   "no puede usar otra vez ese agarre".
4. **Half-implemented feature smell:** slot 19 already existed in `scr_exe.gml`, and
   `Draw_76` already had `case JINNA_ZIPLINE:` (image_speed=0). When a sprite slot +
   draw case exist but no Step_2 block, suspect a forgotten template block.

### What worked (keep doing)

1. **Character-family invariant sweeps.** A one-line shell loop over every
   `objects/obj_*/Step_2.gml` checking for the reset pattern instantly identified both
   the bug and its uniqueness (22 OK / 1 missing). Do this BEFORE designing a fix.
2. **Executing the real GML with a mini-interpreter** (check_v89.py parses and runs the
   ACTUAL Step_2 file — and, via `git show origin/main:...`, the OLD file too). The old
   file reproduces both reported symptoms; the new file produces the exact expected
   frame sequences. This is far stronger than eyeballing a diff.
3. **Template parity runs:** executing the REAL `obj_metalamy/Step_2.gml` (Jinna's
   stated template) through the same interpreter and comparing state sequences
   end-to-end ([19,19,19,(idle,flag 0),idle] in both).
4. **Testing the never-broken path too** (jump-release): asserts the fix adds no
   regression where the old code was already correct.

### Facts learned (verified in docs/code)

- NEW RULE WHEN ADDING A CHARACTER: copy ALL standard template blocks into the new
  Step_2 (zipline included — it is the one everyone forgets). `check_v89.py`'s family
  sweep can be re-run after any future character addition.
- `global.character` does NOT distinguish EXE variants: playing Jinna means
  `global.character == CHARACTER_EXE` (0) + `global.exeCharacter == EXE_JINNA`
  (`player_getexe(5)` spawns `obj_jinna`). The zipline's `switch(global.character)`
  therefore needs NO Jinna case (`case CHARACTER_EXE`, y+22, already covers her).
- `state` travels as `buffer_u8`, so any state up to 255 is network-safe; Jinna's
  JINNA_ZIPLINE (19) is the same slot value Metalamy has always sent — zero anti-cheat
  surface (verified: Step_2 touches no packets/buffers).
- scr_carry also sets `isZipline = true` for a passenger hanging from a flying
  Tails/Cream, but `scr_carry_end` clears it explicitly — carry was never affected;
  with v89, Jinna also renders the hang pose while carried (consistent with everyone).
- `obj_aiz_zipline` calls `_holdPlayer()` from Step_0 AND Draw_72 AND Draw_76 while
  holding (three times per frame) — any future change to that function must stay
  idempotent per frame.

## 2026-11-27 — v90 QoL Sonic: parry fixes + stability + strength (owner request «QoL sonic Arreglos a su parry Y mejora de estabilidad y fortalezas»)

### Bugs found (each one a lesson)

1. **NEVER read instance data through an OBJECT INDEX inside a `with` loop over
   that same object.** `scr_parry_detect`'s laser-vs-ally branch did
   `scr_parry_bbox_overlap(self, obj_tails_projectile)` inside
   `with(obj_tails_projectile){ with(obj_player_puppet){ ... } }`: GameMaker
   resolves `obj.bbox_*` with ONE instance of the object (the first it finds),
   not the one the outer `with` is iterating — with 2+ lasers in flight it
   read the wrong laser, the deflect packet was never sent, and the laser kept
   flying. Correct spelling inside a nested `with`: use **`other`** (= the
   enclosing with's instance). This is the same object-index-semantics trap as
   the v88 house rule; extend that rule: object indices are for `with`,
   instance_find and filters — never for member reads in a loop that already
   holds the instance.
2. **`audio_play_sound(snd, priority, loop)`** — argument ORDER matters.
   `audio_play_sound(Perfect_Parry, false, 0)` "worked" only because false→0
   and 0→false. It survived months because both swapped values happened to be
   the zero-value of the right type. Grep for the pattern
   `audio_play_sound\([^,]+,\s*(false|true)\s*,` to find latent swaps.
3. **Input gates for survivor abilities MUST gate `revivalTimes < 2`.**
   Demonized esbirros (and nega subditos — the conversion sets
   `revivalTimes = 2` too) KEEP player control. Sonic's parry gate didn't
   check it, so an esbirro Sonic could open the parry window: state 61
   traveled and every client drew the aura circle around the esbirro — a
   FAKE aura that protects nobody (all protection checks filter
   `isDemonized`) and baits allies into huddling next to an enemy. Same fix
   shape as other survivor gates: block it at the input, cancel it on
   conversion, and filter defensively at every draw site that renders from
   the network state byte (obj_player_puppet/Draw_0). Do NOT filter the
   pose block in Draw_72 the same way: falling through to the anim array
   with a 60+ state would index out of bounds — the aura block is standalone
   (safe to filter), the pose block is not.
4. **A damage pipeline can kill a defense WITHOUT dealing damage.** The
   survivors' ball-bounce (`scr_player_hurt(0, ..., snd_buble, ..., true,
   true)`, damage 0) never touched the parry negation (it required
   `damage > 0`) but the hurttime guard happily applied the ignore-knockback
   (`isGrounded = false`), and the NEXT frame scr_parry_step canceled the
   window with the full 14 s fail CD — an EXE-side contact that
   scr_parry_detect already treats as an attack (JUMP/SPIN) was punishing the
   parry instead of being parried. Lesson: when a defense claims to intercept
   "attacks from side X", audit EVERY pipeline exit that mutates the
   defender's state (knockback paths with damage==0 included), and make the
   negation run BEFORE the guards that mutate state, not after them.
   Moving the negation above the hurttime guard also made i-frame coverage
   consistent (the attacker-side ting/stun paths from v3.4 already existed;
   both sides deduplicate through `shockedTimer` + the 200 ms FX throttles).
5. **Every survivor's ball-contact bounce call must carry `exeSource=true`.**
   Amy Canon's tarot-float bounce was the only one without it — with a
   Sonic's aura covering her, that contact was never negated. A grep over
   `scr_player_hurt(` calls sorted by arg pattern found it. When adding a new
   survivor contact branch, copy the full 7-arg pattern
   `(..., snd_buble|snd_hurt, blood, ignore, true)`.

### What worked (keep doing)

1. **Differential fuzz with the OLD file as oracle:** check_v90.py runs 2000
   random input sequences through BOTH the old and the new scr_parry_step
   (old AST evaluated with the NEW macro values, so intended numeric buffs
   don't count as regressions — only structural changes do). Benign
   sequences (no demonize, no air taps) must produce byte-identical final
   states. This caught nothing broken but PROVES the refactor changed only
   what it claims to change.
2. **Mini-interpreter of the real patched GML** (same technique as v89, now
   with expression parser + macro evaluation): the landing buffer, demonized
   gate, cancel-on-conversion, PB cooldowns and Amy's V+Up toggle guard are
   all verified on the REAL file text, not on a re-implementation. Interpreter
   gotchas that cost time this session: tokenize multi-char operators
   INCLUDING `--`/`++` (or `x--` parses as two `-` and statements silently
   become NOPs), never merge punctuation runs (`(!` / `)))`), and make
   bare `return;` propagate out of nested blocks with a sentinel object
   (returning None is ambiguous with "no return executed").
3. **Testing the GM semantics of the bug itself:** the laser fix can't be
   executed without GameMaker, so the checker MODELS the documented GM
   behavior (object-index member read = first instance found) and proves
   old=miss / new=hit with a 2-laser scenario. When the engine can't run,
   simulate its documented semantics and test both files against it.
4. **The CD-countdown-aware assertion:** cooldowns tick down the frame they
   are applied, so exact-equality assertions on `parryCooldown` are brittle;
   assert ranges (applied and not wiped) instead, and verify the exact macro
   values separately.

### Facts learned (verified in code)

- Numbers after v90: window 50f, grace 6f (was 4), aura 64 px (was 58),
  attacker stun 4 s (was 3.5; LMS 6 s), fail CD 12 s (was 14), success CD
  7 s, PB 10/2 s, landing buffer 8f, windup 1f, success anim 22f.
- The parry negation now lives in scr_player_hurt BEFORE the hurttime guard
  and the block passives (FW tower / LMS block), with condition
  `exeSource && (damage > 0 || sndid == snd_buble)`; the tombstone comment
  marks its old spot. Immune-to-everything early returns (bubble, nervios,
  slide, invis...) still return BEFORE the negation — unchanged.
- `parryLandBuffer` lives in the 3 Create_0s (sonic/amy_canon/kris), is
  consumed or expires in scr_parry_step, and is reset by Amy Canon's kidnap
  bubble. Any future parry character needs the declaration.
- `scr_parry_detect`'s attacker predicate (`isAttacking || state == JUMP ||
  state == SPIN`) IS the definition of "EXE-side attack" for the parry; the
  negation condition in scr_player_hurt now matches it for the damage-0
  bounce case via the `snd_buble` marker.
- `SONIC_PARRY_LASER_MAXDMG` (4) is consumed by net_state_game.gml (the
  deflect receiver caps the reflected laser's damage) — near-miss during
  editing: it was accidentally clobbered and immediately restored; the
  checker now asserts it stays 4 (S2/S4.D).
- Kris's directional front check `scr_kris_block_front(kris, kris)` on
  self-object exeSource calls is degenerate (dx = 0) but PASSES because
  KRIS_BLOCK_VISION = -8 (0 >= -8): the shield still blocks when the
  attacker instance isn't reachable from the call site. Documented quirk,
  not fixed (no user report; changing it would alter hit-vs-block feel).

### Pass 2 (owner request «2 pasada para verificar errores») — independent re-verification from a fresh clone

Fresh clone + re-extracted ZIP, zero knowledge reuse: every one of the 7 files
re-diffed against upstream, plus a NEW checker (check_v90_pass2.py) and a NEW
state-machine simulation (sim_v90_parry_machine.py + sim_v90_parry_buffer.py,
9 scenarios). Result: PASS, zero code changes needed. Lessons from the pass:

1. **Static-checker false alarms come in 3 flavors on this repo — triage before
   believing a FAIL.** (a) `PacketType.CLIENT_XXX` looks like an undefined
   CONST_NAME to a regex but is an ENUM MEMBER (net_packets.gml) — a checker
   must harvest enum members, not just `#macro`s; (b) the fix comments NAME the
   old broken pattern (`obj_tails_projectile.bbox_*` appears INSIDE the
   comments that document the fix) — grep the comment-stripped code, not the
   raw text; (c) GameMaker `.yyp` files legitimately contain trailing commas
   (`"targets":-1,}`) — strict `json.load` rejects them but the IDE reads them
   fine; validate with a JSON5-tolerant parse (strip `,\s*[}\]]`) or, better,
   verify `git status --porcelain` is clean (the ZIP must never touch .yy).
2. **Re-deriving the network architecture from scratch found nothing to fix
   but is worth the time once per system.** Confirmed by reading code only:
   each client simulates ONLY its own character object + everyone else as
   obj_player_puppet; `global.player` = the local character (object index at
   charselect, first-instance dot access after spawn — hence the v88 house
   rule). The ball-bounce that killed the parry runs on the VICTIM's client
   from the 10 survivor objects' own contact blocks
   (`scr_player_hurt(0, ..., snd_buble, ..., true, true)` — exeSource=true),
   while the EXE's own bounce (obj_exe/obj_exetior/obj_exeller/obj_metalamy/
   obj_chaos/obj_jinna Step) calls with exeSource=false (default) — the parry
   negation correctly ignores the exe's self-bounce. The tarot-float bounce
   (obj_amy_canon) was the 11th survivor bounce and the only one missing
   exeSource — that asymmetry is exactly how the grep for "full 7-arg pattern"
   caught it in pass 1.
3. **`other` inside nested `with`s: verified semantics one more time.** In
   `with(laser){ with(puppet){ scr_parry_bbox_overlap(self, other) } }`:
   `self` = puppet, `other` = the laser (the enclosing with's instance), and
   AABB overlap is symmetric so argument order carries no risk. The function
   ALSO pre-declares `var _me = self;` at the top — the v88 `_eid` lesson
   (declare before use inside nested scopes) is baked in and survives review.
4. **Frame-order audit of the landing buffer:** scr_parry_step decrements
   `parryLandBuffer` in the timers block ABOVE the input block, so a tap
   buffered on frame N is consumable on frames N+1..N+8 (8 real frames of
   landing window), the input gate re-evaluates EVERYTHING at the landing
   frame (cooldown, demonized, hurt, bounceTimer, Amy's V+Up guard), and the
   buffer is zeroed on consume — no double starts (simulation: start_count==1).
   Known and accepted edge (pre-v90 semantics, unchanged): landing WITH a
   buffered start directly into an EXE ball still bounces (windup frame has no
   protection yet) and cancels the just-started parry with the fail CD —
   consistent with the grounded-tap behavior into the same contact.
5. **Verification scripts ship with the ZIP** (house convention since v89):
   check_v90.py (pass 1, 135 checks) + check_v90_pass2.py + the 2 sim files
   (pass 2). All runnable offline against the repo root.
6. **The second pass caught a real bug — in the pass-1 TOOL, not the game.**
   check_v90.py's S5 parsed `git status --porcelain` with
   `r.stdout.strip().split("\n")`: the global `.strip()` eats the leading
   space of the FIRST line, so an UNSTAGED modified first file
   (` M objects/obj_amy_canon/Create_0.gml`, alphabetically first) failed
   the `^(..)\s` parse and silently vanished from the modified list → false
   "falta por modificar". In pass 1 the 7 files were evidently STAGED
   (`M  file`, no leading space), which masked it. Lesson: never
   `.strip()` the WHOLE multi-line CLI output before line-parsing when
   lines have significant leading whitespace (git porcelain XY codes);
   strip per-line (`l.strip()` for emptiness, regex for content). Fixed in
   the shipped check_v90.py; pass-1 checker re-run after the fix: 131
   checks, ALL OK.
7. **Location-dependent verification tools bite their own authors.**
   check_v90.py anchors ROOT to ITS OWN directory
   (`dirname(__file__)`): run from outside the repo (e.g.
   `python3 ../v90check/check_v90.py .`), it inspects the wrong folder
   and fails S3/S5/S6 in confusing ways. The pass-2 re-run initially
   "failed" purely because of this. Fixed by documenting the contract in
   the script header (copy it into the project root, run it from there)
   and by making check_v90_pass2.py take the repo path as an ARGUMENT
   (and work in both pre- and post-import modes). Rule of thumb: a
   verification tool must never guess its target from its own location.

## v91 — Rouge: mode-name visibility + the passive glide respects coyote time (2026-11-27, owner request «Rouge rework a su modo cambio de habilidades... y el glide ahora respetara al tiempo de coyote ya que cuando salta se activa el glide durante ese tiempo de gracia»)

Base: origin/main 387cb916 (v89 in). The v90 (Sonic parry) was delivered as a
ZIP ONLY and touches neither obj_rouge nor scr_rouge_special — this v91
coexists with it (verified: both checkers green in the "owner project with
v90 applied uncommitted + v91 on top" scenario). Code scope: exactly 2 files
(+17 lines in scr_rouge_special.gml, one block replaced in Draw_64.gml).

### What was requested and what it actually was

1. «las palabras que salen seran mas visibles» = the v32 mode NAME under her
   HP bar (Draw_64, `draw_text_transformed_color`, fnt_big at scale 0.4,
   NO outline, resting alpha 0.55). Fixed: scale 0.6 (~11px), 8-pass 1px
   black outline with the colored name drawn LAST (on top), resting alpha
   0.9, and a smooth 0.7→0.6 scale pop during the 2s `modeFlash`
   (`0.6 + 0.1 * min(modeFlash / 12, 1)` — a uniform 12-frame landing ramp
   so the shrink has no jump cut).
2. «el glide... respetara al tiempo de coyote... cuando salta se activa el
   glide durante ese tiempo de gracia» = a REAL input-eating bug, root-caused
   to a family-parity gap (below).

### Root cause (the lesson, keep forever)

1. **Family sweeps must include members added LATER with DIFFERENT input
   semantics.** The v4.9 coyote guard (`&& !(variable_instance_exists(id,
   "coyoteTimer") && coyoteTimer > 0 && yspd >= 0))`) was added to Knuckles'
   PRESS-activated glide. Rouge's glide (v14) is HOLD-activated
   (`keyboard_check`, Z held) and was created 5 versions later WITHOUT the
   guard — she was the only glide in the family missing it, and the v4.9
   family sweep had no way to catch a member that did not exist yet.
2. **Why HOLD-based abilities break coyote specifically:** `specialFunc()`
   runs at scr_move_basic L786, BEFORE the jump block (L835). A late Z press
   during the 10-frame window: (1) the glide activation sees Z held +
   yspd > 0 → glide ON in the SAME press; (2) the jump block still fires (it
   never checks isGliding) → yspd = -6.5; (3) NEXT frame the glide-ACTIVE
   block overwrites yspd with `ROUGE_GLIDE_FALL - yAccel` → the jump lasts
   exactly ONE frame. Symptom: "cuando salta se activa el glide durante ese
   tiempo de gracia". Any hold-based passive that overwrites yspd every
   frame MUST carry the coyote guard, or it eats the grace jump.
3. **The fix is a PARITY fix, not a redesign:** the exact v4.9 string now
   appears 2× in scr_rouge_special (her fly + her glide) and 1× in
   scr_knux_special — grep-able family invariant.
4. **HUD text in this project:** the ONLY font is `fnt_big` (18px Andy
   glyphs). Scale 0.4 ≈ 7px text = unreadable. The game has no outline
   support (scr_text_spr letters are pre-outlined sprites but LOWERCASE
   only — uppercase mode names can't use it). The 8-pass 1px offset outline
   (4 cardinal + 4 diagonal, black) with the colored text drawn LAST
   (GameMaker draws later = on top) is the house technique now.

### Verification lessons (paid for, again)

1. **A section-prefix `check()` refactor made 3-arg calls VACUOUS.**
   pass-2's original `check(section, name, cond, detail)` was refactored to
   `check(*args)`; 3-arg calls (`check("P1", "name", cond)`) then bound
   cond=the NAME STRING — always truthy — so every such check passed with an
   EMPTY name ("[OK]   P1"). Symptom to watch for: **check lines whose
   printed name is just the section tag**. Fix: normalize EVERY call to
   `check(name, cond, detail="")` and re-run — which immediately exposed 4
   REAL hidden failures (guard count 1→2 because the fly guard is the SAME
   line; `_modeAlpha);` vs `_modeAlpha)`; modeFlash tick has no braces;
   "rougeMode =" matches "rougeMode =="). LESSON: after refactoring a
   checker's own check function, a full re-run is MANDATORY — vacuous
   checks hide real failures.
2. **`next()` over a failure-detail generator without a default raises
   StopIteration exactly when the check PASSES.** Compute lazily, but guard:
   `first_diff = "NONE (identical)"; if lines != expected: for...: break`.
3. **Raw-string regex over-escaping:** matching GML hex colors
   (`_modeCol = $F2A0C8`) needs `r"\$[0-9A-F]{6}"` — writing
   `r"\\\$..."` matches nothing. If a findall returns [] unexpectedly,
   print what the regex actually is.
4. **"TODO" is normal Spanish in this project** («durante TODO el
   tornado», «en TODOS los clientes») — marker scans must require the
   colon: `TODO:` / `FIXME:` / `XXX:` / `PLACEHOLDER:`.
5. **`find()` vs `rfind()` when the SAME line legitimately appears
   twice** (the family guard exists in her fly AND her glide): locating
   "the glide one" needs `rfind` (the last one), and the count itself is
   the better assertion (== 2).
6. **Byte-a-byte reconstruction is the strongest scope proof:** applying
   the expected hunks to `git show origin/main:file` and requiring the
   result to EQUAL the shipped file line-by-line proves nothing else moved
   (pass 2 rebuilt BOTH files this way). For insert-only diffs, anchor on a
   unique pre-existing line (the v24 comment «caer ya NO lo gasta») instead
   of climbing contiguous comment blocks — banners are never the top of a
   comment run.
7. **Exhaustive input sequences beat scenarios:** 256 scripted key
   sequences (all 8-input combinations × follow-ups) comparing OLD vs NEW
   traces proved EVERY behavioral difference lives in frames 0-9 (the
   coyote window) and nowhere else — a stronger statement than any single
   scenario pair.

## v92 — Jinna V grab: more range + explicit circular hitbox; electric shield stun "tipo ataque" (2026-11-27)

Request: «Mejora de la habilidad V de Jina. (mas alcance y ahora la hitbox es
circular. arreglo de la escudo electrico. que ahora podra stunear. tipo ataque
jina.. Es decir si se parte el stun le stuneara. sin importar la distancia si
detecta quien la rompio.»
Outcome: 4 code files — `scr_jinna_special.gml` (range 50→110 + JINNA_GRAB_POSE
macro), `obj_jinna/Draw_0.gml` (visible exact-hitbox ring), `scr_player_hurt.gml`
(shield-breaker detection, no distance cap), `net_state_game.gml`
(ITEMBOX_ELECTRIC_STUN 3s receptor). Pass 1: 66 OK / 0 FAIL; pass 2: 27 OK /
0 FAIL (after fixing 4 checker-self bugs — see verification lessons).

### Root cause of the "shield never stuns" (the lesson, keep forever)

1. **The v62 electric-shield zap had THREE stacked gates, each alone enough to
   eat the stun.** (a) Emitter `_zd = 64` cap: any hitbox that reaches further
   than 64px center-to-center (Jinna's post-teleport pad +35%/+75%, hammer,
   jump arcs, spindash) broke the shield with ZERO stun, forever. (b) Emitter
   filter `!_pp.isAttacking` only: jump/spindash breakers were invisible to
   the detector even at 0px. (c) Receptor gate `isAttacking || isJumping ||
   isSpinning` re-tested ATTACK-STILL-ACTIVE on ARRIVAL: with network lag the
   attack had already ended on the attacker's own client → stun lost. The
   owner's spec («si detecta quien la rompio») pins the AUTHORITY at break
   time on the VICTIM's client — the only place where exact contact exists —
   and the receptor must honor it, not re-derive it. Same pattern as Sonic's
   parry stun (v3.4/v3.5): victim detects, targeted signal, attacker self-
   applies. When a signal can be eaten by THREE gates, remove all three and
   move the proof obligation to the emitter.
2. **"Stun tipo ataque jinna" has a literal reference value:** the exe X
   attack's BASE stun is `var stunTime = 3;` (obj_player_puppet/Step_0.gml
   L927, before per-character deltas). ITEMBOX_ELECTRIC_STUN = (60 * 3) matches
   it, with the same knockback shape (xspd = -image_xscale * 3, yspd = -2,
   isGrounded = false) and the same shock particle + sound.
3. **The grab was ALREADY center-to-center circular** (`point_distance < range`
   with NO direction filter, puppet search + dummy search alike) — at 50px it
   just FELT point-blank. "Circular" was made the CONTRACT: documented at the
   macro, the SAME circle rules the practice dummy, and Draw_0 draws the exact
   circle (outer ring = literal reach border, inner ring closes during the
   pose) so what you see is what grabs. Pre-existing 1px asymmetry kept
   deliberately: puppet search strict `<`, dummy search `<=` — changing the
   dummy line would break repo-tracked `check_jinna_dummy.py`'s static pattern
   for zero gameplay value at exactly 110.0px.

### Facts learned (verified in docs/code)

- **What GameMaker compiles in this repo:** the .yyp lists ONLY GMFolder
  entries (213, zero leaf resources) — resources are discovered by their .yy.
  Compiled .gml = object events (sibling .yy), scripts/xxx/xxx.gml (folder
  .yy) and loose .gml directly under scripts/ (scr_globals.gml + 4 legacy —
  GM compiles those too). NOT compiled: `_backups_animeditor/**` (the
  SUITE_TD2D.html tool's backup dir, 200 TRACKED files, 0 references in the
  .yyp, no .yy anywhere) — whole-repo code sweeps MUST exclude it; its old
  `#macro JINNA_GRAB_RANGE 50` snapshots are correct-as-backups.
- **Repo-tracked python checkers can go stale:** `check_jinna_dummy.py` (user
  committed it in "ewe") still models range 50 and a broken sandbox path —
  do not trust its Python model after range changes; the .gml it counts is
  still accurate.
- **Breaker-detection design used (copy for any future "who did it" signal):**
  step 1 = exact bbox overlap with the carrier ("whoever touches, broke it",
  absolute priority, break on first); step 2 = nearest puppet with ANY active
  attack form (isAttacking || isJumping || isSpinning) at ANY distance;
  filters: isDead, isHiding, isInactive (frozen state). Signal = targeted
  `net_sound_emit_at(snd_metal_stun, nid)`; receptor gates kept: EXE side
  (character == EXE || revivalTimes >= 2), !isDead, shockedTimer <= 0 (no
  stacking). Anti-cheat surface unchanged (same channel as v62/Sonic parry;
  the removed "still attacking" gate was UX, not a cheat barrier — a cheater
  could hold attack through it anyway).
- **draw_circle(x, y, r, true) is the outline form**; a pose-countdown ring is
  drawn from `var _gT = timer / POSE` (1→0) with alpha `0.15 + 0.5 * _gT` and
  MUST restore draw_set_color(c_white) + draw_set_alpha(1) after (Draw event
  state leaks into everything drawn later).

### Verification lessons (paid for)

1. **Function-extraction regexes MUST strip trailing comments first.** Pass 2
   dropped only full-comment lines; trailing Spanish comments like «el agarre
   (tecla V)» matched `\b([a-z_]\w*)\s*\(` ("agarre(", "pose(") and reported
   phantom undefined functions. Strip string literals FIRST (a // inside a
   string is not a comment), then the // tail, then extract.
2. **Never count macro names in raw file text.** The v92 comments NAME their
   macros ("radio JINNA_GRAB_RANGE...", "TIPO ATAQUE (ITEMBOX_ELECTRIC_STUN)")
   — counts must be CODE-only (comment-stripped) or they go 8/4/4 instead of
   5/3/2. Stronger form shipped: code-only count over ALL compiled .gml +
   exactly-one `#macro` definition + zero uses outside the 4 changed files.
3. **A whole-repo sweep needs a "compiled code" definition** (see fact above)
   — without the `_backups*` exclusion, 6 backup snapshots read as 12 extra
   macro uses + 6 fake definitions.
4. **When the GML is right and the checker is wrong, fix the CHECKER and
   re-run — but only after proving the game code by hand** (grep: the 8 hits
   were 5 code + 3 comments; code counts were exactly 5/3/2 as designed).

## v93 — Metal Amy rework: hunt-confirm dash refund + tactical-data scan synergy + 4s bullet; animated own-sprite HUD icons (2026-11-27)

Request: «Rework De metal amy Mejora a sus habilidades y gui (recuerdas el cosito
que hisiste que aparecia el chao. de vanilla como habilidad osea ese icono animado?
me gusto me gustaria que metal amy tubiera la misma cosa para sus habilidades» —
followed by an owner clarification: the icons must use the abilities' OWN
animations (like Chocola used Chocola's own idle), NOT Chocola pasted everywhere.
Outcome: 4 code files — `scr_metalamy_special.gml` (refund + double recharge +
bullet 4s + doc fixes), `obj_metalamy/Create_0.gml` (`dashHitConfirm` + doc fixes),
`obj_metalamy/Step_0.gml` (doc fixes only), `obj_playerui/Draw_64.gml` (new
`drawMiniIcon` helper + the EXE_METALAMY case fully animated). Pass 1: 72 OK /
0 FAIL; pass 2: 31 OK / 0 FAIL (byte-exact reconstruction of all 4 files +
owner-scenario clone re-running pass 1: 72 OK / 0 FAIL).

### The Chocola pattern, generalized (copy for any future animated HUD icon)

1. **`drawMiniIcon(_spr, _cx, _cy, _cw, _ch, _scale, _key, _xx, _yy, _col, _alpha, _fly)`**
   (obj_playerui/Draw_64.gml, next to drawKeyIcon) = the v83 Chocola icon as a
   reusable helper: `frame = floor(current_time / 150) mod max(1,
   sprite_get_number(_spr))`, `slide = (1.0 - _alpha) * 10`,
   `draw_sprite_part_ext(spr, frame, _cx.._ch, _xx + _slide + _flyX, _yy, _scale,
   _scale, _col, _alpha)` + the REAL bound key via `scr_text_spr`. `_fly > 0`
   gives a ±3px sine sway (period = `_fly` ms) for SINGLE-frame sprites — the
   only way to "animate" a 1-frame projectile sprite honestly.
2. **Crop = the measured content box (v4.3b rule), never the sprite box.**
   Measured with PIL over the source PNGs: jump (0,0,30,30), attack2 (0,0,31,31),
   bullet (1,3,40,10) [41x17 with margins], scan (0,18,53,44) [top 18 rows
   transparent in ALL frames]. Requesting transparent-margin rows is the Amelia-
   trap failure mode; the Chocola icon itself crops (3,2,13,21) = its content box.
3. **Per-icon scale is chosen from the measured content height to fit the ~10-13px
   HUD band**, not from a uniform "half scale like Chocola": 0.4 (30-31px anims),
   0.7 (10px bullet), 0.3 (44px scan pose). Layout locked in a 4x pixel mock built
   with the real sprites (PREVIEW_V93_HUD_*) BEFORE writing GML; VLM confirmed no
   overlap/no clipping in 3 states (ready / recharging / huntress-gold).
4. **Row band y-anchors changed**: Z 219-ico (y=3), X 238-ico (y=22), C/V 252-ico
   (y=36) — the icons are 12-13px tall (vs 9-11 of the old GUI sprites); keeping
   the old 218/240/250 anchors made the 12.4px X art overlap the C row by 1.4px.
   The V letter column stays < 480 even at max slide (451.9).

### Facts learned (verified in code)

- **The server bullet cooldown is ZERO.** Game.c CLIENT_METALAMY_BULLET sets
  `plr_cooldowns[METALAMY_BULLET] = 0 * TICKSPERSEC` and only enforces ONE live
  bullet via `game_find(..., "mabul", 1)`; the whole 5s (now 4s) cooldown lived in
  the client (`bulletTimer`). Buffing client cooldowns of server-tick'd entities
  is safe WITHOUT touching the server or BUILD_VER. Bullet lifetime is 4s server-
  side (MakeMetalAmyBullet timer), speed 14px/tick, straight line only.
- **The shipped scan macro values postdate the v4.10 spec and are the owner's
  later tuning**: SUITE backups of 2026-11-10 have SCAN_TIME (60*12),
  HUNT_TIME (60*14), DASH_RECHARGE (60*5), BULLET (60*3); shipped HEAD has 15.5 /
  11.25 / 3.75 / 5. The COMMENTS still described the v4.10 spec (12/20/14/5/8).
  v93 fixed the comments to the shipped values and changed NO scan/hunt/dash
  values — comment drift ≠ license to revert gameplay. CONSEQUENCE worth knowing:
  manual reveal 15.5s > cooldown 14.5s ⇒ the V is re-pressable while still
  revealed (near-permanent uptime is possible). Left as-is, documented.
- **Where dash damage actually happens**: NOT on Metal Amy's client. The
  victim's client detects it in obj_player_puppet/Step_0 (`place_meeting(x, y,
  global.player)` + the attacker puppet's isAttacking bitflag) and calls
  scr_player_hurt there. So her own client cannot know "my dash hit" without
  packets — the v93 refund is a LOCAL approximation: her own Step_0's
  `instance_place_list(x, y, obj_player_puppet, ...)` with the same filters the
  victim's path uses (isDemonized/isInactive/isHurt/hp<=0 skipped). If the victim
  parries/i-frames the hit, she still gets the refund — acceptable QoL: dash
  charges were ALWAYS client-authoritative (the server never validates the X
  dash), so the anti-cheat surface did not move.
- **A dash contact can be missed between frames** at 12px/frame on HER client the
  same way it can on the victims' clients (same mask check, synced positions);
  the refund only triggers on frames where the masks actually overlap.
- **`instance_place_list` is the established same-object pattern** (obj_metalamy/
  Step_0 line ~33 for the jump-bounce); `dashHitConfirm` re-arms on every X press
  (`dashCharges--; dashBoost = ...; dashHitConfirm = false;`).
- **METALAMY_DASH_HIT_REFUND (60 * 1.5)** — refund 90 frames, capped at
  `min(dashRecharge + 90, 225)`; with DATOS TACTICOS the same +2/+1 recharge step
  applies after, so a refund at frame 50 of a charge completes it at frame 224
  (instead of 225 from scratch — verified by simulation both passes).
- **Multi-frame crop must cover the UNION of all frames' content** (scan frames
  vary x[0..26..52] per frame); the static crop window (0,18,53,44) covers every
  frame, verified per-frame by PIL at two alpha thresholds (>8 and >16).
- **The pre-existing nested ternary in Draw_64.gml line ~187 (Chaos slime jump
  icon)** is HISTORIC and untouched; the v83 no-chained-ternary rule applies to
  NEW code — scope the check to the new helper + new case, not the whole file.
- **spr_metalamy_bullet is wired to obj_metal_amy_bullet via its .yy spriteId**
  (no .gml references it anywhere) — asset-existence checks for sprites must look
  at .yy spriteId, not grep .gml.

### Verification lessons (pass 1 had 5 checker-side FAILs; pass 2 had 3)

1. **`str.find()` with a whitespace-free needle over comment-stripped code
   matches nothing** — strip_gml removes comments/strings but NOT spaces; keep
   the literal spaces in the needle or use a `\s*` regex.
2. **Model branches that draw the SAME icon twice** (huntress gold / manual white
   for the V scanner): the expected call set must count the pair, or the checker
   invents a phantom 5th icon.
3. **Regex group order bugs surface as int("0.4") ValueError** — when unpacking a
   match, write the tuple in GROUP ORDER with the types read off the regex, and
   remember `(\d+)` does not match floats (use `([0-9.]+)` for scale args).
4. **A checker's "clean clone" scenario must commit the baseline BEFORE the
   overlay** — overlay-then-commit makes `git diff` empty and the scope check
   fail on exactly the 4 expected files.
5. **Letter-band math**: scr_letter glyphs are 6px tall, 6px advance
   (scr_text_spr); letter y = icon_y + floor(ch*scale/2) - 3 keeps them inside a
   7-13px band; assert per icon in pass 2 (D section).

### Pending

Nothing for v93. Tuning knobs if the owner asks: refund size (METALAMY_DASH_
HIT_REFUND), scan-dash double step (+2/+1 in the recharge block), bullet 4s
(METALAMY_BULLET_RECHARGE), icon scales/anchors (the 4 drawMiniIcon calls in
obj_playerui/Draw_64.gml case EXE_METALAMY). If the owner wants the v4.10
documented scan values back (12s reveal / 20s cooldown / 14s hunt cycle), it is a
3-macro change in scr_metalamy_special — the shipped 15.5/14.5/11.25 values were
kept deliberately (see "Facts learned").

## v94 — Kris + Amy Canon: animated own-sprite HUD icons ("el mismo tratamiento", 2026-11-27)

Owner asked to give Kris and Amy Canon «the same treatment» as Metal Amy v93
(animated icons). Key readings of the request, in priority order:

1. **"El mismo tratamiento" = extend the v93 machinery, do NOT invent gameplay.**
   The v81 lesson ("EXTEND, DON'T INVENT") is the exact precedent: when the
   owner says "add the same thing as X to characters A/B", reuse the existing
   system (here: drawMiniIcon) and change presentation only. Kris and Amy
   Canon kept their kits 100% intact — only the HUD drawing changed. This also
   matches the immediate conversational context (the clarification exchange was
   about the ICONS, and the answer "ok" preceded the request).
2. **An ability's "own animation" is defined by the state->sprite table**, not
   by guessing: scr_survivors' player_anims maps AMY_CANON_HJUMP(15)->
   spr_amy_attack2_canon, DASH(18)->attack3, TAROTDASH(23)->attack1,
   LIGHTDASH(25)->light_speed; Kris's air-attack phases are
   spr_kris_attack1_air1 (ground + phase 1; ground art was never made) and
   _air2 (phase 2). The HUD icon should use the sprite the STATE actually
   shows, so the icon previews the real move.
3. **A multi-face icon can animate its face too.** Amy Canon's C already chose
   its COLOR by context (v83: air = LSA shares dashTimer, super phase 2 ground
   = hammer throw); v94 additionally chooses the ART: hrow_hammer (10f) /
   light_speed (1f + _fly wobble) / attack3 (8f). Keep the branch order aligned
   with the color logic (throw -> air -> ground) so icon art and readiness never
   disagree.
4. **Choosing between two candidate sprites is a legibility decision.** Kris's
   sword had two animations (air1 4f vs air2 8f): the contact sheet + VLM read
   showed air1's big contiguous slash + visible pink blade survive 24% scale,
   while air2's fragmented trail turns to noise. More frames != better icon.
5. **Removing placeholder fallbacks is a cleanup, not a risk**: Kris's three
   icons were borrowed placeholders (Eggman jetpack / Amy attack / Eggman
   shield) behind asset_get_index guards for GUI sprites that never materialized.
   Real game sprites (already in the .yyp, already drawn by Draw_76) need no
   guard — direct references are safer than asset_get_index strings.
6. **Sprites that lose their last reference do not break the project**: the four
   static GUI sprites (spr_gui_amy{hjump,attack,dash,parry}_canon) are now
   unreferenced; GameMaker keeps them as resources. No .yy/.yyp edits are
   needed to stop using a sprite.

### Verification lessons (both passes clean after fixing CHECKER bugs only)

- **The .yyp lists sprites as "sprites/<name>/<name>.yy"** (plural folder,
  .yy extension) — check membership with that exact string, not
  "sprite/name/name.yy".
- **Counting calls by identifier over-reports**: comments mention drawMiniIcon
  too ("...ciclando frames (drawMiniIcon):"); count "drawMiniIcon(" minus the
  definition instead of \b drawMiniIcon \b.
- **Mutually exclusive draw branches draw the same key**: Amy Canon's C has 3
  calls in if/else-if/else at the same anchor. Overlap checks must either
  dedupe by key+position or explicitly exempt same-key alternatives;
  otherwise the checker "finds" a C-vs-C collision that can never render.
- **Extract the old/new pairs for pass 2 from git itself** (gen_v94_pairs.py
  anchors on unique strings, slices HEAD and the delivered file, and proves
  HEAD+v93pairs+v94pairs == delivered byte a byte). Hand-copied pairs from the
  chat are the error source; generated pairs cannot drift.
- **Mock-rendering the HUD needs the panel math from the renderer, not from
  the game**: the first PREVIEW_V94 pasted the second panel at x=HUD_W*ZOOM
  on a canvas of exactly HUD_W*ZOOM width (invisible). The panel-canvas
  mismatch was in the mock only — the game code was already verified by the
  bounds check; VLM caught it, layout math re-confirmed.

### Pending

Nothing for v94. Tuning knobs if the owner asks: icon scales/anchors (the 9
drawMiniIcon calls in obj_playerui/Draw_64.gml cases CHARACTER_KRIS /
CHARACTER_AMY_CANON), and per-face art swaps (e.g. sword air2 for air1, or
block_success_air for the shield icon) — all single-argument changes.

## v95 — Kris: exit compass + LOVE growth + the LV-20 killer duel (2026-11-27)

Owner's ask: Kris sees the exit always; each LOVE level up = +20 max HP and
heals 20; at LV 20 the killer gets a health bar and Kris deals 35 per sword
hit (ONLY at LV 20); in LMS his level rises 100% faster (pace retuned in
v96 below: LMS 3 hits/event, normal 1.5). Everything hangs off
the v46 LOVE system — extend, don't invent.

1. **The v46 LOVE system was the whole skeleton**: krisLv 1-20
   (KRIS_LV_MAX), krisLvHits thresholds, krisLvNet mirrored on puppets via
   the silent snd_none signal, and the victim-authority stun scaling — all
   reused. The LV-20 "consequences" needed ZERO new player state: the exe
   side reads the SAME krisLvNet mirror to decide if the sword wounds.
2. **A character max HP that grows needs FOUR alignment points, or the
   feature silently breaks**: (a) scr_player_maxhp must be level-aware —
   every heal gate, the LMS heal, revival, spawn and the
   CLIENT_PLAYER_DATA clamp call it, so ONE change aligned them all;
   (b) the SERVER anti-cheat cap must be raised to the reachable max
   (CH_KRIS 100 -> 480 in Game.c) or the server disconnects the player
   ("garic forn") on the first heal past 100; (c) puppet displays must pass
   the instance so the bar scales with the MIRROR (krisLvNet), not the local
   player's level; (d) overhead HP rings keep their hardcoded 100-steps —
   Rouge (125) and Metal (150) already shipped like that, so Kris at 480+
   is house-consistent (the "+NN" HUD bar is the source of truth).
3. **A per-character optional parameter is the house-safe signature change**:
   scr_player_maxhp(char, inst = noone) — every existing call site keeps
   working (local reads global.player.krisLv inside), and only the 4 puppet
   call sites needed the extra argument.
4. **The exe's "boss pool" is a GLOBAL, not an instance variable**: the exe
   has 6 playable variants (Original/Exeller/Exetior/Chaos/Jinna/Metal Amy),
   each with its own Create — global.exeHpPool (reset per round in
   obj_level/Create, boot value in scr_globals.gml) works for all of them
   with zero Create edits and doubles as the mirror target on every client.
5. **Net signals: verify the REAL array index, not the comments**. The
   net_snds comments have drifted +1 since v4.7 ("lo que manda es el ORDEN").
   The array was 124 entries (0..123) before v95 — snd_kris_lvup appended =
   REAL index 124, and the receiver ignores anything >= its own length, so
   a v94 client simply drops the new signal. Count entries by parsing, and
   remember a duplicate asset (snd_exe_laugh exists twice, pre-existing)
   can never be a new index (array_find_index resolves to the first).
6. **The invisible-exe sound gate forces a raw packet for exe-emitted
   signals**: net_sound_emit silences everything but snd_spring while the
   exe is invisible — but the sword DOES stun (and now wounds) the
   invisible exe. A signal sent through the gate would be lost exactly
   when the exe tries to hide, and the mirrored bar would drift forever
   (no absolute resync exists). scr_kris_exe_hp_signal writes the SAME
   packet layout by hand, and the receiver branch is excluded from
   scr_audio_play_3d so nothing audible leaks the invisible exe's
   position. Data is not a sound.
7. **Refills can be DERIVED instead of signaled when both sides apply the
   same ordered sequence**: exe pool and Kris mirror both start at 350 and
   apply the same TCP-ordered -35 signals, so "pool hits 0" is the same
   event on both — each side refills itself. No second signal type, no
   drift (a missed refill needs a lost TCP packet, which the transport
   forbids).
8. **Sprite geometry beats sprite name for layout**: spr_status
   ("Escape!!!") is drawn at y=32 but is 168x15 with origin (84,0) — it
   OCCUPIES y=32..47. The first bar draft at y=38 "was below the Escape
   text" by its draw coordinate and still overlapped 12 rows. The VLM pass
   on the pixel-exact mock caught it; the fix (y=51) was then verified by
   mock + pixel sampling + VLM again. Check origin + height, not just the
   draw call's y.

### Verification lessons (both passes clean; all early failures were
### checker bugs)

- **Positional diff application must special-case pure insertions**:
  unified-diff hunk "@@ -l,0 +m,n @@" inserts AFTER old line l — a naive
  idx = l-1 shifts the block up one line and the byte-exact reconstruction
  fails for every pure-insert file. (Also: a checker assertion can be wrong
  — 25 hits = 2 knockdowns + 5 wounding hits = 175 left, not 350.)
- **gcc -fsyntax-only of the server needs an enet stub**: enet isn't in the
  sandbox; a ~40-line stub header with the types/prototypes the server uses
  lets states/Game.c (the COMPILED copy, per the v14.3 lesson) pass a FULL
  syntax check against the real headers. The root Game.c is dead code that
  already had 23 errors at HEAD — verify only that your hunks add none
  (23 == 23).

### Pending

Nothing for v95. Tuning knobs if the owner asks: KRIS_LV_HP_BONUS (20),
KRIS_LV_BASE_HP (100), KRIS_EXE_DAMAGE (35), KRIS_EXE_MAXHP (350),
KRIS_EXE_DOWN_SEC (10) — all macros in scr_kris_special.gml; bar geometry
in obj_playerui/Draw_64.gml (_kbX/_kbY); the bar is Kris-only by design
(making it visible to the exe too = remove the global.character check).

## v96 — Kris: LOVE pace retune — LMS +200%, normal +50% (2026-11-27)

Owner's ask: "ok bn pero esta vez aumentaremos a 200% lo del aumento de
nivel en lms y 50% en modo normal" — the level-gain boost goes to +200% in
LMS (3x) and the normal mode now also gets +50% (1.5x).

1. **One tuning knob away from the math = extract the macro when the
   owner asks for a different number**: v95 hardcoded
   `krisLvHits += global.lmsActive ? 2 : 1;` — v96 becomes
   `lmsActive ? KRIS_LV_XP_LMS : KRIS_LV_XP_NORMAL` with
   KRIS_LV_XP_LMS 3 / KRIS_LV_XP_NORMAL 1.5 next to the LOVE v46 macros.
   Single accumulation point in the whole game (both call sites — sword
   hit and parry success — go through scr_kris_love_event), so ONE line
   of logic changed.
2. **Fractional hit counters are safe HERE because the numbers are exact
   in binary**: 1.5 and 3.0 are exactly representable doubles, so
   krisLvHits stays exact forever (no rounding drift); the thresholds are
   integers compared with >=, which is float-safe. LV 20 (56 hits)
   arrives at 19 events in LMS (was 28) and 38 in normal (was 56).
3. **The +1-per-signal mirror survives ANY per-event multiplier as long
   as no single event can cross two thresholds**: thresholds are spaced
   3 apart and both multipliers are <= 3, so one event can cross at most
   one new threshold (crossing two needs an advance > 3). The silent
   snd_none signal fires once per actual level-up and krisLvNet does +1
   (first signal = 2) — zero mirror changes needed. Also true when LMS
   activates mid-round on top of a fractional normal-phase total.
4. **Docs must annotate superseded behavior, not just append**: v95's
   CACHE/LEARNING entries said "2 : 1"; a future session greps the rate,
   finds the stale line first, and reimplements v95. Keep the historical
   entry but mark it SUPERSEDIDO with a pointer to the new one.

### Verification lessons

- **Re-run the OLD check's assertions after retuning numbers**: check_v95.py
  asserts the literal `? 2 : 1` formula — by design it now FAILS on the v96
  tree (it verified v95, it is not a regression test). A rate change needs
  a fresh check pair that pins the NEW literals and re-simulates the events
  to LV 20 (19 LMS / 38 normal / 56 untouched thresholds).

### Pending

Nothing for v96. Tuning knobs: KRIS_LV_XP_NORMAL (1.5) / KRIS_LV_XP_LMS (3)
in scr_kris_special.gml — any > 3 multiplier per event would break the
one-level-per-event invariant (mirror drift) and would need threshold
respacing or a multi-signal flush first.

## v97 — Kris LOVE desync: client LV 20, everyone else sees LV 13 (2026-11-27)

Owner's report: "kris sube rapido en el cliente pero en el server no lo
reconose los demas lo ven a lv 13 mientras que en su cliente ya es lv 20".

1. **A mirror that advances +1 per SIGNAL is only exact while one event
   can cross at most one threshold**. The owner raised the v96 knob
   KRIS_LV_XP_LMS from 3 to 5 after applying the v96 zip (their repo,
   their tune — keep it). Thresholds are spaced 3 apart
   (2,5,8,...,56), so a 5-per-hit event crosses TWO thresholds: the
   local krisLv jumps 2 levels while the single snd_none signal only
   moves the remote krisLvNet +1. Twelve LMS hits later the numbers are
   EXACTLY the reported pair: local 20, mirror 13 (6 double-jumps =
   6 levels of drift, permanent — no absolute resync exists in the
   design). Every symptom in the report is the same root: the others'
   HP bar capped at the mirror's maxhp (340 vs 480), the scaled stun
   ran short, and the exe NEVER saw LV 20 so the killer-duel real
   damage never armed on their screen.
2. **The fix that makes the knob FREE is the multi-signal flush
   (predicted by the v96 pending note, now implemented)**: compute
   `_up = _new - krisLv` BEFORE assigning, heal `KRIS_LV_HP_BONUS *
   _up` (a double-level hit heals +40, +40 max hp — the old code
   healed only +20 per EVENT which contradicted "heals that amount per
   level up"), and `repeat(_up) net_sound_emit(snd_none)` — one signal
   PER LEVEL crossed. The receiver (+1 per signal, cap KRIS_LV_MAX) is
   untouched and now exact for ANY multiplier (verified 1.5/3/5/7/10
   and normal→LMS mixes).
3. **The relay path was verified, not assumed**: the C server's
   CLIENT_SOUND_EMIT case only drops DIRECTED stun signals
   (`nid != v->id`) and rate-limits Chocola indices 109/110; the Kris
   broadcast travels with `nid == emitter` and lands straight in
   `server_broadcast_ex` — N signals in, N signals out, no dedup. The
   exe-invisible silence gate in net_sound_emit only applies to
   `global.character == CHARACTER_EXE`, and Kris is never the exe.
   Write the proof into the check, not just the comment.
4. **"2 call sites" in the v96 notes were 2 SOURCES, 1 call site**:
   since v47 the parry success does NOT call scr_kris_love_event —
   both the sword hit and the parry land as stuns, and the VICTIM's
   client emits CLIENT_PLAYER_HURT with pid == Kris's nid, which the
   Kris client counts in ONE place (net_state_game.gml ~3060). Single
   accumulation point = the flush covers every path. Grep for real
   call sites before trusting old doc counts.
5. **Stale index comments in net_snds are a live trap**: the comment
   said snd_kris_lvup was "124 (real)" but Jina's taunts had pushed it
   to 126. Harmless at runtime (both sides resolve by VALUE via
   array_find_index, and the server's hardcoded stun indices
   0/1/12/109/110/118 were still correct), but a future editor
   "fixing" code to match the comment would break things. Fixed the
   comment (126, with the why) — diff is 100% comment lines, verified
   by comparing the code part of every +/- diff line.
6. **Simulate the REPORTED numbers, not just the fix**: reproducing
   the owner's exact 20-vs-13 with the old rule proves the diagnosis
   (same cause, not a different bug), and keeping that reproduction
   in the check (assert mirror == 13 without flush) turns the user's
   bug report into a permanent regression test.

### Verification lessons

- Both passes green on the first run after fixing 4 CHECKER bugs (the
  game code never changed mid-verification): (a) `git status
  --porcelain` starts unstaged mods with a SPACE (' M path') — don't
  .strip() the output before splitlines or you eat the marker;
  (b) a naive "no code changed" grep must compare the code PART of
  each diff line (before //), because pure-comment lines can be
  re-split into more lines — compare the multiset of non-empty code
  parts instead of raw line counts; (c) the server's `sndidx == 0`
  references inside game_stun_signal_ok looked like a dedup on our
  signal until you check the caller gates it behind `nid != v->id`;
  (d) "events with a level-up" (12 at knob 5) != "levels gained"
  (19) when double-jumps exist — assert the right one.
- Event count sanity for the new pacing (knob 5): LV 20 in 12 LMS
  hits / 12 events / 19 levels / 19 signals; normal 1.5 unchanged at
  38 hits. The heal chain from full HP stays == maxhp at every level
  (100 → 480), and a wounded double-level hit heals +40.

### Pending

Nothing for v97. Tuning knobs are now FREE: KRIS_LV_XP_NORMAL (1.5) /
KRIS_LV_XP_LMS (5) in scr_kris_special.gml can be any value — the
flush keeps the mirror exact regardless (cap: one TCP packet per
level, 19 max per round per event class). KNOWN LIMIT (pre-existing,
unchanged by v97): a client that JOINS mid-round starts its mirror at
LV 1 and never receives past signals (no absolute resync exists) —
only affects late joiners/spectators, not the players present from
the start. If the owner ever wants it fixed it needs a new
piggybacked absolute value (e.g., ride CLIENT_PLAYER_DATA) — ask
first, don't invent packets (rule 7).

## v98 — Kris LV 20 "final duel": 8 owner requests — lessons

- **The HUD micro-font (scr_text_spr / spr_letter1) is LOWERCASE-ONLY.**
  Base index is `ord(c) - 97`; every unsupported char falls to
  `default: ind = 44`, which renders as a "?" glyph. That was the whole
  mystery of the owner's "the exe bar shows ?????": the v95 label was
  `"EL ASESINO  N golpes"` — every UPPERCASE letter rendered as "?".
  Fix: build HUD labels from `string_lower(name)` (á é í ó ú ñ ü survive
  because string_lower maps Á→á and frames 78-84 exist). Never put
  uppercase in anything drawn with scr_text_spr. Digits and a-z are
  safe; everything else falls to glyph 44.
- **The exe's own client has no puppet of itself** — for "show the exe's
  nickname to everyone" use the puppet lookup (`master_id ==
  obj_netclient.exeId`) on other clients but `global.nickname` on the
  exe's own screen. Same class of asymmetry as Kris's own krisLv vs the
  krisLvNet mirror on his puppet.
- **A "visible to everyone" boss bar only needs the DRAW gate changed.**
  v95 already mirrored global.exeHpPool on every client (the raw
  CLIENT_SOUND_EMIT signal is a broadcast); the bar was simply gated to
  the Kris client. The everyone-gate is: local Kris → own krisLv; other
  clients → the Kris puppet's krisLvNet (exact since v97's 1-signal-
  per-level flush). Hide it when that Kris is dead (puppet.isDead is a
  local approximation; the real isDead never travels by net).
- **The server can mirror client-side progress with ZERO new packets.**
  Kris's LOVE levels already travel as silent snd_none broadcasts (nid
  == sender, sound index 0) with exactly one signal per level since
  v97 — so the server just counts them in CLIENT_SOUND_EMIT
  (gate: sender is CH_KRIS, sender is not the round's exe — Exeller's
  clone also emits snd_none but that player IS the exe; directed
  signals like Super Amy's hammer throw have nid != sender and never
  count). Server LV = count + 1; 19 signals = LV 20. Cap the counter
  at 19 so a hacked spam client can't keep inflating it.
- **New server→client "state" packets need the join-resend.** LMS did it
  (SERVER_GAME_LMS re-sent in game_state_join because it was a one-shot
  broadcast); SERVER_GAME_RING_OFF needed the same or reconnecting
  clients would keep a ghost escape ring during the final duel.
- **Owner-phrase interpretation (documented, tunable):** "el
  enfriamiento general del golpe de espada se reducira 2 seg en lms
  4 seg" was ambiguous; implemented as two stackable cuts (-2 s while
  LMS is active, -4 s more at LV 20 → 10.75/8.75/4.75 s) with every
  number in its own macro + a floor macro, and the interpretation
  flagged in the LEEME. One-line retune if the owner meant "to 4 s".
- **Reuse the ring-escape bookkeeping for "counts as escaped".** Do NOT
  invent a new result path: the server marks each living,
  non-corrupted survivor PLAYER_ESCAPED and re-sends the SAME two
  packets the bigring flow sends (SERVER_PLAYER_ESCAPED +
  SERVER_GAME_PLAYER_ESCAPED), then calls game_end(ED_SURVWIN). The
  results screen then shows them exactly like ring-escapers. Negas
  (PLAYER_NEGATIZED) fight for the exe and are excluded; also exclude
  DEAD/DEMONIZED/CAUGHT/already-ESCAPED.
- **CLIENT_EXE_DEFEATED anti-cheat: the sender must be the round's
  exe** (AssertOrDisconnect), and a duplicated report is absorbed by
  the existing `game.end > 0` gate. A survivor forging it gets
  disconnected; a hacked exe can only forfeit its own round.
- **gcc -fsyntax-only + a ~40-line enet stub verifies the whole
  server.** No enet/SDL in the sandbox: write the stub to a temp dir
  (NOT the repo), include it with -I, and syntax-check states/*.c and
  the entities. The root-level Lobby.c/Server.c/Game.c and
  entities/AmeliaBomb.c already fail to compile on HEAD (stale
  diverged copies outside the build + a missing enum entry) — compare
  against HEAD before blaming your own diff.
- **CHECKER BUG CLASS (recurring): a check that passes when its
  verification step silently no-ops.** Pass-2's roundtrip originally
  applied the git patch in REVERSE on the HEAD copy (wrong direction)
  and, when `git apply` failed, fell through to comparing the
  untouched copy with itself → always OK. Correct roundtrip: write
  HEAD to a temp file, apply the patch FORWARD (a/<file> → a/copy),
  then byte-compare against the working tree; make any apply failure
  an explicit FAIL. Rule of thumb from v94 stands: every checker bug
  you find, fix it IN the checker and re-run — the game code was never
  wrong here, the check was.
- **Parsing the two packet enums:** GameMaker's enum can end WITHOUT a
  trailing comma on the last entry, and the C side has `typedef enum {`
  noise — parse entries by identifier pattern, not by "line ends with
  comma". Then assert BOTH name parity and numeric index parity (the
  new packets must land at 191/192, right after SERVER_CLAIM_STATE at
  190, in both files).
- **The .yyp is JSON5-ish** (trailing commas everywhere): strip
  `,(\s*[}\]])` before json.loads or the integrity check crashes on
  line 5. Resource entries are `{"id": {"name", "path"}}` — compare
  sets of `id.path` against HEAD.
- **Cooldown-reduction HUD**: when the max recharge can shrink
  mid-round (sword: -2 s at LMS start, -4 s at LV 20), the icon's fill
  must divide by the CURRENT max (scr_kris_sword_recharge()), and the
  min() clamp keeps it honestly red while an old, longer timer drains
  past the new max. An in-progress cooldown is never cut short — the
  cut applies to the next swing.
- **Deployment note for the owner:** v98 adds 2 packets at the tail of
  BOTH enums — client and server must be rebuilt together. An old
  server with a new client: the pool-empty report is ignored (no round
  end at 0), no auto-LMS at LV 20 and no ring-off; an old client with
  a new server just misses the new visuals. KNOWN LIMIT carried over
  from v97: a client joining mid-round starts its krisLvNet mirror at
  LV 1 (no absolute resync), so late joiners won't see the boss bar;
  players present from the start see everything exactly.

## v98b — The LMS latch ate the ring retirement + infinite-time duel (2026-11-27)

- **Never gate a LATER, live condition on a latched "origin story".**
  v98 retired the escape ring only when `lms_natural` was true, but
  that flag is written ONCE when the show starts (natural last-man-
  standing vs automatic LV-20 trigger) and the LMS itself is a latch.
  The very common path — Kris hits LV 20 while others are alive
  (automatic show, `lms_natural = false`), THEN the others die — could
  never re-evaluate, so the ring stayed usable inside the 1v1 and Kris
  could escape mid-duel. Fix: check the state you actually care about,
  live, every tick (`game_kris_alone()`, same survivor criteria as the
  LMS trigger). `lms_natural` stays as documentation only.
- **"Volverá a estado inactivo" meant the 10-second state, not
  destruction.** The owner's original spec had the ring become
  unusable; v98 destroyed it. obj_bigring's Step only accepts a touch
  when `sprite_index == spr_bigring_ready`, so flipping the sprite
  back to `spr_bigring` yields a visible-but-unusable ring with zero
  new assets — and the server now discards `CLIENT_PLAYER_ESCAPED`
  under `ring_off` (that packet had NO server validation at all: any
  hacked client could always "escape"; the duel is server-
  authoritative now).
- **Infinite time with existing assets.** Freeze the countdown server
  side (skip TIME_SYNC; the clock hand freezes by itself because
  `timeFrame` only advances on that packet) and draw ∞ as the counter
  font's "8" rotated 90° — a pixel 8 IS two loops, rotated they sit
  side by side. Frame order in a GM sprite .yy = the `frames` array
  order; digit N = frame N, frame 10 = ":". Pixel-dump counter PNGs by
  LUMINANCE, not alpha: they are opaque black plates with bright
  glyphs, so an alpha threshold shows a solid block and the digit
  shape is in the RGB.
- **A frozen clock silently freezes everything keyed on it** — which
  is exactly what a duel wants here: the sudden-death trigger (2:00),
  the periodic small-ring spawns (anti-stall: no ring regrowth in the
  duel) and the last-10s tick sound all stop. Known carry-over: if the
  duel starts under 1:00, `scr_player_hurt` keeps the 1-second i-frame
  window for the rest of the duel (same as v98 running the clock down).
  The freeze trick itself: add back inside what the tick tail
  subtracts (`time += server->delta` vs the trailing `-=`), leaving a
  stable block that re-enters as a no-op.
- **GM rotation is COUNTERCLOCKWISE for positive angles — and the
  owner caught the mistake before any tool did.** The house's own
  clock hand proves it: it draws with `-45 * timeFrame` precisely so
  it sweeps clockwise as time passes. With `draw_sprite_ext(..., 90,
  ...)` the sprite content lands UP-RIGHT of the draw point (x' ∈
  [px, px+w-1], y' ∈ [py-h+1, py]) — I first assumed up-LEFT and the ∞
  landed +14/-6 px off-center, clipped by the top of the screen
  ("el infinito esta mal posicionado"). Two lessons: (1) when placing
  rotated or offset HUD elements, don't trust mental math — render
  the actual sprite stack (PIL `rotate(90)` matches GM's convention)
  against a reference composition and compare bounding boxes; (2) the
  clock icon is bright AND wide (its face reaches x ≈ 224-226, under
  the first digit's cell), so a bbox window over "the digit area"
  must start at the digits, not at the icon's edge — measure
  digits-only strips or the icon pollutes every center. The fix is
  now regression-checked: check_v98b.py renders the ∞ at the literal
  draw coords from the GML and asserts its bbox center is within
  3 px of the real "4:37" block's center.
- **A remote-player proxy must defensively initialize every variable
  any system might read on it — even when the codebase already
  documents the rule.** The puppet's own Create spells the pattern
  out since v76 ("any future system that consults it"), with fixes
  for isDead (v76) and isGrounded (v2.1.1); v92 then added
  `_pp.isAttacking || _pp.isJumping || _pp.isSpinning` to the
  electric-shield zap and nobody added those defaults — the owner
  hit "Variable obj_player_puppet.isJumping … not set before reading
  it" a full v98b later (Tails projectile → scr_player_hurt →
  shield break → zap loop over every puppet in the room). Two
  subtleties: (1) the crash only fires when earlier operands are
  false — `isAttacking || isJumping` short-circuits, so an ATTACKING
  puppet never reaches the unset read; the bomb needs a NON-attacking
  puppet in the room, which is exactly what a playtest watching the
  attacker mid-swing never hits. (2) The regression check writes
  itself from the reader, not from the fix: extract every
  `_pp.<var>` the game reads on puppets and demand a Create default
  for each (x/y/bbox_* built-ins aside) — that check would have
  caught v92's bug the day it shipped and now guards every future
  read. Shipped as v98c: two `= false` lines + comment next to
  isGrounded.
- **When the owner commits your delivery upstream, "expected
  modified files" checks false-fail.** She pushed the v98b zip
  verbatim ("ewe", fd4c159b — 13 files, +846/-48), so clone + zip
  overlay leaves a CLEAN tree: the check asserting "exactly 11
  modified files" failed with `real: []`. Git-state checks must
  recognize the three real states of this workflow: clean tree
  (version committed upstream), classic overlay (old base + zip),
  and next-version flight (the new fix's files modified). Her "ewe"
  commits have swallowed whole deliveries before (v89, v80e) — when
  a delivery's own checks suddenly fail on a fresh clone, look at
  `git log` before touching anything.
- **When a feature needs "who caused this", check what the network
  already sends before inventing attribution.** The Tails laser's
  spawn packet has carried the shooter's nid since the beginning —
  the client only used it to compute isOwner and threw it away, and
  the electric-shield zap fell back to guessing ("nearest attacking
  puppet"), which fails exactly when the attacker is a shooter
  standing 2000 px away not attacking. Same fix twice over (v98d):
  (1) exact attackerNid plumbed into scr_player_hurt as an 8th
  optional param (default -1 = fall back to the heuristic, so every
  existing caller keeps working); (2) the box packet grew an owner
  u16 so the server credits the SHOOTER instead of pid 0 — with the
  owner's rules expressed as explicit exceptions (boots: nobody —
  forced speed is a grief; exe owner: nobody, v74 surface). Two
  design notes worth keeping: attribute by the INSTANCE that touched
  (instance_place — with 2+ Tails there are up to 3 live lasers, "the
  first one found" is the wrong one), and re-verify server-side
  facts on the server (owner != game.exe from the server's own state)
  instead of trusting a client-claimed field. Also: changing a packet
  format means shipping client and server together — say so loudly in
  the LEEME, both binaries travel in the same zip anyway.
- **"Return the projectile" and "negate the damage" are different
  features, and one of them usually already exists.** In this engine
  every exeSource hit was already negated by the parry inside
  scr_player_hurt — the owner's complaint "the parry doesn't return
  some projectiles" was purely about the RETURN (the deflect that
  flips direction and sends it back cian). Before building anything,
  grep for the existing negation and count what's missing: it's
  usually the deflect packet + server flip + a client state, once per
  projectile, all copies of the laser's deflect pattern. Two more
  patterns worth naming: a "side-override flag" beats editing branch
  conditions when a returning projectile must swap teams (the fireball
  reads its team from its owner's puppet EVERY STEP — a deflected flag
  consulted at that one point makes it anti-exe without touching the
  per-branch logic); and "convert to the existing variant" beats
  inventing new behavior (the demonized Fleetway arrow returns as the
  dmg-0 stun variant that already existed — zero new client hit code).
  Also: effect-only objects (Exetior's stompballs: no damage calls at
  all) must be excluded from "all projectiles" asks — read their Step
  before promising coverage.
- **A network signal carrying game logic must never live inside a
  cosmetic throttle.** The parry's stun signal (snd_exe_stun
  positioned) was emitted inside the 200ms FX throttle of the
  negation: a second attack negated inside that window shipped no
  signal at all, and since the attacker's own local detection "almost
  never catches the contact at full speed", the parry negated damage
  without ever punishing — the exact user report ("ni stuneaba, solo
  negaba"). Rule: signals whose RECEIVER deduplicates (shockedTimer,
  anim-state) can be sent every frame; only pure cosmetics (sound
  flourishes, particles, shake) get throttled. Same lesson on the
  reward side: any damage-credit that fires only when its carrier
  effect actually applies (the exe pool hit lived inside the stun
  application — dedup/attack-gate branches returned before it) will
  silently vanish in exactly those branches; credit the reward at the
  event, not inside the punishment, and give the credit function its
  own short dedup so two racing paths for the same event don't
  double-count. And an input "tap" that is silently dropped during
  transient states (attacking/spin-charging/bounce) reads to the
  player as "my block didn't work" — buffer taps past hard gates and
  consume them when the transient clears.
- **A lag-tolerance gate on the receiver is a lag shield for the
  offender.** The v3.0 rule "only punish attacks still active on the
  attacker's screen" was meant to avoid "free punishment" from late
  signals — but the owner spotted the real effect: a laggy attacker
  finishes the attack on his own client before the victim's block
  signal (TCP, RTT later) arrives, and the gate drops the punishment.
  The attacker gained immunity FROM his own lag. When the
  authoritative event happened on the VICTIM's client (victim-authority
  pattern), the attacker's local state must never veto the consequence;
  at most deduplicate re-deliveries (shockedTimer), never dismiss the
  event. The owner's exact override is documented in scr_parry_stun_signal
  (v101) — design rules from older requests are hers to revoke, quote the
  revocation in the code comment.
