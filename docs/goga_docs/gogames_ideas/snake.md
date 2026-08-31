# snake.md — the GDD journal

## 2026-08-31 04:20 — the journal starts (the snake as it shipped v0.1.7)

The classic, arcade edition, exactly as it lived from v0.0.x through
v0.1.7 — written down here so the journal has a "before":

- **Pitch**: steer the snake, eat apples, grab GOGACoins. Every apple makes
  you longer and faster; walls and your own tail end the run.
- **Core loop**: grid steps (16×24 cells @ 44px, one cell per tick,
  `step_time` 0.16s ramping to 0.075s with score), swipe steering in 4
  directions, 180° reversals ignored.
- **Economy**: apple = +1 score; coin pickup = +1 GOGACoin; `coin_div 2`
  score bonus at run end; entry `fee 10` with `partial_pay` (thin wallet
  pours everything); SHOP with 4 skins (classic 0, lava 120, ice 120,
  gold 300) — head_/body_ PNG sprites.
- **Scene**: fixed hardcoded board (704×1056) centered in the viewport,
  dark green panel; death = the WHOLE world modulate-flashes red 3×.
- **Achievements**: score 30/60/100, 100 coins total.

## 2026-08-31 04:20 — v0.1.8 THE SMOOTH MAKEOVER (owner directive)

Owner's words of direction: work on snake, make it smooth "with this good
minimal but amazing assets and particles with satisfying SFX and a music
for it" (reference screenshot = warm cream/peach minimal scene, cute bold
shapes, glowing collectible — lives & gun explicitly ignored). Everything
below is the contract for v0.1.8.

### Movement — grid is dead
- Continuous smooth motion. The head owns a heading (radians); the body is
  a trail: points are recorded along the head's path and the body is drawn
  along that trail — steering bends the whole body with zero snapping.
- Steering = HOLD THE LEFT / RIGHT HALF of the screen (dario's proven
  hold-halves pattern) at a capped turn rate, so the body always flows.

### Growth — small and thin, wide with a limit
- Starts small and thin. Every apple adds body LENGTH and a little WIDTH.
- Width growth is capped (owner: "not wider too much, wide with a limit").
- Speed still ramps gently with apples (classic DNA, smooth now).

### Color — blue melting into milk (owner's design)
- The snake is BLUE, and the transition of the color along its body toward
  MILK stretches as the snake gets longer: a short snake is mostly blue, a
  long snake carries a long blue→milk gradient down its body. The gradient
  length is a function of current body length.
- Skins survive as palettes over the SAME gradient system (classic =
  blue→milk; lava / ice / gold get their own primary→milk pairs), so the
  shop and owned skins keep working.

### The apple — designed entrance/exit, no literal alpha fade
- Spawn: pop-in (scale overshoot + one soft ring pulse). Idle: gentle
  breathing pulse. Eaten: instant pop with a particle burst — no "fade"
  anywhere in its life.
- The GOGACoin pickup keeps its rules (+1 coin, spawn chance after apples)
  and gets the same pop-in language.

### Death — flash the SNAKE ONLY (owner fix)
- The old death flashed the whole world red. Now ONLY the snake's body
  blinks red (× eyes included), a small puff at the head, then the run
  ends. Everything else stays untouched.

### The tongue
- A forked red tongue flicks on a soft random timer, and leans out when an
  apple is close ahead. Pure charm, zero mechanics.

### Scene — full screen, both orientations, chosen at load
- The hardcoded small board is dead. The field is the FULL screen (under
  the HUD, above the banner strip when a banner is on).
- Portrait AND landscape are supported; the mode is chosen ONCE when the
  game loads, before the run starts (registry `"orientation": "auto"` —
  the host reads the real window shape at load and locks it). Owner note:
  more snake work is coming later, so this structure is the floor, not
  the ceiling.
