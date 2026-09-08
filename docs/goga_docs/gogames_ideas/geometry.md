# GEOMETRY FLASH — the owner's GDD, v0.3.6 (from the owner's message + drawing)

> The real Geometry Flash. Not a GD clone: GD ships pre-made levels; this is
> an **endless world generator** with the neon-filled GD feel. The PGB
> v1.3.8 pygame sketch is the grandfather; this is the rebirth.
> Asset study: Geometry Dash Lite 2.2.147 (APKPure, `tools/study/` first real
> mission) — THE USAGE LAW in force: study only, everything redesigned.

## 1. THE FEEL (owner's words, locked)

- **Neon that feels FILLED.** No empty outlines: every shape gets a real
  inner fill (gradient body + lit edges), GD-style dark body + bright
  structure lines, but recast in our neon identity. Gentle glow, never a
  mess — "the glow make it gentle and amazing".
- **No faces on the square for now.**
- **Cool VFX + melodic SFX** — "the SFXs are the most important stuff".
  Music matches the same feeling (energetic, satisfying, melodic).
- Dynamic everything: the jump is an ANIMATION, not a state (below).

## 2. SCREEN + LAYOUT (the owner's drawing = law)

Horizontal-only (`"orientation": "landscape"`, design 1920x1080 EXPAND).
Opens with **"TAP ANYWHERE TO START"** over a live idle world.

Vertical stack (design y, top→bottom):

| strip | surface y | notes |
|---|---|---|
| ROOF strip | 300 | solid ceiling; you stand UNDER it when gravity is up |
| line 3 | ~460 | platform segment (1 cell thick) |
| line 2 | ~620 | platform segment |
| line 1 | ~780 | platform segment — jump apex clears it "by a little distance" |
| GROUND strip | 940 | the default floor |

- Gaps between lines ≈ 160 design px ≈ 2 cells; the square (84 px) travels
  through them. **Jump apex ≈ 200 px** — higher than the next line by a
  little, so you can land ON a line or clip its underside while rising.
- The square's **default standpoint is BEFORE center** (x ≈ 0.32 * width) —
  after every push it drifts back there, never to center (reaction time).
- Use every pixel horizontally: obstacles ride all 3 lines + both strips.

## 3. THE RUN

- **Touch = jump.** That is the whole verb (plus what the mechanic does).
- **Golden orbits**: +1 score each, spawned in lines/arcs/waves in the open
  lanes. Twinkle anim (starAnim study), pitch-ladder pickup blip.
- **Every 10 score → world speed x1.1.** HUD shows both: score chip +
  "x1.00" speed chip + the mechanic chip next to them.
- **GOGACoin**: the first one waits 30-50 s from run start, then each next
  spawns 30/35/40/45/50 s after the last APPEAR (random pick). Floats at a
  reachable height; collect = real GOGACoins.
- **Pusher blocks** sit in the road ON the ground AND the roof: hitting one
  is not death — it HOLDS YOU BACK (shoves you left while overlapping). You
  can still jump; survive the overlap and you drift back to the standpoint.
  Pushed past the left screen edge = death ("out-of-screen from a block").
- **Pits**: the ground AND the roof have opened stretches. Fall into one =
  death (both gravities — the roof pits matter in flip modes).
- **Floating hazards** ride the line lanes. Touch = death. No enemies:
  **"the enemy here is just the wrong timing"**.
- Death (any): burst VFX + the run ends through the standard finish_run.

## 4. THE THREE MECHANICS (the surprise engine)

A hidden scheduler picks the next mechanic + its duration secretly:
duration ∈ {10, 20, 30, 40 s} random, next mechanic random (never the same
twice in a row). The swap lands mid-run with a flash + chime — the player
only learns from the **mechanic chip** next to the widgets:

| chip | mechanic | verb |
|---|---|---|
| ◯ + ↑ | **NORMAL** | tap = jump; gravity down; classic |
| ↑ ↓ (apart) | **FLIP** | tap ANYWHERE, ANYTIME = gravity inverts; you sail up/up/up, stick to the roof, tap again to drop back through the lanes |
| ↑⇵↓ (linked) | **STICKY** | tap ON a surface = jump + gravity flips WITH the leap — you arc off and stick to the far side; mid-air taps do nothing |

All three share the world; the generator weights hazards for the active
mechanic (roof content only matters when you can get there — and in FLIP/
STICKY you can, always).

## 5. THE SHOP

- **SKINS (5)** — the square's fill/edge identity (first owned free).
- **THEMES (3)** — the world's palette + VFX tint (first active free):
  each theme recolors bg, strips, lines, hazards, orbits' halo.
