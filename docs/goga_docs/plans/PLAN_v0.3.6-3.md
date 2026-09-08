# PLAN v0.3.6-3 — GEOMETRY FLASH patch 3 (the owner's 11-item report on patch 2)

Owner test report on v0.3.6-2, verbatim laws. Geometry is easier to move fast
on than Pop Siege — the owner says make the WORLD the star this round: more
obstacles, more blocks, cool shapes, zero empty feel, zero idle-tap sim.

## 1. THE /50 + /10 TRUTH (the misunderstanding, undone)
- The patch-1 "score bonus /50" was the BOX score bonus (the dead-menu
  "score bonus S/D" line = registry coin_div). It was never touched —
  geometry still pays /4. FIX: registry coin_div 4 -> 50.
- The speed step was NEVER the ask — revert SPEED_BONUS_AT 50 -> 10
  (x1.1 every 10 points, the v0.3.6 cadence the owner liked).
- Registry desc/controls + in-file law comments updated to match.

## 2. THE NONE ROW COLOR
- With a tail worn, the NONE row reads "NONE - TRAIL OFF" in BROWN — brown
  is the "currently in use" color, so none looks worn. FIX: violet 8a4ab8
  (the non-used item color). The action stays: tap none to remove the tail.

## 3. THE TAIL BACK LAW
- The tail emitters offset rotates with the square (the flip swings the
  trail overhead/underfoot). FIX: the offset is ALWAYS screen-left (the
  world-scroll back side) no matter the square's rotation or gravity.

## 4. THE WHITE-TAIL REPLAY BUG (root caused)
- Every replay boots a FRESH game instance: _goga_setup -> _build_world()
  calls _apply_tail() while trail_mode is still the default "none" (the
  emitters get reset to plain WHITE p_soft config), then _load_meta() sets
  the real tail but never re-applies it; _ready_start() flips emitting=true
  with the stale white config. First run only looked right because the
  owner's shop visit re-applied. FIX: _load_meta() ends with _apply_tail().

## 5. THE ROCKET SIMPLICITY LAW
- The jump-power burn was a constant plume under the square. FIX: much
  simpler, fires ONLY on each jump, and SIDE-AWARE — it pours from the
  face the square jumps OFF (below when leaving the ground, above when
  leaving the roof). Skin-colored, one-shot, gone in ~0.35s.

## 6. THE FLIP PUSH + THE COLLECT TRUTH
- FLIP's gravity switch VFX was a radial burst ("weird looking"). FIX: a
  simple push puff from the side being LEFT — under the square when it
  launches off the ground, above when it launches off the roof.
- Orbit collect was the "implosion" the owner still calls bad. FIX: a
  proper COLORED particle burst — golden soft-glow pop + white star
  flashes + a light ring. Juicy, simple, readable.

## 7. THE COIN SPACE LAW
- The coin spawn never checked the world — it could sit inside a block,
  a line or a hazard. FIX: every candidate (lane x y) is validated against
  pushers/lines/hazards/orbits; blocked candidates re-roll; a fully crowded
  window defers the spawn 2s instead of forcing a bad coin.

## 8. THE THUMB REDO
- The old thumb is dark, sparse and stars the big ugly triangle. R1/R2
  hold (960x640, no text). New composition: the REAL world look — block
  staircase up to a line, the square mid-jump with its tail streaming,
  the NEW small triple spikes below, the golden orbit arc, gentle glows.

## 9. THE WORLD LAW (the big one)
- spikes3: the spike becomes THREE SMALL triangles on a surface base —
  new art + a WIDE-SHORT hitbox, length calculated so a normal hop clears
  it from anywhere (dodge-able by construction). The old big triangle
  becomes a rare high-level wall threat.
- BLOCK STRUCTURES from stacked block columns (the pusher cell generalized
  into a column primitive): STAIRS UP (2-3 steps + orbit path + a floor
  threat under the far side), STAIRS DOWN (the climb-down the owner
  missed — plateau then descending steps), PYRAMID, TWIN TOWERS (two 2-cell
  columns with a hop valley), BLOCK GARDEN (rhythm singles), BRIDGE (elevated
  deck over an open underpass). Weight rebalance: structures are COMMON from
  level 0; the world stops feeling empty.

