# v041-2 r2 — THE IMPLEMENTATION PLAN (roots found, orders locked)

## ROOT CAUSES FOUND (the study)

### A1 THE ROTATION MIS-SCALE (the deadly one)
- The window rotation (re_window) is ASYNC on real Windows (WM_SIZE echo pumps
  late). On the WM-less Xvfb probes it lands instantly - that is why every
  window probe was green while the owner's Windows never was.
- host_node._ready applies the design + re_window, awaits TWO FRAMES, and boots
  the loader + the game. On real Windows the game's first layout pass can run
  BEFORE the real window lands -> the game (and anything reading real px) bakes
  a STALE-shape layout -> "a vertical image in the horizontal view" forever
  (games read the viewport once in _ready).
- The r7 mid-flight wait loop verified get_viewport_rect() - on PC KEEP that is
  the DESIGN, which flips instantly - it verified NOTHING on a PC. THE PROBE
  HOLE.
- The r6 design governor asserts only content_scale_size; nothing ever HEALS a
  lost WM echo (the window stays old-shaped forever while the design is right).

### A2 THE CURSOR LEAK (exact mechanism)
- heavywar arms the STATIC game seat (GogaCursorLib.game_arm) in _ready.
- NOBODY EVER CALLS game_disarm - not the host, not main, not the game's death.
- Quit road: main re-arms the BOX arrow (arm()) -> GOGACursor returns.
- But _game_armed stays TRUE with the WAR images: main._input's menu LMB mirror
  calls set_held -> the GAME branch swaps the WAR click/normal image back in
  on EVERY click in the menu. In the next game the OS cursor still WEARS the
  war image (never reset). = the exact report.

## THE FIXES

### F1 goga_cursor + the twins: THE SEAT DIES WITH THE GAME
- game_base.gd + game_base3d.gd: _exit_tree() -> if _game_cur_armed:
  GogaCursorLib.game_disarm(). Every quit/reload/finish frees the game node ->
  the static seat resets -> no click anywhere can resurrect war images.

### F2 host_node: THE REAL-WINDOW BOOT GATE (the root kill)
- NEW _window_kind_matches(kind) - reads DisplayServer.window_get_size() (the
  REAL px), not the design-locked viewport rect. PC fullscreen: no gate (KEEP
  letterboxes correctly instantly). Headless: no gate (probes).
- _ready: after _apply_orientation, WAIT (capped 90 frames) for the REAL window
  to match the kind; on timeout: resync _orient_now from the REAL window +
  re_window back (honest settle). ONLY THEN: W/H, loader, game boot.
- _on_orientation_reload: the wait loop now checks the REAL window (the same
  helper); the design still flips instantly, but the GAME REBOOTS only after
  the physical rotation landed.
- _assert_design_law: the WINDOW HALF - PC windowed: if the real window kind
  disagrees with _orient_now for 45 consecutive frames (and no gate is open),
  re_window ONCE (the lost-echo heal). Counter resets on match. Zero writes at
  steady state (the r5 no-flicker law holds).

### F3 towerball: the flow (the one-tap disease)
- ROOT: emulate_touch_from_mouse sends ONE physical click as a mouse event AND
  an emulated touch; tap_anywhere fired on the PRESS -> the optionals sheet
  opened inside the press handler -> the SAME click's emulated touch press
  landed on the PLAY button (press+release on it) -> the run auto-started.
  The owner never saw the optionals at all.
- tap_anywhere fires on RELEASE now (a true tap) + sheet_push stamps a birth
  frame: a sheet ignores pointer events on its birth frame (infra-wide, the
  game_base seat).

### F4 towerball: THE REBUILD
- NO LIVES anywhere (the owner's words meant there ARE no lives). Crash = the
  run ends. The lives chip is dead.
- THE HUD: [score chip] [THE FIRE GAUGE (circular, Canvas-drawn: the charge
  fill, the burn ring while active, the cooldown decay)] ... [coins chip].
  The empty widget is dead.
- The ball EXISTS from the first frame: it bounces on the top disc through the
  intro + the optionals (the living scenery), never hidden again.
- BALL MODE: the EXACT Stack Bounce boost law (the owner's source):
  boostValue -0.25 start, +0.03 per break, >=1 -> slomo 0.1 + 1.6s charge ->
  boosting (fire material, white trail, death parts break, dive lerp), burn
  -0.6/s, idle decay -0.15/s, floor -0.5 (the cooldown: ~50 breaks to refill).
  Score stays the owner's: +1 per round won, /5 bonus.
- PLATFORM MODE: THE REAL NEON TOWER (the owner's source, the decompiled
  config): the ball ORBITS the pole at a fixed radius and bounces vertically
  (gravity -60, quadratic drag 0.02, bounceV 23, apex ~6); YOU ROTATE THE
  TOWER (swipe / arrows / gamepad LR); rings with gaps fall = combo
  (score = combo+1 pending), solid landing resets unless the combo charge
  (threshold 4) SMASHES through; red sectors + walls kill; rotating into a
  wall kills; walls (8deg wide, height 3-6) some MOVING (slow/fast);
  round = the same 150..900 ladder (rings); the last ring = the finish.
- SKINS = DESIGNS (not colors): breakables GLASS/ROCK/WOOD/WATER (+CLASSIC
  default) - each with its own material character (transparency/metallic/
  roughness), its own break VFX (glass shards / rock rubble / wood splinters /
  water splash) and its own break SFX; the ball CLASSIC/ICE/METAL/RUBBER/GOLD
  (+ prices 0/250/350/450/550). BLACK ALWAYS BLACK in every skin.
- GAMEPAD: X = dive/launch, d-pad/stick left-right = rotate (platform).
- THE LIVING WORLD: the sky follows the DEVICE's local day time - morning /
  noon / evening / night palettes, the sun (day) / moon + stars (night),
  drifting cloud quads, softer ambient; the thumbnail forces golden hour.
- VFX: the disc breaks into its own SEGMENTS (real mesh fragments with spin +
  gravity), a ring shockwave, dust; the fireball leaves a flame trail; the
  crash shakes harder + a red flash.

### F5 menu.gd
- The doomscroll engine: arrow-key RELEASE glides out with decaying force
  (the same law as the touch release) - r7 already killed the echoes; the
  release path now inherits the live velocity instead of stopping dead.
- The feed card's right-edge vertical line: find the card draw (the thumbnail
  edge or a stray bar) on the Xvfb screenshot rig, kill it at the root.

### F6 meta
- Registry: achievements re-cut to the new mechanics (boost ignitions, combo
  chains, the 900 ring), guide rewritten (both modes, rotate = platform),
  the entry notes gamepad. Thumbnail: the living-world golden-hour capture.

## THE ORDER
1. F1 cursor (small, independent)
2. F2 rotation gate
3. F3 tap/sheet law
4. F5 menu
5. F4 towerball (data -> game -> registry -> thumb)
6. probes + film + eye pass + regression
7. commit -> push -> CI -> deliver (v041-2 r2 changelog)
