# POP SIEGE — the bloon siege (GDD v0.3.5)

> The next-version game. The owner's own PGB `Pop_TD.py` (v1.3.8, linear) reborn as a real
> point-to-point landscape TD, taught by the Gamesnacks hit ENDLESS SIEGE (decompiled,
> studied, honored) and dressed with the GameMaker Tower Defense Template's props.
> 30 maps. 10 folk. 3 gears x 10 upgrades each. Synergies. PopCoins. The bloons are coming.

## 0. IDENTITY

- **Name:** POP SIEGE (was "Pop TD"). Pop = what you do to bloons. Siege = what they do to you.
- **Shape:** LANDSCAPE (registry `orientation: landscape`, the dario path). Grid + side panel.
- **Fantasy:** tiny cheerful defenders ("the folk") hold a winding road against waves of
  bloons that march from the spawn to the village heart. Every pop is a point, every
  point is pride, every 10 waves hides a GOGACoin inside a bloon.
- **Feel laws:** smooth (pooled bullets, zero per-frame alloc, capped particles),
  juicy (shockwave pops, screenshake, gear-up pillars), readable (the next-value >>).

## 1. THE BATTLEFIELD (the map grid)

- Grid: **18 x 10 cells**, cell = 62 logical px (1116 x 620 field) + the folk panel on the right.
- Cells are: **ground** (buildable), **road** (never buildable, bloons only), **blocked**
  (a prop lives there: tree, rock, palm, grave, crystal... never buildable), **water**
  (never buildable; shimmers), **decor** (non-blocking pretty scatter).
- Roads are **waypoint polylines** through cell centers; bloons steer along them with a
  lane offset (spread) so packs look organic, not conga lines.
- Placement feedback (the Endless Siege law): drag a folk card, the hovered cell paints
  GREEN when buildable, RED when not, with the drag tick sfx each change; drop on green
  = place with a land-ring + smoke puff.
- Range preview: soft circle while placing; tap a placed folk = its range ring + the
  upgrade menu in the panel.

## 2. THE 30 MAPS ("maps" = the optionals button)

30 handcrafted layouts across 12 themes, each with its own **day + night** mood BUNDLED
(buy the map = own both; the price reflects the pair). Themes set the ground grain tile,
path material, prop pool, ambience and music accent:

| # range | theme | props | road |
|---|---|---|---|
| 1-3 | meadow | trees, bushes, flowers, fences | dirt |
| 4-6 | forest | pines, stumps, mushrooms | pine-needle dirt |
| 7-9 | desert | cacti, skull rocks, dunes | sand |
| 10-12 | snow | bare trees, snowmen, ice rocks | trampled snow |
| 13-15 | beach | palms, crabs, shells, piers | boardwalk |
| 16-18 | swamp | dead trees, lilypads, frogs | muddy plank |
| 19-21 | volcano | lava rocks, vents, obsidian | obsidian cobble |
| 22-24 | candy | lollipuffs, gummy rocks, canes | frosting |
| 25-27 | graveyard | graves, tombstones, dead fences | old cobble |
| 28-30 | crystal cave | crystals, glow shrooms, stalagmites | rune stone |

Layout archetypes (waypoint sets): S-curve, double-S, U-turn, spiral in, spiral out,
zigzag, twin rivers (2 paths, separate spawns), the crossing X (paths intersect mid-map),
the merge (2 spawns join into one road), the perimeter loop, the staircase, the hourglass,
the heart. **Multi-path maps spawn alternating groups on each path.**

Difficulty stars 1-3: star 2 = wave budget x1.18, star 3 = x1.38 + tighter spacing.
Prices (GOGACoins, day+night included): first 3 FREE (First Bloom, Dune Run, Pine Twist),
the rest **250 - 900** by stars and layout craziness. Best wave per map is saved and
worn on the map cards.

### The 2x15 sheet (the owner's exact spec)

