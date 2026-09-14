# HEAVY WAR — build plan (02)

> The architecture + the pass order. Data-first: everything the pack would
> tune lives in tables, so the pack's arrival is a swap, not a surgery.

## Architecture

```
projects/gogabox/game/games/heavywar/
  heavywar.gd        # the world: road, tank, waves, drops, bosses, tunnels
  heavywar_data.gd   # ALL tables: places, enemies, bosses, drops, upgrades
  heavywar_meta.gd   # the persistent armory: banked points + allocations
```

- `heavywar.gd` extends `GogaGame` (the house contract). Landscape.
- Registry entry: id `heavywar`, title "HEAVY WAR", landscape, shop true,
  banner true, coin_div 500 (the owner's score bonus law), fee + price set
  at ship, reveal direct.
- Persistent armory: `heavywar_meta.gd` mirrors `cs_meta.gd`'s pattern —
  a small per-save dict (banked points, allocated levels, unlocked
  upgrades, laser owned). Shop purchases (4 upgrades + laser) ride the
  standard shop item system; the meta reads the owned flags.
- Stand-in art: house code-drawn (the snl/ludo way). The pack swaps it:
  every visual is drawn through one `_art_*` indirection keyed by data ids
  (`enemy.skin`, `place.skin`), so real sprites drop in without touching
  the sim code.

## The systems (each gets its own pass + its own qa phase)

1. **THE ROAD** — fixed-screen arena, the tank on the bottom road,
   parallax dress per place. The screen is the world during a place.
2. **THE TANK** — left-half horizontal swipe (TouchKit drag), iframe
   blink, 3 lives, shield layers drawn as rings.
3. **THE GUN** — right-half tap/hold fires; fire rate/damage/spread read
   the armory. Shell = vertical tracer, hit = the plane's hp.
4. **THE SKY** — the spawn director: per-place tables (shared + exclusive
   enemies), intensity ramps with places survived, the "always goes up"
   law. All spawn math parameterized (the XML will re-tune it).
5. **THE PLACES + TUNNELS** — place shuffle each run; the tunnel transition
   (tank drives in, screen scrolls, calm zone both sides — no spawns for
   N seconds before/after). Place duration pressure: the director moves on
   when the place's quota is served (target feel 3–10+ min).
6. **THE FRIEND** — the helicopter's drop logic: shields (max 3), nukes
   (max 3), laser components, life (max 3), GOGACoin after each 3 places.
7. **THE BOSSES** — every 5 places; +10 faces, comeback scaling (more
   shots, faster acts); death pays 1 point and opens the armory menu.
8. **THE ARMORY** — 6 upgrades x 5 levels; first 2 open, 4 shop-locked;
   the after-boss menu (house layout, law 28: title + equal cards) with
   increase/decrease reallocation; permanent across runs.
9. **THE ECONOMY** — kills = score; the 10 special enemies pay 10..100;
   life every 1000 score (max 3); bonus /500; nuke tap = middle area.
10. **THE WAR ROOM (top bar)** — lives, nukes, shields, laser charge,
    score, coins, place progress — the accurate widget strip the owner
    demanded.
11. **THE SHIP** — thumbnail (composer scene), flow_test block, qa file,
    config bump 0.4.0 (the owner's own v040 name), commit + push + CI.

## The upgrade six (stand-in names until the pack's XML names them)

ENGINE (move speed) / ARMOR (hit forgiveness) / RELOAD (fire rate) /
CANNONS (multishot spread) / SHELLS (damage) / AEGIS (nuke capacity +
laser charge). The data table maps ids -> the real six the moment the
pack study reads the XML.

## The enemy table shape (the XML's future home)

```
{id, name, hp, speed, pts, pattern, skin, shared: bool, places: []}
```
- 11+ types: the small fry pays 1; the ten specials pay 10,20,...,100.
- Each place = {id, name, palette, props, exclusive: [enemy ids]}.
- Spawn director reads the place's table + the run's escalation knob.

## Test plan (the brutal + critical part)

- `tests/qa_v040_heavywar.gd`: headless — controls (real finger events),
  spawn director laws (calm zones, ramp, shuffle determinism), drop laws
  (helicopter cadence, caps 3/3/3, coin every 3 places), boss cadence
  (every 5 places), point payout + menu open, armory laws (caps 5,
  reallocation math, permanence across a simulated death), economy laws
  (kill score, life per 1000 max 3, nuke caps), tunnel transitions never
  spawn, quit-from-any-sheet leaves the tree breathing (law 30).
- flow_test: the registry block + boot + a scored run.
- Xvfb film rig: the tank, the sky, the tunnel, the war room strip —
  pixel census, not eyeballs.
