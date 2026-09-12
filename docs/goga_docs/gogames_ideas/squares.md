# SQUARES — the dots-and-boxes classic (KSquares energy)

Graduated from the workshop in v0.3.9-3 (the owner's GDD round). The teaser
was parked as **DOTS** (the seventh dump, "KDE KSquares-like"); the owner
renamed it: "the game dots, i guess we should rename it to squares? feels
better". The brain's honest ancestor is KDE's KSquares (open source) —
take turns drawing lines between the dots, close a box to claim it, close
one and you go again, most boxes wins.

## The owner's contract (v0.3.9-3, verbatim intent)

- **Rename**: the game is SQUARES, not DOTS.
- **Vertical only** (the xo law — no position ask).
- **The colors are fixed**: the user is RED, the enemy is BLUE. Not for
  sale, not a skin.
- **The shop: themes only, no skins** — but the OPTIONS button is there,
  and the 3 board sizes are BOUGHT from the shop (the 2048 mechanic word
  for word: buy in the shop, apply in the options — THE BUY LAW).
- **The economy**: a lose takes 1 score point and the score bonus is /2
  (registry `coin_div: 2`). Win +1.
- **NO DRAWS**: "winner who has more squares, loser who has less, no draw
  situation here". Enforced by ARITHMETIC, not by a rule patch — every
  board wears an ODD box total (4x4 dots = 9 boxes, 6x6 = 25, 8x8 = 49),
  so a tie cannot exist on any board the box sells.
- **The squares widget**: "make a widget for this game before the goals
  one right after the score one to show red square and nn and next to it
  blue square and nn" — a live RED nn | BLUE nn tally seated between the
  score chip and the W/D/L cards.
- **A GOGACoin after 3 rounds** (the xo cadence) — it rests inside a box;
  whoever CLAIMS that box takes it.
- **The difficulty**: "same dynamic way with different gameplay profiles
  that are all challenging without one being impossible and no one be easy
  while all having programmed mistakes and the profile changes based on
  how the user won or lost" — the four-moods rotation (the xo law) plus
  the chain-scar memory (below).
- **The controls**:
  - TAP ANYWHERE TO START, properly (the chess gate).
  - "tapping on the edge of the square to put the line" — the tap maps to
    the NEAREST edge.
  - THE LINE'S LIFE: "the line will be first fade-in with smooth alpha
    level modification to match the color of the player then after it
    completes this part, it will smoothly transform the color to normal
    black, make sure it is smooth and fast but not very instant" —
    phase A (0.16s): alpha 0→1 in the player's color; phase B (0.26s):
    the color dries into the board ink. The line ends INK on every board
    (the boxes keep the color — that is where ownership lives).
  - A claimed square "fades-in the color using that alpha smooth
    transition" (0.26s alpha fade in the owner's color).
  - THE HOLD LAW: "when i hold at somewhere, it will apply the standby
    semi-transparent line and when move the finger, the line will follow
    me to the nearest edge, when released it will get applied, if the
    finger went out of board, it's canceled" — press = dashed translucent
    standby on the nearest edge, drag = it follows finger edge to edge,
    release = applied, off-board = nothing shown and a release out there
    places nothing. "very smooth!"
  - "the square edges like...striped or...that thing where they are like
    alpha" — the standby line is DASHED and translucent (both).
  - "the end button in the back menu too ofc" — pause_end_run (the pong
    law).
- **Guide, rate-limits, entry, achievements, thumbnail, SFX/VFX/music**:
  the house standard (the registry entry wears the fee/limit keys; the
  audio family is `sq_*` + `sq_theme`; the thumbnail is a composed scene,
  960x640, no text).

## The KSquares law (the game's spine)

Close a box and you go AGAIN. This one rule makes the whole game: long
chains are handed over, the eater swallows, and the double-cross ("all
but two") is the endgame's sword. The CPU plays it; the player learns it
(the guide teaches: never leave a third side open — unless the
double-cross is the plan).

## The brain (the xo dialect)

- FOUR moods, invisible rotation (`wall / trick / rusher / sage`), each
  with its own miss_take / err_safe / chain_iq / noise — programmed
  failures everywhere, never 40/40 (the blind-spot law).
- The pipeline: take the capture (a small miss chance blinds the whole
  capture set) → play a safe edge (a small error chance blinds the safe
  set) → concede the SHORTEST chain (the smart hand) or fumble blind.
- THE DOUBLE-CROSS EYE: while eating, if exactly TWO boxes would fall and
  a next chain waits after them, the eye plays the LAST close edge
  instead — both boxes go to the player, and the player must open the
  next chain. `chain_iq` is the eye's openness.
- THE CHAIN-SCAR MEMORY (the 2-round window): lose a round where the
  player swallowed a chain of 4+ in one breath and the eye stays WIDE
  (chain_iq floored at 0.92) for the memory window. The CPU learns
  exactly the way it lost.

## The boards (no-draw arithmetic)

| size | dots | boxes | price |
|------|------|-------|-------|
| 4x4 dots | 16 dots, 24 edges | 9 boxes | free |
| 6x6 dots | 36 dots, 60 edges | 25 boxes | 1800 |
| 8x8 dots | 64 dots, 112 edges | 49 boxes | 3600 |

All box totals odd → the tie class cannot exist. The owner's ladder
mirrors bovo's 8/10/12 pricing.

## The shop (themes only — the owner: "no skins")

5 paper themes (PAPER free / KRAFT 220 / OCEAN 280 / MIDNIGHT 340 /
MARBLE 420) + the board sizes (sell only — the options applies). The
RED/BLUE pens are nobody's merchandise.

## The probe contract

The whole CPU core is STATIC — `idx_h / idx_v / box_edges / edge_boxes /
box_sides / closers / safe_edges / greedy_run / hands_run / winner_of /
cpu_pick / remember / adapt` drive headless laws without the scene (the
bovo contract). The scene probes ride `probe_reset(seed, dots)` +
`probe_step(dt)`.
