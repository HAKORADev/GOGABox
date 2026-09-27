# THE v042 GAME ARCHIVE — the last generation of baked games, whole

v043 THE EMPTY BINARY LAW: GOGABox stopped baking games. The binary ships
as the ENGINE + the store (discover, wallet, LAN, profiles) and every game
arrives as a GOGA package (see `docs/goga_docs/plans/PLAN_v043.md` and the
developers catalog). The owner's order: "save the original current games
in the repo somewhere" — this is the somewhere.

The base state is the exact v042 tree (commit 444c38c9); the pass 2 strip
topped it up with the audio + the probes (see the table).

| folder | what |
|---|---|
| `scripts/<id>/` | the game's `.gd` source (the whole game — these games are code-drawn) |
| `assets/<id>/` | the game's asset folder from `projects/gogabox/assets/games/` |
| `audio/sfx/`, `audio/music/` | the game-owned audio from `projects/gogabox/assets/audio/` (topped up in the v043 pass 2 strip — the first archive pass forgot it; the box-owned keep-set stays in the engine: `ui/`, `notify/`, `jingles/`, `music/box_theme.mp3`, `sfx/{boom,coin,unlock}.ogg`) |
| `thumbs/<id>.png` | the feed thumbnail |
| `registry_entries/<id>.json` | the exact registry dict (revival seed: the v043 package index consumes this shape almost verbatim) |
| `probes/` | the per-game test probes, moved out of `projects/gogabox/tests/` by the pass 2 strip (they reference the deleted baked paths; revived with their games) |

The games: snake, rally, lanes, slasher, hopper, merge, dario, xo, matcher,
invaders, cosmic_spud, pop_siege, geometry, maze, domino, chess, fourline,
bovo, squares, pacman, brickbreaker, jumpcube, ludo, snl, heavywar,
rockbreaker, deathworm, marble, goldminer, towerball, towerdestroyer
+ the SOON teasers (knife, maskrush, stickbridge, bubbleshot, towertrim —
no scripts yet, entries only).

## REVIVAL RECIPE (how any archived game becomes a v043 package)

1. The v043 packaging rig (`packaging/` + `tools/v043_package.py`) stages a
   Godot project per game: the box core at the SAME `res://game/core/` paths
   (so the compiled base class resolves to the box's real class at runtime,
   the pck law), the game script, the game assets namespaced under
   `res://goga/<id>/`.
2. Headless export-pack → `game/android/goga.pck` + `game/pc/goga.pck`.
3. The index: `registry_entries/<id>.json` + the v043 additions (`age`,
   `content`, the package fields) → `index/index.json`.
4. `data/` minimums (logic / audio sfx+music / visuals shaders+assets) +
   `save/` + `discover/` (page.json + media) → the validator passes.
5. The four PILOT ports (rally, slasher, domino, jumpcube) shipped in v043 —
   the rest wait for their porting rounds. Zero code was deleted: every
   game here runs again through the same three steps.