- Field look (the reference feeling): warm cream/peach field, soft deco
  blobs, rounded wall line, bold readable shapes, everything with a soft
  rim so color always reads.

### Ready state
- When the game is ready it says "TAP ANYWHERE TO START"; the first tap
  starts the run. Snake idles (breathing, tongue flicks) on the ready
  screen.

### Audio
- Satisfying SFX set of its own: juicy eat pop (pitch rises with length,
  the classic dopamine trick), soft die, start blip; coin keeps the box
  coin sound.
- A dedicated music loop for snake (warm, minimal, loops seamlessly),
  played only inside snake runs — the box theme stays box-only, per the
  v0.1.1 rule.

### Economy — unchanged
- Apple = 1 score, coin = 1 GOGACoin, fee 10 partial-pay, `coin_div 2`,
  achievements untouched. The makeover is feel-first, not economy-first.

### Open questions (for later sessions, owner asleep)
- Boost button? (slither-style hold-to-dash) — parked.
- Portal walls vs deadly walls — walls are deadly today; owner never asked
  to change it.
- Skins shop refresh with named palette swatches in the sheet — parked.

## 2026-08-31 04:52 — v0.1.8 SHIPPED: implementation notes + the look pass

Everything in the 04:20 entry is now real, plus what building it taught:

- **Structure**: the whole game is ONE view node; `_paint()` draws field,
  deco, walls, rings, coin, apple, then the snake (tail first, head on
  top). State: heading + trail (`Array[Vector2]`, newest last, trimmed to
  body length); body = arc-samples every 11px with a taper to a fine tail
  tip; head = 1.22x disc with eyes (+ x-eyes on death) and the tongue
  UNDER the head disc.
- **The gradient, tuned**: the transition IS the body - gradient length =
  0.96 x body length, so a baby snake is a full blue->milk sweep and a
  long snake carries a LONG sweep. (First attempt had a fixed-ish
  gradient longer than the body - the tail never reached milk. The
  owner's sentence, re-read literally, fixed it.)
- **Width/growth**: starts 26 design-px wide, +1.6/apple, hard cap 64
  ("wide with a limit"). Length +70/apple, eases toward the target so
  growth looks smooth. Speed 430 -> +6/apple -> cap 880.
- **Self-bite fairness**: neck arc ignored (2.2 x width + 10px), bite
  threshold 0.58x(head+body radius) - forgiving on curves, honest on
  loops.
- **Visual QA loop**: captured REAL rendered frames via the v0.1.6 Xvfb
  harness (rewrote snake_drive for the smooth era: tap-to-start, steer at
  the apple, wall avoidance via board-center aim, quiet respawn) in BOTH
  orientations at native res. Fixes driven by looking: circle spacing
  16->11 (beaded -> silky), deco blobs quieter (6, alpha .38), coin 54px,
  eyes bigger.
- **New test**: tests/snake_probe.tscn boots a real run headless, starts
  it, steers it, force-eats an apple, caps width, executes the whole
  paint pass via a real redraw, then wall-crashes and asserts the
  finish_run handover + music stop. ALL PASS, geometry probe PASS,
  flow_test ALL PASS.
- **Juice inventory**: eat burst (red/milk/blue motes + ring), coin
  sparkle, death puff + snake-only red blink x3, apple pop-in with ring
  and breathing idle (BACK ease, no alpha fade anywhere), tongue flicks
  on a 1.4-2.8s timer and when an apple is near ahead, TAP ANYWHERE TO
  START card pops in and pops out.
- **Shop**: same 4 skins, now palettes over one gradient system - classic
  renamed "Blue Melt" in the sheet. Bought skins keep working.
- **Music**: 9.6s seamless warm lo-fi loop (Cmaj7-Am7-Fmaj7-G7, cycle-
  locked frequencies so the waveform itself is seam-continuous), starts
  with the run, dies with the run. Eat/die/start SFX synthesized in
  tools/snake_audio.py (re-runnable).
