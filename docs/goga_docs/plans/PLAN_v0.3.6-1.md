# PLAN v0.3.6-1 — GEOMETRY FLASH patch 1 (the owner's 8-item report)

Owner test report on v0.3.6, verbatim laws. Every item lands in geometry.gd,
the art/sfx scripts, the probe, and the QA rigs. Nothing else may regress.

## 1. THE /50 LAW (speed bonus)
- "make score bonus be /50 instead of /10" -> the speed-up step fires every
  50 points now, not every 10. `score % 50 == 0` -> speed x1.1. The speed
  chip stays. The registry desc + guide text updated to match.

## 2. THE COIN SCALE + THE FIRST-APPEAR LAW
- The world GOGACoin rendered too big -> shrink to a fair size (44 design px
  core, halo around it) so it reads as a pickup, not a second sun.
- "i said to appear from likely 30-50 seconds, but i see a coin from the
  start of the game" -> THE FIRST-APPEAR LAW: `coin_timer` initializes to a
  roll of 30/35/40/45/50 at run start (it started at 0.0 = instant coin).
  Every later spawn rolls 30-50s from the LAST APPEAR (unchanged).

## 3. THE STICK TRUTH (flip vs stick)
- FLIP stays as shipped: tap = gravity inverts with the jump, anytime.
- STICK was wrong (it toggled gravity on the jump = a FLIP copy). THE STICK
  LAW: gravity changes ONLY when the square touches the OTHER floor - ground
  <-> roof. The jump itself is a normal hop; mid-air taps do nothing; the
  gravity flips the moment the square touches the roof (sticks up) or the
  ground (sticks down). The two lines are NOT floors for this law.
- Implementation: mechanic "sticky" -> jump = normal hop (no g flip);
  in `_vertical`, when grounded on roof with g==1 (touched roof) flip g to
  -1; grounded under roof with g==-1... -> landing on a surface flips g to
  STICK to it (roof land -> g=-1, ground/line-top land -> g=+1). Falls keep
  their g until the touch. Probe laws updated.

## 4. SPIKES + CLIMBING (fill the empty world)
- The generator gains: spike clusters on lines (floor + roof rows), the
  STAIRCASE chunk - stacked blocks to climb up/down between the lines (the
  owner: "proper obstacles to climb them up"), floating spike bars mid-lane,
  and denser mixed chunks. Surfaces get inner detail so they stop feeling
  empty: the strip gains a top glow seam + block-grid inner pattern (art).

## 5. THE VFX OVERHAUL (the big one)
- THE TAIL LAW: tails emit BEHIND the square (left, world-scroll side), not
  below. A real ribbon/shader trail: neon = additive light ribbon, fire =
  flame puffs that rise, rainbow = hue-cycling ribbon, gold = sparkle
  stream, match = skin-colored ribbon. NONE stays none.
- THE NONE BUG: selecting a tail left "none" visually ON (the old emitter
  kept its last config). One `_apply_tail()` path kills the emitter dead on
  none and the probe asserts the swap.
- THE LANDING VFX LAW: the jump/impact VFX fires ON COLLISION (landing,
  bonk), scaled by impact speed - not a fixed burst on the tap.
- THE REPEATED-SHAPES LAW: every effect that was "repeated small shapes"
  (jump burst, orbit collect, death burst, tails) is redone with soft glow
  sprites + additive shockwave rings + shard/streak mixes + per-skin colors.
  Death = ring shockwave + shards + screen flash + slow shake. Orbit collect
  = a golden implosion ring + streak spark + score popup feel.
- Per-skin VFX identity: each skin carries its own burst hue; death/jump
  particles inherit it (the MATCH tail law generalizes).

## 6. THE REPLAY RESET LAW (the ground-fall bug)
- "after playing the game for the first time, every run ... make the square
  go fall into the ground in a weird way" -> replay state must be EXACTLY
  the first-run state. The replay repro probe (gf_replay_repro) boots
  run1 -> dies -> boots run2/run3 exactly like the host's PLAY AGAIN and
  asserts the square never sinks into solid ground and never dies early.
  Whatever the repro catches gets fixed and the case stays in the probe.

## 8. POWER-UPS (the new layer)
- 3 power-ups, collected in-world like anything else, 10s each (game-time),
  bought STANDALONE in the shop, one spawns every 30/40/50/60s.
  - JUMP+ ("up arrow with a > on top"): jumps x1.5 longer/higher; while on,
    a rocket glow pours under the square in the skin color ("whooph").
  - SLOW ("<<"): the whole world runs 50% slower for 10 game-seconds = 20
    real seconds. The scale must hit EVERYTHING in the core: scroll speed,
    gravity/jump integration, mechanic clock, coin + power-up clocks, spin,
    particles, bg pulse - one `gdt` (game delta) multiplier.
  - INVINCIBLE (the most expensive; square with a smaller blacked-out
    inner square): out-of-screen -> re-enters in a cool way; pit fall ->
    bounces up and continues; spikes/saws do not kill during it.
- Widgets: active power-up chips sit next to the mechanic chip with their
  own countdown shrink. Spawn pickup sprite = the power-up's icon in a
  neon capsule.

## Version
- projects.json: 0.3.6-1 / version_code_base 30680 (arm64 30682, arm32 30681).
- Registry desc + controls updated (score /50, spikes, power-ups).
- gf_probe: new laws for every item above; ALL PASS. flow_test pass.
- QA rigs (Xvfb): before/after shots - tails, landing, death, power-ups,
  coin size, stick mode. Owner gets the patch; no release (THE LAW).

## ship record
- [x] every item implemented + law-named in geometry.gd
- [x] gf_probe 73/0, gf_replay_repro CLEAN, gf_soak CLEAN, flow_test + all
      game probes green (invaders shelf count made save-state proof)
- [x] qa_v036p1 12 Xvfb rigs eyeballed (tails behind / none dead / landing
      ring / collect implosion / death layers / the three powers + chips /
      the 44px coin / the power shop rows / stick_roof at y=342)
- [x] version 0.3.6-1 / 30680 (arm32 30681 / arm64 30682), cert 6db87aca...
      unchanged; APKs backed up to the download folder
- [x] pushed a266edb, CI run 34168216706 GREEN, NO release (the law)
