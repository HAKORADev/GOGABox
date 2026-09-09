# DOMINO — the owner's GDD, v0.3.8 (from the owner's message)

> The tile classic. The SOON teaser "DOMINO / the tile classic" graduates.
> Base study: Loop Games Domino 2.6.0 (APKPure XAPK, decompiled through
> `tools/study/`) — the tile ANATOMY is what we kept from it: ivory body,
> rounded corners, a center divider line, separate colored pips. All art
> in the box is our own, drawn to that vocabulary.

## 1. THE SHAPE

- **Vertical only** (portrait). One mode: the CLASSIC known dominoes.
- **TAP ANYWHERE TO START**, then the deal flies: one tile to you, one to
  the CPU, alternating, until each holds 7 — the other 14 wait in the
  boneyard (the owner: "the user will tap one, the enemy will tap one,
  until each one has i guess 7? — you know it better").
- Scoring (the XO shape, the owner's law): **win +1 / lose −1 (the score
  never goes negative) / a draw 0**. Run bonus **/2** (registry coin_div 2).
- Fee 10, price **500**, direct reveal, appear_after 7, needs_games 8.
- **No optionals menu** — skins + themes live DIRECTLY in the shop (the
  owner: "letting it direct like other games will be better"). Everything
  past the defaults is BOUGHT.

## 2. THE RULES (the owner trusts the implementation)

- Double-six set: 28 tiles, 7 each, 14 boneyard.
- The holder of the **highest double opens with it**; no doubles anywhere
  = the holder of the heaviest tile opens with it.
- Turns alternate; a tile must match one open end of the snake.
- Can't play: **draw from the boneyard until you can** (or it empties),
  then **pass**. The DRAW button feeds one tile per tap with the count on
  it; an empty boneyard turns it into PASS.
- **Both pass in a row = BLOCKED**: the lighter hand (fewer pips) wins,
  even pips draw.
- Empty your hand = **DOMINO!** — you win the round.

## 3. THE INPUT LAW (both gestures, always)

- **Tap-tap**: tap a tile to lift it, tap a glowing end to play it.
- **Drag-and-drop**: drag the tile onto the end. The dragged tile renders
  at BOARD scale (the hand tile is bigger than the board tile — the owner's
  "proper scale from the domino on the hand compared to the one in the
  ground").
- Ends glow green ONLY where the selected tile truly fits; no fit = no
  glow (and a shake). A tile that fits exactly one end plays on the second
  tap without asking which end.
- **The board scales down as the chain grows** — the owner's "a scale for
  big grounds"; the snake re-flows with elbows and never leaves the felt.

## 4. THE COIN LAW

After every **3rd completed round**, the next round carries one GOGACoin
sitting ON a legal playable spot (one of the two chain ends). **Whoever
puts a domino on that spot takes it — the CPU races you for it.** The coin
bobs, wears a shimmer ring, and flies to the taker's side with the +1.

## 5. THE CPU (the xo law travels here)

One opponent, **four moods rotating invisibly** (one name: CPU): HEAVY
(pip-greedy), KEEPER (doubles + board control), BLOCKER (the end-freezer),
RACY (fast hand dump). Each mood is a weighted pick with **real programmed
failures** (miss_win 6–12%, heavy noise) — good but beatable. The 2-round
memory: feed him on a side twice and he locks that side down.

## 6. THE SHOP (all bought past the defaults)

- **Tile sets (skins)**: BONE (free classic ivory) · ONYX 150 · CHERRY 220
  · JADE 280 · ROYAL 340.
- **Table felts (themes)**: TAVERN (free green) · BLUE QUILT 200 · SUNSET
  260 · MIDNIGHT MARBLE 320.

## 7. ACHIEVEMENTS (10, tiered)

First Chain / Tile Sharp / The Long Table / The Chain Lord (score 5/15/40/
100 in a run), Domino! / Table Regular / The Bone King (10/50/200 round
wins), Coin Snatcher (25 coins taken), Regular / The Table's Resident
(8/40 rounds).

## 8. SFX + FEEL (all synthesized, the box law)

d_pick (lift) · d_place (land) · d_flip (the elbow flip) · d_draw (the
boneyard diet, pitched per deal step) · d_pass · d_blocked · d_win (the
round jingle) · d_lose · d_draw_jingle · d_coin. Smooth fly-overs from
hand to end, the elbow tiles flip, the ends pulse.

## 9. THE PROBE (tests/domino_probe.gd — ALL PASS)

The whole rules core + CPU brain are STATIC (`deck/pips/ends/can_play/
cpu_pick/remember/adapt`) — the probe drives them headless: the 28-tile
deck, the deal law (7/7/14), tile conservation every ply, the blocked law,
the opener law across 600 seeds, all four moods legal, the coin race, the
score floor, the memory law.
