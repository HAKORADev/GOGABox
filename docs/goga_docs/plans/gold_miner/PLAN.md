# GOLD MINER — build plan (v040-15)

Working subfolder for the game (the owner's tracking law). Progress lives in
PROGRESS.md next to this file. The GDD (owner laws) is
`docs/goga_docs/gogames_ideas/gold_miner.md`.

v040-15 BUNDLES the v040-14 fix list (the owner tests both at once): those
fixes are already IN the base (9b08480) — v040-15 sits on top and ships the
whole thing. The version number wears 0.4.0-15 / code base 31250 in BOTH
spots (the VERSION LAW the owner pinned at v040-14).

## Pipeline

1. **STUDY** (done) — gamesnacks goldminertom mirrored whole to
   `study_locker/gamesnacks/goldminertom/` (c2runtime + data.js + 98 images
   + 18 sound pairs); every sheet montaged and EYED (the vision law); the
   object inventory + claw atlas decoded (GDD §4).
2. **FORGE ART** — `tools/v0415_miner_art.py`: cuts + code-modifies the
   miner rig parts, the claw (open/closed), the claw+item reeling cells,
   g1-4 golds, r1/r2/rock, the bomb, the explosion frames, the dust puff,
   the ground stack (bgtiles + bottomtile + groundtile + gametopbg
   recomposed for portrait), 5 miner skins + 5 vein skins (palette
   re-inks), the intro logo — into `assets/games/goldminer/`.
3. **FORGE AUDIO** — `tools/v0415_miner_sfx.py`: adapts the scraped oggs
   into `assets/audio/sfx/gm_*` (trim/normalize/pitch variants per thing —
   different SFX for the things) + `assets/audio/music/gm_music.ogg`.
4. **GENERATOR** — the ground generator lives IN the game script (pure
   functions, probe-testable): budgets, six profiles, the fairness
   validator (no overlap, all golds reachable, bombs sane).
5. **GAME CODE** — `game/games/goldminer/goldminer.gd` (+ `miner_data.gd`)
   on the GogaGame contract: the swing/throw/reel loop, bombs = lives +
   blast, level clear law, GOGACoin every-50 law with the next-level edge
   case, drag dust trails, hearts/score/coins widgets, the 5+5 shop,
   END in the pause sheet, tap-anywhere intro.
6. **REGISTRY** — graduate the `goldminer` teaser seat (portrait, coin_div
   30, fee 8, shop, banner, achievements, guide); park the NEXT FIVE teasers
   after it (FUTURE_GAMES.md file order law: knife circle, mask rush, stick
   hero, bubble shooter, stack trim).
7. **TEST** — `tests/miner_probe.gd` (generator fairness battery + the
   loop laws + the coin law + the bomb law); `qa_v0415_miner.tscn` (real
   finger rig); flow_test updated (29 playable / 5 teasers / order);
   films + eye passes; the fast-forward pacing sim (the sim-tells-the-design
   law) — the CURVE picks the feel constants.
8. **BOOKKEEPING** — games_done.md marks the last 5 games done; FUTURE_GAMES.md
   wears the graduation marks + the twenty-first dump (brawl-stars-like,
   full orbit); the SOON teasers ride the registry.
9. **SHIP** — version 0.4.0-15 / base+10 in config/projects.json (both
   spots), README, commit + push, CI green.

## Loop laws (design notes to self)

- the claw swing is a sinusoid around the pulley anchor (±72°, ~2.1s);
  state: swing | fly | grab | reel | bank.
- the rope is a LINE (polyline draw) from winch over pulley to claw; the
  claw flies along the CURRENT swing angle (straight ray).
- item hit = circle test against the ray (substepped sweep — the tunneling
  law); grab closes 0.12s; reel speed = weight table; bank at the pulley.
- bombs: touch = life-1 + blast (260px, kills golds/rocks, never the coin);
  shake + explosion frames; 3rd bomb = finish_run.
- level clear = golds_left == 0 (banked OR blasted) → success jingle →
  populate next; rocks fade with the ground.
- GOGACoin: things_banked % 50 == 0 → spawn glowing gold now; if the level
  ended on the same bank → pending coin spawns in the next populate.
- dust: while reeling, spawn darkened dust puffs under the dragged item
  every ~90px of rope travel.
- the generator is PURE (in: level index + rng; out: item list) so the
  probe can assert fairness on hundreds of seeds fast.
