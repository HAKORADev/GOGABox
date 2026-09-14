# HEAVY WAR — the original pack study (01)

> Study source: the owner's archive (password-protected 7z, landed 2026-09-14
> at `heavywar_src/`, OUTSIDE the repo). THE USAGE LAW (docs/DECOMPILATION.md)
> applies end-to-end: **zero original bytes enter the repo or the APK.**
> Everything below is our own factual digest — mechanics numbers, dimensions,
> structure — used as the teacher for our own redrawn art, synthesized audio
> and rewritten tables. The precedent pipelines: GEOMETRY FLASH (v036) and
> POP SIEGE (redesigned art + synth SFX, provenance recorded).

## 1. What the pack is

A full Windows copy of the original horizontal tank shooter (the PopCap
classic, 640x480 era). Everything needed to study is NAKED:

| item | count / form | study value |
|---|---|---|
| `data/craft.xml` | 21 enemy defs | hp(armor) + points + weapon per enemy |
| `data/waves.xml` | 19 mission levels, 3-6 waves each | wave composition law |
| `data/survival0-9.xml` | 10 sets x 80 waves | endless-pressure law |
| `data/bosses.xml` | 10 bosses, encounter L1/L2 | boss params + comeback scaling |
| `data/levels.xml` | 10 places, scroll lengths | place order + pacing (10000-30000 px) |
| `Images/` | 465 files | sprites, 4-layer parallax, boss parts, UI |
| `Images/Anims/Anims.xml` | 54 props across 10 places + survival | parallax prop spec (plane/offset/y/mx/nuked/rare) |
| `Sounds/` | 184 files (ogg + cached wav twins) | full event → sound map |
| `Music/` | tracker module + theme ogg | mood reference only |
| `HeavyWeapon.dat` + dlls | opaque DRM-packed binary | IGNORED (logic lives in the XML + exe) |

What is NOT in the XML: pickup-drop tables and the RNG internals (compiled).
Our drop logic is our own design per the GDD (the friend helicopter cadence).

## 2. The craft table (21 enemies) — facts + our mapping

Original fields: `armor` = hits to kill (tank gun power runs 1 -> ~8 late),
`points`, `arms` (weapon). Sprite = horizontal strip, frames left-to-right.

| orig id | armor | orig pts | strip px | frames | our id | our pts | role |
|---|---|---|---|---|---|---|---|
| PROPFIGHTER | 1 | 50 | 280x30 | ~3 | SCOUT | 1 | shared fry, none |
| SMALLJET | 1 | 100 | 80x30 | ~1 | DART | 1 | shared fry, dumb bombs |
| BOMBER | 10 | 250 | 120x44 | ~2 | RAIDER | 1 | shared, dumb bombs |
| JETFIGHTER | 6 | 500 | 80x28 | ~1 | LYNX | 1 | shared, guided bombs |
| BIGMISSILE | 10 | 500 | 300x200 | ~8+exhaust | KOMET | 1 | shared, ballistic faller |
| CRUISE | 75 | 500 | 720x90 | ~8 | SKIMMER | 1 | shared, sea-skimmer |
| DELTAJET | 20 | 1500 | 100x34 | ~2 | FANG | 1 | shared, armored bombs |
| DELTABOMBER | 30 | 1500 | 110x36 | ~2 | TALON | 1 | shared, frag bombs |
| STRAFER | 20 | 1500 | 850x72 | ~10 | WASP | 1 | shared, swoop + cannon |
| SMALLCOPTER | 25 | 1000 | 450x40 | ~9 | HORNET | 1 | shared, energy cannon |
| DEFLECTOR | 80 | 2000 | 100x33 | ~2 | MIRROR | 1 | shared, front shield + missiles |
| TRUCK | 40 | 750 | 900x60 | ~15 | TECHNICAL | 10 | special, RPG arcs |
| BIGBOMBER | 40 | 750 | 160x50 | ~4 | CARPET | 20 | special, carpet bombs |
| MEDCOPTER | 80 | 1500 | 700x60 | ~10 | VIPER | 30 | special, AT missiles |
| BIGCOPTER | 180 | 2000 | 900x60 | ~15 | MAMMOTH | 40 | special, AT missiles |
| SUPERBOMBER | 90 | 2000 | 160x43 | ~3 | FORTRESS | 50 | special, armored bombs |
| SATELLITE | 200 | 5000 | 760x100 | ~8 | ORBITAL | 60 | special, sky laser |
| ENEMYTANK | 150 | 7500 | 900x60 | ~15 | GRINDER | 70 | special, cannon |
| DOZER | 400 | 8000 | 1400x90 | ~15 | PLOWMAN | 80 | special, plow (invulnerable front) |
| FATBOMBER | 300 | 3000 | 200x77 | ~3 | ATOMAULT | 90 | special, atom bombs |
| BLIMP | 400 | 25000 | 300x82 | ~1 | ZEPPELIN | 100 | special, bombs + bullet shower on death |

