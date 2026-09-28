# WEB_GAMES.md — HTML5 in the box

The box runs web games INSIDE the app — no pop-up browser tabs, no
redirection. Two families, one door:

1. **bare web games** — a real `.html` entry (three.js, phaser, DOM
   games, anything a browser plays),
2. **Godot HTML5 exports** — a Godot game exported for web (the
   `index.html` + `.wasm` + `.pck` bundle), running in the same surface.

## The seats (how it actually runs, v043 pass 3)

The box is the SERVER and the HOST:

1. **the localhost seat** — the box serves the package's `game/web/`
   over `http://127.0.0.1:<port>/` (GogaWebserve — loopback only, one
   package at a time, torn down when the game closes). Relative paths,
   ES modules, wasm, textures: the whole modern toolkit works, the
   `file://` quirks never happen.
2. **the surface** — Android: the `gogabrowser` plugin hosts the system
   WebView INSIDE the activity (no browser chrome, no tab, no
   redirection — the surface is a FrameLayout overlay over the game
   view). PC: the system's own WebView2 runtime in APP MODE
   (`msedge --app=<url>` / Chrome fallback) — a chromeless window with
   no tabs and no address bar, the same engine WebView2 would embed.
   This is the honest seat until the WebView2 extension lands.
3. **the bridge** — the page includes `sdk/web/goga_bridge.js` (the
   packager stages it next to the entry) and speaks `window.GOGA.*`
   over the box's WebSocket door (`ws://127.0.0.1:31443`). The bridge is
   the SAME vocabulary every transport speaks (embedded doors, the TCP
   bridge, the C ABI). Loopback cleartext is the only wire allowed in
   the clear (Android's network security config names exactly
   127.0.0.1/localhost).

The working pilot: **GOGA ORBIT** (`GOGAs/games/...orbit.005...`) — a
three.js game, vendored library, drag to steer, gold pays through the
bridge, the best run lands in the package's portable save.

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
  goga_bridge.js    # the SDK bridge (stage it from sdk/web/)
  ...               # every other file the game needs, listed in the manifest
```

Everything ships as plain files in the package; the strict validator's
data/ minimums still hold (see PACKAGING.md). If the surface cannot
open (no browser on the PC, the plugin missing on a device), the runner
refuses with the named why — never a silent death.

## The SDK bridge — window.GOGA.*

```js
await GOGA.hello()               // the handshake (also auto-runs on load)
GOGA.coins()            -> n     // THE ONE WALLET (a Promise)
await GOGA.spend(10)             // true when the box ledger accepted it
await GOGA.earn(5)
await GOGA.saveWrite("save", txt)  // THE PORTABLE SAVE LAW (lands in the
GOGA.saveRead("save")              //   GOGAs tree, never app-data)
await GOGA.toast("hello")
GOGA.connected()                 // true once the box answered
```

Every call resolves or REJECTS — a web game run outside the box gets
the honest refusal, never a hang.

## The laws at this layer

- NO pop-up tabs, NO external browser redirection, NO full browser
  install — the in-app surface only (the app-mode window carries no
  chrome: no tabs, no address bar).
- The bridge is the ONLY door between the web game and the box — a web
  game cannot reach the filesystem beyond its own package's seats.
- The save law is absolute: saves land in the GOGAs tree, carried with
  the package.
