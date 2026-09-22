# v041-2 — THE GAME DESIGN (the working sheet)

# TOWER BALL — two modes, one tower law

## THE IDENTITY
- id `towerball`, title TOWER BALL, tag "smash the tower, ride the bounce"
- 3D (`dim: "3d"`), orientation AUTO (plays vertical AND horizontal)
- the ball is BALLDOZER (eyes, no mouth) - no lore popup, no words
- casual known look: warm pastel casual palette, clean soft-gradient sky,
  ONE theme; skins re-ink the breakables + the ball. NOT neon. Cool
  shadows: one DirectionalLight3D (soft, shadowed) + gentle ambient.

## THE ECONOMY (the owner's numbers, exact)
- each round WON = +1 score (set_score - the HUD chip)
- score bonus = score / 5 (registry coin_div 5)
- lives = 3 per run (gold miner law: crash = -1 life, the round CONTINUES;
  0 lives = finish_run - the run over sheet rides the host)
- GOGACoin: after every 6 rounds WON, the next round spawns ONE coin in a
  legal spot; it can be MISSED (one window, then it pops away)
- pickups = add_run_coins(1) - the host theatre pays them 1:1
- entry: price 400, fee 8, shop true, reveal direct appear_after 8
  needs_games 11 (the goldminer shelf numbers)

## THE ROUND LENGTH LAW (the owner's ladder, exact)
- round 1..6 -> 150, 300, 450, 600, 750, 900 rows; round 7+ holds 900.
- length(r) = min(900, 150 * r)   [TowerData.round_length]
- BOTH modes ride the same ladder.

## MODE "BALL" (the stack ball smash)
- the helix: a pole + a stack of DISC rows; every disc = a ring of arc
  segments around the pole; discs rotate (per-row speed + direction).
- the ball bounces on the current top disc; HOLD (touch anywhere / LMB /
  SPACE / DOWN) = SMASH: the ball dives; on contact the disc under the
  ball SHATTERS (whole ring pops outward) and the ball falls through.
- the segment under the ball at contact decides:
  - breakable (skin color) -> shatter + fall through (+streak)
  - black -> fire ball? smash through it : CRASH (-1 life, blast VFX,
    the ball bounces back up; the round continues - the gold miner law)
- fair generation (TowerData, pure): no black rows in the first 8 of a
  round; black probability ramps with depth; never a full-black ring
  (always >= 45% breakable); per-row rotation speed/direction alternating,
  magnitude ramps with depth; segment count 10..14 by depth.
- streak / FIRE BALL: each shattered disc +1 streak; a bounce that breaks
  nothing resets it; streak >= 12 -> FIRE for 5s: black segments shatter
  too, flame VFX + trail, +speed. Fire ends -> streak = 0.
- the coin: sits ON one segment of a future disc (a "legal area": a
  breakable segment, never on black, never within 3 rows of the round
  start). Collect = the ball's contact lands on THAT segment. The disc
  shatters as a whole, so the wrong contact = the coin pops away = MISSED.
- round clear: the last disc shatters -> +1 score -> confetti + arp ->
  next round builds (longer ladder), lives persist.

## MODE "PLATFORM" (the neon tower adaptation, round-shaped)
- the tower: rows of blocks spanning the field width above the paddle;
  each row = blocks (breakable, skin color) + rare HARD blocks (black,
  the ball bounces off; fire breaks them; a cleared row crumbles its
  hard blocks away with it).
- the paddle rides near the bottom; the ball bounces break-out style
  (constant speed, no gravity): angle off the paddle = hit-offset law,
  paddle motion adds english, walls reflect.
- the ball breaks blocks of the bottom-most intact row; when a row's
  breakables are all gone, the row collapses and the tower SLIDES DOWN
  one row (smooth 0.12s) - the next row enters reach. The tower's bottom
  edge stays at the reach line the whole round.
- crash: the ball falls past the paddle line -> -1 life -> re-serve on
  the paddle (tap / press to launch). The round continues.
- streak / FIRE: consecutive blocks without a paddle touch; >= 12 -> FIRE
  5s (hard blocks break, flames). Paddle touch resets the streak.
- the coin: floats in the OPEN air between the paddle zone and the tower
  bottom (the legal area), random legal X; collect = the ball touches it;
  window = the next 8 rows cleared, then it pops = MISSED.
- paddle control: touch = drag anywhere, the paddle follows the finger X
  (smoothed); PC = LEFT/RIGHT arrows (hold) + the mouse X moves it; gamepad
  rides the box translation (left stick / dpad -> arrows).
