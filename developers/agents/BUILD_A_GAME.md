# PLAYBOOK: build a GOGABox game from zero

You are an agent building a new game for the platform. The whole loop is
local until the publish step — nothing touches the network.

1. **The scaffold.** A Godot 4.7 project. ONE game script
   (`mygame.gd`, extends the box's `GogaGame` — read
   `archive/games_v042/scripts/` for 31 working examples, every one
   code-drawn and self-contained). The game reads NOTHING from the box
   by hardcoded path: its entry comes from its index, its tunables from
   `data/logic/*.json` through `GOGA.data_json` (with the packed
   fallback so the game still runs when the file is gone), its saves
   through `GOGA.save_write/save_read`, its coins through the SDK doors.
2. **The data minimums, live from day one.** `data/logic/tuning.json`
   (real tables the code reads), `data/audio/sfx/` + `music/` (real
   files), `data/visuals/shaders/` + `assets/` (a real shader + the
   override-able art the game loads FIRST through
   `GOGA.visual_override`). The validator refuses empty folders — make
   the files real, not placeholders.
3. **The manifest.** `index/index.json` per PACKAGING.md — every field,
   the honest age + content tags, the long id with YOUR github name:
   `gogabox_github-<you>_<ns>.<name>.<n>_hobbyist` (publishing upgrades
   the tier later, PUBLISHING.md).
4. **The package.** `game/` builds through the packaging rig
   (tools/v043_package.py — copy the pilot shape). Assemble
   `discover/` (page.json + the thumb), `save/`.
5. **Validate + test.** Import the folder into the box (the discover
   feed > IMPORT PACKAGE, or drop it in `GOGAs/games/`), press play,
   finish a run, check the coins landed, check the save file appeared
   in the package's `save/`. The local flow IS the remote flow: if it
   plays from a folder import, it will play from a download.
6. **The eye pass.** Screenshot or run it under Xvfb; a game that only
   "compiles" is not done. The box's own rig proves boots
   (tests/flow_test.gd) — the game must boot there too once packaged.
