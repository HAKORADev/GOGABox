# Port notes — PGB v1.3.8 -> GOGABox v0.0.1

Source of truth for what changed vs the Python originals. PvP/2P modes were
dropped everywhere (design rule). "Endless" conversions are listed per game.

## Snake
- Original: pygame grid snake, 2P + AI modes, obstacles.
- Port: solo endless. 16x24 grid, swipe steering (TouchKit), speed ramps
  0.16s -> 0.075s per step with score. Apples = +10 score. GOGACoin pickups
  (+5) spawn ~45% after each apple. Skin shop (classic/lava/ice/gold,
  120-300 coins) driven by Box skin infra. Deaths flash then finish_run.

## Pong -> Pong Rally
- Original: classic pong, AI difficulties (easy/medium/hard), 2P.
- Port: endless survival rally. AI wobble shrinks as rally grows (difficulty
  emerges from the ramp). Ball speed +6 px/s every second forever. Score =
  returns. Drag anywhere to move paddle.

## Geometry Flash
- Original: 3-lane dodge, speed multiplier +0.1 every 20s.
- Port: same DNA, touch-first: tap thirds or swipe to change lanes, ramps
  every 8s (+0.06) — tighter loop for mobile sessions. Coins float in lanes.

## Fruit Slasher
- Original: mouse swipe fruit slicing, bombs.
- Port: LANDSCAPE (GameHost rotates the window). Combo chain multiplier while
  swiping, golden fruit = +10 GOGACoins, bombs end the run. Trail rendering
  via Line2D. Total-slashed + best-combo counters feed achievements.

## Snowy Tower
- Original: jump between platforms, one-tap.
- Port: tap left/right half to hop that direction; platforms prefill upward;
  camera follows only upward (no coming down). Height = score. Miss and fall
  = run over.

## 2048
- Original: pygame 2048 with VS mode.
- Port: solo endless swipe merge. Classic compress+merge rules, animated tile
  tweens, big tiles pay GOGACoins (v/32 for v > 64).

## Dropped on purpose
- Keyboard Singer (toy, not arcade) -> reworked into a rhythm idea, see
  Docs/ideas/BRAINSTORM.md.
- Pop TD (2300 lines pygame) -> deserves its own release cycle, stays SOON.
