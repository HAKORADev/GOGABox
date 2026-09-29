# POP THE DOTS — the GOGABox game template

A complete, tiny GOGABox game. Two files matter:

- `entry.gd` — the whole game, extends `GameBase` (read the comments)
- `game.json` — the name file the box reads

## Build it

```bash
python3 tools/make_game.py developers/template my_first_game
```

The folder lands in `GOGAs/games/my_first_game/` — start GOGABox and
it is in the feed. (First time on this machine? `./tools/bootstrap.sh`
once, so the pinned Godot toolchain exists.)

## Make it yours

Copy this folder anywhere, rename things, grow the game. When your
folder carries more scripts/assets, `make_game.py` stages them all and
audits every `res://` reference — a missing file aborts the build by
name. Read `../GAMES.md` for the full contract.
