# ROCK BREAKER — GDD (v040-7)

Graduated from the CRAZE CAVES-LIKE parking-lot note (registry id
`rockbreaker`, the owner's rename law: "the name feels like brick breaker
but actually the game mechanic is different"). The owner's own spec,
verbatim-shaped into laws. Vertical only. The honest teachers: Gamesnacks'
**Crazy Caves** (web build + APK, decompiled) and Voodoo's **Ball Blast**
(APK, decompiled) — same core mechanic, studied for the real numbers
(HP curves, upgrade pacing, spawn pressure); every asset and line we ship
is our own redrawn/re-written work (the usage law, docs/DECOMPILATION.md).

## THE GAME IN ONE BREATH

A vertical closed arena. Your two-wheeled cannon rolls along the ground.
Boulders of every size, color-heat and speed fly in from the sides and
bounce forever — billiard physics, spin and flips. Hold to shoot them
until they crack; every break splits a big rock into its children, pays
rockCoins by the damage the rock carried, and the count on screen only
grows. One touch of a rock and the run is over. Break rocks, buy
projectiles and damage, chase the golden rocks that carry GOGACoins,
survive the flood.

## THE OWNER'S LAWS (binding, from the v040-7 message)

- **THE RENAME LAW**: "rename it to rock breaker (the name feels like
  brick breaker but actually the game mechanic is different)". The game
  ships as ROCK BREAKER — no caves, no craze.
- **THE ROCKCOIN LAW**: "make the game currency called rockCoins and make
  a coin drop based on number of damage needed to break the rock, it
  will be /10 so a 120-damage rock will give 12 rockCoins". The drop is
  paid at break time, computed from the rock's full damage pool. No
  gem-coins in this game ("there will be no gem-coins here").
- **THE SCORE LAW**: "score be based on rockPoints, rockPoints is the
  number of break-ed rocks in the round regardless of its level, score
  bonus will be /250". Registry coin_div 250. One broken rock = 1
  rockPoint, whether it is a pebble or a mountain.
- **THE GOLDEN LAW**: "a GOGACoin will drop from a hidden-damage-length
  golden rock that appears after every 300 rock points, it takes from
  300-1000 damage to be hatched/broken and the game will show always
  another one after 300 RockPoints from the last collected gogacoin".
  The golden rock's damage is hidden (no number on its face). The 300
  counter restarts when the GOGACoin is collected, not when the golden
  rock spawns. Golden and mystery rocks NEVER leave the screen.
- **THE MYSTERY LAW**: "mystery rocks ... have the slow-down and shield
  and x2 throw speed but without the double throw from crazy caves and
  without the extra cash thing from it and will take also hidden
  damage-length that ranges from 250-500". Exactly three gifts — SLOW
  (the rocks crawl for a while), SHIELD (the cannon survives one touch),
  RUSH (x2 throw speed for a while). NO double-throw, NO cash bonus.
  Mystery rock damage is hidden too.
- **THE COLOR LAW**: "rocks will have levels which is the color, the
  intense-er the longer, rocks never have a maximum number of required
  damage". A rock's level is its color heat — the hotter the tint, the
  longer it takes to break. Levels are UNBOUNDED: there is no cap on the
  damage a rock may demand, and the spawn law keeps pushing the heat up
  so an endless run stays intense.
- **THE SIZE LAW**: "rocks will have sizes, five levels, 1 is one and 2
  has two inside and 3 has 3 and 4 has 4 and 5 has 5, the level will be
  visualized as different rock sizes". Size 1 is one rock (terminal —
  nothing inside). A size-N rock (N ≥ 2) carries N children. "a rock
  level 4 can have rocks inside it randomly from 1 to 3 but not 4 or
  bigger, one from 3 can be 2 or 1 but not 3-5 and like that over and
  over": every child of a size-N rock rolls its own size in 1..N-1.
  Big rocks split into swarms; only the little ones end a family tree.
