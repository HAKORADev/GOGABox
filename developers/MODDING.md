# MODDING.md — the open-data law, worked for real

Every GOGA package carries its guts in plain files. This file is written
aggressive ON PURPOSE (the owner's order): modding here means REACH IN
AND CHANGE THE THING — yours, or someone else's who shipped it open,
locally, on your own box, for your own play. The platform is MIT, the
data is plain, the saves are portable, and nothing is encrypted because
nothing needs to be.

## What is moddable, where

| you want to change | touch |
|---|---|
| how the game BALANCES (speeds, prices, waves, drops) | `data/logic/*.json` — plain tables; a game that reads them obeys your edit |
| how the game SOUNDS | `data/audio/sfx/`, `data/audio/music/`, `data/audio/voice/` |
| how the game LOOKS | `data/visuals/assets/` — the game loads these FIRST (the override door); packed art is only the fallback |
| how the game SHINES | `data/visuals/shaders/*.gdshader` — replaceable |
| WHO the characters are | `data/visuals/characters/` |
| the game's CODE | `src/` when the dev shared it (preached; not guaranteed) |
| ANYTHING in a compiled pck | the pck is a plain Godot pack — the box's own study line (`tools/study/`) extracts `.pck` files; nothing here is obfuscated |

The override door is live code, not decoration: a package game checks
`GOGA.visual_override(...)` FIRST and falls back to its packed art. Drop
a replacement image with the right name, press play, see your art.

## Flavors (the owner's examples, verbatim intent)

"make this horror, add gamble, make it porn, make it for girls, make it
calm" — a flavor is a data-layer edit: swap the palette JSON, the sfx
set, the logic tables' mood numbers, the visuals overrides. A flavor can
be shipped as a plain folder diff against any package's `data/` tree.
The engine does not gate flavors; the AGE + CONTENT tags describe what a
package carries, the box's simplified age door gates only the play
button, and the human decides what runs on their box.

## Localization

`data/logic/strings.json` (or any JSON the game reads) is the string
table when the developer ships one — plain key/value, translate the
values, done. A localization pack is just that file + the optional
audio/visual overrides. Agents: translate the WHOLE table, keep the keys
untouched, and never invent keys the game does not read.

## The aggressive part (read this before you complain anywhere)

- The pck format is Godot's own, unencrypted by choice. Extract it with
  the box's own study tools or any Godot pack extractor. Read the code.
- The saves are plain files in plain folders. Edit them. Carry them to
  another box. Back them up.
- There is no anti-tamper, no signature gate on local files, no
  phone-home, no kill switch, no DRM — the box's only integrity checks
  are the strict validator on IMPORT/DOWNLOAD (structure, not obedience)
  and the sha the index lists (optional, transport honesty).
- A mod that breaks a game breaks YOUR copy. Uninstall, reinstall,
  gone. Nobody else is affected — local edits never climb back into any
  source, repo, or another player's box.

## The line (the only one)

This is a modding chapter, not a piracy chapter: the platform does not
crack, download, or distribute games you have no right to run. What you
do with a game YOU legally hold on YOUR machine is your business; the
platform's tools are neutral and the platform takes no cut, no side and
no liability. See ACKNOWLEDGMENT.md and REPORTING.md for the whole
picture.
