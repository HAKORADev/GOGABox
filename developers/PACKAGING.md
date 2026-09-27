# PACKAGING.md — the GOGA package contract

A GOGA package is a FOLDER. That is the whole trick: no installer, no
proprietary blob, no database — a folder a human can read, an agent can
write, and the box can validate. The zip shapes (.goga / .gogas) are that
same folder, zipped, for easy sharing.

## The folder

```
<package root>/
  index/
    index.json          # THE MANIFEST - everything the box reads
  game/                 # THE RUNNABLE
    android/goga.pck    #   godot packages: one pck per platform (or one shared)
    pc/goga.pck         #   native: .exe / .so · web: entry .html + files
  discover/
    page.json           # the store page material
    media/thumb.png     # the thumbnail (the index points at it)
  data/                 # THE OPEN DATA LAW - plain moddable files (STRICT)
    logic/*.json        #   the game's tuning tables (plain JSON!)
    audio/sfx/          #   at least one real file each:
    audio/music/        #   logic, sfx, music, shaders, assets
    audio/voice/        #   (optional - recognized, must be populated)
    visuals/assets/     #   (moddable images - the game loads them FIRST)
    visuals/shaders/    #   (replaceable .gdshader files)
    visuals/characters/ #   (optional)
    visuals/vfx/        #   (optional)
  save/                 # THE PORTABLE SAVE LAW - the folder is the contract
  src/                  # optional, PREACHED: share your source (remix culture)
```

## index.json — every field

```jsonc
{
  "schema": 1,
  "id": "gogabox_github-<user>_<ns>.<name>.<n>_<tier>",
        // THE LONG ID: the publishing identity. tier = official |
        // community | hobbyist. The installed folder IS renamed to it.
  "game_id": "mygame",  // THE SHORT ID: the box's internal key (letters,
                        // digits, underscore). One installed box seat.
  "title": "MY GAME",
  "tag": "one sharp line",
  "version": "1.0.0",   // numeric dotted - the update law compares this
  "age": 7,             // THE AGE LADDER: 3/5/7/9/12/16/18/21 (Meta.AGES)
  "content": [],        // horror/psycho/gore/porn/gambling/politics/
                        // illegal_trading/nudity - tag honestly
  "genres": {"main": ["arcade"], "sub": ["retro"]},  // <= 3 each
  "os": ["android", "pc"],   // platform exclusives = one entry
  "runs": {                    // THE INDEX DECIDES (per-platform builds)
    "android": {"kind": "godot_embedded", "pck": "game/android/goga.pck",
                "script": "res://game/games/mygame/mygame.gd",
                "renderer": "mobile"},
    "pc":      {"kind": "godot_embedded", "pck": "game/pc/goga.pck",
                "script": "res://game/games/mygame/mygame.gd",
                "renderer": "forward_plus"}
  },
  "thumb": "discover/media/thumb.png",
  "desc": "the discover page reads this",
  "fee": 0, "price": 0,        // the GOGACoins economy (0 = free)
  "coin_div": 10,              // the run-end bonus divisor
  "charges": {"per_round": 2, "capacity": 10, "regen_minutes": 5},  // optional
  "daily_rounds": 6, "daily_minutes": 15,                           // optional
  "lan": {"players": 4, "platforms": ["android", "pc"], "cross": true}, // opt
  "controls": ["touch lines..."], "controls_pc": ["kb/mouse lines..."],
  "ach": [ {"id": "...", "title": "...", "desc": "...", "tier": 1,
            "rule": {"k": "score", "v": 30}} ],
  "updated": "2026-09-27",
  "versions_count": 1,
  "size_bytes": 1234567,
  "files": [ {"path": "game/pc/goga.pck"}, {"path": "game/android/goga.pck"},
             ... ]           // THE FILES MANIFEST - the discover downloader
                             // fetches EVERYTHING through this list; a file
                             // missing here never arrives, and the strict
                             // validator then refuses the install
}
```

`kind` values: `godot_embedded` (a .pck loaded in-box), `native`
(a Windows `.exe` child process / an Android `.so` in-process —
NATIVE_GAMES.md), `web` (an `.html` entry — WEB_GAMES.md).

## The strict validator (what refuses, by name)

The box refuses an import/download with a NAMED error for each miss:

- `index/index.json` missing / not a JSON object / missing any of
  `id, game_id, title, version, age, genres, os, runs, thumb`
- the `id` does not wear the long-id scheme, or the tier is unknown
- a `runs.<plat>` entry points at a pck/bin/html that does not exist,
  or wears an unknown `kind`
- `data/logic/`, `data/audio/sfx/`, `data/audio/music/`,
  `data/visuals/shaders/`, `data/visuals/assets/` missing OR EMPTY
  (at least one real file each — the five minimums; voice/characters/vfx
  are optional but must be populated if present)
- `save/` missing (the folder is the contract)
- `discover/page.json` missing
- the index `thumb` path does not resolve inside the package

Fix the named thing, re-zip, done.

## The shapes the importer eats

| shape | what it is |
|---|---|
| a folder root | a folder carrying `index/index.json` |
| a parent of roots | a folder of folders each carrying one |
| `something.goga` | a zip with ONE root inside |
| `something.gogas` | a zip with MANY roots inside |

THE RENAME LAW: an installed root is renamed to its long `id` — the
folder name it arrived with means nothing. THE UPDATE LAW: same version
skips (with the why), an older version refuses, a newer version replaces.
THE COLLISION LAW: two packages claiming the same short `game_id` — the
first installed wins.

Zip note: archives carry files, not empty folders — a fresh package's
empty `save/` re-seats in transit (the transport-artifact law). Your
`data/` minimums must be REAL FILES; they survive zips fine.

## The pck law (godot_embedded)

The box loads your pck with `load_resource_pack(path, false)` —
`replace_files = false`, ALWAYS. The box's own files can never be
shadowed by a package. Consequence: build your pck from a project that
stages the box core at the SAME `res://game/core/` paths (your compiled
base-class references then resolve to the box's real classes at runtime)
and names YOUR files under your own paths. The reference rig:
`tools/v043_package.py` + `packaging/` (the four official pilots live
there — read them as working examples).

## Renderers

The box runs `gl_compatibility` (it must: 32-bit Windows, ancient GPUs,
a phone spread over years). An embedded game SHARES the host renderer —
that is the honest engineering (a pck cannot re-boot the engine). A game
that needs `forward_plus` ships the NATIVE kind: its own export, its own
renderer, its own process — the box launches it and it talks back over
the SDK (NATIVE_GAMES.md). The index's `runs.<plat>.renderer` records
the preference either way.