OPTIONALS menu (in-game) -> **MAPS** button -> a scrollable sheet with TWO vertical
columns of 15 map cards (2 x 15). Each card: generated thumb, name, stars, best wave,
and its day/night chips (D/N remembered per map). Tap owned = switch (confirm if mid-run).
Tap locked = the coin-price buy (the universal GOGACoins shop flow, price with the coin
icon, never spelled out - the patch-4 coin-icon law).

## 3. THE BLOONS (enemies = score)

Layer system (the PGB truth): popping a bloon releases its children, same cell, spread.
**Score = damage instances ("hits"): every hit dealt is +1 score.** Ceramic takes 10 hits,
MOAB takes 200 - "some enemies worth more than 20 damage points", delivered.

| bloon | hp | speed | children | trait | coins |
|---|---|---|---|---|---|
| red | 1 | 1.0 | - | - | 1 |
| blue | 1 | 1.3 | red | - | 1 |
| green | 1 | 1.6 | blue | - | 1 |
| yellow | 1 | 2.2 | green | - | 2 |
| pink | 1 | 2.8 | yellow | - | 2 |
| black | 1 | 2.0 | pink x2 | EXPLOSION-immune | 3 |
| white | 1 | 2.2 | pink x2 | ICE-immune | 3 |
| lead | 1 | 0.8 | black x2 | SHARP-immune (fire/energy pop it) | 3 |
| zebra | 1 | 2.0 | black+white | EXPLOSION+ICE-immune | 4 |
| rainbow | 1 | 2.0 | zebra x2 | - | 6 |
| ceramic | 10 | 2.0 | rainbow x2 | cracked shell visual by hp | 10 |
| M.O.A.B. | 200 | 0.6 | ceramic x4 | blimp; takes all damage | 40 |
| BRUTUS | 700 | 0.5 | moab x2 | blimp; SHARP takes half | 120 |

Traits are honest: the lead sheen, the zebra stripes, the ceramic cracks by hp, the MOAB
nose, BRUTUS' rivets. Damage classes: SHARP (darty, boomo, longeye base), EXPLOSION
(boomba, frag), FIRE (pyra - pops lead), ICE (kolda - pops nothing frozen-solid, slows),
ENERGY (zappy, longeye FMJ rounds - pops lead too).

## 4. THE FOLK (10 characters, 3 gears x 10 upgrades)

In-run economy: place for **PopCoins**, upgrade 10 levels per gear, **GEAR UP** at level
10 (expensive jump to a new stat table + a signature extra), 10 more, gear 3. Every stat
row in the menu speaks the ES law: `value  >>  +next`. Free trio: DARTY, PYRA, BOOMBA.
The rest buy with GOGACoins (never too expensive): 250-500.

| id | folk | role | base (dmg/rate/range) | cost | gear 2 extra | gear 3 extra |
|---|---|---|---|---|---|---|
| darty | Darty | sharp singles | 1 / 0.95s / 130 | FREE | double dart | golden darts (+1 dmg, pierce 3) |
| pyra | Pyra | fire splash + burn | 2 / 1.4s / 110 | FREE | FIRE TRAPS on the road | ETERNAL FLAME ring around her |
| boomba | Boomba | explosion lobber | 3 / 1.9s / 140, blast 52 | FREE | frag cluster | mauler (+12 vs blimps) + 0.4s stun |
| boomo | Boomo | pierce arcs | 1 / 1.3s / 120, pierce 3 | 250 | orbit guard (spinning rang) | grinder (x2 hits vs blimps) |
| gloop | Gloop | glue slow | 0 / 1.5s / 100, slow 45% 2.5s | 300 | corrosive (1 dps) | THE FLUX (teleports bloons back) |
| kolda | Kolda | ice control | 1 / 1.7s / 105, slow 40% 2s | 350 | permafrost patches | deep freeze (+1 all-dmg to frozen; 1.2s blimp freeze) |
| longeye | Longeye | sniper | 6 / 2.3s / 9999 | 350 | FMJ (+2 dmg, pops lead) | assassin (+25 vs blimps) + shrapnel |
| zappy | Zappy | chain lightning | 2 / 1.6s / 115, chain 3 | 420 | 15% stun | STORM aura (random strikes in range) |
| kaching | Kaching | the bank | +26 PopCoins each wave end, in range aura? no - global | 450 | interest (+8% wave income) | golden egg (+120 every 5 waves) |
| marshal | Marshal | the buff tent | +12% fire rate aura (scales +2%/lvl) | 500 | +8% range in aura | +1 pierce in aura |

