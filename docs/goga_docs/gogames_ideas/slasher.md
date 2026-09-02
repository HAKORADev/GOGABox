# FRUIT SLASHER — the v0.2.9 journal

The box's oldest stub (185 lines: brown rectangle, pixel fruits, combo
scoring, one bomb = dead) got the owner's verdict: "currently it's too
bad, even my PGB v1.3.8 is bad so you have nothing as reference". A clean
sheet, his spec.

## THE SHAPE OF THE GAME

- THE POSITION ASK first (the snake flow, orientation "auto"): portrait
  and landscape are genuinely different games — portrait tosses fruit up
  from below (gravity 1560), landscape lobs it across from the left
  (gravity 1180, flatter faster arcs, wilder spin). The options screen
  follows: the VEGETABLES gate (BUY 1500 once -> a FRUITS/VEGETABLES
  toggle) and START.
- THE REAL SLICE: the owner's core wish — "cut the fruit in that place
  and split it with physical flips". The slash segment is mapped into the
  fruit's local space; the sprite's square is Sutherland-Hodgman-clipped
  against the cut line; the two pieces are reborn as textured Polygon2D
  halves with the juice-soft flesh implied by the art, thrown apart along
  the cut normal with flips and a fade.
- THE FEEL: a tapered glowing blade ribbon (pale glow + white core), a
  flash line on every cut, per-fruit juice droplets (14 tints) thrown
  against the cut direction, a wet splat ring, and three wet-cut SFX
  variants pitched per fruit.
- THE ECONOMY (the owner's numbers): fruit +1, fallen fruit -2 (floor
  0), three hearts, a slashed bomb takes one, 0 hearts ends the run, run
  bonus /15. A GOGACoin rides by every 20 seconds from the last one —
  slash it like a fruit.
- THE +N / -N READER (his no-combo pivot): one fast swipe counts
  +1 +2 +3 in a single top zone (young entries MERGE — never spam), and
  falls inside a 0.9s window flush as one honest -N beside it.
- THE SPAWNER: single / pair / fan / ROW patterns, speeds that grow with
  the clock plus occasional fast ones, and every ROW carries a sneaky
  bomb tucked between the fruits.
- THE ART: the online hunt (GameArt2D freebies: no fruit pack; OGA fruit
  pages: preview JPGs only; Kenney's food kit: JS-gated) came up empty —
  documented in docs/ASSETS.md's spirit — so the wardrobe is PAINTED:
  8 fruits (watermelon, orange, apple, lemon, pear, strawberry, peach,
  plum) + 6 vegetables (carrot, tomato, eggplant, broccoli, corn,
  pepper), each a silhouette + a generic soft-shading pass (rim shadow,
  top-left light, specular, bounce) + a contour. The pear is stamped
  along a curve (no two-circle seams). The thumb wears the new look with
  a split melon whose flesh face is masked to the silhouette.
- ACHIEVEMENTS: Untouchable (bank a run with all three hearts), Sharp
  Blade (300 in a run), Juice Bar (100 slashed total).
