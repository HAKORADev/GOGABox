# AGENTS.md — operating manual for AI agents (and future humans)

> **You are resuming work on this repo. Start here, do not archaeologize.**
> This file is the "AI skill": it compresses everything a fresh session needs
> — environment, workflow, the ads integration with the real IDs, and the
> commit / push / build discipline — so the path from "hello" to "working"
> is one obvious step.

Human guides live next door: SETUP · ASSETS · ADS · CI · RESOLUTION_RULE.
Planning lives in `docs/goga_docs/`. This file is about *operating* the
repo: resuming, changing, shipping.

## 0. The one obvious step (resume checklist)

```bash
cd GOGABox                      # fresh sandbox? see §7 first
git pull                        # fast-forward to latest main
./tools/bootstrap.sh            # idempotent: ~1 min warm, ~10 min cold
./tools/test.sh gogabox         # must end ALL PASS
```

Then, in order:

1. Skim `git log --oneline -15` — commit subjects (`<area>: summary`) tell
   you what landed last. The repo has no in-repo journal by design (see §8).
2. Check CI is green: `./tools/ci.sh` (or the Actions tab).
3. Do the task — §4 for ads, §5 for build, §6 for shipping.
4. **Log your session in the sandbox-level journal** (outside the repo,
   §8). An undocumented change is half-done work.

## 1. What this repo is (and is not)

**This repo is GOGABox** — the Godot all-in-one Game box. One product: the
`projects/gogabox/` Godot project (menu + games + economy + plugins). The
machinery around it (`build.sh`, `.ci/`, `tools/`, `config/`, `plugins/`,
CI) exists to build and ship that one product — it stays generic in
mechanics (registry-driven, no hardcoded IDs) but serves nothing else.

| layer | rule |
|---|---|
| **The machinery** — `build.sh`, `.ci/`, `tools/`, `config/`, `plugins/`, CI | stays project-agnostic in mechanics; no game name or ad IDs hardcoded |
| **The product** — `projects/gogabox/` | the whole point of the repo |

`docs/` = **guides** (SETUP · CI · ADS · ASSETS · RESOLUTION_RULE · AGENTS)
plus `docs/goga_docs/` — the GOGABox planning home (GDDs in `gogames_ideas/`,
product thoughts in `ideas/`, release lists in `plans/`, raw dumps in
`brainstorms/`). If a doc answer starts with "for gogabox …", that content
belongs in `docs/goga_docs/`.

## 2. Ground rules (non-negotiable)

1. **Never edit generated paths**: `projects/*/android/build/`,
   `projects/*/addons/`, `dist/`, `.cache/`, `.godot/`. They are wiped and
   re-materialized on every build. Fix the *source* instead: the
   `android-overlay/`, the plugin, or the config.
2. **Toolchain changes go through `config/environment.lock`** — never curl a
   random SDK version into a script. Bump lock → delete the affected cache →
   `./tools/bootstrap.sh` (docs/SETUP.md has the exact freeze procedure).
3. **If you did it twice by hand, script it** and put it in `tools/`.
4. **Assets: CC0 only**, vendored (committed), recorded in the project's
   `assets.manifest.json`. Never hot-link at runtime.
5. **Secrets discipline**: keystores, passwords and GitHub tokens never
   enter the repo (`.gitignore` guards `*.keystore` and `.ci/local.env`).
   Ad IDs / App Keys are *not* secrets — they ship inside every APK and
   mediation platforms gate misuse by package name — so they live in
   `ads_config.json` and in §4 below.
   **Exception (owner-approved, v0.0.7):** `config/keystore/arsenal-release.jks`
   IS committed. An ephemeral per-run debug keystore made every update
   "conflict with the installed package" — a stable signature is what makes
   sideloaded updates installable. This is a hobby sideload project: rotate
   the keystore (and bump `keystore.pass` in `config/projects.json`) BEFORE
   any store publishing, and treat the current signature as public.
6. **Tests are the contract**: `tools/test.sh <game>` passes before and
   after every change. CI green = shippable; red = stop and fix first.
7. **Talk to the user in English**, short messages, conclusions first.

## 3. Map (30 seconds)

| path | what |
|---|---|
| `config/environment.lock` | pinned toolchain: Godot 4.7.2, JDK 17, Android SDK 36 / build-tools 36.1.0, AGP 8.6.1, Gradle 8.11.1, Unity Ads 4.20.0 |
| `config/projects.json` | registry: package, version, ABIs, presets, `use_plugins`, `ci_auto` |
| `.ci/materialize-project.sh` | builds a clean `android/build`: pinned template + `android-overlay/` + plugins + config injection |
| `build.sh <g> [--abi ...] [--type ...] [--aab]` | materialize → patch presets → import → export → verify |
| `tools/test.sh <g>` | headless integration test (`tests/flow_test.tscn`, exit 0 = pass) |
| `tools/bootstrap.sh` | installs exactly the locked toolchain into `.cache/` (same on CI and local) |
| `tools/ci.sh [watch]` | list / watch GitHub Actions runs from the terminal |
| `tools/sync-assets.py` | re-vendor assets from `assets.manifest.json` |
| `plugins/<name>/` | GOGABox android plugins (`unity_ads`, `notify`) |
| `docs/` | guides + `docs/goga_docs/` planning home (GDDs · ideas · plans · brainstorms) |