Upgrade costs scale by level (`base x 1.14^level`, folk-flavored bases 45-90); GEAR UP
jumps are the expensive door (800 / 2200 for most, more for the bankers). Sell = 70%.
Menu rows per folk speak only THEIR truths (burn dps, blast radius, slow %, chain count,
coins per wave) - the ES "info under the button, >> the next value" law everywhere.
Each gear REPAINTS the folk (bigger, brighter, gear-badge, weapon evolves) - you SEE the
power. Gear 3 wears a golden trim + a soft rune glow.

## 5. SYNERGIES (the in-range lore, BTD-style)

A folk standing in another folk's aura earns the pair bonus; a small badge icon floats
over the buffed folk and the menu lists active pacts by name. Some scale, some are
gear-gated, one is free:

- **DRUM BEAT** - Marshal aura: +fire rate (scales with Marshal level; G2 +range, G3 +pierce). Icon: drum.
- **RALLY** - Darty + Boomo near each other: both +15% attack speed (no gear gate; the free one). Icon: swirl.
- **THERMAL SHOCK** - Pyra (G2) near Kolda: slowed/frozen bloons take +2 from Pyra. Icon: flame-snow.
- **SUPERCONDUCT** - Zappy (G2) near Kolda: chain +2 targets. Icon: bolt-snow.
- **SPOTTER** - Longeye (G2) in a Marshal aura: +3 damage. Icon: crosshair.
- **WAR DRUMS** - Boomba (G2) in a Marshal aura: blast +15%. Icon: ring-drum.
- **GOLD WING** - Kaching (G2) in a Marshal aura: +2 PopCoins per pop. Icon: coin-wing.
- **IGNITE** - Gloop (G3) near Pyra: glued bloons burn 1 dps. Icon: drop-flame.

## 6. WAVES + ECONOMY

- **Start: 250 PopCoins, 100 lives.** Leak damage = the rbe that reached the heart
  (a leaked red = 1 life, a leaked ceramic = 10+, a MOAB = 50).
- 40 designed waves, then endless with +2% bloon speed per extra wave (fatigue).
  Budget grows `60 + 22w + 3w^1.7`; composition bands unlock families wave by wave;
  spacing tightens. Milestones: 10 MOAB, 20 MOAB rush, 30 BRUTUS, 40 THE SIEGE BREAKS
  (victory star, run continues if you stay).
- **The GOGACoin rider:** every 10 waves a random bloon of that wave secretly carries
  the GOGACoin (a faint golden sparkle if you look closely). Pop the carrier and it
  flies to the wallet chip (+1 GOGACoin, collected immediately via the run wallet).
- Wave flow: countdown auto-start, or tap PLAY for an early call (+small PopCoin bonus).
- **Score bonus:** the run bonus is score **/1000** (GOGACoins, the dead-menu law).

## 7. THE SHOP (GOGACoins, the universal shelf)

The HUD SHOP button opens the universal GOGACoins shop (the CS/invaders/matcher shape:
wallet header + coin-icon rows + CLOSE) with two shelves:
- **MAPS:** all 30 (thumb, name, stars, price / OWNED; first 3 wear FREE).
- **FOLK:** all 10 (portrait, role line, price / OWNED; the trio wears FREE).
Buys pay from the box wallet (Box.spend) and flip the same PDMeta flags the game reads -
one source of truth, idempotent, the CS gogabuy law.

## 8. DAY / NIGHT

Every map carries both moods. Night = the ground grain re-graded dark, cold shadows,
the road glows faint, fireflies drift, the folk glow warm. The D/N chips live on the map
cards (2x15 sheet + the shop rows) and the door remembers the last pick per map.

## 9. VFX (the complex-shader law)