- **TAILS (6)** — none (default) / neon / fire / rainbow / gold / match
  (match = the square's own color). Buy once → toggle ON/OFF forever.
- No powerups (owner: skip for now). No enemies.

## 6. THE GENERATOR (endless, chunk-based, fair)

- Chunks of patterns stitched by a seeded rng; weights tighten with speed
  level: wider pits, longer pusher trains, tighter lane gaps, more hazards.
- THE FAIRNESS LAWS: every pit is jumpable at the current speed; solid
  landing ≥ 2 cells after any pit; a pusher never shares its cell-window
  with a pit or a hazard; orbit arcs always clear their pit; the first
  ~6 seconds are a calm runway (learn the feel before the first threat).
- Orbit patterns: straight lanes, arcs over pits, waves riding the line
  gaps, zigzags that teach the next mechanic's verb.

## 7. LAWS FROM THE OWNER (verbatim, binding)

- "a jump should rotate the body by 90 degree in a smooth way depending on
  the distance of the next surface colliding so it be a dynamic animation
  with dynamic VFX that changes based on distance and time"
- "the jump should be higher than the first platform line by a little
  distance so the square can jump to it or even hit it's bottom part"
- "the square if survived, will try to return to the center but before the
  center by a good distance so the user has time to realize what appeared"
- "both what comes next or when are hidden from the user so it feels
  surprising and fun"
- "tweak the algorithm ofc to be cool and the VFXs/SFXs are the most
  important stuff here"
- Test headless AND visual; collisions + movement solid before ship.

## 8. SHIP SHAPE

- Registry: the `geometry` SOON teaser graduates (landscape, price 350,
  needs_games 2 reveal kept, fee 10, coin_div 4, banner on).
- Achievements: score_100 / score_300 one-run + orbits + flips + triple.
- Thumbnail 960x640 composed from the real assets; guide = controls lines.
- version 0.3.6 / code base 30670. NO release (the law). Probes + QA rigs
  green, APKs built, pushed, CI watched.

## 9. PATCH 1 - v0.3.6-1 (the owner's 8-item test report)

- THE /50 LAW: the speed step fires every 50 points now (was /10).
- THE COIN LAWS: the world coin shrinks to a 44px core (was 64 - "very
  big"); the FIRST coin waits the full 30-50s window from the run start
  (the timer started at 0 = an instant coin).
- THE STICK TRUTH (the big fix): STICK was a FLIP copy (it toggled gravity
  on the jump). Now: the tap is JUST a hop; gravity changes ONLY when the
  square TOUCHES another floor - ground <-> roof (the two lines are not
  floors). The climb path is real: ground -> line 1 -> 2 -> 3 -> roof, and
  back down the undersides. FLIP stays the tap-flip.
- SPIKES FROM LEVEL 0 + the LADDER chunk (a climbing rung path with orbit
  marks and a floor threat under it) + the FLOATERS chunk (spike threats
  floating BETWEEN the lines - they only threaten line-hoppers, the ground
  route never has a forced jump under them). Surfaces re-filled: block /
  line / strip / pusher carry denser inner structure (double bevels, stud
  glows, block-joint seams).
- THE VFX OVERHAUL: tails are TWO additive emitters BEHIND the square
  (rotation-aware back face, world-speed launch - never a puddle below);
  the NONE bug is dead (none kills both emitters, the probe asserts it);
  the jump burst moved ONTO the collision (landing dust ring scaled by
  impact + bonk star flashes); the orbit collect is a golden implosion
  (inward ring + star flash + diving streaks); death = double shockwave +
  the ghost square + shard storm + lingering embers. Every effect layered,
  additive, skin-colored - no more repeated small shapes.
- THE REPLAY GROUND-FALL BUG (found + killed by the repro): the ready-phase
  idle bob could BURY the square inside the ground at tap time; the old 2px
  support window dropped the support and the square fell through the world
  forever (replays tap fast = always buried). THE READY GROUND LAW: the
  bob breathes UP only, the run start snaps the stance, and the support
  check carries a 6px SNAP band. Also killed the p["y"]*us double-scale
  (sprite/burst positions) - the SCREEN-px TRUTH part 2.
- THE POWER LAW: 3 power-ups, bought STANDALONE (jump 240 / slow 320 /
  shield 520 - the extra life is the most expensive), spawning in-run every
  30/40/50/60s (never at the start), 10 GAME-seconds each. ROCKET JUMP =
  x1.5 hops + a skin-colored burn under the square. SLOW WORLD = every core
  clock runs at half (its own 10s = 20 real seconds). EXTRA LIFE = pits
  bounce (a 1.4x rescue hop), off-screen re-enters through a light beam,
  hazards pass through with a spark. The chips sit next to the mechanic
  chip with countdowns.
- SFX: gf_pow / gf_pow_end / gf_save / gf_reentry (all synthesized).
- Tests: gf_probe 73 checks 0 fails (the new stick/power/coin//50/none
  laws); gf_replay_repro CLEAN; flow_test + every game probe green.
- version 0.3.6-1 / code base 30680. NO release (the law).

## 9. THE PATCH LAWS (amendments, binding)

### v0.3.6-1 (patch 1)
- THE STICK TRUTH: STICK is not a FLIP copy - the tap is JUST a hop; gravity
  changes ONLY when the square TOUCHES another floor (ground <-> roof; the
  three lines are not floors). The climb ground -> line -> roof is real.
- THE COIN LAWS: 44px core (not a second sun); the FIRST coin waits the full
  30-50s from the run start.
- Spikes from level 0; the surfaces re-filled with inner detail.
- THE VFX OVERHAUL: layered additive bursts (never "repeated small shapes"),
  the landing VFX fires ON the collision, tails are emitters behind the
  square, death = shockwaves + ghost + shards.
- THE READY GROUND LAW: the idle bob can never bury the square at tap time
  (the replay ground-fall bug).
- THE POWER LAW: rocket jump / slow world / extra life - bought standalone,
  30/40/50/60s spawner, 10 game-seconds each (slow world's own clock is
  game-time, so it lasts 20 real seconds).

### v0.3.6-3 (patch 3) - the owner's 11-item round
- THE /50 + /10 TRUTH: "score bonus /50" was the BOX score bonus (registry
  coin_div 4 -> 50, the dead-menu line) - NEVER the speed step; the speed
  step is x1.1 every 10 again.
- THE WHITE-TAIL LAW: _load_meta() re-applies the tail - a replay boots THE
  tail the player wore (the old build streamed a white stranger: the apply
  ran before the meta existed and the stale none-reset config went live).
- THE TAIL BACK LAW: the tail emitters sit ALWAYS at the screen-back side -
  the offset never rides the square's rotation; a flip cannot swing it.
- THE NONE COLOR LAW: with a tail worn, the NONE row wears the VIOLET of
  every not-worn item (brown means "currently in use"); tapping it still
  removes the tail.
- THE STREAK RESET LAW: the collect-blip pitch ladder decays after 2.0s of
  silence - one rung per 1.0s, the last rung to 0.0 after 0.5s; a collect
  freezes the decay.
- THE ROCKET SIMPLICITY LAW: the jump-power burn is a ONE-SHOT on the jump,
  SIDE-AWARE (under the square off the ground, above it off the roof) - no
  constant plume.
- THE FLIP PUSH LAW: the flip's switch reads as a simple push from the side
  being LEFT (a puff below when leaving the ground, above off the roof).
- THE COLLECT BURST: the orbit collect is a golden colored particle burst
  (glow pop + star flashes + a light ring) - the implosion is dead.
- THE COIN SPACE LAW: every coin spawn validates against blocks/lines/
  hazards/orbits and DEFERS 2s when the horizon is crowded - no coin ever
  inside the world.
- THE WORLD LAW: the spike is THREE SMALL triangles on a base (spike3,
  a calculated 120x48 box a base hop always clears; the big triangle is a
  rare level-3 wall) + the BLOCK STRUCTURES: stairs up, gardens, pyramids
  (up AND down), descents (line -> pads -> floor), twin towers with a hop
  valley, floating slab bridges, hanging roof stairs for the flip modes -
  common from level 0, the world is BUILT, not empty.
- THE CLIMB TRUTH: block tops are landing surfaces in the spin predictor
  (the 90 completes at the touchdown); THE CLIMB SNAP catches rising
  near-misses; THE LANDING BAND turns a same-frame touchdown into a landing
  (the old 6px window shoved honest landings away - "it slides on the block
  without letting me able to do a jump"); THE SPACE TRUTH part 3: the
  support check compared the pusher's SCREEN x against the player's WORLD
  span - support silently dropped at world_x > 0 (the deep mid-run block
  bug); the under-bonk makes a clipped slab underside bonk honestly.
- THE THUMB REDO: the thumbnail is the built world (the staircase, the
  mid-jump square with its fire tail, the spike3 row, the orbit arc).
