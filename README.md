# Godot Android Arsenal

A **reusable Godot → Android build environment** and **multi-game monorepo**.
Everything is pinned, scripted and identical on GitHub Actions and on any
developer machine — no IDE, no manual setup, no mystery steps.

> The two things this repo does:
> 1. **Builds games**: source + vendored CC0 assets → signed per-ABI APKs.
> 2. **Stores many projects**: games live under `projects/` and do not depend
>    on anyone's workspace; a fresh clone is a complete source of truth.

```
clone → ./tools/bootstrap.sh → ./build.sh jellyjump     # that's the whole pipeline
```

## Repo map

| path | role |
|---|---|
| `config/environment.lock` | Pinned toolchain: Godot, JDK, Android SDK, AGP, Gradle, Unity Ads SDK |
| `config/projects.json` | Project registry (versions, ABIs, presets, plugins, CI flags) |
| `tools/bootstrap.sh` | One-shot env setup (idempotent, same on CI and local) |
| `build.sh` | Build CLI: materialize → patch presets → export → verify |
| `tools/test.sh` | Headless integration tests (`tests/flow_test.tscn` convention) |
| `tools/sync-assets.py` | Re-download/re-vendor assets from `assets.manifest.json` |
| `.ci/` | Shared plumbing (SDK/Godot installers, preset patcher, APK verifier, CI matrix) |
| `plugins/` | Shared Godot android plugins (currently: `unity_ads`) |
| `projects/<game>/` | One self-contained Godot project per game |
| `docs/` | SETUP · ADDING_A_GAME · ASSETS · ADS · CI |

## Current projects

| project | status | ABIs | monetization |
|---|---|---|---|
| `jellyjump` | playable, CI-green | arm64-v8a, armeabi-v7a | Unity Ads: interstitial every 3 runs, rewarded revive + double coins, menu banner |

## Quickstart (local)

Ubuntu (24.04 tested) with `curl unzip zip jq python3` — then:

```bash
./tools/bootstrap.sh                 # JDK17 + Android SDK + Godot 4.7.2 (cached in .cache/)
./tools/test.sh jellyjump            # headless integration tests
./build.sh jellyjump                 # both ABIs → dist/jellyjump/*.apk
./build.sh jellyjump --abi arm64-v8a # single ABI
```

Details & troubleshooting: [docs/SETUP.md](docs/SETUP.md)

## CI

`.github/workflows/build-android.yml`:

- **push to main** → builds every project with `ci_auto: true`, both ABIs, uploads APK artifacts.
- **manual dispatch** → choose project / ABI / build type, optionally publish a GitHub release.

Caching is keyed on `config/environment.lock`, so bumping a version re-fetches
exactly once. See [docs/CI.md](docs/CI.md).

## Monetization

Unity Ads is integrated as a shared, configurable plugin: each project ships a
`config/ads_config.json` (game id, placements, pacing, test mode). Full guide:
[docs/ADS.md](docs/ADS.md).

## Assets

All art/audio is CC0 (Kenney packs + in-repo generated SFX). Provenance,
licenses and re-download instructions per project: `projects/<game>/assets.manifest.json`
and [docs/ASSETS.md](docs/ASSETS.md).

## Adding a new game

Copy `projects/jellyjump` as a template, add one entry to `config/projects.json`,
push — CI picks it up automatically. Full checklist: [docs/ADDING_A_GAME.md](docs/ADDING_A_GAME.md).

## Release checklist (per game)

1. `config/ads_config.json` → `"test_mode": false`
2. Bump `version_name` / `version_code_base` in `config/projects.json`
3. For Play Store upload, produce an `.aab`: `./build.sh <game> --aab`
4. Real release signing: set `GDA_RELEASE_KEYSTORE*` env vars (CI: repo secrets, see docs/CI.md)
5. Change `package` in `config/projects.json` if the current one must stay unique

## License

Repo code: MIT (see [LICENSE](LICENSE)). Game assets: CC0 by their authors
(Kenney). Unity Ads SDK is governed by Unity's own terms when you ship it.
