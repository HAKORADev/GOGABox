# PLAN_v035p2.md - POP SIEGE PATCH 2 (the wheel patch)

The owner's v0.3.5-1 report: 20 items. Every item lands here with its law.
Version 0.3.5-2 / version_code_base 30620 (arm32 30621, arm64 30622).

## The bug laws (items 1, 2, 4, 6, 7, 8, 10, 11, 12, 13, 14, 15, 17)

- THE CLOSE LAW: THE SHOP + THE MAPS wear their own red X (head row, top right).
- THE FAT BUY LAW: the coin BUY buttons grew to 210x56 with a 28px coin - the
  icon never leaves the box again; the maps wall price icons grew too.
- THE DRAG LAW: placement works by TAP-TAP (card, then grass) AND by DRAG
  (press a card, move 26px, the ghost rides the finger, release places). The
  card's Control ate every drag before; the raw stream now carries it, and
  TouchKit's tap window grew to 520ms so a slow deliberate tap still counts.
- THE PIVOT LAW: the gadget head rotates around its MOUNT (offset draws the
  texture above the pivot) - the body-steering glitch is dead.
- THE NO PAUSE BUTTON LAW: the HUD wears SHOP + MAPS only; back opens the
  pause sheet (it always did the same thing).
- THE POP PAY LAW v2: a PopCoin per DAMAGE dealt (the red popped from one hit
  pays exactly 1). Armor damage pays too. Score = damage dealt.
- THE WAVE-START LAW: no firing without a target in range - with the range fix
  the across-map pre-wave snipe is gone.
- THE BUTTON TRUTH LAW: at level 10 the UPGRADE button disappears (GEAR UP
  takes the slot); a maxed folk shows THE FINAL GEAR and never a fake price;
  every door grays LIVE when the purse cannot open it (repaints on coin change).
- THE LIVES FLOOR LAW: the chip reads 0, never negative.
- THE DEATH MENU LAW (the headline bug): `_game_over` pre-set `over = true`,
  and `finish_run` bails on `over` - so `request_finish` never fired and the
  death menu NEVER surfaced. `over` now belongs to finish_run alone.
- THE A/M TRUTH LAW: the restored mode now PAINTS on boot (`_paint_am` after
  the button build) - the old build showed AUTO while the ledger said MANUAL.
- THE RANGE TRUTH LAW (the big one): `_recompute_auras` multiplied rng by
  CELL * CELL (56 * 56 = 3136px per cell) - EVERY shooter was omniscient,
  the "map brightened" fill was a 7000px range circle. eff_rng = cells * CELL.
  Longeye keeps a long but finite 7..8.2 cells.
- THE AIM LAW: the head tracks only for 0.4s after a real shot (aim decay),
  and the target search runs only when the cooldown is ready.

## The first wave (item 3)

- THE FIRST WAVE LAW: wave 1 NEVER rides a countdown - AUTO or MANUAL, the
  owner opens every siege with the SEND WAVE button. AUTO's clock exists only
  BETWEEN waves (tick gated on wave_n >= 1). MANUAL has no timer at all. The
  first send pays no early bonus (there was no timer to beat).

## The difficulty system (item 20)

- THE WHEEL LAW: bloons wear COLOR LEVELS 1..12. Level L cracks for
  base_hp + (L - 1) - the owner's exact ladder (red 001 = 1, 002 = 2, 003 = 3;
  the body's total is the pyramid 1+2+3). The over-damage spills into the next
  ring. Art: 8 wheel-recolored variants per kind (a visible hue step per level,
  generated in v035p2_pop_art.py), levels 9+ reuse the 8th.
- THE STRIPS LAW: a striped bloon hides one bloon per band (25% chance of a
  second) of the band's color; balloons carry up to 10 bands, blimps up to 50;
  the counts NEVER show. Inner bloons can wear strips of their own (depth 2,
  from wave 21). Bands draw at runtime (StripDraw) in the strip's kind color.
