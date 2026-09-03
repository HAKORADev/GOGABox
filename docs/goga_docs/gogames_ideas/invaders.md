# SPACE INVADERS — the v0.3.2 journal

One file per game, newest at bottom, never in-place edits (repo law). This is the
born-of-loss rebuild: the first v0.3.2 died with an unpushed sandbox. Everything
below is re-derived from the owner's contract (preserved verbatim in the chat log)
+ the repo's own history.

---

## THE OWNER'S CONTRACT (digest)

Space Invaders (the hen workshop teaser, renamed + graduated). Horizontal. Ten
stages, ten waves each, wave ten is that world's boss, and the tenth place is the
aliens' hideout where THE INVADER waits. Tour the solar system from Neptune inward
to the Sun. Small scores (+1/+2/+3), bosses +25..+200. Three hearts, a heart loss
costs -500 score, the run bonus is ÷500, a new heart every +1000. Left half moves,
right half fires. No shields for the protector. The SSDS crew ships are the shop:
2-in-1 buys (ship + exclusive weapon, no mid-run switching), optionals menu picks
the starter, weapon item icons only spawn for the ship that needs them. Thunder
becomes an electric beam that chains around itself upward; the Bomb Launcher has
no ammo limit and detonates only on touch. A Stage Themes pack paints every world
its own color. The DEFEND button rents a crew defender for ten waves - one hit
kills it, items ignore it, three dialogue variants per moment. Bosses 3, 6 and 9
run away and come back for the finale gauntlet before THE INVADER. Lore pop-ups
from the Protector everywhere, alpha panels with white text, wave titles at the
center, smooth stage transitions, "TAP ANYWHERE TO PLAY", no orientation ask,
nobody ever dies - the war loops, one universe with Space Dash.

---

## 1. THE TOUR (stage table, real-world data drives each background)

| # | Stage name            | Background law (real data)                                                  |
|---|-----------------------|-----------------------------------------------------------------------------|
| 1 | NEPTUNE - THE OUTPOST | deep azure; the fastest winds in the solar system (2,100 km/h) as long streak lines; a dark storm oval |
| 2 | URANUS - THE TILT     | pale cyan methane haze; the rings run VERTICALLY (98° axial tilt)            |
| 3 | SATURN - THE RINGS    | pale gold; a huge ring arc across the frame; the hexagon storm at the pole   |
| 4 | JUPITER - THE GIANT   | banded cream/rust stripes; the Great Red Spot drifting; 300+ Earth-mass bulk  |
| 5 | MARS - THE RED DUST   | rust gradient, dust veils, Olympus Mons silhouette on the horizon, two moon dots |
| 6 | EARTH - HOME          | blue marble light, cloud swirls - the protector's own ground (special dialogue) |
| 7 | VENUS - THE FURNACE   | yellow-white sulfur cloud deck, 465°C glow, the retrograde spin (bg scrolls backwards) |
| 8 | MERCURY - THE CRATERS | gray, crater ring shadows, 430°C day vs -180°C night as a hard light split    |
| 9 | THE SUN - THE WALL    | blinding corona, 5,500°C surface arc, flare loops, heat shimmer              |
|10 | THE HIDEOUT           | void black; the alien megastructure with purple reactor veins; the war's front door |

Stage themes: without the pack the tour wears one neutral deep-space scheme; with
the Stage Themes pack (shop, 6000) every stage wears its own palette and the change
cross-fades over ~1.5s when the stage flips.

## 2. ENEMY ROSTER (aliens; CI archetypes reskinned)

Score law: +1/+2/+3 only. HP scales per stage: `hp = base * (1 + 0.18*(stage-1))`,
so stage-1 enemies feel iron (the owner: "at the start, enemies will not go down")
while the power ladder outgrows them later.

