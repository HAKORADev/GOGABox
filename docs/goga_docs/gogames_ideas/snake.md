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

---

## 2026-08-31 — v0.1.9 "the snake goes to war" (the owner played v0.1.8)

The owner tested and the verdict came in one long voice-note of a message.
Fixes first, additions second, "work slowly, no skipping, no weak designs".

**What he saw (the fixes):**
- The snake starts TOO FAST - "a little slower than that".
- The body is "connected circles" - it must be ONE PART, no other objects,
  no weird circles, "like... too smooth!". The beaded look dies.
- The controls are broken-ish: tap-left/right-halves is not what he wants.
  He wants HOLDING and MOVING the finger like an invisible analog gamepad
  wheel. CRITICAL: the wheel controls the HEAD in absolute screen space -
  "left when the head is upside down stays left", never relative steering.
  Must handle vertical AND horizontal accurately.
- Eat particles were blue; they belong to the thing being eaten (apple=red).
- Before "tap anywhere to start": ASK the play mode - vertical or horizontal,
  with assets showing the phone position. NOT auto-sensed - the choice
  overwrites the auto. (Future-proofing: position-specific ways to play.)

**What he wants added (the war):**
- Mode menu AFTER the position menu: NO-WALLS (edge-to-edge wrap) plus
  classic. And inside the mode menu, a left-right scrollable area of
  boxes called the OPTIONALS: enemy / power-ups / bugs / obstacles / fruits.
- Study HIS snake games first (HAKORADev/Python_Game_Box_PGB): the python
  snake (grid, A*, temp obstacles) and the Snake3D web game he spent a week
  on - THAT one carries the super powers system, and "bugs hit you without
  dying" is confirmed in its constants (BUG_PENALTY_LENGTH/SCORE, no death).
  Its power spread (20% chance, weighted types, 10s board expiry, 25s
  speed/slow, black apple = -5 length) is the design baseline.
- GREEN enemy snake with real AI: it eats apples AND coins; coins weigh
  more than apples (two apples = one coin, each coin = one) but score
  power-ups make apples profitable again. When it gets BIG it tries to
  WRAP ITSELF AROUND the player's snake to end him. Enemy death is
  permanent for the round; the game only ends when the USER dies.
- Shop becomes scrollable with labeled sections: skins, fruits, power-ups,
  bugs, obstacles, enemies. Prices wear the GOGACoin icon; unaffordable
  items gray out. (Design law -> AGENTS.md: ANY price gets the coin icon,
  because games may have their own currencies someday.)
- Fruits = customization for the edible thing (banana, cherry, orange,
  grapes, strawberry, pear, lemon, peach, watermelon, pineapple); owned
  fruits feed an optionals selector (one / specific / all - randomized).
- Power-ups AND power-downs live in special fruits with auras; never the
  same spawn-randomness, spawn-time, or activation time. SLOWER, FASTER,
  GHOST, MAGNET (coins come to you from further), SNAKE-EATER (bite snakes
  from their TAILS ONLY - shorter them, bigger you; needs the enemies
  pack), WITHER (the power-down: fruits REDUCE length while cursed).
- ENEMIES PACK: up to 10 enemies at once, each a different color, THE most
  expensive thing in the shop.
- HUD: power icon + timer, enemy score. SFX: eating tails, power-ups,
  power-downs.

**Design decisions recorded (mine, from his words):**
- The analog wheel = touch anywhere, that point is the wheel center, the
  drag vector's angle is the head's target heading (absolute), rotate at
  a capped rate, release keeps the heading. Deadzone 12px so resting
  fingers don't jitter the head.
- The one-part body = a single ribbon polygon: the trail is resampled at
  fine arc steps, smoothed, and extruded into a closed polygon with
  per-vertex half-width (taper to a fine tail) and per-vertex gradient
  color (the blue->melt rule stays). draw_polygon paints it in ONE call.
  A slightly larger darkened outline polygon under it keeps the pop.
- The orientation choice letterboxes the FIELD: vertical = ~9:16 field
  centered, horizontal = ~16:9 field centered, whatever the device is
  doing. The choice overwrites the v0.1.8 auto-sense every load.
- AI value function: value/target-distance with coin=1.0, apple=0.5,
  apple=x1.5 while golden/score-boost is live; obstacle probing ahead;
  wrap-aware pathing in no-walls; encircle = orbit the player's head and
  tighten when enemy_len >= 2x player_len.
- Powers apply to the AI too (symmetry), and each power re-writes part of
  the AI's behavior table (the owner: "make a proper design that modifies
  the AI system for each different power-up").

---

## 2026-08-31 — v0.1.9 SHIPPED (the build record)

Everything in the entry above is IN. Implementation notes worth keeping:
- The war lives in FOUR files now: snake.gd (orchestration + paint + shop),
  snake_body.gd (one SnakeBody per snake - physics, trail, the RIBBON),
  snake_ai.gd (the brain + the per-power behavior table), snake_fruits.gd
  (catalogs + the vector fruit painters).
- The ribbon: trail resampled at 11px arc steps -> left/right edges by
  local normal -> tail cap fan -> ONE closed polygon with per-vertex
  gradient colors, draw_polygon in a single call, over a +3.5px darkened
  outline pass. Wrap breaks (segments > 220px) split the sampling so
  NO-WALLS teleport lines never paint across the field.
- The wheel: first finger = wheel center, stick = drag offset, deadzone
  12px, stick angle = ABSOLUTE target heading, capped bend 4.6 rad/s.
- The orientation ask letterboxes the FIELD (9:16 / 16:9) inside any
  device orientation; the mode menu carries the OPTIONALS strip (a
  game_safe BoxScroll) - enemy open from day one, the rest unlocked in
  the shop, locked boxes wear lock + coin price and tap into the shop.
- The powers table (weights 12-22, cooldowns 8-22s, durations 7-12s) is
  in snake_fruits.gd POWERS - adding a power = one dict entry + one
  behavior-table row + one chip glyph.
- Tests: flow_test grew record_started semantics + the shop-item API +
  the LEAST PLAYED regression + the battery-ping title; snake_probe grew
  to 30 checks (the whole war walked headless); visual QA ran REAL
  frames through Xvfb (landscape gameplay + the three screens) and caught
  two real layout bugs pre-build (optionals strip overflow; Kenney Rocket
  section labels blowing the shop sheet's min width - fit_label or die).
- Version 0.1.9, base 30280 (arm32 30281, arm64 30282).
