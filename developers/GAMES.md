# GAMES.md — the folder, the entry, the pack

A GOGABox game is a Godot 4 game that runs INSIDE the box: your script is
instantiated by the box's host, draws on the box's canvas, and inherits a
complete set of furniture (touch controls, orientation handling, the
pause sheet, the game-over sheet, the scale rule) from `GameBase`.

## 1. The folder

```
GOGAs/games/<game-id>/
├── game.json     the name file
├── game.pck      the pack (your script + your assets, imported)
└── thumb.png     the feed tile (3:2, like 960x640)
```

The folder name IS the game's id — keep it lowercase, letters/digits/
underscores (`domino`, `fruit_slasher`). The display name lives in
`game.json`, so a folder can stay boring and the box can still read
"FRUIT SLASHER".

## 2. game.json — the name file

The box's whole vocabulary, flat and human-editable:

```json
{
  "title": "FRUIT SLASHER",
  "tag": "slice the fruit, skip the bombs",
  "desc": "one line shown on the game page",
  "os": ["android", "pc"],
  "age": 7,
  "content": [],
  "genres": { "main": ["arcade"], "sub": ["reflex"] },
  "fee": 0,
  "price": 0,
  "controls": ["swipe to slice"],
  "controls_pc": ["hold the mouse button and swipe"],
  "thumb": "thumb.png",
  "script": "res://game/games/fruit_slasher/fruit_slasher.gd"
}
```

- `os` — `["android"]`, `["pc"]` or both. A game missing this device
  shows an honest dead **PHONE ONLY** / **PC ONLY** button instead of a
  play button that does nothing.
- `age` — the age-door tag (3..21). The profile's age number is the only
  reader: an underage profile sees the play button grayed with "you must
  be +nn". Browsing and owning are never age-gated.
- `content` — optional content tags (`horror`, `gore`, `porn`, `gambling`
  ...) that ride the search filters.
- `fee` — GOGACoins per round (0 = free). `price` — the shop price
  (0 = free to own). `shop: true` lets the player buy it from the page.
- `script` — the res:// path of your main script INSIDE the pack. Every
  game the box ships uses its natural path; a game that prefers the
  default can skip the key (the box then looks for `res://entry.gd`).

## 3. The script

Your main script extends `GameBase` (the box's class, available because
the packer stages the box core beside your code). The shape:

```gdscript
extends GameBase
# my_game.gd - the whole game

const A := "res://assets/games/my_game/"   # your assets, any layout you like

func _goga_setup() -> void:
        # build your world here - runs once at boot
        pass

func _goga_tick(delta: float) -> void:
        # your frame update
        pass
```

`GameBase` hands you: the touch kit (taps, drags, holds), the HUD
helpers, the score/coins doors (`set_score`, `add_run_coins`,
`finish_run(score)`), the pause/back sheet, the orientation ask, and the
scale rule (portrait, landscape or both). The shipped games under
`GOGAs/games/` are the living reference — `rally/` (pong.gd) is the
smallest complete one.

## 4. The pack

Run the packer:

```bash
python3 tools/v044_package.py my_game
```

It stages a Godot project around your files (the box's base classes at
their real paths — that is what lets a pack extend them), imports it,
exports ONE `game.pck`, and writes `game.json` + `thumb.png` beside it.
One pack runs on BOTH platforms — a pure-GDScript 2D pack is
platform-neutral.

The packer audits every referenced path (your script's `res://` literals
must exist — missing art or audio aborts the build by name) and carries
your music + sfx in automatically.

## 5. Ship it

The folder IS the distribution. Zip it, drop it on a drive, send it to a
friend — a player copies it into `GOGAs/games/` and starts the box. That
is the whole platform.
