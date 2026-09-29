# Making games for GOGABox

Everything you need is in this folder. The box is Godot-only and
offline-only; a game is a folder you can hand to a friend.

| you want to... | read |
|---|---|
| make a game | [GAMES.md](GAMES.md) — the folder, the entry, the pack |
| use GOGACoins / achievements / saves in it | [GOGACOINS.md](GOGACOINS.md) |
| make it playable on a LAN | [LAN.md](LAN.md) |

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

- `tools/v044_package.py` — stages a Godot project around your game
  (the box's base classes at their real paths), imports, exports the one
  `game.pck`, and writes `game.json` from your registry entry.
- `tools/test.sh gogabox` — the box's battery; it boots every game folder
  in the tree, so a game that survives it boots on a player's device.
