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

## v0.3.0 — THE VERDICT (the real face)

The owner played the rework and sent a list headed "work harder on it so
it gets even better than the real fruit ninja bruh!". What changed:

- THE SLICE WAS INVISIBLE — root cause: the v0.2.9 halves were polygons
  in a UNIT square scaled by the item scale (~0.5) = sub-pixel sprites;
  all he saw was the splat ring and a fade. The fruit now swaps for its
  two REAL pre-drawn halves (the classic art set ships them), aligned so
  the flat faces sit on YOUR cut line, thrown apart with flips.
- THE CLASSIC ART SET landed (the hunt: Kenney is a JS shell now, OGA's
  fruit packs are pixel art or CC-BY-SA samples, the GitHub crayon pack
  was reviewed and skipped) — apple, banana, basaha, peach, sandia, each
  whole + two halves, the boom, the flash glint, the smoke, and the WOOD
  BOARD (composed into portrait/landscape plates with mirrored tiling).
  Source: github.com/ChineseDron/fruit-ninja (the classic html5 clone
  set), documented in ASSETS.md. The painted fruits retired from the
  spawner; they remain the vegetables stand-in behind the shop.
- THE GLITCH LINE: the v0.2.9 cut-flash drew the entire swipe segment —
  it looked like a glitch streak. Now the classic flash.png glint appears
  only along real cuts, quick and small.
- THE JUICE: bigger stretched droplets + splatter decals stuck to the
  wood (merged blobs + a drip), fading slow — the board remembers.
- THE BOMB: classic art + a real explosion (flash, shockwave, smoke,
  sparks, shake, red pulse) and its own "-1 HEART" floater.
- THE FEEDBACK: the zone reader died — "+1" floats at the cut, "-2"
  floats at each fall. Simple, honest, per event.
- THE ASK: just the two phone cards.
- THE SFX: the wet cuts became squelches (soft slide + snap + plips).
- The sparkles are 4 tiny slow dots now ("small cool things").

## v0.3.1 — the patch round

- the vegs grew (150px target — the painted art sits smaller in its
  canvas than the classic fruits do in theirs)
- BOTH positions now toss from the bottom; the landscape spreads around
  the CENTER ("it throws from the left to the bottom" is dead) — the row
  pattern is a wide bottom row there too
- the slice glint is gone ("we have our own finger-slasher thing")
- THE DYNAMIC SWIPE VOICE: the whoosh was measured (0.16s, peak at
  ~55-75%, ~12k zc/s) and rebuilt as four speed cuts — the swipe speed
  picks lo/med/hi/fast + a pitch nudge, and a voice never overlaps
  itself; "wheeeph or whoph based on slash movement speed"
- the thumbnail recomposed to the current wood look
