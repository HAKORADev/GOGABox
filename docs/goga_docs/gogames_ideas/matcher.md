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
- Deadlock: after every settle, if no valid move exists the board shuffles
  with a sparkle sweep (never a dead player). A gentle hint glows on a valid
  swap after ~5s idle.

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
- Endless Classic board, no goals, no timer, no fail state. Locked valid
  moves reshuffle silently; the board literally cannot kill you.
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