Real .gdshader canvas work, not stickers:
- **pop shockwave** ring shader + confetti burst + the layer-flash.
- **burn** heat wobble on burning bloons + ember drift.
- **frost** desaturate + sparkle + crystal overlay.
- **glue** wobbling goo mask.
- **boom** flash + double shockwave + smoke + screenshake.
- **chain** jagged lightning with glow pass.
- **storm/eternal flame** aura rings with scrolling noise.
- **water** shimmer (the river maps).
- **night** full-screen grade + vignette + fireflies.
- **gear up** golden pillar + rune ring burst.
All GL-Compatibility-safe; pooled; capped; the game stays SMOOTH.

## 10. SOUND

The pop is the star: a layered squeak-pop with pitch ladder by layer. Synth set: place,
upgrade, gear-up fanfare, boom, zap, freeze, splat, coin, leak, wave horn, victory, lose.
One happy-strategic music loop + a night variant. Template/ES audio bits reused modified
(button ticks, impacts).

## 11. THE REGISTRY ENTRY

id `pop_siege`, landscape, coin_div **1000**, price 400, fee 10, shop true, banner true,
charge_unlock 100, reveal direct (needs_games 3, price 400) - the owner's graduation
ritual, matcher-style. Achievements: pop_1000, moab_1, wave_25, gear3_any.

## 12. LAWS

1. THE HITS LAW - score = damage instances. Ceramic 10, MOAB 200+.
2. THE /1000 LAW - run bonus = score /1000.
3. THE 2x15 LAW - the maps sheet is two vertical columns of 15, thumbs, day+night chips.
4. THE BUNDLE LAW - day+night ship together, priced together.
5. THE >> LAW - every upgrade row shows value >> +next; hidden at max (the ES law).
6. THE GEAR LAW - 10 levels per gear, the jump is expensive and REPAINTS the folk.
7. THE RIDER LAW - every 10 waves, a GOGACoin hides in a bloon.
8. THE FREE TRIO LAW - 3 folk + 3 maps free; the rest are GOGACoins, never steep.
9. THE BLOCKED LAW - props block cells; green/red drag feedback + tick sfx.
10. THE SMOOTH LAW - pooled, capped, no per-frame trash.

## 17. PATCH 2 - THE WHEEL LAWS (v0.3.5-2)

11. THE GRID LAW - the roads ARE grid cells (full-cell paint, merged rounded
    corners); 9 archetypes x per-map mirrors; the 3-lane wide highway; props
    wall 36-46% of the free land; ground chevrons mark every door.
12. THE WHEEL LAW - color levels 1..12 (crack cost = base + L - 1, the total
    is the pyramid, over-damage spills); 8 wheel art variants per kind.
13. THE STRIPS LAW - up to 10 bands on balloons / 50 on blimps; each band
    hides a bloon of its color; counts never show; inner bloons can be
    striped (depth 2).
14. THE ARMOR LAW - metal (fire only) from wave 22, rock (bombs only) from
    wave 26; the shell eats the hit first; wrong class = clink.
15. THE BLIMP TIERS - moab -> brutus -> gargantua -> titan (shapes are tiers,
    colors are contents).
16. THE POP PAY LAW v2 - a PopCoin per damage dealt; score = damage; the
    threat (leak) counts the whole chain + levels + strips.
17. THE FIRST WAVE LAW - wave 1 never rides a timer; AUTO clocks only the
    between-waves space; MANUAL has no clock at all.
18. THE DRAG LAW - tap-tap AND press-drag-release placement; range rings on
    place AND select; every range finite (the CELL x CELL typo is dead).
19. THE DEATH MENU LAW - `over` belongs to finish_run; game over pops every
    sheet, unpauses, and FIRES.
20. THE CLOSE LAW - the shop and the maps wall wear their own X.
21. THE CORE LAW - the bucket grid + segment caches + capped fx keep
    thousands of bloons at a real 60 (run/max_fps).
22. THE GEAR DOOR - gear-ups cost 2800..15000; upgrades climb at 1.22;
    sell pays 70% of everything invested; broke doors gray live.
