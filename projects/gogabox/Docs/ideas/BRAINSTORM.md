# Ideas garage (spam freely, prune never)

## Ports waiting for their cycle
- **Pop TD**: keep 6 towers? simplify to 4, endless waves, GOGACoin economy
  funds towers between runs. Maybe 3D (Godot does 2D+3D in one project —
  the registry already has a `dim` field).
- **Dario**: port platformer levels into an endless procedural climber with
  the hopper camera rules; reuse hopper entry flow.
- **Matcher**: endless timed match-3 — but we already ship CandyRush outside
  the box; make this one 60-second blitz so both coexist.
- **XO Ladder**: AI difficulty ladder where each win climbs a streak multiplier;
  loss resets. Cheap to build, good coin sink (hints cost coins).
- **Hen Invaders 1P**: waves + boss hens; GOGACoin drop per wave.
- **Escape The Maze**: procedurally generated, coin rooms, fog-of-war.
- **Key Singer**: rhythm-tapper rework: falling notes, tap lanes, combos.
  Needs per-game music (see below).

## Box-level ideas
- Per-game music: 2-3 more CC0 loops from OpenGameArt, one per game vibe.
- Daily missions (play 3 different games / score X in lanes) -> GOGACoins.
- GOGACoin skins for the BOX itself (amber / midnight / mint chrome).
- Achievements page per game already in infra; add a global trophy case.
- Leaderboards: local first (best per game); online later, no accounts,
  maybe plain opt-in name entry.
- Fruit Slasher frenzy power-up (rewarded ad: 10s slow-mo).
- Snake shield: one free crash per run via rewarded ad.
