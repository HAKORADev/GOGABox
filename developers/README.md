# Making games for GOGABox

Everything you need is in this folder. The box is Godot-only and
offline-only; a game is a folder you can hand to a friend.

| you want to... | read |
|---|---|
| make a game | [GAMES.md](GAMES.md) — the folder, the entry, the pack, the mystery/reveal vocabulary |
| use GOGACoins / achievements / saves in it | [GOGACOINS.md](GOGACOINS.md) |
| make it playable on a LAN | [LAN.md](LAN.md) |
| mod an existing game (or make yours moddable) | [MODDING.md](MODDING.md) |

## Start from the template

`template/` is a complete, tiny, working game — script, name file and
all. Build it and it lands in your box:

```bash
python3 tools/make_game.py developers/template my_first_game
```

Start GOGABox: the game is in the feed. Then make it yours.

## The whole contract in one screen

```
GOGAs/games/<game-id>/
├── game.json     the name file: title, os, age, genres, fee, price...
├── game.pck      the game - a Godot pack holding your script + assets
└── thumb.png     the tile picture in the feed
```

- The folder name is the game's id. The name lives in `game.json`.
- `game.pck` is THE one entry — every game's pack wears this name.
- The box reads two files, launches one, and never looks at anything else
  in the folder. No validation, no required subfolders, no approval.
- A game that ignores the coins, the achievements and the LAN is just as
  welcome as one that uses them all.

## The tools

- `tools/make_game.py <folder> [--id <game-id>]` — stages a Godot
  project around your game (the box's base classes at their real
  paths), audits every referenced asset, imports, exports the one
  `game.pck`, and writes the folder into `GOGAs/games/`.
- `tools/test.sh gogabox` — the box's battery; it boots every game
  folder in the tree, so a game that survives it boots on a player's
  device.

## The settings seat

`GOGAs/box.json` (beside the games) is the player-facing settings file:
`hide_mature` keeps +12 games out of the feed (default true),
`dev_cheats` keeps the dev menu locked (default false),
`starter_game` names the free starter game (empty = the box picks the
alphabetically-first folder). A game developer reads it the same way a
player does — it is one honest file, documented in `GOGAs/README.txt`.
