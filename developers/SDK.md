# SDK.md — THE GOGABOX SDK

One API. Every game. Four transports; the developer's code never changes.

| where the game runs | what serves the calls |
|---|---|
| **EMBEDDED** — a `.pck` package inside the box | the box's own `GOGA` autoload (the binary IS the SDK — the unified-libs decision) |
| **STANDALONE** — the game's own Godot export (the Steam model) | the running box's SDK BRIDGE over `127.0.0.1:31442` (newline-delimited JSON) |
| **NATIVE** — a non-Godot game (a `.exe`, an `.so`) | the same bridge through `sdk/native/goga_sdk.h` (pure C ABI) |
| **WEB** — an HTML5 game in the in-app WebView | the `window.GOGA.*` JavascriptInterface bridge (Android) |

## The doors (the complete developer contract)

```gdscript
# the Godot plugin: sdk/godot/gogabox_sdk/ - add as an autoload named GogaSdk
GogaSdk.coins() -> int                  # the player's GOGACoins (THE ONE WALLET)
GogaSdk.spend(10) -> bool               # true when the box ledger accepted it
GogaSdk.earn(5)                         # reward the player
GogaSdk.save_write("save", txt)         # THE PORTABLE SAVE LAW
GogaSdk.save_read("save") -> String     # (empty when unset)
GogaSdk.toast("hello")                  # a note in the box's top-level layer
GogaSdk.is_box() -> bool                # true when embedded inside the box
GogaSdk.wire_ok() -> bool               # standalone: the box is reachable
```

The embedded transport adds the package-level doors (games inside the box
use these through the box's `GOGA` autoload directly):

```gdscript
GOGA.my_id() -> String                  # the short game_id this run serves
GOGA.my_root() -> String                # the installed package root on disk
GOGA.data_read(rel) -> String           # a data/ file (the modding door)
GOGA.data_json(rel) -> Dictionary       # a data/ JSON ({} when absent)
GOGA.data_path(rel) -> String           # the abs path (file tools)
GOGA.visual_override(name) -> String    # a data/visuals/assets file or ""
GOGA.save_write(rel, txt) -> bool       # into the package's save/
GOGA.save_read(rel) -> String
```

The native ABI (C): `goga_connect / goga_coins_balance / goga_coins_spend /
goga_coins_earn / goga_save_write / goga_save_read / goga_toast /
goga_disconnect` — see `sdk/native/goga_sdk.h`, the reference client
`sdk/native/goga_sdk.c` builds clean with `-Wall -Wextra`.

## The honesty law

No box running (standalone/native)? Every call answers truthfully —
`false`, `0`, `""` — within the 2.5s deadline. Never a fake success,
never an infinite hang. A standalone game that REQUIRES the box (the
Steam model) checks `GogaSdk.wire_ok()` at boot and shows its own
"launch GOGABox first" seat. The box never launches a game by force.

## Where the saves live

| seat | the folder |
|---|---|
| embedded packages | `<package root>/save/` = `GOGAs/games/<pkg id>/save/` |
| standalone / native clients | `GOGAs/libs/clients/<client id>/` |
| web games | the bridge stores under the client's folder |

Both sit inside the GOGAs tree — the folder a player can carry, back up,
and delete with the game. Nothing sprawls into app-data.

## The wire (for direct implementations)

```
connect 127.0.0.1:31442
-> {"op":"hello","client":"<id>","proto":1}\n
<- {"ok":true,"box":"<version>","proto":1}\n
-> {"op":"coins.balance"}\n                <- {"ok":true,"coins":<n>}\n
-> {"op":"coins.spend","n":<n>}\n          <- {"ok":true|false}\n
-> {"op":"coins.earn","n":<n>}\n           <- {"ok":true}\n
-> {"op":"save.write","key":"<k>","data":"<s>"}\n  <- {"ok":true}\n
-> {"op":"save.read","key":"<k>"}\n        <- {"ok":true,"data":"<s>"}\n
-> {"op":"toast","msg":"<s>"}\n            <- {"ok":true}\n
```

One request line, one answer line, UTF-8. The box serves this ALWAYS
(even from the paused menu) on `127.0.0.1` only.
