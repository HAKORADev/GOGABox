# PLAN v0.2.4 — Space Dash: the enemies-and-weapons redesign

The owner's brief: rename the lane-dodger AGAIN (Space Dodge -> **Space
Dash**), then tear the "3 lanes + falling blocks" game down and build the
real thing — tons of enemy SHIPS, kills as score, four weapons, loot from
wrecks, hearts, power ladders, a shop with skins/weapons/spaces, SFX/VFX
with a realistic-lighting pass. "take your whole time working on the game,
but first update that doc then do that lite bugfix for the box".

Order of work (the owner's literal order):

## 0. The docs first
- [x] FUTURE_GAMES.md fifth dump: "1 2 3 4 player games - offline" joins
  the study shelf WITH the owner's local-network-multiplayer note (a device
  per player pays the per-round economy better than one-phone-many), +
  party-dash-like (endless vertical action platformer), + memory-cards-like,
  + 3D rubiks-cube-3d.
- [x] gogames_ideas/dash.md — the game journal (contract + decisions).

## 1. The box lite bugfix
- [x] **Top picks leaked SOON tiles** (owner: "in the top-picks, it lists
  some soon titles while it should only list owned playable games").
  `Roadmap.daily_picks()` pooled every game `Box.owns_game()` accepts —
  and under the all_owned dev cheat that is EVERYTHING, workshop teasers
  included. The pool now skips `coming_soon` games outright: today's picks
  suggests PLAYABLE games, cheat or no cheat.

## 2. The rename
- [x] Registry title "Space Dodge" -> **"Space Dash"** (id `lanes` never
  moves). Tag, desc, controls rewritten for the new game. FLOW_TEST's
  rename law updated to guard the new name.

## 3. Assets (CC0, vendored, manifest recorded)
- [x] Kenney Space Shooter Redux (OGA mirror): enemy hulls, 12 player
  ships, laser bolts, shield bubble animation, fire animation frames,
  speed line, power-up icons.
- [x] Kenney Space Shooter Extension (OGA): 4 more player hulls (7-skin
  wardrobe), the bomb missile + its loot icon.
- [x] Kenney Particle Pack (kenney.nl): flare/spark/smoke/star glow
  textures — the tintable workhorses behind every code VFX.
- [x] Deterministic recolors: yellow beam (hue-rotated green bolt), white
  thunder bolt (desaturated blue bolt).
- [x] Old game leftovers gone: `block.png`, old `ship.png` deleted (no
  obstacles in this game, no code-drawn ships).

## 4. Audio (tools/v024_sfx.py, deterministic, re-runnable)
- [x] dash_beam / dash_laser / dash_thunder / dash_bomb / dash_boom /
  dash_boom_small / dash_boom_big / dash_coin / dash_pick / dash_weapon /
  dash_shield / dash_shield_hit / dash_hit / dash_heart / dash_upgrade /
  dash_over / dash_start / dash_swap / dash_alert — every voice has a sub
  body + an edge + a tail (the "realistic" ask).
- [x] dash_theme.wav — 32s deep-space pad loop (Am F C G, sub + detuned
  pad + wash + second-pass arp), seamless crossfade seam.

## 5. The game (game/games/lanes/lanes.gd — full rewrite)
- [x] 5 lanes, alpha guide lines, portrait FHD, banner-safe bottom.
- [x] Controls: edge taps move one lane (smooth tween + bank tilt + wall
  block); middle-zone press = fire (hold AND rapid taps); multi-touch
  (move finger + fire finger at once).
- [x] The shot-floor rate limiter: `max(0.030, 1/fps)` — probed.
- [x] Enemies: grunt / grunt2 / runner / shooter / splitter (dies into 2) /
  tank / shielded (bubble) / shatter-carrier (1-3 orbiting invulnerable
  shards, gap faces the player at spawn) + RARE elites: ufo shotgun spread,
  ufo double shotgun, ufo power elite (dash_alert + they hit HARD).
- [x] Enemy fire: red bolts down-lane; shooter ratio scales with tier.
- [x] Dynamic difficulty from TOTAL KILLS in tiers (spawn interval, top
  speed, shooter ratio, elite odds, HP scale).
- [x] Kill payouts: +nn floating score per ship, score by ship class.
- [x] Loot from wrecks only: coins (1 per 5-10 kills from last coin),
  power points, shield items (shop-gated), weapon items laser/thunder/bomb
  (shop-gated).
- [x] Hearts: 3 to start, +1 per 1000 score crossing, wreck = -500 score +
  1 heart, last-heart death ends the run.
- [x] Power ladders per weapon: 0/1/3/6/10/15/20; death = exactly 3 rungs
  down the current weapon.
- [x] Weapons: yellow beams (upgrades add beams), red laser (piercing
  continuous, 2s live / 0.5s cd), thunder (chain strikes, 5s live / 2s cd,
  upgrade = longer chain), bomb launcher (radius blast, single shots 2s cd,
  upgrade = bigger + stronger).
- [x] Shield power: 3 levels, alpha aura (deeper = stronger), eats one hit.
- [x] Shop: 7 ship skins, red laser / thunder / bomb launcher purchases,
  shield powerup purchase, 3 spaces (blue default / green / yellow), CLOSE.
  No optionals menu anywhere — shop then "tap anywhere to start".
- [x] VFX pass: parallax starfield + nebula shader bg (3 space palettes),
  additive glow layer, engine flame animation, smoke/spark particles,
  explosion flashes + shockwave rings, muzzle flashes, screen shake,
  +nn popups, lane guide alpha, hit flashes.
- [x] Round fee 20 (registry fee), coin_div 20 (score/20 = bonus coins).
- [x] Thumbnail: real-asset posed scene (thumb_composer spec), guide
  (desc + controls) rewritten.

## 6. Tests (the contract)
- [x] flow_test: picks-no-soon law (the bug), Space Dash rename law,
  registry sanity (fee 20 / div 20 / shop true / 7 skins / 3 spaces),
  soon-geometry untouched.
- [x] NEW dash_probe.tscn — headless drive: lane moves + wall block,
  shot floor (no 2 shots one frame, macro capped, human taps all fire),
  beam upgrade beams, laser pierce + cooldown law, thunder chain + cooldown
  law, bomb radius + cooldown law, kill score + +nn, coin every 5-10 from
  last coin, loot drop gating (weapons/shield need the shop unlock),
  power ladder + death drop of 3 rungs, hearts (+1 per 1000, -500 wreck,
  last-heart end), splitter splits, shatter gap faces the player, kill-tier
  director climbs, shop buys.
- [x] Xvfb QA screenshots: menu -> shop -> run frames (beams, laser,
  thunder, bombs, elites, shatter carrier), both a blue and a green space.

## 7. The same-version patch (owner verdict: ZERO bugs — keep the version)
- [x] Shop re-priced "for real": skins 1200-5500, weapons 2500-4500,
  shield 3000, spaces 1500/2000 (price-0 defaults stay 0).
- [x] Score bonus slowed: coin_div 20 -> 50 (score/50 at run end).
- [x] FUTURE_GAMES.md sixth dump: klickety-like, tetris-like,
  snakes-and-ladders, heavy-weapon-like, zuma-like, plants-vs-zombies-like,
  jigsaw-puzzle.
- [x] flow_test laws: /50 + the >=1200 price floor (reads lanes.gd's real
  constants). Same version, same codes (0.2.4 / 30330-30332).
