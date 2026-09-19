# PENDING — the box's waiting list

> The owner's break note (2026-09-19, kept in spirit): "i am not going to
> abandon the project, i will just, likely take a small rest thinking about
> some stuff, i do not know if i will return shortly or what — the todo file
> will let both of us ready when the time of work returns."
>
> v040-15 is pushed but UNTESTED. Nothing below is started until the owner
> says go. When an item is done, its section moves to `../done/`.

---

## 1. TEST v040-15 — which bundles the full v040-14 round (nothing tested yet)

The owner has NOT tested v040-15, which means v040-14 is still pending too.
v040-15 ships BOTH rounds in one build on purpose (the owner's bundling
order), so one test pass covers two versions. Shipped at commit `a1e57ea`
(config 0.4.0-15 / code base 31250, both spots), v040-14 at `9b08480`
(config 0.4.0-14 / code base 31240).

**v040-15 — GOLD MINER** (new game; GDD: `docs/goga_docs/gogames_ideas/gold_miner.md`):
tap anywhere to start; endless grounds; the claw swings as a pendulum and
the tap releases it (pure timing); golds pay 1/2/3 and rocks 2/4/6 by size;
rocks are heavy and crawl home (the weight law); bombs are the LIVES —
3 touches = game over and every touch blasts the surroundings; a ground
clears when ALL gold is taken, then the next grows in; a GOGACoin glowing
gold joins the field every 50 banked things — including the edge case where
the 50th bank ends the ground (the glow rides the NEXT ground); reeled
things leave darker dust trails; DIFFERENT SFX per thing (gold S/M/L, rock
S/M/L, bomb, coin); shop = 5 rig skins + 5 vein skins, bombs are ONE
(not skinnable); score bonus /30; hearts x3 + score + GOGACoins widgets;
END button in the back menu (the XO law); the rig sits at a random X each
run and never moves mid-run; six generator profiles (incl. FORTRESS, the
big-gold-ringed-by-small-rocks shape) with the fairness validator.

**v040-14 — the polish round** (all inside the same build):
- *Marble Popper*: the intro helper line removed; the shop button-hold
  hang root-killed (tappables registered after the content builds); the
  COLLAPSE law — the first marble over the lip sends the whole chain into
  the hole, then the UNIVERSAL box death menu (no private card, no LEVELS
  button, the widget says LEVEL); the FULL RUN law — match walking pops the
  whole running chain, not 3; the PUSH law — inserts push the rear back one
  spacing, the top-left ghost marble is dead; hole entries grow in / roll
  in from off-screen; the loaded marble sits IN the totem's mouth + the
  next one at the back collar; the idol's jaw fits its head and the idol
  ROTATES to face the incoming chain; the ghost-chain PATH PREVIEW loops
  the route until the tap; the levels menu shows all 100 cards LOCKED until
  100% (jump + challenge + free play open together); level 1 redesigned
  (3-lane ~2900px serpent, the levels forge revalidated every path);
  modular DEV CHEATS — the EXTRAS list behind the ALL EXTRAS parent toggle
  (first extra: MARBLE — UNLOCK ALL LEVELS).
- *Rock Breaker*: the CHAOS BOUNCE law — every ground bounce re-rolls the
  rebound (0.62–1.22, one in five a POWER bounce up to 1.58) plus a
  sideways re-roll, Crazy-Caves style, nothing parks or gets stuck.
- *Deadly Worm*: the STAY-OPEN law — pow buys, place buys, place visits,
  worm unlocks and switches refresh the sheet IN PLACE, the shop never
  quits itself.

Done when: the owner's test report comes back and any fix round ships.
(Report format as always: the bad things first, then the rest.)

---

## 2. LAN MULTIPLAYER — documented in another file

The LAN multiplayer system is specced in its OWN home:
**`docs/goga_docs/ideas/LAN_MULTIPLAYER.md`** (the owner's spec, shaped in
the v040-7 round). DOCUMENT ONLY — nothing scheduled, nothing built. The
short of it: players on their own phones, one wifi, no accounts, no
servers; the main menu grows a drawn multiplayer seat (plus + human symbol,
never an emoji), multiplayer-capable games wear a PLAYERS badge (1–4), and
a game opened by 2+ holding players becomes a real-everyone match. When
the owner green-lights it, it becomes a `plans/PLAN_vX.Y.Z.md` task list
and that file is the contract every game and the box both read.

Done when: the owner green-lights the build round — then this item moves
to `../done/` and a PLAN file opens.

---

## 3. SNAKE — third play mode "SURVIVAL" (the snake.io-like option)

The owner's idea, verbatim kept: "Add third play mode in snake called
'survival' where it will be open walls or closed normally (means it is a
submode and not main so it will be an option) and it will offer much bigger
land with camera following snake and will spawn many fruits in many places
and it will only be toggled if +4 opponent snakes are selected and can not
be toggled if there is less snakes and will not work with bugs or obstacles
and it will offer snake getting slower when it gets bigger instead of
getting much faster and will offer snakes growing very very very bigger
than usual and score here will be based on eaten snake parts (or full snake
giving all it's parts as score) and bonus be /100 for it. this mode will
make the game like the snake.io games but more fun."

Shaped into laws:
- **THE SUBMODE LAW**: Survival is a togglable OPTION inside the snake
  game — a third play mode behind the scenes, never a main mode.
- **THE WALLS LAW**: open walls OR the normal closed walls — both possible
  inside the mode.
- **THE LAND LAW**: much bigger land, and the camera follows the snake.
- **THE FEAST LAW**: many fruits spawned in many places.
- **THE GATE LAW**: the option only unlocks when MORE than 4 opponent
  snakes are selected (5+). With fewer snakes it cannot be toggled.
- **THE EXCLUSIVITY LAW**: does NOT work with bugs or obstacles — those
  combos are off.
- **THE SLOWDOWN LAW**: the snake gets SLOWER as it gets bigger (the
  inverse of the normal much-faster scaling).
- **THE GROWTH LAW**: snakes grow very, very, very bigger than usual.
- **THE PARTS LAW**: score is based on eaten snake parts — eating a full
  snake banks all of its parts as score.
- **THE BONUS LAW**: the score bonus for this mode is /100 (the same bonus
  mechanic gold miner runs at /30).
- **THE FEEL LAW**: the snake.io games — but more fun.

Done when: designed + built + probed + shipped in a version round.