- round clear: the last row collapses -> +1 score -> next round (longer).

## THE FLOW (the owner's two asks, exact)
1. loader overlay (the box's universal screen, works over 3D)
2. intro: the game's own art + "TAP ANYWHERE TO START" through
   tap_anywhere_start (the universal overlay: tap OR any key - accurate)
3. THE OPTIONALS MENU (a sheet, the snake-card design):
   - MODE row: BALL card / PLATFORM card (the mode selection lives HERE
     as ordered)
   - POSITION row: VERTICAL card / HORIZONTAL card (the snake phone
     cards; the ask judges the LIVE window at tap time, the pref decides
     nothing)
   - PLAY button (the mode is remembered via Box progress)
   - a different position than the live one -> request_orientation_reload;
     the host reboots the game with start_orientation set -> the flow
     skips the intro and opens the round straight away (the snake law)
4. pause sheet: RESUME / END (banks the run any time, pause_end_run) /
   QUIT TO BOX; HUD carries SHOP (goldminer law).

## THE SKINS (5 + 5, first default, the goldminer price law)
BALL SKINS (the ball material; the eyes stay):
- classic (default, 0) - Balldozer red-orange rubber
- gold (250), emerald (350), sapphire (450), candy (550)
BREAKABLE SKINS (the segment/block palette + pole + sky tint; black
segments stay BLACK in every skin - the danger must always read):
- classic (0), ocean (250), forest (350), sunset (450), berry (550)
- each skin = a designed 4-color ramp (the tower lesson: ONE designed
  palette, deterministic per row - never random colors)

## THE 3D LOOK (high quality on gl_compatibility)
- one WorldEnvironment: soft vertical-gradient sky (ProceduralSkyMaterial
  or gradient), gentle ambient, subtle glow OFF (not neon), fog OFF
- one DirectionalLight3D, shadow_enabled, warm sun + cool ambient
- MSAA 2x on the root viewport while a 3D game lives (restored on exit)
- the tower meshes: each disc/row = ONE ArrayMesh (vertex-colored segments,
  shared skin material) - ~1 draw call per row, ~25 rows alive max
- the ball: SphereMesh + StandardMaterial3D (skin), Balldozer eyes (two
  small dark capsules riding the sphere, camera-facing)
- shatter: per-contact fragment meshes (4-7 per disc) with velocity, spin,
  gravity, fade - pooled, no physics engine
- the coin: Coin3D (the new 3D default) - accurate scale: the 2D coin is
  drawn ~64 design px; the coin mesh diameter projects to ~64 design px
  at play depth (computed from the camera FOV)

## THE ACHIEVEMENTS (the rule table, my 8)
- tb_first  T1 First Smash      - win a round (cnt rounds_won 1)
- tb_r10    T1 Tower Rookie     - win 10 rounds (lifetime cnt 10)
- tb_fire   T1 On Fire          - trigger the fire ball (cnt fires 1)
- tb_coin   T2 Coin Snatcher    - collect 10 tower GOGACoins (cnt coins 10)
- tb_fire5  T2 Firestarter      - trigger fire 5 times (lifetime cnt 5)
- tb_deep   T2 The Long Way     - reach round 4 in one run (max round 4)
- tb_900    T3 The 900          - reach round 6 in one run (max round 6)
- tb_score  T3 High Tower       - score 12 in one run (score 12)

## THE GUIDE (registry desc + controls + controls_pc)
- desc: the two modes, the rounds 150..900, the lives, the fire, the coin
- controls (touch): tap anywhere to start; BALL: hold anywhere to smash,
  release to bounce, never touch black (fire forgives); PLATFORM: drag
  anywhere, the platform follows your finger, catch the ball, break the
  tower row by row; the coin after every 6 rounds - miss it and it's gone
- controls_pc: BALL: hold LMB / SPACE / DOWN to smash; PLATFORM: mouse X
  moves the platform, or hold LEFT/RIGHT arrows

## THE TESTS (nothing ships blind)
- towerball_data laws: length ladder, fairness (no early black, never
  full-black, rotation ramp), coin placement legality + spacing (every 6),
  fire threshold, paddle bounce law, row collapse law, platform serve
- flow_test: registry shape (dim 3d, coin_div 5, os, controls_pc), shop
  prices/rows, boot the game headless through the host (both modes)
- Xvfb film: ball+platform x vertical+horizontal, EYEBALL before shipping
