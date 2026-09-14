# THE BOX'S CAST — how GOGABox feels alive (the characters bible)

The owner's hidden work, v0.3.9-13. This file is the vision doc for the
characters that live inside the box — read it before writing any new
dialogue, any new character, any new game that one of the cast could
appear in. Nothing here ships to players as text; it ships as FEELING.

---

## The one idea

GOGABox is not a menu with games. It is an **arcade cabinet that is
alive**, and the games are its rooms. The characters inside them are
aware — not fourth-wall-broken, not winking at a camera: quietly,
trapped-ly aware. The closest cousins are Wreck-It Ralph (games as
places where somebody lives), Ben 10's "Game Over" (the fox who does
not know he is behind a screen), The Stanley Parable / DDLC / Eversion
(the game that knows). The owner's own words on why it works: the box
is "a living prison ecosystem", and playing it is "watching the lore
more than watching myself winning".

Three pillars, taken from the owner's own talk (the Wreck-It Ralph
PDF, 2026-09-14):

1. **THE PRISON.** The box is the whole universe. Nobody gets out.
   Balldozer already said it: "There is no out. There is only NEXT."
   Every loss state, every wall, every reset is the box itself doing
   its job. The characters do not mourn this. They LIVE it — that is
   the existential-horror half, and the humor is how they cope.

2. **THE SUPERVISOR.** The player is not a player to them — it is a
   god-finger, a hive mind, "the SUPERVISOR". It moves Balldozer, and
   Balldozer copes by calling the leash TEAMWORK. It moves the
   platform and the platform calls being wired to a finger "being
   handled". It controls two bodies at once and they draw the only
   possible conclusion: *it can read minds.*

3. **THE TELEPATHY LAW (the text-box meta).** The characters have no
   voices. In-universe, that is not a budget limit — it is the lore:
   the text boxes are their THOUGHTS, and because you can read them,
   they must assume you hear everything they think. The dialogue the
   owner remembers, verbatim: *"balldozer: thank god the user can not
   hear what we say / geoquare: but what if it can read our minds /
   balldozer: it is likely do since it can control both of us
   simultaneously at the same time."* Every silent NPC, every text
   box, every limitation is canon. When you hit a technical wall, add
   it to the lore — the box always has.

The tone: **existential horror played completely straight by cute
shapes.** A square that keeps hitting dead ends is funny. A square that
KEEPS hitting dead ends and remembers each one is GOGABox.

---

## The cast (first appearances, in order of waking)

