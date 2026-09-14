# SNAKES & LADDERS — GDD (v0.3.9-12)

> The owner's verbatim intent, pinned before the script. The shelf name is
> **SNAKES & LADDERS** (the generic classic — no trademark risk). The
> honest brain is the pure-RNG children's classic: no intelligence at the
> table, the die is the only mind ("ludo has a little logic but this one
> is literally pure RNG!").

## The verdict from the field

v0.3.9-11 landed (board ludo's selection round, the shelf-truth laws, the
slasher frenzy + dessert shelf). The owner parks testing for one round —
v0.3.9-12 ships the next board game and rides together with v0.3.9-11's
work in one download.

## The table (the owner's spec)

- **10x10 board, 100 steps.** Boustrophedon numbering: cell 1 bottom-left,
  the row snakes left→right→left up to cell 100 at the top. Cell 1 and
  cell 100 wear their own special design (the gate mat and the crown cell
  — the two squares every eye lands on).
- **2 to 4 players.** The optionals ask at the START shows 2, 3, 4 as the
  house side-by-side cards (law 28 — no title, no hint, no mode talk).
  2 = 1v1, 3 = 1v2, 4 = 1v3. The user is always player 1; the others are
  the CPU.
- **PURE RNG.** No opponent intelligence, no moods, no memory — the CPUs
  breathe and roll, that is the whole brain.
- **One figure each.** The figures wait OUT of the board, in their owner's
  tray (the ludo tray law: player 1 top-left, 2 top-right, 3 bottom-right,
  4 bottom-left). The first roll walks the figure onto the board.
- **The die is ludo's die.** The grayed waiting die sits at the active
  tray's pad — tapping IT rolls (the v0.3.9-11 waiting-die law). Fade in,
  shuffle, settle: the face is the truth. One die only.
- **The walk is ludo's walk.** The figure hops square to square (up, over,
  drop) with a soft tick per hop, the pitch rising along the move.
- **THE EXACT LANDING LAW (the owner pointed it at BOTH board games):**
  at 97 you need a 3 for 100. Roll a 4 and the move is illegal — the die
  is refused, the turn is skipped. Ludo already wears it (`np > PATH_LEN`
  refuses); this board wears it as `pos + roll > 100` → the skipped beat.
- **Ladders ride, snakes fall.** Land on a ladder base and the figure
  SLIDES UP the ladder's rails — a straight lane, the two rails + the
  rungs drawn honest. Land on a snake head and the figure FALLS following
  the snake BODY's turns — the drawn zigzag polyline IS the fall path.
  Ladders look like ladders, snakes look like snakes (code-drawn, no
  sprite art — "amazing code-designed art" is the owner's ask).
- **The classic fixed layout** (the Milton Bradley table, the one everyone
  grew up on — the owner: "same places of snakes and ladders", the same
  board every round):
  - LADDERS: 4→25, 13→46, 33→49, 42→63, 50→69, 62→81, 74→92
  - SNAKES: 27→5, 40→3, 43→18, 54→31, 66→45, 76→58, 89→53, 99→41
- **THE CHECKER (the owner's taste):** the board wears the 1,2,1,2
  alternating squares — cell-number parity paints the two tones.
- **The verdict is ludo's verdict.** First figure on 100 wins the round.
  Win +1 score, loss -1 (never under zero), run bonus /1. No draws. The
  LOSER opens the next round; the user opens round 1.
- **THE COIN CLOCK:** one GOGACoin after each 5 in-game minutes, spawned
  in a legal area (strictly ahead of the user's figure, on a free cell) —
  whoever's figure steps on it takes it, the CPU steals too.
- **VERTICAL.** The tall board is a portrait native.

## The look (all code-drawn — no external assets)

- **THEMES (5)** — a theme owns the room, the board, the squares, the
  ladders, the snakes AND the rivals' figures; the user's figure wears
  its skin on every theme (the theme-ownership law):
  1. **THE MOUNTAIN** (default, free) — the warm paper classic: brown
     ladders, green snakes, the 1,2 checker in warm cream/ink.
  2. **NEON** — the cyberpunk board: internally bright lanes, glowing
     rails and serpent lines on the dark.
  3. **CANDY** — the sugar board: pastel squares, candy rails, gummy
     snakes.
  4. **BLACK & WHITE** — the mono board: you are WHITE, the rivals wear
     the grays and black; ink snakes, pale ladders.
  5. **JUNGLE** (the owner left the 5th to us, NOT pixelated) — deep
     greens, bamboo-gold ladders, vivid vine snakes.
- **SKINS (5)** — the user's figure only: THEME TOKEN (free), IVORY,
  JADE, ROSE, ONYX (the ludo pricing ladder — "good pricing" = the house
  ladder the owner already approved).
- The shop wears the shelf-truth laws from birth: skins above themes, the
  ON row, no dash talk, one action color.

## The sound (100% synthesized, the house way)

snl_roll (rattle) · snl_settle (wood thock) · snl_hop (soft tick, rising
in-game) · snl_climb (the ladder's rising gliss) · snl_fall (the snake's
descending slide) · snl_denied (the polite refusal) · snl_coin ·
snl_win · snl_lose · snl_theme (the music loop).

## The tests (the owner: real simulated play, not syntax checks)

- `tests/qa_v03912_snl.gd` — the headless law probe: the state law, the
  theater, the exact-landing law (97 + 4 refused), the ladder ride, the
  snake fall, the coin clock, the verdict + opener law, the shelf laws,
  and THE SOAK: full random rounds to a verdict, the machine never hangs,
  every position stays legal.
- The Xvfb film rig photographs the board, the ride and the fall; PIL
  censuses the pixels (the checker count, the rails, the serpent line) —
  evidence, not eyeballs.
- `flow_test` wears the snl rules block + the 24-playable contract.

## The registry

price 450 · fee 8 · coin_div 1 · shop · banner · portrait · reveal
(16 hours / 17 games) · 15 tiered achievements.
