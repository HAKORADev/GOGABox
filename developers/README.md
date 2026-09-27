# THE DEVELOPERS CATALOG — GOGABox is a platform, this is your door

Everything GOGABox is, is open: MIT-licensed, zero ads, zero servers of
ours, games as plain folders, data as plain files. A game on GOGABox can
be built by a human, by an AI agent, or by both at 2 AM. Nothing here is
closed, nothing here is gated, nothing here is ours-only. The engine
validates structure, not taste.

Start where you are:

| you are... | read this | then this |
|---|---|---|
| building a NEW Godot game | [SDK.md](SDK.md) | [PACKAGING.md](PACKAGING.md) |
| bringing an EXISTING Godot game | [PACKAGING.md](PACKAGING.md) | [SDK.md](SDK.md) |
| building an HTML5 / web game | [WEB_GAMES.md](WEB_GAMES.md) | [PACKAGING.md](PACKAGING.md) |
| wrapping a NON-Godot game (a .exe, an .so, "zuma-shaped") | [NATIVE_GAMES.md](NATIVE_GAMES.md) | [SDK.md](SDK.md) |
| publishing (the two-step, no tokens for us) | [PUBLISHING.md](PUBLISHING.md) | — |
| modding ANY game (yours or not) | [MODDING.md](MODDING.md) | — |
| an AI agent doing all of the above | [AGENTS.md](AGENTS.md) + [agents/](agents/) | — |
| reporting a game or the app | [../REPORTING.md](../REPORTING.md) | — |

## The catalog, sorted

1. **[SDK.md](SDK.md)** — the one API: GOGACoins, portable saves, toasts,
   (and the LAN seat) — one contract, four transports (embedded, standalone
   Godot, native C, web bridge).
2. **[PACKAGING.md](PACKAGING.md)** — the GOGA package contract: the folder
   shape, `index/index.json` (every field), the strict validator's rules
   (the open-data minimums, the portable save), .goga/.gogas/folder shapes,
   the id scheme, per-platform builds, renderers.
3. **[DISCOVER.md](DISCOVER.md)** — how the store works: sources (github
   raw + local + the virtual repo), the tiers (official/community/hobbyist),
   the source.json file, the files manifest, how updates flow.
4. **[WEB_GAMES.md](WEB_GAMES.md)** — HTML5 in the box: bare .html games,
   Godot HTML5 exports, the in-app WebView, the `window.GOGA.*` bridge.
5. **[NATIVE_GAMES.md](NATIVE_GAMES.md)** — non-Godot games: the Steam
   model (the box must run), the C ABI header, per-platform loading.
6. **[PUBLISHING.md](PUBLISHING.md)** — the two-step publish: make a repo,
   PR one line into the official REPOS.txt; CI validates; merged =
   community tier. No tokens ever leave you.
7. **[MODDING.md](MODDING.md)** — the open-data law in practice: logic
   JSON, audio, visuals, shaders, localization, flavors. Written to be
   aggressive on purpose (see AGENTS.md for why).
8. **[AGENTS.md](AGENTS.md)** — the operating manual for AI agents on
   this platform + [agents/](agents/) — task playbooks (build a game,
   package one, wrap one, publish one, mod one).
9. **[ACKNOWLEDGMENT.md](ACKNOWLEDGMENT.md)** — the developers'
   acknowledgment: everything here is exposed, wide-open, hijackable,
   moddable — nothing is ours-only. Read before you publish.
10. **[../REPORTING.md](../REPORTING.md)** — how reports work (github
    issues, the game-id rule, what gets refused and why).

## The laws that hold everywhere (the short list)

- **THE PORTABLE SAVE LAW** — saves live in the package's `save/` (or
  `GOGAs/libs/clients/<id>/` for standalone), never in app-data bloat.
- **THE OPEN DATA LAW** — a package carries `data/` with real, plain
  files: logic JSON, sfx, music, shaders, assets. The validator refuses
  less than the minimum.
- **THE NO-API-LIMIT LAW** — discovery rides raw http known-file URLs;
  github's REST API is never touched.
- **THE ONE WALLET** — GOGACoins are the box's; a game never keeps its
  own ledger.
- **THE HONEST DOOR** — every SDK call answers truthfully when the box
  (or the door) is not there: false, 0, "" — never a fake, never a hang.
- **THE AGE DOOR** — the box's simplified age system touches only the
  play button; your game is discoverable, downloadable and ownable by
  anyone. Tag it honestly (`age` + `content` in the index) and carry on.
