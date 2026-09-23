# TOWER DESTROYER — the GDD (v041-3)

> Graduated from `FUTURE_GAMES.md`'s `fire-ball-3d-like` note. The teacher
> is Voodoo's **Fire Balls 3D** (`com.NikSanTech.FireDots3D`, the owner
> handed the XAPK). The bundle is Unity il2cpp — the study yielded the
> SHAPE (HOLD TO FIRE, the rotating segment platforms, the tower coming
> down on the shooter), not numbers; every constant here is ours, tuned
> by the pacing sim and the probe. Mechanics study only — zero original
> bytes (THE USAGE LAW). The box's **second 3D game** (the 3D seat is
> v041-2 infra) and its **first multiplayer-shaped one**.

## The one-paragraph pitch

You sit at the bottom of an endless tower that will not stop coming down.
Hold to fire: balls climb from your cannon, hit the lowest platform, and
chip its colored segments. Break a platform's last colored segment and
the whole ring shatters — 1 point, banked by whoever's ball landed the
final hit. Black segments never break; when a platform crosses your
muzzle line, the seat under a black segment **dies**. Every platform
rolls its own descent speed and its own spin, so the tower never repeats
itself. Bring a crew: 1/2/3/4 shooters on the four ground seats — the
CPUs watch with their own eyes and fire with their own rhythm.

## The laws (the owner's words, restated as systems)

- **BOTTOM-TO-TOP** — Tower Ball's ball descended; here the shooter is
  planted at the bottom and the tower descends to him. Progress reads
  upward: the deeper the wreckage counter, the harder the tower pushes.
- **BLACK KILLS, AS USUAL** — the tower-ball black law, inverted for a
  shooter: at the landing line each seat is judged by the slot over its
  angle. Alive black = that shooter dies (the human's death ends the
  run; a CPU's death is just one gunner fewer). Alive colored shatters
  harmlessly against the ground; an open slot (already broken) forgives.
- **1 PLATFORM = 1 POINT** — to the shooter whose ball broke the LAST
  colored segment. Personal scores; CPU scores live on their seat tags.
- **THE /100 BONUS** — registry `coin_div: 100`; the host banks
  `pickups + score/100` at the gate (Arc.bonus_ratio_text prints it).
- **DIFFERENT SPEEDS, NOT-PREDICTABLE** — every platform rolls its own
  descent speed in a ±(0.55..1.65) band around a base that grows with
  the run's destroyed count (1.05 → cap 2.4 u/s) AND its own spin
  (±0.25..1.2 rad/s). The pacing is the challenge; nothing is memorized.
- **THE COIN AFTER 200 PLATFORMS** — after 200 run-wide destroyed
  platforms (and every 200 after), a GOGACoin boards a COLORED slot of
  the platform two spawns later. Break THAT segment to bank it into the
  run wallet; let the platform land and the coin is gone forever. After
  200 *platforms*, not 200 points — CPU kills count toward the clock.
- **ENDLESS** — no rounds, no ladder: ALIVE_AHEAD (14) platforms kept in
  the air, spawned at y=118, hp tiers grow every 18 destroyed (cap 3),
  black and gap bands widen with depth.

## The four seats (THE LAN SEED)

The ground ring carries four seats at exactly 90°: front (angle 0, the
human), right, back, left. Every shooter is a `PlayerSeat` dictionary:
`angle, alive, score, is_cpu, pers, cannon, tag, fire/burst clocks` —
the ONLY difference between a human and a CPU is the input source that
drives its fire clock. The future LAN play swaps `cpu` for
`network`, and nothing else in the file changes. (The owner: "the
current implementation is not true multiplayer ofc" — this game is the
test rig for that future.)

## The CPU minds (human-like, per the owner)

Every CPU rolls its own personality at seat build:

| trait | band | meaning |
|---|---|---|
| detection_lead | 0.3..0.9s | how early it answers an incoming platform, scaled by the platform's own speed (a fast platform pulls an earlier lead) |
| reaction | 0.1..0.4s | the beat before its first ball on a fresh target |
| burst_len | 2..6 | balls per burst — a human trigger finger |
| burst_pause | 0.25..0.7s | the breathing gap between bursts |
| discipline | 0.65..0.95 | the chance it correctly holds fire while black rides over its seat; a mistake wastes balls into the armor (never kills) |

CPUs fire at 85% of the player's rate (the human has the edge), keep
their own score, wear a small seat-tinted cannon, and their score tag
rides above their seat — unprojected every frame, removed accurately
when they die (the tag fades, the cannon sinks below the ground).

## Controls (hold to fire, the box's one input road)

- Touch: HOLD anywhere to fire, release to save shots.
- PC: hold LMB / SPACE / DOWN; 1-4 picks the crew on the ask screen.
- Gamepad: X (or A) holds the fire.
- The flow is the universal one, portrait-only: Screen 1 CHOOSE PLAYERS
  (1/2/3/4, the house ask layout), Screen 2 TAP ANYWHERE. The asks are
  the game's ROOT — back never closes them (the tower ball r3 law).

## Skins (designs, not colors — the tower ball r2 law)

- CANNONS (5): GUNNER (the free classic) · IRON HOWITZER (rough metal,
  short fat barrel) · CRYSTAL CANNON (transmissive glass, long slim) ·
  CARBON PIERCER (dark matte, longest barrel) · GOLD BOMBARD (polished
  gold). Each is a material + shape identity, not a tint.
- BALLS (5): STONE SHOT · ICE SPHERE (translucent frost) · LAVA CORE
  (emissive) · STEEL BALL (polished metal) · GOLD SHOT.
- Prices ride the box ladder: 0 / 250 / 350 / 450 / 550 GOGACoins; the
  shop sells (ON rows, dry wallets disabled), the game applies live.

## Economy + entry

- Registry: price 450, fee 8, `coin_div` 100, shop, `dim: 3d`,
  `orientation: portrait`, reveal `{direct, appear_after 8,
  needs_games 11}` — the same gates the last graduates wear.
- 8 achievements: First Rubble · Demolition Hand (50) · Site Regular
  (10 plays) · Full Crew (a 4-shooter run) · Coin Crane (3 coins) ·
  High Excavation (150) · The 200 Club (200 in one run — the coin law
  tie-in) · Eternal Wreckage (500 lifetime).
- Sounds: the td_* family + the td_theme loop (the v0413_td_sfx forge,
  OGG q6 per the slim audio law).

## The proof

- `tests/towerdestroyer_probe.gd`: the pure laws over hundreds of seeds
  (slot bands, the guarantee, hp tiers, the speed/spin bands, the black
  landing truth table, the coin clock, the CPU minds) + the REAL host
  boot + simulated play (the crew flow, the back law, the fire, the
  point law, the live coin carrier, the CPU death removing the seat
  accurately, the human death banking the run).
- `tests/flow_test.gd` wears the four-seat section (31 playable,
  towerdestroyer walks last).
- The film: the crew firefight under the dusk sky, eyed across
  iterations (the vision law).
