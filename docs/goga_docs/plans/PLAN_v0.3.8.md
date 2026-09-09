# PLAN v0.3.8 — DOMINO + CHECKMATE + the maze ear/clock fix

The owner: "make v038 with this… GO!" — two new games graduate from the
SOON row (domino, chess), Maze Escaper gets a new solve sound and a
stricter clock, and the v0.3.7-2 feed rollback gets a hard integrity
re-verification (the owner worried the rollback had eaten the leveled
chains or the requirements — it did not).

## 1. THE FEED ROLLBACK AUDIT (the owner's fear, answered first)

> "i am not sure what you mean by meters and chains are chains… all i
> asked for was only to make the sort as the old one… for the requirements
> i said nothing, so make sure what you made as a roll back wasn't erasing
> the leveled chains or requirements"

"Chains are chains, meters back to 100/100/200" was shorthand for the
registry's reveal LADDER shape (which games chain-reveal behind which
played counts and at what price meters) — not a change to it. The audit
(`scripts/reveal_map.py`, run against the v0.3.7 registry) diffs EVERY
reveal block old-vs-new: kinds, appear_after, prices, fees, coin_divs,
needs_games — **zero diffs**. The v0.3.7-2 rollback re-sorted the feed
and restored the old ladder values it had inherited from patch 1's
re-sort; nothing was erased. probe_v037p2's feed-restore battery (15
checks) re-runs green every suite pass.

## 2. MAZE ESCAPER — the ear + the clock

- **THE SOLVE TRUTH**: the old `m_win` (a 3-note bell rise) was the same
  musical shape as the box's end-of-run jingle — the owner heard one
  sound twice. The map escape now wears `m_solve`, a portal-warp timbre
  (a downward warp sweep + sparkle — a completely different voice); the
  run end keeps its jingle. `m_win.wav` deleted.
- **THE TIME LAW TIGHTENED**: budget = `4.5s + 0.42s/cell` (was `10s +
  0.8s/cell`), clamp 13..62 (was 24..99). The flight check: an expert
  swiping at the 12 cells/s cap needs ~0.083s/cell of pure travel; the
  new budget pays ~0.42s/cell — reading and planning eat the rest. Hard
  on the idle thumb, fair to the planner — "much stricter but ensure it
  is not impossible".

## 3. DOMINO graduates (portrait — docs in gogames_ideas/domino.md)

The full classic draw game: 28 tiles, 7/7/14 deal, highest-double opener,
tap-tap AND drag with true hand/board scales, the elbow snake with board
down-scaling, green end glows only where the tile truly fits, boneyard
diet + pass + the blocked law, 4 rotating CPU moods with the 2-round
memory, win +1 / lose −1 / draw 0, bonus /2, a GOGACoin on a live end
spot after every 3rd round (the CPU races you), 5 tile sets + 4 felts in
the direct shop (150–340), 10 achievements, 10 synthesized SFX. The probe
plays 600 seeds headless against the static rules core — ALL PASS.

## 4. CHECKMATE graduates (landscape — docs in gogames_ideas/chess.md)

Full legal chess: perft-certified move gen (20/400/8902), castling with
every condition, en passant, promotion + underpromotion, check/checkmate/
stalemate, the 50-move rule, threefold, insufficient material. SIX hidden
CPU personalities (STARTER / AGGRESSOR / JOBAVA / TRICKSTER / ROYAL /
FLANKER), each with its own opening book — the chess.com study shape: a
book + style knobs + a real mistake model — and the 2-round adaptive
memory. Win +1 / lose −1 / draw 0, bonus /1, a GOGACoin every 3 minutes
on a reachable square. 4 piece sets + 4 boards (180–340), 10 achievements,
12 SFX. Dots/rings/tints/check-glow everywhere; drag or tap-tap.

## 5. THE STUDY (tools/study/ — the owner's "repo tools")

- Loop Games Domino 2.6.0 (259.9MB XAPK): Unity IL2CPP — the global
  metadata dump gave the tile anatomy + the mode list (classic draw =
  our one mode). No code reused; the rules are written from the public
  classic and probe-pinned.
- chess.com 4.10.13 (183.9MB XAPK): the assets side — the personality
  bins decoded as Polyglot opening books (one per named style), the
  sound anatomy, the board themes. The engine, books, art and audio are
  our own originals.

## 6. THE VISUAL QA ROUND (8 Xvfb rigs, all eyeballed)

dom_ready / dom_mid / dom_shop / chs_ready / chs_mid / chs_shop + TWO new
gate-truth rigs (dom_gate / chs_gate: a live round → a mid-play shop
round-trip → the shot). The round caught three things:

1. **THE STALE TABLE** — domino's table layer (boneyard pile + count, CPU
   fan + count) never redrawed: the boneyard label read 28 forever after
   the deal ate half of it. THE LIVE TABLE LAW: `table_l.queue_redraw()`
   joins the tick's redraw block.
2. **THE TOAST SEAT** — the shared toast seat (−180..−120 off the bottom)
   printed THE CPU HOLDS THE OPENER straight across the fresh hand fan.
   Domino re-seats the SAME one overlay onto the felt above the hand
   (the newest-wins law untouched).
3. **THE GATE TRUTH** — `_goga_sheet_popped` re-showed the tap-anywhere
   gate UNCONDITIONALLY: any mid-play shop visit floated TAP ANYWHERE TO
   START over the live game (both new games). The gate now returns ONLY
   over the ready state.

Investigated and cleared: the chess score widget's right edge (pixel-
measured 16px margin — the same house convention as the host bar's 14px;
the "overflow" was a thumbnail-scale misread).

## 7. TESTS (the full sweep, all green)

- flow_test ALL PASS (16 playable boot clean, the menu, the sheets, the
  plugins, the isolation)
- domino_probe ALL PASS (28-tile deck, deal law, conservation every ply,
  blocked law, the coin race, 4 moods × 600 seeds legal)
- chess_probe ALL PASS (perft 20/400/8902, the endings battery, the
  books, the memory, the coin minute, the score floor)
- maze_probe 30/0 (the tightened clock + the new solve sound ride the
  same laws)
- probe_v037p2 25/0 (the shelf counts updated for the graduation: 16
  playable / 3 teasers)

## 8. SHIP

Version **0.3.8 / 30900** (arm32 30901 / arm64 30902), cert unchanged,
NO release (the law). The owner tests this build together with the
not-yet-tested v0.3.7-2 and reports back.
