# GOGABox

GOGABox is an open-source game platform for Android and Windows: a
lightweight launcher, a discovery store and a runtime engine in one
application. The app itself ships without games. Games are delivered as
open, folder-based packages that anyone can inspect, modify and publish —
from a terminal, an editor or an AI agent.

Licensed under MIT. No ads, no accounts, no tracking, no DRM, no servers
of ours.

## How it works

**The application is an engine.** The binary contains the feed, the
search, the wallet (GOGACoins), the achievements, the LAN multiplayer and
the package runtime — but zero games. Every game arrives as a package:

```
my-game/                      a GOGA package (a plain folder)
├── index/index.json          the manifest: id, title, version, age,
│                             genres, platform builds, thumbnail
├── game/                     the runnable build (Godot .pck, a native
│                             binary, or a web entry .html)
├── discover/                 the store-page material (text, media)
├── data/                     plain, moddable game data (JSON logic,
│                             audio, visuals, shaders)
└── save/                     portable saves — live inside the package
```

Packages are installed from the built-in discovery feed, from a `.goga`
(single game) or `.gogas` (collection) archive, or from any local folder.
Everything installs into the player's **GOGAs** folder — next to the
executable on Windows, in `Downloads/GOGAs/` on Android — and that folder
belongs to the player: games, saves and mods included.

**Discovery is decentralized.** The engine reads package indexes over
plain HTTP (GitHub raw URLs; the GitHub API is never used, so there are no
rate-limit problems). This repository is the first official source.
Community repos publish by opening a pull request that adds one line to
`GOGAs/discover/REPOS.txt`; a CI workflow validates the linked repo's
index before it merges. Anyone can also add a local folder as a source —
including a "virtual repo" layout that simulates the full GitHub flow
offline, which is how developers test before publishing.

**Three tiers, hardcoded in the engine:** `official` (this repository's
packages), `community` (listed in `REPOS.txt`, CI-verified) and
`hobbyist` (everything else). There is no developer account system.

**Games run through the box, never around it.** Godot games load in-process
from their `.pck`; native games launch as child processes and talk to the
box over localhost (the same model as the Steam API); web games (Godot
HTML5 or plain HTML/three.js) run in an in-app browser view with a
JavaScript bridge — no pop-up tabs, no redirects. A small C ABI
(`sdk/native/`) lets any native game integrate coins, saves and
achievements.

## Repository layout

| path | what |
|---|---|
| `projects/gogabox/` | the application (Godot 4.7): engine, store, package runtime |
| `GOGAs/` | the official package source: committed packages + discovery manifest |
| `developers/` | the developers catalog — SDK reference, packaging, publishing, modding |
| `sdk/` | the Godot SDK plugin and the native C ABI header + reference client |
| `packaging/` | per-game packaging sources for the official packages |
| `archive/games_v042/` | the last generation of built-in games, preserved whole |
| `tools/` | bootstrap, test runner, packaging rig, CI validators |
| `docs/` | project documentation and planning notes |
| `AGREEMENT.md` | end-user and developer agreements |
| `REPORTING.md` | how bug reports work |

## Getting started

### Players

Install the app and it already carries the official games: the Windows
zip ships the `GOGAs` folder next to `GOGABox.exe` (unzip, run), and on
Android you extract the `GOGAs-official` zip so the folder lands at
`Downloads/GOGAs` — the release page lists both, and the app itself
reminds you where the folder goes if it boots without it. From there,
open the discovery feed (the arrow next to **All Games**), download
more, play. The age field in your profile only gates the play button on
age-rated games — browsing, downloading and owning are unrestricted.
See `REPORTING.md` if something is broken.

### Developers

Start at `developers/README.md`. The short path: read
`developers/PACKAGING.md`, copy one of the official packages under
`GOGAs/games/` as a template, validate it with
`python3 tools/goga_ci_validate.py tree`, then publish via pull request
(`developers/PUBLISHING.md`). Modding existing games is a first-class
workflow — see `developers/MODDING.md`.

### Building from source

Ubuntu (24.04 tested) with `curl unzip zip jq python3`:

```bash
git clone https://github.com/HAKORADev/GOGABox.git
cd GOGABox
./tools/bootstrap.sh          # installs JDK 17, Android SDK, Godot 4.7.2 (cached in .cache/)
./tools/test.sh gogabox       # headless integration tests
./build.sh gogabox            # release APKs (arm32 + arm64) into dist/
```

Windows builds run on GitHub Actions for every push (the
`GOGABox-windows` zip artifact carries the exe and the official GOGAs
tree together; `GOGAs-official` is the same tree zipped alone for the
Android Downloads placement), and the same commands work locally with
the Windows export templates. The pinned toolchain versions live in
`config/environment.lock`; everything is scripted, so CI and local builds
are identical.

## Contributing

Bug reports go through GitHub issues — see `REPORTING.md` for what a good
report contains (a game id, when the report is about a game). Game changes
and new packages are pull requests. The agreements in `AGREEMENT.md`
describe what players and developers can expect from each other; the
short version is that everything here is open by construction and stays
that way.