## 4. Ads integration playbook

### 4.0 Where ads live

Nothing ad-related sits inside game scenes. Game code calls only:

```gdscript
Ads.register_run()
Ads.maybe_interstitial(func(shown): ...)
Ads.show_rewarded(func(watched_to_end): ...)
Ads.banner_show() / Ads.banner_hide()
```

The `Ads` autoload (pacing + **desktop simulation**) and the native bridge
are staged in at build time from `plugins/<backend>/`, selected by
`use_plugins` in `config/projects.json`. Per-project knobs and IDs live in
`projects/<g>/config/ads_config.json`. Architecture details: docs/ADS.md.

### 4.1 The real IDs (as of Aug 2026)

**ACTIVE backend — Unity Ads direct** (`use_plugins: ["unity_ads"]`):

| thing | gogabox |
|---|---|
| Unity Game ID (Android) | `5770940` (owner decision: GOGABox reuses the first ID created for the repo) |
| test_mode | `false` (real ads; flip `projects/gogabox/config/ads_config.json` for local testing) |
| interstitial placement | `Interstitial_Android` |
| rewarded placement | `Rewarded_Android` |
| banner placement | `Banner_Android` |
| package name | `hakora.dev.gogabox` |
| dashboard | Unity Publishing dashboard → Monetization → Projects. NOTE: per-package dashboard entries may be needed later if Unity restricts serving for unregistered packages — create them, then paste the new Game ID into `projects/gogabox/config/ads_config.json`. Placements and the plugin contract stay identical. |
| config file | `projects/gogabox/config/ads_config.json` |

**LevelPlay mediation — built, verified, then rolled back (see §4.3):**

| thing | value |
|---|---|
| App Key | `27d84b1ed` |
| interstitial ad unit | `6j6die13bsc4f0n3` |
| rewarded ad unit | `s6iuno9k7m9nx0sz` |
| banner ad unit | `l7t8jl7rzxpuq0im` |
| native ad unit — **not wired** (no native format in any plugin yet) | `jsyz6rjnru2nd61x` |
| dashboard | app.unity.com → Grow → LevelPlay (same platform as ironsrc.com; either URL works) |
| recover from commits | `19d5369` (plugin) + `7257c24` (activation) |

### 4.2 Wiring a backend into a project (any backend)

1. Does the plugin exist? (`ls plugins/`) → set `use_plugins: ["<name>"]`
   in `config/projects.json`. If not, write one (§4.4).
2. Fill `projects/<g>/config/ads_config.json` with that backend's schema and
   IDs (`unity_ads`: `game_id` + `placements`; `levelplay`: `app_key` +
   `ad_units`). Keep `test_mode: true` while developing.
3. Desktop must never crash: every plugin's `ads.gd` simulates ads when not
   running on Android. Order matters — the desktop branch must come **before**
   any native `available()` check (a past bug; `tools/test.sh` catches it).
4. Verify: `./tools/test.sh <g>` → `./build.sh <g> --abi arm64-v8a` → confirm
   the plugin meta-data and dex classes landed in the APK (`.ci/verify-apk.sh`,
   or `aapt2 dump badging` + a dex grep).
5. One-line override without editing config:
   `GDA_FORCE_PLUGINS=<name> ./build.sh <g>`.

### 4.3 Re-enabling LevelPlay (if ever asked)

The full mediation backend (LevelPlay SDK 9.6.0 + Unity Ads adapter, plugin,
config, docs) was built, CI-verified green, then rolled back at the user's
request ("UnityAds only is good for me"). It is two revert commits deep in
history:

```bash
git revert --no-edit 56f53d4 f74a0f1   # undo the reverts: plugin first, then activation
```

After reverting: re-check the IDs against §4.1 (they come back with the
revert), keep `test_mode: true`, run tests + both-ABI build, push.
Reporting shows up in the **LevelPlay console** (app.unity.com → Grow), not
the classic Unity Ads monetization section. Future option, not a pending
task: AppLovin MAX could be added as just another `plugins/<name>`.

### 4.4 Writing a new ad backend plugin

Contract — `plugins/unity_ads/` is canonical:

```
plugins/<name>/
  plugin.meta.json     # addon_dir, gradle_deps[], manifest_meta{}, autoload{name,script}
  addon/ads.gd         # autoload `Ads`: DEFAULTS + config merge + desktop sim + the standard GDScript API
  android/...java      # GodotPlugin v1: configure / load / show / banner + signals
```