| kind      | tex            | hp base | score | behavior law |
|-----------|----------------|---------|-------|--------------|
| grunt     | en_grunt.png   | 6       | +1    | formation hover, gentle bob |
| swift     | en_swift.png   | 4       | +1    | fast figure-eight weave inside its slot |
| aimer     | en_aimer.png   | 8       | +2    | fires an aimed bolt every 2.6-4.2s |
| diver     | en_diver.png   | 5       | +1    | detaches and dives the ship - THE breach threat |
| tank      | en_tank.png    | 22      | +2    | slow, armored, sits and soaks |
| splitter  | en_split.png   | 7       | +1    | on death spawns 2 grunts at its slot |
| weaver    | en_weaver.png  | 10      | +2    | wide sine drift, harder to lead |
| spitter   | en_spit.png    | 12      | +2    | 3-bolt fan every 3.4s |
| brute     | en_brute.png   | 30      | +3    | shotgun spread of 5, elite armor |
| magma     | en_magma.png   | 18      | +3    | sun stages: drops fire trails that linger |
| void      | en_void.png    | 26      | +3    | hideout: blinks 140px, fires a ring of 8 |

Stage pools: stage 1 = grunt/swift/diver; +aimer 2, +tank 3, +splitter 4, +weaver 5,
+spitter 6, +brute 7, +magma 8 (sun-born, ride the tour), +void 10. More types per
stage = the owner's "more different types of enemies" law.

## 3. BOSSES (wave 10 of every stage; every one has named specials + own SFX/VFX)

| # | Boss name        | HP  | score | special moves |
|---|------------------|-----|-------|----------------|
| 1 | Triton Warden    | 60  | +25   | SPEAR VOLLEY (aimed 3-line), DIVE CALL (summons 3 divers) |
| 2 | Tilted Monarch   | 80  | +30   | SIDE ROLL sweep across the frame, RING TILT (vertical ring shots) |
| 3 | Ring Duke        | 100 | +40   | SHARD RING (orbiting shards, lanes seam law), RAIN OF ICE — RUNS at 20% hp |
| 4 | Storm Tyrant     | 130 | +50   | RED SPOT PULSE (slow big orb), SPIRAL STORM (rotating bolts) |
| 5 | Dust Reaver      | 150 | +60   | DUST DASH charges, SAND SPREAD fans |
| 6 | The Mimic        | 170 | +75   | wears our blue: MIMIC BEAM (fake friendly laser), DECOYS — RUNS at 20% |
| 7 | Ash Queen        | 200 | +90   | ACID RAIN curtains, MIRROR doubles |
| 8 | Sun Eater        | 230 | +110  | CRATER SUMMON (spawn craters that burst), FLARE BEAM sweep |
| 9 | Solar Herald     | 280 | +150  | PROMINENCE arcs, HEAT WAVE pushback — RUNS into the sun at 20% |
|10 | THE INVADER      | 420 | +200  | VOID FLOWER (bullet flowers), BLINK, ELITE CALL, phase 2 rage under 40% |

The 3/6/9 law: they are never killed mid-tour - at 20% HP they RUN with a lore
popup and return in the stage-10 gauntlet: #3 alone → a strong wave → #3+#6 → a
stronger wave → #3+#6+#9 finished for real → THE INVADER descends.

## 4. THE SSDS CREW (ships = shop, 2-in-1 with their weapon)

| ship     | price | tail color  | exclusive weapon law |
|----------|-------|-------------|----------------------|
| Azure    | 0 (starter, THE PROTECTOR) | blue   | blue small balls, yellow-weapon cadence (0.16s), upgrade = more balls, small angle |
| Ember    | 1500  | orange      | red small beams; upgrade = more beams, wider spread |
| Verdant  | 2000  | green       | green snake beams: slow weaving, PIERCE (DPS while overlapping), upgrade = more + taller |
| Veteran  | 3000  | bright red  | sound arcs (open-circle waves); upgrade = bigger + stronger |
| Phantom  | 3500  | normal red  | machine gun: rapid, small damage per bullet |
| Hornet   | 4500  | white       | fire: spreads across enemies on hit; upgrade = spreads more, burns longer |
| Titan    | 6000  | deep red    | missile 1 per 5s, SAME damage to every enemy; upgrade = more damage |

Damage laws (owner-exact):
- Per-hit weapons: damage per shot = power level (1..5).
- Continuous (Verdant, lasers): damage is hits/sec; piercing falls off per enemy
  passed, floor 1, never 0.
