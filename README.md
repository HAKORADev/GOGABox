# GOGABox

**Godot all-in-one Game box** — one Android app that is a whole shelf of
games: unlock them, play them, collect GOGACoins, climb achievements.

Everything is pinned, scripted and identical on GitHub Actions and on any
developer machine — no IDE, no manual setup, no mystery steps.

```
clone → ./tools/bootstrap.sh → ./build.sh gogabox      # that's the whole pipeline
```

## What GOGABox is

- A single Godot 4 project (`projects/gogabox`) shipping a menu "box" that
  hosts multiple games (snake, hopper, lanes, rally, slasher, merge2048, ...).
- A locked/soonest tile economy: games unlock with GOGACoins, mysteries
  reveal, favorites are hearted.
- Android-native extras through small Godot plugins: Unity Ads
  (banner / interstitial / rewarded) and local notifications ("reminders").

## Repo map

| path | role |
|---|---|
| `config/environment.lock` | Pinned toolchain: Godot 4.7.2, JDK 17, Android SDK, AGP, Gradle, Unity Ads SDK |
| `config/projects.json` | The GOGABox build registry (version, ABIs, plugins, keystore) |
| `tools/bootstrap.sh` | One-shot env setup (idempotent, same on CI and local) |
| `build.sh` | Build CLI: materialize → patch presets → export → verify |
| `tools/test.sh` | Headless integration tests (`projects/gogabox/tests/flow_test.tscn`) |
| `tools/sync-assets.py` | Re-download/re-vendor assets from `assets.manifest.json` |
| `.ci/` | Shared plumbing (SDK/Godot installers, preset patcher, APK verifier) |
| `plugins/` | GOGABox Godot android plugins (`unity_ads`, `notify`) |
| `projects/gogabox/` | The GOGABox Godot project (the whole product) |
| `docs/` | Guides: SETUP · CI · ADS · ASSETS · RESOLUTION_RULE · AGENTS |
| `docs/goga_docs/` | GOGABox planning home: `gogames_ideas/` (game GDDs), `ideas/`, `plans/`, `brainstorms/` |
| `docs/AGENTS.md` | Operating manual for AI agents / returning sessions |

## Quickstart (local)

Ubuntu (24.04 tested) with `curl unzip zip jq python3` — then:

```bash
./tools/bootstrap.sh                 # JDK17 + Android SDK + Godot 4.7.2 (cached in .cache/)
./tools/test.sh gogabox              # headless integration tests
./build.sh gogabox                   # both ABIs → dist/gogabox/*.apk
./build.sh gogabox --abi arm64-v8a   # single ABI
```

Details & troubleshooting: [docs/SETUP.md](docs/SETUP.md)

## Returning to this repo (AI agents included)

One obvious step, then real work:

```bash
git pull && ./tools/bootstrap.sh && ./tools/test.sh gogabox
```

Then read [docs/AGENTS.md](docs/AGENTS.md) — how everything works: ads IDs,
build, commit/push/CI conventions, sandbox recovery.

## CI

`.github/workflows/build-android.yml`:

- **push to main** → builds GOGABox, both ABIs, uploads APK artifacts.
- **manual dispatch** → choose ABI / build type, optionally publish a GitHub release.

Caching is keyed on `config/environment.lock`, so bumping a version re-fetches
exactly once. See [docs/CI.md](docs/CI.md).

## Monetization

Unity Ads is integrated as a configurable plugin: GOGABox ships
`projects/gogabox/config/ads_config.json` (game id, placements, pacing,
test mode). Full guide: [docs/ADS.md](docs/ADS.md).

## Assets

All art/audio is CC0 (Kenney packs + in-repo generated SFX). General policy,
manifest schema, source catalogs and the asset-store download log:
[docs/ASSETS.md](docs/ASSETS.md).

## Planning & ideas

Planning lives in [docs/goga_docs/](docs/goga_docs/):

- `gogames_ideas/` — GDDs for the games inside the box
- `ideas/` — general product ideas
- `plans/` — version plans (what shipped in each release and why)
- `brainstorms/` — raw brainstorm material

## Release checklist

1. `projects/gogabox/config/ads_config.json` → `"test_mode": false`
2. Bump `version_name` / `version_code_base` in `config/projects.json`
3. For Play Store upload, produce an `.aab`: `./build.sh gogabox --aab`
4. Real release signing: set `GDA_RELEASE_KEYSTORE*` env vars (CI: repo secrets, see docs/CI.md)
5. Change `package` in `config/projects.json` if the current one must stay unique

## License

GOGABox is **AS-IS** — Copyright HAKORADev, all rights reserved; personal
non-commercial use allowed, redistribution/commercial use needs written
permission (see [LICENSE](LICENSE)). Bundled third-party content keeps its
own licenses (Godot Engine: MIT, Kenney assets: CC0). Unity Ads SDK is
governed by Unity's own terms when you ship it.
