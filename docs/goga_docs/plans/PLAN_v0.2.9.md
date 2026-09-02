# PLAN v0.2.9 — XO patched + Fruit Slasher reborn

The owner's XO verdict round (patched into the same cycle), then the next
game as the real new version.

## XO — the patch list (all landed)

- [x] THE BIG BUG: after the player's move the CPU played round after
      round — the state stayed "ai_wait" when the turn came back (the
      refactor lost the else branch). One move each, always. Probe law
      added (3 seconds of ticking = zero extra CPU marks).
- [x] THE LOSER OPENS next round; a draw flips the opener.
- [x] THE SCORE FLOOR: a loss at 0 stays 0 — never -1 -2 -3.
- [x] REAL SKETCH MARKS: the owner read the v0.2.8 marks as "polygons" —
      no more Line2D segments: strokes are smooth layered-sine noise
      painted as circle stamps with a tapered width and ink breathing,
      over dark under-strokes. The O's close overlaps like a real ring.
- [x] ONE NAME: the CPU. The four moods rotate invisibly (no WALL /
      TRICKSTER / RUSHER / SAGE in any text).
- [x] THE WINNER ANIM: just the yellow strike — the amber cell highlight
      is gone, the mark zoom/pulse is gone, and the strike draws ONCE
      (the old one oscillated forever — "acts very weirdly").
- [x] The "next GOGACoin lands in N rounds" note line is REMOVED.
- [x] THE SFX MATCH THE DESIGN: the dry pencil-scratch set was replaced
      by a soft cozy sketchbook set (warm plucks, mallet tones, a whisper
      of paper) — tools/v029_sfx.py.
- [x] THE AI MISSES: the miss/block-skip knobs grew (win-miss ~0.10-0.13,
      block-skip ~0.08-0.17) — vs a decent player the CPU now drops ~9%
      (the user can win sometimes) while still drawing most games.

## Fruit Slasher — the rework (the real v0.2.9)

- [x] THE POSITION ASK FIRST (like snake): portrait tosses fruit up from
      below (g 1560); landscape lobs it across from the left (g 1180,
      faster flatter arcs, more spin). Orientation registry "auto".
- [x] THE OPTIONS: the vegetables gate lives there — BUY 1500 once, then
      a FRUITS / VEGETABLES toggle feeds the spawner.
- [x] THE BACKGROUND: dusk gradient, three drifting light rays, floating
      bokeh, a soft floor shade — minimal, cool.
- [x] REAL SLICING: the fruit is cut AT the slash segment — the sprite's
      local square is polygon-clipped against the cut line and reborn as
      two textured Polygon2D halves that fly apart with physical flips
      and fade; a glowing tapered blade ribbon + white core; a flash line
      on every cut.
- [x] THE VFX/SFX: per-fruit juice colors (14 tints), droplets thrown
      against the cut direction, a wet splat ring, and a designed wet-cut
      SFX trio (sl_cut_a/b/c) + whoosh + bomb + heart + miss + coin +
      launch + over voices (tools/v029_slash_sfx.py).
- [x] THE ECONOMY: fruit = +1; a fallen fruit = -2 with the score floor
      at 0; three hearts — a slashed bomb takes one, 0 hearts ends the
      run; run bonus /15 (registry coin_div 15).
- [x] THE +N / -N READER (the owner's no-combo idea): one fast swipe
      counting +1 +2 +3 in ONE top zone (entries merge, never spam), and
      falls flushing as a single -N beside it.
- [x] THE SPAWNER: patterns (single / pair / fan / ROW), speed that grows
      with the clock (+ occasional fast ones), and a SNEAKY bomb tucked
      inside every row of fruits.
- [x] THE COIN: a GOGACoin every 20s from the last one, tossed like any
      fruit, collected by slashing it.
- [x] THE ART: the online hunt (GameArt2D freebies, OpenGameArt, Kenney)
      found no fruit packs — so 8 fruits + 6 vegetables are PAINTED
      (silhouette + generic soft shading + contour; tools/v029_fruits.py)
      and the watermelon halves carry a masked flesh face.
- [x] The thumbnail recomposed to the rework (dusk, painted fruits, the
      split melon + juice, the ribbon, the coin, the glowing bomb).
- [x] Achievements: Untouchable (end a run with all 3 hearts) replaces
      the combo law (combos are gone by design).

## Quality gates

- [x] tests: slasher_probe.tscn NEW (modes, ask->options->run, +1/-2
      floor, hearts/bomb/0-hearts, the halves fly, the coin 20s law, the
      veg gate, the sneaky-row bombs), xo_probe grew the state/opener/
      floor/strike laws, flow_test grew the /15 + auto + shop laws. ALL
      SUITES EXIT 0.
- [x] Xvfb qa_v029: the marks, the clean strike, the ask, the options,
      the fruits, the slice (halves + juice + the reader), the bomb-heart
      — eyeballed BEFORE shipping.
- [x] Version 0.2.9 (base 30380: arm32 30381, arm64 30382), dual-ABI
      build, cert check, backups, push, worklog.
