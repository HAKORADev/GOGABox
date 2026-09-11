# FIVE IN ROW — GDD (v0.3.9)

> The owner's directive (v039 round): the gomoku sibling of four in line.
> The owner: "score bonus will be /2 and a gogacoin will appear in a place
> after each 3 rounds and whoever put a thing on it will take it". Boards
> bought first then applied "the exact same way" as 2048. Vertical only.
> Renamed: "five lines" -> **FIVE IN ROW**.

## The pitch

Stones on a warm wooden board — place one per turn, five in a row (row,
column or diagonal) wins. Calm surfaces, sharp reads: open threes, fours,
double threats. The CPU wears four moods, remembers two rounds, and will
not fall for the same trick twice in a row.

## Owner contract (locked)

- **Vertical only** (the XO law — no position ask).
- **The economy (the xo shape):** win +1, loss -1 (never negative), draw
  0. **Run bonus /2** (registry `coin_div: 2`).
- **The coin law:** after every **3 completed rounds** the next round
  opens with a GOGACoin resting on an intersection — the stone placed
  there takes it, the CPU races you.
- **The opener law:** the player opens round 1; the loser opens next; a
  draw flips the opener.
- **W/D/L widget**, **TAP ANYWHERE TO START**, **pause_end_run** — the
  same three laws as four in line (dominoes/chess cards, the chess gate
  under the sheets, the pong END bank).
- **THE OPTIONALS MENU (the 2048 mechanic word for word):** an OPTIONS
  button opens the board-size sheet; owned sizes show SWITCH with the
  are-you-sure (switching wipes the round); locked sizes are LOCKED and
  their tap walks to the SHOP; the SHOP sells them (buy -> are-you-sure
  -> the board applies, a fresh sheet reads it as ON — the v0.3.8-8
  fresh-sheet law).
- **The shop (5-5):** 5 stone skins (first = IVORY & CHARCOAL, owned) +
  5 themes (board wood + room), real prices, grayed when unaffordable.

## The boards (owner: "8x8? then 10x10 then 12x12")

| size | name    | price | note                          |
|------|---------|-------|-------------------------------|
| 8    | 8 x 8   | 0     | normal - the default board    |
| 10   | 10 x 10 | 1800  | bigger - the wide board       |
| 12   | 12 x 12 | 3600  | the monster board             |

Five in a row on 8x8 is tight and tactical; 12x12 breathes. The equipped
size persists (Box `item_on`), switching starts a fresh round.

## The CPU (static core, the xo probe contract)

- `winner_of(board, n, to_win)` — 0 none / 1 player / 2 CPU / 3 draw,
  `cpu_pick(board, n, profile_id, mem, rng)`, `remember(mem, record)`,
  `adapt(mem)` — all STATIC.
- Threat tallies per empty cell over four directions: open four, four,
  open three, three, open two, two — attack + defense weighted. Cells
  far from every stone are dead (the near-law, distance 2).
- Four profiles: **wall** (defense-first), **trick** (fork hunter),
  **rusher** (attack-first), **sage** (balanced) — same invisible
  rotation law as XO/fourline ("just keep it one name: CPU").
- `miss_win` / `skip_block` / `fork_watch` / `noise` per profile: strong
  blocks, small miss chances, a fork-watch that wakes wide when the
  memory says the player forked recently (the xo law).
- The 2-round memory: `open` = the player's first stone, `reply` = the
  CPU's first answer — same opening twice means the burned reply never
  repeats and the winning reply is trusted once.
- Programmed failures everywhere: it is always possible to win.

## The look (code-designed, primitives only)

- Honey-wood board with subtle grain strokes, ink grid, star points;
  stones with radial shading + a soft contact shadow; the last move
  wears a small marker dot; the win line is an amber strike that draws
  once and stays.
- Stones settle with a tiny drop-bounce; a placement ripple rings out;
  the aim ghost previews the intersection under the finger.
- The coin bobs and glints on its intersection (the xo coin law).

## SFX (tools/v039_audio.py)

`bv_stone` (wood clack) · `bv_denied` (occupied point) · `bv_win` ·
`bv_lose` · `bv_draw` · `bv_coin` · theme `bv_theme.wav` (calm board
loop).
