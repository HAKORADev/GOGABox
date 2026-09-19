# GOLD MINER — GDD (v040-15)

> The `goldminer` coming-soon teaser seat graduates as **GOLD MINER**. id =
> `goldminer`. Portrait (vertical for now — "it can be both, but for now
> vertical"). 2D. Reference study (scraped completely locally, the owner's
> order): Gamesnacks' **Gold Miner Tom** (Construct 2 build: c2runtime.js +
> data.js mirrored whole, 98 sprite sheets + 18 sound pairs) — mirrored in
> the local study locker, OUTSIDE the repo (the study law: study copies are
> never committed). Its assets are code-modified and used as ours (the
> scrape law), integrated with proper changes.

## 1. One line

An endless timing miner: the claw swings on its rope like a pendulum, you
release it at the right angle, and whatever it bites — gold or rock — is
reeled back to the top; clear every gold in a ground and the next one loads,
while the bombs wait to blow your haul and your lives apart.

## 2. The owner's laws (verbatim requirements, each one is a ship gate)

- **The name is GOLD MINER.** Scraped from
  `https://gamesnacks.com/games/goldminertom` completely locally, assets
  code-modified ("take the assets accurately and integrate them with
  proper-changes").
- **Vertical for now** (can be both later). Starts with a **"TAP ANYWHERE TO
  START"** screen.
- **Endless**, similar to how Fruit Slasher is endless.
- **Algorithms populate the ground** with gold and rocks — S/M/L sizes,
  different points: **small gold = 1, up to 3 for large gold; rock = 2, up
  to 6 for large rock** (gold 1/2/3, rock 2/4/6). Random for each game, with
  **different algorithm profiles** — "like big gold be surrounded by many
  small rocks and things like that".
- **A stage/ground is cleared by taking ALL the gold in it**, then another
  one loads.
- **Bombs are the lives: when 3 are touched, the game is done.** When
  touched, the bomb **blasts the surrounded things whether gold or rocks**.
- **The END button in the back menu** like XO and the other games ("because
  one game could take too long here, not really but it could").
- **Score bonus = /30** (coin_div 30).
- **No coins economy inside the run, no upgrades, no places, no powerups.**
- **The shop wears 5 + 5 skins**: one set of 5 for the player vehicle/thing
  (the overall player), one set of 5 for the **rocks/golds**; bombs are one
  (single, not skinnable) — "this will let you focus more on the game
  design core".
- **The character position differs from game to game**; the algorithm
  calculates everything so it stays fair and challenging.
- **The character cannot change position during play.** The main challenge
  is **TIMING**: the mechanic is easy — release the swinging claw, whatever
  it hits is collected and returns to the top; the thrown thing keeps
  angle-ing (the swing never stops between throws).
- **Two widgets**: one for **hearts** and one for **score**, plus the
  obvious **GOGACoins** one.
- **GOGACoins appear after every 50 collected things** (rocks + golds
  combined), appearing **like a glowing gold** — when it is time, put it in
  a gold's place in the level, **or in the next level if the level somehow
  ended with the 50th thing** (the edge case is covered).
- **Drag leftovers**: a rock/gold/bomb leaves **leftovers behind it when
  dragged** — "like making the dust under it darker".
- **Different SFXs for the things.**
- **Thumbnail, entry, rate-limiting, guide, achievements, requirements**:
  left to the agent.
- Could add upgrades (double-shot etc.) later — for now **focus on making
  it really fun to play**.
- v040-15 **bundles the previous version's updates**: the whole v040-14
  fix list rides in the same release (the owner tests both at once).
- After the game: mark the **last 5 GOGABox games done** in games_done.md,
  take the **next 5 names from FUTURE_GAMES.md** into the app as the SOON
  titles; the owner's two new dump ideas (brawl-stars-like, full orbit)
  park in FUTURE_GAMES.md.

## 3. The design (the owner's spec worked into systems)

### 3.1 The stage (portrait 1080x1920 design space)

- **Surface band** (top ~330px): sky, the dark cave skyline (gametopbg),
  the grass/dirt surface line (groundtile) — the miner rig stands ON it.
- **The rig**: the wooden pulley tower (elevator asset) with the winch reel
  and the miner (head/body/arm from the miner_miner_* family) beside it.
  The rig sits at a **random X anchor each run** (the "character position
  differs game to game" law) — clamped so the whole field stays reachable:
  anchor X in [270..810], the pulley Y at the tower top.
- **The field** (underground, ~Y 430..1830): the layered dirt bands
  (bgtile1/2/3 + bgtile4 clumps) over the striped bedrock (bottomtile),
  above the reserved banner strip (banner_safe_px).
- **The rope** runs from the winch, over the pulley, down to the claw. The
  claw **swings as a pendulum** around the pulley anchor: angle = ±72°
  sinusoid, period ~2.1s (feels quick but readable).

### 3.2 The throw (the timing loop)

1. The claw swings continuously (the swing never stops between throws).
2. **TAP = release**: the claw flies STRAIGHT along the current angle, rope
   paying out at ~950px/s, up to the max rope length (~1500px).
3. **Hit an item** → the claw closes (0.12s), grabs it, and reels back —
   the reel speed is the item's **weight**: empty ~900px/s, S gold ~820,
   M gold ~640, L gold ~480, S rock ~520, M rock ~380, L rock ~300
   (heavy value crawls home — the risk/reward heart).
4. **Hit nothing** (max length) → retracts empty at full speed.
5. Back at the pulley → the item is banked (score + counters + sfx), the
   claw reopens, the swing resumes from the angle it stopped at.

### 3.3 The cast and the points (the owner's law verbatim)

| thing | sprite (scraped) | points | weight feel |
|---|---|---|---|
| gold S | g1 (36x32) | **1** | light |
| gold M | g2 (66x57) | **2** | medium |
| gold L | g3 (141x120) | **3** | heavy |
| rock S | r1/r2 (70px) | **2** | medium |
| rock M | rock (128x128) | **4** | heavy |
| rock L | rock scaled 1.35x | **6** | very heavy |
| bomb | bombsprite (170x170) | lives −1 + blast | n/a |
| GOGACoin | g2 gold + glow (shinetitle sparkle) | run coin +1 | light |

- Rocks pay MORE than gold but crawl home — the owner's "rock takes 2, up
  to 6" law turned into the game's core risk/reward.
- The **mole/diamole/bag/diamond/skull/bone/TNT** family stays OUT of the
  gameplay cast (no powerups, no extras — the owner's focus law); their art
  is left in the study locker.

### 3.4 Bombs (the lives law)

- Touch a bomb = **1 of 3 lives lost**, the bomb **explodes** (the scraped
  expoanimation frames + shake): every gold/rock in the blast radius
  (~260px) is destroyed with it (a gold caught in the blast is LOST, not
  banked — but its absence still counts toward clearing the ground).
- The GOGACoin is magic: blasts never eat it.
- 3rd bomb = the run ends (`finish_run` → the universal box death menu).
- The hearts widget reads x3 → x2 → x1 → gone.

### 3.5 The ground generator (the algorithmic heart)

Per level, seeded fresh (RandomNumberGenerator, randomized per run):

- **Budget scales with the level index**: golds 4..10, rocks 2..8, bombs 0
  (level 1) then 1..3; L-gold guaranteed from level 2; L-rock from level 3.
- **All items random each game**; the rig anchor is drawn once per RUN.
- **Profiles** (weighted, rotate with depth — "different algorithms
  profiles like big gold be surrounded by many small rocks"):
  1. `classic` — uniform scatter;
  2. `fortress` — the owner's example: a big gold ringed by small rocks;
  3. `deep_vein` — heavy golds near the bottom, smalls on top;
  4. `minefield` — bombs parked beside gold clusters;
  5. `twin_pockets` — two clusters at the left/right extremes;
  6. `cross_haul` — big rocks ringing medium golds (the reel-risk test).
- **Fairness validator at generation time** (nothing ships blind — the
  marble levels-forge law): every item inside the field margins; no
  overlaps (radii + 26px); every gold within rope reach
  (dist + item radius < rope max − 40); bombs never adjacent to each
  other; the generator retries N times then falls back to `classic`.

### 3.6 The loop

- **Level cleared** when every gold is banked or blasted away (rocks are
  optional; untouched rocks fade with the ground) → the `success` jingle →
  the ground slides out and the next one pops in (items grow in).
- **Endless** — no win state; the run ends only on the 3rd bomb or END.
- **GOGACoin law**: a hidden counter counts every banked thing (gold +
  rock). Every 50th spawn: a **glowing gold** (g2 with the sparkle overlay
  pulsing) replaces a normal spawn in the current level; **if the 50th
  thing banked the level simultaneously**, the glowing gold is flagged
  `pending` and spawns in the NEXT level's first populate — the owner's
  edge case, covered by construction. Grabbing it = +1 GOGACoin
  (`add_run_coins`).

### 3.7 The shop (5 + 5, the shelf laws)

- **MINER SKINS** (5): classic Tom + 4 code-modified recolors/rehats of the
  miner family (the winch tower recolors with the miner).
- **VEIN SKINS** (5): re-inked gold+rock palettes (classic gold/gray +
  4 alternates: emerald, amethyst, candy, obsidian). **Bombs are one** —
  never skinned.
- Buy/equip rides `Box.buy_item` / `Box.equip_item` per category
  (`skin_miner`, `skin_vein`); the shelf wears the ON ROW law, the
  NO-DASH law, the ONE-COLOR law; buys refresh the sheet IN PLACE (the
  stay-open law); the shop SELLS, the game APPLIES at the next draw.

### 3.8 Widgets, chrome, economy

- **Hearts chip** (heart icon + x3), **score chip**, **GOGACoins chip** —
  the three widgets in the top bar.
- `pause_end_run = true` — the pause sheet wears **RESUME / END / QUIT**
  (the XO/pong law; END banks the run's score → bonus /30).
- fee 8, price 450, coin_div 30, banner on, portrait, `shop: true`.
- Achievements (the tiered ladder, rule-table driven): first gold, gold
  counts, rock counts, score tiers, coins taken, plays.
- Guide (desc + controls) carries ALL the words (the guide law); the
  intro screen carries only "TAP ANYWHERE TO START".

## 4. Study notes (the scrape, for the next agent)

- Build: Construct 2. `c2runtime.js` + `data.js` (JSON, project tuple).
  Object types p[3][0..97] map 1:1 to `images/*-sheet0.png` strips.
- The item family: g1..g4 = gold nuggets S..XL, r1/r2/rock = boulders,
  bombsprite = the bomb (sheet1 = white hit-flash), tnt = barrel, mole +
  diamole = 2-frame walk cycles (plain / diamond carrier), bag = mystery,
  diamond/skull/bone = bonus/junk.
- **hook-sheet0/1 (256x256, 128px cells) = the CLAW+ITEM atlas** — the
  reeling compositions for every grabbable (gold S/M/L, rock, bag,
  diamond, skull, bone, mole). The bare claw lives inside those cells;
  the swing claw is cut/rebuilt from the cleanest cell.
- miner_miner_* = the rig parts (h1 head + sheet1 blink variant, bodym,
  arm, armup, hand, handle, roll = the wooden winch reel, shadow);
  `miner-sheet0.png` is an EMPTY dead asset (bbox None) — ignored.
- elevator = the pulley tower; ropepin/ropetile/elevatorrope = rope bits;
  bgtile1-4/bottomtile/groundtile/gametopbg = the ground stack; menudoor =
  the mine entrance; menuchar = the menu gold-cart art; title-sheet0 =
  the "GOLD MINER" logo; popup = the wooden dialog board; shopitems/
  shopbottles/shopitembg = shop art; expoanimation-sheet0 = 4 explosion
  frames (256px cells); dustparticle = the soft puff (the trail law).
- Audio (18 pairs m4a+ogg): music loop, start, counter, pop, point, good,
  great, low, machine (the winch), rattle, puff, bag, explode, fail,
  getbomb, getpower, purchase, success.
