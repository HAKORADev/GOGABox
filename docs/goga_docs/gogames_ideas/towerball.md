# TOWER BALL — the v041-2 GDD

The stack ball note graduated. The owner parked it under the
helix-jump-like in FUTURE_GAMES.md (v0.3.9-5 round): "this one may wear
TWO MODES - the first is the CLASSIC stack-ball smash, the second is
inspired by the game Neon Tower from Gamesnacks" - and the open question
(endless or round-shaped) got answered in the assignment: ROUNDS, like
gold miner and brick breaker, with real ends.

## THE OWNER CONTRACT (the assignment, kept in spirit)

- do it for PC and Android, touch and keyboard+mouse, vertical AND
  horizontal ("this game will come with vertical and horizontal to test
  both scenes")
- breakable-things skins + ball skins, 5 in the shop, first is default,
  the rest for GOGACoins
- round algorithms like gold miner / brick breaker: each round has an
  end; the run ends when you crash with no lives; each win gives 1 score
  point; the score bonus is /5
- mode "ball" = the stack ball smash; mode "platform" = the neon-tower
  take (you control the platform); the mode selection lives as THE
  OPTIONALS MENU; the neon tower's endless shape becomes rounds the same
  way stack ball does
- a GOGACoin appears in a legal area after every 6 rounds and it CAN BE
  MISSED, in both modes; the coin's scale must be accurate, and the coin
  becomes the 3D default for future 3D games (the 2D one is coin.png)
- 3D, non-themed (ONE look with skins), NOT neon - "that casual known
  look" with cool shadows and high quality
- SFX + VFX + the spam-like super move: after a long streak the ball is
  the FIRE BALL
- level length 150..900 by the 150-300-450-600-750-900 ladder
- "make the algorithm accurately like the exact originals"
- the game is literally geometrics, NO lore - but the character is
  BALLDOZER as known (the lore already lives in dot eater)
- "make sure that GOGABox infra and game loader will handle a 3D scene"
  FIRST, and "work on the infra too, so any future 3D game will work"
- this is v041-2, NOT another v041-1 round

## WHAT SHIPPED

- THE 3D SEAT (the infra, see the brainstorm sheet): game_base3d.gd
  (GogaGame3D, the Node3D twin of GogaGame - every var/signal/method the
  host and the box chrome touch), game_coin3d.gd (Coin3D - the 3D
  GOGACoin default with the fade-in ramp, the breathing pop, the warm
  halo, the spin, and the SCALE LAW: world_diameter(design_px, cam,
  distance)), the host's dim=="3d" branch (the brown bg skips - 2D
  renders above 3D, so the 3D world brings its own sky), the registry
  "dim" field made real, the MSAA 2x seat while a 3D game lives.
  The loader, the HUD, the sheets, the popups, the toasts, the cursor
  seat - all dimension-blind already: the 3D game gets them for free.
- BALL MODE (the classic smash): the helix spins under Balldozer; hold
  (touch anywhere / LMB / SPACE / DOWN) dives the ball; the disc under
  the ball SHATTERS whole (fragments pop outward in their segment
  colors); the segment under the ball at the contact frame decides -
  breakable = fall through, black = CRASH (one life, the round
  continues, THE GRACE: the black gives way and the ball drifts through
  stunned 0.65s so a held dive can never chain-crash all three lives);
  the fire ball smashes black too.
- PLATFORM MODE (the neon-tower take, round-shaped): the platform
  follows the finger (drag), the mouse (PC), or LEFT/RIGHT (WASD rides
  the box translation); breakout bounce law (offset -> angle up to 62
  degrees + paddle-motion english); the ball breaks the tower row by
  row, a cleared row crumbles (its hard blocks give way) and the tower
  SLIDES DOWN one row; hard blocks are black - they take the bounce
  until fire; the ball falling past the platform costs a life (serve on
  the platform, tap or 1s auto-launch).
