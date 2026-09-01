# Space Dash — the game journal

One file per game, named after the game, journal style (timestamp heading
per entry, newest at the bottom, never in-place edits) — the house rule.

---

## 2026-09-02 — the game is born (v0.2.4, the big redesign)

The owner's verdict on Space Dodge: "the current game called geometry flash
is not like my geometry flash game" (v0.2.3 patch renamed it to Space Dodge
as a stopgap) — and then the real verdict: rename it AGAIN to **Space Dash**,
because that name fits the owner's plans, and give it a REAL redesign. Not a
lane-dodger with obstacles anymore — a full enemies-and-weapons shooter.
Space Dash ships in v0.2.4. The registry id stays `lanes` (ids never move).

### What the owner specified (the contract, near-verbatim)

- **Renamed again**: Space Dodge -> **Space Dash** ("renaming it again to
  space dash will be better for my plans").
- **NO obstacles** like the current falling blocks. The sky is FULL of
  enemy ships — "tons of enemies", "make them a lot of enemy ships".
- **NOT Space Invaders** — review the assets so the game doesn't read as a
  fixed-formation invaders clone. Enemies flow in, they don't sit in rows.
- **Real art only**: "do not make code-generated ships" — download lots of
  space ships + effects, pick the best. (Effects VFX are code — that part
  is explicitly fine.)
- **Score is KILLS.** Different ships pay different score. Every kill pops
  a "+nn" at the death spot.
- **End-of-run coin conversion: score / 20** (the registry's coin_div).
- **5 lanes**, drawn as faint alpha guides so the space background still
  shows through. (The owner weighed invisible lanes vs visible and chose
  visible-but-alpha: "i still think the lanes design is good".)
- **Controls**: tap the left/right EDGE of the screen -> the ship moves ONE
  lane toward that side, smoothly, blocked at the walls. Press the MIDDLE
  of the screen -> shoot. Rapid taps shoot AND holding shoots. Some
  weapons do something different on hold than on rapid taps.
- **Anti-spam rate limit**: max one shot per ~30ms — but STUDY it, don't
  hardcode: the floor must be "past any human spam, still responsive for a
  human". Our law: floor = max(30ms, one rendered frame at the live FPS),
  so a slow device can never fire more shots than it can draw, and a 1000Hz
  macro can never fire faster than 33/s. Human range (8-12 taps/s) sails
  through untouched.
- **Loot lives on kills**: nothing free-floats from a spawner anymore.
  - GOGACoins: exactly 1 coin drops per 5-10 kills (random), the counter
    resets at every coin collected — "1 coin between 5-10 enemies, counts
    from last coin collected".
  - Power points, weapon items, shield items — all drop from wrecks, spawn
    rates tuned per item.
- **Hearts**: start with 3 shown in the UI; +1 heart for every 1000 score
  (multiples of 1000 crossed); every wreck costs -500 score AND one heart;
  the death that takes the last heart ends the game.
- **Weapon power**: the UI shows a weapon-power gauge. Power points are one
  loot item and they upgrade the CURRENT weapon on the ladder
  0 -> 1 -> 3 -> 6 -> 10 -> 15 -> 20 (max). Each weapon keeps its OWN
  power count — swapping weapons keeps the ladder per weapon ("more
  tactical"). Dying costs 3 upgrades worth of points.
- **The weapons (4)**:
  1. **Yellow beams** (base, everyone has it): fast, weak; upgrades add
     beams per shot. Rapid taps and holds both fire.
  2. **Red laser** (shop): continuous piercing beam, passes THROUGH
     enemies, up to 2s of continuity, then 0.5s cooldown. Upgrades make it
     stronger.
  3. **Thunder** (shop): white strikes, chain-lightning — a strike jumps to
     nearby ships, one to the next ("shazam-like"). Up to 5s continuous,
     2s cooldown. Upgrades damage MORE enemies per strike.
  4. **Bomb launcher** (shop): throws a bomb, high damage in a radius,
     single shots, 2s cooldown; upgrades hit harder and a little wider.
  - Collecting a weapon item swaps your current weapon.
- **Shield power**: covers one hit, up to 3 levels. It reads as an aura
  whose alpha gets deeper/stronger with level.
- **Shield shatters on enemies**: some ships carry orbiting shield shards
  — invulnerable — with a kept-open gap; up to 3 shards, different speeds
  and sizes, TUNED so a gap always faces the player's side. Shoot the gap.
- **Enemy variety**: different speeds, powers, defenses; some shoot, some
  don't; some split into two more enemies when they die.
- **Rare intense ships**: one with a shotgun spread, one with a DOUBLE
  shotgun, and "too powerful" elites. Rare — but they exist.
- **Dynamic difficulty from KILLS, not score, not player power**: kills
  drive the spawn budget, speeds, shooter ratio and elite chances — the
  owner's reason: kills can't be farmed by hoarding power, so endless
  stays HARD and competitive.
- **Shop (no options menu — everything lives in the shop)**:
  - ship skins (real Kenney hulls),
  - the red laser, the thunder, the bomb launcher (bought = the weapon
    EXISTS in the run's loot pool; not equipped as a base weapon),
  - the shield powerup (bought = shield items join the loot pool),
  - spaces/backgrounds: blue (default), green, yellow.
- **Round fee: 20 GOGACoins.**
- **Start**: "tap anywhere to start" card. No optionals screen.
- **Presentation**: "realistic atmosphere with realistic lighting and
  shading" — additive light pass, bloom-ish glows, parallax starfield,
  moving nebula background, engine flames, smoke, sparks, screen shake,
  +nn popups. Background spaces: blue / green / yellow.

### Assets (CC0, vendored — see assets.manifest.json)

- **Kenney Space Shooter Redux** (OpenGameArt mirror, CC0): enemy hulls
  (5 shapes x 4 colors), 12 player ships, laser bolts, the shield bubble
  animation (shield1-3), the fire animation (fire00-19 -> 10 frames), the
  speed line, power-up icons.
- **Kenney Space Shooter Extension** (OpenGameArt, CC0): 4 more distinct
  player hulls (the 7-skin wardrobe), missiles (the bomb shell + its loot
  icon).
- **Kenney Particle Pack** (kenney.nl, CC0): flare / spark / smoke / star
  glow textures — the tintable workhorses behind every code VFX.
- Deterministic recolors (CC0 inherits): `laser_yellow.png` = hue-rotated
  green bolt, `laser_thunder.png` = desaturated-white blue bolt.
- Enemies are drawn nose-DOWN in these packs — they descend as-is; player
  ships are nose-up. No rotation lies anywhere.

### The design decisions (why it plays the way it plays)

1. **Kills as the difficulty clock.** Score can be pumped (hearts feed
   score, elites pay big) and power decays on death — neither is a stable
   difficulty signal. Kills are monotonic and honest: the spawn director
   reads TOTAL kills this run, in tiers, and every tier raises spawn
   pressure, top speed, shooter ratio and elite odds. The run gets harder
   because YOU got good, and the dead menu tells you the kill count that
   killed you.
2. **The 30ms law is a floor, not a number.** `shot floor = max(0.030,
   1.0 / Engine.frames_per_second)` - measured, documented, probe-tested:
   2 shots in one frame are impossible, a 120Hz macro is capped at 33/s,
   a human's 10 taps/s never drop a shot. Hold-fire uses each weapon's own
   cadence ON TOP of this floor (beam 0.16s, laser continuous while it
   lives, thunder strikes 0.22s apart, bombs 2.0s).
3. **Shatter orbits are fair by construction.** N shards (1-3) divide the
   circle, and the orbit's PHASE locks one gap toward the bottom of the
   screen (the player's side) at spawn; the gap drifts as the shards spin,
   so timing shots through the gap is the skill. The probe asserts the gap
   faces the player at spawn and that shard arcs never seal it.
4. **The laser pierces, the thunder chains, the bomb splash — one weapon
   per crowd problem.** Beams thin out early waves; laser lines up columns
   (it goes THROUGH everything on its lane); thunder jumps across lanes
   (damage travels to nearest-neighbor ships, upgrade = longer chain);
   bombs erase clusters around the impact. Upgrades deepen the weapon's
   own idea instead of making it a generic bigger bullet.
5. **Per-weapon power ladders.** Power points feed the weapon you are
   HOLDING, and each weapon's ladder is separate (0/1/3/6/10/15/20).
   Swapping is a build decision, not a sidegrade. Death drops you exactly
   3 rungs on the CURRENT weapon's ladder (owner: "dying takes 3 upgrades
   worth of points").
6. **Coins are a rhythm, not a rain.** 1 coin per 5-10 kills from the last
   coin keeps a steady heartbeat (~every 8 kills on average) — enough to
   feel the economy, rare enough that the score/20 end bonus is still the
   real payout.
7. **No options menu.** The owner killed the optionals screen for this
   game: shop first, "tap anywhere to start" second, play. Fewer screens,
   faster loop.

### Open for later versions (owner: "there will likely be more stuff")

- Bosses, mini-boss formations, lane-blocking hulls.
- More spaces / skins / a prestige weapon slot.
- The owner will keep playing Space Dash and plan its updates from the
  feel of this first real build.
