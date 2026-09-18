# MARBLE POPPER — GDD (v040-13)

> The `zuma` coming-soon teaser seat graduates as **MARBLE POPPER** (the owner's
> rename law: "rename it to just marble popper"). id = `marble`. Portrait. 2D.
> Reference studies (scraped, the owner's order): `study_locker/gamesnacks/totemia/`
> (Totemia: Cursed Marbles - 90 levels extracted) and
> `study_locker/gamesnacks/zumble_ocean/` (Zumble Ocean - 60 levels extracted).
> Their assets are code-modified and used as ours (the owner's scrape law).

## 1. One line

A vertical marble shooter: marbles roll along carved paths toward a hungry idol
mouth; you fire marbles from a totem launcher to make 3+ matches, pop them, and
clear 100 hand-built levels across 10 places.

## 2. The owner's laws (verbatim requirements, each one is a ship gate)

- **Vertical** design first ("same as the gamesnacks games").
- **Places are NOT buyable.** Skins are: 5 player skins + 5 marble skins + 5
  hole skins, proper GOGACoins pricing.
- **Powerups are bought from the shop so they can spawn** in runs.
- **100 levels, 10 per place** (10 places). Places double as difficulty tiers:
  the more you progress the more complexity, hardness, length and speed.
- **LEVELS button after SHOP** - a vertical menu: first the places (5 + 5),
  then the levels inside a place (5 + 5), with **map previews like Pop Siege**.
- Selecting a level: **NORMAL** or **CHALLENGE** (same level repeats as 10
  waves - longer, faster, more complex - until you lose).
- **Score**: each completed level = +1 point. Score bonus = score / 5
  (coin_div 5). **No in-game currency** in this game.
- **GOGACoin collectable** rides the chain in place of a collectable marble:
  appears every 10 waves from the last collected one, lives 5 seconds, then
  flickers and fades. Missed coins re-appear in a later wave ("if one appeared
  at level 10 and not collected, it will re-appear in another level like 11").
- **Level variety** (the heart of the game):
  - shooter at right / center / left / upper-left / upper-center / upper-right /
    bottom;
  - some levels: **movable** shooter (Luxor-style slider along the bottom);
  - some levels: **two marble paths**;
  - some levels: **two legal shooter spots** - tap the other spot and the
    launcher fades out there, fades in at the new one.
- **Places are "just a feel" - the design must make the game amazing.**
- **Before every level**: a **path preview** shows the marble route accurately
  (arrows run the path), THEN the marbles are sent.
- **5 hole skins** (the mouth at the end of the path).
- **Locked levels menu** unless the game is 100% complete: levels unlock
  sequentially; endless/challenge jumps reveal only when completed.
- **Lives system + widget**: 3 lives. Losing one ends the round but the game
  stays saved. All 3 lost -> the game restarts from the first level. Extra
  life owned after each 10 levels. **After 100% completion the lives system is
  removed** (free jump anywhere).
- **Level cleared menu**: a small "tap it" menu - go to the next level / next
  place.
- **Challenge = 10 waves** (not endless) so every wave can be tuned.
- **Colors grow with places** (more colors = harder matches).
- **Marbles slow down a little before the hole** (like the originals).
- **Level length hidden** - once reached, no extra marbles spawn.
- **Connection logic**: 2 marbles matching connect if the marbles in-between
  got matched and removed; non-matched inserted balls wait for the row to move
  and hit them to move together (the classic gap law).
- **Powerups** (glowing marbles sitting in the chain; tap them with a shot to
  collect; name text with black outline on pickup; **a collected powerup's
  effect marbles vanish if not matched for 10s**):
  1. **BACK** - the chain pushes backward (buys space).
  2. **BOMB** - blasts a radius of marbles.
  3. **HIGH SPEED** - shots fly much faster for a while.
  4. **VAPOR** - matches burst wider (vapor eats one extra neighbor each side).
  5. **RAINBOW** - the next shot matches any color.
  6. **LIGHTNING** - zaps every marble of the color you hit.
- Spawn rate: **1-2 powerups per 60 seconds** of a level (tweak for feel).
- **No eye-candy widgets for powerup time** - the owner does not want a timer
  widget revealing powerup duration.
- Thumbnail, guide, achievements, requirements/orders, entry, rate-limits:
  delegated to the implementer (as usual).
- Core mechanics, SFX, VFX, music: "all are obvious" - the scraped games are
  the audio/feel reference; assets are cut + code-modified into `mb_*` files.
- "The game is on algorithms, geometrics, level-designing" - the chain math
  and the level data must be first-class, not vibes.
- **Real emulated testing is mandatory** - record gameplay, catch scaling /
  logic / visual bugs, fix before pushing (the owner does not want a 40-bug
  report).

## 3. Core loop (seconds-level)

1. LEVELS menu -> place -> level -> NORMAL/CHALLENGE.
2. Path preview (arrows run the carved route, ~1.2s).
3. Marbles roll in from the path start in waves (a wave = one spawn group).
4. Tap anywhere to shoot the loaded marble toward the tap; tap the launcher to
   swap its loaded marble with the next one.
5. Matches of 3+ pop; gaps collapse; new joins may cascade; combos rise.
6. Marbles reaching the idol mouth = a life lost (round ends, progress kept).
7. All marbles gone and quota spent = level cleared -> cleared menu.
8. Score: +1 per level; GOGACoin pickups add wallet coins; bonus score/5 paid
   on cleared levels.

## 4. Chain math (the algorithms section)

- Path = control points -> Catmull-Rom spline (tension from the level data)
  sampled every RES px (arc-length resampled, uniform spacing).
- Chain = ordered list of marbles with a continuous `dist` along the path.
  Front marble has the max dist. `dist += speed * dt` while rolling.
- Insert: a shot marble lands on the chain -> find the two neighbors it lands
  between (nearest point projection), insert at that dist, split rolling
  groups: the front group keeps rolling, the back group pauses until contact.
- Match: same-color run >= 3 around the inserted marble pops (score by run
  length + combo multiplier), leaves a gap.
- Gap collapse: back group accelerates forward until it touches the front
  group; on contact, if the joined ends match >= 3 -> pop (cascade chain).
- Inserted-but-unmatched marbles stay at their dist; the front group rolling
  back into them "collects" them (the wait law).
- Backward push (BACK powerup) decreases dist of the whole chain.
- The mouth eats when the front marble reaches the path end (danger pulse in
  the last 12% and the slow law at 0.55x in the last 15%).
- Spawn: a wave spawns at the path start as long as `spawned < quota` (quota =
  hidden level length). Wave gap based on level pace.

## 5. Level data schema (ours, informed by the studies)

```json
{"id": "m01", "place": 0, "name": "First Steps",
 "paths": [[[x,y],...]],            // 1 or 2 polylines (control points, 720x1280 design space)
 "shooter": {"x": 360, "y": 980, "mode": "fixed"|"slider"|"twin"},
 "twin": [[x,y],[x,y]],             // for mode "twin"
 "speed": 80,                        // px/s base
 "quota": 55,                        // total marbles (hidden)
 "wave": 10,                         // marbles per wave
 "colors": 3,                        // colors this place reveals
 "gravity_holes": false}             // future
```

Places define palette (bg / track / decor / idol tint), colors count, speed
and quota growth. 10 places x 10 levels = 100. Generated by a forge tool
(`tools/v0413_marble_levels.py`) with hand-tuned per-place rules + variety
machine (shooter modes distribution, twin paths at place >= 4, twin shooters
at place >= 3).

## 6. Economy

- price (unlock): 350 GOGACoins; fee 5; coin_div 5 (the score bonus /5 law).
- Skins (Box shop_items categories, owned forever, equip on tap):
  - player: classic 0 / jade 140 / obsidian 180 / royal 240 / gold 320
  - marble: classic 0 / frost 140 / magma 180 / venom 240 / prism 320
  - hole: classic 0 / coral 140 / gold 180 / shadow 240 / soul 320
- Powers (cat "power", geometry model A - owned => they can spawn):
  back 200 / bomb 260 / speed 260 / vapor 300 / rainbow 340 / lightning 380.

## 7. Achievements (tier law)

- First Blood - clear your first level (cnt levels_cleared 1, tier 1)
- Century Club - clear 100 levels total (cnt, tier 4)
- Combo Artist - reach a x5 combo (max combo_best 5, tier 2)
- Coin Snatcher - collect 10 chain GOGACoins (cnt coin_taken 10, tier 2)
- Wave Rider - clear a challenge with all 10 waves (stat challenges_won, tier 3)

## 8. Audio (mb_* prefix)

Shots, inserts, pops (color-pitched), gap collapse, combos 1..10 (pitched
ladder), bomb, lightning, laser, coin, powerup appear/pickup, danger
heartbeat, win/lose, click - cut from the studies + code-modified. Music: 3
looping themes rotating across places + the menu bed.

## 9. Visual

- Code-generated place backgrounds (10) - layered, themed, rich (the Rock
  Breaker rich-world law applies).
- Marble = cut + code-modified glossy marble per color with carved patterns;
  5 marble skins restyle the base (frost/magma/venom/prism regrade).
- Launcher = totem-style head that aims (rotates toward the tap); 5 skins.
- Hole = living idol mouth (opens/closes); 5 skins.
- Track = carved groove drawn under the marbles with per-place palette +
  edge highlights; path preview arrows run it before the level.
- Powerup marble = glowing halo + icon glyph; name text with black outline on
  pickup; 10s unmatched vanish law.