- **THE ENDLESS LAW**: "in our game, we will not offer specific levels,
  we will offer endless play that lasts forever until the player get
  crushed". No level select, no waves screen, no win state. The run ends
  in one of two ways: a rock touches the cannon ("one rock hit and it's
  over") or the player quits.
- **THE PRESSURE LAW**: "sizes are random but the required damage is
  dynamic for long gameplay which means it has to be intense". The
  damage pool scales with the run (see THE HEAT CURVE below) — the game
  must never settle into a comfortable plateau.
- **THE SIDES LAW**: "rocks will come in different sides and different
  angles and different speeds too, maximum rocks can spawn from sides
  are 30, 15 from each side, maximum allowed rocks in screen are 50, if
  they are 45+ do not spawn extra ones until user get rid off some of
  the rocks and break the small ones, like that". The spawner feeds both
  walls (15 alive side-spawns per side max), the screen holds at most 50
  rocks, and at 45+ the spawner holds its breath until the player thins
  the herd. Children born from a break always spawn (they were already
  inside) — the caps govern NEW spawns.
- **THE UPGRADE LAW**: "there will be projectile ... more of them means
  more shot/s will happen — and second will be damage, more of it means
  the one shot will deal extra +1 damage point for each upgrade.
  Upgrades of projectiles will be capped at 50, damage will not, no
  third upgrade (in crazy caves it was cash)". Two shelves, forever:
  PROJECTILE (cap 50) and DAMAGE (no cap). "Also here make upgrades get
  much expensive fast so it feels like a very long-term goal for the
  player" — the price curve is steep on purpose (THE PRICE CURVE below).
  Upgrades are bought with rockCoins and persist across runs.
- **THE HOLD LAW**: "controls will be like snowy tower and space invaders
  where the left area for moving and right for shooting (holding only,
  tapping will not spam shots here)". The left half drags the cannon
  along the ground; the right half FIRES only while HELD — a tap taps
  nothing, no spam, the cannon speaks in sustained volleys.
- **THE GATE LAW**: "will start with tap anywhere to start ... no menus
  required for it, simple and direct". The silent gate (dot eater's
  shape). Shop and upgrades are merchandise buttons, not options.
- **THE BUTTON LAW**: "shop button at the top left and upgrades button
  next to it at the right". In the HUD top bar: SHOP, then UPGRADES
  beside it.
- **THE VERTICAL LAW**: "the game will be vertical only".
- **THE SHOP LAW**: "the shop will offer skins and themes, 5 and 5 where
  first is already default". Five cannon skins, five themes, the first
  of each free. Skins redraw the cannon; themes redraw the world.
- **THE RIDE LAW**: "the player will be canon with two wheels moving on
  whatever you will make". Two visible wheels, rolling with the cannon,
  riding the ground the theme draws.
- **THE FIVE PLACES LAW**: "you have to make 5 different views/places for
  each theme". Every theme owns FIVE distinct background places, and
  each theme covers "the places and rocks skins packs" — theme changes
  the world AND the rocks (cave rocks, wood, pixel, neon, candy).
- **THE THEME NAMES LAW**: "first theme to be called cave ... another one
  to be called forest and third to be pixel and fourth to be neon and
  fifth to be candy, feels logical for GOGABox".
- **THE NEON FILL LAW**: neon is "filled-from-inside neon, not the empty
  one style" — glowing filled bodies with soft inner light, never hollow
  outlines.
- **THE JUICE LAW**: "it should offer cool and fun bouncing physics and
  rock flips and VFXs and SFXs". Rocks spin and flip as they fly,
  cracks spread as damage lands, breaks burst into shards and dust,
  coins fly, the screen shakes where it is earned, and every event has
  its voice.

## THE WORLD (what the study says, turned ours)

- The arena is CLOSED. Rocks enter from the left wall, the right wall
  and the top at random angles and speeds, bounce elastically off every
  wall, spin while they fly (the flips), and never despawn — the only
  way a rock leaves the arena is by being broken. The pressure law lives
  here: the herd only grows unless you break it down.
