# MAZE ESCAPER — the owner's GDD, v0.3.7 (from the owner's message)

> The PGB v1.3.8 "Escape The Maze" reborn (the owner: it was bad — the
> algorithm felt like "one single path with background noise"). The name is
> **Maze Escaper**. The character is GEOQUARE (the Geometry Flash square,
> the blue one). The theme is NEON like the Geometry Flash world.

## 1. THE RUN

- Horizontal, landscape. Each map = one maze; escaping = **+1 score**.
- **Score bonus /3** (registry coin_div 3). Fee 10, price 350, direct
  reveal, needs_games 2 (the graduation ritual, matcher style).

## 2. THE REAL MAZE LAW (the algorithm remake)

- **Wilson's algorithm** (loop-erased random walks → a UNIFORM spanning
  tree): every corridor is honest, the dead ends are real, the texture is
  genuinely branchy — never "one path with noise".
- Probe-asserted: every cell woven in (the UST property), the dead-end
  ratio ≥ 16%, the solution a winding thread (never shorter than the
  manhattan span).

## 3. THE RANDOM ENDS LAW

- The start AND the exit roll EVERY map (the python game's same-two-corners
  sin is dead). The exit lives in the far BFS band (≥ 62% of the deepest
  travel), so every map demands real reading.

## 4. THE SCALE LAW

- Maps grow: +1 col every 2 maps, +1 row every 3. The cell shrinks to fit
  the board area (every pixel used, centered) — but never below the
  MIN CELL (40 design px); past that the grid CAPS (the owner's limit).

## 5. THE TIME LAW (the enemy)

- Time and scale are the only enemies (the python enemies were trash — no
  enemies for now). Each map's budget = 10s + 0.8s per solution cell
  (clamped 24..99). The timeout ends the run.

## 6. THE SWIPE LAW (the movement)

- One swipe = one queued step (TouchKit). The queue animates grid by grid
  and the animation SPEEDS UP as the queue grows (5.5 → 12 cells/s) —
  fast fingers flow, the square never teleports. A wall eats the input
  with a visible red cell flash.

## 7. THE COIN LAW

- Every 5th map a GOGACoin waits ONE OR TWO BFS-steps OFF the solution
  path — reachable, a detour, never exposing the direct route.

## 8. THE PATH FINDER (the helper)

- Shop item (standalone, 450). Earns **one charge every 2 maps** (the PGB
  design, `wins // 2 - used`). The HUD button next to the widgets shows
  the charges; tap = 8s window lighting the NEXT 8 solution cells with a
  live countdown — same way, but better.

## 9. THE SHOP

- 5 square skins (GEOQUARE free / ember / toxin / ghost / prism — the
  Geometry Flash skin set), 3 maze themes (midnight free / solar / violet
  — the walls' light), the PATH FINDER.

## 10. THE FEEL

- The gf_bg shader sky (the maze themes tint it), neon wall strokes with a
  dim glow bed, the exit portal breathing, Geoquare faceless. SFX + theme
  synthesized in the geometry voice (v037_maze_audio.py).
