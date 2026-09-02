# PLAN v0.3.1 — the XO/slasher patch + CURSED DARIO reborn

The owner's order: 1) FUTURE_GAMES.md, 2) the patches, 3) dario's docs,
4) the asset hunt, 5) the game.

## FUTURE_GAMES.md (done first, per the owner)

- [x] the horizontal-action companion note under the party-dash entry
- [x] the dump: the Ben 10 runner, Dan the Man, Crossy Road, the four
  STUDY entries (Offline Games app, Cooking Mama, BabyBus, Good Pizza +
  idle), Where-Water, Goods Sort, Stack Sort, Happy Glass, State.io,
  Fire Ball 3D, Minesweeper

## The patches (the owner's "accurately" list)

- [x] XO: the marks are ~74% of a cell now (was 155%!) — the before/after
  Xvfb shots confirm they sit inside the cells
- [x] Slasher: the vegetables grow past the fruits (150px target — their
  painted art sits smaller in its canvas)
- [x] Slasher: BOTH positions toss from the bottom; the landscape spawns
  around the CENTER with a wide spread (the left-to-the-bottom weirdness
  is dead); the row pattern became a wide bottom row there too
- [x] Slasher: the slice glint is GONE ("we have our own finger-slasher
  thing") — the blade ribbon is the only effect
- [x] Slasher: THE DYNAMIC SWIPE VOICE — the whoosh was analyzed (0.16s,
  the swell peaks ~55-75%, ~12k zc/s brightness) and rebuilt as FOUR
  speed cuts (lo/med/hi/fast: darker-longer to brighter-shorter); the
  swipe speed picks the cut + a pitch nudge; a voice never restarts
  while audible
- [x] The slasher thumbnail recomposed to the CURRENT look (the wood
  board, the classic fruits, the split apple with its real halves, the
  juice, the coin, the boom)

## CURSED DARIO (the rename + the rebuild)

- [x] THE LORE (dario.md): the Witcher's curse, the ten levels, the boss,
  the shot from behind, the forever-cursed replays with deja vu
- [x] The registry: title Cursed Dario, fee 100 (!), coin_div 10, shop
  true, the new desc/controls, the achievements (Heel of the Hero 100
  stomps, Witcher Slayer, The Escape That Wasn't all-10)
- [x] The game (dario.gd rebuilt): the tile grid from 10 hand-authored
  maps, the hand-rolled AABB physics, the snowy-tower controls (the left
  half walks, the right taps to jump), the enemy roster (snail +10 /
  fly +15 / spitter +20 / blocker 3-stomp shield +25 / spiky timing +30),
  the ? blocks (5 coin boxes a level, power boxes live ONLY when the
  powerup is owned, else the block is EMPTY), the powerups (STRONG FOOT,
  THE SHIELD, POWER JUMP at 1000/1200/1000), burning platforms, moving
  platforms that carry, pits, 3 lives with the -200 floored death and
  the same-level restart, the door progression, the Witcher (20 stomps,
  aimed curses, +100), THE ENDING (the escape run, the shot from behind,
  the final line), the dialogue (the L1 box, 10s story pops per level,
  the end-of-level lines, the cursed replay pool), the night theme
  (the sky + the crescent moon + stars + the tile tint), the banner
  raised above the strip
- [x] THE ASSETS: the CC0 Kenney Platformer Art Deluxe from OGA (the
  alien hero with walk frames, the fly/snail/blocker, the grass/dirt/
  brick/? boxes/spikes/door/castle tiles, the plants/torches/fences, the
  coins, both backgrounds) + the painted-to-style pieces (the Witcher 2
  poses, the three powerup icons, the curse bolt, the crescent moon)
  + twelve designed voices (tools/v031_sfx.py)
- [x] tests: dario_probe.tscn NEW (37 checks: the economy, the ten maps,
  the physics, the stomp table, the blocker shield, the death law, the
  door law, the boss law, the night equip); flow_test/xo/merge/slasher
  probes all green
- [x] Xvfb qa_v031 eyeballed (the marks, the portrait, the bigger vegs,
  the day level, the blocks, the night, the Witcher) — caught THREE real
  bugs (the enemies born spriteless, the Witcher spriteless, the enemies
  floating off the ground; all fixed) + the moon crescent repaint
- [x] Version 0.3.1 (base 30400: arm32 30401, arm64 30402)