11 shared pay 1 pt; 10 specials pay 10..100 (the GDD's 10/11 law satisfied:
specials = the ten above). `armor` retunes into our `hp` after the shells
scale is set (gun dmg 1..8 -> our dmg 1..5 via SHELLS + boss points).

Place-exclusivity (GDD): each of the 10 places claims 1-2 exclusive specials,
the rest go shared. Draft: snow=ATOMAULT, coast=SKIMMER, oil=TECHNICAL,
nuclear=ORBITAL, jungle=PLOWMAN, gothic=ZEPPELIN, war-torn=GRINDER,
desert=CARPET, city=MAMMOTH, hq=FORTRESS + VIPER. Tunable in the table.

## 3. Waves — the pressure law

- Mission: wave `length` 1000 -> 2000 px of scroll; waves mix 2-4 craft ids,
  qty 2-8 each early, 20-50 late (level 10 = mono-swarm spectacle waves).
- Survival: 80 waves per set; later sets reuse compositions with bigger qty
  (qty 30+ of one id per wave at set 9) — pressure via QUANTITY, not new types.
- Takeaway for our director: compositions are the vocabulary; escalation =
  longer waves + fatter quantities + rarer fry/ heavier specials ratio.
  We keep ~10 hand-built wave recipes per pressure tier and remix per place.

## 4. Bosses — params + the comeback model

10 bosses; first 9 have L1 + L2 blocks, final has one. Components carry their
own armor + `fire` delay (frames at 100 fps -> seconds = frames/100).

| boss | body armor L1 -> L2 | score L1 -> L2 | key components (L1) |
|---|---|---|---|
| twin-rotor gunship | 300 -> 4000 | 10k -> 80k | turret 80hp/fire 1.75s; missile launcher 100hp/2.5s |
| battleship | 800 -> 3500 (turrets 200 -> 1500) | 20k -> 90k | 4 guns (fire 1.5-2s, creep speed .075-.1) + launcher 2.5s |
| meteor blimp | 2700 -> 9000 | 30k -> 100k | tractor dish (down .8s/up .4s), 15 -> 20 meteors, fire .8 -> .6s |
| wrecking walker | 2500 -> 5500 | 40k -> 110k | ball on chain, short -> long chain |
| charge head | 2800 -> 5000 | 60k -> 130k | 2 launchers, charge delay 5s, bomb on/off 30/30 f |
| giant ape | 2500 -> 6000 | 50k -> 120k | thrown projectiles .04, jump physics (xspeed 1.35, yspeed 4, gravity .06) |
| eyebot | 1500 -> 2500 (hand 300 -> 900) | 50k -> 120k | body fire .6 -> .4s, hand fire .2 -> .1s |
| mech worm | 2000 -> 4000 (turret 500 -> 1000) | 50k -> 120k | jump depth 1100 -> 900, boulders 8 -> 16, fire .4 -> .3s |
| war robot | 2200 -> 4000 (arm 750 -> 1700, launcher 700 -> 1000) | 70k -> 140k | eye laser 3.0 -> 2.5s, jump accel params |
| secret weapon | 15000 | 140k | bomb 2s, laser .5s, turret .6s spin .1, small+big launchers |

THE COMEBACK LAW (ours): each re-encounter multiplies armor ~x2.5-4 and cuts
fire delays ~x0.6 — exactly the GDD's "comebacks: shoot more, act faster".
Our endless model: comeback N scales armor x2.2^min(N,4), fire x0.85^N
(floored), +1 new component behavior every 2nd comeback.

## 5. Places — the 10 sceneries + the parallax spec

Mission lengths: 10000, 15000, 25000, 20000, 30000 x6 (px of scroll).
Scenery themes in order: snow waste / sea coast / oilfields / nuclear zone /
jungle / gothic hills / war-torn steppe / desert / metropolis / HQ.
THE SHUFFLE (GDD) frees us from the order; the tunnel swaps the palette.

Parallax layers per place (from Backgrounds/ + Anims.xml):
- `sky` 640x480 (flat + gradient, sits still) — plane 4
- `bg` 960x300 (far silhouettes) — plane 3, slow scroll
- `bg2` 960x300 (near dress) — plane 2, faster scroll
- `ground` 640x60 (the road strip) — plane 1, tank-speed scroll
- props: 3-6 per place (`Anims.xml`): plane, offset x, y, `mx` drift
  (px/frame extra), frames 1-9, speed (1 = 100fps), `rare` flag (some),
  `nuke` flag = strip's last frame is the burnt variant.

