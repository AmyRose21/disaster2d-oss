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

## v80h2 — 2026-11-24 — Lessons from the "argument 1 undefined" crash
1. ARGUMENT INDEX BASE: GameMaker runner errors use 1-BASED indexes ("an
   index of 1 is the first argument"). Earlier I assumed 0-based and blamed
   the wrong variable. ALWAYS check the index base before diagnosing.
2. MOBILE TOUCH READS: device_mouse_x_to_gui/y_to_gui only update WHILE
   the screen is being touched. Any point_in_circle/rectangle built on
   them must sit behind _state/device_mouse_check_button. That was already
   the house pattern everywhere else in this codebase.
3. DIAGNOSING WITHOUT THE REAL FILE IS GAMBLING: v80h diagnosed bV2X
   undefined from memory of a reconstruction; the real repo (this one)
   defines everything correctly and the true cause was the unguarded _x.
   Clone/read the real file BEFORE closing a runtime-error diagnosis.
4. json_parse AND MISSING FIELDS: reading struct.field when field is
   absent returns undefined WITHOUT throwing. The try/catch blocks in
   obj_config load() do NOT protect against a half-written 1.bson. Armor
   critical reads with is_undefined (variables on instances:
   variable_instance_exists).
5. VERIFICATION CHAIN THAT CAUGHT THIS: snippet lint -> patch the REAL
   file with the exact PowerShell logic -> semantic simulation of runtime
   cases (including the crash case) -> idempotency -> 3 application paths
   -> re-extract from the generated .bat and re-verify. Keep doing this
   for every fix.
6. USER GOLDEN RULES (re-confirmed): fetch the repo every session; zip
   contains ONLY modified/new files; re-analyze only recently edited
   files; keep CACHE/LEARNING in English and inside the zip; verify 100%
   (including .yy/.yyp sanity); watch the anti-cheat for new attack
   patterns to whitelist; research everything for the editor; write what
   was learned in LEARNING.md.