- Radius (Thunder, bombs): each chain hop / radius line deals one less: 6→5→4…, floor 1.
- Power ladder 1..5; points needed per level: 2/3/4/5; a power point spawns 1 per
  1-2 waves; death drops 3 LEVELS (the lanes law).
- Shop add-ons (like Space Dash): THUNDER 2500 (electric beam up, chains around the
  beam column), BOMB LAUNCHER 3500 (no ammo limit, contact-detonate only).
  They join the loot pool when bought and are picked up as a weapon SWITCH (own
  ladder); the ship's own icon switches back.
- Loot: GOGACoin 2-10 waves after the last; power point 1 per 1-2 waves; weapon
  icons 5% rolls (own icon always allowed, thunder/bomb only if bought).
- Hearts: start 3, cap 3 (a 4th pays +25 score, lanes law), +1 every 1000 score,
  -1 and -500 score (floored at 0) on a hit, 1.4s invuln.
- Breach: one enemy past the bottom = the run is LOST (dialogue + END → death menu).

## 5. DEFEND (the rented crew)

Button next to SHOP. Rents any crew ship except the current one: 10 waves of life,
one at a time, once per ship per run, level-3 weapon, one hit kills, invisible to
all items, overlaps the protector (protector drawn on top). Prices: Ember 120,
Verdant 150, Veteran 180, Phantom 200, Hornet 240, Titan 300 (Azure 100 if the
starter is not the current ship). Defender AI: mirrors the owner's ship weapon
behavior, targets the nearest threat, never breaches (it never dives past the bottom).

## 6. DIALOGUE (alpha pop-ups, white text, up to 3 variants per moment)

- Intro (first stage, once per run): references Space Dash - the protector has been
  holding the line since the dash wars so the aliens never reach our solar system.
- Stage arrival ×3, boss start ×3, boss end ×3, escape popups for #3/#6/#9, the
  gauntlet calls, breach ×2, the end (the Invader runs, the protector chases
  off-screen, END button: "they may not be out yet. they never really are.").
- Defender call (caller line + called reply) ×3, defender end (called farewell +
  caller reply) ×3, defender death (caller) ×3. Full text tables live in the engine
  header (invaders.gd LINES) and are quoted verbatim from the owner's brief where
  the owner wrote them.

## 7. ECONOMY

fee 100 (dario-tier tour game), price 350 (the hen teaser's own price), coin_div 500,
shop on, banner on, orientation landscape, ach: score_2000 "Solar Shield", kill_500
"Star Sweep", clear_tour "The Long War", boss_all "Duke Hunter" (meet 3/6/9),
defend_3 "Crew Trust" (call 3 defenders total), breach none (obviously).

## 8. ASSETS (all painted/derived in tools/v032_invaders_art.py)

- 7 crew ships (Kenney space-shooter-redux hulls recolored per SSDS law + painted
  cockpit variants) + the protector's dedicated look.
- 11 enemy types + 10 bosses (painted alien tech, planet-themed).
- 10 planet background plates (1920×1080, real-data driven) + the neutral scheme.
- Projectiles/VFX: blue ball, red beam bolt, green snake segment, sound arc, MG
  bullet, fire puff, missile, thunder beam, bomb, impact rings, burn marks.
- Items: 7 weapon icons, power point, GOGACoin, thunder, bomb, heart.
- SFX: 20+ voices (inv_*) + tour theme + hideout theme (tools/v032_invaders_sfx.py).

## 9. ENGINE SHAPE

`game/games/invaders/invaders.gd extends GogaGame`, no .tscn, landscape 1920×1080
design (ScaleRule.DESIGN_LANDSCAPE), raw ScreenTouch by index (dario law): first
left-half touch owns the move anchor, right-half press/hold fires. Painter pattern:
one painter node draws entity arrays (the lanes mobile law). Wave director builds
formations (line/V/arc/circle/diamond/columns/ring/lattice) from per-stage pools,
waves complete when cleared, wave titles center-pop, bosses script their own moves.
Finale gauntlet wired in stage 10 between waves. `finish_run(score)` on death/breach/
end dialogue; `pause_end_run` true (bank from pause).
