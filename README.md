# GOGABox

**The games platform that is also a game box** — an engine, a store and
a launcher in one: the box bakes ZERO games; every game arrives as an
open GOGA package (a plain folder a human or an agent can read) through
the discover engine (github raw + local), plays inside the box with the
shared wallet (GOGACoins), the portable saves, the LAN seat and the
achievements. Open source under **MIT**, **zero ads**, no accounts, no
servers of ours, no DRM.

Everything is pinned, scripted and identical on GitHub Actions and on
any developer machine — no IDE, no manual setup, no mystery steps.

```
clone → ./tools/bootstrap.sh → ./tools/test.sh gogabox → ./build.sh gogabox
```

## What GOGABox is (the v043 platform shape)

- **The empty binary law**: `projects/gogabox` is the ENGINE + the store
  (the feed, the wallet, the LAN, the profiles, the discover engine, the
  package runner). It ships zero games by law.
- **The GOGAs tree** — the player's game home: Windows next to the exe,
  Android in the system Downloads. `libs/` (the SDK bridges) ·
  `games/<pkg id>/` (installed packages) · `discover/` (the sources +
  the register) · `.cache/`.
- **The GOGA package** — a plain folder: `index/` (the manifest), `game/`
  (the runnable: a godot pck, a native binary, or a web entry), `discover/`
  (the page), `data/` (THE OPEN DATA LAW: plain moddable logic/sfx/music/
  shaders/assets), `save/` (THE PORTABLE SAVE LAW). Distributed as a
  folder, a `.goga` (one game zipped) or a `.gogas` (many).
- **The discover engine** — sources over RAW http only (the known-file
  convention, github's API never touched): the official repo (this one)
  is hardcoded-official, `GOGAs/discover/REPOS.txt` is the community
  register (a PR, CI-validated — the two-step publish), everything else
  is hobbyist. Local sources and "virtual repos" simulate the full
  github flow with zero network (the local flow IS the contract).
- **The four transports of one SDK** — embedded games ride the box's own
  doors; standalone Godot games talk to the running box over localhost
  (the Steam model); native games link the C ABI (`sdk/native/`); web
  games ride the in-app WebView bridge (`window.GOGA.*`).
- **The runner kinds** — `godot_embedded` (a pck loaded in-box, the box's
  files un-shadowable), `native` (own process on PC, in-process .so on
  Android — the scale door), `web` (HTML5 in-app, no pop-up tabs).
- **The simplified age system** — the ladder (3..+21) and the content
  tags describe honestly; the profile's age number gates ONLY the play
  button. Discovery, downloading and owning are age-blind.
- **The self-update** — the official source serves `engine_version` +
  release URLs; Android hands the apk to the package installer
  (permission asked at use-time), Windows writes a replace-after-close
  helper and tells the player.
- TWO platforms from ONE build action: Android APKs (arm32 + arm64) and
  THE one Windows exe — `GOGABox.exe` (32-bit, SSE2 baseline).
- The last generation of baked games lives whole in
  `archive/games_v042/` (31 games + teasers, scripts + assets + the
  registry entries as the revival seed); the four PILOT ports
  (rally + slasher both devices, dominoes PC-only, CONQUER DICE
  Android-only) ship as the first official packages under `GOGAs/`.

## Repo map

| path | role |
|---|---|
| `GOGAs/` | THE OFFICIAL SOURCE — the committed packages tree + the discover manifest + the community register (served over raw URLs) |
| `projects/gogabox/` | The engine + the store (the one Godot product) |
| `game/core/goga_core.gd` | The GOGA runtime: the home tree, the validator, the importer, the runner, the SDK bridge |
| `game/core/goga_discover.gd` | The discover engine: sources, tiers, feed, search, downloads, updates |
| `game/core/goga_update.gd` | The app self-update (the Android/Windows tricks) |
| `developers/` | THE DEVELOPERS CATALOG (SDK, packaging, discover, web, native, publishing, modding, the agents playbooks, the acknowledgment) |
| `sdk/godot/gogabox_sdk/` | The Godot SDK plugin (one API, two transports) |
| `sdk/native/` | The C ABI header + the reference client (compiles clean) |
| `packaging/` | The packaging rig's per-game sources + specs (the four pilots) |
| `archive/games_v042/` | The v042 baked generation, saved whole |
| `config/environment.lock` | Pinned toolchain: Godot 4.7.2, JDK 17, Android SDK, AGP, Gradle |
| `tools/bootstrap.sh` | One-shot env setup (idempotent, same on CI and local) |
| `tools/v043_package.py` | The packaging rig (stage → export-pack → assemble → manifest) |
| `tools/goga_ci_validate.py` | The CI's mirror of the strict validator |
| `tools/test.sh` | Headless integration tests (the rig installs the official source first) |
| `build.sh` | Build CLI: materialize → patch presets → export → verify |
| `.ci/` | Shared plumbing (SDK/Godot installers, preset patcher, APK verifier) |
| `plugins/` | GOGABox Godot android plugin (`notify`) |
| `docs/goga_docs/` | Planning home: `gogames_ideas/` (game GDDs), `ideas/`, `plans/`, `brainstorms/` |
| `docs/AGENTS.md` | Operating manual for AI agents / returning sessions |
| `REPORTING.md` | The report flow (github issues, the game id, the triage) |

## For players

Install the box, open it, pull the discover feed (the arrow beside
ALL GAMES), download a game, play. Import a `.goga`/`.gogas`/folder any
time. The GOGAs folder in your Downloads (or next to the exe) is YOURS —
games, saves, mods and all. See `developers/` for everything a game can
do, and `REPORTING.md` for what a report is.

## For developers (human and AI)

Start at `developers/README.md` — the indexed catalog. The short path:
read `developers/PACKAGING.md`, copy the pilot shape from `packaging/`,
validate against the box, publish with the two-step
(`developers/PUBLISHING.md`). Modding is a first-class door
(`developers/MODDING.md`), written aggressive on purpose.

## Quickstart (local)

Ubuntu (24.04 tested) with `curl unzip zip jq python3` — then:

```bash
./tools/bootstrap.sh                 # JDK17 + Android SDK + Godot 4.7.2 (cached in .cache/)
./tools/test.sh gogabox              # headless integration tests (installs the official source first)
./build.sh gogabox                   # both ABIs → dist/gogabox/*.apk
python3 tools/v043_package.py        # rebuild the four pilot packages into GOGAs/
```