Our place set (own names, same ten sceneries): FROSTKRAI, GULFGATE,
OILREACH, NUKEFLATS, VINEBELT, GLOOMKEEP, ASHFALL, DUNEFORT, STEELCROWN,
IRONHOLD. Each carries: palette quad, 2 bg silhouettes, ground strip,
3 prop doodads (1 redrawn anim each), 1-2 exclusive enemies (see §2).

## 6. Art slots we redraw (sizes matched, art ours)

Slots and target sizes (px, from the strips' single frames):

| slot | frame size | notes |
|---|---|---|
| player tank + shadow | 80x55 (+80x20) | 10 drive frames; flame 80x20; muzzle flash |
| scout/dart fry | 80-93x28-30 | 2-3 frames |
| bombers (raider/carpet/fortress/atomault) | 110-160x43-77 | 2-4 frames |
| copters (hornet/viper/mammoth + friend) | 90-120x40-44 | body + separate rotor strip |
| deltas (fang/talon) | 100-110x34-36 | 2 frames |
| strafer/wasp | 85x72 | 10 frames (swoop pose) |
| grinder/plowman (ground) | 90x60 | 15 frames incl. wheels |
| skimmer/komet + warheads | 90x22-40 | missile shapes + exhaust |
| zeppelin | 300x82 | 1 frame + separate prop |
| orbital | 95x100 | 8 frames panels |
| mirror + its shield | 100x33 + 120x30 | shield is separate overlay |
| bombs family (dumb/guided/frag/armored/atom/fragments) | 10-60 x 10-30 | white-mask style = we tint |
| explosion | 160x160 x 20 | white mask -> we draw 20 ours (radius ramp) |
| shield ring | 80x70 x 10 | pulsing ring, ours |
| friend copter | 120x44 + rotor strip | the GDD's delivery helicopter |
| powerup icons | 32x32 x 12 | shield/nuke/laser-part/life/coin set |
| upgrade icons | 72x72 x 6 | our six stats |
| status bar | 640x30 | our war room strip (rebuilt to our layout) |
| tunnel | n/a | ours entirely (no reference art in pack) |
| place layers | sky 640x480 / bg 960x300 / bg2 960x300 / ground 640x60 | x10 places |
| boss parts | hulls 330-592x62-310, turrets 1440x90 strips, blades 1000x50 | 10 bosses, component lists per §4 |

Style contract (ours): flat toy-military look, 2px dark outline, 3-4 tones
per sprite + 1 highlight; enemies get faction rust-red insignia; player gets
olive + star; white-mask parts (explosions, bombs) tinted at runtime.

## 7. Sound events (the 184-file map, ours synthesized)

Groups seen by filename: gun (shoot/hit), bombs falling + whistles, three
explosion tiers (small/med/big + debris), laser (charge/fire/hit), shield
(up/zap/break), nuke (launch/mushroom/click), alarms (airraid/alert), enemy
weapons (cannon/missile/rpg), engines (copter loop), boss (roar/blast/laser),
UI (button up/down), the friend copter loop, victory sting. Our synth set
rebuilds ~30 distinct events in our own sound (numpy, see the sfx tool).

## 8. Fonts / music

- Bitmap stencil fonts (keypunch/rubberstamp/station) — we keep the house
  Kenney CC0 font, stenciled via spacing/caps; no pack bytes.
- Music: a tracker module + a theme ogg stay out; our own 2 loops (action +
  boss) get synthesized or sourced CC0 and logged in the manifest.

## 9. Integration map (XML -> our tables)

- craft.xml -> `ENEMIES` in heavywar_data.gd (hp/pts/speed/pattern/skin,
  shared flag, place exclusivity list)
- waves/survival -> `WAVE_RECIPES` per pressure tier (10 recipes x 5 tiers)
- bosses.xml -> `BOSSES` (per-boss component list + base fire/armor + the
  comeback formula)
- levels.xml -> `PLACES` (palette, layers, props, exclusive enemies, length
  in seconds 150-300 per place — the GDD's 3-10+ min law)
- Anims.xml -> per-place prop tables (plane, y, drift mx, frames, rare)
- Numbers are STARTING POINTS — the owner tunes after the first test build.

## 10. Provenance note for the manifest

Source: owner-supplied archive (private study copy, outside repo). Derived:
100% redrawn/synthesized. Zero original bytes ship — same posture as v036.