- THE ARMOR LAW: metal (fears ONLY fire) from wave 22, rock (fears ONLY
  bombs) from wave 26. The shell eats the hit first; the wrong class CLINKS
  for nothing. Blimps wear fat shells (20 + 0.6/w hp vs 2 + 0.12/w).
- THE THREAT LAW: a leak costs the FULL chain + the level armor + the hidden
  strips (PDData.threat) - leaking a stripped blimp is catastrophic.
- THE CLIMB LAW: the wave budget grew to 60 + 26w + 4.2w^1.85; spacing
  tightened; group caps grew (80 -> 220 past wave 20); milestones: 10 = MOAB,
  20 = 3 MOABs, 30 = BRUTUS, 35 = GARGANTUA, 40 = TITAN + 2 BRUTUS.
- THE BLIMP TIERS: shapes are tiers - moab (T1) -> brutus (T2) ->
  gargantua (T3, the twin-gondola fortress, 2600hp) -> titan (T4, the
  triple-fin leviathan, 9000hp, half sharp). Colors/stripes are contents.

## The grid maps (item 20)

- THE GRID LAW: the roads ARE grid cells now (the owner: "everything else is
  grid based" - the spline ribbons are dead). Paths march cell to cell,
  chaikin-relaxed (resample then (1,2,1) windows - no measured hop turns over
  54 degrees), and paint as FULL CELLS with merged rounded corners.
- The 30 maps wear 9 archetypes: snakes, TRUE grid spirals (rings 2 cells
  apart), grand loops (single + double), combs (every OTHER column), twin
  merges, split-rejoins (2 + 3 branches), bendy crosses, the 3-lane WIDE
  HIGHWAY (three parallel paths, the wide line that fits 3 bloon lines), and
  the 3-door FORTRESS (the last siege). Per-map mirrors keep same-archetype
  maps from reading the same.
- THE RICH BOARD: props wall 36-46% of the free land (every road cell keeps at
  least one buildable side), water pools per theme, and the whole grid matters.
- THE ENTRY LAW: doors sit off-board with worn trails + chevron arrows painted
  on the ground (the black spawn pockets are dead - the owner's ground-line
  idea). Every path's last cell is the heart.
- road_cells ship in the map data - one source for paint AND build blocking.

## The economy (items 8, 18)

- Purse 650 (per-damage pay opens smaller early). Place prices 200..800.
- Upgrades: up_base x2.2..2.5, ladder pow 1.13 -> 1.22.
- THE GEAR DOOR: gear 2 = 2800..4800, gear 3 = 8800..15000 - the very very
  expensive jump the owner demanded.
- Kaching: income 90/150/220, interest 8%, egg 900 (it must compete with the
  richer pops). Early-call bonus 25 + 5*wave.
- THE SELL LAW: 70% of EVERYTHING invested (place + upgrades + gears), the
  ledger lives on the folk.

## The siege engine (item 19)

- THE 60 LAW: run/max_fps = 60 in project.godot.
- THE CORE LAW: a bucket grid (2x2-cell buckets, rebuilt once per tick)
  serves targeting, bullet collisions, explosions, pulses, traps and storms -
  no more whole-roster scans per folk per frame. The march carries a per-bloon
  segment cache. Splashes + coin floaters cap themselves. The spawner rolls
  each entry's difficulty bands from its OWN wave.
- THE SCORE ICON LAW: a layered bloon (the bands are the layers) sits next to
  the HUD score.

## Verification

- pd_probe: 5500+ checks 0 fails (grid maps, wheel ladder, strips, armor,
  pay-per-damage, threat, A/M truth paint, first-wave law, drag law, MAX law,
  gray law, sell law, death-menu request_finish, close law, finite ranges).
- flow_test ALL PASS, cs_probe 186/0 (cosmic spud untouched).
- qa_v035p2 Xvfb rigs eyeballed: field (rings + armored march), place (drag
  ghost), maps/shop (the X), menu (the gray doors).
