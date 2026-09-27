# WEB_GAMES.md — HTML5 in the box

The box runs web games INSIDE the app — no pop-up browser tabs, no
redirection. Two families, one door:

1. **bare web games** — a real `.html` entry (three.js, phaser, DOM
   games, anything a browser plays),
2. **Godot HTML5 exports** — a Godot game exported for web (the
   `index.html` + `.wasm` + `.pck` bundle), running in the same surface.

The tech is the device's own WebView hosted in-app (Android's
`android.webkit.WebView` — the system browser engine, no browser chrome,
no tab, no redirection). On PC the box carries the WebView2 slot: the
web runner is built to light it up when the WebView2 extension lands,
and until then it refuses with the honest why instead of pretending.

## The package shape

```jsonc
// inside index.json - "runs"
"runs": {
  "android": {"kind": "web", "entry": "game/web/index.html"},
  "pc":      {"kind": "web", "entry": "game/web/index.html"}
}
```

```
game/web/
  index.html        # THE ENTRY - the validator refuses if missing
  ...               # every other file the game needs, listed in the manifest
```

Everything ships as plain files in the package; the strict validator's
data/ minimums still hold (see PACKAGING.md).

## The SDK bridge — window.GOGA.*

The WebView carries a JavascriptInterface named `GOGA` — the SAME SDK
vocabulary as everyone else, no server, no keys:

```js
GOGA.coins()                    // the player's GOGACoins (a JSON answer)
GOGA.spend(10)                  // true when the box ledger accepted it
GOGA.earn(5)
GOGA.saveWrite("save", txt)     // THE PORTABLE SAVE LAW (lands in the
GOGA.saveRead("save")           //   GOGAs tree, never app-data)
GOGA.toast("hello")
```

The LAN seat for web games rides the same bridge: the box hosts the
session and the web game speaks the box's own LAN vocabulary through
`GOGA.*` — the logic is the box's ported LAN (the same seat/room model
the native games play), not a second implementation drifting apart.

## The laws at this layer

- NO pop-up tabs, NO external browser redirection, NO full browser
  install — the in-app surface only.
- The bridge is the ONLY door between the web game and the box — a web
  game cannot reach the filesystem beyond its own package's seats.
- The save law is absolute: saves land in the GOGAs tree, carried with
  the package.