- THE ROUND LADDER (exact): 150, 300, 450, 600, 750, 900 - round 1..6
  walks it, round 7+ holds 900. Both modes. Each round ends at a real
  finish (the victory disc in ball mode, the last row in platform) and
  pays +1 score; the run ends at 0 lives; score bonus /5 (coin_div 5).
- THE COIN LAW: the round after every 6 wins carries ONE GOGACoin. Ball
  mode: the coin rides a breakable segment of a disc 15..40 rows under
  the top - collect only when THAT segment takes the contact (the wrong
  segment pops it away = MISSED). Platform mode: the coin floats in the
  open air between the platform zone and the tower bottom - one window
  of 8 rows cleared, then it pops. The coin IS Coin3D, sized by the
  scale law at the 2D coin's 64 design px.
- THE FIRE BALL: streak 12 (consecutive discs / blocks without a
  break) ignites 5 seconds of fire - flames ride the ball, black
  shatters, the dive speeds up. A bounce/miss resets the streak.
- THE FAIRNESS (TowerData, pure, probe-verified on hundreds of seeds):
  no black in a round's first 8 rows (platform: first 3); black/hard
  probability ramps with depth; a ring is never 45%+ black, a row never
  25%+ hard; black arrives in honest 1-3 runs, never salt-and-pepper;
  rows spin 0.7..2.4 rad/s alternating direction.
- THE LOOK: one casual theme (warm pastel ramp, cream pole, soft blue
  sky), one shadowed DirectionalLight3D + gentle ambient, MSAA 2x,
  vertex-colored ArrayMesh per row (the draw-call law: ~1 draw per alive
  row - a 900-row round stays cheap on a phone), pooled fragment VFX,
  camera shake on crash, confetti on the round win. Skins re-ink
  everything; black stays black in every skin (the danger always reads).
- THE SHOP: BALLDOZER (0) / GOLD (250) / EMERALD (350) / SAPPHIRE (450)
  / CANDY (550); CLASSIC TOWER (0) / OCEAN (250) / FOREST (350) /
  SUNSET (450) / BERRY (550). Live apply (the shelf laws).
- THE FLOW: loader -> intro (logo + TAP ANYWHERE, the universal overlay:
  tap OR any key) -> THE OPTIONALS MENU (mode cards + position cards +
  PLAY, the snake ask design; a different position reloads the session
  through the host) -> the round. Pause sheet: RESUME / END (banks the
  run) / QUIT TO BOX; HUD: score (rounds won), lives, streak/FIRE chip,
  SHOP.
- THE AUDIO: 11 pure-math SFX (tools/v0412_sfx.py) + a 32s casual loop
  theme. No words in the world, no lore card - Balldozer just has its
  eyes (the cross-game character law).
- THE ACHIEVEMENTS (8, the rule table): First Smash, Tower Rookie,
  On Fire, Firestarter, Coin Snatcher, The Long Way (round 4), The 900
  (round 6), High Tower (score 12).
- THE THUMBNAIL: the real render (law 44) - the smash capture as the
  hero + the platform mode in a rounded inset (tools/v0412_thumb.py).

## THE TESTS (nothing shipped blind)

- towerball_probe: 11,370 checks 0 fails - the ladder, the coin law, the
  fairness laws over 300 seeds x full depth, the bounce/serve math, the
  skins' prices and colors, the registry seat, and the REAL host boot of
  both modes asserting `game is Node3D` (the 3D seat proof).
- flow_test: ALL PASSED (the registry counts, the shelf order, the /5
  economy, the skin shelf laws, and every playable game boots - the 3D
  game rides the same 3s loader flow as every 2D game).
- tb_film (the Vision Law rig): both modes x both orientations x 5 beats
  + the optionals + the shop, EYEBALLED before shipping. The eyeball
  round caught: the ball mesh never following the physics in ball mode
  (the write-once seat bug), the hard blocks born "absent" (the presence
  law), the landscape camera hiding the stack under the top disc, and
  the platform field reading flat (the subtle tilt).

