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
