# FOUR IN LINE — GDD (v0.3.9)

> The owner's directive (v039 round): four in line + five in row together,
> both nearly siblings at the core. The owner: "same way for AI difficulty,
> same shop way with 5-5 and for score, bonus be /3 and goga coin in a
> place after each 4 rounds". Vertical only. Mid-sized board.

## The pitch

The drop classic, played straight: a disc falls down the column you tap,
gravity bounces it into its seat, four in any direction wins. One CPU,
many moods, an adaptive memory that stops falling for the same opening.
The whole thing in the GOGABox toy-shop look — a warm frame, deep holes,
glossy discs, hard little sounds.

## Owner contract (locked)

- **Vertical only** (registry `orientation: "portrait"` — the XO law, no
  position ask, no horizontal table).
- **No optionals menu.** The SHOP button is the only extra HUD button.
- **The economy (the xo shape):** win +1, loss -1 (score never negative),
  draw 0. **Run bonus /3** (registry `coin_div: 3`).
- **The coin law:** after every **4 completed rounds** the next round
  opens with a GOGACoin resting in a hole — the disc that lands in that
  hole takes it, the CPU races you for it.
- **The opener law:** the player opens round 1; the LOSER of a round
  opens the next; a draw flips the opener.
- **W/D/L widget** — the dominoes/chess cards (W green / D gray / L red),
  in the HUD row hugging the score chip.
- **TAP ANYWHERE TO START** — the chess gate (HUD index 0, under every
  sheet).
- **pause_end_run** — the pause sheet wears RESUME / END / QUIT (the pong
  law); END banks the run.
- **The shop (5-5):** 5 disc skins (first = CLASSIC, owned) + 5 themes
  (frame + room), everything past the defaults bought with real prices,
  grayed out when the wallet is dry (the price-display law).
- **Dynamic CPU:** profiles that rotate invisibly + the 2-round adaptive
  memory (the xo law) — spam the same opening and the burned reply never
  repeats; challenging, with programmed failures, always beatable.

## The board

- **8 columns x 7 rows** (the owner: "a mid-sized board that is big but
  not huge and not a small size"). The classic toy is 7x6; one extra
  column and row reads "bigger" without turning into a grind.
- Cells fill bottom-up; a column that is full ignores taps (a small
  shake + deny sound says so).

## The CPU (static core, the xo probe contract)

- `drop_row(board, col)`, `winner_of(board)`, `winning_cols(board, who)`,
  `cpu_pick(board, profile_id, mem, rng)`, `remember(mem, record)`,
  `adapt(mem)` — all STATIC, headless-testable, no scene needed.
- Four profiles: **wall** (block-first), **trick** (threat-builder),
  **rusher** (attack-first), **sage** (balanced). Each wears:
  - `miss_win` — the chance it fails to take an immediate win (0.10-0.15)
  - `skip_block` — the chance it fails to block an immediate loss (0.06-0.16)
  - `noise` — root evaluation jitter (same board never plays the same twice)
  - `w_build / w_block / w_center / w_avoid` — the feel knobs
- The avoid law: a profile-weighted chance to notice that blocking UNDER
  the player's winning cell hands the win back (the classic connect-four
  blunder); weaker profiles notice less.
- The memory: `open` = the player's first column of the round, `reply` =
  the CPU's first answer, `result` — replay the same opening twice and
  the burned reply never repeats; the reply that won last time is
  trusted once (the xo adapt law verbatim).

## The look (code-designed, primitives only)

- The room: theme-painted backdrop behind a rounded toy frame with
  circular holes; the room shows THROUGH the empty holes.
- Discs: two-tone radial shading, a small gloss dot, drop shadow.
- The drop: a real gravity fall (accelerating), one squash-bounce on
  landing, dust pips, the column ghost preview while aiming.
- The win: the four discs pulse once, an amber strike line draws through
  them and stays (the xo strike law — no zoom).
- VFX: dust pips on landing, confetti on a player win (Arc.confetti),
  coin glint ring while the coin waits.

## SFX (tools/v039_audio.py)

`fl_tap` (column pick) · `fl_drop` (launch whoosh) · `fl_land` (wood
thud + bounce) · `fl_denied` (full column) · `fl_win` · `fl_lose` ·
`fl_draw` · `fl_coin` · theme `fl_theme.wav` (calm toy-shop loop).
