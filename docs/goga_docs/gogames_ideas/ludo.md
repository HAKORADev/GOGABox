# BOARD LUDO — GDD (v0.3.9-10)

> The owner's verbatim intent, pinned before the script. Ludo descends from
> Pachisi; the word LUDO itself is trademarked, so the shelf name is
> **BOARD LUDO**. The honest brain is the classic ONE-DIE ludo the owner
> grew up on ("to me, the original one dice is the better choice").

## The verdict from the field

v0.3.9-9's CONQUER DICE landed ("this game and brick breaker are considered
complete to me") — this patch is the next shelf game plus the dice game's
honesty fixes (the silent in/out SFX, the easy CPU, the swapped shop).

## The modes (the owner's own split)

Ludo is usually 4 players, but 2 works two ways. The game asks at the START
(a mode menu, not an options button — "no options button here"):

- **x1 — ONE ARMY**: the user plays one side (army 1), the CPU one side
  (army 2). 4 chess-like figures each.
- **x2 — THE DOUBLE**: the 4 sides pair up; the user is **1 and 3**, the
  CPU is **2 and 4** — turn after turn around the table. THE ALLY LAW
  (the owner pointed it so we would not miss it): the user's two armies
  behave as ONE team — they never eat each other, they may sit side by
  side and stack, exactly "like if they were from the same square".
- **x4 — THE CHAOS**: every side is a real opponent (user + 3 CPUs). Cool
  chaos, the owner green-lit it twice ("ok really do it then").

Modes are FREE (no shop item) — the ask is "optionals menu at the start".

## The rules (the owner is a ludo player — these are HIS words)

- **ONE die**, the original. Two dice only speed the game up; we do not.
- Roll a **6** to drop a figure onto your start cell, and a 6 **grants
  another roll** (drop AND roll again, the classic law).
- Move one figure forward by the roll. Landing on a foe figure **eats it**
  — it slides the whole way back to its base (the owner's animation ask).
  NO bonus moves for eating or for reaching home ("we do not need these
  bad stuff here" — no 10/20 move points, ever).
- **THE GUARDED DROPS**: the four colored start cells are safe — a figure
  standing there cannot be eaten. (The reference game's isSafeSquare is
  the same law; the owner: "the ludo game has the guarded areas of drop
  point".) The four star cells are safe too, the classic board's own law.
- **THE BLOCKADE**: two figures of one team on the same cell form a block —
  foes cannot pass NOR land on it, the owning team passes freely, and a
  THIRD figure can never land on the pair ("illegal to land the third one
  in it"). The pair slides mid→side to show it; unblocking slides it back.
- The colored home lane is exclusive to its own team; the final home needs
  no exact count beyond the lane's own math (a roll that overshoots the
  lane's end is simply illegal — the classic law).
- First team to bring ALL its figures home wins the round. **No draws.**

## The turn flow (the owner's UX, better than the reference)

- Vertical. The board is a square — portrait seats it with proper side
  rooms for the dice (the reference used top/bottom strips; ours is
  bigger: the dice live in the side rooms with the army trays).
- "Tap anywhere to play" gate. The user opens round 1; **the loser opens**
  the next round. No draws, so the flip is clean.
- The player marks are bare numerals **1 2 3 4** at their corners ("they
  called players player 1..4, you can just make them 1,2,3,4 - the
  correct way").
- **THE DICE THEATER**: the die is NOT always visible. When a turn starts,
  a ROLL button fades in at that army's dice seat. Tapping it fades the
  die in, it shuffles, and it settles on a face. Legal moves → the arrows
  wake; no legal moves → a soft denied beat and the turn walks on. The
  CPU wears the same theater on its own seat.
- **THE ARROWS**: when moves exist, a bouncing arrow rides each movable
  figure; tapping the figure paints arrows on every legal destination
  (and on the start cell when a drop is legal). The arrow's ink and shape
  belong to the theme.
- **THE HOP WALK**: a figure walks cell by cell — a little up, over, drop
  — at a proper speed, neither too slow nor instant. An eaten figure
  SLIDES the whole way home. A forming block slides mid→side.
- **THE END BUTTON** in the pause menu banks the run (the pong law — a
  ludo run has no natural death).

## The economy

- Win **+1 score**, loss **−1**. Run bonus **/1** ("ludo turns always take
  too long anyway") — registry coin_div 1. No draws, W/L widget only.
- **THE COIN CLOCK**: one GOGACoin appears after every **6 in-game
  minutes** ("a ludo game takes more than 15 minutes anyway"), on a track
  cell that is LEGAL for the player right now — reachable by one of the
  user's figures before it would have to turn into its home lane. Whoever
  walks over it takes it — passing through collects, no need to land; a
  foe stepping on it steals it. It wears the GOGACoin icon at a proper
  scale.

## The look

- Colors: **green, yellow, red and blue** — the owner "is not sure" about
  the exact wheel order, and it does not matter: everything is skinnable.
  Shelf order 1=RED, 2=GREEN, 3=YELLOW, 4=BLUE, clockwise from top-left.
- **5 THEMES** (first is default) own the room, the board frame, the
  track, the trays, the die, the arrow and the feel. **5 PIECE SKINS**
  re-ink the USER's figures only (the theme-matched default + 4 bought),
  on every theme — the Conquer Dice ownership law, chess-like dialect.
- The die's face style differs theme to theme. VFX wear theme colors.

## The CPU

**No AI. No profiles. Pure RNG.** ("there is no AI or profiles here,
there is just a move that will happen or not and pure RNG") — the CPU
rolls the same die and picks UNIFORMLY among its legal moves. The drama
comes from the board, not from a brain.

## The shelf entry

- id `ludo`, title **BOARD LUDO**, portrait, shop, banner (turn-based),
  price/fee in registry, achievements (wins, captures, coins, streaks),
  desc + controls for the pre-play ? menu, thumb via the composer.
- Audio: one synthesized theme song + the satisfying set (roll shuffle,
  drop, hops, the eat-slide, the block, home arrival, coin, win/lose).
