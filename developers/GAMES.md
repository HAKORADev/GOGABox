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
  "orientation": "portrait",
  "age": 7,
  "content": [],
  "genres": { "main": ["arcade"], "sub": ["reflex"] },
  "fee": 0,
  "price": 0,
  "shop": false,
  "controls": ["swipe to slice"],
  "controls_pc": ["hold the mouse button and swipe"],
  "thumb": "thumb.png",
  "script": "res://game/games/fruit_slasher/fruit_slasher.gd"
}
```

- `os` — `["android"]`, `["pc"]` or both (the default). A game missing
  this device shows an honest dead **PHONE ONLY** / **PC ONLY** button
  instead of a play button that does nothing. One pure-GDScript pack
  runs on both platforms unchanged — write the tag only when a game
  truly cannot run somewhere.
- `orientation` — `"portrait"`, `"landscape"`, or `"auto"` (the window's
  shape at launch decides; the sensor then locks it for the session).
- `age` — the age-door tag (3, 5, 7, 9, 12, 16, 18, 21). The profile's
  age number is the only reader: an underage profile sees the play
  button grayed with "you must be +nn". Browsing and owning are never
  age-gated. NOTE: while the box's `hide_mature` setting rules (the
  default), games rated +12 and up are hidden from the feed entirely —
  see the box.json section in this folder's README.
- `content` — optional content tags (`horror`, `gore`, `porn`,
  `gambling`, `politics`, `psycho`, `nudity`, `illegal`) that ride the
  search filters and fold away with the mature view.
- `fee` — GOGACoins per round (0 = free). `price` — the shop price
  (0 = free to own). `shop: true` lets the player buy it from the page.
- `script` — the res:// path of your main script INSIDE the pack. The
  default is `res://game/games/<id>/entry.gd`.

### The reveal vocabulary — mystery, orders, unlock conditions

A game does not have to appear the moment its folder lands. The
`reveal` block turns it into a mystery tile that resolves when the
player does something:

```json
"reveal": {
  "kind": "orders",
  "appear_after": 3,
  "needs_games": 5,
  "orders": [
    { "type": "plays",    "game": "xo",     "count": 3 },
    { "type": "earn_in",  "game": "snake",  "amount": 30 },
    { "type": "spend_in", "game": "rally",  "amount": 20 },
    { "type": "beat_best","game": "merge" },
    { "type": "ach_exact","game": "bovo",   "ach": "wins_t1" },
    { "type": "ach_in",   "game": "ludo",   "count": 2 }
  ]
}
```

- `kind` — how the tile appears:
  - `"direct"` — no conditions; it shows as a locked tile right away.
  - `"orders"` — a MYSTERY (black tile) until every order line is done.
  - `"inbox"` — a MYSTERY until the box has `minutes` of total play time.
  - `"real"` — a MYSTERY on a countdown: `hours` after the box first
    saw it, it reveals (the mystery page shows the clock).
  - `"chain"` — reveals only when the previous game in the feed is owned
    and played (the old ladder; rare now).
- `appear_after` — owned games needed before the teaser even shows.
- `needs_games` — owned games required to BUY once revealed.
- `orders` — the requirement lines (shown on the mystery page with live
  progress): `plays`, `earn_in`, `spend_in`, `beat_best`, `ach_in`,
  `ach_exact` — each names a `game` (another installed game's id) and
  its `count`/`amount`/`ach`.

The box computes everything live from its own stats — your game ships
the declarative block and the box does the watching. Games can also
declare `charge_unlock` (GOGACharges poured before the buy),
`hours`/`blocked_hours` (time-of-day windows), `daily_rounds`/
`daily_minutes` (per-day caps) and `charges` (the GOGABattery pool).

## 3. The script

Your main script extends `GameBase` (the box's class, available because
the packer stages the box core beside your code). The shape:

```gdscript
extends GameBase
# my_game.gd - the whole game

func _goga_setup() -> void:
        # build your world here - runs once at boot
        pass

func _goga_tick(delta: float) -> void:
        # your frame update
        pass
```

`GameBase` hands you: the touch kit (`tk.tapped`, `tk.swiped`,
`tk.dragged` — mouse included), the HUD (score + coins), the score and
coin doors (`set_score`, `add_score`, `add_run_coins`, `finish_run`),
the pause/back sheet, the orientation ask, the LAN relay doors (see
LAN.md), and the SDK doors (see GOGACOINS.md).

`developers/template/` is a COMPLETE tiny game built exactly this way —
copy it, rename it, make it yours. It builds and runs out of the box:

```bash
python3 tools/make_game.py developers/template my_first_game
```

## 4. The pack

From any folder shaped like the template (a `game.json`, an `entry.gd`,
your assets):

```bash
python3 tools/make_game.py path/to/your_game [--id your_game_id]
```

The tool stages a Godot project around your files (the box's base
classes at their real paths — that is what lets a pack extend them),
imports it, exports ONE `game.pck`, and writes the folder straight into
`GOGAs/games/<id>/`. One pack runs on BOTH platforms.

The audit walks every `res://` literal in your scripts: a missing art or
audio file aborts the build BY NAME (a pack never ships half-referenced);
box-project files (fonts, shared UI) are carried in automatically.

## 5. Ship it

The folder IS the distribution. Zip it, drop it on a drive, send it to a
friend — a player copies it into `GOGAs/games/` and starts the box. That
is the whole platform.
