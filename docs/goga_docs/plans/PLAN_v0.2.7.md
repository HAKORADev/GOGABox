# PLAN_v0.2.7 — the tower verdict round II + 2048 reborn

Owner feedback after playing v0.2.6 on device. Two work fronts: finish the
tower (bugs + new platform kinds + difficulty) and rebuild 2048 into a real
game with a theme shop. Every item below is quoted/deduced from the owner's
message; the probe + Xvfb laws pin each one.

## A. SNOWY TOWER (hopper.gd)

1. **Coins invisible** — root cause: the tower NEVER DREW them (the coins
   array fed collection logic only; no painter touched coin.png). The QA
   shot 06 parked a coin and eyeballed nothing. FIX: a real pickup painter —
   the snake law (the REAL coin.png asset) + fade-in (alpha+scale ramp over
   ~0.35s) + bob. Powerup pickups were ALSO invisible (same bug) — they get
   a glyph capsule painter with the same fade law.
2. **Empty widget between speed and coins** — the always-present empty MELT
   chip (add_hud_chip("")) sat between the speed chip and the coins chip.
   FIX: the chip hides when melting is OFF (HBoxContainer skips hidden
   children — no gap). The powerup widget moves TOP-LEFT next to the score
   (owner: "make it to the left next to score").
3. **No powerup ever spawned** — root cause: `next_pick_idx` initialized 0
   and the `next_idx > 4` guard skipped the branch at idx 0..4, so
   next_pick_idx stayed 0 forever and `next_idx == next_pick_idx` never
   matched again. FIX: the owner's law — one random powerup every 20-40
   platforms counted from the LAST SPAWNED (on-screen) powerup; first one
   20-40 up; initialized properly.
4. **Banner in the tower** — the v0.2.6 law is reversed by the owner: the
   tower wears the banner like every other game. Registry `"banner": true`;
   the fall-death line insets above the strip.
5. **Break effect static** — the vanish crack was 3 fixed lines. FIX: a real
   break — progressive jagged cracks (deterministic per idx) that grow with
   the grace clock, debris chunks popping off while it cracks, then the
   platform SHATTERS into 4-6 physical chunks (gravity, spin, fade) sized by
   the platform's own width. New SFX tower_break.
6. **Blink snow mismatch** — snow stays on invisible blinking platforms and
   the owner wants snow to appear/disappear WITH the platform. FIX: going
   invisible stashes the cap (`snow_stash`) and zeroes it; reappearing
   restores it. The cap is only ever drawn on a visible platform.
7. **Shard (triangle) physics broken** — root cause (math): the settle
   target ±1.094 rad puts a SIDE ON TOP, not on the ground — the triangle
   "rested" balancing on one corner, hoisted by the support law ("not
   landing on its sides"). FIX: the true edge-down stance is
   ±(π − φ), φ = atan2(edge_h, edge_w) ≈ 2.047 rad; the tumble pivots over
   the ACTUAL lowest vertex (dynamic pivot radius), settle eases onto a real
   flat side and slaps it.
8. **NEW: size platforms (30+)** — width oscillates smoothly wide↔small
   (sine on a per-platform clock, 0.55..1.30 of its base width, the drawn
   cap follows). Reliable type, wall-clamped at max width.
9. **NEW: dropper platforms (50+)** — landing on one triggers a drop: it
   accelerates down out of the screen, waits, then rises back to its spot.
   The rider rides it down (jump off in time). Unreliable type (the
   reliability law protects the next platform).
10. **Difficulty at 25+** — "after 25 platforms start making jumps wider":
    the vertical gap ramps toward the character's real jump ceiling and the
    horizontal spread widens with a descending-branch reach law (the time
    when a rising jump CROSSES a higher platform on the way down). Real
    timing: full-speed runs + late jumps.

## B. 2048 (merge2048.gd — rebuilt)

The shipped 2048 was a stub: hardcoded top-left board (27,250), tiles
teleported (the bookkeeping freed the source and respawned at the
destination — the "tween" branch almost never fired), score = merge-value
sum, coins auto-granted per big merge, no shop, no themes.

1. **Layout**: the same 4x4 grid, centered and BIGGER (viewport-computed,
   banner-aware); a cool backdrop matched to the grid.
2. **Controls**: swipe any direction (TouchKit.swiped — stays), plus a
   slide SFX and a board nudge for feel.
3. **Score**: each successful fusion = exactly +1. Run bonus = score/20
   (registry coin_div 150 -> 20).
4. **GOGACoin cells**: after every 15 fusions one empty cell grows a REAL
   coin (coin.png, fade+sparkle). Slide any tile INTO that cell to take it.
   Board full when due -> it waits for the next freedom.
5. **Animations/effects (better than the PGB python one)**: tiles keep their
   identity and TWEEN (real slides), merge pop + ring + square-chunk
   particles with gravity that bounce off the board frame, floating +1,
   golden board pulse on 128+, a game-over gray-out cascade, 2048 win
   burst with endless play after.
6. **Shop (THEMES)** — registry shop: true:
   - **Classic** (free default): the warm beige board on a deep cool slate.
   - **Minecraft** (800): stone-block backdrop, dirt-grid holes, block-face
     tiles with deterministic pixel noise (grass/wood/stone/iron/gold/
     diamond tiers), lava-glow numbers on hot tiers + ember VFX, stone thud
     / lava pop SFX.
   - **Sea** (650): deep blue everything; tiles are glass cells with REAL
     animated water inside — a per-tile shader (fill = the tier, light blue
     water that sloshes with the tile's velocity while it slides, splashes
     droplets on merge), splash/slosh SFX.
7. **End**: no more moves ends the run (kept law, now with the cascade).
8. **Thumb**: scene_merge recomposed to the new look (cool bg, centered
   board, hero glow, a coin cell).
9. **Guide**: registry desc/controls rewritten for both games; tower.md
   journal grows the v0.2.7 chapter; merge.md journal created.

## C. Ship

- version 0.2.7 (base 30360: arm32 30361, arm64 30362)
- probes: tower_probe + NEW merge_probe + flow_test suites; ALL PASS
- Xvfb QA sheets for BOTH games BEFORE shipping (owner rule)
- build dual ABI, cert check, backup to /home/z/my-project/download/,
  commit, push, watch CI green.
