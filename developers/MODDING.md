# MODDING.md — mod a game without touching its pack

Every GOGABox game is a plain folder. Around the pack (`game.pck`) sits
a small file system the box never checks and the game itself reads when
it wants to. That is the modding surface:

```
GOGAs/games/<game-id>/
├── game.json                 <- edit: rename, re-price, re-age the game
├── game.pck                  <- the packed game (leave it alone)
├── thumb.png                 <- swap: any 3:2 image (960x640 is the norm)
├── data/                     <- the modding seat - the game reads it live
│   ├── logic/tuning.json     <- whatever files the game documents
│   └── visuals/assets/
│       └── board.png         <- replacement art, the game's own names
└── save/                     <- the game's own saves (its business)
```

## 1. Edit game.json

The name file is human JSON. Change `title`, `tag`, `desc`, the genres,
the entry `fee`, the shop `price` — save the file, restart the box (or
just return to it), the feed shows your version. Nothing is signed,
nothing is validated: the game is yours now.

## 2. Swap the thumbnail

`thumb.png` is the tile art. Replace it with any image (3:2 reads best)
under the same name. The box reads it from disk on the next boot.

## 3. The data seat — mods the game obeys

The SDK door behind this (what the game's code calls):

```gdscript
GOGA.data_json("logic/tuning.json")   # {} when the file is absent/broken
GOGA.data_read("logic/board.txt")     # "" when absent
GOGA.visual_override("board.png")     # a path, or "" when you didn't
```

- The game ships its own packed defaults; a file you place under
  `data/` WINS over the packed one.
- A broken or missing file is never a crash — the game falls back to
  its defaults. Worst case a mod is simply ignored.
- `data/visuals/assets/<name>` is the art-override seat: whatever file
  names the game asks for by `visual_override()`. The names a game
  accepts are its own - a moddable game documents them (the shipped
  games' tuning files live under the same `data/` names in their
  sources; the template shows the reading side).

## 4. The save seat

`save/` belongs to the game's portable save door
(`GOGA.save_json_write` / `save_json_read`). It moves WITH the folder
when you copy or share it. Delete it to reset that game's own state.
(The box-level progress — coins, bests, trophies — lives in the box's
own save file, not here.)

## 5. Remix rules of the road

- Mod YOUR folders; a game folder someone else made may carry their
  own terms (see AGREEMENT.md for the plain repo terms).
- The box never validates a mod: a broken `data/` file can only be
  ignored, a broken `game.json` makes the tile fall back to the folder
  name and the default tags — the game still launches.
- There is no approval step and no store. Sharing a mod = sharing the
  folder.
