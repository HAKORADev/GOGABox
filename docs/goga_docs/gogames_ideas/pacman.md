# DOT EATER — the endless maze chomp (Balldozer's home game)

Graduated from the workshop in v0.3.9-5 (the owner's patch-5 round). The
teaser was parked as **DOT MUNCHER** (the thirteenth dump, "pacman-like");
the owner renamed it before graduation: "dot eater better so dot eater".
The honest ancestor is the 1980 arcade original — "this is a very old game
so i know that you know how to do that". The character is **BAL.DOZER**
(hereafter Balldozer), the owner's cross-game ball: it will be the
ball/circle in every ball game from now on (it already took Snowy Tower's
default roller seat in this same round — renamed from "Snowball").

## THE OWNER'S CONTRACT (v0.3.9-5, verbatim intent)

- **The name**: DOT EATER, not DOT MUNCHER.
- **Horizontal only** — the maze runs landscape (the maze escaper frame).
- **ENDLESS RANDOM MAZES**: the original was "supposed to be endless" (the
  level-256 kill screen made 255 the end) — ours IS endless, and RANDOM:
  "i recommend you to go with the random one, because static one means
  players will get used to it almost instantly". Every level 1 is fresh.
  The generator must still produce "patterns and proper design" —
  braided corridors with loops, never a cornerable tree.
- **The controls** — swipe, the maze escaper verb, but with THE ORIGINAL
  PACMAN THING: "it goes all the pathway until another movement come".
  THE JUNCTION BUFFER (the owner's own numbers): "we have a long path,
  and the next way is at 10 and we are at 5: doing the move will NOT be
  recorded. doing the move at 7-8 will be recorded, to be applied at 10.
  doing it at 10 will do it instantly. doing one at 7-8 then doing
  another before going through 10 will NOT record it." One buffer slot,
  a pre-junction window, no early records, no double records.
- **Wrap tunnels**: "pacman has some of it's walls opened to the other
  side, make sure to make this thing too".
- **NO FRUIT** ("pacman has fruits which gives high amounts of score, we
  do not need this here").
- **THE MAGICAL DOT**: makes you faster, makes the ball-eaters slower and
  EDIBLE for an amount of time. "do it accurately." Color: BLUE ("because
  the rush-like effect that happens from it"). AND THE COUNTDOWN IS
  VISIBLE: "i recommend you to add the count down as a widget here too,
  will be good because original was letting it hidden".
- **The dots are GOLDEN.**
- **The enemies are BALL-EATERS** — four of them ("ball-eaters will be 4
  too"), the ghosts' job with round bodies and mouths of their own.
- **The character is BAL.DOZER** with a BITING animation ("make sure to
  make the biting animation of balldozer").
- **The economy (the owner's numbers, exact)**:
  - dots are NOT score and NOT currency ("collecting dots will give 1 dot
    points, 1 dot 2 dot 3 dot" — a dot COUNTER, nothing more);
  - every 500 collected dots = ONE EXTRA LIFE ("collecting 500 will give
    one extra life");
  - the run starts with 3 LIVES; the run ends when all lives are gone;
  - SCORE comes from completing mazes: each maze = 1 point;
  - a GOGACoin appears in place of a normal dot after EACH 3 MAZES;
  - the box score bonus is /3 (registry coin_div 3).
- **The shop**: skins and "different cool themes", the default theme the
  known NEON ("geometry flash and maze escaper have that type of neon").
  "Other themes should be different things and not just colors somehow" —
  each theme changes HOW the maze is drawn, not only the palette.
- **The lore**: "the lore text dialogue will appear same way as space
  invaders or cursed dario". A lore at the VERY FIRST START and a lore at
  the VERY FIRST END ("i wonder where i will find myself next, whether
  here again, falling from a tower, breaking bricks or finally out of the
  box"). TAP ANYWHERE TO START state. NO optionals / options for now.
- **The character lore**: "balldozer is a hyper-active ball that goes
  through 2D and 3D universes and trapped into a game box from game to
  another and always finds itself in different worlds and just
  brain-washed to the supervisor controls (aka user inputs in a funny way
  i mean)". It joins Geoquare (geometry) and Dario in the conscious-cast.
- **Everything else** — SFX, music, VFX, animations, smoothness, game
  guide, thumbnail, entry, rate-limits — the house standard, left to the
  builder ("that's the game, the rest are left for you as always").

## THE BUILD (v0.3.9-5)

- **The maze**: recursive-backtracker carve on a half grid, MIRRORED
  left-right (the original's symmetry, "patterns and proper design"),
  then BRAIDED (every dead end gets a knock-through — loops everywhere,
  you can never be cornered with no exit), a spawn PLAZA punched open in
  the middle, and WRAP TUNNELS on 1-3 rows (the left opening joins the
  right). Grid grows every few mazes (cap at the cell-fit floor), so the
  mazes breathe bigger as you climb. Dots fill every corridor cell.
- **The buffer**: window = 2.5 cells before the next junction. Swipe at
  the junction = instant. Within the window = the single slot fills. A
  second swipe while the slot is full = ignored. Too early = ignored.
  Reversal is always instant (the original's mercy).
- **The ball-eaters**: four bodies, four drives — the hunter (chases),
  the ambusher (aims ahead), the flanker (works the mirror side), the
  mood-swinger (chases far, sulks near). Scatter/chase waves like the
  original; during the RUSH they turn scared-blue and flee; eaten ones
  become eyes that run home and come back.
- **The rush**: BLUE dot. Balldozer x1.32 speed, ball-eaters x0.55 and
  edible, 7.0s on the widget countdown.
- **The shop**: 5 skins (Balldozer coats), 4 themes that change the DRAW:
  NEON (glow-line walls, the gf shader world), ARCADE (the double-stroke
  blue on near-black, white dots), DUNGEON (thick stone blocks, warm
  torch dark, ember diamonds), CANDY (a light pastel page, rounded
  candy walls, sugar pearls).
- **The guide, the rate-limits, the entry, the achievements**: the house
  standard — fee 8, price 450, bonus /3, banner on, landscape only.

## THE REPAIRS (v0.3.9-6, the owner's first-test report)

- **THE STORY SHEET TRUTH**: the lore card was built with a raw
  `Arc.sheet` — the game_base sheet STACK stayed empty, so the START
  button's `sheet_pop()` was a silent no-op: the dialogue never closed,
  the dim ate every tap, the game could not start AT ALL ("the biggest
  L here"). The sheet's exact dim+center pair is tracked and freed by
  the button now (the invaders `_story_pair` pattern, word for word).
  The Xvfb rig presses the START button with a real finger event and
  proves the dialogue dies + the gate appears + the tap starts the run.
- **THE NAME LAW**: "character name is bal.dozer instead of balldozer
  which is weird because it is double l" — BALLDOZER everywhere, no
  dots (the skin, the lore, the gate, the shop headers).
- **THE DOT WIDGET TRUTH**: "the dots and score widgets next to each
  other and there is no visual feedback to which is which" — the dot
  counter wears a LIVE dot icon painted from the theme's own dot color
  (gold on neon, pearl on arcade, ember on dungeon, sugar on candy);
  it re-paints when a theme equips. The score chip stays as-is.
- **THE WRAP TRUTH**: the opened-wall area now reads REALLY open — the
  old half-moon mouth circles are chevron arrows pointing off-board,
  and a wrap flight walks the body OFF one edge while its other half
  EMERGES on the far edge (two honest copies, `_travel_px`). The old
  whole-board glide swept phantom collisions through the middle — the
  owner's "crash when i swipe 3/4 times, maybe i get eaten" was the
  seam glide killing him mid-board. Every body draws and collides on
  ALL its copies now.
- **THE PEN LAW**: "i saw the ball-hunters area without that
  ghost-gate rectangle/square thing" — the pen is a sealed HOUSE: the
  perimeter walls close on BOTH sides (the old plaza opened the pen
  cells' flags only — ONE-WAY walls: walk out through a face, bounce
  off the next), ONE door at the top middle, and the door wears the
  classic pale-rose GATE BAR, drawn on every theme. A pen-safe braid
  fixup re-loops any corridor the seal stranded.
- **THE SIZE LADDER**: "different maze sizes and not one size that get
  shuffled from shape to another" — the maze grows every 2-3 runs:
  15x9 up to 35x19 (cols stay 4m+3 for the mirror seam), the cell
  floor keeps everything human-visible (the maze escaper scaling law).
- **THE MERCY LAW**: a 1.1s spawn breath after every READY — no eater
  kills inside it (the old run could die three bites in).
- **The thumbnail**: in-game capture (the thumb_capture rig + a
  pacman_drive autopilot: the dense 35x17 maze, the BLUE rush armed,
  real greedy swipes) cooled by `tools/v0396_pacman_thumb.py` — bloom,
  vignette, saturation. No baked text.
