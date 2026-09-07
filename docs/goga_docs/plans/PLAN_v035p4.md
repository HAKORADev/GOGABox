# PLAN v0.3.5-4 - POP SIEGE PATCH 4 (the owner's 6-item round)

The owner's report (tested v0.3.5-3, planned the next GDD while this bakes):
bomber VFX buggy + the ball floats, the pathway still fights the paint, night
misses tall things, the shop scroll jumps to the top on every buy, the doors
law was a simplification of what he asked, and the maps are still too simple
and "directly pointed to the house". His meta-demand: VISUALIZE EVERYTHING FOR
REAL - screenshot the boom's latest moments, look at the maps, test manually.

## THE LAWS

### THE FILLET LAW (item 2 - "the most annoying thing for now")
ROOT CAUSE (measured by eye + overlay): the chaikin relaxation let the march
curve drift up to ~0.4 cell off the grid center lines and bend EARLY at
corners - the paint stayed on the cells, the walk did not. The door chevrons
sat on the polyline but the polyline was not where the eye believed the road
was.
FIX: tools/v035p4_pop_maps.py replaces relaxation with the FILLET WALK:
- straight runs lie EXACTLY on cell center lines (resampled every 0.5 cell)
- every 90-degree turn = a quarter-circle fillet, radius 0.5 cell, tangent to
  both legs, INSIDE the corner cell (no drift, ever)
- one polyline per path ships in the data; the bake AND the game consume it
- THE BEATEN TRACK: the bake strokes that polyline with a soft worn center -
  the road's visual centerline IS the march line
- THE CHEVRON TRUTH: door arrows stamp ON the polyline samples (position AND
  angle from local direction) - they sit where the bloons ride and point the
  way the road bends
- THE UNIT-STEP LAW: fill_gaps normalizes every archetype output to an
  orthogonal walk (no jumps, no diagonals reach the fillet)
- THE CLEAN LINE: zero-length segments deduped (the march cache hates dupes)
PROOF: pd_probe THE FILLET LAW (every sample within 0.51 of a road-cell
center, all 30 maps), the overlay gallery, and the Xvfb field/doors rigs
(bloons ride the worn line under the chevrons).

### THE BOOM TRUTH v2 + THE SHELL TRUTH (item 1)
ROOT CAUSES: (a) the "shell" bullet never stopped at its target - t kept
counting and from.lerp(to, tt) extrapolated the bomb past the target for up
to 9 seconds while spinning (the "ball floating in the sky"); (b) the old
boom frames shrank 62px -> 18px into lingering mini-wisps with an ugly olive
ring on frame 0.
FIX: the shell sets t=9 + hides at detonation (erased same tick); new 7-frame
set (tools/v035p4_pop_art.py) on ONE 128px canvas - flash, fireball swell
with spark petals, smoke that expands and fades to NOTHING; 0.30s frames +
0.34s ring; 2.0x the blast (was 2.4x); ps_boom re-synthesized (0.42s tight
thump, fast decay).
PROOF: the qa_v035p4 boom1..boom6 Xvfb timeline (the owner's "screenshot its
latest moments" honored) - flash, fireball + ring, dissipation, and TWO clean
end frames: nothing floats, nothing lingers. pd_probe THE SHELL TRUTH.

### THE NIGHT LAW v2 (item 3)
ROOT CAUSE: the tint rect covered only the board (COLS x ROWS cells) - tall
props poked above it and stayed day-colored.
FIX: the multiply tint covers the WHOLE viewport (+shake margin); fireflies
re-seated above the tint; the heart lamp stays additive; the folk panel and
the HUD draw above (tree order + the HUD layer) so the UI never sleeps.
PROOF: qa_v035p4 night rig (stump_waltz at night: the big dead tree, the top
trees, everything past the frame - all tinted; panel bright).

### THE SCROLL TRUTH (item 4)
ROOT CAUSE: the REFRESH LAW rebuilt the sheet - the new BoxScroll started at
0.
FIX: _sheet_refresh remembers the dying sheet's scroll_vertical (per sheet
id), rebuilds, and restores after two layout frames. Shop AND maps ride it.
PROOF: pd_probe (scroll 500 survives a refresh) + the scroll rig screenshot
(scrolled to 900, refreshed, still at Marshal/maps rows).

### THE RANDOM DOORS LAW (item 5 - "i said make it randomly launch them")
The owner's words: "a wave takes 1 start line only, and another wave takes
two, third wave takes different two, 4th takes 3".
FIX: _pick_doors(wave, n): wave 1 = exactly ONE random door; then the crew
GROWS (1 + (wave-1)/3, +30% jitter, capped at the map's doors); every 5th
wave bursts from ALL doors; every wave rolls a fresh random SUBSET (Fisher-
Yates on the game rng). wave_mode "rand" in the data; the ready gate speaks
"N DOORS - EVERY WAVE ROLLS ITS OWN CREW - IT GROWS"; the registry + the
first-place toast updated.
PROOF: pd_probe (wave 1 one door, 40/40 opening singles, wave-2 crew sizes
genuinely vary, every 5th = all, members always distinct) + the doors rig.

### THE LOOP LAW + THE GROVE LAW (item 6 - "make many loops, make it cool")
New archetypes (all grid-perfect under the fillet walk):
- heart_ring: the road CIRCLES the house once before it strikes (sunny_loop,
  frog_heart)
- detour_loop: a full loop detour midway, exits downward (first_bloom,
  murk_marsh)
- horseshoe: sweeps the whole board and ends near home (dune_run, old_ground)
- double_loop: two stacked loops with a neck (obsidian_loop)
- switchback: deep long-run zigzags edge to edge (stump_waltz, snowman_march,
  ash_ridge)
- s_long: three big bends (pine_twist, scarab_s)
- claw/trident split: SEPARATE doors, each road loops, then they merge
  (crab_claw, frostbite, sugar_rush) - distinct doors for the random law
- looped twins (twin_bloom, wailing_twin, aurora_twin), the 3-door cross /
  highway / fortress kept, snakes get an honest exit
THE GROVE LAW: interiors wear family prop GROVES (3-4 clusters of up to 9
cells) + scatter fill + richer shoulder decor; ONE auto-placed pond/lava/
ice blob at the freest spot (theme decides the kind) - no more vast empty
fields.
PROOF: the 30-bake overlay gallery + the maps wall rig (the new thumbs).

## THE CARRIED FIXES
- ui_kit toast: Tween.process_mode property is gone in Godot 4.7.2 - the
  assignment errored every toast since v0.3.5-3 (cosmetic; the tween still
  ran). Now set_process_mode().
- _spawn_bloon clamps pi into the live paths (a queued spawn never outlives
  its map - caught by the probe's map-swap).

## THE NUMBERS
- version 0.3.5-4 / 30640 (arm32 30641 / arm64 30642)
- pd_probe 9479 checks 0 fails; flow_test ALL PASS; cs 186/0; slasher,
  merge, dario, invaders ALL PASS
- NO release (the law) - push + CI + the owner playtests later
