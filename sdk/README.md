# THE GOGABOX SDK — one API, two transports

Every game talks to the platform the same way. Where the game RUNS picks
the transport; the developer's code never changes.

| where the game runs | what serves the calls |
|---|---|
| **EMBEDDED** — a `.pck` package inside the box | the box's own `GOGA` autoload (the binary IS the SDK — the unified-libs decision) |
| **STANDALONE** — the game's own Godot export (the Steam model) | the running box's SDK BRIDGE over `127.0.0.1:31442` |
| **NATIVE** — a non-Godot game (a `.exe`, an `.so`) | the same bridge through `sdk/native/goga_sdk.h` (C ABI) |
| **WEB** — an HTML5 game in the in-app WebView | the `window.GOGA.*` JavascriptInterface bridge (Android) |

## The doors (the whole contract)

```gdscript
# the Godot plugin (sdk/godot/gogabox_sdk/) - add as an autoload named GogaSdk
GogaSdk.coins() -> int            # the player's GOGACoins (the ONE wallet)
GogaSdk.spend(10) -> bool         # true when the box ledger accepted it
GogaSdk.earn(5)                   # reward the player
GogaSdk.save_write("save", txt)   # THE PORTABLE SAVE LAW: lands inside
GogaSdk.save_read("save") -> String   #   the GOGAs tree, never app-data
GogaSdk.toast("hello")            # a note in the box's top-level layer
GogaSdk.is_box() -> bool          # true when embedded inside the box
```

The native ABI carries the same doors over C:
`goga_connect / goga_coins_balance / goga_coins_spend / goga_coins_earn /
goga_save_write / goga_save_read / goga_toast / goga_disconnect`.

## The honesty seat

No box running (standalone/native)? Every call answers honestly — `false`,
`0`, `""` — never a hang, never a fake. A standalone game that REQUIRES the
box (the Steam model) checks `GogaSdk.wire_ok()` at boot and shows its own
"launch GOGABox first" seat. The box never launches a game by force.

## Where the saves live

- embedded packages: `<package root>/save/` (inside `GOGAs/games/<pkg id>/`)
- standalone/native clients: `GOGAs/libs/clients/<client id>/`
- web games: the bridge stores under the client's folder as well

Both sit inside the GOGAs tree — the folder a player can carry, back up,
and delete with the game. Nothing sprawls into app-data.