## 10. THE CLIMB TRUTH (block-landing glitch)
- Root cause: the spin predictor (_flight_lands) only knows ground/roof/
  lines — a jump onto a block spins for the FULL fall, lands mid-rotation
  (the non-perfect angle), and the face-shove fights the next hop. FIX:
  a) _flight_lands learns pusher tops/bottoms -> the 90 completes exactly
     at touchdown on ANY block.
  b) THE CLIMB SNAP: rising feet just below a block top (a small band)
     snap ONTO the block instead of shoving — climbing feels clean.
  c) The shove keeps guarding real face-hits (walls still push, never kill).

## 11. THE STREAK RESET LAW (the pitch ladder)
- The collect blip pitch climbed forever (never reset). FIX: 2.0s with no
  collect starts the decay — one level down every 1.0s, the final drop to
  0.0 after 0.5s, then the ladder is from the start. A collect during the
  decay stops it and plays the current level.

## Version
- projects.json: 0.3.6-3 / version_code_base 30700 (arm32 30701, arm64 30702).
- GDD (geometry.md) + registry desc/controls updated to the new laws.
- gf_probe: every law above assertable headless; replay repro + soak re-run.
- qa_v036p3 Xvfb rigs: before/after shots eyeballed.
- NO release (the law) — push, CI green, owner tests the APKs.

## ship record
- [x] 1: registry coin_div 4 -> 50 (THE /50 TRUTH) + SPEED_BONUS_AT 10 + the
      desc/controls text + probe laws (the /10 TRUTH x2 + the constant)
- [x] 2: the NONE row violet (THE NONE COLOR LAW, probe-asserted + shot)
- [x] 3: the tail offset never rotates (THE TAIL BACK LAW, probe + shot at
      137deg: the trail is still screen-behind)
- [x] 4: _load_meta -> _apply_tail (THE WHITE-TAIL LAW; replay repro boots
      run2 with gold and the emitter wears GOLD - 3 probe laws)
- [x] 5: the rocket one-shot ON the jump, side-aware (probe: below on the
      ground / above off the roof; shots: the burn at the takeoff point)
- [x] 6: the flip push puff (side-aware, probe + shot) + the golden collect
      burst (probe + shot)
- [x] 7: THE COIN SPACE LAW (probe: 40 spawns all clear + the crowded
      horizon defers with its own retry clock - _coin_clock no longer
      clobbers the defer)
- [x] 8: the thumb recomposed (the built world: staircase, mid-jump square
      + fire tail, spike3, orbit arc, coin, pusher)
- [x] 9: spike3 (art + WIDE-LOW box + the dodge law) + the block structures
      (stairs/garden/pyramid/descent/twin/bridge/roof_stairs) + the weight
      rebalance from level 0; the shape battery probe (7 checks)
- [x] 10: THE CLIMB TRUTH - _flight_lands learns blocks; THE CLIMB SNAP;
      THE LANDING BAND (the same-frame touchdown lands); THE SPACE TRUTH
      part 3 (the support check's screen-vs-world pusher span - the deep
      mid-run block bug); the under-bonk + the down-bonk; probe: the flight
      lands ON the block, the 90 completes, the jump OFF works at once
- [x] 11: THE STREAK RESET LAW (probe: 6 laws covering the exact cadence)
- [x] gf_probe 104/0, gf_replay_repro CLEAN (+ the white-tail battery),
      gf_soak CLEAN (5 seeds; the /10 cadence visible: x1.10/x1.21/x1.33),
      flow_test ALL PASS (coin_div 50 asserted), cs 197/0, pd ALL HOLD,
      dash/invaders/matcher/slasher/merge/dario/tower/pong ALL PASS (exit 0)
- [x] qa_v036p3: 12 Xvfb rigs eyeballed (stairs/garden/world/roof_stairs/
      spike3/tail_back/rocket/rocket_roof/flip_push/collect/coin/none_violet)
- [x] version 0.3.6-3 / 30700 (arm32 30701 / arm64 30702); NO release (the
      law) - pushed, CI green, the owner tests the CI APKs