`.ci/materialize-project.sh` consumes `plugin.meta.json`: copies the addon,
injects the gradle deps, injects the manifest meta-data, repoints the
autoload. Before trusting any ad-SDK API from docs, download the AAR and
**`javap` it** — docs lie, bytecode doesn't (this caught real API drift
before). Details: `plugins/unity_ads/README.md`.

### 4.5 SDK upgrades

1. Bump the SDK version in `config/environment.lock` and the plugin's
   `plugin.meta.json`.
2. `rm -rf .cache/android-sdk && ./tools/bootstrap.sh`.
3. `javap` the new AAR; re-verify every signature the plugin uses.
4. `tools/test.sh` + full both-ABI build before pushing. CI cache keys hash
   the lock file, so runners re-fetch exactly once.

## 5. Developing & building

```bash
./tools/test.sh gogabox                # desktop integration test (ads simulated, no device)
./build.sh gogabox                     # both ABIs → dist/gogabox/*.apk
./build.sh gogabox --abi arm64-v8a     # fast single-ABI loop
./build.sh gogabox --aab               # Play Store bundle
```

- Godot binary: `.cache/godot/bin/godot` (or `source .cache/env.sh`).
- A build = materialize → patch presets → headless import → headless export
  per ABI → APK verify. Identical steps on CI and local.
- Generated assets (SFX, launcher icons): per-project tools under
  `projects/<g>/tools/`.
- Environment details and troubleshooting: docs/SETUP.md.

## 6. Commit, push, CI, release

**Commit style** — `<area>: <imperative summary>`, matching history:
`ads:` · `build:` · `ci:` · `config:` · `docs:` · `game:`. Plain `git revert`
for undos (keeps the original subject). One logical change per commit;
include the WORKLOG.md entry with it.

**Push** — `git push origin main`. Repo is public: clone/pull need no auth;
push needs the PAT (§7).

**CI** — pushes matching `projects/** plugins/** config/** .ci/** tools/**
build.sh` trigger `build-android` (every `ci_auto` project × every ABI).
**Docs-only pushes do not trigger CI — that is fine.** Terminal watching:
`./tools/ci.sh` (list last runs) · `./tools/ci.sh watch` (tail one to
completion). Cached runs ≈ 8–12 min per ABI, cold ≈ 20–25.

**Version bump** — every user-visible change: `version_name` +1 patch and
`version_code_base` +100 in `config/projects.json`. Effective version codes:
arm32 = base+1, arm64 = base+2 (Play Store needs distinct codes, higher on
the modern ABI).

**Release** — bump version → push → CI green → Actions → **build-android →
Run workflow** → pick project + `create_release: true` → tag `v<version_name>`
gets both APKs. Re-running the same version clobbers the previous assets.

**Before any store submission** — `test_mode: false` in the project's
`ads_config.json` · package name matches the ad dashboard entry · one real
interstitial + rewarded tested on device · consent/GDPR guidance reviewed ·
docs updated.

## 7. Sandbox survival (this machine)

The workspace has been wiped **twice**; both times full recovery took
~10 minutes because everything lives in git:

1. `git clone https://github.com/HAKORADev/GOGABox.git`
   (public — no auth needed).
2. `./tools/bootstrap.sh`.
3. `./tools/test.sh gogabox` — if this passes, you are fully back.

Notes:

- GitHub PAT (push + CI API): kept **outside** the repo; if missing, ask the
  user. `tools/ci.sh` accepts `GITHUB_TOKEN` or `$HOME/.arsenal-gh-token`;
  read-only public access works without one (rate limits apply).
- Session journal lives **outside the repo** (user preference):
  `/home/z/my-project/worklog.md`. Write entries there, never commit a
  journal file into the repo. Since it can be lost with a sandbox wipe,
  the durable memory is this manual + clean commit messages.
- Builds are validated on 4 GB RAM; keep `org.gradle.jvmargs=-Xmx2048m`
  (already set in the overlay).

## 8. Session journal (outside the repo)

The task journal is **not part of the repo** (user preference — the repo
ships products, not diary entries). It lives in the sandbox at
`/home/z/my-project/worklog.md`: append-only, newest at the bottom, one
entry per session — what was asked → what was done (commits, runs,
versions) → what is pending → decisions taken.

Because that file can vanish with a sandbox wipe, keep the durable record
in the repo itself: accurate AGENTS.md sections and descriptive commit
subjects (`git log` is the real history).

## 9. Doc index

| need | read |
|---|---|
| env setup, toolchain freeze, pitfalls | docs/SETUP.md |
| add a new game | inside the box: one registry entry + one GogaGame script + one thumbnail — read `docs/goga_docs/plans/BOX_CORE_DESIGN.md` and docs/ADDING_A_GAME.md |
| ads architecture and config | docs/ADS.md + plugins/unity_ads/README.md |
| assets policy, manifest, source catalogs, store trials | docs/ASSETS.md |
| CI, caching, releases, signing | docs/CI.md |
| what happened so far | `git log` + the sandbox session journal (§8) |
