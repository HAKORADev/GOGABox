# PLAYBOOK: ship an HTML5 / web game

1. The game is a folder of web files with an `index.html` entry
   (three.js, phaser, DOM, a Godot HTML5 export — anything a WebView
   plays). No build step is imposed; the entry file is the contract.
2. The manifest's runs: `{"kind": "web", "entry": "game/web/index.html"}`
   — the validator refuses when the entry file is missing.
3. The bridge: `window.GOGA.*` (SDK.md) for coins/saves/toasts. Guard
   every call (`if (window.GOGA)`) so the game also runs in a plain
   browser during development — the bridge simply is not there there.
4. The data minimums still hold (PACKAGING.md) — a web game ships its
   data/ tree like everyone (the game may read it via relative fetch,
   the modder edits it the same way).
5. Android runs it in the in-app WebView (no tabs, no redirection); PC
   carries the WebView2 slot and refuses honestly until it lands — say
   that in your game's discover page instead of pretending.
