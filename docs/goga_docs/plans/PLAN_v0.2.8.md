# PLAN v0.2.8 — 2048 verdict round II + XO reborn

Owner feedback on the shipped v0.2.7, plus the next game. "Take your time
doing everything very good" continues to be the law. The brainstorm file
(THE_APP_STORE_QUESTION.md) was written FIRST per the owner's order.

## 2048 (merge) — the verdict items

- [ ] 1. Classic background is BLUE (the owner never wanted that outside
      Deep Sea): Classic gets a really suitable backdrop — the warm paper
      cream of the real 2048 palette, warm dust, soft vignette. Registry
      desc + theme desc updated.
- [ ] 2. Collected coins never disappear (stale canvas item — coin_layer
      only redrawed while coin_cell was alive): explicit redraw on take +
      the tick redraws the layer every frame like the other themes.
- [ ] 3. Sea water is a direction-driven fake (a "weird wave", moves even
      when the square does not move — swipe into a wall and the still
      water sloshes). REBUILT as real motion physics: per-tile spring
      driven by the tile's ACTUAL position deltas (acceleration of the
      container), damped settle, tilt + energy to the shader; the shader's
      time-wave dies — no motion, no motion of water. Natural meniscus,
      no more weird wave.
- [ ] 4. OPTIONS menu: 4x4 normal / 6x6 / 8x8; 6x6 and 8x8 are shop items
      bought for real prices first; 6x6 bonus /80, 8x8 bonus /160 via a
      modular per-game bonus_div_override (host reads it; no game names
      in the economy). Switching size starts a fresh board.
- [ ] 5. Thumbnail: the "+1" over the empty hole renders with the Kenney
      "1" glyph that reads as "41" (owner: "an empty square has number
      41 which is weird") — the pop is REMOVED and the scene re-composed
      on the new warm classic background.

## XO — the rework (was XO Ladder)

- [ ] 6. Renamed to plain XO everywhere (registry, guide, thumb scene).
- [ ] 7. Full remake, SKETCH design like the owner's xo html: paper
      background, white board with hard ink offset shadows, red X /
      blue O hand-drawn strokes (wobble + under-shadows), symbols pop in
      with overshoot + rotation, winning cells pulse amber, thinking
      dots while the CPU thinks. Smooth animations everywhere.
- [ ] 8. New designed SFX (v028_sfx.py): pencil scratches for X/O, win /
      lose / draw voices, a paper tap.
- [ ] 9. YOU / DRAWS / CPU widget (the html score-board shape).
- [ ] 10. Scoring: win +1, lose -1, draw 0. Run bonus /2 (registry
      coin_div 2). The bank path is the PONG design: pause sheet END
      button (pause_end_run) — the CASH OUT button dies.
- [ ] 11. GOGACoin every 3 rounds: the 4th round opens with a coin in a
      random EMPTY cell; whoever marks that cell takes it (CPU can take
      it too — it is a race). Real coin.png painter, fade-in, glint.
- [ ] 12. THE ADAPTIVE CPU (no difficulty levels): four profiles
      (WALL / TRICK / RUSHER / SAGE) rotated across rounds — good enough
      to rarely lose, not smart enough to always win (small miss chances
      on wins/blocks per profile). A 2-round FIFO memory adapts on the
      fly: repeated openings get a different response (the burned reply
      is not repeated), fork history raises fork-scan, opener habits
      pre-seed the counter-move. Memory forgets after 2 rounds.
- [ ] 13. Achievements: rung/streak trio replaced by wins/streak laws
      (Pencil Pusher 10, Sketch Master 40, Unstoppable 5 in a row).
- [ ] 14. XO thumbnail rebuilt to the sketch look (no ladder); registry
      desc/controls rewritten; xo.md journal born; merge.md verdict
      chapter.

## Quality gates (the shipping law)

- [ ] 15. tests: xo_probe.tscn new (AI laws: takes wins, blocks, rarely
      loses vs random, adaptable replies, memory FIFO cap 2, coin laws,
      scoring laws) + merge_probe grew the v0.2.8 laws (grid options,
      div overrides, water stillness when still, coin vanish) + flow_test
      (xo /2, div overrides, achievements).
- [ ] 16. Xvfb :99 qa_v028 screenshots of BOTH games eyeballed BEFORE
      shipping (the owner rule).
- [ ] 17. Version 0.2.8 (base 30370: arm32 30371, arm64 30372), dual-ABI
      build, cert check (6db87aca...), APK backups, push main, worklog.