---

# r2 (v041-2 r2) - THE REBUILD AFTER THE OWNER'S TEST

The owner's verdict on r1: 99.99% broken. The r2 rebuild, from his given
sources (the decompiled originals):

- THE SOURCES: Stack Bounce (gamesnacks, PlayCanvas - readable bundle),
  Neon Tower (gamesnacks, famobi/THREE - the full config JSON in the
  bundle), Stack Ball 1.2.38 XAPK (Unity il2cpp - the fireball field
  names m_killsToStart/m_fillSpeed/m_unfillSpeed/m_fireSpeed + the look).
- BALL mode: the EXACT Stack Bounce boost law - boostValue -0.25 start,
  +0.03 a break, >=1 -> slomo 0.1 + a 1.6s slow-mo charge -> the FIREBALL
  (fire material + the flame halo + the burn loop), burn -0.6/s, idle
  decay -0.15/s, floor -0.5 (the ~50-break cooldown). The r1 fixed-count
  streak (12/5s) is dead.
- PLATFORM mode: THE REAL NEON TOWER - the ball orbits the pole at 4.55
  and bounces on its own (gravity -60, quadratic drag 0.02, bounce 23);
  the PLAYER rotates the whole tower (swipe/arrows/stick); falls through
  gaps build the combo (threshold 4 charges the SMASH-THROUGH); red
  sectors + walls kill; rotating a wall through the ball kills; the
  original's getAvailableRotation law honored (resting on top rotates
  free, inside the slab it constrains/kills). The r1 breakout-paddle
  invention is dead.
- NO LIVES anywhere (the owner: "i meant with no lives for real") - one
  crash ends the run. The lives chip is gone.
- THE HUD: [score] [THE FIRE GAUGE - a circular widget left of the score:
  the charge arc, the burn ring (the remaining active time), the cooldown
  refill] [coins]. The empty widget is gone.
- THE FLOW: the intro (the ball bounces the tower as living scenery) ->
  the optionals (mode + position + PLAY) -> the run. THE ONE-TAP DISEASE
  (the emulated touch self-pressed PLAY the frame the sheet opened) is
  dead: tap-anywhere fires on release + every sheet wears a one-frame
  birth shield. The r1 "the game starts with no mode selection" report.
- THE BALL'S FRONT SEAT: the ball rides the disc's FRONT (world angle 0,
  z=8), not the center axis where the pole hid it - the r1 "the ball is
  not even a ball, not even exist" report.
- SKINS ARE DESIGNS: breakables CLASSIC/GLASS/ROCK/WOOD/WATER (own
  roughness/metal/alpha, own debris styles shard/rubble/splinter/splash,
  own SFX voices); balls CLASSIC/ICE/METAL/RUBBER/GOLD; black always
  black. The r1 "another color" mistake.
- THE LIVING WORLD: the sky follows the DEVICE's local day time (morning/
  noon/evening/night palettes, the sun disc + the moon + 90 stars + 7
  drifting cloud billboards, the sky-driven reflections); the thumbnail
  forces the golden hour.
- GAMEPAD: X/A dives, the stick/d-pad's left-right rotates the tower.
- THE BOX FIXES that rode this round: the real-window boot gate + the
  governor's window half (the rotation mis-scale root), the cursor seat
  death (the war-cursor leak), the doomscroll release slide (friction
  decay instead of the dead stop), and the thumbnails' right-edge bg
  sliver (pop_siege's capture artifact) resmeared away.
- TESTS: towerball_probe 19,951 checks 0 fails; flow_test ALL PASSED;
  r5/r6/r7 window + scroll + continuity probes ALL GREEN under Xvfb;
  the film rig re-shot (intro/opts/ball_v/ball_h/plat_v/plat_h/fire_h/
  shop_v) and EYEBALLED - caught the ball's hidden axis seat, the
  platform camera hugging the pole, the missing ring regen, and the
  degenerate full-circle sector quad (the rings were slivers).
