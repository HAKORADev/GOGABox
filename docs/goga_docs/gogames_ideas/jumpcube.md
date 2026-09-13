# CONQUER DICE — the jumping-dice war (KJumpingCube energy)

Graduated from the workshop in v0.3.9-9. The teaser was parked as **CUBE
OVERFLOW** (the owner: "cube overflow which is a KJumpinCube-like"); the
owner renamed it: "let's rename it to conquer dice, or dice conquer, i
guess conquer dice is good? maybe" — CONQUER DICE it is (the machine id
stays `jumpcube`). The brain's honest ancestor is KDE's KJumpingCube —
cloned from invent.kde.org and read line by line; the cascade law, the
cap law, the re-push law and the total-conquest verdict are the
original's, ported word for word.

## The rules (the original's own laws)

- An N×N board of dice; every die wakes NEUTRAL with ONE dot.
- A die holds as many dots as it has orthogonal neighbors: corner 2,
  edge 3, middle 4 (THE CAP LAW).
- On your turn, tap a NEUTRAL or YOUR OWN die — the enemy's dice are
  solid. The die grows one dot and turns your color.
- One dot TOO MANY and the die SPILLS: the cap leaves it (value −= cap)
  and one dot flies into EVERY neighbor, flipping them all to your
  color. A neighbor over its cap joins the cascade; a still-overloaded
  popper re-queues itself (THE RE-PUSH LAW).
- THE VERDICT IS TOTAL CONQUEST: own every die on the board and the
  round is yours. The original ABANDONS the cascade mid-air the moment
  the win is read — a finished board never keeps popping (the QA SOAK
  caught the live port cycling forever without this).
- No draws can exist: the only verdict is a total conquest.

## The owner's contract (v0.3.9-9, verbatim intent)

- **Vertical only** for now — "we may do the horizontal one but later".
- **3 sizes**: "medium and big and too big, maybe 4x4/6x6/8x8" — the
  2048 mechanic word for word (bought in the shop, applied from the
  OPTIONS, THE BUY LAW). 4 free, 6 = 1800, 8 = 3600 (the squares ladder).
- **The dice colors**: "user should be red and enemy should be blue as
  always" — the DEFAULT; and "there is no hard rule that tell us to
  make always the user red/blue or something like that, sooo....yeah,
  ART!":
- **5 THEMES, the first the default** — a theme owns EVERYTHING except
  the user's dice: the room, the board wall, the neutral dice, the
  enemy's color, the pip inks, the corner style AND the SFX voice
  ("SFXs should differ from theme to another"). WOOD (free, red vs
  blue on the warm table), BLACK & WHITE ("me as white and enemy as
  black", neutrals gray), PIXEL (the 8-bit table), NEON (the digital
  night), CANDY (the sugar board).
- **DICE SKINS** — "skins should be related to each theme while giving
  the user the ability to change their dice without matching the theme,
  so theme is everything except user-owned dices". The default skin
  wears the theme's own color; CRIMSON / GREEN / GOLD / PINK / CYAN /
  ONYX re-ink ONLY the user's dice on any theme.
- **The economy**: "1 score point per win and each lose takes one and
  score bonus will be /2" (registry `coin_div: 2`); the score never
  goes under zero.
- **The GOGACoin**: "after each 3 levels in a place of a dice that is
  still not conquered yet and whoever reaches it take the coin" — the
  coin rests ON a neutral die; whoever conquers that die takes it, the
  CPU races you.
- **Who opens**: "for now who plays first is the user then the loser
  plays first for other rounds!" (the who-plays-first purchase screen
  idea is parked in FUTURE_GAMES.md).
- **THE HOLD LAW** (the squares/fourline hand, dice dialect): "holding
  on a dice should make it give the pressing effect which is highlighted
  in gray-out and when user release the finger, that dice will get the
  action, if finger released out of board, nothing will happen" — the
  gray-out wash + bright rim on the held die, the drag follows the
  finger, the release off the board cancels.
- **THE IN AND THE OUT** (the animation ask): "the transition animation
  should make the in and the out, where the dice gets the dots or gives
  them" — a spill's dots FLY out of the popping die into its neighbors
  (0.15s arcs), each landing pip pops in, an ownership change
  crossfades the die's color (0.26s), the cascade's sounds RISE in
  pitch as the chain grows ("out will usually make from 2 to 4 ins
  so...it has to feel satisfying in a cool way"), and a chain of 3+
  pops shakes the table.
- **The CPU**: the xo four-moods law — wall / trick / rusher / sage,
  invisible rotation, one name "CPU", programmed failures everywhere
  (miss_take blinds the immediate spill, err_risk fumbles, noise
  jitters; trick + sage wear the reply eye). THE SPILL-SCAR MEMORY (2
  rounds): lose to a 6+ chain and the CPU plays feed-aware for the
  window — it learns the way it lost.
- **The GATE HUSH** (found on the film rig): the tap that closes the
  gate rides an EMULATED mouse press — without the hush that second
  press lands on the live board and the tap's own release plays a move
  under the gate tap point. Presses are swallowed for a beat after the
  gate closes.
- TAP ANYWHERE TO START (the gate, HUD index 0), pause_end_run (the
  pong END bank), the W|L cards + the live RED nn | BLUE nn dice tally
  (the squares seat, before the score chip).
- Achievements: the 15-trophy rule-table ladder (score, wins, streaks,
  dice conquered, big spills, coins, plays).

## The laws the tests pin

`flow_test.gd` pins the registry entry, the shelf tables, the cap law,
the pure move (illegal refused, growth, spill, the re-push storm = 6
pops on the 8x8, pip conservation, the early exit), the moods' eye and
the memory; `tests/qa_v0399_dice.gd` pins the scene laws (the state
law, the gate hush, the hold law with a REAL finger event, the live
cascade = the pure plan, the coin law, the verdicts, the buy law, the
theme-ownership law, the 16-round soak); `tests/film_jumpcube.gd`
photographs the 12 beats (the gate, the press, the spill mid-air, the
coin, the four themes, the 8x8, the verdict).
