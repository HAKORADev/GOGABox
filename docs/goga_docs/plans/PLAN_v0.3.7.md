# PLAN v0.3.7 — the GEOQUARE update (patch 3 shipped apart; this is the big one)

## 1. THE LORE (geometry flash)
- The Geoquare lore box: a square that escaped the Matrix, cursed to loop
  back to the beginning, referencing Snowy Tower (the ice-cube years) and
  Maze Escaper (next on the escape list). First launch EVER only.
- The square is GEOQUARE now: geometry's CLASSIC -> GEOQUARE; Snowy Tower's
  Ice Cube -> Geoquare (the lore crosses both shops).

## 2. SNOWY TOWER: THE GEOMETRIC STYLE
- A new STYLE category in the tower shop: SNOWY (classic, free) and
  GEOMETRIC (1200 - the priciest thing on the shelf).
- The style re-skins the WHOLE mountain live: the matrix palette (sky
  shader + modulate), neon block platforms (the GF block anatomy), the
  faceless Geoquare cube for every character, neon diamond dust + golden
  stars instead of snowflakes, the golden-orbit coins, its own synthesized
  theme (tower_geo_theme.ogg) + the geo_* SFX voice (11 sounds).

## 3. MAZE ESCAPER (the new game)
- Wilson's real-maze algorithm; random start/end (BFS-far band); the scale
  law (grow + shrink + the MIN CELL cap); the time law (10 + 0.8s/cell);
  the swipe queue with the dynamic speed; the coin every 5th map 1-2 steps
  off the route; the PATH FINDER (charges per 2 maps, 8s window, 8 cells);
  the shop (5 skins / 3 themes / the finder); score /3; +1 per map.
- Neon everything (the gf bg shader), synthesized audio, composed thumb.

## Version
- projects.json: 0.3.7 / version_code_base 30800 (arm32 30801, arm64 30802).
- flow_test: 14 playable / 1 teaser + the maze registry laws + the queue
  retirement; maze_probe; the tower style laws; the gf lore laws.
- NO release (the law) — push, CI green, the owner tests everything.