Each character speaks ONCE EVER per beat — a lore at the VERY FIRST
START (and where noted, at the VERY FIRST END/DEATH) — riding the
shared box story card (game_base.gd `box_story_show`, the typewriter
beat, the character's own color). The counters make it once-ever:
`Box.counter(game_id, "lore_start" / "lore_end")`.

| Character | First appears | Where | Voice |
|---|---|---|---|
| CURSED DARIO | the side-scrollers | dario.gd | the mascot who fell through a Witcher's curse; aware of the endless loop |
| AZURE & THE SSDs | the solar system | invaders.gd + dash.gd | the 5-6 ship crew holding the line since the dash wars; the aliens are EVERYONE's enemy |
| GEOQUARE | the grid | geometry.gd (+ maze skin) | the square that hunts an exit and never finds one; once pretended to be an Ice Cube on a snowy mountain |
| BALLDOZER | the maze | pacman.gd (dot eater), hopper, maze, geometry | the ball that was BORN ROLLING; calls the leash TEAMWORK; "the dot eater, the snow ball" |
| COSMIC SHADOW | **COSMIC SPUD** (v0.3.9-13) | cosmic_spud.gd | the shapeshifter: "shadow can be whatever"; wears a body per world (a square once, a fighter, a gunner, now the spud); its ONE power is being whatever the next world needs |
| THE PLATFORM | **PING-PONG** (v0.3.9-13) | rally/pong.gd | the underpaid employee wired to your finger; watched the square hunt an exit and the ball call its leash teamwork |
| BOARDYBARD | **2048** (v0.3.9-13) | merge2048.gd | the board itself: XO, dominoes, chess, the conquest dice, the ladders — every table game happens ON it; 2048 was its first shift ("tiles, not pieces — but a table takes the work") |
| THE PAWNS | **CHECKMATE** (v0.3.9-13) | chess.gd | the SAME sixteen everywhere: the round board's racers, the ladder board's climbers; brainwashed hardwired — "there is no opinion in a pawn, only a direction"; "we ARE the wash" |
| THE DIE | **CONQUER DICE** (v0.3.9-13) | jumpcube.gd | six faces, zero opinions; the referee of every turn game; hears the round board and the ladder board rehearsing its other jobs |
| THE SNAKE | **SNAKE** (v0.3.9-13) | snake.gd | the one under your finger; knows its cousins sleep flat under ladders on a far board and "just lie there and BE the fall" |
| FROGGY-INSTANT | not yet woken | FUTURE_GAMES.md (the tap-the-frog study) | the twitch frog of the reflex games; misses one timing and the ALIEN VACUUM takes him back — the same aliens the SSDs fight |

### The easter egg — THE TABLE'S SECRET (conquer dice)

Leave the conquest board untouched for EXACTLY sixty seconds of live
play and the box's oldest rumor stands up: the neutral die is
**GEOQUARE** wearing a dice costume, the one dot on it is **BALLDOZER**
(gold, breathing), and they talk — the owner's PDF dialogue verbatim,
popping line after line, a tap hearing the next:

> BALDOZER: I'm bored here. / Being a dot eater was more fun. / Hello?
> GEOQUARE: Who is that
> BALLDOZER: The dot eater. The snow ball. The dot on top of you, Geoquare.
> GEOQUARE: Balldozer? We are both in same place at the same time!? For the first time?
> BALLDOZER: Thank god the user can not hear what we say.
> GEOQUARE: But what if it can read our minds.
> BALLDOZER: It is likely do since it can control both of us simultaneously at the same time.

They have never been in the same place at the same time before. They
still do not know the reader exists. Keep it that way.

---

## The laws of the cast (how to write them)

1. **THE ONCE-EVER LAW.** A character's story beat fires ONCE EVER:
   `Box.counter` + `Box.bump_counter` with "lore_start"/"lore_end".
   Replays never re-tell. A second beat (end/death) is its own counter.
2. **THE SHARED CARD LAW.** All new dialogue rides the shared box story
   card (`box_story_show` in game_base.gd): the character name in ITS
   OWN color, the name bar, the typewriter beat (~55 glyphs/sec, first
   tap completes the line, next tap continues). Never build a raw
   Arc.sheet for a story (the story sheet law 25).
3. **THE AWARENESS LAW.** A character knows the box, knows the
   SUPERVISOR's finger, and knows the OTHER GAMES where it exists. The
   pawns remember the ludo board; the snake knows its flat cousins;
   boardybard feels the other tables waiting. Awareness is the whole
   flavor — a character that only knows its own game is just a mascot.
4. **THE VOICE LAW.** First person. Short sentences. The horror is
   calm, the coping is funny, nothing is explained to the player. No
   "!?" energy except where the owner wrote one himself. Names: BALLDOZER
   (one word, the name law), GEOQUARE, BOARDYBARD, FROGGY-INSTANT,
   COSMIC SHADOW, THE DIE, THE PAWNS, THE PLATFORM, THE SNAKE.
5. **THE CANON LAW.** Never contradict an established line. Balldozer
   denies being brainwashed ("I call it TEAMWORK") while the pawns
   embrace being exactly that — both are true: the wiring is real, the
   coping is individual. The aliens are one faction across dash,
   invaders and froggy's vacuum. The shapes are coats.
6. **THE SILENCE LAW.** The cast never speaks outside its story beats
   and never interrupts play. The box's games stay games. The lore is
   the shadow under the floorboards, not a narrator.

The owner reads the box like a writer reads a set. Every new game
should answer one question quietly: **who is in this room, and what do
they think the room is?**
