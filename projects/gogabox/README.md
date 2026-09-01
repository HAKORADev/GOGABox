# GOGABox (Godot Game Box)

One Android app, many endless arcade mini-games, one shared engine. Ported
from [Python_Game_Box_PGB](https://github.com/HAKORADev/Python_Game_Box_PGB)
v1.3.8 and grown into a proper Godot 4.7 game box: GOGACoin economy, game
unlocks, per-game progress/achievements, skins shop, Unity Ads (real ads).

**Read `Docs/plans/BOX_CORE_DESIGN.md` before touching anything** — it is the
contract that makes "adding a game = blinking".

## v0.0.1 games
| game | how it plays | fee |
|---|---|---|
| Snake | swipe, eat, grab coins, skin shop | 10 |
| Pong Rally | endless survival rally vs ramping AI | 8 |
| Space Dash | 5-lane space shooter: kills are score, 4 weapons, loot from wrecks, hearts, shop with skins/weapons/spaces (was Geometry Flash, then Space Dodge) | 20 |
| Fruit Slasher | landscape swipe slasher, combos | 15 |
| Snowy Tower | hop upward forever | 12 |
| 2048 | swipe merge puzzle | 15 |

8 more PGB ports sit behind SOON tiles (roadmap in `Docs/`).

## Layout
- `game/core/` — the engine: Box store, Jukebox audio, GameReg registry,
  Arc UI kit, TouchKit gestures, GogaGame base, GameHost runner.
- `game/games/` — one file per game, extending GogaGame.
- `game/menu/` — box chrome (grid, game pages, settings, unlock sheets).
- `Docs/` — plans/ + ideas/: design docs and brainstorms (not shipped in APK).
- `tools/derive_assets.py` — deterministic CC0 asset pipeline (PIL art,
  Kenney fonts, thumbnails, audio copies + synth sfx).

## Checks
    ./tools/test.sh gogabox        # from repo root
