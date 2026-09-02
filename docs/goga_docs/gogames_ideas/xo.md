# XO — the v0.2.8 journal (born again)

The ladder is gone. The owner played the v0.2.7 box, delivered the 2048
verdict, and ordered the next game in the same breath: "rename it to just
XO without the word ladder and remake it", pointing at the PGB v1.3.8 xo
and an uploaded xo.html (his own sketch-design mock: paper, ink, red X vs
blue O, hard offset shadows, a YOU/DRAWS/O score-board).

## THE OWNER CONTRACT

- plain XO — no ladder word anywhere
- SKETCH design with smooth animations and cool SFX
- a user-enemy wins/draws widget
- each WIN +1 score, each LOSS -1, a DRAW 0
- a GOGACoin spawns after each 3 rounds, in an empty grid cell, and
  WHOEVER PUTS A THING ON IT TAKES IT (the CPU can steal it — a race)
- the CASH OUT button dies; banking is the PONG design (the pause
  sheet's END button, `pause_end_run`)
- NO difficulty levels: one opponent, "good enough to not lose but not
  smart enough to always win", with different profiles, and it ADAPTS
  on the fly — "if first round the user used pattern xx so round 2 make
  the CPU do not fell in same pattern" — with a SHORT MEMORY, only 2
  rounds, "so it does not adapt for every single thing"
- run bonus /2 (registry coin_div 2)
- XO thumb + guide update
- the shop question was deferred BY THE OWNER: every idea he had was
  virtual gambling/betting and the box is not ready to answer its own
  content rules yet (see brainstorms/THE_APP_STORE_QUESTION.md)

## WHAT SHIPPED

- THE SKETCH PAGE: cream paper with faint ruled lines + a red margin
  line, eraser smudges; the white board plate with the hard ink offset
  shadow (the html's `box-shadow 4px 4px 0`); four wobbly hand-drawn
  grid strokes. THE MARKS: X = two red strokes with dark under-shadows,
  O = a blue ring with its dark under-ring, both with per-mark
  deterministic wobble (a stroke never twitches between frames) and a
  pop-in (scale overshoot TRANS_BACK + a rotation settle). The winners
  get amber cells + a growing amber strike; the winning marks breathe.
- THE WIDGET: YOU / DRAWS / CPU boxes with sketch shadows and colored
  rims, right under the HUD. A small note line under the turn banner
  counts the coin clock ("the next GOGACoin lands in 2 rounds").
- THE ADAPTIVE CPU: four PROFILES — THE WALL (blocks everything, low
  noise), THE TRICKSTER (fork-hunter), THE RUSHER (aggressive, the only
  one that sometimes skips a block), THE SAGE (balanced) — rotated
  round-robin so the player meets all four moods. The pipeline: take
  the win (tiny per-profile miss chance) → block the threat (rarely
  skipped) → the FORK WATCH (kill the player's fork before it exists;
  forced awake when the memory says the player forks) → profile-weighted
  build/block/position scoring with a little noise, so the same board
  never plays the same twice.
- THE 2-ROUND MEMORY: every finished round is remembered (the player's
  opening, the CPU's reply, whether the player built a fork, the
  result) in a FIFO capped at TWO. adapt() turns it into moves: repeat
  an opening twice and the reply that failed to win is BURNED (never
  played again against that opening — the probe proves 0/200 picks);
  a fork inside the window wakes the fork watch; after two rounds it
  all forgets.
- THE BALANCE (measured, 600 seeded games): vs a random player the CPU
  wins 92% and NEVER lost; vs a decent greedy player it draws 97% and
  lost 3%. Hard to beat, never perfect — the owner's law, pinned in
  tests.
- THE COIN RACE: after every 3 COMPLETED rounds the next round opens
  with a real coin.png in a random EMPTY cell (fade-in, bob, glint).
  Whoever marks that cell takes it: the player (+1 run coin, sparkle,
  xo_coin voice) or THE CPU (it steals, the toast says so). Unclaimed,
  it vanishes with the board.
- THE BANK: pause_end_run = true — the pause sheet's END button ends
  the run and pays score/2. No CASH OUT button anywhere.
- THE VOICES (tools/v028_sfx.py): xo_tap (paper tap), xo_x (two dry
  pencil scratches with real-catch stutters), xo_o (one round swirl),
  xo_win (rising sketch chime), xo_lose (soft descending wah), xo_draw
  (flat two-note shrug), xo_think (tiny pencil dot while the CPU
  thinks), xo_coin (bright pick + sparkle). Plus the pencil dust
  particles every placement throws.
- ACHIEVEMENTS: Pencil Pusher (10 wins), Sketch Master (40 wins),
  Unstoppable (5 in a row) — the rung trio is gone.
- THE THUMB: recomposed to the sketch look (paper, board, X's winning
  row + the amber strike, O's blocks, the coin waiting) — no ladder.
- tests: xo_probe.tscn NEW — registry laws (+1/-1/0, /2, banner, fee),
  the pong END law, the widget, the coin race (player take, CPU steal,
  ordinary rounds, the note clock), the burned reply (0/200), the live
  fork spy, the memory FIFO + expiry, 300 legality picks, the 600-game
  balance, the 400-game greedy-draw law. flow_test grew the title/div
  laws. ALL PASS.
- Xvfb QA (qa_v028): the fresh page, the marks mid-game, the coin round,
  the winning strike, the verdict + the round rollover — eyeballed
  BEFORE shipping.
