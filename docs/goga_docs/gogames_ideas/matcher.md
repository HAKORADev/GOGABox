# MATCHER — GDD (v0.3.3)

The happy one. Bejeweled-Classic energy (PopCap's endless jewel), NOT Candy
Crush's level machine — the board never ends, no hand-designed levels, the
difficulty lives in the MODE you picked and its own progression. The Python
matcher (PGB `matcher.py` v1.3.8) comes home inside it as the CHALLENGE mode.

Owner laws, kept verbatim in spirit:
- "be like bejeweled classic from popcap, and not like candy crush ... like
  infinity but we do not design every single level ofc"
- "every single thing will be 1 score point, and the bonus will be /300"
- the GOGACoin: "make it appear and takes a grid real place, then the user
  has to make it reach the bottom and it will drop and be earned, make the
  30s timer be based on last collected one not last appeared one"
- "make a lose here takes -500 score points ... only in challenge mode"
- PEACE = the snake peace: "0 score bonus and 0 gogacoins ... no powerups"
- "the 4-match special thing will be a VFX drawn on-top of whatever" (so
  skins never break specials)
- "the universal standard default atmosphere feel happy and welcoming, not
  dark like the rest of the games"
- vertical-only view; banner ad strip at the bottom

## THE GRID

- 8x8 board, 5 gem colors, swap-adjacent, matches of 3+ pop, gravity fills
  from the top, cascades chain with a rising combo pitch. The classic.
- Portrait only. The board is the hero: wide as the screen allows, centered,
  rounded cells, soft drop shadows. Top bar = the box chrome (back / score /
  round-coins). Bottom = the power-up rail + the reserved banner strip.
- Deadlock (v0.3.3-8 THE OWNER'S LAW): after every settle, if no valid move
  exists the run LOSES - no rescue shuffle. Challenge pays the round fail
  (-500, a life, the sweep theatre, a fresh legal round); every other mode
  ends the run. A fresh pour can never spawn locked (the quiet deal
  backstop). A gentle hint glows on a valid swap after ~5s idle. The SHOP
  shuffle power stays: a paid PRE-EMPTIVE reshuffle, the last legal move
  of a dying board.

## SCORING

- EVERY gem that pops = +1 score. No multipliers hiding the count — the HUD
  score is literally "gems matched this run" (plus mode bonuses, see below).
- Special gems pay their area (a flame pops 8 neighbors = 9 points total,
  a star clears 15 cells = 15 points, a hypercube feast counts every gem it
  takes).
- Run-end GOGACoin bonus = score / 300 (`bonus_div_override = 300`).
- CHALLENGE round goals are scored in the same currency (a "goal 60" round
  wants 60 gems matched inside its window).
- PEACE pays nothing (the snake peace law) — score stays on the HUD for the
  eyes only.

## THE GOGACOIN (the board guest)

- One coin at a time, never two. 30s after the last coin was COLLECTED, the
  next one materializes in a random cell with a sparkle wink (it takes that
  cell — nothing spawns inside it, it never matches, it just rides the
  gravity).
- Bring it down: clear the gems under it and it falls like everything else.
  When it reaches the BOTTOM row it drops out of the board and is banked:
  +1 round-coin, a golden plink, a coin fly-to-HUD.
- If a match would pop THROUGH its cell the coin simply falls — it is never
  destroyed, never matched, never blocked.
- PEACE: no coins at all. DIAMOND MINE: the coin can also be dug free.

## SPECIAL GEMS (earned by matching — the Bejeweled layer)

The 4/5-match specials live as VFX OVERLAYS drawn on top of the base gem,
so any skin works without new art (the owner's skin-safe law):

- **FLAME GEM** — match 4 in a line. Wears a molten ring + ember particles.
  When it pops (by match or by touching a detonation) it blows a 3x3 blast.
- **STAR GEM** — match an L / T / + shape. Wears a white star sparkle.
  Popping it clears its whole row AND column in one cross-burst.
- **HYPERCUBE** — match 5 in a line. A colorless prism (all skins' faces
  cycling). SWAP it with any gem (no match needed — that swap is legal and
  does not cost the "no match" penalty) to zap EVERY gem of that color off
  the board. Two hypercubes swapped = the full board wipe (rare, glorious).

Chain reactions: flame blasts can ignite other flames, star crosses can
sweep a hypercube, everything cascades. Combo banners fire on cascades
(SWEET / SUPER / EXQUISITE / SPECTACULAR, pitch-ladder pops under them).

## BOUGHT POWER-UPS (the Candy Crush layer)

Four consumables, tap-to-arm, tap-to-fire. Each is unlocked ONCE in the shop
with the real GOGACoin wallet, then stocked in-play up to 3 charges each,
refilled with the ROUND BALANCE (the coins you collected from the board this
run) — never with the box wallet mid-run. High prices, owner's word.

| power | effect | unlock | in-play refill (max 3) |
|---|---|---|---|
| SHUFFLE | reshuffles the whole board (deadlock buster, plan reset) | 100 | 30 |
| LINE BLAST | tap a gem: its row AND column blow (star cross on demand) | 150 | 45 |
| GEM BOMB | tap any cell: 3x3 blast centered there | 200 | 60 |
| COLOR VAPOR | tap a gem: every gem of its color vanishes | 260 | 80 |

- The rail: a scrollable strip at the BOTTOM of the screen (above the banner
  reserve). Each slot = icon + charge dots (0..3) + price chip; tapping an
  empty slot opens the mini refill sheet (round-balance prices); tapping a
  stocked slot arms it (the board dims, a targeting cursor rides the finger)
  and the next tap fires it.
- Stock does NOT persist between runs (fresh 0/0/0/0 each run) — the refill
  economy IS the mode's spend. Unlocks are forever.
- POWER-UPS ARE OFF IN PEACE (the owner's law — peace wears nothing).

## THE MODES

The entry flow is Bejeweled-style: a MODE PICKER screen first (the optionals
screen standard — one big happy card per mode, art + name + price chip),
then the board. Modes are products in the shop except CHALLENGE, which is
free and default. On first launch the picker greets you; the last played
mode is pre-selected next time.

### CHALLENGE (free — the PGB matcher, modernized)
The Python matcher reborn as a fair, varied, timed run. Rounds instead of a
static up-up-up ladder:
- Each round rolls a FAIR RANDOM goal: score target 40..90 (+6 per round
  number, soft growth), a time window 45..70s, and sometimes a twist.
- Twists (rolled per round, each game different): "color drought" (one
  color spawns rare this round), "gem rain" (extra spawns, one free shuffle),
  "gold rush" (all pops +1 double for the first 10s). Never unfair — twists
  only reshape the round, never starve the board of moves.
- Reach the goal inside the window: round banks (fanfare, next round rolls).
- Miss it: **-500 score** (only in Challenge, the owner's law, floor at 0),
  a soft gong, and the next round rolls anyway — the run never hard-stops
  on a bad round; the clock below is your real life.
- The RUN is timed fatal: 5 minutes of run clock, ticking down across
  rounds; when it hits zero the run ends (banks everything). Deeper rounds
  roll harder goals. This kills the old static machine: every run is a
  different ride.

### PEACE (Zen — the snake peace, mirrored)
- Endless Classic board, no goals, no timer. v0.3.3-8: a LOCKED board ends
  the peaceful session (the owner's deadlock law - no reshuffles anywhere);
  the run ends gently, the clock stands as the trophy.
- 0 score bonus, 0 GOGACoins (no board coins either), NO power-ups.
- The pause menu carries the END button (the snake/pong law) so a peaceful
  session can still be closed gently.
- Sounds softer, background calmer, combo banners replaced with drifting
  petals. It is the breathing room of the box.

### BUTTERFLIES
- Butterfly gems hatch on the bottom row and flutter UP one row every move
  you make. A friendly (but hungry) spider waits above the top edge.
- Match butterflies (any match containing one) to collect them: +1 per gem
  as always, butterflies bank a +2 bonus each on top (mode flavor).
- If a butterfly crosses the top and the spider eats it: the run ends
  (fatal, no timer needed — the tension is the rise). Rise pace quickens as
  the run ages (every 45s the butterflies gain pace).
- HUD shows the highest butterfly ("danger row" tint when one is 2 rows
  from the spider).

### ICE STORM
- Ice columns grow up from the bottom of the board, one layer at a time,
  on a global frost clock that accelerates (starts 7s/layer, floors at 3s).
  A column is a stack of frozen cells under the gems (up to 6 layers tall).
- Matches played ON a column's gems melt one layer per match. Flame/star
  blasts melt their whole overlap. The TEMPERATURE GAUGE heats with every
  quick melt (chain melts inside 3s) and pays a melt multiplier (+1 layer
  melted per hot bar filled).
- Any column that grows past the top water line freezes the run: over.
- Score = gems as always; every full layer melted banks +5 on top.

### DIAMOND MINE
- 90 seconds on the dig clock. The top 4 rows of the board start buried in
  earth; a DIG LINE sits under the earth. Matches touching earth dig the
  earth above them away (each pop digs its cell's earth + the cell above).
- Buried inside the earth: GOLD nuggets (+10 when dug), DIAMONDS (+25),
  ARTIFACTS (+60, one per layer). Dig them, don't pop them — a treasure
  dug is a treasure banked.
- Clear ALL earth above the dig line: the layer breaks, you descend one
  depth (the meter climbs in meters), +30s on the clock, a fresh richer
  earth slides in from the top. Deeper layers hold denser treasure.
- Clock zero: the run ends, everything banks. Pure PopCap Diamond Mine.

## THE ECONOMY (taste-designed per the owner's delegation)

- Registry: price 400 (the shelf's own v0.1.4 promise for this exact tile),
  fee 10, coin_div 300, banner true, portrait, shop true. THE POUR RITUAL
  rides along from the teaser days (the owner's own v0.1.4 design): the tile
  shows up day one, never a mystery - pour 100 GOGACharges into its meter
  and own 3 games, then it is buyable at 400.
- Modes (shop products, one-time): CHALLENGE free & default · PEACE 120 ·
  BUTTERFLIES 180 · ICE STORM 240 · DIAMOND MINE 300.
- Power-up unlocks: SHUFFLE 100 · LINE BLAST 150 · GEM BOMB 200 ·
  COLOR VAPOR 260 (see the table for round-balance refill prices).
- Round balance IS run_coins until the run ends (refills spend it down;
  what survives banks to the wallet at finish_run).
- Achievements (taste): matcher trio (GEM FRESH 300 matched / GEM HOARD
  3000 matched / LIGHT TOUCH one hypercube), cascade love (SWEET TOOTH a
  x4 cascade), mode stories (MOTH KEEPER 100 butterflies total, ICE BREAKER
  melt 25 layers total, DEEP DIG descend 5 layers in one mine, CALM MIND
  one 5-minute peace session), CHALLENGE CHEST finish a challenge run over
  1500 score.

## SKINS (optional, happy)

- **Gem Vault** (default, free) — the glossy 5-shape jewels (diamond /
  ruby / emerald / citrine / amethyst). Colorblind-safe by shape.
- **Candy Shop** (220) — the OGA candy set: beans, drops, gumdrops.
- Specials stay overlays in every skin (flame ring / star sparkle /
  prism cycle) — skins swap base art only, the owner's skin-safe law.
- Board frames: one per skin, plus a gold frame option (180).

## THE FEEL (the tasty part)

- Swaps are 0.16s eased tweens; illegal swaps rubber-band back with a soft
  thud. Pops: 0.22s scale-burst + a 6..10 particle puff in the gem's color
  + a pitch-laddered pluck (cascades climb the scale, cap at +12 semitones).
- Gravity falls with a 1.06 overshoot bounce. Refills deal in a quick
  diagonal wave from the top-left.
- Flame ignition: screen-safe flash ring + 8 embers. Star: two light beams
  sweep the row/column in 0.12s. Hypercube: lightning arcs to every victim
  gem, all popping in one shimmer.
- Combo banners: fat rounded text, spring-in scale, confetti puff behind
  (confetti = the box's Achiever confetti style, borrowed legally).
- Music: a bright marimba-and-palm loop (major key, 96 BPM, birds at the
  edges) for the standard modes; PEACE gets its calmer twin (same key, half
  the drums, more air). Menu carries the same happy loop.
- Background: a soft daylight sky gradient (cream horizon into pale blue),
  slow floating bokeh bubbles, zero menace. The one sunny room of GOGABox.

## THE BANNER & THE AD PACING

- `banner: true` in the registry, the board and the power-up rail reserve
  the shared `banner_bottom()` strip — the native 52dp banner sits in its
  proper place, nothing overlaps it. SPACE INVADERS already wears its strip
  the same way (v0.2.6 law) — this release re-checks its inset on the new
  layouts (the fly-in and the gap popup both stay above it).

## THE TECH NOTES (for the builder)

- One script `game/games/matcher/matcher.gd` + one board model
  (`BoardState` inner class, seeded RNG, pure functions for match/resolve
  so the probe can fuzz it), presentation layered on top.
- The box layout: 1080x1920 portrait internal. Cell size = (1080 - 2*36 -
  rail) / 8 ≈ 112..120px; the board top sits under the box HUD.
- TouchKit: taps select + swap (tap gem A, tap adjacent gem B), drag from
  a gem toward a direction swaps in that direction (the slasher/dash
  drag law: real TouchKit events, no direct handler calls).
- SFX synth script: `tools/v033_sfx.py` (the house gen_sfx lineage); art
  derivation script: `tools/v033_matcher_art.py` (copies the candyrush gem
  and candy sets out of git history, builds butterfly/spider/ice/earth/
  treasure/power-up icons with PIL, assembles the special overlays).
- Probe: `tests/matcher_probe.gd` — model fuzz (2000 seeded swaps, no
  invalid states), match/cascade correctness, special creation + blast
  areas, deadlock shuffle, coin fall + bottom drop + 30s-last-collected
  rhythm, round roll fairness bands, -500 challenge loss, mode purchases,
  refill economy (round balance only, max 3, wallet untouched mid-run),
  peace pays nothing, banner inset reserved. 55 checks - ALL PASS.
  Xvfb shots for every mode (`tests/qa_v033.gd`).

## THE BUILD LOG (v0.3.3)

- THE TWEEN-AWAIT LAW (the probe caught it, now house doctrine): NEVER
  `await tw.finished` on a tween that may already be done - a short tween
  finishes while the longer ones are awaited and that await hangs forever.
  One timer sized to the longest animation moves the whole wave instead
  (`_gravity`, `_animate_swap`).
- THE UNFREEZE LAW (matcher flavor): the mode picker and the power sheets
  pause the tree; `_exit_tree()` always thaws it - a game torn down under
  an open sheet can never leave the box frozen (the invaders defend-freeze
  class, killed at the root).
- THE FIRST ROUND LAW: challenge round 1 rolls BEFORE the first tick - the
  naive deal started the round clock at 0 and every run ate an instant
  -500 gong.
- THE CROWN TABLE: special births live in the pure `_birth_kinds()` unit -
  the swap cell wins the crown, L/T crosses birth at the cross, otherwise
  the run's middle. The probe reads it without playing a wave.
- Assets: the candyrush CC0 gem + candy sets and pops return from git
  history (documented provenance), Kenney's particle pack powers the
  overlays, the monarch butterfly is a CC0 OGA find with its studio
  background flood-filled away; spider/ice/earth/treasures/power icons/
  skies/mode cards are PIL originals (`tools/v033_matcher_art.py`), the
  17 SFX + the peace theme are numpy synth (`tools/v033_sfx.py`).

---

# v0.3.3 PATCH 3 — the real-match-3 round (2026-09-05)

The owner's verdict after patch 2: 2048 and invaders are GOOD, matcher gets
the whole next patch. Everything below is his spec, quotes verbatim.

## THE OWNER'S SPECIAL TABLE (replacing the Bejeweled guesses)
- "the L or T is the bomb" -> BOMB: a 3x3 crater + the shockwave + the shake.
- "the 4 vertical makes a horizontal line sweeper" -> ROW SWEEPER: its whole
  row, with a glowing bar racing left-to-right and STAGED pops (distance
  delays) so the eye sees the sweep.
- "the 4 horizontal makes vertical one line sweeper" -> COLUMN SWEEPER:
  its whole column, top-to-bottom staged.
- "the +5 in a line makes color remover" -> COLOR REMOVER: "matchable with
  whatever 3+" (swap with ANY gem) and "remove that color in a proper
  bottom-to-up animation and removing" - the doomed color pops row by row
  from the bottom edge upward under a rising shimmer. Caught in a blast it
  takes a random color with it.
- Shader v2 (`special.gdshader`): molten bomb heartbeat + orbiting embers,
  gliding energy bands on both sweepers, an iridescent swirl + sparkle on
  the remover. Still ON the gem, still skin-safe (the owner: "ofc first
  they need more proper shaders for their effects btw because currently
  they are too poor").
- The invalid-SFX leak: blasts only speak when they actually hit.

## BUTTERFLIES - the two bug laws
- THE AFTER-MOVE LAW: "butterfly should move after the moves are done" -
  the rise walks AFTER the full resolve (swap -> cascades -> settle), never
  during the swap (his 2+1 example).
- THE GRACE LAW: "the butterfly should reach the top, and then after that,
  if it stayed at the top again, the spider will take it, not take it once
  it is in the top" - touching row 0 is SAFE; the spider stirs (glides to
  the column, red pulse, m_grace sting, "THE SPIDER STIRS..." banner); a
  butterfly STILL on row 0 after the next rise gets grabbed - run over.

## DIAMOND MINE - the pure-dirt rebuild
- THE PURE DIRT LAW: "the sand/whatever that tiles are, should contain
  nothing from the matchable jewels" - earth rows are pure dirt cells with
  treasures, never gems.
- THE BOARD LIFT: "when a line comes, it will raise the top line up and
  remove it in a smooth way" - a rise glides the WHOLE board up one cell,
  the top row sails out of the frame and fades, the freed bottom row
  becomes fresh dirt sliding in from below. (The model lifts; one tween
  wave moves everything together.)
- THE PROGRESSION LAYERS: "by progression has intense layers like 3 layers
  or 4 or a level of layers that needs only a special item to break it" -
  dirt (1 dig) -> clay (2 digs, cracks first) -> ROCK (a plain match just
  clanks; only special blasts shatter it).
- The 25s rise (+ sometimes two), the 60s start and the +25s per cleared
  row stay exactly as the owner specced in patch 2.

## ICE STORM - the video's design
The owner's Bejeweled 3 footage: frosted full-cell blocks with snow caps,
gems standing ON the ice. The old overlay sat ABOVE the gems ("currently
and weirdly you freeze the tiles"). Now the blocks render BEHIND the gems
(z 1 < gem 2), the top segment wears the cap, melts still pay the
h-3 / v-all laws.

## CHALLENGE - the pre-solve rounds (the owner's math)
"calculate the matches and the grid before even starting it and then set
the requirements and time and allowed moves based on that" - every fresh
board is PRE-SOLVED: all legal swaps are played on the model and their
immediate yields measured. Target, allowed moves and time all DERIVE from
that measurement (tightness climbs with the round; rush/drought twist it).
Score is the requirement (the owner: "i see gem matches requirements and
have not seen score requirements"); the old "fair random" numbers are dead.
THE SHOWN LAW: "it does not show how many rounds won and how many lost in
challenge and does not show how many losses until end" - the HUD wears
R/wins/losses and a 5-life bank; a lost round costs a life + the -500;
the last life ends the run. Rounds redeal with a fresh analyzed board.

## THE THREE NEW MODES
- JELLY (360): "like candy crush jelly ... it can spread between 3 extra
  grids up to 8 in a connected way, it feels like a virus" - starts as full
  lines from the bottom (sides on odd levels), a match ADJACENT dissolves
  it, a move with zero jelly cleared SPREADS (+1..3 connected cells), the
  spread EATS the gem it lands on, "jelly do not fall and nothing go past
  through it" (a solid plug: gems rest ON it, nothing refills beneath),
  limited moves, clear the grid. Levels ladder the layouts.
- ICE CRASH (420): "like jelly but different ... things go pass through it
  and it has layers" - 1..5 ice layers (the ladder art), hits happen INSIDE
  the ice (a popped iced cell loses one layer), "level 6 makes it like a
  rock and requires a special thing to crash it down to level 5", gems fall
  straight through, a dry move spreads it, limited moves.
- DROP DOWN (480): "items dropped from top after there is a match ... the
  round will start with 1-5 items exists at the top line first, with a UI
  widget tells user how many remaining, it will use both moves and timing
  or one of them as a limit, so there is 3 possibilities ... the drop logic
  will be like the gogacoin one here, make it down down down" - parcels
  ride gravity AND trade one row down per move, the bottom row delivers
  (+3), each round rolls moves / time / both.

## THE LOOK + THE VOICE (the owner's zip as the defaults)
"the zip i uploaded earlier that contained assets, it has grid assets and
background and amazing SFXs that i guess using it as the default will be
cooler" - the template checker cells, the template backdrop, the pop burst
frames, the richer objective-token donuts, and most SFX are now THE
DEFAULTS; "the game music except peace uses GOGABox main menu music" -
verified by cross-correlation (cos-sim 1.0) and replaced with the zip's own
81s A-major-feel track (matcher_game.mp3). Peace keeps v2.

## THE OPTIONALS + THE RAIL
- "make the skins just show the names and the highlight on the in-use one
  and remove the text of 'on' or tap to use, these are not in my design
  plannings at all" - names only, the green border IS the highlight.
- "redesign the powerups to look more rich, also remove the other text ...
  just show empty or nn or grayed out, let the name in the buy pop-up" -
  the rail is ICON ONLY: gold-rimmed 132px icons, a count bubble, three
  stock pips, gray when locked/empty/spent; names and prices live in the
  buy popup.

## PROBE (the owner: "run real tests so i do not have to hunt")
matcher_probe rebuilt: 110 hard checks, 0 fails - the owner's table
(births + blast areas + staged pops), the grace law, the after-move law,
the pure dirt / clay / rock / board-lift laws, the pre-solve derived
rounds + the lives math, the jelly spread/eat/plug laws, the ice-crash
layer/rock/pass laws, the drop limits + gravity/step/delivery laws, the
icon rail, the skin-name law, the music law, plus every p1/p2 regression
(coin, shop stack, back law, wallet, fuzz 2000). Full battery green:
flow_test + invaders + merge + dario + slasher + dash + snake + xo +
tower + pong.