- The cannon rides the bottom strip on its two wheels. Bullets fly
  straight up; a volley is a fan of parallel streams (the PROJECTILE
  stat). Damage lands on contact; a rock's remaining damage is printed
  on its face in the short number form (999 → 1.00K → 1.00M — "big
  numbers after 999 will show as 1.00K and 1.00M and like that").
- A rock dies the moment its damage pool empties: shards burst, dust
  puffs, the rockCoins fly to the wallet, and — if it had a family — the
  children pop out with fresh angles and speeds of their own.
- The places rotate: each theme's five views take turns while the run
  lives (a calm crossfade every few hundred rockPoints), so endless play
  keeps breathing new scenery.

## THE HEAT CURVE (the dynamic damage law)

The run carries one number, the HEAT. Every spawned rock reads its color
level from the heat plus a per-rock wobble, so the herd's demanded damage
climbs as the run ages — early rocks are warm grays and browns, deep-run
rocks glow like embers and demand numbers with suffixes. The heat rises
with rockPoints and time; the color ramp runs cool → intense so "the
intense-er the longer" reads at a glance. Children inherit their parent's
era (with a wobble), so a family stays readable while still climbing.

## THE PRICE CURVE (the long-term goal law)

- PROJECTILE: level 0..50, each level +1 stream. Price starts small and
  multiplies steeply per level — the first handful of levels come fast,
  the tail is a war chest.
- DAMAGE: level 0..∞, each level +1 damage per shot. Same steep curve,
  no ceiling.
- rockCoins bank across runs (the box save carries the wallet), so the
  long-term goal survives the death. The GOGACoin top-up system (see
  ideas/TOPUP_SYSTEM.md) can feed the wallet from other games later.

## THE ECONOMY

price 500 (the shelf's own), fee 8, coin_div 250 (score bonus /250),
shop true, banner true, vertical, free play (no charges/daily caps — the
endless ladder is the game). rockCoins are the in-game currency; GOGACoins
come only from golden rocks and the score bonus. Achievements: the tiered
ladder (rockPoints per run, total rocks broken, heat survived, coins,
plays). Guide: the registry "controls" array carries the hold law.

## THE ACHIEVEMENTS (the tiered ladder)

- tier 1: first 100 rockPoints in a run / 250 rocks broken total / play 5
  rounds.
- tier 2: 500 rockPoints in a run / 2,500 rocks broken total / break a
  golden rock / play 20 rounds.
- tier 3: 2,000 rockPoints in a run / 10,000 rocks broken total / carry
  the shield into a break and live / collect 10 GOGACoins.
- tier 4: 5,000 rockPoints in a run / 50,000 rocks broken total / reach
  the deepest heat.

## THE SHOP (skins and themes)

- CANNON SKINS (5, first free): CLASSIC (the steel original), then the
  owner's palette picks — each a body+accent pair for the cannon body,
  the barrel and the wheels.
- THEMES (5, first free; each theme = its five places + its rock pack +
  its world palette):
  1. **CAVE** (default, price 0) — the cave place, cave rocks: stone
     bodies, mineral veins, dust.
  2. **FOREST** — the woodland place, wood rocks: logs, knots and bark.
  3. **PIXEL** — the pixel place, pixelated rocks: blocky stepped
     silhouettes.
  4. **NEON** — the neon place, filled-from-inside neon rocks: solid
     glowing cores, soft inner light (never hollow).
  5. **CANDY** — the candy place, candy rocks: glossy sweets, sugar
     sheen.

## THE WIDGETS (simple and direct)

- Top bar: back · SHOP · UPGRADES · (spacer) · score chip · GOGACoin chip
  (the base chrome, the box law).
- In-world: the rockCoins wallet chip (icon widget, the pop siege chip
  law), the live powerup chips (SLOW / SHIELD / RUSH with their time),
  and the tap-anywhere gate with the best line.
- Death menu: the host chrome (score, bonus, coins) — nothing custom.

## THE SFX/VFX (the juice law)

Synthesized in-house (the box law): the volley tick, the crack per hit,
the break burst (pitched by rock size), the golden hatch, the mystery
gift, the shield save, the death crunch, the coin chime. VFX: shards and
dust on break, crack webs as damage lands, spin trails on fast rocks,
coin-fly arcs, the heat shimmer on hot rocks, the touch flash on death,
the ground dust when the cannon moves fast.
